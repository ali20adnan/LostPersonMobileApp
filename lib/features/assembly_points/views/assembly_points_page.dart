import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/themes/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/assembly_point_model.dart';
import '../assembly_point_visuals.dart';
import '../controllers/assembly_points_controller.dart';
import '../widgets/assembly_point_form_sheet.dart';

/// Full-screen interactive map of assembly points ("نقاط التجمّع").
///
/// This mirrors the web feature 1:1: small colored dots, an info **popup** on
/// tap (name + volunteer badge + nearest place + volunteer avatars), and a
/// points list whose rows carry the management actions (edit / toggle / open in
/// maps / delete). Create & edit use a non-modal bottom panel that coexists
/// with an interactive map, so the draggable pin can be moved while the form is
/// open (this unifies create + edit + relocate exactly like the web).
class AssemblyPointsPage extends StatefulWidget {
  const AssemblyPointsPage({super.key});

  @override
  State<AssemblyPointsPage> createState() => _AssemblyPointsPageState();
}

class _AssemblyPointsPageState extends State<AssemblyPointsPage> {
  // Default center: Samarra (matches the web map's home view).
  static const LatLng _defaultCenter = LatLng(34.1959, 43.8742);

  // Restrict panning to the Samarra region (mirrors the web SAMARRA_BOUNDS).
  static final LatLngBounds _samarraBounds = LatLngBounds(
    const LatLng(34.05, 43.75),
    const LatLng(34.35, 44.02),
  );

  final _controller = Get.find<AssemblyPointsController>();
  final _mapController = MapController();
  bool _loadingGps = false;

  /// The user's last known GPS position, shown as a "you are here" dot.
  LatLng? _myLocation;

  /// While the form is open, the draft location of the new/edited point.
  LatLng? _draft;

  /// Whether the create/edit panel is open. While open the map is in placing
  /// mode and a draggable pin tracks [_draft].
  bool _formOpen = false;

  /// The point being edited (null = creating a new point).
  AssemblyPoint? _editing;

  bool _didFit = false;
  Worker? _pointsWorker;

