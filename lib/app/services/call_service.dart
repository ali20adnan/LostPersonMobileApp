import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
// `navigator` is exported by both flutter_webrtc (MediaDevices) and GetX; we use
// the WebRTC one for getUserMedia, so hide GetX's.
import 'package:get/get.dart' hide navigator;
import 'package:permission_handler/permission_handler.dart';

import '../routes/app_routes.dart';
import 'api_service.dart';
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

/// 1:1 audio call service (WebRTC over the shared Socket.IO signaling channel).
///
/// Signaling rides [SocketService] (`call:*` events); the audio itself is a
/// peer-to-peer [RTCPeerConnection] relayed through TURN when direct fails.
///
/// Scope (v1): audio only, 1:1 only, foreground only.
class CallService extends GetxService {
  static const _listenerId = 'call_service';
  static const _ringTimeout = Duration(seconds: 30);
  static const _fallbackIce = [
    {'urls': 'stun:stun.l.google.com:19302'},
  ];

  // ── reactive state ────────────────────────────────────────────
  final status = CallStatus.idle.obs;
  final Rxn<CallPeer> peer = Rxn<CallPeer>();
  final isMuted = false.obs;
  final startedAt = Rxn<DateTime>();
  final endReason = RxnString();

  // ── call bookkeeping ──────────────────────────────────────────
  String? _callId;
  int? _peerUserId;
  bool _isCaller = false;

  // ── WebRTC objects ────────────────────────────────────────────
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final _pendingCandidates = <RTCIceCandidate>[];
  Timer? _ringTimer;

  bool get inCall => status.value != CallStatus.idle && status.value != CallStatus.ended;

  /// The remote party's audio stream (retained so the track isn't GC'd; audio
  /// plays automatically on mobile once received).
  MediaStream? get remoteStream => _remoteStream;

  Future<CallService> init() async {
    _registerSocketListeners();
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

    _callId = _generateCallId();
    _peerUserId = toUserId;
    _isCaller = true;
    peer.value = callee;
    endReason.value = null;
    startedAt.value = null;
    isMuted.value = false;
    status.value = CallStatus.calling;

    _emit('call:invite', {
      'toUserId': toUserId,
      'conversationId': conversationId,
      'callId': _callId,
    });

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

    try {
      // Build the peer connection BEFORE accepting so we're ready for the offer.
      await _buildPeer();
    } catch (e) {
      debugPrint('CallService: buildPeer failed - $e');
      _emit('call:reject', {'toUserId': _peerUserId, 'callId': _callId, 'reason': 'mic'});
      _endWith('mic-denied');
      return;
    }

    status.value = CallStatus.connecting;
    _emit('call:accept', {'toUserId': _peerUserId, 'callId': _callId});
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
    final tracks = _localStream?.getAudioTracks() ?? [];
    if (tracks.isEmpty) return;
    final enabled = tracks.any((t) => t.enabled);
    for (final t in tracks) {
      t.enabled = !enabled;
    }
    isMuted.value = enabled; // muted == tracks now disabled
  }

  // ─────────────────────────────────────────────────────────────
  //  Signaling
  // ─────────────────────────────────────────────────────────────

  void _registerSocketListeners() {
    if (!Get.isRegistered<SocketService>()) return;
    final socket = Get.find<SocketService>();

    socket.on('call:incoming', _listenerId, (data) => _onIncoming(_asMap(data)));
    socket.on('call:accepted', _listenerId, (data) => _onAccepted(_asMap(data)));
    socket.on('call:offer', _listenerId, (data) => _onOffer(_asMap(data)));
    socket.on('call:answer', _listenerId, (data) => _onAnswer(_asMap(data)));
    socket.on('call:ice', _listenerId, (data) => _onRemoteIce(_asMap(data)));
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
    startedAt.value = null;
    isMuted.value = false;
    status.value = CallStatus.ringing;

    _openCallUi();

    _ringTimer = Timer(_ringTimeout, () {
      if (status.value == CallStatus.ringing) {
        _emit('call:reject', {'toUserId': _peerUserId, 'callId': _callId, 'reason': 'timeout'});
        _endWith('no-answer');
      }
    });
  }

  // Caller: callee accepted → create & send the offer.
  Future<void> _onAccepted(Map<String, dynamic> data) async {
    if (data['callId'] != _callId || !_isCaller) return;
    _ringTimer?.cancel();

    final granted = await _ensureMicPermission();
    if (!granted) {
      _emit('call:end', {'toUserId': _peerUserId, 'callId': _callId});
      _endWith('mic-denied');
      return;
    }

    status.value = CallStatus.connecting;
    try {
      await _buildPeer();
      final offer = await _pc!.createOffer({});
      await _pc!.setLocalDescription(offer);
      _emit('call:offer', {
        'toUserId': _peerUserId,
        'callId': _callId,
        'sdp': offer.toMap(),
      });
    } catch (e) {
      debugPrint('CallService: offer failed - $e');
      _emit('call:end', {'toUserId': _peerUserId, 'callId': _callId});
      _endWith('failed');
    }
  }

