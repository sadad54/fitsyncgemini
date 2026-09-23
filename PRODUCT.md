# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

Note: FitSync ships as a native mobile app (Expo/React Native, targeting iOS and Android via Expo Go and eventually native builds) — not a website. It is recorded as `web` here because the product deliberately runs one unified custom design system on both iOS and Android rather than adapting to native platform conventions (see Brand Commitments); native HIG/Material guidance should not be loaded or applied to this project.

## Stack

Mobile: Expo / React Native (TypeScript), `expo-router` file-based routing, `@tanstack/react-query`, `zustand`.
Backend: FastAPI (Python) + Supabase (Postgres, Auth, Storage) — service code talks to Supabase directly via `supabase-py`, not an ORM.
AI/ML: on-device `fashion-clip` (CLIP fine-tuned on fashion photos) for clothing classification, and a local PIL-based image compositor for virtual try-on — both chosen specifically to avoid paid third-party AI APIs in the core loop (see Capabilities and Constraints).

## Users

Everyday people who want AI-assisted help deciding what to wear from clothes they actually own — not fashion industry professionals, and not shoppers browsing a catalog. Their job: photograph/log their own wardrobe, get outfit suggestions generated from that real closet (optionally weather-aware), preview combinations via virtual try-on, and engage with a style community (challenges, trends, nearby fashion locations) for inspiration and motivation.

## Product Purpose

FitSync turns a user's own physical wardrobe into a digital, AI-queryable closet: photograph clothing items, get them auto-categorized, generate outfit combinations from what's actually owned, see those combinations on a photo of yourself via virtual try-on, and share/discover style within a community layer. Success means users rely on it before getting dressed and keep their digital closet current because doing so pays off in better suggestions.

## Positioning

The mechanism a catalog/shopping app (Pinterest, Stitch Fix, ASOS) can't truthfully copy: FitSync's AI outfit generation and virtual try-on operate on photos of clothes the user actually owns, not a product catalog — the recommendation is "wear item X with item Y from your own closet," not "buy this." That's paired with a technical commitment (see Constraints) to keep the core AI loop running on local/on-device inference rather than metered third-party AI APIs, so the closet-scanning and try-on loop has no per-use cost ceiling pushing the product toward upsells.

## Operating Context

- Adding a wardrobe item: photograph or pick from library → on-device ML suggests category/subcategory/colors → user confirms/edits → saved to their closet.
- Generating an outfit: pick an occasion (optionally with live weather) → backend assembles a combination from the user's own `clothing_items`.
- Virtual try-on: user's photo + selected wardrobe item(s) composited locally (no external try-on API).
- Community: posts, likes, comments, follows, and style challenges scoped to the user's own content and social graph — not a public content feed sourced from brands/retailers.
- Trends: sourced from a backend `fashion_insights` table (editorial/seeded), not live social-media scraping.
- Locations: nearby fashion retail via Google Places, with graceful empty-state fallback (not fabricated results) when the provider is unavailable.
- Primary test/dev device today: a physical phone running Expo Go over LAN against a locally-run FastAPI backend — not yet a published store build.

## Capabilities and Constraints

- The core AI loop (clothing classification, virtual try-on) must keep running on local/on-device inference — no paid vision or try-on API — a deliberate cost and independence constraint, not a temporary placeholder.
- Stack is fixed: Supabase (Postgres/Auth/Storage) backend reached via FastAPI, Expo/React Native mobile client. Not open for reconsideration as part of design work.
- Should stay usable on modest/budget Android hardware, not only flagship devices — a real constraint on animation/asset weight and on-device model cost, not just aspirational.
- Community/Trends/Locations backend endpoints were only just rebuilt against the live Supabase schema this session and are not yet wired to the mobile screens, which currently render from local seed data (`mobile/src/data/discover.ts`) as placeholder content.
- No production build/deploy config yet (no `eas.json`, no App Store/Play Store bundle identifiers) — pre-launch, dev-only distribution today (Expo Go over LAN).

## Brand Commitments

- Name: FitSync.
- Visual identity ("Modernist" system, already implemented): Archivo typeface across all weights; dark palette — ink (`#131211`) ground, bone (`#f3f2f2`) text, signal red (`#ec3013`) accent; zero border radius everywhere; "bands not cards" — full-bleed sections divided by hairline rules instead of floating shadowed cards; a custom geometric icon language (per-corner radius glyphs) instead of a standard icon library; diamond (rotated-square) ratings instead of stars; custom `Toggle`/`ConfirmDialog` components instead of native platform equivalents.
- This system is a deliberate, confirmed brand decision to run identically on iOS and Android rather than adapt to each platform's native conventions (see Platform note above) — not an unfinished default.
- The stale root `README.md` (Flutter/cyan-magenta-violet/Space Grotesk era) does not reflect current brand truth and should not be treated as authoritative; the Modernist system described here is current.

## Evidence on Hand

- No user research, testimonials, or usage data on hand — do not fabricate any in future work.
- Working reference implementation exists for most core flows (wardrobe, outfit generation, virtual try-on, weather-aware suggestions) — treat the current `mobile/` and `backend/` code as the primary source of visual and interaction truth alongside this document.
- A Claude Design reference bundle exists at `design-system/fitsync/` from an earlier import of Modernist screen designs — treat as supplementary visual reference, not yet reconciled with what's actually implemented.

## Product Principles

1. The closet is real, not a catalog — every suggestion traces back to an item the user actually photographed and owns.
2. No metered AI cost gates the core loop — classification and try-on stay local/on-device by design.
3. One brand language everywhere — the Modernist system is not a per-platform default; it's the product's identity on both iOS and Android.
4. Budget-hardware usable — a suggestion engine that only works well on a flagship phone fails the primary user.
5. Ship the honest state — placeholder/seed content (Community/Trends/Locations screens) should read as such until real backend wiring lands, not be dressed up as live data.

## Accessibility & Inclusion

No product-specific accessibility requirement has been established yet beyond ordinary mobile platform baselines (font scaling, tap target sizing, color contrast). Not yet confirmed with the user — treat as an open gap, not a decided scope exclusion.
