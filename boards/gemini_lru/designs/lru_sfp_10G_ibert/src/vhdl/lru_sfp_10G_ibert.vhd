-------------------------------------------------------------------------------
--
-- Copyright (C) 2017
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

LIBRARY IEEE, UNISIM, common_lib, axi4_lib, lru_board_lib, technology_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE UNISIM.vcomponents.all; -- IBUFDS, OBUFDS, ...
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE lru_board_lib.lru_board_pkg.ALL;


ENTITY lru_sfp_10G_ibert IS
  GENERIC (
    g_design_name   : STRING  := "lru_sfp_10G_ibert";
    g_design_note   : STRING  := "UNUSED";
    g_technology    : NATURAL := c_tech_xcvu9p;
    g_sim           : BOOLEAN := FALSE; --Overridden by TB
    g_sim_unb_nr    : NATURAL := 0;
    g_sim_node_nr   : NATURAL := 0;
    g_stamp_date    : NATURAL := 0;  -- Date (YYYYMMDD)
    g_stamp_time    : NATURAL := 0;  -- Time (HHMMSS)
    g_stamp_svn     : NATURAL := 0;  -- SVN revision
    g_factory_image : BOOLEAN := TRUE;
    C_NUM_GTY_QUADS : NATURAL := 1;
    C_GTY_REFCLKS_USED : NATURAL := 1 
  );
  PORT (
    clk_e_p     : in std_logic; -- 125MHz PTP clk
    clk_e_n     : in std_logic;

    led_din     : out std_logic;
    led_dout    : in  std_logic;
    led_cs      : out std_logic;
    led_sclk    : out std_logic;

    gty_txn_o      : out std_logic_vector((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);
    gty_txp_o      : out std_logic_vector((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);
    gty_rxn_i      : in  std_logic_vector((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);
    gty_rxp_i      : in  std_logic_vector((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);

    gty_sysclkp_i  : in  std_logic;
    gty_sysclkn_i  : in  std_logic;

    gty_refclk0p_i : in  std_logic_vector(C_GTY_REFCLKS_USED-1 DOWNTO 0);
    gty_refclk0n_i : in  std_logic_vector(C_GTY_REFCLKS_USED-1 DOWNTO 0);
    gty_refclk1p_i : in  std_logic_vector(C_GTY_REFCLKS_USED-1 DOWNTO 0);
    gty_refclk1n_i : in  std_logic_vector(C_GTY_REFCLKS_USED-1 DOWNTO 0);
    
    ptp_clk_sel   : out std_logic;    
    sfp_led       : out std_logic;
    sfp_tx_enable : out std_logic
  );
END lru_sfp_10G_ibert ;

ARCHITECTURE str OF lru_sfp_10G_ibert IS

  -- Firmware version x.y
  CONSTANT c_fw_version         : t_lru_board_fw_version := (1, 1);
  CONSTANT c_mm_clk_freq        : NATURAL := c_lru_board_mm_clk_freq_100M;

  CONSTANT c_mm_reg_led         : t_c_mem := (latency  => 1,
                                              adr_w    => 1,
                                              dat_w    => c_word_w,
                                              nof_dat  => 1,
                                              init_sl  => '0');
  -- System
  SIGNAL mm_rst            : STD_LOGIC;
  SIGNAL ph_rst            : STD_LOGIC;
  SIGNAL mm_clk            : STD_LOGIC;

  SIGNAL led2_colour_arr   : STD_LOGIC_VECTOR(c_word_w-1 DOWNTO 0);

  SIGNAL reg_lru_system_info_mosi : t_axi4_lite_mosi := c_axi4_lite_mosi_rst;
  SIGNAL reg_lru_system_info_miso : t_axi4_lite_miso := c_axi4_lite_miso_rst;
  SIGNAL rom_lru_system_info_mosi : t_axi4_lite_mosi := c_axi4_lite_mosi_rst;
  SIGNAL rom_lru_system_info_miso : t_axi4_lite_miso := c_axi4_lite_miso_rst;

  SIGNAL reg_led_mosi      : t_axi4_lite_mosi;
  SIGNAL reg_led_miso      : t_axi4_lite_miso;


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

  ptp_clk_sel   <= '1'; -- select 156.25 MHz for MGTREFCLK0
  sfp_tx_enable <= '1';
  
  u_ctrl_lru_board : ENTITY lru_board_lib.ctrl_lru_board
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
    led_sclk    => led_sclk,
        
    sfp_led     => sfp_led
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

  u_mmm : ENTITY work.mmm_lru_sfp_10G_ibert
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
    reg_lru_system_info_mosi => reg_lru_system_info_mosi,
    reg_lru_system_info_miso => reg_lru_system_info_miso,
    rom_lru_system_info_mosi => rom_lru_system_info_mosi,
    rom_lru_system_info_miso => rom_lru_system_info_miso,

    -- lru led
    reg_led_mosi    => reg_led_mosi,
    reg_led_miso    => reg_led_miso
  );


  u_example_ibert_ultrascale_gty_0 : example_ibert_ultrascale_gty_0
  port map (
      gty_txn_o      => gty_txn_o,
      gty_txp_o      => gty_txp_o,
      gty_rxn_i      => gty_rxn_i,
      gty_rxp_i      => gty_rxp_i,

      gty_sysclkp_i  => gty_sysclkp_i,
      gty_sysclkn_i  => gty_sysclkn_i,

      gty_refclk0p_i => gty_refclk0p_i,
      gty_refclk0n_i => gty_refclk0n_i,
      gty_refclk1p_i => gty_refclk1p_i,
      gty_refclk1n_i => gty_refclk1n_i
  );

END str;
