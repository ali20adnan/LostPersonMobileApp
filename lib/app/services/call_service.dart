import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/translator/controllers/translator_controller.dart';
import '../routes/app_routes.dart';
import 'api_service.dart';
import 'call_sound_service.dart';
import 'socket_service.dart';

/// Call lifecycle states (mirrors the web `CallStatus`).
enum CallStatus { idle, calling, ringing, connecting, active, ended }

/// The other party in a 1:1 call.
class CallPeer {
  final int id;
  final String fullName;
  final String? avatarUrl;
  const CallPeer({required this.id, required this.fullName, this.avatarUrl});
}

/// 1:1 audio call service (Agora RTC + Socket.IO ring signaling).
///
/// Ring/presence signaling rides [SocketService] (`call:*` events); the audio
/// itself flows over Agora's network (SD-RTN). Both peers join the channel
/// `call_<callId>` with a short-lived token from POST /agora-token and publish
/// their mic. There is no SDP/ICE negotiation — Agora handles the media.
///
/// Scope (v1): audio only, 1:1 only, foreground only.
class CallService extends GetxService {
  static const _listenerId = 'call_service';
  static const _ringTimeout = Duration(seconds: 30);

  // ── reactive state ────────────────────────────────────────────
  final status = CallStatus.idle.obs;
  final Rxn<CallPeer> peer = Rxn<CallPeer>();
  final isMuted = false.obs;
  /// Whether audio is routed to the loudspeaker (true) vs. the earpiece (false).
  /// Communication profile defaults to the earpiece, so this starts false.
  final isSpeakerOn = false.obs;
  final startedAt = Rxn<DateTime>();
  final endReason = RxnString();

  /// Last Agora error (`code: message`) captured during a call — surfaced for
  /// diagnostics so token/join failures are visible instead of silently printed.
  final lastError = RxnString();

  // ── call bookkeeping ──────────────────────────────────────────
  String? _callId;
  int? _peerUserId;
  bool _isCaller = false;

  // ── Agora objects ─────────────────────────────────────────────
  RtcEngine? _engine;
  Timer? _ringTimer;
  /// Pending teardown of the previous engine (leaveChannel + release run off the
  /// call stack). A new join awaits this so two native engines never coexist —
  /// creating a fresh engine before the old one's native release() finishes can
  /// hard-crash the app on Android.
  Future<void>? _engineTeardown;

  /// Monotonic call generation. Bumped whenever the current call is set up or
  /// torn down (_endWith / _dismissSilently / new call). An in-flight _joinAgora
  /// captures it on entry and re-checks it AFTER EVERY await so a join that was
  /// superseded (e.g. this device lost a simultaneous-answer race and got
  /// call:handled mid-join) backs out silently — disposing its own engine —
  /// instead of publishing a dead engine or emitting stray signals.
  int _callGen = 0;

  // ── ringtones / SFX ───────────────────────────────────────────
  final CallSoundService _sound = CallSoundService();

  bool get inCall => status.value != CallStatus.idle && status.value != CallStatus.ended;

  Future<CallService> init() async {
    _registerSocketListeners();
    await _sound.init();
    return this;
  }

  // ─────────────────────────────────────────────────────────────
  //  Public actions
  // ─────────────────────────────────────────────────────────────

  /// Start an outgoing call to [toUserId] within [conversationId].
  Future<void> startCall({
    required int conversationId,
    required int toUserId,
    required CallPeer callee,
  }) async {
    if (inCall) return;
    if (!Get.isRegistered<SocketService>()) return;

    _callGen++;
    _callId = _generateCallId(toUserId);
    _peerUserId = toUserId;
    _isCaller = true;
    peer.value = callee;
    endReason.value = null;
    lastError.value = null;
    startedAt.value = null;
    isMuted.value = false;
    isSpeakerOn.value = false;
    status.value = CallStatus.calling;

    _emit('call:invite', {
      'toUserId': toUserId,
      'conversationId': conversationId,
      'callId': _callId,
    });

    _sound.startOutgoingRing(); // caller ringback while waiting for an answer
    _openCallUi();

    _ringTimer = Timer(_ringTimeout, () {
      if (status.value == CallStatus.calling) {
        _emit('call:cancel', {'toUserId': _peerUserId, 'callId': _callId});
        _endWith('no-answer');
      }
    });
  }

