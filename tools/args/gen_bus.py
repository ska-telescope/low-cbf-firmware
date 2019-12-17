#################################################################################
#
#
#   Bus assumptions:
#   - optional user signals not used
#   - Has BURST 1
#   - Has LOCK 0 (AXI4 does not support locked transactions)
#   - Has CACHE 0
#   - Has PROT 0
#
#################################################################################

import os
import logging
import common as cm
import collections
from py_args_lib import *
from fpga import FPGA
import numpy as np
from gen_slave import tab_aligned
logger = logging.getLogger('main.gen_bus')

def get_cmd(raw_line):
    return raw_line.split('}>')[-1]

class Bus(object):
    """
        A bus is generated based on a FPGA object which is a collection of peripherals from different peripheral libraries
    """
    def __init__(self, fpga):
        self.fpga = fpga
        self.root_dir   = os.path.expandvars('$RADIOHDL/tools/args')
        self.out_dir    = os.path.expandvars('$HDL_BUILD_DIR/ARGS/{}'.format(self.fpga.system_name))
        self.tmpl_mstr_port_full = os.path.join(self.root_dir, 'templates/template_bus_master_axi_full.vho')
        self.tmpl_mstr_port_lite = os.path.join(self.root_dir, 'templates/template_bus_master_axi_lite.vho')
        self.tmpl_mstr_port_cast = os.path.join(self.root_dir, 'templates/template_bus_master_port_casting.vho')
        self.tmpl_bus_pkg = os.path.join(self.root_dir, 'templates/template_bus_pkg.vhd')
        self.tmpl_bus_top = os.path.join(self.root_dir, 'templates/template_bus_top.vhd')
        self.tmpl_tcl = os.path.join(self.root_dir, 'templates/template_create_bd.tcl')
        self.bus_config  = {'burst':'1','lock':'1', 'cache':'1', 'prot':'1', 'qos':'0','region':'0','wstrb':'1'}
        self.lite_slaves = []
        self.full_slaves = []
        self.nof_slaves = self.fpga.nof_lite + self.fpga.nof_full
        self.output_files = []
        self.vhd_replace_dict = {'<nof_lite_slaves>' : str(self.fpga.nof_lite), '<nof_full_slaves>' : str(self.fpga.nof_full),
        '<fpga_name>':self.fpga.system_name }
        self.nof_interconnects = int(np.ceil((max(1,self.nof_slaves-1))/15))
        self.indexes = self.calc_indexes()
        self.tcl_replace_dict = {'<fpga_name>':self.fpga.system_name, '<nof_slaves>' : str(self.nof_slaves)}

    def gen_tcl(self):

        lines = []
        with open(self.tmpl_tcl, 'r') as infile:
            input = list(infile)
        for line_num, line in enumerate(input):
            if '<{' not in line:
                for tag, replace_string in self.tcl_replace_dict.items():
                    line = line.replace(tag, replace_string)
                lines.append(line)
            else :
                if 'create_interconnects' in line:
                    for i in range(self.nof_interconnects):
                        lines.append(get_cmd(line).format(i))
                        nof_slaves = 16 if i < (self.nof_interconnects - 1) else (self.nof_slaves - i*15)
                        lines.append(get_cmd(input[line_num+1]).replace('<i_nof_slaves>', str(nof_slaves)))
                        lines.extend([get_cmd(input[line_num+2]).replace('<i>',str(i).zfill(2)) for i in range(nof_slaves)])
                        lines.append(get_cmd(input[line_num+3]).format(i))
                if 'connect_clock_pins' in line:
                    for i in range(self.nof_interconnects):
                        lines.append(get_cmd(line).format(i,0, 'S').replace('S00_',''))
                        lines.append(get_cmd(line).format(i,0, 'S'))
                        if i < (self.nof_interconnects-1):
                            lines.append(get_cmd(line).format(i,15,'M'))
                    for i in range(self.nof_slaves):
                        lines.append(get_cmd(line).format(self.indexes[i][0],self.indexes[i][1], 'M'))
                if 'connect_reset_pins' in line:
                    for i in range(self.nof_interconnects):
                        lines.append(get_cmd(line).format(i,0, 'S').replace('S00_',''))
                        lines.append(get_cmd(line).format(i,0, 'S'))
                        if i < (self.nof_interconnects-1):
                            lines.append(get_cmd(line).format(i,15,'M'))
                    for i in range(self.nof_slaves):
                        lines.append(get_cmd(line).format(self.indexes[i][0],self.indexes[i][1], 'M'))
                if 'create_master_ports' in line:
                    last_port = -1
                    last_prot = None
                    i = -1
                    # for i, slave_attr in enumerate(self.fpga.address_map.values()):
                    for slave_attr in self.fpga.address_map.values():
                        if slave_attr['port_index'] == last_port and slave_attr['type'] == last_prot:
                            continue; # skip port indexes already dealt with
                        i = i+1
                        last_port = slave_attr['port_index']
                        last_prot = slave_attr['type']
                        if np.mod(i, 15) == 0 and self.indexes[i][1] == 0 and i != 0:
                            lines.append(get_cmd(input[line_num+4])) # daisy chain interconnects
                            lines.append(get_cmd(input[line_num+5]).format(self.indexes[i][0]-1, self.indexes[i][0]))
                        lines.append(get_cmd(line).replace('<i>',str(i).zfill(2)))
                        _protocol = 'AXI4LITE' if slave_attr['type'] == 'LITE' else 'AXI4'
                        lines.append(get_cmd(input[line_num+1]).format(self.indexes[i][0],self.indexes[i][1], i))
                        _line = get_cmd(input[line_num+2]).replace('<protocol>', _protocol)
                        lines.append(_line.replace('<i>',str(i).zfill(2)))
                        fifo_access = slave_attr.get('access',None)
                        if fifo_access is not None:
                            _line = get_cmd(input[line_num+6]).replace('<access_mode>', 'READ' if fifo_access == 'RO' else 'WRITE')
                            lines.append(_line.replace('<i>',str(i).zfill(2)))
                        lines.append(get_cmd(input[line_num+3]).format(self.indexes[i][0],self.indexes[i][1], i))
                if 'set_address_small_range' in line:
                    last_port = -1
                    last_prot = None
                    i = -1
                    for slave_attr in self.fpga.address_map.values():
                        if slave_attr['port_index'] == last_port and slave_attr['type'] == last_prot:
                            continue
                        i = i+1
                        last_port = slave_attr['port_index']
                        last_prot = slave_attr['type']
                        if isinstance(slave_attr['slave'], Register):
                            if not getattr(slave_attr['slave'], 'isIP', False):
                                span = cm.ceil_pow2(max(slave_attr['peripheral'].reg_len, 4096))
                            else :
                                span = cm.ceil_pow2(max(slave_attr['slave'].address_length(), 4096))
                        else :
                            span = slave_attr['span']
                        _line = get_cmd(line).replace('<range>', '4') # 4k is minimum settable size for vivado
                        lines.append(_line.replace('<i>',str(i).zfill(2)))
                if 'set_address_map' in line:
                    last_port = -1
                    last_prot = None
                    i = -1
                    for slave_attr in self.fpga.address_map.values():
                        if slave_attr['port_index'] == last_port and slave_attr['type'] == last_prot:
                            continue
                        i = i+1
                        last_port = slave_attr['port_index']
                        last_prot = slave_attr['type']
                        _line = get_cmd(line).replace('<address>', "{:08x}".format(slave_attr['base']))
                        lines.append(_line.replace('<i>',str(i).zfill(2)))
                if 'set_address_range' in line:
                    last_port = -1
                    last_prot = None
                    i = -1
                    for slave_attr in self.fpga.address_map.values():
                        if slave_attr['port_index'] == last_port and slave_attr['type'] == last_prot:
                            continue
                        i = i+1
                        last_port = slave_attr['port_index']
                        last_prot = slave_attr['type']
                        if isinstance(slave_attr['slave'], Register):
                            if not getattr(slave_attr['slave'], 'isIP', False):
                                span = cm.ceil_pow2(max(slave_attr['peripheral'].reg_len, 4096))
                            else :
                                span = cm.ceil_pow2(max(slave_attr['slave'].address_length(), 4096))
                        else :
                            span = slave_attr['span']
                        lines.append('# interconnect[{}]  <{}>   base: 0x{:08x} span: 0x{:06x}\n'.format(i, slave_attr['peripheral'].name(), slave_attr['base'], span))
                        _line = get_cmd(line).replace('<range>', str(int(span/1024)))
                        lines.append(_line.replace('<i>',str(i).zfill(2)))

        return lines

    def gen_vhdl(self):
        lines = []
        slave_index = -1
        add_lines = []
