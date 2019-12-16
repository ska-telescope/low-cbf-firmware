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

LIBRARY IEEE, UNISIM, common_lib, gmi_board_lib, technology_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE gmi_board_lib.gmi_board_pkg.ALL;
USE UNISIM.vcomponents.all; -- IBUFDS, OBUFDS, ...

ENTITY gmi_heater_alt IS
  GENERIC (
    g_design_name   : STRING  := "gmi_heater_alt";
    g_design_note   : STRING  := "UNUSED";
    g_technology    : NATURAL := c_tech_xcvu9p;
    g_sim           : BOOLEAN := FALSE; --Overridden by TB
    g_sim_unb_nr    : NATURAL := 0;
    g_sim_node_nr   : NATURAL := 0;
    g_stamp_date    : NATURAL := 0;  -- Date (YYYYMMDD)
    g_stamp_time    : NATURAL := 0;  -- Time (HHMMSS)
    g_stamp_svn     : NATURAL := 0;  -- SVN revision
    g_factory_image : BOOLEAN := TRUE;
    C_NUM_GTY_QUADS : NATURAL := 29;
    C_GTY_REFCLKS_USED : NATURAL := 17
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
END gmi_heater_alt;

ARCHITECTURE str OF gmi_heater_alt IS

  CONSTANT c_reset_len          : NATURAL := 4;  -- >= c_meta_delay_len from common_pkg

  -- System
  SIGNAL pll_locked             : STD_LOGIC;
  SIGNAL mm_clk                 : STD_LOGIC;
  SIGNAL mm_rst                 : STD_LOGIC;
  SIGNAL st_clk                 : STD_LOGIC;
  SIGNAL st_rst                 : STD_LOGIC;

  SIGNAL cs_sim                 : STD_LOGIC;
  
  -- heater enable
  SIGNAL heater_enable_axi      : STD_LOGIC_VECTOR(511 DOWNTO 0);
  SIGNAL heater_output_axi      : STD_LOGIC_VECTOR(511 DOWNTO 0);

  -- color leds:
  SIGNAL led1_colour_arr        : STD_LOGIC_VECTOR(23 DOWNTO 0);
  SIGNAL led2_colour_arr        : STD_LOGIC_VECTOR(23 DOWNTO 0);
  SIGNAL led3_colour_arr        : STD_LOGIC_VECTOR(23 DOWNTO 0);


  -- copy/pasted this component from Vivado:
  COMPONENT gmi_heater_axi_wrapper IS
    PORT (
        clock_rtl         : in STD_LOGIC;
        heater_reg_input  : in STD_LOGIC_VECTOR ( 511 downto 0 );
        heater_reg_output : out STD_LOGIC_VECTOR ( 511 downto 0 );
        reset_rtl         : in STD_LOGIC
    );
  END COMPONENT;

  COMPONENT heater IS
    PORT (
        clk         : in STD_LOGIC;
        enable      : in STD_LOGIC;
        err_clear   : in STD_LOGIC;
        err         : out STD_LOGIC
    );
  END COMPONENT;

COMPONENT spi_max6966 is
   generic (
      con_simulation       : boolean := false;
      con_configuration    : std_logic_vector(7 downto 0) := "00100001";      -- Run mode with staggered PWM outputs
      con_global_current   : std_logic_vector(7 downto 0) := "00000000";      -- 2.5mA full and 1.25mA half current for leds
      con_current_select   : std_logic_vector(9 downto 0) := "0001001001";    -- Half/Full current flags
      con_ramp_up          : std_logic_vector(7 downto 0) := "00000101";      -- 1s ramp up
      con_ramp_down        : std_logic_vector(7 downto 0) := "00000101";      -- 1s ramp down
      con_input_clk        : integer := 125;                                  -- Input clock frequency in MHz
      con_tch              : integer := 40;                                   -- sclk high time, in ns
      con_tcl              : integer := 40;                                   -- sclk low time, in ns
      con_tcss             : integer := 20;                                   -- CS fall to SCLK rise time, in ns (must be biffer than tds)
      con_tcsh             : integer := 0;                                    -- Sclk rise to cs rise hold time, in ns
      con_tds              : integer := 16;                                   -- DIN setup time, in ns  (must be bigger than actual tds)
      con_tdh              : integer := 0;                                    -- DIN data hold time, in ns
      con_tdo              : integer := 21;                                   -- Data ouput propegation delay, in ns
      con_tcsw             : integer := 39);                                  -- Minimum CS pulse high time
   port (
      -- Clocks
      clock                : in std_logic;
      reset                : in std_logic;

      enable               : in std_logic;

      -- Registers
      led1_colour          : in std_logic_vector(23 downto 0);        -- In format R, G, B. Each is 8 bits for intensity
      led2_colour          : in std_logic_vector(23 downto 0);
      led3_colour          : in std_logic_vector(23 downto 0);

      full_cycle           : out std_logic;                          -- Pulsed when a complete cycle is done (for synchronisation of outputs)
      
      -- SPI Interface
      din                  : out std_logic;
      sclk                 : out std_logic;
      cs                   : out std_logic;
      dout                 : in std_logic);
end component;

component mod_ibert_ultrascale_gty_0 is
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
  -----------------------------------------------------------------------------

u_mod_ibert_ultrascale_gty_0 : mod_ibert_ultrascale_gty_0 
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

  qsfp_a_reset <= '0';
  qsfp_b_reset <= '0';
  qsfp_c_reset <= '0';
  qsfp_d_reset <= '0';
  qsfp_clock_sel <= '0';

  

  u_common_areset_mm : ENTITY common_lib.common_areset
  GENERIC MAP (
    g_rst_level => '1', -- power up default will be inferred in FPGA
    g_delay_len => c_reset_len
  )
  PORT MAP (
    in_rst    => NOT pll_locked,
    clk       => mm_clk,
    out_rst   => mm_rst
  );

  u_common_areset_st : ENTITY common_lib.common_areset
  GENERIC MAP (
    g_rst_level => '1', -- power up default will be inferred in FPGA
    g_delay_len => c_reset_len
  )
  PORT MAP (
    in_rst    => NOT pll_locked,
    clk       => st_clk,
    out_rst   => st_rst
  );

  u_gmi_board_clk125d_pll : ENTITY gmi_board_lib.gmi_board_clk125d_pll
  GENERIC MAP (
    g_technology => g_technology
  )
  PORT MAP (
      arst       => '0',
      clk125_n   => clk_e_n,
      clk125_p   => clk_e_p,
      c0_clk50   => mm_clk,
      c1_clk375  => st_clk,
      pll_locked => pll_locked
  );



  -- connect to JTAG-AXI:
  u_gmi_heater_axi_wrapper : gmi_heater_axi_wrapper
  PORT MAP (
    clock_rtl             => mm_clk,
    reset_rtl             => mm_rst,
    heater_reg_output     => heater_output_axi,
    heater_reg_input      => heater_enable_axi
  );

  --gen_heaters : FOR i IN 470 DOWNTO 0 GENERATE
  gen_heaters : FOR i IN 350 DOWNTO 0 GENERATE
    u_heater : heater
    PORT MAP (
      clk       => st_clk,
      enable    => heater_enable_axi(i),
      err_clear => st_rst,
      err       => heater_output_axi(i)
    );
  END GENERATE;
  
  led1_colour_arr <= X"ff0000";
  led2_colour_arr <= X"00ff00";
  led3_colour_arr <= X"0000ff";
  
  u_spi_max6966 : spi_max6966
  GENERIC MAP (
    con_simulation => FALSE
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
END str;
