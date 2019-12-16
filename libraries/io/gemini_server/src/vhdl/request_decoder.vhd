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
--      The Request Decoder module is responsible for:
--              1) Receiving Ethernet packet data through the ETHRX interface
--                   when becomes available.
--              2) Stripping MAC, IP and UDP headers from the received Ethernet
--                   packet data.
--              3) Validating the Gemini PDU header
--              4) Extracting Gemini PDU header fields for the S2MM and MM2S
--                   command words and control information for the MM Transaction
--                   Controller module.
--              5) Extracting client address and PDU payload register values.
--              6) Performing connection lookup
--
-- Remarks:
--      Assumes that connection_lookup module always returns a lookup_complete after every
--      lookup request.
--

LIBRARY IEEE, common_lib, gemini_server_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE gemini_server_lib.gemini_server_pkg.ALL;

ENTITY request_decoder IS
    GENERIC (
        g_data_w : NATURAL;
        g_noof_clnts : NATURAL;
        g_max_nregs : NATURAL;
        g_key_w : NATURAL;
        g_tod_w : NATURAL;
        g_crqb_len : NATURAL;
        g_crqb_addr_w : NATURAL;
        g_crqb_fifo_w : NATURAL;
        g_min_recycle_secs : NATURAL
    );
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        -- Interface: Time of Day with seconds resolution
        tod_in : IN STD_LOGIC_VECTOR(g_tod_w-1 DOWNTO 0);
        -- Interface: ETHRX AXI4S slave
        ethrx_tvalid_in : IN STD_LOGIC;
        ethrx_tready_out : OUT STD_LOGIC;
        ethrx_tdata_in : IN STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
        ethrx_tstrb_in : IN STD_LOGIC_VECTOR(g_data_w/8-1 DOWNTO 0);
        ethrx_tkeep_in : IN STD_LOGIC_VECTOR(g_data_w/8-1 DOWNTO 0);
        ethrx_tlast_in : IN STD_LOGIC;
        -- Interface: Client Request Buffer RAM
        crqb_wr_out : OUT STD_LOGIC;
        crqb_addr_out : OUT STD_LOGIC_VECTOR(g_crqb_addr_w-1 DOWNTO 0);
        crqb_data_out : OUT STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
        -- Interface: Client Request Buffer FIFOs
        crqb_fifo_wr_out : OUT STD_LOGIC_VECTOR(g_noof_clnts+1 DOWNTO 1);
        crqb_fifo_full_in : IN STD_LOGIC_VECTOR(g_noof_clnts+1 DOWNTO 1);
        crqb_fifo_data_out : OUT STD_LOGIC_VECTOR(g_crqb_fifo_w-1 DOWNTO 0);
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
        state_out : out std_logic_vector(3 downto 0)
    );
END;

