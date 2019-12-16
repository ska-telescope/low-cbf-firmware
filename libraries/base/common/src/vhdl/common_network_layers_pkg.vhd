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

-- Purpose: Define the fields of network headers

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;

PACKAGE common_network_layers_pkg IS

  -- All *_len constants are in nof octets = nof bytes = c_8 bits
  
  ------------------------------------------------------------------------------
  -- Ethernet Packet (with payload 32b word alignment!)
  --
  --  0                               15 16                               31  wi
  -- |----------------------------------------------------------------------|
  -- |     32b Word Align               |    Destination MAC Address        |  0
  -- |-----------------------------------                                   |
  -- |                                                                      |  1
  -- |----------------------------------------------------------------------|
  -- |                Source MAC Address                                    |  2
  -- |                                  ------------------------------------|
  -- |                                  |    EtherType                      |  3
  -- |----------------------------------|-----------------------------------|
  -- |                                                                      |
  -- |                Ethernet Payload                                      |
  -- |                                                                      |
  -- |------------------------------------------------------------ // ------|
  -- |                Frame Check Sequence                                  |
  -- |------------------------------------------------------------ // ------|
  --
  
  -- field widths in bits '_w' or in bytes '_len', '_min', '_max', '_sz'
  CONSTANT c_network_eth_preamble_len      : NATURAL := 8;
  CONSTANT c_network_eth_mac_addr_len      : NATURAL := 6;
  CONSTANT c_network_eth_mac_addr_w        : NATURAL := c_network_eth_mac_addr_len*c_8;
  CONSTANT c_network_eth_type_len          : NATURAL := 2;
  CONSTANT c_network_eth_type_w            : NATURAL := c_network_eth_type_len*c_8;
  CONSTANT c_network_eth_header_len        : NATURAL := 2*c_network_eth_mac_addr_len+c_network_eth_type_len;  -- = 14
  CONSTANT c_network_eth_payload_min       : NATURAL := 46;
  CONSTANT c_network_eth_payload_max       : NATURAL := 1500;
  CONSTANT c_network_eth_payload_jumbo_max : NATURAL := 9000;
  CONSTANT c_network_eth_crc_len           : NATURAL := 4;
  CONSTANT c_network_eth_crc_w             : NATURAL := c_network_eth_crc_len*c_8;
  CONSTANT c_network_eth_gap_len           : NATURAL := 12;   -- IPG = interpacket gap, minimum idle period between transmission of Ethernet packets
  CONSTANT c_network_eth_frame_max         : NATURAL := c_network_eth_header_len + c_network_eth_payload_max       + c_network_eth_crc_len;  -- = 1518
  CONSTANT c_network_eth_frame_jumbo_max   : NATURAL := c_network_eth_header_len + c_network_eth_payload_jumbo_max + c_network_eth_crc_len;  -- = 9018
  
  -- default field values
  CONSTANT c_network_eth_preamble          : NATURAL := 5;      -- nibble "0101"
  CONSTANT c_network_eth_frame_delimiter   : NATURAL := 13;     -- nibble "1101"
  
  -- useful field values
  CONSTANT c_network_eth_mac_slv           : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0) := (OTHERS=>'X');  -- Ethernet MAC slv RANGE
  CONSTANT c_network_eth_bc_mac            : STD_LOGIC_VECTOR(c_network_eth_mac_slv'RANGE) := (OTHERS=>'1');          -- Broadcast destination MAC

  CONSTANT c_network_eth_type_slv          : STD_LOGIC_VECTOR(c_network_eth_type_w-1 DOWNTO 0) := (OTHERS=>'X');      -- Ethernet TYPE slv RANGE
  CONSTANT c_network_eth_type_arp          : NATURAL := 16#0806#;  -- ARP = Address Resolution Prorotol
  CONSTANT c_network_eth_type_ip           : NATURAL := 16#0800#;  -- IPv4 = Internet Protocol, Version 4

  TYPE t_network_eth_header IS RECORD
    dst_mac    : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0);
    src_mac    : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0);
    eth_type   : STD_LOGIC_VECTOR(c_network_eth_type_w-1 DOWNTO 0);
  END RECORD;

  CONSTANT c_network_eth_header_ones : t_network_eth_header := ("000000000000000000000000000000000000000000000001",
                                                                "000000000000000000000000000000000000000000000001",
                                                                "0000000000000001");

  ------------------------------------------------------------------------------
  -- IPv4 Packet
  --
  --  0       3 4     7 8            15 16   18 19                        31  wi
  -- |----------------------------------------------------------------------|
  -- | Version |  HLEN |    Services    |      Total Length                 |  4
  -- |----------------------------------------------------------------------|
  -- |       Identification             | Flags |    Fragment Offset        |  5
  -- |----------------------------------------------------------------------|
  -- |     TTL         |    Protocol    |      Header Checksum              |  6
  -- |----------------------------------------------------------------------|
  -- |              Source IP Address                                       |  7
  -- |----------------------------------------------------------------------|
  -- |              Destination IP Address                                  |  8
  -- |----------------------------------------------------------------------|
  -- |                                                                      |
  -- |              IP Payload                                              |
  -- |                                                                      |
  -- |------------------------------------------------------------ // ------|
  --

  -- field widths in bits '_w' or in bytes '_len'
  CONSTANT c_network_ip_version_w           : NATURAL := 4;   -- 4-bit field
  CONSTANT c_network_ip_header_length_w     : NATURAL := 4;   -- 4-bit field
  CONSTANT c_network_ip_version_header_len  : NATURAL := 1;
  CONSTANT c_network_ip_version_header_w    : NATURAL := c_network_ip_version_header_len*c_8;
  CONSTANT c_network_ip_services_len        : NATURAL := 1;
  CONSTANT c_network_ip_services_w          : NATURAL := c_network_ip_services_len*c_8;
  CONSTANT c_network_ip_total_length_len    : NATURAL := 2;
  CONSTANT c_network_ip_total_length_w      : NATURAL := c_network_ip_total_length_len*c_8;
  CONSTANT c_network_ip_identification_len  : NATURAL := 2;
  CONSTANT c_network_ip_identification_w    : NATURAL := c_network_ip_identification_len*c_8;
  CONSTANT c_network_ip_flags_w             : NATURAL := 3;   -- 3-bit field
  CONSTANT c_network_ip_fragment_offset_w   : NATURAL := 13;  -- 13-bit field
  CONSTANT c_network_ip_flags_fragment_len  : NATURAL := 2;
  CONSTANT c_network_ip_flags_fragment_w    : NATURAL := c_network_ip_flags_fragment_len*c_8;
  CONSTANT c_network_ip_time_to_live_len    : NATURAL := 1;
  CONSTANT c_network_ip_time_to_live_w      : NATURAL := c_network_ip_time_to_live_len*c_8;
  CONSTANT c_network_ip_protocol_len        : NATURAL := 1;
  CONSTANT c_network_ip_protocol_w          : NATURAL := c_network_ip_protocol_len*c_8;
  CONSTANT c_network_ip_header_checksum_len : NATURAL := 2;
  CONSTANT c_network_ip_header_checksum_w   : NATURAL := c_network_ip_header_checksum_len*c_8;
  CONSTANT c_network_ip_addr_len            : NATURAL := 4;
  CONSTANT c_network_ip_addr_w              : NATURAL := c_network_ip_addr_len*c_8;

                                                      -- [0:7]                             [8:15]                      [16:31]
  CONSTANT c_network_ip_header_len          : NATURAL := c_network_ip_version_header_len + c_network_ip_services_len + c_network_ip_total_length_len +
                                                         c_network_ip_identification_len +                             c_network_ip_flags_fragment_len +
                                                         c_network_ip_time_to_live_len   + c_network_ip_protocol_len + c_network_ip_header_checksum_len +
                                                         c_network_ip_addr_len +
                                                         c_network_ip_addr_len;
                                                    -- = c_network_ip_header_length * c_word_sz = 20
  -- default field values
  CONSTANT c_network_ip_version             : NATURAL := 4;    -- 4 = IPv4,
  CONSTANT c_network_ip_header_length       : NATURAL := 5;    -- 5 = nof words in the header, no options field support
  CONSTANT c_network_ip_services            : NATURAL := 0;    -- 0 = default, use default on transmit, ignore on receive, copy on reply
  CONSTANT c_network_ip_total_length        : NATURAL := 20;   -- >= 20, nof bytes in entire datagram including header and data
  CONSTANT c_network_ip_identification      : NATURAL := 0;    -- identification number, copy on reply
  CONSTANT c_network_ip_flags               : NATURAL := 2;    -- 2 = don't fragment and this is the last fragment
  CONSTANT c_network_ip_fragment_offset     : NATURAL := 0;    -- 0 = first fragment
  CONSTANT c_network_ip_time_to_live        : NATURAL := 127;  -- number of hops until the packet will be discarded
  CONSTANT c_network_ip_header_checksum     : NATURAL := 0;    -- init value
  
  -- useful field values
  CONSTANT c_network_ip_protocol_slv        : STD_LOGIC_VECTOR(c_network_ip_protocol_w-1 DOWNTO 0) := (OTHERS=>'X');  -- IP protocol slv RANGE
  CONSTANT c_network_ip_protocol_udp        : NATURAL := 17;  -- UDP = User Datagram Protocol (for board control and streaming data)
  CONSTANT c_network_ip_protocol_icmp       : NATURAL := 1;   -- ICMP = Internet Control Message Protocol (for ping)

  CONSTANT c_network_ip_addr_slv            : STD_LOGIC_VECTOR(c_network_ip_addr_w-1 DOWNTO 0) := (OTHERS=>'X');  -- IP address slv RANGE
  
  TYPE t_network_ip_header IS RECORD
    version             : STD_LOGIC_VECTOR(c_network_ip_version_w-1 DOWNTO 0);          -- 4 bit
    header_length       : STD_LOGIC_VECTOR(c_network_ip_header_length_w-1 DOWNTO 0);    -- 4 bit
    services            : STD_LOGIC_VECTOR(c_network_ip_services_w-1 DOWNTO 0);         -- 1 octet
    total_length        : STD_LOGIC_VECTOR(c_network_ip_total_length_w-1 DOWNTO 0);     -- 2 octet
    identification      : STD_LOGIC_VECTOR(c_network_ip_identification_w-1 DOWNTO 0);   -- 2 octet
    flags               : STD_LOGIC_VECTOR(c_network_ip_flags_w-1 DOWNTO 0);            -- 3 bit
    fragment_offset     : STD_LOGIC_VECTOR(c_network_ip_fragment_offset_w-1 DOWNTO 0);  -- 13 bit
    time_to_live        : STD_LOGIC_VECTOR(c_network_ip_time_to_live_w-1 DOWNTO 0);     -- 1 octet
    protocol            : STD_LOGIC_VECTOR(c_network_ip_protocol_w-1 DOWNTO 0);         -- 1 octet
    header_checksum     : STD_LOGIC_VECTOR(c_network_ip_header_checksum_w-1 DOWNTO 0);  -- 2 octet
    src_ip_addr         : STD_LOGIC_VECTOR(c_network_ip_addr_w-1 DOWNTO 0);             -- 4 octet
    dst_ip_addr         : STD_LOGIC_VECTOR(c_network_ip_addr_w-1 DOWNTO 0);             -- 4 octet
  END RECORD;
  
  CONSTANT c_network_ip_header_ones : t_network_ip_header := ("0001", "0001", "00000001", "0000000000000001",
                                                              "0000000000000001", "001", "0000000000001",
                                                              "00000001", "00000001", "0000000000000001",
                                                              "00000000000000000000000000000001",
                                                              "00000000000000000000000000000001");

  ------------------------------------------------------------------------------
  -- ARP Packet
  --
  --  0               7 8             15 16                               31  wi
  -- |----------------------------------------------------------------------|
  -- |       Hardware Type              |      Protocol Type                |  4
  -- |----------------------------------------------------------------------|
  -- |  HW Addr Len    |  Prot Addr Len |      Operation                    |  5
  -- |----------------------------------------------------------------------|
  -- |         Sender Hardware Address                                      |  6
  -- |                                  ------------------------------------|
  -- |                                  |                                   |  7
  -- |---------------------------------/ /----------------------------------|
  -- |         Sender Protocol Address  |                                   |  8
  -- |-----------------------------------                                   |
  -- |         Target Hardware Address                                      |  9
  -- |----------------------------------------------------------------------|
  -- |         Target Protocol Address                                      | 10
  -- |----------------------------------------------------------------------|
  --
  -- Note that ARP header = ARP packet, because ARP has no payload
  --
  
  -- field widths in bits '_w' or in bytes '_len'
  CONSTANT c_network_arp_htype_len          : NATURAL := 2;
  CONSTANT c_network_arp_htype_w            : NATURAL := c_network_arp_htype_len*c_8;
  CONSTANT c_network_arp_ptype_len          : NATURAL := 2;
  CONSTANT c_network_arp_ptype_w            : NATURAL := c_network_arp_ptype_len*c_8;
  CONSTANT c_network_arp_hlen_len           : NATURAL := 1;
  CONSTANT c_network_arp_hlen_w             : NATURAL := c_network_arp_hlen_len*c_8;
  CONSTANT c_network_arp_plen_len           : NATURAL := 1;
  CONSTANT c_network_arp_plen_w             : NATURAL := c_network_arp_plen_len*c_8;
  CONSTANT c_network_arp_oper_len           : NATURAL := 2;
  CONSTANT c_network_arp_oper_w             : NATURAL := c_network_arp_oper_len*c_8;
  
                                                      -- [0:15]                       [16:31]
  CONSTANT c_network_arp_data_len           : NATURAL := c_network_arp_htype_len    + c_network_arp_ptype_len +
                                                         c_network_arp_hlen_len     + c_network_arp_plen_len  + c_network_arp_oper_len +
                                                         c_network_eth_mac_addr_len + c_network_ip_addr_len   +
                                                         c_network_eth_mac_addr_len + c_network_ip_addr_len;
                                                      -- [0:47]                       [0:31]                  = 8 + 2*(6+4) = 28

  -- default field values
  CONSTANT c_network_arp_htype              : NATURAL := 1;                           -- Hardware type, 1=ethernet
  CONSTANT c_network_arp_ptype              : NATURAL := c_network_eth_type_ip;       -- Protocol type, do ARP for IPv4
  CONSTANT c_network_arp_hlen               : NATURAL := c_network_eth_mac_addr_len;  -- Hardware length = 6
  CONSTANT c_network_arp_plen               : NATURAL := c_network_ip_addr_len;       -- Protocol length = 4
  CONSTANT c_network_arp_oper_request       : NATURAL := 1;                           -- Operator, 1=request
  CONSTANT c_network_arp_oper_reply         : NATURAL := 2;                           -- Operator, 2=reply
  
  -- useful field values
  CONSTANT c_network_arp_dst_mac            : STD_LOGIC_VECTOR(c_network_eth_mac_slv'RANGE) := c_network_eth_bc_mac;   -- Broadcast destination MAC
  CONSTANT c_network_arp_tha                : STD_LOGIC_VECTOR(c_network_eth_mac_slv'RANGE) := c_network_eth_bc_mac;   -- Broadcast target hardware address
  
  TYPE t_network_arp_packet IS RECORD
    htype   : STD_LOGIC_VECTOR(c_network_arp_htype_w-1 DOWNTO 0);     -- 2 octet
    ptype   : STD_LOGIC_VECTOR(c_network_arp_ptype_w-1 DOWNTO 0);     -- 2 octet
    hlen    : STD_LOGIC_VECTOR(c_network_arp_hlen_w-1 DOWNTO 0);      -- 1 octet
    plen    : STD_LOGIC_VECTOR(c_network_arp_plen_w-1 DOWNTO 0);      -- 1 octet
    oper    : STD_LOGIC_VECTOR(c_network_arp_oper_w-1 DOWNTO 0);      -- 2 octet
    sha     : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0);  -- 6 octet, Sender Hardware Address
    spa     : STD_LOGIC_VECTOR(c_network_ip_addr_w-1 DOWNTO 0);       -- 4 octet, Sender Protocol Address
    tha     : STD_LOGIC_VECTOR(c_network_eth_mac_addr_w-1 DOWNTO 0);  -- 6 octet, Target Hardware Address
    tpa     : STD_LOGIC_VECTOR(c_network_ip_addr_w-1 DOWNTO 0);       -- 4 octet, Target Protocol Address
  END RECORD;
  
  CONSTANT c_network_arp_packet_ones : t_network_arp_packet := ("0000000000000001", "0000000000000001",
                                                                "00000001", "00000001", "0000000000000001",
                                                                "000000000000000000000000000000000000000000000001",
                                                                "00000000000000000000000000000001",
                                                                "000000000000000000000000000000000000000000000001",
                                                                "00000000000000000000000000000001");
                                                              
  ------------------------------------------------------------------------------
  -- ICMP (for ping)
  --
  --  0               7 8             15 16                               31  wi
  -- |----------------------------------------------------------------------|
  -- |    Type         |    Code        |      Checksum                     |  9
  -- |----------------------------------------------------------------------|
  -- |    ID                            |      Sequence                     | 10
  -- |----------------------------------------------------------------------|
  -- |                                                                      |
  -- |              ICMP Payload (padding data)                             |
  -- |                                                                      |
  -- |------------------------------------------------------------ // ------|
  --
  
  -- field widths in bits '_w' or in bytes '_len'
  CONSTANT c_network_icmp_msg_type_len      : NATURAL := 1;
  CONSTANT c_network_icmp_msg_type_w        : NATURAL := c_network_icmp_msg_type_len*c_8;
  CONSTANT c_network_icmp_code_len          : NATURAL := 1;
  CONSTANT c_network_icmp_code_w            : NATURAL := c_network_icmp_code_len*c_8;
  CONSTANT c_network_icmp_checksum_len      : NATURAL := 2;
  CONSTANT c_network_icmp_checksum_w        : NATURAL := c_network_icmp_checksum_len*c_8;
  CONSTANT c_network_icmp_id_len            : NATURAL := 2;
  CONSTANT c_network_icmp_id_w              : NATURAL := c_network_icmp_id_len*c_8;
  CONSTANT c_network_icmp_sequence_len      : NATURAL := 2;
  CONSTANT c_network_icmp_sequence_w        : NATURAL := c_network_icmp_sequence_len*c_8;
  CONSTANT c_network_icmp_header_len        : NATURAL := c_network_icmp_msg_type_len + c_network_icmp_code_len + c_network_icmp_checksum_len +
                                                         c_network_icmp_id_len                                 + c_network_icmp_sequence_len;

  -- default field values
  CONSTANT c_network_icmp_msg_type_request   : NATURAL := 8;  -- 8 = echo request
  CONSTANT c_network_icmp_msg_type_reply     : NATURAL := 0;  -- 8 = echo reply (ping)
  CONSTANT c_network_icmp_checksum           : NATURAL := 0;  -- init value
  
  -- useful field values
  CONSTANT c_network_icmp_code               : NATURAL := 0;  -- default
  CONSTANT c_network_icmp_id                 : NATURAL := 3;  -- arbitrary value
  CONSTANT c_network_icmp_sequence           : NATURAL := 4;  -- arbitrary value
    
  TYPE t_network_icmp_header IS RECORD
    msg_type   : STD_LOGIC_VECTOR(c_network_icmp_msg_type_w-1 DOWNTO 0);  -- 1 octet
    code       : STD_LOGIC_VECTOR(c_network_icmp_code_w-1 DOWNTO 0);      -- 1 octet
    checksum   : STD_LOGIC_VECTOR(c_network_icmp_checksum_w-1 DOWNTO 0);  -- 2 octet
    id         : STD_LOGIC_VECTOR(c_network_icmp_id_w-1 DOWNTO 0);        -- 2 octet
    sequ       : STD_LOGIC_VECTOR(c_network_icmp_sequence_w-1 DOWNTO 0);  -- 2 octet
  END RECORD;
  
  CONSTANT c_network_icmp_header_ones : t_network_icmp_header := ("00000001", "00000001", "0000000000000001",
                                                                  "0000000000000001", "0000000000000001");
  
  ------------------------------------------------------------------------------
  -- UDP Packet
  --
  --  0                               15 16                               31  wi
  -- |----------------------------------------------------------------------|
  -- |      Source Port                 |      Destination Port             |  9
  -- |----------------------------------------------------------------------|
  -- |      Total Length                |      Checksum                     | 10
  -- |----------------------------------------------------------------------|
  -- |                                                                      |
  -- |                      UDP Payload                                     |
  -- |                                                                      |
  -- |----------------------------------------------------------- // -------|
  --
  
  -- field widths in bits '_w' or in bytes '_len'
  CONSTANT c_network_udp_port_len           : NATURAL := 2;
  CONSTANT c_network_udp_port_w             : NATURAL := c_network_udp_port_len*c_8;
  CONSTANT c_network_udp_total_length_len   : NATURAL := 2;
  CONSTANT c_network_udp_total_length_w     : NATURAL := c_network_udp_total_length_len*c_8;
  CONSTANT c_network_udp_checksum_len       : NATURAL := 2;
  CONSTANT c_network_udp_checksum_w         : NATURAL := c_network_udp_checksum_len*c_8;

                                                      -- [0:15]                           [16:31]
  CONSTANT c_network_udp_header_len         : NATURAL := c_network_udp_port_len         + c_network_udp_port_len +
                                                         c_network_udp_total_length_len + c_network_udp_checksum_len;  -- 8

  -- default field values
  CONSTANT c_network_udp_total_length       : NATURAL := 8;  -- >= 8, nof bytes in entire datagram including header and data
  CONSTANT c_network_udp_checksum           : NATURAL := 0;  -- init value
  
  -- useful field values  -- Note that ARP header = ARP packet, because ARP has no payload

  CONSTANT c_network_udp_port_dhcp_in       : NATURAL := 68;  -- DHCP to client = Dynamic Host Configuration Protocol (for IP address assignment)
  CONSTANT c_network_udp_port_dhcp_out      : NATURAL := 67;  -- DHCP to server
  CONSTANT c_network_udp_port_slv           : STD_LOGIC_VECTOR(c_network_udp_port_w-1 DOWNTO 0) := (OTHERS=>'X');  -- UDP port slv RANGE

  TYPE t_network_udp_header IS RECORD
    src_port     : STD_LOGIC_VECTOR(c_network_udp_port_w-1 DOWNTO 0);          -- 2 octet
    dst_port     : STD_LOGIC_VECTOR(c_network_udp_port_w-1 DOWNTO 0);          -- 2 octet
    total_length : STD_LOGIC_VECTOR(c_network_udp_total_length_w-1 DOWNTO 0);  -- 2 octet
    checksum     : STD_LOGIC_VECTOR(c_network_udp_checksum_w-1 DOWNTO 0);      -- 2 octet
  END RECORD;

  CONSTANT c_network_udp_header_ones : t_network_udp_header := ("0000000000000001", "0000000000000001",
                                                                "0000000000000001", "0000000000000001");
                                                                  
END common_network_layers_pkg;


PACKAGE BODY common_network_layers_pkg IS
END common_network_layers_pkg;
