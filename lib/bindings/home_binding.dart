import 'package:get/get.dart';

import '../app/services/storage_service.dart';
import '../features/home/controllers/home_controller.dart';
import '../features/translator/controllers/translator_controller.dart';
import '../features/ocr_reader/controllers/ocr_reader_controller.dart';
import '../features/missing_persons/controllers/missing_persons_controller.dart';
import '../features/incident_reporting/controllers/incidents_list_controller.dart';
import '../features/history/controllers/history_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize StorageService if not already available
    if (!Get.isRegistered<StorageService>()) {
      Get.put(StorageService()..init());
    }

    // Put HomeController
    Get.put(HomeController());

    // Put all page controllers
    Get.put(TranslatorController());
    Get.put(OcrReaderController());
    Get.put(MissingPersonsController());
    Get.put(IncidentsListController());
    Get.put(HistoryController());
  }
}
