import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/themes/app_theme.dart';
import 'app/services/api_service.dart';
import 'app/services/auth_service.dart';
import 'app/services/socket_service.dart';
import 'app/services/storage_service.dart';
import 'app/services/unread_count_service.dart';
import 'core/widgets/app_error_widget.dart';
import 'core/widgets/islamic/sacred_background.dart';
import 'features/missing_persons/services/pending_found_requests_service.dart';
import 'features/notifications/bindings/app_notifications_bootstrap.dart';
import 'features/notifications/services/app_notifications_service.dart';
import 'features/settings/controllers/settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Replace the default red error screen with a user-friendly Arabic widget
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('ErrorWidget: ${details.exception}');
    return AppErrorWidget(errorDetails: details);
  };

  // Catch Flutter framework errors (render, build, layout)
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('FlutterError: ${details.exception}');
    debugPrint('${details.stack}');
  };

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Error loading .env file: $e');
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize API & Auth services globally
  await Get.putAsync<ApiService>(() async => ApiService());
  await Get.putAsync<AuthService>(() => AuthService().init());

  // StorageService must be registered BEFORE SettingsController because
  // the controller's field initializer does Get.find<StorageService>() to
  // back its toggles (auto-detect, auto-tts, auto-save, notifications).
  await Get.putAsync<StorageService>(() async {
    final s = StorageService();
    await s.init();
    return s;
  });

  // Initialize settings (dark mode, notifications)
  Get.put(SettingsController(), permanent: true);

  // Tracks volunteer "found" requests awaiting approval (in-memory, app-wide).
  Get.put(PendingFoundRequestsService(), permanent: true);

  // Initialize Socket.IO if user is already logged in
  final authService = Get.find<AuthService>();
  if (authService.isLoggedIn) {
    await Get.putAsync<SocketService>(() => SocketService().init());
    await Get.putAsync<UnreadCountService>(() => UnreadCountService().init());
    await Get.putAsync<AppNotificationsService>(
        () => AppNotificationsService().init());
    await AppNotificationsBootstrap.setup();
  }

  // Wrap runApp in runZonedGuarded to catch uncaught async errors
  runZonedGuarded(
    () => runApp(const SpeechTranslatorApp()),
    (error, stack) {
      debugPrint('Uncaught async error: $error');
      debugPrint('$stack');
    },
  );
}

class SpeechTranslatorApp extends StatelessWidget {
  const SpeechTranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: dotenv.env['APP_NAME'] ?? 'الملاذ',
      debugShowCheckedModeBanner: false,

      // Arabic RTL support
      locale: const Locale('ar', 'IQ'),
      fallbackLocale: const Locale('en', 'US'),
      supportedLocales: const [
        Locale('ar', 'IQ'),
        Locale('ar'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // GetX Navigation
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,

      // RTL text direction + the app-wide "sacred" backdrop (login identity).
      // The gradient + star pattern sits statically behind every route, so any
      // screen with a transparent Scaffold inherits the same surface as login.
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SacredBackground(child: child!),
        );
      },
    );
  }
}
