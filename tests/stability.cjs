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
(async()=>{
 const admin=new Client(), editor=new Client(), other=new Client(), guest=new Client();
 await admin.login('qa-admin'); await editor.login('qa-editor1'); await other.login('qa-editor2');
 const title='QA_STABILITY_'+Date.now();
 assert.equal((await editor.request('/Admin/CreateArticle',{ArticleTitle:title,ArticleContent:'<p>Test</p><script>alert(1)</script>',CategoryId:'8'})).status,302);
 let list=await editor.request('/Admin/Articles?q='+title);
 assert.ok(list.text.includes(title),'Editor can see draft');
 const id=list.text.match(/\/Admin\/EditArticle\/(\d+)/)?.[1]; assert.ok(id);
 assert.equal((await editor.request('/Admin/EditArticle/'+id)).status,200);
 assert.equal((await guest.request('/x-ar'+id)).status,404);
 assert.equal((await other.request('/Admin/EditArticle/'+id)).status,302);
 assert.equal((await other.request('/Admin/EditArticle/'+id,{Id:id,ArticleTitle:'forged',ArticleContent:'bad',CategoryId:'8'})).status,302);
 assert.equal((await admin.request('/Admin/EditArticle/'+id)).status,200);
 assert.equal((await editor.request('/Admin/EditArticle/'+id,{Id:id,ArticleTitle:title,ArticleContent:'<p>Updated</p><img src=x onerror=alert(1)>',CategoryId:'8'})).status,302);
 assert.equal((await editor.request('/Admin/CreateArticle',{ArticleTitle:'',CategoryId:'8'})).status,200);
 assert.equal((await editor.request('/Admin/CreateArticle',{ArticleTitle:'csrf'},false)).status,400);
 assert.equal((await editor.request('/Admin/DeleteArticle/'+id)).status,405);
 assert.equal((await other.request('/Admin/DeleteArticle/'+id,{})).status,302);
 assert.equal((await admin.request('/Admin/ActiveArticle/'+id,{})).status,200);
 const article=await guest.request('/'+title+'-ar'+id); assert.equal(article.status,200); assert.ok(!article.text.includes('onerror=alert'));
 assert.equal((await guest.request('/Like/'+id,{})).status,200);
 assert.equal((await guest.request('/Like/'+id,{})).status,200);
 assert.equal((await guest.request('/x-ar2147483647')).status,404);
 assert.equal((await guest.request('/x-2147483647')).status,404);
 assert.equal((await editor.request('/Admin/UploadImage',{})).status,400);
 assert.equal((await editor.request('/Admin/Articles/0')).status,200);
 assert.equal((await editor.request('/Admin/Articles/999999')).status,200);
 assert.equal((await admin.request('/Admin/DeleteArticle/'+id,{})).status,302);
 assert.equal((await guest.request('/'+title+'-ar'+id)).status,404);
 console.log('PASS: logins, draft visibility, ownership GET/POST, hidden article, validation, CSRF, POST deletion, publish, sanitized HTML, likes, missing IDs, upload rejection, pagination, deletion.');
})().catch(e=>{console.error(e);process.exitCode=1;});
