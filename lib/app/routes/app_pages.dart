import 'package:get/get.dart';

import '../../core/widgets/shared/motion/page_transitions.dart';
import '../../features/splash/bindings/splash_binding.dart';
import '../../features/splash/views/splash_page.dart';
import '../../bindings/home_binding.dart';
import '../../bindings/settings_binding.dart';
import '../../bindings/auth_binding.dart';
import '../../bindings/incident_reporting_binding.dart';
import '../../bindings/missing_person_form_binding.dart';
import '../../bindings/messaging_binding.dart';
import '../../bindings/alerts_binding.dart';
import '../../bindings/notifications_binding.dart';
import '../../bindings/missing_person_detail_binding.dart';
import '../../bindings/incident_detail_binding.dart';
import '../../features/home/views/home_page.dart';
import '../../features/settings/views/settings_page.dart';
import '../../features/auth/views/login_page.dart';
import '../../features/incident_reporting/views/incident_reporting_page.dart';
import '../../features/incident_reporting/views/incidents_list_page.dart';
import '../../features/missing_persons/views/missing_person_form_page.dart';
import '../../features/messaging/views/chat_page.dart';
import '../../features/alerts/views/alerts_page.dart';
import '../../features/notifications/views/notifications_page.dart';
import '../../features/missing_persons/views/missing_person_detail_page.dart';
import '../../features/incident_reporting/views/incident_detail_page.dart';
import 'app_routes.dart';

class AppPages {
  static final _sharedAxisX = SharedAxisXTransition();
  static final _sharedAxisY = SharedAxisYTransition();
  static final _fadeThrough = FadeThroughGetTransition();

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: AuthBinding(),
      customTransition:_fadeThrough,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
      customTransition:_fadeThrough,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
      customTransition:_fadeThrough,
    ),
    GetPage(
      name: AppRoutes.incidentReporting,
      page: () => const IncidentReportingPage(),
      binding: IncidentReportingBinding(),
      customTransition:_sharedAxisX,
    ),
    GetPage(
      name: AppRoutes.incidentsList,
      page: () => const IncidentsListPage(),
      binding: IncidentReportingBinding(),
      customTransition:_sharedAxisX,
    ),
    GetPage(
      name: AppRoutes.missingPersonForm,
      page: () => const MissingPersonFormPage(),
      binding: MissingPersonFormBinding(),
      customTransition:_sharedAxisX,
    ),
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatPage(),
      binding: MessagingBinding(),
      customTransition:_sharedAxisX,
    ),
    GetPage(
      name: AppRoutes.alerts,
      page: () => const AlertsPage(),
      binding: AlertsBinding(),
      customTransition:_sharedAxisY,
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsPage(),
      binding: NotificationsBinding(),
      customTransition:_sharedAxisY,
    ),
    GetPage(
      name: AppRoutes.missingPersonDetail,
      page: () => const MissingPersonDetailPage(),
      binding: MissingPersonDetailBinding(),
      customTransition:_sharedAxisX,
    ),
    GetPage(
      name: AppRoutes.incidentDetail,
      page: () => const IncidentDetailPage(),
      binding: IncidentDetailBinding(),
      customTransition:_sharedAxisX,
    ),
  ];
}
