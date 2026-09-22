import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum HivemindLogoVariant {
  /// Standalone icon mark
  iconOnly,

  /// Horizontal layout (icon + wordmark)
  horizontal,

  /// Vertical layout (stacked icon + wordmark)
  vertical,
}

/// Official Hivemind logo widget supporting Light & Dark mode adaptation.
class HivemindLogo extends StatelessWidget {
  final HivemindLogoVariant variant;
  final double? width;
  final double? height;
  final bool? isDark;

  const HivemindLogo({
    super.key,
    this.variant = HivemindLogoVariant.horizontal,
    this.width,
    this.height,
    this.isDark,
  });

  const HivemindLogo.icon({super.key, double size = 48, this.isDark})
    : variant = HivemindLogoVariant.iconOnly,
      width = size,
      height = size;

  const HivemindLogo.horizontal({
    super.key,
    this.width = 180,
    this.height = 40,
    this.isDark,
  }) : variant = HivemindLogoVariant.horizontal;

  const HivemindLogo.vertical({
    super.key,
    this.width = 140,
    this.height = 140,
    this.isDark,
  }) : variant = HivemindLogoVariant.vertical;

  @override
  Widget build(BuildContext context) {
    final effectiveDark =
        isDark ?? (Theme.of(context).brightness == Brightness.dark);

    final String assetPath;
    switch (variant) {
      case HivemindLogoVariant.iconOnly:
        assetPath = effectiveDark
            ? 'assets/logo/hivemind_icon_dark.svg'
            : 'assets/logo/hivemind_icon_light.svg';
        break;
      case HivemindLogoVariant.horizontal:
        assetPath = effectiveDark
            ? 'assets/logo/hivemind_logo_dark.svg'
            : 'assets/logo/hivemind_logo_light.svg';
        break;
      case HivemindLogoVariant.vertical:
        assetPath = effectiveDark
            ? 'assets/logo/hivemind_logo_vertical_dark.svg'
            : 'assets/logo/hivemind_logo_vertical_light.svg';
        break;
    }

    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
