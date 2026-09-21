import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/l10n_extension.dart';
import '../../../shared/widgets/minimal_button.dart';
import '../../hiveminds/presentation/hivemind_invite_sheet.dart';
import '../../hiveminds/presentation/hivemind_switcher_sheet.dart';
import '../../hiveminds/providers/hivemind_provider.dart';
import '../domain/reminder_model.dart';
import '../providers/reminder_provider.dart';
import 'create_reminder_sheet.dart';
import 'reminder_card.dart';

sealed class _TimelineRowItem {
  const _TimelineRowItem();
}

class _SectionHeaderItem extends _TimelineRowItem {
  final String title;
  final int count;
  const _SectionHeaderItem(this.title, this.count);
}

class _ReminderRowItem extends _TimelineRowItem {
  final Reminder reminder;
  const _ReminderRowItem(this.reminder);
}

class _CompletedHeaderItem extends _TimelineRowItem {
  final int count;
  const _CompletedHeaderItem(this.count);
}

class _CompletedReminderRowItem extends _TimelineRowItem {
  final Reminder reminder;
  const _CompletedReminderRowItem(this.reminder);
}

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  bool _showCompleted = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedReminderIds = {};

  void _openHivemindSwitcher() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const HivemindSwitcherSheet(),
    );
  }

  void _openCreateReminder() {
    final activeHivemind = ref.read(activeHivemindProvider);
    if (activeHivemind == null) {
      _openHivemindSwitcher();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateReminderSheet(),
    );
  }

  void _enterSelectionMode(Reminder reminder, bool canBeDeleted) {
    if (!canBeDeleted) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.cannotDeleteWaitingForMembers),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _isSelectionMode = true;
      _selectedReminderIds.add(reminder.id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedReminderIds.clear();
    });
  }

  void _toggleSelectAll(List<Reminder> completedList, Set<String> memberUserIds) {
    final eligibleIds = completedList
        .where((r) => r.isFullyCompleted(memberUserIds))
        .map((r) => r.id)
        .toSet();

    setState(() {
      if (_selectedReminderIds.length == eligibleIds.length && eligibleIds.isNotEmpty) {
        _selectedReminderIds.clear();
      } else {
        _selectedReminderIds.addAll(eligibleIds);
      }
    });
  }

  Future<void> _confirmDeleteSelected() async {
    final count = _selectedReminderIds.length;
    if (count == 0) return;

    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteCompletedConfirmTitle),
        content: Text(l10n.deleteCompletedConfirmMessage(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final idsToDelete = _selectedReminderIds.toList();
      _exitSelectionMode();
      ref.read(remindersProvider.notifier).removeOptimistically(idsToDelete);
      await ref.read(reminderRepositoryProvider).deleteReminders(idsToDelete);
      await ref.read(remindersProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.remindersDeleted(idsToDelete.length)),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedHeader(int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 28, bottom: 8),
      child: Semantics(
        button: true,
        label: '${_showCompleted ? "Collapse" : "Expand"} completed reminders',
        child: InkWell(
          onTap: () {
            setState(() {
              _showCompleted = !_showCompleted;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Row(
              children: [
                Icon(
                  _showCompleted
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  size: 22,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.sectionCompleted(count),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final activeHivemind = ref.watch(activeHivemindProvider);
    final remindersGrouped = ref.watch(remindersGroupedProvider);
    final remindersAsync = ref.watch(remindersStreamProvider);

    final membersAsync = ref.watch(activeHivemindMembersProvider);
    final members = membersAsync.value ?? [];
    final memberUserIds = members.map((m) => m.userId).toSet();
    final totalMembersCount = members.isNotEmpty ? members.length : 1;

    final todayList = remindersGrouped[ReminderSection.today] ?? [];
    final tomorrowList = remindersGrouped[ReminderSection.tomorrow] ?? [];
    final upcomingList = remindersGrouped[ReminderSection.upcoming] ?? [];
    final recurringList = remindersGrouped[ReminderSection.recurring] ?? [];
    final completedList = remindersGrouped[ReminderSection.completed] ?? [];

    final eligibleCompletedCount = completedList
        .where((r) => r.isFullyCompleted(memberUserIds))
        .length;

    final hasAnyReminders = todayList.isNotEmpty ||
        tomorrowList.isNotEmpty ||
        upcomingList.isNotEmpty ||
        recurringList.isNotEmpty ||
        completedList.isNotEmpty;

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSelectionMode) {
          _exitSelectionMode();
        }
      },
      child: Scaffold(
        appBar: _isSelectionMode
            ? AppBar(
                titleSpacing: 16,
                toolbarHeight: 64,
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 26),
                  tooltip: l10n.cancel,
                  onPressed: _exitSelectionMode,
                ),
                title: Text(
                  l10n.selectedCount(_selectedReminderIds.length),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _selectedReminderIds.length == eligibleCompletedCount && eligibleCompletedCount > 0
                          ? Icons.deselect_rounded
                          : Icons.select_all_rounded,
                      size: 24,
                    ),
                    tooltip: _selectedReminderIds.length == eligibleCompletedCount && eligibleCompletedCount > 0
                        ? l10n.deselectAll
                        : l10n.selectAll,
                    onPressed: () => _toggleSelectAll(completedList, memberUserIds),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 26, color: AppColors.error),
                    tooltip: l10n.deleteSelected,
                    onPressed: _selectedReminderIds.isNotEmpty ? _confirmDeleteSelected : null,
                  ),
                  const SizedBox(width: 6),
                ],
              )
            : AppBar(
                titleSpacing: 16,
                toolbarHeight: 64,
                title: Semantics(
                  button: true,
                  label: activeHivemind != null
                      ? 'Active group: ${activeHivemind.name}. Tap to switch group.'
                      : l10n.selectHivemind,
                  child: InkWell(
                    onTap: _openHivemindSwitcher,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              activeHivemind?.icon ?? '🐝',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              activeHivemind?.name ?? l10n.selectHivemind,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 22,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  if (activeHivemind != null)
                    IconButton(
                      icon: const Icon(Icons.person_add_outlined, size: 24),
                      tooltip: l10n.inviteMembers,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => HivemindInviteSheet(hivemind: activeHivemind),
                        );
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.account_circle_outlined, size: 26),
                    tooltip: l10n.account,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () => context.push('/profile'),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
        body: activeHivemind == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🐝', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noActiveHivemindTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noActiveHivemindDescription,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      MinimalButton(
                        text: l10n.buttonSelectOrCreateHivemind,
                        onPressed: _openHivemindSwitcher,
                      ),
                    ],
                  ),
                ),
              )
            : remindersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      l10n.errorLoadingReminders(err.toString()),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
                data: (_) {
                  if (!hasAnyReminders) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 48,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.allClearTitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.allClearDescription,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            MinimalButton(
                              text: l10n.buttonCreateFirstReminder,
                              onPressed: _openCreateReminder,
                              isFullWidth: false,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final List<_TimelineRowItem> listItems = [];

                  if (todayList.isNotEmpty) {
                    listItems.add(_SectionHeaderItem(l10n.sectionToday, todayList.length));
                    for (final r in todayList) {
                      listItems.add(_ReminderRowItem(r));
                    }
                  }

                  if (tomorrowList.isNotEmpty) {
                    listItems.add(_SectionHeaderItem(l10n.sectionTomorrow, tomorrowList.length));
                    for (final r in tomorrowList) {
                      listItems.add(_ReminderRowItem(r));
                    }
                  }

                  if (upcomingList.isNotEmpty) {
                    listItems.add(_SectionHeaderItem(l10n.sectionUpcoming, upcomingList.length));
                    for (final r in upcomingList) {
                      listItems.add(_ReminderRowItem(r));
                    }
                  }

                  if (recurringList.isNotEmpty) {
                    listItems.add(_SectionHeaderItem(l10n.sectionRecurring, recurringList.length));
                    for (final r in recurringList) {
                      listItems.add(_ReminderRowItem(r));
                    }
                  }

                  if (completedList.isNotEmpty) {
                    listItems.add(_CompletedHeaderItem(completedList.length));
                    if (_showCompleted) {
                      for (final r in completedList) {
                        listItems.add(_CompletedReminderRowItem(r));
                      }
                    }
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.read(remindersProvider.notifier).refresh(),
                    color: AppColors.primary,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: listItems.length,
                      itemBuilder: (context, index) {
                        final item = listItems[index];
                        switch (item) {
                          case _SectionHeaderItem(:final title, :final count):
                            return _buildSectionHeader(title, count);
                          case _ReminderRowItem(:final reminder):
                            return ReminderCard(
                              key: ValueKey(reminder.id),
                              reminder: reminder,
                              completedCount: reminder.completedByIds.length,
                              totalMembersCount: totalMembersCount,
                            );
                          case _CompletedHeaderItem(:final count):
                            return _buildCompletedHeader(count);
                          case _CompletedReminderRowItem(:final reminder):
                            final canBeDeleted = reminder.isFullyCompleted(memberUserIds);
                            return ReminderCard(
                              key: ValueKey('completed_${reminder.id}'),
                              reminder: reminder,
                              isSelectionMode: _isSelectionMode,
                              isSelected: _selectedReminderIds.contains(reminder.id),
                              canBeDeleted: canBeDeleted,
                              completedCount: reminder.completedByIds.length,
                              totalMembersCount: totalMembersCount,
                              onLongPress: () {
                                _enterSelectionMode(reminder, canBeDeleted);
                              },
                              onSelectedChanged: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedReminderIds.add(reminder.id);
                                  } else {
                                    _selectedReminderIds.remove(reminder.id);
                                  }
                                });
                              },
                            );
                        }
                      },
                    ),
                  );
                },
              ),
        floatingActionButton: (_isSelectionMode || activeHivemind == null)
            ? null
            : FloatingActionButton.extended(
                onPressed: _openCreateReminder,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                elevation: 3,
                icon: const Icon(Icons.add_rounded, size: 24),
                label: Text(
                  l10n.newReminder,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, letterSpacing: -0.2),
                ),
              ),
      ),
    );
  }
}
