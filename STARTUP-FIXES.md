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

Initial Netlify startup deployment: 6ae2469fb5308518dd226b48.
Firebase-enabled Render deployment: dep-dbh4glec6qcc73cib380, live on the existing
validated server revision c84f951ef0b0033f92c61ee74b23c776e64deb50. The scheduler-only
source update does not change the deployed Java server.

Remaining release checks: install the new FCM APK on a physical Android phone,
enable reminders, verify a targeted delivery/tap, and verify a scheduled morning
delivery. Password-recovery email still needs the planned verified email-provider
setup. Store publication remains deferred as previously planned.
