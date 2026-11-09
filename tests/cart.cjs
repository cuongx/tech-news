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
 async request(path,data,csrf=true){const headers={Accept:"application/json",Cookie:[...this.cookies].map(([k,v])=>`${k}=${v}`).join('; ')};if(data&&csrf)headers.RequestVerificationToken=this.token;const r=await fetch(base+path,{method:data?'POST':'GET',headers,body:data?new URLSearchParams(data):undefined,redirect:'manual'});for(const c of r.headers.getSetCookie()){const pair=c.split(';')[0],i=pair.indexOf('=');this.cookies.set(pair.slice(0,i),pair.slice(i+1));}const text=await r.text();const token=text.match(/name="__RequestVerificationToken"[^>]*value="([^"]+)"/)?.[1]||text.match(/name="csrf-token" content="([^"]+)"/)?.[1];if(token)this.token=decode(token);return {status:r.status,text,location:r.headers.get('location'),setCookies:r.headers.getSetCookie(),cache:r.headers.get('cache-control')};}
 async login(name,returnUrl){await this.request('/Admin/Login');const r=await this.request('/Admin/Login',{name,password:process.env.TEST_PASSWORD||'TechNews-Verify-2026!',...(returnUrl?{returnUrl}:{})});assert.equal(r.status,302,'login '+name);return r;}
 async signup(name){await this.request('/Account/Register');assert.equal((await this.request('/Account/Register',{UserName:name,UserLogin:name,UserEmail:name+'@example.test',UserPassword:'TechNews-Verify-2026!',confirmPassword:'TechNews-Verify-2026!'})).status,302);await this.login(name);}
}
(async()=>{
 const guest=new Client();
 const id=sql("INSERT Products(Name,Category,Description,Price,Stock,IsActive) OUTPUT INSERTED.Id VALUES(N'QA_CART_"+Date.now()+"',N'QA',N'Cart verification',125000,9,1)");
 await guest.request('/Shop/Product/'+id);
 assert.equal((await guest.request('/Shop/Cart/Add/'+id,{quantity:'1'},false)).status,400,'CSRF required');
 const added=await guest.request('/Shop/Cart/Add/'+id,{quantity:'2'});assert.equal(added.status,200);assert.equal(JSON.parse(added.text).count,2);
 assert.ok(added.setCookies.some(c=>c.startsWith('TechNews.Cart=')&&/httponly/i.test(c)&&/expires=/i.test(c)),'persistent HttpOnly cart cookie');
 const fresh=new Client();fresh.cookies.set('TechNews.Cart',guest.cookies.get('TechNews.Cart'));
 const restored=await fresh.request('/Shop/Cart');assert.equal(restored.status,200);assert.ok(restored.text.includes('250.000'),'cart restored without session cookie');
 let summary=await fresh.request('/Shop/Cart/Summary');assert.equal(JSON.parse(summary.text).count,2);assert.ok(summary.cache.includes('no-store'));
 assert.equal((await fresh.request('/Shop/Cart/Update/'+id,{quantity:'abc'})).status,400,'malformed update does not delete');assert.equal(JSON.parse((await fresh.request('/Shop/Cart/Summary')).text).count,2);
 assert.equal((await fresh.request('/Shop/Cart/Add/'+id,{quantity:'99'})).status,400,'stock checked');
 await fresh.login('qa-admin');assert.equal(JSON.parse((await fresh.request('/Shop/Cart/Summary')).text).count,2,'login preserves guest cart');
 sql('UPDATE Products SET Price=175000 WHERE Id='+id);
 let content=await fresh.request('/Shop/Cart/Content');assert.ok(content.text.includes('cart-item-warning'));assert.ok(content.text.includes('cart-checkout-warning'));assert.ok(content.text.includes('350.000'));
 assert.equal((await fresh.request('/Shop/Checkout')).location,'/Shop/Cart','price acknowledgement required before checkout');
 assert.equal((await fresh.request('/Shop/Cart/Update/'+id,{quantity:'2'})).status,200);
 content=await fresh.request('/Shop/Cart/Content');assert.ok(!content.text.includes('cart-checkout-warning'),'updated price acknowledged');
 assert.equal((await fresh.request('/Shop/Checkout')).status,200);
 sql('UPDATE Products SET Stock=1 WHERE Id='+id);
 content=await fresh.request('/Shop/Cart/Content');assert.ok(content.text.includes('cart-checkout-warning'));assert.equal((await fresh.request('/Shop/Checkout')).location,'/Shop/Cart','stock issue blocks checkout');
 await fresh.request('/Shop/Cart/Update/'+id,{quantity:'1'});assert.ok(!(await fresh.request('/Shop/Cart/Content')).text.includes('cart-checkout-warning'));
 sql('UPDATE Products SET IsActive=0 WHERE Id='+id);assert.ok((await fresh.request('/Shop/Cart/Content')).text.includes('cart-checkout-warning'));
 assert.equal(JSON.parse((await fresh.request('/Shop/Cart/Update/'+id,{quantity:'0'})).text).count,0,'inactive product removable');assert.ok((await fresh.request('/Shop/Cart')).text.includes('cart-empty'));
 const tampered=new Client();tampered.cookies.set('TechNews.Cart','not-a-valid-cart');assert.equal(JSON.parse((await tampered.request('/Shop/Cart/Summary')).text).count,0,'invalid cookie ignored');
 console.log('PASS: AJAX count, CSRF, stock validation, persistent protected cookie without session, login preservation, invalid input, price acknowledgement, stock/hidden-product warnings, removal, empty state, invalid-cookie recovery.');
})().catch(e=>{console.error(e);process.exitCode=1});
