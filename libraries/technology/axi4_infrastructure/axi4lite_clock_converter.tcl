set componentName axi4lite_clock_converter
create_ip -name axi_clock_converter -vendor xilinx.com -library ip -module_name $componentName
set_property -dict [list CONFIG.PROTOCOL {AXI4LITE} CONFIG.DATA_WIDTH {32} CONFIG.ID_WIDTH {0} CONFIG.AWUSER_WIDTH {0} CONFIG.ARUSER_WIDTH {0} CONFIG.RUSER_WIDTH {0} CONFIG.WUSER_WIDTH {0} CONFIG.BUSER_WIDTH {0}] [get_ips $componentName]
source $env(RADIOHDL)/libraries/technology/build_ip.tcl