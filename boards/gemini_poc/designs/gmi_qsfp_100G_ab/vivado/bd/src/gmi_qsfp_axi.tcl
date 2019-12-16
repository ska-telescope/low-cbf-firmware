
############################

set design gmi_qsfp_axi

#Project directory
set projdir ./build/

if ![file exists $projdir]  {file mkdir $projdir}

#Device name
set partname "xcvu9p-flga2577-2L-e-es1"

#Board part
set boardpart ""

#Paths to all IP blocks to use in Vivado bd
set ip_repos [list "../../../../../libraries/gmi_board/ip/repo/"]
set ip_repos_build [list "$projdir/repo/"]
if ![file exists $ip_repos_build]  {file mkdir $ip_repos_build}

#System's extra source files
set hdl_files []

#System's constraints files
set constraints_files []

################
# CREATE PROJECT
################

create_project -force $design $projdir -part $partname
set_property target_language VHDL [current_project]

if {$boardpart != ""} {
set_property "board_part" $boardpart [current_project]
}

#################################
# Create Report/Results Directory
#################################

set report_dir  $projdir/reports
set results_dir $projdir/results
if ![file exists $report_dir]  {file mkdir $report_dir}
if ![file exists $results_dir] {file mkdir $results_dir}

####################################
# Add IP Repositories to search path
####################################

set other_repos [get_property ip_repo_paths [current_project]]
set_property  ip_repo_paths  "$ip_repos $other_repos $ip_repos_build" [current_project]

update_ip_catalog
update_ip_catalog -add_ip $ip_repos/axi_slave_led_reg.zip -repo_path $ip_repos_build
update_ip_catalog -add_ip $ip_repos/axi_slave_reg_rw.zip -repo_path $ip_repos_build


#####################################
# CREATE BLOCK DESIGN (GUI/TCL COMBO)
#####################################

create_bd_design "gmi_qsfp_axi"

# Place components (including set properties):
startgroup
#create_bd_cell -type ip -vlnv user.org:user:axi_slave_led_reg:1.0 axi_slave_led_reg_0
create_bd_cell -type ip -vlnv user.org:user:axi_slave_led_reg axi_slave_led_reg_0
endgroup
startgroup
#create_bd_cell -type ip -vlnv user.org:user:axi_slave_reg_rw:1.0 axi_slave_reg_rw_0
create_bd_cell -type ip -vlnv user.org:user:axi_slave_reg_rw axi_slave_reg_rw_0
endgroup

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
set_property -dict [list CONFIG.C_AUX_RESET_HIGH.VALUE_SRC USER] [get_bd_cells proc_sys_reset_0]
set_property -dict [list CONFIG.C_AUX_RESET_HIGH {0}] [get_bd_cells proc_sys_reset_0]
endgroup
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:jtag_axi:1.2 jtag_axi_0
endgroup
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
endgroup
set_property -dict [list CONFIG.NUM_MI {5}] [get_bd_cells axi_interconnect_0]

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_amm_bridge:1.0 axi_amm_bridge_0
endgroup
startgroup
set_property -dict [list CONFIG.C_HAS_WAIT_REQUEST {0} CONFIG.C_HAS_READ_DATA_VALID {0} CONFIG.C_USE_BYTEENABLE {0} CONFIG.C_HAS_RESPONSE {0}] [get_bd_cells axi_amm_bridge_0]
endgroup


# Ports:
startgroup
create_bd_port -dir I -type clk clock_rtl
set_property CONFIG.FREQ_HZ 125000000 [get_bd_ports clock_rtl]
endgroup

create_bd_port -dir I -type rst reset_rtl
set_property CONFIG.POLARITY ACTIVE_HIGH [get_bd_ports reset_rtl]

create_bd_port -dir I pll_locked

create_bd_port -dir O -from 23 -to 0 led_axi_out

# avalon:
create_bd_port -dir I -from 31 -to 0 avm_readdata
create_bd_port -dir O -from 31 -to 0 avm_writedata
create_bd_port -dir O -from 31 -to 0 avm_address
create_bd_port -dir O avm_read
create_bd_port -dir O avm_write


# reg rw:
create_bd_port -dir I -from 127 -to 0 reg_axi_in
create_bd_port -dir O -from 127 -to 0 reg_axi_out

#make M03_AXI and M04_AXI available external:
startgroup
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M03_AXI
set_property -dict [list CONFIG.NUM_READ_OUTSTANDING [get_property CONFIG.NUM_READ_OUTSTANDING [get_bd_intf_pins axi_interconnect_0/xbar/M03_AXI]] CONFIG.NUM_WRITE_OUTSTANDING [get_property CONFIG.NUM_WRITE_OUTSTANDING [get_bd_intf_pins axi_interconnect_0/xbar/M03_AXI]]] [get_bd_intf_ports M03_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M03_AXI] [get_bd_intf_ports M03_AXI]
endgroup
startgroup
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M04_AXI
set_property -dict [list CONFIG.NUM_READ_OUTSTANDING [get_property CONFIG.NUM_READ_OUTSTANDING [get_bd_intf_pins axi_interconnect_0/xbar/M04_AXI]] CONFIG.NUM_WRITE_OUTSTANDING [get_property CONFIG.NUM_WRITE_OUTSTANDING [get_bd_intf_pins axi_interconnect_0/xbar/M04_AXI]]] [get_bd_intf_ports M04_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M04_AXI] [get_bd_intf_ports M04_AXI]
endgroup


