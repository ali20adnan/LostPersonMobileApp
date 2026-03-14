import 'package:get/get.dart';

import '../features/notifications/controllers/notifications_page_controller.dart';

class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationsPageController>(() => NotificationsPageController());
  }
}
