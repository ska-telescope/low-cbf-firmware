----------------------------------------------------------------------------
-- (c) Copyright - Commonwealth Scientific and Industrial Research Organisation
-- (CSIRO) - 2017
--
-- All Rights Reserved.
--
-- Restricted Use.
--
-- Copyright protects this code. Except as permitted by the Copyright Act, you
-- may only use the code as expressly permitted under the terms on which the
-- code was licensed to you.
--
-------------------------------------------------------------------------------
--
-- File Name: ethernet_framer.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Wed Aug 15 15:40:00 2017
-- Template Rev: 1.0
--
-- Title: Packet Decoder
--
-- Description: Decodes packets on an AXI streaming bus and prints the results
--              to the console. Also checks that checksums are OK. Always
--              ready to accept data so timing for ready needs to be provided
--              upstream.
--
-- Compiler options:
--
--
-- Dependencies:
--
--
--
-------------------------------------------------------------------------------

LIBRARY IEEE, axi4_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.math_real.ALL;
USE IEEE.std_logic_textio.ALL;
USE STD.textio.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;


ENTITY packet_decoder IS
   GENERIC (
      prefix                  : STRING := "";
      g_packet_padding        : BOOLEAN := TRUE);        -- Assume packets padded to minimum size
   PORT (
      clk                     : IN STD_LOGIC;
      reset                   : IN STD_LOGIC;

      -- Ethernet Input
      eth_out_sosi            : IN t_axi4_sosi;
      eth_out_siso            : IN t_axi4_siso);
END packet_decoder;

ARCHITECTURE testbench OF packet_decoder IS



  ---------------------------------------------------------------------------
  -- SIGNAL DECLARATIONS  --
  ---------------------------------------------------------------------------

   SIGNAL mac_word_count_ely        : INTEGER;
   SIGNAL mac_word_count            : INTEGER;
   SIGNAL transaction_cycle_count   : INTEGER;
   SIGNAL mac_valid_ely             : STD_LOGIC;
   SIGNAL mac_valid                 : STD_LOGIC;
   SIGNAL mac_recieving_ely         : BOOLEAN;
   SIGNAL mac_recieving             : BOOLEAN;
   SIGNAL mac_recieving_dly         : BOOLEAN;
   SIGNAL mac_word_long             : STD_LOGIC_VECTOR(127 DOWNTO 0);
   SIGNAL mac_keep_long             : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL mac_tready                : STD_LOGIC := '1';
   SIGNAL arp_detected              : BOOLEAN;
   SIGNAL ip_detected               : BOOLEAN;
   SIGNAL icmp_detected             : BOOLEAN;
   SIGNAL udp_detected              : BOOLEAN;
   SIGNAL gemini_detected           : BOOLEAN;
   SIGNAL gemini_publish_detected   : BOOLEAN;
   SIGNAL dhcp_detected             : BOOLEAN;
   SIGNAL packet_number             : INTEGER := 0;
   SIGNAL vlan_tag                  : BOOLEAN := TRUE;
   SIGNAl spare_data                : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL spare_keep                : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL valid_dly                 : STD_LOGIC;
   SIGNAL extra_cycle               : STD_LOGIC;


BEGIN
---------------------------------------------------------------------------
-- Transmit MAC Reciever  --
---------------------------------------------------------------------------

