-------------------------------------------------------------------------------
--
-- Copyright (C) 2009
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

LIBRARY IEEE, sim_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.common_pkg.ALL;


-- Purpose: Test bench for common_requantize.vhd
-- Usage:
-- > do wave_requantize.do
-- > run 1 us
-- . Do a diff with the golden reference output files for the DUTs. These files
--   are created using run 1 us and:
--   . c_in_dat_w           = 6
--   . c_out_dat_w          = 3
--   . c_lsb_w              = 2
--   . c_lsb_round_clip     = TRUE
--   . c_msb_clip_symmetric = TRUE
-- . Observe reg_dat with respect to the out_s_*_*.dat and out_u_*_*.dat
-- . Try also c_lsb_round_clip=FALSE
-- . Try also c_msb_clip_symmetric=FALSE

ENTITY tb_requantize IS
END tb_requantize;

ARCHITECTURE tb OF tb_requantize IS

  CONSTANT clk_period            : TIME := 10 ns;
  CONSTANT c_output_file_dir     : STRING := "../../../data/";

  CONSTANT c_nof_dut             : NATURAL := 4;
  CONSTANT g_pipeline_remove_lsb : NATURAL := 0;
  CONSTANT g_pipeline_remove_msb : NATURAL := 1;
  CONSTANT c_pipeline            : NATURAL := g_pipeline_remove_lsb + g_pipeline_remove_msb;
  CONSTANT c_in_dat_w            : NATURAL := 6;
  CONSTANT c_out_dat_w           : NATURAL := 3;
  CONSTANT c_lsb_w               : NATURAL := 2;
  CONSTANT c_lsb_round_clip      : BOOLEAN := TRUE; --FALSE;
  CONSTANT c_msb_clip_symmetric  : BOOLEAN := TRUE; --FALSE;

  -- Stimuli
  SIGNAL in_val         : STD_LOGIC;
  SIGNAL in_dat         : STD_LOGIC_VECTOR(c_in_dat_w-1 DOWNTO 0);
  SIGNAL in_vec         : STD_LOGIC_VECTOR(c_in_dat_w   DOWNTO 0);
  SIGNAL reg_vec        : STD_LOGIC_VECTOR(c_in_dat_w   DOWNTO 0);
  SIGNAL reg_val        : STD_LOGIC;
  SIGNAL reg_dat        : STD_LOGIC_VECTOR(c_in_dat_w-1 DOWNTO 0);

  -- DUT output
  SIGNAL out_s_r_c_dat  : STD_LOGIC_VECTOR(c_out_dat_w-1 DOWNTO 0);  -- src = signed round and clip
  SIGNAL out_s_r_c_ovr  : STD_LOGIC;
  SIGNAL out_s_r_w_dat  : STD_LOGIC_VECTOR(c_out_dat_w-1 DOWNTO 0);  -- srw = signed round and wrap
  SIGNAL out_s_r_w_ovr  : STD_LOGIC;
  SIGNAL out_s_t_c_dat  : STD_LOGIC_VECTOR(c_out_dat_w-1 DOWNTO 0);  -- stc = signed truncate and clip
  SIGNAL out_s_t_c_ovr  : STD_LOGIC;
  SIGNAL out_s_t_w_dat  : STD_LOGIC_VECTOR(c_out_dat_w-1 DOWNTO 0);  -- stw = signed truncate and wrap
  SIGNAL out_s_t_w_ovr  : STD_LOGIC;

  SIGNAL out_u_r_c_dat  : STD_LOGIC_VECTOR(c_out_dat_w-1 DOWNTO 0);  -- urc = unsigned round and clip
  SIGNAL out_u_r_c_ovr  : STD_LOGIC;
  SIGNAL out_u_r_w_dat  : STD_LOGIC_VECTOR(c_out_dat_w-1 DOWNTO 0);  -- urw = unsigned round and wrap
  SIGNAL out_u_r_w_ovr  : STD_LOGIC;
  SIGNAL out_u_t_c_dat  : STD_LOGIC_VECTOR(c_out_dat_w-1 DOWNTO 0);  -- utc = unsigned truncate and clip
  SIGNAL out_u_t_c_ovr  : STD_LOGIC;
  SIGNAL out_u_t_w_dat  : STD_LOGIC_VECTOR(c_out_dat_w-1 DOWNTO 0);  -- utw = unsigned truncate and wrap
  SIGNAL out_u_t_w_ovr  : STD_LOGIC;

  -- Verification by means of writing output files that can be compared with stored golden reference files
  SIGNAL out_s_dat_vec  : STD_LOGIC_VECTOR(c_out_dat_w*c_nof_dut-1 DOWNTO 0);
  SIGNAL out_s_ovr_vec  : STD_LOGIC_VECTOR(            c_nof_dut-1 DOWNTO 0);
  SIGNAL out_u_dat_vec  : STD_LOGIC_VECTOR(c_out_dat_w*c_nof_dut-1 DOWNTO 0);
  SIGNAL out_u_ovr_vec  : STD_LOGIC_VECTOR(            c_nof_dut-1 DOWNTO 0);

  SIGNAL rst            : STD_LOGIC;
  SIGNAL clk            : STD_LOGIC := '1';

  CONSTANT c_init       : STD_LOGIC_VECTOR(in_dat'RANGE) := (OTHERS=>'0');

BEGIN

  -- Stimuli
  clk <= NOT(clk) AFTER clk_period/2;
  rst <= '1', '0' AFTER 3*clk_period;

  p_clk : PROCESS (rst, clk)
  BEGIN
    IF rst='1' THEN
      in_val      <= '0';
      in_dat      <= c_init;
    ELSIF rising_edge(clk) THEN
      in_val      <= '1';
      in_dat      <= STD_LOGIC_VECTOR(SIGNED(in_dat)+1);
    END IF;
  END PROCESS;

  -- Delay input as much as DUT output
  in_vec <= in_val & in_dat;

  u_pipe : ENTITY work.common_pipeline
  GENERIC MAP (
    g_representation => "SIGNED",
    g_pipeline       => c_pipeline,
    g_in_dat_w       => c_in_dat_w+1,
    g_out_dat_w      => c_in_dat_w+1
  )
  PORT MAP (
    clk     => clk,
    in_dat  => in_vec,
    out_dat => reg_vec
  );

  reg_val <= reg_vec(c_in_dat_w);
  reg_dat <= reg_vec(c_in_dat_w-1 DOWNTO 0);

  -- DUT for "SIGNED"
  u_s_r_c : ENTITY work.common_requantize
  GENERIC MAP (
    g_representation      => "SIGNED",
    g_lsb_w               => c_lsb_w,
    g_lsb_round           => TRUE,
    g_lsb_round_clip      => c_lsb_round_clip,
    g_msb_clip            => TRUE,
    g_msb_clip_symmetric  => c_msb_clip_symmetric,
    g_pipeline_remove_lsb => g_pipeline_remove_lsb,
    g_pipeline_remove_msb => g_pipeline_remove_msb,
    g_in_dat_w            => c_in_dat_w,
    g_out_dat_w           => c_out_dat_w
  )
  PORT MAP (
    clk            => clk,
    in_dat         => in_dat,
    out_dat        => out_s_r_c_dat,
    out_ovr        => out_s_r_c_ovr
  );

  u_s_r_w : ENTITY work.common_requantize
  GENERIC MAP (
    g_representation      => "SIGNED",
    g_lsb_w               => c_lsb_w,
    g_lsb_round           => TRUE,
    g_lsb_round_clip      => c_lsb_round_clip,
    g_msb_clip            => FALSE,
    g_msb_clip_symmetric  => c_msb_clip_symmetric,
    g_pipeline_remove_lsb => g_pipeline_remove_lsb,
    g_pipeline_remove_msb => g_pipeline_remove_msb,
    g_in_dat_w            => c_in_dat_w,
    g_out_dat_w           => c_out_dat_w
  )
  PORT MAP (
    clk            => clk,
    in_dat         => in_dat,
    out_dat        => out_s_r_w_dat,
    out_ovr        => out_s_r_w_ovr
  );

  u_s_t_c : ENTITY work.common_requantize
  GENERIC MAP (
    g_representation      => "SIGNED",
    g_lsb_w               => c_lsb_w,
    g_lsb_round           => FALSE,
    g_lsb_round_clip      => c_lsb_round_clip,
    g_msb_clip            => TRUE,
    g_msb_clip_symmetric  => c_msb_clip_symmetric,
    g_pipeline_remove_lsb => g_pipeline_remove_lsb,
    g_pipeline_remove_msb => g_pipeline_remove_msb,
    g_in_dat_w            => c_in_dat_w,
    g_out_dat_w           => c_out_dat_w
  )
  PORT MAP (
    clk            => clk,
    in_dat         => in_dat,
    out_dat        => out_s_t_c_dat,
    out_ovr        => out_s_t_c_ovr
  );

  u_s_t_w : ENTITY work.common_requantize
  GENERIC MAP (
    g_representation      => "SIGNED",
    g_lsb_w               => c_lsb_w,
    g_lsb_round           => FALSE,
    g_lsb_round_clip      => c_lsb_round_clip,
    g_msb_clip            => FALSE,
    g_msb_clip_symmetric  => c_msb_clip_symmetric,
    g_pipeline_remove_lsb => g_pipeline_remove_lsb,
    g_pipeline_remove_msb => g_pipeline_remove_msb,
    g_in_dat_w            => c_in_dat_w,
    g_out_dat_w           => c_out_dat_w
  )
  PORT MAP (
    clk            => clk,
    in_dat         => in_dat,
    out_dat        => out_s_t_w_dat,
    out_ovr        => out_s_t_w_ovr
  );

  -- DUT for "UNSIGNED"
  u_u_r_c : ENTITY work.common_requantize
  GENERIC MAP (
    g_representation      => "UNSIGNED",
    g_lsb_w               => c_lsb_w,
    g_lsb_round           => TRUE,
    g_lsb_round_clip      => c_lsb_round_clip,
    g_msb_clip            => TRUE,
    g_msb_clip_symmetric  => c_msb_clip_symmetric,
    g_pipeline_remove_lsb => g_pipeline_remove_lsb,
    g_pipeline_remove_msb => g_pipeline_remove_msb,
    g_in_dat_w            => c_in_dat_w,
    g_out_dat_w           => c_out_dat_w
  )
  PORT MAP (
    clk            => clk,
    in_dat         => in_dat,
    out_dat        => out_u_r_c_dat,
    out_ovr        => out_u_r_c_ovr
  );

  u_u_r_w : ENTITY work.common_requantize
  GENERIC MAP (
    g_representation      => "UNSIGNED",
    g_lsb_w               => c_lsb_w,
    g_lsb_round           => TRUE,
    g_lsb_round_clip      => c_lsb_round_clip,
    g_msb_clip            => FALSE,
    g_msb_clip_symmetric  => c_msb_clip_symmetric,
    g_pipeline_remove_lsb => g_pipeline_remove_lsb,
    g_pipeline_remove_msb => g_pipeline_remove_msb,
    g_in_dat_w            => c_in_dat_w,
    g_out_dat_w           => c_out_dat_w
  )
  PORT MAP (
    clk            => clk,
    in_dat         => in_dat,
    out_dat        => out_u_r_w_dat,
    out_ovr        => out_u_r_w_ovr
  );

  u_u_t_c : ENTITY work.common_requantize
  GENERIC MAP (
    g_representation      => "UNSIGNED",
    g_lsb_w               => c_lsb_w,
    g_lsb_round           => FALSE,
    g_lsb_round_clip      => c_lsb_round_clip,
    g_msb_clip            => TRUE,
    g_msb_clip_symmetric  => c_msb_clip_symmetric,
    g_pipeline_remove_lsb => g_pipeline_remove_lsb,
    g_pipeline_remove_msb => g_pipeline_remove_msb,
    g_in_dat_w            => c_in_dat_w,
    g_out_dat_w           => c_out_dat_w
  )
  PORT MAP (
    clk            => clk,
    in_dat         => in_dat,
    out_dat        => out_u_t_c_dat,
    out_ovr        => out_u_t_c_ovr
  );

  u_u_t_w : ENTITY work.common_requantize
  GENERIC MAP (
    g_representation      => "UNSIGNED",
    g_lsb_w               => c_lsb_w,
    g_lsb_round           => FALSE,
    g_lsb_round_clip      => c_lsb_round_clip,
    g_msb_clip            => FALSE,
    g_msb_clip_symmetric  => c_msb_clip_symmetric,
    g_pipeline_remove_lsb => g_pipeline_remove_lsb,
    g_pipeline_remove_msb => g_pipeline_remove_msb,
    g_in_dat_w            => c_in_dat_w,
    g_out_dat_w           => c_out_dat_w
  )
  PORT MAP (
    clk            => clk,
    in_dat         => in_dat,
    out_dat        => out_u_t_w_dat,
    out_ovr        => out_u_t_w_ovr
  );

  -- Verification
  out_s_dat_vec <= out_s_r_c_dat & out_s_r_w_dat & out_s_t_c_dat & out_s_t_w_dat;
  out_s_ovr_vec <= out_s_r_c_ovr & out_s_r_w_ovr & out_s_t_c_ovr & out_s_t_w_ovr;
  out_u_dat_vec <= out_u_r_c_dat & out_u_r_w_dat & out_u_t_c_dat & out_u_t_w_dat;
  out_u_ovr_vec <= out_u_r_c_ovr & out_u_r_w_ovr & out_u_t_c_ovr & out_u_t_w_ovr;

  u_output_file_s_dat : ENTITY sim_lib.file_output
  GENERIC MAP (
    g_file_name   => c_output_file_dir & "tb_requantize_s_dat.out",
    g_nof_data    => c_nof_dut,
    g_data_width  => c_out_dat_w,
    g_data_type   => "SIGNED"
  )
  PORT MAP (
    clk      => clk,
    rst      => rst,
    in_dat   => out_s_dat_vec,
    in_val   => reg_val
  );

  u_output_file_s_ovr : ENTITY sim_lib.file_output
  GENERIC MAP (
    g_file_name   => c_output_file_dir & "tb_requantize_s_ovr.out",
    g_nof_data    => c_nof_dut,
    g_data_width  => 1,
    g_data_type   => "UNSIGNED"
  )
  PORT MAP (
    clk      => clk,
    rst      => rst,
    in_dat   => out_s_ovr_vec,
    in_val   => reg_val
  );

  u_output_file_u_dat : ENTITY sim_lib.file_output
  GENERIC MAP (
    g_file_name   => c_output_file_dir & "tb_requantize_u_dat.out",
    g_nof_data    => c_nof_dut,
    g_data_width  => c_out_dat_w,
    g_data_type   => "UNSIGNED"
  )
  PORT MAP (
    clk      => clk,
    rst      => rst,
    in_dat   => out_u_dat_vec,
    in_val   => reg_val
  );

  u_output_file_u_ovr : ENTITY sim_lib.file_output
  GENERIC MAP (
    g_file_name   => c_output_file_dir & "tb_requantize_u_ovr.out",
    g_nof_data    => c_nof_dut,
    g_data_width  => 1,
    g_data_type   => "UNSIGNED"
  )
  PORT MAP (
    clk      => clk,
    rst      => rst,
    in_dat   => out_u_ovr_vec,
    in_val   => reg_val
  );

END tb;
