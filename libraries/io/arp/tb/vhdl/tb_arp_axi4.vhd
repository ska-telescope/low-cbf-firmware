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

LIBRARY IEEE, common_lib, axi4_lib, arp_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
use common_lib.common_mem_pkg.ALL;

ENTITY tb_arp_axi4 IS
END tb_arp_axi4;

ARCHITECTURE tb OF tb_arp_axi4 IS

    CONSTANT MM_CLK_PERIOD  : TIME := 6.4 ns;
    CONSTANT C_RESET_LEN    : NATURAL := 4;   
    CONSTANT LOCAL_IP       : STD_LOGIC_VECTOR(31 downto 0) := x"0201010A";
    CONSTANT LOCAL_MAC      : STD_LOGIC_VECTOR(47 downto 0) := x"00F1E0D9C8B7"; 
    CONSTANT REMOTE_IP      : STD_LOGIC_VECTOR(31 downto 0) := x"0101010A";
    CONSTANT REMOTE_MAC     : STD_LOGIC_VECTOR(47 downto 0) := x"00E5D4C3B2A1"; 
    CONSTANT OTHER_IP       : STD_LOGIC_VECTOR(31 downto 0) := x"0A01010A";
    
    CONSTANT ARP_ETYPE      : STD_LOGIC_VECTOR(15 downto 0) := x"0608";    
	CONSTANT HTYPE_ETH		: STD_LOGIC_VECTOR(15 downto 0) := x"0100";
	CONSTANT PTYPE_IPV4		: STD_LOGIC_VECTOR(15 downto 0) := x"0008";
	CONSTANT HLEN_ETH 		: STD_LOGIC_VECTOR(7 downto 0) := x"06";
	CONSTANT PLEN_IPV4		: STD_LOGIC_VECTOR(7 downto 0) := x"04";
	CONSTANT OP_REQ			: STD_LOGIC_VECTOR(15 downto 0) := x"0100";
	CONSTANT OP_RESP		: STD_LOGIC_VECTOR(15 downto 0) := x"0200";
	CONSTANT ARP_REQ		: STD_LOGIC_VECTOR(63 downto 0) := (OP_REQ & PLEN_IPV4 & HLEN_ETH & PTYPE_IPV4 & HTYPE_ETH);
	CONSTANT ARP_RESP		: STD_LOGIC_VECTOR(63 downto 0) := (OP_RESP & PLEN_IPV4 & HLEN_ETH & PTYPE_IPV4 & HTYPE_ETH);
	
    SIGNAL mm_clk       : STD_LOGIC := '0';
    SIGNAL mm_rst       : STD_LOGIC;
    
    SIGNAL deframer_sosi        : t_axi4_sosi;
    SIGNAL deframer_siso        : t_axi4_siso;
    SIGNAL deframer_data        : STD_LOGIC_VECTOR(63 downto 0);
    
    SIGNAL framer_sosi          : t_axi4_sosi;
    SIGNAL framer_siso          : t_axi4_siso;
    SIGNAL framer_data        : STD_LOGIC_VECTOR(63 downto 0);
    
