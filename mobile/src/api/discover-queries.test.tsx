jest.mock("@/api/client", () => ({ api: { setLike: jest.fn(), setJoined: jest.fn() } }));

import { notifyManager, QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { act, renderHook, waitFor } from "@testing-library/react-native";
import type { ReactNode } from "react";
import { api } from "@/api/client";
import { discoverKeys, patchPostEverywhere, useToggleJoin, useToggleLike } from "@/api/discover-queries";
import type { CommunityMember, CommunityPost, StyleChallenge } from "@/types/api";

// Deliver React Query notifications synchronously so state updates land inside act().
notifyManager.setScheduler((callback) => callback());

const setLike = api.setLike as jest.Mock;
const setJoined = api.setJoined as jest.Mock;

const post = (id: string, overrides: Partial<CommunityPost> = {}): CommunityPost => ({
  id, user_id: "u1", author_name: "Rina", content: "", image_url: null, tags: [], challenge_id: null,
  likes_count: 5, comments_count: 0, liked: false, following: false, created_at: "2026-11-03T00:00:00Z", ...overrides
});

function setup() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false, gcTime: Infinity }, mutations: { retry: false, gcTime: Infinity } } });
  clients.push(client);
  const wrapper = ({ children }: { children: ReactNode }) => <QueryClientProvider client={client}>{children}</QueryClientProvider>;
  return { client, wrapper };
}

const clients: QueryClient[] = [];
afterEach(() => {
  jest.resetAllMocks();
  clients.splice(0).forEach((client) => client.clear());
});

describe("patchPostEverywhere", () => {
  it("updates the post in feeds, its own cache, member pages and challenge entries", () => {
    const { client } = setup();
    client.setQueryData(discoverKeys.posts("discover"), [post("a"), post("b")]);
    client.setQueryData(discoverKeys.posts("following"), [post("a")]);
    client.setQueryData(discoverKeys.post("a"), post("a"));
    client.setQueryData<CommunityMember>(discoverKeys.member("u1"), {
      user_id: "u1", name: "Rina", style_tags: [], posts_count: 1, followers_count: 0, challenges_count: 0, following: false, is_self: false, posts: [post("a")]
    });

    patchPostEverywhere(client, "a", (p) => ({ ...p, likes_count: 99 }));

    expect(client.getQueryData<CommunityPost[]>(discoverKeys.posts("discover"))!.map((p) => p.likes_count)).toEqual([99, 5]);
    expect(client.getQueryData<CommunityPost[]>(discoverKeys.posts("following"))![0].likes_count).toBe(99);
    expect(client.getQueryData<CommunityPost>(discoverKeys.post("a"))!.likes_count).toBe(99);
    expect(client.getQueryData<CommunityMember>(discoverKeys.member("u1"))!.posts[0].likes_count).toBe(99);
  });
});

describe("useToggleLike", () => {
  it("updates optimistically, then takes the server's count", async () => {
    const { client, wrapper } = setup();
    client.setQueryData(discoverKeys.posts("discover"), [post("a")]);
    let resolve!: (value: { liked: boolean; likes_count: number }) => void;
    setLike.mockReturnValue(new Promise((r) => { resolve = r; }));

    const { result } = renderHook(() => useToggleLike(), { wrapper });
    act(() => result.current.mutate({ postId: "a", liked: true }));

    await waitFor(() => expect(client.getQueryData<CommunityPost[]>(discoverKeys.posts("discover"))![0]).toMatchObject({ liked: true, likes_count: 6 }));
    await act(async () => resolve({ liked: true, likes_count: 9 }));
    await waitFor(() => expect(client.getQueryData<CommunityPost[]>(discoverKeys.posts("discover"))![0].likes_count).toBe(9));
    expect(setLike).toHaveBeenCalledWith("a", true);
  });

  it("rolls back when the request fails", async () => {
    const { client, wrapper } = setup();
    client.setQueryData(discoverKeys.posts("discover"), [post("a", { liked: true, likes_count: 3 })]);
    setLike.mockRejectedValue(new Error("offline"));

    const { result } = renderHook(() => useToggleLike(), { wrapper });
    act(() => result.current.mutate({ postId: "a", liked: false }));

    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(client.getQueryData<CommunityPost[]>(discoverKeys.posts("discover"))![0]).toMatchObject({ liked: true, likes_count: 3 });
  });
});

describe("useToggleJoin", () => {
  it("syncs the joined flag and participant count from the server", async () => {
    const { client, wrapper } = setup();
    const challenge: StyleChallenge = {
      id: "c1", title: "Mono", description: "", reward: "", difficulty: "easy", participants_count: 10, days_left: 3, joined: false
    };
    client.setQueryData(discoverKeys.challenges, [challenge]);
    setJoined.mockResolvedValue({ joined: true, participants_count: 12 });

    const { result } = renderHook(() => useToggleJoin(), { wrapper });
    await act(async () => { await result.current.mutateAsync({ challengeId: "c1", joined: true }); });

    expect(client.getQueryData<StyleChallenge[]>(discoverKeys.challenges)![0]).toMatchObject({ joined: true, participants_count: 12 });
  });
});
