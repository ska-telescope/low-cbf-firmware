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


-- Purpose: Testbench for Request Streamer module
-- Description:
--

LIBRARY IEEE, gemini_server_lib, technology_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_textio.ALL;
USE technology_lib.technology_pkg.ALL;

LIBRARY STD;
USE STD.textio.ALL;

ENTITY tb_request_streamer IS
END tb_request_streamer;

ARCHITECTURE tb OF tb_request_streamer IS

    CONSTANT c_clk_period : TIME := 10 ns;
    CONSTANT c_data_w : NATURAL := 16;
    CONSTANT c_mm_data_w : NATURAL := 8;
    CONSTANT c_crqb_len : NATURAL := 7;
    CONSTANT c_crqbaddr_w : NATURAL := 4;
    CONSTANT c_clnt_addr_w : NATURAL := 8;
    CONSTANT c_nregs_w : NATURAL := 4;

    TYPE t_data_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);
    TYPE t_mm_data_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_mm_data_w-1 DOWNTO 0);

    TYPE t_test IS RECORD
        nregs : NATURAL;
        addr : NATURAL RANGE 0 TO c_crqb_len-1;
        mac : STD_LOGIC_VECTOR(c_clnt_addr_w-1 DOWNTO 0);
        ipudp : STD_LOGIC_VECTOR(c_clnt_addr_w-1 DOWNTO 0);
        tdata : t_mm_data_arr(1 TO 5);
    END RECORD t_test;

    TYPE t_test_vec IS ARRAY (INTEGER RANGE <>) OF t_test;
    CONSTANT c_test_vec : t_test_vec(1 TO 6) := (

            ( nregs => 0, addr => 2, mac => x"F6", ipudp => x"F0", tdata => ( x"00", x"00", x"00", x"00", x"00" ) ),
            ( nregs => 1, addr => 1, mac => x"73", ipudp => x"F6", tdata => ( x"F0", x"00", x"00", x"00", x"00" ) ),
            ( nregs => 2, addr => 0, mac => x"52", ipudp => x"73", tdata => ( x"F6", x"C5", x"00", x"00", x"00" ) ),
            ( nregs => 3, addr => 1, mac => x"73", ipudp => x"F6", tdata => ( x"F0", x"33", x"80", x"00", x"00" ) ),
            ( nregs => 1, addr => 6, mac => x"EF", ipudp => x"52", tdata => ( x"73", x"00", x"00", x"00", x"00" ) ),
            ( nregs => 4, addr => 4, mac => x"80", ipudp => x"07", tdata => ( x"EF", x"03", x"52", x"31", x"00" ) )

    );

    SIGNAL rst : STD_LOGIC;
    SIGNAL clk : STD_LOGIC := '1';
    SIGNAL crqb_mem : t_data_arr(0 TO c_crqb_len-1) := ( x"3152", x"1373", x"C5F6", x"33F0", x"4080", x"0F07", x"03EF" );
    SIGNAL tb_end : STD_LOGIC := '0';
    SIGNAL mm_start : STD_LOGIC;
    SIGNAL mm_nregs : STD_LOGIC_VECTOR(c_nregs_w-1 DOWNTO 0);
    SIGNAL mm_addr : STD_LOGIC_VECTOR(c_crqbaddr_w-1 DOWNTO 0);
    SIGNAL crqb_data : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);
    SIGNAL mem_dly : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);
    SIGNAL crqb_addr : STD_LOGIC_VECTOR(c_crqbaddr_w-1 DOWNTO 0);
    SIGNAL s2mm_tdata : STD_LOGIC_VECTOR ( c_mm_data_w-1 DOWNTO 0 );
    SIGNAL s2mm_tkeep : STD_LOGIC_VECTOR ( c_mm_data_w/8-1 DOWNTO 0 );
    SIGNAL s2mm_tlast : STD_LOGIC;
    SIGNAL s2mm_tready : STD_LOGIC;
    SIGNAL s2mm_tvalid : STD_LOGIC;
    SIGNAL clnt_addr_mac : STD_LOGIC_VECTOR(c_clnt_addr_w-1 DOWNTO 0);
    SIGNAL clnt_addr_ipudp : STD_LOGIC_VECTOR(c_clnt_addr_w-1 DOWNTO 0);

