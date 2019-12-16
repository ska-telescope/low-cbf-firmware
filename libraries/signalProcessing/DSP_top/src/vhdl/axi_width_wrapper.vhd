----------------------------------------------------------------------------
-- AXI full width converter
-- Author : David Humphrey (dave.humphrey@csiro.au)
-- Description :
--  Convert from a 32 bit wide bus to 256 bit wide bus.
--  Used to interface MACE to the HBM.
--
----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library axi4_lib;
use axi4_lib.axi4_full_pkg.all;

entity axi_width_wrapper is
    port (
        -- AXI full bus going into the width converter
        -- 32 bit wide data bus
        i_MACE_clk     : in  std_logic;
        i_MACE_clk_rst : in  std_logic;
        i_MACE_mosi   : in  t_axi4_full_mosi;
        o_MACE_miso   : out t_axi4_full_miso;
        -- Memory page into the HBM is 4 MBytes in size
        -- So top ten bits of the address come from the page
        -- This is in the MACE clock domain.
        i_page : in std_logic_vector(9 downto 0);
        -- AXI full bus coming out of the width converter
        -- 256 bit wide data bus
        i_HBM_clk     : in  std_logic;
        i_HBM_rst     : in  std_logic;
        i_HBM_miso    : in  t_axi4_full_miso;
        o_HBM_mosi    : out t_axi4_full_mosi
    );
end entity axi_width_wrapper;

architecture Behavioral of axi_width_wrapper is

    signal resetn : std_logic;
    signal HBM_rstn : std_logic;
    signal MACE_wr_addr : std_logic_vector(31 downto 0);
    signal MACE_rd_addr : std_logic_vector(31 downto 0);
    
    COMPONENT hbmdbg_axi_width_convert
    PORT (
        s_axi_aclk    : IN STD_LOGIC;
        s_axi_aresetn : IN STD_LOGIC;
        s_axi_awaddr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axi_awlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        s_axi_awsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi_awburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi_awlock : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        s_axi_awcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi_awregion : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_awqos : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_awvalid : IN STD_LOGIC;
        s_axi_awready : OUT STD_LOGIC;
        s_axi_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axi_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_wlast : IN STD_LOGIC;
        s_axi_wvalid : IN STD_LOGIC;
        s_axi_wready : OUT STD_LOGIC;
        s_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi_bvalid : OUT STD_LOGIC;
        s_axi_bready : IN STD_LOGIC;
        s_axi_araddr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axi_arlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        s_axi_arsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi_arburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi_arlock : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        s_axi_arcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi_arregion : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_arqos : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_arvalid : IN STD_LOGIC;
        s_axi_arready : OUT STD_LOGIC;
        s_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi_rlast : OUT STD_LOGIC;
        s_axi_rvalid : OUT STD_LOGIC;
        s_axi_rready : IN STD_LOGIC;
        m_axi_aclk : IN STD_LOGIC;
        m_axi_aresetn : IN STD_LOGIC;
        m_axi_awaddr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axi_awlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        m_axi_awsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        m_axi_awburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        m_axi_awlock : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        m_axi_awcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_awprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        m_axi_awregion : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_awqos : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_awvalid : OUT STD_LOGIC;
        m_axi_awready : IN STD_LOGIC;
        m_axi_wdata : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
        m_axi_wstrb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axi_wlast : OUT STD_LOGIC;
        m_axi_wvalid : OUT STD_LOGIC;
        m_axi_wready : IN STD_LOGIC;
        m_axi_bresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        m_axi_bvalid : IN STD_LOGIC;
        m_axi_bready : OUT STD_LOGIC;
        m_axi_araddr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axi_arlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        m_axi_arsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        m_axi_arburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        m_axi_arlock : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        m_axi_arcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_arprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        m_axi_arregion : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_arqos : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_arvalid : OUT STD_LOGIC;
        m_axi_arready : IN STD_LOGIC;
        m_axi_rdata : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
        m_axi_rresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        m_axi_rlast : IN STD_LOGIC;
        m_axi_rvalid : IN STD_LOGIC;
        m_axi_rready : OUT STD_LOGIC);
    END COMPONENT;

    signal MACE_awlock, MACE_arlock : std_logic_vector(0 downto 0);
    signal HBM_arlock, HBM_awlock  : std_logic_vector(0 DOWNTO 0);

