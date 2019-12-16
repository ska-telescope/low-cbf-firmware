
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
create_clock -period 6.206 [get_ports qsfp_c_clk_p]

create_clock -period 6.400 [get_ports {clk_c_p[0]}]
create_clock -period 6.400 [get_ports {clk_c_p[1]}]
create_clock -period 6.400 [get_ports {clk_c_p[2]}]
create_clock -period 6.400 [get_ports {clk_c_p[3]}]
create_clock -period 6.400 [get_ports {clk_c_p[4]}]

create_clock -period 50.000 [get_ports clk_f]

create_clock -period 3.750 [get_ports clk_g_p]

create_clock -period 5.000 [get_ports clk_h_p]

####################################################################################
# Fixed Configuration Constraints
####################################################################################

set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 10.6 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]

set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]

set_property INTERNAL_VREF 0.84 [get_iobanks 64]
set_property INTERNAL_VREF 0.84 [get_iobanks 65]
set_property INTERNAL_VREF 0.84 [get_iobanks 66]

####################################################################################
# Pin Constraints
####################################################################################

##########################
# Clocks

set_property -dict {PACKAGE_PIN F20 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports clk_e_p]
set_property -dict {PACKAGE_PIN F19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports clk_e_n]

set_property -dict {PACKAGE_PIN F18 IOSTANDARD LVCMOS18} [get_ports clk_f]

set_property -dict {PACKAGE_PIN BJ43 IOSTANDARD DIFF_SSTL12} [get_ports clk_g_p]
set_property -dict {PACKAGE_PIN BJ44 IOSTANDARD DIFF_SSTL12} [get_ports clk_g_n]

set_property -dict {PACKAGE_PIN BH26 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports clk_h_p]
set_property -dict {PACKAGE_PIN BH25 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports clk_h_n]

set_property -dict {PACKAGE_PIN BK3 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports clk_aux_b_n]
set_property -dict {PACKAGE_PIN BJ4 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports clk_aux_b_p]

set_property -dict {PACKAGE_PIN BK5 IOSTANDARD LVCMOS18} [get_ports clk_aux_c]

##########################
# MBOs

set_property -dict {PACKAGE_PIN H10 IOSTANDARD LVCMOS18 IOB TRUE PULLUP TRUE} [get_ports mbo_int_n]
set_property -dict {PACKAGE_PIN G10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 IOB TRUE} [get_ports mbo_sda]
set_property -dict {PACKAGE_PIN F9 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 IOB TRUE} [get_ports mbo_scl]

set_property PACKAGE_PIN W15 [get_ports {clk_d_p[0]}]
set_property PACKAGE_PIN W14 [get_ports {clk_d_n[0]}]
set_property PACKAGE_PIN AH13 [get_ports {clk_d_p[1]}]
set_property PACKAGE_PIN AH12 [get_ports {clk_d_n[1]}]
set_property PACKAGE_PIN AT13 [get_ports {clk_d_p[2]}]
set_property PACKAGE_PIN AT12 [get_ports {clk_d_n[2]}]

# A
set_property PACKAGE_PIN T12 [get_ports {mbo_a_clk_n[0]}]
set_property PACKAGE_PIN V12 [get_ports {mbo_a_clk_n[1]}]
set_property PACKAGE_PIN Y12 [get_ports {mbo_a_clk_n[2]}]
set_property PACKAGE_PIN T13 [get_ports {mbo_a_clk_p[0]}]
set_property PACKAGE_PIN V13 [get_ports {mbo_a_clk_p[1]}]
set_property PACKAGE_PIN Y13 [get_ports {mbo_a_clk_p[2]}]

set_property PACKAGE_PIN N1 [get_ports {mbo_a_rx_n[0]}]
set_property PACKAGE_PIN N2 [get_ports {mbo_a_rx_p[0]}]
set_property PACKAGE_PIN R1 [get_ports {mbo_a_rx_n[1]}]
set_property PACKAGE_PIN R2 [get_ports {mbo_a_rx_p[1]}]
set_property PACKAGE_PIN M3 [get_ports {mbo_a_rx_n[2]}]
set_property PACKAGE_PIN M4 [get_ports {mbo_a_rx_p[2]}]
set_property PACKAGE_PIN P3 [get_ports {mbo_a_rx_n[3]}]
set_property PACKAGE_PIN P4 [get_ports {mbo_a_rx_p[3]}]
set_property PACKAGE_PIN U5 [get_ports {mbo_a_rx_n[4]}]
set_property PACKAGE_PIN U6 [get_ports {mbo_a_rx_p[4]}]
set_property PACKAGE_PIN T3 [get_ports {mbo_a_rx_n[5]}]
set_property PACKAGE_PIN T4 [get_ports {mbo_a_rx_p[5]}]
set_property PACKAGE_PIN L1 [get_ports {mbo_a_rx_n[6]}]
set_property PACKAGE_PIN L2 [get_ports {mbo_a_rx_p[6]}]
set_property PACKAGE_PIN U1 [get_ports {mbo_a_rx_n[7]}]
set_property PACKAGE_PIN U2 [get_ports {mbo_a_rx_p[7]}]
set_property PACKAGE_PIN K3 [get_ports {mbo_a_rx_n[8]}]
set_property PACKAGE_PIN K4 [get_ports {mbo_a_rx_p[8]}]
set_property PACKAGE_PIN R5 [get_ports {mbo_a_rx_n[9]}]
set_property PACKAGE_PIN R6 [get_ports {mbo_a_rx_p[9]}]
set_property PACKAGE_PIN J1 [get_ports {mbo_a_rx_n[10]}]
set_property PACKAGE_PIN J2 [get_ports {mbo_a_rx_p[10]}]
set_property PACKAGE_PIN H3 [get_ports {mbo_a_rx_n[11]}]
set_property PACKAGE_PIN H4 [get_ports {mbo_a_rx_p[11]}]

