import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MissingPersonsController extends GetxController {
  // Observable state
  final selectedTab = 0.obs; // 0: Report, 1: Search, 2: Found
  final reportedPersons = <MissingPerson>[].obs;
  final foundPersons = <MissingPerson>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadMockData();
  }

  /// Change tab
  void changeTab(int index) {
    selectedTab.value = index;
    debugPrint('MissingPersonsController: Changed to tab $index');
  }

  /// Report a missing person
  void reportMissingPerson() {
    Get.snackbar(
      'بلاغ جديد',
      'جاري فتح نموذج الإبلاغ عن شخص مفقود',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.withOpacity(0.8),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
    debugPrint('MissingPersonsController: Opening report form');
  }

  /// Search for a person
  void searchPerson(String query) {
    debugPrint('MissingPersonsController: Searching for: $query');
    Get.snackbar(
      'البحث',
      'جاري البحث عن: $query',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.withOpacity(0.8),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }

  /// Mark person as found
  void markAsFound(MissingPerson person) {
    reportedPersons.remove(person);
    foundPersons.add(person);
    Get.snackbar(
      'تم العثور',
      'تم نقل البلاغ إلى قائمة الموجودين',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
    debugPrint('MissingPersonsController: Person marked as found');
  }

  /// Load mock data
  void _loadMockData() {
    reportedPersons.addAll([
      MissingPerson(
        id: '1',
        name: 'محمد أحمد',
        age: 65,
        description: 'يرتدي ثوباً أبيض وعمامة سوداء',
        lastSeen: 'بالقرب من باب الحرم الرئيسي',
        country: 'المملكة العربية السعودية',
        reportTime: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      MissingPerson(
        id: '2',
        name: 'Ali Hassan',
        age: 45,
        description: 'Wearing grey jubba and white cap',
        lastSeen: 'Near the main prayer hall',
        country: 'Pakistan',
        reportTime: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      MissingPerson(
        id: '3',
        name: 'حسین رضایی',
        age: 58,
        description: 'لباس مشکی، سن متوسط',
        lastSeen: 'نزدیک درب شرقی',
        country: 'Iran',
        reportTime: DateTime.now().subtract(const Duration(hours: 8)),
      ),
    ]);

    foundPersons.add(
      MissingPerson(
        id: '4',
        name: 'عبدالله محمود',
        age: 52,
        description: 'يرتدي ثوباً بنياً',
        lastSeen: 'بالقرب من المواضئ',
        country: 'مصر',
        reportTime: DateTime.now().subtract(const Duration(days: 1)),
        foundTime: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    );
  }
}

class MissingPerson {
  final String id;
  final String name;
  final int age;
  final String description;
  final String lastSeen;
  final String country;
  final DateTime reportTime;
  final DateTime? foundTime;

  MissingPerson({
    required this.id,
    required this.name,
    required this.age,
    required this.description,
    required this.lastSeen,
    required this.country,
    required this.reportTime,
    this.foundTime,
  });
}
