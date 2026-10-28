# Your first week with AnkiDSA

Open the web app at https://ankidsa.netlify.app. The web app, Chrome extension,
and Android APK all use https://ankidsa-backend.onrender.com and the same account.
See [CURRENT-RELEASE.md](CURRENT-RELEASE.md) for the current APK, release status,
and remaining checks. Firebase is configured for the new Android build; physical-phone
delivery still needs verification. Password-reset email is enabled through Brevo;
one controlled live reset and its actual inbox receipt passed. A second actual
recovery-message check remains in the release checklist.

## Set up your account once

1. Open the web app and choose the account-creation option on the sign-in screen.
2. Enter your name, your own email, and a unique password. Save the password in
   your password manager. Use Forgot password if you need to recover an existing account.
3. If you already created an account with that email, sign in to it instead.
4. Use exactly that account on Chrome and your phone. Do not register a separate
   account for each device. Problems and reviews belong to the signed-in account.

You can be the first active tester of this release. The database already had two
account records before this deployment; they were preserved. Automated verification
accounts were removed. Existing IDs do not affect your ability to use the app.

The public URL does not make your study data public: the API requires your login.
Signup remains public, as you requested. You can use it alone for your trial by
waiting until the week is over to share the link, but other visitors can still
create their own accounts.

## Recover an existing account

Choose Forgot password and enter the exact email used when creating your AnkiDSA
account. Check the inbox and spam folder for "Reset your AnkiDSA password". Links
expire after 30 minutes and work once. After resetting, sign in again on your other
clients and re-enable reminders if needed; earlier sessions and device registrations
are invalidated. A generic request acknowledgement does not confirm that an account
exists or an email arrived. Create an account first if you have never registered.
Do not share your password or reset link when reporting a problem.

## Install the Chrome extension on your computer

1. Open Chrome and enter `chrome://extensions` in the address bar.
2. Turn on **Developer mode**, then click **Load unpacked**.
3. Select `C:\Users\rajsi\ankidsa\build\extension\live-unpacked`.
   Alternatively, extract `build\extension\ankidsa-extension.zip` and select
   the extracted directory containing `manifest.json`.
4. Pin AnkiDSA from Chrome's Extensions menu and open its popup.
5. Sign in with the same email and password as the web app.
6. Refresh any LeetCode tabs that were already open before installation.

Keep the extracted directory in place while you use the extension. On another
computer, copy the ZIP and extract it there. This is a testing installation; it
has not been published in the Chrome Web Store. For this trial, install the
extension in desktop Chrome and use the Android app on your phone.

Chrome Web Store publication is deferred by your choice. Use the manual ZIP for
your trial and for sharing with others; it needs no Store registration or fee.
`INSTALL.txt` inside the ZIP has portable setup and update instructions. Each
person should create their own AnkiDSA account. No Store Item ID or backend change
is needed for this package. Updates are manual: sync pending notes, replace the
files in the same installed folder, click Reload on AnkiDSA at
`chrome://extensions`, and refresh LeetCode.

## Install the Android app on your phone

1. Transfer `build\app\outputs\flutter-apk\app-release.apk` to your phone by
   USB, cloud drive, or another file-transfer method you normally use.
2. Open the APK from your phone's Files app. If Android asks, allow that Files app
   to install this APK, then complete installation. You can turn that permission
   off afterward.
3. Open AnkiDSA and sign in with your existing account. Internet access is needed
   for signing in and syncing reviews.
4. Check that the AnkiDSA logo appears on the launcher and the app opens normally.
5. If Android refuses the installation, record the exact message and your Android
   version. Do not erase an older installation containing unsynced work just to
   bypass an installation error.

The APK supports Android 7.0 and later. It is signed for this beta and does not
require a Play Store listing. No physical phone was available during automated
verification, so this installation and device test are still required.

