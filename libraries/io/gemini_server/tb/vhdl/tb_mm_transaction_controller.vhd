-------------------------------------------------------------------------------
--
-- Copyright (C) 2017
-- CSIRO 
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


-- Purpose: Testbench for MM Transaction Controller module
-- Description:
--

LIBRARY IEEE, gemini_server_lib, common_lib, technology_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_textio.ALL;
USE common_lib.common_pkg.ALL;
USE gemini_server_lib.gemini_server_pkg.ALL;

LIBRARY STD;
USE STD.textio.ALL;

ENTITY tb_mm_transaction_controller IS
END tb_mm_transaction_controller;

ARCHITECTURE tb OF tb_mm_transaction_controller IS

    CONSTANT c_clk_period : TIME := 10 ns;
    CONSTANT c_key_w : NATURAL := 2;
    CONSTANT c_max_pipeline : NATURAL := 2;
    CONSTANT c_noof_clnts : NATURAL := 3;
    CONSTANT c_crsb_npart_len : NATURAL := 21;
    CONSTANT c_crsb_cpart_len : NATURAL := 21;
    CONSTANT c_crqb_fifo_w : NATURAL := 88;
    CONSTANT c_crsb_fifo_w : NATURAL := 80;
    CONSTANT c_crqb_addr_w : NATURAL := 18;
    CONSTANT c_crsb_addr_w : NATURAL := 18;

    TYPE t_test IS RECORD
        -- Inputs
        mmcmd : STD_LOGIC_VECTOR(c_mmcmd_w-1 DOWNTO 0);
        client : NATURAL RANGE 1 TO c_noof_clnts;
        crqb_addr : NATURAL;
        gemaddr : STD_LOGIC_VECTOR(31 DOWNTO 0);
        nregs : NATURAL;
        csn : STD_LOGIC_VECTOR(c_gempro_csn_w-1 DOWNTO 0);
        dm_sts : STD_LOGIC_VECTOR(7 DOWNTO 0);
        -- Outputs
        ssn : INTEGER;
    END RECORD t_test;
    
    TYPE t_crqb_clnt_arr IS ARRAY(INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_noof_clnts+1 DOWNTO 1); 
    
    -- CRSB client partition boundaries
    CONSTANT crsb_low_addr_arr : t_integer_arr(1 TO c_noof_clnts) := ( 0, 21, 42 );
    CONSTANT crsb_high_addr_arr : t_integer_arr(1 TO c_noof_clnts) := ( 20, 41, 62 );

    TYPE t_test_vec IS ARRAY (INTEGER RANGE <>) OF t_test;
    CONSTANT c_test_vec : t_test_vec(1 TO 3) := ( 

            -- Client 1 connect
            -- CRSB frame length is 5 
            (   mmcmd => STD_LOGIC_VECTOR(TO_UNSIGNED(2**c_mmcmd_connect,8)),
                client => 1,
                crqb_addr => 3,
                gemaddr => x"01_02_03_04",
                nregs => 0,
                csn => x"01",
                dm_sts => x"FF",
                ssn => 1 ),

            -- Client 1 readInc
            -- CRSB frame length is floor((nregs+8)/2)
            (   mmcmd => STD_LOGIC_VECTOR(TO_UNSIGNED(2**c_mmcmd_read,8)) OR STD_LOGIC_VECTOR(TO_UNSIGNED(2**c_mmcmd_type,8)),
                client => 1,
                crqb_addr => 5,
                gemaddr => x"11_12_13_14",
                nregs => 3,
                csn => x"02",
                dm_sts => x"80",
                ssn => 2 ),

            -- Client 1 writeRep
            (   mmcmd => STD_LOGIC_VECTOR(TO_UNSIGNED(2**c_mmcmd_write,8)),
                client => 1,
                crqb_addr => 7,
                gemaddr => x"21_22_23_24",
                nregs => 3,
                csn => x"03",
                dm_sts => x"00",
                ssn => 3 )

              );

    SIGNAL rst : STD_LOGIC;
    SIGNAL clk : STD_LOGIC := '1';
    SIGNAL tb_end : STD_LOGIC := '0';
    SIGNAL crqb_data : STD_LOGIC_VECTOR(c_crqb_fifo_w-1 DOWNTO 0);
    SIGNAL crqb_rd : STD_LOGIC_VECTOR(c_noof_clnts+1 DOWNTO 1);
    SIGNAL crqb_sel : STD_LOGIC_VECTOR(c_noof_clnts+1 DOWNTO 1);
    SIGNAL crqb_clnt_arr : t_crqb_clnt_arr(0 TO c_noof_clnts) := ( "0001", "0010", "0100", "1000" );
    SIGNAL crqb_empty : STD_LOGIC;
    SIGNAL rqs_start : STD_LOGIC;
    SIGNAL rqs_nregs : STD_LOGIC_VECTOR(c_gempro_nreg_w-1 DOWNTO 0);
    SIGNAL rqs_addr : STD_LOGIC_VECTOR(c_crqb_addr_w-1 DOWNTO 0);
    SIGNAL re_start : STD_LOGIC; 
    SIGNAL re_cmd : STD_LOGIC_VECTOR(c_gempro_cmd_w-1 DOWNTO 0);
    SIGNAL re_fc : STD_LOGIC_VECTOR(c_gempro_fc_w-1 DOWNTO 0);
    SIGNAL re_csn : STD_LOGIC_VECTOR(c_gempro_csn_w-1 DOWNTO 0);
    SIGNAL re_nregs : STD_LOGIC_VECTOR(c_gempro_nreg_w-1 DOWNTO 0);
    SIGNAL re_crsb_addr : STD_LOGIC_VECTOR(c_crsb_addr_w-1 DOWNTO 0);
    SIGNAL re_crsb_low_addr : STD_LOGIC_VECTOR(c_crsb_addr_w-1 DOWNTO 0);
    SIGNAL re_crsb_high_addr : STD_LOGIC_VECTOR(c_crsb_addr_w-1 DOWNTO 0);
    SIGNAL re_complete : STD_LOGIC;
    SIGNAL s2mm_sts_tdata : STD_LOGIC_VECTOR ( 7 DOWNTO 0 );
    SIGNAL s2mm_sts_tkeep : STD_LOGIC_VECTOR ( 0 TO 0 );
    SIGNAL s2mm_sts_tlast : STD_LOGIC;
    SIGNAL s2mm_sts_tready : STD_LOGIC;
    SIGNAL s2mm_sts_tvalid : STD_LOGIC;
    SIGNAL s2mm_cmd_tdata : STD_LOGIC_VECTOR ( 71 DOWNTO 0 );
    SIGNAL s2mm_cmd_tready : STD_LOGIC;
    SIGNAL s2mm_cmd_tvalid : STD_LOGIC;
    SIGNAL s2mm_err : STD_LOGIC;
    SIGNAL mm2s_sts_tdata : STD_LOGIC_VECTOR ( 7 DOWNTO 0 );
    SIGNAL mm2s_sts_tkeep : STD_LOGIC_VECTOR ( 0 TO 0 );
    SIGNAL mm2s_sts_tlast : STD_LOGIC;
    SIGNAL mm2s_sts_tready : STD_LOGIC;
    SIGNAL mm2s_sts_tvalid : STD_LOGIC;
    SIGNAL mm2s_cmd_tdata : STD_LOGIC_VECTOR ( 71 DOWNTO 0 );
    SIGNAL mm2s_cmd_tready : STD_LOGIC;
    SIGNAL mm2s_cmd_tvalid : STD_LOGIC;
    SIGNAL mm2s_err : STD_LOGIC;
    SIGNAL crsb_fifo_wr : STD_LOGIC;
    SIGNAL crsb_fifo_full : STD_LOGIC;
    SIGNAL crsb_fifo_data : STD_LOGIC_VECTOR(c_crsb_fifo_w-1 DOWNTO 0);

    SIGNAL mmcmd : STD_LOGIC_VECTOR(c_mmcmd_w-1 DOWNTO 0);
    SIGNAL key : STD_LOGIC_VECTOR(c_key_w-1 DOWNTO 0);
    SIGNAL crqb_addr : NATURAL;
    SIGNAL crsb_addr : NATURAL;
    SIGNAL crsb_low_addr : NATURAL;
    SIGNAL crsb_high_addr : NATURAL;
    SIGNAL gemaddr : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL nregs : NATURAL;
    SIGNAL rd_nregs : NATURAL;
    SIGNAL wr_nregs : NATURAL;
    SIGNAL csn : STD_LOGIC_VECTOR(c_gempro_csn_w-1 DOWNTO 0);
    SIGNAL dm_sts : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL crsb_len : NATURAL;

    SIGNAL rqs_rst : STD_LOGIC;
    SIGNAL rqs_check : INTEGER;
    SIGNAL re_rst : STD_LOGIC;
    SIGNAL re_check : INTEGER;
    SIGNAL dm_rst : STD_LOGIC;

