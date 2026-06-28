import 'package:get/get.dart';

import '../features/incident_reporting/controllers/incident_detail_controller.dart';

class IncidentDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<IncidentDetailController>()) {
      Get.delete<IncidentDetailController>(force: true);
    }
    Get.put(IncidentDetailController());
  }
}
