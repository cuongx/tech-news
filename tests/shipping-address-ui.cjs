const assert=require('node:assert/strict'),fs=require('node:fs'),{execFileSync}=require('node:child_process'),{chromium}=require('playwright');
const base=process.env.TEST_URL||'http://127.0.0.1:5331',database=process.env.TEST_DATABASE||'TechNews_Verification_20261025';
assert.ok(database.startsWith('TechNews_Verification_'));
(async()=>{
 const product=execFileSync('sqlcmd',['-S','localhost','-E','-C','-b','-d',database,'-h','-1','-W','-Q',"SET NOCOUNT ON; INSERT Products(Name,Category,Price,Stock,IsActive) OUTPUT INSERTED.Id VALUES('QA_ADDRESS_UI','QA',125000,10,1)"],{encoding:'utf8',windowsHide:true}).trim();
 const browser=await chromium.launch({channel:'msedge',headless:true});
 try{
 const page=await browser.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto(base+'/Admin/Login');await page.locator('#name').fill('qa-admin');await page.locator('#password').fill(process.env.TEST_PASSWORD||'TechNews-Verify-2026!');await page.locator('.login-submit').click();
 await page.goto(base+'/Shop/Product/'+product);await page.locator('.product-detail-add').click();await page.waitForFunction(()=>document.querySelector('[data-cart-count]').textContent==='1');
 await page.goto(base+'/Shop/Checkout');assert.equal(await page.locator('#WardCode').isDisabled(),true);
 await page.locator('#Recipient').fill('QA Browser');await page.locator('#Phone').fill('0901234567');await page.locator('#Address').fill('12 Test Street');
 await page.locator('#ProvinceCode').selectOption('1');await page.locator('#WardCode').selectOption('4');await page.locator('#checkout-submit').click();assert.equal(await page.locator('#checkout-review').isVisible(),true);
 assert.match(await page.locator('#checkout-address').innerText(),/12 Test Street, Phường Ba Đình, Thành phố Hà Nội/);
 const catalogue=require('../TechNews/Data/vietnam-addresses.json'),next=String(catalogue[1].code);
 await page.locator('#ProvinceCode').selectOption(next);assert.equal(await page.locator('#WardCode').inputValue(),'');assert.equal(await page.locator('#checkout-review').isVisible(),false);
 await page.locator('#ProvinceCode').selectOption('1');await page.locator('#WardCode').selectOption('4');
 for(const width of [375,768,1440]){await page.setViewportSize({width,height:1000});assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'checkout width '+width);}
 await page.locator('#checkout-submit').click();await page.locator('#checkout-submit').click();await page.waitForURL(/\/Shop\/Orders\/\d+$/);
 const order=page.url();await page.goto(order+'/Address');assert.equal(await page.locator('#ProvinceCode').inputValue(),'1');assert.equal(await page.locator('#WardCode').inputValue(),'4');assert.equal(await page.locator('#Address').inputValue(),'12 Test Street');
 await page.locator('#Address').fill('34 <script>window.addressXss=true</script> Street');await page.locator('.shop-form button[type=submit]').click();await page.waitForURL(order);
 assert.equal(await page.evaluate(()=>window.addressXss),undefined);assert.ok((await page.locator('.order-history').textContent()).includes('34 <script>'));
 await page.goto(order+'/Address');
 for(const width of [375,768,1440]){await page.setViewportSize({width,height:1000});assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'edit width '+width);}
 const output=process.env.TEST_ARTIFACTS||'C:/Users/acer/technews-address-20261125/browser';fs.mkdirSync(output,{recursive:true});await page.screenshot({path:output+'/edit-address.png',fullPage:true});
 const context=await browser.newContext({javaScriptEnabled:false,storageState:await page.context().storageState()});const nojs=await context.newPage();await nojs.goto(order+'/Address');assert.equal(await nojs.locator('#WardCode optgroup').count(),34);await nojs.locator('#Address').fill('56 No JavaScript Street');await nojs.locator('.shop-form button[type=submit]').click();await nojs.waitForURL(order);await context.close();
 assert.deepEqual(errors,[]);fs.writeFileSync(output+'/results.json',JSON.stringify({passed:true,widths:[375,768,1440],checks:['cascade','review/reset','canonical address','edit preselection','HTML encoding','no-JavaScript edit'],errors},null,2));console.log('PASS shipping address browser');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