set_property PACKAGE_PIN T9 [get_ports {mbo_a_tx_p[0]}]
set_property PACKAGE_PIN T8 [get_ports {mbo_a_tx_n[0]}]
set_property PACKAGE_PIN P9 [get_ports {mbo_a_tx_p[1]}]
set_property PACKAGE_PIN P8 [get_ports {mbo_a_tx_n[1]}]
set_property PACKAGE_PIN V9 [get_ports {mbo_a_tx_p[2]}]
set_property PACKAGE_PIN V8 [get_ports {mbo_a_tx_n[2]}]
set_property PACKAGE_PIN N7 [get_ports {mbo_a_tx_p[3]}]
set_property PACKAGE_PIN N6 [get_ports {mbo_a_tx_n[3]}]
set_property PACKAGE_PIN U11 [get_ports {mbo_a_tx_p[4]}]
set_property PACKAGE_PIN U10 [get_ports {mbo_a_tx_n[4]}]
set_property PACKAGE_PIN M9 [get_ports {mbo_a_tx_p[5]}]
set_property PACKAGE_PIN M8 [get_ports {mbo_a_tx_n[5]}]
set_property PACKAGE_PIN R11 [get_ports {mbo_a_tx_p[6]}]
set_property PACKAGE_PIN R10 [get_ports {mbo_a_tx_n[6]}]
set_property PACKAGE_PIN L7 [get_ports {mbo_a_tx_p[7]}]
set_property PACKAGE_PIN L6 [get_ports {mbo_a_tx_n[7]}]
set_property PACKAGE_PIN N11 [get_ports {mbo_a_tx_p[8]}]
set_property PACKAGE_PIN N10 [get_ports {mbo_a_tx_n[8]}]
set_property PACKAGE_PIN K9 [get_ports {mbo_a_tx_p[9]}]
set_property PACKAGE_PIN K8 [get_ports {mbo_a_tx_n[9]}]
set_property PACKAGE_PIN L11 [get_ports {mbo_a_tx_p[10]}]
set_property PACKAGE_PIN L10 [get_ports {mbo_a_tx_n[10]}]
set_property PACKAGE_PIN J7 [get_ports {mbo_a_tx_p[11]}]
set_property PACKAGE_PIN J6 [get_ports {mbo_a_tx_n[11]}]

set_property -dict {PACKAGE_PIN E9 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 IOB TRUE} [get_ports mbo_a_reset]


# B
set_property PACKAGE_PIN AD13 [get_ports {mbo_b_clk_p[0]}]
set_property PACKAGE_PIN AD12 [get_ports {mbo_b_clk_n[0]}]
set_property PACKAGE_PIN AG15 [get_ports {mbo_b_clk_p[1]}]
set_property PACKAGE_PIN AG14 [get_ports {mbo_b_clk_n[1]}]
set_property PACKAGE_PIN AJ15 [get_ports {mbo_b_clk_p[2]}]
set_property PACKAGE_PIN AJ14 [get_ports {mbo_b_clk_n[2]}]

set_property PACKAGE_PIN AC2 [get_ports {mbo_b_rx_p[0]}]
set_property PACKAGE_PIN AC1 [get_ports {mbo_b_rx_n[0]}]
set_property PACKAGE_PIN AF4 [get_ports {mbo_b_rx_p[1]}]
set_property PACKAGE_PIN AF3 [get_ports {mbo_b_rx_n[1]}]
set_property PACKAGE_PIN AB4 [get_ports {mbo_b_rx_p[2]}]
set_property PACKAGE_PIN AB3 [get_ports {mbo_b_rx_n[2]}]
set_property PACKAGE_PIN AG2 [get_ports {mbo_b_rx_p[3]}]
set_property PACKAGE_PIN AG1 [get_ports {mbo_b_rx_n[3]}]
set_property PACKAGE_PIN AD4 [get_ports {mbo_b_rx_p[4]}]
set_property PACKAGE_PIN AD3 [get_ports {mbo_b_rx_n[4]}]
set_property PACKAGE_PIN AE2 [get_ports {mbo_b_rx_p[5]}]
set_property PACKAGE_PIN AE1 [get_ports {mbo_b_rx_n[5]}]
set_property PACKAGE_PIN AC6 [get_ports {mbo_b_rx_p[6]}]
set_property PACKAGE_PIN AC5 [get_ports {mbo_b_rx_n[6]}]
set_property PACKAGE_PIN AH4 [get_ports {mbo_b_rx_p[7]}]
set_property PACKAGE_PIN AH3 [get_ports {mbo_b_rx_n[7]}]
set_property PACKAGE_PIN AE6 [get_ports {mbo_b_rx_p[8]}]
set_property PACKAGE_PIN AE5 [get_ports {mbo_b_rx_n[8]}]
set_property PACKAGE_PIN AJ2 [get_ports {mbo_b_rx_p[9]}]
set_property PACKAGE_PIN AJ1 [get_ports {mbo_b_rx_n[9]}]
set_property PACKAGE_PIN AL6 [get_ports {mbo_b_rx_p[10]}]
set_property PACKAGE_PIN AL5 [get_ports {mbo_b_rx_n[10]}]
set_property PACKAGE_PIN AK4 [get_ports {mbo_b_rx_p[11]}]
set_property PACKAGE_PIN AK3 [get_ports {mbo_b_rx_n[11]}]

