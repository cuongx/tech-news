const fs=require('node:fs'),assert=require('node:assert/strict');
(async()=>{const tabs=await(await fetch((process.env.TEST_CDP_URL||'http://127.0.0.1:9342')+'/json')).json();const ws=new WebSocket(tabs.find(t=>t.type==='page').webSocketDebuggerUrl);await new Promise(r=>ws.addEventListener('open',r,{once:true}));let id=0;const pending=new Map();ws.addEventListener('message',e=>{const m=JSON.parse(e.data),p=pending.get(m.id);if(p){pending.delete(m.id);m.error?p.reject(m.error):p.resolve(m.result)}});const call=(method,params={})=>new Promise((resolve,reject)=>{pending.set(++id,{resolve,reject});ws.send(JSON.stringify({id,method,params}))});async function js(expression){const r=await call('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});if(r.exceptionDetails)throw Error(JSON.stringify(r.exceptionDetails));return r.result.value;}
async function waitFor(expression){for(let i=0;i<50;i++){await new Promise(r=>setTimeout(r,120));if(await js(expression))return;}throw Error('Timeout: '+expression)}
async function go(path,selector){await call('Page.navigate',{url:(process.env.TEST_URL||'http://127.0.0.1:5313')+path});await waitFor('document.readyState==="complete" && !!document.querySelector('+JSON.stringify(selector)+')');}
async function screenshot(name){await new Promise(r=>setTimeout(r,300));let shot=await call('Page.captureScreenshot',{format:'png'});fs.writeFileSync(name,Buffer.from(shot.data,'base64'));}

try {
 await call('Page.enable');await call('Network.clearBrowserCookies');
 await go('/Admin/Login','.login-submit');
 await js("document.querySelector('#name').value='qa-admin';document.querySelector('#password').value='TechNews-Verify-2026!';document.querySelector('.login-submit').click()");
 await waitFor("location.pathname!='/Admin/Login'");
 const {execFileSync}=require('node:child_process');
 const db=process.env.TEST_DATABASE||'TechNews_Verification_20261025';
 assert.ok(db.startsWith('TechNews_Verification_'));
 const name=execFileSync('sqlcmd',['-S','localhost','-E','-C','-b','-d',db,'-h','-1','-W','-Q',"SET NOCOUNT ON; SELECT TOP 1 Recipient FROM ShopOrders WHERE Recipient LIKE 'ADMIN_FILTER_%' ORDER BY Id DESC"],{encoding:'utf8',windowsHide:true}).trim();
 const path='/Admin/ShopOrders?q='+name+'&status=Pending&from=2026-11-09&to=2026-11-09';
 for(const width of [1440,375]){
  await call('Emulation.setDeviceMetricsOverride',{width,height:1000,deviceScaleFactor:1,mobile:width<600});
  await go(path,'.admin-orders-table');
  assert.ok(await js('document.documentElement.scrollWidth<=innerWidth'),'list fits '+width);
  assert.ok(await js("[...document.querySelectorAll('#accordionSidebar .nav-link')].every(a=>a.querySelector('i[aria-hidden=true]'))"),'sidebar icons');
  assert.equal(await js("document.querySelector('#accordionSidebar a[aria-current=page]').getAttribute('href')"),'/Admin/ShopOrders');
  await js('document.fonts.ready');
  assert.ok(await js("getComputedStyle(document.querySelector('a[href=\"/Admin/ShopOrders\"] i'),'::before').content.includes(String.fromCharCode(0xf290))"));
  await screenshot('admin-orders-'+width+'.png');
  await js("document.querySelector('.shop-pagination a[rel=next]').click()");
  await waitFor("location.search.includes('page=2') && document.readyState==='complete'");
  const listUrl=await js('location.pathname+location.search');
  await js("document.querySelector('.order-id').click()");
  await waitFor("!!document.querySelector('.order-processing')");
  assert.ok(await js('document.documentElement.scrollWidth<=innerWidth'),'detail fits '+width);
  assert.equal(await js("document.querySelector('.order-back').getAttribute('href')"),listUrl);
  await screenshot('admin-order-detail-'+width+'.png');
  await js("document.querySelector('.order-back').click()");
  await waitFor("!!document.querySelector('.admin-orders-table')");
  assert.equal(await js('location.pathname+location.search'),listUrl);
 }
 let accept=false,dialogs=0;
 ws.addEventListener('message',e=>{const m=JSON.parse(e.data);if(m.method==='Page.javascriptDialogOpening'){dialogs++;call('Page.handleJavaScriptDialog',{accept});}});
 await go(path,'.admin-orders-table');
 await js("document.querySelector('.order-id').click()");
 await waitFor("!!document.querySelector('.order-processing')");
 await js("document.querySelector('.order-status-form button').click()");
 assert.equal(dialogs,1);assert.equal(await js("document.querySelector('.shop-heading .shop-status').dataset.status"),'Pending');
 accept=true;
 await js("document.querySelector('.order-status-form button').click()");
 await waitFor("document.querySelector('.shop-heading .shop-status').dataset.status==='Confirmed'");
 assert.equal(dialogs,2);
 await js("document.querySelector('.admin-order-cancel').open=true;document.querySelector('[name=reason]').value='   ';document.querySelector('.admin-order-cancel button').click()");
 assert.equal(dialogs,2);
 await js("var r=document.querySelector('[name=reason]');r.value='Admin browser verification';r.dispatchEvent(new Event('input'));document.querySelector('.admin-order-cancel button').click()");
 await waitFor("document.querySelector('.shop-heading .shop-status').dataset.status==='Cancelled'");
 assert.ok(await js("document.querySelector('.order-timeline').textContent.includes('Admin browser verification')"));
 console.log('PASS: admin 375/1440px layouts, sidebar icons, pagination/detail/back preserves filters, dismiss/accept confirmation, cancellation validation and history.');
} finally {ws.close()}
})().catch(e=>{console.error(e);process.exitCode=1});
