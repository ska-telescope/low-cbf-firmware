#! /usr/bin/env python
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
###############################################################################

"""Regression test generation for simulating pure VHDL test benches with Modelsim.

   Preconditions:
   - run modelsim_config.py to create the Modelsim project files
   - run generate-all-ip.sh to create all technology specific IP HDL

   Usage:
   > python $RADIOHDL/tools/oneclick/base/modelsim_regression_test_vhdl.py -h

   --lib:
   The --lib specifies which HDL libraries are used. If --lib is not specified
   then all available HDL libraries are used.
   Only the HDL libraries that have a 'regression_test_vhdl' key are processed
   further.

   --run:
   Without --run only the test bench do files are created for the VHDL test bench
   files that are listed at the 'regression_test_vhdl' key. With --run then
   the created test bench do files are also ran and the transcript log is saved.
   The do files and the log files are kept in the same build directory as the mpf
   directory of the HDL library. From the log files the regression test also
   reports a pass/fail result summary in modelsim_regression_test_vhdl.log.

"""

import common as cm
import hdl_config
import modelsim_config
import sys
import subprocess
import glob
import os.path
import shutil
import time
import datetime
import platform
import shutil

###############################################################################
# Parse command line arguments
###############################################################################
myPath = os.path.expandvars('$HDL_BUILD_DIR') #os.getcwd()

hdl_args = hdl_config.HdlParseArgs(toolsetSelect=cm.find_all_toolsets(os.path.expandvars('$RADIOHDL/tools')))
if hdl_args.verbosity>=1:
    print('')
    hdl_args.argparser.print_help()
###############################################################################
# Trash old simulation data
###############################################################################

sim_files = os.path.join(myPath, hdl_args.toolset, "modelsim")

print("Remove old simulation files from: {}".format(sim_files))

if os.path.exists(sim_files):
   shutil.rmtree(sim_files, ignore_errors=True)


###############################################################################
# Read the dictionary info from all HDL tool and library configuration files in the current directory and the sub directories
###############################################################################

print("Scanning for regression test files")

msim = modelsim_config.ModelsimConfig(toolRootDir=os.path.expandvars('$RADIOHDL/tools'), libFileName='hdllib.cfg', toolFileName=hdl_args.toolFileName, verbosity=hdl_args.verbosity)


###############################################################################
# Build the IP Simulation libraries
###############################################################################

# Generate IP libraries (Needed as some veriifcation processes need IP)
build_maindir, build_toolsetdir, build_tooldir = msim.get_tool_build_dir('sim')
if platform.system().lower() == "windows":
    subprocess.call(["run_vcomp.cmd",hdl_args.toolset, msim.tool_dict['tool_name_synth'],  msim.tool_dict['tool_version_synth'],os.path.join(build_maindir, build_toolsetdir, build_tooldir, 'generate_ip.tcl')], shell=True)
else:
    subprocess.call(["run_vcomp",hdl_args.toolset, msim.tool_dict['tool_name_synth'],  msim.tool_dict['tool_version_synth'],os.path.join(build_maindir, build_toolsetdir, build_tooldir, 'generate_ip.tcl')])




###############################################################################
# Get HDL library names for regression test
###############################################################################
lib_names = hdl_args.lib_names            # Default use lib_names from command line
msim.check_library_names(lib_names)       # Check that the provided lib_names indeed exist
if lib_names==[]:
    lib_names=msim.lib_names              # If no lib_names are provided then use all available HDL libraries
lib_dicts = msim.libs.get_dicts(key='hdl_lib_name', values=lib_names)                       # Get HDL libraries dicts
test_dicts = msim.libs.get_dicts(key='regression_test_vhdl', values=None, dicts=lib_dicts)  # Get HDL libraries dicts with 'regression_test_vhdl' key

