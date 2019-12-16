
################################################################
# This is a generated script based on design: system
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2016.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source system_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvu190-flgc2104-2-e-es2
   set_property BOARD_PART xilinx.com:vcu110:part0:1.0 [current_project]
}


# CHANGE DESIGN NAME HERE
set design_name system

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: microblaze_0_local_memory
proc create_hier_cell_microblaze_0_local_memory { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_microblaze_0_local_memory() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB

  # Create pins
  create_bd_pin -dir I -type clk LMB_Clk
  create_bd_pin -dir I -from 0 -to 0 -type rst LMB_Rst

  # Create instance: dlmb_bram_if_cntlr, and set properties
  set dlmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 dlmb_bram_if_cntlr ]
  set_property -dict [ list \
CONFIG.C_ECC {0} \
 ] $dlmb_bram_if_cntlr

  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 dlmb_v10 ]

  # Create instance: ilmb_bram_if_cntlr, and set properties
  set ilmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 ilmb_bram_if_cntlr ]
  set_property -dict [ list \
CONFIG.C_ECC {0} \
 ] $ilmb_bram_if_cntlr

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 ilmb_v10 ]

  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.3 lmb_bram ]
  set_property -dict [ list \
CONFIG.Memory_Type {True_Dual_Port_RAM} \
CONFIG.use_bram_block {BRAM_Controller} \
 ] $lmb_bram

  # Create interface connections
  connect_bd_intf_net -intf_net microblaze_1_dlmb [get_bd_intf_pins DLMB] [get_bd_intf_pins dlmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_1_dlmb_bus [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB] [get_bd_intf_pins dlmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net microblaze_1_dlmb_cntlr [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net microblaze_1_ilmb [get_bd_intf_pins ILMB] [get_bd_intf_pins ilmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_1_ilmb_bus [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB] [get_bd_intf_pins ilmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net microblaze_1_ilmb_cntlr [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTB]

  # Create port connections
  connect_bd_net -net microblaze_1_Clk [get_bd_pins LMB_Clk] [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk] [get_bd_pins dlmb_v10/LMB_Clk] [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk] [get_bd_pins ilmb_v10/LMB_Clk]
  connect_bd_net -net microblaze_1_LMB_Rst [get_bd_pins LMB_Rst] [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst] [get_bd_pins dlmb_v10/SYS_Rst] [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst] [get_bd_pins ilmb_v10/SYS_Rst]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set FERR_N [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 FERR_N ]
  set HMC_REFCLK_SEL [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 HMC_REFCLK_SEL ]
  set LxRXPS [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 LxRXPS ]
  set LxTXPS [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 LxTXPS ]
  set REFCLK_BOOT [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 REFCLK_BOOT ]
  set iic_main [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 iic_main ]
  set rs232_uart [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 rs232_uart ]

  # Create ports
  set gth_sysclk_i [ create_bd_port -dir I -type clk gth_sysclk_i ]
  set_property -dict [ list \
CONFIG.FREQ_HZ {300000000} \
 ] $gth_sysclk_i
  set iic_mux_reset_b [ create_bd_port -dir O -from 2 -to 0 iic_mux_reset_b ]
  set reset [ create_bd_port -dir I -type rst reset ]
  set_property -dict [ list \
CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $reset

  # Create instance: HMC_FATAL_ERROR, and set properties
  set HMC_FATAL_ERROR [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 HMC_FATAL_ERROR ]
  set_property -dict [ list \
CONFIG.C_ALL_INPUTS {1} \
CONFIG.C_GPIO_WIDTH {1} \
 ] $HMC_FATAL_ERROR

  # Create instance: HMC_READ_POWER, and set properties
  set HMC_READ_POWER [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 HMC_READ_POWER ]
  set_property -dict [ list \
CONFIG.C_ALL_INPUTS {1} \
CONFIG.C_GPIO_WIDTH {2} \
 ] $HMC_READ_POWER

  # Create instance: HMC_REFCLK_SELECT, and set properties
  set HMC_REFCLK_SELECT [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 HMC_REFCLK_SELECT ]
  set_property -dict [ list \
CONFIG.C_ALL_OUTPUTS {1} \
CONFIG.C_DOUT_DEFAULT {0xFFFFFFFF} \
CONFIG.C_GPIO_WIDTH {1} \
 ] $HMC_REFCLK_SELECT

  # Create instance: HMC_SET_POWER, and set properties
  set HMC_SET_POWER [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 HMC_SET_POWER ]
  set_property -dict [ list \
CONFIG.C_ALL_OUTPUTS {1} \
CONFIG.C_DOUT_DEFAULT {0xFFFFFFFF} \
CONFIG.C_GPIO_WIDTH {2} \
 ] $HMC_SET_POWER

  # Create instance: REFCLK_BOOT, and set properties
  set REFCLK_BOOT [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 REFCLK_BOOT ]
  set_property -dict [ list \
CONFIG.C_ALL_OUTPUTS {1} \
CONFIG.C_DOUT_DEFAULT {0x00000000} \
CONFIG.C_GPIO_WIDTH {2} \
 ] $REFCLK_BOOT

  # Create instance: axi_iic_0, and set properties
  set axi_iic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.0 axi_iic_0 ]
  set_property -dict [ list \
CONFIG.C_DEFAULT_VALUE {0xFF} \
CONFIG.C_GPO_WIDTH {3} \
CONFIG.C_SCL_INERTIAL_DELAY {5} \
CONFIG.C_SDA_INERTIAL_DELAY {5} \
CONFIG.IIC_BOARD_INTERFACE {iic_main} \
 ] $axi_iic_0

  # Create instance: axi_uart16550_0, and set properties
  set axi_uart16550_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uart16550:2.0 axi_uart16550_0 ]
  set_property -dict [ list \
CONFIG.C_EXTERNAL_XIN_CLK_HZ {25000000} \
CONFIG.C_S_AXI_ACLK_FREQ_HZ {100000000} \
CONFIG.UART_BOARD_INTERFACE {rs232_uart} \
CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_uart16550_0

  # Need to retain value_src of defaults
  set_property -dict [ list \
CONFIG.C_EXTERNAL_XIN_CLK_HZ.VALUE_SRC {DEFAULT} \
CONFIG.C_S_AXI_ACLK_FREQ_HZ.VALUE_SRC {DEFAULT} \
 ] $axi_uart16550_0

  # Create instance: clk_wiz_1, and set properties
  set clk_wiz_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:5.3 clk_wiz_1 ]
  set_property -dict [ list \
CONFIG.CLKIN1_JITTER_PS {33.330000000000005} \
CONFIG.CLKOUT1_JITTER {129.666} \
CONFIG.CLKOUT1_PHASE_ERROR {98.575} \
CONFIG.MMCM_CLKFBOUT_MULT_F {10.000} \
CONFIG.MMCM_CLKIN1_PERIOD {3.333} \
CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
CONFIG.MMCM_CLKOUT0_DIVIDE_F {10.000} \
CONFIG.MMCM_DIVCLK_DIVIDE {3} \
CONFIG.PRIM_IN_FREQ {300.000} \
CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} \
CONFIG.RESET_BOARD_INTERFACE {reset} \
CONFIG.USE_BOARD_FLOW {true} \
 ] $clk_wiz_1

  # Need to retain value_src of defaults
  set_property -dict [ list \
CONFIG.CLKOUT1_PHASE_ERROR.VALUE_SRC {DEFAULT} \
CONFIG.MMCM_CLKFBOUT_MULT_F.VALUE_SRC {DEFAULT} \
CONFIG.MMCM_CLKIN1_PERIOD.VALUE_SRC {DEFAULT} \
CONFIG.MMCM_CLKIN2_PERIOD.VALUE_SRC {DEFAULT} \
CONFIG.MMCM_CLKOUT0_DIVIDE_F.VALUE_SRC {DEFAULT} \
CONFIG.MMCM_DIVCLK_DIVIDE.VALUE_SRC {DEFAULT} \
 ] $clk_wiz_1

  # Create instance: mdm_1, and set properties
  set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm:3.2 mdm_1 ]

  # Create instance: microblaze_0, and set properties
  set microblaze_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:9.6 microblaze_0 ]
  set_property -dict [ list \
CONFIG.C_DEBUG_ENABLED {1} \
CONFIG.C_D_AXI {1} \
CONFIG.C_D_LMB {1} \
CONFIG.C_I_LMB {1} \
 ] $microblaze_0

  # Create instance: microblaze_0_axi_intc, and set properties
  set microblaze_0_axi_intc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 microblaze_0_axi_intc ]
  set_property -dict [ list \
CONFIG.C_ASYNC_INTR {0xFFFFFFFC} \
CONFIG.C_DISABLE_SYNCHRONIZERS {1} \
CONFIG.C_HAS_FAST {1} \
CONFIG.C_KIND_OF_INTR {0xFFFFFFFC} \
 ] $microblaze_0_axi_intc

  # Create instance: microblaze_0_axi_periph, and set properties
  set microblaze_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 microblaze_0_axi_periph ]
  set_property -dict [ list \
CONFIG.NUM_MI {8} \
 ] $microblaze_0_axi_periph

  # Create instance: microblaze_0_local_memory
  create_hier_cell_microblaze_0_local_memory [current_bd_instance .] microblaze_0_local_memory

  # Create instance: microblaze_0_xlconcat, and set properties
  set microblaze_0_xlconcat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 microblaze_0_xlconcat ]

  # Create instance: rst_clk_wiz_1_100M, and set properties
  set rst_clk_wiz_1_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_1_100M ]
  set_property -dict [ list \
CONFIG.C_AUX_RESET_HIGH {0} \
CONFIG.RESET_BOARD_INTERFACE {reset} \
CONFIG.USE_BOARD_FLOW {true} \
 ] $rst_clk_wiz_1_100M

  # Create interface connections
  connect_bd_intf_net -intf_net HMC_FATAL_ERROR_GPIO [get_bd_intf_ports FERR_N] [get_bd_intf_pins HMC_FATAL_ERROR/GPIO]
  connect_bd_intf_net -intf_net HMC_REFCLK_SELECT_GPIO [get_bd_intf_ports HMC_REFCLK_SEL] [get_bd_intf_pins HMC_REFCLK_SELECT/GPIO]
  connect_bd_intf_net -intf_net LxRXPS_GPIO [get_bd_intf_ports LxRXPS] [get_bd_intf_pins HMC_SET_POWER/GPIO]
  connect_bd_intf_net -intf_net LxTXPS_GPIO [get_bd_intf_ports LxTXPS] [get_bd_intf_pins HMC_READ_POWER/GPIO]
  connect_bd_intf_net -intf_net REFCLK_BOOT_GPIO [get_bd_intf_ports REFCLK_BOOT] [get_bd_intf_pins REFCLK_BOOT/GPIO]
  connect_bd_intf_net -intf_net axi_iic_0_IIC [get_bd_intf_ports iic_main] [get_bd_intf_pins axi_iic_0/IIC]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins microblaze_0_axi_intc/s_axi] [get_bd_intf_pins microblaze_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins axi_uart16550_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M02_AXI [get_bd_intf_pins axi_iic_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M03_AXI [get_bd_intf_pins REFCLK_BOOT/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M04_AXI [get_bd_intf_pins HMC_REFCLK_SELECT/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M04_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M05_AXI [get_bd_intf_pins HMC_READ_POWER/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M05_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M06_AXI [get_bd_intf_pins HMC_SET_POWER/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M06_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M07_AXI [get_bd_intf_pins HMC_FATAL_ERROR/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M07_AXI]
  connect_bd_intf_net -intf_net axi_uart16550_0_UART [get_bd_intf_ports rs232_uart] [get_bd_intf_pins axi_uart16550_0/UART]
  connect_bd_intf_net -intf_net microblaze_0_axi_intc_interrupt [get_bd_intf_pins microblaze_0/INTERRUPT] [get_bd_intf_pins microblaze_0_axi_intc/interrupt]
  connect_bd_intf_net -intf_net microblaze_1_M_AXI_DP [get_bd_intf_pins microblaze_0/M_AXI_DP] [get_bd_intf_pins microblaze_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net microblaze_1_debug [get_bd_intf_pins mdm_1/MBDEBUG_0] [get_bd_intf_pins microblaze_0/DEBUG]
  connect_bd_intf_net -intf_net microblaze_1_dlmb_1 [get_bd_intf_pins microblaze_0/DLMB] [get_bd_intf_pins microblaze_0_local_memory/DLMB]
  connect_bd_intf_net -intf_net microblaze_1_ilmb_1 [get_bd_intf_pins microblaze_0/ILMB] [get_bd_intf_pins microblaze_0_local_memory/ILMB]

  # Create port connections
  connect_bd_net -net axi_iic_0_gpo [get_bd_ports iic_mux_reset_b] [get_bd_pins axi_iic_0/gpo]
  connect_bd_net -net axi_iic_0_iic2intc_irpt [get_bd_pins axi_iic_0/iic2intc_irpt] [get_bd_pins microblaze_0_xlconcat/In1]
  connect_bd_net -net axi_uart16550_0_ip2intc_irpt [get_bd_pins axi_uart16550_0/ip2intc_irpt] [get_bd_pins microblaze_0_xlconcat/In0]
  connect_bd_net -net clk_in1_1 [get_bd_ports gth_sysclk_i] [get_bd_pins clk_wiz_1/clk_in1]
  connect_bd_net -net clk_wiz_1_locked [get_bd_pins clk_wiz_1/locked] [get_bd_pins rst_clk_wiz_1_100M/dcm_locked]
  connect_bd_net -net cpu_reset_1 [get_bd_ports reset] [get_bd_pins clk_wiz_1/reset] [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins mdm_1/Debug_SYS_Rst] [get_bd_pins rst_clk_wiz_1_100M/mb_debug_sys_rst]
  connect_bd_net -net microblaze_0_intr [get_bd_pins microblaze_0_axi_intc/intr] [get_bd_pins microblaze_0_xlconcat/dout]
  connect_bd_net -net microblaze_1_Clk [get_bd_pins HMC_FATAL_ERROR/s_axi_aclk] [get_bd_pins HMC_READ_POWER/s_axi_aclk] [get_bd_pins HMC_REFCLK_SELECT/s_axi_aclk] [get_bd_pins HMC_SET_POWER/s_axi_aclk] [get_bd_pins REFCLK_BOOT/s_axi_aclk] [get_bd_pins axi_iic_0/s_axi_aclk] [get_bd_pins axi_uart16550_0/s_axi_aclk] [get_bd_pins clk_wiz_1/clk_out1] [get_bd_pins microblaze_0/Clk] [get_bd_pins microblaze_0_axi_intc/processor_clk] [get_bd_pins microblaze_0_axi_intc/s_axi_aclk] [get_bd_pins microblaze_0_axi_periph/ACLK] [get_bd_pins microblaze_0_axi_periph/M00_ACLK] [get_bd_pins microblaze_0_axi_periph/M01_ACLK] [get_bd_pins microblaze_0_axi_periph/M02_ACLK] [get_bd_pins microblaze_0_axi_periph/M03_ACLK] [get_bd_pins microblaze_0_axi_periph/M04_ACLK] [get_bd_pins microblaze_0_axi_periph/M05_ACLK] [get_bd_pins microblaze_0_axi_periph/M06_ACLK] [get_bd_pins microblaze_0_axi_periph/M07_ACLK] [get_bd_pins microblaze_0_axi_periph/S00_ACLK] [get_bd_pins microblaze_0_local_memory/LMB_Clk] [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk]
  connect_bd_net -net rst_clk_wiz_1_100M_bus_struct_reset [get_bd_pins microblaze_0_local_memory/LMB_Rst] [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_interconnect_aresetn [get_bd_pins microblaze_0_axi_periph/ARESETN] [get_bd_pins rst_clk_wiz_1_100M/interconnect_aresetn]
  connect_bd_net -net rst_clk_wiz_1_100M_mb_reset [get_bd_pins microblaze_0/Reset] [get_bd_pins microblaze_0_axi_intc/processor_rst] [get_bd_pins rst_clk_wiz_1_100M/mb_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins HMC_FATAL_ERROR/s_axi_aresetn] [get_bd_pins HMC_READ_POWER/s_axi_aresetn] [get_bd_pins HMC_REFCLK_SELECT/s_axi_aresetn] [get_bd_pins HMC_SET_POWER/s_axi_aresetn] [get_bd_pins REFCLK_BOOT/s_axi_aresetn] [get_bd_pins axi_iic_0/s_axi_aresetn] [get_bd_pins axi_uart16550_0/s_axi_aresetn] [get_bd_pins microblaze_0_axi_intc/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph/M00_ARESETN] [get_bd_pins microblaze_0_axi_periph/M01_ARESETN] [get_bd_pins microblaze_0_axi_periph/M02_ARESETN] [get_bd_pins microblaze_0_axi_periph/M03_ARESETN] [get_bd_pins microblaze_0_axi_periph/M04_ARESETN] [get_bd_pins microblaze_0_axi_periph/M05_ARESETN] [get_bd_pins microblaze_0_axi_periph/M06_ARESETN] [get_bd_pins microblaze_0_axi_periph/M07_ARESETN] [get_bd_pins microblaze_0_axi_periph/S00_ARESETN] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn]

  # Create address segments
  create_bd_addr_seg -range 0x00010000 -offset 0x40030000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs HMC_FATAL_ERROR/S_AXI/Reg] SEG_HMC_FATAL_ERROR_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40040000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs HMC_READ_POWER/S_AXI/Reg] SEG_HMC_READ_POWER_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40010000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs HMC_REFCLK_SELECT/S_AXI/Reg] SEG_HMC_REFCLK_SELECT_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40020000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs HMC_SET_POWER/S_AXI/Reg] SEG_HMC_SET_POWER_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40000000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs REFCLK_BOOT/S_AXI/Reg] SEG_REFCLK_BOOT_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40800000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_iic_0/S_AXI/Reg] SEG_axi_iic_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40400000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_uart16550_0/S_AXI/Reg] SEG_axi_uart16550_0_Reg
  create_bd_addr_seg -range 0x00080000 -offset 0x00000000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs microblaze_0_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] SEG_dlmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x00080000 -offset 0x00000000 [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs microblaze_0_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] SEG_ilmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x00010000 -offset 0x41200000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs microblaze_0_axi_intc/s_axi/Reg] SEG_microblaze_0_axi_intc_Reg

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   guistr: "# # String gsaved with Nlview 6.5.12  2016-01-29 bk=1.3547 VDI=39 GEI=35 GUI=JA:1.6
#  -string -flagsOSRD
preplace port LxTXPS -pg 1 -y 810 -defaultsOSRD
preplace port HMC_REFCLK_SEL -pg 1 -y 930 -defaultsOSRD
preplace port LxRXPS -pg 1 -y 690 -defaultsOSRD
preplace port FERR_N -pg 1 -y 570 -defaultsOSRD
preplace port rs232_uart -pg 1 -y 430 -defaultsOSRD
preplace port iic_main -pg 1 -y 150 -defaultsOSRD
preplace port gth_sysclk_i -pg 1 -y 230 -defaultsOSRD
preplace port REFCLK_BOOT -pg 1 -y 310 -defaultsOSRD
preplace port reset -pg 1 -y 210 -defaultsOSRD
preplace portBus iic_mux_reset_b -pg 1 -y 190 -defaultsOSRD
preplace inst axi_iic_0 -pg 1 -lvl 6 -y 170 -defaultsOSRD
preplace inst HMC_SET_POWER -pg 1 -lvl 6 -y 690 -defaultsOSRD
preplace inst HMC_READ_POWER -pg 1 -lvl 6 -y 810 -defaultsOSRD
preplace inst HMC_FATAL_ERROR -pg 1 -lvl 6 -y 570 -defaultsOSRD
preplace inst microblaze_0_axi_periph -pg 1 -lvl 5 -y 480 -defaultsOSRD
preplace inst microblaze_0_xlconcat -pg 1 -lvl 2 -y 120 -defaultsOSRD
preplace inst HMC_REFCLK_SELECT -pg 1 -lvl 6 -y 930 -defaultsOSRD
preplace inst microblaze_0_axi_intc -pg 1 -lvl 3 -y 110 -defaultsOSRD
preplace inst mdm_1 -pg 1 -lvl 3 -y 450 -defaultsOSRD
preplace inst microblaze_0 -pg 1 -lvl 4 -y 450 -defaultsOSRD
preplace inst rst_clk_wiz_1_100M -pg 1 -lvl 2 -y 300 -defaultsOSRD
preplace inst axi_uart16550_0 -pg 1 -lvl 6 -y 440 -defaultsOSRD
preplace inst REFCLK_BOOT -pg 1 -lvl 6 -y 310 -defaultsOSRD
preplace inst microblaze_0_local_memory -pg 1 -lvl 5 -y 840 -defaultsOSRD
preplace inst clk_wiz_1 -pg 1 -lvl 1 -y 220 -defaultsOSRD
preplace netloc microblaze_1_M_AXI_DP 1 4 1 1310
preplace netloc HMC_FATAL_ERROR_GPIO 1 6 1 NJ
preplace netloc microblaze_1_dlmb_1 1 4 1 1300
preplace netloc REFCLK_BOOT_GPIO 1 6 1 NJ
preplace netloc HMC_REFCLK_SELECT_GPIO 1 6 1 NJ
preplace netloc microblaze_0_intr 1 2 1 N
preplace netloc axi_iic_0_iic2intc_irpt 1 1 6 230 200 NJ 210 NJ 100 NJ 100 NJ 100 1920
preplace netloc clk_in1_1 1 0 1 NJ
preplace netloc axi_interconnect_0_M02_AXI 1 5 1 1640
preplace netloc axi_uart16550_0_ip2intc_irpt 1 1 6 220 190 NJ 220 NJ 220 NJ 220 NJ 240 1920
preplace netloc microblaze_1_ilmb_1 1 4 1 1280
preplace netloc cpu_reset_1 1 0 2 20 160 NJ
preplace netloc axi_uart16550_0_UART 1 6 1 NJ
preplace netloc axi_interconnect_0_M07_AXI 1 5 1 N
preplace netloc axi_interconnect_0_M04_AXI 1 5 1 1650
preplace netloc rst_clk_wiz_1_100M_interconnect_aresetn 1 2 3 NJ 320 NJ 320 N
preplace netloc rst_clk_wiz_1_100M_bus_struct_reset 1 2 3 N 280 NJ 280 NJ
preplace netloc LxRXPS_GPIO 1 6 1 NJ
preplace netloc rst_clk_wiz_1_100M_peripheral_aresetn 1 2 4 550 250 NJ 250 1330 190 1660
preplace netloc rst_clk_wiz_1_100M_mb_reset 1 2 2 590 260 NJ
preplace netloc microblaze_1_Clk 1 1 5 220 210 560 240 840 240 1320 200 1690
preplace netloc clk_wiz_1_locked 1 1 1 200
preplace netloc microblaze_1_debug 1 3 1 N
preplace netloc axi_interconnect_0_M05_AXI 1 5 1 1640
preplace netloc axi_interconnect_0_M00_AXI 1 2 4 550 10 NJ 10 NJ 10 1630
preplace netloc axi_iic_0_IIC 1 6 1 NJ
preplace netloc axi_iic_0_gpo 1 6 1 NJ
preplace netloc axi_interconnect_0_M01_AXI 1 5 1 1670
preplace netloc microblaze_0_axi_intc_interrupt 1 3 1 830
preplace netloc axi_interconnect_0_M06_AXI 1 5 1 1630
preplace netloc mdm_1_debug_sys_rst 1 1 3 230 390 NJ 390 810
preplace netloc axi_interconnect_0_M03_AXI 1 5 1 1680
preplace netloc LxTXPS_GPIO 1 6 1 NJ
levelinfo -pg 1 0 110 390 700 1060 1480 1810 1940 -top 0 -bot 1000
",
}

  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


