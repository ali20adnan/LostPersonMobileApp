import '../../data/models/language_model.dart';

class LanguageConstants {
  static const Language arabic = Language(
    code: 'ar',
    nameAr: 'العربية',
    nameEn: 'Arabic',
    flagPath: 'assets/images/flags/ar.png',
  );

  static const Language english = Language(
    code: 'en',
    nameAr: 'الإنجليزية',
    nameEn: 'English',
    flagPath: 'assets/images/flags/en.png',
  );

  static const Language persian = Language(
    code: 'fa',
    nameAr: 'الفارسية',
    nameEn: 'Persian',
    flagPath: 'assets/images/flags/fa.png',
  );

  static const Language urdu = Language(
    code: 'ur',
    nameAr: 'الأردية',
    nameEn: 'Urdu',
    flagPath: 'assets/images/flags/ur.png',
  );

  static const Language kurdish = Language(
    code: 'ku',
    nameAr: 'الكردية',
    nameEn: 'Kurdish',
    flagPath: 'assets/images/flags/ku.png',
  );

  static const List<Language> supportedLanguages = [
    arabic,
    english,
    persian,
    urdu,
    kurdish,
  ];

  static Language? getLanguageByCode(String code) {
    try {
      return supportedLanguages.firstWhere((lang) => lang.code == code);
    } catch (e) {
      return null;
    }
  }

  static String getLanguageNameArabic(String code) {
    final language = getLanguageByCode(code);
    return language?.nameAr ?? code;
  }

  static String getLanguageNameEnglish(String code) {
    final language = getLanguageByCode(code);
    return language?.nameEn ?? code;
  }
}
