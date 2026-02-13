import 'package:get/get.dart';

import '../../bindings/home_binding.dart';
import '../../bindings/translator_binding.dart';
import '../../bindings/languages_binding.dart';
import '../../bindings/history_binding.dart';
import '../../bindings/settings_binding.dart';
import '../../bindings/incident_reporting_binding.dart';
import '../../features/home/views/home_page.dart';
import '../../features/translator/views/translator_page.dart';
import '../../features/languages/views/languages_page.dart';
import '../../features/history/views/history_page.dart';
import '../../features/history/views/conversation_detail_page.dart';
import '../../features/settings/views/settings_page.dart';
import '../../features/incident_reporting/views/incident_reporting_page.dart';
import '../../features/incident_reporting/views/incidents_list_page.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.translator,
      page: () => const TranslatorPage(),
      binding: TranslatorBinding(),
    ),
    GetPage(
      name: AppRoutes.languages,
      page: () => const LanguagesPage(),
      binding: LanguagesBinding(),
    ),
    GetPage(
      name: AppRoutes.history,
      page: () => const HistoryPage(),
      binding: HistoryBinding(),
    ),
    GetPage(
      name: AppRoutes.conversationDetail,
      page: () => const ConversationDetailPage(),
      binding: HistoryBinding(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.incidentReporting,
      page: () => const IncidentReportingPage(),
      binding: IncidentReportingBinding(),
    ),
    GetPage(
      name: AppRoutes.incidentsList,
      page: () => const IncidentsListPage(),
      binding: IncidentReportingBinding(),
    ),
  ];
}
