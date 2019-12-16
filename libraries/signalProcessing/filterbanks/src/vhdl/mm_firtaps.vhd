--------------------------------------------------------------------------------
--
--  Filterbanks fir filter taps interface.
--  Author : David Humphrey (dave.humphrey@csiro.au)
--           Modified from the automatically generated using ARGS file, 
--           based on the config file filterbanks.peripheral.yaml
--  
--  Takes the axi full interface and converts to a memory interface with addr, data, wr_en.
--  
--------------------------------------------------------------------------------

LIBRARY ieee, common_lib, axi4_lib;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE axi4_lib.axi4_full_pkg.ALL;

ENTITY filterbanks_firtaps_ram IS
    PORT (
        -- full AXI bus
        CLK_A      : IN  STD_LOGIC;
        RST_A      : IN  STD_LOGIC;
        MM_IN      : IN  t_axi4_full_mosi;
        MM_OUT     : OUT t_axi4_full_miso;
        -- Interface to the memories. Should be a 3 cycle latency for reads
        -- Note - two extra cycles of latency added in this file, so axi interface is configured for 5 cycle read latency.
        -- Common memory interface signals
        mem_clk    : out std_logic;
        mem_rst    : out std_logic;
        mem_addr   : out std_logic_vector(15 downto 0);
        mem_wr_data : out std_logic_vector(17 downto 0);
        -- Correlator - address 0 to 49151 (0x0 to 0xC000)
        o_cor_we     : out std_logic;
        i_cor_rd_data : in std_logic_vector(17 downto 0);
        -- PST - 3072 words, address 49152 to 52223 (0xC000 to 0xCBFF)
        o_PST_we : out std_logic;
        i_PST_rd_data : in std_logic_vector(17 downto 0);
        -- PSS - 768 words, Address 53248 to 54015 (0xD000 to 0xD2FF)
        o_PSS_we : out std_logic;
        i_PSS_rd_data : in std_logic_vector(17 downto 0)
    );
END filterbanks_firtaps_ram;

ARCHITECTURE str OF filterbanks_firtaps_ram IS

    SIGNAL sig_ena  : std_logic;
    SIGNAL sig_addr : std_logic_vector(17 downto 0);
    SIGNAL sig_din  : std_logic_vector(31 downto 0);
    SIGNAL sig_dout : std_logic_vector(31 downto 0);
    
    signal sig_wea     : std_logic_vector(3 downto 0);
    SIGNAL sig_arstn   : std_logic;
    SIGNAL sig_brstn   : std_logic;
    
    signal mem_we : std_logic;
    signal mem_clki : std_logic;
    signal mem_addri : std_logic_vector(15 downto 0);

    signal selectCor, selectPSS, selectPST : std_logic := '0';
    signal selectCorDel1, selectPSSDel1, selectPSTDel1 : std_logic := '0';
    signal selectCorDel2, selectPSSDel2, selectPSTDel2 : std_logic := '0';
    signal selectCorDel3, selectPSSDel3, selectPSTDel3 : std_logic := '0';

    COMPONENT ip_filterbanks_firtaps_axi_a
      PORT (
        s_axi_aclk : IN STD_LOGIC;
        s_axi_aresetn : IN STD_LOGIC;
        s_axi_awaddr : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
        s_axi_awlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        s_axi_awsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi_awburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi_awlock : IN STD_LOGIC;
        s_axi_awcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
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
        s_axi_araddr : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
        s_axi_arlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        s_axi_arsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi_arburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi_arlock : IN STD_LOGIC;
        s_axi_arcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        s_axi_arvalid : IN STD_LOGIC;
        s_axi_arready : OUT STD_LOGIC;
        s_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi_rlast : OUT STD_LOGIC;
        s_axi_rvalid : OUT STD_LOGIC;
        s_axi_rready : IN STD_LOGIC;
        bram_rst_a : OUT STD_LOGIC;
        bram_clk_a : OUT STD_LOGIC;
        bram_en_a : OUT STD_LOGIC;
        bram_we_a : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        bram_addr_a : OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
        bram_wrdata_a : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        bram_rddata_a : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
      );
    END COMPONENT;
    
