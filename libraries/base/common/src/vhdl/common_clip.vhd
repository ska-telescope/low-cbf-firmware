-------------------------------------------------------------------------------
--
-- Copyright (C) 2011
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

LIBRARY IEEE, common_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;

-- Function:
--   When enabled clip input, else pass input on unchanged. Report clippled
--   output data via overflow bit.
--   . Clip   signed input to range [-g_full_scale +g_full_scale]
--   . Clip unsigned input to range [ 0            +g_full_scale]
-- Remark:
-- . Define g_full_scale as SIGNED to avoid NATURAL limited to <= 2**31-1.
-- . Input and output must have the same width
-- . Use g_full_scale = 2**(c_dat_w-1)-1 to achieve a symmetrical range which
--   allow skipping one sign bit after multiplication. E.g. 18b*18b --> 35b
--   are sufficient for the signed product instead of 36b.

ENTITY common_clip IS
  GENERIC (
    g_representation : STRING  := "SIGNED";  -- SIGNED or UNSIGNED clipping
    g_pipeline       : NATURAL := 1;
    g_full_scale     : UNSIGNED
  );
  PORT (
    rst      : IN  STD_LOGIC := '0';
    clk      : IN  STD_LOGIC;
    clken    : IN  STD_LOGIC := '1';
    enable   : IN  STD_LOGIC := '1';
    in_dat   : IN  STD_LOGIC_VECTOR;
    out_dat  : OUT STD_LOGIC_VECTOR;
    out_ovr  : OUT STD_LOGIC
  );
END;


ARCHITECTURE rtl OF common_clip IS
  
  CONSTANT c_s_full_scale_w : NATURAL := g_full_scale'LENGTH + 1;
  CONSTANT c_u_full_scale_w : NATURAL := g_full_scale'LENGTH;
  
  CONSTANT c_s_full_scale   :   SIGNED(c_s_full_scale_w-1 DOWNTO 0) := SIGNED('0' & STD_LOGIC_VECTOR(g_full_scale));
  CONSTANT c_u_full_scale   : UNSIGNED(c_u_full_scale_w-1 DOWNTO 0) := g_full_scale;
  
  CONSTANT c_output_pipe    : NATURAL := sel_a_b(g_pipeline>1, g_pipeline-1, 0);
  
  CONSTANT c_dat_w          : NATURAL := out_dat'LENGTH;

  SIGNAL clip_dat     : STD_LOGIC_VECTOR(c_dat_w-1 DOWNTO 0);
  SIGNAL nxt_clip_dat : STD_LOGIC_VECTOR(c_dat_w-1 DOWNTO 0);
  SIGNAL clip_ovr     : STD_LOGIC;
  SIGNAL nxt_clip_ovr : STD_LOGIC;
  
  SIGNAL pipe_in      : STD_LOGIC_VECTOR(c_dat_w DOWNTO 0);
  SIGNAL pipe_out     : STD_LOGIC_VECTOR(c_dat_w DOWNTO 0);
  
BEGIN

  p_clip : PROCESS(in_dat, enable)
  BEGIN
    nxt_clip_dat <= in_dat;
    nxt_clip_ovr <= '0';
    IF enable='1' THEN
      IF g_representation="SIGNED" THEN
        IF    SIGNED(in_dat) >  c_s_full_scale THEN
          nxt_clip_dat <= STD_LOGIC_VECTOR(RESIZE_NUM( c_s_full_scale, c_dat_w));
          nxt_clip_ovr <= '1';
        ELSIF SIGNED(in_dat) < -c_s_full_scale THEN
          nxt_clip_dat <= STD_LOGIC_VECTOR(RESIZE_NUM(-c_s_full_scale, c_dat_w));
          nxt_clip_ovr <= '1';
        END IF;
      ELSE
        IF UNSIGNED(in_dat) > c_u_full_scale THEN
          nxt_clip_dat <= STD_LOGIC_VECTOR(RESIZE_NUM(c_u_full_scale, c_dat_w));
          nxt_clip_ovr <= '1';
        END IF;
      END IF;
    END IF;
  END PROCESS;

  no_reg : IF g_pipeline=0 GENERATE
    clip_dat <= nxt_clip_dat;
    clip_ovr <= nxt_clip_ovr;
  END GENERATE;
  
  gen_reg : IF g_pipeline>0 GENERATE
    p_clk : PROCESS (rst, clk)
    BEGIN
      IF rst='1' THEN
        clip_dat <= (OTHERS => '0');
        clip_ovr <= '0';
      ELSIF rising_edge(clk) THEN
        IF clken='1' THEN
          clip_dat <= nxt_clip_dat;
          clip_ovr <= nxt_clip_ovr;
        END IF;
      END IF;
    END PROCESS;
  END GENERATE;
  
  -- Optional extra pipelining
  pipe_in <= clip_ovr & clip_dat;
  
  u_output_pipe : ENTITY work.common_pipeline
  GENERIC MAP (
    g_pipeline       => c_output_pipe,
    g_in_dat_w       => c_dat_w+1,
    g_out_dat_w      => c_dat_w+1
  )
  PORT MAP (
    rst     => rst,
    clk     => clk,
    clken   => clken,
    in_dat  => pipe_in,
    out_dat => pipe_out
  );
  
  out_ovr <= pipe_out(pipe_out'HIGH);
  out_dat <= pipe_out(pipe_out'HIGH-1 DOWNTO 0);
  
END rtl;