import base64
import cv2
import numpy as np
from pydantic import BaseModel, field_validator


class ImageInput(BaseModel):
    image_data: str
    background_color: str = "w"

    @field_validator("image_data")
    def validate_image_string(cls, v):
        try:
            base64.b64decode(v)
            return v
        except Exception as error:
            raise error

    @property
    def image(self):
        image_bytes = base64.b64decode(self.image_data)

        # Convert bytes to numpy array
        image_np = np.frombuffer(image_bytes, np.uint8)

        return cv2.imdecode(image_np, cv2.IMREAD_COLOR)


class ImageOutput(BaseModel):
    image: str
    mask: str
