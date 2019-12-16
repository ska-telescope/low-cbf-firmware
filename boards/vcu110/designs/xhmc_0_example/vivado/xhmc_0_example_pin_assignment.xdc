
#############################################################################
# PIN allocation constraints for Xilinx HMC demo on VCU110 evaluation board #
#                                                                           #
# Note 1: The example is tagert at VCU110 HMC link 0 by default which uses  #
#         out of order lane mapping among HMC lanes and controller GT lans. #
#         Please refer to the listed lane order for mapping and ensure the  #
#         right order while generating the XHMC IP.                         #  
#                                                                           #
# GT_LINK   :   0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15             # 
# HMC_LINK_1:   0  2  1  6  4  3  7  5  11 14 15 13 12 10 9  8              #
# HMC_LINK_0:   12 9  13 8  10 14 0  1  4  11 6  2  3  15 5  7              # 
#                                                                           #
# Note 2: The last portion of this has the pin constraints correspond to    #
#         VCU110 HMC LINK 1. The user are free to midify the file if needed.#
#                                                                           #
#############################################################################



set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 8 [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN div-1 [current_design]
#set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.CONFIG.SPI_OPCODE 8'h6B [current_design]
set_property CONFIG_MODE SPIx8 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]

set_property INTERNAL_VREF {0.6} [get_iobanks 70]
set_property INTERNAL_VREF {0.6} [get_iobanks 71]


#######################################################################
# Reset & clock
#######################################################################
set_property PACKAGE_PIN J29 [get_ports rst]
set_property IOSTANDARD LVCMOS12 [get_ports rst]

set_property IOSTANDARD LVDS [get_ports clk_free_p]
set_property PACKAGE_PIN AW20 [get_ports clk_free_n]
set_property IOSTANDARD LVDS [get_ports clk_free_n]

######################################################################
#IIC interface
######################################################################
set_property PACKAGE_PIN AV19 [get_ports IIC_MAIN_SCL_LS]
set_property IOSTANDARD LVCMOS18 [get_ports IIC_MAIN_SCL_LS]
set_property PACKAGE_PIN AV21 [get_ports IIC_MAIN_SDA_LS]
set_property IOSTANDARD LVCMOS18 [get_ports IIC_MAIN_SDA_LS]
set_property PACKAGE_PIN AR18 [get_ports IIC_MUX_RESET_B_LS]
set_property IOSTANDARD LVCMOS18 [get_ports IIC_MUX_RESET_B_LS]

set_property PACKAGE_PIN AW21 [get_ports SI5328_RST_N_LS]   
set_property IOSTANDARD LVCMOS18 [get_ports SI5328_RST_N_LS] 
######################################################################
#UART/RS232 interface
######################################################################

######################################################################
# MISC IOs
######################################################################
#HMC FAN
set_property PACKAGE_PIN AT21 [get_ports SM_FAN_PWM]
set_property IOSTANDARD LVCMOS18 [get_ports SM_FAN_PWM]

#FPGA FAN
set_property PACKAGE_PIN AT19 [get_ports SM_FAN_TACH]
set_property IOSTANDARD LVCMOS18 [get_ports SM_FAN_TACH]

#LEDs
set_property PACKAGE_PIN N25 [get_ports GPIO_LED_0_LS]
set_property IOSTANDARD LVCMOS12 [get_ports GPIO_LED_0_LS]
set_property PACKAGE_PIN N22 [get_ports GPIO_LED_1_LS]
set_property IOSTANDARD LVCMOS12 [get_ports GPIO_LED_1_LS]
set_property PACKAGE_PIN M22 [get_ports GPIO_LED_2_LS]
set_property IOSTANDARD LVCMOS12 [get_ports GPIO_LED_2_LS]
set_property PACKAGE_PIN M26 [get_ports GPIO_LED_3_LS]
set_property IOSTANDARD LVCMOS12 [get_ports GPIO_LED_3_LS]
set_property PACKAGE_PIN M25 [get_ports GPIO_LED_4_LS]
set_property IOSTANDARD LVCMOS12 [get_ports GPIO_LED_4_LS]
set_property PACKAGE_PIN P24 [get_ports GPIO_LED_5_LS]
set_property IOSTANDARD LVCMOS12 [get_ports GPIO_LED_5_LS]
set_property PACKAGE_PIN N24 [get_ports GPIO_LED_6_LS]
set_property IOSTANDARD LVCMOS12 [get_ports GPIO_LED_6_LS]
set_property PACKAGE_PIN N23 [get_ports GPIO_LED_7_LS]
set_property IOSTANDARD LVCMOS12 [get_ports GPIO_LED_7_LS]

set_property DRIVE 8 [get_ports GPIO_LED_0_LS]
set_property DRIVE 8 [get_ports GPIO_LED_1_LS]
set_property DRIVE 8 [get_ports GPIO_LED_2_LS]
set_property DRIVE 8 [get_ports GPIO_LED_3_LS]
set_property DRIVE 8 [get_ports GPIO_LED_4_LS]
set_property DRIVE 8 [get_ports GPIO_LED_5_LS]
set_property DRIVE 8 [get_ports GPIO_LED_6_LS]
set_property DRIVE 8 [get_ports GPIO_LED_7_LS]

#

######################################################################
#HMC device control
######################################################################
set_property PACKAGE_PIN BA26 [get_ports HMC_REFCLK_BOOT_0]
set_property IOSTANDARD LVCMOS15 [get_ports HMC_REFCLK_BOOT_0]
set_property PACKAGE_PIN BB26 [get_ports HMC_REFCLK_BOOT_1]
set_property IOSTANDARD LVCMOS15 [get_ports HMC_REFCLK_BOOT_1]

set_property PACKAGE_PIN AW28 [get_ports device_p_rst_n]
set_property IOSTANDARD LVCMOS15 [get_ports device_p_rst_n]

set_property PACKAGE_PIN AV30 [get_ports HMC_REFCLK_SEL]
set_property IOSTANDARD LVCMOS15 [get_ports HMC_REFCLK_SEL]

set_property PACKAGE_PIN AW30 [get_ports HMC_FERR_B]
set_property IOSTANDARD LVCMOS15 [get_ports HMC_FERR_B]
set_property PULLUP true [get_ports HMC_FERR_B]

######################################################################
#HMC LINK 0
######################################################################
set_property PACKAGE_PIN R10 [get_ports refclk_n]

set_property PACKAGE_PIN AY30 [get_ports lxtxps]
set_property IOSTANDARD LVCMOS15 [get_ports lxtxps]
set_property PACKAGE_PIN AW27 [get_ports lxrxps]
set_property IOSTANDARD LVCMOS15 [get_ports lxrxps]


