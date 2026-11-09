const fs=require('node:fs');const assert=require('node:assert/strict');
(async()=>{
 const tabs=await(await fetch('http://127.0.0.1:9337/json')).json();const socket=new WebSocket(tabs.find(t=>t.type==='page').webSocketDebuggerUrl);await new Promise(r=>socket.addEventListener('open',r,{once:true}));let seq=0;const pending=new Map();
 socket.addEventListener('message',e=>{const m=JSON.parse(e.data);if(pending.has(m.id)){const p=pending.get(m.id);pending.delete(m.id);m.error?p.reject(m.error):p.resolve(m.result);}});
 function call(method,params={}){return new Promise((resolve,reject)=>{const id=++seq;pending.set(id,{resolve,reject});socket.send(JSON.stringify({id,method,params}));});}
 async function js(expression){const r=await call('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});if(r.exceptionDetails)throw Error(JSON.stringify(r.exceptionDetails));return r.result.value;}
 await call('Page.enable');
 for(const width of [1440,375]){
  await call('Emulation.setDeviceMetricsOverride',{width,height:1000,deviceScaleFactor:1,mobile:width<600});
  for(const path of ['/Shop','/Shop/Cart']){
   await call('Page.navigate',{url:'http://127.0.0.1:5307'+path});
   for(let n=0;n<30;n++){await new Promise(r=>setTimeout(r,150));if(await js('document.readyState==="complete" && !!document.querySelector(".shop-shell")'))break;}
   const metrics=await js('({width:innerWidth,scroll:document.documentElement.scrollWidth,title:document.querySelector("h1")?.innerText})');assert.ok(metrics.title,JSON.stringify(metrics));assert.ok(metrics.scroll<=metrics.width+1,'horizontal overflow '+path+' '+width+': '+JSON.stringify(metrics));
   if(path==='/Shop'){const screenshot=await call('Page.captureScreenshot',{format:'png',captureBeyondViewport:false});fs.writeFileSync('tests/shop-'+width+'.png',Buffer.from(screenshot.data,'base64'));}
  }
 }
 socket.close();console.log('PASS: Shop and cart render without horizontal overflow at 1440px and 375px.');
})().catch(e=>{console.error(e);process.exitCode=1});
