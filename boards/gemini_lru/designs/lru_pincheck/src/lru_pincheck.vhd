-- last modified: 05-01-2017 
-- last modified by Gys
-- sfp_clk_b changed to sfp_clk_c 

library ieee;
library UNISIM;
use ieee.std_logic_1164.all;
use UNISIM.vcomponents.all;

entity lru_pincheck is
   port (
      -- Global clks
      clk_aux_b_p          : in std_logic;                           -- Differential clock input
      clk_aux_b_n          : in std_logic;
      clk_aux_c            : inout std_logic;                        -- Multi-purpose IO to MMBX
      clk_c_p              : in std_logic_vector(4 downto 0);        -- Shared 156.25MHz clock (QSFP & MBO)
      clk_c_n              : in std_logic_vector(4 downto 0);
      clk_d_p              : in std_logic_vector(2 downto 0);        -- variable clock inputs to enable MBO operation at ADC-speed (Shared between MBO connections, see schematic, clk_d)
      clk_d_n              : in std_logic_vector(2 downto 0);
      clk_e_p              : in std_logic;                           -- 125MHz PTP clk
      clk_e_n              : in std_logic;
      clk_f                : in std_logic;                           -- 20MHz PTP clk
      clk_g_p              : in std_logic;                           -- 266.67 Memory reference clock
      clk_g_n              : in std_logic;
      clk_h                : in std_logic;                           -- 20MHz LO clk
      clk_bp_p             : in std_logic;                           -- Clock connection from the backplane connector
      clk_bp_n             : in std_logic;

      -- DDR4 interface
      ddr4_ck_p            : out std_logic_vector (1 downto 0);
      ddr4_ck_n            : out std_logic_vector (1 downto 0);

      ddr4_cke             : out std_logic_vector (1 downto 0);
      ddr4_reset_n         : out std_logic;

      ddr4_a               : out std_logic_vector (13 downto 0);
      ddr4_act_n           : out std_logic;
      ddr4_ba              : out std_logic_vector (1 downto 0);
      ddr4_bg              : out std_logic_vector (1 downto 0);
      ddr4_ras_a16         : out std_logic;
      ddr4_cas_a15         : out std_logic;
      ddr4_we_a14          : out std_logic;
      ddr4_parity          : out std_logic;
      ddr4_cs              : out std_logic_vector (3 downto 0);
      ddr4_odt             : out std_logic_vector (1 downto 0);
      ddr4_alert           : inout std_logic;

      ddr4_dm              : inout std_logic_vector (8 downto 0);
      ddr4_dq              : inout std_logic_vector (63 downto 0);
      ddr4_cb              : inout std_logic_vector (7 downto 0);
      ddr4_dqs_p           : inout std_logic_vector (8 downto 0);
      ddr4_dqs_n           : inout std_logic_vector (8 downto 0);

      -- DDR4 SPD Interface
      ddr4_scl             : out std_logic;
      ddr4_sda             : inout std_logic;
      ddr4_event_n         : inout std_logic;

      -- MBO
      mbo_a_clk_p          : in std_logic_vector(2 downto 0);        -- 161.13MHz reference (clk_b & clk_a)
      mbo_a_clk_n          : in std_logic_vector(2 downto 0);
      mbo_a_tx_p           : out std_logic_vector(11 downto 0);
      mbo_a_tx_n           : out std_logic_vector(11 downto 0);
      mbo_a_rx_p           : in std_logic_vector(11 downto 0);
      mbo_a_rx_n           : in std_logic_vector(11 downto 0);
      mbo_a_reset          : out std_logic;                          -- LVCMOS 1.8V

      mbo_b_clk_p          : in std_logic_vector(2 downto 0);        -- 161.13MHz reference (clk_a)
      mbo_b_clk_n          : in std_logic_vector(2 downto 0);
      mbo_b_tx_p           : out std_logic_vector(11 downto 0);
      mbo_b_tx_n           : out std_logic_vector(11 downto 0);
      mbo_b_rx_p           : in std_logic_vector(11 downto 0);
      mbo_b_rx_n           : in std_logic_vector(11 downto 0);
      mbo_b_reset          : out std_logic;                          -- LVCMOS 1.8V

      mbo_c_clk_p          : in std_logic_vector(2 downto 0);        -- 161.13MHz reference (clk_a)
      mbo_c_clk_n          : in std_logic_vector(2 downto 0);
      mbo_c_tx_p           : out std_logic_vector(11 downto 0);
      mbo_c_tx_n           : out std_logic_vector(11 downto 0);
      mbo_c_rx_p           : in std_logic_vector(11 downto 0);
      mbo_c_rx_n           : in std_logic_vector(11 downto 0);
      mbo_c_reset          : out std_logic;                          -- LVCMOS 1.8V

      mbo_int_n            : in std_logic;
      mbo_sda              : inout std_logic;                        -- OC drive, internal Pullups
      mbo_scl              : out std_logic;                          -- LVCMOS 1.8V

      -- QSFP
      qsfp_a_mod_prs_n     : in std_logic;
      qsfp_a_mod_sel       : in std_logic;
      qsfp_a_reset         : out std_logic;
      qsfp_a_led           : out std_logic;
      qsfp_a_clk_p         : in std_logic;                           -- 161.13MHz reference
      qsfp_a_clk_n         : in std_logic;
      qsfp_a_tx_p          : out std_logic_vector(3 downto 0);
      qsfp_a_tx_n          : out std_logic_vector(3 downto 0);
      qsfp_a_rx_p          : in std_logic_vector(3 downto 0);
      qsfp_a_rx_n          : in std_logic_vector(3 downto 0);

      qsfp_b_mod_prs_n     : in std_logic;
      qsfp_b_mod_sel       : in std_logic;
      qsfp_b_reset         : out std_logic;
      qsfp_b_led           : out std_logic;
      qsfp_b_clk_p         : in std_logic;                           -- 161.13MHz reference
      qsfp_b_clk_n         : in std_logic;
      qsfp_b_tx_p          : out std_logic_vector(3 downto 0);
      qsfp_b_tx_n          : out std_logic_vector(3 downto 0);
      qsfp_b_rx_p          : in std_logic_vector(3 downto 0);
      qsfp_b_rx_n          : in std_logic_vector(3 downto 0);

      qsfp_c_mod_prs_n     : in std_logic;
      qsfp_c_mod_sel       : in std_logic;
      qsfp_c_reset         : out std_logic;
      qsfp_c_led           : out std_logic;
      qsfp_c_clk_p         : in std_logic;                           -- 161.13MHz reference
      qsfp_c_clk_n         : in std_logic;
      qsfp_c_tx_p          : out std_logic_vector(3 downto 0);
      qsfp_c_tx_n          : out std_logic_vector(3 downto 0);
      qsfp_c_rx_p          : in std_logic_vector(3 downto 0);
      qsfp_c_rx_n          : in std_logic_vector(3 downto 0);

      qsfp_d_mod_prs_n     : in std_logic;
      qsfp_d_mod_sel       : in std_logic;
      qsfp_d_reset         : out std_logic;
      qsfp_d_led           : out std_logic;
      qsfp_d_clk_p         : in std_logic;                           -- 161.13MHz reference
      qsfp_d_clk_n         : in std_logic;
      qsfp_d_tx_p          : out std_logic_vector(3 downto 0);
      qsfp_d_tx_n          : out std_logic_vector(3 downto 0);
      qsfp_d_rx_p          : in std_logic_vector(3 downto 0);
      qsfp_d_rx_n          : in std_logic_vector(3 downto 0);

      qsfp_int_n           : in std_logic;
      qsfp_sda             : inout std_logic;                        -- OC drive, internal Pullups
      qsfp_scl             : out std_logic;                          -- LVCMOS 1.8V

      -- SFP
      sfp_sda              : inout std_logic;                        -- OC drive, internal Pullups
      sfp_scl              : out std_logic;                          -- LVCMOS 1.8V      
      sfp_fault            : in std_logic;
      sfp_tx_enable        : out std_logic;
      sfp_mod_abs          : in std_logic;
      sfp_led              : out std_logic;

      sfp_clk_c_p          : in std_logic;                           -- 156.25MHz reference
      sfp_clk_c_n          : in std_logic;
      sfp_clk_e_p          : in std_logic;                           -- 125MHz reference (PTP)
      sfp_clk_e_n          : in std_logic;
      sfp_tx_p             : out std_logic;
      sfp_tx_n             : out std_logic;
      sfp_rx_p             : in std_logic;
      sfp_rx_n             : in std_logic;

      -- Backplane Connector I/O
      bp_id                : inout std_logic;                        -- 1-wire interface to the EEPROM on the backplane
      bp_id_pullup         : out std_logic;                          -- Strong pullup enable

      bp_power_scl         : out std_logic;                          -- Power control clock
      bp_power_sda         : inout std_logic;                        -- Power control data
      
      bp_aux_io_p          : inout std_logic_vector(1 downto 0);
      bp_aux_io_n          : inout std_logic_vector(1 downto 0);

      -- Power Interface
      power_sda            : inout std_logic;                        -- OC drive, internal Pullups
      power_sdc            : out std_logic;                          -- LVCMOS 1.8V
      power_alert_n        : in std_logic;
      
      shutdown             : out std_logic;                          -- Assert to latch power off

      -- Configuration IO
      spi_d                : inout std_logic_vector(7 downto 4);    -- Other IO through startup block
      --spi_c                : out std_logic;                       -- Through startup block
      --spi_cs               : out std_logic_vector(1 downto 1);      -- Other IO through startup block

      -- PTP
      ptp_pll_reset        : out std_logic;                          -- PLL reset
      ptp_clk_sel          : out std_logic;                          -- PTP Interface
      ptp_sync_n           : out std_logic_vector(1 downto 0);
      ptp_sclk             : out std_logic;
      ptp_din              : out std_logic;

      -- Misc IO
      led_din              : out std_logic;                          -- SPI Led Interface
      led_dout             : in std_logic;
      led_cs               : out std_logic;
      led_sclk             : out std_logic;

      serial_id            : inout std_logic;                        -- Onboard serial number PROM & MAC ID
      serial_id_pullup     : out std_logic;

      hum_sda              : inout std_logic;                        -- Humidity & temperature chip
      hum_sdc              : out std_logic;

      debug                : inout std_logic_vector(3 downto 0);     -- General debug IOs
      version              : in std_logic_vector (1 downto 0));
