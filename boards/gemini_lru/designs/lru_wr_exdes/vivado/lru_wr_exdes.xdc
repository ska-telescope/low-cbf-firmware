
# For reset path
set_false_path -from [get_clocks clk_125m_ref] -to [get_clocks txoutclk_out[0]*]

set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_pins -hier -filter {NAME=~"cmp_xwrc_board_lru/cmp_xwrc_platform/gen_default_plls.gen_xcvu9p_default_plls.cmp_sys_clk_pll/clk_in1"}]
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets cmp_xwrc_board_lru/cmp_xwrc_platform/clk_125m_pllref_buf]
#disconnect_debug_port dbg_hub/clk
#connect_debug_port dbg_hub/clk [get_nets clk_sys_62m5]
#connect_debug_port dbg_hub/clk [get_nets clk_ref_125m]
#set_property clock_region X0Y7 [get_cells cmp_xwrc_board_lru/cmp_xwrc_platform/gen_phy_vu9p.cmp_gtx/U_BUF_TxOutClk]
#set_property clock_region X0Y7 [get_cells cmp_xwrc_board_lru/cmp_xwrc_platform/gen_phy_vu9p.cmp_gtx/U_BUF_RxRecClk]
#set_property clock_region X0Y7 [get_cells cmp_xwrc_board_lru/cmp_xwrc_platform/gen_phy_vu9p.cmp_gtx/BUFG_GT_SYNC_tx_inst]
#set_property clock_region X0Y7 [get_cells cmp_xwrc_board_lru/cmp_xwrc_platform/gen_phy_vu9p.cmp_gtx/BUFG_GT_SYNC_rx_inst]

