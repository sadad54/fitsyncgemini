from PIL import Image

from app.ml.clothing_classifier import ClothingClassifier


def test_nearest_color_name_maps_pure_red_to_red():
    classifier = ClothingClassifier()
    assert classifier._nearest_color_name((200, 30, 30)) == "red"


def test_nearest_color_name_maps_near_black_to_black():
    classifier = ClothingClassifier()
    assert classifier._nearest_color_name((10, 10, 12)) == "black"


def test_dominant_colors_returns_named_colors_for_solid_image():
    classifier = ClothingClassifier()
    image = Image.new("RGB", (64, 64), (20, 20, 20))
    colors = classifier._dominant_colors(image)
    assert colors == ["black"]


def test_dominant_colors_caps_at_top_n():
    classifier = ClothingClassifier()
    # A striped image with several distinct colors.
    image = Image.new("RGB", (80, 20))
    pixels = image.load()
    palette = [(200, 30, 30), (40, 80, 190), (230, 210, 40), (20, 20, 20)]
    for x in range(80):
        for y in range(20):
            pixels[x, y] = palette[x // 20 % len(palette)]
    colors = classifier._dominant_colors(image, top_n=2)
    assert len(colors) <= 2
