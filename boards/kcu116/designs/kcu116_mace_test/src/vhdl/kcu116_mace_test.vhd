-------------------------------------------------------------------------------
--
-- Copyright (C) 2017
-- ASTRON (Netherlands Institute for Radio Astronomy) <http:--www.astron.nl/>
-- JIVE (Joint Institute for VLBI in Europe) <http:--www.jive.nl/>
-- P.O.Box 2, 7990 AA Dwingeloo, The Netherlands
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http:--www.gnu.org/licenses/>.
--
-------------------------------------------------------------------------------

LIBRARY IEEE, UNISIM, common_lib, axi4_lib, kcu116_board_lib, technology_lib, tech_mac_10g_lib, eth_lib, gemini_server_lib, ping_protocol_lib, gemini_subscription_lib, arp_lib, dhcp_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE axi4_lib.axi4_full_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE kcu116_board_lib.kcu116_board_pkg.ALL;
USE tech_mac_10g_lib.tech_mac_10g_component_pkg.ALL;
USE UNISIM.vcomponents.all;



ENTITY kcu116_mace_test IS
  GENERIC (
    g_design_name   : STRING  := "kcu116_mace_test";
    g_design_note   : STRING  := "UNUSED";
    g_technology    : t_technology := c_tech_xcku5p;
    g_sim           : BOOLEAN := FALSE; --Overridden by TB
    g_sim_unb_nr    : NATURAL := 0;
    g_sim_node_nr   : NATURAL := 0;
    g_stamp_date    : NATURAL := 0;  -- Date (YYYYMMDD)
    g_stamp_time    : NATURAL := 0;  -- Time (HHMMSS)
    g_stamp_svn     : NATURAL := 0;  -- SVN revision
    g_factory_image : BOOLEAN := TRUE
  );
  PORT (
    --gt_rxp_in  : in std_logic;
    --gt_rxn_in  : in std_logic;
    --gt_txp_out : out std_logic;
    --gt_txn_out : out std_logic;

    --restart_tx_rx_0     : in  std_logic;
    --rx_gt_locked_led_0  : out std_logic; -- Indicates GT LOCK
    --rx_block_lock_led_0 : out std_logic; -- Indicates Core Block Lock
    completion_status   : out std_logic_vector(4 downto 0);

    --sys_reset   : in std_logic;
    --gt_refclk_p : in std_logic;  -- 156.25 MHz
    --gt_refclk_n : in std_logic;
    --dclk_p      : in std_logic;  -- 125 MHz
    --dclk_n      : in std_logic;

    sysclk_300_clk_n : in STD_LOGIC;
    sysclk_300_clk_p : in STD_LOGIC;
    
    mdio_mdc_mdc : out STD_LOGIC;
    mdio_mdc_mdio_io : inout STD_LOGIC;
    phy_reset_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    reset : in STD_LOGIC;
    rs232_uart_rxd : in STD_LOGIC;
    rs232_uart_txd : out STD_LOGIC;
    sgmii_lvds_rxn : in STD_LOGIC;
    sgmii_lvds_rxp : in STD_LOGIC;
    sgmii_lvds_txn : out STD_LOGIC;
    sgmii_lvds_txp : out STD_LOGIC;
    sgmii_phyclk_clk_n : in STD_LOGIC;
    sgmii_phyclk_clk_p : in STD_LOGIC;
    link_led           : out std_logic_vector(1 downto 0);
    button             : in std_logic_vector(4 downto 0)    
  );
END kcu116_mace_test;

