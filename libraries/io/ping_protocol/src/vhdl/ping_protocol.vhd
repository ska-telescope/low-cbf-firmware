-------------------------------------------------------------------------------
-- File Name: ping_protocol.vhd
-- Contributing Authors: Leon Hiemstra
-- Created: September, 2017
--
-- Title: Ping Protocol Processor
--
-- Description: Converts incoming ICMP/ping request packet into a reply packet
--
-------------------------------------------------------------------------------

LIBRARY IEEE, technology_lib, common_lib, axi4_lib, eth_lib;
USE IEEE.std_logic_1164.ALL;
--USE IEEE.NUMERIC_STD.ALL;
USE IEEE.std_logic_unsigned.all;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE eth_lib.eth_pkg.ALL;


ENTITY ping_protocol IS
  GENERIC (
    g_technology : t_technology := c_tech_select_default
  );
  PORT (
    clk          : IN STD_LOGIC;
    rst          : IN STD_LOGIC;

    eth_in_sosi  : IN  t_axi4_sosi; -- IN  stream
    eth_in_siso  : OUT t_axi4_siso; -- IN  stream

    eth_out_sosi : OUT t_axi4_sosi; -- OUT stream
    eth_out_siso : IN  t_axi4_siso; -- OUT stream

    my_mac       : IN STD_LOGIC_VECTOR(47 DOWNTO 0)
  );
END ping_protocol;


