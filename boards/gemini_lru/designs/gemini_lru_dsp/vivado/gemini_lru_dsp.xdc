
#current_instance -quiet


set_property C_CLK_INPUT_FREQ_HZ 100000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_100]


####################################################################################
# Clock Crossing FFs
####################################################################################



# For the traffic generators
set_property ASYNC_REG true [get_cells {*traffic_gen/i_core_cdc_sync_block_lock_syncer_gen*}]

# Led Inouts
set_property ASYNC_REG true [get_cells {u_led_driver/register_gen[?].colour_reg/gen_reg.shift_reg_reg*}]

# Reset logic
set_property ASYNC_REG true [get_cells {system_reset_shift*}]

####################################################################################
# Interclock constraints
####################################################################################

# TX to RX Paths within MBOs (Reset tree from TX logic to RX)
set_max_delay 2.56 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mb0a*quad*_gen*/inst/i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mb0a*quad*_gen*/inst/i_core_gtwiz_userclk_rx_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only -through [get_nets -hier -filter {NAME =~ u_mb0a*reset*}]
#set_max_delay 2.56 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mb0b*quad*_gen*/inst/i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mb0b*quad*_gen*/inst/i_core_gtwiz_userclk_rx_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only -through [get_nets -hier -filter {NAME =~ u_mb0b*reset*}]
#set_max_delay 2.56 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mb0c*quad*_gen*/inst/i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mb0c*quad*_gen*/inst/i_core_gtwiz_userclk_rx_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only -through [get_nets -hier -filter {NAME =~ u_mb0c*reset*}]

# RX/TX to TX paths within MBOs (Watchdog reset)
set_max_delay 2.56 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mb0a*quad*_gen*/inst/i_core_gtwiz_userclk_?x_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mb0a*quad*_gen*/inst/i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only -through [get_pins -of [get_cells -hier -filter {NAME =~ u_mb0a*master_watchdog*}] -filter {REF_PIN_NAME == O}]
#set_max_delay 2.56 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mb0b*quad*_gen*/inst/i_core_gtwiz_userclk_?x_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mb0b*quad*_gen*/inst/i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only -through [get_pins -of [get_cells -hier -filter {NAME =~ u_mb0b*master_watchdog*}] -filter {REF_PIN_NAME == O}]
#set_max_delay 2.56 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mb0c*quad*_gen*/inst/i_core_gtwiz_userclk_?x_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mb0c*quad*_gen*/inst/i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only -through [get_pins -of [get_cells -hier -filter {NAME =~ u_mb0c*master_watchdog*}] -filter {REF_PIN_NAME == O}]

# RX to TX paths with MBOs (FIFOs, status info, other signals)
set_max_delay 2.56 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mb0a*quad*_gen*/inst/i_core_gtwiz_userclk_rx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mb0a*quad*_gen*/inst/i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only
#set_max_delay 2.56 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mb0b*quad*_gen*/inst/i_core_gtwiz_userclk_rx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mb0b*quad*_gen*/inst/i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only
#set_max_delay 2.56 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mb0c*quad*_gen*/inst/i_core_gtwiz_userclk_rx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mb0c*quad*_gen*/inst/i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only

# QSFP TX to TX (Watchdog reset)
set_max_delay 2.56 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_qsfp_a*quad*_gen*/inst/i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_qsfp_a*quad*_gen*/inst/i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only -through [get_pins -of [get_cells -hier -filter {NAME =~ u_qsfp_a*master_watchdog*}] -filter {REF_PIN_NAME == O}]
set_max_delay 2.56 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_qsfp_b*quad*_gen*/inst/i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_qsfp_b*quad*_gen*/inst/i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only -through [get_pins -of [get_cells -hier -filter {NAME =~ u_qsfp_b*master_watchdog*}] -filter {REF_PIN_NAME == O}]


