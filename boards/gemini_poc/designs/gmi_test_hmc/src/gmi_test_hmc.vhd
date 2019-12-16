LIBRARY IEEE, UNISIM;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE UNISIM.vcomponents.all; -- IBUFDS, OBUFDS, ...

ENTITY gmi_test_hmc IS
  GENERIC (
    GMI_GT_NUM_CHANNEL : NATURAL := 16
  );
  PORT (
      -- Global clks
      clk_b_p           : in std_logic;                              -- 156.25MHz system clk
      clk_b_n           : in std_logic;
      clk_f             : in std_logic;                              -- 20MHz PTP clk
--      clk_e_p           : in std_logic;                              -- 125MHz PTP clk
--      clk_e_n           : in std_logic;
--      clk_sfp_p         : in std_logic;                              -- Input from second SFP module (assume 64 MHz)
--      clk_sfp_n         : in std_logic;
--      clk_mmbx_p        : in std_logic;                              -- Clock from MMBX connector (assume 64 MHz)
--      clk_mmbx_n        : in std_logic;

      -- Auxillary IO Connector
      aux_in_sda        : inout std_logic;                           -- To input connector
      aux_in_scl        : inout std_logic;
      aux_in_alert      : inout std_logic;

      aux_out_sda       : inout std_logic;                           -- To output connector
      aux_out_scl       : inout std_logic;
      aux_out_alert     : inout std_logic;
 
      aux_pgood         : in std_logic;                              -- Communal power good, Active high power good
      aux_pwr_off       : out std_logic;                             -- Disable downstream power
 
      last_board        : in std_logic;                              -- Internal pullup (active high last board in chain)
      slave             : in std_logic;                              -- Internal pullup (active high slave)

      -- Identification & Misc
      serial_prom       : inout std_logic;                           -- LVCMOS 1.8V
      version           : in std_logic_vector(1 downto 0);           -- Internal Pullups
      debug_mmbx        : inout std_logic;                           -- Debug connection to MMBX connector
      debug             : inout std_logic_vector(3 downto 0);
 
      led_din           : out std_logic;
      led_dout          : in std_logic;
      led_cs            : out std_logic;
      led_sclk          : out std_logic;
 
--      aux_sfp_tx_p      : out std_logic;                             -- General IO otuptu to secondary SFP
--      aux_sfp_tx_n      : out std_logic;    
      aux_sfp_tx_sel    : out std_logic;                             -- Selects if secondary SFP is driven from GTY or general IO
 
      qsfp_clock_sel    : out std_logic;                             -- Select crystal or MMBX inptu for QSFP clock
 
      -- Configuration IO
      spi_d             : inout std_logic_vector(7 downto 0);
      spi_c             : out std_logic;
      spi_cs            : out std_logic_vector(1 downto 0);
 
      -- Power Monitor & Control
      pmbus_sda         : inout std_logic;                           -- OC drive, internal Pullups
      pmbus_sdc         : inout std_logic;                           -- LVCMOS 1.8V
      pmbus_alert       : in std_logic;

      -- HMC Blocks
      hmc_a_clk_p       : in std_logic;                              -- 125MHz reference
      hmc_a_clk_n       : in std_logic;
      hmc_a_tx_p        : out std_logic_vector(GMI_GT_NUM_CHANNEL-1 downto 0);
      hmc_a_tx_n        : out std_logic_vector(GMI_GT_NUM_CHANNEL-1 downto 0);
      hmc_a_rx_p        : in std_logic_vector(GMI_GT_NUM_CHANNEL-1 downto 0);
      hmc_a_rx_n        : in std_logic_vector(GMI_GT_NUM_CHANNEL-1 downto 0);
      hmc_a_ferr_n      : in std_logic;
      hmc_a_p_rst_n     : out std_logic;
      hmc_a_sda         : inout std_logic;                           -- OC drive, internal Pullups
      hmc_a_scl         : inout std_logic;                           -- LVCMOS 1.5V

      hmc_b_clk_p       : in std_logic;                              -- 125MHz reference
      hmc_b_clk_n       : in std_logic;

      hmc_b_tx_p        : out std_logic_vector(GMI_GT_NUM_CHANNEL-1 downto 0);
      hmc_b_tx_n        : out std_logic_vector(GMI_GT_NUM_CHANNEL-1 downto 0);
      hmc_b_rx_p        : in std_logic_vector(GMI_GT_NUM_CHANNEL-1 downto 0);
      hmc_b_rx_n        : in std_logic_vector(GMI_GT_NUM_CHANNEL-1 downto 0);

      hmc_b_ferr_n      : in std_logic;
      hmc_b_p_rst_n     : out std_logic;
      hmc_b_sda         : inout std_logic;                           -- OC drive, internal Pullups
      hmc_b_scl         : inout std_logic;                           -- LVCMOS 1.5V

      hmc_c_clk_p       : in std_logic;                              -- 125MHz reference
      hmc_c_clk_n       : in std_logic;
      hmc_c_tx_p        : out std_logic_vector(GMI_GT_NUM_CHANNEL-1 downto 0);
      hmc_c_tx_n        : out std_logic_vector(GMI_GT_NUM_CHANNEL-1 downto 0);
      hmc_c_rx_p        : in std_logic_vector(GMI_GT_NUM_CHANNEL-1 downto 0);
      hmc_c_rx_n        : in std_logic_vector(GMI_GT_NUM_CHANNEL-1 downto 0);
      hmc_c_ferr_n      : in std_logic;
      hmc_c_p_rst_n     : out std_logic;
      hmc_c_sda         : inout std_logic;                           -- OC drive, internal Pullups
      hmc_c_scl         : inout std_logic;                           -- LVCMOS 1.5V

      hmc_d_clk_p       : in std_logic;                              -- 125MHz reference
      hmc_d_clk_n       : in std_logic;
      hmc_d_tx_p        : out std_logic_vector(GMI_GT_NUM_CHANNEL-1 downto 0);
      hmc_d_tx_n        : out std_logic_vector(GMI_GT_NUM_CHANNEL-1 downto 0);
      hmc_d_rx_p        : in std_logic_vector(GMI_GT_NUM_CHANNEL-1 downto 0);
      hmc_d_rx_n        : in std_logic_vector(GMI_GT_NUM_CHANNEL-1 downto 0);
      hmc_d_ferr_n      : in std_logic;
      hmc_d_p_rst_n     : out std_logic;
      hmc_d_sda         : inout std_logic;                           -- OC drive, internal Pullups
      hmc_d_scl         : inout std_logic;                           -- LVCMOS 1.5V

      -- Optics I2C Busses
      optics_l_sda      : inout std_logic;                           -- OC drive, internal Pullups
      optics_l_scl      : inout std_logic;                           -- LVCMOS 1.8V
      optics_l_reset_n  : out std_logic;                             -- LVCMOS 1.8V
      optics_r_sda      : inout std_logic;                           -- OC drive, internal Pullups
      optics_r_scl      : inout std_logic;                           -- LVCMOS 1.8V
      optics_r_reset_n  : out std_logic;                             -- LVCMOS 1.8V

      mbo_clk_g_p       : in std_logic_vector(2 downto 0);           -- 156.25MHz clock inputs to enable MBO operation at 10G. (Shared between MBO connections, see schematic)
      mbo_clk_g_n       : in std_logic_vector(2 downto 0);

      -- MBO
      mbo_a_clk_p       : in std_logic_vector(2 downto 0);           -- 161.13MHz reference
      mbo_a_clk_n       : in std_logic_vector(2 downto 0);
      mbo_a_tx_p        : out std_logic_vector(11 downto 0);
      mbo_a_tx_n        : out std_logic_vector(11 downto 0);
      mbo_a_rx_p        : in std_logic_vector(11 downto 0);
      mbo_a_rx_n        : in std_logic_vector(11 downto 0);
      mbo_a_int_n       : in std_logic;                              -- LVCMOS 1.8V
      mbo_a_modprs_tx_n : in std_logic;                              -- LVCMOS 1.8V
      mbo_a_modprs_rx_n : in std_logic;                              -- LVCMOS 1.8V
      mbo_a_reset       : out std_logic;                             -- LVCMOS 1.8V


      mbo_b_clk_p       : in std_logic_vector(2 downto 0);           -- 161.13MHz reference
      mbo_b_clk_n       : in std_logic_vector(2 downto 0);
      mbo_b_tx_p        : out std_logic_vector(11 downto 0);
      mbo_b_tx_n        : out std_logic_vector(11 downto 0);
      mbo_b_rx_p        : in std_logic_vector(11 downto 0);
      mbo_b_rx_n        : in std_logic_vector(11 downto 0);
      mbo_b_int_n       : in std_logic;                              -- LVCMOS 1.8V
      mbo_b_modprs_tx_n : in std_logic;                              -- LVCMOS 1.8V
      mbo_b_modprs_rx_n : in std_logic;                              -- LVCMOS 1.8V
      mbo_b_reset       : out std_logic;                             -- LVCMOS 1.8V

      mbo_c_clk_p       : in std_logic_vector(2 downto 0);           -- 161.13MHz reference
      mbo_c_clk_n       : in std_logic_vector(2 downto 0);
      mbo_c_tx_p        : out std_logic_vector(11 downto 0);
      mbo_c_tx_n        : out std_logic_vector(11 downto 0);
      mbo_c_rx_p        : in std_logic_vector(11 downto 0);
      mbo_c_rx_n        : in std_logic_vector(11 downto 0);
      mbo_c_int_n       : in std_logic;                              -- LVCMOS 1.8V
      mbo_c_modprs_tx_n : in std_logic;                              -- LVCMOS 1.8V
      mbo_c_modprs_rx_n : in std_logic;                              -- LVCMOS 1.8V
      mbo_c_reset       : out std_logic;                             -- LVCMOS 1.8V

      -- QSFP
      qsfp_clock_b_p    : in std_logic_vector(2 downto 0);           -- Shared 156.25MHz clock
      qsfp_clock_b_n    : in std_logic_vector(2 downto 0);
      qsfp_int_n        : in std_logic;

      qsfp_a_mod_prs_n  : in std_logic;
      qsfp_a_reset      : out std_logic;
      qsfp_a_clk_p      : in std_logic;                              -- 161.13MHz reference
      qsfp_a_clk_n      : in std_logic;
      qsfp_a_tx_p       : out std_logic_vector(3 downto 0);
      qsfp_a_tx_n       : out std_logic_vector(3 downto 0);
      qsfp_a_rx_p       : in std_logic_vector(3 downto 0);
      qsfp_a_rx_n       : in std_logic_vector(3 downto 0);

      qsfp_b_mod_prs_n  : in std_logic;
      qsfp_b_reset      : out std_logic;
      qsfp_b_clk_p      : in std_logic;                              -- 161.13MHz reference
      qsfp_b_clk_n      : in std_logic;
      qsfp_b_tx_p       : out std_logic_vector(3 downto 0);
      qsfp_b_tx_n       : out std_logic_vector(3 downto 0);
      qsfp_b_rx_p       : in std_logic_vector(3 downto 0);
      qsfp_b_rx_n       : in std_logic_vector(3 downto 0);

      qsfp_c_mod_prs_n  : in std_logic;
      qsfp_c_reset      : out std_logic;
      qsfp_c_clk_p      : in std_logic;                              -- 161.13MHz reference
      qsfp_c_clk_n      : in std_logic;
      qsfp_c_tx_p       : out std_logic_vector(3 downto 0);
      qsfp_c_tx_n       : out std_logic_vector(3 downto 0);
      qsfp_c_rx_p       : in std_logic_vector(3 downto 0);
      qsfp_c_rx_n       : in std_logic_vector(3 downto 0);

      qsfp_d_mod_prs_n  : in std_logic;
      qsfp_d_reset      : out std_logic;
      qsfp_d_clk_p      : in std_logic;                              -- 161.13MHz reference
      qsfp_d_clk_n      : in std_logic;
      qsfp_d_tx_p       : out std_logic_vector(3 downto 0);
      qsfp_d_tx_n       : out std_logic_vector(3 downto 0);
      qsfp_d_rx_p       : in std_logic_vector(3 downto 0);
      qsfp_d_rx_n       : in std_logic_vector(3 downto 0);

      -- SFP
      sfp_fault         : in std_logic;

      sfp_a_mod_abs     : in std_logic;
      sfp_a_tx_enable   : out std_logic;
      sfp_a_clk_p       : in std_logic;                              -- 156.25MHz reference
      sfp_a_clk_n       : in std_logic;
      sfp_a_tx_p        : out std_logic;
      sfp_a_tx_n        : out std_logic;
      sfp_a_rx_p        : in std_logic;
      sfp_a_rx_n        : in std_logic;

      sfp_b_mod_abs     : in std_logic;
      sfp_b_tx_enable   : out std_logic;
      sfp_b_clk_p       : in std_logic;                              -- 125MHz reference from PTP system (clock e)
      sfp_b_clk_n       : in std_logic;
      sfp_b_tx_p        : out std_logic;                             -- GTY output
      sfp_b_tx_n        : out std_logic;
      sfp_b_rx_p        : in std_logic;                              -- GTY input
      sfp_b_rx_n        : in std_logic;

      -- PTP
      ptp_clk_sel       : out std_logic;
      ptp_sync_n        : in std_logic_vector(1 downto 0);
      ptp_sclk          : out std_logic;
      ptp_din           : out std_logic
  );
