import 'package:get/get.dart';

import '../data/repositories/incident_repository.dart';
import '../features/incident_reporting/controllers/incident_reporting_controller.dart';
import '../features/incident_reporting/controllers/incidents_list_controller.dart';
import '../features/alerts/controllers/alert_controller.dart';

/// Binding for incident reporting feature
class IncidentReportingBinding extends Bindings {
  @override
  void dependencies() {
    // Register repository
    if (!Get.isRegistered<ReportRepository>()) {
      Get.lazyPut<ReportRepository>(() => ReportRepository());
    }

    // Initialize controllers
    Get.lazyPut<IncidentReportingController>(
      () => IncidentReportingController(),
    );
    Get.lazyPut<IncidentsListController>(
      () => IncidentsListController(),
    );
    Get.lazyPut<AlertController>(
      () => AlertController(),
    );
  }
}
