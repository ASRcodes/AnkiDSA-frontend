# AnkiDSA deployment status - 2026-10-15

Web: https://ankidsa.netlify.app
API: https://ankidsa-backend.onrender.com

Both are deployed. Netlify uses the existing Free team with paid overages disabled.
Signup remains public by request. Follow TESTING-GUIDE.md for the owner's first
week of web, extension, and physical-phone testing with one shared account.
Render deployed backend commit 499d3690f86f7a55c94e9416491bd6480ac7585d. Its
/health and database-backed /ready endpoints return 200. Exact CORS origins are
https://ankidsa.netlify.app and chrome-extension://bafnmcdkpidnpollodebmifggmmpkbje.

## Database and backend

The Supabase tenant-routing error is fixed. The existing public schema was backed
up outside the repositories with Windows DPAPI encryption, restored locally,
compared with V1, and rehearsed through V5 before applying the migrations remotely.
Original accounts, problems, and review values were verified unchanged. Temporary
plaintext backup/rehearsal copies were removed; the verified encrypted backup remains.

Public API grants were revoked on the 11 app tables and 3 ID sequences. Supabase's
anon/authenticated roles can no longer read or modify them directly. The backend
uses JDBC and continued to work after this change. Project-wide defaults remain
unchanged; review grants whenever future migrations add tables.

46 Java tests and 3 Python tests passed locally. The full GitHub validation run
38719029107 passed, including PostgreSQL/TLS and Docker startup. Nineteen live API
checks passed, including registration, login, create/edit/delete, scheduling,
idempotent reviews, stats, logout revocation, and extension CORS.

## Web, extension, and logo

The new shared logo is integrated into Flutter, web favicons/PWA icons, Chrome
popup/toolbar icons, Android launcher/adaptive/themed/notification icons, and iOS
icon assets. Editable SVGs, PNGs, wordmarks, and a preview sheet are in branding/.
The portable kit is build/branding/ankidsa-brand-kit.zip. iOS artwork is prepared;
no iOS binary was built on this Windows machine.

The production web build uses the real API, bundled fonts/CanvasKit, security
headers, and SPA routing. Netlify's optional injected badge is disabled. The APK's
public certificate association is served as JSON at /.well-known/assetlinks.json.
The static ZIP deployment uses an exact internal rewrite because Netlify's ZIP
importer omitted the hidden .well-known directory.

Flutter analysis and all 19 tests passed. Seven live browser checks passed with
zero JavaScript or browser console errors:
extension signup/save, Netlify login and synced queue, note reveal/review,
scheduling/session persistence, mobile route refresh, sync back to the extension,
and logout revocation. These checks used a deterministic LeetCode fixture while
all app/API requests reached the live services. A separate read-only check on the
real LeetCode Two Sum page also passed. No real code submission was automated.
Disposable verification accounts were removed and original study data rechecked.
The activity legend uses drawn color swatches, keeping its symbols within the
bundled font coverage and avoiding external fallback-font requests.

Client GitHub run 38723766919 passed on commit f374d6c: analysis, 19 Flutter tests,
3 JavaScript tests, all 6 browser integration tests, production-validation web
packaging, and Android debug/release compilation. Browser automation now waits
for Flutter's native input focus and verifies entered values, fixing dropped
characters on the clean CI runner. CI uses disposable services and signing keys;
use the production artifacts listed below for the phone trial.

## Phone and Chrome testing

Signed APK: build/app/outputs/flutter-apk/app-release.apk (50.9 MB).
Package: app.ankidsa.mobile, version 1.0.0+1; ARM64, ARMv7, and x86_64.
The existing AnkiDSA Beta signing key was retained and APK verification passed.
The manifest and Netlify association use the same certificate and web hostname.
Configuration: config/study-beta.example.json, with push explicitly disabled.

Extension ZIP: build/extension/ankidsa-extension.zip. It contains the real API/web
URLs and no localhost permissions. Extract it and use Chrome > chrome://extensions
> Developer mode > Load unpacked. The stable extension ID is
bafnmcdkpidnpollodebmifggmmpkbje. It has not been published to the Chrome Web Store.

Chrome Web Store publication is deferred by the owner. Distribution is by the
manual-install ZIP above, which includes INSTALL.txt and the finalized privacy
policy. Its public manifest key keeps the allowed extension ID consistent across
installations, so recipients need no new Item ID or backend settings. Each person
creates their own AnkiDSA account. Updates are installed manually.

The optional Store submission kit remains at build/chrome-web-store/ for future
use; it is not the ZIP to share for manual installation. No Google submission or
review is pending. The public privacy and support pages are live at
https://ankidsa.netlify.app/privacy/ and https://ankidsa.netlify.app/support/.
Publisher: Anubhav Singh; support: rajsinghrajput7002@gmail.com.

No physical phone is connected here. Install the APK on your phone and test with
the same account used on the web/extension. Confirm capture after an actual accepted
LeetCode submission while signed in. Push and password-recovery email remain
disabled pending Firebase and verified email-provider setup. Play Store publication
is deferred until phone/system testing is complete.

The original IMPLEMENTATION-REPORT.md is historical. Do not distribute its older
.invalid validation artifacts. Current artifacts use the actual HTTPS services.
