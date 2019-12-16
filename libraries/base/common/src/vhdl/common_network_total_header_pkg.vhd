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

-- Purpose: Map the fields of network headers on to a total header array of words
-- Description:
--
-- * 32b, word align = 2 octets
--         wi: |0  1  2  3 |4  5  6  7  8 | 9 10 | ...
--    octet:   |---------------------------------|---------
--         0   |x          |              |      |
--         1   |x   eth    |   ipv4       | udp  | udp payload
--         2   |    14     |   20         |  8   |
--         3   |           |              |      |
--
-- * 64b, word align = 6 octets
--         wi: |0  1  2 |3  4 |5 | ...
--    octet:   |-----------------|---------
--         0   |x       |     |  |
--         1   |x  eth  |ipv4 |u | udp payload
--         2   |x  14   | 20  |d |
--         3   |x    ___|     |p |
--         4   |x   |         |8 |
--         5   |x   |         |  |
--         6   |    |         |  |
--         7   |    |         |  |
--
-- The word align separates the network total header and the udp payload on a word boundary. This allows the network 
-- total header to be handled as a t_network_total_header_<word width>_arr. It is also useful for the data path
-- application that can handle the UDP payload on word boundaries. For output to the MAC the word align can be removed
-- using dp_pad_remove. For input from the MAC the word align can be inserted using dp_pad_insert.
--

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;
USE work.common_network_layers_pkg.ALL;