ARCHITECTURE str OF kcu116_mace_test IS

    COMPONENT rx_debug_fifo
    PORT (
        clk : IN STD_LOGIC;
        srst : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        full : OUT STD_LOGIC;
        empty : OUT STD_LOGIC;
        wr_rst_busy : OUT STD_LOGIC;
        rd_rst_busy : OUT STD_LOGIC
    );
    END COMPONENT;
    
    COMPONENT rx_pre_debug_fifo
      PORT (
        srst : IN STD_LOGIC;
        wr_clk : IN STD_LOGIC;
        rd_clk : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
        full : OUT STD_LOGIC;
        empty : OUT STD_LOGIC;
        wr_rst_busy : OUT STD_LOGIC;
        rd_rst_busy : OUT STD_LOGIC
      );
    END COMPONENT;

  COMPONENT rx_axi_interconnect
  PORT (
    ACLK : IN STD_LOGIC;
    ARESETN : IN STD_LOGIC;
    S00_AXIS_ACLK : IN STD_LOGIC;
    S00_AXIS_ARESETN : IN STD_LOGIC;
    S00_AXIS_TVALID : IN STD_LOGIC;
    S00_AXIS_TREADY : OUT STD_LOGIC;
    S00_AXIS_TDATA : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    S00_AXIS_TKEEP : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    S00_AXIS_TLAST : IN STD_LOGIC;
    M00_AXIS_ACLK : IN STD_LOGIC;
    M00_AXIS_ARESETN : IN STD_LOGIC;
    M00_AXIS_TVALID : OUT STD_LOGIC;
    M00_AXIS_TREADY : IN STD_LOGIC;
    M00_AXIS_TDATA : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    M00_AXIS_TKEEP : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    M00_AXIS_TLAST : OUT STD_LOGIC;
    M00_FIFO_DATA_COUNT : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
  END COMPONENT;

  COMPONENT tx_axi_interconnect
  PORT (
    ACLK : IN STD_LOGIC;
    ARESETN : IN STD_LOGIC;
    S00_AXIS_ACLK : IN STD_LOGIC;
    S00_AXIS_ARESETN : IN STD_LOGIC;
    S00_AXIS_TVALID : IN STD_LOGIC;
    S00_AXIS_TREADY : OUT STD_LOGIC;
    S00_AXIS_TDATA : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    S00_AXIS_TKEEP : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    S00_AXIS_TLAST : IN STD_LOGIC;
    M00_AXIS_ACLK : IN STD_LOGIC;
    M00_AXIS_ARESETN : IN STD_LOGIC;
    M00_AXIS_TVALID : OUT STD_LOGIC;
    M00_AXIS_TREADY : IN STD_LOGIC;
    M00_AXIS_TDATA : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    M00_AXIS_TKEEP : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    M00_AXIS_TLAST : OUT STD_LOGIC;
    S00_FIFO_DATA_COUNT : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
  END COMPONENT;


  component phy is
  port (
    sysclk_300_clk_n : in STD_LOGIC;
    sysclk_300_clk_p : in STD_LOGIC;
    rs232_uart_rxd : in STD_LOGIC;
    rs232_uart_txd : out STD_LOGIC;
    sgmii_lvds_rxn : in STD_LOGIC;
    sgmii_lvds_rxp : in STD_LOGIC;
    sgmii_lvds_txn : out STD_LOGIC;
    sgmii_lvds_txp : out STD_LOGIC;
    mdio_mdc_mdc : out STD_LOGIC;
    mdio_mdc_mdio_i : in STD_LOGIC;
    mdio_mdc_mdio_o : out STD_LOGIC;
    mdio_mdc_mdio_t : out STD_LOGIC;
    sgmii_phyclk_clk_n : in STD_LOGIC;
    sgmii_phyclk_clk_p : in STD_LOGIC;
    s_axis_tx_0_tdata : in STD_LOGIC_VECTOR ( 7 downto 0 );
    s_axis_tx_0_tlast : in STD_LOGIC;
    s_axis_tx_0_tready : out STD_LOGIC;
    s_axis_tx_0_tuser : in STD_LOGIC_VECTOR ( 0 to 0 );
    s_axis_tx_0_tvalid : in STD_LOGIC;
    s_axis_pause_0_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
    s_axis_pause_0_tvalid : in STD_LOGIC;
    m_axis_rx_0_tdata : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axis_rx_0_tlast : out STD_LOGIC;
    m_axis_rx_0_tuser : out STD_LOGIC;
    m_axis_rx_0_tvalid : out STD_LOGIC;
    GPIO_0_tri_i : in STD_LOGIC_VECTOR ( 31 downto 0 );
    GPIO2_0_tri_o : out STD_LOGIC_VECTOR ( 31 downto 0 );
    axi_clk : out STD_LOGIC;
    axi_rst_n : out STD_LOGIC_VECTOR ( 0 to 0 );
    reset : in STD_LOGIC;
    phy_reset_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    tx_clk : out STD_LOGIC;
    rx_clk : out STD_LOGIC;
    tx_reset : out STD_LOGIC;
    rx_reset : out STD_LOGIC
  );
  end component phy;

  component IOBUF is
  port (
    I : in STD_LOGIC;
    O : out STD_LOGIC;
    T : in STD_LOGIC;
    IO : inout STD_LOGIC
  );
  end component IOBUF;

  component ip_xcku040_mac10g_noaxi_pkt_gen_mon is
    port (
      gen_clk : IN STD_LOGIC;
      mon_clk : IN STD_LOGIC;
      dclk : IN STD_LOGIC;
      sys_reset : IN STD_LOGIC;
      restart_tx_rx : IN STD_LOGIC;
  
    -- RX Signals
      user_rx_reset : IN STD_LOGIC;
  
    -- RX Stats Signals
      stat_rx_block_lock : IN STD_LOGIC;
  
    -- TX Signals
      user_tx_reset : IN STD_LOGIC;
  
      tx_unfout : IN STD_LOGIC;
      tx_preamblein : OUT STD_LOGIC_VECTOR(55 DOWNTO 0);
  
      rx_gt_locked_led : OUT STD_LOGIC;
      rx_block_lock_led : OUT STD_LOGIC
  );
  end component ip_xcku040_mac10g_noaxi_pkt_gen_mon; 

  -- Firmware version x.y
  CONSTANT c_fw_version      : t_kcu116_board_fw_version := (1, 1);
  CONSTANT c_reset_len       : NATURAL := 4;  -- >= c_meta_delay_len from common_pkg
  CONSTANT c_num_eth_lanes   : INTEGER := 6;
  CONSTANT c_local_ip        : STD_LOGIC_VECTOR(31 DOWNTO 0) := X"0a200102"; -- 10.32.1.2
  CONSTANT c_local_mac       : STD_LOGIC_VECTOR(47 DOWNTO 0) := x"1A2B3C4D5E6F";

  CONSTANT c_arp_priority      : INTEGER := 7;
  CONSTANT c_icmp_priority     : INTEGER := 6;
  CONSTANT c_udp_priority      : INTEGER := 2;
  CONSTANT c_udp_long_priority : INTEGER := 3;
  

  SIGNAL  dclk, gt_refclk : STD_LOGIC;

  SIGNAL tx_clk_out : STD_LOGIC;
  SIGNAL rx_clk_out : STD_LOGIC;

    -- RX Signals  
  SIGNAL  user_rx_reset : STD_LOGIC;

    -- RX Stats Signals
  SIGNAL  stat_rx_block_lock : STD_LOGIC;

    -- TX Signals
  SIGNAL  user_tx_reset : STD_LOGIC;


    -- TX LBUS Signals
  SIGNAL  tx_unfout : STD_LOGIC;
  SIGNAL  tx_preamblein : STD_LOGIC_VECTOR(55 DOWNTO 0);

  SIGNAL rx_block_lock : STD_LOGIC;
  SIGNAL eth_reset : STD_LOGIC;
  SIGNAL eth_reset_n : STD_LOGIC;

  SIGNAL eth_in_siso  : t_axi4_siso;
  SIGNAL eth_in_sosi  : t_axi4_sosi;
  SIGNAL eth_out_sosi : t_axi4_sosi;
  SIGNAL eth_out_siso : t_axi4_siso;
  SIGNAL decoder_out_sosi : t_axi4_sosi_arr(0 TO c_num_eth_lanes-1);
  SIGNAL decoder_out_siso : t_axi4_siso_arr(0 TO c_num_eth_lanes-1);

  SIGNAL framer_in_sosi   : t_axi4_sosi_arr(0 TO c_num_eth_lanes-1);
  SIGNAL framer_in_siso   : t_axi4_siso_arr(0 TO c_num_eth_lanes-1);

  SIGNAL time_in                   : STD_LOGIC_VECTOR(63 DOWNTO 0);
  SIGNAL event_in                  : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL s_axi_mosi                : t_axi4_lite_mosi_arr(0 TO 1);
  SIGNAL s_axi_miso                : t_axi4_lite_miso_arr(0 TO 1);

  -- MAC pause signals
  SIGNAL ctl_rx_pause_ack    : STD_LOGIC_VECTOR(8 DOWNTO 0);
  SIGNAL ctl_rx_pause_enable : STD_LOGIC_VECTOR(8 DOWNTO 0);
  SIGNAL stat_rx_pause_req   : STD_LOGIC_VECTOR(8 DOWNTO 0);

  SIGNAL mm_in : t_axi4_full_miso;
  SIGNAL mm_out : t_axi4_full_mosi;

  SIGNAL tod : STD_LOGIC_VECTOR(13 DOWNTO 0);
  
  SIGNAL vcc : STD_LOGIC_VECTOR(7 DOWNTO 0);
  
  SIGNAL serial_number  : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL ip_address     : STD_LOGIC_VECTOR(31 DOWNTO 0);
  
  signal completion_status_i : std_logic_vector(4 downto 0);
  
  --SIGNAL led0 : STD_LOGIC;
  --SIGNAL led1 : STD_LOGIC;
  --SIGNAL led2 : STD_LOGIC;

  signal mdio_mdc_mdio_i : STD_LOGIC;
  signal mdio_mdc_mdio_o : STD_LOGIC;
  signal mdio_mdc_mdio_t : STD_LOGIC;
  
  signal GPIO1 : std_logic_vector(31 downto 0) := (others => '0');
  signal GPIO2 : std_logic_vector(31 downto 0) := (others => '0');
  
  signal old   : std_logic;
  signal rd_en : std_logic;
  
  signal axi_clk  : std_logic;
  signal axi_rst  : std_logic;
  signal rx_clk   : std_logic;
  signal rx_reset : std_logic;
  signal tx_clk   : std_logic;
  signal tx_reset : std_logic;

  signal axi_rst_n  : std_logic;
  signal rx_reset_n : std_logic;
  signal tx_reset_n : std_logic;

  
  signal rx_data  : std_logic_vector(7 downto 0);
  signal rx_last  : std_logic;
  signal rx_user  : std_logic;
  signal rx_valid : std_logic;

  signal rx_64_valid : std_logic;
  signal rx_64_ready : std_logic;
  signal rx_64_last  : std_logic;
  signal rx_64_data  : std_logic_vector(63 downto 0);
  signal rx_64_keep  : std_logic_vector(7 downto 0);
  
  signal tx_data  : std_logic_vector(7 downto 0);
  signal tx_last  : std_logic;
  signal tx_user  : std_logic;
  signal tx_valid : std_logic;
  signal tx_ready : std_logic;

  signal tx_64_valid : std_logic;
  signal tx_64_ready : std_logic;
  signal tx_64_last  : std_logic;
  signal tx_64_data  : std_logic_vector(63 downto 0);
  signal tx_64_keep  : std_logic_vector(7 downto 0);
  
  signal mem          : std_logic_vector(31 downto 0) := (others => '0');
  signal pre_debug_re : std_logic := '0';
  signal debug_re     : std_logic := '0';

  signal mace_gpio_in  : STD_LOGIC_VECTOR ( 31 downto 0 ) := (others => '0');
  signal mace_gpio_out : STD_LOGIC_VECTOR ( 31 downto 0 ) := (others => '0');


BEGIN
  vcc <= (OTHERS => '1');
  serial_number <= X"00000001"; 
   
  --rx_block_lock_led_0 <= rx_block_lock;
  eth_reset_n <= not axi_rst; --rx_block_lock;
  eth_reset <= axi_rst; --NOT rx_block_lock;

--  u_IBUFDS_dclk_inst : IBUFDS
--   PORT MAP (
--    O => dclk,
--    I => dclk_p,
--    IB=> dclk_n
--  );

  u_ctrl_kcu116_board : ENTITY kcu116_board_lib.ctrl_kcu116_board
  GENERIC MAP (
    g_sim           => g_sim,
    g_technology    => g_technology,
    g_mm_clk_freq   => c_kcu116_board_mm_clk_freq_156M,
    g_design_name   => g_design_name,
    g_stamp_date    => g_stamp_date,
    g_stamp_time    => g_stamp_time,
    g_stamp_svn     => g_stamp_svn,
    g_fw_version    => c_fw_version,
    g_factory_image => g_factory_image
  )
  PORT MAP (
    mm_rst      => eth_reset,
    mm_clk      => rx_clk_out,
    tod         => tod,
    led_in(0)   => decoder_out_sosi(0).tvalid,
    led_in(1)   => decoder_out_sosi(1).tvalid,
    led_in(2)   => decoder_out_sosi(2).tvalid,
    led_in(3)   => decoder_out_sosi(3).tvalid,
    led_in(4)   => decoder_out_sosi(4).tvalid,
    led_out     => completion_status_i
  );

  completion_status <= completion_status_i;




  -------------------------------------------------------------------
  -- MAC
  -------------------------------------------------------------------

    axi_rst    <= not axi_rst_n;
    rx_reset_n <= not rx_reset;
    tx_reset_n <= not tx_reset;


    mdio_mdc_mdio_iobuf: component IOBUF
    port map (
        I => mdio_mdc_mdio_o,
        IO => mdio_mdc_mdio_io,
        O => mdio_mdc_mdio_i,
        T => mdio_mdc_mdio_t
    );

    --GPIO_o <= GPIO2(7 downto 0);
    --GPIO1(27 downto 24) <= GPIO_i;
    
     phy_i: component phy
     port map (
        sysclk_300_clk_n => sysclk_300_clk_n,
        sysclk_300_clk_p => sysclk_300_clk_p,
        GPIO2_0_tri_o(31 downto 0) => GPIO2,
        GPIO_0_tri_i(31 downto 0) => GPIO1,
        axi_clk    => axi_clk,
        axi_rst_n(0) => axi_rst_n,
        m_axis_rx_0_tdata => rx_data,
        m_axis_rx_0_tlast => rx_last,
        m_axis_rx_0_tuser => rx_user,
        m_axis_rx_0_tvalid => rx_valid,
        mdio_mdc_mdc => mdio_mdc_mdc,
        mdio_mdc_mdio_i => mdio_mdc_mdio_i,
        mdio_mdc_mdio_o => mdio_mdc_mdio_o,
        mdio_mdc_mdio_t => mdio_mdc_mdio_t,
        phy_reset_out(0) => phy_reset_out(0),
        reset => reset,
        rs232_uart_rxd => rs232_uart_rxd,
        rs232_uart_txd => rs232_uart_txd,
        s_axis_pause_0_tdata(15 downto 0) => (others => '0'),
        s_axis_pause_0_tvalid             => '0',
        s_axis_tx_0_tdata(7 downto 0)     => tx_data,
        s_axis_tx_0_tlast                 => tx_last,
        s_axis_tx_0_tready                => tx_ready,
        s_axis_tx_0_tuser(0)              => '0',
        s_axis_tx_0_tvalid                => tx_valid,
        sgmii_lvds_rxn => sgmii_lvds_rxn,
        sgmii_lvds_rxp => sgmii_lvds_rxp,
        sgmii_lvds_txn => sgmii_lvds_txn,
        sgmii_lvds_txp => sgmii_lvds_txp,
        sgmii_phyclk_clk_n => sgmii_phyclk_clk_n,
        sgmii_phyclk_clk_p => sgmii_phyclk_clk_p,
        tx_clk   => tx_clk,
        tx_reset => tx_reset,
        rx_clk   => rx_clk,
        rx_reset => rx_reset
    );
    
    --connect PHY clocks to MACE clocks: (representing the CDC FIFOs below)
    dclk       <= axi_clk;
    rx_clk_out <= axi_clk;
    tx_clk_out <= axi_clk;


    rx_pre_debug_fifo_inst : rx_pre_debug_fifo
    PORT MAP (
        wr_clk => rx_clk,  
        rd_clk => axi_clk,
        srst   => axi_rst,
        din(8) => rx_last,
        din(7 downto 0) => rx_data,
        wr_en => rx_valid,
        rd_en => pre_debug_re,
        dout  => GPIO1(20 downto 12),
        full  => GPIO1(21),
        empty => GPIO1(22),
        wr_rst_busy => open,
        rd_rst_busy => open
    );

    P_SINGLE_PULSE_RE: process(axi_clk)
    begin
        if rising_edge(axi_clk) then
            mem <= GPIO2;
            if GPIO2(1)='1' and mem(1)='0' then
                pre_debug_re<='1';
            else
                pre_debug_re<='0';
            end if;        
            if GPIO2(0)='1' and mem(0)='0' then
                debug_re<='1';
            else
                debug_re<='0';
            end if;        
        end if;
    end process;
   
    link_led <= mace_gpio_out(1 downto 0); --GPIO2(9 downto 8);
    GPIO1(28 downto 24) <= button;     
    
    mace_gpio_in <= GPIO1;
      
    rx_axi_interconnect_inst : rx_axi_interconnect
      PORT MAP (
        ACLK             => rx_clk,
        ARESETN          => rx_reset_n,
        S00_AXIS_ACLK    => rx_clk,
        S00_AXIS_ARESETN => rx_reset_n,
        S00_AXIS_TVALID  => rx_valid,
        S00_AXIS_TREADY  => open,
        S00_AXIS_TDATA   => rx_data,
        S00_AXIS_TKEEP(0)=> rx_valid,
        S00_AXIS_TLAST   => rx_last,
        M00_AXIS_ACLK    => axi_clk,
        M00_AXIS_ARESETN => axi_rst_n,
        M00_AXIS_TVALID  => rx_64_valid,
        M00_AXIS_TREADY  => rx_64_ready,
        M00_AXIS_TDATA   => rx_64_data,
        M00_AXIS_TKEEP   => rx_64_keep,
        M00_AXIS_TLAST   => rx_64_last,
        M00_FIFO_DATA_COUNT => open
      );

    eth_in_sosi.tvalid              <= rx_64_valid;
    eth_in_sosi.tdata(63 downto 00) <= rx_64_data;
    eth_in_sosi.tstrb               <= (others => '0');
    eth_in_sosi.tkeep(07 downto 00) <= rx_64_keep;
    eth_in_sosi.tlast               <= rx_64_last;
    eth_in_sosi.tid                 <= (others => '0');
    eth_in_sosi.tdest               <= (others => '0');
    eth_in_sosi.tuser               <= (others => '0');
    rx_64_ready                     <= '1'; --eth_in_siso.tready;              

    rx_debug_fifo_inst : rx_debug_fifo
    PORT MAP (
        clk   => axi_clk,
        srst  => axi_rst,
        din   => rx_64_data,
        wr_en => rx_64_valid,
        rd_en => debug_re,
        dout  => GPIO1(7 downto 0),
        full  => GPIO1(8),
        empty => GPIO1(9),
        wr_rst_busy => open,
        rd_rst_busy => open
    );

    GPIO1(10) <= rx_reset;
    GPIO1(11) <= axi_rst;

    tx_axi_interconnect_inst : tx_axi_interconnect
    PORT MAP (
        ACLK             => tx_clk,
        ARESETN          => tx_reset_n,
        S00_AXIS_ACLK    => axi_clk,
        S00_AXIS_ARESETN => axi_rst_n,
        S00_AXIS_TVALID  => tx_64_valid,
        S00_AXIS_TREADY  => tx_64_ready,
        S00_AXIS_TDATA   => tx_64_data,
        S00_AXIS_TKEEP   => tx_64_keep,
        S00_AXIS_TLAST   => tx_64_last,
        M00_AXIS_ACLK    => tx_clk,
        M00_AXIS_ARESETN => tx_reset_n,
        M00_AXIS_TVALID  => tx_valid,
        M00_AXIS_TREADY  => tx_ready,
        M00_AXIS_TDATA   => tx_data,
        M00_AXIS_TKEEP   => open,
        M00_AXIS_TLAST   => tx_last,
        S00_FIFO_DATA_COUNT => open
    );
    
    tx_64_valid         <= eth_out_sosi.tvalid;
    tx_64_data          <= eth_out_sosi.tdata(63 downto 0);
    tx_64_keep          <= eth_out_sosi.tkeep(7 downto 0);
    tx_64_last          <= eth_out_sosi.tlast;
    eth_out_siso.tready <= tx_64_ready; 



  
--  u_tech_mac_10g : ENTITY tech_mac_10g_lib.tech_mac_10g
--                 GENERIC MAP (g_technology      => g_technology)
--                 PORT MAP (gt_rxp_in            => gt_rxp_in,
--                           gt_rxn_in            => gt_rxn_in,
--                           gt_txp_out           => gt_txp_out,
--                           gt_txn_out           => gt_txn_out,
--                           gt_refclk_p          => gt_refclk_p,
--                           gt_refclk_n          => gt_refclk_n,
--                           sys_reset            => sys_reset,
--                           dclk                 => dclk,
--                           tx_clk_out           => tx_clk_out,
--                           rx_clk_out           => rx_clk_out,
--                           user_rx_reset        => user_rx_reset,
--                           stat_rx_block_lock   => stat_rx_block_lock,
--                           user_tx_reset        => user_tx_reset,
--                           eth_in_sosi          => eth_in_sosi,
--                           eth_in_siso          => eth_in_siso,
--                           eth_out_sosi         => eth_out_sosi,
--                           eth_out_siso         => eth_out_siso,
--                           tx_unfout            => tx_unfout,
--                           ctl_rx_pause_ack     => ctl_rx_pause_ack,
--                           ctl_rx_pause_enable  => ctl_rx_pause_enable,
--                           stat_rx_pause_req    => stat_rx_pause_req);


  
  
  
  
  
  
  
  
  
  
  -------------------------------------------------------------------
  -- MACE
  -------------------------------------------------------------------

  u_eth_rx : ENTITY eth_lib.eth_rx
  GENERIC MAP (
    g_technology    => g_technology,
    g_num_eth_lanes => c_num_eth_lanes
  )
  PORT MAP (
    clk   => rx_clk_out,
    rst   => eth_reset,
    mymac_addr   => c_local_mac,
    eth_in_sosi  => eth_in_sosi,  -- RX Signals
    eth_out_sosi => decoder_out_sosi, -- eth output lanes
    eth_out_siso => decoder_out_siso  -- eth output lanes
    --led0 => led0,
    --led1 => led1,
    --led2 => led2
  );

u_ethernet_framer : ENTITY eth_lib.eth_tx
                    GENERIC MAP (g_technology        => g_technology,
                                 g_num_frame_inputs  => c_num_eth_lanes,
                                 g_max_packet_length => 8192,
                                 g_lane_priority     => (0, 1, 1, 1, 6, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1))
                    PORT MAP (eth_tx_clk             => tx_clk_out,
                              eth_rx_clk             => rx_clk_out,
                              axi_clk                => rx_clk_out,
                              axi_rst                => eth_reset,
                              eth_tx_rst             => eth_reset,
                              eth_address_ip         => ip_address,
                              eth_address_mac        => c_local_mac,
                              eth_pause_rx_enable    => ctl_rx_pause_enable,
                              eth_pause_rx_req       => stat_rx_pause_req,
                              eth_pause_rx_ack       => ctl_rx_pause_ack,
                              eth_out_sosi           => eth_out_sosi,
                              eth_out_siso           => eth_out_siso,
                              framer_in_sosi         => framer_in_sosi,
                              framer_in_siso         => framer_in_siso);



u_arp_protocol: ENTITY arp_lib.arp_responder
                GENERIC MAP (g_technology   => g_technology)
                PORT MAP (clk               => rx_clk_out,
                          rst               => eth_reset,
                          eth_addr_ip       => ip_address,
                          eth_addr_mac      => c_local_mac,
                          frame_in_sosi     => decoder_out_sosi(3),
                          frame_in_siso     => decoder_out_siso(3),
                          frame_out_siso    => framer_in_siso(3),
                          frame_out_sosi    => framer_in_sosi(3));

  u_gemini_server : ENTITY gemini_server_lib.gemini_server
  GENERIC MAP (
    g_technology       => g_technology,
    g_min_recycle_secs => 30, -- seconds timeout on a gemini client connection
    g_txfr_timeout       => 6250 -- time for packet-length register reads
  )
  PORT MAP (
    clk       => rx_clk_out,
    rst       => eth_reset,
    ethrx_in  => decoder_out_sosi(0),
    ethrx_out => decoder_out_siso(0),
    ethtx_in  => framer_in_siso(0),
    ethtx_out => framer_in_sosi(0),
    mm_in     => mm_in,
    mm_out    => mm_out,
    tod_in    => tod
  );
  decoder_out_siso(1).tready <= '1';
  decoder_out_siso(5).tready <= '1';
  
  u_ping_protocol : ENTITY ping_protocol_lib.ping_protocol
  PORT MAP (
    clk          => rx_clk_out,
    rst          => eth_reset,
    my_mac       => c_local_mac,
    eth_in_sosi  => decoder_out_sosi(4),
    eth_in_siso  => decoder_out_siso(4),
    eth_out_sosi => framer_in_sosi(4),
    eth_out_siso => framer_in_siso(4)
  );

u_dhcp_protocol: ENTITY dhcp_lib.dhcp_protocol 
                 GENERIC MAP (g_technology         => g_technology)
                 PORT MAP (axi_clk                 => rx_clk_out,
                           axi_rst                 => eth_reset,
                           ip_address_default      => c_local_ip,
                           mac_address             => c_local_mac,
                           serial_number           => serial_number,
                           dhcp_start              => vcc(0),
                           ip_address              => ip_address,
                           ip_event                => event_in(0),
                           s_axi_mosi              => s_axi_mosi(1),
                           s_axi_miso              => s_axi_miso(1),
                           frame_in_sosi           => decoder_out_sosi(2),
                           frame_in_siso           => decoder_out_siso(2),
                           frame_out_sosi          => framer_in_sosi(2),
                           frame_out_siso          => framer_in_siso(2));


   event_in(30 DOWNTO 1) <= (OTHERS => '0');
   event_in(31)          <= button(1);

u_subscription_protocol: ENTITY gemini_subscription_lib.subscription_protocol 
                         GENERIC MAP (g_technology      => g_technology,
                                      g_num_clients     => 4)
                         PORT MAP (axi_clk              => rx_clk_out,
                                   axi_rst              => eth_reset,
                                   time_in              => time_in,
                                   event_in             => event_in,
                                   s_axi_mosi           => s_axi_mosi(0),
                                   s_axi_miso           => s_axi_miso(0),
                                   stream_out_sosi      => framer_in_sosi(5),
                                   stream_out_siso      => framer_in_siso(5));

  axi_test_i: ENTITY work.axi_test_wrapper
  PORT MAP (
      aclk => rx_clk_out,
      ARESETN => eth_reset_n,
      GPIO_IN_tri_i  => mace_gpio_in,
      GPIO_OUT_tri_o => mace_gpio_out,
      M02_AXI_LITE_araddr => s_axi_mosi(0).araddr,
      M02_AXI_LITE_arprot  => s_axi_mosi(0).arprot,
      M02_AXI_LITE_arready => s_axi_miso(0).arready,
      M02_AXI_LITE_arvalid  => s_axi_mosi(0).arvalid,
      M02_AXI_LITE_awaddr => s_axi_mosi(0).awaddr,
      M02_AXI_LITE_awprot => s_axi_mosi(0).awprot,
      M02_AXI_LITE_awready  => s_axi_miso(0).awready,
      M02_AXI_LITE_awvalid => s_axi_mosi(0).awvalid,
      M02_AXI_LITE_bready => s_axi_mosi(0).bready,
      M02_AXI_LITE_bresp => s_axi_miso(0).bresp,
      M02_AXI_LITE_bvalid => s_axi_miso(0).bvalid,
      M02_AXI_LITE_rdata => s_axi_miso(0).rdata,
      M02_AXI_LITE_rready  => s_axi_mosi(0).rready,
      M02_AXI_LITE_rresp => s_axi_miso(0).rresp,
      M02_AXI_LITE_rvalid => s_axi_miso(0).rvalid,
      M02_AXI_LITE_wdata => s_axi_mosi(0).wdata,
      M02_AXI_LITE_wready => s_axi_miso(0).wready,
      M02_AXI_LITE_wstrb => s_axi_mosi(0).wstrb,
      M02_AXI_LITE_wvalid => s_axi_mosi(0).wvalid,
      M03_AXI_LITE_araddr => s_axi_mosi(1).araddr,
      M03_AXI_LITE_arprot  => s_axi_mosi(1).arprot,
      M03_AXI_LITE_arready => s_axi_miso(1).arready,
      M03_AXI_LITE_arvalid  => s_axi_mosi(1).arvalid,
      M03_AXI_LITE_awaddr => s_axi_mosi(1).awaddr,
      M03_AXI_LITE_awprot => s_axi_mosi(1).awprot,
      M03_AXI_LITE_awready  => s_axi_miso(1).awready,
      M03_AXI_LITE_awvalid => s_axi_mosi(1).awvalid,
      M03_AXI_LITE_bready => s_axi_mosi(1).bready,
      M03_AXI_LITE_bresp => s_axi_miso(1).bresp,
      M03_AXI_LITE_bvalid => s_axi_miso(1).bvalid,
      M03_AXI_LITE_rdata => s_axi_miso(1).rdata,
      M03_AXI_LITE_rready  => s_axi_mosi(1).rready,
      M03_AXI_LITE_rresp => s_axi_miso(1).rresp,
      M03_AXI_LITE_rvalid => s_axi_miso(1).rvalid,
      M03_AXI_LITE_wdata => s_axi_mosi(1).wdata,
      M03_AXI_LITE_wready => s_axi_miso(1).wready,
      M03_AXI_LITE_wstrb => s_axi_mosi(1).wstrb,
      M03_AXI_LITE_wvalid => s_axi_mosi(1).wvalid,
      S00_AXI_araddr => mm_out.araddr(14 DOWNTO 0),
      S00_AXI_arburst => mm_out.arburst,
      S00_AXI_arcache => mm_out.arcache,
      S00_AXI_arlen => mm_out.arlen,
      S00_AXI_arlock => mm_out.arlock,
      S00_AXI_arqos => (others=>'0'),
      S00_AXI_arprot => mm_out.arprot,
      S00_AXI_arready => mm_in.arready,
      S00_AXI_arsize => mm_out.arsize,
      S00_AXI_arvalid => mm_out.arvalid,
      S00_AXI_awaddr => mm_out.awaddr(14 DOWNTO 0),
      S00_AXI_awburst => mm_out.awburst,
      S00_AXI_awcache => mm_out.awcache,
      S00_AXI_awlen => mm_out.awlen,
      S00_AXI_awlock => mm_out.awlock,
      S00_AXI_awqos => (others=>'0'),
      S00_AXI_awprot => mm_out.awprot,
      S00_AXI_awready => mm_in.awready,
      S00_AXI_awsize => mm_out.awsize,
      S00_AXI_awvalid => mm_out.awvalid,
      S00_AXI_bready => mm_out.bready,
      S00_AXI_bresp => mm_in.bresp,
      S00_AXI_bvalid => mm_in.bvalid,
      S00_AXI_rdata => mm_in.rdata(31 DOWNTO 0),
      S00_AXI_rlast => mm_in.rlast,
      S00_AXI_rready => mm_out.rready,
      S00_AXI_rresp => mm_in.rresp,
      S00_AXI_rvalid => mm_in.rvalid,
      S00_AXI_wdata => mm_out.wdata(31 DOWNTO 0),
      S00_AXI_wlast => mm_out.wlast,
      S00_AXI_wready => mm_in.wready,
      S00_AXI_wstrb => mm_out.wstrb(3 DOWNTO 0),
      S00_AXI_wvalid => mm_out.wvalid );

--  u_ip_xcku040_mac10g_noaxi_pkt_gen_mon : ip_xcku040_mac10g_noaxi_pkt_gen_mon
--  PORT MAP (
--    gen_clk => tx_clk_out,
--    mon_clk => rx_clk_out,
--    dclk => dclk,
--    sys_reset => sys_reset,
--  -- User Interface signals
--    restart_tx_rx => restart_tx_rx_0,
--  -- RX Signals
--    user_rx_reset=> user_rx_reset,

--  -- RX Stats Signals
--    stat_rx_block_lock => stat_rx_block_lock,
--    user_tx_reset => user_tx_reset,
--  -- TX LBUS Signals
--    tx_unfout => tx_unfout,
--    tx_preamblein => tx_preamblein,

--    rx_gt_locked_led => rx_gt_locked_led_0,
--    rx_block_lock_led => rx_block_lock
--    );

END str;

