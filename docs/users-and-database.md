# Users and PostgreSQL – copy-and-paste guide

Everything you need to manage AASHANet AI login accounts and work with the
PostgreSQL database. Every command is ready to copy and paste.

**Your setup (local PC)**

| Item | Value |
|---|---|
| PostgreSQL version | 18 (Windows service `postgresql-x64-18`) |
| Database name | `aashanet_db` |
| Database user | `postgres` |
| Database password | the one inside `C:\PROJECTS\AASHANet-AI\backend\.env` (`DATABASE_URL=postgresql://postgres:PASSWORD@localhost:5432/aashanet_db`) |
| Port | `5432` |
| psql program | `C:\Program Files\PostgreSQL\18\bin\psql.exe` |

**Two tools, two jobs**

| Job | Use |
|---|---|
| Create users, passwords, switch accounts on/off, rename | **Part 1 – the user script** (always) |
| Look at data, search records, reports, backups, fixes | **Part 2 – PostgreSQL (psql or pgAdmin)** |

> **Why passwords are never set with SQL:** the app stores only a scrambled
> *hash* of each password (Argon2). If you type
> `UPDATE users SET password_hash = 'asha123'` the login will **stop
> working**, because `asha123` is not a valid hash. Always use
> `--reset-password` from Part 1, which makes the hash for you.

---

## Part 1 – Managing users with the script

### 1.1 Open the right folder (do this first, every time)

Open **PowerShell** (Start menu → type `PowerShell` → Enter), then paste:

```powershell
cd C:\PROJECTS\AASHANet-AI\backend
```

All commands in Part 1 are run from this folder. The backend server does
**not** need to be stopped; changes work immediately.

### 1.2 See all users

```powershell
.\.venv\Scripts\python.exe -m scripts.create_admin --list
```

Example output:

```text
USERNAME             FULL NAME                ROLE           ACTIVE
asha1                ASHA Worker 1            ASHA           yes
asha_demo            Demo ASHA Worker         asha_worker    yes
danny                Yeshwanth                admin          yes
```

Passwords are never shown (they cannot be – only the hash is stored).

### 1.3 Create a new ASHA worker (phone login)

```powershell
.\.venv\Scripts\python.exe -m scripts.create_admin --role asha_worker
```

It asks, one at a time:

1. `Username for the new asha_worker account:` → e.g. `asha_lakshmi`
   (lowercase, no spaces – this is what the worker types on the phone)
