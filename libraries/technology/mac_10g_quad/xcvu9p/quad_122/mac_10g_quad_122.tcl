set componentName mac_10g_quad_122
create_ip -name xxv_ethernet -vendor xilinx.com -library ip -module_name $componentName
set_property -dict [list CONFIG.LINE_RATE {10} CONFIG.NUM_OF_CORES {4} CONFIG.BASE_R_KR {BASE-R} CONFIG.GT_DRP_CLK {125} CONFIG.GT_REF_CLK_FREQ {156.25} CONFIG.GT_GROUP_SELECT {Quad_X0Y3} CONFIG.LANE1_GT_LOC {X0Y12} CONFIG.LANE2_GT_LOC {X0Y13} CONFIG.LANE3_GT_LOC {X0Y14} CONFIG.LANE4_GT_LOC {X0Y15} CONFIG.ENABLE_PIPELINE_REG {1} CONFIG.ADD_GT_CNTRL_STS_PORTS {1} ] [get_ips $componentName]
source $env(RADIOHDL)/libraries/technology/build_ip.tcl