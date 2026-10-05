# FitSync — Flow Overhaul Plan

Status: proposal, pre-implementation. Scope: navigation, screen responsibilities and
feature linking. Visual design is the *next* phase; this plan deliberately says nothing
about colour or type beyond hierarchy.

---

## 1. Diagnosis: why the app feels complicated

| Problem | Evidence in today's build | Cost |
|---|---|---|
| The differentiator is hidden | Try-on has no tab. Reachable only via a Home shortcut, a generated outfit, or an item page. | Most users never see the one thing competitors don't have. |
| Two flows for one job | "Style" (generate outfit) and "Try-on" are separate screens with separate histories. Users think "what do I wear and how does it look", not "generate" then "try on". | Extra decisions, duplicated history. |
| Home is a menu | Home ends in a 6-tile "Shortcuts" grid (Add, Closet, Saved, Try-on, Community, Trends). | A grid of equal options = no guidance. |
| Discovery is orphaned | Community, Trends and Stores (8 screens) are reachable only from Home shortcuts. | Invisible features never get used; dead weight for review. |
| Results are split | Saved outfits live in "Looks"; try-on results live in `/tryon/history`. | "Where did that picture go?" |
| Onboarding stops before value | Onboarding collects name / style / colours, then drops the user on an empty Home. | No "aha" in session one → poor D1 retention. |
| Try-on re-asks for a photo every time | Each try-on needs a fresh person photo upload. | Highest-friction step on the highest-value feature. |
| Placeholder data looks real | Community/Trends/Stores render `src/data/discover.ts` seed content. | App Store / Play review risk and trust risk. |

## 2. Positioning the flow must sell

**"See outfits from your own closet on you — before you get dressed."**

Three things competitors don't combine, and the flow should put them in this order:

1. **Your real closet** (not a shopping catalogue) — every suggestion is wearable today.
2. **AI outfit from that closet**, aware of weather and occasion.
3. **Try it on yourself** in one tap.

Rule for every screen: the next step toward "see it on me" is always the primary button.

## 3. New information architecture

### Tabs: 4 tabs + a centre action

```
 Today     Closet     [ ✦ Style me ]     Looks     Discover
```

| Tab | Replaces | Job |
|---|---|---|
| **Today** | Home | Today's outfit, ready to wear and ready to try on. One decision, not a menu. |
| **Closet** | Closet | Your items. Every item can be styled or tried on from here. |
| **✦ Style me** (raised centre button, opens a full-screen flow) | Style + Try-on | The core loop: occasion → outfit → see it on me → save. |
| **Looks** | Looks + Try-on history | Everything you've liked, with try-on images attached. |
| **Discover** | Community, Trends, Stores (from Home shortcuts) | Inspiration and social. |

**Profile ("You") leaves the tab bar.** It becomes an avatar button in the top-right of Today
(and Looks). Settings are visited rarely; they shouldn't cost a permanent tab.

### Global elements

- **Avatar (top-right)** → Profile & settings.
- **Getting-started checklist** on Today until complete (see §5).
- **Try-on credits pill** on try-on surfaces once monetised (see §7).

## 4. The core loop (the 30-second path)

```
Today ──"Try it on"──▶ Try-on result ──Save──▶ Looks
  │                         ▲
  └─"Style something else"─▶ Style me: occasion ▶ outfit ▶ "See it on me"
Closet item ──"Style around this" / "Try on"──┘
```

Every entry point converges on **one try-on result screen** and **one Looks library**.

## 5. Onboarding & activation (first session)

Goal: the user sees *their own clothes on themselves* within the first session.
Activation metric = first completed try-on using their own item and their own photo.

| Step | Screen | Notes |
|---|---|---|
| 1 | **Welcome** (1 screen, not a carousel) | One sentence + one visual: a before/after try-on. CTA "Get started". |
| 2 | **Sign in / sign up** | Moved *after* the welcome so people know why they're signing up. Apple + Google sign-in (Apple is required on iOS if any social login exists). |
| 3 | **Style basics** | Existing name / style energy / colours, made skippable. Name can come from the auth provider. |
| 4 | **Add 3 pieces** | Camera-first, batch capture: snap, auto-tag, next. Progress "1 of 3". Tagging review happens in a single list at the end, not per photo. Skippable to "Add later" but nudged. |
| 5 | **Your fit photo** | Take or pick one full-body photo, stored privately as the default try-on photo. Clear consent copy + delete anytime in Profile. |
| 6 | **First look** | Auto-generate an outfit from the 3 pieces and immediately run the try-on. Show progress honestly (~30-60 s). Result → "Save to Looks". |

Anyone who skips lands on Today with the **Getting started checklist**:
`Add 3 pieces · Add your fit photo · Try on your first look · Save a look` (0/4).
It disappears when complete. Each row deep-links to the exact step.

