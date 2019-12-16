LIBRARY IEEE, technology_lib, axi4_lib;
USE IEEE.std_logic_1164.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE axi4_lib.axi4_full_pkg.ALL;
USE work.tech_axi4dm_component_pkg.ALL;

ENTITY tech_axi4dm IS
    GENERIC (
        g_technology : t_technology := c_tech_select_default
    );
    PORT (
        -- MM2S clks, resets and err
        mm2s_aclk : IN STD_LOGIC;
        mm2s_aresetn : IN STD_LOGIC;
        mm2s_cmdsts_aclk : IN STD_LOGIC;
        mm2s_cmdsts_aresetn : IN STD_LOGIC;
        mm2s_err : OUT STD_LOGIC;
        -- S2MM clks, resets and err
        s2mm_aclk : IN STD_LOGIC;
        s2mm_aresetn : IN STD_LOGIC;
        s2mm_cmdsts_awclk : IN STD_LOGIC;
        s2mm_cmdsts_aresetn : IN STD_LOGIC;
        s2mm_err : OUT STD_LOGIC;
        -- AXI4 Master: MM bus
        -- MM2S acts as master for MM bus read signals
        -- S2MM acts as master for MM bus write signals
        mm_in : IN t_axi4_full_miso;  -- Master in
        mm_out : OUT t_axi4_full_mosi; -- Master out
        -- AXI4S Sink: S2MM Stream data
        s2mm_in : IN t_axi4_sosi;  -- Sink in
        s2mm_out : OUT t_axi4_siso; -- Sink out
        -- AXI4S Sink: S2MM Command
        s2mm_cmd_in : IN t_axi4_sosi; -- Sink in
        s2mm_cmd_out : OUT t_axi4_siso; -- Sink out
        -- AXI4 Sink: MM2S Command
        mm2s_cmd_in : IN t_axi4_sosi; -- Sink in
        mm2s_cmd_out : OUT t_axi4_siso; -- Sink out
        -- AXI4S Source: M_AXIS_S2MM_STS
        s2mm_sts_in : IN t_axi4_siso;  -- Source in
        s2mm_sts_out : OUT t_axi4_sosi;  -- Source out
        -- AXI4S Source: M_AXIS_MM2S_STS
        mm2s_sts_in : IN t_axi4_siso;  -- Source in
        mm2s_sts_out : OUT t_axi4_sosi;  -- Source out
        -- AXI4 Source: M_AXIS_MM2S
        mm2s_in : IN t_axi4_siso;  -- Source in
        mm2s_out : OUT t_axi4_sosi  -- Source out
    );
END tech_axi4dm;

ARCHITECTURE wrapper OF tech_axi4dm IS

BEGIN

