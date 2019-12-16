LIBRARY IEEE, technology_lib, axi4_lib, tech_axi4_infrastructure_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE axi4_lib.axi4_full_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE work.tech_hbm_pkg.ALL;
USE work.tech_hbm_component_pkg.ALL;

ENTITY tech_hbm IS
   GENERIC (
      g_technology         : t_technology;
      g_device             : t_hbm_configuration);
   PORT (
      hbm_ref_clk          : IN STD_LOGIC;                           -- HBM clock memory 125 MHz

      apb_clk              : IN STD_LOGIC;                           -- 100MHz or less clock for HBM internal registers
      axi_clk              : IN STD_LOGIC;                           -- MACE register clock for HBM internal registers
      hbm_data_clk         : IN STD_LOGIC_VECTOR(0 TO 15);           -- AXI port clocks, upto 450MHz

      hbm_data_rst         : IN STD_LOGIC_VECTOR(0 TO 15);
      axi_rst              : IN STD_LOGIC;
      apb_rst              : IN STD_LOGIC;

      -- Control Interface
      axi_lite_mosi        : IN t_axi4_lite_mosi;
      axi_lite_miso        : OUT t_axi4_lite_miso;

      temperature_failure  : OUT STD_LOGIC;

      -- HBM ports
      hbm_data_miso        : OUT t_axi4_full_miso_arr(0 TO 15);
      hbm_data_mosi        : IN t_axi4_full_mosi_arr(0 TO 15));
END tech_hbm;

ARCHITECTURE str OF tech_hbm IS

   SIGNAL hbm_data_rst_n    : STD_LOGIC_VECTOR(0 TO 15);
   SIGNAL apb_rst_n     : STD_LOGIC;

   SIGNAL apb_mosi      : t_axi4_lite_mosi;
   SIGNAL apb_miso      : t_axi4_lite_miso;

   SIGNAL apb_prdata    : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL apb_pwdata    : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL apb_paddr     : STD_LOGIC_VECTOR(21 DOWNTO 0);
   SIGNAL apb_pslverr   : STD_LOGIC;
   SIGNAL apb_penable   : STD_LOGIC;
   SIGNAL apb_pwrite    : STD_LOGIC;
   SIGNAL apb_psel      : STD_LOGIC;
   SIGNAL apb_pready    : STD_LOGIC;

