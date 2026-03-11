import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/incidents_list_controller.dart';
import '../widgets/incident_card_widget.dart';
import '../../../core/constants/incident_constants.dart';

/// Page displaying list of reports with filtering
class IncidentsListPage extends GetView<IncidentsListController> {
  const IncidentsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الإبلاغات'),
        centerTitle: true,
        actions: [
          Obx(() => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${controller.filteredReports.length}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )),
        ],
      ),
      body: Column(
        children: [
          // Search + filter section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: controller.updateSearch,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'ابحث بالعنوان أو الوصف أو الموقع...',
                    hintTextDirection: TextDirection.rtl,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 11,
                      horizontal: 16,
                    ),
                    isDense: true,
                  ),
                ),

                const SizedBox(height: 10),

                // Status filters
                const Text(
                  'الحالة',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Obx(() => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            context,
                            'الكل',
                            'all',
                            controller.selectedStatusFilter.value == null,
                            () => controller.filterByStatus(null),
                          ),
                          ...ReportStatus.values.map((status) {
                            final isSelected =
                                controller.selectedStatusFilter.value == status;
                            return _buildFilterChip(
                              context,
                              status.displayNameAr,
                              status.name,
                              isSelected,
                              () => controller.filterByStatus(status),
                            );
                          }),
                        ],
                      ),
                    )),

                const SizedBox(height: 8),

                // Type filters
                const Text(
                  'النوع',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Obx(() => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            context,
                            'الكل',
                            'all',
                            controller.selectedTypeFilter.value == null,
                            () => controller.filterByType(null),
                          ),
                          ...ReportType.values.map((type) {
                            final isSelected =
                                controller.selectedTypeFilter.value == type;
                            return _buildFilterChip(
                              context,
                              type.displayNameAr,
                              type.name,
                              isSelected,
                              () => controller.filterByType(type),
                              icon: type.icon,
                            );
                          }),
                        ],
                      ),
                    )),
              ],
            ),
          ),

          // Reports list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final reports = controller.filteredReports;
              if (reports.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text('لا توجد بلاغات',
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Text('جرب تغيير الفلاتر أو أضف بلاغ جديد',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refreshReports,
                child: ListView.builder(
                  itemCount: reports.length + (controller.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == reports.length) {
                      controller.loadMore();
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final report = reports[index];
                    return IncidentCardWidget(
                      incident: report,
                      onTap: () =>
                          controller.navigateToReportDetail(report.id),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showReportTypeSheet(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('إبلاغ جديد'),
      ),
    );
  }

  /// Build stat pill
  Widget _buildStatPill(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontSize: 11,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Build filter chip
  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String value,
    bool isSelected,
    VoidCallback onTap, {
    IconData? icon,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 6),
            ],
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        labelStyle: TextStyle(
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  /// Build statistics item

  void _showReportTypeSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'نوع الإبلاغ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.report_problem,
                    color: Color(0xFF8B5CF6)),
              ),
              title: const Text('بلاغ عادي',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('إبلاغ عن حادثة أو طوارئ'),
              onTap: () {
                Navigator.pop(context);
                controller.navigateToCreateReport();
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.person_search, color: Colors.red),
              ),
              title: const Text('إبلاغ عن مفقود',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('الإبلاغ عن شخص مفقود'),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed('/missing-person-form');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
