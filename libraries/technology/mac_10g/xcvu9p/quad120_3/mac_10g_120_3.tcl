set componentName mac_10g_120_3
create_ip -name xxv_ethernet -vendor xilinx.com -library ip -module_name $componentName
set_property -dict [list CONFIG.LINE_RATE {10} CONFIG.BASE_R_KR {BASE-R} CONFIG.ENABLE_TX_FLOW_CONTROL_LOGIC {1} CONFIG.ENABLE_RX_FLOW_CONTROL_LOGIC {1} CONFIG.ENABLE_TIME_STAMPING {1} CONFIG.GT_REF_CLK_FREQ {156.25} CONFIG.GT_DRP_CLK {125} CONFIG.GT_GROUP_SELECT {Quad_X0Y1} CONFIG.LANE1_GT_LOC {X0Y7} CONFIG.ENABLE_PIPELINE_REG {1} CONFIG.ADD_GT_CNTRL_STS_PORTS {1} ] [get_ips $componentName]
source $env(RADIOHDL)/libraries/technology/build_ip.tcl