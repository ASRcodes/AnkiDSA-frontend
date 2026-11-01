# Startup and notification release

## Current update - 1 November 2026

The live web release is Netlify `6ae73478c2249eb0795a76e8` from `c2fa574`.
Signed Android `1.0.1+2` is built and verified. Backend `f6f36cb`, including the
reminder and proxy fixes, is live on `dep-dbjjcqnb9u1s73e7a1o0`; health, feature
flags, audit authorization and automatic dispatcher startup passed live checks. See CURRENT-RELEASE.md for artifact hashes and CI.

Delayed GitHub jobs caused the repeated reminder failures after the morning
window. Supabase now provides ten morning wake requests, and a nonblocking
backend timer dispatches every minute while awake. GitHub performs a read-only
12:47 IST audit. One real temporary cron request returned HTTP 200/ready and was
removed; this was not a cold-host test or evidence of scheduled phone receipt.

The backend now uses extracted JAR packaging. The live deployment logged Spring
startup of 111.999 seconds and process time of 118.115 seconds. These observations
are not a controlled comparison against the historical cold-start measurement.
Client readiness remains 180 seconds; the operational runner allows five minutes.
No paid hosting was added. Phone acceptance of the new APK, scheduled due delivery
and the real cross-client trial remain pending; Play Store work follows that trial.

## Historical verification - 29 October 2026

The remainder records the prior release's evidence, timings and artifacts; current
versions and deployment identifiers are listed above and in CURRENT-RELEASE.md.

The saved-login screen previously waited for server verification before rendering.
Render Free spins down after inactivity; the previously observed server startup
was about 140 seconds, but Flutter and Chrome stopped readiness retries after
about 75-79 seconds, or sooner when the host returned immediate errors.

The app now renders the restored local session while the server verifies it.
Every protected request still requires server authorization; a 401 clears the
session and account data. Late verification cannot overwrite a newer login.
Readiness polling has a 180-second total deadline in Flutter, Chrome, and the
GitHub reminder runner. Only readiness probes retry automatically; writes are
not replayed after ambiguous failures. Loading text explains the wait.

The production web page starts a nonblocking readiness request while Flutter
downloads. The app can render even when that request fails. The Free plan still
sleeps, so this change does not promise instant server responses after inactivity.
No paid hosting or artificial keep-alive schedule was added.

Validation: Flutter analysis passed; all 26 Flutter tests, 3 JavaScript tests,
4 Firebase configuration tests, and 5 reminder scheduler tests passed. The
credential scan found no high-confidence findings. The production web build
completed; live index, startup script, compiled application, and Android App Links
association matched their local SHA-256 digests. The live sign-in screen rendered.

Client CI 40753563031 passed at source revision bc06712, including all six browser
flows and Android debug/release compilation. The corrected test input helper uses
ordinary keyboard events to keep Flutter's editing controller synchronized.

Initial Netlify startup deployment: 6ae2469fb5308518dd226b48.
Historical initial Firebase-enabled Render deployment: dep-dbh4glec6qcc73cib380,
at validated server revision c84f951ef0b0033f92c61ee74b23c776e64deb50. The scheduler-only
source update did not change that Java server. The latest deployment is recorded below.

Remaining release checks: scheduled morning delivery with due questions, daily
deduplication/no further sends after completion, physical-phone sign-out/account
switching, and the real Accepted-submission/cross-client trial. Direct phone
delivery and opt-out/re-enable passed as recorded below. Live password recovery
passed one complete controlled-account flow and actual reset-message inbox checks
for two mailboxes. Store publication remains deferred as previously planned.

## Additional server startup check

A read-only live call through the actual Flutter ApiService completed readiness
and auth-options loading in 177.8 seconds. Render's initialization log reported
146.299 seconds for Spring and 158.734 seconds of process time. This test exercised
the preceding server revision and did not create accounts or mutate study data.

Backend revision `0b6ed1d` removes one unnecessary BCrypt computation during
class initialization. Unknown/passwordless accounts still perform a valid cost-12
password check and receive the existing 401 response. Eighteen targeted tests and
full backend CI 40757324830 passed. No measured startup reduction is claimed for
this small optimization.

An isolated six-launch Java compiler benchmark did not support changing the JVM
compiler setting: median readiness was 29.70 seconds with the default and 39.05
seconds with C1-only compilation, with high variance; C1 warm BCrypt login was
about 19% slower. Production retains the existing compiler and memory settings.

Historical server deployment: `dep-dbh5j0lg1s2s73cvhvkg`, live at the same backend
revision `0b6ed1d`, with health/readiness 200 and both daily reminders and password
recovery enabled. The cold-start acceptance below ran on the preceding deployment
`dep-dbh540nlk1mc73f8vj70` of that revision, before email configuration changed.

## Live idle-sleep acceptance

The complete sign-in/load/mutation flow passed on `0b6ed1d` after 16 minutes
30 seconds without probe traffic. A fresh Flutter test process used the real
ApiService to sign in, verify identity, load an empty collection, create one
synthetic problem, reload and verify it, delete it, reload the empty collection,
and log out. Request observation confirmed exactly one problem-create POST.

Render logs show Spring starting at 20:17:52 UTC on 28 October, after the actual
client probe began at 20:17:24 UTC, and completing startup at 20:20:04 UTC. The
deployment ID remained unchanged, establishing a real cold restart. Spring took
141.603 seconds and the process took 154.003 seconds. Login completed in 183.8
seconds including readiness; its POST took 14.8 seconds. The full flow completed
in 195.2 seconds. These measurements show correct recovery after sleep, not a
controlled or demonstrated startup speedup.

The probe used one disposable account and synthetic study data. Cleanup required
its exact generated email and recorded account ID, removed its own session records,
and verified zero remaining scoped rows. The private probe credentials were removed.
This acceptance check exercised the real Flutter service code against production;
it does not replace the separate physical-phone and rendered-client checks.

## Physical phone notification verification

The signed APK was installed on the owner's phone and registered successfully
with the restricted Firebase Android key. The owner confirmed receipt and queue
opening for direct FCM tests in foreground, background, and swiped-away states.
Opt-out left zero active registrations; re-enabling restored one. No send was
attempted while reminders were off. The original APK and AAB were unchanged.

These direct FCM sends exercised the release app and sender configuration. They
do not establish backend scheduled dispatch, due-question selection, daily
deduplication, or no further reminders after queue completion. Those checks and
sign-out/account switching remain pending.

## Live password-recovery verification

Brevo Free now sends recovery email through a verified sender and a restricted
transactional key kept privately in Render. On one temporary controlled account,
the real reset message was recorded delivered by Brevo and confirmed in its inbox.
Reset succeeded; old sessions and the old password stopped working; the new
password signed in; and reuse of the same reset token returned 400. The account
and its tracked temporary records were removed after verification. No existing
study-account password was changed.

After registering the primary study account, the owner also confirmed its actual
reset message in the inbox. Its token was not read or redeemed and its password
was not changed. Actual reset-message inbox receipt is therefore verified for
two controlled mailboxes, while the complete password-change flow was exercised
only on the temporary account. Direct provider test messages were separately
confirmed in both inboxes.
