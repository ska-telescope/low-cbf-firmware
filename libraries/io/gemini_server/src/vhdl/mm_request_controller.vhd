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

-- Purpose: MM Request Controller
--
-- Description: This module is responsible for the following:
--          1) Selection of a client request from one of the CRSB FIFO.
--              There is one FIFO per client connection. Round-robin scheduling is
--              used to ensure fairness.
--          2) Lookup of a CRSB RAM frame address, CRSBReplayAddr, from the
--              Replay Table using key and CSN.
--          3) Lookup of a CRSB RAM frame address, CRSBAddr, and SSN from
--              the Connection Table using key.
--          4) Instructing the Response Encoder to start operation to build
--              a CRSB frame. Note that the Gemini Protocol SSN and Cmd fields
--              are unknown by the MM Request Controller. These two fields are
--              written later.
--          5) Instructing the Request Streamer to start operation, optionally
--             streaming the request register payload to the MM bus for read requests.
--          6) Writing SSN+1 to a Connection Table location specified by key.
--          7) Writing CRSBAddr to a Replay Table location specified by (key,csn).
--          8) Issuing MM2S and S2MM commands.
--          9) Starting a completion event timer.
--
-- Remarks:
--

LIBRARY IEEE, common_lib, gemini_server_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE gemini_server_lib.gemini_server_pkg.ALL;

