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
 const admin=new Client(),guest=new Client(),editor=new Client();
 await admin.login('qa-admin');await editor.login('qa-editor1');
 for(const client of [guest,editor])assert.equal((await client.request('/Admin/ShopOrders')).status,302);
 const name='ADMIN_FILTER_'+Date.now();
 const uid=sql("SELECT TOP 1 id FROM dbo.[user] WHERE user_login='qa-admin'");
 const insert=(date,status='Pending')=>sql("INSERT ShopOrders(UserId,CheckoutToken,Recipient,Phone,Address,Status,CreatedUtc,Total) OUTPUT INSERTED.Id VALUES("+uid+",NEWID(),N'"+name+"','0987654321',N'QA address','"+status+"','"+date+"',125000)");
 const before=insert('2026-11-08T16:59:59'),first=insert('2026-11-08T17:00:00'),last=insert('2026-11-09T16:59:59'),after=insert('2026-11-09T17:00:00');
 const completed=insert('2026-11-09T12:00:00','Completed');
 for(let i=0;i<32;i++)insert('2026-11-09T10:00:00');
 const ids=html=>[...html.matchAll(/data-order-id="(\d+)"/g)].map(m=>m[1]);
 const root='/Admin/ShopOrders?q='+name;
 let r=await admin.request(root);assert.equal(r.status,200);assert.equal(ids(r.text).length,30);
 const second=await admin.request(root+'&page=2');assert.equal(ids(second.text).length,7);
 assert.equal(new Set([...ids(r.text),...ids(second.text)]).size,37);
 assert.deepEqual(ids((await admin.request(root+'&page=2147483647')).text),ids(second.text));
 assert.deepEqual(ids((await admin.request(root+'&page=-1')).text),ids(r.text));
 const filtered=root+'&status=Pending&from=2026-11-09&to=2026-11-09';
 r=await admin.request(filtered);const next=decode(r.text.match(/rel="next" href="([^"]+)"/)[1]);
 for(const part of ['q='+name,'status=Pending','from=2026-11-09','to=2026-11-09','page=2'])assert.ok(next.includes(part),part);
 const all=[...ids(r.text),...ids((await admin.request(next)).text)];
 assert.equal(all.length,34);assert.ok(all.includes(first));assert.ok(all.includes(last));assert.ok(!all.includes(before));assert.ok(!all.includes(after));assert.ok(!all.includes(completed));
 assert.deepEqual(ids((await admin.request('/Admin/ShopOrders?q=%23'+first)).text),[first]);
 assert.deepEqual(ids((await admin.request(root+'&status=Completed')).text),[completed]);
 assert.ok(ids((await admin.request('/Admin/ShopOrders?q=0987654321')).text).length>0);
 for(const query of ['from=invalid','from=2026-11-10&to=2026-11-09','status=Fake','from=0001-01-01','to=9999-12-31']){
  const bad=await admin.request(root+'&'+query);assert.equal(bad.status,200);assert.equal(ids(bad.text).length,0);assert.ok(bad.text.includes('validation-summary-errors'));
 }
 const empty=await admin.request(root+'missing');assert.equal(ids(empty.text).length,0);assert.ok(empty.text.includes('shop-empty'));
 const detail=await admin.request('/Admin/ShopOrders/'+first+'?returnUrl='+encodeURIComponent(next));assert.ok(detail.text.includes('href="'+next.replaceAll('&','&amp;')+'"'));
 const version=field(detail.text,'version');
 assert.equal((await admin.request('/Admin/ShopOrders/'+first+'/Status',{target:'Confirmed',version,returnUrl:next},false)).status,400);
 const changed=await admin.request('/Admin/ShopOrders/'+first+'/Status',{target:'Confirmed',version,returnUrl:next});
 assert.equal(changed.status,302);assert.equal(new URL(base+changed.location).searchParams.get('returnUrl'),next);
 assert.equal(sql('SELECT Status FROM ShopOrders WHERE Id='+first),'Confirmed');
 const unsafe=await admin.request('/Admin/ShopOrders/'+first+'?returnUrl=https://evil.example');assert.ok(unsafe.text.includes('href="/Admin/ShopOrders" class="order-back"'));
 const state=await admin.request(changed.location);assert.ok(state.text.includes('value="Shipping"'));assert.ok(!state.text.includes('value="Completed"'));
 const done=await admin.request('/Admin/ShopOrders/'+completed);assert.ok(!done.text.includes('class="order-status-form"'));
 console.log('PASS: admin search, pagination, filters, Vietnam date boundaries, invalid input, access control, CSRF, safe return URL, state actions.');
})().catch(e=>{console.error(e);process.exitCode=1});
