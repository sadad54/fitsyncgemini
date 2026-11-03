import { useMutation, useQuery, useQueryClient, type QueryClient } from "@tanstack/react-query";
import { api } from "@/api/client";
import type { CommunityMember, CommunityPost, StyleChallenge, StyleChallengeDetail } from "@/types/api";

export const discoverKeys = {
  posts: (feed: "discover" | "following") => ["community", "posts", feed] as const,
  postsRoot: ["community", "posts"] as const,
  post: (id: string) => ["community", "post", id] as const,
  comments: (id: string) => ["community", "comments", id] as const,
  member: (id: string) => ["community", "member", id] as const,
  challenges: ["community", "challenges"] as const,
  challenge: (id: string) => ["community", "challenge", id] as const,
  trends: ["trends"] as const,
  trend: (id: string) => ["trend", id] as const,
  stores: (lat: number, lon: number) => ["stores", lat.toFixed(3), lon.toFixed(3)] as const,
  store: (id: string) => ["store", id] as const
};

export function usePosts(feed: "discover" | "following", enabled = true) {
  return useQuery({ queryKey: discoverKeys.posts(feed), queryFn: () => api.posts(feed), enabled });
}

export function usePost(id?: string) {
  return useQuery({ queryKey: discoverKeys.post(id ?? ""), queryFn: () => api.post(id!), enabled: Boolean(id) });
}

export function useComments(postId?: string) {
  return useQuery({ queryKey: discoverKeys.comments(postId ?? ""), queryFn: () => api.comments(postId!), enabled: Boolean(postId) });
}

export function useMember(userId?: string) {
  return useQuery({ queryKey: discoverKeys.member(userId ?? ""), queryFn: () => api.member(userId!), enabled: Boolean(userId) });
}

export function useChallenges() {
  return useQuery({ queryKey: discoverKeys.challenges, queryFn: api.challenges });
}

export function useChallenge(id?: string) {
  return useQuery({ queryKey: discoverKeys.challenge(id ?? ""), queryFn: () => api.challenge(id!), enabled: Boolean(id) });
}

export function useTrends() {
  return useQuery({ queryKey: discoverKeys.trends, queryFn: api.trends, staleTime: 10 * 60_000 });
}

export function useTrend(id?: string) {
  return useQuery({ queryKey: discoverKeys.trend(id ?? ""), queryFn: () => api.trend(id!), enabled: Boolean(id) });
}

export function useNearbyStores(position: { latitude: number; longitude: number } | null) {
  return useQuery({
    queryKey: discoverKeys.stores(position?.latitude ?? 0, position?.longitude ?? 0),
    queryFn: () => api.nearbyStores(position!.latitude, position!.longitude),
    enabled: Boolean(position),
    staleTime: 30 * 60_000
  });
}

export function useStore(placeId?: string) {
  return useQuery({ queryKey: discoverKeys.store(placeId ?? ""), queryFn: () => api.store(placeId!), enabled: Boolean(placeId), staleTime: 60 * 60_000 });
}

/** Apply `update` to one post wherever it is cached: feeds, the post itself, member pages and challenge entries. */
export function patchPostEverywhere(client: QueryClient, postId: string, update: (post: CommunityPost) => CommunityPost) {
  const patch = (post: CommunityPost) => (post.id === postId ? update(post) : post);
  client.setQueriesData<CommunityPost[]>({ queryKey: discoverKeys.postsRoot }, (posts) => posts?.map(patch));
  client.setQueryData<CommunityPost>(discoverKeys.post(postId), (post) => (post ? patch(post) : post));
  client.setQueriesData<CommunityMember>({ queryKey: ["community", "member"] }, (m) => (m ? { ...m, posts: m.posts.map(patch) } : m));
  client.setQueriesData<StyleChallengeDetail>({ queryKey: ["community", "challenge"] }, (c) => (c ? { ...c, entries: c.entries.map(patch) } : c));
}

/** Optimistic like/unlike, rolled back if the request fails, then reconciled with the server's count. */
export function useToggleLike() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: ({ postId, liked }: { postId: string; liked: boolean }) => api.setLike(postId, liked),
    onMutate: async ({ postId, liked }) => {
      await client.cancelQueries({ queryKey: ["community"] });
      const snapshot = client.getQueriesData({ queryKey: ["community"] });
      patchPostEverywhere(client, postId, (p) =>
        p.liked === liked ? p : { ...p, liked, likes_count: Math.max(0, p.likes_count + (liked ? 1 : -1)) });
      return { snapshot };
    },
    onError: (_error, _vars, context) => context?.snapshot.forEach(([key, data]) => client.setQueryData(key, data)),
    onSuccess: (result, { postId }) => patchPostEverywhere(client, postId, (p) => ({ ...p, liked: result.liked, likes_count: result.likes_count }))
  });
}

export function useAddComment(postId: string) {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (content: string) => api.addComment(postId, content),
    onSuccess: (comment) => {
      client.setQueryData(discoverKeys.comments(postId), (current: typeof comment[] | undefined) => [...(current ?? []), comment]);
      patchPostEverywhere(client, postId, (p) => ({ ...p, comments_count: p.comments_count + 1 }));
    }
  });
}

export function useCreatePost() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: api.createPost,
    onSuccess: () => client.invalidateQueries({ queryKey: ["community"] })
  });
}

export function useToggleFollow() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: ({ userId, following }: { userId: string; following: boolean }) => api.setFollow(userId, following),
    onMutate: async ({ userId, following }) => {
      await client.cancelQueries({ queryKey: discoverKeys.member(userId) });
      const previous = client.getQueryData<CommunityMember>(discoverKeys.member(userId));
      if (previous) client.setQueryData(discoverKeys.member(userId), { ...previous, following,
        followers_count: Math.max(0, previous.followers_count + (following === previous.following ? 0 : following ? 1 : -1)) });
      return { previous };
    },
    onError: (_e, { userId }, context) => { if (context?.previous) client.setQueryData(discoverKeys.member(userId), context.previous); },
    onSettled: () => client.invalidateQueries({ queryKey: discoverKeys.postsRoot })
  });
}

export function useToggleJoin() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: ({ challengeId, joined }: { challengeId: string; joined: boolean }) => api.setJoined(challengeId, joined),
    onMutate: async ({ challengeId, joined }) => {
      await client.cancelQueries({ queryKey: ["community"] });
      const snapshot = client.getQueriesData({ queryKey: ["community"] });
      const apply = <T extends StyleChallenge>(c: T): T => c.id !== challengeId || c.joined === joined ? c
        : { ...c, joined, participants_count: Math.max(0, c.participants_count + (joined ? 1 : -1)) };
      client.setQueryData<StyleChallenge[]>(discoverKeys.challenges, (list) => list?.map(apply));
      client.setQueryData<StyleChallengeDetail>(discoverKeys.challenge(challengeId), (c) => (c ? apply(c) : c));
      return { snapshot };
    },
    onError: (_e, _v, context) => context?.snapshot.forEach(([key, data]) => client.setQueryData(key, data)),
    onSuccess: (result, { challengeId }) => {
      const sync = <T extends StyleChallenge>(c: T): T => c.id === challengeId ? { ...c, joined: result.joined, participants_count: result.participants_count } : c;
      client.setQueryData<StyleChallenge[]>(discoverKeys.challenges, (list) => list?.map(sync));
      client.setQueryData<StyleChallengeDetail>(discoverKeys.challenge(challengeId), (c) => (c ? sync(c) : c));
    }
  });
}
