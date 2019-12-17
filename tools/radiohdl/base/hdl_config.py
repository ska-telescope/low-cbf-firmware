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

"""HDL configuration for building simulation and synthesis targets.

   There should be one hdltool_<toolset>.cfg file per toolset somewhere in the
   toolRootDir and at least one hdllib.cfg file somewhere in the libRootDir.
   Every HDL library that is in the libRootDir can be found if it has a hdllib.cfg file.
   Together the hdltool_<toolset>.cfg and hdllib.cfg files contain all the keys and
   values that are sufficient to be able to build the targets for the HDL
   library. The possible targets are:

   - compile to created the library binaries for simulation
   - synthesize to created an image that can be loaded ion the FPGA
   - verify VHDL test benches in simulation
   - verify Python test cases via the MM control interface in simulation
   - validate Python test cases on hardware via the MM control interface

   The contents of the cfg files consist of a series of key - value pairs
   that are read into a dictionary as defined in common_dict_file.py. Whether
   the key is a valid key depends on the application that interprets the
   dictionary.

   The methods can have the library dictionary or the library name as
   argument. The default arguments are the self.libs.dicts and the
   corresponding self.lib_names. The argument can be a list or a single value.
   Similar the return can be a list or a single value, because a list of one
   element is unlistified.

"""

import common as cm
import common_dict_file
import sys
import os
import subprocess
import shutil
from distutils.dir_util import copy_tree
import argparse
import collections
import yaml
import logging
sys.path.append('../../args/')
from py_args_lib import *
import gen_slave
import gen_bus
import gen_doc
import gen_fpgamap_py
import gen_c_config
import datetime


logger = logging.getLogger('main.hdl_config')

