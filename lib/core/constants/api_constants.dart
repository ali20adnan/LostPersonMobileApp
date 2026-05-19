import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // ── Backend API ────────────────────────────────────────────────
  /// Backend REST API base URL.
  /// Override via .env `API_BASE_URL` (e.g. http://10.0.2.2:3003/api for Android emulator).
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://lostpersons.askdevelopers.online/api';

  /// Server root for static files (images, avatars, etc.)
  static String get filesBaseUrl =>
      dotenv.env['FILES_BASE_URL'] ?? 'https://lostpersons.askdevelopers.online/uploads/losts';

  static String get uploadsBaseUrl {
    final normalized = filesBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return normalized.endsWith('/losts')
        ? normalized.substring(0, normalized.length - 6)
        : normalized;
  }

  /// Server root (without /api) – used for sockets and some relative paths.
  /// Override via .env `SERVER_BASE_URL` (e.g. http://10.0.2.2:3003 for Android emulator).
  static String get serverBaseUrl =>
      dotenv.env['SERVER_BASE_URL'] ?? 'https://lostpersons.askdevelopers.online';

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Missing Person Reports
  static const String missingPersonReports = '/missing-persons';
  static const String missingPersonReportSearch =
      '/missing-persons/search';

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
  static const String messagesUnreadCount = '/messages/unread-count';

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

  // ── LibreTranslate API ─────────────────────────────────────────
  static String get libreTranslateUrl =>
      dotenv.env['LIBRE_TRANSLATE_URL'] ?? 'https://libretranslate.com/translate';
  static String get libreTranslateApiKey =>
      dotenv.env['LIBRE_TRANSLATE_API_KEY'] ?? '';

  /// Resolve an avatar URL from the backend.
  /// Handles: null, "undefined", full URLs, and relative paths.
  static String? resolveAvatarUrl(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'undefined' || raw == 'null') {
      return null;
    }
    
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    
    // 1. تنظيف المسار من أي شرطة مائلة في البداية
    String cleanPath = raw.startsWith('/') ? raw.substring(1) : raw;
    
    // 2. حل مشكلة التكرار: إذا كان المسار يبدأ بـ "losts/" والرابط الأساسي ينتهي بـ "losts"
    // نقوم بحذف الجزء المكرر من المسار
    if (filesBaseUrl.endsWith('losts') && cleanPath.startsWith('losts/')) {
      cleanPath = cleanPath.substring(6); // حذف "losts/"
    }
    
    // 3. تأكد أيضاً من عدم تكرار "uploads/losts" بالكامل
    if (filesBaseUrl.endsWith('uploads/losts') && cleanPath.startsWith('uploads/losts/')) {
      cleanPath = cleanPath.substring(14); // حذف "uploads/losts/"
    }

    return '$filesBaseUrl/$cleanPath';
  }

  /// Resolve a file URL served from the backend uploads route.
  static String? resolveUploadUrl(String? raw, {String? localFolder}) {
    if (raw == null || raw.isEmpty || raw == 'undefined' || raw == 'null') {
      return null;
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    var cleanPath = raw.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');

    if (cleanPath.startsWith('uploads/')) {
      cleanPath = cleanPath.substring('uploads/'.length);
    }

    if (cleanPath.startsWith('losts/reports/')) {
      cleanPath =
          'losts/other/${cleanPath.substring('losts/reports/'.length)}';
    } else if (cleanPath.startsWith('reports/')) {
      cleanPath = 'losts/other/${cleanPath.substring('reports/'.length)}';
    }

    if (cleanPath.startsWith('losts/')) {
      return '$uploadsBaseUrl/$cleanPath';
    }

    if (localFolder != null && localFolder.isNotEmpty && !cleanPath.contains('/')) {
      final normalizedFolder = localFolder
          .replaceAll('\\', '/')
          .replaceAll(RegExp(r'^/+|/+$'), '');
      cleanPath = '$normalizedFolder/$cleanPath';
    }

    return '$filesBaseUrl/$cleanPath';
  }

  // Reconnection settings
  static const int maxReconnectAttempts = 5;
  static const List<int> reconnectDelaysMs = [1000, 2000, 4000, 8000, 30000];

  // Session limits
  static const int maxSessionDurationMinutes = 30;
  static const int audioBufferDurationSeconds = 10;
}
