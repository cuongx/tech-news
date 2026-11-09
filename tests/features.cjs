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
 const admin=new Client(), editor=new Client(), reader=new Client(), guest=new Client();
 await admin.login('qa-admin');await editor.login('qa-editor1');
 for(const path of ['/','/Search','/Admin/Workflow','/Admin/Assets','/Admin/Comments','/Admin/Tags','/Admin/Dashboard']) {
  const response=await admin.request(path);assert.equal(response.status,200,path);
 }
 const suffix=Date.now(), login='reader'+suffix, title='QA_FEATURE_'+suffix;
 assert.equal((await reader.request('/Account/Register')).status,200);
 assert.equal((await reader.request('/Account/Register',{UserName:'QA Reader',UserLogin:login,UserEmail:login+'@technews.test',UserPassword:'TechNews-Verify-2026!',confirmPassword:'TechNews-Verify-2026!',UserRole:'Admin'})).status,302);
 await reader.request('/Admin/Login');assert.equal((await reader.request('/Admin/Login',{name:login,password:'TechNews-Verify-2026!'})).location,'/Account');
 assert.equal((await reader.request('/Account')).status,200);assert.equal((await reader.request('/Admin/Users')).status,302);
 assert.equal((await reader.request('/Admin/Articles')).status,302);
 await editor.request('/Admin/CreateArticle');
 assert.equal((await editor.request('/Admin/CreateArticle',{ArticleTitle:title,ArticleContent:'<p>Feature test</p>',CategoryId:'8',TagsText:'QA_TAG, QA_SECOND'})).status,302);
 const list=await editor.request('/Admin/Articles?q='+title);const id=list.text.match(/\/Admin\/EditArticle\/(\d+)/)?.[1];assert.ok(id);
 await editor.request('/Admin/Workflow/'+id);
 assert.equal((await editor.request('/Admin/Workflow/'+id,{target:'Published'})).status,302);
 assert.equal((await guest.request('/'+title+'-ar'+id)).status,404);
 await editor.request('/Admin/Workflow/'+id);await editor.request('/Admin/Workflow/'+id,{target:'Pending'});
 await admin.request('/Admin/Workflow/'+id);await admin.request('/Admin/Workflow/'+id,{target:'Approved'});
 assert.ok((await admin.request('/Admin/Workflow/'+id)).text.includes('<strong>Approved</strong>'));
 await admin.request('/Admin/Workflow/'+id,{target:'Published'});
 assert.equal((await guest.request('/'+title+'-ar'+id)).status,200);
 await reader.request('/'+title+'-ar'+id);await reader.request('/Account/Save/'+id,{saved:'true'});await reader.request('/Account/Saved');await reader.request('/Account/Save/'+id,{saved:'true'});
 const saved=await reader.request('/Account/Saved');assert.equal(saved.text.split(title).length-1,2,'one saved link and its slug');
 const comment='QA_COMMENT_'+suffix;await reader.request('/Articles/'+id+'/Comments',{body:comment});
 assert.ok(!(await guest.request('/'+title+'-ar'+id)).text.includes(comment));
 const pending=await admin.request('/Admin/Comments');const position=pending.text.indexOf(comment);assert.ok(position>=0);
 const cid=pending.text.slice(position).match(/\/Admin\/Comments\/(\d+)/)?.[1];assert.ok(cid);
 await admin.request('/Admin/Comments/'+cid,{status:'Approved'});
 assert.ok((await guest.request('/'+title+'-ar'+id)).text.includes(comment));
 const search=await guest.request('/Search?q='+title+'&categoryId=8');assert.equal(search.status,200);assert.ok(search.text.includes(title));
 assert.ok((await admin.request('/Admin/Dashboard')).text.includes('Lượt xem'));
 // Editing a published article removes it from public views and requires approval again.
 await editor.request('/Admin/EditArticle/'+id);await editor.request('/Admin/EditArticle/'+id,{Id:id,ArticleTitle:title,ArticleContent:'<p>Edited</p>',CategoryId:'8',TagsText:'QA_TAG'});
 assert.equal((await guest.request('/'+title+'-ar'+id)).status,404);
 assert.ok(!(await reader.request('/Account/Saved')).text.includes(title));
 await editor.request('/Admin/Workflow/'+id);await editor.request('/Admin/Workflow/'+id,{target:'Pending'});
 await admin.request('/Admin/Workflow/'+id);await admin.request('/Admin/Workflow/'+id,{target:'Rejected',note:'Please revise'});
 assert.ok((await editor.request('/Admin/Workflow/'+id)).text.includes('<strong>Rejected</strong>'));
 await editor.request('/Admin/Workflow/'+id,{target:'Pending'});await admin.request('/Admin/Workflow/'+id);await admin.request('/Admin/Workflow/'+id,{target:'Approved'});
 await admin.request('/Admin/Workflow/'+id);
 const schedule=new Date(Date.now()+7*3600000+20000).toISOString().slice(0,19);
 await admin.request('/Admin/Workflow/'+id,{target:'Scheduled',schedule});
 assert.equal((await guest.request('/'+title+'-ar'+id)).status,404);
 for(let i=0;i<9;i++){await new Promise(r=>setTimeout(r,5000));if((await guest.request('/'+title+'-ar'+id)).status===200)break;}
 assert.equal((await guest.request('/'+title+'-ar'+id)).status,200,'scheduler publishes due article');
 await admin.request('/Admin/Workflow/'+id);await admin.request('/Admin/Workflow/'+id,{target:'Unpublished'});
 assert.equal((await guest.request('/'+title+'-ar'+id)).status,404);
 console.log('PASS: all new screens, reader signup/role isolation, save idempotence, pending/approved comments, search, dashboard, workflow permissions, reject/resubmit, edit invalidates publication, scheduled publication, unpublish.');
})().catch(e=>{console.error(e);process.exitCode=1;});
