--------------------------------------------------------------------------------
--
--  This file was automatically generated using ARGS config file <lib>.peripheral.yaml
--
--  This wrapper depends on IP created by ip_<lib>_<entity>_axi4.tcl
--
--
--------------------------------------------------------------------------------

LIBRARY ieee, common_lib, axi4_lib;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_full_pkg.ALL;

ENTITY <lib>_<name>_ram IS
    GENERIC (
        g_ram_b     : t_c_mem   := (latency => 1, adr_w => <adr_wb>, dat_w => <dat_wb>, addr_base => 0, nof_slaves => <nof_slaves>, nof_dat => <nof_datb>, init_sl => '<init_sl>')
    );
    PORT (
        CLK_A       : IN    STD_LOGIC;
        RST_A       : IN    STD_LOGIC;
        CLK_B       : IN    STD_LOGIC;
        RST_B       : IN    STD_LOGIC;
        MM_IN       : IN    t_axi4_full_mosi;
        MM_OUT      : OUT   t_axi4_full_miso;
        user_we     : in    std_logic;
        user_addr   : in    std_logic_vector(g_ram_b.adr_w-1 downto 0);
        user_din    : in    std_logic_vector(g_ram_b.dat_w-1 downto 0);
        user_dout   : out   std_logic_vector(g_ram_b.dat_w-1 downto 0)
    );
END <lib>_<name>_ram;

