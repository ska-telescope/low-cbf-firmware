--Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2016.2 (lin64) Build 1577090 Thu Jun  2 16:32:35 MDT 2016
--Date        : Fri Oct  7 22:54:03 2016
--Host        : dop350 running 64-bit openSUSE 13.2 (Harlequin) (x86_64)
--Command     : generate_target vcu108_heater_axi_wrapper.bd
--Design      : vcu108_heater_axi_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity vcu108_heater_axi_wrapper is
  port (
    clock_rtl : in STD_LOGIC;
    heater_enable_axi_out : out STD_LOGIC_VECTOR ( 511 downto 0 );
    heater_xor_axi_in : in STD_LOGIC_VECTOR ( 511 downto 0 );
    led_axi_out : out STD_LOGIC_VECTOR ( 3 downto 0 );
    reset_rtl : in STD_LOGIC
  );
end vcu108_heater_axi_wrapper;

architecture rtl of vcu108_heater_axi_wrapper is
  component vcu108_heater_axi is
  port (
    reset_rtl : in STD_LOGIC;
    clock_rtl : in STD_LOGIC;
    heater_enable_axi_out : out STD_LOGIC_VECTOR ( 511 downto 0 );
    heater_xor_axi_in : in STD_LOGIC_VECTOR ( 511 downto 0 );
    led_axi_out : out STD_LOGIC_VECTOR ( 3 downto 0 )
  );
  end component vcu108_heater_axi;
begin
vcu108_heater_axi_i: component vcu108_heater_axi
     port map (
      clock_rtl => clock_rtl,
      heater_enable_axi_out(511 downto 0) => heater_enable_axi_out(511 downto 0),
      heater_xor_axi_in(511 downto 0) => heater_xor_axi_in(511 downto 0),
      led_axi_out(3 downto 0) => led_axi_out(3 downto 0),
      reset_rtl => reset_rtl
    );
end rtl;
