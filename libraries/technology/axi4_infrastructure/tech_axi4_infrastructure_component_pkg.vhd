LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

PACKAGE tech_axi4_infrastructure_component_pkg IS

COMPONENT axi4lite_clock_converter
  PORT (
    s_axi_aclk : IN STD_LOGIC;
    s_axi_aresetn : IN STD_LOGIC;
    s_axi_awaddr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axi_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s_axi_awvalid : IN STD_LOGIC;
    s_axi_awready : OUT STD_LOGIC;
    s_axi_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axi_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    s_axi_wvalid : IN STD_LOGIC;
    s_axi_wready : OUT STD_LOGIC;
    s_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi_bvalid : OUT STD_LOGIC;
    s_axi_bready : IN STD_LOGIC;
    s_axi_araddr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axi_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s_axi_arvalid : IN STD_LOGIC;
    s_axi_arready : OUT STD_LOGIC;
    s_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi_rvalid : OUT STD_LOGIC;
    s_axi_rready : IN STD_LOGIC;
    m_axi_aclk : IN STD_LOGIC;
    m_axi_aresetn : IN STD_LOGIC;
    m_axi_awaddr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axi_awprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    m_axi_awvalid : OUT STD_LOGIC;
    m_axi_awready : IN STD_LOGIC;
    m_axi_wdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axi_wstrb : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_wvalid : OUT STD_LOGIC;
    m_axi_wready : IN STD_LOGIC;
    m_axi_bresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_bvalid : IN STD_LOGIC;
    m_axi_bready : OUT STD_LOGIC;
    m_axi_araddr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axi_arprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    m_axi_arvalid : OUT STD_LOGIC;
    m_axi_arready : IN STD_LOGIC;
    m_axi_rdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axi_rresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_rvalid : IN STD_LOGIC;
    m_axi_rready : OUT STD_LOGIC
  );
END COMPONENT;

  COMPONENT axi4_ila
      PORT (clk : IN STD_LOGIC;
      	probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      	probe1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      	probe2 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      	probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      	probe4 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      	probe5 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      	probe6 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      	probe7 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      	probe8 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      	probe9 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      	probe10 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      	probe11 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      	probe12 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      	probe13 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      	probe14 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      	probe15 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      	probe16 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      	probe17 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      	probe18 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      	probe19 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      	probe20 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      	probe21 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      	probe22 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      	probe23 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      	probe24 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      	probe25 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      	probe26 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      	probe27 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      	probe28 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      	probe29 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      	probe30 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      	probe31 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      	probe32 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      	probe33 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      	probe34 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      	probe35 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      	probe36 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      	probe37 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      	probe38 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      	probe39 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      	probe40 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      	probe41 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      	probe42 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      	probe43 : IN STD_LOGIC_VECTOR(0 DOWNTO 0));
   END COMPONENT ;

   COMPONENT axi_apb_translate
      PORT (
         s_axi_aclk : IN STD_LOGIC;
         s_axi_aresetn : IN STD_LOGIC;
         s_axi_awaddr : IN STD_LOGIC_VECTOR(21 DOWNTO 0);
         s_axi_awvalid : IN STD_LOGIC;
         s_axi_awready : OUT STD_LOGIC;
         s_axi_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
         s_axi_wvalid : IN STD_LOGIC;
         s_axi_wready : OUT STD_LOGIC;
         s_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
         s_axi_bvalid : OUT STD_LOGIC;
         s_axi_bready : IN STD_LOGIC;
         s_axi_araddr : IN STD_LOGIC_VECTOR(21 DOWNTO 0);
         s_axi_arvalid : IN STD_LOGIC;
         s_axi_arready : OUT STD_LOGIC;
         s_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
         s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
         s_axi_rvalid : OUT STD_LOGIC;
         s_axi_rready : IN STD_LOGIC;
         m_apb_paddr : OUT STD_LOGIC_VECTOR(21 DOWNTO 0);
         m_apb_psel : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
         m_apb_penable : OUT STD_LOGIC;
         m_apb_pwrite : OUT STD_LOGIC;
         m_apb_pwdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
         m_apb_pready : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
         m_apb_prdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
         m_apb_pslverr : IN STD_LOGIC_VECTOR(0 DOWNTO 0));
   END COMPONENT;

END tech_axi4_infrastructure_component_pkg;