  /// Accept the currently ringing incoming call.
  Future<void> acceptCall() async {
    if (status.value != CallStatus.ringing || _callId == null || _peerUserId == null) {
      return;
    }
    _ringTimer?.cancel();

    final granted = await _ensureMicPermission();
    if (!granted) {
      _emit('call:reject', {'toUserId': _peerUserId, 'callId': _callId, 'reason': 'mic'});
      _endWith('mic-denied');
      return;
    }

    _sound.stopRinging(); // stop the incoming ring the moment we answer
    status.value = CallStatus.connecting;
    // Tell the caller we accepted so they join too.
    _emit('call:accept', {'toUserId': _peerUserId, 'callId': _callId});

    final gen = _callGen;
    try {
      await _joinAgora();
    } catch (e) {
      // Only report a REAL failure of the still-current attempt. If the call was
      // dismissed/ended while joining (call:handled, remote end), stay silent —
      // emitting call:end here would carry stale/null fields.
      if (gen != _callGen) return;
      // A join failure here (bad/absent Agora token, engine init failure) means
      // the callee can't participate — tell the caller so it doesn't hang, and
      // record why so the "failed" state is diagnosable.
      debugPrint('CallService: joinAgora failed (callee) - $e');
      lastError.value ??= '$e';
      _emit('call:end', {'toUserId': _peerUserId, 'callId': _callId});
      _endWith('failed');
    }
  }

  /// Reject the ringing incoming call.
  void rejectCall() {
    _emit('call:reject', {'toUserId': _peerUserId, 'callId': _callId});
    _endWith('rejected');
  }

  /// Cancel an outgoing call before it is answered.
  void cancelCall() {
    _emit('call:cancel', {'toUserId': _peerUserId, 'callId': _callId});
    _endWith('canceled');
  }

  /// Hang up an active call.
  void endCall() {
    _emit('call:end', {'toUserId': _peerUserId, 'callId': _callId});
    _endWith('ended');
  }

  /// Hang up regardless of state (used by the single call-screen button).
  void hangUp() {
    switch (status.value) {
      case CallStatus.active:
      case CallStatus.connecting:
        endCall();
        break;
      case CallStatus.calling:
        cancelCall();
        break;
      case CallStatus.ringing:
        rejectCall();
        break;
      default:
        break;
    }
  }

  void toggleMute() {
    final engine = _engine;
    if (engine == null) return;
    final next = !isMuted.value;
    engine.muteLocalAudioStream(next);
    isMuted.value = next;
  }

