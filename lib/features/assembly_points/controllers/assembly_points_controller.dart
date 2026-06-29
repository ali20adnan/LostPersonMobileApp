import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../app/services/api_service.dart';
import '../../../app/services/auth_service.dart';
import '../../../app/services/socket_service.dart';
import '../../../data/models/assembly_point_model.dart';
import '../../../data/repositories/assembly_points_repository.dart';

/// State for the assembly-points map ("نقاط التجمّع").
///
/// Reads are open to everyone; management actions are gated by [canManage].
/// Listens to the realtime `assemblyPointsChanged` event to keep the map fresh.
class AssemblyPointsController extends GetxController {
  AssemblyPointsController({AssemblyPointsRepository? repository})
      : _repo = repository ?? Get.find<AssemblyPointsRepository>();

  final AssemblyPointsRepository _repo;
  final AuthService _auth = Get.find<AuthService>();

  static const _socketEvent = 'assemblyPointsChanged';
  static const _listenerId = 'assembly_points_map';

  final RxList<AssemblyPoint> points = <AssemblyPoint>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxnInt selectedId = RxnInt();
  final RxString searchQuery = ''.obs;

  /// True while an admin is in "tap the map to place a point" mode.
  final RxBool placingMode = false.obs;

  bool get canManage =>
      _auth.currentUser.value?.canManageAssemblyPoints ?? false;

  /// The volunteer's assigned point id, if any ("نقطتي").
  int? get myPointId => _auth.currentUser.value?.assemblyPointId;

  SocketService? get _socket =>
      Get.isRegistered<SocketService>() ? Get.find<SocketService>() : null;

  @override
  void onInit() {
    super.onInit();
    loadPoints();
    // Refresh the profile so a volunteer's assigned point ("نقطتي") is current.
    _auth.fetchProfile();
    _socket?.on(_socketEvent, _listenerId, (_) => loadPoints());
  }

  @override
  void onClose() {
    _socket?.off(_socketEvent, _listenerId);
    super.onClose();
  }

  /// Points after applying the search filter (by name or nearest place).
  List<AssemblyPoint> get filteredPoints {
    final q = searchQuery.value.trim();
    if (q.isEmpty) return points;
    return points
        .where((p) =>
            p.name.contains(q) || (p.nearestPlaceName ?? '').contains(q))
        .toList();
  }

  AssemblyPoint? get selectedPoint {
    final id = selectedId.value;
    if (id == null) return null;
    return points.firstWhereOrNull((p) => p.id == id);
  }

  void select(int? id) => selectedId.value = id;

  void updateSearch(String value) => searchQuery.value = value;

  void setPlacingMode(bool value) => placingMode.value = value;

  Future<void> loadPoints() async {
    if (isLoading.value) return;
    isLoading.value = true;
    hasError.value = false;
    try {
      final result = await _repo.getPoints(limit: 200);
      points.assignAll(result.items);
    } catch (e) {
      hasError.value = true;
      debugPrint('AssemblyPointsController: loadPoints error - $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Management actions (ADMIN/OFFICIAL/CENTER) ─────────────────────

  Future<ApiResponse> createPoint({
    required String name,
    required double latitude,
    required double longitude,
    String? nearestPlaceName,
    String? color,
    String? description,
    bool isActive = true,
    List<int>? volunteerIds,
  }) async {
    final res = await _repo.createPoint(
      name: name,
      latitude: latitude,
      longitude: longitude,
      nearestPlaceName: nearestPlaceName,
      color: color,
      description: description,
      isActive: isActive,
      volunteerIds: volunteerIds,
    );
    if (res.isSuccess) await loadPoints();
    return res;
  }

  Future<ApiResponse> updatePoint(
    int id, {
    String? name,
    double? latitude,
    double? longitude,
    String? nearestPlaceName,
    String? color,
    String? description,
    bool? isActive,
  }) async {
    final res = await _repo.updatePoint(
      id,
      name: name,
      latitude: latitude,
      longitude: longitude,
      nearestPlaceName: nearestPlaceName,
      color: color,
      description: description,
      isActive: isActive,
    );
    if (res.isSuccess) await loadPoints();
    return res;
  }

  Future<ApiResponse> toggleActive(AssemblyPoint point) async {
    final res = await _repo.updatePoint(point.id, isActive: !point.isActive);
    if (res.isSuccess) await loadPoints();
    return res;
  }

  Future<ApiResponse> deletePoint(int id) async {
    final res = await _repo.deletePoint(id);
    if (res.isSuccess) {
      if (selectedId.value == id) selectedId.value = null;
      await loadPoints();
    }
    return res;
  }

  /// Fetch the volunteers list for the assign picker.
  Future<List<VolunteerOption>> getVolunteers() => _repo.getVolunteers();

  /// Apply volunteer membership changes for [pointId]: link [toAdd] (which
  /// moves them off any previous point) and unlink [toRemove]. Reloads points
  /// afterward. Returns false if any call failed.
  Future<bool> syncVolunteers(
    int pointId, {
    required List<int> toAdd,
    required List<int> toRemove,
  }) async {
    var ok = true;
    if (toAdd.isNotEmpty) {
      final res = await _repo.assignVolunteers(pointId, toAdd);
      ok = ok && res.isSuccess;
    }
    for (final userId in toRemove) {
      final res = await _repo.removeVolunteer(pointId, userId);
      ok = ok && res.isSuccess;
    }
    if (toAdd.isNotEmpty || toRemove.isNotEmpty) await loadPoints();
    return ok;
  }
}
