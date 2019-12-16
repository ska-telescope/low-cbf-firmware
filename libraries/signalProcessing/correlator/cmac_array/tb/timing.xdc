

# 450 MHz
create_clock -period 2.222 -name i_cturn_clk [get_ports i_cturn_clk]

# 450 MHz
create_clock -period 2.220 -name i_cmac_clk [get_ports i_cmac_clk]

# CDC in retimer:
set_false_path -from [get_pins {*/*/tx_data_false_path_from_anchor_reg[*]/C}] -to [get_pins {*/*/retime_slv_rx_data_false_path_to_anchor_reg[*]/D}]