import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivemind/core/theme/app_theme.dart';
import 'package:hivemind/features/reminders/domain/reminder_model.dart';
import 'package:hivemind/features/reminders/presentation/create_reminder_sheet.dart';
import 'package:hivemind/l10n/app_localizations.dart';

void main() {
  testWidgets('CreateReminderSheet pre-fills fields when reminderToEdit is provided', (tester) async {
    final reminder = Reminder(
      id: 'rem-123',
      hivemindId: 'hive-1',
      title: 'Kaffee kaufen',
      notes: 'Ganze Bohnen',
      dueAt: DateTime(2026, 9, 21, 14, 30),
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

    // Verify Title and Notes are prefilled
    expect(find.text('Kaffee kaufen'), findsOneWidget);
    expect(find.text('Ganze Bohnen'), findsOneWidget);
    expect(find.text('Erinnerung bearbeiten'), findsOneWidget);
    expect(find.text('Änderungen speichern'), findsOneWidget);
  });
}
