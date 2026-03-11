import 'package:get/get.dart';

import '../app/services/storage_service.dart';
import '../data/repositories/incident_repository.dart';
import '../features/home/controllers/home_controller.dart';
import '../features/translator/controllers/translator_controller.dart';
import '../features/ocr_reader/controllers/ocr_reader_controller.dart';
import '../features/missing_persons/controllers/missing_persons_controller.dart';
import '../features/incident_reporting/controllers/incidents_list_controller.dart';
import '../features/messaging/controllers/conversations_controller.dart';
import '../data/repositories/conversation_repository.dart';
import '../features/notifications/controllers/notifications_controller.dart';
import '../features/profile/controllers/profile_controller.dart';


class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize StorageService if not already available
    if (!Get.isRegistered<StorageService>()) {
      Get.put(StorageService()..init());
    }

    // Register repositories needed by controllers
    if (!Get.isRegistered<ReportRepository>()) {
      Get.put(ReportRepository());
    }

    // Put HomeController
    Get.put(HomeController());

    // Put all page controllers
    Get.put(TranslatorController());
    Get.put(OcrReaderController());
    Get.put(MissingPersonsController());
    Get.put(IncidentsListController());

    if (!Get.isRegistered<ConversationRepository>()) {
      Get.put(ConversationRepository());
    }
    Get.put(ConversationsController());
    Get.put(NotificationsController());
    Get.put(ProfileController());
  }
}
