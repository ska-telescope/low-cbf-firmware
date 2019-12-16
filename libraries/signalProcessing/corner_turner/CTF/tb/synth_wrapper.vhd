---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Fine (CTF) - Synth Wrapper
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert.abel@autac.nz)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- This is a dummy synth wrapper flopping all inputs and outputs to make timing analysis meaningful.
-- Set "More Options" of Synthesis Settings to "-mode out_of_context" to compile without using
-- real pins.
--
---------------------------------------------------------------------------------------------------
-- NOTE:
-- There are plenty of generics in play. However, not every combination is supported by the code.
-- The validity of generics is checked by assertions.
--
-- The data bus format supports a metadata part that is only used in simulation to ease debugging.
-- It is explicitly excluded from synthesis using pragmas.
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.ctf_pkg.all;

library ct_hbm_lib;

Library axi4_lib;
USE axi4_lib.axi4_lite_pkg.ALL;
use axi4_lib.axi4_full_pkg.all;

entity synth_wrapper is
Generic (
      g_HBM_BURST_LENGTH : natural := 6;
      g_COARSE_CHANNELS  : natural := 128;
      g_STATION_GROUPS   : natural := 3;
      g_TIME_STAMPS      : natural := 204;
      g_FINE_CHANNELS    : natural := 3456
);      
Port ( i_hbm_ref_clk   : in  STD_LOGIC;
       i_hbm_clk       : in  STD_LOGIC;
       i_input_clk     : in  STD_LOGIC;
       i_apb_clk       : in  STD_LOGIC;
       i_mace_clk      : in std_logic;
       i_mace_clk_rst  : in std_logic;
       i_saxi_mosi     : IN  t_axi4_lite_mosi;
       o_saxi_miso     : OUT t_axi4_lite_miso;
       i_data_in       : in  std_logic_vector(63 downto 0);
       i_data_in_vld   : in  std_logic;
       o_data_in_stop  : out std_logic;  
       o_data_out      : out t_ctf_output_data_a(pc_CTF_OUTPUT_NUMBER-1 downto 0);
       o_header_out    : out t_ctf_output_header_a(pc_CTF_OUTPUT_NUMBER-1 downto 0);
       o_data_out_vld  : out std_logic;
       i_data_out_stop : in  std_logic
     );  
end synth_wrapper;

architecture Behavioral of synth_wrapper is
    
    signal mace_clk_rst   : std_logic := '1';
    
    signal i_rst_p           : STD_LOGIC;
    signal i_data_in_p       : std_logic_vector(63 downto 0);
    signal i_data_in_vld_p   : std_logic;
    signal o_data_in_stop_p  : std_logic;  
    signal o_data_out_p      : t_ctf_output_data_a(pc_CTF_OUTPUT_NUMBER-1 downto 0);
    signal o_header_out_p    : t_ctf_output_header_a(pc_CTF_OUTPUT_NUMBER-1 downto 0);
    signal o_data_out_vld_p  : std_logic;
    signal i_data_out_stop_p : std_logic;
    
    signal saxi_mosi       : t_axi4_lite_mosi;
    signal saxi_miso       : t_axi4_lite_miso;
    
    signal hbm_rst   : std_logic;
    signal hbm_mosi  : t_axi4_full_mosi;
    signal hbm_miso  : t_axi4_full_miso;
    signal hbm_ready : std_logic;   
    
    signal unused_mosi  : t_axi4_full_mosi;
    
begin

    ---------------------------------------------------------------------------------------------------
    -- HBM
    ---------------------------------------------------------------------------------------------------
    E_HBM: entity ct_hbm_lib.hbm_wrapper
    Port Map (
        i_hbm_ref_clk       => i_hbm_ref_clk, 
        i_axi_clk           => i_hbm_clk, 
        i_axi_clk_rst       => hbm_rst,
        i_saxi_00           => hbm_mosi,
        o_saxi_00           => hbm_miso,
        i_saxi_14           => unused_mosi,
        o_saxi_14           => open,
        i_saxi_15           => unused_mosi,
        o_saxi_15           => open,
        o_apb_complete      => hbm_ready,
        i_apb_clk           => i_apb_clk   
    );

    ---------------------------------------------------------------------------------------------------
    --Fine Corner Turner
    ---------------------------------------------------------------------------------------------------
    E_DUT: entity work.ctf
    generic map (
        g_USE_HBM          => TRUE,
        g_HBM_BURST_LENGTH => g_HBM_BURST_LENGTH,
        g_COARSE_CHANNELS  => g_COARSE_CHANNELS,
        g_STATION_GROUPS   => g_STATION_GROUPS,
        g_TIME_STAMPS      => g_TIME_STAMPS,
        g_FINE_CHANNELS    => g_FINE_CHANNELS
    ) port map (
        i_mace_clk      => i_mace_clk,
        i_mace_clk_rst  => mace_clk_rst,
        i_saxi_mosi     => saxi_mosi,
        o_saxi_miso     => saxi_miso,
        i_hbm_clk       => i_hbm_clk,
        i_input_clk     => i_input_clk,
        i_data_in       => i_data_in_p,
        i_data_in_vld   => i_data_in_vld_p,
        o_data_in_stop  => o_data_in_stop_p,  
        o_data_out      => o_data_out_p,
        o_header_out    => o_header_out_p,
        o_data_out_vld  => o_data_out_vld_p,
        i_data_out_stop => i_data_out_stop_p,
        --HBM INTERFACE:
        o_hbm_clk_rst => hbm_rst,
        o_hbm_mosi    => hbm_mosi,
        i_hbm_miso    => hbm_miso,
        i_hbm_ready   => hbm_ready            
    );  

    P_FLOP_INPUT: process(i_input_clk)
    begin
        if rising_edge(i_input_clk) then
            i_data_in_p       <= i_data_in;
            i_data_in_vld_p   <= i_data_in_vld;
            o_data_in_stop    <= o_data_in_stop_p;
        end if;
    end process;


    P_FLOP_HBM: process(i_hbm_clk)
    begin
        if rising_edge(i_hbm_clk) then
            o_data_out        <= o_data_out_p;
            o_header_out      <= o_header_out_p;
            o_data_out_vld    <= o_data_out_vld_p;
            i_data_out_stop_p <= i_data_out_stop;
        end if;
    end process;
    
    P_FLOP_MACE: process(i_mace_clk)
    begin
        if rising_edge(i_mace_clk) then
            mace_clk_rst         <= i_mace_clk_rst;
            saxi_mosi            <= i_saxi_mosi;
            o_saxi_miso          <= saxi_miso;
        end if;
    end process;
end Behavioral;
