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
from io import StringIO
from subprocess import CalledProcessError
from pylatex import Document, Section, Subsection, Subsubsection, NewPage, Command, Package, LongTable, Tabular,Tabularx, MultiColumn, MultiRow, NewLine, MiniPage
from pylatex import SmallText, MediumText, LargeText, HugeText
from pylatex.base_classes import Environment
from pylatex.utils import italic, bold, NoEscape, verbatim, escape_latex
from copy import deepcopy
from math import ceil

from py_args_lib import *

import common as cm

def gen_reg_tables(subsection, group_fields):
    """
    Takes a list of fields belonging to a field group and a register subsection
    Returns the subsection with fully formatted variable width tables for a field group 

    Needs to support field splitting in the case when field width exceeds 16 

    """
    c_max_chars = 64
    char_sum = 0
    last_bit_boundary = 0
    bit_bounds = [32]
    i = 0
    # iterate through fields and break whenever max chars has been exceeded 
    #print("New field group")
    for field in group_fields[::-1]:
        i = i+1
        field_name = field.name() if field.group_name() == 'None' else field.name().split(field.group_name() + '_')[-1]
        char_sum = char_sum + len(field_name)
        if char_sum > c_max_chars:  
            char_sum = len(field_name)
            bit_bounds.append(last_bit_boundary)
        last_bit_boundary = field.bit_offset()
        if (bit_bounds[-1]-last_bit_boundary) > 16:
                bit_bounds.append(bit_bounds[-1]-16)# still limit to max of  16
                last_bit_boundary = bit_bounds[-1]
        #print("field {} upper {} lower {}".format(field.name(), str(field.bit_offset() + field.width() -1), str(field.bit_offset())))
        #print(*bit_bounds)
    if bit_bounds[-1] != 0 : bit_bounds.append(0) 

    bit_bounds = [32,16,0] if len(bit_bounds) < 3 else bit_bounds
    nof_tables = len(bit_bounds)
    
    # generate columns for fields, mostly useful for gaps, can make it less bulky than the column dictionary 
    for i in range(1, nof_tables): # starts from second bound
        col_list = []
        nof_cols = bit_bounds[i-1]-bit_bounds[i]+1 # nof bits + bit label column
        group_table =  Tabular('|c'*nof_cols+'|')
        group_table.add_hline()
        group_table.add_row((MultiColumn(nof_cols, align='|c|', data='Addr: {}h'.format(str(hex(field.address_offset()))[2:])),))
        group_table.add_hline()
        # group_table.add_row(('Bit',*range(bit_bounds[i-1]-1,bit_bounds[i]-1,-1)))
        row = ['Bit'] + [str(bit) for bit in range(bit_bounds[i-1]-1,bit_bounds[i]-1,-1)]
        group_table.add_row(row)
        group_table.add_hline()
        gap_bit = bit_bounds[i-1] -1 # next available bit, inclusive
        end_bit = bit_bounds[i]
        #print("Table {} bounding {} and {}".format(str(i),str(gap_bit+1), str(end_bit)))
        for field in group_fields[::-1]:
            field_name = field.name() if field.group_name() == 'None' else field.name().split(field.group_name() + '_')[-1]
            upper_bit = field.bit_offset() + field.width() -1 # inclusive 
            # print("field {} has upper bit {} gap bit is {}".format(field_name,str(upper_bit), str(gap_bit)))
            if upper_bit < gap_bit:
                gap_width = min(gap_bit - upper_bit, nof_cols-1)
                col_list.append(MultiColumn(gap_width, align='|c|', data='RES'))
                gap_bit = max(upper_bit, bit_bounds[i]-1)#gap_bit-(nof_cols-1))
                #print("added gap before field {} of width {}".format(field_name, str(gap_width)))
                if gap_bit == (end_bit-1): break;

            #print("field {} bit offset {} should be more or equal to {} and upper bit {} should be less than {}".format(field_name, str(field.bit_offset()), str(bit_bounds[i]), str(upper_bit), str(bit_bounds[i-1])))
            if field.bit_offset() >= end_bit and upper_bit < bit_bounds[i-1]: # field fully contained
                col_list.append(MultiColumn(field.width(), align='|c|', data=field_name))
                #print("added complete field {} of width {}".format(field_name, str(field.width())))
                gap_bit = field.bit_offset()-1
            elif upper_bit >= end_bit and field.bit_offset() < end_bit: # upper partial 
                col_list.append(MultiColumn(upper_bit - bit_bounds[i]+1, align='|c|', data=field_name))
                #print("added upper partial for field {} of width {}".format(field_name, str(upper_bit - bit_bounds[i]+1)))
                gap_bit = bit_bounds[i]-1# end of table 
                break
            elif upper_bit >= bit_bounds[i-1] and field.bit_offset() < bit_bounds[i-1]:# lower partial field 
                col_list.append(MultiColumn(bit_bounds[i-1]-field.bit_offset(),align='|c|',data=field_name))
                #print("added lower partial for field {} of width {}".format(field_name, str(bit_bounds[i-1]-field.bit_offset())))
                gap_bit = field.bit_offset()-1

            if field.bit_offset() == (bit_bounds[i]): break

        if gap_bit != (bit_bounds[i]-1): # bottom gap 
            gap_width = max(0,gap_bit - (bit_bounds[i]-1))
            col_list.append(MultiColumn(gap_width, align='|c|', data='RES'))
            #print("added gap after field {} of width {}".format(field_name, str(gap_width)))
        row = ['Name'] + col_list
        group_table.add_row(row)
        # group_table.add_row(('Name',*col_list,))# add 
        group_table.add_hline()
        subsection.append(group_table)
        subsection.append(NewLine())
        subsection.append(NewLine())
        subsection.append(NewLine())

    return subsection

