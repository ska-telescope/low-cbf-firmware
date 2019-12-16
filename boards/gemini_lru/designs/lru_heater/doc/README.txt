Purpose
-------
Make use of many DSP blocks to warm up the FPGA


Tool
----
Vivado 2016.2


Quick steps to compile and use design [lru_heater] in RadionHDL
---------------------------------------------------------------

1.
-> In case of needing a fresh compilation, delete the build directory.
    rm -r $RADIOHDL/build


-> For complete synthesis of this design until bitstream-file do:
    python3 $RADIOHDL/tools/radiohdl/base/vivado_config.py -t lru -l lru_heater -r -v3

    -t: technology
    -l: the design name
    -r: do compile all until bitstream file
    -v: verbose

    if in doubt: add -h for help

The python scripts create projectfiles and bitstream file in the [build] directory: $RADIOHDL/build



-> After the Vivado project has been generated, abort the compilation process and start the GUI.
   run_vivado lru
   In the top menu: Tools->Settings: Synthesis: set -max_dsp to 0
   This will inform the synthese to use as much LUTs as possible and not use the power-optimized DSPs

-> Compile until bitstream in the Vivado GUI



2. Test on hardware: the Gemini board:

Refer to $RADIOHDL/boards/vcu108/designs/vcu108_heater/doc/README.txt


To get rid of the Vivado message sizelimit:
set_param messaging.defaultLimit 100000

# Enable on all heaters (write to all addresses):
for {set x 0x44a00000} {$x<0x44a00300} {incr x} {
   create_hw_axi_txn wr_txn [get_hw_axis hw_axi_1] -address [format %08x $x] -data 0xffffffff -type write -force
   run_hw_axi [get_hw_axi_txns wr_txn]
}

# Watch the temperature rising quickly... The 0xffffffff means all heaters (bitwise enable)

# Read out XOR on all heaters (readout all addresses):
for {set x 0x44a00000} {$x<0x44a00040} {incr x} {
   create_hw_axi_txn rd_txn [get_hw_axis hw_axi_1] -address [format %08x $x] -len 4 -type read -force
   run_hw_axi [get_hw_axi_txns rd_txn]
}   
    

Test Led R,G,B:
---------------

set_param messaging.defaultLimit 100000
set addr_led  0x44A10000

proc mm_write { addr  data } {
  create_hw_axi_txn wr_txn [get_hw_axis hw_axi_1] -address [format %08x $addr] -data [format %08x $data] -type write -force
  run_hw_axi [get_hw_axi_txns wr_txn]
  after 10
}

proc mm_read { addr } {
  create_hw_axi_txn rd_txn [get_hw_axis hw_axi_1] -address [format %08x $addr] -len 1 -type read -force
  run_hw_axi [get_hw_axi_txns rd_txn]
  return [get_property DATA [get_hw_axi_txn rd_txn]]
}


for {set i 0} {$i<100} {incr i} {
    mm_write $addr_led 0xff0000    ;# Red
    puts "Led should be RED now"
    after 100
    
    mm_write $addr_led 0x00ff00    ;# Green
    puts "Led should be GREEN now"
    after 100

    mm_write $addr_led 0x0000ff    ;# Blue
    puts "Led should be BLUE now"
    after 100
}