--gen_ip_kcu105: IF tech_is_board(g_technology, c_tech_board_kcu105) OR  tech_is_board(g_technology, c_tech_board_gemini_lru) OR tech_is_board(g_technology, c_tech_board_kcu116) OR  tech_is_board(g_technology, c_tech_board_gemini_xh_lru) GENERATE

      u_axi4dm_32 : axi4dm_32
      PORT MAP (
         m_axi_mm2s_aclk            => mm2s_aclk,
         m_axi_mm2s_aresetn         => mm2s_aresetn,
         mm2s_err                   => mm2s_err,
         m_axis_mm2s_cmdsts_aclk    => mm2s_cmdsts_aclk,
         m_axis_mm2s_cmdsts_aresetn => mm2s_cmdsts_aresetn,
         s_axis_mm2s_cmd_tvalid     => mm2s_cmd_in.tvalid,
         s_axis_mm2s_cmd_tready     => mm2s_cmd_out.tready,
         s_axis_mm2s_cmd_tdata      => mm2s_cmd_in.tdata(c_axi4dm_cmd_w-1 DOWNTO 0),
         m_axis_mm2s_sts_tvalid     => mm2s_sts_out.tvalid,
         m_axis_mm2s_sts_tready     => mm2s_sts_in.tready,
         m_axis_mm2s_sts_tdata      => mm2s_sts_out.tdata(c_axi4dm_sts_w-1 DOWNTO 0),
         m_axis_mm2s_sts_tkeep      => mm2s_sts_out.tkeep(c_axi4dm_sts_w/8-1 DOWNTO 0),
         m_axis_mm2s_sts_tlast      => mm2s_sts_out.tlast,
         m_axi_mm2s_araddr          => mm_out.araddr(31 DOWNTO 0),
         m_axi_mm2s_arlen           => mm_out.arlen,
         m_axi_mm2s_arsize          => mm_out.arsize,
         m_axi_mm2s_arburst         => mm_out.arburst,
         m_axi_mm2s_arprot          => mm_out.arprot,
         m_axi_mm2s_arcache         => mm_out.arcache,
         m_axi_mm2s_aruser          => mm_out.aruser,
         m_axi_mm2s_arvalid         => mm_out.arvalid,
         m_axi_mm2s_arready         => mm_in.arready,
         m_axi_mm2s_rdata           => mm_in.rdata(31 DOWNTO 0),
         m_axi_mm2s_rresp           => mm_in.rresp,
         m_axi_mm2s_rlast           => mm_in.rlast,
         m_axi_mm2s_rvalid          => mm_in.rvalid,
         m_axi_mm2s_rready          => mm_out.rready,
         m_axis_mm2s_tdata          => mm2s_out.tdata(c_axi4dm_sda_w-1 DOWNTO 0),
         m_axis_mm2s_tkeep          => mm2s_out.tkeep(c_axi4dm_sda_w/8-1 DOWNTO 0),
         m_axis_mm2s_tlast          => mm2s_out.tlast,
         m_axis_mm2s_tvalid         => mm2s_out.tvalid,
         m_axis_mm2s_tready         => mm2s_in.tready,
--         m_axi_mm2s_arid            => mm_out.arid(0 DOWNTO 0),
         m_axi_s2mm_aclk            => s2mm_aclk,
         m_axi_s2mm_aresetn         => s2mm_aresetn,
         s2mm_err                   => s2mm_err,
         m_axis_s2mm_cmdsts_awclk   => s2mm_cmdsts_awclk,
         m_axis_s2mm_cmdsts_aresetn => s2mm_cmdsts_aresetn,
         s_axis_s2mm_cmd_tvalid     => s2mm_cmd_in.tvalid,
         s_axis_s2mm_cmd_tready     => s2mm_cmd_out.tready,
         s_axis_s2mm_cmd_tdata      => s2mm_cmd_in.tdata(c_axi4dm_cmd_w-1 DOWNTO 0),
         m_axis_s2mm_sts_tvalid     => s2mm_sts_out.tvalid,
         m_axis_s2mm_sts_tready     => s2mm_sts_in.tready,
         m_axis_s2mm_sts_tdata      => s2mm_sts_out.tdata(c_axi4dm_sts_w-1 DOWNTO 0),
         m_axis_s2mm_sts_tkeep      => s2mm_sts_out.tkeep(c_axi4dm_sts_w/8-1 DOWNTO 0),
         m_axis_s2mm_sts_tlast      => s2mm_sts_out.tlast,
         m_axi_s2mm_awaddr          => mm_out.awaddr(31 DOWNTO 0),
--         m_axi_s2mm_awid            => mm_out.awid(0 DOWNTO 0),
         m_axi_s2mm_awlen           => mm_out.awlen,
         m_axi_s2mm_awsize          => mm_out.awsize,
         m_axi_s2mm_awburst         => mm_out.awburst,
         m_axi_s2mm_awprot          => mm_out.awprot,
         m_axi_s2mm_awcache         => mm_out.awcache,
         m_axi_s2mm_awuser          => mm_out.awuser,
         m_axi_s2mm_awvalid         => mm_out.awvalid,
         m_axi_s2mm_awready         => mm_in.awready,
         m_axi_s2mm_wdata           => mm_out.wdata(31 DOWNTO 0),
         m_axi_s2mm_wstrb           => mm_out.wstrb(3 DOWNTO 0),
         m_axi_s2mm_wlast           => mm_out.wlast,
         m_axi_s2mm_wvalid          => mm_out.wvalid,
         m_axi_s2mm_wready          => mm_in.wready,
         m_axi_s2mm_bresp           => mm_in.bresp,
         m_axi_s2mm_bvalid          => mm_in.bvalid,
         m_axi_s2mm_bready          => mm_out.bready,
         s_axis_s2mm_tdata          => s2mm_in.tdata(c_axi4dm_sda_w-1 DOWNTO 0),
         s_axis_s2mm_tkeep          => s2mm_in.tkeep(c_axi4dm_sda_w/8-1 DOWNTO 0),
         s_axis_s2mm_tlast          => s2mm_in.tlast,
         s_axis_s2mm_tvalid         => s2mm_in.tvalid,
         s_axis_s2mm_tready         => s2mm_out.tready);

--   end generate;

   mm_out.awlock <= '0';
   mm_out.arlock <= '0';

END wrapper;



