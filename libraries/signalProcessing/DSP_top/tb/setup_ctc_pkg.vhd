--
-- AXI lite transactions to configure the coarse corner turn module
--
library IEEE, axi4_lib, ctc_lib, common_lib;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use axi4_lib.axi4_lite_pkg.all;
use ctc_lib.ctc_pkg.all;
use ctc_lib.ctc_config_reg_pkg.all;
use common_lib.common_pkg.ALL;

use IEEE.MATH_REAL.ALL;

package setup_ctc_pkg is 

    constant g_USE_DATA_IN_STOP     : boolean := TRUE;       --PISA: FALSE -- should normally be set to TRUE to allow more scrutiny in TB, if FALSE, set g_ALLOW_MORE_MISSING to TRUE 
    constant g_USE_HBM              : boolean := FALSE;      --TRUE: use Xilinx' HBM model, FALSE: use HBM emulator (simpler, faster, no SystemVerilog needed)
    constant g_HBM_EMU_STUTTER      : boolean := FALSE;      --if HBM emulator used: set w_ready and wa_ready to '0' in a pseudo random pattern    
    constant g_INPUT_STUTTER        : boolean := FALSE;      --TB: create random pattern of invalid input cycles  
    constant g_OUTPUT_STUTTER       : boolean := FALSE;      --TB: create random pattern of output stop cycles  
    constant g_SCRAMBLE_INPUT_DATA  : boolean := TRUE;       --PISA: TRUE  --random order of Coarse Channels, stations drift apart from another (turn off for easier debugging)
    constant g_MAXIMUM_SIM_DRIFT    : integer := 2;          --PISA: 20    --how far can stations drift away from each other in Stimuli?
    constant g_MAXIMUM_CTC_DRIFT    : integer := 2;          --PISA: 20    --how far does the CTC allow stations to be late before cutting them off?
    constant g_ALLOW_MORE_MISSING   : boolean := FALSE;      --TB: allow extra missing packets (due to packets being too late)       
    constant g_MISSING_PACKET_RATE  : integer := 0;          --TB: 0=none, 1=all, x=1/x packets missing
    constant g_AWOL                 : boolean := FALSE;      --TB: have a station go AWOL for a while
    constant g_AWOL_STATION         : integer := 2;          --TB: which station goes AWOL? 
    constant g_AWOL_START           : integer := 0;          --TB: when does the station go AWOL?
    constant g_AWOL_END             : integer := 40;         --TB: when does the station come back online?
    constant g_BLACKOUT             : boolean := FALSE;      --TB: have ALL stations go AWOL for a while
    constant g_BLACKOUT_START       : integer := 40;         --TB: when does the Blackout start?
    constant g_BLACKOUT_END         : integer := 80;         --TB: when does the Blackout end?
    constant g_HBM_BURST_LEN        : integer := 16;         --PISA: 16    --length of HBM burst 
    constant g_SKIP_START_BLOCKS    : integer := 7;          --            --configure the system to wait for outer time stamp >= g_SKIP_START_BLOCKS
    constant g_FIRST_PACKET_OFFSET  : integer := 2**11;      --TB          --at which time stamp do we start sending (and the skipping) 
    constant g_FLUSHOUT_END_BLOCKS  : integer := 0; --g_MAXIMUM_CTC_DRIFT+1;    --send final blocks to allow for last buffer to empty
    constant g_FPGA_COUNT           : integer := 3;          --PISA: 3     --how many FPGAs are used?
    constant g_FPGA_ID              : integer := 0;          --            --number of this FPGA
    constant g_ITERATIONS           : integer := 32;         --PISA: inf   --outer timestamp iterations
    constant g_COARSE_CHANNELS      : integer := 4;          --PISA: 128   --how many different CCs are there?
    constant g_CC_GROUP_SIZE        : integer := 2;          --PISA: 8     --how many coarse channels come in consecutively?
    constant g_INPUT_BLOCK_SIZE     : integer := 512; --256  --PISA: 2048  --how many time stamps are in one CC? (unit: 32 bit (dual pol)) 
    constant g_OUTPUT_BLOCK_SIZE    : integer := 1024;--512  --PISA: 4096  --how many time stamps are in one output block? (unit: 32 bit (dual pol))
    constant g_OUTPUT_TIME_COUNT    : integer := 8;   --204  --PISA: 204   --how many output blocks come consecutively?
    constant g_STATION_GROUP_SIZE   : integer := 2;          --PISA: 2     --how many stations are in one station_group (on the output side)                    
        --
        -- g_AUX_WIDTH = 2*g_OUTPUT_TIME_COUNT - (pc_CTC_MAX_STATIONS*g_COARSE_CHANNELS)/2   (if this is negative, change the values above!)
    constant g_AUX_WIDTH           : integer := 4; --24     --unit: input blocks   --PISA: 24
    constant g_WIDTH_PADDING       : integer := 7; --26     --unit: input blocks   --PISA: 26
    constant g_OUTPUT_PRELOAD      : integer := 1; --11     --unit: output blocks  --PISA: 11    --how many output blocks do we need to preload before the real data comes?
    constant g_COARSE_DELAY_OFFSET : integer := 1;          --unit: output blocks  --PISA: 1     --how many output blocks too early do we start reading to allow for coarse delay?
                             
    constant g_SAMPLE_RATE_IN_NS        : integer := 1080;  --PISA: 1080 ns                                     
    constant g_INTEGRATION_TIME_IN_PS   : real := real(g_SAMPLE_RATE_IN_NS * 1000 * g_OUTPUT_BLOCK_SIZE * g_OUTPUT_TIME_COUNT); --PISA: 0.9s
                                                                                                                                                                                                                  
    constant g_PS_PER_OUTPUT_BLOCK      : integer := integer(1000.0 * real(g_SAMPLE_RATE_IN_NS) * real(g_OUTPUT_BLOCK_SIZE) * (real(g_OUTPUT_TIME_COUNT) / real(g_OUTPUT_TIME_COUNT+g_OUTPUT_PRELOAD)) / real(128) / real(pc_STATIONS_PER_PORT) / 2.0 * 2.0 * 2.0);
    constant g_NS_PER_OUTPUT_BLOCK      : integer := g_PS_PER_OUTPUT_BLOCK / 1000;
    constant g_READOUT_START_TIME       : integer := 550000;      --unit: ns   
                                                                     
    constant g_PS_PER_INPUT_BLOCK       : integer := integer(1000.0 * real(g_SAMPLE_RATE_IN_NS) * real(g_INPUT_BLOCK_SIZE) *                           1.0                                             / real(128) / real(pc_STATIONS_PER_PORT) / 2.0 * 2.0 * 2.0 / 2.0);
    constant g_NS_PER_INPUT_BLOCK       : integer := g_PS_PER_INPUT_BLOCK / 1000;
     --                                                          IBUF+OBUF    FULL PHASE LENGTH    -- AUX PRELOAD BEFORE FIRST PHASE LENGTH --        CHANNELS * STATIONS / parallel stations     INPUT BLOCK LEN IN PS                               
    constant g_FRAME_TIME               : integer := 2*g_OUTPUT_TIME_COUNT * (g_COARSE_CHANNELS * pc_STATION_NUMBER / 2) * 2 * g_PS_PER_INPUT_BLOCK;
    constant g_FIRST_AUX_TIME           : integer :=(2*g_OUTPUT_PRELOAD + 2*g_COARSE_DELAY_OFFSET) * (g_COARSE_CHANNELS * pc_STATION_NUMBER / 2) * 2 * g_PS_PER_INPUT_BLOCK;
    constant g_IN_OUT_BUFFER_TIME       : integer := 2 * 4 * g_PS_PER_INPUT_BLOCK;
    constant g_DRIFT_TIME               : integer :=                     4 * (g_COARSE_CHANNELS * pc_STATION_NUMBER / 2) * 2 * g_PS_PER_INPUT_BLOCK;
    constant g_FIRST_FRAME_CTC_DELAY    : integer := g_FRAME_TIME + g_FIRST_AUX_TIME + g_IN_OUT_BUFFER_TIME + g_DRIFT_TIME;
    constant g_PRIME_TIME               : integer := g_READOUT_START_TIME - (g_FIRST_FRAME_CTC_DELAY / 1000); --unit: ns
    constant g_INPUT_BLOCK_TIME_OFFSET  : integer := 1000; --unit: ns 
    
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
        
    function addr(i: t_register_address) return integer;
    
    procedure setupCTC(signal mace_clk : in std_logic;
                       signal saxi_miso : in t_axi4_lite_miso;
                       signal saxi_mosi : out t_axi4_lite_mosi;
                       signal setup_done : out std_logic);

