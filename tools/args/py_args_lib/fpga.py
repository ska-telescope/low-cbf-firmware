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
import copy
import logging
import yaml
import time
import collections
import common as cm
from py_args_lib import *
from peripheral_lib import *
import numpy as np

logger = logging.getLogger('main.fpga')


class FPGA(object):
    """ A System consist of a set of one or more Peripherals.
    """
    def __init__(self, file_path_name=None, periph_lib=None):
        self.file_path_name  = file_path_name
        self.root_dir        = os.environ['RADIOHDL']
        if periph_lib is None:
            self.peri_lib        = PeripheralLibrary(self.root_dir)
        else :
            self.peri_lib = periph_lib
        self.system_name     = ""
        self.fpga_description = ""
        self.parameters      = {}
        # self.peripherals     = {}
        self.peripherals = collections.OrderedDict()
        self.valid_file_type = False
        self.nof_lite = 0
        self.nof_full = 0
        self.address_map = collections.OrderedDict()
        logger.debug("***FPGA object instantiation: creating for {}".format(file_path_name))

        if file_path_name is None:
            logger.debug("No system configuration file specified")
            self.system_config = None
            self.system        = None
        else:
            # list of peripheral configurations that are read from the available peripheral files
            self.system_config = self.read_system_file(file_path_name)
            self.create_system()

    def is_valid(self):
        """ return False or True if the given file is a valid system file """
        return self.valid_file_type

    def read_system_file(self, file_path_name):
        """Read the system information from the file_path_name file."""

        logger.info("Load system from '%s'", file_path_name)
        system_config = yaml.load(open(file_path_name, 'r'))

        self.valid_file_type = True
        return system_config


    def create_system(self):
        """ Create a system object based on the information in the system_config """
        logger.debug("Creating system")
        logger.debug("Instantiating the peripherals from the peripheral Library")
        # self.system_name = self.system_config['hdl_library_name']
        self.system_name = self.system_config['fpga_name']
        config = self.system_config

        if "fpga_description" in config:
            self.fpga_description = copy.deepcopy(config['fpga_description'])

        if "parameters" in config:
            _parameters = copy.deepcopy(config['parameters'])

            # keys with '.' in the name indicate the use of a structs
            # inside this class it is a dict in a dict
            for parameter_set in _parameters:
                name  = parameter_set['name']
                value = parameter_set['value']
                if '.' in name:
                    _struct, _key = name.split('.')
                    if _struct not in self.parameters:
                        self.parameters[_struct] = {}

            remove_list = []
            for parameter_set_nr, parameter_set in enumerate(_parameters):
                name  = parameter_set['name']
                value = parameter_set['value']
                if '.' in name: # struct notation with dot
                    _struct, _name = name.split('.')
                    self.parameters[_struct][_name] = self._eval(str(value))
                else:
                    self.parameters[name] = self._eval(str(value))
                remove_list.append((parameter_set_nr, name))

            for parameter_set_nr, name in sorted(remove_list, reverse=True):
                logger.debug("delete '%s' from parameters", name)
                del _parameters[parameter_set_nr]

            for parameter_set in _parameters:
                name  = parameter_set['name']
                value = parameter_set['value']
                logger.debug("eval of name=%s and value=%s not posible", name, value)


            logger.debug("parameters={}".format(self.parameters))

        for peripheral_config in config['peripherals']:
            # (Deep)Copy the peripheral from the library in order to avoid creating a reference
            component_name         = peripheral_config['peripheral_name'] if '/' not in peripheral_config['peripheral_name'] else peripheral_config['peripheral_name'].split('/')[1]
            component_lib          = None if '/' not in peripheral_config['peripheral_name'] else peripheral_config['peripheral_name'].split('/')[0]
            component_prefix       = peripheral_config.get('peripheral_group',None)
            number_of_peripherals  = int(self._eval(peripheral_config.get('number_of_peripherals', 1)))

            peripheral_from_lib = copy.deepcopy(self.peri_lib.find_peripheral(component_name, component_lib, self.system_name))
            if peripheral_from_lib is None:
                logger.error("Peripheral component '{}' referenced in {}.fpga.yaml not found in "
                "peripheral library {}".format(component_name, self.system_name, '\'' + component_lib + '\'' if component_lib is not None else ''))
                sys.exit()

            logger.debug(" Finding %s", peripheral_from_lib.name())

            if 'parameter_overrides' in peripheral_config:
                logger.debug("parameters={}".format(peripheral_config['parameter_overrides']))
                for parameter_set in peripheral_config['parameter_overrides']:
                    name  = parameter_set['name']
                    value = parameter_set['value']
                    peripheral_from_lib.parameter(key=name, val=self._eval(value))


            if 'slave_port_names' in peripheral_config:
                logger.debug("slave_port_names={}".format(peripheral_config['slave_port_names']))
                for slave_nr, slave_port_name in enumerate(peripheral_config['slave_port_names']):
                    peripheral_from_lib.set_user_defined_slavename(slave_nr, slave_port_name)

            peripheral_from_lib.number_of_peripherals(number_of_peripherals)
            peripheral_from_lib.prefix(component_prefix)
            peripheral_name = []
            if component_prefix not in (None, ''):
                peripheral_name.append(component_prefix)
            peripheral_name.append(component_name)
            peripheral_from_lib.name('_'.join(peripheral_name))

            if peripheral_from_lib.name() not in self.peripherals:
                self.peripherals[peripheral_from_lib.name()] = copy.deepcopy(peripheral_from_lib)
            else:
                logger.error("  Duplicate found: use unique labels per instance in %s.fpga.yaml to distinguish "
                                "between multiple instances of the same peripheral.\n"
                                "  Cannot add a second instance of peripheral: %s",
                                self.system_name, peripheral_from_lib.name())
                sys.exit()

        logger.debug("Start evaluating the peripherals")
        for peripheral_config in self.peripherals.values():
            peripheral_config.eval_peripheral()

        self.create_address_map()
        return

    def _eval(self, val):
        """ evaluate val.
        1) trying to parse values of known parameter into the value
        2) eval the value, known imported function are also evaluated """

        _val = str(val)
        # first replace all knowns parameter names with its assigned value
        for key1, val1 in iter(self.parameters.items()):
            # if val is a dict, in vhdl it's a struct
            if isinstance(val1, dict):
                for key2, val2 in iter(val1.items()):
                    key = "{}.{}".format(key1, key2)
                    # logger.debug("replace %s with %s", key, str(val2))
                    _val = _val.replace(key, str(val2))
            else:
                # logger.debug("replace %s with %s", key1, str(val1))
                _val = _val.replace(key1, str(val1))
        result = eval(_val)
        logger.debug("_eval(%s) returns eval(%s) = %s", str(val), _val, str(result))
        return result

    def create_address_map(self):
        """ Preserves order of entry from fpga.yaml
            Based on vivado limitations, minimum span is 4kB
            Configurable ranges are 4k, 8k, 16k, 32k, 64k i.e. 2^(12,13,14,15,16)
            There is a maximum of one register group per peripheral
        """
        print("[fpga.py] create_address_map('{:s}')".format(self.system_name))

        # Largest peripheral will determine spacing between peripheral base addresses
        largest_addr_range = 4096 # minimal allowed address-decode spacing with Xilinx interconnect
        for peripheral in self.peripherals.values():
            if peripheral.reg_len > largest_addr_range:
                largest_addr_range = peripheral.reg_len
        peripheral_spacing = cm.ceil_pow2(largest_addr_range)

        lowest_free_addr = 0
        for peripheral in self.peripherals.values():
            # Ensure peripheral base is aligned to address decode
            lowest_free_addr = int(np.ceil(lowest_free_addr/peripheral_spacing)*peripheral_spacing)
            p_nam = peripheral.name()
            if len(p_nam) > 20:
                p_nam = p_nam[0:20]
            pad = ' ' * (21-len(peripheral.name()))
            print('** PERIPHERAL: {} {}base_addr=0x{:08x} [occupied size=0x{:x}]'.format(p_nam, pad, lowest_free_addr, peripheral.reg_len))
            # assigned_reg = False
            # _nof_regs =  sum([isinstance(slave, Register) for slave in peripheral.slaves])
            # _minus_regs = _nof_regs - 1 if _nof_regs > 0 else 0
            # _nof_slaves = len(peripheral.slaves) - _minus_regs
            for periph_num in range(peripheral.number_of_peripherals()):
                assigned_reg = False
                for slave in peripheral.slaves:
                    if isinstance(slave, Register) and not getattr(slave, 'isIP', False):
                        if assigned_reg == False: #calc for entire register slave port
                            reg_span = cm.ceil_pow2(max(peripheral.reg_len, 4096))
                            lowest_free_addr = int(np.ceil(lowest_free_addr/reg_span)*reg_span)
                            register_base = lowest_free_addr
                        else :
                            self.nof_lite = self.nof_lite - 1
                            lowest_free_addr = register_base + (slave.base_address() if not any(slave.rams) else slave.rams[0].base_address())
                        ram_span = slave.base_address() - slave.rams[0].base_address() if any(slave.rams) else  0 
                        slave_span = slave.address_length()*slave.number_of_slaves()+ram_span
                        slave_port_name = peripheral.name() + '_' + slave.name() + (('_' + str(periph_num)) if peripheral.number_of_peripherals() > 1 else '')
                        self.address_map[slave_port_name] = {'base':lowest_free_addr,'span':slave_span,'type':'LITE','port_index':self.nof_lite,'peripheral':peripheral,'periph_num':periph_num,'slave':slave}
                        logger.info("Register for %s has span 0x%x", peripheral.name(), slave_span)
                        lowest_free_addr = lowest_free_addr + int(slave_span)
                        self.nof_lite = self.nof_lite + 1
                        assigned_reg = True

                    elif isinstance(slave, Register) and getattr(slave, 'isIP', False):
                        slave_span = cm.ceil_pow2(max(slave.address_length()*slave.number_of_slaves(), 4096)) #slave.address_length()*slave.number_of_slaves()#
                        lowest_free_addr = int(np.ceil(lowest_free_addr/slave_span)*slave_span)
                        slave_port_name = peripheral.name() + '_' +  slave.name() #+ '_reg_ip'
                        self.address_map[slave_port_name] =  {'base':lowest_free_addr, 'span':slave_span, 'type':slave.protocol, 'port_index':eval("self.nof_{}".format(slave.protocol.lower())),'peripheral':peripheral,'periph_num':periph_num,'slave':slave}
                        if slave.protocol.lower() == 'lite':
                            self.nof_lite = self.nof_lite + 1
                        else :
                            self.nof_full = self.nof_full + 1
                        lowest_free_addr = lowest_free_addr + slave_span

                    elif isinstance(slave, RAM):
                        slave_type = 'ram'
                        size_in_bytes =  np.ceil(slave.width()/8)*slave.address_length()*cm.ceil_pow2(slave.number_of_slaves())
                        slave_span = cm.ceil_pow2(max(size_in_bytes, 4096))
                        logger.info("Slave %s has span 0x%x", peripheral.name() + '_' + slave.name() , slave_span)
                        # slave_name = slave.name() + ('_{}'.format(slave_no) if slave.number_of_slaves() >1 else '')
                        lowest_free_addr = int(np.ceil(lowest_free_addr/slave_span)*slave_span)
                        slave_port_name = peripheral.name() + '_' + slave.name() + '_' + slave_type+ (('_' + str(periph_num)) if peripheral.number_of_peripherals() > 1 else '')
                        self.address_map[slave_port_name] = {'base':lowest_free_addr,'span':slave_span,'type':'FULL','port_index':self.nof_full,'peripheral':peripheral,'periph_num':periph_num,'slave':slave}
                        self.nof_full = self.nof_full + 1
                        lowest_free_addr = lowest_free_addr + slave_span

                    elif isinstance(slave, FIFO):
                        slave_type = 'fifo'
                        size_in_bytes =  np.ceil(slave.width()/8)*slave.address_length()
                        slave_span = cm.ceil_pow2(max(size_in_bytes, 4096))
                        for i in range(slave.number_of_slaves()):
                            lowest_free_addr = int(np.ceil(lowest_free_addr/slave_span)*slave_span)
                            slave_port_name = peripheral.name() + '_' + slave.name() + '_' + slave_type+ (('_' + str(periph_num)) if peripheral.number_of_peripherals() > 1 else '') + ('_{}'.format(i) if slave.number_of_slaves() > 1 else '')
                            self.address_map[slave_port_name] = {'base':lowest_free_addr,'span':slave_span,'type':'FULL','port_index':self.nof_full,'access':slave.access_mode(),'peripheral':peripheral,'periph_num':periph_num,'slave':slave}
                            self.nof_full = self.nof_full + 1
                            lowest_free_addr = lowest_free_addr + slave_span

                    #if slave_span > 65536:
                    #    logger.error("Slave %s has slave span %d. Maximum slave span in Vivado Address Editor is 64kB", slave.name(), slave_span)
                    #    sys.exit()

    def show_overview(self):
        """ print system overview
        """
        logger.info("----------------")
        logger.info("SYSTEM OVERVIEW:")
        logger.info("----------------")
        logger.info("System name '%s'", self.system_name)
        logger.info("- System parameters:")
        for key, val in iter(self.parameters.items()):
            if isinstance(val, dict):
                for _key, _val in val.items():
                    logger.info("  %-25s  %s", "{}.{}".format(key, _key), str(_val))
            else:
                logger.info("  %-20s  %s", key, str(val))
        logger.info("- System Address Map:")
        for slave_name, attributes in self.address_map.items():
            logger.info("  %-30s 0x%x, range %dkB at port MSTR_%s[%d]", slave_name, attributes['base'], attributes['span']/1024, attributes['type'],attributes['port_index'])
        logger.info("- Peripherals:")
        for peripheral in sorted(self.peripherals):
            self.peripherals[peripheral].show_overview(header=False)

