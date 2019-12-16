---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Coarse (CTC) - HBM Wrapper
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert_abel@gmx.net)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- Put the HBM signals into nice records.
--
---------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

Library xpm;
use xpm.vcomponents.all;

library axi4_lib;
use axi4_lib.axi4_full_pkg.all;

entity hbm_wrapper is
  Port (i_hbm_ref_clk       : in  std_logic; 
        i_axi_clk           : in  std_logic; 
        i_axi_clk_rst       : in  std_logic;
        i_saxi_00           : in  t_axi4_full_mosi;
        o_saxi_00           : out t_axi4_full_miso;
        i_saxi_14           : in  t_axi4_full_mosi;
        o_saxi_14           : out t_axi4_full_miso;
        i_saxi_15           : in  t_axi4_full_mosi;
        o_saxi_15           : out t_axi4_full_miso;
        i_apb_clk           : in  std_logic;   
        o_apb_complete      : out std_logic
  );
end entity hbm_wrapper;
   
architecture Behavioral of hbm_wrapper is
    COMPONENT HBM_MC0
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
        AXI_14_ACLK : IN STD_LOGIC;
        AXI_14_ARESET_N : IN STD_LOGIC;
        AXI_14_ARADDR : IN STD_LOGIC_VECTOR(32 DOWNTO 0);
        AXI_14_ARBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        AXI_14_ARID : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
        AXI_14_ARLEN : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        AXI_14_ARSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        AXI_14_ARVALID : IN STD_LOGIC;
        AXI_14_AWADDR : IN STD_LOGIC_VECTOR(32 DOWNTO 0);
        AXI_14_AWBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        AXI_14_AWID : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
        AXI_14_AWLEN : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        AXI_14_AWSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        AXI_14_AWVALID : IN STD_LOGIC;
        AXI_14_RREADY : IN STD_LOGIC;
        AXI_14_BREADY : IN STD_LOGIC;
        AXI_14_WDATA : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
        AXI_14_WLAST : IN STD_LOGIC;
        AXI_14_WSTRB : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        AXI_14_WDATA_PARITY : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        AXI_14_WVALID : IN STD_LOGIC;
        AXI_14_ARREADY : OUT STD_LOGIC;
        AXI_14_AWREADY : OUT STD_LOGIC;
        AXI_14_RDATA_PARITY : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        AXI_14_RDATA : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
        AXI_14_RID : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
        AXI_14_RLAST : OUT STD_LOGIC;
        AXI_14_RRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        AXI_14_RVALID : OUT STD_LOGIC;
        AXI_14_WREADY : OUT STD_LOGIC;
        AXI_14_BID : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
        AXI_14_BRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        AXI_14_BVALID : OUT STD_LOGIC;        
        AXI_15_ACLK : IN STD_LOGIC;
        AXI_15_ARESET_N : IN STD_LOGIC;
        AXI_15_ARADDR : IN STD_LOGIC_VECTOR(32 DOWNTO 0);
        AXI_15_ARBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        AXI_15_ARID : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
        AXI_15_ARLEN : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        AXI_15_ARSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        AXI_15_ARVALID : IN STD_LOGIC;
        AXI_15_AWADDR : IN STD_LOGIC_VECTOR(32 DOWNTO 0);
        AXI_15_AWBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        AXI_15_AWID : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
        AXI_15_AWLEN : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        AXI_15_AWSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        AXI_15_AWVALID : IN STD_LOGIC;
        AXI_15_RREADY : IN STD_LOGIC;
        AXI_15_BREADY : IN STD_LOGIC;
        AXI_15_WDATA : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
        AXI_15_WLAST : IN STD_LOGIC;
        AXI_15_WSTRB : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        AXI_15_WDATA_PARITY : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        AXI_15_WVALID : IN STD_LOGIC;
        AXI_15_ARREADY : OUT STD_LOGIC;
        AXI_15_AWREADY : OUT STD_LOGIC;
        AXI_15_RDATA_PARITY : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        AXI_15_RDATA : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
        AXI_15_RID : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
        AXI_15_RLAST : OUT STD_LOGIC;
        AXI_15_RRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        AXI_15_RVALID : OUT STD_LOGIC;
        AXI_15_WREADY : OUT STD_LOGIC;
        AXI_15_BID : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
        AXI_15_BRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        AXI_15_BVALID : OUT STD_LOGIC;        
        APB_0_PWDATA        : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        APB_0_PADDR         : IN STD_LOGIC_VECTOR(21 DOWNTO 0);
        APB_0_PCLK          : IN STD_LOGIC;
        APB_0_PENABLE       : IN STD_LOGIC;
        APB_0_PRESET_N      : IN STD_LOGIC;
        APB_0_PSEL          : IN STD_LOGIC;
        APB_0_PWRITE        : IN STD_LOGIC;
        APB_0_PRDATA        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        APB_0_PREADY        : OUT STD_LOGIC;
        APB_0_PSLVERR       : OUT STD_LOGIC;
        apb_complete_0      : OUT STD_LOGIC;
        DRAM_0_STAT_CATTRIP : OUT STD_LOGIC;
        DRAM_0_STAT_TEMP    : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
      );
    END COMPONENT;

    signal apb_complete_i     : std_logic := '0';
    signal apb_complete_cdc   : std_logic := '0';

    signal axi_rst_n     : std_logic;
    signal apb_rst_n     : std_logic;
    signal apb_rst_n_cdc : std_logic;
    
    type hbm_state_t is (s_INIT, s_RESET, s_POST_RESET, s_RUNNING);
    signal hbm_state : hbm_state_t;
    
    signal reset_counter : unsigned (7 downto 0);

