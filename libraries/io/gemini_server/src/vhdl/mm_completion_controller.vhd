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

-- Purpose: MM Completion Controller
--
-- Description: This module is responsible for the following:
--               1) Instructing the Request Streamer to complete.
--               2) Providing the Request Encoder with MM transaction status
--                   information in the form of the response Gemini Protocol
--                   command and optional failure code.
--               3) Cleaning up S2MM or MM2S state after a MM bus error.
--               4) Generating GemCmd and GemFC from the S2MM and MM2S status words.
-- Remarks:
--

LIBRARY IEEE, common_lib, gemini_server_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE gemini_server_lib.gemini_server_pkg.ALL;

ENTITY mm_completion_controller IS
   PORT (
      clk               : IN STD_LOGIC;
      rst               : IN STD_LOGIC;

      s2mm_aresetn_out  : OUT STD_LOGIC;
      mm2s_aresetn_out  : OUT STD_LOGIC;
      mm2s_err_out      : OUT STD_LOGIC;
      s2mm_err_out      : OUT STD_LOGIC;
      -- reset to downstream modules on the mm bus, to prevent lockup from broken transactions issued by the datamover when it is reset.
      mm_reset_out      : out std_logic;
      -- Interface: MM Transaction Controller
      mm_txfr_busy_in   : IN STD_LOGIC;
      mm_txfr_complete_out : OUT STD_LOGIC;
      mm_txfr_timer_expiry_in : IN STD_LOGIC;
      mm_cmd_in         : IN STD_LOGIC_VECTOR(c_mmcmd_w-1 DOWNTO 0);

      -- Interface: Response Encoder (Complete phase)
      re_cmd_out        : OUT STD_LOGIC_VECTOR(c_gempro_cmd_w-1 DOWNTO 0);
      re_fc_out         : OUT STD_LOGIC_VECTOR(c_gempro_fc_w-1 DOWNTO 0);
      re_complete_out   : OUT STD_LOGIC;

      -- Interface: S2MM status
      s2mm_sts_tdata_in : IN STD_LOGIC_VECTOR ( 7 DOWNTO 0 );
      s2mm_sts_tkeep_in : IN STD_LOGIC_VECTOR ( 0 TO 0 );
      s2mm_sts_tlast_in : IN STD_LOGIC;
      s2mm_sts_tready_out : OUT STD_LOGIC;
      s2mm_sts_tvalid_in : IN STD_LOGIC;
      s2mm_err_in       : IN STD_LOGIC;

      -- Interface: MM2S status
      mm2s_sts_tdata_in : IN STD_LOGIC_VECTOR ( 7 DOWNTO 0 );
      mm2s_sts_tkeep_in : IN STD_LOGIC_VECTOR ( 0 TO 0 );
      mm2s_sts_tlast_in : IN STD_LOGIC;
      mm2s_sts_tready_out : OUT STD_LOGIC;
      mm2s_sts_tvalid_in : IN STD_LOGIC;
      mm2s_err_in       : IN STD_LOGIC;
      
      -- debug
      state_out : out std_logic_vector(3 downto 0)
      
   );
END mm_completion_controller;

ARCHITECTURE rtl of mm_completion_controller IS

    TYPE t_state_enum IS ( s_wait_start, s_complete, s_readwrite, s_non_readwrite, s_mm2s_cleanup, s_s2mm_cleanup, s_wait_re, s_wait_end );

    CONSTANT c_sts_okay : NATURAL := 7;

    SIGNAL state : t_state_enum;
    SIGNAL last_state : t_state_enum;
    SIGNAL fc : STD_LOGIC_VECTOR(c_gempro_fc_w-1 DOWNTO 0);
    SIGNAL count : t_sl_arr(2 TO 3);
    signal cleanup_count : std_logic_vector(7 downto 0);