PACKAGE common_network_total_header_pkg IS

  -- Define total network header that fits all relevant packets in common_network_layers_pkg, because they have the same total header length
  CONSTANT c_network_total_header_arp_len   : NATURAL := c_network_eth_header_len + c_network_arp_data_len;                               -- = 14 + 28     = 42
  CONSTANT c_network_total_header_icmp_len  : NATURAL := c_network_eth_header_len + c_network_ip_header_len + c_network_icmp_header_len;  -- = 14 + 20 + 8 = 42
  CONSTANT c_network_total_header_udp_len   : NATURAL := c_network_eth_header_len + c_network_ip_header_len + c_network_udp_header_len;   -- = 14 + 20 + 8 = 42
  
  CONSTANT c_network_total_header_len       : NATURAL := 42;

  -----------------------------------------------------------------------------
  -- Aggregate all supported network headers into one record
  -----------------------------------------------------------------------------
  
  TYPE t_network_total_header IS RECORD
    eth  : t_network_eth_header;
    arp  : t_network_arp_packet;
    ip   : t_network_ip_header;
    icmp : t_network_icmp_header;
    udp  : t_network_udp_header;
  END RECORD;

  CONSTANT c_network_total_header_ones : t_network_total_header := (c_network_eth_header_ones,
                                                                    c_network_arp_packet_ones,
                                                                    c_network_ip_header_ones,
                                                                    c_network_icmp_header_ones,
                                                                    c_network_udp_header_ones);

  -----------------------------------------------------------------------------
  -- Map total network header in words array
  -----------------------------------------------------------------------------
  
  CONSTANT c_network_total_header_32b_align_len : NATURAL := 2;                                         -- to align eth, ip and udp payload to 32 bit boundaries
  CONSTANT c_network_total_header_32b_align_w   : NATURAL := c_network_total_header_32b_align_len*c_8;
  
  CONSTANT c_network_total_header_64b_align_len : NATURAL := 6;                                         -- to align eth, ip and udp payload to 32 bit boundaries and
  CONSTANT c_network_total_header_64b_align_w   : NATURAL := c_network_total_header_64b_align_len*c_8;  --                      udp payload to 64 bit boundaries
  
  CONSTANT c_network_total_header_32b_nof_words       : NATURAL := (c_network_total_header_32b_align_len + c_network_total_header_len)/4;  -- = 44 / c_word_sz     = 11
  CONSTANT c_network_total_header_64b_nof_words       : NATURAL := (c_network_total_header_64b_align_len + c_network_total_header_len)/8;  -- = 48 / c_longword_sz = 6
  
  TYPE t_network_total_header_32b_arr IS ARRAY(0 TO c_network_total_header_32b_nof_words-1) OF STD_LOGIC_VECTOR(c_32-1 DOWNTO 0);
  TYPE t_network_total_header_64b_arr IS ARRAY(0 TO c_network_total_header_64b_nof_words-1) OF STD_LOGIC_VECTOR(c_64-1 DOWNTO 0);
  
  -- Word indices in the total header array to know when the field in the mapped record is valid
  -- . 32b
  CONSTANT c_network_total_header_32b_eth_lo_wi              : NATURAL := 0;  -- first word index
  CONSTANT c_network_total_header_32b_eth_dst_mac_wi         : NATURAL := 1;
  CONSTANT c_network_total_header_32b_eth_src_mac_wi         : NATURAL := 3;
  CONSTANT c_network_total_header_32b_eth_type_wi            : NATURAL := 3;
  CONSTANT c_network_total_header_32b_eth_hi_wi              : NATURAL := 3;  -- last word index
  CONSTANT c_network_total_header_32b_eth_nof_words          : NATURAL := c_network_total_header_32b_eth_hi_wi - c_network_total_header_32b_eth_lo_wi + 1;
  
  CONSTANT c_network_total_header_32b_ip_lo_wi               : NATURAL := 4;  -- first word index
  CONSTANT c_network_total_header_32b_ip_version_wi          : NATURAL := 4;
  CONSTANT c_network_total_header_32b_ip_header_length_wi    : NATURAL := 4;
  CONSTANT c_network_total_header_32b_ip_services_wi         : NATURAL := 4;
  CONSTANT c_network_total_header_32b_ip_total_length_wi     : NATURAL := 4;
  CONSTANT c_network_total_header_32b_ip_identification_wi   : NATURAL := 5;
  CONSTANT c_network_total_header_32b_ip_flags_wi            : NATURAL := 5;
  CONSTANT c_network_total_header_32b_ip_fragment_offset_wi  : NATURAL := 5;
  CONSTANT c_network_total_header_32b_ip_time_to_live_wi     : NATURAL := 6;
  CONSTANT c_network_total_header_32b_ip_protocol_wi         : NATURAL := 6;
  CONSTANT c_network_total_header_32b_ip_header_checksum_wi  : NATURAL := 6;
  CONSTANT c_network_total_header_32b_ip_src_ip_addr_wi      : NATURAL := 7;
  CONSTANT c_network_total_header_32b_ip_dst_ip_addr_wi      : NATURAL := 8;
  CONSTANT c_network_total_header_32b_ip_hi_wi               : NATURAL := 8;  -- last word index
  CONSTANT c_network_total_header_32b_ip_nof_words           : NATURAL := c_network_total_header_32b_ip_hi_wi - c_network_total_header_32b_ip_lo_wi + 1;

  CONSTANT c_network_total_header_32b_arp_lo_wi              : NATURAL := 4;   -- first word index
  CONSTANT c_network_total_header_32b_arp_htype_wi           : NATURAL := 4;
  CONSTANT c_network_total_header_32b_arp_ptype_wi           : NATURAL := 4;
  CONSTANT c_network_total_header_32b_arp_hlen_wi            : NATURAL := 5;
  CONSTANT c_network_total_header_32b_arp_plen_wi            : NATURAL := 5;
  CONSTANT c_network_total_header_32b_arp_oper_wi            : NATURAL := 5;
  CONSTANT c_network_total_header_32b_arp_sha_wi             : NATURAL := 7;
  CONSTANT c_network_total_header_32b_arp_spa_wi             : NATURAL := 8;
  CONSTANT c_network_total_header_32b_arp_tha_wi             : NATURAL := 9;
  CONSTANT c_network_total_header_32b_arp_tpa_wi             : NATURAL := 10;
  CONSTANT c_network_total_header_32b_arp_hi_wi              : NATURAL := 10;  -- last word index
  CONSTANT c_network_total_header_32b_arp_nof_words          : NATURAL := c_network_total_header_32b_arp_hi_wi - c_network_total_header_32b_arp_lo_wi + 1;

  CONSTANT c_network_total_header_32b_icmp_lo_wi             : NATURAL := 9;   -- first word index                                            
  CONSTANT c_network_total_header_32b_icmp_msg_type_wi       : NATURAL := 9;                                                                  
  CONSTANT c_network_total_header_32b_icmp_code_wi           : NATURAL := 9;                                                                  
  CONSTANT c_network_total_header_32b_icmp_checksum_wi       : NATURAL := 9;                                                                  
  CONSTANT c_network_total_header_32b_icmp_id_wi             : NATURAL := 10;                                                                 
  CONSTANT c_network_total_header_32b_icmp_sequence_wi       : NATURAL := 10;                                                                 
  CONSTANT c_network_total_header_32b_icmp_hi_wi             : NATURAL := 10;  -- last word index                                             
  CONSTANT c_network_total_header_32b_icmp_nof_words         : NATURAL := c_network_total_header_32b_icmp_hi_wi - c_network_total_header_32b_icmp_lo_wi + 1;
  
  CONSTANT c_network_total_header_32b_udp_lo_wi              : NATURAL := 9;   -- first word index
  CONSTANT c_network_total_header_32b_udp_src_port_wi        : NATURAL := 9;
  CONSTANT c_network_total_header_32b_udp_dst_port_wi        : NATURAL := 9;
  CONSTANT c_network_total_header_32b_udp_total_length_wi    : NATURAL := 10;
  CONSTANT c_network_total_header_32b_udp_checksum_wi        : NATURAL := 10;
  CONSTANT c_network_total_header_32b_udp_hi_wi              : NATURAL := 10;  -- last word index
  CONSTANT c_network_total_header_32b_udp_nof_words          : NATURAL := c_network_total_header_32b_udp_hi_wi - c_network_total_header_32b_udp_lo_wi + 1;

  -- . 64b
  CONSTANT c_network_total_header_64b_eth_lo_wi              : NATURAL := 0;  -- first word index
  CONSTANT c_network_total_header_64b_eth_dst_mac_wi         : NATURAL := 1;
  CONSTANT c_network_total_header_64b_eth_src_mac_wi         : NATURAL := 2;
  CONSTANT c_network_total_header_64b_eth_type_wi            : NATURAL := 2;
  CONSTANT c_network_total_header_64b_eth_hi_wi              : NATURAL := 2;  -- last word index
  CONSTANT c_network_total_header_64b_eth_nof_words          : NATURAL := c_network_total_header_64b_eth_hi_wi - c_network_total_header_64b_eth_lo_wi + 1;
  
  CONSTANT c_network_total_header_64b_ip_lo_wi               : NATURAL := 2;  -- first word index
  CONSTANT c_network_total_header_64b_ip_version_wi          : NATURAL := 2;
  CONSTANT c_network_total_header_64b_ip_header_length_wi    : NATURAL := 2;
  CONSTANT c_network_total_header_64b_ip_services_wi         : NATURAL := 2;
  CONSTANT c_network_total_header_64b_ip_total_length_wi     : NATURAL := 2;
  CONSTANT c_network_total_header_64b_ip_identification_wi   : NATURAL := 3;
  CONSTANT c_network_total_header_64b_ip_flags_wi            : NATURAL := 3;
  CONSTANT c_network_total_header_64b_ip_fragment_offset_wi  : NATURAL := 3;
  CONSTANT c_network_total_header_64b_ip_time_to_live_wi     : NATURAL := 3;
  CONSTANT c_network_total_header_64b_ip_protocol_wi         : NATURAL := 3;
  CONSTANT c_network_total_header_64b_ip_header_checksum_wi  : NATURAL := 3;
  CONSTANT c_network_total_header_64b_ip_src_ip_addr_wi      : NATURAL := 4;
  CONSTANT c_network_total_header_64b_ip_dst_ip_addr_wi      : NATURAL := 4;
  CONSTANT c_network_total_header_64b_ip_hi_wi               : NATURAL := 4;  -- last word index
  CONSTANT c_network_total_header_64b_ip_nof_words           : NATURAL := c_network_total_header_64b_ip_hi_wi - c_network_total_header_64b_ip_lo_wi + 1;

  CONSTANT c_network_total_header_64b_arp_lo_wi              : NATURAL := 2;  -- first word index
  CONSTANT c_network_total_header_64b_arp_htype_wi           : NATURAL := 2;
  CONSTANT c_network_total_header_64b_arp_ptype_wi           : NATURAL := 2;
  CONSTANT c_network_total_header_64b_arp_hlen_wi            : NATURAL := 3;
  CONSTANT c_network_total_header_64b_arp_plen_wi            : NATURAL := 3;
  CONSTANT c_network_total_header_64b_arp_oper_wi            : NATURAL := 3;
  CONSTANT c_network_total_header_64b_arp_sha_wi             : NATURAL := 4;
  CONSTANT c_network_total_header_64b_arp_spa_wi             : NATURAL := 4;
  CONSTANT c_network_total_header_64b_arp_tha_wi             : NATURAL := 5;
  CONSTANT c_network_total_header_64b_arp_tpa_wi             : NATURAL := 5;
  CONSTANT c_network_total_header_64b_arp_hi_wi              : NATURAL := 5;  -- last word index
  CONSTANT c_network_total_header_64b_arp_nof_words          : NATURAL := c_network_total_header_64b_arp_hi_wi - c_network_total_header_64b_arp_lo_wi + 1;

  CONSTANT c_network_total_header_64b_icmp_lo_wi             : NATURAL := 5;  -- first word index                                            
  CONSTANT c_network_total_header_64b_icmp_msg_type_wi       : NATURAL := 5;                                                                  
  CONSTANT c_network_total_header_64b_icmp_code_wi           : NATURAL := 5;                                                                  
  CONSTANT c_network_total_header_64b_icmp_checksum_wi       : NATURAL := 5;                                                                  
  CONSTANT c_network_total_header_64b_icmp_id_wi             : NATURAL := 5;                                                                 
  CONSTANT c_network_total_header_64b_icmp_sequence_wi       : NATURAL := 5;                                                                 
  CONSTANT c_network_total_header_64b_icmp_hi_wi             : NATURAL := 5;  -- last word index                                             
  CONSTANT c_network_total_header_64b_icmp_nof_words         : NATURAL := c_network_total_header_64b_icmp_hi_wi - c_network_total_header_64b_icmp_lo_wi + 1;
  
  CONSTANT c_network_total_header_64b_udp_lo_wi              : NATURAL := 5;  -- first word index
  CONSTANT c_network_total_header_64b_udp_src_port_wi        : NATURAL := 5;
  CONSTANT c_network_total_header_64b_udp_dst_port_wi        : NATURAL := 5;
  CONSTANT c_network_total_header_64b_udp_total_length_wi    : NATURAL := 5;
  CONSTANT c_network_total_header_64b_udp_checksum_wi        : NATURAL := 5;
  CONSTANT c_network_total_header_64b_udp_hi_wi              : NATURAL := 5;  -- last word index
  CONSTANT c_network_total_header_64b_udp_nof_words          : NATURAL := c_network_total_header_64b_udp_hi_wi - c_network_total_header_64b_udp_lo_wi + 1;
  
  -----------------------------------------------------------------------------
  -- Functions to map between header record fields and header words array
  -----------------------------------------------------------------------------
  
  -- Combinatorial map of the total header array on to a network header record (type casting an array to a record is not possible, so therefore we need these functions)
  FUNCTION func_network_total_header_extract_eth( hdr_arr : t_network_total_header_32b_arr) RETURN t_network_eth_header;
  FUNCTION func_network_total_header_extract_eth( hdr_arr : t_network_total_header_64b_arr) RETURN t_network_eth_header;
  FUNCTION func_network_total_header_extract_ip(  hdr_arr : t_network_total_header_32b_arr) RETURN t_network_ip_header;
  FUNCTION func_network_total_header_extract_ip(  hdr_arr : t_network_total_header_64b_arr) RETURN t_network_ip_header;
  FUNCTION func_network_total_header_extract_arp( hdr_arr : t_network_total_header_32b_arr) RETURN t_network_arp_packet;
  FUNCTION func_network_total_header_extract_arp( hdr_arr : t_network_total_header_64b_arr) RETURN t_network_arp_packet;
  FUNCTION func_network_total_header_extract_icmp(hdr_arr : t_network_total_header_32b_arr) RETURN t_network_icmp_header;
  FUNCTION func_network_total_header_extract_icmp(hdr_arr : t_network_total_header_64b_arr) RETURN t_network_icmp_header;
  FUNCTION func_network_total_header_extract_udp( hdr_arr : t_network_total_header_32b_arr) RETURN t_network_udp_header;
  FUNCTION func_network_total_header_extract_udp( hdr_arr : t_network_total_header_64b_arr) RETURN t_network_udp_header;
  
  -- Construct the total header array from the individual header records
  FUNCTION func_network_total_header_construct_eth( eth : t_network_eth_header)                                                          RETURN t_network_total_header_32b_arr;  -- sets unused words to zero
  FUNCTION func_network_total_header_construct_eth( eth : t_network_eth_header)                                                          RETURN t_network_total_header_64b_arr;  -- sets unused words to zero
  FUNCTION func_network_total_header_construct_arp( eth : t_network_eth_header; arp : t_network_arp_packet)                              RETURN t_network_total_header_32b_arr;
  FUNCTION func_network_total_header_construct_arp( eth : t_network_eth_header; arp : t_network_arp_packet)                              RETURN t_network_total_header_64b_arr;
  FUNCTION func_network_total_header_construct_ip(  eth : t_network_eth_header; ip  : t_network_ip_header)                               RETURN t_network_total_header_32b_arr;  -- sets unused words to zero
  FUNCTION func_network_total_header_construct_ip(  eth : t_network_eth_header; ip  : t_network_ip_header)                               RETURN t_network_total_header_64b_arr;  -- sets unused words to zero
  FUNCTION func_network_total_header_construct_icmp(eth : t_network_eth_header; ip  : t_network_ip_header; icmp : t_network_icmp_header) RETURN t_network_total_header_32b_arr;
  FUNCTION func_network_total_header_construct_icmp(eth : t_network_eth_header; ip  : t_network_ip_header; icmp : t_network_icmp_header) RETURN t_network_total_header_64b_arr;
  FUNCTION func_network_total_header_construct_udp( eth : t_network_eth_header; ip  : t_network_ip_header; udp  : t_network_udp_header)  RETURN t_network_total_header_32b_arr;
  FUNCTION func_network_total_header_construct_udp( eth : t_network_eth_header; ip  : t_network_ip_header; udp  : t_network_udp_header)  RETURN t_network_total_header_64b_arr;
  
  -- Construct the response total header array for a total header array
  FUNCTION func_network_total_header_response_eth( eth_arr  : t_network_total_header_32b_arr; mac_addr : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0)) RETURN t_network_total_header_32b_arr;
  FUNCTION func_network_total_header_response_eth( eth_arr  : t_network_total_header_64b_arr; mac_addr : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0)) RETURN t_network_total_header_64b_arr;
  FUNCTION func_network_total_header_response_arp( arp_arr  : t_network_total_header_32b_arr; mac_addr : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0);
                                                                                              ip_addr  : STD_LOGIC_VECTOR(c_network_ip_addr_w-1 DOWNTO 0))
                                                                                              RETURN t_network_total_header_32b_arr;
  FUNCTION func_network_total_header_response_arp( arp_arr  : t_network_total_header_64b_arr; mac_addr : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0);
                                                                                              ip_addr  : STD_LOGIC_VECTOR(c_network_ip_addr_w-1 DOWNTO 0))
                                                                                              RETURN t_network_total_header_64b_arr;
  FUNCTION func_network_total_header_response_ip(  ip_arr   : t_network_total_header_32b_arr; mac_addr : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0)) RETURN t_network_total_header_32b_arr;
  FUNCTION func_network_total_header_response_ip(  ip_arr   : t_network_total_header_64b_arr; mac_addr : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0)) RETURN t_network_total_header_64b_arr;
  FUNCTION func_network_total_header_response_icmp(icmp_arr : t_network_total_header_32b_arr; mac_addr : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0)) RETURN t_network_total_header_32b_arr;
  FUNCTION func_network_total_header_response_icmp(icmp_arr : t_network_total_header_64b_arr; mac_addr : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0)) RETURN t_network_total_header_64b_arr;
  FUNCTION func_network_total_header_response_udp( udp_arr  : t_network_total_header_32b_arr; mac_addr : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0)) RETURN t_network_total_header_32b_arr;
  FUNCTION func_network_total_header_response_udp( udp_arr  : t_network_total_header_64b_arr; mac_addr : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0)) RETURN t_network_total_header_64b_arr;
  
