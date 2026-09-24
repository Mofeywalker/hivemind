import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum MinimalButtonVariant { primary, secondary, outline, ghost, danger }

class MinimalButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final MinimalButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;

  const MinimalButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = MinimalButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case MinimalButtonVariant.primary:
        backgroundColor = AppColors.primary;
        foregroundColor = Colors.black;
        break;
      case MinimalButtonVariant.secondary:
        backgroundColor = isDark
            ? AppColors.darkSurfaceSubtle
            : AppColors.lightSurfaceSubtle;
        foregroundColor = isDark
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary;
        break;
      case MinimalButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = isDark
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary;
        borderSide = BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        );
        break;
      case MinimalButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary;
        break;
      case MinimalButtonVariant.danger:
        backgroundColor = AppColors.error.withValues(alpha: 0.12);
        foregroundColor = AppColors.error;
        break;
    }

    final childContent = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Text(
                text,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          );

    final button = Semantics(
      button: true,
      label: text,
      enabled: !isLoading && onPressed != null,
      child: Material(
        color: onPressed == null
            ? backgroundColor.withValues(alpha: 0.5)
            : backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: borderSide,
        ),
        child: InkWell(
          onTap: (isLoading || onPressed == null) ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: height,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.center,
            child: childContent,
          ),
        ),
      ),
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
