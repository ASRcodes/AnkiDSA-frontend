# Deploying AnkiDSA

The local demo is deliberately separate from production. This document covers the remaining operator configuration and the code's limits; a successful local build is not a deployment or a security audit.

## Accounts and credentials

The old source contained a database password. **Rotate it in Supabase before deploying.** The replacement configuration reads `DB_URL`, `DB_USER`, `DB_PASSWORD`, and `JWT_SECRET` from the environment. Never publish `.work/backups`, `.local`, `.env`, keystores, database files, or service-account JSON.

Generate a random JWT secret with at least 32 bytes of entropy. Tokens expire after 24 hours. The API checks account session versions and problem ownership. Passwords use BCrypt; a reset revokes earlier tokens and device registrations. Installing this update requires existing users to sign in again. Account endpoints have an in-process limit of 30 requests per client address in 10 minutes.

Existing accounts created by email-only login have no password hash and are locked. They can set a password by completing email recovery, which requires access to their mailbox. Do not restore the old email-only endpoint.

Email recovery is implemented; Google OAuth is not. Before opening public signup, configure and verify your email provider and publish a support contact:

```text
APP_PUBLIC_URL=https://YOUR_APP_HOST
RECOVERY_ENABLED=true
MAIL_HOST=smtp.YOUR_PROVIDER
MAIL_PORT=587
MAIL_FROM=AnkiDSA <accounts@YOUR_DOMAIN>
MAIL_USER=your_smtp_user
MAIL_PASSWORD=your_smtp_password
MAIL_AUTH=true
MAIL_STARTTLS=true
```

Use your provider's verified sender domain and required SPF/DKIM settings. Recovery requests give the same acknowledgement for existing and unknown accounts. Random links expire after 30 minutes, are stored only as SHA-256 hashes, and can be used once. Requests are limited to one email per account per minute. Reset pages require password confirmation, and the server sends a change notice. Mailbox delivery and spam placement must be checked with your provider; local tests establish SMTP transport and application behavior only.

