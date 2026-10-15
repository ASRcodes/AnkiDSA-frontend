> Historical local implementation report. The subsequent Render deployment and new shared logo are recorded in [LIVE-STATUS.md](LIVE-STATUS.md). Web hosting now targets Netlify.

# AnkiDSA beta implementation report

Repository-local implementation and the available local tests/builds are complete for the approved $0 beta architecture. **This is not yet a verified live production deployment.** No external deployment, publication, provider purchase, live email, live push, or Supabase migration has been performed. Real URLs have not been allocated. The generated release checks therefore use explicit `.invalid` validation origins; do not distribute those binaries to real users.

## Baseline recovered from the current repositories

Frontend baseline `a982409` (`AnkiDSA-frontend`); backend baseline `b3d425a` (`AnkiDSA-Backend`). Existing code already provided BCrypt/password login, JWT account identity/versioning, single-use hashed reset tokens, problem CRUD and ownership checks, SM-2 reviews with optimistic versions/request UUIDs, statistics, responsive Flutter screens, Android reminder opt-in/token updates, and an MV3 extension with a persistent offline queue. Those functions were extended and preserved, not rebuilt.

The audit covered Flutter Web/Android, Java/Maven/Docker, entities/repositories/transactions, V1–V4 SQL, auth/recovery/FCM, scheduled work, scripts, tests, environment examples, existing assets and docs. The current application does not use Supabase Auth, Google OAuth, refresh tokens, Crashlytics, or web push. Existing study data must all be retained; remote database identity/schema/history could not be inspected without the owner's connection.

## Implemented features

- Production/staging/development profiles; strict HTTPS/TLS origins, environment secrets, small connection pool, bounded server/container settings, graceful shutdown, structured production logging and safe error handling.
- Readiness `/ready` plus liveness `/health`; request IDs/size limits, strict CORS, secure headers, bounded auth rate limits and explicit proxy trust configuration.
- JWT issuer/session IDs/lifetime checks, individual server-side session revocation, single-use recovery, password hashing/ownership preserved. Client logout revocations retry after reconnect; storage writes are serialized to prevent logout/login races.
- Additive V5 coordination schema; explicit read-only verification and approved migration entry points; hosted startup does not apply Flyway automatically. Tests refuse hosted/non-test database targets.
- Firebase Admin SDK notification interface, bounded HTTP/send timeouts, generic private payloads, transient retries and invalid-token cleanup. Android background handler, foreground banner, notification channel/icon, permission/token rotation/tap/logout/re-login handling.
- Authenticated external reminder endpoint and GitHub schedule, renewable PostgreSQL job lease, fenced per-device/day delivery ledger, claim recovery and bounded retries. No reliance on a sleeping JVM cron.
- Brevo HTTPS provider behind the existing mail abstraction; bounded retries, database-coordinated rolling quota and a provider rate-limit pause. Reset tokens remain hashed/short-lived/single-use and are absent from application logs.
- Problem notebook/detail view, revision timeline, profile/security/reminder settings, skeleton loading, cold-start feedback, foreground reminder action, routable collection/insights/schedule/settings and unknown-route recovery. Existing green/paper identity, fonts, icons and review design are retained.
- Hosted clients probe readiness before mutations; ambiguous writes are not automatically replayed. Cloudflare build preparation adds security/cache headers, local font/CanvasKit serving and SPA refresh fallback.
- Android release signing from private local/environment inputs, HTTPS-only release networking, API 36, R8/resource shrinking and provider-hosted App Links preparation.
- Extension release packager with an explicit allowlist, pinned public API origin/CSP/host permissions, no development host grants, stable existing extension ID, cold-start handling and remote logout revocation.
- Non-root Java 21 Docker build with health probe and memory settings; PR/main validation, browser integration, Docker validation, manual deploy and authenticated reminder workflows. Production secrets are absent from PR jobs.

## Verification ledger

