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
 const admin=new Client(),owner=new Client(),other=new Client(),guest=new Client();
 await admin.login('qa-admin');
 const stamp=Date.now();await owner.signup('order-'+stamp);await other.signup('outsider-'+stamp);
 const product=sql("INSERT Products(Name,Category,Price,Stock,IsActive) OUTPUT INSERTED.Id VALUES(N'QA_ORDER_"+stamp+"',N'QA',125000,20,1)");
 const stock=()=>sql('SELECT Stock FROM Products WHERE Id='+product);
 const status=id=>sql('SELECT Status FROM ShopOrders WHERE Id='+id);
 const count=id=>sql('SELECT COUNT(*) FROM ShopOrderEvents WHERE ShopOrderId='+id);
 async function place(){
  await owner.request('/Shop/Product/'+product);await owner.request('/Shop/Cart/Add/'+product,{quantity:'2'});
  const checkout=await owner.request('/Shop/Checkout');assert.equal(checkout.status,200);
  assert.ok(checkout.text.includes('checkout-review'));
  const input={Token:field(checkout.text,'Token'),Recipient:'QA Owner',Phone:'0901234567',Address:'QA address'};
  const placed=await owner.request('/Shop/Checkout',input);assert.equal(placed.status,302);
  const id=placed.location.match(/\d+$/)[0];assert.equal(count(id),'1');
  assert.equal((await owner.request('/Shop/Checkout',input)).location,placed.location);assert.equal(count(id),'1','replay does not duplicate history');
  const page=await owner.request(placed.location);assert.ok(page.text.includes('order-success'));assert.ok(page.text.includes('order-timeline'));
  return {id,version:field(page.text,'version')};
 }
 async function move(id,target,reason){const page=await admin.request('/Admin/ShopOrders/'+id);return admin.request('/Admin/ShopOrders/'+id+'/Status',{target,reason:reason||'',version:field(page.text,'version')});}
 const first=await place(),url='/Shop/Orders/'+first.id+'/Cancel';assert.equal(stock(),'18');
 assert.equal((await guest.request(url,{version:first.version,reason:'test'})).status,302);
 await other.request('/Shop/Product/'+product);
 assert.equal((await other.request(url,{version:first.version,reason:'test'})).status,404);
 assert.equal((await owner.request(url,{version:first.version,reason:'test'},false)).status,400);
 assert.equal((await owner.request(url,{version:'invalid!',reason:'test'})).status,400);
 for(const reason of ['', '   ', 'x'.repeat(501)]){await owner.request(url,{version:first.version,reason});assert.equal(status(first.id),'Pending');assert.equal(stock(),'18');assert.equal(count(first.id),'1');}
 await move(first.id,'Confirmed');assert.equal(count(first.id),'2');
 await owner.request(url,{version:first.version,reason:'stale request'});assert.equal(status(first.id),'Confirmed');assert.equal(stock(),'18');
 const current=await owner.request('/Shop/Orders/'+first.id),version=field(current.text,'version');
 const reason='<script>alert(1)</script> changed my mind';
 const race=await Promise.all([owner.request(url,{version,reason}),admin.request('/Admin/ShopOrders/'+first.id+'/Status',{target:'Cancelled',version,reason})]);
 assert.ok(race.every(r=>r.status===302));assert.equal(status(first.id),'Cancelled');assert.equal(stock(),'20');assert.equal(count(first.id),'3','single cancellation event');
 await owner.request(url,{version,reason});assert.equal(stock(),'20');assert.equal(count(first.id),'3');
 const cancelled=await owner.request('/Shop/Orders/'+first.id);assert.ok(!cancelled.text.includes('<script>alert(1)</script>'));assert.ok(cancelled.text.includes('&lt;script&gt;'));assert.ok(!cancelled.text.includes('class="order-cancel"'));
 const second=await place();await move(second.id,'Confirmed');await move(second.id,'Shipping');
 await owner.request('/Shop/Orders/'+second.id+'/Cancel',{version:second.version,reason:'too late'});assert.equal(status(second.id),'Shipping');
 await move(second.id,'Cancelled','too late');assert.equal(status(second.id),'Shipping');assert.equal(stock(),'18');
 await move(second.id,'Completed');assert.equal(count(second.id),'4');
 const third=await place();await owner.request('/Shop/Orders/'+third.id+'/Cancel',{version:third.version,reason:'Customer cancellation'});
 assert.equal(status(third.id),'Cancelled');assert.equal(stock(),'18');
 assert.equal(sql("SELECT ActorRole FROM ShopOrderEvents WHERE ShopOrderId="+third.id+" AND Status='Cancelled'"),'Customer');
 const fourth=await place();await move(fourth.id,'Cancelled');assert.equal(status(fourth.id),'Pending');
 await move(fourth.id,'Cancelled','Admin cancellation');assert.equal(status(fourth.id),'Cancelled');assert.equal(stock(),'18');
 assert.equal(sql("SELECT ActorRole FROM ShopOrderEvents WHERE ShopOrderId="+fourth.id+" AND Status='Cancelled'"),'Admin');
 // More than 100 orders must remain reachable, with ownership enforced on every page.
 sql("DECLARE @i int=0; WHILE @i<105 BEGIN INSERT ShopOrders(UserId,CheckoutToken,Recipient,Phone,Address,Status,CreatedUtc,Total) SELECT UserId,NEWID(),N'Pagination fixture',Phone,Address,'Pending',GETUTCDATE(),0 FROM ShopOrders WHERE Id="+first.id+"; SET @i+=1; END");
 const orderIds=html=>[...html.matchAll(/href=\"\/Shop\/Orders\/(\d+)\"/g)].map(m=>m[1]);
 const seen=new Set();
 for(let page=1;page<=6;page++){
  const result=await owner.request('/Shop/Orders?page='+page);assert.equal(result.status,200);
  const ids=orderIds(result.text);assert.equal(ids.length,page===6?9:20);
  for(const id of ids){assert.ok(!seen.has(id),'no duplicate order across pages');seen.add(id);}
 }
 assert.equal(seen.size,109);assert.ok(seen.has(first.id),'oldest order remains reachable');
 const firstPage=orderIds((await owner.request('/Shop/Orders?page=1')).text);
 assert.deepEqual(orderIds((await owner.request('/Shop/Orders?page=-2')).text),firstPage);
 assert.deepEqual(orderIds((await owner.request('/Shop/Orders?page=2147483647')).text),orderIds((await owner.request('/Shop/Orders?page=6')).text));
 const pending=await owner.request('/Shop/Orders?status=Pending');assert.equal(orderIds(pending.text).length,20);
 assert.match(pending.text,/status=Pending(?:&amp;|&)page=2/,'next page preserves status filter');
 assert.equal(orderIds((await owner.request('/Shop/Orders?status=Pending&page=6')).text).length,5);
 assert.deepEqual(orderIds((await owner.request('/Shop/Orders?status=Completed')).text),[second.id]);
 assert.equal(orderIds((await owner.request('/Shop/Orders?status=Shipping')).text).length,0);
 for(const path of ['/Shop/Orders','/Shop/Orders?page=6','/Shop/Orders?status=Pending']){
  assert.equal(orderIds((await other.request(path)).text).length,0,'other customer sees none of owner orders');
 }
 assert.equal((await guest.request('/Shop/Orders?page=6')).status,302);
 console.log('PASS: order history, checkout replay, ownership, CSRF, cancellation reasons, stale version, simultaneous cancellation restores stock once, escaped reasons, customer/admin cancellation, shipping restrictions, COD lifecycle, pagination beyond 100 orders and status filters.');
})().catch(e=>{console.error(e);process.exitCode=1});
