import 'package:get/get.dart';

import '../features/missing_persons/controllers/missing_person_form_controller.dart';

class MissingPersonFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MissingPersonFormController());
  }
}
