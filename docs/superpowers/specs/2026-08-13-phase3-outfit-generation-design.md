# Phase 3: AI Outfit Generation

**Status:** Approved for planning
**Date:** 2026-08-13

## Context

Phases 1 (auth) and 2 (wardrobe) shipped real, working backends behind already-built mobile screens. Phase 3 follows the same shape: `mobile/app/(tabs)/generate.tsx` (occasion picker, weather toggle via `expo-location`, result card with score/explanation/save/favorite/rating) and `mobile/app/(tabs)/saved.tsx` (lookbook, all/favorites filter, rating) are fully built and polished. They call `mobile/src/api/client.ts`'s `generateOutfit`, `outfits(savedOnly)`, `saveOutfit`, `favoriteOutfit`, `feedbackOutfit` — which already target `/outfits/generate`, `/outfits?saved_only=`, `/outfits/{id}/save`, `/outfits/{id}/favorite`, `/outfits/{id}/feedback`. **Unlike Phases 1 and 2, mobile's paths already match the target contract — no mobile path changes are needed this phase.**

The backend's actual `/api/v1/outfits` router and services are, once again, a different and largely non-functional feature:

- `backend/app/api/endpoints/outfits.py` exposes a generic CRUD API (`POST /`, `GET /`, `GET/PUT/DELETE /{id}`, `POST /{id}/share`) built around manually-supplied outfit data. **There is no `/generate` endpoint at all** — the core feature this phase is about doesn't exist yet.
- `backend/app/models/outfit.py`'s `Outfit`/`OutfitCreate`/`OutfitUpdate` models (`name`, `description`, `clothing_items: List[str]`, `is_public`) don't match mobile's `Outfit` type (`item_ids`, `occasion`, `weather_context`, `score`, `explanation`, `saved`, `favorited`) at all.
- `backend/app/services/outfit_service.py` does `self.db = get_db()` in `__init__` without `await`ing it — `get_db()` is an `async def`, so `self.db` is an unawaited coroutine object, not a Supabase client. Every method on this service is broken from construction.
- All endpoint handlers use `current_user.id` — broken since Phase 1 made `get_current_user` return a typed `User` with `.user_id`, not `.id`.
- `backend/app/services/recommendation_service.py` (748 lines) is where actual AI generation logic seems to have been intended, but it calls `db.get_user_profile(user_id)` and `db.get_clothing_items(user_id)` directly on the `Database` class instance — the same nonexistent-method bug Phase 2 found and fixed in the old `clothing_service.py`. Not preserved; dropped, same as Phase 2's approach to non-functional legacy code.
- The weather integration this would lean on is itself broken: `WeatherService.get_current_weather(lat, lon)` calls `WeatherClient.get_current_weather(lat, lon, user_id)` — missing the required third argument, a guaranteed `TypeError`. `WeatherClient` also holds its own raw `redis.asyncio` client (`self.redis = redis.from_url(...)`) with no fallback if Redis isn't running (unlike `app/core/cache.py`'s `Cache` class, which fails soft). The existing `/api/v1/weather/current` endpoint only survives this by wrapping the whole chain in a blanket try/except at the route level and returning mock data on failure.
- The live `outfits` table (9 rows — likely demo/seed data, to be confirmed and handled the same way Phase 2 handled `clothing_items`' 25 seed rows) has the same wrong-FK issue: `user_id` references `public.users(id)` instead of `auth.users(id)`. Columns are also named differently from what mobile needs (`ai_score` vs `score`, `is_favorite` vs `favorited`) and missing `saved`, `explanation`, `weather_context` entirely.

## Decision: AI picks nothing, AI describes what rules already picked

Two approaches were considered for outfit selection:

**A. Full AI-driven selection** — send the whole wardrobe to Groq, ask it to return chosen item IDs as JSON. Rejected as the primary path: the LLM could hallucinate item IDs, pick the wrong count, or return malformed JSON — all of which require the same fallback path anyway, just as an exception case instead of the normal case.

**B. Rule-based selection + AI explanation (chosen)** — deterministic logic picks real, owned items; Groq is called only to write the natural-language explanation for a selection that's already valid. Groq failing degrades explanation quality, never outfit validity — same resilience shape as Phase 2's Vision+Groq fallback.

## Scope

### Database migration

1. Fix `outfits`' FK (after confirming and clearing the 9 existing rows are demo data, same process as Phase 2's `clothing_items`): drop and recreate `outfits_user_id_fkey` to reference `auth.users(id)`.
2. `ALTER TABLE outfits RENAME COLUMN ai_score TO score;`
3. `ALTER TABLE outfits RENAME COLUMN is_favorite TO favorited;`
4. Add columns: `saved boolean NOT NULL DEFAULT false`, `explanation text NOT NULL DEFAULT ''`, `weather_context jsonb`, `feedback_rating integer`, `feedback_reason text`.
5. Leave `image_url`, `style_analysis`, `wear_count`, `last_worn` in place (unused by this phase's API surface, harmless — same treatment as Phase 2's unused `price`/`purchase_location`/`purchase_date`).

### Backend models (`app/models/outfit.py`, full rewrite)

