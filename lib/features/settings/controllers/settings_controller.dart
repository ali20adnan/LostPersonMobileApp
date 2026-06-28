import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/services/storage_service.dart';

class SettingsController extends GetxController {
  static const _darkModeKey = 'settings_dark_mode';

  // StorageService is the source of truth for non-theme prefs so the
  // consumers (TranslationRepository, SonioxService, notifications
  // bootstrap, etc.) can read the same values without duplicating keys.
  final StorageService _storage = Get.find<StorageService>();

  final isDarkMode = false.obs;
  final isNotificationsEnabled = true.obs;
  final isAutoDetectLanguage = true.obs;
  final isAutoSpeakEnabled = false.obs;
  final isAutoSaveConversations = true.obs;

  /// Installed app version, read from the platform package metadata
  /// (pubspec `version: x.y.z+build`). Shown read-only in Settings.
  final appVersion = '...'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion.value = '${info.version} (${info.buildNumber})';
    } catch (_) {
      // Leave the placeholder if metadata is unavailable.
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool(_darkModeKey) ?? false;
    isNotificationsEnabled.value = _storage.getNotificationsEnabled();
    isAutoDetectLanguage.value = _storage.getAutoDetectLanguage();
    isAutoSaveConversations.value = _storage.getAutoSaveConversations();
    isAutoSpeakEnabled.value =
        await _storage.getTtsEnabled(defaultValue: false);

    // Apply saved theme
    Get.changeThemeMode(
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
    );
  }

  Future<void> toggleDarkMode(bool value) async {
    isDarkMode.value = value;
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  Future<void> toggleNotifications(bool value) async {
    isNotificationsEnabled.value = value;
    await _storage.saveNotificationsEnabled(value);
  }

  Future<void> toggleAutoDetectLanguage(bool value) async {
    isAutoDetectLanguage.value = value;
    await _storage.saveAutoDetectLanguage(value);
  }

  Future<void> toggleAutoSpeak(bool value) async {
    isAutoSpeakEnabled.value = value;
    await _storage.saveTtsEnabled(value);
  }

  Future<void> toggleAutoSaveConversations(bool value) async {
    isAutoSaveConversations.value = value;
    await _storage.saveAutoSaveConversations(value);
  }
}
