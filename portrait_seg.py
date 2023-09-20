import paddle
import numpy as np

from paddleseg.cvlibs import manager

manager.BACKBONES._components_dict.clear()
manager.TRANSFORMS._components_dict.clear()

from ppmatting.core.predict import preprocess, reverse_transform
from utils import init_model, rebuild_mask
from setting import CONFIG_PATH
from PIL import ImageColor

MODEL, TRANSFORMs = init_model(CONFIG_PATH)


def remove_background(image, background_color, trimap=None):
    data = preprocess(img=image, transforms=TRANSFORMs, trimap=trimap)
    with paddle.no_grad():
        result = MODEL(data)
    alpha = reverse_transform(result, data["trans_info"])
    alpha = (alpha.numpy()).squeeze()
    alpha = rebuild_mask(alpha)
    alpha = alpha[:, :, np.newaxis]
    bg = get_bg(background_color, image.shape)

    rgba = alpha * image + (1 - alpha) * bg

    return rgba.astype("uint8"), alpha


def get_bg(color_code: str, img_shape: tuple[int]):
    bg = np.zeros(img_shape)
    red, green, blue = ImageColor.getcolor(color_code, "RGB")
    bg[:, :, 2] = red
    bg[:, :, 1] = green
    bg[:, :, 0] = blue
    return bg