set_property PACKAGE_PIN AJ7 [get_ports {mbo_b_tx_p[0]}]
set_property PACKAGE_PIN AJ6 [get_ports {mbo_b_tx_n[0]}]
set_property PACKAGE_PIN AF9 [get_ports {mbo_b_tx_p[1]}]
set_property PACKAGE_PIN AF8 [get_ports {mbo_b_tx_n[1]}]
set_property PACKAGE_PIN AH9 [get_ports {mbo_b_tx_p[2]}]
set_property PACKAGE_PIN AH8 [get_ports {mbo_b_tx_n[2]}]
set_property PACKAGE_PIN AD9 [get_ports {mbo_b_tx_p[3]}]
set_property PACKAGE_PIN AD8 [get_ports {mbo_b_tx_n[3]}]
set_property PACKAGE_PIN AK9 [get_ports {mbo_b_tx_p[4]}]
set_property PACKAGE_PIN AK8 [get_ports {mbo_b_tx_n[4]}]
set_property PACKAGE_PIN AG7 [get_ports {mbo_b_tx_p[5]}]
set_property PACKAGE_PIN AG6 [get_ports {mbo_b_tx_n[5]}]
set_property PACKAGE_PIN AJ11 [get_ports {mbo_b_tx_p[6]}]
set_property PACKAGE_PIN AJ10 [get_ports {mbo_b_tx_n[6]}]
set_property PACKAGE_PIN AE11 [get_ports {mbo_b_tx_p[7]}]
set_property PACKAGE_PIN AE10 [get_ports {mbo_b_tx_n[7]}]
set_property PACKAGE_PIN AG11 [get_ports {mbo_b_tx_p[8]}]
set_property PACKAGE_PIN AG10 [get_ports {mbo_b_tx_n[8]}]
set_property PACKAGE_PIN AC11 [get_ports {mbo_b_tx_p[9]}]
set_property PACKAGE_PIN AC10 [get_ports {mbo_b_tx_n[9]}]
set_property PACKAGE_PIN AB9 [get_ports {mbo_b_tx_p[10]}]
set_property PACKAGE_PIN AB8 [get_ports {mbo_b_tx_n[10]}]
set_property PACKAGE_PIN AA7 [get_ports {mbo_b_tx_p[11]}]
set_property PACKAGE_PIN AA6 [get_ports {mbo_b_tx_n[11]}]

set_property -dict {PACKAGE_PIN H9 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 IOB TRUE} [get_ports mbo_b_reset]


# C
set_property PACKAGE_PIN AN15 [get_ports {mbo_c_clk_p[0]}]
set_property PACKAGE_PIN AN14 [get_ports {mbo_c_clk_n[0]}]
set_property PACKAGE_PIN AR15 [get_ports {mbo_c_clk_p[1]}]
set_property PACKAGE_PIN AR14 [get_ports {mbo_c_clk_n[1]}]
set_property PACKAGE_PIN AV13 [get_ports {mbo_c_clk_p[2]}]
set_property PACKAGE_PIN AV12 [get_ports {mbo_c_clk_n[2]}]

set_property PACKAGE_PIN AT4 [get_ports {mbo_c_rx_p[0]}]
set_property PACKAGE_PIN AT3 [get_ports {mbo_c_rx_n[0]}]
set_property PACKAGE_PIN AU2 [get_ports {mbo_c_rx_p[1]}]
set_property PACKAGE_PIN AU1 [get_ports {mbo_c_rx_n[1]}]
set_property PACKAGE_PIN AR2 [get_ports {mbo_c_rx_p[2]}]
set_property PACKAGE_PIN AR1 [get_ports {mbo_c_rx_n[2]}]
set_property PACKAGE_PIN AV4 [get_ports {mbo_c_rx_p[3]}]
set_property PACKAGE_PIN AV3 [get_ports {mbo_c_rx_n[3]}]
set_property PACKAGE_PIN AP4 [get_ports {mbo_c_rx_p[4]}]
set_property PACKAGE_PIN AP3 [get_ports {mbo_c_rx_n[4]}]
set_property PACKAGE_PIN AW2 [get_ports {mbo_c_rx_p[5]}]
set_property PACKAGE_PIN AW1 [get_ports {mbo_c_rx_n[5]}]
set_property PACKAGE_PIN AW6 [get_ports {mbo_c_rx_p[6]}]
set_property PACKAGE_PIN AW5 [get_ports {mbo_c_rx_n[6]}]
set_property PACKAGE_PIN AY4 [get_ports {mbo_c_rx_p[7]}]
set_property PACKAGE_PIN AY3 [get_ports {mbo_c_rx_n[7]}]
set_property PACKAGE_PIN BA6 [get_ports {mbo_c_rx_p[8]}]
set_property PACKAGE_PIN BA5 [get_ports {mbo_c_rx_n[8]}]
set_property PACKAGE_PIN BA2 [get_ports {mbo_c_rx_p[9]}]
set_property PACKAGE_PIN BA1 [get_ports {mbo_c_rx_n[9]}]
set_property PACKAGE_PIN BC2 [get_ports {mbo_c_rx_p[10]}]
set_property PACKAGE_PIN BC1 [get_ports {mbo_c_rx_n[10]}]
set_property PACKAGE_PIN BB4 [get_ports {mbo_c_rx_p[11]}]
set_property PACKAGE_PIN BB3 [get_ports {mbo_c_rx_n[11]}]

