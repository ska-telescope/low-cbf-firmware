-------------------------------------------------------------------------------
--
-- Copyright (C) 2010
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

-- Purpose: Testbench for eth_ihl_to_20.vhd
-- Description:
-- Usage:
--   > as 10
--   > run -all

LIBRARY IEEE, common_lib, dp_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE dp_lib.dp_stream_pkg.ALL;
USE common_lib.common_network_layers_pkg.ALL;
USE work.eth_pkg.ALL;


ENTITY tb_eth_IHL_to_20 IS
END tb_eth_IHL_to_20;


ARCHITECTURE tb OF tb_eth_IHL_to_20 IS

  CONSTANT clk_period : TIME := 5 ns;  -- 100 MHz


  SIGNAL tb_end         : STD_LOGIC := '0';
  SIGNAL clk            : STD_LOGIC := '0';
  SIGNAL rst            : STD_LOGIC;


  SIGNAL snk_in         : t_dp_sosi := c_dp_sosi_rst;
  SIGNAL snk_out        : t_dp_siso;
  
  SIGNAL src_in         : t_dp_siso := c_dp_siso_rdy;
  SIGNAL src_out        : t_dp_sosi;

  TYPE int_arr is array (natural range <>) of integer;
  CONSTANT c_IHL_to_test : int_arr(1 to 11) := (5,6,7,8,9,10,11,12,13,14,15);
  CONSTANT c_len_to_test : int_arr(1 to 5) := (0,1,16,20,3000);
  

  PROCEDURE gen_eth_frame (constant IHL             : natural;
                           constant UDP_payload_len : natural;
                           signal   clk             : in std_logic;
                           signal   snk_in          : inout t_dp_sosi) is
  BEGIN
    snk_in.sop   <= '1';
    snk_in.valid <= '1';
    snk_in.data  <= RESIZE_DP_DATA(X"0000FFFF");  -- Eth header
    WAIT UNTIL rising_edge(clk);
    snk_in.sop   <= '0';
    snk_in.data  <= RESIZE_DP_DATA(X"FFFFFFFF");
    WAIT UNTIL rising_edge(clk);
    snk_in.data  <= RESIZE_DP_DATA(X"10FA0004");
    WAIT UNTIL rising_edge(clk);
    snk_in.data  <= RESIZE_DP_DATA(X"00000800");
    WAIT UNTIL rising_edge(clk);
    snk_in.data  <= RESIZE_DP_DATA(X"4" &        -- IPv4 header 
                                   TO_UVEC(IHL,c_network_ip_header_length_w) &
                                   X"00" &
                                   TO_UVEC((IHL+UDP_payload_len+2)*4,c_network_ip_total_length_w));
    WAIT UNTIL rising_edge(clk);
    snk_in.data  <= RESIZE_DP_DATA(X"00004000");
    WAIT UNTIL rising_edge(clk);
    snk_in.data  <= RESIZE_DP_DATA(X"80110000");
    WAIT UNTIL rising_edge(clk);
    snk_in.data  <= RESIZE_DP_DATA(X"0A0B0001");
    WAIT UNTIL rising_edge(clk);
    snk_in.data  <= RESIZE_DP_DATA(X"0A0B00FF");
    WAIT UNTIL rising_edge(clk);

    FOR I IN 6 TO IHL LOOP
      snk_in.data  <= RESIZE_DP_DATA(X"BAD000" & TO_UVEC(I,c_network_ip_header_length_w));  -- optionnal option word
      WAIT UNTIL rising_edge(clk);
    END LOOP;
    
    snk_in.data  <= RESIZE_DP_DATA(X"10FA10FA");  -- UDP header
    WAIT UNTIL rising_edge(clk);
    snk_in.data  <= RESIZE_DP_DATA(TO_UVEC((UDP_payload_len+2)*4,c_network_udp_total_length_w) & X"0000");
    WAIT UNTIL rising_edge(clk);
    
    FOR I IN 0 TO UDP_payload_len-1 LOOP                  -- UDP payload
      snk_in.data  <= RESIZE_DP_DATA(X"BEEF" & TO_UVEC(I,16));  
      WAIT UNTIL rising_edge(clk);
    END LOOP;

    snk_in.data  <= RESIZE_DP_DATA(X"CCCCCCCC");  -- Eth CRC
    snk_in.eop   <= '1';
    WAIT UNTIL rising_edge(clk);

    snk_in.data  <= (OTHERS=>'0');
    snk_in.valid <= '0';
    snk_in.eop   <= '0';
    WAIT UNTIL rising_edge(clk);
  END PROCEDURE gen_eth_frame;

  PROCEDURE check_eth_frame ( constant UDP_payload_len : natural;
                              signal   clk             : in std_logic;
                              signal   src_out         : in t_dp_sosi) is
    CONSTANT c_IHL : natural := 5;
  BEGIN
    
     -- Eth header
    WAIT UNTIL falling_edge(clk) and src_out.valid = '1' and src_out.sop = '1';
    ASSERT src_out.data(31 downto 0) = X"0000FFFF" REPORT "Wrong word align and Destination MAC"       SEVERITY FAILURE; 
    WAIT UNTIL falling_edge(clk) and src_out.valid = '1';
    ASSERT src_out.data(31 downto 0) = X"FFFFFFFF" REPORT "Wrong Destination MAC"                      SEVERITY FAILURE;
    WAIT UNTIL falling_edge(clk) and src_out.valid = '1';
    ASSERT src_out.data(31 downto 0) = X"10FA0004" REPORT "Wrong Source MAC"                           SEVERITY FAILURE;
    WAIT UNTIL falling_edge(clk) and src_out.valid = '1';
    ASSERT src_out.data(31 downto 0) = X"00000800" REPORT "Wrong Source MAC and EtherType"             SEVERITY FAILURE;
    
    -- IPv4 header
    WAIT UNTIL falling_edge(clk) and src_out.valid = '1';
    ASSERT src_out.data(31 downto 0) = X"4" &
                                       TO_UVEC(c_IHL,c_network_ip_header_length_w) &
                                       X"00" &
                                       TO_UVEC((c_IHL+UDP_payload_len+2)*4,c_network_ip_total_length_w)
                                                   REPORT "Wrong Version / IHL / Total Length"         SEVERITY FAILURE;
    
    WAIT UNTIL falling_edge(clk) and src_out.valid = '1';
    ASSERT src_out.data(31 downto 0) = X"00004000" REPORT "Wrong identification / Flags / Frag Offset" SEVERITY FAILURE;
    WAIT UNTIL falling_edge(clk) and src_out.valid = '1';
    ASSERT src_out.data(31 downto 0) = X"80110000" REPORT "Wrong TTL / Protocol / Checksum"            SEVERITY FAILURE;
    WAIT UNTIL falling_edge(clk) and src_out.valid = '1';
    ASSERT src_out.data(31 downto 0) = X"0A0B0001" REPORT "Wrong Source IP"                            SEVERITY FAILURE;
    WAIT UNTIL falling_edge(clk) and src_out.valid = '1';
    ASSERT src_out.data(31 downto 0) = X"0A0B00FF" REPORT "Wrong Dest IP"                              SEVERITY FAILURE;
    -- No options Here

    -- UDP header
    WAIT UNTIL falling_edge(clk) and src_out.valid = '1';                                                                 
    ASSERT src_out.data(31 downto 0) = X"10FA10FA" REPORT "Wrong UDP ports"                            SEVERITY FAILURE;
    WAIT UNTIL falling_edge(clk) and src_out.valid = '1';
    ASSERT src_out.data(31 downto 0) = TO_UVEC((UDP_payload_len+2)*4,c_network_udp_total_length_w) &
                                       X"0000" 
                                                   REPORT "Wrong UDP length / CRC"                     SEVERITY FAILURE;
    -- UDP payload
    FOR I IN 0 TO UDP_payload_len-1 LOOP
      WAIT UNTIL falling_edge(clk) and src_out.valid = '1';
      ASSERT src_out.data(31 downto 0) = X"BEEF" & TO_UVEC(I,16) REPORT "Wrong UDP Payload"            SEVERITY FAILURE;
