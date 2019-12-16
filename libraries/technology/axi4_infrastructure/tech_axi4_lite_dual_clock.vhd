LIBRARY IEEE, technology_lib, axi4_lib;
USE IEEE.std_logic_1164.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE work.tech_axi4_infrastructure_component_pkg.ALL;

ENTITY tech_axi4_lite_dual_clock IS
   GENERIC (
      g_technology   : t_technology := c_tech_select_default);
   PORT (
      m_clk          : IN STD_LOGIC;
      m_rst          : IN STD_LOGIC;
      m_axi_miso     : IN t_axi4_lite_miso;
      m_axi_mosi     : OUT t_axi4_lite_mosi;

      s_clk          : IN STD_LOGIC;
      s_rst          : IN STD_LOGIC;
      s_axi_miso     : OUT t_axi4_lite_miso;
      s_axi_mosi     : IN t_axi4_lite_mosi);
END tech_axi4_lite_dual_clock;

ARCHITECTURE wrapper OF tech_axi4_lite_dual_clock IS

   SIGNAL m_rst_n    : STD_LOGIC;
   SIGNAL s_rst_n    : STD_LOGIC;

BEGIN

   m_rst_n <= NOT m_rst;
   s_rst_n <= NOT s_rst;

   gen_ip: IF  tech_is_board(g_technology, c_tech_board_gemini_lru) OR tech_is_board(g_technology, c_tech_board_gemini_xh_lru) GENERATE

      u_axi_clock_converter : axi4lite_clock_converter
      PORT MAP (
         s_axi_aclk => s_clk,
         s_axi_aresetn => s_rst_n,
         s_axi_awaddr => s_axi_mosi.awaddr(31 DOWNTO 0),
         s_axi_awprot => s_axi_mosi.awprot,
         s_axi_awvalid => s_axi_mosi.awvalid,
         s_axi_awready => s_axi_miso.awready,
         s_axi_wdata => s_axi_mosi.wdata(31 DOWNTO 0),
         s_axi_wstrb => s_axi_mosi.wstrb(3 DOWNTO 0),
         s_axi_wvalid => s_axi_mosi.wvalid,
         s_axi_wready => s_axi_miso.wready,
         s_axi_bresp => s_axi_miso.bresp,
         s_axi_bvalid => s_axi_miso.bvalid,
         s_axi_bready => s_axi_mosi.bready,
         s_axi_araddr => s_axi_mosi.araddr(31 DOWNTO 0),
         s_axi_arprot => s_axi_mosi.arprot,
         s_axi_arvalid => s_axi_mosi.arvalid,
         s_axi_arready => s_axi_miso.arready,
         s_axi_rdata => s_axi_miso.rdata(31 DOWNTO 0),
         s_axi_rresp => s_axi_miso.rresp,
         s_axi_rvalid => s_axi_miso.rvalid,
         s_axi_rready => s_axi_mosi.rready,
         m_axi_aclk => m_clk,
         m_axi_aresetn => m_rst_n,
         m_axi_awaddr =>  m_axi_mosi.awaddr(31 DOWNTO 0),
         m_axi_awprot => m_axi_mosi.awprot,
         m_axi_awvalid => m_axi_mosi.awvalid,
         m_axi_awready => m_axi_miso.awready,
         m_axi_wdata => m_axi_mosi.wdata(31 DOWNTO 0),
         m_axi_wstrb => m_axi_mosi.wstrb(3 DOWNTO 0),
         m_axi_wvalid =>  m_axi_mosi.wvalid,
         m_axi_wready => m_axi_miso.wready,
         m_axi_bresp => m_axi_miso.bresp,
         m_axi_bvalid => m_axi_miso.bvalid,
         m_axi_bready => m_axi_mosi.bready,
         m_axi_araddr => m_axi_mosi.araddr(31 DOWNTO 0),
         m_axi_arprot => m_axi_mosi.arprot,
         m_axi_arvalid => m_axi_mosi.arvalid,
         m_axi_arready => m_axi_miso.arready,
         m_axi_rdata => m_axi_miso.rdata(31 DOWNTO 0),
         m_axi_rresp => m_axi_miso.rresp,
         m_axi_rvalid => m_axi_miso.rvalid,
         m_axi_rready => m_axi_mosi.rready);

   END GENERATE;

END wrapper;