tx_mac: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         mac_word_count <= mac_word_count_ely;
         mac_recieving <= mac_recieving_ely;
         mac_valid <= mac_valid_ely;
         valid_dly <= eth_out_sosi.tvalid;

         IF reset = '1' THEN
            mac_recieving_ely <= FALSE;
            mac_word_count_ely <= 0;
            extra_cycle <= '0';
         ELSE
            -- Enable
            IF mac_recieving_ely = FALSE THEN
               IF eth_out_sosi.tvalid = '1' AND eth_out_siso.tready = '1' THEN
                  mac_recieving_ely <= TRUE;
               END IF;
            END IF;

            -- Used to insert random tready deassertions
            IF mac_recieving = FALSE THEN
               transaction_cycle_count <= 0;
            ELSE
               transaction_cycle_count <= transaction_cycle_count + 1;
            END IF;

            IF (eth_out_sosi.tvalid = '1' AND eth_out_siso.tready = '1') OR extra_cycle = '1' THEN
               extra_cycle <= '0';

               -- Count words in packet (for decoding)
               IF mac_recieving_ely = FALSE and valid_dly = '0' THEN
                  mac_word_count_ely <= 1;
               ELSE
                  mac_word_count_ely <= mac_word_count_ely + 1;
               END IF;


               spare_data <= eth_out_sosi.tdata(39 DOWNTO 32) &
                             eth_out_sosi.tdata(47 DOWNTO 40) &
                             eth_out_sosi.tdata(55 DOWNTO 48) &
                             eth_out_sosi.tdata(63 DOWNTO 56);

               spare_keep <= eth_out_sosi.tkeep(4) &
                             eth_out_sosi.tkeep(5) &
                             eth_out_sosi.tkeep(6) &
                             eth_out_sosi.tkeep(7);


               IF mac_word_count_ely = 1 AND (eth_out_sosi.tdata(39 DOWNTO 32) /= X"81" OR eth_out_sosi.tdata(47 DOWNTO 40) /= X"00") THEN
                  -- Insert pad for vlan header if not there
                  mac_word_long <= mac_word_long(63 DOWNTO 0) &
                                   eth_out_sosi.tdata(7 DOWNTO 0) &
                                   eth_out_sosi.tdata(15 DOWNTO 8) &
                                   eth_out_sosi.tdata(23 DOWNTO 16) &
                                   eth_out_sosi.tdata(31 DOWNTO 24) &
                                   X"00000000";

                  mac_keep_long <= mac_keep_long(7 downto 0) &
                                   eth_out_sosi.tkeep(0) &
                                   eth_out_sosi.tkeep(1) &
                                   eth_out_sosi.tkeep(2) &
                                   eth_out_sosi.tkeep(3) &
                                   X"F";

                  vlan_tag <= FALSE;

               ELSE
                  IF vlan_tag = FALSE THEN

                     IF extra_cycle = '0' THEN

                        mac_word_long <= mac_word_long(63 DOWNTO 0) &
                                         spare_data &
                                         eth_out_sosi.tdata(7 DOWNTO 0) &
                                         eth_out_sosi.tdata(15 DOWNTO 8) &
                                         eth_out_sosi.tdata(23 DOWNTO 16) &
                                         eth_out_sosi.tdata(31 DOWNTO 24);

                        mac_keep_long <= mac_keep_long(7 downto 0) &
                                         spare_keep &
                                         eth_out_sosi.tkeep(0) &
                                         eth_out_sosi.tkeep(1) &
                                         eth_out_sosi.tkeep(2) &
                                         eth_out_sosi.tkeep(3);

                     ELSE

                        mac_word_long <= mac_word_long(63 DOWNTO 0) &
                                         spare_data &
                                         X"00000000";

                        mac_keep_long <= mac_keep_long(7 downto 0) &
                                         spare_keep &
                                         "0000";
                     END IF;

                  ELSE

                     -- Go back to big endian and store 2 words incase fields cross boundaries
                     mac_word_long <= mac_word_long(63 DOWNTO 0) &
                                      eth_out_sosi.tdata(7 DOWNTO 0) &
                                      eth_out_sosi.tdata(15 DOWNTO 8) &
                                      eth_out_sosi.tdata(23 DOWNTO 16) &
                                      eth_out_sosi.tdata(31 DOWNTO 24) &
                                      eth_out_sosi.tdata(39 DOWNTO 32) &
                                      eth_out_sosi.tdata(47 DOWNTO 40) &
                                      eth_out_sosi.tdata(55 DOWNTO 48) &
                                      eth_out_sosi.tdata(63 DOWNTO 56);

                     mac_keep_long <= mac_keep_long(7 downto 0) &
                                      eth_out_sosi.tkeep(0) &
                                      eth_out_sosi.tkeep(1) &
                                      eth_out_sosi.tkeep(2) &
                                      eth_out_sosi.tkeep(3) &
                                      eth_out_sosi.tkeep(4) &
                                      eth_out_sosi.tkeep(5) &
                                      eth_out_sosi.tkeep(6) &
                                      eth_out_sosi.tkeep(7);
                  END IF;
               END IF;

               -- Stop receiving when last occurs (make extra cycle longer for NO VLAN packets if needed)
               IF eth_out_sosi.tlast = '1' OR extra_cycle = '1' THEN
                  IF vlan_tag = FALSE AND extra_cycle = '0' AND eth_out_sosi.tkeep(7 DOWNTO 4) /= X"0" THEN
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

   mac_valid_ely <= (eth_out_sosi.tvalid and eth_out_siso.tready) OR extra_cycle when mac_recieving_ely = TRUE ELSE '0';

---------------------------------------------------------------------------
-- RX Code  --
---------------------------------------------------------------------------
-- Assumes a VLAN tagged frame. Extra 32bits inserted in MAC simulation.