--      ASSERT src_out.data(31 downto 0) = X"BEEF" & TO_UVEC(I,16) REPORT "Wrong UDP Payload: 0xBEEF" & TO_UVEC(I,16)'IMAGE                SEVERITY FAILURE;
    END LOOP;

    -- Eth CRC
    WAIT UNTIL falling_edge(clk) and src_out.valid = '1' and src_out.eop   <= '1';
    ASSERT src_out.data(31 downto 0) = X"CCCCCCCC" REPORT "Wrong Eth CRC"                              SEVERITY FAILURE;

  END PROCEDURE check_eth_frame;
  
  
BEGIN

  clk <= NOT clk OR tb_end AFTER clk_period/2;
  rst <= '1', '0' AFTER clk_period*7;
  
  
  gen_frame: PROCESS  
  BEGIN
    WAIT UNTIL rst='0';

    FOR len_n in c_len_to_test'RANGE LOOP
      FOR IHL_n in c_IHL_to_test'RANGE LOOP
        WAIT FOR 50 ns; WAIT UNTIL rising_edge(clk);
        gen_eth_frame (c_IHL_to_test(IHL_n),
                       c_len_to_test(len_n),
                       clk,snk_in);
      END LOOP;
    END LOOP;
    
    wait for 1 ms;
    IF tb_end='0' THEN
      ASSERT FALSE REPORT "ERROR: Processing was too long. DUT is stuck" SEVERITY FAILURE;
    END IF;
    WAIT;
  END PROCESS;

  
  dut : ENTITY work.eth_IHL_to_20
  GENERIC MAP (
    incoming_IHL => 24
  )
  PORT MAP (
    rst         => rst,
    clk         => clk,

    -- Streaming Sink
    snk_in      => snk_in,
    snk_out     => snk_out,
    
    -- Streaming Source
    src_in      => src_in,
    src_out     => src_out
  );
  
  
  check_frame: PROCESS  
  BEGIN

    FOR len_n in c_len_to_test'RANGE LOOP
      FOR IHL_n in c_IHL_to_test'RANGE LOOP
        check_eth_frame (c_len_to_test(len_n), clk, src_out);
      END LOOP;
    END LOOP;
    
    WAIT for 1 us;
    tb_end <= '1';
    ASSERT FALSE REPORT "Simulation tb_eth_IHL_to_20 finished." SEVERITY NOTE;
    WAIT;
  END PROCESS;

END tb;
