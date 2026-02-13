import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../translator/views/translator_page.dart';
import '../../ocr_reader/views/ocr_reader_page.dart';
import '../../missing_persons/views/missing_persons_page.dart';
import '../../incident_reporting/views/incidents_list_page.dart';
import '../../history/views/history_page.dart';

class HomeController extends GetxController {
  // Current selected index
  final currentIndex = 0.obs;

  // Pages for bottom navigation
  final List<Widget> pages = const [
    TranslatorPage(),
    OcrReaderPage(),
    MissingPersonsPage(),
    IncidentsListPage(),
    HistoryPage(),
  ];

  /// Change page
  void changePage(int index) {
    currentIndex.value = index;
    debugPrint('HomeController: Changed to page $index');
  }

  /// Navigate to specific page
  void navigateToTranslator() => changePage(0);
  void navigateToOcr() => changePage(1);
  void navigateToMissingPersons() => changePage(2);
  void navigateToIncidents() => changePage(3);
  void navigateToHistory() => changePage(4);
}
