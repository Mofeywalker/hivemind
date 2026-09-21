import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/l10n_extension.dart';
import '../../../core/utils/recurrence_util.dart';
import '../../../shared/widgets/minimal_button.dart';
import '../../../shared/widgets/minimal_text_field.dart';
import '../../hiveminds/providers/hivemind_provider.dart';
import '../domain/reminder_model.dart';
import '../providers/reminder_provider.dart';

class CreateReminderSheet extends ConsumerStatefulWidget {
  final Reminder? reminderToEdit;

  const CreateReminderSheet({
    super.key,
    this.reminderToEdit,
  });

  @override
  ConsumerState<CreateReminderSheet> createState() => _CreateReminderSheetState();
}

class _CreateReminderSheetState extends ConsumerState<CreateReminderSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late RecurrencePreset _selectedPreset;
  late Set<int> _selectedWeekdays;
  late ReminderCompletionScope _selectedScope;
  String? _selectedAssignedTo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.reminderToEdit;
    if (edit != null) {
      _titleController = TextEditingController(text: edit.title);
      _notesController = TextEditingController(text: edit.notes ?? '');
      _selectedDate = edit.dueAt.toLocal();
      _selectedTime = TimeOfDay.fromDateTime(edit.dueAt.toLocal());
      _selectedPreset = RecurrenceUtil.presetFromRRule(edit.rrule);
      _selectedScope = edit.completionScope;
      _selectedAssignedTo = edit.assignedTo;
      final days = RecurrenceUtil.weekdaysFromRRule(edit.rrule);
      _selectedWeekdays = days.isNotEmpty
          ? Set<int>.from(days)
          : {_selectedDate.weekday};
    } else {
      _titleController = TextEditingController();
      _notesController = TextEditingController();
      _selectedDate = DateTime.now().add(const Duration(hours: 1));
      _selectedTime = TimeOfDay.fromDateTime(
        DateTime.now().add(const Duration(hours: 1)),
      );
      _selectedPreset = RecurrencePreset.none;
      _selectedScope = ReminderCompletionScope.anyone;
      _selectedAssignedTo = null;
      _selectedWeekdays = {_selectedDate.weekday};
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime get _combinedDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        if (_selectedPreset == RecurrencePreset.weekly) {
          _selectedWeekdays = {picked.weekday};
        }
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _toggleWeekday(int day) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedWeekdays.contains(day)) {
        if (_selectedWeekdays.length > 1) {
          _selectedWeekdays.remove(day);
        }
      } else {
        _selectedWeekdays.add(day);
      }

      if (_selectedWeekdays.length > 1) {
        _selectedPreset = RecurrencePreset.customDays;
      } else {
        _selectedPreset = RecurrencePreset.weekly;
      }
    });
  }

  void _selectWeekdayPreset(Set<int> days) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedWeekdays = Set<int>.from(days);
      if (days.length == 5 && days.contains(1) && days.contains(5)) {
        _selectedPreset = RecurrencePreset.weekdays;
      } else if (days.length == 7) {
        _selectedPreset = RecurrencePreset.daily;
      } else if (days.length > 1) {
        _selectedPreset = RecurrencePreset.customDays;
      } else {
        _selectedPreset = RecurrencePreset.weekly;
      }
    });
  }

  Future<void> _handleSubmit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      DateTime effectiveDueAt = _combinedDateTime;
      if (_selectedPreset == RecurrencePreset.customDays ||
          _selectedPreset == RecurrencePreset.weekly) {
        effectiveDueAt = RecurrenceUtil.getFirstOccurrenceOnOrAfter(
          baseDueAt: _combinedDateTime,
          weekdays: _selectedWeekdays,
        );
      }

      final rrule = RecurrenceUtil.toRRuleString(
        preset: _selectedPreset,
        baseDateTime: effectiveDueAt,
        customWeekdays: _selectedWeekdays,
      );

      final edit = widget.reminderToEdit;
      final assignedId = _selectedScope == ReminderCompletionScope.assigned ? _selectedAssignedTo : null;

      if (edit != null) {
        await ref.read(reminderRepositoryProvider).updateReminder(
          reminderId: edit.id,
          title: title,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          dueAt: effectiveDueAt,
          rrule: rrule,
          completionScope: _selectedScope,
          assignedTo: assignedId,
        );
        await ref.read(remindersProvider.notifier).refresh();
      } else {
        final activeHivemind = ref.read(activeHivemindProvider);
        if (activeHivemind == null) return;

        await ref.read(reminderRepositoryProvider).createReminder(
          hivemindId: activeHivemind.id,
          title: title,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          dueAt: effectiveDueAt,
          rrule: rrule,
          completionScope: _selectedScope,
          assignedTo: assignedId,
        );
        await ref.read(remindersProvider.notifier).refresh();
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final isEdit = widget.reminderToEdit != null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? context.l10n.errorUpdatingReminder(e.toString())
                  : context.l10n.errorCreatingReminder(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildDayButton(int day, bool isDark, bool isGerman) {
    final isSelected = _selectedWeekdays.contains(day);
    final dayLabel = _getDayLabel(day, isGerman);
    final fullDayName = _getFullDayName(day, isGerman);

    return Semantics(
      button: true,
      label: '$fullDayName, ${isSelected ? "selected" : "not selected"}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _toggleWeekday(day),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: isSelected ? 1.8 : 1.0,
              ),
            ),
            child: Text(
              dayLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.black
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getDayLabel(int day, bool isGerman) {
    if (isGerman) {
      switch (day) {
        case DateTime.monday: return 'Mo';
        case DateTime.tuesday: return 'Di';
        case DateTime.wednesday: return 'Mi';
        case DateTime.thursday: return 'Do';
        case DateTime.friday: return 'Fr';
        case DateTime.saturday: return 'Sa';
        case DateTime.sunday: return 'So';
        default: return '';
      }
    } else {
      switch (day) {
        case DateTime.monday: return 'M';
        case DateTime.tuesday: return 'Tu';
        case DateTime.wednesday: return 'W';
        case DateTime.thursday: return 'Th';
        case DateTime.friday: return 'F';
        case DateTime.saturday: return 'Sa';
        case DateTime.sunday: return 'Su';
        default: return '';
      }
    }
  }

  String _getFullDayName(int day, bool isGerman) {
    if (isGerman) {
      switch (day) {
        case DateTime.monday: return 'Montag';
        case DateTime.tuesday: return 'Dienstag';
        case DateTime.wednesday: return 'Mittwoch';
        case DateTime.thursday: return 'Donnerstag';
        case DateTime.friday: return 'Freitag';
        case DateTime.saturday: return 'Samstag';
        case DateTime.sunday: return 'Sonntag';
        default: return '';
      }
    } else {
      switch (day) {
        case DateTime.monday: return 'Monday';
        case DateTime.tuesday: return 'Tuesday';
        case DateTime.wednesday: return 'Wednesday';
        case DateTime.thursday: return 'Thursday';
        case DateTime.friday: return 'Friday';
        case DateTime.saturday: return 'Saturday';
        case DateTime.sunday: return 'Sunday';
        default: return '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final isGerman = locale.startsWith('de');
    final dateFormat = DateFormat.yMMMEd(locale);
    final timeFormat = DateFormat.jm(locale);
    final isEdit = widget.reminderToEdit != null;

    final showWeekdayPicker = _selectedPreset == RecurrencePreset.customDays ||
        _selectedPreset == RecurrencePreset.weekly ||
        _selectedPreset == RecurrencePreset.weekdays;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEdit ? l10n.editReminder : l10n.newReminder,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 18),

            // Title
            MinimalTextField(
              controller: _titleController,
              hintText: l10n.reminderTitleHint,
              autofocus: !isEdit,
            ),
            const SizedBox(height: 12),

            // Notes
            MinimalTextField(
              controller: _notesController,
              hintText: l10n.reminderNotesHint,
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // Due Date & Time Pickers
            Text(
              l10n.sectionDueDateAndTime,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(dateFormat.format(_selectedDate)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      side: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time_rounded, size: 18),
                    label: Text(
                      timeFormat.format(
                        DateTime(2026, 1, 1, _selectedTime.hour, _selectedTime.minute),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      side: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Completion Requirement Section (Anyone, Assigned, All)
            Text(
              l10n.sectionCompletionRequirement,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  avatar: Icon(
                    Icons.bolt_rounded,
                    size: 16,
                    color: _selectedScope == ReminderCompletionScope.anyone
                        ? AppColors.primary
                        : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  ),
                  label: Text(l10n.scopeAnyone),
                  selected: _selectedScope == ReminderCompletionScope.anyone,
                  selectedColor: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                  backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: _selectedScope == ReminderCompletionScope.anyone
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: _selectedScope == ReminderCompletionScope.anyone
                        ? AppColors.primary
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  side: BorderSide(
                    color: _selectedScope == ReminderCompletionScope.anyone
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: _selectedScope == ReminderCompletionScope.anyone ? 1.5 : 1,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedScope = ReminderCompletionScope.anyone;
                      });
                    }
                  },
                ),
                ChoiceChip(
                  avatar: Icon(
                    Icons.assignment_ind_outlined,
                    size: 16,
                    color: _selectedScope == ReminderCompletionScope.assigned
                        ? AppColors.primary
                        : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  ),
                  label: Text(l10n.scopeAssigned),
                  selected: _selectedScope == ReminderCompletionScope.assigned,
                  selectedColor: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                  backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: _selectedScope == ReminderCompletionScope.assigned
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: _selectedScope == ReminderCompletionScope.assigned
                        ? AppColors.primary
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  side: BorderSide(
                    color: _selectedScope == ReminderCompletionScope.assigned
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: _selectedScope == ReminderCompletionScope.assigned ? 1.5 : 1,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedScope = ReminderCompletionScope.assigned;
                        final members = ref.read(activeHivemindMembersProvider).value ?? [];
                        final currentUid = FirebaseService.currentUserId;
                        if (_selectedAssignedTo == null && members.isNotEmpty) {
                          _selectedAssignedTo = currentUid ?? members.first.userId;
                        }
                      });
                    }
                  },
                ),
                ChoiceChip(
                  avatar: Icon(
                    Icons.groups_outlined,
                    size: 16,
                    color: _selectedScope == ReminderCompletionScope.all
                        ? AppColors.primary
                        : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  ),
                  label: Text(l10n.scopeAll),
                  selected: _selectedScope == ReminderCompletionScope.all,
                  selectedColor: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                  backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: _selectedScope == ReminderCompletionScope.all
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: _selectedScope == ReminderCompletionScope.all
                        ? AppColors.primary
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  side: BorderSide(
                    color: _selectedScope == ReminderCompletionScope.all
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: _selectedScope == ReminderCompletionScope.all ? 1.5 : 1,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedScope = ReminderCompletionScope.all;
                      });
                    }
                  },
                ),
              ],
            ),

            if (_selectedScope == ReminderCompletionScope.assigned) ...[
              const SizedBox(height: 10),
              Builder(
                builder: (context) {
                  final members = ref.watch(activeHivemindMembersProvider).value ?? [];
                  final currentUid = FirebaseService.currentUserId;
                  if (members.isEmpty) {
                    return Text(
                      l10n.selectAssignee,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: members.map((member) {
                      final isSelected = _selectedAssignedTo == member.userId;
                      final isYou = member.userId == currentUid;
                      final labelText = isYou ? '${member.displayName} (${l10n.assignedToYou})' : member.displayName;

                      return FilterChip(
                        selected: isSelected,
                        showCheckmark: false,
                        avatar: CircleAvatar(
                          radius: 10,
                          backgroundColor: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle),
                          child: Text(
                            member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                        label: Text(labelText),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        selectedColor: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: isSelected ? 1.5 : 1,
                        ),
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedAssignedTo = member.userId;
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
            const SizedBox(height: 22),

            // Recurrence Section
            Text(
              l10n.sectionRecurrence,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RecurrencePreset.values.map((preset) {
                final isSelected = _selectedPreset == preset;
                return ChoiceChip(
                  label: Text(RecurrenceUtil.getReadablePresetTitle(preset, l10n)),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                  backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: isSelected ? 1.5 : 1,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPreset = preset;
                        if (preset == RecurrencePreset.weekdays) {
                          _selectedWeekdays = {1, 2, 3, 4, 5};
                        } else if (preset == RecurrencePreset.daily) {
                          _selectedWeekdays = {1, 2, 3, 4, 5, 6, 7};
                        } else if (preset == RecurrencePreset.weekly) {
                          _selectedWeekdays = {_selectedDate.weekday};
                        } else if (preset == RecurrencePreset.customDays && _selectedWeekdays.isEmpty) {
                          _selectedWeekdays = {_selectedDate.weekday};
                        }
                      });
                    }
                  },
                );
              }).toList(),
            ),

            // Weekday Picker Section (Visible when customDays, weekly, or weekdays is selected)
            if (showWeekdayPicker) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.sectionSelectWeekdays,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  // Quick selection pills
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildQuickPill(
                        label: l10n.presetWeekdaysOnly,
                        isSelected: _selectedWeekdays.length == 5 &&
                            _selectedWeekdays.contains(1) &&
                            _selectedWeekdays.contains(5),
                        isDark: isDark,
                        onTap: () => _selectWeekdayPreset({1, 2, 3, 4, 5}),
                      ),
                      const SizedBox(width: 6),
                      _buildQuickPill(
                        label: l10n.presetWeekendsOnly,
                        isSelected: _selectedWeekdays.length == 2 &&
                            _selectedWeekdays.contains(6) &&
                            _selectedWeekdays.contains(7),
                        isDark: isDark,
                        onTap: () => _selectWeekdayPreset({6, 7}),
                      ),
                      const SizedBox(width: 6),
                      _buildQuickPill(
                        label: l10n.presetAllDays,
                        isSelected: _selectedWeekdays.length == 7,
                        isDark: isDark,
                        onTap: () => _selectWeekdayPreset({1, 2, 3, 4, 5, 6, 7}),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final day in [
                    DateTime.monday,
                    DateTime.tuesday,
                    DateTime.wednesday,
                    DateTime.thursday,
                    DateTime.friday,
                    DateTime.saturday,
                    DateTime.sunday,
                  ])
                    _buildDayButton(day, isDark, isGerman),
                ],
              ),
            ],

            const SizedBox(height: 28),

            // Submit Button
            MinimalButton(
              text: isEdit ? l10n.saveChanges : l10n.buttonSaveReminder,
              isLoading: _isLoading,
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPill({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15)
              : (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          ),
        ),
      ),
    );
  }
}
