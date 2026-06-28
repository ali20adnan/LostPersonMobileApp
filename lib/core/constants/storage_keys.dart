class StorageKeys {
  // Hive boxes
  static const String conversationsBox = 'conversations';
  static const String settingsBox = 'settings';

  // Settings keys
  static const String selectedSourceLanguage = 'selected_source_language';
  static const String selectedTargetLanguage = 'selected_target_language';
  static const String ttsEnabled = 'tts_enabled';
  static const String ttsRate = 'tts_rate';
  static const String ttsPitch = 'tts_pitch';
  static const String themeMode = 'theme_mode';
  static const String apiKey = 'api_key';
  static const String autoSaveConversations = 'auto_save_conversations';
  static const String autoDetectLanguage = 'settings_auto_detect_language';
  // Matches the legacy raw-SharedPreferences key already used by
  // SettingsController so the existing saved value is preserved.
  static const String notificationsEnabled = 'settings_notifications';

  // Secure storage keys
  static const String secureApiKey = 'secure_api_key';

  // Usage tracking
  static const String totalUsageMinutes = 'total_usage_minutes';
  static const String lastUsageDate = 'last_usage_date';
}
