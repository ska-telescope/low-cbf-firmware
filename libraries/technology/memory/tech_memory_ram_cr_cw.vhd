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

ENTITY tech_memory_ram_cr_cw IS
  GENERIC (
    g_technology : t_technology := c_tech_select_default;
    g_adr_w      : NATURAL := 5;
    g_dat_w      : NATURAL := 8;
    g_nof_words  : NATURAL := 2**5;
    g_rd_latency : NATURAL := 2;  -- choose 1 or 2
    g_init_file  : STRING  := "UNUSED"
  );
  PORT
  (
    data      : IN  STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    rdaddress : IN  STD_LOGIC_VECTOR (g_adr_w-1 DOWNTO 0);
    rdclock   : IN  STD_LOGIC ;
    rdclocken : IN  STD_LOGIC  := '1';
    wraddress : IN  STD_LOGIC_VECTOR (g_adr_w-1 DOWNTO 0);
    wrclock   : IN  STD_LOGIC  := '1';
    wrclocken : IN  STD_LOGIC  := '1';
    wren      : IN  STD_LOGIC  := '0';
    q         : OUT STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0)
  );
END tech_memory_ram_cr_cw;

ARCHITECTURE str OF tech_memory_ram_cr_cw IS

   CONSTANT c_ultrascale_memory_init      : STRING := tech_sel_a_b(g_init_file, "UNUSED", "none", g_init_file);

BEGIN

  gen_ip_stratixiv : IF tech_is_device(g_technology, c_tech_device_stratixiv) GENERATE
    u0 : ip_stratixiv_ram_cr_cw
    GENERIC MAP (g_adr_w, g_dat_w, g_nof_words, g_rd_latency, g_init_file)
    PORT MAP (data, rdaddress, rdclock, rdclocken, wraddress, wrclock, wrclocken, wren, q);
  END GENERATE;

  gen_ip_arria10 : IF tech_is_device(g_technology, c_tech_device_arria10) GENERATE
    u0 : ip_arria10_ram_cr_cw
    GENERIC MAP (FALSE, g_adr_w, g_dat_w, g_nof_words, g_rd_latency, g_init_file)
    PORT MAP (data, rdaddress, rdclock, wraddress, wrclock, wren, q);
  END GENERATE;

  gen_ip_arria10_e3sge3 : IF tech_is_device(g_technology, c_tech_device_arria10_e3sge3) GENERATE
    u0 : ip_arria10_e3sge3_ram_cr_cw
    GENERIC MAP (FALSE, g_adr_w, g_dat_w, g_nof_words, g_rd_latency, g_init_file)
    PORT MAP (data, rdaddress, rdclock, wraddress, wrclock, wren, q);
  END GENERATE;

  gen_ip_ultrascale: IF tech_is_device(g_technology, c_tech_device_ultrascalep + c_tech_device_ultrascale) GENERATE
    u0: xpm_memory_sdpram GENERIC MAP (MEMORY_SIZE => g_nof_words*g_dat_w, MEMORY_PRIMITIVE => "auto", CLOCKING_MODE => "independent_clock",
                                       MEMORY_INIT_FILE => c_ultrascale_memory_init, MEMORY_INIT_PARAM => "",
                                       USE_MEM_INIT => 1, WAKEUP_TIME => "disable_sleep", MESSAGE_CONTROL => 0,
                                       ECC_MODE => "no_ecc", AUTO_SLEEP_TIME => 0, WRITE_DATA_WIDTH_A => g_dat_w,
                                       BYTE_WRITE_WIDTH_A => g_dat_w, ADDR_WIDTH_A => g_adr_w, READ_DATA_WIDTH_B => g_dat_w,
                                       ADDR_WIDTH_B => g_adr_w, READ_RESET_VALUE_B => "0", READ_LATENCY_B => g_rd_latency,
                                       WRITE_MODE_B => "no_change")
                          PORT MAP (sleep => '0', clka => wrclock, ena => wrclocken,
                                    wea(0) => wren, addra => wraddress, dina => data,
                                    injectsbiterra => '0', injectdbiterra => '0',
                                    clkb => rdclock, rstb => '0', enb => rdclocken,
                                    regceb => rdclocken, addrb => rdaddress, doutb => q,
                                    sbiterrb => open, dbiterrb => open);
  END GENERATE;


END ARCHITECTURE;
