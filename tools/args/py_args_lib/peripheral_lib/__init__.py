import os
import sys

# cwd = __file__[:__file__.rfind('/')]
cwd = os.path.dirname(os.path.realpath(__file__))

sys.path.append(cwd)

from constants import *
from base_object import BaseObject
from field import Field
from register import Register
from ram import RAM
from fifo import FIFO
from args_errors import *
