# Startup and notification release - 29 October 2026

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

Remaining release checks: install the new FCM APK on a physical Android phone,
enable reminders, verify a targeted delivery/tap, and verify a scheduled morning
delivery. Live password recovery now passes the controlled-account flow and
actual inbox check below; a second actual recovery-message check remains. Store
publication remains deferred as previously planned.

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

Latest server deployment: `dep-dbh5j0lg1s2s73cvhvkg`, live at the same backend
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

## Live password-recovery verification

Brevo Free now sends recovery email through a verified sender and a restricted
transactional key kept privately in Render. On one temporary controlled account,
the real reset message was recorded delivered by Brevo and confirmed in its inbox.
Reset succeeded; old sessions and the old password stopped working; the new
password signed in; and reuse of the same reset token returned 400. The account
and its tracked temporary records were removed after verification. No existing
study-account password was changed.

The owner also confirmed direct provider test messages in two mailboxes. Those
messages are distinct from the one actual recovery flow above. A second actual
recovery-message check remains; the primary study address had no registered
account when checked, so its generic request response correctly sent no email.