def main():
    try:
        for fpganame in args.system:
            doc = FPGADocumentation(fpganame, fpga_libs[fpganame])
            doc.fill()
            doc.make_pdf()
            del doc
            time.sleep(0.5)
        
        for peripheralname in args.peripheral:
            doc = PeripheralDocumentation(peripheralname, periph_libs[peripheralname])
            doc.fill()
            doc.make_pdf()
            del doc
            time.sleep(0.5)

    except IOError:
        logger.error("config file '{}' does not exist".format(filename))

# class SamePage(Environment):
    # """ A class to wrap a section in same page environment """
    # packages = [Package('MiniPage')]
    # escape = False # not sure 

class FPGADocumentation(object):
    def __init__(self, fpga_name, fpga_lib):
        self.fpga_name = fpga_name
        self.out_dir = os.path.expandvars('$HDL_BUILD_DIR/ARGS/{}'.format(self.fpga_name))

        try:
            os.stat(os.path.expandvars('$HDL_BUILD_DIR/ARGS/{}'.format(self.fpga_name)))
        except:
            os.mkdir(os.path.expandvars('$HDL_BUILD_DIR/ARGS/{}'.format(self.fpga_name)))
        self.fpga = fpga_lib['fpga']
        self.fpga_lib = fpga_lib
        # self.fpga_filename = "./systems/{}.fpga.yaml".format(fpganame)
        # self.config = yaml.load(open(self.fpga_filename, "r"))
        
        geometry_options = {"tmargin": "1cm", "lmargin": "2.5cm"}
        self.doc = Document(geometry_options=geometry_options)
        self.doc.packages.add(Package('hyperref','bookmarks'))#(Command('usepackage','bookmarks','hyperref'))
        self.doc.preamble.append(Command('title', 'ARGS Documentation for FPGA design \'{}\''.format(self.fpga_name)))
        self.doc.preamble.append(Command('author', 'ARGS script gen_doc.py'))
        self.doc.preamble.append(Command('date', NoEscape(r'\today')))
        self.doc.append(NoEscape(r'\maketitle'))
        self.doc.append(NewLine())
        self.doc.append(bold('FPGA design description\n'))
        self.doc.append(self.fpga.fpga_description)
        self.doc.append(NewLine())
        self.doc.append(NewLine())
        self.doc.append(bold('FPGA design configuration file location\n'))
        self.doc.append(self.fpga_lib['file_path_name'].split('Firmware')[-1])
        self.doc.append(NewLine())
        self.doc.append(Command('tableofcontents'))
        self.doc.append(NewPage())
        #self.doc = Documentation(self.config['system_name'])
        # self.system = System(self.fpga_filename)
        # self.fpga = fpga
        
    
    def __del__(self):
        del self.doc
        del self.fpga
        time.sleep(0.5)

    def fill(self):
        with self.doc.create(Section("{} FPGA system map".format(self.fpga_name))):
            self.doc.append(self.fpga.fpga_description)
            self.doc.append(NewLine())
            self.doc.append(NewLine())
            self.doc.append(MediumText(bold('Slave Port Map')))
            self.doc.append(NewLine())
            self.doc.append(NewLine())
            fpga_system_table = Tabular('|c|c|c|c|c|')
            fpga_system_table.add_hline()
            fpga_system_table.add_row(('Hex','Range (Bytes)','Slave Port','Protocol','Port No.'))
            fpga_system_table.add_hline()

            for slave_port, slave_dict in self.fpga.address_map.items():
                fpga_system_table.add_row((str(hex(slave_dict['base'])),str(slave_dict['span']),slave_port,slave_dict['type'], slave_dict['port_index']))
                fpga_system_table.add_hline()
            self.doc.append(fpga_system_table)

        for periph_name, periph in self.fpga.peripherals.items():
            self.peripheral_fill(periph, periph_name)

        # with self.doc.create(Section("Peripherals.")):
            # added_instances = []
            # for peri_name, peri_class in self.fpga.peripherals.items():#sorted(self.fpga.peripherals.items()):
                # if peri_class.name() in added_instances:
                    # continue
                # added_instances.append(peri_class.name())

                # with self.doc.create(Section(peri_class.name(), numbering=True)):
                    # # self.doc.append(peri_class.get_kv('peripheral_description').replace('"', ''))
                    # self.doc.append(peri_class.get_description().replace('"', ''))
                    # self.doc.append(NewLine())
                    
                    # #self.doc.append(MediumText(bold("slave ports.")))
        
                    # for val_info, val_type in ((peri_class.registers, 'Registers'), 
                                               # (peri_class.rams, 'Rams'), 
                                               # (peri_class.fifos, 'Fifos')):
                                    
                        # if len(val_info) == 0:
                            # continue

                        # #self.doc.add(text=val_type, size="medium")
                        
                        # added_val_types = []
                        # for key, val in sorted(val_info.items()):
                            # if val.name() in added_val_types:
                                # continue
                            # added_val_types.append(val.name())
                            
                            # with self.doc.create(Subsection("{} slave.".format(val.name().lower()), numbering=True)):
                                # if val.get_kv('slave_description') is not None:
                                    # self.doc.append(val.get_kv('slave_description').replace('"', ''))
                                # added_fields = []
                                # for field_key, field_val in sorted(val.fields.items()):
                                    # real_name = field_val.name().strip().split('.')[0]
                                    # if real_name in added_fields:
                                        # continue
                                    # added_fields.append(real_name)
                                    # with self.doc.create(Subsubsection("{} field.".format("{}".format(real_name)), numbering=True)):
                                        # self.doc.append(field_val.get_kv('field_description').replace('"', '') )
                                        # #self.doc.append(NewLine())
    
    def make_pdf(self):
        stdout = sys.stdout # keep a handle on the real standard output
        sys.stdout = StringIO()
        try:
            self.doc.generate_pdf(os.path.join(self.out_dir, self.fpga_name), clean_tex=True)
            time.sleep(0.5)
        except CalledProcessError:
            pass

    def peripheral_fill(self, periph, periph_name):
        self.doc.append(NewPage())
        periph_subsection = Section(periph_name, numbering=True)
        periph_subsection.append(periph.get_description().replace('""',''))  
        periph_reg_section = Subsection("{} register slave".format(periph_name), numbering=False)
        periph_reg_table = Tabular('|c|c|c|c|')
        periph_reg_table.add_hline()
        periph_reg_table.add_row(('Base Address','Range','Register group', 'Number of Slaves'))
        periph_reg_table.add_hline()
        # slave_subsections = ("{} slaves".format(periph_name), numbering=False)
        # slave_subsections = []
        # slave_subsections.append(NewLine())
        # slave_subsections.append(MediumText(bold("Slave Ports for peripheral " + periph_name + "\n")))
        slave_subsections = Subsection("Slave Ports for peripheral \'{}\'".format(periph_name), numbering=False)
        for slave in periph.slaves: 

            #self.doc.add(text=val_type, size="medium")
            
            # added_val_types = []
            # for key, val in sorted(val_info.items()):
                # if val.name() in added_val_types:
                    # continue
                # added_val_types.append(val.name())
            slave_subsection = Subsection("Slave Port: {} ({})".format(slave.name(), 'Register block' if isinstance(slave, Register) else 'RAM' if isinstance(slave, RAM) else 'FIFO'), numbering=True)
            slave_subsection.append(slave.get_kv('slave_description'))
            slave_subsection.append(NewLine())
            # slave_subsection.append("Slave Type: {}".format('REGISTER' if isinstance(slave, Register) else 'RAM' if isinstance(slave, RAM) else 'FIFO'))
            slave_subsection.append(NewLine())
            slave_subsection.append("Address Length: {} bytes".format(str(slave.address_length())))
            slave_subsection.append(NewLine())
            slave_subsection.append("Number of Slaves: {}".format(str(slave.number_of_slaves())))
            slave_subsection.append(NewLine())
            slave_subsection.append(NewLine())
            
            # if val_type == 'Registers':
            if isinstance(slave, Register): # expand registers and fields 
                for ram in slave.rams:
                    periph_reg_table.add_row((str(ram.base_address()), str(ram.number_of_fields()), ram.name() + ' (RAM)', str(slave.number_of_slaves())))
                    periph_reg_table.add_hline()
                periph_reg_table.add_row((str(slave.base_address()),str(slave.address_length()), slave.name(), str(slave.number_of_slaves())))
                periph_reg_table.add_hline()
                added_field_groups = []
                # with self.doc.create(Subsection("{} Register Fields".format(val.name().lower()), numbering=True)):
                # if val.get_kv('slave_description') is not None:
                    # slave_subsection.append(val.get_kv('slave_description').replace('"', ''))
                    
                # generate register table i.e. by word 
                group_address = -1
                group_list = []
                for field in slave.fields:
                    if field.address_offset() != group_address:  
                        group_address = field.address_offset()
                        group_list.append(field)
                        # addr_name = field.group_name() if field.group_name() != "None" else field.name()
                        
                        # slave_table.add_row(str(hex(field.address_offset())), addr_name)
                        # slave_table.add_hline()
                c_max_rows = 30
                nof_cols = ceil(len(group_list)/c_max_rows) # register table has max length of 40 
                nof_rows = min(len(group_list), c_max_rows)
                slave_table = Tabular('|c|c|'*nof_cols)
                slave_table.add_hline()
                # slave_table.add_row((*['Hex','Field Group']*nof_cols))
                slave_table.add_row(['Hex','Field Group']*nof_cols)
                slave_table.add_hline()
                for i in range(nof_rows): 
                    row = []
                    for j in range(nof_cols):
                        if i+c_max_rows*j < len(group_list):
                            field.group_name() if field.group_name() != "None" else field.name()
                            row.extend([str(hex(group_list[i+c_max_rows*j].address_offset())), group_list[i+c_max_rows*j].name()])
                        else : 
                            row.extend(['',''])
                    # slave_table.add_row(*row)
                    slave_table.add_row(row)
                    slave_table.add_hline()

                slave_subsection.append(slave_table)
                slave_subsection.append(NewPage())
                
                group_address = -1
                for field in slave.fields:
                    # if field.group_name() is None or field.group_name() != last_group: # base on group_address instead
                    # print("field {} address {} bit{}".format(field.name(), str(field.address_offset()), str(field.bit_offset())))
                    if field.address_offset() != group_address:  
                        group_address = field.address_offset()
                        # group_page = MiniPage()
                        group_subsection = Subsection('{} {}'.format(str(hex(field.address_offset())), field.name() if field.group_name() == 'None' else field.group_name()),numbering=False)
                        group_fields = [field for field in slave.fields if field.address_offset() == group_address ]
                        if len(group_fields)>10: slave_subsection.append(NewPage())
                        group_subsection = gen_reg_tables(group_subsection, group_fields)
                        for field in group_fields[::-1]:
                            field_name = field.name() if field.group_name() == 'None' else field.name().split(field.group_name() + '_')[-1]
                            bit_string = "Bit {}".format(str(field.bit_offset())) if field.width() == 1 else "Bits {}:{}".format(str(field.bit_offset()+field.width()-1), str(field.bit_offset()))
                            group_subsection.append(bold("{}\t\t{} ({}):".format(bit_string, field_name, field.access_mode())))
                            group_subsection.append("\t\t{}".format(field.field_description()))
                            group_subsection.append(NewLine())
                            group_subsection.append(NewLine())
                        # group_page.append(group_subsection)
                        slave_subsection.append(group_subsection)
            else: # RAM or FIFO
                slave_subsection.append("Data width: {}".format(slave.width()))
                slave_subsection.append(NewLine())
                if isinstance(slave, RAM):
                    slave_subsection.append("User data width: {}".format(slave.user_width()))

            slave_subsections.append(slave_subsection)
        periph_reg_section.append(periph_reg_table)
        self.doc.append(periph_subsection)
        if any([isinstance(slave, Register) for slave in periph.slaves]): self.doc.append(periph_reg_section)
        # for i in range(len(slave_subsections)):
            # self.doc.append(slave_subsections[i])
        self.doc.append(slave_subsections)

        # self.doc.append(periph_section)
        self.doc.append(NewPage())


