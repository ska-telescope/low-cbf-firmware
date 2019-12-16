set componentName mac_25g_quad_233
create_ip -name xxv_ethernet -vendor xilinx.com -library ip -module_name $componentName
set_property -dict [list CONFIG.NUM_OF_CORES {4} CONFIG.BASE_R_KR {BASE-R} CONFIG.GT_DRP_CLK {125} CONFIG.GT_GROUP_SELECT {Quad_X1Y14} CONFIG.LANE1_GT_LOC {X1Y56} CONFIG.LANE2_GT_LOC {X1Y57} CONFIG.LANE3_GT_LOC {X1Y58} CONFIG.LANE4_GT_LOC {X1Y59} CONFIG.ENABLE_PIPELINE_REG {1} CONFIG.ADD_GT_CNTRL_STS_PORTS {1}] [get_ips $componentName]
source $env(RADIOHDL)/libraries/technology/build_ip.tcl