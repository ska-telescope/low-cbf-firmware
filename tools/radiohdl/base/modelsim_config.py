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

"""HDL configuration for building Modelsim simulation targets.

   Usage:
   > python $RADIOHDL/tools/oneclick/base/modelsim_config.py -t default
"""

import common as cm
import hdl_config
import sys
import os.path
import argparse
import platform
import subprocess

class ModelsimConfig(hdl_config.HdlConfig):

    def __init__(self, toolRootDir, libFileName='hdllib.cfg', toolFileName='hdltool_<toolset>.cfg', verbosity=0):
        """Get Modelsim tool info from toolRootDir and all HDL library info from libRootDir.

           This class uses the default keys and the keys from the libFileSections in the libFileName config file.

           Arguments:
           - toolRootDir     : Root directory from where the hdltool_<toolset>.cfg file is searched for.
           - libFileName     : Default HDL library configuration file name
           - toolFileName    : Default HDL tools configuration file name

           The libRootDir is defined in the hdltool_<toolset>.cfg file and is the root directory from where the hdllib.cfg
           files are searched for.

           The technologyNames parameter is defined in the hdltool_<toolset>.cfg file. All generic HDL libraries and these
           technology specific libraries are kept. The technologyNames refer one or more
           hdl_libraries_<technologyName>.txt files.

           Files:
           - hdltool_<toolset>.cfg : HDL tool configuration dictionary file. One central file per toolset.

           - hdllib.cfg : HDL library configuration dictionary file. One file for each HDL library.

           - hdl_libraries_<technologyName>.txt : Dictionary file with the technology libraries for the FPGA device that
             come with the synthesis tool. The keys are the library names and the values are the paths. The file needs to be
             created manually and can be read by read_hdl_libraries_technology_file().

           - modelsim_project_files.txt
             The modelsim_project_files.txt file is a dictionary file with the list the Modelsim project files for all HDL
             libraries that were found in the libRootDir. The keys are the library names and the values are the paths to the
             corresponding modelsim project files. The modelsim_project_files.txt file is created by
             create_modelsim_project_files_file() and is read by the TCL commands.do file in Modelsim. Creating the file in
             Python and then reading this in TCL makes the commands.do much simpler.

           - <lib_name>.mpf : Modelsim project file for a certain HDL library based on the hdllib.cfg. The file is created by
             create_modelsim_project_file().

           - <lib_name>_lib_order.txt
             The <lib_name>_lib_order.txt file contains the library compile order for a certain HDL library. The files are
             created by create_lib_order_files() in the same build directory as where the Modelsim project file is stored.
             The <lib_name>_lib_order.txt files are read by the TCL commands.do file in Modelsim. Creating the files in Python
             and then reading them in TCL makes the commands.do much simpler.
        """

        libFileSections=['modelsim_project_file']
        hdl_config.HdlConfig.__init__(self, toolRootDir, libFileName, libFileSections, toolFileName)

        # Read the dictionary info from all HDL tool and library configuration files in the current directory and the sub directories
        if verbosity>=2:
            print('#')
            print('# ModelsimConfig:')
            print('#')
            print('')
            print('HDL library paths that are found in ${}:'.format(self.libRootDir))
            for p in self.libs.filePaths:
                print('    ', p)

        if verbosity>=2:
            print('')
            print('get_lib_build_dirs for simulation:')
            for sim_dir in self.get_lib_build_dirs('sim'):
                print('    ', sim_dir)

        print('')
        print('Create library compile order files for simulation.')
        self.create_lib_order_files('sim')

        print('')
        print('Create library compile ip files.')
        self.create_modelsim_lib_compile_ip_files()

        print('')
        print('Create modelsim projects list file.')
        self.create_modelsim_project_files_file()

        print('')
        print('Copy Modelsim directories and files from HDL library source tree to build_dir for all HDL libraries that are found in ${}.'.format(self.libRootDir))
        self.copy_files('sim')

        print('')
        print('Create modelsim project files for technology {0} and all HDL libraries in ${1}.'.format(self.technologyNames, self.libRootDir))
        self.create_modelsim_project_file()

    def read_compile_order_from_mpf(self, mpfPathName):
        """Utility to read the compile order of the project files from an existing <mpfPathName>.mpf."""
        # read <mpfPathName>.mpf to find all project files
        project_file_indices = []
        project_file_names = []
        with open(mpfPathName, 'r') as fp:
            for line in fp:
                words = line.split()
                if len(words)>0:
                    key = words[0]
                    if key.find('Project_File_')>=0 and key.find('Project_File_P_')==-1:
                        project_file_indices.append(key[len('Project_File_'):])
                        project_file_names.append(words[2])
        # read <mpfPathName>.mpf again to find compile order for the project files
        compile_order = range(len(project_file_names))
        with open(mpfPathName, 'r') as fp:
            for line in fp:
                words = line.split()
                if len(words)>0:
                    key = words[0]
                    if key.find('Project_File_P_')>=0:
                        project_file_index = project_file_indices.index(key[len('Project_File_P_'):])
                        project_file_name = project_file_names[project_file_index]
                        k = words.index('compile_order')
                        k = int(words[k+1])
                        compile_order[k]=project_file_name
        return compile_order

    def create_modelsim_lib_compile_ip_files(self, lib_names=None):
        """Create the '<lib_name>_lib_compile_ip.txt' file for all HDL libraries in the specified list of lib_names.

           The file is stored in the sim build directory of the HDL library.
           The file is read by commands.do in Modelsim to know which IP needs to be compiled before the library is compiled.
        """
        if lib_names==None: lib_names=self.lib_names
        lib_dicts = self.libs.get_dicts('hdl_lib_name', lib_names)

        build_maindir, build_toolset_dir, build_tooldir = self.get_tool_build_dir('sim')
        genIPScript = os.path.join(build_maindir, build_toolset_dir, build_tooldir, 'generate_ip.tcl')
        with open(genIPScript, 'w') as ipFile:
            ipFile.write('set_part %s\n' % self.tool_dict['device'])

            for lib_dict in cm.listify(lib_dicts):
                if 'modelsim_compile_ip_files' in lib_dict:
                    compile_ip_files = lib_dict['modelsim_compile_ip_files'].split()
                    lib_name = lib_dict['hdl_lib_name']
                    file_name = lib_name + '_lib_compile_ip.txt'
                    file_path = self.get_lib_build_dirs('sim', lib_dicts=lib_dict)
                    cm.mkdir(file_path)
                    filePathName = os.path.join(file_path, file_name)

                    # Append to the ip generation scripts (TCL always uses UNIX slashes)
                    ipFile.write('cd %s\n' % file_path.replace("\\", "/"))

                    with open(filePathName, 'w') as fp:
                        for fpn in compile_ip_files:
                            # Write the expanded file path name for <lib_name>_lib_compile_ip.txt so that it can be executed directly from its location in SVN using the Modelsim "do"-command in the commands.do.
                            # An alternative would be to write the basename, so only <lib_name>_lib_compile_ip.txt, but that would require copying the basename file to the mpf build directory
                            efpn = os.path.expandvars(fpn)
                            fp.write('%s ' % os.path.splitext(os.path.split(fpn)[1])[0])
                            ipFile.write('source %s\n' % os.path.join(lib_dict['lib_path'],fpn).replace("\\", "/"))

            ipFile.write('exit\n')





    def simulation_configuration(self, list_mode=False):
        """Prepare settings for simulation configuration.
           The output format is string or list, dependent on list_mode.
           Return tuple of project_sim_p_defaults, project_sim_p_search_libraries, project_sim_p_otherargs, project_sim_p_optimization.
        """
        # project_sim_p_defaults
        project_sim_p_defaults = 'Generics {} timing default -std_output {} -nopsl 0 +notimingchecks 1 selected_du {} -hazards 0 -sdf {} ok 1 -0in 0 -nosva 0 +pulse_r {} -absentisempty 0 -multisource_delay {} +pulse_e {} vopt_env 1 -coverage 0 -sdfnoerror 0 +plusarg {} -vital2.2b 0 -t default -memprof 0 is_vopt_flow 1 -noglitch 0 -nofileshare 0 -wlf {} -assertdebug 0 +no_pulse_msg 0 -0in_options {} -assertfile {} -sdfnowarn 0 -Lf {} -std_input {}'

        # project_sim_p_search_libraries
        if list_mode:
            project_sim_p_search_libraries = self.tool_dict['modelsim_search_libraries'].split()
        else:
            project_sim_p_search_libraries = '-L {}'
            if 'modelsim_search_libraries' in self.tool_dict:
                project_sim_p_search_libraries = '-L {'
                for sl in self.tool_dict['modelsim_search_libraries'].split():
                    project_sim_p_search_libraries += sl
                    project_sim_p_search_libraries += ' '
                project_sim_p_search_libraries += '}'

        # project_sim_p_otherargs
        otherargs = ''
        otherargs = '+nowarn8684 +nowarn8683 -quiet'
        otherargs = '+nowarn8684 +nowarn8683'
        otherargs = '+nowarn8684 +nowarn8683 +nowarnTFMPC +nowarnPCDPC'  # nowarn on verilog IP connection mismatch warnings
        if list_mode:
            project_sim_p_otherargs = otherargs.split()
        else:
            project_sim_p_otherargs = 'OtherArgs {' + otherargs + '}'

        # project_sim_p_optimization
        project_sim_p_optimization = 'is_vopt_opt_used 2'  # = when 'Enable optimization' is not selected in GUI
        project_sim_p_optimization = 'is_vopt_opt_used 1 voptargs {OtherVoptArgs {} timing default VoptOutFile {} -vopt_keep_delta 0 -0in 0 -fvopt {} VoptOptimize:method 1 -vopt_00 2 +vopt_notimingcheck 1 -Lfvopt {} VoptOptimize:list .vopt_opt.nb.canvas.notebook.cs.page1.cs.g.spec.listbox -Lvopt {} +vopt_acc {} VoptOptimize .vopt_opt.nb.canvas.notebook.cs.page1.cs -vopt_hazards 0 VoptOptimize:Buttons .vopt_opt.nb.canvas.notebook.cs.page1.cs.g.spec.bf 0InOptionsWgt .vopt_opt.nb.canvas.notebook.cs.page3.cs.zf.ze -0in_options {}}' # = when 'Enable optimization' is selected in GUI for full visibility

        return project_sim_p_defaults, project_sim_p_search_libraries, project_sim_p_otherargs, project_sim_p_optimization


    def create_modelsim_project_file(self, lib_names=None):
        """Create the Modelsim project file for all technology libraries and RTL HDL libraries.

           Arguments:
           - lib_names       : one or more HDL libraries

           Library mapping:
           - Technology libraries that are available, but not used are mapped to work.
           - Unavailable libraries are also mapped to work. The default library clause name is <lib_name> with postfix '_lib'. This is a best
             effort guess, because it is impossible to know the library clause name for an unavailable library. If the best effort guess is
             not suitable, then the workaround is to create a place holder directory with hdllib.cfg that defines the actual library clause
             name as it appears in the VHDL for the unavailable HDL library. unavailable library names occur when e.g. a technology IP library
             is not available in the toolRootDir because it is not needed, or it may indicate a spelling error.
        """
        if lib_names==None: lib_names=self.lib_names
        lib_dicts = self.libs.get_dicts('hdl_lib_name', lib_names)
        for lib_dict in cm.listify(lib_dicts):
            # Open mpf
            lib_name = lib_dict['hdl_lib_name']
            mpf_name = lib_name + '.mpf'
            mpf_path = self.get_lib_build_dirs('sim', lib_dicts=lib_dict)
            cm.mkdir(mpf_path)
            mpfPathName = os.path.normpath(os.path.join(mpf_path, mpf_name))
            with open(mpfPathName, 'w') as fp:
                # Write [Library] section for all used libraries
                fp.write('[Library]\n')

                # . map used vendor technology libs to their target directory
                for technologyName in self.technologyNames:
                    tech_dict = self.read_hdl_libraries_technology_file(technologyName, 'tool_name_sim')

                    for lib_clause, lib_work in tech_dict.items():
                        if type(lib_work) is str:
                            lib_work = cm.expand_file_path_name(lib_work)

                        fp.write('%s = %s\n' % (lib_clause, lib_work))
                # . not used vendor technology libs are not compiled but are mapped to work to avoid compile error when mentioned in the LIBRARY clause
