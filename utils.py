import base64
import cv2
import numpy as np
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


def rebuild_mask(mask, threshold=0.01):
    binary_mask = (mask > threshold).astype(np.uint8)

    # Apply connected component analysis
    num_labels, labels = cv2.connectedComponents(binary_mask)

    # Find the label with the maximum area
    largest_label = 0
    largest_area = 0
    for label in range(1, num_labels):  # Start from 1 to ignore the background
        area = np.sum(labels == label)
        if area > largest_area:
            largest_area = area
            largest_label = label

    # Create a new binary mask where only the largest blob is set to 1
    final_mask = (labels == largest_label).astype(np.uint8)
    return final_mask * mask
