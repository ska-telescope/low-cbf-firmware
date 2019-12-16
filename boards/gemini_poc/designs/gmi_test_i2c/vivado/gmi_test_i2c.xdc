create_clock -period 8.000 -name clk_e -waveform {0.000 4.000} [get_ports clk_e_p]
#create_clock -period 6.400 -name clk_e -waveform {0.000 3.200} [get_ports clk_b_p]

set_property BITSTREAM.GENERAL.COMPRESS FALSE [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 5.3 [current_design]

set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN DISABLE [current_design]

set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [current_design]

set_property BITSTREAM.CONFIG.PERSIST YES [current_design]

set_property CONFIG_MODE SPIx1 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 1 [current_design]



# ila:

create_debug_core u_ila_0_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0_0]
set_property C_DATA_DEPTH 131072 [get_debug_cores u_ila_0_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0_0]
set_property port_width 1 [get_debug_ports u_ila_0_0/clk]
connect_debug_port u_ila_0_0/clk [get_nets [list u_gmi_board_clk125_pll/u_pll/gen_ip_xcvu9p.u0/inst/clk_out1]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0_0/probe0]
set_property port_width 1 [get_debug_ports u_ila_0_0/probe0]
connect_debug_port u_ila_0_0/probe0 [get_nets [list u_mms_gmi_board_sens/mm_start]]
create_debug_port u_ila_0_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0_0/probe1]
set_property port_width 1 [get_debug_ports u_ila_0_0/probe1]
connect_debug_port u_ila_0_0/probe1 [get_nets [list u_mms_gmi_board_sens/u_gmi_board_sens/u_i2c_smbus/scl_i]]
create_debug_port u_ila_0_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0_0/probe2]
set_property port_width 1 [get_debug_ports u_ila_0_0/probe2]
connect_debug_port u_ila_0_0/probe2 [get_nets [list u_mms_gmi_board_sens/u_gmi_board_sens/u_i2c_smbus/scl_o]]
create_debug_port u_ila_0_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0_0/probe3]
set_property port_width 1 [get_debug_ports u_ila_0_0/probe3]
connect_debug_port u_ila_0_0/probe3 [get_nets [list u_mms_gmi_board_sens/u_gmi_board_sens/u_i2c_smbus/sda_i]]
create_debug_port u_ila_0_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0_0/probe4]
set_property port_width 1 [get_debug_ports u_ila_0_0/probe4]
connect_debug_port u_ila_0_0/probe4 [get_nets [list u_mms_gmi_board_sens/u_gmi_board_sens/u_i2c_smbus/sda_o]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets mm_clk]

