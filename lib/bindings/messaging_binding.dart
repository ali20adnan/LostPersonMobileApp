import 'package:get/get.dart';

import '../features/messaging/controllers/chat_controller.dart';

class MessagingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatController>(() => ChatController());
  }
}
