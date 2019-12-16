LIBRARY IEEE, UNISIM;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE UNISIM.vcomponents.all; -- IBUFDS, OBUFDS, ...

ENTITY gmi_test_25G IS
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
 
--      led_din           : out std_logic;
--      led_dout          : in std_logic;
--      led_cs            : out std_logic;
--      led_sclk          : out std_logic;
 
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
      qsfp_d_rx_n       : in std_logic_vector(3 downto 0)
  );
END gmi_test_25G;

ARCHITECTURE str OF gmi_test_25G IS

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

  SIGNAL pin_last_board  : STD_LOGIC;
  SIGNAL pin_slave       : STD_LOGIC;
  SIGNAL pin_version     : STD_LOGIC_VECTOR(1 downto 0);

  SIGNAL rst             : STD_LOGIC;
--  SIGNAL led_d           : STD_LOGIC;
--  SIGNAL sfp_fault_led   : STD_LOGIC;
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

  rst <= '0';
  qsfp_clock_sel <= '0';




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


u_qsfp_25g_ethernet_exdes_a : qsfp_25g_ethernet_exdes_a
  PORT MAP (
    gt_rxp_in_0         => qsfp_a_rx_p(3),
    gt_rxn_in_0         => qsfp_a_rx_n(3),
    gt_txp_out_0        => qsfp_a_tx_p(3),
    gt_txn_out_0        => qsfp_a_tx_n(3),
    restart_tx_rx_0     => '0',

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
    restart_tx_rx_0     => '0',

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
    restart_tx_rx_0     => '0',

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
    restart_tx_rx_0     => '0',

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
    restart_tx_rx_0     => '0',

    -- 1_119
    gt_rxp_in_1         => mbo_a_rx_p(1),
    gt_rxn_in_1         => mbo_a_rx_n(1),
    gt_txp_out_1        => mbo_a_tx_p(1),
    gt_txn_out_1        => mbo_a_tx_n(1),
    restart_tx_rx_1     => '0',

    -- 2_119
    gt_rxp_in_2         => mbo_a_rx_p(6),
    gt_rxn_in_2         => mbo_a_rx_n(6),
    gt_txp_out_2        => mbo_a_tx_p(6),
    gt_txn_out_2        => mbo_a_tx_n(6),
    restart_tx_rx_2     => '0',

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
    restart_tx_rx_0     => '0',

    -- 1_120
    gt_rxp_in_1         => mbo_a_rx_p(8),
    gt_rxn_in_1         => mbo_a_rx_n(8),
    gt_txp_out_1        => mbo_a_tx_p(8),
    gt_txn_out_1        => mbo_a_tx_n(8),
    restart_tx_rx_1     => '0',

    -- 2_120
    gt_rxp_in_2         => mbo_a_rx_p(11),
    gt_rxn_in_2         => mbo_a_rx_n(11),
    gt_txp_out_2        => mbo_a_tx_p(11),
    gt_txn_out_2        => mbo_a_tx_n(11),
    restart_tx_rx_2     => '0',

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
    restart_tx_rx_0     => '0',

    -- 1_121
    gt_rxp_in_1         => mbo_a_rx_n(7), --swapped
    gt_rxn_in_1         => mbo_a_rx_p(7), --swapped
    gt_txp_out_1        => mbo_a_tx_p(7),
    gt_txn_out_1        => mbo_a_tx_n(7),
    restart_tx_rx_1     => '0',

    -- 2_121
    gt_rxp_in_2         => mbo_a_rx_p(5),
    gt_rxn_in_2         => mbo_a_rx_n(5),
    gt_txp_out_2        => mbo_a_tx_p(5),
    gt_txn_out_2        => mbo_a_tx_n(5),
    restart_tx_rx_2     => '0',

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
    restart_tx_rx_0     => '0',

    gt_rxp_in_1         => mbo_b_rx_p(10),
    gt_rxn_in_1         => mbo_b_rx_n(10),
    gt_txp_out_1        => mbo_b_tx_p(10),
    gt_txn_out_1        => mbo_b_tx_n(10),
    restart_tx_rx_1     => '0',

    gt_rxp_in_2         => mbo_b_rx_p(9),
    gt_rxn_in_2         => mbo_b_rx_n(9),
    gt_txp_out_2        => mbo_b_tx_p(9),
    gt_txn_out_2        => mbo_b_tx_n(9),
    restart_tx_rx_2     => '0',

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
    restart_tx_rx_0     => '0',

    gt_rxp_in_1         => mbo_b_rx_p(6),
    gt_rxn_in_1         => mbo_b_rx_n(6),
    gt_txp_out_1        => mbo_b_tx_p(6),
    gt_txn_out_1        => mbo_b_tx_n(6),
    restart_tx_rx_1     => '0',

    gt_rxp_in_2         => mbo_b_rx_p(5),
    gt_rxn_in_2         => mbo_b_rx_n(5),
    gt_txp_out_2        => mbo_b_tx_p(0),
    gt_txn_out_2        => mbo_b_tx_n(0),
    restart_tx_rx_2     => '0',

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
    restart_tx_rx_0     => '0',

    gt_rxp_in_1         => mbo_b_rx_p(2),
    gt_rxn_in_1         => mbo_b_rx_n(2),
    gt_txp_out_1        => mbo_b_tx_p(2),
    gt_txn_out_1        => mbo_b_tx_n(2),
    restart_tx_rx_1     => '0',

    gt_rxp_in_2         => mbo_b_rx_p(0),
    gt_rxn_in_2         => mbo_b_rx_n(0),
    gt_txp_out_2        => mbo_b_tx_p(5),
    gt_txn_out_2        => mbo_b_tx_n(5),
    restart_tx_rx_2     => '0',

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
    restart_tx_rx_0     => '0',

    gt_rxp_in_1         => mbo_c_rx_p(5),
    gt_rxn_in_1         => mbo_c_rx_n(5),
    gt_txp_out_1        => mbo_c_tx_p(5),
    gt_txn_out_1        => mbo_c_tx_n(5),
    restart_tx_rx_1     => '0',

    gt_rxp_in_2         => mbo_c_rx_p(3),
    gt_rxn_in_2         => mbo_c_rx_n(3),
    gt_txp_out_2        => mbo_c_tx_p(3),
    gt_txn_out_2        => mbo_c_tx_n(3),
    restart_tx_rx_2     => '0',

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
    restart_tx_rx_0     => '0',

    gt_rxp_in_1         => mbo_c_rx_p(0),
    gt_rxn_in_1         => mbo_c_rx_n(0),
    gt_txp_out_1        => mbo_c_tx_n(0), --swapped
    gt_txn_out_1        => mbo_c_tx_p(0), --swapped
    restart_tx_rx_1     => '0',

    gt_rxp_in_2         => mbo_c_rx_p(6),
    gt_rxn_in_2         => mbo_c_rx_n(6),
    gt_txp_out_2        => mbo_c_tx_p(6),
    gt_txn_out_2        => mbo_c_tx_n(6),
    restart_tx_rx_2     => '0',

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
    restart_tx_rx_0     => '0',

    gt_rxp_in_1         => mbo_c_rx_p(10),
    gt_rxn_in_1         => mbo_c_rx_n(10),
    gt_txp_out_1        => mbo_c_tx_p(10),
    gt_txn_out_1        => mbo_c_tx_n(10),
    restart_tx_rx_1     => '0',

    gt_rxp_in_2         => mbo_c_rx_p(9),
    gt_rxn_in_2         => mbo_c_rx_n(9),
    gt_txp_out_2        => mbo_c_tx_p(9),
    gt_txn_out_2        => mbo_c_tx_n(9),
    restart_tx_rx_2     => '0',

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

END str;

