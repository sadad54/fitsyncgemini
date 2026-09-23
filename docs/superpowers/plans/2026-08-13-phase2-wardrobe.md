# Phase 2 Wardrobe Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the existing, already-built mobile closet screens (browse/search/filter, add with camera/library, edit, delete) work end to end against a real backend: real image upload to Supabase Storage, real AI tagging (Google Vision + Groq, with a resilient fallback), real CRUD against the `clothing_items` table.

**Architecture:** Rebuild `backend/app/services/clothing_service.py` to talk to Supabase directly (via `app.core.database.db.get_client()`, the pattern Phase 1 established for auth) instead of the currently-broken `Database` class methods that don't exist. Rewrite the `/api/v1/clothing` endpoints to match, fix the mobile API client's paths to match the backend (same "mobile follows backend" direction as Phase 1), leave the mobile screens/types/query-hooks untouched since they already match this contract.

**Tech Stack:** FastAPI/Python (`backend/`), Supabase (Postgres + Storage), Google Cloud Vision API, Groq API, Expo/React Native/TypeScript (`mobile/`), pytest.

**Spec:** `docs/superpowers/specs/2026-08-13-phase2-wardrobe-design.md`

## Global Constraints

- No paid APIs or services — Google Vision and Groq are both free-tier, already credentialed in `backend/.env` and `backend/secrets/service_account.json`.
- Follow the pattern Phase 1 established: services talk to Supabase directly via `db.get_client()`, not through the dead `Database` class methods.
- The AI enrichment call (Groq) must never hard-fail the whole item creation — wrap in try/except, fall back to Vision-only tagging.
- `mobile/`'s screens, types (`mobile/src/types/api.ts`), and query hooks (`mobile/src/api/queries.ts`) already match the target backend contract exactly — do not modify them. Only `mobile/src/api/client.ts`'s path strings change.
- `GET /clothing/stats` must be registered before `GET /clothing/{item_id}` in the router, or FastAPI will try to match "stats" as an `item_id`.
- Every task must leave the repo in a working, testable state.

---

## Task 1: Migrate the `clothing_items` table schema

**Files:** None (database migration via Supabase MCP tools — project `eixnacajmchafxkbtmnr`).

**Interfaces:**
- Produces: `public.clothing_items` with `user_id` FK → `auth.users(id)` (was `public.users(id)`), column `subcategory` (renamed from `sub_category`), new columns `seasons text[]`, `occasions text[]`, `notes text`. Task 2's Pydantic model and Task 5's service both read/write these exact column names.

- [ ] **Step 1: Apply the migration**

Call `mcp__claude_ai_Supabase__apply_migration` with `project_id: "eixnacajmchafxkbtmnr"`, `name: "fix_clothing_items_schema"`, and this SQL:

```sql
alter table public.clothing_items drop constraint clothing_items_user_id_fkey;

alter table public.clothing_items
  add constraint clothing_items_user_id_fkey
  foreign key (user_id) references auth.users(id) on delete cascade;

alter table public.clothing_items rename column sub_category to subcategory;

alter table public.clothing_items
  add column seasons text[] not null default '{}',
  add column occasions text[] not null default '{}',
  add column notes text;
```

- [ ] **Step 2: Verify**

Call `mcp__claude_ai_Supabase__list_tables` with `project_id: "eixnacajmchafxkbtmnr"`, `schemas: ["public"]`, `verbose: true`. Confirm `public.clothing_items`'s `foreign_key_constraints` shows `target_table: "auth.users"` (not `public.users`), and its `columns` list includes `subcategory` (not `sub_category`), `seasons`, `occasions`, `notes`.

*(No git commit — this is a live database change, not a file change.)*

---

## Task 2: Rewrite the clothing Pydantic models

**Files:**
- Modify: `backend/app/models/clothing.py` (full rewrite)

**Interfaces:**
- Produces: `ClothingCategory` (a `Literal` type, not an enum class), `ClothingItem`, `ClothingItemUpdate`. Tasks 5 and 6 import all three from `app.models.clothing`.

- [ ] **Step 1: Replace the file contents**

