
connect_debug_port dbg_hub/clk [get_nets clk_125]


# Reset Paths
set_clock_groups -asynchronous -group clk_eth -group clk_100_system_clock
set_clock_groups -asynchronous -group clk_100_system_clock -group clk_eth

set_clock_groups -asynchronous -group clk_tx_eth -group clk_100_system_clock
set_clock_groups -asynchronous -group clk_100_system_clock -group clk_tx_eth





