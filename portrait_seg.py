import paddle
import numpy as np

from paddleseg.cvlibs import manager

manager.BACKBONES._components_dict.clear()
manager.TRANSFORMS._components_dict.clear()

from ppmatting.core.predict import preprocess, reverse_transform
from utils import init_model
from setting import CONFIG_PATH

MODEL, TRANSFORMs = init_model(CONFIG_PATH)


def remove_background(image, background_mode="w", trimap=None):
    data = preprocess(img=image, transforms=TRANSFORMs, trimap=trimap)
    with paddle.no_grad():
        result = MODEL(data)
    alpha = reverse_transform(result, data["trans_info"])
    alpha = (alpha.numpy()).squeeze()

    alpha = alpha[:, :, np.newaxis]

    bg = get_bg(background_mode, image.shape)

    rgba = alpha * image + (1 - alpha) * bg

    return rgba.astype("uint8"), alpha


def get_bg(background, img_shape):
    bg = np.zeros(img_shape)
    if background == "r":
        bg[:, :, 2] = 255
    elif background is None or background == "g":
        bg[:, :, 1] = 255
    elif background == "b":
        bg[:, :, 0] = 255
    elif background == "w":
        bg[:, :, :] = 255
    return bg
