-------------------------------------------------------------------------------
--
-- File Name: tb_subscription.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Wed Aug 15 15:40:00 2017
-- Template Rev: 1.0
--
-- Title: Top Level of Ethernet Framer Testbench
--
-- Description: Includes a simple protocol analyser and a payload verification check
--              against the source dataset. Tests concurrent transmisison of 5 packets
--              of varying priorities and then sequential transmisison of packets of a
--              series of packets. Transmitted data is verified for correct inclsuion
--              of IP/MAC address and IP/UDP checksum as well as correct payload
--
-- Compiler options:
--
--
-- Dependencies:
--
--
--
-------------------------------------------------------------------------------

LIBRARY IEEE, common_lib, axi4_lib, technology_lib, gemini_subscription_lib, eth_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.math_real.ALL;
USE IEEE.std_logic_textio.ALL;
USE STD.textio.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE gemini_subscription_lib.gemini_subscription_reg_pkg.ALL;

ENTITY tb_subscription IS

END tb_subscription;

ARCHITECTURE testbench OF tb_subscription IS

  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   CONSTANT c_axi_clk_period     : TIME := 6.4 ns;
   CONSTANT c_reset_len          : INTEGER := 10;

   CONSTANT c_ifg_clocks         : INTEGER := 100;
   CONSTANT c_local_ip           : STD_LOGIC_VECTOR(31 DOWNTO 0) := X"0a010517";
   CONSTANT c_local_mac          : STD_LOGIC_VECTOR(47 DOWNTO 0) := X"001122334455";

  ---------------------------------------------------------------------------
  -- SIGNAL DECLARATIONS  --
  ---------------------------------------------------------------------------

   SIGNAL axi_clk                   : STD_LOGIC := '0';
   SIGNAL tb_end                    : STD_LOGIC := '0';

   -- DUT Signals
   SIGNAL stream_out_sosi           : t_axi4_sosi;
   SIGNAL stream_out_siso           : t_axi4_siso;
   SIGNAL time_in                   : STD_LOGIC_VECTOR(63 DOWNTO 0);
   SIGNAL event_in                  : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL s_axi_mosi                : t_axi4_lite_mosi;
   SIGNAL s_axi_miso                : t_axi4_lite_miso;

   SIGNAl encoder_in_sosi           : t_axi4_sosi_arr(0 TO 0);
   SIGNAL encoder_in_siso           : t_axi4_siso_arr(0 TO 0);

   -- Testbench
   SIGNAL reset                     : STD_LOGIC := '0';
   SIGNAL mac_ifg                   : INTEGER;
   SIGNAL mac_word_count_ely        : INTEGER;
   SIGNAL mac_word_count            : INTEGER;
   SIGNAL transaction_cycle_count   : INTEGER;
   SIGNAL mac_valid_ely             : STD_LOGIC;
   SIGNAL mac_valid                 : STD_LOGIC;
   SIGNAL mac_recieving_ely         : BOOLEAN;
   SIGNAL mac_recieving             : BOOLEAN;
   SIGNAL mac_recieving_dly         : BOOLEAN;
   SIGNAL mac_word_long             : STD_LOGIC_VECTOR(255 DOWNTO 0);
   SIGNAL mac_keep_long             : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL mac_tready                : STD_LOGIC := '1';
   SIGNAL arp_detected              : BOOLEAN;
   SIGNAL ip_detected               : BOOLEAN;
   SIGNAL icmp_detected             : BOOLEAN;
   SIGNAL udp_detected              : BOOLEAN;
   SIGNAL packet_number             : INTEGER := 0;
   SIGNAL trigger_event             : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL vlan_tag                  : BOOLEAN := TRUE;
   SIGNAl spare_data                : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL spare_keep                : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL valid_dly                 : STD_LOGIC;
   SIGNAL extra_cycle               : STD_LOGIC;


   SIGNAL new_packet                : BOOLEAN;
   SIGNAL gemini_detected           : BOOLEAN;
   SIGNAL dest_mac                  : STD_LOGIC_VECTOR(47 DOWNTO 0);
   SIGNAL dest_ip                   : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL dest_port                 : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL event_data                : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL event_time                : STD_LOGIC_VECTOR(63 DOWNTO 0);

BEGIN



---------------------------------------------------------------------------
-- Clocks  --
---------------------------------------------------------------------------

   axi_clk <= NOT axi_clk OR tb_end  AFTER c_axi_clk_period/2;
   reset <= '1', '0'    AFTER c_axi_clk_period*c_reset_len;

---------------------------------------------------------------------------
-- Time Simulation  --
---------------------------------------------------------------------------

