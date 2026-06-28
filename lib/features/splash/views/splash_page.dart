import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/themes/app_colors.dart';
import '../../../core/widgets/islamic/dome_silhouette.dart';
import '../../../core/widgets/islamic/islamic_pattern_painter.dart';
import '../controllers/splash_controller.dart';

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is initialized
    Get.find<SplashController>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF004D40), Color(0xFF0A1628)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Islamic pattern overlay
            Positioned.fill(
              child: IslamicPatternOverlay(
                color: Colors.white.withValues(alpha: 0.03),
                cellSize: 50,
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Bismillah
                  Text(
                    'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentLight,
                    ),
                  )
                      .animate()
                      .fadeIn(
                        duration: 800.ms,
                        delay: 200.ms,
                      )
                      .slideY(begin: -0.3, end: 0),

                  const SizedBox(height: 40),

                  // Dome silhouette
                  const DomeSilhouette(
                    width: 280,
                    height: 220,
                    domeColor: Color(0xFFC49B00),
                    minaretColor: Color(0xFFFFD54F),
                    showGlow: true,
                  )
                      .animate()
                      .fadeIn(duration: 1200.ms, delay: 400.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                        duration: 1200.ms,
                        delay: 400.ms,
                        curve: Curves.easeOutBack,
                      ),

                  const SizedBox(height: 32),

                  // App name
                  Text(
                    'الملاذ',
                    style: GoogleFonts.cairo(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: AppColors.accent.withValues(alpha: 0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 1000.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'العتبة العسكرية المقدسة',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accentLight.withValues(alpha: 0.7),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 1300.ms)
                      .slideY(begin: 0.3, end: 0),
                ],
              ),
            ),

            // Bottom decoration
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.accentLight.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 1800.ms),
            ),
          ],
        ),
      ),
    );
  }
}
