# AnkiDSA local demo package

This package contains the verified local prototype: the Flutter web app, Spring Boot API, Chrome extension, and Android x86_64 debug APK. Production deployment is outside this submission's scope.

## Start the packaged demo

1. Extract the ZIP completely. Open PowerShell in the extracted `AnkiDSA-local-demo` folder.
2. Install Java 21 and Node.js 22 or newer if needed. Set `JAVA_HOME` to the Java 21 installation. Chrome is needed for the extension; Flutter and Maven are not needed to run these built files.
3. Stop any existing AnkiDSA demo using its own stop script, then run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Start-Demo.ps1
```

Open **http://localhost:3000** and sign in with **demo@ankidsa.local / DemoRecall!2026**. The API is **http://localhost:8081**. In Chrome, open **chrome://extensions**, enable **Developer mode**, select **Load unpacked**, choose this package's `extension` folder, and sign in with the same account. Refresh the LeetCode tab after loading the extension.

The first launch creates a fresh local sample database and a local session-signing secret automatically. No passwords, provider keys, or production services need to be configured. This package does not contain the developer's database, mailbox, sessions, or private backups. Internet access is needed to use live LeetCode; the review app's rendering assets and fonts are bundled locally.

## Record

Capture a new Accepted LeetCode submission, save an approach note in the extension, open the app, reveal the note in a review, select Good, and show Collection and Insights. The sample history is synthetic. The user confirmed live Accepted capture in normal Chrome; automated browser checks use controlled LeetCode fixtures.

See `docs/DEMO.md` for the 90-second recording story. Paths in the source-project guides refer to the development machine; use this package's commands and relative paths when running the extracted copy.

## Stop or reset

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Stop-Demo.ps1
```

Local data survives a restart. To reset only the sample account's collection and history while the API is running:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Reset-Demo.ps1
```

Reset removes problems added to the sample account. Other accounts are preserved. Refresh the app and extension afterwards.

## Optional Android demo

The APK at `android/app-x86_64-debug.apk` is for a **64-bit x86 Android emulator**, API 26 or newer. With the local API running and the emulator started:

```powershell
adb install -r .\android\app-x86_64-debug.apk
```

The emulator reaches the computer's API at `http://10.0.2.2:8081`. Sign in with the same sample account. This is a large debug APK; it does not require release signing and is not an ARM phone build.

## Verification and troubleshooting

`docs/WORKLOG.md` records the passing checks. `checksums.json` lists the SHA-256 and size of every packaged payload file. `docs/TESTING.md` contains commands for repeating the full test suites from the source projects.

- API health: **http://localhost:8081/health** should return `{"status":"ok"}`.
- Logs: `.work/backend.log`, `.work/backend-error.log`, and `.work/web.log` in this package.
- Password recovery: local `.eml` messages appear in `backend/.local/outbox`; no external email is sent. Use a separate account for recovery so the sample password stays unchanged.
- Reminders: inactive in the local demo. SMTP, Firebase production configuration, AWS deployment, and Android release signing are not required for this submission.
- Rebuilds: use the original source projects and their documented build commands. This bundle runs already-built artifacts.
