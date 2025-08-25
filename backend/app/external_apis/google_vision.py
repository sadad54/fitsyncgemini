from google.cloud import vision
from google.oauth2 import service_account
import asyncio
import base64
from typing import Dict, List, Optional
import os

from app.core.config import settings
from app.utils.rate_limiter import rate_limiter
from fastapi import HTTPException

class GoogleVisionClient:
    def __init__(self):
        # Load service account credentials from file path
        credentials_path = os.getenv("GOOGLE_CLOUD_CREDENTIALS_PATH")
        if not credentials_path or not os.path.exists(credentials_path):
            print("[DEBUG] ENV PATH:", credentials_path)
            print("[DEBUG] File exists:", os.path.exists(credentials_path))
            raise RuntimeError("❌ GOOGLE_CLOUD_CREDENTIALS_PATH not set or file not found.")

        self.credentials = service_account.Credentials.from_service_account_file(
            credentials_path
        )
        self.client = vision.ImageAnnotatorClient(credentials=self.credentials)

        print(f"[✅] Google Vision API initialized — project: {self.credentials.project_id}")

    async def analyze_clothing_item(self, image_data: bytes, user_id: str) -> Dict:
        """Analyze clothing item using Google Cloud Vision API"""

        # Rate limit check
        allowed, reset_time = await rate_limiter.check_rate_limit(
            "google_vision",
            settings.GOOGLE_VISION_RATE_LIMIT,
            86400,  # 24 hours
            user_id
        )

        if not allowed:
            raise HTTPException(
                status_code=429,
                detail=f"Rate limit exceeded. Reset at {reset_time}"
            )

        try:
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(
                None,
                self._analyze_image_sync,
                image_data
            )
            return result

        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Vision API error: {str(e)}"
            )

    def _analyze_image_sync(self, image_data: bytes) -> Dict:
        image = vision.Image(content=image_data)

        objects = self.client.object_localization(image=image).localized_object_annotations
        labels = self.client.label_detection(image=image).label_annotations
        colors = self.client.image_properties(image=image).dominant_colors.colors

        clothing_objects = [obj for obj in objects if self._is_clothing_object(obj.name)]
        clothing_labels = [label for label in labels if self._is_clothing_label(label.description)]

        category, sub_category = self._categorize_clothing(clothing_objects, clothing_labels)
        dominant_colors = self._extract_colors(colors)

        return {
            "category": category,
            "sub_category": sub_category,
            "colors": dominant_colors,
            "confidence": self._calculate_confidence(clothing_objects, clothing_labels),
            "detected_objects": [obj.name for obj in clothing_objects],
            "detected_labels": [label.description for label in clothing_labels[:5]],
            "raw_analysis": {
                "objects": [{"name": obj.name, "confidence": obj.score} for obj in objects],
                "labels": [{"description": label.description, "confidence": label.score} for label in labels[:10]]
            }
        }

    def _is_clothing_object(self, object_name: str) -> bool:
        clothing_objects = [
            "clothing", "shirt", "t-shirt", "dress", "pants", "jeans",
            "skirt", "jacket", "coat", "sweater", "blouse", "shorts",
            "suit", "tie", "hat", "shoe", "boot", "sneaker", "sandal",
            "hoodie", "cardigan", "blazer", "vest", "scarf", "gloves"
        ]
        return any(item in object_name.lower() for item in clothing_objects)

    def _is_clothing_label(self, label: str) -> bool:
        clothing_labels = [
            "clothing", "fashion", "textile", "fabric", "apparel",
            "garment", "outfit", "wear", "style", "dress", "shirt",
            "casual wear", "formal wear", "sportswear", "footwear"
        ]
        return any(item in label.lower() for item in clothing_labels)

    def _categorize_clothing(self, objects: List, labels: List) -> tuple:
        category_map = {
            "tops": {
                "keywords": ["shirt", "t-shirt", "blouse", "sweater", "hoodie", "tank top", "polo"],
                "subcategories": {
                    "casual": ["t-shirt", "tank top", "casual shirt", "hoodie"],
                    "formal": ["dress shirt", "blouse", "button-up"],
                    "sweaters": ["sweater", "cardigan", "pullover", "jumper"]
                }
            },
            "bottoms": {
                "keywords": ["pants", "jeans", "shorts", "skirt", "trousers", "leggings"],
                "subcategories": {
                    "casual": ["jeans", "shorts", "casual pants", "leggings"],
                    "formal": ["dress pants", "trousers", "chinos"],
                    "skirts": ["skirt", "mini skirt", "maxi skirt", "pencil skirt"]
                }
            },
            "dresses": {
                "keywords": ["dress", "gown", "frock"],
                "subcategories": {
                    "casual": ["sundress", "casual dress", "day dress"],
                    "formal": ["evening dress", "cocktail dress", "gown"],
                    "party": ["party dress", "mini dress", "bodycon dress"]
                }
            },
            "outerwear": {
                "keywords": ["jacket", "coat", "blazer", "cardigan", "windbreaker"],
                "subcategories": {
                    "light": ["blazer", "cardigan", "light jacket"],
                    "heavy": ["coat", "parka", "winter jacket"],
                    "rain": ["raincoat", "windbreaker", "trench coat"]
                }
            },
            "footwear": {
                "keywords": ["shoe", "boot", "sneaker", "sandal", "heel", "loafer"],
                "subcategories": {
                    "casual": ["sneaker", "casual shoe", "loafer"],
                    "formal": ["dress shoe", "heel", "oxford", "pump"],
                    "athletic": ["running shoe", "sports shoe", "trainer"],
                    "boots": ["boot", "ankle boot", "knee boot"]
                }
            },
            "accessories": {
                "keywords": ["hat", "cap", "belt", "bag", "scarf", "jewelry", "watch"],
                "subcategories": {
                    "headwear": ["hat", "cap", "beanie", "beret"],
                    "bags": ["handbag", "backpack", "purse", "tote"],
                    "jewelry": ["necklace", "bracelet", "ring", "earrings"]
                }
            }
        }

        detected_items = [obj.name.lower() for obj in objects] + [label.description.lower() for label in labels]
        detected_text = " ".join(detected_items)

        for category, data in category_map.items():
            for keyword in data["keywords"]:
                if keyword in detected_text:
                    subcategory = self._find_best_subcategory(category, data["subcategories"], detected_text)
                    return category, subcategory

        return "unknown", "unknown"

    def _find_best_subcategory(self, category: str, subcategories: Dict, detected_text: str) -> str:
        for subcat, keywords in subcategories.items():
            for keyword in keywords:
                if keyword in detected_text:
                    return subcat
        return "general"

    def _extract_colors(self, colors_info) -> List[str]:
        colors = []
        for color in colors_info[:5]:
            rgb = color.color
            color_name = self._rgb_to_color_name(rgb.red, rgb.green, rgb.blue)
            if color_name not in colors and color_name != "unknown":
                colors.append(color_name)
        return colors[:3]

    def _rgb_to_color_name(self, r: int, g: int, b: int) -> str:
        color_map = {
            (0, 0, 0): "black", (255, 255, 255): "white", (128, 128, 128): "gray",
            (255, 0, 0): "red", (0, 128, 0): "green", (0, 0, 255): "blue",
            (255, 255, 0): "yellow", (255, 165, 0): "orange", (128, 0, 128): "purple",
            (255, 192, 203): "pink", (165, 42, 42): "brown", (0, 255, 255): "cyan",
            (255, 0, 255): "magenta", (75, 0, 130): "indigo", (255, 20, 147): "deep pink",
            (0, 100, 0): "dark green", (139, 69, 19): "saddle brown", (255, 215, 0): "gold",
            (192, 192, 192): "silver", (128, 128, 0): "olive"
        }

        min_distance = float('inf')
        closest_color = "unknown"
        for (cr, cg, cb), name in color_map.items():
            dist = ((r - cr) ** 2 + (g - cg) ** 2 + (b - cb) ** 2) ** 0.5
            if dist < min_distance:
                min_distance = dist
                closest_color = name
        if min_distance > 150:
            return "multicolor"
        return closest_color

    def _calculate_confidence(self, objects: List, labels: List) -> float:
        if not objects and not labels:
            return 0.0
        total_confidence = sum(obj.score for obj in objects) + sum(label.score for label in labels[:5])
        count = len(objects) + min(len(labels), 5)
        return round(total_confidence / count, 2) if count else 0.0

# Global instance
google_vision_client = GoogleVisionClient()
