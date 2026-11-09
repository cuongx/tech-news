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
 const admin=new Client(),reader=new Client(),other=new Client();
 await admin.login('qa-admin');const stamp=Date.now(),name='lists-'+stamp;
 await reader.signup(name);await other.signup('lists-other-'+stamp);
 const uid=sql("SELECT id FROM dbo.[user] WHERE user_login='"+name+"'");
 const article=sql("SELECT TOP 1 id FROM article WHERE article_status=1 ORDER BY id");
 assert.ok(article);
 assert.ok((await reader.request('/Account/Saved')).text.includes('account-empty'));
 assert.ok((await reader.request('/Account/Comments')).text.includes('account-empty'));
 await reader.request('/Account/Saved');
 assert.equal((await reader.request('/Account/Save/'+article,{saved:'true'},false)).status,400);
 assert.equal((await reader.request('/Account/Save/'+article,{saved:'true'})).status,302);
 assert.ok((await reader.request('/Account/Saved')).text.includes('/Account/Save/'+article));
 assert.ok(!(await other.request('/Account/Saved')).text.includes('/Account/Save/'+article));
 await reader.request('/Articles/'+article+'/Comments',{body:'QA_LIST_'+stamp+' <script>alert(1)</script>'});
 const comment=sql('SELECT TOP 1 Id FROM Comments WHERE UserId='+uid+' ORDER BY Id DESC');
 const page=await reader.request('/Account/Comments');assert.ok(decode(page.text).includes('Chờ duyệt'));assert.ok(!decode(page.text).includes('<script>alert(1)</script>'));assert.ok(decode(page.text).includes('&lt;script&gt;'));
 const target='/Account/Comments/'+comment+'/Delete';
 assert.equal((await reader.request(target,{},false)).status,400);
 await other.request('/Account/Comments');assert.equal((await other.request(target,{})).status,302);
 assert.equal(sql('SELECT COUNT(*) FROM Comments WHERE Id='+comment),'1');
 await reader.request('/Account/Comments');assert.equal((await reader.request(target,{})).status,302);assert.equal(sql('SELECT COUNT(*) FROM Comments WHERE Id='+comment),'0');
 await reader.request('/Account/Saved');await reader.request('/Account/Save/'+article,{saved:'false'});assert.ok((await reader.request('/Account/Saved')).text.includes('account-empty'));
 await reader.request('/Account');
 assert.equal((await reader.request('/Account',{UserName:'',UserEmail:name+'@example.test',UserLogin:name})).status,200);
 const duplicate=await reader.request('/Account',{UserName:'QA',UserEmail:'qa-admin@technews.test',UserLogin:name});assert.equal(duplicate.status,200);assert.ok(duplicate.text.includes('validation-summary-errors'));
 assert.equal(sql("SELECT user_email FROM dbo.[user] WHERE id="+uid),name+'@example.test');
 await admin.request('/Admin/Products/Create');
 const bad=await admin.request('/Admin/Products/Save',{Name:'',Category:'',Price:'-1',Stock:'-1',IsActive:'true'});assert.equal(bad.status,200);assert.ok(decode(bad.text).includes('Nhập tên sản phẩm'));assert.ok(decode(bad.text).includes('Tồn kho phải'));
 console.log('PASS: empty lists, saved ownership, comment CSRF/ownership/HTML encoding/delete, required fields, duplicate email and product validation.');
})().catch(e=>{console.error(e);process.exitCode=1});
