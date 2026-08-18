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

CATEGORY_PROMPTS: Dict[str, str] = {
    "tops": "a photo of a top, shirt, or blouse",
    "bottoms": "a photo of pants, jeans, or a skirt",
    "dresses": "a photo of a dress",
    "outerwear": "a photo of a jacket or coat",
    "footwear": "a photo of shoes or boots",
    "accessories": "a photo of a bag, hat, or jewelry accessory",
    "activewear": "a photo of athletic or workout clothing",
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


class ClothingClassifier:
    def __init__(self) -> None:
        self._model = None
        self._processor = None
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

    async def analyze(self, image_bytes: bytes) -> Dict[str, Any]:
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, self._analyze_sync, image_bytes)

    def _analyze_sync(self, image_bytes: bytes) -> Dict[str, Any]:
        self._ensure_loaded()
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")

        category, confidence, category_scores = self._classify(image, CATEGORY_PROMPTS)
        sub_category: Optional[str] = None
        if category in SUBCATEGORY_PROMPTS:
            sub_prompts = {label: f"a photo of {label}" for label in SUBCATEGORY_PROMPTS[category]}
            sub_category, _, _ = self._classify(image, sub_prompts)

        colors = self._dominant_colors(image)
        detected_labels = [category] + ([sub_category] if sub_category else [])

        return {
            "category": category,
            "sub_category": sub_category,
            "colors": colors,
            "confidence": confidence,
            "detected_objects": [category],
            "detected_labels": detected_labels,
            "raw_analysis": {"category_scores": category_scores},
            "method": "local_clip",
        }

    def _classify(self, image: Image.Image, prompts: Dict[str, str]) -> Tuple[str, float, Dict[str, float]]:
        import torch

        labels = list(prompts.keys())
        texts = list(prompts.values())
        inputs = self._processor(text=texts, images=image, return_tensors="pt", padding=True)
        with torch.no_grad():
            outputs = self._model(**inputs)
            probs = outputs.logits_per_image.softmax(dim=1)[0].tolist()
        scored = dict(zip(labels, (round(p, 4) for p in probs)))
        best_label = max(scored, key=scored.get)
        return best_label, scored[best_label], scored

    def _dominant_colors(self, image: Image.Image, top_n: int = 3) -> List[str]:
        small = image.copy()
        small.thumbnail((100, 100))
        quantized = small.quantize(colors=8, method=Image.MEDIANCUT)
        palette = quantized.getpalette() or []
        counts = sorted(quantized.getcolors(), reverse=True)

        names: List[str] = []
        for count, index in counts:
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
