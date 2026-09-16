const {test,expect,chromium}=require('@playwright/test');
const path=require('node:path');
test.describe.configure({mode:'serial'});
let ctx,worker,popup,lc,extensionId,email,token;
const profile=path.resolve('.work/e2e-'+Date.now());
const base='http://localhost:8081';
async function launch(offline=false) {
 ctx=await chromium.launchPersistentContext(profile,{
  channel:'chromium',headless:true,args:['--disable-extensions-except='+path.resolve('extension'),'--load-extension='+path.resolve('extension')],
  offline,
  viewport:{width:1280,height:900}});
 worker=ctx.serviceWorkers()[0] || await ctx.waitForEvent('serviceworker');
 extensionId=new URL(worker.url()).host;
 await ctx.route('https://leetcode.com/graphql/',route=>route.fulfill({json:{data:{question:{title:'Two Sum',difficulty:'Easy',topicTags:[{name:'Hash Table',slug:'hash-table'}]}}}}));
 await ctx.route('https://leetcode.com/problems/two-sum/**',route=>route.fulfill({contentType:'text/html',body:
  '<!doctype html><html><body><h1>1. Two Sum</h1><div class="text-difficulty-easy">Easy</div><button id="submit">Submit</button><div id="results"></div><script>document.getElementById("submit").onclick=()=>{document.getElementById("results").innerHTML="<span data-e2e-locator=\\"submission-result\\">Pending</span>";setTimeout(()=>document.querySelector("[data-e2e-locator]").textContent="Accepted",700)}</script></body></html>'}));
 popup=await ctx.newPage();
 await popup.goto('chrome-extension://'+extensionId+'/popup.html');
}
test.beforeAll(async()=>{
 email='browser-'+Date.now()+'@example.com';
 await launch();
});
test.afterAll(async()=>{await ctx?.close();});
test('account signup, accepted capture, note edit, and duplicate protection',async()=>{
 await popup.locator('#toggle-auth').click();
 await popup.locator('#name').fill('Sam');
 await popup.locator('#email').fill(email);
 await popup.locator('#password').fill('BrowserTest!2026');
 await popup.locator('#sign-in').click();
 await expect(popup.locator('#capture')).toBeVisible({timeout:20000});
 token=(await worker.evaluate(()=>chrome.storage.local.get('session'))).session.token;
 lc=await ctx.newPage();
 await lc.goto('https://leetcode.com/problems/two-sum/description/');
 await lc.locator('#submit').click();
 await expect.poll(async()=>{
  const r=await fetch(base+'/api/problems',{headers:{Authorization:'Bearer '+token}});return (await r.json()).length;
 },{timeout:20000}).toBe(1);
 const list=await (await fetch(base+'/api/problems',{headers:{Authorization:'Bearer '+token}})).json();
 expect(list[0].title).toBe('Two Sum');
 expect(list[0].difficulty).toBe('EASY');
 // Keep LeetCode active while the popup is rendered as a page for automation.
 await lc.bringToFront();
 await popup.reload();
 await expect(popup.locator('#problem-form')).toBeVisible({timeout:15000});
 await popup.locator('#notes').fill('Store each complement in a hash map. One pass, O(n).');
 await popup.locator('#save').click();
 await expect(popup.locator('#notice')).toContainText('Saved.',{timeout:15000});
 const updated=await (await fetch(base+'/api/problems',{headers:{Authorization:'Bearer '+token}})).json();
 expect(updated[0].notes).toContain('Store each complement');
 await lc.bringToFront();await lc.locator('#submit').click();await lc.waitForTimeout(1500);
 const after=await (await fetch(base+'/api/problems',{headers:{Authorization:'Bearer '+token}})).json();
 expect(after).toHaveLength(1);expect(after[0].notes).toContain('Store each complement');
 await popup.setViewportSize({width:400,height:760});
 await popup.screenshot({path:'.work/extension-saved.png',fullPage:true});
});
test('capture without pressing submit does not log old accepted results',async()=>{
 const another=await ctx.newPage();
 await another.goto('https://leetcode.com/problems/two-sum/description/');
 await another.evaluate(()=>{document.getElementById('results').innerHTML='<span data-e2e-locator="submission-result">Accepted</span>';});
 await another.waitForTimeout(800);
 const logs=await (await fetch(base+'/api/stats',{headers:{Authorization:'Bearer '+token}})).json();
 expect(logs.totalProblems).toBe(1);
 await another.close();
});
test('captured problem appears in Flutter, reviews successfully, and survives reload',async()=>{
 const app=await ctx.newPage();
 const errors=[];app.on('pageerror',e=>errors.push(e.message));
 await app.goto('http://localhost:3000');
 await app.bringToFront();
 await app.getByRole('textbox',{name:'Email',exact:true}).click();
 await app.keyboard.type(email,{delay:25});
 await app.getByRole('textbox',{name:'Password',exact:true}).click();
 await app.keyboard.type('BrowserTest!2026',{delay:25});
 await app.getByRole('button',{name:'Sign in',exact:true}).click();
 await expect(app.getByRole('button',{name:'Begin a review',exact:true})).toBeVisible({timeout:45000});
 await app.screenshot({path:'.work/app-captured-queue.png'});
 await app.getByRole('button',{name:'Begin a review',exact:true}).click();
 await expect(app.getByLabel('Store each complement in a hash map. One pass, O(n).',{exact:true})).toHaveCount(0);
 await app.getByRole('button',{name:'Reveal my notes',exact:true}).click();
 await expect(app.getByLabel('Store each complement in a hash map. One pass, O(n).',{exact:true})).toBeVisible();
 await app.screenshot({path:'.work/app-review.png'});
 await app.getByRole('button',{name:/^Good/}).click();
 await expect(app.getByRole('button',{name:'Back to my queue',exact:true})).toBeVisible({timeout:20000});
 await app.getByRole('button',{name:'Back to my queue',exact:true}).click();
 const stats=await (await fetch(base+'/api/stats',{headers:{Authorization:'Bearer '+token}})).json();
 expect(stats.totalReviews).toBe(1);expect(stats.retentionRate).toBe(100);expect(stats.dueToday).toBe(0);
 await app.reload();
 await expect(app.getByRole('button',{name:'Review queue 0',exact:true})).toBeVisible({timeout:20000});
 await expect(app.getByRole('group',{name:/A good place to pause\./})).toBeVisible();
 await app.setViewportSize({width:390,height:844});
 await app.screenshot({path:'.work/app-mobile-queue.png'});
 expect(errors).toEqual([]);
 await app.close();
});
test('LeetCode content scripts cannot read the session token or invoke account endpoints',async()=>{
 const cdp=await ctx.newCDPSession(lc);
 const contexts=[];
 cdp.on('Runtime.executionContextCreated',({context})=>contexts.push(context));
 await cdp.send('Runtime.enable');
 const isolated=contexts.find(c=>c.origin==='chrome-extension://'+extensionId);
 expect(isolated).toBeTruthy();
 const {result}=await cdp.send('Runtime.evaluate',{
  contextId:isolated.id,awaitPromise:true,returnByValue:true,
  expression:`(async()=>({
   storage:await chrome.storage.local.get('session').then(()=> 'allowed',()=> 'denied'),
   account:await chrome.runtime.sendMessage({type:'STATE'}),
   options:await chrome.runtime.sendMessage({type:'AUTH_OPTIONS'})
  }))()`
 });
 expect(result.value.storage).toBe('denied');
 expect(result.value.account.error).toBe('Unsupported request.');
 expect(result.value.options.error).toBe('Unsupported request.');
 expect(await lc.evaluate(()=>typeof chrome.runtime)).toBe('undefined');
 await cdp.detach();
});