END common_network_total_header_pkg;


PACKAGE BODY common_network_total_header_pkg IS

  -- Assume the total header has been padded with the word align field to have the udp payload at a 32b or 64b boundary
  -- Map the 11 32b words or 6 64b longwords from the total header to the header field records
  
  FUNCTION func_network_total_header_extract_eth(hdr_arr : t_network_total_header_32b_arr) RETURN t_network_eth_header IS
    VARIABLE v_hdr : t_network_eth_header;
  BEGIN
    --                             hdr_arr(0)(31 DOWNTO 16)  -- ignore word align field
    v_hdr.dst_mac(47 DOWNTO 32) := hdr_arr(0)(15 DOWNTO  0);
    v_hdr.dst_mac(31 DOWNTO  0) := hdr_arr(1);
    v_hdr.src_mac(47 DOWNTO 16) := hdr_arr(2);
    v_hdr.src_mac(15 DOWNTO  0) := hdr_arr(3)(31 DOWNTO 16);
    v_hdr.eth_type              := hdr_arr(3)(15 DOWNTO  0);
    RETURN v_hdr;
  END;
  
  FUNCTION func_network_total_header_extract_eth(hdr_arr : t_network_total_header_64b_arr) RETURN t_network_eth_header IS
    VARIABLE v_hdr : t_network_eth_header;
  BEGIN
    --                             hdr_arr(0)(63 DOWNTO 16)  -- ignore word align field
    v_hdr.dst_mac(47 DOWNTO 32) := hdr_arr(0)(15 DOWNTO  0);
    v_hdr.dst_mac(31 DOWNTO  0) := hdr_arr(1)(63 DOWNTO 32);
    v_hdr.src_mac(47 DOWNTO 16) := hdr_arr(1)(31 DOWNTO  0);
    v_hdr.src_mac(15 DOWNTO  0) := hdr_arr(2)(63 DOWNTO 48);
    v_hdr.eth_type              := hdr_arr(2)(47 DOWNTO 32);
    RETURN v_hdr;
  END;
  
  FUNCTION func_network_total_header_extract_ip(hdr_arr : t_network_total_header_32b_arr) RETURN t_network_ip_header IS
    VARIABLE v_hdr : t_network_ip_header;
  BEGIN
    v_hdr.version            := hdr_arr(4)(31 DOWNTO 28);
    v_hdr.header_length      := hdr_arr(4)(27 DOWNTO 24);
    v_hdr.services           := hdr_arr(4)(23 DOWNTO 16);
    v_hdr.total_length       := hdr_arr(4)(15 DOWNTO  0);
    v_hdr.identification     := hdr_arr(5)(31 DOWNTO 16);
    v_hdr.flags              := hdr_arr(5)(15 DOWNTO 13);
    v_hdr.fragment_offset    := hdr_arr(5)(12 DOWNTO  0);
    v_hdr.time_to_live       := hdr_arr(6)(31 DOWNTO 24);
    v_hdr.protocol           := hdr_arr(6)(23 DOWNTO 16);
    v_hdr.header_checksum    := hdr_arr(6)(15 DOWNTO  0);
    v_hdr.src_ip_addr        := hdr_arr(7);
    v_hdr.dst_ip_addr        := hdr_arr(8);
    RETURN v_hdr;
  END;
  
  FUNCTION func_network_total_header_extract_ip(hdr_arr : t_network_total_header_64b_arr) RETURN t_network_ip_header IS
    VARIABLE v_hdr : t_network_ip_header;
  BEGIN
    v_hdr.version            := hdr_arr(2)(31 DOWNTO 28);
    v_hdr.header_length      := hdr_arr(2)(27 DOWNTO 24);
    v_hdr.services           := hdr_arr(2)(23 DOWNTO 16);
    v_hdr.total_length       := hdr_arr(2)(15 DOWNTO  0);
    v_hdr.identification     := hdr_arr(3)(63 DOWNTO 48);
    v_hdr.flags              := hdr_arr(3)(47 DOWNTO 45);
    v_hdr.fragment_offset    := hdr_arr(3)(44 DOWNTO 32);
    v_hdr.time_to_live       := hdr_arr(3)(31 DOWNTO 24);
    v_hdr.protocol           := hdr_arr(3)(23 DOWNTO 16);
    v_hdr.header_checksum    := hdr_arr(3)(15 DOWNTO  0);
    v_hdr.src_ip_addr        := hdr_arr(4)(63 DOWNTO 32);
    v_hdr.dst_ip_addr        := hdr_arr(4)(31 DOWNTO  0);
    RETURN v_hdr;
  END;
  
  FUNCTION func_network_total_header_extract_arp(hdr_arr : t_network_total_header_32b_arr) RETURN t_network_arp_packet IS
    VARIABLE v_arp : t_network_arp_packet;
  BEGIN
    v_arp.htype              := hdr_arr(4)(31 DOWNTO 16);
    v_arp.ptype              := hdr_arr(4)(15 DOWNTO  0);
    v_arp.hlen               := hdr_arr(5)(31 DOWNTO 24);
    v_arp.plen               := hdr_arr(5)(23 DOWNTO 16);
    v_arp.oper               := hdr_arr(5)(15 DOWNTO  0);
    v_arp.sha(47 DOWNTO 16)  := hdr_arr(6);
    v_arp.sha(15 DOWNTO  0)  := hdr_arr(7)(31 DOWNTO 16);
    v_arp.spa(31 DOWNTO 16)  := hdr_arr(7)(15 DOWNTO  0);
    v_arp.spa(15 DOWNTO  0)  := hdr_arr(8)(31 DOWNTO 16);
    v_arp.tha(47 DOWNTO 32)  := hdr_arr(8)(15 DOWNTO  0);
    v_arp.tha(31 DOWNTO  0)  := hdr_arr(9);
    v_arp.tpa                := hdr_arr(10);
    RETURN v_arp;
  END;
  
  FUNCTION func_network_total_header_extract_arp(hdr_arr : t_network_total_header_64b_arr) RETURN t_network_arp_packet IS
    VARIABLE v_arp : t_network_arp_packet;
  BEGIN
    v_arp.htype              := hdr_arr(2)(31 DOWNTO 16);
    v_arp.ptype              := hdr_arr(2)(15 DOWNTO  0);
    v_arp.hlen               := hdr_arr(3)(63 DOWNTO 56);
    v_arp.plen               := hdr_arr(3)(55 DOWNTO 48);
    v_arp.oper               := hdr_arr(3)(47 DOWNTO 32);
    v_arp.sha(47 DOWNTO 16)  := hdr_arr(3)(31 DOWNTO  0);
    v_arp.sha(15 DOWNTO  0)  := hdr_arr(4)(63 DOWNTO 48);
    v_arp.spa(31 DOWNTO 16)  := hdr_arr(4)(47 DOWNTO 32);
    v_arp.spa(15 DOWNTO  0)  := hdr_arr(4)(31 DOWNTO 16);
    v_arp.tha(47 DOWNTO 32)  := hdr_arr(4)(15 DOWNTO  0);
    v_arp.tha(31 DOWNTO  0)  := hdr_arr(5)(63 DOWNTO 32);
    v_arp.tpa                := hdr_arr(5)(31 DOWNTO  0);
    RETURN v_arp;
  END;
  
  FUNCTION func_network_total_header_extract_icmp(hdr_arr : t_network_total_header_32b_arr) RETURN t_network_icmp_header IS
    VARIABLE v_hdr : t_network_icmp_header;
  BEGIN
    v_hdr.msg_type  := hdr_arr(9)(31 DOWNTO 24);
    v_hdr.code      := hdr_arr(9)(23 DOWNTO 16);
    v_hdr.checksum  := hdr_arr(9)(15 DOWNTO  0);
    v_hdr.id        := hdr_arr(10)(31 DOWNTO 16);
    v_hdr.sequ      := hdr_arr(10)(15 DOWNTO  0);
    RETURN v_hdr;
  END;
  
  FUNCTION func_network_total_header_extract_icmp(hdr_arr : t_network_total_header_64b_arr) RETURN t_network_icmp_header IS
    VARIABLE v_hdr : t_network_icmp_header;
  BEGIN
    v_hdr.msg_type  := hdr_arr(5)(63 DOWNTO 56);
    v_hdr.code      := hdr_arr(5)(55 DOWNTO 48);
    v_hdr.checksum  := hdr_arr(5)(47 DOWNTO 32);
    v_hdr.id        := hdr_arr(5)(31 DOWNTO 16);
    v_hdr.sequ      := hdr_arr(5)(15 DOWNTO  0);
    RETURN v_hdr;
  END;
  
  FUNCTION func_network_total_header_extract_udp(hdr_arr : t_network_total_header_32b_arr) RETURN t_network_udp_header IS
    VARIABLE v_hdr : t_network_udp_header;
  BEGIN
    v_hdr.src_port            := hdr_arr(9)(31 DOWNTO 16);
    v_hdr.dst_port            := hdr_arr(9)(15 DOWNTO  0);
    v_hdr.total_length        := hdr_arr(10)(31 DOWNTO 16);
    v_hdr.checksum            := hdr_arr(10)(15 DOWNTO  0);
    RETURN v_hdr;
  END;
  
  FUNCTION func_network_total_header_extract_udp(hdr_arr : t_network_total_header_64b_arr) RETURN t_network_udp_header IS
    VARIABLE v_hdr : t_network_udp_header;
  BEGIN
    v_hdr.src_port            := hdr_arr(5)(63 DOWNTO 48);
    v_hdr.dst_port            := hdr_arr(5)(47 DOWNTO 32);
    v_hdr.total_length        := hdr_arr(5)(31 DOWNTO 16);
    v_hdr.checksum            := hdr_arr(5)(15 DOWNTO  0);
    RETURN v_hdr;
  END;
  
  -- Construct the total header array from the individual header records
  FUNCTION func_network_total_header_construct_eth( eth : t_network_eth_header) RETURN t_network_total_header_32b_arr IS
    VARIABLE v_total : t_network_total_header_32b_arr := (OTHERS=>(OTHERS=>'0'));
  BEGIN
    v_total(0)(31 DOWNTO 16) := (OTHERS=>'0');  -- force word align to zero
    v_total(0)(15 DOWNTO  0) := eth.dst_mac(47 DOWNTO 32);
    v_total(1)               := eth.dst_mac(31 DOWNTO  0);
    v_total(2)               := eth.src_mac(47 DOWNTO 16);
    v_total(3)(31 DOWNTO 16) := eth.src_mac(15 DOWNTO  0);
    v_total(3)(15 DOWNTO  0) := eth.eth_type;
    RETURN v_total;
  END;
  
  FUNCTION func_network_total_header_construct_eth( eth : t_network_eth_header) RETURN t_network_total_header_64b_arr IS
    VARIABLE v_total : t_network_total_header_64b_arr := (OTHERS=>(OTHERS=>'0'));
  BEGIN
    v_total(0)(63 DOWNTO 16) := (OTHERS=>'0');  -- force word align to zero
    v_total(0)(15 DOWNTO  0) := eth.dst_mac(47 DOWNTO 32);
    v_total(1)(63 DOWNTO 32) := eth.dst_mac(31 DOWNTO  0);
    v_total(1)(31 DOWNTO  0) := eth.src_mac(47 DOWNTO 16);
    v_total(2)(63 DOWNTO 48) := eth.src_mac(15 DOWNTO  0);
    v_total(2)(47 DOWNTO 32) := eth.eth_type;
    RETURN v_total;
  END;
  
  FUNCTION func_network_total_header_construct_arp(eth : t_network_eth_header; arp : t_network_arp_packet) RETURN t_network_total_header_32b_arr IS
    VARIABLE v_total : t_network_total_header_32b_arr;
  BEGIN
    v_total := func_network_total_header_construct_eth(eth);
    
    v_total(4)(31 DOWNTO 16) := arp.htype;
    v_total(4)(15 DOWNTO  0) := arp.ptype;
    v_total(5)(31 DOWNTO 24) := arp.hlen;
    v_total(5)(23 DOWNTO 16) := arp.plen;
    v_total(5)(15 DOWNTO  0) := arp.oper;
    v_total(6)               := arp.sha(47 DOWNTO 16);
    v_total(7)(31 DOWNTO 16) := arp.sha(15 DOWNTO  0);
    v_total(7)(15 DOWNTO  0) := arp.spa(31 DOWNTO 16);
    v_total(8)(31 DOWNTO 16) := arp.spa(15 DOWNTO  0);
    v_total(8)(15 DOWNTO  0) := arp.tha(47 DOWNTO 32);
    v_total(9)               := arp.tha(31 DOWNTO  0);
    v_total(10)              := arp.tpa;
    RETURN v_total;
  END;
  
  FUNCTION func_network_total_header_construct_arp(eth : t_network_eth_header; arp : t_network_arp_packet) RETURN t_network_total_header_64b_arr IS
    VARIABLE v_total : t_network_total_header_64b_arr;
  BEGIN
    v_total := func_network_total_header_construct_eth(eth);
    
    v_total(2)(31 DOWNTO 16) := arp.htype;
    v_total(2)(15 DOWNTO  0) := arp.ptype;
    v_total(3)(63 DOWNTO 56) := arp.hlen;
    v_total(3)(55 DOWNTO 48) := arp.plen;
    v_total(3)(47 DOWNTO 32) := arp.oper;
    v_total(3)(31 DOWNTO  0) := arp.sha(47 DOWNTO 16);
    v_total(4)(63 DOWNTO 48) := arp.sha(15 DOWNTO  0);
    v_total(4)(47 DOWNTO 16) := arp.spa(31 DOWNTO  0);
    v_total(4)(15 DOWNTO  0) := arp.tha(47 DOWNTO 32);
    v_total(5)(63 DOWNTO 32) := arp.tha(31 DOWNTO  0);
    v_total(5)(31 DOWNTO  0) := arp.tpa;
    RETURN v_total;
  END;
  
  FUNCTION func_network_total_header_construct_ip(eth : t_network_eth_header; ip : t_network_ip_header) RETURN t_network_total_header_32b_arr IS
    VARIABLE v_total : t_network_total_header_32b_arr := (OTHERS=>(OTHERS=>'0'));
  BEGIN
    v_total := func_network_total_header_construct_eth(eth);
    
    v_total(4)(31 DOWNTO 28) := ip.version;
    v_total(4)(27 DOWNTO 24) := ip.header_length;
    v_total(4)(23 DOWNTO 16) := ip.services;  
    v_total(4)(15 DOWNTO  0) := ip.total_length;
    v_total(5)(31 DOWNTO 16) := ip.identification;
    v_total(5)(15 DOWNTO 13) := ip.flags;
    v_total(5)(12 DOWNTO  0) := ip.fragment_offset;
    v_total(6)(31 DOWNTO 24) := ip.time_to_live;
    v_total(6)(23 DOWNTO 16) := ip.protocol;
    v_total(6)(15 DOWNTO  0) := ip.header_checksum;
    v_total(7)               := ip.src_ip_addr;
    v_total(8)               := ip.dst_ip_addr;    
    RETURN v_total;
  END;
  
  FUNCTION func_network_total_header_construct_ip(eth : t_network_eth_header; ip : t_network_ip_header) RETURN t_network_total_header_64b_arr IS
    VARIABLE v_total : t_network_total_header_64b_arr := (OTHERS=>(OTHERS=>'0'));
  BEGIN
    v_total := func_network_total_header_construct_eth(eth);
    
    v_total(2)(31 DOWNTO 28) := ip.version;
    v_total(2)(27 DOWNTO 24) := ip.header_length;
    v_total(2)(23 DOWNTO 16) := ip.services;  
    v_total(2)(15 DOWNTO  0) := ip.total_length;
    v_total(3)(63 DOWNTO 48) := ip.identification;
    v_total(3)(47 DOWNTO 45) := ip.flags;
    v_total(3)(44 DOWNTO 32) := ip.fragment_offset;
    v_total(3)(31 DOWNTO 24) := ip.time_to_live;
    v_total(3)(23 DOWNTO 16) := ip.protocol;
    v_total(3)(15 DOWNTO  0) := ip.header_checksum;
    v_total(4)(63 DOWNTO 32) := ip.src_ip_addr;
    v_total(4)(31 DOWNTO  0) := ip.dst_ip_addr;
    RETURN v_total;
  END;
  
  FUNCTION func_network_total_header_construct_icmp(eth : t_network_eth_header; ip : t_network_ip_header; icmp : t_network_icmp_header) RETURN t_network_total_header_32b_arr IS
    VARIABLE v_total : t_network_total_header_32b_arr;
  BEGIN
    v_total := func_network_total_header_construct_ip(eth, ip);
    
    v_total(9)(31 DOWNTO 24)  := icmp.msg_type;
    v_total(9)(23 DOWNTO 16)  := icmp.code;
    v_total(9)(15 DOWNTO  0)  := icmp.checksum;
    v_total(10)(31 DOWNTO 16) := icmp.id;
    v_total(10)(15 DOWNTO  0) := icmp.sequ;
    RETURN v_total;
  END;
  
  FUNCTION func_network_total_header_construct_icmp(eth : t_network_eth_header; ip : t_network_ip_header; icmp : t_network_icmp_header) RETURN t_network_total_header_64b_arr IS
    VARIABLE v_total : t_network_total_header_64b_arr;
  BEGIN
    v_total := func_network_total_header_construct_ip(eth, ip);
    
    v_total(5)(63 DOWNTO 56) := icmp.msg_type;
    v_total(5)(55 DOWNTO 48) := icmp.code;
    v_total(5)(47 DOWNTO 32) := icmp.checksum;
    v_total(5)(31 DOWNTO 16) := icmp.id;
    v_total(5)(15 DOWNTO  0) := icmp.sequ;
    RETURN v_total;
  END;
  
  FUNCTION func_network_total_header_construct_udp( eth : t_network_eth_header; ip : t_network_ip_header; udp : t_network_udp_header) RETURN t_network_total_header_32b_arr IS
    VARIABLE v_total : t_network_total_header_32b_arr;
  BEGIN
    v_total := func_network_total_header_construct_ip(eth, ip);
    
    v_total(9)(31 DOWNTO 16)  := udp.src_port;
    v_total(9)(15 DOWNTO  0)  := udp.dst_port;
    v_total(10)(31 DOWNTO 16) := udp.total_length;
    v_total(10)(15 DOWNTO  0) := udp.checksum;
    RETURN v_total;
  END;
  
  FUNCTION func_network_total_header_construct_udp( eth : t_network_eth_header; ip : t_network_ip_header; udp : t_network_udp_header) RETURN t_network_total_header_64b_arr IS
    VARIABLE v_total : t_network_total_header_64b_arr;
  BEGIN
    v_total := func_network_total_header_construct_ip(eth, ip);
    
    v_total(5)(63 DOWNTO 48) := udp.src_port;
    v_total(5)(47 DOWNTO 32) := udp.dst_port;
    v_total(5)(31 DOWNTO 16) := udp.total_length;
    v_total(5)(15 DOWNTO  0) := udp.checksum;
    RETURN v_total;
  END;
  
  -- Construct the response headers
  FUNCTION func_network_total_header_response_eth(eth_arr  : t_network_total_header_32b_arr;
                                                  mac_addr : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0)) RETURN t_network_total_header_32b_arr IS
    VARIABLE v_response : t_network_total_header_32b_arr;
  BEGIN
    -- Default
    v_response := eth_arr;
    -- ETH
    -- . use input src mac for dst mac
    v_response(0)(15 DOWNTO  0) := eth_arr(2)(31 DOWNTO 16);
    v_response(1)               := eth_arr(2)(15 DOWNTO  0) & eth_arr(3)(31 DOWNTO 16);
    -- . force eth src mac to this node mac address (because the input dst_mac can be via eth broadcast mac)
    v_response(2)               := mac_addr(47 DOWNTO 16);
    v_response(3)(31 DOWNTO 16) := mac_addr(15 DOWNTO  0);
    RETURN v_response;
  END;
  
  FUNCTION func_network_total_header_response_eth(eth_arr  : t_network_total_header_64b_arr;
                                                  mac_addr : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0)) RETURN t_network_total_header_64b_arr IS
    VARIABLE v_response : t_network_total_header_64b_arr;
  BEGIN
    -- Default
    v_response := eth_arr;
    -- ETH
    -- . use input src mac for dst mac
    v_response(0)(15 DOWNTO  0) := eth_arr(1)(31 DOWNTO 16);
    v_response(1)(63 DOWNTO 32) := eth_arr(1)(15 DOWNTO  0) & eth_arr(2)(63 DOWNTO 48);
    -- . force eth src mac to this node mac address (because the input dst_mac can be via eth broadcast mac)
    v_response(1)(31 DOWNTO  0) := mac_addr(47 DOWNTO 16);
    v_response(2)(63 DOWNTO 48) := mac_addr(15 DOWNTO  0);
    RETURN v_response;
  END;
  
  FUNCTION func_network_total_header_response_arp(arp_arr  : t_network_total_header_32b_arr;
                                                  mac_addr : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0);
                                                  ip_addr  : STD_LOGIC_VECTOR(c_network_ip_addr_w-1 DOWNTO 0)) RETURN t_network_total_header_32b_arr IS
    VARIABLE v_response : t_network_total_header_32b_arr;
  BEGIN
    -- ETH
    v_response := func_network_total_header_response_eth(arp_arr, mac_addr);
    -- ARP
    -- . force operation arp reply
    v_response(5)(15 DOWNTO  0) := TO_UVEC(c_network_arp_oper_reply, 16);
    -- . force sha to this node mac address
    v_response(6)               := mac_addr(47 DOWNTO 16);
    v_response(7)(31 DOWNTO 16) := mac_addr(15 DOWNTO  0);
    -- . force spa to this node ip address
    v_response(7)(15 DOWNTO  0) := ip_addr(31 DOWNTO 16);
    v_response(8)(31 DOWNTO 16) := ip_addr(15 DOWNTO  0);
    -- . use input sha for tha
    v_response(8)(15 DOWNTO  0) := arp_arr(6)(31 DOWNTO 16);
    v_response(9)               := arp_arr(6)(15 DOWNTO  0) & arp_arr(7)(31 DOWNTO 16);
    -- . use input spa for tpa
    v_response(10)              := arp_arr(7)(15 DOWNTO  0) & arp_arr(8)(31 DOWNTO 16);
    RETURN v_response;
  END;
  
  FUNCTION func_network_total_header_response_arp(arp_arr  : t_network_total_header_64b_arr;
                                                  mac_addr : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0);
                                                  ip_addr  : STD_LOGIC_VECTOR(c_network_ip_addr_w-1 DOWNTO 0)) RETURN t_network_total_header_64b_arr IS
    VARIABLE v_response : t_network_total_header_64b_arr;
  BEGIN
    -- ETH
    v_response := func_network_total_header_response_eth(arp_arr, mac_addr);
    -- ARP
    -- . force operation arp reply
    v_response(3)(47 DOWNTO 32) := TO_UVEC(c_network_arp_oper_reply, 16);
    -- . force sha to this node mac address
    v_response(3)(31 DOWNTO  0) := mac_addr(47 DOWNTO 16);
    v_response(4)(63 DOWNTO 48) := mac_addr(15 DOWNTO  0);
    -- . force spa to this node ip address
    v_response(4)(47 DOWNTO 16) := ip_addr(31 DOWNTO  0);
    -- . use input sha for tha
    v_response(4)(15 DOWNTO  0) := arp_arr(3)(31 DOWNTO 16);
    v_response(5)(63 DOWNTO 32) := arp_arr(3)(15 DOWNTO  0) & arp_arr(4)(63 DOWNTO 48);
    -- . use input spa for tpa
    v_response(5)(31 DOWNTO  0) := arp_arr(4)(47 DOWNTO 16);
    RETURN v_response;
  END;
  
  FUNCTION func_network_total_header_response_ip(ip_arr   : t_network_total_header_32b_arr;
                                                 mac_addr : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0)) RETURN t_network_total_header_32b_arr IS
    VARIABLE v_response : t_network_total_header_32b_arr;
  BEGIN
    -- ETH
    v_response := func_network_total_header_response_eth(ip_arr, mac_addr);
    -- IP
    -- . force ip header checksum to 0
    v_response(6)(15 DOWNTO  0) := TO_UVEC(0, 16);
    -- . swap ip dst_addr and ip src_addr
    v_response(7)               := ip_arr(8);
    v_response(8)               := ip_arr(7);
    RETURN v_response;
  END;
  
  FUNCTION func_network_total_header_response_ip(ip_arr   : t_network_total_header_64b_arr;
                                                 mac_addr : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0)) RETURN t_network_total_header_64b_arr IS
    VARIABLE v_response : t_network_total_header_64b_arr;
  BEGIN
    -- ETH
    v_response := func_network_total_header_response_eth(ip_arr, mac_addr);
    -- IP
    -- . force ip header checksum to 0
    v_response(3)(15 DOWNTO  0) := TO_UVEC(0, 16);
    -- . swap ip dst_addr and ip src_addr
    v_response(4)(63 DOWNTO 32) := ip_arr(4)(31 DOWNTO  0);
    v_response(4)(31 DOWNTO  0) := ip_arr(4)(63 DOWNTO 32);
    RETURN v_response;
  END;
  
  FUNCTION func_network_total_header_response_icmp(icmp_arr : t_network_total_header_32b_arr;
                                                   mac_addr : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0)) RETURN t_network_total_header_32b_arr IS
    VARIABLE v_response : t_network_total_header_32b_arr;
  BEGIN
    -- ETH, IP
    v_response := func_network_total_header_response_ip(icmp_arr, mac_addr);
    -- ICMP : force type to icmp reply
    v_response(9)(31 DOWNTO 24) := TO_UVEC(c_network_icmp_msg_type_reply, 8);
    -- ICMP : force icmp checksum to 0
    v_response(9)(15 DOWNTO  0) := TO_UVEC(0, 16);
    RETURN v_response;
  END;
  
  FUNCTION func_network_total_header_response_icmp(icmp_arr : t_network_total_header_64b_arr;
                                                   mac_addr : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0)) RETURN t_network_total_header_64b_arr IS
    VARIABLE v_response : t_network_total_header_64b_arr;
  BEGIN
    -- ETH, IP
    v_response := func_network_total_header_response_ip(icmp_arr, mac_addr);
    -- ICMP : force type to icmp reply
    v_response(5)(63 DOWNTO 56) := TO_UVEC(c_network_icmp_msg_type_reply, 8);
    -- ICMP : force icmp checksum to 0
    v_response(5)(15 DOWNTO  0) := TO_UVEC(0, 16);
    RETURN v_response;
  END;
  
  FUNCTION func_network_total_header_response_udp(udp_arr  : t_network_total_header_32b_arr;
                                                  mac_addr : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0)) RETURN t_network_total_header_32b_arr IS
    VARIABLE v_response : t_network_total_header_32b_arr;
  BEGIN
    -- ETH, IP
    v_response := func_network_total_header_response_ip(udp_arr, mac_addr);
    -- UDP : swap udp dst port and udp src port
    v_response(9)               := udp_arr(9)(15 DOWNTO  0) & udp_arr(9)(31 DOWNTO 16);
    -- UDP : force udp checksum to 0
    v_response(10)(15 DOWNTO 0) := TO_UVEC(0, 16);
    RETURN v_response;
  END;
  
  FUNCTION func_network_total_header_response_udp(udp_arr  : t_network_total_header_64b_arr;
                                                  mac_addr : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0)) RETURN t_network_total_header_64b_arr IS
    VARIABLE v_response : t_network_total_header_64b_arr;
  BEGIN
    -- ETH, IP
    v_response := func_network_total_header_response_ip(udp_arr, mac_addr);
    -- UDP : swap udp dst port and udp src port
    v_response(5)(63 DOWNTO 32) := udp_arr(5)(47 DOWNTO 32) & udp_arr(5)(63 DOWNTO 48);
    -- UDP : force udp checksum to 0
    v_response(5)(15 DOWNTO  0) := TO_UVEC(0, 16);
    RETURN v_response;
  END;
  
END common_network_total_header_pkg;
