import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

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

    try {
      await _joinAgora();
    } catch (e) {
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
    try {
      await _joinAgora();
    } catch (e) {
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
    if (callId != null && callId != _callId) return;
    if (status.value == CallStatus.idle) return;
    _endWith(reason);
  }

  // ─────────────────────────────────────────────────────────────
  //  Agora plumbing
  // ─────────────────────────────────────────────────────────────

  /// Join the call channel and publish the mic. The call goes "active" once the
  /// OTHER peer joins (see [onUserJoined]). May throw if the token fetch or
  /// engine init fails.
  Future<void> _joinAgora() async {
    final creds = await _fetchAgoraToken();
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

    final engine = createAgoraRtcEngine();
    _engine = engine;
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));
    await engine.enableAudio();

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

  // ─────────────────────────────────────────────────────────────
  //  Teardown
  // ─────────────────────────────────────────────────────────────

  Future<void> _endWith(String reason) async {
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
      // callback can deadlock or hard-crash the app on Android. Scheduling it as a
      // fresh event-loop task lets the native callback unwind first.
      Future(() async {
        try {
          await engine.leaveChannel();
        } catch (_) {}
        try {
          await engine.release();
        } catch (_) {}
      });
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