#        if self.fpga.nof_full == 0 or self.nof_slaves == 1  :
#            self.vhd_replace_dict.update({'<sla_in_vec>':'SLA_IN','<sla_out_vec>':'SLA_OUT','<(0)>':'     '})
#        else :
#            self.vhd_replace_dict.update({'<sla_in_vec>':'sla_in_vec','<sla_out_vec>':'sla_out_vec','<(0)>':'(0)  '})
        with open(self.tmpl_bus_top, 'r') as infile:
            for line in infile:
#                if '<{std_ulogic_casting}>' in line:
#                    input = list(open(self.tmpl_mstr_port_cast,'r'))
#                    last_port = -1
#                    last_prot = None
#                    for slave_port, slave_dict in self.fpga.address_map.items():
#                        if slave_dict['port_index'] == last_port and slave_dict['type'] == last_prot:
#                            continue
#                        last_port = slave_dict['port_index']
#                        last_prot = slave_dict['type']
#                        if self.fpga.nof_full == 0 or slave_dict['type'] == 'FULL':
#                            bad_tags = ['lock','last'] if slave_dict['type'] == 'LITE' else []
#                            _input = [_line for _line in input if not any([bad_tag in _line for bad_tag in bad_tags])]
#                            add_lines = [line.format(slave_dict['type'],slave_dict['port_index'], slave_dict['type'].lower()) for line in _input]
#                            lines.extend(add_lines)
                if '<{master_interfaces}>' in line:
                    last_port = -1
                    last_prot = None
                    for slave_port, slave_dict in self.fpga.address_map.items():
                        if slave_dict['port_index'] == last_port and slave_dict['type'] == last_prot:
                            continue
                        last_port = slave_dict['port_index']
                        last_prot = slave_dict['type']
                        slave_index = slave_index + 1
                        if self.fpga.nof_full == 0 and self.fpga.nof_lite > 1 :
                            zero_index = '(0)'
