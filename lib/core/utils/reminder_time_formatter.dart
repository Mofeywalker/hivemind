import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'recurrence_util.dart';

class ReminderTimeFormatter {
  ReminderTimeFormatter._();

  static String formatTimeTrigger({
    required DateTime dueAt,
    String? rrule,
    Locale? locale,
  }) {
    final effectiveLocale =
        locale ?? WidgetsBinding.instance.platformDispatcher.locale;
    final localeStr = effectiveLocale.languageCode;
    final isGerman = localeStr == 'de';

    final localDueAt = dueAt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(localDueAt.year, localDueAt.month, localDueAt.day);
    final dayDiff = dueDate.difference(today).inDays;

    final timeFormat = DateFormat(isGerman ? 'HH:mm' : 'h:mm a', localeStr);
    final timeStr = timeFormat.format(localDueAt);
    final timeWithUnit = isGerman ? '$timeStr Uhr' : timeStr;

    String datePart;
    if (dayDiff == 0) {
      datePart = isGerman ? 'Heute, $timeWithUnit' : 'Today, $timeWithUnit';
    } else if (dayDiff == 1) {
      datePart = isGerman ? 'Morgen, $timeWithUnit' : 'Tomorrow, $timeWithUnit';
    } else if (dayDiff == -1) {
      datePart = isGerman
          ? 'Gestern, $timeWithUnit'
          : 'Yesterday, $timeWithUnit';
    } else {
      final dateFormat = DateFormat.MMMd(localeStr);
      final dateFormatted = dateFormat.format(localDueAt);
      datePart = isGerman
          ? '$dateFormatted, $timeWithUnit'
          : '$dateFormatted at $timeWithUnit';
    }

    final preset = RecurrenceUtil.presetFromRRule(rrule);
    if (preset != RecurrencePreset.none) {
      final recurrenceLabel = _getRecurrenceLabel(preset, rrule, isGerman);
      return '$datePart • $recurrenceLabel';
    }

    return datePart;
  }

  static String _getRecurrenceLabel(
    RecurrencePreset preset,
    String? rrule,
    bool isGerman,
  ) {
    switch (preset) {
      case RecurrencePreset.daily:
        return isGerman ? 'Täglich' : 'Daily';
      case RecurrencePreset.weekly:
        return isGerman ? 'Wöchentlich' : 'Weekly';
      case RecurrencePreset.customDays:
        return RecurrenceUtil.getReadableRecurrenceDescription(
          rrule,
          isGerman: isGerman,
        );
      case RecurrencePreset.biweekly:
        return isGerman ? 'Alle 2 Wochen' : 'Bi-weekly';
      case RecurrencePreset.monthly:
        return isGerman ? 'Monatlich' : 'Monthly';
      case RecurrencePreset.weekdays:
        return isGerman ? 'Mo - Fr' : 'Mon - Fri';
      case RecurrencePreset.none:
        return '';
    }
  }
}
