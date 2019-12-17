#! /usr/bin/env python
###############################################################################
#
# Copyright (C) 2014
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
###############################################################################

"""HDL configuration for building Quartus synthesis targets.

   Usage:
   > python $RADIOHDL/tools/oneclick/base/quartus_config.py -t unb2a
"""

import common as cm
import hdl_config
import sys
import os.path
import argparse

class QuartusConfig(hdl_config.HdlConfig):

    def __init__(self, toolRootDir, libFileName='hdllib.cfg', toolFileName='hdltool_<toolset>.cfg'):
        """Get Quartus tool info from toolRootDir and all HDL library info from libRootDir.
        
           This class uses the default keys and the keys from the libFileSections in the libFileName config file.
           
           Arguments:
           - toolRootDir     : Root directory from where the hdltool_<toolset>.cfg file is searched for.
           - libFileName     : Default HDL library configuration file name
           - toolFileName    : Default HDL tools configuration file name
           
           The libRootDir is defined in the hdltool_<toolset>.cfg file and is the root directory from where the hdllib.cfg
           files are searched for.
           
           The technologyNames parameter is defined in the hdltool_<toolset>.cfg file. All generic HDL libraries and these
           technology specific libraries are kept.
           
           Files:
           - hdltool_<toolset>.cfg : HDL tool configuration dictionary file. One central file per toolset.
           
           - hdllib.cfg : HDL library configuration dictionary file. One file for each HDL library.
           
           - <lib_name>.qpf : Quartus project file (QPF) for a certain HDL library based on the hdllib.cfg. The file is created by
                              create_quartus_project_file().
                              
           - <lib_name>.qsf : Quartus settings file (QSF) for a certain HDL library based on the hdllib.cfg. The file is created by
                              create_quartus_settings_file(). There is one QSF per Quartus synthesis project.
        """
        libFileSections=['quartus_project_file']
        hdl_config.HdlConfig.__init__(self, toolRootDir, libFileName, libFileSections, toolFileName)

    def create_quartus_ip_lib_file(self, lib_names=None):
        """Create the Quartus IP file <hdl_lib_name>_lib.qip for all HDL libraries. The <hdl_lib_name>.qip file contains the list of files that are given
           by the synth_files key and the quartus_*_file keys.
           
           Note:
           . Use post fix '_lib' in QIP file name *_lib.qip to avoid potential conflict with *.qip that may come with the IP.
           . The HDL library *_lib.qip files contain all files that are listed by the synth_files key. Hence when these qip files are included then
             the Quartus project will analyse all files even if there entity is not instantiated in the design. This is fine, it is unnecessary
             to parse the hierarchy of the synth_top_level_entity VHDL file to find and include only the source files that are actually used.
        
           Arguments:
           - lib_names      : one or more HDL libraries
        """
        if lib_names==None: lib_names=self.lib_names
        lib_dicts = self.libs.get_dicts('hdl_lib_name', values=lib_names)
        for lib_dict in cm.listify(lib_dicts):
            # Open qip
            lib_name = lib_dict['hdl_lib_name']
            lib_path = self.libs.get_filePath(lib_dict)
            qip_name = lib_name + '_lib.qip'
            qip_path = self.get_lib_build_dirs('synth', lib_dicts=lib_dict)
            cm.mkdir(qip_path)
            qipPathName = cm.expand_file_path_name(qip_name, qip_path)
            with open(qipPathName, 'w') as fp:
                if 'synth_files' in lib_dict:
                    fp.write('# synth_files\n')
                    synth_files = lib_dict['synth_files'].split()
                    for fn in synth_files:
                        filePathName = cm.expand_file_path_name(fn, lib_path)

                        file_ext = fn.split('.')[-1]
                        if file_ext=='vhd' or file_ext=='vhdl':
                            file_type = 'VHDL_FILE'                         
                        elif file_ext=='v':
                            file_type = 'VERILOG_FILE'                              
                        else:
                             print '\nERROR - Undefined file extension in synth_files:', fn
                             sys.exit()

                        fp.write('set_global_assignment -name %s %s -library %s\n' % (file_type, filePathName, lib_name + '_lib'))
    
                if 'quartus_vhdl_files' in lib_dict:
                    fp.write('\n')
                    fp.write('# quartus_vhdl_files\n')
                    quartus_vhdl_files = lib_dict['quartus_vhdl_files'].split()
                    for fn in quartus_vhdl_files:
                        filePathName = cm.expand_file_path_name(fn, lib_path)

                        file_ext = fn.split('.')[-1]
                        if file_ext=='vhd' or file_ext=='vhdl':
                            file_type = 'VHDL_FILE'                         
                        elif file_ext=='v':
                            file_type = 'VERILOG_FILE'                              
                        else:
                             print '\nERROR - Undefined file extension in quartus_vhdl_files:', fn
                             sys.exit()

                        fp.write('set_global_assignment -name VHDL_FILE %s -library %s\n' % (filePathName, lib_name + '_lib'))
                    
                if 'quartus_qip_files' in lib_dict:
                    fp.write('\n')
                    fp.write('# quartus_qip_files\n')
                    quartus_qip_files = lib_dict['quartus_qip_files'].split()
                    for fn in quartus_qip_files:
                        filePathName = cm.expand_file_path_name(fn, lib_path)
                        fp.write('set_global_assignment -name QIP_FILE %s\n' % filePathName)

                if 'quartus_tcl_files' in lib_dict:
                    fp.write('\n')
                    fp.write('# quartus_tcl_files\n')
                    quartus_tcl_files = lib_dict['quartus_tcl_files'].split()
                    for fn in quartus_tcl_files:
                        filePathName = cm.expand_file_path_name(fn, lib_path)
                        fp.write('set_global_assignment -name SOURCE_TCL_SCRIPT_FILE %s\n' % filePathName)
                    
                if 'quartus_sdc_files' in lib_dict:
                    fp.write('\n')
                    fp.write('# quartus_sdc_files\n')
                    quartus_sdc_files = lib_dict['quartus_sdc_files'].split()
                    for fn in quartus_sdc_files:
                        filePathName = cm.expand_file_path_name(fn, lib_path)
                        fp.write('set_global_assignment -name SDC_FILE %s\n' % filePathName)
                    
          
    def create_quartus_project_file(self, lib_names=None):
        """Create the Quartus project file (QPF) for all HDL libraries that have a toplevel entity key synth_top_level_entity.
        
           Note:
           . Default if the synth_top_level_entity key is defined but left empty then the top level entity has the same name as the lib_name in hdl_lib_name.
             Otherwise synth_top_level_entity can specify another top level entity name in the library. Each HDL library can only have one Quartus project
             file
           . The project revision has the same name as the lib_name and will result in a <lib_name>.sof FPGA image file. 
           . For each additional revision a subdirectory can be used. 
             This subdirectory can be named 'revisions/' and lists a number of revisions as subdirectories. Each revision will have a separate hdllib.cfg file and a 
             .vhd file with the toplevel entity. The toplevel .vhd file specifies the <g_design_name> for the revision in the generics. 
        
           Arguments:
           - lib_names      : one or more HDL libraries
        """
        if lib_names==None: lib_names=self.lib_names
        lib_dicts = self.libs.get_dicts(key='hdl_lib_name', values=lib_names)
        syn_dicts = self.libs.get_dicts(key='synth_top_level_entity', values=None, dicts=lib_dicts)
        for syn_dict in cm.listify(syn_dicts):
            # Open qpf for each HDL library that has a synth_top_level_entity
            lib_name = syn_dict['hdl_lib_name']
            qpf_name = lib_name + '.qpf'
            qpf_path = self.get_lib_build_dirs('synth', lib_dicts=syn_dict)
            cm.mkdir(qpf_path)
            qpfPathName = cm.expand_file_path_name(qpf_name, qpf_path)
            with open(qpfPathName, 'w') as fp:
                fp.write('PROJECT_REVISION = "%s"\n' % lib_name)
                
    def create_quartus_settings_file(self, lib_names=None):
        """Create the Quartus settings file (QSF) for all HDL libraries that have a toplevel entity key synth_top_level_entity.
        
           Note:
           . No support for revisions, so only one qsf per qpf
           
           Arguments:
           - lib_names      : one or more HDL libraries
        """
        if lib_names==None: lib_names=self.lib_names
        lib_dicts = self.libs.get_dicts(key='hdl_lib_name', values=lib_names)
        syn_dicts = self.libs.get_dicts(key='synth_top_level_entity', values=None, dicts=lib_dicts)
        for syn_dict in cm.listify(syn_dicts):
            # Open qsf for each HDL library that has a synth_top_level_entity
            lib_name = syn_dict['hdl_lib_name']
            lib_path = self.libs.get_filePath(syn_dict)
            top_level_entity = syn_dict['synth_top_level_entity']
            if top_level_entity=='':
                top_level_entity = lib_name
            qsf_path = self.get_lib_build_dirs('synth', lib_dicts=syn_dict)
            cm.mkdir(qsf_path)

            # One qsf per lib_name
            qsf_name = lib_name + '.qsf'
            qsfPathName = cm.expand_file_path_name(qsf_name, qsf_path)
            with open(qsfPathName, 'w') as fp:
                fp.write('# synth_top_level_entity\n')
                fp.write('set_global_assignment -name TOP_LEVEL_ENTITY %s\n' % top_level_entity)

                fp.write('\n')
                fp.write('# quartus_qsf_files\n')
                quartus_qsf_files = syn_dict['quartus_qsf_files'].split()
                for fn in quartus_qsf_files:
                    filePathName = cm.expand_file_path_name(fn, lib_path)
                    fp.write('set_global_assignment -name SOURCE_TCL_SCRIPT_FILE %s\n' % filePathName)

                fp.write('\n')
                fp.write('# All used HDL library *_lib.qip files in order with top level last\n')
                use_lib_order = self.derive_lib_order('synth', lib_name)
                #use_lib_dicts = self.libs.get_dicts('hdl_lib_name', values=use_lib_order)    # uses original libs.dicts order, but
                use_lib_dicts = self.get_lib_dicts_from_lib_names(lib_names=use_lib_order)    # must preserve use_lib_order order to ensure that top level design qip with sdc file is include last in qsf
                for lib_dict in cm.listify(use_lib_dicts):
                    qip_path = self.get_lib_build_dirs('synth', lib_dicts=lib_dict)
                    qip_name = lib_dict['hdl_lib_name'] + '_lib.qip'
                    qipPathName = cm.expand_file_path_name(qip_name, qip_path)
                    fp.write('set_global_assignment -name QIP_FILE %s\n' % qipPathName)
                            

