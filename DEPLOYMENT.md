# AnkiDSA $0 beta deployment

This guide deploys the existing two repositories. Frontend: `ASRcodes/AnkiDSA-frontend` (this directory). Backend: `ASRcodes/AnkiDSA-Backend` (locally `C:\SpringBoot\ankidsa`). The backend is live at https://ankidsa-backend.onrender.com and the web app at https://ankidsa.netlify.app. See [CURRENT-RELEASE.md](CURRENT-RELEASE.md) for current verification and remaining checks, and [LIVE-STATUS.md](LIVE-STATUS.md) for earlier deployment history. Web and API publication and Firebase provider configuration are verified. Physical-phone and scheduled FCM delivery, verified Brevo email delivery, and the live beta accepted-submission capture checks remain pending.

**Do not upload validation artifacts to a live beta.** They use `https://api.validation.invalid`. Rebuild with the real provider URLs. Never paste secrets into chat, issues, screenshots, commit messages, Flutter defines, or extension configuration.

## Architecture and cost boundary

```text
Flutter Web → Netlify Free (*.netlify.app)
                       ↓ HTTPS
Flutter Android ───→ one Spring Boot / Java 21 API on Render Free (*.onrender.com)
Chrome extension ──→                    ↓ JDBC/TLS
                              existing Supabase PostgreSQL Free
GitHub Actions scheduled trigger → API → Firebase Admin SDK → FCM → Android
Password recovery → API → Brevo Free HTTPS API → verified recipient mailbox
```

| Component | Provider | Plan | Cost | Free-tier limitation | Fallback |
|---|---|---|---|---|---|
| Web | Netlify | Free, prebuilt static deploy | $0 | Existing team is on legacy Free; consult its usage dashboard. New credit-based Free plans have 300 credits/month | Build locally, preview before production; keep the previous artifact |
| API | Render | Free Web Service, one instance | $0 | 512 MB RAM, 0.1 CPU, 750 instance-hours/month; sleeps after 15 idle minutes; cold start roughly a minute; ephemeral disk | Wait/retry; suspension when quotas exhaust |
| Database | Existing Supabase | Free | $0 | 500 MB database, 5 GB egress; low-activity projects can pause after 7 days; no automatic downloadable backups | Resume in dashboard; external manual backups; stop writes at quota |
| Email | Brevo | Free | $0 | 300 sends/day, sender verification and account approval; no owned-domain authentication | App caps 250 attempts/rolling 24h; retry later, never charge |
| Push | Firebase | Spark / FCM | $0 | Best-effort push, device permission and connectivity required | In-app review queue |
| CI/scheduler | GitHub Actions | Free allowance | $0 | Private repos: 2,000 Linux minutes/month and 500 MB artifacts; schedules can be delayed/dropped | Local builds; manual workflow run; later scheduled retry |
| Android testing | Local APK / Firebase App Distribution | No-cost distribution | $0 | Tester invitation; APK distribution without Play; Firebase releases expire after 150 days | Sideload signed APK |
| Extension testing | Chrome | Unpacked ZIP | $0 | Developer-mode installation and manual updates | Reinstall unpacked folder preserving extension ID |
| HTTPS/domain | Provider subdomains | Included | $0 | URLs must be allocated before release rebuild | Keep provider URLs |

Estimated monthly infrastructure cost **$0**; mandatory one-time beta cost **$0**, within quotas and subject to free-account approval. No custom domain, paid email, database, always-on instance, or store account is required. Do not add billing cards, buy credits, enable overages, or upgrade to pass a setup gate. If a provider requires a payment method/account upgrade, stop that provider setup and keep the beta private while reassessing.