END gmi_test_hmc;

ARCHITECTURE str OF gmi_test_hmc IS




COMPONENT hmc_free_clk_mmcm_0 IS
   PORT (
    clk_in1_p          : in std_logic;
    clk_in1_n          : in std_logic;
    clk_out1           : out std_logic;
    clk_out2           : out std_logic;
    clk_out3           : out std_logic;
    clk_out4           : out std_logic;
    clk_out5           : out std_logic;
    clk_out6           : out std_logic;
    clk_out7           : out std_logic;
    reset              : in std_logic;
    locked             : out std_logic
  );
END COMPONENT hmc_free_clk_mmcm_0;

COMPONENT hmc_core_a IS
  GENERIC (
    HMC_VER         : NATURAL := 1;     -- HMC standard version; 1:Gen2; 2:Gen3
    N_FLIT          : NATURAL := 4;     -- number of FLITs
    FULL_WIDTH      : NATURAL := 1;     -- HMC full-width (1) or half-width (0)
    GT_NUM_CHANNEL  : NATURAL := 16;    -- Number of GT lanes
    GT_USE_GTH      : NATURAL := 0;     -- By default, uses GTH to establish HMC links
    GT_SPEED        : NATURAL := 15;    -- GT speed (10/12.5/15/25/28/30)
    GT_REFCLK_FREQ  : NATURAL := 125;   -- GT reference clock frequency (125Mhz/156.25Mhz/166.67Mhz/312.5Mhz)
    DEV_CUB_ID      : std_logic_vector(2 downto 0) := "000";--3'b000; -- HMC device CUB-ID
    HMC_DEV_LINK_ID : std_logic := '0';--1'b0;   -- HMC DEVICE link ID
    IIC_MUX_ADDR    : std_logic_vector(6 downto 0) := "1110100";--7'h74;  -- IIC MUX ADDRESS
    IIC_HMC_ADDR    : std_logic_vector(6 downto 0) := "0010100";--7'h14;  -- HMC device IIC address
    TGEN_SIM_F      : NATURAL :=0
  );
  PORT (
    rst                : in std_logic;
    clk_free           : in std_logic;
    -- HMC-Device interface
    refclk_p           : in std_logic;
    refclk_n           : in std_logic;
    txp                : out std_logic_vector(GT_NUM_CHANNEL-1 downto 0);
    txn                : out std_logic_vector(GT_NUM_CHANNEL-1 downto 0);
    rxp                : in std_logic_vector(GT_NUM_CHANNEL-1 downto 0);
    rxn                : in std_logic_vector(GT_NUM_CHANNEL-1 downto 0);
    lxrxps             : in std_logic;
    lxtxps             : out std_logic;
    device_p_rst_n     : out std_logic;
    HMC_REFCLK_BOOT_0  : out std_logic;
    HMC_REFCLK_BOOT_1  : out std_logic;
    HMC_REFCLK_SEL     : out std_logic;
    HMC_FERR_B         : in std_logic;
    -- Hardware control for evaluation board
    IIC_MAIN_SCL_LS    : inout std_logic;
    IIC_MAIN_SDA_LS    : inout std_logic;
    IIC_MUX_RESET_B_LS : out std_logic;
    SI5328_RST_N_LS    : out std_logic;
    SM_FAN_PWM         : out std_logic; -- HMC device fan 
    SM_FAN_TACH        : out std_logic; -- FPGA fan
    GPIO_LED_0_LS      : out std_logic;
    GPIO_LED_1_LS      : out std_logic;
    GPIO_LED_2_LS      : out std_logic;
    GPIO_LED_3_LS      : out std_logic;
    GPIO_LED_4_LS      : out std_logic;
    GPIO_LED_5_LS      : out std_logic;
    GPIO_LED_6_LS      : out std_logic;
    GPIO_LED_7_LS      : out std_logic
  );
