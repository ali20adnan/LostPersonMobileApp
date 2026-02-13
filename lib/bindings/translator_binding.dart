import 'package:get/get.dart';
import '../features/translator/controllers/translator_controller.dart';

class TranslatorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TranslatorController>(() => TranslatorController());
  }
}
