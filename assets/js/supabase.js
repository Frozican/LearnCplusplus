import { SUPABASE_URL, SUPABASE_ANON_KEY } from "./config.js";

// The learning app must remain usable even when the Supabase CDN is unavailable.
// Load the optional cloud client asynchronously instead of blocking app startup.
export let isSupabaseConfigured = Boolean(SUPABASE_URL && SUPABASE_ANON_KEY);
export let supabase = null;

export const supabaseReady = (async () => {
  if (!isSupabaseConfigured) return null;
  try {
    const { createClient } = await import("https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm");
    supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
    });
    return supabase;
  } catch (error) {
    console.warn("Supabase could not be loaded. Continuing with local progress.", error);
    isSupabaseConfigured = false;
    return null;
  }
})();