begin
    
    --CDC: APB to AXI
    E_CDC_APB_COMPLETE : xpm_cdc_single
    generic map (
        DEST_SYNC_FF => 2,
        INIT_SYNC_FF => 0,
        SIM_ASSERT_CHK => 0,
        SRC_INPUT_REG => 1 
    )
    port map (
        src_clk  => i_apb_clk, 
        src_in   => apb_complete_i,
        dest_clk => i_axi_clk,
        dest_out => apb_complete_cdc
    );

    --CDC: AXI to APB
    E_CDC_APB_RST : xpm_cdc_single
    generic map (
        DEST_SYNC_FF => 2,
        INIT_SYNC_FF => 0,
        SIM_ASSERT_CHK => 0,
        SRC_INPUT_REG => 1 
    )
    port map (
        src_clk  => i_axi_clk, 
        src_in   => apb_rst_n,
        dest_clk => i_apb_clk,
        dest_out => apb_rst_n_cdc
    );
    
    --RESET LOGIC
    P_RESET_FSM:process (i_axi_clk)
    begin
        if rising_edge(i_axi_clk) then
            o_apb_complete  <= '0';
            axi_rst_n       <= '1';
            apb_rst_n       <= '1';
            case hbm_state is
            when s_INIT=>                
                if i_axi_clk_rst='1' then
                    hbm_state <= s_RESET;
                end if;
            when s_RESET=>    
                axi_rst_n <= '0';
                apb_rst_n <= '0';
                if reset_counter(reset_counter'HIGH)='1' then
                    hbm_state <= s_POST_RESET;
                end if;    
            when s_POST_RESET=>    
                if apb_complete_cdc='1' then
                    hbm_state <= s_RUNNING;
                end if;
            when s_RUNNING =>
                o_apb_complete <= '1';
                if i_axi_clk_rst='1' then
                    o_apb_complete <= '0';
                    hbm_state <= s_RESET;
                end if;
            end case;
        end if;                    
    end process;

    P_RESET_COUNTER:process (i_axi_clk)
    begin
        if rising_edge(i_axi_clk) then
            if hbm_state/=s_RESET then
                reset_counter <= (others=>'0');
            else
                reset_counter <= reset_counter + 1;
            end if;    
        end if;
    end process;

    HBM_MC0_STACK_1: HBM_MC0  
    PORT MAP (
    HBM_REF_CLK_0       => i_hbm_ref_clk,
    AXI_00_ACLK         => i_axi_clk,
    AXI_00_ARESET_N     => axi_rst_n,
    AXI_00_ARADDR       => i_saxi_00.araddr(32 downto 0),
    AXI_00_ARBURST      => i_saxi_00.arburst,
    AXI_00_ARID         => i_saxi_00.arid(5 downto 0),
    AXI_00_ARLEN        => i_saxi_00.arlen(3 downto 0),
    AXI_00_ARSIZE       => i_saxi_00.arsize,
    AXI_00_ARVALID      => i_saxi_00.arvalid,
    AXI_00_AWADDR       => i_saxi_00.awaddr(32 downto 0),
    AXI_00_AWBURST      => i_saxi_00.awburst,
    AXI_00_AWID         => i_saxi_00.awid(5 downto 0),
    AXI_00_AWLEN        => i_saxi_00.awlen(3 downto 0),
    AXI_00_AWSIZE       => i_saxi_00.awsize,
    AXI_00_AWVALID      => i_saxi_00.awvalid,
    AXI_00_RREADY       => i_saxi_00.rready,
    AXI_00_BREADY       => i_saxi_00.bready,
    AXI_00_WDATA        => i_saxi_00.wdata(255 downto 0),
    AXI_00_WLAST        => i_saxi_00.wlast,
    AXI_00_WSTRB        => i_saxi_00.wstrb(31 downto 0),
    AXI_00_WDATA_PARITY => (others => '0'),
    AXI_00_WVALID       => i_saxi_00.wvalid,
    AXI_00_ARREADY      => o_saxi_00.arready,
    AXI_00_AWREADY      => o_saxi_00.awready,
    AXI_00_RDATA_PARITY => open,
    AXI_00_RDATA        => o_saxi_00.rdata(255 downto 0),
    AXI_00_RID          => o_saxi_00.rid(5 downto 0),
    AXI_00_RLAST        => o_saxi_00.rlast,
    AXI_00_RRESP        => o_saxi_00.rresp,
    AXI_00_RVALID       => o_saxi_00.rvalid,
    AXI_00_WREADY       => o_saxi_00.wready,
    AXI_00_BID          => o_saxi_00.bid(5 downto 0),
    AXI_00_BRESP        => o_saxi_00.bresp,
    AXI_00_BVALID       => o_saxi_00.bvalid,

    AXI_14_ACLK         => i_axi_clk,
    AXI_14_ARESET_N     => axi_rst_n,
    AXI_14_ARADDR       => i_saxi_14.araddr(32 downto 0),
    AXI_14_ARBURST      => i_saxi_14.arburst,
    AXI_14_ARID         => i_saxi_14.arid(5 downto 0),
    AXI_14_ARLEN        => i_saxi_14.arlen(3 downto 0),
    AXI_14_ARSIZE       => i_saxi_14.arsize,
    AXI_14_ARVALID      => i_saxi_14.arvalid,
    AXI_14_AWADDR       => i_saxi_14.awaddr(32 downto 0),
    AXI_14_AWBURST      => i_saxi_14.awburst,
    AXI_14_AWID         => i_saxi_14.awid(5 downto 0),
    AXI_14_AWLEN        => i_saxi_14.awlen(3 downto 0),
    AXI_14_AWSIZE       => i_saxi_14.awsize,
    AXI_14_AWVALID      => i_saxi_14.awvalid,
    AXI_14_RREADY       => i_saxi_14.rready,
    AXI_14_BREADY       => i_saxi_14.bready,
    AXI_14_WDATA        => i_saxi_14.wdata(255 downto 0),
    AXI_14_WLAST        => i_saxi_14.wlast,
    AXI_14_WSTRB        => i_saxi_14.wstrb(31 downto 0),
    AXI_14_WDATA_PARITY => (others => '0'),
    AXI_14_WVALID       => i_saxi_14.wvalid,
    AXI_14_ARREADY      => o_saxi_14.arready,
    AXI_14_AWREADY      => o_saxi_14.awready,
    AXI_14_RDATA_PARITY => open,
    AXI_14_RDATA        => o_saxi_14.rdata(255 downto 0),
    AXI_14_RID          => o_saxi_14.rid(5 downto 0),
    AXI_14_RLAST        => o_saxi_14.rlast,
    AXI_14_RRESP        => o_saxi_14.rresp,
    AXI_14_RVALID       => o_saxi_14.rvalid,
    AXI_14_WREADY       => o_saxi_14.wready,
    AXI_14_BID          => o_saxi_14.bid(5 downto 0),
    AXI_14_BRESP        => o_saxi_14.bresp,
    AXI_14_BVALID       => o_saxi_14.bvalid,

    AXI_15_ACLK         => i_axi_clk,
    AXI_15_ARESET_N     => axi_rst_n,
    AXI_15_ARADDR       => i_saxi_15.araddr(32 downto 0),
    AXI_15_ARBURST      => i_saxi_15.arburst,
    AXI_15_ARID         => i_saxi_15.arid(5 downto 0),
    AXI_15_ARLEN        => i_saxi_15.arlen(3 downto 0),
    AXI_15_ARSIZE       => i_saxi_15.arsize,
    AXI_15_ARVALID      => i_saxi_15.arvalid,
    AXI_15_AWADDR       => i_saxi_15.awaddr(32 downto 0),
    AXI_15_AWBURST      => i_saxi_15.awburst,
    AXI_15_AWID         => i_saxi_15.awid(5 downto 0),
    AXI_15_AWLEN        => i_saxi_15.awlen(3 downto 0),
    AXI_15_AWSIZE       => i_saxi_15.awsize,
    AXI_15_AWVALID      => i_saxi_15.awvalid,
    AXI_15_RREADY       => i_saxi_15.rready,
    AXI_15_BREADY       => i_saxi_15.bready,
    AXI_15_WDATA        => i_saxi_15.wdata(255 downto 0),
    AXI_15_WLAST        => i_saxi_15.wlast,
    AXI_15_WSTRB        => i_saxi_15.wstrb(31 downto 0),
    AXI_15_WDATA_PARITY => (others => '0'),
    AXI_15_WVALID       => i_saxi_15.wvalid,
    AXI_15_ARREADY      => o_saxi_15.arready,
    AXI_15_AWREADY      => o_saxi_15.awready,
    AXI_15_RDATA_PARITY => open,
    AXI_15_RDATA        => o_saxi_15.rdata(255 downto 0),
    AXI_15_RID          => o_saxi_15.rid(5 downto 0),
    AXI_15_RLAST        => o_saxi_15.rlast,
    AXI_15_RRESP        => o_saxi_15.rresp,
    AXI_15_RVALID       => o_saxi_15.rvalid,
    AXI_15_WREADY       => o_saxi_15.wready,
    AXI_15_BID          => o_saxi_15.bid(5 downto 0),
    AXI_15_BRESP        => o_saxi_15.bresp,
    AXI_15_BVALID       => o_saxi_15.bvalid,
   
    APB_0_PWDATA        => (others => '0'),
    APB_0_PADDR         => (others => '0'),
    APB_0_PCLK          => i_apb_clk,
    APB_0_PENABLE       => '0',
    APB_0_PRESET_N      => apb_rst_n_cdc,
    APB_0_PSEL          => '0',
    APB_0_PWRITE        => '0',
    APB_0_PRDATA        => open,
    APB_0_PREADY        => open,
    APB_0_PSLVERR       => open,
    apb_complete_0      => apb_complete_i,
    DRAM_0_STAT_CATTRIP => open,
    DRAM_0_STAT_TEMP    => open
  );

end Behavioral;
