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

LIBRARY IEEE, common_lib, technology_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE common_lib.common_pkg.ALL;

ENTITY common_complex_mult_add IS
  GENERIC (
    g_technology       : t_technology := c_tech_select_default;
    g_in_a_w           : POSITIVE := 16;
    g_in_b_w           : POSITIVE := 16;
    g_ch_w             : POSITIVE := 38;
    g_out_p_w          : POSITIVE := 38;          
    g_pipeline_input   : NATURAL  := 1;      -- 0 or 1
    g_pipeline_product : NATURAL  := 0;      -- 0 or 1
    g_pipeline_adder   : NATURAL  := 1;      -- 0 or 1
    g_pipeline_output  : NATURAL  := 1       -- >= 0
  );
  PORT (
    rst        : IN   STD_LOGIC := '0';
    clk        : IN   STD_LOGIC;
    clken      : IN   STD_LOGIC := '1';
    in_ar      : IN   STD_LOGIC_VECTOR(g_in_a_w-1 DOWNTO 0);              
    in_ai      : IN   STD_LOGIC_VECTOR(g_in_a_w-1 DOWNTO 0);              
    in_br      : IN   STD_LOGIC_VECTOR(g_in_b_w-1 DOWNTO 0);              
    in_bi      : IN   STD_LOGIC_VECTOR(g_in_b_w-1 DOWNTO 0);              
    in_chr     : IN   STD_LOGIC_VECTOR(g_ch_w-1   DOWNTO 0);              
    in_chi     : IN   STD_LOGIC_VECTOR(g_ch_w-1   DOWNTO 0);              
    out_sumr   : OUT  STD_LOGIC_VECTOR(g_out_p_w-1 DOWNTO 0);              
    out_sumi   : OUT  STD_LOGIC_VECTOR(g_out_p_w-1 DOWNTO 0)
  );     
END common_complex_mult_add;

-- The str architecture uses a complex multiplier and two adders: one for real and one for the 
-- imaginary part. The output of the complex multiplier is connected to the adders. 
-- Pipeling should be done in the multiplier or adder entity.

ARCHITECTURE str of common_complex_mult_add is 

  CONSTANT c_conjugate    : boolean := FALSE;
  constant c_direction    : STRING := "ADD";
  constant c_pipeline_in  : NATURAL := 0;     -- input pipelining 0 or 1
  constant c_pipeline_out : NATURAL := 1;     -- output pipelining >= 0 
  constant c_sel_add      : STD_LOGIC :='1'; 
  constant c_prod_w       : natural := g_in_a_w+g_in_b_w;
  
  signal out_pr : std_logic_vector(c_prod_w-1 downto 0);
  signal out_pi : std_logic_vector(c_prod_w-1 downto 0);
  
  signal add_inr : std_logic_vector(g_out_p_w-1 downto 0);
  signal add_ini : std_logic_vector(g_out_p_w-1 downto 0);

