import base64
import cv2
from fastapi import FastAPI
from pydantic import BaseModel
import uvicorn

import numpy as np
from portrait_seg import remove_background

app = FastAPI()


def cv2base64(image_array):
    _, buffer = cv2.imencode(".jpg", image_array)
    processed_img_base64 = base64.b64encode(buffer).decode("utf-8")
    return processed_img_base64


class ImageInput(BaseModel):
    image_data: str
    background_color: str = "w"


class ImageOutput(BaseModel):
    image: str
    mask: str


@app.post("/process_image")
async def upload_file(payload: ImageInput):
    # Read the image using cv2
    image_bytes = base64.b64decode(payload.image_data)

    # Convert bytes to numpy array
    image_np = np.frombuffer(image_bytes, np.uint8)

    image = cv2.imdecode(image_np, cv2.IMREAD_COLOR)

    # Process the image
    image_rgba, mask = remove_background(image, payload.background_color)

    return ImageOutput(image=cv2base64(image_rgba), mask=cv2base64(mask))


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
