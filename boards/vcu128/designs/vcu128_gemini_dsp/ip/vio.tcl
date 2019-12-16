set componentName vio_0
create_ip -name vio -vendor xilinx.com -library ip -module_name $componentName
set_property -dict [list CONFIG.C_PROBE_OUT2_WIDTH {48} CONFIG.C_PROBE_OUT1_WIDTH {32} CONFIG.C_PROBE_OUT0_WIDTH {32} CONFIG.C_NUM_PROBE_OUT {3} CONFIG.C_EN_PROBE_IN_ACTIVITY {0} CONFIG.C_NUM_PROBE_IN {0}] [get_ips $componentName]
source $env(RADIOHDL)/libraries/technology/build_ip.tcl