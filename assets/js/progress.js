import { supabaseReady, isSupabaseConfigured } from "./supabase.js";
const KEY = "learncpp-v2";
const dateKey = (date = new Date()) => {
  const y = date.getFullYear(), m = String(date.getMonth()+1).padStart(2,"0"), d = String(date.getDate()).padStart(2,"0");
  return y+"-"+m+"-"+d;
};
const xpFor = s => {
  const passedChapters = new Set((s.tests||[]).filter(t => Number(t.score)>=4).map(t=>t.chapter_id)).size;
  return (s.completed||[]).length*25 + passedChapters*50;
};
export const emptyProgress = () => ({ completed: [], answers: [], tests: [], activityDays: [], xp: 0 });
export function loadLocal() {
  try {
    const saved = JSON.parse(localStorage.getItem(KEY) || "{}");
    const state = { ...emptyProgress(), ...saved, completed: Array.isArray(saved.completed)?saved.completed:[], answers: Array.isArray(saved.answers)?saved.answers:[], tests: Array.isArray(saved.tests)?saved.tests:[], activityDays: Array.isArray(saved.activityDays)?saved.activityDays:[] };
    state.xp = xpFor(state);
    return state;
  } catch { return emptyProgress(); }
}
export function saveLocal(s) {
  s.activityDays = [...new Set(s.activityDays||[])].sort();
  s.xp = xpFor(s);
  localStorage.setItem(KEY, JSON.stringify(s));
}
function streakStats(days) {
  const sorted=[...new Set(days||[])].sort();
  const set=new Set(sorted), today=dateKey(), yesterday=dateKey(new Date(Date.now()-86400000));
  let current=0, cursor=set.has(today)?today:set.has(yesterday)?yesterday:null;
  while(cursor && set.has(cursor)){
    current++;
    const d=new Date(cursor+"T12:00:00");
    d.setDate(d.getDate()-1);
    cursor=dateKey(d);
  }
  let best=0, run=0, previous=null;
  for(const key of sorted){
    const d=new Date(key+"T12:00:00");
    const expected=previous?new Date(previous+"T12:00:00"):null;
    if(expected){expected.setDate(expected.getDate()+1);run=dateKey(expected)===key?run+1:1}else run=1;
    best=Math.max(best,run);previous=key;
  }
  return { current, best, activeToday:set.has(today) };
}
export function getGamification(s) {
  const xp=xpFor(s);
  let level=1, floor=0, next=100;
  while(xp>=next){floor=next;level++;next+=100+(level-2)*50;}
  const streak=streakStats(s.activityDays);
  return {xp,level,levelFloor:floor,nextLevelXp:next,levelProgress:Math.max(0,Math.min(100,(xp-floor)/(next-floor)*100)),...streak};
}
export async function loadProgress(user) {
  const local=loadLocal(), client=await supabaseReady;
  if(!user||!client||!isSupabaseConfigured)return local;
  const [p,a,t]=await Promise.all([
    client.from("lesson_progress").select("lesson_id,completed_at").eq("user_id",user.id),
    client.from("quiz_attempts").select("lesson_id,skill,correct,created_at").eq("user_id",user.id).order("created_at",{ascending:false}).limit(500),
    client.from("chapter_test_attempts").select("chapter_id,score,total,created_at").eq("user_id",user.id).order("created_at",{ascending:false}).limit(100)
  ]);
  for(const x of [p,a,t])if(x.error)throw x.error;
  const completedRows=p.data||[], answers=a.data||[], tests=t.data||[];
  const cloudDays=completedRows.map(x=>dateKey(new Date(x.completed_at)));
  const mergedDays=[...new Set([...(local.activityDays||[]),...cloudDays])];
  const state={completed:completedRows.map(x=>x.lesson_id),answers,tests,activityDays:mergedDays,xp:0};
  state.xp=xpFor(state);
  return state;
}
export async function saveLesson(user,s,id) {
  if(!s.completed.includes(id)){
    s.completed.push(id);
    s.activityDays=[...new Set([...(s.activityDays||[]),dateKey()])];
  }
  saveLocal(s);
  const client=await supabaseReady;
  if(user&&client&&isSupabaseConfigured){
    const {error}=await client.from("lesson_progress").upsert({user_id:user.id,lesson_id:id,completed_at:new Date().toISOString()},{onConflict:"user_id,lesson_id"});
    if(error)throw error;
  }
}
export async function recordAnswer(user,s,lesson,correct) {
  const a={lesson_id:lesson.id,skill:lesson.tags[0],correct,created_at:new Date().toISOString()};
  s.answers.unshift(a);
  if(s.answers.length>500)s.answers.length=500;
  saveLocal(s);
  const client=await supabaseReady;
  if(user&&client&&isSupabaseConfigured){
    const {error}=await client.from("quiz_attempts").insert({user_id:user.id,...a});
    if(error)throw error;
  }
}
export async function recordTest(user,s,chapterId,score,total) {
  const a={chapter_id:chapterId,score,total,created_at:new Date().toISOString()};
  s.tests.unshift(a);
  saveLocal(s);
  const client=await supabaseReady;
  if(user&&client&&isSupabaseConfigured){
    const {error}=await client.from("chapter_test_attempts").insert({user_id:user.id,...a});
    if(error)throw error;
  }
}
export function analyse(s) {
  const stats={};
  for(const a of s.answers||[]){
    const k=a.skill||"General";stats[k]??={right:0,total:0};stats[k].total++;if(a.correct)stats[k].right++;
  }
  const all=Object.entries(stats).map(([skill,v])=>({skill,total:v.total,accuracy:Math.round(v.right/v.total*100)})).filter(x=>x.total>=2).sort((a,b)=>b.accuracy-a.accuracy);
  return {strengths:all.filter(x=>x.accuracy>=80).slice(0,5),weaknesses:all.filter(x=>x.accuracy<65).reverse().slice(0,5),all};
}
