# AnkiDSA extension privacy

The extension reads the title, difficulty, topic tags, and canonical URL of an open LeetCode problem. With automatic saving enabled, it watches for an Accepted result after you submit a solution. It sends that problem metadata and any notes you enter to the AnkiDSA server you configure.

It does not collect source code, LeetCode passwords, cookies, browsing history outside LeetCode problem pages, or analytics. LeetCode metadata requests are made on the LeetCode page itself. Your AnkiDSA password is used for sign-in and is not saved.

The session token, connection settings, and unsynced problem notes are kept in this browser's local extension storage. Content scripts are denied access to that storage. Tokens are never passed to the LeetCode page. Signing out removes the active session; pending notes remain separated by server and account. Remove pending items in the popup or uninstall the extension to clear its local data.

Your server stores account details, problem metadata, notes, and review history. Deleting a problem from the app deletes its notes and history from that server. Before publishing, the operator must supply their identity, contact address, retention policy, and a hosted copy of this policy.
