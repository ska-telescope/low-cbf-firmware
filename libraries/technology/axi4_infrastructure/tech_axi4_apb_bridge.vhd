LIBRARY IEEE, technology_lib, axi4_lib;
USE IEEE.std_logic_1164.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE work.tech_axi4_infrastructure_component_pkg.ALL;

ENTITY tech_axi4_apb_bridge IS
   GENERIC (
      g_technology   : t_technology := c_tech_select_default);
   PORT (
      clk               : IN STD_LOGIC;
      rst               : IN STD_LOGIC;
      axi4_lite_miso    : OUT t_axi4_lite_miso;
      axi4_lite_mosi    : IN t_axi4_lite_mosi;

      apb_paddr         : OUT STD_LOGIC_VECTOR(21 DOWNTO 0);
      apb_psel          : OUT STD_LOGIC;
      apb_penable       : OUT STD_LOGIC;
      apb_pwrite        : OUT STD_LOGIC;
      apb_pwdata        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      apb_pready        : IN STD_LOGIC;
      apb_prdata        : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      apb_pslverr       : IN STD_LOGIC);
END tech_axi4_apb_bridge;

ARCHITECTURE wrapper OF tech_axi4_apb_bridge IS

   SIGNAL rst_n    : STD_LOGIC;


BEGIN

   rst_n <= NOT rst;

   u_axi_apb_translate : axi_apb_translate
   PORT MAP (
      s_axi_aclk => clk, s_axi_aresetn => rst_n,

      s_axi_awaddr => axi4_lite_mosi.awaddr(21 DOWNTO 0), s_axi_awvalid => axi4_lite_mosi.awvalid,
      s_axi_awready => axi4_lite_miso.awready, s_axi_wdata => axi4_lite_mosi.wdata(31 DOWNTO 0),
      s_axi_wvalid => axi4_lite_mosi.wvalid, s_axi_wready => axi4_lite_miso.wready,
      s_axi_bresp => axi4_lite_miso.bresp, s_axi_bvalid => axi4_lite_miso.bvalid,
      s_axi_bready => axi4_lite_mosi.bready, s_axi_araddr => axi4_lite_mosi.araddr(21 DOWNTO 0),
      s_axi_arvalid => axi4_lite_mosi.arvalid, s_axi_arready => axi4_lite_miso.arready,
      s_axi_rdata => axi4_lite_miso.rdata(31 DOWNTO 0), s_axi_rresp => axi4_lite_miso.rresp,
      s_axi_rvalid => axi4_lite_miso.rvalid, s_axi_rready => axi4_lite_mosi.rready,

      m_apb_paddr => apb_paddr, m_apb_psel(0) => apb_psel, m_apb_penable => apb_penable,
      m_apb_pwrite => apb_pwrite, m_apb_pwdata => apb_pwdata, m_apb_pready(0) => apb_pready,
      m_apb_prdata => apb_prdata, m_apb_pslverr(0) => apb_pslverr);

END wrapper;



