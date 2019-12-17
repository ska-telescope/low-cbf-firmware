Contents:

1) Introduction

2) Tool environment setup
  a) ~/.bashrc
  b) Python environment setup
  c) Tool environment setup scripts
  d) Compiling the Altera libraries for simulation with Modelsim
  e) Quartus user_components.ipx
  f) Generate IP
  g) Tool start scripts
  h) How to start Modelsim for RadioHDL
  i) How to start Quartus for RadioHDL
  j) How to start Modelsim for UNB
  k) How to start Quartus for UNB
  l) UniBoard2 device family
  m) Upgrading the IP for new version of Quartus or for another device family
  n) How to use RadioHDL for CSP.Low
  o) How to use Modelsim for RadioHDL on Windows
  
3) HDL environment configuration files
  a) Tools and libraries
  b) Target configuration scripts
  c) hdltool_<toolset>.cfg key sections
  d) hdltool_<toolset>.cfg key descriptions
  e) hdllib.cfg key sections
  f) hdllib.cfg key descriptions 
  
4) Porting from $UNB to $RADIOHDL
  a) History
  b) Use SVN-copy
  c) Replace SOPC avs2_eth_coe instance

5) Build directory location

6) Compilation and simulation in Modelsim
  a) Creating the Modelsim project files
  b) Compilation
  c) Simulation
  
7) Synthesis in Quartus
  a) Creating the Quartus project files

8) Design revisions

9) RadioHDL directory structure
  a) applications
  b) boards
  c) libraries
  d) software
  e) tools  

100) To do
101) More ideas
102) Know errors




1) Introduction 

This readme file describes the practical realisation of the prestudy ideas for the RadioHDL directory tree
for the UniBoard2 development, as was described in:

  $RADIOHDL/tools/oneclick/prestudy/ASTRON_SP_057_RadioHDL_Firmware_Directory_Structure.pdf

The big difference between the RadioHDL environment and the old style UNB environment is that RadioHDL uses configuration files to setup the
tools and the libraries. From these configuration files the tool specific project files like mpf for Modelsim and qpf for Quartus are created
using Python scripts. In the old style UNB environment the tool project files need to be created and managed manually.

   
2) Tool environment setup

a) ~/.bashrc

To setup the RadioHDL environment add this to the .bashrc:

    # Python
    PATH=${PATH}:/usr/local/anaconda/bin
    
    # SVN checkout root directory
    export SVN=${HOME}/svnroot/UniBoard_FP7

    # define SITE env variable for laboratory specific software tool versions (USN, )
    # Used in ${RADIOHDL}/tools/quartus/set_quartus and ${RADIOHDL}/tools/modelsim/set_modelsim
    export SITE=

    # If necessary create a symbolic link to the actual Altera root directory (used in quartus_version.sh for Quartus)
    ln -s <Altera root directory> /home/software/Altera 
  
    # If necessary create a symbolic link to the actual Mentor root directory (used in modelsim_version.sh for Modelsim)
    ln -s <Mentor root directory> /home/software/Mentor
    
    # Altera + ModelSim licences
    export LM_LICENSE_FILE=1800@LICENSE2.astron.nl:1717@LICENSE1.astron.nl

    # Setup RadioHDL environment for UniBoard2 and new UniBoard1 applications
    . ${SVN}/RadioHDL/trunk/tools/setup_radiohdl.sh
    
In case of running the non-RadioHDL UniBoard environment: UNB, AARTFAAC or PAASAR add this to ~/.bashrc as well:

    # Support old UniBoard environment (including Aartfaac and Paasar)
    . ${SVN}/RadioHDL/trunk/tools/setup_unb.sh
    


b) Python environment setup

For Python the Anaconda distribution is used, because it combine the appropriate versions of the various packages.
On dop233 python is used from:

  /usr/local/anaconda/bin/python

This installation directory is must be added to the search PATH in the .bashrc. The setup_radiohdl.sh defines the PYTHONPATH to the
UniBoard and RadioHDL python files that we use.


c) Tool environment setup scripts

The settings for the RadioHDL environment and the old style UniBoard development are kept in environment setup scripts that
gets sourced in the ~/.bashrc:

  - $RADIOHDL/tools/setup_radiohdl.sh   # always needed to source in .bashrc (see 2a)
  - $RADIOHDL/tools/setup_unb.sh        # only needed to source in .bashrc if old style UniBoard 1 development in $UNB, $PAASAR and $AARTFAAC is required (see 2a)
  
The .bashrc settings apply to the terminal that is opened. The adavantage of using an environment setup script instead of
direct definition in the .bashrc are:

  - the environment setup script can be kept in SVN
  - it makes it easier to ensure that all users apply the same RadioHDL environment settings, because all source the same environment setup script
  - it avoids that the .bashrc gets cluttered with various definitions

Some environment variables need to be set in the .bashrc, because they are not kept the setup script in SVN:
  
  - The $SVN environment variable with the path to the SVN checkout directory, because it is user specific.
  - The $LM_LICENSE_FILE environment variable, because it is site specific.
  - The $PATH to the python installation directory, because it is machine specific and may also be used for other projects. 
  
The toolset defines which comination of Modelsim and Quartus tools is used. Currently there are:

  - toolset 'unb1' --> use to compile for StratixIV and UniBoard1
  - toolset 'unb2' --> use to compile for Arria10 and UniBoard2
  - toolset 'unb2a' --> use to compile for Arria10 ES3 and UniBoard2a
  - toolset 'vcu108' --> use to compile with Xilinx/Vivado on an xcvu095 technology for the VCU108 eval board
  - toolset 'vcu110' --> use to compile with Xilinx/Vivado on an xcvu190 technology for the VCU110 eval board
  - toolset 'gmi'    --> use to compile with Xilinx/Vivado on an xcvu9p technology for the Gemini board

The tool versions that belong to these toolsets are defined in:

   ${RADIOHDL}/tools/quartus/set_quartus
   ${RADIOHDL}/tools/modelsim/set_modelsim
   ${RADIOHDL}/tools/vivado/set_vivado

  
d) Compiling the Altera libraries for simulation with Modelsim

The Altera verilog and vhdl libraries for the required FPGA device families can be compiled using:

 > ${RADIOHDL}/tools/quartus/run_altera_simlib_comp <tool target> <compilation output directory> <FPGA device family>
 
For Modelsim versions newer than about version 10 this run_altera_simlib_comp script must be used and not the tools/Launch simulation library compiler in the Quartus GUI, because
the libraries have to be compiled with the 'vlib -type directory' option to be able to use 'mk all'. 
The run_altera_simlib_comp uses set_modelsim and set_quartus to make the tool settings for Modelsim and Quartus. For more info also see the description in run_altera_simlib_comp.

For example:

 > cd ${RADIOHDL}/tools/quartus/
 
 # For toolset 'unb1' with only stratixiv the libraries can be compiled with the GUI (because 'unb1' uses Modelsim 6.6.c < 10) or one may use:
 > run_altera_simlib_comp unb1 11.1 stratixiv

 # For toolset 'unb2' with arria10 and also support for stratixiv
 > run_altera_simlib_comp unb2 15.0 stratixiv
 > run_altera_simlib_comp unb2 15.0 arria10

Note that the second argument of the Quartus version is used as OUTPUT_DIR and must match the toolset.

Then use 'sudo' to move the directory to the protected central project directory that is set by $MODEL_TECH_ALTERA_LIB.

 > sudo mv 15.0 /home/software/modelsim_altera_libs


e) Quartus user_components.ipx

The user_components.ipx tells QSYS and SOPC where to search for MM components. The user_components.ipx is kept in SVN at:

  https://svn.astron.nl/UniBoard_FP7/UniBoard/trunk/Firmware/synth/quartus/user_components.ipx

In a Unix system this goes to the personal folder at ~ (= $HOME):

  ~/.altera.quartus/ip/15.0/ip_search_path/user_components.ipx
  
It appears that copying the user_components.ipx from SVN location to the personal ~ location avoids having to copy it into the installation location. The
version part of the directory name needs to match the Quartus version (eg. 11.1sp2, 14.1, 15.0). The ${RADIOHDL}/tools/quartus/check_ipx_content bash script
checks that the paths in the ipx file are oke. The check_ipx_content is called in the set_quartus bash script that is called in run_quartus.

Alternatively the user_components.ipx can be copied to the Quartus installation directory, given by $QUARTUS_DIR that is defined in quartus_version.sh, at:

  /ip/altera/user_components.ipx



