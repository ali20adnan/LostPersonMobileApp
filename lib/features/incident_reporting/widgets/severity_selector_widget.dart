import 'package:flutter/material.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'مستوى الخطورة',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ReportSeverity.values.map((severity) {
            final isSelected = selectedSeverity == severity;
            return GestureDetector(
              onTap: () => onChanged(severity),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? severity.color
                      : severity.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: severity.color,
                    width: isSelected ? 2 : 1,
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
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? Colors.white : severity.color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      severity.displayNameAr,
                      style: TextStyle(
                        color: isSelected ? Colors.white : severity.color,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
