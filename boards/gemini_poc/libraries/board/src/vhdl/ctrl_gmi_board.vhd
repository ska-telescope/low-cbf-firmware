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
--   . ctrl_gmi_board.vhd with e.g. 1GbE, PPS, I2C, Remu, EPCS

LIBRARY IEEE, UNISIM, common_lib, technology_lib, tech_pll_lib, spi_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE UNISIM.vcomponents.all; 
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE work.gmi_board_pkg.ALL;

ENTITY ctrl_gmi_board IS
  GENERIC (
    ----------------------------------------------------------------------------
    -- General
    ----------------------------------------------------------------------------
    g_technology     : NATURAL := c_tech_xcvu9p;
    g_sim            : BOOLEAN := FALSE;
    g_design_name    : STRING := "UNUSED";
    g_fw_version     : t_gmi_board_fw_version := (0, 0);  -- firmware version x.y
    g_stamp_date     : NATURAL := 0;
    g_stamp_time     : NATURAL := 0;
    g_stamp_svn      : NATURAL := 0;
    g_design_note    : STRING  := "UNUSED";
    g_mm_clk_freq    : NATURAL := c_gmi_board_mm_clk_freq_100M;
 
    
    ----------------------------------------------------------------------------
    -- Auxiliary Interface
    ----------------------------------------------------------------------------
    g_fpga_temp_high : NATURAL := 85;
    g_app_led_red    : BOOLEAN := FALSE;  -- when TRUE use external LED control via app_led_red
    g_app_led_green  : BOOLEAN := FALSE;  -- when TRUE use external LED control via app_led_green
    
    g_aux            : t_c_gmi_board_aux := c_gmi_board_aux;
    g_factory_image  : BOOLEAN := FALSE
  );
  PORT (
    --
    -- System    
    xo_clk                 : OUT STD_LOGIC;   -- 125 MHz CLK
    xo_rst                 : OUT STD_LOGIC;   -- reset in CLK domain released after few cycles
       
    mm_clk                 : OUT STD_LOGIC;   -- MM clock from xo_clk PLL
    mm_rst                 : OUT STD_LOGIC;   -- reset in MM clock domain released after xo_clk PLL locked
    ph_rst                 : OUT STD_LOGIC;   -- reset in MM clock domain released after xo_clk PLL locked
    
    led2_colour_arr        : IN  STD_LOGIC_VECTOR(23 DOWNTO 0);

    --
    -- >>> Ctrl FPGA pins
    --
    -- GENERAL
    CLK_E_P                : IN  STD_LOGIC; -- 125MHz PTP clk
    CLK_E_N                : IN  STD_LOGIC;
    LED_DIN                : OUT STD_LOGIC;
    LED_DOUT               : IN  STD_LOGIC;
    LED_CS                 : OUT STD_LOGIC;
    LED_SCLK               : OUT STD_LOGIC


    -- I2C Interface to Sensors
    --SENS_SC                : INOUT STD_LOGIC := 'Z';
    --SENS_SD                : INOUT STD_LOGIC := 'Z';

    ---- pmbus
    --PMBUS_SC               : INOUT STD_LOGIC := 'Z';
    --PMBUS_SD               : INOUT STD_LOGIC := 'Z';
    --PMBUS_ALERT            : IN    STD_LOGIC := '0';
  );
END ctrl_gmi_board;


ARCHITECTURE str OF ctrl_gmi_board IS

  CONSTANT c_rom_version : NATURAL := 1; -- Only increment when something changes to the register map of rom_system_info. 
  CONSTANT c_reset_len   : NATURAL := 4;  -- >= c_meta_delay_len from common_pkg
  CONSTANT c_mm_clk_freq : NATURAL := sel_a_b(g_sim=FALSE,g_mm_clk_freq,c_gmi_board_mm_clk_freq_10M);
    
  
  -- Clock and reset  
  SIGNAL i_xo_clk               : STD_LOGIC;
  SIGNAL i_xo_rst               : STD_LOGIC;    
  
  SIGNAL i_mm_clk               : STD_LOGIC;
  SIGNAL i_mm_rst               : STD_LOGIC;
  SIGNAL i_ph_rst               : STD_LOGIC;
  
  SIGNAL pll_locked             : STD_LOGIC;
  SIGNAL clk125                 : STD_LOGIC := '1';
  SIGNAL clk100                 : STD_LOGIC := '1';
  SIGNAL clk50                  : STD_LOGIC := '1';

  SIGNAL pulse_10Hz             : STD_LOGIC;
  SIGNAL pulse_10Hz_extended    : STD_LOGIC;
  SIGNAL mm_pulse_ms            : STD_LOGIC;
  SIGNAL mm_pulse_s             : STD_LOGIC;

  SIGNAL led_toggle             : STD_LOGIC;
  SIGNAL led_flash              : STD_LOGIC;
  SIGNAL led_flash_green0       : STD_LOGIC;
  SIGNAL led_flash_green1       : STD_LOGIC;

  -- color leds:
  SIGNAL led1_colour_arr        : STD_LOGIC_VECTOR(23 DOWNTO 0);
  SIGNAL led3_colour_arr        : STD_LOGIC_VECTOR(23 DOWNTO 0);
 
