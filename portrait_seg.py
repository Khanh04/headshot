import paddle
import numpy as np

from paddleseg.cvlibs import manager
from models import BackgroundColor

manager.BACKBONES._components_dict.clear()
manager.TRANSFORMS._components_dict.clear()

from ppmatting.core.predict import preprocess, reverse_transform
from utils import init_model, rebuild_mask
from setting import CONFIG_PATH

MODEL, TRANSFORMs = init_model(CONFIG_PATH)


def remove_background(image, background_mode="w", trimap=None):
    data = preprocess(img=image, transforms=TRANSFORMs, trimap=trimap)
    with paddle.no_grad():
        result = MODEL(data)
    alpha = reverse_transform(result, data["trans_info"])
    alpha = (alpha.numpy()).squeeze()
    alpha = rebuild_mask(alpha)
    alpha = alpha[:, :, np.newaxis]
    bg = get_bg(background_mode, image.shape)

    rgba = alpha * image + (1 - alpha) * bg

    return rgba.astype("uint8"), alpha


def get_bg(background: str, img_shape: tuple[int]):
    bg = np.zeros(img_shape)
    match background:
        case BackgroundColor.Red:
            bg[:, :, 2] = 255
        case BackgroundColor.Green:
            bg[:, :, 1] = 255
        case BackgroundColor.Blue:
            bg[:, :, 0] = 255
        case BackgroundColor.White:
            bg[:, :, :] = 255
        case _:
            raise ValueError("Invalid background color mode")
    return bg
