import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivemind/core/theme/app_theme.dart';
import 'package:hivemind/features/reminders/domain/reminder_model.dart';
import 'package:hivemind/features/reminders/presentation/create_reminder_sheet.dart';
import 'package:hivemind/l10n/app_localizations.dart';

void main() {
  group('Custom Weekdays Picker Tests in CreateReminderSheet', () {
    testWidgets('Tapping Bestimmte Tage displays weekday buttons and quick selectors', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('de'),
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: CreateReminderSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially, weekday section is not visible because preset is 'Einmalig'
      expect(find.text('WOCHENTAGE'), findsNothing);

      // Tap 'Bestimmte Tage' choice chip
      await tester.tap(find.text('Bestimmte Tage'));
      await tester.pumpAndSettle();

      // Now weekday section and quick buttons appear
      expect(find.text('WOCHENTAGE'), findsOneWidget);
      expect(find.text('Mo - Fr'), findsOneWidget);
      expect(find.text('Sa - So'), findsOneWidget);
      expect(find.text('Alle'), findsOneWidget);

      // Verify day labels are present
      expect(find.text('Mo'), findsOneWidget);
      expect(find.text('Di'), findsOneWidget);
      expect(find.text('Mi'), findsOneWidget);
      expect(find.text('Do'), findsOneWidget);
      expect(find.text('Fr'), findsOneWidget);
      expect(find.text('Sa'), findsOneWidget);
      expect(find.text('So'), findsOneWidget);
    });

    testWidgets('Pre-fills custom weekdays when editing an existing multi-day reminder', (tester) async {
      final reminder = Reminder(
        id: 'rem-recurring-1',
        hivemindId: 'hive-1',
        title: 'Müll rausbringen',
        notes: 'Biotonne & Restmüll',
        dueAt: DateTime(2026, 9, 24, 18, 0),
        rrule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,TH',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        completedByIds: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('de'),
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: CreateReminderSheet(reminderToEdit: reminder),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should automatically show weekday section
      expect(find.text('WOCHENTAGE'), findsOneWidget);
      expect(find.text('Erinnerung bearbeiten'), findsOneWidget);

      // Semantics should indicate Monday and Thursday are selected
      expect(find.bySemanticsLabel(RegExp(r'Montag, selected')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Donnerstag, selected')), findsOneWidget);
    });

    testWidgets('Quick select Sa - So selects weekend days', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('de'),
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: CreateReminderSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'Bestimmte Tage'
      await tester.tap(find.text('Bestimmte Tage'));
      await tester.pumpAndSettle();

      // Tap 'Sa - So' quick select button
      await tester.tap(find.text('Sa - So'));
      await tester.pumpAndSettle();

      // Samstag and Sonntag should now be selected
      expect(find.bySemanticsLabel(RegExp(r'Samstag, selected')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Sonntag, selected')), findsOneWidget);
    });
  });
}
