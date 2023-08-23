from fastapi import FastAPI
import uvicorn

from models import ImageInput, ImageOutput
from portrait_seg import remove_background
from utils import cv2base64

app = FastAPI()


@app.post("/process_image")
async def upload_file(payload: ImageInput) -> ImageOutput:
    # Process the image
    image_rgba, mask = remove_background(payload.image, payload.background_color)

    return ImageOutput(image=cv2base64(image_rgba), mask=cv2base64(mask))


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5000, reload=True)