# Connect everything:
connect_bd_net [get_bd_ports reset_rtl] [get_bd_pins proc_sys_reset_0/ext_reset_in]
connect_bd_net [get_bd_ports led_axi_out] [get_bd_pins axi_slave_led_reg_0/led_output]

connect_bd_net [get_bd_ports clock_rtl] [get_bd_pins jtag_axi_0/aclk]
connect_bd_net [get_bd_ports clock_rtl] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
connect_bd_net [get_bd_ports clock_rtl] [get_bd_pins axi_slave_led_reg_0/s0_axi_aclk]

connect_bd_net [get_bd_ports clock_rtl] [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M00_ARESETN]
connect_bd_net [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] -boundary_type upper
connect_bd_net [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
connect_bd_net [get_bd_ports clock_rtl] [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net [get_bd_ports clock_rtl] [get_bd_pins axi_interconnect_0/M00_ACLK]
connect_bd_intf_net [get_bd_intf_pins jtag_axi_0/M_AXI] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins axi_slave_led_reg_0/S0_AXI]
connect_bd_net [get_bd_pins axi_slave_led_reg_0/s0_axi_aresetn] [get_bd_pins axi_interconnect_0/M00_ARESETN]
connect_bd_net [get_bd_pins jtag_axi_0/aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]

#connect avalon to bridge:
connect_bd_net [get_bd_ports avm_readdata] [get_bd_pins axi_amm_bridge_0/avm_readdata]
connect_bd_net [get_bd_ports avm_address] [get_bd_pins axi_amm_bridge_0/avm_address]
connect_bd_net [get_bd_ports avm_read] [get_bd_pins axi_amm_bridge_0/avm_read]
connect_bd_net [get_bd_ports avm_write] [get_bd_pins axi_amm_bridge_0/avm_write]
connect_bd_net [get_bd_ports avm_writedata] [get_bd_pins axi_amm_bridge_0/avm_writedata]

connect_bd_net [get_bd_ports pll_locked] [get_bd_pins proc_sys_reset_0/dcm_locked]
connect_bd_intf_net [get_bd_intf_pins axi_amm_bridge_0/S_AXI_LITE] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M02_AXI]
connect_bd_net [get_bd_ports clock_rtl] [get_bd_pins axi_amm_bridge_0/s_axi_aclk]
connect_bd_net [get_bd_pins axi_amm_bridge_0/s_axi_aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
connect_bd_net [get_bd_ports reg_axi_out] [get_bd_pins axi_slave_reg_rw_0/reg_output]
connect_bd_net [get_bd_ports reg_axi_in] [get_bd_pins axi_slave_reg_rw_0/reg_input]
connect_bd_intf_net [get_bd_intf_pins axi_slave_reg_rw_0/S00_AXI] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M01_AXI]
connect_bd_net [get_bd_ports clock_rtl] [get_bd_pins axi_slave_reg_rw_0/s00_axi_aclk]
connect_bd_net [get_bd_pins axi_slave_reg_rw_0/s00_axi_aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
connect_bd_net [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
connect_bd_net [get_bd_pins axi_interconnect_0/M02_ARESETN] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
connect_bd_net [get_bd_pins axi_interconnect_0/M03_ARESETN] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
connect_bd_net [get_bd_pins axi_interconnect_0/M04_ARESETN] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
connect_bd_net [get_bd_ports clock_rtl] [get_bd_pins axi_interconnect_0/M01_ACLK]
connect_bd_net [get_bd_ports clock_rtl] [get_bd_pins axi_interconnect_0/M02_ACLK]
connect_bd_net [get_bd_ports clock_rtl] [get_bd_pins axi_interconnect_0/M03_ACLK]
connect_bd_net [get_bd_ports clock_rtl] [get_bd_pins axi_interconnect_0/M04_ACLK]



# Assign base addresses:
create_bd_addr_seg -range 64K -offset 0x40000000 [get_bd_addr_spaces /jtag_axi_0/Data] [get_bd_addr_segs {axi_slave_led_reg_0/s0_axi/axi_lite }] axi_slave_led_reg_0
create_bd_addr_seg -range 64K -offset 0x40010000 [get_bd_addr_spaces /jtag_axi_0/Data] [get_bd_addr_segs {axi_slave_reg_rw_0/s00_axi/axi_lite}] axi_slave_reg_rw_0
create_bd_addr_seg -range 64K -offset 0x40020000 [get_bd_addr_spaces /jtag_axi_0/Data] [get_bd_addr_segs {axi_amm_bridge_0/S_AXI_LITE/Reg }] axi_amm_bridge_0
create_bd_addr_seg -range 64K -offset 0x40030000 [get_bd_addr_spaces /jtag_axi_0/Data] [get_bd_addr_segs {M03_AXI/Reg }] M03_AXI
create_bd_addr_seg -range 64K -offset 0x40040000 [get_bd_addr_spaces /jtag_axi_0/Data] [get_bd_addr_segs {M04_AXI/Reg }] M04_AXI

# Finish, Check and Save:
regenerate_bd_layout
validate_bd_design
save_bd_design


# Optionally derive a wrapper:
#make_wrapper -files [get_files /home/hiemstra/svnlowcbf/LOWCBF/Firmware/boards/gemini/designs/gmi_led/vivado/bd/src/build/gmi_led_axi.srcs/sources_1/bd/gmi_led_axi/gmi_led_axi.bd] -top


exit

