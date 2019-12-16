set componentName ila_2
create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name $componentName
set_property -dict [list CONFIG.C_ADV_TRIGGER {true} CONFIG.C_PROBE3_WIDTH {3} CONFIG.C_PROBE2_WIDTH {8} CONFIG.C_PROBE0_WIDTH {33} CONFIG.C_NUM_OF_PROBES {12}] [get_ips $componentName]
source $env(RADIOHDL)/libraries/technology/build_ip.tcl
