import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/services/soniox_service.dart';
import '../../app/themes/app_colors.dart';

class ConnectionStatusIndicator extends StatelessWidget {
  final ConnectionStatus status;

  const ConnectionStatusIndicator({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final label = _getStatusLabel();
    final icon = _getStatusIcon();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (status) {
      case ConnectionStatus.connected:
        return PhosphorIcons.wifiHigh();
      case ConnectionStatus.connecting:
        return PhosphorIcons.arrowsClockwise();
      case ConnectionStatus.disconnected:
        return PhosphorIcons.wifiSlash();
      case ConnectionStatus.error:
        return PhosphorIcons.warning();
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case ConnectionStatus.connected:
        return AppColors.connected;
      case ConnectionStatus.connecting:
        return AppColors.connecting;
      case ConnectionStatus.disconnected:
        return AppColors.disconnected;
      case ConnectionStatus.error:
        return AppColors.error;
    }
  }

  String _getStatusLabel() {
    switch (status) {
      case ConnectionStatus.connected:
        return 'متصل';
      case ConnectionStatus.connecting:
        return 'جاري الاتصال...';
      case ConnectionStatus.disconnected:
        return 'غير متصل';
      case ConnectionStatus.error:
        return 'خطأ في الاتصال';
    }
  }
}
