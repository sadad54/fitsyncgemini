from app.services.outfit_service import OutfitService

TOP = {"id": "top-1", "category": "tops", "name": "Cream poplin shirt", "colors": ["cream"]}
BOTTOM = {"id": "bottom-1", "category": "bottoms", "name": "Olive wide trouser", "colors": ["olive"]}
SHOE = {"id": "shoe-1", "category": "footwear", "name": "Black leather boot", "colors": ["black"]}
OUTER = {"id": "outer-1", "category": "outerwear", "name": "Charcoal wool blazer", "colors": ["charcoal"]}
DRESS = {"id": "dress-1", "category": "dresses", "name": "Sage linen dress", "colors": ["sage"]}
ACTIVEWEAR = {"id": "active-1", "category": "activewear", "name": "Ribbed performance tee", "colors": ["black"]}


def test_select_items_picks_essentials_for_casual():
    service = OutfitService()
    selected, filled = service._select_items([TOP, BOTTOM, SHOE], "casual", None)
    assert filled == 3
    assert {item["id"] for item in selected} == {"top-1", "bottom-1", "shoe-1"}


def test_select_items_prefers_dress_for_dinner():
    service = OutfitService()
    selected, filled = service._select_items([TOP, BOTTOM, SHOE, DRESS], "dinner", None)
    ids = {item["id"] for item in selected}
    assert "dress-1" in ids
    assert "top-1" not in ids
    assert filled == 2


def test_select_items_uses_activewear_for_workout():
    service = OutfitService()
    selected, filled = service._select_items([TOP, BOTTOM, SHOE, ACTIVEWEAR], "workout", None)
    ids = {item["id"] for item in selected}
    assert "active-1" in ids
    assert filled == 2


def test_select_items_adds_outerwear_when_cold():
    service = OutfitService()
    selected, _ = service._select_items([TOP, BOTTOM, SHOE, OUTER], "casual", {"temperature": 5})
    ids = {item["id"] for item in selected}
    assert "outer-1" in ids


def test_select_items_skips_outerwear_when_hot():
    service = OutfitService()
    selected, _ = service._select_items([TOP, BOTTOM, SHOE, OUTER], "travel", {"temperature": 30})
    ids = {item["id"] for item in selected}
    assert "outer-1" not in ids


def test_score_is_zero_for_empty_closet():
    service = OutfitService()
    assert service._score(0, False, 0) == 0.0


def test_score_rewards_full_coverage_and_weather():
    service = OutfitService()
    score = service._score(3, True, 4)
    assert score > 0.9


def test_explain_handles_empty_selection():
    service = OutfitService()
    message = service._explain([], "casual", None)
    assert "closet" in message.lower()


def test_explain_mentions_items_and_weather():
    service = OutfitService()
    message = service._explain([TOP, BOTTOM], "work", {"temperature": 12})
    assert "Cream poplin shirt" in message
    assert "12" in message