f) Generate IP

The IP needs to be generated before it can be simulated or synthesized. The Quartus IP is generated using Qsys or the Megawizard.
Initialy the GUI was used to create and generate the IP, but once it works and is stable then the IP can be generated uisng a script.
Therefore each library with IP has a dedicated generate_ip.sh, for example:

  > cd $RADIOHDL/libraries/technology/ip_stratixiv/mac_10g
  > ./generate_ip.sh
 
The IP for all libraries of a certain FPGA technology can also be generated automatically in one command using:
  
  # ip_stratixiv 
  > cd $RADIOHDL/libraries/technology/ip_stratixiv
  > ./generate-all-ip.sh

  # ip_arria10
  > cd $RADIOHDL/libraries/technology/ip_arria10
  > ./generate-all-ip.sh
  


g) Tool start scripts

The definitions for actually running Modelsim and Quartus are not kept in the ~/.bashrc file or the setup script but are
set in a tool start script:

  $RADIOHDL/tools/modelsim/run_modelsim      # calls set_modelsim and starts the Modelsim GUI for simulation
  $RADIOHDL/tools/quartus/run_quartus        # calls set_quartus and starts the Quartus GUI for synthesis

The paths to these tool start scripts are defined in setup_radiohdl.sh. In addition to the advantages mentioned above for the environment setup scripts,
the advantages of using a seperate tool start script is:

  - different versions of the tool can be started in parallel on the same machine, because the tool start script settings
    only apply to the started tool environment


h) How to start Modelsim for RadioHDL

To start Modelsim for RadioHDL do:

  > run_modelsim unb1 &
  
This starts Modelsim 6.6c using Quartus 11.1 libraries for Stratix IV and with extra commands from ${RADIOHDL}/tools/modelsim/commands.do
To start Modelsim 10.4 using Quartus 14.1 libraries for Arria10 as needed for UniBoard2 do:

  > run_modelsim unb2 &
  
To make the tool version dependent settings the run_modelsim script calls:

  $RADIOHDL/tools/quartus/quartus_version.sh     # for path to the FPGA technology HDL simulation libraries
  $RADIOHDL/tools/modelsim/modelsim_version.sh   # for path to the vsim simulator

To enable other Modelsimtool versions, edit the script $RADIOHDL/tools/modelsim/set_modelsim
Now only the toolsets 'unb1' and 'unb2' are defined

The commands.do defines the following extra commands that can be used at the Modelsim prompt:

  . lp <name> : load HDL library <name>.mpf project
  . mk <name> : make one or range of HDL library mpf projects
  . as #      : add signals for # levels of hierarchy to the wave window (use 'asf #' for flat list of signals)
  . ds        : delete all signals from the wave window
  
  
i) How to start Quartus for RadioHDL

To start Quartus for RadioHDL do:

  > run_quartus unb1 &
  
This starts Quartus 11.1 for Stratix IV. To start Quartus 14.1 for Arria10 as needed for UniBoard2 do:

  > run_quartus unb2 &
  
To make the tool version dependent settings and the generic settings the run_quartus script calls:

  $RADIOHDL/tools/quartus/quartus_version.sh   # for path to the quartus sythesis tool
  $RADIOHDL/tools/quartus/quartus_generic.sh   # version independent paths and settings for Quartus, SOPC, Nios

To enable other Quartus tool versions, edit the script $RADIOHDL/tools/quartus/set_quartus
Now only the toolsets 'unb1' and 'unb2' are defined
  
The Quartus unb_* bash commands for $UNB have also been ported to $RADIOHDL. They use quartus 11.1 so they only support Stratix IV and UniBoard1.
For Arria10 and UniBoard2 these commands will have to be ported to an equivalent in Python. The following Quartus run_* bash commands are kept in
$RADIOHDL/tools/quartus. These run_* bash commands can be used in $RADIOHDL. The run_* bash commands assume that the design library
projects are in the central $HDL_BUILD_DIR = $RADIOHDL/build:

For building a SOPC system use:
  > run_sopc      unb1 unb1_minimal_sopc
  > run_app       unb1 unb1_minimal_sopc             # calls: run_bsp, run_reg, run_mif
  > run_app_clean unb1 unb1_minimal_sopc app=unb_osy
  > run_qcomp     unb1 unb1_minimal_sopc
  > run_all_sopc  unb1 unb1_minimal_sopc             # sequentially running: run_sopc + run_app + run_qcomp
  > run_rbf       unb1 unb1_minimal_sopc
  > run_sof       unb1 unb1_minimal_sopc 0
  
For building a QSYS system use:
  > run_qsys      unb1 unb1_minimal_qsys
  > run_sopc      unb1 unb1_minimal_sopc     # (normally not needed but the unb1_minimal_qsys revision has a GENERATE sopc-OR-qsys section)
  > run_app       unb1 unb1_minimal_qsys use=qsys
  > run_qcomp     unb1 unb1_minimal_qsys
  > run_all_qsys  unb1 unb1_minimal_qsys     # sequentially running: run_qsys + run_app + run_qcomp
  > run_rbf       unb1 unb1_minimal_qsys
  > run_sof       unb1 unb1_minimal_qsys 0


j) How to start Modelsim for UNB

GUI:

  > unb_msim &        # for UNB
  > aaf_msim &        # for AARTFAAC
  > paasar_msim &     # for PAASAR

See the setup_unb.sh environment script and ASTRON_RP_1354_unb_minimal.pdf for more description.


k) How to start Quartus for UNB

GUI:

  > quartus --64bit &   # The UNB settings have been made in setup_unb.sh, so direct calling the 11.1 executable is fine
  
  or
  
  > run_quartus unb1 &  # Makes the UNB settings again and calls the 11.1 executable
  
For command line scripts use the unb_* scripts. See ASTRON_RP_1354_unb_minimal.pdf for more description.


l) UniBoard2 device family

The device family of the Arria10 on UniBoard2 v0 is 10AX115U4F45I3SGES as can be seen at the photo of the FPGA:

    $RADIOHDL/boards/uniboard2/libraries/unb2_board/quartus/unb2_board_v0_device_family.JPG

The device family is used in:
- $RADIOHDL/boards/uniboard2/libraries/unb2_board/quartus/unb2_board.qsf
- QSYS IP component files
- QSYS system design file


m) Upgrading the IP for new version of Quartus or for another device family

On 20 May 2015 Eric manually upgraded all current Arria10 IP to Quartus 15.0 and used the Qsys GUI menu view->device family to set the FPGA that is on UniBoard2 v0. 
These are the current Qsys IP components for ip_arria10:

    kooistra@dop233 ip_arria10 $ svn status -q
    M       ddio/ip_arria10_ddio_in_1.qsys
    M       ddio/ip_arria10_ddio_out_1.qsys
    M       ddr4_4g_1600/ip_arria10_ddr4_4g_1600.qsys
    M       ddr4_8g_2400/ip_arria10_ddr4_8g_2400.qsys
    M       fifo/ip_arria10_fifo_dc.qsys
    M       fifo/ip_arria10_fifo_dc_mixed_widths.qsys
    M       fifo/ip_arria10_fifo_sc.qsys
    M       flash/asmi_parallel/ip_arria10_asmi_parallel.qsys
    M       flash/remote_update/ip_arria10_remote_update.qsys
    M       mac_10g/ip_arria10_mac_10g.qsys
    M       phy_10gbase_r/ip_arria10_phy_10gbase_r.qsys
    M       phy_10gbase_r_24/ip_arria10_phy_10gbase_r_24.qsys
    M       pll_clk125/ip_arria10_pll_clk125.qsys
    M       pll_clk200/ip_arria10_pll_clk200.qsys
    M       pll_clk25/ip_arria10_pll_clk25.qsys
    M       pll_xgmii_mac_clocks/ip_arria10_pll_xgmii_mac_clocks.qsys
    M       pll_xgmii_mac_clocks/pll_xgmii_mac_clocks.qsys
    M       ram/ip_arria10_ram_cr_cw.qsys
    M       ram/ip_arria10_ram_crw_crw.qsys
    M       ram/ip_arria10_ram_crwk_crw.qsys
    M       ram/ip_arria10_ram_r_w.qsys
    M       transceiver_phy_1/transceiver_phy_1.qsys
    M       transceiver_phy_48/transceiver_phy_48.qsys
    M       transceiver_pll/transceiver_pll.qsys
    M       transceiver_pll_10g/ip_arria10_transceiver_pll_10g.qsys
    M       transceiver_reset_controller_1/ip_arria10_transceiver_reset_controller_1.qsys
    M       transceiver_reset_controller_1/transceiver_reset_controller_1.qsys
    M       transceiver_reset_controller_24/ip_arria10_transceiver_reset_controller_24.qsys
    M       transceiver_reset_controller_48/ip_arria10_transceiver_reset_controller_48.qsys
    M       transceiver_reset_controller_48/transceiver_reset_controller_48.qsys
    M       tse_sgmii_gx/ip_arria10_tse_sgmii_gx.qsys
    M       tse_sgmii_lvds/ip_arria10_tse_sgmii_lvds.qsys

