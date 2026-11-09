(()=>{
 const form=document.getElementById('checkout-form');if(!form)return;
 const review=document.getElementById('checkout-review'),submit=document.getElementById('checkout-submit'),edit=document.getElementById('checkout-edit');
 const fields=['Recipient','Phone','Address','Note'].map(name=>form.elements.namedItem(name));
 let reviewed=false;
 submit.textContent='Kiểm tra đơn hàng';
 function reset(){reviewed=false;review.hidden=true;edit.hidden=true;submit.textContent='Kiểm tra đơn hàng';}
 fields.forEach(field=>field.addEventListener('input',reset));
 edit.addEventListener('click',()=>{reset();fields[0].focus();});
 form.addEventListener('submit',event=>{
  if(reviewed){submit.disabled=true;submit.textContent='Đang đặt hàng…';return;}
  event.preventDefault();
  document.getElementById('checkout-recipient').textContent=fields[0].value.trim()+' · '+fields[1].value.trim();
  document.getElementById('checkout-address').textContent=fields[2].value.trim();
  document.getElementById('checkout-note').textContent=fields[3].value.trim()?'Ghi chú: '+fields[3].value.trim():'';
  reviewed=true;review.hidden=false;edit.hidden=false;submit.textContent='Xác nhận đặt hàng';review.focus();
 });
 window.addEventListener('pageshow',()=>{submit.disabled=false;reset();});
})();
