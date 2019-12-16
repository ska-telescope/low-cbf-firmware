
####################################################################################
# Clocks
####################################################################################


create_clock -period 6.400 [get_ports sfp_clk_c_p]

create_clock -period 6.206 [get_ports {mbo_a_clk_p[0]}]
create_clock -period 6.206 [get_ports {mbo_a_clk_p[1]}]
create_clock -period 6.206 [get_ports {mbo_a_clk_p[2]}]

create_clock -period 6.206 [get_ports {mbo_b_clk_p[0]}]
create_clock -period 6.206 [get_ports {mbo_b_clk_p[1]}]
create_clock -period 6.206 [get_ports {mbo_b_clk_p[2]}]

create_clock -period 6.206 [get_ports {mbo_c_clk_p[0]}]
create_clock -period 6.206 [get_ports {mbo_c_clk_p[1]}]
create_clock -period 6.206 [get_ports {mbo_c_clk_p[2]}]

create_clock -period 6.206 [get_ports qsfp_a_clk_p]
create_clock -period 6.206 [get_ports qsfp_b_clk_p]
create_clock -period 6.206 [get_ports qsfp_c_clk_p]
create_clock -period 6.206 [get_ports qsfp_d_clk_p]

create_clock -period 6.400 [get_ports {clk_c_p[0]}]
create_clock -period 6.400 [get_ports {clk_c_p[1]}]
create_clock -period 6.400 [get_ports {clk_c_p[2]}]
create_clock -period 6.400 [get_ports {clk_c_p[3]}]
create_clock -period 6.400 [get_ports {clk_c_p[4]}]

create_clock -period 50.000 [get_ports clk_f]

create_clock -period 3.750 [get_ports clk_g_p]

create_clock -period 50.000 [get_ports clk_h]

####################################################################################
# Fixed Configuration Constraints
####################################################################################

set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]
set_property CONFIG_MODE SPIx8 [current_design]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 10.6 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 8 [current_design]

set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]

set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]

set_property INTERNAL_VREF 0.84 [get_iobanks 61]
set_property INTERNAL_VREF 0.84 [get_iobanks 62]
set_property INTERNAL_VREF 0.84 [get_iobanks 63]


####################################################################################
# Pin Constraints
####################################################################################

##########################
# Clocks


set_property PACKAGE_PIN M13 [get_ports {clk_c_p[0]}]
set_property PACKAGE_PIN M12 [get_ports {clk_c_n[0]}]

set_property PACKAGE_PIN AL11 [get_ports {clk_c_p[1]}]
set_property PACKAGE_PIN AL10 [get_ports {clk_c_n[1]}]

set_property PACKAGE_PIN AW11 [get_ports {clk_c_p[2]}]
set_property PACKAGE_PIN AW10 [get_ports {clk_c_n[2]}]

set_property PACKAGE_PIN AU41 [get_ports {clk_c_p[3]}]
set_property PACKAGE_PIN AU42 [get_ports {clk_c_n[3]}]

set_property PACKAGE_PIN AL41 [get_ports {clk_c_p[4]}]
set_property PACKAGE_PIN AL42 [get_ports {clk_c_n[4]}]

set_property -dict {PACKAGE_PIN P13 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {clk_d_p[0]}]
set_property -dict {PACKAGE_PIN P12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {clk_d_n[0]}]

set_property -dict {PACKAGE_PIN AN11 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {clk_d_p[1]}]
set_property -dict {PACKAGE_PIN AN10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {clk_d_n[1]}]

set_property -dict {PACKAGE_PIN BA11 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {clk_d_p[2]}]
set_property -dict {PACKAGE_PIN BA10 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {clk_d_n[2]}]

set_property -dict {PACKAGE_PIN A29 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports clk_e_n]
set_property -dict {PACKAGE_PIN A28 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports clk_e_p]

set_property -dict {PACKAGE_PIN C29 IOSTANDARD LVCMOS18} [get_ports clk_f]

set_property -dict {PACKAGE_PIN BD29 IOSTANDARD DIFF_SSTL12} [get_ports clk_g_n]
set_property -dict {PACKAGE_PIN BC28 IOSTANDARD DIFF_SSTL12} [get_ports clk_g_p]

set_property -dict {PACKAGE_PIN N33 IOSTANDARD LVCMOS18} [get_ports clk_h]


set_property PACKAGE_PIN R17 [get_ports clk_aux_b_n]
set_property PACKAGE_PIN R18 [get_ports clk_aux_b_p]

set_property PACKAGE_PIN P19 [get_ports clk_aux_c]

set_property PACKAGE_PIN K22 [get_ports clk_bp_n]
set_property PACKAGE_PIN K23 [get_ports clk_bp_p]

##########################
# MBOs
set_property PACKAGE_PIN L10 [get_ports {mbo_a_clk_n[0]}]
set_property PACKAGE_PIN L11 [get_ports {mbo_a_clk_p[0]}]
set_property PACKAGE_PIN N10 [get_ports {mbo_a_clk_n[1]}]
set_property PACKAGE_PIN N11 [get_ports {mbo_a_clk_p[1]}]
set_property PACKAGE_PIN R10 [get_ports {mbo_a_clk_n[2]}]
set_property PACKAGE_PIN R11 [get_ports {mbo_a_clk_p[2]}]

set_property PACKAGE_PIN AJ10 [get_ports {mbo_b_clk_n[0]}]
set_property PACKAGE_PIN AM12 [get_ports {mbo_b_clk_n[1]}]
set_property PACKAGE_PIN AP12 [get_ports {mbo_b_clk_n[2]}]
set_property PACKAGE_PIN AJ11 [get_ports {mbo_b_clk_p[0]}]
set_property PACKAGE_PIN AM13 [get_ports {mbo_b_clk_p[1]}]
set_property PACKAGE_PIN AP13 [get_ports {mbo_b_clk_p[2]}]

