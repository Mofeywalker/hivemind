// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Hivemind';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get create => 'Erstellen';

  @override
  String get join => 'Beitreten';

  @override
  String get loading => 'Wird geladen...';

  @override
  String get authSubtitlePassword =>
      'Willkommen zurück. Melde dich bei deinen Hiveminds an.';

  @override
  String get authSubtitleSignUp =>
      'Erstelle ein Konto, um Hiveminds beizutreten oder zu erstellen.';

  @override
  String get authSubtitleMagicLink =>
      'Gib deine E-Mail-Adresse ein, um einen passwortlosen Anmeldelink zu erhalten.';

  @override
  String get emailLabel => 'E-Mail';

  @override
  String get emailHint => 'name@beispiel.de';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String get passwordHint => '••••••••';

  @override
  String get emailRequired => 'E-Mail ist erforderlich';

  @override
  String get emailInvalid => 'Bitte gib eine gültige E-Mail-Adresse ein';

  @override
  String get passwordTooShort =>
      'Das Passwort muss mindestens 6 Zeichen lang sein';

  @override
  String get accountCreatedCheckEmail =>
      'Konto erstellt! Bitte überprüfe deine E-Mails zur Bestätigung.';

  @override
  String get magicLinkSent =>
      'Magic-Link gesendet! Bitte überprüfe dein E-Mail-Postfach.';

  @override
  String errorCouldNotSendMagicLink(String error) {
    return 'Magic-Link konnte nicht gesendet werden: $error';
  }

  @override
  String errorUnexpected(String error) {
    return 'Ein unerwarteter Fehler ist aufgetreten: $error';
  }

  @override
  String errorOAuth(String error) {
    return 'OAuth-Fehler: $error';
  }

  @override
  String get buttonSendMagicLink => 'Magic-Link senden';

  @override
  String get buttonCreateAccount => 'Konto erstellen';

  @override
  String get buttonSignIn => 'Anmelden';

  @override
  String get usePasswordInstead => 'Stattdessen Passwort verwenden';

  @override
  String get useMagicLink => 'Magic-Link verwenden';

  @override
  String get haveAccountSignIn => 'Bereits ein Konto? Anmelden';

  @override
  String get needAccountSignUp => 'Noch kein Konto? Registrieren';

  @override
  String get orContinueWith => 'oder fortfahren mit';

  @override
  String get google => 'Google';

  @override
  String get apple => 'Apple';

  @override
  String get accountAndSettings => 'Konto & Einstellungen';

  @override
  String get hivemindMember => 'Hivemind-Mitglied';

  @override
  String get anonymous => 'Anonym';

  @override
  String get sectionApplication => 'ANWENDUNG';

  @override
  String get version => 'Version';

  @override
  String get theme => 'Erscheinungsbild';

  @override
  String get themeDarkMode => 'Dunkelmodus';

  @override
  String get themeLightMode => 'Hellmodus';

  @override
  String get themeSystem => 'Systemstandard';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'Systemstandard';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get signOut => 'Abmelden';

  @override
  String get selectHivemind => 'Hivemind wählen';

  @override
  String get inviteMembers => 'Mitglieder einladen';

  @override
  String get account => 'Konto';

  @override
  String get noActiveHivemindTitle => 'Kein aktiver Hivemind';

  @override
  String get noActiveHivemindDescription =>
      'Erstelle eine Gruppe oder tritt mit einem Einladungscode bei, um zusammenzuarbeiten.';

  @override
  String get buttonSelectOrCreateHivemind => 'Hivemind wählen oder erstellen';

  @override
  String errorLoadingReminders(String error) {
    return 'Fehler beim Laden der Erinnerungen: $error';
  }

  @override
  String get allClearTitle => 'Alles erledigt';

  @override
  String get allClearDescription =>
      'Noch keine Erinnerungen für diesen Hivemind geplant.';

  @override
  String get buttonCreateFirstReminder => 'Erste Erinnerung erstellen';

  @override
  String get sectionToday => 'HEUTE';

  @override
  String get sectionTomorrow => 'MORGEN';

  @override
  String get sectionUpcoming => 'DEMNÄCHST';

  @override
  String get sectionRecurring => 'WIEDERKEHRENDE EREIGNISSE';

  @override
  String sectionCompleted(int count) {
    return 'ERLEDIGT ($count)';
  }

  @override
  String get newReminder => 'Neue Erinnerung';

  @override
  String get editReminder => 'Erinnerung bearbeiten';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String errorUpdatingReminder(String error) {
    return 'Fehler beim Aktualisieren der Erinnerung: $error';
  }

  @override
  String get reminderTitleHint => 'Was muss erledigt werden?';

  @override
  String get reminderNotesHint => 'Notizen oder Kontext hinzufügen (optional)';

  @override
  String get sectionDueDateAndTime => 'FÄLLIGKEIT & UHRZEIT';

  @override
  String get sectionRecurrence => 'WIEDERHOLUNG';

  @override
  String get buttonSaveReminder => 'Erinnerung speichern';

  @override
  String errorCreatingReminder(String error) {
    return 'Fehler beim Erstellen der Erinnerung: $error';
  }

  @override
  String get overdue => 'Überfällig';

  @override
  String get recurrenceDoesNotRepeat => 'Einmalig';

  @override
  String get recurrenceDaily => 'Täglich';

  @override
  String get recurrenceWeekly => 'Wöchentlich';

  @override
  String get recurrenceBiweekly => 'Alle 2 Wochen';

  @override
  String get recurrenceMonthly => 'Monatlich';

  @override
  String get recurrenceWeekdays => 'Jeden Werktag (Mo - Fr)';

  @override
  String get hiveminds => 'Hiveminds';

  @override
  String errorLoadingHiveminds(String error) {
    return 'Fehler beim Laden der Hiveminds: $error';
  }

  @override
  String get emptyHivemindsList =>
      'Du bist noch in keinem Hivemind.\nErstelle einen oder tritt unten bei.';

  @override
  String get buttonCreateNew => 'Neu erstellen';

  @override
  String get buttonJoinExisting => 'Beitreten';

  @override
  String get createHivemindTitle => 'Hivemind erstellen';

  @override
  String get groupNameLabel => 'Gruppenname';

  @override
  String get groupNameHint => 'z. B. Familie, WG, Team';

  @override
  String get descriptionOptionalLabel => 'Beschreibung (optional)';

  @override
  String get descriptionHint => 'Wofür ist dieser Hivemind?';

  @override
  String failedToCreateHivemind(String error) {
    return 'Hivemind konnte nicht erstellt werden: $error';
  }

  @override
  String get joinHivemindTitle => 'Hivemind beitreten';

  @override
  String get sixCharacterCodeLabel => '6-stelliger Code';

  @override
  String get sixCharacterCodeHint => 'z. B. 7K9X2B';

  @override
  String get scanQrCodeInstead => 'Stattdessen QR-Code scannen';

  @override
  String failedToJoinHivemind(String error) {
    return 'Konnte nicht beitreten: $error';
  }

  @override
  String inviteToHivemind(String name) {
    return 'Zu $name einladen';
  }

  @override
  String get inviteSheetSubtitle =>
      'Teile diesen QR-Code oder den 6-stelligen Code mit Personen, mit denen du zusammenarbeiten möchtest.';

  @override
  String get inviteCodeCopied =>
      'Einladungscode in die Zwischenablage kopiert!';

  @override
  String shareInviteMessage(String name, String code, String link) {
    return 'Tritt meinem Hivemind \"$name\" bei, um gemeinsame Erinnerungen zu teilen! Nutze den Code: $code oder öffne: $link';
  }

  @override
  String shareInviteSubject(String name) {
    return 'Hivemind \"$name\" beitreten';
  }

  @override
  String get shareLink => 'Link teilen';

  @override
  String get copyCode => 'Code kopieren';

  @override
  String get scanHivemindQr => 'Hivemind-QR-Code scannen';

  @override
  String joinedHivemind(String name) {
    return '„$name“ beigetreten!';
  }

  @override
  String get qrScannerGuide =>
      'Kamera auf einen Hivemind-QR-Code richten, um beizutreten';

  @override
  String selectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get deleteSelected => 'Ausgewählte löschen';

  @override
  String get selectAll => 'Alle auswählen';

  @override
  String get deselectAll => 'Auswahl aufheben';

  @override
  String get deleteCompletedConfirmTitle => 'Erledigte Aufgaben löschen';

  @override
  String deleteCompletedConfirmMessage(int count) {
    return 'Möchtest du $count erledigte Aufgaben wirklich löschen?';
  }

  @override
  String get delete => 'Löschen';

  @override
  String remindersDeleted(int count) {
    return '$count Aufgaben gelöscht';
  }

  @override
  String get cannotDeleteWaitingForMembers =>
      'Kann erst gelöscht werden, wenn alle Mitglieder abgehakt haben';

  @override
  String get completedByAll => 'Von allen abgehakt';

  @override
  String completedFraction(int completed, int total) {
    return '$completed von $total abgehakt';
  }

  @override
  String get waitingForMembers => 'Wartet auf Mitglieder';

  @override
  String get reminderIsDue => 'Erinnerung ist fällig';

  @override
  String get recurrenceCustomDays => 'Bestimmte Tage';

  @override
  String get sectionSelectWeekdays => 'WOCHENTAGE';

  @override
  String get presetWeekdaysOnly => 'Mo - Fr';

  @override
  String get presetWeekendsOnly => 'Sa - So';

  @override
  String get presetAllDays => 'Alle';

  @override
  String get everyWeekdayPrefix => 'Jeden';

  @override
  String get sectionCompletionRequirement => 'WER MUSS ERLEDIGEN?';

  @override
  String get scopeAnyone => 'Eine Person';

  @override
  String get scopeAnyoneSubtitle => 'Wer zuerst kommt';

  @override
  String get scopeAssigned => 'Zugewiesen';

  @override
  String get scopeAssignedSubtitle => 'Bestimmtes Mitglied';

  @override
  String get scopeAll => 'Alle Mitglieder';

  @override
  String get scopeAllSubtitle => 'Jeder einzeln';

  @override
  String get selectAssignee => 'Mitglied auswählen';

  @override
  String assignedToUser(String name) {
    return 'Für $name';
  }

  @override
  String get assignedToYou => 'Für dich';

  @override
  String get completedBySingle => 'Erledigt';

  @override
  String get membersTitle => 'Mitglieder';

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mitglieder',
      one: '1 Mitglied',
    );
    return '$_temp0';
  }

  @override
  String get memberRoleOwner => 'Eigentümer';

  @override
  String get memberRoleMember => 'Mitglied';

  @override
  String get memberYou => 'Du';

  @override
  String memberJoinedDate(String date) {
    return 'Beigetreten am $date';
  }

  @override
  String get inviteNewMember => 'Person einladen';

  @override
  String get noMembers => 'Keine Mitglieder gefunden';

  @override
  String viewMembersTooltip(int count) {
    return 'Mitglieder ansehen ($count)';
  }
}
