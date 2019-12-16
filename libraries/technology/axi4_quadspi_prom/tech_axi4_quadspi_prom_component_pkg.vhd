LIBRARY IEEE, technology_lib, common_lib;
USE IEEE.std_logic_1164.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;

PACKAGE tech_axi4_quadspi_prom_component_pkg IS

COMPONENT axi_quadspi_prom_dual
  PORT (
    ext_spi_clk : IN STD_LOGIC;
    s_axi4_aclk : IN STD_LOGIC;
    s_axi4_aresetn : IN STD_LOGIC;
    s_axi4_awaddr : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    s_axi4_awlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    s_axi4_awsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s_axi4_awburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi4_awlock : IN STD_LOGIC;
    s_axi4_awcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    s_axi4_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s_axi4_awvalid : IN STD_LOGIC;
    s_axi4_awready : OUT STD_LOGIC;
    s_axi4_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axi4_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    s_axi4_wlast : IN STD_LOGIC;
    s_axi4_wvalid : IN STD_LOGIC;
    s_axi4_wready : OUT STD_LOGIC;
    s_axi4_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi4_bvalid : OUT STD_LOGIC;
    s_axi4_bready : IN STD_LOGIC;
    s_axi4_araddr : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    s_axi4_arlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    s_axi4_arsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s_axi4_arburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi4_arlock : IN STD_LOGIC;
    s_axi4_arcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    s_axi4_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s_axi4_arvalid : IN STD_LOGIC;
    s_axi4_arready : OUT STD_LOGIC;
    s_axi4_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axi4_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi4_rlast : OUT STD_LOGIC;
    s_axi4_rvalid : OUT STD_LOGIC;
    s_axi4_rready : IN STD_LOGIC;
    eos: OUT STD_LOGIC;
    gsr : IN STD_LOGIC;
    gts : IN STD_LOGIC;
    keyclearb : IN STD_LOGIC;
    usrcclkts : IN STD_LOGIC;
    usrdoneo : IN STD_LOGIC;
    usrdonets : IN STD_LOGIC;
    io0_1_i : IN STD_LOGIC;
    io0_1_o : OUT STD_LOGIC;
    io0_1_t : OUT STD_LOGIC;
    io1_1_i : IN STD_LOGIC;
    io1_1_o : OUT STD_LOGIC;
    io1_1_t : OUT STD_LOGIC;
    io2_1_i : IN STD_LOGIC;
    io2_1_o : OUT STD_LOGIC;
    io2_1_t : OUT STD_LOGIC;
    io3_1_i : IN STD_LOGIC;
    io3_1_o : OUT STD_LOGIC;
    io3_1_t : OUT STD_LOGIC;
    ss_1_i : IN STD_LOGIC;
    ss_1_o : OUT STD_LOGIC;
    ss_1_t : OUT STD_LOGIC;
    ip2intc_irpt : OUT STD_LOGIC
  );
END COMPONENT;

COMPONENT axi_quadspi_prom_single
  PORT (
    ext_spi_clk : IN STD_LOGIC;
    s_axi4_aclk : IN STD_LOGIC;
    s_axi4_aresetn : IN STD_LOGIC;
    s_axi4_awaddr : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    s_axi4_awlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    s_axi4_awsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s_axi4_awburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi4_awlock : IN STD_LOGIC;
    s_axi4_awcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    s_axi4_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s_axi4_awvalid : IN STD_LOGIC;
    s_axi4_awready : OUT STD_LOGIC;
    s_axi4_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axi4_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    s_axi4_wlast : IN STD_LOGIC;
    s_axi4_wvalid : IN STD_LOGIC;
    s_axi4_wready : OUT STD_LOGIC;
    s_axi4_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi4_bvalid : OUT STD_LOGIC;
    s_axi4_bready : IN STD_LOGIC;
    s_axi4_araddr : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    s_axi4_arlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    s_axi4_arsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s_axi4_arburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi4_arlock : IN STD_LOGIC;
    s_axi4_arcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    s_axi4_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s_axi4_arvalid : IN STD_LOGIC;
    s_axi4_arready : OUT STD_LOGIC;
    s_axi4_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axi4_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi4_rlast : OUT STD_LOGIC;
    s_axi4_rvalid : OUT STD_LOGIC;
    s_axi4_rready : IN STD_LOGIC;
    cfgclk : OUT STD_LOGIC;
    cfgmclk : OUT STD_LOGIC;
    eos : OUT STD_LOGIC;
    preq : OUT STD_LOGIC;
    gsr : IN STD_LOGIC;
    gts : IN STD_LOGIC;
    keyclearb : IN STD_LOGIC;
    usrcclkts : IN STD_LOGIC;
    usrdoneo : IN STD_LOGIC;
    usrdonets : IN STD_LOGIC;
    ip2intc_irpt : OUT STD_LOGIC
  );
END COMPONENT;

END tech_axi4_quadspi_prom_component_pkg;