BEGIN

    p_main : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF rst = '1' THEN
                state <= s_wait_start;
                mm2s_aresetn_out <= '0';
                s2mm_aresetn_out <= '0';
                mm_reset_out <= '0'; -- This reset is or'd with the general mm reset at the top level, so do not assert it here, (risk reset holding it in reset indefinitely) 
            ELSE

                re_fc_out <= fc;

                mm2s_aresetn_out <= '1';
                s2mm_aresetn_out <= '1'; -- active low
                mm_reset_out <= '0'; -- active high

                mm2s_err_out <= '0';
                s2mm_err_out <= '0';

                last_state <= state;
                count <= '0' & count(count'left TO count'right-1);
                IF state /= last_state THEN
                    count <= (count'left=>'1',others=>'0');
                END IF;

                CASE state IS
                    WHEN s_wait_start =>
                        -- Wait for transfer to start
                        state_out <= "0000";
                        cleanup_count <= "00000000";
                        IF mm_txfr_busy_in = '1' THEN
                            state <= s_complete;
                        END IF;
                    WHEN s_complete =>
                        -- Wait for either completion timer or MM2S/S2MM completion
                        state_out <= "0001";
                        cleanup_count <= "00000000";
                        IF mm_cmd_in(c_mmcmd_nackt) = '1' OR mm_cmd_in(c_mmcmd_nackp) = '1' OR mm_cmd_in(c_mmcmd_replay) = '1' OR mm_cmd_in(c_mmcmd_ack) = '1' THEN
                            fc <= x"0000";
                            IF mm_txfr_timer_expiry_in = '1' THEN
                                state <= s_non_readwrite;
                            END IF;
                        ELSIF mm_cmd_in(c_mmcmd_read) = '1' AND (mm2s_err_in = '1' OR mm_txfr_timer_expiry_in = '1') THEN
                            mm2s_err_out <= mm2s_err_in OR mm_txfr_timer_expiry_in;
                            fc <= mm_txfr_timer_expiry_in & mm2s_err_in & "00" & x"000";
                            state <= s_mm2s_cleanup;
                        ELSIF mm_cmd_in(c_mmcmd_write) = '1' AND (s2mm_err_in = '1' OR mm_txfr_timer_expiry_in = '1') THEN
                            s2mm_err_out <= mm2s_err_in OR mm_txfr_timer_expiry_in;
                            fc <= mm_txfr_timer_expiry_in & "0" & s2mm_err_in & "0" & x"000";
                            state <= s_s2mm_cleanup;
                        ELSIF mm2s_sts_tvalid_in = '1' AND mm_cmd_in(c_mmcmd_read) = '1' THEN
                            fc(c_gempro_fc_w-1 DOWNTO 8) <= (others=>'0');
                            fc(7 DOWNTO 0) <= mm2s_sts_tdata_in;
                            state <= s_readwrite;
                        ELSIF s2mm_sts_tvalid_in = '1' AND mm_cmd_in(c_mmcmd_write) = '1' THEN
                            fc(c_gempro_fc_w-1 DOWNTO 8) <= (others=>'0');
                            fc(7 DOWNTO 0) <= s2mm_sts_tdata_in;
                            state <= s_readwrite;
                        END IF;
                    WHEN s_readwrite =>
                        -- Read or Write operation has just completed
                        state_out <= "0010";
                        cleanup_count <= "00000000";
                        IF fc(c_sts_okay) = '1' THEN
                            re_cmd_out <= c_gemresp_ack;
                        ELSE
                            re_cmd_out <= c_gemresp_nackp;
                        END IF;
                        state <= s_wait_re;
                    WHEN s_non_readwrite =>
                        -- Non read/write operation has just completed
                        state_out <= "0011";
                        cleanup_count <= "00000000";
                        re_cmd_out <= (others=>'0');
                        re_cmd_out(c_mmcmd_nackp DOWNTO c_mmcmd_ack)  <= mm_cmd_in(c_mmcmd_nackp DOWNTO c_mmcmd_ack);
                        IF mm_cmd_in(c_mmcmd_replay) = '1' THEN
                            state <= s_wait_end;
                        ELSE
                            state <= s_wait_re;
                        END IF;
                    WHEN s_mm2s_cleanup =>
                        re_cmd_out <= c_gemresp_nackp;
                        state_out <= "0100";
                        -- mm2s_err is cleared by holding MM2S in reset for 3 clocks
                        -- We also need to reset the downstream modules on the mm bus becauase
                        -- reseting the datamover can generate bad transactions on the mm bus 
                        -- which can lockup the interconnect. Interconnect reset is recommended to be 
                        -- held for 16 clocks. The component in the register blocks has a timeout of 64 clocks,
                        -- so we need to hold this long to ensure it doesn't respond after the reset is deasserted.
                        -- So stay in this state for 20 clocks, with 3 clocks of reset for mm2s and 
                        -- 16 clocks of reset for the rest of the downstream modules.
                        if (unsigned(cleanup_count) < 3) then
                            mm2s_aresetn_out <= '0';
                        else
                            mm2s_aresetn_out <= '1';
                        end if;
                        if (unsigned(cleanup_count) < 80) then
                            mm_reset_out <= '1';
                        else
                            mm_reset_out <= '0';
                        end if;
                        cleanup_count <= std_logic_vector(unsigned(cleanup_count) + 1);
                        IF unsigned(cleanup_count) = 84 THEN
                            state <= s_wait_re;
                        END IF;
                    WHEN s_s2mm_cleanup =>
                        re_cmd_out <= c_gemresp_nackp;
                        state_out <= "0101";
                        -- s2mm_err is cleared by holding S2MM in reset for 3 clocks
                        -- see comments above relating to reset for s_mm2s_cleanup.
                        if (unsigned(cleanup_count) < 3) then
                            s2mm_aresetn_out <= '0';
                        else
                            s2mm_aresetn_out <= '1';
                        end if;
                        if (unsigned(cleanup_count) < 80) then
                            mm_reset_out <= '1';
                        else
                            mm_reset_out <= '0';
                        end if;
                        cleanup_count <= std_logic_vector(unsigned(cleanup_count) + 1);
                        IF unsigned(cleanup_count) = 84 THEN
                            state <= s_wait_re;
                        END IF;
                    WHEN s_wait_re =>
                        -- Wait 3 clocks for Response Encoder to finish before signalling MM complete
                        state_out <= "0110";
                        cleanup_count <= "00000000";
                        IF count(3) = '1' THEN
                            state <= s_wait_end;
                        END IF;
                    WHEN s_wait_end =>
                        state_out <= "0111";
                        cleanup_count <= "00000000";
                        -- Signal completion and wait for transfer to end
                        IF mm_txfr_busy_in = '0' THEN
                            state <= s_wait_start;
                        END IF;
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    re_complete_out <= '1' WHEN state = s_wait_re AND last_state /= s_wait_re ELSE '0';
    mm_txfr_complete_out <= '1' WHEN state = s_wait_end AND last_state /= s_wait_end ELSE '0';
    s2mm_sts_tready_out <= '1' WHEN state = s_complete AND NOT ( mm_cmd_in(c_mmcmd_nackt) = '1' OR mm_cmd_in(c_mmcmd_nackp) = '1' OR mm_cmd_in(c_mmcmd_replay) = '1' OR mm_cmd_in(c_mmcmd_ack) = '1' ) ELSE '0';
    mm2s_sts_tready_out <= '1' WHEN state = s_complete AND NOT ( mm_cmd_in(c_mmcmd_nackt) = '1' OR mm_cmd_in(c_mmcmd_nackp) = '1' OR mm_cmd_in(c_mmcmd_replay) = '1' OR mm_cmd_in(c_mmcmd_ack) = '1' ) ELSE '0';

END rtl;
