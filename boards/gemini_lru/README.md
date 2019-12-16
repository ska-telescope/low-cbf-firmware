# Gemini LRU Projects

---

## Projects

* gemini_lru_test - General test project inlcuidng all board support functionality and transcievers with traffic generators/checkers on them
* lru_minimal -
* lru_heater -
* lru_led -
* lru_pincheck -
* lru_mbo_25G_ibert - Optical module test project for MBO's using 25G Xilinx IBERT core
* lru_qsfp_25G_ibert - Optical module test project for QSFP's using 25G Xilinx IBERT core
* lru_qsfp_mbo_25G_ibert - Optical module test project for QSFP's & MBO's using 25G Xilinx IBERT core
* lru_sfp_10G_ibert - Optical module test project for SFP using 10G Xilinx IBERT core

---

## Compilation

To build any project use the lru or lru_es toolset, where the es toolset is used for the es Gemini LRU cards

python3 $RADIOHDL/tools/radiohdl/base/vivado_config.py -t lru -l gemini_lru_test -r -v3

Where:

* -r will compile the deisgn to a bitfile
* -p will only create a project file
* -t <toolset> lru or lru_es
* -l <project>

---

## Simulation

Simulation project can be built using

python $RADIOHDL/tools/radiohdl/base/modelsim_config.py -t <lru> -v3