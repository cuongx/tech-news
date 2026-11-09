const assert = require('node:assert/strict');
const {execFileSync} = require('node:child_process');
const base = process.env.TEST_URL || 'http://127.0.0.1:5307';
const database = process.env.TEST_DATABASE || 'TechNews_Verification_20261025';
assert.ok(database.startsWith('TechNews_Verification_'), 'Use verification database only');
function sql(query){return execFileSync('sqlcmd',['-S','localhost','-E','-C','-b','-d',database,'-h','-1','-W','-Q','SET NOCOUNT ON; '+query],{encoding:'utf8',windowsHide:true}).trim();}
function decode(s){return s.replace(/&#x([\da-f]+);/gi,(_,x)=>String.fromCodePoint(parseInt(x,16))).replace(/&#(\d+);/g,(_,x)=>String.fromCodePoint(+x)).replace(/&amp;/g,'&');}
function field(text,name){const tag=text.match(new RegExp('<input[^>]*name="'+name+'"[^>]*>','i')); assert.ok(tag,'missing '+name);return decode(tag[0].match(/value="([^"]*)"/)?.[1]||'');}
class Client {
 cookies=new Map();token='';
 async request(path,data,csrf=true){const headers={Cookie:[...this.cookies].map(([k,v])=>`${k}=${v}`).join('; ')};if(data&&csrf)headers.RequestVerificationToken=this.token;const r=await fetch(base+path,{method:data?'POST':'GET',headers,body:data?new URLSearchParams(data):undefined,redirect:'manual'});for(const c of r.headers.getSetCookie()){const pair=c.split(';')[0],i=pair.indexOf('=');this.cookies.set(pair.slice(0,i),pair.slice(i+1));}const text=await r.text();const token=text.match(/name="__RequestVerificationToken"[^>]*value="([^"]+)"/)?.[1]||text.match(/name="csrf-token" content="([^"]+)"/)?.[1];if(token)this.token=decode(token);return {status:r.status,text,location:r.headers.get('location')};}
 async login(name,returnUrl){await this.request('/Admin/Login');const r=await this.request('/Admin/Login',{name,password:process.env.TEST_PASSWORD||'TechNews-Verify-2026!',...(returnUrl?{returnUrl}:{})});assert.equal(r.status,302,'login '+name);return r;}
 async signup(name){await this.request('/Account/Register');assert.equal((await this.request('/Account/Register',{UserName:name,UserLogin:name,UserEmail:name+'@example.test',UserPassword:'TechNews-Verify-2026!',confirmPassword:'TechNews-Verify-2026!'})).status,302);await this.login(name);}
}
(async()=>{
 const admin=new Client(),reader=new Client(),other=new Client(),guest=new Client(),editor=new Client();
 await admin.login('qa-admin');await editor.login('qa-editor1');
 const stamp=Date.now();await reader.signup('shop-'+stamp);await other.signup('other-'+stamp);
 assert.equal((await guest.request('/Admin/Products')).status,302);
 assert.equal((await reader.request('/Admin/Products')).status,302);
 assert.equal((await editor.request('/Admin/Products')).status,302);
 await admin.request('/Admin/Products/Create');
 const data={Name:'QA_SHOP_'+stamp,Category:'QA',Description:'Integration test',Price:'125000',Stock:'3',IsActive:'true'};
 assert.equal((await admin.request('/Admin/Products/Save',data,false)).status,400,'CSRF required');
 assert.equal((await admin.request('/Admin/Products/Save',{...data,Price:'-1'})).status,200,'reject negative price');
 assert.equal((await admin.request('/Admin/Products/Save',data)).status,302,'create product');
 const listing=await admin.request('/Admin/Products?q='+data.Name);
 const id=listing.text.match(/\/Admin\/Products\/(\d+)\/Edit/)?.[1];assert.ok(id);
 const product=await guest.request('/Shop/Product/'+id);assert.equal(product.status,200);assert.ok(product.text.includes('125.000'),'display VND price');
 assert.equal((await guest.request('/Shop?q='+data.Name)).status,200);
 await reader.request('/Shop/Product/'+id);
 await reader.request('/Shop/Cart/Add/'+id,{quantity:'4'});assert.equal(sql('SELECT Stock FROM Products WHERE Id='+id),'3');assert.ok(!(await reader.request('/Shop/Cart')).text.includes(data.Name),'overstock not added');
 await reader.request('/Shop/Cart/Add/'+id,{quantity:'2'});
 let checkout=await reader.request('/Shop/Checkout');assert.equal(checkout.status,200);
 let token=field(checkout.text,'Token');const shipping={Token:token,Recipient:'QA Customer',Phone:'0901234567',Address:'Test address',Note:'Test order',Total:'1'};
 assert.equal((await reader.request('/Shop/Checkout',{...shipping,Phone:'x'})).status,200,'invalid shipping');
 const edit=await admin.request('/Admin/Products/'+id+'/Edit');const version=field(edit.text,'Version');
 assert.equal((await admin.request('/Admin/Products/Save',{...data,Id:id,Version:version,Price:'150000'})).status,302);
 const repriced=await reader.request('/Shop/Checkout',shipping);assert.equal(repriced.status,200,'price change needs confirmation');assert.equal(sql('SELECT COUNT(*) FROM ShopOrders WHERE CheckoutToken=\''+token+'\''),'0');
 const placed=await reader.request('/Shop/Checkout',shipping);assert.equal(placed.status,302);const order=placed.location.match(/\d+$/)?.[0];assert.ok(order);
 assert.equal(sql('SELECT Total FROM ShopOrders WHERE Id='+order),'300000','server price ignores posted total');assert.equal(sql('SELECT Stock FROM Products WHERE Id='+id),'1');
 assert.equal((await reader.request('/Shop/Checkout',shipping)).location,placed.location,'idempotent replay');assert.equal(sql('SELECT Stock FROM Products WHERE Id='+id),'1');
 assert.equal((await other.request('/Shop/Orders/'+order)).status,404,'order ownership');assert.equal((await reader.request('/Shop/Orders/'+order)).status,200);
 assert.equal((await admin.request('/Admin/Products/Save',{...data,Id:id,Version:version,Stock:'99'})).status,200,'stale stock edit rejected');assert.equal(sql('SELECT Stock FROM Products WHERE Id='+id),'1');
 let orderPage=await admin.request('/Admin/ShopOrders/'+order);let orderVersion=field(orderPage.text,'version');
 await admin.request('/Admin/ShopOrders/'+order+'/Status',{target:'Completed',version:orderVersion});assert.equal(sql('SELECT Status FROM ShopOrders WHERE Id='+order),'Pending','invalid transition rejected');
 await admin.request('/Admin/ShopOrders/'+order+'/Status',{target:'Cancelled',version:orderVersion,reason:'QA cancellation'});assert.equal(sql('SELECT Stock FROM Products WHERE Id='+id),'3');
 await admin.request('/Admin/ShopOrders/'+order+'/Status',{target:'Cancelled',version:orderVersion});assert.equal(sql('SELECT Stock FROM Products WHERE Id='+id),'3','cancellation restores stock only once');
 await reader.request('/Shop/Product/'+id);await reader.request('/Shop/Cart/Add/'+id,{quantity:'1'});checkout=await reader.request('/Shop/Checkout');
 const second=await reader.request('/Shop/Checkout',{...shipping,Token:field(checkout.text,'Token')});const secondId=second.location.match(/\d+$/)[0];
 for(const target of ['Confirmed','Shipping','Completed']){orderPage=await admin.request('/Admin/ShopOrders/'+secondId);await admin.request('/Admin/ShopOrders/'+secondId+'/Status',{target,version:field(orderPage.text,'version')});assert.equal(sql('SELECT Status FROM ShopOrders WHERE Id='+secondId),target);}
 assert.equal((await reader.request('/Shop/Orders')).status,200);assert.equal((await admin.request('/Admin/ShopOrders')).status,200);
 const loginBack=new Client();assert.equal((await loginBack.login('qa-admin','/Shop/Checkout')).location,'/Shop/Checkout');assert.ok(!(await loginBack.login('qa-admin','https://example.com')).location.startsWith('https:'),'no open redirect');
 // Two buyers contend for the final item: only one order may reserve it.
 sql('UPDATE Products SET Stock=1 WHERE Id='+id);
 for(const buyer of [reader,other]){await buyer.request('/Shop/Product/'+id);await buyer.request('/Shop/Cart/Add/'+id,{quantity:'1'});}
 const checkouts=await Promise.all([reader.request('/Shop/Checkout'),other.request('/Shop/Checkout')]);
 const race=await Promise.all([reader,other].map((buyer,i)=>buyer.request('/Shop/Checkout',{...shipping,Token:field(checkouts[i].text,'Token')})));
 assert.equal(race.filter(r=>r.status==302).length,1,'one last-item order');assert.equal(sql('SELECT Stock FROM Products WHERE Id='+id),'0');assert.ok(race.every(r=>[200,302].includes(r.status)),'loser receives validation instead of server error');
 console.log('PASS: prices, admin/reader permissions, CSRF, validation, cart limits, repricing confirmation, server totals, checkout replay, order ownership, stale stock edit, cancellation, COD workflow, safe return URL, concurrent last-item checkout.');
})().catch(e=>{console.error(e);process.exitCode=1});
