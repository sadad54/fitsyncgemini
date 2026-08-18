import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@/api/client";
import type { ClothingCategory, ClothingItem, Profile } from "@/types/api";

export const keys = {
  profile: ["profile"] as const,
  closetRoot: ["closet"] as const,
  closet: (category?: string, search?: string) => ["closet", category ?? "all", search ?? ""] as const,
  closetItem: (id: string) => ["closet-item", id] as const,
  stats: ["closet-stats"] as const,
  outfitsRoot: ["outfits"] as const,
  outfits: (savedOnly: boolean) => ["outfits", savedOnly] as const,
  tryonsRoot: ["tryons"] as const,
  tryon: (id: string) => ["tryon", id] as const,
  health: ["health"] as const
};

export function useProfile(enabled = true) {
  return useQuery({ queryKey: keys.profile, queryFn: api.profile, enabled });
}

export function useUpdateProfile() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (input: Partial<Profile>) => api.updateProfile(input),
    onSuccess: (profile) => queryClient.setQueryData(keys.profile, profile)
  });
}

export function useCloset(category: ClothingCategory | "all" = "all", search = "") {
  return useQuery({ queryKey: keys.closet(category, search), queryFn: () => api.closetItems({ category, search }) });
}

export function useClosetItem(id: string, enabled = true) {
  return useQuery({ queryKey: keys.closetItem(id), queryFn: () => api.closetItem(id), enabled: Boolean(id) && enabled });
}

export function useClosetStats() {
  return useQuery({ queryKey: keys.stats, queryFn: api.closetStats });
}

export function useOutfits(savedOnly = false) {
  return useQuery({ queryKey: keys.outfits(savedOnly), queryFn: () => api.outfits(savedOnly) });
}

export function useSavedOutfits() {
  return useOutfits(true);
}

export function useAddClosetItem() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: api.addClosetItem,
    onSuccess: (item) => {
      queryClient.setQueryData(keys.closetItem(item.id), item);
      queryClient.invalidateQueries({ queryKey: keys.closetRoot });
      queryClient.invalidateQueries({ queryKey: keys.stats });
    }
  });
}

export function useDetectClosetItemCategory() {
  return useMutation({ mutationFn: api.detectClosetItemCategory });
}

export function useUpdateClosetItem() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, input }: { id: string; input: Partial<ClothingItem> }) => api.updateClosetItem(id, input),
    onSuccess: (item) => {
      queryClient.setQueryData(keys.closetItem(item.id), item);
      queryClient.invalidateQueries({ queryKey: keys.closetRoot });
      queryClient.invalidateQueries({ queryKey: keys.stats });
    }
  });
}

export function useDeleteClosetItem() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: api.deleteClosetItem,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: keys.closetRoot });
      queryClient.invalidateQueries({ queryKey: keys.stats });
      queryClient.invalidateQueries({ queryKey: keys.outfitsRoot });
    }
  });
}

export function useGenerateOutfit() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: api.generateOutfit,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: keys.outfitsRoot })
  });
}

export function useSaveOutfit() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: api.saveOutfit,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: keys.outfitsRoot })
  });
}

export function useFavoriteOutfit() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: api.favoriteOutfit,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: keys.outfitsRoot })
  });
}

export function useOutfitFeedback() {
  return useMutation({ mutationFn: ({ id, rating, reason }: { id: string; rating: number; reason?: string }) => api.feedbackOutfit(id, rating, reason) });
}

export function useTryOns() {
  return useQuery({ queryKey: keys.tryonsRoot, queryFn: api.tryOns });
}

export function useCreateTryOn() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: api.createTryOn,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: keys.tryonsRoot })
  });
}

export function useDeleteTryOn() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: api.deleteTryOn,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: keys.tryonsRoot })
  });
}
