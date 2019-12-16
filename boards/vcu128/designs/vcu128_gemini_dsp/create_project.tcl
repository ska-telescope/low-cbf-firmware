set time_raw [clock seconds];
set date_string [clock format $time_raw -format "%y%m%d_%H%M%S"]

set proj_dir "$env(RADIOHDL)/build/vcu128/vivado/vcu128_gemini_dsp/vcu128_gemini_dsp_build_$date_string"
set ARGS_PATH "$env(RADIOHDL)/build/ARGS/vcu128_gemini_dsp"
set BOARD_PATH "$env(RADIOHDL)/boards/vcu128/libraries/board"
set DEVICE "xcvu37p-fsvh2892-2L-e-es1"
set BOARD ""

# Create the new build directory
puts "Creating build_directory $proj_dir"
file mkdir $proj_dir

# This script sets the project variables
puts "Creating new project: vcu128_gemini_dsp"
cd $proj_dir

set workingDir [pwd]
puts "Working directory:"
puts $workingDir

# WARNING - proj_dir must be relative to workingDir.
# But cannot be empty because args generates tcl with the directory specified as "$proj_dir/"
set proj_dir "../vcu128_gemini_dsp_build_$date_string"


create_project vcu128_gemini_dsp -part $DEVICE -force
set_property board_part $BOARD [current_project]
set_property target_language VHDL [current_project]
set_property target_simulator XSim [current_project]

############################################################
# Board specific files
############################################################
add_files -fileset sources_1 [glob \
$BOARD_PATH/src/vhdl/i2c_addresses_pkg.vhd \
$BOARD_PATH/src/vhdl/board_pkg.vhd \
$BOARD_PATH/src/vhdl/qsfp_control.vhd \
$BOARD_PATH/src/vhdl/qsfp_25g.vhd \
$BOARD_PATH/src/vhdl/qsfp_40g.vhd \
$BOARD_PATH/src/vhdl/qsfp_100g.vhd \
$BOARD_PATH/src/vhdl/uptime_counter.vhd \
$BOARD_PATH/src/vhdl/mace_mac.vhd \
$BOARD_PATH/ip/ip_pkg.vhd \
]

set_property library vcu128_board_lib [get_files {\
*boards/vcu128/libraries/board/src/vhdl/i2c_addresses_pkg.vhd \
*boards/vcu128/libraries/board/src/vhdl/board_pkg.vhd \
*boards/vcu128/libraries/board/src/vhdl/qsfp_control.vhd \
*boards/vcu128/libraries/board/src/vhdl/qsfp_25g.vhd \
*boards/vcu128/libraries/board/src/vhdl/qsfp_40g.vhd \
*boards/vcu128/libraries/board/src/vhdl/qsfp_100g.vhd \
*boards/vcu128/libraries/board/src/vhdl/uptime_counter.vhd \
*boards/vcu128/libraries/board/src/vhdl/mace_mac.vhd \
*boards/vcu128/libraries/board/ip/ip_pkg.vhd \
}]

add_files -fileset constrs_1 [ glob $BOARD_PATH/vivado/vcu128_Rev1.0_.xdc ]
set_property PROCESSING_ORDER LATE [get_files *boards/vcu128/libraries/board/vivado/vcu128_Rev1.0_.xdc]
# tcl scripts for ip generation
source $BOARD_PATH/ip/system_clock.tcl

############################################################
# ARGS generated files
############################################################

# This script uses the construct $workingDir/$proj_dir
# So $proj_dir must be relative to $workingDir
# 
source $ARGS_PATH/vcu128_gemini_dsp_bd.tcl

add_files -fileset sources_1 [glob \
$ARGS_PATH/vcu128_gemini_dsp_bus_pkg.vhd \
$ARGS_PATH/vcu128_gemini_dsp_bus_top.vhd \
$ARGS_PATH/vcu128_gemini_dsp/system/vcu128_gemini_dsp_system_reg_pkg.vhd \
$ARGS_PATH/vcu128_gemini_dsp/system/vcu128_gemini_dsp_system_reg.vhd \
]
set_property library vcu128_gemini_dsp_lib [get_files {\
*build/ARGS/vcu128_gemini_dsp/vcu128_gemini_dsp_bus_pkg.vhd \
*build/ARGS/vcu128_gemini_dsp/vcu128_gemini_dsp_bus_top.vhd \
*build/ARGS/vcu128_gemini_dsp/vcu128_gemini_dsp/system/vcu128_gemini_dsp_system_reg_pkg.vhd \
*build/ARGS/vcu128_gemini_dsp/vcu128_gemini_dsp/system/vcu128_gemini_dsp_system_reg.vhd \
}]

add_files -fileset sources_1 [glob \
$ARGS_PATH/../vcu128_board/qsfp/vcu128_board_qsfp_reg_pkg.vhd \
$ARGS_PATH/../vcu128_board/qsfp/vcu128_board_qsfp_reg.vhd \
$ARGS_PATH/../vcu128_board/ethernet_mace/vcu128_board_ethernet_mace_reg_pkg.vhd \
$ARGS_PATH/../vcu128_board/ethernet_mace/vcu128_board_ethernet_mace_reg.vhd \
$ARGS_PATH/../vcu128_board/ethernet_qsfp/vcu128_board_ethernet_qsfp_reg_pkg.vhd \
$ARGS_PATH/../vcu128_board/ethernet_qsfp/vcu128_board_ethernet_qsfp_reg.vhd \
$ARGS_PATH/../vcu128_board/ethernet_quad_qsfp/vcu128_board_ethernet_quad_qsfp_reg_pkg.vhd \
$ARGS_PATH/../vcu128_board/ethernet_quad_qsfp/vcu128_board_ethernet_quad_qsfp_reg.vhd \
]

set_property library vcu128_board_lib [get_files { \
*vcu128_board/qsfp/vcu128_board_qsfp_reg_pkg.vhd \
*vcu128_board/qsfp/vcu128_board_qsfp_reg.vhd \
*vcu128_board/ethernet_mace/vcu128_board_ethernet_mace_reg_pkg.vhd \
*vcu128_board/ethernet_mace/vcu128_board_ethernet_mace_reg.vhd \
*vcu128_board/ethernet_qsfp/vcu128_board_ethernet_qsfp_reg_pkg.vhd \
*vcu128_board/ethernet_qsfp/vcu128_board_ethernet_qsfp_reg.vhd \
*vcu128_board/ethernet_quad_qsfp/vcu128_board_ethernet_quad_qsfp_reg_pkg.vhd \
*vcu128_board/ethernet_quad_qsfp/vcu128_board_ethernet_quad_qsfp_reg.vhd \
}]
#$ARGS_PATH/gemini_lru_board/onewire_prom/gemini_lru_board_onewire_prom_reg_pkg.vhd \
#$ARGS_PATH/gemini_lru_board/onewire_prom/gemini_lru_board_onewire_prom_reg.vhd \
#$ARGS_PATH/gemini_lru_board/backplane_control/gemini_lru_board_backplane_control_reg_pkg.vhd \
#$ARGS_PATH/gemini_lru_board/backplane_control/gemini_lru_board_backplane_control_reg.vhd \
#$ARGS_PATH/gemini_lru_board/humidity/gemini_lru_board_humidity_reg_pkg.vhd \
#$ARGS_PATH/gemini_lru_board/humidity/gemini_lru_board_humidity_reg.vhd \
#$ARGS_PATH/gemini_lru_board/pmbus/gemini_lru_board_pmbus_reg_pkg.vhd \
#$ARGS_PATH/gemini_lru_board/pmbus/gemini_lru_board_pmbus_reg.vhd \

