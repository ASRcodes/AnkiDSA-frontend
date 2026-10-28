# AnkiDSA privacy policy — operator details required before publication

This draft describes the inspected extension and current service. Replace the
two operator fields below before publishing the public privacy page.

Effective date: 29 October 2026

Operator: Anubhav Singh

Privacy and support contact: [CONFIRMED PUBLIC SUPPORT EMAIL]

AnkiDSA helps you save LeetCode problems and personal notes for spaced reviews.
This policy covers the AnkiDSA Chrome extension and the companion AnkiDSA service.

## Information used

When you create an AnkiDSA account, the service receives your name, email address
and password. Passwords are stored as hashes on the server. The extension uses
your password for registration/sign-in and does not persist it. It keeps a session
token locally so you can remain signed in.

On LeetCode problem pages, the extension reads the problem title, difficulty,
topic tags and canonical URL. If automatic saving is enabled, it observes a new
submission and its Accepted result to decide when to capture the problem. It
sends the captured metadata and the notes you choose to save to the AnkiDSA API.
The companion service also stores your review ratings, dates and scheduling data.

The extension does not collect solution source code, LeetCode passwords or cookies,
general browsing history, or activity on unrelated websites. It does not include
an advertising or analytics SDK.

## Password recovery email

When you request password recovery, AnkiDSA uses Brevo to send email to your
account address. Brevo processes the recipient email address, message content
(including the reset link or password-change confirmation), and delivery events
needed to send these messages and investigate delivery problems. Passwords are
not included in these emails or sent to Brevo.

Reset links expire after 30 minutes and can be used once. AnkiDSA stores a hash
of each reset token. A successful reset invalidates earlier sessions and removes
their notification device registrations. Sign in again on each device and check
that Daily reminders is enabled if you want to resume Android reminders.

## Optional Android reminders

If you enable Daily reminders in the Android app, Google Firebase Cloud Messaging
(FCM) processes a device registration token and generic notification text to deliver
your reminder. AnkiDSA stores the token linked to your account, your reminder
preference, and delivery status needed to avoid duplicate daily reminders. Your
problem notes and solution details are not included in the push message. Opening
the notification loads your review queue from AnkiDSA after authentication.

You can turn reminders off in the app or in Android notification settings. Turning
them off in the app unregisters the device and deletes its FCM token. Signing out
also removes the account's device registration when the backend can be reached;
offline sign-out queues server cleanup for retry. Notification receipt depends on
network availability and device settings. The Chrome extension does not use FCM.

## Local storage and synchronization

The extension stores your AnkiDSA session, connection/automatic-saving preferences,
unsynced problem notes and pending session revocations in local extension storage.
Pending notes remain separated by server and account. LeetCode content scripts
cannot read this storage, and the AnkiDSA session token is not given to the page.

Signing out removes active local access. If the server cannot be reached, a copy
of the token remains in a local retry queue solely to complete revocation, until
revocation succeeds or the server rejects the expired token. Unsynced notes can
remain after sign-out so they are not lost; remove them in the extension's pending
items controls or uninstall the extension to clear its local data.

## How information is used and shared

Information is used to operate accounts, save and synchronize study material,
schedule reviews, show study progress and protect the service. It is not sold or
used for advertising, unrelated tracking, or credit/lending decisions.

The service uses Render for its API, Supabase for its database, and Netlify for
its web app. These providers process information needed to run those services,
including technical requests and potentially IP addresses in operational logs.
Problem metadata requests also reach LeetCode from the open LeetCode page; those
requests are subject to LeetCode's own policies. AnkiDSA is independent of LeetCode.

Release builds communicate with the fixed AnkiDSA API over HTTPS. This policy
does not promise that data transmission or storage can be completely risk-free.

## Retention and deletion

Account and study records are retained while you use the service, until you delete
the relevant problem or request account deletion. Deleting a problem through the
app removes its notes and associated review history from the active database.
Uninstalling the extension clears local extension data but does not delete the
server account or already synchronized study records.

For account deletion or other privacy requests, contact the operator above from
your account email. The current beta has no self-service account-deletion screen.
Operational logs and backup copies may outlive the active records until removed
or rotated. Backups are managed manually during the beta; contact the operator
for information about remaining backup copies when making a deletion request.

## Your controls and updates

You can disable automatic capture, choose which notes to save, edit/delete saved
problems, discard pending notes, sign out, or uninstall the extension. Android
reminders are opt-in and require the current notification-enabled APK. You can
request a password-reset link using Forgot your password? on the sign-in screen.

Updates to this policy will appear on the public privacy page with a revised
effective date. Contact the operator using the address above with privacy questions.
