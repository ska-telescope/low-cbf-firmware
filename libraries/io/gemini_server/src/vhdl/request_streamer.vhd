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
--      The Request Streamer module is responsible for the following:
--              1) Streaming data from the Client Request Buffer RAM to
--                   the S2MM module for write requests.
--              2) Converting data width
--   
-- Remarks:
--      This version only supports data width conversion from N to N/2

LIBRARY IEEE, common_lib, technology_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;

ENTITY request_streamer IS
    GENERIC (
        g_technology: t_technology;
        g_crqbaddr_w : NATURAL;
        g_crqb_len : NATURAL;  -- Length of CRQB RAM in 64bit word units
        g_nregs_w : NATURAL;
        g_clnt_addr_w : NATURAL;
        g_data_w : NATURAL;
        g_mm_data_w : NATURAL; -- Must be g_data_w/2
        g_crqb_ram_rd_latency : NATURAL -- CRQB RAM read latency
    );
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        -- Interface: MM Transaction Controller
        mm_start_in : IN STD_LOGIC; -- Start streaming operation
        mm_nregs_in : IN STD_LOGIC_VECTOR(g_nregs_w-1 DOWNTO 0);  -- Length of CRQB frame register payload in 32bit word units
        mm_crqbaddr_in : IN STD_LOGIC_VECTOR(g_crqbaddr_w-1 DOWNTO 0); -- Base address of CRQB frame
        -- Interface: Client Request Buffer RAM
        -- Assume 2 clock read latency
        crqb_data_in : IN STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
        crqb_addr_out : OUT STD_LOGIC_VECTOR(g_crqbaddr_w-1 DOWNTO 0);
        -- Interface: Response Encoder
        clnt_addr_mac_out : OUT STD_LOGIC_VECTOR(g_clnt_addr_w-1 DOWNTO 0);
        clnt_addr_ipudp_out : OUT STD_LOGIC_VECTOR(g_clnt_addr_w-1 DOWNTO 0);
        -- Interface: S2MM streaming data
        s2mm_tdata_out : OUT STD_LOGIC_VECTOR ( g_mm_data_w-1 DOWNTO 0 );
        s2mm_tkeep_out : OUT STD_LOGIC_VECTOR ( g_mm_data_w/8-1 DOWNTO 0 );
        s2mm_tlast_out : OUT STD_LOGIC;
        s2mm_tready_in : IN STD_LOGIC;
        s2mm_tvalid_out : OUT STD_LOGIC;
        -- debug
        state_out : out std_logic_vector(3 downto 0)
    );
END request_streamer;

ARCHITECTURE rtl OF request_streamer IS

    CONSTANT c_fifo_w : INTEGER := g_mm_data_w + 1;
    CONSTANT c_fifo_len : INTEGER := 16;
    CONSTANT c_fifo_full_len : INTEGER := 11; --c_fifo_len - 2 * g_crqb_ram_rd_latency; 

    TYPE t_state_enum IS ( s_wait_start, s_hdr1, s_hdr2, s_payload_low, s_payload_high );

    SIGNAL state : t_state_enum;
    SIGNAL nregs : UNSIGNED(g_nregs_w-1 DOWNTO 0);
    SIGNAL s2mm_rst : STD_LOGIC;
    SIGNAL crqb_addr : UNSIGNED(g_crqbaddr_w-1 DOWNTO 0);
    SIGNAL crqb_rd : STD_LOGIC;
    SIGNAL crqb_high_rd : STD_LOGIC;
    SIGNAL crqb_low_rd : STD_LOGIC;
    SIGNAL crqb_data_valid : STD_LOGIC;
    SIGNAL crqb_low_rd_dly : t_sl_arr(1 TO g_crqb_ram_rd_latency);
    SIGNAL crqb_high_rd_dly : t_sl_arr(1 TO g_crqb_ram_rd_latency);
    SIGNAL crqb_last_dly : t_sl_arr(1 TO g_crqb_ram_rd_latency);
    SIGNAL crqb_hdr1_dly : t_sl_arr(1 TO g_crqb_ram_rd_latency);
    SIGNAL crqb_hdr2_dly : t_sl_arr(1 TO g_crqb_ram_rd_latency);
    SIGNAL fifo_wr_data : STD_LOGIC_VECTOR(c_fifo_w-1 DOWNTO 0);
    SIGNAL fifo_rd_data : STD_LOGIC_VECTOR(c_fifo_w-1 DOWNTO 0);
    SIGNAL fifo_wr : STD_LOGIC;
    SIGNAL fifo_rd : STD_LOGIC;
    SIGNAL fifo_full : STD_LOGIC;
    SIGNAL fifo_empty : STD_LOGIC;