#$ARGS_PATH/gemini_lru_board/sfp/gemini_lru_board_sfp_reg_pkg.vhd \
#$ARGS_PATH/gemini_lru_board/sfp/gemini_lru_board_sfp_reg.vhd \
#$ARGS_PATH/gemini_lru_board/mbo/gemini_lru_board_mbo_reg_pkg.vhd \
#$ARGS_PATH/gemini_lru_board/mbo/gemini_lru_board_mbo_reg.vhd \







#*build/ARGS/gemini_lru_dsp/gemini_lru_board/qsfp/gemini_lru_board_qsfp_reg_pkg.vhd \
#*build/ARGS/gemini_lru_dsp/gemini_lru_board/qsfp/gemini_lru_board_qsfp_reg.vhd \
#*build/ARGS/gemini_lru_dsp/gemini_lru_board/ethernet_mace/gemini_lru_board_ethernet_mace_reg_pkg.vhd \
#*build/ARGS/gemini_lru_dsp/gemini_lru_board/ethernet_mace/gemini_lru_board_ethernet_mace_reg.vhd \
#*build/ARGS/gemini_lru_board/ethernet_qsfp/gemini_lru_board_ethernet_qsfp_reg_pkg.vhd \
#*build/ARGS/gemini_lru_board/ethernet_qsfp/gemini_lru_board_ethernet_qsfp_reg.vhd \
#*build/ARGS/gemini_lru_board/ethernet_quad_qsfp/gemini_lru_board_ethernet_quad_qsfp_reg_pkg.vhd \
#*build/ARGS/gemini_lru_board/ethernet_quad_qsfp/gemini_lru_board_ethernet_quad_qsfp_reg.vhd \

#*build/ARGS/gemini_lru_dsp/gemini_lru_board/sfp/gemini_lru_board_sfp_reg_pkg.vhd \
#*build/ARGS/gemini_lru_dsp/gemini_lru_board/sfp/gemini_lru_board_sfp_reg.vhd \
#*build/ARGS/gemini_lru_dsp/gemini_lru_board/mbo/gemini_lru_board_mbo_reg_pkg.vhd \
#*build/ARGS/gemini_lru_dsp/gemini_lru_board/mbo/gemini_lru_board_mbo_reg.vhd \
#*build/ARGS/gemini_lru_dsp/gemini_lru_board/pmbus/gemini_lru_board_pmbus_reg_pkg.vhd \
#*build/ARGS/gemini_lru_dsp/gemini_lru_board/pmbus/gemini_lru_board_pmbus_reg.vhd \
#*build/ARGS/gemini_lru_dsp/gemini_lru_board/onewire_prom/gemini_lru_board_onewire_prom_reg_pkg.vhd \
#*build/ARGS/gemini_lru_dsp/gemini_lru_board/onewire_prom/gemini_lru_board_onewire_prom_reg.vhd \
#*build/ARGS/gemini_lru_dsp/gemini_lru_board/backplane_control/gemini_lru_board_backplane_control_reg_pkg.vhd \
#*build/ARGS/gemini_lru_dsp/gemini_lru_board/backplane_control/gemini_lru_board_backplane_control_reg.vhd \
#*build/ARGS/gemini_lru_dsp/gemini_lru_board/humidity/gemini_lru_board_humidity_reg_pkg.vhd \
#*build/ARGS/gemini_lru_dsp/gemini_lru_board/humidity/gemini_lru_board_humidity_reg.vhd \

############################################################
# Design specific files
############################################################

set DESIGN_PATH "../../../../../boards/vcu128/designs/vcu128_gemini_dsp"
add_files -fileset sources_1 [glob \
$DESIGN_PATH/ip/ip_pkg.vhd \
$DESIGN_PATH/src/vhdl/vcu128_gemini_dsp.vhd \
$DESIGN_PATH/src/verilog/mac_100g_pkt_gen_mon.v \
$DESIGN_PATH/src/verilog/mac_100g_pkt_gen.v \
$DESIGN_PATH/src/verilog/mac_100g_pkt_mon.v \
]

set_property library vcu128_gemini_dsp_lib [get_files {\
*boards/vcu128/designs/vcu128_gemini_dsp/ip/ip_pkg.vhd \
*boards/vcu128/designs/vcu128_gemini_dsp/src/vhdl/vcu128_gemini_dsp.vhd \
*boards/vcu128/designs/vcu128_gemini_dsp/src/verilog/mac_100g_pkt_gen_mon.v \
*boards/vcu128/designs/vcu128_gemini_dsp/src/verilog/mac_100g_pkt_gen.v \
*boards/vcu128/designs/vcu128_gemini_dsp/src/verilog/mac_100g_pkt_mon.v \
}]

add_files -fileset constrs_1 [ glob $DESIGN_PATH/vivado/vcu128_gemini_dsp.xdc ]

# test_bench_files
#add_files -fileset sim_1 [glob \
#$DESIGN_PATH/tb/vhdl/tb_lru_dsp.vhd \
#]
#set_property library vcu128_gemini_dsp_lib [get_files {\
#*boards/gemini_lru/designs/gemini_lru_dsp/tb/vhdl/tb_lru_dsp.vhd \
#}]
#set_property -name {xsim.compile.xvlog.more_options} -value {-d SIM_SPEED_UP} -objects [get_filesets sim_1]
#set_property top_lib xil_defaultlib [get_filesets sim_1]
# vivado_bd_files
# vivado_xdc_files

# vivado_xci_files: Importing IP to the project
# tcl scripts for ip generation
source $DESIGN_PATH/ip/ila_0.tcl
source $DESIGN_PATH/ip/vio.tcl
############################################################
# AXI4
set RLIBRARIES_PATH "../../../../../libraries"
add_files -fileset sources_1 [glob \
$RLIBRARIES_PATH/base/axi4/src/vhdl/axi4_lite_pkg.vhd \
$RLIBRARIES_PATH/base/axi4/src/vhdl/axi4_full_pkg.vhd \
$RLIBRARIES_PATH/base/axi4/src/vhdl/axi4_stream_pkg.vhd \
$RLIBRARIES_PATH/base/axi4/src/vhdl/mem_to_axi4_lite.vhd \
]
set_property library axi4_lib [get_files {\
*libraries/base/axi4/src/vhdl/axi4_lite_pkg.vhd \
*libraries/base/axi4/src/vhdl/axi4_full_pkg.vhd \
*libraries/base/axi4/src/vhdl/axi4_stream_pkg.vhd \
*libraries/base/axi4/src/vhdl/mem_to_axi4_lite.vhd \
}]

#############################################################
# Common

