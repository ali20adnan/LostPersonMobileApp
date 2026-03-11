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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Initialize Socket.IO if user is logged in
  final authService = Get.find<AuthService>();

  // ── Temporary auto-login ──────────────────────────────────────────────
  if (!authService.isLoggedIn) {
    try {
      final result = await authService.login('qader', 'admin123');
      if (result.isSuccess) {
        debugPrint('Auto-login successful as qader');
        await Get.putAsync<SocketService>(() => SocketService().init());
      }
    } catch (e) {
      debugPrint('Auto-login failed: $e');
    }
  }
  // ─────────────────────────────────────────────────────────────────────

  if (authService.isLoggedIn) {
    await Get.putAsync<SocketService>(() => SocketService().init());
  }

  runApp(const SpeechTranslatorApp());
}

class SpeechTranslatorApp extends StatelessWidget {
  const SpeechTranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final initialRoute =
        authService.isLoggedIn ? AppRoutes.home : AppRoutes.login;

    return GetMaterialApp(
      title: dotenv.env['APP_NAME'] ?? 'مساعد الحرم - العثور على المفقودين',
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
      themeMode: ThemeMode.light,

      // GetX Navigation
      initialRoute: initialRoute,
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