BEGIN
    
    sig_arstn <= not RST_A;
    
    u_axi4_ctrl_a : COMPONENT ip_filterbanks_firtaps_axi_a -- mm bus side
    PORT MAP(
        s_axi_aclk      => CLK_A,
        s_axi_aresetn   => sig_arstn,
        s_axi_awaddr    => MM_IN.awaddr(17 downto 0),
        s_axi_awlen     => MM_IN.awlen,
        s_axi_awsize    => MM_IN.awsize,
        s_axi_awburst   => MM_IN.awburst,
        s_axi_awlock    => MM_IN.awlock ,
        s_axi_awcache   => MM_IN.awcache,
        s_axi_awprot    => MM_IN.awprot,
        s_axi_awvalid   => MM_IN.awvalid,
        s_axi_awready   => MM_OUT.awready,
        s_axi_wdata     => MM_IN.wdata(31 downto 0),
        s_axi_wstrb     => MM_IN.wstrb(3 downto 0),
        s_axi_wlast     => MM_IN.wlast,
        s_axi_wvalid    => MM_IN.wvalid,
        s_axi_wready    => MM_OUT.wready,
        s_axi_bresp     => MM_OUT.bresp,
        s_axi_bvalid    => MM_OUT.bvalid,
        s_axi_bready    => MM_IN.bready ,
        s_axi_araddr    => MM_IN.araddr(17 downto 0),
        s_axi_arlen     => MM_IN.arlen,
        s_axi_arsize    => MM_IN.arsize,
        s_axi_arburst   => MM_IN.arburst,
        s_axi_arlock    => MM_IN.arlock ,
        s_axi_arcache   => MM_IN.arcache,
        s_axi_arprot    => MM_IN.arprot,
        s_axi_arvalid   => MM_IN.arvalid,
        s_axi_arready   => MM_OUT.arready,
        s_axi_rdata     => MM_OUT.rdata(31 downto 0),
        s_axi_rresp     => MM_OUT.rresp,
        s_axi_rlast     => MM_OUT.rlast,
        s_axi_rvalid    => MM_OUT.rvalid,
        s_axi_rready    => MM_IN.rready,
        bram_rst_a      => mem_rst,
        bram_clk_a      => mem_clki,
        bram_en_a       => sig_ena,
        bram_we_a       => sig_wea,
        bram_addr_a     => sig_addr,
        bram_wrdata_a   => sig_din,
        bram_rddata_a   => sig_dout
    );

    mem_we  <= sig_wea(0); --    : out std_logic; -- _vector(c_ram_a.dat_w/8-1 downto 0);        
    mem_clk <= mem_clki;
    mem_addr <= mem_addri;
    
    
    
    
    process(mem_clki)
    begin
        if rising_edge(mem_clki) then
            
            if mem_addri(15 downto 14) /= "11" then
                -- Correlator - address 0 to 49151 (0x0 to 0xC000)
                selectCor <= '1';
                selectPSS <= '0';
                selectPST <= '0';
                if mem_we = '1' then
                    o_cor_we <= '1';
                else
                    o_cor_we <= '0';
                end if;
                o_PST_we <= '0';
                o_PSS_we <= '0';
            elsif mem_addri(15 downto 12) = "1100" and mem_addri(11 downto 10) /= "11" then
                -- PST - 3072 words, address 49152 to 52223 (0xC000 to 0xCBFF)
                selectCor <= '0';
                selectPST <= '1';
                selectPSS <= '0';
                if mem_we = '1' then
                    o_PST_we <= '1';
                else
                    o_PST_we <= '0';
                end if;
                o_cor_we <= '0';
                o_PSS_we <= '0';                
            elsif mem_addri(15 downto 10) = "110100" and mem_addri(9 downto 8) /= "11" then
                -- PSS - 768 words, Address 53248 to 54015 (0xD000 to 0xD2FF)
                selectCor <= '0';
                selectPST <= '0';
                selectPSS <= '1';
                if mem_we = '1' then
                    o_PSS_we <= '1';
                else
                    o_PSS_we <= '0';
                end if;
                o_cor_we <= '0';
                o_PST_we <= '0';
            else
                selectCor <= '0';
                selectPST <= '0';
                selectPSS <= '0';
                o_PSS_we <= '0';
                o_Cor_we <= '0';
                o_PST_we <= '0';
            end if;
            
            mem_wr_data <= sig_din(17 downto 0);  -- out std_logic_vector(17 downto 0);
            mem_addri <= sig_addr(17 downto 2);    -- out std_logic_vector(15 downto 0);
            
            --
            selectCorDel1 <= selectCor;
            selectPSTDel1 <= selectPST;
            selectPSSDel1 <= selectPSS;
            
            --
            selectCorDel2 <= selectCorDel1;
            selectPSTDel2 <= selectPSTDel1;
            selectPSSDel2 <= selectPSSDel1;
            
            --
            selectCorDel3 <= selectCorDel2;
            selectPSTDel3 <= selectPSTDel2;
            selectPSSDel3 <= selectPSSDel2;
            
            --
            if selectCorDel3 = '1' then
                sig_dout(17 downto 0) <= i_cor_rd_data;
            elsif selectPSSDel3 = '1' then
                sig_dout(17 downto 0) <= i_PSS_rd_data;
            elsif selectPSTDel3 = '1' then
                sig_dout(17 downto 0) <= i_PST_rd_data;
            else
                sig_dout(17 downto 0) <= (others => '0');
            end if;
            sig_dout(31 downto 18) <= (others => '0');
            
    
        end if;
    end process;
    
end str;

