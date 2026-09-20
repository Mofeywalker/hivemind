import 'package:flutter_test/flutter_test.dart';
import 'package:hivemind/features/reminders/domain/reminder_model.dart';

void main() {
  group('Reminder Model Tests', () {
    final now = DateTime(2026, 9, 20, 15, 30);

    test('isCompletedByUser checks completedByIds and fallback', () {
      final reminder = Reminder(
        id: 'rem-1',
        hivemindId: 'hive-1',
        title: 'Clean kitchen',
        dueAt: now,
        completedByIds: ['user-alice', 'user-bob'],
        createdAt: now,
        updatedAt: now,
      );

      expect(reminder.isCompletedByUser('user-alice'), isTrue);
      expect(reminder.isCompletedByUser('user-bob'), isTrue);
      expect(reminder.isCompletedByUser('user-charlie'), isFalse);
    });

    test('isCompletedByAll verifies all hive members', () {
      final reminder = Reminder(
        id: 'rem-1',
        hivemindId: 'hive-1',
        title: 'Müll rausbringen',
        dueAt: now,
        completedByIds: ['user-alice', 'user-bob'],
        createdAt: now,
        updatedAt: now,
      );

      // Only Alice & Bob in Hive
      expect(reminder.isCompletedByAll({'user-alice', 'user-bob'}), isTrue);

      // Alice, Bob & Charlie in Hive
      expect(reminder.isCompletedByAll({'user-alice', 'user-bob', 'user-charlie'}), isFalse);

      // Empty member set falls back to isCompleted
      expect(reminder.isCompletedByAll({}), isFalse);

      final fullyCompleted = reminder.copyWith(isCompleted: true);
      expect(fullyCompleted.isCompletedByAll({}), isTrue);
    });

    test('JSON serialization handles completed_by_ids and backwards compatibility', () {
      final jsonLegacy = {
        'id': 'rem-1',
        'hivemind_id': 'hive-1',
        'title': 'Legacy reminder',
        'due_at': now.toUtc().toIso8601String(),
        'is_completed': true,
        'completed_by': 'user-alice',
        'created_at': now.toUtc().toIso8601String(),
        'updated_at': now.toUtc().toIso8601String(),
      };

      final parsedLegacy = Reminder.fromJson(jsonLegacy);
      expect(parsedLegacy.completedByIds, ['user-alice']);
      expect(parsedLegacy.isCompletedByUser('user-alice'), isTrue);

      final jsonMulti = {
        'id': 'rem-2',
        'hivemind_id': 'hive-1',
        'title': 'Multi-member reminder',
        'due_at': now.toUtc().toIso8601String(),
        'is_completed': false,
        'completed_by_ids': ['user-alice', 'user-bob'],
        'created_at': now.toUtc().toIso8601String(),
        'updated_at': now.toUtc().toIso8601String(),
      };

      final parsedMulti = Reminder.fromJson(jsonMulti);
      expect(parsedMulti.completedByIds, ['user-alice', 'user-bob']);
      expect(parsedMulti.isCompletedByAll({'user-alice', 'user-bob'}), isTrue);
      expect(parsedMulti.isCompletedByAll({'user-alice', 'user-bob', 'user-charlie'}), isFalse);

      final serialized = parsedMulti.toJson();
      expect(serialized['completed_by_ids'], ['user-alice', 'user-bob']);
      expect(serialized['completed_by'], 'user-bob');
    });
  });
}
