(() => {
  if (globalThis.__ankiDsaLoaded) return;
  globalThis.__ankiDsaLoaded = true;
  const slug = () => /^\/problems\/([a-z0-9-]+)/.exec(location.pathname)?.[1];
  let armed = null, timer, metadata = new Map();
  async function readProblem() {
    const current = slug();
    if (!current) throw new Error('Open a LeetCode problem first.');
    let question = metadata.get(current);
    if (!question) {
      try {
        const res = await fetch('/graphql/', { method: 'POST', credentials: 'same-origin',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ query: 'query AnkiDsaQuestion($titleSlug: String!) { question(titleSlug: $titleSlug) { title difficulty topicTags { name slug } } }', variables: { titleSlug: current } }),
          signal: AbortSignal.timeout(5000) });
        if (res.ok) question = (await res.json()).data?.question;
        if (question) metadata.set(current, question);
      } catch { /* The visible page remains usable when metadata requests fail. */ }
    }
    const heading = document.querySelector('a[href="/problems/' + current + '/"], [data-cy="question-title"], h1');
    const difficulty = document.querySelector('[class*="text-difficulty-"], [data-difficulty]');
    return { leetcodeUrl: 'https://leetcode.com/problems/' + current + '/',
      title: question?.title || heading?.textContent?.trim().replace(/^\d+\.\s*/, '') || current.split('-').map(s => s[0].toUpperCase() + s.slice(1)).join(' '),
      difficulty: (question?.difficulty || difficulty?.textContent?.trim() || '').toUpperCase(),
      tags: (question?.topicTags || []).map(t => t.slug || t.name).join(', '), notes: '' };
  }
  function toast(text) {
    document.getElementById('ankidsa-toast')?.remove();
    const host = document.createElement('div'); host.id = 'ankidsa-toast';
    host.style.cssText = 'position:fixed;bottom:24px;right:24px;z-index:2147483647';
    const shadow = host.attachShadow({ mode: 'closed' });
    const box = document.createElement('div');
    box.style.cssText = 'max-width:320px;padding:18px 22px;background:#173f35;color:#fffdf7;border:1px solid #436b5c;border-radius:14px;box-shadow:0 8px 32px #0003;font:14px/1.5 system-ui';
    box.textContent = text; shadow.append(box); document.documentElement.append(host);
    setTimeout(() => host.remove(), 6000);
  }
  function result() {
    return [...document.querySelectorAll('[data-e2e-locator="submission-result"], [data-e2e-locator="console-result"], [data-submission-result]')]
      .find(el => el.getClientRects().length && el.textContent.trim() === 'Accepted');
  }
  function arm() {
    armed = { slug: slug(), at: Date.now(), previous: result(), changed: !result() };
  }
  document.addEventListener('click', e => {
    const button = e.target.closest('button, [role="button"]');
    if (button && (/^Submit\b/i.test(button.textContent.trim()) || /submit/i.test(button.getAttribute('data-e2e-locator') || ''))) arm();
  }, true);
  document.addEventListener('keydown', e => { if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') arm(); }, true);
  async function check() {
    if (!armed) return;
    if (Date.now() - armed.at > 120000 || slug() !== armed.slug) { armed = null; return; }
    const accepted = result();
    if (!accepted) { armed.changed = true; return; }
    if (!armed.changed && accepted === armed.previous) return;
    armed = null;
    try {
      const problem = await readProblem();
      if (!problem.difficulty) { toast('Accepted! Open AnkiDSA to choose the difficulty and save.'); return; }
      const response = await chrome.runtime.sendMessage({ type: 'CAPTURE', problem });
      if (response.error) toast(response.error);
      else if (!response.data?.skipped) toast(response.data?.pending ? 'Saved on this browser. AnkiDSA will sync when your server returns.' : 'Saved to AnkiDSA. Add what clicked from the extension.');
    } catch { toast('Open the AnkiDSA extension to save this problem.'); }
  }
  new MutationObserver(() => { clearTimeout(timer); timer = setTimeout(check, 200); }).observe(document.documentElement, { childList: true, subtree: true, characterData: true });
  chrome.runtime.onMessage.addListener((msg, sender, respond) => {
    if (msg.type !== 'READ_PROBLEM') return;
    readProblem().then(data => respond({ data }), e => respond({ error: e.message }));
    return true;
  });
})();