  @override
  void initState() {
    super.initState();
    // Auto-fit the camera to all points the first time they arrive (like the
    // web's fitBounds on load).
    _pointsWorker = ever<List<AssemblyPoint>>(_controller.points, (list) {
      if (!_didFit && list.isNotEmpty) {
        _didFit = true;
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _fitToPoints(list));
      }
    });
    if (!_didFit && _controller.points.isNotEmpty) {
      _didFit = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _fitToPoints(_controller.points));
    }
  }

  @override
  void dispose() {
    _pointsWorker?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── Map helpers ────────────────────────────────────────────────

  void _fitToPoints(List<AssemblyPoint> list) {
    final pts = list
        .where((p) => p.latitude.isFinite && p.longitude.isFinite)
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      _mapController.move(pts.first, 14);
    } else {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: pts,
          padding: const EdgeInsets.all(60),
          maxZoom: 14,
        ),
      );
    }
  }

  void _focusPoint(AssemblyPoint p) {
    _controller.select(p.id);
    _mapController.move(LatLng(p.latitude, p.longitude), 15);
  }

  void _zoom(double delta) {
    final z = (_mapController.camera.zoom + delta).clamp(11.0, 18.0);
    _mapController.move(_mapController.camera.center, z);
  }

  Future<void> _goToMyLocation() async {
    setState(() => _loadingGps = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        AppSnackbar.glass('إذن مطلوب', 'يتطلب الوصول إلى الموقع');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final me = LatLng(pos.latitude, pos.longitude);
      if (mounted) setState(() => _myLocation = me);
      _mapController.move(me, 16);
    } catch (_) {
      AppSnackbar.glass('خطأ', 'فشل تحديد موقعك الحالي');
    } finally {
      if (mounted) setState(() => _loadingGps = false);
    }
  }

  void _onMapTap(LatLng latLng) {
    if (_formOpen) {
      // While the form is open, tapping drops/moves the draggable draft pin.
      setState(() => _draft = latLng);
    } else {
      // Otherwise a tap on empty map closes any open popup.
      _controller.select(null);
    }
  }

  // ── Create / edit flow (non-modal panel) ───────────────────────

  void _openCreateForm() {
    HapticFeedback.lightImpact();
    _controller.select(null);
    setState(() {
      _editing = null;
      _draft = null;
      _formOpen = true;
    });
    _controller.setPlacingMode(true);
  }

  void _openEditForm(AssemblyPoint p) {
    HapticFeedback.lightImpact();
    _controller.select(null);
    setState(() {
      _editing = p;
      _draft = LatLng(p.latitude, p.longitude);
      _formOpen = true;
    });
    _controller.setPlacingMode(true);
    _mapController.move(LatLng(p.latitude, p.longitude), 16);
  }

  void _closeForm() {
    setState(() {
      _formOpen = false;
      _editing = null;
      _draft = null;
    });
    _controller.setPlacingMode(false);
  }

  // ── Row actions (shared by the list) ───────────────────────────

  Future<void> _toggleActive(AssemblyPoint p) async {
    final wasActive = p.isActive;
    final res = await _controller.toggleActive(p);
    AppSnackbar.glass(
      res.isSuccess ? 'تم' : 'خطأ',
      res.isSuccess
          ? (wasActive ? 'تم تعطيل النقطة' : 'تم تفعيل النقطة')
          : (res.errorMessage ?? 'فشل تحديث حالة النقطة'),
    );
  }

  Future<void> _confirmDelete(AssemblyPoint p) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('حذف النقطة'),
        content: Text(
            'هل أنت متأكد من حذف نقطة «${p.name}»؟ سيتم فكّ ارتباط جميع المتطوعين عنها. لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final res = await _controller.deletePoint(p.id);
      AppSnackbar.glass(
        res.isSuccess ? 'تم' : 'خطأ',
        res.isSuccess
            ? 'تم حذف النقطة بنجاح'
            : (res.errorMessage ?? 'فشل حذف النقطة'),
      );
    }
  }

  Future<void> _openInMaps(AssemblyPoint p) async {
    final uri = Uri.parse(
        'https://www.google.com/maps?q=${p.latitude},${p.longitude}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      AppSnackbar.glass('خطأ', 'تعذّر فتح تطبيق الخرائط');
    }
  }

  void _openList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PointsListSheet(
        controller: _controller,
        canManage: _controller.canManage,
        onSelect: (p) {
          Navigator.pop(context);
          _focusPoint(p);
        },
        onEdit: (p) {
          Navigator.pop(context);
          _openEditForm(p);
        },
        onToggle: _toggleActive,
        onDelete: _confirmDelete,
        onNavigate: _openInMaps,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    // Bottom controls must clear the floating nav bar (height 72 + 12 margin
    // + bottom safe-area) — keep them above the home indicator on iOS.
    final controlsBottom = 110 + bottomPad;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── The map ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 13,
              minZoom: 11,
              maxZoom: 18,
              cameraConstraint:
                  CameraConstraint.contain(bounds: _samarraBounds),
              onTap: (_, latLng) => _onMapTap(latLng),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.speech_translator_app',
              ),
              // Plain colored dots (web parity).
              Obx(() => MarkerLayer(markers: _buildMarkers())),
              // "You are here" dot (only after the GPS button is used).
              if (_myLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _myLocation!,
                      width: 30,
                      height: 30,
                      child: const _MyLocationDot(),
                    ),
                  ],
                ),
              // Info popup above the selected point (web parity).
              Obx(() => MarkerLayer(markers: _popupMarkers(isDark))),
              // Draggable draft pin while the form is open.
              if (_formOpen && _draft != null)
                DragMarkers(
                  markers: [
                    DragMarker(
                      point: _draft!,
                      size: const Size(48, 48),
                      alignment: Alignment.topCenter,
                      builder: (context, pos, isDragging) => Icon(
                        Icons.location_pin,
                        size: 48,
                        color: isDragging ? Colors.redAccent : AppColors.accent,
                      ),
                      onDragEnd: (details, point) =>
                          setState(() => _draft = point),
                    ),
                  ],
                ),
            ],
          ),

          // ── Top banner: placing-mode hint or "نقطتي" chip ──
          Positioned(
            top: topPad + 64,
            left: 16,
            right: 16,
            child: _formOpen
                ? _placingBanner(isDark)
                : Obx(() => _topChip(isDark)),
          ),

          // ── Loading indicator ──
          Obx(() => _controller.isLoading.value
              ? Positioned(
                  top: topPad + 64,
                  left: 0,
                  right: 0,
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink()),

          // ── Zoom controls (right) ──
          Positioned(
            right: 16,
            bottom: controlsBottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _smallFab(
                  icon: Icons.add,
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  iconColor: AppColors.primary,
                  onTap: () => _zoom(1),
                ),
                const Gap(12),
                _smallFab(
                  icon: Icons.remove,
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  iconColor: AppColors.primary,
                  onTap: () => _zoom(-1),
                ),
              ],
            ),
          ),

          // ── Bottom-left action FABs ──
          Positioned(
            left: 16,
            bottom: controlsBottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_controller.canManage && !_formOpen)
                  _smallFab(
                    icon: PhosphorIcons.plus(),
                    color: AppColors.accent,
                    onTap: _openCreateForm,
                  ),
                const Gap(12),
                _smallFab(
                  icon: _loadingGps
                      ? null
                      : PhosphorIcons.navigationArrow(PhosphorIconsStyle.fill),
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  iconColor: AppColors.accent,
                  loading: _loadingGps,
                  onTap: _loadingGps ? null : _goToMyLocation,
                ),
              ],
            ),
          ),

          // ── Bottom-center "list" pill (hidden while the form is open) ──
          if (!_formOpen)
            Positioned(
              left: 0,
              right: 0,
              bottom: controlsBottom,
              child: Center(child: Obx(() => _listPill(isDark))),
            ),

          // ── Create / edit panel (non-modal, slides up) ──
          if (_formOpen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AssemblyPointFormSheet(
                key: ValueKey(_editing?.id ?? 'new'),
                existing: _editing,
                latitude: _draft?.latitude,
                longitude: _draft?.longitude,
                onClose: _closeForm,
              )
                  .animate()
                  .slideY(
                      begin: 1,
                      end: 0,
                      duration: 250.ms,
                      curve: Curves.easeOutCubic),
            ),
        ],
      ),
    );
  }

  // ── Marker building ────────────────────────────────────────────

  List<Marker> _buildMarkers() {
    final placing = _controller.placingMode.value;
    return _controller.points.map((p) {
      final color = p.isActive
          ? assemblyPointColor(p.color)
          : kAssemblyPointInactiveColor;
      return Marker(
        point: LatLng(p.latitude, p.longitude),
        width: 24,
        height: 24,
        child: GestureDetector(
          onTap: placing
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  _focusPoint(p);
                },
          child: _MarkerDot(color: color, active: p.isActive),
        ),
      );
    }).toList();
  }

  List<Marker> _popupMarkers(bool isDark) {
    if (_controller.placingMode.value) return const [];
    final id = _controller.selectedId.value;
    if (id == null) return const [];
    final p = _controller.points.firstWhereOrNull((x) => x.id == id);
    if (p == null) return const [];
    return [
      Marker(
        point: LatLng(p.latitude, p.longitude),
        width: 260,
        height: 320,
        alignment: Alignment.bottomCenter,
        child: _PointPopup(point: p, isDark: isDark),
      ),
    ];
  }

  // ── Small UI pieces ────────────────────────────────────────────

  Widget _placingBanner(bool isDark) {
    final hasDraft = _draft != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Icon(PhosphorIcons.mapPin(), color: Colors.white, size: 20),
          const Gap(10),
          Expanded(
            child: Text(
              hasDraft
                  ? 'تم تحديد الموقع — يمكنك سحب العلامة لضبطه'
                  : 'انقر على الخريطة لتحديد موقع النقطة',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topChip(bool isDark) {
    final myId = _controller.myPointId;
    AssemblyPoint? myPoint;
    if (myId != null) {
      myPoint = _controller.points.firstWhereOrNull((p) => p.id == myId);
    }
    // Volunteers with an assigned point get a tappable "نقطتي" chip.
    if (myPoint != null) {
      final mp = myPoint;
      return Align(
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () => _focusPoint(mp),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDark.withValues(alpha: 0.92)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(30),
              boxShadow: AppColors.cardShadow,
              border: Border.all(color: assemblyPointColor(mp.color), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
                    color: assemblyPointColor(mp.color), size: 18),
                const Gap(8),
                Text('نقطتي: ${mp.name}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? AppColors.textOnDark : AppColors.textPrimary)),
              ],
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _listPill(bool isDark) {
    final count = _controller.points.length;
    return GestureDetector(
      onTap: _openList,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark.withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(30),
          boxShadow: AppColors.cardShadow,
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.listBullets(), color: AppColors.accent, size: 20),
            const Gap(8),
            Text(
              'النقاط ($count)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallFab({
    IconData? icon,
    required Color color,
    Color? iconColor,
    bool loading = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: AppColors.cardShadow,
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, color: iconColor ?? Colors.white, size: 22),
      ),
    );
  }
}

// ── Marker dot widget (small colored circle, web parity) ────────────
class _MarkerDot extends StatelessWidget {
  final Color color;
  final bool active;

  const _MarkerDot({required this.color, required this.active});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color.withValues(alpha: active ? 0.95 : 0.55),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info popup above the selected marker (mirrors web buildPopupHtml) ──
class _PointPopup extends StatelessWidget {
  final AssemblyPoint point;
  final bool isDark;
  const _PointPopup({required this.point, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.cardDark : Colors.white;
    final textColor = isDark ? AppColors.textOnDark : AppColors.textPrimary;
    final muted = textColor.withValues(alpha: 0.6);
    final vols = point.volunteers;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 260),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(point.name,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: textColor)),
                      ),
                      const Gap(8),
                      _VolunteerBadge(count: point.volunteersCount),
                    ],
                  ),
                  if (point.nearestPlaceName != null &&
                      point.nearestPlaceName!.isNotEmpty) ...[
                    const Gap(2),
                    Text(point.nearestPlaceName!,
                        style: TextStyle(fontSize: 12, color: muted)),
                  ],
                  const Gap(8),
                  Divider(
                      height: 1,
                      color: textColor.withValues(alpha: 0.12)),
                  const Gap(8),
                  if (vols.isEmpty)
                    Text('لا يوجد متطوعون',
                        style: TextStyle(fontSize: 12, color: muted))
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...vols.take(8).map((v) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    children: [
                                      _Avatar(
                                          url: v.avatarUrl,
                                          name: v.fullName,
                                          radius: 12),
                                      const Gap(6),
                                      Expanded(
                                        child: Text(v.fullName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: textColor)),
                                      ),
                                    ],
                                  ),
                                )),
                            if (vols.length > 8)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('+${vols.length - 8} آخرين',
                                    style:
                                        TextStyle(fontSize: 11, color: muted)),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Gap(14),
        ],
      ),
    );
  }
}

