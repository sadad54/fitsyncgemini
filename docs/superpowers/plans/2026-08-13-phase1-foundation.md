# Phase 1 Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the fake local-only mobile session with real Supabase email/password auth, and make the existing mobile screens read/write a real user profile through `backend/`'s `/api/v1/auth/me` route.

**Architecture:** Mobile authenticates directly against Supabase Auth (email+password) using `@supabase/supabase-js`, storing the resulting session tokens in `expo-secure-store`. Every authenticated call to `backend/` carries the Supabase access token as a Bearer token; `backend/`'s existing `unified_auth_service` verifies that token against Supabase and upserts a row in a new `user_profiles` table, which is the single source of truth for `display_name`, `style_preferences`, `favorite_colors`, `sizes`, and `onboarding_complete`.

**Tech Stack:** Expo/React Native/TypeScript (`mobile/`), FastAPI/Python (`backend/`), Supabase (Postgres + Auth), pytest, jest-expo.

## Global Constraints

- No paid APIs or services — Supabase free tier only for this phase (existing project `eixnacajmchafxkbtmnr`, already provisioned).
- `mobile/`'s API layer is being rewritten to match `backend/`'s existing route shapes, not the other way around (per approved spec).
- Email + password auth only for this phase — no OAuth providers, no password reset flow yet.
- Follow the existing mobile design system in `mobile/src/theme.ts` and the component patterns in `mobile/src/components/` — do not introduce a new styling approach.
- Every task must leave `backend/` and `mobile/` in a working, testable state — no partial/broken intermediate commits.

**Reference spec:** `docs/superpowers/specs/2026-08-13-phase1-foundation-design.md`

---

## Task 1: Create the `user_profiles` table in Supabase

**Files:** None (database migration via Supabase MCP tools — the `fitsync` project, id `eixnacajmchafxkbtmnr`).

**Interfaces:**
- Produces: a `public.user_profiles` table with columns `user_id uuid PK`, `email text`, `display_name text`, `style_preferences text[]`, `favorite_colors text[]`, `sizes jsonb`, `onboarding_complete boolean`, `created_at timestamptz`, `updated_at timestamptz`. Later tasks (2–4) read/write this table by these exact column names.

- [ ] **Step 1: Apply the migration**

Call the `mcp__claude_ai_Supabase__apply_migration` tool with `project_id: "eixnacajmchafxkbtmnr"`, `name: "create_user_profiles"`, and this SQL:

```sql
create table if not exists public.user_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text,
  style_preferences text[] not null default '{}',
  favorite_colors text[] not null default '{}',
  sizes jsonb not null default '{}'::jsonb,
  onboarding_complete boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_profiles enable row level security;

create policy "Users can view their own profile"
  on public.user_profiles for select
  using (auth.uid() = user_id);

create policy "Users can insert their own profile"
  on public.user_profiles for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own profile"
  on public.user_profiles for update
  using (auth.uid() = user_id);
```

- [ ] **Step 2: Verify the table exists with the right columns**

Call `mcp__claude_ai_Supabase__list_tables` with `project_id: "eixnacajmchafxkbtmnr"`, `schemas: ["public"]`, `verbose: true`.
Expected: the result includes a `user_profiles` table with the 9 columns listed above.