END COMPONENT hmc_core_a;

COMPONENT hmc_core_b IS
  GENERIC (
    HMC_VER         : NATURAL := 1;     -- HMC standard version; 1:Gen2; 2:Gen3
    N_FLIT          : NATURAL := 4;     -- number of FLITs
    FULL_WIDTH      : NATURAL := 1;     -- HMC full-width (1) or half-width (0)
    GT_NUM_CHANNEL  : NATURAL := 16;    -- Number of GT lanes
    GT_USE_GTH      : NATURAL := 0;     -- By default, uses GTH to establish HMC links
    GT_SPEED        : NATURAL := 15;    -- GT speed (10/12.5/15/25/28/30)
    GT_REFCLK_FREQ  : NATURAL := 125;   -- GT reference clock frequency (125Mhz/156.25Mhz/166.67Mhz/312.5Mhz)
    DEV_CUB_ID      : std_logic_vector(2 downto 0) := "000";--3'b000; -- HMC device CUB-ID
    HMC_DEV_LINK_ID : std_logic := '0';--1'b0;   -- HMC DEVICE link ID
    IIC_MUX_ADDR    : std_logic_vector(6 downto 0) := "1110100";--7'h74;  -- IIC MUX ADDRESS
    IIC_HMC_ADDR    : std_logic_vector(6 downto 0) := "0010100";--7'h14;  -- HMC device IIC address
    TGEN_SIM_F      : NATURAL :=0
  );
  PORT (
    rst                : in std_logic;
    clk_free           : in std_logic;
    -- HMC-Device interface
    refclk_p           : in std_logic;
    refclk_n           : in std_logic;
    txp                : out std_logic_vector(GT_NUM_CHANNEL-1 downto 0);
    txn                : out std_logic_vector(GT_NUM_CHANNEL-1 downto 0);
    rxp                : in std_logic_vector(GT_NUM_CHANNEL-1 downto 0);
    rxn                : in std_logic_vector(GT_NUM_CHANNEL-1 downto 0);
    lxrxps             : in std_logic;
    lxtxps             : out std_logic;
    device_p_rst_n     : out std_logic;
    HMC_REFCLK_BOOT_0  : out std_logic;
    HMC_REFCLK_BOOT_1  : out std_logic;
    HMC_REFCLK_SEL     : out std_logic;
    HMC_FERR_B         : in std_logic;
    -- Hardware control for evaluation board
    IIC_MAIN_SCL_LS    : inout std_logic;
    IIC_MAIN_SDA_LS    : inout std_logic;
    IIC_MUX_RESET_B_LS : out std_logic;
    SI5328_RST_N_LS    : out std_logic;
    SM_FAN_PWM         : out std_logic; -- HMC device fan 
    SM_FAN_TACH        : out std_logic; -- FPGA fan
    GPIO_LED_0_LS      : out std_logic;
    GPIO_LED_1_LS      : out std_logic;
    GPIO_LED_2_LS      : out std_logic;
    GPIO_LED_3_LS      : out std_logic;
    GPIO_LED_4_LS      : out std_logic;
    GPIO_LED_5_LS      : out std_logic;
    GPIO_LED_6_LS      : out std_logic;
    GPIO_LED_7_LS      : out std_logic
  );
