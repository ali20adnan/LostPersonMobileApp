import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/services/auth_service.dart';

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

    isLoading.value = false;

    if (response.isSuccess) {
      Get.offAllNamed('/home');
    } else {
      errorMessage.value =
          response.errorMessage ?? 'فشل تسجيل الدخول، تحقق من البيانات';
    }
  }

  @override
  void onClose() {
    // Defer disposal to avoid 'used after being disposed' during navigation
    Future.microtask(() {
      userNameController.dispose();
      passwordController.dispose();
    });
    super.onClose();
  }
}
