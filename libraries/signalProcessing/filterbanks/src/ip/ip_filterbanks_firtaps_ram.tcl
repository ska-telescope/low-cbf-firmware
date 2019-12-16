create_ip -name axi_bram_ctrl -vendor xilinx.com -library ip -version 4.1 -module_name ip_filterbanks_firtaps_axi_a -dir "$proj_dir/"
set_property -dict [list CONFIG.DATA_WIDTH {32} \
 CONFIG.SINGLE_PORT_BRAM {1} \
 CONFIG.MEM_DEPTH {65536} \
 CONFIG.ECC_TYPE {0} \
 CONFIG.READ_LATENCY {5} \
] [get_ips ip_filterbanks_firtaps_axi_a]

