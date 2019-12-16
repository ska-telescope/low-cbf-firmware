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

LIBRARY IEEE, technology_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE technology_lib.technology_pkg.ALL;

PACKAGE tech_fifo_component_pkg IS

  -----------------------------------------------------------------------------
  -- ip_stratixiv
  -----------------------------------------------------------------------------
  
  COMPONENT ip_stratixiv_fifo_sc IS
  GENERIC (
    g_use_eab    : STRING := "ON";
    g_dat_w      : NATURAL;
    g_nof_words  : NATURAL
  );
  PORT (
    aclr  : IN STD_LOGIC;
    clock : IN STD_LOGIC;
    data  : IN STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    rdreq : IN STD_LOGIC;
    wrreq : IN STD_LOGIC;
    empty : OUT STD_LOGIC;
    full  : OUT STD_LOGIC;
    q     : OUT STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    usedw : OUT STD_LOGIC_VECTOR (tech_ceil_log2(g_nof_words)-1 DOWNTO 0)
  );
  END COMPONENT;
  
  COMPONENT ip_stratixiv_fifo_dc IS
  GENERIC (
    g_dat_w      : NATURAL;
    g_nof_words  : NATURAL
  );
  PORT (
    aclr    : IN STD_LOGIC  := '0';
    data    : IN STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    rdclk   : IN STD_LOGIC;
    rdreq   : IN STD_LOGIC;
    wrclk   : IN STD_LOGIC;
    wrreq   : IN STD_LOGIC;
    q       : OUT STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    rdempty : OUT STD_LOGIC;
    rdusedw : OUT STD_LOGIC_VECTOR (tech_ceil_log2(g_nof_words)-1 DOWNTO 0);
    wrfull  : OUT STD_LOGIC;
    wrusedw : OUT STD_LOGIC_VECTOR (tech_ceil_log2(g_nof_words)-1 DOWNTO 0)
  );
  END COMPONENT;
  
  COMPONENT ip_stratixiv_fifo_dc_mixed_widths IS
  GENERIC (
    g_nof_words  : NATURAL;  -- FIFO size in nof wr_dat words
    g_wrdat_w    : NATURAL;
    g_rddat_w    : NATURAL
  );
  PORT (
    aclr    : IN STD_LOGIC  := '0';
    data    : IN STD_LOGIC_VECTOR (g_wrdat_w-1 DOWNTO 0);
    rdclk   : IN STD_LOGIC;
    rdreq   : IN STD_LOGIC;
    wrclk   : IN STD_LOGIC;
    wrreq   : IN STD_LOGIC;
    q       : OUT STD_LOGIC_VECTOR (g_rddat_w-1 DOWNTO 0);
    rdempty : OUT STD_LOGIC;
    rdusedw : OUT STD_LOGIC_VECTOR (tech_ceil_log2(g_nof_words*g_wrdat_w/g_rddat_w)-1 DOWNTO 0);
    wrfull  : OUT STD_LOGIC;
    wrusedw : OUT STD_LOGIC_VECTOR (tech_ceil_log2(g_nof_words)-1 DOWNTO 0)
  );
  END COMPONENT;
  
  
  -----------------------------------------------------------------------------
  -- ip_arria10
  -----------------------------------------------------------------------------
  
  COMPONENT ip_arria10_fifo_sc IS
  GENERIC (
    g_use_eab   : STRING := "ON";
    g_dat_w     : NATURAL := 20;
    g_nof_words : NATURAL := 1024
  );
  PORT (
    aclr    : IN STD_LOGIC ;
    clock   : IN STD_LOGIC ;
    data    : IN STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    rdreq   : IN STD_LOGIC ;
    wrreq   : IN STD_LOGIC ;
    empty   : OUT STD_LOGIC ;
    full    : OUT STD_LOGIC ;
    q       : OUT STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0) ;
    usedw   : OUT STD_LOGIC_VECTOR (tech_ceil_log2(g_nof_words)-1 DOWNTO 0)
  );
  END COMPONENT;

  COMPONENT ip_arria10_fifo_dc IS
  GENERIC (
    g_use_eab   : STRING := "ON";
    g_dat_w     : NATURAL := 20;
    g_nof_words : NATURAL := 1024
  );
  PORT (
    aclr    : IN STD_LOGIC  := '0';
    data    : IN STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    rdclk   : IN STD_LOGIC ;
    rdreq   : IN STD_LOGIC ;
    wrclk   : IN STD_LOGIC ;
    wrreq   : IN STD_LOGIC ;
    q       : OUT STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    rdempty : OUT STD_LOGIC ;
    rdusedw : OUT STD_LOGIC_VECTOR (tech_ceil_log2(g_nof_words)-1 DOWNTO 0);
    wrfull  : OUT STD_LOGIC ;
    wrusedw : OUT STD_LOGIC_VECTOR (tech_ceil_log2(g_nof_words)-1 DOWNTO 0)
  );
  END COMPONENT;
  
  COMPONENT ip_arria10_fifo_dc_mixed_widths IS
  GENERIC (
    g_nof_words : NATURAL := 1024;  -- FIFO size in nof wr_dat words
    g_wrdat_w   : NATURAL := 20;
    g_rddat_w   : NATURAL := 10
  );
  PORT (
    aclr    : IN STD_LOGIC  := '0';
    data    : IN STD_LOGIC_VECTOR (g_wrdat_w-1 DOWNTO 0);
    rdclk   : IN STD_LOGIC ;
    rdreq   : IN STD_LOGIC ;
    wrclk   : IN STD_LOGIC ;
    wrreq   : IN STD_LOGIC ;
    q       : OUT STD_LOGIC_VECTOR (g_rddat_w-1 DOWNTO 0);
    rdempty : OUT STD_LOGIC ;
    rdusedw : OUT STD_LOGIC_VECTOR (tech_ceil_log2(g_nof_words*g_wrdat_w/g_rddat_w)-1 DOWNTO 0);
    wrfull  : OUT STD_LOGIC ;
    wrusedw : OUT STD_LOGIC_VECTOR (tech_ceil_log2(g_nof_words)-1 DOWNTO 0)
  );
  END COMPONENT;

  -----------------------------------------------------------------------------
  -- ip_arria10_e3sge3
  -----------------------------------------------------------------------------
  
  COMPONENT ip_arria10_e3sge3_fifo_sc IS
  GENERIC (
    g_use_eab   : STRING := "ON";
    g_dat_w     : NATURAL := 20;
    g_nof_words : NATURAL := 1024
  );
  PORT (
    aclr    : IN STD_LOGIC ;
    clock   : IN STD_LOGIC ;
    data    : IN STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    rdreq   : IN STD_LOGIC ;
    wrreq   : IN STD_LOGIC ;
    empty   : OUT STD_LOGIC ;
    full    : OUT STD_LOGIC ;
    q       : OUT STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0) ;
    usedw   : OUT STD_LOGIC_VECTOR (tech_ceil_log2(g_nof_words)-1 DOWNTO 0)
  );
  END COMPONENT;

  COMPONENT ip_arria10_e3sge3_fifo_dc IS
  GENERIC (
    g_use_eab   : STRING := "ON";
    g_dat_w     : NATURAL := 20;
    g_nof_words : NATURAL := 1024
  );
  PORT (
    aclr    : IN STD_LOGIC  := '0';
    data    : IN STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    rdclk   : IN STD_LOGIC ;
    rdreq   : IN STD_LOGIC ;
    wrclk   : IN STD_LOGIC ;
    wrreq   : IN STD_LOGIC ;
    q       : OUT STD_LOGIC_VECTOR (g_dat_w-1 DOWNTO 0);
    rdempty : OUT STD_LOGIC ;
    rdusedw : OUT STD_LOGIC_VECTOR (tech_ceil_log2(g_nof_words)-1 DOWNTO 0);
    wrfull  : OUT STD_LOGIC ;
    wrusedw : OUT STD_LOGIC_VECTOR (tech_ceil_log2(g_nof_words)-1 DOWNTO 0)
  );
  END COMPONENT;
  
  COMPONENT ip_arria10_e3sge3_fifo_dc_mixed_widths IS
  GENERIC (
    g_nof_words : NATURAL := 1024;  -- FIFO size in nof wr_dat words
    g_wrdat_w   : NATURAL := 20;
    g_rddat_w   : NATURAL := 10
  );
  PORT (
    aclr    : IN STD_LOGIC  := '0';
    data    : IN STD_LOGIC_VECTOR (g_wrdat_w-1 DOWNTO 0);
    rdclk   : IN STD_LOGIC ;
    rdreq   : IN STD_LOGIC ;
    wrclk   : IN STD_LOGIC ;
    wrreq   : IN STD_LOGIC ;
    q       : OUT STD_LOGIC_VECTOR (g_rddat_w-1 DOWNTO 0);
    rdempty : OUT STD_LOGIC ;
    rdusedw : OUT STD_LOGIC_VECTOR (tech_ceil_log2(g_nof_words*g_wrdat_w/g_rddat_w)-1 DOWNTO 0);
    wrfull  : OUT STD_LOGIC ;
    wrusedw : OUT STD_LOGIC_VECTOR (tech_ceil_log2(g_nof_words)-1 DOWNTO 0)
  );
  END COMPONENT;
  

END tech_fifo_component_pkg;
