-------------------------------------------------------------------------------
--
-- Copyright (C) 2017
-- ASTRON (Netherlands Institute for Radio Astronomy) <http://www.astron.nl/>
-- JIVE (Joint Institute for VLBI in Europe) <http://www.jive.nl/>
-- P.O.Box 2, 7990 AA Dwingeloo, The Netherlands
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-------------------------------------------------------------------------------

LIBRARY IEEE, common_lib, axi4_lib, arp_lib, eth_lib, technology_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.math_real.ALL;
USE IEEE.std_logic_textio.ALL;
USE STD.textio.ALL;
USE common_lib.common_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
use common_lib.common_mem_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;

ENTITY tb_arp_framer_axi4 IS
END tb_arp_framer_axi4;

ARCHITECTURE tb OF tb_arp_framer_axi4 IS

   CONSTANT c_eth_tx_clk_period  : TIME := 2.56 ns;
   CONSTANT c_eth_rx_clk_period  : TIME := 2.56 ns;
   CONSTANT c_axi_clk_period     : TIME := 6.4 ns;
   CONSTANT c_ifg_clocks         : INTEGER := 10;
   CONSTANT c_arp_priority          : INTEGER := 7;

    CONSTANT C_RESET_LEN    : NATURAL := 4;   
    
    -- Constants used to feed into ARP packet 
    CONSTANT LOCAL_IP       : STD_LOGIC_VECTOR(31 downto 0) := x"0201010A";
    CONSTANT LOCAL_MAC      : STD_LOGIC_VECTOR(47 downto 0) := x"00F1E0D9C8B7"; 
    CONSTANT REMOTE_IP      : STD_LOGIC_VECTOR(31 downto 0) := x"0101010A";
    CONSTANT REMOTE_MAC     : STD_LOGIC_VECTOR(47 downto 0) := x"00E5D4C3B2A1"; 
    CONSTANT OTHER_IP       : STD_LOGIC_VECTOR(31 downto 0) := x"0A01010A";
    CONSTANT C_LOCAL_IP       : STD_LOGIC_VECTOR(31 downto 0) := x"0A010102";
    CONSTANT C_LOCAL_MAC      : STD_LOGIC_VECTOR(47 downto 0) := x"B7C8D9E0F100";
    CONSTANT C_REMOTE_IP      : STD_LOGIC_VECTOR(31 downto 0) := x"0A010101";
    CONSTANT C_REMOTE_MAC     : STD_LOGIC_VECTOR(47 downto 0) := x"A1B2C3D4E500";
    CONSTANT C_OTHER_IP       : STD_LOGIC_VECTOR(31 downto 0) := x"0A01010A";    

    -- Ethernet MAC constants
    CONSTANT ARP_ETYPE      : STD_LOGIC_VECTOR(15 downto 0) := x"0608";    
    
    -- ARP payload constants
	CONSTANT HTYPE_ETH		: STD_LOGIC_VECTOR(15 downto 0) := x"0100";
	CONSTANT PTYPE_IPV4		: STD_LOGIC_VECTOR(15 downto 0) := x"0008";
	CONSTANT HLEN_ETH 		: STD_LOGIC_VECTOR(7 downto 0) := x"06";
	CONSTANT PLEN_IPV4		: STD_LOGIC_VECTOR(7 downto 0) := x"04";
	CONSTANT OP_REQ			: STD_LOGIC_VECTOR(15 downto 0) := x"0100";
	CONSTANT OP_RESP		: STD_LOGIC_VECTOR(15 downto 0) := x"0200";
	CONSTANT ARP_REQ		: STD_LOGIC_VECTOR(63 downto 0) := (OP_REQ & PLEN_IPV4 & HLEN_ETH & PTYPE_IPV4 & HTYPE_ETH);
	CONSTANT ARP_RESP		: STD_LOGIC_VECTOR(63 downto 0) := (OP_RESP & PLEN_IPV4 & HLEN_ETH & PTYPE_IPV4 & HTYPE_ETH);
	
    -- constants for frmaer
   CONSTANT c_arp_packet            : STD_LOGIC_VECTOR(3*6*73-1 DOWNTO 0) := "0" & X"FF" & REMOTE_MAC(15 downto 0) & X"ffffffffffff" & -- start of correctly targeted ARP -- start of different targeted ARP
                                                                           "0" & X"FF" & ARP_REQ(15 downto 0) & ARP_ETYPE & REMOTE_MAC(47 downto 16) &
                                                                           "0" & X"FF" & REMOTE_MAC(15 downto 0) & ARP_REQ(63 downto 16) &
                                                                           "0" & X"FF" & REMOTE_IP & REMOTE_MAC(47 downto 16) &
                                                                           "0" & X"FF" & OTHER_IP(15 downto 0) & X"FFFFFFFFFFFF" &
                                                                           "1" & X"03" & X"000000000000" & OTHER_IP(31 downto 16) & 
                                                                           "0" & X"FF" & REMOTE_MAC(15 downto 0) & X"ffffffffffff" & -- start of correctly targeted ARP
                                                                           "0" & X"FF" & ARP_REQ(15 downto 0) & ARP_ETYPE & REMOTE_MAC(47 downto 16) &
                                                                           "0" & X"FF" & REMOTE_MAC(15 downto 0) & ARP_REQ(63 downto 16) &
                                                                           "0" & X"FF" & REMOTE_IP & REMOTE_MAC(47 downto 16) &
                                                                           "0" & X"FF" & LOCAL_IP(15 downto 0) & X"FFFFFFFFFFFF" &
                                                                           "1" & X"03" & X"000000000000" & LOCAL_IP(31 downto 16) &
                                                                           "0" & X"FF" & LOCAL_MAC(15 downto 0) & REMOTE_MAC & -- start of correctly targeted ARP
                                                                           "0" & X"FF" & ARP_RESP(15 downto 0) & ARP_ETYPE & LOCAL_MAC(47 downto 16) &
                                                                           "0" & X"FF" & LOCAL_MAC(15 downto 0) & ARP_RESP(63 downto 16) &
                                                                           "0" & X"FF" & LOCAL_IP & LOCAL_MAC(47 downto 16) &
                                                                           "0" & X"FF" & REMOTE_IP(15 downto 0) & REMOTE_MAC &
                                                                           "1" & X"03" & X"000000000000" & REMOTE_IP(31 downto 16)     ; 
                                                                           

    SIGNAL eth_tx_clk                : STD_LOGIC := '0';
    SIGNAL eth_rx_clk                : STD_LOGIC := '1';
    SIGNAL axi_clk                   : STD_LOGIC := '0';
    SIGNAL axi_rst                  : STD_LOGIC;
    
    SIGNAL deframer_sosi        : t_axi4_sosi;
    SIGNAL deframer_siso        : t_axi4_siso;
    SIGNAL deframer_data        : STD_LOGIC_VECTOR(63 downto 0);
    
    SIGNAL framer_sosi          : t_axi4_sosi_arr(0 to 0);
    SIGNAL framer_siso          : t_axi4_siso_arr(0 to 0);
    SIGNAL framer_data        : STD_LOGIC_VECTOR(63 downto 0); -- debug signal
    SIGNAL eth_out_sosi              : t_axi4_sosi;
    SIGNAL eth_out_siso              : t_axi4_siso;
   
    
    SIGNAL       dbg_mac_word_count      :  INTEGER;
    SIGNAL   dbg_mac_receiving       :  BOOLEAN;
    SIGNAL   dbg_arp_detected          : BOOLEAN;
 
   -- Testbench
   SIGNAL reset                     : STD_LOGIC;
   SIGNAL finished_sim              : STD_LOGIC;
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
   SIGNAL packet_number             : INTEGER := 0;

 
   SIGNAL eth_pause_rx_enable       : STD_LOGIC_VECTOR(8 downto 0);
   SIGNAL eth_pause_rx_req          : STD_LOGIC_VECTOR(8 downto 0);
   SIGNAL eth_pause_rx_ack          : STD_LOGIC_VECTOR(8 downto 0);
    -- traffic generator signals
    SIGNAL sending_arp      : BOOLEAN;
    SIGNAL arp_payload      : INTEGER;
    SIGNAL send_arp         : STD_LOGIC;
    
