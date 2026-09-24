import 'package:rrule/rrule.dart';

import '../../l10n/app_localizations.dart';

enum RecurrencePreset {
  none,
  daily,
  weekly,
  customDays,
  biweekly,
  monthly,
  weekdays,
}

class RecurrenceUtil {
  RecurrenceUtil._();

  static Set<int> weekdaysFromRRule(String? rruleString) {
    if (rruleString == null || rruleString.trim().isEmpty) {
      return {};
    }
    final upper = rruleString.toUpperCase();

    if (upper.contains('FREQ=DAILY')) {
      return {1, 2, 3, 4, 5, 6, 7};
    }

    final match = RegExp(r'BYDAY=([A-Z,]+)').firstMatch(upper);
    if (match == null) return {};

    final daysStr = match.group(1)!;
    final tokens = daysStr.split(',');
    final result = <int>{};
    for (final t in tokens) {
      final trimmed = t.trim();
      switch (trimmed) {
        case 'MO':
          result.add(DateTime.monday);
          break;
        case 'TU':
          result.add(DateTime.tuesday);
          break;
        case 'WE':
          result.add(DateTime.wednesday);
          break;
        case 'TH':
          result.add(DateTime.thursday);
          break;
        case 'FR':
          result.add(DateTime.friday);
          break;
        case 'SA':
          result.add(DateTime.saturday);
          break;
        case 'SU':
          result.add(DateTime.sunday);
          break;
      }
    }
    return result;
  }

  static String weekdaysToByDay(Iterable<int> weekdays) {
    final sorted = weekdays.toSet().toList()..sort();
    return sorted.map((w) => _toByWeekDay(w)).join(',');
  }

  static String? toRRuleString({
    required RecurrencePreset preset,
    required DateTime baseDateTime,
    int? customWeekday, // 1 = Mon, 7 = Sun (DateTime convention)
    Set<int>? customWeekdays,
  }) {
    if (preset == RecurrencePreset.none) return null;

    switch (preset) {
      case RecurrencePreset.none:
        return null;
      case RecurrencePreset.daily:
        return 'RRULE:FREQ=DAILY';
      case RecurrencePreset.weekly:
        final weekday = (customWeekdays != null && customWeekdays.isNotEmpty)
            ? customWeekdays.first
            : (customWeekday ?? baseDateTime.weekday);
        final byWeekDay = _toByWeekDay(weekday);
        return 'RRULE:FREQ=WEEKLY;BYDAY=$byWeekDay';
      case RecurrencePreset.customDays:
        final days = (customWeekdays != null && customWeekdays.isNotEmpty)
            ? customWeekdays
            : {customWeekday ?? baseDateTime.weekday};
        return 'RRULE:FREQ=WEEKLY;BYDAY=${weekdaysToByDay(days)}';
      case RecurrencePreset.biweekly:
        final weekday = (customWeekdays != null && customWeekdays.isNotEmpty)
            ? customWeekdays.first
            : (customWeekday ?? baseDateTime.weekday);
        final byWeekDay = _toByWeekDay(weekday);
        return 'RRULE:FREQ=WEEKLY;INTERVAL=2;BYDAY=$byWeekDay';
      case RecurrencePreset.monthly:
        return 'RRULE:FREQ=MONTHLY;BYMONTHDAY=${baseDateTime.day}';
      case RecurrencePreset.weekdays:
        return 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR';
    }
  }

  static RecurrencePreset presetFromRRule(String? rruleString) {
    if (rruleString == null || rruleString.trim().isEmpty) {
      return RecurrencePreset.none;
    }
    final upper = rruleString.toUpperCase();
    if (upper.contains('INTERVAL=2')) return RecurrencePreset.biweekly;
    if (upper.contains('BYDAY=MO,TU,WE,TH,FR')) {
      return RecurrencePreset.weekdays;
    }
    if (upper.contains('FREQ=DAILY')) return RecurrencePreset.daily;
    if (upper.contains('FREQ=MONTHLY')) return RecurrencePreset.monthly;
    if (upper.contains('FREQ=WEEKLY')) {
      final days = weekdaysFromRRule(upper);
      if (days.length > 1) {
        return RecurrencePreset.customDays;
      }
      return RecurrencePreset.weekly;
    }
    return RecurrencePreset.none;
  }

