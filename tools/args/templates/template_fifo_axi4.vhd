--------------------------------------------------------------------------------
--
--  This file was automatically generated using ARGS config file <lib>.peripheral.yaml
--  
--  This wrapper depends on IP created by ip_<lib>_<entity>_axi4.tcl
--
--
--------------------------------------------------------------------------------
LIBRARY IEEE, common_lib, axi4_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE axi4_lib.axi4_full_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;

ENTITY <lib>_<name>_fifo IS 
    GENERIC (
        g_fifo   : t_c_mem := (1, 1, <dat_w>, 0, <nof_slaves>, <nof_dat>, 'X')
    );
    PORT (
        MM_RST          : IN STD_LOGIC;
        MM_CLK          : IN STD_LOGIC;
        
        -- AXI4-Lite Interface (config and optionally data)
        SLA_IN          : IN    t_axi4_lite_mosi<_arr>;
        SLA_OUT         : OUT   t_axi4_lite_miso<_arr>;
        
        -- AXI4 Data Interface
        SLA_IN_DATA     : IN    t_axi4_full_mosi<_arr>; 
        SLA_OUT_DATA    : OUT   t_axi4_full_miso<_arr>;
        
        -- Stream interfaces 
        TXD_IN          : IN    t_axi4_siso<_arr>;
        TXD_OUT         : OUT   t_axi4_sosi<_arr>;        
        RST_TXD_OUT     : OUT   STD_LOGIC<_VECTOR>;
        
        RXD_IN          : IN    t_axi4_sosi<_arr>;
        RXD_OUT         : OUT   t_axi4_siso<_arr>;
        RST_RXD_OUT     : OUT   STD_LOGIC<_VECTOR>; 
        
        INTERRUPT       : OUT   STD_LOGIC
        
    ); 
END <lib>_<name>_fifo;

ARCHITECTURE str OF <lib>_<name>_fifo IS

    SIGNAL rstn : STD_LOGIC;

    COMPONENT ip_<lib>_<name>_fifo
      PORT (
        interrupt : OUT STD_LOGIC;
        s_axi_aclk : IN STD_LOGIC;
        s_axi_aresetn : IN STD_LOGIC;
        s_axi_awaddr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
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
        s_axi_arvalid : IN STD_LOGIC;
        s_axi_arready : OUT STD_LOGIC;
        s_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi_rvalid : OUT STD_LOGIC;
        s_axi_rready : IN STD_LOGIC;
        s_axi4_awid : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi4_awaddr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axi4_awlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        s_axi4_awsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi4_awburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi4_awlock : IN STD_LOGIC;
        s_axi4_awcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi4_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi4_awvalid : IN STD_LOGIC;
        s_axi4_awready : OUT STD_LOGIC;
        s_axi4_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axi4_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi4_wlast : IN STD_LOGIC;
        s_axi4_wvalid : IN STD_LOGIC;
        s_axi4_wready : OUT STD_LOGIC;
        s_axi4_bid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi4_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi4_bvalid : OUT STD_LOGIC;
        s_axi4_bready : IN STD_LOGIC;
        s_axi4_arid : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi4_araddr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axi4_arlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        s_axi4_arsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi4_arburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi4_arlock : IN STD_LOGIC;
        s_axi4_arcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi4_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi4_arvalid : IN STD_LOGIC;
        s_axi4_arready : OUT STD_LOGIC;
        s_axi4_rid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi4_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axi4_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi4_rlast : OUT STD_LOGIC;
        s_axi4_rvalid : OUT STD_LOGIC;
        s_axi4_rready : IN STD_LOGIC;
        mm2s_prmry_reset_out_n : OUT STD_LOGIC;
        axi_str_txd_tvalid : OUT STD_LOGIC;
        axi_str_txd_tready : IN STD_LOGIC;
        axi_str_txd_tlast : OUT STD_LOGIC;
        axi_str_txd_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        s2mm_prmry_reset_out_n : OUT STD_LOGIC;
        axi_str_rxd_tvalid : IN STD_LOGIC;
        axi_str_rxd_tready : OUT STD_LOGIC;
        axi_str_rxd_tlast : IN STD_LOGIC;
        axi_str_rxd_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
      );
    END COMPONENT;

BEGIN

    rstn <= NOT MM_RST;
    ---------------------------------------------------------------------------
    --                        INSTANTIATE COMPONENTS                         --
    ---------------------------------------------------------------------------
    --  direct instantiation of existing xci file from library 
    -- generic ports will be set via tcl file when generating IP 
