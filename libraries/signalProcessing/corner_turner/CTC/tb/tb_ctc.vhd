---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Coarse (CTC) - Test Bench
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert_abel@gmx.net)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- Simulates the Coarse Corner Turner
-- 
-- Creates stimuli and checks the DUT's output response
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
use IEEE.MATH_REAL.ALL;

library std;
use std.env.all;

library ct_hbm_lib;

library common_tb_lib;
use common_tb_lib.common_tb_pkg.all;

Library axi4_lib;
USE axi4_lib.axi4_lite_pkg.ALL;
use axi4_lib.axi4_full_pkg.all;

use work.ctc_pkg.all;
use work.ctc_config_reg_pkg.all;

Library common_lib;
use common_lib.common_pkg.ALL;

entity tb_ctc is
    generic (
        g_USE_DATA_IN_STOP     : boolean := TRUE;       --PISA: FALSE -- should normally be set to TRUE to allow more scrutiny in TB, if FALSE, set g_ALLOW_MORE_MISSING to TRUE 
        g_USE_HBM              : boolean := FALSE;      --TRUE: use Xilinx' HBM model, FALSE: use HBM emulator (simpler, faster, no SystemVerilog needed)
        g_HBM_EMU_STUTTER      : boolean := FALSE;      --if HBM emulator used: set w_ready and wa_ready to '0' in a pseudo random pattern    
        g_INPUT_STUTTER        : boolean := FALSE;      --TB: create random pattern of invalid input cycles  
        g_OUTPUT_STUTTER       : boolean := FALSE;      --TB: create random pattern of output stop cycles  
        g_SCRAMBLE_INPUT_DATA  : boolean := TRUE;       --PISA: TRUE  --random order of Coarse Channels, stations drift apart from another (turn off for easier debugging)
        g_MAXIMUM_SIM_DRIFT    : integer := 2;          --PISA: 20    --how far can stations drift away from each other in Stimuli?
        g_MAXIMUM_CTC_DRIFT    : integer := 2;          --PISA: 20    --how far does the CTC allow stations to be late before cutting them off?
        g_ALLOW_MORE_MISSING   : boolean := FALSE;      --TB: allow extra missing packets (due to packets being too late)       
        g_MISSING_PACKET_RATE  : integer := 100;        --TB: 0=none, 1=all, x=1/x packets missing
        g_AWOL                 : boolean := TRUE;       --TB: have a station go AWOL for a while
        g_AWOL_STATION         : integer := 2;          --TB: which station goes AWOL? 
        g_AWOL_START           : integer := 0;          --TB: when does the station go AWOL?
        g_AWOL_END             : integer := 40;         --TB: when does the station come back online?
        g_BLACKOUT             : boolean := FALSE;      --TB: have ALL stations go AWOL for a while
        g_BLACKOUT_START       : integer := 40;         --TB: when does the Blackout start?
        g_BLACKOUT_END         : integer := 80;         --TB: when does the Blackout end?
        g_HBM_BURST_LEN        : integer := 16;         --PISA: 16    --length of HBM burst 
        g_SKIP_START_BLOCKS    : integer := 7;          --            --configure the system to wait for outer time stamp >= g_SKIP_START_BLOCKS
        g_FIRST_PACKET_OFFSET  : integer := 2**11;      --TB          --at which time stamp do we start sending (and the skipping) 
        g_FLUSHOUT_END_BLOCKS  : integer := 0; --g_MAXIMUM_CTC_DRIFT+1;    --send final blocks to allow for last buffer to empty
        g_FPGA_COUNT           : integer := 3;          --PISA: 3     --how many FPGAs are used?
        g_FPGA_ID              : integer := 0;          --            --number of this FPGA
        g_ITERATIONS           : integer := 32;         --PISA: inf   --outer timestamp iterations
        g_COARSE_CHANNELS      : integer := 4;          --PISA: 128   --how many different CCs are there?
        g_CC_GROUP_SIZE        : integer := 2;          --PISA: 8     --how many coarse channels come in consecutively?
        g_INPUT_BLOCK_SIZE     : integer := 512; --256  --PISA: 2048  --how many time stamps are in one CC? (unit: 32 bit (dual pol)) 
        g_OUTPUT_BLOCK_SIZE    : integer := 1024;--512  --PISA: 4096  --how many time stamps are in one output block? (unit: 32 bit (dual pol))
        g_OUTPUT_TIME_COUNT    : integer := 12;   --204  --PISA: 204   --how many output blocks come consecutively?
        g_STATION_GROUP_SIZE   : integer := 2;          --PISA: 2     --how many stations are in one station_group (on the output side)                    
        --
        -- g_AUX_WIDTH = 2*g_OUTPUT_TIME_COUNT - (pc_CTC_MAX_STATIONS*g_COARSE_CHANNELS)/2   (if this is negative, change the values above!)
        g_AUX_WIDTH           : integer := 12;--24     --unit: input blocks   --PISA: 24
        g_WIDTH_PADDING       : integer := 7; --26     --unit: input blocks   --PISA: 26
        g_OUTPUT_PRELOAD      : integer := 5; --11     --unit: output blocks  --PISA: 11    --how many output blocks do we need to preload before the real data comes?
        g_COARSE_DELAY_OFFSET : integer := 1;          --unit: output blocks  --PISA: 1     --how many output blocks too early do we start reading to allow for coarse delay?
        --                           
        g_SAMPLE_RATE_IN_NS        : integer := 1080;  --PISA: 1080 ns                                     
        g_INTEGRATION_TIME_IN_PS   : real := real(g_SAMPLE_RATE_IN_NS * 1000 * g_OUTPUT_BLOCK_SIZE * g_OUTPUT_TIME_COUNT); --PISA: 0.9s
        --                                                                                                                                                                                                                    
        g_PS_PER_OUTPUT_BLOCK      : integer := integer(1000.0 * real(g_SAMPLE_RATE_IN_NS) * real(g_OUTPUT_BLOCK_SIZE) * (real(g_OUTPUT_TIME_COUNT) / real(g_OUTPUT_TIME_COUNT+g_OUTPUT_PRELOAD)) / real(128) / real(pc_STATIONS_PER_PORT) / 2.0 * 2.0 * 2.0);
        g_NS_PER_OUTPUT_BLOCK      : integer := g_PS_PER_OUTPUT_BLOCK / 1000;
        g_READOUT_START_TIME       : integer := 550000;      --unit: ns   
        --                                                                      
        g_PS_PER_INPUT_BLOCK       : integer := integer(1000.0 * real(g_SAMPLE_RATE_IN_NS) * real(g_INPUT_BLOCK_SIZE) *                           1.0                                             / real(128) / real(pc_STATIONS_PER_PORT) / 2.0 * 2.0 * 2.0 / 2.0);
        g_NS_PER_INPUT_BLOCK       : integer := g_PS_PER_INPUT_BLOCK / 1000;
        --                                                          IBUF+OBUF    FULL PHASE LENGTH    -- AUX PRELOAD BEFORE FIRST PHASE LENGTH --        CHANNELS * STATIONS / parallel stations     INPUT BLOCK LEN IN PS                               
        g_FRAME_TIME               : integer := 2*g_OUTPUT_TIME_COUNT * (g_COARSE_CHANNELS * pc_STATION_NUMBER / 2) * 2 * g_PS_PER_INPUT_BLOCK;
        g_FIRST_AUX_TIME           : integer :=(2*g_OUTPUT_PRELOAD + 2*g_COARSE_DELAY_OFFSET) * (g_COARSE_CHANNELS * pc_STATION_NUMBER / 2) * 2 * g_PS_PER_INPUT_BLOCK;
        g_IN_OUT_BUFFER_TIME       : integer := 2 * 4 * g_PS_PER_INPUT_BLOCK;
        g_DRIFT_TIME               : integer :=                     4 * (g_COARSE_CHANNELS * pc_STATION_NUMBER / 2) * 2 * g_PS_PER_INPUT_BLOCK;
        g_FIRST_FRAME_CTC_DELAY    : integer := g_FRAME_TIME + g_FIRST_AUX_TIME + g_IN_OUT_BUFFER_TIME + g_DRIFT_TIME;
        g_PRIME_TIME               : integer := g_READOUT_START_TIME - (g_FIRST_FRAME_CTC_DELAY / 1000); --unit: ns
        g_INPUT_BLOCK_TIME_OFFSET  : integer := 1000 --unit: ns 
    );
