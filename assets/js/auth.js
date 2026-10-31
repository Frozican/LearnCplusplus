import { supabaseReady, isSupabaseConfigured } from "./supabase.js";

async function client() {
  const value = await supabaseReady;
  if (!value || !isSupabaseConfigured) throw new Error("Cloud sign-in is unavailable. You can keep learning with local progress.");
  return value;
}
export async function getSession() {
  const value = await supabaseReady;
  if (!value || !isSupabaseConfigured) return null;
  const { data, error } = await value.auth.getSession();
  if (error) throw error;
  return data.session;
}
export async function signUp(email, password, displayName) {
  const value = await client();
  const { data, error } = await value.auth.signUp({ email, password, options: { data: { display_name: displayName } } });
  if (error) throw error;
  return data;
}
export async function signIn(email, password) {
  const value = await client();
  const { data, error } = await value.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return data;
}
export async function signOut() {
  const value = await client();
  const { error } = await value.auth.signOut();
  if (error) throw error;
}
export async function resetPassword(email) {
  const value = await client();
  const { error } = await value.auth.resetPasswordForEmail(email, { redirectTo: location.origin + location.pathname });
  if (error) throw error;
}
export function onAuthChange(callback) {
  let subscription = null;
  let active = true;
  supabaseReady.then(value => {
    if (!active || !value || !isSupabaseConfigured) return;
    const { data } = value.auth.onAuthStateChange((_event, session) => callback(session));
    subscription = data.subscription;
  });
  return () => { active = false; subscription?.unsubscribe(); };
}
