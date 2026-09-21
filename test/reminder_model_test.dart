import 'package:flutter_test/flutter_test.dart';
import 'package:hivemind/features/reminders/domain/reminder_model.dart';

void main() {
  group('Reminder Model Tests', () {
    final now = DateTime(2026, 9, 20, 15, 30);

    test('isCompletedByUser with scope: all checks individual users', () {
      final reminder = Reminder(
        id: 'rem-1',
        hivemindId: 'hive-1',
        title: 'Clean kitchen',
        dueAt: now,
        completionScope: ReminderCompletionScope.all,
        completedByIds: ['user-alice', 'user-bob'],
        createdAt: now,
        updatedAt: now,
      );

      expect(reminder.isCompletedByUser('user-alice'), isTrue);
      expect(reminder.isCompletedByUser('user-bob'), isTrue);
      expect(reminder.isCompletedByUser('user-charlie'), isFalse);
    });

    test('isCompletedByUser and isFullyCompleted with scope: anyone (single person)', () {
      final incomplete = Reminder(
        id: 'rem-anyone-1',
        hivemindId: 'hive-1',
        title: 'Müll rausbringen',
        dueAt: now,
        completionScope: ReminderCompletionScope.anyone,
        completedByIds: const [],
        createdAt: now,
        updatedAt: now,
      );

      expect(incomplete.isCompletedByUser('user-alice'), isFalse);
      expect(incomplete.isCompletedByUser('user-bob'), isFalse);
      expect(incomplete.isFullyCompleted({'user-alice', 'user-bob'}), isFalse);

      final completedByAlice = incomplete.copyWith(
        isCompleted: true,
        completedByIds: ['user-alice'],
        completedBy: 'user-alice',
      );

      // Once Alice completes it, it is completed for all members!
      expect(completedByAlice.isCompletedByUser('user-alice'), isTrue);
      expect(completedByAlice.isCompletedByUser('user-bob'), isTrue);
      expect(completedByAlice.isCompletedByUser('user-charlie'), isTrue);
      expect(completedByAlice.isFullyCompleted({'user-alice', 'user-bob'}), isTrue);
    });

    test('isCompletedByUser and isFullyCompleted with scope: assigned (specific member)', () {
      final assignedToBob = Reminder(
        id: 'rem-assigned-1',
        hivemindId: 'hive-1',
        title: 'Paket abholen',
        dueAt: now,
        completionScope: ReminderCompletionScope.assigned,
        assignedTo: 'user-bob',
        completedByIds: const [],
        createdAt: now,
        updatedAt: now,
      );

      expect(assignedToBob.isCompletedByUser('user-bob'), isFalse);
      expect(assignedToBob.isFullyCompleted({'user-alice', 'user-bob'}), isFalse);

      final completedByBob = assignedToBob.copyWith(
        isCompleted: true,
        completedByIds: ['user-bob'],
        completedBy: 'user-bob',
      );

      expect(completedByBob.isCompletedByUser('user-bob'), isTrue);
      expect(completedByBob.isCompletedByUser('user-alice'), isTrue);
      expect(completedByBob.isFullyCompleted({'user-alice', 'user-bob'}), isTrue);
    });

    test('isCompletedByAll and isFullyCompleted with scope: all', () {
      final reminder = Reminder(
        id: 'rem-1',
        hivemindId: 'hive-1',
        title: 'Wahlunterlagen abschicken',
        dueAt: now,
        completionScope: ReminderCompletionScope.all,
        completedByIds: ['user-alice', 'user-bob'],
        createdAt: now,
        updatedAt: now,
      );

      // Only Alice & Bob in Hive
      expect(reminder.isCompletedByAll({'user-alice', 'user-bob'}), isTrue);
      expect(reminder.isFullyCompleted({'user-alice', 'user-bob'}), isTrue);

      // Alice, Bob & Charlie in Hive
      expect(reminder.isCompletedByAll({'user-alice', 'user-bob', 'user-charlie'}), isFalse);
      expect(reminder.isFullyCompleted({'user-alice', 'user-bob', 'user-charlie'}), isFalse);

      // Empty member set falls back to isCompleted
      expect(reminder.isCompletedByAll({}), isFalse);

      final fullyCompleted = reminder.copyWith(isCompleted: true);
      expect(fullyCompleted.isCompletedByAll({}), isTrue);
      expect(fullyCompleted.isFullyCompleted({}), isTrue);
    });

    test('JSON serialization handles completion_scope and assigned_to', () {
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
      expect(parsedLegacy.completionScope, ReminderCompletionScope.anyone);
      expect(parsedLegacy.assignedTo, isNull);
      expect(parsedLegacy.isCompletedByUser('user-alice'), isTrue);

      final jsonAssigned = {
        'id': 'rem-2',
        'hivemind_id': 'hive-1',
        'title': 'Assigned reminder',
        'due_at': now.toUtc().toIso8601String(),
        'is_completed': false,
        'completion_scope': 'assigned',
        'assigned_to': 'user-charlie',
        'completed_by_ids': ['user-charlie'],
        'created_at': now.toUtc().toIso8601String(),
        'updated_at': now.toUtc().toIso8601String(),
      };

      final parsedAssigned = Reminder.fromJson(jsonAssigned);
      expect(parsedAssigned.completionScope, ReminderCompletionScope.assigned);
      expect(parsedAssigned.assignedTo, 'user-charlie');
      expect(parsedAssigned.isFullyCompleted({'user-alice', 'user-charlie'}), isTrue);

      final serialized = parsedAssigned.toJson();
      expect(serialized['completion_scope'], 'assigned');
      expect(serialized['assigned_to'], 'user-charlie');
    });
  });
}
