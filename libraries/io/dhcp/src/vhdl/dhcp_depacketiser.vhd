-------------------------------------------------------------------------------
--
-- File Name: dhcp_depacketiser.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Wed Aug 15 15:40:00 2017
-- Template Rev: 1.0
--
-- Title: DHCP Packet Decoder
--
-- Description: Decodes DHCP packets. Payload locations inside packet are not
--              fixed so the whole packet must be recieved and decoded 
--              afterwards. Header fileds are fixed and are decoded based on 
--              fixed locations
--
--
-- Compiler options:
-- 
-- 
-- Dependencies:
-- 
-- 
-- 
-------------------------------------------------------------------------------

LIBRARY IEEE, common_lib, axi4_lib, technology_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;

-------------------------------------------------------------------------------
ENTITY dhcp_depacketiser IS
   GENERIC (
      g_technology            : t_technology := c_tech_select_default);
   
   PORT (
      -- Clocks & Resets
      axi_clk                 : IN STD_LOGIC;
      axi_rst                 : IN STD_LOGIC;

      -- Decoded data
      rx_ok                   : OUT STD_LOGIC;                             -- RX packet decode complete
      dhcp_op                 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);          -- RX packet type 
      xid                     : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);         -- XID field from packet
      dhcp_ip                 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);         -- IP of DHCP server
      dhcp_mac                : OUT STD_LOGIC_VECTOR(47 DOWNTO 0);         -- MAC of DHCP server
      lease_time              : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);         -- Lease time of IP allocation
      my_ip                   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);         -- Suggested IP allocation
      
      -- Framer Input
      frame_in_sosi           : IN t_axi4_sosi;
      frame_in_siso           : OUT t_axi4_siso);
END dhcp_depacketiser;

-------------------------------------------------------------------------------
ARCHITECTURE behaviour of dhcp_depacketiser is
   
  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   TYPE t_dhcp_decode IS (s_idle, s_look_for_magic, s_read_op_code, s_read_length,
                          s_read_payload, s_process_op, s_finished);

  ---------------------------------------------------------------------------
  -- SIGNAL DECLARATIONS  --
  ---------------------------------------------------------------------------

   SIGNAL i_tready               : STD_LOGIC;
   SIGNAL word_count             : UNSIGNED(4 DOWNTO 0);
   SIGNAL i_packet_data          : STD_LOGIC_VECTOR(127 DOWNTO 0);
   SIGNAL i_packet_data_valid    : STD_LOGIC;
   SIGNAL i_packet_last          : STD_LOGIC;
   
   SIGNAL payload                : STD_LOGIC;
   SIGNAL fifo_write             : STD_LOGIC;
   SIGNAL fifo_full              : STD_LOGIC;

   SIGNAL packet_decode          : t_dhcp_decode;
   SIGNAL dhcp_read              : STD_LOGIC;
   SIGNAL dhcp_data              : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL dhcp_empty             : STD_LOGIC;
   SIGNAL param_op               : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL param_length           : UNSIGNED(7 DOWNTO 0);
   SIGNAL read_counter           : UNSIGNED(7 DOWNTO 0);
   SIGNAL dhcp_shifter           : STD_LOGIC_VECTOR(31 DOWNTO 0);

  ---------------------------------------------------------------------------
  -- COMPONENT DECLARATIONS  --
  ---------------------------------------------------------------------------
   
   
BEGIN

   frame_in_siso.tready <= i_tready;

---------------------------------------------------------------------------
-- Header Field Latch  --
---------------------------------------------------------------------------

   -- Counts words of the packet as they pass
pkt_word_counter: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         IF axi_rst = '1' OR (frame_in_sosi.tlast = '1' AND frame_in_sosi.tvalid = '1' AND i_tready = '1') THEN
            word_count <= (OTHERS => '0');
         ELSE
            IF frame_in_sosi.tvalid = '1' AND i_tready = '1' AND word_count(4) = '0' THEN
               word_count <= word_count + 1;
            END IF;
         END IF;
      END IF;
   END PROCESS;


rx_pipeline: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         IF frame_in_sosi.tvalid = '1' AND i_tready = '1' THEN
            i_packet_data <= i_packet_data(63 DOWNTO 0) &
                             frame_in_sosi.tdata(7 DOWNTO 0) &
                             frame_in_sosi.tdata(15 DOWNTO 8) &
                             frame_in_sosi.tdata(23 DOWNTO 16) &
                             frame_in_sosi.tdata(31 DOWNTO 24) &
                             frame_in_sosi.tdata(39 DOWNTO 32) &
                             frame_in_sosi.tdata(47 DOWNTO 40) &
                             frame_in_sosi.tdata(55 DOWNTO 48) &
                             frame_in_sosi.tdata(63 DOWNTO 56);
            i_packet_data_valid <= '1';
            i_packet_last <= frame_in_sosi.tlast;
         ELSE
            i_packet_data_valid <= '0';
         END IF;
      END IF;
   END PROCESS;

------------------------------

