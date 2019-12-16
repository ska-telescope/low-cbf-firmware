-------------------------------------------------------------------------------
--
-- File Name: eth_tx.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Wed Aug 15 15:40:00 2017
-- Template Rev: 1.0
--
-- Title: Top Level of Ethernet Framer
--
-- Description: Top level file for implmentation the ethernet TX framer. Muxes
--              multiple lanes together
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

LIBRARY IEEE, common_lib, axi4_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;

-------------------------------------------------------------------------------
ENTITY dhcp_packetiser IS
   PORT (
      -- Clocks & Resets
      axi_clk                 : IN STD_LOGIC;

      axi_rst                 : IN STD_LOGIC;

      ip_address              : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      mac_address             : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
      serial_number           : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      pending_ip              : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

      dhcp_mac                : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
      dhcp_ip                 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      dhcp_xid                : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

      dhcp_op                 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      dhcp_gen                : IN STD_LOGIC;
      dhcp_complete           : OUT STD_LOGIC;

      -- Ethernet Output
      frame_out_sosi            : OUT t_axi4_sosi;
      frame_out_siso            : IN t_axi4_siso);
END dhcp_packetiser;

-------------------------------------------------------------------------------
ARCHITECTURE behaviour of dhcp_packetiser is

  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   TYPE transmit_states IS (s_idle, s_charge_pipe, s_send_packet, s_clear_pipe, s_done);

  ---------------------------------------------------------------------------
  -- SIGNAL DECLARATIONS  --
  ---------------------------------------------------------------------------

   SIGNAL tx_state            : transmit_states;

   SIGNAL op_code             : STD_LOGIC_VECTOR(5 DOWNTO 0);
   SIGNAL packet_counter      : UNSIGNED(5 DOWNTO 0);
   SIGNAL pipeline_read       : STD_LOGIC;

   SIGNAL dest_mac            : STD_LOGIC_VECTOR(47 DOWNTO 0);
   SIGNAL dest_ip             : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL ci_ip               : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL ip_length           : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL udp_length          : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL flags               : STD_LOGIC_VECTOR(15 DOWNTO 0);

   SIGNAL packet_data         : STD_LOGIC_VECTOR(63 DOWNTO 0);
   SIGNAL packet_keep         : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL packet_last         : STD_LOGIC;
   SIGNAL packet_valid        : STD_LOGIC;

  ---------------------------------------------------------------------------
  -- COMPONENT DECLARATIONS  --
  ---------------------------------------------------------------------------


BEGIN


---------------------------------------------------------------------------
-- Control State Machine  --
---------------------------------------------------------------------------

transmit_fsm: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         IF axi_rst = '1' THEN
            tx_state <= s_idle;
         ELSE
            CASE tx_state IS
               WHEN s_idle =>
                  packet_counter <= (OTHERS => '0');
                  IF dhcp_gen = '1' THEN
                     IF dhcp_op(0) = '0' THEN
                        op_code(3 DOWNTO 0) <= X"1";     -- DHCPDISCOVER
                     ELSE
                        op_code(3 DOWNTO 0) <= X"3";     -- DHCPREQUEST
                     END IF;
                     op_code(5 DOWNTO 4) <= dhcp_op(2 DOWNTO 1);
                     tx_state <= s_charge_pipe;
                  END IF;
               WHEN s_charge_pipe =>
                  tx_state <= s_send_packet;
                  packet_counter <= packet_counter + 1;
               WHEN s_send_packet =>
                  IF frame_out_siso.tready = '1' THEN
                     packet_counter <= packet_counter + 1;

                     IF (packet_counter = 36 AND op_code(3 DOWNTO 0) = X"3" AND op_code(4) = '1') OR (packet_counter = 37 AND op_code(3 DOWNTO 0) = X"1") OR packet_counter = 38 THEN                      -- N+1 because of pipline
                        tx_state <= s_clear_pipe;
                     END IF;
                  END IF;
               WHEN s_clear_pipe =>
                  IF frame_out_siso.tready = '1' THEN
                     tx_state <= s_done;
                  END IF;
               WHEN s_done =>
                  IF dhcp_gen = '0' THEN
                     tx_state <= s_idle;
                  END IF;
            END CASE;
         END IF;
      END IF;
   END PROCESS;

   -- Need to precharge the pipline before we start
   pipeline_read <= '1' WHEN tx_state = s_charge_pipe ELSE
                    frame_out_siso.tready;

   packet_valid <= '1' WHEN tx_state = s_charge_pipe or tx_state = s_send_packet ELSE '0';

   dhcp_complete <= '1' WHEN tx_state = s_done ELSE '0';