```python
from datetime import datetime
from typing import Any, Dict, List, Literal, Optional

from pydantic import BaseModel

ClothingCategory = Literal[
    "tops", "bottoms", "dresses", "outerwear", "footwear", "accessories", "activewear", "unknown"
]


class ClothingItem(BaseModel):
    id: str
    user_id: str
    name: str
    image_url: Optional[str] = None
    category: ClothingCategory
    subcategory: Optional[str] = None
    colors: List[str] = []
    tags: List[str] = []
    seasons: List[str] = []
    occasions: List[str] = []
    brand: Optional[str] = None
    notes: Optional[str] = None
    analysis: Dict[str, Any] = {}
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ClothingItemUpdate(BaseModel):
    name: Optional[str] = None
    image_url: Optional[str] = None
    category: Optional[ClothingCategory] = None
    subcategory: Optional[str] = None
    colors: Optional[List[str]] = None
    tags: Optional[List[str]] = None
    seasons: Optional[List[str]] = None
    occasions: Optional[List[str]] = None
    brand: Optional[str] = None
    notes: Optional[str] = None
```

- [ ] **Step 2: Confirm nothing references the removed enum class**

Run: `grep -rn "ClothingItemBase\|ClothingItemCreate" backend/app --include=*.py`
Expected: no matches (nothing outside this file used them).

- [ ] **Step 3: Verify the module imports cleanly**

Run: `cd backend && PYTHONIOENCODING=utf-8 venv/Scripts/python.exe -c "import app.models.clothing; print('OK')"`
Expected: `OK`

- [ ] **Step 4: Commit**

```bash
git add backend/app/models/clothing.py
git commit -m "refactor(backend): align ClothingItem models with mobile's category taxonomy"
```

---

## Task 3: Fix image upload utilities and remove the redundant Supabase client

**Files:**
- Modify: `backend/app/utils/image_utils.py` (full rewrite)
- Delete: `backend/app/utils/supabase_client.py`

**Interfaces:**
- Produces: `process_and_upload_image(image_bytes: bytes, user_id: str) -> Tuple[str, str]` (returns `(public_url, storage_path)`), uploading to the real `"clothing-items"` bucket via `app.core.database.db.get_client()`. Task 5's service calls this by this exact name/signature.

- [ ] **Step 1: Confirm nothing else imports the file being deleted**

Run: `grep -rn "utils.supabase_client\|utils import supabase_client" backend/app --include=*.py`
Expected: only `backend/app/utils/image_utils.py` (the file this task is about to fix).

- [ ] **Step 2: Replace `image_utils.py`**

```python
import uuid
from typing import Tuple

import cv2
import numpy as np

from app.core.database import db

BUCKET = "clothing-items"


def process_image(image_bytes: bytes, resize_dim: Tuple[int, int] = (512, 512)) -> bytes:
    """Resize an image and return the re-encoded JPEG bytes."""
    try:
        nparr = np.frombuffer(image_bytes, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if image is None:
            raise ValueError("OpenCV failed to decode image. Invalid image format.")

        resized = cv2.resize(image, resize_dim)

        success, encoded_image = cv2.imencode(".jpg", resized)
        if not success:
            raise ValueError("Failed to encode image to JPEG.")

        return encoded_image.tobytes()

    except Exception as e:
        raise RuntimeError(f"Image processing error: {str(e)}")


def upload_to_supabase(image_bytes: bytes, user_id: str) -> Tuple[str, str]:
    """Upload processed image bytes to Supabase storage and return (public_url, image_path)."""
    try:
        file_id = uuid.uuid4().hex
        image_path = f"{user_id}/{file_id}.jpg"

        client = db.get_client()
        client.storage.from_(BUCKET).upload(
            path=image_path,
            file=image_bytes,
            file_options={"content-type": "image/jpeg"},
        )

        public_url = client.storage.from_(BUCKET).get_public_url(image_path)
        return public_url, image_path

    except Exception as e:
        raise RuntimeError(f"Supabase upload error: {str(e)}")


def process_and_upload_image(image_bytes: bytes, user_id: str) -> Tuple[str, str]:
    """Full pipeline: resize/process the image, then upload it. Returns (public_url, image_path)."""
    try:
        processed_image = process_image(image_bytes)
        return upload_to_supabase(processed_image, user_id)
    except Exception as e:
        raise RuntimeError(f"process_and_upload_image failed: {str(e)}")
```

- [ ] **Step 3: Delete the redundant client module**

```bash
git rm backend/app/utils/supabase_client.py
```

- [ ] **Step 4: Verify the module imports cleanly**

