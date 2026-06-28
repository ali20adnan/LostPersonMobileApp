import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    debugPrint('┌─────────────────────────────────────────────────────┐');
    debugPrint('│ PermissionService: REQUEST MICROPHONE PERMISSION   │');
    debugPrint('└─────────────────────────────────────────────────────┘');

    debugPrint('PermissionService: Checking current permission status...');
    final status = await Permission.microphone.status;
    debugPrint('PermissionService: Current status = $status');

    if (status.isGranted) {
      debugPrint('┌─────────────────────────────────────────────────────┐');
      debugPrint('│ PermissionService: ✓✓✓ PERMISSION GRANTED ✓✓✓     │');
      debugPrint('└─────────────────────────────────────────────────────┘');
      return true;
    }

    if (status.isDenied) {
      debugPrint('PermissionService: Permission DENIED, showing rationale...');
      // Show rationale dialog in Arabic
      final shouldRequest = await _showPermissionRationale();
      debugPrint('PermissionService: User response to rationale = $shouldRequest');

      if (!shouldRequest) {
        debugPrint('PermissionService: ✗ User declined to grant permission');
        return false;
      }

      debugPrint('PermissionService: Requesting permission...');
      final result = await Permission.microphone.request();
      debugPrint('PermissionService: Permission request result = $result');

      if (result.isGranted) {
        debugPrint('┌─────────────────────────────────────────────────────┐');
        debugPrint('│ PermissionService: ✓✓✓ PERMISSION GRANTED ✓✓✓     │');
        debugPrint('└─────────────────────────────────────────────────────┘');
      } else {
        debugPrint('PermissionService: ✗ Permission request denied');
      }

      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      debugPrint('PermissionService: ✗ Permission PERMANENTLY DENIED');
      // Show dialog to open app settings
      await _showOpenSettingsDialog();
      return false;
    }

    // Request permission
    debugPrint('PermissionService: Requesting permission directly...');
    final result = await Permission.microphone.request();
    debugPrint('PermissionService: Direct permission result = $result');

    if (result.isGranted) {
      debugPrint('┌─────────────────────────────────────────────────────┐');
      debugPrint('│ PermissionService: ✓✓✓ PERMISSION GRANTED ✓✓✓     │');
      debugPrint('└─────────────────────────────────────────────────────┘');
    } else {
      debugPrint('PermissionService: ✗ Permission denied');
    }

    return result.isGranted;
  }

  /// Check if microphone permission is granted
  Future<bool> isMicrophonePermissionGranted() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Show permission rationale dialog in Arabic
  Future<bool> _showPermissionRationale() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('إذن الميكروفون مطلوب'),
        content: const Text(
          'نحتاج إلى الوصول إلى الميكروفون لتسجيل صوتك وترجمته في الوقت الفعلي. '
          'لن يتم حفظ التسجيلات أو مشاركتها مع أي طرف ثالث.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('متابعة'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    return result ?? false;
  }

  /// Show dialog to open app settings
  Future<void> _showOpenSettingsDialog() async {
    await Get.dialog(
      AlertDialog(
        title: const Text('الإذن مرفوض بشكل دائم'),
        content: const Text(
          'تم رفض إذن الميكروفون بشكل دائم. '
          'يرجى الانتقال إلى إعدادات التطبيق وتفعيل إذن الميكروفون يدوياً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Show error message for permission denial
  void showPermissionDeniedMessage() {
    Get.snackbar(
      'الإذن مرفوض',
      'يتطلب التطبيق إذن الميكروفون للعمل بشكل صحيح',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withValues(alpha: 0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    debugPrint('PermissionService: Requesting camera permission');
    final status = await Permission.camera.status;

    if (status.isGranted) {
      debugPrint('PermissionService: Camera permission already granted');
      return true;
    }

    if (status.isDenied) {
      // Show rationale dialog
      final shouldRequest = await _showCameraRationale();
      if (!shouldRequest) {
        return false;
      }

      final result = await Permission.camera.request();
      debugPrint('PermissionService: Camera permission result = $result');
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await _showCameraSettingsDialog();
      return false;
    }

    final result = await Permission.camera.request();
    return result.isGranted;
  }

  /// Request photo library permission
  Future<bool> requestPhotoLibraryPermission() async {
    debugPrint('PermissionService: Requesting photo library permission');
    final status = await Permission.photos.status;

    if (status.isGranted) {
      debugPrint('PermissionService: Photo library permission already granted');
      return true;
    }

    if (status.isDenied) {
      final shouldRequest = await _showPhotosRationale();
      if (!shouldRequest) {
        return false;
      }

      final result = await Permission.photos.request();
      debugPrint('PermissionService: Photos permission result = $result');
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await _showPhotosSettingsDialog();
      return false;
    }

    final result = await Permission.photos.request();
    return result.isGranted;
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    debugPrint('PermissionService: Requesting location permission');
    final status = await Permission.location.status;

    if (status.isGranted) {
      debugPrint('PermissionService: Location permission already granted');
      return true;
    }

    if (status.isDenied) {
      final shouldRequest = await _showLocationRationale();
      if (!shouldRequest) {
        return false;
      }

      final result = await Permission.location.request();
      debugPrint('PermissionService: Location permission result = $result');
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await _showLocationSettingsDialog();
      return false;
    }

    final result = await Permission.location.request();
    return result.isGranted;
  }

  /// Show camera permission rationale dialog in Arabic
  Future<bool> _showCameraRationale() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('إذن الكاميرا مطلوب'),
        content: const Text(
          'نحتاج إلى الوصول إلى الكاميرا لالتقاط صور للحوادث والبلاغات. '
          'لن يتم استخدام الصور إلا لأغراض التوثيق.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('متابعة'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return result ?? false;
  }

  /// Show photos permission rationale dialog in Arabic
  Future<bool> _showPhotosRationale() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('إذن الصور مطلوب'),
        content: const Text(
          'نحتاج إلى الوصول إلى مكتبة الصور لاختيار صور للحوادث والبلاغات. '
          'لن يتم استخدام الصور إلا لأغراض التوثيق.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('متابعة'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return result ?? false;
  }

  /// Show location permission rationale dialog in Arabic
  Future<bool> _showLocationRationale() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('إذن الموقع مطلوب'),
        content: const Text(
          'نحتاج إلى الوصول إلى موقعك لتحديد مكان الحوادث تلقائياً. '
          'لن يتم تتبع موقعك أو مشاركته مع أي طرف ثالث.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('متابعة'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return result ?? false;
  }

  /// Show camera settings dialog
  Future<void> _showCameraSettingsDialog() async {
    await Get.dialog(
      AlertDialog(
        title: const Text('الإذن مرفوض بشكل دائم'),
        content: const Text(
          'تم رفض إذن الكاميرا بشكل دائم. '
          'يرجى الانتقال إلى إعدادات التطبيق وتفعيل إذن الكاميرا يدوياً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Show photos settings dialog
  Future<void> _showPhotosSettingsDialog() async {
    await Get.dialog(
      AlertDialog(
        title: const Text('الإذن مرفوض بشكل دائم'),
        content: const Text(
          'تم رفض إذن الوصول للصور بشكل دائم. '
          'يرجى الانتقال إلى إعدادات التطبيق وتفعيل إذن الصور يدوياً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Show location settings dialog
  Future<void> _showLocationSettingsDialog() async {
    await Get.dialog(
      AlertDialog(
        title: const Text('الإذن مرفوض بشكل دائم'),
        content: const Text(
          'تم رفض إذن الموقع بشكل دائم. '
          'يرجى الانتقال إلى إعدادات التطبيق وتفعيل إذن الموقع يدوياً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