In addition several other files need to be modified to be able to simulate the IP:

    - the tech_*.vhd files that instantiate the IP component need to have the LIBRARY clause for binding
    - the compile_ip.tcl files need to be updated according to the generated/sim/mentor/msim_setup.tcl
      because the IP library name and file names may have changed
    . the copy_hex_files.tcl files need to be updated 
    . the IP library name in the hdllib.cfg of the IP needs to be changed

This concerned these files:

    kooistra@dop233 trunk $ svn status -q
    M       libraries/technology/10gbase_r/tech_10gbase_r_arria10.vhd
    M       libraries/technology/ddr/tech_ddr_arria10.vhd
    M       libraries/technology/flash/tech_flash_asmi_parallel.vhd
    M       libraries/technology/flash/tech_flash_remote_update.vhd
    M       libraries/technology/ip_arria10/ddio/compile_ip.tcl
    M       libraries/technology/ip_arria10/ddr4_4g_1600/compile_ip.tcl
    M       libraries/technology/ip_arria10/ddr4_4g_1600/copy_hex_files.tcl
    M       libraries/technology/ip_arria10/ddr4_4g_1600/hdllib.cfg
    M       libraries/technology/ip_arria10/ddr4_8g_2400/compile_ip.tcl
    M       libraries/technology/ip_arria10/ddr4_8g_2400/copy_hex_files.tcl
    M       libraries/technology/ip_arria10/ddr4_8g_2400/hdllib.cfg
    M       libraries/technology/ip_arria10/flash/asmi_parallel/compile_ip.tcl
    M       libraries/technology/ip_arria10/flash/asmi_parallel/hdllib.cfg
    M       libraries/technology/ip_arria10/flash/remote_update/compile_ip.tcl
    M       libraries/technology/ip_arria10/flash/remote_update/hdllib.cfg
    M       libraries/technology/ip_arria10/mac_10g/compile_ip.tcl
    M       libraries/technology/ip_arria10/mac_10g/hdllib.cfg
    M       libraries/technology/ip_arria10/phy_10gbase_r/compile_ip.tcl
    M       libraries/technology/ip_arria10/phy_10gbase_r/hdllib.cfg
    M       libraries/technology/ip_arria10/phy_10gbase_r_24/compile_ip.tcl
    M       libraries/technology/ip_arria10/phy_10gbase_r_24/hdllib.cfg
    M       libraries/technology/ip_arria10/pll_clk125/compile_ip.tcl
    M       libraries/technology/ip_arria10/pll_clk125/hdllib.cfg
    M       libraries/technology/ip_arria10/pll_clk200/compile_ip.tcl
    M       libraries/technology/ip_arria10/pll_clk200/hdllib.cfg
    M       libraries/technology/ip_arria10/pll_clk25/compile_ip.tcl
    M       libraries/technology/ip_arria10/pll_clk25/hdllib.cfg
    M       libraries/technology/ip_arria10/pll_xgmii_mac_clocks/compile_ip.tcl
    M       libraries/technology/ip_arria10/pll_xgmii_mac_clocks/hdllib.cfg
    M       libraries/technology/ip_arria10/transceiver_pll_10g/compile_ip.tcl
    M       libraries/technology/ip_arria10/transceiver_pll_10g/hdllib.cfg
    M       libraries/technology/ip_arria10/transceiver_reset_controller_1/compile_ip.tcl
    M       libraries/technology/ip_arria10/transceiver_reset_controller_1/hdllib.cfg
    M       libraries/technology/ip_arria10/transceiver_reset_controller_24/compile_ip.tcl
    M       libraries/technology/ip_arria10/transceiver_reset_controller_24/hdllib.cfg
    M       libraries/technology/ip_arria10/tse_sgmii_gx/compile_ip.tcl
    M       libraries/technology/ip_arria10/tse_sgmii_gx/hdllib.cfg
    M       libraries/technology/ip_arria10/tse_sgmii_lvds/compile_ip.tcl
    M       libraries/technology/ip_arria10/tse_sgmii_lvds/hdllib.cfg
    M       libraries/technology/mac_10g/tech_mac_10g_arria10.vhd
    M       libraries/technology/pll/tech_pll_clk125.vhd
    M       libraries/technology/pll/tech_pll_clk200.vhd
    M       libraries/technology/pll/tech_pll_clk25.vhd
    M       libraries/technology/pll/tech_pll_xgmii_mac_clocks.vhd
    M       libraries/technology/technology_select_pkg.vhd
    M       libraries/technology/tse/tech_tse_arria10.vhd
    
Then run generate-all-ip.sh and try to simulate the test benches that verify the IP:

  - tb_eth
  - tb_tr_10GbE
  - tb_io_ddr
  
and the try to simulate a design, eg.:

  - unb2_minimal
  
n) How to use RadioHDL for CSP.Low
* The CSP.Low firmware is kept in a separate SVN repository at:

    svn://codehostingbt.aut.ac.nz/svn/LOWCBF/Firmware

  In ~/.bashrc make a selection choice which can be made at each login. 
  This will select the SVN tree for LOWCBF or UNB:


    echo -n "UNB='1' (default) or LOWCBF='2': "
    read choice
    case ${choice} in
      2)
        echo "LOWCBF is selected"
        export SVN=${HOME}/svnlowcbf/LOWCBF
        . ${SVN}/Firmware/tools/bin/setup_radiohdl.sh
        work="LOWCBF"
        ;;
      *)
        echo "UNB is selected"
        export SVN=${HOME}/svn/UniBoard_FP7
        # Setup RadioHDL environment for UniBoard2 and and new Uniboard1 applications
        . ${SVN}/RadioHDL/trunk/tools/setup_radiohdl.sh
        work="UNB"
        ;;
    esac


* To compile the Vivado 2016.4 models with Modelsim 10.4 under linux do:

  Make a destination directory for the compiled libraries for modelsim:

  cd /home/software
  sudo mkdir -p modelsim_xilinx_libs/vivado/2016.4
  sudo chmod o+w -R modelsim_xilinx_libs

  Now start Vivado 2016.4 GUI
  In top menu select: Tools->Compile Simulation Libraries
    Simulator: ModelSim (or Questa Advanced Simulator)
    Language:  All
    Library:   All
    Family:    Virtex UltraScale+ FPGAs
    Compiled library location: /home/software/modelsim_xilinx_libs/vivado/2016.4
    Simulator executable path: /home/software/Mentor/10.4/modeltech/linux_x86_64
    Check "Overwrite"
    Uncheck "32 bit"
    Check "verbose"

  After compilation is done a modelsim.ini file is written in /home/software/modelsim_xilinx_libs/vivado/2016.4
  Now create a file: $RADIOHDL/tools/vivado/hdl_libraries_ip_xcvu9p.txt   (for Gemini)
  and paste the modelsim.ini file in here. Edit then to keep only the needed libraries. For example:

    unisim = /home/software/modelsim_xilinx_libs/vivado/2016.4/unisim

  In this way the global modelsim.ini does not need to be editted

* Create tools/hdltool_gmi.cfg HDL tool configuration dictionary file for toolset 'gmi'
  Put the entries (without paths) after the key "modelsim_search_libraries". For example:

    modelsim_search_libraries =
      unisims_ver
      axi_interconnect_v1_7_12
      unisim

  Note: do not put too many libraries in here, Otherwise Modelsim truncates the lines in the .mpf files

* Add 'gmi' toolset for Modelsim to tools/modelsim/set_modelsim.

* To start the Modelsim GUI do:
  > run_modelsim gmi &

* To start the Vivado GUI do:
  > run_vivado gmi &


o) How to use Modelsim for RadioHDL on Windows

