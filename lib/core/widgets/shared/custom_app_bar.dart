import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../app/themes/app_colors.dart';

/// A consistent custom app bar with optional glassmorphic background,
/// gradient title, and action buttons.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final bool centerTitle;
  final bool enableGlass;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onBack;
  final Color? backgroundColor;
  final double elevation;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.centerTitle = true,
    this.enableGlass = false,
    this.actions,
    this.leading,
    this.onBack,
    this.backgroundColor,
    this.elevation = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (enableGlass) {
      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: _buildAppBar(context, theme),
        ),
      );
    }

    return _buildAppBar(context, theme);
  }

  Widget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      elevation: elevation,
      scrolledUnderElevation: 0,
      backgroundColor: backgroundColor ?? Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: centerTitle,
      leading: leading ??
          (showBack
              ? IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Iconsax.arrow_right_3,
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  onPressed: onBack ?? () => Navigator.of(context).pop(),
                )
              : null),
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: actions,
    );
  }
}
