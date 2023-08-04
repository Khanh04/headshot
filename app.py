import io
import cv2
from fastapi import FastAPI, UploadFile, File
from fastapi.responses import StreamingResponse
import uvicorn

import numpy as np
from portrait_seg import remove_background

app = FastAPI()


@app.post("/process_image")
async def upload_file(file: UploadFile = File(...)):
    # Read the image using cv2
    image_bytes = await file.read()
    image_np = np.frombuffer(image_bytes, np.uint8)
    image = cv2.imdecode(image_np, cv2.IMREAD_COLOR)

    # Process the image
    image_rgba = remove_background(image).astype("uint8")

    # Swap the Red and Blue channels in the RGBA image
    image_rgba[:, :, [0, 2]] = image_rgba[:, :, [2, 0]]

    # Convert the PIL image to Bytes and prepare for the response
    image_bytes = cv2.imencode(".png", image_rgba)[1].tobytes()

    return StreamingResponse(io.BytesIO(image_bytes), media_type="image/png")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
