Purpose
-------

Simulate AXI4 bus transactions

Tool:
-----
Xilinx/Vivado 2016.2


Quick steps to simulate
-----------------------

-> In case of needing a fresh compilation, delete the build directory.
    rm -r $RADIOHDL/build


1.  For simulation do:
    python $RADIOHDL/tools/radiohdl/base/modelsim_config.py -t gmi -v3
    run_modelsim gmi

2.  In modelsim do:
    lp axi4
    mk clean
    mk all

    (double click on testbench file)
    as 10
    run 10us