set_property PACKAGE_PIN AV12 [get_ports {mbo_c_clk_n[0]}]
set_property PACKAGE_PIN AV13 [get_ports {mbo_c_clk_p[0]}]
set_property PACKAGE_PIN AY13 [get_ports {mbo_c_clk_p[1]}]
set_property PACKAGE_PIN AY12 [get_ports {mbo_c_clk_n[1]}]
set_property PACKAGE_PIN BB13 [get_ports {mbo_c_clk_p[2]}]
set_property PACKAGE_PIN BB12 [get_ports {mbo_c_clk_n[2]}]


set_property PACKAGE_PIN E2 [get_ports {mbo_a_rx_p[0]}]
set_property PACKAGE_PIN E1 [get_ports {mbo_a_rx_n[0]}]
set_property PACKAGE_PIN D9 [get_ports {mbo_a_tx_p[0]}]
set_property PACKAGE_PIN D8 [get_ports {mbo_a_tx_n[0]}]
set_property PACKAGE_PIN D4 [get_ports {mbo_a_rx_p[7]}]
set_property PACKAGE_PIN D3 [get_ports {mbo_a_rx_n[7]}]
set_property PACKAGE_PIN B8 [get_ports {mbo_a_tx_n[1]}]
set_property PACKAGE_PIN B9 [get_ports {mbo_a_tx_p[1]}]
set_property PACKAGE_PIN G7 [get_ports {mbo_a_tx_p[2]}]
set_property PACKAGE_PIN G6 [get_ports {mbo_a_tx_n[2]}]
set_property PACKAGE_PIN G2 [get_ports {mbo_a_rx_p[1]}]
set_property PACKAGE_PIN G1 [get_ports {mbo_a_rx_n[1]}]
set_property PACKAGE_PIN C5 [get_ports {mbo_a_rx_n[9]}]
set_property PACKAGE_PIN C6 [get_ports {mbo_a_rx_p[9]}]
set_property PACKAGE_PIN E10 [get_ports {mbo_a_tx_n[3]}]
set_property PACKAGE_PIN E11 [get_ports {mbo_a_tx_p[3]}]
set_property PACKAGE_PIN H4 [get_ports {mbo_a_rx_p[3]}]
set_property PACKAGE_PIN H3 [get_ports {mbo_a_rx_n[3]}]
set_property PACKAGE_PIN H9 [get_ports {mbo_a_tx_p[4]}]
set_property PACKAGE_PIN H8 [get_ports {mbo_a_tx_n[4]}]
set_property PACKAGE_PIN C10 [get_ports {mbo_a_tx_n[5]}]
set_property PACKAGE_PIN E6 [get_ports {mbo_a_rx_p[11]}]
set_property PACKAGE_PIN E5 [get_ports {mbo_a_rx_n[11]}]
set_property PACKAGE_PIN C11 [get_ports {mbo_a_tx_p[5]}]
set_property PACKAGE_PIN F9 [get_ports {mbo_a_tx_p[6]}]
set_property PACKAGE_PIN F8 [get_ports {mbo_a_tx_n[6]}]
set_property PACKAGE_PIN F4 [get_ports {mbo_a_rx_p[2]}]
set_property PACKAGE_PIN F3 [get_ports {mbo_a_rx_n[2]}]
set_property PACKAGE_PIN A10 [get_ports {mbo_a_tx_n[7]}]
set_property PACKAGE_PIN A6 [get_ports {mbo_a_rx_p[10]}]
set_property PACKAGE_PIN A5 [get_ports {mbo_a_rx_n[10]}]
set_property PACKAGE_PIN A11 [get_ports {mbo_a_tx_p[7]}]
set_property PACKAGE_PIN J7 [get_ports {mbo_a_tx_p[8]}]
set_property PACKAGE_PIN J6 [get_ports {mbo_a_tx_n[8]}]
set_property PACKAGE_PIN J2 [get_ports {mbo_a_rx_p[5]}]
set_property PACKAGE_PIN J1 [get_ports {mbo_a_rx_n[5]}]
set_property PACKAGE_PIN B12 [get_ports {mbo_a_tx_n[9]}]
set_property PACKAGE_PIN A20 [get_ports {mbo_a_rx_p[8]}]
set_property PACKAGE_PIN A19 [get_ports {mbo_a_rx_n[8]}]
set_property PACKAGE_PIN B13 [get_ports {mbo_a_tx_p[9]}]
set_property PACKAGE_PIN A15 [get_ports {mbo_a_tx_p[10]}]
set_property PACKAGE_PIN B18 [get_ports {mbo_a_rx_p[6]}]
set_property PACKAGE_PIN B17 [get_ports {mbo_a_rx_n[6]}]
set_property PACKAGE_PIN A14 [get_ports {mbo_a_tx_n[10]}]
set_property PACKAGE_PIN C15 [get_ports {mbo_a_tx_p[11]}]
set_property PACKAGE_PIN C20 [get_ports {mbo_a_rx_p[4]}]
set_property PACKAGE_PIN C19 [get_ports {mbo_a_rx_n[4]}]
set_property PACKAGE_PIN C14 [get_ports {mbo_a_tx_n[11]}]
set_property PACKAGE_PIN AH9 [get_ports {mbo_b_tx_p[0]}]
set_property PACKAGE_PIN AH4 [get_ports {mbo_b_rx_p[9]}]
set_property PACKAGE_PIN AH3 [get_ports {mbo_b_rx_n[9]}]
set_property PACKAGE_PIN AH8 [get_ports {mbo_b_tx_n[0]}]
set_property PACKAGE_PIN AF9 [get_ports {mbo_b_tx_p[1]}]
set_property PACKAGE_PIN AF8 [get_ports {mbo_b_tx_n[1]}]
set_property PACKAGE_PIN AF4 [get_ports {mbo_b_rx_p[10]}]
set_property PACKAGE_PIN AF3 [get_ports {mbo_b_rx_n[10]}]
set_property PACKAGE_PIN AG2 [get_ports {mbo_b_rx_p[8]}]
set_property PACKAGE_PIN AG1 [get_ports {mbo_b_rx_n[8]}]
set_property PACKAGE_PIN AG7 [get_ports {mbo_b_tx_p[2]}]
set_property PACKAGE_PIN AG6 [get_ports {mbo_b_tx_n[2]}]
set_property PACKAGE_PIN AM8 [get_ports {mbo_b_tx_n[3]}]
set_property PACKAGE_PIN AM4 [get_ports {mbo_b_rx_p[11]}]
set_property PACKAGE_PIN AM3 [get_ports {mbo_b_rx_n[11]}]
set_property PACKAGE_PIN AM9 [get_ports {mbo_b_tx_p[3]}]
set_property PACKAGE_PIN AP9 [get_ports {mbo_b_tx_p[4]}]
set_property PACKAGE_PIN AP4 [get_ports {mbo_b_rx_p[4]}]
set_property PACKAGE_PIN AP3 [get_ports {mbo_b_rx_n[4]}]
set_property PACKAGE_PIN AP8 [get_ports {mbo_b_tx_n[4]}]
set_property PACKAGE_PIN AL6 [get_ports {mbo_b_tx_n[5]}]
set_property PACKAGE_PIN AL2 [get_ports {mbo_b_rx_p[2]}]
set_property PACKAGE_PIN AL1 [get_ports {mbo_b_rx_n[2]}]
set_property PACKAGE_PIN AL7 [get_ports {mbo_b_tx_p[5]}]
set_property PACKAGE_PIN AR7 [get_ports {mbo_b_tx_p[6]}]
set_property PACKAGE_PIN AR2 [get_ports {mbo_b_rx_p[1]}]
set_property PACKAGE_PIN AR1 [get_ports {mbo_b_rx_n[1]}]
set_property PACKAGE_PIN AR6 [get_ports {mbo_b_tx_n[6]}]
set_property PACKAGE_PIN AN2 [get_ports {mbo_b_rx_p[0]}]
set_property PACKAGE_PIN AN1 [get_ports {mbo_b_rx_n[0]}]
set_property PACKAGE_PIN AN6 [get_ports {mbo_b_tx_n[7]}]
set_property PACKAGE_PIN AN7 [get_ports {mbo_b_tx_p[7]}]
set_property PACKAGE_PIN AT8 [get_ports {mbo_b_tx_n[8]}]
set_property PACKAGE_PIN AT9 [get_ports {mbo_b_tx_p[8]}]
set_property PACKAGE_PIN AT4 [get_ports {mbo_b_rx_p[3]}]
set_property PACKAGE_PIN AT3 [get_ports {mbo_b_rx_n[3]}]
set_property PACKAGE_PIN AK8 [get_ports {mbo_b_tx_n[9]}]
set_property PACKAGE_PIN AK4 [get_ports {mbo_b_rx_p[7]}]
set_property PACKAGE_PIN AK3 [get_ports {mbo_b_rx_n[7]}]
set_property PACKAGE_PIN AK9 [get_ports {mbo_b_tx_p[9]}]
set_property PACKAGE_PIN AJ2 [get_ports {mbo_b_rx_p[6]}]
set_property PACKAGE_PIN AJ1 [get_ports {mbo_b_rx_n[6]}]
set_property PACKAGE_PIN AJ7 [get_ports {mbo_b_tx_p[10]}]
set_property PACKAGE_PIN AJ6 [get_ports {mbo_b_tx_n[10]}]
set_property PACKAGE_PIN AU2 [get_ports {mbo_b_rx_p[5]}]
set_property PACKAGE_PIN AU1 [get_ports {mbo_b_rx_n[5]}]
set_property PACKAGE_PIN AU6 [get_ports {mbo_b_tx_n[11]}]
set_property PACKAGE_PIN AU7 [get_ports {mbo_b_tx_p[11]}]
set_property PACKAGE_PIN BD9 [get_ports {mbo_c_tx_p[0]}]
set_property PACKAGE_PIN BD8 [get_ports {mbo_c_tx_n[0]}]
set_property PACKAGE_PIN BD4 [get_ports {mbo_c_rx_p[7]}]
set_property PACKAGE_PIN BD3 [get_ports {mbo_c_rx_n[7]}]
set_property PACKAGE_PIN BB9 [get_ports {mbo_c_tx_p[1]}]
set_property PACKAGE_PIN BB8 [get_ports {mbo_c_tx_n[1]}]
set_property PACKAGE_PIN BB4 [get_ports {mbo_c_rx_p[10]}]
set_property PACKAGE_PIN BB3 [get_ports {mbo_c_rx_n[10]}]
set_property PACKAGE_PIN BC2 [get_ports {mbo_c_rx_p[6]}]
set_property PACKAGE_PIN BC1 [get_ports {mbo_c_rx_n[6]}]
set_property PACKAGE_PIN BC7 [get_ports {mbo_c_tx_p[2]}]
set_property PACKAGE_PIN BC6 [get_ports {mbo_c_tx_n[2]}]
set_property PACKAGE_PIN BH4 [get_ports {mbo_c_rx_p[1]}]
set_property PACKAGE_PIN BH3 [get_ports {mbo_c_rx_n[1]}]
set_property PACKAGE_PIN BG11 [get_ports {mbo_c_tx_p[3]}]
set_property PACKAGE_PIN BG10 [get_ports {mbo_c_tx_n[3]}]
set_property PACKAGE_PIN BJ11 [get_ports {mbo_c_tx_p[4]}]
set_property PACKAGE_PIN BJ10 [get_ports {mbo_c_tx_n[4]}]
set_property PACKAGE_PIN BG2 [get_ports {mbo_c_rx_p[2]}]
set_property PACKAGE_PIN BG1 [get_ports {mbo_c_rx_n[2]}]
set_property PACKAGE_PIN BF4 [get_ports {mbo_c_rx_p[0]}]
set_property PACKAGE_PIN BF3 [get_ports {mbo_c_rx_n[0]}]
set_property PACKAGE_PIN BF8 [get_ports {mbo_c_tx_n[5]}]
set_property PACKAGE_PIN BF9 [get_ports {mbo_c_tx_p[5]}]
set_property PACKAGE_PIN BJ6 [get_ports {mbo_c_rx_p[3]}]
set_property PACKAGE_PIN BJ5 [get_ports {mbo_c_rx_n[3]}]
set_property PACKAGE_PIN BK9 [get_ports {mbo_c_tx_p[6]}]
set_property PACKAGE_PIN BK8 [get_ports {mbo_c_tx_n[6]}]
set_property PACKAGE_PIN BG6 [get_ports {mbo_c_rx_p[9]}]
set_property PACKAGE_PIN BG5 [get_ports {mbo_c_rx_n[9]}]
set_property PACKAGE_PIN BH9 [get_ports {mbo_c_tx_p[7]}]
set_property PACKAGE_PIN BH8 [get_ports {mbo_c_tx_n[7]}]
set_property PACKAGE_PIN BK12 [get_ports {mbo_c_tx_n[8]}]
set_property PACKAGE_PIN BL20 [get_ports {mbo_c_rx_p[8]}]
set_property PACKAGE_PIN BL19 [get_ports {mbo_c_rx_n[8]}]
set_property PACKAGE_PIN BK13 [get_ports {mbo_c_tx_p[8]}]
set_property PACKAGE_PIN BL10 [get_ports {mbo_c_tx_n[9]}]
set_property PACKAGE_PIN BL6 [get_ports {mbo_c_rx_p[11]}]
set_property PACKAGE_PIN BL5 [get_ports {mbo_c_rx_n[11]}]
set_property PACKAGE_PIN BL11 [get_ports {mbo_c_tx_p[9]}]
set_property PACKAGE_PIN BE2 [get_ports {mbo_c_rx_p[4]}]
set_property PACKAGE_PIN BE1 [get_ports {mbo_c_rx_n[4]}]
set_property PACKAGE_PIN BE7 [get_ports {mbo_c_tx_p[10]}]
set_property PACKAGE_PIN BE6 [get_ports {mbo_c_tx_n[10]}]
set_property PACKAGE_PIN BL14 [get_ports {mbo_c_tx_n[11]}]
set_property PACKAGE_PIN BK18 [get_ports {mbo_c_rx_p[5]}]
set_property PACKAGE_PIN BK17 [get_ports {mbo_c_rx_n[5]}]
set_property PACKAGE_PIN BL15 [get_ports {mbo_c_tx_p[11]}]


