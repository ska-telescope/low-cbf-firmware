set componentName mac_25g_quad_230
create_ip -name xxv_ethernet -vendor xilinx.com -library ip -module_name $componentName
set_property -dict [list CONFIG.NUM_OF_CORES {4} CONFIG.BASE_R_KR {BASE-R} CONFIG.ENABLE_DATAPATH_PARITY {0} CONFIG.GT_DRP_CLK {125} CONFIG.GT_GROUP_SELECT {Quad_X1Y6} CONFIG.LANE1_GT_LOC {X1Y24} CONFIG.LANE2_GT_LOC {X1Y25} CONFIG.LANE3_GT_LOC {X1Y26} CONFIG.LANE4_GT_LOC {X1Y27} CONFIG.ENABLE_PIPELINE_REG {1} CONFIG.ADD_GT_CNTRL_STS_PORTS {1}] [get_ips $componentName]
source $env(RADIOHDL)/libraries/technology/build_ip.tcl