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
    final route = authService.isLoggedIn ? AppRoutes.home : AppRoutes.login;

    Get.offAllNamed(route);
  }
}
