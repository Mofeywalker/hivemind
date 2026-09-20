import 'package:flutter_test/flutter_test.dart';
import 'package:hivemind/features/hiveminds/domain/hivemind_model.dart';
import 'package:hivemind/features/reminders/domain/reminder_model.dart';

void main() {
  group('Hivemind Domain Models Test', () {
    test('Hivemind model serialization & deserialization', () {
      final now = DateTime.now();
      final hivemind = Hivemind(
        id: '11111111-1111-1111-1111-111111111111',
        name: 'Family Squad',
        description: 'Daily household reminders',
        icon: '🏠',
        inviteCode: 'FAM123',
        createdBy: '22222222-2222-2222-2222-222222222222',
        createdAt: now,
      );

      final json = hivemind.toJson();
      expect(json['id'], hivemind.id);
      expect(json['name'], 'Family Squad');
      expect(json['icon'], '🏠');
      expect(json['invite_code'], 'FAM123');

      final fromJson = Hivemind.fromJson(json);
      expect(fromJson.id, hivemind.id);
      expect(fromJson.name, hivemind.name);
      expect(fromJson.icon, hivemind.icon);
      expect(fromJson.inviteCode, hivemind.inviteCode);
    });

    test('Reminder model serialization & recurrence helpers', () {
      final due = DateTime(2026, 9, 21, 10, 0);
      final reminder = Reminder(
        id: 'rem-1',
        hivemindId: 'hive-1',
        title: 'Weekly Standup',
        notes: 'Discuss sprint goals',
        dueAt: due,
        rrule: 'RRULE:FREQ=WEEKLY;BYDAY=MO',
        createdAt: due.subtract(const Duration(days: 1)),
        updatedAt: due.subtract(const Duration(days: 1)),
      );

      expect(reminder.isRecurring, isTrue);
      expect(reminder.isCompleted, isFalse);

      final json = reminder.toJson();
      expect(json['id'], 'rem-1');
      expect(json['rrule'], 'RRULE:FREQ=WEEKLY;BYDAY=MO');

      final fromJson = Reminder.fromJson(json);
      expect(fromJson.title, 'Weekly Standup');
      expect(fromJson.isRecurring, isTrue);

      final completedCopy = reminder.copyWith(isCompleted: true);
      expect(completedCopy.isCompleted, isTrue);
      expect(completedCopy.id, reminder.id);
    });
  });
}
