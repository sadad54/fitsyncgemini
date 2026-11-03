<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="brand/logo/flairwise-horizontal-dark.svg">
    <img alt="Flairwise" src="brand/logo/flairwise-horizontal-light.svg" width="360">
  </picture>
</p>

<h3 align="center">An AI stylist for the clothes you already own.</h3>

<p align="center">
  Expo / React Native · FastAPI · Supabase · FashionCLIP · CatVTON virtual try-on
</p>

---

**Flairwise** (formerly *FitSync*) is a full-stack mobile app that turns your real wardrobe into a digital closet. You photograph a clothing item and a local vision model tags its category and colours. The app then builds outfits from what you actually own, using the occasion and today's weather. You can preview a look on a photo of yourself through an asynchronous virtual try-on pipeline running on a remote GPU.

The design principle: **every suggestion traces back to an item you photographed. It's your closet, not a shopping catalogue.**

<!-- Screenshots: add 3–4 phone screenshots here (closet → outfit → try-on result), e.g.
<p align="center">
  <img src="docs/screenshots/closet.png" width="220" />
  <img src="docs/screenshots/outfit.png" width="220" />
  <img src="docs/screenshots/tryon.png" width="220" />
</p>
-->

## At a glance

| | |
|---|---|
| **Scope** | 28 mobile screens (Expo, TypeScript) · 42 REST endpoints (FastAPI) · 3 services: API, try-on queue consumer, GPU worker |
| **Vision tagging** | Zero-shot FashionCLIP over **7 categories → 35 subcategories**, each label scored as an ensemble of **3 prompts**, plus nearest-neighbour mapping to a **17-colour** palette. Runs locally, so tagging costs **$0 per call**. |
| **Try-on reliability** | Durable Postgres job queue (`FOR UPDATE SKIP LOCKED`), request deduplication, per-user quota (**5/day**) and global cap (**100/month**), 240 s provider timeout, and explicit failure of stale jobs (30 min queued / 15 min processing) instead of replaying GPU work. |
| **Provider flexibility** | 1 `TryOnProvider` interface, **3 interchangeable backends** (Kaggle T4 tunnel, Modal serverless T4 that scales to zero, FASHN API), selected by config. |
| **Testing** | **61 pytest tests** across the API, classifier, outfit service, try-on queue and GPU worker contract, plus SQL tests that run the real migration in PGlite. |
| **Delivery** | 70+ commits over 14 months (Aug 2025 – Oct 2026). |

## Features

| | |
|---|---|
| **Digital closet** | Camera or photo-library intake, search and category filters, item detail, editing and confirmed deletion. |
| **Local AI tagging** | Background removal (rembg/U²-Net), then zero-shot category and subcategory classification with FashionCLIP (`patrickjohncyh/fashion-clip`), using an ensemble of prompts per label, plus dominant-colour extraction. It runs on the backend after a one-time model download, with no per-call API cost. |
| **Outfit generation** | Builds a combination from the user's own items for a chosen occasion, optionally using current weather (temperature) from the device location, with a plain-language explanation of the pairing. |
| **Virtual try-on** | Asynchronous, durable GPU job pipeline (details below) with history you can reopen after navigating away or restarting the app. |
| **Saved looks & feedback** | Save and favourite outfits; rate recommendations 1–5. |
| **Profile & onboarding** | Supabase Auth email/password sign-in, style anchors and favourite colours. |
| **Discover** | Community, trends and nearby fashion stores (Google Places). Backend endpoints are built; the mobile screens currently show seed content (see *Status*). |
| **Design system** | Custom brand system shared across iOS and Android, with reduced-motion-aware motion. |

## Architecture

```
┌──────────────────────┐      HTTPS / JSON       ┌─────────────────────────────┐
│  Expo / React Native │ ──────────────────────► │  FastAPI backend            │
│  TypeScript          │                          │  · auth (Supabase JWT)      │
│  expo-router         │ ◄──── 202 + job id ───── │  · closet / outfits / feed  │
│  TanStack Query      │       poll every 3 s     │  · FashionCLIP + rembg      │
│  Zustand, Zod        │                          │  · try-on API + queue       │
└──────────────────────┘                          └─────────────┬───────────────┘
                                                                │ supabase-py
                                     ┌──────────────────────────▼───────────────┐
                                     │  Supabase: Postgres · Auth · Storage      │
                                     │  tryon_jobs table + atomic queue RPCs     │
                                     │  private bucket, 1-hour signed URLs       │
                                     └──────────────────────────┬───────────────┘
                                                                │ claimed by
                                     ┌──────────────────────────▼───────────────┐
                                     │  Try-on consumer (separate process)       │
                                     │  → TryOnProvider: Kaggle tunnel │ Modal │  │
                                     │    FASHN  → GPU worker (CatVTON, FP16)   │
                                     └──────────────────────────────────────────┘
```

### Virtual try-on pipeline

