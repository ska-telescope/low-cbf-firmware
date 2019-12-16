LIBRARY IEEE, technology_lib, common_lib, axi4_lib, UNISIM;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE axi4_lib.axi4_full_pkg.ALL;
USE work.tech_axi4_quadspi_prom_component_pkg.ALL;
USE UNISIM.vcomponents.all;

ENTITY tech_axi4_quadspi_prom IS
   GENERIC (
      g_technology         : t_technology);

   PORT (
      axi_clk              : IN STD_LOGIC;
      spi_clk              : IN STD_LOGIC;
      axi_rst              : IN STD_LOGIC;

      spi_interrupt        : OUT STD_LOGIC;

      spi_mosi             : IN t_axi4_full_mosi;
      spi_miso             : OUT t_axi4_full_miso;

      -- Second SPI PROM Interface
      spi_i                : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      spi_o                : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      spi_t                : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);

      spi_ss_o             : OUT STD_LOGIC;
      spi_ss_t             : OUT STD_LOGIC;
      spi_ss_i             : IN STD_LOGIC;

      end_of_startup       : OUT STD_LOGIC);
END tech_axi4_quadspi_prom;

ARCHITECTURE str OF tech_axi4_quadspi_prom IS

   SIGNAL axi_not_reset    : STD_LOGIC;
   SIGNAL gnd              : STD_LOGIC_VECTOR(299 DOWNTO 0);
   SIGNAL vcc              : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

   axi_not_reset <= not(axi_rst);
   gnd <= (OTHERS => '0');
   vcc <= (OTHERS => '1');

   gen_dual_ip: IF tech_is_board(g_technology, c_tech_board_kcu105) OR tech_is_board(g_technology, c_tech_board_gemini_lru) GENERATE

      qspi_prom_core: axi_quadspi_prom_dual
      PORT MAP (
         s_axi4_aclk => axi_clk, s_axi4_aresetn => axi_not_reset,
         s_axi4_awaddr => spi_mosi.awaddr(23 DOWNTO 0),
         s_axi4_awlen => spi_mosi.awlen, s_axi4_awsize => spi_mosi.awsize,
         s_axi4_awburst => spi_mosi.awburst, s_axi4_awlock => spi_mosi.awlock,
         s_axi4_awcache => spi_mosi.awcache, s_axi4_awprot => spi_mosi.awprot,
         s_axi4_awvalid => spi_mosi.awvalid, s_axi4_awready => spi_miso.awready,
         s_axi4_wdata => spi_mosi.wdata(31 DOWNTO 0), s_axi4_wstrb => spi_mosi.wstrb(3 DOWNTO 0),
         s_axi4_wlast => spi_mosi.wlast, s_axi4_wvalid => spi_mosi.wvalid,
         s_axi4_wready => spi_miso.wready, s_axi4_bresp => spi_miso.bresp,
         s_axi4_bvalid => spi_miso.bvalid, s_axi4_bready => spi_mosi.bready,
         s_axi4_araddr => spi_mosi.araddr(23 DOWNTO 0), s_axi4_arlen => spi_mosi.arlen(7 DOWNTO 0),
         s_axi4_arsize => spi_mosi.arsize, s_axi4_arburst => spi_mosi.arburst,
         s_axi4_arlock => spi_mosi.arlock, s_axi4_arcache => spi_mosi.arcache,
         s_axi4_arprot => spi_mosi.arprot, s_axi4_arvalid => spi_mosi.arvalid,
         s_axi4_arready => spi_miso.arready, s_axi4_rdata => spi_miso.rdata(31 DOWNTO 0),
         s_axi4_rresp => spi_miso.rresp, s_axi4_rlast => spi_miso.rlast,
         s_axi4_rvalid => spi_miso.rvalid, s_axi4_rready => spi_mosi.rready,
         ext_spi_clk => spi_clk,  ip2intc_irpt => spi_interrupt,
         io0_1_i => spi_i(0), io0_1_o => spi_o(0), io0_1_t => spi_t(0),
         io1_1_i => spi_i(1), io1_1_o => spi_o(1), io1_1_t => spi_t(1),
         io2_1_i => spi_i(2), io2_1_o => spi_o(2), io2_1_t => spi_t(2),
         io3_1_i => spi_i(3), io3_1_o => spi_o(3), io3_1_t => spi_t(3),
         ss_1_i => spi_ss_i, ss_1_o => spi_ss_o, ss_1_t => spi_ss_t,
         gsr => gnd(0), gts => gnd(0), keyclearb => vcc(0), usrcclkts => gnd(0),
         usrdoneo => vcc(0), usrdonets => gnd(0), eos => end_of_startup);
   END GENERATE;

   gen_single_ip: IF tech_is_board(g_technology, c_tech_board_gemini_xh_lru) GENERATE

      qspi_prom_core: axi_quadspi_prom_single
      PORT MAP (
         s_axi4_aclk => axi_clk, s_axi4_aresetn => axi_not_reset,
         s_axi4_awaddr => spi_mosi.awaddr(23 DOWNTO 0),
         s_axi4_awlen => spi_mosi.awlen, s_axi4_awsize => spi_mosi.awsize,
         s_axi4_awburst => spi_mosi.awburst, s_axi4_awlock => spi_mosi.awlock,
         s_axi4_awcache => spi_mosi.awcache, s_axi4_awprot => spi_mosi.awprot,
         s_axi4_awvalid => spi_mosi.awvalid, s_axi4_awready => spi_miso.awready,
         s_axi4_wdata => spi_mosi.wdata(31 DOWNTO 0), s_axi4_wstrb => spi_mosi.wstrb(3 DOWNTO 0),
         s_axi4_wlast => spi_mosi.wlast, s_axi4_wvalid => spi_mosi.wvalid,
         s_axi4_wready => spi_miso.wready, s_axi4_bresp => spi_miso.bresp,
         s_axi4_bvalid => spi_miso.bvalid, s_axi4_bready => spi_mosi.bready,
         s_axi4_araddr => spi_mosi.araddr(23 DOWNTO 0), s_axi4_arlen => spi_mosi.arlen(7 DOWNTO 0),
         s_axi4_arsize => spi_mosi.arsize, s_axi4_arburst => spi_mosi.arburst,
         s_axi4_arlock => spi_mosi.arlock, s_axi4_arcache => spi_mosi.arcache,
         s_axi4_arprot => spi_mosi.arprot, s_axi4_arvalid => spi_mosi.arvalid,
         s_axi4_arready => spi_miso.arready, s_axi4_rdata => spi_miso.rdata(31 DOWNTO 0),
         s_axi4_rresp => spi_miso.rresp, s_axi4_rlast => spi_miso.rlast,
         s_axi4_rvalid => spi_miso.rvalid, s_axi4_rready => spi_mosi.rready,
         ext_spi_clk => spi_clk,  ip2intc_irpt => spi_interrupt,
         gsr => gnd(0), gts => gnd(0), keyclearb => vcc(0), usrcclkts => gnd(0),
         usrdoneo => vcc(0), usrdonets => gnd(0), eos => end_of_startup);
   END GENERATE;

END str;