set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 IOB TRUE} [get_ports mbo_a_reset]
set_property -dict {PACKAGE_PIN V19 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 IOB TRUE} [get_ports mbo_b_reset]
set_property -dict {PACKAGE_PIN T19 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 IOB TRUE} [get_ports mbo_c_reset]

set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 IOB TRUE} [get_ports mbo_scl]
set_property -dict {PACKAGE_PIN V18 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 IOB TRUE} [get_ports mbo_sda]
set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS18 IOB TRUE PULLUP true} [get_ports mbo_int_n]

##########################
# QSFPs
set_property PACKAGE_PIN AJ42 [get_ports qsfp_a_clk_n]
set_property PACKAGE_PIN AJ41 [get_ports qsfp_a_clk_p]

set_property PACKAGE_PIN AM40 [get_ports qsfp_b_clk_n]
set_property PACKAGE_PIN AM39 [get_ports qsfp_b_clk_p]

set_property PACKAGE_PIN AP40 [get_ports qsfp_c_clk_n]
set_property PACKAGE_PIN AP39 [get_ports qsfp_c_clk_p]

set_property PACKAGE_PIN AV40 [get_ports qsfp_d_clk_n]
set_property PACKAGE_PIN AV39 [get_ports qsfp_d_clk_p]

set_property PACKAGE_PIN AF49 [get_ports {qsfp_a_rx_n[0]}]
set_property PACKAGE_PIN AG51 [get_ports {qsfp_a_rx_n[1]}]
set_property PACKAGE_PIN AH49 [get_ports {qsfp_a_rx_n[2]}]
set_property PACKAGE_PIN AJ51 [get_ports {qsfp_a_rx_n[3]}]
set_property PACKAGE_PIN AF48 [get_ports {qsfp_a_rx_p[0]}]
set_property PACKAGE_PIN AG50 [get_ports {qsfp_a_rx_p[1]}]
set_property PACKAGE_PIN AH48 [get_ports {qsfp_a_rx_p[2]}]
set_property PACKAGE_PIN AJ50 [get_ports {qsfp_a_rx_p[3]}]
set_property PACKAGE_PIN AH44 [get_ports {qsfp_a_tx_n[0]}]
set_property PACKAGE_PIN AJ46 [get_ports {qsfp_a_tx_n[1]}]
set_property PACKAGE_PIN AG46 [get_ports {qsfp_a_tx_n[2]}]
set_property PACKAGE_PIN AF44 [get_ports {qsfp_a_tx_n[3]}]
set_property PACKAGE_PIN AH43 [get_ports {qsfp_a_tx_p[0]}]
set_property PACKAGE_PIN AJ45 [get_ports {qsfp_a_tx_p[1]}]
set_property PACKAGE_PIN AG45 [get_ports {qsfp_a_tx_p[2]}]
set_property PACKAGE_PIN AF43 [get_ports {qsfp_a_tx_p[3]}]