class HdlConfig:

    def __init__(self, toolRootDir, libFileName='hdllib.cfg', libFileSections=None, toolFileName='hdltool_<toolset>.cfg', libtop=None):
        """Get tool dictionary info from toolRootDir and all HDL library dictionary info for it

           - self.tool.dicts = single dictionary that contains the tool info (only one tool dict in dicts list)
           - self.libs.dicts = list of dictionaries that contains the info of the HDL libraries.

           The libRootDir parameter is defined in the hdltool_<toolset>.cfg file and is the root directory from where the hdllib.cfg
           files are searched for.

           - self.lib_names = the library names of self.libs.dicts

           In parallel to the self.libs.dicts list of dictionaries a list of self.lib_names is created to be able to identify
           a HDL library dict also by its library name. Iherefore it is important that the indexing of parallel lists remains
           intact at all times.

           - self.technologyNames = the technologyNames parameter is defined in the hdltool_<toolset>.cfg file. All generic HDL
             libraries and these technology specific libraries are kept. If self.technologyNames is:
             []                              : Keep all HDL libraries that were found.
             ['ip_stratixiv', 'ip_arria10']  : The HDL libraries with a hdl_lib_technology that is not '' or does not match one of the technologies
                                               in technologyNames are removed from the list of HDL library dictionaries.

           - self.removed_dicts = contains the HDL library dicts that have been removed from self.libs.dicts, because they are for
                                  a technology that is not within technologyNames.
           - self.removed_lib_names = the library names of self.removed_dicts

           Keep lists of all unavailable library names that were found at the hdl_lib_uses_synth, hdl_lib_uses_ip, hdl_lib_uses_sim and
           hdl_lib_include_ip keys in the self.libs.dicts:

           - self.unavailable_use_libs = self.unavailable_use_synth_libs + self.unavailable_use_ip_libs + self.unavailable_use_sim_libs
           - self.unavailable_include_ip_libs

           Unavailable used libraries can be missing for a valid reason when they are not required (e.g. IP for another technology). Being able to
           ignore missing libraries does require that the entities from these libraries are instantiated as components in the VHDL. The difference
           between a removed library and an unavailable library is that for a removed library the HDL config information is still known, whereas
           for an unavailable library it is not. Therefore the library clause names for referred but unavailable HDL libraries are disclosed at the
           'hdl_lib_disclose_library_clause_names' keys of the libraries that use them and kept in a dictionary:

           - self.disclosed_library_clause_names

        """
        self.toolRootDir = toolRootDir
        self.libtop = libtop

        # HDL tool config file
        self.tool = common_dict_file.CommonDictFile(toolRootDir, toolFileName)      # tool dict filedupkc
        if self.tool.nof_dicts==0: sys.exit('Error : No HDL tool config file found')
        if self.tool.nof_dicts >1: sys.exit('Error : Multiple HDL tool config files found')
        self.tool_dict = self.tool.dicts[0]    # there is only one tool dict in dicts list so for convenience make it also accessible as self.tool_dict

        # HDL library config files
        self.libRootDir = os.path.expandvars(self.tool_dict['lib_root_dir'])
        self.libs = common_dict_file.CommonDictFile(self.libRootDir, libFileName, libFileSections)   # all library dict files found under tool's libRootDir ($RADIOHDL)
        self.periph_libs = PeripheralLibrary(root_dir=self.libRootDir).library
        self.fpga_libs = FPGALibrary(self.libRootDir).library
        self.fpga_lib_names = self.fpga_libs.keys()
        self.periph_lib_names = self.periph_libs.keys()#self.periph_libs.lib_names
        self.args_generated = []
        if self.libs.nof_dicts==0: sys.exit('Error : No HDL library config file found')

        # Keep the generic HDL libraries and remove those that do not match the specified IP technologies
        # BUT if there is a variant of the library that supports the technology then keep it out of the removed_lib_list
        self.technologyNames = self.tool_dict['technology_names'].split()

        
        
        good_list = []
        for ld in self.libs.dicts:
            if ld['hdl_lib_technology']=='' or (len(self.technologyNames)>0 and any(e in ld['hdl_lib_technology'].split() for e in self.technologyNames)):
               good_list.append(ld['hdl_lib_name'])

        self.removed_dicts = []
        temp = []
        if len(self.technologyNames)>0:
            for ld in self.libs.dicts:
                if not(ld['hdl_lib_technology']=='' or any(e in ld['hdl_lib_technology'].split() for e in self.technologyNames)):
                    if ld['hdl_lib_name'] not in good_list:
                        self.removed_dicts.append(ld)
                    temp.append(ld)

            for ld in temp:
                self.libs.remove_dict_from_list(ld)

        # Keep list of removed HDL library paths of found, but removed technology dicts
        self.removed_lib_names = self.libs.get_key_values(key='hdl_lib_name', dicts=self.removed_dicts, must_exist=True)

        # Keep list of used HDL library names
        self.lib_names = self.libs.get_key_values(key='hdl_lib_name', must_exist=True)

        # Check that there are no duplicate library names (eg. due to copying a hdlib.cfg without modifying the hdl_lib_name value)
        duplicate_lib_names = cm.list_duplicates(self.lib_names)
        if len(duplicate_lib_names)>0:
            for dup_name in duplicate_lib_names:
                while True:
                    # Get all dup_dicts libraries that use the same library name and remove them all
                    dup_dicts = cm.listify(self.libs.get_dicts('hdl_lib_name', values=dup_name))
                    if len(dup_dicts)>0:
                        for ld in dup_dicts:
                            k = self.libs.dicts.index(ld)
                            print("Warning : Duplicate HDL library config file found and removed from list: {}".format(self.libs.filePaths[k]))
                            self.libs.remove_dict_from_list(ld)
                    else:
                        break;
            # Update local list of HDL library names
            self.lib_names = self.libs.get_key_values('hdl_lib_name')

        # create dictionary of library names with library clause names that are disclosed at the 'hdl_lib_disclose_library_clause_names' keys.
        self.disclosed_library_clause_names = collections.OrderedDict()
        for lib_dict in self.libs.dicts:
            if 'hdl_lib_disclose_library_clause_names' in lib_dict:
                key_values = lib_dict['hdl_lib_disclose_library_clause_names'].split()
                lib_name = key_values[0::2]
                lib_clause_name = key_values[1::2]
                lib_pairs = zip(lib_name, lib_clause_name)
                # No need to check for duplicate lib_names, because a dictionary cannot have duplicate keys
                for lp in lib_pairs:
                    self.disclosed_library_clause_names[lp[0]] = lp[1]
        # Check whether the used libraries from the self.libs.dicts keys indeed exist, otherwise remove them from the dictionary key
        # string and add the used library name to the list of unavailable used library names and check that the library use clause
        # name was disclosed at the 'hdl_lib_disclose_library_clause_names' key. In this way other methods do not have to check a
        # used library does indeed exist.
        self.unavailable_use_synth_libs = []
        self.unavailable_use_ip_libs = []
        self.unavailable_use_sim_libs = []
        self.unavailable_include_ip_libs = []
        for lib_dict in self.libs.dicts:
            lib_name = lib_dict['hdl_lib_name']
            use_synth_libs = []
            use_ip_libs = []
            use_sim_libs = []
            include_ip_libs = []

            #print(self.libs.filePathNames[self.libs.dicts.index(lib_dict)])

            if 'hdl_lib_uses_synth' in lib_dict:
                use_synth_libs = lib_dict['hdl_lib_uses_synth'].split()
            if 'hdl_lib_uses_ip' in lib_dict:
                use_ip_libs += lib_dict['hdl_lib_uses_ip'].split()
            if 'hdl_lib_uses_sim' in lib_dict:
                use_sim_libs += lib_dict['hdl_lib_uses_sim'].split()
            if 'hdl_lib_include_ip' in lib_dict:
                include_ip_libs = lib_dict['hdl_lib_include_ip'].split()
            if lib_name in self.fpga_lib_names:
                # library of peripherals that should have names unique from self.periph_lib_names
                # generate files and append to lib dict's synth_files and vivado_tcl_files
                self.handle_args_lib_references(use_name=lib_name, lib_dict=lib_dict, is_fpga=True)

            for use_name in use_synth_libs:
                # ARGS assumption: only ARGS lib/peripherals can contain forward slashes - absolute paths not used here so shouldn't clash
                if (use_name not in self.lib_names) and (use_name not in self.removed_lib_names) and (use_name.split('/')[0] not in self.periph_lib_names):
                    lib_dict['hdl_lib_uses_synth']=cm.remove_from_list_string(lib_dict['hdl_lib_uses_synth'], use_name)
                    self.unavailable_use_synth_libs.append(use_name)
                    if use_name not in self.disclosed_library_clause_names.keys():
                        # logger.error("Error : Unavailable library %s at 'hdl_lib_uses_synth' key is not disclosed at 'hdl_lib_disclose_library_clause_names' key in library %s" % (use_name.upper(), lib_name.upper()))
                        sys.exit("Error : Unavailable library %s at 'hdl_lib_uses_synth' key is not disclosed at 'hdl_lib_disclose_library_clause_names' key in library %s" % (use_name.upper(), lib_name.upper()))
                # Handle ARGS peripheral files
                if use_name.split('/')[0] in self.periph_lib_names:
                    self.handle_args_lib_references(use_name, lib_dict)

            for use_name in use_ip_libs:
                if (use_name not in self.lib_names) and (use_name not in self.removed_lib_names):
                    if 'hdl_lib_include_ip' in lib_dict:
                        lib_dict['hdl_lib_include_ip']=cm.remove_from_list_string(lib_dict['hdl_lib_include_ip'], use_name)
                        self.unavailable_use_ip_libs.append(use_name)
                        if use_name not in self.disclosed_library_clause_names.keys():
                            # logger.error("Error : Unavailable library %s at 'hdl_lib_uses_ip' key is not disclosed at 'hdl_lib_disclose_library_clause_names' key in library %s" % (use_name, lib_name))
                            sys.exit("Error : Unavailable library %s at 'hdl_lib_uses_ip' key is not disclosed at 'hdl_lib_disclose_library_clause_names' key in library %s" % (use_name, lib_name))

                # Handle ARGS peripheral files
                if use_name.split('/')[0] in self.periph_lib_names:
                    self.handle_args_lib_references(use_name, lib_dict, 'hdl_lib_uses_sim')

            for use_name in include_ip_libs:
                if (use_name not in self.lib_names) and (use_name not in self.removed_lib_names):
                    lib_dict['hdl_lib_include_ip']=cm.remove_from_list_string(lib_dict['hdl_lib_include_ip'], use_name)
                    self.unavailable_include_ip_libs.append(use_name)
                    if use_name not in self.disclosed_library_clause_names.keys():
                        sys.exit("Error : Unavailable library %s at 'hdl_lib_include_ip' key in library %s is not disclosed at any 'hdl_lib_disclose_library_clause_names' key" % (use_name, lib_name))
                        #logger.error("Error : Unavailable library %s at 'hdl_lib_include_ip' key in library %s is not disclosed at any 'hdl_lib_disclose_library_clause_names' key" % (use_name, lib_name))

        # remove all duplicates from the list
        self.unavailable_use_synth_libs = cm.unique(self.unavailable_use_synth_libs)
        self.unavailable_use_ip_libs = cm.unique(self.unavailable_use_ip_libs)
        self.unavailable_use_sim_libs = cm.unique(self.unavailable_use_sim_libs)
        self.unavailable_use_libs = self.unavailable_use_synth_libs + self.unavailable_use_ip_libs + self.unavailable_use_sim_libs
        self.unavailable_use_libs = cm.unique(self.unavailable_use_libs)                 # aggregate list of use_*_libs
        self.unavailable_include_ip_libs = cm.unique(self.unavailable_include_ip_libs)   # list of include_ip_use_libs



    def check_library_names(self, check_lib_names, lib_names=None):
        """Check that HDL library names exists within the list of library names, if not then exit with Error message.
           The list of library names can be specified via the argument lib_names, or it defaults to the list of
           self.lib_names of HDL libraries that were found in the toolRootDir for the libFileName of this object.
        """
        if lib_names==None: lib_names=self.lib_names
        for check_lib_name in cm.listify(check_lib_names):
            if check_lib_name not in cm.listify(lib_names):
                sys.exit('Error : Unknown HDL library name %s found with %s' % (check_lib_name, cm.method_name()))


    def get_used_libs(self, build_type, lib_dict, arg_include_ip_libs=[]):
        """Get the list of used HDL libraries from the lib_dict that this library directly depends on, so only at this HDL library hierachy level.

           Which libraries are actually used depends on the build_type. The build_type can be:
            ''      uses all libraries from 'hdl_lib_uses_synth', 'hdl_lib_uses_ip' and 'hdl_lib_uses_sim' in the lib_dict
            'sim'   uses all libraries from 'hdl_lib_uses_synth', 'hdl_lib_uses_ip' and 'hdl_lib_uses_sim' in the lib_dict
            'synth' uses all libraries from 'hdl_lib_uses_synth' in the lib_dict and from 'hdl_lib_uses_ip' it only uses the IP
                    libraries that are mentioned in the local 'hdl_lib_include_ip' key or in the global arg_include_ip_libs

           The 'hdl_lib_uses_*' keys all appear locally in the same hdllib.cfg file. The 'hdl_lib_include_ip' key appears at this level or at
           a higher level (design) library hdllib.cfg file to select which of all available 'hdl_lib_uses_ip' IP libraries will actually be
           used in the design. The 'hdl_lib_include_ip' cannot appear in a lower level hdllib.cfg, because a lower level HDL library cannot
           depend on a higher level HDL library. Therefore the IP libraries that need to be included from 'hdl_lib_uses_ip' will be known in
           include_ip_libs.
        """
        # Get local library dependencies
        use_synth_libs = []
        use_ip_libs = []
        use_sim_libs = []
        include_ip_libs = []
        if 'hdl_lib_uses_synth' in lib_dict:
            use_synth_libs = lib_dict['hdl_lib_uses_synth'].split()
        if 'hdl_lib_uses_ip' in lib_dict:
            use_ip_libs += lib_dict['hdl_lib_uses_ip'].split()
        if 'hdl_lib_uses_sim' in lib_dict:
            use_sim_libs += lib_dict['hdl_lib_uses_sim'].split()
        if 'hdl_lib_include_ip' in lib_dict:
            include_ip_libs = lib_dict['hdl_lib_include_ip'].split()

        # Append include_ip_libs from this level to the global list of arg_include_ip_libs
        include_ip_libs = list(arg_include_ip_libs) + include_ip_libs

        # Get the actually use_libs for lib_dict
        use_libs = use_synth_libs + use_ip_libs + use_sim_libs  # default include all IP, so ignore include_ip_libs
