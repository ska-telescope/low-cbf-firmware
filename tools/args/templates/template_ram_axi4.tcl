set ip_name "ip_<lib>_<name>_bram"
if {$ip_name ni [get_ips]} { 
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name ip_<lib>_<name>_bram -dir "$proj_dir/"
set_property -dict [list CONFIG.Memory_Type {True_Dual_Port_RAM} \
 CONFIG.Enable_32bit_Address {false} \
 CONFIG.Write_Depth_A {<nof_dat>} \
 CONFIG.Fill_Remaining_Memory_Locations {true} \
 CONFIG.Remaining_Memory_Locations {<default>} \
 CONFIG.Use_Byte_Write_Enable {true} \
 CONFIG.Byte_Size {8} \
 CONFIG.Write_Width_A {<dat_w>} \
 CONFIG.Write_Width_B {<dat_wb>} \
 CONFIG.Read_Width_A {<dat_w>} \
 CONFIG.Read_Width_B {<dat_wb>} \
 CONFIG.Enable_B {Use_ENB_Pin} \
 CONFIG.Register_PortB_Output_of_Memory_Primitives {true} \
 CONFIG.Use_RSTA_Pin {true} \
 CONFIG.Use_RSTB_Pin {true} \
 CONFIG.Load_Init_File {true} \
 CONFIG.Coe_File {<coe_file>} \
 CONFIG.Port_B_Clock {100} \
 CONFIG.Port_B_Write_Rate {50} \
 CONFIG.Port_B_Enable_Rate {100} \
] [get_ips ip_<lib>_<name>_bram]
}
set ip_name "ip_<lib>_<name>_axi_a"
if {$ip_name ni [get_ips]} { 
create_ip -name axi_bram_ctrl -vendor xilinx.com -library ip -version 4.1 -module_name ip_<lib>_<name>_axi_a -dir "$proj_dir/"
set_property -dict [list CONFIG.DATA_WIDTH {<dat_w>} \
 CONFIG.SINGLE_PORT_BRAM {1} \
 CONFIG.MEM_DEPTH {<nof_dat_by_slaves>} \
 CONFIG.ECC_TYPE {0} \
 CONFIG.READ_LATENCY {2} \
] [get_ips ip_<lib>_<name>_axi_a]


create_ip -name axi_bram_ctrl -vendor xilinx.com -library ip -version 4.1 -module_name ip_<lib>_<name>_axi_b -dir "$proj_dir/"
set_property -dict [list CONFIG.DATA_WIDTH {<dat_wb>} \
 CONFIG.SINGLE_PORT_BRAM {1} \
 CONFIG.MEM_DEPTH {<nof_datb>} \
 CONFIG.ECC_TYPE {0} \
 CONFIG.READ_LATENCY {2} \
] [get_ips ip_<lib>_<name>_axi_b]
}
