 # Tcl to create the FIR coefficient memories for the correlator Filter Bank

set coepath [glob $env(RADIOHDL)libraries/signalProcessing/filterbanks/src/coe/]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name CFB_ROM1
set_property -dict [list CONFIG.Component_Name {CFB_ROM1} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/correlatorFIRTaps1.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips CFB_ROM1]
create_ip_run [get_ips CFB_ROM1]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name CFB_ROM2
set_property -dict [list CONFIG.Component_Name {CFB_ROM2} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/correlatorFIRTaps2.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips CFB_ROM2]
create_ip_run [get_ips CFB_ROM2]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name CFB_ROM3
set_property -dict [list CONFIG.Component_Name {CFB_ROM3} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/correlatorFIRTaps3.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips CFB_ROM3]
create_ip_run [get_ips CFB_ROM3]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name CFB_ROM4
set_property -dict [list CONFIG.Component_Name {CFB_ROM4} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/correlatorFIRTaps4.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips CFB_ROM4]
create_ip_run [get_ips CFB_ROM4]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name CFB_ROM5
set_property -dict [list CONFIG.Component_Name {CFB_ROM5} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/correlatorFIRTaps5.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips CFB_ROM5]
create_ip_run [get_ips CFB_ROM5]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name CFB_ROM6
set_property -dict [list CONFIG.Component_Name {CFB_ROM6} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/correlatorFIRTaps6.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips CFB_ROM6]
create_ip_run [get_ips CFB_ROM6]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name CFB_ROM7
set_property -dict [list CONFIG.Component_Name {CFB_ROM7} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/correlatorFIRTaps7.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips CFB_ROM7]
create_ip_run [get_ips CFB_ROM7]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name CFB_ROM8
set_property -dict [list CONFIG.Component_Name {CFB_ROM8} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/correlatorFIRTaps8.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips CFB_ROM8]
create_ip_run [get_ips CFB_ROM8]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name CFB_ROM9
set_property -dict [list CONFIG.Component_Name {CFB_ROM9} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/correlatorFIRTaps9.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips CFB_ROM9]
create_ip_run [get_ips CFB_ROM9]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name CFB_ROM10
set_property -dict [list CONFIG.Component_Name {CFB_ROM10} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/correlatorFIRTaps10.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips CFB_ROM10]
create_ip_run [get_ips CFB_ROM10]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name CFB_ROM11
set_property -dict [list CONFIG.Component_Name {CFB_ROM11} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/correlatorFIRTaps11.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips CFB_ROM11]
create_ip_run [get_ips CFB_ROM11]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name CFB_ROM12
set_property -dict [list CONFIG.Component_Name {CFB_ROM12} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {18} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {18} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {18} CONFIG.Read_Width_B {18} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$coepath/correlatorFIRTaps12.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips CFB_ROM12]
create_ip_run [get_ips CFB_ROM12]
