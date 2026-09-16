export function canonicalProblem(raw) {
  const u = new URL(raw);
  const match = /^\/problems\/([a-z0-9-]+)(?:\/.*)?$/.exec(u.pathname);
  if (u.protocol !== 'https:' || u.hostname !== 'leetcode.com' || u.port || u.username || u.password || !match) throw new Error('Open a LeetCode problem first.');
  return 'https://leetcode.com/problems/' + match[1] + '/';
}
export function serverUrl(raw) {
  const u = new URL(raw);
  const local = ['localhost', '127.0.0.1'].includes(u.hostname);
  if ((!local && u.protocol !== 'https:') || !['http:', 'https:'].includes(u.protocol) || u.username || u.password || u.search || u.hash || !['','/'].includes(u.pathname))
    throw new Error('Use an HTTPS server address, or localhost for a local demo.');
  return u.origin;
}
export function cleanProblem(p) {
  const title = String(p.title || '').trim();
  if (!title || title.length > 500) throw new Error('Add a problem title (up to 500 characters).');
  if (!['EASY', 'MEDIUM', 'HARD'].includes(p.difficulty)) throw new Error('Choose the problem difficulty.');
  return { leetcodeUrl: canonicalProblem(p.leetcodeUrl), title, difficulty: p.difficulty,
    tags: String(p.tags || '').slice(0, 2000), notes: String(p.notes || '').slice(0, 20000) };
}
