import * as SecureStore from "expo-secure-store";
import { File, Paths } from "expo-file-system";
import { create } from "zustand";

/**
 * The user's default try-on photo, kept privately on this device so every
 * "Try it on" is one tap. Only the local file path is stored; the image is
 * uploaded per try-on job, as before.
 */
const KEY = "fitsync.fit-photo.uri";

async function read() {
  if (process.env.EXPO_OS === "web") return globalThis.localStorage?.getItem(KEY) ?? null;
  return SecureStore.getItemAsync(KEY);
}

async function write(value: string | null) {
  if (process.env.EXPO_OS === "web") {
    if (value) globalThis.localStorage?.setItem(KEY, value); else globalThis.localStorage?.removeItem(KEY);
    return;
  }
  if (value) await SecureStore.setItemAsync(KEY, value); else await SecureStore.deleteItemAsync(KEY);
}

type FitPhotoState = {
  uri: string | null;
  loaded: boolean;
  load: () => Promise<void>;
  save: (pickedUri: string) => Promise<string>;
  clear: () => Promise<void>;
};

export const useFitPhoto = create<FitPhotoState>((set, get) => ({
  uri: null,
  loaded: false,
  load: async () => {
    if (get().loaded) return;
    let uri = await read().catch(() => null);
    if (uri && process.env.EXPO_OS !== "web") {
      try { if (!new File(uri).exists) uri = null; } catch { uri = null; }
      if (!uri) await write(null);
    }
    set({ uri, loaded: true });
  },
  save: async (pickedUri) => {
    let stored = pickedUri;
    if (process.env.EXPO_OS !== "web") {
      try {
        // Picker results live in a cache the OS may purge; keep our own copy.
        const target = new File(Paths.document, `fit-photo-${Date.now()}.jpg`);
        new File(pickedUri).copy(target);
        const previous = get().uri;
        if (previous && previous !== pickedUri) { try { new File(previous).delete(); } catch { /* already gone */ } }
        stored = target.uri;
      } catch { /* fall back to the picker uri */ }
    }
    await write(stored);
    set({ uri: stored, loaded: true });
    return stored;
  },
  clear: async () => {
    const previous = get().uri;
    if (previous && process.env.EXPO_OS !== "web") { try { new File(previous).delete(); } catch { /* already gone */ } }
    await write(null);
    set({ uri: null });
  }
}));
