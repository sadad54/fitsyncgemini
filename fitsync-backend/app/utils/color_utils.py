from sklearn.cluster import KMeans
import numpy as np
from PIL import Image

def extract_dominant_colors(image_path: str, num_colors=3):
    image = Image.open(image_path).resize((100, 100))
    image_array = np.array(image).reshape((-1, 3))

    kmeans = KMeans(n_clusters=num_colors)
    kmeans.fit(image_array)

    colors = kmeans.cluster_centers_.astype(int).tolist()
    return colors