ARCHITECTURE str OF ping_protocol IS

  function byte_swap_mac (a: in std_logic_vector) return std_logic_vector is
    variable result: std_logic_vector(a'RANGE);
  begin
    result(7 downto 0)   := a(47 downto 40);
    result(15 downto 8)  := a(39 downto 32);
    result(23 downto 16) := a(31 downto 24);
    result(31 downto 24) := a(23 downto 16);
    result(39 downto 32) := a(15 downto 8);
    result(47 downto 40) := a(7 downto 0);
    return result;
  end;

CONSTANT c_pipeline : NATURAL := 1;
TYPE t_dat IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR(63 DOWNTO 0);

TYPE t_reg IS RECORD
    pkt_idx    : NATURAL RANGE 0 TO c_max_pkt_size_in64bitwords-1;
    dat        : t_dat(0 TO c_pipeline);
    mac_in_dst : STD_LOGIC_VECTOR(47 DOWNTO 0);
    mac_in_src : STD_LOGIC_VECTOR(47 DOWNTO 0);
    iphdr0    : STD_LOGIC_VECTOR(31 DOWNTO 0);
    iphdr1    : STD_LOGIC_VECTOR(63 DOWNTO 0);
    iphdr2    : STD_LOGIC_VECTOR(15 DOWNTO 0);
    ipaddr_src : STD_LOGIC_VECTOR(31 DOWNTO 0);
    ipaddr_dst : STD_LOGIC_VECTOR(31 DOWNTO 0);
    icmp_type  : STD_LOGIC_VECTOR(15 DOWNTO 0);
    checksum  : STD_LOGIC_VECTOR(15 DOWNTO 0);
    iphdr3    : STD_LOGIC_VECTOR(15 DOWNTO 0);
    iphdr4    : STD_LOGIC_VECTOR(63 DOWNTO 0);
    iphdr5    : STD_LOGIC_VECTOR(63 DOWNTO 0);    
    tdata_tmp : STD_LOGIC_VECTOR(63 DOWNTO 0);
    tvalid    : STD_LOGIC;
    tlast     : STD_LOGIC;
    tlast_idx : NATURAL RANGE 0 TO 3;
    tkeep     : STD_LOGIC_VECTOR(7 DOWNTO 0);
    tkeep_tmp : STD_LOGIC_VECTOR(7 DOWNTO 0);
END RECORD;

SIGNAL r, nxt_r : t_reg;
SIGNAL fifo_full     : STD_LOGIC;
SIGNAL fifo_empty    : STD_LOGIC;
SIGNAL fifo_read     : STD_LOGIC;
SIGNAL ping_out_sosi : t_axi4_sosi;
SIGNAL ping_out_valid : STD_LOGIC;
SIGNAL ping_out_tvalid : STD_LOGIC;
SIGNAL ping_out_tlast  : STD_LOGIC;
SIGNAL checksum_add    : STD_LOGIC_VECTOR(15 downto 0) := x"0008"; -- byte swapped x"0800"


BEGIN

  eth_in_siso.tready <= NOT fifo_full;
  fifo_read          <= eth_out_siso.tready AND (NOT fifo_empty);

  ping_out_valid     <= fifo_read AND ping_out_tvalid;

  eth_out_sosi.tlast  <= ping_out_tlast AND ping_out_valid;
  eth_out_sosi.tvalid <= ping_out_valid;


  u_ping_out_fifo: ENTITY common_lib.common_fifo_sc
  GENERIC MAP (
      g_technology   => g_technology,
      g_use_lut      => FALSE,
      g_dat_w        => 74,
      g_nof_words    => 32,
      g_fifo_latency => 0
  )
  PORT MAP (
      rst                  => rst,
      clk                  => clk,
      wr_dat(63 downto 0)  => ping_out_sosi.tdata(63 downto 0),
      wr_dat(71 downto 64) => ping_out_sosi.tkeep(7 downto 0),
      wr_dat(72)           => ping_out_sosi.tlast,
      wr_dat(73)           => ping_out_sosi.tvalid,
      wr_req               => ping_out_sosi.tvalid,
      wr_ful               => fifo_full,
      wr_prog_ful          => OPEN,
      wr_aful              => OPEN,
      rd_dat(63 downto 0)  => eth_out_sosi.tdata(63 downto 0),
      rd_dat(71 downto 64) => eth_out_sosi.tkeep(7 downto 0),
      rd_dat(72)           => ping_out_tlast,
      rd_dat(73)           => ping_out_tvalid,
      rd_req               => fifo_read,
      rd_emp               => fifo_empty,
      rd_prog_emp          => OPEN,
      rd_val               => OPEN,
      usedw                => OPEN
  );



  p_comb: PROCESS(rst, r, eth_in_sosi)
    VARIABLE v : t_reg;
  BEGIN
    -- defaults:
    v        := r;
    v.tvalid := '0';
    v.tlast  := '0';
    v.tkeep  := eth_in_sosi.tkeep(7 DOWNTO 0);

    IF eth_in_sosi.tvalid = '1' THEN

            IF r.mac_in_dst = byte_swap_mac(my_mac) AND r.pkt_idx > 1 THEN
                v.tvalid := '1';
            END IF;

            CASE r.pkt_idx IS
                WHEN 0 =>                 
                  v.mac_in_dst              := eth_in_sosi.tdata(47 DOWNTO 0);
                  v.mac_in_src(15 DOWNTO 0) := eth_in_sosi.tdata(63 DOWNTO 48);
                  v.pkt_idx                 := r.pkt_idx + 1;
                WHEN 1 =>
                  v.mac_in_src(47 DOWNTO 16) := eth_in_sosi.tdata(31 DOWNTO 0);
                  v.iphdr0                   := eth_in_sosi.tdata(63 DOWNTO 32);
                  v.pkt_idx    := r.pkt_idx + 1;
                WHEN 2 =>
                  v.tdata_tmp  := r.mac_in_dst(15 DOWNTO 0) & r.mac_in_src(47 DOWNTO 0); -- swap dst-src MAC
                  v.iphdr1     := eth_in_sosi.tdata(63 DOWNTO 0); -- 00 32 1a 22 00 00 40 11
                  v.pkt_idx    := r.pkt_idx + 1;
                WHEN 3 =>
                  v.tdata_tmp  := r.iphdr0 & r.mac_in_dst(47 DOWNTO 16); -- swap dst-src MAC
                  v.iphdr2     := eth_in_sosi.tdata(15 DOWNTO 0);  -- 03 5d
                  v.ipaddr_src := eth_in_sosi.tdata(47 DOWNTO 16); -- 0a 20 01 02
                  v.ipaddr_dst(15 DOWNTO 0) := eth_in_sosi.tdata(63 DOWNTO 48); -- 0a 20
                  v.pkt_idx    := r.pkt_idx + 1;
                WHEN 4 =>
                  v.tdata_tmp  := r.iphdr1;
                  v.ipaddr_dst(31 DOWNTO 16) := eth_in_sosi.tdata(15 DOWNTO 0); -- 01 01
                  v.icmp_type  := eth_in_sosi.tdata(31 DOWNTO 16); -- 08 00
                  v.checksum   := eth_in_sosi.tdata(47 DOWNTO 32);
                  v.iphdr3     := eth_in_sosi.tdata(63 DOWNTO 48);
                  v.pkt_idx    := r.pkt_idx + 1;
                WHEN 5 =>
                  v.tdata_tmp(15 DOWNTO 0)  := r.iphdr2;
                  v.tdata_tmp(47 DOWNTO 16) := r.ipaddr_dst; -- swap src-dst IP addr
                  v.tdata_tmp(63 DOWNTO 48) := r.ipaddr_src(15 DOWNTO 0);
                  v.pkt_idx                 := r.pkt_idx + 1;

                  v.dat(0)               := eth_in_sosi.tdata(63 DOWNTO 0); 
                  v.dat(1 TO c_pipeline) := r.dat(0 TO c_pipeline-1);
                WHEN 6 =>
                  v.tdata_tmp(15 DOWNTO 0)  := r.ipaddr_src(31 DOWNTO 16);
                  v.tdata_tmp(31 DOWNTO 16) := x"0000"; -- toggle ICMP type 0800 -> 0000                  
                  v.tdata_tmp(47 DOWNTO 32) := r.checksum + checksum_add; -- change checksum according to Type field
                  v.tdata_tmp(63 DOWNTO 48) := r.iphdr3;
                  v.pkt_idx                 := r.pkt_idx + 1;

                  v.dat(0)               := eth_in_sosi.tdata(63 DOWNTO 0); 
                  v.dat(1 TO c_pipeline) := r.dat(0 TO c_pipeline-1);
                WHEN OTHERS =>
                  v.tdata_tmp            := r.dat(c_pipeline);
                  v.dat(0)               := eth_in_sosi.tdata(63 DOWNTO 0); 
                  v.dat(1 TO c_pipeline) := r.dat(0 TO c_pipeline-1);
            END CASE;


        IF eth_in_sosi.tlast = '1' THEN
            v.tlast_idx := r.tlast_idx + 1;
            v.tkeep_tmp := eth_in_sosi.tkeep(7 DOWNTO 0);
            v.tkeep     := x"FF";
        END IF;
    END IF;


    -- activate tlast after pipelined delay
    IF r.tlast_idx > 0 THEN
        IF r.mac_in_dst = byte_swap_mac(my_mac) THEN
            v.tvalid := '1';
        END IF;
        v.tkeep     := x"FF";
        v.tlast_idx := r.tlast_idx + 1;
        v.tdata_tmp := r.dat(c_pipeline);
        v.dat(1 TO c_pipeline) := r.dat(0 TO c_pipeline-1);
    END IF;

    IF r.tlast_idx = 2 THEN
        v.tlast_idx := 0;
        v.pkt_idx   := 0;
        v.tlast     := '1';
        v.tkeep     := r.tkeep_tmp;
    END IF;


    IF rst='1' THEN
        v.pkt_idx   :=  0;
        v.tlast_idx :=  0;
        v.tdata_tmp := (OTHERS=>'0');
        v.tvalid    := '0';
        v.tlast     := '0';
        v.tkeep     := (OTHERS=>'0');
        v.tkeep_tmp := (OTHERS=>'0');
        v.dat(1 TO c_pipeline) := (OTHERS=>(OTHERS=>'0'));
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
  ping_out_sosi.tdata(63 DOWNTO 0) <= r.tdata_tmp;
  ping_out_sosi.tvalid             <= r.tvalid;
  ping_out_sosi.tlast              <= r.tlast;
  ping_out_sosi.tkeep(7 DOWNTO 0)  <= r.tkeep;

END str;


