import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../../../core/constants/incident_constants.dart';

/// Widget for selecting report severity with color-coded chips
class SeveritySelectorWidget extends StatelessWidget {
  final ReportSeverity selectedSeverity;
  final Function(ReportSeverity) onChanged;

  const SeveritySelectorWidget({
    super.key,
    required this.selectedSeverity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: ReportSeverity.values.map((severity) {
        final isSelected = selectedSeverity == severity;
        return GestureDetector(
          onTap: () => onChanged(severity),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        severity.color,
                        severity.color.withValues(alpha: 0.8),
                      ],
                    )
                  : null,
              color: isSelected
                  ? null
                  : isDark
                      ? AppColors.cardDark
                      : severity.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : severity.color.withValues(alpha: 0.4),
                width: isSelected ? 0 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: severity.color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? PhosphorIcons.checkCircle() : PhosphorIcons.record(),
                  color: isSelected
                      ? Colors.white
                      : severity.color,
                  size: 20,
                ),
                const Gap(8),
                Text(
                  severity.displayNameAr,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : isDark
                            ? AppColors.textOnDark
                            : severity.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
