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
USE IEEE.STD_LOGIC_1164.ALL;
USE common_lib.common_pkg.ALL;
USE IEEE.NUMERIC_STD.ALL;     

PACKAGE common_interface_layers_pkg IS

  ------------------------------------------------------------------------------
  -- XAUI
  ------------------------------------------------------------------------------

  CONSTANT c_nof_xaui_lanes    : NATURAL := 4;

  TYPE t_xaui_arr IS ARRAY(INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_nof_xaui_lanes-1 DOWNTO 0);

  ------------------------------------------------------------------------------
  -- XGMII
  ------------------------------------------------------------------------------
  
  CONSTANT c_xgmii_data_w      : NATURAL := 64;
  CONSTANT c_xgmii_nof_lanes   : NATURAL := 8;

  CONSTANT c_xgmii_ctrl_w      : NATURAL := c_xgmii_nof_lanes;
  CONSTANT c_xgmii_lane_data_w : NATURAL := c_xgmii_data_w / c_xgmii_nof_lanes;
  CONSTANT c_xgmii_w           : NATURAL := c_xgmii_data_w + c_xgmii_ctrl_w;

  CONSTANT c_xgmii_d_idle      : STD_LOGIC_VECTOR(c_xgmii_data_w-1 DOWNTO 0) := x"0707070707070707";
  CONSTANT c_xgmii_d_start     : STD_LOGIC_VECTOR(c_xgmii_data_w-1 DOWNTO 0) := x"00000000000000FB";
  CONSTANT c_xgmii_d_term      : STD_LOGIC_VECTOR(c_xgmii_data_w-1 DOWNTO 0) := x"07070707FD000000";

  CONSTANT c_xgmii_c_init      : STD_LOGIC_VECTOR(c_xgmii_nof_lanes-1 DOWNTO 0) := x"11"; -- During (re)initialization
  CONSTANT c_xgmii_c_idle      : STD_LOGIC_VECTOR(c_xgmii_nof_lanes-1 DOWNTO 0) := x"FF"; 
  CONSTANT c_xgmii_c_data      : STD_LOGIC_VECTOR(c_xgmii_nof_lanes-1 DOWNTO 0) := x"00";
  CONSTANT c_xgmii_c_start     : STD_LOGIC_VECTOR(c_xgmii_nof_lanes-1 DOWNTO 0) := x"01"; --b'00000001' as byte 0 contains START word FB
  CONSTANT c_xgmii_c_term      : STD_LOGIC_VECTOR(c_xgmii_nof_lanes-1 DOWNTO 0) := x"F8"; --b'11111000' as byte 3 contains TERMINATE word FD, bytes 7..4 are IDLE.

  FUNCTION func_xgmii_dc( data : IN STD_LOGIC_VECTOR(c_xgmii_data_w-1 DOWNTO 0); ctrl : IN STD_LOGIC_VECTOR(c_xgmii_nof_lanes-1 DOWNTO 0)) RETURN STD_LOGIC_VECTOR;
  FUNCTION func_xgmii_d( data_ctrl: IN STD_LOGIC_VECTOR(c_xgmii_w-1 DOWNTO 0)) RETURN STD_LOGIC_VECTOR;
  FUNCTION func_xgmii_c( data_ctrl: IN STD_LOGIC_VECTOR(c_xgmii_w-1 DOWNTO 0)) RETURN STD_LOGIC_VECTOR;

  TYPE t_xgmii_dc_arr IS ARRAY(INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_xgmii_w-1 DOWNTO 0);
  TYPE t_xgmii_d_arr IS ARRAY(INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_xgmii_data_w-1 DOWNTO 0);
  TYPE t_xgmii_c_arr IS ARRAY(INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_xgmii_nof_lanes-1 DOWNTO 0);

 END common_interface_layers_pkg;

