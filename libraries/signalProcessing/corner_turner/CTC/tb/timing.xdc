
# 100 MHz
create_clock -period 10.000 -name i_mace_clk [get_ports i_mace_clk]

# 100 MHz
create_clock -period 10.000 -name i_apb_clk [get_ports i_apb_clk]

# 450 MHz
create_clock -period 2.222 -name i_hbm_clk [get_ports i_hbm_clk]

# 450 MHz
create_clock -period 2.220 -name i_input_clk [get_ports i_input_clk]

# 450 MHz
create_clock -period 2.217 -name i_output_clk [get_ports i_output_clk]


# CDC in MACE is a mess:
set_max_delay -datapath_only -from [get_clocks i_mace_clk] -to [get_clocks i_hbm_clk] 2.000
set_max_delay -datapath_only -from [get_clocks i_hbm_clk] -to [get_clocks i_mace_clk] 2.000
