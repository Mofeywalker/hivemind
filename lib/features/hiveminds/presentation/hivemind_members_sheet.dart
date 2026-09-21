import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/l10n_extension.dart';
import '../../../shared/widgets/minimal_button.dart';
import '../domain/hivemind_member_model.dart';
import '../domain/hivemind_model.dart';
import '../providers/hivemind_provider.dart';
import 'hivemind_invite_sheet.dart';

class HivemindMembersSheet extends ConsumerWidget {
  final Hivemind hivemind;
  final String? currentUserId;

  const HivemindMembersSheet({
    super.key,
    required this.hivemind,
    this.currentUserId,
  });

  String _getEffectiveUserId() {
    if (currentUserId != null) return currentUserId!;
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  void _openInvite(BuildContext context) {
    Navigator.of(context).pop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => HivemindInviteSheet(hivemind: hivemind),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final effectiveUserId = _getEffectiveUserId();

    final membersAsync = ref.watch(activeHivemindMembersProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    hivemind.icon,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hivemind.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      membersAsync.when(
                        data: (members) => Text(
                          l10n.membersCount(members.length),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        loading: () => Text(
                          l10n.membersTitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        error: (err, stack) => Text(
                          l10n.membersTitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  tooltip: l10n.cancel,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Members List
            membersAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  err.toString(),
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),
              data: (members) {
                if (members.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        l10n.noMembers,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  );
                }

                // Sort: current user first, then owners, then others
                final sortedMembers = List<HivemindMember>.from(members)..sort((a, b) {
                  if (a.userId == effectiveUserId) return -1;
                  if (b.userId == effectiveUserId) return 1;
                  final aOwner = a.role.toLowerCase() == 'owner';
                  final bOwner = b.role.toLowerCase() == 'owner';
                  if (aOwner && !bOwner) return -1;
                  if (!aOwner && bOwner) return 1;
                  return a.displayName.compareTo(b.displayName);
                });

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 340),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: sortedMembers.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final member = sortedMembers[index];
                      final isCurrent = member.userId == effectiveUserId;
                      final isOwner = member.role.toLowerCase() == 'owner';
                      final initial = member.displayName.isNotEmpty
                          ? member.displayName.substring(0, 1).toUpperCase()
                          : '?';
                      final joinedFormatted = DateFormat.yMMMd(locale).format(member.joinedAt);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent
                                ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            _MemberAvatar(
                              avatarUrl: member.avatarUrl,
                              initial: initial,
                              isCurrent: isCurrent,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 12),

                            // Name and Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          member.displayName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14.5,
                                            letterSpacing: -0.2,
                                            color: isDark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.lightTextPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isCurrent) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            l10n.memberYou,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${isOwner ? l10n.memberRoleOwner : l10n.memberRoleMember} • ${l10n.memberJoinedDate(joinedFormatted)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            // Action: Invite
            MinimalButton(
              text: l10n.inviteNewMember,
              variant: MinimalButtonVariant.outline,
              icon: const Icon(Icons.person_add_outlined, size: 18),
              onPressed: () => _openInvite(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String initial;
  final bool isCurrent;
  final bool isDark;

  const _MemberAvatar({
    required this.avatarUrl,
    required this.initial,
    required this.isCurrent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          avatarUrl!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildInitial(),
        ),
      );
    }
    return _buildInitial();
  }

  Widget _buildInitial() {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.15)
            : (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle),
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrent
              ? AppColors.primary.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: 1.2,
        ),
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isCurrent
              ? AppColors.primary
              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        ),
      ),
    );
  }
}
