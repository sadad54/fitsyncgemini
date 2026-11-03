import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "eval"))

import classifier_eval as ev  # noqa: E402
from app.ml.clothing_classifier import CATEGORY_PROMPTS  # noqa: E402


def test_mapping_only_targets_real_categories():
    assert set(ev.ARTICLE_TYPES.values()) == set(ev.CATEGORIES) == set(CATEGORY_PROMPTS)
    assert ev.category_for("Jeans") == "bottoms"
    assert ev.category_for("Watches") is None  # ambiguous types are skipped, not guessed


def test_stratified_sampling_is_capped_and_reproducible():
    items = [("tops", i) for i in range(10)] + [("dresses", i) for i in range(3)]
    first = ev.stratified(items, per_class=4, seed=7)
    assert [label for label, _ in first].count("tops") == 4
    assert [label for label, _ in first].count("dresses") == 3
    assert first == ev.stratified(items, per_class=4, seed=7)


def test_summarise_reports_accuracy_recall_confusion_and_latency():
    rows = [
        {"label": "tops", "predicted": "tops", "seconds": 0.1},
        {"label": "tops", "predicted": "outerwear", "seconds": 0.3},
        {"label": "dresses", "predicted": "dresses", "seconds": 0.2},
        {"label": "dresses", "predicted": "dresses", "seconds": 0.2},
    ]
    out = ev.summarise(rows)
    assert out["top1_accuracy"] == 0.75
    assert out["per_class"] == {"dresses": {"images": 2, "recall": 1.0}, "tops": {"images": 2, "recall": 0.5}}
    assert out["macro_recall"] == 0.75
    assert out["confusion"]["tops"] == {"tops": 1, "outerwear": 1}
    assert out["latency_ms"]["p50"] == 200.0 and out["latency_ms"]["p95"] == 300.0


def test_summarise_empty():
    assert ev.summarise([]) == {"images": 0}
