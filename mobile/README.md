# FitSync Mobile

The production-direction Expo app for FitSync's wardrobe and AI styling loop.

## What works

- Secure local preview session with profile onboarding.
- Editable style anchors and favorite-color preferences.
- Responsive closet search and category filters.
- Camera or photo-library garment intake with backend tagging.
- Closet item detail, editing, and confirmed deletion.
- Occasion-based outfit generation from owned pieces.
- Optional on-device location for current-weather styling.
- Saved looks, favorites, and 1–5 star recommendation feedback.
- Pull-to-refresh, timeout/error recovery, cache invalidation, and backend status.
- Reduced-motion-aware parallax and entrance motion.

## Run locally

```powershell
cd mobile
pnpm install
pnpm run start
```

Start `backend_v2` on all interfaces and set the app's API URL:

```text
EXPO_PUBLIC_API_BASE_URL=http://YOUR_COMPUTER_LAN_IP:8000
```

For the Android emulator, use `http://10.0.2.2:8000`. For the iOS simulator, use `http://127.0.0.1:8000`.

## Quality checks

```powershell
pnpm run typecheck
pnpm run doctor
```

The UI direction is documented in `../design-system/fitsync/MASTER.md`.
