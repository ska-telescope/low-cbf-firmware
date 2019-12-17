set ip_name "ip_<lib>_<name>_fifo" 
if {$ip_name ni [get_ips]} { 
create_ip -name axi_fifo_mm_s -vendor xilinx.com -library ip -module_name ip_<lib>_<name>_fifo -dir "$proj_dir/"
set_property -dict [list \
CONFIG.C_S_AXI_ID_WIDTH {4} \
CONFIG.C_DATA_INTERFACE_TYPE {1} \
CONFIG.C_S_AXI4_DATA_WIDTH {32} \
CONFIG.C_USE_TX_DATA {<WO>} \
CONFIG.C_USE_TX_CTRL {false} \
CONFIG.C_USE_TX_CUT_THROUGH {false} \
CONFIG.C_TX_FIFO_DEPTH {<nof_dat>} \
CONFIG.C_TX_FIFO_PF_THRESHOLD {<FTHRESHOLD>} \
CONFIG.C_TX_FIFO_PE_THRESHOLD {<ETHRESHOLD>} \
CONFIG.C_USE_RX_DATA {<RO>} \
CONFIG.C_USE_RX_CUT_THROUGH {false} \
CONFIG.C_RX_FIFO_DEPTH {<nof_dat>} \
CONFIG.C_RX_FIFO_PF_THRESHOLD {<FTHRESHOLD>} \
CONFIG.C_RX_FIFO_PE_THRESHOLD {<ETHRESHOLD>} \
CONFIG.C_HAS_AXIS_TUSER {false} \
CONFIG.C_HAS_AXIS_TID {false} \
CONFIG.C_HAS_AXIS_TDEST {false} \
CONFIG.C_AXIS_TID_WIDTH {4} \
CONFIG.C_AXIS_TUSER_WIDTH {4} \
CONFIG.C_AXIS_TDEST_WIDTH {4} \
CONFIG.C_HAS_AXIS_TSTRB {false} \
CONFIG.C_HAS_AXIS_TKEEP {false}] [get_ips ip_<lib>_<name>_fifo]
}