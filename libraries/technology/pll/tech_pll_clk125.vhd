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
USE work.tech_pll_component_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;


ENTITY tech_pll_clk125 IS
  GENERIC (
    g_technology : t_technology := c_tech_select_default
  );
  PORT (
    areset  : IN STD_LOGIC  := '0';
    inclk0  : IN STD_LOGIC  := '0';
    c0      : OUT STD_LOGIC ;
    c1      : OUT STD_LOGIC ;
    c2      : OUT STD_LOGIC ;
    c3      : OUT STD_LOGIC ;
    c4      : OUT STD_LOGIC;
    locked  : OUT STD_LOGIC
  );
END tech_pll_clk125;

ARCHITECTURE str OF tech_pll_clk125 IS

BEGIN

  gen_ip_arria10 : IF tech_is_device(g_technology,c_tech_device_arria10) GENERATE
    u0 : ip_arria10_pll_clk125
    PORT MAP (
      rst      => areset,
      refclk   => inclk0,
      outclk_0 => c0,
      outclk_1 => c1,
      outclk_2 => c2,
      outclk_3 => c3,
      locked   => locked
    );
  END GENERATE;

  gen_ip_arria10_e3sge3 : IF tech_is_device(g_technology,c_tech_device_arria10_e3sge3) GENERATE
    u0 : ip_arria10_e3sge3_pll_clk125
    PORT MAP (
      rst      => areset,
      refclk   => inclk0,
      outclk_0 => c0,
      outclk_1 => c1,
      outclk_2 => c2,
      outclk_3 => c3,
      locked   => locked
    );
  END GENERATE;

--  gen_ip_xcvu095 : IF tech_is_device(g_technology,c_tech_device_ultrascalep + c_tech_device_ultrascale) GENERATE
--    u0 : ip_xcvu095_mmcm_clk125
--    PORT MAP (
--      clk_in1  => inclk0,
--     -- clk_out0 => c0,
--      clk_out1 => c1,
--      clk_out2 => c2,
--      clk_out3 => c3,
--      reset    => areset,
--      locked   => locked
--    );
--  END GENERATE;
--
--  gen_ip_xcvu190 : IF tech_is_device(g_technology,c_tech_device_ultrascalep + c_tech_device_ultrascale) GENERATE
--    u0 : ip_xcvu190_mmcm_clk125
--    PORT MAP (
--      clk_in1  => inclk0,
--     -- clk_out0 => c0,
--      clk_out1 => c1,
--      clk_out2 => c2,
--      clk_out3 => c3,
--      reset    => areset,
--      locked   => locked
--    );
--  END GENERATE;

  gen_ip_xcvu9p : IF tech_is_device(g_technology,c_tech_device_ultrascalep) GENERATE
    u0 : ip_xcvu9p_mmcm_clk125
    PORT MAP (
      clk_in1  => inclk0,
      clk_out1 => c0,
      clk_out2 => c1,
      clk_out3 => c2,
      --clk_out4 => '0',--c3,
      --clk_out5 => '0',--c4,
      reset    => areset,
      locked   => locked
    );
  END GENERATE;

  gen_ip_xcku040 : IF tech_is_device(g_technology, c_tech_device_ultrascale) GENERATE
    u0 : ip_xcku040_mmcm_clk125
    PORT MAP (
      clk_in1  => inclk0,
      clk_out1 => c0,
      clk_out2 => c1,
      clk_out3 => c2,
      --clk_out4 => '0',--c3,
      --clk_out5 => '0',--c4,
      reset    => areset,
      locked   => locked
    );
  END GENERATE;
END ARCHITECTURE;
