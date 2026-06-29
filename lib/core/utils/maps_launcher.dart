import 'package:get/get.dart';
import 'package:speech_translator_app/core/utils/app_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens Google Maps directions from the user's current location to [lat]/[lng]
/// or [address]. Google Maps uses the device's current location as the origin
/// automatically when no origin is specified.
Future<void> openMapsDirections({
  double? lat,
  double? lng,
  String? address,
}) async {
  String destination;

  if (lat != null && lng != null) {
    destination = '$lat,$lng';
  } else if (address != null && address.isNotEmpty) {
    destination = Uri.encodeComponent(address);
  } else {
    return;
  }

  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$destination',
  );

  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    AppSnackbar.glass(
      'خطأ',
      'تعذّر فتح خرائط Google',
      snackPosition: SnackPosition.TOP,
    );
  }
}
