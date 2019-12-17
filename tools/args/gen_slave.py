import os
import sys
import copy
import logging
import argparse
import subprocess
import traceback
import shutil
import numpy as np
from common import ceil_log2, ceil_pow2
from constants import *
from peripheral_lib import *
import peripheral
# from peripheral import PeripheralLibrary, Peripheral
# from system import System
# Inputs:
# takes inputs from peripheral.py
#- VHDL and TCL source template file
#- YAML config file
#
# Outputs
# - VHDL wrapper files
# - IP creation TCL files

logger = logging.getLogger('main.gen_slave')
def word_wise(byte_address):
    return int(byte_address/WIDTH_IN_BYTES)

def tab_aligned(input_strings):
    """Takes array of strings and replaces tag <tabs> with appropriate number of tabs, outputs resulting string array"""
    # automatically determine prefix i.e. common string
    tag = '<tabs>'
    len_array = []
    output_strings = []
    for line in input_strings:
        if tag in line:
            line = line.strip(' ')
            splits = line.split(tag, 1)    # parse from before tag
            len_array.append(len(str(splits[0]))-splits[0].count('\t'))

    try:
        minLength =  min(len_array)
    except ValueError: # if no lines with tabs tag in it
        return(input_strings)

    offset = 4 - np.mod(minLength, 4)
    max_var = np.ceil(max(len_array)/4)*4  - minLength
    max_tabs = int(np.ceil((max_var)/4)) - 1#+(1 if np.mod(max(len_array),4) == 0 else 0)
    i = 0
    for line in input_strings:
        if tag in line:
            # nof_tabs = (max_tabs - int(np.ceil((len_array[i] - minLength - offset)/4)))
            nof_tabs = max_tabs - int(np.floor((len_array[i] - minLength-offset)/4))
            line = line.replace(tag, nof_tabs*'\t')
            i = i + 1
        output_strings.append(line)
    return(output_strings)

def aligned_tabs(name, max_chars, prefix = ''):
    offset = 4 - np.mod(len(prefix),4)
    max_tabs = np.ceil(max_chars/4) + 1 # for max variation between names
    nof_tabs = int(max_tabs - np.ceil((len(name)-offset)/4))
    return(nof_tabs*'\t')

def vector_len(width):
    return '' if width == 1 else '_VECTOR(' + str(width-1) + ' downto 0)'

