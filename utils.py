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