set_property PACKAGE_PIN AY9 [get_ports {mbo_c_tx_p[0]}]
set_property PACKAGE_PIN AY8 [get_ports {mbo_c_tx_n[0]}]
set_property PACKAGE_PIN AV9 [get_ports {mbo_c_tx_p[1]}]
set_property PACKAGE_PIN AV8 [get_ports {mbo_c_tx_n[1]}]
set_property PACKAGE_PIN BB9 [get_ports {mbo_c_tx_p[2]}]
set_property PACKAGE_PIN BB8 [get_ports {mbo_c_tx_n[2]}]
set_property PACKAGE_PIN AU7 [get_ports {mbo_c_tx_p[3]}]
set_property PACKAGE_PIN AU6 [get_ports {mbo_c_tx_n[3]}]
set_property PACKAGE_PIN BC7 [get_ports {mbo_c_tx_p[4]}]
set_property PACKAGE_PIN BC6 [get_ports {mbo_c_tx_n[4]}]
set_property PACKAGE_PIN AT9 [get_ports {mbo_c_tx_p[5]}]
set_property PACKAGE_PIN AT8 [get_ports {mbo_c_tx_n[5]}]
set_property PACKAGE_PIN BC11 [get_ports {mbo_c_tx_p[6]}]
set_property PACKAGE_PIN BC10 [get_ports {mbo_c_tx_n[6]}]
set_property PACKAGE_PIN AR7 [get_ports {mbo_c_tx_p[7]}]
set_property PACKAGE_PIN AR6 [get_ports {mbo_c_tx_n[7]}]
set_property PACKAGE_PIN AW11 [get_ports {mbo_c_tx_p[8]}]
set_property PACKAGE_PIN AW10 [get_ports {mbo_c_tx_n[8]}]
set_property PACKAGE_PIN AU11 [get_ports {mbo_c_tx_p[9]}]
set_property PACKAGE_PIN AU10 [get_ports {mbo_c_tx_n[9]}]
set_property PACKAGE_PIN BA11 [get_ports {mbo_c_tx_p[10]}]
set_property PACKAGE_PIN BA10 [get_ports {mbo_c_tx_n[10]}]
set_property PACKAGE_PIN AR11 [get_ports {mbo_c_tx_p[11]}]
set_property PACKAGE_PIN AR10 [get_ports {mbo_c_tx_n[11]}]

set_property -dict {PACKAGE_PIN D9 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 IOB TRUE} [get_ports mbo_c_reset]

##########################
# QSFPs

set_property -dict {PACKAGE_PIN D21 IOSTANDARD LVCMOS18 IOB TRUE PULLUP TRUE} [get_ports qsfp_int_n]

set_property -dict {PACKAGE_PIN A11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 IOB TRUE} [get_ports qsfp_scl]
set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 IOB TRUE} [get_ports qsfp_sda]

set_property PACKAGE_PIN U15 [get_ports {clk_c_p[0]}]
set_property PACKAGE_PIN U14 [get_ports {clk_c_n[0]}]
set_property PACKAGE_PIN AF13 [get_ports {clk_c_p[1]}]
set_property PACKAGE_PIN AF12 [get_ports {clk_c_n[1]}]
set_property PACKAGE_PIN AP13 [get_ports {clk_c_p[2]}]
set_property PACKAGE_PIN AP12 [get_ports {clk_c_n[2]}]
set_property PACKAGE_PIN AC40 [get_ports {clk_c_p[3]}]
set_property PACKAGE_PIN AC41 [get_ports {clk_c_n[3]}]
set_property PACKAGE_PIN AM42 [get_ports {clk_c_p[4]}]
set_property PACKAGE_PIN AM43 [get_ports {clk_c_n[4]}]

# A
set_property PACKAGE_PIN AB42 [get_ports qsfp_a_clk_p]
set_property PACKAGE_PIN AB43 [get_ports qsfp_a_clk_n]

set_property PACKAGE_PIN W53 [get_ports {qsfp_a_rx_p[0]}]
set_property PACKAGE_PIN W54 [get_ports {qsfp_a_rx_n[0]}]
set_property PACKAGE_PIN V51 [get_ports {qsfp_a_rx_p[1]}]
set_property PACKAGE_PIN V52 [get_ports {qsfp_a_rx_n[1]}]
set_property PACKAGE_PIN AA53 [get_ports {qsfp_a_rx_p[2]}]
set_property PACKAGE_PIN AA54 [get_ports {qsfp_a_rx_n[2]}]
set_property PACKAGE_PIN Y51 [get_ports {qsfp_a_rx_p[3]}]
set_property PACKAGE_PIN Y52 [get_ports {qsfp_a_rx_n[3]}]

set_property PACKAGE_PIN W48 [get_ports {qsfp_a_tx_p[0]}]
set_property PACKAGE_PIN W49 [get_ports {qsfp_a_tx_n[0]}]
set_property PACKAGE_PIN W44 [get_ports {qsfp_a_tx_p[1]}]
set_property PACKAGE_PIN W45 [get_ports {qsfp_a_tx_n[1]}]
set_property PACKAGE_PIN AA44 [get_ports {qsfp_a_tx_p[2]}]
set_property PACKAGE_PIN AA45 [get_ports {qsfp_a_tx_n[2]}]
set_property PACKAGE_PIN Y46 [get_ports {qsfp_a_tx_p[3]}]
set_property PACKAGE_PIN Y47 [get_ports {qsfp_a_tx_n[3]}]

set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_a_led]
set_property -dict {PACKAGE_PIN A21 IOSTANDARD LVCMOS18 PULLUP TRUE} [get_ports qsfp_a_mod_prs_n]
set_property -dict {PACKAGE_PIN A13 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_a_mod_sel]
set_property -dict {PACKAGE_PIN B21 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_a_reset]

# B
set_property PACKAGE_PIN AD42 [get_ports qsfp_b_clk_p]
set_property PACKAGE_PIN AD43 [get_ports qsfp_b_clk_n]

set_property PACKAGE_PIN AC53 [get_ports {qsfp_b_rx_p[0]}]
set_property PACKAGE_PIN AC54 [get_ports {qsfp_b_rx_n[0]}]
set_property PACKAGE_PIN AB51 [get_ports {qsfp_b_rx_p[1]}]
set_property PACKAGE_PIN AB52 [get_ports {qsfp_b_rx_n[1]}]
set_property PACKAGE_PIN AD51 [get_ports {qsfp_b_rx_p[2]}]
set_property PACKAGE_PIN AD52 [get_ports {qsfp_b_rx_n[2]}]
set_property PACKAGE_PIN AC49 [get_ports {qsfp_b_rx_p[3]}]
set_property PACKAGE_PIN AC50 [get_ports {qsfp_b_rx_n[3]}]

