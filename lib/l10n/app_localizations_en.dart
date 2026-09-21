// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Hivemind';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get create => 'Create';

  @override
  String get join => 'Join';

  @override
  String get loading => 'Loading...';

  @override
  String get authSubtitlePassword => 'Welcome back. Sign in to your Hiveminds.';

  @override
  String get authSubtitleSignUp =>
      'Create an account to join and create Hiveminds.';

  @override
  String get authSubtitleMagicLink =>
      'Enter your email to receive a passwordless sign-in link.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => '••••••••';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get accountCreatedCheckEmail =>
      'Account created! Please check your email to confirm.';

  @override
  String get magicLinkSent => 'Magic link sent! Check your email inbox.';

  @override
  String errorCouldNotSendMagicLink(String error) {
    return 'Could not send magic link: $error';
  }

  @override
  String errorUnexpected(String error) {
    return 'An unexpected error occurred: $error';
  }

  @override
  String errorOAuth(String error) {
    return 'OAuth error: $error';
  }

  @override
  String get buttonSendMagicLink => 'Send Magic Link';

  @override
  String get buttonCreateAccount => 'Create Account';

  @override
  String get buttonSignIn => 'Sign In';

  @override
  String get usePasswordInstead => 'Use password instead';

  @override
  String get useMagicLink => 'Use magic link';

  @override
  String get haveAccountSignIn => 'Have an account? Sign In';

  @override
  String get needAccountSignUp => 'Need an account? Sign Up';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get google => 'Google';

  @override
  String get apple => 'Apple';

  @override
  String get accountAndSettings => 'Account & Settings';

  @override
  String get hivemindMember => 'Hivemind Member';

  @override
  String get anonymous => 'Anonymous';

  @override
  String get sectionApplication => 'APPLICATION';

  @override
  String get version => 'Version';

  @override
  String get theme => 'Theme';

  @override
  String get themeDarkMode => 'Dark Mode';

  @override
  String get themeLightMode => 'Light Mode';

  @override
  String get themeSystem => 'System default';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get signOut => 'Sign Out';

  @override
  String get selectHivemind => 'Select Hivemind';

  @override
  String get inviteMembers => 'Invite Members';

  @override
  String get account => 'Account';

  @override
  String get noActiveHivemindTitle => 'No Active Hivemind';

  @override
  String get noActiveHivemindDescription =>
      'Create a group or join one with an invite code to start collaborating.';

  @override
  String get buttonSelectOrCreateHivemind => 'Select or Create Hivemind';

  @override
  String errorLoadingReminders(String error) {
    return 'Error loading reminders: $error';
  }

  @override
  String get allClearTitle => 'All Clear';

  @override
  String get allClearDescription =>
      'No reminders scheduled for this Hivemind yet.';

  @override
  String get buttonCreateFirstReminder => 'Create First Reminder';

  @override
  String get sectionToday => 'TODAY';

  @override
  String get sectionTomorrow => 'TOMORROW';

  @override
  String get sectionUpcoming => 'UPCOMING';

  @override
  String get sectionRecurring => 'RECURRING EVENTS';

  @override
  String sectionCompleted(int count) {
    return 'COMPLETED ($count)';
  }

  @override
  String get newReminder => 'New Reminder';

  @override
  String get editReminder => 'Edit Reminder';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String errorUpdatingReminder(String error) {
    return 'Error updating reminder: $error';
  }

  @override
  String get reminderTitleHint => 'What needs to be done?';

  @override
  String get reminderNotesHint => 'Add notes or context (optional)';

  @override
  String get sectionDueDateAndTime => 'DUE DATE & TIME';

  @override
  String get sectionRecurrence => 'RECURRENCE';

  @override
  String get buttonSaveReminder => 'Save Reminder';

  @override
  String errorCreatingReminder(String error) {
    return 'Error creating reminder: $error';
  }

  @override
  String get overdue => 'Overdue';

  @override
  String get recurrenceDoesNotRepeat => 'Does not repeat';

  @override
  String get recurrenceDaily => 'Every day';

  @override
  String get recurrenceWeekly => 'Every week';

  @override
  String get recurrenceBiweekly => 'Every other week';

  @override
  String get recurrenceMonthly => 'Every month';

  @override
  String get recurrenceWeekdays => 'Every weekday (Mon - Fri)';

  @override
  String get hiveminds => 'Hiveminds';

  @override
  String errorLoadingHiveminds(String error) {
    return 'Error loading Hiveminds: $error';
  }

  @override
  String get emptyHivemindsList =>
      'You are not in any Hiveminds yet.\nCreate or join one below.';

  @override
  String get buttonCreateNew => 'Create New';

  @override
  String get buttonJoinExisting => 'Join Existing';

  @override
  String get createHivemindTitle => 'Create Hivemind';

  @override
  String get groupNameLabel => 'Group Name';

  @override
  String get groupNameHint => 'e.g. Family, Roommates, Team';

  @override
  String get descriptionOptionalLabel => 'Description (optional)';

  @override
  String get descriptionHint => 'What is this Hivemind for?';

  @override
  String failedToCreateHivemind(String error) {
    return 'Failed to create Hivemind: $error';
  }

  @override
  String get joinHivemindTitle => 'Join Hivemind';

  @override
  String get sixCharacterCodeLabel => '6-Character Code';

  @override
  String get sixCharacterCodeHint => 'e.g. 7K9X2B';

  @override
  String get scanQrCodeInstead => 'Scan QR Code Instead';

  @override
  String failedToJoinHivemind(String error) {
    return 'Failed to join: $error';
  }

  @override
  String inviteToHivemind(String name) {
    return 'Invite to $name';
  }

  @override
  String get inviteSheetSubtitle =>
      'Share this QR code or 6-digit code with people you want to collaborate with.';

  @override
  String get inviteCodeCopied => 'Invite code copied to clipboard!';

  @override
  String shareInviteMessage(String name, String code, String link) {
    return 'Join my Hivemind \"$name\" to share reminders! Use code: $code or open: $link';
  }

  @override
  String shareInviteSubject(String name) {
    return 'Join Hivemind \"$name\"';
  }

  @override
  String get shareLink => 'Share Link';

  @override
  String get copyCode => 'Copy Code';

  @override
  String get scanHivemindQr => 'Scan Hivemind QR';

  @override
  String joinedHivemind(String name) {
    return 'Joined \"$name\"!';
  }

  @override
  String get qrScannerGuide => 'Point camera at a Hivemind QR code to join';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get deleteSelected => 'Delete selected';

  @override
  String get selectAll => 'Select all';

  @override
  String get deselectAll => 'Deselect all';

  @override
  String get deleteCompletedConfirmTitle => 'Delete completed reminders';

  @override
  String deleteCompletedConfirmMessage(int count) {
    return 'Are you sure you want to delete $count completed reminders?';
  }

  @override
  String get delete => 'Delete';

  @override
  String remindersDeleted(int count) {
    return '$count reminders deleted';
  }

  @override
  String get cannotDeleteWaitingForMembers =>
      'Can only be deleted once all members have checked it off';

  @override
  String get completedByAll => 'Completed by all';

  @override
  String completedFraction(int completed, int total) {
    return '$completed of $total checked off';
  }

  @override
  String get waitingForMembers => 'Waiting for members';

  @override
  String get reminderIsDue => 'Reminder is due';

  @override
  String get recurrenceCustomDays => 'Specific days';

  @override
  String get sectionSelectWeekdays => 'DAYS OF THE WEEK';

  @override
  String get presetWeekdaysOnly => 'Mon - Fri';

  @override
  String get presetWeekendsOnly => 'Sat - Sun';

  @override
  String get presetAllDays => 'All';

  @override
  String get everyWeekdayPrefix => 'Every';

  @override
  String get sectionCompletionRequirement => 'COMPLETION';

  @override
  String get scopeAnyone => 'One person';

  @override
  String get scopeAnyoneSubtitle => 'First to complete';

  @override
  String get scopeAssigned => 'Assigned';

  @override
  String get scopeAssignedSubtitle => 'Specific member';

  @override
  String get scopeAll => 'All members';

  @override
  String get scopeAllSubtitle => 'Everyone individually';

  @override
  String get selectAssignee => 'Select member';

  @override
  String assignedToUser(String name) {
    return 'For $name';
  }

  @override
  String get assignedToYou => 'For you';

  @override
  String get completedBySingle => 'Completed';
}
