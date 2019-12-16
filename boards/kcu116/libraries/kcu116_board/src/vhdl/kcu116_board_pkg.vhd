-------------------------------------------------------------------------------
--
-- Copyright (C) 2009-2016
-- ASTRON (Netherlands Institute for Radio Astronomy) <http://www.astron.nl/>
-- JIVE (Joint Institute for VLBI in Europe) <http://www.jive.nl/>
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
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;

PACKAGE kcu116_board_pkg IS

  -- Board
  CONSTANT c_kcu116_board_nof_node             : NATURAL := 1;                     -- number of nodes on Board
  CONSTANT c_kcu116_board_nof_node_w           : NATURAL := 2;                     -- = ceil_log2(c_kcu116_board_nof_node)
  CONSTANT c_kcu116_board_nof_chip             : NATURAL := c_kcu116_board_nof_node; -- = 4
  CONSTANT c_kcu116_board_nof_chip_w           : NATURAL := 2;                     -- = ceil_log2(c_kcu116_board_nof_chip)
  CONSTANT c_kcu116_board_nof_ddr              : NATURAL := 2;                     -- each node has 2 DDR modules
  
  -- Clock frequencies
  CONSTANT c_kcu116_board_ext_clk_freq_200M    : NATURAL := 200 * 10**6;  -- external clock, SMA clock
  CONSTANT c_kcu116_board_eth_clk_freq_25M     : NATURAL :=  25 * 10**6;  -- fixed 25 MHz  ETH XO clock used as reference clock for the PLL
  CONSTANT c_kcu116_board_eth_clk_freq_125M    : NATURAL := 125 * 10**6;  -- fixed 125 MHz ETH XO clock used as direct clock for TSE
  CONSTANT c_kcu116_board_tse_clk_freq         : NATURAL := 125 * 10**6;  -- fixed 125 MHz TSE reference clock derived from ETH_clk by PLL
  CONSTANT c_kcu116_board_cal_clk_freq         : NATURAL :=  40 * 10**6;  -- fixed 40 MHz IO calibration clock derived from ETH_clk by PLL
  CONSTANT c_kcu116_board_mm_clk_freq_10M      : NATURAL :=  10 * 10**6;  -- clock when g_sim=TRUE
  CONSTANT c_kcu116_board_mm_clk_freq_25M      : NATURAL :=  25 * 10**6;  -- clock derived from ETH_clk by PLL
  CONSTANT c_kcu116_board_mm_clk_freq_50M      : NATURAL :=  50 * 10**6;  -- clock derived from ETH_clk by PLL
  CONSTANT c_kcu116_board_mm_clk_freq_100M     : NATURAL := 100 * 10**6;  -- clock derived from ETH_clk by PLL
  CONSTANT c_kcu116_board_mm_clk_freq_125M     : NATURAL := 125 * 10**6;  -- clock derived from ETH_clk by PLL
  CONSTANT c_kcu116_board_mm_clk_freq_156M     : NATURAL := 156 * 10**6;  -- clock derived from ETH_clk by PLL
  
  -- I2C
  CONSTANT c_kcu116_board_reg_sens_adr_w       : NATURAL := 3;  -- must match ceil_log2(c_mm_nof_dat) in kcu116_board_sens_reg.vhd

  CONSTANT c_i2c_peripheral_optics_l        : NATURAL := 0;
  CONSTANT c_i2c_peripheral_optics_r        : NATURAL := 1;
  CONSTANT c_i2c_peripheral_pmbus           : NATURAL := 2;

  -- ETH
  CONSTANT c_kcu116_board_nof_eth              : NATURAL := 1;  -- number of ETH channels per node
  
  -- CONSTANT RECORD DECLARATIONS ---------------------------------------------
  
  -- c_kcu116_board_signature_* : random signature words used for unused status bits to ensure that the software reads the correct interface address
  CONSTANT c_kcu116_board_signature_eth1g_slv   : STD_LOGIC_VECTOR(31 DOWNTO 0) := X"46e46cbc";
  CONSTANT c_kcu116_board_signature_eth10g_slv  : STD_LOGIC_VECTOR(31 DOWNTO 0) := X"2bd2e40a";

  CONSTANT c_kcu116_board_signature_eth1g       : INTEGER := TO_SINT(c_kcu116_board_signature_eth1g_slv  );
  CONSTANT c_kcu116_board_signature_eth10g      : INTEGER := TO_SINT(c_kcu116_board_signature_eth10g_slv );
  
  -- Transceivers
  TYPE t_c_kcu116_board_tr IS RECORD
    nof_bus                           : NATURAL;
    bus_w                             : NATURAL;
    i2c_w                             : NATURAL;
  END RECORD;

  CONSTANT c_kcu116_board_nof_gpioleds         : NATURAL := 8;


  --CONSTANT c_kcu116_board_tr_back              : t_c_kcu116_board_tr := (2, 24, 3); -- per node: 2 buses with 24 channels
  CONSTANT c_kcu116_board_tr_back              : t_c_kcu116_board_tr := (1, 24, 3); -- per node: 1 buses with 24 channels (testing)
  --CONSTANT c_kcu116_board_tr_back              : t_c_kcu116_board_tr := (2, 12, 3); -- per node: 2 buses with 24 channels (testing)
  --CONSTANT c_kcu116_board_tr_back              : t_c_kcu116_board_tr := (2, 4, 3); -- per node: 2 buses with 24 channels (testing)

  CONSTANT c_kcu116_board_tr_ring              : t_c_kcu116_board_tr := (2, 12, 0); -- per node: 2 buses with 12 channels
  --CONSTANT c_kcu116_board_tr_ring              : t_c_kcu116_board_tr := (2, 4, 0); -- per node: 2 buses with 12 channels (testing)

  CONSTANT c_kcu116_board_tr_qsfp              : t_c_kcu116_board_tr := (6, 4,  6); -- per node: 6 buses with 4 channels
  CONSTANT c_kcu116_board_tr_qsfp_nof_leds     : NATURAL := c_kcu116_board_tr_qsfp.nof_bus * 2; -- 2 leds per qsfp




  TYPE t_kcu116_board_qsfp_bus_2arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_kcu116_board_tr_qsfp.bus_w-1 DOWNTO 0);
  TYPE t_kcu116_board_ring_bus_2arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_kcu116_board_tr_ring.bus_w-1 DOWNTO 0);
  TYPE t_kcu116_board_back_bus_2arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_kcu116_board_tr_back.bus_w-1 DOWNTO 0);


  -- Auxiliary
  
  -- Test IO Interface
  TYPE t_c_kcu116_board_testio IS RECORD  
    tst_w                             : NATURAL;  -- = nof tst = 2; [tst_w-1 +tst_lo : tst_lo] = [5:4],
    led_w                             : NATURAL;  -- = nof led = 2; [led_w-1 +led_lo : led_lo] = [3:2],
    jmp_w                             : NATURAL;  -- = nof jmp = 2; [jmp_w-1 +jmp_lo : jmp_lo] = [1:0],
    tst_lo                            : NATURAL;  -- = 2;
    led_lo                            : NATURAL;  -- = 2;
    jmp_lo                            : NATURAL;  -- = 0;
  END RECORD;

  CONSTANT c_kcu116_board_testio               : t_c_kcu116_board_testio := (2, 2, 2, 2, 2, 0);
  CONSTANT c_kcu116_board_testio_led_green     : NATURAL := c_kcu116_board_testio.led_lo;
  CONSTANT c_kcu116_board_testio_led_red       : NATURAL := c_kcu116_board_testio.led_lo+1;

  CONSTANT c_kcu116_board_gpioled_green0       : NATURAL := 0;
  CONSTANT c_kcu116_board_gpioled_green1       : NATURAL := 1;
  
  TYPE t_c_kcu116_board_aux IS RECORD
    version_w                         : NATURAL;  -- = 2;
    id_w                              : NATURAL;  -- = 8;  -- 6+2 bits wide = total node ID for up to 64 UniBoards in a system and 4 nodes per board
    chip_id_w                         : NATURAL;  -- = 2;  -- board node ID for the 4 FPGA nodes on a UniBoard
    testio_w                          : NATURAL;  -- = 6;
    testio                            : t_c_kcu116_board_testio;
  END RECORD;
  
  CONSTANT c_kcu116_board_aux           : t_c_kcu116_board_aux := (2, 8, c_kcu116_board_nof_chip_w, 6, c_kcu116_board_testio);
  
  TYPE t_e_kcu116_board_node IS (e_any);

  TYPE t_kcu116_board_fw_version IS RECORD
    hi                                : NATURAL;  -- = 0..15
    lo                                : NATURAL;  -- = 0..15, firmware version is: hi.lo
  END RECORD;
  
  CONSTANT c_kcu116_board_fw_version    : t_kcu116_board_fw_version := (0, 0);
    
  -- SIGNAL RECORD DECLARATIONS -----------------------------------------------
  
  
  -- I2C, MDIO
  -- . If no I2C bus arbitration or clock stretching is needed then the SCL only needs to be output.
  -- . Can also be used for a PHY Management Data IO interface with serial clock MDC and serial data MDIO
  TYPE t_kcu116_board_i2c_inout IS RECORD  
    scl : STD_LOGIC;  -- serial clock
    sda : STD_LOGIC;  -- serial data
  END RECORD;
    
  -- System info
  TYPE t_c_kcu116_board_system_info IS RECORD
    version  : NATURAL;  -- UniBoard board HW version (2 bit value)
    id       : NATURAL;  -- UniBoard FPGA node id (8 bit value)
                         -- Derived ID info:
    bck_id   : NATURAL;  -- = id[7:2], ID part from back plane
    chip_id  : NATURAL;  -- = id[1:0], ID part from UniBoard
    node_id  : NATURAL;  -- = id[1:0], node ID: 0, 1, 2 or 3
    is_node2 : NATURAL;  -- 1 for Node 2, else 0.
  END RECORD;

  FUNCTION func_kcu116_board_system_info(VERSION : IN STD_LOGIC_VECTOR(c_kcu116_board_aux.version_w-1 DOWNTO 0);
                                       ID      : IN STD_LOGIC_VECTOR(c_kcu116_board_aux.id_w-1 DOWNTO 0)) RETURN t_c_kcu116_board_system_info;
                                
