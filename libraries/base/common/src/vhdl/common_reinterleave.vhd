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
USE IEEE.STD_LOGIC_1164.ALL;
USE work.common_pkg.ALL;

-- Purpose: 
--   Deinterleave g_nof_in inputs based on g_deint_block_size and re-interleave 
--   these streams onto g_nof_out outputs based on g_inter_block_size.
-- Description: 
--   The input and output streams are concatenated into one SLV.
-- Remarks:
-- . g_inter_block_size >= g_deint_block_size;
-- . One valid input applies to all input data streams;
-- . The user must take care of the correct valid/gap ratio on the inputs.

ENTITY common_reinterleave IS
  GENERIC (
    g_nof_in         : NATURAL;
    g_deint_block_size  : NATURAL;
    g_nof_out        : NATURAL;
    g_inter_block_size : NATURAL;
    g_dat_w          : NATURAL;
    g_align_out  : BOOLEAN := FALSE
 );
  PORT (
    clk         : IN  STD_LOGIC;
    rst         : IN  STD_LOGIC;

    in_dat      : IN  STD_LOGIC_VECTOR(g_nof_in*g_dat_w-1 DOWNTO 0);
    in_val      : IN  STD_LOGIC;

    out_dat     : OUT STD_LOGIC_VECTOR(g_nof_out*g_dat_w-1 DOWNTO 0);
    out_val     : OUT STD_LOGIC_VECTOR(g_nof_out-1 DOWNTO 0)
  );
END;


