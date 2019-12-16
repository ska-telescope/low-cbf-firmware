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

-- Purpose: MM Transaction Controller
--
-- Description: This module is responsible for the following:
--              1) Syncronising the request and completion processes
--              2) Connection Table (RAM & ROM)
--
-- Remarks:
--

LIBRARY IEEE, common_lib, gemini_server_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE gemini_server_lib.gemini_server_pkg.ALL;

ENTITY mm_transaction_controller IS
   GENERIC (
      g_key_w : NATURAL;
      g_max_pipeline : NATURAL;
      g_noof_clnts : NATURAL := 3; -- Maximum number of supported clients
      g_crsb_npart_len : NATURAL; -- Length of CRB unconnected client partition (in 64bit words)
      g_crsb_cpart_len : NATURAL; -- Length of single client CRB partition (in 64it words)
      g_crqb_fifo_w : NATURAL;
      g_crqb_addr_w : NATURAL;  -- Width of client address indentifier (must be >= 48 bits)
      g_crsb_addr_w : NATURAL; -- Width of Client Response Buffer address
      g_crsb_fifo_w : NATURAL;
      g_txfr_timeout : NATURAL  -- AXI transaction aborted if it takes longer than nregs + g_txfr_timeout
   );
   PORT (
      clk                  : IN STD_LOGIC;
      rst                  : IN STD_LOGIC;

      s2mm_aresetn_out     : OUT STD_LOGIC;
      s2mm_err_out         : OUT STD_LOGIC;
      mm2s_aresetn_out     : OUT STD_LOGIC;
      mm2s_err_out         : OUT STD_LOGIC;
      -- reset to downstream modules on the mm bus, to prevent lockup from broken transactions issued by the datamover when it is reset.
      mm_reset_out         : out std_logic;
      
      -- Interface: CRQB FIFOs
      crqb_data_in         : IN STD_LOGIC_VECTOR(g_crqb_fifo_w-1 DOWNTO 0);
      crqb_rd_out          : OUT STD_LOGIC_VECTOR(g_noof_clnts+1 DOWNTO 1);
      crqb_sel_out         : OUT STD_LOGIC_VECTOR(g_noof_clnts+1 DOWNTO 1);
      crqb_empty_in        : IN STD_LOGIC;

      -- Interface: Request Streamer
      rqs_start_out        : OUT STD_LOGIC;
      rqs_nregs_out        : OUT STD_LOGIC_VECTOR(c_gempro_nreg_w-1 DOWNTO 0);
      rqs_addr_out         : OUT STD_LOGIC_VECTOR(g_crqb_addr_w-1 DOWNTO 0);
      rqs_rst_out          : OUT STD_LOGIC;

      -- Interface: Response Encoder (Start phase)
      re_start_out         : OUT STD_LOGIC;
      re_csn_out           : OUT STD_LOGIC_VECTOR(c_gempro_csn_w-1 DOWNTO 0);
      re_nregs_out         : OUT STD_LOGIC_VECTOR(c_gempro_nreg_w-1 DOWNTO 0);
      re_connect_out       : OUT STD_LOGIC;
      re_key_out           : OUT STD_LOGIC_VECTOR(g_key_w-1 DOWNTO 0);
      re_crsb_addr_out     : OUT STD_LOGIC_VECTOR(g_crsb_addr_w-1 DOWNTO 0);
      re_crsb_low_addr_out : OUT STD_LOGIC_VECTOR(g_crsb_addr_w-1 DOWNTO 0);
      re_crsb_high_addr_out : OUT STD_LOGIC_VECTOR(g_crsb_addr_w-1 DOWNTO 0);

      -- Interface: Response Encoder (Complete phase)
      re_complete_out      : OUT STD_LOGIC;
      re_cmd_out           : OUT STD_LOGIC_VECTOR(c_gempro_cmd_w-1 DOWNTO 0);
      re_fc_out            : OUT STD_LOGIC_VECTOR(c_gempro_fc_w-1 DOWNTO 0);
      re_rst_out           : OUT STD_LOGIC;

      -- Interface: S2MM command and status
      s2mm_sts_tdata_in    : IN STD_LOGIC_VECTOR ( 7 DOWNTO 0 );
      s2mm_sts_tkeep_in    : IN STD_LOGIC_VECTOR ( 0 TO 0 );
      s2mm_sts_tlast_in    : IN STD_LOGIC;
      s2mm_sts_tready_out  : OUT STD_LOGIC;
      s2mm_sts_tvalid_in   : IN STD_LOGIC;
      s2mm_cmd_tdata_out   : OUT STD_LOGIC_VECTOR ( 71 DOWNTO 0 );
      s2mm_cmd_tready_in   : IN STD_LOGIC;
      s2mm_cmd_tvalid_out  : OUT STD_LOGIC;
      s2mm_err_in          : IN STD_LOGIC;


      -- Interface: MM2S command and status
      mm2s_sts_tdata_in    : IN STD_LOGIC_VECTOR ( 7 DOWNTO 0 );
      mm2s_sts_tkeep_in    : IN STD_LOGIC_VECTOR ( 0 TO 0 );
      mm2s_sts_tlast_in    : IN STD_LOGIC;
      mm2s_sts_tready_out  : OUT STD_LOGIC;
      mm2s_sts_tvalid_in   : IN STD_LOGIC;
      mm2s_cmd_tdata_out   : OUT STD_LOGIC_VECTOR ( 71 DOWNTO 0 );
      mm2s_cmd_tready_in   : IN STD_LOGIC;
      mm2s_cmd_tvalid_out  : OUT STD_LOGIC;
      mm2s_err_in          : IN STD_LOGIC;

      -- Interface: CRSB FIFO
      crsb_fifo_wr_out     : OUT STD_LOGIC;
      crsb_fifo_full_in    : IN STD_LOGIC;
      crsb_fifo_data_out   : OUT STD_LOGIC_VECTOR(g_crsb_fifo_w-1 DOWNTO 0);
      
      -- debug
      req_csrb_state   : out std_logic_vector(2 downto 0);
      req_main_state   : out std_logic_vector(3 downto 0);
      replay_state     : out std_logic_vector(3 downto 0);
      completion_state : out std_logic_vector(3 downto 0);
      dbg_timer_expire : out std_logic;
      dbg_timer : out std_logic_vector(15 downto 0)
   );
