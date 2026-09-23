"""Body-region mask generation via MediaPipe Pose landmarks.

CatVTON's inpainting pipeline needs a mask marking the region to redraw with
the new garment. The official demo generates this from a full human-parsing
model (SCHP) plus DensePose. We approximate it instead with a landmark-
derived polygon: cheaper, no extra heavy model, no Detectron2 install (which
is notoriously fragile on Windows) — and CatVTON's own docs note SCHP/
DensePose are "not required for inference," only for their auto-mask demo
convenience. The tradeoff is a coarser mask; CatVTON's inpainting still
settles to real garment edges within it, just with a bit more background
context to work around than a pixel-perfect segmentation would give it.
"""

from typing import Dict, Literal

import mediapipe as mp
import numpy as np
from PIL import Image, ImageDraw

Region = Literal["upper", "lower", "overall"]

CATEGORY_TO_REGION: Dict[str, Region] = {
    "tops": "upper",
    "outerwear": "upper",
    "activewear": "upper",
    "accessories": "upper",
    "bottoms": "lower",
    "footwear": "lower",
    "dresses": "overall",
}

_pose = mp.solutions.pose.Pose(static_image_mode=True, model_complexity=1)
_LM = mp.solutions.pose.PoseLandmark


def build_mask(person_image: Image.Image, region: Region) -> Image.Image:
    """Returns a single-channel ("L") mask the same size as person_image:
    255 where the garment should be redrawn, 0 elsewhere. Raises ValueError
    if no person is detected in the photo."""
    width, height = person_image.size
    rgb = np.array(person_image.convert("RGB"))
    results = _pose.process(rgb)
    if not results.pose_landmarks:
        raise ValueError("No person detected in the photo — try a clearer, front-facing photo.")

    lm = results.pose_landmarks.landmark

    def pt(index):
        p = lm[index]
        return (p.x * width, p.y * height)

    shoulder_l, shoulder_r = pt(_LM.LEFT_SHOULDER), pt(_LM.RIGHT_SHOULDER)
    hip_l, hip_r = pt(_LM.LEFT_HIP), pt(_LM.RIGHT_HIP)
    ankle_l, ankle_r = pt(_LM.LEFT_ANKLE), pt(_LM.RIGHT_ANKLE)

    shoulder_width = abs(shoulder_r[0] - shoulder_l[0])
    margin = max(shoulder_width * 0.35, 20.0)
    top = min(shoulder_l[1], shoulder_r[1]) - margin * 0.6

    if region == "upper":
        polygon = [
            (shoulder_l[0] - margin, top), (shoulder_r[0] + margin, top),
            (hip_r[0] + margin, hip_r[1] + margin), (hip_l[0] - margin, hip_l[1] + margin),
        ]
    elif region == "lower":
        polygon = [
            (hip_l[0] - margin, hip_l[1] - margin * 0.4), (hip_r[0] + margin, hip_r[1] - margin * 0.4),
            (ankle_r[0] + margin, ankle_r[1]), (ankle_l[0] - margin, ankle_l[1]),
        ]
    else:  # overall
        polygon = [
            (shoulder_l[0] - margin, top), (shoulder_r[0] + margin, top),
            (ankle_r[0] + margin, ankle_r[1]), (ankle_l[0] - margin, ankle_l[1]),
        ]

    mask = Image.new("L", (width, height), 0)
    ImageDraw.Draw(mask).polygon(polygon, fill=255)
    return mask