PACKAGE BODY common_interface_layers_pkg IS 

  -- Refer to the 10GBASE-R PHY IP Core section of the Altera Transceiver PHY IP Core User Guide
  -- (November 2011) page 3-11: SDR XGMII Tx Interface for the proper mapping.

  -- Combine separate data and control bits into one XGMII SLV.
  FUNCTION func_xgmii_dc( data : IN STD_LOGIC_VECTOR(c_xgmii_data_w-1 DOWNTO 0); ctrl : IN STD_LOGIC_VECTOR(c_xgmii_nof_lanes-1 DOWNTO 0)) RETURN STD_LOGIC_VECTOR IS  
    VARIABLE data_ctrl_out : STD_LOGIC_VECTOR(c_xgmii_w-1 DOWNTO 0);
  BEGIN
    -- Lane 0:
    data_ctrl_out( 7 DOWNTO  0) := data( 7 DOWNTO 0); 
    data_ctrl_out( 8)           := ctrl(0);
    -- Lane 1:
    data_ctrl_out(16 DOWNTO  9) := data(15 DOWNTO 8);
    data_ctrl_out(17)           := ctrl(1);
    -- Lane 2:
    data_ctrl_out(25 DOWNTO 18) := data(23 DOWNTO 16); 
    data_ctrl_out(26)           := ctrl(2);
    -- Lane 3:
    data_ctrl_out(34 DOWNTO 27) := data(31 DOWNTO 24);
    data_ctrl_out(35)           := ctrl(3);
    -- Lane 4:
    data_ctrl_out(43 DOWNTO 36) := data(39 DOWNTO 32); 
    data_ctrl_out(44)           := ctrl(4);
    -- Lane 5:
    data_ctrl_out(52 DOWNTO 45) := data(47 DOWNTO 40);
    data_ctrl_out(53)           := ctrl(5);
    -- Lane 6:
    data_ctrl_out(61 DOWNTO 54) := data(55 DOWNTO 48); 
    data_ctrl_out(62)           := ctrl(6);
    -- Lane 7:
    data_ctrl_out(70 DOWNTO 63) := data(63 DOWNTO 56);
    data_ctrl_out(71)           := ctrl(7);

    RETURN data_ctrl_out;
  END;

  -- Extract the data bits from combined data+ctrl XGMII SLV.
  FUNCTION func_xgmii_d( data_ctrl: IN STD_LOGIC_VECTOR(c_xgmii_w-1 DOWNTO 0)) RETURN STD_LOGIC_VECTOR IS
    VARIABLE data_out : STD_LOGIC_VECTOR(c_xgmii_data_w-1 DOWNTO 0);
  BEGIN
    -- Lane 0:
    data_out( 7 DOWNTO 0)  := data_ctrl( 7 DOWNTO  0);
    -- Lane 1:
    data_out(15 DOWNTO 8)  := data_ctrl(16 DOWNTO  9); 
    -- Lane 2:
    data_out(23 DOWNTO 16) := data_ctrl(25 DOWNTO 18); 
    -- Lane 3:
    data_out(31 DOWNTO 24) := data_ctrl(34 DOWNTO 27); 
    -- Lane 4:
    data_out(39 DOWNTO 32) := data_ctrl(43 DOWNTO 36);
    -- Lane 5: 
    data_out(47 DOWNTO 40) := data_ctrl(52 DOWNTO 45); 
    -- Lane 6:
    data_out(55 DOWNTO 48) := data_ctrl(61 DOWNTO 54); 
    -- Lane 7:
    data_out(63 DOWNTO 56) := data_ctrl(70 DOWNTO 63); 

    RETURN data_out;
  END;

  -- Extract the control bits from combined data+ctrl XGMII SLV.
  FUNCTION func_xgmii_c( data_ctrl: IN STD_LOGIC_VECTOR(c_xgmii_w-1 DOWNTO 0)) RETURN STD_LOGIC_VECTOR IS
    VARIABLE ctrl_out : STD_LOGIC_VECTOR(c_xgmii_nof_lanes-1 DOWNTO 0);
  BEGIN
    -- Lane 0:
    ctrl_out(0) := data_ctrl( 8);   
    -- Lane 1:  
    ctrl_out(1) := data_ctrl(17);            
    -- Lane 2:  
    ctrl_out(2) := data_ctrl(26); 
    -- Lane 3:           
    ctrl_out(3) := data_ctrl(35);            
    -- Lane 4:  
    ctrl_out(4) := data_ctrl(44);
    -- Lane 5:            
    ctrl_out(5) := data_ctrl(53);            
    -- Lane 6:   
    ctrl_out(6) := data_ctrl(62);
    -- Lane 7:            
    ctrl_out(7) := data_ctrl(71);

    RETURN ctrl_out;
  END;
  
END common_interface_layers_pkg;

