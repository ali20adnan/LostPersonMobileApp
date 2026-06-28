import 'package:flutter/foundation.dart';

/// Maps technical error messages to user-friendly Arabic messages.
class ErrorMapper {
  ErrorMapper._();

  static final _patterns = <RegExp, String>{
    RegExp(r'TextEditingController.*disposed'):
        'حدث خطأ أثناء الانتقال بين الصفحات، يرجى إعادة المحاولة',
    RegExp(r'setState.*mounted'):
        'حدث خطأ أثناء تحديث الصفحة، يرجى إعادة المحاولة',
    RegExp(r'RenderFlex|overflowed'):
        'حدث خطأ في عرض المحتوى، يرجى تدوير الشاشة أو تغيير حجم النص',
    RegExp(r'Socket|Connection refused|Connection reset'):
        'لا يمكن الاتصال بالخادم، تحقق من اتصال الإنترنت',
    RegExp(r'TimeoutException|timed?\s*out'):
        'انتهت مهلة الاتصال، تحقق من اتصال الإنترنت وحاول مرة أخرى',
    RegExp(r'NetworkImage|HttpException.*image|Failed to load'):
        'فشل تحميل الصورة، تحقق من اتصال الإنترنت',
    RegExp(r'FormatException|type.*is not a subtype'):
        'حدث خطأ في معالجة البيانات، يرجى إعادة المحاولة',
    RegExp(r'Null check|null'):
        'حدث خطأ في تحميل البيانات، يرجى إعادة المحاولة',
    RegExp(r'Permission|denied'):
        'لا تملك الصلاحيات الكافية للقيام بهذا الإجراء',
    RegExp(r'No.*internet|SocketException|NetworkException'):
        'لا يوجد اتصال بالإنترنت، تحقق من الشبكة وحاول مرة أخرى',
  };

  static const _defaultMessage =
      'حدث خطأ غير متوقع، يرجى إعادة المحاولة أو إعادة تشغيل التطبيق';

  /// Converts a technical error into an Arabic user-friendly message.
  static String toArabic(dynamic error) {
    final message = error.toString();
    for (final entry in _patterns.entries) {
      if (entry.key.hasMatch(message)) {
        return entry.value;
      }
    }
    debugPrint('ErrorMapper: Unmapped error → $message');
    return _defaultMessage;
  }
}