time_sim: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         time_in <= STD_LOGIC_VECTOR(to_unsigned((now / 8 ns), 64));
      END IF;
   END PROCESS;



---------------------------------------------------------------------------
-- Event Simulation  --
---------------------------------------------------------------------------

-- Simulate getting an IP address
startup_event: PROCESS
   BEGIN
      event_in(0) <= '0';
      WAIT FOR 2 us;
      event_in(0) <= '1';
      WAIT;
   END PROCESS;

   event_in(31 DOWNTO 1) <= trigger_event(31 DOWNTO 1);



---------------------------------------------------------------------------
-- DUT  --
---------------------------------------------------------------------------

dut: ENTITY work.subscription_protocol
     GENERIC MAP (g_technology         => c_tech_gemini,
                  g_num_clients        => 4)
     PORT MAP (axi_clk              => axi_clk,
               axi_rst              => reset,
               time_in              => time_in,
               event_in             => event_in,
               s_axi_mosi           => s_axi_mosi,
               s_axi_miso           => s_axi_miso,
               stream_out_sosi      => encoder_in_sosi(0),
               stream_out_siso      => encoder_in_siso(0));

---------------------------------------------------------------------------
-- Add Headers  --
---------------------------------------------------------------------------


u_eth_tx : ENTITY eth_lib.eth_tx
           GENERIC MAP (g_technology            => c_tech_gemini,
                        g_num_frame_inputs      => 1,
                        g_max_packet_length     => 8192,
                        g_lane_priority         => (0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1))
           PORT MAP (eth_tx_clk             => axi_clk,
                     eth_rx_clk             => axi_clk,
                     axi_clk                => axi_clk,
                     axi_rst                => reset,
                     eth_tx_rst             => reset,
                     eth_address_ip         => c_local_ip,
                     eth_address_mac        => c_local_mac,
                     eth_pause_rx_enable    => OPEN,
                     eth_pause_rx_req       => "000000000",
                     eth_pause_rx_ack       => OPEN,
                     eth_out_sosi           => stream_out_sosi,
                     eth_out_siso           => stream_out_siso,
                     framer_in_sosi         => encoder_in_sosi,
                     framer_in_siso         => encoder_in_siso);


---------------------------------------------------------------------------
-- Packet Decoder  --
---------------------------------------------------------------------------
-- Generate textual descriptions of the packets

pkt_decode: ENTITY eth_lib.packet_decoder
            PORT MAP (clk           => axi_clk,
                      reset         => reset,
                      eth_out_sosi  => stream_out_sosi,
                      eth_out_siso  => stream_out_siso);

---------------------------------------------------------------------------
-- Transmit MAC Reciever  --
---------------------------------------------------------------------------

