document.querySelectorAll('.account-confirm').forEach(form=>{
 form.addEventListener('submit',event=>{
  if(!window.confirm(form.dataset.confirm))event.preventDefault();
 });
});
