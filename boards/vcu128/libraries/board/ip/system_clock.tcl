create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name system_clock
set_property -dict [list CONFIG.Component_Name {system_clock} CONFIG.PRIMITIVE {Auto} CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} CONFIG.CLKOUT2_USED {true} CONFIG.CLKOUT3_USED {true} CONFIG.CLK_OUT1_PORT {clk_100} CONFIG.CLK_OUT2_PORT {clk_125} CONFIG.CLK_OUT3_PORT {clk_50} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {125.000} CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {50.000} CONFIG.USE_LOCKED {true} CONFIG.CLKOUT1_DRIVES {Buffer} CONFIG.CLKOUT2_DRIVES {Buffer} CONFIG.CLKOUT3_DRIVES {Buffer} CONFIG.CLKOUT4_DRIVES {Buffer} CONFIG.CLKOUT5_DRIVES {Buffer} CONFIG.CLKOUT6_DRIVES {Buffer} CONFIG.CLKOUT7_DRIVES {Buffer} CONFIG.FEEDBACK_SOURCE {FDBK_AUTO} CONFIG.USE_RESET {false} CONFIG.MMCM_BANDWIDTH {OPTIMIZED} CONFIG.MMCM_CLKFBOUT_MULT_F {10} CONFIG.MMCM_COMPENSATION {AUTO} CONFIG.MMCM_CLKOUT0_DIVIDE_F {10} CONFIG.MMCM_CLKOUT1_DIVIDE {8} CONFIG.MMCM_CLKOUT2_DIVIDE {20} CONFIG.NUM_OUT_CLKS {3} CONFIG.CLKOUT1_JITTER {130.958} CONFIG.CLKOUT1_PHASE_ERROR {98.575} CONFIG.CLKOUT2_JITTER {125.247} CONFIG.CLKOUT2_PHASE_ERROR {98.575} CONFIG.CLKOUT3_JITTER {151.636} CONFIG.CLKOUT3_PHASE_ERROR {98.575} CONFIG.AUTO_PRIMITIVE {PLL}] [get_ips system_clock]
create_ip_run [get_ips system_clock]

create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name pll_hbm
set_property -dict [list CONFIG.Component_Name {pll_hbm} CONFIG.PRIMITIVE {Auto} CONFIG.PRIM_SOURCE {Global_buffer} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {400.000} CONFIG.CLKOUT1_DRIVES {Buffer} CONFIG.CLKOUT2_DRIVES {Buffer} CONFIG.CLKOUT3_DRIVES {Buffer} CONFIG.CLKOUT4_DRIVES {Buffer} CONFIG.CLKOUT5_DRIVES {Buffer} CONFIG.CLKOUT6_DRIVES {Buffer} CONFIG.CLKOUT7_DRIVES {Buffer} CONFIG.FEEDBACK_SOURCE {FDBK_AUTO} CONFIG.USE_LOCKED {false} CONFIG.USE_RESET {false} CONFIG.MMCM_BANDWIDTH {OPTIMIZED} CONFIG.MMCM_CLKFBOUT_MULT_F {8} CONFIG.MMCM_COMPENSATION {AUTO} CONFIG.MMCM_CLKOUT0_DIVIDE_F {2} CONFIG.CLKOUT1_JITTER {111.164} CONFIG.CLKOUT1_PHASE_ERROR {114.212} CONFIG.AUTO_PRIMITIVE {PLL}] [get_ips pll_hbm]
create_ip_run [get_ips pll_hbm]

create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name wall_clk_pll
set_property -dict [list CONFIG.Component_Name {wall_clk_pll} CONFIG.PRIMITIVE {Auto} CONFIG.PRIM_SOURCE {Global_buffer} CONFIG.PRIM_IN_FREQ {125.000} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {250.000} CONFIG.CLKIN1_JITTER_PS {80.0} CONFIG.CLKOUT1_DRIVES {Buffer} CONFIG.CLKOUT2_DRIVES {Buffer} CONFIG.CLKOUT3_DRIVES {Buffer} CONFIG.CLKOUT4_DRIVES {Buffer} CONFIG.CLKOUT5_DRIVES {Buffer} CONFIG.CLKOUT6_DRIVES {Buffer} CONFIG.CLKOUT7_DRIVES {Buffer} CONFIG.FEEDBACK_SOURCE {FDBK_AUTO} CONFIG.USE_LOCKED {false} CONFIG.USE_RESET {false} CONFIG.MMCM_DIVCLK_DIVIDE {1} CONFIG.MMCM_BANDWIDTH {OPTIMIZED} CONFIG.MMCM_CLKFBOUT_MULT_F {6} CONFIG.MMCM_CLKIN1_PERIOD {8.0} CONFIG.MMCM_CLKIN2_PERIOD {10.0} CONFIG.MMCM_COMPENSATION {AUTO} CONFIG.MMCM_CLKOUT0_DIVIDE_F {3} CONFIG.CLKOUT1_JITTER {112.962} CONFIG.CLKOUT1_PHASE_ERROR {112.379} CONFIG.AUTO_PRIMITIVE {PLL}] [get_ips wall_clk_pll]
create_ip_run [get_ips wall_clk_pll]
