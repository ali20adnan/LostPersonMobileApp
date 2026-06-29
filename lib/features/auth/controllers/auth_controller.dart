import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/services/auth_service.dart';
import '../services/session_bootstrap.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final userNameController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final errorMessage = ''.obs;

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  Future<void> login() async {
    final userName = userNameController.text.trim();
    final password = passwordController.text;

    if (userName.isEmpty || password.isEmpty) {
      errorMessage.value = 'يرجى إدخال اسم المستخدم وكلمة المرور';
      return;
    }

    errorMessage.value = '';
    isLoading.value = true;

    final response = await _authService.login(userName, password);

    if (!response.isSuccess) {
      isLoading.value = false;
      errorMessage.value =
          response.errorMessage ?? 'فشل تسجيل الدخول، تحقق من البيانات';
      return;
    }

    // Signed in with a temporary (default) password: gate the app behind the
    // forced password-change screen, exactly like the web. Pass the password
    // just entered so it can be used as the current password there. Real-time
    // services come up only after the password is replaced.
    if (_authService.currentUser.value?.isTempPass == true) {
      isLoading.value = false;
      Get.offAllNamed(AppRoutes.forcePasswordChange, arguments: password);
      return;
    }

    // Bring up real-time services now that we have a fresh, permanent session.
    await bootstrapRealtimeServices();
    isLoading.value = false;
    Get.offAllNamed(AppRoutes.home);
  }

  @override
  void onClose() {
    try {
      userNameController.dispose();
    } catch (_) {}
    try {
      passwordController.dispose();
    } catch (_) {}
    super.onClose();
  }
}
