--Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2017.2 (lin64) Build 1909853 Thu Jun 15 18:39:10 MDT 2017
--Date        : Fri Jul 14 15:54:19 2017
--Host        : dop350 running 64-bit openSUSE 13.2 (Harlequin) (x86_64)
--Command     : generate_target lru_heater_axi_wrapper.bd
--Design      : lru_heater_axi_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity lru_heater_axi_wrapper is
  port (
    clock_rtl : in STD_LOGIC;
    heater_enable_axi_out : out STD_LOGIC_VECTOR ( 1407 downto 0 );
    heater_xor_axi_in : in STD_LOGIC_VECTOR ( 1407 downto 0 );
    led_axi_out : out STD_LOGIC_VECTOR ( 23 downto 0 );
    reset_rtl_0 : in STD_LOGIC
  );
end lru_heater_axi_wrapper;

architecture STRUCTURE of lru_heater_axi_wrapper is
  component lru_heater_axi is
  port (
    clock_rtl : in STD_LOGIC;
    reset_rtl_0 : in STD_LOGIC;
    heater_enable_axi_out : out STD_LOGIC_VECTOR ( 1407 downto 0 );
    heater_xor_axi_in : in STD_LOGIC_VECTOR ( 1407 downto 0 );
    led_axi_out : out STD_LOGIC_VECTOR ( 23 downto 0 )
  );
  end component lru_heater_axi;
begin
lru_heater_axi_i: component lru_heater_axi
     port map (
      clock_rtl => clock_rtl,
      heater_enable_axi_out(1407 downto 0) => heater_enable_axi_out(1407 downto 0),
      heater_xor_axi_in(1407 downto 0) => heater_xor_axi_in(1407 downto 0),
      led_axi_out(23 downto 0) => led_axi_out(23 downto 0),
      reset_rtl_0 => reset_rtl_0
    );
end STRUCTURE;
