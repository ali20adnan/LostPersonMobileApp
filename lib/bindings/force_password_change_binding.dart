import 'package:get/get.dart';

import '../features/auth/controllers/force_password_change_controller.dart';

class ForcePasswordChangeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ForcePasswordChangeController>(
        () => ForcePasswordChangeController());
  }
}
