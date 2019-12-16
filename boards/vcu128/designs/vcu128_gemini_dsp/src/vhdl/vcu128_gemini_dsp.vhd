-------------------------------------------------------------------------------
--
-- File Name: vcu128_gemini_dsp.vhd
-- Contributing Authors: Andrew Brown, David Humphrey
-- Type: RTL
-- Created: Thurs Oct 19 16:40:00 2017
-- Template Rev: 1.0
--
-- Title: Top Level of Gemini LRU DSP project
--
-- Description: 
--  Top level for code running on the Xilinx VCU128 test board. 
--
-------------------------------------------------------------------------------

LIBRARY IEEE, UNISIM, common_lib, axi4_lib, technology_lib, util_lib, dsp_top_lib;
LIBRARY vcu128_board_lib, spi_lib, onewire_lib, eth_lib, arp_lib, dhcp_lib, gemini_server_lib, gemini_subscription_lib, ping_protocol_lib;
LIBRARY tech_ddr4_lib, tech_mac_100g_lib, tech_axi4_quadspi_prom_lib, tech_system_monitor_lib, tech_axi4_infrastructure_lib;
library LFAADecode_lib, timingcontrol_lib, capture128bit_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE axi4_lib.axi4_full_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE vcu128_board_lib.ip_pkg.ALL;
USE vcu128_board_lib.board_pkg.ALL;
USE tech_mac_100g_lib.tech_mac_100g_pkg.ALL;

USE work.vcu128_gemini_dsp_bus_pkg.ALL;
USE work.vcu128_gemini_dsp_system_reg_pkg.ALL;
use work.ip_pkg.all;
USE UNISIM.vcomponents.all;


