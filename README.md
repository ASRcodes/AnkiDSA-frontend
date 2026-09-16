# AnkiDSA
Keep the patterns you learn.

AnkiDSA connects a Chrome extension, a Flutter review app, and a Spring Boot API. Capture a LeetCode problem, write down the insight, and revisit it on a schedule that responds to your recall.

## Run the local demo

From PowerShell in this folder:

```powershell
.\scripts\start-demo.ps1
```

Open **http://localhost:3000**. Sign in with **demo@ankidsa.local / DemoRecall!2026**. The account and its synthetic history exist only in the backend's local `demo` profile. Your Supabase database is not used.

Chrome: open **chrome://extensions**, enable **Developer mode**, choose **Load unpacked**, and select this project's **extension** folder. Pin AnkiDSA and sign in with the same account.

See [DEMO.md](DEMO.md) for the recording walkthrough, [TESTING.md](TESTING.md) for verification, and [PRODUCTION.md](PRODUCTION.md) before deployment.

Today's delivery is the local prototype; production setup is deferred. The runnable bundle is `.work/AnkiDSA-local-demo.zip`, including the web app, API, extension, and emulator APK. See [the package guide](docs/LOCAL_DEMO_PACKAGE.md) for extraction and launch instructions. Use `.\scripts\package-demo.ps1` to refresh it after builds.

The backend lives at `C:\SpringBoot\ankidsa`. Pass `-BackendPath` to the launcher if you move it. Java 21, Maven 3.9+, Flutter 3.38+, Node 22+, and Chrome are required. The Maven helper also recognizes the Maven bundled with IntelliJ on this machine.

Use `.\scripts\stop-demo.ps1` to stop processes started by the launcher. Use `-Rebuild` on the next start after changing code. Database contents persist across restarts.

## What is implemented

- Chrome Manifest V3 capture, metadata extraction, editable notes, accepted-submission detection, and a persistent retry queue.
- Password-based accounts, signed sessions, account-scoped problem access, and isolated local demo data.
- Email password recovery with expiring, single-use links and revocation of earlier sessions.
- Opt-in phone reminders, token rotation, and account-safe device registration; Firebase setup is required for delivery.
- Responsive review queue, searchable collection, editing and deletion, notes hidden during recall, and accurate review statistics.
- Transactional scheduling with ownership checks, stale-version protection, and idempotent retries.
- PostgreSQL migrations, environment-based production configuration, and Android signing configuration.

The client does not execute or upload your LeetCode code. It saves problem metadata and notes. LeetCode's page structure can change; manual capture is always available from the popup.

## Source layout

| Path | Purpose |
|---|---|
| `lib/` | Flutter app |
| `extension/` | Loadable Chrome extension; no build step |
| `test/` | Flutter regression tests |
| `tests/` | Chrome and JavaScript tests |
| `scripts/` | Local demo and verification helpers |
| `C:\SpringBoot\ankidsa\src/` | API, scheduling, migrations, backend tests |

Fonts are bundled for consistent rendering and offline use; their OFL licenses are in `assets/fonts/` and the extension folder.
