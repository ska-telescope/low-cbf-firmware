---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Coarse (CTF) - Synth Wrapper
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert_abel@gmx.net)
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
-- It is explicitly excluded from synthesis using the function THIS_IS_SIMULATION.
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

library work;
use work.ctc_pkg.all;

library ct_hbm_lib;

Library axi4_lib;
USE axi4_lib.axi4_lite_pkg.ALL;
use axi4_lib.axi4_full_pkg.all;

entity synth_wrapper is
    generic (
        g_FPGA_COUNT           : integer := 3;          --PISA: 3
        g_USE_HBM              : boolean := TRUE;       --SYNTH: TRUE!!!  --TRUE: use Xilinx' HBM model, FALSE: use HBM emulator (simulation only)
        g_HBM_EMU_STUTTER      : boolean := FALSE;
        g_HBM_BURST_LEN        : integer := 16;         --PISA: 16    --length of one continuous HBM access (more than 16 would require separating this length from the ATOM size) 
        g_STATIONS_PER_PORT    : integer := 2;          --PISA: 2          
        g_COARSE_CHANNELS      : integer := 128;        --PISA: 128   --how many differnet CCs are there?
        g_CC_GROUP_SIZE        : integer := 8;          --PISA: 8     --how many coarse channels come in consecutively?
        g_INPUT_BLOCK_SIZE     : integer := 2048;       --PISA: 2048  --how many time stamps are in one CC?  
        g_OUTPUT_BLOCK_SIZE    : integer := 4096;       --PISA: 4096  --how many time stamps are in one output block?
        g_OUTPUT_TIME_COUNT    : integer := 204;        --PISA: 204   --how many output blocks come consecutively?
        g_OUTPUT_PRELOAD       : integer := 11;         --PISA: 11    --how many output blocks do we need to preload before the real data comes?
        g_MAXIMUM_DRIFT        : integer := 20;         --PISA: 20    --how many packet counts are stations allowed to be too late?
        g_STATION_GROUP_SIZE   : integer := 2;          --PISA: 2     --how many stations are in one station_group (on the output side)                    
        g_AUX_WIDTH            : integer := 24;         --PISA: 24    --unit: input blocks 
        g_WIDTH_PADDING        : integer := 26;         --PISA: 26    --unit: input blocks
        g_COARSE_DELAY_OFFSET  : integer := 2;          --PISA: 2     --how many input blocks too early do we start reading to allow for coarse delay?
        --                                          ms       us       ns       ps        coarse   count   st    pol   ||st  ||pol  integration time in s 
        g_PS_PER_OUTPUT_BLOCK  : integer := integer(1000.0 * 1000.0 * 1000.0 * 1000.0 / (128.0  * 215.0 * 6.0 * 2.0 / 2.0 / 2.0  / 0.902430720))
    );
    port ( 
        i_hbm_ref_clk     : in  std_logic;
        i_hbm_clk         : in  std_logic;
        i_apb_clk         : in  std_logic;
        i_input_clk       : in std_logic;            
        i_output_clk      : in std_logic;            
        i_mace_clk        : in std_logic;
        i_mace_clk_rst    : in std_logic;
        --MACE:
        i_saxi_mosi       : IN  t_axi4_lite_mosi;
        o_saxi_miso       : OUT t_axi4_lite_miso;
        --wall time:
        i_input_clk_wall_time   : in t_wall_time;    
        i_output_clk_wall_time : in t_wall_time;            
        i_data_in         : in  std_logic_vector(pc_CTC_INPUT_WIDTH-1 downto 0);
        i_data_in_vld     : in  std_logic;
        i_data_in_sop     : in  std_logic;
        o_start_of_frame  : out std_logic;
        o_header_out_vld  : out std_logic;
        o_header_out      : out t_ctc_output_header_a(pc_CTC_OUTPUT_NUMBER-1 downto 0);
        o_data_out        : out t_ctc_output_data_a(pc_CTC_OUTPUT_NUMBER-1 downto 0);
        o_data_out_vld    : out std_logic;
        o_packet_vld      : out std_logic_vector(pc_CTC_OUTPUT_NUMBER-1 downto 0);
        i_data_out_stop   : in  std_logic
    );
end synth_wrapper;

