-------------------------------------------------------------------------------
--
-- Copyright (C) 2012-2016
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

-- Purpose: Provide general control infrastructure
-- Usage: In a design <design_name>.vhd that consists of:
--   . mmm_<design_name>.vhd with MM bus and the peripherals
--   . ctrl_vcu108_board.vhd with e.g. 1GbE, PPS, I2C, Remu, EPCS

LIBRARY IEEE, common_lib, technology_lib, tech_pll_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE work.vcu108_board_pkg.ALL;
USE technology_lib.technology_pkg.ALL;

ENTITY ctrl_vcu108_board IS
  GENERIC (
    ----------------------------------------------------------------------------
    -- General
    ----------------------------------------------------------------------------
    g_technology     : NATURAL := c_tech_xcvu095;
    g_sim            : BOOLEAN := FALSE;
    g_design_name    : STRING := "UNUSED";
    g_fw_version     : t_vcu108_board_fw_version := (0, 0);  -- firmware version x.y
    g_stamp_date     : NATURAL := 0;
    g_stamp_time     : NATURAL := 0;
    g_stamp_svn      : NATURAL := 0;
    g_design_note    : STRING  := "UNUSED";
    g_mm_clk_freq    : NATURAL := c_vcu108_board_mm_clk_freq_125M;
 
    
    ----------------------------------------------------------------------------
    -- Auxiliary Interface
    ----------------------------------------------------------------------------
    g_fpga_temp_high : NATURAL := 85;
    g_app_led_red    : BOOLEAN := FALSE;  -- when TRUE use external LED control via app_led_red
    g_app_led_green  : BOOLEAN := FALSE;  -- when TRUE use external LED control via app_led_green
    
    g_aux            : t_c_vcu108_board_aux := c_unb2_board_aux;
    g_factory_image  : BOOLEAN := FALSE
  );
  PORT (
    --
    --
    -- System
    cs_sim                 : OUT STD_LOGIC;
    
    xo_ethclk              : OUT STD_LOGIC;   -- 125 MHz ETH_CLK
    xo_rst                 : OUT STD_LOGIC;   -- reset in ETH_CLK domain released after few cycles
    xo_rst_n               : OUT STD_LOGIC; 
   
    mm_clk                 : OUT STD_LOGIC;   -- MM clock from xo_ethclk PLL
    mm_rst                 : OUT STD_LOGIC;   -- reset in MM clock domain released after xo_ethclk PLL locked
    
    this_chip_id           : OUT STD_LOGIC_VECTOR(c_unb2_board_nof_chip_w-1 DOWNTO 0);      -- [1:0], so range 0-3 for PN
    this_bck_id            : OUT STD_LOGIC_VECTOR(c_unb2_board_nof_uniboard_w-1 DOWNTO 0);  -- [1:0] used out of ID[7:2] to index boards 3..0 in subrack
    
    app_led_red            : IN  STD_LOGIC := '0';
    app_led_green          : IN  STD_LOGIC := '1';
    
    --
    -- >>> Ctrl FPGA pins
    --
    -- GENERAL
    CLK                    : IN    STD_LOGIC; -- System Clock
    PPS                    : IN    STD_LOGIC; -- System Sync
    WDI                    : OUT   STD_LOGIC; -- Watchdog Clear
    INTA                   : INOUT STD_LOGIC; -- FPGA interconnect line
    INTB                   : INOUT STD_LOGIC; -- FPGA interconnect line

    -- Others
    VERSION                : IN    STD_LOGIC_VECTOR(g_aux.version_w-1 DOWNTO 0);
    ID                     : IN    STD_LOGIC_VECTOR(g_aux.id_w-1 DOWNTO 0);
    TESTIO                 : INOUT STD_LOGIC_VECTOR(g_aux.testio_w-1 DOWNTO 0);
    
    -- I2C Interface to Sensors
    SENS_SC                : INOUT STD_LOGIC := 'Z';
    SENS_SD                : INOUT STD_LOGIC := 'Z';

    -- pmbus
    PMBUS_SC               : INOUT STD_LOGIC := 'Z';
    PMBUS_SD               : INOUT STD_LOGIC := 'Z';
    PMBUS_ALERT            : IN    STD_LOGIC := '0';
    
    -- DDR reference clock domains reset creation
    MB_I_REF_CLK           : IN    STD_LOGIC := '0';  -- 25 MHz
    MB_II_REF_CLK          : IN    STD_LOGIC := '0';  -- 25 MHz
    
    -- 1GbE Control Interface
    ETH_CLK                : IN    STD_LOGIC;  -- 125 MHz
    ETH_SGIN               : IN    STD_LOGIC_VECTOR(c_unb2_board_nof_eth-1 DOWNTO 0) := (OTHERS=>'0');
    ETH_SGOUT              : OUT   STD_LOGIC_VECTOR(c_unb2_board_nof_eth-1 DOWNTO 0)
  );
