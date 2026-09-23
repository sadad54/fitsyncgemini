"""Local, offline clothing detection — no external API, no per-call cost.

Runs a CLIP model fine-tuned on fashion product photos
(patrickjohncyh/fashion-clip) fully on-device for zero-shot category
classification, plus a local dominant-color extraction pass. The model
weights download once from the Hugging Face Hub on first use and are then
cached on disk (~/.cache/huggingface) — every classification after that is
pure local inference, no network call, no auth, no API key.
"""

import asyncio
import io
import threading
from typing import Any, Dict, List, Optional, Tuple

from PIL import Image

MODEL_NAME = "patrickjohncyh/fashion-clip"

# Each label gets several phrasings, scored and averaged together (an
# ensemble) instead of one phrase per label — meaningfully more stable
# zero-shot accuracy than a single prompt, for one extra batched CLIP call.
CATEGORY_PROMPTS: Dict[str, List[str]] = {
    "tops": ["a photo of a top, shirt, or blouse", "a product photo of a shirt", "a t-shirt on a plain background"],
    "bottoms": ["a photo of pants, jeans, or a skirt", "a product photo of trousers", "jeans on a plain background"],
    "dresses": ["a photo of a dress", "a product photo of a dress", "a dress on a plain background"],
    "outerwear": ["a photo of a jacket or coat", "a product photo of a coat", "an outerwear jacket on a plain background"],
    "footwear": ["a photo of shoes or boots", "a product photo of sneakers", "a pair of shoes on a plain background"],
    "accessories": ["a photo of a bag, hat, or jewelry accessory", "a product photo of a fashion accessory", "a handbag on a plain background"],
    "activewear": ["a photo of athletic or workout clothing", "a product photo of activewear", "gym clothing on a plain background"],
}

SUBCATEGORY_PROMPTS: Dict[str, List[str]] = {
    "tops": ["t-shirt", "blouse", "sweater", "hoodie", "polo shirt", "tank top", "button-up shirt"],
    "bottoms": ["jeans", "trousers", "shorts", "skirt", "leggings"],
    "dresses": ["casual dress", "cocktail dress", "maxi dress", "sundress"],
    "outerwear": ["blazer", "denim jacket", "winter coat", "cardigan", "windbreaker"],
    "footwear": ["sneakers", "boots", "sandals", "heels", "loafers"],
    "accessories": ["handbag", "hat", "scarf", "belt", "jewelry"],
    "activewear": ["athletic top", "leggings", "tracksuit", "sports bra"],
}

# A small, named color palette for nearest-neighbor mapping of the image's
# dominant pixel clusters — plain arithmetic, no model needed.
_COLOR_PALETTE: List[Tuple[str, Tuple[int, int, int]]] = [
    ("black", (20, 20, 20)), ("white", (245, 245, 245)), ("gray", (128, 128, 128)),
    ("red", (200, 30, 30)), ("green", (40, 130, 60)), ("blue", (40, 80, 190)),
    ("navy", (25, 35, 80)), ("yellow", (230, 210, 40)), ("orange", (230, 120, 30)),
    ("purple", (120, 50, 140)), ("pink", (230, 150, 180)), ("brown", (110, 70, 40)),
    ("beige", (215, 195, 165)), ("cream", (235, 225, 200)), ("olive", (110, 115, 60)),
    ("gold", (200, 165, 60)), ("silver", (190, 190, 195)),
]


def _phrase_variants(label: str) -> List[str]:
    return [f"a photo of {label}", f"a product photo of {label}", f"{label} on a plain background"]


