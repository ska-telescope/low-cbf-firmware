set componentName axi_apb_translate

if {[version -short] >= 2018.1} {
  # Only supported in Vivado 2018.1 or greater
  create_ip -name axi_apb_bridge -vendor xilinx.com -library ip -module_name $componentName
  set_property -dict [list CONFIG.C_M_APB_PROTOCOL {apb3} CONFIG.C_APB_NUM_SLAVES {1} CONFIG.C_ADDR_WIDTH {22} ] [get_ips $componentName]
  source $env(RADIOHDL)/libraries/technology/build_ip.tcl
}