It is possible to use Modelsim on Windows OS. Here are the steps to prepare the Modelsim project files in the
build directory:
- Download and install Python 2.7 for Windows (www.python.org/downloads). Default install location is C:\Python27
- In Windows, go to Settings -> Environment Variables
- Add C:\Python27 to PATH
- Also add the following environment variables:
  set RADIOHDL=G:\svn\LOWCBF\Firmware
  set HDL_BUILD_DIR=%RADIOHDL%\build
  set MODEL_TECH_XILINX_LIB=C:\modelsim_xilinx_libs

  # The toolset must be set, for example the kcu105 eval board, set this environment variable:
  set TOOLSET=kcu105  

  Notes: . In this example the SVN is located on a Samba share, mounted as drive G:
         . The modelsim_xilinx_libs are compiled with Vivado on Windows
  
Now it is possible to generate the Modelsim project files in the build directory. Open a CMD terminal and do:
  G:
  cd svn\LOWCBF\Firmware\tools\radiohdl\base
  python modelsim_config.py -t kcu105

In case you want to use the macros in $RADIOHDL/tools/modelsim/commands.do :
Change the Modelsim Shortcut icon on the desktop (rightclick->properties)
- Change "Target" to: C:\modeltech_pe_10.6b\win32pe\modelsim.exe -do $RADIOHDL/tools/modelsim/commands.do
- Change "Start in" to: G:\svn\LOWCBF\Firmware\build

Start the Modelsim Simulator and you are ready to simulate the projects in the build directory:
lp common
mk clean all
mk all
--> see modelsim Section: 2(h)

  
3) HDL environment configuration files

a) Tools and libraries

The HDL environment consists of tools and libraries. The HDL environment is defined in configuration files.

- hdltool<toolset>.cfg : HDL tool configuration dictionary file. One central file per toolset.
- hdllib.cfg           : HDL library configuration dictionary file. One file for each HDL library.

The HDL libraries can define a module library with VHDL that is reused in other libraries or a design library
with a top level entity that maps on the IO of the FPGA. For the hdllib.cfg there is no difference between
a module library or a design library, they are all HDL libraries.

The hdllib.cfg typically points to sources that are located in the same directory or in its subdirectories.
However the sources can be located elsewhere, the hdllib.cfg can refer to sources at any location.

b) Target configuration scripts

The configuration files define how the tools should build the libraries to create the targets. The target can be:

  t1. compile to created the library binaries for simulation
  t2. synthesize to created an image that can be loaded ion the FPGA
  t3. verify VHDL test benches in simulation
  t4. verify Python test cases via the MM control interface in simulation
  t5. validate Python test cases on hardware via the MM control interface
  t6. bundle and zip all sources necessary for a library, e.g. to export a design
  
The configuration files are interpreted by Python scripts in $RADIOHDL/tools/oneclick/base:

  - common_dict_file.py - read and modify a dictionary file
  - hdl_config.py       - get tool dictionary info, all HDL library dictionary infos and the target technology name

The hdllib_config.py can also run standalone to manipulate cfg files, eg. to insert, remove or rename keys.

These general dictionary file and HDL configuration file handling scripts are used by the HDL library target scripts:

  - modelsim_config.py                - for target t1)
  - quartus_config.py                 - for target t2)
  - modelsim_regression_test_vhdl.py  - for target t3)

For the other targets there are no scripts yet.

See also the docstring help text in the Python code:

  > python  
  >> import common_dict_file.py
  >> import hdl_config.py
  >> import modelsim_config.py
  >> import quartus_config.py
  >> help(common_dict_file.py)
  >> help(hdl_config.py)
  >> help(modelsim_config.py)
  >> help(quartus_config.py)


c) hdltool_<toolset>.cfg key sections

The hdltool_<toolset>.cfg has no key sections yet. Hence all toolset keys are visible to target scripts.


d) hdltool_<toolset>.cfg key descriptions

- lib_root_dir =
    Root directory from where all HDL library configuration files (hdllib.cfg) are searched
    
- build_dir =
    Global root path (e.g. $HDL_BUILD_DIR) to the build directory for simulation. The path gets extended with the
    tool_name_<build_type> from hdltool_<toolset>.cfg.

- tool_name_sim =
    Used as directory name in the build directory, e.g. modelsim.
  
- tool_name_synth =
    Used as directory name in the build directory, e.g. quartus.
    
- model_tech_dir =
    Used to get the location of the modelsim.ini file, e.g. /home/software/Mentor/modeltech. The modelsim.ini needs
    to be included in the mpf, because without the IEEE and STD libraries are not known anymore after the mpf is loaded.
  
- modelsim_search_libraries =
    List of IP technology search libraries that will be put in the -L {} option of a Modelsim simulation configuration in the mpf. This avoids that all
    IP technology needs to be compiled into the work library. The -L {} option is needed for simulations in libraries that use generated IP like
    ip_stratixiv_phy_xaui which do not recognize the IP technology libraries mapping in [libraries] section in the mpf. The -L {} option is added to
    all simulation configurations in all mpf even if they do not need it, which is fine because it does not harm and avoids the need for having to
    decide whether to include it or not per individual library or even per individual simulation configuration.

- technology_names =
    The technology_names key lists the IP technologies that are supported within this toolset, eg. ip_stratixiv, ip_arria10.
    It is possible to define multiple technologies. As long as Modelsim supports these technolgies (ie the technology
    libraries are available in Modelsim) then unused technologies are not disturbing and then they also do not cause
    simulation load errors with the 'modelsim_search_libraries' key. The HDL libraries with a hdl_lib_technology key value that
    is not in the list of technology_names will not be in the build.


e) hdllib.cfg key sections

The hdllib.cfg can be devided into sections to group the keys that are used for a specific target. The sections headers are
identified between [section_name] like in a ini file. The first part of the hdllib.cfg has no section header is these 
keys are available for all target scripts. The keys within in a section are only available for the target script that 
has selected the section_name in its libFileSections list. The libFileSections argument is a list because it is allowed for a target
script to use keys from more than one section.

   hdllib.cfg section name      target script
  [modelsim_project_file]   --> modelsim_config.py (with libFileSections=['modelsim_project_file'])
  [quartus_project_file]    --> quartus_config.py (with libFileSections=['quartus_project_file'])

Future target scripts will have their own [section name] header in the hdllib.cfg. In this way the hdllib.cfg remains more organised and the
keys per target are independ.


f) hdllib.cfg key descriptions 

- hdl_lib_name =
    The name of the HDL library, e.g. common, dp, unb1_minimal.

- hdl_library_clause_name =
    'The name of the HDL library as it is used in the VHDL LIBRARY clause, e.g. common_lib, dp_lib, unb1_minimal_lib.

- hdl_lib_uses_synth =
    See also the other 'hdl_lib_include_*' descriptions.
    List of HDL library names that are used in this HDL library for the 'synth_files', only the libraries that appear in
    VHDL LIBRARY clauses need to be mentioned, all lower level libraries are found automatically. The following libraries
    have to be declared at the 'hdl_lib_uses_synth' key:
    - Libraries with packages that are used
    - Library components that are instantiated as entities
    Libraries that are instantiated as components can be specified at the 'hdl_lib_uses_synth' key, but instead it may also be
    specified at the 'hdl_lib_uses_ip' key. If there are different source variants of the component and if these source lirbaries
    can be missing in the 'lib_root_dir' tree, then the library must be specified at the 'hdl_lib_uses_ip' key.
    
