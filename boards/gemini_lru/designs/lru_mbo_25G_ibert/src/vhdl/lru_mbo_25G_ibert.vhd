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

LIBRARY IEEE, UNISIM, common_lib, axi4_lib, gemini_lru_board_lib, technology_lib, spi_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE UNISIM.vcomponents.all; -- IBUFDS, OBUFDS, ...
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE gemini_lru_board_lib.ip_pkg.ALL;
USE gemini_lru_board_lib.board_pkg.ALL;


ENTITY lru_mbo_25G_ibert IS
   GENERIC (
    g_design_name   : STRING  := "lru_mbo_25G_ibert";
    g_design_note   : STRING  := "UNUSED";
    g_technology    : t_technology := c_tech_xcvu9p;
    g_sim           : BOOLEAN := FALSE; --Overridden by TB
    g_sim_unb_nr    : NATURAL := 0;
    g_sim_node_nr   : NATURAL := 0;
    g_stamp_date    : NATURAL := 0;  -- Date (YYYYMMDD)
    g_stamp_time    : NATURAL := 0;  -- Time (HHMMSS)
    g_stamp_svn     : NATURAL := 0;  -- SVN revision
    g_factory_image : BOOLEAN := TRUE;
    C_NUM_GTY_QUADS : NATURAL := 9;
    C_GTY_REFCLKS_USED : NATURAL := 9
   );
   PORT (
      clk_e_p              : IN STD_LOGIC;         -- 125MHz PTP clk
      clk_e_n              : IN STD_LOGIC;

      clk_h                : IN STD_LOGIC;         -- 20MHz LO clk

      led_din              : OUT STD_LOGIC;
      led_dout             : IN STD_LOGIC;
      led_cs               : OUT STD_LOGIC;
      led_sclk             : OUT STD_LOGIC;

      gty_txn_o            : OUT STD_LOGIC_VECTOR((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);
      gty_txp_o            : OUT STD_LOGIC_VECTOR((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);
      gty_rxn_i            : IN STD_LOGIC_VECTOR((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);
      gty_rxp_i            : IN STD_LOGIC_VECTOR((4*C_NUM_GTY_QUADS)-1 DOWNTO 0);

      gty_sysclkp_i        : IN STD_LOGIC;
      gty_sysclkn_i        : IN STD_LOGIC;

      gty_refclk0p_i       : IN STD_LOGIC_VECTOR(C_GTY_REFCLKS_USED-1 DOWNTO 0);
      gty_refclk0n_i       : IN STD_LOGIC_VECTOR(C_GTY_REFCLKS_USED-1 DOWNTO 0);
      gty_refclk1p_i       : IN STD_LOGIC_VECTOR(C_GTY_REFCLKS_USED-1 DOWNTO 0);
      gty_refclk1n_i       : IN STD_LOGIC_VECTOR(C_GTY_REFCLKS_USED-1 DOWNTO 0);


      mbo_a_reset          : OUT STD_LOGIC;                          -- LVCMOS 1.8V
      mbo_b_reset          : OUT STD_LOGIC;                          -- LVCMOS 1.8V
      mbo_c_reset          : OUT STD_LOGIC;                          -- LVCMOS 1.8V

      mbo_int_n            : IN STD_LOGIC;
      mbo_sda              : INOUT STD_LOGIC;                        -- OC drive, internal Pullups
      mbo_scl              : INOUT STD_LOGIC);                        -- LVCMOS 1.8V
END lru_mbo_25G_ibert;

ARCHITECTURE str OF lru_mbo_25G_ibert IS

   ---------------------------------------------------------------------------
   -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
   ---------------------------------------------------------------------------

   CONSTANT c_mm_reg_led         : t_c_mem := (latency  => 1,
                                               adr_w    => 1,
                                               dat_w    => c_word_w,
                                               nof_slaves   => 1,
                                               nof_dat  => 1,
                                               addr_base    => 0,
                                               init_sl  => '0');


   ---------------------------------------------------------------------------
   -- SIGNAL DECLARATIONS  --
   ---------------------------------------------------------------------------

   SIGNAL system_reset           : STD_LOGIC;
   SIGNAL clk_125                : STD_LOGIC;
   SIGNAL clk_100                : STD_LOGIC;
   SIGNAL clk_50                 : STD_LOGIC;

   SIGNAL system_locked          : STD_LOGIC;
   SIGNAL system_reset_shift     : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL gnd                    : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL vcc                    : STD_LOGIC_VECTOR(31 DOWNTO 0);

   SIGNAL led1_colour            : STD_LOGIC_VECTOR(23 DOWNTO 0);
   SIGNAL led2_colour            : STD_LOGIC_VECTOR(c_word_w-1 DOWNTO 0);
   SIGNAL led3_colour            : STD_LOGIC_VECTOR(23 DOWNTO 0);

   SIGNAL reg_lru_system_info_mosi : t_axi4_lite_mosi := c_axi4_lite_mosi_rst;
   SIGNAL reg_lru_system_info_miso : t_axi4_lite_miso := c_axi4_lite_miso_rst;
   SIGNAL rom_lru_system_info_mosi : t_axi4_lite_mosi := c_axi4_lite_mosi_rst;
   SIGNAL rom_lru_system_info_miso : t_axi4_lite_miso := c_axi4_lite_miso_rst;

   SIGNAL reg_led_mosi           : t_axi4_lite_mosi;
   SIGNAL reg_led_miso           : t_axi4_lite_miso;


   SIGNAL rd_dat                 : STD_LOGIC_VECTOR(c_mm_reg_led.dat_w-1 DOWNTO 0);
   SIGNAL wr_dat                 : STD_LOGIC_VECTOR(c_mm_reg_led.dat_w-1 DOWNTO 0);
   SIGNAL wr_val                 : STD_LOGIC;
   SIGNAL rd_val                 : STD_LOGIC;
   SIGNAL rd_busy                : STD_LOGIC;
   SIGNAL wr_busy                : STD_LOGIC;
   SIGNAL reg_wren               : STD_LOGIC;
   SIGNAL reg_rden               : STD_LOGIC;
   SIGNAL wr_adr                 : STD_LOGIC_VECTOR(c_mm_reg_led.adr_w-1 DOWNTO 0);
   SIGNAL rd_adr                 : STD_LOGIC_VECTOR(c_mm_reg_led.adr_w-1 DOWNTO 0);

   ---------------------------------------------------------------------------
   -- COMPONENT DECLARATIONS  --
   ---------------------------------------------------------------------------

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
      gty_refclk1n_i : in std_logic_vector(C_GTY_REFCLKS_USED-1 DOWNTO 0));
   end component;

BEGIN

   gnd <= (OTHERS => '0');
   vcc <= (OTHERS => '1');

  ---------------------------------------------------------------------------
  -- CLOCKING & RESETS  --
  ---------------------------------------------------------------------------

   system_pll: system_clock
   PORT MAP (
      clk_in1  => clk_h,
      clk_125  => clk_125,
      clk_100  => clk_100,
      clk_50   => clk_50,
      resetn   => vcc(0),
      locked   => system_locked);

   system_pll_reset: PROCESS(clk_125)
   BEGIN
      IF RISING_EDGE(clk_125) THEN
         system_reset_shift <= system_reset_shift(6 DOWNTO 0) & NOT(system_locked);
      END IF;
   END PROCESS;

   system_reset <= system_reset_shift(7);

  ---------------------------------------------------------------------------
  -- CLOCKING & RESETS  --
  ---------------------------------------------------------------------------

   u_led_driver : ENTITY spi_lib.spi_max6966
   GENERIC MAP (
      g_simulation  => g_sim,
      g_input_clk   => 125)
   PORT MAP (
      clk           => clk_125,
      rst           => system_reset,
      enable        => '1',
      led1_colour   => led1_colour,
      led2_colour   => led2_colour(23 downto 0),
      led3_colour   => led3_colour,
      din           => led_din,
      sclk          => led_sclk,
      cs            => led_cs,
      dout          => led_dout);

   u_mem_to_axi4_lite : ENTITY axi4_lib.mem_to_axi4_lite
   GENERIC MAP (
      g_adr_w => c_mm_reg_led.adr_w,
      g_dat_w => c_mm_reg_led.dat_w)
   PORT MAP (
      rst        => system_reset,
      clk        => clk_125,
      sla_in     => reg_led_mosi,
      sla_out    => reg_led_miso,
      wren       => reg_wren,
      rden       => reg_rden,
      wr_adr     => wr_adr,
      wr_dat     => wr_dat,
      wr_val     => wr_val,
      wr_busy    => wr_busy,
      rd_adr     => rd_adr,
      rd_dat     => rd_dat,
      rd_busy    => rd_busy,
      rd_val     => rd_val);

   led_reg : ENTITY common_lib.common_reg_r_w
   GENERIC MAP (
      g_reg        => c_mm_reg_led)
   PORT MAP (
      mm_rst          => system_reset,
      mm_clk          => clk_125,
      wr_en           => reg_wren,
      wr_adr          => wr_adr,
      wr_dat          => wr_dat,
      wr_val          => wr_val,
      wr_busy         => wr_busy,
      rd_en           => reg_rden,
      rd_adr          => rd_adr,
      rd_dat          => rd_dat,
      rd_val          => rd_val,
      rd_busy         => rd_busy,
      reg_wr_arr      => open,
      reg_rd_arr      => open,
      out_reg         => led2_colour,
      in_reg          => x"AAAA5555");

  u_mmm : ENTITY work.mmm_lru_mbo_25G_ibert
  GENERIC MAP (
    g_sim           => g_sim,
    g_sim_unb_nr    => g_sim_unb_nr,
    g_sim_node_nr   => g_sim_node_nr,
    g_technology    => g_technology
  )
  PORT MAP (
    mm_clk          => clk_125,
    mm_rst          => system_reset,
    ph_rst          => system_reset,

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



   mbo_support: ENTITY gemini_lru_board_lib.mbo_control
   GENERIC MAP (
      g_technology      => g_technology,
      g_clk_rate        => 125000000)
   PORT MAP (
      clk               => clk_125,
      rst               => system_reset,
      s_axi_mosi        => reg_lru_system_info_mosi,
      s_axi_miso        => reg_lru_system_info_miso,
      mbo_a_tx_disable  => OPEN,
      mbo_a_rx_disable  => OPEN,
      mbo_a_loopback    => OPEN,
      mbo_a_rx_locked   => X"FFF",
      mbo_b_tx_disable  => OPEN,
      mbo_b_rx_disable  => OPEN,
      mbo_b_loopback    => OPEN,
      mbo_b_rx_locked   => X"FFF",
      mbo_c_tx_disable  => OPEN,
      mbo_c_rx_disable  => OPEN,
      mbo_c_loopback    => OPEN,
      mbo_c_rx_locked   => X"FFF",
      mbo_a_reset       => mbo_a_reset,
      mbo_b_reset       => mbo_b_reset,
      mbo_c_reset       => mbo_c_reset,
      mbo_int_n         => mbo_int_n,
      mbo_sda           => mbo_sda,
      mbo_scl           => mbo_scl);


END str;
