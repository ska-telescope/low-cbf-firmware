--Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2017.2 (lin64) Build 1909853 Thu Jun 15 18:39:10 MDT 2017
--Date        : Wed Sep 13 17:24:43 2017
--Host        : giant running 64-bit Debian GNU/Linux 8.9 (jessie)
--Command     : generate_target axi_test_wrapper.bd
--Design      : axi_test_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity axi_test_wrapper is
  port (
    ACLK : in STD_LOGIC;
    ARESETN : in STD_LOGIC;     
    GPIO_IN_tri_i : in STD_LOGIC_VECTOR ( 31 downto 0 );
    GPIO_OUT_tri_o : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M02_AXI_LITE_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M02_AXI_LITE_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M02_AXI_LITE_arready : in STD_LOGIC;
    M02_AXI_LITE_arvalid : out STD_LOGIC;
    M02_AXI_LITE_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M02_AXI_LITE_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M02_AXI_LITE_awready : in STD_LOGIC;
    M02_AXI_LITE_awvalid : out STD_LOGIC;
    M02_AXI_LITE_bready : out STD_LOGIC;
    M02_AXI_LITE_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M02_AXI_LITE_bvalid : in STD_LOGIC;
    M02_AXI_LITE_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    M02_AXI_LITE_rready : out STD_LOGIC;
    M02_AXI_LITE_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M02_AXI_LITE_rvalid : in STD_LOGIC;
    M02_AXI_LITE_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M02_AXI_LITE_wready : in STD_LOGIC;
    M02_AXI_LITE_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M02_AXI_LITE_wvalid : out STD_LOGIC;
    M03_AXI_LITE_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_LITE_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M03_AXI_LITE_arready : in STD_LOGIC;
    M03_AXI_LITE_arvalid : out STD_LOGIC;
    M03_AXI_LITE_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_LITE_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M03_AXI_LITE_awready : in STD_LOGIC;
    M03_AXI_LITE_awvalid : out STD_LOGIC;
    M03_AXI_LITE_bready : out STD_LOGIC;
    M03_AXI_LITE_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M03_AXI_LITE_bvalid : in STD_LOGIC;
    M03_AXI_LITE_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_LITE_rready : out STD_LOGIC;
    M03_AXI_LITE_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M03_AXI_LITE_rvalid : in STD_LOGIC;
    M03_AXI_LITE_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_LITE_wready : in STD_LOGIC;
    M03_AXI_LITE_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M03_AXI_LITE_wvalid : out STD_LOGIC;
    S00_AXI_araddr : in STD_LOGIC_VECTOR ( 14 downto 0 );
    S00_AXI_arburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S00_AXI_arcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S00_AXI_arlen : in STD_LOGIC_VECTOR ( 7 downto 0 );
    S00_AXI_arlock : in STD_LOGIC;
    S00_AXI_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S00_AXI_arqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S00_AXI_arready : out STD_LOGIC;
    S00_AXI_arsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S00_AXI_arvalid : in STD_LOGIC;
    S00_AXI_awaddr : in STD_LOGIC_VECTOR ( 14 downto 0 );
    S00_AXI_awburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S00_AXI_awcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S00_AXI_awlen : in STD_LOGIC_VECTOR ( 7 downto 0 );
    S00_AXI_awlock : in STD_LOGIC;
    S00_AXI_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S00_AXI_awqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S00_AXI_awready : out STD_LOGIC;
    S00_AXI_awsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S00_AXI_awvalid : in STD_LOGIC;
    S00_AXI_bready : in STD_LOGIC;
    S00_AXI_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S00_AXI_bvalid : out STD_LOGIC;
    S00_AXI_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    S00_AXI_rlast : out STD_LOGIC;
    S00_AXI_rready : in STD_LOGIC;
    S00_AXI_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S00_AXI_rvalid : out STD_LOGIC;
    S00_AXI_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S00_AXI_wlast : in STD_LOGIC;
    S00_AXI_wready : out STD_LOGIC;
    S00_AXI_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S00_AXI_wvalid : in STD_LOGIC
  );
end axi_test_wrapper;

