# Testing AnkiDSA

## Automated checks

From the Flutter/extension project:

```powershell
flutter test
dart analyze lib test
npm ci
node --test tests/extension-core.test.mjs
npx playwright install chromium
```

Start the local backend and built web app, then run:

```powershell
npx playwright test
```

The browser tests load the real extension into Chromium and use the real local API. LeetCode HTML and its metadata response are controlled fixtures, so tests do not submit code to a real LeetCode account. The user confirmed the normal-Chrome live Accepted capture on 16 September 2026, completing that check for this demo.

The browser tests also exercise the Flutter review flow, content-script storage restrictions, and offline notes across a full browser restart and a change of account. The recovery test requires the **local demo profile** and reads only its test account's message from the local `.local/outbox` mailbox. It does not use external SMTP. Set `ANKIDSA_BACKEND` if the backend folder was moved.

From the backend:

```powershell
$env:SPRING_PROFILES_ACTIVE='test'
.\scripts\maven.ps1 -B test
```

The default suite creates a temporary H2 database and applies Flyway migrations V1–V4. It checks password validation, anonymous access, ownership, URL normalization, duplicates, idempotency, concurrent reviews, statistics, editing, deletion, CORS, recovery expiry/replay/concurrency/session revocation, device ownership, and concurrent device registration. Mail tests use mocks or a loopback SMTP server.

To run that suite against a **disposable** PostgreSQL database:

```powershell
$env:TEST_DB_URL='jdbc:postgresql://127.0.0.1:55432/ankidsa_test'
$env:TEST_DB_USER='ankidsa_test'
.\scripts\maven.ps1 -B test
```

The current test configuration expects that disposable database to use local trust authentication. Never point tests at a production database.

## Native Android check

The dedicated `AnkiDSA_Demo_64` emulator uses Android 8/API 26 and x86_64. Start it on port 5556 and install the APK described in DEMO.md. With the local API running:

```powershell
.\scripts\android-smoke.ps1
```

This script requires that named test emulator. It clears only that emulator's local AnkiDSA app data, creates a separate API test account and problem, signs in through the native fields, reveals a note, submits a review, checks the resulting statistics, and restarts the app to verify its stored session. It does not reset the shared sample account. Screenshots and the last accessibility tree are saved in `.work/`.

The script retries a temporarily unavailable accessibility tree during emulator startup and checks screenshot-transfer exit codes, so redirected adb progress output does not fail a successful test.

## Manual acceptance

- Sign up in the extension and sign into Flutter with the same account.
- Save a real LeetCode problem; confirm URL, title, difficulty, tags, and multiline notes.
- Repeat an accepted submission; confirm one collection entry and preserved notes.
- Disconnect the API, save a new problem, restart the extension, restore the API, and sync. Confirm the problem appears exactly once.
- Sign out with pending notes and sign in as a different account. Confirm those notes are not uploaded into the new account.
- Review from Flutter: tags and notes remain hidden before reveal. Each rating must update the queue and Insights.
- Replay the same review request: one history record. Two different stale requests: one success and one conflict.
- Edit a note, search by title/tag, filter by difficulty, open LeetCode, and delete a problem.
- Check empty, offline, malformed-input, expired-session, and slow-response states.
- Check phone width, desktop width, large text, keyboard navigation, and screen-reader labels.
- Request recovery, open the link in a fresh tab and an already-open app tab, reset the password, and confirm the old password and old sessions stop working.
- Future production check, outside this local submission: with Firebase configured on a real phone, opt in, deny/restore permission, receive a reminder while backgrounded, tap it to open the queue, then sign out and change accounts. Confirm reminders follow the opted-in account. Automated tests use a fake push adapter; provider delivery requires this device check.
- Follow the Android install steps in DEMO.md and verify native sign-in and review.

## Evidence

Development evidence and screenshots are stored locally in `.work/`; that folder is private and excluded from publication. The explicitly assembled `.work/AnkiDSA-local-demo.zip` contains only the selected demo deliverables and can be shared. See WORKLOG.md for the current verification status and deferred production work.
