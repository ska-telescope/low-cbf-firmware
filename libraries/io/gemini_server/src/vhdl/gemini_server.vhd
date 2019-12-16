----------------------------------
-- Copyright (C) 2017
-- CSIRO (Commonwealth Scientific and Industrial Research Organization) <http://www.csiro.au/>
-- GPO Box 1700, Canberra, ACT 2601, Australia
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
--   Author           Date      Version comments
--   John Matthews    Dec 2017  Original
-----------------------------------

-- Purpose: Gemini Server
--
-- Description:
--
-- Remarks:
--

LIBRARY IEEE, common_lib, technology_lib, gemini_server_lib, tech_axi4dm_lib, axi4_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE gemini_server_lib.gemini_server_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE axi4_lib.axi4_full_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE tech_axi4dm_lib.tech_axi4dm_component_pkg.ALL;

ENTITY gemini_server IS
GENERIC (
    g_technology: t_technology := c_tech_select_default;
    g_noof_clnts : NATURAL RANGE 1 TO 3 := 3; -- Maximum number of clients
    g_data_w : NATURAL := 64; -- Data width for ETHTX and ETHRX buses
    g_mm_data_w : NATURAL := 32; -- Data width for MM bus
    g_tod_w : NATURAL := 14; -- Width of ToD
    g_max_pipeline : NATURAL := 8; -- Maximum pipeline depth (packets)
    g_mtu : NATURAL := 8000; -- Maximum Transmission Unit (bytes)
    g_min_recycle_secs : NATURAL RANGE 0 to 7*24*60 := 5*60; -- Minimum client connection recycle time in seconds
    -- AXI transaction aborted if it takes longer than nregs + g_txfr_timeout
    -- If blen is AXI max burst length (in clocks) - assume 2 wasted cycles per
    -- burst. So a max length Ethernet frame would result in approx = g_mtu/(8*blen) bursts.
    -- Assuming blen is 16.
    g_txfr_timeout : NATURAL := 400
    );
PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    mm_reset_out : out std_logic; -- reset to downstream modules on the mm bus, to prevent lockup from broken transactions issued by the datamover when it is reset.
    -- Interface (AXI4S Sink): ETHRX
    ethrx_in : IN t_axi4_sosi; -- Sink in
    ethrx_out : OUT t_axi4_siso; -- Sink out
    -- Interface (AXI4S Source): ETHTX
    ethtx_in : IN t_axi4_siso; -- Source in
    ethtx_out : OUT t_axi4_sosi; -- Source out
    -- Interface (AXI4 Master): MM bus
    mm_in : IN t_axi4_full_miso;
    mm_out : OUT t_axi4_full_mosi;
    -- Time Of Day with seconds precision
    tod_in : IN STD_LOGIC_VECTOR(g_tod_w-1 DOWNTO 0);
    -- status signals to send to the register interface
    client0IP : out std_logic_vector(31 downto 0);
    client0Port : out std_logic_vector(15 downto 0);
    client0LastUsed : out std_logic_vector(31 downto 0);
    client1IP : out std_logic_vector(31 downto 0);
    client1Port : out std_logic_vector(15 downto 0);
    client1LastUsed : out std_logic_vector(31 downto 0);
    client2IP : out std_logic_vector(31 downto 0);
    client2Port : out std_logic_vector(15 downto 0);
    client2LastUsed : out std_logic_vector(31 downto 0);
    -- other debug
    req_csrb_state : out std_logic_vector(2 downto 0);
    req_main_state : out std_logic_vector(3 downto 0);
    replay_state   : out std_logic_vector(3 downto 0);
    completion_state : out std_logic_vector(3 downto 0);
    rq_state         : out std_logic_vector(3 downto 0);
    rq_stream_state  : out std_logic_vector(3 downto 0);
    resp_state       : out std_logic_vector(3 downto 0);
    crqb_fifo_rd_data_sel_out : out std_logic_vector(87 DOWNTO 0);
    crqb_fifo_rd_out : out std_logic_vector(2 downto 0);
    -- debug commands to datamover
    s2mm_in_dbg : out t_axi4_sosi;  -- Sink in
    s2mm_out_dbg : out t_axi4_siso; -- Sink out
    -- AXI4S Sink: S2MM Command
    s2mm_cmd_in_dbg : out t_axi4_sosi; -- Sink in
    s2mm_cmd_out_dbg : OUT t_axi4_siso; -- Sink out
    -- AXI4S Source: M_AXIS_S2MM_STS
    s2mm_sts_in_dbg : out t_axi4_siso;  -- Source in
    s2mm_sts_out_dbg : OUT t_axi4_sosi;  -- Source out
    -- timer expiry debug
    dbg_timer_expire : out std_logic;
    dbg_timer : out std_logic_vector(15 downto 0)
    );
