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
import 'app/services/unread_count_service.dart';
import 'core/widgets/app_error_widget.dart';
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

  // Initialize settings (dark mode, notifications)
  Get.put(SettingsController(), permanent: true);

  // Initialize Socket.IO if user is already logged in
  final authService = Get.find<AuthService>();
  if (authService.isLoggedIn) {
    await Get.putAsync<SocketService>(() => SocketService().init());
    await Get.putAsync<UnreadCountService>(() => UnreadCountService().init());
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

      // RTL text direction
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
  }
}