// ── Volunteer count badge (icon + small blue count, web parity) ────
class _VolunteerBadge extends StatelessWidget {
  final int count;
  const _VolunteerBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 30,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Icon(PhosphorIcons.users(PhosphorIconsStyle.fill),
                size: 26, color: AppColors.primary),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16),
              height: 16,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text('$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── "You are here" location dot ────────────────────────────────────
class _MyLocationDot extends StatelessWidget {
  const _MyLocationDot();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Soft accuracy halo
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF1A73E8).withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
        ),
        // Solid blue dot with white ring
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF1A73E8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A73E8).withValues(alpha: 0.5),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Points list sheet (mirrors the web side panel: header + rows with
//    inline actions) ───────────────────────────────────────────────
class _PointsListSheet extends StatelessWidget {
  final AssemblyPointsController controller;
  final bool canManage;
  final void Function(AssemblyPoint) onSelect;
  final void Function(AssemblyPoint) onEdit;
  final void Function(AssemblyPoint) onToggle;
  final void Function(AssemblyPoint) onDelete;
  final void Function(AssemblyPoint) onNavigate;

  const _PointsListSheet({
    required this.controller,
    required this.canManage,
    required this.onSelect,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textOnDark : AppColors.textPrimary;
    final searchCtrl = TextEditingController(text: controller.searchQuery.value);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            const Gap(10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header (title + count + refresh)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  Icon(PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
                      size: 20, color: AppColors.primary),
                  const Gap(8),
                  Text('نقاط التجمّع',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor)),
                  const Gap(8),
                  Obx(() => Text('${controller.points.length} نقطة',
                      style: TextStyle(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.6)))),
                  const Spacer(),
                  Obx(() => IconButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.loadPoints,
                        icon: controller.isLoading.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : Icon(PhosphorIcons.arrowsClockwise(), size: 20),
                        tooltip: 'تحديث',
                      )),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: searchCtrl,
                textDirection: TextDirection.rtl,
                onChanged: controller.updateSearch,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'بحث بالاسم أو أقرب مكان...',
                  hintTextDirection: TextDirection.rtl,
                  prefixIcon: Icon(PhosphorIcons.magnifyingGlass(), size: 20),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final items = controller.filteredPoints;
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIcons.mapPin(),
                            size: 32, color: textColor.withValues(alpha: 0.4)),
                        const Gap(8),
                        Text('لا توجد نقاط',
                            style: TextStyle(
                                color: textColor.withValues(alpha: 0.6))),
                        const Gap(4),
                        Text('اضغط «إضافة نقطة» لوضع نقطة على الخريطة',
                            style: TextStyle(
                                fontSize: 12,
                                color: textColor.withValues(alpha: 0.5))),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Gap(8),
                  itemBuilder: (_, i) {
                    final p = items[i];
                    final isMine = controller.myPointId == p.id;
                    return _PointRow(
                      point: p,
                      isMine: isMine,
                      isDark: isDark,
                      canManage: canManage,
                      onTap: () => onSelect(p),
                      onEdit: () => onEdit(p),
                      onToggle: () => onToggle(p),
                      onDelete: () => onDelete(p),
                      onNavigate: () => onNavigate(p),
                    );
                  },
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

// ── One list row: info + inline actions (web parity) ───────────────
class _PointRow extends StatelessWidget {
  final AssemblyPoint point;
  final bool isMine;
  final bool isDark;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onNavigate;

  const _PointRow({
    required this.point,
    required this.isMine,
    required this.isDark,
    required this.canManage,
    required this.onTap,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textOnDark : AppColors.textPrimary;
    final color = point.isActive
        ? assemblyPointColor(point.color)
        : kAssemblyPointInactiveColor;
    final hasPlace =
        point.nearestPlaceName != null && point.nearestPlaceName!.isNotEmpty;

    return Opacity(
      opacity: point.isActive ? 1 : 0.6,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
          ),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 14,
                      height: 14,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(point.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textColor)),
                              ),
                              if (isMine) ...[
                                const Gap(6),
                                const _MineBadge(),
                              ],
                            ],
                          ),
                          if (hasPlace)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(point.nearestPlaceName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: textColor.withValues(alpha: 0.6))),
                            ),
                          if (point.volunteers.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: _AvatarStack(
                                volunteers: point.volunteers,
                                ringColor:
                                    isDark ? AppColors.cardDark : Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Gap(8),
                    _CountBadge(count: point.volunteersCount),
                  ],
                ),
              ),
            ),
            Divider(
                height: 1,
                color: textColor.withValues(alpha: 0.08),
                indent: 12,
                endIndent: 12),
            Row(
              children: [
                if (canManage)
                  _rowAction(
                    icon: PhosphorIcons.pencilSimple(),
                    color: AppColors.primary,
                    tooltip: 'تعديل وإدارة المتطوعين',
                    onTap: onEdit,
                  ),
                if (canManage)
                  _rowAction(
                    icon: PhosphorIcons.power(),
                    color: point.isActive
                        ? Colors.green
                        : textColor.withValues(alpha: 0.5),
                    tooltip: point.isActive ? 'تعطيل' : 'تفعيل',
                    onTap: onToggle,
                  ),
                _rowAction(
                  icon: PhosphorIcons.navigationArrow(),
                  color: const Color(0xFF2563EB),
                  tooltip: 'فتح في خرائط جوجل',
                  onTap: onNavigate,
                ),
                const Spacer(),
                if (canManage)
                  _rowAction(
                    icon: PhosphorIcons.trash(),
                    color: Colors.red,
                    tooltip: 'حذف',
                    onTap: onDelete,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowAction({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.users(), size: 14, color: AppColors.accent),
          const Gap(4),
          Text('$count متطوع',
              style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;
  final double radius;
  const _Avatar({required this.url, required this.name, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConstants.resolveAvatarUrl(url);
    if (resolved != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(resolved),
      );
    }
    final initial = name.isNotEmpty ? name.characters.first : '؟';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.accent.withValues(alpha: 0.15),
      child: Text(initial,
          style: TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: radius * 0.8)),
    );
  }
}

// ── Overlapping volunteer avatar stack (max 5 + "+N") ──────────────
class _AvatarStack extends StatelessWidget {
  final List<AssemblyPointVolunteer> volunteers;
  final Color ringColor;
  const _AvatarStack({required this.volunteers, required this.ringColor});

  static const double _avatar = 24; // outer diameter incl. ring
  static const double _step = 16; // horizontal offset between avatars
  static const int _max = 5;

  @override
  Widget build(BuildContext context) {
    final shown = volunteers.take(_max).toList();
    final extra = volunteers.length - shown.length;
    final slots = shown.length + (extra > 0 ? 1 : 0);
    if (slots == 0) return const SizedBox.shrink();
    return SizedBox(
      height: _avatar,
      width: _avatar + (slots - 1) * _step,
      child: Stack(
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(left: i * _step, child: _ring(_inner(shown[i]))),
          if (extra > 0)
            Positioned(
              left: shown.length * _step,
              child: _ring(
                CircleAvatar(
                  radius: 10,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.18),
                  child: Text('+$extra',
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ring(Widget child) => Container(
        width: _avatar,
        height: _avatar,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: ringColor),
        child: child,
      );

  Widget _inner(AssemblyPointVolunteer v) {
    final resolved = ApiConstants.resolveAvatarUrl(v.avatarUrl);
    if (resolved != null) {
      return CircleAvatar(
        radius: 10,
        backgroundImage: CachedNetworkImageProvider(resolved),
      );
    }
    final initial = v.fullName.isNotEmpty ? v.fullName.characters.first : '؟';
    return CircleAvatar(
      radius: 10,
      backgroundColor: AppColors.accent.withValues(alpha: 0.15),
      child: Text(initial,
          style: const TextStyle(
              fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.accent)),
    );
  }
}

class _MineBadge extends StatelessWidget {
  const _MineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber, width: 1),
      ),
      child: const Text('نقطتي',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFFB45309))),
    );
  }
}