- hdl_lib_uses_ip =
    See also the other 'hdl_lib_include_*' descriptions.
    The 'hdl_lib_uses_ip' typically defines IP libraries that have multiple variants even within a specific technology (as specified
    by toolset key 'technology_names'). However typically only one tech variant of the IP is used in a design. The
    'hdl_lib_include_ip' key therefore defines the library that must be included in the list of library dependencies that are derived
    from 'hdl_lib_uses_ip'. Hence the 'hdl_lib_uses_ip' key defines the multiple choice IP libraries that are available in this
    library and the 'hdl_lib_include_ip' select which one (or more) are used by a higher level component (design). For tech libraries
    with only one IP library variant the IP libraries should be listed at the 'hdl_lib_uses_synth' key or at both the
    'hdl_lib_uses_ip' and 'hdl_lib_include_ip' key. If a multiple choice IP library can be included always, then it may also be
    specified at the 'hdl_lib_uses_synth'.
    Typically present, but unused IP is no problem. However for synthesis the constraint files of unused IP can cause problems.
    Therefore then use 'hdl_lib_include_ip' to only include this IP library from the IP variants in 'hdl_lib_uses_ip'. An 
    example is to only include ip_stratixiv_ddr3_uphy_4g_800_master in unb1_ddr3 / io_ddr / tech_ddr by setting hdl_lib_include_ip
    = ip_stratixiv_ddr3_uphy_4g_800_master in the hdllib.cfg of unb1_ddr3. Another example is ip_stratixiv_tse_sgmii_lvds for
    tech_tse which is included by the board specific library unb1_board to avoid that the other ip_stratixiv_tse_sgmii_gx variant
    is also include when it is not actually used. This example also shows that a 'hdl_lib_include_ip' can also occur at some
    intermediate hierarchical component level in a design. The advantage is that the include of ip_stratixiv_tse_sgmii_lvds in
    the unb1_board hdlib.cfg now automatically applies to all designs that instantiate unb1_board.
    The exclusion can only be done when the component is instantiated as a component and not as a entity. Therefore the
    exclusion is done at the IP level, because the IP is instantiated as component. Hence the exclusion works because for a
    component instance that is not used, only the component declaration (in the component package) needs to be known by the
    tools. Hence the exclusion makes use of the same VHDL component mechanism as the technology independence.
    The exclusion is only done for synthesis, so not for simulation. The reason is that for simulation it is oke to keep the
    library included.
    The difference between this 'hdl_lib_uses_ip' key and the 'hdl_lib_technology' key is that the HDL libraries with
    'hdl_lib_technology' key value that does not match the specified technologies are not build. Whereas HDL libraries that
    are excluded via the combination of 'hdl_lib_include_ip' and 'hdl_lib_uses_ip' are still created in the build directory, but
    they are not used for that HDL library so they are excluded dynamically. 
    
- hdl_lib_uses_sim =
    See also the other 'hdl_lib_include_*' descriptions.
    List of HDL library names that are used in this HDL library for the 'test_bench_files', only the libraries that appear in
    VHDL LIBRARY clauses need to be mentioned, all lower level libraries are found automatically.
    The 'hdl_lib_uses_synth' and 'hdl_lib_uses_ip' keys and 'hdl_lib_uses_sim' key separate the dependencies due to the synth_files
    from the extra dependencies that come from the test bench files. Quartus can exit with error if IP is included in the
    'hdl_lib_uses_ip' list of libraries but not actually used in the design, eg due to a sdc file that is then sourced but
    that cannot find some IP signals. Having a seperate 'hdl_lib_uses_ip' and 'hdl_lib_uses_sim' key solves this issue, by avoiding
    that libraries that are only needed for test bench simulation get included in the list for synthesis. Often the
    'test_bench_files' do not depend on other libraries then those that are already mentioned at the 'hdl_lib_uses_synth' key, so
    then the 'hdl_lib_uses_sim' remains empty.

- hdl_lib_include_ip =
    See also the 'hdl_lib_include_*' descriptions.
    The 'hdl_lib_uses_*' keys identify which libraries are available for that particular HDL library. For simulation they are all
    included. The 'hdl_lib_include_ip' identifies which IP libraries from 'hdl_lib_uses_ip' will actually be included for synthesis.
    The 'hdl_lib_include_ip' typically appears in another higher layer HDL library. IP libraries can be includes in the following
    ways:
    . by listing the IP library name at the 'hdl_lib_uses_synth' key, then it is always included
    . by listing the IP library name at the 'hdl_lib_uses_ip' key, and including it explicitly with the 'hdl_lib_include_ip' key.
    The 'hdl_lib_include_ip' is typically set at:
    . the design library that actually uses that IP library, this then has to be done per design revision.
    . for IP in unb*_board that is used in all designs it is set in these unb*_board libraries so that it is then automatically
      included for all designs that use the unb*_board library (i.e. via ctrl_unb*_board.vhd).
    . Note that specifying an IP library at the 'hdl_lib_uses_ip' key and then including it via 'hdl_lib_include_ip' in the same
      hdllib.cfg, is equivalent to specifying the IP library at the 'hdl_lib_uses_synth' key.
    
- hdl_lib_disclose_library_clause_names =
    See also the 'hdl_lib_include_*' descriptions.
    If a component from a library is instantiated as a component (instead of as an entity) then that means that this library may be
    unavailable and then it has to be listed as a pair of lib_name and library_clause_name at this 'hdl_lib_disclose_library_clause_names'
    key. For components that are instantiated as components the actual source library may have been removed (via the 'hdl_lib_technology'
    key) or it may even not be present at all. The library clause name of instantiated components is used in the VHDL code at the LIBRARY 
    statement in e.g. a tech_*.vhd file to ensure default component binding in simulation. The 'hdl_lib_disclose_library_clause_names'
    key is then used in the hdllib.cfg file of that (technology) wrapper library to disclose the library clause name of the component
    library that is listed at the hdl_lib_uses_* key.

- hdl_lib_technology =
    The IP technology that this library is using or targets, e.g. ip_stratixiv for UniBoard1, ip_arria10 for UniBoard2. For generic HDL libraries use ''.
    For simulating systems with multiple FPGA technologies it is also possible to list multiple IP technology names.

- regression_test_vhdl = 
    List of pure VHDL testbenches that need to be included in the regression simulation test. For Modelsim this key is used by
    modelsim_regression_test_vhdl.py to simulate all testbenches and report their result in a log. The VDHL test benches must be
    self-checking and self-stopping.
    
- modelsim_compile_ip_files =
    This key lists one or more TCL scripts that are executed by the Modelsim mpf before it compiles the rest of the source code. Eg:
    - compile_ip.tcl : a TCL script that contains external IP sources that are fixed and need to be compiled before the synth_files. For
                       the Altera IP the compile_ip.tcl is derived from the msim_setup.tcl that is generated by the MegaWizard or Qsys.
    - map_ip.tcl : a TCL script that maps a VHDL library name to another location.
    
- <tool_name>_copy_files =
  The copy_files key can copy one file or a directory. The first value denotes the source file or directory and the second value
  denotes the destination directory. The paths may use use environment variables. The file path or directory can be an absolute path
  or a relative path. The relative path can be from hdllib.cfg location in SVN or from the build dir location. Whether the source
  directory is the hdllib.cfg location in SVN or the build_dir location depends on the <tool_name>. For modelsim_copy_files and 
  quartus_copy_files the relative source directory is the hdllib.cfg location in SVN and the relative destination directory is the
  build_dir location. The direction can be from build dir to dir in SVN or vice versa, or to any directory location in case
  absolute paths are used. The destination directory will be removed if it already exists, but only if it is within in the build_dir.
  If the destination directory is not in the build_dir then it first needs to be removed manually to avoid accidentally removing a 
  directory tree that should remain (eg. ~).

- modelsim_copy_files =
    Copy listed all directories and files for simulation with Modelsim, used when tool_name_sim = modelsim in hdltool_<toolset>.cfg.
    Can be used to eg. copy wave.do or data files from SVN directory to the build directory where the Modelsim project file is. For 
    data files that are read in VHDL the path then becomes data/<file_name>.

- quartus_copy_files =
    Copy listed all directories and files for synthesis with Quartus, used when tool_name_synth = quartus in hdltool_<toolset>.cfg.
    Can be used to eg. copy sopc or qsys file from SVN directory to the build directory where the Quartus project file is and that is where the
    run_* bash commands expect them to be.
    
- synth_files =
    All HDL files that are needed for synthesis. For Modelsim they need to be in compile order and they areplaced in the 'synth_files' project folder.
    For Quartus synthesis these files get included in the HDL library qip file.
    Both Verilog and VHDL files are supported.
    
- test_bench_files = 
    All HDL files that are needed only for simulation. These are typically test bench files, but also HDL models. For Modelsim they need to
    be in compile order and they are placed in the 'test_bench_files' project folder.
    Both Verilog and VHDL files are supported.

