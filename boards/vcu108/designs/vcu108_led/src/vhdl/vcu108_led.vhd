-------------------------------------------------------------------------------
--
-- Copyright (C) 2016
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

LIBRARY IEEE, UNISIM, common_lib, vcu108_board_lib, technology_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE UNISIM.vcomponents.all; -- IBUFDS, OBUFDS, ...
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE vcu108_board_lib.vcu108_board_pkg.ALL;

ENTITY vcu108_led IS
  GENERIC (
    g_design_name   : STRING  := "vcu108_led";
    g_design_note   : STRING  := "UNUSED";
    g_technology    : NATURAL := c_tech_xcvu095;
    g_sim           : BOOLEAN := FALSE; --Overridden by TB
    g_sim_unb_nr    : NATURAL := 0;
    g_sim_node_nr   : NATURAL := 0;
    g_stamp_date    : NATURAL := 0;  -- Date (YYYYMMDD) -- set by QSF
    g_stamp_time    : NATURAL := 0;  -- Time (HHMMSS)   -- set by QSF
    g_stamp_svn     : NATURAL := 0;  -- SVN revision    -- set by QSF
    g_factory_image : BOOLEAN := TRUE
  );
  PORT (
    CLK_p       : IN    STD_LOGIC;  -- 125 MHz
    CLK_n       : IN    STD_LOGIC;  -- 125 MHz
    GPIOLED     : OUT   STD_LOGIC_VECTOR(c_vcu108_board_nof_gpioleds-1 DOWNTO 0)
  );
END vcu108_led;


ARCHITECTURE str OF vcu108_led IS

  -- Firmware version x.y
  CONSTANT c_fw_version         : t_vcu108_board_fw_version := (1, 1);
  CONSTANT c_reset_len          : NATURAL := 4;  -- >= c_meta_delay_len from common_pkg
  CONSTANT c_mm_clk_freq        : NATURAL := c_vcu108_board_mm_clk_freq_50M;

  -- System
  SIGNAL i_xo_clk               : STD_LOGIC;
  SIGNAL i_xo_rst               : STD_LOGIC;
  SIGNAL i_mm_rst               : STD_LOGIC;
  SIGNAL i_mm_clk               : STD_LOGIC;
  SIGNAL mm_locked              : STD_LOGIC;

  SIGNAL clk125                 : STD_LOGIC := '1';
  SIGNAL clk100                 : STD_LOGIC := '1';
  SIGNAL clk50                  : STD_LOGIC := '1';

  SIGNAL cs_sim                 : STD_LOGIC;
  SIGNAL xo_clk                 : STD_LOGIC;
  SIGNAL xo_rst                 : STD_LOGIC;
  SIGNAL xo_rst_n               : STD_LOGIC;
  SIGNAL mm_clk                 : STD_LOGIC;
  SIGNAL mm_rst                 : STD_LOGIC;

  SIGNAL pulse_10Hz             : STD_LOGIC;
  SIGNAL pulse_10Hz_extended    : STD_LOGIC;
  SIGNAL mm_pulse_ms            : STD_LOGIC;
  SIGNAL mm_pulse_s             : STD_LOGIC;
  
  SIGNAL led_toggle             : STD_LOGIC;
  SIGNAL led_flash              : STD_LOGIC;
  SIGNAL led_flash_green0       : STD_LOGIC;
  SIGNAL led_flash_green1       : STD_LOGIC;

  -- GPIO leds
  SIGNAL green_led_arr          : STD_LOGIC_VECTOR(c_vcu108_board_nof_gpioleds-1 DOWNTO 0);

  COMPONENT vcu108_led_axi_wrapper IS
    PORT (
      axi_led_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      clock_rtl   : IN  STD_LOGIC;
      reset_rtl   : IN  STD_LOGIC
    );
  END COMPONENT vcu108_led_axi_wrapper;
  

BEGIN
  xo_clk  <= i_xo_clk;
  xo_rst     <=     i_xo_rst;
  xo_rst_n   <= NOT i_xo_rst;
  mm_clk     <= i_mm_clk;
  mm_rst     <= i_mm_rst;

  -----------------------------------------------------------------------------

  u_IBUFDS_clk_e_inst : IBUFDS -- page 201 of ug974-vivado-ultrascale-libraries.pdf
                               -- http://www.xilinx.com/support/documentation/sw_manuals/xilinx2016_1/ug974-vivado-ultrascale-libraries.pdf
   PORT MAP (
    O => i_xo_clk,
    I => CLK_p,
    IB=> CLK_n
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

  -----------------------------------------------------------------------------
  -- mm_clk
  -- . use mm_sim_clk in sim
  -- . derived from CLK via PLL on hardware
  -----------------------------------------------------------------------------

  i_mm_clk <= clk50;

  gen_mm_clk_sim: IF g_sim = TRUE GENERATE
      clk50       <= NOT clk50 AFTER 10 ns;      -- 50 MHz, 20ns/2
      mm_locked   <= '0', '1' AFTER 70 ns;
  END GENERATE;

  gen_mm_clk_hardware: IF g_sim = FALSE GENERATE
    u_vcu108_board_clk125_pll : ENTITY vcu108_board_lib.vcu108_board_clk125_pll
    GENERIC MAP (
      g_technology => g_technology
    )
    PORT MAP (
      arst       => i_xo_rst,
      clk125     => i_xo_clk,
      c1_clk50   => clk50,
      pll_locked => mm_locked
    );
  END GENERATE;

  u_vcu108_board_node_ctrl : ENTITY vcu108_board_lib.vcu108_board_node_ctrl
  GENERIC MAP (
    g_pulse_us => c_mm_clk_freq / (10**6)     -- nof system clock cycles to get us period, equal to system clock frequency / 10**6
  )
  PORT MAP (
    -- MM clock domain reset
    mm_clk      => i_mm_clk,
    mm_locked   => mm_locked,
    mm_rst      => i_mm_rst,
    -- WDI extend
    mm_wdi_in   => mm_pulse_s,
    -- Pulses
    mm_pulse_us => OPEN,
    mm_pulse_ms => mm_pulse_ms,
    mm_pulse_s  => mm_pulse_s  -- could be used to toggle a LED
  );

  ------------------------------------------------------------------------------
  -- Toggle red LED when vcu108_minimal is running, green LED for other designs.
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




  -- Green0 LED control
  --GPIOLED(c_vcu108_board_gpioled_green0) <= led_flash_green0;

  -- Green1 LED control
  --GPIOLED(c_vcu108_board_gpioled_green1) <= led_flash_green1;


  
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

  -- connect to LED pulser:
  GPIOLED(4)  <= '1';
  GPIOLED(5)  <= pulse_10Hz_extended;
  GPIOLED(6)  <= NOT led_toggle;
  GPIOLED(7)  <= led_toggle;

  -- connect to JTAG-AXI:
  u_vcu108_led_axi_wrapper : vcu108_led_axi_wrapper
  PORT MAP (
    axi_led_out => GPIOLED(3 DOWNTO 0),
    clock_rtl   => i_mm_clk,
    reset_rtl   => i_mm_rst
  ); 

END str;

