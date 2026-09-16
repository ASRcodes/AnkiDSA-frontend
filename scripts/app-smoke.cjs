const {chromium,expect}=require('@playwright/test');

(async()=>{
 const browser=await chromium.launch({headless:true});
 try {
  const page=await browser.newPage({viewport:{width:1440,height:1000}});
  const errors=[];
  page.on('pageerror',error=>errors.push(error.message));
  await page.goto('http://localhost:3000');
  await page.getByRole('button',{name:'Fill demo account',exact:true}).click();
  await page.getByRole('button',{name:'Sign in',exact:true}).click();
  await expect(page.getByRole('button',{name:'Begin a review',exact:true})).toBeVisible({timeout:30000});
  await page.screenshot({path:'.work/app-queue.png'});
  await page.getByRole('button',{name:'Collection',exact:true}).click();
  await expect(page.getByRole('textbox',{name:/Search/})).toBeVisible();
  await page.screenshot({path:'.work/app-collection.png'});
  await page.getByRole('button',{name:'Insights',exact:true}).click();
  await page.screenshot({path:'.work/app-insights.png'});
  await page.setViewportSize({width:390,height:844});
  await page.screenshot({path:'.work/app-mobile-insights.png'});
  expect(errors).toEqual([]);
  console.log('Sample account sign-in and desktop/mobile screenshots passed.');
 } finally { await browser.close(); }
})().catch(error=>{console.error(error);process.exitCode=1;});
