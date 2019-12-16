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


ENTITY tb_axi4_lite_ram IS
END tb_axi4_lite_ram;

ARCHITECTURE tb OF tb_axi4_lite_ram IS

   CONSTANT mm_clk_period     : TIME := 40 ns;
   CONSTANT usr_clk_period    : TIME := 10 ns;
   CONSTANT c_reset_len       : NATURAL := 16;

   CONSTANT dat_w             : INTEGER := 32;
   CONSTANT adr_w             : INTEGER := 8;

   CONSTANT c_mm_usr_ram      : t_c_mem :=   (latency     => 1,
                                              adr_w	    => 5,
                                              dat_w	    => 8,
                                              nof_dat	    => 32,
                                              nof_slaves  => 1,
                                              addr_base   => 0,
                                              init_sl     => '0');

   CONSTANT ram_addr_base     : NATURAL := to_integer(shift_right(to_unsigned(c_mm_usr_ram.addr_base, 32), ceil_log2(c_mm_usr_ram.nof_dat))) ;

   SIGNAL mm_rst              : STD_LOGIC;
   SIGNAL mm_clk              : STD_LOGIC := '0';
   SIGNAL usr_rst             : STD_LOGIC;
   SIGNAL usr_clk             : STD_LOGIC := '0';
   SIGNAL sim_finished        : STD_LOGIC := '0';
   SIGNAL tb_end              : STD_LOGIC := '0';


   SIGNAL rd_dat              : STD_LOGIC_VECTOR(dat_w-1 DOWNTO 0);
   SIGNAL wr_dat              : STD_LOGIC_VECTOR(dat_w-1 DOWNTO 0);
   SIGNAL wr_val              : STD_LOGIC;
   SIGNAL rd_val              : STD_LOGIC;
   SIGNAL reg_wren            : STD_LOGIC;
   SIGNAL reg_rden            : STD_LOGIC;
   SIGNAL wr_adr              : STD_LOGIC_VECTOR(adr_w-1 DOWNTO 0);
   SIGNAL rd_adr              : STD_LOGIC_VECTOR(adr_w-1 DOWNTO 0);

   SIGNAL ram_wr_en           : STD_LOGIC;
   SIGNAL ram_rd_en           : STD_LOGIC;
   SIGNAL ram_adr             : STD_LOGIC_VECTOR(c_mm_usr_ram.adr_w-1 DOWNTO 0);
   SIGNAL ram_rd_dat          : STD_LOGIC_VECTOR(c_mm_usr_ram.dat_w-1 DOWNTO 0);

   SIGNAL axi_mosi            : t_axi4_lite_mosi;
   SIGNAL axi_miso            : t_axi4_lite_miso;

BEGIN



   mm_clk <= NOT mm_clk OR sim_finished  AFTER mm_clk_period/2;
   mm_rst <= '1', '0'    AFTER mm_clk_period*c_reset_len;

   usr_clk <= NOT usr_clk OR sim_finished  AFTER usr_clk_period/2;
   usr_rst <= '1', '0'    AFTER usr_clk_period*c_reset_len;

   u_mem_to_axi4_lite : ENTITY work.mem_to_axi4_lite
   GENERIC MAP (
      g_adr_w    => adr_w,
      g_dat_w    => dat_w)
   PORT MAP (
      rst        => mm_rst,
      clk        => mm_clk,
      sla_in     => axi_mosi,
      sla_out    => axi_miso,
      wren       => reg_wren,
      rden       => reg_rden,
      wr_adr     => wr_adr,
      wr_dat     => wr_dat,
      wr_val     => wr_val,
      wr_busy    => '0',
      rd_adr     => rd_adr,
      rd_dat     => rd_dat,
      rd_busy    => '0',
      rd_val     => rd_val);


   ram_wr_en <= reg_wren AND is_true(ram_addr_base = unsigned(wr_adr(wr_adr'length-1 downto c_mm_usr_ram.adr_w)));
   ram_rd_en <= reg_rden AND is_true(ram_addr_base = unsigned(rd_adr(rd_adr'length-1 downto c_mm_usr_ram.adr_w)));

	ram_adr <= wr_adr(c_mm_usr_ram.adr_w-1 downto 0) WHEN ram_wr_en = '1' ELSE
				  rd_adr(c_mm_usr_ram.adr_w-1 downto 0);

   u_ram : ENTITY common_lib.common_ram_crw_crw
   GENERIC MAP (
      g_ram               => c_mm_usr_ram,
      g_true_dual_port    => TRUE)
   PORT MAP (
      rst_a       => mm_rst,
      rst_b       => usr_rst,
      clk_a       => mm_clk,
      clk_b       => usr_clk,
      clken_a     => '1',
      clken_b     => '1',
      wr_en_a     => ram_wr_en,
      wr_dat_a    => wr_dat(c_mm_usr_ram.dat_w-1 downto 0),
      adr_a       => ram_adr,
      rd_en_a     => ram_rd_en,
      rd_dat_a    => ram_rd_dat,
      rd_val_a    => rd_val,
      wr_en_b     => '0',
      wr_dat_b    => X"00",
      adr_b       => "00000",
      rd_en_b     => '0',
      rd_dat_b    => OPEN,
      rd_val_b    => OPEN
   );

    u_ram_wr_val : ENTITY common_lib.common_pipeline
    GENERIC MAP (
        g_pipeline   => c_mm_usr_ram.latency,
        g_in_dat_w   => c_mm_usr_ram.nof_slaves,
        g_out_dat_w  => c_mm_usr_ram.nof_slaves)
    PORT MAP (
        clk          => mm_clk,
        clken        => '1',
        in_dat(0)    => ram_wr_en,
        out_dat(0)   => wr_val);

   rd_dat <= "000000000000000000000000" & ram_rd_dat WHEN rd_val = '1' ELSE (OTHERS => '0');


 --
 tb : PROCESS

      variable data_in     : t_slv_32_arr(0 TO 10);
   BEGIN

      axi_lite_init (mm_rst, mm_clk, axi_miso, axi_mosi);

      -- Read and write a number of words to memory
      for i in 0 to 10 loop
         data_in(i) := std_logic_vector(to_unsigned(57+i, 32));
      end loop;
      axi_lite_transaction (mm_clk, axi_miso, axi_mosi, 0, true, data_in, mask => c_mask_zeros);


      for i in 0 to 10 loop
         data_in(i) := std_logic_vector(to_unsigned(57+i, 32));
      end loop;
      axi_lite_transaction (mm_clk, axi_miso, axi_mosi, 0, false, data_in, validate => true);



      sim_finished <= '1';
      tb_end <= '1';
      wait for 1 us;
      REPORT "Finished Simulation" SEVERITY FAILURE;
      WAIT;
 END PROCESS tb;


END tb;