BEGIN

    clk <= NOT clk OR tb_end AFTER c_clk_period/2;
    rst <= '1', '0' AFTER 3*c_clk_period;

    p_stimuli : PROCESS
    BEGIN

        -- Initialization
        mm_start <= '0';
        s2mm_tready <= '0';
        WAIT UNTIL rst='0';
        WAIT UNTIL RISING_EDGE(clk);

        FOR T IN c_test_vec'range LOOP

            mm_start <= '1';
            mm_nregs <= STD_LOGIC_VECTOR(TO_UNSIGNED(c_test_vec(T).nregs,mm_nregs'length));
            mm_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(c_test_vec(T).addr,mm_addr'length));
            WAIT UNTIL RISING_EDGE(clk);

            mm_start <= '0';

            s2mm_tready <= '1';
            WAIT UNTIL RISING_EDGE(clk);

            FOR J IN 1 TO c_test_vec(T).nregs LOOP
                WAIT UNTIL s2mm_tvalid = '1' AND RISING_EDGE(clk);
                ASSERT s2mm_tdata = c_test_vec(T).tdata(J) REPORT "Incorrect tdata" SEVERITY FAILURE;
                IF J = c_test_vec(T).nregs THEN
                    ASSERT s2mm_tlast = '1' REPORT "Incorrect tlast" SEVERITY FAILURE;
                ELSE
                    ASSERT s2mm_tlast = '0' REPORT "Incorrect tlast" SEVERITY FAILURE;
                END IF;
            END LOOP;

            s2mm_tready <= '0';

            WAIT FOR 6 * c_clk_period;

            WAIT UNTIL RISING_EDGE(clk);

            ASSERT clnt_addr_mac = c_test_vec(T).mac REPORT "Incorrect MAC" SEVERITY FAILURE;
            ASSERT clnt_addr_ipudp = c_test_vec(T).ipudp REPORT "Incorrect IP/UDP" SEVERITY FAILURE;

        END LOOP;

        tb_end <= '1';
        ASSERT FALSE REPORT "Simulation completed with no errors." SEVERITY NOTE;
        WAIT;

    END PROCESS;

    -- Simulate memory with 2 clock cycle read latency
    p_payload : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            mem_dly <= crqb_mem(TO_INTEGER(UNSIGNED(crqb_addr)));
            crqb_data <= mem_dly;
        END IF;
    END PROCESS;

    u_dut : ENTITY gemini_server_lib.request_streamer
    GENERIC MAP (
        g_technology => c_tech_gemini,
        g_data_w => c_data_w,
        g_mm_data_w => c_mm_data_w,
        g_crqb_len => c_crqb_len,
        g_nregs_w => c_nregs_w,
        g_clnt_addr_w => c_clnt_addr_w,
        g_crqbaddr_w => c_crqbaddr_w,
        g_crqb_ram_rd_latency => 2 )
    PORT MAP (
        clk => clk,
        rst => rst,
        mm_start_in => mm_start,
        mm_nregs_in => mm_nregs,
        mm_crqbaddr_in => mm_addr,
        crqb_data_in => crqb_data,
        crqb_addr_out => crqb_addr,
        clnt_addr_mac_out => clnt_addr_mac,
        clnt_addr_ipudp_out => clnt_addr_ipudp,
        s2mm_tdata_out =>  s2mm_tdata,
        s2mm_tkeep_out =>  s2mm_tkeep,
        s2mm_tlast_out =>  s2mm_tlast,
        s2mm_tready_in =>  s2mm_tready,
        s2mm_tvalid_out => s2mm_tvalid );

END tb;
