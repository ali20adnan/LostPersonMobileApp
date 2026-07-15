import '../constants/language_constants.dart';
import '../../data/models/language_model.dart';

/// Offline, heuristic language detector for the smart-paste button.
///
/// The app's supported languages fall into two script families:
///   • Latin script      → English (`en`)
///   • Arabic script      → Arabic / Persian / Urdu / Kurdish (Sorani)
///
/// Because Arabic, Persian, Urdu and Kurdish all share the Arabic script,
/// telling them apart cannot rely on the script alone — it looks for
/// **marker letters** that exist in one language but not the others.
///
/// This runs instantly on-device to update the language pill the moment the
/// user pastes. The translation itself is still verified server-side
/// (`source: 'auto'`), so a rare misclassification never corrupts the result.
class LanguageDetector {
  LanguageDetector._();

  // ── Marker-letter sets ─────────────────────────────────────────────
  // These are the tuning knobs. Each set holds letters that are (near-)
  // exclusive to one language, so their mere presence is a strong signal.

  /// Kurdish (Sorani) — the most distinctive family: ڕ ڵ ۆ ێ ە.
  static const Set<String> _kurdishMarkers = {
    'ڕ', 'ڵ', 'ۆ', 'ێ', 'ە', 'ھ',
  };

  /// Urdu — retroflex + special final forms not used in Persian/Arabic.
  static const Set<String> _urduMarkers = {
    'ٹ', 'ڈ', 'ڑ', 'ں', 'ے', 'ہ', 'ۂ', 'ۃ',
  };

  /// Persian — letters absent from Arabic (پ چ ژ گ) plus the Persian
  /// keheh/yeh forms (ک ی) that Arabic writes differently (ك ي).
  static const Set<String> _persianMarkers = {
    'پ', 'چ', 'ژ', 'گ', 'ک', 'ی',
  };

  /// Detect the language of [text] against the supported set.
  ///
  /// Returns the best-guess [Language], or `null` when the text carries no
  /// usable letters (only digits, punctuation or emoji) — the caller decides
  /// the fallback in that case.
  static Language? detect(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    var latin = 0;
    var arabicScript = 0;
    for (final rune in trimmed.runes) {
      if (_isLatinLetter(rune)) {
        latin++;
      } else if (_isArabicScriptLetter(rune)) {
        arabicScript++;
      }
    }

    // No letters at all → nothing to detect.
    if (latin == 0 && arabicScript == 0) return null;

    // Predominantly Latin → English.
    if (latin > arabicScript) return LanguageConstants.english;

    // Arabic-script family → disambiguate by marker letters.
    return _disambiguateArabicScript(trimmed);
  }

  /// Pick among Arabic-script languages using marker letters.
  ///
  /// Priority order matters: Kurdish and Urdu carry the most exclusive
  /// markers, so they are checked first; Persian markers overlap slightly
  /// with Urdu (ک/ی), so it comes last before the Arabic default.
  static Language _disambiguateArabicScript(String text) {
    if (_containsAny(text, _kurdishMarkers)) return LanguageConstants.kurdish;
    if (_containsAny(text, _urduMarkers)) return LanguageConstants.urdu;
    if (_containsAny(text, _persianMarkers)) return LanguageConstants.persian;
    // Arabic script with none of the above markers → Arabic.
    return LanguageConstants.arabic;
  }

  static bool _containsAny(String text, Set<String> markers) {
    for (final marker in markers) {
      if (text.contains(marker)) return true;
    }
    return false;
  }

  // ── Unicode range helpers ──────────────────────────────────────────

  static bool _isLatinLetter(int rune) =>
      (rune >= 0x41 && rune <= 0x5A) || // A-Z
      (rune >= 0x61 && rune <= 0x7A); // a-z

  static bool _isArabicScriptLetter(int rune) =>
      (rune >= 0x0620 && rune <= 0x064A) || // core Arabic letters
      (rune >= 0x0660 && rune <= 0x06FF) || // Arabic supplement (fa/ur/ku)
      (rune >= 0x0750 && rune <= 0x077F) || // Arabic Supplement block
      (rune >= 0xFB50 && rune <= 0xFDFF) || // Arabic Presentation Forms-A
      (rune >= 0xFE70 && rune <= 0xFEFF); // Arabic Presentation Forms-B
}
