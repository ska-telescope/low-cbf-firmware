# To build this project :

# 1. Use bash
bash

# 2. set SVN to the checkout root
export SVN=~/path_name/your_firmware_dir_name

# 3. Setup RadioHDl
source @SVN/tools/bin/setup_radiohdl.sh

# 4. Run RadioHDL with -a option, to generate all ARGS files (and do nothing else)
python3 $SVN/tools/radiohdl/base/vivado_config.py -t lru -l gemini_lru_dsp -a

# 5. Generate the c config file for use by the fpga viewer application :
# Result will be in build/ARGS/gemini_lru_dsp
python3 $SVN/tools/args/gen_c_config.py -f gemini_lru_dsp

# set which version of Vivado to use, e.g. 2019.1
source /opt/Xilinx/Vivado/2019.1/settings64.sh

# 5. Run the setup project script
vivado -mode batch -source create_project.tcl

# 6. Open the project in vivado

