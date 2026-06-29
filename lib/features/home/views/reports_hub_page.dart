import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/services/unread_count_service.dart';
import '../../incident_reporting/controllers/incidents_list_controller.dart';
import '../../incident_reporting/views/incidents_list_page.dart';
import '../../missing_persons/views/missing_persons_page.dart';

/// Merged "البلاغات" tab combining the missing-persons list and the incidents
/// list under one segmented toggle. Both pages are embedded (their own headers
/// are suppressed) so this hub owns the single shared header.
class ReportsHubPage extends StatefulWidget {
  const ReportsHubPage({super.key});

  @override
  State<ReportsHubPage> createState() => _ReportsHubPageState();
}

class _ReportsHubPageState extends State<ReportsHubPage> {
  // 0 = المفقودون, 1 = الحوادث
  int _index = 0;

  void _select(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
    // Entering the incidents sub-tab clears its unread badge.
    if (i == 1 && Get.isRegistered<IncidentsListController>()) {
      Get.find<IncidentsListController>().markAllAsReadOnView();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _header(isDark),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [
                MissingPersonsPage(embedded: true),
                IncidentsListPage(embedded: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(bool isDark) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 14),
      child: Row(
        children: [
          // Reserve space for HomePage's floating notification / messaging icons.
          const SizedBox(width: 52),
          Expanded(child: _segmented()),
          const SizedBox(width: 52),
        ],
      ),
    );
  }

  Widget _segmented() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          _segment(
            index: 0,
            label: 'المفقودون',
            icon: PhosphorIcons.users(),
            badge: _alertsBadge,
          ),
          _segment(
            index: 1,
            label: 'الحوادث',
            icon: PhosphorIcons.fileText(),
            badge: _reportsBadge,
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required int index,
    required String label,
    required IconData icon,
    required int badge,
  }) {
    final selected = _index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _select(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? AppColors.primary : Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: selected ? AppColors.primary : Colors.white,
                ),
              ),
              if (badge > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accent : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  int get _alertsBadge => Get.isRegistered<UnreadCountService>()
      ? Get.find<UnreadCountService>().alertsUnread.value
      : 0;

  int get _reportsBadge => Get.isRegistered<UnreadCountService>()
      ? Get.find<UnreadCountService>().reportsUnread.value
      : 0;
}
