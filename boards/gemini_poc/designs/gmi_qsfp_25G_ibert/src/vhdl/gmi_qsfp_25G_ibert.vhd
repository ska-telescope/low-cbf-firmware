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

LIBRARY IEEE, UNISIM, common_lib, gmi_board_lib, technology_lib, spi_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE gmi_board_lib.gmi_board_pkg.ALL;
USE UNISIM.vcomponents.all; -- IBUFDS, OBUFDS, ...

ENTITY gmi_qsfp_25G_ibert IS
  GENERIC (
    g_design_name   : STRING  := "gmi_qsfp_25G_ibert";
    g_design_note   : STRING  := "UNUSED";
    g_technology    : NATURAL := c_tech_xcvu9p;
    g_sim           : BOOLEAN := FALSE; --Overridden by TB
    g_sim_unb_nr    : NATURAL := 0;
    g_sim_node_nr   : NATURAL := 0;
    g_stamp_date    : NATURAL := 0;  -- Date (YYYYMMDD)
    g_stamp_time    : NATURAL := 0;  -- Time (HHMMSS)
    g_stamp_svn     : NATURAL := 0;  -- SVN revision
    g_factory_image : BOOLEAN := TRUE;
    C_NUM_GTY_QUADS : NATURAL := 4;
    C_GTY_REFCLKS_USED : NATURAL := 4 
  );
  PORT (
    clk_e_p     : in std_logic; -- 125MHz PTP clk
    clk_e_n     : in std_logic;
    debug_mmbx  : out std_logic;
    led_din     : out std_logic;
    led_dout    : in  std_logic;
    led_cs      : out std_logic;
    led_sclk    : out std_logic;

    gty_txn_o   : out std_logic_vector((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);
    gty_txp_o   : out std_logic_vector((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);
    gty_rxn_i   : in std_logic_vector((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);
    gty_rxp_i   : in std_logic_vector((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);

    gty_sysclkp_i : in std_logic;
    gty_sysclkn_i : in std_logic;

    gty_refclk0p_i : in std_logic_vector(C_GTY_REFCLKS_USED-1 DOWNTO 0);
    gty_refclk0n_i : in std_logic_vector(C_GTY_REFCLKS_USED-1 DOWNTO 0);
    gty_refclk1p_i : in std_logic_vector(C_GTY_REFCLKS_USED-1 DOWNTO 0);
    gty_refclk1n_i : in std_logic_vector(C_GTY_REFCLKS_USED-1 DOWNTO 0);

    qsfp_a_reset  : out std_logic;
    qsfp_b_reset: out std_logic;
    qsfp_c_reset: out std_logic;
    qsfp_d_reset: out std_logic;
    qsfp_clock_sel: out std_logic
  );
END gmi_qsfp_25G_ibert;

ARCHITECTURE str OF gmi_qsfp_25G_ibert IS

  -- Firmware version x.y
  CONSTANT c_fw_version         : t_gmi_board_fw_version := (1, 1);
  CONSTANT c_reset_len          : NATURAL := 4;  -- >= c_meta_delay_len from common_pkg
  CONSTANT c_mm_clk_freq        : NATURAL := c_gmi_board_mm_clk_freq_50M;

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

  -- color leds:
  SIGNAL led1_colour_arr        : STD_LOGIC_VECTOR(23 DOWNTO 0);
  SIGNAL led3_colour_arr        : STD_LOGIC_VECTOR(23 DOWNTO 0);

  SIGNAL reg_axi_out            : STD_LOGIC_VECTOR(23 DOWNTO 0);


  COMPONENT gmi_led_axi_wrapper IS
    PORT (
      axi_led_out : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
      clock_rtl   : IN  STD_LOGIC;
      reset_rtl   : IN  STD_LOGIC
    );
  END COMPONENT gmi_led_axi_wrapper;

component example_ibert_ultrascale_gty_0 is
port (
    gty_txn_o   : out std_logic_vector((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);
    gty_txp_o   : out std_logic_vector((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);
    gty_rxn_i   : in std_logic_vector((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);
    gty_rxp_i   : in std_logic_vector((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);

    gty_sysclkp_i : in std_logic;
    gty_sysclkn_i : in std_logic;

    gty_refclk0p_i : in std_logic_vector(C_GTY_REFCLKS_USED-1 DOWNTO 0);
    gty_refclk0n_i : in std_logic_vector(C_GTY_REFCLKS_USED-1 DOWNTO 0);
    gty_refclk1p_i : in std_logic_vector(C_GTY_REFCLKS_USED-1 DOWNTO 0);
    gty_refclk1n_i : in std_logic_vector(C_GTY_REFCLKS_USED-1 DOWNTO 0)
);
end component;

BEGIN
  xo_clk     <= i_xo_clk;
  xo_rst     <=     i_xo_rst;
  xo_rst_n   <= NOT i_xo_rst;
  mm_clk     <= i_mm_clk;
  mm_rst     <= i_mm_rst;

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

  -----------------------------------------------------------------------------
  -- mm_clk
  -- . use mm_sim_clk in sim
  -- . derived from CLK via PLL on hardware
  -----------------------------------------------------------------------------

  i_mm_clk <= clk50;
  debug_mmbx <= i_mm_clk;
  
--  gen_mm_clk_sim: IF g_sim = TRUE GENERATE
--      clk50       <= NOT clk50 AFTER 10 ns;      -- 50 MHz, 20ns/2
--      mm_locked   <= '0', '1' AFTER 70 ns;
--  END GENERATE;

--  gen_mm_clk_hardware: IF g_sim = FALSE GENERATE
    u_gmi_board_clk125_pll : ENTITY gmi_board_lib.gmi_board_clk125_pll
    GENERIC MAP (
      g_technology => g_technology
    )
    PORT MAP (
      arst       => i_xo_rst,
      clk125     => i_xo_clk,
      c0_clk50   => clk50,
      pll_locked => mm_locked
    );
--  END GENERATE;

  u_gmi_board_node_ctrl : ENTITY gmi_board_lib.gmi_board_node_ctrl
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
    led2_colour => reg_axi_out,
    led3_colour => led3_colour_arr,
    din         => led_din,
    sclk        => led_sclk,
    cs          => led_cs,
    dout        => led_dout
  );

  -- Copied the color codes from the spi_lib.spi_max6966 testbench
  led1_colour_arr <= X"4578ef" WHEN (led_flash_green0 = '1') ELSE (OTHERS => '0');
  led3_colour_arr <= X"47a6c8" WHEN (led_flash_green1 = '1') ELSE (OTHERS => '0');

  -- connect LED2 to JTAG-AXI:
  u_gmi_led_axi_wrapper : gmi_led_axi_wrapper
  PORT MAP (
    axi_led_out => reg_axi_out,
    clock_rtl   => i_mm_clk,
    reset_rtl   => i_mm_rst
  );

    qsfp_a_reset <= reg_axi_out(0);
    qsfp_b_reset <= reg_axi_out(1);
    qsfp_c_reset <= reg_axi_out(2);
    qsfp_d_reset <= reg_axi_out(3);
    qsfp_clock_sel <= reg_axi_out(4);

 u_example_ibert_ultrascale_gty_0 : example_ibert_ultrascale_gty_0
  port map (
      gty_txn_o   =>gty_txn_o,
      gty_txp_o   =>gty_txp_o,
      gty_rxn_i   =>gty_rxn_i,
      gty_rxp_i   =>gty_rxp_i,

      gty_sysclkp_i => gty_sysclkp_i,
      gty_sysclkn_i =>  gty_sysclkn_i,

      gty_refclk0p_i => gty_refclk0p_i,
      gty_refclk0n_i => gty_refclk0n_i,
      gty_refclk1p_i => gty_refclk1p_i,
      gty_refclk1n_i => gty_refclk1n_i
  );

END str;