ENTITY mm_request_controller IS
    GENERIC (
        g_key_w : NATURAL;
        g_noof_clnts : NATURAL := 3;
        g_crsb_npart_len : NATURAL; -- Length of CRB unconnected client partition (in 64bit words)
        g_crsb_cpart_len : NATURAL; -- Length of single client CRB partition (in 64it words)
        g_crqb_fifo_w : NATURAL;
        g_crqb_addr_w : NATURAL;
        g_crsb_addr_w : NATURAL;
        g_crsb_fifo_w : NATURAL;
        g_crsb_npart_start_addr : NATURAL;
        g_crsb_npart_end_addr : NATURAL;
        g_txfr_timeout : NATURAL
    );
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        -- Interface: MM Transaction Controller
        mm_enable_in : IN STD_LOGIC;
        mm_txfr_busy_in : IN STD_LOGIC;
        mm_txfr_start_out : OUT STD_LOGIC;
        mm_txfr_timeout_out : OUT STD_LOGIC_VECTOR(c_gempro_nreg_w-1 DOWNTO 0);
        mm_crsb_ctrl_out : OUT STD_LOGIC_VECTOR(g_crsb_fifo_w-1 DOWNTO 0);
        mm_cmd_out : OUT STD_LOGIC_VECTOR(c_mmcmd_w-1 DOWNTO 0);
        -- Interface: Connection Table
        ct_wr_out : OUT STD_LOGIC;
        ct_addr_out : OUT STD_LOGIC_VECTOR(g_key_w-1 DOWNTO 0);
        ct_wr_data_out : OUT STD_LOGIC_VECTOR(c_gempro_ssn_w+g_crsb_addr_w-1 DOWNTO 0);
        ct_rd_data_in : IN STD_LOGIC_VECTOR(c_gempro_ssn_w+3*g_crsb_addr_w-1 DOWNTO 0);
        -- Interface: Replay Table
        rt_key_out : OUT STD_LOGIC_VECTOR(g_key_w-1 DOWNTO 0);
        rt_csn_out : OUT STD_LOGIC_VECTOR(c_gempro_csn_w-1 DOWNTO 0);
        rt_lookup_out : OUT STD_LOGIC;
        rt_connect_out : OUT STD_LOGIC;
        rt_complete_in : IN STD_LOGIC;
        rt_valid_in : IN STD_LOGIC;
        rt_dout_in : IN STD_LOGIC_VECTOR(g_crsb_addr_w-1 DOWNTO 0);
        rt_din_out : OUT STD_LOGIC_VECTOR(g_crsb_addr_w-1 DOWNTO 0);
        rt_wr_out : OUT STD_LOGIC;
        -- Interface: CRQB FIFOs
        crqb_data_in : IN STD_LOGIC_VECTOR(g_crqb_fifo_w-1 DOWNTO 0);
        crqb_rd_out : OUT STD_LOGIC_VECTOR(g_noof_clnts+1 DOWNTO 1);
        crqb_sel_out : OUT STD_LOGIC_VECTOR(g_noof_clnts+1 DOWNTO 1);
        crqb_empty_in : IN STD_LOGIC;
        -- Interface: Request Streamer
        rqs_start_out : OUT STD_LOGIC;
        rqs_nregs_out : OUT STD_LOGIC_VECTOR(c_gempro_nreg_w-1 DOWNTO 0);
        rqs_addr_out : OUT STD_LOGIC_VECTOR(g_crqb_addr_w-1 DOWNTO 0);
        -- Interface: Response Encoder (Start phase)
        re_start_out : OUT STD_LOGIC;
        re_csn_out : OUT STD_LOGIC_VECTOR(c_gempro_csn_w-1 DOWNTO 0);
        re_nregs_out : OUT STD_LOGIC_VECTOR(c_gempro_nreg_w-1 DOWNTO 0);
        re_connect_out : OUT STD_LOGIC;
        re_key_out : OUT STD_LOGIC_VECTOR(g_key_w-1 DOWNTO 0);
        re_crsb_addr_out : OUT STD_LOGIC_VECTOR(g_crsb_addr_w-1 DOWNTO 0);
        re_crsb_low_addr_out : OUT STD_LOGIC_VECTOR(g_crsb_addr_w-1 DOWNTO 0);
        re_crsb_high_addr_out : OUT STD_LOGIC_VECTOR(g_crsb_addr_w-1 DOWNTO 0);
        -- Interface: S2MM command
        s2mm_cmd_tdata_out : OUT STD_LOGIC_VECTOR ( 71 DOWNTO 0 );
        s2mm_cmd_tready_in : IN STD_LOGIC;
        s2mm_cmd_tvalid_out : OUT STD_LOGIC;
        -- Interface: MM2S command
        mm2s_cmd_tdata_out : OUT STD_LOGIC_VECTOR ( 71 DOWNTO 0 );
        mm2s_cmd_tready_in : IN STD_LOGIC;
        mm2s_cmd_tvalid_out : OUT STD_LOGIC;
        mm2s_err_in : IN STD_LOGIC;
        -- Debug
        crsb_state_out : out std_logic_vector(2 downto 0);
        main_state_out : out std_logic_vector(3 downto 0)
);
END mm_request_controller;

