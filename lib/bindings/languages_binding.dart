import 'package:get/get.dart';

import '../app/services/storage_service.dart';
import '../features/languages/controllers/languages_controller.dart';

class LanguagesBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize StorageService if not already available
    if (!Get.isRegistered<StorageService>()) {
      Get.put(StorageService()..init());
    }

    Get.lazyPut<LanguagesController>(() => LanguagesController());
  }
}
