-------------------------------------------------------------------------------
--
-- File Name: eth_tx_lane.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Wed Aug 15 15:40:00 2017
-- Template Rev: 1.0
--
-- Title: Transmit Lane Interface
--
-- Description: Interface for a single AXI4 stream lane
--
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
USE technology_lib.technology_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;

-------------------------------------------------------------------------------
ENTITY eth_tx_lane IS
   GENERIC (
      g_technology            : t_technology;
      g_lane_priority         : INTEGER := 0);

   PORT (
      -- Clocks & Resets
      clk                     : IN STD_LOGIC;
      rst                     : IN STD_LOGIC;

      fifo_read               : IN STD_LOGIC;                        -- FIFO Read
      fifo_data               : OUT STD_LOGIC_VECTOR(75 downto 0);   -- Data from FIFO

      fifo_ready              : OUT STD_LOGIC;                       -- FIFO data available
      is_ip                   : OUT STD_LOGIC;                       -- Is the packet an IP packet (from MAC type field), valid on fifo_ready assertion
      is_udp                  : OUT STD_LOGIC;                       -- Is the packet a UDP packet (from IP type field), valid on fifo_ready assertion

      -- Framer Input
      framer_in_sosi          : IN t_axi4_sosi;
      framer_in_siso          : OUT t_axi4_siso);
END eth_tx_lane;

-------------------------------------------------------------------------------
ARCHITECTURE behaviour of eth_tx_lane is

   SIGNAL fifo_write       : STD_LOGIC;
   SIGNAL fifo_write_dly   : STD_LOGIC;
   SIGNAL fifo_empty       : STD_LOGIC;
   SIGNAL fifo_full        : STD_LOGIC;
   SIGNAL fifo_rd_valid    : STD_LOGIC;

   SIGNAL i_is_ip          : STD_LOGIC;
   SIGNAL i_is_udp         : STD_LOGIC;
   SIGNAL i_fifo_ready     : STD_LOGIC;
   SIGNAL lane_enabled     : STD_LOGIC := '1';

   SIGNAL word_counter     : UNSIGNED(2 DOWNTO 0);
   SIGNAL mac_lt           : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL ip_proto         : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL i_fifo_data      : STD_LOGIC_VECTOR(72 DOWNTO 0);

BEGIN

   -- Turn lane priority into a signal
   fifo_data(63 DOWNTO 0) <= i_fifo_data(63 DOWNTO 0);
   fifo_data(72 DOWNTO 64) <= i_fifo_data(72 DOWNTO 64) when fifo_rd_valid = '1' else (others => '0');
   fifo_data(75 downto 73) <= STD_LOGIC_VECTOR(TO_UNSIGNED(g_lane_priority, 3));

   is_ip <= i_is_ip;
   is_udp <= i_is_udp;
   fifo_ready <= i_fifo_ready and not(fifo_empty);

  ---------------------------------------------------------------------------
  -- Packet Type Flags  --
  ---------------------------------------------------------------------------

word_cnt: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         IF rst = '1' THEN
            word_counter <= (OTHERS => '0');
         ELSE
            IF fifo_write = '1' THEN
               IF framer_in_sosi.tlast = '1' then
                  word_counter <= (OTHERS => '0');
               ELSE
                  IF word_counter(2) = '0' THEN
                     word_counter <= word_counter + 1;
                  ELSE
                     word_counter <= word_counter;
                  END IF;
               END IF;
            ELSE
               word_counter <= word_counter;
            END IF;
         END IF;
      END IF;
   END PROCESS;

comparators: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         mac_lt <= framer_in_sosi.tdata(39 downto 32) & framer_in_sosi.tdata(47 downto 40);
         ip_proto <= framer_in_sosi.tdata(63 downto 56);
         fifo_write_dly <= fifo_write;

         IF fifo_write_dly = '1' THEN
            IF word_counter = 2 THEN
               IF mac_lt = X"0800" THEN
                  i_is_ip <= '1';
               ELSE
                  i_is_ip <= '0';
               END IF;
            ELSE
               i_is_ip <= i_is_ip;
            END IF;

            -- Only UDP if IP as well
            IF word_counter = 3 THEN
               IF ip_proto = X"11" THEN
                  i_is_udp <= i_is_ip;
               ELSE
                  i_is_udp <= '0';
               END IF;
            ELSE
               i_is_udp <= i_is_udp;
            END IF;
         END IF;
      END IF;
   END PROCESS;


  ---------------------------------------------------------------------------
  -- Input Logic  --
  ---------------------------------------------------------------------------

   fifo_write <= not(fifo_full) and framer_in_sosi.tvalid AND lane_enabled;

   framer_in_siso.tready <= not(fifo_full) AND lane_enabled;

input_fifo: ENTITY common_lib.common_fifo_sc
            GENERIC MAP (g_technology    => g_technology,
                         g_use_lut       => TRUE,
                         g_dat_w         => 73,
                         g_nof_words     => 32,
                         g_fifo_latency  => 1)
            PORT MAP (rst                    => rst,
                      clk                    => clk,
                      wr_dat(63 downto 0)    => framer_in_sosi.tdata(63 downto 0),
                      wr_dat(71 downto 64)   => framer_in_sosi.tkeep(7 downto 0),
                      wr_dat(72)             => framer_in_sosi.tlast,
                      wr_req                 => fifo_write,
                      wr_ful                 => fifo_full,
                      wr_prog_ful            => OPEN,
                      wr_aful                => OPEN,
                      rd_dat                 => i_fifo_data(72 downto 0),
                      rd_req                 => fifo_read,
                      rd_emp                 => fifo_empty,
                      rd_prog_emp            => OPEN,
                      rd_val                 => fifo_rd_valid,
                      usedw                  => OPEN);

  ---------------------------------------------------------------------------
  -- Lane Ready Latch (Input) --
  ---------------------------------------------------------------------------
-- If we recieve a tlast we need to drop the outgoing ready until the FIFO has
-- been serviced

write_latch: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(CLK) THEN
         IF rst = '1' THEN
            lane_enabled <= '1';
         ELSE
            IF lane_enabled = '1' THEN
               IF fifo_write = '1' and framer_in_sosi.tlast = '1' THEN
                  lane_enabled <= '0';
               END IF;
            ELSE
               IF i_fifo_data(72) = '1' AND fifo_rd_valid = '1' THEN
                  lane_enabled <= '1';
               END IF;
            END IF;
         END IF;
      END IF;
   END PROCESS;

  ---------------------------------------------------------------------------
  -- Lane Ready Latch (Output)  --
  ---------------------------------------------------------------------------

read_latch: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(CLK) THEN
         IF rst = '1' THEN
            i_fifo_ready <= '0';
         ELSE
            -- Data available (if early headers have been decoded)
            IF word_counter(2) = '1' THEN
               i_fifo_ready <= '1';
            ELSE
               -- Tlast coming out clears it.
               IF i_fifo_data(72) = '1' AND fifo_rd_valid = '1' THEN
                  i_fifo_ready <= '0';
               END IF;
           END IF;
         END IF;
      END IF;

   END PROCESS;











END behaviour;
-------------------------------------------------------------------------------