ARCHITECTURE rtl OF request_decoder IS

    TYPE t_state_enum IS ( s_start, s_lookup, s_wait, s_last_before_complete, s_complete_before_last, s_last_and_complete );

    SIGNAL state : t_state_enum;
    SIGNAL data_reg : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    SIGNAL valid_reg : STD_LOGIC;
    SIGNAL last_reg : STD_LOGIC;
    SIGNAL hdr : STD_LOGIC_VECTOR(63 DOWNTO 8);
    SIGNAL request_word : UNSIGNED(ceil_log2((g_max_nregs+15)/2)-1 DOWNTO 0);
    SIGNAL lookup : STD_LOGIC;
    SIGNAL key : STD_LOGIC_VECTOR(g_key_w-1 DOWNTO 0);
    SIGNAL key_reg : STD_LOGIC_VECTOR(g_key_w-1 DOWNTO 0);
    SIGNAL key_reg_valid : STD_LOGIC;
    SIGNAL lookup_failed : STD_LOGIC;
    SIGNAL lookup_recycle : STD_LOGIC;
    SIGNAL lookup_complete : STD_LOGIC;
    SIGNAL mm_cmd : STD_LOGIC_VECTOR(c_mmcmd_w-1 DOWNTO 0);
    SIGNAL req_cmd : STD_LOGIC_VECTOR(c_gempro_cmd_w-1 DOWNTO 0);
    SIGNAL gem_ver : STD_LOGIC_VECTOR(c_gempro_ver_w-1 DOWNTO 0);
    SIGNAL clnt_addr : STD_LOGIC_VECTOR(47 DOWNTO 0);
    SIGNAL ready : STD_LOGIC;
    SIGNAL ready_reg : STD_LOGIC;
    SIGNAL payload_last : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL crqb_wr : STD_LOGIC;
    SIGNAL crqb_addr : UNSIGNED(g_crqb_addr_w-1 DOWNTO 0);
    SIGNAL crqb_frame_addr : UNSIGNED(g_crqb_addr_w-1 DOWNTO 0);
    SIGNAL crqb_data : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    SIGNAL crqb_fifo_wr : STD_LOGIC;
    SIGNAL udp_len : UNSIGNED(15 DOWNTO 0);
    SIGNAL wr_len_check : UNSIGNED(udp_len'left-2 DOWNTO 0);
    SIGNAL request_valid : STD_LOGIC;
    SIGNAL req_connect : STD_LOGIC;
    SIGNAL req_read : STD_LOGIC;
    SIGNAL req_write : STD_LOGIC;
    SIGNAL mm_cmd_valid : STD_LOGIC;

BEGIN

    p_main: PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF rst = '1' THEN
                crqb_wr <= '0';
                crqb_wr_out <= '0';
                crqb_fifo_wr <= '0';
                lookup <= '0';
                request_word <= TO_UNSIGNED(1,request_word'length);
                crqb_addr <= (others=>'0');
            ELSE

                -- Register the inputs
                data_reg <= ethrx_tdata_in;
                valid_reg <= ethrx_tvalid_in;
                last_reg <= ethrx_tlast_in;

                lookup <= '0';
                crqb_wr <= '0';
                crqb_fifo_wr <= '0';
                ready_reg <= ready;

                IF crqb_wr = '1' AND crqb_addr = TO_UNSIGNED(g_crqb_len-1,crqb_addr'length) THEN
                    crqb_addr <= (others=>'0');
                ELSIF crqb_wr = '1' THEN
                    crqb_addr <= crqb_addr + TO_UNSIGNED(1,crqb_addr'length);
                END IF;

                -- Request validation checks
                IF mm_cmd_valid = '1' THEN

                    -- For write commands then GemNRegs = UDPLen/4 - 5, otherwise UDPLen = 20
                    IF mm_cmd(c_mmcmd_write) = '1' AND wr_len_check /= TO_UNSIGNED(5,wr_len_check'length) THEN
                        request_valid <= '0';
                    ELSIF mm_cmd(c_mmcmd_write) = '0' AND udp_len /= TO_UNSIGNED(20, udp_len'length) THEN
                        request_valid <= '0';
                    END IF;

                    -- Check Gemini Protocol version
                    IF gem_ver /= c_gemver THEN
                        request_valid <= '0';
                    END IF;

                    -- Check max nregs that will fit into MTU
                    IF UNSIGNED(hdr(29 DOWNTO 16)) > TO_UNSIGNED(g_max_nregs,14) THEN
                        request_valid <= '0';
                    END IF;

                END IF;

                -- Pick the useful bits out of a Gemini request
                IF valid_reg = '1' AND ready_reg = '1' THEN

                    request_word <= request_word + TO_UNSIGNED(1,request_word'length);
                    IF last_reg = '1' THEN
                        request_word <= TO_UNSIGNED(1,request_word'length);
                    END IF;

                    CASE TO_INTEGER(request_word) IS
                        WHEN 1 =>
                            crqb_data(15 DOWNTO 0) <= data_reg(63 DOWNTO 48);
                        WHEN 2 =>
                            crqb_data(63 DOWNTO 16) <= x"0000" & data_reg(31 DOWNTO 0);
                            crqb_wr <= '1';
                        WHEN 3 =>
                            null;
                        WHEN 4 =>
                            clnt_addr(31 DOWNTO 0) <= data_reg(47 DOWNTO 16);  -- IPSrc
                            crqb_data(31 DOWNTO 0) <= data_reg(47 DOWNTO 16);  -- IPSrc
                        WHEN 5 =>
                            clnt_addr(47 DOWNTO 32) <= data_reg(31 DOWNTO 16); -- UDPSrcPt
                            crqb_data(63 DOWNTO 32) <= x"0000" & data_reg(31 DOWNTO 16); -- UDPSrcPt
                            udp_len <= UNSIGNED(data_reg(55 DOWNTO 48)) & UNSIGNED(data_reg(63 DOWNTO 56));
                            crqb_wr <= '1';
                        WHEN 6 =>
                            req_cmd <= data_reg(31 DOWNTO 24); -- GemCmd
                            gem_ver <= data_reg(23 DOWNTO 16); -- GemVer
                            hdr(15 DOWNTO 8) <= data_reg(39 DOWNTO 32); -- GemCSN
                            hdr(47 DOWNTO 32) <= data_reg(63 DOWNTO 48); -- GemAddr<15:0>
                        WHEN 7 =>
                            hdr(63 DOWNTO 48) <= data_reg(15 DOWNTO 0); -- GemAddr<31:16>
                            hdr(31 DOWNTO 16) <= "00" & data_reg(29 DOWNTO 16); -- GemNRegs (Top 2 bits must be 0 for valid UDPLen)
                            payload_last <= data_reg(63 DOWNTO 48); -- Gemini registers
                            wr_len_check <= udp_len(udp_len'left DOWNTO 2) - UNSIGNED(data_reg(29 DOWNTO 16)); -- UDPLen/4 - GemNRegs
                            request_valid <= '1';
                        WHEN OTHERS =>
                            crqb_data <= data_reg(47 DOWNTO 0) & payload_last;
                            payload_last <= data_reg(63 DOWNTO 48); -- Gemini registers
                            crqb_wr <= '1';
                    END CASE;

                END IF;

                -- Register outputs and deal with wrapping at the end of the CRQB RAM
                crqb_wr_out <= crqb_wr;
                crqb_data_out <= crqb_data;
                crqb_addr_out <= STD_LOGIC_VECTOR(crqb_addr);

                CASE state IS
                    WHEN s_start =>
                        -- Start of Gemini request packet
                        state_out <= "0000";
                        crqb_frame_addr <= crqb_addr;
                        mm_cmd_valid <= '0';
                        IF TO_INTEGER(request_word) = 2 THEN
                            state <= s_lookup;
                        END IF;
                    WHEN s_lookup =>
                        state_out <= "0001";
                        IF TO_INTEGER(request_word) = 5 THEN
                            state <= s_wait;
                            lookup <= '1';
                        END IF;
                    WHEN s_wait =>
                        -- Wait for last Gemini request word or lookup_complete
                        state_out <= "0010";
                        IF lookup_complete = '0' AND valid_reg = '1' AND ready_reg = '1' AND last_reg = '1' THEN
                            state <= s_last_before_complete;
                        ELSIF lookup_complete = '1' AND valid_reg = '1' AND ready_reg = '1' AND last_reg = '1' THEN
                            state <= s_last_and_complete;
                        ELSIF lookup_complete = '1' THEN
                            state <= s_complete_before_last;
                        END IF;
                    WHEN s_last_before_complete =>
                        -- Wait for lookup_complete
                        state_out <= "0011";
                        IF lookup_complete = '1' THEN
                            state <= s_last_and_complete;
                        END IF;
                    WHEN s_complete_before_last =>
                        -- Wait for last Gemini request word
                        state_out <= "0100";
                        IF valid_reg = '1' AND ready_reg = '1' AND last_reg = '1' THEN
                            state <= s_last_and_complete;
                        END IF;
                    WHEN s_last_and_complete =>
                        -- Push frame information word into crqb_fifo
                        state_out <= "0101";
                        crqb_fifo_wr <= '1';
                        state <= s_start;
                END CASE;

                -- Capture the output from the connection_lookup
                IF lookup_complete = '1' THEN
                    key_reg <= key;
                    key_reg_valid <= NOT lookup_failed;
                    mm_cmd_valid <= '1';
                    mm_cmd(c_mmcmd_w-1 DOWNTO c_mmcmd_read) <= (others=>'0');
                    IF req_connect = '1' AND lookup_failed = '1' THEN
                        mm_cmd(c_mmcmd_nackt) <= '1'; -- Failed connect
                    ELSIF lookup_failed = '1' THEN
                        --mm_cmd(c_mmcmd_nackp) <= '1';
                        request_valid <= '0';
                    ELSIF req_connect = '1' THEN
                        mm_cmd(c_mmcmd_connect) <= '1';
                    ELSIF req_read = '1' THEN
                        mm_cmd(c_mmcmd_read) <= '1';
                    ELSIF req_write = '1' THEN
                        mm_cmd(c_mmcmd_write) <= '1';
                    ELSE
                        --mm_cmd(c_mmcmd_nackp) <= '1';
                        request_valid <= '0';
                    END IF;
                END IF;

            END IF;
        END IF;
    END PROCESS;

    ready <= '0' WHEN state = s_last_before_complete ELSE '1';
    ethrx_tready_out <= ready;

    req_connect <= '1' WHEN req_cmd = c_gemreq_connect ELSE '0';
    req_read <= '1' WHEN req_cmd = c_gemreq_read_inc OR req_cmd = c_gemreq_read_rep ELSE '0';
    req_write <= '1' WHEN req_cmd = c_gemreq_write_inc OR req_cmd = c_gemreq_write_rep ELSE '0';

    crqb_fifo_data_out(g_crqb_fifo_w-1 DOWNTO g_crqb_addr_w+64) <= (others=>'0');
    crqb_fifo_data_out(g_crqb_addr_w+64-1 DOWNTO 64) <= STD_LOGIC_VECTOR(crqb_frame_addr);
    crqb_fifo_data_out(63 DOWNTO 8) <= hdr(63 DOWNTO 8);
    crqb_fifo_data_out(c_mmcmd_w-1) <= '0'; -- Unused mmcmd bit
    crqb_fifo_data_out(c_mmcmd_nackp) <= NOT request_valid;
    crqb_fifo_data_out(c_mmcmd_nackp-1 DOWNTO c_mmcmd_read) <= mm_cmd(c_mmcmd_nackp-1 DOWNTO c_mmcmd_read);
    crqb_fifo_data_out(c_mmcmd_type) <= req_cmd(0); -- S2MM/MM2S type field

    gen_crqb_fifo_wr_out : FOR B IN 1 TO g_noof_clnts GENERATE
        crqb_fifo_wr_out(B) <= crqb_fifo_wr WHEN TO_INTEGER(UNSIGNED(key_reg)) = B-1 AND key_reg_valid='1' ELSE '0';
    END GENERATE;
    crqb_fifo_wr_out(g_noof_clnts+1) <= crqb_fifo_wr WHEN key_reg_valid='0' ELSE '0';

    u_lookup : ENTITY gemini_server_lib.connection_lookup
    GENERIC MAP (
        g_clnt_addr_w => clnt_addr'length,
        g_noof_clnts  => g_noof_clnts,
        g_key_w => g_key_w,
        g_tod_w => g_tod_w,
        g_min_recycle_secs => g_min_recycle_secs
    )
    PORT MAP (
        rst          => rst,
        clk           => clk,
        lookup_in     => lookup,
        tod_in        => tod_in,
        clnt_addr_in  => clnt_addr,
        connect_in    => req_connect,
        key_out       => key,
        failed_out    => lookup_failed,
        recycle_out   => lookup_recycle,
        complete_out  => lookup_complete,
        -- status signals to send to the register interface
        client0IP => client0IP, -- : out std_logic_vector(31 downto 0);
        client0Port => client0Port, -- : out std_logic_vector(15 downto 0);
        client0LastUsed => client0LastUsed, -- : out std_logic_vector(g_tod_w-1 downto 0);
        client1IP => client1IP, --: out std_logic_vector(31 downto 0);
        client1Port => client1Port, --: out std_logic_vector(15 downto 0);
        client1LastUsed => client1LastUsed, -- : out std_logic_vector(g_tod_w-1 downto 0);
        client2IP  => client2IP, --out std_logic_vector(31 downto 0);
        client2Port => client2Port, --: out std_logic_vector(15 downto 0);
        client2LastUsed  => client2LastUsed --: out std_logic_vector(g_tod_w-1 downto 0)
    );

END rtl;
