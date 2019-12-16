Status: Untested, but derived from ref designs of App notes XTP374 and XTP362

Purpose
-------
This design is based on the Xilinx application notes XTP374 and XTP362 for the evalation boards.
For Gemini, it is converted to match technology and pinout


Tool
----
Xilinx/Vivado 2016.2


Quick steps to compile and use design [gmi_test_25G_ibert] in RadionHDL
-----------------------------------------------------------------------

-> In case of a fresh compilation, delete the build directory.
    rm -r $RADIOHDL/build


-> For complete synthese until bitstream-file do:
    python $RADIOHDL/tools/radiohdl/base/vivado_config.py -t gmi -l gmi_test_25G_ibert -r -v3



