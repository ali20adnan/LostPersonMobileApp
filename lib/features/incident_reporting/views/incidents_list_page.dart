import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/incidents_list_controller.dart';
import '../widgets/incident_card_widget.dart';
import '../../../core/constants/incident_constants.dart';

/// Page displaying list of incidents with filtering
class IncidentsListPage extends GetView<IncidentsListController> {
  const IncidentsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الحوادث'),
        centerTitle: true,
        actions: [
          // Statistics badge
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
                      '${controller.filteredIncidents.length}',
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
          // Filters section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status filters
                const Text(
                  'الحالة',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            context,
                            'الكل',
                            'all',
                            controller.selectedStatusFilter.value == 'all',
                            () => controller.filterByStatus('all'),
                          ),
                          ...IncidentStatus.values.map((status) {
                            final isSelected =
                                controller.selectedStatusFilter.value ==
                                    status.name;
                            return _buildFilterChip(
                              context,
                              status.displayNameAr,
                              status.name,
                              isSelected,
                              () => controller.filterByStatus(status.name),
                            );
                          }),
                        ],
                      ),
                    )),

                const SizedBox(height: 12),

                // Type filters
                const Text(
                  'النوع',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            context,
                            'الكل',
                            'all',
                            controller.selectedTypeFilter.value == 'all',
                            () => controller.filterByType('all'),
                          ),
                          ...IncidentType.values.map((type) {
                            final isSelected =
                                controller.selectedTypeFilter.value == type.name;
                            return _buildFilterChip(
                              context,
                              type.displayNameAr,
                              type.name,
                              isSelected,
                              () => controller.filterByType(type.name),
                              icon: type.icon,
                            );
                          }),
                        ],
                      ),
                    )),
              ],
            ),
          ),

          // Incidents list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (controller.filteredIncidents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد حوادث',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'جرب تغيير الفلاتر أو أضف حادثة جديدة',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refreshIncidents,
                child: ListView.builder(
                  itemCount: controller.filteredIncidents.length,
                  itemBuilder: (context, index) {
                    final incident = controller.filteredIncidents[index];
                    return IncidentCardWidget(
                      incident: incident,
                      onTap: () =>
                          controller.navigateToIncidentDetail(incident.id),
                    );
                  },
                ),
              );
            }),
          ),

          // Statistics bar at bottom
          Obx(() => Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      'قيد الانتظار',
                      controller.pendingCount,
                      IncidentStatus.pending.color,
                    ),
                    _buildStatItem(
                      context,
                      'قيد المعالجة',
                      controller.inProgressCount,
                      IncidentStatus.inProgress.color,
                    ),
                    _buildStatItem(
                      context,
                      'تم الحل',
                      controller.resolvedCount,
                      IncidentStatus.resolved.color,
                    ),
                  ],
                ),
              )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.navigateToCreateIncident,
        icon: const Icon(Icons.add),
        label: const Text('إبلاغ جديد'),
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
  Widget _buildStatItem(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
