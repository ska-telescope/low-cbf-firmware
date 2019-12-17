
import common as cm
import os
import os.path
import sys
import hdl_config
import common_dict_file
import argparse
import subprocess
import platform
import logging
import re
import yaml
from py_args_lib import *

logger = logging.getLogger('main.vivado_config')


class VivadoConfig(hdl_config.HdlConfig): #(tcl_config.TclConfig):#

    def __init__(self, toolRootDir, libFileName='hdllib.cfg', toolFileName='hdltool_<toolset>.cfg', libtop=None):
        """Get Vivado tool info from toolRootDir and all HDL library info from libRootDir.

           Arguments:
           - toolRootDir     : Root directory from where the hdltool_<toolset>.cfg file is searched for.
           - libFileName     : Default HDL library configuration file name ($RADIOHDL)
           - toolFileName    : Default HDL tools configuration file name

           The libRootDir is defined in the hdltool_<toolset>.cfg file and is the root directory from where the hdllib.cfg
           files are searched for.

           The technologyNames parameter is defined in the hdltool_<toolset>.cfg file. All generic HDL libraries and these
           technology specific libraries are kept.

           Files:
           - hdltool_<toolset>.cfg : HDL tool configuration dictionary file. One central file per toolset.

           - hdllib.cfg : HDL library configuration dictionary file. One file for each HDL library.

           - <lib_name>.xpr : Vivado project file (XPR) for a certain HDL library based on the hdllib.cfg. The file is created by
                              create_quartus_project_file().

           - <lib_name>. : Vivado settings file for a certain HDL library based on the hdllib.cfg. The file is created by
                              create_quartus_settings_file().
        """
        libFileSections=['vivado_project_file']
        hdl_config.HdlConfig.__init__(self, toolRootDir, libFileName, libFileSections, toolFileName, libtop)

    def run_tcl_build_script(self, toolset, tool, version, lib_names=None):
        try:
            os.chdir(self.build_dir)
        except AttributeError:
            sys.exit('Error: Project scripts not yet created, check if project hdllib.cfg has synth_top_level_entity key')
        #subprocess.call(["vivado","-mode","tcl","-source",self.build_script_name])

        if platform.system().lower() == "windows":
            subprocess.call(["run_vcomp.cmd",toolset,tool, version,"{}_build_script.tcl".format(self.build_project)])
        else:
            subprocess.call(["run_vcomp",toolset,tool, version, "{}_build_script.tcl".format(self.build_project)])

    def create_vivado_ip_lib_file(self, lib_name): #lib_names=None):
        """Create <lib_name>_load_files.tcl based on
        if lib_names==None: lib_names=self.lib_names and add to build script """
        lib_names = self.lib_names
        lib_dicts = self.libs.get_dicts('hdl_lib_name', values=lib_names)
        toplevel_lib_name = lib_name
        self.create_project_build_script(lib_name)
        use_lib_names = self.derive_lib_order('synth', lib_name)
        print("USE LIBS",use_lib_names)
        lib_dicts = self.libs.get_dicts('hdl_lib_name', values=use_lib_names) # libraries used for top level design
        synth_top_level_entity=toplevel_lib_name
        for lib_dict in cm.listify(lib_dicts):
            # Open qip
            lib_name = lib_dict['hdl_lib_name']
            print('get_filepath', lib_name)
            lib_path = self.libs.get_filePath(lib_dict)
            loader_script_name = lib_name + '_load_files.tcl'
            loader_script_path = self.get_lib_build_dirs('synth', lib_dicts=lib_dict)
            cm.mkdir(loader_script_path)
            loaderScriptPathName = cm.expand_file_path_name_posix(loader_script_name, loader_script_path)
            logger.info("loaderscriptPathName = {}".format(loaderScriptPathName))
            for key, value in lib_dict.items():
                if value:
                    logger.debug("\t%s :\t%s",key, value)
            with open(loaderScriptPathName, 'w') as fp:

                if 'synth_files' in lib_dict:
                    fp.write('# synth_files\n')
                    synth_files = lib_dict['synth_files'].split()
                    if any(synth_files):
                        fp.write('add_files -fileset sources_1 [glob \\\n')
                        [fp.write('%s \\\n' % cm.expand_file_path_name_posix(fn, lib_path)) for fn in synth_files]
                        fp.write(']\n')
                        fp.write('set_property library %s [get_files {\\\n' % (lib_name + '_lib'))
                        [fp.write('%s \\\n' % cm.expand_file_path_name_posix(fn, lib_path)) for fn in synth_files]
                        fp.write('}]\n')


                if 'test_bench_files' in lib_dict:
                    fp.write('# test_bench_files\n')
                    test_bench_files = lib_dict['test_bench_files'].split()
                    if any(test_bench_files):
                        fp.write('add_files -fileset sim_1 [glob \\\n')
                        [fp.write('%s \\\n' % cm.expand_file_path_name_posix(fn, lib_path)) for fn in test_bench_files]
                        fp.write(']\n')
                        fp.write('set_property library %s [get_files {\\\n' % (lib_name + '_lib'))
                        [fp.write('%s \\\n' % cm.expand_file_path_name_posix(fn, lib_path)) for fn in test_bench_files]
                        fp.write('}]\n')

                    fp.write('set_property -name {xsim.compile.xvlog.more_options} -value {-d SIM_SPEED_UP} -objects [get_filesets sim_1]\n')
                    fp.write('set_property top_lib xil_defaultlib [get_filesets sim_1]\n')

                if 'vivado_ip_repo' in lib_dict:
                    fp.write('# vivado_ip_repo\n')
                    iprepo_files = lib_dict['vivado_ip_repo'].split()
                    for fn in iprepo_files:
                        filePathName = cm.expand_file_path_name_posix(fn, lib_path)
                        fp.write('set repo_dir $proj_dir/ip_repo\n') # Tcl variable $proj_dir is still available since create_project
                        fp.write('file mkdir $repo_dir\n')
                        fp.write('set_property "ip_repo_paths" $repo_dir [get_filesets sources_1]\n')
                        fp.write('update_ip_catalog -rebuild\n')
                        fp.write('update_ip_catalog -add_ip %s -repo_path $repo_dir\n' % (filePathName))
                    fp.write('update_ip_catalog -rebuild\n')
                if 'vivado_bd_files' in lib_dict:
                    fp.write('# vivado_bd_files\n')
                    bd_files = lib_dict['vivado_bd_files'].split()
                    for fn in bd_files:
                        filePathName = cm.expand_file_path_name_posix(fn, lib_path)
                        fp.write('import_files -force -fileset sources_1 [glob %s]\n' % filePathName) # paramterize constraints set
                        #fp.write('add_files -fileset sources_1 [ glob %s ]\n' % filePathName )
                if 'vivado_elf_files' in lib_dict:
                    fp.write('# vivado_elf_files\n')
                    elf_files = lib_dict['vivado_elf_files'].split()
                    for fn in elf_files:
                        filePathName = cm.expand_file_path_name_posix(fn, lib_path)
                        fp.write('import_files -force -fileset sources_1 [glob %s]\n' % filePathName) # paramterize constraints set
                        #fp.write('add_files -fileset sources_1 [ glob %s ]\n' % filePathName )
                if 'vivado_xdc_files' in lib_dict:
                    fp.write('# vivado_xdc_files\n')
                    xdc_files = lib_dict['vivado_xdc_files'].split()
                    for fn in xdc_files:
                        # filePathName = filePathName.replace('/cygdrive/C','c:')
                        filePathName = cm.expand_file_path_name_posix(fn, lib_path)
                        #fp.write('import_files -force -fileset [get_filesets constrs_1] %s\n' % filePathName) # paramterize constraints set
                        fp.write('add_files -fileset constrs_1 [ glob %s ]\n' % filePathName) # paramterize constraints set

                        # For the top level xdc files set processing order of xdc to LATE
                        if lib_name == toplevel_lib_name:
                            fp.write('set_property PROCESSING_ORDER LATE [get_files %s]\n' % filePathName)

                if 'vivado_xci_files' in lib_dict:
                    fp.write('# vivado_xci_files: Importing IP to the project\n')
                    xci_files = lib_dict['vivado_xci_files'].split()
                    for fn in xci_files:
                        filePathName = cm.expand_file_path_name_posix(fn, lib_path)
                        ipName = re.split('[./]',fn)[-2]
                        print("ipName = {}".format(ipName))
                        fp.write('import_ip -files %s -name %s\n' % (filePathName, ipName)) # paramterize constraints set
                        fp.write('create_ip_run -force [get_ips %s]\n' % (ipName))
                        #create_ip_run -force [get_files my_core_1.xci]

                if 'vivado_top_level_entity' in lib_dict:
                    synth_top_level_entity = lib_dict['vivado_top_level_entity'].split()[0]
                    print ("set toplevel entity to ", synth_top_level_entity);

                if 'vivado_tcl_files' in lib_dict: # can make this more flexible by searching recursively by extension
                    fp.write('# tcl scripts for ip generation\n')
                    tcl_files = lib_dict['vivado_tcl_files'].split()
                    for fn in tcl_files:
                        if '_board.tcl' not in fn:
                            filePathName = cm.expand_file_path_name_posix(fn, lib_path)
                            fp.write('source %s\n' % filePathName)
                            logger.debug('lib %s source %s\n', lib_name, filePathName)



            f = open(self.buildScriptPathName, 'a+')
            # if lib appears in
            print("source [pwd]/{}/{}\n".format(lib_name, loader_script_name))
            f.write('source [pwd]/%s/%s\n' % (lib_name, loader_script_name))
        f.write('set_property top %s [current_fileset]\n' %synth_top_level_entity)
        f.write('set_property top %s [get_filesets sim_1]\n' % ('tb_' + toplevel_lib_name))
        # self.implement_project(f);
        f.close()


    def create_project_build_script(self, design):
        """
            Create tcl build script per top level design of toolset
        """
        pathSet = self.get_tool_build_dir('synth') # parameterize synth
        #print("pathSet = ",pathSet)
        self.build_dir = os.path.join(pathSet[0],pathSet[1],pathSet[2])
        print("buildDir = {}".format(self.build_dir))
        cm.mkdir(self.build_dir)
        self.build_script_name = design + '_build_script.tcl'
        self.build_project = design
        self.buildScriptPathName = cm.expand_file_path_name_posix(self.build_script_name, self.build_dir)
        with open(self.buildScriptPathName,'w') as f:
            f.write('set time_raw [clock seconds];\n')
            f.write('set date_string [clock format $time_raw -format "%y%m%d_%H%M%S"]\n')
            f.write('set proj_dir "%s/%s_build_$date_string"\n' %(design, design))
            f.write('# Create the new build directory\n')
            f.write('puts "Creating build_directory $proj_dir"\n')
            f.write('file mkdir $proj_dir\n')
            f.write('set workingDir [pwd]\n')
            f.write('puts "Working directory:"\n')
            f.write('puts $workingDir\n')
            # put at end of script f.write('exit\n')
            xpr_name = design + '_project.tcl'
            f.write('source [pwd]/%s/%s\n' % (design, xpr_name))
            f.close()
    def implement_project(self): # not used
        f = open(self.buildScriptPathName,'a+')
        f.write('puts "."\n')
        f.write('puts "."\n')
        f.write('puts "."\n')
        f.write('puts "All Vivado projectfiles are prepared in the build directory."\n')
        f.write('puts "Ready to Synthesize the design now.."\n')
        f.write('puts "Continueing after 2 seconds..."\n')
        f.write('exec sleep 2\n')
        f.write('puts "."\n')
        f.write('puts "."\n')
        f.write('puts "."\n')

        #with open(self.buildScriptPathName, 'a+') as f:
        f.write('set_param general.maxThreads 6\n')
        f.write('puts "Synthesizing the design now"\n')
        f.write('launch_runs synth_1\n') # PARAMETERIZE
        f.write('puts "wait until synthesis done"\n')
        f.write('wait_on_run synth_1\n') # PARAMETERIZE
        #f.write('set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED false [get_runs impl_1]\n')
        f.write('puts "Implementing the design"\n')
        f.write('launch_runs impl_1 -to_step write_bitstream\n') # PARAMATERIZE
        f.write('puts "Wait until Implementation done"\n')
        f.write('wait_on_run impl_1\n')
        f.write('exit\n')
        f.close()

    def create_vivado_project_file(self, lib_names=None, design=None):
        """Create the Vivado project file (XPR) for all HDL libraries that have a
        top level entity key synth_top_level_entity.
        The project revision has the same name as the lib_name and will result in a
        <lib_name>.bit FPGA image file.

        Arguments:
        - lib_names : one or more HDL libraries.
        """

        if lib_names==None: lib_names=self.lib_names
        lib_dicts = self.libs.get_dicts(key='hdl_lib_name', values=lib_names)
        if design==None:
            syn_dicts = self.libs.get_dicts(key='synth_top_level_entity', values=None, dicts=lib_dicts)
        else:
            syn_dicts = self.libs.get_dicts(key='synth_top_level_entity', values = [design], dicts=lib_dicts)

        for syn_dict in cm.listify(syn_dicts):
            # Open xpr for each HDL library that has a synth_top_level_entity
            lib_name = syn_dict['hdl_lib_name']
            xpr_name = lib_name + '_project.tcl'
            self.create_project_build_script(lib_name)

            xpr_path = self.get_lib_build_dirs('synth', lib_dicts=syn_dict)
            print("xpr_path = {}".format(xpr_path))
            cm.mkdir(xpr_path)
            xprPathName = cm.expand_file_path_name_posix(xpr_name, xpr_path)
            print(xprPathName)
            with open(xprPathName, 'w') as fp:
                # call board configuration tcl files
                fp.write('\n# vivado_tcl_files (toplevel)\n')
                fp.write('set DEVICE \"{}\"\n'.format(self.tool_dict['device']))
                fp.write('set BOARD \"{}\"\n'.format(self.tool_dict['board']))
                board_dicts = cm.listify(self.libs.get_dicts('hdl_lib_name', values=syn_dict['hdl_lib_uses_synth'].split()))
                board_dicts.append(syn_dict)
                for board_dict in board_dicts:
                    if 'vivado_tcl_files' in board_dict:
                        vivado_tcl_files = board_dict['vivado_tcl_files'].split()
                        for fn in vivado_tcl_files:
                            if '_board.tcl' in fn:
                                filePathName = cm.expand_file_path_name_posix(fn, self.libs.get_filePath(board_dict))
                                # filePathName = filePathName.replace('/cygdrive/C','c:')
                                fp.write('source %s\n' % filePathName)

                # fp.write('PROJECT_REVISION = "%s"\n' % lib_name)
                fp.write('# This script sets the project variables\n')
                fp.write('puts "Creating new project: %s"\n' % lib_name)
                fp.write('cd $proj_dir\n')


                fp.write('create_project %s -part $DEVICE -force\n' % lib_name)
                fp.write('set_property board_part $BOARD [current_project]\n')
                fp.write('set_property target_language VHDL [current_project]\n')
                #fp.write('set_property target_simulator ModelSim [current_project]\n')
                fp.write('set_property target_simulator XSim [current_project]\n')
                #fp.write('set_property "ip_repo_paths" /home/software/Xilinx/extra_ip_repo/xhmc_v1_0 [get_filesets sources_1]\n')
                #fp.write('update_ip_catalog -rebuild\n')
                fp.write('cd ../..\n')
                fp.close()
            self.create_vivado_ip_lib_file(lib_name)

    def get_file_type(self, fileName):
        file_ext = fileName.split('.')[-1]
        if file_ext=='vhd' or file_ext=='vhdl':
            file_type = 'VHDL_FILE'
        elif file_ext == 'v' or file_ext == 'vh':
            file_type = 'VERILOG_FILE'
        elif file_ext == 'sv':
            file_type = 'SYSTEMVERILOG_FILE'
        else:
            print('\nERROR - Undefined file extension in synth_files:', fileName)
            sys.exit()
        return file_type

