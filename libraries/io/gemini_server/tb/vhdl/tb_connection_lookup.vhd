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


-- Purpose: Testbench for connection_lookup
-- Description:
--

LIBRARY IEEE, gemini_server_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_textio.ALL;

LIBRARY STD;
USE STD.textio.ALL;

ENTITY tb_connection_lookup IS
END tb_connection_lookup;

ARCHITECTURE tb OF tb_connection_lookup IS

    CONSTANT c_clk_period : TIME := 10 ns;  -- 100 MHz

    TYPE t_test IS RECORD
        addr : STD_LOGIC_VECTOR(3 DOWNTO 0);
        key : STD_LOGIC_VECTOR(1 DOWNTO 0);
        failed : STD_LOGIC;
        recycled : STD_LOGIC;
    END RECORD t_test;
    
    TYPE t_test_vec IS ARRAY (INTEGER RANGE <>) OF t_test;
    CONSTANT c_test_vec : t_test_vec(1 TO 5) := ( 

            -- Lookup for client address 0. DUT should successfully return key 1
            ( x"0", "01", '0', '0' ),
            -- Lookup for client address 1. DUT should successfully return key 0
            ( x"1", "00", '0', '0' ),
            -- Lookup for client address 2. Should fail since DUT configured for only 2 clients
            ( x"2", "01", '1', '0' ),
            -- Lookup for client address 1. Should return same key as previously
            ( x"1", "00", '0', '0' ),
            -- Lookup for client address 2. Should recycle key 1 since min_recycle_secs has elapsed since last key 1 lookup
            ( x"2", "01", '0', '1' ) 

    );

    SIGNAL rst : STD_LOGIC;
    SIGNAL clk : STD_LOGIC := '1';
    SIGNAL tb_end : STD_LOGIC := '0';
    SIGNAL lookup : STD_LOGIC;
    SIGNAL tod : UNSIGNED(7 DOWNTO 0);
    SIGNAL clnt_addr : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL key : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL lookup_failed : STD_LOGIC;
    SIGNAL lookup_complete : STD_LOGIC;
    SIGNAL lookup_recycled : STD_LOGIC;
    
BEGIN

    clk <= NOT clk OR tb_end AFTER c_clk_period/2;
    rst <= '1', '0' AFTER 3*c_clk_period;
  
    p_tod : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF rst = '1' THEN
                tod <= (others=>'0');
            ELSE
                tod <= tod + TO_UNSIGNED(1,tod'length);
            END IF;
         END IF;
    END PROCESS;

    p_stimuli : PROCESS
    BEGIN

        -- Initialization
        lookup <= '0';
        clnt_addr <= (others=>'0');
        WAIT UNTIL rst='0';
        WAIT UNTIL rising_edge(clk);

        -- Lookup each client in the test vector
        FOR I IN c_test_vec'range LOOP
            lookup <= '1';
            clnt_addr <= c_test_vec(I).addr;
            WAIT UNTIL RISING_EDGE(clk);
            lookup <= '0';
            WHILE lookup_complete = '0' LOOP
                WAIT UNTIL RISING_EDGE(clk);
            END LOOP;
            ASSERT lookup_failed=c_test_vec(I).failed REPORT "Wrong lookup outcome" SEVERITY FAILURE;
            IF lookup_failed = '0' THEN
                REPORT "Lookup of client " & INTEGER'IMAGE(TO_INTEGER(UNSIGNED(clnt_addr))) & " at tod " & INTEGER'IMAGE(TO_INTEGER(tod)) & " returned key " & INTEGER'IMAGE(TO_INTEGER(UNSIGNED(key))) & LF; 
                ASSERT key=c_test_vec(I).key REPORT "Wrong key" SEVERITY FAILURE;
                ASSERT lookup_recycled=c_test_vec(I).recycled REPORT "Incorrect recycle value" SEVERITY FAILURE;
            ELSE
                REPORT "Lookup of client " & INTEGER'IMAGE(TO_INTEGER(UNSIGNED(clnt_addr))) & " at tod " & INTEGER'IMAGE(TO_INTEGER(tod)) & " failed"  & LF; 
            END IF;
        END LOOP;
    
        tb_end <= '1';
        ASSERT FALSE REPORT "Simulation tb_connection_lookup completed with no errors." SEVERITY NOTE;
        WAIT;

    END PROCESS;
  
    -- Use small connection table and short min_recycle_secs
    -- to make it easier to test recycling of connections
    u_dut : ENTITY gemini_server_lib.connection_lookup
    GENERIC MAP (
        g_clnt_addr_w => 4,
        g_noof_clnts  => 2,
        g_key_w => 2,
        g_tod_w => 8,
        g_min_recycle_secs => 11 )
    PORT MAP (
        rst          => rst,
        clk           => clk,
        lookup_in     => lookup,
        tod_in        => STD_LOGIC_VECTOR(tod),
        clnt_addr_in  => clnt_addr,
        connect_in    => '1',
        key_out       => key,
        failed_out    => lookup_failed,
        recycle_out   => lookup_recycled,
        complete_out  => lookup_complete );

END tb;