#                for tech_dict in self.removed_dicts:
#                    fp.write('%s = work\n' % tech_dict['hdl_library_clause_name'])
                # . unavailable used libs are not compiled but are mapped to work to avoid compile error when mentioned in the LIBRARY clause
                for unavailable_use_name in self.unavailable_use_libs:
                    # if the unavailable library is not in the dictionary of disclosed unavailable library clause names, then assume that the library clause
                    # name has the default postfix '_lib'.
                    if unavailable_use_name in self.disclosed_library_clause_names:
                        fp.write('%s = work\n' % self.disclosed_library_clause_names[unavailable_use_name])
                    else:
                        fp.write('%s_lib = work\n' % unavailable_use_name)
                # . all used libs for this lib_name
                use_lib_names = self.derive_all_use_libs('sim', lib_name)
                use_lib_dicts = self.libs.get_dicts('hdl_lib_name', use_lib_names)
                use_lib_build_sim_dirs = self.get_lib_build_dirs('sim', lib_dicts=use_lib_dicts)
                use_lib_clause_names = self.libs.get_key_values('hdl_library_clause_name', use_lib_dicts)
                for lib_clause, lib_dir in zip(cm.listify(use_lib_clause_names), cm.listify(use_lib_build_sim_dirs)):
                    lib_work = os.path.normpath(os.path.join(lib_dir, 'work'))
                    fp.write('%s = %s\n' % (lib_clause, lib_work))
                # . work
                fp.write('work = work\n')
                # . others modelsim default libs
                model_tech_dir = os.path.expandvars(self.tool_dict['model_tech_dir'])
                fp.write('others = %s\n' % os.path.normpath(os.path.join(model_tech_dir, 'modelsim.ini')))

                # Write [Project] section for all used libraries
                fp.write('[Project]\n')
                fp.write('Project_Version = 6\n')  # must be >= 6 to fit all
                fp.write('Project_DefaultLib = work\n')
                fp.write('Project_SortMethod = unused\n')

                # - project files
                try:
                    synth_files = lib_dict['synth_files'].split()
                except KeyError:
                    synth_files = []

                try:
                    test_bench_files = lib_dict['test_bench_files'].split()
                except KeyError:
                    test_bench_files = []

                project_files = synth_files + test_bench_files
                if 'modelsim_compile_ip_files' in lib_dict:
                    compile_ip_files = lib_dict['modelsim_compile_ip_files'].split()
                    project_files += compile_ip_files
                fp.write('Project_Files_Count = %d\n' % len(project_files))
                lib_path = self.libs.get_filePath(lib_dict)


                project_file_p_defaults_hdl     = 'vhdl_novitalcheck 0 group_id 0 cover_nofec 0 vhdl_nodebug 0 vhdl_1164 1 vhdl_noload 0 vhdl_synth 0 vhdl_enable0In 0 vlog_1995compat 0 last_compile 0 vhdl_disableopt 0 cover_excludedefault 0 vhdl_vital 0 vhdl_warn1 1 vhdl_warn2 1 vhdl_explicit 1 vhdl_showsource 0 cover_covercells 0 vhdl_0InOptions {} vhdl_warn3 1 vlog_vopt {} cover_optlevel 3 voptflow 1 vhdl_options {} vhdl_warn4 1 toggle - ood 0 vhdl_warn5 1 cover_noshort 0 compile_to work cover_nosub 0 dont_compile 0 vhdl_use93 2008 cover_stmt 1'
                project_file_p_defaults_vhdl    = 'file_type vhdl'
                project_file_p_defaults_verilog = 'file_type verilog'
                project_file_p_defaults_systemverilog = 'file_type systemverilog'
                project_file_p_defaults_tcl     = 'last_compile 0 compile_order -1 file_type tcl group_id 0 dont_compile 1 ood 1'

                project_folders = []
                offset = 0

                nof_synth_files = len(synth_files)

