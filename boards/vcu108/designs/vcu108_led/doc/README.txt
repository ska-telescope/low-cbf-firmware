Status: Tested OK

Purpose: Blink LEDs

Tool: Vivado 2016.2

Quick steps to compile and use design [vcu108_led] in RadionHDL
---------------------------------------------------------------

-> In case of needing a fresh compilation, delete the build directory.
    rm -r $RADIOHDL/build


1. Compile the vcu108_led design with the RadioHDL command:
    python $RADIOHDL/tools/radiohdl/base/vivado_config.py -t vcu108 -l vcu108_led -r -v3

    -t: technology
    -l: the design name
    -r: do compile all until bitstream file
    -v: verbose

    if in doubt: add -h for help

The python scripts create projectfiles and bitstream file in the [build] directory: $RADIOHDL/build



2. Test on hardware: the VCU108 board:

Start Vivado with the shell command: run_vivado vcu108

Then browse through $RADIOHDL/build to find the compiled project. For example it could be in:
$RADIOHDL/build/vcu108/vivado/vcu108_led_build_160928_144815 (where "160928_144815" is a timestamp)
- Open the project by clicking on the .XPR file.
- Open Hardware Manager
- Open Target (assume that VCU108 connected via USB)
- Program the Device with the bitstream file
--> Look at the blinking LEDs (GPIOLED4..7)
- GPIOLED0..3 can be controlled by JTAG in Vivado. Use these Tcl commands in Vivado to test this:
  create_hw_axi_txn wr_txn [get_hw_axis hw_axi_1] -address 0x40000000 -data 87654321 -type write -force
  run_hw_axi [get_hw_axi_txns wr_txn]
  create_hw_axi_txn wr_txn [get_hw_axis hw_axi_1] -address 0x40000000 -data 12345678 -type write -force
  run_hw_axi [get_hw_axi_txns wr_txn]