class Slave(object):
    """Generate VHDL and IP source for memory mapped slaves"""

    def __init__(self, peripheral, system_name=None):
        self.rootDir = os.path.expandvars('$RADIOHDL/tools/args') #('$RADIOHDL/tools/prestudy/YAML')
        self.nof_dat = 0
        self.replaceDict = {}
        self.periph_name = peripheral.name()
        self.periph_lib = peripheral.lib
        self.slaves = peripheral.slaves
        self.prefix = (( peripheral.lib + '_' ) if peripheral.lib != peripheral.name() else '') + peripheral.name()
        self.output_files = []
        self.system_name = system_name

    def generate_mem(self, settings, slave_type):
        """ Generate a VHDL instantiation file and a TCL file to create and customise the IP """
        lines = []
        # fix memory to fit Xilinx IP width/depth combinations
        # self.xilinxConstraints()
        # self.fix_mem_size(settings, slave_type)
        self.gen_file(settings, slave_type,'vhd')
        self.gen_file(settings, slave_type,'tcl')

    def generate_regs(self, peripheral):
        """ Generate a set of entity, pkg and instantiation files for all reg slaves """
        self.periph_name = peripheral.name()
        self.periph_lib = peripheral.lib
        self.nof_dat = 0
        for slave in self.slaves:
            if not isinstance(slave, Register) or (isinstance(slave, Register) and getattr(slave, 'isIP', False)):
                continue
            self.nof_dat = int(slave.base_address()/WIDTH_IN_BYTES + slave.address_length()/WIDTH_IN_BYTES*slave.number_of_slaves())

        if self.nof_dat > 1:
            self.dat_w = DEFAULT_WIDTH # parameterize
            self.adr_w = ceil_log2(self.nof_dat) # makes addressing word wise
            # self.slaves = peripheral.slaves
            self.gen_pkg()
            self.gen_file(None, 'reg','vhd')
            self.gen_file(None, 'reg','vho')


    def write_file(self, lines, file_name):
        out_dir = os.path.expandvars('$HDL_BUILD_DIR/ARGS')
        if self.system_name is not None:
            out_dir = os.path.join(out_dir, self.system_name)
        try:
            os.stat(out_dir)
        except:
            os.mkdir(out_dir)
        out_dir = os.path.join(out_dir, self.periph_lib)
        try:
            os.stat(out_dir)
        except:
            os.mkdir(out_dir)
        out_dir = os.path.join(out_dir, self.periph_name)
        try:
            os.stat(out_dir)
        except:
            os.mkdir(out_dir)
        file_name = os.path.join(out_dir, file_name)
        with open(file_name, 'w') as outFile:
            for line in lines:
                outFile.write(line)
        logger.info('Generated ARGS output %s', file_name)
        self.output_files.append(file_name)

    def get_args_files(self):
        return self.output_files


    def gen_pkg(self):
        tmplFile = os.path.join(self.rootDir, "templates/template_reg_pkg.vhd")
        # outDir = os.path.join(self.rootDir, 'outputs')
        # pkgFile = os.path.join(outDir, self.periph_lib + '_' + self.periph_name + "_reg_pkg.vhd")
        file_name = self.prefix + "_reg_pkg.vhd"
        lines = []
        # fields_dict = regGroup.fields
        with open(tmplFile, 'r') as infile:
            for line in infile:
                addlines = []
                if '<lib_name>' in line:
                    line = line.replace('<lib_name>', self.periph_lib if self.periph_lib == self.periph_name else self.periph_lib + '_' + self.periph_name)
                if '<lib>' in line:
                    line = line.replace('<lib>', self.periph_lib)
                # if '<{library_statements}>' in line:
                    # addlines = ['USE axi4_lib.axi4_lite_pkg.ALL;\n']
                    line = '';
                if '<{constant_statements}>' in line:
                    for slave in self.slaves:
                        if not isinstance(slave, Register) or (isinstance(slave, Register) and getattr(slave, 'isIP', False)):
                            continue
                        regGroup = slave
                        # reg_name = regGroup.name()
                        # fields_dict = regGroup.fields
                        # fields_dict = registers[reg_name].fields
                        addlines.extend(tab_aligned(self.fields_constants(regGroup)))
                        addlines.append('\n')
                    line = '';
                if '<{type_statements}>' in line:
                    record_lines = []
                    for slave in self.slaves:
                        if not isinstance(slave, Register):
                            continue
                        regGroup = slave
                        reg_name = regGroup.name()
                        record_lines.extend(self.ram_records(regGroup))
                        record_lines.extend(self.fields_records(reg_name, regGroup, 'RW'))
                        record_lines.extend(self.fields_records(reg_name, regGroup, 'RO'))
                        record_lines.extend(self.pulse_records(reg_name, regGroup, 'PR')[0])
                        record_lines.extend(self.pulse_records(reg_name, regGroup, 'PW')[0])
                        record_lines.extend(self.fields_records(reg_name, regGroup,'COUNT'))
                    record_lines = tab_aligned(record_lines)
                    addlines.extend(record_lines)
                    line = '';
                addlines.append(line)
                lines.extend(addlines)
        self.write_file(lines, file_name)

    def gen_vho(self, slaveSettings, slave_type):
        lines = []
        tmplFile = os.path.join(self.rootDir, "templates/template_reg_axi4.vho")
        # fields_dict = slaveSettings.fields
        with open(tmplFile, 'r') as infile:
            for line in infile:
                addlines = []
                if '<lib_name>' in line:
                    line = line.replace('<lib_name>', self.periph_lib if self.periph_lib == self.periph_name else self.periph_lib + '_' + self.periph_name)
                if '<lib>' in line:
                    line = line.replace('<lib>', self.periph_lib)
                if '<{slave_ports}>' in line:
                    sublines = []
                    for slave in self.slaves:
                        if not isinstance(slave, Register):
                            continue
                        for field in slave.fields:
                            if field.access_mode() == 'RW':
                                sublines.append('    '*2 + slave.name().upper() + '_FIELDS_RW.'+ field.name() + '<tabs>=>\n')
                                # sublines.extend(' ,\t\t -- '+ 'STD_LOGIC' + vector_len(field.width()) +'\n')
                            if field.access_mode() == 'RO':
                                sublines.append('    '*2 + slave.name().upper() + '_FIELDS_RO.'+ field.name() + '<tabs>=>\n')
                                # sublines.extend(' ,\t\t -- '+ 'STD_LOGIC' + vector_len(field.width()) +'\n')
                            if ((field.access_mode() == 'CS') or (field.access_mode() == 'CW')):
                                sublines.append('    '*2 + slave.name().upper() + '_FIELDS_COUNT.'+ field.name() + '<tabs>=>\n')
                        sublines.extend(self.ram_records(slave, False))
                    # lines.extend(tab_aligned(sublines))
                    lines.extend(sublines)
                    line = ''

                lines.append(line)
            lines.append(');')
        return(tab_aligned(lines))


    def gen_vhdl(self, slaveSettings, slave_type):
        lines = []
        slave_type = slave_type.lower()
        if (slave_type == 'ram') and (slaveSettings.interface() == 'simple'):
            tmplFile = os.path.join(self.rootDir, "templates/template_ramsimple_axi4.vhd")
        else:
            tmplFile = os.path.join(self.rootDir, "templates/template_" + slave_type + "_axi4.vhd")
        
        removePort = {}
        replace_dicts = {}
        if slave_type == 'reg':
            self.replaceDict = {'<lib>' : self.periph_lib,
                                '<lib_name>' : self.periph_lib if self.periph_lib == self.periph_name else self.periph_lib + '_' + self.periph_name,
                                '<adr_w>' : self.adr_w ,
                                '<dat_w>' : self.dat_w}
            for slave in self.slaves:
                if not isinstance(slave, Register):
                    continue
                regGroup = slave
                # regGroup = self.registers[key]
                fields_dict = regGroup.fields
                replace_dicts.update({regGroup.name(): {'<name>': self.periph_name,
                                                        '<reg_ram>': 'reg',
                                                        '<reg_name>': regGroup.name(),
                                                        '<adr_w>': 'c_addr_w',
                                                        '<dat_w>': 'c_dat_w',
                                                        '<nof_dat>' : int(regGroup.address_length()/WIDTH_IN_BYTES),
                                                        '<c_init_reg>': self.set_init_string(regGroup)[0],
                                                        '<nof_slaves>' : regGroup.number_of_slaves(),
                                                        '<addr_base>' : int(regGroup.base_address()/WIDTH_IN_BYTES),
                                                        '<c_clr_mask>':  self.set_clr_mask(regGroup)[0]}})
        else :
            self.replaceDict = {'<name>': slaveSettings.name(),
                                '<lib>': self.prefix,
                                '<adr_w>':ceil_log2(slaveSettings.address_length()),
                                '<dat_w>':  slaveSettings.width(),
                                '<nof_dat>': slaveSettings.address_length(),
                                '<nof_dat_by_slaves>': slaveSettings.address_length()*ceil_pow2(slaveSettings.number_of_slaves()),
                                '<init_sl>':str(0),#slaveSettings.default() if '.coe' not in str(slaveSettings.default()) else str(0),
                                '<RO>' : slaveSettings.access_mode() == 'RO',
                                '<WO>' : slaveSettings.access_mode() == 'WO',
                                '<FTHRESHOLD>' : slaveSettings.address_length() - 5,
                                '<ETHRESHOLD>' : 2 , '<nof_slaves>':slaveSettings.number_of_slaves(),
                                '<t_we_arr>':'t_we_arr' if slaveSettings.number_of_slaves() > 1 else 'std_logic_vector',
                                '<web_range>':'c_ram_b.nof_slaves' if slaveSettings.number_of_slaves() > 1 else 'c_ram_b.dat_w/8'}
            if slave_type == 'ram':
            
                self.replaceDict.update({'<dat_wb>' : slaveSettings.user_width(),
                                         '<nof_datb>' : slaveSettings.user_depth(),
                                         '<adr_wb>' : ceil_log2(slaveSettings.user_depth()),
                                         '<sig_wea>' : 'sig_wea' if slaveSettings.access_mode() == 'RW' else '(others => \'0\')',
                                         '<user_upper>':str(ceil_log2(slaveSettings.user_width()/8)-1),
                                         '<user_lower>':str(ceil_log2(slaveSettings.user_width()/8))})
                if slaveSettings.number_of_slaves() == 1:
                    appendDict = {'<sig_addra>': 'sig_addra',
                                  '<sig_dina>':'sig_dina',
                                  '<sig_douta>':'sig_douta',
                                  '<tab>':'',
                                  '<sig_addrb>': 'sig_addrb',
                                  '<sig_dinb>': 'sig_dinb',
                                  '<sig_doutb>':'sig_doutb',
                                  '<(i)>':'',
                                  '<array>':'',
                                  '<vector>':''}
                else:
                    if slave_type == 'ramsimple':
                        print('ramsimple slaves only support single instances of the slave')
                        sys.exit()
                    appendDict = {'<sig_addra>':'mem_mosi_arr_a(i).address',
                                  '<sig_dina>':'mem_mosi_arr_a(i).wrdata',
                                  '<tab>':'\t',
                                  '<sig_douta>':'mem_miso_arr_a(i).rddata',
                                  '<sig_addrb>': 'mem_mosi_arr_b(i).address',
                                  '<sig_dinb>':'mem_mosi_arr_b(i).wrdata',
                                  '<sig_doutb>':'mem_miso_arr_b(i).rddata',
                                  '<(i)>':'(i)',
                                  '<array>':'_arr(g_ram_b.nof_slaves-1 downto 0)',
                                  '<vector>':'_vector(c_ram_b.nof_slaves-1 downto 0)'}
                self.replaceDict.update(appendDict)
            portTags = {'WO' : ['RXD','axi4_ar','axi4_r', 'rxd'],
                        'RO' : ['TXD','axi4_aw','axi4_w', 'txd']} # change to read
            if slave_type == 'fifo':
                removePort[slaveSettings.access_mode()] = portTags[slaveSettings.access_mode()]
                if slaveSettings.number_of_slaves() > 1 :
                    self.replaceDict.update({'<_arr>':'_arr(g_fifo.nof_slaves-1 downto 0)',
                                             '<_VECTOR>':'_VECTOR(g_fifo.nof_slaves-1 downto 0)',
                                             '<(i)>':'(i)'})
                else:
                    self.replaceDict.update({'<_arr>':'',
                                             '<_VECTOR>':'',
                                             '<(i)>':''})
        with open(tmplFile, 'r') as infile:
            temp = []
            for line in infile:
                if '<' in line and '{' not in line:
                    for tag in self.replaceDict.keys():
                        if tag in line:
                            line = line.replace(tag, str(self.replaceDict[tag]))
                # elif '<{' in line:
                if slave_type == 'reg':
                    if '<{user_clocks}>' in line:
                        # If any slave is a dual clock slave we need to set all up as dual clock but only once
                        for slave in self.slaves:
                            if slave.get_kv("dual_clock"):
                                lines.extend('        st_clk_{} : IN STD_LOGIC_VECTOR(0 TO {});\n'.format(slave.name(), slave.number_of_slaves()-1))
                                lines.extend('        st_rst_{} : IN STD_LOGIC_VECTOR(0 TO {});\n'.format(slave.name(), slave.number_of_slaves()-1))

                    nof_regs = sum([(isinstance(slave, Register) and not getattr(slave, 'isIP', False)) for slave in self.slaves])
                    i = 0
                    for slave in self.slaves:
                        if not isinstance(slave, Register) or (isinstance(slave,Register) and getattr(slave, 'isIP', False)):
                            continue
                        self.regGroup = slave
                        regGroup = slave
                        fields_dict = regGroup.fields
                        if '<{slave_ports}>' in line:
                            sublines = self.slave_ports()
                            if i == nof_regs-1:
                                sublines[-1] = sublines[-1].replace(';','')
                            lines.extend(sublines)
                        if '<{c_mm_reg}>' in line:
                            lines.extend(self.c_mm_reg(replace_dicts))
                        if '<{signal_declarations}>' in line:
                            for ram in regGroup.rams:
                                lines.extend(self.signal_declarations(ram, True, regGroup.number_of_slaves(), regGroup.name()))
                            lines.extend(self.signal_declarations(regGroup))
                        if '<{wr_val}>' in line:
                            lines.extend(self.read_write_vals(i, nof_regs, 'wr'))
                        if '<{rd_val}>' in line:
                            lines.extend(self.read_write_vals(i, nof_regs, 'rd'))
                        if '<{wr_busy}>' in line:
                            lines.extend(self.read_write_busys(i, nof_regs, 'wr'))
                        if '<{rd_busy}>' in line:
                            lines.extend(self.read_write_busys(i, nof_regs, 'rd'))
                        if '<{rd_dat}>' in line:
                            lines.extend(self.read_data_compare(regGroup, i, nof_regs))
                        if '<{input_statements}>' in line: # TODO: clean up and add comment for unlabelled fields
                            lines.extend(self.input_statements(regGroup))
                        if '<{output_statements}>' in line:
                            lines.extend(self.output_statements(regGroup))
                        if '<{common_reg_inst}>' in line : #or common_reg_inst == 1:
                            lines.extend(self.instantiate_rams())
                            sublines = []
                            if slave.get_kv("dual_clock"):
                                tmpl_file = os.path.join(self.rootDir, 'templates/template_common_reg_r_w_dc.vho')
                                # Need to add support for peripherals with different kinds of dual clock slaves
                            else:
                                tmpl_file = os.path.join(self.rootDir, 'templates/template_common_reg_r_w.vho')

                            with open(tmpl_file, 'r') as inst_file:
                                sublines = [(subline.replace('<reg_name>', regGroup.name())) for subline in inst_file]
                            lines.extend(sublines)
                            # Put in logic and components for any counters
                            lines.extend(self.instantiate_counters(regGroup))
                        if '<{' in line and i == nof_regs-1:#len(self.registers.keys())-1:# at last register
                            line = ''
                        i = i + 1
                else :
                    if slaveSettings.number_of_slaves() == 1:
                        generate_tags = ['SIGNAL mem', '<{multiple_slaves}>','GENERATE']
                        if any([tag in line for tag in generate_tags]):
                            line = ''
                    else :  # insert mux and add generates
                        if '<{multiple_slaves}>' in line:
                            tmpl_file = os.path.join(self.rootDir, 'templates/template_common_mem_mux.vho')
                            with open(tmpl_file, 'r') as inst_file:
                                lines.extend(inst_file)
                            line = ''

                # remove lines containing tags associated with unnecessary ports
                for badTagList in removePort.values():
                    if any(badTag in line for badTag in badTagList):
                        line = ""
                lines.append(line)
        return(lines)

    def gen_tcl(self, settings, slave_type):
        lines = []
        tmplFile = os.path.join(self.rootDir, "templates/template_" + slave_type + "_axi4.tcl")
        # replaceDict = {'<entity>': settings.name, '<FW>' : settings.access_mode() == 'FW', '<init_sl>' : settings.default(), '<bDefault>':settings.default() is not None,
                    # '<dat_w>' : settings.width(), '<FR>' : settings.access_mode() == 'FR', '<nof_dat>' : settings.address_length(), '<FTHRESHOLD>' : settings.address_length() - 5, '<ETHRESHOLD>' : 2 }
        default = settings.reset_value() if settings.reset_value() is not None else 0
        if 'coe' not in str(default):
            removeDict = {'<coe_file>':'', 'Load_Init_File' :'', '<default>':str(hex(default)).replace('0x','')}
        else :
            removeDict = {'<coe_file>': default, '<default>': 0}
        # if slave_type == "fifo":
            # removeDict.update({'RX': ''}) if settings.access_mode() == 'WO' else removeDict.update({'TX': ''});
        with open(tmplFile, 'r') as infile:
            for line in infile:
                for tag in removeDict.keys():
                    if tag in line:
                        if removeDict[tag] != '':
                            line = line.replace(tag, str(removeDict[tag]))
                        else:
                            line = ''
                if '<' in line:
                    for tag in self.replaceDict.keys():
                        if tag in line:
                            line = line.replace(tag, str(self.replaceDict[tag]))
                lines.append(line)
        return(lines)

    def gen_file(self, settings, slave_type, file_type):
        lines = []
        if file_type == 'tcl':
            lines = self.gen_tcl(settings, slave_type)
        elif file_type == 'vho':
            lines = self.gen_vho(settings, slave_type)
        else :
            lines = self.gen_vhdl(settings, slave_type)
        # outDir = os.path.join(self.rootDir, 'outputs')

        out_file = ('ip_' if file_type == 'tcl' else '') + (self.prefix + '_' + settings.name() if slave_type != 'reg' else self.prefix) + '_' + slave_type  + '.' + file_type
        # outFile = os.path.join(outDir, prefix + settings.lib + '_' + (self.periph_name if slave_type == 'reg' else settings.name) + '_' + slave_type + '_axi4.' + file_type)
        self.write_file(lines, out_file)

    def set_init_string(self, regGroup):
        field_list = regGroup.fields
        temp_vector = [0]*regGroup.address_length()*self.dat_w
        bInit = 0
        padding = ''
        for field in field_list:
            if field.reset_value() != 0:
                bInit = 1
                lowestBit = None if word_wise(field.address_offset())*self.dat_w+field.bit_offset() == 0 else word_wise(field.address_offset())*self.dat_w+field.bit_offset() - 1
                temp_vector[word_wise(field.address_offset())*self.dat_w+field.bit_offset() + field.width() -1 :lowestBit:-1] = list(format(field.reset_value(), '0' + str(field.width()) + 'b'))
        temp_string = ''.join(map(str, temp_vector[::-1]))
        hexValue = hex(int(temp_string,2))[2:]
        if len(hexValue) < int(word_wise(regGroup.address_length())*self.dat_w/4):
            padding = "0"*(int(word_wise(regGroup.address_length())*self.dat_w/4)-len(hexValue))
        if bInit == 1 :
            c_init_reg =  'X"' + padding + hexValue.upper() + '"'
        else:
            c_init_reg = '(others => \'0\')'
        return(c_init_reg, bInit)

    def set_clr_mask(self, regGroup):
        field_list = regGroup.fields
        if (regGroup.address_length() < 4):
            # This can occur if only a memory is defined in a register slave. The clr_mask is not used in this case anyway.
            temp_vector = [0]*4*self.dat_w
        else:
            temp_vector = [0]*word_wise(regGroup.address_length())*self.dat_w
        bMask = 0
        padding = ''      
        
        for field in field_list:
            if "CLR" in field.side_effect():
                bMask = 1
                lowestBit = None if word_wise(field.address_offset())*self.dat_w+field.bit_offset() == 0 else word_wise(field.address_offset())*self.dat_w+field.bit_offset() - 1
                temp_vector[word_wise(field.address_offset())*self.dat_w+field.bit_offset() + field.width() -1 :lowestBit:-1] = [1]*field.width() #list(format(field.default(), '0' + str(field.width()) + 'b'))

        temp_string = ''.join(map(str, temp_vector[::-1]))
        hexValue = hex(int(temp_string,2))[2:]
        if len(hexValue) < int(word_wise(regGroup.address_length())*self.dat_w/4):
            padding = "0"*(int(word_wise(regGroup.address_length())*self.dat_w/4)-len(hexValue))
        # hexValue = "{0:#0{1}x}".format(int(temp_string,2),self.nof_dat*self.dat_w/4)#hex(int(temp_string, 2))
        if bMask == 1 :
            clr_mask = 'X"' + padding + hexValue.upper() + '"'
        else:
            clr_mask = '(others => \'0\')'
        return(clr_mask, bMask)

    def pulse_records(self, reg_name, regGroup, pulse_type):
        lines = []
        bPulseFields = 0
        field_list = regGroup.fields
        nof_inst = regGroup.number_of_slaves()
        for field in field_list:
            if field.side_effect() == pulse_type:
                bPulseFields = 1
        if bPulseFields:
            if nof_inst != 1:
                lines.append('\tTYPE t_' + reg_name + '_' + pulse_type.lower() + ' is RECORD\n')
                for field in field_list:
                    if field.side_effect() == pulse_type:
                        lines.append('\t\t'+field.name().lower()+'<tabs>:\t' + 'STD_LOGIC_VECTOR(0 TO ' + str(nof_inst - 1) + ');\n')
                lines.append('\tEND RECORD;\n\n')
            else:
                lines.append('\tTYPE t_' + reg_name + '_' + pulse_type.lower() + ' is RECORD\n')
                for field in field_list:
                    if field.side_effect() == pulse_type:
                        lines.append('\t\t'+field.name().lower()+'<tabs>:\t' + 'STD_LOGIC' + ';\n')
                lines.append('\tEND RECORD;\n\n')
        return(lines, bPulseFields)

    def fields_constants(self, regGroup):
        lines = []
        reg_name = regGroup.name()
        for ram in regGroup.rams:
            for i in range(regGroup.number_of_slaves()):
                lines.append('\tCONSTANT c_' + reg_name + '_' + ram.name() + (str(i) if regGroup.number_of_slaves() > 1 else '') +  '_address<tabs>: t_register_address := ('+ 'base_address => ' + str(word_wise(ram.base_address()) + (i)*(ceil_pow2(ram.number_of_fields()))) +', address => 0, offset => 0, width => ' + str(ram.width()) + ', name => pad("' + reg_name + '_' + ram.name() + '"));\n' )
        for i in range(regGroup.number_of_slaves()):
            slave_index = '_' + str(i) if regGroup.number_of_slaves() > 1 else ''
            for field in regGroup.fields:
                lines.append('\tCONSTANT c_' + reg_name + '_' + field.name() + '_address'+slave_index+'<tabs>: t_register_address := ('+ 'base_address => ' + str(word_wise(regGroup.base_address())+i*word_wise(regGroup.address_length())) +', address => ' + str(word_wise(field.address_offset())) + ', offset => ' + str(field.bit_offset()) + ', width => ' + str(field.width()) + ', name => pad("' + reg_name + '_' + field.name() + '"));\n' )
        if regGroup.number_of_slaves() > 1 :
            for field in regGroup.fields:
                fields_string = ""
                for i in range(regGroup.number_of_slaves()):
                    fields_string = fields_string  + ("c_{0}_{1}_address_{2}{3} ".format(reg_name, field.name(),i, '' if i==(regGroup.number_of_slaves()-1) else ','))
                lines.append("\tCONSTANT c_{0}_{1}_address<tabs>: t_register_address_array(0 to {2}) := ({3});\n".format(reg_name, field.name(), str(regGroup.number_of_slaves()-1),fields_string))
        # for field in field_list:
            # lowerBit = self.dat_w*field.address_offset() + field.bit_offset()

            # lines.append('\tCONSTANT c_lwr_' + reg_name + '_' + field.name() + '\t' + aligned_tabs(field.name(), 32)*'\t' + 'NATURAL := ' + str(lowerBit) + ';\n'  )
            # upper_bit = self.dat_w*field.address_offset() + field.bit_offset() + field.width() - 1
            # lines.append('\tCONSTANT c_upr_' + reg_name + '_' + field.name() + '\t' + aligned_tabs(field.name(), 32)*'\t' + 'NATURAL := ' + str(upper_bit) + ';\n'  )
        return(lines)

    def ram_records(self, regGroup, bRecords = True):
        lines = []
        nof_inst = regGroup.number_of_slaves()
        for ram in regGroup.rams:
            slave_ram_name = regGroup.name() + '_' + ram.name()
            bit_type = 'STD_LOGIC' if nof_inst == 1 else ('STD_LOGIC_VECTOR(0 to '+ str(nof_inst-1) +')')
            adr_type = ('STD_LOGIC_VECTOR('+str(ceil_log2(ram.number_of_fields())-1)+' downto 0)' if nof_inst == 1 else ('t_slv_<>_arr(0 to '+ str(nof_inst-1) +')')).replace('<>', str(ceil_log2(ram.number_of_fields())))
            rd_type = 'STD_LOGIC_VECTOR('+str(ram.width()-1)+' downto 0)' if nof_inst == 1 else ('t_slv_'+str(ram.width())+'_arr(0 to '+ str(nof_inst-1) +')')
            # write user_out record
            in_ports = {'adr' : adr_type, 'wr_dat' : rd_type, 'wr_en' : bit_type, 'rd_en' : bit_type, 'clk' : bit_type, 'rst': bit_type}
            out_ports = {'rd_dat' : rd_type, 'rd_val': bit_type}
            if bRecords:
                lines.append('\tTYPE t_' + slave_ram_name + '_ram_out' + ' is RECORD\n')
                for port, type in out_ports.items():
                    lines.append('\t'*2 + port + '<tabs>: ' + type + ';\n')
                lines.append('\tEND RECORD;\n\n')
                #write user_in record
                lines.append('\tTYPE t_' + slave_ram_name + '_ram_in' + ' is RECORD\n')
                for port, type in in_ports.items():
                    lines.append('\t'*2 + port + '<tabs>: ' + type + ';\n')
                lines.append('\tEND RECORD;\n\n')
            else :
                for port, type in out_ports.items():
                    lines.append('\t\t' + slave_ram_name.upper() + '_OUT.' + port + '<tabs>=>\n')
                for port, type in in_ports.items():
                    lines.append('\t\t' + slave_ram_name.upper() + '_IN.' + port + '<tabs>=>\n')


        return(lines)

    def fields_records(self, reg_name, regGroup, mode):
        lines = []
        write_record = 0
        field_list = regGroup.fields
        nof_inst = regGroup.number_of_slaves()
        
        for field in field_list:
            if  ((field.access_mode() == mode) or
                 ((mode == 'COUNT') and (field.access_mode() == 'CS')) or
                 ((mode == 'COUNT') and (field.access_mode() == 'CW'))):
                write_record = 1
        if write_record:
            lines.append('\tTYPE t_' + reg_name + '_' + mode.lower() + ' is RECORD\n')
            if nof_inst != 1:
                for field in field_list:
                    if ((field.access_mode() == mode) or
                        ((mode == 'COUNT') and (field.access_mode() == 'CS')) or
                        ((mode == 'COUNT') and (field.access_mode() == 'CW'))):
                        if ((field.width() == 1) or (mode == 'COUNT')):
                            data_type = 'std_logic_vector(0 to ' + str(nof_inst - 1)
                        else :
                            data_type = 't_slv_' + str(field.width()) + '_arr(0 to ' + str(nof_inst - 1)
                        lines.append('        ' + field.name().lower() + '<tabs>' + ': ' + data_type + ');\n')
            else : # no arrays required
                for field in field_list:
                    if ((field.access_mode() == mode) or
                        ((mode == 'COUNT') and (field.access_mode() == 'CS')) or
                        ((mode == 'COUNT') and (field.access_mode() == 'CW'))):
                        if ((field.width() == 1) or (mode == 'COUNT')):
                            data_type = 'std_logic'
                        else :
                            data_type = 'std_logic_vector('+str(field.width()-1)+' downto 0)'
                        lines.append('        ' + field.name().lower() + '<tabs>' + ': ' + data_type + ';\n')

            lines.append('\tEND RECORD;\n\n')

            if mode == 'COUNT':
                for field in field_list:
                    if ((field.access_mode() == 'CS') or (field.access_mode() == 'CW')):
                        count_name_t = 't_' + regGroup.name() + '_' + field.name()   # just a std_logic_vector of width field.width()
                        lines.append('    subtype ' + count_name_t + ' is std_logic_vector((' + str(field.width()) + '-1) downto 0);\n')

        return(lines)

    def slave_ports(self):
        lines = []
        reg_name = self.regGroup.name()
        field_list = self.regGroup.fields
        ram_list = self.regGroup.rams
        if any(field.access_mode() == 'RW' for field in field_list):
            lines.append('        ' + reg_name.upper() + '_FIELDS_RW' + '<tabs>' + ': OUT t_' + reg_name + '_rw;\n')
        if any(field.access_mode() == 'RO' for field in field_list):
            lines.append('        ' + reg_name.upper() + '_FIELDS_RO' + '<tabs>' + ': IN  t_' + reg_name + '_ro;\n')
        if any((field.access_mode() == 'CS' or field.access_mode() == 'CW') for field in field_list):
            lines.append('        ' + reg_name.upper() + '_FIELDS_COUNT' + '  : IN t_' + reg_name + '_count;\n')
            lines.append('        count_rsti : in std_logic := \'0\';\n')
        for field in ram_list:
            lines.append('\t\t' + (reg_name + '_' + field.name()).upper() + '_IN' + '<tabs>' + ': IN  t_' +  reg_name + '_' + field.name() + '_ram_in;\n')
            lines.append('\t\t' + (reg_name + '_' + field.name()).upper() + '_OUT' + '<tabs>' + ': OUT t_' + reg_name + '_' + field.name() + '_ram_out;\n')
        if self.pulse_records('', self.regGroup, 'PR')[1]:
            lines.append('\t\t' + reg_name.upper() + '_FIELDS_PR' + aligned_tabs(reg_name, 6, '_FIELDS_PR') + ': OUT\tt_' + reg_name + '_pr;\n')
        lines = tab_aligned(lines)
        return(lines)

    def signal_declarations(self, regGroup, ram = False, nof_slaves = 1, regGroup_name = None):

        lines = []
        reg_name = regGroup.name()
        ro_dict = {'postfix' : 'in_reg', 'type': ': STD_LOGIC_VECTOR(<>.nof_slaves*<>.dat_w*<>.nof_dat-1 downto 0);\n' }
        rw_dict = {'postfix' : 'out_reg', 'type': ': STD_LOGIC_VECTOR(<>.nof_slaves*<>.dat_w*<>.nof_dat-1 downto 0);\n'}
        pw_dict = {'postfix' : 'pulse_write', 'type' : ': STD_LOGIC_VECTOR(<>.nof_slaves*<>.nof_dat-1 downto 0);\n'}
        pr_dict = {'postfix' : 'pulse_read', 'type' : ': STD_LOGIC_VECTOR(<>.nof_slaves*<>.nof_dat-1 downto 0);\n'}
        rd_dict = {'postfix' : 'rd_dat', 'type' : ': STD_LOGIC_VECTOR(<>.dat_w-1 downto 0);\n'}
        rv_dict = {'postfix' : 'rd_val', 'type' : ': STD_LOGIC;\n'}
        rb_dict = {'postfix' : 'rd_busy', 'type' : ': STD_LOGIC_VECTOR(<>.nof_slaves-1 downto 0);\n' if nof_slaves >1 else ': STD_LOGIC;\n' }
        wv_dict = {'postfix' : 'wr_val', 'type' : ': STD_LOGIC;\n'}
        wb_dict = {'postfix' : 'wr_busy', 'type' : ': STD_LOGIC_VECTOR(<>.nof_slaves-1 downto 0);\n' if nof_slaves >1 else ': STD_LOGIC;\n' }

        wr_en_dict = {'postfix' : 'wr_en', 'type' : ': STD_LOGIC_VECTOR(<>.nof_slaves-1 downto 0);\n' if nof_slaves > 1 else ': STD_LOGIC;\n' }
        wr_en_vec_dict = {'postfix' : 'wr_en_vec', 'type' : ': STD_LOGIC_VECTOR(0 downto 0);\n' }
        wr_val_dict = {'postfix' : 'wr_val', 'type' : ': STD_LOGIC_VECTOR(<>.nof_slaves-1 downto 0);\n' if nof_slaves >1 else ': STD_LOGIC;\n' }
        wr_val_vec_dict = {'postfix' : 'wr_val_vec', 'type' : ': STD_LOGIC_VECTOR(0 downto 0);\n' }
        adr_dict = {'postfix' : 'adr', 'type' : ': STD_LOGIC_VECTOR(<>.adr_w-1 downto 0);\n' }
        rd_en_dict = {'postfix' : 'rd_en', 'type' : ': STD_LOGIC_VECTOR(<>.nof_slaves-1 downto 0);\n' if nof_slaves > 1 else ': STD_LOGIC;\n'}
        rd_dat_dict = {'postfix' : 'rd_dat', 'type' : ': t_slv_'+str(regGroup.width())+'_arr(0 to <>.nof_slaves-1);\n' if nof_slaves > 1 else ': STD_LOGIC_VECTOR(<>.dat_w-1 downto 0);\n' }
        rd_val_dict = {'postfix' : 'rd_val', 'type' : ': STD_LOGIC_VECTOR(<>.nof_slaves-1 downto 0);\n' if nof_slaves >1 else ': STD_LOGIC;\n' }


        if ram :
            # if regGroup.access_mode() == "RW":
            dict_list = [wr_en_dict, wr_val_dict, adr_dict, rd_en_dict, rd_dat_dict, rd_val_dict]
            if nof_slaves == 1 :
                dict_list.extend([wr_en_vec_dict, wr_val_vec_dict])
            reg_name = regGroup_name + '_' + reg_name
            # else : # RO
        else:
            dict_list = [ro_dict, rw_dict, pr_dict, pw_dict, rd_dict, wv_dict, rv_dict, rb_dict, wb_dict]
        c_mm_reg =  'c_mm_' + reg_name + ('_reg' if not ram else '_ram')
        for dict in dict_list:
            lines.append('\tSIGNAL ' + reg_name +  '_' + dict['postfix'] + '<tabs>' + dict['type'].replace('<>', c_mm_reg))
        lines.append('\n')
        lines = tab_aligned(lines)

        # signal names for any counters
        if (not ram):
            field_list = regGroup.fields
            for field in field_list:
                if ((field.access_mode() == 'CW') or (field.access_mode() == 'CS')):
                    count_name = regGroup.name() + '_' + field.name()
                    count_name_t = 't_' + regGroup.name() + '_' + field.name()   # just a std_logic_vector of width field.width()
                    count_name_array_t = 't_array_' + regGroup.name() + '_' + field.name()
                    nslave_name = '(c_mm_' + regGroup.name() + '_reg.nof_slaves-1)'
                    lines.append('    type ' + count_name_array_t + ' is array(0 to ' + nslave_name + ') of ' + count_name_t +  ';\n')
                    lines.append('    signal ' + count_name + ' : ' + count_name_array_t + ';\n')
                    rst_name_final = regGroup.name() + '_' + field.name() + '_rst'                     # or'ed reset with external reset.
                    lines.append('    signal ' + rst_name_final + ' : std_logic_vector(0 to ' + nslave_name + ');\n')
        
        return(lines)

    def input_statements(self, regGroup):
        lines = []
        field_list = regGroup.fields
        if regGroup.number_of_slaves() > 1 :
            lines.append('\t' + regGroup.name() + '_nof_slaves_fb: FOR i in 0 to c_mm_' + regGroup.name() + '_reg.nof_slaves-1 GENERATE\n\n')
            slave_offset = 'c_mm_<reg_name>_reg.dat_w*c_mm_<reg_name>_reg.nof_dat*i + '
            tab_no = 2
            index = '(i)'
            index_counters = '(i)'
        else :
            slave_offset = ''
            tab_no = 1
            index = ''
            index_counters = '(0)'

        for field in field_list:
            upper_bit = field.bit_offset() + field.width() - 1
            if field.access_mode() == 'SP':
                mapped_field = 'x"{:08x}"'.format(field.reset_value())
                lines.append("\t-- Special constant value {} for field: {}\n".format(mapped_field, field.name()))
            elif ((field.access_mode() == 'CW') or (field.access_mode() == 'CS')):
                mapped_field = regGroup.name() + '_' + field.name() + index_counters
            elif field.side_effect() != 'PW': # and field.side_effect() != 'PR':
                mapped_field = regGroup.name().upper() + '_FIELDS_RO.'+ field.name() + index if field.access_mode() == 'RO' else '<reg_name>_out_reg('+slave_offset+'c_byte_w*' + str(field.address_offset()) \
                        + ('+' + str(upper_bit) if upper_bit is not 0 else '') \
                        + ((' downto '+slave_offset+'c_byte_w*'+ str(field.address_offset()) + ('+' + str(field.bit_offset()) if field.bit_offset() is not 0 else '')) if field.width() > 1 else '') \
                        + ')'   # doesn't test for other cases WO etc.
            else :
                mapped_field = '\'' + '0'*field.width() + '\''
                if field.width() > 1 :
                    mapped_field = mapped_field.replace('\'', '\"')
            if field.width() > 1:
                line = '\t'*tab_no +'<reg_name>_in_reg('+slave_offset+'c_byte_w*' + str(field.address_offset()) + ('+' + str(upper_bit) if upper_bit is not 0 else '' ) +  ' downto '+slave_offset+'c_byte_w*'+ str(field.address_offset()) + ('+' + str(field.bit_offset()) if field.bit_offset() is not 0 else '') + ')<tabs><= ' + mapped_field +  ';\n'
                lines.append(line)
                # lines.append('\t\t' + regGroup.name() + '_in_reg( + c_mm_' + regGroup.name() + '_reg.dat_w*' + str(field.address_offset()) +  ('+' + str(upper_bit) if upper_bit is not 0 else '' )  + ' downto c_mm_reg.dat_w*'+ str(field.address_offset()) + ('+' + str(field.bit_offset()) if field.bit_offset() is not 0 else '') + ') <= ' + mapped_field +  ';\n')
            else :
                line = '\t'*tab_no + regGroup.name() +'_in_reg('+slave_offset+'c_byte_w*' + str(field.address_offset()) +  ('+' + str(upper_bit) if upper_bit is not 0 else '' )  + ')<tabs><= ' + mapped_field + ';\n'
                lines.append(line)
        if regGroup.number_of_slaves() > 1 :
            lines.append('\n\tEND GENERATE;\n\n')
        lines = [line.replace('<reg_name>', regGroup.name()) for line in lines]
        lines = tab_aligned(lines)
        return(lines)

    def output_statements(self, regGroup):
        lines = []
        field_list = regGroup.fields
        if regGroup.number_of_slaves() > 1:
            lines.append('\t' + regGroup.name() + '_nof_slaves_outputs: FOR i in 0 to c_mm_' + regGroup.name() + '_reg.nof_slaves-1 GENERATE\n\n')
            slave_offset = 'c_mm_<reg_name>_reg.dat_w*c_mm_<reg_name>_reg.nof_dat*i + '
            slave_offset_pulse = 'c_mm_<reg_name>_reg.nof_dat*i + '
            tab_no = 2
            index = '(i)'
        else :
            slave_offset = ''
            slave_offset_pulse = ''
            tab_no = 1
            index = ''
        for field in field_list:
            if field.access_mode() == 'RW':
                upper_bit = field.bit_offset() + field.width() - 1
                side_effect = ''
                # multiple side effects need to be supported
                if  'P' in field.side_effect():
                    side_effect_string = '<reg_name>_pulse_<>('+ slave_offset_pulse + str(word_wise(field.address_offset()))
                    side_effect_string = (side_effect_string + ')') if field.width() == 1 else '(' + str(field.width()-1) + ' downto 0 => ' + side_effect_string + '))'
                    if 'PW' in field.side_effect() and 'PR' in field.side_effect():
                        side_effect = '(' + side_effect_string.replace('<>', 'write') + ' OR ' + (side_effect_string.replace('<>', 'read')) + ') AND '
                    else :
                        side_effect = side_effect_string.replace('<>', 'write' if 'PW' in field.side_effect() else 'read') + ' AND '
                if field.width() > 1:
                    lines.append(tab_no*'\t'+ regGroup.name().upper()+'_FIELDS_RW.'+ field.name() +index+'<tabs><= '+side_effect+'<reg_name>_out_reg('+ slave_offset +'c_byte_w*' + str(field.address_offset()) + ('+' + str(upper_bit) if upper_bit is not 0 else '' ) + ' downto '+ slave_offset +'c_byte_w*'+ str(field.address_offset()) +(  '+' +   str(field.bit_offset()) if field.bit_offset() is not 0 else '') + ');\n')
                else :
                    lines.append(tab_no*'\t'+ regGroup.name().upper()+'_FIELDS_RW.'+ field.name() +index+'<tabs><= '+side_effect+'<reg_name>_out_reg('+ slave_offset +'c_byte_w*' + str(field.address_offset()) + ('+' + str(upper_bit) if upper_bit is not 0 else '' ) + ');\n')
            if field.access_mode() == 'RO':
                if field.side_effect() == 'PR':
                    side_effect_string = '<reg_name>_pulse_read('+ slave_offset_pulse + str(word_wise(field.address_offset())) + ')'
                    lines.append(tab_no*'\t'+ regGroup.name().upper()+'_FIELDS_PR.'+ field.name() +index+'<tabs><= '+side_effect_string + ';\n')
                #if field.side_effect() == 'PW':
                #    # "Read only" register can still generate a side effect when written.
                #    # Use case is as a reset signal for a counter, i.e. no change on read, clear on write.
                #    side_effect_string = '<reg_name>_pulse_write('+ slave_offset_pulse + str(word_wise(field.address_offset())) + ')'




        # lines.append('\n')
        # for field in field_list:
            # if field.side_effect() == 'PR':
                # lines.append('\t\t' + regGroup.name().upper() + '_PULSE_R.'+ field.name() + '(i)<tabs><= <reg_name>_pulse_read(' + str(field.address_offset()) + ');\n')
            # if field.side_effect() == 'PW':
                # lines.append('\t\t' + regGroup.name().upper() + '_PULSE_W.'+ field.name() + '(i)<tabs><= <reg_name>_pulse_write(' + str(field.address_offset()) + ');\n')
        if regGroup.number_of_slaves() > 1 :
            lines.append('\n\tEND GENERATE;\n\n')
        lines = [line.replace('<reg_name>', regGroup.name()) for line in lines]
        lines = tab_aligned(lines)

        return(lines)
    
    def instantiate_rams(self):
        lines = []
        for ram in self.regGroup.rams:
            # logger.info("slave %s ram %s ceillog2(base_address)%d(%d) ceillog2(nof_dat)%d (%d)", regGroup.name(), ram.name(), ram.base_address(), ceil_log2(ram.base_address()) if ram.base_address() != 0 else 0, ram.number_of_fields(), ceil_log2(ram.number_of_fields()))
            sublines = []
            sublines.append(('\t<>_adr <= wr_adr(c_mm_<>_ram.adr_w-1 downto 0) WHEN <>_wr_en '+ ('= \'1\'' if self.regGroup.number_of_slaves() == 1 else '/= (<>_wr_en\'range => \'0\')')+' ELSE\n\t\t\t\trd_adr(c_mm_<>_ram.adr_w-1 downto 0);\n\n ').replace('<>', self.regGroup.name() + '_' + ram.name()))
            if self.regGroup.number_of_slaves() > 1:
                sublines.append(('\t<>_' + ram.name() + '_gen: FOR i in 0 to c_mm_<>_reg.nof_slaves-1 GENERATE\n').replace('<>', self.regGroup.name()))
            with open(os.path.join(self.rootDir,'templates/template_common_ram_rw_rw.vho'), 'r') as inst_file:
                for subline in inst_file:
                    for tag, replace_string in {'<field_name>' : self.regGroup.name() + '_' + ram.name(), '<FIELD_NAME>': (self.regGroup.name() + '_' +ram.name()).upper(), '<reg_name>': self.regGroup.name(), '(i)' : '' if self.regGroup.number_of_slaves() == 1 else '(i)', '+ i' : '' if self.regGroup.number_of_slaves() == 1 else '+ i'}.items():
                        subline = subline.replace(tag, replace_string)
                    if self.regGroup.number_of_slaves() > 1:
                        subline = '\t' + subline
                    sublines.append(subline)
            if self.regGroup.number_of_slaves() > 1:
                sublines.append('\tEND GENERATE;\n\n')
            with open(os.path.join(self.rootDir, 'templates/template_common_pipeline.vho'),'r') as inst_file:
                # sublines.extend(subline.replace('<field_name>', regGroup.name() + '_' + ram.name()) for subline in inst_file)
                for subline in inst_file:
                    if '<nof_slaves>' in subline:
                        if self.regGroup.number_of_slaves() == 1:
                            subline = subline.replace('<nof_slaves>','')
                            sublines.append(subline.replace('<field_name>', self.regGroup.name() + '_' + ram.name()))
                    else:
                        subline = subline.replace('<_vec>', '_vec' if self.regGroup.number_of_slaves() == 1 else '')
                        sublines.append(subline.replace('<field_name>', self.regGroup.name() + '_' + ram.name()))
            lines.extend(sublines)
        return(lines)

    def instantiate_counters(self,regGroup):
        # Counters are registers with access type of either
        #    "CW" = count wrap
        # or "CS" = Count saturate
        # Counters reset on write, and have a single input to the registers module to enable count up.
        lines = []
        field_list = regGroup.fields

        # get the name of the clock and reset for this counter
        if regGroup.get_kv("dual_clock"):
            # number of clocks is regGroup.number_of_slaves
            clk_name = 'st_clk_' + regGroup.name() + '(i)'
        else:
            clk_name = 'mm_clk'

        any_counters = False
        for field in field_list:
            if ((field.access_mode() == 'CS') or (field.access_mode() == 'CW')):
                any_counters = True
                
        if (any_counters):
            subline = '    counters_gen : FOR i in 0 to c_mm_' + regGroup.name() + '_reg.nof_slaves-1 GENERATE\n'
            lines.extend(subline)

            for field in field_list:
                sublines = []
                count_name = regGroup.name() + '_' + field.name() + '(i)'
                rst_name = regGroup.name() + '_pulse_write(' + str(word_wise(field.address_offset()))  + ')' # reset from the write pulse
                rst_name_final = regGroup.name() + '_' + field.name() + '_rst(i)'                     # or'ed reset with external reset.
                if (field.access_mode() == 'CS'):
                    # count saturate, instantiate a component to do the count
                    sublines.append('        process('+ clk_name + ')\n')
                    sublines.append('        begin \n')
                    sublines.append('            if rising_edge(' + clk_name + ') then \n')
                    sublines.append('                ' + rst_name_final + ' <= count_rsti or ' + rst_name + ';\n')
                    sublines.append('            end if;\n')
                    sublines.append('        end process;\n\n')
                    sublines.append('        ' + field.name() + 'csi : ENTITY common_lib.common_count_saturate\n')
                    sublines.append('        generic map(\n')
                    sublines.append('            WIDTH => ' + str(field.width()) + ')\n')
                    sublines.append('        port map (\n')
                    sublines.append('            enable   => ' + regGroup.name() + '_fields_count.' + field.name() + ',\n')
                    sublines.append('            clk      => ' + clk_name + ',\n')
                    sublines.append('            rst      => ' + rst_name_final + ',\n')
                    sublines.append('            count    => ' + count_name + '\n')
                    sublines.append('        );\n\n')
                
                elif (field.access_mode() == 'CW'):
                    # count wrap, create a clocked process to do the count
                    sublines.append('        process(' + clk_name + ')\n')
                    sublines.append('        begin \n')
                    sublines.append('            if rising_edge(' + clk_name + ') then \n')
                    sublines.append('                ' + rst_name_final + ' <= count_rsti or ' + rst_name + ';\n')
                    sublines.append('                if ' + rst_name_final + ' = \'1\' then \n')
                    sublines.append('                    ' + count_name + ' <= (others => \'0\');\n')
                    sublines.append('                elsif '  + regGroup.name() + '_fields_count.' + field.name() +  ' = \'1\' then \n')
                    sublines.append('                    ' + count_name + ' <= std_logic_vector(unsigned(' + count_name + ') + 1);\n')
                    sublines.append('                end if;\n')
                    sublines.append('            end if;\n')
                    sublines.append('        end process;\n\n')

                lines.extend(sublines)

            subline = '    end GENERATE;\n\n'
            lines.extend(subline)
        return(lines)

        
    
    def c_mm_reg(self, replace_dicts):
        lines = []
        tmpl_file = os.path.join(self.rootDir, 'templates/template_c_mm_reg.vho')
        for ram in self.regGroup.rams:
            sublines = []
            with open(tmpl_file, 'r') as inst_file:
                for subline in inst_file:
                    for tag, replace_string in {'<reg_name>' : self.regGroup.name() + '_' + ram.name(),'<reg_ram>': 'ram', '<adr_w>' : str(ceil_log2(ram.number_of_fields())), '<nof_dat>' : str(ram.number_of_fields()), '<nof_slaves>' : self.regGroup.number_of_slaves(), '<addr_base>' : str(int(ram.base_address()/WIDTH_IN_BYTES)), '<dat_w>' : ram.width()}.items():
                        subline = subline.replace(tag, str(replace_string))
                    if 'STD_LOGIC_VECTOR' not in subline: sublines.append(subline)
            lines.extend(sublines)
            lines.append('\n\n')
        sublines = []
        with open(tmpl_file, 'r') as inst_file:
            for subline in inst_file:
                for tag, replace_string in replace_dicts[self.regGroup.name()].items():
                    subline = subline.replace(tag, str(replace_string))
                sublines.append(subline)
        lines.extend(sublines)
        lines.append('\n\n')
        return(lines)

    def read_write_vals(self, i, nof_regs, read_write = 'rd'):
        lines = []
        
        for ram in self.regGroup.rams:
            for j in range(self.regGroup.number_of_slaves()):
                # Was:
                #   lines.append('\t\t' + self.regGroup.name() + '_' + ram.name() + '_' + read_write + '_val' + ('('+str(j)+')' if self.regGroup.number_of_slaves() > 1 else '') + (';' if (i == self.regGroup.number_of_slaves()-1 and ram == self.regGroup.rams[-1] and len(self.regGroup.fields) == 0) else ' OR\n'))
                # But there is always an extra condition added outside the ram for loop, so always put an OR after each signal here.
                lines.append('\t\t' + self.regGroup.name() + '_' + ram.name() + '_' + read_write + '_val' + ('('+str(j)+')' if self.regGroup.number_of_slaves() > 1 else '') + ' OR\n')
                        
        lines.append('\t\t' + self.regGroup.name() + '_'+ read_write +'_val' + (';\n\n' if i == nof_regs -1 else ' OR '))
        
        return lines

    def read_write_busys(self, i, nof_regs, read_write = 'rd'):
        lines = []

        lines.append('\t\t' + self.regGroup.name() + '_'+ read_write +'_busy' + (';\n\n' if i == nof_regs -1 else ' OR '))
        return lines

    def read_data_compare(self, regGroup, i, nof_regs):
        lines = []
        for ram in regGroup.rams:
            partial = 32 - ram.width()
            others = '' if partial == 0 else '\'0\' & '  if partial == 1 else '\"'+'0'*partial+'\" & '
            for j in range(regGroup.number_of_slaves()):
                lines.append('\t'*2 + others + regGroup.name() + '_' + ram.name() + '_rd_dat' + ('('+str(j)+')' if regGroup.number_of_slaves() > 1 else '') + (';' if (i == regGroup.number_of_slaves()-1 and ram == regGroup.rams[-1] and len(regGroup.fields) == 0) else ' WHEN '+regGroup.name() + '_' + ram.name()+'_rd_val<> = \'1\' ELSE\n'.replace('<>', '(' + str(j) + ')' if regGroup.number_of_slaves() > 1 else '')))
        lines.append('\t'*2 + regGroup.name() + '_rd_dat' + (';\n\n' if i == nof_regs -1 else ' WHEN ' + regGroup.name() + '_rd_val = \'1\' ELSE\n'))
        return lines
    # def fix_mem_size(self, slaveSettings, slave_type): # should be in peripheral.py
        # if slaveSettings.() < 32:
            # logger.warning('Updating %s width %d to 32 (minimum data width)', slave_type, slaveSettings.width())
            # slaveSettings.width(32)

        # if slave_type.lower() == 'ram':
            # if slaveSettings.address_length() < 1024:
                # slaveSettings.depth(1024)


            # if slaveSettings.width_b() == slaveSettings.width() :
                # self.depth_b = slaveSettings.address_length()
            # else :
                # self.depth_b = slaveSettings.address_length() / (slaveSettings.width_b()/slaveSettings.width())
                # if self.depth_b < 1024:
                    # logger.warning('BRAM port B violation: BRAM controller requires minimum depth of 1k')

        # elif slave_type.lower() == 'fifo':
            # if slaveSettings.address_length() < 512:
                # slaveSettings.depth(512)

        # return