add_files -fileset sources_1 [glob \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_reg_r_w.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_reg_r_w_dc.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_pkg.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_str_pkg.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_mem_pkg.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_field_pkg.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_lfsr_sequences_pkg.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_interface_layers_pkg.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_network_layers_pkg.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_network_total_header_pkg.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_components_pkg.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_pulse_extend.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_spulse.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_switch.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_accumulate.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_counter.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_delay.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_ram_crw_crw.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_pipeline.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_fifo_sc.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_areset.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_async.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_multiplexer.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_select_symbol.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_pipeline_sl.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_fifo_dc.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_fifo_dc_mixed_widths.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_count_saturate.vhd \
 $RLIBRARIES_PATH/base/common/src/vhdl/common_multiStepLFSR.vhd \
]
set_property library common_lib [get_files {\
 *libraries/base/common/src/vhdl/common_reg_r_w.vhd \
 *libraries/base/common/src/vhdl/common_reg_r_w_dc.vhd \
 *libraries/base/common/src/vhdl/common_pkg.vhd \
 *libraries/base/common/src/vhdl/common_str_pkg.vhd \
 *libraries/base/common/src/vhdl/common_mem_pkg.vhd \
 *libraries/base/common/src/vhdl/common_field_pkg.vhd \
 *libraries/base/common/src/vhdl/common_lfsr_sequences_pkg.vhd \
 *libraries/base/common/src/vhdl/common_interface_layers_pkg.vhd \
 *libraries/base/common/src/vhdl/common_network_layers_pkg.vhd \
 *libraries/base/common/src/vhdl/common_network_total_header_pkg.vhd \
 *libraries/base/common/src/vhdl/common_components_pkg.vhd \
 *libraries/base/common/src/vhdl/common_pulse_extend.vhd \
 *libraries/base/common/src/vhdl/common_spulse.vhd \
 *libraries/base/common/src/vhdl/common_switch.vhd \
 *libraries/base/common/src/vhdl/common_accumulate.vhd \
 *libraries/base/common/src/vhdl/common_counter.vhd \
 *libraries/base/common/src/vhdl/common_delay.vhd \
 *libraries/base/common/src/vhdl/common_ram_crw_crw.vhd \
 *libraries/base/common/src/vhdl/common_pipeline.vhd \
 *libraries/base/common/src/vhdl/common_fifo_sc.vhd \
 *libraries/base/common/src/vhdl/common_areset.vhd \
 *libraries/base/common/src/vhdl/common_async.vhd \
 *libraries/base/common/src/vhdl/common_multiplexer.vhd \
 *libraries/base/common/src/vhdl/common_select_symbol.vhd \
 *libraries/base/common/src/vhdl/common_pipeline_sl.vhd \
 *libraries/base/common/src/vhdl/common_fifo_dc.vhd \
 *libraries/base/common/src/vhdl/common_fifo_dc_mixed_widths.vhd \
 *libraries/base/common/src/vhdl/common_count_saturate.vhd \
 *libraries/base/common/src/vhdl/common_multiStepLFSR.vhd \
}]

#############################################################
# ARP
add_files -fileset sources_1 [glob \
$RLIBRARIES_PATH/io/arp/src/vhdl/arp.vhd \
]
set_property library arp_lib [get_files {\
*libraries/io/arp/src/vhdl/arp.vhd \
}]

#############################################################
# DHCP
add_files -fileset sources_1 [glob \
 $ARGS_PATH/dhcp/dhcp/dhcp_reg_pkg.vhd \
 $ARGS_PATH/dhcp/dhcp/dhcp_reg.vhd \
 $RLIBRARIES_PATH/io/dhcp/src/vhdl/dhcp_depacketiser.vhd \
 $RLIBRARIES_PATH/io/dhcp/src/vhdl/dhcp_packetiser.vhd \
 $RLIBRARIES_PATH/io/dhcp/src/vhdl/dhcp_transaction_fsm.vhd \
 $RLIBRARIES_PATH/io/dhcp/src/vhdl/dhcp_protocol.vhd \
]
set_property library dhcp_lib [get_files {\
 *build/ARGS/vcu128_gemini_dsp/dhcp/dhcp/dhcp_reg_pkg.vhd \
 *build/ARGS/vcu128_gemini_dsp/dhcp/dhcp/dhcp_reg.vhd \
 *libraries/io/dhcp/src/vhdl/dhcp_depacketiser.vhd \
 *libraries/io/dhcp/src/vhdl/dhcp_packetiser.vhd \
 *libraries/io/dhcp/src/vhdl/dhcp_transaction_fsm.vhd \
 *libraries/io/dhcp/src/vhdl/dhcp_protocol.vhd \
}]

#############################################################
# ETH
add_files -fileset sources_1 [glob \
 $RLIBRARIES_PATH/io/eth/src/vhdl/eth_pkg.vhd \
 $RLIBRARIES_PATH/io/eth/src/vhdl/eth_rx_queue.vhd \
 $RLIBRARIES_PATH/io/eth/src/vhdl/eth_rx_tvalid_extend.vhd \
 $RLIBRARIES_PATH/io/eth/src/vhdl/eth_rx_vlan.vhd \
 $RLIBRARIES_PATH/io/eth/src/vhdl/eth_rx_chk.vhd \
 $RLIBRARIES_PATH/io/eth/src/vhdl/eth_rx_decode.vhd \
 $RLIBRARIES_PATH/io/eth/src/vhdl/eth_rx.vhd \
 $RLIBRARIES_PATH/io/eth/src/vhdl/eth_tx_lane.vhd \
 $RLIBRARIES_PATH/io/eth/src/vhdl/eth_tx_lane_fsm.vhd \
 $RLIBRARIES_PATH/io/eth/src/vhdl/eth_tx_udp_checksum.vhd \
 $RLIBRARIES_PATH/io/eth/src/vhdl/eth_tx_ip_checksum.vhd \
 $RLIBRARIES_PATH/io/eth/src/vhdl/eth_tx_fsm.vhd \
 $RLIBRARIES_PATH/io/eth/src/vhdl/eth_tx.vhd \
]
set_property library eth_lib [get_files {\
 *libraries/io/eth/src/vhdl/eth_pkg.vhd \
 *libraries/io/eth/src/vhdl/eth_rx_queue.vhd \
 *libraries/io/eth/src/vhdl/eth_rx_tvalid_extend.vhd \
 *libraries/io/eth/src/vhdl/eth_rx_vlan.vhd \
 *libraries/io/eth/src/vhdl/eth_rx_chk.vhd \
 *libraries/io/eth/src/vhdl/eth_rx_decode.vhd \
 *libraries/io/eth/src/vhdl/eth_rx.vhd \
 *libraries/io/eth/src/vhdl/eth_tx_lane.vhd \
 *libraries/io/eth/src/vhdl/eth_tx_lane_fsm.vhd \
 *libraries/io/eth/src/vhdl/eth_tx_udp_checksum.vhd \
 *libraries/io/eth/src/vhdl/eth_tx_ip_checksum.vhd \
 *libraries/io/eth/src/vhdl/eth_tx_fsm.vhd \
 *libraries/io/eth/src/vhdl/eth_tx.vhd \
}]