---------------------------------------------------------------------------
-- Packet Field Muxes  --
---------------------------------------------------------------------------

   -- DHCPDISCOVERY always broadcast, DHCPREQUEST unicast in renewal otherwise broadcast
   dest_mac <= X"FFFFFFFFFFFF" WHEN op_code(5) = '0' OR op_code(3 DOWNTO 0) = X"1" OR op_code(4) = '0' ELSE
               dhcp_mac;

   dest_ip <=  X"FFFFFFFF" WHEN op_code(5) = '0' OR op_code(3 DOWNTO 0) = X"1" OR op_code(4) = '0' ELSE
               dhcp_ip;

   -- Fixed packet lengths
   ip_length <= X"0117" WHEN op_code(3 DOWNTO 0) = X"3" AND op_code(4) = '1' ELSE   -- renewal DHCPREQUEST
                X"011b" WHEN op_code(3 DOWNTO 0) = X"1"  ELSE                       -- DHCPDISCOVERY
                X"0127";                                                            -- DHCPREQUEST

   udp_length <= X"0103" WHEN op_code(3 DOWNTO 0) = X"3" AND op_code(4) = '1' ELSE  -- renewal DHCPREQUEST
                 X"0107" WHEN op_code(3 DOWNTO 0) = X"1" ELSE                       -- DHCPDISCOVERY
                 X"0113";                                                           -- DHCPREQUEST

   flags <= X"8000" WHEN op_code(3 DOWNTO 0) = X"1" ELSE                            -- Need broadcast response to DHCPDISCOVERY (DHCPOFFER)
            X"0000";                                                                -- Otehrwise UNICAST (DHCPACK)

   -- Only after allocation can the IP be set in this field for a DHCPREQUEST
   ci_ip <= ip_address WHEN op_code(4) = '1' AND op_code(3 DOWNTO 0) = X"3" ELSE
            X"00000000";

---------------------------------------------------------------------------
-- Packet Generation  --
---------------------------------------------------------------------------
-- Byte ordering is swapped later (makes loading busses more obvious)