end lru_pincheck;

architecture structure of lru_pincheck is

COMPONENT ddr4_0
  PORT (
    c0_init_calib_complete : OUT STD_LOGIC;
    dbg_clk : OUT STD_LOGIC;
    c0_sys_clk_p : IN STD_LOGIC;
    c0_sys_clk_n : IN STD_LOGIC;
    dbg_bus : OUT STD_LOGIC_VECTOR(511 DOWNTO 0);
    c0_ddr4_adr : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    c0_ddr4_ba : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    c0_ddr4_cke : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    c0_ddr4_cs_n : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    c0_ddr4_dm_dbi_n : INOUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    c0_ddr4_dq : INOUT STD_LOGIC_VECTOR(71 DOWNTO 0);
    c0_ddr4_dqs_c : INOUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    c0_ddr4_dqs_t : INOUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    c0_ddr4_odt : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    c0_ddr4_bg : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    c0_ddr4_reset_n : OUT STD_LOGIC;
    c0_ddr4_act_n : OUT STD_LOGIC;
    c0_ddr4_ck_c : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    c0_ddr4_ck_t : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    c0_ddr4_ui_clk : OUT STD_LOGIC;
    c0_ddr4_ui_clk_sync_rst : OUT STD_LOGIC;
    c0_ddr4_app_en : IN STD_LOGIC;
    c0_ddr4_app_hi_pri : IN STD_LOGIC;
    c0_ddr4_app_wdf_end : IN STD_LOGIC;
    c0_ddr4_app_wdf_wren : IN STD_LOGIC;
    c0_ddr4_app_rd_data_end : OUT STD_LOGIC;
    c0_ddr4_app_rd_data_valid : OUT STD_LOGIC;
    c0_ddr4_app_rdy : OUT STD_LOGIC;
    c0_ddr4_app_wdf_rdy : OUT STD_LOGIC;
    c0_ddr4_app_addr : IN STD_LOGIC_VECTOR(29 DOWNTO 0);
    c0_ddr4_app_cmd : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    c0_ddr4_app_wdf_data : IN STD_LOGIC_VECTOR(575 DOWNTO 0);
    c0_ddr4_app_wdf_mask : IN STD_LOGIC_VECTOR(71 DOWNTO 0);
    c0_ddr4_app_rd_data : OUT STD_LOGIC_VECTOR(575 DOWNTO 0);
    c0_ddr4_app_sref_req : IN STD_LOGIC;
    c0_ddr4_app_sref_ack : OUT STD_LOGIC;
    c0_ddr4_app_restore_en : IN STD_LOGIC;
    c0_ddr4_app_restore_complete : IN STD_LOGIC;
    c0_ddr4_app_mem_init_skip : IN STD_LOGIC;
    c0_ddr4_app_xsdb_select : IN STD_LOGIC;
    c0_ddr4_app_xsdb_rd_en : IN STD_LOGIC;
    c0_ddr4_app_xsdb_wr_en : IN STD_LOGIC;
    c0_ddr4_app_xsdb_addr : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    c0_ddr4_app_xsdb_wr_data : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    c0_ddr4_app_xsdb_rd_data : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    c0_ddr4_app_xsdb_rdy : OUT STD_LOGIC;
    c0_ddr4_app_dbg_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    sys_rst : IN STD_LOGIC
  );
