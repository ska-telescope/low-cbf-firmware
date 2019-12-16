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
USE IEEE.std_logic_1164.ALL;

ENTITY common_complex_round IS
  GENERIC (
    g_representation  : STRING  := "SIGNED";  -- SIGNED (round +-0.5 away from zero to +- infinity) or UNSIGNED rounding (round 0.5 up to + inifinity)
    g_round           : BOOLEAN := TRUE;      -- when TRUE round the input, else truncate the input
    g_round_clip      : BOOLEAN := FALSE;     -- when TRUE clip rounded input >= +max to avoid wrapping to output -min (signed) or 0 (unsigned)
    g_pipeline_input  : NATURAL := 0;         -- >= 0
    g_pipeline_output : NATURAL := 1;         -- >= 0, use g_pipeline_input=0 and g_pipeline_output=0 for combinatorial output
    g_in_dat_w        : NATURAL := 36;
    g_out_dat_w       : NATURAL := 18
  );
  PORT (
    clk        : IN  STD_LOGIC;
    clken      : IN  STD_LOGIC := '1';
    in_re      : IN  STD_LOGIC_VECTOR(g_in_dat_w-1 DOWNTO 0);
    in_im      : IN  STD_LOGIC_VECTOR(g_in_dat_w-1 DOWNTO 0);
    out_re     : OUT STD_LOGIC_VECTOR(g_out_dat_w-1 DOWNTO 0);
    out_im     : OUT STD_LOGIC_VECTOR(g_out_dat_w-1 DOWNTO 0)
  );
END;


ARCHITECTURE str OF common_complex_round IS
BEGIN

  re: ENTITY work.common_round
  GENERIC MAP (
    g_representation  => g_representation,
    g_round           => g_round,
    g_round_clip      => g_round_clip,
    g_pipeline_input  => g_pipeline_input,
    g_pipeline_output => g_pipeline_output,
    g_in_dat_w        => g_in_dat_w,
    g_out_dat_w       => g_out_dat_w
  )
  PORT MAP (
    clk     => clk,
    clken   => clken,
    in_dat  => in_re,
    out_dat => out_re
  );

  im: ENTITY work.common_round
  GENERIC MAP (
    g_representation  => g_representation,
    g_round           => g_round,
    g_round_clip      => g_round_clip,
    g_pipeline_input  => g_pipeline_input,
    g_pipeline_output => g_pipeline_output,
    g_in_dat_w        => g_in_dat_w,
    g_out_dat_w       => g_out_dat_w
  )
  PORT MAP (
    clk     => clk,
    clken   => clken,
    in_dat  => in_im,
    out_dat => out_im
  );
END str;
