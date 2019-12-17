#! /usr/bin/env python3
###############################################################################
#
# Copyright (C) 2017
# CSIRO (Commonwealth Scientific and Industrial Research Organization) <http://www.csiro.au/>
# GPO Box 1700, Canberra, ACT 2601, Australia
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
#   Author           Date      Version comments
#   Keith Bengsotn   Nov 2018  Original
#
###############################################################################

"""
    Generate Address Map for usage in C software.
    Lists every 'field' in the fpga.yaml and peripheral.yaml files
    ordered by address in the address map.
"""

import sys
import os
#import logging
from argparse import ArgumentParser
#from py_args_lib import FPGA, RAM, FIFO, Register, PeripheralLibrary, FPGALibrary
from py_args_lib import  RAM, FIFO, Register, FPGALibrary
#from common import ceil_pow2
#import pprint
#import code

#logging.basicConfig(stream=sys.stdout, level=logging.INFO)

def gen_c_config(fpga, fpga_name, out_dir):
    """
    Generate adderss map
        fpga: all fpga.yaml files found in system
        fpga_name: the particular fpga we're interested in
        out_dir: the directory in which output should be written
    """
    out = [] # list to hold text lines to be written to output .ccfg file
    out.append("# Peripherals for {}:\n".format(fpga_name))
    field_count = 0 # count of number of fields found in FPGA address map
#    for periph_name, periph_info in fpga['fpga'].address_map.items():

    # Multiple peripherals can be assigned the same port.
    # When this occurs, they all have the same base address, and addresses are all 
    # relative to that base address.
    # But fpga['fpga'].address_map.base is the base for that peripheral, not for the port.
    # So go through and build a list of the smallest base addresses for each peripheral, and 
    # use that as the base address.
    port_base_dict_lite = dict()  # for axi4_lite slaves
    port_base_dict_full = dict()  # for axi4_full slaves
    for periph_info in fpga['fpga'].address_map.values():
        print(periph_info)
        base = int(periph_info['base']/4)
        port = int(periph_info['port_index'])
        type = periph_info['type']
        #print('port = ' + str(port) + ', base = ' + str(base))
        if (type == 'LITE'):
            if port in port_base_dict_lite:
                if (port_base_dict_lite[port] > base):
                    port_base_dict_lite[port] = base;
            else:
                port_base_dict_lite[port] = base
        else: # type is full
            if port in port_base_dict_full:
                if (port_base_dict_full[port] > base):
                    port_base_dict_full[port] = base;
            else:
                port_base_dict_full[port] = base
        
    print('---- port_base_dict_lite -')
    print(port_base_dict_lite)
    print('----')
    print('---- port_base_dict_full -')
    print(port_base_dict_full)
    print('----')
    
    for periph_info in fpga['fpga'].address_map.values():

        #print('--------------------')
        #print(periph_info['peripheral'])
        #print('--------------------')

        peripheral = periph_info['peripheral']
        p_num = int(periph_info['periph_num'])
        pname = peripheral.name()
        count = peripheral.number_of_peripherals()
        base = int(periph_info['base']/4)   # start address of this slave.
        span = int(periph_info['span']/4) # span can be incorrect (bug in pyargslib?)
        typ = periph_info['type']
        port = int(periph_info['port_index'])
        txt = ('#  peripheral={} start=0x{:04X} span=0x{:04X} type={}'
               ' count={:02} idx={} stop=0x{:04X}').format(
                   pname, base, span, typ, count, p_num, base+count*span)
        out.append(txt+'\n')

        slave = periph_info['slave']
        
        #print('----------------')
        #print(slave.name())
        #print('base = ' + str(base))
        #for fld in slave.fields:
        #    print(str(fld.address_offset()) + ':')   -- these always count from 0
        
        num_slaves = slave.number_of_slaves()
        slave_name = slave.name()
        if isinstance(slave, RAM):
            out.append('#   RAM-SLAVE={:20}\n'.format(slave.name()))
            ram_base = base
            ram_len = int(slave.address_length())
            ram_name = 'data'
            access = slave.access_mode()
#            width = slave.width() # Should be slave.user_width() ??
            for i in range(0, num_slaves):
                txt = '      BlockRAM   0x{:08X} len={} {}'.format(
                    ram_base + i*ram_len, ram_len, access)
                if p_num == 0:
                    txt += ' {}'.format(pname)
                else:
                    txt += ' {}[{}]'.format(pname, p_num)
                if num_slaves == 1:
                    txt += ' {} {}'.format(slave_name, ram_name)
                    out.append(txt+'\n')
                else:
                    out.append(txt + ' {}[{}] {}\n'.format(slave_name, i, ram_name))
                field_count += 1
        elif isinstance(slave, FIFO):
            out.append('#   FIFO-SLAVE={:20}\n'.format(slave.name()))
            fifo_base = base
            fifo_len = int(slave.address_length())
            fifo_name = 'data'
            access = slave.access_mode()
