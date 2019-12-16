----------------------------------------------------------------------------------
-- Company: Massey university
-- Engineer: Vignesh raja balu
-- 
-- Create Date: 12.11.2018 13:39:06
-- Design Name: 
-- Module Name: hbm_wrapper - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.hbm_pkg.all;

entity hbm_wrapper is
  Port (i_saxi_00           : in i_SAXI_t;
        o_saxi_00           : out o_SAXI_t;
        i_sapb_0            : in i_SAPB_t;
        o_sapb_0            : out o_SAPB_t;
        hbm_ref_clk_0       : in std_logic; 
        axi_00_aclk         : in std_logic; 
        apb_0_pclk          : in std_logic;   
        axi_00_areset_n     : in std_logic;
        apb_0_preset_n      : in std_logic;
        axi_00_wdata_parity : in std_logic_vector(31 downto 0);
        axi_00_rdata_parity : out std_logic_vector(31 downto 0);
        apb_complete_0      : out std_logic;
        DRAM_0_STAT_CATTRIP : out std_logic;
        DRAM_0_STAT_TEMP    : out std_logic_vector(6 downto 0));
end entity hbm_wrapper;
   
architecture Behavioral of hbm_wrapper is
COMPONENT hbm_saxi_00
  PORT (
    HBM_REF_CLK_0       : IN STD_LOGIC;
    AXI_00_ACLK         : IN STD_LOGIC;
    AXI_00_ARESET_N     : IN STD_LOGIC;
    AXI_00_ARADDR       : IN STD_LOGIC_VECTOR(32 DOWNTO 0);
    AXI_00_ARBURST      : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    AXI_00_ARID         : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    AXI_00_ARLEN        : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    AXI_00_ARSIZE       : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    AXI_00_ARVALID      : IN STD_LOGIC;
    AXI_00_AWADDR       : IN STD_LOGIC_VECTOR(32 DOWNTO 0);
    AXI_00_AWBURST      : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    AXI_00_AWID         : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    AXI_00_AWLEN        : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    AXI_00_AWSIZE       : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    AXI_00_AWVALID      : IN STD_LOGIC;
    AXI_00_RREADY       : IN STD_LOGIC;
    AXI_00_BREADY       : IN STD_LOGIC;
    AXI_00_WDATA        : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    AXI_00_WLAST        : IN STD_LOGIC;
    AXI_00_WSTRB        : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    AXI_00_WDATA_PARITY : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    AXI_00_WVALID       : IN STD_LOGIC;
    APB_0_PWDATA        : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    APB_0_PADDR         : IN STD_LOGIC_VECTOR(21 DOWNTO 0);
    APB_0_PCLK          : IN STD_LOGIC;
    APB_0_PENABLE       : IN STD_LOGIC;
    APB_0_PRESET_N      : IN STD_LOGIC;
    APB_0_PSEL          : IN STD_LOGIC;
    APB_0_PWRITE        : IN STD_LOGIC;
    AXI_00_ARREADY      : OUT STD_LOGIC;
    AXI_00_AWREADY      : OUT STD_LOGIC;
    AXI_00_RDATA_PARITY : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    AXI_00_RDATA        : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    AXI_00_RID          : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    AXI_00_RLAST        : OUT STD_LOGIC;
    AXI_00_RRESP        : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    AXI_00_RVALID       : OUT STD_LOGIC;
    AXI_00_WREADY       : OUT STD_LOGIC;
    AXI_00_BID          : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    AXI_00_BRESP        : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    AXI_00_BVALID       : OUT STD_LOGIC;
    APB_0_PRDATA        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    APB_0_PREADY        : OUT STD_LOGIC;
    APB_0_PSLVERR       : OUT STD_LOGIC;
    apb_complete_0      : OUT STD_LOGIC;
    DRAM_0_STAT_CATTRIP : OUT STD_LOGIC;
    DRAM_0_STAT_TEMP    : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
  );
END COMPONENT;
begin
HBM_MC0_STACK_1: hbm_saxi_00  
    PORT MAP (
    HBM_REF_CLK_0       => hbm_ref_clk_0,
    AXI_00_ACLK         => axi_00_aclk,
    AXI_00_ARESET_N     => axi_00_areset_n,
    AXI_00_ARADDR       => i_saxi_00.ar.addr,
    AXI_00_ARBURST      => i_saxi_00.ar.burst,
    AXI_00_ARID         => i_saxi_00.ar.id,
    AXI_00_ARLEN        => i_saxi_00.ar.len,
    AXI_00_ARSIZE       => i_saxi_00.ar.size,
    AXI_00_ARVALID      => i_saxi_00.ar.valid,
    AXI_00_AWADDR       => i_saxi_00.aw.addr,
    AXI_00_AWBURST      => i_saxi_00.aw.burst,
    AXI_00_AWID         => i_saxi_00.aw.id,
    AXI_00_AWLEN        => i_saxi_00.aw.len,
    AXI_00_AWSIZE       => i_saxi_00.aw.size,
    AXI_00_AWVALID      => i_saxi_00.aw.valid,
    AXI_00_RREADY       => i_saxi_00.rready,
    AXI_00_BREADY       => i_saxi_00.bready,
    AXI_00_WDATA        => i_saxi_00.w.data,
    AXI_00_WLAST        => i_saxi_00.w.last,
    AXI_00_WSTRB        => i_saxi_00.w.strb,
    AXI_00_WDATA_PARITY => axi_00_wdata_parity,
    AXI_00_WVALID       => i_saxi_00.w.valid,
    
    APB_0_PWDATA        => i_sapb_0.pwdata,
    APB_0_PADDR         => i_sapb_0.paddr,
    APB_0_PCLK          => apb_0_pclk,
    APB_0_PENABLE       => i_sapb_0.penable,
    APB_0_PRESET_N      => apb_0_preset_n,
    APB_0_PSEL          => i_sapb_0.psel,
    APB_0_PWRITE        => i_sapb_0.pwrite,
    
    AXI_00_ARREADY      => o_saxi_00.arready,
    AXI_00_AWREADY      => o_saxi_00.awready,
    AXI_00_RDATA_PARITY => axi_00_rdata_parity,
    AXI_00_RDATA        => o_saxi_00.r.data,
    AXI_00_RID          => o_saxi_00.r.id,
    AXI_00_RLAST        => o_saxi_00.r.last,
    AXI_00_RRESP        => o_saxi_00.r.resp,
    AXI_00_RVALID       => o_saxi_00.r.valid,
    AXI_00_WREADY       => o_saxi_00.wready,
    AXI_00_BID          => o_saxi_00.b.id,
    AXI_00_BRESP        => o_saxi_00.b.resp,
    AXI_00_BVALID       => o_saxi_00.b.valid,
    
    APB_0_PRDATA        => o_sapb_0.prdata,
    APB_0_PREADY        => o_sapb_0.pready,
    APB_0_PSLVERR       => o_sapb_0.pslverr,
    apb_complete_0      => apb_complete_0,
    DRAM_0_STAT_CATTRIP => DRAM_0_STAT_CATTRIP,
    DRAM_0_STAT_TEMP    => DRAM_0_STAT_TEMP
  );

end Behavioral;