Run: `cd backend && PYTHONIOENCODING=utf-8 venv/Scripts/python.exe -c "import app.utils.image_utils; print('OK')"`
Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add backend/app/utils/image_utils.py backend/app/utils/supabase_client.py
git commit -m "fix(backend): upload clothing photos to the real clothing-items bucket"
```

---

## Task 4: Rewrite the clothing service (CRUD + AI tagging with fallback)

**Files:**
- Modify: `backend/app/core/config.py` (add one missing setting — `google_vision.py` already references `settings.GOOGLE_VISION_RATE_LIMIT`, which doesn't exist on `Settings`, so any call into the Vision client currently raises `AttributeError`)
- Modify: `backend/app/services/clothing_service.py` (full rewrite — the existing 781-line file's wardrobe-compatibility/recommendation logic is dropped entirely, not preserved; it called nonexistent `Database` methods and is out of this phase's scope per the spec)

**Interfaces:**
- Consumes: `ClothingItem` (Task 2), `process_and_upload_image` (Task 3), `db.get_client()` (`app.core.database`), `google_vision_client.analyze_clothing_item(image_bytes: bytes, user_id: str) -> dict` (unchanged, already correct), `groq_client.analyze_style_and_outfit(image_bytes: bytes, user_preferences: dict, user_id: str) -> dict` (unchanged; may raise — must be caught).
- Produces: a `clothing_service` singleton with `create_clothing_item(user_id, name, image_bytes, category=None, brand=None, notes=None) -> ClothingItem`, `list_clothing_items(user_id, category=None, search=None) -> tuple[list[ClothingItem], int]`, `get_clothing_item(user_id, item_id) -> ClothingItem` (raises `HTTPException(404)` if not found/owned), `update_clothing_item(user_id, item_id, updates: dict) -> ClothingItem` (raises `HTTPException(404)`), `delete_clothing_item(user_id, item_id) -> None` (raises `HTTPException(404)`), `get_stats(user_id) -> dict` (keys `total_items`, `by_category`, `missing_essentials`). Task 6 imports `clothing_service` and calls exactly these methods.

- [ ] **Step 1: Add the missing config field**

In `backend/app/core/config.py`, add this line inside the `Settings` class, near the other `GOOGLE_PLACES_RATE_LIMIT`/`OPENWEATHER_RATE_LIMIT`-style fields:

```python
    GOOGLE_VISION_RATE_LIMIT: int = int(os.getenv("GOOGLE_VISION_RATE_LIMIT", "30"))
```

- [ ] **Step 2: Replace `clothing_service.py`**

```python
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple

from fastapi import HTTPException, status

from app.core.database import db
from app.external_apis.google_vision import google_vision_client
from app.external_apis.groq_client import groq_client
from app.models.clothing import ClothingItem
from app.utils.image_utils import process_and_upload_image

CORE_CATEGORIES = ["tops", "bottoms", "footwear", "outerwear"]


def _to_clothing_item(row: Dict[str, Any]) -> ClothingItem:
    return ClothingItem(
        id=row["id"],
        user_id=row["user_id"],
        name=row["name"],
        image_url=row.get("image_url"),
        category=row.get("category") or "unknown",
        subcategory=row.get("subcategory"),
        colors=row.get("colors") or [],
        tags=row.get("tags") or [],
        seasons=row.get("seasons") or [],
        occasions=row.get("occasions") or [],
        brand=row.get("brand"),
        notes=row.get("notes"),
        analysis=row.get("ml_analysis") or {},
        created_at=row["created_at"],
        updated_at=row["updated_at"],
    )


