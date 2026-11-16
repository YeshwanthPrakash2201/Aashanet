# Offline-first sync – testing guide

How the offline workflow was tested, what the results were, and the
on-device checklist that still has to be run on a real phone.

## How it works (short)

1. **Save** – every record is written to the phone's SQLite database
   (Drift) first, with a random UUID, the creation time, the original
   audio file path and status `pending_sync` / `ai_pending`. This never
   needs the internet.
2. **Online check** – the app shows **Online** only when the backend
   actually answers (`GET /`), not merely when Wi-Fi is on.
3. **Sync** – runs at app start, when the server becomes reachable, when
   the app returns to the foreground, every minute while online, after
   saving/confirming a record, and from the **Sync now** button. Each
   record goes through three server steps, each safe to repeat:
   `create` (idempotent by client UUID) → `AI` (Gemini; needs internet)
   → `confirm` (same data again is accepted; different data = conflict).
4. **Synced** is set only after the server answered successfully.
   Failures keep the record and audio, and retry after 30 s, 1 min,
   2 min … up to 1 hour. An expired login pauses sync and shows
   *Log in again*; nothing is lost.
5. **Conflict** – if the server already holds a *different* confirmed
   version, nothing is overwritten. The record shows *Needs your
   decision*; both versions are shown, and choosing the server version
   keeps the worker's version stored on the phone.

AI processing runs on the server (Gemini) and therefore **requires
internet**. There is no offline AI. AI output is always a suggestion the
worker must review; it is never treated as medically verified.

## Automated test results (2026-11-16)

| Suite | Command (from the folder) | Result |
|---|---|---|
| Backend unit + endpoint tests | `backend`: `.\.venv\Scripts\python.exe -m unittest discover -s tests -t .` | 39 passed, 5 skipped* |
| Backend real-SQL repository tests* | same, with `TEST_DATABASE_URL` set | 5 passed (rolled back, no data changed) |
| Flutter unit + widget tests | `mobile`: `flutter test` | 35 passed |
| Live end-to-end (phone sync engine → real FastAPI + PostgreSQL + Gemini) | `mobile`: `flutter test test/live/live_sync_test.dart` with `LIVE_API_URL`, `LIVE_TOKEN`, `LIVE_AUDIO` | passed |

Live end-to-end run, actual output:

```
offline  : sync=pending_sync ai=ai_pending error=network server=null
online   : sync=synced ai=ai_completed server=0258…1b42 (19s)
ai fields: {"age":21,"duration":"3 days","symptoms":["fever","cold","cough"],"patient_name":"Ranjan M G"}
typed    : sync=synced ai=ai_completed fields={"age":42,"symptoms":["fever"],"patient_name":"Ramesh",...}
retry    : same server id = true
confirm  : local=synced server=confirmed v3
conflict : status=409
```

PostgreSQL afterwards: exactly **one** row per client UUID (no
duplicates). The two test rows were then deleted.

### Requested scenarios → where they are covered

| # | Scenario | Automated test | On-device check |
|---|---|---|---|
| 1 | Save while online | sync test 1, live run | A |
| 2 | Save while offline | sync test 2, live run | B |
| 3 | Close and reopen while offline | DB "survive closing and reopening", sync "app restart" | C |
| 4 | Saved records still available | same as 3, widget "offline record shows…" | C |
| 5 | Internet restored | sync test 5/6/9, live run | D |
| 6 | Pending records sync | same as 5 | D |
| 7 | Failed upload keeps the record | sync test 7, "AI busy" | E |
| 8 | Retry creates no duplicates | sync tests 8 / 8b, backend idempotency tests, live run | E |
| 9 | AI resumes when online | sync test 5/6/9, "AI busy", live run | D |
| 10 | App usable during sync | sync test 10 (serialized), live-updating list | F |

## On-device checklist (to be run by you)

Prepare: start the backend reachable from the phone
(`uvicorn app.main:app --host 0.0.0.0 --port 8000`), rebuild the app
(`flutter run`), log in as `asha_demo`. Write the actual result next to
each step.

**A – online save**
1. Confirm the app bar shows **Online**.
2. Record a short voice note, tap *Process Record*.
3. Expected: the review screen opens with AI suggestions within ~10–20 s.
   Confirm it → dialog *The record has been confirmed and saved on the server.*

**B – offline save**
1. Turn on airplane mode. Within a few seconds the badge shows **Offline**.
2. Record a voice note and tap *Process Record*.
3. Expected: message *Saved on this phone. AI processing will run when you are back online.*
   Home shows *1 not yet synced*. *View records* shows the record with
   **Saved offline** and **AI processing pending (needs internet)**.

**C – close and reopen offline**
1. Still in airplane mode, close the app completely (swipe it away), reopen.
2. Expected: you are not asked to log in; the record from B is still in
   the list with the same statuses.

**D – connection returns**
1. Turn airplane mode off. Stay on the home screen or the records list.
2. Expected: within about a minute the badge shows **Online**, then
   **Syncing…**; the record changes to **Synced** and **AI processing
   completed – review needed**; *not yet synced* disappears.
3. Tap the record → review screen opens → confirm → *saved on the server*.

**E – failed upload and retry (no duplicates)**
1. Stop the backend (Ctrl+C) while the phone stays on Wi-Fi.
2. Record a voice note. Expected: *Saved…*; status **Saved offline** (the
   server cannot be reached).
3. Start the backend again. Expected: the record syncs automatically.
4. In PostgreSQL, check the record exists **once**:
   `SELECT client_record_id, count(*) FROM health_records GROUP BY 1 HAVING count(*) > 1;`
   must return no rows.

**F – app usable during sync**
1. Make 3 offline records, then go online.
2. While the badge shows **Syncing…**, open *View records*, scroll, open
   a record, start a new recording.
3. Expected: nothing freezes; statuses update by themselves.

**G – expired login (optional)**
1. Temporarily set `ACCESS_TOKEN_EXPIRE_MINUTES=1` in `backend/.env`,
   restart the backend, log in, wait 2 minutes, go offline, record a note,
   go online.
2. Expected: banner *Your login has expired…*; the record stays
   **Saved offline / Pending sync**. Tap *Log in again*, log in → it syncs.
3. Restore `ACCESS_TOKEN_EXPIRE_MINUTES=60`.

## Known limitations

- Sync runs only while the app is open (no background sync when closed).
- AI processing needs internet; there is no offline AI.
- Traffic uses plain `http://`; a real deployment needs HTTPS.
- The phone's SQLite database and audio files are not encrypted (they are
  in the app's private storage).
- Audio recordings are kept after sync (by decision) and are not cleaned
  up automatically.
- Conflicts can only be resolved by taking the server's version, because
  a confirmed server record is final (no edit endpoint).
- Hindi and Kannada texts for the new statuses were written by the
  developer tooling and should be checked by a native speaker.
