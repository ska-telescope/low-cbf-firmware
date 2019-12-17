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

import logging
import sys
from constants import *
from common import c_word_w, c_nof_complex, ceil_pow2, ceil_log2
from base_object import BaseObject
from numpy import mod

logger = logging.getLogger('main.periph.field')


class Field(BaseObject):
    """ A field defines data at certain address or an array of addresses
    """
    def __init__(self, name, settings=None):
        super().__init__()

        self.name(name)

        # self._valid_keys = ['width', 'bit_offset', 'access_mode', 'side_effect', 'address_offset', 'number_of_fields',
                            # 'reset_value', 'software_value', 'radix', 'field_description', 'field_name', 'default', 'user_width']
        self._valid_dict = {'width':{'max':32, 'min':1}, 'bit_offset':{'max':UNASSIGNED_BIT,'min':0}, 'access_mode':{}, 'interface':{}, 'side_effect':{},'address_offset': {'max':16384,'min':0, 'word_aligned':True},
                            'number_of_fields':{'max':262144,'min':'1'},'reset_value':{'max':131071},'software_value':{},'radix':{},'field_description':{},'field_name':{},'user_width':{'max':2048,'min':32}}
        self._args.update({'width'            : DEFAULT_WIDTH,
                           'bit_offset'       : DEFAULT_BIT_OFFSET,
                           'access_mode'      : DEFAULT_ACCESS_MODE,
                           'side_effect'      : DEFAULT_SIDE_EFFECT,
                           'address_offset'   : DEFAULT_ADDRESS_OFFSET,
                           'number_of_fields' : DEFAULT_NUMBER_OF_FIELDS,
                           'reset_value'      : RESET_VALUE,
                           'software_value'   : DEFAULT_SOFTWARE_VALUE,
                           'radix'            : DEFAULT_RADIX,
                           'field_description': DEFAULT_DESCRIPTION,
                           'interface'        : DEFAULT_INTERFACE,
                           'group_name'       : None})

        if settings is not None:
            # print(name)
            # print(settings)
            for key, val in settings.items():
                if key in self._valid_dict.keys(): #self._valid_keys:

                    if key == 'access_mode' and val.upper() not in VALID_ACCESS_MODES:
                        logger.error("Field.__init__(), Not a valid acces_mode '%s'", val)
                        self.success = False
                    elif key == 'side_effect' and val.upper() not in VALID_SIDE_EFFECTS:
                        logger.error("Field.__init__(), Not a valid side_effect '%s'", val)
                        self.success = False
                    else:
                        self.set_kv(key, val)
                else:
                    logger.error("Field.__init__(), Not a valid key '%s'", key)
                    self.success = False

    def __lt__(self, other):
        return self.address_offset() < other.address_offset()

    def number_of_fields(self, val=None):
        """ set/get number of fields """
        if val is not None:
            self.set_kv('number_of_fields', val)
            return
        return self._as_int('number_of_fields')

    def group_name(self, val=None):
        """ set/get group name """
        if val is not None:
            self.set_kv('group_name', val)
            return
        return self._as_str('group_name')

    def width(self, val=None):
        """ set/get width of field
        val: if not None set width of field
        return: actual width of field """
        if val is not None:
            return self.set_kv('width', val)
        _val = self._as_int('width')

        if not self.is_valid('width'):
            return None

        return self._as_int('width')

    def bit_offset(self, val=None):
        """ set/get bit_offset of field
        val: if not None set bit_offset of field
        return: actual bit_offset of field """
        if val is not None:
            return self.set_kv('bit_offset', val)
        if not self.is_valid('bit_offset'):
            return None
        return self._as_int('bit_offset')

    def access_mode(self, val=None):
        """ set/get access_mode of field
        val: if not None and a valid mode set access_mode of field
        return: actual access_mode of field """
        if val is not None:
            if val.upper() in VALID_ACCESS_MODES:
                return self.set_kv('access_mode', val.upper())
            else:
                logger.error("unknown access_mode '%s'", val)
                self.success = False
                return False
        return self._as_str('access_mode').upper()

    def side_effect(self, val=None):
        """ set/get side_effect of field
        val: if not None and a valid side_effect set side_effect of field
        return: actual side_effect of field """
        if val is not None:
            if val.upper() != 'NONE':
                vals = val.split(',')
                for _val in vals:
                    _val = _val.strip()
                    if _val.upper() not in VALID_SIDE_EFFECTS:
                        logger.error("unknown side_effect '%s'", _val)
                        self.success = False
                        return False
                return self.set_kv('side_effect', val.upper())
        return self._as_str('side_effect').upper()

    def address_offset(self, val=None):
        """ set/get address offset of field
        val: if not None set address offset of field
        return: actual address offset of field """
        if val is not None:
            return self.set_kv('address_offset', val)
        if not self.is_valid('address_offset'):
            return None
        return self._as_int('address_offset')

    def reset_value(self, val=None):
        """ set/get default hardware reset value of field
        val: if not None set default value of field
        return: active hardware reset value of field """
        if val is not None:
            return self.set_kv('reset_value', val)
        if not self.is_valid('reset_value'):
            return None
        return self._as_int('reset_value')

    def software_value(self, val=None):
        """ set/get software reset value of field
        val: if not None set default value of field
        return: active software reset value of field """
        if val is not None:
            return self.set_kv('software_value', val)
        if not self.is_valid('software_value'):
            return None
        return self._as_int('software_value')

    def radix(self, val=None):
        """ set/get radix value of field
        val: if not None set default value of field
        return: active radix value of field """
        if val is not None:
            if val.upper() in VALID_RADIXS:
                return self.set_kv('radix', val.upper())
            else:
                logger.error("unknown radix '%s'", val)
                self.success = False
                return False
        return self._as_int('radix')

    def field_description(self, val=None):
        """ set/get description of field
        val: if not None set description of field
        return: description of field """
        if val is not None:
            return self.set_kv('field_description', val)
        return self._as_str('field_description')


    def user_width(self, val=None):
        """ set/get width of RAM MM bus side interface  """
        if val is not None:
            self.set_kv('user_width', val)
            return
        return self._as_int('user_width', default=32)

    def interface(self, val=None):
        """ interface is used for rams to select between simple addr/data and full AXI4 """
        if val is not None:
            self.set_kv('interface', val)
            return
        return self._as_str('interface')

    def base_address(self, val = None):
        if val is not None:
            if mod(val, WIDTH_IN_BYTES):  # don't need check here if tool calcs are correct
                logger.error("Base address for field {} is not word aligned".format(field.name()))
            self.set_kv('base_addr', val)
            return
        return self._as_int('base_addr', default=0)


    def is_valid(self, yaml_key):
        """ Check value falls within min max range for keys that are ints """
        min = self._valid_dict[yaml_key].get('min', None)
        max = self._valid_dict[yaml_key].get('max', None)
        check_alignment = self._valid_dict[yaml_key].get('word_aligned', False)

        if yaml_key in ['software_value','reset_value']:
            min =  0
            max = int(1<<self._args.get('width', 32))-1


        _val = self._as_int(yaml_key)
        if not isinstance(_val, int):
            return True # may not have been evaluated from parameter yet, skip

        if check_alignment:
            if mod(_val, WIDTH_IN_BYTES):
                logger.error("Address offset for field {} is not word aligned".format(self.name()))
                sys.exit()

        if min is not None:
            if _val < min:
                logger.error("Field '{}': Value {} for '{}' key is outside of supported range, min is {}. Value reset to None".format(self.name(), _val, yaml_key, min))
                return False
        if max is not None:
            if _val > max:
                logger.error("Field '{}': Value {} for '{}' key is outside of supported range, max is {}. Value reset to None".format(self.name(), _val, yaml_key, max))
                return False
        return True



    # TODO: calc size in bytes
    # def get_byte_size(self):

    #def address_length(self, val=None):
    #    """ set/get address length of field
    #    val: if not None set address length of field
    #    return: active address_length of field """
    #    if val is not None:
    #        return self.set_kv('address_length', val)
    #    return self._as_int('address_length')
