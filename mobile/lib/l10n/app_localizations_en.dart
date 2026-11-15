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
}