  static DateTime getFirstOccurrenceOnOrAfter({
    required DateTime baseDueAt,
    required Set<int> weekdays,
  }) {
    if (weekdays.isEmpty || weekdays.contains(baseDueAt.weekday)) {
      return baseDueAt;
    }

    for (int i = 1; i <= 7; i++) {
      final candidate = baseDueAt.add(Duration(days: i));
      if (weekdays.contains(candidate.weekday)) {
        return candidate;
      }
    }
    return baseDueAt;
  }

  static DateTime? getNextOccurrence({
    required String? rruleString,
    required DateTime baseDueAt,
    DateTime? after,
  }) {
    if (rruleString == null || rruleString.trim().isEmpty) {
      return null;
    }

    final validWeekdays = weekdaysFromRRule(rruleString);

    try {
      final effectiveAfter = after ?? DateTime.now();
      final rruleClean = rruleString.startsWith('RRULE:')
          ? rruleString.substring(6)
          : rruleString;

      final recurrenceRule = RecurrenceRule.fromString('RRULE:$rruleClean');
      final instances = recurrenceRule.getInstances(start: baseDueAt.toUtc());

      for (final dt in instances) {
        final localDt = dt.toLocal();
        if (localDt.isAfter(effectiveAfter)) {
          if (validWeekdays.isEmpty ||
              validWeekdays.contains(localDt.weekday)) {
            return localDt;
          }
        }
      }
    } catch (_) {
      // Fallback interval if RRULE parsing fails
      final preset = presetFromRRule(rruleString);
      final ref = after ?? DateTime.now();

      if (validWeekdays.isNotEmpty) {
        var next = DateTime(
          ref.year,
          ref.month,
          ref.day,
          baseDueAt.hour,
          baseDueAt.minute,
        );
        if (!next.isAfter(ref)) {
          next = next.add(const Duration(days: 1));
        }
        for (int i = 0; i < 60; i++) {
          if (validWeekdays.contains(next.weekday) && next.isAfter(ref)) {
            return next;
          }
          next = next.add(const Duration(days: 1));
        }
      }

      switch (preset) {
        case RecurrencePreset.daily:
          return ref.add(const Duration(days: 1));
        case RecurrencePreset.weekly:
          return ref.add(const Duration(days: 7));
        case RecurrencePreset.biweekly:
          return ref.add(const Duration(days: 14));
        case RecurrencePreset.monthly:
          return DateTime(
            ref.year,
            ref.month + 1,
            ref.day,
            baseDueAt.hour,
            baseDueAt.minute,
          );
        case RecurrencePreset.weekdays:
          var next = ref.add(const Duration(days: 1));
          while (next.weekday == DateTime.saturday ||
              next.weekday == DateTime.sunday) {
            next = next.add(const Duration(days: 1));
          }
          return next;
        case RecurrencePreset.customDays:
        case RecurrencePreset.none:
          return null;
      }
    }
    return null;
  }

  static String getReadablePresetTitle(
    RecurrencePreset preset, [
    AppLocalizations? l10n,
  ]) {
    if (l10n != null) {
      switch (preset) {
        case RecurrencePreset.none:
          return l10n.recurrenceDoesNotRepeat;
        case RecurrencePreset.daily:
          return l10n.recurrenceDaily;
        case RecurrencePreset.weekly:
          return l10n.recurrenceWeekly;
        case RecurrencePreset.customDays:
          return l10n.recurrenceCustomDays;
        case RecurrencePreset.biweekly:
          return l10n.recurrenceBiweekly;
        case RecurrencePreset.monthly:
          return l10n.recurrenceMonthly;
        case RecurrencePreset.weekdays:
          return l10n.recurrenceWeekdays;
      }
    }
    switch (preset) {
      case RecurrencePreset.none:
        return 'Does not repeat';
      case RecurrencePreset.daily:
        return 'Every day';
      case RecurrencePreset.weekly:
        return 'Every week';
      case RecurrencePreset.customDays:
        return 'Specific days';
      case RecurrencePreset.biweekly:
        return 'Every other week';
      case RecurrencePreset.monthly:
        return 'Every month';
      case RecurrencePreset.weekdays:
        return 'Every weekday (Mon - Fri)';
    }
  }

