import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'AASHANet AI'**
  String get appName;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @record.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get record;

  /// No description provided for @dataShowing.
  ///
  /// In en, this message translates to:
  /// **'Data Showing'**
  String get dataShowing;

  /// No description provided for @typingOption.
  ///
  /// In en, this message translates to:
  /// **'Typing Option'**
  String get typingOption;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select your default language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @kannada.
  ///
  /// In en, this message translates to:
  /// **'Kannada'**
  String get kannada;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get usernameHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI-Powered Voice-Based Health Assistant'**
  String get loginSubtitle;

  /// No description provided for @loginSupportText.
  ///
  /// In en, this message translates to:
  /// **'Supporting ASHA workers in rural healthcare'**
  String get loginSupportText;

  /// No description provided for @enterUsernamePassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter username and password'**
  String get enterUsernamePassword;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @couldNotConnectServer.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to server'**
  String get couldNotConnectServer;

  /// No description provided for @recordHealthVisit.
  ///
  /// In en, this message translates to:
  /// **'Record Health Visit'**
  String get recordHealthVisit;

  /// No description provided for @captureHealthInformation.
  ///
  /// In en, this message translates to:
  /// **'Capture Health Information'**
  String get captureHealthInformation;

  /// No description provided for @captureHealthDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter health information naturally. AASHANet AI will analyze it and create a health record.'**
  String get captureHealthDescription;

  /// No description provided for @tapToRecordVoice.
  ///
  /// In en, this message translates to:
  /// **'Tap to record voice'**
  String get tapToRecordVoice;

  /// No description provided for @tapToStopRecording.
  ///
  /// In en, this message translates to:
  /// **'Tap to stop recording'**
  String get tapToStopRecording;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get recording;

  /// No description provided for @recordingSaved.
  ///
  /// In en, this message translates to:
  /// **'Recording saved'**
  String get recordingSaved;

  /// No description provided for @recordingStarted.
  ///
  /// In en, this message translates to:
  /// **'Recording started'**
  String get recordingStarted;

  /// No description provided for @enterRecordByTyping.
  ///
  /// In en, this message translates to:
  /// **'Enter record by typing'**
  String get enterRecordByTyping;

  /// No description provided for @processRecord.
  ///
  /// In en, this message translates to:
  /// **'Process Record'**
  String get processRecord;

  /// No description provided for @analyzingRecord.
  ///
  /// In en, this message translates to:
  /// **'Analyzing record...'**
  String get analyzingRecord;

  /// No description provided for @orText.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orText;

  /// No description provided for @recordExampleHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Ramesh is 42 years old and has cough and fever for three days'**
  String get recordExampleHint;

  /// No description provided for @microphonePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required'**
  String get microphonePermissionRequired;

  /// No description provided for @couldNotRecordVoice.
  ///
  /// In en, this message translates to:
  /// **'Could not record voice'**
  String get couldNotRecordVoice;

  /// No description provided for @couldNotSaveRecordLocally.
  ///
  /// In en, this message translates to:
  /// **'Could not save record locally'**
  String get couldNotSaveRecordLocally;

  /// No description provided for @pleaseEnterOrRecordHealthInfo.
  ///
  /// In en, this message translates to:
  /// **'Please enter or record the health information'**
  String get pleaseEnterOrRecordHealthInfo;

  /// No description provided for @recordSavedLocallyOffline.
  ///
  /// In en, this message translates to:
  /// **'Record saved on this device, but it could not be sent to the server. Please try again later.'**
  String get recordSavedLocallyOffline;

  /// No description provided for @reviewExtractedInformation.
  ///
  /// In en, this message translates to:
  /// **'Review Extracted Information'**
  String get reviewExtractedInformation;

  /// No description provided for @localHealthRecords.
  ///
  /// In en, this message translates to:
  /// **'Local Health Records'**
  String get localHealthRecords;

  /// No description provided for @couldNotLoadRecords.
  ///
  /// In en, this message translates to:
  /// **'Could not load records'**
  String get couldNotLoadRecords;

  /// No description provided for @noLocalHealthRecords.
  ///
  /// In en, this message translates to:
  /// **'No local health records yet.'**
  String get noLocalHealthRecords;

  /// No description provided for @workerLabel.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get workerLabel;

  /// No description provided for @notAssignedYet.
  ///
  /// In en, this message translates to:
  /// **'Not assigned yet'**
  String get notAssignedYet;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncing;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @statusSavedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved offline'**
  String get statusSavedOffline;

  /// No description provided for @statusPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get statusPendingSync;

  /// No description provided for @statusUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get statusUploading;

  /// No description provided for @statusSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get statusSynced;

  /// No description provided for @statusSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed – will retry'**
  String get statusSyncFailed;

  /// No description provided for @statusConflict.
  ///
  /// In en, this message translates to:
  /// **'Needs your decision'**
  String get statusConflict;

  /// No description provided for @aiPending.
  ///
  /// In en, this message translates to:
  /// **'AI processing pending (needs internet)'**
  String get aiPending;

  /// No description provided for @aiCompleted.
  ///
  /// In en, this message translates to:
  /// **'AI processing completed – review needed'**
  String get aiCompleted;

  /// No description provided for @aiFailed.
  ///
  /// In en, this message translates to:
  /// **'AI could not process – enter details manually'**
  String get aiFailed;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @savedOfflineAiPending.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone. AI processing will run when you are back online.'**
  String get savedOfflineAiPending;

  /// No description provided for @savedAiRetry.
  ///
  /// In en, this message translates to:
  /// **'Saved. AI processing did not finish; it will retry automatically.'**
  String get savedAiRetry;

  /// No description provided for @loginToSync.
  ///
  /// In en, this message translates to:
  /// **'Your login has expired. Log in again to sync your records.'**
  String get loginToSync;

  /// No description provided for @logInAgain.
  ///
  /// In en, this message translates to:
  /// **'Log in again'**
  String get logInAgain;

  /// No description provided for @unsyncedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} not yet synced'**
  String unsyncedCount(int count);

  /// No description provided for @logoutUnsyncedWarning.
  ///
  /// In en, this message translates to:
  /// **'{count} records are not yet synced. They stay on this phone and will sync after you log in again.'**
  String logoutUnsyncedWarning(int count);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @recordConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Record confirmed'**
  String get recordConfirmedTitle;

  /// No description provided for @confirmedSynced.
  ///
  /// In en, this message translates to:
  /// **'The record has been confirmed and saved on the server.'**
  String get confirmedSynced;

  /// No description provided for @confirmedOffline.
  ///
  /// In en, this message translates to:
  /// **'Confirmed on this phone. It will be sent to the server when you are online.'**
  String get confirmedOffline;

  /// No description provided for @conflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Different version on the server'**
  String get conflictTitle;

  /// No description provided for @conflictBody.
  ///
  /// In en, this message translates to:
  /// **'This record was already confirmed with different details. Nothing has been overwritten.'**
  String get conflictBody;

  /// No description provided for @yourVersion.
  ///
  /// In en, this message translates to:
  /// **'Your version'**
  String get yourVersion;

  /// No description provided for @serverVersion.
  ///
  /// In en, this message translates to:
  /// **'Server version'**
  String get serverVersion;

  /// No description provided for @useServerVersion.
  ///
  /// In en, this message translates to:
  /// **'Use server version'**
  String get useServerVersion;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @recordDetails.
  ///
  /// In en, this message translates to:
  /// **'Record details'**
  String get recordDetails;

  /// No description provided for @audioKeptOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Audio recording kept on this phone'**
  String get audioKeptOnPhone;

  /// No description provided for @transcriptLabel.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get transcriptLabel;

  /// No description provided for @translationLabel.
  ///
  /// In en, this message translates to:
  /// **'English translation'**
  String get translationLabel;

  /// No description provided for @confirmedDetails.
  ///
  /// In en, this message translates to:
  /// **'Confirmed details'**
  String get confirmedDetails;

  /// No description provided for @createdLabel.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdLabel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @aiNotVerifiedNotice.
  ///
  /// In en, this message translates to:
  /// **'AI suggestions are not medically verified. Please check every field.'**
  String get aiNotVerifiedNotice;

  /// No description provided for @statRecordsSaved.
  ///
  /// In en, this message translates to:
  /// **'Records saved'**
  String get statRecordsSaved;

  /// No description provided for @statAwaitingReview.
  ///
  /// In en, this message translates to:
  /// **'Awaiting review'**
  String get statAwaitingReview;

  /// No description provided for @statNotSynced.
  ///
  /// In en, this message translates to:
  /// **'Not yet synced'**
  String get statNotSynced;
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
      <String>['en', 'hi', 'kn'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
