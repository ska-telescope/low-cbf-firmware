-------------------------------------------------------------------------------
-- File Name: eth_rx_queue.vhd
-- Contributing Authors: Leon Hiemstra
-- Created: September, 2017
--
-- Title: Ethernet RX Queue
--
-- Description: Incoming RX packets get queued in a FIFO
--
-------------------------------------------------------------------------------

LIBRARY IEEE, technology_lib, common_lib, axi4_lib;
USE IEEE.std_logic_1164.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE work.eth_pkg.ALL;


ENTITY eth_rx_queue IS
  GENERIC (
      g_technology    : t_technology
  );
  PORT (
    clk   : IN STD_LOGIC;
    rst   : IN STD_LOGIC;

    eth_in_sosi    : IN  t_axi4_sosi;

    eth_fifo_sosi     : OUT t_axi4_sosi;
    eth_fifo_read_en  : IN  STD_LOGIC;

    pkt_queue_valid   : OUT STD_LOGIC;
    pkt_queue_data    : OUT STD_LOGIC;
    pkt_queue_read_en : IN  STD_LOGIC
  );
END eth_rx_queue;


ARCHITECTURE str OF eth_rx_queue IS

SIGNAL eth_fifo_rd_valid  : STD_LOGIC;
SIGNAL eth_fifo_valid     : STD_LOGIC;
SIGNAL eth_fifo_out_tlast : STD_LOGIC;
SIGNAL pkt_queue_write_en : STD_LOGIC;
SIGNAL pkt_is_good        : STD_LOGIC;
SIGNAL pkt_queue_avail    : STD_LOGIC;
SIGNAL pkt_queue_empty    : STD_LOGIC;

BEGIN

  eth_fifo_valid       <= eth_fifo_read_en; -- AND fifo_rd_valid;
  eth_fifo_sosi.tvalid <= eth_fifo_valid;

  eth_fifo_sosi.tlast  <= eth_fifo_out_tlast AND eth_fifo_valid;


  u_eth_rx_fifo: ENTITY common_lib.common_fifo_sc
  GENERIC MAP (
    g_technology    => g_technology,
    g_use_lut       => FALSE,
    g_dat_w         => 73,
    g_nof_words     => 2048, -- MTU of 9000 bytes / 8bytes = 1125 --> 2048
    --g_nof_words     => 4096, -- MTU of 9000 bytes / 8bytes = 1125 --> 2048
    g_fifo_latency  => 0
  )
  PORT MAP (
    rst                  => rst,
    clk                  => clk,
    wr_dat(63 DOWNTO 0)  => eth_in_sosi.tdata(63 downto 0),
    wr_dat(71 DOWNTO 64) => eth_in_sosi.tkeep(7 DOWNTO 0),
    wr_dat(72)           => eth_in_sosi.tlast,
    wr_req               => eth_in_sosi.tvalid,
    rd_dat(63 DOWNTO 0)  => eth_fifo_sosi.tdata(63 DOWNTO 0),
    rd_dat(71 DOWNTO 64) => eth_fifo_sosi.tkeep(7 DOWNTO 0),
    rd_dat(72)           => eth_fifo_out_tlast,
    rd_req               => eth_fifo_read_en,
    rd_val               => eth_fifo_rd_valid
  );

  u_eth_pkt_queue: ENTITY common_lib.common_fifo_sc
  GENERIC MAP (
    g_technology    => g_technology,
    g_use_lut       => FALSE,
    g_dat_w         => 1,
    g_nof_words     => 256, -- fifo u_eth_rx_fifo holding maximal number of packets in queue
    g_fifo_latency  => 0
  )
  PORT MAP (
    rst       => rst,
    clk       => clk,
    wr_dat(0) => pkt_is_good,
    wr_req    => pkt_queue_write_en,
    rd_dat(0) => pkt_queue_data,
    rd_req    => pkt_queue_read_en,
    rd_emp    => pkt_queue_empty
    --rd_val    => pkt_queue_valid
  );

  pkt_queue_write_en <= eth_in_sosi.tvalid AND eth_in_sosi.tlast;-- AND (NOT eth_in_sosi.tuser(0));
  pkt_is_good        <= NOT eth_in_sosi.tuser(0);
  pkt_queue_avail    <= (NOT pkt_queue_empty); -- AND pkt_queue_valid
  pkt_queue_valid    <= pkt_queue_avail;

END str;