#        if build_type=='sim':
#            use_libs = use_synth_libs + use_ip_libs + use_sim_libs    # for simulation included all IP, so ignore include_ip_libs
#        if build_type=='synth':
#            use_libs = use_synth_libs
#            # For synthesis only keep the local use_ip_libs if it is mentioned in the global include_ip_libs. Vice versa also only
#            # include the global include_ip_libs if they appear in a local use_ip_libs, to avoid that an IP library that is mentioned
#            # in the global include_ip_libs gets included while it is not instantiated anywhere in the design.
#            for ip_lib in use_ip_libs:
#                if ip_lib in include_ip_libs:
#                    use_libs += [ip_lib]

        # Strip out discolsed libraries that haven't been used but only for sim or synth builds
        if build_type == 'synth' or build_type=='sim':
            remove_libs = []
            for name in self.disclosed_library_clause_names:
                if name not in include_ip_libs:
                   if name not in self.removed_lib_names:
                      self.removed_lib_names.append(name)

        # Remove any duplicate library names from the lists
        use_libs = cm.unique(use_libs)
        include_ip_libs = cm.unique(include_ip_libs)

        # Remove libraries that are in the removed technologies (use list() to take copy)
        for use_name in list(use_libs):
            if use_name in self.removed_lib_names:
                use_libs.remove(use_name)
        for use_name in list(include_ip_libs):
            if use_name in self.removed_lib_names:
                include_ip_libs.remove(use_name)

        return use_libs, include_ip_libs


    def derive_all_use_libs(self, build_type, lib_name, arg_include_ip_libs=[]):
        """Recursively derive a complete list of all HDL libraries that the specified HDL lib_name library depends on, so from this
           HDL library down the entire hierachy.

           The hdl_lib_uses_* key only needs to contain all libraries that are declared at the VHDL LIBRARY clauses of the
           source files in this VHDL library. This derive_all_use_libs() will recursively find all deeper level VHDL libraries as well.

           The arg_include_ip_libs selects the IP library to keep from 'hdl_lib_uses_ip'. The include_ip_libs is passed on
           through the recursion hierarchy via arg_include_ip_libs to ensure that the from the top level library down all
           multiple choice IP libraries in 'hdl_lib_uses_ip' that need to be included are indeed included. The multiple choice IP
           libraries in 'hdl_lib_uses_ip' that are not in include_ip_libs are excluded.

           Note:
           . Only the generic HDL libraries and the technology specific libraries that match self.technologyNames are used,
             because the other technology libraries have been removed from self.libs.dicts already at __init__() and from the
             library dependency lists in get_used_libs()
        """
        # use list() to take local copy, to avoid next that default empty list argument arg_include_ip_libs=[] gets disturbed
        include_ip_libs = list(arg_include_ip_libs)

        if lib_name in self.lib_names:
            all_use_libs = [lib_name]
            lib_dict = self.libs.dicts[self.lib_names.index(lib_name)]
            use_libs, include_ip_libs = self.get_used_libs(build_type, lib_dict, include_ip_libs)

            for use_lib in use_libs:
                if use_lib not in all_use_libs:
                    all_use_libs.append(use_lib)
                    # use recursion to include all used libs
                    all_use_libs += self.derive_all_use_libs(build_type, use_lib, include_ip_libs)
            # remove all duplicates from the list
            return cm.unique(all_use_libs)
        else:

            print(self.lib_names)

            sys.exit('Error : Unknown HDL library name %s in %s()' % (lib_name, cm.method_name()))








    def derive_lib_order(self, build_type, lib_name, lib_names=None):
        """Derive the dependency order for all HDL libraries in lib_names that HDL library lib_name depends on.
        """
        if lib_names==None:
            # At first entry derive the list of all HDL libraries that lib_name depends on
            lib_names = self.derive_all_use_libs(build_type, lib_name)

        # Derive the order of all HDL libraries that lib_name depends on, start with the order of lib_names
        lib_dicts = self.libs.get_dicts('hdl_lib_name', values=lib_names)
        # use list() to take local copy to avoid modifying list order of self.lib_names which matches self.libs.dicts list order
        lib_order = list(lib_names)

        for lib_dict in cm.listify(lib_dicts):
            lib_name = lib_dict['hdl_lib_name']
            use_libs, _ = self.get_used_libs('', lib_dict, [])
            for use_lib in use_libs:
                if use_lib in lib_names:
                    if lib_order.index(use_lib) > lib_order.index(lib_name):
                        lib_order.remove(use_lib)
                        lib_order.insert(lib_order.index(lib_name), use_lib)  # move used lib to just before this lib
        # use recursion to keep on reordering the lib_order until it is stable
        if lib_names != lib_order:
            lib_order = self.derive_lib_order(build_type, lib_name, lib_order)
        return lib_order


    def get_lib_dicts_from_lib_names(self, lib_names=None):
        """Get list the HDL libraries lib_dicts from list of HDL libraries lib_names and preseve the library order.
        """
        if lib_names==None: lib_names=self.lib_names
        # Cannot use:
        #lib_dicts = self.libs.get_dicts('hdl_lib_name', values=lib_names)
        # because then the order of self.libs.dicts is used
        lib_dicts = []
        for lib_name in cm.listify(lib_names):
            lib_dict = self.libs.dicts[self.lib_names.index(lib_name)]
            lib_dicts.append(lib_dict)
        return lib_dicts


    def get_lib_names_from_lib_dicts(self, lib_dicts=None):
        """Get list the HDL libraries lib_names from list of HDL libraries lib_dicts and preseve the library order.
        """
        lib_names = self.libs.get_key_values('hdl_lib_name', lib_dicts)
        return lib_names


    def get_tool_build_dir(self, build_type):
        """Get the central tool build directory.

        The build_type can be:
            'sim'   uses the 'tool_name_sim'   key in the self.tool_dict
            'synth' uses the 'tool_name_synth' key in the self.tool_dict

        The build dir key value must be an absolute directory path. The tool build dir consists of
            - the absolute path to the central main build directory
            - the toolset_name key value as subdirectory
            - the tool_name_* key value as subdirectory
        """
        # Determine build_maindir
        build_maindir = os.path.expandvars(self.tool_dict['build_dir'])
        if not os.path.isabs(build_maindir):
            sys.exit('Error : The build_dir value must be an absolute path' + build_maindir)
        # Determine build_toolset_dir
        build_toolset_dir = self.tool_dict['toolset_name']
        # Determine build_tooldir
        tool_name_key = 'tool_name_' + build_type
        if self.tool_dict[tool_name_key]==None:
            sys.exit('Error : Unknown build type for tool_name_key')
        build_tooldir = self.tool_dict[tool_name_key]
        return build_maindir, build_toolset_dir, build_tooldir

    def get_lib_build_dirs(self, build_type, lib_dicts=None):
        """Get the subdirectories within the central tool build directory for all HDL libraries in the specified list of lib_dicts.

        The build_type can be:
            'sim'   uses the 'tool_name_sim'   key in the self.tool_dict
            'synth' uses the 'tool_name_synth' key in the self.tool_dict

        The build dir key value must be an absolute directory path. The lib build dir consists of
            - the absolute path to the central main build directory
            - the tool_name_key value as subdirectory
            - the library name as library subdirectory
        """
        if lib_dicts==None: lib_dicts=self.libs.dicts
        build_maindir, build_toolset_dir, build_tooldir = self.get_tool_build_dir(build_type)
        build_dirs = []
        for lib_dict in cm.listify(lib_dicts):
            lib_name = lib_dict['hdl_lib_name']
            build_dirs.append(os.path.join(build_maindir, build_toolset_dir, build_tooldir, lib_name))  # central build main directory with subdirectory per library
        return cm.unlistify(build_dirs)


    def create_lib_order_files(self, build_type, lib_names=None):
        """Create the compile order file '<lib_name>_lib_order.txt' for all HDL libraries in the specified list of lib_names.

           The file is stored in the sim build directory of the HDL library.
           The file is read by commands.do in Modelsim to avoid having to derive the library compile order in TCL.
        """
        if lib_names==None: lib_names=self.lib_names
        lib_dicts = self.libs.get_dicts('hdl_lib_name', values=lib_names)
        for lib_dict in cm.listify(lib_dicts):
            lib_name = lib_dict['hdl_lib_name']
            lib_order = self.derive_lib_order(build_type, lib_name)
            file_name = lib_name + '_lib_order.txt'
            file_path = self.get_lib_build_dirs('sim', lib_dicts=lib_dict)
            cm.mkdir(file_path)
            filePathName = os.path.join(file_path, file_name)
            with open(filePathName, 'w') as fp:
                for lib in lib_order:
                    fp.write('%s ' % lib)

    def read_hdl_libraries_technology_file(self, technologyName, tool, filePath=None):
        """Read the list of technology HDL libraries from a file.

           Arguments:
           - technologyName : refers to the hdl_libraries_<technologyName>.txt file
           - filePath       : path to hdl_libraries_<technologyName>.txt, when None then the file is
                              read in the default toolRootDir
        """
        fileName = 'hdl_libraries_' + technologyName + '.txt'                  # use fixed file name format
        if filePath==None:
            toolSubDir = self.tool_dict[tool]
            fileNamePath=os.path.join(self.toolRootDir, toolSubDir, fileName)  # default file path
        else:
            fileNamePath=os.path.join(filePath, fileName)                      # specified file path
        tech_dict = self.tool.read_dict_file(fileNamePath)
        return tech_dict


    def copy_files(self, build_type, lib_names=None):
        """Copy all source directories and source files listed at the <tool_name>_copy_files key. The build_type selects the <tool_name>_copy_files key using the
           tool_name_<build_type> key value from the hdltool_<toolset>.cfg.
           The <tool_name>_copy_files key expects a source and a destination pair per listed directory or file:

           - The sources need to be specified with absolute path or relative to the HDL library source directory where the hdllib.cfg is stored
           - The destinations need to be specified with absolute path or relative to HDL library build directory where the project file (e.g. mpf, qpf) gets stored

           Arguments:
           - lib_names      : one or more HDL libraries
        """
        if lib_names==None: lib_names=self.lib_names
        lib_dicts = self.libs.get_dicts(key='hdl_lib_name', values=lib_names)
        tool_name_key = 'tool_name_' + build_type
        tool_name_value = self.tool_dict[tool_name_key]
        tool_name_copy_key = tool_name_value + '_copy_files'
        for lib_dict in cm.listify(lib_dicts):
            if tool_name_copy_key in lib_dict:
                lib_path = self.libs.get_filePath(lib_dict)
                build_dir_path = self.get_lib_build_dirs(build_type, lib_dicts=lib_dict)
                cm.mkdir(build_dir_path)
                key_values = lib_dict[tool_name_copy_key].split()
                sources = key_values[0::2]
                destinations = key_values[1::2]
                file_io = zip(sources, destinations)
                for fpn_io in file_io:
                    sourcePathName = cm.expand_file_path_name(fpn_io[0], lib_path)
                    destinationPath = cm.expand_file_path_name(fpn_io[1], build_dir_path)
                    if os.path.isfile(sourcePathName):
                        shutil.copy(sourcePathName, destinationPath)     # copy file
                    else:
                        copy_tree(sourcePathName, destinationPath)       # copy directory tree (will create new destinationPath directory)

    def handle_args_lib_references(self, use_name, lib_dict, hdllib_key='hdl_lib_uses_synth', is_fpga=False):
        use_name_keep = use_name
        use_name_split = use_name.split('/')
        lib_name = use_name_split[0]
        periph_name = 'None' if len(use_name_split) == 1 else use_name_split[1]
        args_lib_name = 'None' if periph_name == 'None' else '_'.join(use_name_split) # if peripheral is specified in fpga.yaml
        args_lib_dict = self.gen_args_lib_dict(lib_name, periph_name, args_lib_name, is_fpga)
        if args_lib_dict is None:
            return
        args_lib_name = args_lib_dict['hdl_lib_name']
        if args_lib_name not in self.lib_names:
        # if hdllib.cfg exists for an args lib then it will be called within that hdllib.cfg file
            self.libs.dicts.insert(0, args_lib_dict)
            self.libs.nof_dicts = len(self.libs.dicts)
            self.lib_names.insert(0, args_lib_name)
            self.libs.filePaths.insert(0, self.periph_libs[lib_name]['file_path'])
            self.libs.filePathNames.insert(0,self.periph_libs[lib_name]['file_path_name'])
        else:
            #if self.libtop == None or args_lib_name not in self.libtop:
            self.args_update_dict(self.libs.dicts[self.lib_names.index(args_lib_name)], args_lib_dict)
            logger.info("Updated lib_dict %s [%s]", args_lib_name, ' '.join([incl_lib.split('\\')[-1] for incl_lib in lib_dict.get('synth_files','').split(' ')]))
            logger.info("Updated lib_dict %s [%s]", args_lib_name, ' '.join([incl_lib.split('\\')[-1] for incl_lib in lib_dict.get('vivado_tcl_files','').split(' ')]))
            #else:
            #   logger.info("Didn't update lib_dict {} as its not the top library".format(args_lib_name))
        # update referred lib name from hdl_lib_uses_sim
        if not is_fpga:
            lib_dict[hdllib_key] = lib_dict[hdllib_key].replace(use_name_keep, args_lib_name)


        return

    def gen_args_lib_dict(self, args_lib_name, periph_select='None', lib_name_custom='None', is_fpga=False): # to support peripheral.py and fpga.py
        try:
            os.stat(os.path.expandvars('$HDL_BUILD_DIR/ARGS'))
        except:
            os.makedirs(os.path.expandvars('$HDL_BUILD_DIR/ARGS'))
        final_name = args_lib_name if lib_name_custom == 'None' else lib_name_custom
        if (final_name in self.args_generated or lib_name_custom!="None") and is_fpga==False :
            logger.warning("ARGS has already generated firmware and documentation for the library {}, will not repeat.".format(args_lib_name)) # have to tolerate when part of fpga
            return None
        logger.debug("gen_args_lib_dict {} hdl_lib_dict \'{}\' args_lib_name \'{}\' lib_name_custom \'{}\'".format(str(datetime.datetime.now()),final_name, args_lib_name, lib_name_custom))
        args_lib_dict = {}
        peripherals = self.fpga_libs[args_lib_name]['peripherals'] if is_fpga else self.periph_libs[args_lib_name]['peripherals']
        output_files = []
        if is_fpga:
            fpga_bus = gen_bus.Bus(self.fpga_libs[args_lib_name]['fpga'])
            gen_fpgamap_py.genPython(self.fpga_libs[args_lib_name], args_lib_name, True)
            out_dir = os.path.expandvars('$HDL_BUILD_DIR/ARGS/{}/'.format(args_lib_name))
            gen_c_config.gen_c_config(self.fpga_libs[args_lib_name], args_lib_name, out_dir)
            output_files.extend(fpga_bus.gen_firmware())

        for component_name, peripheral in peripherals.items():
            # if periph_select != 'None' and periph['peripheral_name'] != periph_select:
            # logger.warning("peripheral name: {}".format(component_name))
            if periph_select != 'None' and component_name != periph_select:
                continue
            if peripheral.evaluated == False:
                peripheral.eval_peripheral()
            periph_slave = gen_slave.Slave(peripheral, args_lib_name if is_fpga else None)
            periph_slave.generate_regs(peripheral)
            for key in peripheral.rams:
                periph_slave.generate_mem(peripheral.rams[key],'ram')
            for key in peripheral.fifos:
                periph_slave.generate_mem(peripheral.fifos[key],'fifo')
            output_files.extend(periph_slave.output_files)

        if output_files:
            args_lib_dict['hdl_lib_name'] = final_name
            args_lib_dict['hdl_lib_uses_synth'] = "common technology axi4"
            args_lib_dict['synth_files'] = ''.join([out_file + ' ' for out_file in output_files if '.vhd' in out_file])
            args_lib_dict['vivado_tcl_files'] = ''.join([out_file + ' ' for out_file in output_files if '.tcl' in out_file])
            # logger.warning(output_files)
        else :
            args_lib_dict['hdl_lib_name'] = args_lib_name if lib_name_custom == 'None' else lib_name_custom
            print('Warning: ARGS peripheral library {} and ARGS peripheral selection {} did not result in any generated reg files'.format(args_lib_name, periph_select))
            # sys.exit('Error: ARGS peripheral library %s and ARGS peripheral selection %s did not result in any generated reg files' %(args_lib_name, periph_select))
        # TODO: add error checking if peripheral doesn't exist or dictionary ends up empty?

        # gen documentation

        self.args_gen_doc(final_name, is_fpga)
        if periph_select == 'None': self.args_generated.append(final_name)

        return args_lib_dict

    def args_update_dict(self, current_dict, args_dict):
        temp_list = []
        current_dict['hdl_lib_uses_synth'] = cm.dict_value_combine('hdl_lib_uses_synth', args_dict, current_dict)
        current_dict['hdl_lib_uses_sim'] = cm.dict_value_combine('hdl_lib_uses_sim', args_dict, current_dict)
        current_dict['synth_files'] = cm.dict_value_combine('synth_files', args_dict, current_dict)
        current_dict['vivado_tcl_files'] = cm.dict_value_combine('vivado_tcl_files', args_dict, current_dict)
        return

    def args_gen_doc(self, lib_name, is_fpga): #, output_files):
        devnull = open(os.devnull, 'w')
        try:
            subprocess.call("pdflatex -version", stdout=devnull, stderr=devnull)
        except FileNotFoundError:
            logger.warning("No latex distribution detected, skipping ARGS documentation generation")
            return
        logger.warning('Generating PDF documentation for library {}...'.format(lib_name))
        if not is_fpga:
            doc = gen_doc.PeripheralDocumentation(lib_name, self.periph_libs[lib_name])
            doc.fill()
            doc.make_pdf()
            del doc
        else:
            doc = gen_doc.FPGADocumentation(lib_name, self.fpga_libs[lib_name])
            doc.fill()
            doc.make_pdf()
            del doc
        return

