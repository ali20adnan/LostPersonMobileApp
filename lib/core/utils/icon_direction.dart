import 'package:flutter/widgets.dart';

/// Phosphor's [PhosphorIconData] hard-codes `matchTextDirection: true`, so under
/// the app's global RTL [Directionality] every asymmetric glyph — most visibly
/// the checkmark — renders horizontally mirrored.
///
/// `.ltr` returns an equivalent [IconData] with the flag cleared, keeping the
/// icon in its natural orientation regardless of text direction.
extension IconNoMirror on IconData {
  IconData get ltr => IconData(
        codePoint,
        fontFamily: fontFamily,
        fontPackage: fontPackage,
        fontFamilyFallback: fontFamilyFallback,
        matchTextDirection: false,
      );
}
