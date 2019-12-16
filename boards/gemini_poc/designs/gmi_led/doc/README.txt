Purpose
-------

Blink a LED. A first board test.

Tool:
-----
Xilinx/Vivado 2016.2


Quick steps to compile and use design [gmi_led] in RadionHDL
------------------------------------------------------------

-> In case of needing a fresh compilation, delete the build directory.
    rm -r $RADIOHDL/build

-> In case it is necessary to compile the .bd file:
    cd $RADIOHDL/boards/gemini/designs/gmi_led/vivado/bd/src
    excute [gmi_led_axi.tcl] script in Vivado
    copy the output
        vivado/bd/src/build/gmi_led_axi.srcs/sources_1/bd/gmi_led_axi/gmi_led_axi.bd to vivado/bd
    copy the wrapper
        vivado/bd/src/build/gmi_led_axi.srcs/sources_1/bd/gmi_led_axi/hdl/gmi_led_axi_wrapper.vhd to src/vhdl

1.

-> For complete synthesis of this design until bitstream-file do:
    python $RADIOHDL/tools/radiohdl/base/vivado_config.py -t gmi -l gmi_led -r -v3

    -t: technology
    -l: the design name
    -r: do compile all until bitstream file
    -v: verbose

    if in doubt: add -h for help

The python scripts create projectfiles and bitstream file in the [build] directory: $RADIOHDL/build

2.
-> For simulation do:
    python $RADIOHDL/tools/radiohdl/base/modelsim_config.py -t gmi -v3
    run_modelsim gmi



3. Test on hardware: the Gemini board:

Start Vivado with the shell command: run_vivado gmi

Then browse through $RADIOHDL/build to find the compiled project. For example it could be in:
$RADIOHDL/build/gemini/vivado/gmi_led_build_160928_144815 (where "160928_144815" is a timestamp)
- Open the project by clicking on the .XPR file.
- Open Hardware Manager
- Open Target (assume that Gemini is connected via JTAG)
- Program the Device with the bitstream file
--> Look at the blinking LED ()
- LEDs can be controlled by JTAG in Vivado. a test sequence shown below



Development notes:
------------------
Video 'axi_for_gmi_led.gif' shows how to add a JTAG interface to the AXI bus to access LEDs




Test Led R,G,B:
---------------

set_param messaging.defaultLimit 100000
set addr_led  0x40000000

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

# Test sequence:
for {set i 0} {$i<100} {incr i} {
    mm_write $addr_led 0xff0000    ;# Red
    puts "Led should be RED now"
    after 1000
    
    mm_write $addr_led 0x00ff00    ;# Green
    puts "Led should be GREEN now"
    after 1000

    mm_write $addr_led 0x0000ff    ;# Blue
    puts "Led should be BLUE now"
    after 1000
}

