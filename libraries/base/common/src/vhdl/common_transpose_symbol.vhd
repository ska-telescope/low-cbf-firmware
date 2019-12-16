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

-- Purpose: Transpose of in_data to out_data
-- Description:
--   The in_data is a concatenation of g_nof_data input streams, that are each
--   g_data_w bits wide. The data in each input stream consists of a 
--   concatenation of g_nof_data symbols, that are g_data_w/g_nof_data bits
--   wide. The out_data contains the transpose of in_data. For example for 
--   g_nof_data=2 this becomes:
--
--                          |- b[1,0] ---> 1[b,a] -|
--                          |          \/          |
--                          |          /\          |
--   in_data[b[1,0,a[1,0]] -+- a[1,0] ---> 0[b,a] -+-> out_data[1[b,a],0[b,a]]
--
--   Idem for g_nof_data=4:
--
--   in_data[d[3:0],c[3:0],b[3:0],a[3:0]] -> out_data[3[d:a],2[d:a],1[d:a],0[d:a]]
--
-- Remarks:
-- . The transpose assumes that the in_data is square, so
--   c_nof_symbols = g_nof_data

ENTITY common_transpose_symbol IS
  GENERIC (
    g_pipeline  : NATURAL := 0;
    g_nof_data  : NATURAL := 4;
    g_data_w    : NATURAL := 16   -- must be multiple of g_nof_data
  );
  PORT (
    rst        : IN  STD_LOGIC;
    clk        : IN  STD_LOGIC;
    
    in_data    : IN  STD_LOGIC_VECTOR(g_nof_data*g_data_w-1 DOWNTO 0);
    in_val     : IN  STD_LOGIC := '0';
    in_sop     : IN  STD_LOGIC := '0';
    in_eop     : IN  STD_LOGIC := '0';
    
    out_data   : OUT STD_LOGIC_VECTOR(g_nof_data*g_data_w-1 DOWNTO 0);
    out_val    : OUT STD_LOGIC;   -- pipelined in_val
    out_sop    : OUT STD_LOGIC;   -- pipelined in_sop
    out_eop    : OUT STD_LOGIC    -- pipelined in_eop
  );
END common_transpose_symbol;


ARCHITECTURE rtl OF common_transpose_symbol IS

  CONSTANT c_nof_symbols : NATURAL := g_nof_data;
  CONSTANT c_symbol_w    : NATURAL := g_data_w/c_nof_symbols;

  TYPE t_symbol_arr  IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_symbol_w-1 DOWNTO 0);
  TYPE t_symbol_2arr IS ARRAY (INTEGER RANGE <>) OF t_symbol_arr(c_nof_symbols-1 DOWNTO 0);

  SIGNAL in_symbol_2arr    : t_symbol_2arr(g_nof_data-1 DOWNTO 0);
  SIGNAL trans_symbol_2arr : t_symbol_2arr(g_nof_data-1 DOWNTO 0);
  
  SIGNAL trans_data        : STD_LOGIC_VECTOR(g_nof_data*g_data_w-1 DOWNTO 0);
  
BEGIN

  no_transpose : IF g_nof_data=1 GENERATE
    trans_data <= in_data;
  END GENERATE;
  
  gen_transpose : IF g_nof_data>1 GENERATE
    gen_data : FOR I IN g_nof_data-1 DOWNTO 0 GENERATE
      gen_symbols : FOR J IN c_nof_symbols-1 DOWNTO 0 GENERATE
        -- map input vector to 2arr
        in_symbol_2arr(I)(J) <= in_data((J+1)*c_symbol_w + I*g_data_w-1 DOWNTO J*c_symbol_w + I*g_data_w);
        
        -- transpose
        trans_symbol_2arr(J)(I) <= in_symbol_2arr(I)(J);
      
        -- map 2arr to output vector
        trans_data((J+1)*c_symbol_w + I*g_data_w-1 DOWNTO J*c_symbol_w + I*g_data_w) <= trans_symbol_2arr(I)(J);
      END GENERATE;
    END GENERATE;
  END GENERATE;
    
  -- pipeline data output
  u_out_data : ENTITY work.common_pipeline
  GENERIC MAP (
    g_pipeline  => g_pipeline,
    g_in_dat_w  => g_nof_data*g_data_w,
    g_out_dat_w => g_nof_data*g_data_w
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => trans_data,
    out_dat => out_data
  );

  -- pipeline control output
  u_out_val : ENTITY work.common_pipeline_sl
  GENERIC MAP (
    g_pipeline => g_pipeline
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => in_val,
    out_dat => out_val
  );

  u_out_sop : ENTITY work.common_pipeline_sl
  GENERIC MAP (
    g_pipeline => g_pipeline
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => in_sop,
    out_dat => out_sop
  );
  
  u_out_eop : ENTITY work.common_pipeline_sl
  GENERIC MAP (
    g_pipeline => g_pipeline
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => in_eop,
    out_dat => out_eop
  );
  
END rtl;