END COMPONENT;

COMPONENT mbo
  PORT (
    gtwiz_userclk_tx_active_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_rx_active_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_clk_freerun_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_all_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_tx_pll_and_datapath_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_tx_datapath_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_pll_and_datapath_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_datapath_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_cdr_stable_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_tx_done_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_done_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userdata_tx_in : IN STD_LOGIC_VECTOR(2303 DOWNTO 0);
    gtwiz_userdata_rx_out : OUT STD_LOGIC_VECTOR(2303 DOWNTO 0);
    gtrefclk00_in : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    qpll0outclk_out : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    qpll0outrefclk_out : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    gtyrxn_in : IN STD_LOGIC_VECTOR(35 DOWNTO 0);
    gtyrxp_in : IN STD_LOGIC_VECTOR(35 DOWNTO 0);
    rxusrclk_in : IN STD_LOGIC_VECTOR(35 DOWNTO 0);
    rxusrclk2_in : IN STD_LOGIC_VECTOR(35 DOWNTO 0);
    txusrclk_in : IN STD_LOGIC_VECTOR(35 DOWNTO 0);
    txusrclk2_in : IN STD_LOGIC_VECTOR(35 DOWNTO 0);
    gtytxn_out : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    gtytxp_out : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    rxoutclk_out : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    rxpmaresetdone_out : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    txoutclk_out : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    txpmaresetdone_out : OUT STD_LOGIC_VECTOR(35 DOWNTO 0)
  );
END COMPONENT;

COMPONENT qsfp
  PORT (
    gtwiz_userclk_tx_active_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_rx_active_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_clk_freerun_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_all_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_tx_pll_and_datapath_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_tx_datapath_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_pll_and_datapath_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_datapath_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_cdr_stable_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_tx_done_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_done_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userdata_tx_in : IN STD_LOGIC_VECTOR(1087 DOWNTO 0);
    gtwiz_userdata_rx_out : OUT STD_LOGIC_VECTOR(1087 DOWNTO 0);
    gtrefclk00_in : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    qpll0outclk_out : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
    qpll0outrefclk_out : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
    gtyrxn_in : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    gtyrxp_in : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    rxusrclk_in : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    rxusrclk2_in : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    txusrclk_in : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    txusrclk2_in : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    gtytxn_out : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    gtytxp_out : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    rxoutclk_out : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    rxpmaresetdone_out : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    txoutclk_out : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    txpmaresetdone_out : OUT STD_LOGIC_VECTOR(16 DOWNTO 0)
  );