architecture STRUCTURE of axi_test_wrapper is
  component axi_test is
  port (
    ACLK : in STD_LOGIC;
    ARESETN : in STD_LOGIC;
    GPIO_IN_tri_i : in STD_LOGIC_VECTOR ( 31 downto 0 );
    GPIO_OUT_tri_o : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M02_AXI_LITE_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M02_AXI_LITE_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M02_AXI_LITE_arready : in STD_LOGIC;
    M02_AXI_LITE_arvalid : out STD_LOGIC;
    M02_AXI_LITE_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M02_AXI_LITE_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M02_AXI_LITE_awready : in STD_LOGIC;
    M02_AXI_LITE_awvalid : out STD_LOGIC;
    M02_AXI_LITE_bready : out STD_LOGIC;
    M02_AXI_LITE_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M02_AXI_LITE_bvalid : in STD_LOGIC;
    M02_AXI_LITE_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    M02_AXI_LITE_rready : out STD_LOGIC;
    M02_AXI_LITE_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M02_AXI_LITE_rvalid : in STD_LOGIC;
    M02_AXI_LITE_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M02_AXI_LITE_wready : in STD_LOGIC;
    M02_AXI_LITE_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M02_AXI_LITE_wvalid : out STD_LOGIC;
    M03_AXI_LITE_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_LITE_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M03_AXI_LITE_arready : in STD_LOGIC;
    M03_AXI_LITE_arvalid : out STD_LOGIC;
    M03_AXI_LITE_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_LITE_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M03_AXI_LITE_awready : in STD_LOGIC;
    M03_AXI_LITE_awvalid : out STD_LOGIC;
    M03_AXI_LITE_bready : out STD_LOGIC;
    M03_AXI_LITE_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M03_AXI_LITE_bvalid : in STD_LOGIC;
    M03_AXI_LITE_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_LITE_rready : out STD_LOGIC;
    M03_AXI_LITE_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M03_AXI_LITE_rvalid : in STD_LOGIC;
    M03_AXI_LITE_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_LITE_wready : in STD_LOGIC;
    M03_AXI_LITE_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M03_AXI_LITE_wvalid : out STD_LOGIC;
    S00_AXI_araddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S00_AXI_arburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S00_AXI_arcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S00_AXI_arlen : in STD_LOGIC_VECTOR ( 7 downto 0 );
    S00_AXI_arlock : in STD_LOGIC_VECTOR ( 0 to 0 );
    S00_AXI_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S00_AXI_arready : out STD_LOGIC_VECTOR ( 0 to 0 );
    S00_AXI_arsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S00_AXI_arvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    S00_AXI_awaddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S00_AXI_awburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S00_AXI_awcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S00_AXI_awlen : in STD_LOGIC_VECTOR ( 7 downto 0 );
    S00_AXI_awlock : in STD_LOGIC_VECTOR ( 0 to 0 );
    S00_AXI_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S00_AXI_awready : out STD_LOGIC_VECTOR ( 0 to 0 );
    S00_AXI_awsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S00_AXI_awvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    S00_AXI_bready : in STD_LOGIC_VECTOR ( 0 to 0 );
    S00_AXI_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S00_AXI_bvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    S00_AXI_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    S00_AXI_rlast : out STD_LOGIC_VECTOR ( 0 to 0 );
    S00_AXI_rready : in STD_LOGIC_VECTOR ( 0 to 0 );
    S00_AXI_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S00_AXI_rvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    S00_AXI_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S00_AXI_wlast : in STD_LOGIC_VECTOR ( 0 to 0 );
    S00_AXI_wready : out STD_LOGIC_VECTOR ( 0 to 0 );
    S00_AXI_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S00_AXI_wvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    S00_AXI_arqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S00_AXI_awqos : in STD_LOGIC_VECTOR ( 3 downto 0 )
  );
  end component axi_test;