header_decode: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         IF axi_rst = '1' THEN
            payload <= '0';
            dhcp_mac <= (OTHERS => '1');
            my_ip <= (OTHERS => '0');
         ELSE
            IF i_packet_data_valid = '1' THEN
               IF i_packet_last = '1' THEN
                  payload <= '0';
               ELSE
                  CASE TO_INTEGER(word_count) IS      -- N+1 becaseu of startup on counter
                     WHEN 2 => dhcp_mac <= i_packet_data(79 DOWNTO 32);
                     WHEN 7 => xid <= i_packet_data(79 DOWNTO 48); 
                     WHEN 8 => my_ip <= i_packet_data(47 DOWNTO 16);
                     WHEN 10 => payload <= '1';
                     WHEN OTHERS =>
                  END CASE;
               END IF;
            END IF;
         END IF;
      END IF;
   END PROCESS;

---------------------------------------------------------------------------
-- Payload Buffer  --
---------------------------------------------------------------------------

   fifo_write <= not(fifo_full) and i_packet_data_valid and payload WHEN packet_decode = s_idle ELSE '0';

   -- Ready if we aren't already decoding a packet
   i_tready <= '1' WHEN packet_decode = s_idle ELSE '0';

input_fifo: ENTITY common_lib.common_fifo_dc_mixed_widths 
            GENERIC MAP (g_technology    => g_technology,
                         g_nof_words     => 1024,            -- 36K BRAM
                         g_wr_dat_w      => 64,
                         g_rd_dat_w      => 8,
                         g_fifo_latency  => 1)
            PORT MAP (rst                    => axi_rst,
                      wr_clk                 => axi_clk, 
                      wr_dat(63 DOWNTO 56)   => i_packet_data(7 DOWNTO 0),
                      wr_dat(55 DOWNTO 48)   => i_packet_data(15 DOWNTO 8),
                      wr_dat(47 DOWNTO 40)   => i_packet_data(23 DOWNTO 16),
                      wr_dat(39 DOWNTO 32)   => i_packet_data(31 DOWNTO 24),
                      wr_dat(31 DOWNTO 24)   => i_packet_data(39 DOWNTO 32),
                      wr_dat(23 DOWNTO 16)   => i_packet_data(47 DOWNTO 40),
                      wr_dat(15 DOWNTO 8)    => i_packet_data(55 DOWNTO 48),
                      wr_dat(7 DOWNTO 0)     => i_packet_data(63 DOWNTO 56),
                      wr_req                 => fifo_write,
                      wr_ful                 => fifo_full,
                      wr_prog_ful            => OPEN,
                      rd_clk                 => axi_clk,
                      rd_dat                 => dhcp_data,
                      rd_req                 => dhcp_read,
                      rd_emp                 => dhcp_empty,
                      rd_prog_emp            => OPEN,
                      rd_val                 => OPEN);

---------------------------------------------------------------------------
-- Decoder  --
---------------------------------------------------------------------------

packet_decode_fsm: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         dhcp_shifter <= dhcp_shifter(23 downto 0) & dhcp_data;
         dhcp_read <= '0';
         rx_ok <= '0';
         
         IF axi_rst = '1' THEN
            packet_decode <= s_idle; 
            dhcp_ip <= (OTHERS => '1');
            lease_time <= (OTHERS => '0');
            dhcp_op <= (OTHERS => '0');
         ELSE
            CASE packet_decode IS
               WHEN s_idle => 
                  IF i_packet_last = '1' AND i_packet_data_valid = '1' THEN
                     packet_decode <= s_look_for_magic;
                     dhcp_read <= '1';
                  END IF;
               WHEN s_look_for_magic =>
                  dhcp_read <= '1';
                  IF dhcp_shifter(23 downto 0) = X"638253" AND dhcp_data = X"63" THEN
                     packet_decode <= s_read_op_code;
                  END IF;
               WHEN s_read_op_code =>
                  dhcp_read <= '1';
                  IF dhcp_data = X"FF" THEN
                     packet_decode <= s_finished;
                  ELSE
                     IF dhcp_data /= X"00" THEN          -- PAD
                        param_op <= dhcp_data;
                        packet_decode <= s_read_length;
                     END IF;
                  END IF;
               WHEN s_read_length =>
                  dhcp_read <= '1';
                  param_length <= UNSIGNED(dhcp_data);
                  packet_decode <= s_read_payload;
                  read_counter <= TO_UNSIGNED(1,8);
               WHEN s_read_payload =>
                  IF read_counter = param_length THEN
                     packet_decode <= s_process_op;
                  ELSE
                     read_counter <= read_counter + 1;
                     dhcp_read <= '1';
                  END IF;
               WHEN s_process_op =>
                  IF param_op = X"35" THEN                           -- Op Type
                     dhcp_op <= dhcp_shifter(7 DOWNTO 0);
                  ELSIF param_op = X"33" THEN                        -- Lease Length
                     lease_time <= dhcp_shifter;
                  ELSIF param_op = X"36" THEN                        -- Server Identifier
                     dhcp_ip <= dhcp_shifter;
                  END IF;
                     
                  packet_decode <= s_read_op_code;
                  dhcp_read <= '1';
               WHEN s_finished =>
                  rx_ok <= '1';
                  dhcp_read <= '1';
                  IF dhcp_empty = '1' THEN                           -- Make sure FIFO is empty
                     packet_decode <= s_idle;
                  END IF;
            END CASE;
         END IF;
      END IF;
   END PROCESS;

END behaviour;
-------------------------------------------------------------------------------