Netlify plan checked 2026-10-15; other limits last reviewed 2026-09-24: [Render Free](https://render.com/docs/free), [Netlify Free credits](https://docs.netlify.com/manage/accounts-and-billing/billing/billing-for-credit-based-plans/credit-based-pricing-plans/), [Supabase pricing](https://supabase.com/pricing), [Supabase pausing](https://supabase.com/docs/guides/platform/free-project-pausing), [Brevo Free limits](https://help.brevo.com/hc/en-us/articles/208580669-FAQs-What-are-the-limits-of-the-Free-plan), [GitHub Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions), [Firebase pricing](https://firebase.google.com/pricing).

## 1. Record revisions and preserve the database

1. In both local repositories run `git status --short` and `git rev-parse HEAD`. Review the changes and record the final release commit IDs in a private deployment log. Commit/push only reviewed source, never build outputs or credentials. Existing files under `.work/backups` are private historical snapshots, not deployment inputs.
2. Open **Supabase Dashboard → existing organization → existing project → Project Settings → General**. Record the project reference and region privately. Confirm the organization is on **Free**. Do not create a replacement project, reset it, delete it, or reset its password without assessing existing consumers.
3. Click **Connect → Session pooler** and select the PostgreSQL connection information. For Render IPv4 use the **session** pooler on **5432**, not transaction pooler 6543. Keep the supplied host and username (often `postgres.PROJECT_REF`). Put the password only in your local process environment/password manager and later Render.
4. Database environment: `DB_URL=jdbc:postgresql://SESSION_POOLER_HOST:5432/postgres?sslmode=require&connectTimeout=10&socketTimeout=30&tcpKeepAlive=true`, `DB_USERNAME` from Connect, `DB_PASSWORD` from your password manager. Prefer `sslmode=verify-full` after validating the provider CA/hostname locally. `DB_POOL_MAX=3` leaves room for administration; do not raise it blindly. Actual pooler capacity is project-specific; inspect **Database → Settings**. Supabase Free nano commonly provides 60 direct / 200 pooler client connections; a pooler client limit is not server throughput.
5. In **SQL Editor → New query**, run backend `scripts/verify-database.sql` as a read-only audit. If `flyway_schema_history` is absent, stop the migration procedure. Inspect the schema against V1–V4 manually. Do not baseline an unknown schema, use `ddl-auto=update/create`, or force checksums with Flyway repair. The script prints metadata and counts, not account rows; keep results private.
6. Inspect **Settings → Data API** and the audit's `anon`/`authenticated` grants. This application uses only Spring JDBC, not Supabase Auth/REST. If the project is dedicated to AnkiDSA, disable Data API exposure for these tables/schema. If shared, review grants and RLS with the existing consumers before changing them. Unauthenticated Supabase REST access to `users`, reset/device/session/delivery tables is a **launch blocker**. Never expose a database password or service-role key to clients. A dedicated runtime role restricted to the application tables is preferable; keep a separate migration role.
7. Create an external encrypted backup **outside either repository** using matching/newer PostgreSQL tools. In a private terminal set `PGHOST`, `PGPORT=5432`, `PGUSER`, `PGDATABASE=postgres`, `PGPASSWORD`, `PGSSLMODE=require`, then run:

   ```powershell
   pg_dump --format=custom --no-owner --no-acl --file C:\PRIVATE-BACKUP\ankidsa-before-beta.dump
   pg_restore --list C:\PRIVATE-BACKUP\ankidsa-before-beta.dump
   ```

   Use a directory you create outside the repository with restricted permissions; do not type the password into a command argument. Clear `PGPASSWORD` afterward. Verify the archive by restoring **into a separately created disposable local database only**, then compare table counts and constraints. Preserve existing roles/grants metadata separately. If `pg_dump` fails on provider-owned schemas, obtain a complete supported backup or review a scoped application-schema backup before proceeding; do not silently skip valuable data.
8. The original migrations **V1–V4 are unchanged**. V4 contains an old `UPDATE users SET fcm_token=NULL` consent migration; it does not erase study data, but is deliberately not approved automatically. If pending, review its effect and legacy consumers separately. V5 adds coordination/session/mail tables and indexes; it does not drop, truncate, or replace study tables. Review all pending SQL and record existing counts first.
9. Build backend with Java 21: `mvn -B verify` (Windows: `.\scripts\maven.ps1 -B verify`). Set maintenance-only `EXPECTED_DATABASE=postgres` and `EXPECTED_DATABASE_ROLE` to the actual role shown by `current_user` (often `postgres`, even when the pooler login contains a project suffix). Run:

   ```powershell
   java -jar target/ankidsa-backend-1.0.0.jar --verify-database
   ```

   After the backup restore check, SQL review and identity match, set `BACKUP_VERIFIED=true`, `MIGRATION_APPROVED=true`, and only if reviewed/pending, `LEGACY_V4_REVIEWED=true`. Run the same command with `--migrate-database`. Never put these approval variables in Render. The maintenance process exits without starting the API. Re-run the audit and compare account/problem/review counts. Flyway clean/baseline-on-migrate are disabled. The existing project was reconciled and migrated through V5 on 2026-10-15 after backup and rehearsal; do not repeat the one-time baseline. See LIVE-STATUS.md.

## 2. Allocate the two public URLs

1. **Netlify dashboard ? Add new project > Deploy manually.** Use the existing Free team and upload the locally built `build/web` folder. Record the exact `https://PROJECT.netlify.app`. A private personal access token also allows the API/CLI to allocate and deploy the project. Do not purchase a domain or enable paid overages. Prefer a manual/prebuilt deploy so Netlify does not try to run Flutter without its SDK.
2. **Render dashboard → New → Web Service → connect GitHub → select AnkiDSA-Backend.** Choose Docker, repository root, Dockerfile `./Dockerfile`, branch `main`, nearest available region to the database, and **Free** instance. Choose a unique service name. Record the exact URL Render allocates, such as `https://ankidsa-api-YOURSUFFIX.onrender.com`; examples are not reserved names.
3. In Render **Settings → Build & Deploy**, disable automatic deployment initially. Set **Health Check Path** to `/ready`. Populate environment values below before the first successful deploy. A service created without configuration will fail closed; this is expected. Do not add a Render database, disk, background worker, cron service or paid instance.

## 3. Firebase Android and FCM

1. **Firebase Console → existing project**, or **Add project** if none exists. Choose **Spark** and decline Google Analytics if not needed. There is no Crashlytics implementation in this repository; no existing telemetry was migrated. FCM and App Distribution do not require Blaze or Cloud Functions.
2. **Project overview → Add app → Android**. Android package name is exactly **`app.ankidsa.mobile`**. Keep this identity; Kotlin namespace `com.example.ankidsa` is an implementation detail. Choose nickname `AnkiDSA Android beta`.
3. Obtain the **public client** values from the downloaded `google-services.json`: `project_info.project_id`, `project_info.project_number`, matching `client_info.mobilesdk_app_id`, and matching client's `api_key.current_key`. Copy them to an ignored `config/production.local.json` based on `config/production.example.json`. These are identifiers/client API keys, not Firebase Admin secrets. Restrict the client API key appropriately to the Android app and required Firebase APIs in **Google Cloud Console → APIs & Services → Credentials**; verify FCM registration after restricting. Do not enable unrelated paid APIs.
4. This build already generates the native Google Services resources from those four Flutter defines; do not add a second generated configuration/plugin. You do not need to commit `google-services.json`. All four values must come from the same Android registration. Partial Firebase configuration fails the build.
5. **Firebase Project settings → General → Your apps → Android → Add fingerprint**: add the SHA-1 and SHA-256 of the release certificate from `keytool -list -v -keystore PRIVATE_KEY_PATH -alias ankidsa` (enter its password privately). FCM itself does not require OAuth SHA fingerprints; Android App Links uses SHA-256. If later using Google sign-in/Play signing, register the correct additional certificates then.
6. **Project settings → Cloud Messaging**: confirm **Firebase Cloud Messaging API (V1)** is enabled. If needed open **Google Cloud Console → APIs & Services → Library → Firebase Cloud Messaging API → Enable**, on this same project. No legacy FCM server key is used.
7. Prefer a dedicated server identity in **Google Cloud Console → IAM & Admin → Service Accounts → Create service account** named `ankidsa-fcm`. Grant **Firebase Cloud Messaging API Admin** (`roles/firebasecloudmessaging.admin`) on this project, not Owner/Editor. Open this service account → **Keys → Add key → Create new key → JSON**. Alternatively Firebase **Project settings → Service accounts** identifies the project/admin identity, but avoid broad default roles where practical.
8. Treat the downloaded JSON as a private credential. **Render service → Environment → Secret Files → Add secret file**, name `firebase-service-account.json`, paste its contents directly in Render. Set `GOOGLE_APPLICATION_CREDENTIALS=/etc/secrets/firebase-service-account.json` and `FIREBASE_PROJECT_ID` to the project ID. Remove the download from general Downloads after securely storing it. Never commit/upload it to Netlify or the extension.
9. Set `NOTIFICATIONS_ENABLED=true` after credentials are ready. Admin SDK requests have bounded connection/read/write and delivery timeouts. Android asks for notification permission only after opt-in, updates token registrations, removes old tokens, handles foreground banners/background system notifications/taps, and cleans up on logout. Invalid/unregistered tokens are removed by the server. Real Android 13+ permission and real-device delivery tests remain mandatory.

## 4. Brevo with no owned domain

1. **Brevo → Sign up → Free**, verify your existing mailbox, complete the requested legitimate account information, and obtain transactional sending approval. Do not add paid credits or a billing method.
2. **Settings → Senders, Domains & Dedicated IPs → Senders → Add a sender**. Name `AnkiDSA`, email an existing mailbox you control (a free mailbox is acceptable only if Brevo approves it). Verify the code/link sent to that mailbox. `MAIL_FROM` must be the verified **bare email address**, not `Name <address>`.
3. No DNS/domain authentication can be completed for a Gmail/Outlook domain you do not own. Brevo documents replacement of unauthenticated/free sender domains with a `brevosend.com` address; branding and inbox placement will differ. See [sender setup](https://help.brevo.com/hc/en-us/articles/208836149-Create-a-new-sender-From-name-and-From-email) and [domain behavior](https://help.brevo.com/hc/en-us/articles/35852083084178-Domain-setup-for-better-email-deliverability). This is conditional on account approval, not a promise that every account will be accepted. If sending is rejected, do not announce public password recovery or purchase a domain silently; keep the beta private until this required flow works.
4. **Account menu → SMTP & API → API Keys → Generate a new API key**. Name it `ankidsa-beta`. Store it directly in Render as `BREVO_API_KEY`. Set `MAIL_PROVIDER=brevo`, `MAIL_FROM=verified@your-mailbox-provider`, `RECOVERY_ENABLED=true`, `MAIL_DAILY_LIMIT=250`.
5. Test recovery to two real mailboxes you control, including spam folders. Check **Transactional → Logs** for accepted/delivered/bounced status. Do not copy message content or reset URLs into logs/issues. The app uses HTTPS port 443; no SMTP credentials are needed on Render Free. Use a dedicated account or reserve quota for other senders; 250 application attempts leave room under the provider's 300/day ceiling.
6. Reset tokens are cryptographically random, stored only as SHA-256 fingerprints, expire after 30 minutes, and are single-use. Successful reset invalidates existing sessions/device registrations. The reset URL token is in the browser fragment, avoiding ordinary web access logs. Recovery replies do not reveal whether an account exists. Email delivery is asynchronous; HTTP acceptance does not prove inbox delivery. If a process stops before sending, request another link after the cooldown. No reset token is stored in a durable mail queue.

## 5. Render environment contract and first deployment

**Render → service → Environment → Add environment variable**, then save/redeploy only after the database migration checks. Values with 🔒 are secrets. Use new independent random 48-byte base64 values for the JWT and scheduler; generate locally with a password manager or a cryptographic RNG, never copy the example text.

| Variable | Value / source |
|---|---|
| `SPRING_PROFILES_ACTIVE` | `production` (`staging` is equally strict; `development` is for local PostgreSQL; never `demo` on Render) |
| `PORT` | Render's provided port; app reads it automatically; local default 8081 |
| `DB_URL` | Verified session-pooler JDBC URL with TLS/timeouts, no password embedded |
| `DB_USERNAME` | Supabase Connect session-pooler username (`DB_USER` remains a legacy alias) |
| `DB_PASSWORD` 🔒 | Existing database password; rotate only after identifying other consumers |
| `DB_POOL_MAX` | `3` |
| `JWT_SECRET` 🔒 | New random secret, at least 48 random bytes encoded as base64 |
| `JWT_EXPIRATION_MS` | `86400000` (maximum 24 hours; no refresh-token endpoint) |
| `APP_PUBLIC_URL` | Exact Netlify HTTPS origin, no path/trailing slash |
| `API_PUBLIC_URL` | Exact Render HTTPS origin |
| `CORS_ORIGINS` | `https://YOUR.netlify.app,chrome-extension://bafnmcdkpidnpollodebmifggmmpkbje` |
| `APP_TIMEZONE` | `Asia/Kolkata` (same study date/scheduling zone everywhere) |
| `FLYWAY_ENABLED` | `false`; run explicit offline maintenance first |
| `API_DOCS_ENABLED` | `false` |
| `RECOVERY_ENABLED`, `MAIL_PROVIDER` | `true`, `brevo` |
| `BREVO_API_KEY` 🔒 | Brevo API key, not SMTP password |
| `MAIL_FROM`, `MAIL_DAILY_LIMIT` | Verified sender email, `250` |
| `NOTIFICATIONS_ENABLED` | `true` after Firebase setup |
| `FIREBASE_PROJECT_ID` | Public Firebase project ID |
| `GOOGLE_APPLICATION_CREDENTIALS` | `/etc/secrets/firebase-service-account.json` (contents 🔒) |
| `REMINDER_TRIGGER_SECRET` 🔒 | Another independent random secret; same value in GitHub reminders environment |
| `TRUSTED_PROXY_CIDRS` | Initially empty. Populate only after verifying the actual trusted ingress chain; never `0.0.0.0/0` to trust arbitrary forwarded headers |
| `JAVA_TOOL_OPTIONS` | Docker default: `-XX:InitialRAMPercentage=10 -XX:MaxRAMPercentage=50 -XX:+ExitOnOutOfMemoryError`; keep within Free memory |

Auth rate limiting is 30 POST attempts per 10 minutes per resolved address in one process. Behind a shared proxy, an empty trusted-proxy list may group users together. Verify Render's forwarded-IP behavior before launch and configure only trusted ingress ranges; do not blindly trust client-supplied `X-Forwarded-For`. This is a beta limiter, not distributed abuse protection.

**Manual Deploy → Deploy latest commit** only after both repositories' checks pass. Inspect logs for startup completion without sharing them publicly. Open `https://YOUR.onrender.com/health` → `{"status":"ok"}` and `/ready` → `{"status":"ready"}`. These are custom endpoints; there is no `/actuator/health`. Readiness also checks the coordination schema. `/internal/reminders` without its dedicated header must return 401. CORS must accept only the exact production origin/extension ID; localhost and arbitrary Netlify previews must fail in production.

## 6. GitHub Actions and reminders

1. Keep the two existing repos. **Each GitHub repository → Settings → Actions → General → Workflow permissions → Read repository contents**. Do not enable PR workflows to access production secrets; there is no `pull_request_target` workflow. Review third-party action updates before merging. **Settings → Branches/Rules → main**: require review and the appropriate validation check where your account's free plan supports rules. Do not buy a plan solely for a gate; otherwise use manual review.
   Publish the reviewed backend changes first: the frontend browser job checks out the public companion backend's `main`. For a coordinated branch test, set frontend **Settings → Secrets and variables → Actions → Variables → `BACKEND_TEST_REF`** to the reviewed backend commit/branch; remove the override after both main branches contain this release. No cross-repository access token is needed for these public repositories. Use the current release record and repository checks to identify the reviewed revisions; older deployment records describe earlier states.
2. Backend **Settings → Environments → New environment → `reminders`**. Restrict deployment branches to `main` where supported. Add environment secret `REMINDER_TRIGGER_SECRET`; add environment variable `API_PUBLIC_URL`. Scheduled jobs must not require a human reviewer on every run. Keep secrets out of ordinary repository-level PR jobs.
3. Backend **Actions → Daily reminder delivery → Enable workflow**, then **Run workflow → main** during the configured window. Schedules run at **06:33, 06:53, 07:13 and 09:47 Asia/Kolkata** (cron is UTC). Backend accepts work from 06:30 until 12:00. To change zones/window, change both backend settings and cron intentionally. No constantly running JVM scheduler or keep-alive ping is used.
4. The Python trigger waits for readiness, then sends `POST /internal/reminders` with `X-Reminder-Secret`. It refuses redirects, masks raw responses/errors, bounds runtime to six minutes and work to eight calls; workflow timeout is eight minutes. It reports only aggregate status. GitHub can delay/drop schedules and disables inactive public-repo schedules after 60 days; check failures and enable/manual-run as needed. There is no 06:30 delivery guarantee.
5. PostgreSQL owns a global renewable lease and per-device/day/session unique delivery rows. States: PENDING, PROCESSING, SENT, RETRYABLE, FAILED. Claims are fenced by UUID; expired claims can be reclaimed. Retryable sends back off up to five attempts. SENT is written only after FCM accepts a send; invalid tokens are removed. Unfinished records remain available for later triggers inside the window. Old pending days expire rather than sending stale reminders. Failed records remain for inspection for 30 days.
6. **Exactly-once external delivery is impossible across a crash between FCM acceptance and database acknowledgment.** Leases prevent normal concurrent duplicate sends; retries after an ambiguous network/crash outcome can still duplicate transport delivery. Stable delivery IDs, Android notification tags/collapse keys and foreground deduplication reduce duplicate presentation. Do not promise a delivery receipt: FCM acceptance is not proof the phone displayed it.
7. Check aggregate status privately in Supabase SQL Editor:

   ```sql
   SELECT study_date, status, failure_code, count(*)
   FROM reminder_deliveries
   GROUP BY study_date, status, failure_code ORDER BY study_date DESC;
   ```

   Do not manually set SENT or clear locks during active runs. Investigate FAILED/configuration failures before requeueing reviewed rows. Scheduler and review requests have independent idempotency mechanisms; review request UUIDs are retained across a client retry.
8. Four six-minute runs/day would consume up to ~744 Linux minutes in a 31-day month, plus startup overhead; normally runs are much shorter. Reserve the rest of the private-repo allowance for builds. Keep artifact retention at three days, monitor **Settings → Billing & licensing → Usage/Budgets**, and set paid usage budgets to zero/stop usage where offered. Do not add a payment method. Reduce build frequency or run locally if necessary; do not enable paid overages.
9. Optional backend deployment automation: create a separate `production` environment restricted to main, secret `RENDER_DEPLOY_HOOK` copied from Render **Settings → Deploy Hook**. The manual **Deploy approved backend revision** workflow requests deployment of Render's configured branch; first confirm main's Backend validation passed and the intended revision is the latest main. This workflow does not publish unreviewed PR code.

## 7. Flutter Web and Netlify

1. Locally use the tested Flutter **3.38.5 / Dart 3.10.4**, with the committed lockfile. After setting the real Render origin run:

   ```powershell
   flutter pub get --enforce-lockfile
   flutter analyze --no-pub
   flutter test --no-pub
   flutter build web --no-pub --no-wasm-dry-run --no-web-resources-cdn --pwa-strategy=none --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://YOUR-API.onrender.com
   python scripts/prepare-web.py --api https://YOUR-API.onrender.com
   ```

2. `build/web` is the upload directory, not the source repo. `prepare-web.py` installs restrictive API-specific CSP/security headers, no-cache revalidation, and a navigation fallback. Hash routes include `/#/collection`, `/#/insights`, `/#/schedule`, `/#/settings`, and recovery routes. Refresh these links after upload. Service-worker caching is disabled for release builds to reduce stale-code issues. Fonts and CanvasKit are served locally; no external font/CDN dependency is needed.
3. Manual upload: **Netlify > project > Deploys > drag and drop `build/web`**. Confirm the production deploy is published and open the allocated HTTPS URL. Upload the contents of `build/web`, never the source tree or private configuration files.
4. CLI/API access: create a personal access token in **Netlify > User settings > Applications > Personal access tokens**. Keep it in an ignored private file locally or GitHub environment secret `NETLIFY_AUTH_TOKEN`. Store the project ID as `NETLIFY_SITE_ID`; it is not a password. For local prebuilt deployment, use `netlify deploy --dir build/web --no-build --prod` with those values in the process environment.
5. Optional GitHub deployment: `.github/workflows/deploy-netlify.yml` is manual-only. Configure the `production` environment secret `NETLIFY_AUTH_TOKEN` and variables `NETLIFY_SITE_ID`, `API_PUBLIC_URL`, `APP_PUBLIC_URL`, and optional `ANDROID_CERT_SHA256`. It builds and checks the web app, packages the extension, and publishes to the existing Netlify project. Verify SPA refresh and CSP in the browser. Set Render CORS to the exact production site origin; preview domains are not automatically trusted.
6. Web sessions are stored with the existing Flutter secure-storage abstraction. In browsers this is origin-scoped client storage, not an HttpOnly server session and not immunity to XSS. Strict CSP, no external scripts, bounded JWT expiry and server logout revocation reduce risk. Signing out removes local access immediately and queues a failed remote revocation for reconnection. Offline revocation cannot be guaranteed until reconnection or expiry; do not treat it as instant server revocation.

## 8. Android release and App Links

1. Installed SDK includes API 36; Flutter config targets/compiles API 36. App ID is `app.ankidsa.mobile`, version from `pubspec.yaml` (`1.0.0+1` initially). Increment build number for updates. A shared AnkiDSA logo now supplies launcher, adaptive, themed, notification, web, and extension icons. Release resource shrinking/R8 is enabled; Firebase/Flutter supply consumer rules. Release HTTP cleartext is forbidden; debug retains local emulator access.
2. A release key was created locally by `scripts/create-signing-key.ps1` under `%USERPROFILE%\.ankidsa\signing-beta`, outside both repositories, with a restricted ACL. The private directory contains `ankidsa-release.p12` and `password.txt`; alias is `ankidsa`. **Back up both securely before distributing any build. Do not regenerate the key for updates.** On a fresh machine only, run that script once or configure an existing key through the environment. No signing secrets go in GitHub PR jobs.
3. Create ignored `config/production.local.json` from the example with `APP_ENV=production`, exact API and Netlify origins and all four public Firebase values. For study-only phone testing before Firebase setup, use `config/study-beta.example.json`, which explicitly sets `PUSH_NOTIFICATIONS_ENABLED=false`; push stays unavailable in that build. Do not include `VALIDATION_ONLY=true` in an actual beta build. In PowerShell with Flutter and Java 21 on PATH:

   ```powershell
   flutter build apk --debug --dart-define-from-file=config/production.local.json
   .\scripts\build-android-release.ps1 -ConfigFile config/production.local.json
   ```

   Outputs: `build/app/outputs/flutter-apk/app-release.apk` and `build/app/outputs/bundle/release/app-release.aab`. Signing can alternatively use `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, or an ignored `android/key.properties`. The release build fails if no key is supplied; it never substitutes the debug key. Never type signing passwords into command history.
4. `adb install -r build/app/outputs/flutter-apk/app-release.apk` on a trusted device. The APK includes ARM64; verify a real ARM64 Android 13+ device. A debug-installed app with the same ID and a different certificate cannot be upgraded in place: export/preserve what is needed and uninstall that local debug app only with your consent, or use a separate test device. Do not delete an existing user's app data automatically.
5. App Links: after the web build, run `python scripts/android-app-links.py --sha256 YOUR_PUBLIC_CERTIFICATE_FINGERPRINT`, then redeploy Netlify. It generates `build/web/.well-known/assetlinks.json` for this app ID. The Android manifest host comes from `APP_PUBLIC_URL`. Test Android Settings → Apps → AnkiDSA → Open by default, then open your HTTPS Netlify recovery link. Test the same link in a desktop browser. FCM notification taps use their own `OPEN_QUEUE` navigation, not a secret-bearing link.
6. Optional free testing: **Firebase Console → Release & Monitor → App Distribution → select Android app → Get started → drag signed APK → add tester emails → Distribute**. This is an external communication/publication you perform manually; no testers were contacted. Use APK to avoid Play integration requirements for AAB distribution. Keep AAB locally for later Play preparation. [Firebase App Distribution](https://firebase.google.com/docs/app-distribution/android/distribute-console).

## 9. Chrome extension release

1. Run `npm ci`, `npm test`, then:

   ```powershell
   python scripts/package-extension.py --api https://YOUR-API.onrender.com --app https://YOUR-APP.netlify.app
   ```

2. Output is `build/extension/ankidsa-extension.zip`. It is an allowlisted package: MV3, source scripts, fonts/licenses/icons/privacy notice and generated config. It includes no server secrets, dev-only localhost permissions or broad optional HTTPS host permission. API host permission and CSP connect-src are limited to the actual API. Source `extension/` keeps local-development defaults.
   Before inviting testers, add your operator identity and a monitored contact email to `extension/PRIVACY.md`, then rebuild the ZIP. No contact identity has been invented for you.
3. Extract the ZIP to a dedicated directory. **Chrome → chrome://extensions → Developer mode → Load unpacked → select extracted folder**. The preserved public manifest key produces ID `bafnmcdkpidnpollodebmifggmmpkbje`; verify it and use that exact ID in CORS. The key is public identity material, not a signing secret.
4. Refresh an actual LeetCode problem tab after installing. Sign in, capture a solved problem, edit notes, save, then open Flutter and verify it appears. Confirm accepted submission capture works on current LeetCode markup; browser fixtures are not proof of compatibility with a newly changed live page. Test offline queue/reconnect, logout, account switch, expired JWT, duplicate save, and pending conflict display. Local queues are capped at 50 per account/server and preserve handwritten notes.
5. Chrome local storage holds the bearer session in trusted extension contexts; page content scripts cannot read it through the extension messaging API. Browser profile access is still sensitive. Remote logout revocation is retried if offline. Production server addresses are fixed by packaging; changing infrastructure means rebuilding the ZIP, not embedding secrets. Public Web Store publication is postponed.

## 10. Launch tests and rollback

Repository checks: backend `mvn -B verify`; PostgreSQL tests use only `TEST_DB_URL=jdbc:postgresql://127.0.0.1:PORT/ankidsa_test_NAME`, `TEST_DB_USER=...`. A test guard rejects hosted/non-test database targets. Flutter analyze/test, web production build, debug/signed release APK/AAB, JS tests and browser tests must pass. `docker build -t ankidsa:beta .` and a disposable demo container startup are required on a Docker-capable machine/CI; Docker was unavailable locally. Never start tests using production credentials.

For browser integration run the local API with `demo` against a separate disposable H2 file, serve `build/web` via `node scripts/serve-demo.cjs`, and `npm run test:e2e`. A build pointed at `api.validation.invalid` can be exercised with `VALIDATION_API_PROXY=1` (test-only Playwright routing to localhost); this is not a deployed API test.

Before inviting real users, verify:

- Allocated HTTPS origins, CSP/CORS, /health and /ready; no debug docs/errors/stacks; Supabase Data API exposure blocked; correct Free plans and zero paid budgets.
- Signup/login/incorrect-password/expiry/logout/account isolation; reset email delivery/30-minute expiry/reuse prevention/session invalidation. Old JWTs lacking new issuer/session-ID claims require sign-in again.
- Problem create/read/edit/delete confirmation, conflicting edit, repeated review UUID, stats after reload, new detail/schedule/settings screens at phone/tablet/desktop widths and large text; keyboard focus and screen-reader labels.
- Real backend sleep: leave it idle >15 minutes, then sign in/load/mutate. Readiness retries should explain the wait; mutating requests must not be blindly replayed after ambiguous failure. Test network errors and manual refresh to resolve saved-state uncertainty.
- FCM opt-in/denial, token rotation, foreground banner, background/killed-app push, tap to queue, logout/re-login, invalid token removal, two phones, duplicate reminder triggers and transient FCM failure. Never expose real device tokens in bug reports.
- Manual scheduler run in its window, database aggregate status, no unauthenticated access, delayed GHA run recovery; Firebase provider setup is configured, but actual phone and scheduled delivery still need verification. Brevo setup and real reset-email delivery remain pending.
- Current real LeetCode pages, extension CSP/host permissions, private ZIP upgrade; Android release certificate/signature, ARM64 launch, app links, Android 13+ permission.

Rollback order:

1. Pause the GitHub reminder workflow and disable Render auto deploy. Record current app revisions, release artifacts and row counts. Do not delete data or stop the database.
2. Netlify **Deploys → previous successful production deploy → Publish deploy**. If unavailable, upload the retained previous web artifact. Distribute the previous reviewed extension ZIP. Keep the previous Android APK with the same signing key; downgrade may require a higher versionCode rebuild, never automatic uninstall/data deletion.
3. Render **Deploys → previous successful deployment → Rollback**, or manually deploy a known-good commit. Check /ready and core flows. Keep new additive V5 tables; do not run down migrations or Flyway clean/repair. A pre-hardening backend lacks session revocation and hosted protections, so prefer a forward fix or restrict access rather than restoring insecure behavior silently.
4. Database rollback is **not** automatic restore. Existing/new study writes must be preserved. Stop writes only if required, make another external backup, compare changes and design a reviewed forward repair. Restore the earlier dump only to a separate recovery database until the owner explicitly approves reconciliation. Do not overwrite the live Supabase project.
5. Rotate exposed/revoked secrets in providers; JWT rotation signs users out. Firebase/Brevo keys need overlapping verification before retiring old keys where supported. Deploy new API/config before removing old credentials. Never restore a compromised key from an old artifact.

## Optional / later — not required for current $0 beta

Always-on Render, larger PostgreSQL, backups/HA, custom domain/authenticated email domain, Play Console and Chrome Web Store registration/publication, additional observability and multiple regions can wait. Provider-independent JDBC, HTTP email/notification interfaces, environment URLs and a single API keep those upgrades incremental. Do not add microservices or migrate away from existing Supabase data to make an upgrade.

## Exact deployment order

Review both repository changes → verify existing database/backup/permissions → allocate provider URLs → configure Firebase and verified Brevo sender → run approved additive migrations → configure/deploy Render → verify API/security → rebuild/upload Netlify → rebuild/sign Android and publish public App Links file → package/load extension → configure/manual-test reminder workflow → run live smoke checklist → invite private beta users. Render and the database are verified live. Remaining provider configuration and end-to-end checks are recorded in [CURRENT-RELEASE.md](CURRENT-RELEASE.md).
