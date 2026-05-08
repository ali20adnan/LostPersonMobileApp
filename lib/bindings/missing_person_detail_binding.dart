import 'package:get/get.dart';

import '../features/missing_persons/controllers/missing_person_detail_controller.dart';

class MissingPersonDetailBinding extends Bindings {
  @override
  void dependencies() {
    // `Get.put` alone won't replace an existing instance, so navigating to a
    // second report would keep the first controller (with stale data). Mirror
    // the pattern in `IncidentDetailBinding`: explicitly delete first, then
    // put — guarantees `onInit` runs fresh with the new `Get.arguments`.
    if (Get.isRegistered<MissingPersonDetailController>()) {
      Get.delete<MissingPersonDetailController>(force: true);
    }
    Get.put(MissingPersonDetailController());
  }
}
