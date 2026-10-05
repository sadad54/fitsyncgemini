"""Builds the Flairwise "Hanger F + Spark" logo kit. Run from the repo root:
    python brand/build_logo.py
Outputs SVG masters into brand/logo/. Wordmark letters are real outlines
(Archivo ExtraBold, SIL OFL) so no font is needed to display them."""
import glob
import os

from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

INK, BONE, VOLT = "#0D0D0F", "#F6F6F2", "#D4FF3A"
OUT = os.path.join(os.path.dirname(__file__), "logo")
os.makedirs(OUT, exist_ok=True)


def spark(cx, cy, r, k=0.18):
    d = r * k
    return (f"M{cx} {cy - r}Q{cx + d} {cy - d} {cx + r} {cy}Q{cx + d} {cy + d} {cx} {cy + r}"
            f"Q{cx - d} {cy + d} {cx - r} {cy}Q{cx - d} {cy - d} {cx} {cy - r}Z")


HOOK = ("M122 67.5A29.5 29.5 0 1 0 92.5 38A9.5 9.5 0 0 0 111.5 38A10.5 10.5 0 1 1 122 48.5Z")
HOOK_NECK = "M112.5 49h19v33h-19z"


def symbol(f_color, spark_color, hook=True, spark_outline=None):
    """The mark on a 256 canvas: F (stem, top bar, scan bar), hanger hook, AI sparkle."""
    parts = [
        f'<rect x="56" y="74" width="30" height="160" rx="8" fill="{f_color}"/>',
        f'<rect x="56" y="74" width="132" height="28" rx="8" fill="{f_color}"/>',
        f'<rect x="56" y="146" width="84" height="26" rx="8" fill="{f_color}"/>',
    ]
    if hook:
        # Hook stroke thickened 16 → 19 so it survives 32 px.
        # Hanger hook as filled outlines (no strokes): a 270° ring segment, centre (122,38),
        # radii 29.5/10.5 (= a 19-unit stroke), round cap at the open end, plus the neck.
        parts.append(f'<path d="{HOOK}" fill="{f_color}"/><path d="{HOOK_NECK}" fill="{f_color}"/>')
    if spark_outline:
        # Outline as a filled, slightly fuller sparkle behind (no strokes in masters).
        parts.append(f'<path d="{spark(184, 159, 41, 0.26)}" fill="{spark_outline}"/>')
    parts.append(f'<path d="{spark(184, 159, 34)}" fill="{spark_color}"/>')
    return "".join(parts)


def wordmark(color_fit, color_sync, height=100, tracking=0.06):
    """'FLAIRWISE' as outlines; returns (svg_group, width) at the given cap height."""
    font = TTFont(glob.glob("mobile/node_modules/@expo-google-fonts/archivo/800ExtraBold/*.ttf")[0])
    gs, cmap, hmtx = font.getGlyphSet(), font.getBestCmap(), font["hmtx"]
    cap = font["OS/2"].sCapHeight
    scale = height / cap
    x, out = 0.0, []
    for i, ch in enumerate("FLAIRWISE"):
        name = cmap[ord(ch)]
        pen = SVGPathPen(gs)
        gs[name].draw(TransformPen(pen, (scale, 0, 0, -scale, x, height)))
        out.append(f'<path d="{pen.getCommands()}" fill="{color_fit if i < 5 else color_sync}"/>')
        x += hmtx[name][0] * scale + tracking * height
    return "".join(out), x - tracking * height


def svg(w, h, body, bg=None):
    rect = f'<rect width="{w}" height="{h}" fill="{bg}"/>' if bg else ""
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}">{rect}{body}</svg>'


def write(name, content):
    with open(os.path.join(OUT, name), "w", encoding="utf8") as f:
        f.write(content)


# Symbol masters
write("flairwise-symbol.svg", svg(256, 256, symbol(INK, INK)))                                  # one-colour master
write("flairwise-symbol-light.svg", svg(256, 256, symbol(INK, VOLT, spark_outline=INK)))        # colour, light bg
write("flairwise-symbol-dark.svg", svg(256, 256, symbol(BONE, VOLT)))                           # colour, dark bg
write("flairwise-symbol-small.svg", svg(256, 256, symbol(INK, INK, hook=False)))                # ≤ 24 px cut


def tile(size, scale, dy=0):
    off = (256 - 256 * scale) / 2
    return f'<g transform="translate({off} {off + dy}) scale({scale})">{symbol(BONE, VOLT)}</g>'


write("flairwise-app-icon.svg", svg(256, 256, f'<rect width="256" height="256" fill="{INK}"/>{tile(256, 0.86, -4)}'))
write("flairwise-adaptive-foreground.svg", svg(256, 256, tile(256, 0.62, -3)))
write("flairwise-splash.svg", svg(256, 256, tile(256, 1.0)))

# Lockups (symbol cropped to its ink box x 46–228, y 8–240)
for mode, f_c, s_c, outline, sync_c, bg in [("light", INK, VOLT, INK, INK, None), ("dark", BONE, VOLT, None, VOLT, INK)]:
    mark = symbol(f_c, s_c, spark_outline=outline)
    wm, ww = wordmark(f_c, sync_c, height=96)
    # horizontal: symbol 232 tall, wordmark cap-aligned to the F
    w = 190 + 40 + ww + 40
    body = f'<g transform="translate(-26 -8)">{mark}</g><g transform="translate({190 + 40} 74)">{wm}</g>'
    write(f"flairwise-horizontal-{mode}.svg", svg(round(w), 248, body, bg))
    # stacked
    wm2, ww2 = wordmark(f_c, sync_c, height=64)
    sw = max(ww2, 190) + 80
    body = f'<g transform="translate({(sw - 190) / 2 - 46} 0)">{mark}</g><g transform="translate({(sw - ww2) / 2} 280)">{wm2}</g>'
    write(f"flairwise-stacked-{mode}.svg", svg(round(sw), 380, body, bg))
print("wrote", sorted(os.listdir(OUT)))
