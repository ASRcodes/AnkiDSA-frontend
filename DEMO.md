# Recording the demo

Today's submission is the local demo/prototype. Production deployment, SMTP, Firebase production configuration, AWS, and Android release signing are not required.

The complete built demo is packaged in `.work/AnkiDSA-local-demo.zip`. Extract it and follow its `README.md` to run it from another folder or Windows computer with Java 21, Node.js 22+, and Chrome. It contains a fresh demo setup; your existing rehearsal data stays in the source project's backend. See [the package guide](docs/LOCAL_DEMO_PACKAGE.md).

## Start

From PowerShell in `C:\Users\rajsi\ankidsa`:

```powershell
.\scripts\start-demo.ps1
```

Open **http://localhost:3000**. Sign in with **demo@ankidsa.local / DemoRecall!2026**. In Chrome, open **chrome://extensions**, enable Developer mode, choose Load unpacked, and select **C:\Users\rajsi\ankidsa\extension**. Pin it and sign in with the same account.

The API uses a separate local H2 database. Your Supabase database is not used. The extension's server and review app defaults are `http://localhost:8081` and `http://localhost:3000`.

## Before recording

The live Accepted capture was confirmed in normal Chrome on 16 September 2026. Reload the extension after updating it and refresh the LeetCode tab. The account-security update requires one fresh sign-in in each client.

- Open a real LeetCode problem in normal Chrome. Complete its normal sign-in or browser verification yourself, then refresh the tab after installing the extension.
- Open AnkiDSA and confirm the title and difficulty are detected correctly.
- Rehearse a real Accepted submission. Automated Chromium encountered LeetCode's browser challenge; the passing automated acceptance tests use a controlled LeetCode page fixture.
- Set browser zoom to 100%. A 1440 × 900 desktop viewport or 390 × 844 phone viewport works well.
- The seeded history is synthetic demo data. Say so when showing Insights.

## A 90-second story

**0–15 seconds — the problem:** “I can solve a problem today and forget the approach next week. AnkiDSA helps me revisit what I learned.”

**15–40 seconds — capture:** Open Two Sum. Submit your own solution. After Accepted, the extension should acknowledge capture. Open it, add “Store each complement in a hash map. One pass, O(n).”, and save. You can also capture manually from the popup if you prefer to skip coding on camera.

**40–65 seconds — recall:** Open the app and refresh. Two Sum is due immediately. Begin a review, think through the approach, reveal your note, and choose Good. Its next review is tomorrow.

**65–80 seconds — collection:** Search for Two Sum. Open it to edit your note or follow its LeetCode link. The saved review date remains intact.

**80–90 seconds — progress:** Show Insights: successful recall, review history, and the activity grid. Explain that later reviews get farther apart when recall remains strong.

## Rehearse again

This resets only the local sample account's collection and history, including problems you added to that sample account:

```powershell
cd C:\SpringBoot\ankidsa
.\scripts\reset-demo.ps1
```

Refresh both clients afterwards. Other accounts are preserved. The endpoint is absent outside the demo profile.

## Android emulator

Build the x86_64 debug APK used for local verification:

```powershell
flutter build apk --debug --split-per-abi --target-platform android-x64 --dart-define=DEMO_MODE=true --dart-define=API_BASE_URL=http://10.0.2.2:8081
adb install -r build\app\outputs\flutter-apk\app-x86_64-debug.apk
```

Start the API with the demo launcher first. Android reaches it through `10.0.2.2`. This debug APK includes debugging symbols and is larger than a signed release.

The `AnkiDSA_Demo_64` emulator is available on this machine for this APK. Its native sign-in, review, statistics, and session restoration have been tested. Start it from Android Studio's Device Manager, then open AnkiDSA and use the sample account. The older 32-bit emulators cannot run this x86_64 APK.

For a USB-connected ARM phone, build with `--target-platform android-arm64` and `API_BASE_URL=http://localhost:8081`, then run `adb reverse tcp:8081 tcp:8081` and install `app-arm64-v8a-debug.apk`. The local API listens only on the computer's loopback interface.

## Stop and rebuild

Use `.\scripts\stop-demo.ps1` from the Flutter project to stop processes started by the launcher. After code changes, start again with `-Rebuild`. Local data survives a restart.

After rebuilding both web and Android artifacts, run `.\scripts\package-demo.ps1` to refresh the complete local ZIP. The script packages selected built files and documentation, excluding local databases, mailboxes, secrets, and private backups.

## Troubleshooting

Password recovery is available from **Forgot your password?**. In this local demo, emails are written as `.eml` files under `C:\SpringBoot\ankidsa\.local\outbox`; no email is sent externally. Use a separate account to demonstrate recovery so the sample account keeps its documented password. Open the latest reset email for that account and copy its link into Chrome. Links expire after 30 minutes and work once.

Phone reminders appear only in builds configured with Firebase and connected to a backend with reminders enabled. They are not needed for this recording walkthrough.

- **Cannot reach the server:** check http://localhost:8081/health and `.work/backend.log`.
- **Nothing captured:** refresh LeetCode, check automatic saving is enabled, and press Submit again. Old Accepted results on page load are ignored.
- **Waiting to sync:** remain signed in. The extension retries every minute, or choose Try now. Pending notes are separated by server and account.
- **Session expired:** sign in again; pending notes remain in this browser.
- **Extension server denied:** keep the manifest public key unchanged, or allow your actual extension origin in backend `CORS_ORIGINS`.
- **Build runs out of memory:** close your other development builds, use the single-architecture Android command above, and avoid building Android and web simultaneously.
