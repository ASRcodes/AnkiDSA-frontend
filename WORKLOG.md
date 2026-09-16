# AnkiDSA delivery status

Updated 16 September 2026.

Submission scope: complete and package the local demo/prototype using the URLs in DEMO.md. Production deployment and provider/signing configuration are deferred by the user and do not block this submission.

## Implemented

- Chrome extension: capture after a new Accepted result, manual capture, metadata extraction, editable notes, duplicate protection, persistent retries, and account isolation.
- Flutter: responsive review, collection, and Insights screens; consistent branding; password sign-in and recovery; refreshed shared data; create/edit/delete; notes and tags hidden until reveal; large-text layout fixes; readable errors. Web rendering assets are served locally.
- Backend: hashed passwords, private endpoints, validated URLs, transactional scheduling, stale-update protection, idempotent review retries, accurate statistics, migrations, and environment configuration. Recovery uses expiring, hashed, single-use tokens and revokes earlier sessions.
- Reminders: mobile opt-in, permission handling, token rotation, account-specific preferences, device ownership, logout/reset cleanup, and notification taps opening the queue. Delivery requires Firebase configuration.
- Delivery: isolated local sample data, start/stop/reset commands, app icons, extension ZIP, a packaged local demo, and recording/testing guides.

## Verified

| Check | Result |
|---|---|
| Java API, recovery, device, mail, and scheduling tests | 18 passed on H2 |
| Same Java tests and migrations V1–V4 | 18 passed on PostgreSQL 18 |
| Flutter regression tests | 15 passed |
| Dart analyzer | No issues |
| JavaScript unit tests | 3 passed |
| Chromium + extension + real API + Flutter workflow | 6 passed |
| Live LeetCode Accepted capture in normal Chrome | Confirmed by the user |
| Flutter web build | Passed |
| Android x86_64 debug APK build | Passed |
| Native Android 8/API 26 sign-in, recall/review, statistics, and session restoration | Passed with the updated APK |
| Demo launcher and sample reset | Passed |
| Sample sign-in and desktop/phone screenshots | Passed |

Browser tests cover signup, accepted capture, duplicate note preservation, Flutter recall/review/statistics, session persistence, content-script storage restrictions, offline edits across browser restart and account changes, and the complete recovery-link flow in an existing tab and across reload. LeetCode responses in these tests are controlled fixtures.

Recovery mail is tested with mocks, a loopback SMTP server, and the demo's local mailbox. Reminder tests use a fake push adapter; they verify denied permissions, token rotation, account switching during a pending registration, and notification-tap handling. Neither test setup establishes delivery through a production provider.

The native check used a dedicated 64-bit emulator and a separate test account. The user confirmed that a new Accepted submission is captured correctly in normal Chrome. Automated Chromium uses controlled fixtures because it encountered LeetCode's browser challenge.

## Evidence and delivery

- Local demo bundle: `.work/AnkiDSA-local-demo.zip`; packaging command: `scripts/package-demo.ps1`. It includes the built web app, backend JAR, extension, emulator APK, launchers, documentation, and a checksum manifest. Only selected public deliverables are packaged.
- Extension: `extension/`; ZIP: `.work/ankidsa-extension.zip`.
- Web app: `build/web/`.
- Android APK: `build/app/outputs/flutter-apk/app-x86_64-debug.apk`.
- Screenshots: `.work/app-queue.png`, `.work/app-collection.png`, `.work/app-insights.png`, `.work/app-mobile-insights.png`, `.work/app-review.png`, `.work/extension-saved.png`.
- Native screenshots: `.work/android-queue.png`, `.work/android-review.png`, `.work/android-restored-session.png`.
- Backend logs: `C:\SpringBoot\ankidsa\.local-reminder-tests.log` and `.local-postgres-tests.log`.
- Current browser and Flutter logs: `.work/browser-tests.log`, `.work/flutter-tests.log`, `.work/analyze.log`.
- Current native build/check logs: `.work/android-build.log`, `.work/android-smoke.log`.
- Instructions: `DEMO.md`, `TESTING.md`, `PRODUCTION.md`.

## Deferred beyond this submission

Production SMTP, Firebase production configuration, AWS deployment, production URLs, and Android release signing are outside today's scope. No secrets or configuration inputs are requested. The local demo uses its existing H2 configuration, localhost URLs, local recovery mailbox, and unsigned-for-release debug APK. Future deployment and provider checks are documented in `PRODUCTION.md`; they are not prerequisites for recording or submitting this prototype.

Original source snapshots are in `.work/backups/`. They contain the old credential and must remain private. No Supabase or other remote database was changed. PostgreSQL tests used an isolated local cluster, which has been stopped.

The final Android check completed at 17:17 IST. The dedicated emulator's test session was cleared and the emulator stopped; its updated APK remains installed for the next launch. The local API and web app remain running. The extension ZIP and APK were refreshed after the final code changes.