END gemini_server;

ARCHITECTURE rtl OF gemini_server IS

    CONSTANT c_key_w : NATURAL := ceil_log2(g_noof_clnts);
    CONSTANT c_npart_len : NATURAL := 16; -- Length of RAM partition for unconnected clients (64bit words)
    CONSTANT c_cpart_len : NATURAL := g_max_pipeline * ( 1 + ( g_mtu + 18 ) / ( g_data_w / 8 ) ); -- Length of RAM partition for connected clients (64 bit words)
    CONSTANT c_ram_len : NATURAL := c_npart_len + g_noof_clnts * c_cpart_len; -- Total length of CRQB/CRSB RAM (64bit words)
    CONSTANT c_ram_addr_w : NATURAL := ceil_log2(c_ram_len);
    CONSTANT c_crqb_fifo_len : NATURAL := 16; -- Length of CRQB FIFOs. Must be >= g_max_pipeline
    CONSTANT c_crqb_fifo_w : NATURAL := 88; -- Must be >= c_crqb_addr_w + 64
    CONSTANT c_crsb_fifo_w : NATURAL := 80;
    CONSTANT c_crsb_fifo_len : NATURAL := 16;
    CONSTANT c_clnt_addr_w : NATURAL := 48;

    -- Header length assumptions: 14 bytes MAC, 20 bytes IP, 8 bytes UDP, 12 bytes Gemini PDU
    -- 2019-04-12 experimentally we find ethernet RX doesn't support MTU 8000 bytes, so we need to decrease
    --            this by 5 registers for it to work, let's decrease by 6 so it's a multiple of 16/32/64
    CONSTANT c_max_nregs : INTEGER := ((g_mtu-(20+8+12))/4)-6;

    TYPE t_data_arr IS ARRAY ( NATURAL RANGE <> ) OF STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    TYPE t_crqb_data_arr IS ARRAY ( NATURAL RANGE <> ) OF STD_LOGIC_VECTOR(c_crqb_fifo_w-1 DOWNTO 0);

    SIGNAL rstn : STD_LOGIC;
    SIGNAL mm2s_aresetn : STD_LOGIC;
    SIGNAL s2mm_aresetn : STD_LOGIC;
    SIGNAL crqb_ram : t_data_arr(0 TO c_ram_len-1);
    SIGNAL crqb_wr : STD_LOGIC;
    SIGNAL crqb_rd_addr : STD_LOGIC_VECTOR(c_ram_addr_w-1 DOWNTO 0);
    SIGNAL crqb_wr_addr : STD_LOGIC_VECTOR(c_ram_addr_w-1 DOWNTO 0);
    SIGNAL crqb_wr_data : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    SIGNAL crqb_rd_data : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    SIGNAL crqb_fifo_wr : STD_LOGIC_VECTOR(g_noof_clnts+1 DOWNTO 1);
    SIGNAL crqb_fifo_rd : STD_LOGIC_VECTOR(g_noof_clnts+1 DOWNTO 1);
    --SIGNAL crqb_fifo_rd_out : STD_LOGIC_VECTOR(g_noof_clnts+1 DOWNTO 1);
    SIGNAL crqb_fifo_full : STD_LOGIC_VECTOR(g_noof_clnts+1 DOWNTO 1);
    SIGNAL crqb_fifo_empty : STD_LOGIC_VECTOR(g_noof_clnts+1 DOWNTO 1);
    SIGNAL crsb_fifo_empty_sel : STD_LOGIC;
    SIGNAL crqb_fifo_wr_data : STD_LOGIC_VECTOR(c_crqb_fifo_w-1 DOWNTO 0);
    SIGNAL crqb_fifo_rd_data : t_crqb_data_arr(1 TO g_noof_clnts+1);
    SIGNAL crqb_fifo_rd_data_sel : STD_LOGIC_VECTOR(c_crqb_fifo_w-1 DOWNTO 0);
    --SIGNAL crqb_fifo_rd_data_sel_out : STD_LOGIC_VECTOR(c_crqb_fifo_w-1 DOWNTO 0);
    SIGNAL crqb_fifo_rd_sel : STD_LOGIC_VECTOR(g_noof_clnts+1 DOWNTO 1);
    SIGNAL mmrqs_start : STD_LOGIC;
    SIGNAL mmrqs_nregs : STD_LOGIC_VECTOR(c_gempro_nreg_w-1 DOWNTO 0);
    SIGNAL mmrqs_addr : STD_LOGIC_VECTOR(c_ram_addr_w-1 DOWNTO 0);
    SIGNAL mmrqs_rst : STD_LOGIC;
    SIGNAL mmre_start : STD_LOGIC;
    SIGNAL mmre_cmd : STD_LOGIC_VECTOR(c_gempro_cmd_w-1 DOWNTO 0);
    SIGNAL mmre_fc : STD_LOGIC_VECTOR(c_gempro_fc_w-1 DOWNTO 0);
    SIGNAL mmre_csn : STD_LOGIC_VECTOR(c_gempro_csn_w-1 DOWNTO 0);
    SIGNAL mmre_nregs : STD_LOGIC_VECTOR(c_gempro_nreg_w-1 DOWNTO 0);
    SIGNAL mmre_connect : STD_LOGIC;
    SIGNAL mmre_key : STD_LOGIC_VECTOR(c_key_w-1 DOWNTO 0);
    SIGNAL mmre_crsb_low_addr : STD_LOGIC_VECTOR(c_ram_addr_w-1 DOWNTO 0);
    SIGNAL mmre_crsb_high_addr : STD_LOGIC_VECTOR(c_ram_addr_w-1 DOWNTO 0);
    SIGNAL mmre_crsb_addr : STD_LOGIC_VECTOR(c_ram_addr_w-1 DOWNTO 0);
    SIGNAL mmre_complete : STD_LOGIC;
    SIGNAL mmre_rst : STD_LOGIC;
    SIGNAL crsb_fifo_wr_data : STD_LOGIC_VECTOR(c_crsb_fifo_w-1 DOWNTO 0);
    SIGNAL crsb_fifo_rd_data : STD_LOGIC_VECTOR(c_crsb_fifo_w-1 DOWNTO 0);
    SIGNAL crsb_fifo_wr : STD_LOGIC;
    SIGNAL crsb_fifo_rd : STD_LOGIC;
    SIGNAL crsb_fifo_full : STD_LOGIC;
    SIGNAL crsb_fifo_empty : STD_LOGIC;
    SIGNAL crsb_ram : t_data_arr(0 TO c_ram_len-1);
    SIGNAL crsb_wr : STD_LOGIC;
    SIGNAL crsb_wr_data : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    SIGNAL crsb_wr_addr : STD_LOGIC_VECTOR(c_ram_addr_w-1 DOWNTO 0);
    SIGNAL crsb_rd_data : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    SIGNAL crsb_rd_addr : STD_LOGIC_VECTOR(c_ram_addr_w-1 DOWNTO 0);
    SIGNAL clnt_addr_mac : STD_LOGIC_VECTOR(c_clnt_addr_w-1 DOWNTO 0);
    SIGNAL clnt_addr_ipudp : STD_LOGIC_VECTOR(c_clnt_addr_w-1 DOWNTO 0);
    SIGNAL s2mm_in : t_axi4_sosi;
    SIGNAL s2mm_cmd_in : t_axi4_sosi;
    SIGNAL mm2s_cmd_in : t_axi4_sosi;
    SIGNAL s2mm_sts_out : t_axi4_sosi;
    SIGNAL mm2s_sts_out : t_axi4_sosi;
    SIGNAL mm2s_out : t_axi4_sosi;
    SIGNAL s2mm_out : t_axi4_siso;
    SIGNAL mm2s_in : t_axi4_siso;
    SIGNAL mm2s_sts_in : t_axi4_siso;
    SIGNAL s2mm_sts_in : t_axi4_siso;
    SIGNAL mm2s_cmd_out : t_axi4_siso;
    SIGNAL s2mm_cmd_out : t_axi4_siso;
    SIGNAL mm2s_err : STD_LOGIC;
    SIGNAL mm2s_err_out : STD_LOGIC;
    SIGNAL s2mm_err : STD_LOGIC;
    SIGNAL s2mm_err_out : STD_LOGIC;
    SIGNAL ethrx_tdata : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    SIGNAL ethrx_tkeep : STD_LOGIC_VECTOR(g_data_w/8-1 DOWNTO 0);
    SIGNAL ethrx_tlast : STD_LOGIC;
    SIGNAL ethrx_tvalid : STD_LOGIC;
    SIGNAL ethrx_tready : STD_LOGIC;
    SIGNAL ethrx_tstrb : STD_LOGIC_VECTOR(g_data_w/8-1 DOWNTO 0);
    SIGNAL ethtx_tdata : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    SIGNAL ethtx_tkeep : STD_LOGIC_VECTOR(g_data_w/8-1 DOWNTO 0);
    SIGNAL ethtx_tlast : STD_LOGIC;
    SIGNAL ethtx_tready : STD_LOGIC;
    SIGNAL ethtx_tvalid : STD_LOGIC;
    SIGNAL ethtx_tstrb : STD_LOGIC_VECTOR(g_data_w/8-1 DOWNTO 0);
    signal mm_downstream_reset : std_logic;

