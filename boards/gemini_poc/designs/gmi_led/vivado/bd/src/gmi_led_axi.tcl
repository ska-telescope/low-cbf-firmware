
############################

set design gmi_led_axi

#Project directory
set projdir ./build/

if ![file exists $projdir]  {file mkdir $projdir}

#Device name
set partname "xcvu9p-flga2577-2L-e-es1"

#Board part
set boardpart ""

#Paths to all IP blocks to use in Vivado "system.bd"
#set ip_repos [list "../../../ip/repo"]
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

#####################################
# CREATE BLOCK DESIGN (GUI/TCL COMBO)
#####################################

create_bd_design "gmi_led_axi"


startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:jtag_axi:1.2 jtag_axi_0
endgroup
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
endgroup
set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {3}] [get_bd_cells axi_interconnect_0]


# Ports:
startgroup
create_bd_port -dir I -type clk mm_clk
set_property CONFIG.FREQ_HZ 100000000 [get_bd_ports mm_clk]
endgroup

create_bd_port -dir I -type rst mm_rst_n
create_bd_port -dir I -type rst ph_rst_n

set_property CONFIG.POLARITY ACTIVE_LOW [get_bd_ports mm_rst_n]
set_property CONFIG.POLARITY ACTIVE_LOW [get_bd_ports ph_rst_n]

# Connect clocks:
connect_bd_net [get_bd_ports mm_clk] [get_bd_pins jtag_axi_0/aclk]
connect_bd_net [get_bd_ports mm_clk] [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_ports mm_clk] [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net [get_bd_ports mm_clk] [get_bd_pins axi_interconnect_0/S01_ACLK]
connect_bd_net [get_bd_ports mm_clk] [get_bd_pins axi_interconnect_0/M00_ACLK]
connect_bd_net [get_bd_ports mm_clk] [get_bd_pins axi_interconnect_0/M01_ACLK]
connect_bd_net [get_bd_ports mm_clk] [get_bd_pins axi_interconnect_0/M02_ACLK]

# Connect resets:
connect_bd_net [get_bd_ports mm_rst_n] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_ports ph_rst_n] [get_bd_pins jtag_axi_0/aresetn]
connect_bd_net [get_bd_ports ph_rst_n] [get_bd_pins axi_interconnect_0/S00_ARESETN]
connect_bd_net [get_bd_ports ph_rst_n] [get_bd_pins axi_interconnect_0/S01_ARESETN]
connect_bd_net [get_bd_ports ph_rst_n] [get_bd_pins axi_interconnect_0/M00_ARESETN]
connect_bd_net [get_bd_ports ph_rst_n] [get_bd_pins axi_interconnect_0/M01_ARESETN]
connect_bd_net [get_bd_ports ph_rst_n] [get_bd_pins axi_interconnect_0/M02_ARESETN]



# Connect masters and slaves to AXI interconnect
connect_bd_intf_net [get_bd_intf_pins jtag_axi_0/M_AXI] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI]


startgroup
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 AXI4_LITE_SLAVE_ROM_INFO
set_property -dict [list CONFIG.NUM_READ_OUTSTANDING [get_property CONFIG.NUM_READ_OUTSTANDING [get_bd_intf_pins axi_interconnect_0/xbar/M00_AXI]] CONFIG.NUM_WRITE_OUTSTANDING [get_property CONFIG.NUM_WRITE_OUTSTANDING [get_bd_intf_pins axi_interconnect_0/xbar/M00_AXI]]] [get_bd_intf_ports AXI4_LITE_SLAVE_ROM_INFO]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_ports AXI4_LITE_SLAVE_ROM_INFO]
set_property -dict [list CONFIG.PROTOCOL {AXI4LITE}] [get_bd_intf_ports AXI4_LITE_SLAVE_ROM_INFO]
set_property -dict [list CONFIG.ADDR_WIDTH {10}] [get_bd_intf_ports AXI4_LITE_SLAVE_ROM_INFO]
endgroup

startgroup
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 AXI4_LITE_SLAVE_REG_INFO
set_property -dict [list CONFIG.NUM_READ_OUTSTANDING [get_property CONFIG.NUM_READ_OUTSTANDING [get_bd_intf_pins axi_interconnect_0/xbar/M01_AXI]] CONFIG.NUM_WRITE_OUTSTANDING [get_property CONFIG.NUM_WRITE_OUTSTANDING [get_bd_intf_pins axi_interconnect_0/xbar/M01_AXI]]] [get_bd_intf_ports AXI4_LITE_SLAVE_REG_INFO]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_ports AXI4_LITE_SLAVE_REG_INFO]
set_property -dict [list CONFIG.PROTOCOL {AXI4LITE}] [get_bd_intf_ports AXI4_LITE_SLAVE_REG_INFO]
set_property -dict [list CONFIG.ADDR_WIDTH {5}] [get_bd_intf_ports AXI4_LITE_SLAVE_REG_INFO]
endgroup

startgroup
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 AXI4_LITE_SLAVE_REG_LED
set_property -dict [list CONFIG.NUM_READ_OUTSTANDING [get_property CONFIG.NUM_READ_OUTSTANDING [get_bd_intf_pins axi_interconnect_0/xbar/M02_AXI]] CONFIG.NUM_WRITE_OUTSTANDING [get_property CONFIG.NUM_WRITE_OUTSTANDING [get_bd_intf_pins axi_interconnect_0/xbar/M02_AXI]]] [get_bd_intf_ports AXI4_LITE_SLAVE_REG_LED]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_ports AXI4_LITE_SLAVE_REG_LED]
set_property -dict [list CONFIG.PROTOCOL {AXI4LITE}] [get_bd_intf_ports AXI4_LITE_SLAVE_REG_LED]
set_property -dict [list CONFIG.ADDR_WIDTH {2}] [get_bd_intf_ports AXI4_LITE_SLAVE_REG_LED]
endgroup

