-------------------------------------------------------------------------------
-- File Name: eth_rx_chk.vhd
-- Contributing Authors: Leon Hiemstra
-- Created: September, 2017
--
-- Title: Ethernet RX Packet checker
--
-- Description: Forwards only valid packets
--
-------------------------------------------------------------------------------

LIBRARY IEEE, technology_lib, common_lib, axi4_lib;
USE IEEE.std_logic_1164.ALL;
USE common_lib.common_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE work.eth_pkg.ALL;


ENTITY eth_rx_chk IS
  PORT (
    clk   : IN STD_LOGIC;
    rst   : IN STD_LOGIC;

    eth_fifo_sosi     : IN  t_axi4_sosi;
    eth_fifo_read_en  : OUT STD_LOGIC;

    eth_pkt_sosi      : OUT t_axi4_sosi;

    pkt_queue_valid   : IN  STD_LOGIC;
    pkt_queue_data    : IN  STD_LOGIC;
    pkt_queue_read_en : OUT STD_LOGIC
  );
END eth_rx_chk;


ARCHITECTURE str OF eth_rx_chk IS

TYPE t_state IS (s_pkt_wait, s_pkt_delay, s_pkt_forward);

TYPE t_reg IS RECORD
    fifo_read_en  : STD_LOGIC;
    queue_read_en : STD_LOGIC;
    state         : t_state;
END RECORD;

SIGNAL r, nxt_r : t_reg;

BEGIN

  p_comb: PROCESS(rst, r, eth_fifo_sosi, pkt_queue_valid, pkt_queue_data)
    VARIABLE v : t_reg;
  BEGIN
      -- defaults:
      v               := r;
      v.fifo_read_en  := '0';
      v.queue_read_en := '0';

      CASE r.state IS

        WHEN s_pkt_wait =>
          IF pkt_queue_valid = '1' THEN
              v.state := s_pkt_delay; -- receivers expect min gap of 2 words
          END IF;

        WHEN s_pkt_delay =>
          IF pkt_queue_valid = '1' THEN
              v.fifo_read_en := '1';
              v.queue_read_en := '1';
              v.state := s_pkt_forward;
          END IF;

        WHEN s_pkt_forward =>
          v.fifo_read_en := '1';

          IF eth_fifo_sosi.tlast = '1' THEN
              v.fifo_read_en := '0';
              v.state := s_pkt_wait;
          END IF;

        WHEN OTHERS =>
          v.state := s_pkt_wait;
      END CASE;


      IF rst='1' THEN
        v.fifo_read_en  := '0';
        v.queue_read_en := '0';
        v.state         := s_pkt_wait;
      END IF;
  
      nxt_r <= v; -- updating registers

  END PROCESS;


  p_reg : PROCESS(clk)
  BEGIN
      IF rising_edge(clk) THEN
          r <= nxt_r;
      END IF;
  END PROCESS;

  -- connect to outside world
  eth_fifo_read_en  <= r.fifo_read_en;
  pkt_queue_read_en <= r.queue_read_en;
  eth_pkt_sosi.tdata  <= eth_fifo_sosi.tdata;
  eth_pkt_sosi.tkeep  <= eth_fifo_sosi.tkeep;
  eth_pkt_sosi.tlast  <= eth_fifo_sosi.tlast;
  eth_pkt_sosi.tvalid <= pkt_queue_data AND eth_fifo_sosi.tvalid;

END str;


