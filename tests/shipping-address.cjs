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
 const owner=new Client(),other=new Client(),guest=new Client(),admin=new Client();
 const stamp=Date.now();await owner.signup('address-'+stamp);await other.signup('address-other-'+stamp);await admin.login('qa-admin');
 const product=sql("INSERT Products(Name,Category,Price,Stock,IsActive) OUTPUT INSERTED.Id VALUES(N'QA_ADDRESS_"+stamp+"',N'QA',125000,10,1)");
 await owner.request('/Shop/Product/'+product);await owner.request('/Shop/Cart/Add/'+product,{quantity:'1'});
 const checkout=await owner.request('/Shop/Checkout');
 const input={Token:field(checkout.text,'Token'),Recipient:'QA Address',Phone:'0901234567',ProvinceCode:'1',WardCode:'4',Address:'12 Test Street'};
 const catalogue=require('../TechNews/Data/vietnam-addresses.json');
 const foreignWard=String(catalogue.find(p=>p.code!==1).wards[0].code);
 for(const bad of [{ProvinceCode:''},{WardCode:''},{ProvinceCode:'999999'},{WardCode:foreignWard},{Address:'    '},{Address:'1234'},{Address:'x'.repeat(301)}]){
  assert.equal((await owner.request('/Shop/Checkout',{...input,...bad})).status,200);
  assert.equal(sql("SELECT COUNT(*) FROM ShopOrders WHERE CheckoutToken='"+input.Token+"'"),'0');
  assert.equal(sql('SELECT Stock FROM Products WHERE Id='+product),'10');
 }
 const placed=await owner.request('/Shop/Checkout',input);assert.equal(placed.status,302);
 const id=placed.location.match(/\d+$/)[0],url='/Shop/Orders/'+id+'/Address';
 const original=sql('SELECT Address FROM ShopOrders WHERE Id='+id);
 assert.equal(sql('SELECT ProvinceCode FROM ShopOrders WHERE Id='+id),'1');assert.equal(sql('SELECT WardCode FROM ShopOrders WHERE Id='+id),'4');
 const page=await owner.request(url);assert.equal(page.status,200);
 const edit={ProvinceCode:'1',WardCode:'4',Address:'34 New Street',Version:field(page.text,'Version')};
 assert.equal((await guest.request(url)).status,302);
 assert.equal((await other.request(url)).status,404);await other.request('/Shop');assert.equal((await other.request(url,edit)).status,404);
 assert.equal((await owner.request(url,edit,false)).status,400);
 assert.equal((await owner.request(url,{...edit,WardCode:foreignWard})).status,200);
 assert.equal((await owner.request(url,{...edit,Version:''})).status,200);
 assert.equal(sql('SELECT Address FROM ShopOrders WHERE Id='+id),original);
 assert.equal((await owner.request(url,edit)).status,302);
 assert.equal(sql('SELECT AddressLine FROM ShopOrders WHERE Id='+id),'34 New Street');
 assert.equal(sql('SELECT COUNT(*) FROM ShopOrderEvents WHERE ShopOrderId='+id+' AND AddressBefore IS NOT NULL AND AddressAfter IS NOT NULL'),'1');
 assert.equal(sql('SELECT Stock FROM Products WHERE Id='+product),'9');assert.equal(sql('SELECT Total FROM ShopOrders WHERE Id='+id),'125000');
 assert.equal((await owner.request(url,{...edit,Address:'56 Stale Street'})).status,409);
 let fresh=await owner.request(url);edit.Version=field(fresh.text,'Version');
 assert.equal((await owner.request(url,edit)).status,302,'unchanged is idempotent');
 assert.equal(sql('SELECT COUNT(*) FROM ShopOrderEvents WHERE ShopOrderId='+id+' AND AddressAfter IS NOT NULL'),'1');
 const adminPage=await admin.request('/Admin/ShopOrders/'+id);
 await admin.request('/Admin/ShopOrders/'+id+'/Status',{target:'Confirmed',version:field(adminPage.text,'version')});
 assert.equal((await owner.request(url)).status,302);
 assert.equal((await owner.request(url,{...edit,Address:'78 Blocked Street'})).status,409);
 assert.equal(sql('SELECT AddressLine FROM ShopOrders WHERE Id='+id),'34 New Street');
 assert.ok(!(await owner.request('/Shop/Orders/'+id)).text.includes('href="'+url+'"'));
 // Legacy free-text orders remain readable and can be upgraded by the owner.
 sql("UPDATE ShopOrders SET Status='Pending',ProvinceCode=NULL,WardCode=NULL,AddressLine=NULL,Address=N'Legacy address' WHERE Id="+id);
 const legacy=await owner.request(url);assert.equal(legacy.status,200);assert.ok(legacy.text.includes('Legacy address'));
 const legacyEdit={...edit,Address:'90 Legacy Street',Version:field(legacy.text,'Version')};
 assert.equal((await owner.request(url,legacyEdit)).status,302);
 const beforeRace=await owner.request(url),adminBeforeRace=await admin.request('/Admin/ShopOrders/'+id);
 const race=await Promise.all([owner.request(url,{...edit,Address:'100 Race Street',Version:field(beforeRace.text,'Version')}),admin.request('/Admin/ShopOrders/'+id+'/Status',{target:'Confirmed',version:field(adminBeforeRace.text,'version')})]);
 assert.ok([302,409].includes(race[0].status));
 const state=sql('SELECT Status FROM ShopOrders WHERE Id='+id),line=sql('SELECT AddressLine FROM ShopOrders WHERE Id='+id);
 if(state==='Confirmed')assert.equal(line,'90 Legacy Street','confirmation won; address cannot change');
 else {assert.equal(state,'Pending');assert.ok(['90 Legacy Street','100 Race Street'].includes(line));}
 for(const state of ['Confirmed','Shipping','Completed','Cancelled']){
  sql("UPDATE ShopOrders SET Status='"+state+"' WHERE Id="+id);
  const version=Buffer.from(sql('SELECT CONVERT(varchar(16),CAST(Version AS varbinary(8)),2) FROM ShopOrders WHERE Id='+id),'hex').toString('base64');
  assert.equal((await owner.request(url,{...edit,Version:version})).status,409,'blocked '+state);
 }
 assert.equal(sql('SELECT Stock FROM Products WHERE Id='+product),'9');
 console.log('PASS shipping address: invalid membership/detail, checkout, ownership, CSRF, audit, stock/total, stale edits, idempotence, confirmed lock');
})().catch(e=>{console.error(e);process.exitCode=1;});
