set componentName axi_quadspi_prom_dual
create_ip -name axi_quad_spi -vendor xilinx.com -library ip -module_name $componentName
set_property -dict [list CONFIG.C_SPI_MEMORY {2} CONFIG.C_USE_STARTUP {1} CONFIG.C_USE_STARTUP_INT {1} CONFIG.C_SPI_MODE {2} CONFIG.C_DUAL_QUAD_MODE {1} CONFIG.C_NUM_SS_BITS {2} CONFIG.C_SCK_RATIO {2} CONFIG.C_FIFO_DEPTH {256} CONFIG.C_TYPE_OF_AXI4_INTERFACE {1} CONFIG.Async_Clk {1} CONFIG.C_S_AXI4_ID_WIDTH {0}] [get_ips $componentName]
source $env(RADIOHDL)/libraries/technology/build_ip.tcl