class PeripheralDocumentation(object):
    def __init__(self, periph_lib_name, periph_lib): # accepts an item from periph_libs 
        self.periph_lib_name = periph_lib_name
        self.periph_lib = periph_lib
        self.out_dir = os.path.expandvars('$HDL_BUILD_DIR/ARGS/{}'.format(self.periph_lib_name))
        try:
            os.stat(os.path.expandvars('$HDL_BUILD_DIR/ARGS'))
        except:
            os.mkdir(os.path.expandvars('$HDL_BUILD_DIR/ARGS'))
        try:
            os.stat(os.path.expandvars('$HDL_BUILD_DIR/ARGS/{}'.format(self.periph_lib_name)))
        except:
            os.mkdir(os.path.expandvars('$HDL_BUILD_DIR/ARGS/{}'.format(self.periph_lib_name)))
        # self.peripheral_filename = "./peripherals/{}.peripheral.yaml".format(peripheralname)
        # self.config = yaml.load(open(self.peripheral_filename, "r"))
        
        geometry_options = {"tmargin": "1cm", "lmargin": "2.5cm"}
        self.doc = Document(font_size='small',geometry_options=geometry_options)
        self.doc.packages.add(Package('hyperref','bookmarks'))
        self.doc.preamble.append(Command('title', 'ARGS Documentation for Peripheral Library \'{}\''.format(self.periph_lib_name)))
        self.doc.preamble.append(Command('author', 'ARGS script gen_doc.py'))
        self.doc.preamble.append(Command('date', NoEscape(r'\today')))
        self.doc.append(NoEscape(r'\hbadness=10000'))
        self.doc.append(NoEscape(r'\maketitle'))
        self.doc.append(NewLine())
        self.doc.append(bold('Peripheral library description\n'))
        self.doc.append(self.periph_lib['description'])
        self.doc.append(NewLine())
        self.doc.append(NewLine())
        self.doc.append(bold('Peripheral library configuration file location\n'))
        self.doc.append(self.periph_lib['file_path_name'].split('Firmware')[-1])
        self.doc.append(NewLine())
        self.doc.append(NewLine())
        self.doc.append('Note: All addressing is byte-wise')
        self.doc.append(Command('tableofcontents'))
        self.doc.append(NewPage())

    
    def fill(self):
        # with self.doc.create(Section("{} library.".format(self.config['hdl_library_name']))):
        # with self.doc.create(Section("{} library".format(self.periph_lib_name))):
        # main_section = Section("{} library".format(self.periph_lib_name))
        # self.doc.append(LargeText(bold('{} library'.format(self.periph_lib_name))))
        # periph_section = Section("Peripherals", numbering = False)
        # i = 1
        # for periph_name in self.periph_lib['peripherals'].keys():
            # self.doc.append("{} {}".format(str(i), periph_name))
            # i = i+1
            # self.doc.append(NewLine())
        # with self.doc.create(Section("Peripherals")):
        added_instances = []
        # for peri_info in self.config['peripherals']:
            # peri_class = Peripheral(peri_info)
        for periph_name, periph in self.periph_lib['peripherals'].items():
            if periph_name in added_instances:
                continue
            added_instances.append(periph_name)

            
            # with self.doc.create(Section(periph_name, numbering=True)):
            # with self.doc.create(Subsection(periph_name, numbering=True)):
            # self.doc.append(peri_class.get_kv('peripheral_description').replace('"', ''))
            self.doc.append(NewPage())
            periph_subsection = Section(periph_name, numbering=True)
            periph_subsection.append(periph.get_description().replace('""',''))

            # Peripheral System Map Table 
            periph_subsection.append(NewLine())
            periph_subsection.append(NewLine())
            periph_subsection.append(MediumText(bold('Local Slave Port Map')))
            periph_subsection.append(NewLine())
            periph_subsection.append(NewLine())
            periph_system_table = Tabular('|c|c|c|c|')
            # periph_system_table.add_row((MultiColumn(4,data=MediumText(bold('System Map'))),))
            periph_system_table.add_hline()
            periph_system_table.add_row(('Hex','Range (Bytes)','Slave Port','Protocol'))
            periph_system_table.add_hline()


            # peripheral system address map 
            dummyFPGA = FPGA(None)
            dummyFPGA.peripherals.update({periph_name: periph})
            dummyFPGA.create_address_map()
            # for slave in periph.slaves:
            for slave_port, slave_dict in dummyFPGA.address_map.items():
                periph_system_table.add_row((str(hex(slave_dict['base'])),str(slave_dict['span']),slave_port,slave_dict['type']))
                periph_system_table.add_hline()
            periph_subsection.append(periph_system_table)

            # self.doc.append(periph.get_description().replace('""',''))
            # self.doc.append(NewLine())
            
            #self.doc.append(MediumText(bold("slave ports.")))

            # for val_info, val_type in ((periph.registers, 'Registers'), 
                                       # (periph.rams, 'Rams'), 
                                       # (periph.fifos, 'Fifos')):
            periph_reg_section = Subsection("{} register slave".format(periph_name), numbering=False)
            periph_reg_table = Tabular('|c|c|c|c|')
            periph_reg_table.add_hline()
            periph_reg_table.add_row(('Base Address','Range','Register group', 'Number of Slaves'))
            periph_reg_table.add_hline()
            # slave_subsections = ("{} slaves".format(periph_name), numbering=False)
            # slave_subsections = []
            # slave_subsections.append(NewLine())
            # slave_subsections.append(MediumText(bold("Slave Ports for peripheral " + periph_name + "\n")))
            slave_subsections = Subsection("Slave Ports for peripheral \'{}\'".format(periph_name), numbering=False)
            for slave in periph.slaves: 

                # if len(val_info) == 0: # not sure what this is for 
                    # continue

                #self.doc.add(text=val_type, size="medium")
                
                # added_val_types = []
                # for key, val in sorted(val_info.items()):
                    # if val.name() in added_val_types:
                        # continue
                    # added_val_types.append(val.name())
                slave_subsection = Subsection("Slave Port: {} ({})".format(slave.name(), 'Register block' if isinstance(slave, Register) else 'RAM' if isinstance(slave, RAM) else 'FIFO'), numbering=True)
                slave_subsection.append(slave.get_kv('slave_description'))
                slave_subsection.append(NewLine())
                # slave_subsection.append("Slave Type: {}".format('REGISTER' if isinstance(slave, Register) else 'RAM' if isinstance(slave, RAM) else 'FIFO'))
                slave_subsection.append(NewLine())
                slave_subsection.append("Address Length: {}".format(str(slave.address_length())))
                slave_subsection.append(NewLine())
                slave_subsection.append("Number of Slaves: {}".format(str(slave.number_of_slaves())))
                slave_subsection.append(NewLine())
                slave_subsection.append(NewLine())
                
                # if val_type == 'Registers':
                if isinstance(slave, Register): # expand registers and fields 
                    for ram in slave.rams:
                        periph_reg_table.add_row((str(ram.base_address()), str(ram.number_of_fields()*WIDTH_IN_BYTES), ram.name() + ' (RAM)', str(slave.number_of_slaves())))
                        periph_reg_table.add_hline()
                    periph_reg_table.add_row((str(slave.base_address()),str(slave.address_length()), slave.name(), str(slave.number_of_slaves())))
                    periph_reg_table.add_hline()
                    added_field_groups = []
                    # with self.doc.create(Subsection("{} Register Fields".format(val.name().lower()), numbering=True)):
                    # if val.get_kv('slave_description') is not None:
                        # slave_subsection.append(val.get_kv('slave_description').replace('"', ''))
                        
                    # generate register table i.e. by word 
                    group_address = -1
                    group_list = []
                    for field in slave.fields:
                        if field.address_offset() != group_address:  
                            group_address = field.address_offset()
                            group_list.append(field)
                            # addr_name = field.group_name() if field.group_name() != "None" else field.name()
                            
                            # slave_table.add_row(str(hex(field.address_offset())), addr_name)
                            # slave_table.add_hline()
                    c_max_rows = 30
                    nof_cols = ceil(len(group_list)/c_max_rows) # register table has max length of c_max_rows 
                    nof_rows = min(len(group_list), c_max_rows)
                    slave_table = Tabular('|c|c|'*nof_cols)
                    slave_table.add_hline()
                    slave_table.add_row(['Hex','Field Group']*nof_cols)
                    # slave_table.add_row((*['Hex','Field Group']*nof_cols))
                    slave_table.add_hline()
                    for i in range(nof_rows): 
                        row = []
                        for j in range(nof_cols):
                            if i+c_max_rows*j < len(group_list):
                                field.group_name() if field.group_name() != "None" else field.name()
                                row.extend([str(hex(group_list[i+c_max_rows*j].address_offset())), group_list[i+c_max_rows*j].name()])
                            else : 
                                row.extend(['',''])
                        slave_table.add_row(row)
                        # slave_table.add_row(*row)
                        slave_table.add_hline()

                    slave_subsection.append(slave_table)
                    slave_subsection.append(NewPage())
                    
                    group_address = -1
                    for field in slave.fields:
                        # if field.group_name() is None or field.group_name() != last_group: # base on group_address instead
                        # print("field {} address {} bit{}".format(field.name(), str(field.address_offset()), str(field.bit_offset())))
                        if field.address_offset() != group_address:  
                            group_address = field.address_offset()
                            # group_page = MiniPage()
                            group_subsection = Subsection('{} {}'.format(str(hex(field.address_offset())), field.name() if field.group_name() == 'None' else field.group_name()),numbering=False)
                            group_fields = [field for field in slave.fields if field.address_offset() == group_address ]
                            if len(group_fields)>10: slave_subsection.append(NewPage())
                            group_subsection = gen_reg_tables(group_subsection, group_fields)
                            for field in group_fields[::-1]:
                                field_name = field.name() if field.group_name() == 'None' else field.name().split(field.group_name() + '_')[-1]
                                bit_string = "Bit {}".format(str(field.bit_offset())) if field.width() == 1 else "Bits {}:{}".format(str(field.bit_offset()+field.width()-1), str(field.bit_offset()))
                                group_subsection.append(bold("{}\t\t{} ({}):".format(bit_string, field_name, field.access_mode())))
                                group_subsection.append("\t\t{}".format(field.field_description()))
                                group_subsection.append(NewLine())
                                group_subsection.append(NewLine())
                            # group_page.append(group_subsection)
                            slave_subsection.append(group_subsection)
                else: # RAM or FIFO
                    slave_subsection.append("Data width: {}".format(slave.width()))
                    slave_subsection.append(NewLine())
                    if isinstance(slave, RAM):
                        slave_subsection.append("User data width: {}".format(slave.user_width()))

                slave_subsections.append(slave_subsection)
            periph_reg_section.append(periph_reg_table)
            self.doc.append(periph_subsection)
            if any([isinstance(slave, Register) for slave in periph.slaves]): self.doc.append(periph_reg_section)
            # for i in range(len(slave_subsections)):
                # self.doc.append(slave_subsections[i])
            self.doc.append(slave_subsections)

            # self.doc.append(periph_section)
            self.doc.append(NewPage())

    def make_pdf(self):
        stdout = sys.stdout # keep a handle on the real standard output
        sys.stdout = StringIO()
        try:
            # self.doc.generate_pdf('{}'.format(self.periph_lib_name), clean_tex=False, silent=True)
            self.doc.generate_pdf(os.path.join(self.out_dir, self.periph_lib_name), clean_tex=True)
            time.sleep(0.5)
        except CalledProcessError:
            pass
        sys.stdout = stdout



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
    else:
        if args.system:
            fpga_libs = FPGALibrary(os.path.expandvars('$RADIOHDL')).library
        if args.peripheral:
            periph_libs = PeripheralLibrary(os.path.expandvars('$RADIOHDL')).library

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