END kcu116_board_pkg;


PACKAGE BODY kcu116_board_pkg IS

  FUNCTION func_kcu116_board_system_info(VERSION : IN STD_LOGIC_VECTOR(c_kcu116_board_aux.version_w-1 DOWNTO 0);
                                       ID      : IN STD_LOGIC_VECTOR(c_kcu116_board_aux.id_w-1 DOWNTO 0)) RETURN t_c_kcu116_board_system_info IS
    VARIABLE v_system_info : t_c_kcu116_board_system_info;
  BEGIN
    v_system_info.version := TO_INTEGER(UNSIGNED(VERSION));
    v_system_info.id      := TO_INTEGER(UNSIGNED(ID));
    v_system_info.bck_id  := TO_INTEGER(UNSIGNED(ID(7 DOWNTO 2)));
    v_system_info.chip_id := TO_INTEGER(UNSIGNED(ID(1 DOWNTO 0)));
    v_system_info.node_id := TO_INTEGER(UNSIGNED(ID(1 DOWNTO 0)));
    IF UNSIGNED(ID(1 DOWNTO 0))=2 THEN v_system_info.is_node2 := 1; ELSE v_system_info.is_node2 := 0; END IF;
    RETURN v_system_info;
  END;
  
END kcu116_board_pkg;
