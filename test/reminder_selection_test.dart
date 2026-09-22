import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivemind/features/reminders/domain/reminder_model.dart';
import 'package:hivemind/features/reminders/presentation/reminder_card.dart';
import 'package:hivemind/l10n/app_localizations.dart';

void main() {
  group('ReminderCard Selection & Member Verification Widget Tests', () {
    final now = DateTime(2026, 9, 20, 10, 0);

    final completedByAllReminder = Reminder(
      id: 'rem-1',
      hivemindId: 'hive-1',
      title: 'Küche putzen',
      dueAt: now,
      completionScope: ReminderCompletionScope.all,
      isCompleted: true,
      completedByIds: ['user-1', 'user-2'],
      createdAt: now,
      updatedAt: now,
    );

    final partiallyCompletedReminder = Reminder(
      id: 'rem-2',
      hivemindId: 'hive-1',
      title: 'Müll runterbringen',
      dueAt: now,
      completionScope: ReminderCompletionScope.all,
      isCompleted: false,
      completedByIds: ['user-1'],
      createdAt: now,
      updatedAt: now,
    );

    Widget createTestableWidget(Widget child) {
      return ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('de'),
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets(
      'Displays "Von allen abgehakt" when task is completed by all members',
      (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            ReminderCard(
              reminder: completedByAllReminder,
              canBeDeleted: true,
              completedCount: 2,
              totalMembersCount: 2,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Küche putzen'), findsOneWidget);
        expect(find.text('Von allen abgehakt'), findsOneWidget);
      },
    );

    testWidgets(
      'Displays "1 von 2 abgehakt • Wartet auf Mitglieder" when waiting for members',
      (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            ReminderCard(
              reminder: partiallyCompletedReminder,
              canBeDeleted: false,
              completedCount: 1,
              totalMembersCount: 2,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Müll runterbringen'), findsOneWidget);
        expect(
          find.text('1 von 2 abgehakt • Wartet auf Mitglieder'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Long press triggers onLongPress callback', (tester) async {
      bool longPressed = false;

      await tester.pumpWidget(
        createTestableWidget(
          ReminderCard(
            reminder: completedByAllReminder,
            canBeDeleted: true,
            completedCount: 2,
            totalMembersCount: 2,
            onLongPress: () {
              longPressed = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Küche putzen'));
      await tester.pumpAndSettle();

      expect(longPressed, isTrue);
    });

    testWidgets(
      'In selection mode: Tapping an eligible task toggles selection',
      (tester) async {
        bool? selectedValue;

        await tester.pumpWidget(
          createTestableWidget(
            ReminderCard(
              reminder: completedByAllReminder,
              isSelectionMode: true,
              isSelected: false,
              canBeDeleted: true,
              completedCount: 2,
              totalMembersCount: 2,
              onSelectedChanged: (val) {
                selectedValue = val;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Küche putzen'));
        await tester.pumpAndSettle();

        expect(selectedValue, isTrue);
      },
    );

    testWidgets(
      'In selection mode: Tapping an ineligible task shows snackbar and blocks selection',
      (tester) async {
        bool? selectedValue;

        await tester.pumpWidget(
          createTestableWidget(
            ReminderCard(
              reminder: partiallyCompletedReminder,
              isSelectionMode: true,
              isSelected: false,
              canBeDeleted: false,
              completedCount: 1,
              totalMembersCount: 2,
              onSelectedChanged: (val) {
                selectedValue = val;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Müll runterbringen'));
        await tester.pumpAndSettle();

        // Selection was not toggled
        expect(selectedValue, isNull);
        // SnackBar explanation is shown
        expect(
          find.text(
            'Kann erst gelöscht werden, wenn alle Mitglieder abgehakt haben',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
