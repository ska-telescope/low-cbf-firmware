

library ieee;
use ieee.std_logic_1164.all;

entity gemini_top is
   port (
      -- Global clks
      clk_b_p           : in std_logic;                              -- 156.25MHz system clk
      clk_b_n           : in std_logic; 
      clk_f             : in std_logic;                              -- 20MHz PTP clk
      clk_e_p           : in std_logic;                              -- 125MHz PTP clk
      clk_e_n           : in std_logic; 
      clk_sfp_p         : in std_logic;                              -- Input from second SFP module
      clk_sfp_n         : in std_logic;
      clk_mmbx_p        : in std_logic;                              -- Clock from MMBX connector 
      clk_mmbx_n        : in std_logic;
      
      -- Auxillary IO Connector
      aux_in_sda        : inout std_logic;                           -- To input connector
      aux_in_scl        : out std_logic;
      aux_in_alert      : inout std_logic;
      
      aux_out_sda       : inout std_logic;                           -- To output connector
      aux_out_scl       : in std_logic;
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
      
      qsfp_clock_sel    : out std_logic;                              -- Select crystal or MMBX inptu for QSFP clock
      
      -- Configuration IO
      spi_d             : inout std_logic_vector(7 downto 0);
      spi_c             : out std_logic;
      spi_cs            : out std_logic_vector(1 downto 0);
      
      -- Power Monitor & Control
      pmbus_sda         : inout std_logic;                           -- OC drive, internal Pullups
      pmbus_sdc         : out std_logic;                             -- LVCMOS 1.8V
      pmbus_alert       : in std_logic;
      
      -- HMC Blocks
      hmc_a_clk_p       : in std_logic;                              -- 125MHz reference
      hmc_a_clk_n       : in std_logic;
      hmc_a_tx_p        : out std_logic_vector(15 downto 0);
      hmc_a_tx_n        : out std_logic_vector(15 downto 0);
      hmc_a_rx_p        : in std_logic_vector(15 downto 0);
      hmc_a_rx_n        : in std_logic_vector(15 downto 0);
      hmc_a_ferr_n      : in std_logic;
      hmc_a_p_rst_n     : out std_logic;
      hmc_a_sda         : inout std_logic;                           -- OC drive, internal Pullups
      hmc_a_scl         : out std_logic;                             -- LVCMOS 1.5V
   
      hmc_b_clk_p       : in std_logic;                              -- 125MHz reference
      hmc_b_clk_n       : in std_logic;
      hmc_b_tx_p        : out std_logic_vector(15 downto 0);
      hmc_b_tx_n        : out std_logic_vector(15 downto 0);
      hmc_b_rx_p        : in std_logic_vector(15 downto 0);
      hmc_b_rx_n        : in std_logic_vector(15 downto 0);
      hmc_b_ferr_n      : in std_logic;
      hmc_b_p_rst_n     : out std_logic;
      hmc_b_sda         : inout std_logic;                           -- OC drive, internal Pullups
      hmc_b_scl         : out std_logic;                             -- LVCMOS 1.5V
   
      hmc_c_clk_p       : in std_logic;                              -- 125MHz reference
      hmc_c_clk_n       : in std_logic;
      hmc_c_tx_p        : out std_logic_vector(15 downto 0);
      hmc_c_tx_n        : out std_logic_vector(15 downto 0);
      hmc_c_rx_p        : in std_logic_vector(15 downto 0);
      hmc_c_rx_n        : in std_logic_vector(15 downto 0);
      hmc_c_ferr_n      : in std_logic;
      hmc_c_p_rst_n     : out std_logic;
      hmc_c_sda         : inout std_logic;                           -- OC drive, internal Pullups
      hmc_c_scl         : out std_logic;                             -- LVCMOS 1.5V
   
      hmc_d_clk_p       : in std_logic;                              -- 125MHz reference
      hmc_d_clk_n       : in std_logic;
      hmc_d_tx_p        : out std_logic_vector(15 downto 0);
      hmc_d_tx_n        : out std_logic_vector(15 downto 0);
      hmc_d_rx_p        : in std_logic_vector(15 downto 0);
      hmc_d_rx_n        : in std_logic_vector(15 downto 0);
      hmc_d_ferr_n      : in std_logic;
      hmc_d_p_rst_n     : out std_logic;                             
      hmc_d_sda         : inout std_logic;                           -- OC drive, internal Pullups
      hmc_d_scl         : out std_logic;                             -- LVCMOS 1.5V
      
      -- Optics I2C Busses
      optics_l_sda      : inout std_logic;                           -- OC drive, internal Pullups
      optics_l_scl      : out std_logic;                             -- LVCMOS 1.8V
      optics_l_reset_n  : out std_logic;                             -- LVCMOS 1.8V
      optics_r_sda      : inout std_logic;                           -- OC drive, internal Pullups
      optics_r_scl      : out std_logic;                             -- LVCMOS 1.8V
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
end gemini_top;