Quick steps to compile and use design [gmi_test_25G] in RadionHDL
-----------------------------------------------------------------

-> In case of a fresh compilation, delete the build directory.
    rm -r $RADIOHDL/build


-> For complete synthese until bitstream-file do:
    python $RADIOHDL/tools/radiohdl/base/vivado_config.py -t gmi -l gmi_test_25G -r -v3



old:



1. Start with the RadioHDL Commands:
#   python $RADIOHDL/tools/radiohdl/base/modelsim_config.py -t gmi
    python $RADIOHDL/tools/radiohdl/base/vivado_config.py -t gmi

The python scripts create projectfiles in the [build] directory: $RADIOHDL/build
The vivado_config.py script only generates a Tcl file with Vivado instructions


2.
skipped


3. -> From here either continue to Modelsim (simulation) or Vivado (synthesis)

#Simulation
#----------
#Modelsim instructions:
#    # in bash do:
#    run_modelsim unb2a
#
#    # in Modelsim do:
#    lp unb2a_led
#    mk all
#    # now double click on testbench file
#    as 10
#    run 500us
#
#    # while the simulation runs... in another bash session do:
#    cd $UPE/peripherals
#    python util_unb2.py --sim --unb 0 --fn 3 --seq INFO,SENSORS
#
#    # (sensor results only show up after 1000us of simulation runtime)
#
#    # to end simulation in Modelsim do:
#    quit -sim


Synthesis
---------
Vivado instructions:
    run_vcomp gmi gmi_led

This runs Vivado in batch mode and takes the Tcl file (generated in 1) as argument.


In case of needing the Vivado GUI for inspection
    run_vivado gmi