end setup_ctc_pkg;

package body setup_ctc_pkg is 

    function addr(i: t_register_address) return integer is
    begin
        return i.base_address + i.address;
    end function;

    procedure setupCTC(signal mace_clk : in std_logic;
                       signal saxi_miso : in t_axi4_lite_miso;
                       signal saxi_mosi : out t_axi4_lite_mosi;
                       signal setup_done : out std_logic) is
    begin 
        -- first transaction unreliable ??? do it twice ?
        setup_done <= '0';
        axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_setup_full_reset_address), true, x"00000001");
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
                                 std_logic_vector(TO_UNSIGNED(g_PRIME_TIME, 32)));                                                                      
            --set input_cycles:
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_timing_input_cycles_address), true, 
                                 std_logic_vector(TO_UNSIGNED((g_COARSE_CHANNELS * pc_STATION_NUMBER / 2) * 2 * g_PS_PER_INPUT_BLOCK / c_INPUT_CLK_PS_PER_CYCLE, 32)));
                                 
            --USE TIMING VALUES and turn input & output time control on:
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_timing_control_enable_timed_output_address), true,
                                 X"00000007");
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_timing_control_enable_timed_output_address), true,
                                 X"00000006");
            
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
            

        -- or should we wait until we turn mace reset off ?
        setup_done <= '1';
           
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
                                 X"00000007");
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_timing_control_enable_timed_output_address), true,
                                 X"00000006");
            
        wait for 300 us;
        wait until rising_edge(mace_clk);
        
        --READ COUNTER
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_valid_blocks_count_address), false, X"00000000");
       
        --wait; --for ever
        
    end procedure;
    
end setup_ctc_pkg;
