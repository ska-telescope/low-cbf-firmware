--Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2016.4 (lin64) Build 1756540 Mon Jan 23 19:11:19 MST 2017
--Date        : Mon Apr 24 17:01:06 2017
--Host        : dop350 running 64-bit openSUSE 13.2 (Harlequin) (x86_64)
--Command     : generate_target gmi_qsfp_axi_wrapper.bd
--Design      : gmi_qsfp_axi_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity gmi_qsfp_axi_wrapper is
  port (
    M03_AXI_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M03_AXI_arready : in STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_arvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M03_AXI_awready : in STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_awvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_bready : out STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M03_AXI_bvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_rready : out STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M03_AXI_rvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_wready : in STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M03_AXI_wvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M04_AXI_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M04_AXI_arready : in STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_arvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M04_AXI_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M04_AXI_awready : in STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_awvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_bready : out STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M04_AXI_bvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    M04_AXI_rready : out STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M04_AXI_rvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M04_AXI_wready : in STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M04_AXI_wvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    avm_address : out STD_LOGIC_VECTOR ( 31 downto 0 );
    avm_read : out STD_LOGIC;
    avm_readdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    avm_write : out STD_LOGIC;
    avm_writedata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    clock_rtl : in STD_LOGIC;
    led_axi_out : out STD_LOGIC_VECTOR ( 23 downto 0 );
    pll_locked : in STD_LOGIC;
    reg_axi_in : in STD_LOGIC_VECTOR ( 127 downto 0 );
    reg_axi_out : out STD_LOGIC_VECTOR ( 127 downto 0 );
    reset_rtl : in STD_LOGIC
  );
end gmi_qsfp_axi_wrapper;

architecture STRUCTURE of gmi_qsfp_axi_wrapper is
  component gmi_qsfp_axi is
  port (
    pll_locked : in STD_LOGIC;
    led_axi_out : out STD_LOGIC_VECTOR ( 23 downto 0 );
    reg_axi_out : out STD_LOGIC_VECTOR ( 127 downto 0 );
    reg_axi_in : in STD_LOGIC_VECTOR ( 127 downto 0 );
    avm_address : out STD_LOGIC_VECTOR ( 31 downto 0 );
    avm_read : out STD_LOGIC;
    avm_write : out STD_LOGIC;
    avm_writedata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    avm_readdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    clock_rtl : in STD_LOGIC;
    reset_rtl : in STD_LOGIC;
    M03_AXI_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M03_AXI_awvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_awready : in STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M03_AXI_wvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_wready : in STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M03_AXI_bvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_bready : out STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M03_AXI_arvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_arready : in STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M03_AXI_rvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_rready : out STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M04_AXI_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M04_AXI_awvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_awready : in STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M04_AXI_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M04_AXI_wvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_wready : in STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M04_AXI_bvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_bready : out STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M04_AXI_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M04_AXI_arvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_arready : in STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    M04_AXI_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M04_AXI_rvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_rready : out STD_LOGIC_VECTOR ( 0 to 0 )
  );
  end component gmi_qsfp_axi;
begin
gmi_qsfp_axi_i: component gmi_qsfp_axi
     port map (
      M03_AXI_araddr(31 downto 0) => M03_AXI_araddr(31 downto 0),
      M03_AXI_arprot(2 downto 0) => M03_AXI_arprot(2 downto 0),
      M03_AXI_arready(0) => M03_AXI_arready(0),
      M03_AXI_arvalid(0) => M03_AXI_arvalid(0),
      M03_AXI_awaddr(31 downto 0) => M03_AXI_awaddr(31 downto 0),
      M03_AXI_awprot(2 downto 0) => M03_AXI_awprot(2 downto 0),
      M03_AXI_awready(0) => M03_AXI_awready(0),
      M03_AXI_awvalid(0) => M03_AXI_awvalid(0),
      M03_AXI_bready(0) => M03_AXI_bready(0),
      M03_AXI_bresp(1 downto 0) => M03_AXI_bresp(1 downto 0),
      M03_AXI_bvalid(0) => M03_AXI_bvalid(0),
      M03_AXI_rdata(31 downto 0) => M03_AXI_rdata(31 downto 0),
      M03_AXI_rready(0) => M03_AXI_rready(0),
      M03_AXI_rresp(1 downto 0) => M03_AXI_rresp(1 downto 0),
      M03_AXI_rvalid(0) => M03_AXI_rvalid(0),
      M03_AXI_wdata(31 downto 0) => M03_AXI_wdata(31 downto 0),
      M03_AXI_wready(0) => M03_AXI_wready(0),
      M03_AXI_wstrb(3 downto 0) => M03_AXI_wstrb(3 downto 0),
      M03_AXI_wvalid(0) => M03_AXI_wvalid(0),
      M04_AXI_araddr(31 downto 0) => M04_AXI_araddr(31 downto 0),
      M04_AXI_arprot(2 downto 0) => M04_AXI_arprot(2 downto 0),
      M04_AXI_arready(0) => M04_AXI_arready(0),
      M04_AXI_arvalid(0) => M04_AXI_arvalid(0),
      M04_AXI_awaddr(31 downto 0) => M04_AXI_awaddr(31 downto 0),
      M04_AXI_awprot(2 downto 0) => M04_AXI_awprot(2 downto 0),
      M04_AXI_awready(0) => M04_AXI_awready(0),
      M04_AXI_awvalid(0) => M04_AXI_awvalid(0),
      M04_AXI_bready(0) => M04_AXI_bready(0),
      M04_AXI_bresp(1 downto 0) => M04_AXI_bresp(1 downto 0),
      M04_AXI_bvalid(0) => M04_AXI_bvalid(0),
      M04_AXI_rdata(31 downto 0) => M04_AXI_rdata(31 downto 0),
      M04_AXI_rready(0) => M04_AXI_rready(0),
      M04_AXI_rresp(1 downto 0) => M04_AXI_rresp(1 downto 0),
      M04_AXI_rvalid(0) => M04_AXI_rvalid(0),
      M04_AXI_wdata(31 downto 0) => M04_AXI_wdata(31 downto 0),
      M04_AXI_wready(0) => M04_AXI_wready(0),
      M04_AXI_wstrb(3 downto 0) => M04_AXI_wstrb(3 downto 0),
      M04_AXI_wvalid(0) => M04_AXI_wvalid(0),
      avm_address(31 downto 0) => avm_address(31 downto 0),
      avm_read => avm_read,
      avm_readdata(31 downto 0) => avm_readdata(31 downto 0),
      avm_write => avm_write,
      avm_writedata(31 downto 0) => avm_writedata(31 downto 0),
      clock_rtl => clock_rtl,
      led_axi_out(23 downto 0) => led_axi_out(23 downto 0),
      pll_locked => pll_locked,
      reg_axi_in(127 downto 0) => reg_axi_in(127 downto 0),
      reg_axi_out(127 downto 0) => reg_axi_out(127 downto 0),
      reset_rtl => reset_rtl
    );
end STRUCTURE;
