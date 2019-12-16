---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Coarse (CTC)
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert_abel@gmx.net)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- The basic structure of the Coarse Corner Turner is as follows:
-- 
-- => INPUT_BUFFER => HBM_BUFFER => OUTPUT_BUFFER =>
--
-- The HBM_BUFFER realises the corner turn. 
-- The input buffer implements a helper FIFO that allows for longer bursts on the HBM.
-- The output buffer sorts the data it into the required output ports. 
--
-- INPUT DATA [x3]:
-- for coarse_group = 1:3:384/8-1 and station 1:2  (order between coarse_group and station is basically random)
--    for coarse = 1:8
--        for time = 1:2:2048
--            [[ts0, pol0], [ts0, pol1], [ts1, pol0], [ts1, pol1]] (this is one port of 3, 64bit per port)
--
--
-- OUTPUT DATA:
-- for coarse = 1:3:384
--    for station_group = 1:3
--        for time = 1:(204+11)x4096
--        if station_group == 1: [station0, pol0], [station0, pol1], [station1, pol0], [station1, pol1] (this is all 4 ports, 16 bit per port) 
--        if station_group == 2: [station2, pol0], [station2, pol1], [station3, pol0], [station3, pol1]
--        if station_group == 3: [station4, pol0], [station4, pol1], [station5, pol0], [station5, pol1]
-- 
---------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.ctc_pkg.all;

Library xpm;
use xpm.vcomponents.all;

Library axi4_lib;
USE axi4_lib.axi4_lite_pkg.ALL;
use axi4_lib.axi4_full_pkg.all;

