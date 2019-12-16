Status: Tested OK

Purpose
-------
Make use of many DSP blocks to warm up the FPGA


Tool
----
Vivado 2016.2


Quick steps to compile and use design [vcu108_heater] in RadionHDL
---------------------------------------------------------------

-> In case of needing a fresh compilation, delete the build directory.
    rm -r $RADIOHDL/build


1. Compile the vcu108_heater design with the RadioHDL command:
    python $RADIOHDL/tools/radiohdl/base/vivado_config.py -t vcu108 -l vcu108_heater -r -v3

    -t: technology
    -l: the design name
    -r: do compile all until bitstream file
    -v: verbose

    if in doubt: add -h for help

The python scripts create projectfiles and bitstream file in the [build] directory: $RADIOHDL/build



2. Test on hardware: the VCU108 board:

Start Vivado with the shell command: run_vivado vcu108

Then browse through $RADIOHDL/build to find the compiheater project. For example it could be in:
$RADIOHDL/build/vcu108/vivado/vcu108_heater_build_160928_144815 (where "160928_144815" is a timestamp)
- Open the project by clicking on the .XPR file.
- Open Hardware Manager
- Open Target (assume that VCU108 connected via USB) 
  (set JTAG frequency to 1MHz, because default 15MHz does not work stable)
- Program the Device with the bitstream file

- Look at the blinking LEDs (GPIOLED4..7)
  LED 4 always ON
  LED 5 flashing ~10Hz
  LED 6,7 toggling ~1Hz

- GPIOLED0..3 can be controlled by JTAG in Vivado. Use these Tcl commands in Vivado to test this:
  #Turn ON LED 0 and 2:
  create_hw_axi_txn wr_txn [get_hw_axis hw_axi_1] -address 0x44A00000 -data 00000005 -type write -force
  run_hw_axi [get_hw_axi_txns wr_txn]

  #Turn ON LED 1 and 3:
  create_hw_axi_txn wr_txn [get_hw_axis hw_axi_1] -address 0x44A00000 -data 0000000A -type write -force
  run_hw_axi [get_hw_axi_txns wr_txn]


- Enable the heaters (DSP blocks)
  In the Vivado Hardware manager, click on the SysMon (System Monitor). 
  This will show a strip chart with the FPGA temperature vs time.

# Enable on all heaters (write to all addresses):
for {set x 0x44a10000} {$x<0x44a10020} {incr x} {
   create_hw_axi_txn wr_txn [get_hw_axis hw_axi_1] -address [format %08x $x] -data 0xffffffff -type write -force
   run_hw_axi [get_hw_axi_txns wr_txn]
}

# Watch the temperature rising quickly... The 0xffffffff means all heaters (bitwise enable)

# Read out XOR on all heaters (readout all addresses):
for {set x 0x44a10000} {$x<0x44a10020} {incr x} {
   create_hw_axi_txn rd_txn [get_hw_axis hw_axi_1] -address [format %08x $x] -len 4 -type read -force
   run_hw_axi [get_hw_axi_txns rd_txn]
}

To get rid of the Vivado message sizelimit:
set_param messaging.defaultLimit 100000

