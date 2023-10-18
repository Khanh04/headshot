import os

import uvicorn
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from models import ImageInput, ImageOutput
from portrait_seg import remove_background
from setting import BACKGROUND_FOLDER
from utils import cv2base64

app = FastAPI()


@app.post("/process_image")
async def upload_file(payload: ImageInput) -> ImageOutput:
    # Process the image
    image_rgba, mask = remove_background(payload.image, payload.background_color)

    return ImageOutput(image=cv2base64(image_rgba), mask=cv2base64(mask))


@app.get("/backgrounds", response_model=list[dict])
async def list_backgrounds():
    """
    List all available backgrounds
    """
    backgrounds = os.listdir(BACKGROUND_FOLDER)
    return [{"id": idx, "name": bg} for idx, bg in enumerate(backgrounds)]


app.mount("/static", StaticFiles(directory="backgrounds"), name="static")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5000, reload=True)