#############################################################
# Gemini Server
add_files -fileset sources_1 [glob \
 $RLIBRARIES_PATH/io/gemini_server/src/vhdl/gemini_server_pkg.vhd \
 $RLIBRARIES_PATH/io/gemini_server/src/vhdl/connection_lookup.vhd \
 $RLIBRARIES_PATH/io/gemini_server/src/vhdl/mm_completion_controller.vhd \
 $RLIBRARIES_PATH/io/gemini_server/src/vhdl/mm_request_controller.vhd \
 $RLIBRARIES_PATH/io/gemini_server/src/vhdl/replay_table.vhd \
 $RLIBRARIES_PATH/io/gemini_server/src/vhdl/mm_transaction_controller.vhd \
 $RLIBRARIES_PATH/io/gemini_server/src/vhdl/request_decoder.vhd \
 $RLIBRARIES_PATH/io/gemini_server/src/vhdl/request_streamer.vhd \
 $RLIBRARIES_PATH/io/gemini_server/src/vhdl/response_encoder.vhd \
 $RLIBRARIES_PATH/io/gemini_server/src/vhdl/response_streamer.vhd \
 $RLIBRARIES_PATH/io/gemini_server/src/vhdl/gemini_server.vhd \
]
set_property library gemini_server_lib [get_files {\
*libraries/io/gemini_server/src/vhdl/gemini_server_pkg.vhd \
*libraries/io/gemini_server/src/vhdl/connection_lookup.vhd \
*libraries/io/gemini_server/src/vhdl/mm_completion_controller.vhd \
*libraries/io/gemini_server/src/vhdl/mm_request_controller.vhd \
*libraries/io/gemini_server/src/vhdl/replay_table.vhd \
*libraries/io/gemini_server/src/vhdl/mm_transaction_controller.vhd \
*libraries/io/gemini_server/src/vhdl/request_decoder.vhd \
*libraries/io/gemini_server/src/vhdl/request_streamer.vhd \
*libraries/io/gemini_server/src/vhdl/response_encoder.vhd \
*libraries/io/gemini_server/src/vhdl/response_streamer.vhd \
*libraries/io/gemini_server/src/vhdl/gemini_server.vhd \
}]

#############################################################
# Gemini Subscription
add_files -fileset sources_1 [glob \
 $ARGS_PATH/gemini_subscription/gemini_subscription/gemini_subscription_reg_pkg.vhd \
 $ARGS_PATH/gemini_subscription/gemini_subscription/gemini_subscription_reg.vhd \
 $RLIBRARIES_PATH/io/gemini_subscription/src/vhdl/client.vhd \
 $RLIBRARIES_PATH/io/gemini_subscription/src/vhdl/service_fsm.vhd \
 $RLIBRARIES_PATH/io/gemini_subscription/src/vhdl/subscription_protocol.vhd \
]
set_property library gemini_subscription_lib [get_files {\
*build/ARGS/vcu128_gemini_dsp/gemini_subscription/gemini_subscription/gemini_subscription_reg_pkg.vhd \
*build/ARGS/vcu128_gemini_dsp/gemini_subscription/gemini_subscription/gemini_subscription_reg.vhd \
*libraries/io/gemini_subscription/src/vhdl/client.vhd \
*libraries/io/gemini_subscription/src/vhdl/service_fsm.vhd \
*libraries/io/gemini_subscription/src/vhdl/subscription_protocol.vhd \
}]

#############################################################
# i2c
add_files -fileset sources_1 [glob \
 $RLIBRARIES_PATH/io/i2c/src/vhdl/i2c_dev_pca9555_pkg.vhd \
 $RLIBRARIES_PATH/io/i2c/src/vhdl/i2c_dev_max1617_pkg.vhd \
 $RLIBRARIES_PATH/io/i2c/src/vhdl/i2c_dev_max6652_pkg.vhd \
 $RLIBRARIES_PATH/io/i2c/src/vhdl/i2c_dev_ltc4260_pkg.vhd \
 $RLIBRARIES_PATH/io/i2c/src/vhdl/i2c_dev_sfp_pkg.vhd \
 $RLIBRARIES_PATH/io/i2c/src/vhdl/i2c_dev_qsfp_pkg.vhd \
 $RLIBRARIES_PATH/io/i2c/src/vhdl/i2c_dev_bmr466_pkg.vhd \
 $RLIBRARIES_PATH/io/i2c/src/vhdl/i2c_dev_bmr457_pkg.vhd \
 $RLIBRARIES_PATH/io/i2c/src/vhdl/i2c_dev_ltm4676_pkg.vhd \
 $RLIBRARIES_PATH/io/i2c/src/vhdl/i2c_dev_si7020_pkg.vhd \
 $RLIBRARIES_PATH/io/i2c/src/vhdl/i2c_dev_ddr4_spd_pkg.vhd \
 $RLIBRARIES_PATH/io/i2c/src/vhdl/i2c_pkg.vhd \
 $RLIBRARIES_PATH/io/i2c/src/vhdl/i2c_bit.vhd \
 $RLIBRARIES_PATH/io/i2c/src/vhdl/i2c_byte.vhd \
 $RLIBRARIES_PATH/io/i2c/src/vhdl/i2c_smbus_pkg.vhd \
 $RLIBRARIES_PATH/io/i2c/src/vhdl/i2c_smbus.vhd \
]
set_property library i2c_lib [get_files {\
 *libraries/io/i2c/src/vhdl/i2c_dev_pca9555_pkg.vhd \
 *libraries/io/i2c/src/vhdl/i2c_dev_max1617_pkg.vhd \
 *libraries/io/i2c/src/vhdl/i2c_dev_max6652_pkg.vhd \
 *libraries/io/i2c/src/vhdl/i2c_dev_ltc4260_pkg.vhd \
 *libraries/io/i2c/src/vhdl/i2c_dev_sfp_pkg.vhd \
 *libraries/io/i2c/src/vhdl/i2c_dev_qsfp_pkg.vhd \
 *libraries/io/i2c/src/vhdl/i2c_dev_bmr466_pkg.vhd \
 *libraries/io/i2c/src/vhdl/i2c_dev_bmr457_pkg.vhd \
 *libraries/io/i2c/src/vhdl/i2c_dev_ltm4676_pkg.vhd \
 *libraries/io/i2c/src/vhdl/i2c_dev_si7020_pkg.vhd \
 *libraries/io/i2c/src/vhdl/i2c_dev_ddr4_spd_pkg.vhd \
 *libraries/io/i2c/src/vhdl/i2c_pkg.vhd \
 *libraries/io/i2c/src/vhdl/i2c_bit.vhd \
 *libraries/io/i2c/src/vhdl/i2c_byte.vhd \
 *libraries/io/i2c/src/vhdl/i2c_smbus_pkg.vhd \
 *libraries/io/i2c/src/vhdl/i2c_smbus.vhd \
}]

#############################################################
# onewire
#add_files -fileset sources_1 [glob \
# $RLIBRARIES_PATH/io/onewire/src/vhdl/onewire_pkg.vhd \
# $RLIBRARIES_PATH/io/onewire/src/vhdl/onewire_phy.vhd \
# $RLIBRARIES_PATH/io/onewire/src/vhdl/onewire_memory.vhd \
#]
#set_property library onewire_lib [get_files {\
# *libraries/io/onewire/src/vhdl/onewire_pkg.vhd \
# *libraries/io/onewire/src/vhdl/onewire_phy.vhd \
# *libraries/io/onewire/src/vhdl/onewire_memory.vhd \
#}]

#############################################################
# ping
add_files -fileset sources_1 [glob \
 $RLIBRARIES_PATH/io/ping_protocol/src/vhdl/ping_protocol.vhd \
]
set_property library ping_protocol_lib [get_files {\
 *libraries/io/ping_protocol/src/vhdl/ping_protocol.vhd \
}]

#############################################################
# technology
add_files -fileset sources_1 [glob \
 $RLIBRARIES_PATH/technology/technology_pkg.vhd \
 $RLIBRARIES_PATH/technology/technology_select_pkg.vhd \
]
set_property library technology_lib [get_files {\
 *libraries/technology/technology_pkg.vhd \
 *libraries/technology/technology_select_pkg.vhd \
}]

