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
Make automatic documentation

"""

import sys
import os
import argparse
import subprocess
import traceback
import yaml
import time
from subprocess import CalledProcessError
from pylatex import Document, Section, Subsection, Subsubsection, Command, Package, Tabular, MultiColumn, MultiRow, NewLine
from pylatex import SmallText, MediumText, LargeText, HugeText
from pylatex.utils import italic, bold, NoEscape, verbatim, escape_latex

from py_args_lib import *

import common as cm

def main():
    try:
        for systemname in args.system:
            doc = SystemDocumentation(systemname)
            doc.fill()
            doc.make_pdf()
            del doc
            time.sleep(0.5)
        
        for peripheralname in args.peripheral:
            doc = PeripheralDocumentation(peripheralname)
            doc.fill()
            doc.make_pdf()
            del doc
            time.sleep(0.5)

    except IOError:
        logger.error("config file '{}' does not exist".format(filename))


class SystemDocumentation(object):
    def __init__(self, systemname):
        self.systemname = systemname
        self.system_filename = "./systems/{}.system.yaml".format(systemname)
        self.config = yaml.load(open(self.system_filename, "r"))
        
        geometry_options = {"tmargin": "1cm", "lmargin": "2.5cm"}
        self.doc = Document(geometry_options=geometry_options)
        self.doc.preamble.append(Command('title', 'ARGS Documentation for {}'.format(self.systemname)))
        self.doc.preamble.append(Command('author', 'oneclick-args-documentation-script'))
        self.doc.preamble.append(Command('date', NoEscape(r'\today')))
        self.doc.append(NoEscape(r'\maketitle'))

        #self.doc = Documentation(self.config['system_name'])
        self.system = System(self.system_filename)
        
    
    def __del__(self):
        del self.doc
        del self.system
        time.sleep(0.5)

    def fill(self):
        with self.doc.create(Section("{} system.".format(self.config['system_name']))):
            self.doc.append(self.system.system_description)

        with self.doc.create(Section("Peripherals.")):
            added_instances = []
            for peri_name, peri_class in sorted(self.system.peripherals.items()):
                if peri_class.name() in added_instances:
                    continue
                added_instances.append(peri_class.name())

                with self.doc.create(Section(peri_class.name(), numbering=True)):
                    self.doc.append(peri_class.get_kv('peripheral_description').replace('"', ''))
                    self.doc.append(NewLine())
                    
                    #self.doc.append(MediumText(bold("slave ports.")))
        
                    for val_info, val_type in ((peri_class.registers, 'Registers'), 
                                               (peri_class.rams, 'Rams'), 
                                               (peri_class.fifos, 'Fifos')):
                                    
                        if len(val_info) == 0:
                            continue

                        #self.doc.add(text=val_type, size="medium")
                        
                        added_val_types = []
                        for key, val in sorted(val_info.items()):
                            if val.name() in added_val_types:
                                continue
                            added_val_types.append(val.name())
                            
                            with self.doc.create(Subsection("{} slave.".format(val.name().lower()), numbering=True)):
                                if val.get_kv('slave_description') is not None:
                                    self.doc.append(val.get_kv('slave_description').replace('"', ''))
                                added_fields = []
                                for field_key, field_val in sorted(val.fields.items()):
                                    real_name = field_val.name().strip().split('.')[0]
                                    if real_name in added_fields:
                                        continue
                                    added_fields.append(real_name)
                                    with self.doc.create(Subsubsection("{} field.".format("{}".format(real_name)), numbering=True)):
                                        self.doc.append(field_val.get_kv('field_description').replace('"', '') )
                                        #self.doc.append(NewLine())
    
    def make_pdf(self):
        try:
            self.doc.generate_pdf('{}'.format(self.systemname), clean_tex=True)
            time.sleep(0.5)
        except CalledProcessError:
            pass


class PeripheralDocumentation(object):
    def __init__(self, peripheralname):
        self.peripheralname = peripheralname
        self.peripheral_filename = "./peripherals/{}.peripheral.yaml".format(peripheralname)
        self.config = yaml.load(open(self.peripheral_filename, "r"))
        
        geometry_options = {"tmargin": "1cm", "lmargin": "2.5cm"}
        self.doc = Document(geometry_options=geometry_options)
        self.doc.preamble.append(Command('title', 'ARGS Documentation for {}'.format(self.peripheralname)))
        self.doc.preamble.append(Command('author', 'oneclick-args-documentation-script'))
        self.doc.preamble.append(Command('date', NoEscape(r'\today')))
        self.doc.append(NoEscape(r'\maketitle'))

    
    def fill(self):
        with self.doc.create(Section("{} library.".format(self.config['hdl_library_name']))):
            self.doc.append(self.config['hdl_library_description'])

        with self.doc.create(Section("Peripherals.")):
            added_instances = []
            for peri_info in self.config['peripherals']:
                peri_class = Peripheral(peri_info)
                if peri_class.name() in added_instances:
                    continue
                added_instances.append(peri_class.name())

                with self.doc.create(Section(peri_class.name(), numbering=True)):
                    self.doc.append(peri_class.get_kv('peripheral_description').replace('"', ''))
                    self.doc.append(NewLine())
                    
                    #self.doc.append(MediumText(bold("slave ports.")))
        
                    for val_info, val_type in ((peri_class.registers, 'Registers'), 
                                               (peri_class.rams, 'Rams'), 
                                               (peri_class.fifos, 'Fifos')):
                                    
                        if len(val_info) == 0:
                            continue

                        #self.doc.add(text=val_type, size="medium")
                        
                        added_val_types = []
                        for key, val in sorted(val_info.items()):
                            if val.name() in added_val_types:
                                continue
                            added_val_types.append(val.name())
                            
                            with self.doc.create(Subsection("{} slave.".format(val.name().lower()), numbering=True)):
                                if val.get_kv('slave_description') is not None:
                                    self.doc.append(val.get_kv('slave_description').replace('"', ''))
                                added_fields = []
                                for field_key, field_val in sorted(val.fields.items()):
                                    real_name = field_val.name().strip().split('.')[0]
                                    if real_name in added_fields:
                                        continue
                                    added_fields.append(real_name)
                                    with self.doc.create(Subsubsection("{} field.".format("{}".format(real_name)), numbering=True)):
                                        self.doc.append(field_val.get_kv('field_description').replace('"', '') )
                                        #self.doc.append(NewLine())

    def make_pdf(self):
        try:
            self.doc.generate_pdf('{}'.format(self.peripheralname), clean_tex=True)
            time.sleep(0.5)
        except CalledProcessError:
            pass



if __name__ == "__main__":
    # setup first log system before importing other user libraries
    PROGRAM_NAME = __file__.split('/')[-1].split('.')[0]
    unit_logger.set_logfile_name(name=PROGRAM_NAME)
    unit_logger.set_file_log_level('DEBUG')

    # Parse command line arguments
    parser = argparse.ArgumentParser(description="System and peripheral config command line parser arguments")
    parser.add_argument('-s','--system', nargs='*', default=[], help="system names separated by spaces")
    parser.add_argument('-p','--peripheral', nargs='*', default=[], help="peripheral names separated by spaces")
    parser.add_argument('-v','--verbosity', default='INFO', help="verbosity level can be [ERROR | WARNING | INFO | DEBUG]")
    args = parser.parse_args()

    if not args.peripheral and not args.system:
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