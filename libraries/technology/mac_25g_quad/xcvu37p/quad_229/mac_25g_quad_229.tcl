set componentName mac_25g_quad_229
create_ip -name xxv_ethernet -vendor xilinx.com -library ip -module_name $componentName
set_property -dict [list CONFIG.NUM_OF_CORES {4} CONFIG.BASE_R_KR {BASE-R} CONFIG.ENABLE_DATAPATH_PARITY {0} CONFIG.GT_DRP_CLK {125} CONFIG.GT_GROUP_SELECT {Quad_X1Y5} CONFIG.LANE1_GT_LOC {X1Y20} CONFIG.LANE2_GT_LOC {X1Y21} CONFIG.LANE3_GT_LOC {X1Y22} CONFIG.LANE4_GT_LOC {X1Y23} CONFIG.ENABLE_PIPELINE_REG {1} CONFIG.ADD_GT_CNTRL_STS_PORTS {1}] [get_ips $componentName]
source $env(RADIOHDL)/libraries/technology/build_ip.tcl