  // Callee: received the offer → answer.
  Future<void> _onOffer(Map<String, dynamic> data) async {
    if (data['callId'] != _callId || _isCaller || _pc == null) return;
    try {
      final sdp = _asMap(data['sdp']);
      await _pc!.setRemoteDescription(
        RTCSessionDescription(sdp['sdp'] as String?, sdp['type'] as String?),
      );
      await _flushPendingCandidates();
      final answer = await _pc!.createAnswer({});
      await _pc!.setLocalDescription(answer);
      _emit('call:answer', {
        'toUserId': _peerUserId,
        'callId': _callId,
        'sdp': answer.toMap(),
      });
    } catch (e) {
      debugPrint('CallService: answer failed - $e');
      _endWith('failed');
    }
  }

  // Caller: received the answer.
  Future<void> _onAnswer(Map<String, dynamic> data) async {
    if (data['callId'] != _callId || !_isCaller || _pc == null) return;
    try {
      final sdp = _asMap(data['sdp']);
      await _pc!.setRemoteDescription(
        RTCSessionDescription(sdp['sdp'] as String?, sdp['type'] as String?),
      );
      await _flushPendingCandidates();
    } catch (e) {
      debugPrint('CallService: setRemote(answer) failed - $e');
      _endWith('failed');
    }
  }

  // Both: trickle ICE.
  Future<void> _onRemoteIce(Map<String, dynamic> data) async {
    if (data['callId'] != _callId) return;
    final c = _asMap(data['candidate']);
    final candidate = RTCIceCandidate(
      c['candidate'] as String?,
      c['sdpMid'] as String?,
      c['sdpMLineIndex'] as int?,
    );
    if (_pc != null && await _hasRemoteDescription()) {
      try {
        await _pc!.addCandidate(candidate);
      } catch (_) {/* ignore bad candidate */}
    } else {
      _pendingCandidates.add(candidate);
    }
  }

  void _onRemoteEnd(Map<String, dynamic> data, String reason) {
    final callId = data['callId'];
    if (callId != null && callId != _callId) return;
    if (status.value == CallStatus.idle) return;
    _endWith(reason);
  }

  // ─────────────────────────────────────────────────────────────
  //  WebRTC plumbing
  // ─────────────────────────────────────────────────────────────

  Future<void> _buildPeer() async {
    final config = {
      'iceServers': await _fetchIceServers(),
      'sdpSemantics': 'unified-plan',
    };
    final pc = await createPeerConnection(config);

    pc.onIceCandidate = (candidate) {
      _emit('call:ice', {
        'toUserId': _peerUserId,
        'callId': _callId,
        'candidate': candidate.toMap(),
      });
    };
    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
      }
    };
    pc.onConnectionState = (state) {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          if (status.value != CallStatus.active) {
            status.value = CallStatus.active;
            startedAt.value ??= DateTime.now();
          }
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _endWith('failed');
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          if (status.value == CallStatus.active) _endWith('ended');
          break;
        default:
          break;
      }
    };

    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
    _localStream = stream;
    for (final track in stream.getTracks()) {
      await pc.addTrack(track, stream);
    }

    _pc = pc;
  }

  Future<bool> _hasRemoteDescription() async {
    try {
      final desc = await _pc!.getRemoteDescription();
      return desc != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _flushPendingCandidates() async {
    if (_pc == null) return;
    final pending = List<RTCIceCandidate>.from(_pendingCandidates);
    _pendingCandidates.clear();
    for (final c in pending) {
      try {
        await _pc!.addCandidate(c);
      } catch (_) {/* ignore */}
    }
  }

  Future<List<Map<String, dynamic>>> _fetchIceServers() async {
    try {
      final res = await Get.find<ApiService>().get('/turn-credentials');
      if (res.isSuccess && res.data is Map<String, dynamic>) {
        final list = (res.data as Map<String, dynamic>)['iceServers'];
        if (list is List) {
          return list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('CallService: fetchIceServers failed - $e');
    }
    return List<Map<String, dynamic>>.from(_fallbackIce);
  }

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // ─────────────────────────────────────────────────────────────
  //  Teardown
  // ─────────────────────────────────────────────────────────────

  Future<void> _endWith(String reason) async {
    _ringTimer?.cancel();
    _ringTimer = null;

    _localStream?.getTracks().forEach((t) => t.stop());
    await _localStream?.dispose();
    _localStream = null;
    _remoteStream = null;
    _pendingCandidates.clear();
    if (_pc != null) {
      try {
        await _pc!.close();
      } catch (_) {}
      _pc = null;
    }

    _callId = null;
    _peerUserId = null;
    _isCaller = false;
    isMuted.value = false;
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

  String _generateCallId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_peerUserId ?? 0}';

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
        'call:offer',
        'call:answer',
        'call:ice',
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
    super.onClose();
  }
}
