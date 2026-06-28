import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Service for handling location operations
class LocationService {
  /// Get current location
  /// Returns null if permission denied or location unavailable
  Future<Position?> getCurrentLocation() async {
    try {
      debugPrint('LocationService: Getting current location');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationService: Location services are disabled');
        return null;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('LocationService: Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('LocationService: Location permission permanently denied');
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint(
          'LocationService: Got location - Lat: ${position.latitude}, Lng: ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('LocationService: Error getting location - $e');
      return null;
    }
  }

  /// Get location with timeout
  Future<Position?> getCurrentLocationWithTimeout({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final position = await getCurrentLocation().timeout(
        timeout,
        onTimeout: () {
          debugPrint('LocationService: Location request timed out');
          return null;
        },
      );
      return position;
    } catch (e) {
      debugPrint('LocationService: Error getting location with timeout - $e');
      return null;
    }
  }

  /// Calculate distance between two positions in meters
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Format coordinates to string
  String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