-------------------------------------------------------------------------------
ENTITY vcu128_gemini_dsp IS
    GENERIC (
        g_technology         : t_technology := c_tech_vcu128;
        g_sim                : BOOLEAN := FALSE);
    PORT (
    
        -- Active high user LEDs on the board
        GPIO_LED_0_LS : out std_logic;
        GPIO_LED_1_LS : out std_logic;
        GPIO_LED_2_LS : out std_logic;
        GPIO_LED_3_LS : out std_logic;
        GPIO_LED_4_LS : out std_logic;
        GPIO_LED_5_LS : out std_logic;
        GPIO_LED_6_LS : out std_logic;
        GPIO_LED_7_LS : out std_logic;
        

--        SYSCTLR_GPIO_0_LS : out std_logic;
--        SYSCTLR_GPIO_1_LS : out std_logic;
        
        -- Looks like a loopback for monitoring I2C0_SDA/SCL
        --SYSMON_SDA_LS : inout std_logic;
        --SYSMON_SCL_LS : out std_logic;

        
        -- i2c bus to the QSFPs, goes via multiplexer chip U54 (TCA9548A) (output ports 4,5,6 and 7 for QSFP1 to QSFP4 respectively)
        PL_I2C0_SCL_LS : out std_logic;
        PL_I2C0_SDA_LS : inout std_logic;

        QSFP1_MODPRSL_LS : in std_logic;
        QSFP1_MODSKLL_LS : out std_logic;
        QSFP1_RESETL_LS  : out std_logic;
        QSFP1_INTL_LS    : in std_logic;
        QSFP1_LPMODE_LS  : out std_logic;
        
        QSFP2_MODPRSL_LS : in std_logic;
        QSFP2_MODSKLL_LS : out std_logic;
        QSFP2_RESETL_LS  : out std_logic;
        QSFP2_INTL_LS    : in std_logic;
        QSFP2_LPMODE_LS  : out std_logic;
        
        QSFP3_MODPRSL_LS : in std_logic;
        QSFP3_MODSKLL_LS : out std_logic;
        QSFP3_RESETL_LS  : out std_logic;
        QSFP3_INTL_LS    : in std_logic;
        QSFP3_LPMODE_LS  : out std_logic;
        
        QSFP4_MODPRSL_LS : in std_logic;
        QSFP4_MODSKLL_LS : out std_logic;
        QSFP4_RESETL_LS  : out std_logic;
        QSFP4_INTL_LS    : in std_logic;
        QSFP4_LPMODE_LS  : out std_logic;

        -- QSFP1 - used for 10GE Gemini protocol
        -- Unless programmed otherwise, QSFP1 quad clock defaults to 156.25 MHz  
        QSFP1_SI570_CLOCK_N : in std_logic;
        QSFP1_SI570_CLOCK_P : in std_logic;
        
        QSFP1_RX1_N : in std_logic; -- qsfp1 is used by MACE, but only one GTY is used.
        --QSFP1_RX2_N : in std_logic;
        --QSFP1_RX3_N : in std_logic;
        --QSFP1_RX4_N : in std_logic;
        QSFP1_RX1_P : in std_logic;
        --QSFP1_RX2_P : in std_logic;
        --QSFP1_RX3_P : in std_logic;
        --QSFP1_RX4_P : in std_logic;
        
        QSFP1_TX1_N : out std_logic;
        --QSFP1_TX2_N : out std_logic;
        --QSFP1_TX3_N : out std_logic;
        --QSFP1_TX4_N : out std_logic;
        QSFP1_TX1_P : out std_logic;
        --QSFP1_TX2_P : out std_logic;
        --QSFP1_TX3_P : out std_logic;
        --QSFP1_TX4_P : out std_logic;

        -- QSFP4 used for 40GE LFAA input
        -- Unless programmed otherwise, QSFP4 quad clock defaults to 156.25 MHz  
        QSFP4_SI570_CLOCK_N : in std_logic;
        QSFP4_SI570_CLOCK_P : in std_logic;
        
        QSFP4_RX1_N : in std_logic;
        QSFP4_RX2_N : in std_logic;
        QSFP4_RX3_N : in std_logic;
        QSFP4_RX4_N : in std_logic;
        QSFP4_RX1_P : in std_logic;
        QSFP4_RX2_P : in std_logic;
        QSFP4_RX3_P : in std_logic;
        QSFP4_RX4_P : in std_logic;
        
        QSFP4_TX1_N : out std_logic;
        QSFP4_TX2_N : out std_logic;
        QSFP4_TX3_N : out std_logic;
        QSFP4_TX4_N : out std_logic;
        QSFP4_TX1_P : out std_logic;
        QSFP4_TX2_P : out std_logic;
        QSFP4_TX3_P : out std_logic;
        QSFP4_TX4_P : out std_logic;

        -- QSFP2 - 4x25GE interfaces
        QSFP2_SI570_CLOCK_N : in std_logic;  -- defaults to 156.25 MHz
        QSFP2_SI570_CLOCK_P : in std_logic;
        QSFP2_RX1_N : in std_logic;
        QSFP2_RX2_N : in std_logic;
        QSFP2_RX3_N : in std_logic;
        QSFP2_RX4_N : in std_logic;
        QSFP2_RX1_P : in std_logic;
        QSFP2_RX2_P : in std_logic;
        QSFP2_RX3_P : in std_logic;
        QSFP2_RX4_P : in std_logic;
        QSFP2_TX1_N : out std_logic;
        QSFP2_TX2_N : out std_logic;
        QSFP2_TX3_N : out std_logic;
        QSFP2_TX4_N : out std_logic;
        QSFP2_TX1_P : out std_logic;
        QSFP2_TX2_P : out std_logic;
        QSFP2_TX3_P : out std_logic;
        QSFP2_TX4_P : out std_logic;
        -- QSFP3 - 100GE interface
        QSFP3_SI570_CLOCK_N : in std_logic;  -- defaults to 156.25 MHz
        QSFP3_SI570_CLOCK_P : in std_logic;
        QSFP3_RX1_N : in std_logic;
        QSFP3_RX2_N : in std_logic;
        QSFP3_RX3_N : in std_logic;
        QSFP3_RX4_N : in std_logic;
        QSFP3_RX1_P : in std_logic;
        QSFP3_RX2_P : in std_logic;
        QSFP3_RX3_P : in std_logic;
        QSFP3_RX4_P : in std_logic;
        QSFP3_TX1_N : out std_logic;
        QSFP3_TX2_N : out std_logic;
        QSFP3_TX3_N : out std_logic;
        QSFP3_TX4_N : out std_logic;
        QSFP3_TX1_P : out std_logic;
        QSFP3_TX2_P : out std_logic;
        QSFP3_TX3_P : out std_logic;
        QSFP3_TX4_P : out std_logic;

        -- -- jitter attenuated recovered clock; (used for synchronous protocols like CPRI)
        --QSFP1_RECCLK_N
        --QSFP1_RECCLK_P
        --QSFP2_RECCLK_N
        --QSFP2_RECCLK_P

        -- -- UARTs are connected to FTDI FT4232HL, which allows connection via USB 
        --UART0_RXD : in std_logic;
        --UART0_TXD : out std_logic;
        --UART0_RTS_B : in std_logic;
        --UART0_CTS_B : out std_logic;
        --UART1_RXD : in std_logic;
        --UART1_TXD : out std_logic;
        --UART1_RTS_B : in std_logic;
        --UART1_CTS_B : out std_logic;
        -- -- goes to the USB chip D port, not sure what it is used for.
        --SYSCTLR_UCA1_TX : out std_logic;
        --SYSCTLR_UCA1_RX : in std_logic;

        
        -- -- 1GE connector 
        --ENET_PDWN_B_I_INT_B_O  : in std_logic;
        --ENET_SGMII_IN_N : in std_logic;
        --ENET_SGMII_IN_P : in std_logic;
        --ENET_SGMII_OUT_N : out std_logic;
        --ENET_SGMII_OUT_P : out std_logic;
        --ENET_MDC : in std_logic;
        --ENET_COL_GPIO : in std_logic;
        --ENET_MDIO : in std_logic;
        --ENET_CLKOUT : out std_logic;
        --ENET_SGMII_CLK_N : in std_logic;
        --ENET_SGMII_CLK_P : in std_logic;


        -- WARNING : CHECK port directions before enabling commented ports.
        --SMA_CLK_OUTPUT_N : out std_logic;
        --SMA_CLK_OUTPUT_P : out std_logic;
        --DUMMY_NC : out std_logic;
        DDR4_CLK_100MHZ_N : in std_logic;     -- This is used as a general purpose clock 
        DDR4_CLK_100MHZ_P : in std_logic
        --PL_DDR4_BOT_CS_B : inout std_logic;
        --PL_DDR4_PARITY : inout std_logic;
        --PL_DDR4_CS_B : inout std_logic;
        --PL_DDR4_A0 : out std_logic;
        --PL_DDR4_A1 : out std_logic;
        --PL_DDR4_A2 : out std_logic;
        --PL_DDR4_A3 : out std_logic;
        --PL_DDR4_A4 : out std_logic;
        --PL_DDR4_A5 : out std_logic;
        --PL_DDR4_A6 : out std_logic;
        --PL_DDR4_A7 : out std_logic;
        --PL_DDR4_A8 : out std_logic;
        --PL_DDR4_A9 : out std_logic;
        --PL_DDR4_A10 : out std_logic;
        --PL_DDR4_A11 : out std_logic;
        --PL_DDR4_A12 : out std_logic;
        --PL_DDR4_A13 : out std_logic;
        --PL_DDR4_BA0 : out std_logic;
        --PL_DDR4_BA1 : out std_logic;
        --PL_DDR4_BG0 : out std_logic;
        --PL_DDR4_WE_B : out std_logic;
        --PL_DDR4_RAS_B : out std_logic;
        --PL_DDR4_CAS_B : out std_logic;
        --PL_DDR4_CK0_C : out std_logic;
        --PL_DDR4_CK0_T : out std_logic;
        --PL_DDR4_CKE : out std_logic;
        --PL_DDR4_ACT_B : out std_logic;
        --PL_DDR4_TEN : out std_logic;
        --PL_DDR4_ALERT_B : out std_logic;
        --PL_DDR4_RESET_B : out std_logic;
        --PL_DDR4_ODT : out std_logic;
        --PL_DDR4_DQS0_C : out std_logic;
        --PL_DDR4_DQS0_T : out std_logic;
        --PL_DDR4_DQS1_C : out std_logic;
        --PL_DDR4_DQS1_T : out std_logic;
        --PL_DDR4_DQS2_C : out std_logic;
        --PL_DDR4_DQS2_T : out std_logic;
        --PL_DDR4_DQS3_C : out std_logic;
        --PL_DDR4_DQS3_T : out std_logic;
        --PL_DDR4_DQS4_C : out std_logic;
        --PL_DDR4_DQS4_T : out std_logic;
        --PL_DDR4_DQS5_C : out std_logic;
        --PL_DDR4_DQS5_T : out std_logic;
        --PL_DDR4_DQS6_C : out std_logic;
        --PL_DDR4_DQS6_T : out std_logic;
        --PL_DDR4_DQS7_C : out std_logic;
        --PL_DDR4_DQS7_T : out std_logic;
        --PL_DDR4_DQS8_C : out std_logic;
        --PL_DDR4_DQS8_T : out std_logic;
        --PL_DDR4_DM0_B : out std_logic;
        --PL_DDR4_DM1_B : out std_logic;
        --PL_DDR4_DM2_B : out std_logic;
        --PL_DDR4_DM3_B : out std_logic;
        --PL_DDR4_DM4_B : out std_logic;
        --PL_DDR4_DM5_B : out std_logic;
        --PL_DDR4_DM6_B : out std_logic;
        --PL_DDR4_DM7_B : out std_logic;
        --PL_DDR4_DM8_B : out std_logic;
        --PL_DDR4_DQ0 : inout std_logic;
        --PL_DDR4_DQ1 : inout std_logic;
        --PL_DDR4_DQ2 : inout std_logic;
        --PL_DDR4_DQ3 : inout std_logic;
        --PL_DDR4_DQ4 : inout std_logic;
        --PL_DDR4_DQ5 : inout std_logic;
        --PL_DDR4_DQ6 : inout std_logic;
        --PL_DDR4_DQ7 : inout std_logic;
        --PL_DDR4_DQ8 : inout std_logic;
        --PL_DDR4_DQ9 : inout std_logic;
        --PL_DDR4_DQ10 : inout std_logic;
        --PL_DDR4_DQ11 : inout std_logic;
        --PL_DDR4_DQ12 : inout std_logic;
        --PL_DDR4_DQ13 : inout std_logic;
        --PL_DDR4_DQ14 : inout std_logic;
        --PL_DDR4_DQ15 : inout std_logic;
        --PL_DDR4_DQ16 : inout std_logic;
        --PL_DDR4_DQ17 : inout std_logic;
        --PL_DDR4_DQ18 : inout std_logic;
        --PL_DDR4_DQ19 : inout std_logic;
        --PL_DDR4_DQ20 : inout std_logic;
        --PL_DDR4_DQ21 : inout std_logic;
        --PL_DDR4_DQ22 : inout std_logic;
        --PL_DDR4_DQ23 : inout std_logic;
        --PL_DDR4_DQ24 : inout std_logic;
        --PL_DDR4_DQ25 : inout std_logic;
        --PL_DDR4_DQ26 : inout std_logic;
        --PL_DDR4_DQ27 : inout std_logic;
        --PL_DDR4_DQ28 : inout std_logic;
        --PL_DDR4_DQ29 : inout std_logic;
        --PL_DDR4_DQ30 : inout std_logic;
        --PL_DDR4_DQ31 : inout std_logic;
        --PL_DDR4_DQ32 : inout std_logic;
        --PL_DDR4_DQ33 : inout std_logic;
        --PL_DDR4_DQ34 : inout std_logic;
        --PL_DDR4_DQ35 : inout std_logic;
        --PL_DDR4_DQ36 : inout std_logic;
        --PL_DDR4_DQ37 : inout std_logic;
        --PL_DDR4_DQ38 : inout std_logic;
        --PL_DDR4_DQ39 : inout std_logic;
        --PL_DDR4_DQ40 : inout std_logic;
        --PL_DDR4_DQ41 : inout std_logic;
        --PL_DDR4_DQ42 : inout std_logic;
        --PL_DDR4_DQ43 : inout std_logic;
        --PL_DDR4_DQ44 : inout std_logic;
        --PL_DDR4_DQ45 : inout std_logic;
        --PL_DDR4_DQ46 : inout std_logic;
        --PL_DDR4_DQ47 : inout std_logic;
        --PL_DDR4_DQ48 : inout std_logic;
        --PL_DDR4_DQ49 : inout std_logic;
        --PL_DDR4_DQ50 : inout std_logic;
        --PL_DDR4_DQ51 : inout std_logic;
        --PL_DDR4_DQ52 : inout std_logic;
        --PL_DDR4_DQ53 : inout std_logic;
        --PL_DDR4_DQ54 : inout std_logic;
        --PL_DDR4_DQ55 : inout std_logic;
        --PL_DDR4_DQ56 : inout std_logic;
        --PL_DDR4_DQ57 : inout std_logic;
        --PL_DDR4_DQ58 : inout std_logic;
        --PL_DDR4_DQ59 : inout std_logic;
        --PL_DDR4_DQ60 : inout std_logic;
        --PL_DDR4_DQ61 : inout std_logic;
        --PL_DDR4_DQ62 : inout std_logic;
        --PL_DDR4_DQ63 : inout std_logic;
        --PL_DDR4_DQ64 : inout std_logic;
        --PL_DDR4_DQ65 : inout std_logic;
        --PL_DDR4_DQ66 : inout std_logic;
        --PL_DDR4_DQ67 : inout std_logic;
        --PL_DDR4_DQ68 : inout std_logic;
        --PL_DDR4_DQ69 : inout std_logic;
        --PL_DDR4_DQ70 : inout std_logic;
        --PL_DDR4_DQ71 : inout std_logic;
        --CPU_RESET : out std_logic;
        --FMCP_HSPC_LA18_CC_N : inout std_logic;
        --FMCP_HSPC_LA18_CC_P : inout std_logic;
        --FMCP_HSPC_LA17_CC_N : inout std_logic;
        --FMCP_HSPC_LA17_CC_P : inout std_logic;
        --FMCP_HSPC_CLK1_M2C_N : inout std_logic;
        --FMCP_HSPC_CLK1_M2C_P : inout std_logic;
        --FMCP_HSPC_LA19_N : inout std_logic;
        --FMCP_HSPC_LA19_P : inout std_logic;
        --FMCP_HSPC_LA20_N : inout std_logic;
        --FMCP_HSPC_LA20_P : inout std_logic;
        --FMCP_HSPC_LA21_N : inout std_logic;
        --FMCP_HSPC_LA21_P : inout std_logic;
        --FMCP_HSPC_LA22_N : inout std_logic;
        --FMCP_HSPC_LA22_P : inout std_logic;
        --FMCP_HSPC_LA23_N : inout std_logic;
        --FMCP_HSPC_LA23_P : inout std_logic;
        --FMCP_HSPC_LA24_N : inout std_logic;
        --FMCP_HSPC_LA24_P : inout std_logic;
        --FMCP_HSPC_LA25_N : inout std_logic;
        --FMCP_HSPC_LA25_P : inout std_logic;
        --FMCP_HSPC_LA26_N : inout std_logic;
        --FMCP_HSPC_LA26_P : inout std_logic;
        --FMCP_HSPC_LA27_N : inout std_logic;
        --FMCP_HSPC_LA27_P : inout std_logic;
        --FMCP_HSPC_LA28_N : inout std_logic;
        --FMCP_HSPC_LA28_P : inout std_logic;
        --FMCP_HSPC_LA29_N : inout std_logic;
        --FMCP_HSPC_LA29_P : inout std_logic;
        --FMCP_HSPC_LA30_N : inout std_logic;
        --FMCP_HSPC_LA30_P : inout std_logic;
        --FMCP_HSPC_LA31_N : inout std_logic;
        --FMCP_HSPC_LA31_P : inout std_logic;
        --FMCP_HSPC_LA32_N : inout std_logic;
        --FMCP_HSPC_LA32_P : inout std_logic;
        --FMCP_HSPC_LA33_N : inout std_logic;
        --FMCP_HSPC_LA33_P : inout std_logic;
        --SMA_REFCLK_INPUT_N : in std_logic;
        --SMA_REFCLK_INPUT_P : in std_logic;
        --SI5328_CLOCK2_C_N : in std_logic;
        --SI5328_CLOCK2_C_P : in std_logic;
        --SI5328_CLOCK1_C_N : in std_logic;
        --SI5328_CLOCK1_C_P : in std_logic;
        --N22119065 : in std_logic;
        --SI5328_INT_ALM_LS : in std_logic;
        --QDR4_DQB0 : inout std_logic;
        --QDR4_DQB1 : inout std_logic;
        --QDR4_DQB2 : inout std_logic;
        --QDR4_DQB3 : inout std_logic;
        --QDR4_DQB4 : inout std_logic;
        --QDR4_DQB5 : inout std_logic;
        --QDR4_DQB6 : inout std_logic;
        --QDR4_DQB7 : inout std_logic;
        --QDR4_DQB8 : inout std_logic;
        --QDR4_DQB9 : inout std_logic;
        --QDR4_DQB10 : inout std_logic;
        --QDR4_DQB11 : inout std_logic;
        --QDR4_DQB12 : inout std_logic;
        --QDR4_DQB13 : inout std_logic;
        --QDR4_DQB14 : inout std_logic;
        --QDR4_DQB15 : inout std_logic;
        --QDR4_DQB16 : inout std_logic;
        --QDR4_DQB17 : inout std_logic;
        --QDR4_DQB18 : inout std_logic;
        --QDR4_DQB19 : inout std_logic;
        --QDR4_DQB20 : inout std_logic;
        --QDR4_DQB21 : inout std_logic;
        --QDR4_DQB22 : inout std_logic;
        --QDR4_DQB23 : inout std_logic;
        --QDR4_DQB24 : inout std_logic;
        --QDR4_DQB25 : inout std_logic;
        --QDR4_DQB26 : inout std_logic;
        --QDR4_DQB27 : inout std_logic;
        --QDR4_DQB28 : inout std_logic;
        --QDR4_DQB29 : inout std_logic;
        --QDR4_DQB30 : inout std_logic;
        --QDR4_DQB31 : inout std_logic;
        --QDR4_DQB32 : inout std_logic;
        --QDR4_DQB33 : inout std_logic;
        --QDR4_DQB34 : inout std_logic;
        --QDR4_DQB35 : inout std_logic;
        --QDR4_DKB1_N : inout std_logic;
        --QDR4_DKB1_P : inout std_logic;
        --QDR4_QVLDB1 : inout std_logic;
        --QDR4_QKB1_N : inout std_logic;
        --QDR4_QKB1_P : inout std_logic;
        --QDR4_QVLDB0 : inout std_logic;
        --QDR4_QKB0_N : inout std_logic;
        --QDR4_QKB0_P : inout std_logic;
        --QDR4_DKB0_N : inout std_logic;
        --QDR4_DKB0_P : inout std_logic;
        --QDR4_A0 : out std_logic;
        --QDR4_A1 : out std_logic;
        --QDR4_A2 : out std_logic;
        --QDR4_A3 : out std_logic;
        --QDR4_A4 : out std_logic;
        --QDR4_A5 : out std_logic;
        --QDR4_A6 : out std_logic;
        --QDR4_A7 : out std_logic;
        --QDR4_A8 : out std_logic;
        --QDR4_A9 : out std_logic;
        --QDR4_A10 : out std_logic;
        --QDR4_A11 : out std_logic;
        --QDR4_A12 : out std_logic;
        --QDR4_A13 : out std_logic;
        --QDR4_A14 : out std_logic;
        --QDR4_A15 : out std_logic;
        --QDR4_A16 : out std_logic;
        --QDR4_A17 : out std_logic;
        --QDR4_A18 : out std_logic;
        --QDR4_A19 : out std_logic;
        --QDR4_A20 : out std_logic;
        --QDR4_A21 : out std_logic;
        --QDR4_A22 : out std_logic;
        --QDR4_A23 : out std_logic;
        --QDR4_A24 : out std_logic;
        --QDR4_CK_N : out std_logic;
        --QDR4_CK_P : out std_logic;
        --QDR4_CLK_100MHZ_N : in std_logic;
        --QDR4_CLK_100MHZ_P : in std_logic;
        --QDR4_PE_N : in std_logic;
        --QDR4_LBK0_N : in std_logic;
        --QDR4_LBK1_N : in std_logic;
        --QDR4_CFG_N : in std_logic;
        --QDR4_RST_N : in std_logic;
        --QDR4_AINV : in std_logic;
        --QDR4_LDB_N : in std_logic;
        --QDR4_RWB_N : in std_logic;
        --QDR4_AP : in std_logic;
        --QDR4_LDA_N : in std_logic;
        --QDR4_RWA_N : in std_logic;
        --QDR4_DQA0 : out std_logic;
        --QDR4_DQA1 : out std_logic;
        --QDR4_DQA2 : out std_logic;
        --QDR4_DQA3 : out std_logic;
        --QDR4_DQA4 : out std_logic;
        --QDR4_DQA5 : out std_logic;
        --QDR4_DQA6 : out std_logic;
        --QDR4_DQA7 : out std_logic;
        --QDR4_DQA8 : out std_logic;
        --QDR4_DQA9 : out std_logic;
        --QDR4_DQA10 : out std_logic;
        --QDR4_DQA11 : out std_logic;
        --QDR4_DQA12 : out std_logic;
        --QDR4_DQA13 : out std_logic;
        --QDR4_DQA14 : out std_logic;
        --QDR4_DQA15 : out std_logic;
        --QDR4_DQA16 : out std_logic;
        --QDR4_DQA17 : out std_logic;
        --QDR4_DQA18 : out std_logic;
        --QDR4_DQA19 : out std_logic;
        --QDR4_DQA20 : out std_logic;
        --QDR4_DQA21 : out std_logic;
        --QDR4_DQA22 : out std_logic;
        --QDR4_DQA23 : out std_logic;
        --QDR4_DQA24 : out std_logic;
        --QDR4_DQA25 : out std_logic;
        --QDR4_DQA26 : out std_logic;
        --QDR4_DQA27 : out std_logic;
        --QDR4_DQA28 : out std_logic;
        --QDR4_DQA29 : out std_logic;
        --QDR4_DQA30 : out std_logic;
        --QDR4_DQA31 : out std_logic;
        --QDR4_DQA32 : out std_logic;
        --QDR4_DQA33 : out std_logic;
        --QDR4_DQA34 : out std_logic;
        --QDR4_DQA35 : out std_logic;
        --QDR4_QVLDA1 : out std_logic;
        --QDR4_DKA1_N : out std_logic;
        --QDR4_DKA1_P : out std_logic;
        --QDR4_QKA1_N : out std_logic;
        --QDR4_QKA1_P : out std_logic;
        --QDR4_QVLDA0 : out std_logic;
        --QDR4_DKA0_N : out std_logic;
        --QDR4_DKA0_P : out std_logic;
        --QDR4_QKA0_N : out std_logic;
        --QDR4_QKA0_P : out std_logic;
        --PMBUS_ALERT_B_LS : inout std_logic;
        --SI5328_RST_B_LS : out std_logic;
        --RLD3_72B_DQ0 : inout std_logic;
        --RLD3_72B_DQ1 : inout std_logic;
        --RLD3_72B_DQ2 : inout std_logic;
        --RLD3_72B_DQ3 : inout std_logic;
        --RLD3_72B_DQ4 : inout std_logic;
        --RLD3_72B_DQ5 : inout std_logic;
        --RLD3_72B_DQ6 : inout std_logic;
        --RLD3_72B_DQ7 : inout std_logic;
        --RLD3_72B_DQ8 : inout std_logic;
        --RLD3_72B_DQ9 : inout std_logic;
        --RLD3_72B_DQ10 : inout std_logic;
        --RLD3_72B_DQ11 : inout std_logic;
        --RLD3_72B_DQ12 : inout std_logic;
        --RLD3_72B_DQ13 : inout std_logic;
        --RLD3_72B_DQ14 : inout std_logic;
        --RLD3_72B_DQ15 : inout std_logic;
        --RLD3_72B_DQ16 : inout std_logic;
        --RLD3_72B_DQ17 : inout std_logic;
        --RLD3_72B_DQ18 : inout std_logic;
        --RLD3_72B_DQ19 : inout std_logic;
        --RLD3_72B_DQ20 : inout std_logic;
        --RLD3_72B_DQ21 : inout std_logic;
        --RLD3_72B_DQ22 : inout std_logic;
        --RLD3_72B_DQ23 : inout std_logic;
        --RLD3_72B_DQ24 : inout std_logic;
        --RLD3_72B_DQ25 : inout std_logic;
        --RLD3_72B_DQ26 : inout std_logic;
        --RLD3_72B_DQ27 : inout std_logic;
        --RLD3_72B_DQ28 : inout std_logic;
        --RLD3_72B_DQ29 : inout std_logic;
        --RLD3_72B_DQ30 : inout std_logic;
        --RLD3_72B_DQ31 : inout std_logic;
        --RLD3_72B_DQ32 : inout std_logic;
        --RLD3_72B_DQ33 : inout std_logic;
        --RLD3_72B_DQ34 : inout std_logic;
        --RLD3_72B_DQ35 : inout std_logic;
        --RLD3_72B_DQ36 : inout std_logic;
        --RLD3_72B_DQ37 : inout std_logic;
        --RLD3_72B_DQ38 : inout std_logic;
        --RLD3_72B_DQ39 : inout std_logic;
        --RLD3_72B_DQ40 : inout std_logic;
        --RLD3_72B_DQ41 : inout std_logic;
        --RLD3_72B_DQ42 : inout std_logic;
        --RLD3_72B_DQ43 : inout std_logic;
        --RLD3_72B_DQ44 : inout std_logic;
        --RLD3_72B_DQ45 : inout std_logic;
        --RLD3_72B_DQ46 : inout std_logic;
        --RLD3_72B_DQ47 : inout std_logic;
        --RLD3_72B_DQ48 : inout std_logic;
        --RLD3_72B_DQ49 : inout std_logic;
        --RLD3_72B_DQ50 : inout std_logic;
        --RLD3_72B_DQ51 : inout std_logic;
        --RLD3_72B_DQ52 : inout std_logic;
        --RLD3_72B_DQ53 : inout std_logic;
        --RLD3_72B_DQ54 : inout std_logic;
        --RLD3_72B_DQ55 : inout std_logic;
        --RLD3_72B_DQ56 : inout std_logic;
        --RLD3_72B_DQ57 : inout std_logic;
        --RLD3_72B_DQ58 : inout std_logic;
        --RLD3_72B_DQ59 : inout std_logic;
        --RLD3_72B_DQ60 : inout std_logic;
        --RLD3_72B_DQ61 : inout std_logic;
        --RLD3_72B_DQ62 : inout std_logic;
        --RLD3_72B_DQ63 : inout std_logic;
        --RLD3_72B_DQ64 : inout std_logic;
        --RLD3_72B_DQ65 : inout std_logic;
        --RLD3_72B_DQ66 : inout std_logic;
        --RLD3_72B_DQ67 : inout std_logic;
        --RLD3_72B_DQ68 : inout std_logic;
        --RLD3_72B_DQ69 : inout std_logic;
        --RLD3_72B_DQ70 : inout std_logic;
        --RLD3_72B_DQ71 : inout std_logic;
        --RLD3_72B_QK0_N : inout std_logic;
        --RLD3_72B_QK0_P : inout std_logic;
        --RLD3_72B_QK1_N : inout std_logic;
        --RLD3_72B_QK1_P : inout std_logic;
        --RLD3_72B_QK2_N : inout std_logic;
        --RLD3_72B_QK2_P : inout std_logic;
        --RLD3_72B_QK3_N : inout std_logic;
        --RLD3_72B_QK3_P : inout std_logic;
        --RLD3_72B_QK4_N : inout std_logic;
        --RLD3_72B_QK4_P : inout std_logic;
        --RLD3_72B_QK5_N : inout std_logic;
        --RLD3_72B_QK5_P : inout std_logic;
        --RLD3_72B_QK6_N : inout std_logic;
        --RLD3_72B_QK6_P : inout std_logic;
        --RLD3_72B_QK7_N : inout std_logic;
        --RLD3_72B_QK7_P : inout std_logic;
        --RLD3_72B_QVLD0 : inout std_logic;
        --RLD3_72B_QVLD1 : inout std_logic;
        --RLD3_72B_QVLD2 : inout std_logic;
        --RLD3_72B_QVLD3 : inout std_logic;
        --RLD3_72B_DM0 : inout std_logic;
        --RLD3_72B_DM1 : inout std_logic;
        --RLD3_72B_DM2 : inout std_logic;
        --RLD3_72B_DM3 : inout std_logic;
        --RLD3_72B_A0 : out std_logic;
        --RLD3_72B_A1 : out std_logic;
        --RLD3_72B_A2 : out std_logic;
        --RLD3_72B_A3 : out std_logic;
        --RLD3_72B_A4 : out std_logic;
        --RLD3_72B_A5 : out std_logic;
        --RLD3_72B_A6 : out std_logic;
        --RLD3_72B_A7 : out std_logic;
        --RLD3_72B_A8 : out std_logic;
        --RLD3_72B_A9 : out std_logic;
        --RLD3_72B_A10 : out std_logic;
        --RLD3_72B_A11 : out std_logic;
        --RLD3_72B_A12 : out std_logic;
        --RLD3_72B_A13 : out std_logic;
        --RLD3_72B_A14 : out std_logic;
        --RLD3_72B_A15 : out std_logic;
        --RLD3_72B_A16 : out std_logic;
        --RLD3_72B_A17 : out std_logic;
        --RLD3_72B_A18 : out std_logic;
        --RLD3_72B_A19 : out std_logic;
        --RLD3_72B_A20 : out std_logic;
        --RLD3_72B_CS_B : out std_logic;
        --RLD3_72B_BA0 : out std_logic;
        --RLD3_72B_BA1 : out std_logic;
        --RLD3_72B_BA2 : out std_logic;
        --RLD3_72B_BA3 : out std_logic;
        --RLD3_72B_RESET_B : out std_logic;
        --RLD3_72B_WE_B : out std_logic;
        --RLD3_72B_REF_B : out std_logic;
        --RLD3_CLK_100MHZ_N: in std_logic;
        --RLD3_CLK_100MHZ_P : in std_logic;
        --RLD3_72B_CK_N : in std_logic;
        --RLD3_72B_CK_P : in std_logic;
        --RLD3_72B_DK0_N : out std_logic;
        --RLD3_72B_DK0_P : out std_logic;
        --RLD3_72B_DK1_N : out std_logic;
        --RLD3_72B_DK1_P : out std_logic;
        --RLD3_72B_DK2_N : out std_logic;
        --RLD3_72B_DK2_P : out std_logic;
        --RLD3_72B_DK3_N : out std_logic;
        --RLD3_72B_DK3_P : out std_logic;
        --VRP_74 : in std_logic;
        --   set_property PACKAGE_PIN A24             [get_ports "FMCP_HSPC_LA13_N"] ;# Bank  72 VCCO - VADJ     - IO_L24N_T3U_N11_72
        --   set_property PACKAGE_PIN A25      [get_ports "FMCP_HSPC_LA13_P"] ;# Bank  72 VCCO - VADJ     - IO_L24P_T3U_N10_72
        --   set_property PACKAGE_PIN A26      [get_ports "FMCP_HSPC_LA03_N"] ;# Bank  72 VCCO - VADJ     - IO_L23N_T3U_N9_72
        --   set_property PACKAGE_PIN B27      [get_ports "FMCP_HSPC_LA03_P"] ;# Bank  72 VCCO - VADJ     - IO_L23P_T3U_N8_72
        --   set_property PACKAGE_PIN A23      [get_ports "FMCP_HSPC_LA10_N"] ;# Bank  72 VCCO - VADJ     - IO_L22N_T3U_N7_DBC_AD0N_72
        --   set_property PACKAGE_PIN B23      [get_ports "FMCP_HSPC_LA10_P"] ;# Bank  72 VCCO - VADJ     - IO_L22P_T3U_N6_DBC_AD0P_72
        --   set_property PACKAGE_PIN B25      [get_ports "FMCP_HSPC_LA11_N"] ;# Bank  72 VCCO - VADJ     - IO_L21N_T3L_N5_AD8N_72
        --   set_property PACKAGE_PIN B26      [get_ports "FMCP_HSPC_LA11_P"] ;# Bank  72 VCCO - VADJ     - IO_L21P_T3L_N4_AD8P_72
        --   set_property PACKAGE_PIN C24      [get_ports "FMCP_HSPC_LA04_N"] ;# Bank  72 VCCO - VADJ     - IO_L20N_T3L_N3_AD1N_72
        --   set_property PACKAGE_PIN C25      [get_ports "FMCP_HSPC_LA04_P"] ;# Bank  72 VCCO - VADJ     - IO_L20P_T3L_N2_AD1P_72
        --   set_property PACKAGE_PIN B22      [get_ports "FMCP_HSPC_LA14_N"] ;# Bank  72 VCCO - VADJ     - IO_L19N_T3L_N1_DBC_AD9N_72
        --   set_property PACKAGE_PIN C23      [get_ports "FMCP_HSPC_LA14_P"] ;# Bank  72 VCCO - VADJ     - IO_L19P_T3L_N0_DBC_AD9P_72
        --   set_property PACKAGE_PIN D27      [get_ports "FMCP_HSPC_LA08_N"] ;# Bank  72 VCCO - VADJ     - IO_L18N_T2U_N11_AD2N_72
        --   set_property PACKAGE_PIN E27      [get_ports "FMCP_HSPC_LA08_P"] ;# Bank  72 VCCO - VADJ     - IO_L18P_T2U_N10_AD2P_72
        --   set_property PACKAGE_PIN D26      [get_ports "FMCP_HSPC_LA09_N"] ;# Bank  72 VCCO - VADJ     - IO_L17N_T2U_N9_AD10N_72
        --   set_property PACKAGE_PIN E26      [get_ports "FMCP_HSPC_LA09_P"] ;# Bank  72 VCCO - VADJ     - IO_L17P_T2U_N8_AD10P_72
        --   set_property PACKAGE_PIN D24      [get_ports "FMCP_HSPC_SYNC_C2M_N"] ;# Bank  72 VCCO - VADJ     - IO_L16N_T2U_N7_QBC_AD3N_72
        --   set_property PACKAGE_PIN D25      [get_ports "FMCP_HSPC_SYNC_C2M_P"] ;# Bank  72 VCCO - VADJ     - IO_L16P_T2U_N6_QBC_AD3P_72
        --   set_property PACKAGE_PIN D22      [get_ports "FMCP_HSPC_LA06_N"] ;# Bank  72 VCCO - VADJ     - IO_L15N_T2L_N5_AD11N_72
        --   set_property PACKAGE_PIN E22      [get_ports "FMCP_HSPC_LA06_P"] ;# Bank  72 VCCO - VADJ     - IO_L15P_T2L_N4_AD11P_72
        --   set_property PACKAGE_PIN F25      [get_ports "FMCP_HSPC_LA01_CC_N"] ;# Bank  72 VCCO - VADJ     - IO_L14N_T2L_N3_GC_72
        --   set_property PACKAGE_PIN F26      [get_ports "FMCP_HSPC_LA01_CC_P"] ;# Bank  72 VCCO - VADJ     - IO_L14P_T2L_N2_GC_72
        --   set_property PACKAGE_PIN E23      [get_ports "FMCP_HSPC_LA00_CC_N"] ;# Bank  72 VCCO - VADJ     - IO_L13N_T2L_N1_GC_QBC_72
        --   set_property PACKAGE_PIN E24      [get_ports "FMCP_HSPC_LA00_CC_P"] ;# Bank  72 VCCO - VADJ     - IO_L13P_T2L_N0_GC_QBC_72
        --   set_property PACKAGE_PIN G25      [get_ports "FMCP_HSPC_REFCLK_M2C_N"] ;# Bank  72 VCCO - VADJ     - IO_L12N_T1U_N11_GC_72
        --   set_property PACKAGE_PIN G26      [get_ports "FMCP_HSPC_REFCLK_M2C_P"] ;# Bank  72 VCCO - VADJ     - IO_L12P_T1U_N10_GC_72
        --   set_property PACKAGE_PIN F23      [get_ports "FMCP_HSPC_CLK0_M2C_N"] ;# Bank  72 VCCO - VADJ     - IO_L11N_T1U_N9_GC_72
        --   set_property PACKAGE_PIN F24      [get_ports "FMCP_HSPC_CLK0_M2C_P"] ;# Bank  72 VCCO - VADJ     - IO_L11P_T1U_N8_GC_72
        --   set_property PACKAGE_PIN G22      [get_ports "FMCP_HSPC_SYNC_M2C_N"] ;# Bank  72 VCCO - VADJ     - IO_L10N_T1U_N7_QBC_AD4N_72
        --   set_property PACKAGE_PIN G23      [get_ports "FMCP_HSPC_SYNC_M2C_P"] ;# Bank  72 VCCO - VADJ     - IO_L10P_T1U_N6_QBC_AD4P_72
        --   set_property PACKAGE_PIN G27      [get_ports "FMCP_HSPC_LA05_N"] ;# Bank  72 VCCO - VADJ     - IO_L9N_T1L_N5_AD12N_72
        --   set_property PACKAGE_PIN H27      [get_ports "FMCP_HSPC_LA05_P"] ;# Bank  72 VCCO - VADJ     - IO_L9P_T1L_N4_AD12P_72
        --   set_property PACKAGE_PIN H22      [get_ports "FMCP_HSPC_LA12_N"] ;# Bank  72 VCCO - VADJ     - IO_L8N_T1L_N3_AD5N_72
        --   set_property PACKAGE_PIN J22      [get_ports "FMCP_HSPC_LA12_P"] ;# Bank  72 VCCO - VADJ     - IO_L8P_T1L_N2_AD5P_72
        --   set_property PACKAGE_PIN H23      [get_ports "FMCP_HSPC_REFCLK_C2M_N"] ;# Bank  72 VCCO - VADJ     - IO_L7N_T1L_N1_QBC_AD13N_72
        --   set_property PACKAGE_PIN H24      [get_ports "FMCP_HSPC_REFCLK_C2M_P"] ;# Bank  72 VCCO - VADJ     - IO_L7P_T1L_N0_QBC_AD13P_72
        --   set_property PACKAGE_PIN J25      [get_ports "FMCP_HSPC_LA15_N"] ;# Bank  72 VCCO - VADJ     - IO_L6N_T0U_N11_AD6N_72
        --   set_property PACKAGE_PIN J26      [get_ports "FMCP_HSPC_LA15_P"] ;# Bank  72 VCCO - VADJ     - IO_L6P_T0U_N10_AD6P_72
        --   set_property PACKAGE_PIN J27      [get_ports "FMCP_HSPC_LA07_N"] ;# Bank  72 VCCO - VADJ     - IO_L5N_T0U_N9_AD14N_72
        --   set_property PACKAGE_PIN K27      [get_ports "FMCP_HSPC_LA07_P"] ;# Bank  72 VCCO - VADJ     - IO_L5P_T0U_N8_AD14P_72
        --   set_property PACKAGE_PIN K22      [get_ports "FMCP_HSPC_LA02_N"] ;# Bank  72 VCCO - VADJ     - IO_L4N_T0U_N7_DBC_AD7N_72
        --   set_property PACKAGE_PIN L23      [get_ports "FMCP_HSPC_LA02_P"] ;# Bank  72 VCCO - VADJ     - IO_L4P_T0U_N6_DBC_AD7P_72
        --   set_property PACKAGE_PIN K23      [get_ports "FMCP_HSPC_LA16_N"] ;# Bank  72 VCCO - VADJ     - IO_L3N_T0L_N5_AD15N_72
        --   set_property PACKAGE_PIN K24      [get_ports "FMCP_HSPC_LA16_P"] ;# Bank  72 VCCO - VADJ     - IO_L3P_T0L_N4_AD15P_72
        --   set_property PACKAGE_PIN AV43     [get_ports "FMCP_HSPC_GBTCLK0_M2C_N"] ;# Bank 124 - MGTREFCLK0N_124
        --   set_property PACKAGE_PIN AV42     [get_ports "FMCP_HSPC_GBTCLK0_M2C_P"] ;# Bank 124 - MGTREFCLK0P_124
        --   set_property PACKAGE_PIN BC54     [get_ports "FMCP_HSPC_DP0_M2C_N"] ;# Bank 124 - MGTYRXN0_124
        --   set_property PACKAGE_PIN BB52     [get_ports "FMCP_HSPC_DP1_M2C_N"] ;# Bank 124 - MGTYRXN1_124
        --   set_property PACKAGE_PIN BA54     [get_ports "FMCP_HSPC_DP2_M2C_N"] ;# Bank 124 - MGTYRXN2_124
        --   set_property PACKAGE_PIN BA50     [get_ports "FMCP_HSPC_DP3_M2C_N"] ;# Bank 124 - MGTYRXN3_124
        --   set_property PACKAGE_PIN BC53     [get_ports "FMCP_HSPC_DP0_M2C_P"] ;# Bank 124 - MGTYRXP0_124
        --   set_property PACKAGE_PIN BB51     [get_ports "FMCP_HSPC_DP1_M2C_P"] ;# Bank 124 - MGTYRXP1_124
        --   set_property PACKAGE_PIN BA53     [get_ports "FMCP_HSPC_DP2_M2C_P"] ;# Bank 124 - MGTYRXP2_124
        --   set_property PACKAGE_PIN BA49     [get_ports "FMCP_HSPC_DP3_M2C_P"] ;# Bank 124 - MGTYRXP3_124
        --   set_property PACKAGE_PIN BC49     [get_ports "FMCP_HSPC_DP0_C2M_N"] ;# Bank 124 - MGTYTXN0_124
        --   set_property PACKAGE_PIN BC45     [get_ports "FMCP_HSPC_DP1_C2M_N"] ;# Bank 124 - MGTYTXN1_124
        --   set_property PACKAGE_PIN BB47     [get_ports "FMCP_HSPC_DP2_C2M_N"] ;# Bank 124 - MGTYTXN2_124
        --   set_property PACKAGE_PIN BA45     [get_ports "FMCP_HSPC_DP3_C2M_N"] ;# Bank 124 - MGTYTXN3_124
        --   set_property PACKAGE_PIN BC48     [get_ports "FMCP_HSPC_DP0_C2M_P"] ;# Bank 124 - MGTYTXP0_124
        --   set_property PACKAGE_PIN BC44     [get_ports "FMCP_HSPC_DP1_C2M_P"] ;# Bank 124 - MGTYTXP1_124
        --   set_property PACKAGE_PIN BB46     [get_ports "FMCP_HSPC_DP2_C2M_P"] ;# Bank 124 - MGTYTXP2_124
        --   set_property PACKAGE_PIN BA44     [get_ports "FMCP_HSPC_DP3_C2M_P"] ;# Bank 124 - MGTYTXP3_124
        --   set_property PACKAGE_PIN AR41     [get_ports "FMCP_HSPC_GBTCLK1_M2C_N"] ;# Bank 125 - MGTREFCLK0N_125
        --   set_property PACKAGE_PIN AR40     [get_ports "FMCP_HSPC_GBTCLK1_M2C_P"] ;# Bank 125 - MGTREFCLK0P_125
        --   set_property PACKAGE_PIN AU41     [get_ports "N22117206"] ;# Bank 125 - MGTRREF_LS
        --   set_property PACKAGE_PIN AY52     [get_ports "FMCP_HSPC_DP4_M2C_N"] ;# Bank 125 - MGTYRXN0_125
        --   set_property PACKAGE_PIN AW54     [get_ports "FMCP_HSPC_DP5_M2C_N"] ;# Bank 125 - MGTYRXN1_125
        --   set_property PACKAGE_PIN AW50     [get_ports "FMCP_HSPC_DP6_M2C_N"] ;# Bank 125 - MGTYRXN2_125
        --   set_property PACKAGE_PIN AV52     [get_ports "FMCP_HSPC_DP7_M2C_N"] ;# Bank 125 - MGTYRXN3_125
        --   set_property PACKAGE_PIN AY51     [get_ports "FMCP_HSPC_DP4_M2C_P"] ;# Bank 125 - MGTYRXP0_125
        --   set_property PACKAGE_PIN AW53     [get_ports "FMCP_HSPC_DP5_M2C_P"] ;# Bank 125 - MGTYRXP1_125
        --   set_property PACKAGE_PIN AW49     [get_ports "FMCP_HSPC_DP6_M2C_P"] ;# Bank 125 - MGTYRXP2_125
        --   set_property PACKAGE_PIN AV51     [get_ports "FMCP_HSPC_DP7_M2C_P"] ;# Bank 125 - MGTYRXP3_125
        --   set_property PACKAGE_PIN AY47     [get_ports "FMCP_HSPC_DP4_C2M_N"] ;# Bank 125 - MGTYTXN0_125
        --   set_property PACKAGE_PIN AW45     [get_ports "FMCP_HSPC_DP5_C2M_N"] ;# Bank 125 - MGTYTXN1_125
        --   set_property PACKAGE_PIN AV47     [get_ports "FMCP_HSPC_DP6_C2M_N"] ;# Bank 125 - MGTYTXN2_125
        --   set_property PACKAGE_PIN AU45     [get_ports "FMCP_HSPC_DP7_C2M_N"] ;# Bank 125 - MGTYTXN3_125
        --   set_property PACKAGE_PIN AY46     [get_ports "FMCP_HSPC_DP4_C2M_P"] ;# Bank 125 - MGTYTXP0_125
        --   set_property PACKAGE_PIN AW44     [get_ports "FMCP_HSPC_DP5_C2M_P"] ;# Bank 125 - MGTYTXP1_125
        --   set_property PACKAGE_PIN AV46     [get_ports "FMCP_HSPC_DP6_C2M_P"] ;# Bank 125 - MGTYTXP2_125
        --   set_property PACKAGE_PIN AU44     [get_ports "FMCP_HSPC_DP7_C2M_P"] ;# Bank 125 - MGTYTXP3_125
        --   set_property PACKAGE_PIN AN41     [get_ports "FMCP_HSPC_GBTCLK2_M2C_N"] ;# Bank 126 - MGTREFCLK0N_126
        --   set_property PACKAGE_PIN AN40     [get_ports "FMCP_HSPC_GBTCLK2_M2C_P"] ;# Bank 126 - MGTREFCLK0P_126
        --   set_property PACKAGE_PIN AU54     [get_ports "FMCP_HSPC_DP8_M2C_N"] ;# Bank 126 - MGTYRXN0_126
        --   set_property PACKAGE_PIN AT52     [get_ports "FMCP_HSPC_DP9_M2C_N"] ;# Bank 126 - MGTYRXN1_126
        --   set_property PACKAGE_PIN AR54     [get_ports "FMCP_HSPC_DP10_M2C_N"] ;# Bank 126 - MGTYRXN2_126
        --   set_property PACKAGE_PIN AP52     [get_ports "FMCP_HSPC_DP11_M2C_N"] ;# Bank 126 - MGTYRXN3_126
        --   set_property PACKAGE_PIN AU53     [get_ports "FMCP_HSPC_DP8_M2C_P"] ;# Bank 126 - MGTYRXP0_126
        --   set_property PACKAGE_PIN AT51     [get_ports "FMCP_HSPC_DP9_M2C_P"] ;# Bank 126 - MGTYRXP1_126
        --   set_property PACKAGE_PIN AR53     [get_ports "FMCP_HSPC_DP10_M2C_P"] ;# Bank 126 - MGTYRXP2_126
        --   set_property PACKAGE_PIN AP51     [get_ports "FMCP_HSPC_DP11_M2C_P"] ;# Bank 126 - MGTYRXP3_126
        --   set_property PACKAGE_PIN AU49     [get_ports "FMCP_HSPC_DP8_C2M_N"] ;# Bank 126 - MGTYTXN0_126
        --   set_property PACKAGE_PIN AT47     [get_ports "FMCP_HSPC_DP9_C2M_N"] ;# Bank 126 - MGTYTXN1_126
        --   set_property PACKAGE_PIN AR49     [get_ports "FMCP_HSPC_DP10_C2M_N"] ;# Bank 126 - MGTYTXN2_126
        --   set_property PACKAGE_PIN AR45     [get_ports "FMCP_HSPC_DP11_C2M_N"] ;# Bank 126 - MGTYTXN3_126
        --   set_property PACKAGE_PIN AU48     [get_ports "FMCP_HSPC_DP8_C2M_P"] ;# Bank 126 - MGTYTXP0_126
        --   set_property PACKAGE_PIN AT46     [get_ports "FMCP_HSPC_DP9_C2M_P"] ;# Bank 126 - MGTYTXP1_126
        --   set_property PACKAGE_PIN AR48     [get_ports "FMCP_HSPC_DP10_C2M_P"] ;# Bank 126 - MGTYTXP2_126
        --   set_property PACKAGE_PIN AR44     [get_ports "FMCP_HSPC_DP11_C2M_P"] ;# Bank 126 - MGTYTXP3_126
        --   set_property PACKAGE_PIN AL41     [get_ports "FMCP_HSPC_GBTCLK3_M2C_N"] ;# Bank 127 - MGTREFCLK0N_127
        --   set_property PACKAGE_PIN AL40     [get_ports "FMCP_HSPC_GBTCLK3_M2C_P"] ;# Bank 127 - MGTREFCLK0P_127
        --   set_property PACKAGE_PIN AN54     [get_ports "FMCP_HSPC_DP12_M2C_N"] ;# Bank 127 - MGTYRXN0_127
        --   set_property PACKAGE_PIN AN50     [get_ports "FMCP_HSPC_DP13_M2C_N"] ;# Bank 127 - MGTYRXN1_127
        --   set_property PACKAGE_PIN AM52     [get_ports "FMCP_HSPC_DP14_M2C_N"] ;# Bank 127 - MGTYRXN2_127
        --   set_property PACKAGE_PIN AL54     [get_ports "FMCP_HSPC_DP15_M2C_N"] ;# Bank 127 - MGTYRXN3_127
        --   set_property PACKAGE_PIN AN53     [get_ports "FMCP_HSPC_DP12_M2C_P"] ;# Bank 127 - MGTYRXP0_127
        --   set_property PACKAGE_PIN AN49     [get_ports "FMCP_HSPC_DP13_M2C_P"] ;# Bank 127 - MGTYRXP1_127
        --   set_property PACKAGE_PIN AM51     [get_ports "FMCP_HSPC_DP14_M2C_P"] ;# Bank 127 - MGTYRXP2_127
        --   set_property PACKAGE_PIN AL53     [get_ports "FMCP_HSPC_DP15_M2C_P"] ;# Bank 127 - MGTYRXP3_127
        --   set_property PACKAGE_PIN AP47     [get_ports "FMCP_HSPC_DP12_C2M_N"] ;# Bank 127 - MGTYTXN0_127
        --   set_property PACKAGE_PIN AN45     [get_ports "FMCP_HSPC_DP13_C2M_N"] ;# Bank 127 - MGTYTXN1_127
        --   set_property PACKAGE_PIN AM47     [get_ports "FMCP_HSPC_DP14_C2M_N"] ;# Bank 127 - MGTYTXN2_127
        --   set_property PACKAGE_PIN AL45     [get_ports "FMCP_HSPC_DP15_C2M_N"] ;# Bank 127 - MGTYTXN3_127
        --   set_property PACKAGE_PIN AP46     [get_ports "FMCP_HSPC_DP12_C2M_P"] ;# Bank 127 - MGTYTXP0_127
        --   set_property PACKAGE_PIN AN44     [get_ports "FMCP_HSPC_DP13_C2M_P"] ;# Bank 127 - MGTYTXP1_127
        --   set_property PACKAGE_PIN AM46     [get_ports "FMCP_HSPC_DP14_C2M_P"] ;# Bank 127 - MGTYTXP2_127
        --   set_property PACKAGE_PIN AL44     [get_ports "FMCP_HSPC_DP15_C2M_P"] ;# Bank 127 - MGTYTXP3_127
        --   set_property PACKAGE_PIN AJ41     [get_ports "FMCP_HSPC_GBTCLK4_M2C_N"] ;# Bank 128 - MGTREFCLK0N_128
        --   set_property PACKAGE_PIN AJ40     [get_ports "FMCP_HSPC_GBTCLK4_M2C_P"] ;# Bank 128 - MGTREFCLK0P_128
        --   set_property PACKAGE_PIN AL50     [get_ports "FMCP_HSPC_DP16_M2C_N"] ;# Bank 128 - MGTYRXN0_128
        --   set_property PACKAGE_PIN AK52     [get_ports "FMCP_HSPC_DP17_M2C_N"] ;# Bank 128 - MGTYRXN1_128
        --   set_property PACKAGE_PIN AJ54     [get_ports "FMCP_HSPC_DP18_M2C_N"] ;# Bank 128 - MGTYRXN2_128
        --   set_property PACKAGE_PIN AH52     [get_ports "FMCP_HSPC_DP19_M2C_N"] ;# Bank 128 - MGTYRXN3_128
        --   set_property PACKAGE_PIN AL49     [get_ports "FMCP_HSPC_DP16_M2C_P"] ;# Bank 128 - MGTYRXP0_128
        --   set_property PACKAGE_PIN AK51     [get_ports "FMCP_HSPC_DP17_M2C_P"] ;# Bank 128 - MGTYRXP1_128
        --   set_property PACKAGE_PIN AJ53     [get_ports "FMCP_HSPC_DP18_M2C_P"] ;# Bank 128 - MGTYRXP2_128
        --   set_property PACKAGE_PIN AH51     [get_ports "FMCP_HSPC_DP19_M2C_P"] ;# Bank 128 - MGTYRXP3_128
        --   set_property PACKAGE_PIN AK47     [get_ports "FMCP_HSPC_DP16_C2M_N"] ;# Bank 128 - MGTYTXN0_128
        --   set_property PACKAGE_PIN AJ49     [get_ports "FMCP_HSPC_DP17_C2M_N"] ;# Bank 128 - MGTYTXN1_128
        --   set_property PACKAGE_PIN AJ45     [get_ports "FMCP_HSPC_DP18_C2M_N"] ;# Bank 128 - MGTYTXN2_128
        --   set_property PACKAGE_PIN AH47     [get_ports "FMCP_HSPC_DP19_C2M_N"] ;# Bank 128 - MGTYTXN3_128
        --   set_property PACKAGE_PIN AK46     [get_ports "FMCP_HSPC_DP16_C2M_P"] ;# Bank 128 - MGTYTXP0_128
        --   set_property PACKAGE_PIN AJ48     [get_ports "FMCP_HSPC_DP17_C2M_P"] ;# Bank 128 - MGTYTXP1_128
        --   set_property PACKAGE_PIN AJ44     [get_ports "FMCP_HSPC_DP18_C2M_P"] ;# Bank 128 - MGTYTXP2_128
        --   set_property PACKAGE_PIN AH46     [get_ports "FMCP_HSPC_DP19_C2M_P"] ;# Bank 128 - MGTYTXP3_128
        --   set_property PACKAGE_PIN AG41     [get_ports "FMCP_HSPC_GBTCLK5_M2C_N"] ;# Bank 129 - MGTREFCLK0N_129
        --   set_property PACKAGE_PIN AG40     [get_ports "FMCP_HSPC_GBTCLK5_M2C_P"] ;# Bank 129 - MGTREFCLK0P_129
        --   set_property PACKAGE_PIN AE41     [get_ports "N21075880"] ;# Bank 129 - MGTRREF_LC
        --   set_property PACKAGE_PIN AG54     [get_ports "FMCP_HSPC_DP20_M2C_N"] ;# Bank 129 - MGTYRXN0_129
        --   set_property PACKAGE_PIN AF52     [get_ports "FMCP_HSPC_DP21_M2C_N"] ;# Bank 129 - MGTYRXN1_129
        --   set_property PACKAGE_PIN AE54     [get_ports "FMCP_HSPC_DP22_M2C_N"] ;# Bank 129 - MGTYRXN2_129
        --   set_property PACKAGE_PIN AE50     [get_ports "FMCP_HSPC_DP23_M2C_N"] ;# Bank 129 - MGTYRXN3_129
        --   set_property PACKAGE_PIN AG53     [get_ports "FMCP_HSPC_DP20_M2C_P"] ;# Bank 129 - MGTYRXP0_129
        --   set_property PACKAGE_PIN AF51     [get_ports "FMCP_HSPC_DP21_M2C_P"] ;# Bank 129 - MGTYRXP1_129
        --   set_property PACKAGE_PIN AE53     [get_ports "FMCP_HSPC_DP22_M2C_P"] ;# Bank 129 - MGTYRXP2_129
        --   set_property PACKAGE_PIN AE49     [get_ports "FMCP_HSPC_DP23_M2C_P"] ;# Bank 129 - MGTYRXP3_129
        --   set_property PACKAGE_PIN AG49     [get_ports "FMCP_HSPC_DP20_C2M_N"] ;# Bank 129 - MGTYTXN0_129
        --   set_property PACKAGE_PIN AG45     [get_ports "FMCP_HSPC_DP21_C2M_N"] ;# Bank 129 - MGTYTXN1_129
        --   set_property PACKAGE_PIN AF47     [get_ports "FMCP_HSPC_DP22_C2M_N"] ;# Bank 129 - MGTYTXN2_129
        --   set_property PACKAGE_PIN AE45     [get_ports "FMCP_HSPC_DP23_C2M_N"] ;# Bank 129 - MGTYTXN3_129
        --   set_property PACKAGE_PIN AG48     [get_ports "FMCP_HSPC_DP20_C2M_P"] ;# Bank 129 - MGTYTXP0_129
        --   set_property PACKAGE_PIN AG44     [get_ports "FMCP_HSPC_DP21_C2M_P"] ;# Bank 129 - MGTYTXP1_129
        --   set_property PACKAGE_PIN AF46     [get_ports "FMCP_HSPC_DP22_C2M_P"] ;# Bank 129 - MGTYTXP2_129
        --   set_property PACKAGE_PIN AE44     [get_ports "FMCP_HSPC_DP23_C2M_P"] ;# Bank 129 - MGTYTXP3_129
        --PCIE_EP_PERST_LS
        --PCIE_EP_WAKE_LS
        --PCIE_EP_RX15_N  --# Bank 224 - MGTYRXN0_224
        --PCIE_EP_RX14_N  --# Bank 224 - MGTYRXN1_224
        --PCIE_EP_RX13_N  --# Bank 224 - MGTYRXN2_224
        --PCIE_EP_RX12_N  --# Bank 224 - MGTYRXN3_224
        --PCIE_EP_RX15_P  --# Bank 224 - MGTYRXP0_224
        --PCIE_EP_RX14_P  --# Bank 224 - MGTYRXP1_224
        --PCIE_EP_RX13_P  --# Bank 224 - MGTYRXP2_224
        --PCIE_EP_RX12_P  --# Bank 224 - MGTYRXP3_224
        --PCIE_EP_TX15_N  --# Bank 224 - MGTYTXN0_224
        --PCIE_EP_TX14_N  --# Bank 224 - MGTYTXN1_224
        --PCIE_EP_TX13_N  --# Bank 224 - MGTYTXN2_224
        --PCIE_EP_TX12_N  --# Bank 224 - MGTYTXN3_224
        --PCIE_EP_TX15_P  --# Bank 224 - MGTYTXP0_224
        --PCIE_EP_TX14_P  --# Bank 224 - MGTYTXP1_224
        --PCIE_EP_TX13_P  --# Bank 224 - MGTYTXP2_224
        --PCIE_EP_TX12_P  --# Bank 224 - MGTYTXP3_224
        --PCIE_CLK1_N  --# Bank 225 - MGTREFCLK0N_225
        --PCIE_CLK1_P  --# Bank 225 - MGTREFCLK0P_225
        --N22119509  --# Bank 225 - MGTRREF_RS
        --PCIE_EP_RX11_N  --# Bank 225 - MGTYRXN0_225
        --PCIE_EP_RX10_N  --# Bank 225 - MGTYRXN1_225
        --PCIE_EP_RX9_N  -- # Bank 225 - MGTYRXN2_225
        --PCIE_EP_RX8_N  -- # Bank 225 - MGTYRXN3_225
        --PCIE_EP_RX11_P --# Bank 225 - MGTYRXP0_225
        --PCIE_EP_RX10_P --# Bank 225 - MGTYRXP1_225
        --PCIE_EP_RX9_P  --# Bank 225 - MGTYRXP2_225
        --PCIE_EP_RX8_P  --# Bank 225 - MGTYRXP3_225
        --PCIE_EP_TX11_N  --# Bank 225 - MGTYTXN0_225
        --PCIE_EP_TX10_N   --# Bank 225 - MGTYTXN1_225
        --PCIE_EP_TX9_N    --# Bank 225 - MGTYTXN2_225
        --PCIE_EP_TX8_N    --# Bank 225 - MGTYTXN3_225
        --PCIE_EP_TX11_P   --# Bank 225 - MGTYTXP0_225
        --PCIE_EP_TX10_P   --# Bank 225 - MGTYTXP1_225
        --PCIE_EP_TX9_P    --# Bank 225 - MGTYTXP2_225
        --PCIE_EP_TX8_P    --# Bank 225 - MGTYTXP3_225
        --PCIE_EP_RX7_N    --# Bank 226 - MGTYRXN0_226
        --PCIE_EP_RX6_N    --# Bank 226 - MGTYRXN1_226
        --PCIE_EP_RX5_N    --# Bank 226 - MGTYRXN2_226
        --PCIE_EP_RX4_N    --# Bank 226 - MGTYRXN3_226
        --PCIE_EP_RX7_P    --# Bank 226 - MGTYRXP0_226
        --PCIE_EP_RX6_P    --# Bank 226 - MGTYRXP1_226
        --PCIE_EP_RX5_P    --# Bank 226 - MGTYRXP2_226
        --PCIE_EP_RX4_P    --# Bank 226 - MGTYRXP3_226
        --PCIE_EP_TX7_N    --# Bank 226 - MGTYTXN0_226
        --PCIE_EP_TX6_N    --# Bank 226 - MGTYTXN1_226
        --PCIE_EP_TX5_N    --# Bank 226 - MGTYTXN2_226
        --PCIE_EP_TX4_N    --# Bank 226 - MGTYTXN3_226
        --PCIE_EP_TX7_P    --# Bank 226 - MGTYTXP0_226
        --PCIE_EP_TX6_P    --# Bank 226 - MGTYTXP1_226
        --PCIE_EP_TX5_P    --# Bank 226 - MGTYTXP2_226
        --PCIE_EP_TX4_P    --# Bank 226 - MGTYTXP3_226
        --PCIE_CLK2_N    --# Bank 227 - MGTREFCLK0N_227
        --PCIE_CLK2_P    --# Bank 227 - MGTREFCLK0P_227
        --PCIE_EP_RX3_N    --# Bank 227 - MGTYRXN0_227
        --PCIE_EP_RX2_N    --# Bank 227 - MGTYRXN1_227
        --PCIE_EP_RX1_N    --# Bank 227 - MGTYRXN2_227
        --PCIE_EP_RX0_N    --# Bank 227 - MGTYRXN3_227
        --PCIE_EP_RX3_P    --# Bank 227 - MGTYRXP0_227
        --PCIE_EP_RX2_P    --# Bank 227 - MGTYRXP1_227
        --PCIE_EP_RX1_P    --# Bank 227 - MGTYRXP2_227
        --PCIE_EP_RX0_P    --# Bank 227 - MGTYRXP3_227
        --PCIE_EP_TX3_N    --# Bank 227 - MGTYTXN0_227
        --PCIE_EP_TX2_N    --# Bank 227 - MGTYTXN1_227
        --PCIE_EP_TX1_N    --# Bank 227 - MGTYTXN2_227
        --PCIE_EP_TX0_N    --# Bank 227 - MGTYTXN3_227
        --PCIE_EP_TX3_P    --# Bank 227 - MGTYTXP0_227
        --PCIE_EP_TX2_P    --# Bank 227 - MGTYTXP1_227
        --PCIE_EP_TX1_P    --# Bank 227 - MGTYTXP2_227
        --PCIE_EP_TX0_P    --# Bank 227 - MGTYTXP3_227
        --N22480070    --# Bank 229 - MGTRREF_RC
        --N22119643    --# Bank 233 - MGTRREF_RN
    );
