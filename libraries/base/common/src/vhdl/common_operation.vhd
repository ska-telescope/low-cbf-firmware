-------------------------------------------------------------------------------
--
-- Copyright (C) 2012
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
-------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;

ENTITY common_operation IS
  GENERIC (
    g_operation       : STRING  := "MAX";      -- supported operations "MAX", "MIN"
    g_representation  : STRING  := "SIGNED";   -- or "UNSIGNED"
    g_pipeline_input  : NATURAL := 0;          -- 0 or 1
    g_pipeline_output : NATURAL := 1;          -- >= 0
    g_dat_w           : NATURAL := 8
  );
  PORT (
    clk     : IN  STD_LOGIC;
    clken   : IN  STD_LOGIC := '1';
    in_a    : IN  STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    in_b    : IN  STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    in_en_a : IN  STD_LOGIC := '1';
    in_en_b : IN  STD_LOGIC := '1';
    result  : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0)
  );
END common_operation;


ARCHITECTURE rtl OF common_operation IS

  FUNCTION func_default(operation, representation : STRING; w : NATURAL) RETURN STD_LOGIC_VECTOR IS
    CONSTANT c_smin : STD_LOGIC_VECTOR(w-1 DOWNTO 0) := '1' & c_slv0(w-2 DOWNTO 0);
    CONSTANT c_umin : STD_LOGIC_VECTOR(w-1 DOWNTO 0) :=       c_slv0(w-1 DOWNTO 0);
    CONSTANT c_smax : STD_LOGIC_VECTOR(w-1 DOWNTO 0) := '0' & c_slv1(w-2 DOWNTO 0);
    CONSTANT c_umax : STD_LOGIC_VECTOR(w-1 DOWNTO 0) :=       c_slv1(w-1 DOWNTO 0);
  BEGIN
    -- return don't care default value
    IF representation="SIGNED" THEN
      IF operation="MIN" THEN RETURN c_smax; END IF;
      IF operation="MAX" THEN RETURN c_smin; END IF;
    ELSE
      IF operation="MIN" THEN RETURN c_umax; END IF;
      IF operation="MAX" THEN RETURN c_umin; END IF;
    END IF;
    ASSERT TRUE REPORT "Operation not supported" SEVERITY FAILURE;
    RETURN c_umin;  -- void return statement to avoid compiler warning on missing return
  END;
  
  FUNCTION func_operation(operation, representation : STRING; a, b : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
  BEGIN
    IF representation="SIGNED" THEN
      IF operation="MIN" THEN IF SIGNED(a) < SIGNED(b) THEN RETURN a; ELSE RETURN b; END IF; END IF;
      IF operation="MAX" THEN IF SIGNED(a) > SIGNED(b) THEN RETURN a; ELSE RETURN b; END IF; END IF;
    ELSE
      IF operation="MIN" THEN IF UNSIGNED(a) < UNSIGNED(b) THEN RETURN a; ELSE RETURN b; END IF; END IF;
      IF operation="MAX" THEN IF UNSIGNED(a) > UNSIGNED(b) THEN RETURN a; ELSE RETURN b; END IF; END IF;
    END IF;
    ASSERT TRUE REPORT "Operation not supported" SEVERITY FAILURE;
    RETURN a;  -- void return statement to avoid compiler warning on missing return
  END;

  SIGNAL nxt_a       : STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
  SIGNAL nxt_b       : STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
  SIGNAL a           : STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
  SIGNAL b           : STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
  SIGNAL nxt_result  : STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
  
BEGIN

  nxt_a <= in_a WHEN in_en_a='1' ELSE func_default(g_operation, g_representation, g_dat_w);
  nxt_b <= in_b WHEN in_en_b='1' ELSE func_default(g_operation, g_representation, g_dat_w);
  
  no_input_reg : IF g_pipeline_input=0 GENERATE  -- wired input
    a <= nxt_a;
    b <= nxt_b;
  END GENERATE;
  gen_input_reg : IF g_pipeline_input>0 GENERATE  -- register input
    p_reg : PROCESS(clk)
    BEGIN
      IF rising_edge(clk) THEN
        IF clken='1' THEN
          a <= nxt_a;
          b <= nxt_b;
        END IF;
      END IF;
    END PROCESS;
  END GENERATE;

  nxt_result <= func_operation(g_operation, g_representation, a, b);
    
  u_output_pipe : ENTITY work.common_pipeline  -- pipeline output
  GENERIC MAP (
    g_representation => g_representation,
    g_pipeline       => g_pipeline_output,  -- 0 for wires, >0 for register stages
    g_in_dat_w       => g_dat_w,
    g_out_dat_w      => g_dat_w
  )
  PORT MAP (
    clk     => clk,
    clken   => clken,
    in_dat  => nxt_result,
    out_dat => result
  );
  
END rtl;
