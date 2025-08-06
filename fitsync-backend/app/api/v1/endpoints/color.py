from fastapi import APIRouter, UploadFile, File
from app.utils.color_utils import extract_dominant_colors

router = APIRouter()

@router.post("/color")
async def color(file: UploadFile = File(...)):
    img_path = f"temp_{file.filename}"
    with open(img_path, "wb") as f:
        f.write(await file.read())

    colors = extract_dominant_colors(img_path)
    return {"dominant_colors": colors}
