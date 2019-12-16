-------------------------------------------------------------------------------
--
-- File Name: tb_eth_tx.vhd
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

LIBRARY IEEE, common_lib, axi4_lib, technology_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.math_real.ALL;
USE IEEE.std_logic_textio.ALL;
USE STD.textio.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE technology_lib.technology_pkg.ALL;

ENTITY tb_eth_tx IS

END tb_eth_tx;

ARCHITECTURE testbench OF tb_eth_tx IS

  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   CONSTANT c_local_ip           : STD_LOGIC_VECTOR(31 DOWNTO 0) := X"0a010517";
   CONSTANT c_local_mac          : STD_LOGIC_VECTOR(47 DOWNTO 0) := X"001122334455";
   CONSTANT c_ifg_clocks         : INTEGER := 10;

   CONSTANT c_eth_tx_clk_period  : TIME := 2.56 ns;
   CONSTANT c_eth_rx_clk_period  : TIME := 2.56 ns;
   CONSTANT c_axi_clk_period     : TIME := 6.4 ns;


  ---------------------------------------------------------------------------
  -- SIGNAL DECLARATIONS  --
  ---------------------------------------------------------------------------

   SIGNAL eth_tx_clk                : STD_LOGIC := '0';
   SIGNAL eth_rx_clk                : STD_LOGIC := '1';
   SIGNAL axi_clk                   : STD_LOGIC := '0';

   SIGNAL eth_out_sosi              : t_axi4_sosi;
   SIGNAL eth_out_siso              : t_axi4_siso;
   SIGNAl framer_in_sosi            : t_axi4_sosi_arr(0 TO 5);
   SIGNAL framer_in_siso            : t_axi4_siso_arr(0 TO 5);

   SIGNAL eth_pause_rx_enable       : STD_LOGIC_VECTOR(8 downto 0);
   SIGNAL eth_pause_rx_req          : STD_LOGIC_VECTOR(8 downto 0);
   SIGNAL eth_pause_rx_ack          : STD_LOGIC_VECTOR(8 downto 0);

   -- Testbench
   SIGNAL reset                     : STD_LOGIC := '0';
   SIGNAL tb_end                    : STD_LOGIC := '0';
   SIGNAL tb_sucess                 : STD_LOGIC := '0';
   SIGNAL mac_ifg                   : INTEGER;
   SIGNAL mac_word_count_ely        : INTEGER;
   SIGNAL mac_word_count            : INTEGER;
   SIGNAL mac_word_count_dly        : INTEGER;
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

   -- ARP Generator
   SIGNAL send_arp                  : STD_LOGIC;
   SIGNAL sending_arp               : BOOLEAN;
   SIGNAL arp_payload               : INTEGER;

   -- ICMP Generator
   SIGNAL send_icmp                 : STD_LOGIC;
   SIGNAL sending_icmp              : BOOLEAN;
   SIGNAL icmp_payload              : INTEGER;

   -- UDP Generator
   SIGNAL send_udp                  : STD_LOGIC_VECTOR(0 TO 3);
   SIGNAL sending_udp               : t_boolean_arr(0 TO 3);
   SIGNAL udp_payload               : t_integer_arr(0 TO 3);

  ---------------------------------------------------------------------------
  -- STIMULUS DEFINITIONS  --
  ---------------------------------------------------------------------------

   CONSTANT c_arp_priority          : INTEGER := 7;
   CONSTANT c_arp_packet            : STD_LOGIC_VECTOR(9*73-1 DOWNTO 0) := "0" & X"FF" & X"1734ffffffffffff" &
                                                                           "0" & X"FF" & X"010006080ce4f0eb" &
                                                                           "0" & X"FF" & X"1100020004060008" &
                                                                           "0" & X"FF" & X"1705010a55443322" &
                                                                           "0" & X"FF" & X"050aff1032547698" &
                                                                           "1" & X"03" & X"0000000000000101" &
                                                                           "0" & X"00" & X"0000000000000000" &
                                                                           "0" & X"00" & X"0000000000000000" &
                                                                           "0" & X"00" & X"0000000000000000";


   CONSTANT c_icmp_priority         : INTEGER := 6;
   CONSTANT c_icmp_packet           : STD_LOGIC_VECTOR(18*73-1 DOWNTO 0) := "0" & X"FF" & X"0000ff1032547698" &
                                                                            "0" & X"FF" & X"0045000800000000" &
                                                                            "0" & X"FF" & X"014000009bd88000" &
                                                                            "0" & X"FF" & X"010a16cb050ac4c1" &
                                                                            "0" & X"FF" & X"88c0230e00000101" &
                                                                            "0" & X"FF" & X"165eb9200ddc0300" &
                                                                            "0" & X"FF" & X"c435f88bb190ca95" &
                                                                            "0" & X"FF" & X"b4eaf1d0e097d473" &
                                                                            "0" & X"FF" & X"2c268e4521dfe19d" &
                                                                            "0" & X"FF" & X"038181e34d36506d" &
                                                                            "0" & X"FF" & X"ee2fd32a44f8944e" &
                                                                            "0" & X"FF" & X"a1158512ff86158b" &
                                                                            "0" & X"FF" & X"b633bcbb8ddabdf3" &
                                                                            "0" & X"FF" & X"83b93b70ba20d0fb" &
                                                                            "0" & X"FF" & X"0160654e81db5d4a" &
                                                                            "0" & X"FF" & X"b0fe729d1c92e8a9" &
                                                                            "0" & X"FF" & X"d487c78aa91139e1" &
                                                                            "1" & X"3F" & X"000011042fb4f0eb";
   CONSTANT c_udp_priority          : INTEGER := 2;
   CONSTANT c_udp_packet            : STD_LOGIC_VECTOR(24*73-1 DOWNTO 0) := "0" & X"FF" & X"0000ff1032547698" &
                                                                            "0" & X"FF" & X"0045000800000000" &
                                                                            "0" & X"FF" & X"114000001ca2b200" &
                                                                            "0" & X"FF" & X"010a1705010a05be" &
                                                                            "0" & X"FF" & X"9e009bc511270101" &
                                                                            "0" & X"FF" & X"5f208dd28f3a19c7" &
                                                                            "0" & X"FF" & X"45f5decd6701770f" &
                                                                            "0" & X"FF" & X"c1b5e0a5f75cb815" &
                                                                            "0" & X"FF" & X"194ae62c71c94cb6" &
                                                                            "0" & X"FF" & X"9583c34b56203284" &
                                                                            "0" & X"FF" & X"5323301a561402a4" &
                                                                            "0" & X"FF" & X"f21620880f7124bf" &
                                                                            "0" & X"FF" & X"7237cad76f820ceb" &
                                                                            "0" & X"FF" & X"16ef6dd773654b29" &
                                                                            "0" & X"FF" & X"af898f95e1cd91da" &
                                                                            "0" & X"FF" & X"8e2ecffdb4b2e8de" &
                                                                            "0" & X"FF" & X"a4cafe7e6dc79c43" &
                                                                            "0" & X"FF" & X"ff8d1297b78a2bd3" &
                                                                            "0" & X"FF" & X"0ad2bd7b310b9f66" &
                                                                            "0" & X"FF" & X"5fb94d9d50855d80" &
                                                                            "0" & X"FF" & X"6a86bd62f9651d62" &
                                                                            "0" & X"FF" & X"ec2d8a0baf83f98d" &
                                                                            "0" & X"FF" & X"9562901c8e527895" &
                                                                            "1" & X"FF" & X"b52a165162724494";

   CONSTANT c_udp_long_priority     : INTEGER := 3;
   CONSTANT c_udp_packet_long       : STD_LOGIC_VECTOR(37*73-1 DOWNTO 0) := "0" & X"FF" & X"0000ff1032547698" &
                                                                            "0" & X"FF" & X"0045000800000000" &
                                                                            "0" & X"FF" & X"114000007a1d1601" &
                                                                            "0" & X"FF" & X"010a1705010a05be" &
                                                                            "0" & X"FF" & X"02019bc517270401" &
                                                                            "0" & X"FF" & X"5f208dd28f3a19c7" &
                                                                            "0" & X"FF" & X"45f5decd6701770f" &
                                                                            "0" & X"FF" & X"c1b5e0a5f75cb815" &
                                                                            "0" & X"FF" & X"194ae62c71c94cb6" &
                                                                            "0" & X"FF" & X"9583c34b56203284" &
                                                                            "0" & X"FF" & X"5323301a561402a4" &
                                                                            "0" & X"FF" & X"f21620880f7124bf" &
                                                                            "0" & X"FF" & X"7237cad76f820ceb" &
                                                                            "0" & X"FF" & X"16ef6dd773654b29" &
                                                                            "0" & X"FF" & X"af898f95e1cd91da" &
                                                                            "0" & X"FF" & X"8e2ecffdb4b2e8de" &
                                                                            "0" & X"FF" & X"a4cafe7e6dc79c43" &
                                                                            "0" & X"FF" & X"ff8d1297b78a2bd3" &
                                                                            "0" & X"FF" & X"0ad2bd7b310b9f66" &
                                                                            "0" & X"FF" & X"5fb94d9d50855d80" &
                                                                            "0" & X"FF" & X"6a86bd62f9651d62" &
                                                                            "0" & X"FF" & X"ec2d8a0baf83f98d" &
                                                                            "0" & X"FF" & X"9562901c8e527895" &
                                                                            "0" & X"FF" & X"b52a165162724494" &
                                                                            "0" & X"FF" & X"4d2212218a02903f" &
                                                                            "0" & X"FF" & X"7d50dfba91431e78" &
                                                                            "0" & X"FF" & X"bbd67a72f98a0950" &
                                                                            "0" & X"FF" & X"0f5620d65c9ceee6" &
                                                                            "0" & X"FF" & X"aaad334d5bd204f9" &
                                                                            "0" & X"FF" & X"d06b948c6ab1908b" &
                                                                            "0" & X"FF" & X"9fc10d48c898ec7b" &
                                                                            "0" & X"FF" & X"e6bdd4bf7e3c47ab" &
                                                                            "0" & X"FF" & X"3ed92c95982771e3" &
                                                                            "0" & X"FF" & X"0805cfcb003b4003" &
                                                                            "0" & X"FF" & X"e774a99b439bd7ba" &
                                                                            "0" & X"FF" & X"91f97b1e7067e6b8" &
                                                                            "1" & X"0f" & X"00000000cc962f9d";