2. `Full name:` → e.g. `Lakshmi Devi` (shown on the app's home screen)
3. `Password (at least 10 characters, hidden):` → type it; **nothing appears
   while typing, that is normal**; press Enter
4. `Repeat password:` → type it again

Success message: `Created asha_worker user 'asha_lakshmi'.`

### 1.4 Create a new admin

```powershell
.\.venv\Scripts\python.exe -m scripts.create_admin --role admin
```

Same questions as above. Admins can create users through the API
(`POST /users`); ASHA workers cannot.

### 1.5 Forgot a password / change a password

Replace `asha1` with the username:

```powershell
.\.venv\Scripts\python.exe -m scripts.create_admin --reset-password asha1
```

Type the new password twice (hidden). Message:
`Password changed for 'asha1'. Log in with the new password.`

The script asks for at least 10 characters. (The `asha1` / `asha123` login
was set directly for local testing; use proper passwords for real workers.)

### 1.6 Stop someone from logging in (keep their data)

```powershell
.\.venv\Scripts\python.exe -m scripts.create_admin --deactivate asha1
```

The account and all its health records stay in the database; login answers
"Account is disabled". To allow login again:

```powershell
.\.venv\Scripts\python.exe -m scripts.create_admin --activate asha1
```

### 1.7 Change the full name shown in the app

```powershell
.\.venv\Scripts\python.exe -m scripts.create_admin --change-name asha1
```

It shows the current name in `[brackets]`; type the new one (or just press
Enter to keep it). The worker sees the new name after logging in again.

### 1.8 Make an existing user an admin

```powershell
.\.venv\Scripts\python.exe -m scripts.create_admin --promote danny
```

### 1.9 Show all script options

```powershell
.\.venv\Scripts\python.exe -m scripts.create_admin --help
```

### 1.10 Common messages

| Message | Meaning / fix |
|---|---|
| `No user named 'xyz'` | Wrong username – check with `--list` |
| `User 'xyz' already exists` | Pick another username, or `--reset-password xyz` |
| `Too short. Use at least 10 characters.` | Longer password |
| `Passwords do not match` | Type the same password both times |
| `connection ... failed` / `password authentication failed` | PostgreSQL is stopped or `.env` is wrong – see Part 2.11 |
| `No module named scripts` | You are not in `C:\PROJECTS\AASHANet-AI\backend` – run step 1.1 |

---

## Part 2 – Working with PostgreSQL

### 2.1 Open the database (psql, the command line)

In PowerShell:

```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d aashanet_db
```

It asks `Password for user postgres:` → type the database password from
`backend\.env` (hidden) → Enter. You now see the prompt:

```text
aashanet_db=#
```

Everything you type at `aashanet_db=#` is SQL. **Every SQL command must end
with a semicolon `;`**. If you forget it, the prompt changes to
`aashanet_db-#` – just type `;` and press Enter.

Optional: to show Kannada/Hindi text correctly in the PowerShell window, run
this **before** opening psql:

```powershell
chcp 65001
```

### 2.2 psql shortcuts (no semicolon needed)

| Type | Does |
|---|---|
| `\dt` | list tables (`users`, `health_records`) |
| `\d users` | show the columns of a table |
| `\d health_records` | columns of the records table |
| `\x` | switch to "one field per line" view (good for long records); type again to switch back |
| `\l` | list all databases |
| `\c aashanet_db` | connect to the AASHANet database |
| `\conninfo` | which database/user you are connected as |
| `\?` | help for psql commands |
| `\q` | quit psql |
| `q` | leave a long result page (when you see `--More--` or `(END)`) |
| ↑ arrow | repeat a previous command |

### 2.3 The other way: pgAdmin (point and click)

1. Start menu → **pgAdmin 4**.
2. Left panel: **Servers → PostgreSQL 18** (enter the database password if
   asked) **→ Databases → aashanet_db**.
3. Right-click **aashanet_db → Query Tool**.
4. Paste any SQL from this guide into the editor, press **F5** (or the ▶
   button). Results appear below.
5. To see a table quickly: **aashanet_db → Schemas → public → Tables →
   users** → right-click → **View/Edit Data → All Rows**.

pgAdmin shows Kannada/Hindi text correctly without any extra step.

### 2.4 What is in the tables

**`users`** – one row per login account

| Column | Meaning |
|---|---|
| `id` | unique id (UUID) |
| `username` | login name |
| `password_hash` | scrambled password – never edit by hand |
| `role` | `asha_worker`, `admin` (older test accounts have other names) |
| `full_name` | name shown in the app |
| `is_active` | `true` = can log in, `false` = blocked |
| `created_at`, `updated_at` | timestamps |

**`health_records`** – one row per visit synced from a phone

| Column | Meaning |
|---|---|
| `id` | unique id of the record on the server |
| `worker_id` | which user created it (`users.id`) |
| `client_record_id` | id made on the phone (stops duplicates when a sync is retried) |
| `raw_input` | what was typed, or `[Voice recording]` |
| `input_language` | `Kannada`, `Hindi`, `English` or `en` (typed) |
| `ai_transcript` | what the AI heard (original language) |
| `ai_translated_text` | English translation by the AI |
| `ai_suggested_data` | AI's suggested details (JSON) |
| `confirmed_data` | details the worker confirmed (JSON: `patient_name`, `age`, `symptoms`, `duration`) |
| `ai_status` | `pending_review` = AI finished, waiting for the worker; `failed` = AI could not process it |
| `record_status` | `draft` = not confirmed yet; `confirmed` = worker pressed Confirm & Save |
| `version` | goes up each time the record is changed |
| `created_at`, `updated_at` | timestamps (India time) |

### 2.5 Useful queries – users

Copy one block at a time into psql (after `aashanet_db=#`) or pgAdmin.

All users:

```sql
SELECT username, full_name, role, is_active, created_at
FROM users
ORDER BY created_at;
```

One user:

```sql
SELECT username, full_name, role, is_active
FROM users
WHERE username = 'asha1';
```

How many users per role:

```sql
SELECT role, COUNT(*) AS users
FROM users
GROUP BY role;
```

Blocked (deactivated) users:

```sql
SELECT username, full_name FROM users WHERE is_active = false;
```

Change a user's role (e.g. make `asha1` a normal `asha_worker`):

```sql
UPDATE users
SET role = 'asha_worker', updated_at = CURRENT_TIMESTAMP
WHERE username = 'asha1';
```

> psql answers `UPDATE 1` = one row changed. `UPDATE 0` = the username was
> wrong, nothing changed. The user gets the new role at their next login.

Do **not** change `username` with SQL: the phone app stores its saved
records under the username, so renaming would hide them on the phone.
Create a new user instead (Part 1.3).

### 2.6 Useful queries – health records

Latest 20 records with the worker's name:

```sql
SELECT r.created_at,
       u.username,
       r.confirmed_data ->> 'patient_name' AS patient,
       r.confirmed_data ->> 'age'          AS age,
       r.record_status,
       r.ai_status
FROM health_records r
JOIN users u ON u.id = r.worker_id
ORDER BY r.created_at DESC
LIMIT 20;
```

Number of records per worker:

```sql
SELECT u.username, u.full_name, COUNT(r.id) AS records
FROM users u
LEFT JOIN health_records r ON r.worker_id = u.id
GROUP BY u.username, u.full_name
ORDER BY records DESC;
```

Records still waiting for the worker's review (not confirmed):

```sql
SELECT r.created_at, u.username, r.raw_input, r.ai_status
FROM health_records r
JOIN users u ON u.id = r.worker_id
WHERE r.record_status = 'draft'
ORDER BY r.created_at DESC;
```

Records the AI could not process:

```sql
SELECT r.created_at, u.username, r.raw_input
FROM health_records r
JOIN users u ON u.id = r.worker_id
WHERE r.ai_status = 'failed';
```

Search by patient name (part of the name, any capital letters):

```sql
SELECT r.created_at, u.username, r.confirmed_data
FROM health_records r
JOIN users u ON u.id = r.worker_id
WHERE r.confirmed_data ->> 'patient_name' ILIKE '%ravi%';
```

Patients with a symptom (e.g. fever):

```sql
SELECT r.confirmed_data ->> 'patient_name' AS patient,
       r.confirmed_data ->> 'symptoms'     AS symptoms,
       r.created_at
FROM health_records r
WHERE r.confirmed_data -> 'symptoms' ? 'fever';
```

Records created today:

```sql
SELECT COUNT(*) AS records_today
FROM health_records
WHERE created_at::date = CURRENT_DATE;
```

Records of one worker:

```sql
SELECT r.created_at, r.confirmed_data ->> 'patient_name' AS patient, r.record_status
FROM health_records r
JOIN users u ON u.id = r.worker_id
WHERE u.username = 'asha1'
ORDER BY r.created_at DESC;
```

Everything about one record (in psql, type `\x` first for a readable view):

```sql
SELECT * FROM health_records
ORDER BY created_at DESC
LIMIT 1;
```

### 2.7 Export to Excel (CSV file)

In **psql** (this is one line; it must start with `\copy`):

```sql
\copy (SELECT r.created_at, u.username, r.confirmed_data ->> 'patient_name' AS patient, r.confirmed_data ->> 'age' AS age, r.confirmed_data ->> 'symptoms' AS symptoms, r.confirmed_data ->> 'duration' AS duration, r.record_status FROM health_records r JOIN users u ON u.id = r.worker_id ORDER BY r.created_at) TO 'C:/Users/danny/Desktop/aashanet_records.csv' WITH (FORMAT csv, HEADER, ENCODING 'UTF8')
```

The file appears on your Desktop. Open it in Excel via **Data → From
Text/CSV** and choose **65001: Unicode (UTF-8)** so Kannada/Hindi show
correctly. (In pgAdmin: run the SELECT, then use the **Save results to
file** button above the results.)

### 2.8 Deleting data safely

Deleting cannot be undone. **Take a backup first (2.9).** Then always use
`BEGIN` … check … `COMMIT` so you can cancel with `ROLLBACK`.

Delete one test record (copy its `id` from a query above):

```sql
BEGIN;
DELETE FROM health_records WHERE id = 'PASTE-RECORD-ID-HERE';
-- psql should answer: DELETE 1
COMMIT;
```

If the answer is not what you expected, type `ROLLBACK;` instead of
`COMMIT;` and nothing is deleted.

Delete a test user **and** all their records (a user with records cannot be
deleted alone):

```sql
BEGIN;
DELETE FROM health_records
WHERE worker_id = (SELECT id FROM users WHERE username = 'postman_test');
DELETE FROM users WHERE username = 'postman_test';
-- check the two answers (DELETE n, then DELETE 1), then:
COMMIT;
```

For real workers prefer `--deactivate` (Part 1.6): nothing is lost.

### 2.9 Backup and restore

Backups are made from **PowerShell** (not inside psql). First create a
folder once:

```powershell
mkdir C:\AASHANet-backups
```

**Make a backup** (asks for the database password):

```powershell
& "C:\Program Files\PostgreSQL\18\bin\pg_dump.exe" -U postgres -d aashanet_db -F c -f "C:\AASHANet-backups\aashanet_db_$(Get-Date -Format yyyy-MM-dd_HHmm).backup"
```

This creates a file such as `aashanet_db_2026-11-17_1930.backup`. Make one
before any delete, before running a new migration, and before a demo.

**Restore a backup into a new, separate database** (safe – your current
data is not touched). Replace the file name with yours:

```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -c "CREATE DATABASE aashanet_restore;"
```

```powershell
& "C:\Program Files\PostgreSQL\18\bin\pg_restore.exe" -U postgres -d aashanet_restore "C:\AASHANet-backups\aashanet_db_2026-11-17_1930.backup"
```

Check it with `psql -d aashanet_restore`. To make the app use it, change
the end of `DATABASE_URL` in `backend\.env` from `/aashanet_db` to
`/aashanet_restore` and restart the backend.

### 2.10 Setting up the database from zero (new PC or after a reset)

```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -c "CREATE DATABASE aashanet_db;"
```

```powershell
cd C:\PROJECTS\AASHANet-AI\backend
```

```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d aashanet_db -f migrations\001_create_users.sql
```

```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d aashanet_db -f migrations\002_create_health_records.sql
```

```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d aashanet_db -f migrations\003_offline_sync.sql
```

Then create the first accounts with Part 1.3 and 1.4. Run each migration
file only once per database, in number order. A future file
`004_....sql` is run the same way.

### 2.11 Problems and fixes

| Problem | Fix |
|---|---|
| `psql : The term 'psql' is not recognized` | Use the full path with `&` exactly as shown in 2.1 |
| `password authentication failed for user "postgres"` | Wrong password – use the one in `backend\.env` |
| `connection to server at "localhost" ... refused` | PostgreSQL is stopped – start it (below) |
| `database "aashanet_db" does not exist` | Create it (2.10), or check the name with `\l` |
| `relation "users" does not exist` | Connected to the wrong database (`\c aashanet_db`) or migrations not run (2.10) |
| Prompt shows `aashanet_db-#` | You forgot `;` – type `;` and Enter |
| Stuck in a long result (`--More--`, `(END)`) | Press `q` |
| Kannada/Hindi shows as `???` in PowerShell | Run `chcp 65001` before psql, or use pgAdmin |
| App login gives "Internal Server Error" | Database unreachable from the backend: check PostgreSQL is running, then restart the backend in a **new** PowerShell window |

Check / start the PostgreSQL service (PowerShell):

```powershell
Get-Service postgresql-x64-18
```

If `Status` is `Stopped`, open PowerShell **as Administrator** (right-click
PowerShell → Run as administrator) and run:

```powershell
Start-Service postgresql-x64-18
```

Or: Start menu → `services.msc` → **postgresql-x64-18** → **Start**.

### 2.12 Same things on the cloud database (Neon)

If you deployed with `docs/deployment.md`:

- **SQL** (Parts 2.5–2.8): paste into Neon's **SQL Editor** instead of psql.
- **User script** (Part 1): in a PowerShell window, point it at Neon for
  that window only, then run the same commands:

  ```powershell
  cd C:\PROJECTS\AASHANet-AI\backend
  $env:DATABASE_URL = "PASTE-THE-NEON-CONNECTION-STRING-HERE"
  .\.venv\Scripts\python.exe -m scripts.create_admin --list
  ```

  **Close that window afterwards.** Do not start the local backend in a
  window where `$env:DATABASE_URL` is set – it would talk to the wrong
  database (this is what caused the earlier login "Internal Server Error").
  To clear it without closing: `Remove-Item Env:DATABASE_URL`

---

## Quick reference

```powershell
cd C:\PROJECTS\AASHANet-AI\backend
.\.venv\Scripts\python.exe -m scripts.create_admin --list
.\.venv\Scripts\python.exe -m scripts.create_admin --role asha_worker
.\.venv\Scripts\python.exe -m scripts.create_admin --role admin
.\.venv\Scripts\python.exe -m scripts.create_admin --reset-password USERNAME
.\.venv\Scripts\python.exe -m scripts.create_admin --deactivate USERNAME
.\.venv\Scripts\python.exe -m scripts.create_admin --activate USERNAME
.\.venv\Scripts\python.exe -m scripts.create_admin --change-name USERNAME
.\.venv\Scripts\python.exe -m scripts.create_admin --promote USERNAME
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d aashanet_db
```
