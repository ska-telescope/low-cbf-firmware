LIBRARY IEEE, technology_lib, common_lib, axi4_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE axi4_lib.axi4_full_pkg.ALL;
USE work.tech_ddr4_component_pkg.ALL;

ENTITY tech_ddr4 IS
   GENERIC (
      g_technology         : t_technology);
   PORT (
      sys_clk_p            : IN STD_LOGIC;                           -- DDR4 clock
      sys_clk_n            : IN STD_LOGIC;

      sys_rst              : IN STD_LOGIC;                           -- Reste to whole memory block
      areset_n             : IN STD_LOGIC;                           -- Reset to AXI shim

      ui_clk               : OUT STD_LOGIC;                          -- User clock (derived from DDR4 system clock)
      ui_clk_sync_rst      : OUT STD_LOGIC;                          -- User reset output

      init_calib_complete  : OUT STD_LOGIC;                          -- Memory block ready

      -- AXI Interface
      axi4_mosi            : IN t_axi4_full_mosi;
      axi4_miso            : OUT t_axi4_full_miso;

      -- DDR Memory interface
      ddr4_reset_n         : OUT STD_LOGIC;
      ddr4_cke             : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      ddr4_ck_c            : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      ddr4_ck_t            : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);

      ddr4_bg              : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      ddr4_ba              : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      ddr4_adr             : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
      ddr4_act_n           : OUT STD_LOGIC;
      ddr4_cs_n            : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      ddr4_odt             : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);

      ddr4_dm_dbi_n        : INOUT STD_LOGIC_VECTOR(8 DOWNTO 0);
      ddr4_dq              : INOUT STD_LOGIC_VECTOR(71 DOWNTO 0);
      ddr4_dqs_c           : INOUT STD_LOGIC_VECTOR(8 DOWNTO 0);
      ddr4_dqs_t           : INOUT STD_LOGIC_VECTOR(8 DOWNTO 0));
END tech_ddr4;

ARCHITECTURE str OF tech_ddr4 IS



BEGIN

   gen_ip_gemini_lru: IF tech_is_board(g_technology, c_tech_board_gemini_lru) OR tech_is_board(g_technology, c_tech_board_gemini_xh_lru) GENERATE

      ddr4_1: gemini_ddr4
      PORT MAP (
         c0_init_calib_complete => init_calib_complete, dbg_clk => open, dbg_bus => open,
         c0_sys_clk_p => sys_clk_p, c0_sys_clk_n => sys_clk_n, sys_rst => sys_rst,
         c0_ddr4_adr => ddr4_adr, c0_ddr4_ba => ddr4_ba, c0_ddr4_cke => ddr4_cke,
         c0_ddr4_cs_n => ddr4_cs_n, c0_ddr4_dm_dbi_n => ddr4_dm_dbi_n, c0_ddr4_dq => ddr4_dq,
         c0_ddr4_dqs_c => ddr4_dqs_c, c0_ddr4_dqs_t => ddr4_dqs_t, c0_ddr4_odt => ddr4_odt,
         c0_ddr4_bg => ddr4_bg, c0_ddr4_reset_n => ddr4_reset_n, c0_ddr4_act_n => ddr4_act_n,
         c0_ddr4_ck_c => ddr4_ck_c, c0_ddr4_ck_t => ddr4_ck_t, c0_ddr4_ui_clk => ui_clk,
         c0_ddr4_ui_clk_sync_rst => ui_clk_sync_rst, c0_ddr4_aresetn => areset_n,
         c0_ddr4_interrupt => open,

         -- AXI4 Lite Interface for ECC control (disabled)
         c0_ddr4_s_axi_ctrl_awvalid => '0', c0_ddr4_s_axi_ctrl_awready => open,
         c0_ddr4_s_axi_ctrl_awaddr => X"00000000", c0_ddr4_s_axi_ctrl_wvalid => '0',
         c0_ddr4_s_axi_ctrl_wready => open, c0_ddr4_s_axi_ctrl_wdata => X"00000000",
         c0_ddr4_s_axi_ctrl_bvalid => open, c0_ddr4_s_axi_ctrl_bready => '1',
         c0_ddr4_s_axi_ctrl_bresp => open, c0_ddr4_s_axi_ctrl_arvalid => '0',
         c0_ddr4_s_axi_ctrl_arready => open, c0_ddr4_s_axi_ctrl_araddr => X"00000000",
         c0_ddr4_s_axi_ctrl_rvalid => open, c0_ddr4_s_axi_ctrl_rready => '1',
         c0_ddr4_s_axi_ctrl_rdata => open, c0_ddr4_s_axi_ctrl_rresp => open,

         -- AXI4 Main Interface
         c0_ddr4_s_axi_awid => axi4_mosi.awid(3 DOWNTO 0), c0_ddr4_s_axi_awaddr => axi4_mosi.awaddr(32 DOWNTO 0),
         c0_ddr4_s_axi_awlen => axi4_mosi.awlen(7 DOWNTO 0), c0_ddr4_s_axi_awsize => axi4_mosi.awsize(2 DOWNTO 0),
         c0_ddr4_s_axi_awburst => axi4_mosi.awburst, c0_ddr4_s_axi_awlock => "0",
         c0_ddr4_s_axi_awcache => "0011", c0_ddr4_s_axi_awprot => "000", c0_ddr4_s_axi_awqos => "0000",
         c0_ddr4_s_axi_awvalid => axi4_mosi.awvalid, c0_ddr4_s_axi_awready => axi4_miso.awready,
         c0_ddr4_s_axi_wdata => axi4_mosi.wdata(511 DOWNTO 0), c0_ddr4_s_axi_wstrb => axi4_mosi.wstrb(63 DOWNTO 0),
         c0_ddr4_s_axi_wlast => axi4_mosi.wlast, c0_ddr4_s_axi_wvalid => axi4_mosi.wvalid,
         c0_ddr4_s_axi_wready => axi4_miso.wready, c0_ddr4_s_axi_bready => axi4_mosi.bready,
         c0_ddr4_s_axi_bid => axi4_miso.bid(3 DOWNTO 0), c0_ddr4_s_axi_bresp => axi4_miso.bresp,
         c0_ddr4_s_axi_bvalid => axi4_miso.bvalid, c0_ddr4_s_axi_arid => axi4_mosi.arid(3 DOWNTO 0),
         c0_ddr4_s_axi_araddr => axi4_mosi.araddr(32 DOWNTO 0), c0_ddr4_s_axi_arlen => axi4_mosi.arlen(7 DOWNTO 0),
         c0_ddr4_s_axi_arsize => axi4_mosi.arsize(2 DOWNTO 0), c0_ddr4_s_axi_arburst => axi4_mosi.arburst,
         c0_ddr4_s_axi_arlock => "0", c0_ddr4_s_axi_arcache => "0011",
         c0_ddr4_s_axi_arprot => "000", c0_ddr4_s_axi_arqos => "0000",
         c0_ddr4_s_axi_arvalid => axi4_mosi.arvalid, c0_ddr4_s_axi_arready => axi4_miso.arready,
         c0_ddr4_s_axi_rready => axi4_mosi.rready, c0_ddr4_s_axi_rlast => axi4_miso.rlast,
         c0_ddr4_s_axi_rvalid => axi4_miso.rvalid, c0_ddr4_s_axi_rresp => axi4_miso.rresp,
         c0_ddr4_s_axi_rid => axi4_miso.rid(3 DOWNTO 0), c0_ddr4_s_axi_rdata => axi4_miso.rdata(511 DOWNTO 0));
END GENERATE;




END str;