entity ctc is
    Generic(
        g_USE_DATA_IN_STOP    : boolean;    --PISA: FALSE -use the stop signal on the ingress?
        g_FPGA_COUNT          : integer;    --PISA: 3     -how many FPGAs are used?
        g_INPUT_STOP_WORDS : integer := 10; --PISA: -     -ignore if g_USE_DATA_IN_STOP is FALSE  -- how many cycles does it take from o_data_in_stop='1' to input data being halted?
        g_USE_HBM             : boolean;    --            -TRUE: use Xilinx' HBM model, FALSE: use HBM emulator (simpler, faster, no SystemVerilog needed)
        g_HBM_EMU_STUTTER     : boolean;    --            -if HBM emulator used: set w_ready and wa_ready to '0' in a pseudo random pattern    
        g_HBM_BURST_LEN       : integer;    --PISA: 16    -length of HBM burst 
        g_COARSE_CHANNELS     : integer;    --PISA: 128   -how many different CCs are there?
        g_INPUT_BLOCK_SIZE    : integer;    --PISA: 2048  -how many time stamps are in one CC? (unit: 32 bit (dual pol)) 
        g_OUTPUT_BLOCK_SIZE   : integer;    --PISA: 4096  -how many time stamps are in one output block? (unit: 32 bit (dual pol))
        g_OUTPUT_TIME_COUNT   : integer;    --PISA: 204   -how many output blocks come consecutively?
        g_STATION_GROUP_SIZE  : integer;    --PISA: 2     -how many stations are in one station_group (on the output side)                
        g_OUTPUT_PRELOAD      : integer;    --PISA: 11    -how many output blocks do we need to preload to initialise the filter banks?
        -- g_AUX_WIDTH = 2*g_OUTPUT_TIME_COUNT - (pc_CTC_MAX_STATIONS*g_COARSE_CHANNELS)/2   (if this is negative, change the values above!)
        g_AUX_WIDTH           : integer;    --PISA: 24    -unit: INPUT_TIME_COUNT - how many packet counts wide are the AUX buffers?
        g_WIDTH_PADDING       : integer;    --PISA: 26    -unit: INPUT_TIME_COUNT - how wide is the padding around the MAIN buffer?
        g_MAXIMUM_DRIFT       : integer;    --PISA: 20    -unit: INPUT_TIME_COUNT - how far does the CTC allow stations to be late before cutting them off?
        g_COARSE_DELAY_OFFSET : integer;     --PISA: 2     -unit: INPUT_TIME_COUNT - how many input blocks too early do we start reading to allow for coarse delay?
        g_USE_DATA_IN_RECORD  : boolean := true -- only use for the stand alone ctc testbench.
    );
    Port ( 
        i_hbm_clk         : in  std_logic;  -- AXI clock: for ES and -1 devices: <=400MHz, for PS of -2 and higher: <=450MHz (HBM core and most of the CTC run in this clock domain)  
        i_mace_clk        : in  std_logic;  -- clock connected to MACE
        i_mace_clk_rst    : in  std_logic;  -- this is the only incoming reset - all other resets are created internally in the config module
        --MACE:
        i_saxi_mosi       : IN  t_axi4_lite_mosi; -- MACE IN
        o_saxi_miso       : OUT t_axi4_lite_miso; -- MACE OUT
        --wall time:
        i_input_clk_wall_time   : in t_wall_time; --wall time in input_clk domain           
        i_output_clk_wall_time  : in t_wall_time; --wall time in output_clk domain           
        --ingress (in input_clk):
        i_input_clk       : in std_logic;                                         -- clock domain for the ingress
        i_data_in_record  : in  t_ctc_input_data := (others => pc_CTC_DATA_ZERO); -- FOR SIMULATION ONLY (data + meta)
        i_data_in         : in  std_logic_vector(pc_CTC_INPUT_WIDTH-1 downto 0);  -- incoming data stream (header, data)
        i_data_in_vld     : in  std_logic;                                        -- is the current data cycle valid?
        i_data_in_sop     : in  std_logic;                                        -- first cycle of the header?
        o_data_in_stop    : out std_logic;                                        -- ignore if g_USE_DATA_IN_STOP is FALSE 
        --egress (in output_clk):
        i_output_clk      : in  std_logic;                                                 -- clock domain for the egress
        o_start_of_frame  : out std_logic;                                                 -- single cycle pulse: this cycle is the first of 204*4096
        o_header_out      : out t_ctc_output_header_a(pc_CTC_OUTPUT_NUMBER-1 downto 0);    -- meta data belonging to the data coming out
        o_header_out_vld  : out std_logic;                                                 -- new meta data (every output packet, aka 4096 cycles) 
        o_data_out        : out t_ctc_output_data_a(pc_CTC_OUTPUT_NUMBER-1 downto 0);      -- the actual output data
        o_data_out_vld    : out std_logic;                                                 -- is this cycle valid? if i_stop is not used, a 4096 packet is uninteruptedly valid
        o_packet_vld      : out std_logic_vector(pc_CTC_OUTPUT_NUMBER-1 downto 0);        -- is this 2048 cycle half of the packet valid or RFI? (RFI = missing input packet)         
        i_data_out_stop   : in  std_logic;                                                 -- set to '0' if not used
        --debug for TB (in hbm_clk) --FOR SIMULATION ONLY:
        o_debug_ibuf_out        : out t_ctc_hbm_data;
        o_debug_ibuf_out_vld    : out std_logic;
        o_debug_header_out      : out t_ctc_input_header;
        o_debug_header_out_vld  : out std_logic;
        o_debug_hbm_out         : out t_ctc_hbm_data;
        o_debug_hbm_out_vld     : out std_logic;
        o_debug_hbm_block_vld   : out std_logic;
        --HBM INTERFACE
        o_hbm_clk_rst : out std_logic;          -- reset going to the HBM core
        o_hbm_mosi    : out t_axi4_full_mosi;   -- data going to the HBM core
        i_hbm_miso    : in  t_axi4_full_miso;   -- data coming from the HBM core
        i_hbm_ready   : in  std_logic           -- HBM reset finished? (=apb_complete)
    );
end ctc;