- synth_top_level_entity =
    When this key exists then a Quartus project file (QPF) and Quartus settings file (QSF) will be created for this HDL library. If this key does
    not exist then no QPF and QSF are created. The 'synth_top_level_entity' key specifies the top level entity in the HDL library that will be the
    top level for synthesis. If the key value is '' then the 'hdl_lib_name' is taken as top level entity name.
    
    * Created QPF:
      - It only states that there is one revision that has the name of the 'synth_top_level_entity'. The Quartus scheme for revisions is not used.
        Instead the RadioHDL scheme of defining design revisions as separate HDL libraries is used.
        
    * Created QSF:
      - Defines the top level entity name using 'synth_top_level_entity'
      - It sources the files listed by the 'quartus_qsf_files' key, this is typically a board qsf that defines settings that are common to all
        designs that target that board, eg. unb1_board.qsf.
      - It sources all library QIP files <lib_name>_lib.qip that are needed by the design. The library QIP files are sourced in dependency order
        so that the top level design <lib_name>_lib.qip is sourced last. In this way the top level design constraints are at the end.
        
    * Created <lib_name>_lib.qip files
      The <lib_name>_lib.qip files are created for each library using the following keys in this order:
      - hdl_lib_uses_synth   -- used for all HDL libraries
      - quartus_vhdl_files   -- used for IP libraries that have different HDL file for sim and for synth (typically not needed for most IP)
      - quartus_qip_files    -- used for IP libraries (constaints for the IP), top level design libraries (SOPC or QSYS MMM, e.g. sopc_unb1_minimal.qip)
      - quartus_tcl_files    -- used for top level design libraries (pinning definitions, e.g. unb1_minimal_pins.tcl)
      - quartus_sdc_files    -- used for top level design libraries (timing constraints, e.g. unb1_board.sdc)

- quartus_qsf_files =
    See also 'synth_top_level_entity' description.
    One or more .qsf files that need to be included in the HDL library qsf file for Quartus synthesis of a 'synth_top_level_entity' VHDL file.
        
- quartus_vhdl_files = 
    See also 'synth_top_level_entity' description.
    One or more .vhdl files that need to be included in the HDL library qip file for Quartus synthesis. These are VHDL files that must not be 
    simulated so the are not listed at the 'synth_files' key. This can typically occur for technology IP libraries where e.g. a .vhd file is used
    for synthesis and a .vho file for simulation like in the tse_sqmii_lvds HDL library.

- quartus_qip_files =
    See also 'synth_top_level_entity' description.
    One or more .qip files that need to be included in the HDL library qip file for Quartus synthesis.
  
- quartus_tcl_files =
    See also 'synth_top_level_entity' description.
    One or more .tcl files that need to be included in the HDL library qip file for Quartus synthesis.

- quartus_sdc_files =
    See also 'synth_top_level_entity' description.
    One or more .sdc files that need to be included in the HDL library qip file for Quartus synthesis.
    
- vivado_copy_files =
    Same as key quartus_copy_files, but for Xilinx/Vivado

- vivado_xdc_files = 
    Same as key quartus_sdc_files, but for Xilinx/Vivado

- vivado_tcl_files =
    Same as key quartus_tcl_files, but for Xilinx/Vivado

- vivado_vhdl_files = 
    Same as key quartus_vhdl_files, but for Xilinx/Vivado

- vivado_bd_files =
    Contains one or more .bd files. bd=block diagram. This can be compared with Quartus QSYS files. The bd file describes the Xilinx AXI bus with
    masters and slaves, including ports, including address map.

- vivado_ip_repo =
    Contains one or more .zip files. Each zip file is an IP block. Simply an enhancement to the IP catalog within Vivado.

- vivado_xci_files =
    Containes a list of one or more xci or xcix files. An xci[x] file is a precompiled IP block. It's internal IP settings are fixed. 
    Like a .zip file, this file also contains a file/directory structure.


4) Porting from $UNB to $RADIOHDL

a) History

First the base modules have been ported, e.g. common, dp. Only the files that need to change are SVN copied from their location
in $UNB to $RADIOHDL. Files that remain unchanged are referred to from $UNB in the hdllib.cfg.
Initially only Modelsim simulation is supported in $RADIOHDL by means of modelsim_config.py. The first design to be ported is
unb_minimal, but that requires tse and unb_common to be ported first.
Major renamings have been done for tse --> eth and unb_common --> unb1_board to make the code more clean. The eth_layers_pkg
has been split into common_network_layers_pkg.vhd (for Ethernet protocol parameters) and common_network_total_header_pkg.vhd (for
representing the header in an array of word).
No functional changes are done, only cosmetic to make the code more clean. The changes are guarded by the tb_tb_tb_*_regression.vhd
test benches for eth and unb1_board that are self-checking and must run without errors.

b) Use SVN-copy

When a source file needs to be modified then it is appropriate to SVN-copy it to the $RADIOHDL tree.
In this way the $UNB tree remains stable, while new developments can continue savely in the $RADIOHDL
tree. Best use SVN-copy instead of plain cp, because SVN-copy preseves the revision log.

c) Replace SOPC avs2_eth_coe instance
   
Replace in SOPC instance avs_eth_0 with avs_eth_coe by avs2_eth_coe. The eth now uses eth_pkg.vhd from
$RADIOHDL. The avs_eth_coe still uses the eth_pkg.vhd from $UNB and this causes duplicate source file
error in synthesis. Therefore open the SOPC GUI and replace the instance avs_eth_0 with avs_eth_coe by
the avs2_eth_coe component.
   
Make sure that the user_component.ipx is set up oke (see point 2e), because that is needed for SOPC to
find the new avs2_eth_coe in $RADIOHDL.



5) Build directory location

The Modelsim and Quartus build location central outside the $RADIOHDL sources directory tree, whereby the
subdirectory names are defined by the corresponding keysin the hdltool_<toolset>.cfg:

  <build_dir>/<toolset_name>/<hdl_lib_name>
  
eg.

  $HDL_BUILD_DIR/unb1/modelsim/common
                
The location is made via the 'build_dir' key that specify the root path to the central directory e.g.
via $HDL_BUILD_DIR. The advantage of the central directory build tree is that it can easily be removed (using rm -rf) and
recreated (using modelsim_config.py and quartus_config.py). For synthesis recreation of targets like sof files can take much
time though.

                

6) Compilation and simulation in Modelsim

a) Creating the Modelsim project files

The binaries for Modelsim get build in a separate directory tree with absolute path set by the build_dir key in the hdltool_<toolset>.cfg.
Currently the path is set to $HDL_BUILD_DIR = $RADIOHDL/build. Using a completely separate absolute build tree is more clear than
building the library in a local build directory. To create the Modelsim project files for all HDL libraries in the $RADIOHDL tree do:

  > rm -rf $RADIOHDL/build/unb1/modelsim                              # optional
  > python $RADIOHDL/tools/oneclick/base/modelsim_config.py -t unb1 

See also the docstring help text in the Python code:

  > python
  >> import modelsim_config.py
  >> help(modelsim_config.py)
  
  
b) Compilation

 > run_modelsim unb1 &
 
In Modelsim do:

 >> lp eth             -- load eth library Modelsim project file
 >> lp all             -- reports all libraries in order that eth depends on
 >> mk compile all     -- compiles all libraries in order that eth depends on
 
Alternatively one can use Unix 'make' and Modelsim 'vmake' via the 'mk' command. The advantage is that after
an initial compile all any subsequent recompiles after editing a VHDL source file only will require recompilation
of the VHDL source files that depend on it. 

 >> mk clean all       -- deletes all created work directories and Makefiles in $HDL_BUILD_DIR that were needed for eth
 >> mk all             -- compiles all libraries in order that eth depends on and creates the Makefiles
 
To load another project do e.g.:

 >> lp common
 >> lp all             -- reports all libraries in order that common depends on

 
c) Simulation

The simulation is done using a VHDL test bench. These test bench files can be recognized by the 'tb_' prefix and
have a simulation configuration icon in the Modelsim GUI. To simulate a tb do e.g.:

 >> double click tb icon, e.g.: tb_eth
 >> as 10              -- add all signals of 10 levels deep into of tb hierarchy to the Wave Window
 >> run -a             -- run all until the tb is done
 
The tb in the eth library run as long as needed toapply the stimuli and they are self checking. The tb are 
instantiated into multi test bench tb_tb_tb_eth_regression.vhd. By running this tb_tb_tb_eth_regression the
entire eth library gets verified in one simulation.



7) Synthesis in Quartus

a) Creating the Quartus project files

The quartus_config.py creates the Quartus qpf, qsf and or qip files for a design library.

  > rm -rf $RADIOHDL/build/unb1/quartus                              # optional
  > python $RADIOHDL/tools/oneclick/base/quartus_config.py -t unb1 


