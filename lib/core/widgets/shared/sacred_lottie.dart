import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../../../app/themes/app_motion.dart';

/// Project-standard Lottie player that:
/// - Gracefully falls back to [fallback] (or [SizedBox.shrink]) if the asset
///   is missing — so the app keeps shipping even if the JSON hasn't been
///   downloaded yet.
/// - Respects MediaQuery "reduce motion" by holding the final frame.
/// - Supports a one-shot or looping playback via [repeat].
class SacredLottie extends StatefulWidget {
  /// Asset path under `assets/lottie/` (e.g. `'assets/lottie/report_success.json'`).
  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool repeat;
  final VoidCallback? onCompleted;
  final Widget? fallback;
  final Color? tint;

  const SacredLottie({
    super.key,
    required this.asset,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.repeat = false,
    this.onCompleted,
    this.fallback,
    this.tint,
  });

  @override
  State<SacredLottie> createState() => _SacredLottieState();
}

class _SacredLottieState extends State<SacredLottie>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this);
  bool? _exists;

  @override
  void initState() {
    super.initState();
    _checkAssetExists();
    if (widget.onCompleted != null) {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onCompleted!();
      });
    }
  }

  Future<void> _checkAssetExists() async {
    try {
      await rootBundle.load(widget.asset);
      if (mounted) setState(() => _exists = true);
    } catch (_) {
      if (mounted) setState(() => _exists = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_exists == null) {
      return SizedBox(width: widget.width, height: widget.height);
    }
    if (_exists == false) {
      return widget.fallback ?? const SizedBox.shrink();
    }
    final reduced =
        AppMotion.respectReducedMotion(context, AppMotion.standard) ==
            Duration.zero;
    return Lottie.asset(
      widget.asset,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      controller: _controller,
      animate: !reduced,
      repeat: widget.repeat,
      delegates: widget.tint == null
          ? null
          : LottieDelegates(
              values: [
                ValueDelegate.color(const ['**'], value: widget.tint),
              ],
            ),
      onLoaded: (composition) {
        _controller
          ..duration = composition.duration
          ..reset();
        if (reduced) {
          _controller.value = 1.0;
        } else if (widget.repeat) {
          _controller.repeat();
        } else {
          _controller.forward();
        }
      },
    );
  }
}