architecture Behavioral of ctc is

    constant g_INPUT_TIME_COUNT : integer := g_OUTPUT_TIME_COUNT*(g_OUTPUT_BLOCK_SIZE/g_INPUT_BLOCK_SIZE);

    signal input_clk_rst   : std_logic;
    signal hbm_clk_rst     : std_logic;
    signal output_clk_rst  : std_logic;

    signal min_packet_seen       : std_logic;                      --the minimum packet has been seen
    signal max_packet_reached    : std_logic;                      --the maximum packet has been reached
    signal input_end_ts          : std_logic_vector(31 downto 0);  --maximum packet count - filter packets higher than this            


    signal hbm_ready       : std_logic;
    
    signal hbm_data_in       : t_ctc_hbm_data;
    signal hbm_data_in_vld   : std_logic;
    signal hbm_in_rdy        : std_logic := '1';

    signal hbm_dummy_header  : std_logic;
    signal hbm_header_in     : t_ctc_input_header;
    signal hbm_header_in_vld : std_logic;
    signal hbm_header_in_rdy : std_logic := '1';

    signal hbm_data_out      : t_ctc_hbm_data;
    signal hbm_data_out_vld  : std_logic;
    signal hbm_data_out_stop : std_logic := '0';
    signal hbm_block_vld     : std_logic := '0';
    
    signal coarse_delay_addr         : std_logic_vector(31 downto 0);
    signal coarse_delay_addr_vld     : std_logic;
    signal coarse_delay_packet_count : std_logic_vector(31 downto 0);
    signal coarse_delay_value        : std_logic_vector(15 downto 0);
    signal coarse_delay_delta_hpol   : std_logic_vector(15 downto 0);
    signal coarse_delay_delta_vpol   : std_logic_vector(15 downto 0);
    signal coarse_delay_delta_delta  : std_logic_vector(15 downto 0);
   
    signal input_config_update  : std_logic;
    signal hbm_config_update    : std_logic;
    signal output_config_update : std_logic;
    
    signal  input_config_start_ts : std_logic_vector(31 downto 0);
    signal    hbm_config_start_ts : std_logic_vector(31 downto 0);
    signal output_config_start_ts : std_logic_vector(31 downto 0);
    
    signal output_config_start_wt     : t_wall_time;
    signal input_config_prime_wt      : t_wall_time;
       
    signal output_config_output_cycles : std_logic_vector(31 downto 0);
    signal input_config_input_cycles   : std_logic_vector(31 downto 0);
   
    signal end_of_integration_period : std_logic;                    
    signal current_packet_count      : std_logic_vector(31 downto 0);
    
    signal enable_timed_input        : std_logic;                    
    signal enable_timed_output       : std_logic;                    
    
    --error (in input_clk)
    signal error_input_buffer_overflow      : std_logic;  --INPUT_FIFO overflows because data has not been read out fast enough and we cannot send in more dummy headers to keep the CTC going    
    --error (in hbm clk):
    signal error_input_buffer_full          : std_logic;  --the INPUT buffer is going into full state (if everything runs smoothly this should not happen) -- this causes packet loss
    signal error_ctc_full                   : std_logic;  --the HBM buffer is going into full state (if everything runs smoothly this should not happen)
    signal error_overwrite                  : std_logic;  --blocks have not been read and are overwritten (HBM read is too slow)
    signal error_too_late                   : std_logic;  --blocks did get actively dropped due to being too late
    signal error_wa_fifo_full               : std_logic;  --the wa_fifo in the block_tracker overflows: FAILURE! -- this should NEVER happen
    signal error_ra_fifo_full               : std_logic;  --the ra_fifo in the block_tracker overflows: FAILURE! -- this should NEVER happen
    signal error_bv_fifo_full               : std_logic;  --the fv_fifo in the block_tracker overflows: FAILURE! -- this should NEVER happen
    signal error_bv_fifo_underflow          : std_logic;  --the fv_fifo in the block_tracker underflows: FAILURE! -- HBM ra_ack comes too fast
    signal error_coarse_delay_fifo_overflow : std_logic;  --the coarse_delay fifo in the output_buffer overflows: FAILURE! -- this should NEVER happen
    signal error_dsp_overflow               : std_logic_vector(3 downto 0); --the delta_P_coarse_out calculations had to cut used bits
    --error (in output_clk)
    signal error_ctc_underflow              : std_logic;  --readout was triggered, but the data FIFO does not contain enough data to start output
    signal error_output_aligment_loss       : std_logic;  --underflow is so massive, that we miss a whole out packet
    
    signal debug_station_channel     : std_logic_vector(9 downto 0);
    signal debug_station_channel_inc : std_logic;
    signal debug_ctc_ra_cursor       : std_logic_vector(15 downto 0);
    signal debug_ctc_ra_phase        : std_logic_vector(1 downto 0);
    signal debug_ctc_empty           : std_logic;
   
