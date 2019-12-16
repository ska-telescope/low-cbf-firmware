#
# KCU105 RevD XDC
#
#Other net   PACKAGE_PIN Y11      - SYSMON_DXN                Bank   0 - DXN
#Other net   PACKAGE_PIN U12      - SYSMON_VCC                Bank   0 - VCCADC
#Other net   PACKAGE_PIN U11      - SYSMON_AGND               Bank   0 - GNDADC
#Other net   PACKAGE_PIN Y12      - SYSMON_DXP                Bank   0 - DXP
#Other net   PACKAGE_PIN W12      - SYSMON_VREFP              Bank   0 - VREFP
#Other net   PACKAGE_PIN V11      - SYSMON_AGND               Bank   0 - VREFN
#Other net   PACKAGE_PIN V12      - SYSMON_VP_R               Bank   0 - VP
#Other net   PACKAGE_PIN W11      - SYSMON_VN_R               Bank   0 - VN
#Other net   PACKAGE_PIN K7       - 3N5500                    Bank   0 - M0_0
#Other net   PACKAGE_PIN L7       - 3N5497                    Bank   0 - M1_0
#Other net   PACKAGE_PIN V7       - FPGA_INIT_B               Bank   0 - INIT_B_0
#Other net   PACKAGE_PIN M7       - FPGA_M2                   Bank   0 - M2_0
#Other net   PACKAGE_PIN W7       - GND                       Bank   0 - CFGBVS_0
#Other net   PACKAGE_PIN R7       - 3N2787                    Bank   0 - PUDC_B_0
#Other net   PACKAGE_PIN P7       - 3N3559                    Bank   0 - POR_OVERRIDE
#Other net   PACKAGE_PIN N7       - FPGA_DONE                 Bank   0 - DONE_0
#Other net   PACKAGE_PIN T7       - FPGA_PROG_B               Bank   0 - PROGRAM_B_0
#Other net   PACKAGE_PIN U9       - FPGA_TDO_FMC_TDI          Bank   0 - TDO_0
#Other net   PACKAGE_PIN V9       - JTAG_TDI_FPGA_BUF         Bank   0 - TDI_0
#Other net   PACKAGE_PIN U7       - QSPI0_CS_B                Bank   0 - RDWR_FCS_B_0
#Other net   PACKAGE_PIN AA7      - QSPI0_IO2                 Bank   0 - D02_0
#Other net   PACKAGE_PIN AC7      - QSPI0_IO0                 Bank   0 - D00_MOSI_0
#Other net   PACKAGE_PIN Y7       - QSPI0_IO3                 Bank   0 - D03_0
#Other net   PACKAGE_PIN AB7      - QSPI0_IO1                 Bank   0 - D01_DIN_0
#Other net   PACKAGE_PIN W9       - FPGA_TMS_BUF              Bank   0 - TMS_0
#Other net   PACKAGE_PIN AA9      - FPGA_CCLK                 Bank   0 - CCLK_0
#Other net   PACKAGE_PIN AC9      - FPGA_TCK_BUF              Bank   0 - TCK_0
#Other net   PACKAGE_PIN AD7      - FPGA_VBATT                Bank   0 - VBATT

set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]
set_property CONFIG_MODE SPIx8 [current_design]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 8 [current_design]

set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]
set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]

create_clock -period 6.4 [get_ports "SI5328_OUT_C_P"]
create_clock -period 8 [get_ports "CLK_125MHZ_P"]


# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L24P_T3U_N10_44
set_property PACKAGE_PIN AN23      [get_ports "DDR4_DQ25"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ25"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L24N_T3U_N11_44
set_property PACKAGE_PIN AP23      [get_ports "DDR4_DQ27"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ27"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_T3U_N12_44
set_property PACKAGE_PIN AM25     [get_ports "4N6824"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "4N6824"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L23P_T3U_N8_44
set_property PACKAGE_PIN AP24      [get_ports "DDR4_DQ30"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ30"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L23N_T3U_N9_44
set_property PACKAGE_PIN AP25      [get_ports "DDR4_DQ28"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ28"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L22P_T3U_N6_DBC_AD0P_44
set_property PACKAGE_PIN AP20       [get_ports "DDR4_DQS3_T"] 
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_DQS3_T"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L22N_T3U_N7_DBC_AD0N_44
set_property PACKAGE_PIN AP21      [get_ports "DDR4_DQS3_C"] 
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_DQS3_C"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L21P_T3L_N4_AD8P_44
set_property PACKAGE_PIN AM24      [get_ports "DDR4_DQ24"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ24"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L21N_T3L_N5_AD8N_44
set_property PACKAGE_PIN AN24      [get_ports "DDR4_DQ26"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ26"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L20P_T3L_N2_AD1P_44
set_property PACKAGE_PIN AM22      [get_ports "DDR4_DQ31"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ31"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L20N_T3L_N3_AD1N_44
set_property PACKAGE_PIN AN22      [get_ports "DDR4_DQ29"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ29"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L19P_T3L_N0_DBC_AD9P_44
set_property PACKAGE_PIN AM21      [get_ports "DDR4_DM3"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DM3"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L19N_T3L_N1_DBC_AD9N_44
set_property PACKAGE_PIN AN21     [get_ports "PMOD0_1_LS"] 
set_property IOSTANDARD  LVCMOS12 [get_ports "PMOD0_1_LS"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L18P_T2U_N10_AD2P_44
set_property PACKAGE_PIN AL24      [get_ports "DDR4_DQ21"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ21"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L18N_T2U_N11_AD2N_44
set_property PACKAGE_PIN AL25      [get_ports "DDR4_DQ17"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ17"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L17P_T2U_N8_AD10P_44
set_property PACKAGE_PIN AL22      [get_ports "DDR4_DQ16"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ16"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L17N_T2U_N9_AD10N_44
set_property PACKAGE_PIN AL23      [get_ports "DDR4_DQ23"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ23"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L16P_T2U_N6_QBC_AD3P_44
set_property PACKAGE_PIN AJ20      [get_ports "DDR4_DQS2_T"] 
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_DQS2_T"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L16N_T2U_N7_QBC_AD3N_44
set_property PACKAGE_PIN AK20      [get_ports "DDR4_DQS2_C"] 
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_DQS2_C"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L15P_T2L_N4_AD11P_44
set_property PACKAGE_PIN AL20      [get_ports "DDR4_DQ22"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ22"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L15N_T2L_N5_AD11N_44
set_property PACKAGE_PIN AM20      [get_ports "DDR4_DQ18"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ18"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L14P_T2L_N2_GC_44
set_property PACKAGE_PIN AK22      [get_ports "DDR4_DQ20"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ20"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L14N_T2L_N3_GC_44
set_property PACKAGE_PIN AK23      [get_ports "DDR4_DQ19"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ19"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_T2U_N12_44
set_property PACKAGE_PIN AK25      [get_ports "PMOD0_0_LS"] 
set_property IOSTANDARD  LVCMOS12  [get_ports "PMOD0_0_LS"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L13P_T2L_N0_GC_QBC_44
set_property PACKAGE_PIN AJ21      [get_ports "DDR4_DM2"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DM2"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L13N_T2L_N1_GC_QBC_44
set_property PACKAGE_PIN AK21      [get_ports "4N7226"] 
set_property IOSTANDARD  LVCMOSxx  [get_ports "4N7226"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L12P_T1U_N10_GC_44
set_property PACKAGE_PIN AH22      [get_ports "DDR4_DQ14"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ14"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L12N_T1U_N11_GC_44
set_property PACKAGE_PIN AH23      [get_ports "DDR4_DQ12"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ12"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_T1U_N12_VRP_44
set_property PACKAGE_PIN AF25      [get_ports "PMOD0_5_LS"] 
set_property IOSTANDARD  LVCMOS12  [get_ports "PMOD0_5_LS"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L11P_T1U_N8_GC_44
set_property PACKAGE_PIN AJ23      [get_ports "DDR4_DQ10"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ10"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L11N_T1U_N9_GC_44
set_property PACKAGE_PIN AJ24      [get_ports "DDR4_DQ8"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ8"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L10P_T1U_N6_QBC_AD4P_44
set_property PACKAGE_PIN AH24       [get_ports "DDR4_DQS1_T"] 
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_DQS1_T"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L10N_T1U_N7_QBC_AD4N_44
set_property PACKAGE_PIN AJ25       [get_ports "DDR4_DQS1_C"] 
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_DQS1_C"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L9P_T1L_N4_AD12P_44
set_property PACKAGE_PIN AG24      [get_ports "DDR4_DQ9"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ9"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L9N_T1L_N5_AD12N_44
set_property PACKAGE_PIN AG25      [get_ports "DDR4_DQ15"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ15"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L8P_T1L_N2_AD5P_44
set_property PACKAGE_PIN AF23      [get_ports "DDR4_DQ11"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ11"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L8N_T1L_N3_AD5N_44
set_property PACKAGE_PIN AF24      [get_ports "DDR4_DQ13"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ13"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L7P_T1L_N0_QBC_AD13P_44
set_property PACKAGE_PIN AE25      [get_ports "DDR4_DM1"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DM1"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L7N_T1L_N1_QBC_AD13N_44
set_property PACKAGE_PIN AE26      [get_ports "PMOD0_4_LS"] 
set_property IOSTANDARD  LVCMOS12  [get_ports "PMOD0_4_LS"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L6P_T0U_N10_AD6P_44
set_property PACKAGE_PIN AF22      [get_ports "DDR4_DQ2"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ2"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L6N_T0U_N11_AD6N_44
set_property PACKAGE_PIN AG22      [get_ports "DDR4_DQ6"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ6"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L5P_T0U_N8_AD14P_44
set_property PACKAGE_PIN AE22      [get_ports "DDR4_DQ4"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ4"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L5N_T0U_N9_AD14N_44
set_property PACKAGE_PIN AE23      [get_ports "DDR4_DQ0"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ0"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L4P_T0U_N6_DBC_AD7P_44
set_property PACKAGE_PIN AG21       [get_ports "DDR4_DQS0_T"] 
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_DQS0_T"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L4N_T0U_N7_DBC_AD7N_44
set_property PACKAGE_PIN AH21       [get_ports "DDR4_DQS0_C"] 
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_DQS0_C"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L3P_T0L_N4_AD15P_44
set_property PACKAGE_PIN AD20      [get_ports "DDR4_DQ5"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ5"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L3N_T0L_N5_AD15N_44
set_property PACKAGE_PIN AE20      [get_ports "DDR4_DQ7"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ7"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L2P_T0L_N2_44
set_property PACKAGE_PIN AF20      [get_ports "DDR4_DQ3"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ3"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L2N_T0L_N3_44
set_property PACKAGE_PIN AG20      [get_ports "DDR4_DQ1"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ1"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_T0U_N12_44
set_property PACKAGE_PIN AD24      [get_ports "VRP_44"] 
set_property IOSTANDARD  LVCMOSxx  [get_ports "VRP_44"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L1P_T0L_N0_DBC_44
set_property PACKAGE_PIN AD21      [get_ports "DDR4_DM0"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DM0"] 
# Bank  44 VCCO - VCC1V2_FPGA_3A - IO_L1N_T0L_N1_DBC_44
set_property PACKAGE_PIN AE21      [get_ports "PMOD0_6_LS"] 
set_property IOSTANDARD  LVCMOS12  [get_ports "PMOD0_6_LS"] 

#Other net   PACKAGE_PIN AD23     - 4N6160                    Bank  44 - VREF_44

# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L24P_T3U_N10_45
set_property PACKAGE_PIN AD16      [get_ports "DDR4_A14_WE_B"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_A14_WE_B"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L24N_T3U_N11_45
set_property PACKAGE_PIN AD15       [get_ports "DDR4_CKE"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_CKE"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_T3U_N12_45
set_property PACKAGE_PIN AD14      [get_ports "4N6835"] 
set_property IOSTANDARD  LVCMOSxx   [get_ports "4N6835"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L23P_T3U_N8_45
set_property PACKAGE_PIN AE17       [get_ports "DDR4_A0"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_A0"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L23N_T3U_N9_45
set_property PACKAGE_PIN AF17       [get_ports "DDR4_BA0"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_BA0"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L22P_T3U_N6_DBC_AD0P_45
set_property PACKAGE_PIN AE16            [get_ports "DDR4_CK_T"] 
set_property IOSTANDARD  DIFF_SSTL2_DCI  [get_ports "DDR4_CK_T"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L22N_T3U_N7_DBC_AD0N_45
set_property PACKAGE_PIN AE15            [get_ports "DDR4_CK_C"] 
set_property IOSTANDARD  DIFF_SSTL12_DCI [get_ports "DDR4_CK_C"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L21P_T3L_N4_AD8P_45
set_property PACKAGE_PIN AE18       [get_ports "DDR4_A2"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_A2"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L21N_T3L_N5_AD8N_45
set_property PACKAGE_PIN AF18       [get_ports "DDR4_A8"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_A8"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L20P_T3L_N2_AD1P_45
set_property PACKAGE_PIN AF15       [get_ports "DDR4_A10"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_A10"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L20N_T3L_N3_AD1N_45
set_property PACKAGE_PIN AF14       [get_ports "DDR4_A16_RAS_B"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_A16_RAS_B"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L19P_T3L_N0_DBC_AD9P_45
set_property PACKAGE_PIN AD19       [get_ports "DDR4_A11"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_A11"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L19N_T3L_N1_DBC_AD9N_45
set_property PACKAGE_PIN AD18       [get_ports "DDR4_PAR"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_PAR"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L18P_T2U_N10_AD2P_45
set_property PACKAGE_PIN AG15       [get_ports "DDR4_BG0"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_BG0"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L18N_T2U_N11_AD2N_45
set_property PACKAGE_PIN AG14       [get_ports "DDR4_A15_CAS_B"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_A15_CAS_B"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L17P_T2U_N8_AD10P_45
set_property PACKAGE_PIN AG19       [get_ports "DDR4_A13"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_A13"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L17N_T2U_N9_AD10N_45
set_property PACKAGE_PIN AH19       [get_ports "DDR4_A9"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_A9"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L16P_T2U_N6_QBC_AD3P_45
set_property PACKAGE_PIN AJ15       [get_ports "DDR4_A3"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_A3"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L16N_T2U_N7_QBC_AD3N_45
set_property PACKAGE_PIN AJ14       [get_ports "DDR4_A12"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_A12"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L15P_T2L_N4_AD11P_45
set_property PACKAGE_PIN AG17       [get_ports "DDR4_A7"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_A7"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L15N_T2L_N5_AD11N_45
set_property PACKAGE_PIN AG16       [get_ports "DDR4_A4"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_A4"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L14P_T2L_N2_GC_45
set_property PACKAGE_PIN AH16       [get_ports "DDR4_TEN"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_TEN"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L14N_T2L_N3_GC_45
set_property PACKAGE_PIN AJ16       [get_ports "DDR4_ALERT_B"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_ALERT_B"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_T2U_N12_45
set_property PACKAGE_PIN AH14       [get_ports "DDR4_ACT_B"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_ACT_B"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L13P_T2L_N0_GC_QBC_45
set_property PACKAGE_PIN AH18      [get_ports "PMOD0_2_LS"] 
set_property IOSTANDARD  LVCMOS12  [get_ports "PMOD0_2_LS"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L13N_T2L_N1_GC_QBC_45
set_property PACKAGE_PIN AH17       [get_ports "DDR4_A1"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_A1"] 
#
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L12P_T1U_N10_GC_45
set_property PACKAGE_PIN AK17            [get_ports "SYSCLK_300_P"]
set_property IOSTANDARD  DIFF_SSTL12     [get_ports "SYSCLK_300_P"] 
set_property ODT         RTT_48          [get_ports "SYSCLK_300_P"] 
#
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L12N_T1U_N11_GC_45
set_property PACKAGE_PIN AK16            [get_ports "SYSCLK_300_N"] 
set_property IOSTANDARD  DIFF_SSTL12     [get_ports "SYSCLK_300_N"] 
set_property ODT         RTT_48          [get_ports "SYSCLK_300_N"]
#
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_T1U_N12_VRP_45
set_property PACKAGE_PIN AJ19      [get_ports "4N8047"] 
set_property IOSTANDARD  LVCMOSxx  [get_ports "4N8047"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L11P_T1U_N8_GC_45
set_property PACKAGE_PIN AJ18       [get_ports "DDR4_ODT"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_ODT"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L11N_T1U_N9_GC_45
set_property PACKAGE_PIN AK18       [get_ports "DDR4_A6"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_A6"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L10P_T1U_N6_QBC_AD4P_45
set_property PACKAGE_PIN AL18      [get_ports "DDR4_RESET_B"] 
set_property IOSTANDARD  LVCMOS12  [get_ports "DDR4_RESET_B"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L10N_T1U_N7_QBC_AD4N_45
set_property PACKAGE_PIN AL17       [get_ports "DDR4_A5"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_A5"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L9P_T1L_N4_AD12P_45
set_property PACKAGE_PIN AK15      [get_ports "4N6914"] 
set_property IOSTANDARD  LVCMOSxx  [get_ports "4N6914"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L9N_T1L_N5_AD12N_45
set_property PACKAGE_PIN AL15       [get_ports "DDR4_BA1"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_BA1"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L8P_T1L_N2_AD5P_45
set_property PACKAGE_PIN AL19       [get_ports "DDR4_CS_B"] 
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_CS_B"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L8N_T1L_N3_AD5N_45
set_property PACKAGE_PIN AM19      [get_ports "PMOD0_3_LS"] 
set_property IOSTANDARD  LVCMOS12  [get_ports "PMOD0_3_LS"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L7P_T1L_N0_QBC_AD13P_45
set_property PACKAGE_PIN AL14      [get_ports "PMOD1_0_LS"] 
set_property IOSTANDARD  LVCMOS12  [get_ports "PMOD1_0_LS"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L7N_T1L_N1_QBC_AD13N_45
set_property PACKAGE_PIN AM14      [get_ports "PMOD1_1_LS"] 
set_property IOSTANDARD  LVCMOS12  [get_ports "PMOD1_1_LS"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L6P_T0U_N10_AD6P_45
set_property PACKAGE_PIN AP16      [get_ports "PMOD1_2_LS"] 
set_property IOSTANDARD  LVCMOS12  [get_ports "PMOD1_2_LS"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L6N_T0U_N11_AD6N_45
set_property PACKAGE_PIN AP15      [get_ports "PMOD1_3_LS"] 
set_property IOSTANDARD  LVCMOS12  [get_ports "PMOD1_3_LS"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L5P_T0U_N8_AD14P_45
set_property PACKAGE_PIN AM16      [get_ports "PMOD1_4_LS"] 
set_property IOSTANDARD  LVCMOS12  [get_ports "PMOD1_4_LS"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L5N_T0U_N9_AD14N_45
set_property PACKAGE_PIN AM15      [get_ports "PMOD1_5_LS"] 
set_property IOSTANDARD  LVCMOS12  [get_ports "PMOD1_5_LS"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L4P_T0U_N6_DBC_AD7P_45
set_property PACKAGE_PIN AN18      [get_ports "PMOD1_6_LS"] 
set_property IOSTANDARD  LVCMOS12  [get_ports "PMOD1_6_LS"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L4N_T0U_N7_DBC_AD7N_45
set_property PACKAGE_PIN AN17      [get_ports "PMOD1_7_LS"] 
set_property IOSTANDARD  LVCMOS12  [get_ports "PMOD1_7_LS"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L3P_T0L_N4_AD15P_45
set_property PACKAGE_PIN AM17      [get_ports "PMOD0_7_LS"] 
set_property IOSTANDARD  LVCMOS12  [get_ports "PMOD0_7_LS"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L3N_T0L_N5_AD15N_45
set_property PACKAGE_PIN AN16      [get_ports "GPIO_DIP_SW0"] 
set_property IOSTANDARD  LVCMOS12  [get_ports "GPIO_DIP_SW0"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L2P_T0L_N2_45
set_property PACKAGE_PIN AN19      [get_ports "GPIO_DIP_SW1"] 
set_property IOSTANDARD  LVCMOS12  [get_ports "GPIO_DIP_SW1"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L2N_T0L_N3_45
set_property PACKAGE_PIN AP18      [get_ports "GPIO_DIP_SW2"] 
set_property IOSTANDARD  LVCMOS12  [get_ports "GPIO_DIP_SW2"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_T0U_N12_45
set_property PACKAGE_PIN AP19      [get_ports "VRP_45"] 
set_property IOSTANDARD  LVCMOSxx  [get_ports "VRP_45"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L1P_T0L_N0_DBC_45
set_property PACKAGE_PIN AN14      [get_ports "GPIO_DIP_SW3"] 
set_property IOSTANDARD  LVCMOS12  [get_ports "GPIO_DIP_SW3"] 
# Bank  45 VCCO - VCC1V2_FPGA_3A - IO_L1N_T0L_N1_DBC_45
set_property PACKAGE_PIN AP14      [get_ports "4N7200"] 
set_property IOSTANDARD  LVCMOSxx  [get_ports "4N7200"] 

#Other net   PACKAGE_PIN AF19     - 4N6273                    Bank  45 - VREF_45

# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L24P_T3U_N10_46
set_property PACKAGE_PIN AL34      [get_ports "DDR4_DQ62"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ62"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L24N_T3U_N11_46
set_property PACKAGE_PIN AM34      [get_ports "DDR4_DQ58"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ58"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_T3U_N12_46
set_property PACKAGE_PIN AK33      [get_ports "46N3480"] 
set_property IOSTANDARD  LVCMOSxx  [get_ports "46N3480"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L23P_T3U_N8_46
set_property PACKAGE_PIN AM32      [get_ports "DDR4_DQ60"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ60"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L23N_T3U_N9_46
set_property PACKAGE_PIN AN32      [get_ports "DDR4_DQ63"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ63"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L22P_T3U_N6_DBC_AD0P_46
set_property PACKAGE_PIN AN34      [get_ports "DDR4_DQS7_T"] 
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_DQS7_T"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L22N_T3U_N7_DBC_AD0N_46
set_property PACKAGE_PIN AP34       [get_ports "DDR4_DQS7_C"] 
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_DQS7_C"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L21P_T3L_N4_AD8P_46
set_property PACKAGE_PIN AN31      [get_ports "DDR4_DQ61"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ61"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L21N_T3L_N5_AD8N_46
set_property PACKAGE_PIN AP31      [get_ports "DDR4_DQ59"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ59"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L20P_T3L_N2_AD1P_46
set_property PACKAGE_PIN AN33      [get_ports "DDR4_DQ56"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ56"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L20N_T3L_N3_AD1N_46
set_property PACKAGE_PIN AP33      [get_ports "DDR4_DQ57"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ57"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L19P_T3L_N0_DBC_AD9P_46
set_property PACKAGE_PIN AL32      [get_ports "DDR4_DM7"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DM7"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L19N_T3L_N1_DBC_AD9N_46
set_property PACKAGE_PIN AL33      [get_ports "46N3671"] 
set_property IOSTANDARD  LVCMOSxx  [get_ports "46N3671"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L18P_T2U_N10_AD2P_46
set_property PACKAGE_PIN AH34      [get_ports "DDR4_DQ54"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ54"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L18N_T2U_N11_AD2N_46
set_property PACKAGE_PIN AJ34      [get_ports "DDR4_DQ50"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ50"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L17P_T2U_N8_AD10P_46
set_property PACKAGE_PIN AH31      [get_ports "DDR4_DQ48"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ48"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L17N_T2U_N9_AD10N_46
set_property PACKAGE_PIN AH32      [get_ports "DDR4_DQ49"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ49"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L16P_T2U_N6_QBC_AD3P_46
set_property PACKAGE_PIN AH33       [get_ports "DDR4_DQS6_T"] 
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_DQS6_T"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L16N_T2U_N7_QBC_AD3N_46
set_property PACKAGE_PIN AJ33       [get_ports "DDR4_DQS6_C"] 
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_DQS6_C"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L15P_T2L_N4_AD11P_46
set_property PACKAGE_PIN AJ30      [get_ports "DDR4_DQ53"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ53"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L15N_T2L_N5_AD11N_46
set_property PACKAGE_PIN AJ31      [get_ports "DDR4_DQ52"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ52"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L14P_T2L_N2_GC_46
set_property PACKAGE_PIN AK31      [get_ports "DDR4_DQ51"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ51"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L14N_T2L_N3_GC_46
set_property PACKAGE_PIN AK32      [get_ports "DDR4_DQ55"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ55"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_T2U_N12_46
set_property PACKAGE_PIN AH29      [get_ports "46N4260"] 
set_property IOSTANDARD  LVCMOSxx  [get_ports "46N4260"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L13P_T2L_N0_GC_QBC_46
set_property PACKAGE_PIN AJ29      [get_ports "DDR4_DM6"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DM6"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L13N_T2L_N1_GC_QBC_46
set_property PACKAGE_PIN AK30      [get_ports "46N3668"] 
set_property IOSTANDARD  LVCMOSxx  [get_ports "46N3668"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L12P_T1U_N10_GC_46
set_property PACKAGE_PIN AL30      [get_ports "DDR4_DQ40"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ40"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L12N_T1U_N11_GC_46
set_property PACKAGE_PIN AM30      [get_ports "DDR4_DQ42"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ42"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_T1U_N12_VRP_46
set_property PACKAGE_PIN AM31      [get_ports "46N4257"] 
set_property IOSTANDARD  LVCMOSxx  [get_ports "46N4257"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L11P_T1U_N8_GC_46
set_property PACKAGE_PIN AL29      [get_ports "DDR4_DQ44"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ44"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L11N_T1U_N9_GC_46
set_property PACKAGE_PIN AM29      [get_ports "DDR4_DQ46"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ46"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L10P_T1U_N6_QBC_AD4P_46
set_property PACKAGE_PIN AN29       [get_ports "DDR4_DQS5_T"] 
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_DQS5_T"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L10N_T1U_N7_QBC_AD4N_46
set_property PACKAGE_PIN AP30       [get_ports "DDR4_DQS5_C"] 
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_DQS5_C"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L9P_T1L_N4_AD12P_46
set_property PACKAGE_PIN AN27      [get_ports "DDR4_DQ47"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ47"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L9N_T1L_N5_AD12N_46
set_property PACKAGE_PIN AN28      [get_ports "DDR4_DQ43"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ43"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L8P_T1L_N2_AD5P_46
set_property PACKAGE_PIN AP28      [get_ports "DDR4_DQ45"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ45"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L8N_T1L_N3_AD5N_46
set_property PACKAGE_PIN AP29      [get_ports "DDR4_DQ41"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ41"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L7P_T1L_N0_QBC_AD13P_46
set_property PACKAGE_PIN AN26      [get_ports "DDR4_DM5"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DM5"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L7N_T1L_N1_QBC_AD13N_46
set_property PACKAGE_PIN AP26      [get_ports "46N3665"] 
set_property IOSTANDARD  LVCMOSxx  [get_ports "46N3665"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L6P_T0U_N10_AD6P_46
set_property PACKAGE_PIN AJ28      [get_ports "DDR4_DQ36"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ36"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L6N_T0U_N11_AD6N_46
set_property PACKAGE_PIN AK28      [get_ports "DDR4_DQ34"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ34"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L5P_T0U_N8_AD14P_46
set_property PACKAGE_PIN AH27      [get_ports "DDR4_DQ37"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ37"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L5N_T0U_N9_AD14N_46
set_property PACKAGE_PIN AH28      [get_ports "DDR4_DQ32"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ32"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L4P_T0U_N6_DBC_AD7P_46
set_property PACKAGE_PIN AL27       [get_ports "DDR4_DQS4_T"] 
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_DQS4_T"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L4N_T0U_N7_DBC_AD7N_46
set_property PACKAGE_PIN AL28       [get_ports "DDR4_DQS4_C"] 
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_DQS4_C"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L3P_T0L_N4_AD15P_46
set_property PACKAGE_PIN AK26      [get_ports "DDR4_DQ33"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ33"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L3N_T0L_N5_AD15N_46
set_property PACKAGE_PIN AK27      [get_ports "DDR4_DQ38"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ38"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L2P_T0L_N2_46
set_property PACKAGE_PIN AM26      [get_ports "DDR4_DQ39"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ39"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L2N_T0L_N3_46
set_property PACKAGE_PIN AM27      [get_ports "DDR4_DQ35"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DQ35"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_T0U_N12_46
set_property PACKAGE_PIN AG26      [get_ports "VRP_46"] 
set_property IOSTANDARD  LVCMOSxx  [get_ports "VRP_46"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L1P_T0L_N0_DBC_46
set_property PACKAGE_PIN AH26      [get_ports "DDR4_DM4"] 
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_DM4"] 
# Bank  46 VCCO - VCC1V2_FPGA_3A - IO_L1N_T0L_N1_DBC_46
set_property PACKAGE_PIN AJ26      [get_ports "46N3735"] 
set_property IOSTANDARD  LVCMOSxx  [get_ports "46N3735"] 

#Other net   PACKAGE_PIN AG27     - 46N3019                   Bank  46 - VREF_46

# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L24P_T3U_N10_47
set_property PACKAGE_PIN V26      [get_ports "FMC_LPC_LA09_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA09_P"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L24N_T3U_N11_47
set_property PACKAGE_PIN W26      [get_ports "FMC_LPC_LA09_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA09_N"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_T3U_N12_47
set_property PACKAGE_PIN U29      [get_ports "5N3695"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N3695"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L23P_T3U_N8_47
set_property PACKAGE_PIN V29      [get_ports "FMC_LPC_LA06_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA06_P"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L23N_T3U_N9_47
set_property PACKAGE_PIN W29      [get_ports "FMC_LPC_LA06_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA06_N"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L22P_T3U_N6_DBC_AD0P_47
set_property PACKAGE_PIN U26      [get_ports "FMC_LPC_LA04_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA04_P"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L22N_T3U_N7_DBC_AD0N_47
set_property PACKAGE_PIN U27      [get_ports "FMC_LPC_LA04_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA04_N"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L21P_T3L_N4_AD8P_47
set_property PACKAGE_PIN W28      [get_ports "FMC_LPC_LA03_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA03_P"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L21N_T3L_N5_AD8N_47
set_property PACKAGE_PIN Y28      [get_ports "FMC_LPC_LA03_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA03_N"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L20P_T3L_N2_AD1P_47
set_property PACKAGE_PIN U24      [get_ports "FMC_LPC_LA08_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA08_P"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L20N_T3L_N3_AD1N_47
set_property PACKAGE_PIN U25      [get_ports "FMC_LPC_LA08_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA08_N"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L19P_T3L_N0_DBC_AD9P_47
set_property PACKAGE_PIN V27      [get_ports "FMC_LPC_LA05_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA05_P"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L19N_T3L_N1_DBC_AD9N_47
set_property PACKAGE_PIN V28      [get_ports "FMC_LPC_LA05_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA05_N"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L18P_T2U_N10_AD2P_47
set_property PACKAGE_PIN V21      [get_ports "FMC_LPC_LA11_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA11_P"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L18N_T2U_N11_AD2N_47
set_property PACKAGE_PIN W21      [get_ports "FMC_LPC_LA11_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA11_N"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L17P_T2U_N8_AD10P_47
set_property PACKAGE_PIN T22      [get_ports "FMC_LPC_LA10_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA10_P"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L17N_T2U_N9_AD10N_47
set_property PACKAGE_PIN T23      [get_ports "FMC_LPC_LA10_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA10_N"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L16P_T2U_N6_QBC_AD3P_47
set_property PACKAGE_PIN V22      [get_ports "FMC_LPC_LA07_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA07_P"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L16N_T2U_N7_QBC_AD3N_47
set_property PACKAGE_PIN V23      [get_ports "FMC_LPC_LA07_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA07_N"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L15P_T2L_N4_AD11P_47
set_property PACKAGE_PIN U21      [get_ports "FMC_LPC_LA14_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA14_P"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L15N_T2L_N5_AD11N_47
set_property PACKAGE_PIN U22      [get_ports "FMC_LPC_LA14_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA14_N"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L14P_T2L_N2_GC_47
set_property PACKAGE_PIN W25      [get_ports "FMC_LPC_LA01_CC_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA01_CC_P"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L14N_T2L_N3_GC_47
set_property PACKAGE_PIN Y25      [get_ports "FMC_LPC_LA01_CC_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA01_CC_N"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_T2U_N12_47
set_property PACKAGE_PIN Y21      [get_ports "ROTARY_INCA"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "ROTARY_INCA"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L13P_T2L_N0_GC_QBC_47
set_property PACKAGE_PIN W23      [get_ports "FMC_LPC_LA00_CC_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA00_CC_P"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L13N_T2L_N1_GC_QBC_47
set_property PACKAGE_PIN W24      [get_ports "FMC_LPC_LA00_CC_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA00_CC_N"] 
#
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L12P_T1U_N10_GC_47
set_property PACKAGE_PIN AA24     [get_ports "FMC_LPC_CLK0_M2C_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_CLK0_M2C_P"] 
set_property DIFF_TERM   TRUE     [get_ports "FMC_LPC_CLK0_M2C_P"] 
#
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L12N_T1U_N11_GC_47
set_property PACKAGE_PIN AA25     [get_ports "FMC_LPC_CLK0_M2C_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_CLK0_M2C_N"] 
set_property DIFF_TERM   TRUE     [get_ports "FMC_LPC_CLK0_M2C_N"] 
#
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_T1U_N12_VRP_47
set_property PACKAGE_PIN Y22      [get_ports "5N5033"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N5033"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L11P_T1U_N8_GC_47
set_property PACKAGE_PIN Y23      [get_ports "5N4122"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N4122"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L11N_T1U_N9_GC_47
set_property PACKAGE_PIN AA23     [get_ports "5N4120"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N4120"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L10P_T1U_N6_QBC_AD4P_47
set_property PACKAGE_PIN AB21     [get_ports "FMC_LPC_LA16_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA16_P"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L10N_T1U_N7_QBC_AD4N_47
set_property PACKAGE_PIN AC21     [get_ports "FMC_LPC_LA16_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA16_N"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L9P_T1L_N4_AD12P_47
set_property PACKAGE_PIN AA20     [get_ports "FMC_LPC_LA13_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA13_P"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L9N_T1L_N5_AD12N_47
set_property PACKAGE_PIN AB20     [get_ports "FMC_LPC_LA13_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA13_N"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L8P_T1L_N2_AD5P_47
set_property PACKAGE_PIN AC22     [get_ports "FMC_LPC_LA12_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA12_P"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L8N_T1L_N3_AD5N_47
set_property PACKAGE_PIN AC23     [get_ports "FMC_LPC_LA12_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA12_N"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L7P_T1L_N0_QBC_AD13P_47
set_property PACKAGE_PIN AA22     [get_ports "FMC_LPC_LA02_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA02_P"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L7N_T1L_N1_QBC_AD13N_47
set_property PACKAGE_PIN AB22     [get_ports "FMC_LPC_LA02_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA02_N"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L6P_T0U_N10_AD6P_47
set_property PACKAGE_PIN AB25     [get_ports "FMC_LPC_LA15_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA15_P"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L6N_T0U_N11_AD6N_47
set_property PACKAGE_PIN AB26     [get_ports "FMC_LPC_LA15_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA15_N"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L5P_T0U_N8_AD14P_47
set_property PACKAGE_PIN AA27     [get_ports "5N4116"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N4116"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L5N_T0U_N9_AD14N_47
set_property PACKAGE_PIN AB27     [get_ports "5N4114"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N4114"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L4P_T0U_N6_DBC_AD7P_47
set_property PACKAGE_PIN AC26     [get_ports "5N4109"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N4109"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L4N_T0U_N7_DBC_AD7N_47
set_property PACKAGE_PIN AC27     [get_ports "5N4107"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N4107"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L3P_T0L_N4_AD15P_47
set_property PACKAGE_PIN AB24     [get_ports "5N4105"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N4105"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L3N_T0L_N5_AD15N_47
set_property PACKAGE_PIN AC24     [get_ports "5N4100"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N4100"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L2P_T0L_N2_47
set_property PACKAGE_PIN AD25     [get_ports "5N4098"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N4098"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L2N_T0L_N3_47
set_property PACKAGE_PIN AD26     [get_ports "ROTARY_INCB"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "ROTARY_INCB"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_T0U_N12_47
set_property PACKAGE_PIN AA28     [get_ports "VRP_47"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "VRP_47"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L1P_T0L_N0_DBC_47
set_property PACKAGE_PIN Y26      [get_ports "5N4093"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N4093"] 
# Bank  47 VCCO - VADJ_1V8_FPGA_10A - IO_L1N_T0L_N1_DBC_47
set_property PACKAGE_PIN Y27      [get_ports "5N4090"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N4090"] 

#Other net   PACKAGE_PIN V24      - 5N4336                    Bank  47 - VREF_47

# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L24P_T3U_N10_48
set_property PACKAGE_PIN V31      [get_ports "FMC_LPC_LA28_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA28_P"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L24N_T3U_N11_48
set_property PACKAGE_PIN W31      [get_ports "FMC_LPC_LA28_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA28_N"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_T3U_N12_48
set_property PACKAGE_PIN V32      [get_ports "5N3527"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N3527"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L23P_T3U_N8_48
set_property PACKAGE_PIN U34      [get_ports "FMC_LPC_LA29_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA29_P"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L23N_T3U_N9_48
set_property PACKAGE_PIN V34      [get_ports "FMC_LPC_LA29_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA29_N"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L22P_T3U_N6_DBC_AD0P_48
set_property PACKAGE_PIN Y31      [get_ports "FMC_LPC_LA30_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA30_P"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L22N_T3U_N7_DBC_AD0N_48
set_property PACKAGE_PIN Y32      [get_ports "FMC_LPC_LA30_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA30_N"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L21P_T3L_N4_AD8P_48
set_property PACKAGE_PIN V33      [get_ports "FMC_LPC_LA31_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA31_P"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L21N_T3L_N5_AD8N_48
set_property PACKAGE_PIN W34      [get_ports "FMC_LPC_LA31_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA31_N"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L20P_T3L_N2_AD1P_48
set_property PACKAGE_PIN W30      [get_ports "FMC_LPC_LA32_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA32_P"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L20N_T3L_N3_AD1N_48
set_property PACKAGE_PIN Y30      [get_ports "FMC_LPC_LA32_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA32_N"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L19P_T3L_N0_DBC_AD9P_48
set_property PACKAGE_PIN W33      [get_ports "FMC_LPC_LA33_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA33_P"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L19N_T3L_N1_DBC_AD9N_48
set_property PACKAGE_PIN Y33      [get_ports "FMC_LPC_LA33_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA33_N"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L18P_T2U_N10_AD2P_48
set_property PACKAGE_PIN AC33     [get_ports "FMC_LPC_LA21_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA21_P"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L18N_T2U_N11_AD2N_48
set_property PACKAGE_PIN AD33     [get_ports "FMC_LPC_LA21_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA21_N"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L17P_T2U_N8_AD10P_48
set_property PACKAGE_PIN AA34     [get_ports "FMC_LPC_LA20_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA20_P"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L17N_T2U_N9_AD10N_48
set_property PACKAGE_PIN AB34     [get_ports "FMC_LPC_LA20_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA20_N"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L16P_T2U_N6_QBC_AD3P_48
set_property PACKAGE_PIN AA29     [get_ports "FMC_LPC_LA19_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA19_P"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L16N_T2U_N7_QBC_AD3N_48
set_property PACKAGE_PIN AB29     [get_ports "FMC_LPC_LA19_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA19_N"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L15P_T2L_N4_AD11P_48
set_property PACKAGE_PIN AC34     [get_ports "FMC_LPC_LA22_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA22_P"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L15N_T2L_N5_AD11N_48
set_property PACKAGE_PIN AD34     [get_ports "FMC_LPC_LA22_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA22_N"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L14P_T2L_N2_GC_48
set_property PACKAGE_PIN AB30     [get_ports "FMC_LPC_LA18_CC_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA18_CC_P"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L14N_T2L_N3_GC_48
set_property PACKAGE_PIN AB31     [get_ports "FMC_LPC_LA18_CC_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA18_CC_N"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_T2U_N12_48
set_property PACKAGE_PIN AA33     [get_ports "5N5055"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N5055"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L13P_T2L_N0_GC_QBC_48
set_property PACKAGE_PIN AA32     [get_ports "FMC_LPC_LA17_CC_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA17_CC_P"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L13N_T2L_N1_GC_QBC_48
set_property PACKAGE_PIN AB32     [get_ports "FMC_LPC_LA17_CC_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA17_CC_N"] 
#
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L12P_T1U_N10_GC_48
set_property PACKAGE_PIN AC31     [get_ports "FMC_LPC_CLK1_M2C_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_CLK1_M2C_P"] 
set_property DIFF_TERM   TRUE     [get_ports "FMC_LPC_CLK1_M2C_P"] 
#
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L12N_T1U_N11_GC_48
set_property PACKAGE_PIN AC32     [get_ports "FMC_LPC_CLK1_M2C_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_CLK1_M2C_N"] 
set_property DIFF_TERM   TRUE     [get_ports "FMC_LPC_CLK1_M2C_N"] 
#
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_T1U_N12_VRP_48
set_property PACKAGE_PIN AE31     [get_ports "5N5047"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N5047"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L11P_T1U_N8_GC_48
set_property PACKAGE_PIN AD30     [get_ports "FMC_LPC_LA23_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA23_P"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L11N_T1U_N9_GC_48
set_property PACKAGE_PIN AD31     [get_ports "FMC_LPC_LA23_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA23_N"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L10P_T1U_N6_QBC_AD4P_48
set_property PACKAGE_PIN AE33     [get_ports "FMC_LPC_LA25_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA25_P"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L10N_T1U_N7_QBC_AD4N_48
set_property PACKAGE_PIN AF34     [get_ports "FMC_LPC_LA25_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA25_N"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L9P_T1L_N4_AD12P_48
set_property PACKAGE_PIN AE32     [get_ports "FMC_LPC_LA24_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA24_P"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L9N_T1L_N5_AD12N_48
set_property PACKAGE_PIN AF32     [get_ports "FMC_LPC_LA24_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA24_N"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L8P_T1L_N2_AD5P_48
set_property PACKAGE_PIN AF33     [get_ports "FMC_LPC_LA26_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA26_P"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L8N_T1L_N3_AD5N_48
set_property PACKAGE_PIN AG34     [get_ports "FMC_LPC_LA26_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA26_N"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L7P_T1L_N0_QBC_AD13P_48
set_property PACKAGE_PIN AG31     [get_ports "FMC_LPC_LA27_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA27_P"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L7N_T1L_N1_QBC_AD13N_48
set_property PACKAGE_PIN AG32     [get_ports "FMC_LPC_LA27_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_LPC_LA27_N"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L6P_T0U_N10_AD6P_48
set_property PACKAGE_PIN AF30     [get_ports "5N4159"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N4159"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L6N_T0U_N11_AD6N_48
set_property PACKAGE_PIN AG30     [get_ports "5N4148"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N4148"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L5P_T0U_N8_AD14P_48
set_property PACKAGE_PIN AD29     [get_ports "5N4146"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N4146"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L5N_T0U_N9_AD14N_48
set_property PACKAGE_PIN AE30     [get_ports "5N4144"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N4144"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L4P_T0U_N6_DBC_AD7P_48
set_property PACKAGE_PIN AF29     [get_ports "5N4139"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N4139"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L4N_T0U_N7_DBC_AD7N_48
set_property PACKAGE_PIN AG29     [get_ports "5N4137"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N4137"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L3P_T0L_N4_AD15P_48
set_property PACKAGE_PIN AC28     [get_ports "5N4135"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N4135"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L3N_T0L_N5_AD15N_48
set_property PACKAGE_PIN AD28     [get_ports "5N4130"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N4130"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L2P_T0L_N2_48
set_property PACKAGE_PIN AE28     [get_ports "5N4128"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N4128"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L2N_T0L_N3_48
set_property PACKAGE_PIN AF28     [get_ports "ROTARY_PUSH"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "ROTARY_PUSH"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_T0U_N12_48
set_property PACKAGE_PIN AC29     [get_ports "VRP_48"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "VRP_48"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L1P_T0L_N0_DBC_48
set_property PACKAGE_PIN AE27     [get_ports "5N4156"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N4156"] 
# Bank  48 VCCO - VADJ_1V8_FPGA_10A - IO_L1N_T0L_N1_DBC_48
set_property PACKAGE_PIN AF27     [get_ports "5N4153"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "5N4153"] 

#Other net   PACKAGE_PIN AA30     - 5N4450                    Bank  48 - VREF_48

# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L24P_T3U_N10_66
set_property PACKAGE_PIN D13      [get_ports "FMC_HPC_LA06_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA06_P"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L24N_T3U_N11_66
set_property PACKAGE_PIN C13      [get_ports "FMC_HPC_LA06_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA06_N"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_T3U_N12_66
set_property PACKAGE_PIN E12      [get_ports "7N4392"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "7N4392"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L23P_T3U_N8_66
set_property PACKAGE_PIN A13      [get_ports "FMC_HPC_LA03_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA03_P"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L23N_T3U_N9_66
set_property PACKAGE_PIN A12      [get_ports "FMC_HPC_LA03_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA03_N"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L22P_T3U_N6_DBC_AD0P_66
set_property PACKAGE_PIN F13      [get_ports "SYSMON_AD0_R_P"] 
set_property IOSTANDARD  ANALOG   [get_ports "SYSMON_AD0_R_P"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L22N_T3U_N7_DBC_AD0N_66
set_property PACKAGE_PIN E13      [get_ports "SYSMON_AD0_R_N"] 
set_property IOSTANDARD  ANALOG   [get_ports "SYSMON_AD0_R_N"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L21P_T3L_N4_AD8P_66
set_property PACKAGE_PIN C11      [get_ports "SYSMON_AD8_R_P"] 
set_property IOSTANDARD  ANALOG   [get_ports "SYSMON_AD8_R_P"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L21N_T3L_N5_AD8N_66
set_property PACKAGE_PIN B11      [get_ports "SYSMON_AD8_R_N"] 
set_property IOSTANDARD  ANALOG   [get_ports "SYSMON_AD8_R_N"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L20P_T3L_N2_AD1P_66
set_property PACKAGE_PIN C12      [get_ports "7N6232"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "7N6232"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L20N_T3L_N3_AD1N_66
set_property PACKAGE_PIN B12      [get_ports "7N6230"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "7N6230"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L19P_T3L_N0_DBC_AD9P_66
set_property PACKAGE_PIN E11      [get_ports "7N6227"] 
set_property IOSTANDARD  LVCMOS12 [get_ports "7N6227"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L19N_T3L_N1_DBC_AD9N_66
set_property PACKAGE_PIN D11      [get_ports "7N6224"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "7N6224"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L18P_T2U_N10_AD2P_66
set_property PACKAGE_PIN J13      [get_ports "SYSMON_AD2_R_P"] 
set_property IOSTANDARD  ANALOG   [get_ports "SYSMON_AD2_R_P"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L18N_T2U_N11_AD2N_66
set_property PACKAGE_PIN H13      [get_ports "SYSMON_AD2_R_N"] 
set_property IOSTANDARD  ANALOG   [get_ports "SYSMON_AD2_R_N"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L17P_T2U_N8_AD10P_66
set_property PACKAGE_PIN L12      [get_ports "FMC_HPC_LA04_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA04_P"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L17N_T2U_N9_AD10N_66
set_property PACKAGE_PIN K12      [get_ports "FMC_HPC_LA04_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA04_N"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L16P_T2U_N6_QBC_AD3P_66
set_property PACKAGE_PIN L13      [get_ports "FMC_HPC_LA05_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA05_P"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L16N_T2U_N7_QBC_AD3N_66
set_property PACKAGE_PIN K13      [get_ports "FMC_HPC_LA05_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA05_N"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L15P_T2L_N4_AD11P_66
set_property PACKAGE_PIN K11      [get_ports "FMC_HPC_LA11_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA11_P"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L15N_T2L_N5_AD11N_66
set_property PACKAGE_PIN J11      [get_ports "FMC_HPC_LA11_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA11_N"] 
#
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L14P_T2L_N2_GC_66
set_property PACKAGE_PIN H12      [get_ports "FMC_HPC_CLK0_M2C_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_CLK0_M2C_P"]
set_property DIFF_TERM   TRUE     [get_ports "FMC_HPC_CLK0_M2C_P"]
# 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L14N_T2L_N3_GC_66
set_property PACKAGE_PIN G12      [get_ports "FMC_HPC_CLK0_M2C_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_CLK0_M2C_N"] 
set_property DIFF_TERM   TRUE     [get_ports "FMC_HPC_CLK0_M2C_N"]
#
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_T2U_N12_66
set_property PACKAGE_PIN F12      [get_ports "SI570_CLK_SEL_LS"] 
set_property IOSTANDARD  LVCMOS18     [get_ports "SI570_CLK_SEL_LS"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L13P_T2L_N0_GC_QBC_66
set_property PACKAGE_PIN H11      [get_ports "FMC_HPC_LA00_CC_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA00_CC_P"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L13N_T2L_N1_GC_QBC_66
set_property PACKAGE_PIN G11      [get_ports "FMC_HPC_LA00_CC_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA00_CC_N"] 
#
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L12P_T1U_N10_GC_66
set_property PACKAGE_PIN G10      [get_ports "CLK_125MHZ_P"] 
set_property IOSTANDARD  LVDS     [get_ports "CLK_125MHZ_P"] 
#
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L12N_T1U_N11_GC_66
set_property PACKAGE_PIN F10      [get_ports "CLK_125MHZ_N"] 
set_property IOSTANDARD  LVDS     [get_ports "CLK_125MHZ_N"]
#
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_T1U_N12_VRP_66
set_property PACKAGE_PIN L9       [get_ports "7N6175"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "7N6175"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L11P_T1U_N8_GC_66
set_property PACKAGE_PIN G9       [get_ports "FMC_HPC_LA01_CC_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA01_CC_P"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L11N_T1U_N9_GC_66
set_property PACKAGE_PIN F9       [get_ports "FMC_HPC_LA01_CC_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA01_CC_N"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L10P_T1U_N6_QBC_AD4P_66
set_property PACKAGE_PIN K10      [get_ports "FMC_HPC_LA02_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA02_P"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L10N_T1U_N7_QBC_AD4N_66
set_property PACKAGE_PIN J10      [get_ports "FMC_HPC_LA02_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA02_N"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L9P_T1L_N4_AD12P_66
set_property PACKAGE_PIN J8       [get_ports "FMC_HPC_LA08_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA08_P"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L9N_T1L_N5_AD12N_66
set_property PACKAGE_PIN H8       [get_ports "FMC_HPC_LA08_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA08_N"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L8P_T1L_N2_AD5P_66
set_property PACKAGE_PIN J9       [get_ports "FMC_HPC_LA09_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA09_P"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L8N_T1L_N3_AD5N_66
set_property PACKAGE_PIN H9       [get_ports "FMC_HPC_LA09_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA09_N"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L7P_T1L_N0_QBC_AD13P_66
set_property PACKAGE_PIN L8       [get_ports "FMC_HPC_LA10_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA10_P"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L7N_T1L_N1_QBC_AD13N_66
set_property PACKAGE_PIN K8       [get_ports "FMC_HPC_LA10_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA10_N"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L6P_T0U_N10_AD6P_66
set_property PACKAGE_PIN E10      [get_ports "FMC_HPC_LA12_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA12_P"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L6N_T0U_N11_AD6N_66
set_property PACKAGE_PIN D10      [get_ports "FMC_HPC_LA12_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA12_N"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L5P_T0U_N8_AD14P_66
set_property PACKAGE_PIN D9       [get_ports "FMC_HPC_LA13_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA13_P"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L5N_T0U_N9_AD14N_66
set_property PACKAGE_PIN C9       [get_ports "FMC_HPC_LA13_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA13_N"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L4P_T0U_N6_DBC_AD7P_66
set_property PACKAGE_PIN B10      [get_ports "FMC_HPC_LA14_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA14_P"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L4N_T0U_N7_DBC_AD7N_66
set_property PACKAGE_PIN A10      [get_ports "FMC_HPC_LA14_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA14_N"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L3P_T0L_N4_AD15P_66
set_property PACKAGE_PIN D8       [get_ports "FMC_HPC_LA15_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA15_P"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L3N_T0L_N5_AD15N_66
set_property PACKAGE_PIN C8       [get_ports "FMC_HPC_LA15_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA15_N"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L2P_T0L_N2_66
set_property PACKAGE_PIN B9       [get_ports "FMC_HPC_LA16_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA16_P"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L2N_T0L_N3_66
set_property PACKAGE_PIN A9       [get_ports "FMC_HPC_LA16_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA16_N"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_T0U_N12_66
set_property PACKAGE_PIN A8       [get_ports "VRP_66"] 
set_property IOSTANDARD  LVCOMSxx [get_ports "VRP_66"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L1P_T0L_N0_DBC_66
set_property PACKAGE_PIN F8       [get_ports "FMC_HPC_LA07_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA07_P"] 
# Bank  66 VCCO - VADJ_1V8_FPGA_10A - IO_L1N_T0L_N1_DBC_66
set_property PACKAGE_PIN E8       [get_ports "FMC_HPC_LA07_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA07_N"] 

#Other net   PACKAGE_PIN L10      - 7N5315                    Bank  66 - VREF_66

# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L24P_T3U_N10_67
set_property PACKAGE_PIN H21      [get_ports "FMC_HPC_LA27_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA27_P"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L24N_T3U_N11_67
set_property PACKAGE_PIN G21      [get_ports "FMC_HPC_LA27_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA27_N"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_T3U_N12_67
set_property PACKAGE_PIN H22      [get_ports "7N4052"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "7N4052"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L23P_T3U_N8_67
set_property PACKAGE_PIN G22      [get_ports "FMC_HPC_LA23_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA23_P"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L23N_T3U_N9_67
set_property PACKAGE_PIN F22      [get_ports "FMC_HPC_LA23_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA23_N"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L22P_T3U_N6_DBC_AD0P_67
set_property PACKAGE_PIN G20      [get_ports "FMC_HPC_LA26_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA26_P"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L22N_T3U_N7_DBC_AD0N_67
set_property PACKAGE_PIN F20      [get_ports "FMC_HPC_LA26_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA26_N"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L21P_T3L_N4_AD8P_67
set_property PACKAGE_PIN F23      [get_ports "FMC_HPC_LA21_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA21_P"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L21N_T3L_N5_AD8N_67
set_property PACKAGE_PIN F24      [get_ports "FMC_HPC_LA21_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA21_N"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L20P_T3L_N2_AD1P_67
set_property PACKAGE_PIN E20      [get_ports "FMC_HPC_LA24_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA24_P"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L20N_T3L_N3_AD1N_67
set_property PACKAGE_PIN E21      [get_ports "FMC_HPC_LA24_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA24_N"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L19P_T3L_N0_DBC_AD9P_67
set_property PACKAGE_PIN G24      [get_ports "FMC_HPC_LA22_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA22_P"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L19N_T3L_N1_DBC_AD9N_67
set_property PACKAGE_PIN F25      [get_ports "FMC_HPC_LA22_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA22_N"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L18P_T2U_N10_AD2P_67
set_property PACKAGE_PIN D20      [get_ports "FMC_HPC_LA25_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA25_P"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L18N_T2U_N11_AD2N_67
set_property PACKAGE_PIN D21      [get_ports "FMC_HPC_LA25_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA25_N"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L17P_T2U_N8_AD10P_67
set_property PACKAGE_PIN B20      [get_ports "FMC_HPC_LA29_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA29_P"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L17N_T2U_N9_AD10N_67
set_property PACKAGE_PIN A20      [get_ports "FMC_HPC_LA29_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA29_N"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L16P_T2U_N6_QBC_AD3P_67
set_property PACKAGE_PIN C21      [get_ports "FMC_HPC_LA19_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA19_P"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L16N_T2U_N7_QBC_AD3N_67
set_property PACKAGE_PIN C22      [get_ports "FMC_HPC_LA19_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA19_N"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L15P_T2L_N4_AD11P_67
set_property PACKAGE_PIN B21      [get_ports "FMC_HPC_LA28_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA28_P"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L15N_T2L_N5_AD11N_67
set_property PACKAGE_PIN B22      [get_ports "FMC_HPC_LA28_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA28_N"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L14P_T2L_N2_GC_67
set_property PACKAGE_PIN E22      [get_ports "FMC_HPC_LA18_CC_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA18_CC_P"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L14N_T2L_N3_GC_67
set_property PACKAGE_PIN E23      [get_ports "FMC_HPC_LA18_CC_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA18_CC_N"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_T2U_N12_67
set_property PACKAGE_PIN A22      [get_ports "7N6184"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "7N6184"] 
#
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L13P_T2L_N0_GC_QBC_67
set_property PACKAGE_PIN D23      [get_ports "USER_SMA_CLOCK_P"] 
set_property IOSTANDARD  LVDS     [get_ports "USER_SMA_CLOCK_P"] 
#
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L13N_T2L_N1_GC_QBC_67
set_property PACKAGE_PIN C23      [get_ports "USER_SMA_CLOCK_N"] 
set_property IOSTANDARD  LVDS     [get_ports "USER_SMA_CLOCK_N"] 
#
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L12P_T1U_N10_GC_67
set_property PACKAGE_PIN D24      [get_ports "FMC_HPC_LA17_CC_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA17_CC_P"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L12N_T1U_N11_GC_67
set_property PACKAGE_PIN C24      [get_ports "FMC_HPC_LA17_CC_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA17_CC_N"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_T1U_N12_VRP_67
set_property PACKAGE_PIN A23      [get_ports "7N6189"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "7N6189"] 
#
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L11P_T1U_N8_GC_67
set_property PACKAGE_PIN E25      [get_ports "FMC_HPC_CLK1_M2C_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_CLK1_M2C_P"] 
set_property DIFF_TERM   TRUE     [get_ports "FMC_HPC_CLK1_M2C_P"] 
#
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L11N_T1U_N9_GC_67
set_property PACKAGE_PIN D25      [get_ports "FMC_HPC_CLK1_M2C_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_CLK1_M2C_N"] 
set_property DIFF_TERM   TRUE     [get_ports "FMC_HPC_CLK1_M2C_N"] 
#
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L10P_T1U_N6_QBC_AD4P_67
set_property PACKAGE_PIN B24      [get_ports "FMC_HPC_LA20_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA20_P"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L10N_T1U_N7_QBC_AD4N_67
set_property PACKAGE_PIN A24      [get_ports "FMC_HPC_LA20_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA20_N"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L9P_T1L_N4_AD12P_67
set_property PACKAGE_PIN C26      [get_ports "FMC_HPC_LA30_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA30_P"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L9N_T1L_N5_AD12N_67
set_property PACKAGE_PIN B26      [get_ports "FMC_HPC_LA30_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA30_N"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L8P_T1L_N2_AD5P_67
set_property PACKAGE_PIN B25      [get_ports "FMC_HPC_LA31_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA31_P"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L8N_T1L_N3_AD5N_67
set_property PACKAGE_PIN A25      [get_ports "FMC_HPC_LA31_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA31_N"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L7P_T1L_N0_QBC_AD13P_67
set_property PACKAGE_PIN E26      [get_ports "FMC_HPC_LA32_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA32_P"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L7N_T1L_N1_QBC_AD13N_67
set_property PACKAGE_PIN D26      [get_ports "FMC_HPC_LA32_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA32_N"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L6P_T0U_N10_AD6P_67
set_property PACKAGE_PIN A27      [get_ports "FMC_HPC_LA33_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA33_P"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L6N_T0U_N11_AD6N_67
set_property PACKAGE_PIN A28      [get_ports "FMC_HPC_LA33_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_LA33_N"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L5P_T0U_N8_AD14P_67
set_property PACKAGE_PIN D28      [get_ports "SFP1_TX_DISABLE"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SFP1_TX_DISABLE"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L5N_T0U_N9_AD14N_67
set_property PACKAGE_PIN C28      [get_ports "7N6001"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "7N6001"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L4P_T0U_N6_DBC_AD7P_67
set_property PACKAGE_PIN B29      [get_ports "7N5998"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "7N5998"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L4N_T0U_N7_DBC_AD7N_67
set_property PACKAGE_PIN A29      [get_ports "7N5995"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "7N5995"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L3P_T0L_N4_AD15P_67
set_property PACKAGE_PIN E28      [get_ports "7N5071"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "7N5071"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L3N_T0L_N5_AD15N_67
set_property PACKAGE_PIN D29      [get_ports "7N5069"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "7N5069"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L2P_T0L_N2_67
set_property PACKAGE_PIN C27      [get_ports "7N5067"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "7N5067"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L2N_T0L_N3_67
set_property PACKAGE_PIN B27      [get_ports "7N5080"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "7N5080"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_T0U_N12_67
set_property PACKAGE_PIN C29      [get_ports "VRP_67"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "VRP_67"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L1P_T0L_N0_DBC_67
set_property PACKAGE_PIN F27      [get_ports "7N5078"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "7N5078"] 
# Bank  67 VCCO - VADJ_1V8_FPGA_10A - IO_L1N_T0L_N1_DBC_67
set_property PACKAGE_PIN E27      [get_ports "7N5085"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "7N5085"] 

#Other net   PACKAGE_PIN J20      - 7N5367                    Bank  67 - VREF_67

# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L24P_T3U_N10_68
set_property PACKAGE_PIN L19      [get_ports "FMC_HPC_HA07_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA07_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L24N_T3U_N11_68
set_property PACKAGE_PIN L18      [get_ports "FMC_HPC_HA07_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA07_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_T3U_N12_68
set_property PACKAGE_PIN L17      [get_ports "45N2871"] 
set_property IOSTANDARD  LVCOMSxx [get_ports "45N2871"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L23P_T3U_N8_68
set_property PACKAGE_PIN K16      [get_ports "FMC_HPC_HA12_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA12_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L23N_T3U_N9_68
set_property PACKAGE_PIN J16      [get_ports "FMC_HPC_HA12_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA12_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L22P_T3U_N6_DBC_AD0P_68
set_property PACKAGE_PIN J19      [get_ports "FMC_HPC_HA11_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA11_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L22N_T3U_N7_DBC_AD0N_68
set_property PACKAGE_PIN J18      [get_ports "FMC_HPC_HA11_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA11_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L21P_T3L_N4_AD8P_68
set_property PACKAGE_PIN L15      [get_ports "FMC_HPC_HA06_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA06_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L21N_T3L_N5_AD8N_68
set_property PACKAGE_PIN K15      [get_ports "FMC_HPC_HA06_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA06_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L20P_T3L_N2_AD1P_68
set_property PACKAGE_PIN K18      [get_ports "FMC_HPC_HA08_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA08_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L20N_T3L_N3_AD1N_68
set_property PACKAGE_PIN K17      [get_ports "FMC_HPC_HA08_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA08_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L19P_T3L_N0_DBC_AD9P_68
set_property PACKAGE_PIN J15      [get_ports "FMC_HPC_HA05_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA05_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L19N_T3L_N1_DBC_AD9N_68
set_property PACKAGE_PIN J14      [get_ports "FMC_HPC_HA05_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA05_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L18P_T2U_N10_AD2P_68
set_property PACKAGE_PIN H19      [get_ports "FMC_HPC_HA02_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA02_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L18N_T2U_N11_AD2N_68
set_property PACKAGE_PIN H18      [get_ports "FMC_HPC_HA02_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA02_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L17P_T2U_N8_AD10P_68
set_property PACKAGE_PIN H17      [get_ports "FMC_HPC_HA10_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA10_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L17N_T2U_N9_AD10N_68
set_property PACKAGE_PIN H16      [get_ports "FMC_HPC_HA10_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA10_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L16P_T2U_N6_QBC_AD3P_68
set_property PACKAGE_PIN G19      [get_ports "FMC_HPC_HA04_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA04_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L16N_T2U_N7_QBC_AD3N_68
set_property PACKAGE_PIN F19      [get_ports "FMC_HPC_HA04_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA04_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L15P_T2L_N4_AD11P_68
set_property PACKAGE_PIN G15      [get_ports "FMC_HPC_HA03_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA03_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L15N_T2L_N5_AD11N_68
set_property PACKAGE_PIN G14      [get_ports "FMC_HPC_HA03_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA03_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L14P_T2L_N2_GC_68
set_property PACKAGE_PIN F18      [get_ports "FMC_HPC_HA09_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA09_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L14N_T2L_N3_GC_68
set_property PACKAGE_PIN F17      [get_ports "FMC_HPC_HA09_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA09_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_T2U_N12_68
set_property PACKAGE_PIN H14      [get_ports "45N3754"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "45N3754"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L13P_T2L_N0_GC_QBC_68
set_property PACKAGE_PIN G17      [get_ports "FMC_HPC_HA00_CC_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA00_CC_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L13N_T2L_N1_GC_QBC_68
set_property PACKAGE_PIN G16      [get_ports "FMC_HPC_HA00_CC_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA00_CC_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L12P_T1U_N10_GC_68
set_property PACKAGE_PIN E18      [get_ports "FMC_HPC_HA17_CC_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA17_CC_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L12N_T1U_N11_GC_68
set_property PACKAGE_PIN E17      [get_ports "FMC_HPC_HA17_CC_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA17_CC_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_T1U_N12_VRP_68
set_property PACKAGE_PIN C16      [get_ports "45N3751"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "45N3751"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L11P_T1U_N8_GC_68
set_property PACKAGE_PIN E16      [get_ports "FMC_HPC_HA01_CC_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA01_CC_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L11N_T1U_N9_GC_68
set_property PACKAGE_PIN D16      [get_ports "FMC_HPC_HA01_CC_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA01_CC_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L10P_T1U_N6_QBC_AD4P_68
set_property PACKAGE_PIN D19      [get_ports "FMC_HPC_HA19_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA19_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L10N_T1U_N7_QBC_AD4N_68
set_property PACKAGE_PIN D18      [get_ports "FMC_HPC_HA19_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA19_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L9P_T1L_N4_AD12P_68
set_property PACKAGE_PIN F15      [get_ports "FMC_HPC_HA14_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA14_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L9N_T1L_N5_AD12N_68
set_property PACKAGE_PIN F14      [get_ports "FMC_HPC_HA14_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA14_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L8P_T1L_N2_AD5P_68
set_property PACKAGE_PIN E15      [get_ports "FMC_HPC_HA21_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA21_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L8N_T1L_N3_AD5N_68
set_property PACKAGE_PIN D15      [get_ports "FMC_HPC_HA21_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA21_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L7P_T1L_N0_QBC_AD13P_68
set_property PACKAGE_PIN D14      [get_ports "FMC_HPC_HA15_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA15_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L7N_T1L_N1_QBC_AD13N_68
set_property PACKAGE_PIN C14      [get_ports "FMC_HPC_HA15_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA15_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L6P_T0U_N10_AD6P_68
set_property PACKAGE_PIN C18      [get_ports "FMC_HPC_HA22_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA22_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L6N_T0U_N11_AD6N_68
set_property PACKAGE_PIN C17      [get_ports "FMC_HPC_HA22_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA22_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L5P_T0U_N8_AD14P_68
set_property PACKAGE_PIN B17      [get_ports "FMC_HPC_HA18_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA18_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L5N_T0U_N9_AD14N_68
set_property PACKAGE_PIN B16      [get_ports "FMC_HPC_HA18_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA18_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L4P_T0U_N6_DBC_AD7P_68
set_property PACKAGE_PIN C19      [get_ports "FMC_HPC_HA20_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA20_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L4N_T0U_N7_DBC_AD7N_68
set_property PACKAGE_PIN B19      [get_ports "FMC_HPC_HA20_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA20_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L3P_T0L_N4_AD15P_68
set_property PACKAGE_PIN B15      [get_ports "FMC_HPC_HA23_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA23_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L3N_T0L_N5_AD15N_68
set_property PACKAGE_PIN A15      [get_ports "FMC_HPC_HA23_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA23_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L2P_T0L_N2_68
set_property PACKAGE_PIN A19      [get_ports "FMC_HPC_HA16_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA16_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L2N_T0L_N3_68
set_property PACKAGE_PIN A18      [get_ports "FMC_HPC_HA16_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA16_N"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_T0U_N12_68
set_property PACKAGE_PIN A17      [get_ports "VRP_68"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "VRP_68"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L1P_T0L_N0_DBC_68
set_property PACKAGE_PIN B14      [get_ports "FMC_HPC_HA13_P"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA13_P"] 
# Bank  68 VCCO - VADJ_1V8_FPGA_10A - IO_L1N_T0L_N1_DBC_68
set_property PACKAGE_PIN A14      [get_ports "FMC_HPC_HA13_N"] 
set_property IOSTANDARD  LVDS     [get_ports "FMC_HPC_HA13_N"] 

#Other net   PACKAGE_PIN L14      - 45N3435                   Bank  68 - VREF_68

# Bank  84 VCCO -          - IO_L24P_T3U_N10_64
set_property PACKAGE_PIN AK8      [get_ports "HDMI_R_D17"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D17"] 
# Bank  84 VCCO -          - IO_L24N_T3U_N11_64
set_property PACKAGE_PIN AL8      [get_ports "SFP0_TX_DISABLE"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SFP0_TX_DISABLE"] 
# Bank  84 VCCO -          - IO_T3U_N12_64
set_property PACKAGE_PIN AM9      [get_ports "SFP1_LOS_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SFP1_LOS_LS"] 
# Bank  84 VCCO -          - IO_L23P_T3U_N8_64
set_property PACKAGE_PIN AJ9      [get_ports "SM_FAN_PWM"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SM_FAN_PWM"] 
# Bank  84 VCCO -          - IO_L23N_T3U_N9_64
set_property PACKAGE_PIN AJ8      [get_ports "SM_FAN_TACH"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SM_FAN_TACH"] 
# Bank  84 VCCO -          - IO_L22P_T3U_N6_DBC_AD0P_64
set_property PACKAGE_PIN AN8      [get_ports "CPU_RESET"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "CPU_RESET"] 
# Bank  84 VCCO -          - IO_L22N_T3U_N7_DBC_AD0N_64
set_property PACKAGE_PIN AP8      [get_ports "GPIO_LED_0_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "GPIO_LED_0_LS"] 
# Bank  84 VCCO -          - IO_L21P_T3L_N4_AD8P_64
set_property PACKAGE_PIN AK10     [get_ports "PMBUS_ALERT_FPGA"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "PMBUS_ALERT_FPGA"] 
# Bank  84 VCCO -          - IO_L21N_T3L_N5_AD8N_64
set_property PACKAGE_PIN AL9      [get_ports "MAXIM_CABLE_B_FPGA"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "MAXIM_CABLE_B_FPGA"] 
# Bank  84 VCCO -          - IO_L20P_T3L_N2_AD1P_64
set_property PACKAGE_PIN AN9      [get_ports "SDIO_DATA1_FPGA"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SDIO_DATA1_FPGA"] 
# Bank  84 VCCO -          - IO_L20N_T3L_N3_AD1N_64
set_property PACKAGE_PIN AP9      [get_ports "SDIO_DATA0_FPGA"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SDIO_DATA0_FPGA"] 
# Bank  84 VCCO -          - IO_L19P_T3L_N0_DBC_AD9P_64
set_property PACKAGE_PIN AL10     [get_ports "SDIO_CLK_FPGA"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SDIO_CLK_FPGA"] 
# Bank  84 VCCO -          - IO_L19N_T3L_N1_DBC_AD9N_64
set_property PACKAGE_PIN AM10     [get_ports "SDIO_CD_FPGA"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SDIO_CD_FPGA"] 
# Bank  84 VCCO -          - IO_L18P_T2U_N10_AD2P_64
set_property PACKAGE_PIN AH9      [get_ports "SDIO_DATA2_FPGA"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SDIO_DATA2_FPGA"] 
# Bank  84 VCCO -          - IO_L18N_T2U_N11_AD2N_64
set_property PACKAGE_PIN AH8      [get_ports "SDIO_DATA3_FPGA"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SDIO_DATA3_FPGA"] 
# Bank  84 VCCO -          - IO_L17P_T2U_N8_AD10P_64
set_property PACKAGE_PIN AD9      [get_ports "SDIO_CMD_FPGA"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SDIO_CMD_FPGA"] 
# Bank  84 VCCO -          - IO_L17N_T2U_N9_AD10N_64
set_property PACKAGE_PIN AD8      [get_ports "6N6184"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "6N6184"] 
# Bank  84 VCCO -          - IO_L16P_T2U_N6_QBC_AD3P_64
set_property PACKAGE_PIN AD10     [get_ports "GPIO_SW_N"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "GPIO_SW_N"] 
# Bank  84 VCCO -          - IO_L16N_T2U_N7_QBC_AD3N_64
set_property PACKAGE_PIN AE10     [get_ports "GPIO_SW_C"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "GPIO_SW_C"] 
# Bank  84 VCCO -          - IO_L15P_T2L_N4_AD11P_64
set_property PACKAGE_PIN AE8      [get_ports "GPIO_SW_E"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "GPIO_SW_E"] 
# Bank  84 VCCO -          - IO_L15N_T2L_N5_AD11N_64
set_property PACKAGE_PIN AF8      [get_ports "GPIO_SW_S"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "GPIO_SW_S"] 
# Bank  84 VCCO -          - IO_L14P_T2L_N2_GC_64
set_property PACKAGE_PIN AF9      [get_ports "GPIO_SW_W"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "GPIO_SW_W"] 
# Bank  84 VCCO -          - IO_L14N_T2L_N3_GC_64
set_property PACKAGE_PIN AG9      [get_ports "SYSCTLR_GPIO_6"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SYSCTLR_GPIO_6"] 
# Bank  84 VCCO -          - IO_T2U_N12_64
set_property PACKAGE_PIN AJ10     [get_ports "SYSCTLR_GPIO_5"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SYSCTLR_GPIO_5"] 
# Bank  84 VCCO -          - IO_L13P_T2L_N0_GC_QBC_64
set_property PACKAGE_PIN AF10     [get_ports "SYSCTLR_GPIO_7"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SYSCTLR_GPIO_7"] 
# Bank  84 VCCO -          - IO_L13N_T2L_N1_GC_QBC_64
set_property PACKAGE_PIN AG10     [get_ports "HDMI_R_D16"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D16"] 

#Other net   PACKAGE_PIN AD13     - 6N5365                    Bank  84 - VREF_64

# Bank  85 VCCO -          - IO_L24P_T3U_N10_EMCCLK_65
set_property PACKAGE_PIN K20      [get_ports "FPGA_EMCCLK"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "FPGA_EMCCLK"] 
# Bank  85 VCCO -          - IO_L24N_T3U_N11_DOUT_CSO_B_65
set_property PACKAGE_PIN K21      [get_ports "SFP0_LOS_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SFP0_LOS_LS"] 
# Bank  85 VCCO -          - IO_T3U_N12_PERSTN0_65
set_property PACKAGE_PIN K22      [get_ports "PCIE_PERST_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "PCIE_PERST_LS"] 
# Bank  85 VCCO -          - IO_L23P_T3U_N8_I2C_SCLK_65
set_property PACKAGE_PIN N21      [get_ports "SYSMON_SCL_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SYSMON_SCL_LS"] 
# Bank  85 VCCO -          - IO_L23N_T3U_N9_I2C_SDA_65
set_property PACKAGE_PIN M21      [get_ports "SYSMON_SDA_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SYSMON_SDA_LS"] 
# Bank  85 VCCO -          - IO_L22P_T3U_N6_DBC_AD0P_D04_65
set_property PACKAGE_PIN M20      [get_ports "QSPI1_IO0"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "QSPI1_IO0"] 
# Bank  85 VCCO -          - IO_L22N_T3U_N7_DBC_AD0N_D05_65
set_property PACKAGE_PIN L20      [get_ports "QSPI1_IO1"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "QSPI1_IO1"] 
# Bank  85 VCCO -          - IO_L21P_T3L_N4_AD8P_D06_65
set_property PACKAGE_PIN R21      [get_ports "QSPI1_IO2"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "QSPI1_IO2"] 
# Bank  85 VCCO -          - IO_L21N_T3L_N5_AD8N_D07_65
set_property PACKAGE_PIN R22      [get_ports "QSPI1_IO3"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "QSPI1_IO3"] 
# Bank  85 VCCO -          - IO_L20P_T3L_N2_AD1P_D08_65
set_property PACKAGE_PIN P20      [get_ports "GPIO_LED_2_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "GPIO_LED_2_LS"] 
# Bank  85 VCCO -          - IO_L20N_T3L_N3_AD1N_D09_65
set_property PACKAGE_PIN P21      [get_ports "GPIO_LED_3_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "GPIO_LED_3_LS"] 
# Bank  85 VCCO -          - IO_L19P_T3L_N0_DBC_AD9P_D10_65
set_property PACKAGE_PIN N22      [get_ports "GPIO_LED_4_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "GPIO_LED_4_LS"] 
# Bank  85 VCCO -          - IO_L19N_T3L_N1_DBC_AD9N_D11_65
set_property PACKAGE_PIN M22      [get_ports "GPIO_LED_5_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "GPIO_LED_5_LS"] 
# Bank  85 VCCO -          - IO_L18P_T2U_N10_AD2P_D12_65
set_property PACKAGE_PIN R23      [get_ports "GPIO_LED_6_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "GPIO_LED_6_LS"] 
# Bank  85 VCCO -          - IO_L18N_T2U_N11_AD2N_D13_65
set_property PACKAGE_PIN P23      [get_ports "GPIO_LED_7_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "GPIO_LED_7_LS"] 
# Bank  85 VCCO -          - IO_L17P_T2U_N8_AD10P_D14_65
set_property PACKAGE_PIN R25      [get_ports "6N6187"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "6N6187"] 
# Bank  85 VCCO -          - IO_L17N_T2U_N9_AD10N_D15_65
set_property PACKAGE_PIN R26      [get_ports "6N6190"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "6N6190"] 
# Bank  85 VCCO -          - IO_L16P_T2U_N6_QBC_AD3P_A00_D16_65
set_property PACKAGE_PIN T24      [get_ports "6N6193"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "6N6193"] 
# Bank  85 VCCO -          - IO_L16N_T2U_N7_QBC_AD3N_A01_D17_65
set_property PACKAGE_PIN T25      [get_ports "6N6196"] 
set_property IOSTANDARD  LVCMOSxx [get_ports "6N6196"] 
# Bank  85 VCCO -          - IO_L15P_T2L_N4_AD11P_A02_D18_65
set_property PACKAGE_PIN T27      [get_ports "SYSMON_MUX_ADDR0_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SYSMON_MUX_ADDR0_LS"] 
# Bank  85 VCCO -          - IO_L15N_T2L_N5_AD11N_A03_D19_65
set_property PACKAGE_PIN R27      [get_ports "SYSMON_MUX_ADDR1_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SYSMON_MUX_ADDR1_LS"] 
# Bank  85 VCCO -          - IO_L14P_T2L_N2_GC_A04_D20_65
set_property PACKAGE_PIN P24            [get_ports "SGMII_RX_P"] 
set_property IOSTANDARD  DIFF_HSTL_I_18 [get_ports "SGMII_RX_P"] 
#
# Bank  85 VCCO -          - IO_L14N_T2L_N3_GC_A05_D21_65
set_property PACKAGE_PIN P25            [get_ports "SGMII_RX_N"] 
set_property IOSTANDARD  DIFF_HSTL_I_18 [get_ports "SGMII_RX_N"] 
#
# Bank  85 VCCO -          - IO_T2U_N12_CSI_ADV_B_65
set_property PACKAGE_PIN N27      [get_ports "SYSMON_MUX_ADDR2_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SYSMON_MUX_ADDR2_LS"] 
#
# Bank  85 VCCO -          - IO_L13P_T2L_N0_GC_QBC_A06_D22_65
set_property PACKAGE_PIN P26      [get_ports "SGMIICLK_P"] 
set_property IOSTANDARD  LVDS_25  [get_ports "SGMIICLK_P"]
# 
# Bank  85 VCCO -          - IO_L13N_T2L_N1_GC_QBC_A07_D23_65
set_property PACKAGE_PIN N26      [get_ports "SGMIICLK_N"] 
set_property IOSTANDARD  LVDS_25  [get_ports "SGMIICLK_N"] 
#
#Other net   PACKAGE_PIN J21      - 6N4871                    Bank  85 - VREF_65

# Bank  94 VCCO -          - IO_L12P_T1U_N10_GC_64
set_property PACKAGE_PIN AG11           [get_ports "REC_CLOCK_C_P"] 
set_property IOSTANDARD  DIFF_HSTL_I_18 [get_ports "REC_CLOCK_C_P"] 
# Bank  94 VCCO -          - IO_L12N_T1U_N11_GC_64
set_property PACKAGE_PIN AH11           [get_ports "REC_CLOCK_C_N"] 
set_property IOSTANDARD  DIFF_HSTL_I_18 [get_ports "REC_CLOCK_C_N"] 
# Bank  94 VCCO -          - IO_T1U_N12_64
set_property PACKAGE_PIN AJ11     [get_ports "HDMI_R_D15"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D15"] 
# Bank  94 VCCO -          - IO_L11P_T1U_N8_GC_64
set_property PACKAGE_PIN AG12     [get_ports "HDMI_R_D14"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D14"] 
# Bank  94 VCCO -          - IO_L11N_T1U_N9_GC_64
set_property PACKAGE_PIN AH12     [get_ports "HDMI_R_D13"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D13"] 
# Bank  94 VCCO -          - IO_L10P_T1U_N6_QBC_AD4P_64
set_property PACKAGE_PIN AD11     [get_ports "HDMI_R_D12"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D12"] 
# Bank  94 VCCO -          - IO_L10N_T1U_N7_QBC_AD4N_64
set_property PACKAGE_PIN AE11     [get_ports "HDMI_R_DE"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_DE"] 
# Bank  94 VCCO -          - IO_L9P_T1L_N4_AD12P_64
set_property PACKAGE_PIN AE12     [get_ports "HDMI_R_SPDIF"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_SPDIF"] 
# Bank  94 VCCO -          - IO_L9N_T1L_N5_AD12N_64
set_property PACKAGE_PIN AF12     [get_ports "HDMI_SPDIF_OUT_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_SPDIF_OUT_LS"] 
# Bank  94 VCCO -          - IO_L8P_T1L_N2_AD5P_64
set_property PACKAGE_PIN AH13     [get_ports "HDMI_R_VSYNC"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_VSYNC"] 
# Bank  94 VCCO -          - IO_L8N_T1L_N3_AD5N_64
set_property PACKAGE_PIN AJ13     [get_ports "HDMI_INT"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_INT"] 
# Bank  94 VCCO -          - IO_L7P_T1L_N0_QBC_AD13P_64
set_property PACKAGE_PIN AE13     [get_ports "HDMI_R_HSYNC"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_HSYNC"] 
# Bank  94 VCCO -          - IO_L7N_T1L_N1_QBC_AD13N_64
set_property PACKAGE_PIN AF13     [get_ports "HDMI_R_CLK"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_CLK"] 
# Bank  94 VCCO -          - IO_L6P_T0U_N10_AD6P_64
set_property PACKAGE_PIN AK13     [get_ports "HDMI_R_D11"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D11"] 
# Bank  94 VCCO -          - IO_L6N_T0U_N11_AD6N_64
set_property PACKAGE_PIN AL13     [get_ports "HDMI_R_D10"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D10"] 
# Bank  94 VCCO -          - IO_L5P_T0U_N8_AD14P_64
set_property PACKAGE_PIN AK12     [get_ports "HDMI_R_D9"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D9"] 
# Bank  94 VCCO -          - IO_L5N_T0U_N9_AD14N_64
set_property PACKAGE_PIN AL12     [get_ports "HDMI_R_D8"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D8"] 
# Bank  94 VCCO -          - IO_L4P_T0U_N6_DBC_AD7P_64
set_property PACKAGE_PIN AM12     [get_ports "HDMI_R_D7"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D7"] 
# Bank  94 VCCO -          - IO_L4N_T0U_N7_DBC_AD7N_64
set_property PACKAGE_PIN AN12     [get_ports "HDMI_R_D6"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D6"] 
# Bank  94 VCCO -          - IO_L3P_T0L_N4_AD15P_64
set_property PACKAGE_PIN AM11     [get_ports "HDMI_R_D5"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D5"] 
# Bank  94 VCCO -          - IO_L3N_T0L_N5_AD15N_64
set_property PACKAGE_PIN AN11     [get_ports "HDMI_R_D4"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D4"] 
# Bank  94 VCCO -          - IO_L2P_T0L_N2_64
set_property PACKAGE_PIN AN13     [get_ports "HDMI_R_D3"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D3"] 
# Bank  94 VCCO -          - IO_L2N_T0L_N3_64
set_property PACKAGE_PIN AP13     [get_ports "HDMI_R_D2"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D2"] 
# Bank  94 VCCO -          - IO_T0U_N12_64
set_property PACKAGE_PIN AK11     [get_ports "HDMI_R_D0"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D0"] 
# Bank  94 VCCO -          - IO_L1P_T0L_N0_DBC_64
set_property PACKAGE_PIN AP11     [get_ports "HDMI_R_D1"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D1"] 
# Bank  94 VCCO -          - IO_L1N_T0L_N1_DBC_64
set_property PACKAGE_PIN AP10     [get_ports "IIC_MUX_RESET_B_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "IIC_MUX_RESET_B_LS"] 
# Bank  95 VCCO -          - IO_L12P_T1U_N10_GC_A08_D24_65
set_property PACKAGE_PIN N24            [get_ports "SGMII_TX_P"] 
set_property IOSTANDARD  DIFF_HSTL_I_18 [get_ports "SGMII_TX_P"] 
#
# Bank  95 VCCO -          - IO_L12N_T1U_N11_GC_A09_D25_65
set_property PACKAGE_PIN M24            [get_ports "SGMII_TX_N"] 
set_property IOSTANDARD  DIFF_HSTL_I_18 [get_ports "SGMII_TX_N"] 
# Bank  95 VCCO -          - IO_T1U_N12_PERSTN1_65
set_property PACKAGE_PIN N23      [get_ports "PCIE_WAKE_B_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "PCIE_WAKE_B_LS"] 
#
# Bank  95 VCCO -          - IO_L11P_T1U_N8_GC_A10_D26_65
set_property PACKAGE_PIN M25      [get_ports "USER_SI570_CLOCK_P"] 
set_property IOSTANDARD  LVDS_25  [get_ports "USER_SI570_CLOCK_P"]
#
# Bank  95 VCCO -          - IO_L11N_T1U_N9_GC_A11_D27_65
set_property PACKAGE_PIN M26      [get_ports "USER_SI570_CLOCK_N"] 
set_property IOSTANDARD  LVDS_25  [get_ports "USER_SI570_CLOCK_N"]
#
# Bank  95 VCCO -          - IO_L10P_T1U_N6_QBC_AD4P_A12_D28_65
set_property PACKAGE_PIN L22      [get_ports "SI5328_INT_ALM_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SI5328_INT_ALM_LS"] 
# Bank  95 VCCO -          - IO_L10N_T1U_N7_QBC_AD4N_A13_D29_65
set_property PACKAGE_PIN K23      [get_ports "SI5328_RST_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "SI5328_RST_LS"] 
# Bank  95 VCCO -          - IO_L9P_T1L_N4_AD12P_A14_D30_65
set_property PACKAGE_PIN L25      [get_ports "PHY_MDC_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "PHY_MDC_LS"] 
# Bank  95 VCCO -          - IO_L9N_T1L_N5_AD12N_A15_D31_65
set_property PACKAGE_PIN K25      [get_ports "PHY_INT_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "PHY_INT_LS"] 
# Bank  95 VCCO -          - IO_L8P_T1L_N2_AD5P_A16_65
set_property PACKAGE_PIN L23      [get_ports "USB_UART_CTS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "USB_UART_CTS"] 
# Bank  95 VCCO -          - IO_L8N_T1L_N3_AD5N_A17_65
set_property PACKAGE_PIN L24      [get_ports "FMC_VADJ_ON_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "FMC_VADJ_ON_LS"] 
# Bank  95 VCCO -          - IO_L7P_T1L_N0_QBC_AD13P_A18_65
set_property PACKAGE_PIN M27      [get_ports "VADJ_1V8_PGOOD_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "VADJ_1V8_PGOOD_LS"] 
# Bank  95 VCCO -          - IO_L7N_T1L_N1_QBC_AD13N_A19_65
set_property PACKAGE_PIN L27      [get_ports "FMC_HPC_PG_M2C_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "FMC_HPC_PG_M2C_LS"] 
# Bank  95 VCCO -          - IO_L6P_T0U_N10_AD6P_A20_65
set_property PACKAGE_PIN J23      [get_ports "PHY_RESET_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "PHY_RESET_LS"] 
# Bank  95 VCCO -          - IO_L6N_T0U_N11_AD6N_A21_65
set_property PACKAGE_PIN H24      [get_ports "FMC_HPC_PRSNT_M2C_B_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "FMC_HPC_PRSNT_M2C_B_LS"] 
# Bank  95 VCCO -          - IO_L5P_T0U_N8_AD14P_A22_65
set_property PACKAGE_PIN J26      [get_ports "FMC_LPC_PRSNT_M2C_B_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "FMC_LPC_PRSNT_M2C_B_LS"] 
# Bank  95 VCCO -          - IO_L5N_T0U_N9_AD14N_A23_65
set_property PACKAGE_PIN H26      [get_ports "PHY_MDIO_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "PHY_MDIO_LS"] 
# Bank  95 VCCO -          - IO_L4P_T0U_N6_DBC_AD7P_A24_65
set_property PACKAGE_PIN J24      [get_ports "IIC_MAIN_SCL_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "IIC_MAIN_SCL_LS"] 
# Bank  95 VCCO -          - IO_L4N_T0U_N7_DBC_AD7N_A25_65
set_property PACKAGE_PIN J25      [get_ports "IIC_MAIN_SDA_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "IIC_MAIN_SDA_LS"] 
# Bank  95 VCCO -          - IO_L3P_T0L_N4_AD15P_A26_65
set_property PACKAGE_PIN K26      [get_ports "USB_UART_RX"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "USB_UART_RX"] 
# Bank  95 VCCO -          - IO_L3N_T0L_N5_AD15N_A27_65
set_property PACKAGE_PIN K27      [get_ports "USB_UART_RTS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "USB_UART_RTS"] 
# Bank  95 VCCO -          - IO_L2P_T0L_N2_FOE_B_65
set_property PACKAGE_PIN G25      [get_ports "USB_UART_TX"] 
set_property IOSTANDARD  LVMOS18  [get_ports "USB_UART_TX"] 
# Bank  95 VCCO -          - IO_L2N_T0L_N3_FWE_FCS2_B_65
set_property PACKAGE_PIN G26      [get_ports "QSPI1_CS_B"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "QSPI1_CS_B"] 
# Bank  95 VCCO -          - IO_T0U_N12_A28_65
set_property PACKAGE_PIN H23      [get_ports "GPIO_LED_1_LS"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "GPIO_LED_1_LS"] 
# Bank  95 VCCO -          - IO_L1P_T0L_N0_DBC_RS0_65
set_property PACKAGE_PIN H27      [get_ports "USER_SMA_GPIO_P"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "USER_SMA_GPIO_P"] 
# Bank  95 VCCO -          - IO_L1N_T0L_N1_DBC_RS1_65
set_property PACKAGE_PIN G27      [get_ports "USER_SMA_GPIO_N"] 
set_property IOSTANDARD  LVCMOS18 [get_ports "USER_SMA_GPIO_N"] 


#Other net   PACKAGE_PIN AK6      - PCIE_TX4_P                Bank 224 - MGTHTXP3_224
#Other net   PACKAGE_PIN AJ4      - PCIE_RX4_P                Bank 224 - MGTHRXP3_224
#Other net   PACKAGE_PIN AJ3      - PCIE_RX4_N                Bank 224 - MGTHRXN3_224
#Other net   PACKAGE_PIN AK5      - PCIE_TX4_N                Bank 224 - MGTHTXN3_224

# Bank 224 - MGTREFCLK1P_224
set_property PACKAGE_PIN AD6      [get_ports "9N3799"] 
# Bank 224 - MGTREFCLK1N_224
set_property PACKAGE_PIN AD5      [get_ports "9N3812"] 

#Other net   PACKAGE_PIN AL4      - PCIE_TX5_P                Bank 224 - MGTHTXP2_224
#Other net   PACKAGE_PIN AK2      - PCIE_RX5_P                Bank 224 - MGTHRXP2_224
#Other net   PACKAGE_PIN AK1      - PCIE_RX5_N                Bank 224 - MGTHRXN2_224
#Other net   PACKAGE_PIN AL3      - PCIE_TX5_N                Bank 224 - MGTHTXN2_224
#Other net   PACKAGE_PIN AM6      - PCIE_TX6_P                Bank 224 - MGTHTXP1_224
#Other net   PACKAGE_PIN AM2      - PCIE_RX6_P                Bank 224 - MGTHRXP1_224
#Other net   PACKAGE_PIN AM1      - PCIE_RX6_N                Bank 224 - MGTHRXN1_224
#Other net   PACKAGE_PIN AM5      - PCIE_TX6_N                Bank 224 - MGTHTXN1_224

# Bank 224 - MGTREFCLK0P_224
set_property PACKAGE_PIN AF6      [get_ports "9N4227"] 
# Bank 224 - MGTREFCLK0N_224
set_property PACKAGE_PIN AF5      [get_ports "9N4225"] 

#Other net   PACKAGE_PIN AN4      - PCIE_TX7_P                Bank 224 - MGTHTXP0_224
#Other net   PACKAGE_PIN AP2      - PCIE_RX7_P                Bank 224 - MGTHRXP0_224
#Other net   PACKAGE_PIN AP1      - PCIE_RX7_N                Bank 224 - MGTHRXN0_224
#Other net   PACKAGE_PIN AN3      - PCIE_TX7_N                Bank 224 - MGTHTXN0_224
#Other net   PACKAGE_PIN AC4      - PCIE_TX0_P                Bank 225 - MGTHTXP3_225
#Other net   PACKAGE_PIN AB2      - PCIE_RX0_P                Bank 225 - MGTHRXP3_225
#Other net   PACKAGE_PIN AB1      - PCIE_RX0_N                Bank 225 - MGTHRXN3_225
#Other net   PACKAGE_PIN AC3      - PCIE_TX0_N                Bank 225 - MGTHTXN3_225

# Bank 225 - MGTREFCLK1P_225
set_property PACKAGE_PIN Y6       [get_ports "9N2894"] 
# Bank 225 - MGTREFCLK1N_225
set_property PACKAGE_PIN Y5       [get_ports "9N2891"] 

#Other net   PACKAGE_PIN AE4      - PCIE_TX1_P                Bank 225 - MGTHTXP2_225
#Other net   PACKAGE_PIN AD2      - PCIE_RX1_P                Bank 225 - MGTHRXP2_225
#Other net   PACKAGE_PIN AD1      - PCIE_RX1_N                Bank 225 - MGTHRXN2_225
#Other net   PACKAGE_PIN AE3      - PCIE_TX1_N                Bank 225 - MGTHTXN2_225

# Bank 225 - MGTRREF_225
set_property PACKAGE_PIN AP5      [get_ports "9N2099"] 

#Other net   PACKAGE_PIN AP6      - MGTAVTT_FPGA_5A           Bank 225 - MGTAVTTRCAL_225
#Other net   PACKAGE_PIN AG4      - PCIE_TX2_P                Bank 225 - MGTHTXP1_225
#Other net   PACKAGE_PIN AF2      - PCIE_RX2_P                Bank 225 - MGTHRXP1_225
#Other net   PACKAGE_PIN AF1      - PCIE_RX2_N                Bank 225 - MGTHRXN1_225
#Other net   PACKAGE_PIN AG3      - PCIE_TX2_N                Bank 225 - MGTHTXN1_225

# Bank 225 - MGTREFCLK0P_225
set_property PACKAGE_PIN AB6      [get_ports "PCIE_CLK_QO_P"] 
# Bank 225 - MGTREFCLK0N_225
set_property PACKAGE_PIN AB5      [get_ports "PCIE_CLK_QO_N"] 

#Other net   PACKAGE_PIN AH6      - PCIE_TX3_P                Bank 225 - MGTHTXP0_225
#Other net   PACKAGE_PIN AH2      - PCIE_RX3_P                Bank 225 - MGTHRXP0_225
#Other net   PACKAGE_PIN AH1      - PCIE_RX3_N                Bank 225 - MGTHRXN0_225
#Other net   PACKAGE_PIN AH5      - PCIE_TX3_N                Bank 225 - MGTHTXN0_225
#Other net   PACKAGE_PIN R4       - SMA_MGT_TX_P              Bank 226 - MGTHTXP3_226
#Other net   PACKAGE_PIN P2       - SMA_MGT_RX_C_P            Bank 226 - MGTHRXP3_226
#Other net   PACKAGE_PIN P1       - SMA_MGT_RX_C_N            Bank 226 - MGTHRXN3_226
#Other net   PACKAGE_PIN R3       - SMA_MGT_TX_N              Bank 226 - MGTHTXN3_226

# Bank 226 - MGTREFCLK1P_226
set_property PACKAGE_PIN T6       [get_ports "FMC_LPC_GBTCLK0_M2C_C_P"] 
# Bank 226 - MGTREFCLK1N_226
set_property PACKAGE_PIN T5       [get_ports "FMC_LPC_GBTCLK0_M2C_C_N"] 

#Other net   PACKAGE_PIN U4       - SFP0_TX_P                 Bank 226 - MGTHTXP2_226
#Other net   PACKAGE_PIN T2       - SFP0_RX_P                 Bank 226 - MGTHRXP2_226
#Other net   PACKAGE_PIN T1       - SFP0_RX_N                 Bank 226 - MGTHRXN2_226
#Other net   PACKAGE_PIN U3       - SFP0_TX_N                 Bank 226 - MGTHTXN2_226
#Other net   PACKAGE_PIN W4       - SFP1_TX_P                 Bank 226 - MGTHTXP1_226
#Other net   PACKAGE_PIN V2       - SFP1_RX_P                 Bank 226 - MGTHRXP1_226
#Other net   PACKAGE_PIN V1       - SFP1_RX_N                 Bank 226 - MGTHRXN1_226
#Other net   PACKAGE_PIN W3       - SFP1_TX_N                 Bank 226 - MGTHTXN1_226

# Bank 226 - MGTREFCLK0P_226
set_property PACKAGE_PIN V6       [get_ports "SMA_MGT_REFCLK_C_P"] 
# Bank 226 - MGTREFCLK0N_226
set_property PACKAGE_PIN V5       [get_ports "SMA_MGT_REFCLK_C_N"] 

#Other net   PACKAGE_PIN AA4      - FMC_LPC_DP0_C2M_P         Bank 226 - MGTHTXP0_226
#Other net   PACKAGE_PIN Y2       - FMC_LPC_DP0_M2C_P         Bank 226 - MGTHRXP0_226
#Other net   PACKAGE_PIN Y1       - FMC_LPC_DP0_M2C_N         Bank 226 - MGTHRXN0_226
#Other net   PACKAGE_PIN AA3      - FMC_LPC_DP0_C2M_N         Bank 226 - MGTHTXN0_226
#Other net   PACKAGE_PIN G4       - FMC_HPC_DP7_C2M_P         Bank 227 - MGTHTXP3_227
#Other net   PACKAGE_PIN F2       - FMC_HPC_DP7_M2C_P         Bank 227 - MGTHRXP3_227
#Other net   PACKAGE_PIN F1       - FMC_HPC_DP7_M2C_N         Bank 227 - MGTHRXN3_227
#Other net   PACKAGE_PIN G3       - FMC_HPC_DP7_C2M_N         Bank 227 - MGTHTXN3_227
# Bank 227 - MGTREFCLK1P_227
set_property PACKAGE_PIN M6       [get_ports "SI5328_OUT_C_P"] 
# Bank 227 - MGTREFCLK1N_227
set_property PACKAGE_PIN M5       [get_ports "SI5328_OUT_C_N"] 

#Other net   PACKAGE_PIN J4       - FMC_HPC_DP5_C2M_P         Bank 227 - MGTHTXP2_227
#Other net   PACKAGE_PIN H2       - FMC_HPC_DP5_M2C_P         Bank 227 - MGTHRXP2_227
#Other net   PACKAGE_PIN H1       - FMC_HPC_DP5_M2C_N         Bank 227 - MGTHRXN2_227
#Other net   PACKAGE_PIN J3       - FMC_HPC_DP5_C2M_N         Bank 227 - MGTHTXN2_227
#Other net   PACKAGE_PIN L4       - FMC_HPC_DP6_C2M_P         Bank 227 - MGTHTXP1_227
#Other net   PACKAGE_PIN K2       - FMC_HPC_DP6_M2C_P         Bank 227 - MGTHRXP1_227
#Other net   PACKAGE_PIN K1       - FMC_HPC_DP6_M2C_N         Bank 227 - MGTHRXN1_227
#Other net   PACKAGE_PIN L3       - FMC_HPC_DP6_C2M_N         Bank 227 - MGTHTXN1_227
# Bank 227 - MGTREFCLK0P_227
set_property PACKAGE_PIN P6       [get_ports "MGT_SI570_CLOCK_C_P"] 
# Bank 227 - MGTREFCLK0N_227
set_property PACKAGE_PIN P5       [get_ports "MGT_SI570_CLOCK_C_N"] 

#Other net   PACKAGE_PIN N4       - FMC_HPC_DP4_C2M_P         Bank 227 - MGTHTXP0_227
#Other net   PACKAGE_PIN M2       - FMC_HPC_DP4_M2C_P         Bank 227 - MGTHRXP0_227
#Other net   PACKAGE_PIN M1       - FMC_HPC_DP4_M2C_N         Bank 227 - MGTHRXN0_227
#Other net   PACKAGE_PIN N3       - FMC_HPC_DP4_C2M_N         Bank 227 - MGTHTXN0_227
#Other net   PACKAGE_PIN B6       - FMC_HPC_DP3_C2M_P         Bank 228 - MGTHTXP3_228
#Other net   PACKAGE_PIN A4       - FMC_HPC_DP3_M2C_P         Bank 228 - MGTHRXP3_228
#Other net   PACKAGE_PIN A3       - FMC_HPC_DP3_M2C_N         Bank 228 - MGTHRXN3_228
#Other net   PACKAGE_PIN B5       - FMC_HPC_DP3_C2M_N         Bank 228 - MGTHTXN3_228
# Bank 228 - MGTREFCLK1P_228
set_property PACKAGE_PIN H6       [get_ports "FMC_HPC_GBTCLK1_M2C_C_P"] 
# Bank 228 - MGTREFCLK1N_228
set_property PACKAGE_PIN H5       [get_ports "FMC_HPC_GBTCLK1_M2C_C_N"] 

#Other net   PACKAGE_PIN C4       - FMC_HPC_DP2_C2M_P         Bank 228 - MGTHTXP2_228
#Other net   PACKAGE_PIN B2       - FMC_HPC_DP2_M2C_P         Bank 228 - MGTHRXP2_228
#Other net   PACKAGE_PIN B1       - FMC_HPC_DP2_M2C_N         Bank 228 - MGTHRXN2_228
#Other net   PACKAGE_PIN C3       - FMC_HPC_DP2_C2M_N         Bank 228 - MGTHTXN2_228
#Other net   PACKAGE_PIN D6       - FMC_HPC_DP1_C2M_P         Bank 228 - MGTHTXP1_228
#Other net   PACKAGE_PIN D2       - FMC_HPC_DP1_M2C_P         Bank 228 - MGTHRXP1_228
#Other net   PACKAGE_PIN D1       - FMC_HPC_DP1_M2C_N         Bank 228 - MGTHRXN1_228
#Other net   PACKAGE_PIN D5       - FMC_HPC_DP1_C2M_N         Bank 228 - MGTHTXN1_228

# Bank 228 - MGTREFCLK0P_228
set_property PACKAGE_PIN K6       [get_ports "FMC_HPC_GBTCLK0_M2C_C_P"] 
# Bank 228 - MGTREFCLK0N_228
set_property PACKAGE_PIN K5       [get_ports "FMC_HPC_GBTCLK0_M2C_C_N"] 

#Other net   PACKAGE_PIN F6       - FMC_HPC_DP0_C2M_P         Bank 228 - MGTHTXP0_228
#Other net   PACKAGE_PIN E4       - FMC_HPC_DP0_M2C_P         Bank 228 - MGTHRXP0_228
#Other net   PACKAGE_PIN E3       - FMC_HPC_DP0_M2C_N         Bank 228 - MGTHRXN0_228
#Other net   PACKAGE_PIN F5       - FMC_HPC_DP0_C2M_N         Bank 228 - MGTHTXN0_228