begin
    
    resetn <= not i_MACE_clk_rst;
    HBM_rstn <= not i_HBM_rst;
    
    MACE_wr_addr <= i_page & i_MACE_mosi.awaddr(21 downto 0);
    MACE_rd_addr <= i_page & i_MACE_mosi.araddr(21 downto 0);
    
    MACE_awlock(0) <= i_MACE_mosi.awlock;
    MACE_arlock(0) <= i_MACE_mosi.arlock;
    
    converti : hbmdbg_axi_width_convert
    port map (
        s_axi_aclk     => i_MACE_clk, -- IN STD_LOGIC;
        s_axi_aresetn  => resetn,     -- IN STD_LOGIC;
        s_axi_awaddr   => MACE_wr_addr,                      -- IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axi_awlen    => i_MACE_mosi.awlen(7 downto 0),     -- IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        s_axi_awsize   => i_MACE_mosi.awsize(2 downto 0),    -- IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi_awburst  => i_MACE_mosi.awburst(1 downto 0),   -- IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi_awlock   => MACE_awlock,                       -- IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        s_axi_awcache  => i_MACE_mosi.awcache(3 downto 0),   -- IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_awprot   => i_MACE_mosi.awprot(2 downto 0),    -- IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi_awregion => i_MACE_mosi.awregion(3 downto 0),  -- IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_awqos    => i_MACE_mosi.awqos(3 downto 0),     -- IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_awvalid  => i_MACE_mosi.awvalid,               -- IN STD_LOGIC;
        
        s_axi_awready => o_MACE_miso.awready,            -- OUT STD_LOGIC;
        s_axi_wdata   => i_MACE_mosi.wdata(31 downto 0), -- IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axi_wstrb   => i_MACE_mosi.wstrb(3 downto 0),  -- IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_wlast   => i_MACE_mosi.wlast,              -- IN STD_LOGIC;
        s_axi_wvalid  => i_MACE_mosi.wvalid,             -- IN STD_LOGIC;
        s_axi_wready  => o_MACE_miso.wready,             -- OUT STD_LOGIC;
        s_axi_bresp   => o_MACE_miso.bresp(1 downto 0),  -- OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi_bvalid  => o_MACE_miso.bvalid,             -- OUT STD_LOGIC;
        s_axi_bready  => i_MACE_mosi.bready,             -- IN STD_LOGIC;
        s_axi_araddr  => MACE_rd_addr,                   -- IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axi_arlen   => i_MACE_mosi.arlen(7 downto 0),  -- IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        s_axi_arsize   => i_MACE_mosi.arsize(2 downto 0),   -- IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi_arburst  => i_MACE_mosi.arburst(1 downto 0),  -- IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi_arlock   => MACE_arlock,                      -- IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        s_axi_arcache  => i_MACE_mosi.arcache(3 downto 0),  -- IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_arprot   => i_MACE_mosi.arprot(2 downto 0),   -- IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi_arregion => i_MACE_mosi.arregion(3 downto 0), -- IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_arqos    => i_MACE_mosi.arqos(3 downto 0),    -- IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_arvalid  => i_MACE_mosi.arvalid,              -- IN STD_LOGIC;
        s_axi_arready  => o_MACE_miso.arready,              -- OUT STD_LOGIC;
        s_axi_rdata    => o_MACE_miso.rdata(31 downto 0),   -- OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axi_rresp    => o_MACE_miso.rresp(1 downto 0),    -- OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi_rlast    => o_MACE_miso.rlast,                -- OUT STD_LOGIC;
        s_axi_rvalid   => o_MACE_miso.rvalid,               -- OUT STD_LOGIC;
        s_axi_rready   => i_MACE_mosi.rready,               -- IN STD_LOGIC;
        --
        m_axi_aclk    => i_HBM_clk, -- IN STD_LOGIC;
        m_axi_aresetn => HBM_rstn,  -- IN STD_LOGIC;
        m_axi_awaddr  => o_HBM_mosi.awaddr(31 downto 0),   -- OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axi_awlen   => o_HBM_mosi.awlen(7 downto 0),     -- OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        m_axi_awsize  => o_HBM_mosi.awsize(2 downto 0),    -- OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        m_axi_awburst => o_HBM_mosi.awburst(1 downto 0),   -- OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        m_axi_awlock  => HBM_awlock,                       -- OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        m_axi_awcache => o_HBM_mosi.awcache(3 downto 0),   -- OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_awprot  => o_HBM_mosi.awprot(2 downto 0),    -- OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        m_axi_awregion => o_HBM_mosi.awregion(3 downto 0), -- OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_awqos => o_HBM_mosi.awqos(3 downto 0),       -- OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_awvalid => o_HBM_mosi.awvalid,               -- OUT STD_LOGIC;
        m_axi_awready => i_HBM_miso.awready,               -- IN STD_LOGIC;
        m_axi_wdata => o_HBM_mosi.wdata(255 downto 0),     -- OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
        m_axi_wstrb => o_HBM_mosi.wstrb(31 downto 0),      -- OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axi_wlast => o_HBM_mosi.wlast,                   -- OUT STD_LOGIC;
        m_axi_wvalid => o_HBM_mosi.wvalid,                 -- OUT STD_LOGIC;
        m_axi_wready  => i_HBM_miso.wready,                -- IN STD_LOGIC;
        m_axi_bresp  => i_HBM_miso.bresp(1 downto 0),      -- IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        m_axi_bvalid  => i_HBM_miso.bvalid,                -- IN STD_LOGIC;
        m_axi_bready => o_HBM_mosi.bready,                 -- OUT STD_LOGIC;
        m_axi_araddr => o_HBM_mosi.araddr(31 downto 0),    -- OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axi_arlen => o_HBM_mosi.arlen(7 downto 0),       -- OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        m_axi_arsize => o_HBM_mosi.arsize(2 downto 0),     -- OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        m_axi_arburst => o_HBM_mosi.arburst(1 downto 0),   -- OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        m_axi_arlock => HBM_arlock,                        -- OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        m_axi_arcache => o_HBM_mosi.arcache(3 downto 0),   -- OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_arprot => o_HBM_mosi.arprot(2 downto 0),     -- OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        m_axi_arregion => o_HBM_mosi.arregion(3 downto 0), -- OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_arqos => o_HBM_mosi.arqos(3 downto 0),       -- OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_arvalid => o_HBM_mosi.arvalid,               -- OUT STD_LOGIC;
        m_axi_arready  => i_HBM_miso.arready,              -- IN STD_LOGIC;
        m_axi_rdata  => i_HBM_miso.rdata(255 downto 0),    -- IN STD_LOGIC_VECTOR(255 DOWNTO 0);
        m_axi_rresp  => i_HBM_miso.rresp(1 downto 0),      -- IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        m_axi_rlast  => i_HBM_miso.rlast,                  -- IN STD_LOGIC;
        m_axi_rvalid  => i_HBM_miso.rvalid,                -- IN STD_LOGIC;
        m_axi_rready => o_HBM_mosi.rready                  -- OUT STD_LOGIC
    );
    
    o_HBM_mosi.arlock <= HBM_arlock(0);
    o_HBM_mosi.awlock <= HBM_awlock(0);
    
end Behavioral;