END ctrl_vcu108_board;


ARCHITECTURE str OF ctrl_vcu108_board IS

  CONSTANT c_rom_version : NATURAL := 1; -- Only increment when something changes to the register map of rom_system_info. 

  CONSTANT c_reset_len   : NATURAL := 4;  -- >= c_meta_delay_len from common_pkg
  CONSTANT c_mm_clk_freq : NATURAL := sel_a_b(g_sim=FALSE,g_mm_clk_freq,c_vcu108_board_mm_clk_freq_10M);
    
  
  -- Clock and reset
  SIGNAL i_xo_ethclk            : STD_LOGIC;
  SIGNAL i_xo_rst               : STD_LOGIC;
  SIGNAL i_mm_rst               : STD_LOGIC;
  SIGNAL i_mm_clk               : STD_LOGIC;
  SIGNAL mm_locked              : STD_LOGIC;
  SIGNAL mm_sim_clk             : STD_LOGIC := '1';
  SIGNAL epcs_clk               : STD_LOGIC := '1';
  SIGNAL clk125                 : STD_LOGIC := '1';
  SIGNAL clk100                 : STD_LOGIC := '1';
  SIGNAL clk50                  : STD_LOGIC := '1';

  SIGNAL mm_pulse_ms            : STD_LOGIC;
  SIGNAL mm_pulse_s             : STD_LOGIC;
 
  SIGNAL led_toggle             : STD_LOGIC;
  SIGNAL led_toggle_red         : STD_LOGIC;
  SIGNAL led_toggle_green       : STD_LOGIC;
 
