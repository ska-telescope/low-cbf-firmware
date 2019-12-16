-------------------------------------------------------------------------------
--
-- Copyright (C) 2012
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

LIBRARY IEEE, common_lib, dp_lib, technology_lib, tech_tse_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE common_lib.tb_common_mem_pkg.ALL;
USE common_lib.common_str_pkg.ALL;
USE common_lib.common_lfsr_sequences_pkg.ALL;
USE common_lib.common_network_layers_pkg.ALL;
USE common_lib.common_network_total_header_pkg.ALL;
USE common_lib.tb_common_pkg.ALL;
USE dp_lib.dp_stream_pkg.ALL;
USE dp_lib.tb_dp_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE tech_tse_lib.tech_tse_pkg.ALL;
USE tech_tse_lib.tb_tech_tse_pkg.ALL;
USE WORK.eth_pkg.ALL;

ENTITY tb_eth_udp_offload IS
  GENERIC (
    g_data_w       : NATURAL := c_word_w;
    g_symbol_w     : NATURAL := 8;     
    g_in_en        : t_dp_flow_control_enum := e_random  
  );
END tb_eth_udp_offload;


ARCHITECTURE tb OF tb_eth_udp_offload IS

  -- tb default
  CONSTANT c_rl               : NATURAL := 1;
  CONSTANT c_pulse_active     : NATURAL := 1;
  CONSTANT c_pulse_period     : NATURAL := 7;
  CONSTANT c_technology_dut   : NATURAL := c_tech_stratixiv;
  
  -- tb specific
  CONSTANT c_nof_repeat       : NATURAL := 10;
  CONSTANT c_bsn_w            : NATURAL := 16;
  CONSTANT c_symbol_init      : NATURAL := 0;
  CONSTANT c_symbol_mod       : INTEGER := 2**g_symbol_w;  -- used to avoid TO_UVEC warning for smaller g_symbol_w : "NUMERIC_STD.TO_UNSIGNED: vector truncated"
  CONSTANT c_err_init         : NATURAL := 0;
  CONSTANT c_sync_period      : NATURAL := 7;
  CONSTANT c_sync_offset      : NATURAL := 2;
  
  -- clock and reset
  CONSTANT c_mm_clk_period    : TIME := 20 ns;
  CONSTANT c_st_clk_period    : TIME := 5 ns;
  CONSTANT c_eth_clk_period   : TIME := 8 ns;  -- 125 MHz

  -- ETH CONSTANTS
  -- ===========================================================================================================================================================

  -- Payload user data
  CONSTANT c_tb_nof_data        : NATURAL := 1440;  -- nof UDP user data, nof ping padding data. NOTE: non-multiples of g_data_w/g_symbol_w not supported as dp_packet_enc/dec do not support encoding/decoding empty
  CONSTANT c_tb_ip_nof_data     : NATURAL := c_network_udp_header_len + c_tb_nof_data; -- nof IP data,

  -- Headers
  -- . Ethernet header
  CONSTANT c_lcu_src_mac        : STD_LOGIC_VECTOR(c_network_eth_mac_slv'RANGE) := X"10FA01020300";
  CONSTANT c_dut_src_mac        : STD_LOGIC_VECTOR(c_network_eth_mac_slv'RANGE) := X"123456789ABC";  -- = 12-34-56-78-9A-BC
  CONSTANT c_dut_src_mac_hi     : NATURAL := TO_UINT(c_dut_src_mac(c_network_eth_mac_addr_w-1 DOWNTO c_word_w));
  CONSTANT c_dut_src_mac_lo     : NATURAL := TO_UINT(c_dut_src_mac(                c_word_w-1 DOWNTO        0));
   
  CONSTANT c_tx_eth_header      : t_network_eth_header := (dst_mac    => c_dut_src_mac,
                                                           src_mac    => c_lcu_src_mac,
                                                           eth_type   => TO_UVEC(c_network_eth_type_ip, c_network_eth_type_w)); --TO_UVEC(c_dut_ethertype, c_network_eth_type_w));
  -- . IP header
  CONSTANT c_lcu_ip_addr        : NATURAL := 16#05060708#;  -- = 05:06:07:08
  CONSTANT c_dut_ip_addr        : NATURAL := 16#01020304#;
  CONSTANT c_tb_ip_total_length : NATURAL := c_network_ip_total_length + c_tb_ip_nof_data;
  CONSTANT c_tb_ip_protocol     : NATURAL := c_network_ip_protocol_udp; --sel_a_b(g_data_type-c_tb_tech_tse_data_type_ping, c_network_ip_protocol_udp, c_network_ip_protocol_icmp);  -- support only ping protocol or UDP protocol over IP
  
  CONSTANT c_tx_ip_header       : t_network_ip_header := (version         => TO_UVEC(c_network_ip_version,         c_network_ip_version_w),
                                                          header_length   => TO_UVEC(c_network_ip_header_length,   c_network_ip_header_length_w),
                                                          services        => TO_UVEC(c_network_ip_services,        c_network_ip_services_w),
                                                          total_length    => TO_UVEC(c_tb_ip_total_length,         c_network_ip_total_length_w),
                                                          identification  => TO_UVEC(c_network_ip_identification,  c_network_ip_identification_w),
                                                          flags           => TO_UVEC(c_network_ip_flags,           c_network_ip_flags_w),
                                                          fragment_offset => TO_UVEC(c_network_ip_fragment_offset, c_network_ip_fragment_offset_w),
                                                          time_to_live    => TO_UVEC(c_network_ip_time_to_live,    c_network_ip_time_to_live_w),
                                                          protocol        => TO_UVEC(c_tb_ip_protocol,             c_network_ip_protocol_w),
                                                          header_checksum => TO_UVEC(c_network_ip_header_checksum, c_network_ip_header_checksum_w),  -- init value (or try 0xEBBD = 60349)
                                                          src_ip_addr     => TO_UVEC(c_lcu_ip_addr,                c_network_ip_addr_w),
                                                          dst_ip_addr     => TO_UVEC(c_dut_ip_addr,                c_network_ip_addr_w));

  -- . UDP header
  CONSTANT c_dut_udp_port_ctrl   : NATURAL := 11;                  -- ETH demux UDP for control
  CONSTANT c_dut_udp_port_st0    : NATURAL := 57;                  -- ETH demux UDP port 0
  CONSTANT c_dut_udp_port_st1    : NATURAL := 58;                  -- ETH demux UDP port 1
  CONSTANT c_dut_udp_port_st2    : NATURAL := 59;                  -- ETH demux UDP port 2
  CONSTANT c_dut_udp_port_en     : NATURAL := 16#10000#;           -- ETH demux UDP port enable bit 16
  CONSTANT c_lcu_udp_port        : NATURAL := 10;                  -- UDP port used for src_port
  CONSTANT c_dut_udp_port_st     : NATURAL := c_dut_udp_port_st0;  -- UDP port used for dst_port
  CONSTANT c_tb_udp_total_length : NATURAL := c_network_udp_total_length + c_tb_nof_data;
  CONSTANT c_tx_udp_header       : t_network_udp_header := (src_port     => TO_UVEC(c_lcu_udp_port,         c_network_udp_port_w),
                                                            dst_port     => TO_UVEC(c_dut_udp_port_st,      c_network_udp_port_w),       -- or use c_dut_udp_port_ctrl
                                                            total_length => TO_UVEC(c_tb_udp_total_length,  c_network_udp_total_length_w),
                                                            checksum     => TO_UVEC(c_network_udp_checksum, c_network_udp_checksum_w));  -- init value
 
  CONSTANT c_word_align          : STD_LOGIC_VECTOR(c_network_total_header_32b_align_w-1 DOWNTO 0) := (OTHERS=>'0');
  CONSTANT c_total_hdr_slv       : STD_LOGIC_VECTOR(c_network_total_header_32b_nof_words*c_word_w-1 DOWNTO 0) := c_word_align                   &
                                                                                                                 c_tx_eth_header.dst_mac        &
                                                                                                                 c_tx_eth_header.src_mac        &
                                                                                                                 c_tx_eth_header.eth_type       &
                                                                                                                 c_tx_ip_header.version         &
                                                                                                                 c_tx_ip_header.header_length   &
                                                                                                                 c_tx_ip_header.services        &
                                                                                                                 c_tx_ip_header.total_length    &
                                                                                                                 c_tx_ip_header.identification  &
                                                                                                                 c_tx_ip_header.flags           &
                                                                                                                 c_tx_ip_header.fragment_offset &
                                                                                                                 c_tx_ip_header.time_to_live    &
                                                                                                                 c_tx_ip_header.protocol        &
                                                                                                                 c_tx_ip_header.header_checksum &
                                                                                                                 c_tx_ip_header.src_ip_addr     &
                                                                                                                 c_tx_ip_header.dst_ip_addr     &
                                                                                                                 c_tx_udp_header.src_port       & 
                                                                                                                 c_tx_udp_header.dst_port       &
                                                                                                                 c_tx_udp_header.total_length   &
                                                                                                                 c_tx_udp_header.checksum;

  -- ===========================================================================================================================================================

  -- TSE constants
  CONSTANT c_promis_en          : BOOLEAN := FALSE;
  CONSTANT c_tx_ready_latency   : NATURAL := c_tech_tse_tx_ready_latency;  -- 0, 1 are supported, must match TSE MAC c_tech_tse_tx_ready_latency

  -- ETH control
  CONSTANT c_dut_control_rx_en   : NATURAL := 2**c_eth_mm_reg_control_bi.rx_en;

  -- ETH TSE interface
  SIGNAL eth_psc_access      : STD_LOGIC;

  SIGNAL tb_eth_hdr           : t_network_eth_header := c_tx_eth_header;
  SIGNAL tb_ip_hdr            : t_network_ip_header  := c_tx_ip_header;
  SIGNAL tb_udp_hdr           : t_network_udp_header := c_tx_udp_header;

  SIGNAL eth_clk              : STD_LOGIC := '0';  -- tse reference clock
  SIGNAL mm_clk               : STD_LOGIC := '0';
  SIGNAL mm_rst               : STD_LOGIC;
  SIGNAL st_rst               : STD_LOGIC;
  SIGNAL st_clk               : STD_LOGIC := '0';

  SIGNAL tb_end               : STD_LOGIC := '0';

  SIGNAL random_0             : STD_LOGIC_VECTOR(14 DOWNTO 0) := (OTHERS=>'0');  -- use different lengths to have different random sequences
  SIGNAL random_1             : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS=>'0');  -- use different lengths to have different random sequences
  SIGNAL pulse_0              : STD_LOGIC;
  SIGNAL pulse_1              : STD_LOGIC;
  SIGNAL pulse_en             : STD_LOGIC := '1';
  
  SIGNAL in_en                : STD_LOGIC := '1';
  
  -- tb verify
  SIGNAL verify_en            : STD_LOGIC := '0';
  SIGNAL verify_done          : STD_LOGIC := '0';
  
  SIGNAL prev_udp_rx_ready    : STD_LOGIC_VECTOR(0 TO c_rl);
  SIGNAL prev_udp_rx_data     : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);

  SIGNAL out_gap              : STD_LOGIC := '1';

  -- dp_hdr_insert/remove signals
  SIGNAL reg_hdr_mosi         : t_mem_mosi;
  SIGNAL ram_hdr_mosi         : t_mem_mosi;
  SIGNAL ram_hdr_miso         : t_mem_miso; 

  -- ETH TSE interface
  SIGNAL eth_tse_miso        : t_mem_miso;
  SIGNAL eth_tse_mosi        : t_mem_mosi;
  SIGNAL eth_serial_loopback : STD_LOGIC;
   
  -- ETH UDP data path from tx generation to rx verification
  SIGNAL udp_tx_sosi         : t_dp_sosi;
  SIGNAL udp_tx_siso         : t_dp_siso;

  SIGNAL udp_tx_pkt_sosi     : t_dp_sosi;
  SIGNAL udp_tx_pkt_siso     : t_dp_siso;

  SIGNAL udp_tx_hdr_pkt_sosi_arr : t_dp_sosi_arr(c_eth_nof_udp_ports-1 DOWNTO 0);
  SIGNAL udp_tx_hdr_pkt_siso_arr : t_dp_siso_arr(c_eth_nof_udp_ports-1 DOWNTO 0);

  SIGNAL udp_rx_frame_pkt_siso_arr : t_dp_siso_arr(c_eth_nof_udp_ports-1 DOWNTO 0);
  SIGNAL udp_rx_frame_pkt_sosi_arr : t_dp_sosi_arr(c_eth_nof_udp_ports-1 DOWNTO 0);

  SIGNAL udp_rx_pkt_siso     : t_dp_siso;
  SIGNAL udp_rx_pkt_sosi     : t_dp_sosi;

  SIGNAL udp_rx_siso         : t_dp_siso;
  SIGNAL udp_rx_sosi         : t_dp_sosi;

  -- ETH MM registers interface
  SIGNAL eth_reg_miso        : t_mem_miso;
  SIGNAL eth_reg_mosi        : t_mem_mosi;
  SIGNAL eth_reg_interrupt   : STD_LOGIC;

  SIGNAL eth_ram_miso        : t_mem_miso;
  SIGNAL eth_ram_mosi        : t_mem_mosi;

  SIGNAL dut_eth_init        : STD_LOGIC := '1';
  SIGNAL dut_tse_init        : STD_LOGIC := '1';  