BEGIN

   tb_end <= '1' AFTER 20 us;

   PROCESS
   BEGIN
      WAIT UNTIL falling_edge(tb_end);
      ASSERT tb_sucess = '1' REPORT "Test Failed" SEVERITY ERROR;
   END PROCESS;

---------------------------------------------------------------------------
-- Clocks  --
---------------------------------------------------------------------------

   eth_tx_clk <= NOT eth_tx_clk OR tb_end AFTER c_eth_tx_clk_period/2;

   eth_rx_clk <= NOT eth_rx_clk OR tb_end AFTER c_eth_rx_clk_period/2;

   axi_clk <= NOT axi_clk or tb_end AFTER c_axi_clk_period/2;

---------------------------------------------------------------------------
-- DUT  --
---------------------------------------------------------------------------

dut: ENTITY work.eth_tx
     GENERIC MAP (g_technology            => c_tech_gemini,
                  g_num_frame_inputs      => 6,
                  g_max_packet_length     => 8192,
                  g_lane_priority         => (c_arp_priority, c_icmp_priority, 0, c_udp_priority, c_udp_long_priority, c_udp_priority, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1))
     PORT MAP (eth_tx_clk                 => eth_tx_clk,
               eth_rx_clk                 => eth_rx_clk,
               axi_clk                    => axi_clk,
               axi_rst                    => reset,
               eth_tx_rst                 => reset,
               eth_address_ip             => c_local_ip,
               eth_address_mac            => c_local_mac,
               eth_pause_rx_enable        => eth_pause_rx_enable,
               eth_pause_rx_req           => eth_pause_rx_req,
               eth_pause_rx_ack           => eth_pause_rx_ack,
               eth_out_sosi               => eth_out_sosi,
               eth_out_siso               => eth_out_siso,
               framer_in_sosi             => framer_in_sosi,
               framer_in_siso             => framer_in_siso);

