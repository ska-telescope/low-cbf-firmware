LIBRARY IEEE, technology_lib, axi4_lib;
USE IEEE.std_logic_1164.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE axi4_lib.axi4_full_pkg.ALL;
USE work.tech_axi4_infrastructure_component_pkg.ALL;

ENTITY tech_axi4_ila IS
   GENERIC (
      g_technology   : t_technology := c_tech_select_default);
   PORT (
      m_clk          : IN STD_LOGIC;
      m_axi_miso     : IN t_axi4_full_miso;
      m_axi_mosi     : IN t_axi4_full_mosi);
END tech_axi4_ila;

ARCHITECTURE wrapper OF tech_axi4_ila IS

--   COMPONENT axi4_ila
--      PORT ( 
--         clk : in STD_LOGIC;
--    probe0 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe1 : in STD_LOGIC_VECTOR ( 31 downto 0 );
--    probe2 : in STD_LOGIC_VECTOR ( 1 downto 0 );
--    probe3 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe4 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe5 : in STD_LOGIC_VECTOR ( 31 downto 0 );
--    probe6 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe7 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe8 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe9 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe10 : in STD_LOGIC_VECTOR ( 31 downto 0 );
--    probe11 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe12 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe13 : in STD_LOGIC_VECTOR ( 1 downto 0 );
--    probe14 : in STD_LOGIC_VECTOR ( 31 downto 0 );
--    probe15 : in STD_LOGIC_VECTOR ( 3 downto 0 );
--    probe16 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe17 : in STD_LOGIC_VECTOR ( 2 downto 0 );
--    probe18 : in STD_LOGIC_VECTOR ( 2 downto 0 );
--    probe19 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe20 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe21 : in STD_LOGIC_VECTOR ( 7 downto 0 );
--    probe22 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe23 : in STD_LOGIC_VECTOR ( 2 downto 0 );
--    probe24 : in STD_LOGIC_VECTOR ( 1 downto 0 );
--    probe25 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe26 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe27 : in STD_LOGIC_VECTOR ( 7 downto 0 );
--    probe28 : in STD_LOGIC_VECTOR ( 2 downto 0 );
--    probe29 : in STD_LOGIC_VECTOR ( 1 downto 0 );
--    probe30 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe31 : in STD_LOGIC_VECTOR ( 3 downto 0 );
--    probe32 : in STD_LOGIC_VECTOR ( 3 downto 0 );
--    probe33 : in STD_LOGIC_VECTOR ( 3 downto 0 );
--    probe34 : in STD_LOGIC_VECTOR ( 3 downto 0 );
--    probe35 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe36 : in STD_LOGIC_VECTOR ( 3 downto 0 );
--    probe37 : in STD_LOGIC_VECTOR ( 3 downto 0 );
--    probe38 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe39 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe40 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe41 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe42 : in STD_LOGIC_VECTOR ( 0 to 0 );
--    probe43 : in STD_LOGIC_VECTOR ( 0 to 0 ));
--END COMPONENT;


BEGIN

   gen_ip: IF  tech_is_board(g_technology, c_tech_board_gemini_lru) OR tech_is_board(g_technology, c_tech_board_gemini_xh_lru) GENERATE

      u_axi_ila : axi4_ila
      PORT MAP (
         clk         => m_clk,
         probe0(0)   => m_axi_miso.wready,
         probe1      => m_axi_mosi.awaddr(31 DOWNTO 0),
         probe2      => m_axi_miso.bresp,
         probe3(0)   => m_axi_miso.bvalid,
         probe4(0)   => m_axi_mosi.bready,
         probe5      => m_axi_mosi.araddr(31 DOWNTO 0),
         probe6(0)   => m_axi_mosi.rready,
         probe7(0)   => m_axi_mosi.wvalid,
         probe8(0)   => m_axi_mosi.arvalid,
         probe9(0)   => m_axi_miso.arready,
         probe10     => m_axi_miso.rdata(31 DOWNTO 0),
         probe11(0)  => m_axi_mosi.awvalid,
         probe12(0)  => m_axi_miso.awready,
         probe13     => m_axi_miso.rresp,
         probe14     => m_axi_mosi.wdata(31 DOWNTO 0),
         probe15     => m_axi_mosi.wstrb(3 DOWNTO 0),
         probe16(0)  => m_axi_miso.rvalid,
         probe17     => m_axi_mosi.arprot,
         probe18     => m_axi_mosi.awprot,
         probe19     => m_axi_mosi.awid(0 DOWNTO 0),
         probe20     => m_axi_miso.bid(0 DOWNTO 0),
         probe21     => m_axi_mosi.awlen(7 DOWNTO 0),
         probe22     => m_axi_miso.buser(0 DOWNTO 0),
         probe23     => m_axi_mosi.awsize,
         probe24     => m_axi_mosi.awburst,
         probe25     => m_axi_mosi.arid(0 DOWNTO 0),
         probe26(0)  => m_axi_mosi.awlock,
         probe27     => m_axi_mosi.arlen(7 DOWNTO 0),
         probe28     => m_axi_mosi.arsize,
         probe29     => m_axi_mosi.arburst,
         probe30(0)  => m_axi_mosi.arlock,
         probe31     => m_axi_mosi.arcache,
         probe32     => m_axi_mosi.awcache,
         probe33     => m_axi_mosi.arregion,
         probe34     => m_axi_mosi.arqos,
         probe35     => m_axi_mosi.aruser(0 DOWNTO 0),
         probe36     => m_axi_mosi.awregion,
         probe37     => m_axi_mosi.awqos,
         probe38     => m_axi_miso.rid(0 DOWNTO 0),
         probe39     => m_axi_mosi.awuser(0 DOWNTO 0),
         probe40     => m_axi_mosi.wid(0 DOWNTO 0),
         probe41(0)  => m_axi_miso.rlast,
         probe42     => m_axi_miso.ruser(0 DOWNTO 0),
         probe43(0)  => m_axi_mosi.wlast );


   END GENERATE;

END wrapper;