BEGIN

  ext_clk200 <= i_ext_clk200;
  xo_ethclk  <= i_xo_ethclk;
  xo_rst     <=     i_xo_rst;
  xo_rst_n   <= NOT i_xo_rst; 
  mm_clk     <= i_mm_clk;
  mm_rst     <= i_mm_rst;
  
  -----------------------------------------------------------------------------
  -- xo_ethclk = ETH_CLK
  -----------------------------------------------------------------------------
  
  i_xo_ethclk <= ETH_CLK;   -- use the ETH_CLK pin as xo_clk
  
  u_common_areset_xo : ENTITY common_lib.common_areset
  GENERIC MAP (
    g_rst_level => '1',       -- power up default will be inferred in FPGA
    g_delay_len => c_reset_len
  )
  PORT MAP (
    in_rst    => '0',         -- release reset after some clock cycles
    clk       => i_xo_ethclk,
    out_rst   => i_xo_rst
  );


  -----------------------------------------------------------------------------
  -- mm_clk
  -- . use mm_sim_clk in sim
  -- . derived from ETH_CLK via PLL on hardware
  -----------------------------------------------------------------------------

  i_mm_clk <= mm_sim_clk WHEN g_sim = TRUE ELSE
              clk125     WHEN g_mm_clk_freq = c_vcu108_board_mm_clk_freq_125M ELSE
              clk100     WHEN g_mm_clk_freq = c_vcu108_board_mm_clk_freq_100M ELSE
              clk50      WHEN g_mm_clk_freq = c_vcu108_board_mm_clk_freq_50M  ELSE
              clk50;  -- default

  gen_mm_clk_sim: IF g_sim = TRUE GENERATE
      epcs_clk    <= NOT epcs_clk AFTER 25 ns; -- 20 MHz, 50ns/2
      clk50       <= NOT clk50 AFTER 10 ns;    -- 50 MHz, 20ns/2
      clk100      <= NOT clk100 AFTER 5 ns;    -- 100 MHz, 10ns/2
      clk125      <= NOT clk125 AFTER 4 ns;    -- 125 MHz, 8ns/2
      mm_sim_clk  <= NOT mm_sim_clk AFTER 50 ns;  -- 10 MHz, 100ns/2
      mm_locked   <= '0', '1' AFTER 70 ns;
  END GENERATE;

  gen_mm_clk_hardware: IF g_sim = FALSE GENERATE
    u_vcu108_board_clk125_pll : ENTITY work.vcu108_board_clk125_pll
    GENERIC MAP (
      g_technology => g_technology
    )
    PORT MAP (
      arst       => i_xo_rst,
      clk125     => i_xo_ethclk,
      c0_clk20   => epcs_clk,
      c1_clk50   => clk50,
      c2_clk100  => clk100,
      c3_clk125  => clk125,
      pll_locked => mm_locked
    );
  END GENERATE;

  u_vcu108_board_node_ctrl : ENTITY work.vcu108_board_node_ctrl
  GENERIC MAP (
    g_pulse_us => c_mm_clk_freq / (10**6)     -- nof system clock cycles to get us period, equal to system clock frequency / 10**6
  )
  PORT MAP (
    -- MM clock domain reset
    mm_clk      => i_mm_clk,
    mm_locked   => mm_locked,
    mm_rst      => i_mm_rst,
    -- WDI extend
    mm_wdi_in   => pout_wdi,
    mm_wdi_out  => mm_wdi,  -- actively toggle the WDI via pout_wdi from software with toggle extend to allow software reload
    -- Pulses
    mm_pulse_us => OPEN,
    mm_pulse_ms => mm_pulse_ms,
    mm_pulse_s  => mm_pulse_s  -- could be used to toggle a LED
  );
  
  -----------------------------------------------------------------------------
  -- System info
  -----------------------------------------------------------------------------
  cs_sim <= is_true(g_sim);
  


  -----------------------------------------------------------------------------
  -- Red LED control
  -----------------------------------------------------------------------------

  gen_app_led_red: IF g_app_led_red = TRUE GENERATE
    -- Let external app control the LED via the app_led_red input
    TESTIO(c_vcu108_board_testio_led_red)   <= app_led_red;
  END GENERATE;

  no_app_led_red: IF g_app_led_red = FALSE GENERATE
    TESTIO(c_vcu108_board_testio_led_red)   <= led_toggle_red;   
  END GENERATE;


  -----------------------------------------------------------------------------
  -- Green LED control
  -----------------------------------------------------------------------------

  gen_app_led_green: IF g_app_led_green = TRUE GENERATE
    -- Let external app control the LED via the app_led_green input
    TESTIO(c_vcu108_board_testio_led_green) <= app_led_green;  
  END GENERATE;

  no_app_led_green: IF g_app_led_green = FALSE GENERATE
    TESTIO(c_vcu108_board_testio_led_green) <= led_toggle_green;   
  END GENERATE;


  ------------------------------------------------------------------------------
  -- Toggle red LED when unb2_minimal is running, green LED for other designs.
  ------------------------------------------------------------------------------
  led_toggle_red   <= sel_a_b(g_factory_image=TRUE,  led_toggle, '0');
  led_toggle_green <= sel_a_b(g_factory_image=FALSE, led_toggle, '0');

  u_toggle : ENTITY common_lib.common_toggle
  PORT MAP (
    rst         => i_mm_rst,
    clk         => i_mm_clk,
    in_dat      => mm_pulse_s,
    out_dat     => led_toggle
  );


END str;
