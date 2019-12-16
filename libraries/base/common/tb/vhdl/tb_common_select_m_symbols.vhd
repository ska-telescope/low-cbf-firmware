-------------------------------------------------------------------------------
--
-- Copyright (C) 2013
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

-- Purpose: Test bench for common_select_m_symbols.vhd
-- Usage:
-- > as 3
-- > run -all
--   p_verify self-checks the output of the reorder by using an inverse reorder
-- Remark:
-- . The verification assumes that the reorderings can be inversed, so all
--   inputs are output. It requires only one extra common_select_m_symbols 
--   unit that has the same selection settings to obtain the original 
--   input data. 

ENTITY tb_common_select_m_symbols IS
  GENERIC (
    g_nof_input     : NATURAL := 4;
    g_nof_output    : NATURAL := 4;
    g_symbol_w      : NATURAL := 16;
    g_pipeline_in   : NATURAL := 0;   -- pipeline in_data
    g_pipeline_in_m : NATURAL := 0;   -- pipeline in_data for M-fold fan out
    g_pipeline_out  : NATURAL := 1;   -- pipeline out_data
    g_select_arr    : t_natural_arr := (2,3,0,1)  
  );
END tb_common_select_m_symbols;

ARCHITECTURE tb OF tb_common_select_m_symbols IS

  CONSTANT clk_period        : TIME := 10 ns;
  
  -- Stimuli constants
  CONSTANT c_frame_len       : NATURAL := 17;
  CONSTANT c_frame_sop       : NATURAL := 1;
  CONSTANT c_frame_eop       : NATURAL := (c_frame_sop + c_frame_len-1) MOD c_frame_len;
  
  -- DUT constants
  CONSTANT c_N               : NATURAL := largest(g_nof_input, g_nof_output);
  
  CONSTANT c_dut_pipeline    : NATURAL := g_pipeline_in + g_pipeline_in_m + g_pipeline_out;
  CONSTANT c_total_pipeline  : NATURAL := c_dut_pipeline * 2;  -- factor for DUT, inverse DUT
  
  CONSTANT c_select_w        : NATURAL := ceil_log2(g_nof_input);
  
  -- Stimuli
  SIGNAL tb_end             : STD_LOGIC := '0';
  SIGNAL rst                : STD_LOGIC;
  SIGNAL clk                : STD_LOGIC := '1';
  
  -- DUT input
  SIGNAL in_select_arr      : t_natural_arr(g_nof_output-1 DOWNTO 0) := g_select_arr;   
  SIGNAL in_select_vec      : STD_LOGIC_VECTOR(g_nof_output*ceil_log2(g_nof_input)-1 DOWNTO 0);
  SIGNAL in_data_vec        : STD_LOGIC_VECTOR(g_nof_input*g_symbol_w-1 DOWNTO 0);
  SIGNAL in_dat             : STD_LOGIC_VECTOR(            g_symbol_w-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL in_val             : STD_LOGIC;
  SIGNAL in_sop             : STD_LOGIC;
  SIGNAL in_eop             : STD_LOGIC;
  SIGNAL in_sync            : STD_LOGIC;
  
  -- DUT output
  SIGNAL reorder_data_vec   : STD_LOGIC_VECTOR(g_nof_output*g_symbol_w-1 DOWNTO 0);
  SIGNAL reorder_val        : STD_LOGIC;
  SIGNAL reorder_sop        : STD_LOGIC;
  SIGNAL reorder_eop        : STD_LOGIC;
  SIGNAL reorder_sync       : STD_LOGIC;
  
  -- inverse output
  SIGNAL inverse_select_arr : t_natural_arr(g_nof_output-1 DOWNTO 0) :=  g_select_arr;  
  SIGNAL inverse_select_vec : STD_LOGIC_VECTOR(g_nof_output*ceil_log2(g_nof_input)-1 DOWNTO 0) := (OTHERS => '0');
  
  -- Verify output
  SIGNAL out_data_vec       : STD_LOGIC_VECTOR(g_nof_input*g_symbol_w-1 DOWNTO 0);
  SIGNAL out_val            : STD_LOGIC;
  SIGNAL out_sop            : STD_LOGIC;
  SIGNAL out_eop            : STD_LOGIC;
  SIGNAL out_sync           : STD_LOGIC;
  
  -- Verify
  SIGNAL exp_data_vec       : STD_LOGIC_VECTOR(g_nof_input*g_symbol_w-1 DOWNTO 0);
  SIGNAL exp_val            : STD_LOGIC;
  SIGNAL exp_sop            : STD_LOGIC;
  SIGNAL exp_eop            : STD_LOGIC;
  SIGNAL exp_sync           : STD_LOGIC;
  
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
    
  gen_in_data_vec: FOR I IN g_nof_input-1 DOWNTO 0 GENERATE
    in_data_vec((I+1)*g_symbol_w-1 DOWNTO I*g_symbol_w) <= INCR_UVEC(in_dat, I);
  END GENERATE;
  
  in_sop  <= in_val WHEN TO_UINT(in_dat) MOD c_frame_len = c_frame_sop ELSE '0';
  in_eop  <= in_val WHEN TO_UINT(in_dat) MOD c_frame_len = c_frame_eop ELSE '0';
  in_sync <= '0';
  
  gen_in_select_vec: FOR K IN g_nof_output-1 DOWNTO 0 GENERATE
    in_select_vec((K+1)*c_select_w-1 DOWNTO K*c_select_w) <= TO_UVEC(in_select_arr(K), c_select_w);
  END GENERATE;
  
  -- DUT
  u_reorder_in : ENTITY work.common_select_m_symbols
  GENERIC MAP (
    g_nof_input     => g_nof_input,    
    g_nof_output    => g_nof_output,   
    g_symbol_w      => g_symbol_w,     
    g_pipeline_in   => g_pipeline_in,  
    g_pipeline_in_m => g_pipeline_in_m,
    g_pipeline_out  => g_pipeline_out 
  )
  PORT MAP (
    rst        => rst,
    clk        => clk,
    
    in_data    => in_data_vec,
    in_val     => in_val,     
    in_sop     => in_sop,     
    in_eop     => in_eop,     
    in_sync    => in_sync,    
    
    in_select  => in_select_vec,   
                                   
    out_data   => reorder_data_vec,
    out_val    => reorder_val,     
    out_sop    => reorder_sop,     
    out_eop    => reorder_eop,     
    out_sync   => reorder_sync     
  );     
                      
  gen_inverse_select_vec: FOR K IN g_nof_output-1 DOWNTO 0 GENERATE
    inverse_select_vec((K+1)*c_select_w-1 DOWNTO K*c_select_w) <= TO_UVEC(inverse_select_arr(K), c_select_w);
  END GENERATE;

  u_inverse_out : ENTITY work.common_select_m_symbols
  GENERIC MAP (
    g_nof_input     => g_nof_output,    
    g_nof_output    => g_nof_input,   
    g_symbol_w      => g_symbol_w,     
    g_pipeline_in   => g_pipeline_in,  
    g_pipeline_in_m => g_pipeline_in_m,
    g_pipeline_out  => g_pipeline_out 
  )
  PORT MAP (
    rst        => rst,                                                                              
    clk        => clk,                                                                              
                                                                                                    
    in_data    => reorder_data_vec,                                                                
    in_val     => reorder_val,                                                                     
    in_sop     => reorder_sop,                                                                     
    in_eop     => reorder_eop,                                                                     
    in_sync    => reorder_sync,                                                                    
                                                                                                    
    in_select  => inverse_select_vec,   
                                                                                                    
    out_data   => out_data_vec,                                                                     
    out_val    => out_val,                                                                          
    out_sop    => out_sop,                                                                          
    out_eop    => out_eop,                                                                          
    out_sync   => out_sync                                                                          
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
      IF exp_sync     /= out_sync     THEN REPORT "Unexpected out_sync"     SEVERITY ERROR; END IF;
    END IF;
  END PROCESS;
  
  -- pipeline data input
  u_out_dat : ENTITY work.common_pipeline
  GENERIC MAP (
    g_pipeline  => c_total_pipeline,
    g_in_dat_w  => g_nof_input*g_symbol_w,
    g_out_dat_w => g_nof_input*g_symbol_w
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
    g_pipeline => c_total_pipeline
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => in_val,
    out_dat => exp_val
  );
  
  u_out_sop : ENTITY work.common_pipeline_sl
  GENERIC MAP (
    g_pipeline => c_total_pipeline
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => in_sop,
    out_dat => exp_sop
  );
  
  u_out_eop : ENTITY work.common_pipeline_sl
  GENERIC MAP (
    g_pipeline => c_total_pipeline
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => in_eop,
    out_dat => exp_eop
  );
  
  u_out_sync : ENTITY work.common_pipeline_sl
  GENERIC MAP (
    g_pipeline => c_total_pipeline
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    in_dat  => in_sync,
    out_dat => exp_sync
  );
  
END tb;
