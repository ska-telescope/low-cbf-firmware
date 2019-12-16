########################
# PINS
########################

#CLOCKS
set_property PACKAGE_PIN K23 [get_ports "SYSCLK_300_N"] ;
set_property IOSTANDARD DIFF_SSTL12 [get_ports "SYSCLK_300_N"] ;
set_property PACKAGE_PIN K22 [get_ports "SYSCLK_300_P"] ;
set_property IOSTANDARD DIFF_SSTL12 [get_ports "SYSCLK_300_P"] ;

#GPIO LEDs
set_property PACKAGE_PIN C9 [get_ports "o_led[0]"] ;
set_property IOSTANDARD LVCMOS33 [get_ports "o_led[0]"] ;
set_property PACKAGE_PIN D9 [get_ports "o_led[1]"] ;
set_property IOSTANDARD LVCMOS33 [get_ports "o_led[1]"] ;
set_property PACKAGE_PIN E10 [get_ports "o_led[2]"] ;
set_property IOSTANDARD LVCMOS33 [get_ports "o_led[2]"] ;
set_property PACKAGE_PIN E11 [get_ports "o_led[3]"] ;
set_property IOSTANDARD LVCMOS33 [get_ports "o_led[3]"] ;
set_property PACKAGE_PIN F9 [get_ports "o_led[4]"] ;
set_property IOSTANDARD LVCMOS33 [get_ports "o_led[4]"] ;
set_property PACKAGE_PIN F10 [get_ports "o_led[5]"] ;
set_property IOSTANDARD LVCMOS33 [get_ports "o_led[5]"] ;
set_property PACKAGE_PIN G9 [get_ports "o_led[6]"] ;
set_property IOSTANDARD LVCMOS33 [get_ports "o_led[6]"] ;
set_property PACKAGE_PIN G10 [get_ports "o_led[7]"] ;
set_property IOSTANDARD LVCMOS33 [get_ports "o_led[7]"] ;