set_property PACKAGE_PIN AM48 [get_ports {qsfp_b_rx_p[2]}]
set_property PACKAGE_PIN AM49 [get_ports {qsfp_b_rx_n[2]}]
set_property PACKAGE_PIN AM43 [get_ports {qsfp_b_tx_p[0]}]
set_property PACKAGE_PIN AM44 [get_ports {qsfp_b_tx_n[0]}]
set_property PACKAGE_PIN AN50 [get_ports {qsfp_b_rx_p[3]}]
set_property PACKAGE_PIN AN45 [get_ports {qsfp_b_tx_p[1]}]
set_property PACKAGE_PIN AN46 [get_ports {qsfp_b_tx_n[1]}]
set_property PACKAGE_PIN AN51 [get_ports {qsfp_b_rx_n[3]}]
set_property PACKAGE_PIN AL50 [get_ports {qsfp_b_rx_p[1]}]
set_property PACKAGE_PIN AL51 [get_ports {qsfp_b_rx_n[1]}]
set_property PACKAGE_PIN AL45 [get_ports {qsfp_b_tx_p[2]}]
set_property PACKAGE_PIN AL46 [get_ports {qsfp_b_tx_n[2]}]
set_property PACKAGE_PIN AK44 [get_ports {qsfp_b_tx_n[3]}]
set_property PACKAGE_PIN AK48 [get_ports {qsfp_b_rx_p[0]}]
set_property PACKAGE_PIN AK49 [get_ports {qsfp_b_rx_n[0]}]
set_property PACKAGE_PIN AK43 [get_ports {qsfp_b_tx_p[3]}]

