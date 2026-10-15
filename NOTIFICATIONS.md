# Daily review reminders

Reminders are a release requirement for the owner's full-system trial. The live
API and existing APK still have notifications disabled until Firebase setup and
a real-phone delivery check are complete. Firebase project: `ankidsa-1b561`.

## Connect Firebase

1. In Firebase Project settings > General, register an Android app with package
   `app.ankidsa.mobile`. Download its `google-services.json`.
2. In Project settings > Service accounts > Firebase Admin SDK, generate a private
   key for the project. Keep it out of chat and source control.
3. Save both files in `C:\Users\rajsi\ankidsa\.work\firebase`, named
   `google-services.json` and `firebase-service-account.json`.
4. Run `python scripts/prepare-firebase.py`. It checks that both files belong to
   the same Firebase project and selects the correct Android application. It
   writes only public client values to ignored `config/production.local.json`.
5. Verify FCM access with a validation-only request. Upload the Admin SDK key to
   Render as a secret file and configure `FIREBASE_PROJECT_ID`,
   `GOOGLE_APPLICATION_CREDENTIALS`, `REMINDER_TRIGGER_SECRET`, and
   `NOTIFICATIONS_ENABLED=true`. Deploy the verified backend revision.
6. Build the signed APK with `scripts/build-android-release.ps1 -ConfigFile
   config/production.local.json -ApkOnly`. Use the existing signing key so the new
   APK can update the previous installation.

The backend repository's `reminders` environment has been prepared for `main`,
with its API URL and separate trigger secret. `REMINDERS_ENABLED` remains off
until provider configuration passes. Do not put the Firebase Admin SDK key in
the client configuration, extension ZIP, or any public build.

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
