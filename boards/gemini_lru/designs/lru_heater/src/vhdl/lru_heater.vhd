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

LIBRARY IEEE, UNISIM, common_lib, lru_board_lib, technology_lib, spi_lib, util_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE lru_board_lib.lru_board_pkg.ALL;
USE UNISIM.vcomponents.all; -- IBUFDS, OBUFDS, ...
USE util_lib.util_heater_pkg.ALL;

ENTITY lru_heater IS
  GENERIC (
    g_design_name   : STRING  := "lru_heater";
    g_design_note   : STRING  := "UNUSED";    
    g_technology    : t_technology := c_tech_gemini;    
    g_sim           : BOOLEAN := FALSE; --Overridden by TB
    g_sim_unb_nr    : NATURAL := 0;
    g_sim_node_nr   : NATURAL := 0;
    g_stamp_date    : NATURAL := 0;  -- Date (YYYYMMDD)
    g_stamp_time    : NATURAL := 0;  -- Time (HHMMSS)
    g_stamp_svn     : NATURAL := 0;  -- SVN revision
    g_factory_image : BOOLEAN := TRUE;
    C_NUM_GTY_QUADS : NATURAL := 10;--13;
    C_GTY_REFCLKS_USED : NATURAL := 10--13
  );
  PORT (
    clk_e_p     : in std_logic; -- 125MHz PTP clk
    clk_e_n     : in std_logic;

    led_din     : out std_logic;
    led_dout    : in  std_logic;
    led_cs      : out std_logic;
    led_sclk    : out std_logic;
    
    gty_txn_o   : out std_logic_vector((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);
    gty_txp_o   : out std_logic_vector((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);
    gty_rxn_i   : in std_logic_vector((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);
    gty_rxp_i   : in std_logic_vector((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);
    
    gty_refclk0p_i : in std_logic_vector(C_GTY_REFCLKS_USED-1 DOWNTO 0);
    gty_refclk0n_i : in std_logic_vector(C_GTY_REFCLKS_USED-1 DOWNTO 0);
    gty_refclk1p_i : in std_logic_vector(C_GTY_REFCLKS_USED-1 DOWNTO 0);
    gty_refclk1n_i : in std_logic_vector(C_GTY_REFCLKS_USED-1 DOWNTO 0);
    shutdown       : OUT STD_LOGIC
  );
END lru_heater;

ARCHITECTURE str OF lru_heater IS

  -- Firmware version x.y
  --CONSTANT c_fw_version         : t_lru_board_fw_version := (1, 1);
  CONSTANT c_reset_len          : NATURAL := 4;  -- >= c_meta_delay_len from common_pkg
  --CONSTANT c_mm_clk_freq        : NATURAL := c_lru_board_mm_clk_freq_125M;

  --CONSTANT c_nof_mac4           : NATURAL := 1200; 
  --CONSTANT c_nof_mac4           : NATURAL := 1250; 
  CONSTANT c_nof_mac4           : NATURAL := 392;--384;--400;--300;--200;--100;--384;--600; --400;--500 too much (1362401/1182240) -- Mod. by Gys 1-8-2017 step 2 from 500 to 750 800;--1000; 
  CONSTANT c_axi_size           : NATURAL := 1408;

  -- System
  SIGNAL mm_rst                 : STD_LOGIC;
  SIGNAL mm_clk                 : STD_LOGIC;
  SIGNAL pll_locked             : STD_LOGIC;
  SIGNAL pll_locked_n           : STD_LOGIC;
  SIGNAL st_clk                 : STD_LOGIC;
  SIGNAL st_rst                 : STD_LOGIC;

  SIGNAL cs_sim                 : STD_LOGIC;

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
  SIGNAL led2_colour_arr        : STD_LOGIC_VECTOR(23 DOWNTO 0);
  SIGNAL led3_colour_arr        : STD_LOGIC_VECTOR(23 DOWNTO 0);

  -- heater enable
  SIGNAL heater_enable_axi      : STD_LOGIC_VECTOR(c_axi_size-1 DOWNTO 0);
  SIGNAL heater_xor_axi         : STD_LOGIC_VECTOR(c_axi_size-1 DOWNTO 0);
  


  -- copy/pasted this component from Vivado:
  COMPONENT lru_heater_axi_wrapper IS
    PORT (
           clock_rtl : in STD_LOGIC;
          heater_enable_axi_out : out STD_LOGIC_VECTOR ( c_axi_size-1 downto 0 );
          heater_xor_axi_in : in STD_LOGIC_VECTOR ( c_axi_size-1 downto 0 );
          led_axi_out : out STD_LOGIC_VECTOR ( 23 downto 0 );
          reset_rtl_0 : in STD_LOGIC
    );
  END COMPONENT;

component example_ibert_ultrascale_gty_0 is
port (
    gty_txn_o   : out std_logic_vector((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);
    gty_txp_o   : out std_logic_vector((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);
    gty_rxn_i   : in std_logic_vector((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);
    gty_rxp_i   : in std_logic_vector((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);

    gty_refclk0p_i : in std_logic_vector(C_GTY_REFCLKS_USED-1 DOWNTO 0);
    gty_refclk0n_i : in std_logic_vector(C_GTY_REFCLKS_USED-1 DOWNTO 0);
    gty_refclk1p_i : in std_logic_vector(C_GTY_REFCLKS_USED-1 DOWNTO 0);
    gty_refclk1n_i : in std_logic_vector(C_GTY_REFCLKS_USED-1 DOWNTO 0)
);
end component;

  COMPONENT ip_xcvu9p_mmcm_clk125d IS
  PORT
  (
    clk_in1_p         : in     std_logic;
    clk_in1_n         : in     std_logic;
    -- Clock out ports
    clk_out1          : out    std_logic;
    clk_out2          : out    std_logic;
    -- Status and control signals
    reset             : in     std_logic;
    locked            : out    std_logic
  );
  END COMPONENT;


BEGIN
  shutdown <= '0';
  
  pll_locked_n <= NOT pll_locked;

  u_common_areset_st : ENTITY common_lib.common_areset
  GENERIC MAP (
    g_rst_level => '1', -- power up default will be inferred in FPGA
    g_delay_len => c_reset_len
  )
  PORT MAP (
    in_rst    => pll_locked_n,
    clk       => st_clk,
    out_rst   => st_rst
  );

  -----------------------------------------------------------------------------
  -- mm_clk
  -- . use mm_sim_clk in sim
  -- . derived from CLK via PLL on hardware
  -----------------------------------------------------------------------------


  gen_mm_clk_hardware: IF g_sim = FALSE GENERATE
    u_lru_board_clk125d_pll : ip_xcvu9p_mmcm_clk125d    
    PORT MAP (
      reset      => '0',      
      clk_in1_p  => clk_e_p,
      clk_in1_n  => clk_e_n,
      clk_out1   => mm_clk,
      clk_out2   => st_clk,
      locked     => pll_locked
    );
  END GENERATE;


--  u_lru_board_node_ctrl : ENTITY lru_board_lib.lru_board_node_ctrl
--  GENERIC MAP (
--    g_pulse_us => c_mm_clk_freq / (10**6)     -- nof system clock cycles to get us period, equal to system clock frequency / 10**6
--  )
--  PORT MAP (
--    -- MM clock domain reset
--    mm_clk      => mm_clk,
--    mm_locked   => pll_locked,
--    mm_rst      => mm_rst,
--    -- WDI extend
--    mm_wdi_in   => mm_pulse_s,
--    -- Pulses
--    mm_pulse_us => OPEN,
--    mm_pulse_ms => mm_pulse_ms,
--    mm_pulse_s  => mm_pulse_s  -- could be used to toggle a LED
--  );

  ------------------------------------------------------------------------------
  -- Toggle red LED when lru_minimal is running, green LED for other designs.
  ------------------------------------------------------------------------------
  led_flash_green0 <= sel_a_b(g_factory_image=TRUE,  led_flash, '0');
  led_flash_green1 <= sel_a_b(g_factory_image=FALSE, led_flash, '0');


  u_extend : ENTITY common_lib.common_pulse_extend
  GENERIC MAP (
    g_extend_w => 22 -- (2^22) / 50e6 = 0.083886 th of 1 sec
  )
  PORT MAP (
    rst     => mm_rst,
    clk     => mm_clk,
    p_in    => mm_pulse_s,
    ep_out  => led_flash
  );


  u_common_pulser_10Hz : ENTITY common_lib.common_pulser
  GENERIC MAP (
    g_pulse_period => 100,
    g_pulse_phase  => 100-1
  )
  PORT MAP (
    rst            => mm_rst,
    clk            => mm_clk,
    clken          => '1',
    pulse_en       => mm_pulse_ms,
    pulse_out      => pulse_10Hz
  );

  u_extend_10Hz : ENTITY common_lib.common_pulse_extend
  GENERIC MAP (
    g_extend_w => 21 -- (2^21) / 50e6 = 0.041943 th of 1 sec
  )
  PORT MAP (
    rst     => mm_rst,
    clk     => mm_clk,
    p_in    => pulse_10Hz,
    ep_out  => pulse_10Hz_extended
  );

  u_toggle : ENTITY common_lib.common_toggle
  PORT MAP (
    rst         => mm_rst,
    clk         => mm_clk,
    in_dat      => mm_pulse_s,
    out_dat     => led_toggle
  );


--  u_spi_max6966 : ENTITY spi_lib.spi_max6966
--  GENERIC MAP (
--    con_simulation => g_sim
--  )
--  PORT MAP (
--    clock       => mm_clk,
--    reset       => mm_rst,
--    enable      => '1',
--    led1_colour => led1_colour_arr,
--    led2_colour => led2_colour_arr,
--    led3_colour => led3_colour_arr,
--    din         => led_din,
--    sclk        => led_sclk,
--    cs          => led_cs,
--    dout        => led_dout
--  );

  -- Copied the color codes from the spi_lib.spi_max6966 testbench
  led1_colour_arr <= X"4578ef" WHEN (led_flash_green0 = '1') ELSE (OTHERS => '0');
--  led2_colour_arr <= X"47a6c8";
  led3_colour_arr <= X"47a6c8" WHEN (led_flash_green1 = '1') ELSE (OTHERS => '0');

  heater_enable_axi <= (OTHERS=>'1');
 
  -- connect to JTAG-AXI:
  u_lru_heater_axi_wrapper : lru_heater_axi_wrapper
  PORT MAP (
    --heater_enable_axi_out => heater_enable_axi,
    heater_xor_axi_in     => heater_xor_axi,
    led_axi_out           => led2_colour_arr,
    clock_rtl             => mm_clk,
    reset_rtl_0           => mm_rst
  );

  u_heater : ENTITY util_lib.util_heater
  GENERIC MAP (
    g_technology  => g_technology,
    g_pipeline    => 10,--12,--12,--64,--10,
    g_nof_ram     => 10,--10,--8,--216,--108,--72,--36,--4,--10,
    g_nof_logic   => 40,--24,--40,
    g_nof_mac4    => c_nof_mac4
  )
  PORT MAP (
    mm_rst  => mm_rst,
    mm_clk  => mm_clk,

    st_rst  => st_rst,
    st_clk  => st_clk,

    --sla_in  => (others => '1'),-- all enabled at startup
    sla_in  => heater_enable_axi(c_nof_mac4-1 downto 0), -- enable bitbise using AXI MM
    sla_out => heater_xor_axi(c_nof_mac4-1 downto 0)
  );
  
  u_mod_ibert_ultrascale_gty_0 : example_ibert_ultrascale_gty_0 
  port map (
      gty_txn_o   =>gty_txn_o,
      gty_txp_o   =>gty_txp_o,
      gty_rxn_i   =>gty_rxn_i,
      gty_rxp_i   =>gty_rxp_i,

      gty_refclk0p_i => gty_refclk0p_i,
      gty_refclk0n_i => gty_refclk0n_i,
      gty_refclk1p_i => gty_refclk1p_i,
      gty_refclk1n_i => gty_refclk1n_i
  );
    
END str;
