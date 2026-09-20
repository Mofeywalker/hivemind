import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivemind/core/utils/reminder_time_formatter.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('de');
    await initializeDateFormatting('en');
  });

  group('ReminderTimeFormatter Tests', () {
    test('Formats today correctly in German', () {
      final now = DateTime.now();
      final todayAt18 = DateTime(now.year, now.month, now.day, 18, 30);

      final result = ReminderTimeFormatter.formatTimeTrigger(
        dueAt: todayAt18,
        locale: const Locale('de'),
      );

      expect(result, contains('Heute'));
      expect(result, contains('18:30 Uhr'));
    });

    test('Formats today with daily recurrence in German', () {
      final now = DateTime.now();
      final todayAt9 = DateTime(now.year, now.month, now.day, 9, 0);

      final result = ReminderTimeFormatter.formatTimeTrigger(
        dueAt: todayAt9,
        rrule: 'RRULE:FREQ=DAILY',
        locale: const Locale('de'),
      );

      expect(result, contains('Heute'));
      expect(result, contains('09:00 Uhr'));
      expect(result, contains('Täglich'));
    });

    test('Formats tomorrow with weekly recurrence in German', () {
      final now = DateTime.now().add(const Duration(days: 1));
      final tomorrowAt15 = DateTime(now.year, now.month, now.day, 15, 0);

      final result = ReminderTimeFormatter.formatTimeTrigger(
        dueAt: tomorrowAt15,
        rrule: 'RRULE:FREQ=WEEKLY;BYDAY=MO',
        locale: const Locale('de'),
      );

      expect(result, contains('Morgen'));
      expect(result, contains('15:00 Uhr'));
      expect(result, contains('Wöchentlich'));
    });

    test('Formats today in English', () {
      final now = DateTime.now();
      final todayAt18 = DateTime(now.year, now.month, now.day, 18, 0);

      final result = ReminderTimeFormatter.formatTimeTrigger(
        dueAt: todayAt18,
        locale: const Locale('en'),
      );

      expect(result, contains('Today'));
      expect(result, contains('6:00 PM'));
    });

    test('Formats recurrence in English', () {
      final now = DateTime.now();
      final todayAt9 = DateTime(now.year, now.month, now.day, 9, 0);

      final result = ReminderTimeFormatter.formatTimeTrigger(
        dueAt: todayAt9,
        rrule: 'RRULE:FREQ=DAILY',
        locale: const Locale('en'),
      );

      expect(result, contains('Today'));
      expect(result, contains('Daily'));
    });

    test('Formats custom weekdays recurrence in German and English', () {
      final now = DateTime.now();
      final todayAt10 = DateTime(now.year, now.month, now.day, 10, 0);

      final resultDe = ReminderTimeFormatter.formatTimeTrigger(
        dueAt: todayAt10,
        rrule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,TH',
        locale: const Locale('de'),
      );

      expect(resultDe, contains('10:00 Uhr'));
      expect(resultDe, contains('Jeden Mo, Do'));

      final resultEn = ReminderTimeFormatter.formatTimeTrigger(
        dueAt: todayAt10,
        rrule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,TH',
        locale: const Locale('en'),
      );

      expect(resultEn, contains('Every Mon, Thu'));
    });
  });
}
