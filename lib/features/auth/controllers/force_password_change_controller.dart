import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/services/auth_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../services/session_bootstrap.dart';

/// Drives the forced password-change screen shown after a user signs in with a
/// temporary (default) password. Mirrors the web flow: the user only enters a
/// new password and its confirmation; the current (default) password is known
/// from login, so it is not asked for again. The user cannot enter the app
/// until the password is replaced.
class ForcePasswordChangeController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  /// The default password the account was created with. Used as the
  /// `currentPassword` when calling the change-password endpoint. The login
  /// flow passes the password the user just authenticated with via
  /// `Get.arguments`; we fall back to the server's default for a session that
  /// was restored at app startup (where the typed password isn't in memory).
  static const String defaultPassword = 'User1234';

  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isLoading = false.obs;
  final obscureNew = true.obs;
  final obscureConfirm = true.obs;
  final errorMessage = ''.obs;

  late final String _currentPassword;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    _currentPassword =
        (arg is String && arg.isNotEmpty) ? arg : defaultPassword;
  }

  void toggleNewVisibility() => obscureNew.value = !obscureNew.value;
  void toggleConfirmVisibility() =>
      obscureConfirm.value = !obscureConfirm.value;

  Future<void> submit() async {
    final newPass = newPasswordController.text;
    final confirm = confirmPasswordController.text;

    if (newPass.isEmpty) {
      errorMessage.value = 'كلمة المرور الجديدة مطلوبة';
      return;
    }
    if (newPass.length < 6) {
      errorMessage.value = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
      return;
    }
    if (newPass != confirm) {
      errorMessage.value = 'كلمتا المرور غير متطابقتين';
      return;
    }
    if (newPass == defaultPassword) {
      errorMessage.value = 'لا يمكن استخدام كلمة المرور الافتراضية';
      return;
    }

    errorMessage.value = '';
    isLoading.value = true;

    final response = await _authService.changePassword(
      currentPassword: _currentPassword,
      newPassword: newPass,
    );

    if (!response.isSuccess) {
      isLoading.value = false;
      errorMessage.value =
          response.errorMessage ?? 'فشل تغيير كلمة المرور، يرجى المحاولة مجدداً';
      return;
    }

    // Password replaced — the session is now fully active. Bring up the
    // real-time services (guarded; no-ops if already running) and enter the app.
    await bootstrapRealtimeServices();
    isLoading.value = false;

    AppSnackbar.glass(
      'تم التغيير',
      'تم تغيير كلمة المرور بنجاح',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.withValues(alpha: 0.8),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );

    Get.offAllNamed(AppRoutes.home);
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