begin

  -- u_complex_mult : entity work.common_complex_mult(stratix4)  -- requires sum of g_pipeline >= 3
  u_complex_mult : entity work.common_complex_mult        -- suits sum of g_pipeline >= 0
  GENERIC MAP (
    g_technology       => g_technology,
    g_variant          => "RTL",
    g_in_a_w           => g_in_a_w,
    g_in_b_w           => g_in_b_w,
    g_out_p_w          => c_prod_w,
    g_conjugate_b      => c_conjugate,
    g_pipeline_input   => g_pipeline_input,
    g_pipeline_product => g_pipeline_product,
    g_pipeline_adder   => g_pipeline_adder,
    g_pipeline_output  => g_pipeline_output
  )
  PORT MAP (
    rst        => rst,
    clk        => clk,
    clken      => '1',
    in_ar      => in_ar,
    in_ai      => in_ai,
    in_br      => in_br,
    in_bi      => in_bi,
    out_pr     => out_pr,
    out_pi     => out_pi
  );

  add_inr <= RESIZE_SVEC(out_pr, g_out_p_w);  -- Connect the output of the multiplier to the adders input
  add_ini <= RESIZE_SVEC(out_pi, g_out_p_w);
  
  u_adder_real : ENTITY common_lib.common_add_sub
  GENERIC MAP (
    g_direction       => c_direction,
    g_representation  => "SIGNED",
    g_pipeline_input  => c_pipeline_in,
    g_pipeline_output => c_pipeline_out,
    g_in_dat_w        => g_out_p_w,
    g_out_dat_w       => g_out_p_w
  )
  PORT MAP (
    clk     => clk,
    clken   => '1',
    sel_add => c_sel_add,
    in_a    => in_chr,
    in_b    => add_inr,
    result  => out_sumr
  );
  
  u_adder_imag : ENTITY common_lib.common_add_sub
  GENERIC MAP (
    g_direction       => c_direction,
    g_representation  => "SIGNED",
    g_pipeline_input  => c_pipeline_in,
    g_pipeline_output => c_pipeline_out,
    g_in_dat_w        => g_out_p_w,
    g_out_dat_w       => g_out_p_w
  )
  PORT MAP (
    clk     => clk,
    clken   => '1',
    sel_add => c_sel_add,
    in_a    => in_chi,
    in_b    => add_ini,
    result  => out_sumi
  );

end str;


-- The rtl architecture follows the syntax that is given as example by Altera for inferring the DSP blocks.
architecture rtl of common_complex_mult_add is        

  constant c_prod_w  : natural := g_in_a_w+g_in_b_w;
  
  signal ar_reg  : signed(g_in_a_w-1  downto 0);
  signal ai_reg  : signed(g_in_a_w-1  downto 0);
  signal br_reg  : signed(g_in_b_w-1  downto 0);
  signal bi_reg  : signed(g_in_b_w-1  downto 0);
  signal chr_reg : signed(g_ch_w-1    downto 0);
  signal chi_reg : signed(g_ch_w-1    downto 0);
  signal pr      : signed(c_prod_w-1  downto 0);
  signal pi      : signed(c_prod_w-1  downto 0);
  signal sumr    : signed(g_out_p_w-1 downto 0);
  signal sumi    : signed(g_out_p_w-1 downto 0);

begin

  process (clk, rst, clken)
  begin
    if(rst = '1') then             -- asynchronous reset
      ar_reg  <= (others => '0');
      ai_reg  <= (others => '0');
      br_reg  <= (others => '0');
      bi_reg  <= (others => '0');
      chr_reg <= (others => '0');
      chi_reg <= (others => '0');
      pr      <= (others => '0');
      pi      <= (others => '0'); 
      sumr    <= (others => '0');
      sumi    <= (others => '0');
      
    elsif(rising_edge(clk) and clken = '1') then  -- rising clock edge
      ar_reg  <= signed(in_ar);
      ai_reg  <= signed(in_ai);
      br_reg  <= signed(in_br);
      bi_reg  <= signed(in_bi);
      chr_reg <= signed(in_chr);
      chi_reg <= signed(in_chi);

      pr <= RESIZE_NUM((ar_reg*br_reg), c_prod_w) - RESIZE_NUM((ai_reg*bi_reg), c_prod_w);  -- Calculate the real part
      pi <= RESIZE_NUM((ar_reg*bi_reg), c_prod_w) + RESIZE_NUM((ai_reg*br_reg), c_prod_w);  -- Calculate the imaginary part
        
      sumr <= RESIZE_NUM(pr, g_out_p_w) + RESIZE_NUM(signed(in_chr), g_out_p_w);              -- Add the chain_in real part to the real product
      sumi <= RESIZE_NUM(pi, g_out_p_w) + RESIZE_NUM(signed(in_chi), g_out_p_w);              -- Add the chain_in imaginary part to the imaginary product 
  
    end if;
  end process;

  out_sumr <= std_logic_vector(sumr);
  out_sumi <= std_logic_vector(sumi);

end rtl;
 
