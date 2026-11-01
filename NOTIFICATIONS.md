# Daily review reminders

## Current delivery setup - 1 November 2026

Firebase project `ankidsa-1b561` contains Android app `app.ankidsa.mobile`,
registered as AnkiDSA Android.
The dedicated `ankidsa-fcm-sender` service account has only the Firebase Cloud
Messaging API Admin project role. Its JSON key is kept in ignored local storage
and in a Render secret file, never in the APK, extension, web build, or Git.

The existing release certificate's SHA-1 and SHA-256 are registered in Firebase.
The public Android key is restricted to `app.ankidsa.mobile` and that certificate,
and to Cloud Logging, FCM Registration, Firebase Installations, and Firebase
Management APIs. Registration after these restrictions is verified on the owner's
physical phone.

A validation-only FCM request passed without sending a real notification.
The reminder backend `f6f36cb` is live on Render deployment
`dep-dbjjcqnb9u1s73e7a1o0` with notifications enabled;
health and database readiness return 200, auth options report dailyReminders=true,
and an unauthenticated reminder trigger is rejected with 401.

The public client configuration is generated into `config/production.local.json`.
Build with `scripts/build-android-release.ps1 -ConfigFile config/production.local.json
-ApkOnly`, retaining the existing beta signing key. `scripts/prepare-firebase.py`
checks that both downloaded files belong to this project and package.

On the previous APK `1.0.0+1`, the owner installed the app and enabled Daily reminders. Physical-phone
receipt and queue opening passed for targeted direct FCM sends with the app in
the foreground, in the background, and swiped away from recent apps. Turning
reminders off removed the active registration (count 0); re-enabling restored it
(count 1). No sends were attempted while reminders were off.

These tests used the configured FCM sender and real release app. They did not
exercise the backend's scheduled morning dispatch, due-question selection, or
daily deduplication. Those checks and sign-out/account switching remain pending.
The operations runner now permits five minutes of readiness waiting; Flutter
and extension readiness remain 180 seconds. APK `1.0.1+2` has passed build, signing
and automated checks; its physical-device acceptance is still pending.

## What the reminder does

- The scheduler checks each registered account's due and overdue questions.
- A morning notification invites the user to view today's questions. Tapping it
  opens and refreshes the signed-in account's review queue, with the exact
  questions, problem links, and saved approach notes.
- It does not send a daily reminder when the account has no questions due.
- Repeated scheduler runs share a per-device daily delivery record. Transient
  failures retry; questions completed before a retry no longer trigger a send.
- Supabase sends public wake requests at 06:30/35/40/45, 09:30/35/40, and
  11:30/35/40 Asia/Kolkata. The backend checks every minute while awake and accepts
  sends only from 06:30 until 12:00. These attempts share one daily delivery record.
- GitHub now performs a read-only audit at 12:47 IST; scheduling delays no longer
  control the morning sender. The audit also checks historical unfinished backlog.
- The test account had zero saved questions at the 1 November check. Registration
  alone does not create a due reminder; add real study questions first.

## Historical phone results and current remaining checks

The following phone results apply to APK `1.0.0+1`. A real temporary Supabase cron
job reached `/ready` successfully on 1 November and was removed afterward; this
verified the wake connection only, not scheduled delivery or a cold-host restart.

| Check on the owner's phone | Result |
| --- | --- |
| Release APK installation and registration with the restricted client key | Passed |
| Foreground receipt and opening the review queue | Owner confirmed |
| Background receipt and opening the review queue | Owner confirmed |
| Swiped-away receipt and opening the review queue | Owner confirmed |
| Opt-out removes registration; re-enable restores it | Active counts 0 then 1 |

Android Force stop is a different state from swiping away and was not tested;
open the app again after using Force stop. These results cover the tested phone,
not every Android device or permission configuration.

1. Install APK `1.0.1+2` and verify registration. Verify a scheduled morning
   delivery on a day with real due questions. Check repeated
   scheduler attempts do not create another daily reminder and that no further
   reminder is sent after the queue has been completed.
2. Check sign-out and account switching, including removal of the previous
   account's registration and opt-in for the next account.
3. Complete the real Accepted-submission and cross-client trial in TESTING-GUIDE.md.

Provider acceptance alone is not proof of display. The three direct tests above
include owner-confirmed receipt and queue opening; scheduled delivery still needs
its own provider, server, and phone evidence.

FCM is a no-cost Firebase product and does not require a Play Store listing:
https://firebase.google.com/pricing
https://firebase.google.com/docs/cloud-messaging/flutter/get-started