8) Design revisions

Within a design, several revisions can be made: 
Add a directory 'revisions/' in the design directory which contains a list of subdirectories. Each subdirectory is 
a revision. The design 'unb1_minimal' can be uses as an example. See the following revisions:

  designs/unb1_minimal/revisions/unb1_minimal_qsys/
  designs/unb1_minimal/revisions/unb1_minimal_sopc/

Each revision should at least have a 'hdllib.cfg' file and a toplevel .vhd file. See for example:

  unb1_minimal_qsys/hdllib.cfg
  unb1_minimal_qsys/unb1_minimal_qsys.vhd

In the toplevel vhdl file you can specify the 'g_design_name' generic (in this example 'unb1_minimal_qsys').
And in 'hdllib.cfg' you specify the libraries and keys you need, in this case 'unb1_minimal'.



9) RadioHDL directory structure

Currently, the RadioHDL SVN repository is contained within the UniBoard_FP7 SVN repository, at the following URL:

https://svn.astron.nl/UniBoard_FP7/RadioHDL/trunk

The above location might change in the future.

The following sections describe the subdirectories that exist.

a) applications/<project_name>/designs/<design_name>/revisions/<design_name_rev_name>
                                                    /quartus
                                                    /src
                                                    /tb
                               libraries/
                               
   . Contains firmware applications designs, categorized by project.

b) boards/<board_name>
         /uniboard2a/designs/unb2a_led/quartus
                                       src
                                       tb
                    /libraries/unb2a_board/quartus
                                           src
                                           tb

   . Contains board-specific support files and reference/testing designs
     . <board_name>/designs/
       . Contains application designs that can be run on that board to test board-specific features.
     . <board_name>/libraries/
       . Contains board-specific support files, such as firmware modules to communicate with board-specific ICs,
         constraint files, pinning files, board settings template files

c) libraries/<library_category>/<library_name>
             base
             dsp
             external
             io
             technology/...
                        ip_arria10_e3sge3
   . See libraries_hierarchy_and_structure.jpg and readme_libraries.txt
   . Library of reusable firmware blocks, categorized by function and in which generic functionality is separated 
     from technology. Within technology another seperation exists between generic technology and hardware-specific IP.
   . The library_category external/ contains HDL code that was obtained from external parties (e.g. open source).
   . <library_category>/<library_name>/designs/
     . Contains reference designs to synthesize the library block for specific boards.

d) software/
   . Intended for software that runs on a PC, such as control/monitoring of boards and programs to capture and process
     board output, e.g. sent via Ethernet to the processing machine.

e) tools/
   . Contains the RadioHDL tools that are described in this readme file.


The subdirectories that reoccur contain:

   - src/vhdl  : contains vhdl source code that can be synthesised
   - tb/vhdl   : contains vhdl source code that can is only for simulation (e.g. test benches, models, stubs)
   - quartus   : synthesis specific settings for design that uses Quartus and an Altera FPGA
   - vivado    : synthesis specific settings for design that uses Vivado and an Xilinx FPGA
   - revisions : contains revisions of a design that only differ in generic settign


100) To do

a) quartus_* keys and synth_top_level_entity
   . The quartus_* keys are now source oriented. Instead it may be better to redefine them as target oriented. Eg. a
     quartus_create_qsf key that defines to create a qsf file using the information listed in the values.
     Whether a key is source oriented or target oriented depends on whether its files are used for one or more targets.
     In general if a file is used for more targets then source oriented is preferred to avoid having to list the file
     name twice. If a file is used only for one target then target oriented is preferred to be more clear about the
     purpose of the key.
   . The synth_top_level_entity enforces the creation of a qpf and qsf. This kind of hidden behavior is not so nice.
     Instead it is more clear to have an explicit quartus_create_qpf and quartus_create_qsf key to define this.   
   
b) Generate Quartus IP key
   The generate_ip.sh scripts for generating the MegaWizard or QSYS IP components in fact are merely a wrapper script
   around the qsys-generate command. The generate_ip.sh may seem an unnecessary intermediate step if the IP is 
   generated automatically. The IP could be generated automatically based on a megawizard key or a qsys key that
   has the description file as value. However the advantage of a generate_ip.sh script is that it can hide whether the
   MegaWizard or QSYS needs to be used to generate the IP, so in that way a 'quartus_generate_ip' key can fit both:
   
     quartus_copy_files =
         generate_ip.sh
         <technology>_<hdl_lib_name>.qsys
     quartus_generate_ip = generate_ip.sh
   
   The 'quartus_copy_files' key is used to copy the IP generation source file and the generation script to the
   build directory. The 'quartus_generate_ip' key identifies the script that needs to be ran when the IP has to be
   generated. Eg. a --generate_ip command line argument for quartus_config.py (rather than a separate
   quartus_generate_ip.py script) can then generate the IP for all libraries that have such a key. The IP can then
   be generated outside the SVN tree. The $IP_DIR path compile_ip.tcl needs to be adjusted to generated/ and the
   IP then gets generated in:
   
      $HDL_BUILD_DIR/<toolset>/quartus/<hdl_lib_name>/generated
   
   For generated IP that is kept in SVN that IP could still remain there.
   
   The hdllib.cfg should then also define a IP toolname subdirectory in build dir, eg.:
    
     <build_dir>/<toolset>/<tool_name> = $HDL_BUILD_DIR/qsys        or
                                         $HDL_BUILD_DIR/megawizard
    
   or more general $HDL_BUILD_DIR/ip?
   The $HDL_BUILD_DIR now has a modelsim and quartus subdir:
    
      $HDL_BUILD_DIR/<toolset>/modelsim       -- made by modelsim_config.py using tool_name_sim from hdltool_<toolset>.cfg
      $HDL_BUILD_DIR/<toolset>/quartus        -- made by quartus_config.py using tool_name_synth from hdltool_<toolset>.cfg
   
   The IP can be put in a subdir using eg 'tool_name_ip' = quartus_ip:
   
      $HDL_BUILD_DIR/<toolset>/quartus_ip     -- made by quartus_config.py using a new tool_name_ip from hdltool_<toolset>.cfg
      
   or can it be put in the tool_name_synth directory:
   
      $HDL_BUILD_DIR/<toolset>/quartus
      
   or do we need tool_name_megawizard and tool_name_qsys to be able to create:
                                      
      <build_dir>/<toolset>/<tool_name>
      $HDL_BUILD_DIR/unb1/megawizard     -- Altera MegaWizard
      $HDL_BUILD_DIR/unb1/qsys           -- Altera QSYS
      $HDL_BUILD_DIR/unb1/coregen        -- Xilinx
      
   Probably it is not so important whether the IP is generated by MegaWizard or Qsys, because that selection is
   already covered by the generate_ip.sh scripts. In the hdltool_<toolset>.cfg both MegaWizard and Qsys can be regarded as
   being part of the Quartus tool. Therefore using tool_name_ip provides sufficient distinction in IP build
   sub directory. However the IP could also be generated into the tool_name_synth build directory and then even
   the tool_name_ip key is not needed, because the tool_name_synth sub directory also suits the Quartus IP
   generation.
   
   Conclusion:
   - Using tool_name_synth = quartus is also sufficient/suitable to define the build subdirectory for IP generation.
     Having a dedicate tool_name_ip could be nice, to more clearly see in the build tree which libraries have IP.
   
c) regression test script
   * For pure HDL tests the modelsim_regression_test.py script can simulate VHDL test benches that are listed at
     the 'regression_test_vhdl' key and report the result.
   * For Python test cases another key can be defined 'regression_test_py_hdl'. The values they may contain the entire command
     to run the Python test case with the HDL test bench. Note that the pure VHDL test benches could be perphaps also be
     regarded as a special case of the Python MM - VHDL tests, ie. as a test without MM.
   * Another bash or Python script that synthesises a set of designs to check that they still run through synthesis ok.

d) multiple libRootDirs for finding hdllib.cfg files
   The libRootDir is now defined via a the 'lib_root_dir' key in the hdltool_<toolset>.cfg.
   Currently hdlib.cfg files are search from one rootDir by find_all_dict_file_paths() in common_dict_file.py. It
   would be usefule to be able to specify multiple rootDirs for the search path. This allows finding eg. all
   hdllib.cfg in two different directory trees without having to specifiy their common higher directory root which
   could be a very large tree to search through. Furthermore by being able to specify the rootDirs more precisely
   avoids finding unintended hdllib.cfg files. Support for multiple rootdirs needs to be implemented in
   common_dict_file.py because the results from all root dirs need to be in a common object.
  
