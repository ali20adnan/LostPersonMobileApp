import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Plays the call ringtones / sound-effects for [CallService].
///
/// Two players: one looping (ring tones during calling/ringing) and one
/// one-shot (connect / end / busy). Every call is wrapped in try/catch — a
/// tone must NEVER be able to disrupt or fail the actual call.
///
/// Assets live under `assets/sounds/` (registered in pubspec) and are addressed
/// via [AssetSource], which prepends `assets/`.
class CallSoundService extends GetxService {
  final AudioPlayer _loopPlayer = AudioPlayer(playerId: 'call_ring');
  final AudioPlayer _sfxPlayer = AudioPlayer(playerId: 'call_sfx');

  static const _outgoingRing = 'sounds/outgoing_ring.mp3';
  static const _incomingRing = 'sounds/incoming_ring.mp3';
  static const _connectEnd = 'sounds/call_connect_end.mp3';
  static const _busy = 'sounds/busy.mp3';

  Future<CallSoundService> init() async {
    try {
      await _loopPlayer.setReleaseMode(ReleaseMode.loop);
      await _sfxPlayer.setReleaseMode(ReleaseMode.release);
    } catch (e) {
      debugPrint('CallSoundService: init failed - $e');
    }
    return this;
  }

  // ── ring loops ────────────────────────────────────────────────
  Future<void> startOutgoingRing() => _startLoop(_outgoingRing);
  Future<void> startIncomingRing() => _startLoop(_incomingRing);

  Future<void> _startLoop(String asset) async {
    try {
      await _loopPlayer.stop();
      await _loopPlayer.play(AssetSource(asset));
    } catch (e) {
      debugPrint('CallSoundService: startLoop($asset) failed - $e');
    }
  }

  Future<void> stopRinging() async {
    try {
      await _loopPlayer.stop();
    } catch (e) {
      debugPrint('CallSoundService: stopRinging failed - $e');
    }
  }

  // ── one-shots ─────────────────────────────────────────────────
  /// Both parties hear this the moment the call opens.
  Future<void> playConnect() => _playSfx(_connectEnd);

  /// Both parties hear this when a call that was open is closed (same asset).
  Future<void> playEnd() => _playSfx(_connectEnd);

  /// Caller-only: recipient pressed busy/reject.
  Future<void> playBusy() => _playSfx(_busy);

  Future<void> _playSfx(String asset) async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(asset));
    } catch (e) {
      debugPrint('CallSoundService: playSfx($asset) failed - $e');
    }
  }

  /// Stop everything immediately (used when the call tears down).
  Future<void> stopAll() async {
    try {
      await _loopPlayer.stop();
    } catch (_) {}
    try {
      await _sfxPlayer.stop();
    } catch (_) {}
  }

  Future<void> disposeAll() async {
    try {
      await _loopPlayer.dispose();
    } catch (_) {}
    try {
      await _sfxPlayer.dispose();
    } catch (_) {}
  }
}
