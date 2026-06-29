import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/services/auth_service.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));

    final authService = Get.find<AuthService>();

    if (!authService.isLoggedIn) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    // A restored session still carrying a temporary password must change it
    // before entering the app, just like a fresh login. The current password
    // isn't in memory here, so the force-change screen falls back to the
    // account's default password.
    if (authService.currentUser.value?.isTempPass == true) {
      Get.offAllNamed(AppRoutes.forcePasswordChange);
      return;
    }

    Get.offAllNamed(AppRoutes.home);
  }
}