architecture Behavioral of synth_wrapper is

    signal mace_clk_rst   : std_logic := '1';
    signal hbm_clk_rst    : std_logic := '1';
    signal input_clk_rst  : std_logic := '1';
    signal output_clk_rst : std_logic := '1';

    signal data_in      : std_logic_vector(pc_CTC_INPUT_WIDTH-1 downto 0);
    signal data_in_vld  : std_logic;
    signal data_in_sop  : std_logic;
   
    signal input_clk_wall_time  : t_wall_time;
    signal output_clk_wall_time : t_wall_time;

    signal start_of_frame  : std_logic;
    signal header_out_vld  : std_logic;
    signal header_out      : t_ctc_output_header_a(pc_CTC_OUTPUT_NUMBER-1 downto 0);
    signal data_out        : t_ctc_output_data_a(pc_CTC_OUTPUT_NUMBER-1 downto 0);
    signal data_out_vld    : std_logic;
    signal data_out_stop   : std_logic;
    
    signal packet_vld      : std_logic_vector(pc_CTC_OUTPUT_NUMBER-1 downto 0);

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
    -- Coarse Corner Turner
    ---------------------------------------------------------------------------------------------------
    E_DUT: entity work.ctc 
    generic map(
        g_USE_DATA_IN_STOP    => FALSE,
        g_FPGA_COUNT          => g_FPGA_COUNT,
        g_INPUT_STOP_WORDS    => 10,
        g_USE_HBM             => g_USE_HBM,
        g_HBM_EMU_STUTTER     => g_HBM_EMU_STUTTER,
        g_HBM_BURST_LEN       => g_HBM_BURST_LEN,
        g_COARSE_CHANNELS     => g_COARSE_CHANNELS,
        g_INPUT_BLOCK_SIZE    => g_INPUT_BLOCK_SIZE,
        g_OUTPUT_BLOCK_SIZE   => g_OUTPUT_BLOCK_SIZE,
        g_OUTPUT_TIME_COUNT   => g_OUTPUT_TIME_COUNT,
        g_OUTPUT_PRELOAD      => g_OUTPUT_PRELOAD,
        g_STATION_GROUP_SIZE  => g_STATION_GROUP_SIZE,
        g_AUX_WIDTH           => g_AUX_WIDTH,
        g_WIDTH_PADDING       => g_WIDTH_PADDING,
        g_COARSE_DELAY_OFFSET => g_COARSE_DELAY_OFFSET,
        g_MAXIMUM_DRIFT       => g_MAXIMUM_DRIFT
    ) port map ( 
        i_hbm_clk         => i_hbm_clk,
        i_input_clk       => i_input_clk,
        i_output_clk      => i_output_clk,
        i_mace_clk        => i_mace_clk,
        i_mace_clk_rst    => mace_clk_rst,
        --MACE:
        i_saxi_mosi       => saxi_mosi,
        o_saxi_miso       => saxi_miso,
         --wall time:
        i_input_clk_wall_time => input_clk_wall_time,
        i_output_clk_wall_time => output_clk_wall_time,
        --ingress (in input_clk)
        i_data_in         => data_in,
        i_data_in_vld     => data_in_vld,
        i_data_in_sop     => data_in_sop,
        --egress (in output_clk)
        o_start_of_frame  => start_of_frame,
        o_header_out      => header_out, 
        o_data_out        => data_out,
        o_data_out_vld    => data_out_vld,
        o_packet_vld      => packet_vld,
        i_data_out_stop   => data_out_stop,
        --HBM INTERFACE:
        o_hbm_clk_rst => hbm_rst,
        o_hbm_mosi    => hbm_mosi,
        i_hbm_miso    => hbm_miso,
        i_hbm_ready   => hbm_ready            
    );

    P_FLOP1: process(i_input_clk)
    begin
        if rising_edge(i_input_clk) then
            data_in             <= i_data_in;            
            data_in_vld         <= i_data_in_vld;        
            data_in_sop         <= i_data_in_sop;        
            input_clk_wall_time <= i_input_clk_wall_time;         
        end if;
    end process;

    P_FLOP2: process(i_hbm_clk)
    begin
        if rising_edge(i_hbm_clk) then
        end if;
    end process;

            
    P_FLOP3: process(i_output_clk)
    begin
        if rising_edge(i_output_clk) then
            output_clk_wall_time  <= i_output_clk_wall_time;
            o_data_out            <= data_out;
            o_data_out_vld        <= data_out_vld;
            o_packet_vld          <= packet_vld;
            data_out_stop         <= i_data_out_stop;
            o_start_of_frame      <= start_of_frame;
            o_header_out_vld      <= header_out_vld;
            o_header_out          <= header_out;
        end if;
    end process;
    
    P_FLOP4: process(i_mace_clk)
    begin
        if rising_edge(i_mace_clk) then
            mace_clk_rst         <= i_mace_clk_rst;
            saxi_mosi            <= i_saxi_mosi;
            o_saxi_miso          <= saxi_miso;
        end if;
    end process;

end Behavioral;
