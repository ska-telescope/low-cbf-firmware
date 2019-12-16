set componentName mac_40g_quad_130
create_ip -name l_ethernet -vendor xilinx.com -library ip -module_name $componentName
set_property -dict [list CONFIG.LINE_RATE {40} CONFIG.BASE_R_KR {BASE-R} CONFIG.GT_DRP_CLK {125} CONFIG.GT_REF_CLK_FREQ {156.25} CONFIG.GT_GROUP_SELECT {Quad_X0Y6} CONFIG.LANE1_GT_LOC {X0Y24} CONFIG.LANE2_GT_LOC {X0Y25} CONFIG.LANE3_GT_LOC {X0Y26} CONFIG.LANE4_GT_LOC {X0Y27} CONFIG.ENABLE_PIPELINE_REG {1} CONFIG.ADD_GT_CNTRL_STS_PORTS {1} CONFIG.INCLUDE_SHARED_LOGIC {1}] [get_ips $componentName]
source $env(RADIOHDL)/libraries/technology/build_ip.tcl