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
--      The Response Streamer module is responsible for the following:
--          1) Streaming Ethernet packet data to the ETHTX interface when external
--               modules are ready.
--          2) Adding MAC, IP and UDP headers to Gemini PDU data
--          3) Updating the Gemini PDU header SSN field with the current value
--
-- Remarks:
--

LIBRARY IEEE, common_lib, technology_lib, gemini_server_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE gemini_server_lib.gemini_server_pkg.ALL;

ENTITY response_streamer IS
    GENERIC (
        g_technology: t_technology;
        g_data_w : NATURAL;
        g_crsb_addr_w : NATURAL;
        g_crsb_fifo_w : NATURAL;
        g_crsb_ram_rd_latency : NATURAL -- CRSB RAM read latency
    );
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        -- Interface: ETHTX AXI4S master
        ethtx_tvalid_out : OUT STD_LOGIC;
        ethtx_tready_in : IN STD_LOGIC;
        ethtx_tdata_out : OUT STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
        ethtx_tstrb_out : OUT STD_LOGIC_VECTOR(g_data_w/8-1 DOWNTO 0);
        ethtx_tkeep_out : OUT STD_LOGIC_VECTOR(g_data_w/8-1 DOWNTO 0);
        ethtx_tlast_out : OUT STD_LOGIC;
        -- Interface: Client Response Buffer FIFO
        crsb_fifo_data_in : IN STD_LOGIC_VECTOR(g_crsb_fifo_w-1 DOWNTO 0);
        crsb_fifo_rd_out : OUT STD_LOGIC;
        crsb_fifo_empty_in : IN STD_LOGIC;
        -- Interface: Client Request Buffer RAM
        crsb_data_in : IN STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
        crsb_addr_out : OUT STD_LOGIC_VECTOR(g_crsb_addr_w-1 DOWNTO 0)
    );
END response_streamer;

