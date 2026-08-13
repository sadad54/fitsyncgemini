# Phase 1: Foundation — Auth, Profile, and a Real API Contract

**Status:** Approved for planning
**Date:** 2026-08-13

## Context

FitSync's prior development (via Codex) left the repo in a fragmented state:

- A mature Flutter app (`lib/`, `android/`, `ios/`, etc., ~97 files, MVVM/Riverpod) was deleted from disk but remains intact in git history. **Decision: abandoned** in favor of continuing the Expo/React Native app in `mobile/`.
- Two FastAPI backends exist: `backend/` (tracked, more complete — auth, clothing, outfits, tryon, trends, community, weather, locations routers already wired in `main.py`) and `backend_v2/` (untracked, simpler, bundled YOLO model). **Decision: `backend/` is the backend of record.**
- `mobile/`'s API layer (`client.ts`, `queries.ts`, `types/api.ts`) was originally written against a leaner, different contract (matching `backend_v2`: `/profiles/me`, `/closet/items`, `/outfits/generate`). **Decision: rewrite mobile's API layer to match `backend/`'s existing routes**, rather than reshaping the backend to match mobile.
- `mobile/`'s auth (`store/auth.ts`) is entirely fake/local: `signIn(displayName)` derives a token from a slugified name with no real backend call. `backend/` has two parallel, inconsistent auth systems: a legacy custom-JWT `auth.py` (`/register`, `/login` against a local `users.password_hash` table) and a Supabase-token-based `unified_auth_service` that `dependencies.get_current_user` actually uses. These are disconnected — tokens issued by `auth.py`'s `/login` would not be accepted by any protected route.
- `backend/.env` already has real, working free-tier credentials configured (Supabase, Groq, Hugging Face, Google Vision, OpenWeather, Google Places) from prior work — no new account setup needed for Phase 1.
- `SUPABASE_SETUP.md` (committed, stale) contains a plaintext-looking password (`pass:j9k87HRqK#Gd!32`) pasted in error, and documents a DB schema (`style_archetype`, `quiz_results`, Dart config paths) that belongs to the abandoned Flutter app — not a source of truth for the current schema. **User has deferred scrubbing this; it should still be rotated/removed eventually — flagged, not resolved, by this spec.**
- Existing mobile screens (`app/(auth)/sign-in.tsx`, `app/onboarding.tsx`) are already well-built (editorial design system in `mobile/src/theme.ts`, polished motion/interaction) but wired to the fake auth store and a mismatched profile shape.

## Goal

Make the existing, already-well-designed mobile screens work end-to-end against a real backend: real account creation, real session persistence, real profile data that round-trips through Supabase.

No new screens or features in this phase — it is a wiring/correctness phase.

## Scope

### Backend (`backend/`)

1. Remove `backend/app/api/endpoints/auth.py`'s custom JWT `/register` and `/login` routes (and the now-unused `password_hash` / bcrypt path in `app/core/security.py` if nothing else depends on it). Keep `/me` (GET/PUT) but back it with `unified_auth_service`, not the local `users` table.
2. Extend the Supabase `user_profiles` table (fresh migration — ignore `SUPABASE_SETUP.md`'s stale schema) with the fields the mobile onboarding flow already sends: `display_name`, `style_preferences` (text[]), `favorite_colors` (text[]), `sizes` (jsonb), `onboarding_complete` (bool).
3. Extend `backend/app/models/user.py`'s `User` and `UserUpdate` Pydantic models to include the above fields.
4. `unified_auth_service.create_backend_user_profile` already upserts a profile row on every authenticated request (idempotent, runs per-request) — keep that pattern; widen the fields it reads/writes to include the new ones (all default to empty/false on first creation, populated once onboarding calls `PUT /me`).

### Mobile (`mobile/`)

1. Add `@supabase/supabase-js`. Initialize with `EXPO_PUBLIC_SUPABASE_URL` / `EXPO_PUBLIC_SUPABASE_ANON_KEY` env vars (values already known from `backend/.env`'s `SUPABASE_URL` / `SUPABASE_ANON_KEY`).
2. Replace `useAuthStore`'s fake `signIn(displayName)` with real `supabase.auth.signUp({ email, password })` and `supabase.auth.signInWithPassword({ email, password })`. Store the Supabase session (access token + refresh token) via `expo-secure-store`, not a derived fake token. Add session refresh handling (Supabase JS's `onAuthStateChange` / auto-refresh).
3. Update `app/(auth)/sign-in.tsx` to collect email + password (and add a sign-up mode/toggle or a separate sign-up screen) instead of just a display name.
4. Update `mobile/src/api/client.ts`: point profile calls at `/api/v1/auth/me` (GET/PUT) instead of `/profiles/me`. Attach the real Supabase access token as the Bearer token (already how `request()` works — just needs a real token from the store).
5. Update `mobile/src/types/api.ts`'s `Profile` type to match the extended backend `User` model.
6. `mobile/app/onboarding.tsx` already calls `useUpdateProfile()` with the correct-shaped payload (`display_name`, `style_preferences`, `favorite_colors`, `onboarding_complete`) — no changes needed there beyond the type/endpoint fixes above. Its auth guard (`if (!token) return <Redirect .../>`) needs `token` to reflect a real Supabase session instead of the fake one.

### Explicitly out of scope for Phase 1

- Closet/outfit/try-on/community endpoints and screens (later phases per the agreed roadmap).
- Social/OAuth sign-in (email+password only, per decision).
- Password reset flow.
- Scrubbing the exposed password from `SUPABASE_SETUP.md` git history (deferred by user; still needs doing before any public push).

## Verification

- Sign up a new account through the app; confirm a `user_profiles` row is created in Supabase.
- Force-close and reopen the app; confirm the session persists (no re-login required) via secure-store-backed Supabase session.
- Complete onboarding (name, style anchors, colors); confirm `PUT /api/v1/auth/me` succeeds and the data round-trips — reload the app and confirm `GET /api/v1/auth/me` returns the same values.
- Confirm the legacy `/api/v1/auth/register` and `/login` routes are gone (404) and nothing else in the codebase still calls them.
