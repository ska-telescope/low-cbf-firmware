LIBRARY IEEE, UNISIM;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE UNISIM.vcomponents.all; -- IBUFDS, OBUFDS, ...

ENTITY gmi_pinning IS
  GENERIC (
    GMI_GT_NUM_CHANNEL : NATURAL := 16
  );
  PORT (
      -- Global clks
      clk_b_p           : in std_logic;                              -- 156.25MHz system clk
      clk_b_n           : in std_logic;
      clk_f             : in std_logic;                              -- 20MHz PTP clk
      clk_e_p           : in std_logic;                              -- 125MHz PTP clk
      clk_e_n           : in std_logic;
      clk_sfp_p         : in std_logic;                              -- Input from second SFP module (assume 64 MHz)
      clk_sfp_n         : in std_logic;
      clk_mmbx_p        : in std_logic;                              -- Clock from MMBX connector (assume 64 MHz)
      clk_mmbx_n        : in std_logic;

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
 
      aux_sfp_tx_p      : out std_logic;                             -- General IO otuptu to secondary SFP
      aux_sfp_tx_n      : out std_logic;    
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
END gmi_pinning;

ARCHITECTURE str OF gmi_pinning IS


COMPONENT ptp_clk125_mmcm IS
   PORT (
    clk_in1_p          : in std_logic;
    clk_in1_n          : in std_logic;
    clk_out1           : out std_logic;
    clk_out2           : out std_logic;
    reset              : in std_logic;
    locked             : out std_logic
  );
END COMPONENT ptp_clk125_mmcm;

COMPONENT mmbx_clk64_mmcm IS
   PORT (
    clk_in1_p          : in std_logic;
    clk_in1_n          : in std_logic;
    clk_out1           : out std_logic;
    clk_out2           : out std_logic;
    clk_out3           : out std_logic;
    clk_out4           : out std_logic;
    clk_out5           : out std_logic;
    clk_out6           : out std_logic;
    reset              : in std_logic;
    locked             : out std_logic
  );
END COMPONENT mmbx_clk64_mmcm;

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


COMPONENT qsfp_25g_ethernet_exdes_a IS
  PORT (
    gt_rxp_in_0         : in std_logic;
    gt_rxn_in_0         : in std_logic;
    gt_txp_out_0        : out std_logic;
    gt_txn_out_0        : out std_logic;
    restart_tx_rx_0     : in std_logic;
    rx_gt_locked_led_0  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_0 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_1         : in std_logic;
    gt_rxn_in_1         : in std_logic;
    gt_txp_out_1        : out std_logic;
    gt_txn_out_1        : out std_logic;
    restart_tx_rx_1     : in std_logic;
    rx_gt_locked_led_1  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_1 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_2         : in std_logic;
    gt_rxn_in_2         : in std_logic;
    gt_txp_out_2        : out std_logic;
    gt_txn_out_2        : out std_logic;
    restart_tx_rx_2     : in std_logic;
    rx_gt_locked_led_2  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_2 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_3         : in std_logic;
    gt_rxn_in_3         : in std_logic;
    gt_txp_out_3        : out std_logic;
    gt_txn_out_3        : out std_logic;
    restart_tx_rx_3     : in std_logic;
    rx_gt_locked_led_3  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_3 : out std_logic; -- Indicated Core Block Lock

    completion_status   : out std_logic_vector(4 downto 0);
    sys_reset           : in std_logic;
    gt_refclk_p         : in std_logic;
    gt_refclk_n         : in std_logic;
    dclk                : in std_logic;

    gt_rxpolarity_0     : in std_logic;
    gt_rxpolarity_1     : in std_logic;
    gt_rxpolarity_2     : in std_logic;
    gt_rxpolarity_3     : in std_logic;
    gt_txpolarity_0     : in std_logic;
    gt_txpolarity_1     : in std_logic;
    gt_txpolarity_2     : in std_logic;
    gt_txpolarity_3     : in std_logic
);
END COMPONENT qsfp_25g_ethernet_exdes_a;

COMPONENT qsfp_25g_ethernet_exdes_b IS
  PORT (
    gt_rxp_in_0         : in std_logic;
    gt_rxn_in_0         : in std_logic;
    gt_txp_out_0        : out std_logic;
    gt_txn_out_0        : out std_logic;
    restart_tx_rx_0     : in std_logic;
    rx_gt_locked_led_0  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_0 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_1         : in std_logic;
    gt_rxn_in_1         : in std_logic;
    gt_txp_out_1        : out std_logic;
    gt_txn_out_1        : out std_logic;
    restart_tx_rx_1     : in std_logic;
    rx_gt_locked_led_1  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_1 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_2         : in std_logic;
    gt_rxn_in_2         : in std_logic;
    gt_txp_out_2        : out std_logic;
    gt_txn_out_2        : out std_logic;
    restart_tx_rx_2     : in std_logic;
    rx_gt_locked_led_2  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_2 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_3         : in std_logic;
    gt_rxn_in_3         : in std_logic;
    gt_txp_out_3        : out std_logic;
    gt_txn_out_3        : out std_logic;
    restart_tx_rx_3     : in std_logic;
    rx_gt_locked_led_3  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_3 : out std_logic; -- Indicated Core Block Lock

    completion_status   : out std_logic_vector(4 downto 0);
    sys_reset           : in std_logic;
    gt_refclk_p         : in std_logic;
    gt_refclk_n         : in std_logic;
    dclk                : in std_logic;

    gt_rxpolarity_0     : in std_logic;
    gt_rxpolarity_1     : in std_logic;
    gt_rxpolarity_2     : in std_logic;
    gt_rxpolarity_3     : in std_logic;
    gt_txpolarity_0     : in std_logic;
    gt_txpolarity_1     : in std_logic;
    gt_txpolarity_2     : in std_logic;
    gt_txpolarity_3     : in std_logic
);
END COMPONENT qsfp_25g_ethernet_exdes_b;

COMPONENT qsfp_25g_ethernet_exdes_c IS
  PORT (
    gt_rxp_in_0         : in std_logic;
    gt_rxn_in_0         : in std_logic;
    gt_txp_out_0        : out std_logic;
    gt_txn_out_0        : out std_logic;
    restart_tx_rx_0     : in std_logic;
    rx_gt_locked_led_0  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_0 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_1         : in std_logic;
    gt_rxn_in_1         : in std_logic;
    gt_txp_out_1        : out std_logic;
    gt_txn_out_1        : out std_logic;
    restart_tx_rx_1     : in std_logic;
    rx_gt_locked_led_1  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_1 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_2         : in std_logic;
    gt_rxn_in_2         : in std_logic;
    gt_txp_out_2        : out std_logic;
    gt_txn_out_2        : out std_logic;
    restart_tx_rx_2     : in std_logic;
    rx_gt_locked_led_2  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_2 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_3         : in std_logic;
    gt_rxn_in_3         : in std_logic;
    gt_txp_out_3        : out std_logic;
    gt_txn_out_3        : out std_logic;
    restart_tx_rx_3     : in std_logic;
    rx_gt_locked_led_3  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_3 : out std_logic; -- Indicated Core Block Lock

    completion_status   : out std_logic_vector(4 downto 0);
    sys_reset           : in std_logic;
    gt_refclk_p         : in std_logic;
    gt_refclk_n         : in std_logic;
    dclk                : in std_logic;

    gt_rxpolarity_0     : in std_logic;
    gt_rxpolarity_1     : in std_logic;
    gt_rxpolarity_2     : in std_logic;
    gt_rxpolarity_3     : in std_logic;
    gt_txpolarity_0     : in std_logic;
    gt_txpolarity_1     : in std_logic;
    gt_txpolarity_2     : in std_logic;
    gt_txpolarity_3     : in std_logic
);
END COMPONENT qsfp_25g_ethernet_exdes_c;

COMPONENT qsfp_25g_ethernet_exdes_d IS
  PORT (
    gt_rxp_in_0         : in std_logic;
    gt_rxn_in_0         : in std_logic;
    gt_txp_out_0        : out std_logic;
    gt_txn_out_0        : out std_logic;
    restart_tx_rx_0     : in std_logic;
    rx_gt_locked_led_0  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_0 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_1         : in std_logic;
    gt_rxn_in_1         : in std_logic;
    gt_txp_out_1        : out std_logic;
    gt_txn_out_1        : out std_logic;
    restart_tx_rx_1     : in std_logic;
    rx_gt_locked_led_1  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_1 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_2         : in std_logic;
    gt_rxn_in_2         : in std_logic;
    gt_txp_out_2        : out std_logic;
    gt_txn_out_2        : out std_logic;
    restart_tx_rx_2     : in std_logic;
    rx_gt_locked_led_2  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_2 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_3         : in std_logic;
    gt_rxn_in_3         : in std_logic;
    gt_txp_out_3        : out std_logic;
    gt_txn_out_3        : out std_logic;
    restart_tx_rx_3     : in std_logic;
    rx_gt_locked_led_3  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_3 : out std_logic; -- Indicated Core Block Lock

    completion_status   : out std_logic_vector(4 downto 0);
    sys_reset           : in std_logic;
    gt_refclk_p         : in std_logic;
    gt_refclk_n         : in std_logic;
    dclk                : in std_logic;

    gt_rxpolarity_0     : in std_logic;
    gt_rxpolarity_1     : in std_logic;
    gt_rxpolarity_2     : in std_logic;
    gt_rxpolarity_3     : in std_logic;
    gt_txpolarity_0     : in std_logic;
    gt_txpolarity_1     : in std_logic;
    gt_txpolarity_2     : in std_logic;
    gt_txpolarity_3     : in std_logic
);
END COMPONENT qsfp_25g_ethernet_exdes_d;

COMPONENT mbo_a_119_25g_ethernet_exdes IS
  PORT (
    gt_rxp_in_0         : in std_logic;
    gt_rxn_in_0         : in std_logic;
    gt_txp_out_0        : out std_logic;
    gt_txn_out_0        : out std_logic;
    restart_tx_rx_0     : in std_logic;
    rx_gt_locked_led_0  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_0 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_1         : in std_logic;
    gt_rxn_in_1         : in std_logic;
    gt_txp_out_1        : out std_logic;
    gt_txn_out_1        : out std_logic;
    restart_tx_rx_1     : in std_logic;
    rx_gt_locked_led_1  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_1 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_2         : in std_logic;
    gt_rxn_in_2         : in std_logic;
    gt_txp_out_2        : out std_logic;
    gt_txn_out_2        : out std_logic;
    restart_tx_rx_2     : in std_logic;
    rx_gt_locked_led_2  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_2 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_3         : in std_logic;
    gt_rxn_in_3         : in std_logic;
    gt_txp_out_3        : out std_logic;
    gt_txn_out_3        : out std_logic;
    restart_tx_rx_3     : in std_logic;
    rx_gt_locked_led_3  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_3 : out std_logic; -- Indicated Core Block Lock

    completion_status   : out std_logic_vector(4 downto 0);
    sys_reset           : in std_logic;
    gt_refclk_p         : in std_logic;
    gt_refclk_n         : in std_logic;
    dclk                : in std_logic;

    gt_rxpolarity_0     : in std_logic;
    gt_rxpolarity_1     : in std_logic;
    gt_rxpolarity_2     : in std_logic;
    gt_rxpolarity_3     : in std_logic;
    gt_txpolarity_0     : in std_logic;
    gt_txpolarity_1     : in std_logic;
    gt_txpolarity_2     : in std_logic;
    gt_txpolarity_3     : in std_logic
);
END COMPONENT mbo_a_119_25g_ethernet_exdes;

COMPONENT mbo_a_120_25g_ethernet_exdes IS
  PORT (
    gt_rxp_in_0         : in std_logic;
    gt_rxn_in_0         : in std_logic;
    gt_txp_out_0        : out std_logic;
    gt_txn_out_0        : out std_logic;
    restart_tx_rx_0     : in std_logic;
    rx_gt_locked_led_0  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_0 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_1         : in std_logic;
    gt_rxn_in_1         : in std_logic;
    gt_txp_out_1        : out std_logic;
    gt_txn_out_1        : out std_logic;
    restart_tx_rx_1     : in std_logic;
    rx_gt_locked_led_1  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_1 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_2         : in std_logic;
    gt_rxn_in_2         : in std_logic;
    gt_txp_out_2        : out std_logic;
    gt_txn_out_2        : out std_logic;
    restart_tx_rx_2     : in std_logic;
    rx_gt_locked_led_2  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_2 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_3         : in std_logic;
    gt_rxn_in_3         : in std_logic;
    gt_txp_out_3        : out std_logic;
    gt_txn_out_3        : out std_logic;
    restart_tx_rx_3     : in std_logic;
    rx_gt_locked_led_3  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_3 : out std_logic; -- Indicated Core Block Lock

    completion_status   : out std_logic_vector(4 downto 0);
    sys_reset           : in std_logic;
    gt_refclk_p         : in std_logic;
    gt_refclk_n         : in std_logic;
    dclk                : in std_logic;

    gt_rxpolarity_0     : in std_logic;
    gt_rxpolarity_1     : in std_logic;
    gt_rxpolarity_2     : in std_logic;
    gt_rxpolarity_3     : in std_logic;
    gt_txpolarity_0     : in std_logic;
    gt_txpolarity_1     : in std_logic;
    gt_txpolarity_2     : in std_logic;
    gt_txpolarity_3     : in std_logic
);
END COMPONENT mbo_a_120_25g_ethernet_exdes;

COMPONENT mbo_a_121_25g_ethernet_exdes IS
  PORT (
    gt_rxp_in_0         : in std_logic;
    gt_rxn_in_0         : in std_logic;
    gt_txp_out_0        : out std_logic;
    gt_txn_out_0        : out std_logic;
    restart_tx_rx_0     : in std_logic;
    rx_gt_locked_led_0  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_0 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_1         : in std_logic;
    gt_rxn_in_1         : in std_logic;
    gt_txp_out_1        : out std_logic;
    gt_txn_out_1        : out std_logic;
    restart_tx_rx_1     : in std_logic;
    rx_gt_locked_led_1  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_1 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_2         : in std_logic;
    gt_rxn_in_2         : in std_logic;
    gt_txp_out_2        : out std_logic;
    gt_txn_out_2        : out std_logic;
    restart_tx_rx_2     : in std_logic;
    rx_gt_locked_led_2  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_2 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_3         : in std_logic;
    gt_rxn_in_3         : in std_logic;
    gt_txp_out_3        : out std_logic;
    gt_txn_out_3        : out std_logic;
    restart_tx_rx_3     : in std_logic;
    rx_gt_locked_led_3  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_3 : out std_logic; -- Indicated Core Block Lock

    completion_status   : out std_logic_vector(4 downto 0);
    sys_reset           : in std_logic;
    gt_refclk_p         : in std_logic;
    gt_refclk_n         : in std_logic;
    dclk                : in std_logic;

    gt_rxpolarity_0     : in std_logic;
    gt_rxpolarity_1     : in std_logic;
    gt_rxpolarity_2     : in std_logic;
    gt_rxpolarity_3     : in std_logic;
    gt_txpolarity_0     : in std_logic;
    gt_txpolarity_1     : in std_logic;
    gt_txpolarity_2     : in std_logic;
    gt_txpolarity_3     : in std_logic
);
END COMPONENT mbo_a_121_25g_ethernet_exdes;

COMPONENT mbo_b_122_25g_ethernet_exdes IS
  PORT (
    gt_rxp_in_0         : in std_logic;
    gt_rxn_in_0         : in std_logic;
    gt_txp_out_0        : out std_logic;
    gt_txn_out_0        : out std_logic;
    restart_tx_rx_0     : in std_logic;
    rx_gt_locked_led_0  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_0 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_1         : in std_logic;
    gt_rxn_in_1         : in std_logic;
    gt_txp_out_1        : out std_logic;
    gt_txn_out_1        : out std_logic;
    restart_tx_rx_1     : in std_logic;
    rx_gt_locked_led_1  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_1 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_2         : in std_logic;
    gt_rxn_in_2         : in std_logic;
    gt_txp_out_2        : out std_logic;
    gt_txn_out_2        : out std_logic;
    restart_tx_rx_2     : in std_logic;
    rx_gt_locked_led_2  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_2 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_3         : in std_logic;
    gt_rxn_in_3         : in std_logic;
    gt_txp_out_3        : out std_logic;
    gt_txn_out_3        : out std_logic;
    restart_tx_rx_3     : in std_logic;
    rx_gt_locked_led_3  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_3 : out std_logic; -- Indicated Core Block Lock

    completion_status   : out std_logic_vector(4 downto 0);
    sys_reset           : in std_logic;
    gt_refclk_p         : in std_logic;
    gt_refclk_n         : in std_logic;
    dclk                : in std_logic;

    gt_rxpolarity_0     : in std_logic;
    gt_rxpolarity_1     : in std_logic;
    gt_rxpolarity_2     : in std_logic;
    gt_rxpolarity_3     : in std_logic;
    gt_txpolarity_0     : in std_logic;
    gt_txpolarity_1     : in std_logic;
    gt_txpolarity_2     : in std_logic;
    gt_txpolarity_3     : in std_logic
);
END COMPONENT mbo_b_122_25g_ethernet_exdes;

COMPONENT mbo_b_123_25g_ethernet_exdes IS
  PORT (
    gt_rxp_in_0         : in std_logic;
    gt_rxn_in_0         : in std_logic;
    gt_txp_out_0        : out std_logic;
    gt_txn_out_0        : out std_logic;
    restart_tx_rx_0     : in std_logic;
    rx_gt_locked_led_0  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_0 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_1         : in std_logic;
    gt_rxn_in_1         : in std_logic;
    gt_txp_out_1        : out std_logic;
    gt_txn_out_1        : out std_logic;
    restart_tx_rx_1     : in std_logic;
    rx_gt_locked_led_1  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_1 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_2         : in std_logic;
    gt_rxn_in_2         : in std_logic;
    gt_txp_out_2        : out std_logic;
    gt_txn_out_2        : out std_logic;
    restart_tx_rx_2     : in std_logic;
    rx_gt_locked_led_2  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_2 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_3         : in std_logic;
    gt_rxn_in_3         : in std_logic;
    gt_txp_out_3        : out std_logic;
    gt_txn_out_3        : out std_logic;
    restart_tx_rx_3     : in std_logic;
    rx_gt_locked_led_3  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_3 : out std_logic; -- Indicated Core Block Lock

    completion_status   : out std_logic_vector(4 downto 0);
    sys_reset           : in std_logic;
    gt_refclk_p         : in std_logic;
    gt_refclk_n         : in std_logic;
    dclk                : in std_logic;

    gt_rxpolarity_0     : in std_logic;
    gt_rxpolarity_1     : in std_logic;
    gt_rxpolarity_2     : in std_logic;
    gt_rxpolarity_3     : in std_logic;
    gt_txpolarity_0     : in std_logic;
    gt_txpolarity_1     : in std_logic;
    gt_txpolarity_2     : in std_logic;
    gt_txpolarity_3     : in std_logic
);
END COMPONENT mbo_b_123_25g_ethernet_exdes;

COMPONENT mbo_b_124_25g_ethernet_exdes IS
  PORT (
    gt_rxp_in_0         : in std_logic;
    gt_rxn_in_0         : in std_logic;
    gt_txp_out_0        : out std_logic;
    gt_txn_out_0        : out std_logic;
    restart_tx_rx_0     : in std_logic;
    rx_gt_locked_led_0  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_0 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_1         : in std_logic;
    gt_rxn_in_1         : in std_logic;
    gt_txp_out_1        : out std_logic;
    gt_txn_out_1        : out std_logic;
    restart_tx_rx_1     : in std_logic;
    rx_gt_locked_led_1  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_1 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_2         : in std_logic;
    gt_rxn_in_2         : in std_logic;
    gt_txp_out_2        : out std_logic;
    gt_txn_out_2        : out std_logic;
    restart_tx_rx_2     : in std_logic;
    rx_gt_locked_led_2  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_2 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_3         : in std_logic;
    gt_rxn_in_3         : in std_logic;
    gt_txp_out_3        : out std_logic;
    gt_txn_out_3        : out std_logic;
    restart_tx_rx_3     : in std_logic;
    rx_gt_locked_led_3  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_3 : out std_logic; -- Indicated Core Block Lock

    completion_status   : out std_logic_vector(4 downto 0);
    sys_reset           : in std_logic;
    gt_refclk_p         : in std_logic;
    gt_refclk_n         : in std_logic;
    dclk                : in std_logic;

    gt_rxpolarity_0     : in std_logic;
    gt_rxpolarity_1     : in std_logic;
    gt_rxpolarity_2     : in std_logic;
    gt_rxpolarity_3     : in std_logic;
    gt_txpolarity_0     : in std_logic;
    gt_txpolarity_1     : in std_logic;
    gt_txpolarity_2     : in std_logic;
    gt_txpolarity_3     : in std_logic
);
END COMPONENT mbo_b_124_25g_ethernet_exdes;

COMPONENT mbo_c_219_25g_ethernet_exdes IS
  PORT (
    gt_rxp_in_0         : in std_logic;
    gt_rxn_in_0         : in std_logic;
    gt_txp_out_0        : out std_logic;
    gt_txn_out_0        : out std_logic;
    restart_tx_rx_0     : in std_logic;
    rx_gt_locked_led_0  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_0 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_1         : in std_logic;
    gt_rxn_in_1         : in std_logic;
    gt_txp_out_1        : out std_logic;
    gt_txn_out_1        : out std_logic;
    restart_tx_rx_1     : in std_logic;
    rx_gt_locked_led_1  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_1 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_2         : in std_logic;
    gt_rxn_in_2         : in std_logic;
    gt_txp_out_2        : out std_logic;
    gt_txn_out_2        : out std_logic;
    restart_tx_rx_2     : in std_logic;
    rx_gt_locked_led_2  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_2 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_3         : in std_logic;
    gt_rxn_in_3         : in std_logic;
    gt_txp_out_3        : out std_logic;
    gt_txn_out_3        : out std_logic;
    restart_tx_rx_3     : in std_logic;
    rx_gt_locked_led_3  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_3 : out std_logic; -- Indicated Core Block Lock

    completion_status   : out std_logic_vector(4 downto 0);
    sys_reset           : in std_logic;
    gt_refclk_p         : in std_logic;
    gt_refclk_n         : in std_logic;
    dclk                : in std_logic;

    gt_rxpolarity_0     : in std_logic;
    gt_rxpolarity_1     : in std_logic;
    gt_rxpolarity_2     : in std_logic;
    gt_rxpolarity_3     : in std_logic;
    gt_txpolarity_0     : in std_logic;
    gt_txpolarity_1     : in std_logic;
    gt_txpolarity_2     : in std_logic;
    gt_txpolarity_3     : in std_logic
);
END COMPONENT mbo_c_219_25g_ethernet_exdes;

COMPONENT mbo_c_220_25g_ethernet_exdes IS
  PORT (
    gt_rxp_in_0         : in std_logic;
    gt_rxn_in_0         : in std_logic;
    gt_txp_out_0        : out std_logic;
    gt_txn_out_0        : out std_logic;
    restart_tx_rx_0     : in std_logic;
    rx_gt_locked_led_0  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_0 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_1         : in std_logic;
    gt_rxn_in_1         : in std_logic;
    gt_txp_out_1        : out std_logic;
    gt_txn_out_1        : out std_logic;
    restart_tx_rx_1     : in std_logic;
    rx_gt_locked_led_1  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_1 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_2         : in std_logic;
    gt_rxn_in_2         : in std_logic;
    gt_txp_out_2        : out std_logic;
    gt_txn_out_2        : out std_logic;
    restart_tx_rx_2     : in std_logic;
    rx_gt_locked_led_2  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_2 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_3         : in std_logic;
    gt_rxn_in_3         : in std_logic;
    gt_txp_out_3        : out std_logic;
    gt_txn_out_3        : out std_logic;
    restart_tx_rx_3     : in std_logic;
    rx_gt_locked_led_3  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_3 : out std_logic; -- Indicated Core Block Lock

    completion_status   : out std_logic_vector(4 downto 0);
    sys_reset           : in std_logic;
    gt_refclk_p         : in std_logic;
    gt_refclk_n         : in std_logic;
    dclk                : in std_logic;

    gt_rxpolarity_0     : in std_logic;
    gt_rxpolarity_1     : in std_logic;
    gt_rxpolarity_2     : in std_logic;
    gt_rxpolarity_3     : in std_logic;
    gt_txpolarity_0     : in std_logic;
    gt_txpolarity_1     : in std_logic;
    gt_txpolarity_2     : in std_logic;
    gt_txpolarity_3     : in std_logic
);
END COMPONENT mbo_c_220_25g_ethernet_exdes;

COMPONENT mbo_c_221_25g_ethernet_exdes IS
  PORT (
    gt_rxp_in_0         : in std_logic;
    gt_rxn_in_0         : in std_logic;
    gt_txp_out_0        : out std_logic;
    gt_txn_out_0        : out std_logic;
    restart_tx_rx_0     : in std_logic;
    rx_gt_locked_led_0  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_0 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_1         : in std_logic;
    gt_rxn_in_1         : in std_logic;
    gt_txp_out_1        : out std_logic;
    gt_txn_out_1        : out std_logic;
    restart_tx_rx_1     : in std_logic;
    rx_gt_locked_led_1  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_1 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_2         : in std_logic;
    gt_rxn_in_2         : in std_logic;
    gt_txp_out_2        : out std_logic;
    gt_txn_out_2        : out std_logic;
    restart_tx_rx_2     : in std_logic;
    rx_gt_locked_led_2  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_2 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_3         : in std_logic;
    gt_rxn_in_3         : in std_logic;
    gt_txp_out_3        : out std_logic;
    gt_txn_out_3        : out std_logic;
    restart_tx_rx_3     : in std_logic;
    rx_gt_locked_led_3  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_3 : out std_logic; -- Indicated Core Block Lock

    completion_status   : out std_logic_vector(4 downto 0);
    sys_reset           : in std_logic;
    gt_refclk_p         : in std_logic;
    gt_refclk_n         : in std_logic;
    dclk                : in std_logic;

    gt_rxpolarity_0     : in std_logic;
    gt_rxpolarity_1     : in std_logic;
    gt_rxpolarity_2     : in std_logic;
    gt_rxpolarity_3     : in std_logic;
    gt_txpolarity_0     : in std_logic;
    gt_txpolarity_1     : in std_logic;
    gt_txpolarity_2     : in std_logic;
    gt_txpolarity_3     : in std_logic
);
END COMPONENT mbo_c_221_25g_ethernet_exdes;

COMPONENT sfp_10g_2x_ethernet_exdes IS
  PORT (
    gt_rxp_in_0         : in std_logic;
    gt_rxn_in_0         : in std_logic;
    gt_txp_out_0        : out std_logic;
    gt_txn_out_0        : out std_logic;
    restart_tx_rx_0     : in std_logic;
    rx_gt_locked_led_0  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_0 : out std_logic; -- Indicated Core Block Lock

    gt_rxp_in_1         : in std_logic;
    gt_rxn_in_1         : in std_logic;
    gt_txp_out_1        : out std_logic;
    gt_txn_out_1        : out std_logic;
    restart_tx_rx_1     : in std_logic;
    rx_gt_locked_led_1  : out std_logic; -- Indicated GT LOCK
    rx_block_lock_led_1 : out std_logic; -- Indicated Core Block Lock

    completion_status   : out std_logic_vector(4 downto 0);

    sys_reset           : in std_logic;
    gt_refclk_p         : in std_logic;
    gt_refclk_n         : in std_logic;
    dclk                : in std_logic;

    gt_rxpolarity_0     : in std_logic;
    gt_rxpolarity_1     : in std_logic;
    gt_txpolarity_0     : in std_logic;
    gt_txpolarity_1     : in std_logic
  );
END COMPONENT sfp_10g_2x_ethernet_exdes;

COMPONENT axi_i2c_exdes_0 IS
 PORT (
    clk_in1_p : in std_logic;
    clk_in1_n : in std_logic;
    reset     : in std_logic;
    start     : in std_logic;
    scl_io    : inout std_logic;
    sda_io    : inout std_logic;
    to_led    : out std_logic_vector (1-1 downto 0);
    done      : out std_logic
  );
END COMPONENT axi_i2c_exdes_0;
COMPONENT axi_i2c_exdes_1 IS
 PORT (
    clk_in1_p : in std_logic;
    clk_in1_n : in std_logic;
    reset     : in std_logic;
    start     : in std_logic;
    scl_io    : inout std_logic;
    sda_io    : inout std_logic;
    to_led    : out std_logic_vector (1-1 downto 0);
    done      : out std_logic
  );
END COMPONENT axi_i2c_exdes_1;
COMPONENT axi_i2c_exdes_2 IS
 PORT (
    clk_in1_p : in std_logic;
    clk_in1_n : in std_logic;
    reset     : in std_logic;
    start     : in std_logic;
    scl_io    : inout std_logic;
    sda_io    : inout std_logic;
    to_led    : out std_logic_vector (1-1 downto 0);
    done      : out std_logic
  );
END COMPONENT axi_i2c_exdes_2;
COMPONENT axi_i2c_exdes_3 IS
 PORT (
    clk_in1_p : in std_logic;
    clk_in1_n : in std_logic;
    reset     : in std_logic;
    start     : in std_logic;
    scl_io    : inout std_logic;
    sda_io    : inout std_logic;
    to_led    : out std_logic_vector (1-1 downto 0);
    done      : out std_logic
  );
END COMPONENT axi_i2c_exdes_3;
COMPONENT axi_i2c_exdes_4 IS
 PORT (
    clk_in1_p : in std_logic;
    clk_in1_n : in std_logic;
    reset     : in std_logic;
    start     : in std_logic;
    scl_io    : inout std_logic;
    sda_io    : inout std_logic;
    to_led    : out std_logic_vector (1-1 downto 0);
    done      : out std_logic
  );
END COMPONENT axi_i2c_exdes_4;

--COMPONENT sfp_1g_ethernet_pcs_pma_b_example_design IS
--  PORT (
--      independent_clock : in std_logic;
--      io_refclk         : in std_logic;
--
--      -- Tranceiver Interface
--      gtrefclk_p        : in std_logic;       -- Differential +ve of reference clock for MGT: very high quality.
--      gtrefclk_n        : in std_logic;       -- Differential -ve of reference clock for MGT: very high quality.
--      rxuserclk2        : out std_logic;
--      txp               : out std_logic;      -- Differential +ve of serial transmission from PMA to PMD.
--      txn               : out std_logic;      -- Differential -ve of serial transmission from PMA to PMD.
--      rxp               : in std_logic;       -- Differential +ve for serial reception from PMD to PMA.
--      rxn               : in std_logic;       -- Differential -ve for serial reception from PMD to PMA.
--
--      -- GMII Interface (client MAC <=> PCS)
--      gmii_tx_clk       : in std_logic;       -- Transmit clock from client MAC.
--      gmii_rx_clk       : out std_logic;      -- Receive clock to client MAC.
--      gmii_txd          : in std_logic_vector(7 downto 0);  -- Transmit data from client MAC.
--      gmii_tx_en        : in std_logic;       -- Transmit control signal from client MAC.
--      gmii_tx_er        : in std_logic;       -- Transmit control signal from client MAC.
--      gmii_rxd          : out std_logic_vector(7 downto 0); -- Received Data to client MAC.
--      gmii_rx_dv        : out std_logic;      -- Received control signal to client MAC.
--      gmii_rx_er        : out std_logic;      -- Received control signal to client MAC.
--
--      -- Management: Alternative to MDIO Interface
--      configuration_vector : in std_logic_vector(4 downto 0);  -- Alternative to MDIO interface.
--
--      -- General IO's
--      status_vector     : out std_logic_vector(15 downto 0);   -- Core status.
--      reset             : in std_logic;      -- Asynchronous reset for entire core.
--      signal_detect     : in std_logic       -- Input from PMD to indicate presence of optical input.
--   );
--END COMPONENT sfp_1g_ethernet_pcs_pma_b_example_design;

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
  SIGNAL sfp_b_gmii_en   : STD_LOGIC;
  SIGNAL sfp_b_gmii_er   : STD_LOGIC;
  SIGNAL sfp_b_gmii_clk  : STD_LOGIC;
  SIGNAL clk_free_25MHz  : STD_LOGIC;
  SIGNAL clk_free_50MHz  : STD_LOGIC;
  SIGNAL clk_free_100MHz : STD_LOGIC;
  SIGNAL ptp_sync_input  : STD_LOGIC_VECTOR(1 downto 0);
  SIGNAL clk_sfp         : STD_LOGIC;
  SIGNAL debug_mmbx_out : STD_LOGIC;
  SIGNAL debug_out : STD_LOGIC_VECTOR(3 downto 0);
  SIGNAL spi_do    : STD_LOGIC_VECTOR(3 downto 0);
  SIGNAL spi_di    : STD_LOGIC_VECTOR(3 downto 0);
  SIGNAL spi_dts   : STD_LOGIC_VECTOR(3 downto 0);
  SIGNAL i2c_clk   : STD_LOGIC_VECTOR(4 downto 0);
  SIGNAL i2c_clk_p : STD_LOGIC_VECTOR(4 downto 0);
  SIGNAL i2c_clk_n : STD_LOGIC_VECTOR(4 downto 0);
BEGIN
  pin_last_board <= last_board;
  u_pullup_last_board : PULLUP port map(O => pin_last_board);

  pin_slave <= slave;
  u_pullup_slave : PULLUP port map(O => pin_slave);

  pin_version <= version;
  u_pullup_version_0 : PULLUP port map(O => pin_version(0));
  u_pullup_version_1 : PULLUP port map(O => pin_version(1));

  
  rst <= aux_pgood;   -- mis-using this line for now
  aux_pwr_off <= rst; -- mis-using this line for now

  led_din  <= led_d;
  led_d    <= led_dout;
  led_cs   <= sfp_fault_led;
  led_sclk <= '1';

  sfp_fault_led  <= sfp_fault;
  qsfp_clock_sel <= '0';


u_STARTUPE3_inst : STARTUPE3
   -- http://www.xilinx.com/support/documentation/sw_manuals/xilinx2016_1/ug974-vivado-ultrascale-libraries.pdf
   -- page 532
   -- example: http://www.xilinx.com/support/answers/62376.html
   -- FIXME: not sure how to connect
   GENERIC MAP (
    PROG_USR => "FALSE", -- Activate program event security feature.
    SIM_CCLK_FREQ => 0.0 -- Set the Configuration Clock Frequency(ns) for simulation.
   )
   PORT MAP (
    USRCCLKO => clk_free_25MHz, -- 1-bit input: User CCLK input

    CFGCLK   => open,      -- 1-bit output: Configuration main clock output
    CFGMCLK  => open,      -- 1-bit output: Configuration internal oscillator clock output
    EOS      => spi_cs(1), -- 1-bit output: Active-High output signal indicating the End Of Startup
    PREQ     => open,      -- 1-bit output: PROGRAM request to fabric output

    DI      => spi_di,     -- 4-bit output: Allow receiving on the Dinput pin
    DO      => spi_do,     -- 4-bit input:  Allows control of the D pin output
    DTS     => spi_dts,    -- 4-bit input: Allows tristate of the D pin

    FCSBO     => '0',  -- 1-bit input: Controls the FCS_B pin for flash access
    FCSBTS    => '0',  -- 1-bit input: Tristate the FCS_B pin
    GSR       => '0',  -- 1-bit input: Global Set/Reset input (GSR cannot be used for the port)
    GTS       => '0',  -- 1-bit input: Global 3-state input (GTS cannot be used for the portname)
    KEYCLEARB => '0',  -- 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM(BBRAM)
    PACK      => '0',  -- 1-bit input: PROGRAM acknowledge input
    USRCCLKTS => '0',  -- 1-bit input: User CCLK3-state enable input
    USRDONEO  => '1',  -- 1-bit input: User DONE pin output control
    USRDONETS => '1'   -- 1-bit input: User DONE 3-state enable output
);

spi_d_inst_4 : IOBUF
   PORT MAP (
    IO       => spi_d(4), -- IO pin
    I        => spi_di(0),
    O        => spi_do(0),
    T        => spi_dts(0)
);
spi_d_inst_5 : IOBUF
   PORT MAP (
    IO       => spi_d(5), -- IO pin
    I        => spi_di(1),
    O        => spi_do(1),
    T        => spi_dts(1)
);
spi_d_inst_6 : IOBUF
   PORT MAP (
    IO       => spi_d(6), -- IO pin
    I        => spi_di(2),
    O        => spi_do(2),
    T        => spi_dts(2)
);
spi_d_inst_7 : IOBUF
   PORT MAP (
    IO       => spi_d(7), -- IO pin
    I        => spi_di(3),
    O        => spi_do(3),
    T        => spi_dts(3)
);



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

u_ptp_clk125_mmcm : ptp_clk125_mmcm
   PORT MAP (
    clk_in1_p          => clk_e_p,
    clk_in1_n          => clk_e_n,
    clk_out1           => ptp_sclk, -- 20MHz
    reset              => ptp_sync_input(0),
    locked             => ptp_clk_sel
);
  ptp_sync_input <= ptp_sync_n;
  ptp_din        <= ptp_sync_input(1);


u_IBUFDS_clk_sfp_inst : IBUFDS -- page 201 of ug974-vivado-ultrascale-libraries.pdf
                       -- http://www.xilinx.com/support/documentation/sw_manuals/xilinx2016_1/ug974-vivado-ultrascale-libraries.pdf
   PORT MAP (
    O => clk_sfp,
    I => clk_sfp_p,
    IB=> clk_sfp_n
);

u_OBUFDS_aux_sfp_tx_inst : OBUFDS -- page 358 of ug974-vivado-ultrascale-libraries.pdf
   PORT MAP (
    O => aux_sfp_tx_p,
    OB=> aux_sfp_tx_n,
    I => clk_sfp
);

u_OBUFDS_i2c_clk_inst_0 : OBUFDS
   PORT MAP (
    O => i2c_clk_p(0),
    OB=> i2c_clk_n(0),
    I => i2c_clk(0)
);
u_OBUFDS_i2c_clk_inst_1 : OBUFDS
   PORT MAP (
    O => i2c_clk_p(1),
    OB=> i2c_clk_n(1),
    I => i2c_clk(1)
);
u_OBUFDS_i2c_clk_inst_2 : OBUFDS
   PORT MAP (
    O => i2c_clk_p(2),
    OB=> i2c_clk_n(2),
    I => i2c_clk(2)
);
u_OBUFDS_i2c_clk_inst_3 : OBUFDS
   PORT MAP (
    O => i2c_clk_p(3),
    OB=> i2c_clk_n(3),
    I => i2c_clk(3)
);
u_OBUFDS_i2c_clk_inst_4 : OBUFDS
   PORT MAP (
    O => i2c_clk_p(4),
    OB=> i2c_clk_n(4),
    I => i2c_clk(4)
);

  aux_sfp_tx_sel <= '0';


u_mmbx_clk64_mmcm : mmbx_clk64_mmcm
   PORT MAP (
    clk_in1_p          => clk_mmbx_p,
    clk_in1_n          => clk_mmbx_n,
    clk_out1           => debug_mmbx_out, -- 32MHz
    clk_out2           => i2c_clk(0), -- 50MHz
    clk_out3           => i2c_clk(1), -- 50MHz
    clk_out4           => i2c_clk(2), -- 50MHz
    clk_out5           => i2c_clk(3), -- 50MHz
    clk_out6           => i2c_clk(4), -- 50MHz
    reset              => rst,
    locked             => debug_out(0)
);

-- debug(3..0) lines are inout. Need IOBUF.
-- in this case fixed to output:
debug_inst_0 : IOBUF
   PORT MAP (
    IO       => debug(0), -- IO pin
    I        => debug_out(0),
    O        => open,
    T        => '0'  -- '0' enables output buffer
);
debug_inst_1 : IOBUF
   PORT MAP (
    IO       => debug(1), -- IO pin
    I        => debug_out(1),
    O        => open,
    T        => '0'  -- '0' enables output buffer
);
debug_inst_2 : IOBUF
   PORT MAP (
    IO       => debug(2), -- IO pin
    I        => debug_out(2),
    O        => open,
    T        => '0'  -- '0' enables output buffer
);
debug_inst_3 : IOBUF
   PORT MAP (
    IO       => debug(3), -- IO pin
    I        => debug_out(3),
    O        => open,
    T        => '0'  -- '0' enables output buffer
);
debug_mmbx_inst : IOBUF
   PORT MAP (
    IO       => debug_mmbx, -- IO pin
    I        => debug_mmbx_out,
    O        => open,
    T        => '0'  -- '0' enables output buffer
);
serial_prom_inst : IOBUF
   PORT MAP (
    IO       => serial_prom, -- IO pin
    I        => '1', -- just output a '1'
    O        => open,
    T        => '0'  -- '0' enables output buffer
);

u_sfp_10g_2x_ethernet_exdes : sfp_10g_2x_ethernet_exdes
  PORT MAP (
    gt_rxp_in_0         => sfp_a_rx_p,
    gt_rxn_in_0         => sfp_a_rx_n,
    gt_txp_out_0        => sfp_a_tx_p,
    gt_txn_out_0        => sfp_a_tx_n,
    restart_tx_rx_0     => sfp_a_mod_abs,

    gt_rxp_in_1         => sfp_b_rx_p,
    gt_rxn_in_1         => sfp_b_rx_n,
    gt_txp_out_1        => sfp_b_tx_p,
    gt_txn_out_1        => sfp_b_tx_n,
    restart_tx_rx_1     => sfp_b_mod_abs,

    sys_reset           => rst,
    gt_refclk_p         => sfp_a_clk_p,
    gt_refclk_n         => sfp_a_clk_n,
    --gt_refclk_p         => sfp_b_clk_p,
    --gt_refclk_n         => sfp_b_clk_n,
    dclk                => clk_free_100MHz,

    gt_rxpolarity_0     => '1', -- p/n swapped
    gt_rxpolarity_1     => '1', -- p/n swapped
    gt_txpolarity_0     => '0', -- p/n not swapped
    gt_txpolarity_1     => '0'  -- p/n not swapped
  );


u_qsfp_25g_ethernet_exdes_a : qsfp_25g_ethernet_exdes_a
  PORT MAP (
    gt_rxp_in_0         => qsfp_a_rx_p(3),
    gt_rxn_in_0         => qsfp_a_rx_n(3),
    gt_txp_out_0        => qsfp_a_tx_p(3),
    gt_txn_out_0        => qsfp_a_tx_n(3),
    restart_tx_rx_0     => qsfp_a_mod_prs_n,

    gt_rxp_in_1         => qsfp_a_rx_p(2),
    gt_rxn_in_1         => qsfp_a_rx_n(2),
    gt_txp_out_1        => qsfp_a_tx_p(2),
    gt_txn_out_1        => qsfp_a_tx_n(2),
    restart_tx_rx_1     => '0',

    gt_rxp_in_2         => qsfp_a_rx_p(1),
    gt_rxn_in_2         => qsfp_a_rx_n(1),
    gt_txp_out_2        => qsfp_a_tx_p(1),
    gt_txn_out_2        => qsfp_a_tx_n(1),
    restart_tx_rx_2     => '0',

    gt_rxp_in_3         => qsfp_a_rx_p(0),
    gt_rxn_in_3         => qsfp_a_rx_n(0),
    gt_txp_out_3        => qsfp_a_tx_p(0),
    gt_txn_out_3        => qsfp_a_tx_n(0),
    restart_tx_rx_3     => '0',

    sys_reset           => rst,
    gt_refclk_p         => qsfp_a_clk_p,
    gt_refclk_n         => qsfp_a_clk_n,
    dclk                => clk_free_100MHz,

    gt_rxpolarity_0     => '0', -- p/n not swapped
    gt_rxpolarity_1     => '0', -- p/n not swapped
    gt_rxpolarity_2     => '0', -- p/n not swapped
    gt_rxpolarity_3     => '0', -- p/n not swapped
    gt_txpolarity_0     => '1', -- p/n swapped
    gt_txpolarity_1     => '1', -- p/n swapped
    gt_txpolarity_2     => '1', -- p/n swapped
    gt_txpolarity_3     => '1'  -- p/n swapped
  );

u_qsfp_25g_ethernet_exdes_b : qsfp_25g_ethernet_exdes_b
  PORT MAP (
    gt_rxp_in_0         => qsfp_b_rx_p(2),
    gt_rxn_in_0         => qsfp_b_rx_n(2),
    gt_txp_out_0        => qsfp_b_tx_p(2),
    gt_txn_out_0        => qsfp_b_tx_n(2),
    restart_tx_rx_0     => qsfp_b_mod_prs_n,

    gt_rxp_in_1         => qsfp_b_rx_p(3),
    gt_rxn_in_1         => qsfp_b_rx_n(3),
    gt_txp_out_1        => qsfp_b_tx_p(3),
    gt_txn_out_1        => qsfp_b_tx_n(3),
    restart_tx_rx_1     => '0',

    gt_rxp_in_2         => qsfp_b_rx_p(1),
    gt_rxn_in_2         => qsfp_b_rx_n(1),
    gt_txp_out_2        => qsfp_b_tx_p(1),
    gt_txn_out_2        => qsfp_b_tx_n(1),
    restart_tx_rx_2     => '0',

    gt_rxp_in_3         => qsfp_b_rx_p(0),
    gt_rxn_in_3         => qsfp_b_rx_n(0),
    gt_txp_out_3        => qsfp_b_tx_p(0),
    gt_txn_out_3        => qsfp_b_tx_n(0),
    restart_tx_rx_3     => '0',

    sys_reset           => rst,
    gt_refclk_p         => qsfp_b_clk_p,
    gt_refclk_n         => qsfp_b_clk_n,
    dclk                => clk_free_100MHz,

    gt_rxpolarity_0     => '1', -- p/n swapped
    gt_rxpolarity_1     => '1', -- p/n swapped
    gt_rxpolarity_2     => '1', -- p/n swapped
    gt_rxpolarity_3     => '1', -- p/n swapped
    gt_txpolarity_0     => '1', -- p/n not swapped
    gt_txpolarity_1     => '0', -- p/n not swapped
    gt_txpolarity_2     => '0', -- p/n swapped
    gt_txpolarity_3     => '0'  -- p/n not swapped
  );

u_qsfp_25g_ethernet_exdes_c : qsfp_25g_ethernet_exdes_c
  PORT MAP (
    gt_rxp_in_0         => qsfp_c_rx_p(1),
    gt_rxn_in_0         => qsfp_c_rx_n(1),
    gt_txp_out_0        => qsfp_c_tx_p(1),
    gt_txn_out_0        => qsfp_c_tx_n(1),
    restart_tx_rx_0     => qsfp_c_mod_prs_n,

    gt_rxp_in_1         => qsfp_c_rx_p(0),
    gt_rxn_in_1         => qsfp_c_rx_n(0),
    gt_txp_out_1        => qsfp_c_tx_p(0),
    gt_txn_out_1        => qsfp_c_tx_n(0),
    restart_tx_rx_1     => '0',

    gt_rxp_in_2         => qsfp_c_rx_p(2),
    gt_rxn_in_2         => qsfp_c_rx_n(2),
    gt_txp_out_2        => qsfp_c_tx_p(2),
    gt_txn_out_2        => qsfp_c_tx_n(2),
    restart_tx_rx_2     => '0',

    gt_rxp_in_3         => qsfp_c_rx_p(3),
    gt_rxn_in_3         => qsfp_c_rx_n(3),
    gt_txp_out_3        => qsfp_c_tx_p(3),
    gt_txn_out_3        => qsfp_c_tx_n(3),
    restart_tx_rx_3     => '0',

    sys_reset           => rst,
    gt_refclk_p         => qsfp_c_clk_p,
    gt_refclk_n         => qsfp_c_clk_n,
    dclk                => clk_free_100MHz,

    gt_rxpolarity_0     => '1', -- p/n swapped
    gt_rxpolarity_1     => '1', -- p/n swapped
    gt_rxpolarity_2     => '1', -- p/n swapped
    gt_rxpolarity_3     => '1', -- p/n swapped
    gt_txpolarity_0     => '0', -- p/n swapped
    gt_txpolarity_1     => '1', -- p/n not swapped
    gt_txpolarity_2     => '0', -- p/n not swapped
    gt_txpolarity_3     => '0'  -- p/n not swapped
  );

u_qsfp_25g_ethernet_exdes_d : qsfp_25g_ethernet_exdes_d
  PORT MAP (
    gt_rxp_in_0         => qsfp_d_rx_p(1),
    gt_rxn_in_0         => qsfp_d_rx_n(1),
    gt_txp_out_0        => qsfp_d_tx_p(1),
    gt_txn_out_0        => qsfp_d_tx_n(1),
    restart_tx_rx_0     => qsfp_d_mod_prs_n,

    gt_rxp_in_1         => qsfp_d_rx_p(3),
    gt_rxn_in_1         => qsfp_d_rx_n(3),
    gt_txp_out_1        => qsfp_d_tx_p(3),
    gt_txn_out_1        => qsfp_d_tx_n(3),
    restart_tx_rx_1     => '0',

    gt_rxp_in_2         => qsfp_d_rx_p(2),
    gt_rxn_in_2         => qsfp_d_rx_n(2),
    gt_txp_out_2        => qsfp_d_tx_p(2),
    gt_txn_out_2        => qsfp_d_tx_n(2),
    restart_tx_rx_2     => '0',

    gt_rxp_in_3         => qsfp_d_rx_p(0),
    gt_rxn_in_3         => qsfp_d_rx_n(0),
    gt_txp_out_3        => qsfp_d_tx_p(0),
    gt_txn_out_3        => qsfp_d_tx_n(0),
    restart_tx_rx_3     => '0',

    sys_reset           => rst,
    gt_refclk_p         => qsfp_d_clk_p,
    gt_refclk_n         => qsfp_d_clk_n,
    dclk                => clk_free_100MHz,

    gt_rxpolarity_0     => '1', -- p/n swapped
    gt_rxpolarity_1     => '1', -- p/n swapped
    gt_rxpolarity_2     => '1', -- p/n swapped
    gt_rxpolarity_3     => '1', -- p/n swapped
    gt_txpolarity_0     => '1', -- p/n not swapped
    gt_txpolarity_1     => '0', -- p/n swapped
    gt_txpolarity_2     => '0', -- p/n not swapped
    gt_txpolarity_3     => '0'  -- p/n not swapped
  );

u_mbo_a_119_25g_ethernet_exdes : mbo_a_119_25g_ethernet_exdes
  PORT MAP (
    -- 0_119
    gt_rxp_in_0         => mbo_a_rx_n(4), --swapped
    gt_rxn_in_0         => mbo_a_rx_p(4), --swapped
    gt_txp_out_0        => mbo_a_tx_p(4),
    gt_txn_out_0        => mbo_a_tx_n(4),
    restart_tx_rx_0     => mbo_a_int_n,

    -- 1_119
    gt_rxp_in_1         => mbo_a_rx_p(1),
    gt_rxn_in_1         => mbo_a_rx_n(1),
    gt_txp_out_1        => mbo_a_tx_p(1),
    gt_txn_out_1        => mbo_a_tx_n(1),
    restart_tx_rx_1     => mbo_a_modprs_tx_n,

    -- 2_119
    gt_rxp_in_2         => mbo_a_rx_p(6),
    gt_rxn_in_2         => mbo_a_rx_n(6),
    gt_txp_out_2        => mbo_a_tx_p(6),
    gt_txn_out_2        => mbo_a_tx_n(6),
    restart_tx_rx_2     => mbo_a_modprs_rx_n,

    -- 3_119
    gt_rxp_in_3         => mbo_a_rx_p(2),
    gt_rxn_in_3         => mbo_a_rx_n(2),
    gt_txp_out_3        => mbo_a_tx_p(2),
    gt_txn_out_3        => mbo_a_tx_n(2),
    restart_tx_rx_3     => '0',

    sys_reset           => rst,
    gt_refclk_p         => mbo_a_clk_n(2), --swapped -- clk for 119
    gt_refclk_n         => mbo_a_clk_p(2), --swapped
    dclk                => clk_free_100MHz,

    gt_rxpolarity_0     => '1',
    gt_rxpolarity_1     => '0',
    gt_rxpolarity_2     => '0',
    gt_rxpolarity_3     => '0',
    gt_txpolarity_0     => '0',
    gt_txpolarity_1     => '0',
    gt_txpolarity_2     => '0',
    gt_txpolarity_3     => '0' 
  );

u_mbo_a_120_25g_ethernet_exdes : mbo_a_120_25g_ethernet_exdes
  PORT MAP (
    -- 0_120
    gt_rxp_in_0         => mbo_a_rx_p(10),
    gt_rxn_in_0         => mbo_a_rx_n(10),
    gt_txp_out_0        => mbo_a_tx_p(10),
    gt_txn_out_0        => mbo_a_tx_n(10),
    restart_tx_rx_0     => mbo_a_int_n,

    -- 1_120
    gt_rxp_in_1         => mbo_a_rx_p(8),
    gt_rxn_in_1         => mbo_a_rx_n(8),
    gt_txp_out_1        => mbo_a_tx_p(8),
    gt_txn_out_1        => mbo_a_tx_n(8),
    restart_tx_rx_1     => mbo_a_modprs_tx_n,

    -- 2_120
    gt_rxp_in_2         => mbo_a_rx_p(11),
    gt_rxn_in_2         => mbo_a_rx_n(11),
    gt_txp_out_2        => mbo_a_tx_p(11),
    gt_txn_out_2        => mbo_a_tx_n(11),
    restart_tx_rx_2     => mbo_a_modprs_rx_n,

    -- 3_120
    gt_rxp_in_3         => mbo_a_rx_p(9),
    gt_rxn_in_3         => mbo_a_rx_n(9),
    gt_txp_out_3        => mbo_a_tx_p(9),
    gt_txn_out_3        => mbo_a_tx_n(9),
    restart_tx_rx_3     => '0',

    sys_reset           => rst,
    gt_refclk_p         => mbo_a_clk_n(1), --swapped -- clk for 120
    gt_refclk_n         => mbo_a_clk_p(1), --swapped
    dclk                => clk_free_100MHz,

    gt_rxpolarity_0     => '0',
    gt_rxpolarity_1     => '0',
    gt_rxpolarity_2     => '0',
    gt_rxpolarity_3     => '0',
    gt_txpolarity_0     => '0',
    gt_txpolarity_1     => '0',
    gt_txpolarity_2     => '0',
    gt_txpolarity_3     => '0' 
  );

u_mbo_a_121_25g_ethernet_exdes : mbo_a_121_25g_ethernet_exdes
  PORT MAP (
    -- 0_121
    gt_rxp_in_0         => mbo_a_rx_p(3),
    gt_rxn_in_0         => mbo_a_rx_n(3),
    gt_txp_out_0        => mbo_a_tx_p(3),
    gt_txn_out_0        => mbo_a_tx_n(3),
    restart_tx_rx_0     => mbo_a_int_n,

    -- 1_121
    gt_rxp_in_1         => mbo_a_rx_n(7), --swapped
    gt_rxn_in_1         => mbo_a_rx_p(7), --swapped
    gt_txp_out_1        => mbo_a_tx_p(7),
    gt_txn_out_1        => mbo_a_tx_n(7),
    restart_tx_rx_1     => mbo_a_modprs_tx_n,

    -- 2_121
    gt_rxp_in_2         => mbo_a_rx_p(5),
    gt_rxn_in_2         => mbo_a_rx_n(5),
    gt_txp_out_2        => mbo_a_tx_p(5),
    gt_txn_out_2        => mbo_a_tx_n(5),
    restart_tx_rx_2     => mbo_a_modprs_rx_n,

    -- 3_121
    gt_rxp_in_3         => mbo_a_rx_p(0),
    gt_rxn_in_3         => mbo_a_rx_n(0),
    gt_txp_out_3        => mbo_a_tx_p(0),
    gt_txn_out_3        => mbo_a_tx_n(0),
    restart_tx_rx_3     => '0',

    sys_reset           => rst,
    gt_refclk_p         => mbo_a_clk_n(0), --swapped  -- clk for 121
    gt_refclk_n         => mbo_a_clk_p(0), --swapped
    dclk                => clk_free_100MHz,

    gt_rxpolarity_0     => '0',
    gt_rxpolarity_1     => '1',
    gt_rxpolarity_2     => '0',
    gt_rxpolarity_3     => '0',
    gt_txpolarity_0     => '0',
    gt_txpolarity_1     => '0',
    gt_txpolarity_2     => '0',
    gt_txpolarity_3     => '0' 
  );

u_mbo_b_122_25g_ethernet_exdes : mbo_b_122_25g_ethernet_exdes
  PORT MAP (
    gt_rxp_in_0         => mbo_b_rx_p(11),
    gt_rxn_in_0         => mbo_b_rx_n(11),
    gt_txp_out_0        => mbo_b_tx_p(11),
    gt_txn_out_0        => mbo_b_tx_n(11),
    restart_tx_rx_0     => mbo_b_int_n,

    gt_rxp_in_1         => mbo_b_rx_p(10),
    gt_rxn_in_1         => mbo_b_rx_n(10),
    gt_txp_out_1        => mbo_b_tx_p(10),
    gt_txn_out_1        => mbo_b_tx_n(10),
    restart_tx_rx_1     => mbo_b_modprs_tx_n,

    gt_rxp_in_2         => mbo_b_rx_p(9),
    gt_rxn_in_2         => mbo_b_rx_n(9),
    gt_txp_out_2        => mbo_b_tx_p(9),
    gt_txn_out_2        => mbo_b_tx_n(9),
    restart_tx_rx_2     => mbo_b_modprs_rx_n,

    gt_rxp_in_3         => mbo_b_rx_p(8),
    gt_rxn_in_3         => mbo_b_rx_n(8),
    gt_txp_out_3        => mbo_b_tx_p(8),
    gt_txn_out_3        => mbo_b_tx_n(8),
    restart_tx_rx_3     => '0',

    sys_reset           => rst,
    gt_refclk_p         => mbo_b_clk_p(0),
    gt_refclk_n         => mbo_b_clk_n(0),
    dclk                => clk_free_100MHz,

    gt_rxpolarity_0     => '0',
    gt_rxpolarity_1     => '0',
    gt_rxpolarity_2     => '0',
    gt_rxpolarity_3     => '0',
    gt_txpolarity_0     => '0',
    gt_txpolarity_1     => '0',
    gt_txpolarity_2     => '0',
    gt_txpolarity_3     => '0' 
  );

u_mbo_b_123_25g_ethernet_exdes : mbo_b_123_25g_ethernet_exdes
  PORT MAP (
    gt_rxp_in_0         => mbo_b_rx_p(7),
    gt_rxn_in_0         => mbo_b_rx_n(7),
    gt_txp_out_0        => mbo_b_tx_p(7),
    gt_txn_out_0        => mbo_b_tx_n(7),
    restart_tx_rx_0     => mbo_b_int_n,

    gt_rxp_in_1         => mbo_b_rx_p(6),
    gt_rxn_in_1         => mbo_b_rx_n(6),
    gt_txp_out_1        => mbo_b_tx_p(6),
    gt_txn_out_1        => mbo_b_tx_n(6),
    restart_tx_rx_1     => mbo_b_modprs_tx_n,

    gt_rxp_in_2         => mbo_b_rx_p(5),
    gt_rxn_in_2         => mbo_b_rx_n(5),
    gt_txp_out_2        => mbo_b_tx_p(0),
    gt_txn_out_2        => mbo_b_tx_n(0),
    restart_tx_rx_2     => mbo_b_modprs_rx_n,

    gt_rxp_in_3         => mbo_b_rx_p(4),
    gt_rxn_in_3         => mbo_b_rx_n(4),
    gt_txp_out_3        => mbo_b_tx_p(4),
    gt_txn_out_3        => mbo_b_tx_n(4),
    restart_tx_rx_3     => '0',

    sys_reset           => rst,
    gt_refclk_p         => mbo_b_clk_p(1),
    gt_refclk_n         => mbo_b_clk_n(1),
    dclk                => clk_free_100MHz,

    gt_rxpolarity_0     => '0',
    gt_rxpolarity_1     => '0',
    gt_rxpolarity_2     => '0',
    gt_rxpolarity_3     => '0',
    gt_txpolarity_0     => '0',
    gt_txpolarity_1     => '0',
    gt_txpolarity_2     => '0',
    gt_txpolarity_3     => '0' 
  );

u_mbo_b_124_25g_ethernet_exdes : mbo_b_124_25g_ethernet_exdes
  PORT MAP (
    gt_rxp_in_0         => mbo_b_rx_p(3),
    gt_rxn_in_0         => mbo_b_rx_n(3),
    gt_txp_out_0        => mbo_b_tx_p(3),
    gt_txn_out_0        => mbo_b_tx_n(3),
    restart_tx_rx_0     => mbo_b_int_n,

    gt_rxp_in_1         => mbo_b_rx_p(2),
    gt_rxn_in_1         => mbo_b_rx_n(2),
    gt_txp_out_1        => mbo_b_tx_p(2),
    gt_txn_out_1        => mbo_b_tx_n(2),
    restart_tx_rx_1     => mbo_b_modprs_tx_n,

    gt_rxp_in_2         => mbo_b_rx_p(0),
    gt_rxn_in_2         => mbo_b_rx_n(0),
    gt_txp_out_2        => mbo_b_tx_p(5),
    gt_txn_out_2        => mbo_b_tx_n(5),
    restart_tx_rx_2     => mbo_b_modprs_rx_n,

    gt_rxp_in_3         => mbo_b_rx_p(1),
    gt_rxn_in_3         => mbo_b_rx_n(1),
    gt_txp_out_3        => mbo_b_tx_p(1),
    gt_txn_out_3        => mbo_b_tx_n(1),
    restart_tx_rx_3     => '0',

    sys_reset           => rst,
    gt_refclk_p         => mbo_b_clk_p(2),
    gt_refclk_n         => mbo_b_clk_n(2),
    dclk                => clk_free_100MHz,

    gt_rxpolarity_0     => '0',
    gt_rxpolarity_1     => '0',
    gt_rxpolarity_2     => '0',
    gt_rxpolarity_3     => '0',
    gt_txpolarity_0     => '0',
    gt_txpolarity_1     => '0',
    gt_txpolarity_2     => '0',
    gt_txpolarity_3     => '0' 
  );

u_mbo_c_219_25g_ethernet_exdes : mbo_c_219_25g_ethernet_exdes
  PORT MAP (
    gt_rxp_in_0         => mbo_c_rx_p(1),
    gt_rxn_in_0         => mbo_c_rx_n(1),
    gt_txp_out_0        => mbo_c_tx_n(1), --swapped
    gt_txn_out_0        => mbo_c_tx_p(1), --swapped
    restart_tx_rx_0     => mbo_c_int_n,

    gt_rxp_in_1         => mbo_c_rx_p(5),
    gt_rxn_in_1         => mbo_c_rx_n(5),
    gt_txp_out_1        => mbo_c_tx_p(5),
    gt_txn_out_1        => mbo_c_tx_n(5),
    restart_tx_rx_1     => mbo_c_modprs_tx_n,

    gt_rxp_in_2         => mbo_c_rx_p(3),
    gt_rxn_in_2         => mbo_c_rx_n(3),
    gt_txp_out_2        => mbo_c_tx_p(3),
    gt_txn_out_2        => mbo_c_tx_n(3),
    restart_tx_rx_2     => mbo_c_modprs_rx_n,

    gt_rxp_in_3         => mbo_c_rx_p(4),
    gt_rxn_in_3         => mbo_c_rx_n(4),
    gt_txp_out_3        => mbo_c_tx_p(4),
    gt_txn_out_3        => mbo_c_tx_n(4),
    restart_tx_rx_3     => '0',

    sys_reset           => rst,
    gt_refclk_p         => mbo_c_clk_p(0),
    gt_refclk_n         => mbo_c_clk_n(0),
    dclk                => clk_free_100MHz,

    gt_rxpolarity_0     => '0',
    gt_rxpolarity_1     => '0',
    gt_rxpolarity_2     => '0',
    gt_rxpolarity_3     => '0',
    gt_txpolarity_0     => '0',
    gt_txpolarity_1     => '0',
    gt_txpolarity_2     => '0',
    gt_txpolarity_3     => '0' 
  );

u_mbo_c_220_25g_ethernet_exdes : mbo_c_220_25g_ethernet_exdes
  PORT MAP (
    gt_rxp_in_0         => mbo_c_rx_p(2),
    gt_rxn_in_0         => mbo_c_rx_n(2),
    gt_txp_out_0        => mbo_c_tx_p(2),
    gt_txn_out_0        => mbo_c_tx_n(2),
    restart_tx_rx_0     => mbo_c_int_n,

    gt_rxp_in_1         => mbo_c_rx_p(0),
    gt_rxn_in_1         => mbo_c_rx_n(0),
    gt_txp_out_1        => mbo_c_tx_n(0), --swapped
    gt_txn_out_1        => mbo_c_tx_p(0), --swapped
    restart_tx_rx_1     => mbo_c_modprs_tx_n,

    gt_rxp_in_2         => mbo_c_rx_p(6),
    gt_rxn_in_2         => mbo_c_rx_n(6),
    gt_txp_out_2        => mbo_c_tx_p(6),
    gt_txn_out_2        => mbo_c_tx_n(6),
    restart_tx_rx_2     => mbo_c_modprs_rx_n,

    gt_rxp_in_3         => mbo_c_rx_p(7),
    gt_rxn_in_3         => mbo_c_rx_n(7),
    gt_txp_out_3        => mbo_c_tx_p(7),
    gt_txn_out_3        => mbo_c_tx_n(7),
    restart_tx_rx_3     => '0',

    sys_reset           => rst,
    gt_refclk_p         => mbo_c_clk_p(1),
    gt_refclk_n         => mbo_c_clk_n(1),
    dclk                => clk_free_100MHz,

    gt_rxpolarity_0     => '0',
    gt_rxpolarity_1     => '0',
    gt_rxpolarity_2     => '0',
    gt_rxpolarity_3     => '0',
    gt_txpolarity_0     => '1',
    gt_txpolarity_1     => '1',
    gt_txpolarity_2     => '0',
    gt_txpolarity_3     => '0' 
  );

u_mbo_c_221_25g_ethernet_exdes : mbo_c_221_25g_ethernet_exdes
  PORT MAP (
    gt_rxp_in_0         => mbo_c_rx_p(8),
    gt_rxn_in_0         => mbo_c_rx_n(8),
    gt_txp_out_0        => mbo_c_tx_p(8),
    gt_txn_out_0        => mbo_c_tx_n(8),
    restart_tx_rx_0     => mbo_c_int_n,

    gt_rxp_in_1         => mbo_c_rx_p(10),
    gt_rxn_in_1         => mbo_c_rx_n(10),
    gt_txp_out_1        => mbo_c_tx_p(10),
    gt_txn_out_1        => mbo_c_tx_n(10),
    restart_tx_rx_1     => mbo_c_modprs_tx_n,

    gt_rxp_in_2         => mbo_c_rx_p(9),
    gt_rxn_in_2         => mbo_c_rx_n(9),
    gt_txp_out_2        => mbo_c_tx_p(9),
    gt_txn_out_2        => mbo_c_tx_n(9),
    restart_tx_rx_2     => mbo_c_modprs_rx_n,

    gt_rxp_in_3         => mbo_c_rx_p(11),
    gt_rxn_in_3         => mbo_c_rx_n(11),
    gt_txp_out_3        => mbo_c_tx_p(11),
    gt_txn_out_3        => mbo_c_tx_n(11),
    restart_tx_rx_3     => '0',

    sys_reset           => rst,
    gt_refclk_p         => mbo_c_clk_p(2),
    gt_refclk_n         => mbo_c_clk_n(2),
    dclk                => clk_free_100MHz,

    gt_rxpolarity_0     => '0',
    gt_rxpolarity_1     => '0',
    gt_rxpolarity_2     => '0',
    gt_rxpolarity_3     => '0',
    gt_txpolarity_0     => '0',
    gt_txpolarity_1     => '0',
    gt_txpolarity_2     => '0',
    gt_txpolarity_3     => '0' 
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

u_axi_i2c_exdes_0 : axi_i2c_exdes_0
   PORT MAP (
    clk_in1_p => i2c_clk_p(0),
    clk_in1_n => i2c_clk_n(0),
    reset     => rst,
    start     => aux_in_alert,
    scl_io    => aux_in_scl,
    sda_io    => aux_in_sda
);
u_axi_i2c_exdes_1 : axi_i2c_exdes_1
   PORT MAP (
    clk_in1_p => i2c_clk_p(1),
    clk_in1_n => i2c_clk_n(1),
    reset     => rst,
    start     => aux_out_alert,
    scl_io    => aux_out_scl,
    sda_io    => aux_out_sda
);
u_axi_i2c_exdes_2 : axi_i2c_exdes_2
   PORT MAP (
    clk_in1_p => i2c_clk_p(2),
    clk_in1_n => i2c_clk_n(2),
    reset     => rst,
    start     => pmbus_alert,
    scl_io    => pmbus_sdc,
    sda_io    => pmbus_sda
);
u_axi_i2c_exdes_3 : axi_i2c_exdes_3
   PORT MAP (
    clk_in1_p => i2c_clk_p(3),
    clk_in1_n => i2c_clk_n(3),
    reset     => rst,
    start     => pmbus_alert,
    scl_io    => optics_l_scl,
    sda_io    => optics_l_sda
);
optics_l_reset_n <= '0';
u_axi_i2c_exdes_4 : axi_i2c_exdes_4
   PORT MAP (
    clk_in1_p => i2c_clk_p(4),
    clk_in1_n => i2c_clk_n(4),
    reset     => rst,
    start     => pmbus_alert,
    scl_io    => optics_r_scl,
    sda_io    => optics_r_sda
);
optics_r_reset_n <= '0';

END str;

