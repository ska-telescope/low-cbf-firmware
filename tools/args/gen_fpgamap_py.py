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
#   John Matthews    Dec 2017  Original
#
###############################################################################

"""
    Generate fpgamap.py M&C Python client include file
"""

import sys
import os
import logging
from argparse import ArgumentParser
from py_args_lib import FPGA, RAM, FIFO, Register, PeripheralLibrary, FPGALibrary
from common import ceil_pow2
import pprint
import code

#logging.basicConfig(stream=sys.stdout, level=logging.INFO)
logger = logging.getLogger('main.fpgamap')

def genPython(fpga, fpgaName, readable):
    _build = None # args build timestamp, from 'args_map_build' field.
    slavePorts={}
    slaveTypeOffset = {}
    print("Including slave ports for {}:".format(fpgaName))
    for slavePortName, slavePortInfo in fpga['fpga'].address_map.items():
        if slavePortInfo['periph_num'] > 0: continue
        #print("slavePortName %s, slavePortInfo %s" % (slavePortName, slavePortInfo))
        peripheral = slavePortInfo['peripheral']
        slave = slavePortInfo['slave']
        base = int(slavePortInfo['base']/4)  # Convert from AXI byte address to register address
        pnt = peripheral.name() + slavePortInfo['type'] # Peripheral Name plus slave port Type
        if pnt not in slaveTypeOffset:
            slaveTypeOffset[pnt] = base
        if peripheral.name() not in slavePorts:
            slavePorts[peripheral.name()] = { 'slaves':{}, 'start':base, 'span':int(slavePortInfo['span']/4), 'count':peripheral.number_of_peripherals() }
        else:
            slavePorts[peripheral.name()]['span'] += int(slavePortInfo['span']/4)
        slaves = slavePorts[peripheral.name()]['slaves']
        # slave atual start address and addresses reported for each slave diverge when block RAM is in play?
        # appears to be something to do with LITE vs FULL type.
        # e.g. cap128ctrl slave starts at 65536 (and fields within slave are correctly offset vs that),
        # but is part of a capture128bit peripheral that starts at 49152, with a 16384 long BlockRAM first. 
        # We need to account for this 'extra' 16384 without causing the fields to have wildly negative addresses calculated.
        slaveOffset = base - slaveTypeOffset[pnt]
        slaveStart = base - slavePorts[peripheral.name()]['start'] 
        if isinstance(slave, RAM):
            print(' {} at 0x{:X}'.format(slavePortName,base))
            # Note py_args_lib quirk. RAM slaves include a single named field. There doesn't seem to be any way to recover this
            # from py_args_lib at present. I shall assume that this field is always called "data"
            slaves[slave.name()] = { 'type':'RAM', 'start':slaveOffset, 'step':slave.number_of_fields(), 'stop':slaveOffset+slave.number_of_fields()*slave.number_of_slaves(), 'fields':{ 'data':{ 'start':0, 'step':1, 'stop':slave.number_of_fields(), 'access_mode':slave.access_mode(), 'width':slave.width(), 'default':slave.reset_value(), 'description':slave.field_description(), 'bit_offset':slave.bit_offset() } } }
            #code.interact(local=locals())
        elif isinstance(slave,FIFO):
            print(' {} at 0x{:X}'.format(slavePortName,base))
            # Assume one field per FIFO slave
            # Assume one field per word
            slaves[slave.name()] = { 'type':'FIFO', 'start':slaveOffset, 'step':1, 'stop':slaveOffset+slave.number_of_slaves(), 'fields':{ 'data':{ 'start':0, 'step':1, 'stop':1, 'access_mode':slave.access_mode(), 'width':slave.width(), 'default':slave.reset_value(), 'description':slave.field_description(), 'bit_offset':slave.bit_offset(), 'depth':slave.number_of_fields() } } }
        elif isinstance(slave,Register):
            print(' {} at 0x{:X}'.format(slavePortName,base))
            fields = {}
            maxOffset = -2**32
            stop_address = 0
            for r in slave.rams:
                offset = int(r.base_address()/4) - slaveOffset
                stop_address = offset + (slave.number_of_slaves()-1)*ceil_pow2(r.number_of_fields())+r.number_of_fields()
                fields[r.name()] = {'start':offset, 'step':1, 'stop':stop_address, 'access_mode': r.access_mode(), 'width' : r.width(), 'default':r.reset_value(), 'description':r.field_description(), 'bit_offset':0}
                maxOffset = max(maxOffset, stop_address)
            for f in slave.fields:
                offset = int(f.address_offset()/4) + int(slave.base_address()/4) - slaveOffset
                # Note py_args_lib quirk. When number_of_fields > 1 then numeric field id is added to string field name
                fields[f.name()] = { 'start':offset, 'step':1, 'stop':offset+1, 'access_mode':f.access_mode(), 'width':f.width(), 'default':f.reset_value(), 'description':f.field_description(), 'bit_offset':f.bit_offset() }
                maxOffset = max(maxOffset,offset+1)
                if _build == None and f.name() == 'args_map_build':
                    _build = f.reset_value()
            slaves[slave.name()] = { 'type':'REG', 'start':slaveStart, 'step':maxOffset, 'stop':slaveStart+slave.number_of_slaves()*(maxOffset), 'fields':fields }

    map={}
    for k, v in slavePorts.items():
        map[k] = { 'start':v['start'], 'step':v['span'], 'stop':v['start']+v['count']*v['span'], 'slaves':v['slaves'] }

    pp = pprint.PrettyPrinter(width=300)
    mapStr = pp.pformat(map) if readable else str(map)

    args_dir = os.path.expandvars('$HDL_BUILD_DIR/ARGS')
    try: os.stat(args_dir)
    except: os.mkdir(args_dir)
    out_dir = os.path.join(args_dir, 'py')
    try: os.stat(out_dir)
    except: os.mkdir(out_dir)
    out_dir = os.path.join(out_dir, fpgaName)
    try: os.stat(out_dir)
    except: os.mkdir(out_dir)

    fname = 'fpgamap.py'
    if _build:
        fname = "fpgamap_{:08x}.py".format(_build)
        logger.info("found args_map_build, using filename: {}".format(fname))
    else:
        logger.error("args_map_build not specified, using default filename: {}".format(fname))
    with open(os.path.join(out_dir, fname),'wt') as file:
        file.write("# M&C Python client include file for {} FPGA\n".format(fpgaName))
        file.write("# Note that this file uses register (not AXI byte) addresses and offsets\n".format(fpgaName))
        file.write("FPGAMAP = " + mapStr + "\n")

if __name__ == '__main__':

    parser = ArgumentParser(description='ARGS tool script to generate fpgamap.py M&C Python client include file')
    parser.add_argument('-f','--fpga', required=True, help='ARGS fpga_name')
    parser.add_argument('-r','--readable', action='store_true', help='Generate human readable map file')
    fpgaName = parser.parse_args().fpga
    readable = parser.parse_args().readable

    libRootDir = os.path.expandvars('$RADIOHDL')

    # Find and parse all *.fpga.yaml YAML files under libRootDir
    # For each FPGA file it extracts a list of the peripherals that are used by that FPGA
    # Here we select the FPGA YAML that matches up with the supplied fpga command line argument
    fpga = FPGALibrary(root_dir=libRootDir).library[fpgaName]

    genPython(fpga, fpgaName, readable)