END COMPONENT hmc_core_b;

COMPONENT hmc_core_c IS
  GENERIC (
    HMC_VER         : NATURAL := 1;     -- HMC standard version; 1:Gen2; 2:Gen3
    N_FLIT          : NATURAL := 4;     -- number of FLITs
    FULL_WIDTH      : NATURAL := 1;     -- HMC full-width (1) or half-width (0)
    GT_NUM_CHANNEL  : NATURAL := 16;    -- Number of GT lanes
    GT_USE_GTH      : NATURAL := 0;     -- By default, uses GTH to establish HMC links
    GT_SPEED        : NATURAL := 15;    -- GT speed (10/12.5/15/25/28/30)
    GT_REFCLK_FREQ  : NATURAL := 125;   -- GT reference clock frequency (125Mhz/156.25Mhz/166.67Mhz/312.5Mhz)
    DEV_CUB_ID      : std_logic_vector(2 downto 0) := "000";--3'b000; -- HMC device CUB-ID
    HMC_DEV_LINK_ID : std_logic := '0';--1'b0;   -- HMC DEVICE link ID
    IIC_MUX_ADDR    : std_logic_vector(6 downto 0) := "1110100";--7'h74;  -- IIC MUX ADDRESS
    IIC_HMC_ADDR    : std_logic_vector(6 downto 0) := "0010100";--7'h14;  -- HMC device IIC address
    TGEN_SIM_F      : NATURAL :=0
  );
  PORT (
    rst                : in std_logic;
    clk_free           : in std_logic;
    -- HMC-Device interface
    refclk_p           : in std_logic;
    refclk_n           : in std_logic;
    txp                : out std_logic_vector(GT_NUM_CHANNEL-1 downto 0);
    txn                : out std_logic_vector(GT_NUM_CHANNEL-1 downto 0);
    rxp                : in std_logic_vector(GT_NUM_CHANNEL-1 downto 0);
    rxn                : in std_logic_vector(GT_NUM_CHANNEL-1 downto 0);
    lxrxps             : in std_logic;
    lxtxps             : out std_logic;
    device_p_rst_n     : out std_logic;
    HMC_REFCLK_BOOT_0  : out std_logic;
    HMC_REFCLK_BOOT_1  : out std_logic;
    HMC_REFCLK_SEL     : out std_logic;
    HMC_FERR_B         : in std_logic;
    -- Hardware control for evaluation board
    IIC_MAIN_SCL_LS    : inout std_logic;
    IIC_MAIN_SDA_LS    : inout std_logic;
    IIC_MUX_RESET_B_LS : out std_logic;
    SI5328_RST_N_LS    : out std_logic;
    SM_FAN_PWM         : out std_logic; -- HMC device fan 
    SM_FAN_TACH        : out std_logic; -- FPGA fan
    GPIO_LED_0_LS      : out std_logic;
    GPIO_LED_1_LS      : out std_logic;
    GPIO_LED_2_LS      : out std_logic;
    GPIO_LED_3_LS      : out std_logic;
    GPIO_LED_4_LS      : out std_logic;
    GPIO_LED_5_LS      : out std_logic;
    GPIO_LED_6_LS      : out std_logic;
    GPIO_LED_7_LS      : out std_logic
  );