begin
axi_test_i: component axi_test
     port map (
      ACLK => ACLK,
      ARESETN => ARESETN,
      
      GPIO_IN_tri_i  => GPIO_IN_tri_i,
      GPIO_OUT_tri_o => GPIO_OUT_tri_o,
      
      M02_AXI_LITE_araddr => M02_AXI_LITE_araddr,
      M02_AXI_LITE_arprot => M02_AXI_LITE_arprot,
      M02_AXI_LITE_arready => M02_AXI_LITE_arready,
      M02_AXI_LITE_arvalid => M02_AXI_LITE_arvalid,
      M02_AXI_LITE_awaddr => M02_AXI_LITE_awaddr,
      M02_AXI_LITE_awprot => M02_AXI_LITE_awprot,
      M02_AXI_LITE_awready => M02_AXI_LITE_awready,
      M02_AXI_LITE_awvalid => M02_AXI_LITE_awvalid,
      M02_AXI_LITE_bready => M02_AXI_LITE_bready,
      M02_AXI_LITE_bresp => M02_AXI_LITE_bresp,
      M02_AXI_LITE_bvalid => M02_AXI_LITE_bvalid,
      M02_AXI_LITE_rdata => M02_AXI_LITE_rdata,
      M02_AXI_LITE_rready => M02_AXI_LITE_rready,
      M02_AXI_LITE_rresp => M02_AXI_LITE_rresp,
      M02_AXI_LITE_rvalid => M02_AXI_LITE_rvalid,
      M02_AXI_LITE_wdata => M02_AXI_LITE_wdata,
      M02_AXI_LITE_wready => M02_AXI_LITE_wready,
      M02_AXI_LITE_wstrb => M02_AXI_LITE_wstrb,
      M02_AXI_LITE_wvalid => M02_AXI_LITE_wvalid,
      
      M03_AXI_LITE_araddr => M03_AXI_LITE_araddr,
      M03_AXI_LITE_arprot => M03_AXI_LITE_arprot,
      M03_AXI_LITE_arready => M03_AXI_LITE_arready,
      M03_AXI_LITE_arvalid => M03_AXI_LITE_arvalid,
      M03_AXI_LITE_awaddr => M03_AXI_LITE_awaddr,
      M03_AXI_LITE_awprot => M03_AXI_LITE_awprot,
      M03_AXI_LITE_awready => M03_AXI_LITE_awready,
      M03_AXI_LITE_awvalid => M03_AXI_LITE_awvalid,
      M03_AXI_LITE_bready => M03_AXI_LITE_bready,
      M03_AXI_LITE_bresp => M03_AXI_LITE_bresp,
      M03_AXI_LITE_bvalid => M03_AXI_LITE_bvalid,
      M03_AXI_LITE_rdata => M03_AXI_LITE_rdata,
      M03_AXI_LITE_rready => M03_AXI_LITE_rready,
      M03_AXI_LITE_rresp => M03_AXI_LITE_rresp,
      M03_AXI_LITE_rvalid => M03_AXI_LITE_rvalid,
      M03_AXI_LITE_wdata => M03_AXI_LITE_wdata,
      M03_AXI_LITE_wready => M03_AXI_LITE_wready,
      M03_AXI_LITE_wstrb => M03_AXI_LITE_wstrb,
      M03_AXI_LITE_wvalid => M03_AXI_LITE_wvalid,
      
      S00_AXI_araddr(14 downto 0) => S00_AXI_araddr(14 downto 0),
      S00_AXI_araddr(31 downto 15) => (others => '0'),
      S00_AXI_arburst(1 downto 0) => S00_AXI_arburst(1 downto 0),
      S00_AXI_arcache(3 downto 0) => S00_AXI_arcache(3 downto 0),
      S00_AXI_arlen(7 downto 0) => S00_AXI_arlen(7 downto 0),
      S00_AXI_arlock(0) => S00_AXI_arlock,
      S00_AXI_arprot(2 downto 0) => S00_AXI_arprot(2 downto 0),
      S00_AXI_arqos(3 downto 0) => S00_AXI_arqos(3 downto 0),
      S00_AXI_arready(0) => S00_AXI_arready,
      S00_AXI_arsize(2 downto 0) => S00_AXI_arsize(2 downto 0),
      S00_AXI_arvalid(0) => S00_AXI_arvalid,
      S00_AXI_awaddr(14 downto 0) => S00_AXI_awaddr(14 downto 0),
      S00_AXI_awaddr(31 downto 15) => (others => '0'),
      S00_AXI_awburst(1 downto 0) => S00_AXI_awburst(1 downto 0),
      S00_AXI_awcache(3 downto 0) => S00_AXI_awcache(3 downto 0),
      S00_AXI_awlen(7 downto 0) => S00_AXI_awlen(7 downto 0),
      S00_AXI_awlock(0) => S00_AXI_awlock,
      S00_AXI_awprot(2 downto 0) => S00_AXI_awprot(2 downto 0),
      S00_AXI_awqos(3 downto 0) => S00_AXI_awqos(3 downto 0),
      S00_AXI_awready(0) => S00_AXI_awready,
      S00_AXI_awsize(2 downto 0) => S00_AXI_awsize(2 downto 0),
      S00_AXI_awvalid(0) => S00_AXI_awvalid,
      S00_AXI_bready(0) => S00_AXI_bready,
      S00_AXI_bresp(1 downto 0) => S00_AXI_bresp(1 downto 0),
      S00_AXI_bvalid(0) => S00_AXI_bvalid,
      S00_AXI_rdata(31 downto 0) => S00_AXI_rdata(31 downto 0),
      S00_AXI_rlast(0) => S00_AXI_rlast,
      S00_AXI_rready(0) => S00_AXI_rready,
      S00_AXI_rresp(1 downto 0) => S00_AXI_rresp(1 downto 0),
      S00_AXI_rvalid(0) => S00_AXI_rvalid,
      S00_AXI_wdata(31 downto 0) => S00_AXI_wdata(31 downto 0),
      S00_AXI_wlast(0) => S00_AXI_wlast,
      S00_AXI_wready(0) => S00_AXI_wready,
      S00_AXI_wstrb(3 downto 0) => S00_AXI_wstrb(3 downto 0),
      S00_AXI_wvalid(0) => S00_AXI_wvalid
    );
end STRUCTURE;
