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

LIBRARY IEEE, UNISIM, common_lib, axi4_lib, kcu105_board_lib, technology_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE UNISIM.vcomponents.all;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE kcu105_board_lib.lru_board_pkg.ALL;


ENTITY kcu105_led IS
  GENERIC (
    g_design_name   : STRING  := "kcu105_led";
    g_design_note   : STRING  := "UNUSED";
    g_technology    : t_technology := c_tech_xcvu9p;
    g_sim           : BOOLEAN := FALSE; --Overridden by TB
    g_sim_unb_nr    : NATURAL := 0;
    g_sim_node_nr   : NATURAL := 0;
    g_stamp_date    : NATURAL := 0;  -- Date (YYYYMMDD)
    g_stamp_time    : NATURAL := 0;  -- Time (HHMMSS)
    g_stamp_svn     : NATURAL := 0;  -- SVN revision
    g_factory_image : BOOLEAN := TRUE
  );
  PORT (
    clk_e_p     : IN STD_LOGIC; -- 125MHz PTP clk
    clk_e_n     : IN STD_LOGIC;

    led_din     : OUT STD_LOGIC;
    led_dout    : IN  STD_LOGIC;
    led_cs      : OUT STD_LOGIC;
    led_sclk    : OUT STD_LOGIc
  );
END kcu105_led;


ARCHITECTURE str OF kcu105_led IS

  -- Firmware version x.y
  CONSTANT c_fw_version    : t_lru_board_fw_version := (1, 1);
  CONSTANT c_mm_clk_freq   : NATURAL := c_lru_board_mm_clk_freq_100M;

  CONSTANT c_mm_reg_led    : t_c_mem := (latency  => 1,
                                         adr_w    => 1,
                                         dat_w    => c_word_w,
                                         nof_dat  => 1,
                                         init_sl  => '0');

  -- System
  SIGNAL mm_rst            : STD_LOGIC;
  SIGNAL ph_rst            : STD_LOGIC;
  SIGNAL mm_clk            : STD_LOGIC;

  SIGNAL led2_colour_arr   : STD_LOGIC_VECTOR(c_word_w-1 DOWNTO 0);

  SIGNAL reg_kcu105_system_info_mosi : t_axi4_lite_mosi := c_axi4_lite_mosi_rst;
  SIGNAL reg_kcu105_system_info_miso : t_axi4_lite_miso := c_axi4_lite_miso_rst;
  SIGNAL rom_kcu105_system_info_mosi : t_axi4_lite_mosi := c_axi4_lite_mosi_rst;
  SIGNAL rom_kcu105_system_info_miso : t_axi4_lite_miso := c_axi4_lite_miso_rst;

  SIGNAL reg_led_mosi      : t_axi4_lite_mosi;
  SIGNAL reg_led_miso      : t_axi4_lite_miso;
  
BEGIN

  u_ctrl_kcu105_board : ENTITY kcu105_board_lib.ctrl_lru_board
  GENERIC MAP (
    g_sim           => g_sim,
    g_technology    => g_technology,
    g_mm_clk_freq   => c_mm_clk_freq,
    g_design_name   => g_design_name,
    g_stamp_date    => g_stamp_date,
    g_stamp_time    => g_stamp_time,
    g_stamp_svn     => g_stamp_svn,
    g_fw_version    => c_fw_version,
    g_factory_image => g_factory_image
  )
  PORT MAP (
    mm_rst      => mm_rst,
    ph_rst      => ph_rst,
    mm_clk      => mm_clk,
    
    led2_colour_arr => led2_colour_arr(23 downto 0),

    clk_e_p     => clk_e_p,
    clk_e_n     => clk_e_n,

    led_din     => led_din,
    led_dout    => led_dout,
    led_cs      => led_cs,
    led_sclk    => led_sclk
  );

  
  u_axi4_lite_reg_r_w : ENTITY axi4_lib.axi4_lite_reg_r_w
  GENERIC MAP (
    g_reg       => c_mm_reg_led
  )
  PORT MAP (
    mm_rst      => mm_rst,
    mm_clk      => mm_clk,
    sla_in      => reg_led_mosi,
    sla_out     => reg_led_miso,
    out_reg     => led2_colour_arr,
    in_reg      => (others => '0')
  );


  u_mmm : ENTITY work.mmm_lru_led
  GENERIC MAP (
    g_sim           => g_sim,
    g_sim_unb_nr    => g_sim_unb_nr,
    g_sim_node_nr   => g_sim_node_nr,
    g_technology    => g_technology
  )
  PORT MAP (
    mm_clk          => mm_clk,
    mm_rst          => mm_rst,
    ph_rst          => ph_rst,

    -- system_info
    reg_lru_system_info_mosi => reg_kcu105_system_info_mosi,
    reg_lru_system_info_miso => reg_kcu105_system_info_miso,
    rom_lru_system_info_mosi => rom_kcu105_system_info_mosi,
    rom_lru_system_info_miso => rom_kcu105_system_info_miso,

    -- kcu105 led
    reg_led_mosi    => reg_led_mosi,
    reg_led_miso    => reg_led_miso
  );

END str;
