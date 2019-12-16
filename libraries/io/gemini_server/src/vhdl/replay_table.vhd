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

-- Purpose: The Replay Table module stores the Client Response Buffer (CRSB)
--           addresses for response PDUs. PDU data is retained after transmission
--           to give the client the option to request a replay if a response packet
--           is lost in transit.
--          The Replay History Table is partitioned so that buffer address information
--           for g_max_pipeline packets is available to each client for replay.
--          Three user operations are provided:
--             1) Client reset. Invalidate all data associated with key_in.
--             2) Write. The user supplies valid key_in, csn_in and wr_data_in and pulses wr_in high
--             3) Lookup. The user supplies valid key_in and csn_in and pulses lookup_in high.
--                  This module responses by pulsing either failed_out or valid_out high for 1 clock.
--                  If failed_out was asserted then there is no data available for the (key,csn)
--                  If valid_out was asserted then the data is supplied on data_out
--
-- Description: In this module "CRSB address" is referred to as the data and part of the CSN is
--                 referred to as the sequence. A single RAM is dimensioned so as to
--                 provide storage for at least the last g_max_pipeline sequences, for each
--                 of the g_noof_clnts clients.
--
-- Remarks: The module stores a data valid bit alongside each data item. This is automatically set to '1'
--              for locations that are written to by the user.
--

LIBRARY IEEE, common_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;

ENTITY replay_table IS
    GENERIC (
        g_key_w : NATURAL := 2;
        g_csn_w : NATURAL := 16;
        g_max_pipeline : NATURAL := 8; -- Maximum pipeline depth (packets)
        g_noof_clnts : NATURAL := 3; -- Maximum number of clients
        g_data_w : NATURAL := 32 -- Width of table data row
    );
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        clnt_rst : IN STD_LOGIC;
        -- Interface: Lookup
        key_in : IN STD_LOGIC_VECTOR(g_key_w-1 DOWNTO 0);
        csn_in : IN STD_LOGIC_VECTOR(g_csn_w-1 DOWNTO 0);
        lookup_in : IN STD_LOGIC;
        complete_out : OUT STD_LOGIC;
        valid_out : OUT STD_LOGIC;
        data_out : OUT STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
        -- Interface: Update
        wr_in : IN STD_LOGIC;
        wr_data_in : IN STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
        -- debug
        state_out : out std_logic_vector(3 downto 0)
    );
END;

ARCHITECTURE rtl OF replay_table IS

    CONSTANT c_seq_w : INTEGER := ceil_log2(g_max_pipeline);
    CONSTANT c_addr_w : INTEGER := g_key_w + c_seq_w;

    TYPE t_state_enum IS ( s_wait, s_write, s_clnt_invalidate, s_lookup_calc, s_lookup_complete );

    TYPE t_data_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    TYPE t_clnt_valid_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(2**c_seq_w-1 DOWNTO 0);
    TYPE t_csn_arr IS ARRAY (INTEGER RANGE <>) OF UNSIGNED(g_csn_w-1 DOWNTO 0);

    SIGNAL state : t_state_enum;
    SIGNAL mem : t_data_arr(0 TO 2**c_addr_w-1);
    SIGNAL mem_wr : STD_LOGIC;
    SIGNAL mem_addr : UNSIGNED(c_addr_w-1 DOWNTO 0);
    SIGNAL mem_wr_data : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    SIGNAL mem_rd_data : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    SIGNAL mem_rd_data_reg : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    SIGNAL key : UNSIGNED(g_key_w-1 DOWNTO 0);
    SIGNAL seq : UNSIGNED(c_seq_w-1 DOWNTO 0);
    SIGNAL csn : UNSIGNED(g_csn_w-1 DOWNTO 0);
    SIGNAL csn_history : t_csn_arr(0 TO g_noof_clnts-1);
    SIGNAL clnt_valid : t_clnt_valid_arr(0 TO g_noof_clnts-1);
    SIGNAL clnt_seq_valid : STD_LOGIC;
    SIGNAL last_csn : UNSIGNED(g_csn_w-1 DOWNTO 0);
    SIGNAL csn_available : STD_LOGIC;

BEGIN

    -- Infer single port distributed memory
    -- Assume 0 clock read latency
    p_mem : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF mem_wr = '1' THEN
                mem(TO_INTEGER(mem_addr)) <= mem_wr_data;
            END IF;
        END IF;
    END PROCESS;

    mem_rd_data <= mem(TO_INTEGER(mem_addr));
    mem_addr <= key & seq;
    mem_wr <= '1' WHEN state = s_write ELSE '0';

    p_main : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF rst = '1' THEN
                state <= s_wait;
                clnt_valid <= (others=>(others=>'0'));
                csn_history <= (others=>(others=>'0'));
                complete_out <= '0';
            ELSE

                -- Calculate whether supplied CSN is available in table
                csn_available <= '0';
                last_csn <= csn_history(TO_INTEGER(key));
                IF last_csn - csn < TO_UNSIGNED(g_max_pipeline,csn'length) THEN
                    csn_available <= '1';
                END IF;

                clnt_seq_valid <= clnt_valid(TO_INTEGER(key))(TO_INTEGER(seq));

                mem_rd_data_reg <= mem_rd_data;
                data_out <= mem_rd_data_reg;
                valid_out <= '0';
                complete_out <= '0';

                CASE state IS
                    WHEN s_wait =>
                        state_out <= "0000";
                        key <= UNSIGNED(key_in);
                        seq <= UNSIGNED(csn_in(c_seq_w-1 DOWNTO 0));
                        csn <= UNSIGNED(csn_in);
                        mem_wr_data <= wr_data_in;
                        IF clnt_rst = '1' THEN
                            state <= s_clnt_invalidate;
                        ELSIF lookup_in = '1' THEN
                            state <= s_lookup_calc;
                        ELSIF wr_in = '1' THEN
                            state <= s_write;
                        END IF;
                    WHEN s_write =>
                        -- Store wr_data_in
                        state_out <= "0001";
                        csn_history(TO_INTEGER(key)) <= csn;
                        clnt_valid(TO_INTEGER(key))(TO_INTEGER(seq)) <= '1';
                        state <= s_wait;
                    WHEN s_clnt_invalidate =>
                        -- Invalidate all data associated with the supplied key
                        state_out <= "0010";
                        clnt_valid(TO_INTEGER(key)) <= (others=>'0');
                        csn_history(TO_INTEGER(key)) <= (others=>'0');
                        state <= s_wait;
                    WHEN s_lookup_calc =>
                        state_out <= "0011";
                        state <= s_lookup_complete;
                    WHEN s_lookup_complete =>
                        -- csn_available & mem_rd_data_reg are now valid
                        state_out <= "0100";
                        complete_out <= '1';
                        IF csn_available = '1' AND clnt_seq_valid = '1' THEN
                            valid_out <= '1';
                        END IF;
                        state <= s_wait;
                END CASE;

            END IF;
        END IF;
    END PROCESS;

END rtl;

