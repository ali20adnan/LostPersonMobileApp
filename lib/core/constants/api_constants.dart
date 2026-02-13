import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // Soniox API
  static String get sonioxApiKey => dotenv.env['SONIOX_API_KEY'] ?? '';
  static String get sonioxWebSocketUrl =>
      dotenv.env['SONIOX_WEBSOCKET_URL'] ??
      'wss://stt-rt.soniox.com/transcribe-websocket';

  // Soniox configuration
  static const String sonioxModel = 'stt-rt-v4';
  static const String audioFormat = 's16le';
  static const int numChannels = 1;
  static const int sampleRate = 16000;
  static const int audioChunkSize = 4096;

  // Translation mode
  static const String translationMode = 'two_way';

  // Reconnection settings
  static const int maxReconnectAttempts = 5;
  static const List<int> reconnectDelaysMs = [1000, 2000, 4000, 8000, 30000];

  // Session limits
  static const int maxSessionDurationMinutes = 30;
  static const int audioBufferDurationSeconds = 10;
}