- Drop `OutfitBase`, `OutfitCreate`, `OutfitUpdate` entirely (nothing in mobile's contract needs a generic outfit-update shape — the only mutations are save/favorite/feedback, each its own small endpoint).
- `Outfit`: `id: str`, `user_id: str`, `name: str`, `item_ids: List[str]`, `occasion: str`, `weather_context: Optional[Dict[str, Any]]`, `score: float`, `explanation: str`, `saved: bool`, `favorited: bool`, `created_at: datetime`, `updated_at: datetime` — matches `mobile/src/types/api.ts`'s `Outfit` field-for-field.
- `GenerateOutfitRequest`: `occasion: str`, `use_weather: bool = False`, `latitude: Optional[float] = None`, `longitude: Optional[float] = None` — matches mobile's `generateOutfit` input.
- `OutfitFeedbackRequest`: `rating: int`, `reason: Optional[str] = None`.

### Backend service (`app/services/outfit_service.py`, full rewrite — `recommendation_service.py` is deleted, not preserved)

- `generate_outfit(user_id, occasion, use_weather=False, latitude=None, longitude=None) -> Outfit`:
  1. Fetch wardrobe via `clothing_service.list_clothing_items(user_id)` (reuse Phase 2's service directly — no duplicate wardrobe-fetching logic).
  2. If `use_weather` and coordinates given, fetch weather via a new small, self-contained helper (see below); wrap in try/except — failure just means no weather bonus/outerwear logic, not a failed generation.
  3. Rule-based selection: for each of `tops`, `bottoms`, `footwear`, pick the item in that category with the highest tag-overlap against a small occasion→synonym map (`casual`→["casual","everyday"], `work`→["work","formal","business"], `date`→["date","evening","chic"], `workout`→["athletic","sport","activewear"], `travel`→["travel","comfortable","casual"], `dinner`→["dinner","evening","formal"]), ties broken by newest `created_at`. If weather temperature < 15°C, also try to fill `outerwear` the same way. A missing category is simply omitted, not an error. If all three core categories are empty, raise `HTTPException(400, "Add clothing items to your closet first.")` — mobile already surfaces `generate.error.message` directly.
  4. Score: `0.5 + 0.15 * (core categories filled, max 3) + (0.1 if outerwear added) + (0.05 if any selected item's tags matched the occasion synonyms)`, capped at `0.99`.
  5. Attempt a Groq call for the explanation string. On any failure, fall back to a template: `f"A {occasion} look built from {len(item_ids)} pieces already in your closet."`.
  6. Insert the outfit row (`saved=false`, `favorited=false`) and return it.
- `list_outfits(user_id, saved_only=False) -> tuple[list[Outfit], int]`.
- `save_outfit(user_id, outfit_id) -> Outfit` — sets `saved=true`; 404 if not found/owned.
- `favorite_outfit(user_id, outfit_id) -> Outfit` — sets `favorited=true`; 404 if not found/owned.
- `record_feedback(user_id, outfit_id, rating, reason=None) -> None` — writes `feedback_rating`/`feedback_reason` onto the outfit row; 404 if not found/owned.
- All row→model mapping through one small helper, same discipline as Phases 1 and 2.

### Weather helper (new, small, self-contained — not a rewrite of the broken `WeatherClient`/`WeatherService`)

A single function, `get_weather_for_outfit(lat, lon) -> Optional[dict]` with just `{"temperature": float, "condition": str}`, calling OpenWeather's API directly via `httpx` using the already-configured `OPENWEATHER_API_KEY`/`OPENWEATHER_BASE_URL`. No caching layer (YAGNI for this phase's traffic level — this is a low-traffic personal app, not something that needs Redis-backed caching yet). Wrapped so any failure returns `None` rather than raising, matching the "AI/external calls degrade, they don't break the feature" pattern established in Phase 2.

### Backend endpoints (`app/api/endpoints/outfits.py`, full rewrite)

- `POST /generate` — body `GenerateOutfitRequest`, returns `Outfit` directly.
- `GET /` — query param `saved_only: bool = False`, returns `{"outfits": [...], "total": int}`.
- `POST /{outfit_id}/save` — returns `Outfit` directly.
- `POST /{outfit_id}/favorite` — returns `Outfit` directly.
- `POST /{outfit_id}/feedback` — body `OutfitFeedbackRequest`, returns `{"recorded": true}`.
- The old generic `POST /`, `GET /{id}`, `PUT /{id}`, `DELETE /{id}`, `POST /{id}/share` are removed — unused by mobile, out of scope.
- Every handler uses `current_user: User = Depends(get_current_user)` and `current_user.user_id`.

### Mobile

No changes. `mobile/src/api/client.ts`'s outfit calls already target the exact paths this phase builds. `mobile/src/types/api.ts`'s `Outfit` type already matches the new backend model field-for-field.

### Explicitly out of scope for Phase 3

- `activewear`-aware selection for the `workout` occasion (only fills `tops`/`bottoms`/`footwear`/`outerwear` from those exact categories in this first pass — a known, called-out simplification, not a silent gap).
- Weather forecast (multi-day) — only current weather.
- Outfit sharing (the old `/share` endpoint is dropped, not rebuilt — no mobile UI for it).
- Wear-count tracking / "last worn" (columns exist, unused — no UI for them yet).
- Caching weather lookups.

## Verification

- Generate an outfit with an empty closet; confirm a clear error message, not a crash.
- Add a few clothing items across categories (from Phase 2), generate an outfit with weather off; confirm a real outfit with a score and explanation, built only from owned items.
- Generate again with weather on (grant location permission); confirm the result reflects current temperature when it's cold enough to add outerwear (or confirm no outerwear when warm and none needed).
- Save an outfit, confirm it now appears in the Saved tab under "All saved".
- Favorite an outfit, confirm it appears under "Favorites" in Saved.
- Rate an outfit via the star row; confirm the rating persists (check the row's `feedback_rating` in Supabase, or via a repeat fetch if surfaced).
- Temporarily simulate a Groq failure (or note if it fails naturally); confirm the outfit still generates with a template explanation instead of failing.
- Confirm `GET /api/v1/outfits/{id}` (generic single-outfit fetch, old route) returns 404 — it's intentionally removed, not just unused.