BEGIN

    clk <= NOT clk OR tb_end AFTER c_clk_period/2;
    rst <= '1', '0' AFTER 3*c_clk_period;
  
    crqb_data <= STD_LOGIC_VECTOR(TO_UNSIGNED(crqb_addr,24)) & gemaddr & STD_LOGIC_VECTOR(TO_UNSIGNED(nregs,16)) & csn & mmcmd;

    crqb_empty <= '0' WHEN crqb_sel = crqb_clnt_arr(TO_INTEGER(UNSIGNED(key))) ELSE '1'; 
    
    p_stimuli : PROCESS
    BEGIN
        
        -- Initialization
        WAIT UNTIL rst='0';
        crsb_len <= 0;
        crsb_addr <= 0;
        WAIT UNTIL RISING_EDGE(clk);

        FOR T IN c_test_vec'range LOOP

            mmcmd <= c_test_vec(T).mmcmd;
            key <= STD_LOGIC_VECTOR(TO_UNSIGNED(c_test_vec(T).client-1,c_key_w));
            crqb_addr <= c_test_vec(T).crqb_addr;
            gemaddr <= c_test_vec(T).gemaddr;
            nregs <= c_test_vec(T).nregs;
            csn <= c_test_vec(T).csn;
            dm_sts <= c_test_vec(T).dm_sts;
            crsb_low_addr <= crsb_low_addr_arr(c_test_vec(T).client);
            crsb_high_addr <= crsb_high_addr_arr(c_test_vec(T).client);

            dm_rst <= '1';
            re_rst <= '1';
            rqs_rst <= '1';
            WAIT UNTIL RISING_EDGE(clk) AND crqb_rd = crqb_clnt_arr(TO_INTEGER(UNSIGNED(key)));
            dm_rst <= '0';
            re_rst <= '0';
            rqs_rst <= '0';

            -- Length of this CRSB frame will be floor((nregs+8)/2)
            IF mmcmd(c_mmcmd_connect) = '1' THEN
                crsb_len <= (3+8)/2;
            ELSE
                crsb_len <= (nregs+8)/2;
            END IF;
            
            IF mmcmd(c_mmcmd_read) = '1' THEN
                rd_nregs <= nregs;
                wr_nregs <= 0;
            ELSIF mmcmd(c_mmcmd_write) = '1' THEN
                rd_nregs <= 0;
                wr_nregs <= nregs;
            ELSIF mmcmd(c_mmcmd_connect) = '1' THEN
                -- Response Encoder adds 3 registers of server information
                -- into the response PDU. Note that this server information
                -- isn't read from the MM bus.
                rd_nregs <= 3; 
                wr_nregs <= 0;
            ELSE
                rd_nregs <= 0; 
                wr_nregs <= 0;
            END IF;

            WAIT FOR 3 * c_clk_period;

            WAIT UNTIL RISING_EDGE(clk) AND crsb_fifo_wr = '1';

            ASSERT UNSIGNED(crsb_fifo_data(7 DOWNTO 0)) = TO_UNSIGNED(c_test_vec(T).ssn,8) REPORT "Incorrect CRSB control word SSN" SEVERITY FAILURE;
            ASSERT UNSIGNED(crsb_fifo_data(8+c_crsb_addr_w-1 DOWNTO 8)) = TO_UNSIGNED(crsb_addr, c_crsb_addr_w) REPORT "Incorrect CRSB control word CRSBAddr" SEVERITY FAILURE;
            ASSERT UNSIGNED(crsb_fifo_data(8+24+c_crsb_addr_w-1 DOWNTO 24+8)) = TO_UNSIGNED(crsb_low_addr, c_crsb_addr_w) REPORT "Incorrect CRSB control word CRSBLowAddr" SEVERITY FAILURE;
            ASSERT UNSIGNED(crsb_fifo_data(8+48+c_crsb_addr_w-1 DOWNTO 48+8)) = TO_UNSIGNED(crsb_high_addr, c_crsb_addr_w) REPORT "Incorrect CRSB control word CRSBHighAddr" SEVERITY FAILURE;
            ASSERT re_check = 3 REPORT "Incorrect Response Encoder control" SEVERITY FAILURE;
            ASSERT rqs_check = 2 REPORT "Incorrect Request Streamer control" SEVERITY FAILURE;

            -- Calculate CRSB address for next CRSB frame
            crsb_addr <= crsb_addr + crsb_len;
             
        END LOOP;

        tb_end <= '1';
        ASSERT FALSE REPORT "Simulation completed with no errors." SEVERITY NOTE;
        WAIT;

    END PROCESS;
    
    -- Emulate DataMover (S2MM/MM2S) 
    p_dm : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF dm_rst = '1' THEN
                mm2s_sts_tvalid <= '0';
                s2mm_sts_tvalid <= '0';
            ELSE
                IF mmcmd(c_mmcmd_read) = '1' THEN
                    mm2s_sts_tdata <= dm_sts;
                    mm2s_sts_tvalid <= '1';
                ELSIF mmcmd(c_mmcmd_write) = '1' THEN
                    s2mm_sts_tdata <= dm_sts;
                    s2mm_sts_tvalid <= '1';
                END IF;
            END IF;
        END IF;
    END PROCESS;

    mm2s_sts_tkeep <= "1";
    mm2s_sts_tlast <= '1';
    s2mm_sts_tkeep <= "1";
    s2mm_sts_tlast <= '1';

    -- Emulate Request Streamer
    p_rqs : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF rqs_rst = '1' THEN
                rqs_check <= 1;
            ELSE
                IF rqs_start = '1' 
                            AND UNSIGNED(rqs_nregs) = TO_UNSIGNED(wr_nregs,16) 
                            AND UNSIGNED(rqs_addr) = TO_UNSIGNED(crqb_addr,24) THEN
                    rqs_check <= rqs_check + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- Emulate Response Encoder
    p_re : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF re_rst = '1' THEN
                re_check <= 1;
            ELSE
                IF re_start = '1' 
                            AND re_csn = csn 
                            AND UNSIGNED(re_nregs) = TO_UNSIGNED(rd_nregs,c_gempro_nreg_w) 
                            AND UNSIGNED(re_crsb_addr) = TO_UNSIGNED(crsb_addr,c_crsb_addr_w) 
                            AND UNSIGNED(re_crsb_low_addr) = TO_UNSIGNED(crsb_low_addr,c_crsb_addr_w) 
                            AND UNSIGNED(re_crsb_high_addr) = TO_UNSIGNED(crsb_high_addr,c_crsb_addr_w) THEN
                    re_check <= re_check + 1;
                ELSIF re_complete = '1' THEN
                    re_check <= re_check + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    crsb_fifo_full <= '0';
    mm2s_err <= '0';
    s2mm_err <= '0';
    mm2s_cmd_tready <= '1';
    s2mm_cmd_tready <= '1';
    
    u_dut : ENTITY gemini_server_lib.mm_transaction_controller
    GENERIC MAP (
        g_key_w => c_key_w,
        g_max_pipeline => c_max_pipeline,
        g_noof_clnts => c_noof_clnts,
        g_crsb_npart_len => c_crsb_npart_len,
        g_crsb_cpart_len => c_crsb_cpart_len,
        g_crqb_fifo_w => c_crqb_fifo_w,
        g_crqb_addr_w => c_crqb_addr_w,
        g_crsb_addr_w => c_crsb_addr_w,
        g_crsb_fifo_w => c_crsb_fifo_w,
        g_txfr_timeout => 5 )
    PORT MAP (
        clk => clk,
        rst => rst,
        crqb_data_in    => crqb_data,
        crqb_rd_out     => crqb_rd,
        crqb_sel_out    => crqb_sel,
        crqb_empty_in   => crqb_empty,
        rqs_start_out   => rqs_start,
        rqs_nregs_out   => rqs_nregs,
        rqs_addr_out    => rqs_addr,
        rqs_rst_out     => open,
        re_start_out          => re_start,
        re_cmd_out            => re_cmd,
        re_fc_out             => re_fc,
        re_csn_out            => re_csn,
        re_nregs_out          => re_nregs,
        re_crsb_addr_out      => re_crsb_addr,
        re_crsb_low_addr_out  => re_crsb_low_addr,
        re_crsb_high_addr_out => re_crsb_high_addr,
        re_complete_out       => re_complete,
        re_rst_out          => open,
        s2mm_sts_tdata_in   => s2mm_sts_tdata,
        s2mm_sts_tkeep_in   => s2mm_sts_tkeep,
        s2mm_sts_tlast_in   => s2mm_sts_tlast,
        s2mm_sts_tready_out => s2mm_sts_tready,
        s2mm_sts_tvalid_in  => s2mm_sts_tvalid,
        s2mm_cmd_tdata_out  => s2mm_cmd_tdata,
        s2mm_cmd_tready_in  => s2mm_cmd_tready,
        s2mm_cmd_tvalid_out => s2mm_cmd_tvalid,
        s2mm_err_in         => s2mm_err,
        mm2s_sts_tdata_in   => mm2s_sts_tdata,
        mm2s_sts_tkeep_in   => mm2s_sts_tkeep,
        mm2s_sts_tlast_in   => mm2s_sts_tlast,
        mm2s_sts_tready_out => mm2s_sts_tready,
        mm2s_sts_tvalid_in  => mm2s_sts_tvalid,
        mm2s_cmd_tdata_out  => mm2s_cmd_tdata,
        mm2s_cmd_tready_in  => mm2s_cmd_tready,
        mm2s_cmd_tvalid_out => mm2s_cmd_tvalid,
        mm2s_err_in         => mm2s_err,
        crsb_fifo_wr_out    => crsb_fifo_wr,
        crsb_fifo_full_in   => crsb_fifo_full,
        crsb_fifo_data_out  => crsb_fifo_data );

END tb;
