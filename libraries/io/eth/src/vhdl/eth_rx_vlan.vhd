-------------------------------------------------------------------------------
-- File Name: eth_rx_vlan.vhd
-- Contributing Authors: Leon Hiemstra
-- Created: September, 2017
--
-- Title: Ethernet RX VLAN header stripper
--
-- Description: Strips off a VLAN header if existing
--
-------------------------------------------------------------------------------

LIBRARY IEEE, common_lib, axi4_lib;
USE IEEE.std_logic_1164.ALL;
USE common_lib.common_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE work.eth_pkg.ALL;


ENTITY eth_rx_vlan IS
  PORT (
    clk          : IN STD_LOGIC;
    rst          : IN STD_LOGIC;

    strip_en     : IN STD_LOGIC;    -- enable VLAN stripper

    eth_in_sosi  : IN  t_axi4_sosi; -- IN  stream
    eth_out_sosi : OUT t_axi4_sosi  -- OUT stream
  );
END eth_rx_vlan;


ARCHITECTURE str OF eth_rx_vlan IS

TYPE t_reg IS RECORD
    pkt_idx   : NATURAL RANGE 0 TO c_max_pkt_size_in64bitwords-1;
    tdata_lsw : STD_LOGIC_VECTOR(31 DOWNTO 0);
    tdata_msw : STD_LOGIC_VECTOR(31 DOWNTO 0);
    tdata_tmp : STD_LOGIC_VECTOR(31 DOWNTO 0);
    tvalid    : STD_LOGIC;
    tlast     : STD_LOGIC;
    tlast_tmp : STD_LOGIC;
    tkeep     : STD_LOGIC_VECTOR(7 DOWNTO 0);
    tkeep_tmp : STD_LOGIC_VECTOR(7 DOWNTO 0);
END RECORD;

SIGNAL r, nxt_r : t_reg;

BEGIN

  p_comb: PROCESS(rst, r, eth_in_sosi, strip_en)
    VARIABLE v : t_reg;
  BEGIN
    -- defaults:
    v           := r;
    v.tkeep     := eth_in_sosi.tkeep(7 DOWNTO 0);
    v.tvalid    := '0';
    v.tlast     := '0';
    v.tlast_tmp := '0';


    IF eth_in_sosi.tvalid = '1' THEN
        v.pkt_idx := r.pkt_idx + 1;


        IF strip_en = '1' AND r.pkt_idx = 0 THEN
            v.tdata_msw := eth_in_sosi.tdata(63 DOWNTO 32);
            v.tdata_lsw := eth_in_sosi.tdata(31 DOWNTO 0);
        ELSIF strip_en = '1' AND r.pkt_idx = 1 THEN
            v.tvalid  := '1';
            -- here ignore eth_in_sosi.tdata(63 DOWNTO 32). This was the VLAN header (bytes are swapped in MAC)
            v.tdata_tmp := eth_in_sosi.tdata(31 DOWNTO 0); -- temporary store
        ELSIF strip_en = '1' AND r.pkt_idx > 1 THEN
            v.tvalid  := '1';
            -- shift msw -> lsw
            v.tdata_lsw := r.tdata_tmp;
            v.tdata_msw := eth_in_sosi.tdata(31 DOWNTO 0); 
            v.tdata_tmp := eth_in_sosi.tdata(63 DOWNTO 32); -- temporary store
        ELSE
            v.tvalid  := '1';
            v.tdata_msw := eth_in_sosi.tdata(63 DOWNTO 32);
            v.tdata_lsw := eth_in_sosi.tdata(31 DOWNTO 0);
        END IF;


        IF eth_in_sosi.tlast = '1' THEN

            IF strip_en = '1' THEN
                IF eth_in_sosi.tkeep(7 DOWNTO 0) <= x"0F" THEN
                    -- logical shift left and fillup with 1's:
                    v.tkeep := eth_in_sosi.tkeep(3 DOWNTO 0) & "1111";                    
                    v.tlast := '1'; -- end packet now
                ELSE
                    v.tlast_tmp := '1'; -- add a pipelined delay
                    v.tkeep_tmp := eth_in_sosi.tkeep(7 DOWNTO 0);
                    v.tkeep := x"FF";   -- second last tkeep is still FF
                END IF;
            ELSE
                v.tlast := '1';
            END IF;
        END IF;
    END IF;


    -- activate tlast after pipelined delay
    IF r.tlast_tmp = '1' THEN
        v.tvalid    := '1';
        v.tdata_lsw := r.tdata_tmp;
        v.tdata_msw := (OTHERS=>'0');
        v.tkeep     := "0000" & r.tkeep_tmp(7 DOWNTO 4); -- logical shift right to reduce 32bits
        v.tlast     := '1';
    END IF;


    IF r.tlast = '1' THEN
        v.pkt_idx  :=  0;      
    END IF;


    IF rst='1' THEN
        v.pkt_idx   :=  0;      
        v.tdata_lsw := (OTHERS=>'0');
        v.tdata_msw := (OTHERS=>'0');
        v.tdata_tmp := (OTHERS=>'0');
        v.tvalid    := '0';
        v.tlast     := '0';
        v.tkeep     := (OTHERS=>'0');
        v.tkeep_tmp := (OTHERS=>'0');
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
  eth_out_sosi.tdata(63 DOWNTO 32) <= r.tdata_msw;
  eth_out_sosi.tdata(31 DOWNTO 0)  <= r.tdata_lsw;
  eth_out_sosi.tvalid              <= r.tvalid;
  eth_out_sosi.tlast               <= r.tlast;
  eth_out_sosi.tkeep(7 DOWNTO 0)   <= r.tkeep;

  -- connect
  eth_out_sosi.tuser <= eth_in_sosi.tuser;
  eth_out_sosi.tid   <= eth_in_sosi.tid;
  eth_out_sosi.tdest <= eth_in_sosi.tdest;
  eth_out_sosi.tstrb <= eth_in_sosi.tstrb;

END str;


