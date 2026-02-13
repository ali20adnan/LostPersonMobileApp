class TranslationMessage {
  final String originalText;
  final String translatedText;
  final DateTime timestamp;
  final bool isFinal;

  TranslationMessage({
    required this.originalText,
    required this.translatedText,
    required this.timestamp,
    this.isFinal = false,
  });

  TranslationMessage copyWith({
    String? originalText,
    String? translatedText,
    DateTime? timestamp,
    bool? isFinal,
  }) {
    return TranslationMessage(
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      timestamp: timestamp ?? this.timestamp,
      isFinal: isFinal ?? this.isFinal,
    );
  }
}