e) Python peripherals
   The Python peripherals are still in the $UNB/Software/python/peripherals directory. At some time we need to move
   these also to RadioHDL. The peripherals could be located central again or local in a src/python directory. A first
   step can be to svn copy the $UNB/Software/python dir to $RADIOHDL/software/python to become independent of the
   $UNB tree. An intermediate scheme is also possible whereby the periperal is kept local but copied to a central
   build/python directory by means of a python_config.py script. The advantage of a central directory is that the periperals 
   are grouped so that only a single Python search path is needed. The disadvantage of having a fixed central
   location in SVN is that peripherals that are application specific also need to be located there. Another option
   may be to use a synbolic link from a central directory to each local Python peripheral.
   
   
f) Improve support IP for multiple FPGA device types and Quartus tool versions

The IP is FPGA type specific (because it needs to be defined in the Qsys source file) and tool version specific
(because some parameters and even port IO may change). Currently there is only one IP directory per FPGA
technology (eg. ip_arria10) so there is no further separation into device family type and tool version. The
disadvantage of this scheme is that only one version of Quartus can be supported. For a minor version 
change it may not be necessary to upgrade, but for a major version change or for a device family type (eg. from
engineering sample to production sample) change it probably is. To preserve the old version IP it is best to
treat the both the FPGA device version id and the Quartus tool version as a new technology. For example for
Arria10 we now use Quartus 15.0 and device family of UniBoard2 v0 and the IP for that is kept in:

  $RADIOHDL/libraries/technology/ip_arria10/
  
This can be renamed in:

  $RADIOHDL/libraries/technology/ip_arria10_device_10AX115U4F45I3SGES_quartus_15.0/
  
For a directory name it is allowed to use a '.' instead of a '_'. The directory name is not mandatory, but the name convention is
to define the FPGA technology as a triplet:

  ip_<fpga family>_device_<fpga identifier>_quartus_<version>
  
A future version of the IP can be kept in:

  $RADIOHDL/libraries/technology/ip_arria10_device_10AX115U4F45I3SGES_quartus_16.0/

The technology_pkg.vhd then gets;

  c_tech_arria10_device_10AX115U4F45I3SGES_quartus_14_1 = ...;
  c_tech_arria10_device_10AX115U4F45I3SGES_quartus_15_0 = ...;
  c_tech_arria10                                        = c_tech_arria10_device_10AX115U4F45I3SGES_quartus_15_0;  -- optional default
  
The hdllib.cfg of the specific technology IP library then has key (only one value):

  hdl_lib_technology = ip_arria10_device_10AX115U4F45I3SGES_quartus_15_0
  
The hdltool_<toolset>.cfg can support multiple technologies eg. to be able to simulate a system with more than one FPGA that are
of different technology (eg. an application with Uniboard1 and Uniboard2):

  technology_names = ip_stratixiv
                     ip_arria10_device_10AX115U4F45I3SGES_quartus_15_0

All libraries that have hdl_lib_technology value that is not in the list of technology_names are removed from the dictionary list
by hdl_config.py, so these IP libraries will not be build.

The build directory currently contains:

  <build_dir>/<toolset_name>/<hdl_lib_name>

This scheme is probably still sufficent to also support the FPGA technology as a triplet. However it may be necessary to rename the
library key values in the IP hdllib.cfg to contain the full triplet information, so eg.

  hdl_lib_name = ip_arria10_fifo
  hdl_library_clause_name = ip_arria10_fifo_lib
  
then becomes:

  hdl_lib_name = ip_arria10_device_10AX115U4F45I3SGES_quartus_15_0_fifo
  hdl_library_clause_name = ip_arria10_device_10AX115U4F45I3SGES_quartus_15_0_fifo_lib
  
this is a bit awkward. If only one Quartus version and only one device type are supported per toolset, then all these versions can keep 
the same basic hdl_lib_name and hdl_library_clause_name because the IP libraries that are not used can be removed from the build.
Alternatively the hdllib_config.py could support multiple technology version IP libraries that use the same logical library name and use
clause.

The purpose is to be able to handle in parallel different FPGA vendors, different FPGA types and different tool version. We do not have
to support all combinations, but only the combinations that we actually use. Eg. for the FPGA type this implies that we only support the FPGA types
that are actually used on our board. If we make a new board with another FPGA, then we add the technology triplet for that FPGA.


g) Improve toolset scheme

The toolset defines the combination of Modelsim version and Quartus version. Currently there are toolsets 'unb1', 'unb2' and 'unb2a'. This
toolset scheme can be improved because:

- for python they are defined by the hdltool_<toolset>.cfg, but for the run_* bash scripts they are defined in set_modelsim and set_quartus,
  can they be defined in a common source (eg. base on hdltool_<toolset>.cfg set an environment variable and uses that for bash). The bash
  script must then be ran from the same terminal as where the python config script was used to set the environment variable, because otherwise
  the environment variable is not set or may not be correct.
- the toolsets are tight to a board name 'unb1' (is that oke?) or should we use more general toolset names, or do we need a symbolic toolset names at all? 
- there is also a 'site' level in the bash scripts set_modelsim and set quartus (is that still needed?)


h) Declare IP libraries to ensure default binding in simulation.

Currently the IP library is declared in the technology VHDL file e.g. like 'LIBRARY ip_arria10_ddr4_4g_1600_altera_emif_150;' in tech_ddr_arria10.vhd.
This IP library clause is ignored by synthesis. The IP library must be mapped for simulation, because otherwise Modelsim gives
an error when it compiles the VHDL. Therefore the IP library can then not be excluded for simulation with 'hdl_lib_include_ip' key.
Alternatively the LIBRARY clause could be omitted if the IP library is added to the -L libraries search list of each simulation configuration the
Modelsim project file. This can be achieved adding the IP library to the modelsim_search_libraries key in the hdltool_unb2.cfg. However the problem is
then that if the IP library is not mapped to a directory then Modelsim will issue an error when it tries to search it.
--> For now keep the 'hdl_lib_include_ip' but only use it for synthesis. For simulation the 'hdl_lib_include_ip' is ignored. Which is fine because
    for simulation there is no need to exclude IP libraries.
   


101) More ideas

a) zip scripts
   A zip script can gather all sources that are needed for a particular RadioHDL view point, eg.
   
   - zip all required libraries for a certain level library --> useful for somebody who wants to reuse a HDL library.
   - zip all code necessary to run Python test cases on HW target --> useful for somebody who only wants to use the HW.
   - zip all tool environent code --> useful for somebody who wants to use our tool flow but not our HDL.
   
   Related to this is (how) can we more clearly divide up the RadioHDL/ directory to eg. reuse only parts of it and
   to develop these in other locations/repositories (eg. GIT). Eg. the applications/ directory may not be needed or
   even suitable in RadioHDL/ because applications could be kept elsewhere, even in another repository at another 
   institute.
   
b) support dynamic generation of IP
   Very preliminary ideas:
   Currently the MegaWizard or QSYS component description file is fixed and created manually in advance via the 
   GUI. In future the component description file could be created based on parameters that are defined in the
   hdllib.cfg or even parameters that depend on the requirements from the design. In a dynamic flow the hdllib.cfg
   for IP could even not exist as a file, but only as a dictionary in the script. 
   
c) Link RadioHDL developments with the OneClick MyHDL developments.
   The hdllib.cfg dictionary format seems useful also in the OneClick flow. For some created libraries the hdllib.cfg
   may not exist as a file and but only as the dictionary in the script. The various methods in modelsim_config.py
   and quartus_config.py can also be reused in a OneClick flow.
 
   
102) Know errors

a) ** Fatal: Error occurred in protected context. when loading a simulation in Modelsim
 - Example:
   # Loading ip_stratixiv_phy_xaui_lib.ip_stratixiv_phy_xaui_0(rtl)
   # ** Fatal: Error occurred in protected context.
   #    Time: 0 fs  Iteration: 0  Instance: /tb_<...>/<hierarchy path to ip>/ip_stratixiv_phy_xaui_0_inst/<protected>/<protected>/<protected>/<protected>/<protected>/<protected> File: nofile
   # FATAL ERROR while loading design
 
   Make sure that the StratixIV IP search libraries are defined by modelsim_search_libraries in the hdltool_<toolset>.cfg.
