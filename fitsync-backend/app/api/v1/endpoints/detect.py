from fastapi import APIRouter, UploadFile, File
from app.models.yolo import detect_clothing

router = APIRouter()

@router.post("/detect")
async def detect(file: UploadFile = File(...)):
    img_path = f"temp_{file.filename}"
    with open(img_path, "wb") as f:
        f.write(await file.read())

    items = detect_clothing(img_path)
    return {"items": items}
