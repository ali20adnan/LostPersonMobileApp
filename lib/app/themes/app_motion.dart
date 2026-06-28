import 'package:flutter/material.dart';

/// Centralized motion-design tokens for the app.
///
/// Use these instead of hard-coding durations and curves so the motion language
/// stays consistent (calm, decelerated, RTL-aware) and can be tuned globally.
class AppMotion {
  AppMotion._();

  // ── Durations ──────────────────────────────────────────────────
  /// 100ms — instant feedback (chip press, toggle).
  static const instant = Duration(milliseconds: 100);

  /// 200ms — quick state changes (icon rotation, small fades).
  static const quick = Duration(milliseconds: 200);

  /// 300ms — standard entrance / dismiss.
  static const standard = Duration(milliseconds: 300);

  /// 450ms — emphasized hero / container transforms.
  static const emphasized = Duration(milliseconds: 450);

  /// 700ms — slow ambient transitions (success ripples, Lottie hand-off).
  static const slow = Duration(milliseconds: 700);

  // ── Curves ─────────────────────────────────────────────────────
  /// Default ease for most entrances.
  static const standardCurve = Curves.easeOutCubic;

  /// Material decelerate — settle-in motion.
  static const decelerate = Cubic(0.0, 0.0, 0.2, 1.0);

  /// Material accelerate — leave-screen motion.
  static const accelerate = Cubic(0.4, 0.0, 1.0, 1.0);

  /// Material 3 "emphasized" — premium hero feel.
  static const emphasizedCurve = Cubic(0.2, 0.0, 0.0, 1.0);

  // ── Stagger intervals ─────────────────────────────────────────
  /// 40ms — tight stagger for compact lists.
  static const staggerSm = Duration(milliseconds: 40);

  /// 70ms — comfortable stagger for cards / form fields.
  static const staggerMd = Duration(milliseconds: 70);

  // ── Accessibility ─────────────────────────────────────────────
  /// Returns [Duration.zero] when the user has system-level "reduce motion"
  /// enabled; otherwise returns [duration] unchanged.
  static Duration respectReducedMotion(BuildContext context, Duration duration) {
    if (MediaQuery.disableAnimationsOf(context)) return Duration.zero;
    return duration;
  }
}
