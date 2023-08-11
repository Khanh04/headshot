import paddle
import numpy as np


from paddleseg.cvlibs import manager
from paddleseg.utils import get_sys_env, logger
import cv2


manager.BACKBONES._components_dict.clear()
manager.TRANSFORMS._components_dict.clear()

import ppmatting
import paddle.nn.functional as F

from ppmatting.core.predict import preprocess, reverse_transform
from ppmatting.utils import get_image_list, estimate_foreground_ml
from utils import init_model
from setting import CONFIG_PATH

MODEL, TRANSFORMs = init_model(CONFIG_PATH)


def remove_background(image, background=None, trimap=None):
    data = preprocess(img=image, transforms=TRANSFORMs, trimap=trimap)
    with paddle.no_grad():
        result = MODEL(data)
    alpha = reverse_transform(result, data["trans_info"])
    alpha = (alpha.numpy()).squeeze()
    alpha = (alpha * 255).astype("uint8")
    fg_estimate = True
    # save rgba
    if fg_estimate:
        fg = estimate_foreground_ml(image / 255.0, alpha / 255.0) * 255
    else:
        fg = background

    fg = fg.astype("uint8")[..., ::-1]
    alpha = alpha[:, :, np.newaxis]

    rgba = np.concatenate((fg, alpha), axis=-1)

    return rgba.astype("uint8"), alpha
