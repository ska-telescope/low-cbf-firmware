---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Fine (CTF) - Address manager
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert_abel@gmx.net)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- This helper unit implements the 4-phase rotation buffer.
-- The addressing scheme is described in detail in Confluence.
--
--
--
-- Throughput vs. Pipeline Steps:
--
-- The code is written in a way that there is always only one
-- valid data item in the entire "pipeline".
--
-- We write 16 addresses that each reflect 16 writes.
-- This will be slowed down by i_address_rdy coming from the HBM,
-- but we definitely have plenty of time until the next address is needed, since
-- data is still being written to the HBM when all addresses already have been written.
-- This gives us the time to do all the pipeline steps.
--
-- The code has been written in a way that decouples i_address_rdy from o_header_in_rdy,
-- to reduce fanout on i_address_rdy.
--
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.all;

use work.ctc_pkg.all;

entity ctc_address_manager is
    Generic (
        g_USE_CASE_IS_WRITE   : boolean := true;       -- is this module used to create write addresses or read addresses?
        g_START_PHASE         : integer range 0 to 3 := 0;
        g_ATOM_SIZE           : integer := 16;
        g_INPUT_BLOCK_SIZE    : integer := 2048/8;     --in 256 bit words              
        g_OUTPUT_BLOCK_SIZE   : integer := 4096/8;     --in 256 bit words              
        g_OUTPUT_TIME_COUNT   : integer := 204;
        g_STATION_GROUP_SIZE  : integer := 2;                    
        g_COARSE_CHANNELS     : integer := 128;
        g_AUX_WIDTH           : integer range 2 to integer'HIGH := 24; --unit: INPUT_TIME_COUNT
        g_WIDTH_PADDING       : integer range 2 to integer'HIGH := 26; --unit: INPUT_TIME_COUNT
        g_OUTPUT_PRELOAD      : integer range 1 to g_AUX_WIDTH/2 := 11; --how many output blocks do we need to preload before the real data comes?
        g_MAXIMUM_DRIFT       : integer := 0;                           --unit: INPUT_TIME_COUNT (Write Case only)    
        g_COARSE_DELAY_OFFSET : integer := 2                            --unit: INPUT_TIME_COUNT
    );
    Port (
        i_clk             : in  STD_LOGIC;
        i_rst             : in  STD_LOGIC;
        --header in (write use case):
        i_config_start_ts : in  std_logic_vector(31 downto 0) := (others => '0');
        i_header_in       : in  t_ctc_input_header := pc_CTC_INPUT_HEADER_ZERO;
        i_dummy_header    : in  std_logic    := '0';
        i_header_in_vld   : in  std_logic    := '0';
        o_header_in_rdy   : out std_logic;
        --block out:
        o_block_offset     : out std_logic_vector;
        o_block_offset_vld : out std_logic;
        o_block_clear      : out std_logic; 
        o_block_good       : out std_logic;
        o_error_too_late   : out std_logic;
        --address out:
        o_address         : out std_logic_vector;        --(256bit-word) address
        o_address_vld     : out std_logic;
        i_address_rdy     : in  std_logic;
        i_address_stop    : in  std_logic    := '0';
        --station/channel out:
        o_station_channel     : out std_logic_vector(9 downto 0);
        o_station_channel_vld : out std_logic;
        o_station_channel_aux : out std_logic;
        --indicator out:
        o_phase_low       : out std_logic_vector(1 downto 0);
        o_phase_high      : out std_logic_vector(1 downto 0);
        o_low_is_aux      : out std_logic;
        o_high_is_aux     : out std_logic;
        o_cursor          : out unsigned(log2_ceil(2*g_OUTPUT_TIME_COUNT+g_WIDTH_PADDING)-1 downto 0)
    );   
end ctc_address_manager;

