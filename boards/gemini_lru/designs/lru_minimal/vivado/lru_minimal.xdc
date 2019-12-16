
current_instance -quiet
set_property INTERNAL_VREF 0.84 [get_iobanks 63]
set_property INTERNAL_VREF 0.84 [get_iobanks 62]
set_property INTERNAL_VREF 0.84 [get_iobanks 61]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_100]

# All The reset clocks
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {clk_c_p[3]} ] -group [get_clocks -include_generated_clocks clk_h ]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {clk_c_p[4]} ] -group [get_clocks -include_generated_clocks clk_h ]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks clk_g_p] -group [get_clocks -include_generated_clocks clk_h ]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {mbo_a_clk_p[0]} ] -group [get_clocks -include_generated_clocks clk_h ]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {mbo_a_clk_p[1]} ] -group [get_clocks -include_generated_clocks clk_h ]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {mbo_a_clk_p[2]} ] -group [get_clocks -include_generated_clocks clk_h ]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {mbo_b_clk_p[0]} ] -group [get_clocks -include_generated_clocks clk_h ]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {mbo_b_clk_p[1]} ] -group [get_clocks -include_generated_clocks clk_h ]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {mbo_b_clk_p[2]} ] -group [get_clocks -include_generated_clocks clk_h ]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {mbo_c_clk_p[0]} ] -group [get_clocks -include_generated_clocks clk_h ]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {mbo_c_clk_p[1]} ] -group [get_clocks -include_generated_clocks clk_h ]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {mbo_c_clk_p[2]} ] -group [get_clocks -include_generated_clocks clk_h ]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks qsfp_a_clk_p ] -group [get_clocks -include_generated_clocks clk_h ]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks qsfp_c_clk_p ] -group [get_clocks -include_generated_clocks clk_h ]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks sfp_clk_c_p ] -group [get_clocks -include_generated_clocks clk_h ]

# MACE TX to RX clocking (for link status & startup)
set_clock_groups -name async_sfp -asynchronous -group [get_clocks -of_objects [get_pins {u_mace_mac/u_mace_mac/gen_ip_gemini_lru.quad120_3/inst/i_mac_10g_120_3_gt/inst/gen_gtwizard_gtye4_top.mac_10g_120_3_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]] \
                                               -group [get_clocks -of_objects [get_pins {u_mace_mac/u_mace_mac/gen_ip_gemini_lru.quad120_3/inst/i_mac_10g_120_3_gt/inst/gen_gtwizard_gtye4_top.mac_10g_120_3_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/RXOUTCLK}]]


####################################################################################
# Location Constraints
####################################################################################

set_property LOC SLICE_X112Y787 [get_cells pmbus_support/u_smbus/scl_oe_comma_reg_reg]
set_property LOC SLICE_X112Y785 [get_cells pmbus_support/u_smbus/sda_oe_reg_reg]

set_property LOC SLICE_X112Y556 [get_cells sfp_support/u_smbus/scl_oe_comma_reg_reg]
set_property LOC SLICE_X112Y548 [get_cells sfp_support/u_smbus/sda_oe_reg_reg]

set_property LOC SLICE_X112Y534 [get_cells qsfp_support/u_smbus/scl_oe_comma_reg_reg]
set_property LOC SLICE_X112Y518 [get_cells qsfp_support/u_smbus/sda_oe_reg_reg]

set_property LOC SLICE_X112Y786 [get_cells mbo_support/u_smbus/scl_oe_comma_reg_reg]
set_property LOC SLICE_X112Y784 [get_cells mbo_support/u_smbus/sda_oe_reg_reg]

set_property LOC SLICE_X112Y748 [get_cells humidity_support/u_smbus/scl_oe_comma_reg_reg]
set_property LOC SLICE_X112Y743 [get_cells humidity_support/u_smbus/sda_oe_reg_reg]