ARCHITECTURE str OF <lib>_<name>_ram IS

    CONSTANT c_ram_a	: t_c_mem :=
        (latency	=> 1,
        adr_w	    => <adr_w>,
        dat_w	    => <dat_w>,
        addr_base   => 0,
        nof_slaves  => <nof_slaves>,
        nof_dat	    => <nof_dat>,
        init_sl	    => '<init_sl>');

    CONSTANT c_ram_b	: t_c_mem := g_ram_b;

    TYPE t_we_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_ram_b.dat_w/8-1 downto 0);

    SIGNAL sig_clka     : std_logic;
    SIGNAL sig_rsta     : std_logic;
    SIGNAL sig_wea      : std_logic_vector(c_ram_a.dat_w/8-1 downto 0);
    SIGNAL sig_wea_sum  : std_logic;
    SIGNAL sig_rea_sum  : std_logic;
    SIGNAL sig_ena      : std_logic;
    SIGNAL sig_addra    : std_logic_vector(c_ram_a.adr_w+1 downto 0);
    SIGNAL sig_dina     : std_logic_vector(c_ram_a.dat_w-1 downto 0);
    SIGNAL sig_douta    : std_logic_vector(c_ram_a.dat_w-1 downto 0);
    SIGNAL sig_clkb     : std_logic<vector>;
    SIGNAL sig_rstb     : std_logic<vector>;
    SIGNAL sig_enb      : std_logic<vector>;
    SIGNAL sig_web      : <t_we_arr>(<web_range>-1 downto 0);
    SIGNAL sig_addrb    : std_logic_vector(c_ram_b.adr_w+<user_upper> downto 0);
    SIGNAL sig_dinb     : std_logic_vector(c_ram_b.dat_w-1 downto 0);
    SIGNAL sig_doutb    : std_logic_vector(c_ram_b.dat_w-1 downto 0);

    SIGNAL mem_mosi_arr_a : t_mem_mosi_arr(c_ram_a.nof_slaves-1 downto 0);
    SIGNAL mem_miso_arr_a : t_mem_miso_arr(c_ram_a.nof_slaves-1 downto 0);
    SIGNAL mem_mosi_arr_b : t_mem_mosi_arr(c_ram_b.nof_slaves-1 downto 0);
    SIGNAL mem_miso_arr_b : t_mem_miso_arr(c_ram_b.nof_slaves-1 downto 0);

    SIGNAL sig_arstn    : std_logic;
    SIGNAL sig_brstn    : std_logic;
    signal user_we_slv : std_logic_vector((g_ram_b.dat_w/8 - 1) downto 0);

    COMPONENT ip_<lib>_<name>_axi_a
      PORT (
        s_axi_aclk : IN STD_LOGIC;
        s_axi_aresetn : IN STD_LOGIC;
        s_axi_awaddr : IN STD_LOGIC_VECTOR(c_ram_a.adr_w+1 DOWNTO 0);
        s_axi_awlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        s_axi_awsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi_awburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi_awlock : IN STD_LOGIC;
        s_axi_awcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi_awvalid : IN STD_LOGIC;
        s_axi_awready : OUT STD_LOGIC;
        s_axi_wdata : IN STD_LOGIC_VECTOR(c_ram_a.dat_w-1 DOWNTO 0);
        s_axi_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_wlast : IN STD_LOGIC;
        s_axi_wvalid : IN STD_LOGIC;
        s_axi_wready : OUT STD_LOGIC;
        s_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi_bvalid : OUT STD_LOGIC;
        s_axi_bready : IN STD_LOGIC;
        s_axi_araddr : IN STD_LOGIC_VECTOR(c_ram_a.adr_w+1 DOWNTO 0);
        s_axi_arlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        s_axi_arsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi_arburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi_arlock : IN STD_LOGIC;
        s_axi_arcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi_arvalid : IN STD_LOGIC;
        s_axi_arready : OUT STD_LOGIC;
        s_axi_rdata : OUT STD_LOGIC_VECTOR(c_ram_a.dat_w-1 DOWNTO 0);
        s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi_rlast : OUT STD_LOGIC;
        s_axi_rvalid : OUT STD_LOGIC;
        s_axi_rready : IN STD_LOGIC;
        bram_rst_a : OUT STD_LOGIC;
        bram_clk_a : OUT STD_LOGIC;
        bram_en_a : OUT STD_LOGIC;
        bram_we_a : OUT STD_LOGIC_VECTOR(c_ram_a.dat_w/8-1 DOWNTO 0);
        bram_addr_a : OUT STD_LOGIC_VECTOR(c_ram_a.adr_w+1 DOWNTO 0);
        bram_wrdata_a : OUT STD_LOGIC_VECTOR(c_ram_a.dat_w-1 DOWNTO 0);
        bram_rddata_a : IN STD_LOGIC_VECTOR(c_ram_a.dat_w-1 DOWNTO 0)
      );
    END COMPONENT;

    COMPONENT ip_<lib>_<name>_axi_b
      PORT (
        s_axi_aclk : IN STD_LOGIC;
        s_axi_aresetn : IN STD_LOGIC;
        s_axi_awaddr : IN STD_LOGIC_VECTOR(g_ram_b.adr_w+1 DOWNTO 0);
        s_axi_awlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        s_axi_awsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi_awburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi_awlock : IN STD_LOGIC;
        s_axi_awcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi_awvalid : IN STD_LOGIC;
        s_axi_awready : OUT STD_LOGIC;
        s_axi_wdata : IN STD_LOGIC_VECTOR(g_ram_b.dat_w-1 DOWNTO 0);
        s_axi_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_wlast : IN STD_LOGIC;
        s_axi_wvalid : IN STD_LOGIC;
        s_axi_wready : OUT STD_LOGIC;
        s_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi_bvalid : OUT STD_LOGIC;
        s_axi_bready : IN STD_LOGIC;
        s_axi_araddr : IN STD_LOGIC_VECTOR(g_ram_b.adr_w+1 DOWNTO 0);
        s_axi_arlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        s_axi_arsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi_arburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi_arlock : IN STD_LOGIC;
        s_axi_arcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi_arvalid : IN STD_LOGIC;
        s_axi_arready : OUT STD_LOGIC;
        s_axi_rdata : OUT STD_LOGIC_VECTOR(g_ram_b.dat_w-1 DOWNTO 0);
        s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi_rlast : OUT STD_LOGIC;
        s_axi_rvalid : OUT STD_LOGIC;
        s_axi_rready : IN STD_LOGIC;
        bram_rst_a : OUT STD_LOGIC;
        bram_clk_a : OUT STD_LOGIC;
        bram_en_a : OUT STD_LOGIC;
        bram_we_a : OUT STD_LOGIC_VECTOR(g_ram_b.dat_w/8-1 DOWNTO 0);
        bram_addr_a : OUT STD_LOGIC_VECTOR(g_ram_b.adr_w+1 DOWNTO 0);
        bram_wrdata_a : OUT STD_LOGIC_VECTOR(g_ram_b.dat_w-1 DOWNTO 0);
        bram_rddata_a : IN STD_LOGIC_VECTOR(g_ram_b.dat_w-1 DOWNTO 0)
      );
    END COMPONENT;

    COMPONENT ip_<lib>_<name>_bram
      PORT (
        clka : IN STD_LOGIC;
        rsta : IN STD_LOGIC;
        ena : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(c_ram_a.dat_w/8-1 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(c_ram_a.adr_w-1 DOWNTO 0); -- adjust for AXI and nof_slaves
        dina : IN STD_LOGIC_VECTOR(c_ram_a.dat_w-1 DOWNTO 0);
        douta : OUT STD_LOGIC_VECTOR(c_ram_a.dat_w-1 DOWNTO 0);
        clkb : IN STD_LOGIC;
        rstb : IN STD_LOGIC;
        enb : IN STD_LOGIC;
        web : IN STD_LOGIC_VECTOR(g_ram_b.dat_w/8-1 DOWNTO 0);
        addrb : IN STD_LOGIC_VECTOR(g_ram_b.adr_w-1 DOWNTO 0);
        dinb : IN STD_LOGIC_VECTOR(g_ram_b.dat_w-1 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(g_ram_b.dat_w-1 DOWNTO 0)
      );
    END COMPONENT;
BEGIN

    sig_arstn <= not RST_A;
    sig_brstn <= not RST_B;

    u_axi4_ctrl_a : COMPONENT ip_<lib>_<name>_axi_a -- mm bus side
    PORT MAP(
        s_axi_aclk      => CLK_A,
        s_axi_aresetn   => sig_arstn,
        s_axi_awaddr    => MM_IN.awaddr(c_ram_a.adr_w+1 downto 0),
        s_axi_awlen     => MM_IN.awlen,
        s_axi_awsize    => MM_IN.awsize,
        s_axi_awburst   => MM_IN.awburst,
        s_axi_awlock    => MM_IN.awlock ,
        s_axi_awcache   => MM_IN.awcache,
        s_axi_awprot    => MM_IN.awprot,
        s_axi_awvalid   => MM_IN.awvalid,
        s_axi_awready   => MM_OUT.awready,
        s_axi_wdata     => MM_IN.wdata(c_ram_a.dat_w-1 downto 0),
        s_axi_wstrb     => MM_IN.wstrb(c_ram_a.dat_w/8-1 downto 0),
        s_axi_wlast     => MM_IN.wlast,
        s_axi_wvalid    => MM_IN.wvalid,
        s_axi_wready    => MM_OUT.wready,
        s_axi_bresp     => MM_OUT.bresp,
        s_axi_bvalid    => MM_OUT.bvalid,
        s_axi_bready    => MM_IN.bready ,
        s_axi_araddr    => MM_IN.araddr(c_ram_a.adr_w+1 downto 0),
        s_axi_arlen     => MM_IN.arlen,
        s_axi_arsize    => MM_IN.arsize,
        s_axi_arburst   => MM_IN.arburst,
        s_axi_arlock    => MM_IN.arlock ,
        s_axi_arcache   => MM_IN.arcache,
        s_axi_arprot    => MM_IN.arprot,
        s_axi_arvalid   => MM_IN.arvalid,
        s_axi_arready   => MM_OUT.arready,
        s_axi_rdata     => MM_OUT.rdata(c_ram_a.dat_w-1 downto 0),
        s_axi_rresp     => MM_OUT.rresp,
        s_axi_rlast     => MM_OUT.rlast,
        s_axi_rvalid    => MM_OUT.rvalid,
        s_axi_rready    => MM_IN.rready,
        bram_rst_a      => sig_rsta,
        bram_clk_a      => sig_clka,
        bram_en_a       => sig_ena,
        bram_we_a       => sig_wea,
        bram_addr_a     => sig_addra,
        bram_wrdata_a   => sig_dina,
        bram_rddata_a   => sig_douta
    );


<{multiple_slaves}>

    blk_mem_gen: FOR i in 0 to c_ram_b.nof_slaves-1 GENERATE

    <tab>u_blk_mem: COMPONENT ip_<lib>_<name>_bram
    <tab>PORT MAP(
        <tab>clka       => sig_clka,
        <tab>rsta       => sig_rsta,
        <tab>wea        => <sig_wea>,
        <tab>ena        => sig_ena,
        <tab>addra      => <sig_addra>(c_ram_a.adr_w+1 downto 2),
        <tab>dina       => <sig_dina>(c_ram_a.dat_w-1 downto 0),
        <tab>douta      => <sig_douta>(c_ram_a.dat_w-1 downto 0),
        <tab>clkb       => CLK_B,
        <tab>rstb       => RST_B,
        <tab>enb        => '1',
        <tab>web        => user_we_slv,
        <tab>addrb      => user_addr(g_ram_b.adr_w-1 downto 0),
        <tab>dinb       => user_din(g_ram_b.dat_w-1 downto 0),
        <tab>doutb      => user_dout(g_ram_b.dat_w-1 downto 0)
    <tab>);
    
    wegen : for i in 0 to (g_ram_b.dat_w/8 - 1) generate
        user_we_slv(i) <= user_we;
    end generate;

END GENERATE;

end str;