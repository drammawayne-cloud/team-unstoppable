const search=document.getElementById('equipment-search'),category=document.getElementById('equipment-category'),grid=document.getElementById('equipment-grid');
let products=[];
function render(){
  const q=search.value.trim().toLowerCase(),rows=products.filter(p=>(category.value==='all'||p.category===category.value)&&(p.brand+' '+p.name+' '+p.description).toLowerCase().includes(q));
  grid.replaceChildren();document.getElementById('equipment-count').textContent=rows.length+' sourcing candidates';document.getElementById('equipment-empty').hidden=rows.length>0;
  for(const p of rows){
    const card=document.createElement('article');card.className='card equipment-card';
    const visual=document.createElement('div');visual.className='equipment-visual';visual.setAttribute('aria-hidden','true');visual.textContent=p.category==='controllers'?'◉ ━ ◉':p.category==='bass'?'◉':'◉\n◎';
    const brand=document.createElement('p');brand.className='eyebrow';brand.textContent=p.brand;
    const title=document.createElement('h3');title.textContent=p.name;
    const description=document.createElement('p');description.textContent=p.description;
    const status=document.createElement('p');status.className='equipment-status';status.textContent='Supplier availability pending';
    card.append(visual,brand,title,description,status);
    try{const url=new URL(p.source);if(url.protocol==='https:'){const link=document.createElement('a');link.className='text-link';link.textContent='Manufacturer details ↗';link.href=url.href;link.target='_blank';link.rel='noopener noreferrer';card.append(link);}}catch{}
    grid.append(card);
  }
}
search.addEventListener('input',render);category.addEventListener('change',render);
fetch('/equipment-catalog.json').then(r=>{if(!r.ok)throw Error();return r.json();}).then(d=>{products=d.products;render();}).catch(()=>{document.getElementById('equipment-count').textContent='The catalog is temporarily unavailable. Please try again later.';});
