
# file: ibert_ultrascale_gty_0.xdc
####################################################################################
##   ____  ____ 
##  /   /\/   /
## /___/  \  /    Vendor: Xilinx
## \   \   \/     Version : 2012.3
##  \   \         Application : IBERT Ultrascale
##  /   /         Filename : example_ibert_ultrascale_gty_0.xdc
## /___/   /\     
## \   \  /  \ 
##  \___\/\___\
##
##
## 
## Generated by Xilinx IBERT Ultrascale
##**************************************************************************
##
## Icon Constraints
##
create_clock -name D_CLK -period 3.75 [get_ports gty_sysclkp_i]
set_clock_groups -group [get_clocks D_CLK -include_generated_clocks] -asynchronous

set_property C_CLK_INPUT_FREQ_HZ 266670000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER true [get_debug_cores dbg_hub]
##
##Eye scan 
##
set_property ES_EYE_SCAN_EN TRUE [get_cells u_ibert_gty_core/inst/QUAD[*].u_q/CH[*].u_ch/u_gtye4_channel]
##
##gtrefclk lock constraints
##
set_property PACKAGE_PIN BB39 [get_ports gty_refclk0p_i[0]]
set_property PACKAGE_PIN BB40 [get_ports gty_refclk0n_i[0]]
set_property PACKAGE_PIN BA41 [get_ports gty_refclk1p_i[0]]
set_property PACKAGE_PIN BA42 [get_ports gty_refclk1n_i[0]]
##
## Refclk constraints
##
create_clock -name gtrefclk0_14 -period 6.401 [get_ports gty_refclk0p_i[0]]
create_clock -name gtrefclk1_14 -period 6.401 [get_ports gty_refclk1p_i[0]]
set_clock_groups -group [get_clocks gtrefclk0_14 -include_generated_clocks] -asynchronous
set_clock_groups -group [get_clocks gtrefclk1_14 -include_generated_clocks] -asynchronous
##
## System clock pin locs and timing constraints
##
set_property PACKAGE_PIN BC28 [get_ports gty_sysclkp_i]
set_property IOSTANDARD LVDS [get_ports gty_sysclkp_i]
##
## TX/RX out clock clock constraints
##
# GT X0Y56
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {u_ibert_gty_core/inst/QUAD[0].u_q/CH[0].u_ch/u_gtye4_channel/RXOUTCLK}] -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {u_ibert_gty_core/inst/QUAD[0].u_q/CH[0].u_ch/u_gtye4_channel/TXOUTCLK}] -include_generated_clocks]
# GT X0Y57
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {u_ibert_gty_core/inst/QUAD[0].u_q/CH[1].u_ch/u_gtye4_channel/RXOUTCLK}] -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {u_ibert_gty_core/inst/QUAD[0].u_q/CH[1].u_ch/u_gtye4_channel/TXOUTCLK}] -include_generated_clocks]
# GT X0Y58
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {u_ibert_gty_core/inst/QUAD[0].u_q/CH[2].u_ch/u_gtye4_channel/RXOUTCLK}] -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {u_ibert_gty_core/inst/QUAD[0].u_q/CH[2].u_ch/u_gtye4_channel/TXOUTCLK}] -include_generated_clocks]
# GT X0Y59
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {u_ibert_gty_core/inst/QUAD[0].u_q/CH[3].u_ch/u_gtye4_channel/RXOUTCLK}] -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {u_ibert_gty_core/inst/QUAD[0].u_q/CH[3].u_ch/u_gtye4_channel/TXOUTCLK}] -include_generated_clocks]


set_property PACKAGE_PIN H29 [get_ports ptp_clk_sel]
set_property IOSTANDARD LVCMOS18 [get_ports ptp_clk_sel]

set_property PACKAGE_PIN H30 [get_ports sfp_led]
set_property IOSTANDARD LVCMOS18 [get_ports sfp_led]
set_property PACKAGE_PIN G30 [get_ports sfp_mod_abs]
set_property IOSTANDARD LVCMOS18 [get_ports sfp_mod_abs]
set_property PACKAGE_PIN D30 [get_ports sfp_tx_enable]
set_property IOSTANDARD LVCMOS18 [get_ports sfp_tx_enable]

set_property PACKAGE_PIN U19 [get_ports mbo_a_reset]
set_property PACKAGE_PIN V19 [get_ports mbo_b_reset]
set_property PACKAGE_PIN T19 [get_ports mbo_c_reset]
set_property IOSTANDARD LVCMOS18 [get_ports mbo_a_reset]
set_property IOSTANDARD LVCMOS18 [get_ports mbo_b_reset]
set_property IOSTANDARD LVCMOS18 [get_ports mbo_c_reset]