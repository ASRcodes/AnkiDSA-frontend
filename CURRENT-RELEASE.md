# Current release - 29 October 2026

Web: https://ankidsa.netlify.app
API: https://ankidsa-backend.onrender.com

## Ready to use

- Web startup no longer waits for saved-session verification to render the app.
- Web starts waking the API while downloading Flutter. App, extension, and reminder
  runner use bounded 180-second readiness waits without replaying writes.
- Firebase Android registration, FCM-only service account, private Render secret,
  validation-only send, backend deployment, and GitHub morning schedule are configured.
- Signed notification-enabled APK: `build/app/outputs/flutter-apk/app-release.apk`.
  SHA-256: `E159EBC7422E4293AA1826570B11B071DDD451AD88767535DC04D33B41542D9D`.
  Existing beta signing certificate retained. Size: 53,332,767 bytes.
- Matching signed AAB: `build/app/outputs/bundle/release/app-release.aab`.
  SHA-256: `604BEB233BBB68D9C3605D8779F6F55D45266C47E80371FB7D42A5BB0C40AF3E`.
  Size: 44,446,644 bytes. Signature, packaged Firebase resources, notification
  declarations, and archive integrity verified. The APK above was not replaced.
- Password recovery is enabled through Brevo Free; one controlled live reset flow
  and its actual reset-email inbox receipt are verified.
- Updated manual-install Chrome ZIP: `build/extension/ankidsa-extension.zip`.
- Privacy/support pages describe optional Firebase token processing and live
  password recovery through Brevo.

## Live verification

Render deployment `dep-dbh5j0lg1s2s73cvhvkg` is live at backend revision `0b6ed1d6d3e028ce66060e3f39d7a840861d1cd2`. Health and database readiness
return 200; dailyReminders=true and passwordRecovery=true. An unauthenticated
reminder trigger is rejected with 401.
The authenticated trigger returns outside_window at this time of night, without
sending a notification. GitHub repository REMINDERS_ENABLED=true is verified.
Morning attempts remain 06:33, 06:53, 07:13 and 09:47 Asia/Kolkata, with daily
deduplication per registered device. First scheduled delivery still needs verification.

Latest Netlify deployment: `6ae25b6f54976c7dec32d872`, ready. The updated privacy
and support pages cover Brevo password recovery and match the built files. The
compiled application, index, startup script, and public App Links association
remain unchanged, with their deployed hashes verified.

The release certificate's SHA-1 and SHA-256 are registered in Firebase. The Android
client key is restricted to `app.ankidsa.mobile` and the release SHA-1, with only
Cloud Logging, FCM Registration, Firebase Installations, and Firebase Management
APIs allowed. These match [Firebase's required API guidance](https://firebase.google.com/docs/projects/api-keys).
Physical-phone registration after this restriction is still pending.

Client CI [40753563031](https://github.com/ASRcodes/AnkiDSA-frontend/actions/runs/40753563031)
passed for `bc06712a311efa54f36325a7e6e086dd5f525698`: analysis, 26 Flutter tests,
3 JavaScript tests, web build, all six browser flows, and Android debug/release
compilation. Four Firebase configuration tests also passed locally. Backend CI
[40752429357](https://github.com/ASRcodes/AnkiDSA-Backend/actions/runs/40752429357)
passed for the scheduler fix `6e60f84`, including five scheduler tests. The subsequent backend startup change
`0b6ed1d` passed full CI [40757324830](https://github.com/ASRcodes/AnkiDSA-Backend/actions/runs/40757324830),
including PostgreSQL, production TLS, and Docker startup checks. It replaces
startup-time BCrypt dummy-hash generation with a precomputed cost-12 value while
preserving the per-login password check for unknown accounts.

The full cold-start flow passed on backend revision `0b6ed1d` after 16 minutes
30 seconds without probe traffic. A fresh Flutter process used the actual ApiService
to sign in, verify the account, load its collection, save one synthetic problem,
reload, delete it, reload again, and log out. Exactly one create request was sent.
Render logs confirmed a new process after the client probe began, on the same
deployment. The generated account and its dependent records were removed with an
exact account-ID/email guard; all scoped cleanup counts were zero.

Login took 183.8 seconds including readiness; the login POST itself took 14.8
seconds, and the complete flow took 195.2 seconds. Spring startup took 141.603
seconds (154.003 seconds of process time). This verifies successful recovery after
idle sleep; it does not establish a startup speedup. A prior read-only probe on
the preceding revision took 177.8 seconds, but these are not controlled benchmarks.
Free-host cold starts remain slow despite prompt local rendering.

## Live password recovery

Brevo Free is configured with a verified sender and the restricted transactional
key `ankidsa-password-recovery`, stored privately in Render. The application caps
mail attempts at 250 per rolling 24 hours. The key expires on 28 October 2027 and
can become inactive after 90 days without use; see DEPLOYMENT.md for rotation.

One temporary account on a controlled secondary mailbox completed the live flow:
the actual reset message was delivered by Brevo and confirmed in the inbox, reset
succeeded, earlier sessions and the old password were rejected, the new password
worked, and token reuse returned 400. The temporary account was removed afterward.
The owner's study password was not changed. Direct provider test messages also
reached two controlled inboxes; these do not establish two actual reset flows.
The primary study address was not registered at verification, so its generic
forgot-password response correctly sent no email. The owner will create that
account before testing it.

## Remaining owner and release checks

1. Install the new APK, sign in, and enable account menu > Reminders > Daily reminders.
   Allow Android notifications. The owner will install manually.
2. Verify a targeted notification on the owner's registered phone, background receipt,
   and tap-to-queue. No real push has been sent yet; provider validation is not receipt.
3. Verify an actual recovery message for a second registered controlled mailbox.
   One full live reset and its inbox receipt passed; the two direct provider test
   emails are separate evidence. The owner will create the primary study account
   before this check.
4. Complete the phone checks in NOTIFICATIONS.md: foreground/background/swiped-away
   receipt, tap to the correct queue, scheduled morning delivery with due questions,
   no further daily sends after completion, opt-out and account switching.
5. Finish the current real Accepted-submission and phone cross-client trial in
   TESTING-GUIDE.md. Previous controlled-page tests do not prove real live capture.

The existing Free hosting plans remain in use. Render still sleeps after inactivity;
the startup fixes improve rendering and recovery but do not eliminate host wake time.
Store publication remains deferred as previously planned. Older LIVE-STATUS.md sections
are historical; see NOTIFICATIONS.md and STARTUP-FIXES.md for this release.
