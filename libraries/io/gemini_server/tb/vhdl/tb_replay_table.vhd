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

LIBRARY IEEE, common_lib, gemini_server_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_textio.ALL;
USE common_lib.common_pkg.ALL;

LIBRARY STD;
USE STD.textio.ALL;

ENTITY tb_replay_table IS
END tb_replay_table;

ARCHITECTURE tb OF tb_replay_table IS

    CONSTANT c_clk_period : TIME := 10 ns;  -- 100 MHz
    CONSTANT c_max_pipeline : NATURAL := 3;
    CONSTANT c_noof_clnts : NATURAL := 2;
    CONSTANT c_data_w : NATURAL := 4;
    CONSTANT c_key_w : NATURAL := ceil_log2(c_noof_clnts);
    CONSTANT c_csn_w : NATURAL := ceil_log2(c_max_pipeline) + 3;

    TYPE t_test_vec_rec IS RECORD
        key : INTEGER RANGE 0 TO c_noof_clnts-1;
        csn : INTEGER RANGE 0 TO 2**c_csn_w-1;
        lookup : STD_LOGIC;
        wr : STD_LOGIC;
        valid : STD_LOGIC;
        data : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);
    END RECORD t_test_vec_rec;
    
    TYPE t_test_vec IS ARRAY (INTEGER RANGE <>) OF t_test_vec_rec;
    CONSTANT c_test_vec : t_test_vec(1 TO 11) := ( 
            ( 0, 10, '0', '1', 'X', x"A" ),
            ( 0, 11, '0', '1', 'X', x"B" ),
            ( 0, 9, '1', '0', '0', x"B" ),  -- Lookup fails because CSN 9 has never been written
            ( 0, 12, '0', '1', 'X', x"C" ),
            ( 0, 13, '0', '1', 'X', x"D" ),
            ( 0, 14, '0', '1', 'X', x"E" ),
            ( 0, 15, '0', '1', 'X', x"F" ),
            ( 0, 12, '1', '0', '0', x"A" ), -- Lookup fails because CSN 12 no longer in history
            ( 0, 13, '1', '0', '1', x"D" ), -- Lookup succeeds because CSN 13 is in history
            ( 0, 16, '0', '1', 'X', x"0" ),
            ( 0, 14, '1', '0', '1', x"E" ) 
    );

    SIGNAL rst : STD_LOGIC;
    SIGNAL clk : STD_LOGIC := '1';
    SIGNAL tb_end : STD_LOGIC := '0';
    SIGNAL clnt_rst : STD_LOGIC := '0';
    SIGNAL key : STD_LOGIC_VECTOR(c_key_w-1 DOWNTO 0);
    SIGNAL csn : STD_LOGIC_VECTOR(c_csn_w-1 DOWNTO 0);
    SIGNAL lookup : STD_LOGIC;
    SIGNAL complete : STD_LOGIC;
    SIGNAL valid : STD_LOGIC;
    SIGNAL wr : STD_LOGIC;
    SIGNAL lookup_data : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);
    SIGNAL wr_data : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);
    
BEGIN

    clk <= NOT clk OR tb_end AFTER c_clk_period/2;
    rst <= '1', '0' AFTER 3*c_clk_period;
  
    p_stimuli : PROCESS
    BEGIN

        -- Initialization
        lookup <= '0';
        wr <= '0';
        clnt_rst <= '0';
        WAIT UNTIL rst='0';
        WAIT UNTIL rising_edge(clk);

        FOR I IN c_test_vec'range LOOP
            csn <= STD_LOGIC_VECTOR(TO_UNSIGNED(c_test_vec(I).csn,c_csn_w));
            key <= STD_LOGIC_VECTOR(TO_UNSIGNED(c_test_vec(I).key,c_key_w));
            lookup <= c_test_vec(I).lookup;
            wr <= c_test_vec(I).wr;
            IF c_test_vec(I).wr = '1' THEN
                wr_data <= c_test_vec(I).data;
            ELSE
                wr_data <= (others=>'U');
            END IF;

            IF c_test_vec(I).lookup = '1' THEN
                WAIT UNTIL RISING_EDGE(clk);
                wr <= '0';
                lookup <= '0';
                WAIT UNTIL RISING_EDGE(clk) AND complete = '1';
                ASSERT valid = c_test_vec(I).valid REPORT "Incorrect lookup valid" SEVERITY FAILURE;
                IF c_test_vec(I).valid = '1' THEN
                    ASSERT lookup_data = c_test_vec(I).data REPORT "Incorrect lookup data" SEVERITY FAILURE;
                END IF;
            ELSE
                WAIT UNTIL RISING_EDGE(clk);
                wr <= '0';
                lookup <= '0';
                WAIT FOR 2*c_clk_period;
            END IF;
            
        END LOOP;
    
        tb_end <= '1';
        ASSERT FALSE REPORT "Simulation tb_connection_lookup completed with no errors." SEVERITY NOTE;
        WAIT;

    END PROCESS;
  
    u_dut : ENTITY gemini_server_lib.replay_table
    GENERIC MAP (
        g_key_w => c_key_w,
        g_csn_w => c_csn_w,
        g_max_pipeline => c_max_pipeline, 
        g_noof_clnts => c_noof_clnts,
        g_data_w => c_data_w )
    PORT MAP (
        rst => rst,
        clk => clk,
        clnt_rst => clnt_rst,
        key_in => key,
        csn_in => csn,
        lookup_in => lookup,
        complete_out => complete,
        valid_out => valid,
        data_out => lookup_data,
        wr_in => wr,
        wr_data_in => wr_data );

END tb;
