# Phase 2: Wardrobe/Closet — Upload, AI Tagging, Browse, Edit, Delete

**Status:** Approved for planning
**Date:** 2026-08-13

## Context

Phase 1 (Foundation) shipped real Supabase auth end to end. This phase wires the wardrobe/closet feature, whose mobile UI (`mobile/app/(tabs)/closet.tsx`, `mobile/app/add-item.tsx`, `mobile/app/item/[id].tsx`) is already fully built and polished — grid/search/category-filter, camera/library picker with a preview, edit/delete with confirmation. It currently talks to a backend contract (`/closet/items`, `/closet/stats`) that was never implemented — the same pre-Phase-1 mismatch pattern as auth.

The backend's actual `/api/v1/clothing` router and its `clothing_service.py` are largely non-functional scaffolding, discovered during design:

- `clothing_service.py` and `v1/clothing.py` call `db.get_clothing_items()`, `db.create_clothing_item()`, `db.get_clothing_item()`, `db.update_clothing_item()`, `db.delete_clothing_item()`, `db.get_user_profile()` — **none of these methods exist** on `app/core/database.py`'s `Database` class (it only has `connect`/`disconnect`/`get_client`/`get_pool`). Every one of these calls would raise `AttributeError` at runtime.
- All handlers use `current_user["id"]` (dict-subscript access) — broken since Phase 1 made `get_current_user` return a typed `User` object, not a dict.
- `image_utils.py`'s `process_and_upload_image` uploads to a Supabase Storage bucket named `"fitsync"`, which doesn't exist. The live project's actual bucket (confirmed via `list_tables`/SQL on `storage.buckets`) is `"clothing-items"` (public).
- `clothing_service.py` calls `process_and_upload_image(image_data, image_filename)` — the function's real signature is `(image_bytes, user_id)`, so the second argument is semantically wrong even before the bucket-name bug.
- `app/models/clothing.py`'s `ClothingCategory` enum (`TOP`, `BOTTOM`, `DRESS`, `OUTERWEAR`, `SHOES`, `ACCESSORIES`) doesn't match mobile's category taxonomy (`tops`, `bottoms`, `dresses`, `outerwear`, `footwear`, `accessories`, `activewear`, `unknown`) and isn't even referenced by `clothing_service.py`, which just passes through whatever string Vision's categorizer returns.
- Google Vision's `_categorize_clothing` internal logic already independently produces `tops`/`bottoms`/`dresses`/`outerwear`/`footwear`/`accessories`/`unknown` (verified by reading `google_vision.py`) — i.e., it already speaks mobile's dialect, missing only `activewear`. The mismatched Pydantic enum is dead weight, not a real second taxonomy to reconcile.
- The live `clothing_items` table (0 rows) has the same wrong-FK problem Phase 1 found and fixed on `user_profiles`: `user_id` references `public.users(id)` (a legacy, abandoned table) instead of `auth.users(id)`.
- The live table is also missing columns mobile's `ClothingItem` type needs: `seasons`, `occasions`, `notes`. It has `sub_category` (underscore) where mobile expects `subcategory` (no underscore).
- `app/utils/supabase_client.py` is a third, redundant Supabase client instantiation (separate from `unified_auth_service.py`'s and `database.py`'s `Database.get_client()`), all pointed at the same project with the same service-role key.
- Real, working free-tier credentials exist for both Google Vision (service account JSON + API key) and Groq (API key) — an actual AI-tagging pipeline is achievable, not just aspirational.
- `v1/clothing.py` also has two endpoints — `GET /analyze/compatibility` and `GET /recommendations/smart` — that belong conceptually to a later phase (AI Outfit Generation) and that mobile never calls. `clothing_service.py` has several hundred lines of supporting logic for these (`_build_compatibility_matrix`, `_generate_outfit_combinations`, `_analyze_wardrobe_gaps`, etc.) that are equally non-functional (same missing-`db`-method problem) and out of this phase's scope.

## Goal

Make the existing, already-built closet screens work end to end against a real backend: real image upload to Supabase Storage, real AI-assisted tagging (Google Vision + Groq, with a resilient fallback), real CRUD backed by the `clothing_items` table, real stats.

