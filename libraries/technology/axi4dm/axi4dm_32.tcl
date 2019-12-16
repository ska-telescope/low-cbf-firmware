set componentName axi4dm_32
create_ip -name axi_datamover -vendor xilinx.com -library ip -module_name $componentName
set_property -dict [list CONFIG.c_mm2s_burst_size {128} CONFIG.c_s2mm_burst_size {128} CONFIG.c_mm2s_include_sf {false} CONFIG.c_s2mm_include_sf {false} CONFIG.c_m_axi_mm2s_id_width {1} CONFIG.c_m_axi_s2mm_id_width {1}] [get_ips $componentName]
source $env(RADIOHDL)/libraries/technology/build_ip.tcl