*(No git commit for this task — it's a live database change, not a file change. Note the migration name `create_user_profiles` in the Task 2 commit message for traceability.)*

---

## Task 2: Rewrite `User` / `UserUpdate` models to match the mobile profile shape

**Files:**
- Modify: `backend/app/models/user.py` (full rewrite)

**Interfaces:**
- Produces: `User` (fields: `user_id: str`, `email: EmailStr`, `display_name: Optional[str]`, `style_preferences: List[str]`, `favorite_colors: List[str]`, `sizes: Dict[str, str]`, `onboarding_complete: bool`, `created_at: datetime`, `updated_at: datetime`) and `UserUpdate` (all fields above except `user_id`/`email`/timestamps, all `Optional`). Tasks 3–5 import both from `app.models.user`.

- [ ] **Step 1: Replace the file contents**

```python
from pydantic import BaseModel, EmailStr
from typing import Dict, List, Optional
from datetime import datetime


class User(BaseModel):
    user_id: str
    email: EmailStr
    display_name: Optional[str] = None
    style_preferences: List[str] = []
    favorite_colors: List[str] = []
    sizes: Dict[str, str] = {}
    onboarding_complete: bool = False
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    display_name: Optional[str] = None
    style_preferences: Optional[List[str]] = None
    favorite_colors: Optional[List[str]] = None
    sizes: Optional[Dict[str, str]] = None
    onboarding_complete: Optional[bool] = None
```

- [ ] **Step 2: Confirm nothing else references the removed `UserBase`/`UserCreate`**

Run: `grep -rn "UserBase\|UserCreate" backend/app --include=*.py`
Expected: no matches (both were only used by the auth endpoints being rewritten in Task 4).

- [ ] **Step 3: Commit**

```bash
git add backend/app/models/user.py
git commit -m "refactor(backend): align User/UserUpdate models with mobile profile shape"
```

---

## Task 3: Rewrite `unified_auth_service` and fix `dependencies.py` typing

**Files:**
- Modify: `backend/app/services/unified_auth_service.py` (full rewrite)
- Modify: `backend/app/api/dependencies.py:1-25` (keep `validate_image_file` unchanged below)

**Interfaces:**
- Consumes: `User` from `app.models.user` (Task 2), the `public.user_profiles` table (Task 1).
- Produces: `auth_service.get_current_user_from_token(token: str) -> User`, `auth_service.update_profile(user_id: str, updates: dict) -> User`. Task 5's `/me` routes call both by these exact names.

- [ ] **Step 1: Replace `unified_auth_service.py`**

```python
from datetime import datetime, timezone
from fastapi import HTTPException, status
from supabase import create_client, Client
from app.core.config import settings
from app.models.user import User


class UnifiedAuthService:
    """Verifies Supabase-issued JWTs and keeps public.user_profiles in sync."""

    def __init__(self):
        self.supabase: Client = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_ROLE_KEY,
        )

    def _verify_supabase_token(self, token: str) -> dict:
        try:
            user_response = self.supabase.auth.get_user(token)
        except Exception:
            user_response = None

        if not user_response or not user_response.user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication token",
            )

        return {"id": user_response.user.id, "email": user_response.user.email}

    def _get_or_create_profile(self, user_id: str, email: str) -> dict:
        existing = self.supabase.table("user_profiles").select("*").eq("user_id", user_id).execute()
        if existing.data:
            return existing.data[0]

        now = datetime.now(timezone.utc).isoformat()
        new_profile = {
            "user_id": user_id,
            "email": email,
            "display_name": None,
            "style_preferences": [],
            "favorite_colors": [],
            "sizes": {},
            "onboarding_complete": False,
            "created_at": now,
            "updated_at": now,
        }
        result = self.supabase.table("user_profiles").insert(new_profile).execute()
        return result.data[0]

    async def get_current_user_from_token(self, token: str) -> User:
        if token.startswith("Bearer "):
            token = token[7:]

        supabase_user = self._verify_supabase_token(token)
        profile = self._get_or_create_profile(supabase_user["id"], supabase_user["email"])
        return User(**profile)

    async def update_profile(self, user_id: str, updates: dict) -> User:
        updates["updated_at"] = datetime.now(timezone.utc).isoformat()
        result = self.supabase.table("user_profiles").update(updates).eq("user_id", user_id).execute()
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Profile not found",
            )
        return User(**result.data[0])


auth_service = UnifiedAuthService()
```

- [ ] **Step 2: Fix the typing in `dependencies.py`**

Replace lines 1-25 of `backend/app/api/dependencies.py` (everything above the `# Image validation` comment) with:

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.models.user import User
from app.services.unified_auth_service import auth_service

security = HTTPBearer()

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> User:
    """Get current authenticated user"""
    try:
        return await auth_service.get_current_user_from_token(credentials.credentials)
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication failed"
        )

async def get_optional_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> User | None:
    """Get current user if authenticated, None otherwise"""
    try:
        return await auth_service.get_current_user_from_token(credentials.credentials)
    except Exception:
        return None