BEGIN

    mm_clk <= NOT mm_clk  AFTER MM_CLK_PERIOD/2;
    mm_rst <= '1', '0'    AFTER MM_CLK_PERIOD*C_RESET_LEN;
  
    deframer_data <= deframer_sosi.tdata(63 downto 0);
    framer_data <= framer_sosi.tdata(63 downto 0);
    
 -- Initiate process which simulates the deframer as an AXI4 stream source.
    p_framer_source : PROCESS
    BEGIN
        deframer_sosi.tvalid <= '0';
        deframer_sosi.tdata <= (others => '0');
        deframer_sosi.tkeep <= (others => '0');
        deframer_sosi.tlast <= '0';
		
		wait until mm_rst = '0';
		wait for 15 ns;
			deframer_sosi.tdata(63 downto 0) <= (others => '0');
			deframer_sosi.tvalid <= '1';
            framer_siso.tready <= '1'; -- sends blank data first
            
        wait until mm_clk = '1';
            deframer_sosi.tdata(63 downto 0) <= REMOTE_MAC(15 downto 0) & X"ffffffffffff" ;
        wait until mm_clk = '1';
			deframer_sosi.tdata(63 downto 0) <= ARP_REQ(15 downto 0) & ARP_ETYPE & REMOTE_MAC(47 downto 16) ;
        wait until mm_clk = '1';
			deframer_sosi.tdata(63 downto 0) <= REMOTE_MAC(15 downto 0) & ARP_REQ(63 downto 16);
        wait until mm_clk = '1';
        	deframer_sosi.tdata(63 downto 0) <= REMOTE_IP & REMOTE_MAC(47 downto 16);
        wait until mm_clk = '1';
            deframer_sosi.tdata(63 downto 0) <= LOCAL_IP(15 downto 0) & X"FFFFFFFFFFFF" ;
        wait until mm_clk = '1';
			deframer_sosi.tdata(63 downto 0) <= X"000000000000" & LOCAL_IP(31 downto 16);
			deframer_sosi.tlast <= '1';
        wait until mm_clk = '1';
			deframer_sosi.tvalid <= '0';
			deframer_sosi.tlast <= '0';
        wait until mm_clk = '1';
            deframer_sosi.tvalid <= '1';
            deframer_sosi.tdata(63 downto 0) <= REMOTE_MAC(15 downto 0) & X"ffffffffffff" ;
        wait until mm_clk = '1';
			deframer_sosi.tdata(63 downto 0) <= ARP_REQ(15 downto 0) & ARP_ETYPE & REMOTE_MAC(47 downto 16) ;
        wait until mm_clk = '1';
			deframer_sosi.tdata(63 downto 0) <= REMOTE_MAC(15 downto 0) & ARP_REQ(63 downto 16);
        wait until mm_clk = '1';
        	deframer_sosi.tdata(63 downto 0) <= REMOTE_IP & REMOTE_MAC(47 downto 16);
        wait until mm_clk = '1';
            deframer_sosi.tdata(63 downto 0) <= OTHER_IP(15 downto 0) & X"FFFFFFFFFFFF" ;
        wait until mm_clk = '1';
			deframer_sosi.tdata(63 downto 0) <= X"000000000000" & OTHER_IP(31 downto 16);
			deframer_sosi.tlast <= '1';
		wait until mm_clk = '1';
			deframer_sosi.tvalid <= '0';
			deframer_sosi.tlast <= '0';			
        wait until mm_clk = '1';
			deframer_sosi.tvalid <= '0';
			deframer_sosi.tlast <= '0';
        wait until mm_clk = '1';
            deframer_sosi.tvalid <= '1';
            deframer_sosi.tdata(63 downto 0) <= REMOTE_MAC(15 downto 0) & X"ffffffffffff"; 
        wait until mm_clk = '1';
			deframer_sosi.tdata(63 downto 0) <= ARP_REQ(15 downto 0) & ARP_ETYPE & REMOTE_MAC(47 downto 16) ;
        wait until mm_clk = '1';
			deframer_sosi.tdata(63 downto 0) <= REMOTE_MAC(15 downto 0) & ARP_REQ(63 downto 16);
        wait until mm_clk = '1';
        	deframer_sosi.tdata(63 downto 0) <= REMOTE_IP & REMOTE_MAC(47 downto 16);
        wait until mm_clk = '1';
            deframer_sosi.tdata(63 downto 0) <= LOCAL_IP(15 downto 0) & X"FFFFFFFFFFFF" ;
        wait until mm_clk = '1';
			deframer_sosi.tdata(63 downto 0) <= X"000000000000" & LOCAL_IP(31 downto 16);
			deframer_sosi.tlast <= '1';
		wait until mm_clk = '1';
			deframer_sosi.tvalid <= '0';
			deframer_sosi.tlast <= '0';			            
    END PROCESS;

    arp_module: ENTITY arp_lib.arp_responder
	PORT MAP(
		clk					=> mm_clk, 
		rst					=> mm_rst,
		                     
		eth_addr_ip		    => LOCAL_IP,
		eth_addr_mac	    => LOCAL_MAC,
		                     
		frame_in_sosi  		=> deframer_sosi,
		frame_in_siso		=> deframer_siso,
		                     
		frame_out_siso 		=> framer_siso,
		frame_out_sosi		=> framer_sosi
);



END tb;
