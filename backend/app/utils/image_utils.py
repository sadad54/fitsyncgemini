import cv2
import numpy as np
from PIL import Image
import io
from typing import Tuple, Optional, List
import base64

class ImageUtils:
    @staticmethod
    def resize_image(image_data: bytes, max_size: Tuple[int, int] = (800, 800)) -> bytes:
        """Resize image while maintaining aspect ratio"""
        image = Image.open(io.BytesIO(image_data))
        image.thumbnail(max_size, Image.Resampling.LANCZOS)
        
        output = io.BytesIO()
        image.save(output, format='JPEG', quality=85)
        return output.getvalue()

    @staticmethod
    def convert_to_base64(image_data: bytes) -> str:
        """Convert image bytes to base64 string"""
        return base64.b64encode(image_data).decode('utf-8')

    @staticmethod
    def detect_face(image_data: bytes) -> Optional[Tuple[int, int, int, int]]:
        """Detect face in image and return bounding box"""
        nparr = np.frombuffer(image_data, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        faces = face_cascade.detectMultiScale(gray, 1.1, 4)
        
        if len(faces) > 0:
            x, y, w, h = faces[0]
            return (x, y, w, h)
        return None

    @staticmethod
    def extract_dominant_colors(image_data: bytes, num_colors: int = 5) -> List[Tuple[int, int, int]]:
        """Extract dominant colors from image"""
        image = Image.open(io.BytesIO(image_data))
        image = image.convert('RGB')
        
        # Resize for faster processing
        image = image.resize((150, 150))
        
        # Convert to numpy array
        pixels = np.array(image)
        pixels = pixels.reshape(-1, 3)
        
        # Use k-means to find dominant colors
        from sklearn.cluster import KMeans
        kmeans = KMeans(n_clusters=num_colors, random_state=42)
        kmeans.fit(pixels)
        
        colors = kmeans.cluster_centers_.astype(int)
        return [tuple(color) for color in colors]
```

```

