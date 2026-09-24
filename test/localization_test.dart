import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivemind/core/providers/locale_provider.dart';
import 'package:hivemind/core/utils/recurrence_util.dart';
import 'package:hivemind/l10n/app_localizations.dart';
import 'package:hivemind/l10n/app_localizations_de.dart';
import 'package:hivemind/l10n/app_localizations_en.dart';

void main() {
  group('Localization Tests', () {
    test('ARB keys parity between English and German', () {
      final enFile = File('lib/l10n/app_en.arb');
      final deFile = File('lib/l10n/app_de.arb');

      expect(enFile.existsSync(), isTrue);
      expect(deFile.existsSync(), isTrue);

      final enJson =
          jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      final deJson =
          jsonDecode(deFile.readAsStringSync()) as Map<String, dynamic>;

      final enKeys = enJson.keys.where((k) => !k.startsWith('@')).toSet();
      final deKeys = deJson.keys.where((k) => !k.startsWith('@')).toSet();

      final missingInDe = enKeys.difference(deKeys);
      final extraInDe = deKeys.difference(enKeys);

      expect(
        missingInDe,
        isEmpty,
        reason: 'Keys missing in German translations: $missingInDe',
      );
      expect(
        extraInDe,
        isEmpty,
        reason: 'Extra keys found in German translations: $extraInDe',
      );
    });

    test('English and German AppLocalizations translations', () {
      final l10nEn = AppLocalizationsEn();
      final l10nDe = AppLocalizationsDe();

      // Common actions
      expect(l10nEn.save, 'Save');
      expect(l10nDe.save, 'Speichern');
      expect(l10nEn.cancel, 'Cancel');
      expect(l10nDe.cancel, 'Abbrechen');
      expect(l10nEn.create, 'Create');
      expect(l10nDe.create, 'Erstellen');
      expect(l10nEn.join, 'Join');
      expect(l10nDe.join, 'Beitreten');

      // Timeline sections
      expect(l10nEn.sectionToday, 'TODAY');
      expect(l10nDe.sectionToday, 'HEUTE');
      expect(l10nEn.sectionTomorrow, 'TOMORROW');
      expect(l10nDe.sectionTomorrow, 'MORGEN');
      expect(l10nEn.sectionUpcoming, 'UPCOMING');
      expect(l10nDe.sectionUpcoming, 'DEMNÄCHST');
      expect(l10nEn.sectionRecurring, 'RECURRING EVENTS');
      expect(l10nDe.sectionRecurring, 'WIEDERKEHRENDE EREIGNISSE');
      expect(l10nEn.sectionCompleted(3), 'COMPLETED (3)');
      expect(l10nDe.sectionCompleted(3), 'ERLEDIGT (3)');

      // Reminders & Recurrence
      expect(l10nEn.newReminder, 'New Reminder');
      expect(l10nDe.newReminder, 'Neue Erinnerung');
      expect(l10nEn.overdue, 'Overdue');
      expect(l10nDe.overdue, 'Überfällig');
      expect(l10nEn.reminderIsDue, 'Reminder is due');
      expect(l10nDe.reminderIsDue, 'Erinnerung ist fällig');

      // Settings
      expect(l10nEn.accountAndSettings, 'Account & Settings');
      expect(l10nDe.accountAndSettings, 'Konto & Einstellungen');
      expect(l10nEn.theme, 'Theme');
      expect(l10nDe.theme, 'Erscheinungsbild');
      expect(l10nEn.themeSystem, 'System default');
      expect(l10nDe.themeSystem, 'Systemstandard');
      expect(l10nEn.themeLightMode, 'Light Mode');
      expect(l10nDe.themeLightMode, 'Hellmodus');
      expect(l10nEn.themeDarkMode, 'Dark Mode');
      expect(l10nDe.themeDarkMode, 'Dunkelmodus');
      expect(l10nEn.language, 'Language');
      expect(l10nDe.language, 'Sprache');
      expect(l10nEn.languageGerman, 'Deutsch');
      expect(l10nDe.languageGerman, 'Deutsch');
    });

    test('RecurrenceUtil localized preset titles', () {
      final l10nDe = AppLocalizationsDe();
      final l10nEn = AppLocalizationsEn();

      expect(
        RecurrenceUtil.getReadablePresetTitle(RecurrencePreset.daily, l10nDe),
        'Täglich',
      );
      expect(
        RecurrenceUtil.getReadablePresetTitle(RecurrencePreset.daily, l10nEn),
        'Every day',
      );
      expect(
        RecurrenceUtil.getReadablePresetTitle(RecurrencePreset.weekly, l10nDe),
        'Wöchentlich',
      );
      expect(
        RecurrenceUtil.getReadablePresetTitle(
          RecurrencePreset.customDays,
          l10nDe,
        ),
        'Bestimmte Tage',
      );
      expect(
        RecurrenceUtil.getReadablePresetTitle(
          RecurrencePreset.customDays,
          l10nEn,
        ),
        'Specific days',
      );
      expect(
        RecurrenceUtil.getReadablePresetTitle(
          RecurrencePreset.biweekly,
          l10nDe,
        ),
        'Alle 2 Wochen',
      );
      expect(
        RecurrenceUtil.getReadablePresetTitle(RecurrencePreset.monthly, l10nDe),
        'Monatlich',
      );
      expect(
        RecurrenceUtil.getReadablePresetTitle(
          RecurrencePreset.weekdays,
          l10nDe,
        ),
        'Jeden Werktag (Mo - Fr)',
      );
      expect(
        RecurrenceUtil.getReadablePresetTitle(RecurrencePreset.none, l10nDe),
        'Einmalig',
      );
    });

    test('LocaleNotifier switching behavior', () {
      final notifier = LocaleNotifier();
      expect(notifier.state, isNull);
      expect(notifier.currentLanguage, AppLanguage.system);

      notifier.setLanguage(AppLanguage.german);
      expect(notifier.state, const Locale('de'));
      expect(notifier.currentLanguage, AppLanguage.german);

      notifier.setLanguage(AppLanguage.english);
      expect(notifier.state, const Locale('en'));
      expect(notifier.currentLanguage, AppLanguage.english);

      notifier.setLanguage(AppLanguage.system);
      expect(notifier.state, isNull);
      expect(notifier.currentLanguage, AppLanguage.system);
    });

    testWidgets('Renders localized text inside Widget tree for German', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Scaffold(
                body: Column(
                  children: [
                    Text(l10n.newReminder),
                    Text(l10n.sectionToday),
                    Text(l10n.accountAndSettings),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Neue Erinnerung'), findsOneWidget);
      expect(find.text('HEUTE'), findsOneWidget);
      expect(find.text('Konto & Einstellungen'), findsOneWidget);
    });
  });
}
