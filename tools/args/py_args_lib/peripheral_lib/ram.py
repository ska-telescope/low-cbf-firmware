###############################################################################
#
# Copyright (C) 2016
# ASTRON (Netherlands Institute for Radio Astronomy) <http://www.astron.nl/>
# P.O.Box 2, 7990 AA Dwingeloo, The Netherlands
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Author  Date
#   HJ    jan 2017  Original
#   EK    feb 2017
#   PD    feb 2017
#
###############################################################################

from math import ceil
import logging
from constants import *
from common import c_word_w, c_nof_complex, ceil_pow2, ceil_log2
from base_object import BaseObject
from field import Field

logger = logging.getLogger('main.perip.ram')

class RAM(Field):
    """ A RAM is a Field that is repeated address_length times
    """
    def __init__(self, name, settings=None):
        super().__init__(name, settings)
        self.name(name)
        self.description = ""

        self._valid_keys = ['number_of_slaves', 'user_width']
        self._args.update({'number_of_slaves' : DEFAULT_NUMBER_OF_SLAVES})

    def number_of_slaves(self, val=None):
        """ set/get number of slaves """
        if val is not None:
            self.set_kv('number_of_slaves', val)
            return
        return self._as_int('number_of_slaves')

 
    
    def user_depth(self, val=None):
        if val is not None:
            if val < 1024: 
                logger.error("Calculated user depth %d for BRAM %s is invalid. Minimum BRAM depth is 1024", val, self.name())
            self.set_kv('user_depth', val)
            return
        return self._as_int('user_depth', self.address_length())

    def update_address_length(self):
        """ update total address_length of Register
        """
        # if len(self.fields) == 0:
            # return
        n_words = 0
        # for field in self.fields.values():
            # n_words += ceil_pow2(int(ceil(float(field.width()) / c_word_w)) * field.number_of_fields())
            #logger.debug("n_words=%d", n_words)
        n_words = ceil_pow2(self.number_of_fields())
        self.user_depth(n_words*self.width()/self.user_width())
        self.set_kv('address_length', n_words)

    def address_length(self, val=None):   
        """ set/get address_length of register
        val: if not None set address_length of register
        return: address_length of register """
        if val is not None:
            return self.set_kv('address_length', val)
        return self._as_int('address_length', default=1)