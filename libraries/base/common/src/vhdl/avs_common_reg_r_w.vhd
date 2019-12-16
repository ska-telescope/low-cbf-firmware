-------------------------------------------------------------------------------
--
-- Copyright (C) 2010
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

-- (AVS Wrapper)


-- Derived from LOFAR cfg_single_reg
--
-- Usage:
-- 1) Connect out_reg to in_reg for write and readback register.
-- 2) Do not connect out_reg to in_reg for seperate write only register and
--    read only register at the same address.
-- 3) Leave out_reg OPEN for read only register.
-- 4) Connect wr_adr and rd_adr to have a shared address bus register.


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.common_pkg.ALL;
USE work.common_mem_pkg.ALL;

ENTITY avs_common_reg_r_w IS
  GENERIC (
    g_latency   : NATURAL := 1;    -- read latency
    g_adr_w     : NATURAL := 5;
    g_dat_w     : NATURAL := 32;
    g_nof_dat   : NATURAL := 32;    -- optional, nof dat words <= 2**adr_w
    g_init_sl   : STD_LOGIC := '0';  -- optional, init all dat words to std_logic '0', '1' or 'X'
    g_init_reg  : STD_LOGIC_VECTOR(c_mem_reg_init_w-1 DOWNTO 0) := (OTHERS => '0')
  );
  PORT (
    csi_system_reset        : IN  STD_LOGIC := '0';
    csi_system_clk          : IN  STD_LOGIC;

    -- MM side
    avs_register_address     : IN  STD_LOGIC_VECTOR(g_adr_w-1 DOWNTO 0);
    avs_register_write       : IN  STD_LOGIC;
    avs_register_writedata   : IN  STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    avs_register_read        : IN  STD_LOGIC;
    avs_register_readdata    : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);

    -- user side
    coe_out_reg_export      : OUT STD_LOGIC_VECTOR(g_dat_w*g_nof_dat-1 DOWNTO 0);
    coe_in_reg_export       : IN STD_LOGIC_VECTOR(g_dat_w*g_nof_dat-1 DOWNTO 0)
  );
END avs_common_reg_r_w;

ARCHITECTURE wrap OF avs_common_reg_r_w IS

  CONSTANT c_avs_memrec  : t_c_mem  := (latency => g_latency,
                                        adr_w => g_adr_w,
                                        dat_w => g_dat_w,
                                        addr_base => 0,
                                        nof_slaves => 1,
                                        nof_dat => g_nof_dat,
                                        init_sl => g_init_sl);

BEGIN

  common_reg_r_w : ENTITY work.common_reg_r_w
    GENERIC MAP(
      g_reg       => c_avs_memrec,
      g_init_reg  => g_init_reg
    )
    PORT MAP(
      mm_rst          => csi_system_reset,
      mm_clk          => csi_system_clk,
      mm_clken        => '1',
      -- control side
      wr_en           => avs_register_write,
      wr_adr          => avs_register_address,
      wr_dat          => avs_register_writedata,
      rd_en           => avs_register_read,
      rd_adr          => avs_register_address,
      rd_dat          => avs_register_readdata,
      rd_val          => OPEN,
      -- data side
      out_reg         => coe_out_reg_export,
      in_reg          => coe_in_reg_export
    );

END wrap;