END vcu128_gemini_dsp;

-------------------------------------------------------------------------------
ARCHITECTURE structure OF vcu128_gemini_dsp IS

    ---------------------------------------------------------------------------
    -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
    ---------------------------------------------------------------------------

    CONSTANT c_num_eth_lanes      : INTEGER := 6;
    CONSTANT c_default_ip         : STD_LOGIC_VECTOR(31 DOWNTO 0) := X"0a2000FE"; -- 10.32.0.254
    CONSTANT c_default_mac        : STD_LOGIC_VECTOR(47 DOWNTO 0) := x"C02B3C4D5E6F";
    CONSTANT c_max_packet_length  : INTEGER := 8192;
    CONSTANT c_tx_priority        : t_integer_arr(0 to 15) := (0,  -- Gemini M&C
                                                              4,  -- PTP
                                                              3,  -- DHCP
                                                              7,  -- ARP
                                                              6,  -- ICMP
                                                              0,  -- Gemini Pub/Sub
                                                              0,0,0,0,0,0,0,0,0,0);
   
    CONSTANT c_nof_mac            : INTEGER := 392*2;
    CONSTANT c_nof_mac_per_block  : INTEGER := c_nof_mac/8;
    CONSTANT c_nof_mac4           : INTEGER := c_nof_mac_per_block*8;

    ---------------------------------------------------------------------------
    -- SIGNAL DECLARATIONS  --
    --------------------------------------------------------------------------- 

    SIGNAL clk_125                            : STD_LOGIC;
    SIGNAL clk_100                            : STD_LOGIC;
    SIGNAL clk_50                             : STD_LOGIC;
    SIGNAL clk_eth                            : STD_LOGIC;      -- RX Recovered clock (synchronous Ethernet reference)
    SIGNAL clk_ddr4                           : STD_LOGIC;
 
    SIGNAL system_reset_shift                 : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '1');
    SIGNAL system_reset                       : STD_LOGIC;
    SIGNAL system_locked                      : STD_LOGIC;
 
    SIGNAL ddr_ip_reset                       : STD_LOGIC;
    SIGNAL ddr_ip_reset_r                     : STD_LOGIC;
    SIGNAL ddr4_cal_done                      : STD_LOGIC;
    SIGNAL ddr4_cal_done_r                    : STD_LOGIC;
    SIGNAL ddr4_reset                         : STD_LOGIC;
    SIGNAL ddr4_sync_rst                      : STD_LOGIC;
    SIGNAL ddr4_axi4_mosi                     : t_axi4_full_mosi;
    SIGNAL ddr4_axi4_miso                     : t_axi4_full_miso;
 
    SIGNAL boot_mode_start                    : STD_LOGIC;
    SIGNAL boot_mode_done                     : STD_LOGIC;
    SIGNAL ddr4_data_msmatch_err              : STD_LOGIC;
    SIGNAL ddr4_write_err                     : STD_LOGIC;
    SIGNAL ddr4_read_err                      : STD_LOGIC;
    SIGNAL boot_mode_running                  : STD_LOGIC;
    SIGNAL prbs_mode_running                  : STD_LOGIC;
    SIGNAL led2_colour_e                      : STD_LOGIC_VECTOR(23 DOWNTO 0);
 
    SIGNAL local_mac                          : STD_LOGIC_VECTOR(47 DOWNTO 0);
    SIGNAL local_ip                           : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL prom_ip                            : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL eth_in_siso                        : t_axi4_siso;
    SIGNAL eth_in_sosi                        : t_axi4_sosi;
    SIGNAL eth_out_sosi                       : t_axi4_sosi;
    SIGNAL eth_out_siso                       : t_axi4_siso;
    SIGNAL eth_rx_reset                       : STD_LOGIC;
    SIGNAL eth_tx_reset                       : STD_LOGIC;
    SIGNAL ctl_rx_pause_ack                   : STD_LOGIC_VECTOR(8 DOWNTO 0);
    SIGNAL ctl_rx_pause_enable                : STD_LOGIC_VECTOR(8 DOWNTO 0);
    SIGNAL stat_rx_pause_req                  : STD_LOGIC_VECTOR(8 DOWNTO 0);
    SIGNAL eth_locked                         : STD_LOGIC;
    SIGNAL axi_rst                            : STD_LOGIC;
    signal gemini_mm_rst                      : std_logic;

    SIGNAL decoder_out_sosi                   : t_axi4_sosi_arr(0 TO c_num_eth_lanes-1);
    SIGNAL decoder_out_siso                   : t_axi4_siso_arr(0 TO c_num_eth_lanes-1);
    SIGNAL encoder_in_sosi                    : t_axi4_sosi_arr(0 TO c_num_eth_lanes-1);
    SIGNAL encoder_in_siso                    : t_axi4_siso_arr(0 TO c_num_eth_lanes-1);

    SIGNAL mc_master_mosi                     : t_axi4_full_mosi;
    SIGNAL mc_master_miso                     : t_axi4_full_miso;
    SIGNAL mc_lite_miso                       : t_axi4_lite_miso_arr(0 TO c_nof_lite_slaves-1);
    SIGNAL mc_lite_mosi                       : t_axi4_lite_mosi_arr(0 TO c_nof_lite_slaves-1);
    SIGNAL mc_full_miso                       : t_axi4_full_miso_arr(0 TO c_nof_full_slaves-1);
    SIGNAL mc_full_mosi                       : t_axi4_full_mosi_arr(0 TO c_nof_full_slaves-1);

    SIGNAL local_prom_ip                      : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL serial_number                      : STD_LOGIC_VECTOR(31 DOWNTO 0); 

    SIGNAL local_time                         : STD_LOGIC_VECTOR(63 DOWNTO 0);
    SIGNAL event_in                           : STD_LOGIC_VECTOR(31 DOWNTO 0);

    SIGNAL qsfp4_tx_clk_out                  : STD_LOGIC;
    SIGNAL qsfp4_tx_disable                  : STD_LOGIC_VECTOR(0 TO 3);
    SIGNAL qsfp4_rx_disable                  : STD_LOGIC_VECTOR(0 TO 3);
    SIGNAL qsfp4_loopback                    : STD_LOGIC_VECTOR(2 DOWNTO 0);
    signal qsfp1_rx_locked                   : std_logic_vector(0 to 3);
    signal qsfp2_rx_locked                   : std_logic_vector(0 to 3);
    signal qsfp3_rx_locked                   : std_logic_vector(0 to 3);
    SIGNAL qsfp4_rx_locked                   : STD_LOGIC_VECTOR(0 TO 3);

    SIGNAL qsfp_c_tx_clk_out                  : STD_LOGIC;
    SIGNAL qsfp_c_tx_disable                  : STD_LOGIC_VECTOR(0 TO 3);
    SIGNAL qsfp_c_rx_disable                  : STD_LOGIC_VECTOR(0 TO 3);
    SIGNAL qsfp_c_loopback                    : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL qsfp_c_rx_locked                   : STD_LOGIC_VECTOR(0 TO 3);

    SIGNAL qsfp_b_tx_clk_out                  : STD_LOGIC_VECTOR(0 TO 3);
    SIGNAL qsfp_b_tx_disable                  : STD_LOGIC_VECTOR(0 TO 3);
    SIGNAL qsfp_b_rx_disable                  : STD_LOGIC_VECTOR(0 TO 3);
    SIGNAL qsfp_b_loopback                    : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL qsfp_b_rx_locked                   : STD_LOGIC_VECTOR(0 TO 3);

    SIGNAL qsfp_a_tx_clk_out                  : STD_LOGIC_VECTOR(0 TO 3);
    SIGNAL qsfp_a_tx_disable                  : STD_LOGIC_VECTOR(0 TO 3);
    SIGNAL qsfp_a_rx_disable                  : STD_LOGIC_VECTOR(0 TO 3);
    SIGNAL qsfp_a_loopback                    : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL qsfp_a_rx_locked                   : STD_LOGIC_VECTOR(0 TO 3);
    SIGNAL traffic_gen_clk                    : STD_LOGIC_VECTOR(0 TO 44);
    SIGNAL completion_status                  : t_slv_5_arr(0 TO 44);
    SIGNAL lane_ok                            : STD_LOGIC_VECTOR(0 TO 44);
    SIGNAL traffic_user_rx_reset              : STD_LOGIC_VECTOR(0 TO 44);
    SIGNAL traffic_user_tx_reset              : STD_LOGIC_VECTOR(0 TO 44);
    SIGNAL traffic_rx_lock                    : STD_LOGIC_VECTOR(0 TO 44);
    SIGNAL data_rx_siso                       : t_axi4_siso_arr(0 TO 44);
    SIGNAL data_rx_sosi                       : t_axi4_sosi_arr(0 TO 44);
    SIGNAL data_rx_sosi_reg                   : t_axi4_sosi_arr(0 TO 44);
    SIGNAL data_tx_siso                       : t_axi4_siso_arr(0 TO 44);
    SIGNAL data_tx_sosi                       : t_axi4_sosi_arr(0 TO 44);

    SIGNAL qmac_rx_locked                     : STD_LOGIC_vector(3 DOWNTO 0);
    SIGNAL qmac_rx_synced                     : STD_LOGIC_vector(3 DOWNTO 0);
    SIGNAL qmac_rx_aligned                    : STD_LOGIC;
    SIGNAL qmac_rx_status                     : STD_LOGIC;

    SIGNAL ctraffic_user_rx_reset             : STD_LOGIC;
    SIGNAL ctraffic_user_tx_reset             : STD_LOGIC;
    SIGNAL ctraffic_rx_aligned                : STD_LOGIC;
    SIGNAL cdata_tx_siso                      : t_lbus_siso;
    SIGNAL cdata_tx_sosi                      : t_lbus_sosi;
    SIGNAL cdata_rx_sosi                      : t_lbus_sosi;
    SIGNAL ctraffic_tx_enable                 : STD_LOGIC;
    SIGNAL ctraffic_rx_enable                 : STD_LOGIC;
    SIGNAL ctraffic_tx_send_rfi               : STD_LOGIC;
    SIGNAL ctraffic_tx_send_lfi               : STD_LOGIC;
    SIGNAL ctraffic_rsfec_tx_enable           : STD_LOGIC;
    SIGNAL ctraffic_rsfec_rx_enable           : STD_LOGIC;
    SIGNAL ctraffic_rsfec_error_mode          : STD_LOGIC;
    SIGNAL ctraffic_rsfec_enable_correction   : STD_LOGIC;
    SIGNAL ctraffic_rsfec_enable_indication   : STD_LOGIC;
    SIGNAL ctraffic_done                      : STD_LOGIC;
    SIGNAL ctraffic_aligned                   : STD_LOGIC;
    SIGNAL ctraffic_failed                    : STD_LOGIC;

    SIGNAL backplane_ip_valid                 : STD_LOGIC;
    SIGNAL backplane_ip                       : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL bp_prom_startup_complete           : STD_LOGIC;
    SIGNAL bp_serial_number                   : STD_LOGIC_VECTOR(31 DOWNTO 0);

    SIGNAL dhcp_start                         : STD_LOGIC;
    SIGNAL system_fields_rw                   : t_system_rw;
    SIGNAL system_fields_ro                   : t_system_ro;
    SIGNAL pps                                : STD_LOGIC;
    SIGNAL pps_extended                       : STD_LOGIC;
    SIGNAL eth_act                            : STD_LOGIC;
    SIGNAL eth_act_extended                   : STD_LOGIC;
    SIGNAL gnd                                : STD_LOGIC_VECTOR(255 DOWNTO 0);

    -- for capture by the debug core.
    signal seg0_sop, seg0_eop, seg0_ena, seg1_sop, seg1_eop, seg1_ena, seg0_err, seg1_err : std_logic;
    signal seg0_mty, seg1_mty : std_logic_vector(2 downto 0);
    signal qsfp_a_led, qsfp_b_led, qsfp_c_led, qsfp_d_led : std_logic;
    signal qsfp_c_led_del2, qsfp_c_led_del1 : std_logic;
    signal qsfp_d_led_del2, qsfp_d_led_del1 : std_logic;

    signal mac40G : std_logic_vector(47 downto 0);
 
    signal ptp_clk        : std_logic;                     -- 125 MHz clock
    signal ptp_time_frac  : std_logic_vector(26 downto 0); -- fraction of a second in units of 8 ns
    signal ptp_time_sec   : std_logic_vector(31 downto 0);
    signal LFAADecode_dbg : std_logic_vector(13 downto 0);
    signal LFAA_tx_fsm, LFAA_stats_fsm, LFAA_rx_fsm : std_logic_vector(3 downto 0);
    signal goodpacket, nonSPEAD : std_logic;
   
    signal wvalid0, wvalid1, wvalid2, wvalid3, rvalid0, rvalid1, rvalid2, rvalid3 : std_logic;
    
    signal req_crsb_state    : std_logic_vector(2 downto 0);
    signal req_main_state    : std_logic_vector(3 downto 0);
    signal replay_state      : std_logic_vector(3 downto 0);
    signal completion_state  : std_logic_vector(3 downto 0);
    signal rq_state          : std_logic_vector(3 downto 0);
    signal rq_stream_state   : std_logic_vector(3 downto 0);
    signal resp_state        : std_logic_vector(3 downto 0);
    signal crqb_fifo_rd_data_sel_out : std_logic_vector(87 DOWNTO 0);
    signal crqb_fifo_rd_out : std_logic_vector(2 downto 0);  
   
    signal s2mm_in_dbg  : t_axi4_sosi;  -- Sink in
    signal s2mm_out_dbg : t_axi4_siso; -- Sink out
    signal s2mm_cmd_in_dbg : t_axi4_sosi; -- Sink in
    signal s2mm_cmd_out_dbg : t_axi4_siso; -- Sink out
    signal s2mm_sts_in_dbg :  t_axi4_siso;  -- Source in
    signal s2mm_sts_out_dbg : t_axi4_sosi;  

    signal shutdown_extended_del1, shutdown_extended_del2, shutdown_extended_del3, shutdown_extended_del4 : std_logic := '0';
    signal rst_qsfp_a, rst_qsfp_b, rst_qsfp_c, rst_qsfp_d : std_logic;
   
    signal qsfp1_tx_p : std_logic_vector(3 downto 0);
    signal qsfp1_tx_n : std_logic_vector(3 downto 0);
    signal qsfp2_tx_p : std_logic_vector(3 downto 0);
    signal qsfp2_tx_n : std_logic_vector(3 downto 0);
    signal qsfp3_tx_p : std_logic_vector(3 downto 0);
    signal qsfp3_tx_n : std_logic_vector(3 downto 0);
    signal qsfp4_tx_p : std_logic_vector(3 downto 0);
    signal qsfp4_tx_n : std_logic_vector(3 downto 0);
     
    signal qsfp1_rx_p : std_logic_vector(3 downto 0);
    signal qsfp1_rx_n : std_logic_vector(3 downto 0);
    signal qsfp2_rx_p : std_logic_vector(3 downto 0);
    signal qsfp2_rx_n : std_logic_vector(3 downto 0);
    signal qsfp3_rx_p : std_logic_vector(3 downto 0);
    signal qsfp3_rx_n : std_logic_vector(3 downto 0);
    signal qsfp4_rx_p : std_logic_vector(3 downto 0);
    signal qsfp4_rx_n : std_logic_vector(3 downto 0);
   
    signal qsfp_int_n : std_logic;
    signal qsfp_sda : std_logic;
    signal qsfp_scl : std_logic;

    signal LFAA_data : std_logic_vector(127 downto 0);
    signal LFAA_valid : std_logic;

    COMPONENT ila_big1
    PORT (
        clk : IN STD_LOGIC;
        probe0 : IN STD_LOGIC_VECTOR(36 DOWNTO 0));
    END COMPONENT;
    
    component system_clock
    port (
        clk_100    : out    std_logic;
        clk_125    : out    std_logic;
        clk_50     : out    std_logic;
        locked     : out    std_logic;
        clk_in1_p  : in     std_logic;
        clk_in1_n  : in     std_logic); 
    end component;    
    
    -- in global buffer 100MHz, out 400MHz 
    component pll_hbm
    port (
        clk_out1 : out std_logic;
        clk_in1  : in  std_logic);
    end component;
    
    component wall_clk_pll
    port (
        clk_out1 : out std_logic;
        clk_in1  : in  std_logic);
    end component;
    
    signal qsfp1_modskl_ls : std_logic;
    signal qsfp1_reset_ls : std_logic;
    signal qsfp2_modskl_ls : std_logic;
    signal qsfp2_reset_ls : std_logic;
    signal qsfp3_modskl_ls : std_logic;
    signal qsfp3_reset_ls : std_logic;
    signal qsfp4_modskl_ls : std_logic;
    signal qsfp4_reset_ls : std_logic;
   
    signal dbg_rx_block_lock, dbg_rx_remote_fault : std_logic;
   

    signal dstat_rx_total_bytes   :  STD_LOGIC_VECTOR(15 DOWNTO 0);
    signal dstat_rx_total_packets :  STD_LOGIC_VECTOR(15 DOWNTO 0);
    signal dstat_rx_bad_fcs       :  STD_LOGIC_VECTOR(15 DOWNTO 0);
    signal dstat_rx_user_pause    :  STD_LOGIC_vector(15 downto 0);
    signal dstat_rx_vlan          :  STD_LOGIC_vector(15 downto 0);
    signal dstat_rx_oversize      :  STD_LOGIC_vector(15 downto 0);
    signal dstat_rx_packet_small  :  STD_LOGIC_vector(15 downto 0);   
    signal dbg_loopback : std_logic_vector(2 downto 0);

   
    COMPONENT vio_0
      PORT (
        clk : IN STD_LOGIC;
        probe_out0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        probe_out1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        probe_out2 : OUT STD_LOGIC_VECTOR(47 DOWNTO 0)
      );
    END COMPONENT;   
   
    signal probe_out0 : std_logic_vector(31 downto 0);
    signal vio_prom_ip : std_logic_vector(31 downto 0);
    signal vio_local_mac : std_logic_vector(47 downto 0);
    
    signal dbg_timer_expire : std_logic;
    signal dbg_timer  :  std_logic_vector(15 downto 0);
    signal clk_400 : std_logic;
    signal wall_clk : std_logic;
    signal clk400StartupCount : std_logic_vector(11 downto 0) := "111111111111";
    signal clk_400_rst : std_logic;
    
