import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/l10n_extension.dart';
import '../../../shared/widgets/minimal_button.dart';
import '../../../shared/widgets/minimal_text_field.dart';
import '../providers/hivemind_provider.dart';
import 'hivemind_invite_sheet.dart';

class HivemindSwitcherSheet extends ConsumerWidget {
  const HivemindSwitcherSheet({super.key});

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.createHivemindTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MinimalTextField(
              controller: nameController,
              label: l10n.groupNameLabel,
              hintText: l10n.groupNameHint,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            MinimalTextField(
              controller: descController,
              label: l10n.descriptionOptionalLabel,
              hintText: l10n.descriptionHint,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          MinimalButton(
            text: l10n.create,
            isFullWidth: false,
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.of(ctx).pop();

              try {
                final created = await ref.read(hivemindRepositoryProvider).createHivemind(
                  name: name,
                  description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                );
                await ref.read(activeHivemindProvider.notifier).refresh();
                ref.read(activeHivemindProvider.notifier).setActive(created);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.failedToCreateHivemind(e.toString()))),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.joinHivemindTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MinimalTextField(
              controller: codeController,
              label: l10n.sixCharacterCodeLabel,
              hintText: l10n.sixCharacterCodeHint,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            MinimalButton(
              text: l10n.scanQrCodeInstead,
              variant: MinimalButtonVariant.outline,
              icon: const Icon(Icons.qr_code_scanner, size: 18),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
                context.push('/qr-scanner');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          MinimalButton(
            text: l10n.join,
            isFullWidth: false,
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) return;
              Navigator.of(ctx).pop();

              try {
                final joined = await ref.read(hivemindRepositoryProvider).joinByInviteCode(code);
                await ref.read(activeHivemindProvider.notifier).refresh();
                ref.read(activeHivemindProvider.notifier).setActive(joined);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.failedToJoinHivemind(e.toString()))),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final hivemindsAsync = ref.watch(joinedHivemindsProvider);
    final activeHivemind = ref.watch(activeHivemindProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.hiveminds,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              if (activeHivemind != null)
                IconButton(
                  icon: const Icon(Icons.person_add_outlined, size: 24, color: AppColors.primary),
                  tooltip: l10n.inviteMembers,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => HivemindInviteSheet(hivemind: activeHivemind),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Hiveminds List
          hivemindsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                l10n.errorLoadingHiveminds(err.toString()),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text(
                      l10n.emptyHivemindsList,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = list[index];
                  final isSelected = activeHivemind?.id == item.id;

                  return InkWell(
                    onTap: () {
                      ref.read(activeHivemindProvider.notifier).setActive(item);
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 56),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1)
                            : (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(item.icon, style: const TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16.5,
                                    letterSpacing: -0.2,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                if (item.description != null && item.description!.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    item.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, size: 22, color: AppColors.primary),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 24),

          // Bottom Action Buttons
          Row(
            children: [
              Expanded(
                child: MinimalButton(
                  text: l10n.buttonCreateNew,
                  icon: const Icon(Icons.add, size: 18, color: Colors.black),
                  onPressed: () => _showCreateDialog(context, ref),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MinimalButton(
                  text: l10n.buttonJoinExisting,
                  variant: MinimalButtonVariant.outline,
                  icon: const Icon(Icons.group_add_outlined, size: 18),
                  onPressed: () => _showJoinDialog(context, ref),
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