fifo_gen : FOR i in 0 to g_fifo.nof_slaves-1 GENERATE

    u_fifo: ip_<lib>_<name>_fifo
    PORT MAP (
        interrupt           => INTERRUPT,       
        s_axi_aclk          => MM_CLK,          
        s_axi_aresetn       => rstn,          
        s_axi_awaddr        => SLA_IN<(i)>.awaddr,   
        s_axi_awvalid       => SLA_IN<(i)>.awvalid,  
        s_axi_awready       => SLA_OUT<(i)>.awready, 
        s_axi_wdata         => SLA_IN<(i)>.wdata,    
        s_axi_wstrb         => SLA_IN<(i)>.wstrb,    
        s_axi_wvalid        => SLA_IN<(i)>.wvalid,   
        s_axi_wready        => SLA_OUT<(i)>.wready,  
        s_axi_bresp         => SLA_OUT<(i)>.bresp,   
        s_axi_bvalid        => SLA_OUT<(i)>.bvalid,  
        s_axi_bready        => SLA_IN<(i)>.bready,   
        s_axi_araddr        => SLA_IN<(i)>.araddr,   
        s_axi_arvalid       => SLA_IN<(i)>.arvalid,  
        s_axi_arready       => SLA_OUT<(i)>.arready, 
        s_axi_rdata         => SLA_OUT<(i)>.rdata,   
        s_axi_rresp         => SLA_OUT<(i)>.rresp,   
        s_axi_rvalid        => SLA_OUT<(i)>.rvalid,  
        s_axi_rready        => SLA_IN<(i)>.rready,   
        s_axi4_awid         => SLA_IN_DATA<(i)>.awid,
        s_axi4_awaddr       => SLA_IN_DATA<(i)>.awaddr  ,     
        s_axi4_awlen        => SLA_IN_DATA<(i)>.awlen   ,     
        s_axi4_awsize       => SLA_IN_DATA<(i)>.awsize  ,     
        s_axi4_awburst      => SLA_IN_DATA<(i)>.awburst ,     
        s_axi4_awlock       => SLA_IN_DATA<(i)>.awlock  ,     
        s_axi4_awcache      => SLA_IN_DATA<(i)>.awcache ,     
        s_axi4_awprot       => SLA_IN_DATA<(i)>.awprot  ,     
        s_axi4_awvalid      => SLA_IN_DATA<(i)>.awvalid ,     
        s_axi4_awready      => SLA_OUT_DATA<(i)>.awready ,     
        s_axi4_wdata        => SLA_IN_DATA<(i)>.wdata   ,     
        s_axi4_wstrb        => SLA_IN_DATA<(i)>.wstrb   ,     
        s_axi4_wlast        => SLA_IN_DATA<(i)>.wlast   ,     
        s_axi4_wvalid       => SLA_IN_DATA<(i)>.wvalid  ,     
        s_axi4_wready       => SLA_OUT_DATA<(i)>.wready ,     
        s_axi4_bid          => SLA_OUT_DATA<(i)>.bid    ,     
        s_axi4_bresp        => SLA_OUT_DATA<(i)>.bresp  ,     
        s_axi4_bvalid       => SLA_OUT_DATA<(i)>.bvalid ,     
        s_axi4_bready       => SLA_IN_DATA<(i)>.bready ,      
        s_axi4_arid         => SLA_IN_DATA<(i)>.arid   ,      
        s_axi4_araddr       => SLA_IN_DATA<(i)>.araddr ,      
        s_axi4_arlen        => SLA_IN_DATA<(i)>.arlen  ,      
        s_axi4_arsize       => SLA_IN_DATA<(i)>.arsize ,      
        s_axi4_arburst      => SLA_IN_DATA<(i)>.arburst,      
        s_axi4_arlock       => SLA_IN_DATA<(i)>.arlock ,      
        s_axi4_arcache      => SLA_IN_DATA<(i)>.arcache,      
        s_axi4_arprot       => SLA_IN_DATA<(i)>.arprot ,      
        s_axi4_arvalid      => SLA_IN_DATA<(i)>.arvalid,      
        s_axi4_arready      => SLA_OUT_DATA<(i)>.arready,     
        s_axi4_rid          => SLA_OUT_DATA<(i)>.rid    ,     
        s_axi4_rdata        => SLA_OUT_DATA<(i)>.rdata  ,    
        s_axi4_rresp        => SLA_OUT_DATA<(i)>.rresp  ,     
        s_axi4_rlast        => SLA_OUT_DATA<(i)>.rlast  ,     
        s_axi4_rvalid       => SLA_OUT_DATA<(i)>.rvalid ,     
        s_axi4_rready       => SLA_IN_DATA<(i)>.rready  ,     
        mm2s_prmry_reset_out_n  => RST_TXD_OUT<(i)>,          
        axi_str_txd_tvalid  => TXD_OUT<(i)>.tvalid ,          
        axi_str_txd_tready  => TXD_IN<(i)>.tready ,           
        axi_str_txd_tlast   => TXD_OUT<(i)>.tlast  ,          
        axi_str_txd_tdata   => TXD_OUT<(i)>.tdata              
        s2mm_prmry_reset_out_n  => RST_RXD_OUT<(i)>,          
        axi_str_rxd_tvalid  => RXD_IN<(i)>.tvalid ,           
        axi_str_rxd_tready  => RXD_OUT<(i)>.tready ,          
        axi_str_rxd_tlast   => RXD_IN<(i)>.tlast  ,           
        axi_str_rxd_tdata   => RXD_IN<(i)>.tdata              
    );
    
END GENERATE;

END str;