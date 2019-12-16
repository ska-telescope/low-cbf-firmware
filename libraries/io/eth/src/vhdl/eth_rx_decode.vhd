-------------------------------------------------------------------------------
-- File Name: eth_rx_decode.vhd
-- Contributing Authors: Leon Hiemstra
-- Created: September, 2017
--
-- Title: Ethernet RX Header Decoder
--
-- Description: Decodes headers of incoming ethernet packets
--
-------------------------------------------------------------------------------

LIBRARY IEEE, technology_lib, common_lib, axi4_lib;
USE IEEE.std_logic_1164.ALL;
use IEEE.Numeric_STD.all;
USE common_lib.common_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE work.eth_pkg.ALL;


ENTITY eth_rx_decode IS
  PORT (
    clk   : IN STD_LOGIC;
    rst   : IN STD_LOGIC;

    eth_pkt_sosi      :  IN  t_axi4_sosi;
    eth_pkt_pipe_sosi : OUT  t_axi4_sosi;

    my_mac        : IN STD_LOGIC_VECTOR(47 DOWNTO 0);

    mac_ok        : OUT STD_LOGIC;
    has_vlan_tag  : OUT STD_LOGIC;

    is_icmp       : OUT STD_LOGIC;
    is_arp        : OUT STD_LOGIC;
    is_udp_dhcp   : OUT STD_LOGIC;
    is_udp_ptp    : OUT STD_LOGIC;
    is_udp_gemini : OUT STD_LOGIC
  );
END eth_rx_decode;


ARCHITECTURE str OF eth_rx_decode IS

TYPE t_reg IS RECORD
    hdr        : t_eth_hdr_arr;
    hdr_idx    : NATURAL RANGE 0 TO 6;
    decoded       : STD_LOGIC;

    mac_ok        : STD_LOGIC;
    has_vlan_tag  : STD_LOGIC;

    is_icmp       : STD_LOGIC;
    is_arp        : STD_LOGIC;
    is_udp_dhcp   : STD_LOGIC;
    is_udp_ptp    : STD_LOGIC;
    is_udp_gemini : STD_LOGIC;
END RECORD;

SIGNAL pipe_sosi : t_axi4_sosi;
SIGNAL r, nxt_r  : t_reg;

BEGIN

  u_eth_rx_pipe : ENTITY common_lib.common_pipeline
  GENERIC MAP (
    g_pipeline  => 7,
    g_in_dat_w  => 74,
    g_out_dat_w => 74
  )
  PORT MAP (
    clk     => clk,
    in_dat(63 DOWNTO 0)   => eth_pkt_sosi.tdata(63 DOWNTO 0),
    in_dat(71 DOWNTO 64)  => eth_pkt_sosi.tkeep(7 DOWNTO 0),
    in_dat(72)            => eth_pkt_sosi.tlast,
    in_dat(73)            => eth_pkt_sosi.tvalid,

    out_dat(63 DOWNTO 0)  => pipe_sosi.tdata(63 DOWNTO 0),
    out_dat(71 DOWNTO 64) => pipe_sosi.tkeep(7 DOWNTO 0),
    out_dat(72)           => pipe_sosi.tlast,
    out_dat(73)           => pipe_sosi.tvalid
  );

-- example incoming packets:

--sudo nping -v4 -c 1 --udp -p 30000 10.32.1.2 -S 10.32.1.1 --source-mac 00:60:DD:46:DE:E3 --dest-mac 1A:2B:3C:4D:5E:6F  --data-string "gemini0123456789abcdef"