```

Leave `validate_image_file` (the rest of the file) unchanged.

- [ ] **Step 3: Verify the backend still imports cleanly**

Run: `cd backend && python -c "import app.main"`
Expected: no `ImportError`/`AttributeError` output.

- [ ] **Step 4: Commit**

```bash
git add backend/app/services/unified_auth_service.py backend/app/api/dependencies.py
git commit -m "fix(backend): return typed User from auth service instead of a raw dict"
```

---

## Task 4: Remove the legacy JWT auth code and fix `/me` in `v1/auth.py`

**Files:**
- Modify: `backend/app/api/endpoints/v1/auth.py` (full rewrite)
- Delete: `backend/app/api/endpoints/auth.py` (dead duplicate — not imported by `main.py`, confirmed via `grep -rn "endpoints.auth\b\|endpoints import auth" backend/app`)
- Delete: `backend/app/core/security.py` (only consumer was the two files above)

**Interfaces:**
- Consumes: `User`, `UserUpdate` (Task 2), `get_current_user` (Task 3), `auth_service.update_profile` (Task 3).
- Produces: `GET /api/v1/auth/me` and `PUT /api/v1/auth/me`. No other routes remain under `/api/v1/auth`.

- [ ] **Step 1: Replace `backend/app/api/endpoints/v1/auth.py`**

```python
from fastapi import APIRouter, Depends
from app.models.user import User, UserUpdate
from app.api.dependencies import get_current_user
from app.services.unified_auth_service import auth_service

router = APIRouter()


@router.get("/me", response_model=User)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    return current_user


@router.put("/me", response_model=User)
async def update_user_info(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_user),
):
    updates = user_update.model_dump(exclude_unset=True)
    return await auth_service.update_profile(current_user.user_id, updates)
```

- [ ] **Step 2: Delete the dead files**

```bash
rm backend/app/api/endpoints/auth.py
rm backend/app/core/security.py
```

- [ ] **Step 3: Confirm no remaining references**

Run: `grep -rn "core.security\|core import security\|endpoints.auth\b" backend/app --include=*.py`
Expected: no matches.

- [ ] **Step 4: Verify the backend still imports and starts cleanly**

Run: `cd backend && python -c "import app.main"`
Expected: no import errors.

- [ ] **Step 5: Commit**

```bash
git add -A backend/app/api/endpoints/v1/auth.py backend/app/api/endpoints/auth.py backend/app/core/security.py
git commit -m "refactor(backend): drop legacy custom-JWT auth, keep Supabase-only /me"
```

---

## Task 5: pytest coverage for `/api/v1/auth/me`

**Files:**
- Create: `backend/tests/__init__.py` (empty)
- Create: `backend/tests/conftest.py`
- Create: `backend/tests/test_auth.py`

**Interfaces:**
- Consumes: `app.main.app`, `app.api.dependencies.get_current_user`, `app.models.user.User`, `app.services.unified_auth_service.auth_service` (all from Tasks 2-4).

- [ ] **Step 1: Write the failing test file**

`backend/tests/__init__.py`:
```python
```

`backend/tests/conftest.py`:
```python
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from datetime import datetime, timezone

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.api.dependencies import get_current_user
from app.models.user import User

TEST_USER_ID = "00000000-0000-0000-0000-000000000001"


def _fake_user() -> User:
    now = datetime.now(timezone.utc)
    return User(
        user_id=TEST_USER_ID,
        email="stylist@example.com",
        display_name="Stylist",
        style_preferences=[],
        favorite_colors=[],
        sizes={},
        onboarding_complete=False,
        created_at=now,
        updated_at=now,
    )


@pytest.fixture
def client():
    app.dependency_overrides[get_current_user] = _fake_user
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()
```

`backend/tests/test_auth.py`:
```python
from datetime import datetime, timezone

from app.api.dependencies import get_current_user
from app.main import app
from app.models.user import User
from app.services import unified_auth_service as auth_module

TEST_USER_ID = "00000000-0000-0000-0000-000000000001"


def test_get_me_returns_current_user(client):
    response = client.get("/api/v1/auth/me", headers={"Authorization": "Bearer test-token"})
    assert response.status_code == 200
    body = response.json()
    assert body["user_id"] == TEST_USER_ID
    assert body["email"] == "stylist@example.com"
    assert body["onboarding_complete"] is False


def test_get_me_without_authorization_header_is_rejected(client):
    app.dependency_overrides.pop(get_current_user, None)
    response = client.get("/api/v1/auth/me")
    assert response.status_code in (401, 403)


