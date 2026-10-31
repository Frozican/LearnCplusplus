const lessons = window.lessonData;
const state=JSON.parse(localStorage.getItem('learncpp-progress')||'{"done":[],"quiz":{},"xp":0}');
const all=()=>Object.entries(lessons).flatMap(([course,items])=>items.map((l,i)=>({course,index:i,...l})));
const total=all().length;
const save=()=>{localStorage.setItem('learncpp-progress',JSON.stringify(state));updateProgress()};
const updateProgress=()=>{const n=state.done.length,p=Math.round(n/total*100);document.getElementById('side-percent').textContent=p+'%';document.getElementById('side-count').textContent=n+' / '+total+' lessons';document.getElementById('side-fill').style.width=p+'%'};
const content=document.getElementById('content');
let current={view:'home'};
const escapeHtml=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function navActive(view,course){document.querySelectorAll('.nav-btn').forEach(b=>b.classList.toggle('active',b.dataset.view===view||b.dataset.course===course));}
