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
USE work.common_mem_pkg.ALL;

ENTITY avs_common_ram_crw_crw IS
  GENERIC (  -- t_c_mem := (c_mem_ram_rd_latency, 10,  9, 2**10, 'X');  -- 1 M9K
    g_latency   : NATURAL := c_mem_ram_rd_latency;  
    g_adr_w     : NATURAL := 10;
    g_dat_w     : NATURAL := 9;
    g_nof_dat   : NATURAL := 2**10;    
    g_init_sl   : STD_LOGIC := 'X'; 
    g_init_file : STRING := "UNUSED" 
  );
  PORT (
    csi_system_reset        : IN  STD_LOGIC := '0';
    csi_system_clk          : IN  STD_LOGIC;
        
    -- MM side
    avs_ram_address     : IN  STD_LOGIC_VECTOR(g_adr_w-1 DOWNTO 0) := (OTHERS=>'0');
    avs_ram_write       : IN  STD_LOGIC;     
    avs_ram_writedata   : IN  STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0) := (OTHERS=>'0');
    avs_ram_read        : IN  STD_LOGIC;    
    avs_ram_readdata    : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0) := (OTHERS=>'0');
   
    -- user side
    coe_rst_export       : IN  STD_LOGIC; 
    coe_clk_export       : IN  STD_LOGIC;
    coe_wr_en_export     : IN  STD_LOGIC; 
    coe_wr_dat_export    : IN  STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0) := (OTHERS=>'0');
    coe_adr_export       : IN  STD_LOGIC_VECTOR(g_adr_w-1 DOWNTO 0) := (OTHERS=>'0');
    coe_rd_en_export     : IN STD_LOGIC;     
    coe_rd_dat_export    : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0) := (OTHERS=>'0');
    coe_rd_val_export    : OUT STD_LOGIC  
  );
END avs_common_ram_crw_crw;

ARCHITECTURE wrap OF avs_common_ram_crw_crw IS

  CONSTANT c_avs_memrec  : t_c_mem  := (g_latency, g_adr_w, g_dat_w, g_nof_dat, g_init_sl);
  
BEGIN            

  u_common_ram_crw_crw : ENTITY work.common_ram_crw_crw 
    GENERIC MAP(
     g_ram       => c_avs_memrec,
     g_init_file => g_init_file
    )
    PORT MAP(
     rst_a     => csi_system_reset,
     rst_b     => coe_rst_export,
     clk_a     => csi_system_clk,
     clk_b     => coe_clk_export,
     clken_a   => '1',
     clken_b   => '1',
     wr_en_a   => avs_ram_write,
     wr_en_b   => coe_wr_en_export,  
     wr_dat_a  => avs_ram_writedata,
     wr_dat_b  => coe_wr_dat_export,
     adr_a     => avs_ram_address,
     adr_b     => coe_adr_export,
     rd_en_a   => avs_ram_read,
     rd_en_b   => coe_rd_en_export,
     rd_dat_a  => avs_ram_readdata,
     rd_dat_b  => coe_rd_dat_export,
     rd_val_a  => OPEN,
     rd_val_b  => coe_rd_val_export      
    );

END wrap;
