
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 8 [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN div-1 [current_design]
#set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design ]
set_property BITSTREAM.config.SPI_opcode 0x6B [current_design ]
set_property CONFIG_MODE SPIx8 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design]
set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]

set_property PACKAGE_PIN AW28 [get_ports iic_mux_reset_b[2]]
set_property IOSTANDARD LVCMOS15 [get_ports iic_mux_reset_b[2]]

set_property PACKAGE_PIN AR18 [get_ports iic_mux_reset_b[1]]
set_property IOSTANDARD LVCMOS18 [get_ports iic_mux_reset_b[1]]

set_property PACKAGE_PIN AW21 [get_ports iic_mux_reset_b[0]]
set_property IOSTANDARD LVCMOS18 [get_ports iic_mux_reset_b[0]]

set_property PACKAGE_PIN AV30 [get_ports hmc_refclk_sel_tri_o[0]]
set_property IOSTANDARD LVCMOS15 [get_ports hmc_refclk_sel_tri_o[0]]

set_property PACKAGE_PIN BB27 [get_ports lxrxps_tri_o[1]]
set_property IOSTANDARD LVCMOS15 [get_ports lxrxps_tri_o[1]]

set_property PACKAGE_PIN AY30 [get_ports lxrxps_tri_o[0]]
set_property IOSTANDARD LVCMOS15 [get_ports lxrxps_tri_o[0]]

set_property PACKAGE_PIN AY29 [get_ports lxtxps_tri_i[1]]
set_property IOSTANDARD LVCMOS15 [get_ports lxtxps_tri_i[1]]

set_property PACKAGE_PIN AW27 [get_ports lxtxps_tri_i[0]]
set_property IOSTANDARD LVCMOS15 [get_ports lxtxps_tri_i[0]]

set_property PACKAGE_PIN BB26 [get_ports refclk_boot_tri_o[1]]
set_property IOSTANDARD LVCMOS15 [get_ports refclk_boot_tri_o[1]]

set_property PACKAGE_PIN BA26 [get_ports refclk_boot_tri_o[0]]
set_property IOSTANDARD LVCMOS15 [get_ports refclk_boot_tri_o[0]]

set_property PACKAGE_PIN AW30 [get_ports ferr_n_tri_i[0]]
set_property IOSTANDARD LVCMOS15 [get_ports ferr_n_tri_i[0]]

