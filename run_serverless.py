import runpod

from models import ImageInput
from portrait_seg import remove_background
from utils import cv2base64


def handler(event):
    input = ImageInput(**event["input"])
    image, mask = remove_background(
        image=input.image, background_color=input.background_color
    )
    return {"image": cv2base64(image), "mask": cv2base64(mask)}


runpod.serverless.start({"handler": handler})