begin

    gnd <= (OTHERS  => '0');


    GPIO_LED_0_LS <= qsfp_a_led; -- out std_logic;
    GPIO_LED_1_LS <= qsfp_b_led; -- out std_logic;
    GPIO_LED_2_LS <= qsfp_c_led; -- out std_logic;
    GPIO_LED_3_LS <= qsfp_d_led; -- out std_logic;
    GPIO_LED_4_LS <= '0';
    GPIO_LED_5_LS <= '1';
    GPIO_LED_6_LS <= '1';
    GPIO_LED_7_LS <= '0';

    ---------------------------------------------------------------------------
    -- CLOCKING & RESETS  --
    ---------------------------------------------------------------------------

    system_pll: system_clock
    PORT MAP (
        clk_in1_n => DDR4_CLK_100MHZ_N,
        clk_in1_p => DDR4_CLK_100MHZ_P,
        clk_125  => clk_125,
        clk_100  => clk_100,
        clk_50   => clk_50,
        locked   => system_locked
    );
    
    hbmplli : pll_hbm
    port map (
        clk_out1  => clk_400, -- out std_logic;
        clk_in1   => clk_100  -- in  std_logic;
    );
    
    process(clk_400)
    begin
        if rising_edge(clk_400) then
            if clk400StartupCount /= "000000000000" then
                clk400StartupCount <= std_logic_vector(unsigned(clk400StartupCount) - 1);
                clk_400_rst <= '1';
            else
                clk_400_rst <= '0';
            end if;
        end if;
    end process;
    
    wallplli : wall_clk_pll    
    port map (
        clk_in1 => clk_125,
        clk_out1 => wall_clk  -- 250 MHz
    );
    
    system_pll_reset: PROCESS(clk_50)
    BEGIN
        IF RISING_EDGE(clk_50) THEN
            system_reset_shift <= system_reset_shift(6 DOWNTO 0) & NOT(system_locked);
            rst_qsfp_a <= system_reset or system_fields_rw.qsfpgty_resets(0);
            rst_qsfp_b <= system_reset or system_fields_rw.qsfpgty_resets(1);
            rst_qsfp_c <= system_reset or system_fields_rw.qsfpgty_resets(2);
            rst_qsfp_d <= system_reset or system_fields_rw.qsfpgty_resets(3);
            
            
            --c100Count <= std_logic_vector(unsigned(c100Count) + 1);
            
        END IF;
    END PROCESS;
    
    system_reset <= system_reset_shift(7) or probe_out0(2);
    dbg_loopback <= probe_out0(6 downto 4);
    

    virtualIO : vio_0
    PORT MAP (
        clk => clk_eth,
        probe_out0 => probe_out0,
        probe_out1 => vio_prom_ip,
        probe_out2 => vio_local_mac
    );
    
    prom_ip <= vio_prom_ip when probe_out0(8) = '1' else x"0A2000FD";
    local_mac <= vio_local_mac when probe_out0(8) = '1' else x"C0001B81C87B";
    
    ---------------------------------------------------------------------------
    -- QSFP Interfaces  --
    ---------------------------------------------------------------------------
    
    -- QSFP1 - One of 4 used for a 10GE interface, used for the Gemini protocol MAC.
     
    QSFP1_TX1_P <= qsfp1_tx_p(0);
    --QSFP1_TX2_P <= qsfp1_tx_p(1);
    --QSFP1_TX3_P <= qsfp1_tx_p(2);
    --QSFP1_TX4_P <= qsfp1_tx_p(3);
    
    QSFP1_TX1_N <= qsfp1_tx_n(0);
    --QSFP1_TX2_N <= qsfp1_tx_n(1);
    --QSFP1_TX3_N <= qsfp1_tx_n(2);
    --QSFP1_TX4_N <= qsfp1_tx_n(3);
    
    qsfp1_rx_p(0) <= QSFP1_RX1_P;
    --qsfp1_rx_p(1) <= QSFP1_RX2_P;
    --qsfp1_rx_p(2) <= QSFP1_RX3_P;
    --qsfp1_rx_p(3) <= QSFP1_RX4_P;
    
    qsfp1_rx_n(0) <= QSFP1_RX1_N;
    --qsfp1_rx_n(1) <= QSFP1_RX2_N;
    --qsfp1_rx_n(2) <= QSFP1_RX3_N;
    --qsfp1_rx_n(3) <= QSFP1_RX4_N;


    u_mace_mac: ENTITY vcu128_board_lib.mace_mac
    GENERIC MAP (
        g_technology         => g_technology)
    PORT MAP (
        sfp_rx_p             => qsfp1_rx_p(0),
        sfp_rx_n             => qsfp1_rx_n(0),
        sfp_tx_p             => qsfp1_tx_p(0),
        sfp_tx_n             => qsfp1_tx_n(0),
        sfp_clk_c_p          => QSFP1_SI570_CLOCK_P,
        sfp_clk_c_n          => QSFP1_SI570_CLOCK_N,
        system_reset         => system_reset,
        rst_clk              => clk_100,          -- in
        tx_clk               => clk_eth,          -- out;
        rx_clk               => OPEN,             -- out; Synchronous clock for PTP timing reference (also unreliable)
        axi_clk              => clk_eth,          -- in
        eth_rx_reset         => eth_rx_reset,
        eth_in_sosi          => eth_in_sosi,
        eth_in_siso          => eth_in_siso,
        eth_out_sosi         => eth_out_sosi,
        eth_out_siso         => eth_out_siso,
        eth_locked           => eth_locked,
        eth_tx_reset         => eth_tx_reset,
        local_mac            => local_mac,
        s_axi_mosi           => mc_lite_mosi(c_ethernet_mace_lite_index),
        s_axi_miso           => mc_lite_miso(c_ethernet_mace_lite_index),
        ctl_rx_pause_ack     => ctl_rx_pause_ack,
        ctl_rx_pause_enable  => ctl_rx_pause_enable,
        stat_rx_pause_req    => stat_rx_pause_req,
        -- debug
        dbg_rx_block_lock    => dbg_rx_block_lock,   -- out std_logic;
        dbg_rx_remote_fault  => dbg_rx_remote_fault, -- out std_logic;
        dbg_loopback         => dbg_loopback,        -- in std_logic_vector(2 downto 0);
        
        dstat_rx_total_bytes   => dstat_rx_total_bytes, -- : out STD_LOGIC_VECTOR(15 DOWNTO 0);
        dstat_rx_total_packets => dstat_rx_total_packets, -- : out STD_LOGIC_VECTOR(15 DOWNTO 0);
        dstat_rx_bad_fcs       => dstat_rx_bad_fcs, -- : out STD_LOGIC_VECTOR(15 DOWNTO 0);
        dstat_rx_user_pause    => dstat_rx_user_pause, -- : out STD_LOGIC_vector(15 downto 0);
        dstat_rx_vlan          => dstat_rx_vlan, -- : out STD_LOGIC_vector(15 downto 0);
        dstat_rx_oversize      => dstat_rx_oversize, -- : out STD_LOGIC_vector(15 downto 0);
        dstat_rx_packet_small  => dstat_rx_packet_small 
        
    );
    
    --local_mac <= x"f1d3ab238179";
    
