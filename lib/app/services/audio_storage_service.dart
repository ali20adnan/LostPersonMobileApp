import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:wav/wav.dart';

/// Service for storing audio recordings to WAV files
class AudioStorageService {
  // Buffer for accumulating audio chunks during recording
  final List<Uint8List> _audioBuffer = [];
  DateTime? _recordingStartTime;

  // Audio configuration (matches AudioService settings)
  static const int sampleRate = 16000;
  static const int numChannels = 1;

  /// Initialize service - create directories if needed
  Future<void> init() async {
    try {
      final audioDir = await _getAudioDirectory();
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
        debugPrint(
            'AudioStorageService: Created audio directory at ${audioDir.path}');
      }
    } catch (e) {
      debugPrint('AudioStorageService: Error initializing - $e');
    }
  }

  /// Get audio storage directory for today
  Future<Directory> _getAudioDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final today = DateTime.now();
    final dateFolder =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return Directory(
        path.join(appDir.path, 'audio', 'conversations', dateFolder));
  }

  /// Start buffering audio chunks for a new conversation
  void startRecording() {
    _audioBuffer.clear();
    _recordingStartTime = DateTime.now();
    debugPrint('AudioStorageService: Started buffering audio');
  }

  /// Add audio chunk to buffer
  void addAudioChunk(Uint8List chunk) {
    if (_recordingStartTime != null) {
      _audioBuffer.add(Uint8List.fromList(chunk));
    }
  }

  /// Stop recording and save to WAV file
  Future<String?> stopAndSaveRecording(String conversationId) async {
    try {
      if (_audioBuffer.isEmpty) {
        debugPrint('AudioStorageService: No audio data to save');
        return null;
      }

      debugPrint(
          'AudioStorageService: Saving ${_audioBuffer.length} audio chunks');

      // Concatenate all audio chunks
      final totalLength =
          _audioBuffer.fold<int>(0, (sum, chunk) => sum + chunk.length);
      final audioData = Uint8List(totalLength);
      int offset = 0;
      for (var chunk in _audioBuffer) {
        audioData.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }

      debugPrint(
          'AudioStorageService: Total audio data: ${audioData.length} bytes');

      // Convert PCM16 bytes to Int16 samples, then to Float64 for wav package
      final numSamples = audioData.length ~/ 2; // 2 bytes per sample (16-bit)
      final samples = Float64List(numSamples);

      for (int i = 0; i < numSamples; i++) {
        // Read int16 sample in little-endian format
        final int16Value = audioData[i * 2] | (audioData[i * 2 + 1] << 8);
        // Convert to signed int16 (-32768 to 32767)
        final signedInt16 =
            int16Value > 32767 ? int16Value - 65536 : int16Value;
        // Normalize to -1.0 to 1.0 range
        samples[i] = signedInt16 / 32768.0;
      }

      // Create WAV file
      final wav = Wav([samples], sampleRate);

      // Get file path
      final audioDir = await _getAudioDirectory();
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final fileName = '$conversationId.wav';
      final filePath = path.join(audioDir.path, fileName);
      final file = File(filePath);

      // Write WAV file
      await wav.writeFile(filePath);

      debugPrint('AudioStorageService: Audio saved to $filePath');
      debugPrint('  File size: ${await file.length()} bytes');

      // Clear buffer
      _audioBuffer.clear();
      _recordingStartTime = null;

      return filePath;
    } catch (e, stackTrace) {
      debugPrint('AudioStorageService: Error saving audio - $e');
      debugPrint('Stack trace: $stackTrace');
      _audioBuffer.clear();
      _recordingStartTime = null;
      return null;
    }
  }

  /// Cancel recording without saving
  void cancelRecording() {
    _audioBuffer.clear();
    _recordingStartTime = null;
    debugPrint('AudioStorageService: Recording cancelled');
  }

  /// Delete audio file
  Future<bool> deleteAudioFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) {
      return false;
    }

    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('AudioStorageService: Deleted audio file: $filePath');
        return true;
      }
    } catch (e) {
      debugPrint('AudioStorageService: Error deleting audio file - $e');
    }
    return false;
  }

  /// Check if audio file exists
  Future<bool> audioFileExists(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return false;
    return await File(filePath).exists();
  }

  /// Get audio file size in bytes
  Future<int?> getAudioFileSize(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return null;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      debugPrint('AudioStorageService: Error getting file size - $e');
    }
    return null;
  }
}
