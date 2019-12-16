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

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;

-- Purpose: Test bench for common_transpose_symbol.vhd
-- Usage:
-- > as 3
-- > run -all
--   p_verify self-checks the output of two time the transpose

ENTITY tb_common_transpose_symbol IS
  GENERIC (
    g_pipeline   : NATURAL := 1;
    g_nof_data   : NATURAL := 4;
    g_data_w     : NATURAL := 12
  );
END tb_common_transpose_symbol;

ARCHITECTURE tb OF tb_common_transpose_symbol IS

  CONSTANT clk_period   : TIME := 10 ns;
  
  CONSTANT c_symbol_w   : NATURAL := g_data_w/g_nof_data;
  
  CONSTANT c_frame_len  : NATURAL := 17;
  CONSTANT c_frame_sop  : NATURAL := 1;
  CONSTANT c_frame_eop  : NATURAL := (c_frame_sop + c_frame_len-1) MOD c_frame_len;
  
  -- Stimuli
  SIGNAL tb_end         : STD_LOGIC := '0';
  SIGNAL rst            : STD_LOGIC;
  SIGNAL clk            : STD_LOGIC := '1';
  
  SIGNAL in_val         : STD_LOGIC;
  SIGNAL in_dat         : STD_LOGIC_VECTOR(           g_data_w-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL in_sop         : STD_LOGIC;
  SIGNAL in_eop         : STD_LOGIC;
  
  SIGNAL in_data_vec    : STD_LOGIC_VECTOR(g_nof_data*g_data_w-1 DOWNTO 0);
  
  -- DUT output
  SIGNAL trans_val      : STD_LOGIC;
  SIGNAL trans_sop      : STD_LOGIC;
  SIGNAL trans_eop      : STD_LOGIC;
  SIGNAL trans_data_vec : STD_LOGIC_VECTOR(g_nof_data*g_data_w-1 DOWNTO 0);
  SIGNAL out_data_vec   : STD_LOGIC_VECTOR(g_nof_data*g_data_w-1 DOWNTO 0);
  SIGNAL out_val        : STD_LOGIC;
  SIGNAL out_sop        : STD_LOGIC;
  SIGNAL out_eop        : STD_LOGIC;
  
  -- Verify
  SIGNAL exp_val        : STD_LOGIC;
  SIGNAL exp_sop        : STD_LOGIC;
  SIGNAL exp_eop        : STD_LOGIC;
  SIGNAL exp_data_vec   : STD_LOGIC_VECTOR(g_nof_data*g_data_w-1 DOWNTO 0);
  
BEGIN

  -- Stimuli
  clk <= NOT clk OR tb_end AFTER clk_period/2;
  rst <= '1', '0' AFTER 3*clk_period;
  
  tb_end <= '1' WHEN SIGNED(in_dat)=-1 ELSE '0';
  
  p_clk : PROCESS (rst, clk)
  BEGIN
    IF rst='1' THEN
      in_val <= '0';
      in_dat <= (OTHERS=>'0');
    ELSIF rising_edge(clk) THEN
      in_val <= '1';
      in_dat <= STD_LOGIC_VECTOR(SIGNED(in_dat)+1);
    END IF;
  END PROCESS;
    
  gen_vec: FOR I IN g_nof_data-1 DOWNTO 0 GENERATE
    in_data_vec((I+1)*g_data_w-1 DOWNTO I*g_data_w) <= INCR_UVEC(in_dat, I * 2**c_symbol_w);
  END GENERATE;
  
  in_sop <= in_val WHEN TO_UINT(in_dat) MOD c_frame_len = c_frame_sop ELSE '0';
  in_eop <= in_val WHEN TO_UINT(in_dat) MOD c_frame_len = c_frame_eop ELSE '0';
  
  -- DUT
  u_transpose_in : ENTITY work.common_transpose_symbol
  GENERIC MAP (
    g_pipeline  => g_pipeline,
    g_nof_data  => g_nof_data,
    g_data_w    => g_data_w
  )
  PORT MAP (
    rst        => rst,
    clk        => clk,
    
    in_data    => in_data_vec,
    in_val     => in_val,
    in_sop     => in_sop,
    in_eop     => in_eop,
    
    out_data   => trans_data_vec,
    out_val    => trans_val,
    out_sop    => trans_sop,
    out_eop    => trans_eop
  );  
  
  u_transpose_out : ENTITY work.common_transpose_symbol
  GENERIC MAP (
    g_pipeline  => g_pipeline,
    g_nof_data  => g_nof_data,
    g_data_w    => g_data_w
  )
  PORT MAP (
    rst        => rst,
    clk        => clk,
    
    in_data    => trans_data_vec,
    in_val     => trans_val,
    in_sop     => trans_sop,
    in_eop     => trans_eop,
    
    out_data   => out_data_vec,
    out_val    => out_val,
    out_sop    => out_sop,
    out_eop    => out_eop
  );  
  
  -- Verification
  p_verify : PROCESS(rst, clk)
  BEGIN
    IF rst='1' THEN
    ELSIF rising_edge(clk) THEN
      IF exp_data_vec /= out_data_vec THEN REPORT "Unexpected out_data_vec" SEVERITY ERROR; END IF;
      IF exp_val      /= out_val      THEN REPORT "Unexpected out_val"      SEVERITY ERROR; END IF;
      IF exp_sop      /= out_sop      THEN REPORT "Unexpected out_sop"      SEVERITY ERROR; END IF;
      IF exp_eop      /= out_eop      THEN REPORT "Unexpected out_eop"      SEVERITY ERROR; END IF;
    END IF;
  END PROCESS;
  
  -- pipeline data input
  u_out_dat : ENTITY work.common_pipeline
  GENERIC MAP (
    g_pipeline  => g_pipeline*2,
    g_in_dat_w  => g_nof_data*g_data_w,
    g_out_dat_w => g_nof_data*g_data_w
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => in_data_vec,
    out_dat => exp_data_vec
  );

  -- pipeline control input
  u_out_val : ENTITY work.common_pipeline_sl
  GENERIC MAP (
    g_pipeline => g_pipeline*2
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => in_val,
    out_dat => exp_val
  );
  
  u_out_sop : ENTITY work.common_pipeline_sl
  GENERIC MAP (
    g_pipeline => g_pipeline*2
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => in_sop,
    out_dat => exp_sop
  );
  
  u_out_eop : ENTITY work.common_pipeline_sl
  GENERIC MAP (
    g_pipeline => g_pipeline*2
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => in_eop,
    out_dat => exp_eop
  );
  
END tb;