#                for i, fn in enumerate(project_files):
#                    filePathName = cm.expand_file_path_name(fn, lib_path)
#                    fp.write('Project_File_%d = %s\n' % (i, filePathName))


                if nof_synth_files>0:
                    project_folders.append('synth_files')
                    for i in range(nof_synth_files):

                        # Add file type specific settings
                        file_ext = synth_files[i].split('.')[-1]
                        if file_ext=='vhd' or file_ext=='vhdl':
                             project_file_p_defaults_file_specific = project_file_p_defaults_vhdl
                        elif file_ext=='v':
                             project_file_p_defaults_file_specific = project_file_p_defaults_verilog
                        elif file_ext=='vh':
                             project_file_p_defaults_file_specific = project_file_p_defaults_verilog
                        elif file_ext=='sv':
                             project_file_p_defaults_file_specific = project_file_p_defaults_systemverilog
                        else:
                             print("\nERROR - Undefined file extension in synth_files:", lib_name, synth_files[i])
                             sys.exit()

                        # Prepend the library path if a relative path
                        if synth_files[i].find(":") == -1:
                           filePathName = cm.expand_file_path_name(synth_files[i], lib_path)
                        else:
                           filePathName = synth_files[i]
                        fp.write('Project_File_%d = %s\n' % (i, filePathName))
                        fp.write('Project_File_P_%d = folder %s compile_order %d %s\n' % (offset+i, project_folders[-1], offset+i, project_file_p_defaults_hdl+' '+project_file_p_defaults_file_specific))

                offset = nof_synth_files

                nof_test_bench_files = len(test_bench_files)
                if nof_test_bench_files>0:
                    project_folders.append('test_bench_files')
                    for i in range(nof_test_bench_files):

                        # Add file type specific settings
                        file_ext = test_bench_files[i].split('.')[-1]
                        if file_ext=='vhd' or file_ext=='vho' or file_ext=='vhdl':
                            project_file_p_defaults_file_specific = project_file_p_defaults_vhdl
                        elif file_ext=='v':
                            project_file_p_defaults_file_specific = project_file_p_defaults_verilog
                        elif file_ext=='vh':
                            project_file_p_defaults_file_specific = project_file_p_defaults_verilog
                        elif file_ext=='sv':
                             project_file_p_defaults_file_specific = project_file_p_defaults_systemverilog
                        else:
                            print("\nERROR - Undefined file extension in test_bench_files:", lib_name, test_bench_files[i])
                            sys.exit()

                        filePathName = cm.expand_file_path_name(test_bench_files[i], lib_path)
                        fp.write('Project_File_%d = %s\n' % (offset+i, filePathName))
                        fp.write('Project_File_P_%d = folder %s compile_order %d %s\n' % (offset+i, project_folders[-1], offset+i, project_file_p_defaults_hdl+' '+project_file_p_defaults_file_specific))
                offset += nof_test_bench_files

                if 'modelsim_compile_ip_files' in lib_dict:
                    nof_compile_ip_files = len(compile_ip_files)
                    if nof_compile_ip_files>0:
                        project_folders.append('compile_ip_files')
                        for i in range(nof_compile_ip_files):
                            filePathName = cm.expand_file_path_name(compile_ip_files[i], lib_path)
                            fp.write('Project_File_%d = %s\n' % (offset+i, filePathName))
                            fp.write('Project_File_P_%d = folder %s compile_order %d %s\n' % (offset+i, project_folders[-1], offset+i, project_file_p_defaults_tcl))
                    offset += nof_compile_ip_files

                # - project folders
                fp.write('Project_Folder_Count = %d\n' % len(project_folders))
                for i, fd in enumerate(project_folders):
                    fp.write('Project_Folder_%d = %s\n' % (i, fd))
                    fp.write('Project_Folder_P_%d = folder {Top Level}\n' % i)

                # - simulation configurations
                fp.write('Project_Sim_Count = %d\n' % len(test_bench_files))
                project_sim_p_defaults, project_sim_p_search_libraries, project_sim_p_otherargs, project_sim_p_optimization = self.simulation_configuration()
                for i, fn in enumerate(test_bench_files):
                    fName = os.path.basename(fn)
                    tbName = os.path.splitext(fName)[0]
                    fp.write('Project_Sim_%d = %s\n' % (i, tbName))
                for i, fn in enumerate(test_bench_files):
                    fName = os.path.basename(fn)
                    tbName = os.path.splitext(fName)[0]

                    #if project_sim_p_search_libraries.find("xpm") != -1: tbName += " xpm.glbl"


                    fp.write('Project_Sim_P_%d = folder {Top Level} additional_dus { work.%s } %s %s %s %s\n' % (i, tbName, project_sim_p_defaults, project_sim_p_search_libraries, project_sim_p_otherargs, project_sim_p_optimization))

                # Write [vsim] section
                fp.write('[vsim]\n')
                fp.write('RunLength = 0 ps\n')
                fp.write('resolution = 1fs\n')
                fp.write('IterationLimit = 5000\n')       # According to 'verror 3601' the default is 5000, typically 100 is enough, but e.g. the ip_stratixiv_phy_xaui_0 requires more.
                fp.write('DefaultRadix = hexadecimal\n')
                fp.write('NumericStdNoWarnings = 1\n')
                fp.write('StdArithNoWarnings = 1\n')
                #fp.write('DefaultRadixFlags = enumnumeric\n')

    def create_modelsim_project_files_file(self, lib_names=None):
        """Create file with list of the Modelsim project files for all HDL libraries.

           Arguments:
           - lib_names  : one or more HDL libraries
        """
        fileName = 'modelsim_project_files.txt'                                              # use fixed file name
        build_maindir, build_toolsetdir, build_tooldir = self.get_tool_build_dir('sim')
        fileNamePath=os.path.join(build_maindir, build_toolsetdir, build_tooldir, fileName)  # and use too build dir for file path
        if lib_names==None: lib_names=self.lib_names
        with open(fileNamePath, 'w') as fp:
            lib_dicts = self.libs.get_dicts('hdl_lib_name', lib_names)
            mpf_paths = self.get_lib_build_dirs('sim', lib_dicts=lib_dicts)
            for lib_name, mpf_path in zip(cm.listify(lib_names),cm.listify(mpf_paths)):
                fp.write('%s = %s\n' % (lib_name, mpf_path))