class ClothingClassifier:
    def __init__(self) -> None:
        self._model = None
        self._processor = None
        self._bg_session = None
        self._lock = threading.Lock()

    def _ensure_loaded(self) -> None:
        if self._model is not None:
            return
        with self._lock:
            if self._model is not None:
                return
            from transformers import CLIPModel, CLIPProcessor

            self._model = CLIPModel.from_pretrained(MODEL_NAME)
            self._processor = CLIPProcessor.from_pretrained(MODEL_NAME)

    def _ensure_bg_session(self):
        if self._bg_session is not None:
            return self._bg_session
        with self._lock:
            if self._bg_session is None:
                from rembg import new_session

                self._bg_session = new_session("u2net")
            return self._bg_session

    async def warmup(self) -> None:
        """Load model weights up front so the first real request isn't the
        one paying the load cost (and risking a client-side timeout)."""
        loop = asyncio.get_event_loop()
        await loop.run_in_executor(None, self._ensure_loaded)
        await loop.run_in_executor(None, self._ensure_bg_session)

    async def analyze(self, image_bytes: bytes) -> Dict[str, Any]:
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, self._analyze_sync, image_bytes)

    def _remove_background(self, image: Image.Image) -> Optional[Image.Image]:
        """Best-effort background removal (rembg/u2net) — fashion-clip was
        trained on clean catalog product photos, and stripping a real photo's
        background before classifying measurably improves zero-shot accuracy.
        Returns None on any failure so the caller falls back to the original
        photo rather than blocking detection on this being a nice-to-have."""
        try:
            from rembg import remove

            buf = io.BytesIO()
            image.save(buf, format="PNG")
            cutout = remove(buf.getvalue(), session=self._ensure_bg_session())
            return Image.open(io.BytesIO(cutout)).convert("RGBA")
        except Exception:
            return None

    def _analyze_sync(self, image_bytes: bytes) -> Dict[str, Any]:
        self._ensure_loaded()
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")

        cutout = self._remove_background(image)
        classify_image = self._on_white(cutout) if cutout else image
        color_source = cutout if cutout else image

        category, confidence, category_scores = self._classify(classify_image, CATEGORY_PROMPTS)
        sub_category: Optional[str] = None
        if category in SUBCATEGORY_PROMPTS:
            sub_prompts = {label: _phrase_variants(label) for label in SUBCATEGORY_PROMPTS[category]}
            sub_category, _, _ = self._classify(classify_image, sub_prompts)

        colors = self._dominant_colors(color_source)
        detected_labels = [category] + ([sub_category] if sub_category else [])

        return {
            "category": category,
            "sub_category": sub_category,
            "colors": colors,
            "confidence": confidence,
            "detected_objects": [category],
            "detected_labels": detected_labels,
            "suggested_name": self._suggest_name(category, sub_category, colors),
            "raw_analysis": {"category_scores": category_scores},
            "method": "local_clip",
        }

    def _on_white(self, cutout: Image.Image) -> Image.Image:
        background = Image.new("RGB", cutout.size, (255, 255, 255))
        background.paste(cutout, mask=cutout.split()[-1])
        return background

    def _suggest_name(self, category: str, sub_category: Optional[str], colors: List[str]) -> str:
        """A free, local first guess at an item name (e.g. "Blue Sweater") —
        composed from what the classifier already detected, not a separate
        model call. Editable by the user, never authoritative."""
        noun = (sub_category or category).replace("-", " ")
        words = [w.capitalize() for w in noun.split(" ")]
        if colors:
            words = [colors[0].capitalize()] + words
        return " ".join(words)

    def _classify(self, image: Image.Image, prompts: Dict[str, List[str]]) -> Tuple[str, float, Dict[str, float]]:
        import torch

        labels = list(prompts.keys())
        flat_texts: List[str] = []
        spans: List[Tuple[int, int]] = []
        for label in labels:
            start = len(flat_texts)
            flat_texts.extend(prompts[label])
            spans.append((start, len(flat_texts)))

        inputs = self._processor(text=flat_texts, images=image, return_tensors="pt", padding=True)
        with torch.no_grad():
            outputs = self._model(**inputs)
            probs = outputs.logits_per_image.softmax(dim=1)[0].tolist()

        scored: Dict[str, float] = {}
        for label, (start, end) in zip(labels, spans):
            scored[label] = round(sum(probs[start:end]) / (end - start), 4)

        best_label = max(scored, key=scored.get)
        return best_label, scored[best_label], scored

    def _dominant_colors(self, image: Image.Image, top_n: int = 3) -> List[str]:
        small = image.copy()
        small.thumbnail((100, 100))
        alpha = small.split()[-1] if small.mode == "RGBA" else None
        rgb = small.convert("RGB")

        quantized = rgb.quantize(colors=8, method=Image.MEDIANCUT)
        palette = quantized.getpalette() or []
        indices = list(quantized.getdata())
        alpha_values = list(alpha.getdata()) if alpha else None

        counts: Dict[int, int] = {}
        for i, index in enumerate(indices):
            # Skip pixels the background-removal step made transparent —
            # otherwise a stripped-out backdrop still pollutes the palette.
            if alpha_values is not None and alpha_values[i] < 16:
                continue
            counts[index] = counts.get(index, 0) + 1

        names: List[str] = []
        for index, _ in sorted(counts.items(), key=lambda kv: kv[1], reverse=True):
            r, g, b = palette[index * 3: index * 3 + 3]
            name = self._nearest_color_name((r, g, b))
            if name not in names:
                names.append(name)
            if len(names) >= top_n:
                break
        return names

    def _nearest_color_name(self, rgb: Tuple[int, int, int]) -> str:
        r, g, b = rgb
        best_name, best_dist = "unknown", float("inf")
        for name, (pr, pg, pb) in _COLOR_PALETTE:
            dist = (r - pr) ** 2 + (g - pg) ** 2 + (b - pb) ** 2
            if dist < best_dist:
                best_dist = dist
                best_name = name
        return best_name


clothing_classifier = ClothingClassifier()