BEGIN

   hbm_data_rst_n <= NOT hbm_data_rst;
   apb_rst_n <= NOT apb_rst;


   axi4_clock_cross: ENTITY tech_axi4_infrastructure_lib.tech_axi4_lite_dual_clock
   GENERIC MAP (
      g_technology   => g_technology)
   PORT MAP (
      s_clk          => axi_clk,
      s_rst          => axi_rst,
      s_axi_miso     => axi_lite_miso,
      s_axi_mosi     => axi_lite_mosi,
      m_clk          => apb_clk,
      m_rst          => apb_rst,
      m_axi_miso     => apb_miso,
      m_axi_mosi     => apb_mosi);

   apb_bridge: ENTITY tech_axi4_infrastructure_lib.tech_axi4_apb_bridge
   GENERIC MAP (
      g_technology      => g_technology)
   PORT MAP (
      clk               => apb_clk,
      rst               => apb_rst,
      axi4_lite_miso    => apb_miso,
      axi4_lite_mosi    => apb_mosi,
      apb_paddr         => apb_paddr,
      apb_psel          => apb_psel,
      apb_penable       => apb_penable,
      apb_pwrite        => apb_pwrite,
      apb_pwdata        => apb_pwdata,
      apb_pready        => apb_pready,
      apb_prdata        => apb_prdata,
      apb_pslverr       => apb_pslverr);


   gen_ip_gemini_xh_lru: IF tech_is_board(g_technology, c_tech_board_gemini_xh_lru) GENERATE

      gen_hbm_left_full: IF g_device = HBM_CONFIG_LEFT_FULL GENERATE

         u_hbm_left_full : hbm_left_full
         PORT MAP (
            HBM_REF_CLK_0 => hbm_ref_clk,

            -- Channel 0
            AXI_00_ACLK => hbm_data_clk(0), AXI_00_ARESET_N => hbm_data_rst_n(0),
            AXI_00_ARADDR => hbm_data_mosi(0).araddr(32 DOWNTO 0), AXI_00_ARBURST => hbm_data_mosi(0).arburst(1 DOWNTO 0), AXI_00_ARID => hbm_data_mosi(0).arid(5 DOWNTO 0),
            AXI_00_ARLEN => hbm_data_mosi(0).arlen(3 DOWNTO 0), AXI_00_ARSIZE => hbm_data_mosi(0).arsize(2 DOWNTO 0), AXI_00_ARVALID => hbm_data_mosi(0).arvalid,
            AXI_00_AWADDR => hbm_data_mosi(0).awaddr(32 DOWNTO 0), AXI_00_AWBURST => hbm_data_mosi(0).awburst(1 DOWNTO 0), AXI_00_AWID => hbm_data_mosi(0).awid(5 DOWNTO 0),
            AXI_00_AWLEN => hbm_data_mosi(0).awlen(3 DOWNTO 0), AXI_00_AWSIZE => hbm_data_mosi(0).awsize(2 DOWNTO 0), AXI_00_AWVALID => hbm_data_mosi(0).awvalid,
            AXI_00_RREADY => hbm_data_mosi(0).rready, AXI_00_BREADY => hbm_data_mosi(0).bready, AXI_00_WDATA => hbm_data_mosi(0).wdata(255 DOWNTO 0),
            AXI_00_WLAST => hbm_data_mosi(0).wlast, AXI_00_WSTRB => hbm_data_mosi(0).wstrb(31 DOWNTO 0),
            AXI_00_WDATA_PARITY => hbm_data_mosi(0).wdata(287 DOWNTO 256), AXI_00_WVALID => hbm_data_mosi(0).wvalid,
            AXI_00_ARREADY => hbm_data_miso(0).arready, AXI_00_AWREADY => hbm_data_miso(0).awready, AXI_00_RDATA_PARITY => hbm_data_miso(0).rdata(287 DOWNTO 256),
            AXI_00_RDATA => hbm_data_miso(0).rdata(255 DOWNTO 0), AXI_00_RID => hbm_data_miso(0).rid(5 DOWNTO 0), AXI_00_RLAST => hbm_data_miso(0).rlast,
            AXI_00_RRESP => hbm_data_miso(0).rresp, AXI_00_RVALID => hbm_data_miso(0).rvalid, AXI_00_WREADY => hbm_data_miso(0).wready,
            AXI_00_BID => hbm_data_miso(0).bid(5 DOWNTO 0), AXI_00_BRESP => hbm_data_miso(0).bresp, AXI_00_BVALID => hbm_data_miso(0).bvalid,

            -- Channel 1
            AXI_01_ACLK => hbm_data_clk(0), AXI_01_ARESET_N => hbm_data_rst_n(0),
            AXI_01_ARADDR => hbm_data_mosi(1).araddr(32 DOWNTO 0), AXI_01_ARBURST => hbm_data_mosi(1).arburst(1 DOWNTO 0), AXI_01_ARID => hbm_data_mosi(1).arid(5 DOWNTO 0),
            AXI_01_ARLEN => hbm_data_mosi(1).arlen(3 DOWNTO 0), AXI_01_ARSIZE => hbm_data_mosi(1).arsize(2 DOWNTO 0), AXI_01_ARVALID => hbm_data_mosi(1).arvalid,
            AXI_01_AWADDR => hbm_data_mosi(1).awaddr(32 DOWNTO 0), AXI_01_AWBURST => hbm_data_mosi(1).awburst(1 DOWNTO 0), AXI_01_AWID => hbm_data_mosi(1).awid(5 DOWNTO 0),
            AXI_01_AWLEN => hbm_data_mosi(1).awlen(3 DOWNTO 0), AXI_01_AWSIZE => hbm_data_mosi(1).awsize(2 DOWNTO 0), AXI_01_AWVALID => hbm_data_mosi(1).awvalid,
            AXI_01_RREADY => hbm_data_mosi(1).rready, AXI_01_BREADY => hbm_data_mosi(1).bready, AXI_01_WDATA => hbm_data_mosi(1).wdata(255 DOWNTO 0),
            AXI_01_WLAST => hbm_data_mosi(1).wlast, AXI_01_WSTRB => hbm_data_mosi(1).wstrb(31 DOWNTO 0),
            AXI_01_WDATA_PARITY => hbm_data_mosi(1).wdata(287 DOWNTO 256), AXI_01_WVALID => hbm_data_mosi(1).wvalid,
            AXI_01_ARREADY => hbm_data_miso(1).arready, AXI_01_AWREADY => hbm_data_miso(1).awready, AXI_01_RDATA_PARITY => hbm_data_miso(1).rdata(287 DOWNTO 256),
            AXI_01_RDATA => hbm_data_miso(1).rdata(255 DOWNTO 0), AXI_01_RID => hbm_data_miso(1).rid(5 DOWNTO 0), AXI_01_RLAST => hbm_data_miso(1).rlast,
            AXI_01_RRESP => hbm_data_miso(1).rresp, AXI_01_RVALID => hbm_data_miso(1).rvalid, AXI_01_WREADY => hbm_data_miso(1).wready,
            AXI_01_BID => hbm_data_miso(1).bid(5 DOWNTO 0), AXI_01_BRESP => hbm_data_miso(1).bresp, AXI_01_BVALID => hbm_data_miso(1).bvalid,

            -- Channel 2
            AXI_02_ACLK => hbm_data_clk(0), AXI_02_ARESET_N => hbm_data_rst_n(0),
            AXI_02_ARADDR => hbm_data_mosi(2).araddr(32 DOWNTO 0), AXI_02_ARBURST => hbm_data_mosi(2).arburst(1 DOWNTO 0), AXI_02_ARID => hbm_data_mosi(2).arid(5 DOWNTO 0),
            AXI_02_ARLEN => hbm_data_mosi(2).arlen(3 DOWNTO 0), AXI_02_ARSIZE => hbm_data_mosi(2).arsize(2 DOWNTO 0), AXI_02_ARVALID => hbm_data_mosi(2).arvalid,
            AXI_02_AWADDR => hbm_data_mosi(2).awaddr(32 DOWNTO 0), AXI_02_AWBURST => hbm_data_mosi(2).awburst(1 DOWNTO 0), AXI_02_AWID => hbm_data_mosi(2).awid(5 DOWNTO 0),
            AXI_02_AWLEN => hbm_data_mosi(2).awlen(3 DOWNTO 0), AXI_02_AWSIZE => hbm_data_mosi(2).awsize(2 DOWNTO 0), AXI_02_AWVALID => hbm_data_mosi(2).awvalid,
            AXI_02_RREADY => hbm_data_mosi(2).rready, AXI_02_BREADY => hbm_data_mosi(2).bready, AXI_02_WDATA => hbm_data_mosi(2).wdata(255 DOWNTO 0),
            AXI_02_WLAST => hbm_data_mosi(2).wlast, AXI_02_WSTRB => hbm_data_mosi(2).wstrb(31 DOWNTO 0),
            AXI_02_WDATA_PARITY => hbm_data_mosi(2).wdata(287 DOWNTO 256), AXI_02_WVALID => hbm_data_mosi(2).wvalid,
            AXI_02_ARREADY => hbm_data_miso(2).arready, AXI_02_AWREADY => hbm_data_miso(2).awready, AXI_02_RDATA_PARITY => hbm_data_miso(2).rdata(287 DOWNTO 256),
            AXI_02_RDATA => hbm_data_miso(2).rdata(255 DOWNTO 0), AXI_02_RID => hbm_data_miso(2).rid(5 DOWNTO 0), AXI_02_RLAST => hbm_data_miso(2).rlast,
            AXI_02_RRESP => hbm_data_miso(2).rresp, AXI_02_RVALID => hbm_data_miso(2).rvalid, AXI_02_WREADY => hbm_data_miso(2).wready,
            AXI_02_BID => hbm_data_miso(2).bid(5 DOWNTO 0), AXI_02_BRESP => hbm_data_miso(2).bresp, AXI_02_BVALID => hbm_data_miso(2).bvalid,

            -- Channel 3
            AXI_03_ACLK => hbm_data_clk(0), AXI_03_ARESET_N => hbm_data_rst_n(0),
            AXI_03_ARADDR => hbm_data_mosi(3).araddr(32 DOWNTO 0), AXI_03_ARBURST => hbm_data_mosi(3).arburst(1 DOWNTO 0), AXI_03_ARID => hbm_data_mosi(3).arid(5 DOWNTO 0),
            AXI_03_ARLEN => hbm_data_mosi(3).arlen(3 DOWNTO 0), AXI_03_ARSIZE => hbm_data_mosi(3).arsize(2 DOWNTO 0), AXI_03_ARVALID => hbm_data_mosi(3).arvalid,
            AXI_03_AWADDR => hbm_data_mosi(3).awaddr(32 DOWNTO 0), AXI_03_AWBURST => hbm_data_mosi(3).awburst(1 DOWNTO 0), AXI_03_AWID => hbm_data_mosi(3).awid(5 DOWNTO 0),
            AXI_03_AWLEN => hbm_data_mosi(3).awlen(3 DOWNTO 0), AXI_03_AWSIZE => hbm_data_mosi(3).awsize(2 DOWNTO 0), AXI_03_AWVALID => hbm_data_mosi(3).awvalid,
            AXI_03_RREADY => hbm_data_mosi(3).rready, AXI_03_BREADY => hbm_data_mosi(3).bready, AXI_03_WDATA => hbm_data_mosi(3).wdata(255 DOWNTO 0),
            AXI_03_WLAST => hbm_data_mosi(3).wlast, AXI_03_WSTRB => hbm_data_mosi(3).wstrb(31 DOWNTO 0),
            AXI_03_WDATA_PARITY => hbm_data_mosi(3).wdata(287 DOWNTO 256), AXI_03_WVALID => hbm_data_mosi(3).wvalid,
            AXI_03_ARREADY => hbm_data_miso(3).arready, AXI_03_AWREADY => hbm_data_miso(3).awready, AXI_03_RDATA_PARITY => hbm_data_miso(3).rdata(287 DOWNTO 256),
            AXI_03_RDATA => hbm_data_miso(3).rdata(255 DOWNTO 0), AXI_03_RID => hbm_data_miso(3).rid(5 DOWNTO 0), AXI_03_RLAST => hbm_data_miso(3).rlast,
            AXI_03_RRESP => hbm_data_miso(3).rresp, AXI_03_RVALID => hbm_data_miso(3).rvalid, AXI_03_WREADY => hbm_data_miso(3).wready,
            AXI_03_BID => hbm_data_miso(3).bid(5 DOWNTO 0), AXI_03_BRESP => hbm_data_miso(3).bresp, AXI_03_BVALID => hbm_data_miso(3).bvalid,

            -- Channel 4
            AXI_04_ACLK => hbm_data_clk(0), AXI_04_ARESET_N => hbm_data_rst_n(0),
            AXI_04_ARADDR => hbm_data_mosi(4).araddr(32 DOWNTO 0), AXI_04_ARBURST => hbm_data_mosi(4).arburst(1 DOWNTO 0), AXI_04_ARID => hbm_data_mosi(4).arid(5 DOWNTO 0),
            AXI_04_ARLEN => hbm_data_mosi(4).arlen(3 DOWNTO 0), AXI_04_ARSIZE => hbm_data_mosi(4).arsize(2 DOWNTO 0), AXI_04_ARVALID => hbm_data_mosi(4).arvalid,
            AXI_04_AWADDR => hbm_data_mosi(4).awaddr(32 DOWNTO 0), AXI_04_AWBURST => hbm_data_mosi(4).awburst(1 DOWNTO 0), AXI_04_AWID => hbm_data_mosi(4).awid(5 DOWNTO 0),
            AXI_04_AWLEN => hbm_data_mosi(4).awlen(3 DOWNTO 0), AXI_04_AWSIZE => hbm_data_mosi(4).awsize(2 DOWNTO 0), AXI_04_AWVALID => hbm_data_mosi(4).awvalid,
            AXI_04_RREADY => hbm_data_mosi(4).rready, AXI_04_BREADY => hbm_data_mosi(4).bready, AXI_04_WDATA => hbm_data_mosi(4).wdata(255 DOWNTO 0),
            AXI_04_WLAST => hbm_data_mosi(4).wlast, AXI_04_WSTRB => hbm_data_mosi(4).wstrb(31 DOWNTO 0),
            AXI_04_WDATA_PARITY => hbm_data_mosi(4).wdata(287 DOWNTO 256), AXI_04_WVALID => hbm_data_mosi(4).wvalid,
            AXI_04_ARREADY => hbm_data_miso(4).arready, AXI_04_AWREADY => hbm_data_miso(4).awready, AXI_04_RDATA_PARITY => hbm_data_miso(4).rdata(287 DOWNTO 256),
            AXI_04_RDATA => hbm_data_miso(4).rdata(255 DOWNTO 0), AXI_04_RID => hbm_data_miso(4).rid(5 DOWNTO 0), AXI_04_RLAST => hbm_data_miso(4).rlast,
            AXI_04_RRESP => hbm_data_miso(4).rresp, AXI_04_RVALID => hbm_data_miso(4).rvalid, AXI_04_WREADY => hbm_data_miso(4).wready,
            AXI_04_BID => hbm_data_miso(4).bid(5 DOWNTO 0), AXI_04_BRESP => hbm_data_miso(4).bresp, AXI_04_BVALID => hbm_data_miso(4).bvalid,

            -- Channel 5
            AXI_05_ACLK => hbm_data_clk(0), AXI_05_ARESET_N => hbm_data_rst_n(0),
            AXI_05_ARADDR => hbm_data_mosi(5).araddr(32 DOWNTO 0), AXI_05_ARBURST => hbm_data_mosi(5).arburst(1 DOWNTO 0), AXI_05_ARID => hbm_data_mosi(5).arid(5 DOWNTO 0),
            AXI_05_ARLEN => hbm_data_mosi(5).arlen(3 DOWNTO 0), AXI_05_ARSIZE => hbm_data_mosi(5).arsize(2 DOWNTO 0), AXI_05_ARVALID => hbm_data_mosi(5).arvalid,
            AXI_05_AWADDR => hbm_data_mosi(5).awaddr(32 DOWNTO 0), AXI_05_AWBURST => hbm_data_mosi(5).awburst(1 DOWNTO 0), AXI_05_AWID => hbm_data_mosi(5).awid(5 DOWNTO 0),
            AXI_05_AWLEN => hbm_data_mosi(5).awlen(3 DOWNTO 0), AXI_05_AWSIZE => hbm_data_mosi(5).awsize(2 DOWNTO 0), AXI_05_AWVALID => hbm_data_mosi(5).awvalid,
            AXI_05_RREADY => hbm_data_mosi(5).rready, AXI_05_BREADY => hbm_data_mosi(5).bready, AXI_05_WDATA => hbm_data_mosi(5).wdata(255 DOWNTO 0),
            AXI_05_WLAST => hbm_data_mosi(5).wlast, AXI_05_WSTRB => hbm_data_mosi(5).wstrb(31 DOWNTO 0),
            AXI_05_WDATA_PARITY => hbm_data_mosi(5).wdata(287 DOWNTO 256), AXI_05_WVALID => hbm_data_mosi(5).wvalid,
            AXI_05_ARREADY => hbm_data_miso(5).arready, AXI_05_AWREADY => hbm_data_miso(5).awready, AXI_05_RDATA_PARITY => hbm_data_miso(5).rdata(287 DOWNTO 256),
            AXI_05_RDATA => hbm_data_miso(5).rdata(255 DOWNTO 0), AXI_05_RID => hbm_data_miso(5).rid(5 DOWNTO 0), AXI_05_RLAST => hbm_data_miso(5).rlast,
            AXI_05_RRESP => hbm_data_miso(5).rresp, AXI_05_RVALID => hbm_data_miso(5).rvalid, AXI_05_WREADY => hbm_data_miso(5).wready,
            AXI_05_BID => hbm_data_miso(5).bid(5 DOWNTO 0), AXI_05_BRESP => hbm_data_miso(5).bresp, AXI_05_BVALID => hbm_data_miso(5).bvalid,

            -- Channel 6
            AXI_06_ACLK => hbm_data_clk(0), AXI_06_ARESET_N => hbm_data_rst_n(0),
            AXI_06_ARADDR => hbm_data_mosi(6).araddr(32 DOWNTO 0), AXI_06_ARBURST => hbm_data_mosi(6).arburst(1 DOWNTO 0), AXI_06_ARID => hbm_data_mosi(6).arid(5 DOWNTO 0),
            AXI_06_ARLEN => hbm_data_mosi(6).arlen(3 DOWNTO 0), AXI_06_ARSIZE => hbm_data_mosi(6).arsize(2 DOWNTO 0), AXI_06_ARVALID => hbm_data_mosi(6).arvalid,
            AXI_06_AWADDR => hbm_data_mosi(6).awaddr(32 DOWNTO 0), AXI_06_AWBURST => hbm_data_mosi(6).awburst(1 DOWNTO 0), AXI_06_AWID => hbm_data_mosi(6).awid(5 DOWNTO 0),
            AXI_06_AWLEN => hbm_data_mosi(6).awlen(3 DOWNTO 0), AXI_06_AWSIZE => hbm_data_mosi(6).awsize(2 DOWNTO 0), AXI_06_AWVALID => hbm_data_mosi(6).awvalid,
            AXI_06_RREADY => hbm_data_mosi(6).rready, AXI_06_BREADY => hbm_data_mosi(6).bready, AXI_06_WDATA => hbm_data_mosi(6).wdata(255 DOWNTO 0),
            AXI_06_WLAST => hbm_data_mosi(6).wlast, AXI_06_WSTRB => hbm_data_mosi(6).wstrb(31 DOWNTO 0),
            AXI_06_WDATA_PARITY => hbm_data_mosi(6).wdata(287 DOWNTO 256), AXI_06_WVALID => hbm_data_mosi(6).wvalid,
            AXI_06_ARREADY => hbm_data_miso(6).arready, AXI_06_AWREADY => hbm_data_miso(6).awready, AXI_06_RDATA_PARITY => hbm_data_miso(6).rdata(287 DOWNTO 256),
            AXI_06_RDATA => hbm_data_miso(6).rdata(255 DOWNTO 0), AXI_06_RID => hbm_data_miso(6).rid(5 DOWNTO 0), AXI_06_RLAST => hbm_data_miso(6).rlast,
            AXI_06_RRESP => hbm_data_miso(6).rresp, AXI_06_RVALID => hbm_data_miso(6).rvalid, AXI_06_WREADY => hbm_data_miso(6).wready,
            AXI_06_BID => hbm_data_miso(6).bid(5 DOWNTO 0), AXI_06_BRESP => hbm_data_miso(6).bresp, AXI_06_BVALID => hbm_data_miso(6).bvalid,

            -- Channel 7
            AXI_07_ACLK => hbm_data_clk(0), AXI_07_ARESET_N => hbm_data_rst_n(0),
            AXI_07_ARADDR => hbm_data_mosi(7).araddr(32 DOWNTO 0), AXI_07_ARBURST => hbm_data_mosi(7).arburst(1 DOWNTO 0), AXI_07_ARID => hbm_data_mosi(7).arid(5 DOWNTO 0),
            AXI_07_ARLEN => hbm_data_mosi(7).arlen(3 DOWNTO 0), AXI_07_ARSIZE => hbm_data_mosi(7).arsize(2 DOWNTO 0), AXI_07_ARVALID => hbm_data_mosi(7).arvalid,
            AXI_07_AWADDR => hbm_data_mosi(7).awaddr(32 DOWNTO 0), AXI_07_AWBURST => hbm_data_mosi(7).awburst(1 DOWNTO 0), AXI_07_AWID => hbm_data_mosi(7).awid(5 DOWNTO 0),
            AXI_07_AWLEN => hbm_data_mosi(7).awlen(3 DOWNTO 0), AXI_07_AWSIZE => hbm_data_mosi(7).awsize(2 DOWNTO 0), AXI_07_AWVALID => hbm_data_mosi(7).awvalid,
            AXI_07_RREADY => hbm_data_mosi(7).rready, AXI_07_BREADY => hbm_data_mosi(7).bready, AXI_07_WDATA => hbm_data_mosi(7).wdata(255 DOWNTO 0),
            AXI_07_WLAST => hbm_data_mosi(7).wlast, AXI_07_WSTRB => hbm_data_mosi(7).wstrb(31 DOWNTO 0),
            AXI_07_WDATA_PARITY => hbm_data_mosi(7).wdata(287 DOWNTO 256), AXI_07_WVALID => hbm_data_mosi(7).wvalid,
            AXI_07_ARREADY => hbm_data_miso(7).arready, AXI_07_AWREADY => hbm_data_miso(7).awready, AXI_07_RDATA_PARITY => hbm_data_miso(7).rdata(287 DOWNTO 256),
            AXI_07_RDATA => hbm_data_miso(7).rdata(255 DOWNTO 0), AXI_07_RID => hbm_data_miso(7).rid(5 DOWNTO 0), AXI_07_RLAST => hbm_data_miso(7).rlast,
            AXI_07_RRESP => hbm_data_miso(7).rresp, AXI_07_RVALID => hbm_data_miso(7).rvalid, AXI_07_WREADY => hbm_data_miso(7).wready,
            AXI_07_BID => hbm_data_miso(7).bid(5 DOWNTO 0), AXI_07_BRESP => hbm_data_miso(7).bresp, AXI_07_BVALID => hbm_data_miso(7).bvalid,

            -- Channel 8
            AXI_08_ACLK => hbm_data_clk(0), AXI_08_ARESET_N => hbm_data_rst_n(0),
            AXI_08_ARADDR => hbm_data_mosi(8).araddr(32 DOWNTO 0), AXI_08_ARBURST => hbm_data_mosi(8).arburst(1 DOWNTO 0), AXI_08_ARID => hbm_data_mosi(8).arid(5 DOWNTO 0),
            AXI_08_ARLEN => hbm_data_mosi(8).arlen(3 DOWNTO 0), AXI_08_ARSIZE => hbm_data_mosi(8).arsize(2 DOWNTO 0), AXI_08_ARVALID => hbm_data_mosi(8).arvalid,
            AXI_08_AWADDR => hbm_data_mosi(8).awaddr(32 DOWNTO 0), AXI_08_AWBURST => hbm_data_mosi(8).awburst(1 DOWNTO 0), AXI_08_AWID => hbm_data_mosi(8).awid(5 DOWNTO 0),
            AXI_08_AWLEN => hbm_data_mosi(8).awlen(3 DOWNTO 0), AXI_08_AWSIZE => hbm_data_mosi(8).awsize(2 DOWNTO 0), AXI_08_AWVALID => hbm_data_mosi(8).awvalid,
            AXI_08_RREADY => hbm_data_mosi(8).rready, AXI_08_BREADY => hbm_data_mosi(8).bready, AXI_08_WDATA => hbm_data_mosi(8).wdata(255 DOWNTO 0),
            AXI_08_WLAST => hbm_data_mosi(8).wlast, AXI_08_WSTRB => hbm_data_mosi(8).wstrb(31 DOWNTO 0),
            AXI_08_WDATA_PARITY => hbm_data_mosi(8).wdata(287 DOWNTO 256), AXI_08_WVALID => hbm_data_mosi(8).wvalid,
            AXI_08_ARREADY => hbm_data_miso(8).arready, AXI_08_AWREADY => hbm_data_miso(8).awready, AXI_08_RDATA_PARITY => hbm_data_miso(8).rdata(287 DOWNTO 256),
            AXI_08_RDATA => hbm_data_miso(8).rdata(255 DOWNTO 0), AXI_08_RID => hbm_data_miso(8).rid(5 DOWNTO 0), AXI_08_RLAST => hbm_data_miso(8).rlast,
            AXI_08_RRESP => hbm_data_miso(8).rresp, AXI_08_RVALID => hbm_data_miso(8).rvalid, AXI_08_WREADY => hbm_data_miso(8).wready,
            AXI_08_BID => hbm_data_miso(8).bid(5 DOWNTO 0), AXI_08_BRESP => hbm_data_miso(8).bresp, AXI_08_BVALID => hbm_data_miso(8).bvalid,

            -- Channel 9
            AXI_09_ACLK => hbm_data_clk(0), AXI_09_ARESET_N => hbm_data_rst_n(0),
            AXI_09_ARADDR => hbm_data_mosi(9).araddr(32 DOWNTO 0), AXI_09_ARBURST => hbm_data_mosi(9).arburst(1 DOWNTO 0), AXI_09_ARID => hbm_data_mosi(9).arid(5 DOWNTO 0),
            AXI_09_ARLEN => hbm_data_mosi(9).arlen(3 DOWNTO 0), AXI_09_ARSIZE => hbm_data_mosi(9).arsize(2 DOWNTO 0), AXI_09_ARVALID => hbm_data_mosi(9).arvalid,
            AXI_09_AWADDR => hbm_data_mosi(9).awaddr(32 DOWNTO 0), AXI_09_AWBURST => hbm_data_mosi(9).awburst(1 DOWNTO 0), AXI_09_AWID => hbm_data_mosi(9).awid(5 DOWNTO 0),
            AXI_09_AWLEN => hbm_data_mosi(9).awlen(3 DOWNTO 0), AXI_09_AWSIZE => hbm_data_mosi(9).awsize(2 DOWNTO 0), AXI_09_AWVALID => hbm_data_mosi(9).awvalid,
            AXI_09_RREADY => hbm_data_mosi(9).rready, AXI_09_BREADY => hbm_data_mosi(9).bready, AXI_09_WDATA => hbm_data_mosi(9).wdata(255 DOWNTO 0),
            AXI_09_WLAST => hbm_data_mosi(9).wlast, AXI_09_WSTRB => hbm_data_mosi(9).wstrb(31 DOWNTO 0),
            AXI_09_WDATA_PARITY => hbm_data_mosi(9).wdata(287 DOWNTO 256), AXI_09_WVALID => hbm_data_mosi(9).wvalid,
            AXI_09_ARREADY => hbm_data_miso(9).arready, AXI_09_AWREADY => hbm_data_miso(9).awready, AXI_09_RDATA_PARITY => hbm_data_miso(9).rdata(287 DOWNTO 256),
            AXI_09_RDATA => hbm_data_miso(9).rdata(255 DOWNTO 0), AXI_09_RID => hbm_data_miso(9).rid(5 DOWNTO 0), AXI_09_RLAST => hbm_data_miso(9).rlast,
            AXI_09_RRESP => hbm_data_miso(9).rresp, AXI_09_RVALID => hbm_data_miso(9).rvalid, AXI_09_WREADY => hbm_data_miso(9).wready,
            AXI_09_BID => hbm_data_miso(9).bid(5 DOWNTO 0), AXI_09_BRESP => hbm_data_miso(9).bresp, AXI_09_BVALID => hbm_data_miso(9).bvalid,

            -- Channel 10
            AXI_10_ACLK => hbm_data_clk(0), AXI_10_ARESET_N => hbm_data_rst_n(0),
            AXI_10_ARADDR => hbm_data_mosi(10).araddr(32 DOWNTO 0), AXI_10_ARBURST => hbm_data_mosi(10).arburst(1 DOWNTO 0), AXI_10_ARID => hbm_data_mosi(10).arid(5 DOWNTO 0),
            AXI_10_ARLEN => hbm_data_mosi(10).arlen(3 DOWNTO 0), AXI_10_ARSIZE => hbm_data_mosi(10).arsize(2 DOWNTO 0), AXI_10_ARVALID => hbm_data_mosi(10).arvalid,
            AXI_10_AWADDR => hbm_data_mosi(10).awaddr(32 DOWNTO 0), AXI_10_AWBURST => hbm_data_mosi(10).awburst(1 DOWNTO 0), AXI_10_AWID => hbm_data_mosi(10).awid(5 DOWNTO 0),
            AXI_10_AWLEN => hbm_data_mosi(10).awlen(3 DOWNTO 0), AXI_10_AWSIZE => hbm_data_mosi(10).awsize(2 DOWNTO 0), AXI_10_AWVALID => hbm_data_mosi(10).awvalid,
            AXI_10_RREADY => hbm_data_mosi(10).rready, AXI_10_BREADY => hbm_data_mosi(10).bready, AXI_10_WDATA => hbm_data_mosi(10).wdata(255 DOWNTO 0),
            AXI_10_WLAST => hbm_data_mosi(10).wlast, AXI_10_WSTRB => hbm_data_mosi(10).wstrb(31 DOWNTO 0),
            AXI_10_WDATA_PARITY => hbm_data_mosi(10).wdata(287 DOWNTO 256), AXI_10_WVALID => hbm_data_mosi(10).wvalid,
            AXI_10_ARREADY => hbm_data_miso(10).arready, AXI_10_AWREADY => hbm_data_miso(10).awready, AXI_10_RDATA_PARITY => hbm_data_miso(10).rdata(287 DOWNTO 256),
            AXI_10_RDATA => hbm_data_miso(10).rdata(255 DOWNTO 0), AXI_10_RID => hbm_data_miso(10).rid(5 DOWNTO 0), AXI_10_RLAST => hbm_data_miso(10).rlast,
            AXI_10_RRESP => hbm_data_miso(10).rresp, AXI_10_RVALID => hbm_data_miso(10).rvalid, AXI_10_WREADY => hbm_data_miso(10).wready,
            AXI_10_BID => hbm_data_miso(10).bid(5 DOWNTO 0), AXI_10_BRESP => hbm_data_miso(10).bresp, AXI_10_BVALID => hbm_data_miso(10).bvalid,

            -- Channel 11
            AXI_11_ACLK => hbm_data_clk(0), AXI_11_ARESET_N => hbm_data_rst_n(0),
            AXI_11_ARADDR => hbm_data_mosi(11).araddr(32 DOWNTO 0), AXI_11_ARBURST => hbm_data_mosi(11).arburst(1 DOWNTO 0), AXI_11_ARID => hbm_data_mosi(11).arid(5 DOWNTO 0),
            AXI_11_ARLEN => hbm_data_mosi(11).arlen(3 DOWNTO 0), AXI_11_ARSIZE => hbm_data_mosi(11).arsize(2 DOWNTO 0), AXI_11_ARVALID => hbm_data_mosi(11).arvalid,
            AXI_11_AWADDR => hbm_data_mosi(11).awaddr(32 DOWNTO 0), AXI_11_AWBURST => hbm_data_mosi(11).awburst(1 DOWNTO 0), AXI_11_AWID => hbm_data_mosi(11).awid(5 DOWNTO 0),
            AXI_11_AWLEN => hbm_data_mosi(11).awlen(3 DOWNTO 0), AXI_11_AWSIZE => hbm_data_mosi(11).awsize(2 DOWNTO 0), AXI_11_AWVALID => hbm_data_mosi(11).awvalid,
            AXI_11_RREADY => hbm_data_mosi(11).rready, AXI_11_BREADY => hbm_data_mosi(11).bready, AXI_11_WDATA => hbm_data_mosi(11).wdata(255 DOWNTO 0),
            AXI_11_WLAST => hbm_data_mosi(11).wlast, AXI_11_WSTRB => hbm_data_mosi(11).wstrb(31 DOWNTO 0),
            AXI_11_WDATA_PARITY => hbm_data_mosi(11).wdata(287 DOWNTO 256), AXI_11_WVALID => hbm_data_mosi(11).wvalid,
            AXI_11_ARREADY => hbm_data_miso(11).arready, AXI_11_AWREADY => hbm_data_miso(11).awready, AXI_11_RDATA_PARITY => hbm_data_miso(11).rdata(287 DOWNTO 256),
            AXI_11_RDATA => hbm_data_miso(11).rdata(255 DOWNTO 0), AXI_11_RID => hbm_data_miso(11).rid(5 DOWNTO 0), AXI_11_RLAST => hbm_data_miso(11).rlast,
            AXI_11_RRESP => hbm_data_miso(11).rresp, AXI_11_RVALID => hbm_data_miso(11).rvalid, AXI_11_WREADY => hbm_data_miso(11).wready,
            AXI_11_BID => hbm_data_miso(11).bid(5 DOWNTO 0), AXI_11_BRESP => hbm_data_miso(11).bresp, AXI_11_BVALID => hbm_data_miso(11).bvalid,

            -- Channel 12
            AXI_12_ACLK => hbm_data_clk(0), AXI_12_ARESET_N => hbm_data_rst_n(0),
            AXI_12_ARADDR => hbm_data_mosi(12).araddr(32 DOWNTO 0), AXI_12_ARBURST => hbm_data_mosi(12).arburst(1 DOWNTO 0), AXI_12_ARID => hbm_data_mosi(12).arid(5 DOWNTO 0),
            AXI_12_ARLEN => hbm_data_mosi(12).arlen(3 DOWNTO 0), AXI_12_ARSIZE => hbm_data_mosi(12).arsize(2 DOWNTO 0), AXI_12_ARVALID => hbm_data_mosi(12).arvalid,
            AXI_12_AWADDR => hbm_data_mosi(12).awaddr(32 DOWNTO 0), AXI_12_AWBURST => hbm_data_mosi(12).awburst(1 DOWNTO 0), AXI_12_AWID => hbm_data_mosi(12).awid(5 DOWNTO 0),
            AXI_12_AWLEN => hbm_data_mosi(12).awlen(3 DOWNTO 0), AXI_12_AWSIZE => hbm_data_mosi(12).awsize(2 DOWNTO 0), AXI_12_AWVALID => hbm_data_mosi(12).awvalid,
            AXI_12_RREADY => hbm_data_mosi(12).rready, AXI_12_BREADY => hbm_data_mosi(12).bready, AXI_12_WDATA => hbm_data_mosi(12).wdata(255 DOWNTO 0),
            AXI_12_WLAST => hbm_data_mosi(12).wlast, AXI_12_WSTRB => hbm_data_mosi(12).wstrb(31 DOWNTO 0),
            AXI_12_WDATA_PARITY => hbm_data_mosi(12).wdata(287 DOWNTO 256), AXI_12_WVALID => hbm_data_mosi(12).wvalid,
            AXI_12_ARREADY => hbm_data_miso(12).arready, AXI_12_AWREADY => hbm_data_miso(12).awready, AXI_12_RDATA_PARITY => hbm_data_miso(12).rdata(287 DOWNTO 256),
            AXI_12_RDATA => hbm_data_miso(12).rdata(255 DOWNTO 0), AXI_12_RID => hbm_data_miso(12).rid(5 DOWNTO 0), AXI_12_RLAST => hbm_data_miso(12).rlast,
            AXI_12_RRESP => hbm_data_miso(12).rresp, AXI_12_RVALID => hbm_data_miso(12).rvalid, AXI_12_WREADY => hbm_data_miso(12).wready,
            AXI_12_BID => hbm_data_miso(12).bid(5 DOWNTO 0), AXI_12_BRESP => hbm_data_miso(12).bresp, AXI_12_BVALID => hbm_data_miso(12).bvalid,

            -- Channel 13
            AXI_13_ACLK => hbm_data_clk(0), AXI_13_ARESET_N => hbm_data_rst_n(0),
            AXI_13_ARADDR => hbm_data_mosi(13).araddr(32 DOWNTO 0), AXI_13_ARBURST => hbm_data_mosi(13).arburst(1 DOWNTO 0), AXI_13_ARID => hbm_data_mosi(13).arid(5 DOWNTO 0),
            AXI_13_ARLEN => hbm_data_mosi(13).arlen(3 DOWNTO 0), AXI_13_ARSIZE => hbm_data_mosi(13).arsize(2 DOWNTO 0), AXI_13_ARVALID => hbm_data_mosi(13).arvalid,
            AXI_13_AWADDR => hbm_data_mosi(13).awaddr(32 DOWNTO 0), AXI_13_AWBURST => hbm_data_mosi(13).awburst(1 DOWNTO 0), AXI_13_AWID => hbm_data_mosi(13).awid(5 DOWNTO 0),
            AXI_13_AWLEN => hbm_data_mosi(13).awlen(3 DOWNTO 0), AXI_13_AWSIZE => hbm_data_mosi(13).awsize(2 DOWNTO 0), AXI_13_AWVALID => hbm_data_mosi(13).awvalid,
            AXI_13_RREADY => hbm_data_mosi(13).rready, AXI_13_BREADY => hbm_data_mosi(13).bready, AXI_13_WDATA => hbm_data_mosi(13).wdata(255 DOWNTO 0),
            AXI_13_WLAST => hbm_data_mosi(13).wlast, AXI_13_WSTRB => hbm_data_mosi(13).wstrb(31 DOWNTO 0),
            AXI_13_WDATA_PARITY => hbm_data_mosi(13).wdata(287 DOWNTO 256), AXI_13_WVALID => hbm_data_mosi(13).wvalid,
            AXI_13_ARREADY => hbm_data_miso(13).arready, AXI_13_AWREADY => hbm_data_miso(13).awready, AXI_13_RDATA_PARITY => hbm_data_miso(13).rdata(287 DOWNTO 256),
            AXI_13_RDATA => hbm_data_miso(13).rdata(255 DOWNTO 0), AXI_13_RID => hbm_data_miso(13).rid(5 DOWNTO 0), AXI_13_RLAST => hbm_data_miso(13).rlast,
            AXI_13_RRESP => hbm_data_miso(13).rresp, AXI_13_RVALID => hbm_data_miso(13).rvalid, AXI_13_WREADY => hbm_data_miso(13).wready,
            AXI_13_BID => hbm_data_miso(13).bid(5 DOWNTO 0), AXI_13_BRESP => hbm_data_miso(13).bresp, AXI_13_BVALID => hbm_data_miso(13).bvalid,

            -- Channel 14
            AXI_14_ACLK => hbm_data_clk(0), AXI_14_ARESET_N => hbm_data_rst_n(0),
            AXI_14_ARADDR => hbm_data_mosi(14).araddr(32 DOWNTO 0), AXI_14_ARBURST => hbm_data_mosi(14).arburst(1 DOWNTO 0), AXI_14_ARID => hbm_data_mosi(14).arid(5 DOWNTO 0),
            AXI_14_ARLEN => hbm_data_mosi(14).arlen(3 DOWNTO 0), AXI_14_ARSIZE => hbm_data_mosi(14).arsize(2 DOWNTO 0), AXI_14_ARVALID => hbm_data_mosi(14).arvalid,
            AXI_14_AWADDR => hbm_data_mosi(14).awaddr(32 DOWNTO 0), AXI_14_AWBURST => hbm_data_mosi(14).awburst(1 DOWNTO 0), AXI_14_AWID => hbm_data_mosi(14).awid(5 DOWNTO 0),
            AXI_14_AWLEN => hbm_data_mosi(14).awlen(3 DOWNTO 0), AXI_14_AWSIZE => hbm_data_mosi(14).awsize(2 DOWNTO 0), AXI_14_AWVALID => hbm_data_mosi(14).awvalid,
            AXI_14_RREADY => hbm_data_mosi(14).rready, AXI_14_BREADY => hbm_data_mosi(14).bready, AXI_14_WDATA => hbm_data_mosi(14).wdata(255 DOWNTO 0),
            AXI_14_WLAST => hbm_data_mosi(14).wlast, AXI_14_WSTRB => hbm_data_mosi(14).wstrb(31 DOWNTO 0),
            AXI_14_WDATA_PARITY => hbm_data_mosi(14).wdata(287 DOWNTO 256), AXI_14_WVALID => hbm_data_mosi(14).wvalid,
            AXI_14_ARREADY => hbm_data_miso(14).arready, AXI_14_AWREADY => hbm_data_miso(14).awready, AXI_14_RDATA_PARITY => hbm_data_miso(14).rdata(287 DOWNTO 256),
            AXI_14_RDATA => hbm_data_miso(14).rdata(255 DOWNTO 0), AXI_14_RID => hbm_data_miso(14).rid(5 DOWNTO 0), AXI_14_RLAST => hbm_data_miso(14).rlast,
            AXI_14_RRESP => hbm_data_miso(14).rresp, AXI_14_RVALID => hbm_data_miso(14).rvalid, AXI_14_WREADY => hbm_data_miso(14).wready,
            AXI_14_BID => hbm_data_miso(14).bid(5 DOWNTO 0), AXI_14_BRESP => hbm_data_miso(14).bresp, AXI_14_BVALID => hbm_data_miso(14).bvalid,


            -- Channel 15
            AXI_15_ACLK => hbm_data_clk(0), AXI_15_ARESET_N => hbm_data_rst_n(0),
            AXI_15_ARADDR => hbm_data_mosi(15).araddr(32 DOWNTO 0), AXI_15_ARBURST => hbm_data_mosi(15).arburst(1 DOWNTO 0), AXI_15_ARID => hbm_data_mosi(15).arid(5 DOWNTO 0),
            AXI_15_ARLEN => hbm_data_mosi(15).arlen(3 DOWNTO 0), AXI_15_ARSIZE => hbm_data_mosi(15).arsize(2 DOWNTO 0), AXI_15_ARVALID => hbm_data_mosi(15).arvalid,
            AXI_15_AWADDR => hbm_data_mosi(15).awaddr(32 DOWNTO 0), AXI_15_AWBURST => hbm_data_mosi(15).awburst(1 DOWNTO 0), AXI_15_AWID => hbm_data_mosi(15).awid(5 DOWNTO 0),
            AXI_15_AWLEN => hbm_data_mosi(15).awlen(3 DOWNTO 0), AXI_15_AWSIZE => hbm_data_mosi(15).awsize(2 DOWNTO 0), AXI_15_AWVALID => hbm_data_mosi(15).awvalid,
            AXI_15_RREADY => hbm_data_mosi(15).rready, AXI_15_BREADY => hbm_data_mosi(15).bready, AXI_15_WDATA => hbm_data_mosi(15).wdata(255 DOWNTO 0),
            AXI_15_WLAST => hbm_data_mosi(15).wlast, AXI_15_WSTRB => hbm_data_mosi(15).wstrb(31 DOWNTO 0),
            AXI_15_WDATA_PARITY => hbm_data_mosi(15).wdata(287 DOWNTO 256), AXI_15_WVALID => hbm_data_mosi(15).wvalid,
            AXI_15_ARREADY => hbm_data_miso(15).arready, AXI_15_AWREADY => hbm_data_miso(15).awready, AXI_15_RDATA_PARITY => hbm_data_miso(15).rdata(287 DOWNTO 256),
            AXI_15_RDATA => hbm_data_miso(15).rdata(255 DOWNTO 0), AXI_15_RID => hbm_data_miso(15).rid(5 DOWNTO 0), AXI_15_RLAST => hbm_data_miso(15).rlast,
            AXI_15_RRESP => hbm_data_miso(15).rresp, AXI_15_RVALID => hbm_data_miso(15).rvalid, AXI_15_WREADY => hbm_data_miso(15).wready,
            AXI_15_BID => hbm_data_miso(15).bid(5 DOWNTO 0), AXI_15_BRESP => hbm_data_miso(15).bresp, AXI_15_BVALID => hbm_data_miso(15).bvalid,

            -- Control
            APB_0_PCLK => apb_clk, APB_0_PRESET_N => apb_rst_n,
            APB_0_PADDR => apb_paddr, APB_0_PWDATA => apb_pwdata, APB_0_PENABLE => apb_penable, APB_0_PSEL => apb_psel, APB_0_PWRITE => apb_pwrite,
            APB_0_PRDATA => apb_prdata, APB_0_PREADY => apb_pready, APB_0_PSLVERR => apb_pslverr, apb_complete_0 => OPEN,

            DRAM_0_STAT_CATTRIP => temperature_failure, DRAM_0_STAT_TEMP => OPEN);

      END GENERATE;

      gen_hbm_right_individual: IF g_device = HBM_CONFIG_RIGHT_INDIVIDUAL GENERATE

         u_hbm_right_individual : hbm_right_individual
         PORT MAP (
            HBM_REF_CLK_0 => hbm_ref_clk,

            -- Channel 0
            AXI_00_ACLK => hbm_data_clk(0), AXI_00_ARESET_N => hbm_data_rst_n(0),
            AXI_00_ARADDR => hbm_data_mosi(0).araddr(32 DOWNTO 0), AXI_00_ARBURST => hbm_data_mosi(0).arburst(1 DOWNTO 0), AXI_00_ARID => hbm_data_mosi(0).arid(5 DOWNTO 0),
            AXI_00_ARLEN => hbm_data_mosi(0).arlen(3 DOWNTO 0), AXI_00_ARSIZE => hbm_data_mosi(0).arsize(2 DOWNTO 0), AXI_00_ARVALID => hbm_data_mosi(0).arvalid,
            AXI_00_AWADDR => hbm_data_mosi(0).awaddr(32 DOWNTO 0), AXI_00_AWBURST => hbm_data_mosi(0).awburst(1 DOWNTO 0), AXI_00_AWID => hbm_data_mosi(0).awid(5 DOWNTO 0),
            AXI_00_AWLEN => hbm_data_mosi(0).awlen(3 DOWNTO 0), AXI_00_AWSIZE => hbm_data_mosi(0).awsize(2 DOWNTO 0), AXI_00_AWVALID => hbm_data_mosi(0).awvalid,
            AXI_00_RREADY => hbm_data_mosi(0).rready, AXI_00_BREADY => hbm_data_mosi(0).bready, AXI_00_WDATA => hbm_data_mosi(0).wdata(255 DOWNTO 0),
            AXI_00_WLAST => hbm_data_mosi(0).wlast, AXI_00_WSTRB => hbm_data_mosi(0).wstrb(31 DOWNTO 0),
            AXI_00_WDATA_PARITY => hbm_data_mosi(0).wdata(287 DOWNTO 256), AXI_00_WVALID => hbm_data_mosi(0).wvalid,
            AXI_00_ARREADY => hbm_data_miso(0).arready, AXI_00_AWREADY => hbm_data_miso(0).awready, AXI_00_RDATA_PARITY => hbm_data_miso(0).rdata(287 DOWNTO 256),
            AXI_00_RDATA => hbm_data_miso(0).rdata(255 DOWNTO 0), AXI_00_RID => hbm_data_miso(0).rid(5 DOWNTO 0), AXI_00_RLAST => hbm_data_miso(0).rlast,
            AXI_00_RRESP => hbm_data_miso(0).rresp, AXI_00_RVALID => hbm_data_miso(0).rvalid, AXI_00_WREADY => hbm_data_miso(0).wready,
            AXI_00_BID => hbm_data_miso(0).bid(5 DOWNTO 0), AXI_00_BRESP => hbm_data_miso(0).bresp, AXI_00_BVALID => hbm_data_miso(0).bvalid,

            -- Channel 1
            AXI_01_ACLK => hbm_data_clk(0), AXI_01_ARESET_N => hbm_data_rst_n(0),
            AXI_01_ARADDR => hbm_data_mosi(1).araddr(32 DOWNTO 0), AXI_01_ARBURST => hbm_data_mosi(1).arburst(1 DOWNTO 0), AXI_01_ARID => hbm_data_mosi(1).arid(5 DOWNTO 0),
            AXI_01_ARLEN => hbm_data_mosi(1).arlen(3 DOWNTO 0), AXI_01_ARSIZE => hbm_data_mosi(1).arsize(2 DOWNTO 0), AXI_01_ARVALID => hbm_data_mosi(1).arvalid,
            AXI_01_AWADDR => hbm_data_mosi(1).awaddr(32 DOWNTO 0), AXI_01_AWBURST => hbm_data_mosi(1).awburst(1 DOWNTO 0), AXI_01_AWID => hbm_data_mosi(1).awid(5 DOWNTO 0),
            AXI_01_AWLEN => hbm_data_mosi(1).awlen(3 DOWNTO 0), AXI_01_AWSIZE => hbm_data_mosi(1).awsize(2 DOWNTO 0), AXI_01_AWVALID => hbm_data_mosi(1).awvalid,
            AXI_01_RREADY => hbm_data_mosi(1).rready, AXI_01_BREADY => hbm_data_mosi(1).bready, AXI_01_WDATA => hbm_data_mosi(1).wdata(255 DOWNTO 0),
            AXI_01_WLAST => hbm_data_mosi(1).wlast, AXI_01_WSTRB => hbm_data_mosi(1).wstrb(31 DOWNTO 0),
            AXI_01_WDATA_PARITY => hbm_data_mosi(1).wdata(287 DOWNTO 256), AXI_01_WVALID => hbm_data_mosi(1).wvalid,
            AXI_01_ARREADY => hbm_data_miso(1).arready, AXI_01_AWREADY => hbm_data_miso(1).awready, AXI_01_RDATA_PARITY => hbm_data_miso(1).rdata(287 DOWNTO 256),
            AXI_01_RDATA => hbm_data_miso(1).rdata(255 DOWNTO 0), AXI_01_RID => hbm_data_miso(1).rid(5 DOWNTO 0), AXI_01_RLAST => hbm_data_miso(1).rlast,
            AXI_01_RRESP => hbm_data_miso(1).rresp, AXI_01_RVALID => hbm_data_miso(1).rvalid, AXI_01_WREADY => hbm_data_miso(1).wready,
            AXI_01_BID => hbm_data_miso(1).bid(5 DOWNTO 0), AXI_01_BRESP => hbm_data_miso(1).bresp, AXI_01_BVALID => hbm_data_miso(1).bvalid,

            -- Channel 2
            AXI_02_ACLK => hbm_data_clk(0), AXI_02_ARESET_N => hbm_data_rst_n(0),
            AXI_02_ARADDR => hbm_data_mosi(2).araddr(32 DOWNTO 0), AXI_02_ARBURST => hbm_data_mosi(2).arburst(1 DOWNTO 0), AXI_02_ARID => hbm_data_mosi(2).arid(5 DOWNTO 0),
            AXI_02_ARLEN => hbm_data_mosi(2).arlen(3 DOWNTO 0), AXI_02_ARSIZE => hbm_data_mosi(2).arsize(2 DOWNTO 0), AXI_02_ARVALID => hbm_data_mosi(2).arvalid,
            AXI_02_AWADDR => hbm_data_mosi(2).awaddr(32 DOWNTO 0), AXI_02_AWBURST => hbm_data_mosi(2).awburst(1 DOWNTO 0), AXI_02_AWID => hbm_data_mosi(2).awid(5 DOWNTO 0),
            AXI_02_AWLEN => hbm_data_mosi(2).awlen(3 DOWNTO 0), AXI_02_AWSIZE => hbm_data_mosi(2).awsize(2 DOWNTO 0), AXI_02_AWVALID => hbm_data_mosi(2).awvalid,
            AXI_02_RREADY => hbm_data_mosi(2).rready, AXI_02_BREADY => hbm_data_mosi(2).bready, AXI_02_WDATA => hbm_data_mosi(2).wdata(255 DOWNTO 0),
            AXI_02_WLAST => hbm_data_mosi(2).wlast, AXI_02_WSTRB => hbm_data_mosi(2).wstrb(31 DOWNTO 0),
            AXI_02_WDATA_PARITY => hbm_data_mosi(2).wdata(287 DOWNTO 256), AXI_02_WVALID => hbm_data_mosi(2).wvalid,
            AXI_02_ARREADY => hbm_data_miso(2).arready, AXI_02_AWREADY => hbm_data_miso(2).awready, AXI_02_RDATA_PARITY => hbm_data_miso(2).rdata(287 DOWNTO 256),
            AXI_02_RDATA => hbm_data_miso(2).rdata(255 DOWNTO 0), AXI_02_RID => hbm_data_miso(2).rid(5 DOWNTO 0), AXI_02_RLAST => hbm_data_miso(2).rlast,
            AXI_02_RRESP => hbm_data_miso(2).rresp, AXI_02_RVALID => hbm_data_miso(2).rvalid, AXI_02_WREADY => hbm_data_miso(2).wready,
            AXI_02_BID => hbm_data_miso(2).bid(5 DOWNTO 0), AXI_02_BRESP => hbm_data_miso(2).bresp, AXI_02_BVALID => hbm_data_miso(2).bvalid,

            -- Channel 3
            AXI_03_ACLK => hbm_data_clk(0), AXI_03_ARESET_N => hbm_data_rst_n(0),
            AXI_03_ARADDR => hbm_data_mosi(3).araddr(32 DOWNTO 0), AXI_03_ARBURST => hbm_data_mosi(3).arburst(1 DOWNTO 0), AXI_03_ARID => hbm_data_mosi(3).arid(5 DOWNTO 0),
            AXI_03_ARLEN => hbm_data_mosi(3).arlen(3 DOWNTO 0), AXI_03_ARSIZE => hbm_data_mosi(3).arsize(2 DOWNTO 0), AXI_03_ARVALID => hbm_data_mosi(3).arvalid,
            AXI_03_AWADDR => hbm_data_mosi(3).awaddr(32 DOWNTO 0), AXI_03_AWBURST => hbm_data_mosi(3).awburst(1 DOWNTO 0), AXI_03_AWID => hbm_data_mosi(3).awid(5 DOWNTO 0),
            AXI_03_AWLEN => hbm_data_mosi(3).awlen(3 DOWNTO 0), AXI_03_AWSIZE => hbm_data_mosi(3).awsize(2 DOWNTO 0), AXI_03_AWVALID => hbm_data_mosi(3).awvalid,
            AXI_03_RREADY => hbm_data_mosi(3).rready, AXI_03_BREADY => hbm_data_mosi(3).bready, AXI_03_WDATA => hbm_data_mosi(3).wdata(255 DOWNTO 0),
            AXI_03_WLAST => hbm_data_mosi(3).wlast, AXI_03_WSTRB => hbm_data_mosi(3).wstrb(31 DOWNTO 0),
            AXI_03_WDATA_PARITY => hbm_data_mosi(3).wdata(287 DOWNTO 256), AXI_03_WVALID => hbm_data_mosi(3).wvalid,
            AXI_03_ARREADY => hbm_data_miso(3).arready, AXI_03_AWREADY => hbm_data_miso(3).awready, AXI_03_RDATA_PARITY => hbm_data_miso(3).rdata(287 DOWNTO 256),
            AXI_03_RDATA => hbm_data_miso(3).rdata(255 DOWNTO 0), AXI_03_RID => hbm_data_miso(3).rid(5 DOWNTO 0), AXI_03_RLAST => hbm_data_miso(3).rlast,
            AXI_03_RRESP => hbm_data_miso(3).rresp, AXI_03_RVALID => hbm_data_miso(3).rvalid, AXI_03_WREADY => hbm_data_miso(3).wready,
            AXI_03_BID => hbm_data_miso(3).bid(5 DOWNTO 0), AXI_03_BRESP => hbm_data_miso(3).bresp, AXI_03_BVALID => hbm_data_miso(3).bvalid,

            -- Channel 4
            AXI_04_ACLK => hbm_data_clk(0), AXI_04_ARESET_N => hbm_data_rst_n(0),
            AXI_04_ARADDR => hbm_data_mosi(4).araddr(32 DOWNTO 0), AXI_04_ARBURST => hbm_data_mosi(4).arburst(1 DOWNTO 0), AXI_04_ARID => hbm_data_mosi(4).arid(5 DOWNTO 0),
            AXI_04_ARLEN => hbm_data_mosi(4).arlen(3 DOWNTO 0), AXI_04_ARSIZE => hbm_data_mosi(4).arsize(2 DOWNTO 0), AXI_04_ARVALID => hbm_data_mosi(4).arvalid,
            AXI_04_AWADDR => hbm_data_mosi(4).awaddr(32 DOWNTO 0), AXI_04_AWBURST => hbm_data_mosi(4).awburst(1 DOWNTO 0), AXI_04_AWID => hbm_data_mosi(4).awid(5 DOWNTO 0),
            AXI_04_AWLEN => hbm_data_mosi(4).awlen(3 DOWNTO 0), AXI_04_AWSIZE => hbm_data_mosi(4).awsize(2 DOWNTO 0), AXI_04_AWVALID => hbm_data_mosi(4).awvalid,
            AXI_04_RREADY => hbm_data_mosi(4).rready, AXI_04_BREADY => hbm_data_mosi(4).bready, AXI_04_WDATA => hbm_data_mosi(4).wdata(255 DOWNTO 0),
            AXI_04_WLAST => hbm_data_mosi(4).wlast, AXI_04_WSTRB => hbm_data_mosi(4).wstrb(31 DOWNTO 0),
            AXI_04_WDATA_PARITY => hbm_data_mosi(4).wdata(287 DOWNTO 256), AXI_04_WVALID => hbm_data_mosi(4).wvalid,
            AXI_04_ARREADY => hbm_data_miso(4).arready, AXI_04_AWREADY => hbm_data_miso(4).awready, AXI_04_RDATA_PARITY => hbm_data_miso(4).rdata(287 DOWNTO 256),
            AXI_04_RDATA => hbm_data_miso(4).rdata(255 DOWNTO 0), AXI_04_RID => hbm_data_miso(4).rid(5 DOWNTO 0), AXI_04_RLAST => hbm_data_miso(4).rlast,
            AXI_04_RRESP => hbm_data_miso(4).rresp, AXI_04_RVALID => hbm_data_miso(4).rvalid, AXI_04_WREADY => hbm_data_miso(4).wready,
            AXI_04_BID => hbm_data_miso(4).bid(5 DOWNTO 0), AXI_04_BRESP => hbm_data_miso(4).bresp, AXI_04_BVALID => hbm_data_miso(4).bvalid,

            -- Channel 5
            AXI_05_ACLK => hbm_data_clk(0), AXI_05_ARESET_N => hbm_data_rst_n(0),
            AXI_05_ARADDR => hbm_data_mosi(5).araddr(32 DOWNTO 0), AXI_05_ARBURST => hbm_data_mosi(5).arburst(1 DOWNTO 0), AXI_05_ARID => hbm_data_mosi(5).arid(5 DOWNTO 0),
            AXI_05_ARLEN => hbm_data_mosi(5).arlen(3 DOWNTO 0), AXI_05_ARSIZE => hbm_data_mosi(5).arsize(2 DOWNTO 0), AXI_05_ARVALID => hbm_data_mosi(5).arvalid,
            AXI_05_AWADDR => hbm_data_mosi(5).awaddr(32 DOWNTO 0), AXI_05_AWBURST => hbm_data_mosi(5).awburst(1 DOWNTO 0), AXI_05_AWID => hbm_data_mosi(5).awid(5 DOWNTO 0),
            AXI_05_AWLEN => hbm_data_mosi(5).awlen(3 DOWNTO 0), AXI_05_AWSIZE => hbm_data_mosi(5).awsize(2 DOWNTO 0), AXI_05_AWVALID => hbm_data_mosi(5).awvalid,
            AXI_05_RREADY => hbm_data_mosi(5).rready, AXI_05_BREADY => hbm_data_mosi(5).bready, AXI_05_WDATA => hbm_data_mosi(5).wdata(255 DOWNTO 0),
            AXI_05_WLAST => hbm_data_mosi(5).wlast, AXI_05_WSTRB => hbm_data_mosi(5).wstrb(31 DOWNTO 0),
            AXI_05_WDATA_PARITY => hbm_data_mosi(5).wdata(287 DOWNTO 256), AXI_05_WVALID => hbm_data_mosi(5).wvalid,
            AXI_05_ARREADY => hbm_data_miso(5).arready, AXI_05_AWREADY => hbm_data_miso(5).awready, AXI_05_RDATA_PARITY => hbm_data_miso(5).rdata(287 DOWNTO 256),
            AXI_05_RDATA => hbm_data_miso(5).rdata(255 DOWNTO 0), AXI_05_RID => hbm_data_miso(5).rid(5 DOWNTO 0), AXI_05_RLAST => hbm_data_miso(5).rlast,
            AXI_05_RRESP => hbm_data_miso(5).rresp, AXI_05_RVALID => hbm_data_miso(5).rvalid, AXI_05_WREADY => hbm_data_miso(5).wready,
            AXI_05_BID => hbm_data_miso(5).bid(5 DOWNTO 0), AXI_05_BRESP => hbm_data_miso(5).bresp, AXI_05_BVALID => hbm_data_miso(5).bvalid,

            -- Channel 6
            AXI_06_ACLK => hbm_data_clk(0), AXI_06_ARESET_N => hbm_data_rst_n(0),
            AXI_06_ARADDR => hbm_data_mosi(6).araddr(32 DOWNTO 0), AXI_06_ARBURST => hbm_data_mosi(6).arburst(1 DOWNTO 0), AXI_06_ARID => hbm_data_mosi(6).arid(5 DOWNTO 0),
            AXI_06_ARLEN => hbm_data_mosi(6).arlen(3 DOWNTO 0), AXI_06_ARSIZE => hbm_data_mosi(6).arsize(2 DOWNTO 0), AXI_06_ARVALID => hbm_data_mosi(6).arvalid,
            AXI_06_AWADDR => hbm_data_mosi(6).awaddr(32 DOWNTO 0), AXI_06_AWBURST => hbm_data_mosi(6).awburst(1 DOWNTO 0), AXI_06_AWID => hbm_data_mosi(6).awid(5 DOWNTO 0),
            AXI_06_AWLEN => hbm_data_mosi(6).awlen(3 DOWNTO 0), AXI_06_AWSIZE => hbm_data_mosi(6).awsize(2 DOWNTO 0), AXI_06_AWVALID => hbm_data_mosi(6).awvalid,
            AXI_06_RREADY => hbm_data_mosi(6).rready, AXI_06_BREADY => hbm_data_mosi(6).bready, AXI_06_WDATA => hbm_data_mosi(6).wdata(255 DOWNTO 0),
            AXI_06_WLAST => hbm_data_mosi(6).wlast, AXI_06_WSTRB => hbm_data_mosi(6).wstrb(31 DOWNTO 0),
            AXI_06_WDATA_PARITY => hbm_data_mosi(6).wdata(287 DOWNTO 256), AXI_06_WVALID => hbm_data_mosi(6).wvalid,
            AXI_06_ARREADY => hbm_data_miso(6).arready, AXI_06_AWREADY => hbm_data_miso(6).awready, AXI_06_RDATA_PARITY => hbm_data_miso(6).rdata(287 DOWNTO 256),
            AXI_06_RDATA => hbm_data_miso(6).rdata(255 DOWNTO 0), AXI_06_RID => hbm_data_miso(6).rid(5 DOWNTO 0), AXI_06_RLAST => hbm_data_miso(6).rlast,
            AXI_06_RRESP => hbm_data_miso(6).rresp, AXI_06_RVALID => hbm_data_miso(6).rvalid, AXI_06_WREADY => hbm_data_miso(6).wready,
            AXI_06_BID => hbm_data_miso(6).bid(5 DOWNTO 0), AXI_06_BRESP => hbm_data_miso(6).bresp, AXI_06_BVALID => hbm_data_miso(6).bvalid,

            -- Channel 7
            AXI_07_ACLK => hbm_data_clk(0), AXI_07_ARESET_N => hbm_data_rst_n(0),
            AXI_07_ARADDR => hbm_data_mosi(7).araddr(32 DOWNTO 0), AXI_07_ARBURST => hbm_data_mosi(7).arburst(1 DOWNTO 0), AXI_07_ARID => hbm_data_mosi(7).arid(5 DOWNTO 0),
            AXI_07_ARLEN => hbm_data_mosi(7).arlen(3 DOWNTO 0), AXI_07_ARSIZE => hbm_data_mosi(7).arsize(2 DOWNTO 0), AXI_07_ARVALID => hbm_data_mosi(7).arvalid,
            AXI_07_AWADDR => hbm_data_mosi(7).awaddr(32 DOWNTO 0), AXI_07_AWBURST => hbm_data_mosi(7).awburst(1 DOWNTO 0), AXI_07_AWID => hbm_data_mosi(7).awid(5 DOWNTO 0),
            AXI_07_AWLEN => hbm_data_mosi(7).awlen(3 DOWNTO 0), AXI_07_AWSIZE => hbm_data_mosi(7).awsize(2 DOWNTO 0), AXI_07_AWVALID => hbm_data_mosi(7).awvalid,
            AXI_07_RREADY => hbm_data_mosi(7).rready, AXI_07_BREADY => hbm_data_mosi(7).bready, AXI_07_WDATA => hbm_data_mosi(7).wdata(255 DOWNTO 0),
            AXI_07_WLAST => hbm_data_mosi(7).wlast, AXI_07_WSTRB => hbm_data_mosi(7).wstrb(31 DOWNTO 0),
            AXI_07_WDATA_PARITY => hbm_data_mosi(7).wdata(287 DOWNTO 256), AXI_07_WVALID => hbm_data_mosi(7).wvalid,
            AXI_07_ARREADY => hbm_data_miso(7).arready, AXI_07_AWREADY => hbm_data_miso(7).awready, AXI_07_RDATA_PARITY => hbm_data_miso(7).rdata(287 DOWNTO 256),
            AXI_07_RDATA => hbm_data_miso(7).rdata(255 DOWNTO 0), AXI_07_RID => hbm_data_miso(7).rid(5 DOWNTO 0), AXI_07_RLAST => hbm_data_miso(7).rlast,
            AXI_07_RRESP => hbm_data_miso(7).rresp, AXI_07_RVALID => hbm_data_miso(7).rvalid, AXI_07_WREADY => hbm_data_miso(7).wready,
            AXI_07_BID => hbm_data_miso(7).bid(5 DOWNTO 0), AXI_07_BRESP => hbm_data_miso(7).bresp, AXI_07_BVALID => hbm_data_miso(7).bvalid,

            -- Channel 8
            AXI_08_ACLK => hbm_data_clk(0), AXI_08_ARESET_N => hbm_data_rst_n(0),
            AXI_08_ARADDR => hbm_data_mosi(8).araddr(32 DOWNTO 0), AXI_08_ARBURST => hbm_data_mosi(8).arburst(1 DOWNTO 0), AXI_08_ARID => hbm_data_mosi(8).arid(5 DOWNTO 0),
            AXI_08_ARLEN => hbm_data_mosi(8).arlen(3 DOWNTO 0), AXI_08_ARSIZE => hbm_data_mosi(8).arsize(2 DOWNTO 0), AXI_08_ARVALID => hbm_data_mosi(8).arvalid,
            AXI_08_AWADDR => hbm_data_mosi(8).awaddr(32 DOWNTO 0), AXI_08_AWBURST => hbm_data_mosi(8).awburst(1 DOWNTO 0), AXI_08_AWID => hbm_data_mosi(8).awid(5 DOWNTO 0),
            AXI_08_AWLEN => hbm_data_mosi(8).awlen(3 DOWNTO 0), AXI_08_AWSIZE => hbm_data_mosi(8).awsize(2 DOWNTO 0), AXI_08_AWVALID => hbm_data_mosi(8).awvalid,
            AXI_08_RREADY => hbm_data_mosi(8).rready, AXI_08_BREADY => hbm_data_mosi(8).bready, AXI_08_WDATA => hbm_data_mosi(8).wdata(255 DOWNTO 0),
            AXI_08_WLAST => hbm_data_mosi(8).wlast, AXI_08_WSTRB => hbm_data_mosi(8).wstrb(31 DOWNTO 0),
            AXI_08_WDATA_PARITY => hbm_data_mosi(8).wdata(287 DOWNTO 256), AXI_08_WVALID => hbm_data_mosi(8).wvalid,
            AXI_08_ARREADY => hbm_data_miso(8).arready, AXI_08_AWREADY => hbm_data_miso(8).awready, AXI_08_RDATA_PARITY => hbm_data_miso(8).rdata(287 DOWNTO 256),
            AXI_08_RDATA => hbm_data_miso(8).rdata(255 DOWNTO 0), AXI_08_RID => hbm_data_miso(8).rid(5 DOWNTO 0), AXI_08_RLAST => hbm_data_miso(8).rlast,
            AXI_08_RRESP => hbm_data_miso(8).rresp, AXI_08_RVALID => hbm_data_miso(8).rvalid, AXI_08_WREADY => hbm_data_miso(8).wready,
            AXI_08_BID => hbm_data_miso(8).bid(5 DOWNTO 0), AXI_08_BRESP => hbm_data_miso(8).bresp, AXI_08_BVALID => hbm_data_miso(8).bvalid,

            -- Channel 9
            AXI_09_ACLK => hbm_data_clk(0), AXI_09_ARESET_N => hbm_data_rst_n(0),
            AXI_09_ARADDR => hbm_data_mosi(9).araddr(32 DOWNTO 0), AXI_09_ARBURST => hbm_data_mosi(9).arburst(1 DOWNTO 0), AXI_09_ARID => hbm_data_mosi(9).arid(5 DOWNTO 0),
            AXI_09_ARLEN => hbm_data_mosi(9).arlen(3 DOWNTO 0), AXI_09_ARSIZE => hbm_data_mosi(9).arsize(2 DOWNTO 0), AXI_09_ARVALID => hbm_data_mosi(9).arvalid,
            AXI_09_AWADDR => hbm_data_mosi(9).awaddr(32 DOWNTO 0), AXI_09_AWBURST => hbm_data_mosi(9).awburst(1 DOWNTO 0), AXI_09_AWID => hbm_data_mosi(9).awid(5 DOWNTO 0),
            AXI_09_AWLEN => hbm_data_mosi(9).awlen(3 DOWNTO 0), AXI_09_AWSIZE => hbm_data_mosi(9).awsize(2 DOWNTO 0), AXI_09_AWVALID => hbm_data_mosi(9).awvalid,
            AXI_09_RREADY => hbm_data_mosi(9).rready, AXI_09_BREADY => hbm_data_mosi(9).bready, AXI_09_WDATA => hbm_data_mosi(9).wdata(255 DOWNTO 0),
            AXI_09_WLAST => hbm_data_mosi(9).wlast, AXI_09_WSTRB => hbm_data_mosi(9).wstrb(31 DOWNTO 0),
            AXI_09_WDATA_PARITY => hbm_data_mosi(9).wdata(287 DOWNTO 256), AXI_09_WVALID => hbm_data_mosi(9).wvalid,
            AXI_09_ARREADY => hbm_data_miso(9).arready, AXI_09_AWREADY => hbm_data_miso(9).awready, AXI_09_RDATA_PARITY => hbm_data_miso(9).rdata(287 DOWNTO 256),
            AXI_09_RDATA => hbm_data_miso(9).rdata(255 DOWNTO 0), AXI_09_RID => hbm_data_miso(9).rid(5 DOWNTO 0), AXI_09_RLAST => hbm_data_miso(9).rlast,
            AXI_09_RRESP => hbm_data_miso(9).rresp, AXI_09_RVALID => hbm_data_miso(9).rvalid, AXI_09_WREADY => hbm_data_miso(9).wready,
            AXI_09_BID => hbm_data_miso(9).bid(5 DOWNTO 0), AXI_09_BRESP => hbm_data_miso(9).bresp, AXI_09_BVALID => hbm_data_miso(9).bvalid,

            -- Channel 10
            AXI_10_ACLK => hbm_data_clk(0), AXI_10_ARESET_N => hbm_data_rst_n(0),
            AXI_10_ARADDR => hbm_data_mosi(10).araddr(32 DOWNTO 0), AXI_10_ARBURST => hbm_data_mosi(10).arburst(1 DOWNTO 0), AXI_10_ARID => hbm_data_mosi(10).arid(5 DOWNTO 0),
            AXI_10_ARLEN => hbm_data_mosi(10).arlen(3 DOWNTO 0), AXI_10_ARSIZE => hbm_data_mosi(10).arsize(2 DOWNTO 0), AXI_10_ARVALID => hbm_data_mosi(10).arvalid,
            AXI_10_AWADDR => hbm_data_mosi(10).awaddr(32 DOWNTO 0), AXI_10_AWBURST => hbm_data_mosi(10).awburst(1 DOWNTO 0), AXI_10_AWID => hbm_data_mosi(10).awid(5 DOWNTO 0),
            AXI_10_AWLEN => hbm_data_mosi(10).awlen(3 DOWNTO 0), AXI_10_AWSIZE => hbm_data_mosi(10).awsize(2 DOWNTO 0), AXI_10_AWVALID => hbm_data_mosi(10).awvalid,
            AXI_10_RREADY => hbm_data_mosi(10).rready, AXI_10_BREADY => hbm_data_mosi(10).bready, AXI_10_WDATA => hbm_data_mosi(10).wdata(255 DOWNTO 0),
            AXI_10_WLAST => hbm_data_mosi(10).wlast, AXI_10_WSTRB => hbm_data_mosi(10).wstrb(31 DOWNTO 0),
            AXI_10_WDATA_PARITY => hbm_data_mosi(10).wdata(287 DOWNTO 256), AXI_10_WVALID => hbm_data_mosi(10).wvalid,
            AXI_10_ARREADY => hbm_data_miso(10).arready, AXI_10_AWREADY => hbm_data_miso(10).awready, AXI_10_RDATA_PARITY => hbm_data_miso(10).rdata(287 DOWNTO 256),
            AXI_10_RDATA => hbm_data_miso(10).rdata(255 DOWNTO 0), AXI_10_RID => hbm_data_miso(10).rid(5 DOWNTO 0), AXI_10_RLAST => hbm_data_miso(10).rlast,
            AXI_10_RRESP => hbm_data_miso(10).rresp, AXI_10_RVALID => hbm_data_miso(10).rvalid, AXI_10_WREADY => hbm_data_miso(10).wready,
            AXI_10_BID => hbm_data_miso(10).bid(5 DOWNTO 0), AXI_10_BRESP => hbm_data_miso(10).bresp, AXI_10_BVALID => hbm_data_miso(10).bvalid,

            -- Channel 11
            AXI_11_ACLK => hbm_data_clk(0), AXI_11_ARESET_N => hbm_data_rst_n(0),
            AXI_11_ARADDR => hbm_data_mosi(11).araddr(32 DOWNTO 0), AXI_11_ARBURST => hbm_data_mosi(11).arburst(1 DOWNTO 0), AXI_11_ARID => hbm_data_mosi(11).arid(5 DOWNTO 0),
            AXI_11_ARLEN => hbm_data_mosi(11).arlen(3 DOWNTO 0), AXI_11_ARSIZE => hbm_data_mosi(11).arsize(2 DOWNTO 0), AXI_11_ARVALID => hbm_data_mosi(11).arvalid,
            AXI_11_AWADDR => hbm_data_mosi(11).awaddr(32 DOWNTO 0), AXI_11_AWBURST => hbm_data_mosi(11).awburst(1 DOWNTO 0), AXI_11_AWID => hbm_data_mosi(11).awid(5 DOWNTO 0),
            AXI_11_AWLEN => hbm_data_mosi(11).awlen(3 DOWNTO 0), AXI_11_AWSIZE => hbm_data_mosi(11).awsize(2 DOWNTO 0), AXI_11_AWVALID => hbm_data_mosi(11).awvalid,
            AXI_11_RREADY => hbm_data_mosi(11).rready, AXI_11_BREADY => hbm_data_mosi(11).bready, AXI_11_WDATA => hbm_data_mosi(11).wdata(255 DOWNTO 0),
            AXI_11_WLAST => hbm_data_mosi(11).wlast, AXI_11_WSTRB => hbm_data_mosi(11).wstrb(31 DOWNTO 0),
            AXI_11_WDATA_PARITY => hbm_data_mosi(11).wdata(287 DOWNTO 256), AXI_11_WVALID => hbm_data_mosi(11).wvalid,
            AXI_11_ARREADY => hbm_data_miso(11).arready, AXI_11_AWREADY => hbm_data_miso(11).awready, AXI_11_RDATA_PARITY => hbm_data_miso(11).rdata(287 DOWNTO 256),
            AXI_11_RDATA => hbm_data_miso(11).rdata(255 DOWNTO 0), AXI_11_RID => hbm_data_miso(11).rid(5 DOWNTO 0), AXI_11_RLAST => hbm_data_miso(11).rlast,
            AXI_11_RRESP => hbm_data_miso(11).rresp, AXI_11_RVALID => hbm_data_miso(11).rvalid, AXI_11_WREADY => hbm_data_miso(11).wready,
            AXI_11_BID => hbm_data_miso(11).bid(5 DOWNTO 0), AXI_11_BRESP => hbm_data_miso(11).bresp, AXI_11_BVALID => hbm_data_miso(11).bvalid,

            -- Channel 12
            AXI_12_ACLK => hbm_data_clk(0), AXI_12_ARESET_N => hbm_data_rst_n(0),
            AXI_12_ARADDR => hbm_data_mosi(12).araddr(32 DOWNTO 0), AXI_12_ARBURST => hbm_data_mosi(12).arburst(1 DOWNTO 0), AXI_12_ARID => hbm_data_mosi(12).arid(5 DOWNTO 0),
            AXI_12_ARLEN => hbm_data_mosi(12).arlen(3 DOWNTO 0), AXI_12_ARSIZE => hbm_data_mosi(12).arsize(2 DOWNTO 0), AXI_12_ARVALID => hbm_data_mosi(12).arvalid,
            AXI_12_AWADDR => hbm_data_mosi(12).awaddr(32 DOWNTO 0), AXI_12_AWBURST => hbm_data_mosi(12).awburst(1 DOWNTO 0), AXI_12_AWID => hbm_data_mosi(12).awid(5 DOWNTO 0),
            AXI_12_AWLEN => hbm_data_mosi(12).awlen(3 DOWNTO 0), AXI_12_AWSIZE => hbm_data_mosi(12).awsize(2 DOWNTO 0), AXI_12_AWVALID => hbm_data_mosi(12).awvalid,
            AXI_12_RREADY => hbm_data_mosi(12).rready, AXI_12_BREADY => hbm_data_mosi(12).bready, AXI_12_WDATA => hbm_data_mosi(12).wdata(255 DOWNTO 0),
            AXI_12_WLAST => hbm_data_mosi(12).wlast, AXI_12_WSTRB => hbm_data_mosi(12).wstrb(31 DOWNTO 0),
            AXI_12_WDATA_PARITY => hbm_data_mosi(12).wdata(287 DOWNTO 256), AXI_12_WVALID => hbm_data_mosi(12).wvalid,
            AXI_12_ARREADY => hbm_data_miso(12).arready, AXI_12_AWREADY => hbm_data_miso(12).awready, AXI_12_RDATA_PARITY => hbm_data_miso(12).rdata(287 DOWNTO 256),
            AXI_12_RDATA => hbm_data_miso(12).rdata(255 DOWNTO 0), AXI_12_RID => hbm_data_miso(12).rid(5 DOWNTO 0), AXI_12_RLAST => hbm_data_miso(12).rlast,
            AXI_12_RRESP => hbm_data_miso(12).rresp, AXI_12_RVALID => hbm_data_miso(12).rvalid, AXI_12_WREADY => hbm_data_miso(12).wready,
            AXI_12_BID => hbm_data_miso(12).bid(5 DOWNTO 0), AXI_12_BRESP => hbm_data_miso(12).bresp, AXI_12_BVALID => hbm_data_miso(12).bvalid,

            -- Channel 13
            AXI_13_ACLK => hbm_data_clk(0), AXI_13_ARESET_N => hbm_data_rst_n(0),
            AXI_13_ARADDR => hbm_data_mosi(13).araddr(32 DOWNTO 0), AXI_13_ARBURST => hbm_data_mosi(13).arburst(1 DOWNTO 0), AXI_13_ARID => hbm_data_mosi(13).arid(5 DOWNTO 0),
            AXI_13_ARLEN => hbm_data_mosi(13).arlen(3 DOWNTO 0), AXI_13_ARSIZE => hbm_data_mosi(13).arsize(2 DOWNTO 0), AXI_13_ARVALID => hbm_data_mosi(13).arvalid,
            AXI_13_AWADDR => hbm_data_mosi(13).awaddr(32 DOWNTO 0), AXI_13_AWBURST => hbm_data_mosi(13).awburst(1 DOWNTO 0), AXI_13_AWID => hbm_data_mosi(13).awid(5 DOWNTO 0),
            AXI_13_AWLEN => hbm_data_mosi(13).awlen(3 DOWNTO 0), AXI_13_AWSIZE => hbm_data_mosi(13).awsize(2 DOWNTO 0), AXI_13_AWVALID => hbm_data_mosi(13).awvalid,
            AXI_13_RREADY => hbm_data_mosi(13).rready, AXI_13_BREADY => hbm_data_mosi(13).bready, AXI_13_WDATA => hbm_data_mosi(13).wdata(255 DOWNTO 0),
            AXI_13_WLAST => hbm_data_mosi(13).wlast, AXI_13_WSTRB => hbm_data_mosi(13).wstrb(31 DOWNTO 0),
            AXI_13_WDATA_PARITY => hbm_data_mosi(13).wdata(287 DOWNTO 256), AXI_13_WVALID => hbm_data_mosi(13).wvalid,
            AXI_13_ARREADY => hbm_data_miso(13).arready, AXI_13_AWREADY => hbm_data_miso(13).awready, AXI_13_RDATA_PARITY => hbm_data_miso(13).rdata(287 DOWNTO 256),
            AXI_13_RDATA => hbm_data_miso(13).rdata(255 DOWNTO 0), AXI_13_RID => hbm_data_miso(13).rid(5 DOWNTO 0), AXI_13_RLAST => hbm_data_miso(13).rlast,
            AXI_13_RRESP => hbm_data_miso(13).rresp, AXI_13_RVALID => hbm_data_miso(13).rvalid, AXI_13_WREADY => hbm_data_miso(13).wready,
            AXI_13_BID => hbm_data_miso(13).bid(5 DOWNTO 0), AXI_13_BRESP => hbm_data_miso(13).bresp, AXI_13_BVALID => hbm_data_miso(13).bvalid,

            -- Channel 14
            AXI_14_ACLK => hbm_data_clk(0), AXI_14_ARESET_N => hbm_data_rst_n(0),
            AXI_14_ARADDR => hbm_data_mosi(14).araddr(32 DOWNTO 0), AXI_14_ARBURST => hbm_data_mosi(14).arburst(1 DOWNTO 0), AXI_14_ARID => hbm_data_mosi(14).arid(5 DOWNTO 0),
            AXI_14_ARLEN => hbm_data_mosi(14).arlen(3 DOWNTO 0), AXI_14_ARSIZE => hbm_data_mosi(14).arsize(2 DOWNTO 0), AXI_14_ARVALID => hbm_data_mosi(14).arvalid,
            AXI_14_AWADDR => hbm_data_mosi(14).awaddr(32 DOWNTO 0), AXI_14_AWBURST => hbm_data_mosi(14).awburst(1 DOWNTO 0), AXI_14_AWID => hbm_data_mosi(14).awid(5 DOWNTO 0),
            AXI_14_AWLEN => hbm_data_mosi(14).awlen(3 DOWNTO 0), AXI_14_AWSIZE => hbm_data_mosi(14).awsize(2 DOWNTO 0), AXI_14_AWVALID => hbm_data_mosi(14).awvalid,
            AXI_14_RREADY => hbm_data_mosi(14).rready, AXI_14_BREADY => hbm_data_mosi(14).bready, AXI_14_WDATA => hbm_data_mosi(14).wdata(255 DOWNTO 0),
            AXI_14_WLAST => hbm_data_mosi(14).wlast, AXI_14_WSTRB => hbm_data_mosi(14).wstrb(31 DOWNTO 0),
            AXI_14_WDATA_PARITY => hbm_data_mosi(14).wdata(287 DOWNTO 256), AXI_14_WVALID => hbm_data_mosi(14).wvalid,
            AXI_14_ARREADY => hbm_data_miso(14).arready, AXI_14_AWREADY => hbm_data_miso(14).awready, AXI_14_RDATA_PARITY => hbm_data_miso(14).rdata(287 DOWNTO 256),
            AXI_14_RDATA => hbm_data_miso(14).rdata(255 DOWNTO 0), AXI_14_RID => hbm_data_miso(14).rid(5 DOWNTO 0), AXI_14_RLAST => hbm_data_miso(14).rlast,
            AXI_14_RRESP => hbm_data_miso(14).rresp, AXI_14_RVALID => hbm_data_miso(14).rvalid, AXI_14_WREADY => hbm_data_miso(14).wready,
            AXI_14_BID => hbm_data_miso(14).bid(5 DOWNTO 0), AXI_14_BRESP => hbm_data_miso(14).bresp, AXI_14_BVALID => hbm_data_miso(14).bvalid,


            -- Channel 15
            AXI_15_ACLK => hbm_data_clk(0), AXI_15_ARESET_N => hbm_data_rst_n(0),
            AXI_15_ARADDR => hbm_data_mosi(15).araddr(32 DOWNTO 0), AXI_15_ARBURST => hbm_data_mosi(15).arburst(1 DOWNTO 0), AXI_15_ARID => hbm_data_mosi(15).arid(5 DOWNTO 0),
            AXI_15_ARLEN => hbm_data_mosi(15).arlen(3 DOWNTO 0), AXI_15_ARSIZE => hbm_data_mosi(15).arsize(2 DOWNTO 0), AXI_15_ARVALID => hbm_data_mosi(15).arvalid,
            AXI_15_AWADDR => hbm_data_mosi(15).awaddr(32 DOWNTO 0), AXI_15_AWBURST => hbm_data_mosi(15).awburst(1 DOWNTO 0), AXI_15_AWID => hbm_data_mosi(15).awid(5 DOWNTO 0),
            AXI_15_AWLEN => hbm_data_mosi(15).awlen(3 DOWNTO 0), AXI_15_AWSIZE => hbm_data_mosi(15).awsize(2 DOWNTO 0), AXI_15_AWVALID => hbm_data_mosi(15).awvalid,
            AXI_15_RREADY => hbm_data_mosi(15).rready, AXI_15_BREADY => hbm_data_mosi(15).bready, AXI_15_WDATA => hbm_data_mosi(15).wdata(255 DOWNTO 0),
            AXI_15_WLAST => hbm_data_mosi(15).wlast, AXI_15_WSTRB => hbm_data_mosi(15).wstrb(31 DOWNTO 0),
            AXI_15_WDATA_PARITY => hbm_data_mosi(15).wdata(287 DOWNTO 256), AXI_15_WVALID => hbm_data_mosi(15).wvalid,
            AXI_15_ARREADY => hbm_data_miso(15).arready, AXI_15_AWREADY => hbm_data_miso(15).awready, AXI_15_RDATA_PARITY => hbm_data_miso(15).rdata(287 DOWNTO 256),
            AXI_15_RDATA => hbm_data_miso(15).rdata(255 DOWNTO 0), AXI_15_RID => hbm_data_miso(15).rid(5 DOWNTO 0), AXI_15_RLAST => hbm_data_miso(15).rlast,
            AXI_15_RRESP => hbm_data_miso(15).rresp, AXI_15_RVALID => hbm_data_miso(15).rvalid, AXI_15_WREADY => hbm_data_miso(15).wready,
            AXI_15_BID => hbm_data_miso(15).bid(5 DOWNTO 0), AXI_15_BRESP => hbm_data_miso(15).bresp, AXI_15_BVALID => hbm_data_miso(15).bvalid,

            -- Control
            APB_0_PCLK => apb_clk, APB_0_PRESET_N => apb_rst_n,
            APB_0_PADDR => apb_paddr, APB_0_PWDATA => apb_pwdata, APB_0_PENABLE => apb_penable, APB_0_PSEL => apb_psel, APB_0_PWRITE => apb_pwrite,
            APB_0_PRDATA => apb_prdata, APB_0_PREADY => apb_pready, APB_0_PSLVERR => apb_pslverr, apb_complete_0 => OPEN,

            DRAM_0_STAT_CATTRIP => temperature_failure, DRAM_0_STAT_TEMP => OPEN);

      END GENERATE;



   END GENERATE;








END str;





