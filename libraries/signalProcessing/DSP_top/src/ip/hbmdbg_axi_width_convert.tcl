create_ip -name axi_dwidth_converter -vendor xilinx.com -library ip -version 2.1 -module_name hbmdbg_axi_width_convert -dir "$proj_dir/"
set_property -dict [list CONFIG.MI_DATA_WIDTH {256} CONFIG.FIFO_MODE {2} CONFIG.ACLK_ASYNC {1}] [get_ips hbmdbg_axi_width_convert]
create_ip_run [get_ips hbmdbg_axi_width_convert]