--    u_qsfp1: ENTITY vcu128_board_lib.qsfp_10g
--    GENERIC MAP (
--        g_technology      => g_technology,
--        g_qsfp            => QSFP_A)
--    PORT MAP(
--        qsfp_clk_p        => QSFP1_SI570_CLOCK_P,
--        qsfp_clk_n        => QSFP1_SI570_CLOCK_N,
--        qsfp_tx_p         => qsfp1_tx_p,
--        qsfp_tx_n         => qsfp1_tx_n,
--        qsfp_rx_p         => qsfp1_rx_p,
--        qsfp_rx_n         => qsfp1_rx_n,
--        sys_rst           => rst_qsfp_a, -- system_reset,
--        axi_rst           => axi_rst,
--        rst_clk           => clk_50,
--        axi_clk           => clk_eth,
--        loopback          => qsfp_a_loopback,
--        tx_disable        => qsfp_a_tx_disable,
--        rx_disable        => qsfp_a_rx_disable,
--        tx_clk_out        => qsfp_a_tx_clk_out,
--        link_locked       => qsfp_a_rx_locked,
--        s_axi_mosi        => mc_lite_mosi(c_qsfp1_ethernet_quad_qsfp_lite_index),
--        s_axi_miso        => mc_lite_miso(c_qsfp1_ethernet_quad_qsfp_lite_index),
--        user_rx_reset     => traffic_user_rx_reset(41 TO 44),
--        user_tx_reset     => traffic_user_tx_reset(41 TO 44),
--        data_rx_sosi      => data_rx_sosi(41 TO 44),
--        data_rx_siso      => data_rx_siso(41 TO 44),
--        data_tx_sosi      => data_tx_sosi(41 TO 44),
--        data_tx_siso      => data_tx_siso(41 TO 44)
--    );

    -- QSFP2, 4x25GE interfaces
    QSFP2_TX1_P <= qsfp2_tx_p(0);
    QSFP2_TX2_P <= qsfp2_tx_p(1);
    QSFP2_TX3_P <= qsfp2_tx_p(2);
    QSFP2_TX4_P <= qsfp2_tx_p(3);
    
    QSFP2_TX1_N <= qsfp2_tx_n(0);
    QSFP2_TX2_N <= qsfp2_tx_n(1);
    QSFP2_TX3_N <= qsfp2_tx_n(2);
    QSFP2_TX4_N <= qsfp2_tx_n(3);
    
    qsfp2_rx_p(0) <= QSFP2_RX1_P;
    qsfp2_rx_p(1) <= QSFP2_RX2_P;
    qsfp2_rx_p(2) <= QSFP2_RX3_P;
    qsfp2_rx_p(3) <= QSFP2_RX4_P;
    
    qsfp2_rx_n(0) <= QSFP2_RX1_N;
    qsfp2_rx_n(1) <= QSFP2_RX2_N;
    qsfp2_rx_n(2) <= QSFP2_RX3_N;
    qsfp2_rx_n(3) <= QSFP2_RX4_N;    
    
    u_qsfp2: ENTITY vcu128_board_lib.qsfp_25g
    GENERIC MAP (
        g_technology      => g_technology,
        g_qsfp            => QSFP2)
    PORT MAP(
        qsfp_clk_p        => QSFP2_SI570_CLOCK_P,
        qsfp_clk_n        => QSFP2_SI570_CLOCK_N,
        qsfp_tx_p         => qsfp2_tx_p,
        qsfp_tx_n         => qsfp2_tx_n,
        qsfp_rx_p         => qsfp2_rx_p,
        qsfp_rx_n         => qsfp2_rx_n,
        sys_rst           => rst_qsfp_b, -- system_reset,
        axi_rst           => axi_rst,
        rst_clk           => clk_50,
        axi_clk           => clk_eth,
        loopback          => qsfp_b_loopback,
        tx_disable        => qsfp_b_tx_disable,
        rx_disable        => qsfp_b_rx_disable,
        tx_clk_out        => qsfp_b_tx_clk_out,
        link_locked       => qsfp_b_rx_locked,
        s_axi_mosi        => mc_lite_mosi(c_qsfp2_ethernet_quad_qsfp_lite_index),
        s_axi_miso        => mc_lite_miso(c_qsfp2_ethernet_quad_qsfp_lite_index),
        user_rx_reset     => traffic_user_rx_reset(37 TO 40),
        user_tx_reset     => traffic_user_tx_reset(37 TO 40),
        data_rx_sosi      => data_rx_sosi(37 TO 40),
        data_rx_siso      => data_rx_siso(37 TO 40),
        data_tx_sosi      => data_tx_sosi(37 TO 40),
        data_tx_siso      => data_tx_siso(37 TO 40)
    );