BEGIN
  xo_clk   <= i_xo_clk;  
  xo_rst   <= i_xo_rst;
  
  mm_clk   <= i_mm_clk;
  mm_rst   <= i_mm_rst;
  ph_rst   <= i_ph_rst;
  
  -----------------------------------------------------------------------------
  u_IBUFDS_clk_e_inst : IBUFDS -- page 201 of ug974-vivado-ultrascale-libraries.pdf
                               -- http://www.xilinx.com/support/documentation/sw_manuals/xilinx2016_1/ug974-vivado-ultrascale-libraries.pdf
   PORT MAP (
    O => i_xo_clk,
    I => clk_e_p,
    IB=> clk_e_n
  );

  u_common_areset_xo : ENTITY common_lib.common_areset
  GENERIC MAP (
    g_rst_level => '1',       -- power up default will be inferred in FPGA
    g_delay_len => c_reset_len
  )
  PORT MAP (
    in_rst    => '0',         -- release reset after some clock cycles
    clk       => i_xo_clk,
    out_rst   => i_xo_rst
  );

  i_mm_clk <= clk100;
  
--  gen_mm_clk_sim: IF g_sim = TRUE GENERATE
--      clk50       <= NOT clk50 AFTER 10 ns;      -- 50 MHz, 20ns/2
--      mm_locked   <= '0', '1' AFTER 70 ns;
--  END GENERATE;

--  gen_mm_clk_hardware: IF g_sim = FALSE GENERATE
    u_gmi_board_clk125_pll : ENTITY work.gmi_board_clk125_pll
    GENERIC MAP (
      g_technology => g_technology
    )
    PORT MAP (
      arst       => i_xo_rst,
      clk125     => i_xo_clk,
      c0_clk50   => clk50,
      c1_clk100  => clk100,
      c2_clk125  => clk125,
      pll_locked => pll_locked
    );
--  END GENERATE;

  u_gmi_board_node_ctrl : ENTITY work.gmi_board_node_ctrl
  GENERIC MAP (
    g_pulse_us => c_mm_clk_freq / (10**6)     -- nof system clock cycles to get us period, equal to system clock frequency / 10**6
  )
  PORT MAP (
    -- MM clock domain reset
    mm_clk      => i_mm_clk,
    mm_locked   => pll_locked,
    mm_rst      => i_mm_rst,
    ph_rst      => i_ph_rst,
    
    -- WDI extend
    mm_wdi_in   => mm_pulse_s,
    -- Pulses
    mm_pulse_us => OPEN,
    mm_pulse_ms => mm_pulse_ms,
    mm_pulse_s  => mm_pulse_s  -- could be used to toggle a LED
  );

  ------------------------------------------------------------------------------
  -- Toggle red LED when gmi_minimal is running, green LED for other designs.
  ------------------------------------------------------------------------------
  led_flash_green0 <= sel_a_b(g_factory_image=TRUE,  led_flash, '0');
  led_flash_green1 <= sel_a_b(g_factory_image=FALSE, led_flash, '0');


  u_extend : ENTITY common_lib.common_pulse_extend
  GENERIC MAP (
    g_extend_w => 22 -- (2^22) / 50e6 = 0.083886 th of 1 sec
  )
  PORT MAP (
    rst     => i_mm_rst,
    clk     => i_mm_clk,
    p_in    => mm_pulse_s,
    ep_out  => led_flash
  );


  u_common_pulser_10Hz : ENTITY common_lib.common_pulser
  GENERIC MAP (
    g_pulse_period => 100,
    g_pulse_phase  => 100-1
  )
  PORT MAP (
    rst            => i_mm_rst,
    clk            => i_mm_clk,
    clken          => '1',
    pulse_en       => mm_pulse_ms,
    pulse_out      => pulse_10Hz
  );

  u_extend_10Hz : ENTITY common_lib.common_pulse_extend
  GENERIC MAP (
    g_extend_w => 21 -- (2^21) / 50e6 = 0.041943 th of 1 sec
  )
  PORT MAP (
    rst     => i_mm_rst,
    clk     => i_mm_clk,
    p_in    => pulse_10Hz,
    ep_out  => pulse_10Hz_extended
  );

  u_toggle : ENTITY common_lib.common_toggle
  PORT MAP (
    rst         => i_mm_rst,
    clk         => i_mm_clk,
    in_dat      => mm_pulse_s,
    out_dat     => led_toggle
  );


  u_spi_max6966 : ENTITY spi_lib.spi_max6966
  GENERIC MAP (
    con_simulation => g_sim
  )
  PORT MAP (
    clock       => i_mm_clk,
    reset       => i_mm_rst,
    enable      => '1',
    led1_colour => led1_colour_arr,
    led2_colour => led2_colour_arr,
    led3_colour => led3_colour_arr,
    din         => led_din,
    sclk        => led_sclk,
    cs          => led_cs,
    dout        => led_dout
  );

  -- Copied the color codes from the spi_lib.spi_max6966 testbench
  led1_colour_arr <= X"4578ef" WHEN (led_flash_green0 = '1') ELSE (OTHERS => '0');
  led3_colour_arr <= X"47a6c8" WHEN (led_flash_green1 = '1') ELSE (OTHERS => '0');


END str;