packet_gen: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         IF pipeline_read = '1' THEN
            CASE TO_INTEGER(packet_counter) IS                                         --     MAC     |      IP/UDP     |      DHCP      |
               WHEN 0 =>  packet_data(63 DOWNTO 16)  <= dest_mac;                      -- Destination |        -        |        -       |
                          packet_data(15 DOWNTO 0)   <= X"0000";                       --    Source   |        -        |        -       |
               WHEN 1 =>  packet_data(63 DOWNTO 32)  <= X"00000000";                   --    Source   |        -        |        -       |
                          packet_data(31 DOWNTO 16)  <= X"0800";                       --   Protocol  |        -        |        -       |
                          packet_data(15 DOWNTO 8)   <= X"45";                         --      -      | Version & Length|        -       |
                          packet_data(7 DOWNTO 0)    <= X"00";                         --      -      |       TOS       |        -       |
               WHEN 2 =>  packet_data(63 DOWNTO 48)  <= ip_length;                     --      -      |   Total length  |        -       |
                          packet_data(47 DOWNTO 32)  <= X"0000";                       --      -      | Identification  |        -       |
                          packet_data(31 DOWNTO 16)  <= X"4000";                       --      -      |    Fragment     |        -       |
                          packet_data(15 DOWNTO 8)   <= X"40";                         --      -      |      TTL        |        -       |
                          packet_data(7 DOWNTO 0)    <= X"11";                         --      -      |    Protocol     |        -       |
               WHEN 3 =>  packet_data(63 DOWNTO 48)  <= X"0000";                       --      -      |   Header CRC    |        -       |
                          packet_data(47 DOWNTO 16)  <= X"00000000";                   --      -      |    Source IP    |        -       |
                          packet_data(15 DOWNTO 0)   <= dest_ip(31 DOWNTO 16);         --      -      | Destination IP  |        -       |
               WHEN 4 =>  packet_data(63 DOWNTO 48)  <= dest_ip(15 DOWNTO 0);          --      -      | Destination IP  |        -       |
                          packet_data(47 DOWNTO 32)  <= X"0044";                       --      -      | Source UDP Port |        -       |
                          packet_data(31 DOWNTO 16)  <= X"0043";                       --      -      |  Dest UDP Port  |        -       |
                          packet_data(15 DOWNTO 0)   <= udp_length;                    --      -      |   UDP Length    |        -       |
               WHEN 5 =>  packet_data(63 DOWNTO 48)  <= X"0000";                       --      -      |     UDP CRC     |        -       |
                          packet_data(47 DOWNTO 40)  <= X"01";                         --      -      |        -        |       OP       |
                          packet_data(39 DOWNTO 32)  <= X"01";                         --      -      |        -        |      HTYPE     |
                          packet_data(31 DOWNTO 24)  <= X"06";                         --      -      |        -        |      HLEN      |
                          packet_data(23 DOWNTO 16)  <= X"00";                         --      -      |        -        |      HOPS      |
                          packet_data(15 DOWNTO 0)   <= dhcp_xid(31 DOWNTO 16);        --      -      |        -        |       XID      |
               WHEN 6 =>  packet_data(63 DOWNTO 48)  <= dhcp_xid(15 DOWNTO 0);         --      -      |        -        |       XID      |
                          packet_data(47 DOWNTO 32)  <= X"0000";                       --      -      |        -        |      SECS      |
                          packet_data(31 DOWNTO 16)  <= flags;                         --      -      |        -        |      FLAGS     |
                          packet_data(15 DOWNTO 0)   <= ci_ip(31 DOWNTO 16);           --      -      |        -        |     CIADDR     |
               WHEN 7 =>  packet_data(63 DOWNTO 48)  <= ci_ip(15 DOWNTO 0);            --      -      |        -        |     CIADDR     |
                          packet_data(47 DOWNTO 16)  <= X"00000000";                   --      -      |        -        |     YIADDR     |
                          packet_data(15 DOWNTO 0)   <= X"0000";                       --      -      |        -        |     SIADDR     |
               WHEN 8 =>  packet_data(63 DOWNTO 48)  <= X"0000";                       --      -      |        -        |     SIADDR     |
                          packet_data(47 DOWNTO 16)  <= X"00000000";                   --      -      |        -        |     GIADDR     |
                          packet_data(15 DOWNTO 0)   <= mac_address(47 DOWNTO 32);     --      -      |        -        |     CHADDR     |
               WHEN 9 =>  packet_data(63 DOWNTO 32)  <= mac_address(31 DOWNTO 0);      --      -      |        -        |     CHADDR     |
                          packet_data(31 DOWNTO 0)   <= X"00000000";                   --      -      |        -        |     CHADDR     |
               ------------
               WHEN 34 => packet_data(63 DOWNTO 16)  <= X"000000000000";               --      -      |        -        |     LEGACY     |
                          packet_data(15 DOWNTO 0)   <= X"6382";                       --      -      |        -        |     MAGIC      |
               WHEN 35 => packet_data(63 DOWNTO 48)  <= X"5363";                       --      -      |        -        |     MAGIC      |
                          packet_data(47 DOWNTO 32)  <= X"3501";                       --      -      |        -        |  EXT: Code 53  |
                          packet_data(31 DOWNTO 24)  <= X"0"& op_code(3 DOWNTO 0);     --      -      |        -        |     Op Type    |
                          packet_data(23 DOWNTO 8)   <= X"3D05";                       --      -      |        -        |  EXT: Code 61  |
                          packet_data(7 DOWNTO 0)    <= X"00";                         --      -      |        -        |      Type      |
               WHEN 36 => packet_data(63 DOWNTO 32)  <= serial_number;                 --      -      |        -        |  Serial Number |
                  IF op_code(3 DOWNTO 0) = X"3" AND op_code(4) = '1' THEN     -- End here for RENEWAL
                          packet_data(31 DOWNTO 24)  <= X"FF";                         --      -      |        -        |      Term      |
                          packet_data(23 DOWNTO 0)   <= X"000000";
                  ELSE
                          packet_data(31 DOWNTO 16)  <= X"3702";                       --      -      |        -        |  EXT: Code 55  |
                          packet_data(15 DOWNTO 0)   <= X"0c1a";                       --      -      |        -        |  Hostname, MTU |
                 END IF;
               WHEN 37 =>
                     IF op_code(3 DOWNTO 0) = X"1" THEN
                          packet_data(63 DOWNTO 56)    <= X"ff";                       --      -      |        -        |      Term      |
                          packet_data(55 DOWNTO 0)   <= X"00000000000000";
                     ELSE                                   -- Initial DHCPREQUEST transactions include selected DHCP server IP
                          packet_data(63 DOWNTO 48)  <= X"3604";                       --      -      |        -        |  EXT: Code 54  |
                          packet_data(47 DOWNTO 16)  <= dhcp_ip;                       --      -      |        -        |    Server IP   |
                          packet_data(15 DOWNTO 0)   <= X"3204";                       --      -      |        -        |  EXT: Code 50  |
                     END IF;
               WHEN 38 =>
                          packet_data(63 DOWNTO 56)    <= pending_ip(31 DOWNTO 24);    --      -      |        -        |  Requested IP  |
                          packet_data(55 DOWNTO 32)  <= pending_ip(23 DOWNTO 0);       --      -      |        -        |  Requested IP  |
                          packet_data(31 DOWNTO 24)  <= X"FF";                         --      -      |        -        |      Term      |
                          packet_data(23 DOWNTO 0)   <= X"000000";
               WHEN OTHERS =>
                         packet_data <= (OTHERS => '0');
            END CASE;

            CASE to_integer(packet_counter) IS
               WHEN 36      =>
                  IF op_code(3 DOWNTO 0) = X"3" AND op_code(4) = '1' THEN
                               packet_keep  <= X"F8";
                               packet_last <= '1';
                  ELSE
                               packet_keep  <= X"FF";
                               packet_last <= '0';
                  END IF;
               WHEN 37      =>
                  IF op_code(3 DOWNTO 0) = X"1" THEN
                               packet_keep  <= X"80";
                               packet_last <= '1';
                  ELSE
                               packet_keep  <= X"FF";
                               packet_last <= '0';
                  END IF;
               WHEN 38      => packet_keep  <= X"F8";
                               packet_last <= '1';
               WHEN OTHERS  => packet_keep  <= X"FF";
                               packet_last <= '0';
            END CASE;
         END IF;
      END IF;
   END PROCESS;

   -- Byte swap
   frame_out_sosi.tdata(63 downto 0) <= packet_data(7 DOWNTO 0) &
                                        packet_data(15 DOWNTO 8) &
                                        packet_data(23 DOWNTO 16) &
                                        packet_data(31 DOWNTO 24) &
                                        packet_data(39 DOWNTO 32) &
                                        packet_data(47 DOWNTO 40) &
                                        packet_data(55 DOWNTO 48) &
                                        packet_data(63 DOWNTO 56);

   frame_out_sosi.tkeep(7 downto 0) <= packet_keep(0) &
                                       packet_keep(1) &
                                       packet_keep(2) &
                                       packet_keep(3) &
                                       packet_keep(4) &
                                       packet_keep(5) &
                                       packet_keep(6) &
                                       packet_keep(7);

   frame_out_sosi.tlast <= packet_last;

valid_data_pipe: ENTITY common_lib.common_pipeline
                 GENERIC MAP (g_pipeline  => 1,
                              g_in_dat_w  => 1,
                              g_out_dat_w => 1)
                 PORT MAP (clk                   => axi_clk,
                           rst                   => '0',
                           in_en                 => pipeline_read,
                           in_dat(0)             => packet_valid,
                           out_dat(0)            => frame_out_sosi.tvalid);


END behaviour;
-------------------------------------------------------------------------------