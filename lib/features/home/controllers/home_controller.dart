import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/services/update_service.dart';
import '../../assembly_points/views/assembly_points_page.dart';
import '../../translator/views/translator_hub_page.dart';
import '../../incident_reporting/controllers/incidents_list_controller.dart';
import '../views/reports_hub_page.dart';
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

  // Pages for bottom navigation (4 tabs):
  //   0 الخريطة (نقاط التجمّع) — الشاشة الرئيسية
  //   1 الترجمة
  //   2 البلاغات (المفقودون + الحوادث مدمجان)
  //   3 حسابي
  final List<Widget> pages = const [
    AssemblyPointsPage(),
    TranslatorHubPage(),
    ReportsHubPage(),
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
  void navigateToMap() => changePage(0);
  void navigateToTranslator() => changePage(1);
  void navigateToReports() => changePage(2);
  void navigateToProfile() => changePage(3);
}