END COMPONENT hmc_core_c;

COMPONENT hmc_core_d IS
  GENERIC (
    HMC_VER         : NATURAL := 1;     -- HMC standard version; 1:Gen2; 2:Gen3
    N_FLIT          : NATURAL := 4;     -- number of FLITs
    FULL_WIDTH      : NATURAL := 1;     -- HMC full-width (1) or half-width (0)
    GT_NUM_CHANNEL  : NATURAL := 16;    -- Number of GT lanes
    GT_USE_GTH      : NATURAL := 0;     -- By default, uses GTH to establish HMC links
    GT_SPEED        : NATURAL := 15;    -- GT speed (10/12.5/15/25/28/30)
    GT_REFCLK_FREQ  : NATURAL := 125;   -- GT reference clock frequency (125Mhz/156.25Mhz/166.67Mhz/312.5Mhz)
    DEV_CUB_ID      : std_logic_vector(2 downto 0) := "000";--3'b000; -- HMC device CUB-ID
    HMC_DEV_LINK_ID : std_logic := '0';--1'b0;   -- HMC DEVICE link ID
    IIC_MUX_ADDR    : std_logic_vector(6 downto 0) := "1110100";--7'h74;  -- IIC MUX ADDRESS
    IIC_HMC_ADDR    : std_logic_vector(6 downto 0) := "0010100";--7'h14;  -- HMC device IIC address
    TGEN_SIM_F      : NATURAL :=0
  );
  PORT (
    rst                : in std_logic;
    clk_free           : in std_logic;
    -- HMC-Device interface
    refclk_p           : in std_logic;
    refclk_n           : in std_logic;
    txp                : out std_logic_vector(GT_NUM_CHANNEL-1 downto 0);
    txn                : out std_logic_vector(GT_NUM_CHANNEL-1 downto 0);
    rxp                : in std_logic_vector(GT_NUM_CHANNEL-1 downto 0);
    rxn                : in std_logic_vector(GT_NUM_CHANNEL-1 downto 0);
    lxrxps             : in std_logic;
    lxtxps             : out std_logic;
    device_p_rst_n     : out std_logic;
    HMC_REFCLK_BOOT_0  : out std_logic;
    HMC_REFCLK_BOOT_1  : out std_logic;
    HMC_REFCLK_SEL     : out std_logic;
    HMC_FERR_B         : in std_logic;
    -- Hardware control for evaluation board
    IIC_MAIN_SCL_LS    : inout std_logic;
    IIC_MAIN_SDA_LS    : inout std_logic;
    IIC_MUX_RESET_B_LS : out std_logic;
    SI5328_RST_N_LS    : out std_logic;
    SM_FAN_PWM         : out std_logic; -- HMC device fan 
    SM_FAN_TACH        : out std_logic; -- FPGA fan
    GPIO_LED_0_LS      : out std_logic;
    GPIO_LED_1_LS      : out std_logic;
    GPIO_LED_2_LS      : out std_logic;
    GPIO_LED_3_LS      : out std_logic;
    GPIO_LED_4_LS      : out std_logic;
    GPIO_LED_5_LS      : out std_logic;
    GPIO_LED_6_LS      : out std_logic;
    GPIO_LED_7_LS      : out std_logic
  );
