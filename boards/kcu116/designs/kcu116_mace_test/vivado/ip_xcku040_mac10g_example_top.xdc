
#------------------------------------------------------------------------------
#  (c) Copyright 2013 Xilinx, Inc. All rights reserved.
#
#  This file contains confidential and proprietary information
#  of Xilinx, Inc. and is protected under U.S. and
#  international copyright and other intellectual property
#  laws.
#
#  DISCLAIMER
#  This disclaimer is not a license and does not grant any
#  rights to the materials distributed herewith. Except as
#  otherwise provided in a valid license issued to you by
#  Xilinx, and to the maximum extent permitted by applicable
#  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
#  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
#  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
#  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
#  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
#  (2) Xilinx shall not be liable (whether in contract or tort,
#  including negligence, or under any other theory of
#  liability) for any loss or damage of any kind or nature
#  related to, arising under or in connection with these
#  materials, including for any direct, or any indirect,
#  special, incidental, or consequential loss or damage
#  (including loss of data, profits, goodwill, or any type of
#  loss or damage suffered as a result of any action brought
#  by a third party) even if such damage or loss was
#  reasonably foreseeable or Xilinx had been advised of the
#  possibility of the same.
#
#  CRITICAL APPLICATIONS
#  Xilinx products are not designed or intended to be fail-
#  safe, or for use in any application requiring fail-safe
#  performance, such as life-support or safety devices or
#  systems, Class III medical devices, nuclear facilities,
#  applications related to the deployment of airbags, or any
#  other applications that could lead to death, personal
#  injury, or severe property or environmental damage
#  (individually and collectively, "Critical
#  Applications"). Customer assumes the sole risk and
#  liability of any use of Xilinx products in Critical
#  Applications, subject only to applicable laws and
#  regulations governing limitations on product liability.
#
#  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
#  PART OF THIS FILE AT ALL TIMES.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# XXV_ETHERNET example design-level XDC file
# ----------------------------------------------------------------------------------------------------------------------
## init_clk should be lesser or equal to reference clock.
### Transceiver Reference Clock Placement
### Transceivers should be adjacent to allow timing constraints to be met easily. 
### Full details of available transceiver locations can be found
### in the appropriate transceiver User Guide, or use the Transceiver Wizard.
create_clock -period 8.000 [get_ports dclk_p]
set_property IOSTANDARD LVDS_25 [get_ports dclk_p]
set_property PACKAGE_PIN G12 [get_ports dclk_p]

# begin import from ibert design
##gth_refclk lock constraints
##
#set_property PACKAGE_PIN P6 [get_ports gth_refclk0p_i[0]]
#set_property PACKAGE_PIN P5 [get_ports gth_refclk0n_i[0]]
#set_property PACKAGE_PIN M6 [get_ports gth_refclk1p_i[0]]
#set_property PACKAGE_PIN M5 [get_ports gth_refclk1n_i[0]]
##
## Refclk constraints
##
#create_clock -name gth_refclk0_3 -period 6.4 [get_ports gth_refclk0p_i[0]]
#create_clock -name gth_refclk1_3 -period 6.4 [get_ports gth_refclk1p_i[0]]
#set_clock_groups -group [get_clocks gth_refclk0_3 -include_generated_clocks] -asynchronous
#set_clock_groups -group [get_clocks gth_refclk1_3 -include_generated_clocks] -asynchronous
#end import from ibert design


create_clock -period 6.400  [get_ports gt_refclk_p]
set_property PACKAGE_PIN P7 [get_ports gt_refclk_p]
### These are sample constraints, please use correct constraints for your device 
### update the gt_refclk pin location accordingly and un-comment the below two lines 
#set_property IOSTANDARD LVDS_25 [get_ports gt_refclk_p]
#set_property PACKAGE_PIN M25 [get_ports gt_refclk_p]
#set_property LOC M25 [get_ports gt_refclk_p]
  #set_property PACKAGE_PIN AK39 [get_ports gt_refclk_n]

###Board constraints to be added here
### Below XDC constraints are for VCU108 board with xcvu095-ffva2104-2-e-es2 device
### Change these constraints as per your board and device
#### Push Buttons
#set_property PACKAGE_PIN B9 [get_ports sys_reset]
#set_property IOSTANDARD LVCMOS33 [get_ports sys_reset]

