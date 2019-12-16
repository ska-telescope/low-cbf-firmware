set componentName gemini_server_test

##########################################

create_bd_design $componentName

# Create interface ports
set M02_AXI_LITE [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M02_AXI_LITE ]
set_property -dict [ list CONFIG.ADDR_WIDTH {32} CONFIG.DATA_WIDTH {32} CONFIG.FREQ_HZ {156250000} CONFIG.NUM_READ_OUTSTANDING {2} CONFIG.NUM_WRITE_OUTSTANDING {2} CONFIG.PROTOCOL {AXI4LITE} ] $M02_AXI_LITE

set M03_AXI_LITE [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M03_AXI_LITE ]
set_property -dict [ list CONFIG.ADDR_WIDTH {32} CONFIG.DATA_WIDTH {32} CONFIG.FREQ_HZ {156250000} CONFIG.NUM_READ_OUTSTANDING {2} CONFIG.NUM_WRITE_OUTSTANDING {2} CONFIG.PROTOCOL {AXI4LITE} ] $M03_AXI_LITE

set S00_AXI [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI ]
set_property -dict [ list CONFIG.ADDR_WIDTH {15} CONFIG.ARUSER_WIDTH {0} CONFIG.AWUSER_WIDTH {0} CONFIG.BUSER_WIDTH {0} CONFIG.DATA_WIDTH {32} CONFIG.FREQ_HZ {156250000} CONFIG.HAS_BRESP {1} CONFIG.HAS_BURST {1} CONFIG.HAS_CACHE {1} CONFIG.HAS_LOCK {1} CONFIG.HAS_PROT {1} CONFIG.HAS_QOS {1} CONFIG.HAS_REGION {0} CONFIG.HAS_RRESP {1} CONFIG.HAS_WSTRB {1} CONFIG.ID_WIDTH {0} CONFIG.MAX_BURST_LENGTH {256} CONFIG.NUM_READ_OUTSTANDING {2} CONFIG.NUM_READ_THREADS {1} CONFIG.NUM_WRITE_OUTSTANDING {2} CONFIG.NUM_WRITE_THREADS {1} CONFIG.PROTOCOL {AXI4} CONFIG.READ_WRITE_MODE {READ_WRITE} CONFIG.RUSER_BITS_PER_BYTE {0} CONFIG.RUSER_WIDTH {0} CONFIG.SUPPORTS_NARROW_BURST {1} CONFIG.WUSER_BITS_PER_BYTE {0} CONFIG.WUSER_WIDTH {0} ] $S00_AXI

# Create ports
set ACLK [ create_bd_port -dir I -type clk ACLK ]
set_property -dict [ list CONFIG.FREQ_HZ {156250000} ] $ACLK
set ARESETN [ create_bd_port -dir I -type rst ARESETN ]

# Create instance: axi_bram_ctrl_0, and set properties
set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]
set_property -dict [ list CONFIG.SINGLE_PORT_BRAM {1}] $axi_bram_ctrl_0

# Create instance: axi_bram_ctrl_1, and set properties
set axi_bram_ctrl_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_1 ]
set_property -dict [ list CONFIG.SINGLE_PORT_BRAM {1}] $axi_bram_ctrl_1

# Create instance: axi_interconnect_0, and set properties
set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
set_property -dict [ list CONFIG.NUM_MI {4} CONFIG.STRATEGY {1} ] $axi_interconnect_0

# Create instance: blk_mem_gen_0, and set properties
set blk_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0 ]

# Create instance: blk_mem_gen_1, and set properties
set blk_mem_gen_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_1 ]

# Create interface connections
connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_ports S00_AXI] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_1/BRAM_PORTA]
connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] [get_bd_intf_pins axi_interconnect_0/M00_AXI]
connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins axi_bram_ctrl_1/S_AXI] [get_bd_intf_pins axi_interconnect_0/M01_AXI]
connect_bd_intf_net -intf_net axi_interconnect_0_M02_AXI [get_bd_intf_ports M02_AXI_LITE] [get_bd_intf_pins axi_interconnect_0/M02_AXI]
connect_bd_intf_net -intf_net axi_interconnect_0_M03_AXI [get_bd_intf_ports M03_AXI_LITE] [get_bd_intf_pins axi_interconnect_0/M03_AXI]

# Create port connections
connect_bd_net -net ACLK_1 [get_bd_ports ACLK] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_bram_ctrl_1/s_axi_aclk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_0/M02_ACLK] [get_bd_pins axi_interconnect_0/M03_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net -net M03_ARESETN_1 [get_bd_ports ARESETN] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_1/s_axi_aresetn] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_0/M02_ARESETN] [get_bd_pins axi_interconnect_0/M03_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN]

# Create address segments
create_bd_addr_seg -range 0x00001000 -offset 0x00002000 [get_bd_addr_spaces S00_AXI] [get_bd_addr_segs M02_AXI_LITE/Reg] SEG_M02_AXI_Reg
create_bd_addr_seg -range 0x00001000 -offset 0x00004000 [get_bd_addr_spaces S00_AXI] [get_bd_addr_segs M03_AXI_LITE/Reg] SEG_M03_AXI_Reg
create_bd_addr_seg -range 0x00001000 -offset 0x00000000 [get_bd_addr_spaces S00_AXI] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0
create_bd_addr_seg -range 0x00001000 -offset 0x00001000 [get_bd_addr_spaces S00_AXI] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0] SEG_axi_bram_ctrl_1_Mem0

save_bd_design $componentName
validate_bd_design

close_bd_design $componentName

##########################################

if {[string equal [current_project] "New Project"]} {
  generate_target Simulation [get_files -of_objects [get_fileset sources_1] ${componentName}.bd]

  set filelist [get_files -of_objects [get_files -of_objects [get_fileset sources_1] ${componentName}.bd] -compile_order sources -used_in simulation]

  file copy -force {*}$filelist .
  set ipBuildScript [open ${componentName}.do w]
  foreach file $filelist {

    set element [file tail $file]

    # Build compilation script
    if {[string equal [file extension $element] ".vhd"] || [string equal [file extension $element] ".vhdl"]} {
      set entry "vcom $element"
    } elseif {[string equal [file extension $element] ".vh"]} {
      set entry "#vlog $element # Header file"
    } else {
      set entry "vlog $element"
    }

    puts $ipBuildScript $entry
  }

  close $ipBuildScript


} else {
  generate_target all [get_files -of_objects [get_fileset sources_1] ${componentName}.bd]
}
