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

ENTITY gmi_test_i2c IS
  GENERIC (
    g_design_name   : STRING  := "gmi_test_i2c";
    g_design_note   : STRING  := "UNUSED";
    g_technology    : NATURAL := c_tech_xcvu9p;
    g_sim           : BOOLEAN := FALSE; --Overridden by TB
    g_sim_unb_nr    : NATURAL := 0;
    g_sim_node_nr   : NATURAL := 0;
    g_stamp_date    : NATURAL := 0;  -- Date (YYYYMMDD)
    g_stamp_time    : NATURAL := 0;  -- Time (HHMMSS)
    g_stamp_svn     : NATURAL := 0;  -- SVN revision
    g_factory_image : BOOLEAN := TRUE;
    C_NUM_GTY_QUADS : NATURAL := 29;   --13;
    C_GTY_REFCLKS_USED : NATURAL := 17; --13
    g_sens_nof_result  : NATURAL := 40
  );
  PORT (
    clk_e_p     : in std_logic; -- 125MHz PTP clk
    clk_e_n     : in std_logic;

    -- Power Monitor & Control
--    pmbus_sda   : inout std_logic;
--    pmbus_sdc   : inout std_logic;
--    pmbus_alert : in std_logic;
    
    optics_l_scl : inout std_logic;
    optics_l_sda : inout std_logic;
    optics_l_reset_n : out std_logic;

    led_din     : out std_logic;
    led_dout    : in  std_logic;
    led_cs      : out std_logic;
    led_sclk    : out std_logic
  );
END gmi_test_i2c;

ARCHITECTURE str OF gmi_test_i2c IS

  -- Firmware version x.y
  CONSTANT c_fw_version         : t_gmi_board_fw_version := (1, 1);
  CONSTANT c_reset_len          : NATURAL := 10;  -- >= c_meta_delay_len from common_pkg
  CONSTANT c_mm_clk_freq        : NATURAL := c_gmi_board_mm_clk_freq_50M;

  -- System
  SIGNAL mm_rst                 : STD_LOGIC;
  SIGNAL mm_clk                 : STD_LOGIC;
  SIGNAL pll_locked             : STD_LOGIC;
  SIGNAL n_pll_locked           : STD_LOGIC;
  SIGNAL st_clk                 : STD_LOGIC;
  SIGNAL st_rst                 : STD_LOGIC;
  SIGNAL xo_clk                 : STD_LOGIC;
  SIGNAL xo_rst                 : STD_LOGIC;

  SIGNAL cs_sim                 : STD_LOGIC;

  SIGNAL pulse_10Hz             : STD_LOGIC;
  SIGNAL pulse_10Hz_extended    : STD_LOGIC;
  SIGNAL mm_pulse_ms            : STD_LOGIC;
  SIGNAL mm_pulse_s             : STD_LOGIC;
  SIGNAL mm_board_sens_start    : STD_LOGIC;

  SIGNAL led_toggle             : STD_LOGIC;
  SIGNAL led_flash              : STD_LOGIC;
  SIGNAL led_flash_green0       : STD_LOGIC;
  SIGNAL led_flash_green1       : STD_LOGIC;
  
  -- color leds:
  SIGNAL led1_colour_arr        : STD_LOGIC_VECTOR(23 DOWNTO 0);
  SIGNAL led2_colour_arr        : STD_LOGIC_VECTOR(23 DOWNTO 0);
  SIGNAL led3_colour_arr        : STD_LOGIC_VECTOR(23 DOWNTO 0);

  SIGNAL reg_axi_mosi           : t_mem_mosi;
  SIGNAL reg_axi_miso           : t_mem_miso;

  SIGNAL reg_mosi_arr : t_mem_mosi_arr(1 DOWNTO 0);
  SIGNAL reg_miso_arr : t_mem_miso_arr(1 DOWNTO 0);
  SIGNAL test_reg : STD_LOGIC_VECTOR(31 downto 0);
  
component gmi_test_iic_axi_wrapper is
  port (
    avm_address : out STD_LOGIC_VECTOR ( 31 downto 0 );
    avm_read : out STD_LOGIC;
    avm_readdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    avm_write : out STD_LOGIC;
    avm_writedata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    clock_rtl : in STD_LOGIC;
    led_axi_out : out STD_LOGIC_VECTOR ( 23 downto 0 );
    pll_locked : in STD_LOGIC;
    reset_rtl : in STD_LOGIC
  );
end component gmi_test_iic_axi_wrapper;

component ila_0 IS
PORT (
clk : IN STD_LOGIC;
    probe0 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    probe1 : IN STD_LOGIC_VECTOR(23 DOWNTO 0)
);
END component ila_0;


