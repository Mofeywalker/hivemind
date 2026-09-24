import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class StatusPill extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;

  const StatusPill({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: effectiveColor.withValues(alpha: isDark ? 0.35 : 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: effectiveColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: effectiveColor,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: child,
        ),
      );
    }

    return child;
  }
}
