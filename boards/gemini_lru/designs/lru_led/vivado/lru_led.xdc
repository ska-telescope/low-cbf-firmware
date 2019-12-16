create_clock -period 8.000 -name clk_e -waveform {0.000 4.000} [get_ports clk_e_p]


set_property BITSTREAM.GENERAL.COMPRESS FALSE [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 5.3 [current_design]

set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN DISABLE [current_design]

set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]

set_property BITSTREAM.CONFIG.PERSIST YES [current_design]

set_property CONFIG_MODE SPIx4 [current_design]





set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]







