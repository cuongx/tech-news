(() => {
 const form=document.getElementById('profile-form');
 const hint=document.getElementById('profile-save-hint');
 const fields=[...form.querySelectorAll('input:not([type=hidden])')];
 const update=()=>{hint.textContent=fields.some(f=>f.value!==f.defaultValue)?'Bạn có thay đổi chưa lưu.':'Chưa có thay đổi.';};
 form.addEventListener('input',update);
 form.addEventListener('reset',()=>setTimeout(update,0));
 document.querySelectorAll('.account-password-input button').forEach(button=>{
  button.hidden=false;
  const input=document.getElementById(button.dataset.password);
  const label=button.getAttribute('aria-label');
  button.addEventListener('click',()=>{
   const visible=input.type==='password';
   input.type=visible?'text':'password';
   button.textContent=visible?'Ẩn':'Hiện';
   button.setAttribute('aria-pressed',String(visible));
   button.setAttribute('aria-label',visible?label.replace('Hiện','Ẩn'):label);
  });
 });
 const passwordForm=document.getElementById('profile-password-form');
 const password=document.getElementById('newPassword'),confirm=document.getElementById('confirmPassword');
 const validate=()=>confirm.setCustomValidity(confirm.value&&confirm.value!==password.value?'Mật khẩu xác nhận không khớp.':'');
 password.addEventListener('input',validate);confirm.addEventListener('input',validate);
 passwordForm.addEventListener('reset',()=>{
  confirm.setCustomValidity('');
  passwordForm.querySelectorAll('button[aria-pressed=true]').forEach(button=>button.click());
 });
})();
