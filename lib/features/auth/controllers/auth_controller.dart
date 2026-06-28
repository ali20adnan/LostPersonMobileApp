import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/services/auth_service.dart';
import '../../../app/services/socket_service.dart';
import '../../../app/services/unread_count_service.dart';
import '../../notifications/bindings/app_notifications_bootstrap.dart';
import '../../notifications/services/app_notifications_service.dart';

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
      // Bring up real-time services now that we have a fresh token.
      try {
        if (!Get.isRegistered<SocketService>()) {
          await Get.putAsync<SocketService>(() => SocketService().init());
        }
        if (!Get.isRegistered<UnreadCountService>()) {
          await Get.putAsync<UnreadCountService>(
              () => UnreadCountService().init());
        }
        if (!Get.isRegistered<AppNotificationsService>()) {
          await Get.putAsync<AppNotificationsService>(
              () => AppNotificationsService().init());
        }
        await AppNotificationsBootstrap.setup();
      } catch (e) {
        debugPrint('AuthController: post-login init failed - $e');
      }
      Get.offAllNamed('/home');
    } else {
      errorMessage.value =
          response.errorMessage ?? 'فشل تسجيل الدخول، تحقق من البيانات';
    }
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
