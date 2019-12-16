-------------------------------------------------------------------------------
--
-- Copyright (C) 2017
-- ASTRON (Netherlands Institute for Radio Astronomy) <http://www.astron.nl/>
-- JIVE (Joint Institute for VLBI in Europe) <http://www.jive.nl/>
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
USE IEEE.std_logic_textio.ALL;
USE STD.textio.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE work.axi4_lite_pkg.ALL;


ENTITY tb_axi4_lite_reg_r_w_dc IS
END tb_axi4_lite_reg_r_w_dc;

ARCHITECTURE tb OF tb_axi4_lite_reg_r_w_dc IS

   CONSTANT mm_clk_period : TIME := 40 ns;
   CONSTANT c_reset_len   : NATURAL := 16;

   CONSTANT c_mm_reg_led    : t_c_mem := (latency      => 1,
                                          adr_w        => 8,
                                          dat_w        => 32,
                                          nof_dat      => 4,
                                          addr_base    => 0,
                                          nof_slaves   => 4,
                                          init_sl      => '0');

   SIGNAL mm_rst              : STD_LOGIC;
   SIGNAL mm_clk              : STD_LOGIC := '0';
   SIGNAL sim_finished        : STD_LOGIC := '0';
   SIGNAL tb_end              : STD_LOGIC := '0';

   SIGNAL rd_dat              : STD_LOGIC_VECTOR(c_mm_reg_led.dat_w-1 DOWNTO 0);
   SIGNAL wr_dat              : STD_LOGIC_VECTOR(c_mm_reg_led.dat_w-1 DOWNTO 0);
   SIGNAL wr_val              : STD_LOGIC;
   SIGNAL rd_val              : STD_LOGIC;
   SIGNAL reg_wren            : STD_LOGIC;
   SIGNAL reg_rden            : STD_LOGIC;
   SIGNAL rd_busy             : STD_LOGIC;
   SIGNAL wr_busy             : STD_LOGIC;
   SIGNAL wr_adr              : STD_LOGIC_VECTOR(c_mm_reg_led.adr_w-1 DOWNTO 0);
   SIGNAL rd_adr              : STD_LOGIC_VECTOR(c_mm_reg_led.adr_w-1 DOWNTO 0);

   SIGNAL st_clk              : STD_LOGIC_VECTOR(c_mm_reg_led.nof_slaves-1 DOWNTO 0) := (OTHERS => '1');
   SIGNAL st_rst              : STD_LOGIC_VECTOR(c_mm_reg_led.nof_slaves-1 DOWNTO 0) := (OTHERS => '0');

   SIGNAL led2_colour_arr     : STD_LOGIC_VECTOR(c_mm_reg_led.nof_slaves*c_mm_reg_led.nof_dat*c_mm_reg_led.dat_w-1 DOWNTO 0);

   SIGNAL reg_led_mosi        : t_axi4_lite_mosi;
   SIGNAL reg_led_miso        : t_axi4_lite_miso;

BEGIN

  -- as 10
  -- run 10 us

   mm_clk <= NOT mm_clk OR sim_finished  AFTER mm_clk_period/2;
   mm_rst <= '1', '0'    AFTER mm_clk_period*c_reset_len;

   st_clk(0) <= NOT st_clk(0) OR sim_finished AFTER mm_clk_period*2/3;
   st_rst(0) <= '1', '0'    AFTER mm_clk_period*2/3*c_reset_len;
   st_clk(1) <= NOT st_clk(1) OR sim_finished AFTER mm_clk_period*3/4;
   st_rst(1) <= '1', '0'    AFTER mm_clk_period*3/4*c_reset_len;
   st_clk(2) <= NOT st_clk(2) OR sim_finished AFTER mm_clk_period/5;
   st_rst(2) <= '1', '0'    AFTER mm_clk_period/5*c_reset_len;
   st_clk(3) <= NOT st_clk(3) OR sim_finished AFTER mm_clk_period*5;
   st_rst(3) <= '1', '0'    AFTER mm_clk_period*5*c_reset_len;


u_mem_to_axi4_lite : ENTITY work.mem_to_axi4_lite
                     GENERIC MAP (g_adr_w    => c_mm_reg_led.adr_w,
                                  g_dat_w    => c_mm_reg_led.dat_w,
                                  g_timeout  => 8)
                     PORT MAP (rst        => mm_rst,
                               clk        => mm_clk,
                               sla_in     => reg_led_mosi,
                               sla_out    => reg_led_miso,
                               wren       => reg_wren,
                               rden       => reg_rden,
                               wr_adr     => wr_adr,
                               wr_dat     => wr_dat,
                               wr_val     => wr_val,
                               wr_busy    => wr_busy,
                               rd_adr     => rd_adr,
                               rd_dat     => rd_dat,
                               rd_busy    => rd_busy,
                               rd_val     => rd_val);

led_reg : ENTITY common_lib.common_reg_r_w_dc
          GENERIC MAP (g_reg        => c_mm_reg_led)
          PORT MAP (mm_rst          => mm_rst,
                    mm_clk          => mm_clk,
                    st_clk          => st_clk,
                    st_rst          => st_rst,
                    wr_en           => reg_wren,
                    wr_adr          => wr_adr,
                    wr_dat          => wr_dat,
                    wr_val          => wr_val,
                    wr_busy         => wr_busy,
                    rd_en           => reg_rden,
                    rd_adr          => rd_adr,
                    rd_dat          => rd_dat,
                    rd_val          => rd_val,
                    rd_busy         => rd_busy,
                    reg_wr_arr      => open,
                    reg_rd_arr      => open,
                    out_reg         => led2_colour_arr,
                    in_reg          => led2_colour_arr);



 --
 tb : PROCESS

   BEGIN

      axi_lite_init (mm_rst, mm_clk, reg_led_miso, reg_led_mosi);

      axi_lite_transaction (mm_clk, reg_led_miso, reg_led_mosi, 0, true, X"AABBCCDD");
      axi_lite_transaction (mm_clk, reg_led_miso, reg_led_mosi, 0, false, X"AABBCCDD", validate => true);

      axi_lite_transaction (mm_clk, reg_led_miso, reg_led_mosi, 2, true, X"12345678");
      axi_lite_transaction (mm_clk, reg_led_miso, reg_led_mosi, 2, false, X"12345678", validate => true);

      axi_lite_transaction (mm_clk, reg_led_miso, reg_led_mosi, 5, true, X"900DBEEF");
      axi_lite_transaction (mm_clk, reg_led_miso, reg_led_mosi, 5, false, X"900DBEEF", validate => true);

      axi_lite_transaction (mm_clk, reg_led_miso, reg_led_mosi, 10, true, X"4E770B00");
      axi_lite_transaction (mm_clk, reg_led_miso, reg_led_mosi, 10, false, X"4E770B00", validate => true);

      axi_lite_transaction (mm_clk, reg_led_miso, reg_led_mosi, 2, false, X"12345678", validate => true);

      axi_lite_transaction (mm_clk, reg_led_miso, reg_led_mosi, 13, true, X"12ab5678");
      axi_lite_transaction (mm_clk, reg_led_miso, reg_led_mosi, 13, false, X"12ab5678", validate => true);

      axi_lite_transaction (mm_clk, reg_led_miso, reg_led_mosi, 16, true, X"66666666", expected_fail => true);

      sim_finished <= '1';
      tb_end <= '1';
      wait for 1 us;
      REPORT "Finished Simulation" SEVERITY FAILURE;
 END PROCESS tb;


END tb;
