# AnkiDSA Chrome Web Store listing

Name (from the package): AnkiDSA — keep what you learn

Short description (from the package):
Save LeetCode problems and your approach. Revisit them when it matters.

Language: English

Category: choose the closest available education/study category in the dashboard.

Website: https://ankidsa.netlify.app

Publisher: Anubhav Singh

Support email: rajsinghrajput7002@gmail.com

Support URL: https://ankidsa.netlify.app/support/

Privacy URL: https://ankidsa.netlify.app/privacy/

## Detailed description — paste this text

Keep what you learn from LeetCode with AnkiDSA.

Save a problem and the idea behind your solution, then revisit your notes through
the AnkiDSA companion app's spaced review queue.

• Capture the current LeetCode problem, including its title, difficulty and tags.
• Automatically save after a new Accepted submission when automatic saving is on.
• Write your own explanation of what clicked and update it from the extension.
• Keep pending notes in this browser when the service is unavailable and sync them
  back to the same account when the connection returns.
• See your collection and due count, and open the companion web app to review.

Create a free AnkiDSA account in the extension or at https://ankidsa.netlify.app.
Use the same account on the web and Android app to access your saved study data.
Internet access is needed for account sign-in and syncing. The hosted API may
take a short time to wake when it has been idle.

AnkiDSA reads problem metadata on LeetCode problem pages and the notes you choose
to save. It does not read your solution source code or your LeetCode password,
copy cookies, or collect browsing activity from unrelated websites. It has no
advertising or analytics SDKs.

This initial release supports capture, notes, syncing and spaced reviews.
Push reminders and password-reset email are not enabled in this beta.

AnkiDSA is an independent project and is not affiliated with or endorsed by LeetCode.

## Privacy practices — review and enter these disclosures

Single purpose:
Save a user's LeetCode problem metadata and personal study notes to their AnkiDSA
account so they can revisit the approach through spaced reviews.

Permissions:

| Permission | Justification |
| --- | --- |
| storage | Keep the signed-in AnkiDSA session, automatic-saving preference, pending sign-outs, and unsynced notes locally. Pending notes are separated by account and server. |
| activeTab | Identify the current tab when the user opens the popup, and request metadata from the content script on the active LeetCode problem page. |
| alarms | Retry queued note synchronization and pending session revocations in the background. This permission is not used for advertising or user tracking. |
| https://leetcode.com/* | Support problem capture from LeetCode. The content script runs only on /problems/* and reads the title, difficulty, topic tags, canonical URL, and the Accepted result after a new submission. |
| https://ankidsa-backend.onrender.com/* | Sign in, save and update the user's problems/notes, synchronize their queue, retrieve study counts, and revoke sessions through the fixed AnkiDSA API. |

Remote code: No. JavaScript, CSS, fonts and icons are bundled in the extension.
HTTPS requests retrieve data, not executable code.

Data types to disclose, with the dashboard's corresponding checkboxes:

| Data type | Limited data used |
| --- | --- |
| Personally identifiable information | AnkiDSA account name and email. |
| Authentication information | AnkiDSA password submitted for sign-in/registration and the session token. The extension does not persist the password. |
| Web history | Only the LeetCode problem URLs/titles the user saves or automatically captures; no general browser-history access. |
| Website content | Problem title, difficulty and topic tags, plus the personal notes the user enters. Solution source code is not collected. |
| User activity | The Submit/Accepted interaction used to trigger capture and the resulting saved study record. No general clickstream, keystroke logging or unrelated-site activity. |

No financial/payment, health, personal-communication, or precise-location data is
requested by the extension. Hosting providers may process ordinary request data
such as IP addresses to operate their services; the privacy page must explain this.

The current implementation uses data only for its described study/sync purpose,
does not sell it or use it for advertising, and does not use it for creditworthiness
or lending. The publisher should read the Store's certifications and confirm them
only if these statements also describe their actual operation of the service.

## Test instructions — paste into the reviewers' test-instructions field

All AnkiDSA features in this release are available through free public signup.
There is no invitation, payment, or email-verification requirement.

1. Install the extension, open its popup, and create a new AnkiDSA account using
   an email of your choice and a password with 10–64 characters. Sign in afterward
   if the session is not already active.
2. Open https://leetcode.com/problems/two-sum/description/ and refresh the page
   after installing. Open the extension. It should show Two Sum and its metadata.
3. Enter a short note and use the save control. A LeetCode login or successful
   submission is not required for manual capture.
4. Select Open my review queue, sign in to the companion web app with the same
   AnkiDSA account, reveal the note, and rate the review. Refresh the extension to
   see the updated due count.
5. Optional automatic-capture check: with automatic saving enabled, use a signed-in
   LeetCode account to submit a correct solution. A new Accepted result triggers
   capture. Previously visible Accepted text without a new submission does not.
6. If the API is waking, wait for the status message and retry once. Use the
   configured public HTTPS services; no local server or special credentials are needed.

Password-reset email and push reminders are disabled in this beta. No reviewer
access to the publisher's accounts, API keys, or hosting dashboard is required.

## Sources checked 2026-10-15

- https://developer.chrome.com/docs/webstore/cws-dashboard-privacy
- https://developer.chrome.com/docs/webstore/cws-dashboard-test-instructions
- https://developer.chrome.com/docs/webstore/images
