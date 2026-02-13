import 'package:get/get.dart';

import '../features/incident_reporting/controllers/incident_reporting_controller.dart';
import '../features/incident_reporting/controllers/incidents_list_controller.dart';
import '../features/alerts/controllers/alert_controller.dart';
import '../app/services/storage_service.dart';
import '../app/services/media_storage_service.dart';
import '../app/services/location_service.dart';

/// Binding for incident reporting feature
class IncidentReportingBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize services
    Get.lazyPut<StorageService>(() => StorageService());
    Get.lazyPut<MediaStorageService>(() => MediaStorageService());
    Get.lazyPut<LocationService>(() => LocationService());

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