**Backend change required:** a saved "fit photo" per user (private bucket, deletable,
reused by `/tryon` when no new photo is sent). Today every try-on re-uploads.

## 6. Screen-by-screen specification

Notation: **Primary** = the one main button. **Links** = where the screen sends people.

### 6.1 Today (tab 1)

Purpose: answer "what do I wear today?" in one glance.

1. Header: greeting + weather chip (temp, condition) + avatar.
2. **Today's look card** (hero): outfit generated from the closet for today's weather and the
   user's most common occasion; item thumbnails underneath.
   - **Primary:** "Try it on" → Try-on result (uses fit photo; asks for one if missing).
   - Secondary: "Shuffle" (regenerate), "Save" (to Looks), tap an item → Item detail.
3. Getting started checklist (new users only).
4. "Continue" rail: last try-on result / last saved look.
5. One Discover teaser (this week's challenge or trend) → Discover.

Empty closet state: the hero becomes "Add your first 3 pieces to get today's look" → Add item.
Removed: the 6-tile Shortcuts grid (every destination is now a tab or a contextual link).

### 6.2 Closet (tab 2)

1. Search + category filter chips (existing).
2. Grid of items; counts per category.
3. **Primary (floating):** "+ Add" → Add item.
4. Multi-select mode (long-press): pick 1-2 items → "Try on these" or "Style around these".

Empty state: camera illustration + "Add a piece" + tip on photo quality.

### 6.3 Add item (modal from Closet, Today checklist, onboarding)

Existing camera/library → auto-detect → confirm flow, plus:
- **Batch mode:** after saving, "Add another" is the primary button; "Done" secondary.
- Leave the detail fields (brand, notes) collapsed under "More details".

### 6.4 Item detail (push from Closet / any thumbnail)

1. Large image, name, category, colours (editable inline).
2. **Primary:** "Try it on" → Try-on result.
3. Secondary: "Style around this" → Style me with this item locked in.
4. "Appears in" rail: saved Looks containing this item → Look detail.
5. Overflow: edit, delete (existing confirm dialog).

### 6.5 Style me (centre action, full-screen flow)

Merges today's Generate and Try-on screens into one 3-step flow with a step indicator.

| Step | Content | Primary |
|---|---|---|
| 1. Plan | Occasion chips (existing), weather toggle (existing), optional "lock items" from closet. | "Style me" |
| 2. Outfit | Generated outfit (existing "Building the edit" state). Swap a single item, shuffle, thumbs up/down feedback (existing `useOutfitFeedback`). | "See it on me" |
| 3. On you | Try-on result (see 6.6). | "Save look" |

Entry with parameters: from Item detail (item locked), from a Trend (`trends/[id]` → generate
with the trend's style), from Today ("Style something else").

### 6.6 Try-on result (single shared screen)

Used by Today, Item detail, Closet multi-select and Style me step 3.

1. Status: queued → processing with honest time estimate → result. User can leave; the job
   keeps running and the result appears in Looks (jobs are already durable on the backend).
2. Result image with before/after toggle (existing `showOriginal`).
3. **Primary:** "Save look". Secondary: "Share" (system share sheet + optional
   post to Community), "Try another photo", "Delete".
4. Failure state: specific reason (e.g. no body pose detected) + "Use a different photo".

Today's `/tryon/history` screen is removed; its contents move to Looks.

### 6.7 Looks (tab 4)

One library for everything the user liked.

1. Segments: **All · On me** (has try-on image) **· Favourites**.
2. Grid of look cards; a card shows the try-on image if one exists, otherwise the item collage.
3. In-progress try-ons appear at the top with a progress state.
4. Look detail: image, items (→ Item detail), "Try on" (if not yet), favourite, share,
   delete.

Empty state: "Your looks will live here" → Style me.

### 6.8 Discover (tab 5)

Single scrolling screen with three sections, each with "See all":
1. **This week's challenge** → Challenge detail → "Enter with a look" (picks from Looks).
2. **Community feed** → Post detail, Member, Create post (create pre-selects a Look).
3. **Trends** → Trend detail → "Style this trend" (Style me with trend parameters)
   → Stores near you (as a section inside trend detail and a "See all").

**Launch rule:** Discover only ships with real backend data. PRODUCT.md notes these screens still
render seed data; until the endpoints are wired, hide the tab or show an honest
"Coming soon" state. Fake social content is both a trust problem and a review risk.

### 6.9 Profile & settings (from avatar)

1. Header: name, avatar, stats (pieces, looks, try-ons).
2. **Fit photo:** view / replace / delete.
3. Style profile: anchors, colours (existing).
4. Plan & credits (once monetised): current plan, remaining try-ons, manage subscription.
5. Notifications: daily outfit time, challenge reminders.
6. Account: sign out (existing confirm), **delete account** (required by both stores when
   account creation exists).
7. Developer-only: "System status" panel (API/Backend/Session) stays behind `__DEV__`.

## 7. Retention and revenue hooks

Grounded in what the app can actually deliver; numbers to be validated, not assumed.

| Hook | Mechanism | Ties to |
|---|---|---|
| Daily habit | Morning push: "Today's look is ready (14°, rain)" → opens Today. User picks the time. | Today hero |
| Closet completeness | "Add 2 more tops for better looks" prompts when outfit variety is low. | Add item |
| Weekly social | Challenge reminders, entry from Looks in two taps. | Discover |
| Share loop | Try-on result share image with subtle FitSync mark → installs. | Try-on result |

**Monetisation (recommended):** Freemium where the *metered cost* sits behind the paywall.
- Free: unlimited closet, unlimited outfit generation, a small number of try-ons per week
  (backend already enforces `TRYON_DAILY_USER_LIMIT`).
- FitSync Pro (monthly/annual): more try-ons, try-on history kept longer, multi-item outfits on you.
- Paywall moment: *after* the first successful try-on, when the user hits the free limit —
  never before they have seen value.
- Implementation: Google Play Billing / StoreKit through RevenueCat (works with Expo).
- Every try-on has a real cost (FASHN API) — the credits model keeps gross margin positive.

## 8. Feature preservation checklist

Every existing feature has a home in the new flow.

| Feature (today) | New location |
|---|---|
| Sign in, session | Welcome → Sign in |
| Onboarding style anchors / colours | Onboarding step 3; editable in Profile |
| Add item (camera/library, AI detect) | Add item modal (Closet, Today, onboarding) |
| Closet browse / search / filter | Closet tab |
| Item detail, edit, delete | Item detail |
| Outfit generation, occasion, weather | Today hero + Style me steps 1-2 |
| Outfit feedback | Style me step 2, Look detail |
| Save / favourite outfit | Try-on result, Style me, Looks |
| Virtual try-on (single + 2-piece) | Try-on result (from 4 entry points) |
| Try-on history, delete | Looks ("On me", in-progress at top) |
| Community feed, post, member, create | Discover |
| Challenges | Discover → Challenge detail |
| Trends, trend detail | Discover → Trend detail → Style this trend |
| Stores list / detail | Discover → Trend detail / See all stores |
| Profile, stats, sign out | Profile (avatar) |
| System status | Profile, dev builds only |

## 9. Route map (expo-router)

```
app/
  _layout.tsx
  index.tsx                 → redirect: welcome | onboarding | (tabs)/today
  welcome.tsx               NEW
  (auth)/sign-in.tsx
  onboarding/               NEW folder: style.tsx, add-items.tsx, fit-photo.tsx, first-look.tsx
  (tabs)/
    _layout.tsx             4 tabs + centre "Style me" button
    today.tsx               was home.tsx
    closet.tsx
    looks.tsx               was saved.tsx, absorbs tryon/history.tsx
    discover.tsx            NEW hub for community/trends/stores
  style/                    NEW modal flow replacing (tabs)/generate.tsx
    index.tsx               steps: plan → outfit → on you
  tryon/[job].tsx           shared result screen (was tryon/index.tsx)
  look/[id].tsx             NEW look detail
  item/[id].tsx
  add-item.tsx              modal presentation
  profile.tsx               was (tabs)/profile.tsx
  community/... trends/... stores/...   unchanged screens, entered from Discover
```

Keep redirects from old routes (`/home`, `/generate`, `/saved`, `/tryon/history`) for one
release so deep links and notifications don't break.

## 10. Build order

| Phase | Work | Why first |
|---|---|---|
| 1 | Tabs + routes restructure (§9), Profile to avatar, Today hero, merge Looks + try-on history | Biggest clarity win, no backend change. |
| 2 | Style me 3-step flow + shared Try-on result screen | Core loop. |
| 3 | Saved fit photo (backend + Profile) + one-tap try-on everywhere | Removes the biggest friction. |
| 4 | New onboarding + Getting started checklist | Activation. |
| 5 | Discover hub; wire real community/trends/stores data or hide | Launch honesty. |
| 6 | Notifications, share image, paywall + RevenueCat, delete account | Retention, revenue, store compliance. |
| 7 | Full UI/UX visual overhaul on the new structure | Design once, on the final structure. |

## 11. What to measure

Instrument before launch (PostHog or Firebase Analytics):
- Activation: % of signups completing a first try-on in session 1.
- Time to first try-on.
- D1 / D7 / D30 retention.
- Try-ons per weekly active user; free-limit hits; paywall view → purchase.
- Funnel drop-off per onboarding step.
