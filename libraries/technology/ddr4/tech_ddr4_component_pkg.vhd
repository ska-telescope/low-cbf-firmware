LIBRARY IEEE, technology_lib, common_lib;
USE IEEE.std_logic_1164.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_interface_layers_pkg.ALL;
USE technology_lib.technology_pkg.ALL;


PACKAGE tech_ddr4_component_pkg IS




COMPONENT gemini_ddr4
  PORT (
    c0_init_calib_complete : OUT STD_LOGIC;
    dbg_clk : OUT STD_LOGIC;
    c0_sys_clk_p : IN STD_LOGIC;
    c0_sys_clk_n : IN STD_LOGIC;
    dbg_bus : OUT STD_LOGIC_VECTOR(511 DOWNTO 0);
    c0_ddr4_adr : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    c0_ddr4_ba : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    c0_ddr4_cke : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    c0_ddr4_cs_n : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    c0_ddr4_dm_dbi_n : INOUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    c0_ddr4_dq : INOUT STD_LOGIC_VECTOR(71 DOWNTO 0);
    c0_ddr4_dqs_c : INOUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    c0_ddr4_dqs_t : INOUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    c0_ddr4_odt : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    c0_ddr4_bg : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    c0_ddr4_reset_n : OUT STD_LOGIC;
    c0_ddr4_act_n : OUT STD_LOGIC;
    c0_ddr4_ck_c : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    c0_ddr4_ck_t : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    c0_ddr4_ui_clk : OUT STD_LOGIC;
    c0_ddr4_ui_clk_sync_rst : OUT STD_LOGIC;
    c0_ddr4_aresetn : IN STD_LOGIC;
    c0_ddr4_s_axi_ctrl_awvalid : IN STD_LOGIC;
    c0_ddr4_s_axi_ctrl_awready : OUT STD_LOGIC;
    c0_ddr4_s_axi_ctrl_awaddr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    c0_ddr4_s_axi_ctrl_wvalid : IN STD_LOGIC;
    c0_ddr4_s_axi_ctrl_wready : OUT STD_LOGIC;
    c0_ddr4_s_axi_ctrl_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    c0_ddr4_s_axi_ctrl_bvalid : OUT STD_LOGIC;
    c0_ddr4_s_axi_ctrl_bready : IN STD_LOGIC;
    c0_ddr4_s_axi_ctrl_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    c0_ddr4_s_axi_ctrl_arvalid : IN STD_LOGIC;
    c0_ddr4_s_axi_ctrl_arready : OUT STD_LOGIC;
    c0_ddr4_s_axi_ctrl_araddr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    c0_ddr4_s_axi_ctrl_rvalid : OUT STD_LOGIC;
    c0_ddr4_s_axi_ctrl_rready : IN STD_LOGIC;
    c0_ddr4_s_axi_ctrl_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    c0_ddr4_s_axi_ctrl_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    c0_ddr4_interrupt : OUT STD_LOGIC;
    c0_ddr4_s_axi_awid : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    c0_ddr4_s_axi_awaddr : IN STD_LOGIC_VECTOR(32 DOWNTO 0);
    c0_ddr4_s_axi_awlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    c0_ddr4_s_axi_awsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    c0_ddr4_s_axi_awburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    c0_ddr4_s_axi_awlock : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    c0_ddr4_s_axi_awcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    c0_ddr4_s_axi_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    c0_ddr4_s_axi_awqos : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    c0_ddr4_s_axi_awvalid : IN STD_LOGIC;
    c0_ddr4_s_axi_awready : OUT STD_LOGIC;
    c0_ddr4_s_axi_wdata : IN STD_LOGIC_VECTOR(511 DOWNTO 0);
    c0_ddr4_s_axi_wstrb : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    c0_ddr4_s_axi_wlast : IN STD_LOGIC;
    c0_ddr4_s_axi_wvalid : IN STD_LOGIC;
    c0_ddr4_s_axi_wready : OUT STD_LOGIC;
    c0_ddr4_s_axi_bready : IN STD_LOGIC;
    c0_ddr4_s_axi_bid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    c0_ddr4_s_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    c0_ddr4_s_axi_bvalid : OUT STD_LOGIC;
    c0_ddr4_s_axi_arid : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    c0_ddr4_s_axi_araddr : IN STD_LOGIC_VECTOR(32 DOWNTO 0);
    c0_ddr4_s_axi_arlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    c0_ddr4_s_axi_arsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    c0_ddr4_s_axi_arburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    c0_ddr4_s_axi_arlock : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    c0_ddr4_s_axi_arcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    c0_ddr4_s_axi_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    c0_ddr4_s_axi_arqos : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    c0_ddr4_s_axi_arvalid : IN STD_LOGIC;
    c0_ddr4_s_axi_arready : OUT STD_LOGIC;
    c0_ddr4_s_axi_rready : IN STD_LOGIC;
    c0_ddr4_s_axi_rlast : OUT STD_LOGIC;
    c0_ddr4_s_axi_rvalid : OUT STD_LOGIC;
    c0_ddr4_s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    c0_ddr4_s_axi_rid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    c0_ddr4_s_axi_rdata : OUT STD_LOGIC_VECTOR(511 DOWNTO 0);
    sys_rst : IN STD_LOGIC
  );
END COMPONENT;


END tech_ddr4_component_pkg;