architecture Behavioral of ctc_address_manager is

    --keep the tools from instantiating DSPs        
    attribute use_dsp48 : string;
    attribute use_dsp48 of Behavioral : architecture is "no";      
        
    --The names below are oriented on Phase 1
    
    constant g_OUTPUT_BLOCK_FACTOR : integer := g_OUTPUT_BLOCK_SIZE/g_INPUT_BLOCK_SIZE;                 --2
    constant g_INPUT_TIME_COUNT    : integer := g_OUTPUT_TIME_COUNT*g_OUTPUT_BLOCK_FACTOR;              --408
    
    constant g_MAIN_WIDTH          : integer := g_INPUT_TIME_COUNT-g_AUX_WIDTH;                         --384                                            
    constant g_MAIN_HEIGHT         : integer := g_COARSE_CHANNELS * pc_STATION_NUMBER;                  --768

    constant g_HEIGHT_FACTOR       : integer := g_MAIN_HEIGHT/g_MAIN_WIDTH;                             --2
    constant g_HEIGHT_PADDING      : integer := g_WIDTH_PADDING * g_HEIGHT_FACTOR;                      --52
                   
    constant g_BUFFER_WIDTH        : integer := g_MAIN_WIDTH + g_WIDTH_PADDING;                         --410
    constant g_BUFFER_HEIGHT       : integer := g_MAIN_HEIGHT + g_HEIGHT_PADDING;                       --820
    
    constant g_MAIN_BUFFER_SIZE    : integer := g_BUFFER_WIDTH * g_BUFFER_HEIGHT * g_INPUT_BLOCK_SIZE;  --86,067,200

    constant g_AUX_HEIGHT          : integer := g_MAIN_HEIGHT;                                          --768
    constant c_AUX_NUMBER          : integer := 3;                                                      --3
    constant g_AUX_BUFFER_SIZE     : integer := g_AUX_HEIGHT * g_AUX_WIDTH * g_INPUT_BLOCK_SIZE;        --4,718,592
    
    constant g_OVERALL_SIZE           : integer := g_MAIN_BUFFER_SIZE + c_AUX_NUMBER*g_AUX_BUFFER_SIZE + 1;    --100,222,976  ==(*256bit)==> 25,657,081,856 bit <=> 12 AXI interfaces (each 2Gib)
    constant g_OVERALL_SIZE_LOG2      : integer := log2_ceil(g_OVERALL_SIZE);                                  --27 bit (256bit-word)-addressing <=> 32 bit byte-addressing on HBM
    constant g_OVERALL_SIZE_IN_BLOCKS : integer := (g_BUFFER_WIDTH*g_BUFFER_HEIGHT) + (c_AUX_NUMBER*g_AUX_HEIGHT*g_AUX_WIDTH);
    
    constant g_DEV_NULL            : integer := g_MAIN_BUFFER_SIZE + c_AUX_NUMBER*g_AUX_BUFFER_SIZE;    --very last address, used to dump data that came in too late based on g_MAXIMUM_DRIFT
    
    constant g_PRELOAD_OFFSET      : integer := g_AUX_WIDTH - 2*g_OUTPUT_PRELOAD;

    constant g_2_POW_40            : unsigned(40 downto 0) := (40=>'1', others => '0');
    -- The following has been verified in Matlab for g_INPUT_TIME_COUNT values of 16 and 408:
    --                                                                                   --round up i.e. add 1, if g_TIME_WIDTH is not a power of 2:
    constant g_TIME_WIDTH_INV41    : unsigned(40 downto 0) := g_2_POW_40 / g_INPUT_TIME_COUNT + (2**log2_ceil(g_INPUT_TIME_COUNT) / (g_INPUT_TIME_COUNT+1));
    constant g_TIME_WIDTH_INV40    : unsigned(39 downto 0) := g_TIME_WIDTH_INV41(39 downto 0);

    signal header_in_rdy : std_logic := '0';

    --Buffer Types:
    constant c_MAIN   : std_logic_vector(1 downto 0) := B"00";
    constant c_AUX_S  : std_logic_vector(1 downto 0) := B"01"; --AUX before MAIN (read only)
    constant c_AUX_E  : std_logic_vector(1 downto 0) := B"10"; --AUX after MAIN
    constant c_INIT   : std_logic_vector(1 downto 0) := B"11";
    
    signal pa_packet_count  : unsigned(31 downto 0);
    signal pa_adjusted      : unsigned(31 downto 0);
    signal pa_min_adjusted  : unsigned(31 downto 0) := (others=>'0');
    signal pa_station       : integer range 0 to pc_CTC_MAX_STATIONS-1;
    signal pa_channel       : integer range 0 to g_COARSE_CHANNELS-1;
    signal pa_dummy_header  : std_logic;

    constant c_ZERO_10 : unsigned(09 downto 0) := (others => '0');
    constant c_ZERO_20 : unsigned(19 downto 0) := (others => '0');
    constant c_ZERO_30 : unsigned(29 downto 0) := (others => '0');

    signal pb_full_product_0     : unsigned(31+10 downto 0);
    signal pb_full_product_1     : unsigned(31+10 downto 0);
    signal pb_full_product_2     : unsigned(31+10 downto 0);
    signal pb_full_product_3     : unsigned(31+10 downto 0);
    signal pb_min_full_product_0 : unsigned(31+10 downto 0) := (others=>'0');
    signal pb_min_full_product_1 : unsigned(31+10 downto 0) := (others=>'0');
    signal pb_min_full_product_2 : unsigned(31+10 downto 0) := (others=>'0');
    signal pb_min_full_product_3 : unsigned(31+10 downto 0) := (others=>'0');
    signal pb_min_quotient       : unsigned(31 downto 0)    := (others=>'0');

    signal pc_iteration     : unsigned(31 downto 0);
    signal pc_min_iteration : unsigned(31 downto 0) := (others=>'0');

    signal pd_time_main     : unsigned(31 downto 0);
    signal pd_time_aux      : unsigned(31 downto 0);
    signal pd_min_time_main : unsigned(31 downto 0) := (others=>'0');
    signal pd_min_time_aux  : unsigned(31 downto 0) := (others=>'0');
        
    signal p1_post_reset    : std_logic;
    signal p1_packet_count  : unsigned(31 downto 0);
    signal p1_iteration     : unsigned(31 downto 0);
    signal p1_iteration_low : unsigned(31 downto 0);
    signal p1_phase         : unsigned(1 downto 0);
    signal p1_dummy_header  : std_logic;
    signal p1_buffer     : std_logic_vector(1 downto 0);
    signal p1_min_buffer : std_logic_vector(1 downto 0) := (others=>'0');
    signal p1_aux        : integer range 0 to c_AUX_NUMBER-1 := 0; 
    signal p1_time       : integer range g_MAIN_WIDTH-1 downto 0;
    signal p1_station    : integer range 0 to pc_CTC_MAX_STATIONS-1;
    signal p1_group      : integer range 0 to pc_CTC_MAX_STATIONS-1;
    signal p1_channel    : integer range 0 to g_COARSE_CHANNELS-1;
    signal p1_inner_time : integer range 0 to g_OUTPUT_BLOCK_FACTOR-1;
    signal p1_cursor     : unsigned(log2_ceil(2*g_OUTPUT_TIME_COUNT+g_WIDTH_PADDING)-1 downto 0);
    signal p1_address_in_packet : integer range 0 to g_INPUT_BLOCK_SIZE-1;
    signal p1_new_block  : std_logic;
    
    signal p2_new_block      : std_logic;
    signal p2_dummy_header   : std_logic := '0';
    signal p2_phase          : unsigned(1 downto 0);
    signal p2_iteration_high : unsigned(31 downto 0);
    signal p2_iteration_low  : unsigned(31 downto 0);
    signal p2_maximum_pc     : unsigned(31 downto 0);
    signal p2_minimum_pc     : unsigned(31 downto 0) := (others=>'0');

    signal p2_low_is_aux  : std_logic;        
    signal p2_high_is_aux : std_logic;        
    signal p2_buffer  : std_logic_vector(1 downto 0);
    signal p2_aux     : integer range 0 to c_AUX_NUMBER-1 := 0;
    signal p2_time    : integer range g_MAIN_WIDTH-1 downto 0;
    signal p2_sc      : integer range 0 to g_MAIN_HEIGHT-1;
    signal p2_station : integer range 0 to pc_CTC_MAX_STATIONS-1;
    signal p2_cursor  : unsigned(log2_ceil(2*g_OUTPUT_TIME_COUNT+g_WIDTH_PADDING)-1 downto 0);
    signal p2_address_in_packet : integer range 0 to g_INPUT_BLOCK_SIZE-1;
    
    signal p3_buffer  : std_logic_vector(1 downto 0);
    signal p3_x: integer range 0 to g_BUFFER_WIDTH-1;
    signal p3_y: integer range 0 to g_BUFFER_HEIGHT-1;
    signal p3_aux_buffer_offset :integer range 0 to g_OVERALL_SIZE-1;
    signal p3_aux_x : integer range 0 to g_OVERALL_SIZE-1;
    signal p3_aux_y : integer range 0 to g_OVERALL_SIZE-1;
    signal p3_address_in_packet : integer range 0 to g_INPUT_BLOCK_SIZE-1;

    signal p3_aux_block_buffer_offset :integer range 0 to g_OVERALL_SIZE_IN_BLOCKS-1;
    signal p3_aux_block_x : integer range 0 to g_OVERALL_SIZE_IN_BLOCKS-1;
    signal p3_aux_block_y : integer range 0 to g_OVERALL_SIZE_IN_BLOCKS-1;

    signal p4_offset        : integer range 0 to g_OVERALL_SIZE-1;
    signal p4_block_offset  : unsigned (log2_ceil(g_OVERALL_SIZE_IN_BLOCKS)-1 downto 0);
    signal p4_clear         : std_logic;
    signal p4_good          : std_logic;
    
    type t_packet_state is (s_IDLE, s_CALC, s_RUNNING, s_DONE);
    signal packet_state : t_packet_state;

    signal p4_address_in_packet : integer range 0 to g_INPUT_BLOCK_SIZE-1;

    signal address_we : std_logic;
    signal address    : unsigned(g_OVERALL_SIZE_LOG2-1 downto 0) := (others=>'0');
    
    signal pa_vld : std_logic;
    signal pb_vld : std_logic;
    signal pc_vld : std_logic;
    signal pd_vld : std_logic;
    signal p1_vld : std_logic;
    signal p2_vld : std_logic;
    signal p3_vld : std_logic;
    signal p4_vld : std_logic;

    signal p2_dev_null : std_logic := '0';
    signal p3_dev_null : std_logic := '0';

    signal my_config_start_ts : std_logic_vector(31 downto 0) := (others=>'0'); 