if __name__ == '__main__':
    
    # Parse command line arguments
    hdl_args = hdl_config.HdlParseArgs(toolsetSelect=cm.find_all_toolsets(os.path.expandvars('$RADIOHDL/tools')))
    if hdl_args.verbosity>=1:
        print('')
        hdl_args.argparser.print_help()

    # setup first log system before importing other user libraries
    PROGRAM_NAME = __file__.split('/')[-1].split('.')[0]
    unit_logger.set_logfile_name(name=PROGRAM_NAME)
    unit_logger.set_file_log_level('DEBUG')
    if hdl_args.verbosity >= 3:
        unit_logger.set_stdout_log_level('DEBUG')
    elif hdl_args.verbosity == 2:
        unit_logger.set_stdout_log_level('INFO')

    # Create and use vsyn object
    vsyn = VivadoConfig(toolRootDir=os.path.expandvars('$RADIOHDL/tools'), libFileName='hdllib.cfg', toolFileName=hdl_args.toolFileName, libtop=hdl_args.lib_top)
    
    if hdl_args.verbosity>=2:
        print('#')
        print('# VivadoConfig:')
        print('#')
        print('')
        print("HDL library paths that are found in {}:".format(vsyn.libRootDir))
        for p in vsyn.libs.filePaths:
            print('    ', p)

    if hdl_args.verbosity>=1:
        print('')
        print("HDL libraries with a top level entity for synthesis that are found in {}:".format(vsyn.libRootDir))
        # print'    %-40s' % 'HDL library', ': Top level entity'
        print("    {:40} {}".format('HDL library', ': Top level entity'))
        syn_dicts = vsyn.libs.get_dicts(key='synth_top_level_entity')
        for d in cm.listify(syn_dicts):
            if d['synth_top_level_entity']=='':
                # print '    %-40s' % d['hdl_lib_name'], ':', d['hdl_lib_name']
                print("    {:40} : {}".format(d['hdl_lib_name'], d['hdl_lib_name']))
            else:
                # print '    %-40s' % d['hdl_lib_name'], ':', d['synth_top_level_entity']
                print("    {:40} : {}".format(d['hdl_lib_name'], d['synth_top_level_entity']))

    print('')
    print("Copy Vivado directories and files from HDL library source tree to build_dir for all HDL libraries that are found in ${}.".format(vsyn.libRootDir))

    if(len(hdl_args.lib_names) == 0):
        arg_design = None
    else:
        arg_design = hdl_args.lib_names

    if hdl_args.argsOnly:
        print('!!! -a option used, Skipping creation of vivado project file')
    else:
        vsyn.create_vivado_project_file(lib_names=arg_design)

    if hdl_args.argsOnly:
        print('!!! -a option used, Skipping implement project and run tcl build script')
    else:
        if arg_design != None and hdl_args.run:
            vsyn.implement_project() # add lines to implement project
            vsyn.run_tcl_build_script(hdl_args.toolset, vsyn.tool_dict['tool_name_synth'], vsyn.tool_dict['tool_version_synth'])
        elif arg_design != None and hdl_args.project:
             vsyn.run_tcl_build_script(hdl_args.toolset, vsyn.tool_dict['tool_name_synth'], vsyn.tool_dict['tool_version_synth']) # create project file only


