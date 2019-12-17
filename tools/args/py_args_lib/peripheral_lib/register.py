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
from numpy import mod
import logging
from constants import *
from common import c_word_w, c_nof_complex, ceil_pow2, ceil_log2
from base_object import BaseObject
from field import Field

logger = logging.getLogger('main.periph.register')

class Register(BaseObject):
    """ A register consists of Fields
    """
    def __init__(self, name, fields=None, settings=None):
        super().__init__()

        self.name(name)

        self.fields   = [] if fields is None else fields

        self.rams = []

        self._valid_keys = ['number_of_slaves', 'address_length', 'slave_description', 'base_address']

        self._args.update({'number_of_slaves' : DEFAULT_NUMBER_OF_SLAVES,
                           'address_length'   : DEFAULT_ADDRESS_LENGTH,
                           'dual_clock'       : False,
                           'slave_description': DEFAULT_DESCRIPTION})

        #self.update_address_length()
        self.isIP = False
        self.slave_span = None

        self.protocol = 'LITE'

    def number_of_slaves(self, val=None):
        """ set/get number of slaves """
        if val is not None:
            self.set_kv('number_of_slaves', val)
            return
        return self._as_int('number_of_slaves')

    def add_field(self, name, settings):
        """ add new Field to Register with given settings
        """
        field = Field(name, settings)
        if field.success:
            # self.fields[name] = field
            self.fields.append(field)
            #self.update_address_length()
            return True
        return False

    def update_address_length(self):
        """ update total address_length of Register
        """
        if len(self.fields) == 0:
            return
        n_bytes = 0
        # for field in self.fields: #.values():
            # n_words += int(ceil_pow2(int(ceil(float(field.width()) / c_word_w)) * field.number_of_fields()))
            # logger.debug("n_words=%d", n_words)
        # n_words = ceil_pow2(n_words)  # round up to power of 2
        # n_bytes = self.fields[-1].address_offset()+WIDTH_IN_BYTES
        n_bytes = max(max([_field.address_offset() for _field in self.fields]) + WIDTH_IN_BYTES, self.slave_span if self.slave_span is not None else 0)
        self.set_kv('address_length', n_bytes)

    def address_length(self, val=None):
        """ set/get address_length of register
        val: if not None set address_length of register
        return: address_length of register """
        if val is not None:
            if mod(val, WIDTH_IN_BYTES): # dont need this if properly calcd
                logger.error("Invalid address length for register {}, not word aligned".format(self.name()))
                sys.exit()
            return self.set_kv('address_length', val)
        return self._as_int('address_length', default=1)


    def base_address(self, val = None):
        if val is not None:
            return self.set_kv('base_address', val)
        return self._as_int('base_address', default=1)