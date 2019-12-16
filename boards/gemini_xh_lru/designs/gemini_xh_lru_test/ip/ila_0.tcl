set componentName ila_0
create_ip -name ila -vendor xilinx.com -library ip -module_name $componentName
set_property -dict [list CONFIG.ALL_PROBE_SAME_MU_CNT {10} CONFIG.C_ADV_TRIGGER {true} CONFIG.C_DATA_DEPTH {4096} CONFIG.C_EN_STRG_QUAL {1} CONFIG.C_INPUT_PIPE_STAGES {1} CONFIG.C_PROBE0_MU_CNT {10} CONFIG.C_PROBE0_WIDTH {200} ] [get_ips $componentName]
source $env(RADIOHDL)/libraries/technology/build_ip.tcl