  /// Toggle audio routing between the external loudspeaker and the earpiece.
  /// `setEnableSpeakerphone` is the correct Agora VoIP-routing call for the
  /// communication profile and needs no extra permissions.
  Future<void> toggleSpeaker() async {
    final engine = _engine;
    if (engine == null) return;
    final next = !isSpeakerOn.value;
    // Only reflect the new state if the routing call actually succeeded, and
    // never let a failure bubble up and disrupt the ongoing call.
    try {
      await engine.setEnableSpeakerphone(next);
      isSpeakerOn.value = next;
    } catch (e) {
      debugPrint('CallService: toggleSpeaker failed - $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Signaling
  // ─────────────────────────────────────────────────────────────

  void _registerSocketListeners() {
    if (!Get.isRegistered<SocketService>()) return;
    final socket = Get.find<SocketService>();

    socket.on('call:incoming', _listenerId, (data) => _onIncoming(_asMap(data)));
    socket.on('call:accepted', _listenerId, (data) => _onAccepted(_asMap(data)));
    // This account handled the call on another device → dismiss our ring quietly.
    socket.on('call:handled', _listenerId, (data) => _onHandledElsewhere(_asMap(data)));
    socket.on('call:rejected', _listenerId, (data) => _onRemoteEnd(_asMap(data), 'rejected'));
    socket.on('call:canceled', _listenerId, (data) => _onRemoteEnd(_asMap(data), 'canceled'));
    socket.on('call:busy', _listenerId, (data) => _onRemoteEnd(_asMap(data), 'busy'));
    socket.on('call:unavailable', _listenerId, (data) => _onRemoteEnd(_asMap(data), 'unavailable'));
    socket.on('call:ended', _listenerId, (data) => _onRemoteEnd(_asMap(data), 'ended'));
  }

  void _onIncoming(Map<String, dynamic> data) {
    // Already busy → tell the caller.
    if (inCall) {
      final fromId = (_asMap(data['from'])['id']) as int?;
      _emit('call:busy', {'toUserId': fromId, 'callId': data['callId']});
      return;
    }
    final from = _asMap(data['from']);
    _callGen++;
    _callId = data['callId'] as String?;
    _peerUserId = from['id'] as int?;
    _isCaller = false;
    peer.value = CallPeer(
      id: (from['id'] as int?) ?? 0,
      fullName: (from['fullName'] as String?) ?? 'مستخدم',
      avatarUrl: from['avatarUrl'] as String?,
    );
    endReason.value = null;
    lastError.value = null;
    startedAt.value = null;
    isMuted.value = false;
    isSpeakerOn.value = false;
    status.value = CallStatus.ringing;

    _sound.startIncomingRing(); // ring the callee until they answer/reject
    _openCallUi();

    _ringTimer = Timer(_ringTimeout, () {
      if (status.value == CallStatus.ringing) {
        _emit('call:reject', {'toUserId': _peerUserId, 'callId': _callId, 'reason': 'timeout'});
        _endWith('no-answer');
      }
    });
  }

  // Caller: callee accepted → join the Agora channel.
  Future<void> _onAccepted(Map<String, dynamic> data) async {
    if (data['callId'] != _callId || !_isCaller) return;
    _ringTimer?.cancel();
    _sound.stopRinging(); // callee answered → stop the outgoing ringback

    final granted = await _ensureMicPermission();
    if (!granted) {
      _emit('call:end', {'toUserId': _peerUserId, 'callId': _callId});
      _endWith('mic-denied');
      return;
    }

    status.value = CallStatus.connecting;
    final gen = _callGen;
    try {
      await _joinAgora();
    } catch (e) {
      if (gen != _callGen) return; // superseded while joining — stay silent
      // Caller's own join failed (was mislabeled 'mic-denied' before). Surface
      // the real reason and notify the callee so neither side hangs.
      debugPrint('CallService: joinAgora failed (caller) - $e');
      lastError.value ??= '$e';
      _emit('call:end', {'toUserId': _peerUserId, 'callId': _callId});
      _endWith('failed');
    }
  }

  void _onRemoteEnd(Map<String, dynamic> data, String reason) {
    final callId = data['callId'];
    // The server always stamps callId; treat a missing one as non-matching so a
    // stray relay can never tear down whatever call happens to be current.
    if (callId == null || callId != _callId) return;
    if (status.value == CallStatus.idle) return;
    // A live call may only be ended by an explicit hang-up. Stray pre-answer
    // signals — a ghost session's reject/busy, a stale timeout — must never kill
    // it. While connecting, 'canceled' stays honored too (cancel-vs-accept race
    // relayed by old servers; new servers map it to 'ended').
    if (status.value == CallStatus.active && reason != 'ended') return;
    if (status.value == CallStatus.connecting &&
        reason != 'ended' &&
        reason != 'canceled') {
      return;
    }
    _endWith(reason);
  }

  /// The same account answered/declined this call on ANOTHER device. Dismiss the
  /// incoming ring here silently — no busy/ended tone and no "missed" state, since
  /// this device didn't miss anything; the call is simply owned elsewhere. Only
  /// applies while still ringing (never interrupt a call already active here).
  void _onHandledElsewhere(Map<String, dynamic> data) {
    final callId = data['callId'];
    if (callId == null || callId != _callId) return;
    // Dismiss while ringing (another device answered/declined) OR while connecting
    // (this device lost a simultaneous-answer race). Never touch an already-active
    // call — the winning device is excluded server-side and never receives this.
    if (status.value != CallStatus.ringing &&
        status.value != CallStatus.connecting) {
      return;
    }
    _dismissSilently();
  }

  void _dismissSilently() {
    _callGen++; // invalidate any in-flight _joinAgora for this call
    _ringTimer?.cancel();
    _ringTimer = null;
    _sound.stopRinging();
    // If we already started joining Agora (lost the answer race while connecting),
    // tear the engine down off the call stack — same deferred pattern as _endWith.
    final engine = _engine;
    _engine = null;
    if (engine != null) {
      _disposeEngineDeferred(engine);
    }
    _callId = null;
    _peerUserId = null;
    _isCaller = false;
    isMuted.value = false;
    isSpeakerOn.value = false;
    startedAt.value = null;
    endReason.value = null;
    lastError.value = null;
    status.value = CallStatus.idle;
    peer.value = null;
    if (Get.currentRoute == AppRoutes.call) {
      Get.back();
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Agora plumbing
  // ─────────────────────────────────────────────────────────────

  /// Join the call channel and publish the mic. The call goes "active" once the
  /// OTHER peer joins (see [onUserJoined]). May throw if the token fetch or
  /// engine init fails.
  Future<void> _joinAgora() async {
    // Generation captured on entry: if the call is dismissed/ended (or replaced)
    // while any await below is in flight, we back out silently — see _callGen.
    final gen = _callGen;

    // Never let two native audio engines own the mic at once: release the live
    // translation recorder (record/AudioRecord) before Agora initializes.
    // Simultaneous mic ownership hard-crashes the app on Android — the reason
    // mobile↔any calls closed the whole app while web↔web (one browser audio
    // session) was unaffected.
    await _releaseConflictingAudio();

    // Wait for any previous engine's deferred teardown to finish, then make sure
    // no live engine lingers, so createAgoraRtcEngine() never runs over another
    // native engine instance.
    final pending = _engineTeardown;
    _engineTeardown = null;
    if (pending != null) {
      try {
        await pending;
      } catch (_) {}
    }
    final stale = _engine;
    if (stale != null) {
      _engine = null;
      try {
        await stale.leaveChannel();
      } catch (_) {}
      try {
        await stale.release();
      } catch (_) {}
    }
    if (gen != _callGen) return; // call went away while we were preparing

    final creds = await _fetchAgoraToken();
    if (gen != _callGen) return; // superseded during the token fetch
    if (creds == null) {
      throw StateError('agora token unavailable');
    }
    final appId = creds['appId'] as String?;
    final channel = creds['channel'] as String?;
    final token = creds['token'] as String?;
    final uid = (creds['uid'] as num?)?.toInt() ?? 0;
    if (appId == null || channel == null || token == null) {
      throw StateError('agora token malformed');
    }

    // The engine stays LOCAL until fully joined: _endWith/_dismissSilently tear
    // down via _engine, and publishing a half-initialized engine would let a
    // concurrent deferred teardown race the in-flight native calls (the
    // two-native-engines hard-crash class). If we get superseded mid-join, WE
    // dispose this engine ourselves.
    final engine = createAgoraRtcEngine();
    try {
      await engine.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));
      await engine.enableAudio();
    } catch (e) {
      _disposeEngineDeferred(engine);
      if (gen != _callGen) return; // superseded: stay silent, no call:end
      rethrow;
    }
    if (gen != _callGen) {
      _disposeEngineDeferred(engine);
      return;
    }

    engine.registerEventHandler(RtcEngineEventHandler(
      onUserJoined: (connection, remoteUid, elapsed) {
        // The other party joined and is publishing → media is flowing.
        if (status.value != CallStatus.active) {
          status.value = CallStatus.active;
          startedAt.value ??= DateTime.now();
          _sound.stopRinging(); // safety: ensure no ring lingers
          _sound.playConnect(); // both parties hear the "connected" tone
        }
      },
      onUserOffline: (connection, remoteUid, reason) {
        if (status.value == CallStatus.active) _endWith('ended');
      },
      onError: (err, msg) {
        // Surface the Agora error code (e.g. errInvalidToken, errTokenExpired,
        // errJoinChannelRejected) instead of a silent print, so join/token
        // failures are diagnosable from the call state.
        lastError.value = '$err: $msg';
        debugPrint('CallService: Agora error $err - $msg');
      },
    ));

    try {
      await engine.joinChannel(
        token: token,
        channelId: channel,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
        ),
      );
    } catch (e) {
      _disposeEngineDeferred(engine);
      if (gen != _callGen) return; // superseded: stay silent, no call:end
      rethrow;
    }
    if (gen != _callGen) {
      // Dismissed while joining (e.g. lost a simultaneous-answer race): leave
      // the channel we just entered and stay silent.
      _disposeEngineDeferred(engine);
      return;
    }
    _engine = engine; // fully joined and still current → publish for teardown

    // Apply mute + speaker-routing intent. These are NON-FATAL: a routing hiccup
    // (some devices/Agora builds return an error from setEnableSpeakerphone) must
    // never fail the whole call — the join already succeeded above.
    try {
      if (isMuted.value) await engine.muteLocalAudioStream(true);
    } catch (e) {
      debugPrint('CallService: muteLocalAudioStream failed - $e');
    }
    try {
      await engine.setEnableSpeakerphone(isSpeakerOn.value);
    } catch (e) {
      debugPrint('CallService: setEnableSpeakerphone failed - $e');
    }
  }

  /// Fetch a short-lived Agora token for the current call from the backend.
  Future<Map<String, dynamic>?> _fetchAgoraToken() async {
    try {
      final res = await Get.find<ApiService>()
          .post('/agora-token', body: {'callId': _callId});
      if (res.isSuccess && res.data is Map) {
        return Map<String, dynamic>.from(res.data as Map);
      }
      debugPrint('CallService: agora-token error - ${res.errorMessage}');
    } catch (e) {
      debugPrint('CallService: fetchAgoraToken failed - $e');
    }
    return null;
  }

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Dispose an engine that never became (or no longer is) `_engine`, off the
  /// current call stack — same deferred pattern as `_endWith`, and chained into
  /// `_engineTeardown` so the next `_joinAgora` awaits it before creating a new
  /// native engine.
  void _disposeEngineDeferred(RtcEngine engine) {
    final previous = _engineTeardown;
    _engineTeardown = Future(() async {
      if (previous != null) {
        try {
          await previous;
        } catch (_) {}
      }
      try {
        await engine.leaveChannel();
      } catch (_) {}
      try {
        await engine.release();
      } catch (_) {}
    });
  }

  /// Stop the live-translation recorder (if running) and let its native audio
  /// session fully release before Agora grabs the mic. The translator captures
  /// the mic via the `record` package with no OS-level audio-session
  /// coordination, so an overlapping Agora init is a native crash on Android.
  Future<void> _releaseConflictingAudio() async {
    try {
      if (!Get.isRegistered<TranslatorController>()) return;
      final translator = Get.find<TranslatorController>();
      if (translator.isRecording.value) {
        await translator.stopRecording();
        // `record` resets AudioRecord to idle ~100ms after stop(); wait a touch
        // longer so the mic is provably free before Agora initializes.
        await Future.delayed(const Duration(milliseconds: 250));
      }
    } catch (e) {
      debugPrint('CallService: _releaseConflictingAudio failed - $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Teardown
  // ─────────────────────────────────────────────────────────────

  Future<void> _endWith(String reason) async {
    _callGen++; // invalidate any in-flight _joinAgora for this call
    // Capture call-scoped facts BEFORE the fields below are reset, so the right
    // teardown tone can be chosen.
    final wasActive = status.value == CallStatus.active;
    final wasCaller = _isCaller;

    _ringTimer?.cancel();
    _ringTimer = null;

    // Tones: stop any ring loop, then play the appropriate one-shot.
    //  • a call that was OPEN → the shared connect/end tone (both parties)
    //  • caller whose callee pressed busy/reject → the busy tone
    //  • cancel / no-answer / unavailable / failed → silence
    _sound.stopRinging();
    if (wasActive) {
      _sound.playEnd();
    } else if (wasCaller && (reason == 'busy' || reason == 'rejected')) {
      _sound.playBusy();
    }

    final engine = _engine;
    _engine = null;
    if (engine != null) {
      // Tear the engine down OFF the current call stack. `_endWith` can be invoked
      // from inside an Agora native event handler (onUserOffline / onError), and
      // calling release() / leaveChannel() synchronously from within such a
      // callback can deadlock or hard-crash the app on Android. The deferred
      // teardown is stored so the next `_joinAgora` awaits it before creating a
      // new engine.
      _disposeEngineDeferred(engine);
    }

    _callId = null;
    _peerUserId = null;
    _isCaller = false;
    isMuted.value = false;
    isSpeakerOn.value = false;
    startedAt.value = null;
    endReason.value = reason;
    status.value = CallStatus.ended;

    // Close the call screen shortly after showing the "ended" state.
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (status.value == CallStatus.ended) {
        status.value = CallStatus.idle;
        endReason.value = null;
        peer.value = null;
      }
      if (Get.currentRoute == AppRoutes.call) {
        Get.back();
      }
    });
  }

  void _openCallUi() {
    if (Get.currentRoute != AppRoutes.call) {
      Get.toNamed(AppRoutes.call);
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────────────────────

  void _emit(String event, Map<String, dynamic> data) {
    if (!Get.isRegistered<SocketService>()) return;
    Get.find<SocketService>().emit(event, data);
  }

  String _generateCallId(int peerId) =>
      '${DateTime.now().microsecondsSinceEpoch}-$peerId';

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  @override
  void onClose() {
    if (Get.isRegistered<SocketService>()) {
      final socket = Get.find<SocketService>();
      for (final event in [
        'call:incoming',
        'call:accepted',
        'call:handled',
        'call:rejected',
        'call:canceled',
        'call:busy',
        'call:unavailable',
        'call:ended',
      ]) {
        socket.off(event, _listenerId);
      }
    }
    _endWith('ended');
    _sound.disposeAll();
    super.onClose();
  }
}
