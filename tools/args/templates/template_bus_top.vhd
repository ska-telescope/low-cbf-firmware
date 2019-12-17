---------------------------------------------------------------------------------------
--
--  This file was automatically generated from ARGS config file
-- <fpga_name>.fpga.yaml
-- <{list peripheral.yaml used including FPN}>
--  and template file template_bus_top.vhd
--
--  This is the instantiation template for the <lib_name> FPGA design.
--
--
---------------------------------------------------------------------------------------

LIBRARY IEEE, axi4_lib, common_lib, technology_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE axi4_lib.axi4_full_pkg.ALL;
USE common_lib.common_pkg.ALL;
USE work.<fpga_name>_bus_pkg.ALL;

-------------------------------------------------------------------------------
--                              ENTITY STATEMENT                             --
-------------------------------------------------------------------------------

ENTITY <fpga_name>_bus_top IS
    PORT (
        CLK             : IN STD_LOGIC;
        RST             : IN STD_LOGIC;
        SLA_IN          : IN t_axi4_full_mosi;
        SLA_OUT         : OUT t_axi4_full_miso;
        MSTR_IN_LITE    : IN t_axi4_lite_miso_arr(0 TO c_nof_lite_slaves-1);
        MSTR_OUT_LITE   : OUT t_axi4_lite_mosi_arr(0 TO c_nof_lite_slaves-1);
        MSTR_IN_FULL    : IN t_axi4_full_miso_arr(0 TO c_nof_full_slaves-1);
        MSTR_OUT_FULL   : OUT t_axi4_full_mosi_arr(0 TO c_nof_full_slaves-1)
    );
END <fpga_name>_bus_top;

ARCHITECTURE RTL OF <fpga_name>_bus_top IS

    ---------------------------------------------------------------------------
    --                         SIGNAL DECLARATIONS                           --
    ---------------------------------------------------------------------------


    SIGNAL rstn : std_logic;

BEGIN
    rstn <= NOT RST;

    <fpga_name>_bd_inst : ENTITY work.<fpga_name>_bd_wrapper
    PORT MAP (
        ACLK                                               => CLK,
        ARESETN                                            => rstn,
        S00_AXI_araddr(c_addr_w-1 downto 0)                => SLA_IN.araddr(c_addr_w-1 downto 0),
        S00_AXI_arprot(c_axi4_full_prot_w-1 downto 0)      => SLA_IN.arprot(c_axi4_full_prot_w-1 downto 0),
        S00_AXI_arvalid                                    => to_sl(SLA_IN.arvalid),
        S00_AXI_awaddr(c_addr_w-1 downto 0)                => SLA_IN.awaddr(c_addr_w-1 downto 0),
        S00_AXI_awprot(c_axi4_full_prot_w-1 downto 0)      => SLA_IN.awprot(c_axi4_full_prot_w-1 downto 0),
        S00_AXI_awvalid                                    => to_sl(SLA_IN.awvalid),
        S00_AXI_bready                                     => to_sl(SLA_IN.bready),
        S00_AXI_rready                                     => to_sl(SLA_IN.rready),
        S00_AXI_wdata(c_data_w-1 downto 0)                 => SLA_IN.wdata(c_data_w-1 downto 0),
        S00_AXI_wstrb(c_strb_w-1 downto 0)                 => SLA_IN.wstrb(c_strb_w-1 downto 0),
        S00_AXI_wvalid                                     => to_sl(SLA_IN.wvalid),
        S00_AXI_arburst(c_axi4_full_aburst_w-1 downto 0)   => SLA_IN.arburst(c_axi4_full_aburst_w-1 downto 0),
        S00_AXI_awburst(c_axi4_full_aburst_w-1 downto 0)   => SLA_IN.awburst(c_axi4_full_aburst_w-1 downto 0),
        S00_AXI_arcache(c_axi4_full_acache_w-1 downto 0)   => SLA_IN.arcache(c_axi4_full_acache_w-1 downto 0),
        S00_AXI_awcache(c_axi4_full_acache_w-1 downto 0)   => SLA_IN.awcache(c_axi4_full_acache_w-1 downto 0),
        S00_AXI_arlen(c_axi4_full_alen_w-1 downto 0)       => SLA_IN.arlen(c_axi4_full_alen_w-1 downto 0),
        S00_AXI_arsize(c_axi4_full_asize_w-1 downto 0)     => SLA_IN.arsize(c_axi4_full_asize_w-1 downto 0),
        S00_AXI_awsize(c_axi4_full_asize_w-1 downto 0)     => SLA_IN.awsize(c_axi4_full_asize_w-1 downto 0),
        S00_AXI_awlen(c_axi4_full_alen_w-1 downto 0)       => SLA_IN.awlen(c_axi4_full_alen_w-1 downto 0),
        S00_AXI_arlock                                     => to_sl(SLA_IN.arlock),
        S00_AXI_awlock                                     => to_sl(SLA_IN.awlock),
        S00_AXI_wlast                                      => to_sl(SLA_IN.wlast),
        S00_AXI_arregion(c_axi4_full_aregion_w-1 downto 0) => SLA_IN.arregion(c_axi4_full_aregion_w-1 downto 0),
        S00_AXI_awregion(c_axi4_full_aregion_w-1 downto 0) => SLA_IN.awregion(c_axi4_full_aregion_w-1 downto 0),
        S00_AXI_awqos(c_axi4_full_aqos_w-1 downto 0)       => SLA_IN.awqos(c_axi4_full_aqos_w-1 downto 0),
        S00_AXI_arqos(c_axi4_full_aqos_w-1 downto 0)       => SLA_IN.arqos(c_axi4_full_aqos_w-1 downto 0),

        S00_AXI_awready(0)                                 => SLA_OUT.awready,
        S00_AXI_wready(0)                                  => SLA_OUT.wready,
        S00_AXI_bresp(c_axi4_full_resp_w-1 downto 0)       => SLA_OUT.bresp(c_axi4_full_resp_w-1 downto 0),
        S00_AXI_bvalid(0)                                  => SLA_OUT.bvalid,
        S00_AXI_arready(0)                                 => SLA_OUT.arready,
        S00_AXI_rdata(c_data_w-1 downto 0)                 => SLA_OUT.rdata(c_data_w-1 downto 0),
        S00_AXI_rresp(c_axi4_full_resp_w-1 downto 0)       => SLA_OUT.rresp(c_axi4_full_resp_w-1 downto 0),
        S00_AXI_rvalid(0)                                  => SLA_OUT.rvalid,
        S00_AXI_rlast(0)                                   => SLA_OUT.rlast,

        <{master_interfaces}>
    );

END RTL;