END COMPONENT;

    signal gnd      : std_logic_vector(4095 downto 0);

    signal sig_mem_done : std_logic;
    signal c0_ddr4_app_rd_data_end : std_logic;
    signal c0_ddr4_app_rd_data_valid : std_logic;
    signal c0_ddr4_app_rdy : std_logic;
    
    signal c0_ddr4_adr : std_logic_vector(16 downto 0);
    signal c0_ddr4_dm_dbi_n : std_logic_vector(7 downto 0);
    signal c0_ddr4_dqs_c : std_logic_vector(7 downto 0);
    signal c0_ddr4_dqs_t : std_logic_vector(7 downto 0);

    signal gtytxn_out : std_logic_vector(35 downto 0);
    signal gtytxp_out : std_logic_vector(35 downto 0);
    signal gtyrxn_in : std_logic_vector(35 downto 0);
    signal gtyrxp_in : std_logic_vector(35 downto 0);

    signal qsfp_gtytxn_out : std_logic_vector(16 downto 0);
    signal qsfp_gtytxp_out : std_logic_vector(16 downto 0);
    signal qsfp_gtyrxn_in : std_logic_vector(16 downto 0);
    signal qsfp_gtyrxp_in : std_logic_vector(16 downto 0);

    signal sig_mbo_a_clk : std_logic_vector(2 downto 0);
    signal sig_mbo_b_clk : std_logic_vector(2 downto 0);
    signal sig_mbo_c_clk : std_logic_vector(2 downto 0);
    signal sig_sfp_clk_c : std_logic;
    signal sig_qsfp_a_clk : std_logic;
    signal sig_qsfp_b_clk : std_logic;
    signal sig_qsfp_c_clk : std_logic;
    signal sig_qsfp_d_clk : std_logic;

    signal gtrefclk00_in : std_logic_vector(8 downto 0);
    signal qsfp_gtrefclk00_in : std_logic_vector(4 downto 0);
    
    signal txusrclk_in : std_logic_vector(35 downto 0);
    signal rxusrclk_in : std_logic_vector(35 downto 0);

begin

    gnd <= (others => '0');


    clk_aux_b : IBUFDS port map (O => open, I => clk_aux_b_p, IB => clk_aux_b_n);
    clk_e : IBUFDS port map (O => open, I => clk_e_p, IB => clk_e_n);
    clk_bp : IBUFDS port map (O => open, I => clk_bp_p, IB => clk_bp_n);

    clk_c_gen: for i in 0 to 4 generate
        mbo_clk_c : IBUFDS_GTE4 port map (O => open, ODIV2 => open,
                                          CEB => '1',
                                          I => clk_c_p(i), IB => clk_c_n(i));
    end generate;

    clk_d_gen: for i in 0 to 2 generate
        mbo_clk_d : IBUFDS_GTE4 port map (O => open, ODIV2 => open,
                                          CEB => '1',
                                          I => clk_d_p(i), IB => clk_d_n(i));
    end generate;

    mbo_a_clk_gen: for i in 0 to 2 generate
        mbo_a_clk : IBUFDS_GTE4 port map (O => sig_mbo_a_clk(i), ODIV2 => open,
                                          CEB => '1',
                                          I => mbo_a_clk_p(i), IB => mbo_a_clk_n(i));
    end generate;

    mbo_b_clk_gen: for i in 0 to 2 generate
        mbo_b_clk : IBUFDS_GTE4 port map (O => sig_mbo_b_clk(i), ODIV2 => open,
                                          CEB => '1',
                                          I => mbo_b_clk_p(i), IB => mbo_b_clk_n(i));
    end generate;

    mbo_c_clk_gen: for i in 0 to 2 generate
        mbo_c_clk : IBUFDS_GTE4 port map (O => sig_mbo_c_clk(i), ODIV2 => open,
                                          CEB => '1',
                                          I => mbo_c_clk_p(i), IB => mbo_c_clk_n(i));
    end generate;


    bp_aux_io_gen: for i in 0 to 1 generate
        bp_aux_io : IOBUFDS port map (O => open, I => '0',
                                      IO => bp_aux_io_p(i), IOB => bp_aux_io_n(i),
                                      T => '0');
    end generate;

    sfp_clk_c : IBUFDS_GTE4 port map (O => sig_sfp_clk_c, ODIV2 => open,
                                      CEB => '1',
                                      I => sfp_clk_c_p, IB => sfp_clk_c_n);

    sfp_clk_e : IBUFDS_GTE4 port map (O => open, ODIV2 => open,
                                      CEB => '1',
                                      I => sfp_clk_e_p, IB => sfp_clk_e_n);


    qsfp_a_clk : IBUFDS_GTE4 port map (O => sig_qsfp_a_clk, ODIV2 => open,
                                      CEB => '1',
                                      I => qsfp_a_clk_p, IB => qsfp_a_clk_n);

    qsfp_b_clk : IBUFDS_GTE4 port map (O => sig_qsfp_b_clk, ODIV2 => open,
                                      CEB => '1',
                                      I => qsfp_b_clk_p, IB => qsfp_b_clk_n);

    qsfp_c_clk : IBUFDS_GTE4 port map (O => sig_qsfp_c_clk, ODIV2 => open,
                                      CEB => '1',
                                      I => qsfp_c_clk_p, IB => qsfp_c_clk_n);

    qsfp_d_clk : IBUFDS_GTE4 port map (O => sig_qsfp_d_clk, ODIV2 => open,
                                      CEB => '1',
                                      I => qsfp_d_clk_p, IB => qsfp_d_clk_n);


      --mbo_a_tx_p           : out std_logic_vector(11 downto 0);
      --mbo_a_tx_n           : out std_logic_vector(11 downto 0);
      --mbo_a_rx_p           : in std_logic_vector(11 downto 0);
      --mbo_a_rx_n           : in std_logic_vector(11 downto 0);
      --mbo_b_tx_p           : out std_logic_vector(11 downto 0);
      --mbo_b_tx_n           : out std_logic_vector(11 downto 0);
      --mbo_b_rx_p           : in std_logic_vector(11 downto 0);
      --mbo_b_rx_n           : in std_logic_vector(11 downto 0);
      --mbo_c_tx_p           : out std_logic_vector(11 downto 0);
      --mbo_c_tx_n           : out std_logic_vector(11 downto 0);
      --mbo_c_rx_p           : in std_logic_vector(11 downto 0);
      --mbo_c_rx_n           : in std_logic_vector(11 downto 0);
      --qsfp_a_tx_p          : out std_logic_vector(3 downto 0);
      --          : out std_logic_vector(3 downto 0);
      --          : in std_logic_vector(3 downto 0);
      --qsfp_a_rx_n          : in std_logic_vector(3 downto 0);

      --qsfp_b_tx_p          : out std_logic_vector(3 downto 0);
      --qsfp_b_tx_n          : out std_logic_vector(3 downto 0);
      --qsfp_b_rx_p          : in std_logic_vector(3 downto 0);
      --qsfp_b_rx_n          : in std_logic_vector(3 downto 0);

      --qsfp_c_tx_p          : out std_logic_vector(3 downto 0);
      --qsfp_c_tx_n          : out std_logic_vector(3 downto 0);
      --qsfp_c_rx_p          : in std_logic_vector(3 downto 0);
      --qsfp_c_rx_n          : in std_logic_vector(3 downto 0);

      --qsfp_d_tx_p          : out std_logic_vector(3 downto 0);
      --qsfp_d_tx_n          : out std_logic_vector(3 downto 0);
      --qsfp_d_rx_p          : in std_logic_vector(3 downto 0);
      --qsfp_d_rx_n          : in std_logic_vector(3 downto 0);
      --sfp_tx_p             : out std_logic;
      --sfp_tx_n             : out std_logic;
      --sfp_rx_p             : in std_logic;
      --sfp_rx_n             : in std_logic;



      


