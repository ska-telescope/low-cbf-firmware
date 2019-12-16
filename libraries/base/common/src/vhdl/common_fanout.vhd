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

-- Purpose : Provide pipelining for fanout from 1 to g_nof_output
-- Description :
-- . The pipeling can be set per output via g_pipeline_arr[g_nof_output-1:0]
-- . For pipeline value 0 the connection becomes wires, for pipeline value > 0
--   the in_dat is passed on via g_pipeline_arr(i) register stages.
-- . When in_en='1' the in_dat is register on, when in_en='0' the pipeline
--   registers maintain their value.

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE work.common_pkg.ALL;

ENTITY common_fanout IS
  GENERIC (
    g_nof_output   : NATURAL := 1;    -- >= 1 
    g_pipeline_arr : t_natural_arr;   -- range: g_nof_output-1 DOWNTO 0, value: 0 for wires, >0 for register stages
    g_dat_w        : NATURAL := 8
  );
  PORT (
    clk         : IN  STD_LOGIC;
    clken       : IN  STD_LOGIC := '1';
    in_en       : IN  STD_LOGIC := '1';
    in_val      : IN  STD_LOGIC := '1';
    in_dat      : IN  STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    out_en_vec  : OUT STD_LOGIC_VECTOR(g_nof_output        -1 DOWNTO 0);
    out_val_vec : OUT STD_LOGIC_VECTOR(g_nof_output        -1 DOWNTO 0);
    out_dat_vec : OUT STD_LOGIC_VECTOR(g_nof_output*g_dat_w-1 DOWNTO 0)
  );
END common_fanout;


ARCHITECTURE str OF common_fanout IS
  
BEGIN

  gen_fanout : FOR i IN g_nof_output-1 DOWNTO 0 GENERATE
    u_pipe_en : ENTITY work.common_pipeline_sl
    GENERIC MAP (
      g_pipeline  => g_pipeline_arr(i)
    )
    PORT MAP (
      clk     => clk,
      clken   => clken,
      in_dat  => in_en,
      in_en   => '1',
      out_dat => out_en_vec(i)
    );
    
    u_pipe_valid : ENTITY work.common_pipeline_sl
    GENERIC MAP (
      g_pipeline  => g_pipeline_arr(i)
    )
    PORT MAP (
      clk     => clk,
      clken   => clken,
      in_dat  => in_val,
      in_en   => in_en,
      out_dat => out_val_vec(i)
    );
    
    u_pipe_data : ENTITY work.common_pipeline
    GENERIC MAP (
      g_pipeline  => g_pipeline_arr(i),
      g_in_dat_w  => g_dat_w,
      g_out_dat_w => g_dat_w
    )
    PORT MAP (
      clk     => clk,
      clken   => clken,
      in_dat  => in_dat,
      in_en   => in_en,
      out_dat => out_dat_vec((i+1)*g_dat_w-1 DOWNTO i*g_dat_w)
    );
  END GENERATE;
  
END str;