#############################################################
# AXI4 infrastructure
#add_files -fileset sources_1 [glob \
# $RLIBRARIES_PATH/technology/axi4_infrastructure/tech_axi4_infrastructure_component_pkg.vhd \
# $RLIBRARIES_PATH/technology/axi4_infrastructure/tech_axi4_lite_dual_clock.vhd \
# $RLIBRARIES_PATH/technology/axi4_infrastructure/tech_axi4_apb_bridge.vhd \
# $RLIBRARIES_PATH/technology/axi4_infrastructure/tech_axi4_ila.vhd \
#]
#set_property library tech_axi4_infrastructure_lib [get_files {\
# *libraries/technology/axi4_infrastructure/tech_axi4_infrastructure_component_pkg.vhd \
# *libraries/technology/axi4_infrastructure/tech_axi4_lite_dual_clock.vhd \
# *libraries/technology/axi4_infrastructure/tech_axi4_apb_bridge.vhd \
# *libraries/technology/axi4_infrastructure/tech_axi4_ila.vhd \
#}]
## tcl scripts for ip generation
#source $RLIBRARIES_PATH/technology/axi4_infrastructure/axi4lite_clock_converter.tcl
#source $RLIBRARIES_PATH/technology/axi4_infrastructure/axi4_apb_bridge.tcl
#source $RLIBRARIES_PATH/technology/axi4_infrastructure/axi4_ila.tcl

#############################################################
# quad SPI prom
#add_files -fileset sources_1 [glob \
# $RLIBRARIES_PATH/technology/axi4_quadspi_prom/tech_axi4_quadspi_prom_component_pkg.vhd \
# $RLIBRARIES_PATH/technology/axi4_quadspi_prom/tech_axi4_quadspi_prom.vhd \
#]
#set_property library tech_axi4_quadspi_prom_lib [get_files {\
# *libraries/technology/axi4_quadspi_prom/tech_axi4_quadspi_prom_component_pkg.vhd \
# *libraries/technology/axi4_quadspi_prom/tech_axi4_quadspi_prom.vhd \
#}]
## vivado_xdc_files
#add_files -fileset constrs_1 [ glob $RLIBRARIES_PATH/technology/axi4_quadspi_prom/axi_quadspi_prom.xdc ]
## tcl scripts for ip generation
#source $RLIBRARIES_PATH/technology/axi4_quadspi_prom/axi_quadspi_prom_dual.tcl
#source $RLIBRARIES_PATH/technology/axi4_quadspi_prom/axi_quadspi_prom_single.tcl

#############################################################
# AXI4 Data mover
add_files -fileset sources_1 [glob \
 $RLIBRARIES_PATH/technology/axi4dm/tech_axi4dm_component_pkg.vhd \
 $RLIBRARIES_PATH/technology/axi4dm/tech_axi4dm.vhd \
]
set_property library tech_axi4dm_lib [get_files {\
 *libraries/technology/axi4dm/tech_axi4dm_component_pkg.vhd \
 *libraries/technology/axi4dm/tech_axi4dm.vhd \
}]
# tcl scripts for ip generation
source $RLIBRARIES_PATH/technology/axi4dm/axi4dm_32.tcl

#############################################################
# tech fifo
add_files -fileset sources_1 [glob \
 $RLIBRARIES_PATH/technology/fifo/tech_fifo_component_pkg.vhd \
 $RLIBRARIES_PATH/technology/fifo/tech_fifo_sc.vhd \
 $RLIBRARIES_PATH/technology/fifo/tech_fifo_dc.vhd \
 $RLIBRARIES_PATH/technology/fifo/tech_fifo_dc_mixed_widths.vhd \
]
set_property library tech_fifo_lib [get_files {\
 *libraries/technology/fifo/tech_fifo_component_pkg.vhd \
 *libraries/technology/fifo/tech_fifo_sc.vhd \
 *libraries/technology/fifo/tech_fifo_dc.vhd \
 *libraries/technology/fifo/tech_fifo_dc_mixed_widths.vhd \
}]
# tcl scripts for ip generation
source $RLIBRARIES_PATH/technology/fifo/enable_xpm.tcl

#############################################################
# tech IO buf

#############################################################
# tech mac100g
add_files -fileset sources_1 [glob \
 $RLIBRARIES_PATH/technology/mac_100g/tech_mac_100g_pkg.vhd \
 $RLIBRARIES_PATH/technology/mac_100g/tech_mac_100g_component_pkg.vhd \
 $RLIBRARIES_PATH/technology/mac_100g/tech_mac_100g.vhd \
]
set_property library tech_mac_100g_lib [get_files {\
 *libraries/technology/mac_100g/tech_mac_100g_pkg.vhd \
 *libraries/technology/mac_100g/tech_mac_100g_component_pkg.vhd \
 *libraries/technology/mac_100g/tech_mac_100g.vhd \
}]

source $RLIBRARIES_PATH/technology/mac_100g/xcvu37p/quad_132/mac_100g_quad_132.tcl

#############################################################
# MAC 10G
add_files -fileset sources_1 [glob \
 $RLIBRARIES_PATH/technology/mac_10g/tech_mac_10g_pkg.vhd \
 $RLIBRARIES_PATH/technology/mac_10g/tech_mac_10g_component_pkg.vhd \
 $RLIBRARIES_PATH/technology/mac_10g/tech_mac_10g.vhd \
]
set_property library tech_mac_10g_lib [get_files {\
 *libraries/technology/mac_10g/tech_mac_10g_pkg.vhd \
 *libraries/technology/mac_10g/tech_mac_10g_component_pkg.vhd \
 *libraries/technology/mac_10g/tech_mac_10g.vhd \
}]

add_files -fileset constrs_1 [ glob $RLIBRARIES_PATH/technology/mac_10g/xcvu37p/quad135_0/mac_10g_135_0.xdc ]

source $RLIBRARIES_PATH/technology/mac_10g/xcvu37p/quad135_0/mac_10g_135_0.tcl

#############################################################
# MAC 25G quad
add_files -fileset sources_1 [glob \
 $RLIBRARIES_PATH/technology/mac_25g_quad/tech_mac_25g_quad_pkg.vhd \
 $RLIBRARIES_PATH/technology/mac_25g_quad/tech_mac_25g_quad_component_pkg.vhd \
 $RLIBRARIES_PATH/technology/mac_25g_quad/tech_mac_25g_quad.vhd \
]
set_property library tech_mac_25g_quad_lib [get_files {\
 *libraries/technology/mac_25g_quad/tech_mac_25g_quad_pkg.vhd \
 *libraries/technology/mac_25g_quad/tech_mac_25g_quad_component_pkg.vhd \
 *libraries/technology/mac_25g_quad/tech_mac_25g_quad.vhd \
}]

add_files -fileset constrs_1 [ glob $RLIBRARIES_PATH/technology/mac_25g_quad/xcvu37p/quad_134/mac_25g_quad_134.xdc ]
# tcl scripts for ip generation
source $RLIBRARIES_PATH/technology/mac_25g_quad/xcvu37p/quad_134/mac_25g_quad_134.tcl

