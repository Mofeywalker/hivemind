import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../domain/hivemind_member_model.dart';
import '../../domain/hivemind_model.dart';
import '../../providers/hivemind_provider.dart';
import '../hivemind_members_sheet.dart';

class MemberAvatarPill extends ConsumerWidget {
  final Hivemind hivemind;
  final VoidCallback? onTap;

  const MemberAvatarPill({
    super.key,
    required this.hivemind,
    this.onTap,
  });

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => HivemindMembersSheet(hivemind: hivemind),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final membersAsync = ref.watch(activeHivemindMembersProvider);
    final members = membersAsync.value ?? [];

    final tooltipText = l10n.viewMembersTooltip(members.length);

    return Semantics(
      button: true,
      label: tooltipText,
      child: Tooltip(
        message: tooltipText,
        child: InkWell(
          onTap: () => _handleTap(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(minHeight: 36, minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1.1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (members.isEmpty)
                  Icon(
                    Icons.people_outline_rounded,
                    size: 18,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  )
                else
                  _buildAvatarStack(members, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarStack(List<HivemindMember> members, bool isDark) {
    const double avatarSize = 22.0;
    const double overlap = 7.0;

    final displayCount = members.length > 3 ? 2 : members.length;
    final overflowCount = members.length > 3 ? members.length - 2 : 0;

    final widgets = <Widget>[];

    for (int i = 0; i < displayCount; i++) {
      final member = members[i];
      widgets.add(
        Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 0),
          child: _MicroAvatar(
            member: member,
            size: avatarSize,
            isDark: isDark,
          ),
        ),
      );
    }

    if (overflowCount > 0) {
      widgets.add(
        Container(
          width: avatarSize,
          height: avatarSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF222634) : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
              width: 1.5,
            ),
          ),
          child: Text(
            '+$overflowCount',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
      );
    }

    // Stack with overlap
    return SizedBox(
      height: avatarSize,
      width: (avatarSize * widgets.length) - (overlap * (widgets.length - 1)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < widgets.length; i++)
            Positioned(
              left: i * (avatarSize - overlap),
              child: widgets[i],
            ),
        ],
      ),
    );
  }
}

class _MicroAvatar extends StatelessWidget {
  final HivemindMember member;
  final double size;
  final bool isDark;

  const _MicroAvatar({
    required this.member,
    required this.size,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle;
    final initial = member.displayName.isNotEmpty
        ? member.displayName.substring(0, 1).toUpperCase()
        : '?';

    if (member.avatarUrl != null && member.avatarUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: ClipOval(
          child: Image.network(
            member.avatarUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallback(initial, borderColor),
          ),
        ),
      );
    }

    return _buildFallback(initial, borderColor);
  }

  Widget _buildFallback(String initial, Color borderColor) {
    final isOwner = member.role.toLowerCase() == 'owner';
    final bgColor = isOwner
        ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.2)
        : (isDark ? const Color(0xFF2A2E3D) : const Color(0xFFCBD5E1));
    final textColor = isOwner
        ? AppColors.primary
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