if hdl_args.verbosity>=1:
    print('')
    print("List of HDL libraries with 'regression_test_vhdl' key and the specified VHDL test benches:")
    nof_lib = 0
    total_nof_tb = 0
    for lib_dict in cm.listify(test_dicts):
        nof_lib += 1
        lib_name = lib_dict['hdl_lib_name']
        test_bench_files = lib_dict['regression_test_vhdl'].split()
        if len(test_bench_files)==0:
            print('%-20s : -' % lib_name)
        else:
            for tbf in test_bench_files:
                total_nof_tb += 1
                print('%-20s : %s' % (lib_name, tbf))
    print('')
    print('The regression test contains %d HDL libraries and in total %d test benches.' % (nof_lib, total_nof_tb))
    print('')

###############################################################################
# Create test bench do files in same build directory as where the mpf is
###############################################################################
project_sim_p_defaults, project_sim_p_search_libraries, project_sim_p_otherargs, project_sim_p_optimization = msim.simulation_configuration(list_mode=True)

do_subdir = 'regression_test_vhdl'
for lib_dict in cm.listify(test_dicts):
    lib_name = lib_dict['hdl_lib_name']
    mpf_path = msim.get_lib_build_dirs('sim', lib_dicts=lib_dict)
    do_path = os.path.join(mpf_path, do_subdir)
    cm.mkdir(do_path)                                                     # mkdir <mpf_path>/regression_test_vhdl, if it does not exist yet
    for rm in glob.glob(os.path.join(do_path, '*.do')): os.remove(rm)     # rm <mpf_path>/regression_test_vhdl/*.do
    for rm in glob.glob(os.path.join(do_path, '*.log')): os.remove(rm)    # rm <mpf_path>/regression_test_vhdl/*.log
    test_bench_files = lib_dict['regression_test_vhdl'].split()
    for tbf in test_bench_files:
        tbf_name = os.path.basename(tbf)
        tb_name = os.path.splitext(tbf_name)[0]
        do_name = tb_name + '.do'
        doPathName = os.path.join(do_path, do_name)
        # Write separate do file for each test bench in the VHDL regression test of this library
        with open(doPathName, 'w') as fp:
            fp.write('# Created by modelsim_regression_test_vhdl.py\n')
            fp.write('do $env(RADIOHDL)/tools/modelsim/commands.do\n')
            fp.write('echo ">>> PROJECT LOAD %s"\n' % lib_name)
            fp.write('lp %s\n' % lib_name)
            fp.write('echo ">>> PROJECT MAKE %s"\n' % lib_name)
            fp.write('mk all\n')
            fp.write('echo ">>> SIMULATION LOAD %s"\n' % tb_name)
            fp.write('vsim ')
            for other_arg in project_sim_p_otherargs:
                fp.write('%s ' % other_arg)
            for search_lib in project_sim_p_search_libraries:
                fp.write('-L %s ' % search_lib)
            fp.write('-novopt work.%s xpm.glbl\n' % tb_name)
            fp.write('echo ">>> SIMULATION RUN %s"\n' % tb_name)
            # Use onbreak to avoid that vsim halts when a simulation VHDL assert failure occurs
            fp.write('onbreak {quit -f}\n')
            # Use onerror to avoid that vsim halts when a simulation fatal error occurs
            fp.write('onerror {quit -f}\n')
            # Use when -label tb_end to stop a tb or multi tb_tb that cannot be stopped by stopping all clocks
            fp.write("when -label tb_end {tb_end == '1'} {\n")
            fp.write('    echo "End of simulation due to -label";\n')
            fp.write('    echo ">>> SIMULATION END  %s (Now = $Now)";\n' % tb_name)
            fp.write('    break;\n')
            fp.write('}\n')
            # A multi tb_tb that cannot stop its clocks will have been stopped by a top level tb_end
            # A multi tb_tb that can stop its clocks may not have a top level tb_end en will be stopped here
            fp.write('run -all\n')
            fp.write('echo "End of simulation due to stop toggling";\n')
            fp.write('echo ">>> SIMULATION END  %s (Now = $Now)"\n' % tb_name)
            fp.write('quit\n')


###############################################################################
# Optionally run the test bench do files
###############################################################################

