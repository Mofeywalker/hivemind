import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/l10n_extension.dart';
import '../../../core/utils/recurrence_util.dart';
import '../../../shared/widgets/card_container.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../hiveminds/providers/hivemind_provider.dart';
import '../domain/reminder_model.dart';
import '../providers/reminder_provider.dart';
import 'create_reminder_sheet.dart';

class _CardDateFormats {
  _CardDateFormats._();
  static final Map<String, DateFormat> _jm = {};
  static final Map<String, DateFormat> _mmmd = {};

  static DateFormat jm(String locale) =>
      _jm.putIfAbsent(locale, () => DateFormat.jm(locale));
  static DateFormat mmmd(String locale) =>
      _mmmd.putIfAbsent(locale, () => DateFormat.MMMd(locale));
}

class ReminderCard extends ConsumerWidget {
  final Reminder reminder;
  final bool isSelectionMode;
  final bool isSelected;
  final bool canBeDeleted;
  final int completedCount;
  final int totalMembersCount;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onSelectedChanged;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.canBeDeleted = true,
    this.completedCount = 0,
    this.totalMembersCount = 1,
    this.onLongPress,
    this.onSelectedChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final timeFormat = _CardDateFormats.jm(locale);
    final dateFormat = _CardDateFormats.mmmd(locale);

    final currentUserId = FirebaseService.currentUserId;
    final bool isCompletedByUser = reminder.isCompletedByUser(currentUserId);
    final isPast =
        reminder.dueAt.isBefore(DateTime.now()) && !isCompletedByUser;

    final members = ref.watch(activeHivemindMembersProvider).value;
    final assignedMember = reminder.assignedTo != null
        ? members?.where((m) => m.userId == reminder.assignedTo).firstOrNull
        : null;
    final assignedLabel = reminder.assignedTo == currentUserId
        ? l10n.assignedToYou
        : (assignedMember != null
              ? l10n.assignedToUser(assignedMember.displayName)
              : l10n.scopeAssigned);

