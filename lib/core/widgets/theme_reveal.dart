import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Circular-reveal theme switching (كشف الثيم بدائرة متوسّعة من نقطة الضغط).
///
/// Wrap the app's visible content in [ThemeReveal] (done once in
/// GetMaterialApp.builder). Calling [ThemeReveal.run] then:
///  1. captures a screenshot of the current (old-theme) UI,
///  2. shows it as a full-screen cover,
///  3. applies the theme change underneath,
///  4. animates a growing circular hole from [origin] that reveals the new
///     theme, then removes the cover.
///
/// Falls back to an instant switch when capture fails, animations are
/// disabled (accessibility), or a reveal is already in progress.
class ThemeReveal extends StatefulWidget {
  ThemeReveal({required this.child}) : super(key: _hostKey);

  final Widget child;

  /// Single host instance lives in GetMaterialApp.builder.
  static final GlobalKey<_ThemeRevealState> _hostKey =
      GlobalKey<_ThemeRevealState>();

  /// Switch theme with a circular reveal expanding from [origin]
  /// (global/screen coordinates, e.g. the toggle's center).
  static Future<void> run({
    required Offset origin,
    required VoidCallback changeTheme,
  }) async {
    final state = _hostKey.currentState;
    if (state == null) {
      changeTheme();
      return;
    }
    await state._run(origin: origin, changeTheme: changeTheme);
  }

  @override
  State<ThemeReveal> createState() => _ThemeRevealState();
}

class _ThemeRevealState extends State<ThemeReveal>
    with SingleTickerProviderStateMixin {
  final GlobalKey _boundaryKey = GlobalKey();

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );

  ui.Image? _cover;
  Offset _origin = Offset.zero;

  @override
  void dispose() {
    _controller.dispose();
    _cover?.dispose();
    super.dispose();
  }

  Future<void> _run({
    required Offset origin,
    required VoidCallback changeTheme,
  }) async {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_cover != null || reduceMotion) {
      // Reveal already running, or animations disabled → instant switch.
      changeTheme();
      return;
    }

    // 1) Screenshot the current UI (old theme).
    ui.Image? shot;
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null || boundary.debugNeedsPaint) {
        changeTheme();
        return;
      }
      shot = await boundary.toImage(
        pixelRatio: MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0,
      );
    } catch (_) {
      changeTheme();
      return;
    }
    if (!mounted) {
      shot.dispose();
      changeTheme();
      return;
    }

    // 2) Cover the screen with the screenshot, 3) switch theme underneath.
    // Both land in the same frame, so the change is invisible until the
    // circle starts growing.
    setState(() {
      _cover = shot;
      _origin = origin;
    });
    changeTheme();

    // 4) Grow the hole, then drop the cover.
    try {
      await _controller.forward(from: 0);
    } finally {
      if (mounted) {
        setState(() {
          _cover?.dispose();
          _cover = null;
        });
      }
    }
  }

  double _maxRadius(Size size, Offset origin) {
    final dx = math.max(origin.dx, size.width - origin.dx);
    final dy = math.max(origin.dy, size.height - origin.dy);
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.rtl,
      children: [
        RepaintBoundary(key: _boundaryKey, child: widget.child),
        if (_cover != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final size = MediaQuery.sizeOf(context);
                  final t = Curves.easeInOutCubic.transform(_controller.value);
                  return ClipPath(
                    clipper: _HoleClipper(
                      center: _origin,
                      radius: _maxRadius(size, _origin) * t,
                    ),
                    child: RawImage(image: _cover, fit: BoxFit.fill),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// Clips to the full rect minus a circle — the "hole" that reveals the new
/// theme underneath as its radius grows.
class _HoleClipper extends CustomClipper<Path> {
  const _HoleClipper({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) {
    return Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldReclip(_HoleClipper oldClipper) =>
      oldClipper.radius != radius || oldClipper.center != center;
}
