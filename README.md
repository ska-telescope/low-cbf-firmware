# Low-CBF Firmware Repository
This repository contains FPGA firmware to implement Low CBF correlator and associated functions.

## Description
FPGAs implementing Low CBF receive dual-polarisation I/Q data from stations in the Low Array and perform filtering, correlation, beamforming operations before delivering the results to SDP, PSS and PST via optical link. Firmware for the FPGAs is written mostly in VHDL.


## License
The firmware in this repository is released under the license that can be found in the root directory of this repository, except where a source file specifically mentions another license.

---

## Directory Structure

* _/applications_ - For all high level FPGA projects. This directory should include projects that are independent of hardware board.
    * Each specific application i.e. csp_low should be grouped into it's own directory.
    * Applications should not include any libraries, only top level design files and include libraries from the board directory or general libraries directory
    * Should include sub directories of vhdl, verilog, vivado
* _/boards_ - For board specific library (including hardware support features) and test projects targeted at testing specific board features. These projects should not be retargeted to different boards.
    * Contains a structure as documented in Figure 3-2 (details listed below)
    * Single library for each board including all hardware support functions
    * May contain multiple libraries if they contain IP for different FPGA variants on same board i.e. ES vs production parts
* _/libraries_ - For all firmware libraries. Contains 5 top level directories (all code to be placed inside one of them) to provide logical grouping but all libraries are available in the same flat namespace. Within each top level directory there is a subdirectory that is structured as shown in Figure 3-3 (details listed below) which contains all user code and text benches. The subdirectory name is open to the designer. The top level directories are:
    * _/base_ - Includes common libraries and building blocks that may be used as small components for higher level libraries i.e. pipeline registers, fifos and AXI4 definitions. This directory also includes all the wrappers for technology blocks
    * _/dsp_ - Includes high level DSP libraries i.e. beamformer or filterbank
    * _/external_ - Direct copies of external vendor IP libraries i.e. Open Hardware White Rabbit core
    * _/io_ - All non-dsp functionality i.e. MACE, FPGA interconnect
    * _/technology_ - Vendor specific IP implementations
* _/tools_ - Contains all of the RadioHDL scripts and configuration files
    * _/args_ - Contains all ARGS script code and templates
    * _/bin_ - Binary files required for RadioHDL operation
    * _/doc_ - RadioHDL documentation
    * _/modelsim_ - Configuration scripts for modelsim simulator tool
    * _/radiohdl_ - Contains scripts to automatically build simulation and FPGA project files. Contains the high level executable python scripts
        * Modelsim_config.py - Build project files for modelsim
        * Vivado_config.py - Build project files (and bitfiles) for Vivado
    * _/vivado_ - Configuration scripts for Xilinx Vivado simulator & building tool
    * _/quartus_ - Configuration scripts for Altera building tool

---

## Tool Environment

RadioHDL (in the 'tools' directory) is a set of python modules that can create a Vivado or Quartus project that allows the source code to be compiled into executable form with the FPGA vendor's tools (Vivado for Xilinx, Quartus for Intel/Altera).
RadioHDL supports both Windows and Linux operating systems. The following software needs to be accessible (in the system PATH) in order to build project files

* Make (Available in /tools/bin for win32 platforms)
* Python 3.6+
* Python Libraries (numpy, pylatex, yaml)

### Environment Variables

The following environment variables must be defined for the python scripts to run correctly. All paths should conform to the path syntax of the operating system being used.

* RADIOHDL = checkout directory of the Low.CBF subversion firmware tree without trailing slash
* HDL_BUILD_DIR = directory to build project to. Normal configured as $RADIOHDL/build
* $RADIOHDL/tools/bin added to PATH
* $MODEL_TECH_XILINX_LIB = directory containing precompiled Xilinx Modelsim libraries
* $MODEL_TECH_DIR = Modelsim directory

### Toolsets

A number of preconfigured targets are available as a **toolset** when building a modelsim or vivado project. A toolset configuration defines a build tool, a simulation tool, FPGA IP libraries and simulation libraries to use. Available targets are:

* default - Generic simulation environment using modelsim and ultrascale libraries
* poc - For the Gemini POC. Vivado tool and Modelsim simulator using IP for an Virtex Ultrascale+ 9 ES
* kcu105 - For the KCU105 development board. Vivado tool and Modelsim simulator using IP for an Kintex Ultrascale 40
* lru - For the Gemini LRU. Vivado tool and Modelsim simulator using IP for an Virtex Ultrascale+ 9
* lru_es - For the Gemini LRU with ES FPGA. Vivado tool and Modelsim simulator using IP for an Virtex Ultrascale+ 9 ES
* vcu108 - For the VCU108 development board. Vivado tool and Modelsim simulator using IP for an Virtex Ultrascale 95
* vcu110 - For the VCU110 development board. Vivado tool and Modelsim simulator using IP for an Virtex Ultrascale 190