  static String getReadableRecurrenceDescription(
    String? rruleString, {
    AppLocalizations? l10n,
    bool isGerman = true,
  }) {
    if (rruleString == null || rruleString.trim().isEmpty) {
      return l10n?.recurrenceDoesNotRepeat ??
          (isGerman ? 'Einmalig' : 'Does not repeat');
    }

    final preset = presetFromRRule(rruleString);
    if (preset == RecurrencePreset.daily) {
      return l10n?.recurrenceDaily ?? (isGerman ? 'Täglich' : 'Daily');
    }
    if (preset == RecurrencePreset.monthly) {
      return l10n?.recurrenceMonthly ?? (isGerman ? 'Monatlich' : 'Monthly');
    }
    if (preset == RecurrencePreset.weekdays) {
      return isGerman ? 'Mo - Fr' : 'Mon - Fri';
    }

    final days = weekdaysFromRRule(rruleString);
    if (days.isEmpty) {
      return getReadablePresetTitle(preset, l10n);
    }

    if (days.length == 7) {
      return l10n?.recurrenceDaily ?? (isGerman ? 'Täglich' : 'Daily');
    }

    final sortedDays = days.toList()..sort();

    // Weekdays check
    if (sortedDays.length == 5 &&
        sortedDays.contains(1) &&
        sortedDays.contains(2) &&
        sortedDays.contains(3) &&
        sortedDays.contains(4) &&
        sortedDays.contains(5)) {
      return isGerman ? 'Mo - Fr' : 'Mon - Fri';
    }

    // Weekend check
    if (sortedDays.length == 2 &&
        sortedDays.contains(6) &&
        sortedDays.contains(7)) {
      return isGerman ? 'Sa, So' : 'Sat, Sun';
    }

    final prefix = l10n?.everyWeekdayPrefix ?? (isGerman ? 'Jeden' : 'Every');

    if (sortedDays.length == 1) {
      final dayName = _weekdayFull(sortedDays.first, isGerman);
      return '$prefix $dayName';
    }

    final formattedDays = sortedDays
        .map((d) => _weekdayShort(d, isGerman))
        .join(', ');
    return '$prefix $formattedDays';
  }

  static String _weekdayShort(int weekday, bool isGerman) {
    if (isGerman) {
      switch (weekday) {
        case DateTime.monday:
          return 'Mo';
        case DateTime.tuesday:
          return 'Di';
        case DateTime.wednesday:
          return 'Mi';
        case DateTime.thursday:
          return 'Do';
        case DateTime.friday:
          return 'Fr';
        case DateTime.saturday:
          return 'Sa';
        case DateTime.sunday:
          return 'So';
        default:
          return 'Mo';
      }
    } else {
      switch (weekday) {
        case DateTime.monday:
          return 'Mon';
        case DateTime.tuesday:
          return 'Tue';
        case DateTime.wednesday:
          return 'Wed';
        case DateTime.thursday:
          return 'Thu';
        case DateTime.friday:
          return 'Fri';
        case DateTime.saturday:
          return 'Sat';
        case DateTime.sunday:
          return 'Sun';
        default:
          return 'Mon';
      }
    }
  }

  static String _weekdayFull(int weekday, bool isGerman) {
    if (isGerman) {
      switch (weekday) {
        case DateTime.monday:
          return 'Montag';
        case DateTime.tuesday:
          return 'Dienstag';
        case DateTime.wednesday:
          return 'Mittwoch';
        case DateTime.thursday:
          return 'Donnerstag';
        case DateTime.friday:
          return 'Freitag';
        case DateTime.saturday:
          return 'Samstag';
        case DateTime.sunday:
          return 'Sonntag';
        default:
          return 'Montag';
      }
    } else {
      switch (weekday) {
        case DateTime.monday:
          return 'Monday';
        case DateTime.tuesday:
          return 'Tuesday';
        case DateTime.wednesday:
          return 'Wednesday';
        case DateTime.thursday:
          return 'Thursday';
        case DateTime.friday:
          return 'Friday';
        case DateTime.saturday:
          return 'Saturday';
        case DateTime.sunday:
          return 'Sunday';
        default:
          return 'Monday';
      }
    }
  }

  static String _toByWeekDay(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'MO';
      case DateTime.tuesday:
        return 'TU';
      case DateTime.wednesday:
        return 'WE';
      case DateTime.thursday:
        return 'TH';
      case DateTime.friday:
        return 'FR';
      case DateTime.saturday:
        return 'SA';
      case DateTime.sunday:
        return 'SU';
      default:
        return 'MO';
    }
  }
}