## Decision: rebuild the backend clothing layer directly against Supabase, not through `Database`

Same pattern Phase 1 used for auth: `clothing_service.py` will call the Supabase client directly (reusing the already-lifespan-managed client via `app.core.database.db.get_client()`) rather than routing through the `Database` class's missing methods. This avoids patching a dead abstraction and keeps the codebase's now-established pattern (auth service does this too) consistent. `app/utils/supabase_client.py`'s redundant client is retired; `image_utils.py` is updated to get its client the same way.

## Scope

### Database migration

1. Fix `clothing_items`' FK (0 rows, safe): drop and recreate `clothing_items_user_id_fkey` to reference `auth.users(id)` instead of `public.users(id)`.
2. `ALTER TABLE clothing_items RENAME COLUMN sub_category TO subcategory;`
3. Add columns: `seasons text[] NOT NULL DEFAULT '{}'`, `occasions text[] NOT NULL DEFAULT '{}'`, `notes text`.
4. Leave `price`, `purchase_location`, `purchase_date`, `ml_confidence` in place (harmless, unused by this phase's API surface — not removed, not exposed).

### Backend models (`app/models/clothing.py`, full rewrite)

- Drop the `ClothingCategory` enum and `ClothingItemBase`/`ClothingItemCreate` classes entirely.
- `ClothingCategory = Literal["tops", "bottoms", "dresses", "outerwear", "footwear", "accessories", "activewear", "unknown"]`
- `ClothingItem`: `id: str`, `user_id: str`, `name: str`, `image_url: Optional[str]`, `category: ClothingCategory`, `subcategory: Optional[str]`, `colors: List[str]`, `tags: List[str]`, `seasons: List[str]`, `occasions: List[str]`, `brand: Optional[str]`, `notes: Optional[str]`, `analysis: Dict[str, Any]`, `created_at: datetime`, `updated_at: datetime` — matches `mobile/src/types/api.ts`'s `ClothingItem` field-for-field (mobile has no `email`-style extra field here to worry about, unlike Phase 1's `User`).
- `ClothingItemUpdate`: all of the above except `id`/`user_id`/`created_at`/`updated_at`/`analysis`, all `Optional`.

### Backend service (`app/services/clothing_service.py`, full rewrite — the existing 781-line file's compatibility/recommendation logic is dropped, not preserved, since it was non-functional and is out of scope)

- `create_clothing_item(user_id, name, image_bytes, category, brand, notes) -> ClothingItem`:
  1. Upload image to the real `clothing-items` bucket via `db.get_client().storage.from_("clothing-items").upload(...)`, path `f"{user_id}/{uuid4()}.jpg"`, get its public URL.
  2. Run Google Vision analysis (`google_vision_client.analyze_clothing_item`) → category/subcategory/colors/confidence. If `category` was supplied manually by the user, it wins over Vision's guess; Vision's subcategory/colors are used regardless.
  3. Attempt Groq style analysis (`groq_client.analyze_style_and_outfit`) for extra tags/insights. **Wrap in try/except** — on any failure (deprecated model, rate limit, network), log and continue with Vision-only data. A garment save must never hard-fail because the secondary enrichment call had a bad day.
  4. Insert a row into `clothing_items` via the Supabase client, `analysis` column populated from the combined Vision+Groq (or Vision-only) result.
  5. Return the constructed `ClothingItem`.
- `list_clothing_items(user_id, category=None, search=None) -> tuple[list[ClothingItem], int]`: query with optional `category` filter and `name`/`colors` search (`ilike` on name is sufficient — no full-text search infra needed for this phase).
- `get_clothing_item(user_id, item_id) -> ClothingItem`: 404 if not found or not owned.
- `update_clothing_item(user_id, item_id, updates) -> ClothingItem`: ownership-scoped update, same `.eq("user_id", ...)` pattern Phase 1 established.
- `delete_clothing_item(user_id, item_id) -> None`: ownership-scoped delete; 404 if not found.
- `get_stats(user_id) -> dict`: `total_items` (count), `by_category` (count per category present), `missing_essentials` (a fixed core list — `["tops", "bottoms", "footwear", "outerwear"]` — filtered down to whichever of those have zero items; no speculative scoring logic).
- All row→model mapping happens in one small helper (`_to_clothing_item(row) -> ClothingItem`), same discipline as Phase 1's `unified_auth_service`.