set_property PACKAGE_PIN AC44 [get_ports {qsfp_b_tx_p[0]}]
set_property PACKAGE_PIN AC45 [get_ports {qsfp_b_tx_n[0]}]
set_property PACKAGE_PIN AA48 [get_ports {qsfp_b_tx_p[1]}]
set_property PACKAGE_PIN AA49 [get_ports {qsfp_b_tx_n[1]}]
set_property PACKAGE_PIN AD46 [get_ports {qsfp_b_tx_p[2]}]
set_property PACKAGE_PIN AD47 [get_ports {qsfp_b_tx_n[2]}]
set_property PACKAGE_PIN AB46 [get_ports {qsfp_b_tx_p[3]}]
set_property PACKAGE_PIN AB47 [get_ports {qsfp_b_tx_n[3]}]

set_property -dict {PACKAGE_PIN C18 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_b_led]
set_property -dict {PACKAGE_PIN A20 IOSTANDARD LVCMOS18 PULLUP TRUE} [get_ports qsfp_b_mod_prs_n]
set_property -dict {PACKAGE_PIN C14 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_b_mod_sel]
set_property -dict {PACKAGE_PIN A14 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_b_reset]

# C
set_property PACKAGE_PIN AJ40 [get_ports qsfp_c_clk_p]
set_property PACKAGE_PIN AJ41 [get_ports qsfp_c_clk_n]

set_property PACKAGE_PIN AL49 [get_ports {qsfp_c_rx_p[0]}]
set_property PACKAGE_PIN AL50 [get_ports {qsfp_c_rx_n[0]}]
set_property PACKAGE_PIN AK51 [get_ports {qsfp_c_rx_p[1]}]
set_property PACKAGE_PIN AK52 [get_ports {qsfp_c_rx_n[1]}]
set_property PACKAGE_PIN AJ53 [get_ports {qsfp_c_rx_p[2]}]
set_property PACKAGE_PIN AJ54 [get_ports {qsfp_c_rx_n[2]}]
set_property PACKAGE_PIN AH51 [get_ports {qsfp_c_rx_p[3]}]
set_property PACKAGE_PIN AH52 [get_ports {qsfp_c_rx_n[3]}]

set_property PACKAGE_PIN AK46 [get_ports {qsfp_c_tx_p[0]}]
set_property PACKAGE_PIN AK47 [get_ports {qsfp_c_tx_n[0]}]
set_property PACKAGE_PIN AJ48 [get_ports {qsfp_c_tx_p[1]}]
set_property PACKAGE_PIN AJ49 [get_ports {qsfp_c_tx_n[1]}]
set_property PACKAGE_PIN AJ44 [get_ports {qsfp_c_tx_p[2]}]
set_property PACKAGE_PIN AJ45 [get_ports {qsfp_c_tx_n[2]}]
set_property PACKAGE_PIN AH46 [get_ports {qsfp_c_tx_p[3]}]
set_property PACKAGE_PIN AH47 [get_ports {qsfp_c_tx_n[3]}]

set_property -dict {PACKAGE_PIN C19 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_c_led]
set_property -dict {PACKAGE_PIN C20 IOSTANDARD LVCMOS18 PULLUP TRUE} [get_ports qsfp_c_mod_prs_n]
set_property -dict {PACKAGE_PIN A15 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_c_mod_sel]
set_property -dict {PACKAGE_PIN A16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_c_reset]

# D
set_property PACKAGE_PIN AN40 [get_ports qsfp_d_clk_p]
set_property PACKAGE_PIN AN41 [get_ports qsfp_d_clk_n]

set_property PACKAGE_PIN AR53 [get_ports {qsfp_d_rx_p[0]}]
set_property PACKAGE_PIN AR54 [get_ports {qsfp_d_rx_n[0]}]
set_property PACKAGE_PIN AP51 [get_ports {qsfp_d_rx_p[1]}]
set_property PACKAGE_PIN AP52 [get_ports {qsfp_d_rx_n[1]}]
set_property PACKAGE_PIN AU53 [get_ports {qsfp_d_rx_p[2]}]
set_property PACKAGE_PIN AU54 [get_ports {qsfp_d_rx_n[2]}]
set_property PACKAGE_PIN AT51 [get_ports {qsfp_d_rx_p[3]}]
set_property PACKAGE_PIN AT52 [get_ports {qsfp_d_rx_n[3]}]

set_property PACKAGE_PIN AR48 [get_ports {qsfp_d_tx_p[0]}]
set_property PACKAGE_PIN AR49 [get_ports {qsfp_d_tx_n[0]}]
set_property PACKAGE_PIN AR44 [get_ports {qsfp_d_tx_p[1]}]
set_property PACKAGE_PIN AR45 [get_ports {qsfp_d_tx_n[1]}]
set_property PACKAGE_PIN AU48 [get_ports {qsfp_d_tx_p[2]}]
set_property PACKAGE_PIN AU49 [get_ports {qsfp_d_tx_n[2]}]
set_property PACKAGE_PIN AT46 [get_ports {qsfp_d_tx_p[3]}]
set_property PACKAGE_PIN AT47 [get_ports {qsfp_d_tx_n[3]}]

set_property -dict {PACKAGE_PIN B20 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_d_led]
set_property -dict {PACKAGE_PIN A19 IOSTANDARD LVCMOS18 PULLUP TRUE} [get_ports qsfp_d_mod_prs_n]
set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_d_mod_sel]
set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports qsfp_d_reset]

