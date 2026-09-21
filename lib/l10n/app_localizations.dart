import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// The application name
  ///
  /// In en, this message translates to:
  /// **'Hivemind'**
  String get appTitle;

  /// Generic cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Generic create button text
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Generic join button text
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// Generic loading state indicator
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Subtitle on login screen for password auth
  ///
  /// In en, this message translates to:
  /// **'Welcome back. Sign in to your Hiveminds.'**
  String get authSubtitlePassword;

  /// Subtitle on login screen for registration
  ///
  /// In en, this message translates to:
  /// **'Create an account to join and create Hiveminds.'**
  String get authSubtitleSignUp;

  /// Subtitle on login screen for magic link auth
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a passwordless sign-in link.'**
  String get authSubtitleMagicLink;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Email field placeholder
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get emailHint;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Password field placeholder
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get passwordHint;

  /// Validation message when email is empty
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// Validation message when email is invalid
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get emailInvalid;

  /// Validation message when password is less than 6 characters
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// Notification message when account is created
  ///
  /// In en, this message translates to:
  /// **'Account created! Please check your email to confirm.'**
  String get accountCreatedCheckEmail;

  /// Notification message when magic link is sent
  ///
  /// In en, this message translates to:
  /// **'Magic link sent! Check your email inbox.'**
  String get magicLinkSent;

  /// Error message when magic link cannot be sent
  ///
  /// In en, this message translates to:
  /// **'Could not send magic link: {error}'**
  String errorCouldNotSendMagicLink(String error);

  /// General error message
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred: {error}'**
  String errorUnexpected(String error);

  /// OAuth error message
  ///
  /// In en, this message translates to:
  /// **'OAuth error: {error}'**
  String errorOAuth(String error);

  /// Button to submit magic link auth
  ///
  /// In en, this message translates to:
  /// **'Send Magic Link'**
  String get buttonSendMagicLink;

  /// Button to register account
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get buttonCreateAccount;

  /// Button to sign into account
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get buttonSignIn;

  /// Toggle to switch from magic link to password
  ///
  /// In en, this message translates to:
  /// **'Use password instead'**
  String get usePasswordInstead;

  /// Toggle to switch from password to magic link
  ///
  /// In en, this message translates to:
  /// **'Use magic link'**
  String get useMagicLink;

  /// Toggle to switch from sign up to sign in
  ///
  /// In en, this message translates to:
  /// **'Have an account? Sign In'**
  String get haveAccountSignIn;

  /// Toggle to switch from sign in to sign up
  ///
  /// In en, this message translates to:
  /// **'Need an account? Sign Up'**
  String get needAccountSignUp;

  /// Divider text before social auth providers
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// Google provider label
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// Apple provider label
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get apple;

  /// Title of profile screen
  ///
  /// In en, this message translates to:
  /// **'Account & Settings'**
  String get accountAndSettings;

  /// Role label under user email
  ///
  /// In en, this message translates to:
  /// **'Hivemind Member'**
  String get hivemindMember;

  /// Fallback username when email is unavailable
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// Application settings section header
  ///
  /// In en, this message translates to:
  /// **'APPLICATION'**
  String get sectionApplication;

  /// App version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// App theme label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Dark theme status
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get themeDarkMode;

  /// Light theme status
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get themeLightMode;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get themeSystem;

  /// Language selector label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Option for system default language
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// German language option
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// Sign out button text
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Placeholder when no hivemind is selected
  ///
  /// In en, this message translates to:
  /// **'Select Hivemind'**
  String get selectHivemind;

  /// Tooltip for invite members button
  ///
  /// In en, this message translates to:
  /// **'Invite Members'**
  String get inviteMembers;

  /// Tooltip for profile button
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Empty state title when no hivemind is selected
  ///
  /// In en, this message translates to:
  /// **'No Active Hivemind'**
  String get noActiveHivemindTitle;

  /// Empty state description when no hivemind is selected
  ///
  /// In en, this message translates to:
  /// **'Create a group or join one with an invite code to start collaborating.'**
  String get noActiveHivemindDescription;

  /// Button to select or create a hivemind
  ///
  /// In en, this message translates to:
  /// **'Select or Create Hivemind'**
  String get buttonSelectOrCreateHivemind;

  /// Error loading reminders
  ///
  /// In en, this message translates to:
  /// **'Error loading reminders: {error}'**
  String errorLoadingReminders(String error);

  /// Title when there are no reminders
  ///
  /// In en, this message translates to:
  /// **'All Clear'**
  String get allClearTitle;

  /// Description when there are no reminders
  ///
  /// In en, this message translates to:
  /// **'No reminders scheduled for this Hivemind yet.'**
  String get allClearDescription;

  /// Button to create the first reminder
  ///
  /// In en, this message translates to:
  /// **'Create First Reminder'**
  String get buttonCreateFirstReminder;

  /// Timeline section for today
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get sectionToday;

  /// Timeline section for tomorrow
  ///
  /// In en, this message translates to:
  /// **'TOMORROW'**
  String get sectionTomorrow;

  /// Timeline section for upcoming
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get sectionUpcoming;

  /// Timeline section for recurring events
  ///
  /// In en, this message translates to:
  /// **'RECURRING EVENTS'**
  String get sectionRecurring;

  /// Timeline section for completed reminders
  ///
  /// In en, this message translates to:
  /// **'COMPLETED ({count})'**
  String sectionCompleted(int count);

  /// Title for new reminder creation
  ///
  /// In en, this message translates to:
  /// **'New Reminder'**
  String get newReminder;

  /// Title for edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'Edit Reminder'**
  String get editReminder;

  /// Button to save reminder edits
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Error message when updating reminder fails
  ///
  /// In en, this message translates to:
  /// **'Error updating reminder: {error}'**
  String errorUpdatingReminder(String error);

  /// Placeholder for reminder title input
  ///
  /// In en, this message translates to:
  /// **'What needs to be done?'**
  String get reminderTitleHint;

  /// Placeholder for reminder notes input
  ///
  /// In en, this message translates to:
  /// **'Add notes or context (optional)'**
  String get reminderNotesHint;

  /// Section header for due date and time
  ///
  /// In en, this message translates to:
  /// **'DUE DATE & TIME'**
  String get sectionDueDateAndTime;

  /// Section header for recurrence options
  ///
  /// In en, this message translates to:
  /// **'RECURRENCE'**
  String get sectionRecurrence;

  /// Button to save a new reminder
  ///
  /// In en, this message translates to:
  /// **'Save Reminder'**
  String get buttonSaveReminder;

  /// Error message when creating reminder fails
  ///
  /// In en, this message translates to:
  /// **'Error creating reminder: {error}'**
  String errorCreatingReminder(String error);

  /// Label for overdue reminders
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// Recurrence preset title: none
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get recurrenceDoesNotRepeat;

  /// Recurrence preset title: daily
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get recurrenceDaily;

  /// Recurrence preset title: weekly
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get recurrenceWeekly;

  /// Recurrence preset title: biweekly
  ///
  /// In en, this message translates to:
  /// **'Every other week'**
  String get recurrenceBiweekly;

  /// Recurrence preset title: monthly
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get recurrenceMonthly;

  /// Recurrence preset title: weekdays
  ///
  /// In en, this message translates to:
  /// **'Every weekday (Mon - Fri)'**
  String get recurrenceWeekdays;

  /// Title of hiveminds switcher sheet
  ///
  /// In en, this message translates to:
  /// **'Hiveminds'**
  String get hiveminds;

  /// Error loading hiveminds
  ///
  /// In en, this message translates to:
  /// **'Error loading Hiveminds: {error}'**
  String errorLoadingHiveminds(String error);

  /// Empty state text in hiveminds switcher
  ///
  /// In en, this message translates to:
  /// **'You are not in any Hiveminds yet.\nCreate or join one below.'**
  String get emptyHivemindsList;

  /// Button to create new hivemind
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get buttonCreateNew;

  /// Button to join existing hivemind
  ///
  /// In en, this message translates to:
  /// **'Join Existing'**
  String get buttonJoinExisting;

  /// Title of create hivemind dialog
  ///
  /// In en, this message translates to:
  /// **'Create Hivemind'**
  String get createHivemindTitle;

  /// Label for hivemind group name field
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupNameLabel;

  /// Hint for hivemind group name field
  ///
  /// In en, this message translates to:
  /// **'e.g. Family, Roommates, Team'**
  String get groupNameHint;

  /// Label for optional description field
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptionalLabel;

  /// Hint for hivemind description field
  ///
  /// In en, this message translates to:
  /// **'What is this Hivemind for?'**
  String get descriptionHint;

  /// Error creating hivemind
  ///
  /// In en, this message translates to:
  /// **'Failed to create Hivemind: {error}'**
  String failedToCreateHivemind(String error);

  /// Title of join hivemind dialog
  ///
  /// In en, this message translates to:
  /// **'Join Hivemind'**
  String get joinHivemindTitle;

  /// Label for join code field
  ///
  /// In en, this message translates to:
  /// **'6-Character Code'**
  String get sixCharacterCodeLabel;

  /// Hint for join code field
  ///
  /// In en, this message translates to:
  /// **'e.g. 7K9X2B'**
  String get sixCharacterCodeHint;

  /// Button to open QR scanner from join dialog
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code Instead'**
  String get scanQrCodeInstead;

  /// Error joining hivemind
  ///
  /// In en, this message translates to:
  /// **'Failed to join: {error}'**
  String failedToJoinHivemind(String error);

  /// Title of invite sheet
  ///
  /// In en, this message translates to:
  /// **'Invite to {name}'**
  String inviteToHivemind(String name);

  /// Subtitle of invite sheet
  ///
  /// In en, this message translates to:
  /// **'Share this QR code or 6-digit code with people you want to collaborate with.'**
  String get inviteSheetSubtitle;

  /// Snackbar message when invite code is copied
  ///
  /// In en, this message translates to:
  /// **'Invite code copied to clipboard!'**
  String get inviteCodeCopied;

  /// Share text for hivemind invite
  ///
  /// In en, this message translates to:
  /// **'Join my Hivemind \"{name}\" to share reminders! Use code: {code} or open: {link}'**
  String shareInviteMessage(String name, String code, String link);

  /// Share subject line
  ///
  /// In en, this message translates to:
  /// **'Join Hivemind \"{name}\"'**
  String shareInviteSubject(String name);

  /// Button to share link
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get shareLink;

  /// Button to copy invite code
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get copyCode;

  /// Title of QR scanner screen
  ///
  /// In en, this message translates to:
  /// **'Scan Hivemind QR'**
  String get scanHivemindQr;

  /// Snackbar message when successfully joined a hivemind
  ///
  /// In en, this message translates to:
  /// **'Joined \"{name}\"!'**
  String joinedHivemind(String name);

  /// Helper instruction on QR scanner view
  ///
  /// In en, this message translates to:
  /// **'Point camera at a Hivemind QR code to join'**
  String get qrScannerGuide;

  /// Number of items selected in multi-selection mode
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// Tooltip and action to delete selected items
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get deleteSelected;

  /// Button to select all eligible items
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// Button to deselect all selected items
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// Title of confirmation dialog for deleting completed tasks
  ///
  /// In en, this message translates to:
  /// **'Delete completed reminders'**
  String get deleteCompletedConfirmTitle;

  /// Message in confirmation dialog for deleting completed tasks
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} completed reminders?'**
  String deleteCompletedConfirmMessage(int count);

  /// Delete action button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Snackbar message after reminders are deleted
  ///
  /// In en, this message translates to:
  /// **'{count} reminders deleted'**
  String remindersDeleted(int count);

  /// Warning shown when a completed task cannot be deleted because not all members have checked it off
  ///
  /// In en, this message translates to:
  /// **'Can only be deleted once all members have checked it off'**
  String get cannotDeleteWaitingForMembers;

  /// Status badge when all hive members checked off a task
  ///
  /// In en, this message translates to:
  /// **'Completed by all'**
  String get completedByAll;

  /// Status badge showing how many members checked off a task
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} checked off'**
  String completedFraction(int completed, int total);

  /// Status badge when task is waiting for other hive members
  ///
  /// In en, this message translates to:
  /// **'Waiting for members'**
  String get waitingForMembers;

  /// Default notification body when a reminder has no notes
  ///
  /// In en, this message translates to:
  /// **'Reminder is due'**
  String get reminderIsDue;

  /// Recurrence chip for specific weekdays
  ///
  /// In en, this message translates to:
  /// **'Specific days'**
  String get recurrenceCustomDays;

  /// Section header for weekday picker
  ///
  /// In en, this message translates to:
  /// **'DAYS OF THE WEEK'**
  String get sectionSelectWeekdays;

  /// Quick select button for Monday to Friday
  ///
  /// In en, this message translates to:
  /// **'Mon - Fri'**
  String get presetWeekdaysOnly;

  /// Quick select button for Saturday and Sunday
  ///
  /// In en, this message translates to:
  /// **'Sat - Sun'**
  String get presetWeekendsOnly;

  /// Quick select button for all days
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get presetAllDays;

  /// Prefix for recurring days like Every Mon, Wed
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get everyWeekdayPrefix;

  /// Section header for who needs to complete the reminder
  ///
  /// In en, this message translates to:
  /// **'COMPLETION'**
  String get sectionCompletionRequirement;

  /// Label for single person / anyone completion
  ///
  /// In en, this message translates to:
  /// **'One person'**
  String get scopeAnyone;

  /// Subtitle for single person completion
  ///
  /// In en, this message translates to:
  /// **'First to complete'**
  String get scopeAnyoneSubtitle;

  /// Label for assigned member completion
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get scopeAssigned;

  /// Subtitle for assigned member completion
  ///
  /// In en, this message translates to:
  /// **'Specific member'**
  String get scopeAssignedSubtitle;

  /// Label for everyone individually completion
  ///
  /// In en, this message translates to:
  /// **'All members'**
  String get scopeAll;

  /// Subtitle for everyone individually completion
  ///
  /// In en, this message translates to:
  /// **'Everyone individually'**
  String get scopeAllSubtitle;

  /// Prompt to select member to assign
  ///
  /// In en, this message translates to:
  /// **'Select member'**
  String get selectAssignee;

  /// Badge showing reminder is assigned to a specific user
  ///
  /// In en, this message translates to:
  /// **'For {name}'**
  String assignedToUser(String name);

  /// Badge showing reminder is assigned to current user
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get assignedToYou;

  /// Badge showing single-person task is completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedBySingle;

  /// Title for the members sheet
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersTitle;

  /// Number of members in the hivemind
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String membersCount(int count);

  /// Role badge for hivemind owner
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get memberRoleOwner;

  /// Role badge for hivemind member
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get memberRoleMember;

  /// Badge marking the current user
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get memberYou;

  /// Subtitle showing member joined date
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String memberJoinedDate(String date);

  /// Button label to invite a person to the hivemind
  ///
  /// In en, this message translates to:
  /// **'Invite person'**
  String get inviteNewMember;

  /// Empty state when hivemind has no members
  ///
  /// In en, this message translates to:
  /// **'No members found'**
  String get noMembers;

  /// Tooltip for member avatar pill
  ///
  /// In en, this message translates to:
  /// **'View members ({count})'**
  String viewMembersTooltip(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