# Remarks on subprocess:
# . Use shell=True to be able to pass on the entire CLI command and have environment variable and wildcard expansion.
# . Use call to run the CLI command and capture the exit code and avoid that Python breaks with CalledProcessError on exit code > 0.
# . Exit code 0 is ok, exit code > 0 is some error, but for 'egrep' exit 1 means that no match was found for the expression.
# . If 'egrep' has exit 0 then a match was found for the expression and then check_output can be used to capture the match.
# . An alternative scheme is to use try-except subprocess.CalledProcessError to handle exit code > 0.

# Remarks using tb_end <='1' to end a simulation
# . The tb_end is or-ed with the clocks, so tb_end <='1' stops all toggling and this ends the tb (see any tb, e.g. tb_dp_split.vhd)
# . For components that have some self ocillation the toggling does not stop so then:
#   - for manual tests in the GUI 'REPORT "Tb simulation finished." SEVERITY FAILURE' in the tb VHDL is used to stop the tb simulation
#   - for regression tests the "when -label tb_end='1'" in the do file is used to stop the tb simulation
#   To make this scheme work it is neccessary to have some WAIT time between tb_end <='1' and the FAILURE.
# . For multi tb_tb there needs to be a top level tb_end signal, even if it is not used, to ensure that the "when -label tb_end='1'"
#   can be applied (see e.g. tb_tb_mms_diag_block_gen.vhd).
# . For multi tb_tb that rely on the FAILURE to end the simulation there is a top level tb_end_vec signal that needs to be used to
#   raise a top level tb_end <= '1' when all sub tb have ended (see e.g. tb_tb_tech_mac_10g.vhd).
#
# Remarks on checking for 'Error' and 'Failure' to detect whether a tb has failed:
#   Make sure the tb has some WAIT time between "tb_end <= '1'" and 'REPORT "Tb simulation finished." SEVERITY FAILURE'.
#   The tb_end will stop the tb in the regression test (via when -label tb_end='1') and the FAILURE will stop the tb
#   in manual simulation in the GUI. The advantage is that the regression test can check also on 'Failure' to detect
#   whether a tb has failed.

# Remarks on Modelsim simulation control:
# . Google search: modelsim stop simulation vhdl
#
# . How to stop the simulation in VHDL TB
#
#   1) The easiest way is to use an assert:  assert false report "Simulation Finished" severity failure;
#   2) The "recommended" way to end a simulation when everything has gone correctly, is to halt all stimulus. This will be stopping
#      the clock like, but also putting any input processes into a never ending wait if they do not use the generated clock.
#   3) In VHDL 2008, they have introduced and new package called env to the std library, with procedures called stop and finish,
#      that act like $finish in verilog. This works, but is not used because the scheme with tb_end suffices:
#
#         library std;
#         use std.env.all;
#
#         .......
#         stop(0);
#         --or
#         finish(0);
#
#         -- For both STOP and FINISH the STATUS values are those used
#           -- in the Verilog $finish task
#           -- 0 prints nothing
#           -- 1 prints simulation time and location
#           -- 2 prints simulation time, location, and statistics about
#           --   the memory and CPU times used in simulation
#           -- Other STATUS values are interpreted as 0.