END mm_transaction_controller;

ARCHITECTURE rtl of mm_transaction_controller IS

    CONSTANT c_crsb_npart_start_addr : NATURAL := g_noof_clnts * g_crsb_cpart_len;
    CONSTANT c_crsb_npart_end_addr : NATURAL := g_noof_clnts * g_crsb_cpart_len + g_crsb_npart_len - 1;
    CONSTANT c_ctram_w : NATURAL := g_crsb_addr_w + c_gempro_ssn_w; -- Space for CRSBClntAddr and SSN
    CONSTANT c_ctrom_w : NATURAL := 2 * g_crsb_addr_w; -- Space for CRSB RAM partition limit addresses

    TYPE t_ctram_arr IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR(c_ctram_w-1 DOWNTO 0);
    TYPE t_ctrom_arr IS ARRAY (NATURAL RANGE <>) OF UNSIGNED(c_ctrom_w-1 DOWNTO 0);

    SIGNAL ctram_mem : t_ctram_arr(0 TO g_noof_clnts-1);
    SIGNAL ct_wr : STD_LOGIC;
    SIGNAL ct_addr : STD_LOGIC_VECTOR(g_key_w-1 DOWNTO 0);
    SIGNAL ct_wr_data : STD_LOGIC_VECTOR(c_ctram_w-1 DOWNTO 0);
    SIGNAL ct_rd_data : STD_LOGIC_VECTOR(c_ctrom_w+c_ctram_w-1 DOWNTO 0);
    SIGNAL rt_key : STD_LOGIC_VECTOR(g_key_w-1 DOWNTO 0);
    SIGNAL rt_csn : STD_LOGIC_VECTOR(c_gempro_csn_w-1 DOWNTO 0);
    SIGNAL rt_lookup : STD_LOGIC;
    SIGNAL rt_complete : STD_LOGIC;
    SIGNAL rt_connect : STD_LOGIC;
    SIGNAL rt_valid : STD_LOGIC;
    SIGNAL rt_dout : STD_LOGIC_VECTOR(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL rt_din : STD_LOGIC_VECTOR(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL rt_wr : STD_LOGIC;
    SIGNAL mm_enable : STD_LOGIC;
    SIGNAL txfr_timer : UNSIGNED(c_gempro_nreg_w-1 DOWNTO 0);
    SIGNAL txfr_timeout : STD_LOGIC_VECTOR(c_gempro_nreg_w-1 DOWNTO 0);
    SIGNAL txfr_busy : STD_LOGIC;
    SIGNAL txfr_start : STD_LOGIC;
    SIGNAL txfr_complete : STD_LOGIC;
    SIGNAL txfr_timer_expiry : STD_LOGIC;
    SIGNAL cmd1 : STD_LOGIC_VECTOR(c_mmcmd_w-1 DOWNTO 0);
    SIGNAL cmd2 : STD_LOGIC_VECTOR(c_mmcmd_w-1 DOWNTO 0);
    SIGNAL crsb_ctrl : STD_LOGIC_VECTOR(g_crsb_fifo_w-1 DOWNTO 0);

BEGIN

    -- Generate the Connection Table ROM which contains CRSB RAM partition start and end addresses
    gen_ctrom_mem_3 : IF g_noof_clnts = 3 GENERATE
        SIGNAL ctrom_mem : t_ctrom_arr(0 TO g_noof_clnts-1) := (
                    TO_UNSIGNED(0,g_crsb_addr_w) & TO_UNSIGNED(g_crsb_cpart_len-1,g_crsb_addr_w),
                    TO_UNSIGNED(g_crsb_cpart_len,g_crsb_addr_w) & TO_UNSIGNED(2*g_crsb_cpart_len-1,g_crsb_addr_w),
                    TO_UNSIGNED(2*g_crsb_cpart_len,g_crsb_addr_w) & TO_UNSIGNED(3*g_crsb_cpart_len-1,g_crsb_addr_w) );
    BEGIN
        ct_rd_data(c_ctrom_w+c_ctram_w-1 DOWNTO c_ctram_w) <= STD_LOGIC_VECTOR(ctrom_mem(TO_INTEGER(UNSIGNED(ct_addr))));
    END GENERATE;

    gen_ctrom_mem_2 : IF g_noof_clnts = 2 GENERATE
        SIGNAL ctrom_mem : t_ctrom_arr(0 TO g_noof_clnts-1) := (
                    TO_UNSIGNED(0,g_crsb_addr_w) & TO_UNSIGNED(g_crsb_cpart_len-1,g_crsb_addr_w),
                    TO_UNSIGNED(g_crsb_cpart_len,g_crsb_addr_w) & TO_UNSIGNED(2*g_crsb_cpart_len-1,g_crsb_addr_w) );
    BEGIN
        ct_rd_data(c_ctrom_w+c_ctram_w-1 DOWNTO c_ctram_w) <= STD_LOGIC_VECTOR(ctrom_mem(TO_INTEGER(UNSIGNED(ct_addr))));
    END GENERATE;

    gen_ctrom_mem_1 : IF g_noof_clnts = 1 GENERATE
        CONSTANT ctrom_mem : UNSIGNED(c_ctrom_w-1 DOWNTO 0) :=
                    TO_UNSIGNED(0,g_crsb_addr_w) & TO_UNSIGNED(g_crsb_cpart_len-1,g_crsb_addr_w);
    BEGIN
        ct_rd_data(c_ctrom_w+c_ctram_w-1 DOWNTO c_ctram_w) <= STD_LOGIC_VECTOR(ctrom_mem);
    END GENERATE;

    -- Infer distributed RAM for the Connection Table
    p_ctram_mem : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF ct_wr = '1' THEN
                ctram_mem(TO_INTEGER(UNSIGNED(ct_addr))) <= ct_wr_data;
            END IF;
        END IF;
    END PROCESS;

    -- Assume 0 clock read latency from CT RAM and ROM
    ct_rd_data(c_ctram_w-1 DOWNTO 0) <= ctram_mem(TO_INTEGER(UNSIGNED(ct_addr)));

    u_mm_request_controller : ENTITY gemini_server_lib.mm_request_controller
    GENERIC MAP (
        g_key_w          => g_key_w,
        g_noof_clnts     => g_noof_clnts,
        g_crsb_npart_len => g_crsb_npart_len,
        g_crsb_cpart_len => g_crsb_cpart_len,
        g_crqb_fifo_w    => g_crqb_fifo_w,
        g_crqb_addr_w    => g_crqb_addr_w,
        g_crsb_addr_w    => g_crsb_addr_w,
        g_crsb_fifo_w    => g_crsb_fifo_w,
        g_crsb_npart_start_addr => c_crsb_npart_start_addr,
        g_crsb_npart_end_addr => c_crsb_npart_end_addr,
        g_txfr_timeout => g_txfr_timeout )
    PORT MAP (
        clk  => clk,
        rst => rst,
        mm_enable_in => mm_enable,
        mm_txfr_busy_in    => txfr_busy,
        mm_txfr_start_out  => txfr_start,
        mm_txfr_timeout_out => txfr_timeout,
        mm_crsb_ctrl_out  => crsb_ctrl,
        mm_cmd_out    => cmd1,
        ct_wr_out       => ct_wr,
        ct_addr_out     => ct_addr,
        ct_wr_data_out  => ct_wr_data,
        ct_rd_data_in   => ct_rd_data,
        rt_key_out      => rt_key,
        rt_csn_out      => rt_csn,
        rt_lookup_out   => rt_lookup,
        rt_connect_out  => rt_connect,
        rt_complete_in  => rt_complete,
        rt_valid_in     => rt_valid,
        rt_dout_in      => rt_dout,
        rt_din_out      => rt_din,
        rt_wr_out       => rt_wr,
        crqb_data_in  => crqb_data_in,
        crqb_rd_out   => crqb_rd_out,
        crqb_sel_out  => crqb_sel_out,
        crqb_empty_in => crqb_empty_in,
        rqs_start_out => rqs_start_out,
        rqs_nregs_out => rqs_nregs_out,
        rqs_addr_out  => rqs_addr_out,
        re_start_out          => re_start_out,
        re_csn_out            => re_csn_out,
        re_nregs_out          => re_nregs_out,
        re_connect_out        => re_connect_out,
        re_key_out            => re_key_out,
        re_crsb_addr_out      => re_crsb_addr_out,
        re_crsb_low_addr_out  => re_crsb_low_addr_out,
        re_crsb_high_addr_out => re_crsb_high_addr_out,
        s2mm_cmd_tdata_out  => s2mm_cmd_tdata_out,
        s2mm_cmd_tready_in  => s2mm_cmd_tready_in,
        s2mm_cmd_tvalid_out => s2mm_cmd_tvalid_out,
        mm2s_cmd_tdata_out  => mm2s_cmd_tdata_out,
        mm2s_cmd_tready_in  => mm2s_cmd_tready_in,
        mm2s_cmd_tvalid_out => mm2s_cmd_tvalid_out,
        mm2s_err_in         => mm2s_err_in,
        -- Debug
        crsb_state_out => req_csrb_state, -- out std_logic_vector(2 downto 0);
        main_state_out => req_main_state  -- out std_logic_vector(3 downto 0) 
    );

    -- Synchronize Request/Completion processes
    -- Guarantee that complete process always follows request process
    -- Output CRSB FIFO control word after completion
    p_sync : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF rst = '1' THEN
                txfr_busy <= '0';
                txfr_timer_expiry <= '0';
                crsb_fifo_wr_out <= '0';
                rqs_rst_out <= '1';
                re_rst_out <= '1';
            ELSE

                crsb_fifo_wr_out <= '0';
                txfr_timer_expiry <= '0';
                rqs_rst_out <= '0';
                re_rst_out <= '0';

                IF txfr_busy = '1' THEN
                    txfr_timer <= txfr_timer - TO_UNSIGNED(1,txfr_timer'length);
                END IF;

                IF txfr_busy = '0' AND txfr_start = '1' THEN
                    txfr_busy <= '1';
                    txfr_timer_expiry <= '0';
                    txfr_timer <= UNSIGNED(txfr_timeout);
                    crsb_fifo_data_out <= crsb_ctrl;
                    cmd2 <= cmd1;
                ELSIF txfr_busy = '1' AND txfr_complete = '1' THEN
                    txfr_busy <= '0';
                    crsb_fifo_wr_out <= '1';
                END IF;

                IF txfr_timer = TO_UNSIGNED(0,txfr_timer'length) THEN
                    txfr_timer_expiry <= '1';
                END IF;

             END IF;
             
             dbg_timer_expire <= txfr_timer_expiry;
             dbg_timer <= std_logic_vector(txfr_timer);
             
        END IF;
    END PROCESS;

    -- Stop performing MM transactions if there's no space left in the CRSB FIFO for results
    mm_enable <= '1' WHEN crsb_fifo_full_in = '0' ELSE '0';

    u_mm_completion_controller : ENTITY gemini_server_lib.mm_completion_controller
    PORT MAP (
      clk  => clk,
      rst => rst,
      s2mm_aresetn_out     => s2mm_aresetn_out,
      mm2s_aresetn_out     => mm2s_aresetn_out,
      mm2s_err_out         => mm2s_err_out,
      s2mm_err_out         => s2mm_err_out,
      -- reset to downstream modules on the mm bus, to prevent lockup from broken transactions issued by the datamover when it is reset.
      mm_reset_out         => mm_reset_out,
      mm_txfr_busy_in      => txfr_busy,
      mm_txfr_complete_out => txfr_complete,
      mm_txfr_timer_expiry_in => txfr_timer_expiry,
      mm_cmd_in            => cmd2,
      re_complete_out      => re_complete_out,
      re_cmd_out           => re_cmd_out,
      re_fc_out            => re_fc_out,
      s2mm_sts_tdata_in    => s2mm_sts_tdata_in,
      s2mm_sts_tkeep_in    => s2mm_sts_tkeep_in,
      s2mm_sts_tlast_in    => s2mm_sts_tlast_in,
      s2mm_sts_tready_out  => s2mm_sts_tready_out,
      s2mm_sts_tvalid_in   => s2mm_sts_tvalid_in,
      s2mm_err_in          => s2mm_err_in,
      mm2s_sts_tdata_in    => mm2s_sts_tdata_in,
      mm2s_sts_tkeep_in    => mm2s_sts_tkeep_in,
      mm2s_sts_tlast_in    => mm2s_sts_tlast_in,
      mm2s_sts_tready_out  => mm2s_sts_tready_out,
      mm2s_sts_tvalid_in   => mm2s_sts_tvalid_in,
      mm2s_err_in          => mm2s_err_in,
      -- debug
      state_out => completion_state    --  out std_logic_vector(3 downto 0) 
    );

    u_replay_table : ENTITY gemini_server_lib.replay_table
    GENERIC MAP (
        g_key_w => g_key_w,
        g_csn_w => c_gempro_csn_w,
        g_max_pipeline => g_max_pipeline,
        g_noof_clnts => g_noof_clnts,
        g_data_w => g_crsb_addr_w )
    PORT MAP (
        clk => clk,
        rst => rst,
        key_in => rt_key,
        csn_in => rt_csn,
        clnt_rst => rt_connect,
        lookup_in => rt_lookup,
        complete_out => rt_complete,
        valid_out => rt_valid,
        data_out => rt_dout,
        wr_in => rt_wr,
        wr_data_in => rt_din,
        -- debug
        state_out => replay_state  -- out std_logic_vector(3 downto 0) 
    );

END rtl;