set_property PACKAGE_PIN AT48 [get_ports {qsfp_c_rx_p[2]}]
set_property PACKAGE_PIN AT49 [get_ports {qsfp_c_rx_n[2]}]
set_property PACKAGE_PIN AT43 [get_ports {qsfp_c_tx_p[0]}]
set_property PACKAGE_PIN AT44 [get_ports {qsfp_c_tx_n[0]}]
set_property PACKAGE_PIN AU50 [get_ports {qsfp_c_rx_p[3]}]
set_property PACKAGE_PIN AU45 [get_ports {qsfp_c_tx_p[1]}]
set_property PACKAGE_PIN AU46 [get_ports {qsfp_c_tx_n[1]}]
set_property PACKAGE_PIN AU51 [get_ports {qsfp_c_rx_n[3]}]
set_property PACKAGE_PIN AR50 [get_ports {qsfp_c_rx_p[1]}]
set_property PACKAGE_PIN AR51 [get_ports {qsfp_c_rx_n[1]}]
set_property PACKAGE_PIN AR45 [get_ports {qsfp_c_tx_p[2]}]
set_property PACKAGE_PIN AR46 [get_ports {qsfp_c_tx_n[2]}]
set_property PACKAGE_PIN AP44 [get_ports {qsfp_c_tx_n[3]}]
set_property PACKAGE_PIN AP48 [get_ports {qsfp_c_rx_p[0]}]
set_property PACKAGE_PIN AP49 [get_ports {qsfp_c_rx_n[0]}]
set_property PACKAGE_PIN AP43 [get_ports {qsfp_c_tx_p[3]}]

set_property PACKAGE_PIN BD48 [get_ports {qsfp_d_rx_p[2]}]
set_property PACKAGE_PIN BD49 [get_ports {qsfp_d_rx_n[2]}]
set_property PACKAGE_PIN BD43 [get_ports {qsfp_d_tx_p[0]}]
set_property PACKAGE_PIN BD44 [get_ports {qsfp_d_tx_n[0]}]
set_property PACKAGE_PIN BE50 [get_ports {qsfp_d_rx_p[3]}]
set_property PACKAGE_PIN BE45 [get_ports {qsfp_d_tx_p[1]}]
set_property PACKAGE_PIN BE46 [get_ports {qsfp_d_tx_n[1]}]
set_property PACKAGE_PIN BE51 [get_ports {qsfp_d_rx_n[3]}]
set_property PACKAGE_PIN BC50 [get_ports {qsfp_d_rx_p[1]}]
set_property PACKAGE_PIN BC51 [get_ports {qsfp_d_rx_n[1]}]
set_property PACKAGE_PIN BC45 [get_ports {qsfp_d_tx_p[2]}]
set_property PACKAGE_PIN BC46 [get_ports {qsfp_d_tx_n[2]}]
set_property PACKAGE_PIN BB44 [get_ports {qsfp_d_tx_n[3]}]
set_property PACKAGE_PIN BB48 [get_ports {qsfp_d_rx_p[0]}]
set_property PACKAGE_PIN BB49 [get_ports {qsfp_d_rx_n[0]}]
set_property PACKAGE_PIN BB43 [get_ports {qsfp_d_tx_p[3]}]

set_property -dict {PACKAGE_PIN K33 IOSTANDARD LVCMOS18 PULLUP true} [get_ports qsfp_a_mod_prs_n]
set_property -dict {PACKAGE_PIN L37 IOSTANDARD LVCMOS18 PULLUP true} [get_ports qsfp_b_mod_prs_n]
set_property -dict {PACKAGE_PIN P36 IOSTANDARD LVCMOS18 PULLUP true} [get_ports qsfp_c_mod_prs_n]
set_property -dict {PACKAGE_PIN U37 IOSTANDARD LVCMOS18 PULLUP true} [get_ports qsfp_d_mod_prs_n]

set_property -dict {PACKAGE_PIN M34 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_a_reset]
set_property -dict {PACKAGE_PIN K37 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_b_reset]
set_property -dict {PACKAGE_PIN N37 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_c_reset]
set_property -dict {PACKAGE_PIN T37 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_d_reset]

set_property -dict {PACKAGE_PIN J33 IOSTANDARD LVCMOS18 IOB TRUE} [get_ports qsfp_int_n]

set_property -dict {PACKAGE_PIN K36 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_scl]
set_property -dict {PACKAGE_PIN M35 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_sda]