BEGIN
  
    deframer_data <= deframer_sosi.tdata(63 downto 0);
    framer_data <= framer_sosi(0).tdata(63 downto 0);
 -- Initiate process which simulates the deframer as an AXI4 stream source.
 ---------------------------------------------------------------------------
-- Traffic Generators  --
---------------------------------------------------------------------------
-- deframer output 
arp_control: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         IF sending_arp = TRUE THEN
            IF framer_siso(0).tready = '1' THEN
               -- IF arp_payload = 0 THEN
               IF arp_payload = 5 THEN
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

   deframer_sosi.tvalid <= '1' WHEN sending_arp = TRUE ELSE '0';

   
arp_data: PROCESS(arp_payload, sending_arp)
   BEGIN
      IF sending_arp = TRUE THEN
         deframer_sosi.tdata(63 DOWNTO 0) <= c_arp_packet((arp_payload*73)+63 downto (arp_payload*73)+0);
         deframer_sosi.tkeep(7 DOWNTO 0) <= c_arp_packet((arp_payload*73)+71 downto (arp_payload*73)+64);
         deframer_sosi.tlast <= c_arp_packet((arp_payload*73)+72);
      ELSE
         deframer_sosi.tdata(63 DOWNTO 0) <= X"0000000000000000";
         deframer_sosi.tkeep(7 DOWNTO 0) <= X"00";
         deframer_sosi.tlast <= '0';
      END IF;
   END PROCESS;
   