if __name__ == '__main__':
    # Parse command line arguments
    hdl_args = hdl_config.HdlParseArgs(toolsetSelect=['unb2a'])
    if hdl_args.verbosity>=1:
        print ''
        hdl_args.argparser.print_help()
          
    # Read the dictionary info from all HDL tool and library configuration files in the current directory and the sub directories
    qsyn = QuartusConfig(toolRootDir=os.path.expandvars('$RADIOHDL/tools'), libFileName='hdllib.cfg', toolFileName=hdl_args.toolFileName)
        
    if hdl_args.verbosity>=2:
        print '#'
        print '# QuartusConfig:'
        print '#'
        print ''
        print 'HDL library paths that are found in $%s:' % qsyn.libRootDir
        for p in qsyn.libs.filePaths:
            print '    ', p

    if hdl_args.verbosity>=1:        
        print ''
        print 'HDL libraries with a top level entity for synthesis that are found in $%s:' % qsyn.libRootDir
        print '    %-40s' % 'HDL library', ': Top level entity'
        syn_dicts = qsyn.libs.get_dicts(key='synth_top_level_entity')
        for d in cm.listify(syn_dicts):
            if d['synth_top_level_entity']=='':
                print '    %-40s' % d['hdl_lib_name'], ':', d['hdl_lib_name']
            else:
                print '    %-40s' % d['hdl_lib_name'], ':', d['synth_top_level_entity']
    
    if(len(hdl_args.lib_names) == 0):
        lib_names = None
    else:
        lib_names = hdl_args.lib_names

    print ''
    print 'Create Quartus IP library qip files for all HDL libraries in $%s.' % qsyn.libRootDir
    qsyn.create_quartus_ip_lib_file(lib_names=lib_names)
    
    print ''
    print 'Copy Quartus directories and files from HDL library source tree to build_dir for all HDL libraries that are found in $%s.' % qsyn.libRootDir
    qsyn.copy_files('synth')
    
    print ''
    print 'Create Quartus project files (QPF) for technology %s and all HDL libraries with a top level entity for synthesis that are found in $%s.' % (qsyn.technologyNames, qsyn.libRootDir)
    qsyn.create_quartus_project_file(lib_names=lib_names)
    
    print ''
    print 'Create Quartus settings files (QSF) for technology %s and all HDL libraries with a top level entity for synthesis that are found in $%s.' % (qsyn.technologyNames, qsyn.libRootDir)
    qsyn.create_quartus_settings_file(lib_names=lib_names)