    final cardContent = CardContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.only(left: 8, right: 16, top: 12, bottom: 14),
      backgroundColor: isSelected
          ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12)
          : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
      border: Border.all(
        color: isSelected
            ? AppColors.primary
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        width: isSelected ? 1.8 : 1.0,
      ),
      borderRadius: 16,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress?.call();
      },
      onTap: isSelectionMode
          ? () {
              if (canBeDeleted) {
                HapticFeedback.selectionClick();
                onSelectedChanged?.call(!isSelected);
              } else {
                HapticFeedback.vibrate();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.cannotDeleteWaitingForMembers),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: (isSelectionMode && !canBeDeleted) ? 0.45 : 1.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selection Checkbox or Standard Completion Checkbox
            if (isSelectionMode)
              Semantics(
                label: canBeDeleted
                    ? (isSelected
                          ? 'Selected: ${reminder.title}'
                          : 'Not selected: ${reminder.title}')
                    : 'Cannot select: waiting for hive members to complete',
                button: true,
                checked: isSelected,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (canBeDeleted) {
                      HapticFeedback.selectionClick();
                      onSelectedChanged?.call(!isSelected);
                    } else {
                      HapticFeedback.vibrate();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.cannotDeleteWaitingForMembers),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.primary
                            : (canBeDeleted
                                  ? Colors.transparent
                                  : (isDark
                                        ? AppColors.darkSurfaceSubtle
                                        : AppColors.lightSurfaceSubtle)),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (canBeDeleted
                                    ? (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextMuted)
                                    : (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder)),
                          width: 2.2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.black,
                            )
                          : (!canBeDeleted
                                ? Icon(
                                    Icons.lock_outline_rounded,
                                    size: 14,
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  )
                                : null),
                    ),
                  ),
                ),
              )
            else
              // Standard Checkbox with 48x48 Accessible Touch Target and Semantics
              Semantics(
                label: isCompletedByUser
                    ? 'Completed: ${reminder.title}. Tap to mark incomplete.'
                    : 'Incomplete: ${reminder.title}. Tap to mark complete.',
                button: true,
                checked: isCompletedByUser,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    final members = ref
                        .read(activeHivemindMembersProvider)
                        .value;
                    final memberIds = members?.map((m) => m.userId);
                    ref
                        .read(reminderRepositoryProvider)
                        .toggleCompletion(
                          reminder,
                          hiveMemberUserIds: memberIds,
                        );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompletedByUser
                            ? AppColors.success
                            : Colors.transparent,
                        border: Border.all(
                          color: isCompletedByUser
                              ? AppColors.success
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextMuted),
                          width: 2.2,
                        ),
                      ),
                      child: isCompletedByUser
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
              ),

            const SizedBox(width: 4),

            // Content
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: isSelectionMode
                    ? (onSelectedChanged != null && canBeDeleted
                          ? () => onSelectedChanged!(!isSelected)
                          : null)
                    : () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (_) =>
                              CreateReminderSheet(reminderToEdit: reminder),
                        );
                      },
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          decoration: isCompletedByUser
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: isCompletedByUser
                              ? (isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted)
                              : (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary),
                        ),
                      ),
                      if (reminder.notes != null &&
                          reminder.notes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          reminder.notes!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.35,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Metadata Pills (Time, Recurrence, Past Due, Member Completion)
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Due Date & Time
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 15,
                                color: isPast
                                    ? AppColors.error
                                    : (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${dateFormat.format(reminder.dueAt)}, ${timeFormat.format(reminder.dueAt)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isPast
                                      ? AppColors.error
                                      : (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary),
                                ),
                              ),
                            ],
                          ),

                          // Recurrence Pill
                          if (reminder.isRecurring)
                            StatusPill(
                              label: () {
                                final preset = RecurrenceUtil.presetFromRRule(
                                  reminder.rrule,
                                );
                                if (preset == RecurrencePreset.customDays) {
                                  return RecurrenceUtil.getReadableRecurrenceDescription(
                                    reminder.rrule,
                                    l10n: l10n,
                                    isGerman: locale.startsWith('de'),
                                  );
                                }
                                return RecurrenceUtil.getReadablePresetTitle(
                                  preset,
                                  l10n,
                                );
                              }(),
                              icon: Icons.repeat_rounded,
                              color: AppColors.primary,
                            ),

                          // Assigned Pill (if assigned scope and not completed)
                          if (!isCompletedByUser &&
                              reminder.completionScope ==
                                  ReminderCompletionScope.assigned)
                            StatusPill(
                              label: assignedLabel,
                              icon: Icons.assignment_ind_outlined,
                              color: reminder.assignedTo == currentUserId
                                  ? AppColors.primary
                                  : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary),
                            ),

                          // All members Pill (if all scope and not completed, in multi-member hivemind)
                          if (!isCompletedByUser &&
                              reminder.completionScope ==
                                  ReminderCompletionScope.all &&
                              totalMembersCount > 1)
                            StatusPill(
                              label: l10n.scopeAll,
                              icon: Icons.groups_outlined,
                              color: AppColors.primary,
                            ),

                          // Overdue Pill
                          if (isPast)
                            StatusPill(
                              label: l10n.overdue,
                              icon: Icons.warning_amber_rounded,
                              color: AppColors.error,
                            ),

                          // Member Completion Pills
                          if (isCompletedByUser) ...[
                            if (reminder.completionScope ==
                                ReminderCompletionScope.all) ...[
                              if (canBeDeleted)
                                StatusPill(
                                  label: l10n.completedByAll,
                                  icon: Icons.done_all_rounded,
                                  color: AppColors.success,
                                )
                              else
                                StatusPill(
                                  label: totalMembersCount > 1
                                      ? '${l10n.completedFraction(completedCount, totalMembersCount)} • ${l10n.waitingForMembers}'
                                      : l10n.waitingForMembers,
                                  icon: Icons.hourglass_top_rounded,
                                  color: AppColors.primary,
                                ),
                            ] else ...[
                              StatusPill(
                                label: l10n.completedBySingle,
                                icon: Icons.done_all_rounded,
                                color: AppColors.success,
                              ),
                            ],
                          ] else if (reminder.completionScope ==
                                  ReminderCompletionScope.all &&
                              completedCount > 0 &&
                              totalMembersCount > 1) ...[
                            StatusPill(
                              label: l10n.completedFraction(
                                completedCount,
                                totalMembersCount,
                              ),
                              icon: Icons.people_outline_rounded,
                              color: AppColors.primary,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (isSelectionMode) {
      return RepaintBoundary(child: cardContent);
    }

    // Dismissible for Swipe-to-Delete
    return RepaintBoundary(
      child: Dismissible(
        key: Key(reminder.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          if (isCompletedByUser && !canBeDeleted) {
            HapticFeedback.vibrate();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.cannotDeleteWaitingForMembers),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return false;
          }
          return true;
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline, color: AppColors.error),
        ),
        onDismissed: (_) async {
          ref.read(remindersProvider.notifier).removeOptimistically([
            reminder.id,
          ]);
          await ref
              .read(reminderRepositoryProvider)
              .deleteReminder(reminder.id);
          await ref.read(remindersProvider.notifier).refresh();
        },
        child: cardContent,
      ),
    );
  }
}
