
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


import os
from copy import deepcopy, copy
from math import ceil
import logging
import yaml
import collections
import datetime
from common import c_word_w, c_nof_complex, ceil_pow2, ceil_log2, unique, path_string
from peripheral_lib import *

logger = logging.getLogger('main.peripheral')

class Peripheral(BaseObject):
    """ A Peripheral consists of 1 or more MM slaves. The slave can be a
    Register, RAM or FIFO.

    The Peripheral has parameters to configure the MM slaves.

    A Peripheral has two levels of supporting multiple instances:
    1) At system level a peripheral can be used more than once. The individual
       peripherals are then distinghuised by defining a unique label per
       instance.
    2) At peripheral level internally in the peripheral if the peripheral
       support an array of instances. The size of the array is then specified
       via nof_inst. Dependent on the specific definition of the peripheral,
       the nof_inst then either replicates some fields in a register or it
       replicates some or all MM slaves nof_inst times.

    The Peripheral evaluates the nof_inst and parameters to set the
    dimensions of the MM slaves.
    """
    
    # args build timestamp - declared as a class variable because this class gets 
    # instantiated more than once and we need to ensure timestamps all match
    # formatted as a 32-bit hex string that looks like a date & hour
    # e.g. 5pm (1700h) on 15 Oct 2019 => 0x19101517
    # Note the decimal value will look nothing like a date.
    # For future maintainers: this will overflow in year 2099, but the chance of collision is small
    __timestamp = datetime.datetime.now().strftime('0x%y%m%d%H')

    def __init__(self, library_config):
        super().__init__()
        self._config         = {}  # read config from file
        self._parameters     = {}  # all used parameters
        self.registers       = {}  # all used registers
        self.rams            = {}  # all used rams
        self.fifos           = {}  # all used fifos
        self.slaves          = []
        self._component_name = library_config['peripheral_name']
        self.lib             = library_config['lib']
        self.name(self._component_name)
        self._valid_keys = ['number_of_peripherals']
        self._args.update({'number_of_peripherals' : DEFAULT_NUMBER_OF_PERIPHERALS})
        self.evaluated = False
        self._config         = library_config  # [self.component_name()]
        self.reg_len = 0

        logger.debug("extract config for %s", self.component_name())
        self.extract_config()

    def get_slave(self, name):
        # for reg in self.registers.values():
            # if name == reg.name() or reg.user_defined_name():
                # return reg
        # for ram in self.rams.values():
            # if name == ram.name() or ram.user_defined_name():
                # return ram
        # for fifo in self.fifos.values():
            # if name == fifo.name() or fifo.user_defined_name():
                # return fifo
        for slave in self.registers.slaves:
             if name == slave.name() or slave.user_defined_name():
                return slave

        return None

    def component_name(self):
        """ get component_name """
        return self._component_name

    def number_of_peripherals(self, val=None):
        """ set/get number of peripherals """
        if val is not None:
            self.set_kv('number_of_peripherals', val)
            return
        return self._as_int('number_of_peripherals')

    def parameter(self, key, val=None):

        if '.' in key:
            _struct, _key = key.split('.')
            if _struct not in self._parameters:
                logger.error("key '%s' not in parameters", key)
                return None
            if _key not in self._parameters[_struct]:
                logger.error("key '%s' not in parameters", key)
                return None
            if val is not None:
                logger.debug("  Parameter %s default value: %s is overwritten with new value: %s",
                             key,
                             str(self._parameters[_struct][_key]),
                             str(val))
                self._parameters[_struct][_key] = val
                return

        if val is not None:
            logger.debug("  Parameter %s default value: %s is overwritten with new value: %s",
                         key,
                         str(self._parameters.get(key, 'None')),
                         str(val))
            self._parameters[key] = val
            return
        return self._parameters[key]

    # def set_user_defined_slavename(self, slave_nr, name):
        # """ set user defined slave name """
        # slave_key = 'slave_{}'.format(slave_nr)
        # if slave_key in self.registers:
            # self.registers[slave_key].user_defined_name(name)
        # elif slave_key in self.rams:
            # self.rams[slave_key].user_defined_name(name)
        # elif slave_key in self.fifos:
            # self.fifos[slave_key].user_defined_name(name)
        # else:
            # logger.error("Unknown slave number")

    def set_user_defined_slavename(self, slave_nr, name):
        """ Set user defined slave name
        """
        if slave_nr in range(len(self.slaves)):
            self.slaves[slave_nr].user_defined_name(name)

    def extract_config(self):
        """ extract all kv pairs from the config (yaml file)
        and assign it to the following dicts:
        parameters, registers, rams, fifos """

        # clear all existing settings
        self._parameters = {}
        self.registers  = {}
        self.rams       = {}
        self.fifos      = {}


        if "parameters" in  self._config:
            #self.parameters.update(val)

            _parameters = deepcopy(self._config['parameters'])

            # keys with '.' in the name indicate the use of a structs
            # inside this class it is a dict in a dict
            for parameter_set in _parameters:
                #print(parameter_set)
                name  = parameter_set['name']
                value = parameter_set['value']
                if '.' in name:
                    _struct, _name = name.split('.')
                    if _struct not in self._parameters:
                        self._parameters[_struct] = {}
            # structs available now in self._parameters

            remove_list = []
            for parameter_set_nr, parameter_set in enumerate(_parameters):
                name  = parameter_set['name']
                value = parameter_set['value']
                if '.' in name: # struct notation with dot
                    _struct, _name = name.split('.')
                    self._parameters[_struct][_name] = self._eval(str(value))
                else:
                    self._parameters[name] = self._eval(str(value))
                remove_list.append((parameter_set_nr, name))

            for parameter_set_nr, name in sorted(remove_list, reverse=True):
                logger.debug("delete '%s' from parameters", name)
                del _parameters[parameter_set_nr]

            for parameter_set in _parameters:
                name  = parameter_set['name']
                value = parameter_set['value']
                logger.debug("eval of name=%s and value=%s not posible", name, value)

            logger.debug("used parameters=%s", str(self._parameters))

        if 'slave_ports' in self._config:
            slave_ports = deepcopy(self._config['slave_ports'])

            if not isinstance(slave_ports, list):
                logger.error("slave_ports not a list in {}.peripheral.yaml".format(self.lib))
                sys.exit()

            for slave_nr, slave_info in enumerate(slave_ports):
                # logger.debug("slave_prefix=%s, slave_name=%s, slave_postfix=%s",
                             # slave_info['slave_prefix'], slave_info['slave_name'], slave_info['slave_postfix'])
                logger.debug("slave_name=%s slave_type=%s", slave_info.get('slave_name',None), slave_info.get('slave_type',None))
                # make full name, dot sepperated
                # slave_name = []
                # for name in ('slave_prefix', 'slave_name', 'slave_postfix'):
                    # if slave_info[name] in (None, ''):
                        # slave_name.append('')
                    # else:
                        # slave_name.append(slave_info[name])
                # slave_name = '.'.join(slave_name)
                slave_name = slave_info['slave_name']

                if slave_name is None:
                    logger.error("Peripheral '{}': 'slave_name' key missing value in {}.peripheral.yaml".format(self.name(), self.lib))
                    sys.exit()

                i = 0
                if slave_info.get('slave_type','').upper() in VALID_SLAVE_TYPES:
                    number_of_slaves = slave_info.get('number_of_slaves', DEFAULT_NUMBER_OF_SLAVES)

                    fields = []
                    if 'fields' in slave_info:
                        # for field_info in slave_info['fields']: # list of addresses
                        defaults = {}
                        for field_group in slave_info['fields']:
                            if isinstance(field_group, dict): # labelled field group
                                (group_label, v), = field_group.items()
                                field_group = v
                            elif len(field_group) > 1:          # unlabelled field group
                                group_label = "reg{}".format(i)
                                i = i + 1
                            else :
                                group_label = None # only one field in group

                            for field_info in field_group:
                                # logger.debug("field_info=%s", str(field_info))

                                # get defaults dictionary if exists for field group
                                if field_info.get('field_defaults', None) is not None:
                                    defaults = field_info['field_defaults']
                                    if any([key.lower() not in VALID_DEFAULT_KEYS for key in defaults.keys()]) :
                                        defaults = {}
                                        logger.error("{}.peripheral.yaml: Invalid key set in defaults for field group {}. Valid keys are {}".format(self.lib, group_label, VALID_DEFAULT_KEYS))
                                        sys.exit()
                                    continue

                                field_name = field_info['field_name']
                                try :
                                    field = Field(field_name)
                                except ARGSNameError:
                                    logger.error("Invalid name '{}' for field in {}.peripheral.yaml".format(field_name, self.lib))
                                    sys.exit()
                                if group_label is not None :
                                    field.group_name(group_label)
                                if field_name == "args_map_build":
                                    logger.info("args_map_build = {}".format(Peripheral.__timestamp))
                                    field_info['reset_value'] = Peripheral.__timestamp
                                for key, val in field_info.items():
                                    if val is not None:
                                        if key == 'field_name':
                                            continue
                                        if key.lower() in VALID_FIELD_KEYS: # if valid attribute key, apply value to attribute
                                            eval("field.{}(val)".format(key.lower()))
                                            # logger.debug("{}.peripheral.yaml: field {} {} is {}".format(self.lib, field.name(),key,str(eval("field.{}()".format(key.lower())))))
                                        else:
                                            logger.error("Unknown key {} in {}.peripheral.yaml".format(key, self.lib))
                                            sys.exit()

                                    else:
                                        logger.error("Peripheral '{}': Slave '{}': '{}' key missing value in {}.peripheral.yaml".format(self.name(), slave_name, key, self.lib))
                                        sys.exit()

                                for key, val in defaults.items():
                                    if field_info.get(key, None) is None: # if key doesn't exist in config file, apply defaults
                                        eval("field.{}(val)".format(key.lower()))
                                        logger.debug("{}.peripheral.yaml: Setting field {} key {} to default {}".format(self.lib,field_info['field_name'], key, val))

                                if field.success:
                                    fields.append(deepcopy(field))
                                else:
                                    logger.error("{}.peripheral.yaml: field '{}' not succesfully added to fields".format(self.lib, field_name))
                                    sys.exit()

                    if slave_info['slave_type'].upper() in ['RAM', 'FIFO']:
                        field = field_group[0]
                        if slave_info['slave_type'] in ['RAM']:
                            self.add_ram(slave_nr, slave_name, field, number_of_slaves)
                        else:
                            self.add_fifo(slave_nr, slave_name, field, number_of_slaves)
                    else: # slave_type is REG or REG_IP
                        logger.debug('adding register %s', slave_name)
                        self.add_register(slave_nr, slave_name, fields, number_of_slaves, slave_info['slave_type'].upper() == 'REG_IP', slave_info.get('slave_protocol', None),slave_info.get('slave_span', None))
                    if 'slave_description' in slave_info.keys():
                        self.slaves[-1].update_args({'slave_description': slave_info['slave_description']})
                    if 'dual_clock' in slave_info.keys():
                        self.slaves[-1].update_args({'dual_clock': slave_info['dual_clock']})

                else :
                    logger.error('Peripheral \'{}\': Slave \'{}\': Invalid value {} for \'slave_type\' key in {}.peripheral.yaml'.format(self.name(), slave_name, slave_info.get('slave_type',None), self.lib))
                    sys.exit()
                # elif slave_info['slave_type'] == 'FIFO':
                    # # TODO:
                    # pass

        if 'peripheral_description' in self._config:
            self.update_args({'peripheral_description': self._config['peripheral_description']})

    def _eval(self, val, val_type=None):
        """ evaluate val.
        1) trying to parse values of known parameter into the value
        2) eval the value, known imported function are also evaluated """



        _val = str(val)
        # first replace all knowns parameter names with its assigned value
        for key1, val1 in self._parameters.items():
            logger.debug("key1={}, val1={}".format(key1, val1))
            # if val is a dict, in vhdl it's a struct
            if isinstance(val1, dict):
                for key2, val2 in val1.items():
                    key = "{}.{}".format(key1, key2)
                    #logger.debug("replace %s with %s", key, str(val2))
                    _val = _val.replace(key, str(val2))
            else:
                #logger.debug("replace %s with %s", key1, str(val1))
                _val = _val.replace(key1, str(val1))
        #logger.debug("_val={}".format(_val))
        if val is None:
            logger.error("key set to invalid value {} in {}.peripheral.yaml".format(_val, self.lib))
            sys.exit()

        if '.coe' in _val:
            return _val
        try:
            result = eval(_val)
            if isinstance(result, float):
                result = int(result)
        except SyntaxError:
            logger.error("Key set to invalid value '{}' in {}.peripheral.yaml".format(_val, self.lib))
            sys.exit()
        except NameError:
            result = _val
            if val_type == int:
                logger.error("Key set to invalid value '{}' in {}.peripheral.yaml".format(_val, self.lib))
                logger.error("Is parameter defined?")
                sys.exit()

        logger.debug("  _eval(%s) returns eval(%s) = %s", str(val), _val, str(result))

        return result

    def add_parameter(self, name, value):
        """ add parameter to  peripheral
        """
        self._parameters[name] = value

    def add_register(self, slave_nr, name, fields, number_of_slaves, isIP, protocol, slave_span):
        """ add register to peripheral
        """

        register = self.init_slave('Register', name, fields)
        register.number_of_slaves(number_of_slaves)
        register.isIP = isIP
        register.slave_span = slave_span
        if protocol is not None and protocol.upper() in ['LITE','FULL']:
            register.protocol = protocol.upper()
        # else :
            # logger.error("{}.peripheral.yaml: Invalid user setting {} for slave {}".format(self.lib, protocol, name))
            # sys.exit()
        self.registers['slave_{}'.format(slave_nr)] = register
        self.slaves.append(register)

    def add_ram(self, slave_nr, name, settings, number_of_slaves):
        """ add RAM to peripheral
        """
        logger.debug("name is %s", name)

        ram = self.init_slave('RAM', name, settings)
        ram.number_of_slaves(number_of_slaves)
        self.rams['slave_{}'.format(slave_nr)] = ram
        self.slaves.append(ram)

    def add_fifo(self, slave_nr, name, field, number_of_slaves):
        """ add FIFO to peripheral
        """
        # fifo = FIFO(name, field)
        fifo = self.init_slave('FIFO', name, field)
        fifo.number_of_slaves(number_of_slaves)
        self.fifos['slave_{}'.format(slave_nr)] = fifo
        self.slaves.append(fifo)

    def init_slave(self, slave_type, name, settings):
        """ init Slave based on type with error checking """
        add_slave = "{}(name, settings)".format(slave_type)
        try :
            slave = eval(add_slave)
        except ARGSNameError:
            logger.error("Invalid slave_name '{}' for {} in {}.peripheral.yaml".format(name, slave_type, self.lib))
            sys.exit()
        except ARGSModeError:
            logger.error("Invalid access mode for {} '{}' in {}.peripheral.yaml".format(slave_type, name, self.lib))
            sys.exit()
        return slave

    def eval_fields(self, fields):
        # Evaluate the fields.
        # ['number_of_fields', 'width', 'bit_offset', 'access_mode', 'side_effect',
        #  'address_offset', 'reset_value', 'software_value', 'radix', 'field_description']

        for field in fields: #.values():
            logger.debug("eval field %s", field.name())
            if [(field.name() == _field.name() and field.group_name() == _field.group_name())for _field in fields].count(True) > 1:
                logger.error("Field name '{}' group_name '{}' is not unique within slave field list in {}.peripheral.yaml".format(field.name(), field.group_name(), self.lib))
                sys.exit()
            if field.group_name() != "None":
                field.name(field.group_name() + '_' +field.name())
            field.width(val=self._eval(field.width(), int))
            field.bit_offset(val=self._eval(field.bit_offset(), int))
            field.access_mode(val=self._eval(field.access_mode()))
            field.side_effect(val=self._eval(field.side_effect()))
            field.address_offset(val=self._eval(field.address_offset(), int))
            field.number_of_fields(val=self._eval(field.number_of_fields(), int))
            field.reset_value(val=self._eval(field.reset_value(), int))
            field.software_value(val=self._eval(field.software_value(), int))
            field.radix(val=self._eval(field.radix()))


    def eval_fifo(self):
        """ Evaluate the paramters and the nof_inst of the peripheral  """

        # for fifo in self.fifos.values():
            # print(type(fifo))
        for slave in self.slaves:
            if isinstance(slave, FIFO):
                # Evaluate the fields
                self.eval_fields([slave])
            else :
                continue
            fifo = slave
            fifo.number_of_slaves(val=self._eval(fifo.number_of_slaves()))
            logger.debug("  -FIFO depth str: %s", fifo.number_of_fields())
            fifo.address_length(val = ceil_pow2(self._eval(fifo.number_of_fields())))
            logger.debug("  -FIFO depth eval: %s", fifo.address_length())
            logger.debug("  -FIFO width str: %s", fifo.width())


    def eval_ram(self):
        """Evaluate the parameters and the nof_inst of the peripheral in order to define the
           real address_length and width of the RAM.
           For example: address_length = c_nof_weights*c_nof_signal_paths
                        witdh = c_weights_w*c_nof_complex """

        # for ram in self.rams.values():
        for slave in self.slaves:
            # Evaluate the fields and see if there are field that have to be repeated.
            if isinstance(slave, RAM):
                ram = slave
            else:
                continue

            self.eval_fields([ram])
            if ram.width() < DEFAULT_WIDTH:
                ram.width(DEFAULT_WIDTH)
            if ram.user_width() <DEFAULT_WIDTH:
                ram.user_width(DEFAULT_WIDTH)

            ram.number_of_slaves(val=self._eval(ram.number_of_slaves()))

            # for ram in self.rams.values():
        for slave in self.slaves:
            # Evaluate the fields and see if there are field that have to be repeated.
            if isinstance(slave, RAM):
                ram = slave
            else:
                continue
            # ram.number_of_slaves(val=self._eval(ram.nof_inst()))
            # for field in ram.fields:
            logger.debug("  -RAM depth str: %s", ram.number_of_fields())
            # Here the variables are used to evaluate the true value for the depth
            # parameter(taking int account the nof_inst as well)
            ram.address_length(val=ceil_pow2(self._eval(ram.number_of_fields())))
            logger.debug("  -RAM depth eval: %d", ram.address_length())

            logger.debug("  -RAM width str: %s", ram.width())
            # Here the variables are used to evaluate the true value for the width parameter.
            # field.width(val=self._eval(field.width()))
            # ram.width(val=self._eval(field.width()))
            # ram.default(val=self._eval(field.default()))
            ram.user_depth(val=self._eval(ram.user_depth()))
            ram.user_width(val=self._eval(ram.user_width()))
            ram.update_address_length()
            # ram.access_mode(val=self._eval(field.access_mode()))
            logger.debug("  -RAM width eval: %d", ram.width())
            logger.debug("  %s access_mode: %s", ram.name(), ram.access_mode())
            logger.debug("  %s depth: %d", ram.name(), ram.address_length())
            logger.debug("  %s width: %d", ram.name(), ram.user_width())


    def eval_register(self):
        """Evaluate the register address_length based on the evaluation of the fields,
           nof registers and the nof_inst."""
        #for parameter in self.parameters:
            # Here the parameters of the peripheral are promoted to real python variables
            #exec("%s = %d" % (parameter, eval(str(self.parameters[parameter]))))
        logger.debug("Number of registers = %d", len(self.registers.items()))
        # for i in range(len(self.registers.values())):#register in self.registers.values():
            # try:
                # register = self.registers['slave_{}'.format(i)]
                # logger.debug(" Register slave %s ", register.name())
            # except KeyError:
                # continue
        base_addr = 0
        for slave in self.slaves:
            if isinstance(slave, Register):
                register = slave
            else :
                continue
            # register.number_of_slaves(val=self._eval(register.number_of_slaves()))

            # Evaluate the fields and see if there are field that have to be repeated.
            fields_eval = []
            for field in register.fields:
                if field.number_of_fields() > 1 and field.number_of_fields() < 32:
                    for i in range(field.number_of_fields()):
                        _field = deepcopy(field)
                        _field.name("{}{}".format(field.name(), i))
                        if _field.bit_offset() != UNASSIGNED_BIT and _field.group_name() != "None" and i > 0:# if fields repeated within the same group and bit offset is set, reset to 0 from the 2nd repeated field
                            _field.bit_offset(field.bit_offset()+i*_field.width()) # duplicate within the field group
                        if _field.address_offset() != UNASSIGNED_ADDRESS and i > 0: # field is manually assigned
                            if _field.group_name() == None or (field.bit_offset() + _field.number_of_fields()*_field.width()) >= DEFAULT_WIDTH:  # not part of a field group
                                _field.address_offset(field.address_offset()+i) # duplicate across addresses
                        fields_eval.append(_field)
                elif field.number_of_fields() >= 32:
                    register.rams.append(field)
                else :
                    fields_eval.append(field)


            self.eval_fields(fields_eval)
            self.eval_fields(register.rams)
            register.number_of_slaves(val=self._eval(register.number_of_slaves()))

            register_name = []
            if self.prefix() not in (None, ''):
                register_name.append(self.prefix().upper())
            register_name.append(register.name())
            register.name('_'.join(register_name))

            # set base addresses for reg fields implemented as RAM
            for field in register.rams:
                base_addr = ceil(base_addr/ceil_pow2(field.number_of_fields()*WIDTH_IN_BYTES))*ceil_pow2(field.number_of_fields()*WIDTH_IN_BYTES) # lowest possible base_addr
                field.base_address(base_addr)
                base_addr = base_addr + ceil_pow2(field.number_of_fields()*WIDTH_IN_BYTES)*register.number_of_slaves() # new base address

            #### Assigned Address and bits to register fields
            # 1st pass for manually set address fields
            occupied_addresses = []
            for field in fields_eval:
                if field.address_offset() != UNASSIGNED_ADDRESS:
                    occupied_addresses.append(field.address_offset())
                    # logger.debug("{}.peripheral.yaml: field {} has manually set address {}".format(self.lib, field.name(), str(hex(field.address_offset()))))

            # 2nd pass for automatic address and bit offset assignment
            lowest_free_addr = 0
            group_address = UNASSIGNED_ADDRESS
            last_group = None
            for field in fields_eval:
                # skip address and bit placement for fields resulting in RAM blocks, addresses already set above
                if field.number_of_fields() >= 32:
                    logger.warning("Field %s number_of_fields >= 32, a dual port RAM will be instantiated within the Register module")
                    continue;

                # new field group or single field
                if field.group_name() != last_group or field.group_name() == "None":
                    if field.group_name() != "None":
                        field_group = [_field for _field in fields_eval if _field.group_name() == field.group_name()]
                        occupied_bits = [bit for _field in field_group for bit in range(_field.bit_offset(), _field.bit_offset()+_field.width())  if _field.bit_offset() != UNASSIGNED_BIT]
                    else :
                        occupied_bits = list(range(field.bit_offset(), field.bit_offset() + field.width())) if field.bit_offset() != UNASSIGNED_BIT else []
                    while (lowest_free_addr) in occupied_addresses:
                        lowest_free_addr = lowest_free_addr + WIDTH_IN_BYTES
                    if len(set(occupied_bits)) < len(occupied_bits) or any([bit>(DATA_WIDTH-1) or bit <0 for bit in occupied_bits]):
                        logger.error("{}.peripheral.yaml: Manually assigned bits for field {} is outside of data width or contains bit collisions".format(self.lib, field.name() if field.group_name() == "None" else "group " + field.group_name()))
                        logger.error("{}".format(str(occupied_bits)))
                        sys.exit()
                # track beginning of group address
                if field.group_name() != "None":
                    if field.group_name() == last_group: # for all subsequent fields in field group
                        field.address_offset(group_address)
                    else : # new group, do for first field in group, checks addresses within group and determines group_address or sets as unassigned
                        last_group = field.group_name()
                        # get unique list of addresses for fields with matching group name and address not equal to unassigned address
                        group_addresses = list(set([_field.address_offset() for _field in field_group if _field.address_offset() != UNASSIGNED_ADDRESS]))
                        if len(group_addresses) == 1:
                            group_address = group_addresses[0]
                        elif len(group_addresses) > 1:
                            logger.error("{}.peripheral.yaml: Manually set addresses within field group \"{}\"are conflicting, please change in configuration file".format(self.lib, field.group_name()))
                            sys.exit()
                        else: # address not assigned
                            group_address = UNASSIGNED_ADDRESS

                if field.address_offset() == UNASSIGNED_ADDRESS:
                    field.address_offset(lowest_free_addr)
                    occupied_addresses.append(lowest_free_addr)

                if field.bit_offset() == UNASSIGNED_BIT:
                    free_bit = 0
                    while any([i in occupied_bits for i in range(free_bit, free_bit + field.width()+1)]): # bit is occupied
                        free_bit = free_bit + 1 # try next bit
                        if free_bit == DEFAULT_WIDTH: # 31 didn't work
                            logger.error("{}.peripheral.yaml: No suitable gap available for automatic bit offset assignment of field{}".format(self.lib, field.name()))
                            logger.error("Check peripheral.yaml file. Field group may be overstuffed or manual bit assignment may have precluded space for other fields")
                            break
                    field.bit_offset(free_bit)
                occupied_bits = occupied_bits + list(range(field.bit_offset(), field.bit_offset() + field.width()))
                # logger.warning("{}.peripheral.yaml: Final field {} addr {} [{}-{}]".format(self.lib, field.name(), str(field.address_offset()), str(field.bit_offset()+field.width()-1),str(field.bit_offset())))

            # re-sort fields to be ordered by address and bit offsets
            fields_eval.sort(key=lambda x: x.address_offset())
            sorted_fields = []
            dummy_group = []
            group_address = -1
            for field in fields_eval:
                if field.address_offset() == group_address:
                    continue
                group_address = field.address_offset()
                dummy_group = [field for field in fields_eval if field.address_offset() == group_address]
                sorted_fields.extend(sorted(dummy_group, key=lambda x: x.bit_offset()))
            register.fields = sorted_fields                  # Update the fields with evaluated fields

            # self.eval_fields(register.fields)
            # self.eval_fields(register.rams)
            register.update_address_length()  # Estimate the new address_length after evaluation of the fields and nof_inst
            # logger.info("  %s address_length: %d", register.name(), register.address_length())
            # logger.info("slave %s has base_address %d", register.name(), register.base_address())
            register.base_address(base_addr)
            base_addr = base_addr + register.address_length()*register.number_of_slaves()

        self.reg_len = base_addr

    def eval_peripheral(self):
        """Evaluate name, label, nof_inst and the parameters to determine the true size of
           the RAMs and the register width and the name of the peripheral, registers and RAMS """
        logger.debug(" Evaluating peripheral '%s'", self.name())

        self.eval_fifo()
        self.eval_ram()
        self.eval_register()
        self.evaluated = True

    def get_description(self):
        """ return peripheral description """
        return self._config.get('peripheral_description',"")

    def show_overview(self, header=True):
        """ print system overview
        """
        if header:
            logger.info("--------------------")
            logger.info("PERIPHERAL OVERVIEW:")
            logger.info("--------------------")

        logger.info("Peripheral name:     %s", self.name())
        if self.number_of_peripherals() > 1:
            logger.info("  number_of_peripheral_instances=%d", self.number_of_peripherals())
        logger.info("  RAM and REG:")
        # for ram in self.rams.values():
        for ram in self.slaves:
            if not isinstance(ram, RAM):
                continue
            logger.info("    %-20s:", ram.name())
            if ram.number_of_slaves() > 1:
                logger.info("      number_of_slaves=%-3s", str(ram.number_of_slaves()))
            logger.info("      fields:")
            # first make list with address_offset as first item to print later fields orderd on address.
            fields = []
            #for field_val in ram.fields.values():
            fields.append([ram.address_offset(), ram.name()])

            for _offset, _name in sorted(fields):
                field = ram
                logger.info("        %-20s:", _name)
                #if field.number_of_fields() > 1:
                #    logger.info("          number_of_fields=%s", str(field.number_of_fields()))
                logger.info("          width=%-2s       number_of_fields=%s",
                            str(field.width()),
                            str(field.number_of_fields()))

        # for reg in self.registers.values():
        for reg in self.slaves:
            if not isinstance(reg, Register):
                continue
            #logger.debug("reg_fields=%s", str(reg.fields))
            logger.info("    %-20s:", reg.name())
            if reg.number_of_slaves() > 1:
                logger.info("      number_of_slaves=%-3s", str(reg.number_of_slaves()))
            logger.info("      address_length=%-3s", str(reg.address_length()))
            logger.info("      fields:")

            for field in reg.fields:

                logger.info("        %-20s", field.name())
                #if field.number_of_fields() > 1:
                #    logger.info("          number_of_fields=%s", str(field.number_of_fields()))

                logger.info("          width=%-2s       address_offset=0x%02x  access_mode=%-4s  reset_value=%-4s  radix=%s",
                            str(field.width()), field.address_offset(),
                            field.access_mode(), str(field.reset_value()),
                            field.radix())
                logger.info("          bit_offset=%-2s  number_of_fields=%-4s  side_effect=%-4s  software_value=%-4s",
                            str(field.bit_offset()), str(field.number_of_fields()),
                            field.side_effect(), str(field.software_value()))

        logger.info("  parameters:")
        for param_key, param_val in self._parameters.items():
            if isinstance(param_val, dict):
                for _key, _val in param_val.items():
                    logger.info("      %-25s  %s", "{}.{}".format(param_key, _key), str(_val))
            else:
                logger.info("      %-20s  %s", param_key, str(param_val))