class HdlParseArgs:
    """ Parse command line arguments
    """
    def __init__(self, toolsetSelect):
        # Parse command line arguments
        argparser = argparse.ArgumentParser(description='HDL config command line parser arguments')
        argparser.add_argument('-t','--toolset', required=False, help='choose toolset %s (default: %s)' % (toolsetSelect,toolsetSelect[0]), default=toolsetSelect[0])
        argparser.add_argument('-l','--lib', default=None, required=False, help='library names separated by commas')
        argparser.add_argument('-r','--run', required=False, action='store_true', default=False, help='Run project to completion to obtain bitfile')
        argparser.add_argument('-p','--project', required=False, action='store_true', default=False, help='Create project but do not execute')
        argparser.add_argument('-ip', required=False, action='store_true', default=False, help='Generate simulation files for technology libraries')
        argparser.add_argument('-v','--verbosity', required=False, type=int, default=0, help='verbosity >= 0 for more info')
        argparser.add_argument('-a','--args', required=False, action='store_true', default=False, help='Run ARGS code generation only (do not create a new project)')
        args = vars(argparser.parse_args())

        # Keep the argparser for external access of e.g. print_help
        self.argparser = argparser

        # Keep arguments in class record
        self.toolset = args['toolset']

        self.lib_names = []
        if args['lib']!=None:
            self.lib_names = args['lib'].split(',')

        self.lib_top = self.lib_names.copy()
        self.run = args['run']
        self.argsOnly = args['args']
        self.project = args['project']
        self.ip = args['ip']

        if self.toolset not in toolsetSelect:
            print("Toolset {} is not supported".format(self.toolset))
            print('Hint: give argument -h for possible options')
            sys.exit(1)
        self.toolFileName = 'hdltool_' + self.toolset + '.cfg'

        self.verbosity = args['verbosity']


