import 'package:flutter/material.dart';

/// Clips a widget with an Islamic pointed arch shape.
/// Used for SliverAppBar headers and decorative card tops.
class IslamicArchClipper extends CustomClipper<Path> {
  /// How much of the bottom to arch (0.0 - 1.0)
  final double archDepth;

  IslamicArchClipper({this.archDepth = 0.08});

  @override
  Path getClip(Size size) {
    final path = Path();
    final archHeight = size.height * archDepth;

    path.lineTo(0, size.height - archHeight);

    // Islamic pointed arch curve
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height + archHeight * 0.3,
      size.width * 0.5,
      size.height,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height + archHeight * 0.3,
      size.width,
      size.height - archHeight,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant IslamicArchClipper oldClipper) =>
      oldClipper.archDepth != archDepth;
}

/// A convenience widget that wraps a child in an Islamic arch clip.
class IslamicArchHeader extends StatelessWidget {
  final Widget child;
  final double archDepth;

  const IslamicArchHeader({
    super.key,
    required this.child,
    this.archDepth = 0.08,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: IslamicArchClipper(archDepth: archDepth),
      child: child,
    );
  }
}