set_property -dict {PACKAGE_PIN L34 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_a_led]
set_property -dict {PACKAGE_PIN J36 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_b_led]
set_property -dict {PACKAGE_PIN M36 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_c_led]
set_property -dict {PACKAGE_PIN R37 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_d_led]

set_property -dict {PACKAGE_PIN K35 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_a_mod_sel]
set_property -dict {PACKAGE_PIN L35 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_b_mod_sel]
set_property -dict {PACKAGE_PIN M37 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_c_mod_sel]
set_property -dict {PACKAGE_PIN U36 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_d_mod_sel]

##########################
# SFP

set_property PACKAGE_PIN BA41 [get_ports sfp_clk_c_p]
set_property PACKAGE_PIN BA42 [get_ports sfp_clk_c_n]

set_property PACKAGE_PIN BB40 [get_ports sfp_clk_e_n]
set_property PACKAGE_PIN BB39 [get_ports sfp_clk_e_p]


set_property PACKAGE_PIN BJ47 [get_ports sfp_rx_n]
set_property PACKAGE_PIN BK44 [get_ports sfp_tx_n]
set_property PACKAGE_PIN BK43 [get_ports sfp_tx_p]
set_property PACKAGE_PIN BJ46 [get_ports sfp_rx_p]

set_property -dict {PACKAGE_PIN E30 IOSTANDARD LVCMOS18 PULLUP true} [get_ports sfp_fault]
set_property -dict {PACKAGE_PIN G30 IOSTANDARD LVCMOS18 PULLUP true} [get_ports sfp_mod_abs]
set_property -dict {PACKAGE_PIN D30 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports sfp_tx_enable]

set_property -dict {PACKAGE_PIN D29 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports sfp_scl]
set_property -dict {PACKAGE_PIN G29 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports sfp_sda]

set_property -dict {PACKAGE_PIN H30 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports sfp_led]

##########################
# Leds
set_property -dict {PACKAGE_PIN A27 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports led_cs]
set_property -dict {PACKAGE_PIN F30 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports led_din]
set_property -dict {PACKAGE_PIN D28 IOSTANDARD LVCMOS18 IOB TRUE} [get_ports led_dout]
set_property -dict {PACKAGE_PIN B27 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports led_sclk]

##########################
# Debug IO
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports {debug[0]}]
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports {debug[1]}]
set_property -dict {PACKAGE_PIN L15 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports {debug[2]}]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports {debug[3]}]

##########################
# Power Interface
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 IOB TRUE PULLUP true} [get_ports power_sda]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 IOB TRUE PULLUP true} [get_ports power_sdc]
set_property -dict {PACKAGE_PIN J28 IOSTANDARD LVCMOS18} [get_ports power_alert_n]

set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports shutdown]

##########################
# Onewire Onboard
set_property -dict {PACKAGE_PIN J35 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 IOB TRUE} [get_ports serial_id]
set_property -dict {PACKAGE_PIN J34 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2} [get_ports serial_id_pullup]

##########################
# Other IO
set_property -dict {PACKAGE_PIN U20 IOSTANDARD LVCMOS18} [get_ports {version[0]}]
set_property -dict {PACKAGE_PIN T20 IOSTANDARD LVCMOS18} [get_ports {version[1]}]

set_property -dict {PACKAGE_PIN BA22 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 2} [get_ports spi_cs[1]]
set_property -dict {PACKAGE_PIN BD18 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 2} [get_ports {spi_d[4]}]
set_property -dict {PACKAGE_PIN BD17 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 2} [get_ports {spi_d[5]}]
set_property -dict {PACKAGE_PIN BB17 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 2} [get_ports {spi_d[6]}]
set_property -dict {PACKAGE_PIN BC17 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 2} [get_ports {spi_d[7]}]

##########################
# Backplane IO
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports bp_id]
set_property -dict {PACKAGE_PIN M21 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports bp_id_pullup]

set_property -dict {PACKAGE_PIN A24 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {bp_aux_io_p[0]}]
set_property -dict {PACKAGE_PIN A23 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {bp_aux_io_n[0]}]
set_property -dict {PACKAGE_PIN C23 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {bp_aux_io_p[1]}]
set_property -dict {PACKAGE_PIN C22 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {bp_aux_io_n[1]}]

set_property -dict {PACKAGE_PIN E22 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 IOB TRUE} [get_ports bp_power_scl]
set_property -dict {PACKAGE_PIN F22 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 IOB TRUE} [get_ports bp_power_sda]

##########################
# PTP
set_property -dict {PACKAGE_PIN H29 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports ptp_clk_sel]

set_property -dict {PACKAGE_PIN J29 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports ptp_pll_reset]
set_property -dict {PACKAGE_PIN B30 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports ptp_din]
set_property -dict {PACKAGE_PIN C30 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports ptp_sclk]
set_property -dict {PACKAGE_PIN J30 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports {ptp_sync_n[0]}]
set_property -dict {PACKAGE_PIN A30 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports {ptp_sync_n[1]}]

##########################
# Humidity Sensor

set_property -dict {PACKAGE_PIN H23 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports hum_sda]
set_property -dict {PACKAGE_PIN J24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports hum_sdc]

##########################
# DDR4

