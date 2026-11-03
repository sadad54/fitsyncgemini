jest.mock("expo-secure-store", () => ({
  getItemAsync: jest.fn(async () => null),
  setItemAsync: jest.fn(async () => undefined),
  deleteItemAsync: jest.fn(async () => undefined)
}));
jest.mock("@/lib/supabase", () => ({ supabase: { auth: { onAuthStateChange: jest.fn(() => ({ data: { subscription: { unsubscribe: jest.fn() } } })) } } }));

import { api, ApiError } from "@/api/client";
import { useAuthStore } from "@/store/auth";

const fetchMock = jest.fn();
globalThis.fetch = fetchMock as unknown as typeof fetch;

const json = (status: number, body: unknown) => ({ ok: status < 400, status, json: async () => body });

beforeEach(() => {
  fetchMock.mockReset();
  useAuthStore.setState({ token: "jwt-123" });
});

it("calls the versioned API with the bearer token", async () => {
  fetchMock.mockResolvedValue(json(200, []));
  await api.posts("following", 10);
  const [url, init] = fetchMock.mock.calls[0];
  expect(url).toMatch(/\/api\/v1\/community\/posts\?feed=following&limit=10$/);
  expect(init.headers.Authorization).toBe("Bearer jwt-123");
});

it("encodes ids in paths and uses DELETE to unlike", async () => {
  fetchMock.mockResolvedValue(json(200, { liked: false, likes_count: 0 }));
  await api.setLike("a/b", false);
  const [url, init] = fetchMock.mock.calls[0];
  expect(url).toMatch(/\/community\/posts\/a%2Fb\/like$/);
  expect(init.method).toBe("DELETE");
});

it("surfaces FastAPI's detail message with the status", async () => {
  fetchMock.mockResolvedValue(json(404, { detail: "Post not found" }));
  await expect(api.post("x")).rejects.toMatchObject({ name: "ApiError", status: 404, message: "Post not found" });
});

it("flattens validation errors into readable lines", async () => {
  fetchMock.mockResolvedValue(json(422, { detail: [{ loc: ["query", "feed"], msg: "Input should be 'discover' or 'following'" }] }));
  await expect(api.posts("discover")).rejects.toThrow("query.feed: Input should be 'discover' or 'following'");
});

it("reports network failures with a stable code", async () => {
  jest.spyOn(console, "warn").mockImplementation(() => undefined); // the client logs failed calls in dev
  fetchMock.mockRejectedValue(new TypeError("Network request failed"));
  const error = await api.challenges().catch((e: unknown) => e);
  expect(error).toBeInstanceOf(ApiError);
  expect((error as ApiError).code).toBe("NETWORK_ERROR");
});

it("reports timeouts separately from network errors", async () => {
  const abort = new Error("aborted");
  abort.name = "AbortError";
  fetchMock.mockRejectedValue(abort);
  await expect(api.trends()).rejects.toMatchObject({ code: "TIMEOUT", status: 0 });
});