--      debug                : inout std_logic_vector(3 downto 0);     -- General debug IOs
















    ptp_clk_sel <= sig_mem_done or c0_ddr4_app_rd_data_end or c0_ddr4_app_rd_data_valid or c0_ddr4_app_rdy;

    gtyrxn_in <=  mbo_a_rx_n(4) & mbo_a_rx_n(6) & mbo_a_rx_n(8) & mbo_a_rx_n(10) & mbo_a_rx_n(9) & mbo_a_rx_n(11) & mbo_a_rx_n(7) & mbo_a_rx_n(0) & mbo_a_rx_n(2) &  mbo_a_rx_n(1) & mbo_a_rx_n(3) & mbo_a_rx_n(5) &
                  mbo_b_rx_n(10) & mbo_b_rx_n(8) & mbo_b_rx_n(9) & mbo_b_rx_n(6) & mbo_b_rx_n(7) & mbo_b_rx_n(2) & mbo_b_rx_n(11) & mbo_b_rx_n(0) & mbo_b_rx_n(4) &  mbo_b_rx_n(1) & mbo_b_rx_n(3) & mbo_b_rx_n(5) &
                  mbo_c_rx_n(10) & mbo_c_rx_n(6) & mbo_c_rx_n(7) & mbo_c_rx_n(4) & mbo_c_rx_n(0) & mbo_c_rx_n(9) & mbo_c_rx_n(2) & mbo_c_rx_n(1) & mbo_c_rx_n(3) &  mbo_c_rx_n(11) & mbo_c_rx_n(8) & mbo_c_rx_n(5);
                  
    gtyrxp_in <=  mbo_a_rx_p(4) & mbo_a_rx_p(6) & mbo_a_rx_p(8) & mbo_a_rx_p(10) & mbo_a_rx_p(9) & mbo_a_rx_p(11) & mbo_a_rx_p(7) & mbo_a_rx_p(0) & mbo_a_rx_p(2) &  mbo_a_rx_p(1) & mbo_a_rx_p(3) & mbo_a_rx_p(5) &
                  mbo_b_rx_p(10) & mbo_b_rx_p(8) & mbo_b_rx_p(9) & mbo_b_rx_p(6) & mbo_b_rx_p(7) & mbo_b_rx_p(2) & mbo_b_rx_p(11) & mbo_b_rx_p(0) & mbo_b_rx_p(4) &  mbo_b_rx_p(1) & mbo_b_rx_p(3) & mbo_b_rx_p(5) &
                  mbo_c_rx_p(10) & mbo_c_rx_p(6) & mbo_c_rx_p(7) & mbo_c_rx_p(4) & mbo_c_rx_p(0) & mbo_c_rx_p(9) & mbo_c_rx_p(2) & mbo_c_rx_p(1) & mbo_c_rx_p(3) &  mbo_c_rx_p(11) & mbo_c_rx_p(8) & mbo_c_rx_p(5);

    mbo_a_tx_n(11) <= gtytxn_out(35);
    mbo_a_tx_n(10) <= gtytxn_out(34);
    mbo_a_tx_n(9) <= gtytxn_out(33);
    mbo_a_tx_n(7) <= gtytxn_out(32);
    mbo_a_tx_n(3) <= gtytxn_out(31);
    mbo_a_tx_n(5) <= gtytxn_out(30);
    mbo_a_tx_n(1) <= gtytxn_out(29);
    mbo_a_tx_n(0) <= gtytxn_out(28);
    mbo_a_tx_n(6) <= gtytxn_out(27);
    mbo_a_tx_n(2) <= gtytxn_out(26);
    mbo_a_tx_n(4) <= gtytxn_out(25);
    mbo_a_tx_n(8) <= gtytxn_out(24);
    mbo_b_tx_n(1) <= gtytxn_out(23);
    mbo_b_tx_n(2) <= gtytxn_out(22);
    mbo_b_tx_n(0) <= gtytxn_out(21);
    mbo_b_tx_n(10) <= gtytxn_out(20);
    mbo_b_tx_n(9) <= gtytxn_out(19);
    mbo_b_tx_n(5) <= gtytxn_out(18);
    mbo_b_tx_n(3) <= gtytxn_out(17);
    mbo_b_tx_n(7) <= gtytxn_out(16);
    mbo_b_tx_n(4) <= gtytxn_out(15);
    mbo_b_tx_n(6) <= gtytxn_out(14);
    mbo_b_tx_n(8) <= gtytxn_out(13);
    mbo_b_tx_n(11) <= gtytxn_out(12);
    mbo_c_tx_n(1) <= gtytxn_out(11);   
    mbo_c_tx_n(2) <= gtytxn_out(10);
    mbo_c_tx_n(0) <= gtytxn_out(9);
    mbo_c_tx_n(10) <= gtytxn_out(8);
    mbo_c_tx_n(5) <= gtytxn_out(7);
    mbo_c_tx_n(7) <= gtytxn_out(6);
    mbo_c_tx_n(4) <= gtytxn_out(5);
    mbo_c_tx_n(3) <= gtytxn_out(4);
    mbo_c_tx_n(6) <= gtytxn_out(3);
    mbo_c_tx_n(9) <= gtytxn_out(2);
    mbo_c_tx_n(8) <= gtytxn_out(1);
    mbo_c_tx_n(11) <= gtytxn_out(0);

    mbo_a_tx_p(11) <= gtytxp_out(35);
    mbo_a_tx_p(10) <= gtytxp_out(34);
    mbo_a_tx_p(9) <= gtytxp_out(33);
    mbo_a_tx_p(7) <= gtytxp_out(32);
    mbo_a_tx_p(3) <= gtytxp_out(31);
    mbo_a_tx_p(5) <= gtytxp_out(30);
    mbo_a_tx_p(1) <= gtytxp_out(29);
    mbo_a_tx_p(0) <= gtytxp_out(28);
    mbo_a_tx_p(6) <= gtytxp_out(27);
    mbo_a_tx_p(2) <= gtytxp_out(26);
    mbo_a_tx_p(4) <= gtytxp_out(25);
    mbo_a_tx_p(8) <= gtytxp_out(24);
    mbo_b_tx_p(1) <= gtytxp_out(23);
    mbo_b_tx_p(2) <= gtytxp_out(22);
    mbo_b_tx_p(0) <= gtytxp_out(21);
    mbo_b_tx_p(10) <= gtytxp_out(20);
    mbo_b_tx_p(9) <= gtytxp_out(19);
    mbo_b_tx_p(5) <= gtytxp_out(18);
    mbo_b_tx_p(3) <= gtytxp_out(17);
    mbo_b_tx_p(7) <= gtytxp_out(16);
    mbo_b_tx_p(4) <= gtytxp_out(15);
    mbo_b_tx_p(6) <= gtytxp_out(14);
    mbo_b_tx_p(8) <= gtytxp_out(13);
    mbo_b_tx_p(11) <= gtytxp_out(12);
    mbo_c_tx_p(1) <= gtytxp_out(11);   
    mbo_c_tx_p(2) <= gtytxp_out(10);
    mbo_c_tx_p(0) <= gtytxp_out(9);
    mbo_c_tx_p(10) <= gtytxp_out(8);
    mbo_c_tx_p(5) <= gtytxp_out(7);
    mbo_c_tx_p(7) <= gtytxp_out(6);
    mbo_c_tx_p(4) <= gtytxp_out(5);
    mbo_c_tx_p(3) <= gtytxp_out(4);
    mbo_c_tx_p(6) <= gtytxp_out(3);
    mbo_c_tx_p(9) <= gtytxp_out(2);
    mbo_c_tx_p(8) <= gtytxp_out(1);
    mbo_c_tx_p(11) <= gtytxp_out(0);
    
    gtrefclk00_in(0) <= sig_mbo_c_clk(0);
    gtrefclk00_in(1) <= sig_mbo_c_clk(1);
    gtrefclk00_in(2) <= sig_mbo_c_clk(2);
    gtrefclk00_in(3) <= sig_mbo_b_clk(0);
    gtrefclk00_in(4) <= sig_mbo_b_clk(1);
    gtrefclk00_in(5) <= sig_mbo_b_clk(2);
    gtrefclk00_in(6) <= sig_mbo_a_clk(0);
    gtrefclk00_in(7) <= sig_mbo_a_clk(1);
    gtrefclk00_in(8) <= sig_mbo_a_clk(2);

    rxusrclk_in <= (others => clk_f);
    txusrclk_in <= (others => clk_f);

