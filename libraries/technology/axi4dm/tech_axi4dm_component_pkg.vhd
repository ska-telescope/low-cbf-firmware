LIBRARY IEEE, tech_axi4dm_lib;
USE IEEE.std_logic_1164.ALL;

PACKAGE tech_axi4dm_component_pkg IS

    CONSTANT c_axi4dm_cmd_w : INTEGER := 72;
    CONSTANT c_axi4dm_sts_w : INTEGER := 8;
    CONSTANT c_axi4dm_sda_w : INTEGER := 32;  -- Streaming data

    COMPONENT axi4dm_32
    PORT (
        m_axi_mm2s_aclk : IN STD_LOGIC;
        m_axi_mm2s_aresetn : IN STD_LOGIC;
        mm2s_err : OUT STD_LOGIC;
        m_axis_mm2s_cmdsts_aclk : IN STD_LOGIC;
        m_axis_mm2s_cmdsts_aresetn : IN STD_LOGIC;
        s_axis_mm2s_cmd_tvalid : IN STD_LOGIC;
        s_axis_mm2s_cmd_tready : OUT STD_LOGIC;
        s_axis_mm2s_cmd_tdata : IN STD_LOGIC_VECTOR(71 DOWNTO 0);
        m_axis_mm2s_sts_tvalid : OUT STD_LOGIC;
        m_axis_mm2s_sts_tready : IN STD_LOGIC;
        m_axis_mm2s_sts_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        m_axis_mm2s_sts_tkeep : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        m_axis_mm2s_sts_tlast : OUT STD_LOGIC;
        m_axi_mm2s_araddr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axi_mm2s_arlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        m_axi_mm2s_arsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        m_axi_mm2s_arburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        m_axi_mm2s_arprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        m_axi_mm2s_arcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_mm2s_aruser : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_mm2s_arvalid : OUT STD_LOGIC;
        m_axi_mm2s_arready : IN STD_LOGIC;
        m_axi_mm2s_rdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axi_mm2s_rresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        m_axi_mm2s_rlast : IN STD_LOGIC;
        m_axi_mm2s_rvalid : IN STD_LOGIC;
        m_axi_mm2s_rready : OUT STD_LOGIC;
        m_axis_mm2s_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axis_mm2s_tkeep : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axis_mm2s_tlast : OUT STD_LOGIC;
        m_axis_mm2s_tvalid : OUT STD_LOGIC;
        m_axis_mm2s_tready : IN STD_LOGIC;
--        m_axi_mm2s_arid    : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        m_axi_s2mm_aclk : IN STD_LOGIC;
        m_axi_s2mm_aresetn : IN STD_LOGIC;
--        m_axi_s2mm_awid : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        s2mm_err : OUT STD_LOGIC;
        m_axis_s2mm_cmdsts_awclk : IN STD_LOGIC;
        m_axis_s2mm_cmdsts_aresetn : IN STD_LOGIC;
        s_axis_s2mm_cmd_tvalid : IN STD_LOGIC;
        s_axis_s2mm_cmd_tready : OUT STD_LOGIC;
        s_axis_s2mm_cmd_tdata : IN STD_LOGIC_VECTOR(71 DOWNTO 0);
        m_axis_s2mm_sts_tvalid : OUT STD_LOGIC;
        m_axis_s2mm_sts_tready : IN STD_LOGIC;
        m_axis_s2mm_sts_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        m_axis_s2mm_sts_tkeep : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        m_axis_s2mm_sts_tlast : OUT STD_LOGIC;
        m_axi_s2mm_awaddr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axi_s2mm_awlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        m_axi_s2mm_awsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        m_axi_s2mm_awburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        m_axi_s2mm_awprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        m_axi_s2mm_awcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_s2mm_awuser : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_s2mm_awvalid : OUT STD_LOGIC;
        m_axi_s2mm_awready : IN STD_LOGIC;
        m_axi_s2mm_wdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axi_s2mm_wstrb : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_s2mm_wlast : OUT STD_LOGIC;
        m_axi_s2mm_wvalid : OUT STD_LOGIC;
        m_axi_s2mm_wready : IN STD_LOGIC;
        m_axi_s2mm_bresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        m_axi_s2mm_bvalid : IN STD_LOGIC;
        m_axi_s2mm_bready : OUT STD_LOGIC;
        s_axis_s2mm_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axis_s2mm_tkeep : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axis_s2mm_tlast : IN STD_LOGIC;
        s_axis_s2mm_tvalid : IN STD_LOGIC;
        s_axis_s2mm_tready : OUT STD_LOGIC
    );
    END COMPONENT;

END tech_axi4dm_component_pkg;