------------------

    -- QSFP3, 100GE interface
    QSFP3_TX1_P <= qsfp3_tx_p(0);
    QSFP3_TX2_P <= qsfp3_tx_p(1);
    QSFP3_TX3_P <= qsfp3_tx_p(2);
    QSFP3_TX4_P <= qsfp3_tx_p(3);
    
    QSFP3_TX1_N <= qsfp3_tx_n(0);
    QSFP3_TX2_N <= qsfp3_tx_n(1);
    QSFP3_TX3_N <= qsfp3_tx_n(2);
    QSFP3_TX4_N <= qsfp3_tx_n(3);
    
    qsfp3_rx_p(0) <= QSFP3_RX1_P;
    qsfp3_rx_p(1) <= QSFP3_RX2_P;
    qsfp3_rx_p(2) <= QSFP3_RX3_P;
    qsfp3_rx_p(3) <= QSFP3_RX4_P;
    
    qsfp3_rx_n(0) <= QSFP3_RX1_N;
    qsfp3_rx_n(1) <= QSFP3_RX2_N;
    qsfp3_rx_n(2) <= QSFP3_RX3_N;
    qsfp3_rx_n(3) <= QSFP3_RX4_N;  

    u_qsfp3: ENTITY vcu128_board_lib.qsfp_100g
    GENERIC MAP (
        g_technology             => g_technology,
        g_qsfp                   => QSFP3)
    PORT MAP(
        qsfp_clk_p               => qsfp3_SI570_CLOCK_P,     -- Dedicated 161MHz clock
        qsfp_clk_n               => qsfp3_SI570_CLOCK_N,
        qsfp_tx_p                => qsfp3_tx_p,
        qsfp_tx_n                => qsfp3_tx_n,
        qsfp_rx_p                => qsfp3_rx_p,
        qsfp_rx_n                => qsfp3_rx_n,
        sys_rst                  => rst_qsfp_c, -- system_reset,
        axi_rst                  => axi_rst,
        rst_clk                  => clk_50,
        axi_clk                  => clk_eth,
        loopback                 => qsfp_c_loopback,
        tx_disable               => qsfp_c_tx_disable(0),
        rx_disable               => qsfp_c_rx_disable(0),
        tx_clk_out               => qsfp_c_tx_clk_out,
        link_locked              => qsfp3_rx_locked(0),
        s_axi_mosi               => mc_lite_mosi(c_qsfp3_ethernet_qsfp_lite_index),
        s_axi_miso               => mc_lite_miso(c_qsfp3_ethernet_qsfp_lite_index),
        user_rx_reset            => ctraffic_user_rx_reset,
        user_tx_reset            => ctraffic_user_tx_reset,
        data_rx_sosi             => cdata_rx_sosi,
        data_tx_sosi             => cdata_tx_sosi,
        data_tx_siso             => cdata_tx_siso
    );

    qsfp3_rx_locked(1 TO 3) <= (OTHERS => qsfp3_rx_locked(0));

    ------------------
    -- QSFP4, 40GE interface
    QSFP4_TX1_P <= qsfp4_tx_p(0);
    QSFP4_TX2_P <= qsfp4_tx_p(1);
    QSFP4_TX3_P <= qsfp4_tx_p(2);
    QSFP4_TX4_P <= qsfp4_tx_p(3);
    
    QSFP4_TX1_N <= qsfp4_tx_n(0);
    QSFP4_TX2_N <= qsfp4_tx_n(1);
    QSFP4_TX3_N <= qsfp4_tx_n(2);
    QSFP4_TX4_N <= qsfp4_tx_n(3);
    
    qsfp4_rx_p(0) <= QSFP4_RX1_P;
    qsfp4_rx_p(1) <= QSFP4_RX2_P;
    qsfp4_rx_p(2) <= QSFP4_RX3_P;
    qsfp4_rx_p(3) <= QSFP4_RX4_P;
    
    qsfp4_rx_n(0) <= QSFP4_RX1_N;
    qsfp4_rx_n(1) <= QSFP4_RX2_N;
    qsfp4_rx_n(2) <= QSFP4_RX3_N;
    qsfp4_rx_n(3) <= QSFP4_RX4_N;  

    u_qsfp4 : ENTITY vcu128_board_lib.qsfp_40g
    GENERIC MAP (
        g_technology      => g_technology,
        g_qsfp            => QSFP4)
    PORT MAP(
        qsfp_clk_p        => qsfp4_SI570_CLOCK_P,          -- 156.25MHz clock shared
        qsfp_clk_n        => qsfp4_SI570_CLOCK_N,
        qsfp_tx_p         => qsfp4_tx_p,
        qsfp_tx_n         => qsfp4_tx_n,
        qsfp_rx_p         => qsfp4_rx_p,
        qsfp_rx_n         => qsfp4_rx_n,
        sys_rst           => rst_qsfp_d,  -- system_reset,
        axi_rst           => axi_rst,
        rst_clk           => clk_50,
        axi_clk           => clk_eth,
        loopback          => qsfp4_loopback,
        tx_disable        => qsfp4_tx_disable(0),
        rx_disable        => qsfp4_rx_disable(0),
        tx_clk_out        => qsfp4_tx_clk_out,
        link_locked       => qsfp4_rx_locked(0),
        rx_locked         => qmac_rx_locked,
        rx_synced         => qmac_rx_synced,
        rx_aligned        => qmac_rx_aligned,
        rx_status         => qmac_rx_status,
        user_rx_reset     => traffic_user_rx_reset(36),
        user_tx_reset     => traffic_user_tx_reset(36),
        s_axi_mosi        => mc_lite_mosi(c_qsfp4_ethernet_qsfp_lite_index),
        s_axi_miso        => mc_lite_miso(c_qsfp4_ethernet_qsfp_lite_index),
        -- received data from optics (sosi = source out, sink in)
        data_rx_sosi      => data_rx_sosi(36),
        data_rx_siso      => data_rx_siso(36),
        -- data to be sent to the optics
        data_tx_sosi      => data_tx_sosi(36),
        data_tx_siso      => data_tx_siso(36)
    );

    qsfp4_rx_locked(1 TO 3) <= (OTHERS => qsfp4_rx_locked(0));