To test the new reminders, open the account menu > Reminders, turn on Daily
reminders, and allow Android notifications. Wait for registration to finish.
Follow [NOTIFICATIONS.md](NOTIFICATIONS.md) to check background receipt, taps,
scheduled delivery, opt-out, and account switching. A configured provider or a
successful registration does not by itself prove the phone displayed a reminder.

## First complete test: computer to phone and back

Use one easy problem, such as Two Sum, and perform these steps in order.

| Step | What you do | What should happen |
| --- | --- | --- |
| 1 | Sign in on the web, extension, and phone. | All three show the same account and collection. |
| 2 | On LeetCode, submit a correct solution and wait for Accepted. Keep automatic capture enabled in the extension. | The problem appears in AnkiDSA once. |
| 3 | Open the extension while that LeetCode tab is active. Add a short explanation of your approach and save. | A saved confirmation appears. |
| 4 | Refresh the web app, then reopen or refresh the phone's collection. | The title, difficulty, tags, and notes match. |
| 5 | Begin a due review. Try recalling the approach before choosing Reveal my notes. | Your notes stay hidden until you reveal them. |
| 6 | Choose an honest review rating, such as Good. | The review completes and a next-review date appears. |
| 7 | Refresh the other clients. | Due counts and the scheduled date agree. |
| 8 | Close and reopen the web page and Android app. | Your saved collection and review remain available. |
| 9 | Submit the same problem again on LeetCode. | It does not create a duplicate or erase your saved notes. |
| 10 | Sign out of the extension, then sign back in. | The extension asks for credentials after sign-out; your collection returns after sign-in. |

If automatic capture does not happen, first refresh the LeetCode page and check
that the extension is signed in and automatic capture is on. Record the problem
URL and whether Accepted appeared after a new Submit click. You can use the
extension's capture/save control to continue studying while reporting the issue.
Automatic capture after a real signed-in submission is one of the checks that
still needs your browser; automation used a controlled LeetCode test page.

## A practical seven-day trial

Choose a convenient 10–15 minute review session. You can enable Daily reminders
in the new Android build; use a phone alarm as a backup while notification delivery
is being verified. Reminders apply only when questions are due. Review what is
actually due; do not change your device clock or force a problem to become due
for a test.

| Day | Focus |
| --- | --- |
| 1 | Install all clients, finish the complete test above, and add 2–3 real problems with useful notes. |
| 2 | Review the due queue on your phone. Check the same results on the web and extension. Add one new problem if useful. |
| 3 | Use the web for reviews. Edit one note in the extension and confirm the update on the phone after refresh. |
| 4 | Test the extension's offline notes: open an already saved problem, disconnect, edit and save a note, close/reopen Chrome, reconnect, and confirm it syncs to your same account. |
| 5 | Check Schedule and Insights against the reviews you completed. Open the web app at a narrow phone-sized width and check that controls remain usable. |
| 6 | Restart your phone and browser, then sign back in if asked. Continue your ordinary study session and look for missing or duplicated work. |
| 7 | Finish the due queue. Review your issue log and decide whether capture, syncing, reviews, and mobile usability have been reliable enough to expand the beta. |

The offline check above applies to extension notes. Do not assume offline phone
reviews will sync: that behavior has not been verified. A session may expire and
ask you to sign in again; that should not delete saved study data.

## Record issues without losing the useful details

Use `build\releases\one-week-test-log.csv`, or a note with these fields:
date/time, device and browser/Android version, action, expected result, actual
result, and problem URL. Mark each day Pass, Fail, or Not tested. Do not include
your password, API keys, or session tokens.

If a save appears to time out, refresh once and check whether it was saved before
repeating the action. If the app says the server is waking, let it finish and
retry when prompted. For a sync issue, confirm the email is the same on every
client, then record which client has the correct value.

Ready to expand means: real Accepted capture works, notes and reviews survive
restarts, the same account stays consistent across clients, and no unresolved
issue can lose or mix up study data. Complete the physical-phone and scheduled
Firebase delivery checks and the remaining second-mailbox recovery check before treating this
release as complete. Store publication remains deferred; broader device coverage
should be recorded separately from the devices actually tested.