---------------------------------------------------------------------------
-- Packet Decoder  --
---------------------------------------------------------------------------
-- Generate textual descriptions of the packets

pkt_decode: ENTITY work.packet_decoder
            PORT MAP (clk           => eth_tx_clk,
                      reset         => reset,
                      eth_out_sosi  => eth_out_sosi,
                      eth_out_siso  => eth_out_siso);

---------------------------------------------------------------------------
-- Traffic Generators  --
---------------------------------------------------------------------------

arp_control: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         IF sending_arp = TRUE THEN
            IF framer_in_siso(0).tready = '1' THEN
               IF arp_payload = 0 THEN
                  sending_arp <= FALSE;
               ELSE
                  arp_payload <= arp_payload - 1;
               END IF;
            END IF;
         ELSE
            IF send_arp = '1' THEN
               sending_arp <= TRUE;
               arp_payload <= ((c_arp_packet'LEFT+1)/73)-1;
            END IF;
         END IF;
      END IF;
   END PROCESS;

   framer_in_sosi(0).tvalid <= '1' WHEN sending_arp = TRUE ELSE '0';

arp_data: PROCESS(arp_payload, sending_arp)
   BEGIN
      IF sending_arp = TRUE THEN
         framer_in_sosi(0).tdata(63 DOWNTO 0) <= c_arp_packet((arp_payload*73)+63 downto (arp_payload*73)+0);
         framer_in_sosi(0).tkeep(7 DOWNTO 0) <= c_arp_packet((arp_payload*73)+71 downto (arp_payload*73)+64);
         framer_in_sosi(0).tlast <= c_arp_packet((arp_payload*73)+72);
      ELSE
         framer_in_sosi(0).tdata(63 DOWNTO 0) <= X"0000000000000000";
         framer_in_sosi(0).tkeep(7 DOWNTO 0) <= X"00";
         framer_in_sosi(0).tlast <= '0';
      END IF;
   END PROCESS;


icmp_control: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         IF sending_icmp = TRUE THEN
            IF framer_in_siso(1).tready = '1' THEN
               IF icmp_payload = 0 THEN
                  sending_icmp <= FALSE;
               ELSE
                  icmp_payload <= icmp_payload - 1;
               END IF;
            END IF;
         ELSE
            IF send_icmp = '1' THEN
               sending_icmp <= TRUE;
               icmp_payload <= ((c_icmp_packet'LEFT+1)/73)-1;
            END IF;
         END IF;
      END IF;
   END PROCESS;

   framer_in_sosi(1).tvalid <= '1' WHEN sending_icmp = TRUE ELSE '0';

icmp_data: PROCESS(icmp_payload, sending_icmp)
   BEGIN
      IF sending_icmp = TRUE THEN
         framer_in_sosi(1).tdata(63 DOWNTO 0) <= c_icmp_packet((icmp_payload*73)+63 downto (icmp_payload*73)+0);
         framer_in_sosi(1).tkeep(7 DOWNTO 0) <= c_icmp_packet((icmp_payload*73)+71 downto (icmp_payload*73)+64);
         framer_in_sosi(1).tlast <= c_icmp_packet((icmp_payload*73)+72);
      ELSE
         framer_in_sosi(1).tdata(63 DOWNTO 0) <= X"0000000000000000";
         framer_in_sosi(1).tkeep(7 DOWNTO 0) <= X"00";
         framer_in_sosi(1).tlast <= '0';
      END IF;
   END PROCESS;



UDP_TRANSMIT_GEN: FOR i IN 0 to 3 GENERATE
   udp_control: PROCESS(axi_clk)
      BEGIN
         IF RISING_EDGE(axi_clk) THEN
            IF sending_udp(i) = TRUE THEN
               IF framer_in_siso(2+i).tready = '1' THEN

                  IF udp_payload(i) = 0 THEN
                     sending_udp(i) <= FALSE;
                  ELSE
                     udp_payload(i) <= udp_payload(i) - 1;
                  END IF;
               END IF;
            ELSE
               IF send_udp(i) = '1' THEN
                  sending_udp(i) <= TRUE;
                  IF i = 2 THEN
                     udp_payload(i) <= ((c_udp_packet_long'LEFT+1)/73)-1;
                  ELSE
                     udp_payload(i) <= ((c_udp_packet'LEFT+1)/73)-1;
                  END IF;
               END IF;
            END IF;
         END IF;
      END PROCESS;

      framer_in_sosi(2+i).tvalid <= '1' WHEN sending_udp(i) = TRUE ELSE '0';

   udp_data: PROCESS(udp_payload(i), sending_udp(i))
      BEGIN
         IF sending_udp(i) = TRUE THEN
            IF i = 2 THEN
               framer_in_sosi(2+i).tdata(63 DOWNTO 0) <= c_udp_packet_long((udp_payload(i)*73)+63 downto (udp_payload(i)*73)+0);
               framer_in_sosi(2+i).tkeep(7 DOWNTO 0) <= c_udp_packet_long((udp_payload(i)*73)+71 downto (udp_payload(i)*73)+64);
               framer_in_sosi(2+i).tlast <= c_udp_packet_long((udp_payload(i)*73)+72);
            ELSE
               IF udp_payload(i) = 19 THEN
                  -- Customise the IP address and port per lane
                  framer_in_sosi(2+i).tdata(15 DOWNTO 0) <= STD_LOGIC_VECTOR(UNSIGNED(c_udp_packet((udp_payload(i)*73)+15 downto (udp_payload(i)*73)+0)) + TO_UNSIGNED(i, 16));
                  framer_in_sosi(2+i).tdata(31 DOWNTO 16) <= STD_LOGIC_VECTOR(UNSIGNED(c_udp_packet((udp_payload(i)*73)+31 downto (udp_payload(i)*73)+16)) + TO_UNSIGNED(i*256, 16));
                  framer_in_sosi(2+i).tdata(63 DOWNTO 32) <= c_udp_packet((udp_payload(i)*73)+63 downto (udp_payload(i)*73)+32);
               ELSE
                  framer_in_sosi(2+i).tdata(63 DOWNTO 0) <= c_udp_packet((udp_payload(i)*73)+63 downto (udp_payload(i)*73)+0);
               END IF;

               framer_in_sosi(2+i).tkeep(7 DOWNTO 0) <= c_udp_packet((udp_payload(i)*73)+71 downto (udp_payload(i)*73)+64);
               framer_in_sosi(2+i).tlast <= c_udp_packet((udp_payload(i)*73)+72);
            END IF;
         ELSE
            framer_in_sosi(2+i).tdata(63 DOWNTO 0) <= X"0000000000000000";
            framer_in_sosi(2+i).tkeep(7 DOWNTO 0) <= X"00";
            framer_in_sosi(2+i).tlast <= '0';
         END IF;
      END PROCESS;

END GENERATE;


---------------------------------------------------------------------------
-- Transmit MAC Reciever  --
---------------------------------------------------------------------------

tx_mac: PROCESS(eth_tx_clk)
   BEGIN
      IF RISING_EDGE(eth_tx_clk) THEN
         mac_word_count <= mac_word_count_ely;
         mac_recieving <= mac_recieving_ely;
         mac_valid <= mac_valid_ely;

         mac_recieving_dly <= mac_recieving;

         -- Gap counter between frames
         IF mac_ifg /= 0 THEN
            mac_ifg <= mac_ifg - 1;
         END IF;

         IF reset = '1' THEN
            mac_recieving_ely <= FALSE;
            mac_word_count_ely <= 0;
            mac_ifg <= 0;
         ELSE
            -- Enable
            IF mac_recieving_ely = FALSE THEN
               IF eth_out_sosi.tvalid = '1' AND mac_ifg = 0 THEN
                  mac_recieving_ely <= TRUE;
               END IF;
            END IF;

            -- Used to insert random tready deassertions
            IF mac_recieving = FALSE THEN
               transaction_cycle_count <= 0;
            ELSE
               transaction_cycle_count <= transaction_cycle_count + 1;
            END IF;

            IF eth_out_sosi.tvalid = '1' AND eth_out_siso.tready = '1' THEN

               -- Count words in packet (for decoding)
               IF mac_recieving_ely = FALSE THEN
                  mac_word_count_ely <= 1;
               ELSE
                  mac_word_count_ely <= mac_word_count_ely + 1;
               END IF;

               -- Go back to big endian and store 2 words incase fields cross boundaries
               mac_word_long <= mac_word_long(191 DOWNTO 0) &
                                eth_out_sosi.tdata(7 DOWNTO 0) &
                                eth_out_sosi.tdata(15 DOWNTO 8) &
                                eth_out_sosi.tdata(23 DOWNTO 16) &
                                eth_out_sosi.tdata(31 DOWNTO 24) &
                                eth_out_sosi.tdata(39 DOWNTO 32) &
                                eth_out_sosi.tdata(47 DOWNTO 40) &
                                eth_out_sosi.tdata(55 DOWNTO 48) &
                                eth_out_sosi.tdata(63 DOWNTO 56);

               mac_keep_long <= mac_keep_long(23 downto 0) &
                                eth_out_sosi.tkeep(0) &
                                eth_out_sosi.tkeep(1) &
                                eth_out_sosi.tkeep(2) &
                                eth_out_sosi.tkeep(3) &
                                eth_out_sosi.tkeep(4) &
                                eth_out_sosi.tkeep(5) &
                                eth_out_sosi.tkeep(6) &
                                eth_out_sosi.tkeep(7);

               -- Stop receiving and insert gap
               IF eth_out_sosi.tlast = '1' THEN
                  mac_ifg <= c_ifg_clocks;
                  mac_recieving_ely <= FALSE;
                  mac_word_count_ely <= 0;
               END IF;
            END IF;
         END IF;
      END IF;
   END PROCESS;

   mac_valid_ely <= eth_out_sosi.tvalid and eth_out_siso.tready when mac_recieving_ely = TRUE ELSE '0';

read_randomiser: PROCESS(eth_tx_clk)
      VARIABLE seed1    : POSITIVE     := 52548;
      VARIABLE seed2    : POSITIVE     := 5087986;
      VARIABLE rand1    : REAL         := 0.5;                 -- random real-number value in range 0 to 1.0
   BEGIN
      IF RISING_EDGE(eth_tx_clk) THEN
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
   eth_out_siso.tready <= '0' WHEN mac_ifg > 0 ELSE
                          '1' WHEN mac_recieving_ely = FALSE OR mac_word_count_ely < 1 ELSE
                          mac_tready;

---------------------------------------------------------------------------
-- RX Code  --
---------------------------------------------------------------------------

protocol_check: PROCESS(eth_tx_clk)
   BEGIN
      IF RISING_EDGE(eth_tx_clk) THEN
         mac_word_count_dly <= mac_word_count;
         IF mac_recieving = TRUE THEN
            ASSERT (eth_out_sosi.tlast = '0' OR mac_keep_long(7 DOWNTO 0) /= X"00" ) REPORT "PROTOCOL: Last asserted with tkeep zero" SEVERITY failure;

         ELSE
            IF mac_recieving_dly = TRUE THEN
               ASSERT mac_word_count_dly > 7 REPORT "Packet too short" SEVERITY failure;
            END IF;
         END IF;
      END IF;
   END PROCESS;


arp_verify: PROCESS(eth_tx_clk)
   BEGIN
      IF RISING_EDGE(eth_tx_clk) THEN
         IF mac_recieving = TRUE THEN
            IF mac_valid = '1' AND (arp_detected = TRUE OR mac_word_count = 2) THEN
               CASE mac_word_count IS
                  WHEN 2 =>
                     IF mac_word_long(63 DOWNTO 48) = X"0806" THEN
                        arp_detected <= TRUE;

                        -- Check MAC Fields
                        ASSERT (mac_word_long(143 DOWNTO 96) = c_local_mac) REPORT "ARP: Wrong Source MAC" SEVERITY failure;
                        ASSERT (mac_word_long(79 DOWNTO 77) = std_logic_vector(to_unsigned(c_arp_priority, 3))) REPORT "ARP: Wrong Priority" SEVERITY failure;

                        -- Check Other fields
                        ASSERT (mac_word_long(47 DOWNTO 40) = c_arp_packet(((((c_arp_packet'LEFT+1)/73)-2)*73) +55 DOWNTO ((((c_arp_packet'LEFT+1)/73)-2)*73) +48)) REPORT "ARP: Payload Incorrect" SEVERITY failure;
                        ASSERT (mac_word_long(39 DOWNTO 32) = c_arp_packet(((((c_arp_packet'LEFT+1)/73)-2)*73) +63 DOWNTO ((((c_arp_packet'LEFT+1)/73)-2)*73) +56)) REPORT "ARP: Payload Incorrect" SEVERITY failure;
                        ASSERT (mac_word_long(31 DOWNTO 24) = c_arp_packet(((((c_arp_packet'LEFT+1)/73)-3)*73) +7  DOWNTO ((((c_arp_packet'LEFT+1)/73)-3)*73) +0))  REPORT "ARP: Payload Incorrect" SEVERITY failure;
                        ASSERT (mac_word_long(23 DOWNTO 16) = c_arp_packet(((((c_arp_packet'LEFT+1)/73)-3)*73) +15 DOWNTO ((((c_arp_packet'LEFT+1)/73)-3)*73) +8))  REPORT "ARP: Payload Incorrect" SEVERITY failure;
                        ASSERT (mac_word_long(15 DOWNTO 8)  = c_arp_packet(((((c_arp_packet'LEFT+1)/73)-3)*73) +23 DOWNTO ((((c_arp_packet'LEFT+1)/73)-3)*73) +16)) REPORT "ARP: Payload Incorrect" SEVERITY failure;
                        ASSERT (mac_word_long(7 DOWNTO 0)   = c_arp_packet(((((c_arp_packet'LEFT+1)/73)-3)*73) +31 DOWNTO ((((c_arp_packet'LEFT+1)/73)-3)*73) +24)) REPORT "ARP: Payload Incorrect" SEVERITY failure;
                     END IF;
                  WHEN OTHERS =>
                     FOR i IN 7 DOWNTO 0 LOOP
                        -- Check byte by byte for payload after MAC header
                        IF mac_keep_long(i) = '1' THEN
                           IF i = 7 or i = 6 or i = 5 or i = 4 THEN
                              ASSERT (mac_word_long(i*8+7 DOWNTO i*8) = c_arp_packet((((((c_arp_packet'LEFT+1)/73)-mac_word_count)*73) +63-(i-4)*8) DOWNTO ((((c_arp_packet'LEFT+1)/73)-mac_word_count)*73) +56-(i-4)*8)) REPORT "ARP: Payload Incorrect" SEVERITY failure;
                           ELSE
                              ASSERT (mac_word_long(i*8+7 DOWNTO i*8) = c_arp_packet((((((c_arp_packet'LEFT+1)/73)-mac_word_count-1)*73) +31-i*8) DOWNTO ((((c_arp_packet'LEFT+1)/73)-mac_word_count-1)*73) +24-i*8)) REPORT "ARP: Payload Incorrect" SEVERITY failure;
                           END IF;
                        END IF;
                     END LOOP;
               END CASE;
            END IF;
         ELSE
            arp_detected <= FALSE;
         END IF;
      END IF;
   END PROCESS;

icmp_verify: PROCESS(eth_tx_clk)
      VARIABLE crc         : UNSIGNED(31 DOWNTO 0);
   BEGIN
      IF RISING_EDGE(eth_tx_clk) THEN
         IF mac_recieving = TRUE THEN
            IF mac_valid = '1' AND (icmp_detected = TRUE OR mac_word_count = 3) THEN
               CASE mac_word_count IS
                  WHEN 3 =>
                     IF mac_word_long(127 DOWNTO 112) = X"0800" AND mac_word_long(39 DOWNTO 32) = X"01" THEN
                        icmp_detected <= TRUE;

                        -- Check MAC Fields
                        ASSERT (mac_word_long(207 DOWNTO 160) = c_local_mac) REPORT "ICMP: Wrong Source MAC" SEVERITY failure;
                        ASSERT (mac_word_long(143 DOWNTO 141) = std_logic_vector(to_unsigned(c_icmp_priority, 3))) REPORT "ICMP: Wrong Priority" SEVERITY failure;
                     END IF;
                  WHEN 4 =>
                        -- Check IP fields
                        ASSERT (mac_word_long(79 DOWNTO 48) = c_local_ip) REPORT "ICMP: Wrong Source IP" SEVERITY failure;

                        -- Check IP CRC
                        crc := (X"0000" & UNSIGNED(mac_word_long(175 DOWNTO 160))) +
                               (X"0000" & UNSIGNED(mac_word_long(159 DOWNTO 144))) +
                               (X"0000" & UNSIGNED(mac_word_long(143 DOWNTO 128))) +
                               (X"0000" & UNSIGNED(mac_word_long(127 DOWNTO 112))) +
                               (X"0000" & UNSIGNED(mac_word_long(111 DOWNTO 96))) +
                               (X"0000" & UNSIGNED(mac_word_long(95 DOWNTO 80))) +
                               (X"0000" & UNSIGNED(mac_word_long(79 DOWNTO 64))) +
                               (X"0000" & UNSIGNED(mac_word_long(63 DOWNTO 48))) +
                               (X"0000" & UNSIGNED(mac_word_long(47 DOWNTO 32))) +
                               (X"0000" & UNSIGNED(mac_word_long(31 DOWNTO 16)));

                        crc := (X"0000" & crc(31 DOWNTO 16)) + (X"0000" & crc(15 DOWNTO 0));
                        crc := (X"0000" & crc(31 DOWNTO 16)) + (X"0000" & crc(15 DOWNTO 0));
                        ASSERT (crc = X"0000FFFF") REPORT "ICMP: IP Header Checksum wrong" SEVERITY failure;

                        -- Check ICMP header & payload
                        ASSERT (mac_word_long(15 DOWNTO 8)  = c_icmp_packet(((((c_icmp_packet'LEFT+1)/73)-5)*73) +23 DOWNTO ((((c_icmp_packet'LEFT+1)/73)-5)*73) +16)) REPORT "ICMP: Payload Incorrect" SEVERITY failure;
                        ASSERT (mac_word_long(7 DOWNTO 0)   = c_icmp_packet(((((c_icmp_packet'LEFT+1)/73)-5)*73) +31 DOWNTO ((((c_icmp_packet'LEFT+1)/73)-5)*73) +24)) REPORT "ICMP: Payload Incorrect" SEVERITY failure;
                  WHEN OTHERS =>
                     FOR i IN 7 DOWNTO 0 LOOP
                        -- Check byte by byte for payload after MAC header
                        IF mac_keep_long(i) = '1' THEN
                           IF i = 7 or i = 6 or i = 5 or i = 4 THEN
                              ASSERT (mac_word_long(i*8+7 DOWNTO i*8) = c_icmp_packet((((((c_icmp_packet'LEFT+1)/73)-mac_word_count)*73) +63-(i-4)*8) DOWNTO ((((c_icmp_packet'LEFT+1)/73)-mac_word_count)*73) +56-(i-4)*8)) REPORT "ICMP: Payload Incorrect" SEVERITY failure;
                           ELSE
                              ASSERT (mac_word_long(i*8+7 DOWNTO i*8) = c_icmp_packet((((((c_icmp_packet'LEFT+1)/73)-mac_word_count-1)*73) +31-i*8) DOWNTO ((((c_icmp_packet'LEFT+1)/73)-mac_word_count-1)*73) +24-i*8)) REPORT "ICMP: Payload Incorrect" SEVERITY failure;
                           END IF;
                        END IF;
                     END LOOP;
               END CASE;
            END IF;
         ELSE
            icmp_detected <= FALSE;
         END IF;
      END IF;
   END PROCESS;



udp_verify: PROCESS(eth_tx_clk)
      VARIABLE ip_crc         : UNSIGNED(31 DOWNTO 0);
      VARIABLE udp_crc        : UNSIGNED(31 DOWNTO 0);
      VARIABLE crc_term       : UNSIGNED(15 DOWNTO 0);
      VARIABLE udp_length     : STD_LOGIC_VECTOR(15 DOWNTO 0);
   BEGIN
      IF RISING_EDGE(eth_tx_clk) THEN
         IF mac_recieving = TRUE THEN
            IF mac_valid = '1' AND (udp_detected = TRUE OR mac_word_count = 3) THEN
               CASE mac_word_count IS
                  WHEN 3 =>
                     IF mac_word_long(127 DOWNTO 112) = X"0800" AND mac_word_long(39 DOWNTO 32) = X"11" THEN
                        udp_detected <= TRUE;

                        -- Check MAC Fields
                        ASSERT (mac_word_long(207 DOWNTO 160) = c_local_mac) REPORT "UDP: Wrong Source MAC" SEVERITY failure;
                        ASSERT (mac_word_long(143 DOWNTO 141) = std_logic_vector(to_unsigned(c_udp_priority, 3)) OR
                                mac_word_long(143 DOWNTO 141) = std_logic_vector(to_unsigned(0, 3)) OR
                                mac_word_long(143 DOWNTO 141) = std_logic_vector(to_unsigned(c_udp_long_priority, 3))) REPORT "UDP: Wrong Priority" SEVERITY failure;
                     END IF;
                  WHEN 4 =>
                        -- Check IP fields
                        ASSERT (mac_word_long(79 DOWNTO 48) = c_local_ip) REPORT "UDP: Wrong Source IP" SEVERITY failure;

                        -- Check IP CRC
                        ip_crc := (X"0000" & UNSIGNED(mac_word_long(175 DOWNTO 160))) +
                               (X"0000" & UNSIGNED(mac_word_long(159 DOWNTO 144))) +
                               (X"0000" & UNSIGNED(mac_word_long(143 DOWNTO 128))) +
                               (X"0000" & UNSIGNED(mac_word_long(127 DOWNTO 112))) +
                               (X"0000" & UNSIGNED(mac_word_long(111 DOWNTO 96))) +
                               (X"0000" & UNSIGNED(mac_word_long(95 DOWNTO 80))) +
                               (X"0000" & UNSIGNED(mac_word_long(79 DOWNTO 64))) +
                               (X"0000" & UNSIGNED(mac_word_long(63 DOWNTO 48))) +
                               (X"0000" & UNSIGNED(mac_word_long(47 DOWNTO 32))) +
                               (X"0000" & UNSIGNED(mac_word_long(31 DOWNTO 16)));

                        ip_crc := (X"0000" & ip_crc(31 DOWNTO 16)) + (X"0000" & ip_crc(15 DOWNTO 0));
                        ASSERT (ip_crc = X"0000FFFF") REPORT "UDP: IP Header Checksum wrong" SEVERITY failure;

                        -- Start UDP header calc
                        udp_crc := (X"0000" & UNSIGNED(mac_word_long(79 DOWNTO 64))) +
                                   (X"0000" & UNSIGNED(mac_word_long(63 DOWNTO 48))) +
                                   (X"0000" & UNSIGNED(mac_word_long(47 DOWNTO 32))) +
                                   (X"0000" & UNSIGNED(mac_word_long(31 DOWNTO 16))) +
                                   (X"0000" & UNSIGNED(mac_word_long(15 DOWNTO 0))) +
                                   (X"00000011");

                        --mac_word_long(15 DOWNTO 0) source port

                  WHEN 5 =>

                        --mac_word_long(63 DOWNTO 48) dest port
                        --mac_word_long(47 DOWNTO 32) length

                        udp_length := mac_word_long(47 DOWNTO 32);

                        udp_crc := udp_crc +
                                    (X"0000" & UNSIGNED(mac_word_long(63 DOWNTO 48))) +
                                    (X"0000" & UNSIGNED(mac_word_long(47 DOWNTO 32))) +         -- Length added twice (1 for pseudo header, 1 for udp header)
                                    (X"0000" & UNSIGNED(mac_word_long(47 DOWNTO 32))) +
                                    (X"0000" & UNSIGNED(mac_word_long(31 DOWNTO 16)));

                        -- Start Of Payload
                        length_check: FOR i IN 0 TO 1 LOOP
                           IF mac_keep_long(i) = '1' THEN
                              IF udp_length = X"0102" THEN
                                 ASSERT (mac_word_long(i*8+7 DOWNTO i*8) = c_udp_packet_long((((((c_udp_packet_long'LEFT+1)/73)-mac_word_count-1)*73) +31-i*8) DOWNTO ((((c_udp_packet_long'LEFT+1)/73)-mac_word_count-1)*73) +24-i*8)) REPORT "UDP: Payload Incorrect" SEVERITY failure;
                              ELSE
                                 ASSERT (mac_word_long(i*8+7 DOWNTO i*8) = c_udp_packet((((((c_udp_packet'LEFT+1)/73)-mac_word_count-1)*73) +31-i*8) DOWNTO ((((c_udp_packet'LEFT+1)/73)-mac_word_count-1)*73) +24-i*8)) REPORT "UDP: Payload Incorrect" SEVERITY failure;
                              END IF;
                              crc_term(i*8+7 DOWNTO i*8) := UNSIGNED(mac_word_long(i*8+7 DOWNTO i*8));
                           ELSE
                              crc_term(i*8+7 DOWNTO i*8) := (others => '0');
                           END IF;
                        END LOOP;

                        udp_crc := udp_crc + (X"0000" & crc_term);
                  WHEN OTHERS =>
                     FOR i IN 7 DOWNTO 0 LOOP
                        -- Check byte by byte for payload after MAC header
                        IF mac_keep_long(i) = '1' THEN
                           IF i = 7 or i = 6 or i = 5 or i = 4 THEN
                              IF udp_length = X"0102" THEN
                                 ASSERT (mac_word_long(i*8+7 DOWNTO i*8) = c_udp_packet_long((((((c_udp_packet_long'LEFT+1)/73)-mac_word_count)*73) +63-(i-4)*8) DOWNTO ((((c_udp_packet_long'LEFT+1)/73)-mac_word_count)*73) +56-(i-4)*8)) REPORT "UDP: Payload Incorrect" SEVERITY failure;
                              ELSE
                                 ASSERT (mac_word_long(i*8+7 DOWNTO i*8) = c_udp_packet((((((c_udp_packet'LEFT+1)/73)-mac_word_count)*73) +63-(i-4)*8) DOWNTO ((((c_udp_packet'LEFT+1)/73)-mac_word_count)*73) +56-(i-4)*8)) REPORT "UDP: Payload Incorrect" SEVERITY failure;
                              END IF;
                           ELSE
                              IF udp_length = X"0102" THEN
                                 ASSERT (mac_word_long(i*8+7 DOWNTO i*8) = c_udp_packet_long((((((c_udp_packet_long'LEFT+1)/73)-mac_word_count-1)*73) +31-i*8) DOWNTO ((((c_udp_packet_long'LEFT+1)/73)-mac_word_count-1)*73) +24-i*8)) REPORT "UDP: Payload Incorrect" SEVERITY failure;
                              ELSE
                                 ASSERT (mac_word_long(i*8+7 DOWNTO i*8) = c_udp_packet((((((c_udp_packet'LEFT+1)/73)-mac_word_count-1)*73) +31-i*8) DOWNTO ((((c_udp_packet'LEFT+1)/73)-mac_word_count-1)*73) +24-i*8)) REPORT "UDP: Payload Incorrect" SEVERITY failure;
                              END IF;
                           END IF;

                           -- CRC Check
                           IF i MOD 2 = 1 THEN
                              crc_term(15 DOWNTO 8) := UNSIGNED(mac_word_long(i*8+7 DOWNTO i*8));
                           ELSE
                              crc_term(7 DOWNTO 0) := UNSIGNED(mac_word_long(i*8+7 DOWNTO i*8));
                           END IF;
                        ELSE
                           IF i MOD 2 = 1 THEN
                              crc_term(15 DOWNTO 8) := (OTHERS => '0');
                           ELSE
                              crc_term(7 DOWNTO 0) := (OTHERS => '0');
                           END IF;
                        END IF;

                        -- CRC Addition
                        IF i MOD 2 = 0 THEN
                           udp_crc := udp_crc + (X"0000" & crc_term);
                        END IF;
                     END LOOP;
               END CASE;
            END IF;
         ELSE
            IF mac_recieving_dly = TRUE AND udp_detected = TRUE THEN
               udp_crc := (X"0000" & udp_crc(31 downto 16)) + (X"0000" & udp_crc(15 downto 0));

               ASSERT (udp_crc = X"0000FFFF") REPORT "UDP: UDP Header Checksum wrong" SEVERITY failure;
            END IF;

            udp_detected <= FALSE;
         END IF;
      END IF;
   END PROCESS;


   -- Verify port

---------------------------------------------------------------------------
-- Test Script  --
---------------------------------------------------------------------------

tb_stim: PROCESS
   BEGIN
      eth_pause_rx_req <= (OTHERS => '0');
      send_arp <= '0';
      reset <= '0';
      WAIT FOR 100 ns;
      reset <= '1';
      WAIT FOR 100 ns;
      reset <= '0';
      WAIT FOR 500 ns;

      ASSERT(eth_pause_rx_enable = "111001101") REPORT "Priority Enables wrong" SEVERITY failure;

      -- Test Transmisison
      WAIT UNTIL RISING_EDGE(axi_clk);
      send_arp <= '1';
      send_icmp <= '1';
      send_udp(0) <= '1';
      send_udp(1) <= '1';
      send_udp(2) <= '1';
      send_udp(3) <= '1';
      WAIT UNTIL RISING_EDGE(axi_clk);
      send_arp <= '0';
      send_icmp <= '0';
      send_udp(0) <= '0';
      send_udp(1) <= '0';
      send_udp(2) <= '0';
      send_udp(3) <= '0';
      WAIT UNTIL RISING_EDGE(axi_clk);
      WAIT UNTIL RISING_EDGE(axi_clk);

      WAIT UNTIL sending_arp = FALSE AND
                 sending_icmp = FALSE AND
                 sending_udp(0) = FALSE AND
                 sending_udp(1) = FALSE AND
                 sending_udp(2) = FALSE AND
                 sending_udp(3) = FALSE;

      -- Send sequentially a couple
      WAIT UNTIL RISING_EDGE(axi_clk);
      send_udp(0) <= '1';
      WAIT UNTIL RISING_EDGE(axi_clk);
      send_udp(0) <= '0';
      WAIT UNTIL RISING_EDGE(axi_clk);
      WAIT UNTIL RISING_EDGE(axi_clk);

      WAIT UNTIL sending_udp(0) = FALSE;

      WAIT UNTIL RISING_EDGE(axi_clk);
      send_icmp <= '1';
      WAIT UNTIL RISING_EDGE(axi_clk);
      send_icmp <= '0';
      WAIT UNTIL RISING_EDGE(axi_clk);
      WAIT UNTIL RISING_EDGE(axi_clk);

      WAIT UNTIL sending_icmp = FALSE;

      WAIT UNTIL RISING_EDGE(axi_clk);
      send_udp(2) <= '1';
      send_udp(3) <= '1';
      WAIT UNTIL RISING_EDGE(axi_clk);
      send_udp(2) <= '0';
      send_udp(3) <= '0';
      WAIT UNTIL RISING_EDGE(axi_clk);
      WAIT UNTIL RISING_EDGE(axi_clk);

      WAIT UNTIL sending_udp(2) = FALSE AND sending_udp(3) = FALSE;

      WAIT FOR 5 us;

      -- Request Pause on 3 and then issue TX

      WAIT UNTIL RISING_EDGE(axi_clk);
      send_udp(2) <= '1';
      WAIT UNTIL RISING_EDGE(axi_clk);
      send_udp(2) <= '0';
      WAIT UNTIL RISING_EDGE(axi_clk);
      WAIT UNTIL RISING_EDGE(axi_clk);

      WAIT UNTIL sending_udp(2) = FALSE;


      WAIT UNTIL RISING_EDGE(eth_rx_clk);
      eth_pause_rx_req(3) <= '1';
      WAIT UNTIL RISING_EDGE(eth_rx_clk);
      WAIT UNTIL RISING_EDGE(eth_pause_rx_ack(3));

      WAIT UNTIL RISING_EDGE(axi_clk);
      send_udp(2) <= '1';
      WAIT UNTIL RISING_EDGE(axi_clk);
      send_udp(2) <= '0';
      WAIT UNTIL RISING_EDGE(axi_clk);
      WAIT UNTIL RISING_EDGE(axi_clk);

      -- Hold for a while
      WAIT FOR 5 us;

      WAIT UNTIL RISING_EDGE(eth_rx_clk);
      eth_pause_rx_req(3) <= '0';
      WAIT UNTIL RISING_EDGE(eth_rx_clk);

      WAIT UNTIL sending_udp(2) = FALSE;

      WAIT;
   END PROCESS;

tb_result: PROCESS
   BEGIN
      -- Should get packets in right order

      WAIT UNTIL FALLING_EDGE(arp_detected);
      WAIT UNTIL FALLING_EDGE(icmp_detected);
      WAIT UNTIL FALLING_EDGE(udp_detected);
      WAIT UNTIL FALLING_EDGE(udp_detected);
      WAIT UNTIL FALLING_EDGE(udp_detected);
      WAIT UNTIL FALLING_EDGE(udp_detected);
      WAIT UNTIL FALLING_EDGE(icmp_detected);      -- Get reordered before the UDP packet becasue it has a higher priority
      WAIT UNTIL FALLING_EDGE(udp_detected);
      WAIT UNTIL FALLING_EDGE(udp_detected);
      WAIT UNTIL FALLING_EDGE(udp_detected);

      WAIT UNTIL RISING_EDGE(udp_detected);
      ASSERT (eth_pause_rx_req(3) = '0') REPORT "Pause Failed" SEVERITY failure;

      WAIT UNTIL FALLING_EDGE(udp_detected);
      WAIT FOR 1 us;


      tb_sucess <= '1';
      REPORT "Finished Simulation" SEVERITY note;
      WAIT;
   END PROCESS;


END ARCHITECTURE;