end tb_ctc;

architecture sim of tb_ctc is
    
    function addr (i: t_register_address) return integer is
    begin
        return i.base_address + i.address;
    end function;
    
    
    constant c_INPUT_CLK_MHZ            : real := 390.0;
    constant c_OUTPUT_CLK_MHZ           : real := 420.0;
    --                                                             ns       ps                 (1/us) 
    constant c_INPUT_CLK_PS_PER_CYCLE   : integer := integer(CEIL(1000.0 * 1000.0 / c_INPUT_CLK_MHZ));
    constant c_OUTPUT_CLK_PS_PER_CYCLE  : integer := integer(CEIL(1000.0 * 1000.0 / c_OUTPUT_CLK_MHZ));
    
    constant c_STATION_COUNT            : integer := pc_STATIONS_PER_PORT*pc_CTC_INPUT_NUMBER;
    constant c_STATION_GROUP_SIZE       : integer := pc_CTC_OUTPUT_NUMBER; --2 pol per station 
    constant c_STATION_GROUP_COUNT      : integer := c_STATION_COUNT/c_STATION_GROUP_SIZE; 

    constant g_COARSE_GROUPS    : integer := g_COARSE_CHANNELS/g_CC_GROUP_SIZE;
    constant c_OUTER_TIME_LIMIT : integer := g_ITERATIONS*(g_OUTPUT_BLOCK_SIZE/g_INPUT_BLOCK_SIZE)*g_OUTPUT_TIME_COUNT + g_SKIP_START_BLOCKS + (g_OUTPUT_PRELOAD+g_COARSE_DELAY_OFFSET)*2 + g_FLUSHOUT_END_BLOCKS;
    
    constant c_TS_RESOLUTION : time    := ((1.0 / 300000000.0) * real(g_COARSE_CHANNELS) * real(g_FPGA_COUNT) * 27.0 / 32.0) * 1000 ms;
        
    signal mace_clk       : std_logic := '0';
    signal mace_clk_rst   : std_logic := '0';
    signal hbm_clk        : std_logic := '0';
    signal apb_clk        : std_logic := '0';
    signal input_clk      : std_logic := '0';
    signal output_clk     : std_logic := '0';

    signal output_clk_time_in_ps : unsigned(63 downto 0) := (others => '0');
    signal output_clk_time_in_ns : unsigned(63 downto 0);

    signal input_clk_time_in_ps : unsigned(63 downto 0) := (others => '0');
    signal input_clk_time_in_ns : unsigned(63 downto 0);

    signal input_packet_counter : integer := 0;
    
    signal data_in      : t_ctc_input_data;
    signal data_in_slv  : std_logic_vector(pc_CTC_INPUT_WIDTH-1 downto 0);
    signal data_in_vld  : std_logic;
    signal data_in_sop  : std_logic;
    signal data_in_stop : std_logic;
    
    signal ibuf_out     : t_ctc_hbm_data;
    signal ibuf_out_vld : std_logic;

    type integer_a is array(integer range <>) of integer; 
    
    signal coarse_group_scrambler : integer_a(g_COARSE_GROUPS-1 downto 0);
    signal station_log            : integer_a(c_OUTER_TIME_LIMIT*g_COARSE_CHANNELS*c_STATION_COUNT-1 downto 0);

    signal config_start_ts      : std_logic_vector(31 downto 0);
    signal config_start_wt      : t_wall_time;
    signal config_prime_wt      : t_wall_time;
    signal config_output_cycles : std_logic_vector(31 downto 0);
    signal config_input_cycles  : std_logic_vector(31 downto 0);
    signal config_vld           : std_logic; 

    signal output_clk_wall_time : t_wall_time;
    signal input_clk_wall_time  : t_wall_time;
    
    signal hbm_data_out       : t_ctc_hbm_data;
    signal hbm_data_out_vld   : std_logic;
    signal hbm_block_vld      : std_logic;
    signal hbm_data_out_stop  : std_logic := '0';

    signal start_of_frame  : std_logic;
    signal header_out_vld  : std_logic;
    signal header_out      : t_ctc_output_header_a(pc_CTC_OUTPUT_NUMBER-1 downto 0);
    signal data_out        : t_ctc_output_data_a(pc_CTC_OUTPUT_NUMBER-1 downto 0);
    signal data_out_vld    : std_logic;
    signal packet_vld      : std_logic_vector(pc_CTC_OUTPUT_NUMBER-1 downto 0);
    signal data_out_stop   : std_logic := '0';
    
    signal out_finished : std_logic_vector(pc_CTC_OUTPUT_NUMBER-1 downto 0) := (others => '0');

    type t_missing is array(c_OUTER_TIME_LIMIT-1 downto 0, g_COARSE_CHANNELS-1 downto 0, c_STATION_COUNT-1 downto 0) of boolean;
    signal missing : t_missing := (others => (others => (others => false)));

    signal saxi_mosi : t_axi4_lite_mosi;
    signal saxi_miso : t_axi4_lite_miso;
    
    signal hbm_rst   : std_logic;
    signal hbm_mosi  : t_axi4_full_mosi;
    signal hbm_miso  : t_axi4_full_miso;
    signal hbm_ready : std_logic;    

    signal unused_mosi  : t_axi4_full_mosi;
    signal hbm_mace_mosi : t_axi4_full_mosi;
    
