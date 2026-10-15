# Submit AnkiDSA to the Chrome Web Store

Status: deferred by the owner; not uploaded or submitted. The current plan is
personal use and sharing build/extension/ankidsa-extension.zip for manual loading.
That ZIP includes INSTALL.txt, keeps the existing backend-compatible extension ID,
and needs no Chrome Web Store developer account or registration fee. There is no
pending request for a Store Item ID. The steps below are optional future reference
if the owner later chooses Store publication.

## 1. Open or register your publisher account

Open https://chrome.google.com/webstore/devconsole in Chrome and sign in with the
Google account you want to own the extension. If prompted, register as a developer,
complete the account requirements and pay the one-time registration fee displayed
by Google. Use the actual amount shown at checkout. Complete any required email,
identity or two-step-verification checks yourself.

Official registration instructions:
https://developer.chrome.com/docs/webstore/register

## 2. Upload the extension ZIP as a draft

Choose Add new item / New item and upload:

`C:\Users\rajsi\ankidsa\build\chrome-web-store\ankidsa-chrome-store.zip`

Upload that ZIP directly. Do not upload the entire project, the artwork folder,
or a ZIP containing the whole submission kit. The package contains only the
extension and its bundled assets, uses the live API/web URLs, and requests no
localhost or arbitrary-server permissions.

After upload, copy the 32-character item ID from the dashboard. Send that ID to
the assistant so the backend can allow `chrome-extension://YOUR_STORE_ITEM_ID`
while retaining the existing web and unpacked-beta origins. Do this before
Submit for review; an otherwise valid Store installation could fail API access
if only the old unpacked extension ID is allowed.

The old unpacked beta ID is `bafnmcdkpidnpollodebmifggmmpkbje`. Do not assume the
new Store ID matches it. Google supplies the Store item's identity. Its public key
is available under Package > View public key if you later want an unpacked copy
with the same ID. The current unpacked beta can continue to work separately.

Official identity instructions:
https://developer.chrome.com/docs/extensions/reference/manifest/key

## 3. Complete the Store listing

Use the copy and reviewer instructions in LISTING.md. The confirmed publisher is
Anubhav Singh, with support email rajsinghrajput7002@gmail.com. Upload these assets
from the assets folder:

| Field | File |
| --- | --- |
| Store icon | icon-128.png |
| Small promotional tile | small-promo-440x280.png |
| Screenshot 1 | screenshot-1-capture-1280x800.png |
| Screenshot 2 | screenshot-2-queue-1280x800.png |
| Screenshot 3 | screenshot-3-review-1280x800.png |

Screenshot 1 shows the real extension UI with sample study data. Screenshots 2
and 3 are explicitly labeled companion web-app views.

## 4. Finish Privacy practices and the public privacy page

Use LISTING.md for the single purpose, permission justifications, remote-code
answer, and data disclosures. Read the certifications before checking them.

The completed policy is in PRIVACY.md and is hosted at:

https://ankidsa.netlify.app/privacy/

Verify it opens without signing in and shows the policy, then enter that exact URL
in the dashboard. The support page is https://ankidsa.netlify.app/support/.

## 5. Choose visibility and submit

For the first week, Unlisted is a useful option: people with its Store link can
install it, but it does not appear in public Store search. This does not change
public signup in AnkiDSA. Public visibility is also available if you want discovery
immediately. All visibility choices still require Google's review.

Select the intended regions, resolve any dashboard validation messages, and choose
Submit for review. Select automatic publication after approval if you want it to
go live as soon as Google approves it. If you choose deferred publishing instead,
you must return and publish after approval.

Submission today does not guarantee availability today. Google says most reviews
finish within a few days, but some take a few weeks:
https://developer.chrome.com/docs/webstore/review-process

## 6. After approval

Open the resulting Chrome Web Store URL and choose Add to Chrome. Sign in with
your existing AnkiDSA account and refresh LeetCode. Check manual capture, an actual
Accepted submission, saved notes, and web/phone sync using TESTING-GUIDE.md.

Avoid running the unpacked beta and Store version with automatic saving enabled
at the same time. Sync pending notes in the unpacked copy first, then disable it
when switching to the Store copy. Local pending queues are not shared between
different extension IDs; already synchronized data remains on your account.

If Google requests changes, keep the same Store item and update its package with
an increased manifest version; do not create a second item just to retry review.

## Official references

- https://developer.chrome.com/docs/webstore/publish
- https://developer.chrome.com/docs/webstore/images
- https://developer.chrome.com/docs/webstore/cws-dashboard-privacy
- https://developer.chrome.com/docs/webstore/cws-dashboard-distribution
