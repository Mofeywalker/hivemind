import 'package:flutter_test/flutter_test.dart';
import 'package:hivemind/core/utils/recurrence_util.dart';

void main() {
  group('RecurrenceUtil Tests', () {
    test(
      'Daily recurrence returns valid RRULE string and next day occurrence',
      () {
        final now = DateTime(2026, 9, 20, 8, 0); // Sunday 8:00 AM
        final rruleStr = RecurrenceUtil.toRRuleString(
          preset: RecurrencePreset.daily,
          baseDateTime: now,
        );

        expect(rruleStr, 'RRULE:FREQ=DAILY');

        final next = RecurrenceUtil.getNextOccurrence(
          rruleString: rruleStr,
          baseDueAt: now,
          after: now,
        );

        expect(next, isNotNull);
        expect(next!.isAfter(now), isTrue);
      },
    );

    test('Weekly recurrence for Sunday 8 AM', () {
      final sunday = DateTime(2026, 9, 20, 8, 0); // Sunday
      final rruleStr = RecurrenceUtil.toRRuleString(
        preset: RecurrencePreset.weekly,
        baseDateTime: sunday,
      );

      expect(rruleStr, 'RRULE:FREQ=WEEKLY;BYDAY=SU');
      expect(RecurrenceUtil.presetFromRRule(rruleStr), RecurrencePreset.weekly);

      final next = RecurrenceUtil.getNextOccurrence(
        rruleString: rruleStr,
        baseDueAt: sunday,
        after: sunday,
      );

      expect(next, isNotNull);
      expect(next!.weekday, DateTime.sunday);
    });

    test('Bi-weekly recurrence contains INTERVAL=2', () {
      final monday = DateTime(2026, 9, 21, 9, 0);
      final rruleStr = RecurrenceUtil.toRRuleString(
        preset: RecurrencePreset.biweekly,
        baseDateTime: monday,
      );

      expect(rruleStr, contains('INTERVAL=2'));
      expect(
        RecurrenceUtil.presetFromRRule(rruleStr),
        RecurrencePreset.biweekly,
      );
    });

    test('Weekdays recurrence contains MO,TU,WE,TH,FR', () {
      final dt = DateTime(2026, 9, 21, 9, 0);
      final rruleStr = RecurrenceUtil.toRRuleString(
        preset: RecurrencePreset.weekdays,
        baseDateTime: dt,
      );

      expect(rruleStr, 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR');
      expect(
        RecurrenceUtil.presetFromRRule(rruleStr),
        RecurrencePreset.weekdays,
      );
    });

    test('Custom weekdays recurrence creates RRULE with sorted BYDAY', () {
      final sunday = DateTime(2026, 9, 20, 10, 0);
      final rruleStr = RecurrenceUtil.toRRuleString(
        preset: RecurrencePreset.customDays,
        baseDateTime: sunday,
        customWeekdays: {DateTime.thursday, DateTime.monday},
      );

      expect(rruleStr, 'RRULE:FREQ=WEEKLY;BYDAY=MO,TH');
      expect(
        RecurrenceUtil.presetFromRRule(rruleStr),
        RecurrencePreset.customDays,
      );
      expect(RecurrenceUtil.weekdaysFromRRule(rruleStr), {
        DateTime.monday,
        DateTime.thursday,
      });
    });

    test('getFirstOccurrenceOnOrAfter advances to first matching weekday', () {
      final sunday = DateTime(2026, 9, 20, 10, 0); // Sunday (day 7)

      // When Sunday is in the set, stays Sunday
      final firstSunday = RecurrenceUtil.getFirstOccurrenceOnOrAfter(
        baseDueAt: sunday,
        weekdays: {DateTime.sunday, DateTime.wednesday},
      );
      expect(firstSunday.weekday, DateTime.sunday);

      // When set is Monday (day 1) and Thursday (day 4), advances to Monday (day 1)
      final firstMonday = RecurrenceUtil.getFirstOccurrenceOnOrAfter(
        baseDueAt: sunday,
        weekdays: {DateTime.monday, DateTime.thursday},
      );
      expect(firstMonday.weekday, DateTime.monday);
      expect(firstMonday.difference(sunday).inDays, 1);
    });

    test('getNextOccurrence alternates accurately between custom weekdays', () {
      // Monday 9:00 AM
      final monday = DateTime(2026, 9, 21, 9, 0);
      final rruleStr = 'RRULE:FREQ=WEEKLY;BYDAY=MO,TH';

      // Next after Monday morning should be Thursday
      final nextThurs = RecurrenceUtil.getNextOccurrence(
        rruleString: rruleStr,
        baseDueAt: monday,
        after: monday,
      );
      expect(nextThurs, isNotNull);
      expect(nextThurs!.weekday, DateTime.thursday);
      expect(nextThurs.hour, 9);
      expect(nextThurs.minute, 0);

      // Next after Thursday should be the following Monday
      final nextMon = RecurrenceUtil.getNextOccurrence(
        rruleString: rruleStr,
        baseDueAt: monday,
        after: nextThurs,
      );
      expect(nextMon, isNotNull);
      expect(nextMon!.weekday, DateTime.monday);
    });

    test('getReadableRecurrenceDescription formats correctly for German and English', () {
      const rruleMulti = 'RRULE:FREQ=WEEKLY;BYDAY=MO,TH';
      expect(
        RecurrenceUtil.getReadableRecurrenceDescription(
          rruleMulti,
          isGerman: true,
        ),
        'Jeden Mo, Do',
      );
      expect(
        RecurrenceUtil.getReadableRecurrenceDescription(
          rruleMulti,
          isGerman: false,
        ),
        'Every Mon, Thu',
      );

      const rruleWeekend = 'RRULE:FREQ=WEEKLY;BYDAY=SA,SU';
      expect(
        RecurrenceUtil.getReadableRecurrenceDescription(
          rruleWeekend,
          isGerman: true,
        ),
        'Sa, So',
      );
      expect(
        RecurrenceUtil.getReadableRecurrenceDescription(
          rruleWeekend,
          isGerman: false,
        ),
        'Sat, Sun',
      );

      const rruleSingle = 'RRULE:FREQ=WEEKLY;BYDAY=WE';
      expect(
        RecurrenceUtil.getReadableRecurrenceDescription(
          rruleSingle,
          isGerman: true,
        ),
        'Jeden Mittwoch',
      );
      expect(
        RecurrenceUtil.getReadableRecurrenceDescription(
          rruleSingle,
          isGerman: false,
        ),
        'Every Wednesday',
      );
    });
  });
}
