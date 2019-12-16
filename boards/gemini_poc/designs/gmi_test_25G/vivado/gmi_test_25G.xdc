
#create_clock ... clk_b ... no need to define this clock, already defined in hmc_free_clk_mmcm_0.xdc
#create_clock ... clk_e ... no need to define this clock, already defined in ptp_clk125_mmcm.xdc
#create_clock ... clk_mmbx ... no need to define this clock, already defined in mmbx_clk64_mmcm.xdc
create_clock -period 50.000 -name clk_f -waveform {0.000 25.000} [get_ports clk_f]
create_clock -period 15.625 -name clk_sfp -waveform {0.000 7.8125} [get_ports clk_sfp_p]

create_clock -period 6.206 -name qsfp_a_clk -waveform {0.000 3.103} [get_ports qsfp_a_clk_p]
create_clock -period 6.206 -name qsfp_b_clk -waveform {0.000 3.103} [get_ports qsfp_b_clk_p]
create_clock -period 6.206 -name qsfp_c_clk -waveform {0.000 3.103} [get_ports qsfp_c_clk_p]
create_clock -period 6.206 -name qsfp_d_clk -waveform {0.000 3.103} [get_ports qsfp_d_clk_p]

#create_clock -period 6.206 -name mbo_a_clk[0] -waveform {0.000 3.103} [get_ports mbo_a_clk[0]]
#create_clock -period 6.206 -name mbo_a_clk[1] -waveform {0.000 3.103} [get_ports mbo_a_clk[1]]
#create_clock -period 6.206 -name mbo_a_clk[2] -waveform {0.000 3.103} [get_ports mbo_a_clk[2]]

#create_clock -period 6.206 -name mbo_b_clk[0] -waveform {0.000 3.103} [get_ports mbo_b_clk[0]]
#create_clock -period 6.206 -name mbo_b_clk[1] -waveform {0.000 3.103} [get_ports mbo_b_clk[1]]
#create_clock -period 6.206 -name mbo_b_clk[2] -waveform {0.000 3.103} [get_ports mbo_b_clk[2]]

#create_clock -period 6.206 -name mbo_c_clk[0] -waveform {0.000 3.103} [get_ports mbo_c_clk[0]]
#create_clock -period 6.206 -name mbo_c_clk[1] -waveform {0.000 3.103} [get_ports mbo_c_clk[1]]
#create_clock -period 6.206 -name mbo_c_clk[2] -waveform {0.000 3.103} [get_ports mbo_c_clk[2]]

#------------------------------------------------------------------------------
# XXV_ETHERNET example design-level XDC file
# ----------------------------------------------------------------------------------------------------------------------
## init_clk should be lesser or equal to reference clock.

#create_clock -period 10.000 [get_ports dclk]
#create_clock -period 6.400 [get_ports gt_refclk_p]

create_generated_clock -name dclk [get_pins u_hmc_free_clk_mmcm_0/inst/mmcme3_adv_inst/CLKOUT6]

### Any other Constraints  

set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -datapath_only 2.560
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -datapath_only 2.560
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -to [get_clocks dclk] -datapath_only 2.560
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -to [get_clocks dclk] -datapath_only 2.560
set_max_delay -from [get_clocks dclk] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -datapath_only 10
set_max_delay -from [get_clocks dclk] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -datapath_only 10






