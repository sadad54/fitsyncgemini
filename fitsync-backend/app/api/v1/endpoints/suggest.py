from fastapi import APIRouter, UploadFile, File
from app.models.yolo import detect_clothing
from app.models.style import suggest_outfit

router = APIRouter()

@router.post("/suggest")
async def suggest(file: UploadFile = File(...)):
    img_path = f"temp_{file.filename}"
    with open(img_path, "wb") as f:
        f.write(await file.read())

    items = detect_clothing(img_path)
    suggestion = suggest_outfit(items)
    return {"suggested_outfit": suggestion}
