from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from typing import List
from app.external_apis.huggingface_virtual_tryon import huggingface_virtual_tryon_client

router = APIRouter(
    prefix="/virtual-tryon",
    tags=["Virtual Try-On"]
)

@router.post("/single")
async def try_on_single_item(
    user_id: str = Form(...),
    person_image: UploadFile = File(...),
    clothing_image: UploadFile = File(...),
    tryon_type: str = Form("full_body")
):
    try:
        person_bytes = await person_image.read()
        clothing_bytes = await clothing_image.read()

        result = await huggingface_virtual_tryon_client.virtual_tryon(
            person_image=person_bytes,
            clothing_image=clothing_bytes,
            user_id=user_id,
            tryon_type=tryon_type
        )
        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/batch")
async def try_on_batch_items(
    user_id: str = Form(...),
    person_image: UploadFile = File(...),
    clothing_images: List[UploadFile] = File(...)
):
    try:
        person_bytes = await person_image.read()
        clothing_items = [await img.read() for img in clothing_images]

        result = await huggingface_virtual_tryon_client.batch_virtual_tryon(
            person_image=person_bytes,
            clothing_items=clothing_items,
            user_id=user_id
        )
        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
