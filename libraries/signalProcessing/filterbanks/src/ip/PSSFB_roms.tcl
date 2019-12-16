set coepath [glob $env(RADIOHDL)libraries/signalProcessing/filterbanks/src/coe/]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSSFB_ROM1
set_property -dict [list CONFIG.Component_Name {PSSFB_ROM1} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSSFIRTaps1.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSFB_ROM1]
create_ip_run [get_ips PSSFB_ROM1]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSSFB_ROM2
set_property -dict [list CONFIG.Component_Name {PSSFB_ROM2} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSSFIRTaps2.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSFB_ROM2]
create_ip_run [get_ips PSSFB_ROM2]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSSFB_ROM3
set_property -dict [list CONFIG.Component_Name {PSSFB_ROM3} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSSFIRTaps3.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSFB_ROM3]
create_ip_run [get_ips PSSFB_ROM3]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSSFB_ROM4
set_property -dict [list CONFIG.Component_Name {PSSFB_ROM4} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSSFIRTaps4.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSFB_ROM4]
create_ip_run [get_ips PSSFB_ROM4]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSSFB_ROM5
set_property -dict [list CONFIG.Component_Name {PSSFB_ROM5} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSSFIRTaps5.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSFB_ROM5]
create_ip_run [get_ips PSSFB_ROM5]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSSFB_ROM6
set_property -dict [list CONFIG.Component_Name {PSSFB_ROM6} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSSFIRTaps6.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSFB_ROM6]
create_ip_run [get_ips PSSFB_ROM6]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSSFB_ROM7
set_property -dict [list CONFIG.Component_Name {PSSFB_ROM7} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSSFIRTaps7.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSFB_ROM7]
create_ip_run [get_ips PSSFB_ROM7]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSSFB_ROM8
set_property -dict [list CONFIG.Component_Name {PSSFB_ROM8} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSSFIRTaps8.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSFB_ROM8]
create_ip_run [get_ips PSSFB_ROM8]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSSFB_ROM9
set_property -dict [list CONFIG.Component_Name {PSSFB_ROM9} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSSFIRTaps9.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSFB_ROM9]
create_ip_run [get_ips PSSFB_ROM9]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSSFB_ROM10
set_property -dict [list CONFIG.Component_Name {PSSFB_ROM10} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSSFIRTaps10.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSFB_ROM10]
create_ip_run [get_ips PSSFB_ROM10]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSSFB_ROM11
set_property -dict [list CONFIG.Component_Name {PSSFB_ROM11} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSSFIRTaps11.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSFB_ROM11]
create_ip_run [get_ips PSSFB_ROM11]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSSFB_ROM12
set_property -dict [list CONFIG.Component_Name {PSSFB_ROM12} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSSFIRTaps12.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSFB_ROM12]
create_ip_run [get_ips PSSFB_ROM12]

create_ip -name dist_mem_gen -vendor xilinx.com -library ip -version 8.0 -module_name PSSFBdr64 
set_property -dict [list CONFIG.data_width {96} CONFIG.Component_Name {PSSFBdr64} CONFIG.memory_type {simple_dual_port_ram} CONFIG.output_options {registered} CONFIG.common_output_clk {true}] [get_ips PSSFBdr64]
create_ip_run [get_ips PSSFBdr64]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSSFBReorderMem
set_property -dict [list CONFIG.Component_Name {PSSFBReorderMem} CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Write_Width_A {192} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {192} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {192} CONFIG.Read_Width_B {192} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Fill_Remaining_Memory_Locations {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSSFBReorderMem]
create_ip_run [get_ips PSSFBReorderMem]
