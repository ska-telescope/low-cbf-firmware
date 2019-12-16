-------------------------------------------------------------------------------
--
-- File Name: client.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Monday Sept 11 15:40:00 2017
-- Template Rev: 1.0
--
-- Title: Gemini Publish/Subscribe Client Interface
--
-- Description:
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
USE IEEE.math_real.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;

-------------------------------------------------------------------------------
ENTITY client IS
   GENERIC (
      g_technology            : t_technology := c_tech_select_default;
      g_clock_rate            : REAL := 156.25;                            -- Frequency of AXI clock in MHz
      g_queue_length          : INTEGER := 32);

   PORT (
      -- Clocks & Resets
      axi_clk                 : IN STD_LOGIC;

      axi_rst                 : IN STD_LOGIC;

      -- Time
      time_in                 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);

      -- Events In
      event_in                : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

      -- Register Inputs
      event_mask              : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      acknowledge             : IN STD_LOGIC;
      dest_mac                : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
      dest_ip                 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      dest_port               : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
      delivery_int            : IN STD_LOGIC_VECTOR(13 DOWNTO 0);

      event_top               : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      event_overflow          : OUT STD_LOGIC;

      -- Framer Output
      stream_out_sosi         : OUT t_axi4_sosi;                           -- Uses valid to indicate that data is available
      stream_out_siso         : IN t_axi4_siso);
END client;

-------------------------------------------------------------------------------
ARCHITECTURE behaviour of client is

  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   CONSTANT c_msCount_width      : INTEGER := ceil_log2(INTEGER(g_clock_rate * 1000.0 - 1.0));
   CONSTANT c_msCount            : UNSIGNED(c_msCount_width-1 DOWNTO 0) := TO_UNSIGNED(INTEGER(g_clock_rate * 1000.0 - 1.0), c_msCount_width);

   TYPE t_fsm_states IS (s_idle, s_read_event, s_assemble_packet, s_wait_interval);

  ---------------------------------------------------------------------------
  -- SIGNAL DECLARATIONS  --
  ---------------------------------------------------------------------------

   -- Events
   SIGNAL event_in_dly           : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
   SIGNAL event_detect           : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL event_record           : STD_LOGIC_VECTOR(31 DOWNTO 0);

   -- FIFO
   SIGNAL event_data             : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL event_time             : STD_LOGIC_VECTOR(63 DOWNTO 0);
   SIGNAL event_write            : STD_LOGIC;
   SIGNAL queue_read             : STD_LOGIC;
   SIGNAL queue_full             : STD_LOGIC;
   SIGNAL queue_empty            : STD_LOGIC;

   -- Control Signals
   SIGNAL publish_state          : t_fsm_states;
   SIGNAL fifo_overflow          : STD_LOGIC;
   SIGNAL acknowledged           : STD_LOGIC;
   SIGNAL packet_counter         : UNSIGNED(3 DOWNTO 0);
   SIGNAL zero_mask              : STD_LOGIC;
   SIGNAL charge_pipe            : STD_LOGIC;

   SIGNAL zero_delivery          : STD_LOGIC;
   SIGNAL delivery_counter       : UNSIGNED(13 DOWNTO 0);
   SIGNAL ms_counter             : UNSIGNED(c_msCount_width-1 DOWNTO 0) := (OTHERS => '0');
   SIGNAL interval_expired       : STD_LOGIC;

   -- Packet Assembly
   SIGNAL packet_data            : STD_LOGIC_VECTOR(63 DOWNTO 0);
   SIGNAL packet_keep            : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL packet_last            : STD_LOGIC;
   SIGNAL packet_valid           : STD_LOGIC;
   SIGNAL pipeline_read          : STD_LOGIC;



BEGIN


   event_top <= event_data;
   event_overflow <= fifo_overflow;


---------------------------------------------------------------------------
-- Event Latches  --
---------------------------------------------------------------------------
-- On the rising edge of an event capture the current timestamp and push
-- it into the event queue (FIFO) when possible

event_capture: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         event_in_dly <= event_in;
         event_detect <= event_in AND NOT(event_in_dly);
         event_record <= event_detect AND event_mask;
      END IF;
   END PROCESS;


---------------------------------------------------------------------------
-- Event Queue  --
---------------------------------------------------------------------------

   -- Save the data when an event occurs
   event_write <= '1' WHEN event_record /= X"00000000" ELSE '0';

