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
const c=new Client(),name='short-'+Date.now();await c.request('/Account/Register');const input={UserName:name,UserLogin:name,UserEmail:name+'@test.local',UserPassword:'12345',confirmPassword:'12345'};
for(const password of ['', 'a'.repeat(129)])assert.equal((await c.request('/Account/Register',{...input,UserPassword:password,confirmPassword:password})).status,200);
assert.equal((await c.request('/Account/Register',input)).status,302);
async function login(password){const client=new Client();await client.request('/Admin/Login');assert.equal((await client.request('/Admin/Login',{name,password})).status,302);await client.request('/Account');return client;}
let owner=await login('12345');const profile=await owner.request('/Account');assert.ok(!profile.text.includes('minlength="8"'));
for(const password of ['', 'a'.repeat(129)]){await owner.request('/Account/Password',{oldPassword:'12345',newPassword:password,confirmPassword:password});await login('12345');}
await owner.request('/Account/Password',{oldPassword:'12345',newPassword:'1',confirmPassword:'1'});owner=await login('1');
const id=sql("SELECT Id FROM [user] WHERE user_login='"+name+"'");await owner.request('/Admin/Profile/'+id);await owner.request('/Admin/ChangePassword',{id,oldPassword:'1',newPassword:'123'});await login('123');
console.log('PASS registration and both password forms accept short passwords; empty/overlong rejected; login verified.');
})().catch(e=>{console.error(e);process.exitCode=1});