#                            sig_out = 'mstr_out_lite_vec'
#                            sig_in = 'mstr_in_lite_vec'
                        else :
                            zero_index = ''
#                            sig_out = 'MSTR_OUT_LITE'
#                            sig_in = 'MSTR_IN_LITE'
                        template_file = self.tmpl_mstr_port_lite if slave_dict['type'] == 'LITE' else self.tmpl_mstr_port_full
                        input = list(open(template_file, 'r'))

#                        # If we have more than 16 slaves, lite interfaces >= 15 use vector for std_logic
#                        if (self.fpga.nof_full + self.fpga.nof_lite) > 16:
#                           if slave_index > 14 and slave_dict['type'] == 'LITE':
#                              zero_index = '(0)'

                        add_lines = [line.format(slave_index, slave_dict['port_index'], zero_index) for line in input]
                        if slave_index == (self.nof_slaves-1): # remove last comma to avoid vhdl syntax error
                            for line_no, line in enumerate(add_lines[::-1]):
                                if ',' in line and '--' not in line:
                                    add_lines[len(add_lines)-line_no-1] = line.replace(',','')
                                    break
                        lines.extend(add_lines)
                else:
                    for key in self.vhd_replace_dict.keys():
                        if key in line:
                            line = line.replace(key, str(self.vhd_replace_dict[key]))
                    lines.append(line)

        # Strip out full (or liet interfaces & correct syntax)
        if self.fpga.nof_full == 0:
            bad_tags = ['mstr_out_full','mstr_in_full']
            for line_num, line in enumerate(lines):
                if 'MSTR_OUT_LITE' in line:
                    lines[line_num] = line.replace(';','')
                    break
        else :
            bad_tags = ['region']
        if self.fpga.nof_lite == 0:
            bad_tags.extend(['mstr_in_lite', 'mstr_out_lite'])
        lines = [line for line in lines if not any([bad_tag in line.lower() for bad_tag in bad_tags])]
        return lines

    def gen_pkg(self):
        lines = []
        input = list(open(self.tmpl_bus_pkg, 'r'))
        for line in input:
            if '<{' not in line:
                for tag, replace_string in self.vhd_replace_dict.items():
                    line = line.replace(tag, replace_string) if tag in line else line
                lines.append(line)
            else :
                sublines = []
                type = line.split('<{')[-1].split('}>')[0]
                line = line.split('<{')[-1].split('}>')[-1]
                last_port = -1
                last_prot = None
                for slave_port, slave_dict in self.fpga.address_map.items():
                    if slave_dict['port_index'] == last_port and slave_dict['type'] == last_prot:
                        continue
                    last_port = slave_dict['port_index']
                    last_prot = slave_dict['type']
                    if slave_dict['type'] == type:
                        sublines.append(line.format(slave_dict['peripheral'].name(), slave_dict['port_index']))
                lines.extend(tab_aligned(sublines))

        return lines

    def gen_file(self, file_type):
        lines = []
        if file_type == 'vhd':
            lines = self.gen_vhdl()
            out_file = self.fpga.system_name + '_bus_top.vhd'
        if file_type == 'tcl':
            lines = self.gen_tcl()
            out_file = self.fpga.system_name + '_bd.tcl'
        if file_type == 'pkg':
            lines = self.gen_pkg()
            out_file = self.fpga.system_name + '_bus_pkg.vhd'
        try:
            os.stat(self.out_dir)
        except:
            os.mkdir(self.out_dir)
        file_name = os.path.join(self.out_dir, out_file)
        with open(file_name, 'w') as out_file:
            for line in lines:
                out_file.write(line)
        logger.info('Generated ARGS output %s', file_name)
        self.output_files.append(file_name)

    def gen_firmware(self):
        self.gen_file('pkg')
        self.gen_file('vhd')
        self.gen_file('tcl')
        return self.output_files

    def calc_indexes(self):
        """
        Calculate interconnects and local slave port numbers for all slaves
        """
        index_list = []
        for i in range(self.nof_slaves):
            if np.floor(i/15) < self.nof_interconnects:
                interconnect_num = int(np.floor(i/15))
            else :
                interconnect_num = int(np.floor(i/15)-1)
            if np.mod(i,15) == 0 and i == (self.nof_slaves-1) and self.nof_interconnects > 1  :
                local_slave_num = 15
            else :
                local_slave_num = np.mod(i,15)
            logger.debug("slave_{} on interconnect {} with local port {} nof_interconnects {}".format(i, interconnect_num, local_slave_num, self.nof_interconnects))

            index_list.append((interconnect_num, local_slave_num))
        return index_list

