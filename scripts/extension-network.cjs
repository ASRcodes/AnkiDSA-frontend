const {chromium}=require('playwright'),path=require('path');
(async()=>{
const b=await chromium.launchPersistentContext(path.resolve('.work/network-'+Date.now()),{channel:'chromium',headless:true,args:['--disable-extensions-except='+path.resolve('extension'),'--load-extension='+path.resolve('extension')]});
b.on('request',async r=>{if(r.url().includes(':8081/')) console.log('Origin:',(await r.allHeaders()).origin)});
const w=b.serviceWorkers()[0]||await b.waitForEvent('serviceworker');
console.log(await w.evaluate(async()=>{const r=await fetch('http://localhost:8081/api/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:'demo@ankidsa.local',password:'DemoRecall!2026'})});return {status:r.status,body:r.ok?'success':await r.text()}}));
await b.close();
})().catch(console.error);