#############################################################
# MAC 40G
add_files -fileset sources_1 [glob \
 $RLIBRARIES_PATH/technology/mac_40g/tech_mac_40g_pkg.vhd \
 $RLIBRARIES_PATH/technology/mac_40g/tech_mac_40g_component_pkg.vhd \
 $RLIBRARIES_PATH/technology/mac_40g/tech_mac_40g.vhd \
]
set_property library tech_mac_40g_lib [get_files {\
 *libraries/technology/mac_40g/tech_mac_40g_pkg.vhd \
 *libraries/technology/mac_40g/tech_mac_40g_component_pkg.vhd \
 *libraries/technology/mac_40g/tech_mac_40g.vhd \
}]
add_files -fileset constrs_1 [ glob $RLIBRARIES_PATH/technology/mac_40g/xcvu37p/quad_131/mac_40g_quad_131.xdc ]
# tcl scripts for ip generation
source $RLIBRARIES_PATH/technology/mac_40g/xcvu37p/quad_131/mac_40g_quad_131.tcl

#############################################################
# tech memory
add_files -fileset sources_1 [glob \
 $RLIBRARIES_PATH/technology/memory/tech_memory_component_pkg.vhd \
 $RLIBRARIES_PATH/technology/memory/tech_memory_ram_cr_cw.vhd \
 $RLIBRARIES_PATH/technology/memory/tech_memory_ram_crw_crw.vhd \
]
set_property library tech_memory_lib [get_files {\
 *libraries/technology/memory/tech_memory_component_pkg.vhd \
 *libraries/technology/memory/tech_memory_ram_cr_cw.vhd \
 *libraries/technology/memory/tech_memory_ram_crw_crw.vhd \
}]

#############################################################
# system monitor
add_files -fileset sources_1 [glob \
 $RLIBRARIES_PATH/technology/system_monitor/tech_system_monitor.vhd \
 $RLIBRARIES_PATH/technology/system_monitor/tech_system_monitor_component_pkg.vhd \
]
set_property library tech_system_monitor_lib [get_files {\
 *libraries/technology/system_monitor/tech_system_monitor.vhd \
 *libraries/technology/system_monitor/tech_system_monitor_component_pkg.vhd \
}]
source $RLIBRARIES_PATH/technology/system_monitor/xcvu37p/system_monitor_gemini_xh_lru.tcl

#############################################################
# LFAA decode

