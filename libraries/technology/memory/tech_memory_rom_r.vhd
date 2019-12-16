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

LIBRARY ieee, technology_lib;
USE ieee.std_logic_1164.all;
USE work.tech_memory_component_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;

LIBRARY xpm;
use xpm.vcomponents.all;

ENTITY tech_memory_rom_r IS
  GENERIC (
    g_technology : t_technology := c_tech_select_default;
    g_adr_w      : NATURAL := 5;
    g_dat_w      : NATURAL := 8;
    g_nof_words  : NATURAL := 2**5;
    g_init_file  : STRING  := "UNUSED"
  );
  PORT (
    address   : IN STD_LOGIC_VECTOR(g_adr_w-1 DOWNTO 0);
    clock     : IN STD_LOGIC  := '1';
    clken     : IN STD_LOGIC  := '1';
    q         : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0)
  );
END tech_memory_rom_r;

ARCHITECTURE str OF tech_memory_rom_r IS

   CONSTANT c_ultrascale_memory_init      : STRING := tech_sel_a_b(g_init_file, "UNUSED", "none", g_init_file);

BEGIN

  gen_ip_stratixiv : IF tech_is_device(g_technology, c_tech_device_stratixiv) GENERATE
    u0 : ip_stratixiv_rom_r
    GENERIC MAP (g_adr_w, g_dat_w, g_nof_words, g_init_file)
    PORT MAP (address, clock, clken, q);
  END GENERATE;

  gen_ip_arria10 : IF tech_is_device(g_technology, c_tech_device_arria10) GENERATE
    -- use ip_arria10_ram_r_w as ROM
    u0 : ip_arria10_ram_r_w
    GENERIC MAP (FALSE, g_adr_w, g_dat_w, g_nof_words, 1, g_init_file)
    PORT MAP (
      clk         => clock,
      --data        => ,
      rdaddress   => address,
      --wraddress   => ,
      --wren        => ,
      q           => q
    );
  END GENERATE;

  gen_ip_arria10_e3sge3 : IF tech_is_device(g_technology, c_tech_device_arria10_e3sge3) GENERATE
    -- use ip_arria10_e3sge3_ram_r_w as ROM
    u0 : ip_arria10_e3sge3_ram_r_w
    GENERIC MAP (FALSE, g_adr_w, g_dat_w, g_nof_words, 1, g_init_file)
    PORT MAP (
      clk         => clock,
      --data        => ,
      rdaddress   => address,
      --wraddress   => ,
      --wren        => ,
      q           => q
    );
  END GENERATE;

  gen_ip_ultrascale: IF tech_is_device(g_technology, c_tech_device_ultrascalep + c_tech_device_ultrascale) GENERATE
    u0: xpm_memory_sprom GENERIC MAP (MEMORY_SIZE => g_nof_words*g_dat_w, MEMORY_PRIMITIVE => "auto", MEMORY_INIT_FILE => c_ultrascale_memory_init,
                                      MEMORY_INIT_PARAM => "", USE_MEM_INIT => 1, WAKEUP_TIME => "disable_sleep", MESSAGE_CONTROL => 1,
                                      ECC_MODE => "no_ecc", AUTO_SLEEP_TIME => 0, READ_DATA_WIDTH_A => g_dat_w, ADDR_WIDTH_A => g_adr_w,
                                      READ_RESET_VALUE_A => "0", READ_LATENCY_A => 1)
                         PORT MAP (sleep => '0', clka => clock, rsta => '0', ena => clken, regcea => clken,
                                   addra => address, injectsbiterra => '0', injectdbiterra => '0',
                                   douta => q, sbiterra => open, dbiterra => open);
  END GENERATE;



END ARCHITECTURE;
