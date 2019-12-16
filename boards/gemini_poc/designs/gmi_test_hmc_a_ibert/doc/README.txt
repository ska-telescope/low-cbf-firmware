Purpose
-------
This design is based on the Xilinx application note XTP374 for the VCU110 evalation board.
For Gemini, it is converted to match technology and pinout.


Tool
----
Xilinx/Vivado 2016.2


Quick steps to compile and use design [gmi_test_hmc_a_ibert] in RadionHDL
-------------------------------------------------------------------------

1.
-> In case of needing a fresh compilation, delete the build directory.
    rm -r $RADIOHDL/build


-> For complete synthesis of this design until bitstream-file do:
    python $RADIOHDL/tools/radiohdl/base/vivado_config.py -t gmi -l gmi_test_hmc_a_ibert -r -v3

    -t: technology
    -l: the design name
    -r: do compile all until bitstream file
    -v: verbose

    if in doubt: add -h for help

The python scripts create projectfiles and bitstream file in the [build] directory: $RADIOHDL/build



2. Test on hardware: the Gemini board:

Start Vivado with the shell command: run_vivado gmi

Then browse through $RADIOHDL/build to find the compiled project. For example it could be in:
$RADIOHDL/build/gemini/vivado/gmi_led_build_160928_144815 (where "160928_144815" is a timestamp)
- Open the project by clicking on the .XPR file.
- Open Hardware Manager
- Open Target (assume that Gemini is connected via JTAG)
- Program the Device with the bitstream file

To get the HMC chip working in loopback mode, it is necessary to connect an RX/TX line to RS232-converter
to PC. FPGA pin Debug[0] (pin A27) is rxd and Debug[1] (pin B27) is txd.

Use a UART connect tool on the PC and refer to page 12 of XTP374 to setup the HMC chip in loopback.


3.
Development note:
See videos
../../../doc/gmi_test_hmc_b_ibert1.gif
../../../doc/gmi_test_hmc_b_ibert2.gif
How to build up this design


