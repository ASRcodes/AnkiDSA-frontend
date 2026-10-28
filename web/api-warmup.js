// Begin waking the API while Flutter downloads. Never delay rendering.
(() => {
  const origin = document.querySelector('meta[name="ankidsa-api"]')?.content;
  if (!origin) return;
  try {
    const url = new URL(origin);
    if (url.protocol !== 'https:') return;
    fetch(url.origin + '/ready', {
      credentials: 'omit', redirect: 'error', cache: 'no-store',
      signal: AbortSignal.timeout(10000)
    }).catch(() => {});
  } catch { /* Startup remains available offline or on older browsers. */ }
})();