set_property PACKAGE_PIN BE30 [get_ports {ddr4_adr[0]}]
set_property PACKAGE_PIN BK28 [get_ports {ddr4_adr[1]}]
set_property PACKAGE_PIN BB29 [get_ports {ddr4_adr[2]}]
set_property PACKAGE_PIN BF28 [get_ports {ddr4_adr[3]}]
set_property PACKAGE_PIN BF30 [get_ports {ddr4_adr[4]}]
set_property PACKAGE_PIN BL30 [get_ports {ddr4_adr[5]}]
set_property PACKAGE_PIN BL28 [get_ports {ddr4_adr[6]}]
set_property PACKAGE_PIN BG27 [get_ports {ddr4_adr[7]}]
set_property PACKAGE_PIN BH29 [get_ports {ddr4_adr[8]}]
set_property PACKAGE_PIN BK27 [get_ports {ddr4_adr[9]}]
set_property PACKAGE_PIN BC29 [get_ports {ddr4_adr[10]}]
set_property PACKAGE_PIN BL27 [get_ports {ddr4_adr[11]}]
set_property PACKAGE_PIN BG26 [get_ports {ddr4_adr[12]}]
set_property PACKAGE_PIN BG29 [get_ports {ddr4_adr[13]}]
set_property PACKAGE_PIN BJ26 [get_ports ddr4_act_n]
set_property PACKAGE_PIN BJ29 [get_ports {ddr4_ba[0]}]
set_property PACKAGE_PIN BJ28 [get_ports {ddr4_ba[1]}]
set_property PACKAGE_PIN BF27 [get_ports {ddr4_bg[0]}]
set_property PACKAGE_PIN BK26 [get_ports {ddr4_bg[1]}]
set_property PACKAGE_PIN BH28 [get_ports {ddr4_adr[15]}]
set_property PACKAGE_PIN BE26 [get_ports {ddr4_ck_p[0]}]
set_property PACKAGE_PIN BE27 [get_ports {ddr4_ck_n[0]}]
set_property PACKAGE_PIN BE28 [get_ports {ddr4_ck_n[1]}]
set_property PACKAGE_PIN BD28 [get_ports {ddr4_ck_p[1]}]
set_property PACKAGE_PIN BC27 [get_ports {ddr4_cke[0]}]
set_property PACKAGE_PIN BB27 [get_ports {ddr4_cke[1]}]
set_property PACKAGE_PIN BH27 [get_ports {ddr4_cs[0]}]
set_property PACKAGE_PIN BJ30 [get_ports {ddr4_cs[1]}]
set_property -dict {PACKAGE_PIN BA29 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_cs[2]}]
set_property -dict {PACKAGE_PIN AW30 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_cs[3]}]
set_property PACKAGE_PIN AW25 [get_ports {ddr4_dm[0]}]
set_property PACKAGE_PIN BD25 [get_ports {ddr4_dm[1]}]
set_property PACKAGE_PIN BG25 [get_ports {ddr4_dm[2]}]
set_property PACKAGE_PIN BL24 [get_ports {ddr4_dm[3]}]
set_property PACKAGE_PIN BE31 [get_ports {ddr4_dm[4]}]
set_property PACKAGE_PIN BD35 [get_ports {ddr4_dm[5]}]
set_property PACKAGE_PIN AW35 [get_ports {ddr4_dm[6]}]
set_property PACKAGE_PIN AU36 [get_ports {ddr4_dm[7]}]
set_property PACKAGE_PIN BA28 [get_ports {ddr4_dm[8]}]
set_property PACKAGE_PIN AW23 [get_ports {ddr4_dq[0]}]
set_property PACKAGE_PIN AV24 [get_ports {ddr4_dq[1]}]
set_property PACKAGE_PIN BA23 [get_ports {ddr4_dq[2]}]
set_property PACKAGE_PIN AV26 [get_ports {ddr4_dq[3]}]
set_property PACKAGE_PIN AV27 [get_ports {ddr4_dq[4]}]
set_property PACKAGE_PIN AW26 [get_ports {ddr4_dq[5]}]
set_property PACKAGE_PIN AY23 [get_ports {ddr4_dq[6]}]
set_property PACKAGE_PIN AY26 [get_ports {ddr4_dq[7]}]
set_property PACKAGE_PIN BB25 [get_ports {ddr4_dq[8]}]
set_property PACKAGE_PIN BC22 [get_ports {ddr4_dq[9]}]
set_property PACKAGE_PIN BC23 [get_ports {ddr4_dq[10]}]
set_property PACKAGE_PIN BC24 [get_ports {ddr4_dq[11]}]
set_property PACKAGE_PIN BB22 [get_ports {ddr4_dq[12]}]
set_property PACKAGE_PIN BA24 [get_ports {ddr4_dq[13]}]
set_property PACKAGE_PIN BB26 [get_ports {ddr4_dq[14]}]
set_property PACKAGE_PIN BA25 [get_ports {ddr4_dq[15]}]
set_property PACKAGE_PIN BE22 [get_ports {ddr4_dq[16]}]
set_property PACKAGE_PIN BD23 [get_ports {ddr4_dq[17]}]
set_property PACKAGE_PIN BF22 [get_ports {ddr4_dq[18]}]
set_property PACKAGE_PIN BF24 [get_ports {ddr4_dq[19]}]
set_property PACKAGE_PIN BF25 [get_ports {ddr4_dq[20]}]
set_property PACKAGE_PIN BF23 [get_ports {ddr4_dq[21]}]
set_property PACKAGE_PIN BE23 [get_ports {ddr4_dq[22]}]
set_property PACKAGE_PIN BG22 [get_ports {ddr4_dq[23]}]
set_property PACKAGE_PIN BK22 [get_ports {ddr4_dq[24]}]
set_property PACKAGE_PIN BK25 [get_ports {ddr4_dq[25]}]
set_property PACKAGE_PIN BL25 [get_ports {ddr4_dq[26]}]
set_property PACKAGE_PIN BJ25 [get_ports {ddr4_dq[27]}]
set_property PACKAGE_PIN BH24 [get_ports {ddr4_dq[28]}]
set_property PACKAGE_PIN BL22 [get_ports {ddr4_dq[29]}]
set_property PACKAGE_PIN BJ24 [get_ports {ddr4_dq[30]}]
set_property PACKAGE_PIN BH23 [get_ports {ddr4_dq[31]}]
set_property PACKAGE_PIN BC32 [get_ports {ddr4_dq[32]}]
set_property PACKAGE_PIN BD33 [get_ports {ddr4_dq[33]}]
set_property PACKAGE_PIN AY32 [get_ports {ddr4_dq[34]}]
set_property PACKAGE_PIN BC33 [get_ports {ddr4_dq[35]}]
set_property PACKAGE_PIN BA32 [get_ports {ddr4_dq[36]}]
set_property PACKAGE_PIN BB32 [get_ports {ddr4_dq[37]}]
set_property PACKAGE_PIN BC34 [get_ports {ddr4_dq[38]}]
set_property PACKAGE_PIN BD34 [get_ports {ddr4_dq[39]}]
set_property PACKAGE_PIN BB34 [get_ports {ddr4_dq[40]}]
set_property PACKAGE_PIN BA35 [get_ports {ddr4_dq[41]}]
set_property PACKAGE_PIN BC37 [get_ports {ddr4_dq[42]}]
set_property PACKAGE_PIN BA37 [get_ports {ddr4_dq[43]}]
set_property PACKAGE_PIN BA34 [get_ports {ddr4_dq[44]}]
set_property PACKAGE_PIN BB35 [get_ports {ddr4_dq[45]}]
set_property PACKAGE_PIN BD37 [get_ports {ddr4_dq[46]}]
set_property PACKAGE_PIN BB37 [get_ports {ddr4_dq[47]}]
set_property PACKAGE_PIN AW34 [get_ports {ddr4_dq[48]}]
set_property PACKAGE_PIN AY35 [get_ports {ddr4_dq[49]}]
set_property PACKAGE_PIN AV37 [get_ports {ddr4_dq[50]}]
set_property PACKAGE_PIN AV36 [get_ports {ddr4_dq[51]}]
set_property PACKAGE_PIN AW33 [get_ports {ddr4_dq[52]}]
set_property PACKAGE_PIN AY36 [get_ports {ddr4_dq[53]}]
set_property PACKAGE_PIN AU34 [get_ports {ddr4_dq[54]}]
set_property PACKAGE_PIN AV34 [get_ports {ddr4_dq[55]}]
set_property PACKAGE_PIN AR35 [get_ports {ddr4_dq[56]}]
set_property PACKAGE_PIN AT35 [get_ports {ddr4_dq[57]}]
set_property PACKAGE_PIN AR37 [get_ports {ddr4_dq[58]}]
set_property PACKAGE_PIN AR34 [get_ports {ddr4_dq[59]}]
set_property PACKAGE_PIN AT32 [get_ports {ddr4_dq[60]}]
set_property PACKAGE_PIN AU32 [get_ports {ddr4_dq[61]}]
set_property PACKAGE_PIN AR36 [get_ports {ddr4_dq[62]}]
set_property PACKAGE_PIN AR33 [get_ports {ddr4_dq[63]}]
set_property PACKAGE_PIN AW31 [get_ports {ddr4_dq[64]}]
set_property PACKAGE_PIN AW28 [get_ports {ddr4_dq[65]}]
set_property PACKAGE_PIN AY28 [get_ports {ddr4_dq[66]}]
set_property PACKAGE_PIN BA30 [get_ports {ddr4_dq[67]}]
set_property PACKAGE_PIN AV29 [get_ports {ddr4_dq[68]}]
set_property PACKAGE_PIN AW29 [get_ports {ddr4_dq[69]}]
set_property PACKAGE_PIN AY30 [get_ports {ddr4_dq[70]}]
set_property PACKAGE_PIN AY31 [get_ports {ddr4_dq[71]}]
set_property PACKAGE_PIN AY27 [get_ports {ddr4_dqs_p[0]}]
set_property PACKAGE_PIN BA27 [get_ports {ddr4_dqs_n[0]}]
set_property PACKAGE_PIN BC26 [get_ports {ddr4_dqs_p[1]}]
set_property PACKAGE_PIN BD26 [get_ports {ddr4_dqs_n[1]}]
set_property PACKAGE_PIN BE21 [get_ports {ddr4_dqs_p[2]}]
set_property PACKAGE_PIN BE20 [get_ports {ddr4_dqs_n[2]}]
set_property PACKAGE_PIN BJ23 [get_ports {ddr4_dqs_p[3]}]
set_property PACKAGE_PIN BK23 [get_ports {ddr4_dqs_n[3]}]
set_property PACKAGE_PIN AY33 [get_ports {ddr4_dqs_p[4]}]
set_property PACKAGE_PIN BA33 [get_ports {ddr4_dqs_n[4]}]
set_property PACKAGE_PIN BB36 [get_ports {ddr4_dqs_p[5]}]
set_property PACKAGE_PIN BC36 [get_ports {ddr4_dqs_n[5]}]
set_property PACKAGE_PIN AV32 [get_ports {ddr4_dqs_p[6]}]
set_property PACKAGE_PIN AV33 [get_ports {ddr4_dqs_n[6]}]
set_property PACKAGE_PIN AT33 [get_ports {ddr4_dqs_p[7]}]
set_property PACKAGE_PIN AT34 [get_ports {ddr4_dqs_n[7]}]
set_property PACKAGE_PIN AV31 [get_ports {ddr4_dqs_n[8]}]
set_property PACKAGE_PIN AU31 [get_ports {ddr4_dqs_p[8]}]
set_property PACKAGE_PIN BB30 [get_ports {ddr4_odt[0]}]
set_property PACKAGE_PIN BD30 [get_ports {ddr4_odt[1]}]
set_property PACKAGE_PIN BG30 [get_ports {ddr4_adr[16]}]
set_property PACKAGE_PIN BC31 [get_ports ddr4_reset_n]
set_property PACKAGE_PIN BK30 [get_ports {ddr4_adr[14]}]

set_property -dict {PACKAGE_PIN BD16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports ddr4_scl]
set_property -dict {PACKAGE_PIN BD15 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports ddr4_sda]


