startgroup
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 AXI4_LITE_MASTER
set_property -dict [list CONFIG.ID_WIDTH [get_property CONFIG.ID_WIDTH [get_bd_intf_pins axi_interconnect_0/xbar/S01_AXI]] CONFIG.HAS_REGION [get_property CONFIG.HAS_REGION [get_bd_intf_pins axi_interconnect_0/xbar/S01_AXI]] CONFIG.NUM_READ_OUTSTANDING [get_property CONFIG.NUM_READ_OUTSTANDING [get_bd_intf_pins axi_interconnect_0/xbar/S01_AXI]] CONFIG.NUM_WRITE_OUTSTANDING [get_property CONFIG.NUM_WRITE_OUTSTANDING [get_bd_intf_pins axi_interconnect_0/xbar/S01_AXI]]] [get_bd_intf_ports AXI4_LITE_MASTER]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/S01_AXI] [get_bd_intf_ports AXI4_LITE_MASTER]
set_property -dict [list CONFIG.PROTOCOL {AXI4LITE}] [get_bd_intf_ports AXI4_LITE_MASTER]
set_property -dict [list CONFIG.ID_WIDTH {0}] [get_bd_intf_ports AXI4_LITE_MASTER]
endgroup


# Assign base addresses:
assign_bd_address [get_bd_addr_segs {AXI4_LITE_SLAVE_ROM_INFO/Reg }]
set_property range 4K [get_bd_addr_segs {jtag_axi_0/Data/SEG_AXI4_LITE_SLAVE_ROM_INFO_Reg}]
set_property offset 0x00001000 [get_bd_addr_segs {jtag_axi_0/Data/SEG_AXI4_LITE_SLAVE_ROM_INFO_Reg}]
set_property range 4K [get_bd_addr_segs {AXI4_LITE_MASTER/SEG_AXI4_LITE_SLAVE_ROM_INFO_Reg}]
set_property offset 0x00001000 [get_bd_addr_segs {AXI4_LITE_MASTER/SEG_AXI4_LITE_SLAVE_ROM_INFO_Reg}]


assign_bd_address [get_bd_addr_segs {AXI4_LITE_SLAVE_REG_INFO/Reg }]
set_property range 4K [get_bd_addr_segs {jtag_axi_0/Data/SEG_AXI4_LITE_SLAVE_REG_INFO_Reg}]
set_property offset 0x00000000 [get_bd_addr_segs {jtag_axi_0/Data/SEG_AXI4_LITE_SLAVE_REG_INFO_Reg}]
set_property range 4K [get_bd_addr_segs {AXI4_LITE_MASTER/SEG_AXI4_LITE_SLAVE_REG_INFO_Reg}]
set_property offset 0x00000000 [get_bd_addr_segs {AXI4_LITE_MASTER/SEG_AXI4_LITE_SLAVE_REG_INFO_Reg}]


assign_bd_address [get_bd_addr_segs {AXI4_LITE_SLAVE_REG_LED/Reg }]
set_property range 4K [get_bd_addr_segs {jtag_axi_0/Data/SEG_AXI4_LITE_SLAVE_REG_LED_Reg}]
set_property offset 0x40000000 [get_bd_addr_segs {jtag_axi_0/Data/SEG_AXI4_LITE_SLAVE_REG_LED_Reg}]
set_property range 4K [get_bd_addr_segs {AXI4_LITE_MASTER/SEG_AXI4_LITE_SLAVE_REG_LED_Reg}]
set_property offset 0x40000000 [get_bd_addr_segs {AXI4_LITE_MASTER/SEG_AXI4_LITE_SLAVE_REG_LED_Reg}]


# Finish, Check and Save:
regenerate_bd_layout
validate_bd_design
save_bd_design
#saved to /home/hiemstra/svnlowcbf/LOWCBF/Firmware/boards/gemini/designs/gmi_led/vivado/bd/src/build/gmi_led_axi.srcs/sources_1/bd/gmi_led_axi/gmi_led_axi.bd

# Optionally derive a wrapper:
make_wrapper -files [get_files /home/hiemstra/svnlowcbf/LOWCBF/Firmware/boards/gemini/designs/gmi_led/vivado/bd/src/build/gmi_led_axi.srcs/sources_1/bd/gmi_led_axi/gmi_led_axi.bd] -top

#VHDL Output written to : /home/hiemstra/svnlowcbf/LOWCBF/Firmware/boards/gemini/designs/gmi_led/vivado/bd/src/build/gmi_led_axi.srcs/sources_1/bd/gmi_led_axi/hdl/gmi_led_axi.vhd
#VHDL Output written to : /home/hiemstra/svnlowcbf/LOWCBF/Firmware/boards/gemini/designs/gmi_led/vivado/bd/src/build/gmi_led_axi.srcs/sources_1/bd/gmi_led_axi/hdl/gmi_led_axi_wrapper.vhd

write_bd_layout -force -format pdf -orientation portrait /home/hiemstra/svnlowcbf/LOWCBF/Firmware/boards/gemini/designs/gmi_led/vivado/bd/src/gmi_led_axi.pdf
#written to: /home/hiemstra/svnlowcbf/LOWCBF/Firmware/boards/gemini/designs/gmi_led/vivado/bd/src/gmi_led_axi.pdf
exit

