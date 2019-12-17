#! /usr/bin/env python3
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
#   PD    feb 2017
#
###############################################################################

"""
Generate system rom files

"""

import argparse
import traceback

from math import ceil
from py_args_lib import *

import common as cm


def main():
    """ generate rom_system reg and txt file """
    for systemname in args.system:
        system_filename = "./systems/{}.system.yaml".format(systemname)
        qsys_filename   = "./{}.build.reg".format(systemname)
        rom_system = RomSystem()
        rom_system.read_system(filename=system_filename)
        rom_system.read_qsys_reg(filename=qsys_filename)
        rom_system.map_memory(use_qsys_base_address=args.qsys)
        rom_system.generate_reg_file(write_file=True)  # make ROM_SYSTEM_INFO old style
        rom_system.generate_mif_file(write_file=True)  # make ROM_SYSTEM_INFO old style
        rom_system.generate_reg_file(write_file=True, version=2)  # make ROM_SYSTEM_INFO new style
        rom_system.generate_mif_file(write_file=True, version=2)  # make ROM_SYSTEM_INFO new style
        rom_system.generate_txt_file()  # write ROM_SYSTEM_INFO in readable format to a '.txt' file


class MemoryMapper(object):
    """ Memory class, add registers to memory.
    order:
    1) fixed memory first.
    2) add biggest sizes first.
    """
    def __init__(self):
        self.map   = []  # [start_address, stop_address, size, name, nof_instances, hide_in_reg_file]
        self.names = []  # already used names

    def add(self, name, size, nof_instances, base_address=None, hide_in_reg_file=False):
        """ add memory segment to the memory-map.
        name: name of register entry
        size: size in words of 1 isinstance
        nof_instances: number of instances
        base_address: base address to use, if None, do an autoplace
        """
        # logger.debug("add(%s, %d, %d)", name, size, nof_instances)
        if name.lower() in self.names:
            logger.debug("%s already added, skip this one", name)
            return

        self.names.append(name.lower())

        if base_address is not None:
            end_address = base_address + (size * nof_instances)
            self.map.append({'name': name, 
                             'base_address': base_address, 
                             'end_address': end_address, 
                             'size': size * cm.c_word_sz, 
                             'nof_instances': nof_instances, 
                             'hide_in_reg_file': hide_in_reg_file})
            
            logger.debug("add(): %08x, %08x, %d, %s, %d, %s", 
                         base_address, end_address, (size * cm.c_word_sz), name, nof_instances, str(hide_in_reg_file))
        else:
            _base_address = self._find_start_addr(size*nof_instances)

            self.map.append({'name': name,
                             'base_address': _base_address, 
                             'end_address': _base_address+(size*nof_instances), 
                             'size': size * cm.c_word_sz, 
                             'nof_instances': nof_instances, 
                             'hide_in_reg_file': hide_in_reg_file})
            logger.debug("add(): %08x, %08x, %d, %s, %d, %s",
                         _base_address, _base_address+(size*nof_instances), size * cm.c_word_sz, name, nof_instances, str(hide_in_reg_file))

    def _find_start_addr(self, size):
        """ look for the next address where the size (in bytes) will fit """
        _size = size  # now size in words
        #logger.debug("trying to fit size = %d", _size)
        
        map = self.get_memory_map('base_address')

        map_size = len(map)
        #logger.debug("map-len = {}".format(map_size))
        if map_size == 0:
            return 0
        map_cnt = 0
        while map_cnt < map_size-1:
            #logger.debug("map_cnt={}".format(map_cnt))
            empty_space = map[map_cnt+1][1] - map[map_cnt][2]
            #logger.debug("empty space = %d", empty_space)
            if empty_space > _size:
                start_addr = int(ceil(map[map_cnt][2] / float(_size)) * _size)
                if start_addr + _size < map[map_cnt+1][1]:
                    return start_addr
            map_cnt += 1
        #logger.debug("last map_cnt={}".format(map_cnt))
        #logger.debug("last map = {}".format(self.map[map_cnt]))
        start_addr = int(ceil(map[map_cnt][2] / float(_size)) * _size)
        #logger.debug("end of map, returm {:x}".format(start_addr))
        return start_addr

    def sorted_list_numbers(self, key):
        sorted_list = []
        for reg in self.map:
            sorted_list.append(reg[key])
        sorted_list.sort()
        return sorted_list

    def make_sorted_list(self, key):
        sorted_list = []
        for reg in self.map:
            sorted_list.append(reg[key])
        sorted_list.sort()
        return sorted_list 

    def get_memory_map(self, sort_on='name'):
        """ return sorted memory map on key
        key can be: name, base_address, size
        """
        map = []
        for key in self.make_sorted_list(sort_on):
            for reg in self.map:
                if reg[sort_on] == key:
                    map.append([reg['name'],
                                reg['base_address'], 
                                reg['end_address'], 
                                reg['size'], 
                                reg['nof_instances'], 
                                reg['hide_in_reg_file']])
                    break
        return map

