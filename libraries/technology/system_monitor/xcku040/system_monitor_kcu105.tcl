set componentName system_monitor_kcu105
create_ip -name system_management_wiz -vendor xilinx.com -library ip -version 1.3 -module_name $componentName
set_property -dict [list CONFIG.INTERFACE_SELECTION {Enable_AXI} CONFIG.DCLK_FREQUENCY {156.25} CONFIG.ENABLE_RESET {false} CONFIG.ENABLE_VBRAM_ALARM {true} CONFIG.SENSOR_OFFSET_CALIBRATION {true} CONFIG.CHANNEL_ENABLE_VP_VN {false} CONFIG.CHANNEL_ENABLE_VAUXP0_VAUXN0 {true} CONFIG.CHANNEL_ENABLE_VAUXP2_VAUXN2 {true} CONFIG.CHANNEL_ENABLE_VAUXP8_VAUXN8 {true} CONFIG.AVERAGE_ENABLE_VAUXP0_VAUXN0 {true} CONFIG.AVERAGE_ENABLE_VAUXP2_VAUXN2 {true} CONFIG.AVERAGE_ENABLE_VAUXP8_VAUXN8 {true} CONFIG.ENABLE_TEMP_BUS {true}] [get_ips $componentName]
source $env(RADIOHDL)/libraries/technology/build_ip.tcl