BEGIN

    process(clk)
    begin
        if rising_edge(clk) then
            mm_reset_out <= mm_downstream_reset or rst; 
        end if;
    end process;
    
    ethrx_tvalid <= ethrx_in.tvalid;
    ethrx_tdata <= ethrx_in.tdata(g_data_w-1 DOWNTO 0);
    ethrx_tkeep <= ethrx_in.tkeep(g_data_w/8-1 DOWNTO 0);
    ethrx_tlast <= ethrx_in.tlast;
    ethrx_tstrb <= ethrx_in.tstrb(g_data_w/8-1 DOWNTO 0);
    ethrx_out.tready <= ethrx_tready;

    ethtx_tready <= ethtx_in.tready;
    ethtx_out.tdata(g_data_w-1 DOWNTO 0) <= ethtx_tdata;
    ethtx_out.tkeep(g_data_w/8-1 DOWNTO 0) <= ethtx_tkeep;
    ethtx_out.tlast <= ethtx_tlast;
    ethtx_out.tvalid <= ethtx_tvalid;
    ethtx_out.tstrb(g_data_w/8-1 DOWNTO 0) <= ethtx_tstrb;

    rstn <= NOT rst;

    -- AXI4 Datamover
   u_axi4dm : ENTITY tech_axi4dm_lib.tech_axi4dm
   GENERIC MAP (
      g_technology => g_technology )
   PORT MAP (
      mm2s_aclk => clk,
      mm2s_cmdsts_aclk => clk,
      s2mm_aclk => clk,
      s2mm_cmdsts_awclk => clk,
      mm2s_cmdsts_aresetn => rstn,
      s2mm_cmdsts_aresetn => rstn,

      -- AXI Interface
      mm_in => mm_in,
      mm_out => mm_out,

      -- AXI Write Path
      -- data from request_streamer
      s2mm_in      => s2mm_in,  -- .tdata, .tkeep, .tlast .tvalid, from request_streamer
      s2mm_out     => s2mm_out, -- .tready only, to request_streamer
      -- commands from mm_transaction_controller
      s2mm_cmd_in  => s2mm_cmd_in,  -- .tdata, .tvalid, from mm_transaction_controller
      s2mm_cmd_out => s2mm_cmd_out, -- .tready, to mm_transaction_controller
      -- status to mm_transaction_controller
      s2mm_sts_in  => s2mm_sts_in,
      s2mm_sts_out => s2mm_sts_out,
      s2mm_aresetn => s2mm_aresetn,
      s2mm_err     => s2mm_err,

      -- AXI Read Path
      mm2s_aresetn => mm2s_aresetn,
      mm2s_err     => mm2s_err,
      -- command from mm_transaction_controller
      mm2s_cmd_in  => mm2s_cmd_in,  -- .tdata, .tvalid, from mm_transaction_controller
      mm2s_cmd_out => mm2s_cmd_out, -- .tready, to mm_transaction_controller
      -- status to mm_transaction_controller
      mm2s_sts_in  => mm2s_sts_in,  -- .tready, from mm_transaction_controller
      mm2s_sts_out => mm2s_sts_out, -- .tdata, .tkeep, .tlast, .tvalid to mm_transaction_controller
      -- data returned to response_encoder
      mm2s_in      => mm2s_in,      -- .tready, from response_encoder
      mm2s_out     => mm2s_out      -- .tdata, .tvalid, .tlast to response_encoder
    );
    
    s2mm_in_dbg <= s2mm_in; -- : out t_axi4_sosi;  -- Sink in
    s2mm_out_dbg <= s2mm_out; -- : out t_axi4_siso; -- Sink out
    -- AXI4S Sink: S2MM Command
    s2mm_cmd_in_dbg <= s2mm_cmd_in; -- : out t_axi4_sosi; -- Sink in
    s2mm_cmd_out_dbg <= s2mm_cmd_out; -- : OUT t_axi4_siso; -- Sink out
    -- AXI4S Source: M_AXIS_S2MM_STS
    s2mm_sts_in_dbg <= s2mm_sts_in; -- : out t_axi4_siso;  -- Source in
    s2mm_sts_out_dbg <= s2mm_sts_out; 
    
    
    -- Request Decoder
    u_request_decoder : ENTITY gemini_server_lib.request_decoder
    GENERIC MAP (
        g_data_w => g_data_w,
        g_noof_clnts => g_noof_clnts,
        g_max_nregs => c_max_nregs,
        g_key_w => c_key_w,
        g_tod_w => g_tod_w,
        g_crqb_len => c_ram_len,
        g_crqb_addr_w => c_ram_addr_w,
        g_crqb_fifo_w => c_crqb_fifo_w,
        g_min_recycle_secs => g_min_recycle_secs )
    PORT MAP (
        clk => clk,
        rst => rst,
        ethrx_tvalid_in => ethrx_tvalid,
        ethrx_tready_out => ethrx_tready,
        ethrx_tdata_in => ethrx_tdata,
        ethrx_tstrb_in => ethrx_tstrb,
        ethrx_tkeep_in => ethrx_tkeep,
        ethrx_tlast_in => ethrx_tlast,
        crqb_wr_out => crqb_wr,
        crqb_addr_out => crqb_wr_addr,
        crqb_data_out => crqb_wr_data,
        crqb_fifo_wr_out => crqb_fifo_wr,
        crqb_fifo_full_in => crqb_fifo_full,
        crqb_fifo_data_out => crqb_fifo_wr_data,
        tod_in => tod_in,
        -- status signals to send to the register interface
        client0IP => client0IP,             -- out std_logic_vector(31 downto 0);
        client0Port => client0Port,         -- out std_logic_vector(15 downto 0);
        client0LastUsed => client0LastUsed, -- out std_logic_vector(g_tod_w-1 downto 0);
        client1IP => client1IP,             -- out std_logic_vector(31 downto 0);
        client1Port => client1Port,         -- out std_logic_vector(15 downto 0);
        client1LastUsed => client1LastUsed, -- out std_logic_vector(g_tod_w-1 downto 0);
        client2IP  => client2IP,            -- out std_logic_vector(31 downto 0);
        client2Port => client2Port,         -- out std_logic_vector(15 downto 0);
        client2LastUsed  => client2LastUsed,-- out std_logic_vector(g_tod_w-1 downto 0)
        state_out => rq_state               -- out std_logic_vector(3 downto 0);
    );

    -- Client Request Buffer RAM
    -- Infer simple dual-port RAM with single clock
    -- Assume 1 clock read latency
    p_crqb_ram : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF crqb_wr = '1' THEN
                crqb_ram(TO_INTEGER(UNSIGNED(crqb_wr_addr))) <= crqb_wr_data;
            END IF;
            crqb_rd_data <= crqb_ram(TO_INTEGER(UNSIGNED(crqb_rd_addr)));
        END IF;
    END PROCESS;

    -- Client Request Buffer FIFOs
    -- One FIFO per client. Each FIFO stores a single word per TF frame
    -- Plus one extra FIFO for unconnected clients
    gen_crqb_fifo : FOR B IN 1 TO g_noof_clnts+1 GENERATE

        u_crqb_fifo : ENTITY common_lib.common_fifo_sc
        GENERIC MAP (
            g_technology=> g_technology,
            g_dat_w     => c_crqb_fifo_w,
            g_nof_words => c_crqb_fifo_len,
            g_prog_full_thresh => g_max_pipeline,
            g_fifo_latency => 0 )
        PORT MAP (
            rst => rst,
            clk => clk,
            wr_dat => crqb_fifo_wr_data,
            wr_req => crqb_fifo_wr(B),
            wr_prog_ful => crqb_fifo_full(B),
            rd_dat => crqb_fifo_rd_data(B),
            rd_req => crqb_fifo_rd(B),
            rd_emp => crqb_fifo_empty(B) );

    END GENERATE;

    gen_crqb_fifo_rd_data_sel_3 : IF g_noof_clnts = 3 GENERATE

        crqb_fifo_rd_data_sel <= crqb_fifo_rd_data(1) WHEN crqb_fifo_rd_sel(1) = '1'
                                    ELSE crqb_fifo_rd_data(2) WHEN crqb_fifo_rd_sel(2) = '1'
                                    ELSE crqb_fifo_rd_data(3) WHEN crqb_fifo_rd_sel(3) = '1'
                                    ELSE crqb_fifo_rd_data(4);

        crsb_fifo_empty_sel <= crqb_fifo_empty(1) WHEN crqb_fifo_rd_sel(1) = '1'
                                ELSE crqb_fifo_empty(2) WHEN crqb_fifo_rd_sel(2) = '1'
                                ELSE crqb_fifo_empty(3) WHEN crqb_fifo_rd_sel(3) = '1'
                                ELSE crqb_fifo_empty(4);
    END GENERATE;

    gen_crqb_fifo_rd_data_sel_2 : IF g_noof_clnts = 2 GENERATE

        crqb_fifo_rd_data_sel <= crqb_fifo_rd_data(1) WHEN crqb_fifo_rd_sel(1) = '1'
                                    ELSE crqb_fifo_rd_data(2) WHEN crqb_fifo_rd_sel(2) = '1'
                                    ELSE crqb_fifo_rd_data(3);

        crsb_fifo_empty_sel <= crqb_fifo_empty(1) WHEN crqb_fifo_rd_sel(1) = '1'
                                ELSE crqb_fifo_empty(2) WHEN crqb_fifo_rd_sel(2) = '1'
                                ELSE crqb_fifo_empty(3);
    END GENERATE;

    gen_crqb_fifo_rd_data_sel_1 : IF g_noof_clnts = 1 GENERATE

        crqb_fifo_rd_data_sel <= crqb_fifo_rd_data(1) WHEN crqb_fifo_rd_sel(1) = '1'
                                    ELSE crqb_fifo_rd_data(2);

        crsb_fifo_empty_sel <= crqb_fifo_empty(1) WHEN crqb_fifo_rd_sel(1) = '1'
                                ELSE crqb_fifo_empty(2);
    END GENERATE;

    -- MM Transaction Controller
    u_mm_transaction_controller : ENTITY gemini_server_lib.mm_transaction_controller
    GENERIC MAP (
      g_noof_clnts => g_noof_clnts,
      g_max_pipeline => g_max_pipeline,
      g_crsb_npart_len => c_npart_len,
      g_crsb_cpart_len => c_cpart_len,
      g_key_w => c_key_w,
      g_crqb_fifo_w => c_crqb_fifo_w,
      g_crqb_addr_w => c_ram_addr_w,
      g_crsb_addr_w => c_ram_addr_w,
      g_crsb_fifo_w => c_crsb_fifo_w,
      g_txfr_timeout => g_txfr_timeout )
    PORT MAP (
      clk => clk,
      rst => rst,
      s2mm_aresetn_out => s2mm_aresetn,
      mm2s_aresetn_out => mm2s_aresetn,
      -- reset to downstream modules on the mm bus, to prevent lockup from broken transactions issued by the datamover when it is reset.
      mm_reset_out => mm_downstream_reset,
      crqb_data_in => crqb_fifo_rd_data_sel,
      crqb_rd_out => crqb_fifo_rd,
      crqb_sel_out => crqb_fifo_rd_sel,
      crqb_empty_in => crsb_fifo_empty_sel,
      rqs_start_out => mmrqs_start,
      rqs_nregs_out => mmrqs_nregs,
      rqs_addr_out => mmrqs_addr,
      rqs_rst_out => mmrqs_rst,
      re_start_out => mmre_start,
      re_csn_out => mmre_csn,
      re_cmd_out => mmre_cmd,
      re_fc_out => mmre_fc,
      re_nregs_out => mmre_nregs,
      re_connect_out => mmre_connect,
      re_key_out => mmre_key,
      re_crsb_addr_out => mmre_crsb_addr,
      re_crsb_low_addr_out => mmre_crsb_low_addr,
      re_crsb_high_addr_out => mmre_crsb_high_addr,
      re_complete_out => mmre_complete,
      re_rst_out => mmre_rst,
      crsb_fifo_wr_out => crsb_fifo_wr,
      crsb_fifo_full_in => crsb_fifo_full,
      crsb_fifo_data_out => crsb_fifo_wr_data,
      s2mm_sts_tdata_in  => s2mm_sts_out.tdata(c_axi4dm_sts_w-1 DOWNTO 0),
      s2mm_sts_tkeep_in  => s2mm_sts_out.tkeep(c_axi4dm_sts_w/8-1 DOWNTO 0),
      s2mm_sts_tlast_in  => s2mm_sts_out.tlast,
      s2mm_sts_tready_out => s2mm_sts_in.tready,
      s2mm_sts_tvalid_in => s2mm_sts_out.tvalid,
      s2mm_cmd_tdata_out  => s2mm_cmd_in.tdata(c_axi4dm_cmd_w-1 DOWNTO 0),
      s2mm_cmd_tready_in => s2mm_cmd_out.tready,
      s2mm_cmd_tvalid_out => s2mm_cmd_in.tvalid,
      s2mm_err_in => s2mm_err,
      s2mm_err_out => s2mm_err_out,
      mm2s_sts_tdata_in  => mm2s_sts_out.tdata(c_axi4dm_sts_w-1 DOWNTO 0),
      mm2s_sts_tkeep_in  => mm2s_sts_out.tkeep(c_axi4dm_sts_w/8-1 DOWNTO 0),
      mm2s_sts_tlast_in  => mm2s_sts_out.tlast,
      mm2s_sts_tready_out => mm2s_sts_in.tready,
      mm2s_sts_tvalid_in => mm2s_sts_out.tvalid,
      mm2s_cmd_tdata_out    => mm2s_cmd_in.tdata(c_axi4dm_cmd_w-1 DOWNTO 0),
      mm2s_cmd_tready_in    => mm2s_cmd_out.tready,
      mm2s_cmd_tvalid_out   => mm2s_cmd_in.tvalid,
      mm2s_err_in           => mm2s_err,
      mm2s_err_out          => mm2s_err_out,
      -- debug
      req_csrb_state   => req_csrb_state,  -- out std_logic_vector(2 downto 0);
      req_main_state   => req_main_state,  -- out std_logic_vector(3 downto 0);
      replay_state     => replay_state,    -- out std_logic_vector(3 downto 0);
      completion_state => completion_state, -- out std_logic_vector(3 downto 0) 
      dbg_timer_expire => dbg_timer_expire, -- out std_logic;
      dbg_timer => dbg_timer -- : out std_logic_vector(15 downto 0)
    );

    -- Request Streamer
    u_request_streamer : ENTITY gemini_server_lib.request_streamer
    GENERIC MAP (
        g_technology => g_technology,
        g_crqbaddr_w => c_ram_addr_w,
        g_crqb_len => c_ram_len,
        g_nregs_w => c_gempro_nreg_w,
        g_clnt_addr_w => c_clnt_addr_w,
        g_data_w => g_data_w,
        g_mm_data_w => g_mm_data_w,
        g_crqb_ram_rd_latency => 1 )
    PORT MAP (
        clk => clk,
        rst => mmrqs_rst,
        mm_start_in => mmrqs_start,
        mm_nregs_in => mmrqs_nregs,
        mm_crqbaddr_in => mmrqs_addr,
        crqb_data_in => crqb_rd_data,
        crqb_addr_out => crqb_rd_addr,
        clnt_addr_mac_out => clnt_addr_mac,
        clnt_addr_ipudp_out => clnt_addr_ipudp,
        s2mm_tdata_out  => s2mm_in.tdata(c_axi4dm_sda_w-1 DOWNTO 0),
        s2mm_tkeep_out  => s2mm_in.tkeep(c_axi4dm_sda_w/8-1 DOWNTO 0),
        s2mm_tlast_out  => s2mm_in.tlast,
        s2mm_tready_in => s2mm_out.tready,
        s2mm_tvalid_out => s2mm_in.tvalid,
        -- debug
        state_out => rq_stream_state
    );

    -- Response Encoder
    u_response_encoder : ENTITY gemini_server_lib.response_encoder
    GENERIC MAP (
        g_max_nregs => c_max_nregs,
        g_key_w => c_key_w,
        g_max_pipeline => g_max_pipeline,
        g_data_w => g_data_w,
        g_mm_data_w => g_mm_data_w,
        g_clnt_addr_w => c_clnt_addr_w,
        g_crsb_addr_w => c_ram_addr_w )
    PORT MAP (
        clk => clk,
        rst => mmre_rst,
        mm_start_in => mmre_start,
        mm_cmd_in => mmre_cmd,
        mm_fc_in => mmre_fc,
        mm_csn_in => mmre_csn,
        mm_nregs_in => mmre_nregs,
        mm_connect_in => mmre_connect,
        mm_key_in => mmre_key,
        mm_crsb_addr_in => mmre_crsb_addr,
        mm_crsb_low_addr_in => mmre_crsb_low_addr,
        mm_crsb_high_addr_in => mmre_crsb_high_addr,
        mm_complete_in => mmre_complete,
        crsb_data_out => crsb_wr_data,
        crsb_wr_out => crsb_wr,
        crsb_addr_out => crsb_wr_addr,
        clnt_addr_mac_in => clnt_addr_mac,
        clnt_addr_ipudp_in => clnt_addr_ipudp,
        mm2s_error      => mm2s_err_out,
        mm2s_tdata_in   => mm2s_out.tdata(c_axi4dm_sda_w-1 DOWNTO 0),
        mm2s_tkeep_in   => mm2s_out.tkeep(c_axi4dm_sda_w/8-1 DOWNTO 0),
        mm2s_tlast_in   => mm2s_out.tlast,
        mm2s_tready_out => mm2s_in.tready,
        mm2s_tvalid_in  => mm2s_out.tvalid,
        state_out       => resp_state
    );

    -- Client Response Buffer RAM
    -- Infer simple dual-port RAM with single clock
    -- Assume 1 clock read latency
    p_crsb_ram : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF crsb_wr = '1' THEN
                crsb_ram(TO_INTEGER(UNSIGNED(crsb_wr_addr))) <= crsb_wr_data;
            END IF;
            crsb_rd_data <= crsb_ram(TO_INTEGER(UNSIGNED(crsb_rd_addr)));
            
            crqb_fifo_rd_data_sel_out <= crqb_fifo_rd_data_sel;
            crqb_fifo_rd_out(0) <= crqb_fifo_rd(1);
            crqb_fifo_rd_out(1) <= crqb_fifo_rd(2);
            crqb_fifo_rd_out(2) <= crqb_fifo_rd(3);
            
        END IF;
    END PROCESS;

    -- Client Respone Buffer FIFO
    u_crsb_fifo : ENTITY common_lib.common_fifo_sc
    GENERIC MAP (
        g_technology=> g_technology,
        g_dat_w     => c_crsb_fifo_w,
        g_nof_words => c_crsb_fifo_len,
        g_fifo_latency => 0 )
    PORT MAP (
        rst      => rst,
        clk      => clk,
        wr_dat   => crsb_fifo_wr_data,
        wr_req   => crsb_fifo_wr,
        wr_ful   => crsb_fifo_full,
        rd_dat   => crsb_fifo_rd_data,
        rd_req   => crsb_fifo_rd,
        rd_emp   => crsb_fifo_empty );

    -- Response Streamer
    u_response_streamer : ENTITY gemini_server_lib.response_streamer
    GENERIC MAP (
        g_technology => g_technology,
        g_data_w => g_data_w,
        g_crsb_addr_w => c_ram_addr_w,
        g_crsb_fifo_w => c_crsb_fifo_w,
        g_crsb_ram_rd_latency => 1 )
    PORT MAP (
        clk => clk,
        rst => rst,
        ethtx_tvalid_out => ethtx_tvalid,
        ethtx_tready_in => ethtx_tready,
        ethtx_tdata_out => ethtx_tdata,
        ethtx_tstrb_out => ethtx_tstrb,
        ethtx_tkeep_out => ethtx_tkeep,
        ethtx_tlast_out => ethtx_tlast,
        crsb_fifo_data_in => crsb_fifo_rd_data,
        crsb_fifo_rd_out => crsb_fifo_rd,
        crsb_fifo_empty_in => crsb_fifo_empty,
        crsb_data_in => crsb_rd_data,
        crsb_addr_out => crsb_rd_addr );

END rtl;
