-------------------------------------------------------------------------------
-- File Name: eth_rx.vhd
-- Contributing Authors: Leon Hiemstra
-- Created: September, 2017
--
-- Title: Top Level of Ethernet RX Decoder
--
-- Description:
--
-------------------------------------------------------------------------------

LIBRARY IEEE, technology_lib, common_lib, axi4_lib;
USE IEEE.std_logic_1164.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE work.eth_pkg.ALL;


ENTITY eth_rx IS
  GENERIC (
      g_technology    : t_technology;
      g_num_eth_lanes : INTEGER := 16
  );
  PORT (
    clk   : IN STD_LOGIC;
    rst   : IN STD_LOGIC;

    mymac_addr   : IN  STD_LOGIC_VECTOR(47 DOWNTO 0); -- fpga MAC address
    eth_in_sosi  : IN  t_axi4_sosi; -- RX from MAC (MAC does not provide tready backpressure)
    eth_out_sosi : OUT t_axi4_sosi_arr(0 TO g_num_eth_lanes-1); -- eth output lanes
    eth_out_siso : IN  t_axi4_siso_arr(0 TO g_num_eth_lanes-1)  -- eth output lanes
  );
END eth_rx;

ARCHITECTURE str OF eth_rx IS

-- tready for back pressure:
SIGNAL eth_fifo_siso     : t_axi4_siso;

-- vlan stripped signals:
SIGNAL eth_vlan_sosi     : t_axi4_sosi;

-- piped signals:
SIGNAL pipe_sosi         : t_axi4_sosi;

-- fifo signals:
SIGNAL eth_fifo_sosi     : t_axi4_sosi;
SIGNAL eth_pkt_sosi      : t_axi4_sosi;
SIGNAL eth_fifo_read_en  : STD_LOGIC;
SIGNAL eth_fifo_read     : STD_LOGIC;

-- queue signals:
SIGNAL pkt_queue_valid   : STD_LOGIC;
SIGNAL pkt_queue_data    : STD_LOGIC;
SIGNAL pkt_queue_read_en : STD_LOGIC;

-- decoder signals:
SIGNAL pkt_decode_mac_ok        : STD_LOGIC;
SIGNAL pkt_decode_has_vlan_tag  : STD_LOGIC;
SIGNAL pkt_decode_is_icmp       : STD_LOGIC;
SIGNAL pkt_decode_is_arp        : STD_LOGIC;
SIGNAL pkt_decode_is_udp_dhcp   : STD_LOGIC;
SIGNAL pkt_decode_is_udp_ptp    : STD_LOGIC;
SIGNAL pkt_decode_is_udp_gemini : STD_LOGIC;

-- pipelined decoder signals:
SIGNAL pkt_mac_ok        : STD_LOGIC;
SIGNAL pkt_has_vlan_tag  : STD_LOGIC;
SIGNAL pkt_is_icmp       : STD_LOGIC;
SIGNAL pkt_is_arp        : STD_LOGIC;
SIGNAL pkt_is_udp_dhcp   : STD_LOGIC;
SIGNAL pkt_is_udp_ptp    : STD_LOGIC;
SIGNAL pkt_is_udp_gemini : STD_LOGIC;