def test_put_me_updates_and_returns_profile(client, monkeypatch):
    async def fake_update_profile(user_id, updates):
        assert user_id == TEST_USER_ID
        assert updates["display_name"] == "Nova"
        assert updates["style_preferences"] == ["minimal", "tailored"]
        now = datetime.now(timezone.utc)
        return User(
            user_id=user_id,
            email="stylist@example.com",
            display_name="Nova",
            style_preferences=["minimal", "tailored"],
            favorite_colors=[],
            sizes={},
            onboarding_complete=True,
            created_at=now,
            updated_at=now,
        )

    monkeypatch.setattr(auth_module.auth_service, "update_profile", fake_update_profile)

    response = client.put(
        "/api/v1/auth/me",
        json={"display_name": "Nova", "style_preferences": ["minimal", "tailored"], "onboarding_complete": True},
        headers={"Authorization": "Bearer test-token"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["display_name"] == "Nova"
    assert body["onboarding_complete"] is True


def test_legacy_register_and_login_routes_are_gone(client):
    assert client.post("/api/v1/auth/register", json={}).status_code == 404
    assert client.post("/api/v1/auth/login", data={}).status_code == 404
```

- [ ] **Step 2: Run the tests to verify they fail (before Tasks 2-4, they'd fail on import; run now to confirm they pass instead, since Tasks 2-4 are already done at this point in the plan)**

Run: `cd backend && python -m pytest tests/test_auth.py -v`
Expected: all 4 tests PASS (Tasks 2-4 already implemented the code these tests exercise).

- [ ] **Step 3: Commit**

```bash
git add backend/tests/
git commit -m "test(backend): cover GET/PUT /api/v1/auth/me and confirm legacy routes are gone"
```

---

## Task 6: Add the Supabase client to mobile

**Files:**
- Modify: `mobile/package.json`
- Create: `mobile/src/lib/supabase.ts`
- Modify: `mobile/.env`
- Modify: `mobile/.env.example`

**Interfaces:**
- Produces: `supabase` client exported from `@/lib/supabase`. Task 7 imports it as `import { supabase } from "@/lib/supabase"`.

- [ ] **Step 1: Add dependencies**

In `mobile/package.json`, add to `"dependencies"`:

```json
    "@supabase/supabase-js": "^2.45.4",
    "react-native-url-polyfill": "^2.0.0",
```

(Keep alphabetical order among the existing dependency keys.)

- [ ] **Step 2: Install**

Run: `cd mobile && pnpm install`
Expected: install succeeds, `pnpm-lock.yaml` updates.

- [ ] **Step 3: Add the Supabase env vars**

Append to `mobile/.env`:
```
EXPO_PUBLIC_SUPABASE_URL=https://eixnacajmchafxkbtmnr.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVpeG5hY2FqbWNoYWZ4a2J0bW5yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU4NDk1NTksImV4cCI6MjA3MTQyNTU1OX0.dLRdQXKI-VIhXu26y7Uld6oCmr6Zxx-EBOCxp7U2h2g
```

Append to `mobile/.env.example`:
```
EXPO_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

- [ ] **Step 4: Create the client**

`mobile/src/lib/supabase.ts`:
```typescript
import "react-native-url-polyfill/auto";
import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL;
const supabaseAnonKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error("Missing EXPO_PUBLIC_SUPABASE_URL or EXPO_PUBLIC_SUPABASE_ANON_KEY.");
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: false,
    autoRefreshToken: true,
    detectSessionInUrl: false
  }
});
```

- [ ] **Step 5: Typecheck**

Run: `cd mobile && pnpm run typecheck`
Expected: no new errors.

- [ ] **Step 6: Commit**

```bash
git add mobile/package.json mobile/pnpm-lock.yaml mobile/src/lib/supabase.ts mobile/.env.example
git commit -m "feat(mobile): add Supabase client"
```

(`mobile/.env` is gitignored — it won't be included in the commit; that's expected.)

---

## Task 7: Rewrite the mobile auth store for real Supabase sessions

**Files:**
- Modify: `mobile/src/store/auth.ts` (full rewrite)
- Modify: `mobile/app/onboarding.tsx:26-27` (remove the now-gone `displayName` read)

**Interfaces:**
- Consumes: `supabase` from `@/lib/supabase` (Task 6).
- Produces: `useAuthStore` state shape `{ token: string | null; onboardingComplete: boolean; hydrated: boolean; authError: string | null }` and actions `hydrate(): Promise<void>`, `signUp(email: string, password: string): Promise<void>`, `signIn(email: string, password: string): Promise<void>`, `signOut(): Promise<void>`, `completeOnboarding(): Promise<void>`. Task 9 (sign-in screen) calls `signUp`/`signIn`; Tasks in later phases and the existing `index.tsx`/`add-item.tsx`/`item/[id].tsx`/`(tabs)/_layout.tsx` continue reading `state.token` unchanged. **Note:** the previous `displayName` field is removed — no other file reads it except `onboarding.tsx` (fixed in Step 3 below).

- [ ] **Step 1: Replace `mobile/src/store/auth.ts`**

```typescript
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
      throw error;
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
```

- [ ] **Step 2: Fix `mobile/app/onboarding.tsx`**

Change line 27 from:
```typescript
  const storedName = useAuthStore((state) => state.displayName) ?? "";
```
to:
```typescript
  const storedName = "";
```

- [ ] **Step 3: Typecheck**

Run: `cd mobile && pnpm run typecheck`
Expected: no errors referencing `displayName` or the old `signIn(displayName: string)` signature (the sign-in screen itself is fixed in Task 9 — until then, expect one typecheck error in `sign-in.tsx`, which is resolved by Task 9).

- [ ] **Step 4: Commit**

```bash
git add mobile/src/store/auth.ts mobile/app/onboarding.tsx
git commit -m "feat(mobile): back the auth store with real Supabase sessions"
```

---

## Task 8: Jest coverage for the auth store

**Files:**
- Create: `mobile/src/store/auth.test.ts`

**Interfaces:**
- Consumes: `useAuthStore` (Task 7), mocks `@/lib/supabase` and `expo-secure-store`.

- [ ] **Step 1: Write the test**

`mobile/src/store/auth.test.ts`:
```typescript
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
```

- [ ] **Step 2: Run the test**

Run: `cd mobile && pnpm test src/store/auth.test.ts`
Expected: both tests PASS.

- [ ] **Step 3: Commit**

```bash
git add mobile/src/store/auth.test.ts
git commit -m "test(mobile): cover sign-in success/failure in the auth store"
```

---

## Task 9: Rewrite the sign-in screen for email/password

**Files:**
- Modify: `mobile/app/(auth)/sign-in.tsx` (full rewrite)

**Interfaces:**
- Consumes: `useAuthStore().signIn`, `useAuthStore().signUp` (Task 7).

- [ ] **Step 1: Replace `mobile/app/(auth)/sign-in.tsx`**

```typescript
import { useState } from "react";
import { KeyboardAvoidingView, Pressable, StyleSheet, TextInput, View } from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { router } from "expo-router";
import { AppText, Display, Eyebrow } from "@/components/AppText";
import { Button } from "@/components/Button";
import { Reveal } from "@/components/motion";
import { Screen } from "@/components/Screen";
import { useAuthStore } from "@/store/auth";
import { colors, gradients, radius, shadows, spacing } from "@/theme";

export default function SignIn() {
  const [mode, setMode] = useState<"sign-in" | "sign-up">("sign-in");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const signIn = useAuthStore((state) => state.signIn);
  const signUp = useAuthStore((state) => state.signUp);

  const ready = email.trim().length > 3 && password.length >= 6;

  async function submit() {
    if (!ready || busy) return;
    setBusy(true);
    setError(null);
    try {
      if (mode === "sign-up") await signUp(email, password);
      else await signIn(email, password);
      router.replace("/onboarding");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong. Try again.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <KeyboardAvoidingView behavior={process.env.EXPO_OS === "ios" ? "padding" : undefined} style={styles.flex}>
      <Screen bottomInset={false} contentStyle={styles.content}>
        <Reveal>
          <View style={styles.brandRow}>
            <View style={styles.mark}><View style={styles.markInset} /></View>
            <AppText style={styles.wordmark}>FitSync</AppText>
            <View style={styles.badge}><AppText style={styles.badgeText}>PRIVATE BETA</AppText></View>
          </View>
        </Reveal>

        <Reveal delay={70}>
          <View style={styles.hero}>
            <Eyebrow>Your wardrobe, remixed</Eyebrow>
            <Display>A smarter closet starts with what you own.</Display>
            <AppText style={styles.subtitle}>Catalog real pieces, build weather-aware looks, and save the combinations that feel like you.</AppText>
          </View>
        </Reveal>

        <Reveal delay={140}>
          <View style={styles.preview}>
            <View style={[styles.previewCard, styles.previewBack]} />
            <LinearGradient colors={gradients.plum} style={[styles.previewCard, styles.previewMiddle]} />
            <LinearGradient colors={gradients.rose} style={[styles.previewCard, styles.previewFront]}>
              <Eyebrow style={styles.previewEyebrow}>Today's edit</Eyebrow>
              <AppText style={styles.previewTitle}>Dinner, but effortless.</AppText>
              <View style={styles.previewRail}>
                <View style={[styles.swatch, { backgroundColor: "#E6D1BD" }]} />
                <View style={[styles.swatch, { backgroundColor: "#25242B" }]} />
                <View style={[styles.swatch, { backgroundColor: "#9A425D" }]} />
              </View>
            </LinearGradient>
          </View>
        </Reveal>

        <Reveal delay={210}>
          <View style={styles.form}>
            <View style={styles.modeRow}>
              <ModeTab label="Sign in" active={mode === "sign-in"} onPress={() => setMode("sign-in")} />
              <ModeTab label="Create account" active={mode === "sign-up"} onPress={() => setMode("sign-up")} />
            </View>
            <AppText style={styles.label}>Email</AppText>
            <TextInput
              accessibilityLabel="Email"
              autoCapitalize="none"
              autoComplete="email"
              keyboardType="email-address"
              returnKeyType="next"
              value={email}
              onChangeText={setEmail}
              placeholder="you@example.com"
              placeholderTextColor={colors.faint}
              style={styles.input}
            />
            <AppText style={styles.label}>Password</AppText>
            <TextInput
              accessibilityLabel="Password"
              autoCapitalize="none"
              autoComplete={mode === "sign-up" ? "new-password" : "current-password"}
              secureTextEntry
              returnKeyType="done"
              value={password}
              onChangeText={setPassword}
              onSubmitEditing={submit}
              placeholder="At least 6 characters"
              placeholderTextColor={colors.faint}
              style={styles.input}
            />
            <Button
              title={busy ? "Opening your closet…" : mode === "sign-up" ? "Create my style space" : "Sign in"}
              disabled={!ready || busy}
              onPress={submit}
            />
            {error ? <AppText selectable style={styles.error}>{error}</AppText> : null}
            <AppText style={styles.privacy}>Your session is secured with Supabase auth and stored only on this device.</AppText>
          </View>
        </Reveal>
      </Screen>
    </KeyboardAvoidingView>
  );
}

function ModeTab({ label, active, onPress }: { label: string; active: boolean; onPress: () => void }) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ selected: active }}
      onPress={onPress}
      style={[modeTabStyles.tab, active && modeTabStyles.tabActive]}
    >
      <AppText style={[modeTabStyles.label, active && modeTabStyles.labelActive]}>{label}</AppText>
    </Pressable>
  );
}

const modeTabStyles = StyleSheet.create({
  tab: { flex: 1, alignItems: "center", justifyContent: "center", paddingVertical: spacing.sm, borderRadius: radius.pill },
  tabActive: { backgroundColor: colors.ink },
  label: { fontWeight: "700", color: colors.faint, fontSize: 14 },
  labelActive: { color: colors.white }
});

const styles = StyleSheet.create({
  flex: { flex: 1, backgroundColor: colors.canvas },
  content: { justifyContent: "space-between", paddingBottom: spacing.xxl },
  brandRow: { flexDirection: "row", alignItems: "center", gap: spacing.sm },
  mark: { width: 42, height: 42, borderRadius: 14, backgroundColor: colors.ink, alignItems: "center", justifyContent: "center" },
  markInset: { width: 12, height: 12, borderRadius: 6, backgroundColor: colors.canvas },
  wordmark: { fontSize: 20, fontWeight: "900", flex: 1 },
  badge: { borderRadius: radius.pill, borderWidth: 1, borderColor: colors.strokeStrong, paddingHorizontal: spacing.md, paddingVertical: 6 },
  badgeText: { color: colors.muted, fontSize: 10, lineHeight: 13, fontWeight: "800", letterSpacing: 0.8 },
  hero: { gap: spacing.md },
  subtitle: { color: colors.muted, fontSize: 17, lineHeight: 26 },
  preview: { height: 190, justifyContent: "center", alignItems: "center" },
  previewCard: { position: "absolute", width: "82%", height: 148, borderRadius: radius.xl, borderCurve: "continuous", boxShadow: shadows.card },
  previewBack: { backgroundColor: colors.surfaceMuted, transform: [{ rotate: "-7deg" }, { translateX: -12 }] },
  previewMiddle: { opacity: 0.64, transform: [{ rotate: "7deg" }, { translateX: 14 }] },
  previewFront: { padding: spacing.xl, justifyContent: "flex-end", gap: spacing.sm },
  previewEyebrow: { color: "rgba(255,255,255,0.72)" },
  previewTitle: { color: colors.white, fontSize: 24, lineHeight: 28, fontWeight: "900" },
  previewRail: { flexDirection: "row", gap: spacing.sm },
  swatch: { width: 30, height: 8, borderRadius: radius.pill },
  form: { gap: spacing.md },
  modeRow: { flexDirection: "row", gap: spacing.xs, backgroundColor: colors.surfaceMuted, borderRadius: radius.pill, padding: 4 },
  label: { fontSize: 14, fontWeight: "700", color: colors.inkSoft },
  input: { minHeight: 56, borderRadius: radius.lg, borderCurve: "continuous", borderWidth: 1, borderColor: colors.strokeStrong, backgroundColor: colors.surface, color: colors.ink, paddingHorizontal: spacing.lg, fontSize: 17 },
  error: { color: colors.danger },
  privacy: { color: colors.faint, fontSize: 12, lineHeight: 18, textAlign: "center" }
});
```

- [ ] **Step 2: Typecheck**

Run: `cd mobile && pnpm run typecheck`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add "mobile/app/(auth)/sign-in.tsx"
git commit -m "feat(mobile): add email/password sign-in and sign-up to the sign-in screen"
```

---

## Task 10: Point the mobile API client at `/auth/me`

**Files:**
- Modify: `mobile/src/api/client.ts:93-94`

**Interfaces:**
- Consumes: nothing new. `mobile/src/types/api.ts`'s `Profile` type already matches `backend/`'s `User` model from Task 2 field-for-field (`user_id`, `display_name`, `style_preferences`, `favorite_colors`, `sizes`, `onboarding_complete`, `created_at`, `updated_at`) — no type changes needed.

- [ ] **Step 1: Update the two profile calls**

Change:
```typescript
  profile: () => request<Profile>("/profiles/me"),
  updateProfile: (profile: Partial<Profile>) => request<Profile>("/profiles/me", { method: "PUT", body: JSON.stringify(profile) }),
```
to:
```typescript
  profile: () => request<Profile>("/auth/me"),
  updateProfile: (profile: Partial<Profile>) => request<Profile>("/auth/me", { method: "PUT", body: JSON.stringify(profile) }),
```

- [ ] **Step 2: Typecheck**

Run: `cd mobile && pnpm run typecheck`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add mobile/src/api/client.ts
git commit -m "fix(mobile): point profile requests at /api/v1/auth/me"
```

---

## Task 11: End-to-end verification

**Files:** None — manual verification only.

- [ ] **Step 1: Start the backend**

Run: `cd backend && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000`
Expected: starts without errors, `http://localhost:8000/health` returns `{"status": "healthy", ...}`.

- [ ] **Step 2: Start the mobile app**

Run: `cd mobile && pnpm run start`
Set `EXPO_PUBLIC_API_BASE_URL` in `mobile/.env` to your machine's LAN IP (already set) and open the app in Expo Go or a simulator.

- [ ] **Step 3: Sign up a new account**

In the app: switch to "Create account", enter a real-format email and a 6+ character password, submit.
Expected: no error banner; app navigates to `/onboarding`.

- [ ] **Step 4: Confirm the profile row was created**

Call `mcp__claude_ai_Supabase__execute_sql` with `project_id: "eixnacajmchafxkbtmnr"` and query:
```sql
select user_id, email, onboarding_complete from public.user_profiles order by created_at desc limit 5;
```
Expected: a row matching the email used in Step 3, with `onboarding_complete = false`.

- [ ] **Step 5: Complete onboarding**

In the app: enter a display name, pick at least one style anchor and one color, submit.
Expected: app navigates to `/(tabs)/home` with no error text under the button.

- [ ] **Step 6: Confirm the update persisted**

Re-run the query from Step 4.
Expected: the same row now has `onboarding_complete = true` and the chosen `display_name`.

- [ ] **Step 7: Confirm session persistence**

Force-close the app and reopen it.
Expected: it lands on `/(tabs)/home` directly (no sign-in prompt) — the Supabase session was restored from `expo-secure-store`.

- [ ] **Step 8: Confirm legacy routes are gone**

Run: `curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8000/api/v1/auth/register`
Expected: `404`.
