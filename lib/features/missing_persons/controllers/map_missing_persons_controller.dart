import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../app/services/socket_service.dart';
import '../../../data/models/missing_person_report_model.dart';
import '../../../data/repositories/missing_persons_repository.dart';

/// Feeds the missing-person markers shown on the assembly-points map.
///
/// Kept separate from [MissingPersonsController] (the paginated list page) so
/// the map layer has its own lightweight, non-paginated data source. Listens to
/// the realtime missing-person events to keep the markers fresh.
class MapMissingPersonsController extends GetxController {
  final MissingPersonsRepository _repo = Get.find<MissingPersonsRepository>();

  final RxList<MissingPersonReport> persons = <MissingPersonReport>[].obs;
  final RxBool isLoading = false.obs;

  static const _events = [
    'newMissingPerson',
    'missingPersonUpdated',
    'missingPersonDeleted',
  ];
  static const _listenerId = 'missing_persons_map';

  SocketService? get _socket =>
      Get.isRegistered<SocketService>() ? Get.find<SocketService>() : null;

  @override
  void onInit() {
    super.onInit();
    load();
    // Realtime: any create/update/delete refreshes the map markers.
    for (final e in _events) {
      _socket?.on(e, _listenerId, (_) => load());
    }
  }

  @override
  void onClose() {
    for (final e in _events) {
      _socket?.off(e, _listenerId);
    }
    super.onClose();
  }

  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final result = await _repo.getMapPoints();
      if (result != null) persons.assignAll(result);
    } catch (e) {
      debugPrint('MapMissingPersonsController: load error - $e');
    } finally {
      isLoading.value = false;
    }
  }
}
