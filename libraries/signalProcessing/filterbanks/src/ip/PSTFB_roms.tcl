set coepath [glob $env(RADIOHDL)libraries/signalProcessing/filterbanks/src/coe/]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSTFB_ROM1
set_property -dict [list CONFIG.Component_Name {PSTFB_ROM1} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSTFIRTaps1.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTFB_ROM1]
create_ip_run [get_ips PSTFB_ROM1]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSTFB_ROM2
set_property -dict [list CONFIG.Component_Name {PSTFB_ROM2} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSTFIRTaps2.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTFB_ROM2]
create_ip_run [get_ips PSTFB_ROM2]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSTFB_ROM3
set_property -dict [list CONFIG.Component_Name {PSTFB_ROM3} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSTFIRTaps3.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTFB_ROM3]
create_ip_run [get_ips PSTFB_ROM3]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSTFB_ROM4
set_property -dict [list CONFIG.Component_Name {PSTFB_ROM4} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSTFIRTaps4.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTFB_ROM4]
create_ip_run [get_ips PSTFB_ROM4]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSTFB_ROM5
set_property -dict [list CONFIG.Component_Name {PSTFB_ROM5} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSTFIRTaps5.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTFB_ROM5]
create_ip_run [get_ips PSTFB_ROM5]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSTFB_ROM6
set_property -dict [list CONFIG.Component_Name {PSTFB_ROM6} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSTFIRTaps6.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTFB_ROM6]
create_ip_run [get_ips PSTFB_ROM6]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSTFB_ROM7
set_property -dict [list CONFIG.Component_Name {PSTFB_ROM7} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSTFIRTaps7.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTFB_ROM7]
create_ip_run [get_ips PSTFB_ROM7]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSTFB_ROM8
set_property -dict [list CONFIG.Component_Name {PSTFB_ROM8} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSTFIRTaps8.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTFB_ROM8]
create_ip_run [get_ips PSTFB_ROM8]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSTFB_ROM9
set_property -dict [list CONFIG.Component_Name {PSTFB_ROM9} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSTFIRTaps9.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTFB_ROM9]
create_ip_run [get_ips PSTFB_ROM9]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSTFB_ROM10
set_property -dict [list CONFIG.Component_Name {PSTFB_ROM10} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSTFIRTaps10.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTFB_ROM10]
create_ip_run [get_ips PSTFB_ROM10]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSTFB_ROM11
set_property -dict [list CONFIG.Component_Name {PSTFB_ROM11} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSTFIRTaps11.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTFB_ROM11]
create_ip_run [get_ips PSTFB_ROM11]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name PSTFB_ROM12
set_property -dict [list CONFIG.Component_Name {PSTFB_ROM12} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/PSTFIRTaps12.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTFB_ROM12]
create_ip_run [get_ips PSTFB_ROM12]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSTFBReorderMem
set_property -dict [list CONFIG.Component_Name {PSTFBReorderMem} CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Write_Width_A {192} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {192} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {192} CONFIG.Read_Width_B {192} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Fill_Remaining_Memory_Locations {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTFBReorderMem]
create_ip_run [get_ips PSTFBReorderMem]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name PSTFBsdp512x96
set_property -dict [list CONFIG.Component_Name {PSTFBsdp512x96} CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Write_Width_A {96} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {96} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {96} CONFIG.Read_Width_B {96} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips PSTFBsdp512x96]
create_ip_run [get_ips PSTFBsdp512x96]