### Backend endpoints (`app/api/endpoints/v1/clothing.py`, full rewrite)

- `POST /` — multipart form (`name: str`, `category: Optional[str]`, `brand: Optional[str]`, `notes: Optional[str]`, `image: UploadFile`), validated via the existing `validate_image_file` dependency, returns the created `ClothingItem` directly (no wrapper).
- `GET /` — query params `category: Optional[str]`, `search: Optional[str]`, returns `{"items": [...], "total": int}`.
- `GET /stats` — **must be declared before `GET /{item_id}`** in the router so FastAPI doesn't match "stats" as an `item_id` path param. Returns `{"total_items": int, "by_category": dict, "missing_essentials": list}`.
- `GET /{item_id}` — returns the `ClothingItem` directly; 404 if not found/not owned.
- `PUT /{item_id}` — body is `ClothingItemUpdate`, returns the updated `ClothingItem` directly.
- `DELETE /{item_id}` — returns `{"deleted": true}`.
- `GET /analyze/compatibility` and `GET /recommendations/smart` are removed from this file (out of scope, non-functional, unused by mobile — belongs to a later AI-outfit phase which will design its own version against real data).
- Every handler uses `current_user: User = Depends(get_current_user)` and `current_user.user_id`, matching Phase 1's pattern.

### Cleanup

- `app/utils/supabase_client.py` deleted; `app/utils/image_utils.py`'s `upload_to_supabase` updated to accept a client (or import `db.get_client()` from `app.core.database`) instead of the deleted module's standalone client, and its call site's bucket name fixed to `"clothing-items"`. `process_and_upload_image`'s call site in the new `clothing_service.py` passes `user_id` correctly (not a filename).

### Mobile (`mobile/src/api/client.ts` only)

- `closetItems` → `GET /clothing` (was `/closet/items`)
- `closetItem` → `GET /clothing/{id}` (was `/closet/items/{id}`)
- `closetStats` → `GET /clothing/stats` (was `/closet/stats`)
- `addClosetItem` → `POST /clothing` (was `/closet/items`)
- `updateClosetItem` → `PUT /clothing/{id}` (was `/closet/items/{id}`)
- `deleteClosetItem` → `DELETE /clothing/{id}` (was `/closet/items/{id}`)
- No changes to `mobile/src/types/api.ts` (already matches the new backend model exactly — verified field-for-field above), no changes to `queries.ts`, `closet.tsx`, `add-item.tsx`, or `item/[id].tsx` — they were already built correctly against this exact contract shape.

### Explicitly out of scope for Phase 2

- Wardrobe compatibility analysis, smart outfit recommendations (Phase 3: AI Outfit Generation).
- `price`/`purchase_location`/`purchase_date` fields (exist in the table, unused — no UI for them yet, not worth wiring for this phase).
- Full-text/fuzzy search (a simple `ilike` on name is sufficient).
- Bulk import/export.

## Verification

- Sign in, add a clothing item with a real photo; confirm it appears in the closet grid with an AI-assigned category and colors within a few seconds.
- Confirm the uploaded image is retrievable (its `image_url` loads in the app).
- Temporarily simulate a Groq failure (or note if it fails naturally) and confirm the item still saves successfully with Vision-only tags — the fallback path must be exercised, not just theorized.
- Filter by category and search by name in the closet grid; confirm results match.
- Edit an item's name/brand/notes/category; confirm changes persist after reload.
- Delete an item; confirm it's gone from the grid and stats update.
- Check `GET /clothing/stats` reflects real counts after a few items exist.
- Confirm `GET /clothing/analyze/compatibility` and `GET /clothing/recommendations/smart` return 404 (routes removed).
