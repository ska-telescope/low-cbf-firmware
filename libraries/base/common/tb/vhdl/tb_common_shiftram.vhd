--------------------------------------------------------------------------------
--
-- Copyright (C) 2014
-- ASTRON (Netherlands Institute for Radio Astronomy) <http://www.astron.nl/>
-- P.O.Box 2, 7990 AA Dwingeloo, The Netherlands
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
--------------------------------------------------------------------------------

-- Purpose:
-- . Lets common_shiftram shift counter data with all possible shift values
-- Description:
-- . The DUT output counter stream is verified
-- . Correct shift and counter values at the output with respect to the input 
--   counter values are verified
-- Usage:
-- > as 10
-- > run -all  -- signal tb_end will stop the simulation by stopping the clk

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.tb_common_pkg.ALL;

ENTITY tb_common_shiftram IS
  GENERIC (
    g_nof_words : NATURAL := 16;
    g_data_w    : NATURAL := 32
  );
END tb_common_shiftram;

ARCHITECTURE tb OF tb_common_shiftram IS

  CONSTANT clk_period     : TIME := 10 ns;
  CONSTANT c_shift_w      : NATURAL := ceil_log2(g_nof_words);

  CONSTANT c_data_io_delay : NATURAL := 3; -- data_in takes 3 cycles to emerge as data_out

  SIGNAL rst              : STD_LOGIC;
  SIGNAL clk              : STD_LOGIC := '1';
  SIGNAL tb_end           : STD_LOGIC := '0';

  SIGNAL gen_data_en      : STD_LOGIC := '1';
  SIGNAL gen_data_rdy     : STD_LOGIC := '1';
  
  SIGNAL data_in        : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
  SIGNAL data_in_val    : STD_LOGIC;
  SIGNAL data_in_shift  : STD_LOGIC_VECTOR(c_shift_w-1 DOWNTO 0);
  SIGNAL data_out       : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
  SIGNAL data_out_val   : STD_LOGIC;
  SIGNAL data_out_shift : STD_LOGIC_VECTOR(c_shift_w-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL prv_data_out_shift : STD_LOGIC_VECTOR(c_shift_w-1 DOWNTO 0) := (OTHERS=>'0');

  SIGNAL prev_data_out   : STD_LOGIC_VECTOR(g_data_w-1 DOWNTO 0);
  SIGNAL ver_data_start  : STD_LOGIC;
  SIGNAL ver_data_toggle : STD_LOGIC;
  SIGNAL ver_data_en     : STD_LOGIC;
  SIGNAL ver_data_rdy    : STD_LOGIC := '1';

BEGIN

  clk <= (NOT clk) OR tb_end AFTER clk_period/2;
  rst <= '1', '0' AFTER clk_period*3;

  -- Generate data_in
  proc_common_gen_data(1, 0, rst, clk, gen_data_en, gen_data_rdy, data_in, data_in_val);

  -- Stimuli: shift range 0->max->0
  p_shift: PROCESS
  BEGIN
    data_in_shift <= (OTHERS=>'0');
    WAIT UNTIL data_out_val='1';

    FOR i IN 0 TO g_nof_words-2 LOOP
      IF rising_edge(clk) THEN
        data_in_shift <= TO_UVEC(i, c_shift_w);
      END IF;
      WHILE TO_UINT(data_out_shift) /= i LOOP
        WAIT UNTIL clk = '1';
      END LOOP;
      WAIT FOR 100 ns;
    END LOOP; 

    FOR i IN g_nof_words-3 DOWNTO 0 LOOP
      IF rising_edge(clk) THEN
        data_in_shift <= TO_UVEC(i, c_shift_w);
      END IF;
      WHILE TO_UINT(data_out_shift) /= i LOOP
        WAIT UNTIL clk = '1';
      END LOOP;
      WAIT FOR 100 ns;
    END LOOP; 

    tb_end <= '1';
    WAIT;
  END PROCESS;

  -- DUT
  u_common_shiftram : ENTITY work.common_shiftram
  GENERIC MAP (
    g_data_w    => g_data_w,
    g_nof_words => g_nof_words
  )
  PORT MAP (
    rst            => rst,
    clk            => clk,
    
    data_in        => data_in,
    data_in_val    => data_in_val,
    data_in_shift  => data_in_shift,
 
    data_out       => data_out,
    data_out_val   => data_out_val,
    data_out_shift => data_out_shift
  );

  -- Make sure prev_data_out has been assigned
  p_verify_start: PROCESS
  BEGIN
    WAIT UNTIL data_out_val = '1';
    proc_common_wait_some_cycles(clk, 1);
    ver_data_start <= '1';
    WAIT;
  END PROCESS;

  -- Disable verification during shifts
  prv_data_out_shift <= data_out_shift WHEN rising_edge(clk);

  p_verify_toggle: PROCESS(data_out, data_out_val, data_out_shift)
  BEGIN
    ver_data_toggle <= '1';
    IF NOT (data_out_shift = prv_data_out_shift) THEN
      ver_data_toggle <= '0';
    END IF;
  END PROCESS;

  -- Verify data_out
  ver_data_en <= ver_data_start AND ver_data_toggle;
  proc_common_verify_data(1, clk, ver_data_en, ver_data_rdy, data_out_val, data_out, prev_data_out);

  -- Verify the relationship between input data and output shift/data
  p_verify_shift: PROCESS(clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF data_out_val='1' THEN
        IF TO_UINT(data_in)/=TO_UINT(data_out)+c_data_io_delay+TO_UINT(data_out_shift) THEN  
          REPORT "Wrong output data/shift with respect to input data" SEVERITY ERROR;
        END IF;
      END IF;
    END IF;
  END PROCESS;

END tb;