event_queue: ENTITY common_lib.common_fifo_sc
             GENERIC MAP (g_technology     => g_technology,
                          g_use_lut        => true,
                          g_fifo_latency   => 1,
                          g_dat_w          => 96,
                          g_nof_words      => g_queue_length)
             PORT MAP (rst                    => axi_rst,
                       clk                    => axi_clk,
                       wr_dat(63 downto 0)    => time_in,
                       wr_dat(95 downto 64)   => event_record,
                       wr_req                 => event_write,
                       wr_ful                 => queue_full,
                       wr_prog_ful            => OPEN,
                       wr_aful                => OPEN,
                       rd_dat(63 DOWNTO 0)    => event_time,
                       rd_dat(95 DOWNTO 64)   => event_data,
                       rd_req                 => queue_read,
                       rd_emp                 => queue_empty,
                       rd_prog_emp            => OPEN,
                       rd_val                 => OPEN,
                       usedw                  => OPEN);

---------------------------------------------------------------------------
-- Control FSM  --
---------------------------------------------------------------------------

publish_fsm: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN

         IF event_mask = X"00000000" THEN
            zero_mask <= '1';
         ELSE
            zero_mask <= '0';
         END IF;

         IF axi_rst = '1' THEN
            publish_state <= s_idle;
            packet_counter <= (OTHERS => '0');
            charge_pipe <= '0';
         ELSE
            CASE publish_state IS
               -------------------------------
               WHEN s_idle =>                                        -- Wait for event to occur
                  packet_counter <= (OTHERS => '0');
                  charge_pipe <= '0';
                  IF queue_empty = '0' THEN
                     publish_state <= s_read_event;
                  END IF;

               -------------------------------
               WHEN s_read_event =>                                  -- Read event queue
                  publish_state <= s_assemble_packet;
                  charge_pipe <= '1';

               -------------------------------
               WHEN s_assemble_packet =>                             -- Assemble the publish packet
                  charge_pipe <= '0';
                  IF stream_out_siso.tready = '1' OR charge_pipe = '1' THEN
                     packet_counter <= packet_counter + 1;

                     IF packet_counter = 8 THEN                      -- N+1 because of pipline
                        IF zero_delivery = '1' or acknowledged = '1' THEN
                           publish_state <= s_idle;
                        ELSE
                           publish_state <= s_wait_interval;
                        END IF;
                     END IF;
                  END IF;

               -------------------------------
               WHEN s_wait_interval =>                               -- Wait for the delivery interval if nessecary
                  IF zero_mask = '1' or acknowledged = '1' THEN
                     publish_state <= s_idle;
                  ELSE
                     IF interval_expired = '1' THEN
                        charge_pipe <= '1';
                        publish_state <= s_assemble_packet;
                        packet_counter <= (OTHERS => '0');
                     END IF;
                  END IF;
            END CASE;
         END IF;
      END IF;
   END PROCESS;

   queue_read <= '1' WHEN publish_state = s_read_event ELSE '0';
   packet_valid <= '1' WHEN publish_state = s_assemble_packet AND packet_counter(3) = '0' ELSE '0';

-- Hold acknowledge until it has been processed

acknowledge_latch: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         IF axi_rst = '1' THEN
            acknowledged <= '0';
            fifo_overflow <= '0';
         ELSE
            fifo_overflow <= fifo_overflow OR (queue_full and event_write);

            IF acknowledged = '0' THEN
               IF acknowledge = '1' THEN
                  acknowledged <= '1';
               END IF;
            ELSE
               IF publish_state = s_idle THEN
                  acknowledged <= '0';
                  fifo_overflow <= '0';
               END IF;
            END IF;
         END IF;
      END IF;
   END PROCESS;


---------------------------------------------------------------------------
-- Delivery Counter  --
---------------------------------------------------------------------------

delivery_timer: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         IF unsigned(delivery_int) = 0 THEN
            zero_delivery <= '1';
         ELSE
            zero_delivery <= '0';
         END IF;

         IF publish_state = s_assemble_packet THEN
            delivery_counter <= unsigned(delivery_int);
            ms_counter <= c_msCount;
            interval_expired <= '0';
         ELSE
            ms_counter <= ms_counter - 1;
            IF publish_state = s_wait_interval THEN
               IF ms_counter = 0 THEN
                  ms_counter <= c_msCount;
                  delivery_counter <= delivery_counter - 1;

                  IF delivery_counter = 1 THEN
                     interval_expired <= '1';
                  END IF;
               END IF;
            END IF;
         END IF;
      END IF;
   END PROCESS;

