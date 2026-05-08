import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../translator/views/translator_hub_page.dart';
import '../../missing_persons/views/missing_persons_page.dart';
import '../../incident_reporting/views/incidents_list_page.dart';
import '../../profile/views/profile_page.dart';


class HomeController extends GetxController {
  // Current selected index
  final currentIndex = 0.obs;

  // Pages for bottom navigation (4 tabs: ترجمة, مفقودون, بلاغات, حسابي)
  final List<Widget> pages = const [
    TranslatorHubPage(),
    MissingPersonsPage(),
    IncidentsListPage(),
    ProfilePage(),
  ];

  /// Change page
  void changePage(int index) {
    currentIndex.value = index;
    debugPrint('HomeController: Changed to page $index');
  }

  /// Navigate to specific page
  void navigateToTranslator() => changePage(0);
  void navigateToMissingPersons() => changePage(1);
  void navigateToIncidents() => changePage(2);
  void navigateToProfile() => changePage(3);
}