| Check | Confirmed result |
|---|---|
| Backend H2 suite | 32 passing tests at the completed hardening checkpoint |
| Final backend Maven verify | **36 passed, 0 failures/errors/skips**, with disposable PostgreSQL 18 and the local TLS production-profile check enabled; JAR built |
| Production profile/TLS smoke | Included in the 36: read-only local PostgreSQL startup, readiness, HTTPS header, CORS and disabled docs |
| Reminder trigger Python tests | 3 passing: busy/retry handling, bounded backlog, disabled-run failure, redacted output |
| Flutter tests | 19 passing, including cold-start writes, auth storage/logout race, device cleanup and large-text layout |
| Flutter analyze | Final source analysis passed with no issues |
| Production web build | Final release build passed; self-hosted assets, Pages headers/fallback and file-limit validation passed with `.invalid` API |
| Browser integration | **6 passed**: capture/notes/review/reload, content-script isolation, offline restart/account isolation, logout revocation, recovery/replay prevention; includes Schedule direct route/refresh and Settings navigation |
| Final UI verification | 2 large-text/compact-layout tests passed after the final heading semantics change; current mobile Schedule/Settings screenshots inspected |
| JavaScript unit tests | 3 passed |
| npm audit | 0 reported vulnerabilities (not a full dependency or penetration audit) |
| Live LeetCode | Read-only extraction of Two Sum/EASY passed; authenticated submission capture remains manual |
| Credential scan | No high-confidence credentials found in tracked/unignored source and both Git histories; redacted scanner has limited patterns |
| Workflow YAML / Python | YAML parsed; Python scripts compile; scheduler unit tests pass |
| Android debug | APK build passed; no physical-device runtime result is claimed |
| Android signed release | Final APK and AAB builds passed; APK signature and AAB JAR signature verified, ZIP integrity passed, ARM64/ARMv7/x86_64 present |
| Android packaging | App ID `app.ankidsa.mobile`, version `1.0.0+1`, target/compile API 36, minimum 24; release network resource forbids cleartext; 16 KiB ZIP alignment check passed (not a full ELF/device compatibility certification) |
| Extension package | Allowlisted MV3 ZIP produced; manifest/host permissions, archive integrity and validation marker checked |
| Docker image/runtime | Not tested locally: Docker is not installed; CI defines build/startup validation |
| Real providers | Not tested: accounts, approved sender, URLs, service-account/client configuration and devices pending |

Checks completed on 2026-09-24. Test logs are local under frontend `.work/beta-*.log` and backend `.local-beta-complete.log`; generated outputs/logs are ignored by Git. The backend log records 36 tests and `BUILD SUCCESS`. The AAB verifier reports the expected self-signed-certificate trust/timestamp warnings for the local Android signing identity. Prior artifacts from August/September under ignored build/work folders are not evidence for this release.

Real errors discovered during validation were fixed and the affected checks rerun: FCM APNS configuration, Kotlin URI resolution, Android network-XML lint, browser tests using a now-revoked session, route-heading semantics, and asynchronous auth-storage/logout races. No real test failure remains in the completed local checks. Docker is unavailable on this machine, so image build/startup must pass the included GitHub workflow or another Docker-capable machine before launch.

## Security and migration limits

V1–V4 and the existing schema/model are preserved. V4 contains a legacy FCM-token clearing statement; if pending on Supabase it requires separate review. V5 adds tables/indexes without rewriting accounts/problems/reviews. An external verified backup, migration history reconciliation and Supabase Data API/RLS/grant review are mandatory owner actions before launch. No database reset, DROP, TRUNCATE or live restore was run.

The secret scan found no high-confidence committed keys; this is not proof that no credential ever escaped elsewhere. Create fresh independent JWT and reminder secrets, a dedicated Brevo API key and least-privilege Firebase key. Rotate any key previously copied to logs/chat/old snapshots/public files. Rotate the database password only after checking other consumers; changing a password does not mean recreating its data. Public Firebase client IDs and the extension public manifest key are not server secrets.

Never commit `.env`, private Firebase JSON, Brevo/JWT/trigger/deploy tokens, database passwords, keystores/passwords, backups/dumps or private outboxes. Private signing files were generated under `%USERPROFILE%\.ankidsa\signing-beta`, outside both repos, and must be backed up securely. An older signed APK may have a different certificate; no installed application was uninstalled or overwritten.