if __name__ == '__main__':
    # Mode
    # 0 = Read dictionary info from all HDL tool and library configuration files and derive the compile order
    # 1 = Change a key value in all hdllib.cfg dict files
    # 2 = Insert a new key = value pair in all hdllib.cfg dict files at the specified line number
    # 3 = Insert a new key = value pair in all hdllib.cfg dict files just before an already existing key
    # 4 = Rename a key in all hdllib.cfg dict files
    # 5 = Remove a new key = value pair from all hdllib.cfg dict files
    mode = 0

    # Parse command line arguments
    hdl_args = HdlParseArgs(toolsetSelect=cm.find_all_toolsets(os.path.expandvars('$RADIOHDL/tools')))

    # Read the dictionary info from all HDL tool and library configuration files in the current directory and the sub directories
    hdl = HdlConfig(toolRootDir=os.path.expandvars('$RADIOHDL/tools'), libFileName='hdllib.cfg', toolFileName=hdl_args.toolFileName)

    if mode==0:
        print("#")
        print("# HdlConfig:")
        print("#")
        for i, p in enumerate(hdl.libs.filePathNames):
            print(i, p)
            d = hdl.libs.dicts[i]
#            for k,v in d.iteritems():
#                print(k, '=', v)
            print('')

        print('')
        print('Toolset file = ', hdl.tool.filePathNames[0])

        print('')
        print('Library paths :')
        for p in hdl.libs.filePaths:
            print('    ', p)

        print('')
        print('Library paths names :')
        for p in hdl.libs.filePathNames:
            print('    ', p)

        print('')
        print('Library section headers :')
        for lib_name in hdl.lib_names:
            lib_dict = hdl.libs.dicts[hdl.lib_names.index(lib_name)]
            print("    {:52} :{}".format(lib_name, lib_dict['section_headers']))

        print('')
        print('get_lib_build_dirs for simulation:')
        for build_dir in hdl.get_lib_build_dirs('sim'):
            print('    ', build_dir)

        print('')
        print('get_lib_build_dirs for synthesis:')
        for build_dir in hdl.get_lib_build_dirs('synth'):
            print('    ', build_dir)

        print('')
        print('Removed library names = \n', hdl.removed_lib_names)

        print('')
        print('Library names = \n', hdl.lib_names)

        print('')
        print("Unavailable library names in any 'hdl_lib_uses_synth' key = \n", hdl.unavailable_use_synth_libs )
        print("Unavailable library names in any 'hdl_lib_uses_ip' key = \n", hdl.unavailable_use_ip_libs       )
        print("Unavailable library names in any 'hdl_lib_uses_sim' key = \n", hdl.unavailable_use_sim_libs     )
        print("Unavailable library names in any 'hdl_lib_uses_*' key = \n", hdl.unavailable_use_libs           )
        print('')
        print("Unavailable library names in any 'hdl_lib_include_ip' key = \n", hdl.unavailable_include_ip_libs)

        print('')
        print("Used library clause names that are explicitly disclosed at the 'hdl_lib_disclose_library_clause_names' keys:")
        for key in hdl.disclosed_library_clause_names.keys():
            print("    {:52} : {}".format(key, hdl.disclosed_library_clause_names[key]))

        for build_type in ['sim', 'synth']:
            print("")
            print("derive_all_use_libs for {} of {} = \n".format(build_type, hdl_args.lib_top), hdl.derive_all_use_libs(build_type, hdl_args.lib_top))
            print("")
            print("derive_lib_order for {} of {} = \n".format(build_type, hdl_args.lib_top), hdl.derive_lib_order(build_type, hdl_args.lib_top))

        print('')
        print('Help: use -h')
        hdl_args.argparser.print_help()

    if mode==1:
        key = 'build_dir'
        new_value = '$HDL_BUILD_DIR'
        for p in hdl.libs.filePathNames:
             hdl.libs.change_key_value_in_dict_file(p, key, new_value)

    if mode==2:
        insert_key = 'hdl_lib_technology'
        insert_value = ''
        insertLineNr = 4
        for p in hdl.libs.filePathNames:
             hdl.libs.insert_key_in_dict_file_at_line_number(p, insert_key, insert_value, insertLineNr)

    if mode==3:
        insert_key = '[quartus_project_file]'
        insert_value = '\n'
        insert_beforeKey = 'synth_files'
        for p in hdl.libs.filePathNames:
             hdl.libs.insert_key_in_dict_file_before_another_key(p, insert_key, insert_value, insert_beforeKey)

    if mode==4:
        old_key = 'hdl_lib_uses'
        new_key = 'hdl_lib_uses_synth'
        for p in hdl.libs.filePathNames:
             hdl.libs.rename_key_in_dict_file(p, old_key, new_key)

    if mode==5:
        remove_key = 'modelsim_search_libraries'
        for p in hdl.libs.filePathNames:
             hdl.libs.remove_key_from_dict_file(p, remove_key)