u_mbo: mbo PORT MAP (gtwiz_userclk_tx_active_in => "1",
                                      gtwiz_userclk_rx_active_in => "1",
                                      gtwiz_reset_clk_freerun_in => "0",
                                      gtwiz_reset_all_in => "0",
                                      gtwiz_reset_tx_pll_and_datapath_in => "0",
                                      gtwiz_reset_tx_datapath_in => "0",
                                      gtwiz_reset_rx_pll_and_datapath_in => "0",
                                      gtwiz_reset_rx_datapath_in => "0",
                                      gtwiz_reset_rx_cdr_stable_out => open,
                                      gtwiz_reset_tx_done_out => open,
                                      gtwiz_reset_rx_done_out => open,
                                      gtwiz_userdata_tx_in => gnd(2303 downto 0),
                                      gtwiz_userdata_rx_out => open,
                                      gtrefclk00_in => gtrefclk00_in,
                                      qpll0outclk_out => open,
                                      qpll0outrefclk_out => open,
                                      gtyrxn_in => gtyrxn_in,
                                      gtyrxp_in => gtyrxp_in,
                                      rxusrclk_in => rxusrclk_in,
                                      rxusrclk2_in => X"000000000",
                                      txusrclk_in => txusrclk_in,
                                      txusrclk2_in => X"000000000",
                                      gtytxn_out => gtytxn_out,
                                      gtytxp_out => gtytxp_out,
                                      rxoutclk_out => open,
                                      rxpmaresetdone_out => open,
                                      txoutclk_out => open,
                                      txpmaresetdone_out => open);

