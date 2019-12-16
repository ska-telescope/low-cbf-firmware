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
USE work.common_pkg.ALL;
USE work.common_components_pkg.ALL;

-- Purpose: Select symbol from input data stream
-- Description:
--   The in_data is a concatenation of g_nof_symbols, that are each g_symbol_w
--   bits wide. The symbol with index set by in_sel is passed on to the output
--   out_dat.
-- Remarks:
-- . If the in_select index is too large for g_nof_input range then the output
--   passes on symbol 0.

ENTITY common_select_symbol IS
  GENERIC (
    g_pipeline_in  : NATURAL := 0;
    g_pipeline_out : NATURAL := 1;
    g_nof_symbols  : NATURAL := 4;
    g_symbol_w     : NATURAL := 16;
    g_sel_w        : NATURAL := 2
  );
  PORT (
    rst        : IN  STD_LOGIC;
    clk        : IN  STD_LOGIC;

    in_data    : IN  STD_LOGIC_VECTOR(g_nof_symbols*g_symbol_w-1 DOWNTO 0);
    in_val     : IN  STD_LOGIC := '0';
    in_sop     : IN  STD_LOGIC := '0';
    in_eop     : IN  STD_LOGIC := '0';
    in_sync    : IN  STD_LOGIC := '0';

    in_sel     : IN  STD_LOGIC_VECTOR(g_sel_w-1 DOWNTO 0);
    out_sel    : OUT STD_LOGIC_VECTOR(g_sel_w-1 DOWNTO 0);  -- pipelined in_sel, use range to allow leaving it OPEN

    out_symbol : OUT STD_LOGIC_VECTOR(g_symbol_w-1 DOWNTO 0);
    out_val    : OUT STD_LOGIC;         -- pipelined in_val
    out_sop    : OUT STD_LOGIC;         -- pipelined in_sop
    out_eop    : OUT STD_LOGIC;         -- pipelined in_eop
    out_sync   : OUT STD_LOGIC          -- pipelined in_sync
  );
END common_select_symbol;


ARCHITECTURE rtl OF common_select_symbol IS

  CONSTANT c_pipeline   : NATURAL := g_pipeline_in + g_pipeline_out;

  SIGNAL in_data_reg    : STD_LOGIC_VECTOR(in_data'RANGE);
  SIGNAL in_sel_reg     : STD_LOGIC_VECTOR(in_sel'RANGE);

  SIGNAL sel_symbol     : STD_LOGIC_VECTOR(g_symbol_w-1 DOWNTO 0);

BEGIN

  -- pipeline input
   u_pipe_in_data: common_pipeline
   GENERIC MAP (
      g_representation => "SIGNED",
      g_pipeline       => g_pipeline_in,
      g_reset_value    => 0,
      g_in_dat_w       => in_data'LENGTH,
      g_out_dat_w      => in_data'LENGTH)
   PORT MAP (
      rst      => rst,
      clk      => clk,
      clken    => '1',
      in_clr   => '0',
      in_en    => '1',
      in_dat   => in_data,
      out_dat  => in_data_reg);

  u_pipe_in_sel: common_pipeline
   GENERIC MAP (
      g_representation => "SIGNED",
      g_pipeline       => g_pipeline_in,
      g_reset_value    => 0,
      g_in_dat_w       => g_sel_w,
      g_out_dat_w      => g_sel_w)
   PORT MAP (
      rst      => rst,
      clk      => clk,
      clken    => '1',
      in_clr   => '0',
      in_en    => '1',
      in_dat   => in_sel,
      out_dat  => in_sel_reg);

  no_sel : IF g_nof_symbols=1 GENERATE
    sel_symbol <= in_data_reg;
  END GENERATE;

  gen_sel : IF g_nof_symbols>1 GENERATE
    -- Default pass on symbol 0 else if supported pass on the selected symbol
    p_sel : PROCESS(in_sel_reg, in_data_reg)
    BEGIN
      sel_symbol <= in_data_reg(g_symbol_w-1 DOWNTO 0);

      FOR I IN g_nof_symbols-1 DOWNTO 0 LOOP
        IF TO_UINT(in_sel_reg)=I THEN
          sel_symbol <= in_data_reg((I+1)*g_symbol_w-1 DOWNTO I*g_symbol_w);
        END IF;
      END LOOP;
    END PROCESS;
  END GENERATE;

  -- pipeline selected symbol output and control outputs
   u_pipe_out_symbol: common_pipeline
   GENERIC MAP (
      g_representation => "SIGNED",
      g_pipeline       => g_pipeline_out,
      g_reset_value    => 0,
      g_in_dat_w       => g_symbol_w,
      g_out_dat_w      => g_symbol_w)
   PORT MAP (
      rst      => rst,
      clk      => clk,
      clken    => '1',
      in_clr   => '0',
      in_en    => '1',
      in_dat   => sel_symbol,
      out_dat  => out_symbol);

  u_pipe_out_sel: common_pipeline
   GENERIC MAP (
      g_representation => "SIGNED",
      g_pipeline       => g_pipeline_out,
      g_reset_value    => 0,
      g_in_dat_w       => in_sel'LENGTH,
      g_out_dat_w      => in_sel'LENGTH)
   PORT MAP (
      rst      => rst,
      clk      => clk,
      clken    => '1',
      in_clr   => '0',
      in_en    => '1',
      in_dat   => in_sel,
      out_dat  => out_sel);


   u_pipe_out_val  : common_pipeline_sl
   GENERIC MAP (
      g_pipeline => c_pipeline,
      g_reset_value => 0,
      g_out_invert => FALSE)
   PORT MAP (
      rst => rst,
      clk => clk,
      clken => '1',
      in_clr => '0',
      in_en => '1',
      in_dat => in_val,
      out_dat => out_val);

   u_pipe_out_sop  : common_pipeline_sl
   GENERIC MAP (
      g_pipeline => c_pipeline,
      g_reset_value => 0,
      g_out_invert => FALSE)
   PORT MAP (
      rst => rst,
      clk => clk,
      clken => '1',
      in_clr => '0',
      in_en => '1',
      in_dat => in_sop,
      out_dat => out_sop);

   u_pipe_out_eop  : common_pipeline_sl
   GENERIC MAP (
      g_pipeline => c_pipeline,
      g_reset_value => 0,
      g_out_invert => FALSE)
   PORT MAP (
      rst => rst,
      clk => clk,
      clken => '1',
      in_clr => '0',
      in_en => '1',
      in_dat => in_eop,
      out_dat => out_eop);

   u_pipe_out_sync : common_pipeline_sl
   GENERIC MAP (
      g_pipeline => c_pipeline,
      g_reset_value => 0,
      g_out_invert => FALSE)
   PORT MAP (
      rst => rst,
      clk => clk,
      clken => '1',
      in_clr => '0',
      in_en => '1',
      in_dat => in_sync,
      out_dat => out_sync);

END rtl;