# M&C to Optics Status & Control Registers
set_max_delay 6.4 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mace_mac*i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  *quad*_gen*/inst/i_core_gtwiz_userclk_?x_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only -through [get_cells -hier -filter {NAME =~ *regs*}]
set_max_delay 6.4 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  *quad*_gen*/inst/i_core_gtwiz_userclk_?x_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mace_mac*i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only

set_max_delay 6.4 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mace_mac*i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  *quad*_gen*/inst/i_core_gtwiz_userclk_?x_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only -through [get_cells -hier -filter {NAME =~ mbo_support*}]
set_max_delay 6.4 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  *quad*_gen*/inst/i_core_gtwiz_userclk_rx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mace_mac*i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only

set_max_delay 6.4 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mace_mac*i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  *quad*_gen*/inst/i_core_gtwiz_userclk_?x_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only -through [get_cells -hier -filter {NAME =~ qsfp_support*}]
set_max_delay 6.4 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  *quad*_gen*/inst/i_core_gtwiz_userclk_rx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mace_mac*i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only

set_max_delay 6.4 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mace_mac*i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  *quad*_gen*/inst/cmac_gtwiz_userclk_?x_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only -through [get_cells -hier -filter {NAME =~ *regs*}]
set_max_delay 6.4 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  *quad*_gen*/inst/cmac_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mace_mac*i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only

#CMAC to Reset clock
set_max_delay 6.4 -from [get_clocks -of_objects [get_nets -hier -filter {NAME =~ clk_100}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  *quad*_gen*/inst/cmac_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only
set_max_delay 6.4 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  *quad*_gen*/inst/cmac_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_nets -hier -filter {NAME =~ clk_100}]] -datapath_only

# AXI Clock (MACE Stats registers rx clock to main tx reference)
set_max_delay 6.4 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mace_mac*i_core_gtwiz_userclk_rx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mace_mac*i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only
set_max_delay 6.4 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mace_mac*i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mace_mac*i_core_gtwiz_userclk_rx_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only

set_max_delay 5 -from [get_clocks clk_e_p] -to [get_clocks txoutclk_out[0]] -datapath_only
set_max_delay 5 -from [get_clocks txoutclk_out[0]] -to [get_clocks clk_e_p] -datapath_only

set_max_delay 6 -from [get_clocks txoutclk_out[0]_22] -to [get_clocks txoutclk_out[0]] -datapath_only
set_max_delay 6 -from [get_clocks txoutclk_out[0]] -to [get_clocks txoutclk_out[0]_22] -datapath_only

set_max_delay 6 -from [get_clocks txoutclk_out[0]_21] -to [get_clocks txoutclk_out[0]] -datapath_only
set_max_delay 6 -from [get_clocks txoutclk_out[0]] -to [get_clocks txoutclk_out[0]_21] -datapath_only

set_max_delay 6.4 -from [get_clocks txoutclk_out[0]] -to [get_clocks clk_100_system_clock] -datapath_only

set_max_delay 6 -from [get_clocks txoutclk_out[0]] -to [get_clocks clk_400_system_clock] -datapath_only
set_max_delay 6 -from [get_clocks clk_400_system_clock] -to [get_clocks txoutclk_out[0]] -datapath_only

# DDR4
#set_max_delay 6.4 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_ddr4*mmcme_adv_inst* }] -filter {REF_PIN_NAME == CLKOUT0}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mace_mac*i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only