#set_property LOC A10 [get_ports restart_tx_rx_0]
# GPIO_SW_C
#set_property PACKAGE_PIN A9 [get_ports restart_tx_rx_0]
#set_property IOSTANDARD LVCMOS33 [get_ports restart_tx_rx_0]

### LEDs
set_property PACKAGE_PIN C9 [get_ports link_led[0]]
set_property IOSTANDARD LVCMOS33 [get_ports link_led[0]]
##
set_property PACKAGE_PIN D9 [get_ports link_led[1]]
set_property IOSTANDARD LVCMOS33 [get_ports link_led[1]]
##
set_property PACKAGE_PIN E10 [get_ports completion_status[0]]
set_property IOSTANDARD LVCMOS33 [get_ports completion_status[0]]
##
set_property PACKAGE_PIN E11 [get_ports completion_status[1]]
set_property IOSTANDARD LVCMOS33 [get_ports completion_status[1]]
##
set_property PACKAGE_PIN F9 [get_ports completion_status[2]]
set_property IOSTANDARD LVCMOS33 [get_ports completion_status[2]]
##
set_property PACKAGE_PIN F10 [get_ports completion_status[3]]
set_property IOSTANDARD LVCMOS33 [get_ports completion_status[3]]
##
set_property PACKAGE_PIN G9 [get_ports completion_status[4]]
set_property IOSTANDARD LVCMOS33 [get_ports completion_status[4]]

### PUSH BUTTONS
set_property PACKAGE_PIN A9        [get_ports button[0]] ;# Center
set_property IOSTANDARD  LVCMOS33  [get_ports button[0]] ;# 
set_property PACKAGE_PIN B11       [get_ports button[1]] ;# East
set_property IOSTANDARD  LVCMOS33  [get_ports button[1]] ;# 
set_property PACKAGE_PIN C11       [get_ports button[2]] ;# South
set_property IOSTANDARD  LVCMOS33  [get_ports button[2]] ;# 
set_property PACKAGE_PIN B10       [get_ports button[3]] ;# West
set_property IOSTANDARD  LVCMOS33  [get_ports button[3]] ;# 
set_property PACKAGE_PIN A10       [get_ports button[4]] ;# North
set_property IOSTANDARD  LVCMOS33  [get_ports button[4]] ;# 





### Any other Constraints  
#set_false_path -to [get_pins -hierarchical -filter {NAME =~ *_pkt_gen_mon_*/*/*_cdc_to_reg*/D}]




#set_max_delay -from [get_clocks -of_objects [get_pins u_tech_mac_10g/u_tech_mac_10g_xcku040/DUT/inst/i_core_gtwiz_userclk_rx_inst_*/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O]] -to [get_clocks -of_objects [get_pins u_tech_mac_10g/u_tech_mac_10g_xcku040/DUT/inst/i_core_gtwiz_userclk_tx_inst_*/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O]] -datapath_only 6.40
#set_max_delay -from [get_clocks -of_objects [get_pins u_tech_mac_10g/u_tech_mac_10g_xcku040/DUT/inst/i_core_gtwiz_userclk_tx_inst_*/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O]] -to [get_clocks -of_objects [get_pins u_tech_mac_10g/u_tech_mac_10g_xcku040/DUT/inst/i_core_gtwiz_userclk_rx_inst_*/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O]] -datapath_only 6.40
#set_max_delay -from [get_clocks dclk_p] -to [get_clocks -of_objects [get_pins u_tech_mac_10g/u_tech_mac_10g_xcku040/DUT/inst/i_core_gtwiz_userclk_tx_inst_*/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O]] -datapath_only 8.000
#set_max_delay -from [get_clocks dclk_p] -to [get_clocks -of_objects [get_pins u_tech_mac_10g/u_tech_mac_10g_xcku040/DUT/inst/i_core_gtwiz_userclk_rx_inst_*/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O]] -datapath_only 8.000
#set_max_delay -from [get_clocks -of_objects [get_pins u_tech_mac_10g/u_tech_mac_10g_xcku040/DUT/inst/i_core_gtwiz_userclk_rx_inst_*/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O]] -to [get_clocks dclk_p] -datapath_only 6.40
#set_max_delay -from [get_clocks -of_objects [get_pins u_tech_mac_10g/u_tech_mac_10g_xcku040/DUT/inst/i_core_gtwiz_userclk_tx_inst_*/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O]] -to [get_clocks dclk_p] -datapath_only 6.40















