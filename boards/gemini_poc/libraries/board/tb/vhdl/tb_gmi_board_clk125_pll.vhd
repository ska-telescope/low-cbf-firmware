LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE common_lib.common_pkg.ALL;


ENTITY tb_gmi_board_clk125_pll IS
END tb_gmi_board_clk125_pll;

ARCHITECTURE tb OF tb_gmi_board_clk125_pll IS

  CONSTANT c_ext_clk_period  : TIME := 8 ns; -- 125 MHz

  SIGNAL tb_end      : STD_LOGIC := '0';
  SIGNAL ext_clk     : STD_LOGIC := '0';
  SIGNAL ext_rst     : STD_LOGIC;
  SIGNAL c0_clk50    : STD_LOGIC;
  SIGNAL c1_clk100   : STD_LOGIC;
  SIGNAL c2_clk125   : STD_LOGIC;
  SIGNAL pll_locked  : STD_LOGIC;

BEGIN

  tb_end <= '0', '1' AFTER c_ext_clk_period*5000;

  ext_clk <= NOT ext_clk OR tb_end AFTER c_ext_clk_period/2;
  ext_rst <= '1', '0' AFTER c_ext_clk_period*7;

  dut_0 : ENTITY work.gmi_board_clk125_pll
  PORT MAP (
    arst      => ext_rst,
    clk125    => ext_clk,

    c0_clk50  => c0_clk50,
    c1_clk100  => c1_clk100,
    c2_clk125  => c2_clk125,

    pll_locked => pll_locked
  );
END tb;