END COMPONENT hmc_core_d;


  SIGNAL pin_last_board  : STD_LOGIC;
  SIGNAL pin_slave       : STD_LOGIC;
  SIGNAL pin_version     : STD_LOGIC_VECTOR(1 downto 0);

  SIGNAL rst             : STD_LOGIC;
  SIGNAL led_d           : STD_LOGIC;
  SIGNAL sfp_fault_led   : STD_LOGIC;
  SIGNAL clk_free_hmc_a  : STD_LOGIC;
  SIGNAL clk_free_hmc_b  : STD_LOGIC;
  SIGNAL clk_free_hmc_c  : STD_LOGIC;
  SIGNAL clk_free_hmc_d  : STD_LOGIC;
  SIGNAL clk_free_locked : STD_LOGIC;
  SIGNAL clk_free_25MHz  : STD_LOGIC;
  SIGNAL clk_free_50MHz  : STD_LOGIC;
  SIGNAL clk_free_100MHz : STD_LOGIC;
  SIGNAL ptp_sync_input  : STD_LOGIC_VECTOR(1 downto 0);
  SIGNAL clk_sfp         : STD_LOGIC;
  SIGNAL debug_mmbx_out : STD_LOGIC;
  SIGNAL debug_out : STD_LOGIC_VECTOR(3 downto 0);
