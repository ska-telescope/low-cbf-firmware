-------------------------------------------------------------------------------
--
-- Copyright (C) 2014
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

LIBRARY IEEE, technology_lib, tech_memory_lib;
USE IEEE.std_logic_1164.ALL;
USE work.common_pkg.ALL;
USE work.common_mem_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;

ENTITY common_ram_crw_crw IS
  GENERIC (
    g_technology     : t_technology := c_tech_select_default;
    g_ram            : t_c_mem := c_mem_ram;
    g_init_file      : STRING  := "UNUSED";
    g_true_dual_port : BOOLEAN := TRUE
  );
  PORT (
    rst_a     : IN  STD_LOGIC := '0';
    rst_b     : IN  STD_LOGIC := '0';
    clk_a     : IN  STD_LOGIC;
    clk_b     : IN  STD_LOGIC;
    clken_a   : IN  STD_LOGIC := '1';
    clken_b   : IN  STD_LOGIC := '1';
    wr_en_a   : IN  STD_LOGIC := '0';
    wr_en_b   : IN  STD_LOGIC := '0';
    wr_dat_a  : IN  STD_LOGIC_VECTOR(g_ram.dat_w-1 DOWNTO 0) := (OTHERS=>'0');
    wr_dat_b  : IN  STD_LOGIC_VECTOR(g_ram.dat_w-1 DOWNTO 0) := (OTHERS=>'0');
    adr_a     : IN  STD_LOGIC_VECTOR(g_ram.adr_w-1 DOWNTO 0) := (OTHERS=>'0');
    adr_b     : IN  STD_LOGIC_VECTOR(g_ram.adr_w-1 DOWNTO 0) := (OTHERS=>'0');
    rd_en_a   : IN  STD_LOGIC := '1';
    rd_en_b   : IN  STD_LOGIC := '1';
    rd_dat_a  : OUT STD_LOGIC_VECTOR(g_ram.dat_w-1 DOWNTO 0);
    rd_dat_b  : OUT STD_LOGIC_VECTOR(g_ram.dat_w-1 DOWNTO 0);
    rd_val_a  : OUT STD_LOGIC;
    rd_val_b  : OUT STD_LOGIC
  );
END common_ram_crw_crw;


ARCHITECTURE str OF common_ram_crw_crw IS

  CONSTANT c_rd_latency : NATURAL := sel_a_b(g_ram.latency<2,            g_ram.latency,              2);  -- handle read latency 1 or 2 in RAM
  CONSTANT c_pipeline   : NATURAL := sel_a_b(g_ram.latency>c_rd_latency, g_ram.latency-c_rd_latency, 0);  -- handle rest of read latency > 2 in pipeline

  -- Intermediate signal for extra pipelining
  SIGNAL ram_rd_dat_a   : STD_LOGIC_VECTOR(rd_dat_a'RANGE);
  SIGNAL ram_rd_dat_b   : STD_LOGIC_VECTOR(rd_dat_b'RANGE);

  -- Map sl to single bit slv for rd_val pipelining
  SIGNAL ram_rd_en_a    : STD_LOGIC_VECTOR(0 DOWNTO 0);
  SIGNAL ram_rd_en_b    : STD_LOGIC_VECTOR(0 DOWNTO 0);
  SIGNAL ram_rd_val_a   : STD_LOGIC_VECTOR(0 DOWNTO 0);
  SIGNAL ram_rd_val_b   : STD_LOGIC_VECTOR(0 DOWNTO 0);  
  
BEGIN

  ASSERT g_ram.latency >= 1
    REPORT "common_ram_crw_crw : only support read latency >= 1"
    SEVERITY FAILURE;
    
  -- memory access
  gen_true_dual_port : IF g_true_dual_port = TRUE GENERATE
    u_ram : ENTITY tech_memory_lib.tech_memory_ram_crw_crw
    GENERIC MAP (
      g_technology => g_technology,
      g_adr_w      => g_ram.adr_w,
      g_dat_w      => g_ram.dat_w,
      g_nof_words  => g_ram.nof_dat,
      g_rd_latency => c_rd_latency,
      g_init_file  => g_init_file
    )
    PORT MAP (
      clock_a     => clk_a,
      clock_b     => clk_b,
      enable_a    => clken_a,
      enable_b    => clken_b,
      wren_a      => wr_en_a,
      wren_b      => wr_en_b,
      data_a      => wr_dat_a,
      data_b      => wr_dat_b,
      address_a   => adr_a,
      address_b   => adr_b,
      q_a         => ram_rd_dat_a,
      q_b         => ram_rd_dat_b
    );
  END GENERATE;
  
  gen_simple_dual_port : IF g_true_dual_port = FALSE GENERATE
    u_ram : ENTITY tech_memory_lib.tech_memory_ram_cr_cw
    GENERIC MAP (
      g_technology => g_technology,
      g_adr_w      => g_ram.adr_w,
      g_dat_w      => g_ram.dat_w,
      g_nof_words  => g_ram.nof_dat,
      g_rd_latency => c_rd_latency,
      g_init_file  => g_init_file
    )
    PORT MAP
    (
      wrclock   => clk_a,
      wrclocken => clken_a,
      wren      => wr_en_a,
      wraddress => adr_a,
      data      => wr_dat_a,
      rdclock   => clk_b,
      rdclocken => clken_b,
      rdaddress => adr_b,
      q         => ram_rd_dat_b
    );
  END GENERATE;

  -- read output
  u_pipe_a : ENTITY work.common_pipeline
  GENERIC MAP (
    g_pipeline   => c_pipeline,
    g_in_dat_w   => g_ram.dat_w,
    g_out_dat_w  => g_ram.dat_w
  )
  PORT MAP (
    clk     => clk_a,
    clken   => clken_a,
    in_dat  => ram_rd_dat_a,
    out_dat => rd_dat_a
  );
  
  u_pipe_b : ENTITY work.common_pipeline
  GENERIC MAP (
    g_pipeline   => c_pipeline,
    g_in_dat_w   => g_ram.dat_w,
    g_out_dat_w  => g_ram.dat_w
  )
  PORT MAP (
    clk     => clk_b,
    clken   => clken_b,
    in_dat  => ram_rd_dat_b,
    out_dat => rd_dat_b
  );

  -- rd_val control
  ram_rd_en_a(0) <= rd_en_a;
  ram_rd_en_b(0) <= rd_en_b;
  
  rd_val_a <= ram_rd_val_a(0);
  rd_val_b <= ram_rd_val_b(0);
  
  u_rd_val_a : ENTITY work.common_pipeline
  GENERIC MAP (
    g_pipeline   => g_ram.latency,
    g_in_dat_w   => 1,
    g_out_dat_w  => 1
  )
  PORT MAP (
    clk     => clk_a,
    clken   => clken_a,
    in_dat  => ram_rd_en_a,
    out_dat => ram_rd_val_a
  );
  
  u_rd_val_b : ENTITY work.common_pipeline
  GENERIC MAP (
    g_pipeline   => g_ram.latency,
    g_in_dat_w   => 1,
    g_out_dat_w  => 1
  )
  PORT MAP (
    clk     => clk_b,
    clken   => clken_b,
    in_dat  => ram_rd_en_b,
    out_dat => ram_rd_val_b
  );
  
END str;
