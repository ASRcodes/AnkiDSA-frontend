# Daily review reminders

## Provider setup completed - 29 October 2026

Firebase project `ankidsa-1b561` belongs to the owner's `anufordevwork@gmail.com`
account. Android app `app.ankidsa.mobile` is registered as AnkiDSA Android.
The dedicated `ankidsa-fcm-sender` service account has only the Firebase Cloud
Messaging API Admin project role. Its JSON key is kept in ignored local storage
and in a Render secret file, never in the APK, extension, web build, or Git.

A validation-only FCM request passed without sending a real notification.
The Render deployment `dep-dbh4glec6qcc73cib380` is live with notifications enabled;
health and database readiness return 200, auth options report dailyReminders=true,
and an unauthenticated reminder trigger is rejected with 401.

The public client configuration is generated into `config/production.local.json`.
Build with `scripts/build-android-release.ps1 -ConfigFile config/production.local.json
-ApkOnly`, retaining the existing beta signing key. `scripts/prepare-firebase.py`
checks that both downloaded files belong to this project and package.

Physical-phone receipt and tap-to-queue verification remain pending. Provider
validation is not evidence that Android displayed the notification. The owner
will install the new signed APK manually. The GitHub scheduler's readiness wait
now permits 180 seconds, including when Render returns immediate 503 responses.

## What the reminder does

- The scheduler checks each registered account's due and overdue questions.
- A morning notification invites the user to view today's questions. Tapping it
  opens and refreshes the signed-in account's review queue, with the exact
  questions, problem links, and saved approach notes.
- It does not send a daily reminder when the account has no questions due.
- Repeated scheduler runs share a per-device daily delivery record. Transient
  failures retry; questions completed before a retry no longer trigger a send.
- The current schedule makes four morning attempts: 06:33, 06:53, 07:13, and
  09:47 Asia/Kolkata. These are attempts for the same daily reminder, not four
  separate reminders. Delivery time depends on scheduling, network, and device.

## Phone verification before calling it working

1. Install the new signed APK over the existing app and sign in.
2. Open the account menu > Reminders, turn on Daily reminders, and allow Android
   notifications. The app must finish registering this phone with the backend.
3. Send a controlled test to this phone only. Check receipt with the app in the
   background and after swiping it out of recent apps. Android Force stop is a
   different state; open the app again after using it.
4. Tap the notification. Confirm it opens the correct account's up-to-date queue
   and lists the questions due today. Test again with the app already open.
5. Verify a scheduled morning delivery on a day with due questions, then confirm
   no further daily reminder is sent after the queue has been completed.
6. Turn reminders off and verify the phone is unregistered. Check sign-out and
   account switching so another account cannot receive the previous user's work.

Provider acceptance is not proof that Android displayed a notification. The owner
must confirm receipt on the physical phone before the trial's reminder check passes.

FCM is a no-cost Firebase product and does not require a Play Store listing:
https://firebase.google.com/pricing
https://firebase.google.com/docs/cloud-messaging/flutter/get-started
