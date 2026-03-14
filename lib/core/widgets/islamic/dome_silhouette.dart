import 'package:flutter/material.dart';

/// Draws the silhouette of the Al-Askari Shrine in Samarra:
/// A central golden dome flanked by two minarets.
class DomeSilhouettePainter extends CustomPainter {
  final Color domeColor;
  final Color minaretColor;
  final Color? glowColor;

  DomeSilhouettePainter({
    required this.domeColor,
    required this.minaretColor,
    this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Glow behind dome
    if (glowColor != null) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [glowColor!, glowColor!.withValues(alpha: 0)],
        ).createShader(
          Rect.fromCircle(center: Offset(w * 0.5, h * 0.45), radius: w * 0.35),
        );
      canvas.drawCircle(Offset(w * 0.5, h * 0.45), w * 0.35, glowPaint);
    }

    final domePaint = Paint()
      ..color = domeColor
      ..style = PaintingStyle.fill;

    final minaretPaint = Paint()
      ..color = minaretColor
      ..style = PaintingStyle.fill;

    // ── Central Dome ─────────────────────────────────────────
    final domePath = Path();
    final domeBase = h * 0.55;
    final domeTop = h * 0.12;
    final domeLeft = w * 0.25;
    final domeRight = w * 0.75;

    // Dome body (base)
    domePath.moveTo(domeLeft, domeBase);

    // Left curve up to top
    domePath.cubicTo(
      domeLeft, domeBase - (domeBase - domeTop) * 0.5,
      w * 0.35, domeTop,
      w * 0.5, domeTop,
    );
    // Right curve from top down
    domePath.cubicTo(
      w * 0.65, domeTop,
      domeRight, domeBase - (domeBase - domeTop) * 0.5,
      domeRight, domeBase,
    );

    domePath.close();
    canvas.drawPath(domePath, domePaint);

    // Dome finial (crescent tip)
    final finialY = domeTop - h * 0.02;
    canvas.drawCircle(Offset(w * 0.5, finialY), w * 0.02, domePaint);
    // Crescent
    final crescentPath = Path();
    crescentPath.addOval(Rect.fromCircle(
      center: Offset(w * 0.5, finialY - w * 0.025),
      radius: w * 0.015,
    ));
    canvas.drawPath(crescentPath, domePaint);

    // ── Drum (base structure under dome) ─────────────────────
    final drumPath = Path();
    drumPath.addRect(Rect.fromLTRB(
      domeLeft - w * 0.02,
      domeBase,
      domeRight + w * 0.02,
      h * 0.72,
    ));
    canvas.drawPath(drumPath, domePaint);

    // Arched windows on drum
    final windowPaint = Paint()
      ..color = domeColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 5; i++) {
      final wx = domeLeft + w * 0.02 + (i * (domeRight - domeLeft) / 5) + (domeRight - domeLeft) / 10;
      final wy = domeBase + (h * 0.72 - domeBase) * 0.3;
      final wh = (h * 0.72 - domeBase) * 0.5;
      final ww = (domeRight - domeLeft) / 8;

      final windowPath = Path();
      windowPath.moveTo(wx - ww, wy + wh);
      windowPath.lineTo(wx - ww, wy);
      windowPath.quadraticBezierTo(wx, wy - wh * 0.3, wx + ww, wy);
      windowPath.lineTo(wx + ww, wy + wh);
      canvas.drawPath(windowPath, windowPaint);
    }

    // ── Base platform ────────────────────────────────────────
    final basePath = Path();
    basePath.addRect(Rect.fromLTRB(
      w * 0.1,
      h * 0.72,
      w * 0.9,
      h * 0.78,
    ));
    canvas.drawPath(basePath, domePaint);

    // ── Left Minaret ─────────────────────────────────────────
    _drawMinaret(canvas, w * 0.15, h, w, minaretPaint, domePaint);

    // ── Right Minaret ────────────────────────────────────────
    _drawMinaret(canvas, w * 0.85, h, w, minaretPaint, domePaint);
  }

  void _drawMinaret(
      Canvas canvas, double cx, double h, double w, Paint bodyPaint, Paint capPaint) {
    final mw = w * 0.05; // minaret width
    final mBottom = h * 0.78;
    final mTop = h * 0.2;

    // Minaret body
    final bodyPath = Path();
    bodyPath.moveTo(cx - mw, mBottom);
    bodyPath.lineTo(cx - mw * 0.7, mTop + h * 0.15);
    bodyPath.lineTo(cx + mw * 0.7, mTop + h * 0.15);
    bodyPath.lineTo(cx + mw, mBottom);
    bodyPath.close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Balcony ring
    final balconyY = mTop + h * 0.15;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, balconyY),
        width: mw * 2.2,
        height: h * 0.015,
      ),
      capPaint,
    );

    // Upper section
    final upperPath = Path();
    upperPath.moveTo(cx - mw * 0.5, balconyY);
    upperPath.lineTo(cx - mw * 0.3, mTop + h * 0.05);
    upperPath.lineTo(cx + mw * 0.3, mTop + h * 0.05);
    upperPath.lineTo(cx + mw * 0.5, balconyY);
    upperPath.close();
    canvas.drawPath(upperPath, bodyPaint);

    // Minaret cap (small dome)
    final capY = mTop + h * 0.05;
    final capPath = Path();
    capPath.moveTo(cx - mw * 0.35, capY);
    capPath.quadraticBezierTo(cx, mTop - h * 0.02, cx + mw * 0.35, capY);
    capPath.close();
    canvas.drawPath(capPath, capPaint);

    // Finial
    canvas.drawCircle(Offset(cx, mTop - h * 0.025), w * 0.008, capPaint);
  }

  @override
  bool shouldRepaint(covariant DomeSilhouettePainter old) =>
      old.domeColor != domeColor || old.minaretColor != minaretColor;
}

/// Widget that displays the Al-Askari shrine silhouette.
class DomeSilhouette extends StatelessWidget {
  final double width;
  final double height;
  final Color? domeColor;
  final Color? minaretColor;
  final bool showGlow;

  const DomeSilhouette({
    super.key,
    this.width = 250,
    this.height = 200,
    this.domeColor,
    this.minaretColor,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final dc = domeColor ?? const Color(0xFFC49B00);
    final mc = minaretColor ?? const Color(0xFFC49B00);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        size: Size(width, height),
        painter: DomeSilhouettePainter(
          domeColor: dc,
          minaretColor: mc,
          glowColor: showGlow ? dc.withValues(alpha: 0.2) : null,
        ),
      ),
    );
  }
}