begin

    assert g_COARSE_CHANNELS rem g_CC_GROUP_SIZE = 0 report "g_COARSE_CHANNELS must be a multiple of g_CC_GROUP_SIZE"  severity FAILURE;
    assert g_INPUT_BLOCK_SIZE rem (g_HBM_BURST_LEN*8) = 0 report "g_INPUT_BLOCK_SIZE must be a multiple of g_HBM_BURST_LEN*8"  severity FAILURE;
    
    assert g_ALLOW_MORE_MISSING or g_MAXIMUM_SIM_DRIFT<=g_MAXIMUM_CTC_DRIFT report "SIM DRIFT has to be <= CTC DRIFT, or more missing packets have to be allowed." severity FAILURE; 

    --INPUT CLK
    input_clk     <= not input_clk after  c_INPUT_CLK_PS_PER_CYCLE/2 * (1 ps);

   --OUTPUT CLK
    output_clk     <= not output_clk after c_OUTPUT_CLK_PS_PER_CYCLE/2 * (1 ps);

    --HBM CLK: 450MHz
    hbm_clk     <= not hbm_clk after 1.111 ns;

    --100MHz
    apb_clk     <= not apb_clk after 5 ns;
    
    --100MHz
    mace_clk     <= not mace_clk after 5 ns;
    mace_clk_rst <= '0', '1' after 10 ns, '0' after 100 ns;
    
    
    ---------------------------------------------------------------------------------------------------
    -- Time Modules
    ---------------------------------------------------------------------------------------------------
    P_INPUT_TIME: process(input_clk)
    begin
        if rising_edge(input_clk) then
            input_clk_time_in_ps <= input_clk_time_in_ps + c_INPUT_CLK_PS_PER_CYCLE;
        end if;
    end process;
    input_clk_time_in_ns <= input_clk_time_in_ps / 1000;
    input_clk_wall_time  <= slv_to_wall_time(std_logic_vector(input_clk_time_in_ns(pc_WALL_TIME_LEN-1 downto 0)));

    P_OUTPUT_TIME: process(output_clk)
    begin
        if rising_edge(output_clk) then
            output_clk_time_in_ps <= output_clk_time_in_ps + c_OUTPUT_CLK_PS_PER_CYCLE;
        end if;
    end process;
    output_clk_time_in_ns <= output_clk_time_in_ps / 1000;
    output_clk_wall_time  <= slv_to_wall_time(std_logic_vector(output_clk_time_in_ns(pc_WALL_TIME_LEN-1 downto 0)));
    

    ---------------------------------------------------------------------------------------------------
    -- HBM
    ---------------------------------------------------------------------------------------------------
    unused_mosi.wvalid <= '0';
    unused_mosi.awvalid <= '0';
    unused_mosi.arvalid <= '0';
    
    hbm_mace_mosi.wvalid <= '0';
    hbm_mace_mosi.awvalid <= '0';
    hbm_mace_mosi.arvalid <= '0';
    
    GEN_HBM: if g_USE_HBM generate
    begin
        E_HBM: entity ct_hbm_lib.hbm_wrapper
        Port Map (
            i_hbm_ref_clk       => apb_clk, 
            i_axi_clk           => hbm_clk, 
            i_axi_clk_rst       => hbm_rst,
            i_saxi_00           => hbm_mosi,
            o_saxi_00           => hbm_miso,
            i_saxi_14           => hbm_mace_mosi,
            o_saxi_14           => open,
            i_saxi_15           => unused_mosi,
            o_saxi_15           => open,
            o_apb_complete      => hbm_ready,
            i_apb_clk           => apb_clk   
        );
    end generate;
    
    ---------------------------------------------------------------------------------------------------
    -- Coarse Corner Turner
    ---------------------------------------------------------------------------------------------------
    E_DUT: entity work.ctc 
    generic map(
        g_USE_DATA_IN_STOP    => g_USE_DATA_IN_STOP,
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
        g_MAXIMUM_DRIFT       => g_MAXIMUM_CTC_DRIFT,
        g_COARSE_DELAY_OFFSET => 2*g_COARSE_DELAY_OFFSET --unit: input blocks
    ) port map ( 
        i_hbm_clk         => hbm_clk,
        i_input_clk       => input_clk,
        i_output_clk      => output_clk,
        i_mace_clk        => mace_clk,
        i_mace_clk_rst    => mace_clk_rst,
        
        i_saxi_mosi => saxi_mosi,
        o_saxi_miso => saxi_miso,

        i_output_clk_wall_time => output_clk_wall_time,
        i_input_clk_wall_time  => input_clk_wall_time,
        
        i_data_in_record  => data_in,
        i_data_in         => data_in_slv,
        i_data_in_vld     => data_in_vld,
        i_data_in_sop     => data_in_sop,
        o_data_in_stop    => data_in_stop,  
        o_start_of_frame  => start_of_frame,
        o_header_out_vld  => header_out_vld,
        o_header_out      => header_out,
        o_data_out        => data_out,
        o_data_out_vld    => data_out_vld,
        o_packet_vld       => packet_vld,
        i_data_out_stop   => data_out_stop,
        o_debug_ibuf_out      => ibuf_out,
        o_debug_ibuf_out_vld  => ibuf_out_vld,
        o_debug_hbm_out       => hbm_data_out,
        o_debug_hbm_out_vld   => hbm_data_out_vld,
        o_debug_hbm_block_vld => hbm_block_vld,
        
        o_hbm_clk_rst => hbm_rst,
        o_hbm_mosi    => hbm_mosi,
        i_hbm_miso    => hbm_miso,
        i_hbm_ready   => hbm_ready        
    );


    ---------------------------------------------------------------------------------------------------
    -- MACE
    ---------------------------------------------------------------------------------------------------
    P_MACE: process
    begin
        wait for 10 us;
        wait until rising_edge(mace_clk);
        
        -- For some reason the first transaction doesn't work; this is just a dummy transaction
        axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_setup_full_reset_address), true, x"00000001");
        wait until rising_edge(mace_clk);

        --turn mace reset on 
        axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_setup_full_reset_address), true, x"00000001");

        --SETUP:        
            --set start_ts:
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_timing_starting_packet_count_address), true, 
                                 std_logic_vector(TO_UNSIGNED(g_SKIP_START_BLOCKS+g_FIRST_PACKET_OFFSET, 32)));

            --set start_wall_time:
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_timing_starting_wall_time_seconds_address), true, 
                                 X"00000000");
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_timing_starting_wall_time_nanos_address), true, 
                                 std_logic_vector(TO_UNSIGNED(g_READOUT_START_TIME, 32)));
            --set output_cycles:
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_timing_output_cycles_address), true, 
                                 std_logic_vector(TO_UNSIGNED(g_PS_PER_OUTPUT_BLOCK/c_OUTPUT_CLK_PS_PER_CYCLE, 32)));
            
            --set prime wall_time:
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_timing_prime_wall_time_seconds_address), true, 
                                 X"00000000");
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_timing_prime_wall_time_nanos_address), true, 
                                 std_logic_vector(TO_SIGNED(g_PRIME_TIME, 32)));                                                                      
            --set input_cycles:
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_timing_input_cycles_address), true, 
                                 std_logic_vector(TO_UNSIGNED((g_COARSE_CHANNELS * pc_STATION_NUMBER / 2) * 2 * g_PS_PER_INPUT_BLOCK / c_INPUT_CLK_PS_PER_CYCLE, 32)));
                                 
            --USE TIMING VALUES and turn input & output time control on:
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_timing_control_enable_timed_output_address), true,
                                 X"00000001");
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_timing_control_enable_timed_output_address), true,
                                 X"00000000");
            
        --COARSE_DELAY:
            --table 0:
            for adr in 0 to g_COARSE_CHANNELS*pc_STATION_NUMBER-1 loop
                axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_coarse_delay_table_0_address)+2*adr, true,
                                     std_logic_vector(to_signed(17, 16) & to_signed((adr+1)*2, 16)));
                axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_coarse_delay_table_0_address)+2*adr+1, true,
                                     std_logic_vector(to_signed(-(adr mod 15) * 2**10, 16) & to_signed(23, 16)));
            end loop;
        
            --table 1:
            for adr in 0 to g_COARSE_CHANNELS*pc_STATION_NUMBER-1 loop
                axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_coarse_delay_table_1_address)+2*adr, true,
                                     std_logic_vector(to_signed(17, 16) & to_signed((adr+1)*3, 16)));
                axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_coarse_delay_table_1_address)+2*adr+1, true,
                                     std_logic_vector(to_signed(-(adr mod 15) * 2**10, 16) & to_signed(23, 16)));
            end loop;

            --setup to switch active table:
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_coarse_delay_table_select_address), true,
                                 X"00000001");            
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_coarse_delay_packet_count_address), true,
                                 X"00000817");            
            
            --set halt packet count:
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_setup_halt_packet_count_address), true,
                                 X"00000000");            
            


            
        wait for 10 us;
        wait until rising_edge(mace_clk);

        --turn mace reset off 
        axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, c_setup_full_reset_address.base_address + c_setup_full_reset_address.address, true, x"00000000");

        wait for 600 us;
        wait until rising_edge(mace_clk);


        --READ COUNTER
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_valid_blocks_count_address), false, X"00000000");
        
        --RESET COUNTER
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_valid_blocks_reset_address), true, X"00000001");
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_valid_blocks_reset_address), true, X"00000000");
        
        
        wait;
        

        --UPDATE TIMING:        
            --set start_ts:
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_timing_starting_packet_count_address), true, 
                                 X"00000827");

            --set start_wall_time:
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_timing_starting_wall_time_seconds_address), true, 
                                 X"00000000");
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_timing_starting_wall_time_nanos_address), true, 
                                 std_logic_vector(to_unsigned(1150000, 32)));
            --set output_cycles:
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_timing_output_cycles_address), true, 
                                 std_logic_vector(TO_UNSIGNED(g_PS_PER_OUTPUT_BLOCK/c_OUTPUT_CLK_PS_PER_CYCLE, 32)));
            
            --set prime wall_time:
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_timing_prime_wall_time_seconds_address), true, 
                                 X"00000000");
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_timing_prime_wall_time_nanos_address), true, 
                                 std_logic_vector(to_unsigned(680000, 32)));                                                                      
            --set input_cycles:
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_timing_input_cycles_address), true, 
                                 std_logic_vector(TO_UNSIGNED((g_COARSE_CHANNELS * pc_STATION_NUMBER / 2) * 2 * g_PS_PER_INPUT_BLOCK / c_INPUT_CLK_PS_PER_CYCLE, 32)));
                                 
            --USE TIMING VALUES and turn input & output time control on:
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_timing_control_enable_timed_output_address), true,
                                 X"00000001");
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_timing_control_enable_timed_output_address), true,
                                 X"00000000");
            
        wait for 300 us;
        wait until rising_edge(mace_clk);
        
        --READ COUNTER
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_valid_blocks_count_address), false, X"00000000");
       
        wait; --for ever
        
    end process;
    

    ---------------------------------------------------------------------------------------------------
    -- Input Stimulus
    ---------------------------------------------------------------------------------------------------
    P_STIMULI: process
        variable seed1:        positive := 1;
        variable seed2:        positive := 1;  
        variable rand:         real;
        variable dice:         integer;
        variable swap:         integer;
        variable station:      integer := pc_STATIONS_PER_PORT-1;
        variable outer_time:   integer_a(pc_STATIONS_PER_PORT-1 downto 0) := (others => 0); 
        variable coarse_group: integer_a(pc_STATIONS_PER_PORT-1 downto 0) := (others => 0); 
        variable coarse:       integer;
        variable timestamp:    integer;
        variable st:           integer;
        variable log_pointer:  integer := 0;
        variable header:       t_ctc_input_header := pc_CTC_INPUT_HEADER_ZERO;
        variable header_slv:   std_logic_vector(127 downto 0);
        variable min:          integer;
        variable awol:         boolean := false;
    begin
        
        data_in_vld <= '0';
        data_in_sop <= '0';
        
        wait until rising_edge(input_clk);
        wait until rising_edge(input_clk);
        wait until rising_edge(input_clk);
        wait until rising_edge(input_clk);
        
        --Random order of coarse_groups in one station: 
        for cg in 0 to g_COARSE_GROUPS-1 loop
            coarse_group_scrambler(cg) <= cg;
        end loop;
        wait for 1 ps;
        if g_SCRAMBLE_INPUT_DATA then
            for cg in 0 to g_COARSE_GROUPS-1 loop
                uniform(seed1, seed2, rand);
                dice := integer(FLOOR(rand*real(g_COARSE_GROUPS)));
                swap := coarse_group_scrambler(dice);
                coarse_group_scrambler(dice) <= coarse_group_scrambler(cg);
                coarse_group_scrambler(cg)   <= swap;
                wait for 1 ps;
            end loop;
        end if;
        
        wait until rising_edge(input_clk);
                                                   
        while data_in_stop = '1' loop
            data_in_vld <= '0';
            wait until rising_edge(input_clk);
        end loop;
        

        while (outer_time /= (outer_time'range => c_OUTER_TIME_LIMIT)) loop
            uniform(seed1, seed2, rand);
            if g_SCRAMBLE_INPUT_DATA then
                station := integer(FLOOR(rand*real(pc_STATIONS_PER_PORT)));
            else    
                station := (station+1) rem pc_STATIONS_PER_PORT;
            end if;    
            min:=outer_time(0);
            for st in 0 to pc_STATIONS_PER_PORT-1 loop
                if outer_time(st)<min then
                    min:= outer_time(st);
                end if;    
            end loop;
            while (outer_time(station)=c_OUTER_TIME_LIMIT) or outer_time(station)>=min+g_MAXIMUM_SIM_DRIFT loop 
                station := (station+1) rem pc_STATIONS_PER_PORT;
            end loop;    
            station_log(log_pointer) <= station;
            log_pointer := log_pointer+1;
            
            for inner_coarse in 0 to g_CC_GROUP_SIZE-1 loop
                coarse := ((coarse_group_scrambler(coarse_group(station))*g_CC_GROUP_SIZE + inner_coarse));
                st     := station;
                awol   := false;
                
                if (g_AWOL=true and st=g_AWOL_STATION and outer_time(st)>=g_AWOL_START and outer_time(st)<g_AWOL_END) 
                or (g_BLACKOUT=true and outer_time(st)>=g_BLACKOUT_START and outer_time(st)<g_BLACKOUT_END) then
                    awol := true;
                end if;
                
                uniform(seed1, seed2, rand);
                dice := integer(CEIL(rand*real(g_MISSING_PACKET_RATE)));
                if dice=1 or awol=true then
                    missing(outer_time(st), coarse, st) <= true;
                    echoln("Stimuli skipping packet: Outer time:" & integer'image(outer_time(station)) & " ,Coarse: " & integer'image(coarse) & " ,Station: " & integer'image(st));
                    wait for 1 ps;
                else
                    --Start of Package:
                    --Header:
                    header.virtual_channel   := std_logic_vector(to_unsigned(coarse*g_FPGA_COUNT + g_FPGA_ID, 9));
                    header.channel_frequency := std_logic_vector(to_unsigned(coarse, 9));
                    header.station_id        := std_logic_vector(to_unsigned(st, 9));
                    header.packet_count      := std_logic_vector(to_unsigned(outer_time(station)+g_FIRST_PACKET_OFFSET, 32));
                    header_slv               := header_to_slv(header);
                    data_in_slv              <= header_slv(63 downto 0);
                    data_in_sop              <= '1';
                    data_in_vld              <= '1';
                    wait until rising_edge(input_clk);
                    
                    if g_INPUT_STUTTER then
                        uniform(seed1, seed2, rand);
                        dice := integer(FLOOR(rand*6.0));
                        for i in 0 to dice-1 loop
                            data_in_sop <= '0';
                            data_in_vld <= '0';
                            wait until rising_edge(input_clk);
                        end loop;
                    end if;
                    
                    data_in_slv <= header_slv(127 downto 64);
                    data_in_vld <= '1';
                    data_in_sop <= '0';
                    wait until rising_edge(input_clk);
                    
                    if g_INPUT_STUTTER then
                        uniform(seed1, seed2, rand);
                        dice := integer(FLOOR(rand*6.0));
                        for i in 0 to dice-1 loop
                            data_in_sop <= '0';
                            data_in_vld <= '0';
                            wait until rising_edge(input_clk);
                        end loop;
                    end if;
                    
                    --Data:
                    missing(outer_time(station), coarse, st) <= false;
                    for inner_time in 0 to g_INPUT_BLOCK_SIZE/2-1 loop
                        for ts_in_one_cycle in 0 to 1 loop
                            timestamp := g_FIRST_PACKET_OFFSET*g_INPUT_BLOCK_SIZE + outer_time(station)*g_INPUT_BLOCK_SIZE + inner_time*2 + ts_in_one_cycle;
                            for pol in 0 to 1 loop
                                data_in(pol+2*ts_in_one_cycle).meta.in_port <= std_logic_vector(to_unsigned(0, 3));
                                data_in(pol+2*ts_in_one_cycle).meta.coarse  <= std_logic_vector(to_unsigned(coarse, 9));
                                data_in(pol+2*ts_in_one_cycle).meta.station <= std_logic_vector(to_unsigned(st, 9));
                                data_in(pol+2*ts_in_one_cycle).meta.pol     <= std_logic_vector(to_unsigned(pol, 1));
                                data_in(pol+2*ts_in_one_cycle).meta.ts      <= std_logic_vector(to_unsigned(timestamp, 32));
                                data_in(pol+2*ts_in_one_cycle).data.im      <= std_logic_vector(to_unsigned(st  + (timestamp/8)*16, 8));
                                data_in(pol+2*ts_in_one_cycle).data.re      <= std_logic_vector(to_unsigned(pol + coarse*16,    8));
                                wait for 1 ps;
                                data_in_slv <= payload_to_slv(data_in);
                                data_in_vld <= '1';
                            end loop;
                        end loop;                                 
                        wait until rising_edge(input_clk);
                        while data_in_stop = '1' loop
                            data_in_vld <= '0';
                            wait until rising_edge(input_clk);
                        end loop;
                        if g_INPUT_STUTTER then
                            uniform(seed1, seed2, rand);
                            dice := integer(FLOOR(rand*6.0));
                            for i in 0 to dice-1 loop
                                data_in_sop <= '0';
                                data_in_vld <= '0';
                                wait until rising_edge(input_clk);
                            end loop;
                        end if;
                    end loop;
                end if;                       

                while input_clk_time_in_ns < input_packet_counter*g_NS_PER_INPUT_BLOCK+g_INPUT_BLOCK_TIME_OFFSET loop
                    data_in_vld <= '0';
                    wait until rising_edge(input_clk);
                end loop;
                input_packet_counter <= input_packet_counter + 1;
                
            end loop;
            if coarse_group(station) = g_COARSE_GROUPS-1 then
                coarse_group(station) := 0;
                outer_time(station) := outer_time(station) + 1; 
            else
                coarse_group(station) := coarse_group(station) + 1;
            end if;   
        end loop;     
        
        data_in_vld <= '0';
        
        wait;
                
    end process; 





    ---------------------------------------------------------------------------------------------------
    -- Check Input Buffer Output
    ---------------------------------------------------------------------------------------------------
    GEN_CHECK_IBUF_DATA: if g_USE_DATA_IN_STOP=TRUE generate
    begin
        P_CHECK_IBUF_DATA: process
            
            type integer_a is array(integer range <>) of integer; 
            variable station:        integer;
            variable outer_time:     integer_a(pc_CTC_INPUT_NUMBER*pc_STATIONS_PER_PORT-1 downto 0) := (others => 0); 
            variable coarse_group:   integer_a(pc_CTC_INPUT_NUMBER*pc_STATIONS_PER_PORT-1 downto 0) := (others => 0);
            variable in_packet_time: integer := 0;
            variable inner_coarse:   integer := 0;
            variable log_pointer:    integer := 0;
            variable coarse:       integer;
            variable timestamp:    integer;
            variable st:           integer;
            variable in_port:      integer := 0;
            variable u, p:         integer;
            variable t:            string(1 to 255);
        begin
            
            wait until rising_edge(hbm_clk);
            wait until rising_edge(hbm_clk);
            wait until rising_edge(hbm_clk);
            wait until rising_edge(hbm_clk);
            
            while (outer_time /= (outer_time'range => c_OUTER_TIME_LIMIT)) loop
                --we have to wait here, so that in_port is valid
                while ibuf_out_vld/='1' loop
                    wait until rising_edge(hbm_clk);
                end loop;
                in_port := to_integer(unsigned(ibuf_out.meta(0).in_port));
                station := station_log(log_pointer);
                st      := station;
                coarse  := ((coarse_group_scrambler(coarse_group(st))*g_CC_GROUP_SIZE + inner_coarse));
                if outer_time(st)>=g_SKIP_START_BLOCKS then
                    if missing(outer_time(st), coarse, station)=true then
                        echoln("IBUF skipping packet: Outer time:" & integer'image(outer_time(station)) & " ,Coarse: " & integer'image(coarse) & " ,Station: " & integer'image(st));
                    else
                        for in_burst_time in 0 to g_HBM_BURST_LEN-1 loop
                            for in_one_cycle_time in 0 to 7 loop
                                timestamp := g_FIRST_PACKET_OFFSET*g_INPUT_BLOCK_SIZE + outer_time(st)*g_INPUT_BLOCK_SIZE + in_packet_time*g_HBM_BURST_LEN*8 + in_burst_time*8 + in_one_cycle_time;
                                for pol in 0 to 1 loop
                                    p:=(pol+2*in_one_cycle_time);
                                    u:=p*16;
                                    t:=fixed_string("[" & integer'image(p) & "]    bt:" & integer'image(in_burst_time) & ", station:" & integer'image(st) & ", coarse:" & integer'image(coarse), 255);
                                    check_equal(unsigned(ibuf_out.meta(p).in_port), 0                     ,                   "IBUF in_port"&t);
                                    check_equal(unsigned(ibuf_out.meta(p).coarse),  to_unsigned(coarse, 9),                   "IBUF coarse"&t);
                                    check_equal(unsigned(ibuf_out.meta(p).station), to_unsigned(st, 9),                       "IBUF station"&t);
                                    check_equal(unsigned(ibuf_out.meta(p).pol),     to_unsigned(pol, 1),                      "IBUF pol"&t);
                                    check_equal(unsigned(ibuf_out.meta(p).ts),      to_unsigned(timestamp, 32),               "IBUF ts"&t);
                                    check_equal(unsigned(ibuf_out.data(u+15 downto u+8)), to_unsigned(st  + (timestamp/8)*16, 8), "IBUF im"&t); --im
                                    check_equal(unsigned(ibuf_out.data(u+7 downto u)),    to_unsigned(pol + coarse*16,    8), "IBUF re"&t); --re
                                end loop;
                            end loop;
                            wait until rising_edge(hbm_clk);
                            if in_burst_time<g_HBM_BURST_LEN-1 then --otherwise we have a loop at the very start that waits for vld
                                while ibuf_out_vld/='1' loop
                                    wait until rising_edge(hbm_clk);
                                end loop;
                            end if;
                        end loop;
                    end if;                        
                end if;        
                if in_packet_time = g_INPUT_BLOCK_SIZE/g_HBM_BURST_LEN/8-1 then
                    in_packet_time := 0;
                    if inner_coarse = g_CC_GROUP_SIZE-1 then
                        inner_coarse := 0;
                        if coarse_group(st) = g_COARSE_GROUPS-1 then
                            coarse_group(st) := 0;
                            outer_time(st) := outer_time(st) + 1; 
                        else
                            coarse_group(st) := coarse_group(st) + 1;
                        end if;
                        log_pointer := log_pointer + 1;   
                    else                
                        inner_coarse := inner_coarse + 1;
                    end if;  
                else
                    in_packet_time := in_packet_time + 1;
                end if;
            end loop;     
            
            assert ibuf_out_vld='0' report "IBUF: TOO MUCH DATA!" severity FAILURE; 
            
            echoln;
            echoln("!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
            echoln("!                          !");
            echoln("!  ALL IBUF DATA RECEIVED  !");
            echoln("!                          !");
            echoln("!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
            echoln;
            
            wait until ibuf_out_vld='1';
            --we should never get here
            report "IBUF: TOO MUCH DATA!" severity FAILURE;
            
            wait;
                    
        end process; 
    end generate;



    ---------------------------------------------------------------------------------------------------
    -- Check HBM Buffer Output
    ---------------------------------------------------------------------------------------------------
    P_CHECK_HBM_DATA: process
        variable st:           integer;
        variable timestamp:    integer;
        variable u, p:         integer;
        variable t:            string(1 to 255);
        variable pc:           integer;
    begin
        
        wait until rising_edge(hbm_clk);
        wait until rising_edge(hbm_clk);
        wait until rising_edge(hbm_clk);
        wait until rising_edge(hbm_clk);
    
        for iteration in 0 to g_ITERATIONS-1 loop 
            for coarse in 0 to g_COARSE_CHANNELS-1 loop
                for station_group in 0 to c_STATION_GROUP_COUNT-1 loop
                    for ts in 0-g_OUTPUT_BLOCK_SIZE/g_INPUT_BLOCK_SIZE*(g_OUTPUT_PRELOAD+g_COARSE_DELAY_OFFSET) to g_OUTPUT_BLOCK_SIZE/g_INPUT_BLOCK_SIZE*g_OUTPUT_TIME_COUNT-1 loop
                        for station in 0 to c_STATION_GROUP_SIZE-1 loop
                            for packet_time in 0 to g_INPUT_BLOCK_SIZE/8/g_HBM_BURST_LEN-1 loop
                                for burst_time in 0 to g_HBM_BURST_LEN-1 loop
                                    while hbm_data_out_vld/='1' loop
                                        wait until rising_edge(hbm_clk);
                                    end loop;
                                    if hbm_block_vld='1' then
                                        for in_one_cycle_time in 0 to 7 loop
                                            timestamp := g_FIRST_PACKET_OFFSET*g_INPUT_BLOCK_SIZE + iteration*g_OUTPUT_TIME_COUNT*g_OUTPUT_BLOCK_SIZE + ts*g_INPUT_BLOCK_SIZE + g_HBM_BURST_LEN*packet_time*8 + burst_time*8 + in_one_cycle_time + g_SKIP_START_BLOCKS*g_INPUT_BLOCK_SIZE + (g_OUTPUT_PRELOAD+g_COARSE_DELAY_OFFSET)*g_OUTPUT_BLOCK_SIZE;
                                            st        := station_group*c_STATION_GROUP_SIZE + station;
                                            pc        := timestamp / g_INPUT_BLOCK_SIZE - g_FIRST_PACKET_OFFSET;
                                            assert missing(pc, coarse, st)=false report "HBM: Missing packet seen as valid." severity FAILURE;
                                            for pol in 0 to 1 loop
                                                p:=(pol+2*in_one_cycle_time);
                                                u:=p*16;
                                                t:=fixed_string("[" & integer'image(p) & "]    bt:" & integer'image(packet_time) & ", station:" & integer'image(st) & ", coarse:" & integer'image(coarse), 255);
                                                check_equal(unsigned(hbm_data_out.meta(p).in_port), 0,                                        "HBM in_port"&t);
                                                check_equal(unsigned(hbm_data_out.meta(p).coarse),  to_unsigned(coarse, 9),                   "HBM coarse"&t);
                                                check_equal(unsigned(hbm_data_out.meta(p).station), to_unsigned(st, 9),                       "HBM station"&t);
                                                check_equal(unsigned(hbm_data_out.meta(p).pol),     to_unsigned(pol, 1),                      "HBM pol"&t);
                                                check_equal(unsigned(hbm_data_out.meta(p).ts),      to_unsigned(timestamp, 32),               "HBM ts"&t);
                                                check_equal(unsigned(hbm_data_out.data(u+15 downto u+8)), to_unsigned(st  + (timestamp/8)*16, 8), "HBM im"&t);
                                                check_equal(unsigned(hbm_data_out.data(u+7 downto u)),    to_unsigned(pol + coarse*16,    8), "HBM re"&t);
                                            end loop;
                                        end loop;
                                    else
                                        timestamp := g_FIRST_PACKET_OFFSET*g_INPUT_BLOCK_SIZE + iteration*g_OUTPUT_TIME_COUNT*g_OUTPUT_BLOCK_SIZE + ts*g_INPUT_BLOCK_SIZE + g_HBM_BURST_LEN*packet_time*8 + burst_time*8 + g_SKIP_START_BLOCKS*g_INPUT_BLOCK_SIZE + 2*(g_OUTPUT_PRELOAD+g_COARSE_DELAY_OFFSET)*g_INPUT_BLOCK_SIZE;
                                        st        := station_group*c_STATION_GROUP_SIZE + station;
                                        pc        := timestamp / g_INPUT_BLOCK_SIZE - g_FIRST_PACKET_OFFSET;
                                        assert g_ALLOW_MORE_MISSING or missing(pc, coarse, st)=true report "HBM: Valid packet seen as missing." severity FAILURE;
                                    end if;    
                                    wait until rising_edge(hbm_clk);
                                end loop;    
                            end loop;
                        end loop;    
                    end loop;
                end loop;                                    
            end loop;
        end loop;            

        echoln;
        echoln("!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        echoln("!                          !");
        echoln("!  ALL HBM DATA RECEIVED   !");
        echoln("!                          !");
        echoln("!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        echoln;
        
        wait;
                
    end process; 



    ---------------------------------------------------------------------------------------------------
    -- Check Output Buffer Output
    ---------------------------------------------------------------------------------------------------
    P_OUTPUT_STUTTER: process
        variable seed1:        positive := 7;
        variable seed2:        positive := 1;  
        variable rand:         real;
        variable dice:         integer;
    begin
        data_out_stop <= '0';
        wait until rising_edge(output_clk);
        if g_OUTPUT_STUTTER then
            uniform(seed1, seed2, rand);
            dice := integer(FLOOR(rand*6.0));
            for i in 0 to dice-1 loop
                data_out_stop <= '0';
                wait until rising_edge(output_clk);
            end loop;
            uniform(seed1, seed2, rand);
            dice := integer(FLOOR(rand*2.0));
            for i in 0 to dice-1 loop
                data_out_stop <= '1';
                wait until rising_edge(output_clk);
            end loop;
        end if;
    end process;

    GEN_CHECK_OUT_DATA: for out_port in 0 to pc_CTC_OUTPUT_NUMBER-1 generate
    begin
        P_CHECK_OUTPUT_DATA: process
            variable st         : integer;
            variable timestamp  : integer;
            variable pc         : integer;
            variable t          : string(1 to 255);
            variable coarse_delay : integer;
            variable coarse_addr  : integer;
            variable factor       : integer := 2;   
            variable hpol_ps      : integer;        
            variable vpol_ps      : integer;        
            variable delta_hpol   : integer;        
            variable delta_vpol   : integer;        
            variable delta_delta  : integer;
            variable product_64   : signed(63 downto 0);
            variable product_16   : signed(15 downto 0);
            variable S            : integer;
            variable S_start      : integer;
                    
        begin
            
            out_finished(out_port) <= '0';
            
            wait until rising_edge(output_clk);
            wait until rising_edge(output_clk);
            wait until rising_edge(output_clk);
            wait until rising_edge(output_clk);

            S_start    := (g_FIRST_PACKET_OFFSET + g_SKIP_START_BLOCKS) *  g_INPUT_BLOCK_SIZE;

            for iteration in 0 to g_ITERATIONS-1 loop 
                for coarse in 0 to g_COARSE_CHANNELS-1 loop
                    for station_group in 0 to c_STATION_GROUP_COUNT-1 loop
                        st           := station_group*c_STATION_GROUP_SIZE + (out_port);
                        coarse_addr  := coarse*c_STATION_COUNT + st;
                        coarse_delay := (coarse_addr+1)*factor;
                        for ts in 0-(g_COARSE_DELAY_OFFSET+g_OUTPUT_PRELOAD)*g_OUTPUT_BLOCK_SIZE+coarse_delay to (g_OUTPUT_TIME_COUNT-g_COARSE_DELAY_OFFSET)*g_OUTPUT_BLOCK_SIZE+coarse_delay-1 loop
                            timestamp := g_FIRST_PACKET_OFFSET*g_INPUT_BLOCK_SIZE + iteration*g_OUTPUT_TIME_COUNT*g_OUTPUT_BLOCK_SIZE + ts + g_SKIP_START_BLOCKS*g_INPUT_BLOCK_SIZE + (g_OUTPUT_PRELOAD+g_COARSE_DELAY_OFFSET)*g_OUTPUT_BLOCK_SIZE;
                            pc        := timestamp / g_INPUT_BLOCK_SIZE - g_FIRST_PACKET_OFFSET;
                            t:=fixed_string("   --   ts:" & integer'image(ts) & ", station:" & integer'image(st) & ", coarse:" & integer'image(coarse), 255);
                            while data_out_vld/='1' loop
                                wait until rising_edge(output_clk);
                            end loop;
                            
                            --first timestamp in frame
                            if ts=0-(g_COARSE_DELAY_OFFSET+g_OUTPUT_PRELOAD)*g_OUTPUT_BLOCK_SIZE+coarse_delay then
                                assert start_of_frame='1' report "Start of Frame missing!" severity FAILURE;
                                check_equal(unsigned(header_out(out_port).timestamp),       to_unsigned(timestamp, 32),    "OUT[" & integer'image(out_port) & "] HEADER TS "&t);
                                check_equal(unsigned(header_out(out_port).coarse_delay),    to_unsigned(coarse_delay, 12), "OUT[" & integer'image(out_port) & "] HEADER COARSE DELAY "&t);
                                check_equal(unsigned(header_out(out_port).virtual_channel), to_unsigned(coarse, 9),        "OUT[" & integer'image(out_port) & "] HEADER VIRTUAl CHANNEL "&t);
                                check_equal(unsigned(header_out(out_port).station_id),      to_unsigned(st, 9),            "OUT[" & integer'image(out_port) & "] HEADER STATION "&t);                                
                            else
                                assert start_of_frame='0' report "Start of Frame where it does not belong!" severity FAILURE;
                            end if; 
                            
                            S           := timestamp;
                            delta_hpol  := 17;
                            delta_vpol  := 23;
                            delta_delta := -((coarse_addr mod 15)*2**10);
                            product_64  := to_signed(delta_delta * ((S-S_start)/64), 64);
                            product_16  := product_64(30 downto 15);  
                            hpol_ps     := delta_hpol + to_integer(product_16);
                            vpol_ps     := delta_vpol + to_integer(product_16);                                                        
                            if header_out_vld='1' then
                                check_equal(unsigned(header_out(out_port).hpol_phase_shift), unsigned(std_logic_vector(to_signed(hpol_ps, 16))),       "OUT[" & integer'image(out_port) & "] HEADER HPOL "&t);
                                check_equal(unsigned(header_out(out_port).vpol_phase_shift), unsigned(std_logic_vector(to_signed(vpol_ps, 16))),       "OUT[" & integer'image(out_port) & "] HEADER VPOL "&t);
                            end if;
                            
                            if packet_vld(out_port)='1' then
                                assert missing(pc, coarse, st)=false report "OUT: Missing packet seen as valid." severity FAILURE;
                                check_equal(unsigned(data_out(out_port).meta(0).in_port), 0,                                  "OUT[" & integer'image(out_port) & "] hpol in_port"&t);
                                check_equal(unsigned(data_out(out_port).meta(0).coarse),  to_unsigned(coarse, 9),             "OUT[" & integer'image(out_port) & "] hpol coarse"&t);
                                check_equal(unsigned(data_out(out_port).meta(0).station), to_unsigned(st, 9),                 "OUT[" & integer'image(out_port) & "] hpol station"&t);
                                check_equal(unsigned(data_out(out_port).meta(0).pol),     to_unsigned(0, 1),                  "OUT[" & integer'image(out_port) & "] hpol pol"&t);
                                check_equal(unsigned(data_out(out_port).meta(0).ts),      to_unsigned(timestamp, 32),         "OUT[" & integer'image(out_port) & "] hpol ts"&t);
                                check_equal(unsigned(data_out(out_port).data.hpol.im),to_unsigned(st  + (timestamp/8)*16, 8), "OUT[" & integer'image(out_port) & "] hpol im"&t);
                                check_equal(unsigned(data_out(out_port).data.hpol.re),    to_unsigned(0 + coarse*16,    8),   "OUT[" & integer'image(out_port) & "] hpol re"&t);
                                check_equal(unsigned(data_out(out_port).meta(1).in_port), 0,                                  "OUT[" & integer'image(out_port) & "] vpol in_port"&t);
                                check_equal(unsigned(data_out(out_port).meta(1).coarse),  to_unsigned(coarse, 9),             "OUT[" & integer'image(out_port) & "] vpol coarse"&t);
                                check_equal(unsigned(data_out(out_port).meta(1).station), to_unsigned(st, 9),                 "OUT[" & integer'image(out_port) & "] vpol station"&t);
                                check_equal(unsigned(data_out(out_port).meta(1).pol),     to_unsigned(1, 1),                  "OUT[" & integer'image(out_port) & "] vpol pol"&t);
                                check_equal(unsigned(data_out(out_port).meta(1).ts),      to_unsigned(timestamp, 32),         "OUT[" & integer'image(out_port) & "] vpol ts"&t);
                                check_equal(unsigned(data_out(out_port).data.vpol.im),to_unsigned(st  + (timestamp/8)*16, 8), "OUT[" & integer'image(out_port) & "] vpol im"&t);
                                check_equal(unsigned(data_out(out_port).data.vpol.re),    to_unsigned(1 + coarse*16,    8),   "OUT[" & integer'image(out_port) & "] vpol re"&t);
                            else
                                assert g_ALLOW_MORE_MISSING or missing(pc, coarse, st)=true report "OUT: Valid packet seen as missing." severity FAILURE;
                                check_equal(unsigned(data_out(out_port).data.hpol.im),      X"80", "OUT[" & integer'image(out_port) & "] hpol invalid im:");
                                check_equal(unsigned(data_out(out_port).data.hpol.re),      X"80", "OUT[" & integer'image(out_port) & "] hpol invalid re:");
                                check_equal(unsigned(data_out(out_port).data.vpol.im),      X"80", "OUT[" & integer'image(out_port) & "] vpol invalid im:");
                                check_equal(unsigned(data_out(out_port).data.vpol.re),      X"80", "OUT[" & integer'image(out_port) & "] vpol invalid re:");
                            end if;    
                            wait until rising_edge(output_clk);
                        end loop;
                    end loop;                                    
                end loop;
                factor  := 3;
                S_start := 16#817# * g_INPUT_BLOCK_SIZE; 
            end loop;            

            out_finished(out_port) <= '1';
            
            echoln;
            echoln("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
            echoln("!                                !");
            echoln("!  ALL OUTPUT[" & integer'image(out_port) & "] DATA RECEIVED   !");
            echoln("!                                !");
            echoln("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
            echoln;
            
            wait;
                    
        end process; 
    end generate;
    
    
    ---------------------------------------------------------------------------------------------------
    -- End of Simulation
    ---------------------------------------------------------------------------------------------------
    P_DETECT_SIM_END: process
    begin
        
        wait until out_finished=(out_finished'range=>'1');
        
        wait for 50 us;
        
        echoln;
        echoln("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        echoln("!                             !");
        echoln("!     SIMULATION FINISHED     !");
        echoln("!                             !");
        echoln("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        echoln;
        
        stop(2); --end simulation

    end process;
        
end sim;