class RomSystem(object):
    """ RomSystem class """
    def __init__(self):
        self.filename        = None
        self.system          = None
        self.qsys_reg        = {}  # read in rom_system_info from old system key=name, val=[base, span]
        #self.address_list    = []
        self.rom_system_info = []
        self.word_size       = 32  # number of bits
        self.memory_mapper = MemoryMapper()

    def read_system(self, filename):
        """ read system configuration file """
        self.filename = filename
        system = System(self.filename)
        if system.is_valid():
            self.system = system
            return True
        return False

    def read_qsys_reg(self, filename=None):
        """ read *.reg file and get register order.
        file format:
        string (1 row) ending with null character, sorted on reg name.
        repeated 'name address span' information, address is word-addressing, span in bytes.
        example:
          AVS_ETH_0_MMS_RAM 4000 4096 AVS_ETH_0_MMS_REG 80 64 AVS_ETH_0_MMS_TSE 2000 4096 PIO_PPS 168 8 NULL.
        To extract order read in sets and order on address.
        """
        qsys_reg = {}
        try:
            with open(filename, 'r') as f:
                data = f.read()
            #logger.debug("read data = %s", str(data))
            data = data[:-2].split()
            n_sets = int(len(data) / 3)
            for i in range(n_sets):
                name, addr, span = data[i*3:i*3+3]
                #print(name, addr, span)
                qsys_reg[name] = [int(addr, 16), int(span, 10)]
        except IOError:
            logger.error("filename '%s' does not excists", filename)
        logger.info("read qsys reg file from build '%s' = %s", filename, str(qsys_reg))
        self.qsys_reg = qsys_reg
        return qsys_reg

    def map_memory(self, use_qsys_base_address=False):
        """ calculate register offsets """

        peripherals = self.system.peripherals

        #print("================")
        #print(peripherals.keys())

        peripheral = peripherals['reg_system_info']
        #print(peripheral.registers)
        base_address = int(peripheral.parameter('lock_base_address'))
        size         = cm.ceil_pow2(int(peripheral.get_slave('reg_system_info').fields['field_reg_info'].number_of_fields()))  # TODO: if not available calculate real size
        name = peripheral.get_slave('reg_system_info').user_defined_name()
        if name  is None:
            name = "reg_system_info"     
        self.memory_mapper.add(name=name, size=size, nof_instances=1, base_address=base_address, hide_in_reg_file=True)

        peripheral = peripherals['rom_system_info']
        base_address    = int(peripheral.parameter('lock_base_address'))
        size            = cm.ceil_pow2(int(peripheral.get_slave('rom_system_info').fields['field_rom_info'].number_of_fields()))  # TODO: if not available calculate real size
        name = peripheral.get_slave('rom_system_info').user_defined_name()
        if name  is None:
            name = "rom_system_info"     
        self.memory_mapper.add(name=name, size=size, nof_instances=1, base_address=base_address, hide_in_reg_file=True)

        size_info = []
        for peripheral in peripherals.values():
            #print(peripheral.component_name())
            if peripheral.component_name() in ('reg_system_info', 'rom_system_info'):
                #print('skip')
                continue
            
            nof_peri_inst = peripheral.number_of_peripherals()
            for rkey, rval in peripheral.rams.items():
                n_addresses = rval.get_kv('address_length')

                nof_inst = rval.number_of_slaves() * peripheral.number_of_peripherals()
                if rval.user_defined_name() is not None:
                    _name = rval.user_defined_name()
                else:
                    _name = rval.name()
                #print("%s %s" % (str(rkey), str(n_addresses)))
                n_addresses = max(n_addresses, 2)
                #print("add")
                size_info.append([n_addresses, nof_inst, _name, False])

            for rkey, rval in peripheral.registers.items():
                n_addresses = rval.get_kv('address_length')
                
                nof_inst = rval.number_of_slaves() * peripheral.number_of_peripherals()
                if rval.user_defined_name() is not None:
                    _name = rval.user_defined_name()
                else:
                    _name = rval.name()
                #print("%s %s" % (str(rkey), str(n_addresses * n_words)))
                #size_info.append([(n_addresses * n_words), nof_inst, _name])
                n_addresses = max(n_addresses, 2)
                #print("add")
                size_info.append([n_addresses, nof_inst, _name, False])

        size_info.sort(reverse=True)
        for size, nof_inst, name, hide_in_reg_file in size_info:
            if use_qsys_base_address:
                _name = name.split('.')

                for i in range(len(_name)-1, -1, -1):
                    if _name[i] == '':
                        del _name[i]

                _qsys_name = []
                if len(_name) == 1:
                    _qsys_name.append(_name[0])
                    name = _name[0]
                elif len(_name) == 2:
                    _qsys_name.append(_name[1])
                    _qsys_name.append(_name[0])
                elif len(_name) == 3:
                    _qsys_name.append(_name[2])
                    _qsys_name.append(_name[0])
                    _qsys_name.append(_name[1])
                elif len(_name) == 4:
                    _qsys_name.append(_name[3])
                    _qsys_name.append(_name[1])
                    _qsys_name.append(_name[2])
                    _qsys_name.append(_name[0])
                else:
                    logger.error("Unknows size for  %s  %s", _name, name)
                qsys_name = '_'.join(_qsys_name).upper()
                #else:
                #    qsys_name = name.upper()
                base_address, qsys_size = self.qsys_reg.get(qsys_name, [None, None])
                if base_address is None:
                    logger.error("%s(%s) not known in qsys.reg", qsys_name, name)
            else:
                base_address = None
            #print(name, base_address, qsys_size, size)
            self.memory_mapper.add(name=name, 
                              size=size, 
                              nof_instances=nof_inst, 
                              base_address=base_address, 
                              hide_in_reg_file=hide_in_reg_file)

        #self.address_list = memory_mapper.get_memory_map()

    def generate_reg_file(self, write_file=False, version=None):
        """ generate qsys '*.reg' file
        if version is None the old way is generated."""

        self.rom_system_info = []
        if version is not None:
            self.rom_system_info.append('{:d}'.format(int(version)))
            logger.debug("generate reg string with starting version number")
        else:
            logger.debug("generate reg string the old way without version number")

        # [start_address, stop_address, size, name, nof_instances]
        for reg in self.memory_mapper.get_memory_map('name'):
            name, start_address, stop_address, size, nof_instances, hide_in_reg_file = reg
            if hide_in_reg_file:
                continue
            # logger.debug("i=%s", str(i))
            if version is None:
                self.rom_system_info.append("{0} {1:x} {2}".format(name.upper(),
                                                                   start_address,
                                                                   size))  # size in bytes
            else:
                self.rom_system_info.append("{0} {1:x} {2} {3}".format(name.upper(),
                                                                       start_address,
                                                                       size,  # size in bytes
                                                                       nof_instances))
        rom_system_info_str = ' '.join(self.rom_system_info) + '\0\0'

        if write_file:
            if version is None:
                filename = "{}.reg".format(self.system.system_name)
            else:
                filename = "{}_V{}.reg".format(self.system.system_name, version)
            logger.debug("Write 'reg' file '%s'", filename)
            logger.debug("ROM_SYSTEM_INFO= %s", rom_system_info_str)
            with open(filename, 'w') as regfile:
                regfile.write(rom_system_info_str)
        return rom_system_info_str

    def generate_mif_file(self, write_file=False, version=None):
        """ generate qsys '*.mif' file
        if version is None the old way is generated."""

        rom_system_info_str = self.generate_reg_file(write_file=False, version=version)

        logger.debug("Convert reg string to mif string")
        mif = []
        mif.append("DEPTH = 1024;")
        mif.append("WIDTH = 32;")
        mif.append("ADDRESS_RADIX = DEC;")
        mif.append("DATA_RADIX = HEX;")
        mif.append("CONTENT BEGIN")
        for cnt in range(int(ceil(len(rom_system_info_str) / 4.0))):
            strword = rom_system_info_str[cnt*4:cnt*4+4]
            if len(strword) < 4:
                strword += '\0' * (4 - len(strword))
            hexword = ''.join(["{:02x}".format(ord(i)) for i in strword])
            mif.append("{} : {};".format(cnt, hexword))
        mif.append("")
        mif.append("END;")
        mif_str = '\n'.join(mif)  # convert to string with line endings

        if write_file:
            if version is None:
                filename = "{}.mif".format(self.system.system_name)
            else:
                filename = "{}_V{}.mif".format(self.system.system_name, version)
            logger.debug("Write 'mif' file '%s'", filename)

            with open(filename, 'w') as miffile:
                miffile.write(mif_str)
        return mif_str


    def generate_txt_file(self):
        """ generate register info file """
        txt = []
        txt.append("address        bytes    n_instances    peripheral_name")
        txt.append("-------        -------  -----------    ---------------")
        # [start_address, stop_address, size, name, nof_instances]
        for reg in self.memory_mapper.get_memory_map('base_address'):
            name, start_address, stop_address, size, nof_instances, hide_in_reg_file = reg
            txt.append("0x{:08x}  {:10d}  {:11d}    {:35s}".format(start_address, size, nof_instances, name.upper()))

        for line in txt:
            logger.info(line)

        filename = "{}.txt".format(self.system.system_name)
        with open(filename, 'w') as f:
            f.write('\n'.join(txt))


if __name__ == "__main__":
    # setup first log system before importing other user libraries
    PROGRAM_NAME = __file__.split('/')[-1].split('.')[0]
    unit_logger.set_logfile_name(name=PROGRAM_NAME)
    unit_logger.set_file_log_level('DEBUG')

    # Parse command line arguments
    parser = argparse.ArgumentParser(description="System and peripheral config command line parser arguments")
    parser.add_argument('-s','--system', nargs='*', default=[], help="system names separated by spaces")
    parser.add_argument('-q','--qsys', action='store_true', default=False, help="Use start address from QSYS reg file")
    parser.add_argument('-v','--verbosity', default='INFO', help="verbosity = [INFO | DEBUG]")
    args = parser.parse_args()

    if not args.system:
        parser.print_help()

    unit_logger.set_stdout_log_level(args.verbosity)
    logger.debug("Used arguments: {}".format(args))

    try:
        main()
    except:
        logger.error('Program fault, reporting and cleanup')
        logger.error('Caught %s', str(sys.exc_info()[0]))
        logger.error(str(sys.exc_info()[1]))
        logger.error('TRACEBACK:\n%s', traceback.format_exc())
        logger.error('Aborting NOW')
        sys.exit("ERROR")
    sys.exit("Normal Exit")