# Stuff to LEDs
#set_max_delay 10 -from [get_clocks -of_objects [get_cells -hier -filter {NAME =~ u_led_pipe*}]] -to [get_clocks -of_objects [get_cells -hier -filter {NAME =~ u_led_driver*}]] -datapath_only -through [get_pins -of [get_cells -hier -filter {NAME =~ u_led_driver/register_gen*}] -filter {REF_PIN_NAME == D}]
set_max_delay 10 -from [get_clocks -of_objects [get_cells -hier -filter {NAME =~ u_cmac_led_reg*}]] -to [get_clocks -of_objects [get_cells -hier -filter {NAME =~ u_led_driver*}]] -datapath_only -through [get_pins -of [get_cells -hier -filter {NAME =~ u_led_driver/register_gen*}] -filter {REF_PIN_NAME == D}]
set_max_delay 10 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mb0a*quad*_gen*/inst/i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_cells -hier -filter {NAME =~ u_led_driver*}]] -datapath_only -through [get_pins -of [get_cells -hier -filter {NAME =~ u_led_driver/register_gen*}] -filter {REF_PIN_NAME == D}]
#set_max_delay 10 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mb0b*quad*_gen*/inst/i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_cells -hier -filter {NAME =~ u_led_driver*}]] -datapath_only -through [get_pins -of [get_cells -hier -filter {NAME =~ u_led_driver/register_gen*}] -filter {REF_PIN_NAME == D}]
#set_max_delay 10 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mb0c*quad*_gen*/inst/i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_cells -hier -filter {NAME =~ u_led_driver*}]] -datapath_only -through [get_pins -of [get_cells -hier -filter {NAME =~ u_led_driver/register_gen*}] -filter {REF_PIN_NAME == D}]
set_max_delay 10 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_qsfp_a*quad*_gen*/inst/i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_cells -hier -filter {NAME =~ u_led_driver*}]] -datapath_only -through [get_pins -of [get_cells -hier -filter {NAME =~ u_led_driver/register_gen*}] -filter {REF_PIN_NAME == D}]
set_max_delay 10 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_qsfp_b*quad*_gen*/inst/i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_cells -hier -filter {NAME =~ u_led_driver*}]] -datapath_only -through [get_pins -of [get_cells -hier -filter {NAME =~ u_led_driver/register_gen*}] -filter {REF_PIN_NAME == D}]
set_max_delay 10 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mace_mac*i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_cells -hier -filter {NAME =~ u_led_driver*}]] -datapath_only -through [get_pins -of [get_cells -hier -filter {NAME =~ u_led_driver/register_gen*}] -filter {REF_PIN_NAME == D}]

# Other
set_max_delay 6.4 -from [get_clocks -of_objects [get_nets -hier -filter {NAME =~ clk_100}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mace_mac*i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only
set_max_delay 6.4 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mace_mac*i_core_gtwiz_userclk_tx_inst*/* }]]] -to [get_clocks -of_objects [get_nets -hier -filter {NAME =~ clk_100}]] -datapath_only -through [get_pins -of [get_cells -hier -filter {NAME =~ eth_act_cross/din_meta_reg*}] -filter {REF_PIN_NAME == Q}]
set_max_delay 6.4 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mace_mac*i_core_gtwiz_userclk_tx_inst*/* }]]] -to [get_clocks -of_objects [get_nets -hier -filter {NAME =~ clk_100}]] -datapath_only -through [get_cells -hier -filter {NAME =~ ddr4_support*}]


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

#current_instance u_ddr4/gen_ip_gemini_lru.ddr4_1/inst
set_property LOC MMCM_X1Y3 [get_cells -hier -filter {NAME =~ */u_ddr4_infrastructure/gen_mmcme*.u_mmcme_adv_inst}]

####################################################################################
# Area Constraints
####################################################################################

#create_pblock pblock_u_mb0a_1
#add_cells_to_pblock [get_pblocks pblock_u_mb0a_1] [get_cells -quiet [list {pkt_gen[0].traffic_gen} {pkt_gen[10].traffic_gen} {pkt_gen[11].traffic_gen} {pkt_gen[1].traffic_gen} {pkt_gen[2].traffic_gen} {pkt_gen[3].traffic_gen} {pkt_gen[4].traffic_gen} {pkt_gen[5].traffic_gen} {pkt_gen[6].traffic_gen} {pkt_gen[7].traffic_gen} {pkt_gen[8].traffic_gen} {pkt_gen[9].traffic_gen} u_mb0a_1]]
#resize_pblock [get_pblocks pblock_u_mb0a_1] -add {SLICE_X118Y701:SLICE_X168Y899}

