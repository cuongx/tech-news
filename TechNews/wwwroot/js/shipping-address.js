(()=>{
 const province=document.getElementById('ProvinceCode'),ward=document.getElementById('WardCode');
 if(!province||!ward)return;
 const wards=new Map([...ward.querySelectorAll('optgroup')].map(group=>[group.dataset.province,[...group.querySelectorAll('option')].map(o=>({value:o.value,text:o.textContent}))]));
 function refresh(keepSelection){
  const selected=keepSelection?ward.value:'';
  const options=wards.get(province.value)||[];
  ward.replaceChildren(new Option(province.value?'Chọn phường / xã':'Chọn tỉnh / thành phố trước',''));
  for(const item of options)ward.add(new Option(item.text,item.value));
  ward.value=options.some(o=>o.value===selected)?selected:'';
  ward.disabled=!province.value;
 }
 province.addEventListener('change',()=>{refresh(false);ward.dispatchEvent(new Event('input',{bubbles:true}));});
 window.addEventListener('pageshow',()=>refresh(true));
 refresh(true);
})();
