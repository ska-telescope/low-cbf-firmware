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

PACKAGE tech_pll_component_pkg IS

  -- Choose multiple of 16 fs to avoid truncation by simulator
  CONSTANT tech_pll_clk_644_period      : TIME := 1551520 fs;                       -- = 1.551520 ns ~= 644.53125 MHz
  CONSTANT tech_pll_clk_156_period      : TIME := (tech_pll_clk_644_period*33)/8;   -- = 6.400020 ns ~= 156.25 MHz
  CONSTANT tech_pll_clk_312_period      : TIME := (tech_pll_clk_644_period*33)/16;  -- = 3.200010 ns ~= 312.5 MHz

  -- Reference clock offset: +100 ppm ~= 155 fs ~= 9*16 = 144 fs
  CONSTANT tech_pll_clk_644_10ppm       : TIME := 16 fs;

  -----------------------------------------------------------------------------
  -- ip_stratixiv
  -----------------------------------------------------------------------------
  
  COMPONENT ip_stratixiv_pll_clk200 IS
  GENERIC (
    g_operation_mode   : STRING := "NORMAL";   -- or "SOURCE_SYNCHRONOUS" --> requires PLL_COMPENSATE assignment to an input pin to compensate for (stratixiv)
    g_clk0_phase_shift : STRING := "0";
    g_clk1_phase_shift : STRING := "0"
  );
  PORT
  (
    areset    : IN STD_LOGIC  := '0';
    inclk0    : IN STD_LOGIC  := '0';
    c0    : OUT STD_LOGIC ;
    c1    : OUT STD_LOGIC ;
    c2    : OUT STD_LOGIC ;
    locked    : OUT STD_LOGIC 
  );
  END COMPONENT;
  
  COMPONENT ip_stratixiv_pll_clk200_p6 IS
  GENERIC (
    g_pll_type         : STRING := "Left_Right"; -- "AUTO", "Left_Right", or "Top_Bottom". Set "Left_Right" to direct using PLL_L3 close to CLK pin on UniBoard, because with "AUTO" still a top/bottom PLL may get inferred.
    g_operation_mode   : STRING := "NORMAL";     -- or "SOURCE_SYNCHRONOUS" --> requires PLL_COMPENSATE assignment to an input pin to compensate for (stratixiv)
    g_clk0_phase_shift : STRING := "0";          -- = 0 degrees for clk 200 MHz
    g_clk1_used        : STRING := "PORT_USED";  -- or "PORT_UNUSED"
    g_clk2_used        : STRING := "PORT_USED";  -- or "PORT_UNUSED"
    g_clk3_used        : STRING := "PORT_USED";  -- or "PORT_UNUSED"
    g_clk4_used        : STRING := "PORT_USED";  -- or "PORT_UNUSED"
    g_clk5_used        : STRING := "PORT_USED";  -- or "PORT_UNUSED"
    g_clk6_used        : STRING := "PORT_USED";  -- or "PORT_UNUSED"
    g_clk1_divide_by   : NATURAL := 32;          -- = clk 200/32 MHz 
    g_clk2_divide_by   : NATURAL := 32;          -- = clk 200/32 MHz 
    g_clk3_divide_by   : NATURAL := 32;          -- = clk 200/32 MHz 
    g_clk4_divide_by   : NATURAL := 32;          -- = clk 200/32 MHz 
    g_clk5_divide_by   : NATURAL := 32;          -- = clk 200/32 MHz 
    g_clk6_divide_by   : NATURAL := 32;          -- = clk 200/32 MHz 
    g_clk1_phase_shift : STRING := "0";          -- = 0     
    g_clk2_phase_shift : STRING := "156";        -- = 011.25
    g_clk3_phase_shift : STRING := "313";        -- = 022.5 
    g_clk4_phase_shift : STRING := "469";        -- = 033.75
    g_clk5_phase_shift : STRING := "625";        -- = 045   
                                -- "781"         -- = 056.25
    g_clk6_phase_shift : STRING := "938"         -- = 067.5 
                                -- "1094"        -- = 078.75
  );
  PORT
  (
    areset    : IN STD_LOGIC  := '0';
    inclk0    : IN STD_LOGIC  := '0';
    c0    : OUT STD_LOGIC ;
    c1    : OUT STD_LOGIC ;
    c2    : OUT STD_LOGIC ;
    c3    : OUT STD_LOGIC ;
    c4    : OUT STD_LOGIC ;
    c5    : OUT STD_LOGIC ;
    c6    : OUT STD_LOGIC ;
    locked    : OUT STD_LOGIC 
  );
  END COMPONENT;
  
  COMPONENT ip_stratixiv_pll_clk25 IS
  PORT
  (
    areset : IN STD_LOGIC  := '0';
    inclk0 : IN STD_LOGIC  := '0';
    c0     : OUT STD_LOGIC ;
    c1     : OUT STD_LOGIC ;
    c2     : OUT STD_LOGIC ;
    c3     : OUT STD_LOGIC ;
    locked : OUT STD_LOGIC
  );
  END COMPONENT;

  -----------------------------------------------------------------------------
  -- ip_arria10
  -----------------------------------------------------------------------------
  
  COMPONENT ip_arria10_pll_xgmii_mac_clocks IS
  PORT (
    pll_refclk0   : in  std_logic := '0'; --   pll_refclk0.clk
    pll_powerdown : in  std_logic := '0'; -- pll_powerdown.pll_powerdown
    pll_locked    : out std_logic;        --    pll_locked.pll_locked
    outclk0       : out std_logic;        --       outclk0.clk
    pll_cal_busy  : out std_logic;        --  pll_cal_busy.pll_cal_busy
    outclk1       : out std_logic         --       outclk1.clk
  );
  END COMPONENT;

  COMPONENT ip_arria10_pll_clk200 IS
  PORT
  (
    rst       : IN STD_LOGIC  := '0';
    refclk    : IN STD_LOGIC  := '0';
    outclk_0  : OUT STD_LOGIC ;
    outclk_1  : OUT STD_LOGIC ;
    outclk_2  : OUT STD_LOGIC ;
    locked    : OUT STD_LOGIC 
  );
  END COMPONENT;

  COMPONENT ip_arria10_pll_clk25 IS
  PORT
  (
    rst       : IN STD_LOGIC  := '0';
    refclk    : IN STD_LOGIC  := '0';
    outclk_0  : OUT STD_LOGIC ;
    outclk_1  : OUT STD_LOGIC ;
    outclk_2  : OUT STD_LOGIC ;
    outclk_3  : OUT STD_LOGIC ;
    locked    : OUT STD_LOGIC 
  );
  END COMPONENT;

  COMPONENT ip_arria10_pll_clk125 IS
  PORT
  (
    rst       : IN STD_LOGIC  := '0';
    refclk    : IN STD_LOGIC  := '0';
    outclk_0  : OUT STD_LOGIC ;
    outclk_1  : OUT STD_LOGIC ;
    outclk_2  : OUT STD_LOGIC ;
    outclk_3  : OUT STD_LOGIC ;
    locked    : OUT STD_LOGIC 
  );
  END COMPONENT;

