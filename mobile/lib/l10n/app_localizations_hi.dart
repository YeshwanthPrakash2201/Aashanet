// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'AASHANet AI';

  @override
  String get loginTitle => 'लॉगिन';

  @override
  String get username => 'उपयोगकर्ता नाम';

  @override
  String get password => 'पासवर्ड';

  @override
  String get login => 'लॉगिन करें';

  @override
  String get welcome => 'स्वागत है';

  @override
  String get role => 'भूमिका';

  @override
  String get record => 'रिकॉर्ड';

  @override
  String get dataShowing => 'रिकॉर्ड देखें';

  @override
  String get typingOption => 'टाइप करने का विकल्प';

  @override
  String get tasks => 'कार्य';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get language => 'भाषा';

  @override
  String get selectLanguage => 'अपनी डिफ़ॉल्ट भाषा चुनें';

  @override
  String get english => 'अंग्रेज़ी';

  @override
  String get kannada => 'कन्नड़';

  @override
  String get hindi => 'हिंदी';

  @override
  String get continueText => 'जारी रखें';

  @override
  String get usernameHint => 'अपना उपयोगकर्ता नाम दर्ज करें';

  @override
  String get passwordHint => 'अपना पासवर्ड दर्ज करें';

  @override
  String get loginSubtitle => 'AI आधारित आवाज़ से संचालित स्वास्थ्य सहायक';

  @override
  String get loginSupportText =>
      'ग्रामीण स्वास्थ्य सेवाओं में आशा कार्यकर्ताओं की सहायता';

  @override
  String get enterUsernamePassword =>
      'कृपया उपयोगकर्ता नाम और पासवर्ड दर्ज करें';

  @override
  String get loginFailed => 'लॉगिन विफल हुआ';

  @override
  String get couldNotConnectServer => 'सर्वर से कनेक्ट नहीं हो सका';

  @override
  String get recordHealthVisit => 'स्वास्थ्य भ्रमण दर्ज करें';

  @override
  String get captureHealthInformation => 'स्वास्थ्य जानकारी दर्ज करें';

  @override
  String get captureHealthDescription =>
      'स्वास्थ्य संबंधी जानकारी सामान्य भाषा में दर्ज करें। AASHANet AI इसका विश्लेषण करके स्वास्थ्य रिकॉर्ड बनाएगा।';

  @override
  String get tapToRecordVoice => 'आवाज़ रिकॉर्ड करने के लिए टैप करें';

  @override
  String get tapToStopRecording => 'रिकॉर्डिंग रोकने के लिए टैप करें';

  @override
  String get recording => 'रिकॉर्डिंग हो रही है...';

  @override
  String get recordingSaved => 'रिकॉर्डिंग सहेजी गई';

  @override
  String get recordingStarted => 'रिकॉर्डिंग शुरू हुई';

  @override
  String get enterRecordByTyping => 'टाइप करके रिकॉर्ड दर्ज करें';

  @override
  String get processRecord => 'रिकॉर्ड संसाधित करें';

  @override
  String get analyzingRecord => 'रिकॉर्ड का विश्लेषण हो रहा है...';

  @override
  String get orText => 'या';

  @override
  String get recordExampleHint =>
      'उदाहरण: रमेश की उम्र 42 वर्ष है और उन्हें तीन दिनों से खांसी और बुखार है';

  @override
  String get microphonePermissionRequired => 'माइक्रोफ़ोन की अनुमति आवश्यक है';

  @override
  String get couldNotRecordVoice => 'आवाज़ रिकॉर्ड नहीं हो सकी';

  @override
  String get couldNotSaveRecordLocally =>
      'रिकॉर्ड स्थानीय रूप से सहेजा नहीं जा सका';

  @override
  String get pleaseEnterOrRecordHealthInfo =>
      'कृपया स्वास्थ्य संबंधी जानकारी लिखें या आवाज़ में रिकॉर्ड करें';

  @override
  String get recordSavedLocallyOffline =>
      'रिकॉर्ड इस डिवाइस पर सहेजा गया है, लेकिन सर्वर पर नहीं भेजा जा सका। कृपया बाद में पुनः प्रयास करें।';

  @override
  String get reviewExtractedInformation => 'निकाली गई जानकारी की समीक्षा करें';

  @override
  String get localHealthRecords => 'स्थानीय स्वास्थ्य रिकॉर्ड';

  @override
  String get couldNotLoadRecords => 'रिकॉर्ड लोड नहीं हो सके';

  @override
  String get noLocalHealthRecords =>
      'अभी तक कोई स्थानीय स्वास्थ्य रिकॉर्ड नहीं है।';

  @override
  String get workerLabel => 'कार्यकर्ता';

  @override
  String get notAssignedYet => 'अभी तक आवंटित नहीं किया गया';

  @override
  String get statusLabel => 'स्थिति';
}