--------------------------------------------------------------------------
-- Clocks  --
---------------------------------------------------------------------------

   eth_tx_clk <= NOT eth_tx_clk AFTER c_eth_tx_clk_period/2;

   eth_rx_clk <= NOT eth_rx_clk AFTER c_eth_rx_clk_period/2;

   axi_clk <= NOT axi_clk  AFTER c_axi_clk_period/2;  
   
    arp_module: ENTITY ap_lib.arp_responder
	PORT MAP(
		clk					=> axi_clk, 
		rst					=> reset,
		                     
		eth_addr_ip		    => LOCAL_IP,
		eth_addr_mac	    => LOCAL_MAC,
		                     
		frame_in_sosi  		=> deframer_sosi,
		frame_in_siso		=> deframer_siso,
		                     
		frame_out_siso 		=> framer_siso(0),
		frame_out_sosi		=> framer_sosi(0));

dut: ENTITY eth_lib.ethernet_framer
     GENERIC MAP (g_technology            => c_tech_select_default,
                  g_num_frame_inputs      => 1,
                  g_max_packet_length     => 8192,
                  g_lane_priority         => (c_arp_priority, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1))
     PORT MAP (eth_tx_clk                 => eth_tx_clk,
               eth_rx_clk                 => eth_rx_clk,
               axi_clk                    => axi_clk,
               axi_rst                    => reset,
               eth_tx_rst                 => reset,
               eth_address_ip             => LOCAL_IP,
               eth_address_mac            => C_LOCAL_MAC,
               eth_pause_rx_enable        => eth_pause_rx_enable,
               eth_pause_rx_req           => eth_pause_rx_req,
               eth_pause_rx_ack           => eth_pause_rx_ack,
               eth_out_sosi               => eth_out_sosi,
               eth_out_siso               => eth_out_siso,
               framer_in_sosi             => framer_sosi,
               framer_in_siso             => framer_siso);

               
---------------------------------------------------------------------------
-- Packet Decoder  --
---------------------------------------------------------------------------
-- Generate textual descriptions of the packets

pkt_decode: ENTITY eth_lib.packet_decoder
            PORT MAP (clk           => eth_tx_clk,
                      reset         => reset,
                      dbg_mac_word_count=> dbg_mac_word_count,
                      dbg_mac_receiving => dbg_mac_receiving ,
                      dbg_arp_detected  => dbg_arp_detected  ,
                      eth_out_sosi  => eth_out_sosi,
                      eth_out_siso  => eth_out_siso);
               
               


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
         IF mac_recieving = TRUE THEN
            ASSERT (eth_out_sosi.tlast = '0' OR mac_keep_long(7 DOWNTO 0) /= X"00" ) REPORT "PROTOCOL: Last asserted with tkeep zero" SEVERITY failure;
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
                              ASSERT (mac_word_long(i*8+7 DOWNTO i*8) = c_arp_packet((((6-mac_word_count)*73) +63-(i-4)*8) DOWNTO ((6-mac_word_count)*73) +56-(i-4)*8)) REPORT "ARP: Payload Incorrect" SEVERITY failure;
                           ELSE
                              ASSERT (mac_word_long(i*8+7 DOWNTO i*8) = c_arp_packet((((6-mac_word_count-1)*73) +31-i*8) DOWNTO ((6- mac_word_count-1)*73) +24-i*8)) REPORT "ARP: Payload Incorrect" SEVERITY failure;
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
          
          
        -- Test Transmisison
        WAIT UNTIL RISING_EDGE(axi_clk);
        send_arp <= '1'; 

        WAIT UNTIL RISING_EDGE(axi_clk);
        send_arp <= '0'; 

        WAIT UNTIL sending_arp = FALSE;
        
        WAIT UNTIL FALLING_EDGE(arp_detected);
        WAIT FOR 100 ns;
        REPORT "Finished Simulation" SEVERITY note;
        WAIT;
    END PROCESS;
    
END tb;
   