tx_mac: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         mac_word_count <= mac_word_count_ely;
         mac_recieving <= mac_recieving_ely;
         mac_valid <= mac_valid_ely;
         valid_dly <= stream_out_sosi.tvalid;

         mac_recieving_dly <= mac_recieving;

         IF reset = '1' THEN
            mac_recieving_ely <= FALSE;
            mac_word_count_ely <= 0;
            extra_cycle <= '0';
         ELSE
            -- Enable
            IF mac_recieving_ely = FALSE THEN
               IF stream_out_sosi.tvalid = '1' AND stream_out_siso.tready = '1' THEN
                  mac_recieving_ely <= TRUE;
               END IF;
            END IF;

            -- Used to insert random tready deassertions
            IF mac_recieving = FALSE THEN
               transaction_cycle_count <= 0;
            ELSE
               transaction_cycle_count <= transaction_cycle_count + 1;
            END IF;

            IF (stream_out_sosi.tvalid = '1' AND stream_out_siso.tready = '1') OR extra_cycle = '1' THEN
               extra_cycle <= '0';

               -- Count words in packet (for decoding)
               IF mac_recieving_ely = FALSE and valid_dly = '0' THEN
                  mac_word_count_ely <= 1;
               ELSE
                  mac_word_count_ely <= mac_word_count_ely + 1;
               END IF;


               spare_data <= stream_out_sosi.tdata(39 DOWNTO 32) &
                             stream_out_sosi.tdata(47 DOWNTO 40) &
                             stream_out_sosi.tdata(55 DOWNTO 48) &
                             stream_out_sosi.tdata(63 DOWNTO 56);

               spare_keep <= stream_out_sosi.tkeep(4) &
                             stream_out_sosi.tkeep(5) &
                             stream_out_sosi.tkeep(6) &
                             stream_out_sosi.tkeep(7);


               IF mac_word_count_ely = 1 AND (stream_out_sosi.tdata(39 DOWNTO 32) /= X"81" OR stream_out_sosi.tdata(47 DOWNTO 40) /= X"00") THEN
                  -- Insert pad for vlan header if not there
                  mac_word_long <= mac_word_long(191 DOWNTO 0) &
                                   stream_out_sosi.tdata(7 DOWNTO 0) &
                                   stream_out_sosi.tdata(15 DOWNTO 8) &
                                   stream_out_sosi.tdata(23 DOWNTO 16) &
                                   stream_out_sosi.tdata(31 DOWNTO 24) &
                                   X"00000000";

                  mac_keep_long <= mac_keep_long(23 downto 0) &
                                   stream_out_sosi.tkeep(0) &
                                   stream_out_sosi.tkeep(1) &
                                   stream_out_sosi.tkeep(2) &
                                   stream_out_sosi.tkeep(3) &
                                   X"F";

                  vlan_tag <= FALSE;

               ELSE
                  IF vlan_tag = FALSE THEN

                     IF extra_cycle = '0' THEN

                        mac_word_long <= mac_word_long(191 DOWNTO 0) &
                                         spare_data &
                                         stream_out_sosi.tdata(7 DOWNTO 0) &
                                         stream_out_sosi.tdata(15 DOWNTO 8) &
                                         stream_out_sosi.tdata(23 DOWNTO 16) &
                                         stream_out_sosi.tdata(31 DOWNTO 24);

                        mac_keep_long <= mac_keep_long(23 downto 0) &
                                         spare_keep &
                                         stream_out_sosi.tkeep(0) &
                                         stream_out_sosi.tkeep(1) &
                                         stream_out_sosi.tkeep(2) &
                                         stream_out_sosi.tkeep(3);

                     ELSE

                        mac_word_long <= mac_word_long(191 DOWNTO 0) &
                                         spare_data &
                                         X"00000000";

                        mac_keep_long <= mac_keep_long(23 downto 0) &
                                         spare_keep &
                                         "0000";
                     END IF;

                  ELSE

                     -- Go back to big endian and store 2 words incase fields cross boundaries
                     mac_word_long <= mac_word_long(191 DOWNTO 0) &
                                      stream_out_sosi.tdata(7 DOWNTO 0) &
                                      stream_out_sosi.tdata(15 DOWNTO 8) &
                                      stream_out_sosi.tdata(23 DOWNTO 16) &
                                      stream_out_sosi.tdata(31 DOWNTO 24) &
                                      stream_out_sosi.tdata(39 DOWNTO 32) &
                                      stream_out_sosi.tdata(47 DOWNTO 40) &
                                      stream_out_sosi.tdata(55 DOWNTO 48) &
                                      stream_out_sosi.tdata(63 DOWNTO 56);

                     mac_keep_long <= mac_keep_long(23 downto 0) &
                                      stream_out_sosi.tkeep(0) &
                                      stream_out_sosi.tkeep(1) &
                                      stream_out_sosi.tkeep(2) &
                                      stream_out_sosi.tkeep(3) &
                                      stream_out_sosi.tkeep(4) &
                                      stream_out_sosi.tkeep(5) &
                                      stream_out_sosi.tkeep(6) &
                                      stream_out_sosi.tkeep(7);
                  END IF;
               END IF;

               -- Stop receiving when last occurs (make extra cycle longer for NO VLAN packets if needed)
               IF stream_out_sosi.tlast = '1' OR extra_cycle = '1' THEN
                  IF vlan_tag = FALSE AND extra_cycle = '0' AND stream_out_sosi.tkeep(7 DOWNTO 4) /= X"0" THEN
                     extra_cycle <= '1';
                  ELSE
                     mac_recieving_ely <= FALSE;
                     mac_word_count_ely <= 0;
                     vlan_tag <= TRUE;
                  END IF;
               END IF;
            END IF;
         END IF;
      END IF;
   END PROCESS;

   mac_valid_ely <= (stream_out_sosi.tvalid and stream_out_siso.tready) OR extra_cycle when mac_recieving_ely = TRUE ELSE '0';


read_randomiser: PROCESS(axi_clk)
      VARIABLE seed1    : POSITIVE     := 52548;
      VARIABLE seed2    : POSITIVE     := 5087986;
      VARIABLE rand1    : REAL         := 0.5;                 -- random real-number value in range 0 to 1.0
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         IF mac_recieving_ely = TRUE THEN
            uniform(seed1, seed2, rand1);

            IF rand1 > 0.5 or transaction_cycle_count = 2 THEN
               mac_tready <= '0';
            ELSE
               mac_tready <= '1';
            END IF;
         END IF;
      END IF;
   END PROCESS;

   -- Handle the ready (ready when nothing going on, not ready duing interf frame gap, random ready during packet)
   stream_out_siso.tready <= '0' WHEN mac_ifg > 0 ELSE
                            '1' WHEN mac_recieving_ely = FALSE OR mac_word_count_ely < 1 ELSE
                            mac_tready;