qsfp_gtyrxn_in <= qsfp_a_rx_n(0) & qsfp_a_rx_n(1) & qsfp_a_rx_n(2) & qsfp_a_rx_n(3) &
                  qsfp_b_rx_n(0) & qsfp_b_rx_n(1) & qsfp_b_rx_n(2) & qsfp_b_rx_n(3) &
                  qsfp_c_rx_n(0) & qsfp_c_rx_n(1) & qsfp_c_rx_n(2) & qsfp_c_rx_n(3) &
                  qsfp_d_rx_n(0) & qsfp_d_rx_n(1) & qsfp_d_rx_n(2) & qsfp_d_rx_n(3) & 
                  sfp_rx_n;

qsfp_gtyrxp_in <= qsfp_a_rx_p(0) & qsfp_a_rx_p(1) & qsfp_a_rx_p(2) & qsfp_a_rx_p(3) &
                  qsfp_b_rx_p(0) & qsfp_b_rx_p(1) & qsfp_b_rx_p(2) & qsfp_b_rx_p(3) &
                  qsfp_c_rx_p(0) & qsfp_c_rx_p(1) & qsfp_c_rx_p(2) & qsfp_c_rx_p(3) &
                  qsfp_d_rx_p(0) & qsfp_d_rx_p(1) & qsfp_d_rx_p(2) & qsfp_d_rx_p(3) &
                  sfp_rx_p;


   

   qsfp_a_tx_n(3) <= qsfp_gtytxn_out(16);
   qsfp_a_tx_n(2) <= qsfp_gtytxn_out(15);
   qsfp_a_tx_n(0) <= qsfp_gtytxn_out(14);
   qsfp_a_tx_n(1) <= qsfp_gtytxn_out(13);
   qsfp_b_tx_n(3) <= qsfp_gtytxn_out(12);
   qsfp_b_tx_n(2) <= qsfp_gtytxn_out(11);
   qsfp_b_tx_n(0) <= qsfp_gtytxn_out(10);
   qsfp_b_tx_n(1) <= qsfp_gtytxn_out(9);
   qsfp_c_tx_n(3) <= qsfp_gtytxn_out(8);
   qsfp_c_tx_n(2) <= qsfp_gtytxn_out(7);
   qsfp_c_tx_n(0) <= qsfp_gtytxn_out(6);
   qsfp_c_tx_n(1) <= qsfp_gtytxn_out(5);
   qsfp_d_tx_n(3) <= qsfp_gtytxn_out(4);
   qsfp_d_tx_n(2) <= qsfp_gtytxn_out(3);
   qsfp_d_tx_n(0) <= qsfp_gtytxn_out(2);
   qsfp_d_tx_n(1) <= qsfp_gtytxn_out(1);

   sfp_tx_n <= qsfp_gtytxn_out(0);

   qsfp_a_tx_p(3) <= qsfp_gtytxp_out(16);
   qsfp_a_tx_p(2) <= qsfp_gtytxp_out(15);
   qsfp_a_tx_p(0) <= qsfp_gtytxp_out(14);
   qsfp_a_tx_p(1) <= qsfp_gtytxp_out(13);
   qsfp_b_tx_p(3) <= qsfp_gtytxp_out(12);
   qsfp_b_tx_p(2) <= qsfp_gtytxp_out(11);
   qsfp_b_tx_p(0) <= qsfp_gtytxp_out(10);
   qsfp_b_tx_p(1) <= qsfp_gtytxp_out(9);
   qsfp_c_tx_p(3) <= qsfp_gtytxp_out(8);
   qsfp_c_tx_p(2) <= qsfp_gtytxp_out(7);
   qsfp_c_tx_p(0) <= qsfp_gtytxp_out(6);
   qsfp_c_tx_p(1) <= qsfp_gtytxp_out(5);
   qsfp_d_tx_p(3) <= qsfp_gtytxp_out(4);
   qsfp_d_tx_p(2) <= qsfp_gtytxp_out(3);
   qsfp_d_tx_p(0) <= qsfp_gtytxp_out(2);
   qsfp_d_tx_p(1) <= qsfp_gtytxp_out(1);

   sfp_tx_p <= qsfp_gtytxp_out(0);

   
   qsfp_gtrefclk00_in(4) <= sig_qsfp_a_clk;
   qsfp_gtrefclk00_in(3) <= sig_qsfp_b_clk;
   qsfp_gtrefclk00_in(2) <= sig_qsfp_c_clk;
   qsfp_gtrefclk00_in(1) <= sig_qsfp_d_clk;
   qsfp_gtrefclk00_in(0) <= sig_sfp_clk_c;


