import type { ClosetStats, ClothingCategory, ClothingItem, Outfit, Profile } from "@/types/api";
import { useAuthStore } from "@/store/auth";

const isLocalWebPreview = process.env.EXPO_OS === "web" && typeof window !== "undefined" && ["localhost", "127.0.0.1"].includes(window.location.hostname);
// A browser preview runs on the same computer as the FastAPI process; a LAN
// address is only needed by Expo Go on a physical device.
const configuredBase = isLocalWebPreview ? "http://127.0.0.1:8000" : process.env.EXPO_PUBLIC_API_BASE_URL || "http://127.0.0.1:8000";
const API_BASE_URL = configuredBase.replace(/\/$/, "");

export class ApiError extends Error {
  constructor(message: string, public status: number, public code?: string) {
    super(message);
    this.name = "ApiError";
  }
}

export function mediaUrl(path?: string | null) {
  if (!path) return null;
  if (path.startsWith("http")) return path;
  return `${API_BASE_URL}${path.startsWith("/") ? path : `/${path}`}`;
}

function errorMessage(payload: unknown, fallback: string) {
  if (typeof payload === "object" && payload) {
    if ("detail" in payload && typeof payload.detail === "string") return payload.detail;
    if ("detail" in payload && Array.isArray(payload.detail)) {
      return payload.detail
        .map((entry) => {
          if (typeof entry !== "object" || !entry) return null;
          const location = "loc" in entry && Array.isArray(entry.loc) ? entry.loc.join(".") : "request";
          const message = "msg" in entry && typeof entry.msg === "string" ? entry.msg : "Invalid value";
          return `${location}: ${message}`;
        })
        .filter(Boolean)
        .join("\n") || fallback;
    }
    if ("message" in payload && typeof payload.message === "string") return payload.message;
  }
  return fallback;
}

function imageName(inputName: string, uri: string) {
  const fallback = `${inputName.trim().toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || "closet-item"}.jpg`;
  const fromUri = uri.split("?")[0]?.split("/").pop();
  return fromUri && /\.[a-z0-9]+$/i.test(fromUri) ? fromUri : fallback;
}

async function imagePart(uri: string, name: string) {
  if (process.env.EXPO_OS === "web") {
    const response = await fetch(uri);
    const blob = await response.blob();
    return new File([blob], name, { type: blob.type || "image/jpeg" });
  }

  return { uri, name, type: "image/jpeg" } as unknown as Blob;
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = useAuthStore.getState().token;
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15000);

  try {
    const response = await fetch(`${API_BASE_URL}/api/v1${path}`, {
      ...options,
      signal: controller.signal,
      headers: {
        Accept: "application/json",
        ...(options.body instanceof FormData ? {} : { "Content-Type": "application/json" }),
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...options.headers
      }
    });

    const payload = await response.json().catch(() => null);
    if (!response.ok) throw new ApiError(errorMessage(payload, `Request failed with ${response.status}`), response.status);
    return payload as T;
  } catch (error) {
    if (error instanceof ApiError) throw error;
    if (error instanceof Error && error.name === "AbortError") throw new ApiError("The request timed out. Check your connection and try again.", 0, "TIMEOUT");
    throw new ApiError("FitSync could not reach the backend. Check the API address and your connection.", 0, "NETWORK_ERROR");
  } finally {
    clearTimeout(timeout);
  }
}

export const api = {
  health: async () => {
    const response = await fetch(`${API_BASE_URL}/health`);
    if (!response.ok) throw new ApiError("Backend health check failed.", response.status);
    return response.json() as Promise<{ status: string; service: string }>;
  },
  profile: () => request<Profile>("/auth/me"),
  updateProfile: (profile: Partial<Profile>) => request<Profile>("/auth/me", { method: "PUT", body: JSON.stringify(profile) }),
  closetItems: (params?: { category?: ClothingCategory | "all"; search?: string }) => {
    const qs = new URLSearchParams();
    if (params?.category && params.category !== "all") qs.set("category", params.category);
    if (params?.search) qs.set("search", params.search);
    const suffix = qs.toString() ? `?${qs}` : "";
    return request<{ items: ClothingItem[]; total: number }>(`/closet/items${suffix}`);
  },
  closetItem: (id: string) => request<ClothingItem>(`/closet/items/${id}`),
  closetStats: () => request<ClosetStats>("/closet/stats"),
  addClosetItem: async (input: { name: string; category?: ClothingCategory; imageUri: string; brand?: string; notes?: string }) => {
    const name = input.name.trim();
    const filename = imageName(name, input.imageUri);
    const form = new FormData();
    form.append("name", name);
    if (input.category) form.append("category", input.category);
    if (input.brand?.trim()) form.append("brand", input.brand.trim());
    if (input.notes?.trim()) form.append("notes", input.notes.trim());
    form.append("image", await imagePart(input.imageUri, filename));
    return request<ClothingItem>("/closet/items", { method: "POST", body: form });
  },
  updateClosetItem: (id: string, input: Partial<ClothingItem>) => request<ClothingItem>(`/closet/items/${id}`, { method: "PUT", body: JSON.stringify(input) }),
  deleteClosetItem: (id: string) => request<{ deleted: boolean }>(`/closet/items/${id}`, { method: "DELETE" }),
  generateOutfit: (input: { occasion: string; use_weather?: boolean; latitude?: number; longitude?: number }) =>
    request<Outfit>("/outfits/generate", { method: "POST", body: JSON.stringify(input) }),
  outfits: (savedOnly = false) => request<{ outfits: Outfit[]; total: number }>(`/outfits?saved_only=${savedOnly}`),
  saveOutfit: (id: string) => request<Outfit>(`/outfits/${id}/save`, { method: "POST" }),
  favoriteOutfit: (id: string) => request<Outfit>(`/outfits/${id}/favorite`, { method: "POST" }),
  feedbackOutfit: (id: string, rating: number, reason?: string) =>
    request<{ recorded: boolean }>(`/outfits/${id}/feedback`, { method: "POST", body: JSON.stringify({ rating, reason }) }),
  weather: (latitude: number, longitude: number) => request<Record<string, unknown>>(`/weather/current?latitude=${latitude}&longitude=${longitude}`)
};
