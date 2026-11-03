"""Measure the closet tagger: top-1 category accuracy, per-class recall and CPU latency.

Runs the exact production path (app/ml/clothing_classifier.py: rembg cut-out,
then FashionCLIP zero-shot over 7 categories with a 3-prompt ensemble) on a
labelled sample, and optionally the same images without background removal
and with a single prompt per label, so each design choice gets a number.

Two sources of labelled images:

  # 1. Public product photos: ashraq/fashion-product-images-small on Hugging Face
  pip install datasets
  python eval/classifier_eval.py --hf --per-class 50 --ablate --out eval/results.json

  # 2. Your own photos: one sub-folder per category (tops/, bottoms/, dresses/, ...)
  python eval/classifier_eval.py --folder ~/closet-photos --ablate

The first run downloads the model weights (~600 MB) once.
"""
from __future__ import annotations

import argparse
import io
import json
import random
import statistics
import sys
import time
from collections import Counter, defaultdict
from pathlib import Path
from typing import Iterable, Iterator

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

CATEGORIES = ["tops", "bottoms", "dresses", "outerwear", "footwear", "accessories", "activewear"]

# fashion-product-images `articleType` -> Flairwise category. Article types
# that could reasonably belong to two categories are left out rather than guessed.
ARTICLE_TYPES: dict[str, str] = {
    **{t: "tops" for t in ["Tshirts", "Shirts", "Tops", "Sweaters", "Sweatshirts", "Tunics"]},
    **{t: "bottoms" for t in ["Jeans", "Trousers", "Shorts", "Skirts", "Capris"]},
    **{t: "dresses" for t in ["Dresses"]},
    **{t: "outerwear" for t in ["Jackets", "Blazers", "Rain Jacket", "Waistcoat"]},
    **{t: "footwear" for t in ["Casual Shoes", "Sports Shoes", "Formal Shoes", "Heels", "Flats", "Sandals", "Flip Flops"]},
    **{t: "accessories" for t in ["Handbags", "Belts", "Caps", "Scarves", "Backpacks", "Clutches", "Earrings"]},
    **{t: "activewear" for t in ["Track Pants", "Tracksuits", "Sports Bra"]},
}


def category_for(article_type: str) -> str | None:
    return ARTICLE_TYPES.get(article_type)


def stratified(items: Iterable[tuple[str, object]], per_class: int, seed: int = 42) -> list[tuple[str, object]]:
    """Up to `per_class` items per label, sampled reproducibly."""
    buckets: dict[str, list[object]] = defaultdict(list)
    for label, item in items:
        buckets[label].append(item)
    rng = random.Random(seed)
    out: list[tuple[str, object]] = []
    for label in sorted(buckets):
        chosen = buckets[label][:]
        rng.shuffle(chosen)
        out.extend((label, item) for item in chosen[:per_class])
    return out


def summarise(rows: list[dict]) -> dict:
    """rows: {"label", "predicted", "seconds"} -> accuracy, recall per class, confusion, latency."""
    if not rows:
        return {"images": 0}
    correct = sum(r["label"] == r["predicted"] for r in rows)
    per_class: dict[str, dict] = {}
    confusion: dict[str, Counter] = defaultdict(Counter)
    for r in rows:
        confusion[r["label"]][r["predicted"]] += 1
    for label, counts in sorted(confusion.items()):
        n = sum(counts.values())
        per_class[label] = {"images": n, "recall": round(counts[label] / n, 4)}
    latencies = sorted(r["seconds"] for r in rows)
    pct = lambda p: round(1000 * latencies[min(len(latencies) - 1, int(p * len(latencies)))], 1)  # noqa: E731
    return {
        "images": len(rows),
        "top1_accuracy": round(correct / len(rows), 4),
        "macro_recall": round(statistics.mean(c["recall"] for c in per_class.values()), 4),
        "per_class": per_class,
        "confusion": {label: dict(counts) for label, counts in confusion.items()},
        "latency_ms": {"p50": pct(0.5), "p95": pct(0.95), "mean": round(1000 * statistics.mean(latencies), 1)},
    }


def from_folder(root: Path) -> Iterator[tuple[str, bytes]]:
    for label_dir in sorted(p for p in root.iterdir() if p.is_dir()):
        if label_dir.name not in CATEGORIES:
            print(f"skipping folder {label_dir.name!r}: not one of {CATEGORIES}", file=sys.stderr)
            continue
        for path in sorted(label_dir.iterdir()):
            if path.suffix.lower() in {".jpg", ".jpeg", ".png", ".webp"}:
                yield label_dir.name, path.read_bytes()


def from_hugging_face() -> Iterator[tuple[str, bytes]]:
    from datasets import load_dataset  # optional dependency, only for this script

    for row in load_dataset("ashraq/fashion-product-images-small", split="train"):
        label = category_for(row["articleType"])
        if label:
            buf = io.BytesIO()
            row["image"].convert("RGB").save(buf, "JPEG", quality=92)
            yield label, buf.getvalue()


def run(samples: list[tuple[str, object]], *, background_removal: bool, ensemble: bool) -> dict:
    from app.ml import clothing_classifier as cc
    from PIL import Image

    classifier = cc.ClothingClassifier()
    classifier._ensure_loaded()
    prompts = cc.CATEGORY_PROMPTS if ensemble else {k: v[:1] for k, v in cc.CATEGORY_PROMPTS.items()}

    # Warm-up, so model loading never counts as inference latency.
    warm = Image.new("RGB", (224, 224), "white")
    classifier._classify(warm, prompts)
    if background_removal:
        classifier._remove_background(warm)

    rows = []
    for label, data in samples:
        start = time.perf_counter()
        image = Image.open(io.BytesIO(data)).convert("RGB")
        if background_removal:
            cutout = classifier._remove_background(image)
            image = classifier._on_white(cutout) if cutout else image
        predicted, _, _ = classifier._classify(image, prompts)
        rows.append({"label": label, "predicted": predicted, "seconds": time.perf_counter() - start})
    return summarise(rows)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    source = ap.add_mutually_exclusive_group(required=True)
    source.add_argument("--hf", action="store_true", help="use ashraq/fashion-product-images-small")
    source.add_argument("--folder", type=Path, help="folder with one sub-folder per category")
    ap.add_argument("--per-class", type=int, default=50)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--ablate", action="store_true", help="also run without background removal and with one prompt per label")
    ap.add_argument("--out", type=Path)
    args = ap.parse_args()

    source_iter = from_hugging_face() if args.hf else from_folder(args.folder.expanduser())
    samples = stratified(source_iter, args.per_class, args.seed)
    print(f"{len(samples)} images: {dict(Counter(label for label, _ in samples))}", file=sys.stderr)

    results = {"source": "ashraq/fashion-product-images-small" if args.hf else str(args.folder), "seed": args.seed,
               "production": run(samples, background_removal=True, ensemble=True)}
    if args.ablate:
        results["no_background_removal"] = run(samples, background_removal=False, ensemble=True)
        results["single_prompt"] = run(samples, background_removal=True, ensemble=False)

    for name, r in results.items():
        if isinstance(r, dict):
            print(f"{name:24s} top-1 {r['top1_accuracy']:.1%}  macro recall {r['macro_recall']:.1%}  "
                  f"p50 {r['latency_ms']['p50']} ms  p95 {r['latency_ms']['p95']} ms")
    if args.out:
        args.out.write_text(json.dumps(results, indent=2) + "\n")


if __name__ == "__main__":
    main()
