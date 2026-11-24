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
 const admin=new Client(),editor=new Client();await admin.login('qa-admin');await editor.login('qa-editor1');
 const name='QA_PRODUCT_ASSET_'+Date.now();
 await admin.request('/Admin/Assets');
 const data=new FormData();
 data.append('file',new Blob([Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aZ3sAAAAASUVORK5CYII=','base64')],{type:'image/png'}),name+'.png');
 const uploaded=await fetch(base+'/Admin/Assets',{method:'POST',headers:{Cookie:[...admin.cookies].map(([k,v])=>`${k}=${v}`).join('; '),RequestVerificationToken:admin.token},body:data,redirect:'manual'});
 assert.equal(uploaded.status,302);
 const asset=sql("SELECT TOP 1 CONCAT(Id,'|',Url) FROM Assets WHERE FileName='"+name+".png'").split('|');
 assert.ok(asset[1]?.startsWith('/uploads/'));
 const form=await admin.request('/Admin/Products/Create');assert.ok(form.text.includes(asset[1]),'uploaded asset available in picker');
 const product={Name:name,Category:'QA',Price:'15000',Stock:'2',IsActive:'true',ImageUrl:asset[1]};
 assert.equal((await editor.request('/Admin/Products/Save',product)).status,302);
 assert.equal(sql("SELECT COUNT(*) FROM Products WHERE Name='"+name+"'"),'0','editor cannot create product');
 assert.equal((await admin.request('/Admin/Products/Save',product,false)).status,400);
 for(const bad of ['/uploads/missing.png','/images/../secret.png','javascript:alert(1)']) {
  assert.equal((await admin.request('/Admin/Products/Save',{...product,ImageUrl:bad})).status,200);
  assert.equal(sql("SELECT COUNT(*) FROM Products WHERE Name='"+name+"'"),'0');
 }
 assert.equal((await admin.request('/Admin/Products/Save',product)).status,302);
 const id=sql("SELECT Id FROM Products WHERE Name='"+name+"'");
 assert.ok((await admin.request('/Admin/Products?q='+name)).text.includes(asset[1]));
 assert.ok((await admin.request('/Shop/Product/'+id)).text.includes(asset[1]));
 await admin.request('/Admin/Assets');await admin.request('/Admin/Assets/'+asset[0]+'/Delete',{});
 assert.equal(sql('SELECT COUNT(*) FROM Assets WHERE Id='+asset[0]),'1','product image cannot be deleted');
 assert.equal((await fetch(base+asset[1])).status,200);
 const edit=await admin.request('/Admin/Products/'+id+'/Edit');
 assert.equal((await admin.request('/Admin/Products/Save',{...product,Id:id,Version:field(edit.text,'Version'),ImageUrl:''})).status,302);
 await admin.request('/Admin/Assets');await admin.request('/Admin/Assets/'+asset[0]+'/Delete',{});
 assert.equal(sql('SELECT COUNT(*) FROM Assets WHERE Id='+asset[0]),'0','unused image can be deleted');
 assert.equal((await fetch(base+asset[1])).status,404);
 sql('DELETE Products WHERE Id='+id);
 console.log('PASS: product asset picker, authorization, CSRF, invalid paths, storefront image, in-use deletion protection and unused image cleanup.');
})().catch(e=>{console.error(e);process.exitCode=1});