##########################
# SFP

set_property PACKAGE_PIN AT42 [get_ports sfp_clk_c_p]
set_property PACKAGE_PIN AT43 [get_ports sfp_clk_c_n]

set_property PACKAGE_PIN AV42 [get_ports sfp_clk_e_p]
set_property PACKAGE_PIN AV43 [get_ports sfp_clk_e_n]

set_property PACKAGE_PIN BC48 [get_ports sfp_tx_p]
set_property PACKAGE_PIN BC49 [get_ports sfp_tx_n]

set_property PACKAGE_PIN BC53 [get_ports sfp_rx_p]
set_property PACKAGE_PIN BC54 [get_ports sfp_rx_n]


set_property -dict {PACKAGE_PIN BJ22 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 IOB TRUE} [get_ports sfp_scl]
set_property -dict {PACKAGE_PIN BH21 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 IOB TRUE} [get_ports sfp_sda]

set_property -dict {PACKAGE_PIN B15 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports sfp_led]
set_property -dict {PACKAGE_PIN G16 IOSTANDARD LVCMOS18 PULLUP TRUE} [get_ports sfp_fault]
set_property -dict {PACKAGE_PIN BG22 IOSTANDARD LVCMOS18 PULLUP TRUE} [get_ports sfp_mod_abs]
set_property -dict {PACKAGE_PIN F13 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports sfp_tx_enable]

##########################
# Leds

set_property -dict {PACKAGE_PIN C12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports led_cs]
set_property -dict {PACKAGE_PIN B12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports led_din]
set_property -dict {PACKAGE_PIN G11 IOSTANDARD LVCMOS18 IOB TRUE} [get_ports led_dout]
set_property -dict {PACKAGE_PIN C10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports led_sclk]


##########################
# Debug IO

set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {debug[0]}]
set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {debug[1]}]
set_property -dict {PACKAGE_PIN F16 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {debug[2]}]
set_property -dict {PACKAGE_PIN E16 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {debug[3]}]

##########################
# Power Interface

set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS18}  [get_ports power_alert_n]

set_property -dict {PACKAGE_PIN C9 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 IOB TRUE PULLUP TRUE}  [get_ports power_sda]
set_property -dict {PACKAGE_PIN B10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 IOB TRUE PULLUP TRUE}  [get_ports power_sdc]

set_property -dict {PACKAGE_PIN BL2 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports shutdown]

##########################
# Onewire Onboard

set_property -dict {PACKAGE_PIN BP7 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 IOB TRUE} [get_ports serial_id]
set_property -dict {PACKAGE_PIN BP6 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2} [get_ports serial_id_pullup]


##########################
# Other IO

set_property -dict {PACKAGE_PIN BM3 IOSTANDARD LVCMOS18 PULLUP TRUE} [get_ports {version[0]}]
set_property -dict {PACKAGE_PIN BM4 IOSTANDARD LVCMOS18 PULLUP TRUE} [get_ports {version[1]}]

##########################
# Backplane IO


set_property -dict {PACKAGE_PIN F11 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports clk_bp_p]
set_property -dict {PACKAGE_PIN E11 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports clk_bp_n]

set_property -dict {PACKAGE_PIN E13 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {bp_aux_io_p[0]}]
set_property -dict {PACKAGE_PIN D12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {bp_aux_io_n[0]}]

set_property -dict {PACKAGE_PIN E12 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {bp_aux_io_p[1]}]
set_property -dict {PACKAGE_PIN D11 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100} [get_ports {bp_aux_io_n[1]}]

set_property -dict {PACKAGE_PIN D10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports bp_id]
set_property -dict {PACKAGE_PIN F10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports bp_id_pullup]

set_property -dict {PACKAGE_PIN A10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports bp_power_scl]
set_property -dict {PACKAGE_PIN A9 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports bp_power_sda]


##########################
# PTP

set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports ptp_clk_sel]
set_property -dict {PACKAGE_PIN B16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports ptp_din]
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports ptp_pll_reset]
set_property -dict {PACKAGE_PIN D16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports ptp_sclk]

set_property -dict {PACKAGE_PIN E17 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports {ptp_sync_n[0]}]
set_property -dict {PACKAGE_PIN B17 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports {ptp_sync_n[1]}]

##########################
# Humidity Sensor

set_property -dict {PACKAGE_PIN BK1 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports hum_sda]
set_property -dict {PACKAGE_PIN BJ1 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports hum_sdc]


##########################
# DDR4

set_property PACKAGE_PIN BE41 [get_ports {ddr4_adr[0]}]
set_property PACKAGE_PIN BK45 [get_ports {ddr4_adr[1]}]
set_property PACKAGE_PIN BP44 [get_ports {ddr4_adr[2]}]
set_property PACKAGE_PIN BJ41 [get_ports {ddr4_adr[3]}]
set_property PACKAGE_PIN BL42 [get_ports {ddr4_adr[4]}]
set_property PACKAGE_PIN BN44 [get_ports {ddr4_adr[5]}]
set_property PACKAGE_PIN BF41 [get_ports {ddr4_adr[6]}]
set_property PACKAGE_PIN BK41 [get_ports {ddr4_adr[7]}]
set_property PACKAGE_PIN BH42 [get_ports {ddr4_adr[8]}]
set_property PACKAGE_PIN BP42 [get_ports {ddr4_adr[9]}]
set_property PACKAGE_PIN BN46 [get_ports {ddr4_adr[10]}]
set_property PACKAGE_PIN BP43 [get_ports {ddr4_adr[11]}]
set_property PACKAGE_PIN BG44 [get_ports {ddr4_adr[12]}]
set_property PACKAGE_PIN BM47 [get_ports {ddr4_adr[13]}]
set_property PACKAGE_PIN BK46 [get_ports {ddr4_adr[14]}]
set_property PACKAGE_PIN BL46 [get_ports {ddr4_adr[15]}]
set_property PACKAGE_PIN BL47 [get_ports {ddr4_adr[16]}]

