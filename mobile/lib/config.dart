// ============================================================
// APP CONFIGURATION
// ============================================================

/// Address of the FastAPI backend.
///
/// Default is the development PC on the current Wi-Fi. Override without
/// editing code:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.31.52:8000',
);
