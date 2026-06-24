import 'package:get/get.dart';

/// Tracks missing-person report IDs for which the current (VOLUNTEER) user has
/// submitted a "found" request that is still awaiting CENTER/ADMIN approval.
///
/// Used to reflect a "قيد المراجعة" (pending review) state on the found button,
/// mirroring the web. State is in-memory only: it is populated optimistically
/// when a request succeeds and cleared when an `approvalUpdate` socket event
/// arrives for the same report (approved or rejected), or on logout.
class PendingFoundRequestsService extends GetxService {
  final RxSet<int> _pendingReportIds = <int>{}.obs;

  /// Reactive read — `true` while a found request for [reportId] is pending.
  bool isPending(int reportId) => _pendingReportIds.contains(reportId);

  void markPending(int reportId) => _pendingReportIds.add(reportId);

  void clear(int reportId) => _pendingReportIds.remove(reportId);

  /// Clear all (e.g. on logout).
  void reset() => _pendingReportIds.clear();
}