ARCHITECTURE rtl OF response_streamer IS

    CONSTANT ethtx_fifo_data_w : INTEGER := 73;
    CONSTANT ethtx_fifo_len : INTEGER := 16;
    CONSTANT ethtx_fifo_full_len : INTEGER := 7; --ethtx_fifo_len - g_crsb_ram_rd_latency - 3;

    TYPE t_pkthdr_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(g_data_w+8-1 DOWNTO 0);

    -- Template for Ethernet packet header
    -- Top 8 bits are used for control
    CONSTANT c_pkthdr_arr : t_pkthdr_arr(0 TO 6) := ( x"01_00_00_FF_FF_FF_FF_FF_FF",
                                                      x"10_00_45_00_08_00_00_00_00",
                                                      x"20_11_40_00_00_00_00_FF_FF",
                                                      x"30_FF_FF_00_00_00_00_00_00",
                                                      x"41_FF_FF_FF_FF_30_75_FF_FF",
                                                      x"51_00_00_00_00_00_00_00_00",
                                                      x"61_00_00_00_00_00_00_00_00" ); -- Just control bits used for last entry

    TYPE t_state_enum IS ( s_wait, s_pkthdr1, s_pkthdr, s_pdu, s_last );

    SIGNAL state : t_state_enum;
    SIGNAL crsb_ctrl_ssn : STD_LOGIC_VECTOR(c_gempro_ssn_w-1 DOWNTO 0);
    SIGNAL crsb_ctrl_addr : STD_LOGIC_VECTOR(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL crsb_ctrl_low_addr : STD_LOGIC_VECTOR(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL crsb_ctrl_high_addr : STD_LOGIC_VECTOR(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL ssn : STD_LOGIC_VECTOR(c_gempro_ssn_w-1 DOWNTO 0);
    SIGNAL crsb_rd : STD_LOGIC;
    SIGNAL pkthdr_rd : STD_LOGIC;
    SIGNAL nregs : UNSIGNED(c_gempro_nreg_w-1 DOWNTO 0);
    SIGNAL nregs_plus_3 : UNSIGNED(c_gempro_nreg_w-1 DOWNTO 0);
    SIGNAL nregs_plus_10 : UNSIGNED(c_gempro_nreg_w-1 DOWNTO 0);
    SIGNAL nregs_plus_5 : UNSIGNED(c_gempro_nreg_w-1 DOWNTO 0);
    SIGNAL len : UNSIGNED(c_gempro_nreg_w-2 DOWNTO 0);
    SIGNAL pdu_len : UNSIGNED(c_gempro_nreg_w-2 DOWNTO 0);
    SIGNAL crsb_addr : UNSIGNED(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL crsb_low_addr : UNSIGNED(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL crsb_high_addr : UNSIGNED(g_crsb_addr_w-1 DOWNTO 0);
    SIGNAL iptotlen : UNSIGNED(c_gempro_nreg_w-1 DOWNTO 0);
    SIGNAL htons_iptotlen : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL udplen : UNSIGNED(c_gempro_nreg_w-1 DOWNTO 0);
    SIGNAL htons_udplen : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL crsb_data : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    SIGNAL crsb_data_valid : t_sl_arr(1 TO g_crsb_ram_rd_latency+1);
    SIGNAL crsb_data_last : t_sl_arr(1 TO g_crsb_ram_rd_latency+1);
    SIGNAL ethtx_fifo_din : STD_LOGIC_VECTOR(ethtx_fifo_data_w-1 DOWNTO 0);
    SIGNAL ethtx_fifo_dout : STD_LOGIC_VECTOR(ethtx_fifo_data_w-1 DOWNTO 0);
    SIGNAL ethtx_fifo_wr : STD_LOGIC;
    SIGNAL ethtx_fifo_full : STD_LOGIC;
    SIGNAL ethtx_fifo_rd : STD_LOGIC;
    SIGNAL ethtx_fifo_empty : STD_LOGIC;
    SIGNAL crsb_last : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL pkthdr_addr : UNSIGNED(ceil_log2(c_pkthdr_arr'length)-1 DOWNTO 0);
    SIGNAL pkthdr_dly : t_pkthdr_arr(1 TO g_crsb_ram_rd_latency+1);
    SIGNAL pkthdr_data : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
    SIGNAL pkthdr_ctrl : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL align_last : STD_LOGIC;

    --ATTRIBUTE MARK_DEBUG : string;
    --ATTRIBUTE MARK_DEBUG OF state: SIGNAL IS "TRUE";
    --ATTRIBUTE MARK_DEBUG OF ethtx_fifo_din: SIGNAL IS "TRUE";
    --ATTRIBUTE MARK_DEBUG OF ethtx_fifo_wr: SIGNAL IS "TRUE";
    --ATTRIBUTE MARK_DEBUG OF ethtx_fifo_full: SIGNAL IS "TRUE";
    --ATTRIBUTE MARK_DEBUG OF pkthdr_ctrl: SIGNAL IS "TRUE";
    --ATTRIBUTE MARK_DEBUG OF crsb_last: SIGNAL IS "TRUE";
    --ATTRIBUTE MARK_DEBUG OF crsb_data: SIGNAL IS "TRUE";
    --ATTRIBUTE MARK_DEBUG OF crsb_data_valid: SIGNAL IS "TRUE";
    --ATTRIBUTE MARK_DEBUG OF crsb_rd: SIGNAL IS "TRUE";

BEGIN

    -- Client Response Buffer FIFO control word format
    crsb_ctrl_ssn <= crsb_fifo_data_in(c_gempro_ssn_w-1 DOWNTO 0);
    crsb_ctrl_addr <= crsb_fifo_data_in(8+g_crsb_addr_w-1 DOWNTO 8);
    crsb_ctrl_low_addr <= crsb_fifo_data_in(8+24+g_crsb_addr_w-1 DOWNTO 8+24);
    crsb_ctrl_high_addr <= crsb_fifo_data_in(8+2*24+g_crsb_addr_w-1 DOWNTO 8+2*24);

    nregs_plus_3 <= nregs + TO_UNSIGNED(3,nregs_plus_3'length);
    nregs_plus_10 <= nregs + TO_UNSIGNED(10,nregs_plus_10'length);
    nregs_plus_5 <= nregs + TO_UNSIGNED(5,nregs_plus_5'length);

    p_ctrl : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF rst = '1' THEN
                state <= s_wait;
                crsb_data_valid <= (others=>'0');
                crsb_fifo_rd_out <= '0';
            ELSE

                IF crsb_rd = '1' AND crsb_addr = crsb_high_addr THEN
                    crsb_addr <= crsb_low_addr;
                ELSIF crsb_rd = '1' THEN
                    crsb_addr <= crsb_addr + TO_UNSIGNED(1,crsb_addr'length);
                END IF;

                crsb_data_valid <= ( crsb_rd OR pkthdr_rd ) & crsb_data_valid(crsb_data_valid'left TO crsb_data_valid'right-1);
                crsb_data_last <= '0' & crsb_data_last(crsb_data_last'left TO crsb_data_last'right-1);

                -- Delay pkthdr data to match reads from CRSB
                pkthdr_dly(pkthdr_dly'left) <= c_pkthdr_arr(TO_INTEGER(pkthdr_addr));
                FOR I IN pkthdr_dly'left+1 TO pkthdr_dly'right LOOP
                    pkthdr_dly(I) <= pkthdr_dly(I-1);
                END LOOP;

                crsb_fifo_rd_out <= '0';

                CASE state IS
                    WHEN s_wait =>
                        ssn <= crsb_ctrl_ssn;
                        crsb_addr <= UNSIGNED(crsb_ctrl_addr);
                        crsb_low_addr <= UNSIGNED(crsb_ctrl_low_addr);
                        crsb_high_addr <= UNSIGNED(crsb_ctrl_high_addr);
                        pkthdr_addr <= (others=>'0');
                        IF crsb_fifo_empty_in = '0' THEN
                            state <= s_pkthdr1;
                            crsb_fifo_rd_out <= '1';
                        END IF;
                    WHEN s_pkthdr1 =>
                        IF ethtx_fifo_full = '0' THEN
                            pkthdr_addr <= TO_UNSIGNED(1,pkthdr_addr'length);
                            state <= s_pkthdr;
                        END IF;
                    WHEN s_pkthdr =>
                        IF ethtx_fifo_full = '0' THEN
                            pkthdr_addr <= pkthdr_addr + TO_UNSIGNED(1,pkthdr_addr'length);
                            IF TO_INTEGER(pkthdr_addr) = c_pkthdr_arr'length-2 THEN
                                pdu_len <= len;
                                state <= s_pdu;
                            END IF;
                        END IF;
                    WHEN s_pdu =>
                        IF ethtx_fifo_full = '0' AND pdu_len = TO_UNSIGNED(1,len'length) THEN
                            crsb_data_last(crsb_data_last'left) <= '1';
                            state <= s_last;
                        ELSIF ethtx_fifo_full = '0' THEN
                            pdu_len <= pdu_len - TO_UNSIGNED(1,pdu_len'length);
                        END IF;
                    WHEN s_last =>
                        IF crsb_data_last(crsb_data_last'right) = '1' THEN
                            state <= s_wait;
                        END IF;
                END CASE;

                crsb_data <= crsb_data_in;

            END IF;
        END IF;
    END PROCESS;

    crsb_rd <= '1' WHEN ( state = s_pdu OR state = s_pkthdr1 OR state = s_pkthdr ) AND ethtx_fifo_full = '0' AND c_pkthdr_arr(TO_INTEGER(pkthdr_addr))(g_data_w) = '1' ELSE '0';
    pkthdr_rd <= '1' WHEN ( state = s_pkthdr1 OR state = s_pkthdr ) AND ethtx_fifo_full = '0' ELSE '0';

    crsb_addr_out <= STD_LOGIC_VECTOR(crsb_addr);
    htons_iptotlen <= STD_LOGIC_VECTOR(iptotlen(7 DOWNTO 0)) & STD_LOGIC_VECTOR(iptotlen(15 DOWNTO 8)); -- Assumes c_gempro_nreg_w = 16
    htons_udplen <= STD_LOGIC_VECTOR(udplen(7 DOWNTO 0)) & STD_LOGIC_VECTOR(udplen(15 DOWNTO 8)); -- Assumes c_gempro_nreg_w = 16

    -- Separate the control and data from the pkthdr word
    pkthdr_data <= pkthdr_dly(pkthdr_dly'right)(g_data_w-1 DOWNTO 0);
    pkthdr_ctrl <= pkthdr_dly(pkthdr_dly'right)(g_data_w+8-1 DOWNTO g_data_w);

    p_data : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN

            CASE pkthdr_ctrl(7 DOWNTO 4) IS
                WHEN "0000" =>
                    ethtx_fifo_din(g_data_w-1 DOWNTO 0) <= pkthdr_data(63 DOWNTO 48) & crsb_data(47 DOWNTO 0); -- dstMac
                    nregs <= UNSIGNED(crsb_data(48+nregs'length-1 DOWNTO 48));
                WHEN "0001" =>
                    ethtx_fifo_din(g_data_w-1 DOWNTO 0) <= pkthdr_data;
                WHEN "0010" =>
                    ethtx_fifo_din(g_data_w-1 DOWNTO 0) <= pkthdr_data(63 DOWNTO 16) & htons_iptotlen;
                WHEN "0011" =>
                    ethtx_fifo_din(g_data_w-1 DOWNTO 0) <= crsb_data(15 DOWNTO 0) & pkthdr_data(47 DOWNTO 0); -- DstIPAddr
                WHEN "0100" =>
                    ethtx_fifo_din(g_data_w-1 DOWNTO 0) <= htons_udplen & crsb_data(47 DOWNTO 32) & pkthdr_data(31 DOWNTO 16) & crsb_data(31 DOWNTO 16); -- DstIPAddr & DstUDPPort
                WHEN "0101" =>
                    ethtx_fifo_din(g_data_w-1 DOWNTO 0) <= crsb_data(47 DOWNTO 0) & x"00_00";
                    ethtx_fifo_din(47 DOWNTO 40) <= ssn;
                WHEN OTHERS =>
                    ethtx_fifo_din(g_data_w-1 DOWNTO 0) <= crsb_data(47 DOWNTO 0) & crsb_last;
            END CASE;

            IF crsb_data_valid(crsb_data_valid'right) = '1' THEN
                crsb_last <= crsb_data(63 DOWNTO 48);
            END IF;

            -- Length of PDU, without first 64bits of PDU header, in Ethernet packet (in CRSB word units) = floor((nregs+3)/2)
            len <= nregs_plus_3(nregs_plus_3'left DOWNTO 1);

            -- tkeep option for last CRSB frame word
            align_last <= nregs(0);
            -- Calculate IPTotLen = (nregs+10)*4 bytes
            iptotlen <= nregs_plus_10(nregs_plus_10'left-2 DOWNTO 0) & "00";
            -- Calculate UDPLen = (nregs+5)*4 bytes
            udplen <= nregs_plus_5(nregs_plus_5'left-2 DOWNTO 0) & "00";

            ethtx_fifo_din(g_data_w+g_data_w/8) <= crsb_data_last(crsb_data_last'right); -- tlast

            -- Calculate TKEEP from align_last
            IF crsb_data_last(crsb_data_last'right) = '1' AND align_last = '0' THEN
                ethtx_fifo_din(g_data_w+g_data_w/8-1 DOWNTO g_data_w) <= "00111111";
            ELSIF crsb_data_last(crsb_data_last'right) = '1' AND align_last = '1' THEN
                ethtx_fifo_din(g_data_w+g_data_w/8-1 DOWNTO g_data_w) <= "00000011";
            ELSE
                ethtx_fifo_din(g_data_w+g_data_w/8-1 DOWNTO g_data_w) <= (others=>'1');
            END IF;

            ethtx_fifo_wr <= crsb_data_valid(crsb_data_valid'right);

        END IF;
    END PROCESS;

    u_ethtx_fifo : ENTITY common_lib.common_fifo_sc
    GENERIC MAP (
        g_technology=> g_technology,
        g_dat_w     => ethtx_fifo_data_w,
        g_nof_words => ethtx_fifo_len,
        g_prog_full_thresh => ethtx_fifo_full_len,
        g_fifo_latency => 0 )
    PORT MAP (
        rst => rst,
        clk => clk,
        wr_dat => ethtx_fifo_din,
        wr_req => ethtx_fifo_wr,
        wr_prog_ful => ethtx_fifo_full,
        rd_dat => ethtx_fifo_dout,
        rd_req => ethtx_fifo_rd,
        rd_emp => ethtx_fifo_empty );

    ethtx_fifo_rd <= ethtx_tready_in;
    ethtx_tvalid_out <= NOT ethtx_fifo_empty;
    ethtx_tdata_out <= ethtx_fifo_dout(g_data_w-1 DOWNTO 0);
    ethtx_tstrb_out <= (others=>'1');
    ethtx_tkeep_out <= ethtx_fifo_dout(g_data_w+g_data_w/8-1 DOWNTO g_data_w);
    ethtx_tlast_out <= ethtx_fifo_dout(g_data_w+g_data_w/8);

END rtl;

