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
// Using the backend deployed on the internet instead? Put its address in
// [cloudServerUrl] below (docs/deployment.md, Part 3).
//
// Nothing else in the app needs to change: every screen and the sync
// engine read [baseUrl] from this file.

/// IPv4 address of the PC running the FastAPI backend.
const String serverIp = '10.90.23.74';

/// Port the backend listens on (`uvicorn ... --port 8000`).
const int serverPort = 8000;

/// Address of the backend deployed on the internet (see
/// docs/deployment.md), e.g. 'https://aashanet-backend.onrender.com'.
/// Leave it empty ('') to use the PC on your Wi-Fi ([serverIp]) instead.
/// When it is filled in, [serverIp] and [serverPort] are ignored.
const String cloudServerUrl = '';

/// Full address of the backend: [cloudServerUrl] if set, otherwise
/// built from [serverIp] and [serverPort].
///
/// It can also be overridden for one run without editing code:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: cloudServerUrl != ''
      ? cloudServerUrl
      : 'http://$serverIp:$serverPort',
);
