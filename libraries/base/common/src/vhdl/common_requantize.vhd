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

LIBRARY IEEE, common_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;

-- Purpose: Requantize the input data to the output data width by removing
--          LSbits and/or MSbits
-- Description:
--
-- . in_dat --> remove LSbits --> rem_dat --> remove MSbits --> shift left by g_gain_w --> out_dat
--
-- . Remove LSBits by means of ROUND or TRUNCATE
-- . Remove LSBits when g_lsb_w>0
--
-- . Remove MSBits by means of CLIP or WRAP
-- . Remove MSbits when g_in_dat_w-g_lsb_w > g_out_dat_w:
--     in_dat   <---------------------g_in_dat_w--------------------->
--     rem_dat  <---------------------c_rem_dat_w-------><--g_lsb_w-->
--     res_dat          <-------------g_out_dat_w-------><--g_lsb_w-->
--
-- . Extend MSbits when g_in_dat_w-g_lsb_w <= g_out_dat_w::
--     in_dat           <-------------g_in_dat_w--------------------->
--     rem_dat          <-------------c_rem_dat_w-------><--g_lsb_w-->
--     res_dat  <---------------------g_out_dat_w-------><--g_lsb_w-->
--
-- . Shift left res_dat before resizing to out_dat'LENGTH, which is useful to keep the res_dat in the MSbits when out_dat'LENGTH > g_out_dat_w
--     gain_dat <-------g_out_dat_w-------><--g_gain_w-->
--  
-- Remarks:
-- . It is not necessary to define g_msb_w, because the number of MSbits that
--   need to be removed (or extended) follows from the other widths.

ENTITY common_requantize IS
  GENERIC (
    g_representation      : STRING  := "SIGNED";  -- SIGNED (round +-0.5 away from zero to +- infinity) or UNSIGNED rounding (round 0.5 up to + inifinity)
    g_lsb_w               : NATURAL := 4;         -- >= 0, number of LSbits to remove from in_dat
    g_lsb_round           : BOOLEAN := TRUE;      -- when true ROUND else TRUNCATE the input LSbits
    g_lsb_round_clip      : BOOLEAN := FALSE;     -- when true round clip to +max to avoid wrapping to output -min (signed) or 0 (unsigned) due to rounding
    g_msb_clip            : BOOLEAN := TRUE;      -- when true CLIP else WRAP the input MSbits
    g_msb_clip_symmetric  : BOOLEAN := FALSE;     -- when TRUE clip signed symmetric to +c_smax and -c_smax, else to +c_smax and c_smin_symm
                                                  -- for wrapping when g_msb_clip=FALSE the g_msb_clip_symmetric is ignored, so signed wrapping is done asymmetric
    g_gain_w              : NATURAL := 0;         -- apply gain before resize to out_dat'LENGTH
    g_pipeline_remove_lsb : NATURAL := 0;         -- >= 0
    g_pipeline_remove_msb : NATURAL := 0;         -- >= 0, use g_pipeline_remove_lsb=0 and g_pipeline_remove_msb=0 for combinatorial output
    g_in_dat_w            : NATURAL := 36;        -- input data width
    g_out_dat_w           : NATURAL := 18         -- output data width
  );
  PORT (
    clk        : IN  STD_LOGIC;
    clken      : IN  STD_LOGIC := '1';
    in_dat     : IN  STD_LOGIC_VECTOR;  -- unconstrained slv to also support widths other than g_in_dat_w by only using [g_in_dat_w-1:0] from the in_dat slv
    out_dat    : OUT STD_LOGIC_VECTOR;  -- unconstrained slv to also support widths other then g_out_dat_w by resizing the result [g_out_dat_w-1:0] to the out_dat slv
    out_ovr    : OUT STD_LOGIC          -- out_ovr is '1' when the removal of MSbits causes clipping or wrapping
  );
END;


ARCHITECTURE str OF common_requantize IS
  
  CONSTANT c_rem_dat_w    : NATURAL := g_in_dat_w-g_lsb_w;
  
  SIGNAL rem_dat       : STD_LOGIC_VECTOR(c_rem_dat_w-1 DOWNTO 0);  -- remaining in_dat after removing the g_lsb_w number of LSBits
  SIGNAL res_dat       : STD_LOGIC_VECTOR(g_out_dat_w-1 DOWNTO 0);  -- resulting out_dat after removing the g_msb_w number of MSBits
  
  SIGNAL gain_dat      : STD_LOGIC_VECTOR(g_out_dat_w+g_gain_w-1 DOWNTO 0) := (OTHERS=>'0');  -- fill extra LSBits with '0' instead of extending MSbits
  
BEGIN

  -- Remove LSBits using ROUND or TRUNCATE
  u_remove_lsb : ENTITY common_lib.common_round
  GENERIC MAP (
    g_representation  => g_representation,
    g_round           => g_lsb_round,
    g_round_clip      => g_lsb_round_clip,
    g_pipeline_input  => 0,
    g_pipeline_output => g_pipeline_remove_lsb,
    g_in_dat_w        => g_in_dat_w,
    g_out_dat_w       => c_rem_dat_w      
  )
  PORT MAP (
    clk        => clk,
    clken      => clken,
    in_dat     => in_dat(g_in_dat_w-1 DOWNTO 0),
    out_dat    => rem_dat
  );
  
  -- Remove MSBits using CLIP or WRAP
  u_remove_msb : ENTITY common_lib.common_resize
  GENERIC MAP (
    g_representation  => g_representation,
    g_pipeline_input  => 0,
    g_pipeline_output => g_pipeline_remove_msb,
    g_clip            => g_msb_clip,
    g_clip_symmetric  => g_msb_clip_symmetric,
    g_in_dat_w        => c_rem_dat_w,
    g_out_dat_w       => g_out_dat_w
  )
  PORT MAP (
    clk        => clk,
    clken      => clken,
    in_dat     => rem_dat,
    out_dat    => res_dat,
    out_ovr    => out_ovr
  );
  
  -- Output gain
  gain_dat(g_out_dat_w+g_gain_w-1 DOWNTO g_gain_w) <= res_dat;
  
  out_dat <= RESIZE_SVEC(gain_dat, out_dat'LENGTH) WHEN g_representation="SIGNED" ELSE RESIZE_UVEC(gain_dat, out_dat'LENGTH);
    
END str;
