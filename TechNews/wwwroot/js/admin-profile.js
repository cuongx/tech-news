const profileForm=document.getElementById('profile-form');
const profileHint=document.getElementById('profile-save-hint');
if(profileForm&&profileHint){
 const inputs=[...profileForm.querySelectorAll('input:not([type=hidden])')];
 const update=()=>{profileHint.textContent=inputs.some(input=>input.value!==input.defaultValue)?'Bạn có thay đổi chưa lưu.':'Chưa có thay đổi.';};
 profileForm.addEventListener('input',update);
 profileForm.addEventListener('reset',()=>setTimeout(update,0));
}
document.querySelectorAll('.profile-reveal').forEach(button=>{
 button.hidden=false;
 const field=document.getElementById(button.dataset.password);
 const label=button.getAttribute('aria-label');
 button.addEventListener('click',()=>{
  const reveal=field.type==='password';
  field.type=reveal?'text':'password';
  button.setAttribute('aria-pressed',String(reveal));
  button.setAttribute('aria-label',reveal?label.replace('Hiện','Ẩn'):label);
  button.querySelector('i').className=reveal?'far fa-eye-slash':'far fa-eye';
 });
});
document.getElementById('profile-password-form')?.addEventListener('reset',()=>{
 document.querySelectorAll('.profile-reveal[aria-pressed=true]').forEach(button=>button.click());
});