---------------------------------------------------------------------------
-- RX Code  --
---------------------------------------------------------------------------

subscription_latch: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         new_packet <= FALSE;
         IF mac_recieving = TRUE THEN
            IF mac_valid = '1' AND (gemini_detected = TRUE OR mac_word_count = 3) THEN
               CASE mac_word_count IS
                  WHEN 3 =>
                     IF mac_word_long(127 DOWNTO 112) = X"0800" AND mac_word_long(39 DOWNTO 32) = X"11" THEN
                        gemini_detected <= TRUE;
                        dest_mac <= mac_word_long(255 DOWNTO 208);
                     END IF;
                  WHEN 5 =>
                     dest_ip <= mac_word_long(111 DOWNTO 80);
                     dest_port <= mac_word_long(63 DOWNTO 48);

                     -- Check source port & length
                     ASSERT (mac_word_long(79 DOWNTO 64) = X"7531") REPORT "Wrong subscription source port" SEVERITY failure;
                     ASSERT (mac_word_long(47 DOWNTO 32) = X"0018") REPORT "Wrong length" SEVERITY failure;
                  WHEN 6 =>

                     -- Check command
                     ASSERT (mac_word_long(39+32 DOWNTO 32+32) = X"80") REPORT "Wrong command code" SEVERITY failure;
                     ASSERT (mac_word_long(47+32 DOWNTO 40+32) = X"01") REPORT "Wrong version" SEVERITY failure;

                  WHEN 7 =>
                     event_data <= mac_word_long(79+32 DOWNTO 48+32);
                  WHEN 8 =>
                     event_time <= mac_word_long(111+32 DOWNTO 48+32);


                  WHEN OTHERS =>
               END CASE;
            END IF;
         ELSE
            IF mac_recieving_dly = TRUE AND gemini_detected = TRUE THEN
               new_packet <= TRUE;
            END IF;

            gemini_detected <= FALSE;
         END IF;
      END IF;

   END PROCESS;



---------------------------------------------------------------------------
-- Test Script  --
---------------------------------------------------------------------------