begin
    
    o_hbm_clk_rst <= hbm_clk_rst;
    
    assert g_OUTPUT_BLOCK_SIZE rem g_INPUT_BLOCK_SIZE = 0 report "g_OUTPUT_BLOCK_SIZE has to be a multiple of g_INPUT_BLOCK_SIZE" severity FAILURE;

    ------------------------------------------------------------------------------------
    -- CONFIG (TO/FROM MACE)
    ------------------------------------------------------------------------------------
    -- + create internal resets
    -- + connect config & error signals to MACE 
    ------------------------------------------------------------------------------------
    E_CTC_CONFIG: entity work.ctc_config
    Port Map( 
        i_mace_clk                  => i_mace_clk,
        i_mace_clk_rst              => i_mace_clk_rst,
        i_input_clk                 => i_input_clk,          
        o_input_clk_rst             => input_clk_rst,           
        i_hbm_clk                   => i_hbm_clk,
        o_hbm_clk_rst               => hbm_clk_rst, 
        i_output_clk                => i_output_clk,            
        o_output_clk_rst            => output_clk_rst,
        
        --MACE:
        i_saxi_mosi                 => i_saxi_mosi,
        o_saxi_miso                 => o_saxi_miso,
        
        -- coarse delay (hbm_clk):
        i_coarse_delay_addr         => coarse_delay_addr,         -- coarse*STATIONS + station
        i_coarse_delay_addr_vld     => coarse_delay_addr_vld,
        o_coarse_delay_packet_count => coarse_delay_packet_count, 
        o_coarse_delay_value        => coarse_delay_value,        -- valid data cycles
        o_coarse_delay_delta_hpol   => coarse_delay_delta_hpol,  
        o_coarse_delay_delta_vpol   => coarse_delay_delta_vpol,   
        o_coarse_delay_delta_delta  => coarse_delay_delta_delta,  
        i_end_of_integration_period => end_of_integration_period, --pulse
        i_curent_packet_count       => current_packet_count,      -- packet count

        
        -- input buffer config (input_clk):
        o_input_update              => input_config_update,
        o_input_start_ts            => input_config_start_ts,     -- packet count
        o_input_prime_wt            => input_config_prime_wt,     -- wall time
        o_input_cycles_per_packet   => input_config_input_cycles, -- clock cycles
        o_enable_timed_input        => enable_timed_input,        -- boolean
        i_min_packet_seen           => min_packet_seen,           -- boolean
        i_max_packet_reached        => max_packet_reached,        -- boolean       
        o_input_end_ts              => input_end_ts,              -- packet_count            
        
        -- hbm config (hbm_clk):
        o_hbm_update                => hbm_config_update,
        i_hbm_ready                 => hbm_ready,
        o_hbm_start_ts              => hbm_config_start_ts,       -- packet count - only change in rst
        
        -- output buffer config (output_clk):
        o_output_update             => output_config_update,
        o_output_start_ts           => output_config_start_ts,      -- packet count
        o_output_start_wt           => output_config_start_wt,      -- wall time
        o_output_cycles_per_packet  => output_config_output_cycles, -- clock cycles        
        o_enable_timed_output       => enable_timed_output,         -- boolean
                        
        -- error (in input clk):
        i_error_input_buffer_full          => error_input_buffer_full,
        i_error_input_buffer_overflow      => error_input_buffer_overflow,
        -- error/debug (in hbm clk):
        i_debug_station_channel            => debug_station_channel,
        i_debug_station_channel_inc        => debug_station_channel_inc,
        i_debug_ctc_ra_cursor                  => debug_ctc_ra_cursor,
        i_debug_ctc_ra_phase               => debug_ctc_ra_phase,
        i_debug_ctc_empty                  => debug_ctc_empty,
        i_error_ctc_full                   => error_ctc_full,
        i_error_overwrite                  => error_overwrite,
        i_error_too_late                   => error_too_late,                  
        i_error_wa_fifo_full               => error_wa_fifo_full,              
        i_error_ra_fifo_full               => error_ra_fifo_full,              
        i_error_bv_fifo_full               => error_bv_fifo_full,              
        i_error_bv_fifo_underflow          => error_bv_fifo_underflow,         
        i_error_coarse_delay_fifo_overflow => error_coarse_delay_fifo_overflow,
        i_error_dsp_overflow               => error_dsp_overflow,
        -- error (in output_clk):         
        i_error_ctc_underflow              => error_ctc_underflow,             
        i_error_output_aligment_loss       => error_output_aligment_loss      
    );        



    
    ------------------------------------------------------------------------------------
    -- INPUT BUFFER
    ------------------------------------------------------------------------------------
    -- + extract header from payload
    -- + CDC to hbm_clk
    ------------------------------------------------------------------------------------
    E_INPUT_BUFFER: entity work.ctc_input_buffer
    generic map(
        g_USE_DATA_IN_STOP  => g_USE_DATA_IN_STOP,
        g_FPGA_COUNT        => g_FPGA_COUNT,
        g_HBM_BURST_LEN     => g_HBM_BURST_LEN,
        g_INPUT_BLOCK_SIZE  => g_INPUT_BLOCK_SIZE,
        g_INPUT_STOP_WORDS  => g_INPUT_STOP_WORDS,
        g_USE_DATA_IN_RECORD => g_USE_DATA_IN_RECORD
    ) port map (
        i_hbm_clk         => i_hbm_clk,
        i_hbm_clk_rst     => hbm_clk_rst,
        i_input_clk       => i_input_clk,
        i_input_clk_rst   => input_clk_rst,
        
        i_config_update       => input_config_update,
        i_enable_timed_input  => enable_timed_input,
        i_input_clk_wall_time => i_input_clk_wall_time,
        i_config_prime_wt     => input_config_prime_wt,
        i_config_start_ts     => input_config_start_ts,
        i_config_input_cycles => input_config_input_cycles,
        o_min_packet_seen     => min_packet_seen,           -- boolean
        o_max_packet_reached  => max_packet_reached,        -- boolean       
        i_input_end_ts        => input_end_ts,              -- packet_count            
        
        i_data_in         => i_data_in,
        i_data_in_record  => i_data_in_record,
        i_data_in_vld     => i_data_in_vld,
        i_data_in_sop     => i_data_in_sop,
        o_data_in_stop    => o_data_in_stop,

        o_data_out        => hbm_data_in,
        o_data_out_vld    => hbm_data_in_vld,
        i_data_out_rdy    => hbm_in_rdy,  

        o_header_out      => hbm_header_in,
        o_header_out_vld  => hbm_header_in_vld,
        o_dummy_header    => hbm_dummy_header,
        i_header_out_rdy  => hbm_header_in_rdy,
        
        o_error_input_buffer_full     => error_input_buffer_full,
        o_error_input_buffer_overflow => error_input_buffer_overflow
    );
    
    o_debug_ibuf_out       <= hbm_data_in;
    o_debug_ibuf_out_vld   <= hbm_data_in_vld and hbm_in_rdy;
    o_debug_header_out     <= hbm_header_in;
    o_debug_header_out_vld <= hbm_header_in_vld and hbm_header_in_rdy;
    
    
    
    ------------------------------------------------------------------------------------
    -- HBM BUFFER
    ------------------------------------------------------------------------------------
    -- + sort incoming data into correct slot based on header data
    -- + perform corner turn
    ------------------------------------------------------------------------------------
    E_HBM_BUFFER: entity work.ctc_hbm_buffer
    generic map (
        g_USE_HBM             => g_USE_HBM,
        g_HBM_EMU_STUTTER     => g_HBM_EMU_STUTTER,
        g_ATOM_SIZE           => g_HBM_BURST_LEN,
        --
        g_INPUT_TIME_COUNT    => g_INPUT_TIME_COUNT,
        g_INPUT_BLOCK_SIZE    => g_INPUT_BLOCK_SIZE/8,  --256bit units
        g_OUTPUT_BLOCK_SIZE   => g_OUTPUT_BLOCK_SIZE/8, --256bit units             
        g_STATION_GROUP_SIZE  => g_STATION_GROUP_SIZE,                    
        g_COARSE_CHANNELS     => g_COARSE_CHANNELS,
        g_AUX_WIDTH           => g_AUX_WIDTH,
        g_WIDTH_PADDING       => g_WIDTH_PADDING,
        g_OUTPUT_PRELOAD      => g_OUTPUT_PRELOAD,
        g_COARSE_DELAY_OFFSET => g_COARSE_DELAY_OFFSET,
        g_MAXIMUM_DRIFT       => g_MAXIMUM_DRIFT    
        
    ) port map (
       i_hbm_clk       => i_hbm_clk,
       i_hbm_rst       => hbm_clk_rst,

       o_hbm_ready       => hbm_ready,
       i_config_start_ts => hbm_config_start_ts,

       i_data_in       => hbm_data_in,
       i_data_in_vld   => hbm_data_in_vld,
       o_data_in_rdy   => hbm_in_rdy,
       
       i_dummy_header  => hbm_dummy_header,
       i_header_in     => hbm_header_in,
       i_header_in_vld => hbm_header_in_vld,
       o_header_in_rdy => hbm_header_in_rdy,

       o_data_out      => hbm_data_out,
       o_data_out_vld  => hbm_data_out_vld,
       o_block_vld     => hbm_block_vld,
       i_data_out_stop => hbm_data_out_stop,
       
       o_debug_station_channel     => debug_station_channel,
       o_debug_station_channel_inc => debug_station_channel_inc,
       o_debug_ctc_ra_cursor       => debug_ctc_ra_cursor,
       o_debug_ctc_ra_phase        => debug_ctc_ra_phase,
       o_debug_ctc_empty           => debug_ctc_empty,
       
       o_error_ctc_full          => error_ctc_full,
       o_error_overwrite         => error_overwrite,
       o_error_wa_fifo_full      => error_wa_fifo_full, 
       o_error_ra_fifo_full      => error_ra_fifo_full, 
       o_error_bv_fifo_full      => error_bv_fifo_full, 
       o_error_bv_fifo_underflow => error_bv_fifo_underflow,
       o_error_too_late          => error_too_late,

       o_hbm_mosi  => o_hbm_mosi, 
       i_hbm_miso  => i_hbm_miso, 
       i_hbm_ready => i_hbm_ready       
    );  

    o_debug_hbm_out       <= hbm_data_out;
    o_debug_hbm_out_vld   <= hbm_data_out_vld;
    o_debug_hbm_block_vld <= hbm_block_vld;

    ------------------------------------------------------------------------------------
    -- OUTPUT BUFFER
    ------------------------------------------------------------------------------------
    -- + Timed Output
    -- + Coarse Delay
    -- + Synchronous output of whole uninterrupted packets
    ------------------------------------------------------------------------------------
    E_OUTPUT_BUFFER: entity work.ctc_output_buffer
    generic map (
        g_FIFO1_DEPTH         => g_INPUT_BLOCK_SIZE/8,     --256bit units
        g_INPUT_PACKET_LEN    => g_INPUT_BLOCK_SIZE/8,     --256bit units
        g_INPUT_PACKET_COUNT  => g_INPUT_TIME_COUNT+2*g_OUTPUT_PRELOAD+g_COARSE_DELAY_OFFSET,
        g_FIFO2_DEPTH         => 2*g_OUTPUT_BLOCK_SIZE,    --64bit  units
        g_OUTPUT_PACKET_LEN   => g_OUTPUT_BLOCK_SIZE,      --64bit units
        g_COARSE_DELAY_OFFSET => g_COARSE_DELAY_OFFSET,
        g_STATION_GROUP_SIZE  => g_STATION_GROUP_SIZE,
        g_COARSE_CHANNELS     => g_COARSE_CHANNELS,
        g_OUTPUT_TIME_COUNT   => g_OUTPUT_TIME_COUNT,
        g_OUTPUT_PRELOAD      => g_OUTPUT_PRELOAD,
        g_INPUT_TIME_COUNT    => g_INPUT_TIME_COUNT,       --64bit units
        g_INPUT_BLOCK_SIZE    => g_INPUT_BLOCK_SIZE,       --64bit units
        g_INPUT_STOP_WORDS    => 8                   
    ) port map(
        i_hbm_clk        => i_hbm_clk,
        i_hbm_clk_rst    => hbm_clk_rst,
        i_output_clk     => i_output_clk,
        i_output_clk_rst => output_clk_rst,
        --config:
        i_hbm_config_start_ts       => hbm_config_start_ts,
        i_out_config_start_ts       => output_config_start_ts,
        o_coarse_delay_addr         => coarse_delay_addr,
        o_coarse_delay_addr_vld     => coarse_delay_addr_vld,
        i_coarse_delay_packet_count => coarse_delay_packet_count,
        i_coarse_delay_value        => coarse_delay_value,
        i_coarse_delay_delta_hpol   => coarse_delay_delta_hpol,   
        i_coarse_delay_delta_vpol   => coarse_delay_delta_vpol,   
        i_coarse_delay_delta_delta  => coarse_delay_delta_delta,  
        o_end_of_integration_period => end_of_integration_period,
        o_current_packet_count      => current_packet_count,
        i_hbm_config_update         => hbm_config_update,
        i_out_config_update         => output_config_update,
        i_output_clk_wall_time      => i_output_clk_wall_time,
        i_config_start_wt           => output_config_start_wt,
        i_config_output_cycles      => output_config_output_cycles,
        i_enable_timed_output       => enable_timed_output, 
        --data in:
        i_data_in        => hbm_data_out,
        i_data_in_vld    => hbm_data_out_vld,
        i_block_vld      => hbm_block_vld,
        o_data_in_stop   => hbm_data_out_stop,
        --data out:
        o_start_of_frame  => o_start_of_frame,
        o_header_out      => o_header_out,
        o_header_out_vld  => o_header_out_vld,
        o_data_out        => o_data_out,
        o_data_out_vld    => o_data_out_vld,
        o_packet_vld      => o_packet_vld,
        i_data_out_stop   => i_data_out_stop,
        --error:
        o_error_dsp_overflow               => error_dsp_overflow, 
        o_error_ctc_underflow              => error_ctc_underflow,
        o_error_output_aligment_loss       => error_output_aligment_loss,
        o_error_coarse_delay_fifo_overflow => error_coarse_delay_fifo_overflow
    );

    
    
end Behavioral;
