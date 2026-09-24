import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/l10n_extension.dart';
import '../../../shared/widgets/minimal_button.dart';
import '../domain/hivemind_model.dart';

class HivemindInviteSheet extends StatelessWidget {
  final Hivemind hivemind;

  const HivemindInviteSheet({super.key, required this.hivemind});

  String get _deepLink => 'hivemind://join?code=${hivemind.inviteCode}';

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: hivemind.inviteCode));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.inviteCodeCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareInvite(BuildContext context) {
    final l10n = context.l10n;
    SharePlus.instance.share(
      ShareParams(
        text: l10n.shareInviteMessage(
          hivemind.name,
          hivemind.inviteCode,
          _deepLink,
        ),
        subject: l10n.shareInviteSubject(hivemind.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.inviteToHivemind(hivemind.name),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.inviteSheetSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // QR Code Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: _deepLink,
              version: QrVersions.auto,
              size: 180.0,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 6-character Code Display
          InkWell(
            onTap: () => _copyCode(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceSubtle
                    : AppColors.lightSurfaceSubtle,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hivemind.inviteCode,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Icon(
                    Icons.copy_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: MinimalButton(
                  text: l10n.shareLink,
                  icon: const Icon(
                    Icons.share_outlined,
                    size: 18,
                    color: Colors.black,
                  ),
                  onPressed: () => _shareInvite(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MinimalButton(
                  text: l10n.copyCode,
                  variant: MinimalButtonVariant.outline,
                  icon: Icon(
                    Icons.copy,
                    size: 18,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  onPressed: () => _copyCode(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
