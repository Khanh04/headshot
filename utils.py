import base64
import cv2
from ppmatting.utils import Config, MatBuilder
from paddleseg.utils import utils

from ppmatting.transforms import Compose
from setting import CHECKPOINT_PATH


def init_model(config_path: str):
    config = Config(config_path)
    builder = MatBuilder(config)
    model = builder.model
    utils.load_entire_model(model, CHECKPOINT_PATH)
    transforms = Compose(builder.val_transforms)
    model.eval()
    return model, transforms


def cv2base64(image_array):
    _, buffer = cv2.imencode(".png", image_array)
    processed_img_base64 = base64.b64encode(buffer).decode("utf-8")
    return processed_img_base64
