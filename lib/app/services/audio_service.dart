import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import '../../core/constants/api_constants.dart';

enum RecordingState { idle, recording, paused, stopped }

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamController<Uint8List>? _audioStreamController;
  StreamController<double>? _amplitudeController;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  RecordingState _state = RecordingState.idle;
  Timer? _amplitudeTimer;

  // Callback for audio chunks (for audio file storage)
  void Function(Uint8List)? onAudioChunk;

  // Getters
  RecordingState get state => _state;
  Stream<Uint8List>? get audioStream => _audioStreamController?.stream;
  Stream<double>? get amplitudeStream => _amplitudeController?.stream;
  bool get isRecording => _state == RecordingState.recording;

  /// Initialize the audio service
  void init() {
    _audioStreamController = StreamController<Uint8List>.broadcast();
    _amplitudeController = StreamController<double>.broadcast();
  }

  /// Check if recording is supported
  Future<bool> isRecordingSupported() async {
    return await _recorder.hasPermission();
  }

  /// Start recording with PCM16 format for Soniox
  Future<bool> startRecording() async {
    try {
      debugPrint('───────────────────────────────────────────────────────');
      debugPrint('AudioService: START RECORDING CALLED');
      debugPrint('───────────────────────────────────────────────────────');

      if (_state == RecordingState.recording) {
        debugPrint('AudioService: ⚠️ Already recording, returning true');
        return true;
      }

      // Check permission
      debugPrint('AudioService: Checking recording permission...');
      final hasPermission = await _recorder.hasPermission();
      debugPrint('AudioService: Permission = $hasPermission');

      if (!hasPermission) {
        debugPrint('AudioService: ✗ NO PERMISSION TO RECORD');
        return false;
      }
      debugPrint('AudioService: ✓ Has permission to record');

      // Configure recording for Soniox requirements
      // PCM16, 16kHz, mono
      debugPrint('AudioService: Configuring audio recording...');
      debugPrint('  Encoder: PCM16');
      debugPrint('  Sample Rate: ${ApiConstants.sampleRate}Hz');
      debugPrint('  Channels: ${ApiConstants.numChannels}');
      debugPrint('  Bit Rate: 128000');

      final config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: ApiConstants.sampleRate,
        numChannels: ApiConstants.numChannels,
        bitRate: 128000,
      );

      // Start recording with stream
      debugPrint('AudioService: Starting audio stream...');
      final stream = await _recorder.startStream(config);
      debugPrint('AudioService: ✓ Audio stream started');

      // Listen to audio stream
      debugPrint('AudioService: Setting up audio stream listener...');
      int chunkCount = 0;
      int totalBytes = 0;

      stream.listen(
        (data) {
          if (_state == RecordingState.recording) {
            chunkCount++;
            totalBytes += data.length;

            // Log every 50th chunk to avoid spam (roughly every 2-3 seconds)
            if (chunkCount % 50 == 0) {
              debugPrint('AudioService: 🎤 Audio chunk #$chunkCount received (${data.length} bytes, total: ${totalBytes} bytes)');
            }

            _audioStreamController?.add(data);

            // Call audio chunk callback for storage
            onAudioChunk?.call(data);
          }
        },
        onError: (error) {
          debugPrint('AudioService: ✗ STREAM ERROR - $error');
          stopRecording();
        },
        onDone: () {
          debugPrint('AudioService: Stream completed (done)');
        },
        cancelOnError: false,
      );
      debugPrint('AudioService: ✓ Stream listener configured');

      // Start amplitude monitoring
      _startAmplitudeMonitoring();
      debugPrint('AudioService: ✓ Amplitude monitoring started');

      _state = RecordingState.recording;
      debugPrint('───────────────────────────────────────────────────────');
      debugPrint('AudioService: ✓✓✓ RECORDING STARTED SUCCESSFULLY ✓✓✓');
      debugPrint('  Format: PCM16, 16kHz, Mono');
      debugPrint('───────────────────────────────────────────────────────');
      return true;
    } catch (e, stackTrace) {
      debugPrint('───────────────────────────────────────────────────────');
      debugPrint('AudioService: ✗✗✗ ERROR STARTING RECORDING ✗✗✗');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('───────────────────────────────────────────────────────');
      return false;
    }
  }

  /// Start monitoring audio amplitude for visualizer
  void _startAmplitudeMonitoring() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) async {
        if (_state != RecordingState.recording) {
          timer.cancel();
          return;
        }

        try {
          final amplitude = await _recorder.getAmplitude();
          if (amplitude.current.isFinite) {
            // Normalize amplitude to 0-1 range
            final normalized = (amplitude.current + 50) / 50;
            final clamped = normalized.clamp(0.0, 1.0);
            _amplitudeController?.add(clamped);
          }
        } catch (e) {
          // Ignore amplitude errors
        }
      },
    );
  }

  /// Pause recording
  Future<void> pauseRecording() async {
    if (_state != RecordingState.recording) {
      return;
    }

    try {
      await _recorder.pause();
      _state = RecordingState.paused;
      _amplitudeTimer?.cancel();
      debugPrint('AudioService: Recording paused');
    } catch (e) {
      debugPrint('AudioService: Error pausing recording - $e');
    }
  }

  /// Resume recording
  Future<void> resumeRecording() async {
    if (_state != RecordingState.paused) {
      return;
    }

    try {
      await _recorder.resume();
      _state = RecordingState.recording;
      _startAmplitudeMonitoring();
      debugPrint('AudioService: Recording resumed');
    } catch (e) {
      debugPrint('AudioService: Error resuming recording - $e');
    }
  }

  /// Stop recording
  Future<void> stopRecording() async {
    if (_state == RecordingState.idle || _state == RecordingState.stopped) {
      return;
    }

    try {
      await _recorder.stop();
      _amplitudeTimer?.cancel();
      _amplitudeSubscription?.cancel();

      _state = RecordingState.stopped;
      debugPrint('AudioService: Recording stopped');

      // Reset to idle after a brief delay
      await Future.delayed(const Duration(milliseconds: 100));
      _state = RecordingState.idle;
    } catch (e) {
      debugPrint('AudioService: Error stopping recording - $e');
      _state = RecordingState.idle;
    }
  }

  /// Get current audio level (0.0 to 1.0)
  Future<double> getCurrentAmplitude() async {
    try {
      final amplitude = await _recorder.getAmplitude();
      if (amplitude.current.isFinite) {
        final normalized = (amplitude.current + 50) / 50;
        return normalized.clamp(0.0, 1.0);
      }
    } catch (e) {
      // Ignore errors
    }
    return 0.0;
  }

  /// Check if microphone is available
  Future<bool> isMicrophoneAvailable() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      return false;
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    _amplitudeTimer?.cancel();
    _amplitudeSubscription?.cancel();

    if (_state == RecordingState.recording || _state == RecordingState.paused) {
      await stopRecording();
    }

    await _recorder.dispose();
    await _audioStreamController?.close();
    await _amplitudeController?.close();

    debugPrint('AudioService: Disposed');
  }

  /// Get recording duration
  Future<Duration> getRecordingDuration() async {
    // Note: record package doesn't provide duration directly
    // You would need to track this manually in the controller
    return Duration.zero;
  }
}
