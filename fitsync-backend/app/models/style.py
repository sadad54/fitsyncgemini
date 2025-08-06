def suggest_outfit(detected_items):
    if "tie" in detected_items or "suit" in detected_items:
        return "Formal Outfit"
    elif "t-shirt" in detected_items or "jeans" in detected_items:
        return "Casual Outfit"
    else:
        return "Smart Casual Outfit"