There are unavoidable beta limits: sleeping/quotas/suspension, delayed GitHub schedules, best-effort FCM, a crash window after FCM accepts a send but before the database records it, non-durable asynchronous email, web client-storage exposure to same-origin script compromise, and offline logout revocation pending reconnection/expiry. The ledger prevents ordinary concurrent duplicate reminders, not mathematically exactly-once external delivery. Failed configuration or sender approval is a launch gate, not a reason to introduce a paid service.

## Manual setup and deployment order

See [DEPLOYMENT.md](DEPLOYMENT.md) for exact dashboard menus, commands, environment variables/secrets, Firebase/FCM/Android setup, Supabase verification/backup/migration, Brevo sender approval, Render, Pages, GitHub scheduler, extension packaging, live smoke tests and rollback. [DEPLOYMENT-MAP.md](DEPLOYMENT-MAP.md) maps every component to its destination.

Order: review both repos → verify/back up existing Supabase → allocate URLs → Firebase/Brevo → approved additive migration → Render API → Pages web → signed Android/App Links → extension → scheduler → live smoke tests → private beta invitations. Expected origins are `https://YOUR-APP.pages.dev` and `https://YOUR-API.onrender.com`; names are not reserved. Android outputs are signed APK/AAB; extension ID remains `bafnmcdkpidnpollodebmifggmmpkbje`.

Monthly infrastructure target **$0**, mandatory one-time beta cost **$0**, within documented quotas and account eligibility. Custom domain, paid hosting/database, HA and public store publication are postponed. Do not enable paid overages.

## Intentionally untouched

All remote data/provider accounts; original V1–V4 migrations and legacy schema SQL; core problem/user/review models, repositories, SM-2 algorithm and study ownership model; original font/icon/splash assets and licenses; dependency manifests/lockfiles except where a verified required change is documented; existing private backups; unrelated user projects/processes. No commits, pushes, stores or deployments were performed.

## Final artifacts and file inventory

All client artifacts below are **validation only**, use `api.validation.invalid`, and need a fresh build after the real origins/Firebase configuration exist. No placeholder is a usable API URL.

| Artifact | Local path | Result |
|---|---|---|
| Signed APK | `build/beta/ankidsa-validation-only.apk` | 52,948,333 bytes; signature verified |
| Signed AAB | `build/beta/ankidsa-validation-only.aab` | 44,291,326 bytes; signature verified |
| Static web ZIP | `build/beta/ankidsa-web-validation-only.zip` | 11,159,448 bytes; upload contents at archive root after a real-config rebuild |
| Extension ZIP | `build/beta/ankidsa-extension-validation-only.zip` | 243,288 bytes; private/unpacked validation |
| Checksums | `build/beta/SHA256SUMS.txt` | SHA-256 for all four artifacts |
| Backend executable JAR | `C:\SpringBoot\ankidsa\target\ankidsa-backend-1.0.0.jar` | Java 21 package from final Maven verify |

The public signing certificate SHA-256 is `1c41b06ff91239e4faa441730510bf4623035836031ab6058d230c9ad52159fb`. Obtain the colon-separated format with `keytool` for Firebase/App Links. The private key/password stay outside both repositories. Nothing in `build/beta` should be committed.

The following inventory is relative to each repository root: **100 source/configuration/documentation files** across both repositories (47 modified, 53 created). Modified and newly created source files are listed separately; ignored build outputs, local test data and private signing files are excluded. Changes are intentionally uncommitted for review; no unrelated files were removed.

### Frontend — `C:\Users\rajsi\ankidsa`

Modified:

- `.gitignore`
- `README.md`
- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/example/ankidsa/MainActivity.kt`
- `android/app/src/main/res/xml/network_security_config.xml`
- `extension/PRIVACY.md`
- `extension/background.js`
- `extension/popup.js`
- `lib/constants.dart`
- `lib/main.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/login_screen.dart`
- `lib/screens/problems_screen.dart`
- `lib/services/api_service.dart`
- `lib/services/auth_service.dart`
- `lib/services/push_client.dart`
- `lib/services/reminder_service.dart`
- `lib/widgets/ui.dart`
- `scripts/serve-demo.cjs`
- `scripts/start-demo.ps1`
- `tests/extension.spec.cjs`
- `tests/recovery.spec.cjs`
- `web/index.html`

Created:

- `.env.example`
- `.github/workflows/checks.yml`
- `.github/workflows/deploy-pages.yml`
- `DEPLOYMENT-MAP.md`
- `DEPLOYMENT.md`
- `IMPLEMENTATION-REPORT.md`
- `android/app/proguard-rules.pro`
- `android/app/src/main/res/drawable/ic_notification.xml`
- `android/app/src/release/res/xml/network_security_config.xml`
- `config/production.example.json`
- `extension/config.js`
- `lib/screens/problem_detail_screen.dart`
- `lib/screens/schedule_screen.dart`
- `lib/screens/settings_screen.dart`
- `scripts/android-app-links.py`
- `scripts/build-android-release.ps1`
- `scripts/check-live-leetcode.cjs`
- `scripts/check-secrets.py`
- `scripts/create-signing-key.ps1`
- `scripts/package-extension.py`
- `scripts/prepare-web.py`
- `test/cold_start_test.dart`
- `test/session_security_test.dart`
- `web/flutter_bootstrap.js`

### Backend — `C:\SpringBoot\ankidsa`

Modified:

- `.dockerignore`
- `.env.example`
- `.gitignore`
- `DEPLOYMENT.md`
- `Dockerfile`
- `README.md`
- `src/main/java/com/ankidsa/AnkiDsaApplication.java`
- `src/main/java/com/ankidsa/config/AuthRateLimitFilter.java`
- `src/main/java/com/ankidsa/config/FirebaseConfig.java`
- `src/main/java/com/ankidsa/config/JwtAuthenticationFilter.java`
- `src/main/java/com/ankidsa/config/JwtService.java`
- `src/main/java/com/ankidsa/config/SecurityConfig.java`
- `src/main/java/com/ankidsa/controller/AuthController.java`
- `src/main/java/com/ankidsa/controller/HealthController.java`
- `src/main/java/com/ankidsa/exception/GlobalExceptionHandler.java`
- `src/main/java/com/ankidsa/service/AccountMailSender.java`
- `src/main/java/com/ankidsa/service/NotificationService.java`
- `src/main/java/com/ankidsa/service/PasswordRecoveryService.java`
- `src/main/java/com/ankidsa/service/SchedulerService.java`
- `src/main/java/com/ankidsa/service/SmtpAccountMailSender.java`
- `src/main/resources/application.yml`
- `src/test/java/com/ankidsa/ApiIntegrationTest.java`
- `src/test/java/com/ankidsa/PasswordRecoveryIntegrationTest.java`

Created:

- `.github/workflows/checks.yml`
- `.github/workflows/deploy.yml`
- `.github/workflows/reminders.yml`
- `docker/Healthcheck.java`
- `render.yaml`
- `scripts/check-secrets.py`
- `scripts/test_trigger_reminders.py`
- `scripts/trigger-reminders.py`
- `scripts/verify-database.sql`
- `src/main/java/com/ankidsa/DatabaseMaintenance.java`
- `src/main/java/com/ankidsa/config/ClientAddress.java`
- `src/main/java/com/ankidsa/config/HostedConfiguration.java`
- `src/main/java/com/ankidsa/config/ReminderTriggerFilter.java`
- `src/main/java/com/ankidsa/config/RequestSafetyFilter.java`
- `src/main/java/com/ankidsa/controller/ReminderJobController.java`
- `src/main/java/com/ankidsa/service/BrevoAccountMailSender.java`
- `src/main/java/com/ankidsa/service/FcmNotificationService.java`
- `src/main/java/com/ankidsa/service/MailBudget.java`
- `src/main/java/com/ankidsa/service/SessionRevocations.java`
- `src/main/resources/application-development.yml`
- `src/main/resources/application-production.yml`
- `src/main/resources/application-staging.yml`
- `src/main/resources/db/migration/V5__beta_delivery_coordination.sql`
- `src/test/java/com/ankidsa/DeliveryAdaptersTest.java`
- `src/test/java/com/ankidsa/HostedConfigurationTest.java`
- `src/test/java/com/ankidsa/HostedPostgresSmokeTest.java`
- `src/test/java/com/ankidsa/JwtSecurityTest.java`
- `src/test/java/com/ankidsa/ReminderIntegrationTest.java`
- `src/test/java/com/ankidsa/TestDatabaseGuard.java`
