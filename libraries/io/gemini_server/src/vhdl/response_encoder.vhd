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

-- Purpose:
--      The Response Encoder module is responsible for the following:
--          1) Writing the CRSB frame into the CRSB RAM. The frame contains the Gemini
--               Protocol response PDU inc all addressing info.
--          2) Read register payload data width conversion from the MM bus.
--          3) Supplying client address information to the Response Streaming module.
--
-- Remarks:
--      The MM2S is expected to be programmed to provide exactly mm_len_in words
--        of payload for the response PDU. This module protects against MM overruns
--        by only writing a maximum of mm_len_in payload words.

LIBRARY IEEE, gemini_server_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE gemini_server_lib.gemini_server_pkg.ALL;

ENTITY response_encoder IS
   GENERIC (
      g_max_nregs : NATURAL;
      g_key_w : NATURAL;
      g_max_pipeline : NATURAL;
      g_data_w : NATURAL;
      g_mm_data_w : NATURAL;
      g_clnt_addr_w : NATURAL;
      g_crsb_addr_w : NATURAL
   );
   PORT (
      clk                  : IN STD_LOGIC;
      rst                  : IN STD_LOGIC;

      -- Interface: MM Transaction Controller
      mm_start_in          : IN STD_LOGIC;
      mm_csn_in            : IN STD_LOGIC_VECTOR(c_gempro_csn_w-1 DOWNTO 0);
      mm_nregs_in          : IN STD_LOGIC_VECTOR(c_gempro_nreg_w-1 DOWNTO 0); -- Number of 32bit registers included in payload
      mm_connect_in        : IN STD_LOGIC;
      mm_key_in            : IN STD_LOGIC_VECTOR(g_key_w-1 DOWNTO 0);
      mm_crsb_addr_in      : IN STD_LOGIC_VECTOR(g_crsb_addr_w-1 DOWNTO 0);
      mm_crsb_low_addr_in  : IN STD_LOGIC_VECTOR(g_crsb_addr_w-1 DOWNTO 0);
      mm_crsb_high_addr_in : IN STD_LOGIC_VECTOR(g_crsb_addr_w-1 DOWNTO 0);
      mm_complete_in       : IN STD_LOGIC;
      mm_cmd_in            : IN STD_LOGIC_VECTOR(c_gempro_cmd_w-1 DOWNTO 0); -- Valid when mm_complete_in = '1'
      mm_fc_in             : IN STD_LOGIC_VECTOR(c_gempro_fc_w-1 DOWNTO 0); -- Valid when mm_complete_in = '1'

      -- Interface: Client Response Buffer
      crsb_data_out        : OUT STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
      crsb_wr_out          : OUT STD_LOGIC;
      crsb_addr_out        : OUT STD_LOGIC_VECTOR(g_crsb_addr_w-1 DOWNTO 0);

      -- Interface: Request Streamer (Valid when mm_complete_in = '1')
      clnt_addr_mac_in     : IN STD_LOGIC_VECTOR(g_clnt_addr_w-1 DOWNTO 0);
      clnt_addr_ipudp_in   : IN STD_LOGIC_VECTOR(g_clnt_addr_w-1 DOWNTO 0);

      -- Interface: MM2S streamed data
      mm2s_tdata_in        : IN STD_LOGIC_VECTOR ( g_mm_data_w-1 DOWNTO 0 );
      mm2s_tkeep_in        : IN STD_LOGIC_VECTOR ( g_mm_data_w/8-1 DOWNTO 0 );
      mm2s_tlast_in        : IN STD_LOGIC;
      mm2s_tready_out      : OUT STD_LOGIC;
      mm2s_tvalid_in       : IN STD_LOGIC;
      mm2s_error           : IN STD_LOGIC;
      
      -- debug
      state_out : out std_logic_vector(3 downto 0)
   );
END response_encoder;

