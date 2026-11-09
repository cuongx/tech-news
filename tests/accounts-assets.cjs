const assert = require('node:assert/strict');
const base = process.env.TEST_URL || 'http://127.0.0.1:5299';
class Client {
  cookies = new Map(); token = '';
  async request(path, data, token = true) {
    const headers = {Cookie: [...this.cookies].map(([k,v])=>`${k}=${v}`).join('; ')};
    if(data && token) headers.RequestVerificationToken = this.token;
    const response = await fetch(base+path,{method:data?'POST':'GET',headers,body:data?new URLSearchParams(data):undefined,redirect:'manual'});
    for(const cookie of response.headers.getSetCookie()) {const [pair]=cookie.split(';');const i=pair.indexOf('=');this.cookies.set(pair.slice(0,i),pair.slice(i+1));}
    const text = await response.text();
    const tokenValue = text.match(/name="__RequestVerificationToken"[^>]*value="([^"]+)"/)?.[1] || text.match(/name="csrf-token" content="([^"]+)"/)?.[1];
    if(tokenValue) this.token=tokenValue;
    return {status:response.status,text,location:response.headers.get('location')};
  }
  async login(name) {
    assert.equal((await this.request('/Admin/Login')).status,200);
    assert.equal((await this.request('/Admin/Login',{name,password:process.env.TEST_PASSWORD || 'TechNews-Verify-2026!'})).status,302);
    assert.equal((await this.request('/Admin/Articles')).status,200);
  }
}
async function upload(client,name,type,bytes){const form=new FormData();form.append('file',new Blob([bytes],{type}),name);const response=await fetch(base+'/Admin/UploadImage',{method:'POST',headers:{Cookie:[...client.cookies].map(([k,v])=>`${k}=${v}`).join('; '),RequestVerificationToken:client.token},body:form,redirect:'manual'});return {status:response.status,text:await response.text()};}
(async()=>{
 const admin=new Client(), editor=new Client(), other=new Client(), reader=new Client();await admin.login('qa-admin');await editor.login('qa-editor1');await other.login('qa-editor2');
 assert.equal((await upload(editor,'bad.jpg','image/jpeg',Buffer.from('<script>bad</script>'))).status,400);
 const png=Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aZxkAAAAASUVORK5CYII=','base64');
 const uploaded=await upload(editor,'QA-image.png','image/png',png);assert.equal(uploaded.status,200);assert.ok(uploaded.text.startsWith('/uploads/'));
 const assets=await editor.request('/Admin/Assets');const position=assets.text.indexOf(uploaded.text);assert.ok(position>=0);const assetId=assets.text.slice(position).match(/\/Admin\/Assets\/(\d+)\/Delete/)?.[1];assert.ok(assetId);
 assert.equal((await other.request('/Admin/Assets/'+assetId+'/Delete',{})).status,302);
 const title='QA_ASSET_'+Date.now();await editor.request('/Admin/CreateArticle');await editor.request('/Admin/CreateArticle',{ArticleTitle:title,ArticleContent:'<p>Image reference</p>',CategoryId:'8',ArticleThumb:uploaded.text});
 const list=await editor.request('/Admin/Articles?q='+title);const id=list.text.match(/\/Admin\/EditArticle\/(\d+)/)?.[1];assert.ok(id);
 await editor.request('/Admin/Assets/'+assetId+'/Delete',{});assert.ok((await editor.request('/Admin/Assets')).text.includes(uploaded.text),'used image remains');
 await editor.request('/Admin/DeleteArticle/'+id,{});await editor.request('/Admin/Assets');await editor.request('/Admin/Assets/'+assetId+'/Delete',{});assert.ok(!(await editor.request('/Admin/Assets')).text.includes(uploaded.text));
 const suffix=Date.now(),login='password'+suffix;await reader.request('/Account/Register');await reader.request('/Account/Register',{UserName:'Password QA',UserLogin:login,UserEmail:login+'@test.local',UserPassword:'TechNews-Verify-2026!',confirmPassword:'TechNews-Verify-2026!'});
 await reader.request('/Admin/Login');await reader.request('/Admin/Login',{name:login,password:'TechNews-Verify-2026!'});await reader.request('/Account');
 assert.equal((await reader.request('/Account/Password',{oldPassword:'wrong',newPassword:'NewPassword-2026!',confirmPassword:'NewPassword-2026!'})).status,302);
 await reader.request('/Account');assert.equal((await reader.request('/Account/Password',{oldPassword:'TechNews-Verify-2026!',newPassword:'NewPassword-2026!',confirmPassword:'NewPassword-2026!'})).status,302);
 const fresh=new Client();await fresh.request('/Admin/Login');assert.equal((await fresh.request('/Admin/Login',{name:login,password:'TechNews-Verify-2026!'})).status,200);assert.equal((await fresh.request('/Admin/Login',{name:login,password:'NewPassword-2026!'})).status,302);
 await fresh.request('/Account');assert.equal((await fresh.request('/Account',{UserName:'Updated QA',UserLogin:login,UserEmail:login+'@test.local',Id:'1',UserRole:'Admin'})).status,302);assert.equal((await fresh.request('/Admin/Users')).status,302);
 await fresh.request('/Account');assert.equal((await fresh.request('/Admin/Logout',{})).status,302);assert.equal((await fresh.request('/Account')).status,302);
 console.log('PASS: disguised upload rejection, PNG upload, asset ownership, in-use image deletion blocked, unused image cleanup, wrong/correct old password, changed password login, profile role isolation, logout.');
})().catch(e=>{console.error(e);process.exitCode=1;});
