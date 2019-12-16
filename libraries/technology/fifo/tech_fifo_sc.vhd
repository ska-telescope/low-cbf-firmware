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

LIBRARY ieee, technology_lib, tech_fifo_lib, xpm;
USE ieee.std_logic_1164.all;
USE tech_fifo_lib.tech_fifo_component_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE xpm.vcomponents.ALL;


ENTITY tech_fifo_sc IS
  GENERIC (
    g_technology        : t_technology := c_tech_select_default;
    g_use_eab           : STRING := "ON";
    g_prog_full_thresh  : INTEGER;
    g_prog_empty_thresh : INTEGER;
    g_fifo_latency      : INTEGER := 1;
    g_dat_w             : NATURAL;
    g_nof_words         : NATURAL
  );
  PORT (
    aclr       : IN STD_LOGIC;
    clock      : IN STD_LOGIC;
    data       : IN STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    rdreq      : IN STD_LOGIC;
    wrreq      : IN STD_LOGIC;
    empty      : OUT STD_LOGIC;
    prog_empty : OUT STD_LOGIC;
    full       : OUT STD_LOGIC;
    prog_full  : OUT STD_LOGIC;
    q          : OUT STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    usedw      : OUT STD_LOGIC_VECTOR (tech_ceil_log2(g_nof_words)-1 DOWNTO 0)
  );
END tech_fifo_sc;


ARCHITECTURE str OF tech_fifo_sc IS

   CONSTANT c_ultrascale_memory_type      : STRING := tech_sel_a_b(g_use_eab, "ON", "auto", "distributed");
   CONSTANT c_ultrascale_fwft             : STRING := tech_sel_a_b(g_fifo_latency, "std", "fwft");

   SIGNAL rd_data_count                   : STD_LOGIC_VECTOR(tech_ceil_log2(g_nof_words) DOWNTO 0);

BEGIN

  gen_ip_stratixiv : IF tech_is_device(g_technology, c_tech_device_stratixiv) GENERATE
    u0 : ip_stratixiv_fifo_sc
    GENERIC MAP (g_use_eab, g_dat_w, g_nof_words)
    PORT MAP (aclr, clock, data, rdreq, wrreq, empty, full, q, usedw);
  END GENERATE;

  gen_ip_arria10 : IF tech_is_device(g_technology, c_tech_device_arria10) GENERATE
    u0 : ip_arria10_fifo_sc
    GENERIC MAP (g_use_eab, g_dat_w, g_nof_words)
    PORT MAP (aclr, clock, data, rdreq, wrreq, empty, full, q, usedw);
  END GENERATE;

  gen_ip_arria10_e3sge3 : IF tech_is_device(g_technology, c_tech_device_arria10_e3sge3) GENERATE
    u0 : ip_arria10_e3sge3_fifo_sc
    GENERIC MAP (g_use_eab, g_dat_w, g_nof_words)
    PORT MAP (aclr, clock, data, rdreq, wrreq, empty, full, q, usedw);
  END GENERATE;

  gen_ip_ultrascale: IF tech_is_device(g_technology, c_tech_device_ultrascalep + c_tech_device_ultrascale) GENERATE
    u0: xpm_fifo_sync
    GENERIC MAP (FIFO_MEMORY_TYPE => c_ultrascale_memory_type, ECC_MODE => "no_ecc",
                 FIFO_WRITE_DEPTH => g_nof_words, WRITE_DATA_WIDTH => g_dat_w,
                 WR_DATA_COUNT_WIDTH => tech_ceil_log2(g_nof_words)+1,
                 PROG_FULL_THRESH => g_prog_full_thresh, FULL_RESET_VALUE => 0,
                 READ_MODE => c_ultrascale_fwft, FIFO_READ_LATENCY => g_fifo_latency,
                 READ_DATA_WIDTH => g_dat_w, RD_DATA_COUNT_WIDTH => tech_ceil_log2(g_nof_words)+1,                      -- To get the counts right you need 1 extra bit, probably from FWFT type having extra counts?
                 PROG_EMPTY_THRESH => g_prog_empty_thresh, DOUT_RESET_VALUE => "0", WAKEUP_TIME => 0)
    PORT MAP (rst => aclr, wr_clk => clock, wr_en => wrreq, din => data, full => full,
              overflow => open, wr_rst_busy => open, rd_en => rdreq, dout => q, empty => empty,
              underflow => open, rd_rst_busy => open, prog_full => prog_full, wr_data_count => open,
              prog_empty => prog_empty, rd_data_count => rd_data_count, sleep => '0',
              injectsbiterr => '0', injectdbiterr => '0', sbiterr => OPEN, dbiterr => OPEN);

  usedw <= rd_data_count(usedw'RANGE);

  END GENERATE;

END ARCHITECTURE;