u_qsfps: qsfp PORT MAP (gtwiz_userclk_tx_active_in => "1",
                        gtwiz_userclk_rx_active_in => "1",
                        gtwiz_reset_clk_freerun_in => "0",
                        gtwiz_reset_all_in => "0",
                        gtwiz_reset_tx_pll_and_datapath_in => "0",
                        gtwiz_reset_tx_datapath_in => "0",
                        gtwiz_reset_rx_pll_and_datapath_in => "0",
                        gtwiz_reset_rx_datapath_in => "0",
                        gtwiz_reset_rx_cdr_stable_out => open,
                        gtwiz_reset_tx_done_out => open,
                        gtwiz_reset_rx_done_out => open,
                        gtwiz_userdata_tx_in => gnd(1087 downto 0),
                        gtwiz_userdata_rx_out => open,
                        gtrefclk00_in => qsfp_gtrefclk00_in,
                        qpll0outclk_out => open,
                        qpll0outrefclk_out => open,
                        gtyrxn_in => qsfp_gtyrxn_in,
                        gtyrxp_in => qsfp_gtyrxp_in,
                        rxusrclk_in => rxusrclk_in(16 downto 0),
                        rxusrclk2_in => gnd(16 downto 0),
                        txusrclk_in => txusrclk_in(16 downto 0),
                        txusrclk2_in => gnd(16 downto 0),
                        gtytxn_out => qsfp_gtytxn_out,
                        gtytxp_out => qsfp_gtytxp_out,
                        rxoutclk_out => open,
                        rxpmaresetdone_out => open,
                        txoutclk_out => open,
                        txpmaresetdone_out => open);



    ddr4_a <= c0_ddr4_adr(13 downto 0);
    ddr4_we_a14 <= c0_ddr4_adr(14);
    ddr4_cas_a15 <= c0_ddr4_adr(15);
    ddr4_ras_a16 <= c0_ddr4_adr(16);

    ddr4_cs(2 downto 3) <= "00";

u_memory: ddr4_0 PORT MAP (
 c0_init_calib_complete => sig_mem_done,
    dbg_clk => open,
    c0_sys_clk_p => clk_g_p,
    c0_sys_clk_n => clk_g_n,
    dbg_bus => open,
    c0_ddr4_adr => c0_ddr4_adr,
    c0_ddr4_ba => ddr4_ba,
    c0_ddr4_cke => ddr4_cke,
    c0_ddr4_cs_n => ddr4_cs(1 downto 0),
    c0_ddr4_dm_dbi_n => ddr4_dm,
    c0_ddr4_dq(63 downto 0) => ddr4_dq,
    c0_ddr4_dq(71 downto 64) => ddr4_cb,
    c0_ddr4_dqs_c => ddr4_dqs_n,
    c0_ddr4_dqs_t => ddr4_dqs_p,
    c0_ddr4_odt => ddr4_odt,
    c0_ddr4_bg => ddr4_bg,
    c0_ddr4_reset_n => ddr4_reset_n,
    c0_ddr4_act_n => ddr4_act_n,
    c0_ddr4_ck_c => ddr4_ck_n,
    c0_ddr4_ck_t => ddr4_ck_p,
    c0_ddr4_ui_clk => open,
    c0_ddr4_ui_clk_sync_rst => open,
    c0_ddr4_app_en => '0',
    c0_ddr4_app_hi_pri => '0',
    c0_ddr4_app_wdf_end => '0',
    c0_ddr4_app_wdf_wren => '0',
    c0_ddr4_app_rd_data_end => c0_ddr4_app_rd_data_end,
    c0_ddr4_app_rd_data_valid => c0_ddr4_app_rd_data_valid,
    c0_ddr4_app_rdy => c0_ddr4_app_rdy,
    c0_ddr4_app_wdf_rdy => open,
    c0_ddr4_app_addr => "000000000000000000000000000000",
    c0_ddr4_app_cmd => "010",
    c0_ddr4_app_wdf_data => X"000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000",
    c0_ddr4_app_wdf_mask => X"ffffffffffffffffff",
    c0_ddr4_app_rd_data => open,
    c0_ddr4_app_sref_req => '0',
    c0_ddr4_app_sref_ack => open,
    c0_ddr4_app_restore_en => '0',
    c0_ddr4_app_restore_complete => '1',
    c0_ddr4_app_mem_init_skip => '0',
    c0_ddr4_app_xsdb_select => '0',
    c0_ddr4_app_xsdb_rd_en => '0',
    c0_ddr4_app_xsdb_wr_en => '0',
    c0_ddr4_app_xsdb_addr => X"0000",
    c0_ddr4_app_xsdb_wr_data => "000000000",
    c0_ddr4_app_xsdb_rd_data => open,
    c0_ddr4_app_xsdb_rdy => open,
    c0_ddr4_app_dbg_out => open,
    sys_rst => clk_f
  );


end structure;