BEGIN

  u_eth_rx_queue : ENTITY work.eth_rx_queue
  GENERIC MAP (
    g_technology => g_technology
  )
  PORT MAP (
    clk               => clk,
    rst               => rst,
    eth_in_sosi       => eth_in_sosi,

    eth_fifo_sosi     => eth_fifo_sosi,
    eth_fifo_read_en  => eth_fifo_read,

    pkt_queue_valid   => pkt_queue_valid,
    pkt_queue_data    => pkt_queue_data,
    pkt_queue_read_en => pkt_queue_read_en
  );

  u_eth_rx_chk : ENTITY work.eth_rx_chk
  PORT MAP (
    clk               => clk,
    rst               => rst,
    eth_fifo_sosi     => eth_fifo_sosi,
    eth_fifo_read_en  => eth_fifo_read_en,

    eth_pkt_sosi      => eth_pkt_sosi,

    pkt_queue_valid   => pkt_queue_valid,
    pkt_queue_data    => pkt_queue_data,
    pkt_queue_read_en => pkt_queue_read_en
  );

  u_eth_rx_decode : ENTITY work.eth_rx_decode
  PORT MAP (
    clk           => clk,
    rst           => rst,

    eth_pkt_sosi      => eth_pkt_sosi,
    eth_pkt_pipe_sosi => pipe_sosi,

    my_mac        => mymac_addr,

    mac_ok        => pkt_decode_mac_ok,
    has_vlan_tag  => pkt_decode_has_vlan_tag,
    is_icmp       => pkt_decode_is_icmp,
    is_arp        => pkt_decode_is_arp,
    is_udp_dhcp   => pkt_decode_is_udp_dhcp,
    is_udp_ptp    => pkt_decode_is_udp_ptp,
    is_udp_gemini => pkt_decode_is_udp_gemini
  );

  u_eth_rx_tvalid_extend : ENTITY work.eth_rx_tvalid_extend
  GENERIC MAP (
    g_dat_w  => 7
  )
  PORT MAP (
    clk        => clk,
    rst        => rst,

    tvalid_on  => pipe_sosi.tvalid,
    tvalid_off => eth_vlan_sosi.tvalid,

    in_dat(0)  => pkt_decode_mac_ok,
    in_dat(1)  => pkt_decode_has_vlan_tag,
    in_dat(2)  => pkt_decode_is_icmp,
    in_dat(3)  => pkt_decode_is_arp,
    in_dat(4)  => pkt_decode_is_udp_dhcp,
    in_dat(5)  => pkt_decode_is_udp_ptp,
    in_dat(6)  => pkt_decode_is_udp_gemini,

    out_dat(0)  => pkt_mac_ok,
    out_dat(1)  => pkt_has_vlan_tag,
    out_dat(2)  => pkt_is_icmp,
    out_dat(3)  => pkt_is_arp,
    out_dat(4)  => pkt_is_udp_dhcp,
    out_dat(5)  => pkt_is_udp_ptp,
    out_dat(6)  => pkt_is_udp_gemini
  );


  u_eth_rx_vlan: ENTITY work.eth_rx_vlan
  PORT MAP (
    clk                => clk,
    rst                => rst,
    strip_en           => pkt_decode_has_vlan_tag,
    eth_in_sosi        => pipe_sosi,
    eth_out_sosi       => eth_vlan_sosi
  );

  gen_eth_output: FOR i IN 0 TO g_num_eth_lanes-1 GENERATE
    eth_out_sosi(i).tdata(63 DOWNTO 0) <= eth_vlan_sosi.tdata(63 DOWNTO 0);
    eth_out_sosi(i).tkeep(7 DOWNTO 0)  <= eth_vlan_sosi.tkeep(7 DOWNTO 0);
    eth_out_sosi(i).tlast              <= eth_vlan_sosi.tlast;
  END GENERATE;

  eth_out_sosi(0).tvalid <= pkt_is_udp_gemini AND pkt_mac_ok AND eth_vlan_sosi.tvalid;
  eth_out_sosi(1).tvalid <= pkt_is_udp_ptp    AND pkt_mac_ok AND eth_vlan_sosi.tvalid;
  eth_out_sosi(2).tvalid <= pkt_is_udp_dhcp   AND pkt_mac_ok AND eth_vlan_sosi.tvalid;
  eth_out_sosi(3).tvalid <= pkt_is_arp        AND pkt_mac_ok AND eth_vlan_sosi.tvalid;
  eth_out_sosi(4).tvalid <= pkt_is_icmp       AND pkt_mac_ok AND eth_vlan_sosi.tvalid;
  eth_out_sosi(5).tvalid <= '0';

  process(eth_out_siso)
      variable tmp_tready : std_logic;
  begin
      tmp_tready := '1';
      loop_fifo_siso_tready : for i in 0 to g_num_eth_lanes-1 loop
          tmp_tready := tmp_tready AND eth_out_siso(i).tready;
      end loop;
      eth_fifo_siso.tready <= tmp_tready;
  end process;

  eth_fifo_read <= eth_fifo_read_en AND eth_fifo_siso.tready;

END str;

