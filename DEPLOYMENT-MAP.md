# AnkiDSA deployment map

The API is live on Render Free. The web app is live at https://ankidsa.netlify.app on the existing Netlify Free team. See LIVE-STATUS.md for current results. Use [DEPLOYMENT.md](DEPLOYMENT.md) for the complete setup and rollback procedure.

| Component | Deploy here | What to upload/connect | Configuration | Final URL | Verification |
|---|---|---|---|---|---|
| Flutter Web | Netlify Free, prebuilt upload | Rebuilt `build/web`; optional manual GitHub deploy workflow | Public `API_BASE_URL` at compile time; Netlify project ID/token | `https://ankidsa.netlify.app` | Open login, refresh `/#/schedule`, inspect CSP and API requests |
| Spring Boot | Render Free Web Service | Existing backend GitHub repo, root Dockerfile | Render environment contract in DEPLOYMENT.md; private Firebase secret file | `https://ankidsa-backend.onrender.com` | `/health`, `/ready`, authentication/ownership checks |
| PostgreSQL | Existing Supabase Free project | **No redeployment/reset**; reviewed additive migrations only after backup | JDBC session-pooler host/user/password in Render; 3 connections | Existing Supabase project/Connect host | Identity, Flyway history, unchanged study counts, blocked public table access |
| FCM | Existing/new Firebase Spark project | Android registration + least-privilege server account key in Render | Four public Android client values; server private JSON via secret file | Firebase Console, no user-facing FCM URL | Real Android permission/token/push/tap/logout tests |
| Email | Brevo Free | Verified sender mailbox, approved transactional account | `BREVO_API_KEY`, `MAIL_FROM`, provider `brevo`, cap 250 | Brevo Transactional Logs | Real reset email delivered; single-use token; old sessions rejected |
| Reminder trigger | Backend GitHub Actions | `reminders.yml` and standard-library Python script | `reminders` environment: private trigger secret + public API origin | `POST https://ankidsa-backend.onrender.com/internal/reminders` | Authorized batch and DB status; unauthenticated request 401 |
| Android | Local release / optional Firebase App Distribution | Signed APK; retain signed AAB for later | Private local signing key; public production JSON/Firebase config | Local artifacts / Firebase tester invitation | Signature, ARM64 launch, App Links and real FCM |
| Chrome extension | Unpacked private ZIP | `build/extension/ankidsa-extension.zip` | Generated public API/Netlify origins; no secrets | `chrome-extension://bafnmcdkpidnpollodebmifggmmpkbje/popup.html` | Actual LeetCode save, offline queue, Flutter sync |

Initial mandatory cost: **$0**. Estimated monthly cost: **$0 within free quotas**. Do not add paid overages. Public store publication and custom domains are postponed. Validation artifacts using `.invalid` origins must be rebuilt before launch.
