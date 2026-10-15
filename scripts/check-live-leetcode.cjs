// Read-only check against a real public page. Never submits code or bypasses a challenge.
const {chromium} = require('@playwright/test');
const path = require('node:path');
(async () => {
  const extension = path.resolve('extension');
  const context = await chromium.launchPersistentContext(path.resolve('.work/live-leetcode-' + Date.now()), {
    channel: 'chromium', headless: true,
    args: ['--disable-extensions-except=' + extension, '--load-extension=' + extension],
  });
  try {
    const worker = context.serviceWorkers()[0] || await context.waitForEvent('serviceworker');
    const page = await context.newPage();
    await page.goto('https://leetcode.com/problems/two-sum/description/', {waitUntil: 'domcontentloaded', timeout: 45000});
    await page.waitForTimeout(5000);
    const result = await worker.evaluate(async () => {
      const tabs = await chrome.tabs.query({url: 'https://leetcode.com/problems/two-sum/*'});
      if (!tabs[0]) return {error: 'Problem tab missing'};
      return chrome.tabs.sendMessage(tabs[0].id, {type: 'READ_PROBLEM'});
    });
    if (result.error || result.data?.title !== 'Two Sum' || result.data?.difficulty !== 'EASY') {
      throw new Error('Public page metadata unavailable or changed; verify manually in Chrome.');
    }
    console.log('Live LeetCode read-only extraction passed: Two Sum / EASY. Accepted-submission capture still needs a signed-in manual check.');
  } finally { await context.close(); }
})().catch(() => { console.error('Live LeetCode extraction could not be verified. Check the page manually; no challenge bypass was attempted.'); process.exitCode = 1; });