test('offline edits survive browser restart and sync only to their original account',async()=>{
 test.setTimeout(120000);
 await lc.bringToFront();
 await popup.reload();
 await expect(popup.locator('#tracked')).toBeVisible();
 await ctx.setOffline(true);
 await popup.locator('#notes').fill('An offline note that must survive.');
 await popup.locator('#save').click();
 await expect(popup.locator('#notice')).toContainText('Saved on this browser.',{timeout:20000});
 await lc.bringToFront();
 await popup.reload();
 await expect(popup.locator('#notes')).toHaveValue('An offline note that must survive.');
 await popup.locator('#notes').fill('An offline note that must survive. Edited twice.');
 await popup.locator('#save').click();
 await expect(popup.locator('#notice')).toContainText('Saved on this browser.',{timeout:20000});
 await ctx.close();
 await launch(true);
 await expect(popup.locator('#pending-list')).toContainText('Two Sum');
 await popup.locator('#logout').click();
 await expect(popup.locator('#auth')).toBeVisible();
 await ctx.setOffline(false);
 await popup.locator('#toggle-auth').click();
 await popup.locator('#name').fill('Another account');
 await popup.locator('#email').fill('other-'+Date.now()+'@example.com');
 await popup.locator('#password').fill('BrowserTest!2026');
 await popup.locator('#sign-in').click();
 await expect(popup.locator('#capture')).toBeVisible();
 await expect(popup.locator('#pending-wrap')).toBeHidden();
 await expect(popup.locator('#total')).toHaveText('0');
 const original=await (await fetch(base+'/api/problems',{headers:{Authorization:'Bearer '+token}})).json();
 expect(original[0].notes).toBe('Store each complement in a hash map. One pass, O(n).');
 await popup.locator('#logout').click();
 await popup.locator('#toggle-auth').click();
 await popup.locator('#email').fill(email);
 await popup.locator('#password').fill('BrowserTest!2026');
 await popup.locator('#sign-in').click();
 await expect(popup.locator('#capture')).toBeVisible();
 await expect(popup.locator('#pending-wrap')).toBeHidden();
 await expect.poll(async()=>{
  const r=await fetch(base+'/api/problems',{headers:{Authorization:'Bearer '+token}});
  return (await r.json())[0].notes;
 }).toBe('An offline note that must survive. Edited twice.');
});
