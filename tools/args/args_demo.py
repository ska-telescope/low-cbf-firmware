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
#   PD    mrt 2017
#
###############################################################################


import os
import sys
import argparse
import yaml
import traceback
from subprocess import CalledProcessError
from py_args_lib import *
#from py_args_lib import gen_slave


def main():
    """ main """
    # show info for all requested peripheral
    for peripheralname in args.peripheral:
        peripheral_filename = "./peripherals/{}.peripheral.yaml".format(peripheralname)
        # show_overview(peripheral_filename)
        generate_fw(peripheral_filename)

    # show info for all requested fpgas
    for fpganame in args.fpga:
        fpga_filename = "./fpgas/{}.fpga.yaml".format(fpganame)
        show_overview(fpga_filename)


def show_overview(filename):
    """ show overview of loaded file """
    try:
        config = yaml.load(open(filename, "r"))
        name = config['hdl_library_name']
        print(name)
        
        #settings = config[name]
        if '.fpga.yaml' in filename:
            fpga = FPGA(filename)
            fpga.show_overview()
        elif '.peripheral.yaml' in filename:
            logger.info("Load peripheral(s) from '%s'", filename)
            library_config = yaml.load(open(filename, 'r'))
            for peripheral_config in library_config['peripherals']:
                peripheral = Peripheral(peripheral_config)
                logger.info("  read peripheral '%s'" % peripheral.component_name())
                peripheral.eval_peripheral()
                peripheral.show_overview()
    except IOError:
        logger.error("config file '{}' does not exist".format(filename))

        
def generate_fw(filename): 
    """ generate vhd reg files for loaded file. """
    try: 
        config = yaml.load(open(filename,"r"))
        peripherals = config['peripherals']
        # genSlave = gen_slave.Slave()
        if '.fpga.yaml' in filename:
            # not supported yet
            print("not supported yet")
        elif '.peripheral.yaml' in filename:
            for periph in peripherals: 
                periph['lib'] = config['hdl_library_name']
                peripheral = Peripheral(periph)
                peripheral.eval_peripheral()
                genSlave = gen_slave.Slave(peripheral)
                genSlave.generate_regs(peripheral)
                for key in peripheral.rams:
                    genSlave.generate_mem(peripheral.rams[key],'ram')
                for key in peripheral.fifos:
                    genSlave.generate_mem(peripheral.fifos[key],'fifo')
    except IOError:
        logger.error("config file '{}' does not exist" .format(filename))
    except CalledProcessError:
        pass        

if __name__ == "__main__":
    # setup first log system before importing other user libraries
    PROGRAM_NAME = __file__.split('/')[-1].split('.')[0]
    unit_logger.set_logfile_name(name=PROGRAM_NAME)
    unit_logger.set_file_log_level('DEBUG')

    # Parse command line arguments
    parser = argparse.ArgumentParser(description="""
    =Args demo= 
    fpga and peripheral config command line parser arguments
    """)
    parser.add_argument('-p','--peripheral', nargs='*', default=[], help="peripheral names separated by spaces")
    parser.add_argument('-f','--fpga', nargs='*', default=[], help="fpga names separated by spaces")
    parser.add_argument('-v','--verbosity', default='INFO', help="verbosity level can be [ERROR | WARNING | INFO | DEBUG]")
    args = parser.parse_args()

    if not args.peripheral and not args.fpga:
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