BEGIN
  pin_last_board <= last_board;
  u_pullup_last_board : PULLUP port map(O => pin_last_board);

  pin_slave <= slave;
  u_pullup_slave : PULLUP port map(O => pin_slave);

  pin_version <= version;
  u_pullup_version_0 : PULLUP port map(O => pin_version(0));
  u_pullup_version_1 : PULLUP port map(O => pin_version(1));

  




u_hmc_free_clk_mmcm_0 : hmc_free_clk_mmcm_0
   PORT MAP (
    clk_in1_p          => clk_b_p,
    clk_in1_n          => clk_b_n,
    clk_out1           => clk_free_hmc_a,
    clk_out2           => clk_free_hmc_b,
    clk_out3           => clk_free_hmc_c,
    clk_out4           => clk_free_hmc_d,
    clk_out5           => clk_free_25MHz,
    clk_out6           => clk_free_50MHz,
    clk_out7           => clk_free_100MHz,
    reset              => rst,
    locked             => clk_free_locked
);




u_hmc_core_a : hmc_core_a
   PORT MAP (
    rst                => rst,
    clk_free           => clk_free_hmc_a,
    -- HMC-Device interface
    refclk_p           => hmc_a_clk_p, --*
    refclk_n           => hmc_a_clk_n, --*
    txp                => hmc_a_tx_p,  --*
    txn                => hmc_a_tx_n,  --*
    rxp                => hmc_a_rx_p,  --*
    rxn                => hmc_a_rx_n,  --*
    lxrxps             => '0',
    device_p_rst_n     => hmc_a_p_rst_n, --*
    HMC_FERR_B         => hmc_a_ferr_n, --*
    -- Hardware control for evaluation board
    IIC_MAIN_SCL_LS    => hmc_a_scl, --*
    IIC_MAIN_SDA_LS    => hmc_a_sda  --*
   );

