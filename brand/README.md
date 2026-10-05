# Flairwise logo — "Hanger F + Spark"

**Idea:** the F hangs from a hanger (your real clothes) and the volt sparkle styles it (the AI stylist).
Fashion on one side, AI on the other, in a single letter.

Rebuild every SVG with `python brand/build_logo.py` (run from the repo root; needs `fontTools`).

## Files (`brand/logo/`)
| File | Use |
|---|---|
| `flairwise-symbol.svg` | One-colour master (ink). Print, stamps, embroidery, anything single-ink. |
| `flairwise-symbol-light.svg` | Colour on light backgrounds: ink F, volt sparkle with an ink outline. |
| `flairwise-symbol-dark.svg` | Colour on ink/dark backgrounds: bone F, volt sparkle. |
| `flairwise-symbol-small.svg` | Small-size cut without the hook. Use at 24 px and below (favicons, tab bars). |
| `flairwise-horizontal-{light,dark}.svg` | Symbol + FLAIRWISE wordmark side by side. Default lockup. |
| `flairwise-stacked-{light,dark}.svg` | Symbol over wordmark. Splash screens, square placements, merch. |
| `flairwise-app-icon.svg`, `flairwise-adaptive-foreground.svg`, `flairwise-splash.svg` | Sources for `mobile/assets/` icons. |
| `../web/` | favicon.ico/svg, PNG icon set, `site.webmanifest`, `head-snippet.html`. |
| `../png/` | 1024 px app-icon PNGs. |

## Colour
| Name | HEX | RGB | Role |
|---|---|---|---|
| Ink | `#0D0D0F` | 13 13 15 | The F and wordmark on light; the stage/tile background |
| Bone | `#F6F6F2` | 246 246 242 | The F and wordmark on dark |
| Volt | `#D4FF3A` | 212 255 58 | The sparkle, and "SYNC" in the dark wordmark. **Never as text or a lone shape on light backgrounds** — on light, give it an ink outline (as in `-light` files) or use the one-colour version. |

Nearest Pantone for volt is in the 802 C / 375 C range; confirm against a printed swatch before you print anything.

## Typography
Wordmark: **Archivo ExtraBold**, uppercase, +6% tracking, converted to outlines (SIL Open Font License, which allows logo use).
On dark backgrounds "FLAIR" is bone and "WISE" is volt; on light backgrounds the whole word is ink.
App UI pairs it with Instrument Serif (headlines) and Geist (interface).

## Rules
- **Clear space:** the height of the F's middle bar (26 units on the 256 grid) on all sides; double that in lockups.
- **Minimum size:** full symbol 32 px / 8 mm; below that use `flairwise-symbol-small.svg` (down to 16 px). Horizontal lockup 96 px wide.
- **Don't:** recolour the sparkle anything but volt (or the single ink colour), rotate or skew the mark, separate the sparkle from the F, put volt on white without the ink outline, add shadows/gradients, or re-set the wordmark in a live font.

## Notes and open items
- All masters are filled outlines (no strokes), ready for print, cutting and embroidery.
- Name: renamed from FitSync (a registered trademark of FitSync Corporation) to Flairwise. A quick web search found no app or brand conflicts for Flairwise, but it is not legally cleared. Run a professional search (USPTO/EUIPO and a reverse image search) before launch.
