-------------------------------------------------------------------------------
--
-- Copyright (C) 2012-2014
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

LIBRARY IEEE, common_lib, i2c_lib;
USE IEEE.std_logic_1164.ALL;
USE common_lib.common_pkg.ALL;
USE i2c_lib.i2c_pkg.ALL;
USE work.gmi_board_pkg.ALL;

ENTITY gmi_board_sens is
  GENERIC (
    g_sim             : BOOLEAN := FALSE;
    g_i2c_peripheral  : NATURAL;
    g_clk_freq        : NATURAL := 100*10**6;  -- clk frequency in Hz
    g_temp_high       : NATURAL := 85;
    g_sens_nof_result : NATURAL; -- Should match nof read bytes via I2C in the gmi_board_sens_ctrl SEQUENCE list
    g_comma_w         : NATURAL := 0
  );
  PORT (
    rst          : IN    STD_LOGIC;
    clk          : IN    STD_LOGIC;
    start        : IN    STD_LOGIC;
    -- i2c bus
    scl          : INOUT STD_LOGIC;
    sda          : INOUT STD_LOGIC;
    -- read results
    sens_evt     : OUT   STD_LOGIC;
    sens_err     : OUT   STD_LOGIC;
    sens_data    : OUT   t_slv_8_arr(0 TO g_sens_nof_result-1)
  );
END ENTITY;


ARCHITECTURE str OF gmi_board_sens IS

  -- I2C clock rate settings
  CONSTANT c_sens_clk_cnt      : NATURAL := sel_a_b(g_sim, 1, func_i2c_calculate_clk_cnt(g_clk_freq/10**6));  -- define I2C clock rate
  --CONSTANT c_sens_comma_w      : NATURAL := 13;  -- 2**c_i2c_comma_w * system clock period comma time after I2C start and after each octet
                                                -- 0 = no comma time

-- octave:4> t=1/50e6
-- t =  2.0000e-08
-- octave:5> delay=2^13 * t
-- delay =  1.6384e-04
-- octave:6> delay/t
-- ans =  8192
-- octave:7> log2(ans)
-- ans =  13
-- octave:8> log2(delay/t)
-- ans =  13

  
  --CONSTANT c_sens_phy          : t_c_i2c_phy := (c_sens_clk_cnt, c_sens_comma_w);
  CONSTANT c_sens_phy          : t_c_i2c_phy := (c_sens_clk_cnt, g_comma_w);
  
  SIGNAL smbus_in_dat  : STD_LOGIC_VECTOR(c_byte_w-1 DOWNTO 0);
  SIGNAL smbus_in_val  : STD_LOGIC;
  SIGNAL smbus_out_dat : STD_LOGIC_VECTOR(c_byte_w-1 DOWNTO 0);
  SIGNAL smbus_out_val : STD_LOGIC;
  SIGNAL smbus_out_err : STD_LOGIC;
  SIGNAL smbus_out_ack : STD_LOGIC;
  SIGNAL smbus_out_end : STD_LOGIC;

BEGIN

  gen_gmi_board_sens_optics_l_ctrl : IF g_i2c_peripheral=c_i2c_peripheral_optics_l GENERATE
    u_gmi_board_sens_optics_l_ctrl : ENTITY work.gmi_board_sens_optics_l_ctrl
    GENERIC MAP (
      g_sim        => g_sim,
      g_nof_result => g_sens_nof_result,
      g_temp_high  => g_temp_high
    )
    PORT MAP (
      clk         => clk,
      rst         => rst,
      start       => start,
      in_dat      => smbus_out_dat,
      in_val      => smbus_out_val,
      in_err      => smbus_out_err,
      in_ack      => smbus_out_ack,
      in_end      => smbus_out_end,
      out_dat     => smbus_in_dat,
      out_val     => smbus_in_val,
      result_val  => sens_evt,
      result_err  => sens_err,
      result_dat  => sens_data
    );
  END GENERATE;

  gen_gmi_board_sens_optics_r_ctrl : IF g_i2c_peripheral=c_i2c_peripheral_optics_r GENERATE
    u_gmi_board_sens_optics_r_ctrl : ENTITY work.gmi_board_sens_optics_r_ctrl
    GENERIC MAP (
      g_sim        => g_sim,
      g_nof_result => g_sens_nof_result,
      g_temp_high  => g_temp_high
    )
    PORT MAP (
      clk         => clk,
      rst         => rst,
      start       => start,
      in_dat      => smbus_out_dat,
      in_val      => smbus_out_val,
      in_err      => smbus_out_err,
      in_ack      => smbus_out_ack,
      in_end      => smbus_out_end,
      out_dat     => smbus_in_dat,
      out_val     => smbus_in_val,
      result_val  => sens_evt,
      result_err  => sens_err,
      result_dat  => sens_data
    );
  END GENERATE;

  gen_gmi_board_pmbus_ctrl : IF g_i2c_peripheral=c_i2c_peripheral_pmbus GENERATE
    u_gmi_board_pmbus_ctrl : ENTITY work.gmi_board_pmbus_ctrl
    GENERIC MAP (
      g_sim        => g_sim,
      g_nof_result => g_sens_nof_result,
      g_temp_high  => g_temp_high
    )
    PORT MAP (
      clk         => clk,
      rst         => rst,
      start       => start,
      in_dat      => smbus_out_dat,
      in_val      => smbus_out_val,
      in_err      => smbus_out_err,
      in_ack      => smbus_out_ack,
      in_end      => smbus_out_end,
      out_dat     => smbus_in_dat,
      out_val     => smbus_in_val,
      result_val  => sens_evt,
      result_err  => sens_err,
      result_dat  => sens_data
    );
  END GENERATE;


  u_i2c_smbus : ENTITY i2c_lib.i2c_smbus
  GENERIC MAP (
    g_i2c_phy                 => c_sens_phy,
    g_clock_stretch_sense_scl => TRUE
  )
  PORT MAP (
    gs_sim      => g_sim,
    clk         => clk,
    rst         => rst,
    in_dat      => smbus_in_dat,
    in_req      => smbus_in_val,
    out_dat     => smbus_out_dat,
    out_val     => smbus_out_val,
    out_err     => smbus_out_err,
    out_ack     => smbus_out_ack,
    st_end      => smbus_out_end,
    scl         => scl,
    sda         => sda
  );

END ARCHITECTURE;