BEGIN

  mm_clk <= (NOT mm_clk) OR tb_end AFTER c_mm_clk_period/2;
  mm_rst <= '1', '0' AFTER c_mm_clk_period*20;

  st_clk <= (NOT st_clk) OR tb_end AFTER c_st_clk_period/2;
  st_rst <= '1', '0' AFTER c_st_clk_period*7;

  eth_clk <= NOT eth_clk OR tb_end AFTER c_eth_clk_period/2;  -- TSE reference clock
  
  random_0 <= func_common_random(random_0) WHEN rising_edge(st_clk);
  random_1 <= func_common_random(random_1) WHEN rising_edge(st_clk);
  
  proc_common_gen_duty_pulse(c_pulse_active, c_pulse_period,   '1', st_rst, st_clk, pulse_en, pulse_0);
  proc_common_gen_duty_pulse(c_pulse_active, c_pulse_period+1, '1', st_rst, st_clk, pulse_en, pulse_1);

  ------------------------------------------------------------------------------
  -- STREAM CONTROL
  ------------------------------------------------------------------------------
  
  in_en          <= '1'                     WHEN g_in_en=e_active      ELSE
                    random_0(random_0'HIGH) WHEN g_in_en=e_random      ELSE
                    pulse_0                 WHEN g_in_en=e_pulse;
                       
   udp_rx_siso.ready <= '1';
   udp_rx_siso.xon   <= '1';

  ------------------------------------------------------------------------------
  -- TSE SETUP
  ------------------------------------------------------------------------------ 
  p_tse_setup : PROCESS
  BEGIN
    dut_tse_init <= '1';
    eth_tse_mosi.wr <= '0';
    eth_tse_mosi.rd <= '0';
     -- Wait for ETH init
    WHILE dut_eth_init='1' LOOP WAIT UNTIL rising_edge(mm_clk); END LOOP;
    -- Setup the TSE MAC
    proc_tech_tse_setup(c_technology_dut,
                        c_promis_en, c_tech_tse_tx_fifo_depth, c_tech_tse_rx_fifo_depth, c_tx_ready_latency,
                        c_dut_src_mac, eth_psc_access,
                        mm_clk, eth_tse_miso, eth_tse_mosi);
    dut_tse_init <= '0';
    WAIT;
  END PROCESS;


  ------------------------------------------------------------------------------
  -- DATA GENERATION
  ------------------------------------------------------------------------------
  
  -- Generate data path input data
  p_stimuli : PROCESS
    VARIABLE v_sync      : STD_LOGIC := '0';
    VARIABLE v_bsn       : STD_LOGIC_VECTOR(c_bsn_w-1 DOWNTO 0) := (OTHERS=>'0');
    VARIABLE v_symbol    : NATURAL := c_symbol_init;
    VARIABLE v_channel   : NATURAL := 1;
    VARIABLE v_err       : NATURAL := c_err_init;

    VARIABLE v_mm_wr_addr : NATURAL := 0;
    VARIABLE v_mm_wr_hdr  : STD_LOGIC_VECTOR(c_word_w-1 DOWNTO 0);
  BEGIN
    udp_tx_sosi  <= c_dp_sosi_rst;
    reg_hdr_mosi <= c_mem_mosi_rst;    
    ram_hdr_mosi <= c_mem_mosi_rst;    
    eth_reg_mosi <= c_mem_mosi_rst;    
    eth_ram_mosi <= c_mem_mosi_rst;    

    dut_eth_init <= '1';

    proc_common_wait_until_low(mm_clk, mm_rst);
    proc_common_wait_some_cycles(mm_clk, 5);

    -- Set up the UDP demux
    proc_mem_mm_bus_wr(c_eth_reg_demux_wi+0, c_dut_udp_port_en+c_dut_udp_port_st0, mm_clk, eth_reg_miso, eth_reg_mosi);  -- UDP port stream 0
    proc_common_wait_some_cycles(mm_clk, 5);

    -- Setup the RX config
    proc_mem_mm_bus_wr(c_eth_reg_config_wi+0, c_dut_src_mac_lo,     mm_clk, eth_reg_miso, eth_reg_mosi);  -- control MAC address lo word
    proc_mem_mm_bus_wr(c_eth_reg_config_wi+1, c_dut_src_mac_hi,     mm_clk, eth_reg_miso, eth_reg_mosi);  -- control MAC address hi halfword
    proc_mem_mm_bus_wr(c_eth_reg_config_wi+2, c_dut_ip_addr,        mm_clk, eth_reg_miso, eth_reg_mosi);  -- control IP address
    proc_mem_mm_bus_wr(c_eth_reg_config_wi+3, c_dut_udp_port_ctrl,  mm_clk, eth_reg_miso, eth_reg_mosi);  -- control UDP port
    -- Enable RX
    proc_mem_mm_bus_wr(c_eth_reg_control_wi+0, c_dut_control_rx_en, mm_clk, eth_reg_miso, eth_reg_mosi);  -- control rx en
    dut_eth_init <= '0';

    -- MM Stimuli: write HEADER to RAM
    FOR i IN c_network_total_header_32b_nof_words DOWNTO 1 LOOP
      -- Extract words from SLV from left to right
      v_mm_wr_hdr := c_total_hdr_slv(i*c_word_w-1 DOWNTO i*c_word_w - c_word_w);
      proc_mem_mm_bus_wr(v_mm_wr_addr, v_mm_wr_hdr, mm_clk, ram_hdr_mosi);
      proc_common_wait_some_cycles(mm_clk, 5);

      IF v_mm_wr_addr<c_network_total_header_32b_nof_words-1 THEN
        v_mm_wr_addr := v_mm_wr_addr + 1;
      END IF;
    END LOOP;

    -- Release the header onto the DP
    proc_mem_mm_bus_wr(0, 1, mm_clk, reg_hdr_mosi);
    
    -- Begin of ST stimuli
    proc_common_wait_until_low(st_clk, st_rst);
    proc_common_wait_some_cycles(st_clk, 50);

    FOR R IN 0 TO c_nof_repeat-1 LOOP
      v_sync := sel_a_b(R MOD c_sync_period = c_sync_offset, '1', '0');  -- v_bsn = R
      proc_dp_gen_block_data(c_rl, TRUE, g_data_w, g_symbol_w, v_symbol, 0, 0, c_tb_nof_data, v_channel, v_err, v_sync, TO_DP_BSN(R), st_clk, in_en, udp_tx_siso, udp_tx_sosi);
      v_bsn     := INCR_UVEC(v_bsn, 1);
      v_symbol  := (v_symbol + c_tb_nof_data) MOD c_symbol_mod;
      v_err     := v_err + 1;
      --proc_common_wait_some_cycles(st_clk, 10);               -- create gap between frames
    END LOOP;
    
    -- End of stimuli
    proc_common_wait_some_cycles(st_clk, 50);  -- depends on stream control
    verify_done <= '1';
    proc_common_wait_some_cycles(st_clk, 1);
    verify_done <= '0';

    -- Resync to MM clk
    proc_common_wait_some_cycles(mm_clk, 5);

    -- Read the stripped header via MM bus and print it in the transcript window
    print_str("Reading stripped header from RAM:");
    FOR i IN 0 TO c_network_total_header_32b_nof_words-1 LOOP
      proc_mem_mm_bus_rd(i, mm_clk, ram_hdr_mosi);
      proc_mem_mm_bus_rd_latency(c_mem_reg_rd_latency, mm_clk);
      print_str("[" & time_to_str(now) & "] 0x" & slv_to_hex(ram_hdr_miso.rddata(c_word_w-1 DOWNTO 0)));
    END LOOP;
    
    proc_common_wait_until_high(st_clk, out_gap);
    proc_common_wait_some_cycles(st_clk, 1000);
    tb_end <= '1';
    WAIT;
  END PROCESS;
 
  -- Stop the simulation
  p_tb_end : PROCESS  
  BEGIN
    WAIT UNTIL tb_end='1';
    WAIT FOR 10 us;
    ASSERT FALSE REPORT "Simulation tb_eth_udp_offload finished." SEVERITY NOTE;
    WAIT;
  END PROCESS;
  
  ------------------------------------------------------------------------------
  -- DATA VERIFICATION
  ------------------------------------------------------------------------------
  
  verify_en <= '1' WHEN rising_edge(st_clk) AND udp_rx_sosi.sop='1';  -- verify enable after first output sop
  
  -- SOSI control
  proc_dp_verify_valid(c_rl, st_clk, verify_en, udp_rx_siso.ready, prev_udp_rx_ready, udp_rx_sosi.valid);        -- Verify that the output valid fits with the output ready latency
  proc_dp_verify_gap_invalid(st_clk, udp_rx_sosi.valid, udp_rx_sosi.sop, udp_rx_sosi.eop, out_gap);                        -- Verify that the output valid is low between blocks from eop to sop
    
  -- SOSI data
  -- . verify that the output is incrementing symbols, like the input stimuli
  proc_dp_verify_symbols(c_rl, g_data_w, g_symbol_w, st_clk, verify_en, udp_rx_siso.ready, udp_rx_sosi.valid, udp_rx_sosi.eop, udp_rx_sosi.data(g_data_w-1 DOWNTO 0), udp_rx_sosi.empty, prev_udp_rx_data);
  
  ------------------------------------------------------------------------------
  -- DUT
  ------------------------------------------------------------------------------
  dut : ENTITY work.eth
  GENERIC MAP (
    g_technology         => c_technology_dut,
    g_cross_clock_domain => TRUE 
  )
  PORT MAP (
    -- Clocks and reset
    mm_rst            => mm_rst,
    mm_clk            => mm_clk,
    eth_clk           => eth_clk,
    st_rst            => st_rst,
    st_clk            => st_clk,
    -- UDP transmit interface
    -- . ST sink
    udp_tx_snk_in_arr  => udp_tx_hdr_pkt_sosi_arr,
    udp_tx_snk_out_arr => udp_tx_hdr_pkt_siso_arr,
    -- UDP receive interface
    -- . ST source
    udp_rx_src_in_arr  => udp_rx_frame_pkt_siso_arr,
    udp_rx_src_out_arr => udp_rx_frame_pkt_sosi_arr,
    -- Control Memory Mapped Slaves
    tse_sla_in        => eth_tse_mosi,
    tse_sla_out       => eth_tse_miso,
    reg_sla_in        => eth_reg_mosi,
    reg_sla_out       => eth_reg_miso,
    reg_sla_interrupt => eth_reg_interrupt,
    ram_sla_in        => eth_ram_mosi,
    ram_sla_out       => eth_ram_miso,
    -- PHY interface
    eth_txp           => eth_serial_loopback,
    eth_rxp           => eth_serial_loopback,
    -- LED interface
    tse_led           => OPEN
  );

  u_hdr_insert : ENTITY dp_lib.dp_hdr_insert
  GENERIC MAP (
    g_data_w        => g_data_w,
    g_symbol_w      => g_symbol_w,
    g_hdr_nof_words => c_network_total_header_32b_nof_words
  )
  PORT MAP (
    mm_rst      => mm_rst,
    mm_clk      => mm_clk, 
                           
    st_rst      => st_rst, 
    st_clk      => st_clk, 

    reg_mosi    => reg_hdr_mosi,                           
    ram_mosi    => ram_hdr_mosi,
                           
    snk_out     => udp_tx_pkt_siso,
    snk_in      => udp_tx_pkt_sosi,
                           
    src_in      => udp_tx_hdr_pkt_siso_arr(0),
    src_out     => udp_tx_hdr_pkt_sosi_arr(0)
  );       

  u_dp_packet_enc : ENTITY dp_lib.dp_packet_enc
  GENERIC MAP (
    g_data_w => g_data_w
  )
  PORT MAP (
    rst       => st_rst,
    clk       => st_clk,

    snk_out   => udp_tx_siso,
    snk_in    => udp_tx_sosi,

    src_in    => udp_tx_pkt_siso,
    src_out   => udp_tx_pkt_sosi
  );             
                           
  u_frame_remove : ENTITY dp_lib.dp_frame_remove
  GENERIC MAP (            
    g_data_w        => g_data_w,
    g_symbol_w      => g_symbol_w,
    g_hdr_nof_words => c_network_total_header_32b_nof_words,
    g_tail_nof_words=> (c_network_eth_crc_len * g_symbol_w) / c_word_w
  )                        
  PORT MAP (               
    mm_rst      => mm_rst, 
    mm_clk      => mm_clk, 
                           
    st_rst      => st_rst, 
    st_clk      => st_clk, 
                           
    snk_out     => udp_rx_frame_pkt_siso_arr(0),
    snk_in      => udp_rx_frame_pkt_sosi_arr(0),

    sla_in      => ram_hdr_mosi,
    sla_out     => ram_hdr_miso,

    src_in      => udp_rx_pkt_siso,
    src_out     => udp_rx_pkt_sosi
  );

  u_dp_packet_dec : ENTITY dp_lib.dp_packet_dec
  GENERIC MAP (
    g_data_w => g_data_w
  )
  PORT MAP (
    rst       => st_rst,
    clk       => st_clk,

    snk_out   => udp_rx_pkt_siso,
    snk_in    => udp_rx_pkt_sosi,

    src_in    => udp_rx_siso,
    src_out   => udp_rx_sosi 
  );
  
END tb;