if hdl_args.run:

    #Report Summary Directory:
    summaryPath=os.path.join(myPath, 'Reports')
    if (not os.path.isdir(summaryPath)):
        os.makedirs(summaryPath)

    #Timestamp Report Subfolder:
    myTime=datetime.datetime.now().isoformat('_').split('.')[0].replace(':','-')
    myReportPath=os.path.join(summaryPath, myTime);
    if (not os.path.isdir(myReportPath)):
        os.makedirs(myReportPath)
    else:
        print ('REPORT ERROR: Report Directory already exists.')
        quit()

    start_time = time.time()
    prev_time = start_time;
    # Put modelsim_regression_test_vhdl.log file in tool build dir
    build_main_dir, build_toolset_dir, build_tool_dir = msim.get_tool_build_dir('sim')
    logFileName='modelsim_regression_test_vhdl.log'
    logFileNamePath=os.path.join(myReportPath, logFileName)
    reportFileName='report.html'
    reportFileNamePath=os.path.join(myReportPath, reportFileName)
    summaryFileName='summary.html'
    summaryFileNamePath=os.path.join(summaryPath, summaryFileName)
    totalNofTb = 0           # total number of tb in regression test
    totalNofFailed = 0       # total number of tb in regression test that failed
    failList = ""

    # Open the log file and run the test bench do files
    with open(logFileNamePath, 'w') as fp:
        with open(reportFileNamePath, 'w') as rp:
            fp.write("# Created by modelsim_regression_test_vhdl.py using HDL library key 'regression_test_vhdl'\n")
            fp.write('# Tested HDL libraries: %s\n' % msim.get_lib_names_from_lib_dicts(test_dicts))
            fp.write('#\n')
            rp.write('<html>\n')
            rp.write('<head>\n<style>\ntd, th {padding: 3;}\ntable, th, td {border: 1px solid #CCCCCC; font-size:14px;}\ntd.grey {color: grey; font-size:10px;}\ntd.failed {color: red}\ntd.passed {color: green}\n</style>\n</head>\n')
            rp.write('<body><center>\n')
            rp.write('<h1>Regression Test - %s </h1>\n' % myTime)
            rp.write('<table border=1>\n<tr><th>LIB</th><th>MODULE</th><th>RESULT</th><th>OUTPUT</th></tr>\n')
            for lb, lib_dict in enumerate(cm.listify(test_dicts)):
                # Derive the do file names from the HDL library 'regression_test_vhdl' key
                lib_name = lib_dict['hdl_lib_name']
                fp.write('# %d: %s\n' % (lb, lib_name))
                nofTb = 0           # number of tb in regression test for this HDL library
                mpf_path = msim.get_lib_build_dirs('sim', lib_dicts=lib_dict)
                transcriptPathName = os.path.join(mpf_path, 'transcript')
                do_path = os.path.join(mpf_path, do_subdir)
                test_bench_files = lib_dict['regression_test_vhdl'].split()
                for tbf in test_bench_files:
                    tbf_name = os.path.basename(tbf)
                    tb_name = os.path.splitext(tbf_name)[0]
                    doName = tb_name + '.do'
                    doPathName = os.path.join(do_path, doName)
                    doLogName = lib_name + '.' + tb_name + '.log'
                    doLogPathName = os.path.join(myReportPath, doLogName)
                    stdout_name = os.path.join(lib_name+'.'+tb_name+'.'+'stdout.log')
                    stdout_path = os.path.join(myReportPath, stdout_name)


                    rp.write('<tr>')
                    rp.write('<td>%s</td>' % lib_name)
                    rp.write('<td><span title="%s">%s</span></td>' % (mpf_path, tb_name))

                    # Simulate the do file with Modelsim
                    if platform.system().lower() == "windows":
                         vsim_cmd = 'cd %s & run_modelsim.cmd %s %s > %s' % (mpf_path, hdl_args.toolset, doPathName, stdout_path)
                    else:
                         vsim_cmd = 'cd %s; vsim -c -do %s > %s' % (mpf_path, doPathName, stdout_path)

                    print(vsim_cmd)

                    call_status = subprocess.call(vsim_cmd, shell=True)
                    nofTb += 1
                    f=0

                    if call_status==0:
                        # Keep the transcript file in the library build directory
                        if platform.system().lower() == "windows":
                            subprocess.call("copy %s %s" % (transcriptPathName, doLogPathName), shell=True)
                        else:
                            subprocess.call("cp %s %s" % (transcriptPathName, doLogPathName), shell=True)
                        # Check that the library compiled and the simulation ran (use try-except to handle exit code > 0)
                        try:
                            if platform.system().lower() == "windows":
                                sim_end = subprocess.check_output("findstr /C:\">>> SIMULATION END\" %s" % transcriptPathName, shell=True)
                            else:
                                sim_end = subprocess.check_output("egrep '>>> SIMULATION END' %s" % transcriptPathName, shell=True)
                        except subprocess.CalledProcessError:
                            fp.write('Error occured while running vcom or -label for %s\n' % lib_name)
                            rp.write('<td class="failed">TB did not finish')
                            f=1
                        else:
                            # Log the simulation run time
                            fp.write('%s' % str(sim_end, 'utf-8'))
                            # Log the simulation Errors if they occured (use subprocess.call-subprocess.check_output to handle exit code > 0)

                            if platform.system().lower() == "windows":
                                grep_cmd = "findstr /V /C:\"Errors: 0,\" %s | findstr /V /C:\"Expected Error\" | findstr /C:\"Error\"" % transcriptPathName
                            else:
                                grep_cmd = "grep -v 'Errors: 0,' %s | grep -v 'Expected Error' | egrep 'Error'" % transcriptPathName

                            grep_status = subprocess.call(grep_cmd, shell=True)
                            if grep_status==0:
                                sim_msg = subprocess.check_output(grep_cmd, shell=True)
                                fp.write('\n\nERRORS and WARNINGS:\n' )
                                fp.write('%s\n' % str(sim_msg, 'utf-8'))
                                rp.write('<td class="failed"><span title="%s">assert: ERROR</span>' % str(sim_msg, 'utf-8'))
                                f=1
                            # Log the simulation Failures if they occured (use subprocess.call-subprocess.check_output to handle exit code > 0)

                            if platform.system().lower() == "windows":
                                grep_cmd = "findstr /V /C:\"Expected Error\" %s | findstr \"Failure\"" % transcriptPathName
                            else:
                                grep_cmd = "grep -v 'Expected Error' %s | egrep -A2 'Failure'" % transcriptPathName

                            grep_status = subprocess.call(grep_cmd, shell=True)
                            if grep_status==0:
                                if f==1:
                                    rp.write('<br/>')
                                else:
                                    rp.write('<td class="failed">')
                                fp.write('\nFAILURE MESSAGES:\n' )
                                sim_msg = subprocess.check_output(grep_cmd, shell=True)
                                fp.write('%s\n\n' % str(sim_msg, 'utf-8'))
                                rp.write('<span title="%s">assert: FAILURE</span>' % str(sim_msg, 'utf-8'))
                                f=1
                    else:
                        fp.write('> Error occured while calling: %s\n' % vsim_cmd)
                        rp.write('<td class="failed">VSIM did not run')
                        f=1
                    totalNofFailed += f

                    if f==1:
                        rp.write('</td>')
                        failList += lib_name + ": " + tb_name + "\n"
                    else:
                        rp.write('<td class="passed">PASSED</td>')
                    rp.write('<td><a href="./%s">stdout.log</a></td></tr>\n' % stdout_name)
                # Maintain count of total number of test benches
                totalNofTb += nofTb
                # Measure regression test time for this HDL library
                cur_time = time.time()
                run_time = cur_time-prev_time
                prev_time = cur_time;
                if nofTb==0:
                    rp.write('<tr><td class="grey">%s</td><td class="grey">---</td><td class="grey">no tb</td><td class="grey"></td></tr>\n' % lib_name)
                    fp.write('# HDL library %s has zero testbenches for regression test.\n' % lib_name)
                    fp.write('#\n')
                else:
                    fp.write('# Test duration for library %s: %.1f seconds\n' % (lib_name, run_time))
                    fp.write('#\n')

            fp.write('# Regression test summary:\n')

            end_time = time.time()
            run_time = end_time-start_time

            # Log overall PASSED or FAILED
            if totalNofTb==0:
                fp.write('# Email SUBJECT: FAILED because no VHDL test bench was simulated.\n')
                mySummaryLine = ('<tr><td><a href="%s">%s</a></td><td>%s</td><td class="failed">NO TEST RUN</td><td><a href="%s">%s</a></td></tr>\n' % (os.path.join(myTime, reportFileName), myTime, datetime.timedelta(seconds=run_time), os.path.join(myTime, logFileName), logFileName))
            elif totalNofFailed==0:
                fp.write('# Email SUBJECT: All %d VHDL test benches PASSED\n' % totalNofTb)
                mySummaryLine = ('<tr><td><a href="%s">%s</a></td><td>%s</td><td class="passed">%d PASSED</td><td><a href="%s">%s</a></td></tr>\n' % (os.path.join(myTime, reportFileName), myTime, datetime.timedelta(seconds=run_time), totalNofTb, os.path.join(myTime, logFileName), logFileName))
            else:
                fp.write('# Email SUBJECT: Out of %d VHDL test benches %d FAILED\n' % (totalNofTb, totalNofFailed))
                mySummaryLine = ('<tr><td><a href="%s">%s</a></td><td>%s</td><td class="failed"><span title="%s">%d / %d FAILED</span></td><td><a href="%s">%s</a></td></tr>\n' % (os.path.join(myTime, reportFileName), myTime, datetime.timedelta(seconds=run_time), failList, totalNofFailed, totalNofTb, os.path.join(myTime, logFileName), logFileName))

            rp.write('</table>\n')
            rp.write('</center>\n</body>\n</html>\n\n\n')

            # Log total test time
            fp.write('# Email MESSAGE: Total regression test duration in days,h:m:s = %s\n' % datetime.timedelta(seconds=run_time))
            fp.write('# Email LOG: %s\n' % logFileNamePath)


            #Summary HTML
            try:
                sp = open(summaryFileNamePath, 'r')
                #Summary HTML exists: read file, delete old lines, insert new line
                summaryFileContent=sp.readlines()
                sp.close()

                #Delete old lines & related directories:
                compareTime=(datetime.datetime.now() - datetime.timedelta(days=7)).isoformat('_').split('.')[0]
                summaryFileContent2=summaryFileContent.copy()
                kd=0
                pa=0
                for line in summaryFileContent:
                    if line.split('<a')[0] == "<tr><td>":
                        kd=0
                        lineDate = line.split('>')[3].split('<')[0]
                        #Only delete old directories if there was a passing test that came chronologically after this one
                        if (pa==1) and (lineDate < compareTime):
                            print ("To delete: %s" % lineDate)
                            summaryFileContent2.remove(line)
                            kd=1
                            shutil.rmtree(os.path.join(summaryPath, lineDate))
                        else:
                            print ("To keep: %s" % lineDate)
                    elif line=="</table>\n":
                        kd=0
                        break
                    elif kd==1:
                        #keep deleting lines until next table row starts
                        summaryFileContent2.remove(line)
                    if 'PASSED' in line:
                        pa=1

                #Insert new line at the top of the table:
                summaryFileContent2.insert(14, mySummaryLine)

                #Write file:
                sp = open(summaryFileNamePath, 'w')
                summaryFileContent2 = "".join(summaryFileContent2)
                sp.write(summaryFileContent2)
                sp.close()

            except IOError:
                #Summary HTML does not exist: create new one
                with open(summaryFileNamePath, 'w') as sp:
                    sp.write('<html>\n')
                    sp.write('<head>\n<style>\ntd, th {padding: 5;}\ntable, th, td {border: 1px solid #CCCCCC; font-size:14px;}\ntd.grey {color: grey; font-size:10px;}\ntd.failed {color: red}\ntd.passed {color: green}\n</style>\n</head>\n')
                    sp.write('<body><center>\n')
                    sp.write('<h1>Regression Test Summary</h1>\n')
                    sp.write('<table border=1>\n<tr><th>DATE</th><th>TEST DURATION</th><th>RESULT</th><th>LOGFILE</th></tr>\n')
                    sp.write(mySummaryLine)
                    sp.write('</table>\n')
                    sp.write('</center>\n</body>\n</html>\n\n\n')

    # Echo the log file
    if platform.system().lower() != "windows":
        print ('\n\ncat %s:\n' % logFileNamePath)
        subprocess.call('cat %s' % logFileNamePath, shell=True)

    print ('\n')
