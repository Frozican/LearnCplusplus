import {supabase,isSupabaseConfigured} from "./supabase.js";
export async function getSession(){if(!isSupabaseConfigured)return null;const {data,error}=await supabase.auth.getSession();if(error)throw error;return data.session;}
export async function signUp(email,password,displayName){const {data,error}=await supabase.auth.signUp({email,password,options:{data:{display_name:displayName}}});if(error)throw error;return data;}
export async function signIn(email,password){const {data,error}=await supabase.auth.signInWithPassword({email,password});if(error)throw error;return data;}
export async function signOut(){if(!isSupabaseConfigured)return;const {error}=await supabase.auth.signOut();if(error)throw error;}
export async function resetPassword(email){const {error}=await supabase.auth.resetPasswordForEmail(email,{redirectTo:location.origin+location.pathname});if(error)throw error;}
export function onAuthChange(callback){if(!isSupabaseConfigured)return()=>{};const {data}=supabase.auth.onAuthStateChange((_event,session)=>callback(session));return()=>data.subscription.unsubscribe();}
