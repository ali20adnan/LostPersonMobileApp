import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Obx(() => controller.pages[controller.currentIndex.value]),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: controller.currentIndex.value,
          onDestinationSelected: controller.changePage,
          elevation: 8,
          height: 80,
          backgroundColor: theme.colorScheme.surface,
          indicatorColor: theme.colorScheme.primary,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.translate_rounded),
              selectedIcon: Icon(
                Icons.translate_rounded,
                color: theme.colorScheme.onPrimary,
              ),
              label: 'مترجم',
              tooltip: 'الترجمة الفورية',
            ),
            NavigationDestination(
              icon: const Icon(Icons.document_scanner_outlined),
              selectedIcon: Icon(
                Icons.document_scanner,
                color: theme.colorScheme.onPrimary,
              ),
              label: 'قارئ النصوص',
              tooltip: 'قراءة اللافتات',
            ),
            NavigationDestination(
              icon: const Icon(Icons.group_outlined),
              selectedIcon: Icon(
                Icons.group,
                color: theme.colorScheme.onPrimary,
              ),
              label: 'المفقودون',
              tooltip: 'الأشخاص المفقودون',
            ),
            NavigationDestination(
              icon: const Icon(Icons.report_problem_outlined),
              selectedIcon: Icon(
                Icons.report_problem,
                color: theme.colorScheme.onPrimary,
              ),
              label: 'الحوادث',
              tooltip: 'إدارة الحوادث',
            ),
            NavigationDestination(
              icon: const Icon(Icons.history_outlined),
              selectedIcon: Icon(
                Icons.history,
                color: theme.colorScheme.onPrimary,
              ),
              label: 'السجل',
              tooltip: 'سجل المحادثات',
            ),
          ],
        ),
      ),
    );
  }
}
