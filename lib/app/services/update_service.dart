import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
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
/// the installed build is older — shows an update dialog. A failure here must
/// never affect the app, so everything is wrapped defensively.
class UpdateService {
  /// Guards against showing the dialog more than once per app session.
  static bool _shownThisSession = false;

  Future<void> checkForUpdate() async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      final uri = Uri.parse(
        '${ApiConstants.apiBaseUrl}/app/version?platform=$platform',
      );

      final res =
          await http.get(uri).timeout(const Duration(seconds: 8));
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
          onUpdate: () => _openDownload(info.downloadUrl),
        ),
        barrierDismissible: !force,
      );
    } catch (e) {
      debugPrint('UpdateService: skipped update check ($e)');
    }
  }

  Future<void> _openDownload(String url) async {
    final uri = Uri.tryParse(url);
    if (url.isEmpty || uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('UpdateService: could not open download url ($e)');
    }
  }
}
