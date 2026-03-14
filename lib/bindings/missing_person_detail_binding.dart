import 'package:get/get.dart';

import '../features/missing_persons/controllers/missing_person_detail_controller.dart';

class MissingPersonDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MissingPersonDetailController());
  }
}