1. **Ownership check.** The backend verifies every selected garment belongs to the signed-in user.
2. **Input hygiene.** Photos are decoded, size-bounded, EXIF-stripped, normalised and snapshotted to a **private** Supabase bucket.
3. **Atomic admission.** A Postgres function deduplicates identical requests, enforces per-user daily and monthly job quotas, and queues the job. The API returns **HTTP 202** with a job id.
4. **Durable processing.** A separate consumer claims jobs and calls the configured GPU provider, so jobs survive API or consumer restarts. Stale or interrupted jobs fail explicitly and are never silently replayed, because a timed-out job may already have used GPU time.
5. **Polling & history.** The app polls the job until it completes or fails. Results are served through one-hour signed URLs, refreshed on reopen, and expire after seven days.
6. **Provider boundary.** A single `TryOnProvider.generate()` interface with Kaggle-tunnel, Modal and FASHN implementations, chosen by config. The mobile app only ever sees Flairwise job ids.

**Model scope.** CatVTON (`mix`) in FP16 at 768×1024, with DensePose + SCHP masking so dresses use a full-body mask. The app supports one dress, one top or outer layer, one bottom, or bottom then top. Shoes, accessories and ambiguous items are rejected explicitly rather than rendered wrongly. A separate notebook compares CatVTON with IDM-VTON on the same prepared inputs. The app shows **no made-up fit or confidence score**.

Full design and runbook: [`docs/VIRTUAL_TRYON.md`](docs/VIRTUAL_TRYON.md).

## Tech stack

- **Mobile:** Expo (React Native, TypeScript), expo-router, TanStack Query, Zustand, React Hook Form + Zod, Reanimated, Supabase JS, expo-location, expo-image-picker, expo-secure-store
- **Backend:** FastAPI, Pydantic v2, supabase-py, httpx, Loguru; Docker / docker-compose
- **ML:** PyTorch + Hugging Face Transformers (FashionCLIP), rembg / ONNX Runtime, OpenCV, Pillow; Groq for optional style analysis
- **Try-on GPU worker:** CatVTON with DensePose + SCHP masking, Kaggle notebooks (T4), optional Modal deployment
- **Data:** Supabase Postgres (SQL migrations, queue RPCs), Auth and Storage
- **External APIs:** weather, Google Places

## Repository layout

```
mobile/        Expo app (screens in app/, shared code in src/)
backend/       FastAPI service: app/api, services, ml, tryon (queue, providers, storage, worker), migrations, tests
gpu_worker/    CatVTON pipeline, masking, Modal app, Kaggle notebooks, benchmark harness, tests
brand/         Logo system and app-icon sources
docs/          Try-on design + runbook, app-flow plan, phase specs
```

## Quality and testing

- **Backend (pytest):** auth, closet CRUD and route ordering, clothing classifier, outfit service and routes, try-on routes and compositor. Run from `backend/` with `python -m pytest tests -q`.
- **Try-on queue and GPU contract:** `python -m pytest backend/tryon_tests gpu_worker/tests --confcutdir=backend/tryon_tests -q`.
- **SQL behaviour:** `backend/tryon_tests/queue.mjs` runs the real migration twice in PGlite. It checks deduplication, quotas, owner scoping, job claims, stale-job failure and service-role restrictions.
- **Mobile:** `npm run typecheck` and Jest tests (auth store sign-in success and failure).

## Getting started

**Prerequisites:** Python 3.11+, Node.js + pnpm, a Supabase project, and Expo Go on a phone (or an emulator).

```bash
# Backend
cd backend
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env    # add SUPABASE_URL, SUPABASE keys, weather / Places keys
uvicorn app.main:app --host 0.0.0.0 --port 8000
python -m app.tryon.worker          # second terminal, only needed for try-on
```

```bash
# Mobile
cd mobile
pnpm install
EXPO_PUBLIC_API_BASE_URL=http://<your-LAN-IP>:8000 pnpm start
```

Apply `backend/migrations/` in the Supabase SQL editor before using try-on. Keep the Supabase service-role key on the backend only, never in the Expo app or the GPU worker.

## Status

Flairwise is a **pre-launch prototype**, run today on a physical phone through Expo Go against a local backend.

- **Working:** sign-in, onboarding, closet intake with local AI tagging, outfit generation (with weather), saved looks and ratings, and the asynchronous try-on job flow.
- **In progress:** wiring the Community, Trends and Stores screens to their backend endpoints (they render seed data today); a published quality benchmark for try-on; and store builds (EAS).
- **Licensing:** CatVTON and IDM-VTON weights are CC BY-NC-SA 4.0, so try-on is non-commercial until it is replaced or licensed.

## Author

**Adnan Mashrur Sadad** · [Portfolio](https://portfolio-sadad.vercel.app) · [LinkedIn](https://www.linkedin.com/in/adnan-mashrur-sadad-87a45b237) · [GitHub](https://github.com/sadad54)
