import * as SecureStore from "expo-secure-store";
import { create } from "zustand";
import type { Session } from "@supabase/supabase-js";
import { supabase } from "@/lib/supabase";

const ACCESS_TOKEN_KEY = "fitsync.session.access-token";
const REFRESH_TOKEN_KEY = "fitsync.session.refresh-token";
const ONBOARDING_KEY = "fitsync.session.onboarding-complete";

type AuthState = {
  token: string | null;
  onboardingComplete: boolean;
  hydrated: boolean;
  authError: string | null;
  hydrate: () => Promise<void>;
  signUp: (email: string, password: string) => Promise<void>;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  completeOnboarding: () => Promise<void>;
};

async function readSecureValue(key: string) {
  if (process.env.EXPO_OS === "web") return globalThis.localStorage?.getItem(key) ?? null;
  return SecureStore.getItemAsync(key);
}

async function writeSecureValue(key: string, value: string | null) {
  if (process.env.EXPO_OS === "web") {
    if (value) globalThis.localStorage?.setItem(key, value);
    else globalThis.localStorage?.removeItem(key);
    return;
  }
  if (value) await SecureStore.setItemAsync(key, value);
  else await SecureStore.deleteItemAsync(key);
}

async function persistSession(session: Session | null) {
  await Promise.all([
    writeSecureValue(ACCESS_TOKEN_KEY, session?.access_token ?? null),
    writeSecureValue(REFRESH_TOKEN_KEY, session?.refresh_token ?? null)
  ]);
}

export const useAuthStore = create<AuthState>((set) => ({
  token: null,
  onboardingComplete: false,
  hydrated: false,
  authError: null,
  hydrate: async () => {
    const [accessToken, refreshToken, onboardingValue] = await Promise.all([
      readSecureValue(ACCESS_TOKEN_KEY),
      readSecureValue(REFRESH_TOKEN_KEY),
      readSecureValue(ONBOARDING_KEY)
    ]);

    if (accessToken && refreshToken) {
      const { data, error } = await supabase.auth.setSession({ access_token: accessToken, refresh_token: refreshToken });
      if (error || !data.session) {
        await persistSession(null);
        set({ token: null, onboardingComplete: false, hydrated: true });
      } else {
        await persistSession(data.session);
        set({ token: data.session.access_token, onboardingComplete: onboardingValue === "true", hydrated: true });
      }
    } else {
      set({ token: null, onboardingComplete: onboardingValue === "true", hydrated: true });
    }

    supabase.auth.onAuthStateChange(async (_event, session) => {
      await persistSession(session);
      set({ token: session?.access_token ?? null });
    });
  },
  signUp: async (email, password) => {
    set({ authError: null });
    const { data, error } = await supabase.auth.signUp({ email: email.trim(), password });
    if (error) {
      set({ authError: error.message });
      throw error;
    }
    if (data.session) {
      await persistSession(data.session);
      set({ token: data.session.access_token });
    }
  },
  signIn: async (email, password) => {
    set({ authError: null });
    const { data, error } = await supabase.auth.signInWithPassword({ email: email.trim(), password });
    if (error) {
      set({ authError: error.message });
      throw new Error(error.message);
    }
    await persistSession(data.session);
    set({ token: data.session?.access_token ?? null });
  },
  completeOnboarding: async () => {
    await writeSecureValue(ONBOARDING_KEY, "true");
    set({ onboardingComplete: true });
  },
  signOut: async () => {
    await supabase.auth.signOut();
    await Promise.all([persistSession(null), writeSecureValue(ONBOARDING_KEY, null)]);
    set({ token: null, onboardingComplete: false, hydrated: true });
  }
}));
