"""

 Constants used by peripheral.py and fpga.py
 this constants can be used in the yaml files
"""

from common import c_word_w, c_byte_w

# RO = read only, WO = write only, RW = read/write, FR = FIFO read, FW = FIFO write, CS = Counter saturating, CW = counter wrapping, 
# SP = special (constant, possibly generated at build time)
VALID_ACCESS_MODES = ['RO', 'WO', 'RW', 'FR', 'FW', 'CS', 'CW', 'SP']
VALID_SIDE_EFFECTS = ['CLR', 'PR', 'PW']
VALID_SLAVE_TYPES  = ['REG', 'RAM', 'FIFO', 'REG_IP']
VALID_FIELD_KEYS = ['width', 'bit_offset', 'side_effect', 'number_of_fields', 'interface', 'address_offset', 'access_mode', 'reset_value', 'radix', 'field_description','user_width','software_value']
VALID_DEFAULT_KEYS = ['width', 'address_offset', 'access_mode', 'reset_value', 'field_description', 'number_of_fields', 'reset_value', 'side_effect', 'interface']
VALID_RADIXS       = ['UNSIGNED', 'SIGNED', 'HEXADECIMAL']

DEFAULT_NUMBER_OF_PERIPHERALS = 1
DEFAULT_NUMBER_OF_SLAVES      = 1

UNASSIGNED_ADDRESS = 16384
UNASSIGNED_BIT = 32

DEFAULT_WIDTH            = c_word_w
WIDTH_IN_BYTES           = int(c_word_w/c_byte_w)
DEFAULT_BIT_OFFSET       = UNASSIGNED_BIT
DEFAULT_ACCESS_MODE      = 'RW'
DEFAULT_SIDE_EFFECT      = None
DEFAULT_ADDRESS_OFFSET   = UNASSIGNED_ADDRESS
DEFAULT_NUMBER_OF_FIELDS = 1
RESET_VALUE              = 0
DEFAULT_SOFTWARE_VALUE   = 0
DEFAULT_RADIX            = 'signed'
DEFAULT_DESCRIPTION      = 'none'
# interface applies to rams, and is full (for full axi4 interface) or simple (for simple memory interface with addr, wr_data, rd_data, we) 
DEFAULT_INTERFACE        = 'full'
DATA_WIDTH               = 32

DEFAULT_ADDRESS_LENGTH   = 1

