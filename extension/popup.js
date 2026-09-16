import { serverUrl } from './core.js';
const $ = id => document.getElementById(id);
let state, problem, existing, register = false;
let recoveryAvailable = false;
async function send(type, data = {}) {
  const response = await chrome.runtime.sendMessage({ type, ...data });
  if(response.error) throw new Error(response.error);
  return response.data;
}
function notice(text, error = false) { $('notice').hidden = false; $('notice').textContent = text; $('notice').classList.toggle('error', error); }
function view(id) { ['auth','capture','preferences'].forEach(s => $(s).hidden = s !== id); }
async function busy(button, action) {
  button.disabled = true;
  try { await action(); } catch(e) { notice(e.message, true); }
  finally { button.disabled = false; }
}
function pending() {
  $('pending-wrap').hidden = !state.pending.length;
  $('pending-list').replaceChildren();
  for (const item of state.pending) {
    const el = document.createElement('div'); el.className = 'pending-item';
    const title = document.createElement('strong'); title.textContent = item.problem.title;
    const desc = document.createElement('p'); desc.textContent = item.error || 'Saved on this browser. Waiting for the server.';
    const discard = document.createElement('button'); discard.className='text-button'; discard.textContent='Remove from sync queue';
    discard.onclick=() => busy(discard,async() => { await send('DISCARD',{url:item.problem.leetcodeUrl}); await load(); });
    el.append(title,desc,discard); $('pending-list').append(el);
  }
}
async function load() {
  state = await send('STATE');
  view(state.signedIn ? 'capture' : 'auth');
  if (!state.signedIn) {
    send('AUTH_OPTIONS').then(options => {
      recoveryAvailable = options.passwordRecovery === true;
      $('forgot-password').hidden = register || !recoveryAvailable;
    }).catch(() => { $('forgot-password').hidden = true; });
    return;
  }
  $('greeting').textContent = 'Hello, ' + (state.name || 'there').split(' ')[0] + '.';
  pending();
  let problems=[];
  try {
    const data=await send('DASHBOARD'); problems=data.problems;
    $('due').textContent=data.stats.dueToday; $('total').textContent=data.stats.totalProblems;
  } catch(e) {
    notice(e.message,true);
    state=await send('STATE'); if(!state.signedIn) { view('auth'); return; }
  }
  try {
    const [tab]=await chrome.tabs.query({ active:true,currentWindow:true });
    if(tab?.url?.startsWith('https://leetcode.com/problems/')) {
      const result=await chrome.tabs.sendMessage(tab.id,{type:'READ_PROBLEM'});
      if(result.error) throw new Error(result.error);
      problem=result.data;
    } else problem=null;
  } catch { problem=null; notice('Refresh your LeetCode tab, then reopen this extension.',true); }
  $('no-problem').hidden=!!problem; $('problem-form').hidden=!problem;
  if(problem) {
    const pendingItem=state.pending.find(p => p.problem.leetcodeUrl===problem.leetcodeUrl);
    existing=problems.find(p => p.leetcodeUrl===problem.leetcodeUrl)
      || (pendingItem?.id ? { ...pendingItem.problem, id:pendingItem.id, version:pendingItem.version } : null);
    const draft=pendingItem?.problem;
    const value=draft || existing || problem;
    $('title').value=value.title; $('difficulty').value=value.difficulty;
    $('tags').value=Array.isArray(value.tags) ? value.tags.join(', ') : value.tags;
    $('notes').value=value.notes || '';
    $('tracked').hidden=!existing;
    $('save').textContent=existing ? 'Update my notes ↗' : 'Save to my collection ↗';
  }
}
$('auth-form').onsubmit=e => { e.preventDefault(); busy($('sign-in'),async() => {
  await send('AUTH',{register,credentials:{email:$('email').value.trim(),password:$('password').value,name:$('name').value.trim()}});
  $('password').value=''; $('notice').hidden=true; await load();
}); };
$('toggle-auth').onclick=() => {
  register=!register; $('name-label').hidden=!register;
  $('forgot-password').hidden=register || !recoveryAvailable;
  $('password').autocomplete=register ? 'new-password' : 'current-password';
  $('sign-in').textContent=register ? 'Create account' : 'Sign in';
  $('toggle-auth').textContent=register ? 'Already have an account? Sign in' : 'New here? Create an account';
};
$('problem-form').onsubmit=e => { e.preventDefault(); busy($('save'),async() => {
  const result=await send('SAVE',{problem:{...problem,title:$('title').value,difficulty:$('difficulty').value,tags:$('tags').value,notes:$('notes').value},id:existing?.id,version:existing?.version});
  await load(); notice(result.pending ? 'Saved on this browser. We will retry the sync automatically.' : 'Saved. Your next review starts with this insight.');
}); };
$('settings').onclick=() => { $('base-url').value=state.baseUrl; $('app-url').value=state.appUrl; $('auto-save').checked=state.autoSave; view('preferences'); };
$('settings-form').onsubmit=e => { e.preventDefault(); busy(e.submitter,async() => {
  const baseUrl=serverUrl($('base-url').value),appUrl=serverUrl($('app-url').value);
  const granted=await chrome.permissions.request({origins:[baseUrl+'/*']});
  if(!granted) throw new Error('Server access was not granted. Your settings have not changed.');
  await send('SETTINGS',{baseUrl,appUrl,autoSave:$('auto-save').checked}); await load(); notice('Connection saved.');
}); };
$('cancel-settings').onclick=() => load().catch(e => notice(e.message,true));
$('home').onclick=e => { e.preventDefault(); load().catch(e => notice(e.message,true)); };
$('logout').onclick=() => busy($('logout'),async() => { await send('LOGOUT'); await load(); });
$('sync').onclick=() => busy($('sync'),async() => { await send('SYNC'); await load(); });
$('open-app').onclick=() => chrome.tabs.create({url:state.appUrl});
$('forgot-password').onclick=() => chrome.tabs.create({url:state.appUrl+'/#/forgot-password'});
load().catch(e => notice(e.message,true));