--  COMPONENT ip_arria10_pll_clk200mm IS
--  PORT
--  (
--    rst       : IN STD_LOGIC  := '0';
--    refclk    : IN STD_LOGIC  := '0';
--    outclk_0  : OUT STD_LOGIC ;
--    outclk_1  : OUT STD_LOGIC ;
--    outclk_2  : OUT STD_LOGIC ;
--    outclk_3  : OUT STD_LOGIC ;
--    locked    : OUT STD_LOGIC 
--  );
--  END COMPONENT;


  -----------------------------------------------------------------------------
  -- ip_arria10_e3sge3
  -----------------------------------------------------------------------------
  
  COMPONENT ip_arria10_e3sge3_pll_xgmii_mac_clocks IS
  PORT (
    pll_refclk0   : in  std_logic := '0'; --   pll_refclk0.clk
    pll_powerdown : in  std_logic := '0'; -- pll_powerdown.pll_powerdown
    pll_locked    : out std_logic;        --    pll_locked.pll_locked
    outclk0       : out std_logic;        --       outclk0.clk
    pll_cal_busy  : out std_logic;        --  pll_cal_busy.pll_cal_busy
    outclk1       : out std_logic         --       outclk1.clk
  );
  END COMPONENT;

  COMPONENT ip_arria10_e3sge3_pll_clk200 IS
  PORT
  (
    rst       : IN STD_LOGIC  := '0';
    refclk    : IN STD_LOGIC  := '0';
    outclk_0  : OUT STD_LOGIC ;
    outclk_1  : OUT STD_LOGIC ;
    outclk_2  : OUT STD_LOGIC ;
    locked    : OUT STD_LOGIC 
  );
  END COMPONENT;

  COMPONENT ip_arria10_e3sge3_pll_clk25 IS
  PORT
  (
    rst       : IN STD_LOGIC  := '0';
    refclk    : IN STD_LOGIC  := '0';
    outclk_0  : OUT STD_LOGIC ;
    outclk_1  : OUT STD_LOGIC ;
    outclk_2  : OUT STD_LOGIC ;
    outclk_3  : OUT STD_LOGIC ;
    locked    : OUT STD_LOGIC 
  );
  END COMPONENT;

  COMPONENT ip_arria10_e3sge3_pll_clk125 IS
  PORT
  (
    rst       : IN STD_LOGIC  := '0';
    refclk    : IN STD_LOGIC  := '0';
    outclk_0  : OUT STD_LOGIC ;
    outclk_1  : OUT STD_LOGIC ;
    outclk_2  : OUT STD_LOGIC ;
    outclk_3  : OUT STD_LOGIC ;
    locked    : OUT STD_LOGIC 
  );
  END COMPONENT;

  COMPONENT ip_xcvu095_mmcm_clk125 IS
  PORT
  (
    clk_in1           : in     std_logic;
    -- Clock out ports
    clk_out1          : out    std_logic;
    clk_out2          : out    std_logic;
    clk_out3          : out    std_logic;
    -- Status and control signals
    reset             : in     std_logic;
    locked            : out    std_logic
  );
  END COMPONENT;

  COMPONENT ip_xcvu190_mmcm_clk125 IS
  PORT
  (
    clk_in1           : in     std_logic;
    -- Clock out ports
    clk_out1          : out    std_logic;
    clk_out2          : out    std_logic;
    clk_out3          : out    std_logic;
    -- Status and control signals
    reset             : in     std_logic;
    locked            : out    std_logic
  );
  END COMPONENT;

  COMPONENT ip_xcvu9p_mmcm_clk125 IS
  PORT
  (
    clk_in1           : in     std_logic;
    -- Clock out ports
    clk_out1          : out    std_logic;
    clk_out2          : out    std_logic;
    clk_out3          : out    std_logic;
    --clk_out4          : out    std_logic;
    --clk_out5          : out    std_logic;
    -- Status and control signals
    reset             : in     std_logic;
    locked            : out    std_logic
  );
  END COMPONENT;
  
  COMPONENT ip_xcvu9p_mmcm_clk125d IS
  PORT
  (
    clk_in1_p         : in     std_logic;
    clk_in1_n         : in     std_logic;
    -- Clock out ports
    clk_out1          : out    std_logic;
    clk_out2          : out    std_logic;
    -- Status and control signals
    reset             : in     std_logic;
    locked            : out    std_logic
  );
  END COMPONENT;

  COMPONENT ip_xcku040_mmcm_clk125 IS
  PORT
  (
    clk_in1           : in     std_logic;
    -- Clock out ports
    clk_out1          : out    std_logic;
    clk_out2          : out    std_logic;
    clk_out3          : out    std_logic;
    --clk_out4          : out    std_logic;
    --clk_out5          : out    std_logic;
    -- Status and control signals
    reset             : in     std_logic;
    locked            : out    std_logic
  );
  END COMPONENT;

END tech_pll_component_pkg;