BEGIN

    ctrl_p : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF rst = '1' THEN
                state <= s_wait_start;
                crqb_low_rd_dly <= (others=>'0');
                crqb_high_rd_dly <= (others=>'0');
                s2mm_rst <= '1';
            ELSE

                s2mm_rst <= '0';
                crqb_low_rd_dly <= crqb_low_rd & crqb_low_rd_dly(crqb_low_rd_dly'left TO crqb_low_rd_dly'right-1);
                crqb_high_rd_dly <= crqb_high_rd & crqb_high_rd_dly(crqb_high_rd_dly'left TO crqb_high_rd_dly'right-1);
                crqb_last_dly <= '0' & crqb_last_dly(crqb_last_dly'left TO crqb_last_dly'right-1);
                crqb_hdr1_dly <= '0' & crqb_hdr1_dly(crqb_hdr1_dly'left TO crqb_hdr1_dly'right-1);
                crqb_hdr2_dly <= '0' & crqb_hdr2_dly(crqb_hdr2_dly'left TO crqb_hdr2_dly'right-1);
                    
                IF crqb_rd = '1' THEN
                    IF crqb_addr = TO_UNSIGNED(g_crqb_len-1,crqb_addr'length) THEN
                        crqb_addr <= (others=>'0');
                    ELSE
                        crqb_addr <= crqb_addr + TO_UNSIGNED(1,crqb_addr'length);
                    END IF;
                END IF;
                                                     
                CASE state IS
                    WHEN s_wait_start =>
                        state_out <= "0000";
                        nregs <= UNSIGNED(mm_nregs_in); 
                        crqb_addr <= UNSIGNED(mm_crqbaddr_in);
                        IF mm_start_in = '1' THEN
                            state <= s_hdr1;
                        END IF;
                    WHEN s_hdr1 =>
                        state_out <= "0001";
                        state <= s_hdr2;
                        crqb_hdr1_dly(crqb_hdr1_dly'left) <= '1';
                    WHEN s_hdr2 =>
                        state <= s_payload_low;
                        state_out <= "0010";
                        IF nregs = TO_UNSIGNED(0,nregs'length) THEN
                            state <= s_wait_start;
                        END IF;
                        crqb_hdr2_dly(crqb_hdr2_dly'left) <= '1';
                    WHEN s_payload_low =>
                        state_out <= "0011";
                        IF fifo_full = '0' AND nregs = TO_UNSIGNED(1,nregs'length) THEN
                            state <= s_wait_start;
                            crqb_last_dly(crqb_last_dly'left) <= '1';
                        ELSIF fifo_full = '0' THEN
                            state <= s_payload_high;
                            nregs <= nregs - TO_UNSIGNED(1,nregs'length);
                        END IF;
                    WHEN s_payload_high =>
                        state_out <= "0100";
                        IF fifo_full = '0' AND nregs = TO_UNSIGNED(1,nregs'length) THEN
                            state <= s_wait_start;
                            crqb_last_dly(crqb_last_dly'left) <= '1';
                        ELSIF fifo_full = '0' THEN
                            state <= s_payload_low;                
                            nregs <= nregs - TO_UNSIGNED(1,nregs'length);
                        END IF;
                END CASE;
                           
            END IF;
        END IF;
    END PROCESS ctrl_p;
    
    crqb_addr_out <= STD_LOGIC_VECTOR(crqb_addr);
    crqb_rd <= '1' WHEN state=s_hdr1 OR state=s_hdr2 OR crqb_high_rd = '1' ELSE '0';
    crqb_low_rd <= NOT fifo_full WHEN state=s_payload_low ELSE '0';
    crqb_high_rd <= NOT fifo_full WHEN state=s_payload_high ELSE '0';
    crqb_data_valid <= crqb_low_rd_dly(g_crqb_ram_rd_latency) OR crqb_high_rd_dly(g_crqb_ram_rd_latency);

    data_p : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            fifo_wr <= crqb_data_valid;
            IF crqb_high_rd_dly(g_crqb_ram_rd_latency) = '1' THEN
                fifo_wr_data(g_mm_data_w-1 DOWNTO 0) <= crqb_data_in(2*g_mm_data_w-1 DOWNTO g_mm_data_w);
            ELSE
                fifo_wr_data(g_mm_data_w-1 DOWNTO 0) <= crqb_data_in(g_mm_data_w-1 DOWNTO 0);
            END IF; 
            fifo_wr_data(g_mm_data_w) <= crqb_last_dly(g_crqb_ram_rd_latency); 
            IF crqb_hdr1_dly(g_crqb_ram_rd_latency) = '1' THEN
                clnt_addr_mac_out <= crqb_data_in(g_clnt_addr_w-1 DOWNTO 0);
                fifo_wr <= '0';
            END IF;
            IF crqb_hdr2_dly(g_crqb_ram_rd_latency) = '1' THEN
                clnt_addr_ipudp_out <= crqb_data_in(g_clnt_addr_w-1 DOWNTO 0);
                fifo_wr <= '0';
            END IF;
        END IF;
    END PROCESS data_p;

    u_s2mm_fifo : ENTITY common_lib.common_fifo_sc
        GENERIC MAP (
            g_technology=> g_technology,
            g_dat_w     => c_fifo_w,
            g_nof_words => c_fifo_len,
            g_prog_full_thresh => c_fifo_full_len,
            g_fifo_latency => 0 ) 
        PORT MAP (
            rst => s2mm_rst,
            clk => clk,
            wr_dat => fifo_wr_data,
            wr_req => fifo_wr,
            wr_prog_ful => fifo_full,
            rd_dat => fifo_rd_data,
            rd_req => fifo_rd,
            rd_emp => fifo_empty );
        
    fifo_rd <= s2mm_tready_in;
    s2mm_tvalid_out <= NOT fifo_empty;
    s2mm_tdata_out <= fifo_rd_data(g_mm_data_w-1 DOWNTO 0);
    s2mm_tlast_out <= fifo_rd_data(g_mm_data_w); 
    s2mm_tkeep_out <= (others=>'1'); -- Only fixed width AXI transfers supported

END rtl;