class FPGALibrary(object):
    """
    List of all information for FPGA config files in the root dir, intended for use in hdl_config.py
    """

    def __init__(self, root_dir=None):
        self.root_dir = root_dir
        self.file_extension = ".fpga.yaml"
        self.library = {}
        self.nof_peripherals = 0
        tic = time.time()
        if root_dir is not None:
            for root, dirs, files in os.walk(self.root_dir, topdown = True):
                if 'tools' not in root:
                    for name in files:
                        if self.file_extension in name:
                            try :
                                library_config = yaml.load(open(os.path.join(root,name),'r'))
                            except:
                                logger.error('Failed parsing YAML in {}. Check file for YAML syntax errors'.format(name))
                                print('ERROR:\n' + sys.exc_info()[1])
                                sys.exit()
                            if not isinstance(library_config, dict):
                                logger.warning('File {} is not readable as a dictionary, it will not be'
                                ' included in the FPGA library of peripherals'.format(name))
                                continue
                            lib_name = name.replace(self.file_extension, '')
                            logger.info("Found fpga.yaml file {}".format(lib_name))
                            if lib_name in self.library:
                                logger.warning("{} library already exists in FPGALibrary, being overwritten".format(lib_name))
                            self.library[lib_name] = {'file_path':root, 'file_path_name':os.path.join(root,name), 'peripherals':{}}
        toc = time.time()
        logger.debug("FPGALibrary os.walk took %.4f seconds" %(toc-tic))
        self.read_all_fpga_files()

    def read_all_fpga_files(self, file_path_names=None):
        """
           Read the information from all FPGA files that were found in the root_dir tree
        """

        self.fpgas = {}
        periph_lib = PeripheralLibrary(self.root_dir)
        if file_path_names is None:
            file_path_names = [lib_dict['file_path_name'] for lib_dict in self.library.values()]
        for fpn in file_path_names:
            logger.info("Creating ARGS FPGA object from {}".format(fpn))
            tic = time.time()
            fpga = FPGA(fpn, periph_lib=periph_lib)
            toc = time.time()
            logger.debug("fpga creation for %s took %.4f seconds" %(fpn, toc-tic))
            fpga.show_overview()
            self.library[fpga.system_name].update({'fpga':fpga})
            for lib, peripheral in fpga.peripherals.items():
                self.library[fpga.system_name]['peripherals'].update({lib:peripheral})