---------------------------------------------------------------------------
-- Packet Generation  --
---------------------------------------------------------------------------
-- Byte ordering is swapped later (makes loading busses better

packet_gen: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         IF pipeline_read = '1' THEN
            CASE TO_INTEGER(packet_counter) IS                                   --     MAC     |      IP/UDP     | Gemini Publish |
               WHEN 0 => packet_data(63 DOWNTO 16)  <= dest_mac;                 -- Destination |        -        |        -       |
                         packet_data(15 DOWNTO 0)   <= X"0000";                  --    Source   |        -        |        -       |
               WHEN 1 => packet_data(63 DOWNTO 32)  <= X"00000000";              --    Source   |        -        |        -       |
                         packet_data(31 DOWNTO 16)  <= X"0800";                  --   Protocol  |        -        |        -       |
                         packet_data(15 DOWNTO 8)   <= X"45";                    --      -      | Version & Length|        -       |
                         packet_data(7 DOWNTO 0)    <= X"00";                    --      -      |       TOS       |        -       |
               WHEN 2 => packet_data(63 DOWNTO 48)  <= X"002C";                  --      -      |   Total length  |        -       |
                         packet_data(47 DOWNTO 32)  <= X"0000";                  --      -      | Identification  |        -       |
                         packet_data(31 DOWNTO 16)  <= X"4000";                  --      -      |    Fragment     |        -       |
                         packet_data(15 DOWNTO 8)   <= X"40";                    --      -      |      TTL        |        -       |
                         packet_data(7 DOWNTO 0)    <= X"11";                    --      -      |    Protocol     |        -       |
               WHEN 3 => packet_data(63 DOWNTO 48)  <= X"0000";                  --      -      |   Header CRC    |        -       |
                         packet_data(47 DOWNTO 16)  <= X"00000000";              --      -      |    Source IP    |        -       |
                         packet_data(15 DOWNTO 0)   <= dest_ip(31 DOWNTO 16);    --      -      | Destination IP  |        -       |
               WHEN 4 => packet_data(63 DOWNTO 48)  <= dest_ip(15 DOWNTO 0);     --      -      | Destination IP  |        -       |
                         packet_data(47 DOWNTO 32)  <= X"7531";                  --      -      | Source UDP Port |        -       |
                         packet_data(31 DOWNTO 16)  <= dest_port;                --      -      |  Dest UDP Port  |        -       |
                         packet_data(15 DOWNTO 0)   <= X"0018";                  --      -      |   UDP Length    |        -       |
               WHEN 5 => packet_data(63 DOWNTO 48)  <= X"0000";                  --      -      |     UDP CRC     |        -       |
                         packet_data(47 DOWNTO 40)  <= X"01";                    --      -      |        -        |     Version    |
                         packet_data(39 DOWNTO 32)  <= X"80";                    --      -      |        -        |     Command    |
                         packet_data(31 DOWNTO 16)  <= X"0000";                  --      -      |        -        |    Reserved    |
                         packet_data(15 DOWNTO 0)   <= event_data(31 DOWNTO 16); --      -      |        -        |   Event Data   |
               WHEN 6 => packet_data(63 DOWNTO 48)  <= event_data(15 DOWNTO 0);  --      -      |        -        |   Event Data   |
                         packet_data(47 DOWNTO 0)   <= event_time(63 DOWNTO 16); --      -      |        -        |   Event Time   |
               WHEN 7 => packet_data(63 DOWNTO 48)  <= event_time(15 DOWNTO 0);  --      -      |        -        |   Event Time   |
                         packet_data(47 DOWNTO 0)   <= X"000000000000";
               WHEN OTHERS =>
                         packet_data <= (OTHERS => '0');
            END CASE;

            CASE to_integer(packet_counter) IS
               WHEN 0|1|2|3|4|5|6 => packet_keep  <= X"FF";
                                     packet_last <= '0';
               WHEN 7             => packet_keep  <= X"C0";
                                     packet_last <= '1';
               WHEN OTHERS        => packet_keep  <= X"00";
                                     packet_last <= '0';
            END CASE;
         END IF;
      END IF;
   END PROCESS;

   -- Byte swap
   stream_out_sosi.tdata(63 downto 0) <= packet_data(7 DOWNTO 0) &
                            packet_data(15 DOWNTO 8) &
                            packet_data(23 DOWNTO 16) &
                            packet_data(31 DOWNTO 24) &
                            packet_data(39 DOWNTO 32) &
                            packet_data(47 DOWNTO 40) &
                            packet_data(55 DOWNTO 48) &
                            packet_data(63 DOWNTO 56);

   stream_out_sosi.tkeep(7 downto 0) <= packet_keep(0) &
                            packet_keep(1) &
                            packet_keep(2) &
                            packet_keep(3) &
                            packet_keep(4) &
                            packet_keep(5) &
                            packet_keep(6) &
                            packet_keep(7);

   stream_out_sosi.tlast <= packet_last;

   -- Need to precharge the pipline before we start
   pipeline_read <= '1' WHEN charge_pipe = '1' ELSE
                    stream_out_siso.tready;


valid_data_pipe: ENTITY common_lib.common_pipeline
                 GENERIC MAP (g_pipeline  => 1,
                              g_in_dat_w  => 1,
                              g_out_dat_w => 1)
                 PORT MAP (clk                   => axi_clk,
                           rst                   => '0',
                           in_en                 => pipeline_read,
                           in_dat(0)             => packet_valid,
                           out_dat(0)            => stream_out_sosi.tvalid);




END ARCHITECTURE;


