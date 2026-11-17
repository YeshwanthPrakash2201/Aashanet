# AASHANet AI

**An AI-powered, voice-based, offline-first health record assistant for ASHA workers in rural India.**

An ASHA worker records a short voice note (or types the details) about a household visit.
The record is saved on the phone immediately – with or without internet – and is synchronised
with the server when a connection is available. The server sends the voice note to the
Google Gemini API, which returns a transcript, an English translation and suggested fields
(patient name, age, symptoms, duration). The worker reviews and corrects the suggestions and
confirms the record. AI output is always a suggestion; it is never treated as medically verified.

## Features

- Voice recording (AAC `.m4a`) or typed entry, in an app available in **English, Kannada and Hindi**
- **Offline-first:** every record is stored on the phone first (Drift / SQLite)
- **Reliable sync:** idempotent, versioned create → AI → confirm protocol; retries never create
  duplicates; conflicting confirmations are detected, never silently overwritten
- **AI processing** with Google Gemini: structured JSON output, validation, model fallback and time limits
- Review-and-confirm screen; live sync and AI status for every record
- JWT login, Argon2 password hashing, admin-only account creation

## Repository structure

```
backend/                 Python FastAPI service
  app/main.py            app start-up, login, current user, account creation
  app/core/              JWT and password hashing
  app/modules/auth/      user service and repository
  app/modules/records/   health-record API, service and repository
  app/modules/ai/        rule-based analyser for typed records
  app/services/          Gemini integration
  app/schemas/           request / response models
  migrations/            SQL scripts (run in order 001, 002, 003)
  scripts/create_admin.py  create admin or ASHA worker accounts
  samples/               sample voice note for manual AI checks
  tests/                 unit, endpoint and database tests
mobile/                  Flutter application
  lib/main.dart          app start-up, login, home, record and review screens
  lib/application/       sync engine and shared services
  lib/domain/            record statuses and local repository
  lib/infrastructure/    database, API client, connectivity, secure session
  lib/presentation/      design system, records list, language selection
  lib/l10n/              English, Kannada and Hindi texts
  test/                  unit, widget, live and screenshot tests
docs/                    testing guide for the offline workflow
```

## Requirements

- Python 3.12, PostgreSQL (tested with 18)
- Flutter 3.47 (Dart 3) and an Android phone or emulator
- A Google Gemini API key

## Backend setup

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env        # then fill in DATABASE_URL, JWT_SECRET_KEY, GEMINI_API_KEY
```

Create the database tables by running `migrations/001_create_users.sql`,
`002_create_health_records.sql` and `003_offline_sync.sql` in order (for example with `psql`).

Create the first administrator and an ASHA worker account (passwords are typed, not shown):

```powershell
python -m scripts.create_admin --role admin
python -m scripts.create_admin --role asha_worker
```

Start the server so that phones on the same Wi-Fi can reach it:

```powershell
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## Mobile app

```powershell
cd mobile
flutter pub get
flutter run
```

The server address is set in one place: `serverIp` in `mobile/lib/config.dart`.
When your PC's Wi-Fi IP changes (check with `ipconfig`), edit that line and run the app again.
For a one-off run you can also pass `--dart-define=API_BASE_URL=http://<ip>:8000`.

## Tests

```powershell
# backend (from backend/)
python -m unittest discover -s tests -t .
# optional: also run the real-SQL tests (rolled back, data unchanged)
$env:TEST_DATABASE_URL = "postgresql://..."; python -m unittest discover -s tests -t .

# mobile (from mobile/)
flutter analyze
flutter test
```

`mobile/test/live/live_sync_test.dart` (real backend) and `mobile/test/screenshots/` (screen
renders) are skipped unless their environment variables are set; see the comments in those files.
The on-device checklist is in `docs/offline-sync-testing.md`.

## Configuration

| Variable | Purpose |
|---|---|
| `DATABASE_URL` | PostgreSQL connection |
| `JWT_SECRET_KEY`, `JWT_ALGORITHM`, `ACCESS_TOKEN_EXPIRE_MINUTES` | login tokens |
| `GEMINI_API_KEY` | Google Gemini API key |
| `GEMINI_MODEL`, `GEMINI_FALLBACK_MODELS`, `GEMINI_TIMEOUT_SECONDS` | AI model choice and time limit |

Never commit the real `.env` file.

## Known limitations

- Sync runs only while the app is open; AI processing needs internet.
- The development set-up uses plain HTTP and an unencrypted local database; production needs HTTPS and encryption.
- Field testing with ASHA workers has not yet been carried out.

## Authors

Ranjan N G, Rohith B, Shridhar K P, Yeshwanth Gowda P – under the guidance of Prof. Ramachandra H Y,
Department of Computer Science and Engineering, Shridevi Institute of Engineering and Technology, Tumakuru.
