import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/services/update_service.dart';
import '../../translator/views/translator_hub_page.dart';
import '../../missing_persons/views/missing_persons_page.dart';
import '../../incident_reporting/controllers/incidents_list_controller.dart';
import '../../incident_reporting/views/incidents_list_page.dart';
import '../../profile/views/profile_page.dart';


class HomeController extends GetxController {
  // Current selected index
  final currentIndex = 0.obs;

  // Direction of the last tab change — drives the directional slide in the
  // page transition (forward = moving to a higher-index tab).
  bool goingForward = true;

  @override
  void onReady() {
    super.onReady();
    // OTA version gate — runs once after the home screen is shown. Safe to
    // fire-and-forget: UpdateService swallows any failure.
    UpdateService().checkForUpdate();
  }

  // Pages for bottom navigation (4 tabs: ترجمة, مفقودون, بلاغات, حسابي)
  final List<Widget> pages = const [
    TranslatorHubPage(),
    MissingPersonsPage(),
    IncidentsListPage(),
    ProfilePage(),
  ];

  /// Change page
  void changePage(int index) {
    if (index == currentIndex.value) return;
    goingForward = index > currentIndex.value;
    currentIndex.value = index;
    debugPrint('HomeController: Changed to page $index');
    if (index == 2 && Get.isRegistered<IncidentsListController>()) {
      Get.find<IncidentsListController>().markAllAsReadOnView();
    }
  }

  /// Navigate to specific page
  void navigateToTranslator() => changePage(0);
  void navigateToMissingPersons() => changePage(1);
  void navigateToIncidents() => changePage(2);
  void navigateToProfile() => changePage(3);
}
