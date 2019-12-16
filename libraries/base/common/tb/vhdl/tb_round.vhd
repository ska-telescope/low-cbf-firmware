-------------------------------------------------------------------------------
--
-- Copyright (C) 2009
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
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.common_pkg.ALL;

-- Purpose: Test bench for common_round.vhd
-- Usage:
-- > do wave_round.do
-- > run 500 ns
-- . Observe reg_dat with respect to out_sdat_no_rc   for signed   round without clipping of rounding overflow
-- . Observe reg_dat with respect to out_sdat_with_rc for signed   round with    clipping of rounding overflow
-- . Observe reg_dat with respect to out_udat for         unsigned round
-- . Observe reg_dat with respect to out_tdat for         truncation

ENTITY tb_round IS
END tb_round;

ARCHITECTURE tb OF tb_round IS

  CONSTANT clk_period   : TIME    := 10 ns;
  
  CONSTANT c_pipeline_input  : NATURAL := 0;
  CONSTANT c_pipeline_output : NATURAL := 0;
  CONSTANT c_pipeline        : NATURAL := c_pipeline_input + c_pipeline_output;
  
  --CONSTANT c_round_clip   : BOOLEAN := TRUE;
  CONSTANT c_round_clip   : BOOLEAN := FALSE;
  CONSTANT c_in_dat_w     : NATURAL := 5;
  CONSTANT c_out_dat_w    : NATURAL := 3;
  CONSTANT c_round_w      : NATURAL := c_in_dat_w - c_out_dat_w;
  
  SIGNAL in_val           : STD_LOGIC;
  SIGNAL in_dat           : STD_LOGIC_VECTOR(c_in_dat_w-1 DOWNTO 0);
  SIGNAL in_vec           : STD_LOGIC_VECTOR(c_in_dat_w   DOWNTO 0);
  SIGNAL reg_vec          : STD_LOGIC_VECTOR(c_in_dat_w   DOWNTO 0);
  SIGNAL reg_val          : STD_LOGIC;
  SIGNAL reg_dat          : STD_LOGIC_VECTOR(c_in_dat_w-1 DOWNTO 0);
  
  SIGNAL out_sdat_no_rc   : STD_LOGIC_VECTOR(c_out_dat_w-1 DOWNTO 0);
  SIGNAL out_sdat_with_rc : STD_LOGIC_VECTOR(c_out_dat_w-1 DOWNTO 0);
  SIGNAL out_udat         : STD_LOGIC_VECTOR(c_out_dat_w-1 DOWNTO 0);
  SIGNAL out_tdat         : STD_LOGIC_VECTOR(c_out_dat_w-1 DOWNTO 0);  -- truncate
  
  SIGNAL clk              : STD_LOGIC := '1';
  SIGNAL rst              : STD_LOGIC := '1';

  CONSTANT c_init         : STD_LOGIC_VECTOR(in_dat'RANGE) := (OTHERS=>'0');
  
BEGIN

  -- Stimuli
  clk <= NOT(clk) AFTER clk_period/2;
  rst <= '1', '0' AFTER 3*clk_period;
  
  p_clk : PROCESS (rst, clk)
  BEGIN
    IF rst='1' THEN
      in_val      <= '0';
      in_dat      <= c_init;
    ELSIF rising_edge(clk) THEN
      in_val      <= '1';
      in_dat      <= STD_LOGIC_VECTOR(SIGNED(in_dat)+1);
    END IF;
  END PROCESS;
  
  -- Delay input as much as DUT output
  in_vec <= in_val & in_dat;
  
  u_pipe : ENTITY work.common_pipeline
  GENERIC MAP (
    g_representation => "SIGNED",
    g_pipeline       => c_pipeline,
    g_in_dat_w       => c_in_dat_w+1,
    g_out_dat_w      => c_in_dat_w+1
  )
  PORT MAP (
    clk     => clk,
    in_dat  => in_vec,
    out_dat => reg_vec
  );
  
  reg_val <= reg_vec(c_in_dat_w);
  reg_dat <= reg_vec(c_in_dat_w-1 DOWNTO 0);
  
  -- DUT for "SIGNED" round without clipping of rounding overflow
  u_s_round : ENTITY work.common_round
  GENERIC MAP (
    g_representation  => "SIGNED",
    g_round           => TRUE,
    g_round_clip      => FALSE,
    g_pipeline_input  => c_pipeline_input,
    g_pipeline_output => c_pipeline_output,
    g_in_dat_w        => c_in_dat_w,
    g_out_dat_w       => c_out_dat_w
  )
  PORT MAP (
    clk            => clk,
    clken          => '1',
    in_dat         => in_dat,
    out_dat        => out_sdat_no_rc
  );

  -- DUT for "SIGNED" round with clipping of rounding overflow
  u_s_round_rc : ENTITY work.common_round
  GENERIC MAP (
    g_representation  => "SIGNED",
    g_round           => TRUE,
    g_round_clip      => TRUE,
    g_pipeline_input  => c_pipeline_input,
    g_pipeline_output => c_pipeline_output,
    g_in_dat_w        => c_in_dat_w,
    g_out_dat_w       => c_out_dat_w
  )
  PORT MAP (
    clk            => clk,
    clken          => '1',
    in_dat         => in_dat,
    out_dat        => out_sdat_with_rc
  );
  
  -- DUT for "UNSIGNED" round
  u_u_round : ENTITY work.common_round
  GENERIC MAP (
    g_representation  => "UNSIGNED",
    g_round           => TRUE,
    g_round_clip      => c_round_clip,
    g_pipeline_input  => c_pipeline_input,
    g_pipeline_output => c_pipeline_output,
    g_in_dat_w        => c_in_dat_w,
    g_out_dat_w       => c_out_dat_w
  )
  PORT MAP (
    clk            => clk,
    clken          => '1',
    in_dat         => in_dat,
    out_dat        => out_udat
  );
  
  -- DUT for truncate
  u_truncate : ENTITY work.common_round
  GENERIC MAP (
    g_representation  => "UNSIGNED",
    g_round           => FALSE,
    g_round_clip      => c_round_clip,
    g_pipeline_input  => c_pipeline_input,
    g_pipeline_output => c_pipeline_output,
    g_in_dat_w        => c_in_dat_w,
    g_out_dat_w       => c_out_dat_w
  )
  PORT MAP (
    clk            => clk,
    clken          => '1',
    in_dat         => in_dat,
    out_dat        => out_tdat
  );
  
  
  -- Verification
  p_verify : PROCESS
  BEGIN
    WAIT UNTIL rising_edge(clk);
    IF reg_val = '1' THEN
    END IF;
  END PROCESS;

END tb;