------------------

   qsfp_support: ENTITY vcu128_board_lib.qsfp_control
   GENERIC MAP (
      g_technology      => g_technology)
   PORT MAP (
      clk               => clk_eth,
      rst               => axi_rst,
      s_axi_mosi        => mc_lite_mosi(c_qsfp_lite_index),
      s_axi_miso        => mc_lite_miso(c_qsfp_lite_index),
      qsfp_a_tx_disable => qsfp_a_tx_disable,
      qsfp_a_rx_disable => qsfp_a_rx_disable,
      qsfp_a_loopback   => qsfp_a_loopback,
      qsfp_a_rx_locked  => qsfp_a_rx_locked,
      qsfp_b_tx_disable => qsfp_b_tx_disable,
      qsfp_b_rx_disable => qsfp_b_rx_disable,
      qsfp_b_loopback   => qsfp_b_loopback,
      qsfp_b_rx_locked  => qsfp_b_rx_locked,
--      qsfp_c_tx_disable => qsfp_c_tx_disable,
 --     qsfp_c_rx_disable => qsfp_c_rx_disable,
      qsfp_c_loopback   => qsfp_c_loopback,
      qsfp_c_rx_locked  => qsfp_c_rx_locked,
      qsfp_d_tx_disable => qsfp4_tx_disable,
      qsfp_d_rx_disable => qsfp4_rx_disable,
      qsfp_d_loopback   => qsfp4_loopback,
      qsfp_d_rx_locked  => qsfp4_rx_locked,
      qsfp_a_mod_prs_n  => qsfp1_modprsl_ls,
      qsfp_a_mod_sel    => qsfp1_modskl_ls,
      qsfp_a_reset      => qsfp1_reset_ls,
      qsfp_b_mod_prs_n  => qsfp2_modprsl_ls,
      qsfp_b_mod_sel    => qsfp2_modskl_ls,
      qsfp_b_reset      => qsfp2_reset_ls,
      qsfp_c_mod_prs_n  => qsfp3_modprsl_ls,
      qsfp_c_mod_sel    => qsfp3_modskl_ls,
      qsfp_c_reset      => qsfp3_reset_ls,
      qsfp_d_mod_prs_n  => qsfp4_modprsl_ls,
      qsfp_d_mod_sel    => qsfp4_modskl_ls,
      qsfp_d_reset      => qsfp4_reset_ls,
      qsfp_int_n        => qsfp_int_n, -- Not connected yet on vcu128 board - needs to go through a switch on the board.
      qsfp_sda          => qsfp_sda,
      qsfp_scl          => qsfp_scl);
   
   -- inverted on the board in the gemini card; not inverted on the vcu128 
   -- So invert here.
   qsfp1_modskll_ls <= not qsfp1_modskl_ls;
   qsfp1_resetl_ls <= not (qsfp1_reset_ls or probe_out0(0));
   qsfp2_modskll_ls <= not qsfp2_modskl_ls;
   qsfp2_resetl_ls <= not qsfp2_reset_ls;
   qsfp3_modskll_ls <= not qsfp3_modskl_ls;
   qsfp3_resetl_ls <= not qsfp3_reset_ls;
   qsfp4_modskll_ls <= not qsfp4_modskl_ls;
   qsfp4_resetl_ls <= not qsfp4_reset_ls;
   
   qsfp_a_led <= '1' WHEN qsfp1_rx_locked /= X"0" ELSE '0';
   qsfp_b_led <= '1' WHEN qsfp2_rx_locked /= X"0" ELSE '0';
   
   process(qsfp_c_tx_clk_out)
   begin
      if rising_edge(qsfp_c_tx_clk_out) then
         if qsfp_c_rx_locked /= X"0" then
            qsfp_c_led_del1 <= '1';
         else
            qsfp_c_led_del1 <= '0';
         end if;
         qsfp_c_led_del2 <= qsfp_c_led_del1;
         qsfp_c_led <= qsfp_c_led_del2;
      end if;
   end process;
   
   process(qsfp4_tx_clk_out)
   begin
      if rising_edge(qsfp4_tx_clk_out) then
         if qsfp4_rx_locked /= X"0" then
            qsfp_d_led_del1 <= '1';
         else
            qsfp_d_led_del1 <= '0';
         end if;
         qsfp_d_led_del2 <= qsfp_d_led_del1;
         qsfp_d_led <= qsfp_d_led_del2;
      end if;
   end process;


  ---------------------------------------------------------------------------
  -- Packet Generators  --
  ---------------------------------------------------------------------------


   traffic_rx_lock(36) <= qsfp4_rx_locked(0);
   traffic_rx_lock(37 TO 40) <= qsfp_b_rx_locked;
   traffic_rx_lock(41 TO 44) <= qsfp_a_rx_locked;


    trdygen0 : for i in 0 to 35 generate
        data_rx_siso(i).tready <= '1'; -- Always ready, but not actually used in MAC
    end generate;
    trdygen1 : for i in 37 to 44 generate
        data_rx_siso(i).tready <= '1';
    end generate;

    pkt_gen: FOR i IN 0 TO 44 GENERATE

        data_reg: PROCESS(traffic_gen_clk(i))
        BEGIN
           IF rising_edge(traffic_gen_clk(i)) THEN
              data_rx_sosi_reg(i) <= data_rx_sosi(i);
           END IF;
        END PROCESS;
    
        --
        -- No packet generation/monitoring in DSP version.
        data_tx_sosi(i).tvalid <= '0';
        data_tx_sosi(i).tdata <= (others => '0');
        data_tx_sosi(i).tlast <= '0';
        data_tx_sosi(i).tkeep <= (others => '0');
        data_tx_sosi(i).tuser <= (others => '0');
        completion_status(i) <= "00001";
    
        --   skip_40g: IF i /= 36 GENERATE
        --  Use pkt_gen_mon component here if needed ...
        
        lane_ok(i) <= '1' WHEN completion_status(i) = "00001" ELSE '0';

    END GENERATE;
   
    completion_status(36) <= "00000";
    data_tx_sosi(36).tvalid <= '0';
    data_tx_sosi(36).tdata <= (others => '0');
    data_tx_sosi(36).tuser <= (others => '0');
   
    qsfp_c_tx_disable(0) <= NOT ctraffic_tx_enable;
    qsfp_c_rx_disable(0) <= NOT ctraffic_rx_enable;
    ctraffic_rx_aligned <= qsfp_c_rx_locked(0);

    ---------------------------------------------------------------------------
    -- Ethernet MAC & Framework  --
    ---------------------------------------------------------------------------



    axi_rst <= eth_tx_reset;

--    sfp_support: ENTITY vcu128_board_lib.sfp_control
--    GENERIC MAP (
--        g_technology   => g_technology)
--    PORT MAP (
--        rst            => axi_rst,
--        clk            => clk_eth,
--        s_axi_mosi     => mc_lite_mosi(c_sfp_lite_index),
--        s_axi_miso     => mc_lite_miso(c_sfp_lite_index),
--        sfp_sda        => sfp_sda,
--        sfp_scl        => sfp_scl,
--        sfp_fault      => sfp_fault,
--        sfp_tx_enable  => sfp_tx_enable,
--        sfp_mod_abs    => sfp_mod_abs);

--    sfp_led <= eth_locked;


    ---------------------------------------------------------------------------
    -- MACE Protocol Blocks  --
    ---------------------------------------------------------------------------


    u_eth_rx: ENTITY eth_lib.eth_rx
    GENERIC MAP (
        g_technology      => g_technology,
        g_num_eth_lanes   => c_num_eth_lanes)
    PORT MAP (
        clk               => clk_eth,
        rst               => axi_rst,   -- do not use gemini_mm_rst, as it is only for modules downstream of the gemini block.
        mymac_addr        => local_mac,
        eth_in_sosi       => eth_in_sosi,
        eth_out_sosi      => decoder_out_sosi,
        eth_out_siso      => decoder_out_siso);

    u_eth_tx : ENTITY eth_lib.eth_tx
    GENERIC MAP (
        g_technology         => g_technology,
        g_num_frame_inputs   => c_num_eth_lanes,
        g_max_packet_length  => c_max_packet_length,
        g_lane_priority      => c_tx_priority)
    PORT MAP (
        eth_tx_clk           => clk_eth,
        eth_rx_clk           => clk_eth,
        axi_clk              => clk_eth,
        axi_rst              => axi_rst,  -- do not use gemini_mm_rst, as it is only for modules downstream of the gemini block.
        eth_tx_rst           => eth_tx_reset,
        eth_address_ip       => local_ip,
        eth_address_mac      => local_mac,
        eth_pause_rx_enable  => ctl_rx_pause_enable,
        eth_pause_rx_req     => stat_rx_pause_req,
        eth_pause_rx_ack     => ctl_rx_pause_ack,
        eth_out_sosi         => eth_out_sosi,
        eth_out_siso         => eth_out_siso,
        framer_in_sosi       => encoder_in_sosi,
        framer_in_siso       => encoder_in_siso);

    u_gemini_server: ENTITY gemini_server_lib.gemini_server
    GENERIC MAP (
        g_technology         => g_technology,
        g_txfr_timeout       => 20000,  -- Can take up to 9 clocks per word read using axi-lite, so maximum ethernet packet of 2048 words (=jumbo packet of 8192 bytes) needs about 18000 clocks. 
        g_min_recycle_secs   => 30)     -- Need to timeout connections straight away
    PORT MAP (
        clk                  => clk_eth,
        rst                  => axi_rst,
        mm_reset_out         => gemini_mm_rst,  -- out std_logic; -- reset to downstream modules on the mm bus, to prevent lockup from broken transactions issued by the datamover when it is reset.
        ethrx_in             => decoder_out_sosi(0),
        ethrx_out            => decoder_out_siso(0),
        ethtx_in             => encoder_in_siso(0),
        ethtx_out            => encoder_in_sosi(0),
        mm_in                => mc_master_miso,
        mm_out               => mc_master_mosi,
        tod_in               => system_fields_ro.time_uptime,
        -- debug
        req_csrb_state => req_crsb_state, -- out std_logic_vector(2 downto 0);
        req_main_state => req_main_state, -- out std_logic_vector(3 downto 0);
        replay_state   => replay_state,   -- out std_logic_vector(3 downto 0);
        completion_state => completion_state, --  out std_logic_vector(3 downto 0);
        rq_state         => rq_state,        -- out std_logic_vector(3 downto 0);
        rq_stream_state  => rq_stream_state, -- out std_logic_vector(3 downto 0);
        resp_state       => resp_state,       -- out std_logic_vector(3 downto 0);
        crqb_fifo_rd_data_sel_out => crqb_fifo_rd_data_sel_out, --  out std_logic_vector(87 DOWNTO 0);
        crqb_fifo_rd_out => crqb_fifo_rd_out,  -- out std_logic_vector(2 downto 0)
        -- debug commands to datamover
        s2mm_in_dbg  => s2mm_in_dbg, -- : out t_axi4_sosi;  -- Sink in
        s2mm_out_dbg => s2mm_out_dbg, -- : out t_axi4_siso; -- Sink out
        -- AXI4S Sink: S2MM Command
        s2mm_cmd_in_dbg => s2mm_cmd_in_dbg, -- : out t_axi4_sosi; -- Sink in
        s2mm_cmd_out_dbg => s2mm_cmd_out_dbg, -- : OUT t_axi4_siso; -- Sink out
        -- AXI4S Source: M_AXIS_S2MM_STS
        s2mm_sts_in_dbg => s2mm_sts_in_dbg, -- : out t_axi4_siso;  -- Source in
        s2mm_sts_out_dbg => s2mm_sts_out_dbg, -- : OUT t_axi4_sosi  -- Source out
        dbg_timer_expire => dbg_timer_expire, -- out std_logic;
        dbg_timer => dbg_timer -- : out std_logic_vector(15 downto 0)
    );

    decoder_out_siso(1).tready <= '1';

    dhcp_start <= (eth_locked or probe_out0(1)); --  AND prom_startup_complete;

    u_dhcp_protocol: ENTITY dhcp_lib.dhcp_protocol
    GENERIC MAP (
        g_technology         => g_technology,
        -- Startup delay (after reset) before transmitting (in mS)
        -- The switch takes 30 seconds to wake up when the new bitfile is loaded, so wait a bit past that before requesting an IP address. 
        g_startup_delay      => 35000                     
    )
    PORT MAP (
        axi_clk              => clk_eth,
        axi_rst              => axi_rst,
        mm_rst               => axi_rst, -- in std_logic, for logic connected to s_axi_mosi, s_axi_miso.
        ip_address_default   => prom_ip,
        mac_address          => local_mac,
        serial_number        => serial_number,
        dhcp_start           => dhcp_start,
        ip_address           => local_ip,
        ip_event             => event_in(0),
        s_axi_mosi           => mc_lite_mosi(c_dhcp_lite_index),
        s_axi_miso           => mc_lite_miso(c_dhcp_lite_index),
        frame_in_sosi        => decoder_out_sosi(2),
        frame_in_siso        => decoder_out_siso(2),
        frame_out_sosi       => encoder_in_sosi(2),
        frame_out_siso       => encoder_in_siso(2));

    u_arp_protocol: ENTITY arp_lib.arp_responder
    GENERIC MAP (
        g_technology   => g_technology)
    PORT MAP (
        clk            => clk_eth,
        rst            => axi_rst,
        eth_addr_ip    => local_ip,
        eth_addr_mac   => local_mac,
        frame_in_sosi  => decoder_out_sosi(3),
        frame_in_siso  => decoder_out_siso(3),
        frame_out_siso => encoder_in_siso(3),
        frame_out_sosi => encoder_in_sosi(3));

    u_icmp_protocol: ENTITY ping_protocol_lib.ping_protocol
    PORT MAP (
        clk            => clk_eth,
        rst            => axi_rst,
        my_mac         => local_mac,
        eth_in_sosi    => decoder_out_sosi(4),
        eth_in_siso    => decoder_out_siso(4),
        eth_out_sosi   => encoder_in_sosi(4),
        eth_out_siso   => encoder_in_siso(4));

    u_pubsub_protocol: ENTITY gemini_subscription_lib.subscription_protocol
    GENERIC MAP (
        g_technology      => g_technology,
        g_num_clients     => 3)
    PORT MAP (
        axi_clk           => clk_eth,
        axi_rst           => axi_rst,
        mm_rst            => axi_rst, -- in std_logic, for logic connected to s_axi_mosi, s_axi_miso.
        time_in           => local_time,
        event_in          => event_in,
        s_axi_mosi        => mc_lite_mosi(c_gemini_subscription_lite_index),
        s_axi_miso        => mc_lite_miso(c_gemini_subscription_lite_index),
        stream_out_sosi   => encoder_in_sosi(5),
        stream_out_siso   => encoder_in_siso(5));

    decoder_out_siso(5).tready <= '1';


    ---------------------------------------------------------------------------
    -- Bus Interconnect  --
    ---------------------------------------------------------------------------

    u_interconnect: ENTITY work.vcu128_gemini_dsp_bus_top
    --u_interconnect: ENTITY vcu128_gemini_dsp_lib.vcu128_gemini_dsp_bus_top
    PORT MAP (
        CLK            => clk_eth,
        RST            => gemini_mm_rst, -- axi_rst,
        SLA_IN         => mc_master_mosi,
        SLA_OUT        => mc_master_miso,
        MSTR_IN_LITE   => mc_lite_miso,
        MSTR_OUT_LITE  => mc_lite_mosi,
        MSTR_IN_FULL   => mc_full_miso,
        MSTR_OUT_FULL  => mc_full_mosi);

    ---------------------------------------------------------------------------
    -- DDR4 Memory  --
    ---------------------------------------------------------------------------

    --led2_colour <= (others => '0');

    ---------------------------------------------------------------------------
    -- LED SUPPORT  --
    ---------------------------------------------------------------------------

    -- Use the local pps to generate a LED pulse
    led_pps_extend : ENTITY common_lib.common_pulse_extend
    GENERIC MAP (
        g_extend_w  => 23) -- 84ms on time
    PORT MAP (
        clk         => clk_100,
        rst         => '0',
        p_in        => pps,
        ep_out      => pps_extended);

    eth_act_cross: ENTITY common_lib.common_async
    GENERIC MAP (
        g_delay_len => 1)
    PORT MAP (
        rst         => '0',
        clk         => clk_eth,
        din         => eth_in_sosi.tlast,
        dout        => eth_act);

    -- Ethernet Activity
    led_act_extend : ENTITY common_lib.common_pulse_extend
    GENERIC MAP (
        g_extend_w  => 24) -- 167ms on time
    PORT MAP (
        clk         => clk_100,
        rst         => '0',
        p_in        => eth_act,
        ep_out      => eth_act_extended);

     -- Status LED



    ---------------------------------------------------------------------------
    -- HARDWARE BOARD SUPPORT  --
    ---------------------------------------------------------------------------

