import { canonicalProblem, serverUrl, cleanProblem } from './core.js';

import { defaults } from './config.js';
const ready = chrome.storage.local.setAccessLevel({ accessLevel: 'TRUSTED_CONTEXTS' });
let tasks = Promise.resolve();
function serial(task) { const next = tasks.then(task); tasks = next.catch(() => {}); return next; }
async function state() {
  await ready;
  const data = await chrome.storage.local.get();
  if (defaults.production && data.baseUrl && data.baseUrl !== defaults.baseUrl) {
    // Keep unsynced drafts under their original account/server key.
    await chrome.storage.local.remove('session');
    await chrome.storage.local.set({ baseUrl: defaults.baseUrl, appUrl: defaults.appUrl });
    delete data.session;
    data.baseUrl = defaults.baseUrl;
    data.appUrl = defaults.appUrl;
  }
  return { ...defaults, ...data };
}
function account(s) { return s.baseUrl + '|' + s.session?.email; }
const warmed = new Map();
async function wake(baseUrl) {
  if (!defaults.production || Date.now() - (warmed.get(baseUrl) || 0) < 300000) return;
  const deadline = Date.now() + 180000;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(baseUrl + '/ready', { credentials: 'omit', redirect: 'error', cache: 'no-store', signal: AbortSignal.timeout(Math.max(1, Math.min(10000, deadline - Date.now()))) });
      if (response.ok) { warmed.set(baseUrl, Date.now()); return; }
    } catch { /* Only the readiness probe is retried. */ }
    const remaining = deadline - Date.now();
    if (remaining > 0) await new Promise(resolve => setTimeout(resolve, Math.min(2000, remaining)));
  }
  throw Object.assign(new Error('AnkiDSA is waking up. Please retry shortly; queued problems remain on this browser.'), { retry: true });
}
async function api(s, path, method = 'GET', body, authenticated = true, clearSession = true) {
  if (defaults.production && s.baseUrl !== defaults.baseUrl) throw new Error('This release connects only to the configured AnkiDSA server.');
  await wake(s.baseUrl);
  let res;
  try {
    res = await fetch(serverUrl(s.baseUrl) + path, { method, credentials: 'omit', redirect: 'error', cache: 'no-store',
      headers: { 'Content-Type': 'application/json', ...(authenticated && s.session?.token ? { Authorization: 'Bearer ' + s.session.token } : {}) },
      ...(body ? { body: JSON.stringify(body) } : {}), signal: AbortSignal.timeout(25000) });
  } catch { throw Object.assign(new Error('Server unavailable. Your saved problems will sync when it returns.'), { retry: true }); }
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    if (res.status >= 500) warmed.delete(s.baseUrl);
    if (res.status === 401 && authenticated && clearSession) await chrome.storage.local.set({ session: { ...s.session, token: null } });
    throw Object.assign(new Error(data.message || 'Could not complete this request.'), { status: res.status, retry: res.status >= 500 || res.status === 429 });
  }
  return data;
}
async function flush() {
  const s = await state();
  if (!s.session?.token) return;
  const queues = s.queues || {};
  const key = account(s);
  const queue = queues[key] || [];
  for (const item of [...queue]) {
    if (item.blocked) continue;
    try {
      await api(s, item.id ? '/api/problems/' + item.id : '/api/problems', item.id ? 'PUT' : 'POST',
        { ...item.problem, ...(item.id ? { version: item.version } : {}) });
      queue.splice(queue.indexOf(item), 1);
    } catch (e) {
      if (e.status === 409 && !item.id && !item.problem.notes.trim()) queue.splice(queue.indexOf(item), 1);
      else { item.error = e.message; item.blocked = !e.retry && e.status !== 401; }
      if (e.retry || e.status === 401) break;
    }
  }
  queues[key] = queue;
  await chrome.storage.local.set({ queues });
  await chrome.action.setBadgeText({ text: queue.length ? String(queue.length) : '' });
  await chrome.action.setBadgeBackgroundColor({ color: '#BD653F' });
}
async function save(problem, id, version) {
  const s = await state();
  if (!s.session?.token) throw new Error('Sign in to AnkiDSA first.');
  const value = cleanProblem(problem);
  const queues = s.queues || {}, key = account(s), queue = queues[key] || [];
  const old = queue.find(q => q.problem.leetcodeUrl === value.leetcodeUrl);
  if (old && !value.notes && old.problem.notes) {
    // A second accepted submission must not erase an unsynced handwritten note.
    await flush();
    return { pending: !!((await state()).queues?.[key] || []).find(q => q.problem.leetcodeUrl === value.leetcodeUrl) };
  }
  if (!old && queue.length >= 50) throw new Error('Your sync queue is full. Sync it before saving another problem.');
  const item = { problem: value, id, version, savedAt: Date.now() };
  if (old) queue.splice(queue.indexOf(old), 1, item); else queue.push(item);
  queues[key] = queue;
  await chrome.storage.local.set({ queues });
  await flush();
  const after = await state();
  const pending = (after.queues?.[key] || []).find(q => q.problem.leetcodeUrl === value.leetcodeUrl);
  if (pending?.blocked) throw new Error(pending.error);
  return { pending: !!pending };
}
async function handle(message, sender) {
  const trusted = sender.id === chrome.runtime.id && sender.url?.startsWith(chrome.runtime.getURL(''));
  if (!trusted) {
    if (message.type !== 'CAPTURE' || sender.frameId !== 0 || !sender.tab) throw new Error('Unsupported request.');
    const source = canonicalProblem(sender.url);
    if (source !== canonicalProblem(message.problem?.leetcodeUrl)) throw new Error('Problem does not match this tab.');
    const s = await state();
    if (!s.autoSave || !s.session?.token) return { skipped: true };
    // Automatic captures never overwrite notes on an already tracked problem.
    return save(message.problem);
  }
  const s = await state();
  switch (message.type) {
    case 'STATE': return { baseUrl: s.baseUrl, appUrl: s.appUrl, autoSave: s.autoSave,
      signedIn: !!s.session?.token, name: s.session?.name, email: s.session?.email,
      pending: s.queues?.[account(s)] || [] };
    case 'AUTH': {
      const session = await api(s, '/api/auth/' + (message.register ? 'register' : 'login'), 'POST', message.credentials, false);
      await chrome.storage.local.set({ session }); await flush(); return { ok: true };
    }
    case 'AUTH_OPTIONS': return api(s, '/api/auth/options', 'GET', undefined, false);
    case 'LOGOUT': {
      // Clear local access even when the sleeping server cannot confirm revocation.
      const pending = [...(s.pendingLogouts || []), ...(s.session?.token ? [{ baseUrl: s.baseUrl, session: s.session }] : [])];
      await chrome.storage.local.set({ pendingLogouts: pending });
      await chrome.storage.local.remove('session');
      await chrome.action.setBadgeText({ text: '' });
      await revokePending();
      return {};
    }
    case 'SETTINGS': {
      const baseUrl = serverUrl(message.baseUrl), appUrl = serverUrl(message.appUrl);
      if (defaults.production && (baseUrl !== defaults.baseUrl || appUrl !== defaults.appUrl)) throw new Error('Server addresses are fixed in this release.');
      if (!await chrome.permissions.contains({ origins: [baseUrl + '/*'] })) throw new Error('Allow access to that server first.');
      await chrome.storage.local.set({ baseUrl, appUrl, autoSave: !!message.autoSave });
      if (baseUrl !== s.baseUrl) await chrome.storage.local.remove('session');
      return {};
    }
    case 'SAVE': return save(message.problem, message.id, message.version);
    case 'SYNC': await flush(); return {};
    case 'DISCARD': {
      const queues=s.queues || {}, key=account(s);
      queues[key]=(queues[key] || []).filter(q => q.problem.leetcodeUrl!==message.url);
      await chrome.storage.local.set({ queues }); await flush(); return {};
    }
    case 'DASHBOARD': {
      // Finish both requests before the next account mutation can run.
      const results = await Promise.allSettled([api(s,'/api/stats'), api(s,'/api/problems')]);
      for (const result of results) if (result.status === 'rejected') throw result.reason;
      const [stats, problems] = results.map(result => result.value);
      return { stats, problems };
    }
    default: throw new Error('Unsupported request.');
  }
}
async function revokePending() {
  const pending = (await state()).pendingLogouts || [], remaining = [];
  for (const item of pending) {
    try { await api(item, '/api/auth/logout', 'POST', {}, true, false); }
    catch (e) { if (e.status !== 401) remaining.push(item); }
  }
  await chrome.storage.local.set({ pendingLogouts: remaining });
}
chrome.runtime.onMessage.addListener((message, sender, respond) => {
  const task = message.type === 'AUTH_OPTIONS' ? handle(message, sender) : serial(() => handle(message, sender));
  task.then(data => respond({ data }), error => respond({ error: error.message }));
  return true;
});
chrome.alarms.onAlarm.addListener(alarm => { if (alarm.name === 'sync') serial(async () => { await revokePending(); await flush(); }); });
chrome.runtime.onInstalled.addListener(() => chrome.alarms.create('sync', { periodInMinutes: 1 }));
chrome.runtime.onStartup.addListener(() => { chrome.alarms.create('sync', { periodInMinutes: 1 }); serial(flush); });