#create_pblock pblock_u_mb0b_1
#add_cells_to_pblock [get_pblocks pblock_u_mb0b_1] [get_cells -quiet [list {pkt_gen[12].traffic_gen} {pkt_gen[13].traffic_gen} {pkt_gen[14].traffic_gen} {pkt_gen[15].traffic_gen} {pkt_gen[16].traffic_gen} {pkt_gen[17].traffic_gen} {pkt_gen[18].traffic_gen} {pkt_gen[19].traffic_gen} {pkt_gen[20].traffic_gen} {pkt_gen[21].traffic_gen} {pkt_gen[22].traffic_gen} {pkt_gen[23].traffic_gen} u_mb0b_1]]
#resize_pblock [get_pblocks pblock_u_mb0b_1] -add {SLICE_X112Y300:SLICE_X168Y478}

#create_pblock pblock_u_mb0c_1
#add_cells_to_pblock [get_pblocks pblock_u_mb0c_1] [get_cells -quiet [list {pkt_gen[24].traffic_gen} {pkt_gen[25].traffic_gen} {pkt_gen[26].traffic_gen} {pkt_gen[27].traffic_gen} {pkt_gen[28].traffic_gen} {pkt_gen[29].traffic_gen} {pkt_gen[30].traffic_gen} {pkt_gen[31].traffic_gen} {pkt_gen[32].traffic_gen} {pkt_gen[33].traffic_gen} {pkt_gen[34].traffic_gen} {pkt_gen[35].traffic_gen} u_mb0c_1]]
#resize_pblock [get_pblocks pblock_u_mb0c_1] -add {SLICE_X118Y25:SLICE_X168Y239}

#create_pblock pblock_u_qsfp_a
#add_cells_to_pblock [get_pblocks pblock_u_qsfp_a] [get_cells -quiet [list u_mac_100g_pkt_gen_mon u_qsfp_a]]
#resize_pblock [get_pblocks pblock_u_qsfp_a] -add {SLICE_X0Y427:SLICE_X96Y569}

#create_pblock pblock_u_qsfp_b
#add_cells_to_pblock [get_pblocks pblock_u_qsfp_b] [get_cells -quiet [list u_qsfp_b]]
#resize_pblock [get_pblocks pblock_u_qsfp_b] -add {SLICE_X0Y300:SLICE_X96Y422}

#create_pblock pblock_u_qsfp_c
#add_cells_to_pblock [get_pblocks pblock_u_qsfp_c] [get_cells -quiet [list {pkt_gen[37].traffic_gen} {pkt_gen[38].traffic_gen} {pkt_gen[39].traffic_gen} {pkt_gen[40].traffic_gen} u_qsfp_c]]
#resize_pblock [get_pblocks pblock_u_qsfp_c] -add {SLICE_X0Y300:SLICE_X54Y358}

#create_pblock pblock_u_qsfp_d
#resize_pblock [get_pblocks pblock_u_qsfp_d] -add {SLICE_X0Y156:SLICE_X50Y255}
#add_cells_to_pblock [get_pblocks pblock_u_qsfp_d] [get_cells [list u_mac_40g_pkt_gen_mon u_qsfp_d]]

#create_pblock pblock_u_ddr4
#add_cells_to_pblock [get_pblocks pblock_u_ddr4] [get_cells -quiet [list u_ddr4 u_ddr4_v2_2_3_axi_tg_top]]
#resize_pblock [get_pblocks pblock_u_ddr4] -add {SLICE_X95Y59:SLICE_X116Y299}

# Make sure MACE MAC goes where it should be
create_pblock pblock_u_mace_mac
resize_pblock [get_pblocks pblock_u_mace_mac] -add {SLICE_X51Y168:SLICE_X104Y297 RAMB18_X4Y68:RAMB18_X6Y117 RAMB36_X4Y34:RAMB36_X6Y58 URAM288_X1Y48:URAM288_X2Y75}
add_cells_to_pblock pblock_u_mace_mac [get_cells [list u_mace_mac]]