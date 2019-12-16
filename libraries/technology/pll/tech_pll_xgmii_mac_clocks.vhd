-------------------------------------------------------------------------------
--
-- Copyright (C) 2014
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

-- Purpose: Create 156.25 and 312.5  MHz clocks for 10GBASE-R and MAC-10G
-- Description:
--   The reference clock frequency for the PLL is 644.53125 MHz.
-- Remark:
-- . This PLL is typically instantiated at the top level of a design in the
--   board support component rather than at the ETH-10G instance. The
--   advantages are:
--   - this avoids having to propagate up the PLL output clocks through the
--     hierarchy, which can cause delta-cycle mismatch between clock
--     processes at different levels in the hierarchy.
--   - the 156 and 312 MHz clocks are also available for other purposes.
-- .

LIBRARY ieee, technology_lib, common_lib;
USE ieee.std_logic_1164.all;
USE work.tech_pll_component_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE common_lib.common_pkg.ALL;

ENTITY tech_pll_xgmii_mac_clocks IS
  GENERIC (
    g_technology  : t_technology := c_tech_select_default
  );
  PORT (
    refclk_644 : IN  STD_LOGIC;   -- 644.53125 MHz reference clock for PLL
    rst_in     : IN  STD_LOGIC;   -- PLL powerdown input, as reset
    clk_156    : OUT STD_LOGIC;   -- 156.25 MHz PLL output clock
    clk_312    : OUT STD_LOGIC;   -- 312.5  MHz PLL output clock
    rst_156    : OUT STD_LOGIC;   -- reset in clk_156 domain based on PLL locked
    rst_312    : OUT STD_LOGIC    -- reset in clk_312 domain based on PLL locked
  );
END tech_pll_xgmii_mac_clocks;

ARCHITECTURE str OF tech_pll_xgmii_mac_clocks IS

  SIGNAL pll_locked    : STD_LOGIC;
  SIGNAL pll_locked_n  : STD_LOGIC;

  SIGNAL i_clk_156     : STD_LOGIC;
  SIGNAL i_clk_312     : STD_LOGIC;

BEGIN

  gen_ip_arria10 : IF g_technology=c_tech_arria10 GENERATE
    u0 : ip_arria10_pll_xgmii_mac_clocks
    PORT MAP (
      pll_refclk0   => refclk_644,
      pll_powerdown => rst_in,
      pll_locked    => pll_locked,
      outclk0       => i_clk_156,
      pll_cal_busy  => OPEN,
      outclk1       => i_clk_312
    );
  END GENERATE;

  gen_ip_arria10_e3sge3 : IF g_technology=c_tech_arria10_e3sge3 GENERATE
    u0 : ip_arria10_e3sge3_pll_xgmii_mac_clocks
    PORT MAP (
      pll_refclk0   => refclk_644,
      pll_powerdown => rst_in,
      pll_locked    => pll_locked,
      outclk0       => i_clk_156,
      pll_cal_busy  => OPEN,
      outclk1       => i_clk_312
    );
  END GENERATE;

  pll_locked_n <= NOT pll_locked;

  -- The delta-cycle difference in simulation between i_clk and output clk is no issue because i_clk is only used to create rst which is not clk cycle critical
  clk_156 <= i_clk_156;
  clk_312 <= i_clk_312;

  u_common_areset_156 : ENTITY common_lib.common_areset
  GENERIC MAP (
    g_rst_level => '1',
    g_delay_len => c_meta_delay_len
  )
  PORT MAP (
    in_rst    => pll_locked_n,
    clk       => i_clk_156,
    out_rst   => rst_156
  );

  u_common_areset_312 : ENTITY common_lib.common_areset
  GENERIC MAP (
    g_rst_level => '1',
    g_delay_len => c_meta_delay_len
  )
  PORT MAP (
    in_rst    => pll_locked_n,
    clk       => i_clk_312,
    out_rst   => rst_312
  );

END ARCHITECTURE;