The recovery token stays in the URL fragment. Keep third-party scripts off recovery pages and never log the full browser URL. The demo profile writes messages to its private `.local/outbox` directory instead of SMTP. See [OWASP's recovery guidance](https://cheatsheetseries.owasp.org/cheatsheets/Forgot_Password_Cheat_Sheet.html).

## PostgreSQL

Use a dedicated database/application role and require TLS:

```text
DB_URL=jdbc:postgresql://YOUR_HOST:5432/postgres?sslmode=require
DB_USER=your_application_role
DB_PASSWORD=your_rotated_password
JWT_SECRET=your_random_secret
CORS_ORIGINS=https://YOUR_APP_HOST,chrome-extension://bafnmcdkpidnpollodebmifggmmpkbje
APP_TIMEZONE=Asia/Kolkata
```

On a fresh database, Flyway runs V1–V4 automatically. Hibernate validates the result. The repository's old root `schema.sql` is the legacy starting schema; do not manually run it in addition to Flyway.

For an existing database created from the old schema:
1. Take and verify a backup.
2. Rehearse the upgrade on a copy.
3. Confirm the three tables match the original schema.
4. Run once with `SPRING_FLYWAY_BASELINE_ON_MIGRATE=true` and `SPRING_FLYWAY_BASELINE_VERSION=1`.
5. Confirm V2 added password hashes, versions, and review request IDs; V3 added recovery and session versions; V4 added device registrations. Legacy notification tokens are cleared so users can opt in again.
6. Remove the baseline override for subsequent deployments.

All review retries carry a request ID. Transactions and row locks prevent duplicate schedule advancement. Clients also submit the version they observed; stale edits receive HTTP 409.

## Backend service

Build with Java 21 and Maven:

```powershell
.\scripts\maven.ps1 -B verify
```

Or use the backend's multi-stage Dockerfile. Supply environment values through your host's secret manager or the provided Compose configuration. The server listens on 8081 and exposes `GET /health`. Run behind an HTTPS reverse proxy. API docs are disabled unless `API_DOCS_ENABLED=true`.

Keep `SPRING_PROFILES_ACTIVE=demo` **out of production**. The sample password and reset endpoint only belong to the local demo profile.

Configure trusted proxy forwarding at the infrastructure boundary. Do not trust arbitrary client-supplied `X-Forwarded-For`. A deployment behind a proxy needs a correct client-address configuration so the in-process auth limiter does not treat every user as one address. For multiple API instances, enforce shared rate limits at the gateway.

Back up the database, monitor health/errors, and rehearse restores. The activity grid covers 84 days; retention covers all logged reviews. Dates use `APP_TIMEZONE` consistently. This release uses one configured study timezone rather than a timezone per account.

## Flutter web

```powershell
flutter build web --no-wasm-dry-run --no-web-resources-cdn --dart-define=API_BASE_URL=https://YOUR_API_HOST
```

Serve `build/web` over HTTPS, with navigation fallback to index.html. Do not include `DEMO_MODE=true`. Configure long caching only for fingerprinted assets; keep index.html and bootstrap scripts fresh. The included Node server is for local demonstrations, not internet hosting.

Use a strict origin allowlist on the API. Restrict scripts and framing at your host, keep dependencies updated, and avoid embedding untrusted HTML. The app renders user notes as text.

## Android and iOS

Android's application ID is `app.ankidsa.mobile`. Confirm ownership/availability before store submission. Copy `android/key.properties.example` to `android/key.properties`, point it to a private upload keystore, and fill its passwords. Release builds no longer use debug signing.

```powershell
flutter build appbundle --release --dart-define=API_BASE_URL=https://YOUR_API_HOST
```

Plain HTTP is allowed only for localhost and the Android emulator address. Internet permission is declared, and Android app backup is disabled to avoid copying stored session material.

iOS signing, bundle registration, and device testing require macOS/Xcode and the operator's Apple account. Those checks cannot be established from this Windows workspace.

## Extension release

The extension uses a stable public manifest key. Its local ID is `bafnmcdkpidnpollodebmifggmmpkbje`. If the Chrome Web Store assigns a different public key, update the backend allowlist and release configuration accordingly.

Set the default server and app addresses in `extension/background.js` to your HTTPS endpoints, while leaving the user's connection settings available. Run the browser tests and check a real accepted submission in normal Chrome. Page selectors and LeetCode metadata APIs are outside this project's control.

Package the contents of `extension/`, excluding development-only package metadata if desired. Publish a hosted privacy policy based on `extension/PRIVACY.md`, with your operator contact details and retention policy. Review the requested permissions in Chrome's installation dialog.

Reference: [Chrome host permissions](https://developer.chrome.com/docs/extensions/develop/concepts/network-requests), [extension storage access levels](https://developer.chrome.com/docs/extensions/reference/api/storage).

## Notifications

Android and iOS clients implement opt-in permission requests, token rotation, account-specific preferences, logout cleanup, and notification taps that open the queue. Reminders appear only when both the client and backend are configured. Web and desktop push are outside this release.

Register the Android application ID `app.ankidsa.mobile` in your Firebase project. Copy `config/firebase.android.example.json` to `config/firebase.android.local.json` and fill in the **public client configuration** from Firebase. Do not put a service-account key in this file. Build with:

```powershell
flutter build appbundle --release --dart-define-from-file=config/firebase.android.local.json
```

The Android build creates Firebase's native string resources from those same four public values, so FCM can initialize before Dart when the app process starts in the background. Supplying only some of the required values fails the build. This follows [Firebase's documented resource mapping](https://firebase.google.com/docs/android/google-services-plugin-and-file); no service-account key belongs in the app.

On the backend set `NOTIFICATIONS_ENABLED=true` and configure Application Default Credentials, preferably through your host's service identity. For local provider verification, `GOOGLE_APPLICATION_CREDENTIALS` may point to a private service-account file. Containers need that file mounted separately; merely setting its path does not copy it into the container.

Reminders run at 06:30 in `APP_TIMEZONE`, only for accounts with due problems. Multiple devices are supported; one token has one account owner. Logout removes only that account's matching token. A password reset clears all its registrations. Registrations inactive for 30 days and tokens reported unregistered by FCM are removed. Messages contain no account name, notes, problem titles, or review counts and expire after one hour. Offline logout cannot immediately reach FCM; cleanup retries on a later app start, and an already delivered notification may remain in the phone's notification tray.

Run one reminder scheduler instance. Real Firebase delivery, Android notification permissions, and background/cold-start notification taps still require a configured real-device check. For iOS, additionally add the project's `GoogleService-Info.plist` to the Runner target in Xcode, configure APNs in Firebase, enable push capabilities and signing, and supply the iOS app ID and `FIREBASE_IOS_BUNDLE_ID` in a separate client configuration. See [Firebase's Flutter setup](https://firebase.google.com/docs/cloud-messaging/flutter/get-started) and [token management guidance](https://firebase.google.com/docs/cloud-messaging/manage-tokens).