set_property PACKAGE_PIN BL43 [get_ports ddr4_act_n]
set_property PACKAGE_PIN BH46 [get_ports ddr4_reset_n]
set_property -dict {PACKAGE_PIN BL45 IOSTANDARD LVCMOS12} [get_ports ddr4_parity]

set_property PACKAGE_PIN BN45 [get_ports {ddr4_ba[0]}]
set_property PACKAGE_PIN BG42 [get_ports {ddr4_ba[1]}]

set_property PACKAGE_PIN BM45 [get_ports {ddr4_bg[0]}]
set_property PACKAGE_PIN BG43 [get_ports {ddr4_bg[1]}]

set_property PACKAGE_PIN BG45 [get_ports {ddr4_odt[0]}]
set_property PACKAGE_PIN BJ46 [get_ports {ddr4_odt[1]}]

set_property PACKAGE_PIN BH45 [get_ports {ddr4_ck_n[0]}]
set_property PACKAGE_PIN BH44 [get_ports {ddr4_ck_p[0]}]
set_property PACKAGE_PIN BK44 [get_ports {ddr4_ck_n[1]}]
set_property PACKAGE_PIN BK43 [get_ports {ddr4_ck_p[1]}]

set_property PACKAGE_PIN BJ42 [get_ports {ddr4_cke[0]}]
set_property PACKAGE_PIN BM42 [get_ports {ddr4_cke[1]}]

set_property PACKAGE_PIN BM44 [get_ports {ddr4_cs[0]}]
set_property PACKAGE_PIN BP46 [get_ports {ddr4_cs[1]}]
set_property -dict {PACKAGE_PIN BP47 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_cs[2]}]
set_property -dict {PACKAGE_PIN BN47 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_cs[3]}]

set_property PACKAGE_PIN BG29 [get_ports {ddr4_dm[0]}]
set_property PACKAGE_PIN BM28 [get_ports {ddr4_dm[1]}]
set_property PACKAGE_PIN BH32 [get_ports {ddr4_dm[2]}]
set_property PACKAGE_PIN BM34 [get_ports {ddr4_dm[3]}]
set_property PACKAGE_PIN BK48 [get_ports {ddr4_dm[4]}]
set_property PACKAGE_PIN BP48 [get_ports {ddr4_dm[5]}]
set_property PACKAGE_PIN BG48 [get_ports {ddr4_dm[6]}]
set_property PACKAGE_PIN BJ52 [get_ports {ddr4_dm[7]}]
set_property PACKAGE_PIN BD41 [get_ports {ddr4_dm[8]}]