tb_stim: PROCESS

   BEGIN
      trigger_event <= (OTHERS => '0');


      -- Reset the AXI-Lite bus
      axi_lite_init (reset, axi_clk, s_axi_miso, s_axi_mosi);


      -------------------------------------------
      --                Test 1                 --
      -------------------------------------------
      -- First Event we recieve is broadcast from power up so wait
      -- for that and then acknowledge it

      WAIT UNTIL RISING_EDGE(new_packet);
      WAIT UNTIL rising_edge(axi_clk);
      ASSERT (dest_port = X"7531") REPORT "Wrong broadcast destination port" SEVERITY failure;
      ASSERT (dest_ip = X"ffffffff") REPORT "Wrong broadcast destination ip address" SEVERITY failure;
      ASSERT (dest_mac = X"ffffffffffff") REPORT "Wrong broadcast destination mac address" SEVERITY failure;
      ASSERT (event_data = X"00000001") REPORT "Unexpected event" SEVERITY failure;
      ASSERT (event_time = X"00000000000000FB") REPORT "Wrong broadcast destination port" SEVERITY failure;

      -- Acknowledge the broadcast event
      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_broadcast_control_acknowledge_address, true, X"00000001");

      REPORT "Finished Test 1" SEVERITY note;
      WAIT FOR 1 us;

      -------------------------------------------
      --                Test 2                 --
      -------------------------------------------
      -- Configure Client 1 for event 2 and trigger 2 events.
      -- Wait for mutiple packets before acknowledgement

      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_client_destination_ip_address(0), true, X"0A010504");
      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_client_destination_mac_lower_address(0), true, X"A2276E1C");
      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_client_destination_mac_upper_address(0), true, X"0000F04D");
      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_client_destination_port_address(0), true, std_logic_vector(to_unsigned(50247, 32)));
      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_client_delivery_interval_address(0), true,  std_logic_vector(to_unsigned(2, 32)));
      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_client_event_mask_address(0), true, X"00000004");

      WAIT FOR 50 us;
      WAIT UNTIL rising_edge(axi_clk);
      trigger_event(2) <= '1';
      trigger_event(6) <= '1';
      WAIT UNTIL rising_edge(axi_clk);
      trigger_event(2) <= '0';
      trigger_event(6) <= '0';


      WAIT UNTIL RISING_EDGE(new_packet);
      WAIT UNTIL rising_edge(axi_clk);
      ASSERT (dest_port = std_logic_vector(to_unsigned(50247, 16))) REPORT "Wrong destination port" SEVERITY failure;
      ASSERT (dest_ip = X"0A010504") REPORT "Wrong destination ip address" SEVERITY failure;
      ASSERT (dest_mac = X"F04DA2276E1C") REPORT "Wrong destination mac address" SEVERITY failure;
      ASSERT (event_data = X"00000004") REPORT "Unexpected event" SEVERITY failure;
      ASSERT (event_time = X"0000000000001A42") REPORT "Wrong event time" SEVERITY failure;

      -- 2ms delay

      WAIT UNTIL RISING_EDGE(new_packet);
      WAIT UNTIL rising_edge(axi_clk);
      ASSERT (dest_port = std_logic_vector(to_unsigned(50247, 16))) REPORT "Wrong destination port" SEVERITY failure;
      ASSERT (dest_ip = X"0A010504") REPORT "Wrong destination ip address" SEVERITY failure;
      ASSERT (dest_mac = X"F04DA2276E1C") REPORT "Wrong destination mac address" SEVERITY failure;
      ASSERT (event_data = X"00000004") REPORT "Unexpected event" SEVERITY failure;
      ASSERT (event_time = X"0000000000001A42") REPORT "Wrong event time" SEVERITY failure;

      -- Acknowledge the event
      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_client_control_acknowledge_address(0), true, X"00000001");

      REPORT "Finished Test 2" SEVERITY note;
      WAIT FOR 1 us;

      -------------------------------------------
      --                Test 3                 --
      -------------------------------------------
      -- Configure Client 2 for event 2 and 3 and trigger event
      -- 2 and 3. We should get packets from both clients
      -- Acknowledge after first packets

      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_client_destination_ip_address(1), true, X"0A010503");
      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_client_destination_mac_lower_address(1), true, X"A3276E1C");
      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_client_destination_mac_upper_address(1), true, X"0000F04D");
      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_client_destination_port_address(1), true, std_logic_vector(to_unsigned(50347, 32)));
      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_client_delivery_interval_address(1), true,  std_logic_vector(to_unsigned(2, 32)));
      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_client_event_mask_address(1), true, X"0000000c");


      WAIT FOR 15 us;
      WAIT UNTIL rising_edge(axi_clk);
      trigger_event(2) <= '1';
      trigger_event(3) <= '1';
      WAIT UNTIL rising_edge(axi_clk);
      trigger_event(2) <= '0';
      trigger_event(3) <= '0';

      test3_loop: FOR i IN 0 TO 1 LOOP
         WAIT UNTIL RISING_EDGE(new_packet);

         IF dest_port = std_logic_vector(to_unsigned(50347, 16)) THEN
            ASSERT (dest_ip = X"0A010503") REPORT "Wrong destination ip address" SEVERITY failure;
            ASSERT (dest_mac = X"F04DA3276E1C") REPORT "Wrong destination mac address" SEVERITY failure;
            ASSERT (event_data = X"0000000c") REPORT "Unexpected event" SEVERITY failure;
            ASSERT (event_time = X"000000000003F308") REPORT "Wrong event time" SEVERITY failure;
         ELSE
            ASSERT (dest_port = std_logic_vector(to_unsigned(50247, 16))) REPORT "Wrong destination port" SEVERITY failure;
            ASSERT (dest_ip = X"0A010504") REPORT "Wrong destination ip address" SEVERITY failure;
            ASSERT (dest_mac = X"F04DA2276E1C") REPORT "Wrong destination mac address" SEVERITY failure;
            ASSERT (event_data = X"00000004") REPORT "Unexpected event" SEVERITY failure;
            ASSERT (event_time = X"000000000003F308") REPORT "Wrong event time" SEVERITY failure;
         END IF;
      END LOOP test3_loop;

      -- Acknowledge the event
      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_client_control_acknowledge_address(0), true, X"00000001");

      -- Acknowledge the event
      axi_lite_transaction(axi_clk, s_axi_miso, s_axi_mosi, c_client_control_acknowledge_address(1), true, X"00000001");

      REPORT "Finished Test 3" SEVERITY note;
      WAIT FOR 1 us;






      tb_end <= '1';
      REPORT "Finished Simulation" SEVERITY note;
      WAIT;
   END PROCESS;






END testbench;