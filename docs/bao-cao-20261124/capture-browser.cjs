const {chromium}=require('playwright');
const fs=require('fs'),assert=require('assert/strict');
const out=require('path').join(__dirname,'images');
const base=process.env.TEST_URL||'http://127.0.0.1:5326';
assert.ok((process.env.TEST_DATABASE||'').startsWith('TechNews_Verification_'),'Set TEST_DATABASE to the verification database used by this server');
(async()=>{
 const browser=await chromium.launch({channel:'msedge',headless:true});
 const context=await browser.newContext({viewport:{width:1440,height:1000}}),page=await context.newPage();
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 async function visit(path){const r=await page.goto(base+path,{waitUntil:"domcontentloaded"});assert.equal(r.status(),200,path);await page.waitForTimeout(350);}
 async function shot(name){await page.evaluate(()=>document.fonts.ready);await page.locator('img[src*="/images/products/official/"]').evaluateAll(async imgs=>await Promise.all(imgs.map(i=>{i.loading='eager';return i.decode()})));console.log('Capture '+name);await page.screenshot({path:out+'/'+name+'.png'});}
 await visit('/');await shot('01-trang-chu');
 const article=await page.locator('a[href*="-ar"]').first().getAttribute('href');
 await visit(article);await shot('02-bai-viet');
 await visit('/Shop');await shot('03-cua-hang');
 const product=await page.locator('.home-product-card').filter({hasText:'iPhone 16'}).locator('a[href^="/Shop/Product/"]').first().getAttribute('href');
 const secondProduct=await page.locator('.home-product-card').filter({hasText:'AirPods 4'}).locator('a[href^="/Shop/Product/"]').first().getAttribute('href');
 await visit(product);await shot('04-san-pham');
 await page.locator('.product-detail-add').click();await page.waitForTimeout(500);
 await visit(secondProduct);await page.locator('.product-detail-add').click();await page.waitForTimeout(500);
 await visit('/Shop/Cart');assert.ok(await page.locator('body').innerText().then(t=>t.includes('iPhone 16')&&t.includes('AirPods 4')));await shot('05-gio-hang');
 await visit('/Admin/Login');await page.locator('#name').fill('qa-admin');await page.locator('#password').fill(process.env.TEST_PASSWORD||'TechNews-Verify-2026!');
 await Promise.all([page.waitForURL('**/Admin/Articles'),page.locator('.login-submit').click()]);
 await visit('/Account');await shot('06-tai-khoan');
 await visit('/Shop/Checkout');await page.locator('#Recipient').fill('Khách hàng minh họa');await page.locator('#Phone').fill('0900000000');await page.locator('#ProvinceCode').selectOption('1');await page.locator('#WardCode').selectOption('4');await page.locator('#Address').fill('Địa chỉ minh họa phục vụ kiểm thử, không giao hàng thực tế');await shot('07-thanh-toan');
 await page.locator('#checkout-submit').click();await page.locator('#checkout-review').waitFor({state:'visible'});
 await Promise.all([page.waitForURL('**/Shop/Orders/*'),page.locator('#checkout-submit').click()]);
 const orderId=page.url().split('/').pop();await shot('08-don-hang');
 await visit('/Admin/ShopOrders/'+orderId);await shot('09-quan-ly-don');
 await visit('/Admin/Products?q=Apple');assert.ok(await page.locator('.admin-product-thumbnail img').first().evaluate(x=>x.complete&&x.naturalWidth>0));await shot('10-quan-ly-san-pham');
 await visit(product.replace('/Shop/Product/','/Admin/Products/')+'/Edit');assert.equal(await page.locator('#product-asset').count(),1);await shot('11-form-san-pham');
 await visit('/Admin/Workflow');await shot('12-bien-tap');
 await visit('/Shop/Orders/'+orderId+'/Address');await shot('19-sua-dia-chi');
 await visit('/Admin/ShopOrders?q='+orderId);await shot('20-danh-sach-don');
 const checks=[];
 for(const width of [375,768,1440]){
  await page.setViewportSize({width,height:1000});
  for(const path of ['/','/Shop',product,'/Shop/Cart','/Account','/Admin/Products/Create','/Admin/ShopOrders/'+orderId]){
   await visit(path);
   const overflow=await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1);
   checks.push({width,path,overflow});assert.equal(overflow,false,'horizontal overflow: '+width+' '+path);
  }
  if(width===375){await visit('/Shop');await shot('13-mobile-shop');await visit('/Account');await shot('14-mobile-account');}
 }
 assert.deepEqual(errors,[]);
 fs.writeFileSync(out+'/browser-results.json',JSON.stringify({capturedAt:new Date().toISOString(),browser:await browser.version(),checks,errors,orderId},null,2));
 await browser.close();console.log('PASS: browser purchase flow; 21 viewport checks; product thumbnails; 16 evidence images with real products.');
})().catch(e=>{console.error(e);process.exit(1)});