#            width = slave.width() # Should be slave.user_width() ??
            for i in range(0, num_slaves):
                txt = '      FIFO       0x{:08X} len={} {}'.format(
                    fifo_base + i*fifo_len, fifo_len, access)
                if p_num == 0:
                    txt += ' {}'.format(pname)
                else:
                    txt += ' {}[{}]'.format(pname, p_num)
                if num_slaves == 1:
                    txt += ' {} {}'.format(slave_name, fifo_name)
                    out.append(txt + '\n')
                else:
                    out.append(txt + ' {}[{}] {}\n'.format(slave_name, i, fifo_name))
                field_count += 1
        elif isinstance(slave, Register):
            out.append('#   REG-SLAVE={} no.slaves={} len={} (base=0x{:X})\n'.format(
                slave.name(), slave.number_of_slaves(), int(slave.address_length()),
                int(slave.base_address()/4)))
            # Fields that have a non-unity 'number_of_fields' specifier may
            #   become RAM at the start of the slave instances
            for ram in slave.rams:
                
                #ram_base = int(ram.base_address()/4)+base
                if (typ == 'LITE'):
                    ram_base = int(ram.base_address()/4) + port_base_dict_lite[port]
                else:
                    ram_base = int(ram.base_address()/4) + port_base_dict_full[port]
                    
                ram_len = int(ram.number_of_fields())
                ram_name = ram.name()
                access = ram.access_mode()
                for i in range(0, num_slaves):
                    txt = '      DistrRAM   0x{:08X} len={} {}'.format(
                        ram_base + i*ram_len, ram_len, access)
                    if p_num == 0:
                        txt += ' {}'.format(pname)
                    else:
                        txt += ' {}[{}]'.format(pname, p_num)
                    if num_slaves == 1:
                        txt += ' {} {}'.format(slave_name, ram_name)
                        out.append(txt + '\n')
                    else:
                        out.append(txt + ' {}[{}] {}\n'.format(slave_name, i, ram_name))
                    field_count += 1
#                if num_slaves == 1:
#                    out.append('      DistrRAM   0x{:08X} len={} {} {} {} {}'.format(
#                        ram_base, ram_len,access,pname,slave_name, ram_name))
#                else:
#                    for i in range(0,num_slaves):
#                        out.append('      DistrRAM   0x{:08X} len={} {} {} {} {}[{}]'.format(
#                             ram_base+i*ram_len, ram_len,access,pname, slave_name, ram_name, i))

            if (typ == 'LITE'):
                field_base = port_base_dict_lite[port] + int(slave.base_address()/4)
            else:
                field_base = port_base_dict_full[port] + int(slave.base_address()/4)
            
            #field_base = base
            #if slave.rams:
            #    field_base += int(slave.base_address()/4)

            # All other fields (with unity 'number_of_fields' attribute)
            slave_length = int(slave.address_length()/4)
            for i in range(0, num_slaves):
                for fld in slave.fields:
                    bit_lo = fld.bit_offset()
                    bit_hi = bit_lo+fld.width()-1
                    #field_base = f.base_address
                    field_offset = int(fld.address_offset()/4)
                    field_name = fld.name()
                    access = fld.access_mode()
                    if field_name == 'args_map_build':
                        _build = fld.reset_value()

                    #if (i == 0):
                    #    print('field_offset = ' + str(field_offset) + ', field_base = ' + str(field_base))

                    txt = '      BitField   0x{:08X} b[{}:{}] {}'.format(
                        field_offset+field_base+i*slave_length, bit_hi, bit_lo, access)
                    if p_num == 0:
                        txt += ' {}'.format(pname)
                    else:
                        txt += ' {}[{}]'.format(pname, p_num)
                    if num_slaves == 1:
                        txt += ' {} {}'.format(slave_name, field_name)
                    else:
                        txt += ' {}[{}] {}'.format(slave_name, i, field_name)
                    out.append(txt+'\n')
                    field_count += 1

    # Write all text lines held in list 'out' to file
    output_filename = out_dir + fpga_name + '.ccfg'
    with open(output_filename, 'w') as out_file:
        if '_build' in locals():
            line = '      FirmwareVersion 0x{:08x}\n'.format(_build)
            out_file.write(line)
        for line in out:
            out_file.write(line)
    print("Found {} fields in FPGA '{}'".format(field_count, fpga_name))
    print('Wrote: {}'.format(output_filename))



if __name__ == '__main__':

    parser = ArgumentParser(
        description='ARGS tool script to generate fpgamap.py M&C Python client include file')
    parser.add_argument('-f', '--fpga', required=True, help='ARGS fpga_name')
    fpga_name = parser.parse_args().fpga

    # Find and parse all *.fpga.yaml YAML files under root directory for RADIOHDL
    # For each FPGA file it extracts a list of the peripherals that are used by that FPGA
    # Here we select the FPGA YAML that matches up with the supplied fpga command line argument
    libRootDir = os.path.expandvars('$RADIOHDL')
    fpga = FPGALibrary(root_dir=libRootDir).library[fpga_name]

    # Check that the output directory exists
    out_dir = os.path.expandvars('$HDL_BUILD_DIR/ARGS/{}/'.format(fpga_name))
    try:
        os.stat(out_dir)
    except:
        print("Error output directory '{}' does not exist".format(out_dir))
        sys.exit()

    # create the summary file in the output directory
    gen_c_config(fpga, fpga_name, out_dir)
