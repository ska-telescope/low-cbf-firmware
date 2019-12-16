-------------------------------------------------------------------------------
--
-- Copyright (C) 2014
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

-- Purpose: IP components declarations for various devices that get wrapped by the tech components

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

PACKAGE tech_memory_component_pkg IS

  -----------------------------------------------------------------------------
  -- ip_stratixiv
  -----------------------------------------------------------------------------
  
  COMPONENT ip_stratixiv_ram_crwk_crw IS  -- support different port data widths and corresponding address ranges
  GENERIC (
    g_adr_a_w     : NATURAL := 5;
    g_dat_a_w     : NATURAL := 32;
    g_adr_b_w     : NATURAL := 7;
    g_dat_b_w     : NATURAL := 8;
    g_nof_words_a : NATURAL := 2**5;
    g_nof_words_b : NATURAL := 2**7;
    g_rd_latency  : NATURAL := 2;     -- choose 1 or 2
    g_init_file   : STRING  := "UNUSED"
  );
  PORT (
    address_a   : IN STD_LOGIC_VECTOR (g_adr_a_w-1 DOWNTO 0);
    address_b   : IN STD_LOGIC_VECTOR (g_adr_b_w-1 DOWNTO 0);
    clock_a   : IN STD_LOGIC  := '1';
    clock_b   : IN STD_LOGIC ;
    data_a    : IN STD_LOGIC_VECTOR (g_dat_a_w-1 DOWNTO 0);
    data_b    : IN STD_LOGIC_VECTOR (g_dat_b_w-1 DOWNTO 0);
    enable_a    : IN STD_LOGIC  := '1';
    enable_b    : IN STD_LOGIC  := '1';
    rden_a    : IN STD_LOGIC  := '1';
    rden_b    : IN STD_LOGIC  := '1';
    wren_a    : IN STD_LOGIC  := '0';
    wren_b    : IN STD_LOGIC  := '0';
    q_a   : OUT STD_LOGIC_VECTOR (g_dat_a_w-1 DOWNTO 0);
    q_b   : OUT STD_LOGIC_VECTOR (g_dat_b_w-1 DOWNTO 0)
  );
  END COMPONENT;
  
  COMPONENT ip_stratixiv_ram_crw_crw IS
  GENERIC (
    g_adr_w      : NATURAL := 5;
    g_dat_w      : NATURAL := 8;
    g_nof_words  : NATURAL := 2**5;
    g_rd_latency : NATURAL := 2;  -- choose 1 or 2
    g_init_file  : STRING  := "UNUSED"
  );
  PORT (
    address_a   : IN STD_LOGIC_VECTOR (g_adr_w-1 DOWNTO 0);
    address_b   : IN STD_LOGIC_VECTOR (g_adr_w-1 DOWNTO 0);
    clock_a   : IN STD_LOGIC  := '1';
    clock_b   : IN STD_LOGIC ;
    data_a    : IN STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    data_b    : IN STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    enable_a    : IN STD_LOGIC  := '1';
    enable_b    : IN STD_LOGIC  := '1';
    rden_a    : IN STD_LOGIC  := '1';
    rden_b    : IN STD_LOGIC  := '1';
    wren_a    : IN STD_LOGIC  := '0';
    wren_b    : IN STD_LOGIC  := '0';
    q_a   : OUT STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    q_b   : OUT STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0)
  );
  END COMPONENT;
  
  COMPONENT ip_stratixiv_ram_cr_cw IS
  GENERIC (
    g_adr_w      : NATURAL := 5;
    g_dat_w      : NATURAL := 8;
    g_nof_words  : NATURAL := 2**5;
    g_rd_latency : NATURAL := 2;  -- choose 1 or 2
    g_init_file  : STRING  := "UNUSED"
  );
  PORT (
    data      : IN  STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    rdaddress : IN  STD_LOGIC_VECTOR (g_adr_w-1 DOWNTO 0);
    rdclock   : IN  STD_LOGIC ;
    rdclocken : IN  STD_LOGIC  := '1';
    wraddress : IN  STD_LOGIC_VECTOR (g_adr_w-1 DOWNTO 0);
    wrclock   : IN  STD_LOGIC  := '1';
    wrclocken : IN  STD_LOGIC  := '1';
    wren      : IN  STD_LOGIC  := '0';
    q         : OUT STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0)
  );
  END COMPONENT;
  
  COMPONENT ip_stratixiv_ram_r_w IS
  GENERIC (
    g_adr_w     : NATURAL := 5;
    g_dat_w     : NATURAL := 8;
    g_nof_words : NATURAL := 2**5;
    g_init_file : STRING  := "UNUSED"
  );
  PORT (
    clock       : IN STD_LOGIC  := '1';
    enable      : IN STD_LOGIC  := '1';
    data        : IN STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    rdaddress   : IN STD_LOGIC_VECTOR(g_adr_w-1 DOWNTO 0);
    wraddress   : IN STD_LOGIC_VECTOR(g_adr_w-1 DOWNTO 0);
    wren        : IN STD_LOGIC  := '0';
    q           : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0)
  );
  END COMPONENT;
  
  COMPONENT ip_stratixiv_rom_r IS
  GENERIC (
    g_adr_w     : NATURAL := 5;
    g_dat_w     : NATURAL := 8;
    g_nof_words : NATURAL := 2**5;
    g_init_file : STRING  := "UNUSED"
  );
  PORT (
    address   : IN STD_LOGIC_VECTOR(g_adr_w-1 DOWNTO 0);
    clock     : IN STD_LOGIC  := '1';
    clken     : IN STD_LOGIC  := '1';
    q         : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0)
  );
  END COMPONENT;


  -----------------------------------------------------------------------------
  -- ip_arria10
  -----------------------------------------------------------------------------
  
  COMPONENT ip_arria10_ram_crwk_crw IS
  GENERIC (
    g_adr_a_w     : NATURAL := 5;
    g_dat_a_w     : NATURAL := 32;
    g_adr_b_w     : NATURAL := 4;
    g_dat_b_w     : NATURAL := 64;
    g_nof_words_a : NATURAL := 2**5;
    g_nof_words_b : NATURAL := 2**4;
    g_rd_latency  : NATURAL := 1;     -- choose 1 or 2
    g_init_file   : STRING  := "UNUSED"
  );
  PORT
  (
    address_a : IN STD_LOGIC_VECTOR (g_adr_a_w-1 DOWNTO 0);
    address_b : IN STD_LOGIC_VECTOR (g_adr_b_w-1 DOWNTO 0);
    clk_a     : IN STD_LOGIC  := '1';
    clk_b     : IN STD_LOGIC ;
    data_a    : IN STD_LOGIC_VECTOR (g_dat_a_w-1 DOWNTO 0);
    data_b    : IN STD_LOGIC_VECTOR (g_dat_b_w-1 DOWNTO 0);
    wren_a    : IN STD_LOGIC  := '0';
    wren_b    : IN STD_LOGIC  := '0';
    q_a       : OUT STD_LOGIC_VECTOR (g_dat_a_w-1 DOWNTO 0);
    q_b       : OUT STD_LOGIC_VECTOR (g_dat_b_w-1 DOWNTO 0)
  );
  END COMPONENT;

  COMPONENT ip_arria10_ram_crw_crw IS
  GENERIC (
    g_inferred   : BOOLEAN := FALSE;
    g_adr_w      : NATURAL := 5;
    g_dat_w      : NATURAL := 8;
    g_nof_words  : NATURAL := 2**5;
    g_rd_latency : NATURAL := 1;  -- choose 1 or 2
    g_init_file  : STRING  := "UNUSED"
  );
  PORT
  (
    address_a : IN STD_LOGIC_VECTOR (g_adr_w-1 DOWNTO 0);
    address_b : IN STD_LOGIC_VECTOR (g_adr_w-1 DOWNTO 0);
    clk_a     : IN STD_LOGIC  := '1';
    clk_b     : IN STD_LOGIC ;
    data_a    : IN STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    data_b    : IN STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    wren_a    : IN STD_LOGIC  := '0';
    wren_b    : IN STD_LOGIC  := '0';
    q_a       : OUT STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    q_b       : OUT STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0)
  );
  END COMPONENT;
  
  COMPONENT ip_arria10_ram_cr_cw IS
  GENERIC (
    g_inferred   : BOOLEAN := FALSE;
    g_adr_w      : NATURAL := 5;
    g_dat_w      : NATURAL := 8;
    g_nof_words  : NATURAL := 2**5;
    g_rd_latency : NATURAL := 1;  -- choose 1 or 2
    g_init_file  : STRING  := "UNUSED"
  );
  PORT
  (
    data      : IN  STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    rdaddress : IN  STD_LOGIC_VECTOR (g_adr_w-1 DOWNTO 0);
    rdclk     : IN  STD_LOGIC ;
    wraddress : IN  STD_LOGIC_VECTOR (g_adr_w-1 DOWNTO 0);
    wrclk     : IN  STD_LOGIC  := '1';
    wren      : IN  STD_LOGIC  := '0';
    q         : OUT STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0)
  );
  END COMPONENT;
  
  COMPONENT ip_arria10_ram_r_w IS
  GENERIC (
    g_inferred   : BOOLEAN := FALSE;
    g_adr_w      : NATURAL := 5;
    g_dat_w      : NATURAL := 8;
    g_nof_words  : NATURAL := 2**5;
    g_rd_latency : NATURAL := 1;     -- choose 1 or 2
    g_init_file  : STRING  := "UNUSED"
  );
  PORT (
    clk         : IN STD_LOGIC  := '1';
    data        : IN STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0) := (OTHERS=>'0');
    rdaddress   : IN STD_LOGIC_VECTOR(g_adr_w-1 DOWNTO 0) := (OTHERS=>'0');
    wraddress   : IN STD_LOGIC_VECTOR(g_adr_w-1 DOWNTO 0) := (OTHERS=>'0');
    wren        : IN STD_LOGIC  := '0';
    q           : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0)
  );
  END COMPONENT;
  
  -----------------------------------------------------------------------------
  -- ip_arria10_e3sge3
  -----------------------------------------------------------------------------
  
  COMPONENT ip_arria10_e3sge3_ram_crwk_crw IS
  GENERIC (
    g_adr_a_w     : NATURAL := 5;
    g_dat_a_w     : NATURAL := 32;
    g_adr_b_w     : NATURAL := 4;
    g_dat_b_w     : NATURAL := 64;
    g_nof_words_a : NATURAL := 2**5;
    g_nof_words_b : NATURAL := 2**4;
    g_rd_latency  : NATURAL := 1;     -- choose 1 or 2
    g_init_file   : STRING  := "UNUSED"
  );
  PORT
  (
    address_a : IN STD_LOGIC_VECTOR (g_adr_a_w-1 DOWNTO 0);
    address_b : IN STD_LOGIC_VECTOR (g_adr_b_w-1 DOWNTO 0);
    clk_a     : IN STD_LOGIC  := '1';
    clk_b     : IN STD_LOGIC ;
    data_a    : IN STD_LOGIC_VECTOR (g_dat_a_w-1 DOWNTO 0);
    data_b    : IN STD_LOGIC_VECTOR (g_dat_b_w-1 DOWNTO 0);
    wren_a    : IN STD_LOGIC  := '0';
    wren_b    : IN STD_LOGIC  := '0';
    q_a       : OUT STD_LOGIC_VECTOR (g_dat_a_w-1 DOWNTO 0);
    q_b       : OUT STD_LOGIC_VECTOR (g_dat_b_w-1 DOWNTO 0)
  );
  END COMPONENT;

  COMPONENT ip_arria10_e3sge3_ram_crw_crw IS
  GENERIC (
    g_inferred   : BOOLEAN := FALSE;
    g_adr_w      : NATURAL := 5;
    g_dat_w      : NATURAL := 8;
    g_nof_words  : NATURAL := 2**5;
    g_rd_latency : NATURAL := 1;  -- choose 1 or 2
    g_init_file  : STRING  := "UNUSED"
  );
  PORT
  (
    address_a : IN STD_LOGIC_VECTOR (g_adr_w-1 DOWNTO 0);
    address_b : IN STD_LOGIC_VECTOR (g_adr_w-1 DOWNTO 0);
    clk_a     : IN STD_LOGIC  := '1';
    clk_b     : IN STD_LOGIC ;
    data_a    : IN STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    data_b    : IN STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    wren_a    : IN STD_LOGIC  := '0';
    wren_b    : IN STD_LOGIC  := '0';
    q_a       : OUT STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    q_b       : OUT STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0)
  );
  END COMPONENT;
  
  COMPONENT ip_arria10_e3sge3_ram_cr_cw IS
  GENERIC (
    g_inferred   : BOOLEAN := FALSE;
    g_adr_w      : NATURAL := 5;
    g_dat_w      : NATURAL := 8;
    g_nof_words  : NATURAL := 2**5;
    g_rd_latency : NATURAL := 1;  -- choose 1 or 2
    g_init_file  : STRING  := "UNUSED"
  );
  PORT
  (
    data      : IN  STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    rdaddress : IN  STD_LOGIC_VECTOR (g_adr_w-1 DOWNTO 0);
    rdclk     : IN  STD_LOGIC ;
    wraddress : IN  STD_LOGIC_VECTOR (g_adr_w-1 DOWNTO 0);
    wrclk     : IN  STD_LOGIC  := '1';
    wren      : IN  STD_LOGIC  := '0';
    q         : OUT STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0)
  );
  END COMPONENT;
  
  COMPONENT ip_arria10_e3sge3_ram_r_w IS
  GENERIC (
    g_inferred   : BOOLEAN := FALSE;
    g_adr_w      : NATURAL := 5;
    g_dat_w      : NATURAL := 8;
    g_nof_words  : NATURAL := 2**5;
    g_rd_latency : NATURAL := 1;     -- choose 1 or 2
    g_init_file  : STRING  := "UNUSED"
  );
  PORT (
    clk         : IN STD_LOGIC  := '1';
    data        : IN STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0) := (OTHERS=>'0');
    rdaddress   : IN STD_LOGIC_VECTOR(g_adr_w-1 DOWNTO 0) := (OTHERS=>'0');
    wraddress   : IN STD_LOGIC_VECTOR(g_adr_w-1 DOWNTO 0) := (OTHERS=>'0');
    wren        : IN STD_LOGIC  := '0';
    q           : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0)
  );
  END COMPONENT;
  
END tech_memory_component_pkg;