ARCHITECTURE rtl OF common_reinterleave IS

  TYPE t_dat_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
  TYPE t_val_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC;

  -----------------------------------------------------------------------------
  -- Constants to determine the number of instances. General rule: 
  -- . Deinterleavers: one for each input  stream. 
  -- . Interleavers:   one for each output stream. 
  -- Exceptions:
  -- . Multi  in, single out = one interleaver   instance only
  -- . Single in, multi  out = one deinterleaver instance only
  -- . One in,    one out    = wires
  -----------------------------------------------------------------------------
  CONSTANT c_interleave_only   : BOOLEAN := g_nof_in>1 AND g_nof_out=1;
  CONSTANT c_deinterleave_only : BOOLEAN := g_nof_in=1 AND g_nof_out>1;
  CONSTANT c_wires_only        : BOOLEAN := g_nof_in=1 AND g_nof_out=1;

  CONSTANT c_nof_deint : NATURAL := sel_a_b( c_interleave_only,   0,                                  
                                    sel_a_b( c_deinterleave_only, 1,
                                    sel_a_b( c_wires_only,        0, 
                                                                  g_nof_in)));

  CONSTANT c_nof_inter : NATURAL := sel_a_b( c_interleave_only,   1,                                  
                                    sel_a_b( c_deinterleave_only, 0,
                                    sel_a_b( c_wires_only,        0, 
                                                                  g_nof_out)));

  CONSTANT c_nof_deint_out : NATURAL := g_nof_out;
  CONSTANT c_nof_inter_in  : NATURAL := g_nof_in;

  -----------------------------------------------------------------------------
  -- in_dat array to the deinterleavers
  -----------------------------------------------------------------------------
  SIGNAL deint_in_dat_arr : t_dat_arr(c_nof_deint-1 DOWNTO 0);
  SIGNAL deint_in_val     : STD_LOGIC;

  -----------------------------------------------------------------------------
  -- Array of concatenated deinterleaver outputs
  -----------------------------------------------------------------------------
  TYPE t_deint_out_concat_dat_arr IS ARRAY (c_nof_deint-1 DOWNTO 0) OF STD_LOGIC_VECTOR(c_nof_deint_out*g_dat_w-1 DOWNTO 0);
  TYPE t_deint_out_concat_val_arr IS ARRAY (c_nof_deint-1 DOWNTO 0) OF STD_LOGIC_VECTOR(c_nof_deint_out-1 DOWNTO 0);

  SIGNAL deint_out_concat_dat_arr : t_deint_out_concat_dat_arr;
  SIGNAL deint_out_concat_val_arr : t_deint_out_concat_val_arr;

  -----------------------------------------------------------------------------
  -- Array of de-concatenated deinterleaver outputs
  -----------------------------------------------------------------------------
  TYPE t_deint_out_dat_2arr IS ARRAY (c_nof_deint-1 DOWNTO 0) OF t_dat_arr(c_nof_deint_out-1 DOWNTO 0);
  TYPE t_deint_out_val_2arr IS ARRAY (c_nof_deint-1 DOWNTO 0) OF t_val_arr(c_nof_deint_out-1 DOWNTO 0);

  SIGNAL deint_out_dat_2arr : t_deint_out_dat_2arr;
  SIGNAL deint_out_val_2arr : t_deint_out_val_2arr;

  -----------------------------------------------------------------------------
  -- Array of de-concatenated interleaver inputs
  -----------------------------------------------------------------------------
  TYPE t_inter_in_dat_2arr IS ARRAY (c_nof_inter-1 DOWNTO 0) OF t_dat_arr(c_nof_inter_in-1 DOWNTO 0);
  TYPE t_inter_in_val_2arr IS ARRAY (c_nof_inter-1 DOWNTO 0) OF t_val_arr(c_nof_inter_in-1 DOWNTO 0);

  SIGNAL inter_in_dat_2arr : t_inter_in_dat_2arr;
  SIGNAL inter_in_val_2arr : t_inter_in_val_2arr;

  -----------------------------------------------------------------------------
  -- Array of concatenated interleaver inputs
  -----------------------------------------------------------------------------
  TYPE t_inter_in_concat_dat_arr IS ARRAY (c_nof_inter-1 DOWNTO 0) OF STD_LOGIC_VECTOR(c_nof_inter_in*g_dat_w-1 DOWNTO 0);
  TYPE t_inter_in_concat_val_arr IS ARRAY (c_nof_inter-1 DOWNTO 0) OF STD_LOGIC_VECTOR(c_nof_inter_in-1 DOWNTO 0);

  SIGNAL inter_in_concat_dat_arr : t_inter_in_concat_dat_arr;
  SIGNAL inter_in_concat_val_arr : t_inter_in_concat_val_arr;

  -----------------------------------------------------------------------------
  -- out_dat array from the interleavers
  -----------------------------------------------------------------------------
  SIGNAL inter_out_dat_arr : t_dat_arr(c_nof_inter-1 DOWNTO 0);
  SIGNAL inter_out_val     : STD_LOGIC_VECTOR(c_nof_inter-1 DOWNTO 0);