arp_decode: PROCESS(clk)
      VARIABLE stdio : line;
   BEGIN
      IF RISING_EDGE(clk) THEN
         IF mac_recieving = TRUE THEN
            IF mac_valid = '1' AND (arp_detected = TRUE OR mac_word_count = 2) THEN
               CASE mac_word_count IS
                  WHEN 2 =>
                     IF mac_word_long(63 DOWNTO 48) = X"0806" THEN
                        arp_detected <= TRUE;
                     END IF;
                  WHEN 4 =>
                     write(stdio, packet_number);
                     write(stdio, string'("@ ARP: Operation - "));
                     IF mac_word_long(127 DOWNTO 112) = X"0001" THEN
                        write(stdio, string'("Request"));
                     ELSIF mac_word_long(127 DOWNTO 112) = X"0002" THEN
                        write(stdio, string'("Reply"));
                     ELSE
                        write(stdio, string'("Unknown"));
                     END IF;
                     writeline(output, stdio);

                     write(stdio, packet_number);
                     write(stdio, string'("@ ARP: Sender MAC - "));
                     hwrite(stdio, mac_word_long(111 DOWNTO 104));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(103 DOWNTO 96));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(95 DOWNTO 88));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(87 DOWNTO 80));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(79 DOWNTO 72));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(71 DOWNTO 64));
                     write(stdio, string'(", Sender IP - "));
                     write(stdio, to_integer(unsigned(mac_word_long(63 DOWNTO 56))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(55 DOWNTO 48))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(47 DOWNTO 40))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(39 DOWNTO 32))));
                     writeline(output, stdio);
                  WHEN 5 =>
                     write(stdio, packet_number);
                     write(stdio, string'("@ ARP: Target MAC - "));
                     hwrite(stdio, mac_word_long(95 DOWNTO 88));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(87 DOWNTO 80));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(79 DOWNTO 72));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(71 DOWNTO 64));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(63 DOWNTO 56));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(55 DOWNTO 48));
                     write(stdio, string'(", Target IP - "));
                     write(stdio, to_integer(unsigned(mac_word_long(47 DOWNTO 40))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(39 DOWNTO 32))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(31 DOWNTO 24))));
                     write(stdio, string'("."));
                     write(stdio,to_integer(unsigned( mac_word_long(23 DOWNTO 16))));
                     writeline(output, stdio);
                  WHEN OTHERS =>
               END CASE;
            END IF;
         ELSE
            arp_detected <= FALSE;
         END IF;
      END IF;
   END PROCESS;

icmp_decode: PROCESS(clk)
      VARIABLE stdio       : line;
      VARIABLE crc_calc    : UNSIGNED(31 DOWNTO 0);
      VARIABLE crc_term    : UNSIGNED(15 DOWNTO 0);
   BEGIN
      IF RISING_EDGE(clk) THEN
         IF mac_recieving = TRUE THEN
            IF mac_valid = '1' AND (icmp_detected = TRUE OR mac_word_count = 2) THEN
               CASE mac_word_count IS
                  WHEN 2 =>
                     IF mac_word_long(63 DOWNTO 48) = X"0800" THEN
                        icmp_detected <= TRUE;
                     END IF;
                  WHEN 3 =>
                     IF mac_word_long(39 DOWNTO 32) /= X"01" THEN
                        icmp_detected <= FALSE;
                     END IF;
                  WHEN 5 =>
                     write(stdio, packet_number);
                     write(stdio, string'("@ ICMP: Type - "));
                     IF mac_word_long(79 DOWNTO 72) = X"00" THEN
                        write(stdio, string'("Echo Reply"));
                     ELSIF mac_word_long(79 DOWNTO 72) = X"08" THEN
                        write(stdio, string'("Echo Request"));
                     ELSE
                        write(stdio, string'("Unknown"));
                     END IF;

                     write(stdio, string'(", Code - "));
                     write(stdio, to_integer(unsigned(mac_word_long(71 DOWNTO 64))));
                     writeline(output, stdio);

                     crc_calc := (X"0000" & UNSIGNED(mac_word_long(79 DOWNTO 64))) +
                                 (X"0000" & UNSIGNED(mac_word_long(63 DOWNTO 48))) +
                                 (X"0000" & UNSIGNED(mac_word_long(47 DOWNTO 32))) +
                                 (X"0000" & UNSIGNED(mac_word_long(31 DOWNTO 16))) +
                                 (X"0000" & UNSIGNED(mac_word_long(15 DOWNTO 0)));

                  WHEN OTHERS =>

                     crc_calc_loop: FOR i IN 0 TO 3 LOOP
                        IF mac_keep_long(2*i+1) = '1' THEN
                           crc_term(15 DOWNTO 8) := UNSIGNED(mac_word_long(15+i*16 DOWNTO 8+i*16));
                        ELSE
                           crc_term(15 DOWNTO 8) := (OTHERS => '0');
                        END IF;

                        IF mac_keep_long(2*i+0) = '1' THEN
                           crc_term(7 DOWNTO 0) := UNSIGNED(mac_word_long(7+i*16 DOWNTO 0+i*16));
                        ELSE
                           crc_term(7 DOWNTO 0) := (OTHERS => '0');
                        END IF;

                        crc_calc := crc_calc + (X"0000" & crc_term);
                     END LOOP;

                     IF mac_word_count > 5 THEN
                        write(stdio, packet_number);
                        write(stdio, string'("@ ICMP: Payload - "));

                        data_check: FOR i in 7 DOWNTO 0 LOOP
                           IF mac_keep_long(i+2) = '1' THEN
                              hwrite(stdio, mac_word_long(15+8*(i+1) DOWNTO 8+8*(i+1)));
                              write(stdio, string'(" "));
                           END IF;
                        END LOOP;
                        writeline(output, stdio);
                     END IF;
               END CASE;
            END IF;
         ELSE
            IF mac_recieving_dly = TRUE AND icmp_detected = TRUE THEN
               crc_calc := (X"0000" & crc_calc(31 downto 16)) + (X"0000" & crc_calc(15 downto 0));

               write(stdio, packet_number);
               write(stdio, string'("@ ICMP: Checksum - "));
               IF crc_calc(15 DOWNTO 0) = X"FFFF" THEN
                  write(stdio, string'("OK"));
               ELSE
                  write(stdio, string'("BAD"));
               END IF;
               writeline(output, stdio);
            END IF;
            icmp_detected <= FALSE;
         END IF;
      END IF;
   END PROCESS;

udp_decode: PROCESS(clk)
      VARIABLE stdio                : line;
      VARIABLE crc_calc             : UNSIGNED(31 DOWNTO 0);
      VARIABLE crc_term             : UNSIGNED(15 DOWNTO 0);
      VARIABLE udp_payload_length   : INTEGER;
   BEGIN
      IF RISING_EDGE(clk) THEN
         IF mac_recieving = TRUE THEN
            IF mac_valid = '1' AND (udp_detected = TRUE OR mac_word_count = 2) THEN
               CASE mac_word_count IS
                  WHEN 2 =>
                     IF mac_word_long(63 DOWNTO 48) = X"0800" THEN
                        udp_detected <= TRUE;
                     END IF;
                  WHEN 3 =>
                     IF mac_word_long(39 DOWNTO 32) /= X"11" THEN
                        udp_detected <= FALSE;
                     END IF;

                  WHEN 4 =>
                     crc_calc := (X"0000" & UNSIGNED(mac_word_long(79 DOWNTO 64))) +
                                 (X"0000" & UNSIGNED(mac_word_long(63 DOWNTO 48))) +
                                 (X"0000" & UNSIGNED(mac_word_long(47 DOWNTO 32))) +
                                 (X"0000" & UNSIGNED(mac_word_long(31 DOWNTO 16))) +
                                 (X"00000011");
                  WHEN 5 =>
                     write(stdio, packet_number);
                     write(stdio, string'("@ UDP: Source Port - "));
                     write(stdio, to_integer(unsigned(mac_word_long(79 DOWNTO 64))));
                     write(stdio, string'(", Destination Port - "));
                     write(stdio, to_integer(unsigned(mac_word_long(63 DOWNTO 48))));
                     write(stdio, string'(", Payload Length - "));
                     udp_payload_length := to_integer(unsigned(mac_word_long(47 DOWNTO 32))) - 8;
                     write(stdio, udp_payload_length);

                     IF g_packet_padding THEN
                        -- Minimum packet size is 65 bytes, if smaller packet is padded to 72 bytes
                        -- NOTE eth_tx module adds padding if not using it (geenrally non VLAN tagged packets)
                        IF (udp_payload_length < (65-46) AND VLAN_TAG) OR (udp_payload_length < (65-42) AND NOT VLAN_TAG) THEN
                           IF VLAN_TAG THEN
                              udp_payload_length := 26;
                           ELSE
                              udp_payload_length := 30;
                           END IF;
                           write(stdio, string'(" (padded to "));
                           write(stdio, udp_payload_length);
                           write(stdio, string'(" bytes)"));
                        END IF;
                     END IF;

                     writeline(output, stdio);

                     crc_calc := crc_calc +
                                 (X"0000" & UNSIGNED(mac_word_long(79 DOWNTO 64))) +
                                 (X"0000" & UNSIGNED(mac_word_long(63 DOWNTO 48))) +
                                 (X"0000" & UNSIGNED(mac_word_long(47 DOWNTO 32))) +         -- Length added twice (1 for pseudo header, 1 for udp header)
                                 (X"0000" & UNSIGNED(mac_word_long(47 DOWNTO 32))) +
                                 (X"0000" & UNSIGNED(mac_word_long(31 DOWNTO 16))) +
                                 (X"0000" & UNSIGNED(mac_word_long(15 DOWNTO 0)));

                     length_check: FOR i IN 0 TO 1 LOOP
                        IF mac_keep_long(i) = '1' THEN
                           udp_payload_length := udp_payload_length - 1;
                        END IF;
                     END LOOP;
                  WHEN OTHERS =>

                     crc_calc_loop: FOR i IN 0 TO 3 LOOP
                        IF mac_keep_long(2*i+1) = '1' THEN
                           crc_term(15 DOWNTO 8) := UNSIGNED(mac_word_long(15+i*16 DOWNTO 8+i*16));
                           udp_payload_length := udp_payload_length - 1;
                        ELSE
                           crc_term(15 DOWNTO 8) := (OTHERS => '0');
                        END IF;

                        IF mac_keep_long(2*i+0) = '1'  THEN
                           crc_term(7 DOWNTO 0) := UNSIGNED(mac_word_long(7+i*16 DOWNTO 0+i*16));
                           udp_payload_length := udp_payload_length - 1;
                        ELSE
                           crc_term(7 DOWNTO 0) := (OTHERS => '0');
                        END IF;

                        crc_calc := crc_calc + (X"0000" & crc_term);
                     END LOOP;

                     IF mac_word_count > 5  AND (dhcp_detected = FALSE AND gemini_detected = FALSE) THEN
                        write(stdio, packet_number);
                        write(stdio, string'("@ UDP: Payload - "));

                        data_check: FOR i in 7 DOWNTO 0 LOOP
                           IF mac_keep_long(i+2) = '1' THEN
                              hwrite(stdio, mac_word_long(15+8*(i+1) DOWNTO 8+8*(i+1)));
                              write(stdio, string'(" "));
                           END IF;
                        END LOOP;
                        writeline(output, stdio);


                        -- Make sure to print out last two bytes if it is the last cycle
                        IF mac_recieving_ely = FALSE AND mac_keep_long(1 DOWNTO 0) /= "00" THEN
                           write(stdio, packet_number);
                           write(stdio, string'("@ UDP: Payload - "));

                           data_final: FOR i in 1 DOWNTO 0 LOOP
                              IF mac_keep_long(i) = '1' THEN
                                 hwrite(stdio, mac_word_long(7+8*i DOWNTO 8*i));
                                 write(stdio, string'(" "));
                              END IF;
                           END LOOP;
                           writeline(output, stdio);
                        END IF;


                     END IF;
               END CASE;
            END IF;
         ELSE
            IF mac_recieving_dly = TRUE AND udp_detected = TRUE THEN
               crc_calc := (X"0000" & crc_calc(31 downto 16)) + (X"0000" & crc_calc(15 downto 0));

               write(stdio, packet_number);
               write(stdio, string'("@ UDP: Checksum - "));
               IF crc_calc(15 DOWNTO 0) = X"FFFF" THEN
                  write(stdio, string'("OK"));
               ELSE
                  write(stdio, string'("BAD"));
               END IF;

               write(stdio, string'(", Length - "));
               IF udp_payload_length = 0 THEN
                  write(stdio, string'("OK"));
               ELSE
                  write(stdio, string'("BAD"));
               END IF;
               writeline(output, stdio);
            END IF;
            udp_detected <= FALSE;
         END IF;
      END IF;
   END PROCESS;



gemini_decode: PROCESS(clk)
      VARIABLE stdio                : line;
   BEGIN
      IF RISING_EDGE(clk) THEN
         IF mac_recieving = TRUE THEN
            IF mac_valid = '1' AND (gemini_detected = TRUE OR mac_word_count = 2) THEN
               CASE mac_word_count IS
                  WHEN 2 =>
                     IF mac_word_long(63 DOWNTO 48) = X"0800" THEN
                        gemini_detected <= TRUE;
                     END IF;
                  WHEN 3 =>
                     IF mac_word_long(39 DOWNTO 32) /= X"11" THEN
                        gemini_detected <= FALSE;
                     END IF;

                  WHEN 5 =>
                     -- Needs to be sourced from 30000 or 30001
                     IF mac_word_long(79 DOWNTO 64) /= X"7530" AND mac_word_long(79 DOWNTO 64) /= X"7531" THEN
                        gemini_detected <= FALSE;
                     ELSE
                        write(stdio, packet_number);
                        write(stdio, string'("@ Gemini: Source Port - "));
                        write(stdio, to_integer(unsigned(mac_word_long(79 DOWNTO 64))));
                        write(stdio, string'(", Destination Port - "));
                        write(stdio, to_integer(unsigned(mac_word_long(63 DOWNTO 48))));
                        writeline(output, stdio);

                        write(stdio, packet_number);
                        write(stdio, string'("@ Gemini: Version - "));
                        write(stdio, to_integer(unsigned(mac_word_long(15 DOWNTO 8))));
                        write(stdio, string'(", Command - "));
                        IF mac_word_long(7 DOWNTO 0) = X"80" THEN
                           write(stdio, string'("Publish"));
                           gemini_publish_detected <= TRUE;
                        END IF;
                        writeline(output, stdio);
                     END IF;
                  WHEN 7 =>
                     IF gemini_publish_detected = TRUE THEN
                        write(stdio, packet_number);
                        write(stdio, string'("@ Gemini: Publish Event - 0x"));
                        hwrite(stdio, mac_word_long(111 DOWNTO 80));
                        write(stdio, string'(",  Occured at - "));
                        write(stdio, to_integer(unsigned(mac_word_long(79 DOWNTO 16))) * 8);
                        write(stdio, string'("ns"));
                        writeline(output, stdio);
                     END IF;
                  WHEN OTHERS =>
               END CASE;
            END IF;
         ELSE
            gemini_publish_detected <= FALSE;
            gemini_detected <= FALSE;
         END IF;
      END IF;
   END PROCESS;


dhcp_decode: PROCESS(clk)
      VARIABLE stdio                   : line;
      VARIABLE dhcp_shifter            : STD_LOGIC_VECTOR(255 DOWNTO 0);
      VARIABLE dhcp_processing_option  : INTEGER;
      VARIABLE dhcp_found_magic        : BOOLEAN;
      VARIABLE dhcp_option             : INTEGER;
      VARIABLE option_payload          : INTEGER;
      VARIABLE dhcp_option_length      : INTEGER;
   BEGIN
      IF RISING_EDGE(clk) THEN
         IF mac_recieving = TRUE THEN
            IF mac_valid = '1' AND (dhcp_detected = TRUE OR mac_word_count = 2) THEN
               CASE mac_word_count IS
                  WHEN 0|1 =>
                  WHEN 2 =>
                     IF mac_word_long(63 DOWNTO 48) = X"0800" THEN
                        dhcp_detected <= TRUE; -- Maybe
                     END IF;
                  WHEN 3 =>
                     IF mac_word_long(39 DOWNTO 32) /= X"11" THEN
                        dhcp_detected <= FALSE;
                     END IF;
                  WHEN 4 =>
                  WHEN 5 =>
                     -- Needs to be sourced from 67 or 68
                     IF mac_word_long(79 DOWNTO 64) /= X"0043" AND mac_word_long(79 DOWNTO 64) /= X"0044"  THEN
                        dhcp_detected <= FALSE;
                     ELSE
                        write(stdio, packet_number);
                        write(stdio, string'("@ DHCP: Command "));
                        IF mac_word_long(15 DOWNTO 8) = X"01" THEN
                           write(stdio, string'("request"));
                        ELSIF mac_word_long(15 DOWNTO 8) = X"02" THEN
                           write(stdio, string'("reply"));
                        ELSE
                           write(stdio, string'("unknown"));
                        END IF;
                        writeline(output, stdio);
                     END IF;
                  WHEN 6 =>
                  WHEN 7 =>
                     write(stdio, packet_number);
                     write(stdio, string'("@ DHCP: XID - 0x"));
                     hwrite(stdio, mac_word_long(111 DOWNTO 80));
                     write(stdio, string'(", Client IP - "));
                     write(stdio, to_integer(unsigned(mac_word_long(47 DOWNTO 40))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(39 DOWNTO 32))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(31 DOWNTO 24))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(23 DOWNTO 16))));
                     writeline(output, stdio);
                  WHEN 8 =>
                     write(stdio, packet_number);
                     write(stdio, string'("@ DHCP: Your IP - "));
                     write(stdio, to_integer(unsigned(mac_word_long(79 DOWNTO 72))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(71 DOWNTO 64))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(63 DOWNTO 56))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(55 DOWNTO 48))));
                     write(stdio, string'(", Server IP - "));
                     write(stdio, to_integer(unsigned(mac_word_long(47 DOWNTO 40))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(39 DOWNTO 32))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(31 DOWNTO 24))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(23 DOWNTO 16))));
                     writeline(output, stdio);
                  WHEN 9 =>
                     write(stdio, packet_number);
                     write(stdio, string'("@ DHCP: Relay IP - "));
                     write(stdio, to_integer(unsigned(mac_word_long(79 DOWNTO 72))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(71 DOWNTO 64))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(63 DOWNTO 56))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(55 DOWNTO 48))));
                     write(stdio, string'(", Hardware Address - "));
                     hwrite(stdio, mac_word_long(47 DOWNTO 40));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(39 DOWNTO 32));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(31 DOWNTO 24));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(23 DOWNTO 16));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(15 DOWNTO 8));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(7 DOWNTO 0));
                     writeline(output, stdio);
                     dhcp_found_magic := FALSE;
                  WHEN OTHERS =>
                     -- Some amount of zeros pass so look for magic number
                     -- Then process options 1 at a time.
                     byte_loop: FOR i IN 7 DOWNTO 0 LOOP
                        -- Option payload needs to be less than 32 bytes
                        dhcp_shifter := dhcp_shifter(247 DOWNTO 0) & mac_word_long(i*8+7 DOWNTO i*8+0);

                        IF dhcp_found_magic = FALSE THEN
                           IF dhcp_shifter(31 DOWNTO 0) = X"63825363" THEN
                              dhcp_found_magic := TRUE;
                              dhcp_processing_option := 0;
                           END IF;
                        ELSE
                           IF dhcp_processing_option = 0 THEN
                              dhcp_option := TO_INTEGER(unsigned(dhcp_shifter(7 DOWNTO 0)));

                              IF dhcp_option = 255 THEN
                                 write(stdio, packet_number);
                                 write(stdio, string'("@ DHCP: OPTION Terminator Found"));
                                 writeline(output, stdio);
                              ELSIF dhcp_option /= 0 THEN
                                 dhcp_processing_option := 1;
                              END IF;
                           ELSIF dhcp_processing_option = 1 THEN
                              dhcp_option_length := TO_INTEGER(unsigned(dhcp_shifter(7 DOWNTO 0)));
                              option_payload := 0;
                              dhcp_processing_option := 2;
                           ELSE
                              option_payload := option_payload + 1;

                              -- Process Option if everything is in shifter
                              IF option_payload = dhcp_option_length THEN
                                 dhcp_processing_option := 0;
                                 CASE dhcp_option IS
                                    WHEN 1 =>
                                       write(stdio, packet_number);
                                       write(stdio, string'("@ DHCP: OPTION Subnet mask - "));
                                       write(stdio, to_integer(unsigned(dhcp_shifter(31 DOWNTO 24))));
                                       write(stdio, string'("."));
                                       write(stdio, to_integer(unsigned(dhcp_shifter(23 DOWNTO 16))));
                                       write(stdio, string'("."));
                                       write(stdio, to_integer(unsigned(dhcp_shifter(15 DOWNTO 8))));
                                       write(stdio, string'("."));
                                       write(stdio, to_integer(unsigned(dhcp_shifter(7 DOWNTO 0))));
                                    WHEN 3 =>
                                       write(stdio, packet_number);
                                       write(stdio, string'("@ DHCP: OPTION Router - "));
                                       write(stdio, to_integer(unsigned(dhcp_shifter(31 DOWNTO 24))));
                                       write(stdio, string'("."));
                                       write(stdio, to_integer(unsigned(dhcp_shifter(23 DOWNTO 16))));
                                       write(stdio, string'("."));
                                       write(stdio, to_integer(unsigned(dhcp_shifter(15 DOWNTO 8))));
                                       write(stdio, string'("."));
                                       write(stdio, to_integer(unsigned(dhcp_shifter(7 DOWNTO 0))));
                                    WHEN 26 =>
                                       write(stdio, packet_number);
                                       write(stdio, string'("@ DHCP: OPTION MTU - "));
                                       write(stdio, to_integer(unsigned(dhcp_shifter(15 DOWNTO 0))));
                                    WHEN 50 =>
                                       write(stdio, packet_number);
                                       write(stdio, string'("@ DHCP: OPTION Requested IP - "));
                                       write(stdio, to_integer(unsigned(dhcp_shifter(31 DOWNTO 24))));
                                       write(stdio, string'("."));
                                       write(stdio, to_integer(unsigned(dhcp_shifter(23 DOWNTO 16))));
                                       write(stdio, string'("."));
                                       write(stdio, to_integer(unsigned(dhcp_shifter(15 DOWNTO 8))));
                                       write(stdio, string'("."));
                                       write(stdio, to_integer(unsigned(dhcp_shifter(7 DOWNTO 0))));
                                    WHEN 51 =>
                                       write(stdio, packet_number);
                                       write(stdio, string'("@ DHCP: OPTION Lease time - "));
                                       write(stdio, to_integer(unsigned(dhcp_shifter(31 DOWNTO 0))));
                                       write(stdio, string'(" seconds"));
                                    WHEN 53 =>
                                       write(stdio, packet_number);
                                       write(stdio, string'("@ DHCP: OPTION DHCP Message Type - "));
                                       IF dhcp_shifter(7 DOWNTO 0) = X"01" THEN
                                          write(stdio, string'("DHCPDISCOVER"));
                                       ELSIF dhcp_shifter(7 DOWNTO 0) = X"02" THEN
                                          write(stdio, string'("DHCPOFFER"));
                                       ELSIF dhcp_shifter(7 DOWNTO 0) = X"03" THEN
                                          write(stdio, string'("DHCPREQUEST"));
                                       ELSIF dhcp_shifter(7 DOWNTO 0) = X"04" THEN
                                          write(stdio, string'("DHCPODECLINE"));
                                       ELSIF dhcp_shifter(7 DOWNTO 0) = X"05" THEN
                                          write(stdio, string'("DHCPACK"));
                                       ELSIF dhcp_shifter(7 DOWNTO 0) = X"06" THEN
                                          write(stdio, string'("DHCPNAK"));
                                       ELSIF dhcp_shifter(7 DOWNTO 0) = X"07" THEN
                                          write(stdio, string'("DHCPRELEASE"));
                                       ELSIF dhcp_shifter(7 DOWNTO 0) = X"08" THEN
                                          write(stdio, string'("DHCPINFORM"));
                                       ELSE
                                          write(stdio, string'("UNKNOWN"));
                                       END IF;
                                    WHEN 54 =>
                                       write(stdio, packet_number);
                                       write(stdio, string'("@ DHCP: OPTION Server IP - "));
                                       write(stdio, to_integer(unsigned(dhcp_shifter(31 DOWNTO 24))));
                                       write(stdio, string'("."));
                                       write(stdio, to_integer(unsigned(dhcp_shifter(23 DOWNTO 16))));
                                       write(stdio, string'("."));
                                       write(stdio, to_integer(unsigned(dhcp_shifter(15 DOWNTO 8))));
                                       write(stdio, string'("."));
                                       write(stdio, to_integer(unsigned(dhcp_shifter(7 DOWNTO 0))));
                                    WHEN 55 =>
                                       write(stdio, packet_number);
                                       write(stdio, string'("@ DHCP: OPTION Parameter List - "));
                                       param_list55: FOR i IN 0 TO dhcp_option_length-1 LOOP
                                          write(stdio, to_integer(unsigned(dhcp_shifter(i*8+7 DOWNTO i*8+0))));
                                          IF i /= dhcp_option_length-1 THEN
                                             write(stdio, string'(" & "));
                                          END IF;
                                       END LOOP;
                                    WHEN 61 =>
                                       write(stdio, packet_number);
                                       write(stdio, string'("@ DHCP: OPTION Client Identifier - 0x"));
                                       hwrite(stdio, dhcp_shifter(31 DOWNTO 0));
                                    WHEN 76 =>
                                       write(stdio, packet_number);
                                       write(stdio, string'("@ DHCP: OPTION Hostname - "));
                                       param_list76: FOR i IN dhcp_option_length-1 DOWNTO 0 LOOP
                                          write(stdio, CHARACTER'VAL(to_integer(unsigned(dhcp_shifter(i*8+7 DOWNTO i*8+0)))));
                                       END LOOP;

                                    WHEN OTHERS =>
                                       write(stdio, packet_number);
                                       write(stdio, string'("@ DHCP: OPTION Unknown Code - "));
                                       write(stdio, dhcp_option);
                                       write(stdio, string'(", Length - "));
                                       write(stdio, dhcp_option_length);
                                       write(stdio, string'(", Data - 0x"));
                                       hwrite(stdio, dhcp_shifter((dhcp_option_length-1)*8+7 DOWNTO 0));
                                 END CASE;
                                 writeline(output, stdio);
                              END IF;
                           END IF;
                        END IF;
                     END LOOP;
               END CASE;
            END IF;
         ELSE
            dhcp_detected <= FALSE;
         END IF;
      END IF;
   END PROCESS;










-- More protocols here





ip_decode: PROCESS(clk)
      VARIABLE stdio                : line;
      VARIABLE crc_calc             : UNSIGNED(31 DOWNTO 0);
      VARIABLE ip_payload_length    : INTEGER;
   BEGIN
      IF RISING_EDGE(clk) THEN
         IF mac_recieving = TRUE THEN
            IF mac_valid = '1' AND (ip_detected = TRUE OR mac_word_count = 2) THEN
               CASE mac_word_count IS
                  WHEN 2 =>
                     IF mac_word_long(63 DOWNTO 48) = X"0800" THEN
                        ip_detected <= TRUE;
                        ip_payload_length := to_integer(UNSIGNED(mac_word_long(31 DOWNTO 16)));

                        write(stdio, packet_number);
                        write(stdio, string'("@ IP: Length "));
                        write(stdio, ip_payload_length);
                        write(stdio, string'(" bytes"));

                        IF g_packet_padding THEN
                           -- Minimum packet size is 65 bytes, if smaller packet is padded to 72 bytes
                           -- NOTE eth_tx module adds padding if not using it (geenrally non VLAN tagged packets)
                           IF (ip_payload_length < (65-18) AND VLAN_TAG) OR (ip_payload_length < (65-14) AND NOT VLAN_TAG) THEN
                              IF VLAN_TAG THEN
                                 ip_payload_length := 54;
                              ELSE
                                 ip_payload_length := 58;
                              END IF;
                              write(stdio, string'(" (padded to "));
                              write(stdio, ip_payload_length);
                              write(stdio, string'(" bytes)"));
                           END IF;
                        END IF;

                        writeline(output, stdio);
                        crc_calc := (X"0000" & UNSIGNED(mac_word_long(47 DOWNTO 32))) +
                                    (X"0000" & UNSIGNED(mac_word_long(31 DOWNTO 16))) +
                                    (X"0000" & UNSIGNED(mac_word_long(15 DOWNTO 0)));
                     END IF;
                  WHEN 3 =>
                     crc_calc := crc_calc + (X"0000" & UNSIGNED(mac_word_long(63 DOWNTO 48))) +
                                            (X"0000" & UNSIGNED(mac_word_long(47 DOWNTO 32))) +
                                            (X"0000" & UNSIGNED(mac_word_long(31 DOWNTO 16))) +
                                            (X"0000" & UNSIGNED(mac_word_long(15 DOWNTO 0)));
                  WHEN 4 =>
                     write(stdio, packet_number);
                     write(stdio, string'("@ IP: Protocol - "));
                     IF mac_word_long(103 DOWNTO 96) = X"01" THEN
                        write(stdio, string'("ICMP"));
                     ELSIF mac_word_long(103 DOWNTO 96) = X"11" THEN
                        write(stdio, string'("UDP"));
                     ELSE
                        write(stdio, string'("Unknown"));
                     END IF;
                     writeline(output, stdio);

                     write(stdio, packet_number);
                     write(stdio, string'("@ IP: Source IP - "));
                     write(stdio, to_integer(unsigned(mac_word_long(79 DOWNTO 72))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(71 DOWNTO 64))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(63 DOWNTO 56))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(55 DOWNTO 48))));
                     write(stdio, string'(", Destination IP - "));
                     write(stdio, to_integer(unsigned(mac_word_long(47 DOWNTO 40))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(39 DOWNTO 32))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(31 DOWNTO 24))));
                     write(stdio, string'("."));
                     write(stdio, to_integer(unsigned(mac_word_long(23 DOWNTO 16))));
                     writeline(output, stdio);

                     -- Finish CRC verification
                     crc_calc := crc_calc + (X"0000" & UNSIGNED(mac_word_long(63 DOWNTO 48))) +
                                            (X"0000" & UNSIGNED(mac_word_long(47 DOWNTO 32))) +
                                            (X"0000" & UNSIGNED(mac_word_long(31 DOWNTO 16)));

                     crc_calc := (X"0000" & crc_calc(31 downto 16)) + (X"0000" & crc_calc(15 downto 0));

                     write(stdio, packet_number);
                     write(stdio, string'("@ IP: Header Checksum - "));
                     IF crc_calc(15 DOWNTO 0) = X"FFFF" THEN
                        write(stdio, string'("OK"));
                     ELSE
                        write(stdio, string'("BAD"));
                     END IF;
                     writeline(output, stdio);

                     -- Keep track of header length
                     ip_payload_length := ip_payload_length - 20;
                     payload_check: FOR i in 0 to 1 LOOP
                        if mac_keep_long(i) = '1' THEN
                           ip_payload_length := ip_payload_length - 1;
                        END IF;
                     END LOOP;
                  WHEN OTHERS =>
                     payload_check2: FOR i in 0 to 7 LOOP
                        if mac_keep_long(i) = '1' THEN
                           ip_payload_length := ip_payload_length - 1;
                        END IF;
                     END LOOP;
               END CASE;
            END IF;
         ELSE
            IF mac_recieving_dly = TRUE AND ip_detected = TRUE THEN
               write(stdio, packet_number);
               write(stdio, string'("@ IP: Length - "));
               IF ip_payload_length = 0 THEN
                  write(stdio, string'("OK"));
               ELSE
                  write(stdio, string'("BAD ("));
                  write(stdio, ip_payload_length);
                  write(stdio, string'(")"));
               END IF;
               writeline(output, stdio);
            END IF;
            ip_detected <= FALSE;
         END IF;
      END IF;
   END PROCESS;

mac_decode: PROCESS(clk)              -- For correct text output printing order needs to be placed at the bottom of file
      VARIABLE stdio : line;
   BEGIN
      IF RISING_EDGE(clk) THEN
         mac_recieving_dly <= mac_recieving;

         IF mac_recieving = TRUE THEN
            IF mac_valid = '1' THEN
               CASE mac_word_count IS
                  WHEN 1 =>

                     write(stdio, string'("---- "));
                     write(stdio, prefix);
                     write(stdio, string'(" New packet @"));
                     write(stdio, packet_number);
                     write(stdio, string'("  ----"));
                     writeline(output, stdio);

                     write(stdio, packet_number);
                     write(stdio, string'("@ MAC: Dest MAC - "));
                     hwrite(stdio, mac_word_long(127 DOWNTO 120));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(119 DOWNTO 112));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(111 DOWNTO 104));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(103 DOWNTO 96));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(95 DOWNTO 88));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(87 DOWNTO 80));
                     write(stdio, string'(", Source MAC - "));
                     hwrite(stdio, mac_word_long(79 DOWNTO 72));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(71 DOWNTO 64));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(63 DOWNTO 56));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(55 DOWNTO 48));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(47 DOWNTO 40));
                     write(stdio, string'(":"));
                     hwrite(stdio, mac_word_long(39 DOWNTO 32));

                     IF mac_word_long(31 DOWNTO 16) = X"8100" THEN
                        write(stdio, string'(", VLAN Tagged Priority - "));
                        write(stdio, to_integer(unsigned(mac_word_long(15 DOWNTO 13))));
                     ELSE
                        write(stdio, string'(", No VLAN Header"));
                     END IF;
                     writeline(output, stdio);
                  WHEN 2 =>
                     write(stdio, packet_number);
                     write(stdio, string'("@ MAC: Protocol - "));
                     IF mac_word_long(63 DOWNTO 48) = X"0806" THEN
                        write(stdio, string'("ARP"));
                     ELSIF mac_word_long(63 DOWNTO 48) = X"0800" THEN
                        write(stdio, string'("IPv4"));
                     ELSE
                        write(stdio, string'("Unknown (0x"));
                        hwrite(stdio, mac_word_long(63 DOWNTO 48));
                        write(stdio, string'(")"));
                     END IF;
                     writeline(output, stdio);
                  WHEN OTHERS =>
               END CASE;
            END IF;
         ELSE
            IF mac_recieving_dly = TRUE THEN
               write(stdio, string'("---- Finished packet @"));
               write(stdio, packet_number);
               write(stdio, string'(" ----"));
               writeline(output, stdio);
               write(stdio, string'(""));
               writeline(output, stdio);
               packet_number <= packet_number + 1;
            END IF;
         END IF;
      END IF;
   END PROCESS;

END ARCHITECTURE;