ARCHITECTURE rtl OF response_encoder IS

    TYPE t_state_enum IS ( s_wait_start, s_calc_addr, s_gemregs_first, s_gemregs_low, s_gemregs_high,
                            s_wait_complete, s_hdr1, s_hdr2, s_gemhdr1, s_gemhdr2, s_connect );

    SIGNAL state : t_state_enum;
    SIGNAL crsb_wr : STD_LOGIC;
    SIGNAL crsb_data : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    SIGNAL reg1 : STD_LOGIC_VECTOR(c_gempro_reg_w-1 DOWNTO 0);
    SIGNAL connect_reg2 : STD_LOGIC_VECTOR(c_gempro_reg_w-1 DOWNTO 0);
    SIGNAL connect_reg3 : STD_LOGIC_VECTOR(c_gempro_reg_w-1 DOWNTO 0);
    SIGNAL cmd : STD_LOGIC_VECTOR(c_gempro_cmd_w-1 DOWNTO 0);
    SIGNAL csn : STD_LOGIC_VECTOR(c_gempro_csn_w-1 DOWNTO 0);
    SIGNAL nregs : UNSIGNED(c_gempro_nreg_w-1 DOWNTO 0);
    SIGNAL connect : STD_LOGIC;
    SIGNAL fc : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL base_addr : UNSIGNED(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL addr : UNSIGNED(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL base_addr_plus_3 : UNSIGNED(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL base_addr_plus_4 : UNSIGNED(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL high_minus_low : UNSIGNED(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL low_addr : UNSIGNED(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL high_addr : UNSIGNED(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL clnt_addr_mac : STD_LOGIC_VECTOR(g_clnt_addr_w-1 DOWNTO 0);
    SIGNAL clnt_addr_ipudp : STD_LOGIC_VECTOR(g_clnt_addr_w-1 DOWNTO 0);
    SIGNAL mm2s_tdata : STD_LOGIC_VECTOR(g_mm_data_w-1 DOWNTO 0);
    SIGNAL mm2s_tvalid : STD_LOGIC;
    SIGNAL mm2s_tlast : STD_LOGIC;

    --ATTRIBUTE MARK_DEBUG : string;
    --ATTRIBUTE MARK_DEBUG OF state: SIGNAL IS "TRUE";
    --ATTRIBUTE MARK_DEBUG OF crsb_wr: SIGNAL IS "TRUE";
    --ATTRIBUTE MARK_DEBUG OF crsb_data: SIGNAL IS "TRUE";
    --ATTRIBUTE MARK_DEBUG OF addr: SIGNAL IS "TRUE";
    --ATTRIBUTE MARK_DEBUG OF mm2s_tdata: SIGNAL IS "TRUE";
    --ATTRIBUTE MARK_DEBUG OF mm2s_tvalid: SIGNAL IS "TRUE";
    --ATTRIBUTE MARK_DEBUG OF mm2s_tlast: SIGNAL IS "TRUE";
    --ATTRIBUTE MARK_DEBUG OF mm2s_tready_out: SIGNAL IS "TRUE";

BEGIN

    connect_reg2 <= STD_LOGIC_VECTOR(TO_UNSIGNED(g_max_pipeline,c_gempro_reg_w));
    connect_reg3(g_key_w-1 DOWNTO 0) <= mm_key_in;
    connect_reg3(c_gempro_reg_w-1 DOWNTO g_key_w) <= (others=>'0');

    p_main : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF rst = '1' THEN
                state <= s_wait_start;
                crsb_wr <= '0';
            ELSE

                crsb_wr <= '0';

                -- Register data inputs
                mm2s_tdata <= mm2s_tdata_in;
                mm2s_tvalid <= mm2s_tvalid_in;
                mm2s_tlast <= mm2s_tlast_in;


                IF crsb_wr = '1' AND addr = high_addr THEN
                    addr <= low_addr;
                ELSIF crsb_wr = '1' THEN
                    addr <= addr + TO_UNSIGNED(1,addr'length);
                END IF;

                CASE state IS
                    WHEN s_wait_start =>
                        state_out <= "0000";
                        csn <= mm_csn_in;
                        nregs <= UNSIGNED(mm_nregs_in);
                        connect <= mm_connect_in;
                        base_addr <= UNSIGNED(mm_crsb_addr_in);
                        low_addr <= UNSIGNED(mm_crsb_low_addr_in);
                        high_addr <= UNSIGNED(mm_crsb_high_addr_in);
                        IF mm_start_in = '1' THEN
                            state <= s_calc_addr;
                        END IF;
                    WHEN s_calc_addr =>
                        state_out <= "0001";
                        base_addr_plus_4 <= base_addr + TO_UNSIGNED(4,base_addr_plus_4'length);
                        base_addr_plus_3 <= base_addr + TO_UNSIGNED(3,base_addr_plus_3'length);
                        high_minus_low <= high_addr - low_addr;
                        state <= s_gemregs_first;
                        IF nregs = TO_UNSIGNED(0,nregs'length) THEN
                            state <= s_wait_complete;
                        END IF;
                    WHEN s_gemregs_first =>
                        -- Store first register value ready to write to CRSB RAM
                        -- in s_gemhdr2
                        state_out <= "0010";
                        addr <= base_addr_plus_4;
                        IF base_addr_plus_4 > high_addr THEN
                            addr <= base_addr_plus_3 - high_minus_low;
                        END IF;

                        reg1 <= mm2s_tdata;
                        IF connect = '1' THEN
                            state <= s_connect;
                        ELSIF (mm2s_tvalid = '1' AND mm2s_tlast = '1') OR mm2s_error = '1' THEN
                            state <= s_wait_complete;
                        ELSIF mm2s_tvalid = '1' THEN
                            state <= s_gemregs_low;
                        END IF;
                    WHEN s_gemregs_low =>
                        -- Write a register to the lower half of a CRSB word
                        state_out <= "0011";
                        crsb_data(g_mm_data_w-1 DOWNTO 0) <= mm2s_tdata;
                        IF (mm2s_tvalid = '1' AND mm2s_tlast = '1') OR mm2s_error = '1' THEN
                            crsb_wr <= '1';
                            state <= s_wait_complete;
                        ELSIF mm2s_tvalid = '1' THEN
                            state <= s_gemregs_high;
                        END IF;
                    WHEN s_gemregs_high =>
                        -- Write a register to the upper half of a CRSB word
                        state_out <= "0100";
                        crsb_data(2*g_mm_data_w-1 DOWNTO g_mm_data_w) <= mm2s_tdata;
                        crsb_wr <= mm2s_tvalid OR mm2s_error;
                        IF (mm2s_tvalid = '1' AND mm2s_tlast = '1') OR mm2s_error = '1' THEN
                            state <= s_wait_complete;
                        ELSIF mm2s_tvalid = '1' THEN
                            state <= s_gemregs_low;
                        END IF;
                    WHEN s_connect =>
                        -- Return Reg1: Maximum PDU payload length in units of registers
                        --        Reg2: Maximum pipeline length in units of PDUs
                        --        Reg3: Client connection identifier
                        state_out <= "0101";
                        reg1 <= STD_LOGIC_VECTOR(TO_UNSIGNED(g_max_nregs,c_gempro_reg_w));
                        crsb_data <= connect_reg3 & connect_reg2;
                        crsb_wr <= '1';
                        state <= s_wait_complete;
                    WHEN s_wait_complete =>
                        state_out <= "0110";
                        cmd <= mm_cmd_in;
                        fc <= mm_fc_in;
                        clnt_addr_mac <= clnt_addr_mac_in;
                        clnt_addr_ipudp <= clnt_addr_ipudp_in;
                        addr <= base_addr;
                        IF mm_complete_in = '1' THEN
                            state <= s_hdr1;
                        END IF;
                    WHEN s_hdr1 =>
                        -- Write the client MAC address
                        state_out <= "0111";
                        crsb_wr <= '1';
                        crsb_data(g_clnt_addr_w-1 DOWNTO 0) <= clnt_addr_mac;
                        crsb_data(g_clnt_addr_w+c_gempro_nreg_w-1 DOWNTO g_clnt_addr_w) <= STD_LOGIC_VECTOR(nregs);
                        state <= s_hdr2;
                    WHEN s_hdr2 =>
                        -- Write the client IP address and UDP port
                        state_out <= "1000";
                        crsb_wr <= '1';
                        crsb_data(g_clnt_addr_w-1 DOWNTO 0) <= clnt_addr_ipudp;
                        state <= s_gemhdr1;
                    WHEN s_gemhdr1 =>
                        -- First Gemini Protocol PDU header CRSB word
                        state_out <= "1001";
                        crsb_wr <= '1';
                        crsb_data <= x"0000000000" & csn & cmd & c_gemver;
                        state <= s_gemhdr2;
                    WHEN s_gemhdr2 =>
                        -- Second Gemini Protocol PDU header CRSB word
                        state_out <= "1010";
                        crsb_wr <= '1';
                        crsb_data <= reg1 & fc & STD_LOGIC_VECTOR(nregs);
                        state <= s_wait_start;
                END CASE;

                crsb_wr_out <= crsb_wr;
                crsb_data_out <= crsb_data;
                crsb_addr_out <= STD_LOGIC_VECTOR(addr);

            END IF;
        END IF;
    END PROCESS;

    mm2s_tready_out <= '1' WHEN state = s_calc_addr OR state = s_gemregs_first OR state = s_gemregs_low OR state = s_gemregs_high ELSE '0';

END rtl;
