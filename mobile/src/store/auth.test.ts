jest.mock("expo-secure-store", () => ({
  getItemAsync: jest.fn(async () => null),
  setItemAsync: jest.fn(async () => undefined),
  deleteItemAsync: jest.fn(async () => undefined)
}));

jest.mock("@/lib/supabase", () => ({
  supabase: {
    auth: {
      setSession: jest.fn(async () => ({ data: { session: null }, error: null })),
      signUp: jest.fn(),
      signInWithPassword: jest.fn(),
      signOut: jest.fn(async () => ({ error: null })),
      onAuthStateChange: jest.fn(() => ({ data: { subscription: { unsubscribe: jest.fn() } } }))
    }
  }
}));

import { supabase } from "@/lib/supabase";
import { useAuthStore } from "@/store/auth";

const mockedSignInWithPassword = supabase.auth.signInWithPassword as jest.Mock;

describe("useAuthStore.signIn", () => {
  beforeEach(() => {
    useAuthStore.setState({ token: null, onboardingComplete: false, hydrated: false, authError: null });
    mockedSignInWithPassword.mockReset();
  });

  it("stores the access token after a successful sign-in", async () => {
    mockedSignInWithPassword.mockResolvedValue({
      data: { session: { access_token: "access-123", refresh_token: "refresh-123" } },
      error: null
    });

    await useAuthStore.getState().signIn("stylist@example.com", "hunter2!");

    expect(useAuthStore.getState().token).toBe("access-123");
    expect(useAuthStore.getState().authError).toBeNull();
  });

  it("records the error message and does not set a token on failed sign-in", async () => {
    mockedSignInWithPassword.mockResolvedValue({
      data: { session: null },
      error: { message: "Invalid login credentials" }
    });

    await expect(useAuthStore.getState().signIn("stylist@example.com", "wrong-password")).rejects.toThrow();

    expect(useAuthStore.getState().token).toBeNull();
    expect(useAuthStore.getState().authError).toBe("Invalid login credentials");
  });
});
