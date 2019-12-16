--Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2016.4 (lin64) Build 1756540 Mon Jan 23 19:11:19 MST 2017
--Date        : Mon Feb 27 15:30:43 2017
--Host        : dop350 running 64-bit openSUSE 13.2 (Harlequin) (x86_64)
--Command     : generate_target gmi_heater_axi_wrapper.bd
--Design      : gmi_heater_axi_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity gmi_heater_axi_wrapper is
  port (
    clock_rtl : in STD_LOGIC;
    heater_reg_input : in STD_LOGIC_VECTOR ( 511 downto 0 );
    heater_reg_output : out STD_LOGIC_VECTOR ( 511 downto 0 );
    reset_rtl : in STD_LOGIC
  );
end gmi_heater_axi_wrapper;

architecture STRUCTURE of gmi_heater_axi_wrapper is
  component gmi_heater_axi is
  port (
    reset_rtl : in STD_LOGIC;
    clock_rtl : in STD_LOGIC;
    heater_reg_input : in STD_LOGIC_VECTOR ( 511 downto 0 );
    heater_reg_output : out STD_LOGIC_VECTOR ( 511 downto 0 )
  );
  end component gmi_heater_axi;
begin
gmi_heater_axi_i: component gmi_heater_axi
     port map (
      clock_rtl => clock_rtl,
      heater_reg_input(511 downto 0) => heater_reg_input(511 downto 0),
      heater_reg_output(511 downto 0) => heater_reg_output(511 downto 0),
      reset_rtl => reset_rtl
    );
end STRUCTURE;
