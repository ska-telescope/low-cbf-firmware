set_property PACKAGE_PIN AT32 [get_ports {GPIOLED[0]}]
set_property PACKAGE_PIN AV34 [get_ports {GPIOLED[1]}]
set_property PACKAGE_PIN AY30 [get_ports {GPIOLED[2]}]
set_property PACKAGE_PIN BB32 [get_ports {GPIOLED[3]}]
set_property PACKAGE_PIN BF32 [get_ports {GPIOLED[4]}]
set_property PACKAGE_PIN AV36 [get_ports {GPIOLED[5]}]
set_property PACKAGE_PIN AY35 [get_ports {GPIOLED[6]}]
set_property PACKAGE_PIN BA37 [get_ports {GPIOLED[7]}]
set_property PACKAGE_PIN BC9 [get_ports CLK_p]

set_property PACKAGE_PIN AU23     [get_ports "USER_SI570_CLOCK_P"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L14P_T2L_N2_GC_84
set_property IOSTANDARD  LVDS_25 [get_ports "USER_SI570_CLOCK_P"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L14P_T2L_N2_GC_84
set_property PACKAGE_PIN AV23     [get_ports "USER_SI570_CLOCK_N"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L14N_T2L_N3_GC_84
set_property IOSTANDARD  LVDS_25 [get_ports "USER_SI570_CLOCK_N"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L14N_T2L_N3_GC_84

set_property IOSTANDARD LVCMOS12 [get_ports {GPIOLED[0]}]
set_property IOSTANDARD LVCMOS12 [get_ports {GPIOLED[1]}]
set_property IOSTANDARD LVCMOS12 [get_ports {GPIOLED[2]}]
set_property IOSTANDARD LVCMOS12 [get_ports {GPIOLED[3]}]
set_property IOSTANDARD LVCMOS12 [get_ports {GPIOLED[4]}]
set_property IOSTANDARD LVCMOS12 [get_ports {GPIOLED[5]}]
set_property IOSTANDARD LVCMOS12 [get_ports {GPIOLED[6]}]
set_property IOSTANDARD LVCMOS12 [get_ports {GPIOLED[7]}]
set_property IOSTANDARD LVDS [get_ports CLK_p]

set_property PACKAGE_PIN E34 [get_ports {GPIOSW[0]}] ;# N
set_property PACKAGE_PIN A10 [get_ports {GPIOSW[1]}] ;# E
set_property PACKAGE_PIN D9 [get_ports {GPIOSW[2]}]  ;# S
set_property PACKAGE_PIN M22 [get_ports {GPIOSW[3]}]  ;# W
set_property PACKAGE_PIN AW27 [get_ports {GPIOSW[4]}] ;# C

set_property IOSTANDARD LVCMOS12 [get_ports {GPIOSW[0]}]
set_property IOSTANDARD LVCMOS12 [get_ports {GPIOSW[1]}]
set_property IOSTANDARD LVCMOS12 [get_ports {GPIOSW[2]}]
set_property IOSTANDARD LVCMOS12 [get_ports {GPIOSW[3]}]
set_property IOSTANDARD LVCMOS12 [get_ports {GPIOSW[4]}]


