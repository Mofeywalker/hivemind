import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final Border? border;
  final double borderRadius;

  const CardContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.border,
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final defaultBorder = Border.all(
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      width: 1,
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? defaultBorder,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
