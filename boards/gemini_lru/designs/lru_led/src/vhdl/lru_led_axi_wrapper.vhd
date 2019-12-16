--Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2017.2 (lin64) Build 1909853 Thu Jun 15 18:39:10 MDT 2017
--Date        : Wed Jul  5 16:28:16 2017
--Host        : dop350 running 64-bit openSUSE 13.2 (Harlequin) (x86_64)
--Command     : generate_target lru_led_axi_wrapper.bd
--Design      : lru_led_axi_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity lru_led_axi_wrapper is
  port (
    AXI4_LITE_MASTER_araddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_MASTER_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    AXI4_LITE_MASTER_arready : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_arvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_awaddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_MASTER_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    AXI4_LITE_MASTER_awready : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_awvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_bready : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI4_LITE_MASTER_bvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_MASTER_rready : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI4_LITE_MASTER_rvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_MASTER_wready : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    AXI4_LITE_MASTER_wvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_arready : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_arvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_awready : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_awvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_bready : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_bvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_rready : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_rvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_wready : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_wvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_arready : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_arvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_awready : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_awvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_bready : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_bvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_rready : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_rvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_wready : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_wvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_arready : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_arvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_awready : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_awvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_bready : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_bvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_rready : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_rvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_wready : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_wvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    mm_clk : in STD_LOGIC;
    mm_rst_n : in STD_LOGIC;
    ph_rst_n : in STD_LOGIC
  );
end lru_led_axi_wrapper;

