""" init file for py_args_lib
"""

import os
import sys

cwd = __file__[:__file__.rfind('/')]
# cwd = os.path.dirname(os.path.realpath(__file__))
sys.path.append(cwd)

from unit_logger import UnitLogger

unit_logger = UnitLogger(os.path.join(cwd, '../log'))
logger = unit_logger.logger

from peripheral import PeripheralLibrary, Peripheral
from fpga import FPGA, FPGALibrary
from peripheral_lib import *
