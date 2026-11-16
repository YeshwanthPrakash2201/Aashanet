// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'AASHANet AI';

  @override
  String get loginTitle => 'Login';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get welcome => 'Welcome';

  @override
  String get role => 'Role';

  @override
  String get record => 'Record';

  @override
  String get dataShowing => 'Data Showing';

  @override
  String get typingOption => 'Typing Option';

  @override
  String get tasks => 'Tasks';

  @override
  String get logout => 'Logout';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select your default language';

  @override
  String get english => 'English';

  @override
  String get kannada => 'Kannada';

  @override
  String get hindi => 'Hindi';

  @override
  String get continueText => 'Continue';

  @override
  String get usernameHint => 'Enter your username';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get loginSubtitle => 'AI-Powered Voice-Based Health Assistant';

  @override
  String get loginSupportText => 'Supporting ASHA workers in rural healthcare';

  @override
  String get enterUsernamePassword => 'Please enter username and password';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get couldNotConnectServer => 'Could not connect to server';

  @override
  String get recordHealthVisit => 'Record Health Visit';

  @override
  String get captureHealthInformation => 'Capture Health Information';

  @override
  String get captureHealthDescription =>
      'Enter health information naturally. AASHANet AI will analyze it and create a health record.';

  @override
  String get tapToRecordVoice => 'Tap to record voice';

  @override
  String get tapToStopRecording => 'Tap to stop recording';

  @override
  String get recording => 'Recording...';

  @override
  String get recordingSaved => 'Recording saved';

  @override
  String get recordingStarted => 'Recording started';

  @override
  String get enterRecordByTyping => 'Enter record by typing';

  @override
  String get processRecord => 'Process Record';

  @override
  String get analyzingRecord => 'Analyzing record...';

  @override
  String get orText => 'OR';

  @override
  String get recordExampleHint =>
      'Example: Ramesh is 42 years old and has cough and fever for three days';

  @override
  String get microphonePermissionRequired =>
      'Microphone permission is required';

  @override
  String get couldNotRecordVoice => 'Could not record voice';

  @override
  String get couldNotSaveRecordLocally => 'Could not save record locally';

  @override
  String get pleaseEnterOrRecordHealthInfo =>
      'Please enter or record the health information';

  @override
  String get recordSavedLocallyOffline =>
      'Record saved on this device, but it could not be sent to the server. Please try again later.';

  @override
  String get reviewExtractedInformation => 'Review Extracted Information';

  @override
  String get localHealthRecords => 'Local Health Records';

  @override
  String get couldNotLoadRecords => 'Could not load records';

  @override
  String get noLocalHealthRecords => 'No local health records yet.';

  @override
  String get workerLabel => 'Worker';

  @override
  String get notAssignedYet => 'Not assigned yet';

  @override
  String get statusLabel => 'Status';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get syncing => 'Syncing…';

  @override
  String get syncNow => 'Sync now';

  @override
  String get statusSavedOffline => 'Saved offline';

  @override
  String get statusPendingSync => 'Pending sync';

  @override
  String get statusUploading => 'Uploading';

  @override
  String get statusSynced => 'Synced';

  @override
  String get statusSyncFailed => 'Sync failed – will retry';

  @override
  String get statusConflict => 'Needs your decision';

  @override
  String get aiPending => 'AI processing pending (needs internet)';

  @override
  String get aiCompleted => 'AI processing completed – review needed';

  @override
  String get aiFailed => 'AI could not process – enter details manually';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get savedOfflineAiPending =>
      'Saved on this phone. AI processing will run when you are back online.';

  @override
  String get savedAiRetry =>
      'Saved. AI processing did not finish; it will retry automatically.';

  @override
  String get loginToSync =>
      'Your login has expired. Log in again to sync your records.';

  @override
  String get logInAgain => 'Log in again';

  @override
  String unsyncedCount(int count) {
    return '$count not yet synced';
  }

  @override
  String logoutUnsyncedWarning(int count) {
    return '$count records are not yet synced. They stay on this phone and will sync after you log in again.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get recordConfirmedTitle => 'Record confirmed';

  @override
  String get confirmedSynced =>
      'The record has been confirmed and saved on the server.';

  @override
  String get confirmedOffline =>
      'Confirmed on this phone. It will be sent to the server when you are online.';

  @override
  String get conflictTitle => 'Different version on the server';

  @override
  String get conflictBody =>
      'This record was already confirmed with different details. Nothing has been overwritten.';

  @override
  String get yourVersion => 'Your version';

  @override
  String get serverVersion => 'Server version';

  @override
  String get useServerVersion => 'Use server version';

  @override
  String get later => 'Later';

  @override
  String get recordDetails => 'Record details';

  @override
  String get audioKeptOnPhone => 'Audio recording kept on this phone';

  @override
  String get transcriptLabel => 'Transcript';

  @override
  String get translationLabel => 'English translation';

  @override
  String get confirmedDetails => 'Confirmed details';

  @override
  String get createdLabel => 'Created';

  @override
  String get close => 'Close';

  @override
  String get aiNotVerifiedNotice =>
      'AI suggestions are not medically verified. Please check every field.';

  @override
  String get statRecordsSaved => 'Records saved';

  @override
  String get statAwaitingReview => 'Awaiting review';

  @override
  String get statNotSynced => 'Not yet synced';
}
