import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // ── Backend API ────────────────────────────────────────────────
  static const String apiBaseUrl = 'https://api.almuntazer.net/losts/api';

  /// Server root (without /api) – used for static files like uploads
  static const String serverBaseUrl = 'https://api.almuntazer.net/losts';

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Missing Person Reports
  static const String missingPersonReports = '/missing-person-reports';
  static const String missingPersonReportSearch =
      '/missing-person-reports/search';

  // Alerts (sightings / tips)
  static const String alerts = '/alerts';

  // Reports (emergency / other)
  static const String reports = '/reports';

  // Governorates
  static const String governorates = '/governorates';

  // Persons
  static const String persons = '/persons';

  // Locations
  static const String locations = '/locations';

  // Attachments
  static const String attachments = '/attachments';

  // Conversations & Messaging
  static const String conversations = '/conversations';
  static const String conversationUsers = '/conversations/users';
  static const String messagesUnreadCount = '/conversations/unread/count';

  // Alert notification endpoints
  static const String alertsUnreadCount = '/alerts/unread/count';
  static const String alertsReadAll = '/alerts/read-all';

  // ── Soniox API ─────────────────────────────────────────────────
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

  /// Resolve an avatar URL from the backend.
  /// Handles: null, "undefined", full URLs, and relative paths.
  static String? resolveAvatarUrl(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'undefined' || raw == 'null') {
      return null;
    }
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    return '$serverBaseUrl$raw';
  }

  // Reconnection settings
  static const int maxReconnectAttempts = 5;
  static const List<int> reconnectDelaysMs = [1000, 2000, 4000, 8000, 30000];

  // Session limits
  static const int maxSessionDurationMinutes = 30;
  static const int audioBufferDurationSeconds = 10;
}
