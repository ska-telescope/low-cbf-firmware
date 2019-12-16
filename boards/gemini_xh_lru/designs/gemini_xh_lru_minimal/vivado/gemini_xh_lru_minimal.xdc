
#current_instance -quiet


set_property C_CLK_INPUT_FREQ_HZ 100000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_100]


####################################################################################
# Clock Crossing FFs
####################################################################################



# Led Inouts
set_property ASYNC_REG true [get_cells {u_led_driver/register_gen[?].colour_reg/gen_reg.shift_reg_reg*}]

# Reset logic
set_property ASYNC_REG true [get_cells {system_reset_shift*}]

####################################################################################
# Interclock constraints
####################################################################################


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

# Stuff to LEDs
set_max_delay 10 -from [get_clocks -of_objects [get_cells -hier -filter {NAME =~ u_led_pipe*}]] -to [get_clocks -of_objects [get_cells -hier -filter {NAME =~ u_led_driver*}]] -datapath_only -through [get_pins -of [get_cells -hier -filter {NAME =~ u_led_driver/register_gen*}] -filter {REF_PIN_NAME == D}]
set_max_delay 10 -from [get_clocks -of_objects [get_cells -hier -filter {NAME =~ u_cmac_led_reg*}]] -to [get_clocks -of_objects [get_cells -hier -filter {NAME =~ u_led_driver*}]] -datapath_only -through [get_pins -of [get_cells -hier -filter {NAME =~ u_led_driver/register_gen*}] -filter {REF_PIN_NAME == D}]
set_max_delay 10 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mace_mac*i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -to [get_clocks -of_objects [get_cells -hier -filter {NAME =~ u_led_driver*}]] -datapath_only -through [get_pins -of [get_cells -hier -filter {NAME =~ u_led_driver/register_gen*}] -filter {REF_PIN_NAME == D}]

# Other
set_max_delay 6.4 -from [get_clocks -of_objects [get_nets -hier -filter {NAME =~ clk_100}]] -to [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mace_mac*i_core_gtwiz_userclk_tx_inst*/* }] -filter {REF_PIN_NAME == O}]] -datapath_only
set_max_delay 6.4 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mace_mac*i_core_gtwiz_userclk_tx_inst*/* }]]] -to [get_clocks -of_objects [get_nets -hier -filter {NAME =~ clk_100}]] -datapath_only -through [get_pins -of [get_cells -hier -filter {NAME =~ eth_act_cross/din_meta_reg*}] -filter {REF_PIN_NAME == Q}]
set_max_delay 6.4 -from [get_clocks -of_objects [get_pins -of [get_cells -hier -filter {NAME =~  u_mace_mac*i_core_gtwiz_userclk_tx_inst*/* }]]] -to [get_clocks -of_objects [get_nets -hier -filter {NAME =~ clk_100}]] -datapath_only -through [get_cells -hier -filter {NAME =~ ddr4_support*}]


####################################################################################
# Location Constraints
####################################################################################


# Need i2c interface constraints



####################################################################################
# Area Constraints
####################################################################################
