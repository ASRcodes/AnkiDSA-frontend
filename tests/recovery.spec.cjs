const { test, expect } = require('@playwright/test');
const fs = require('node:fs/promises');
const path = require('node:path');

// Run against scripts/start-demo.ps1. Its mail sender writes locally, without SMTP.
const base = 'http://localhost:8081';
const outbox = path.join(process.env.ANKIDSA_BACKEND || 'C:/SpringBoot/ankidsa', '.local/outbox');

async function typeInto(page, label, value) {
  await page.getByRole('textbox', { name: label, exact: true }).click();
  await page.keyboard.press('ControlOrMeta+A');
  await page.keyboard.type(value, { delay: 15 });
}

async function resetLinkFor(email) {
  for (const file of await fs.readdir(outbox).catch(() => [])) {
    if (!file.endsWith('.eml')) continue;
    const content = await fs.readFile(path.join(outbox, file), 'utf8');
    if (content.startsWith('To: ' + email + '\n') && content.includes('Subject: Reset your AnkiDSA password')) {
      return content.match(/http:\/\/localhost:3000\/#\/reset-password\?token=[A-Za-z0-9_-]{43}/)?.[0];
    }
  }
}

test('recovery email link resets the password, revokes sessions, and cannot be replayed', async ({ page, request }) => {
  test.setTimeout(90000);
  const email = 'recovery-browser-' + Date.now() + '@ankidsa.local';
  const password = 'RecoveryBrowser!2026';
  const changed = 'ChangedBrowser!2026';
  const registered = await request.post(base + '/api/auth/register', {
    data: { email, password, name: 'Recovery check' }
  });
  expect(registered.ok()).toBe(true);
  const { token } = await registered.json();
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));

  await page.goto('http://localhost:3000');
  await page.getByRole('button', { name: 'Forgot your password?', exact: true }).click();
  await typeInto(page, 'Email', email);
  await page.getByRole('button', { name: 'Send a reset link', exact: true }).click();
  await expect(page.getByRole('button', { name: 'Use a different email', exact: true })).toBeVisible();
  let link;
  await expect.poll(async () => !!(link = await resetLinkFor(email))).toBe(true);

  await page.goto(link);
  await expect(page.getByRole('textbox', { name: 'New password', exact: true })).toBeVisible({ timeout: 15000 });
  await page.reload();
  await typeInto(page, 'New password', changed);
  await typeInto(page, 'Confirm new password', 'DifferentPassword!');
  await page.getByRole('button', { name: 'Set new password', exact: true }).click();
  // A mismatched confirmation must leave the original session valid.
  expect((await request.get(base + '/api/auth/verify', {
    headers: { Authorization: 'Bearer ' + token }
  })).status()).toBe(200);
  await typeInto(page, 'Confirm new password', changed);
  await page.getByRole('button', { name: 'Set new password', exact: true }).click();
  await expect(page.getByRole('button', { name: 'Return to sign in', exact: true })).toBeVisible();
  expect((await request.get(base + '/api/auth/verify', {
    headers: { Authorization: 'Bearer ' + token }
  })).status()).toBe(401);
  expect((await request.post(base + '/api/auth/login', { data: { email, password } })).status()).toBe(401);

  await page.getByRole('button', { name: 'Return to sign in', exact: true }).click();
  await expect.poll(() => new URL(page.url()).hash).toMatch(/^#?\/?$/);
  await typeInto(page, 'Email', email);
  await typeInto(page, 'Password', changed);
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
  await expect(page.getByRole('button', { name: 'Review queue 0', exact: true })).toBeVisible();

  await page.goto(link);
  await typeInto(page, 'New password', 'ThirdPassword!2026');
  await typeInto(page, 'Confirm new password', 'ThirdPassword!2026');
  await page.getByRole('button', { name: 'Set new password', exact: true }).click();
  await expect(page.getByRole('button', { name: 'Request a new link', exact: true })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Return to sign in', exact: true })).toHaveCount(0);
  expect((await request.post(base + '/api/auth/login', {
    data: { email, password: changed }
  })).status()).toBe(200);
  expect(errors).toEqual([]);
});