--    pmbus_support: ENTITY gemini_lru_board_lib.pmbus_control
--    GENERIC MAP (
--        g_technology   => g_technology)
--    PORT MAP (
--        clk            => clk_eth,
--        rst            => axi_rst,
--        s_axi_mosi     => mc_lite_mosi(c_pmbus_lite_index),
--        s_axi_miso     => mc_lite_miso(c_pmbus_lite_index),
--        power_sda      => power_sda,
--        power_sdc      => power_sdc,
--        power_alert_n  => power_alert_n);


--     prom_ip <= x"12345678";
     serial_number <= x"00000001";


    -- Second SPI PROM CS pin not through startup block
--    spi_cs(1) <= prom_spi_ss_o WHEN prom_spi_ss_t = '0' ELSE 'Z';

--    spi_d(4) <= prom_spi_o(0) WHEN prom_spi_t(0) = '0' ELSE 'Z';
--    prom_spi_i(0) <= spi_d(4);

--    spi_d(5) <= prom_spi_o(1) WHEN prom_spi_t(1) = '0' ELSE 'Z';
--    prom_spi_i(1) <= spi_d(5);

--    spi_d(6) <= prom_spi_o(2) WHEN prom_spi_t(2) = '0' ELSE 'Z';
--    prom_spi_i(2) <= spi_d(6);

--    spi_d(7) <= prom_spi_o(3) WHEN prom_spi_t(3) = '0' ELSE 'Z';
--    prom_spi_i(3) <= spi_d(7);

    system_monitor: ENTITY tech_system_monitor_lib.tech_system_monitor
    GENERIC MAP (
        g_technology      => g_technology)
    PORT MAP (
        axi_clk           => clk_eth,
        axi_reset         => axi_rst,
        axi_lite_mosi     => mc_lite_mosi(c_system_monitor_lite_index),
        axi_lite_miso     => mc_lite_miso(c_system_monitor_lite_index),
        over_temperature  => event_in(2),
        voltage_alarm     => OPEN,
        temp_out          => OPEN,
        v_p               => '0',
        v_n               => '0',
        vaux_p            => X"0000",
        vaux_n            => X"0000");


    ---------------------------------------------------------------------------
    -- TOP Level Registers  --
    ---------------------------------------------------------------------------

    fpga_regs: ENTITY work.vcu128_gemini_dsp_system_reg
    GENERIC MAP (
        g_technology      => g_technology)
    PORT MAP (
        mm_clk            => clk_eth,
        mm_rst            => axi_rst,
        sla_in            => mc_lite_mosi(c_system_lite_index),
        sla_out           => mc_lite_miso(c_system_lite_index),
        system_fields_rw  => system_fields_rw,
        system_fields_ro  => system_fields_ro);

    -- Build Date
    u_useraccese2: USR_ACCESSE2
    PORT MAP (
        CFGCLK     => OPEN,
        DATA       => system_fields_ro.build_date,
        DATAVALID  => OPEN);

    -- Uptime counter
    uptime_cnt: ENTITY vcu128_board_lib.uptime_counter
    GENERIC MAP (
        g_tod_width    => 14,
        g_clk_freq     => 100.0E6)
    PORT MAP (
        clk            => clk_100,
        rst            => system_reset,
        pps            => pps,
        tod_rollover   => system_fields_ro.time_wrapped,
        tod            => system_fields_ro.time_uptime);

    -- Broadcast shutdown request
    event_in(1) <= '0';
    
    --------------------------------------------------------------------------
    -- Signal Processing
    dsp_topi : entity dsp_top_lib.DSP_top
    generic map (
        ARRAYRELEASE => 0, -- : integer range -2 to 5 := 0;
        g_sim        => false -- : BOOLEAN := FALSE
    )
    port map (
        -- Processing clocks
        i_clk100 => clk_100,          -- in std_logic; -- HBM reference clock
        -- HBM_AXI_clk and wallClk should be derived from the OCXO on the gemini boards, so that clocks on different boards run very close to the same frequency.
        i_HBM_clk => clk_400,         -- in std_logic; -- 400 MHz for the vcu128 board, up to 450 for production devices. Also used for general purpose processing.
        i_HBM_clk_rst => clk_400_rst, -- in std_logic;
        i_wall_clk => wall_clk, -- in std_logic;    -- 250 MHz, derived from the 125MHz OCXO. Used for timing of events (e.g. when to start reading in the corner turn)
        -- 40GE LFAA ingest data
        i_LFAA40GE => data_rx_sosi(36),     -- in t_axi4_sosi;
        o_LFAA40GE => data_rx_siso(36),     -- out t_axi4_siso;
        i_LFAA40GE_clk => qsfp4_tx_clk_out, -- in std_logic;
        i_mac40G => mac40G,                 -- in std_logic_vector(47 downto 0); --    mac40G <= x"aabbccddeeff";
        -- XYZ interconnect inputs
        i_gtyZdata  => (others => (others => '0')), -- in t_slv_64_arr(6 downto 0);
        i_gtyZValid => "0000000", -- in std_logic_vector(6 downto 0);
        i_gtyZSof   => "0000000", -- in std_logic_vector(6 downto 0);
        i_gtyZEof   => "0000000", -- in std_logic_vector(6 downto 0);
        i_gtyYdata  => (others => (others => '0')), -- in t_slv_64_arr(4 downto 0);
        i_gtyYValid => "00000", -- in std_logic_vector(4 downto 0);
        i_gtyYSof   => "00000", -- in std_logic_vector(4 downto 0);
        i_gtyYEof   => "00000", -- in std_logic_vector(4 downto 0);
        i_gtyXdata  => (others => (others => '0')), -- in t_slv_64_arr(4 downto 0);
        i_gtyXValid => "00000", -- in std_logic_vector(4 downto 0);
        i_gtyXSof   => "00000", -- in std_logic_vector(4 downto 0);
        i_gtyXEof   => "00000", -- in std_logic_vector(4 downto 0);        
        -- XYZ interconnect outputs
        o_gtyZData  => open,    -- out t_slv_64_arr(6 downto 0);
        o_gtyZValid => open,    -- out std_logic_vector(6 downto 0);
        o_gtyYData  => open,    -- out t_slv_64_arr(4 downto 0);
        o_gtyYValid => open,    -- out std_logic_vector(4 downto 0);
        o_gtyXData  => open,    -- out t_slv_64_arr(4 downto 0);
        o_gtyXValid => open,    -- out std_logic_vector(4 downto 0);
        -- Serial interface to the OCXO
        o_ptp_pll_reset => open, -- out std_logic;                     -- PLL reset
        o_ptp_clk_sel   => open, -- out std_logic;                     -- PTP Interface (156.25MH select when high)
        o_ptp_sync_n    => open, -- out std_logic_vector(1 downto 0);  -- bit(0) = active low enable for DAC controlling the clk_e = 25 MHz crystal (which is then upconverted to either 125 or 156.25 MHz), bit(1) = active low enable for DAC controlling the clk_f = 20 MHz crystal.  
        o_ptp_sclk      => open, -- out std_logic;
        o_ptp_din       => open, -- out std_logic;
        -----------------------------------------------------------------------
        -- AXI slave interfaces for modules
        i_MACE_clk  => clk_eth, -- in std_logic;
        i_MACE_rst  => axi_rst, -- in std_logic;
        -- dsp top full slave (access to the HBM)
        i_HBMDbgFull_axi_mosi => mc_full_mosi(c_dsp_top_full_index), -- in t_axi4_full_mosi;
        o_HBMDbgFull_axi_miso => mc_full_miso(c_dsp_top_full_index), -- out t_axi4_full_miso;
        -- DSP top lite slave
        i_dsptopLite_axi_mosi => mc_lite_mosi(c_dsp_top_lite_index), -- in t_axi4_lite_mosi;
        o_dsptopLite_axi_miso => mc_lite_miso(c_dsp_top_lite_index), -- out t_axi4_lite_miso;
        -- LFAADecode, lite + full slave
        i_LFAALite_axi_mosi => mc_lite_mosi(c_LFAADecode_lite_index), -- in t_axi4_lite_mosi; 
        o_LFAALite_axi_miso => mc_lite_miso(c_LFAADecode_lite_index), -- out t_axi4_lite_miso;
        i_LFAAFull_axi_mosi => mc_full_mosi(c_lfaadecode_full_index), -- in  t_axi4_full_mosi;
        o_LFAAFull_axi_miso => mc_full_miso(c_lfaadecode_full_index), -- out t_axi4_full_miso;
        -- Capture, lite + full
        i_Cap128Lite_axi_mosi => mc_lite_mosi(c_capture128bit_lite_index), -- in t_axi4_lite_mosi;
        o_Cap128Lite_axi_miso => mc_lite_miso(c_capture128bit_lite_index), -- out t_axi4_lite_miso;
        i_Cap128Full_axi_mosi => mc_full_mosi(c_capture128bit_full_index), -- in  t_axi4_full_mosi;
        o_Cap128Full_axi_miso => mc_full_miso(c_capture128bit_full_index), -- out t_axi4_full_miso;
        -- Timing control
        i_timing_axi_mosi => mc_lite_mosi(c_timingcontrol_lite_index), -- in  t_axi4_lite_mosi;
        o_timing_axi_miso => mc_lite_miso(c_timingcontrol_lite_index), -- out t_axi4_lite_miso;
        -- Interconnect
        i_IC_axi_mosi => mc_lite_mosi(c_interconnect_lite_index), -- in t_axi4_lite_mosi;
        o_IC_axi_miso => mc_lite_miso(c_interconnect_lite_index), -- out t_axi4_lite_miso;
        -- Corner Turn
        i_CTC_axi_mosi => mc_lite_mosi(c_config_lite_index), -- in  t_axi4_lite_mosi;
        o_CTC_axi_miso => mc_lite_miso(c_config_lite_index), -- out t_axi4_lite_miso;
        -- Fine Capture, lite + full
        i_CapFineLite_axi_mosi => mc_lite_mosi(c_capturefine_lite_index), -- in  t_axi4_lite_mosi;
        o_CapFineLite_axi_miso => mc_lite_miso(c_capturefine_lite_index), -- out t_axi4_lite_miso;
        i_CapFineFull_axi_mosi => mc_full_mosi(c_capturefine_full_index), -- in  t_axi4_full_mosi; 
        o_CapFineFull_axi_miso => mc_full_miso(c_capturefine_full_index), -- out t_axi4_full_miso;
        -- Filterbanks FIR taps
        i_FB_axi_mosi => mc_full_mosi(c_filterbanks_full_index), -- in t_axi4_full_mosi;
        o_FB_axi_miso => mc_full_miso(c_filterbanks_full_index)  -- out t_axi4_full_miso
    );
    
    mac40G <= x"aabbccddeeff";
    
    
    ---------------------------------------------------------------------------
    -- Debug  --
    ---------------------------------------------------------------------------

    wvalid0 <= mc_lite_mosi(0).awvalid;
    wvalid1 <= mc_lite_mosi(1).awvalid;
    wvalid2 <= mc_lite_mosi(2).awvalid;
    wvalid3 <= mc_lite_mosi(3).awvalid;
    rvalid0 <= mc_lite_mosi(0).arvalid;
    rvalid1 <= mc_lite_mosi(1).arvalid;
    rvalid2 <= mc_lite_mosi(2).arvalid;
    rvalid3 <= mc_lite_mosi(3).arvalid;
    
    connectdbg : ila_0
    port map (
        clk => clk_eth,
        probe0(0) => eth_rx_reset,
        probe0(1) => eth_tx_reset,
        probe0(2) => eth_locked,
        probe0(3) => eth_in_sosi.tvalid,
        probe0(4) => eth_in_sosi.tuser(0),
        probe0(5) => eth_in_sosi.tlast,
        probe0(7 downto 6) => gnd(7 downto 6),
        probe0(15 downto 8) => eth_in_sosi.tkeep(7 downto 0),
        probe0(79 downto 16) => eth_in_sosi.tdata(63 downto 0),
        probe0(80) => dbg_rx_block_lock,
        probe0(81) => dbg_rx_remote_fault,
        
        probe0(97 downto 82) => dstat_rx_total_bytes , --  :  STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe0(113 downto 98) => dstat_rx_total_packets, -- :  STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe0(129 downto 114) => dstat_rx_bad_fcs, --        :  STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe0(145 downto 130) => dstat_rx_user_pause, --    :  STD_LOGIC_vector(15 downto 0);
        probe0(161 downto 146) => dstat_rx_vlan, --          :  STD_LOGIC_vector(15 downto 0);
        probe0(177 downto 162) => dstat_rx_oversize, --      :  STD_LOGIC_vector(15 downto 0);
        probe0(193 downto 178) => dstat_rx_packet_small,        
        
        probe0(194) => probe_out0(0),
        probe0(195) => probe_out0(1),
        probe0(196) => probe_out0(2),
        probe0(199 downto 197) => probe_out0(6 downto 4)
    );
    

    connectdbg2 : ila_0
    port map (
        clk => clk_eth,
        probe0(63 downto 0) => eth_out_sosi.tdata(63 downto 0),
        probe0(71 downto 64) => eth_out_sosi.tkeep(7 downto 0),
        probe0(72) => eth_out_sosi.tlast,
        probe0(73) => eth_out_sosi.tvalid,
        probe0(74) => eth_in_sosi.tvalid,
        probe0(75) => eth_in_sosi.tlast,
        probe0(83 downto 76) => eth_in_sosi.tkeep(7 downto 0),
        probe0(147 downto 84) => eth_in_sosi.tdata(63 downto 0),
        probe0(179 downto 148) => probe_out0,
        probe0(199 downto 180) => gnd(199 downto 180)
    );
    
    
    connectdbg3 : ila_0
    port map (
        clk => clk_eth,
        probe0(2 downto 0) => req_crsb_state,
        probe0(6 downto 3) => req_main_state, -- out std_logic_vector(3 downto 0);
        probe0(10 downto 7) => replay_state,   -- out std_logic_vector(3 downto 0);
        probe0(14 downto 11) => completion_state, --  out std_logic_vector(3 downto 0);
        probe0(18 downto 15) => rq_state,        -- out std_logic_vector(3 downto 0);
        probe0(22 downto 19) => rq_stream_state, -- out std_logic_vector(3 downto 0);
        probe0(26 downto 23) => resp_state,       -- out std_logic_vector(3 downto 0);
        probe0(114 downto 27) => crqb_fifo_rd_data_sel_out, --  out std_logic_vector(87 DOWNTO 0);
        probe0(117 downto 115) => crqb_fifo_rd_out,  -- out std_logic_vector(2 downto 0)   
        
        probe0(118) => mc_lite_mosi(1).bready,
        probe0(131 downto 119) => mc_lite_mosi(1).araddr(12 downto 0),
        probe0(132) => mc_lite_mosi(1).arvalid,
        probe0(133) => mc_lite_mosi(1).rready,
        probe0(134) => mc_lite_miso(1).rvalid,
        probe0(166 downto 135) => mc_lite_miso(1).rdata(31 downto 0),
        probe0(167) => mc_lite_miso(1).arready,
        probe0(168) => dbg_timer_expire,
        probe0(184 downto 169) => dbg_timer,
        probe0(199 downto 185) => gnd(199 downto 185)
    );
    -- dbg_timer_expire => dbg_timer_expire, -- out std_logic;
    -- dbg_timer => dbg_timer -- : out std_logic_vector(15 downto 0)
    
-- data_rx_sosi     : in t_axi4_sosi;   -- 128 bit wide data in, only fields that are used are .tdata, .tvalid, .tuser
    seg0_ena <= data_rx_sosi(36).tuser(56);
    seg0_sop <= data_rx_sosi(36).tuser(57);  -- start of packet
    seg0_eop <= data_rx_sosi(36).tuser(58);  -- end of packet
    seg0_mty <= data_rx_sosi(36).tuser(61 DOWNTO 59); -- number of unused bytes in segment 0, only used when eop0 = '1', ena0 = '1', tvalid = '1'. 
    seg0_err <= data_rx_sosi(36).tuser(62);  -- error reported by 40GE MAC (e.g. FCS, bad 64/66 bit block, bad packet length), only valid on eop0, ena0 and tvalid all = '1'
---- segment 1 relates to data_rx_sosi.tdata(127:64)
    seg1_ena <= data_rx_sosi(36).tuser(63);
    seg1_sop <= data_rx_sosi(36).tuser(64);
    seg1_eop <= data_rx_sosi(36).tuser(65);
    seg1_mty <= data_rx_sosi(36).tuser(68 DOWNTO 66);
    seg1_err <= data_rx_sosi(36).tuser(69);
    
    LFAA_tx_fsm <= LFAADecode_dbg(3 downto 0);
    LFAA_stats_fsm <= LFAADecode_dbg(7 downto 4);
    LFAA_rx_fsm <= LFAADecode_dbg(11 downto 8);
    goodpacket <= LFAADecode_dbg(12);
    nonSPEAD   <= LFAADecode_dbg(13);
    
END structure;
