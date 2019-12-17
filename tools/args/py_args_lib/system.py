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

import common as cm
from peripheral import PeripheralLibrary

logger = logging.getLogger('main.system')


class System(object):
    """ A System consist of a set of one or more Peripherals.
    """
    def __init__(self, file_path_name=None):
        self.file_path_name  = file_path_name
        self.root_dir        = os.environ['RADIOHDL']
        self.peri_lib        = PeripheralLibrary(self.root_dir)
        self.system_name     = ""
        self.system_description = ""
        self.parameters      = {}
        self.peripherals     = {}
        self.valid_file_type = False

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
        self.system_name = self.system_config['hdl_library_name']
        config = self.system_config

        if "system_description" in config:
            self.system_description = copy.deepcopy(config['system_description'])

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
            component_name         = peripheral_config['peripheral_name']
            component_prefix       = peripheral_config['subsystem_name']
            number_of_peripherals  = int(self._eval(peripheral_config.get('number_of_peripherals', 1)))
            
            peripheral_from_lib = copy.deepcopy(self.peri_lib.find_peripheral(component_name))
            if peripheral_from_lib is None:
                logger.warning("component_name '%s' not found in library", component_name)
                continue

            logger.debug(" Finding %s", peripheral_from_lib.name())

            if 'parameters' in peripheral_config:
                logger.debug("parameters={}".format(peripheral_config['parameters']))
                for parameter_set in peripheral_config['parameters']:
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
            peripheral_from_lib.name('.'.join(peripheral_name))

            if peripheral_from_lib.name() not in self.peripherals:
                self.peripherals[peripheral_from_lib.name()] = copy.deepcopy(peripheral_from_lib)
            else:
                logger.warning("  Duplicate found: use unique labels per instance to distinguish "
                                "between multiple instances of the same peripheral.\n"
                                "  Cannot add a second instance of peripheral: %s",
                                peripheral_from_lib.name())

        logger.debug("Start evaluating the peripherals")
        for peripheral_config in self.peripherals.values():
            peripheral_config.eval_peripheral()
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
        logger.info("- Peripherals:")
        for peripheral in sorted(self.peripherals):
            self.peripherals[peripheral].show_overview(header=False)