--Starting Nping 0.7.01 ( https://nmap.org/nping ) at 2017-09-29 19:53 AEST
--SENT (0.0023s) UDP [10.32.1.1:53 > 10.32.1.2:30000 len=30 csum=0x019B] IP [ver=4 ihl=5 tos=0x00 iplen=50 id=13751 foff=0 ttl=64 proto=17 csum=0x2ec2]
--0000   1a 2b 3c 4d 5e 6f 00 60  dd 46 de e3 08 00 45 00  .+<M^o.`.F....E.
--0010   00 32 35 b7 00 00 40 11  2e c2 0a 20 01 01 0a 20  .25...@.........
--0020   01 02 00 35 75 30 00 1e  01 9b 67 65 6d 69 6e 69  ...5u0....gemini
--0030   30 31 32 33 34 35 36 37  38 39 61 62 63 64 65 66  0123456789abcdef


-- this is ICMP/PING:
--SENT (0.0025s) ICMP [10.32.1.2 > 10.32.1.1 Echo request (type=8/code=0) id=36899 seq=1] IP [ver=4 ihl=5 tos=0x00 iplen=50 id=24876 foff=0 ttl=64 proto=1 csum=0x035d]
--0000   00 60 dd 46 de e3 1a 2b  3c 4d 5e 6f 08 00 45 00  .`.F...+<M^o..E.
--0010   00 32 61 2c 00 00 40 01  03 5d 0a 20 01 02 0a 20  .2a,..@..]......
--0020   01 01 08 00 f5 6b 90 23  00 01 67 65 6d 69 6e 69  .....k.#..gemini
--0030   30 31 32 33 34 35 36 37  38 39 61 62 63 64 65 66  0123456789abcdef



  p_comb: PROCESS(rst, r, eth_pkt_sosi, pipe_sosi, my_mac)
    VARIABLE v : t_reg;
  BEGIN
      -- defaults:
      v := r;

      IF eth_pkt_sosi.tvalid = '1' THEN
          v.hdr(r.hdr_idx) := byte_swap_vector(eth_pkt_sosi.tdata(63 DOWNTO 0)); -- byte swap for easier read/decode

          IF r.hdr_idx = 6 THEN 
              v.hdr_idx := 0;

              IF r.decoded = '0' THEN
                  v.decoded := '1';

                  IF (r.hdr(0)(63 DOWNTO 16) = my_mac(47 DOWNTO 0)) OR
                     (r.hdr(0)(63 DOWNTO 16) = x"FFFFFFFFFFFF") THEN

                      v.mac_ok := '1';
                  ELSE
                      v.mac_ok := '0';
                  END IF;




                  -- test if there is a VLAN header:
                  IF r.hdr(1)(31 DOWNTO 16) = x"8100" THEN
                      v.has_vlan_tag := '1';

                      IF r.hdr(2)(63 DOWNTO 48) = x"0806" THEN
                          v.is_arp := '1';
                      ELSE
                          v.is_arp := '0';
                      END IF;

                      IF r.hdr(2)(63 DOWNTO 48) = x"0800" AND r.hdr(3)(39 DOWNTO 32) = x"01" THEN
                          v.is_icmp := '1';
                      ELSE
                          v.is_icmp := '0';
                      END IF;

                      IF r.hdr(2)(63 DOWNTO 48) = x"0800" AND r.hdr(3)(39 DOWNTO 32) = x"11" AND
                        (r.hdr(5)(63 DOWNTO 48) = std_logic_vector(to_unsigned(67,16)) OR    -- dest UDP
                         r.hdr(5)(63 DOWNTO 48) = std_logic_vector(to_unsigned(68,16))) THEN -- dest UDP

                         v.is_udp_dhcp := '1';
                      ELSE
                         v.is_udp_dhcp := '0';
                      END IF;

                      IF r.hdr(2)(63 DOWNTO 48) = x"0800" AND r.hdr(3)(39 DOWNTO 32) = x"11" AND
                        (r.hdr(5)(63 DOWNTO 48) = std_logic_vector(to_unsigned(319,16)) OR    -- dest UDP
                         r.hdr(5)(63 DOWNTO 48) = std_logic_vector(to_unsigned(320,16))) THEN -- dest UDP
                         v.is_udp_ptp := '1';
                      ELSE
                         v.is_udp_ptp := '0';
                      END IF;

                      IF r.hdr(2)(63 DOWNTO 48) = x"0800" AND r.hdr(3)(39 DOWNTO 32) = x"11" AND
                         r.hdr(5)(63 DOWNTO 48) = std_logic_vector(to_unsigned(30000,16)) THEN -- dest UDP
                         v.is_udp_gemini := '1';
                      ELSE
                         v.is_udp_gemini := '0';
                      END IF;

                  ELSE
                      v.has_vlan_tag := '0';

                      IF r.hdr(1)(31 DOWNTO 16) = x"0806" THEN
                          v.is_arp := '1';
                      ELSE
                          v.is_arp := '0';
                      END IF;


                      IF r.hdr(1)(31 DOWNTO 16) = x"0800" AND r.hdr(2)(7 DOWNTO 0) = x"01" THEN
                          v.is_icmp := '1';
                      ELSE
                          v.is_icmp := '0';
                      END IF;

                      IF r.hdr(1)(31 DOWNTO 16) = x"0800" AND r.hdr(2)(7 DOWNTO 0) = x"11" AND
                        (r.hdr(4)(31 DOWNTO 16) = std_logic_vector(to_unsigned(67,16)) OR
                         r.hdr(4)(31 DOWNTO 16) = std_logic_vector(to_unsigned(68,16))) THEN

                         v.is_udp_dhcp := '1';
                      ELSE
                         v.is_udp_dhcp := '0';
                      END IF;

                      IF r.hdr(1)(31 DOWNTO 16) = x"0800" AND r.hdr(2)(7 DOWNTO 0) = x"11" AND
                        (r.hdr(4)(31 DOWNTO 16) = std_logic_vector(to_unsigned(319,16)) OR
                         r.hdr(4)(31 DOWNTO 16) = std_logic_vector(to_unsigned(320,16))) THEN
                         v.is_udp_ptp := '1';
                      ELSE
                         v.is_udp_ptp := '0';
                      END IF;

                      IF r.hdr(1)(31 DOWNTO 16) = x"0800" AND r.hdr(2)(7 DOWNTO 0) = x"11" AND
                         r.hdr(4)(31 DOWNTO 16) = std_logic_vector(to_unsigned(30000,16)) THEN
                         v.is_udp_gemini := '1';
                      ELSE
                         v.is_udp_gemini := '0';
                      END IF;

                  END IF;

              END IF;

          ELSE
              v.hdr_idx := r.hdr_idx + 1;
          END IF;
      END IF;

      IF eth_pkt_sosi.tlast = '1' THEN
        v.hdr_idx := 0;
      END IF;

      IF pipe_sosi.tlast = '1' THEN
        v.decoded       := '0';
        v.mac_ok        := '0';
        v.has_vlan_tag  := '0';
        v.is_arp        := '0';
        v.is_icmp       := '0';
        v.is_udp_dhcp   := '0';
        v.is_udp_ptp    := '0';
        v.is_udp_gemini := '0';
      END IF;

      IF rst='1' THEN
        v.decoded       := '0';
        v.hdr_idx       :=  0;
        v.mac_ok        := '0';
        v.has_vlan_tag  := '0';
        v.is_arp        := '0';
        v.is_icmp       := '0';
        v.is_udp_dhcp   := '0';
        v.is_udp_ptp    := '0';
        v.is_udp_gemini := '0';
      END IF;

      nxt_r <= v; -- updating registers

  END PROCESS;


  p_reg : PROCESS(clk)
  BEGIN
      IF rising_edge(clk) THEN
          r <= nxt_r;
      END IF;
  END PROCESS;

  -- connect to outside world
  eth_pkt_pipe_sosi <= pipe_sosi;

  mac_ok        <= r.mac_ok;
  has_vlan_tag  <= r.has_vlan_tag;
  is_arp        <= r.is_arp;
  is_icmp       <= r.is_icmp;
  is_udp_dhcp   <= r.is_udp_dhcp;
  is_udp_ptp    <= r.is_udp_ptp;
  is_udp_gemini <= r.is_udp_gemini;

END str;