BEGIN

  n_pll_locked <= NOT pll_locked;
  optics_l_reset_n <= NOT mm_rst;
  
  u_ila_0 : ila_0
  port map (
  clk => mm_clk,
  probe0(0) =>pll_locked,
  probe0(1) =>mm_pulse_ms,
  probe0(2) =>mm_board_sens_start,
  probe1 =>led2_colour_arr
  );

  u_gmi_test_iic_axi_wrapper : gmi_test_iic_axi_wrapper 
  port map (
   clock_rtl        => mm_clk,
   pll_locked       => pll_locked,
   led_axi_out      => led2_colour_arr,
   reset_rtl        => mm_rst,

   -- t_mem_miso:
   avm_readdata     => reg_axi_miso.rddata(c_word_w-1 downto 0),

   -- t_mem_mosi:
   avm_address      => reg_axi_mosi.address,
   avm_writedata    => reg_axi_mosi.wrdata(c_word_w-1 downto 0),
   avm_write        => reg_axi_mosi.wr,
   avm_read         => reg_axi_mosi.rd
  );

   
   
  u_IBUFDS_clk_e_inst : IBUFDS -- page 201 of ug974-vivado-ultrascale-libraries.pdf
                               -- http://www.xilinx.com/support/documentation/sw_manuals/xilinx2016_1/ug974-vivado-ultrascale-libraries.pdf
   PORT MAP (
    O => xo_clk,
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
    clk       => xo_clk,
    out_rst   => xo_rst
  );


  u_common_areset_st : ENTITY common_lib.common_areset
  GENERIC MAP (
    g_rst_level => '1', -- power up default will be inferred in FPGA
    g_delay_len => c_reset_len
  )
  PORT MAP (
    in_rst    => n_pll_locked,
    clk       => st_clk,
    out_rst   => st_rst
  );



  
  -----------------------------------------------------------------------------
  -- mm_clk
  -- . use mm_sim_clk in sim
  -- . derived from CLK via PLL on hardware
  -----------------------------------------------------------------------------


--  gen_mm_clk_hardware: IF g_sim = FALSE GENERATE
    u_gmi_board_clk125_pll : ENTITY gmi_board_lib.gmi_board_clk125_pll
    GENERIC MAP (
      g_technology => g_technology
    )
    PORT MAP (
      arst       => xo_rst,
      clk125     => xo_clk,
      c0_clk50   => mm_clk,
      pll_locked => pll_locked
    );
--  END GENERATE;


  u_gmi_board_node_ctrl : ENTITY gmi_board_lib.gmi_board_node_ctrl
  GENERIC MAP (
    g_pulse_us => c_mm_clk_freq / (10**6)     -- nof system clock cycles to get us period, equal to system clock frequency / 10**6
  )
  PORT MAP (
    -- MM clock domain reset
    mm_clk      => mm_clk,
    mm_locked   => pll_locked,
    mm_rst      => mm_rst,
    -- WDI extend
    mm_wdi_in   => mm_pulse_s,
    -- Pulses
    mm_pulse_us => OPEN,
    mm_pulse_ms => mm_pulse_ms,
    mm_pulse_s  => mm_pulse_s  -- could be used to toggle a LED
  );

  mm_board_sens_start <= mm_pulse_s WHEN g_sim=FALSE ELSE mm_pulse_ms;  -- speed up in simulation

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
    rst     => mm_rst,
    clk     => mm_clk,
    p_in    => mm_board_sens_start,
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
    in_dat      => mm_board_sens_start,
    out_dat     => led_toggle
  );


  u_spi_max6966 : ENTITY spi_lib.spi_max6966
  GENERIC MAP (
    con_simulation => g_sim
  )
  PORT MAP (
    clock       => mm_clk,
    reset       => mm_rst,
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
  --led2_colour_arr <= X"47a6c8";
  led3_colour_arr <= X"47a6c8" WHEN (led_flash_green1 = '1') ELSE (OTHERS => '0');
  
  u_mms_common_reg : ENTITY common_lib.mms_common_reg
  PORT MAP (
     mm_clk       => mm_clk,
     mm_rst       => mm_rst,
     st_clk       => mm_clk,
     st_rst       => mm_rst,

     reg_mosi     => reg_mosi_arr(0),
     reg_miso     => reg_miso_arr(0),
     
     in_reg       => test_reg,
     out_reg      => test_reg
  );
  
  
  u_mms_gmi_board_sens_optics_l : ENTITY gmi_board_lib.mms_gmi_board_sens
  GENERIC MAP (
    g_sim             => g_sim,
    g_i2c_peripheral  => c_i2c_peripheral_optics_l,
    g_sens_nof_result => g_sens_nof_result,
    g_clk_freq        => c_mm_clk_freq
  )
  PORT MAP (
    mm_clk       => mm_clk,
    mm_rst       => mm_rst,
    mm_start     => mm_board_sens_start,

    reg_mosi     => reg_mosi_arr(1),
    reg_miso     => reg_miso_arr(1),
    -- i2c bus
    scl          => optics_l_scl,
    sda          => optics_l_sda
  );
  
    -- Combine the internal array of mm interfaces for the weight factors to one array that is connected to the port of bf
  u_reg_mux : ENTITY common_lib.common_mem_mux
  GENERIC MAP ( 
    g_nof_mosi    => 2,
    g_mult_addr_w => 6
  )
  PORT MAP (
    mosi     => reg_axi_mosi,
    miso     => reg_axi_miso,
    mosi_arr => reg_mosi_arr,
    miso_arr => reg_miso_arr
  );

END str;
