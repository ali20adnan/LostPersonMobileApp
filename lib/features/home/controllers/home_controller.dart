import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../assembly_points/views/assembly_points_page.dart';
import '../../translator/views/translator_hub_page.dart';
import '../../incident_reporting/controllers/incidents_list_controller.dart';
import '../../incident_reporting/views/incidents_list_page.dart';
import '../../missing_persons/views/missing_persons_page.dart';
import '../../profile/views/profile_page.dart';


class HomeController extends GetxController {
  // Current selected index
  final currentIndex = 0.obs;

  // Direction of the last tab change — drives the directional slide in the
  // page transition (forward = moving to a higher-index tab).
  bool goingForward = true;

  // Pages for bottom navigation (5 tabs):
  //   0 الخريطة (نقاط التجمّع) — الشاشة الرئيسية
  //   1 الترجمة
  //   2 المفقودين
  //   3 الحوادث
  //   4 حسابي
  final List<Widget> pages = const [
    AssemblyPointsPage(),
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
    // Entering the incidents tab clears its unread badge.
    if (index == 3 && Get.isRegistered<IncidentsListController>()) {
      Get.find<IncidentsListController>().markAllAsReadOnView();
    }
  }

  /// Navigate to specific page
  void navigateToMap() => changePage(0);
  void navigateToTranslator() => changePage(1);
  void navigateToMissing() => changePage(2);
  void navigateToIncidents() => changePage(3);
  void navigateToProfile() => changePage(4);
}
