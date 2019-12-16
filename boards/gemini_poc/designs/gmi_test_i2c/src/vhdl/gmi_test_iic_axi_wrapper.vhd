--Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2016.4 (lin64) Build 1756540 Mon Jan 23 19:11:19 MST 2017
--Date        : Thu Apr  6 16:32:02 2017
--Host        : dop350 running 64-bit openSUSE 13.2 (Harlequin) (x86_64)
--Command     : generate_target gmi_test_iic_axi_wrapper.bd
--Design      : gmi_test_iic_axi_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity gmi_test_iic_axi_wrapper is
  port (
    avm_address : out STD_LOGIC_VECTOR ( 31 downto 0 );
    avm_read : out STD_LOGIC;
    avm_readdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    avm_write : out STD_LOGIC;
    avm_writedata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    clock_rtl : in STD_LOGIC;
    led_axi_out : out STD_LOGIC_VECTOR ( 23 downto 0 );
    pll_locked : in STD_LOGIC;
    reset_rtl : in STD_LOGIC
  );
end gmi_test_iic_axi_wrapper;

architecture STRUCTURE of gmi_test_iic_axi_wrapper is
  component gmi_test_iic_axi is
  port (
    clock_rtl : in STD_LOGIC;
    reset_rtl : in STD_LOGIC;
    led_axi_out : out STD_LOGIC_VECTOR ( 23 downto 0 );
    pll_locked : in STD_LOGIC;
    avm_readdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    avm_address : out STD_LOGIC_VECTOR ( 31 downto 0 );
    avm_read : out STD_LOGIC;
    avm_write : out STD_LOGIC;
    avm_writedata : out STD_LOGIC_VECTOR ( 31 downto 0 )
  );
  end component gmi_test_iic_axi;
begin
gmi_test_iic_axi_i: component gmi_test_iic_axi
     port map (
      avm_address(31 downto 0) => avm_address(31 downto 0),
      avm_read => avm_read,
      avm_readdata(31 downto 0) => avm_readdata(31 downto 0),
      avm_write => avm_write,
      avm_writedata(31 downto 0) => avm_writedata(31 downto 0),
      clock_rtl => clock_rtl,
      led_axi_out(23 downto 0) => led_axi_out(23 downto 0),
      pll_locked => pll_locked,
      reset_rtl => reset_rtl
    );
end STRUCTURE;