class PeripheralLibrary(object):
    """ List of all information for peripheral config files in the root dir
    """
    def __init__(self, root_dir=None, file_extension='.peripheral.yaml'):
        """Store the dictionaries from all file_name files in root_dir."""
        self.root_dir   = root_dir
        logger.debug("****PERIPHERAL LIBRARY FUNCTION CALLED*****,root dir is {}  \n".format(root_dir))

        # all peripheral files have the same double file extension ".peripheral.yaml"
        self.file_extension  = file_extension
        self.library = collections.OrderedDict()
        self.nof_peripherals = 0 # number of peripherals

        exclude = set([path_string(os.path.expandvars('$HDL_BUILD_DIR')), path_string(os.path.join(os.path.expandvars('$RADIOHDL'),'tools'))])
        if root_dir is not None:
            for root, dirs, files in os.walk(self.root_dir, topdown=True):#topdown=False):
                #logger.debug("root is {}".format(root))
                #logger.debug("dirs is {}".format(dirs))
                dirs[:] = [d for d in dirs if path_string(root+d) not in exclude and '.svn' not in d]
                for name in files:
                    #print("loop through files, name is {}".format(name))
                    #if self.file_extension in name and name[0]!='.':
                    if name.endswith(self.file_extension) and name[0]!='.':
                        #logger.debug("*** PARSING {} ****".format(os.path.join(root,name)))
                        try :
                            library_config = yaml.load(open(os.path.join(root,name), 'r'))
                            #print(library_config)
                        except :
                            logger.error('Failed parsing YAML in {}. Check file for YAML syntax errors'.format(name))
                            print('\nERROR:\n')
                            print(sys.exc_info()[1])
                            sys.exit()
                        if not isinstance(library_config, dict):
                            logger.warning('File {} is not readable as a dictionary, it will not be'
                            ' included in the RadioHDL library of ARGS peripherals'.format(name))
                            continue
                        else:
                            try:
                                library_config['schema_type']
                                library_config['peripherals']
                                library_config['hdl_library_name']
                            except KeyError:
                                logger.warning('File {0} will not be included in the RadioHDL library. '
                                '{0} is missing schema_type and/or peripherals and/or hdl_library_name key'.format(name))
                                continue
                        lib_name = library_config['hdl_library_name']#name.replace(file_extension, '')
                        if lib_name != name.split('.')[0]:
                            logger.error("File {} has mismatching filename \'{}\' and hdl_library_name \'{}\'".format(os.path.join(root,name), name.split('.')[0], lib_name))
                            sys.exit()
                        if self.library.get(lib_name, None) is None: # check peripheral library name is unique
                            self.library.update({lib_name: {'file_path':root,'file_path_name':os.path.join(root,name), 'peripherals':collections.OrderedDict(), 'description':library_config.get('hdl_library_description', "") }})
                        else :
                            logger.error("More than one instance of args peripheral library '{}' found under {}".format(lib_name, root_dir))
                            logger.error("\nConflicting files:\n\t{}\n\t{}".format(self.library[lib_name]['file_path_name'], os.path.join(root,name)))
                            sys.exit()

            # list of peripheral configurations that are read from the available peripheral files
            self.read_all_peripheral_files()

    def read_all_peripheral_files(self, file_path_names=None):
        """Read the peripheral information from all peripheral files that were found in the root_dir tree."""
        self.peripherals = {}
        if file_path_names is None:
            # file_path_names = self.file_path_names
            file_path_names = [lib_dict['file_path_name'] for lib_dict in self.library.values()]
        for fpn in file_path_names:
            logger.info("Load peripheral(s) from '%s'", fpn)
            library_config = yaml.load(open(fpn, 'r'))
            for peripheral_config in library_config['peripherals']:
                lib = library_config['hdl_library_name']
                peripheral_config['lib'] = library_config['hdl_library_name'] #TODO: get rid of need for this
                try :
                    peripheral = deepcopy(Peripheral(peripheral_config))
                except ARGSNameError:
                    logger.error("Invalid peripheral_name '{}' in {}.peripheral.yaml".format(peripheral_config['peripheral_name'], lib))
                    sys.exit()
                logger.info("  read peripheral '%s'" % peripheral.component_name())
                self.library[lib]['peripherals'].update({peripheral.component_name():peripheral})
                self.nof_peripherals = self.nof_peripherals + 1
        # self.nof_peripherals = len(self.peripherals)  # number of peripherals
        return

    def find_peripheral(self, periph_name, peripheral_library=None, fpga_library=None):
        """ find peripheral referenced by <lib_name>/<periph_name> or just <periph_name> where possible """
        matching_libs = []
        count = 0
        if peripheral_library is not None:
            if self.library.get(peripheral_library, None) is not None:
                logger.info("Peripheral {} found under library {}".format(periph_name, peripheral_library))
                return self.library[peripheral_library]['peripherals'].get(periph_name, None)
            else :
                logger.error("No peripheral library '{}' found under {}".format(peripheral_library, self.root_dir))
                sys.exit()
                return None
        else :
            # try to find unique instance of peripheral, failing that look for local
            for lib in self.library.keys():
                # periph_names.extend(list(self.library[lib]['peripherals'].keys()))
                if periph_name in self.library[lib]['peripherals'].keys():
                    matching_libs.append(lib)
            # matches = len([name for name in periph_names if name == periph_name])
            matches = len(matching_libs)
            if matches > 1:
                if fpga_library is not None and fpga_library in matching_libs:
                    logger.info("Multiple peripherals named {} found under libs {}, limiting peripheral search to local design library".format(periph_name, ' '.join(matching_libs).upper(), fpga_library))
                    return self.library[fpga_library]['peripherals'].get(periph_name, None)
                else:
                    print(' '.join(matching_libs))
                    logger.error("Multiple peripherals named '{}' found under libs {}, please specify peripheral library for peripheral {} in format \'<lib_name>/{}\'".format(periph_name, ' '.join(matching_libs).upper(), periph_name, periph_name))
                    sys.exit()
            elif matches == 1:
                logger.info("Peripheral {} found under library {}".format(periph_name, matching_libs[0]))
                return self.library[matching_libs[0]]['peripherals'][periph_name]
            else:
                logger.error("No matching peripherals for '{}' found under {}".format(periph_name, self.root_dir))
                sys.exit()
        # if peripheral_library is None:
            # return self.peripherals.get(name, None)
        # return peripheral_library.get(name, None)
        return None

    def show_overview(self, header=True):
        """ print system overview
        """
        if header:
            logger.info("---------------------")
            logger.info("PERIPHERALS OVERVIEW:")
            logger.info("---------------------")

        for peripheral in self.peripherals.values():
            peripheral.show_overview(header=False)