class ClothingService:
    async def create_clothing_item(
        self,
        user_id: str,
        name: str,
        image_bytes: bytes,
        category: Optional[str] = None,
        brand: Optional[str] = None,
        notes: Optional[str] = None,
    ) -> ClothingItem:
        image_url, _ = process_and_upload_image(image_bytes, user_id)

        vision_result = await google_vision_client.analyze_clothing_item(image_bytes, user_id)

        analysis: Dict[str, Any] = {"vision": vision_result}
        tags: List[str] = list(vision_result.get("detected_labels") or [])

        try:
            groq_result = await groq_client.analyze_style_and_outfit(image_bytes, {}, user_id=user_id)
            analysis["groq"] = groq_result
            tags.extend(groq_result.get("occasion_recommendations") or [])
        except Exception:
            analysis["groq"] = {"success": False, "note": "style analysis unavailable"}

        now = datetime.now(timezone.utc).isoformat()
        row = {
            "user_id": user_id,
            "name": name,
            "image_url": image_url,
            "category": category or vision_result.get("category") or "unknown",
            "subcategory": vision_result.get("sub_category"),
            "colors": vision_result.get("colors") or [],
            "tags": tags,
            "seasons": [],
            "occasions": [],
            "brand": brand,
            "notes": notes,
            "ml_confidence": vision_result.get("confidence", 0.0),
            "ml_analysis": analysis,
            "created_at": now,
            "updated_at": now,
        }
        result = db.get_client().table("clothing_items").insert(row).execute()
        return _to_clothing_item(result.data[0])

    async def list_clothing_items(
        self, user_id: str, category: Optional[str] = None, search: Optional[str] = None
    ) -> Tuple[List[ClothingItem], int]:
        query = db.get_client().table("clothing_items").select("*").eq("user_id", user_id)
        if category:
            query = query.eq("category", category)
        if search:
            query = query.ilike("name", f"%{search}%")
        result = query.order("created_at", desc=True).execute()
        items = [_to_clothing_item(row) for row in result.data]
        return items, len(items)

    async def get_clothing_item(self, user_id: str, item_id: str) -> ClothingItem:
        result = (
            db.get_client()
            .table("clothing_items")
            .select("*")
            .eq("id", item_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not result.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Clothing item not found")
        return _to_clothing_item(result.data[0])

    async def update_clothing_item(self, user_id: str, item_id: str, updates: Dict[str, Any]) -> ClothingItem:
        updates = dict(updates)
        updates["updated_at"] = datetime.now(timezone.utc).isoformat()
        result = (
            db.get_client()
            .table("clothing_items")
            .update(updates)
            .eq("id", item_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not result.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Clothing item not found")
        return _to_clothing_item(result.data[0])

    async def delete_clothing_item(self, user_id: str, item_id: str) -> None:
        result = (
            db.get_client()
            .table("clothing_items")
            .delete()
            .eq("id", item_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not result.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Clothing item not found")

    async def get_stats(self, user_id: str) -> Dict[str, Any]:
        result = db.get_client().table("clothing_items").select("category").eq("user_id", user_id).execute()
        rows = result.data or []
        by_category: Dict[str, int] = {}
        for row in rows:
            cat = row.get("category") or "unknown"
            by_category[cat] = by_category.get(cat, 0) + 1
        missing_essentials = [cat for cat in CORE_CATEGORIES if by_category.get(cat, 0) == 0]
        return {
            "total_items": len(rows),
            "by_category": by_category,
            "missing_essentials": missing_essentials,
        }


clothing_service = ClothingService()
```

Note: `uuid` is imported but unused directly in this file (it's used inside `image_utils.py`) — remove the unused `import uuid` line from the top of this file if your editor/linter flags it; it's harmless either way but keep the file clean.

- [ ] **Step 3: Verify the module imports cleanly**

Run: `cd backend && PYTHONIOENCODING=utf-8 venv/Scripts/python.exe -c "import app.services.clothing_service; print('OK')"`
Expected: `OK`

- [ ] **Step 4: Commit**

```bash
git add backend/app/core/config.py backend/app/services/clothing_service.py
git commit -m "refactor(backend): rebuild clothing service against Supabase directly, with Groq fallback"
```

---

## Task 5: Rewrite the clothing endpoints

**Files:**
- Modify: `backend/app/api/endpoints/v1/clothing.py` (full rewrite)

**Interfaces:**
- Consumes: `ClothingItem`, `ClothingItemUpdate` (Task 2), `clothing_service` (Task 4), `get_current_user`, `validate_image_file` (`app.api.dependencies`, unchanged), `User` (`app.models.user`, unchanged from Phase 1).
- Produces: `POST /`, `GET /stats`, `GET /`, `GET /{item_id}`, `PUT /{item_id}`, `DELETE /{item_id}` under the `/api/v1/clothing` prefix (already wired in `app/main.py` — no change needed there). No other routes remain in this file.

- [ ] **Step 1: Replace the file contents**

```python
from typing import Optional

from fastapi import APIRouter, Depends, File, Form, UploadFile

from app.api.dependencies import get_current_user, validate_image_file
from app.models.clothing import ClothingItem, ClothingItemUpdate
from app.models.user import User
from app.services.clothing_service import clothing_service

router = APIRouter()


@router.post("/", response_model=ClothingItem)
async def create_clothing_item(
    name: str = Form(...),
    category: Optional[str] = Form(None),
    brand: Optional[str] = Form(None),
    notes: Optional[str] = Form(None),
    image: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    await validate_image_file(image)
    image_bytes = await image.read()
    return await clothing_service.create_clothing_item(
        user_id=current_user.user_id,
        name=name,
        image_bytes=image_bytes,
        category=category,
        brand=brand,
        notes=notes,
    )


@router.get("/stats")
async def get_clothing_stats(current_user: User = Depends(get_current_user)):
    return await clothing_service.get_stats(current_user.user_id)


@router.get("/")
async def list_clothing_items(
    category: Optional[str] = None,
    search: Optional[str] = None,
    current_user: User = Depends(get_current_user),
):
    items, total = await clothing_service.list_clothing_items(current_user.user_id, category, search)
    return {"items": items, "total": total}


@router.get("/{item_id}", response_model=ClothingItem)
async def get_clothing_item(item_id: str, current_user: User = Depends(get_current_user)):
    return await clothing_service.get_clothing_item(current_user.user_id, item_id)


@router.put("/{item_id}", response_model=ClothingItem)
async def update_clothing_item(
    item_id: str,
    update_data: ClothingItemUpdate,
    current_user: User = Depends(get_current_user),
):
    updates = update_data.model_dump(exclude_unset=True)
    return await clothing_service.update_clothing_item(current_user.user_id, item_id, updates)


@router.delete("/{item_id}")
async def delete_clothing_item(item_id: str, current_user: User = Depends(get_current_user)):
    await clothing_service.delete_clothing_item(current_user.user_id, item_id)
    return {"deleted": True}
```

- [ ] **Step 2: Verify the full app still imports cleanly**

Run: `cd backend && PYTHONIOENCODING=utf-8 venv/Scripts/python.exe -c "import app.main; print('OK')"`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add backend/app/api/endpoints/v1/clothing.py
git commit -m "refactor(backend): rewrite /api/v1/clothing endpoints against the new service"
```

---

## Task 6: pytest coverage for the clothing endpoints

**Files:**
- Create: `backend/tests/test_clothing.py`

**Interfaces:**
- Consumes: the `client` fixture from `backend/tests/conftest.py` (already exists from Phase 1 — overrides `get_current_user` with a fake `User`, `user_id="00000000-0000-0000-0000-000000000001"`), `ClothingItem` (Task 2), `clothing_service` (Task 4, imported as `app.services.clothing_service` module for monkeypatching).

- [ ] **Step 1: Write the test file**

`backend/tests/test_clothing.py`:
```python
from datetime import datetime, timezone
from io import BytesIO

from fastapi import HTTPException, status

from app.models.clothing import ClothingItem
from app.services import clothing_service as clothing_module

TEST_USER_ID = "00000000-0000-0000-0000-000000000001"


def _sample_item(**overrides):
    now = datetime.now(timezone.utc)
    base = dict(
        id="11111111-1111-1111-1111-111111111111",
        user_id=TEST_USER_ID,
        name="Blue linen shirt",
        image_url="https://example.com/image.jpg",
        category="tops",
        subcategory="casual",
        colors=["blue"],
        tags=["linen"],
        seasons=[],
        occasions=[],
        brand=None,
        notes=None,
        analysis={},
        created_at=now,
        updated_at=now,
    )
    base.update(overrides)
    return ClothingItem(**base)


def test_create_clothing_item_returns_created_item(client, monkeypatch):
    async def fake_create(**kwargs):
        assert kwargs["user_id"] == TEST_USER_ID
        assert kwargs["name"] == "Blue linen shirt"
        return _sample_item()

    monkeypatch.setattr(clothing_module.clothing_service, "create_clothing_item", fake_create)

    response = client.post(
        "/api/v1/clothing/",
        data={"name": "Blue linen shirt"},
        files={"image": ("shirt.jpg", BytesIO(b"fake-image-bytes"), "image/jpeg")},
        headers={"Authorization": "Bearer test-token"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["name"] == "Blue linen shirt"
    assert body["category"] == "tops"


def test_list_clothing_items_returns_items_and_total(client, monkeypatch):
    async def fake_list(user_id, category=None, search=None):
        assert user_id == TEST_USER_ID
        return [_sample_item()], 1

    monkeypatch.setattr(clothing_module.clothing_service, "list_clothing_items", fake_list)

    response = client.get("/api/v1/clothing/", headers={"Authorization": "Bearer test-token"})
    assert response.status_code == 200
    body = response.json()
    assert body["total"] == 1
    assert body["items"][0]["name"] == "Blue linen shirt"


def test_get_clothing_stats_is_not_shadowed_by_the_item_id_route(client, monkeypatch):
    async def fake_stats(user_id):
        assert user_id == TEST_USER_ID
        return {"total_items": 3, "by_category": {"tops": 2, "bottoms": 1}, "missing_essentials": ["footwear", "outerwear"]}

    async def poisoned_get_item(user_id, item_id):
        raise AssertionError(f"GET /stats was routed to get_clothing_item with item_id={item_id!r} instead")

    monkeypatch.setattr(clothing_module.clothing_service, "get_stats", fake_stats)
    monkeypatch.setattr(clothing_module.clothing_service, "get_clothing_item", poisoned_get_item)

    response = client.get("/api/v1/clothing/stats", headers={"Authorization": "Bearer test-token"})
    assert response.status_code == 200
    body = response.json()
    assert body["total_items"] == 3
    assert "footwear" in body["missing_essentials"]


def test_get_clothing_item_not_found_returns_404(client, monkeypatch):
    async def fake_get(user_id, item_id):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Clothing item not found")

    monkeypatch.setattr(clothing_module.clothing_service, "get_clothing_item", fake_get)

    response = client.get("/api/v1/clothing/does-not-exist", headers={"Authorization": "Bearer test-token"})
    assert response.status_code == 404


def test_update_clothing_item_returns_updated_item(client, monkeypatch):
    async def fake_update(user_id, item_id, updates):
        assert updates["name"] == "Updated name"
        return _sample_item(name="Updated name")

    monkeypatch.setattr(clothing_module.clothing_service, "update_clothing_item", fake_update)

    response = client.put(
        "/api/v1/clothing/11111111-1111-1111-1111-111111111111",
        json={"name": "Updated name"},
        headers={"Authorization": "Bearer test-token"},
    )
    assert response.status_code == 200
    assert response.json()["name"] == "Updated name"


def test_delete_clothing_item_returns_deleted_true(client, monkeypatch):
    async def fake_delete(user_id, item_id):
        return None

    monkeypatch.setattr(clothing_module.clothing_service, "delete_clothing_item", fake_delete)

    response = client.delete(
        "/api/v1/clothing/11111111-1111-1111-1111-111111111111",
        headers={"Authorization": "Bearer test-token"},
    )
    assert response.status_code == 200
    assert response.json() == {"deleted": True}


def test_legacy_analyze_and_recommendations_routes_are_gone(client):
    assert client.get("/api/v1/clothing/analyze/compatibility", headers={"Authorization": "Bearer test-token"}).status_code == 404
    assert client.get("/api/v1/clothing/recommendations/smart", headers={"Authorization": "Bearer test-token"}).status_code == 404
```

- [ ] **Step 2: Run the tests**

Run: `cd backend && PYTHONIOENCODING=utf-8 venv/Scripts/python.exe -m pytest tests/test_clothing.py -v`
Expected: all 7 tests PASS.

- [ ] **Step 3: Run the full backend test suite to confirm nothing else broke**

Run: `cd backend && PYTHONIOENCODING=utf-8 venv/Scripts/python.exe -m pytest tests/ -v`
Expected: all tests PASS (4 from Phase 1's `test_auth.py` + 7 new ones = 11 total).

- [ ] **Step 4: Commit**

```bash
git add backend/tests/test_clothing.py
git commit -m "test(backend): cover /api/v1/clothing CRUD, stats route ordering, and removed routes"
```

---

## Task 7: Point the mobile API client at `/clothing`

**Files:**
- Modify: `mobile/src/api/client.ts:100,102,103,113,115,116`

**Interfaces:**
- Consumes: nothing new — `mobile/src/types/api.ts`'s `ClothingItem`/`ClosetStats` types already match the backend `ClothingItem` model (Task 2) and stats shape (Task 4) field-for-field. No type changes needed.

- [ ] **Step 1: Update the six closet-related paths**

In `mobile/src/api/client.ts`, change:
```typescript
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
```
to:
```typescript
  closetItems: (params?: { category?: ClothingCategory | "all"; search?: string }) => {
    const qs = new URLSearchParams();
    if (params?.category && params.category !== "all") qs.set("category", params.category);
    if (params?.search) qs.set("search", params.search);
    const suffix = qs.toString() ? `?${qs}` : "";
    return request<{ items: ClothingItem[]; total: number }>(`/clothing${suffix}`);
  },
  closetItem: (id: string) => request<ClothingItem>(`/clothing/${id}`),
  closetStats: () => request<ClosetStats>("/clothing/stats"),
  addClosetItem: async (input: { name: string; category?: ClothingCategory; imageUri: string; brand?: string; notes?: string }) => {
    const name = input.name.trim();
    const filename = imageName(name, input.imageUri);
    const form = new FormData();
    form.append("name", name);
    if (input.category) form.append("category", input.category);
    if (input.brand?.trim()) form.append("brand", input.brand.trim());
    if (input.notes?.trim()) form.append("notes", input.notes.trim());
    form.append("image", await imagePart(input.imageUri, filename));
    return request<ClothingItem>("/clothing", { method: "POST", body: form });
  },
  updateClosetItem: (id: string, input: Partial<ClothingItem>) => request<ClothingItem>(`/clothing/${id}`, { method: "PUT", body: JSON.stringify(input) }),
  deleteClosetItem: (id: string) => request<{ deleted: boolean }>(`/clothing/${id}`, { method: "DELETE" }),
```

(Note: `closetItems`'s query string still lands on `/clothing?category=...`, which matches Task 5's `GET /` handler's `category`/`search` query params — no backend change needed for the query string shape.)

- [ ] **Step 2: Typecheck**

Run: `cd mobile && npx tsc --noEmit`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add mobile/src/api/client.ts
git commit -m "fix(mobile): point closet requests at /api/v1/clothing"
```

---

## Task 8: End-to-end verification

**Files:** None — manual/automated verification only.

- [ ] **Step 1: Start the backend**

Run: `cd backend && PYTHONIOENCODING=utf-8 venv/Scripts/python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000`
Expected: starts without errors; `http://localhost:8000/health` returns healthy.

- [ ] **Step 2: Confirm the removed routes are gone and stats route ordering works over HTTP (not just TestClient)**

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/api/v1/clothing/analyze/compatibility
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/api/v1/clothing/recommendations/smart
```
Expected: both `404`. Neither path matches any registered route — `/{item_id}` only matches a single path segment, so a two-segment path like `/analyze/compatibility` matches nothing at all, and FastAPI returns 404 before any auth dependency runs.

- [ ] **Step 3: Run the full backend test suite one more time against the running-server-adjacent code state**

Run: `cd backend && PYTHONIOENCODING=utf-8 venv/Scripts/python.exe -m pytest tests/ -v`
Expected: all 11 tests pass.

- [ ] **Step 4: Mobile typecheck and existing test suite**

Run: `cd mobile && npx tsc --noEmit` (expect clean) and `npx jest src/store/auth.test.ts` (expect 2/2 passing — unaffected by this phase's changes, confirms nothing regressed).

- [ ] **Step 5: Manual walkthrough (needs a human — no automated mobile UI driver available)**

Start the mobile app (`cd mobile && pnpm run start`), sign in with an account from Phase 1 (or create one), then:
1. Go to the Closet tab, tap "Add first piece" (or the `+` button).
2. Take or pick a clear photo of a real garment, give it a name, leave category blank (let AI infer it), submit.
3. Confirm it lands in the closet grid within a few seconds with an image, a category chip, and at least one color tag — this proves the Vision pipeline ran and Supabase Storage upload worked.
4. Open the item, confirm its detail screen shows the AI-assigned category/colors/tags, edit its name and save, confirm the change persists after navigating back and re-opening it.
5. Use the category filter chips and the search box on the closet grid; confirm filtering/search narrow the results correctly.
6. Delete the item; confirm it disappears from the grid.
7. Ask me (or check yourself via Supabase) to confirm the `clothing_items` row's `ml_analysis` column has both a `"vision"` key and either a `"groq"` key with real content or `{"success": false, "note": "style analysis unavailable"}` — either is correct proof the fallback path is real, not just theorized.