ARCHITECTURE rtl of mm_request_controller IS

    -- SSN field position within Connection Table data
    CONSTANT c_ct_ssn : NATURAL := 0;
    -- CRSBClntAddr field position within Connection Table data
    CONSTANT c_ct_crsb_clnt_addr : NATURAL := c_gempro_ssn_w;
    -- CRSB RAM client partition high address position within Connection Table data
    CONSTANT c_ct_crsb_clnt_high_addr : NATURAL := c_gempro_ssn_w+g_crsb_addr_w;
    -- CRSB RAM client partition low address position within Connection Table data
    CONSTANT c_ct_crsb_clnt_low_addr : NATURAL := c_gempro_ssn_w+2*g_crsb_addr_w;

    CONSTANT c_crsb_unconnected_low_addr : UNSIGNED(g_crsb_addr_w-1 DOWNTO 0) := TO_UNSIGNED(g_crsb_npart_start_addr,g_crsb_addr_w);
    CONSTANT c_crsb_unconnected_high_addr : UNSIGNED(g_crsb_addr_w-1 DOWNTO 0) := TO_UNSIGNED(g_crsb_npart_end_addr,g_crsb_addr_w);
    CONSTANT c_crsb_clnt_len : UNSIGNED(g_crsb_addr_w-1 DOWNTO 0) := TO_UNSIGNED(g_crsb_cpart_len,g_crsb_addr_w);

    TYPE t_state_enum IS ( s_crqb_sel_next, s_crqb_sel_empty, s_ct_wait, s_cmd, s_addr_wait,
                                s_lookup, s_next_addr_wait, s_update, s_mmbus_txfr, s_other_txfr );

    SIGNAL state : t_state_enum;
    SIGNAL crqb_sel : STD_LOGIC_VECTOR(g_noof_clnts+1 DOWNTO 1);
    SIGNAL connection_key : STD_LOGIC_VECTOR(g_key_w-1 DOWNTO 0); -- Only valid for connected clients
    SIGNAL unconnected : STD_LOGIC; -- '1' for unconnected clients.
    SIGNAL cmd : STD_LOGIC_VECTOR(c_mmcmd_w-1 DOWNTO 0);
    SIGNAL csn : UNSIGNED(c_gempro_csn_w-1 DOWNTO 0);
    SIGNAL last_ssn : UNSIGNED(c_gempro_ssn_w-1 DOWNTO 0);
    SIGNAL this_ssn : UNSIGNED(c_gempro_ssn_w-1 DOWNTO 0);
    SIGNAL ssn_plus_1 : UNSIGNED(c_gempro_ssn_w-1 DOWNTO 0);
    SIGNAL nregs : UNSIGNED(c_gempro_nreg_w-1 DOWNTO 0);
    SIGNAL read_nregs : UNSIGNED(c_gempro_nreg_w-1 DOWNTO 0);
    SIGNAL write_nregs : UNSIGNED(c_gempro_nreg_w-1 DOWNTO 0);
    SIGNAL crqb_addr : STD_LOGIC_VECTOR(g_crqb_addr_w-1 DOWNTO 0);
    SIGNAL crsb_addr : UNSIGNED(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL crsb_next_addr : UNSIGNED(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL crsb_next_addr_unwrapped : UNSIGNED(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL crsb_clnt_addr : UNSIGNED(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL crsb_clnt_low_addr : UNSIGNED(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL crsb_clnt_high_addr : UNSIGNED(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL crsb_len : UNSIGNED(c_gempro_nreg_w-1 DOWNTO 0);
    SIGNAL crsb_addr_len : UNSIGNED(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL crsb_low_addr : UNSIGNED(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL crsb_high_addr : UNSIGNED(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL mm_addr : STD_LOGIC_VECTOR(c_gempro_addr_w-1 DOWNTO 0);
    SIGNAL txfr_timeout : UNSIGNED(c_gempro_nreg_w-1 DOWNTO 0);
    SIGNAL replay : STD_LOGIC;
    SIGNAL connect : STD_LOGIC;
    SIGNAL crsb_state : STD_LOGIC_VECTOR(2 DOWNTO 0);

BEGIN

    gen_crsb_addr_len_le : IF crsb_addr_len'length <= crsb_len'length-1 GENERATE
        crsb_addr_len <= crsb_len(crsb_addr_len'left+1 DOWNTO crsb_len'right+1);
    END GENERATE;

    gen_crsb_addr_len_gt : IF crsb_addr_len'length > crsb_len'length-1 GENERATE
        crsb_addr_len(crsb_len'left-1 DOWNTO crsb_addr_len'right) <= crsb_len(crsb_len'left DOWNTO crsb_len'right+1);
        crsb_addr_len(crsb_addr_len'left DOWNTO crsb_len'left) <= (others=>'0');
    END GENERATE;

    p_ctrl : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF rst = '1' THEN
                state <= s_crqb_sel_next;
                crqb_sel <= (crqb_sel'left=>'1',others=>'0');
                crqb_rd_out <= (others=>'0');
                rt_lookup_out <= '0';
                re_start_out <= '0';
                rqs_start_out <= '0';
                mm2s_cmd_tvalid_out <= '0';
                s2mm_cmd_tvalid_out <= '0';
                mm_txfr_start_out <= '0';
                rt_wr_out <= '0';
                rt_connect_out <= '0';
                ct_wr_out <= '0';
            ELSE

                ---------------------------------
                -- debug outputs
                crsb_state_out <= crsb_state;
                if state = s_crqb_sel_next then
                    main_state_out <= "0000";
                elsif state = s_crqb_sel_empty then
                    main_state_out <= "0001";
                elsif state =  s_ct_wait then
                    main_state_out <= "0010";
                elsif state =  s_cmd then
                    main_state_out <= "0011";
                elsif state = s_addr_wait then
                    main_state_out <= "0100";
                elsif state = s_lookup then
                    main_state_out <= "0101";
                elsif state = s_next_addr_wait then
                    main_state_out <= "0110";
                elsif state = s_update then
                    main_state_out <= "0111";
                elsif state = s_mmbus_txfr then
                    main_state_out <= "1000";
                elsif state = s_other_txfr then
                    main_state_out <= "1001";
                else
                    main_state_out <= "1111";
                end if;
                
                ----------------------------------

                crqb_rd_out <= (others=>'0');
                rt_lookup_out <= '0';
                re_start_out <= '0';
                rqs_start_out <= '0';
                mm2s_cmd_tvalid_out <= '0';
                s2mm_cmd_tvalid_out <= '0';
                mm_txfr_start_out <= '0';
                rt_wr_out <= '0';
                rt_connect_out <= '0';
                ct_wr_out <= '0';

                rt_din_out <= STD_LOGIC_VECTOR(crsb_addr);
                re_csn_out <= STD_LOGIC_VECTOR(csn);
                re_nregs_out <= STD_LOGIC_VECTOR(read_nregs);
                re_crsb_addr_out <= STD_LOGIC_VECTOR(crsb_addr);
                re_connect_out <= connect;
                re_key_out <= connection_key;
                rt_key_out <= connection_key;
                rt_csn_out <= STD_LOGIC_VECTOR(csn);
                ct_addr_out <= connection_key;
                rqs_nregs_out <= STD_LOGIC_VECTOR(write_nregs);
                rqs_addr_out <= crqb_addr;

                mm_cmd_out <= cmd;
                mm_crsb_ctrl_out(c_gempro_ssn_w-1 DOWNTO 0) <= STD_LOGIC_VECTOR(this_ssn);
                mm_crsb_ctrl_out(8+g_crsb_addr_w-1 DOWNTO 8) <= STD_LOGIC_VECTOR(crsb_addr);

                -- Register outputs from Connection Table
                last_ssn <= UNSIGNED(ct_rd_data_in(c_ct_ssn+c_gempro_ssn_w-1 DOWNTO c_ct_ssn));
                crsb_clnt_addr <= UNSIGNED(ct_rd_data_in(c_ct_crsb_clnt_addr+g_crsb_addr_w-1 DOWNTO c_ct_crsb_clnt_addr));
                crsb_clnt_low_addr <= UNSIGNED(ct_rd_data_in(c_ct_crsb_clnt_low_addr+g_crsb_addr_w-1 DOWNTO c_ct_crsb_clnt_low_addr));
                crsb_clnt_high_addr <= UNSIGNED(ct_rd_data_in(c_ct_crsb_clnt_high_addr+g_crsb_addr_w-1 DOWNTO c_ct_crsb_clnt_high_addr));

                -- Inputs to Connection Table
                ct_wr_data_out(c_ct_ssn+c_gempro_ssn_w-1 DOWNTO c_ct_ssn) <= STD_LOGIC_VECTOR(this_ssn);
                ct_wr_data_out(c_ct_crsb_clnt_addr+g_crsb_addr_w-1 DOWNTO c_ct_crsb_clnt_addr) <= STD_LOGIC_VECTOR(crsb_next_addr);

                -- S2MM command
                s2mm_cmd_tdata_out <= (others=>'0');
                s2mm_cmd_tdata_out(2+write_nregs'length-1 DOWNTO 2) <= STD_LOGIC_VECTOR(write_nregs); -- BTT
                s2mm_cmd_tdata_out(23) <= cmd(c_mmcmd_type); -- Type (1 for increment, 0 for repeat)
                s2mm_cmd_tdata_out(30) <= '1'; -- EOF
                -- mm_addr is a 32 bit register address. SADDR is a byte address.
                s2mm_cmd_tdata_out(33 DOWNTO 32) <= "00";
                s2mm_cmd_tdata_out(32+mm_addr'length-1 DOWNTO 34) <= mm_addr(mm_addr'length-3 DOWNTO 0);

                -- MM2S command
                mm2s_cmd_tdata_out <= (others=>'0');
                mm2s_cmd_tdata_out(2+read_nregs'length-1 DOWNTO 2) <= STD_LOGIC_VECTOR(read_nregs); -- BTT
                mm2s_cmd_tdata_out(23) <= cmd(c_mmcmd_type); -- Type (1 for increment, 0 for repeat)
                mm2s_cmd_tdata_out(30) <= '1'; -- EOF
                -- mm_addr is a 32 bit register address. SADDR is a byte address.
                mm2s_cmd_tdata_out(33 DOWNTO 32) <= "00";
                mm2s_cmd_tdata_out(32+mm_addr'length-1 DOWNTO 34) <= mm_addr(mm_addr'length-3 DOWNTO 0);

                -- Number of registers that we expect to read or write to/from MM bus
                -- depends on the Gemini Protocol command and nregs
                IF cmd(c_mmcmd_nackt) = '1' OR cmd(c_mmcmd_nackp) = '1' THEN
                    read_nregs <= (others=>'0');
                    write_nregs <= (others=>'0');
                ELSIF cmd(c_mmcmd_write) = '1' THEN
                    read_nregs <= (others=>'0');
                    write_nregs <= nregs;
                ELSIF cmd(c_mmcmd_read) = '1' THEN
                    read_nregs <= nregs;
                    write_nregs <= (others=>'0');
                ELSIF cmd(c_mmcmd_connect) = '1' THEN
                    -- Response Encoder adds 3 registers of server information
                    -- into the response PDU. Note that this server information
                    -- isn't read from the MM bus.
                    read_nregs <= TO_UNSIGNED(3,read_nregs'length);
                    write_nregs <= (others=>'0');
                ELSE
                    read_nregs <= (others=>'0');
                    write_nregs <= (others=>'0');
                END IF;

                txfr_timeout <= UNSIGNED(nregs) + TO_UNSIGNED(g_txfr_timeout,txfr_timeout'length);

                CASE crsb_state IS
                    WHEN "100" => -- Unconnected
                        crsb_addr <= c_crsb_unconnected_low_addr;
                        crsb_low_addr <= c_crsb_unconnected_low_addr;
                        crsb_high_addr <= c_crsb_unconnected_high_addr;
                    WHEN "010" => -- Replay
                        crsb_addr <= UNSIGNED(rt_dout_in);
                        crsb_low_addr <= crsb_clnt_low_addr;
                        crsb_high_addr <= crsb_clnt_high_addr;
                    WHEN "001" => -- Connect
                        crsb_addr <= crsb_clnt_low_addr;
                        crsb_low_addr <= crsb_clnt_low_addr;
                        crsb_high_addr <= crsb_clnt_high_addr;
                    WHEN OTHERS =>
                        crsb_addr <= crsb_clnt_addr;
                        crsb_low_addr <= crsb_clnt_low_addr;
                        crsb_high_addr <= crsb_clnt_high_addr;
                END CASE;

                -- For connected clients: Calculate next CRSB RAM address from crsb_addr
                -- Length of CRSB frame is floor((read_nregs+8)/2)
                crsb_len <= read_nregs + TO_UNSIGNED(8,crsb_len'length);
                crsb_next_addr_unwrapped <= crsb_addr + crsb_addr_len;
                IF crsb_next_addr_unwrapped > crsb_high_addr THEN
                    crsb_next_addr <= crsb_next_addr_unwrapped - c_crsb_clnt_len;
                ELSE
                    crsb_next_addr <= crsb_next_addr_unwrapped;
                END IF;

                CASE state IS
                    WHEN s_crqb_sel_next =>
                        -- Select the next CRQB FIFO
                        state <= s_crqb_sel_empty;
                        crqb_sel <= crqb_sel(crqb_sel'right) & crqb_sel(crqb_sel'left DOWNTO crqb_sel'right+1);
                    WHEN s_crqb_sel_empty =>
                        -- Check if the selected CRQB FIFO is empty
                        cmd <= crqb_data_in(c_mmcmd_w-1 DOWNTO 0);
                        csn <= UNSIGNED(crqb_data_in(8+c_gempro_csn_w-1 DOWNTO 8));
                        nregs <= UNSIGNED(crqb_data_in(16+c_gempro_nreg_w-1 DOWNTO 16));
                        mm_addr <= crqb_data_in(32+c_gempro_addr_w-1 DOWNTO 32);
                        crqb_addr <= crqb_data_in(64+g_crqb_addr_w-1 DOWNTO 64);
                        replay <= '0';
                        connect <= '0';
                        state <= s_crqb_sel_next;
                        IF crqb_empty_in = '0' AND mm_enable_in = '1' THEN
                            -- Pop control word from selected CRQB FIFO
                            state <= s_ct_wait;
                            crqb_rd_out <= crqb_sel;
                        END IF;
                    WHEN s_ct_wait =>
                        -- Connection Table lookup wait
                        state <= s_cmd;
                    WHEN s_cmd =>
                        -- Connection Table lookup completed
                        -- last_ssn and crsb_clnt addresses now valid
                        IF cmd(c_mmcmd_nackt) = '1' THEN
                            state <= s_other_txfr;
                        ELSIF unconnected = '1' THEN
                            cmd(c_mmcmd_nackp) <= '1';
                            state <= s_other_txfr;
                        ELSIF cmd(c_mmcmd_nackp) = '1' THEN
                            rt_lookup_out <= '1';
                            state <= s_lookup;
                        ELSIF cmd(c_mmcmd_connect) = '1' THEN
                            cmd(c_mmcmd_ack) <= '1';
                            rt_connect_out <= '1';
                            this_ssn <= TO_UNSIGNED(1,this_ssn'length);
                            connect <= '1';
                            state <= s_addr_wait;
                        ELSIF ( cmd(c_mmcmd_write) = '1' OR cmd(c_mmcmd_read) = '1' ) AND csn = ssn_plus_1 THEN
                            -- CSN=SSN+1.
                            this_ssn <= ssn_plus_1;
                            state <= s_mmbus_txfr;
                        ELSIF cmd(c_mmcmd_write) = '1' OR cmd(c_mmcmd_read) = '1' THEN
                            rt_lookup_out <= '1';
                            state <= s_lookup;
                        ELSE
                            cmd(c_mmcmd_nackp) <= '1';
                            this_ssn <= ssn_plus_1;
                            state <= s_other_txfr;
                        END IF;
                    WHEN s_lookup =>
                        -- Wait for Replay Table lookup to complete
                        IF rt_complete_in = '1' AND rt_valid_in = '1' THEN
                            -- (connection_key,csn) found. Replay
                            replay <= '1';
                            cmd(c_mmcmd_replay) <= '1';
                            state <= s_addr_wait;
                        ELSIF rt_complete_in = '1' THEN
                            -- (connection_key,csn) not found.
                            IF csn = ssn_plus_1 THEN
                                this_ssn <= ssn_plus_1;
                                state <= s_addr_wait;
                            ELSE
                                cmd(c_mmcmd_nackt) <= '1';
                                cmd(c_mmcmd_nackp) <= '0';
                                state <= s_addr_wait;
                            END IF;
                        END IF;
                    WHEN s_mmbus_txfr =>
                        -- crsb_addr now valid
                        IF cmd(c_mmcmd_read)  = '1' AND mm2s_cmd_tready_in = '1' AND mm_txfr_busy_in = '0' THEN
                            mm2s_cmd_tvalid_out <= '1';
                            re_start_out <= '1';
                            rqs_start_out <= '1';
                            mm_txfr_start_out <= '1';
                            state <= s_next_addr_wait;
                        ELSIF cmd(c_mmcmd_write) = '1' AND s2mm_cmd_tready_in = '1' AND mm_txfr_busy_in = '0' THEN
                            s2mm_cmd_tvalid_out <= '1';
                            re_start_out <= '1';
                            mm_txfr_start_out <= '1';
                            rqs_start_out <= '1';
                            state <= s_next_addr_wait;
                        END IF;
                    WHEN s_addr_wait =>
                        -- Need extra clock to calculate crsb_addr
                        -- and for read_nregs/write_nregs to become valid
                        state <= s_other_txfr;
                    WHEN s_other_txfr =>
                        -- crsb_addr now valid for both connected
                        -- and unconnected client cases
                        txfr_timeout <= (others=>'0');
                        IF mm_txfr_busy_in = '0' THEN
                            re_start_out <= not replay;
                            mm_txfr_start_out <= '1';
                            rqs_start_out <= not replay;
                            IF unconnected = '0' THEN
                                state <= s_next_addr_wait;
                            ELSE
                                state <= s_crqb_sel_next;
                            END IF;
                        END IF;
                    WHEN s_next_addr_wait =>
                        -- Need extra clock to calculate crsb_next_addr
                        state <= s_update;
                    WHEN s_update =>
    
                        -- Replay table always updated regardless of success of transaction
    
                        -- Write crsb_next_addr and this_ssn to location (connection_key) in the Connection Table
                        -- Write crsb_addr to location (connection_key,csn) in the Replay Table
                        rt_wr_out <= '1';
                        IF cmd(c_mmcmd_nackt) = '1' OR replay = '1' THEN
                            rt_wr_out <= '0';
                        END IF;
                        ct_wr_out <= not replay;
                        state <= s_crqb_sel_next;
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    crqb_sel_out <= crqb_sel;
    ssn_plus_1 <= last_ssn + TO_UNSIGNED(1,ssn_plus_1'length);

    re_crsb_low_addr_out <= STD_LOGIC_VECTOR(crsb_low_addr);
    re_crsb_high_addr_out <= STD_LOGIC_VECTOR(crsb_high_addr);
    mm_crsb_ctrl_out(8+24+g_crsb_addr_w-1 DOWNTO 8+24) <= STD_LOGIC_VECTOR(crsb_low_addr);
    mm_crsb_ctrl_out(8+2*24+g_crsb_addr_w-1 DOWNTO 8+2*24) <= STD_LOGIC_VECTOR(crsb_high_addr);

    mm_txfr_timeout_out <= STD_LOGIC_VECTOR(txfr_timeout);

    gen_connection_key_3 : IF g_noof_clnts = 3 GENERATE
        connection_key <= "00" WHEN crqb_sel = "0001"
                     ELSE "01" WHEN crqb_sel = "0010"
                     ELSE "10";
        unconnected <= '1' WHEN crqb_sel = "1000" ELSE '0';
    END GENERATE;

    gen_connection_key_2 : IF g_noof_clnts = 2 GENERATE
        connection_key <= "0" WHEN crqb_sel = "001"
                     ELSE "1";
        unconnected <= '1' WHEN crqb_sel = "100" ELSE '0';
    END GENERATE;

    gen_connection_key_1 : IF g_noof_clnts = 1 GENERATE
        connection_key <= "0";
        unconnected <= '1' WHEN crqb_sel = "10" ELSE '0';
    END GENERATE;

    crsb_state <= unconnected & replay & connect;

END rtl;
