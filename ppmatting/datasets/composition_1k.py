# Copyright (c) 2022 PaddlePaddle Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import math
import os
import random

import cv2
import numpy as np
import paddle
from paddleseg.cvlibs import manager

import ppmatting.transforms as T
from ppmatting.datasets.matting_dataset import MattingDataset


@manager.DATASETS.add_component
class Composition1K(MattingDataset):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