set_property PACKAGE_PIN BF32 [get_ports {ddr4_dq[0]}]
set_property PACKAGE_PIN BH31 [get_ports {ddr4_dq[1]}]
set_property PACKAGE_PIN BG32 [get_ports {ddr4_dq[2]}]
set_property PACKAGE_PIN BF33 [get_ports {ddr4_dq[3]}]
set_property PACKAGE_PIN BH29 [get_ports {ddr4_dq[4]}]
set_property PACKAGE_PIN BH30 [get_ports {ddr4_dq[5]}]
set_property PACKAGE_PIN BF31 [get_ports {ddr4_dq[6]}]
set_property PACKAGE_PIN BJ31 [get_ports {ddr4_dq[7]}]
set_property PACKAGE_PIN BL30 [get_ports {ddr4_dq[8]}]
set_property PACKAGE_PIN BP31 [get_ports {ddr4_dq[9]}]
set_property PACKAGE_PIN BP32 [get_ports {ddr4_dq[10]}]
set_property PACKAGE_PIN BN32 [get_ports {ddr4_dq[11]}]
set_property PACKAGE_PIN BP28 [get_ports {ddr4_dq[12]}]
set_property PACKAGE_PIN BP29 [get_ports {ddr4_dq[13]}]
set_property PACKAGE_PIN BM30 [get_ports {ddr4_dq[14]}]
set_property PACKAGE_PIN BN31 [get_ports {ddr4_dq[15]}]
set_property PACKAGE_PIN BJ34 [get_ports {ddr4_dq[16]}]
set_property PACKAGE_PIN BH35 [get_ports {ddr4_dq[17]}]
set_property PACKAGE_PIN BH34 [get_ports {ddr4_dq[18]}]
set_property PACKAGE_PIN BF36 [get_ports {ddr4_dq[19]}]
set_property PACKAGE_PIN BG35 [get_ports {ddr4_dq[20]}]
set_property PACKAGE_PIN BG34 [get_ports {ddr4_dq[21]}]
set_property PACKAGE_PIN BJ33 [get_ports {ddr4_dq[22]}]
set_property PACKAGE_PIN BF35 [get_ports {ddr4_dq[23]}]
set_property PACKAGE_PIN BK31 [get_ports {ddr4_dq[24]}]
set_property PACKAGE_PIN BN34 [get_ports {ddr4_dq[25]}]
set_property PACKAGE_PIN BP34 [get_ports {ddr4_dq[26]}]
set_property PACKAGE_PIN BM33 [get_ports {ddr4_dq[27]}]
set_property PACKAGE_PIN BL31 [get_ports {ddr4_dq[28]}]
set_property PACKAGE_PIN BL32 [get_ports {ddr4_dq[29]}]
set_property PACKAGE_PIN BK33 [get_ports {ddr4_dq[30]}]
set_property PACKAGE_PIN BL33 [get_ports {ddr4_dq[31]}]
set_property PACKAGE_PIN BK50 [get_ports {ddr4_dq[32]}]
set_property PACKAGE_PIN BH49 [get_ports {ddr4_dq[33]}]
set_property PACKAGE_PIN BK51 [get_ports {ddr4_dq[34]}]
set_property PACKAGE_PIN BJ51 [get_ports {ddr4_dq[35]}]
set_property PACKAGE_PIN BJ48 [get_ports {ddr4_dq[36]}]
set_property PACKAGE_PIN BJ49 [get_ports {ddr4_dq[37]}]
set_property PACKAGE_PIN BH50 [get_ports {ddr4_dq[38]}]
set_property PACKAGE_PIN BH51 [get_ports {ddr4_dq[39]}]
set_property PACKAGE_PIN BN50 [get_ports {ddr4_dq[40]}]
set_property PACKAGE_PIN BN49 [get_ports {ddr4_dq[41]}]
set_property PACKAGE_PIN BL53 [get_ports {ddr4_dq[42]}]
set_property PACKAGE_PIN BM52 [get_ports {ddr4_dq[43]}]
set_property PACKAGE_PIN BN51 [get_ports {ddr4_dq[44]}]
set_property PACKAGE_PIN BM48 [get_ports {ddr4_dq[45]}]
set_property PACKAGE_PIN BL52 [get_ports {ddr4_dq[46]}]
set_property PACKAGE_PIN BL51 [get_ports {ddr4_dq[47]}]
set_property PACKAGE_PIN BF52 [get_ports {ddr4_dq[48]}]
set_property PACKAGE_PIN BE51 [get_ports {ddr4_dq[49]}]
set_property PACKAGE_PIN BE50 [get_ports {ddr4_dq[50]}]
set_property PACKAGE_PIN BD51 [get_ports {ddr4_dq[51]}]
set_property PACKAGE_PIN BG50 [get_ports {ddr4_dq[52]}]
set_property PACKAGE_PIN BF50 [get_ports {ddr4_dq[53]}]
set_property PACKAGE_PIN BF51 [get_ports {ddr4_dq[54]}]
set_property PACKAGE_PIN BE49 [get_ports {ddr4_dq[55]}]
set_property PACKAGE_PIN BG53 [get_ports {ddr4_dq[56]}]
set_property PACKAGE_PIN BK54 [get_ports {ddr4_dq[57]}]
set_property PACKAGE_PIN BE54 [get_ports {ddr4_dq[58]}]
set_property PACKAGE_PIN BE53 [get_ports {ddr4_dq[59]}]
set_property PACKAGE_PIN BK53 [get_ports {ddr4_dq[60]}]
set_property PACKAGE_PIN BH52 [get_ports {ddr4_dq[61]}]
set_property PACKAGE_PIN BG54 [get_ports {ddr4_dq[62]}]
set_property PACKAGE_PIN BG52 [get_ports {ddr4_dq[63]}]
set_property PACKAGE_PIN BD42 [get_ports {ddr4_dq[64]}]
set_property PACKAGE_PIN BE43 [get_ports {ddr4_dq[65]}]
set_property PACKAGE_PIN BF46 [get_ports {ddr4_dq[66]}]
set_property PACKAGE_PIN BF45 [get_ports {ddr4_dq[67]}]
set_property PACKAGE_PIN BC42 [get_ports {ddr4_dq[68]}]
set_property PACKAGE_PIN BF42 [get_ports {ddr4_dq[69]}]
set_property PACKAGE_PIN BF43 [get_ports {ddr4_dq[70]}]
set_property PACKAGE_PIN BE44 [get_ports {ddr4_dq[71]}]

set_property PACKAGE_PIN BJ29 [get_ports {ddr4_dqs_p[0]}]
set_property PACKAGE_PIN BK30 [get_ports {ddr4_dqs_n[0]}]
set_property PACKAGE_PIN BN29 [get_ports {ddr4_dqs_p[1]}]
set_property PACKAGE_PIN BN30 [get_ports {ddr4_dqs_n[1]}]
set_property PACKAGE_PIN BK34 [get_ports {ddr4_dqs_p[2]}]
set_property PACKAGE_PIN BK35 [get_ports {ddr4_dqs_n[2]}]
set_property PACKAGE_PIN BL35 [get_ports {ddr4_dqs_p[3]}]
set_property PACKAGE_PIN BM35 [get_ports {ddr4_dqs_n[3]}]
set_property PACKAGE_PIN BH47 [get_ports {ddr4_dqs_p[4]}]
set_property PACKAGE_PIN BJ47 [get_ports {ddr4_dqs_n[4]}]
set_property PACKAGE_PIN BM49 [get_ports {ddr4_dqs_p[5]}]
set_property PACKAGE_PIN BM50 [get_ports {ddr4_dqs_n[5]}]
set_property PACKAGE_PIN BF47 [get_ports {ddr4_dqs_p[6]}]
set_property PACKAGE_PIN BF48 [get_ports {ddr4_dqs_n[6]}]
set_property PACKAGE_PIN BH54 [get_ports {ddr4_dqs_p[7]}]
set_property PACKAGE_PIN BJ54 [get_ports {ddr4_dqs_n[7]}]
set_property PACKAGE_PIN BE45 [get_ports {ddr4_dqs_p[8]}]
set_property PACKAGE_PIN BE46 [get_ports {ddr4_dqs_n[8]}]

set_property -dict {PACKAGE_PIN BN22 IOSTANDARD LVCMOS18 PULLUP TRUE} [get_ports ddr4_event_n]
set_property -dict {PACKAGE_PIN BP23 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports ddr4_scl]
set_property -dict {PACKAGE_PIN BP22 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4 IOB TRUE} [get_ports ddr4_sda]