begin

    assert g_MAIN_HEIGHT = g_MAIN_WIDTH*2 report "g_MAIN_HEIGHT has to be MAIN_WIDTH times 2. Set g_AUX_WIDTH = 2*g_OUTPUT_TIME_COUNT - (pc_CTC_MAX_STATIONS*g_COARSE_CHANNELS)/2, which in this case would be " & integer'image(2*g_OUTPUT_TIME_COUNT-(pc_CTC_MAX_STATIONS*g_COARSE_CHANNELS)/2) & ". If that value is negative, you will have to change the other generics until it isn't anymore." severity FAILURE;
    assert g_INPUT_BLOCK_SIZE rem g_ATOM_SIZE = 0 report "g_INPUT_BLOCK_SIZE has to be a multiple of g_ATOM_SIZE" severity FAILURE;
    assert g_OUTPUT_BLOCK_SIZE = g_INPUT_BLOCK_SIZE*2 report "This design assumes that g_OUTPUT_BLOCK_SIZE is 2*g_INPUT_BLOCK_SIZE!" severity FAILURE;
    assert pc_STATION_NUMBER rem g_STATION_GROUP_SIZE = 0 report "g_STATION_NUMBER has to be a multiple of g_STATION_GROUP_SIZE" severity FAILURE;
    assert g_PRELOAD_OFFSET >= g_COARSE_DELAY_OFFSET report "g_PRELOAD_OFFSET has to be >= g_COARSE_DELAY_OFFSET!" severity FAILURE;  
    assert g_MAXIMUM_DRIFT<g_MAIN_WIDTH-1 and g_MAXIMUM_DRIFT<g_AUX_WIDTH-1 report "g_MAXIMUM_DRIFT has to be smaller than g_MAIN_WIDTH and g_AUX_WIDTH!" severity FAILURE;

    o_header_in_rdy <= header_in_rdy;

    GEN_READ_OR_WRITE: if g_USE_CASE_IS_WRITE generate

        -- ########################################################################
        -- ##########################  USE CASE = WRITE  ##########################
        -- ########################################################################

        o_phase_low   <= std_logic_vector(p2_iteration_low(1 downto 0));
        o_phase_high  <= std_logic_vector(p2_iteration_high(1 downto 0));
        o_cursor      <= p2_cursor;
        o_high_is_aux <= p2_high_is_aux;
        o_low_is_aux  <= p2_low_is_aux;
        
        -----------------------------------------------------------------------------------------
        -- PIPELINE STAGE A, B, C, 1: USE CASE = WRITE ADDRESS
        --
        -- Extract iteration, phase, aux_number, time, channel & station from header 
        -----------------------------------------------------------------------------------------
        PA_EXTRACT_DATA: process (i_clk)
        begin
            if rising_edge(i_clk) then
                if i_rst='1' then
                    pa_vld <= '0';
                    my_config_start_ts <= i_config_start_ts; 
                else
                    if packet_state=s_IDLE and i_header_in_vld='1' then
                        pa_vld <= '1';
                        pa_adjusted      <= unsigned(i_header_in.packet_count)-unsigned(my_config_start_ts)+g_MAIN_WIDTH+g_PRELOAD_OFFSET-g_COARSE_DELAY_OFFSET;
                        pa_dummy_header  <= i_dummy_header;
                        pa_channel       <= to_integer(unsigned(i_header_in.virtual_channel));
                        pa_station       <= to_integer(unsigned(i_header_in.station_id));
                        pa_packet_count  <= unsigned(i_header_in.packet_count);
                    else    
                        pa_vld <= '0';
                    end if;    
                    pa_min_adjusted  <= p2_minimum_pc - unsigned(my_config_start_ts)+g_MAIN_WIDTH+g_PRELOAD_OFFSET-g_COARSE_DELAY_OFFSET;
                end if;
    
            end if;
        end process;


        assert g_INPUT_TIME_COUNT=16 or g_INPUT_TIME_COUNT=24 or g_INPUT_TIME_COUNT=408 report "The given value of g_INPUT_TIME_COUNT has not been verified in Matlab to work for the multiplication replacement of the division for all possible input values." severity FAILURE;
        --MATLAB VERIFICATION:
        --408:     all(floor((1:2^32) * 2694881441  / 2^40) == floor((1:2^32)/408))
        -- 24:     all(floor((1:2^32) * 45812984491 / 2^40) == floor((1:2^32)/ 24))
        -- 16:     all(floor((1:2^32) * 68719476736 / 2^40) == floor((1:2^32)/ 16))

        PB_EXTRACT_DATA: process (i_clk)
        begin
            if rising_edge(i_clk) then
                if i_rst='1' then
                    pb_vld <= '0';
                else
                    pb_vld <= pa_vld;
                end if;
    
                --We calculate a division by multiplying with a 40bit value representing the 40bit inverse of the divisor.
                if pa_vld='1' then
                    pb_full_product_0     <= pa_adjusted * g_TIME_WIDTH_INV40(09 downto 00);
                    pb_full_product_1     <= pa_adjusted * g_TIME_WIDTH_INV40(19 downto 10);
                    pb_full_product_2     <= pa_adjusted * g_TIME_WIDTH_INV40(29 downto 20);
                    pb_full_product_3     <= pa_adjusted * g_TIME_WIDTH_INV40(39 downto 30);
                end if;     
                
                -- The minimum calculations (that determine when a packet is too old and thus discarded)
                -- are done here, because they are very similar to the calculations above
                -- and earliest required along with the calculations above.
                -- However, they do explicitly NOT depend on vld.
                -- If no data comes in, the minimum still has to be calculated.
                -- Otherwise we potentially get a lockup where empty and full are true at the same time.
                pb_min_full_product_0 <= pa_min_adjusted * g_TIME_WIDTH_INV40(09 downto 00);
                pb_min_full_product_1 <= pa_min_adjusted * g_TIME_WIDTH_INV40(19 downto 10);
                pb_min_full_product_2 <= pa_min_adjusted * g_TIME_WIDTH_INV40(29 downto 20);
                pb_min_full_product_3 <= pa_min_adjusted * g_TIME_WIDTH_INV40(39 downto 30);
                pb_min_quotient       <= pa_min_adjusted / (g_AUX_WIDTH+g_MAIN_WIDTH);
            end if;
        end process;
        
        PC_EXTRACT_DATA: process (i_clk)
            variable full_product      : unsigned(31+40 downto 0);
            variable cut_product       : unsigned(31 downto 0);
            variable quotient          : unsigned(31 downto 0);
            variable min_full_product  : unsigned(31+40 downto 0);
            variable min_cut_product   : unsigned(31 downto 0);
        begin
            if rising_edge(i_clk) then
                if i_rst='1' then
                    pc_vld <= '0';
                else
                    pc_vld <= pb_vld;
                end if;
    
                if pb_vld='1' then
                    full_product  := (pb_full_product_3(31+10 downto 0) & c_ZERO_30) + (pb_full_product_2(31+10 downto 0) & c_ZERO_20) + (pb_full_product_1(31+10 downto 0) & c_ZERO_10) + pb_full_product_0(31+10 downto 0);
                    cut_product  := full_product(31+40 downto 40);
                    quotient     := pa_adjusted / (g_AUX_WIDTH+g_MAIN_WIDTH);
                    assert cut_product=quotient report "Iteration: Miscalculation! Calc: " & integer'image(to_integer(cut_product)) & " Expected: " & integer'image(to_integer(quotient)) severity FAILURE; 
                    pc_iteration <= cut_product;
                end if;     

                min_full_product := (pb_min_full_product_3(31+10 downto 0) & c_ZERO_30) + (pb_min_full_product_2(31+10 downto 0) & c_ZERO_20) + (pb_min_full_product_1(31+10 downto 0) & c_ZERO_10) + pb_min_full_product_0(31+10 downto 0);
                min_cut_product  := min_full_product(31+40 downto 40);
                assert min_cut_product=pb_min_quotient report "Minimum Iteration: Miscalculation! Calc: " & integer'image(to_integer(min_cut_product)) & " Expected: " & integer'image(to_integer(pb_min_quotient)) severity FAILURE; 
                pc_min_iteration <= min_cut_product;

            end if;
        end process;


        PD_EXTRACT_DATA: process(i_clk)
            constant c_FACTOR_A       : unsigned(31 downto 0) := to_unsigned(g_INPUT_TIME_COUNT, 32);
            variable full_product     : unsigned(63 downto 0);
            variable cut_product      : unsigned(31 downto 0);
            variable min_full_product : unsigned(63 downto 0);
            variable min_cut_product  : unsigned(31 downto 0);
        begin
            
            if rising_edge(i_clk) then
                if i_rst='1' then
                    pd_vld <= '0';
                else
                    pd_vld <= pc_vld;
                end if;
    
                if pc_vld='1' then
                    full_product := pc_iteration*c_FACTOR_A;
                    cut_product  := full_product(31 downto 0);
                    pd_time_main <= pa_adjusted - cut_product;
                    pd_time_aux  <= pa_adjusted - cut_product  - g_MAIN_WIDTH;
                end if;
            
                min_full_product := pc_min_iteration*c_FACTOR_A;
                min_cut_product  := full_product(31 downto 0);
                pd_min_time_main <= pa_min_adjusted - min_cut_product;
                pd_min_time_aux  <= pa_min_adjusted - min_cut_product  - g_MAIN_WIDTH;
                
            end if;
        end process;
        

        P1_EXTRACT_DATA: process(i_clk)
            variable sum1 : unsigned(7 downto 0) := (others => '0');
            variable sum2 : unsigned(3 downto 0) := (others => '0');
            variable sum3 : unsigned(2 downto 0) := (others => '0');
        begin
            
            if rising_edge(i_clk) then
                if i_rst='1' then
                    p1_vld   <= '0';
                else
                    p1_vld <= pd_vld;
                end if;
    
                if pd_vld='1' then
                    if pd_time_main>=g_MAIN_WIDTH then
                        p1_buffer <= c_AUX_E;
                        p1_time   <= to_integer(pd_time_aux);
                    else
                        p1_buffer <= c_MAIN;
                        p1_time   <= to_integer(pd_time_main);
                    end if;

                    p1_dummy_header  <= pa_dummy_header;
                    p1_channel       <= pa_channel;
                    p1_station       <= pa_station;
                    p1_packet_count  <= pa_packet_count;
                    p1_phase         <= pc_iteration(1 downto 0);
                    p1_iteration     <= pc_iteration;

                    --------------------------------------------------------------
                    -- The following calculates a mod3 of pc_iteration.
                    -- It uses the fact that the (digit sum of x) mod 3 = x mod 3  
                    -- This is true for base 10 (as one learns in school), but
                    -- also for base 4 and base 16.
                    -- This basically works for any divider x and base b where
                    -- there is an n so that n*x=b-1 
                    --------------------------------------------------------------
                    sum1 := (others => '0');
                    sum2 := (others => '0');
                    sum3 := (others => '0');
                    for i in 0 to 7 loop
                        sum1 := sum1 + pc_iteration(4*(i+1)-1 downto 4*i);
                    end loop;
                    for i in 0 to 3 loop
                        sum2 := sum2 + sum1(2*(i+1)-1 downto 2*i);
                    end loop;
                    for i in 0 to 1 loop
                        sum3 := sum3 + sum2(2*(i+1)-1 downto 2*i);
                    end loop;
                    if sum3=B"000" or sum3=B"011" or sum3=B"110" then
                        p1_aux<=0;
                    elsif sum3=B"001" or sum3=B"100" or sum3=B"111" then
                        p1_aux<=1;
                    else
                        p1_aux<=2;       
                    end if;                                         
                end if;    

                p1_iteration_low <= pc_min_iteration;
                if pd_min_time_main>=g_MAIN_WIDTH then
                    p1_min_buffer <= c_AUX_E;
                else
                    p1_min_buffer <= c_MAIN;
                end if;
            
            end if;
        end process;
    
        -----------------------------------------------------------------------------------------
        -- PIPELINE STAGE 2: USE CASE = WRITE ADDRESS
        --
        -- Calculate the time-station/channel-coordinates inside the memory.
        -- (this is phase independent)
        -- (g_MAIN_WIDTH represents the number of ts stored in Main Buffer here)
        ------------------------------------------------------------------------------------------
        P2_CALC_XY_ADDRESS: process (i_clk)
            variable check_mod3 : unsigned(31 downto 0);
        begin
            if rising_edge(i_clk) then
                if i_rst='1' then
                    p2_buffer <= c_INIT; 
                    p2_time   <= 0;
                    p2_sc     <= 0;
                    p2_aux    <= 0;
                    p2_vld    <= '0';
                    p2_station<= 0;
                    p2_phase  <= (others =>'0');
                    p2_iteration_high <= (others =>'0');
                    p2_iteration_low  <= (others =>'0');
                    p2_cursor       <= (others => '0');
                    p2_low_is_aux   <= '0';
                    p2_high_is_aux  <= '0';
                    p2_maximum_pc   <= (others => '0');
                    p2_minimum_pc   <= unsigned(i_config_start_ts);
                    p2_dummy_header <= '0';
                else
                    p2_vld <= p1_vld;
                    if p1_vld='1' then
                        
                        --defaults:
                        p2_station      <= p1_station;
                        p2_phase        <= p1_phase;
                        p2_time         <= p1_time;
                        p2_buffer       <= p1_buffer;
                        p2_dummy_header <= p1_dummy_header;
                        
                        check_mod3  := pc_iteration mod 3;
                        assert p1_aux=to_integer(check_mod3) report "Wrong mod3 result!" severity FAILURE;
                        p2_aux      <= p1_aux;
                        
                        p2_sc       <= p1_channel*pc_STATION_NUMBER + p1_station;
                        p2_dev_null <= '0';
                        
                        if p1_iteration>p2_iteration_high then
                            p2_iteration_high <= p1_iteration;
                        end if;    
                    
                        if p1_packet_count > p2_maximum_pc then
                            p2_maximum_pc <= p1_packet_count;
                            p2_cursor     <= to_unsigned(p1_time, p2_cursor'length);
                            if p1_buffer = c_AUX_E then
                                p2_high_is_aux <= '1';
                            else
                                p2_high_is_aux <= '0';
                            end if;        
                            if p1_packet_count >= g_MAXIMUM_DRIFT then
                                p2_minimum_pc <= p1_packet_count - g_MAXIMUM_DRIFT; 
                            else
                                p2_minimum_pc <= (others => '0');
                            end if;
                        end if;
                        
                        if p1_packet_count < p2_minimum_pc then
                            p2_dev_null <= '1';
                        end if;                         
                    end if;  
                                      
                    p2_iteration_low <= p1_iteration_low;
                    if p1_min_buffer = c_AUX_E then
                        p2_low_is_aux <= '1';
                    else
                        p2_low_is_aux <= '0';
                    end if;   
                         
                end if;
            end if;
        end process;
    
    
    else generate 
    
        -- ########################################################################
        -- ##########################  USE CASE = READ  ###########################
        -- ########################################################################

        o_phase_low  <= std_logic_vector(p2_phase);  
        o_phase_high <= std_logic_vector(p2_phase);  
        o_cursor     <= p2_cursor;
        
        -----------------------------------------------------------------------------------------
        -- PIPELINE STAGE 1: USE CASE = READ ADDRESS
        --
        -- Generate Station, Group, Channel and Time 
        -- This is a look-ahead stage representing of what is going to be used next.
        ------------------------------------------------------------------------------------------
        P1_GENERATE_SCT: process (i_clk)
        begin
            if rising_edge(i_clk) then
                
                if i_rst='1' then
                    p1_buffer     <= c_AUX_S; 
                    p1_time       <= g_PRELOAD_OFFSET-g_COARSE_DELAY_OFFSET;
                    p1_phase      <= to_unsigned(g_START_PHASE, 2);
                    p1_station    <= 0;
                    p1_group      <= 0;
                    p1_channel    <= 0;
                    p1_aux        <= 1;
                    p1_vld        <= '0';
                    p1_inner_time <= 0;
                    p1_cursor     <= to_unsigned(g_WIDTH_PADDING, p1_cursor'length); 
                    p1_address_in_packet <= 0;
                else
                    if packet_state=s_IDLE then
                        if p1_address_in_packet=g_INPUT_BLOCK_SIZE-g_ATOM_SIZE then
                            p1_address_in_packet <= 0;
                            if p1_station = g_STATION_GROUP_SIZE-1 then
                                p1_station <= 0;
                                if p1_buffer=c_AUX_S and p1_time=g_AUX_WIDTH-1 then
                                    p1_time   <= 0;
                                    p1_buffer <= c_MAIN;
                                elsif p1_buffer=c_MAIN and p1_time=g_MAIN_WIDTH-1 then
                                    p1_time   <= 0;
                                    p1_buffer <= c_AUX_E;
                                elsif p1_buffer=c_AUX_E and p1_time=g_AUX_WIDTH-1 then
                                    p1_time   <= g_PRELOAD_OFFSET-g_COARSE_DELAY_OFFSET;
                                    p1_buffer <= c_AUX_S;
                                    if p1_group=(pc_STATION_NUMBER/g_STATION_GROUP_SIZE)-1 then
                                        p1_group <= 0;
                                        if p1_channel=g_COARSE_CHANNELS-1 then
                                            p1_cursor   <= to_unsigned(g_WIDTH_PADDING, p1_cursor'length);
                                            p1_channel  <= 0;
                                            p1_phase    <= p1_phase + 1;
                                            if p1_aux = c_AUX_NUMBER-1 then
                                                p1_aux <= 0;
                                            else    
                                                p1_aux <= p1_aux + 1;
                                            end if;
                                        else
                                            p1_cursor  <= p1_cursor + 1;
                                            p1_channel <= p1_channel + 1;
                                        end if;    
                                    else    
                                        p1_cursor <= p1_cursor + 1;
                                        p1_group  <= p1_group + 1;
                                    end if;    
                                else
                                    p1_time  <= p1_time + 1;
                                end if;
                            else
                               p1_station <= p1_station + 1;
                            end if;            
                        else                            
                            p1_address_in_packet <= p1_address_in_packet + g_ATOM_SIZE;
                        end if;
                    end if;                    
                end if;
            end if;
        end process;


        -----------------------------------------------------------------------------------------
        -- PIPELINE STAGE 2: USE CASE = READ ADDRESS
        --
        -- Calculate sc and aux 
        ------------------------------------------------------------------------------------------
        P2_CALCULATE_SC: process (i_clk)
        begin
            if rising_edge(i_clk) then
                if i_rst='1' then
                    p2_phase  <= to_unsigned(g_START_PHASE, 2);
                    p2_buffer <= c_INIT; 
                    p2_time   <= 0;
                    p2_sc     <= 0;
                    p2_aux    <= 0;
                    p2_vld    <= '0';
                    p2_cursor <= to_unsigned(g_WIDTH_PADDING, p2_cursor'length); 
                    p2_address_in_packet <= 0;
                    p2_new_block <= '0';
                else
                    if packet_state=s_IDLE then
                        p2_vld     <= '1';
                        p2_sc      <= p1_channel*pc_STATION_NUMBER + p1_group*g_STATION_GROUP_SIZE + p1_station;
                        p2_time    <= p1_time;
                        p2_buffer  <= p1_buffer;
                        p2_station <= p1_station;
                        p2_phase   <= p1_phase;
                        p2_cursor  <= p1_cursor;
                        p2_address_in_packet <= p1_address_in_packet;
                        
                        if p1_address_in_packet=0 then
                            p2_new_block <= '1';
                        else
                            p2_new_block <= '0';
                        end if;                            
                        
                        if p1_buffer=c_AUX_S then
                            if p1_aux = 0 then
                                p2_aux <= c_AUX_NUMBER-1;
                            else
                                p2_aux <= p1_aux - 1;
                            end if;    
                        else
                            p2_aux <= p1_aux;
                        end if;                    
                    else
                        p2_vld <= '0';
                    end if;        
                end if;
            end if;
        end process;
    
    end generate;
    
    
    -- ########################################################################
    -- ##########################  USE CASE = BOTH  ###########################
    -- ########################################################################


    -----------------------------------------------------------------------------------------
    -- PIPELINE STAGE 3
    --
    -- Calculate the x-y-coordinates based on station/channel, time and phase.
    -----------------------------------------------------------------------------------------
    P3_CALC_XY: process (i_clk)
    begin
       if rising_edge(i_clk) then
            
            o_station_channel_vld <= '0';
            
            if i_rst='1' then
                p3_vld   <='0';
            else 
                --keep p3_vld at '1' until it has been seen
                if p2_vld='1' and p2_dummy_header='0' then
                    o_station_channel     <= std_logic_vector(to_unsigned(p2_sc, 10));
                    o_station_channel_vld <= p2_new_block;

                    if p2_buffer=c_AUX_S then
                        o_station_channel_aux <= '1';
                    else
                        o_station_channel_aux <= '0';
                    end if;

                    p3_vld <= '1';
                elsif i_address_rdy='1' and i_address_stop='0' then
                    p3_vld <= '0';
                end if;        
            end if;
            
            p3_dev_null <= p2_dev_null;   
           
            case p2_phase is
            when B"00" =>
                p3_x <= g_WIDTH_PADDING + p2_sc/2;
                if to_unsigned(p2_sc,1)=B"0" then
                    p3_y <= 2*p2_time;
                else
                    p3_y <= 2*p2_time+1;
                end if;    
            when B"01" =>
                    p3_x <= p2_time;
                    p3_y <= (g_MAIN_HEIGHT-1)-p2_sc;
            when B"10" =>
                p3_x <= (g_MAIN_WIDTH-1)-(p2_sc/2);
                if to_unsigned(p2_sc,1)=B"0" then
                    p3_y <= (g_BUFFER_HEIGHT-1) - 2*p2_time;
                else
                    p3_y <= (g_BUFFER_HEIGHT-2) - 2*p2_time;
                end if;    
            when B"11" =>
                    p3_x <= (g_BUFFER_WIDTH-1) - p2_time;
                    p3_y <= g_HEIGHT_PADDING + p2_sc;
            when others =>                    
            end case;    

            p3_aux_buffer_offset <= (g_MAIN_BUFFER_SIZE + p2_aux*g_AUX_BUFFER_SIZE);
            p3_aux_x             <= p2_time*g_INPUT_BLOCK_SIZE;
            p3_aux_y             <= p2_sc*g_INPUT_BLOCK_SIZE*g_AUX_WIDTH;
            p3_buffer            <= p2_buffer;
            
            p3_aux_block_buffer_offset <= ((g_BUFFER_WIDTH*g_BUFFER_HEIGHT) + p2_aux*(g_AUX_HEIGHT*g_AUX_WIDTH));
            p3_aux_block_x             <= p2_time;
            p3_aux_block_y             <= p2_sc*g_AUX_WIDTH;
            
            p3_address_in_packet <= p2_address_in_packet;
             
        end if;
    end process;
        
        
    -----------------------------------------------------------------------------------------
    -- PIPELINE STAGE 4
    --
    -- Calculate the packet address based on the x-y-coordinates
    -----------------------------------------------------------------------------------------
    P4_CALC_OFFSET: process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst='1' then
                p4_vld <='0';
            elsif i_address_rdy='1' and i_address_stop='0' and p3_vld='1' then
                p4_vld <= '1';
            else
                p4_vld <= '0';    
            end if;    

            if p3_dev_null='0' then
                if p3_buffer=c_MAIN then
                    p4_offset <= p3_x*g_INPUT_BLOCK_SIZE + p3_y*g_INPUT_BLOCK_SIZE*g_BUFFER_WIDTH;
                else --c_AUX_E or c_AUX_S
                    p4_offset <= p3_aux_buffer_offset + p3_aux_x + p3_aux_y;
                end if;
            else
                p4_offset <= g_DEV_NULL;    
            end if;    
            
            if p3_buffer=c_MAIN then
                p4_block_offset <= to_unsigned(p3_x + p3_y*g_BUFFER_WIDTH, p4_block_offset'length);
            else --c_AUX_E or c_AUX_S
                p4_block_offset <= to_unsigned(p3_aux_block_buffer_offset + p3_aux_block_x + p3_aux_block_y, p4_block_offset'length);
            end if;
            
            if p3_buffer=c_AUX_S or p3_buffer=c_MAIN or (p3_buffer=c_AUX_E and p3_aux_block_x<g_PRELOAD_OFFSET-g_COARSE_DELAY_OFFSET) then
                --is this the last time we read this address? if so, clear the valid bit!
                p4_clear <= '1';
            else
                p4_clear <= '0';
            end if; 
            
            p4_good <= not p3_dev_null;     

        end if;
    end process;

    o_block_offset     <= std_logic_vector(p4_block_offset);
    o_block_offset_vld <= p4_vld when g_USE_CASE_IS_WRITE else p4_vld when p4_address_in_packet=0 else '0';
    o_block_clear      <= p4_clear;
    o_block_good       <= p4_good;
    o_error_too_late   <= not p4_good and o_block_offset_vld;  

    -----------------------------------------------------------------------------------------
    -- PIPELINE STAGE 4
    -- (This happens in parallel to the pipeline stage above)
    --
    -- Calculate the sub-address inside one packet
    -----------------------------------------------------------------------------------------
    P4_CALC_IN_PACKET_ADDRESS: process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst='1' then
                p4_address_in_packet <= 0;
                packet_state         <= s_DONE;
                address_we           <= '0';
                header_in_rdy        <= '0';
            else
                if packet_state=s_IDLE and (not g_USE_CASE_IS_WRITE or i_header_in_vld='1') then

                    --this is independent of i_address_rdy and i_address_stop
                    packet_state  <= s_CALC;
                    header_in_rdy <= '0';

                elsif i_address_rdy='1' then

                    --defaults:
                    address_we <= '0';
                    
                    if i_address_stop='0' then
                        case packet_state is
                        when s_IDLE  =>
                            header_in_rdy <= '1';
                        when s_CALC  =>
                            if p3_vld='1' then
                                if g_USE_CASE_IS_WRITE then
                                    packet_state         <= s_RUNNING;
                                    p4_address_in_packet <= 0;
                                    address_we           <= '1';
                                else
                                    packet_state         <= s_DONE;
                                    p4_address_in_packet <= p3_address_in_packet;
                                    address_we           <= '1';
                                end if;    
                            end if;
                            if p2_vld='1' and p2_dummy_header='1' then
                                address_we   <= '0';
                                packet_state <= s_DONE;
                            end if;    
                            
                        when s_RUNNING => 
                            address_we        <= '1';
                            if p4_address_in_packet=g_INPUT_BLOCK_SIZE-g_ATOM_SIZE then
                                header_in_rdy     <= '1';
                                packet_state      <= s_IDLE;
                                p4_address_in_packet <= 0;
                                address_we        <= '0';
                            else
                                p4_address_in_packet <= p4_address_in_packet + g_ATOM_SIZE; 
                            end if;    
                        when s_DONE =>
                            header_in_rdy <= '1';
                            address_we    <= '0';
                            packet_state  <= s_IDLE;
                        end case;
                    end if;    
                end if;                    
            end if;
        end if;
    end process;
    
    
    -----------------------------------------------------------------------------------------
    -- PIPELINE STAGE 5
    --
    -- Combine offset and sub-address to the address output.
    -----------------------------------------------------------------------------------------
    P5_CALC_ADDRESS: process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst='1' then
                o_address_vld <= '0';
            elsif i_address_rdy='1' then
                o_address_vld <= address_we;
                address       <= to_unsigned(p4_address_in_packet + p4_offset, address'length);
            end if;          
        end if;
    end process;

    o_address <= std_logic_vector(address);



end Behavioral;
