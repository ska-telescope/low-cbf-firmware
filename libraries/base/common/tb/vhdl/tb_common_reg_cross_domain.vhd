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

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;

ENTITY tb_common_reg_cross_domain IS
END tb_common_reg_cross_domain;

ARCHITECTURE tb OF tb_common_reg_cross_domain IS

  --CONSTANT in_clk_period    : TIME := 10 ns;
  CONSTANT in_clk_period    : TIME := 17 ns;
  CONSTANT out_clk_period   : TIME := 17 ns;
  CONSTANT c_interval       : NATURAL := 19;
  --CONSTANT c_interval       : NATURAL := 20;
  
  CONSTANT c_in_new_latency : NATURAL := 2;  -- use <2 and =2 to verify s_pulse_latency
  CONSTANT c_dat_w          : NATURAL := 8;

  -- The state name tells what kind of test is done
  TYPE t_state_enum IS (
    s_idle,
    s_pulse,
    s_pulse_latency,
    s_level,
    s_done
  );
  
  SIGNAL state     : t_state_enum;
  
  SIGNAL in_rst    : STD_LOGIC;
  SIGNAL out_rst   : STD_LOGIC;
  SIGNAL in_clk    : STD_LOGIC := '0';
  SIGNAL out_clk   : STD_LOGIC := '0';
  SIGNAL in_new    : STD_LOGIC := '0';
  SIGNAL in_done   : STD_LOGIC;
  SIGNAL in_dat    : STD_LOGIC_VECTOR(c_dat_w-1 DOWNTO 0);
  SIGNAL out_dat   : STD_LOGIC_VECTOR(c_dat_w-1 DOWNTO 0);
  SIGNAL out_new   : STD_LOGIC;

BEGIN

  in_clk  <= NOT in_clk  AFTER in_clk_period/2;
  out_clk <= NOT out_clk AFTER out_clk_period/2;
    
  p_in_stimuli : PROCESS
  BEGIN
    state  <= s_idle;
    in_rst <= '1';
    in_new <= '0';
    in_dat <= (OTHERS=>'0');
    WAIT UNTIL rising_edge(in_clk);
    in_rst <= '0';
    FOR I IN 0 TO c_interval LOOP WAIT UNTIL rising_edge(in_clk); END LOOP;
    
    -- Single in_new pulse
    state <= s_pulse;
    in_dat <= INCR_UVEC(in_dat, 1);
    WAIT UNTIL rising_edge(in_clk);
    in_new <= '1';
    WAIT UNTIL rising_edge(in_clk);
    in_new <= '0';
    FOR I IN 0 TO c_interval LOOP WAIT UNTIL rising_edge(in_clk); END LOOP;
    
    -- Single in_new pulse with latency 2
    state <= s_pulse_latency;
    in_new <= '1';
    WAIT UNTIL rising_edge(in_clk);
    in_new <= '0';
    WAIT UNTIL rising_edge(in_clk);
    in_dat <= INCR_UVEC(in_dat, 1);
    WAIT UNTIL rising_edge(in_clk);
    FOR I IN 0 TO c_interval LOOP WAIT UNTIL rising_edge(in_clk); END LOOP;
    
    -- Continue level high in_new
    state <= s_level;
    in_dat <= INCR_UVEC(in_dat, 1);
    WAIT UNTIL rising_edge(in_clk);
    in_new <= '1';
    FOR I IN 0 TO c_interval LOOP WAIT UNTIL rising_edge(in_clk); END LOOP;
    in_dat <= INCR_UVEC(in_dat, 1);
    FOR I IN 0 TO c_interval LOOP WAIT UNTIL rising_edge(in_clk); END LOOP;
    in_dat <= INCR_UVEC(in_dat, 1);
    FOR I IN 0 TO c_interval LOOP WAIT UNTIL rising_edge(in_clk); END LOOP;
    in_new <= '0';
    FOR I IN 0 TO c_interval LOOP WAIT UNTIL rising_edge(in_clk); END LOOP;
    
    state <= s_done;
    WAIT;
  END PROCESS;

  u_out_rst : ENTITY work.common_areset
  PORT MAP (
    in_rst   => in_rst,
    clk      => out_clk,
    out_rst  => out_rst
  );
  
  u_reg_cross_domain : ENTITY work.common_reg_cross_domain
  GENERIC MAP (
    g_in_new_latency => c_in_new_latency
  )
  PORT MAP (
    in_rst     => in_rst,
    in_clk     => in_clk,
    in_new     => in_new,  -- when '1' then new in_dat is available after g_in_new_latency
    in_dat     => in_dat,
    in_done    => in_done,
    out_rst    => out_rst,
    out_clk    => out_clk,
    out_dat    => out_dat,
    out_new    => out_new  -- when '1' then the out_dat was updated with in_dat due to in_new
  );
  
END tb;