BEGIN

  -----------------------------------------------------------------------------
  -- Deinterleavers and their input wiring
  -----------------------------------------------------------------------------
  gen_deint: FOR i IN 0 TO c_nof_deint-1 GENERATE
    deint_in_dat_arr(i) <= in_dat( i*g_dat_w+g_dat_w -1 DOWNTO i*g_dat_w);
    deint_in_val        <= in_val;

    u_deinterleave : ENTITY work.common_deinterleave
    GENERIC MAP (
      g_nof_out => c_nof_deint_out,
      g_dat_w   => g_dat_w,
      g_block_size => g_deint_block_size,
      g_align_out => g_align_out
    )
    PORT MAP (
      rst        => rst,
      clk        => clk,
      
      in_dat     => deint_in_dat_arr(i),
      in_val     => deint_in_val,
      
      out_dat    => deint_out_concat_dat_arr(i),
      out_val    => deint_out_concat_val_arr(i)
    );
  END GENERATE;

  -----------------------------------------------------------------------------
  -- Wire the array of concatenated deinterleaver outputs to an array
  -- of de-concatenated (so another array) deinterleaver outputs.
  -- Use the entity outputs if no interleavers are instantiated.
  -----------------------------------------------------------------------------
  gen_wire_deint_out: IF c_deinterleave_only=FALSE GENERATE
    gen_wires_deint : FOR i IN 0 TO c_nof_deint-1 GENERATE
      gen_deint_out : FOR j IN 0 TO c_nof_deint_out-1 GENERATE
        deint_out_dat_2arr(i)(j) <= deint_out_concat_dat_arr(i)(j*g_dat_w+g_dat_w -1 DOWNTO j*g_dat_w);
        deint_out_val_2arr(i)(j) <= deint_out_concat_val_arr(i)(j);
      END GENERATE;
    END GENERATE;
  END GENERATE;

  gen_wire_deint_only: IF c_deinterleave_only=TRUE GENERATE
    out_dat <= deint_out_concat_dat_arr(0);
    out_val <= deint_out_concat_val_arr(0);
  END GENERATE;

  -----------------------------------------------------------------------------
  -- Deinterleavers -> Interleavers interconnections
  -----------------------------------------------------------------------------
  gen_interconnect: IF c_deinterleave_only=FALSE AND c_interleave_only = FALSE GENERATE
    gen_wires_deint : FOR i IN 0 TO c_nof_deint-1 GENERATE
      gen_deint_out : FOR j IN 0 TO c_nof_deint_out-1 GENERATE
        inter_in_dat_2arr(j)(i) <= deint_out_dat_2arr(i)(j);
        inter_in_val_2arr(j)(i) <= deint_out_val_2arr(i)(j);
      END GENERATE;
    END GENERATE;
  END GENERATE;

  -----------------------------------------------------------------------------
  -- Wire the array of concatenated interleaver inputs to an array
  -- of de-concatenated (so another array) interleaver inputs.
  -- Use the entity inputs if no deinterleavers are instantiated.
  -----------------------------------------------------------------------------
  gen_wire_inter_arr: IF c_interleave_only=FALSE GENERATE
    gen_nof_inter : FOR i IN 0 TO c_nof_inter-1 GENERATE
      gen_inter_in : FOR j IN 0 TO c_nof_inter_in-1 GENERATE
        inter_in_concat_dat_arr(i)(j*g_dat_w+g_dat_w -1 DOWNTO j*g_dat_w) <= inter_in_dat_2arr(i)(j);
        inter_in_concat_val_arr(i)(j)                                     <= inter_in_val_2arr(i)(j);
      END GENERATE;
    END GENERATE;
  END GENERATE;

  gen_wire_inter_only: IF c_interleave_only=TRUE GENERATE
    inter_in_concat_dat_arr(0)    <= in_dat;
  
    gen_inter_in : FOR i IN 0 TO c_nof_inter_in-1 GENERATE
      inter_in_concat_val_arr(0)(i) <= in_val;
    END GENERATE;
  END GENERATE;

  -----------------------------------------------------------------------------
  -- Interleavers and their output wiring
  -----------------------------------------------------------------------------
  gen_inter: FOR i IN 0 TO c_nof_inter-1 GENERATE
    u_interleave : ENTITY work.common_interleave
    GENERIC MAP (
      g_nof_in     => c_nof_inter_in,
      g_dat_w      => g_dat_w,
      g_block_size => g_inter_block_size
    )
    PORT MAP (
      rst        => rst,
      clk        => clk,
      
      in_dat     => inter_in_concat_dat_arr(i),
      in_val     => inter_in_concat_val_arr(i)(0), -- All input streams are valid at the same time.
      
      out_dat    => inter_out_dat_arr(i),
      out_val    => inter_out_val(i)
    ); 

    out_dat( i*g_dat_w+g_dat_w -1 DOWNTO i*g_dat_w) <= inter_out_dat_arr(i);
    out_val(i)                                      <= inter_out_val(i);
  END GENERATE;

END rtl;
