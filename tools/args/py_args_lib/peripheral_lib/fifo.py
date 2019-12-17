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
from register import Register
from args_errors import ARGSModeError

logger = logging.getLogger('main.periph.fifo')

# TODO: use BaseObject
class FIFO(Field):
    """ A FIFO is a specific set of Fields
        A FIFO is a Field that is repeated address_length times 
    """
    def __init__(self, name, settings):
        super().__init__(name, settings)
        self.name(name)
        self.description = ""
        # self.number_of_fifos = 1
        self.fifo_fields = []
        if self.access_mode() not in ['RO','WO']:
            logger.error("'{}' not a valid access mode for slaves of type FIFO. Valid modes include 'RO' and 'WO'".format(self.access_mode()))
            raise ARGSModeError
            
        self.tx_fifo_vacancy =    Field(name="fifo_status",
                                              settings={
                                                  'width': 32,
                                                  'access_mode': "RO",
                                                  'address_offset': 0x8,
                                                  'reset_value': 0,
                                                  'field_description': "Transmit Data FIFO Vacancy (TDFV). Width N equal to C_S_AXI_DATA_WIDTH"
                                                  })        
        self.rx_fifo_occupancy =    Field(name="fifo_status",
                                              settings={
                                                  'width': 16,
                                                  'access_mode': "RO",
                                                  'address_offset': 0x1C,
                                                  'reset_value': 0,
                                                  'field_description': "Receive Data FIFO Occupancy (RDFO). Number of locations in use for data storage"
                                                  })               
        self.rx_length =    Field(name="fifo_status",
                                              settings={
                                                  'width': 23,
                                                  'access_mode': "RO",
                                                  'address_offset': 0x24,
                                                  'reset_value': 0,
                                                  'field_description': "Receive Length Register (RLR). The number of bytes of the corresponding receive data stored in the receive data FIFO"
                                                  })         
 
        # fifo_fields["fifo_status"] =    Field(name="fifo_status",
                                              # settings={
                                                  # 'width': 4,
                                                  # 'mode': "RO",
                                                  # 'offset': 0x0,
                                                  # 'default': 0,
                                                  # 'descr': "fifo status register. Bit 0: Fifo Full Bit 1: Fifo Empty"
                                                  # })

        # fifo_fields["fifo_used_w"] =    Field(name="fifo_used_w",
                                              # settings={
                                                  # 'width': 32,
                                                  # 'mode': "RO",
                                                  # 'offset': 0x4,
                                                  # 'default': 0,
                                                  # 'descr': "fifo used words register."
                                                  # })

        # fifo_fields["fifo_read_reg"]  = Field(name="fifo_read_reg",
                                              # settings={
                                                  # 'width': settings['width'],
                                                  # 'mode': "RO",
                                                  # 'offset': 0x8,
                                                  # 'default': 0,
                                                  # 'descr': "fifo read register."
                                                  # })

        # fifo_fields["fifo_write_reg"] = Field(name="fifo_write_reg",
                                              # settings={
                                                  # 'width': settings['width'],
                                                  # 'mode': "WO",
                                                  # 'offset': 0xC,
                                                  # 'default': 0,
                                                  # 'descr': "fifo write register."
                                                  # })

        # self.register = Register("FIFO Register", fifo_fields)
        # self.address_length = settings['address_length']
        
    def set_mon_fields():
        """ fifo_fields are set based on FIFO access mode if side effect 'MON' is configured """
    
    def number_of_slaves(self, val=None):
        """ set/get number of slaves """
        if val is not None:
            self.set_kv('number_of_slaves', val)
            return
        return self._as_int('number_of_slaves')
        
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
        self.set_kv('address_length', n_words)

    def address_length(self, val=None):   
        """ set/get address_length of register
        val: if not None set address_length of register
        return: address_length of register """
        if val is not None:
            return self.set_kv('address_length', val)
        return self._as_int('address_length', default=1)