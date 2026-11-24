(() => {
 const input=document.getElementById('ImageUrl'),button=document.getElementById('preview-product-image');
 const image=document.getElementById('product-image'),status=document.getElementById('product-image-status');
 button.hidden=false;
 let revision=0;
 function preview(){
  const current=++revision,value=input.value.trim();
  image.hidden=true;image.removeAttribute('src');
  if(!value){status.textContent='Chưa có đường dẫn ảnh.';return;}
  let url;
  try{url=new URL(value,location.origin);}catch{status.textContent='Đường dẫn ảnh không hợp lệ.';return;}
  const local=['/images/','/uploads/'].some(prefix=>value.startsWith(prefix)&&url.pathname.startsWith(prefix))&&!value.includes('\\')&&url.origin===location.origin;
  if(!local&&!(value.startsWith('https://')&&url.protocol==='https:')){status.textContent='Chọn ảnh thư viện, đường dẫn /images/... hoặc URL HTTPS.';return;}
  status.textContent='Đang tải ảnh…';
  const probe=new Image();probe.referrerPolicy='no-referrer';
  probe.onload=()=>{if(current!==revision)return;image.src=url.href;image.hidden=false;status.textContent='Ảnh xem trước';};
  probe.onerror=()=>{if(current!==revision)return;status.textContent='Không tải được ảnh. Kiểm tra lại đường dẫn.';};
  probe.src=url.href;
 }
 button.addEventListener('click',preview);
 document.getElementById('product-asset').addEventListener('change',event=>{if(event.target.value){input.value=event.target.value;preview();}});
 input.addEventListener('input',()=>{revision++;image.hidden=true;image.removeAttribute('src');status.textContent='Nhấn Xem trước ảnh để kiểm tra đường dẫn mới.';});
 if(input.value.trim())preview();
})();