add_files -fileset sources_1 [glob \
 $ARGS_PATH/LFAADecode/lfaadecode/LFAADecode_lfaadecode_reg_pkg.vhd \
 $ARGS_PATH/LFAADecode/lfaadecode/LFAADecode_lfaadecode_reg.vhd \
 $ARGS_PATH/LFAADecode/lfaadecode/LFAADecode_lfaadecode_vcstats_ram.vhd \
 $RLIBRARIES_PATH/signalProcessing/LFAADecode/src/vhdl/LFAADecodeTop.vhd \
 $RLIBRARIES_PATH/signalProcessing/LFAADecode/src/vhdl/LFAAProcess.vhd \
 $RLIBRARIES_PATH/signalProcessing/LFAADecode/src/vhdl/testProcess.vhd \
 $RLIBRARIES_PATH/signalProcessing/LFAADecode/src/vhdl/LFAAStats.vhd \
]
set_property library LFAADecode_lib [get_files {\
 *build/ARGS/vcu128_gemini_dsp/LFAADecode/lfaadecode/LFAADecode_lfaadecode_reg_pkg.vhd \
 *build/ARGS/vcu128_gemini_dsp/LFAADecode/lfaadecode/LFAADecode_lfaadecode_reg.vhd \
 *build/ARGS/vcu128_gemini_dsp/LFAADecode/lfaadecode/LFAADecode_lfaadecode_vcstats_ram.vhd \
 *libraries/signalProcessing/LFAADecode/src/vhdl/LFAADecodeTop.vhd \
 *libraries/signalProcessing/LFAADecode/src/vhdl/LFAAProcess.vhd \
 *libraries/signalProcessing/LFAADecode/src/vhdl/testProcess.vhd \
 *libraries/signalProcessing/LFAADecode/src/vhdl/LFAAStats.vhd \
}]
# test_bench_files
add_files -fileset sim_1 [glob \
 $RLIBRARIES_PATH/signalProcessing/LFAADecode/tb/tb_LFAADecode.vhd \
]
set_property library LFAADecode_lib [get_files {\
 *libraries/signalProcessing/LFAADecode/tb/tb_LFAADecode.vhd \
}]
set_property -name {xsim.compile.xvlog.more_options} -value {-d SIM_SPEED_UP} -objects [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
# tcl scripts for ip generation
source $ARGS_PATH/LFAADecode/lfaadecode/ip_LFAADecode_lfaadecode_vcstats_ram.tcl

#############################################################
# Timing Control
add_files -fileset sources_1 [glob \
 $ARGS_PATH/timingControl/timingcontrol/timingControl_timingcontrol_reg_pkg.vhd \
 $ARGS_PATH/timingControl/timingcontrol/timingControl_timingcontrol_reg.vhd \
 $RLIBRARIES_PATH/signalProcessing/timingControl/src/vhdl/timing_control.vhd \
]
set_property library timingControl_lib [get_files {\
 *build/ARGS/vcu128_gemini_dsp/timingControl/timingcontrol/timingControl_timingcontrol_reg_pkg.vhd \
 *build/ARGS/vcu128_gemini_dsp/timingControl/timingcontrol/timingControl_timingcontrol_reg.vhd \
 *libraries/signalProcessing/timingControl/src/vhdl/timing_control.vhd \
}]

# tcl scripts for ip generation
source $RLIBRARIES_PATH/signalProcessing/timingControl/ptpclk125.tcl

#############################################################
# Capture128bit
add_files -fileset sources_1 [glob \
 $ARGS_PATH/capture128bit/capture128bit/capture128bit_reg_pkg.vhd \
 $ARGS_PATH/capture128bit/capture128bit/capture128bit_reg.vhd \
 $ARGS_PATH/capture128bit/capture128bit/capture128bit_capbuf_ram.vhd \
 $RLIBRARIES_PATH/signalProcessing/capture128bit/src/vhdl/capture128bit.vhd \
]
set_property library capture128bit_lib [get_files {\
 *build/ARGS/vcu128_gemini_dsp/capture128bit/capture128bit/capture128bit_reg_pkg.vhd \
 *build/ARGS/vcu128_gemini_dsp/capture128bit/capture128bit/capture128bit_reg.vhd \
 *build/ARGS/vcu128_gemini_dsp/capture128bit/capture128bit/capture128bit_capbuf_ram.vhd \
 *libraries/signalProcessing/capture128bit/src/vhdl/capture128bit.vhd \
}]

# tcl scripts for ip generation
source $ARGS_PATH/capture128bit/capture128bit/ip_capture128bit_capbuf_ram.tcl

#############################################################
# Interconnect
add_files -fileset sources_1 [glob \
 $ARGS_PATH/interconnect/interconnect/interconnect_reg_pkg.vhd \
 $ARGS_PATH/interconnect/interconnect/interconnect_reg.vhd \
 $RLIBRARIES_PATH/signalProcessing/interconnect/src/vhdl/crc32Full64Step.vhd \
 $RLIBRARIES_PATH/signalProcessing/interconnect/src/vhdl/IC_URAMBuffer.vhd \
 $RLIBRARIES_PATH/signalProcessing/interconnect/src/vhdl/IC_outputMux.vhd \
 $RLIBRARIES_PATH/signalProcessing/interconnect/src/vhdl/IC_LFAAInput.vhd \
 $RLIBRARIES_PATH/signalProcessing/interconnect/src/vhdl/IC_LFAAInputFifo.vhd \
 $RLIBRARIES_PATH/signalProcessing/interconnect/src/vhdl/IC_top.vhd \
]
set_property library interconnect_lib [get_files {\
 *build/ARGS/vcu128_gemini_dsp/interconnect/interconnect/interconnect_reg_pkg.vhd \
 *build/ARGS/vcu128_gemini_dsp/interconnect/interconnect/interconnect_reg.vhd \
 *libraries/signalProcessing/interconnect/src/vhdl/crc32Full64Step.vhd \
 *libraries/signalProcessing/interconnect/src/vhdl/IC_URAMBuffer.vhd \
 *libraries/signalProcessing/interconnect/src/vhdl/IC_outputMux.vhd \
 *libraries/signalProcessing/interconnect/src/vhdl/IC_LFAAInput.vhd \
 *libraries/signalProcessing/interconnect/src/vhdl/IC_LFAAInputFifo.vhd \
 *libraries/signalProcessing/interconnect/src/vhdl/IC_top.vhd \
}]

set_property file_type {VHDL 2008} [get_files {\
*libraries/signalProcessing/interconnect/src/vhdl/IC_outputMux.vhd \
}]

#############################################################
# Coarse Corner Turn
add_files -fileset sources_1 [glob \
 $ARGS_PATH/ctc/config/ctc_config_reg_pkg.vhd \
 $ARGS_PATH/ctc/config/ctc_config_reg.vhd \
 $RLIBRARIES_PATH/signalProcessing/corner_turner/CTC/ctc_pkg.vhd \
 $RLIBRARIES_PATH/signalProcessing/corner_turner/CTC/ctc_config/ctc_config.vhd \
 $RLIBRARIES_PATH/signalProcessing/corner_turner/CTC/ctc_hbm_buffer/ctc_address_manager.vhd \
 $RLIBRARIES_PATH/signalProcessing/corner_turner/CTC/ctc_hbm_buffer/ctc_hbm_block_tracker.vhd \
 $RLIBRARIES_PATH/signalProcessing/corner_turner/CTC/ctc_hbm_buffer/ctc_hbm_buffer_ram.vhd \
 $RLIBRARIES_PATH/signalProcessing/corner_turner/CTC/ctc_hbm_buffer/ctc_hbm_buffer.vhd \
 $RLIBRARIES_PATH/signalProcessing/corner_turner/CTC/ctc_input_buffer/ctc_input_buffer.vhd \
 $RLIBRARIES_PATH/signalProcessing/corner_turner/CTC/ctc_output_buffer/ctc_output_buffer.vhd \
 $RLIBRARIES_PATH/signalProcessing/corner_turner/CTC/ctc_output_buffer/ctc_output_dsp.vhd \
 $RLIBRARIES_PATH/signalProcessing/corner_turner/CTC/ctc.vhd \
]
set_property library ctc_lib [get_files {\
 *build/ARGS/vcu128_gemini_dsp/ctc/config/ctc_config_reg_pkg.vhd \
 *build/ARGS/vcu128_gemini_dsp/ctc/config/ctc_config_reg.vhd \
 *libraries/signalProcessing/corner_turner/CTC/ctc_pkg.vhd \
 *libraries/signalProcessing/corner_turner/CTC/ctc_config/ctc_config.vhd \
 *libraries/signalProcessing/corner_turner/CTC/ctc_hbm_buffer/ctc_address_manager.vhd \
 *libraries/signalProcessing/corner_turner/CTC/ctc_hbm_buffer/ctc_hbm_block_tracker.vhd \
 *libraries/signalProcessing/corner_turner/CTC/ctc_hbm_buffer/ctc_hbm_buffer_ram.vhd \
 *libraries/signalProcessing/corner_turner/CTC/ctc_hbm_buffer/ctc_hbm_buffer.vhd \
 *libraries/signalProcessing/corner_turner/CTC/ctc_input_buffer/ctc_input_buffer.vhd \
 *libraries/signalProcessing/corner_turner/CTC/ctc_output_buffer/ctc_output_buffer.vhd \
 *libraries/signalProcessing/corner_turner/CTC/ctc_output_buffer/ctc_output_dsp.vhd \
 *libraries/signalProcessing/corner_turner/CTC/ctc.vhd \
}]

set_property file_type {VHDL 2008} [get_files {\
 *libraries/signalProcessing/corner_turner/CTC/ctc_pkg.vhd \
 *libraries/signalProcessing/corner_turner/CTC/ctc_config/ctc_config.vhd \
 *libraries/signalProcessing/corner_turner/CTC/ctc_hbm_buffer/ctc_address_manager.vhd \
 *libraries/signalProcessing/corner_turner/CTC/ctc_hbm_buffer/ctc_hbm_block_tracker.vhd \
 *libraries/signalProcessing/corner_turner/CTC/ctc_hbm_buffer/ctc_hbm_buffer_ram.vhd \
 *libraries/signalProcessing/corner_turner/CTC/ctc_hbm_buffer/ctc_hbm_buffer.vhd \
 *libraries/signalProcessing/corner_turner/CTC/ctc_input_buffer/ctc_input_buffer.vhd \
 *libraries/signalProcessing/corner_turner/CTC/ctc_output_buffer/ctc_output_buffer.vhd \
 *libraries/signalProcessing/corner_turner/CTC/ctc_output_buffer/ctc_output_dsp.vhd \
 *libraries/signalProcessing/corner_turner/CTC/ctc.vhd \
}]

add_files -fileset sources_1 [glob \
 $RLIBRARIES_PATH/signalProcessing/corner_turner/CTC/hbm/hbm_wrapper.vhd \
]

# $RLIBRARIES_PATH/signalProcessing/corner_turner/CTC/hbm/HBM_MC0.v 
# $RLIBRARIES_PATH/signalProcessing/corner_turner/CTC/hbm/hbm_v1_0_3.sv 

set_property library ctc_hbm_lib [get_files {\
 *libraries/signalProcessing/corner_turner/CTC/hbm/hbm_wrapper.vhd \
}]

# test_bench_files
add_files -fileset sim_1 [glob \
 $RLIBRARIES_PATH/signalProcessing/corner_turner/CTC/tb/emulator_ram.vhd \
]
set_property library ctc_lib [get_files {\
 *libraries/signalProcessing/corner_turner/CTC/tb/emulator_ram.vhd \
}]
set_property file_type {VHDL 2008} [get_files {\
 *libraries/signalProcessing/corner_turner/CTC/tb/emulator_ram.vhd \
}]

# *libraries/signalProcessing/corner_turner/CTC/hbm/HBM_MC0.v 
# *libraries/signalProcessing/corner_turner/CTC/hbm/hbm_v1_0_3.sv 

import_files [glob \
 $RLIBRARIES_PATH/signalProcessing/corner_turner/CTC/hbm/HBM_MC0.xci
]

#############################################################
# Fine Capture
add_files -fileset sources_1 [glob \
 $ARGS_PATH/captureFine/capturefine/captureFine_capturefine_reg_pkg.vhd \
 $ARGS_PATH/captureFine/capturefine/captureFine_capturefine_reg.vhd \
 $ARGS_PATH/captureFine/capturefine/captureFine_capturefine_capbuf_ram.vhd \
 $RLIBRARIES_PATH/signalProcessing/captureFine/src/vhdl/captureFine.vhd \
]
set_property library captureFine_lib [get_files {\
 *build/ARGS/vcu128_gemini_dsp/captureFine/capturefine/captureFine_capturefine_reg_pkg.vhd \
 *build/ARGS/vcu128_gemini_dsp/captureFine/capturefine/captureFine_capturefine_reg.vhd \
 *build/ARGS/vcu128_gemini_dsp/captureFine/capturefine/captureFine_capturefine_capbuf_ram.vhd \
 *libraries/signalProcessing/captureFine/src/vhdl/captureFine.vhd \
}]

# tcl scripts for ip generation
source $ARGS_PATH/captureFine/capturefine/ip_captureFine_capturefine_capbuf_ram.tcl

#############################################################
# Filterbanks
add_files -fileset sources_1 [glob \
 $RLIBRARIES_PATH/signalProcessing/filterbanks/src/vhdl/mm_firtaps.vhd \
 $RLIBRARIES_PATH/signalProcessing/filterbanks/src/vhdl/correlatorFBMem.vhd \
 $RLIBRARIES_PATH/signalProcessing/filterbanks/src/vhdl/correlatorFFT25wrapper.vhd \
 $RLIBRARIES_PATH/signalProcessing/filterbanks/src/vhdl/URAMWrapper.vhd \
 $RLIBRARIES_PATH/signalProcessing/filterbanks/src/vhdl/fb_DSP25.vhd \
 $RLIBRARIES_PATH/signalProcessing/filterbanks/src/vhdl/correlatorFBTop25.vhd \
 $RLIBRARIES_PATH/signalProcessing/filterbanks/src/vhdl/fb_DSP.vhd \
 $RLIBRARIES_PATH/signalProcessing/filterbanks/src/vhdl/PSSFBmem.vhd \
 $RLIBRARIES_PATH/signalProcessing/filterbanks/src/vhdl/PSSFFTwrapper.vhd \
 $RLIBRARIES_PATH/signalProcessing/filterbanks/src/vhdl/PSSFBTop.vhd \
 $RLIBRARIES_PATH/signalProcessing/filterbanks/src/vhdl/FBDistFIFOWrapper.vhd \
 $RLIBRARIES_PATH/signalProcessing/filterbanks/src/vhdl/PSTFFTwrapper.vhd \
 $RLIBRARIES_PATH/signalProcessing/filterbanks/src/vhdl/PSTFBmem.vhd \
 $RLIBRARIES_PATH/signalProcessing/filterbanks/src/vhdl/PSTFBTop.vhd \
 $RLIBRARIES_PATH/signalProcessing/filterbanks/src/vhdl/FB_top.vhd \
]

set_property library filterbanks_lib [get_files {\
 *libraries/signalProcessing/filterbanks/src/vhdl/mm_firtaps.vhd \
 *libraries/signalProcessing/filterbanks/src/vhdl/correlatorFBMem.vhd \
 *libraries/signalProcessing/filterbanks/src/vhdl/correlatorFFT25wrapper.vhd \
 *libraries/signalProcessing/filterbanks/src/vhdl/URAMWrapper.vhd \
 *libraries/signalProcessing/filterbanks/src/vhdl/fb_DSP25.vhd \
 *libraries/signalProcessing/filterbanks/src/vhdl/correlatorFBTop25.vhd \
 *libraries/signalProcessing/filterbanks/src/vhdl/fb_DSP.vhd \
 *libraries/signalProcessing/filterbanks/src/vhdl/PSSFBmem.vhd \
 *libraries/signalProcessing/filterbanks/src/vhdl/PSSFFTwrapper.vhd \
 *libraries/signalProcessing/filterbanks/src/vhdl/PSSFBTop.vhd \
 *libraries/signalProcessing/filterbanks/src/vhdl/FBDistFIFOWrapper.vhd \
 *libraries/signalProcessing/filterbanks/src/vhdl/PSTFFTwrapper.vhd \
 *libraries/signalProcessing/filterbanks/src/vhdl/PSTFBmem.vhd \
 *libraries/signalProcessing/filterbanks/src/vhdl/PSTFBTop.vhd \
 *libraries/signalProcessing/filterbanks/src/vhdl/FB_top.vhd \
}]

source $RLIBRARIES_PATH/signalProcessing/filterbanks/src/ip/dspAxB.tcl
source $RLIBRARIES_PATH/signalProcessing/filterbanks/src/ip/CorFB_FFT.tcl
source $RLIBRARIES_PATH/signalProcessing/filterbanks/src/ip/CorFB_roms.tcl
source $RLIBRARIES_PATH/signalProcessing/filterbanks/src/ip/PSSFB_FFT.tcl
source $RLIBRARIES_PATH/signalProcessing/filterbanks/src/ip/PSSFB_roms.tcl
source $RLIBRARIES_PATH/signalProcessing/filterbanks/src/ip/PSTFB_FFT.tcl
source $RLIBRARIES_PATH/signalProcessing/filterbanks/src/ip/PSTFB_roms.tcl
source $RLIBRARIES_PATH/signalProcessing/filterbanks/src/ip/ip_filterbanks_firtaps_ram.tcl


##############################################################
## DSP top level
add_files -fileset sources_1 [glob \
 $ARGS_PATH/dsp_top/dsp_top/dsp_top_reg_pkg.vhd \
 $ARGS_PATH/dsp_top/dsp_top/dsp_top_reg.vhd \
 $RLIBRARIES_PATH/signalProcessing/DSP_top/src/vhdl/DSP_top_pkg.vhd \
 $RLIBRARIES_PATH/signalProcessing/DSP_top/src/vhdl/DSP_top.vhd \
 $RLIBRARIES_PATH/signalProcessing/DSP_top/src/vhdl/axi_width_wrapper.vhd \
]

set_property library DSP_top_lib [get_files {\
 *build/ARGS/vcu128_gemini_dsp/dsp_top/dsp_top/dsp_top_reg_pkg.vhd \
 *build/ARGS/vcu128_gemini_dsp/dsp_top/dsp_top/dsp_top_reg.vhd \
 *libraries/signalProcessing/DSP_top/src/vhdl/DSP_top_pkg.vhd \
 *libraries/signalProcessing/DSP_top/src/vhdl/DSP_top.vhd \
 *libraries/signalProcessing/DSP_top/src/vhdl/axi_width_wrapper.vhd \
}]

# test_bench_files
add_files -fileset sim_1 [glob \
 $RLIBRARIES_PATH/signalProcessing/DSP_top/tb/tb_DSP_top.vhd \
 $RLIBRARIES_PATH/signalProcessing/DSP_top/tb/run2_tb_pkg.vhd \
 $RLIBRARIES_PATH/signalProcessing/DSP_top/tb/setup_ctc_pkg.vhd \
]
set_property library DSP_top_lib [get_files {\
 *libraries/signalProcessing/DSP_top/tb/run2_tb_pkg.vhd \
 *libraries/signalProcessing/DSP_top/tb/tb_DSP_top.vhd \
 *libraries/signalProcessing/DSP_top/tb/setup_ctc_pkg.vhd \
}]

source $RLIBRARIES_PATH/signalProcessing/DSP_top/src/ip/hbmdbg_axi_width_convert.tcl

##############################################################
# Set top
set_property top vcu128_gemini_DSP [current_fileset]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
