startgroup

# Create BD design
create_bd_design "<fpga_name>_bd"
# open_bd_design "<fpga_name>_bd"

# Create interconnect
# Configure number of slave and master ports and other settings
<{create_interconnects}>create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_{}
<{}>set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {<i_nof_slaves>} CONFIG.STRATEGY {1} CONFIG.S00_HAS_REGSLICE {3} \
<{}>CONFIG.M<i>_HAS_REGSLICE {4} \
<{}>] [get_bd_cells axi_interconnect_{}]

# Create and connect ports
# Create clk port and connect
create_bd_port -dir I -type clk ACLK
set_property -dict [list CONFIG.FREQ_HZ 100000000] [get_bd_ports ACLK]
<{connect_clock_pins}>connect_bd_net [get_bd_pins /axi_interconnect_{0}/{2}{1:0=2d}_ACLK] [get_bd_ports ACLK]
# Create reset port and connect
create_bd_port -dir I -type rst ARESETN
<{connect_reset_pins}>connect_bd_net [get_bd_pins /axi_interconnect_{0}/{2}{1:0=2d}_ARESETN] [get_bd_ports ARESETN]
set_property CONFIG.POLARITY ACTIVE_LOW [get_bd_ports ARESETN]
# Create slave interface port and connect
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI
connect_bd_intf_net [get_bd_intf_pins /axi_interconnect_0/S00_AXI] [get_bd_intf_ports S00_AXI]
# Create, connect, configure master inface ports
<{create_master_ports}>create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M<i>_AXI
<{}>#set_property -dict [list CONFIG.NUM_READ_OUTSTANDING [get_property CONFIG.NUM_READ_OUTSTANDING [get_bd_intf_pins axi_interconnect_{0}/xbar/M{1:0=2d}_AXI]] CONFIG.NUM_WRITE_OUTSTANDING [get_property CONFIG.NUM_WRITE_OUTSTANDING [get_bd_intf_pins axi_interconnect_{0}/xbar/M{1:0=2d}_AXI]]] [get_bd_intf_ports M{2:0=2d}_AXI]
<{}>set_property -dict [list CONFIG.HAS_QOS {0} CONFIG.PROTOCOL {<protocol>}] [get_bd_intf_ports M<i>_AXI]
<{}>connect_bd_intf_net [get_bd_intf_pins /axi_interconnect_{0}/M{1:0=2d}_AXI] [get_bd_intf_ports M{2:0=2d}_AXI]
<{}># Daisy chain interconnects
<{}>connect_bd_intf_net [get_bd_intf_pins /axi_interconnect_{0}/M15_AXI] [get_bd_intf_pins /axi_interconnect_{1}/S00_AXI]
<{}>set_property -dict [list CONFIG.READ_WRITE_MODE {<access_mode>_ONLY}] [get_bd_intf_ports M<i>_AXI]
assign_bd_address
# Set slave ranges and addresses
<{set_address_small_range}>set_property range <range>K [get_bd_addr_segs {S00_AXI/SEG_M<i>_AXI_Reg}]
<{set_address_map}>set_property offset 0x<address> [get_bd_addr_segs {S00_AXI/SEG_M<i>_AXI_Reg}]
<{set_address_range}>set_property range <range>K [get_bd_addr_segs {S00_AXI/SEG_M<i>_AXI_Reg}]

save_bd_design "<fpga_name>_bd"
validate_bd_design
endgroup
set bd_dir "$workingDir/$proj_dir/<fpga_name>.srcs/sources_1/bd/<fpga_name>_bd"
generate_target all [get_files $bd_dir/<fpga_name>_bd.bd]
make_wrapper -files [get_files $bd_dir/<fpga_name>_bd.bd] -top
read_vhdl $bd_dir/hdl/<fpga_name>_bd_wrapper.vhd
set_property library <fpga_name>_lib [get_files $bd_dir/hdl/<fpga_name>_bd_wrapper.vhd]
