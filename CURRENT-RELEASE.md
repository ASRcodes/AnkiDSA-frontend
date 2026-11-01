# Current release - 1 November 2026

Web: https://ankidsa.netlify.app

API: https://ankidsa-backend.onrender.com

## Reminder incident and repair

From 29 October through 1 November, GitHub reminder jobs started after the
06:30–12:00 Asia/Kolkata delivery window. The backend correctly refused late sends;
the workflows failed and generated email without delivering a reminder. Earlier
phone tests exercised direct FCM sends, so they did not verify this scheduling path.

Supabase now has three wake jobs and one history-retention job. The ten public
`GET /ready` requests run at **06:30/35/40/45, 09:30/35/40, and 11:30/35/40 IST**.
They carry no credentials. After startup, the backend checks reminders every
60 seconds while awake, using the existing morning window, leases, retries and
daily delivery records. GitHub runs a read-only delivery audit at **12:47 IST**;
that audit may be delayed, and manual delivery remains restricted to the window.

The audit reports provider failures, missed morning execution, current pending
work, and the last batch's recorded backlog, including unstaged devices. A
successful wake request is not evidence that a phone received a notification.
The owner's study account had **zero saved questions** at the 1 November check, so no daily
reminder was due for that account. Add real study questions before the phone trial.

## Verified builds and deployments

| Artifact | Current verification |
| --- | --- |
| Android APK | **1.0.1+2**, source `c2fa5743ca0cf6674f4776a1671c535c8dc3b163`; 53,332,835 bytes |
| Android AAB | **1.0.1+2**, same source; 44,451,003 bytes |
| Web | Netlify `6ae73478c2249eb0795a76e8`, ready at `c2fa574`; deployed application/configuration/policy/App Links hashes verified |
| Backend, including proxy fix | `f6f36cb1cee40061ed8d325386ac395fe967e90b`, live on Render `dep-dbjjcqnb9u1s73e7a1o0`; health, feature flags, protected audit and dispatcher startup verified |

APK: `build/app/outputs/flutter-apk/app-release.apk`

SHA-256: `ee7e596767693df0d5636e6e3c3540de8197b1b5a517ca0a1fa6233a3075a462`

AAB: `build/app/outputs/bundle/release/app-release.aab`

SHA-256: `8a99dbf9cc0ca29c07beb998cd55350f8e5bb513b752b851eb296aaadab494e0`

Both Android artifacts retain the previous release signer; signatures, manifests,
Firebase resources, ARM64 contents and archive integrity passed verification.
The prior `1.0.0+1` artifacts are retained under `build/releases/android/1.0.0+1`.
Web ZIP SHA-256: `e718f78c2d819de4051771a684f9b7c20e0a0f90659650c5a8bee999350d19f4`.
The manual Chrome package remains `build/extension/ankidsa-extension.zip`.

Client CI [41307141997](https://github.com/ASRcodes/AnkiDSA-frontend/actions/runs/41307141997)
and backend CI [41307439070](https://github.com/ASRcodes/AnkiDSA-Backend/actions/runs/41307439070)
passed. Focused checks passed 34 Java, 17 Python and 32 Flutter tests; Flutter
analysis passed. Proxy-fix CI
[41308315930](https://github.com/ASRcodes/AnkiDSA-Backend/actions/runs/41308315930)
passed. The final deployment is live with `CLIENT_IP_MODE=render-cloudflare`;
login limits now use the verified public Render client header. Health and database
readiness return 200, both reminder/recovery flags are enabled, and unauthenticated
audit access returns 401. The first morning cycle after this evening deployment
remains a separate acceptance check.

A real one-off Supabase cron job ran on 1 November at 12:50 UTC and obtained
HTTP 200 with `status=ready`; the temporary job was removed. The four production
jobs remain active. The backend emitted its automatic-dispatcher-ready log.
This verifies the scheduler-to-API connection, not a cold-host wake or scheduled FCM receipt.

## Startup and previously verified flows

The app renders its restored session before remote verification; web warmup
runs alongside the Flutter download. Flutter and extension readiness waits remain
180 seconds; the operations runner now allows five minutes. Extracted backend
JAR packaging reduces class-loading overhead. The deployment above logged
111.999 seconds of Spring startup and 118.115 seconds of process time; this is a
deployment observation, not a controlled cold-start performance comparison.
Render Free still sleeps after inactivity.

On the previous APK, direct FCM receipt and queue opening passed on the physical
phone in foreground, background and swiped-away states. Opt-out removed registration;
re-enable restored it. Those results are historical and do not certify the new
APK's physical-device or scheduled-delivery behavior.

Brevo recovery remains configured privately. One complete controlled reset flow
verified single-use links and old-session/password invalidation; actual reset
emails reached two controlled inboxes. The existing study-account password was
not changed. Detailed historical evidence remains in STARTUP-FIXES.md.

## Remaining acceptance before public launch

1. Install APK 1.0.1+2, verify reminder registration and sign-out/account switching
   on the phone, then complete a real Accepted-submission/notes/review sync trial.
2. Verify morning delivery with real due questions, queue opening, daily
   deduplication and no further sends after completing the queue.
3. Complete the user trial in TESTING-GUIDE.md before broader distribution.
   Play Store publication is a later step, not completed by these builds.

Existing Free plans remain in use. Automated checks, live provider acceptance,
phone receipt and the user trial are separate verification stages; this record
does not claim production availability guarantees or completed public launch.
