Purpose
-------


Tool:
-----
Xilinx/Vivado 2017.2


Quick steps to compile and use design [kcu105_eth10g_test] in RadionHDL
-----------------------------------------------------------------------

1.

-> For complete synthesis of this design until bitstream-file do:
    python $RADIOHDL/tools/radiohdl/base/vivado_config.py -t kcu105 -l kcu105_eth10g_test -r -v3

    -t: technology
    -l: the design name
    -r: do compile all until bitstream file
    -v: verbose

    if in doubt: add -h for help

The python scripts create projectfiles and bitstream file in the [build] directory: $RADIOHDL/build


2.

Simulation.
For simulating this design, use the Vivado simulator. 
After step 1 (above) Start the Vivado GUI: 

run_vivado kcu105

Then open the generated Vivado project in the build directory.

Click Flow->Run Simulation->Run behaviour Simulation

After compile, the wave window shows up. Then add wished signals to the wave window:

In Scope: click-once on 'u_eth_rx'. Then in Objects click-once on clk, then Ctrl-A to select all signals. Right-click and
add to wave window.

In the Tcl Console start the simulation:
run all
 
