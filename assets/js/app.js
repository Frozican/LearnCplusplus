document.querySelectorAll('[data-view]').forEach(b=>b.addEventListener('click',()=>{document.getElementById('sidebar').classList.remove('open');b.dataset.view==='home'?home():b.dataset.view==='progress'?openProgress():openPractice()}));
document.querySelectorAll('[data-course]').forEach(b=>b.addEventListener('click',()=>{document.getElementById('sidebar').classList.remove('open');openCourse(b.dataset.course)}));
document.getElementById('menu').addEventListener('click',()=>document.getElementById('sidebar').classList.toggle('open'));
document.getElementById('search').addEventListener('input',e=>searchLessons(e.target.value));
document.addEventListener('click',e=>{if(!e.target.closest('.top-actions'))document.getElementById('search-results').classList.add('hidden')});
document.addEventListener('keydown',e=>{if(e.key==='/'&&!['INPUT','TEXTAREA'].includes(document.activeElement.tagName)){e.preventDefault();document.getElementById('search').focus()}if(e.key==='Escape'){document.getElementById('search-results').classList.add('hidden');document.getElementById('sidebar').classList.remove('open')}});
home();