architecture STRUCTURE of lru_led_axi_wrapper is
  component lru_led_axi is
  port (
    mm_clk : in STD_LOGIC;
    mm_rst_n : in STD_LOGIC;
    ph_rst_n : in STD_LOGIC;
    AXI4_LITE_SLAVE_ROM_INFO_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_awvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_awready : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_wvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_wready : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_bvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_bready : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_arvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_arready : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_rvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_rready : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_awvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_awready : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_wvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_wready : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_bvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_bready : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_arvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_arready : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_rvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_rready : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_awvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_awready : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_wvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_wready : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_bvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_bready : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_arvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_arready : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_rvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_rready : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_awaddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_MASTER_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    AXI4_LITE_MASTER_awvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_awready : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_MASTER_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    AXI4_LITE_MASTER_wvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_wready : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI4_LITE_MASTER_bvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_bready : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_araddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_MASTER_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    AXI4_LITE_MASTER_arvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_arready : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_MASTER_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI4_LITE_MASTER_rvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_rready : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
  end component lru_led_axi;
begin
lru_led_axi_i: component lru_led_axi
     port map (
      AXI4_LITE_MASTER_araddr(31 downto 0) => AXI4_LITE_MASTER_araddr(31 downto 0),
      AXI4_LITE_MASTER_arprot(2 downto 0) => AXI4_LITE_MASTER_arprot(2 downto 0),
      AXI4_LITE_MASTER_arready(0) => AXI4_LITE_MASTER_arready(0),
      AXI4_LITE_MASTER_arvalid(0) => AXI4_LITE_MASTER_arvalid(0),
      AXI4_LITE_MASTER_awaddr(31 downto 0) => AXI4_LITE_MASTER_awaddr(31 downto 0),
      AXI4_LITE_MASTER_awprot(2 downto 0) => AXI4_LITE_MASTER_awprot(2 downto 0),
      AXI4_LITE_MASTER_awready(0) => AXI4_LITE_MASTER_awready(0),
      AXI4_LITE_MASTER_awvalid(0) => AXI4_LITE_MASTER_awvalid(0),
      AXI4_LITE_MASTER_bready(0) => AXI4_LITE_MASTER_bready(0),
      AXI4_LITE_MASTER_bresp(1 downto 0) => AXI4_LITE_MASTER_bresp(1 downto 0),
      AXI4_LITE_MASTER_bvalid(0) => AXI4_LITE_MASTER_bvalid(0),
      AXI4_LITE_MASTER_rdata(31 downto 0) => AXI4_LITE_MASTER_rdata(31 downto 0),
      AXI4_LITE_MASTER_rready(0) => AXI4_LITE_MASTER_rready(0),
      AXI4_LITE_MASTER_rresp(1 downto 0) => AXI4_LITE_MASTER_rresp(1 downto 0),
      AXI4_LITE_MASTER_rvalid(0) => AXI4_LITE_MASTER_rvalid(0),
      AXI4_LITE_MASTER_wdata(31 downto 0) => AXI4_LITE_MASTER_wdata(31 downto 0),
      AXI4_LITE_MASTER_wready(0) => AXI4_LITE_MASTER_wready(0),
      AXI4_LITE_MASTER_wstrb(3 downto 0) => AXI4_LITE_MASTER_wstrb(3 downto 0),
      AXI4_LITE_MASTER_wvalid(0) => AXI4_LITE_MASTER_wvalid(0),
      AXI4_LITE_SLAVE_REG_INFO_araddr(31 downto 0) => AXI4_LITE_SLAVE_REG_INFO_araddr(31 downto 0),
      AXI4_LITE_SLAVE_REG_INFO_arprot(2 downto 0) => AXI4_LITE_SLAVE_REG_INFO_arprot(2 downto 0),
      AXI4_LITE_SLAVE_REG_INFO_arready(0) => AXI4_LITE_SLAVE_REG_INFO_arready(0),
      AXI4_LITE_SLAVE_REG_INFO_arvalid(0) => AXI4_LITE_SLAVE_REG_INFO_arvalid(0),
      AXI4_LITE_SLAVE_REG_INFO_awaddr(31 downto 0) => AXI4_LITE_SLAVE_REG_INFO_awaddr(31 downto 0),
      AXI4_LITE_SLAVE_REG_INFO_awprot(2 downto 0) => AXI4_LITE_SLAVE_REG_INFO_awprot(2 downto 0),
      AXI4_LITE_SLAVE_REG_INFO_awready(0) => AXI4_LITE_SLAVE_REG_INFO_awready(0),
      AXI4_LITE_SLAVE_REG_INFO_awvalid(0) => AXI4_LITE_SLAVE_REG_INFO_awvalid(0),
      AXI4_LITE_SLAVE_REG_INFO_bready(0) => AXI4_LITE_SLAVE_REG_INFO_bready(0),
      AXI4_LITE_SLAVE_REG_INFO_bresp(1 downto 0) => AXI4_LITE_SLAVE_REG_INFO_bresp(1 downto 0),
      AXI4_LITE_SLAVE_REG_INFO_bvalid(0) => AXI4_LITE_SLAVE_REG_INFO_bvalid(0),
      AXI4_LITE_SLAVE_REG_INFO_rdata(31 downto 0) => AXI4_LITE_SLAVE_REG_INFO_rdata(31 downto 0),
      AXI4_LITE_SLAVE_REG_INFO_rready(0) => AXI4_LITE_SLAVE_REG_INFO_rready(0),
      AXI4_LITE_SLAVE_REG_INFO_rresp(1 downto 0) => AXI4_LITE_SLAVE_REG_INFO_rresp(1 downto 0),
      AXI4_LITE_SLAVE_REG_INFO_rvalid(0) => AXI4_LITE_SLAVE_REG_INFO_rvalid(0),
      AXI4_LITE_SLAVE_REG_INFO_wdata(31 downto 0) => AXI4_LITE_SLAVE_REG_INFO_wdata(31 downto 0),
      AXI4_LITE_SLAVE_REG_INFO_wready(0) => AXI4_LITE_SLAVE_REG_INFO_wready(0),
      AXI4_LITE_SLAVE_REG_INFO_wstrb(3 downto 0) => AXI4_LITE_SLAVE_REG_INFO_wstrb(3 downto 0),
      AXI4_LITE_SLAVE_REG_INFO_wvalid(0) => AXI4_LITE_SLAVE_REG_INFO_wvalid(0),
      AXI4_LITE_SLAVE_REG_LED_araddr(31 downto 0) => AXI4_LITE_SLAVE_REG_LED_araddr(31 downto 0),
      AXI4_LITE_SLAVE_REG_LED_arprot(2 downto 0) => AXI4_LITE_SLAVE_REG_LED_arprot(2 downto 0),
      AXI4_LITE_SLAVE_REG_LED_arready(0) => AXI4_LITE_SLAVE_REG_LED_arready(0),
      AXI4_LITE_SLAVE_REG_LED_arvalid(0) => AXI4_LITE_SLAVE_REG_LED_arvalid(0),
      AXI4_LITE_SLAVE_REG_LED_awaddr(31 downto 0) => AXI4_LITE_SLAVE_REG_LED_awaddr(31 downto 0),
      AXI4_LITE_SLAVE_REG_LED_awprot(2 downto 0) => AXI4_LITE_SLAVE_REG_LED_awprot(2 downto 0),
      AXI4_LITE_SLAVE_REG_LED_awready(0) => AXI4_LITE_SLAVE_REG_LED_awready(0),
      AXI4_LITE_SLAVE_REG_LED_awvalid(0) => AXI4_LITE_SLAVE_REG_LED_awvalid(0),
      AXI4_LITE_SLAVE_REG_LED_bready(0) => AXI4_LITE_SLAVE_REG_LED_bready(0),
      AXI4_LITE_SLAVE_REG_LED_bresp(1 downto 0) => AXI4_LITE_SLAVE_REG_LED_bresp(1 downto 0),
      AXI4_LITE_SLAVE_REG_LED_bvalid(0) => AXI4_LITE_SLAVE_REG_LED_bvalid(0),
      AXI4_LITE_SLAVE_REG_LED_rdata(31 downto 0) => AXI4_LITE_SLAVE_REG_LED_rdata(31 downto 0),
      AXI4_LITE_SLAVE_REG_LED_rready(0) => AXI4_LITE_SLAVE_REG_LED_rready(0),
      AXI4_LITE_SLAVE_REG_LED_rresp(1 downto 0) => AXI4_LITE_SLAVE_REG_LED_rresp(1 downto 0),
      AXI4_LITE_SLAVE_REG_LED_rvalid(0) => AXI4_LITE_SLAVE_REG_LED_rvalid(0),
      AXI4_LITE_SLAVE_REG_LED_wdata(31 downto 0) => AXI4_LITE_SLAVE_REG_LED_wdata(31 downto 0),
      AXI4_LITE_SLAVE_REG_LED_wready(0) => AXI4_LITE_SLAVE_REG_LED_wready(0),
      AXI4_LITE_SLAVE_REG_LED_wstrb(3 downto 0) => AXI4_LITE_SLAVE_REG_LED_wstrb(3 downto 0),
      AXI4_LITE_SLAVE_REG_LED_wvalid(0) => AXI4_LITE_SLAVE_REG_LED_wvalid(0),
      AXI4_LITE_SLAVE_ROM_INFO_araddr(31 downto 0) => AXI4_LITE_SLAVE_ROM_INFO_araddr(31 downto 0),
      AXI4_LITE_SLAVE_ROM_INFO_arprot(2 downto 0) => AXI4_LITE_SLAVE_ROM_INFO_arprot(2 downto 0),
      AXI4_LITE_SLAVE_ROM_INFO_arready(0) => AXI4_LITE_SLAVE_ROM_INFO_arready(0),
      AXI4_LITE_SLAVE_ROM_INFO_arvalid(0) => AXI4_LITE_SLAVE_ROM_INFO_arvalid(0),
      AXI4_LITE_SLAVE_ROM_INFO_awaddr(31 downto 0) => AXI4_LITE_SLAVE_ROM_INFO_awaddr(31 downto 0),
      AXI4_LITE_SLAVE_ROM_INFO_awprot(2 downto 0) => AXI4_LITE_SLAVE_ROM_INFO_awprot(2 downto 0),
      AXI4_LITE_SLAVE_ROM_INFO_awready(0) => AXI4_LITE_SLAVE_ROM_INFO_awready(0),
      AXI4_LITE_SLAVE_ROM_INFO_awvalid(0) => AXI4_LITE_SLAVE_ROM_INFO_awvalid(0),
      AXI4_LITE_SLAVE_ROM_INFO_bready(0) => AXI4_LITE_SLAVE_ROM_INFO_bready(0),
      AXI4_LITE_SLAVE_ROM_INFO_bresp(1 downto 0) => AXI4_LITE_SLAVE_ROM_INFO_bresp(1 downto 0),
      AXI4_LITE_SLAVE_ROM_INFO_bvalid(0) => AXI4_LITE_SLAVE_ROM_INFO_bvalid(0),
      AXI4_LITE_SLAVE_ROM_INFO_rdata(31 downto 0) => AXI4_LITE_SLAVE_ROM_INFO_rdata(31 downto 0),
      AXI4_LITE_SLAVE_ROM_INFO_rready(0) => AXI4_LITE_SLAVE_ROM_INFO_rready(0),
      AXI4_LITE_SLAVE_ROM_INFO_rresp(1 downto 0) => AXI4_LITE_SLAVE_ROM_INFO_rresp(1 downto 0),
      AXI4_LITE_SLAVE_ROM_INFO_rvalid(0) => AXI4_LITE_SLAVE_ROM_INFO_rvalid(0),
      AXI4_LITE_SLAVE_ROM_INFO_wdata(31 downto 0) => AXI4_LITE_SLAVE_ROM_INFO_wdata(31 downto 0),
      AXI4_LITE_SLAVE_ROM_INFO_wready(0) => AXI4_LITE_SLAVE_ROM_INFO_wready(0),
      AXI4_LITE_SLAVE_ROM_INFO_wstrb(3 downto 0) => AXI4_LITE_SLAVE_ROM_INFO_wstrb(3 downto 0),
      AXI4_LITE_SLAVE_ROM_INFO_wvalid(0) => AXI4_LITE_SLAVE_ROM_INFO_wvalid(0),
      mm_clk => mm_clk,
      mm_rst_n => mm_rst_n,
      ph_rst_n => ph_rst_n
    );
end STRUCTURE;
