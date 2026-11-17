// ============================================================
// APP CONFIGURATION  -  the ONLY place the server address is set
// ============================================================
//
// When your PC's Wi-Fi IP address changes:
//   1. On the PC, run `ipconfig` and copy the "IPv4 Address"
//      of your Wi-Fi adapter (for example 192.168.1.20).
//   2. Paste it into [serverIp] below and save.
//   3. Re-run the app (`flutter run`) - hot reload is not enough.
//
// Nothing else in the app needs to change: every screen and the sync
// engine read [baseUrl] from this file.

/// IPv4 address of the PC running the FastAPI backend.
const String serverIp = '192.168.31.52';

/// Port the backend listens on (`uvicorn ... --port 8000`).
const int serverPort = 8000;

/// Full address of the backend, built from the two values above.
///
/// It can also be overridden for one run without editing code:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://$serverIp:$serverPort',
);
