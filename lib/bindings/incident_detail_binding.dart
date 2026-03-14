import 'package:get/get.dart';

import '../features/incident_reporting/controllers/incident_detail_controller.dart';

class IncidentDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => IncidentDetailController());
  }
}