u_hmc_core_b : hmc_core_b
   PORT MAP (
    rst                => rst,
    clk_free           => clk_free_hmc_b,
    -- HMC-Device interface
    refclk_p           => hmc_b_clk_p, --*
    refclk_n           => hmc_b_clk_n, --*
    txp                => hmc_b_tx_p, --*
    txn                => hmc_b_tx_n, --*
    rxp                => hmc_b_rx_p, --*
    rxn                => hmc_b_rx_n, --*
    lxrxps             => '0',
    device_p_rst_n     => hmc_b_p_rst_n, --*
    HMC_FERR_B         => hmc_b_ferr_n, --*
    -- Hardware control for evaluation board
    IIC_MAIN_SCL_LS    => hmc_b_scl, --*
    IIC_MAIN_SDA_LS    => hmc_b_sda --*
   );

u_hmc_core_c : hmc_core_c
   PORT MAP (
    rst                => rst,
    clk_free           => clk_free_hmc_c,
    -- HMC-Device interface
    refclk_p           => hmc_c_clk_p, --*
    refclk_n           => hmc_c_clk_n, --*
    txp                => hmc_c_tx_p, --*
    txn                => hmc_c_tx_n, --*
    rxp                => hmc_c_rx_p, --*
    rxn                => hmc_c_rx_n, --*
    lxrxps             => '0',
    device_p_rst_n     => hmc_c_p_rst_n, --*
    HMC_FERR_B         => hmc_c_ferr_n, --*
    -- Hardware control for evaluation board
    IIC_MAIN_SCL_LS    => hmc_c_scl, --*
    IIC_MAIN_SDA_LS    => hmc_c_sda --*
   );

u_hmc_core_d : hmc_core_d
   PORT MAP (
    rst                => rst,
    clk_free           => clk_free_hmc_d,
    -- HMC-Device interface
    refclk_p           => hmc_d_clk_p, --*
    refclk_n           => hmc_d_clk_n, --*
    txp                => hmc_d_tx_p, --*
    txn                => hmc_d_tx_n, --*
    rxp                => hmc_d_rx_p, --*
    rxn                => hmc_d_rx_n, --*
    lxrxps             => '0',
    device_p_rst_n     => hmc_d_p_rst_n, --*
    HMC_FERR_B         => hmc_d_ferr_n, --*
    -- Hardware control for evaluation board
    IIC_MAIN_SCL_LS    => hmc_d_scl, --*
    IIC_MAIN_SDA_LS    => hmc_d_sda --*
   );


END str;

