import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/api_constants.dart';
import '../../core/widgets/update_dialog.dart';

/// Parsed response of `GET /api/app/version`.
class AppVersionInfo {
  final String latestVersion;
  final int latestBuild;
  final int minBuild;
  final String downloadUrl;
  final String changelog;

  const AppVersionInfo({
    required this.latestVersion,
    required this.latestBuild,
    required this.minBuild,
    required this.downloadUrl,
    required this.changelog,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    return AppVersionInfo(
      latestVersion: json['latestVersion']?.toString() ?? '',
      latestBuild: asInt(json['latestBuild']),
      minBuild: asInt(json['minBuild']),
      downloadUrl: json['downloadUrl']?.toString() ?? '',
      changelog: json['changelog']?.toString() ?? '',
    );
  }
}

/// OTA "version gate": on startup, asks the API for the latest build and — if
/// the installed build is older — shows an update dialog. On Android the dialog
/// downloads the new APK in-app and launches the installer; on iOS it opens the
/// distribution page (Apple forbids self-installing binaries).
class UpdateService {
  /// Guards against showing the dialog more than once per app session.
  static bool _shownThisSession = false;

  Future<void> checkForUpdate() async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      final uri = Uri.parse(
        '${ApiConstants.apiBaseUrl}/app/version?platform=$platform',
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return;

      final info = AppVersionInfo.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );

      final pkg = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(pkg.buildNumber) ?? 0;

      // Already on the latest (or newer) build — nothing to do.
      if (info.latestBuild <= currentBuild) return;
      if (_shownThisSession) return;
      _shownThisSession = true;

      final force = currentBuild < info.minBuild;

      await Get.dialog(
        UpdateDialog(
          info: info,
          force: force,
          onUpdate: (onProgress) =>
              startUpdate(info.downloadUrl, onProgress: onProgress),
        ),
        barrierDismissible: !force,
      );
    } catch (e) {
      debugPrint('UpdateService: skipped update check ($e)');
    }
  }

  /// Drives the actual update. On iOS we can only redirect; on Android we
  /// download the APK (reporting [onProgress] 0..1) and open the installer.
  /// Returns an error message on failure, or null on success.
  Future<String?> startUpdate(
    String url, {
    required void Function(double progress) onProgress,
  }) async {
    final uri = Uri.tryParse(url);
    if (url.isEmpty || uri == null) {
      return 'رابط التحديث غير متوفّر';
    }

    // iOS: cannot self-install — open the distribution page.
    if (Platform.isIOS) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return null;
      } catch (e) {
        return 'تعذّر فتح صفحة التحديث';
      }
    }

    try {
      // Android 8+ requires permission to install from this app.
      final status = await Permission.requestInstallPackages.request();
      if (!status.isGranted) {
        return 'يلزم السماح بتثبيت التطبيقات لإكمال التحديث';
      }

      final filePath = await _downloadApk(uri, onProgress);
      if (filePath == null) return 'فشل تنزيل التحديث';

      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        // Fallback: let the system/browser handle the file.
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return null;
    } catch (e) {
      debugPrint('UpdateService: update failed ($e)');
      return 'حدث خطأ أثناء التحديث';
    }
  }

  Future<String?> _downloadApk(
    Uri uri,
    void Function(double) onProgress,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/app-update.apk');
    if (await file.exists()) {
      await file.delete();
    }

    final client = http.Client();
    try {
      final response = await client.send(http.Request('GET', uri));
      if (response.statusCode != 200) return null;

      final total = response.contentLength ?? 0;
      var received = 0;
      final sink = file.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress(received / total);
      }
      await sink.flush();
      await sink.close();
      onProgress(1);
      return file.path;
    } finally {
      client.close();
    }
  }
}
