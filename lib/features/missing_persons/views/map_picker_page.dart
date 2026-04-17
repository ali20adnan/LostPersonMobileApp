import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Full-screen map picker — tap to place a pin, confirm to return LatLng.
class MapPickerPage extends StatefulWidget {
  /// Optional initial location to show when opening the picker.
  final LatLng? initialLocation;

  const MapPickerPage({super.key, this.initialLocation});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  // Default center: Baghdad
  static const _defaultCenter = LatLng(33.3152, 44.3661);

  late final MapController _mapController;
  LatLng? _selected;
  bool _loadingGps = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selected = widget.initialLocation;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _loadingGps = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        Get.snackbar('إذن مطلوب', 'يتطلب الوصول إلى الموقع',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final latLng = LatLng(position.latitude, position.longitude);
      _mapController.move(latLng, 15.0);
      setState(() => _selected = latLng);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحديد الموقع',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _loadingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحديد الموقع على الخريطة'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1a1a2e),
        foregroundColor: Colors.white,
        actions: [
          if (_selected != null)
            TextButton.icon(
              onPressed: () => Get.back(result: _selected),
              icon: const Icon(Icons.check, color: Colors.greenAccent),
              label: const Text('تأكيد',
                  style: TextStyle(color: Colors.greenAccent)),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selected ?? _defaultCenter,
              initialZoom: _selected != null ? 15.0 : 6.0,
              onTap: (tapPosition, latLng) {
                setState(() => _selected = latLng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.speech_translator_app',
              ),
              if (_selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selected!,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 48,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Top hint
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _selected == null
                    ? 'اضغط على الخريطة لتحديد الموقع'
                    : 'خط العرض: ${_selected!.latitude.toStringAsFixed(5)}  |  خط الطول: ${_selected!.longitude.toStringAsFixed(5)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Bottom confirm button (always visible when location selected)
          if (_selected != null)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: ElevatedButton.icon(
                onPressed: () => Get.back(result: _selected),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('تأكيد الموقع',
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4a9eff),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),

      // GPS FAB
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1a1a2e),
        foregroundColor: Colors.white,
        onPressed: _loadingGps ? null : _goToCurrentLocation,
        child: _loadingGps
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.my_location),
      ),
    );
  }
}
