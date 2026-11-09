const fs=require('node:fs'),assert=require('node:assert/strict');
(async()=>{const tabs=await(await fetch('http://127.0.0.1:9342/json')).json();const ws=new WebSocket(tabs.find(t=>t.type==='page').webSocketDebuggerUrl);await new Promise(r=>ws.addEventListener('open',r,{once:true}));let id=0;const pending=new Map();ws.addEventListener('message',e=>{const m=JSON.parse(e.data),p=pending.get(m.id);if(p){pending.delete(m.id);m.error?p.reject(m.error):p.resolve(m.result)}});const call=(method,params={})=>new Promise((resolve,reject)=>{pending.set(++id,{resolve,reject});ws.send(JSON.stringify({id,method,params}))});async function js(expression){const r=await call('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});if(r.exceptionDetails)throw Error(JSON.stringify(r.exceptionDetails));return r.result.value;}
async function waitFor(expression){for(let i=0;i<50;i++){await new Promise(r=>setTimeout(r,120));if(await js(expression))return;}throw Error('Timeout: '+expression)}
async function go(path,selector){await call('Page.navigate',{url:'http://127.0.0.1:5312'+path});await waitFor('document.readyState==="complete" && !!document.querySelector('+JSON.stringify(selector)+')');}
async function screenshot(name){await new Promise(r=>setTimeout(r,300));let shot=await call('Page.captureScreenshot',{format:'png'});fs.writeFileSync(name,Buffer.from(shot.data,'base64'));}
try {
 await call('Page.enable');await call('Network.clearBrowserCookies');
 await call('Emulation.setDeviceMetricsOverride',{width:1440,height:1000,deviceScaleFactor:1,mobile:false});
 await go('/Admin/Login?returnUrl=/Shop','.login-submit');
 await js(`document.querySelector('#name').value='qa-admin';document.querySelector('#password').value='TechNews-Verify-2026!';document.querySelector('.login-submit').click()`);
 await waitFor(`location.pathname==='/Shop' && !!document.querySelector('.shop-grid')`);
 await go('/Shop?q=QA_ORDER_','.shop-grid a[href^="/Shop/Product/"]');
 const productPath=await js(`document.querySelector('.shop-grid a[href^="/Shop/Product/"]').getAttribute('href')`);
 await go(productPath,'.product-detail-add');await js(`document.querySelector('.product-detail-add').click()`);
 await waitFor(`document.querySelector('[data-cart-count]').textContent==='1'`);
 await go('/Shop/Checkout','#checkout-submit');
 await js(`var f=document.getElementById('checkout-form');f.elements.Recipient.value='Khách kiểm thử';f.elements.Phone.value='0901234567';f.elements.Address.value='123 Nguyễn Văn Linh, Đà Nẵng';f.elements.Note.value='<script>test</script>';document.getElementById('checkout-submit').click()`);
 assert.equal(await js(`location.pathname`),'/Shop/Checkout');
 assert.equal(await js(`document.getElementById('checkout-review').hidden`),false);
 assert.equal(await js(`document.getElementById('checkout-note').textContent`),'Ghi chú: <script>test</script>');
 assert.equal(await js(`document.getElementById('checkout-note').children.length`),0);
 await screenshot('checkout-review-desktop.png');
 await js(`document.getElementById('checkout-edit').click()`);assert.equal(await js(`document.getElementById('checkout-review').hidden`),true);
 await js(`document.getElementById('checkout-submit').click();var f=document.getElementById('checkout-form');f.elements.Address.value='456 Nguyễn Văn Linh, Đà Nẵng';f.elements.Address.dispatchEvent(new Event('input',{bubbles:true}))`);
 assert.equal(await js(`document.getElementById('checkout-review').hidden`),true,'editing invalidates review');
 await js(`document.getElementById('checkout-submit').click()`);
 await call('Emulation.setDeviceMetricsOverride',{width:375,height:1000,deviceScaleFactor:1,mobile:true});
 assert.ok(await js(`document.documentElement.scrollWidth<=innerWidth`),'checkout fits mobile');
 await js(`document.getElementById('checkout-review').scrollIntoView()`);await screenshot('checkout-review-mobile.png');
 await js(`document.getElementById('checkout-submit').click()`);await waitFor(`!!document.querySelector('.order-success')`);
 const orderPath=await js('location.pathname');
 assert.ok(await js(`document.documentElement.scrollWidth<=innerWidth`),'order fits mobile');
 await js(`document.querySelector('.order-success').scrollIntoView()`);await screenshot('order-success-mobile.png');
 assert.equal(await js(`document.querySelectorAll('.order-timeline li').length`),1);
 await js(`document.querySelector('.order-cancel').open=true;document.querySelector('[name=reason]').value='Thay đổi nhu cầu';document.querySelector('.order-cancel button').click()`);
 await waitFor(`!document.querySelector('.order-cancel') && document.querySelectorAll('.order-timeline li').length===2`);
 assert.ok(await js(`document.querySelector('.order-timeline').textContent.includes('Thay đổi nhu cầu')`));
 await js(`document.querySelector('.order-history').scrollIntoView()`);await screenshot('order-cancelled-mobile.png');
 await call('Emulation.setDeviceMetricsOverride',{width:1440,height:1000,deviceScaleFactor:1,mobile:false});
 await go(orderPath,'.order-history');await screenshot('order-cancelled-desktop.png');
 console.log('PASS: browser checkout review/edit/reset, escaped notes, submission, confirmation, cancellation history and 375px/1440px layouts.');
} finally {ws.close()}
})().catch(e=>{console.error(e);process.exitCode=1});
