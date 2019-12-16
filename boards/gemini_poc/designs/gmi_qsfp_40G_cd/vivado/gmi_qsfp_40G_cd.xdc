create_clock -period 8.000 -name clk_e -waveform {0.000 4.000} [get_ports clk_e_p]

create_clock -period 6.206 [get_ports qsfp_c_clk_p]
create_clock -period 6.206 [get_ports qsfp_d_clk_p]


### Any other Constraints  
###set_power_opt -exclude_cells [get_cells -hierarchical -filter {NAME =~ */*HSEC_CORES*/i_RX_TOP/i_RX_CORE/i_RX_LANE*/i_BUFF_*/i_RAM/i_RAM_* }]

####set_power_opt -exclude_cells [get_cells {DUT/inst/i_my_ip_top_0/i_my_ip_HSEC_CORES/i_RX_TOP/i_RX_CORE/i_RX_LANE0/i_BUFF_1/i_RAM/i_RAM_0}]


set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -datapath_only 3.20
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -datapath_only 3.20
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -to [get_clocks -of_objects [get_pins i_CLK_GEN_*/inst/mmcme3_adv_inst/CLKOUT0]] -datapath_only 10
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -to [get_clocks -of_objects [get_pins i_CLK_GEN_*/inst/mmcme3_adv_inst/CLKOUT0]] -datapath_only 10
set_max_delay -from [get_clocks -of_objects [get_pins i_CLK_GEN_*/inst/mmcme3_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -datapath_only 10
set_max_delay -from [get_clocks -of_objects [get_pins i_CLK_GEN_*/inst/mmcme3_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -datapath_only 10


set_max_delay -from [get_clocks dclk] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -datapath_only 8.000
set_max_delay -from [get_clocks dclk] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -datapath_only 8.000
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -to [get_clocks dclk]  -datapath_only 8.000
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -to [get_clocks dclk]  -datapath_only 8.000




set_property BITSTREAM.GENERAL.COMPRESS FALSE [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 5.3 [current_design]

set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN DISABLE [current_design]

set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [current_design]

set_property BITSTREAM.CONFIG.PERSIST YES [current_design]

set_property CONFIG_MODE SPIx1 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 1 [current_design]