if __name__ == '__main__':
    # Parse command line arguments
    hdl_args = hdl_config.HdlParseArgs(toolsetSelect=cm.find_all_toolsets(os.path.expandvars('$RADIOHDL/tools')))
    if hdl_args.verbosity>=1:
        print("")
        hdl_args.argparser.print_help()

    # Read the dictionary info from all HDL tool and library configuration files in the current directory and the sub directories
    msim = ModelsimConfig(toolRootDir=os.path.normpath(os.path.expandvars('$RADIOHDL/tools')), libFileName='hdllib.cfg', toolFileName=hdl_args.toolFileName, verbosity=hdl_args.verbosity)

    if hdl_args.ip:
        # Generate IP libraries
        build_maindir, build_toolsetdir, build_tooldir = msim.get_tool_build_dir('sim')
        if platform.system().lower() == "windows":
            subprocess.call(["run_vcomp.cmd",hdl_args.toolset, msim.tool_dict['tool_name_synth'],  msim.tool_dict['tool_version_synth'],os.path.join(build_maindir, build_toolsetdir, build_tooldir, 'generate_ip.tcl')], shell=True)
        else:
            subprocess.call(["run_vcomp",hdl_args.toolset, msim.tool_dict['tool_name_synth'],  msim.tool_dict['tool_version_synth'],os.path.join(build_maindir, build_toolsetdir, build_tooldir, 'generate_ip.tcl')])
