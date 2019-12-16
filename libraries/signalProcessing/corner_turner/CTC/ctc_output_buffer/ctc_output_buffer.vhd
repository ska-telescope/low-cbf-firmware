---------------------------------------------------------------------------------------------------
-- 
-- OUTPUT BUFFER
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert_abel@gmx.net)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
-- 
-- This module takes the HBM output data and splits it out to the 4 output ports,
-- so that each output port gets all the data in ts order.
-- Port0: station=st_group*2+0, pol0  
-- Port1: station=st_group*2+0, pol1  
-- Port2: station=st_group*2+1, pol0  
-- Port3: station=st_group*2+1, pol1  
-- 
-- All output ports are synchronous in regard to data_valid.
--
-- This module also takes care of the timed output and the coarse delay.
--
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.ctc_pkg.all;

Library xpm;
use xpm.vcomponents.all;

entity ctc_output_buffer is
    generic(
        g_FIFO1_DEPTH             : integer := 512;
        g_FIFO2_DEPTH             : integer := 512;
        g_INPUT_PACKET_LEN        : integer := 16;
        g_INPUT_PACKET_COUNT      : integer := 408+24;
        g_OUTPUT_PACKET_LEN       : integer := 4096;
        g_COARSE_DELAY_OFFSET     : integer := 2;
        g_STATION_GROUP_SIZE      : integer := 2; 
        g_COARSE_CHANNELS         : integer := 128;
        g_OUTPUT_TIME_COUNT       : integer := 204;
        g_OUTPUT_PRELOAD          : integer := 11;
        g_INPUT_TIME_COUNT        : integer := 408;
        g_INPUT_BLOCK_SIZE        : integer := 2048;
        g_INPUT_STOP_WORDS        : integer
    );
    port (
        i_hbm_clk        : in  std_logic;
        i_hbm_clk_rst    : in  std_logic;
        i_output_clk     : in std_logic;
        i_output_clk_rst : in std_logic;
        --coarse delay:
        o_coarse_delay_addr         : out std_logic_vector(31 downto 0);
        o_coarse_delay_addr_vld     : out std_logic;
        i_coarse_delay_packet_count : in  std_logic_vector(31 downto 0);
        i_coarse_delay_value        : in  std_logic_vector(15 downto 0);
        i_coarse_delay_delta_hpol   : in  std_logic_vector(15 downto 0);
        i_coarse_delay_delta_vpol   : in  std_logic_vector(15 downto 0);
        i_coarse_delay_delta_delta  : in  std_logic_vector(15 downto 0);
        o_end_of_integration_period : out std_logic;
        o_current_packet_count      : out std_logic_vector(31 downto 0);
        -- config:
        i_output_clk_wall_time : in t_wall_time;            
        i_hbm_config_update    : in std_logic;
        i_hbm_config_start_ts  : in std_logic_vector(31 downto 0);
        i_out_config_start_ts  : in std_logic_vector(31 downto 0);
        i_out_config_update    : in std_logic;
        i_config_start_wt      : in t_wall_time;
        i_config_output_cycles : in std_logic_vector(31 downto 0);
        i_enable_timed_output  : in std_logic;
        --data in:
        i_data_in        : in  t_ctc_hbm_data;
        i_data_in_vld    : in  std_logic;
        i_block_vld      : in  std_logic;
        o_data_in_stop   : out std_logic;
        --data out:
        o_start_of_frame  : out std_logic;
        o_header_out      : out t_ctc_output_header_a(pc_CTC_OUTPUT_NUMBER-1 downto 0);
        o_header_out_vld  : out std_logic;
        o_data_out        : out t_ctc_output_data_a(pc_CTC_OUTPUT_NUMBER-1 downto 0);
        o_data_out_vld    : out std_logic;
        o_packet_vld      : out std_logic_vector(pc_CTC_OUTPUT_NUMBER-1 downto 0);
        i_data_out_stop   : in  std_logic;
        --error:
        o_error_dsp_overflow               : out std_logic_vector(3 downto 0);
        o_error_ctc_underflow              : out std_logic;
        o_error_output_aligment_loss       : out std_logic;
        o_error_coarse_delay_fifo_overflow : out std_logic
    );
end ctc_output_buffer;

architecture Behavioral of ctc_output_buffer is

    --keep the tools from instantiating DSPs        
    attribute use_dsp48 : string;
    attribute use_dsp48 of Behavioral : architecture is "no";      

    constant c_NUMBER_OF_SEGMENTS  : integer := 8;   --how many dual polarisations (32 bit) are in one 256bit vector? 

    constant c_COARSE_DELAY_ONE_CYCLE_POS  : integer := log2_ceil(c_NUMBER_OF_SEGMENTS);  --fix: one input cycle is 8 samples (256=8*32)
    constant c_COARSE_DELAY_PACKET_NUM_POS : integer := log2_ceil(g_INPUT_PACKET_LEN*c_NUMBER_OF_SEGMENTS);
    constant c_COARSE_DELAY_MAXIMUM_POS    : integer := log2_ceil(g_INPUT_PACKET_COUNT*g_INPUT_PACKET_LEN*c_NUMBER_OF_SEGMENTS);    

    constant c_COARSE_DELAY_WIDTH          : integer := 12;
    
    constant g_STATION_NUMBER      : integer := pc_STATIONS_PER_PORT*pc_CTC_INPUT_NUMBER;               --6
    constant g_GROUP_NUMBER        : integer := g_STATION_NUMBER/g_STATION_GROUP_SIZE; 

    constant c_HBM_WIDTH       : integer := 256; --fix for this design
    constant c_DUAL_POL_WIDTH  : integer := 32;  --fix for this design
    constant c_META_WIDTH      : integer := sel(THIS_IS_SIMULATION, pc_CTC_META_WIDTH, 0);
    constant c_FIFO1_WIDTH     : integer := c_HBM_WIDTH+16*c_META_WIDTH+1+c_COARSE_DELAY_ONE_CYCLE_POS+1+c_COARSE_DELAY_WIDTH+1;
    constant c_FIFO2_WIDTH     : integer := c_DUAL_POL_WIDTH+2*c_META_WIDTH+1;
    
    constant c_ALMOST_FULL_THRESHOLD : integer := g_INPUT_STOP_WORDS;
   
    constant c_FIFO_NUM              : integer := pc_CTC_OUTPUT_NUMBER; --2 polarisations per FIFO

    constant c_MAXIMUM_TIME : integer := g_INPUT_PACKET_LEN*g_INPUT_PACKET_COUNT*c_NUMBER_OF_SEGMENTS-1;
    
    signal wr_en_station  : std_logic_vector(c_FIFO_NUM-1 downto 0);
    signal wr_en_coarse   : std_logic;
    signal counter     : unsigned(log2_ceil(g_INPUT_PACKET_LEN)-1 downto 0);
    signal almost_full : std_logic_vector(c_FIFO_NUM-1 downto 0);
    signal wr_rst_busy : std_logic_vector(c_FIFO_NUM-1 downto 0);
    
    type t_output_data is array (integer range <>) of std_logic_vector(c_FIFO2_WIDTH-1 downto 0);
    signal dout        : t_output_data(c_FIFO_NUM-1 downto 0);
    signal rd_en       : std_logic;
    signal empty       : std_logic_vector(c_FIFO_NUM-1 downto 0);
    signal out_counter : unsigned(log2_ceil(g_OUTPUT_PACKET_LEN)-1 downto 0);
    signal out_running : std_logic;
    
    signal p1_data_in_vld : std_logic;
    
    signal next_station : unsigned(log2_ceil(g_STATION_GROUP_SIZE)-1 downto 0);
    signal next_time    : unsigned(log2_ceil(g_INPUT_PACKET_COUNT)-1 downto 0);
    signal curr_time    : unsigned(log2_ceil(g_INPUT_PACKET_COUNT)-1 downto 0);
    signal next_group   : unsigned(log2_ceil(g_GROUP_NUMBER)-1 downto 0);
    signal next_coarse  : unsigned(log2_ceil(g_COARSE_CHANNELS)-1 downto 0);
    signal next_address : unsigned(31 downto 0);
    
    signal segment_valid_in : std_logic_vector(c_COARSE_DELAY_ONE_CYCLE_POS downto 0);
    
    signal switch_fifo  : std_logic;
    signal post_reset   : std_logic;
    
    signal coarse_delay_start : unsigned(63 downto 0);
    signal coarse_delay_end   : unsigned(63 downto 0);
    signal coarse_delay_we    : std_logic;
    signal coarse_delay_re    : std_logic;
    signal coarse_delay_empty : std_logic_vector(c_FIFO_NUM-1 downto 0);
       
    signal cycle_counter  : unsigned(31 downto 0);
    signal wait_for_start : std_logic;
    signal output_trigger : std_logic;
   
    signal out_packet_count_raw     : unsigned(31 downto 0);
    signal out_inner_packet_count   : unsigned(31 downto 0);
    type t_out_coarse_delay is array(c_FIFO_NUM-1 downto 0) of std_logic_vector(11 downto 0);
    signal out_coarse_delay         : t_out_coarse_delay;
    signal out_virtual_channel      : unsigned(08 downto 0);
    signal out_station              : unsigned(08 downto 0);
    
    type t_out_coarse_delay_delta is array(c_FIFO_NUM-1 downto 0) of std_logic_vector(31 downto 0);
    signal out_coarse_delay_delta : t_out_coarse_delay_delta;
    signal coarse_delay_delta_empty : std_logic_vector(c_FIFO_NUM-1 downto 0);
    
    signal error_coarse_delay_fifo_overflow : std_logic_vector(c_FIFO_NUM-1 downto 0);

    signal end_of_integration_period : std_logic;
    signal current_packet_count      : std_logic_vector(31 downto 0);
   
    signal my_enable_timed_output    : std_logic;
    signal my_update                 : std_logic;
    
    signal coarse_delay_addr_vld     : std_logic;
    signal coarse_delay_delta_vld    : std_logic;
    
begin

    o_error_coarse_delay_fifo_overflow <= OR(error_coarse_delay_fifo_overflow);

    o_coarse_delay_addr <= std_logic_vector(next_address);

    ----------------------------------------------------------------------------
    --
    -- Demultiplex: Write to the correct output FIFO.
    --
    -- Coarse Delay - First Stage (256 bit granularity):
    -- Only write to the FIFO if the data is required (based on the coarse delay value).
    -- Also write the relevant coarse delay info into the FIFO. 
    ----------------------------------------------------------------------------
    P_DEMULTIPLEX: process (i_hbm_clk)
        variable coarse_delay_start_inpacket : unsigned(c_COARSE_DELAY_PACKET_NUM_POS-c_COARSE_DELAY_ONE_CYCLE_POS-1 downto 0);
        variable coarse_delay_start_time     : unsigned(c_COARSE_DELAY_MAXIMUM_POS-c_COARSE_DELAY_PACKET_NUM_POS-1 downto 0);
        variable coarse_delay_end_inpacket   : unsigned(c_COARSE_DELAY_PACKET_NUM_POS-c_COARSE_DELAY_ONE_CYCLE_POS-1 downto 0);
        variable coarse_delay_end_time       : unsigned(c_COARSE_DELAY_MAXIMUM_POS-c_COARSE_DELAY_PACKET_NUM_POS-1 downto 0);
    begin
        if rising_edge(i_hbm_clk) then
    
            --defaults:
            switch_fifo     <= '0';
            coarse_delay_we <= '0';
            wr_en_coarse    <= '0';
            end_of_integration_period <= '0';
            o_coarse_delay_addr_vld   <= '0';
            coarse_delay_delta_vld    <= '0';

            if i_hbm_clk_rst='1' then
                wr_en_station  <= (0=>'1', others=>'0');
                wr_en_coarse   <= '0';
                counter        <= (others=>'0');
                p1_data_in_vld <= '0';
                next_station   <= to_unsigned(1, next_station'length); --the next_... stuff is always one station ahead
                next_time      <= (others => '0');
                curr_time      <= (others => '0');
                next_group     <= (others => '0');
                next_coarse    <= (others => '0');
                next_address   <= (others => '0');
                post_reset     <= '1';
                coarse_delay_start <= (others => '0');
                coarse_delay_end   <= (others => '1');
                segment_valid_in   <= (others => '0');
                current_packet_count <= i_hbm_config_start_ts;
                o_end_of_integration_period <= '0';
                coarse_delay_addr_vld  <= '1';
                o_current_packet_count <= (others => '0');
            else

                p1_data_in_vld <= i_data_in_vld;
                
                coarse_delay_start_inpacket := coarse_delay_start(c_COARSE_DELAY_PACKET_NUM_POS-1 downto c_COARSE_DELAY_ONE_CYCLE_POS);
                coarse_delay_start_time     := coarse_delay_start(c_COARSE_DELAY_MAXIMUM_POS-1 downto c_COARSE_DELAY_PACKET_NUM_POS);
                coarse_delay_end_inpacket   := coarse_delay_end(c_COARSE_DELAY_PACKET_NUM_POS-1 downto c_COARSE_DELAY_ONE_CYCLE_POS);
                coarse_delay_end_time       := coarse_delay_end(c_COARSE_DELAY_MAXIMUM_POS-1 downto c_COARSE_DELAY_PACKET_NUM_POS);
                
                --cycle valid?
                if  ((curr_time>coarse_delay_start_time) or (curr_time=coarse_delay_start_time and counter>=coarse_delay_start_inpacket)) and
                    ((curr_time<coarse_delay_end_time) or (curr_time=coarse_delay_end_time and counter<=coarse_delay_end_inpacket))
                then
                    if i_data_in_vld='1' then
                        wr_en_coarse <= '1';
                        if (curr_time =coarse_delay_start_time and counter=g_INPUT_PACKET_LEN-1 and (OR(coarse_delay_start(c_COARSE_DELAY_PACKET_NUM_POS-1 downto 0))='0'))
                        or (curr_time/=coarse_delay_start_time and counter=coarse_delay_end_inpacket) then
                            coarse_delay_we <= '1'; --block complete! - this is done at the end of a block and used at readout to identify that a whole block is ready 
                        end if;
                    end if;           
                end if;
                
                --segment valid?
                --(this is one cycle delayed and catches up by not being flopped below)
                if (curr_time=coarse_delay_start_time and counter=coarse_delay_start_inpacket) then
                    --                 start                   delay value inside one cycle
                    segment_valid_in <= '1' & std_logic_vector(coarse_delay_start(c_COARSE_DELAY_ONE_CYCLE_POS-1 downto 0));
                elsif (curr_time=coarse_delay_end_time and counter=coarse_delay_end_inpacket) then
                    --                  end                    delay value inside one cycle
                    segment_valid_in <= '0' & std_logic_vector(coarse_delay_end(c_COARSE_DELAY_ONE_CYCLE_POS-1 downto 0));
                else
                    segment_valid_in <= (segment_valid_in'HIGH=>'1', others=>'0');
                end if;
                
                --switch to next fifo:
                if switch_fifo='1' then 
                    wr_en_station <= wr_en_station(c_FIFO_NUM-2 downto 0) & wr_en_station(c_FIFO_NUM-1);
                end if;

                --load first coarse delay value after reset:
                if post_reset='1' then
                    coarse_delay_start(c_COARSE_DELAY_WIDTH-1 downto 0) <= unsigned(i_coarse_delay_value(c_COARSE_DELAY_WIDTH-1 downto 0));
                    coarse_delay_end   <= to_unsigned(c_MAXIMUM_TIME - g_COARSE_DELAY_OFFSET*g_INPUT_PACKET_LEN*c_NUMBER_OF_SEGMENTS + to_integer(unsigned(i_coarse_delay_value(c_COARSE_DELAY_WIDTH-1 downto 0))), coarse_delay_end'length);
                end if;    

           
                --determine end of packet & next address in coarse delay buffer:
                if i_data_in_vld='1' then
                    post_reset <= '0';
                                        
                    next_address <= to_unsigned(to_integer(next_coarse)*g_STATION_NUMBER + to_integer(next_group)*g_STATION_GROUP_SIZE + to_integer(next_station), 32);
                    o_coarse_delay_addr_vld <= coarse_delay_addr_vld;
                    coarse_delay_addr_vld   <= '0';
                    
                    counter      <= counter + 1;
                    o_end_of_integration_period <= end_of_integration_period;
                    o_current_packet_count      <= current_packet_count;
                    
                    if counter=g_INPUT_PACKET_LEN-1 then                       
                        coarse_delay_addr_vld <= '1';
                        coarse_delay_start(c_COARSE_DELAY_WIDTH-1 downto 0) <= unsigned(i_coarse_delay_value(c_COARSE_DELAY_WIDTH-1 downto 0));
                        coarse_delay_end   <= to_unsigned(c_MAXIMUM_TIME - g_COARSE_DELAY_OFFSET*g_INPUT_PACKET_LEN*c_NUMBER_OF_SEGMENTS + to_integer(unsigned(i_coarse_delay_value(c_COARSE_DELAY_WIDTH-1 downto 0))), coarse_delay_end'length);
                        counter     <= (others=>'0');
                        switch_fifo <= '1';
                        coarse_delay_delta_vld <= '1';
                        curr_time   <= next_time;
                        if next_station=g_STATION_GROUP_SIZE-1 then
                            next_station<=(others => '0');
                            if next_time=g_INPUT_PACKET_COUNT-1 then
                                next_time   <= (others => '0');
                                if next_group=g_GROUP_NUMBER-1 then
                                    next_group <= (others => '0');
                                    if next_coarse=g_COARSE_CHANNELS-1 then
                                        end_of_integration_period <= '1';
                                        current_packet_count      <= std_logic_vector(unsigned(current_packet_count)+2*g_OUTPUT_TIME_COUNT);
                                        next_coarse <= (others => '0');
                                    else
                                        next_coarse <= next_coarse + 1;
                                    end if;
                                else    
                                    next_group <= next_group + 1;
                                end if;
                            else
                                next_time <= next_time + 1;
                            end if;        
                        else
                            next_station <= next_station + 1;
                        end if;         
                    end if;
                end if;    
            end if;
        end if;
    end process;
    
    P_READY: process (i_hbm_clk)
    begin
        if rising_edge(i_hbm_clk) then
            o_data_in_stop <= OR(almost_full) or OR(wr_rst_busy);
        end if;
    end process;
        
    GEN_FIFOS: for fifo in 0 to c_FIFO_NUM-1 generate
        
        constant c_CD_CYCLES : integer := 6;

        signal din : std_logic_vector(c_FIFO1_WIDTH-(c_COARSE_DELAY_ONE_CYCLE_POS+1)-2 downto 0);
        
        signal local_re           : std_logic; 
        signal local_empty        : std_logic; 
        signal local_full         : std_logic; 
        signal local_dout         : std_logic_vector(c_FIFO1_WIDTH-1 downto 0);
        signal local_din          : std_logic_vector(c_FIFO2_WIDTH-1 downto 0);
        signal local_we           : std_logic;
        
        signal local_coarse_delay      : std_logic_vector(c_COARSE_DELAY_WIDTH-1 downto 0);
        signal local_coarse_delay_we   : std_logic;
        signal second_coarse_delay_we  : std_logic;
        signal local_coarse_delay_full : std_logic;
        
        signal segment     : integer range 0 to c_NUMBER_OF_SEGMENTS;
        
        signal coarse_delay_hpol_delta_out : std_logic_vector(15 downto 0);
        signal coarse_delay_vpol_delta_out : std_logic_vector(15 downto 0);
        
        signal coarse_delay_delta_we   : std_logic_vector(c_CD_CYCLES-1 downto 0);
        signal coarse_delay_delta_full : std_logic;
        signal second_delta : std_logic; 
        
        signal cd_packet_count : unsigned(31 downto 0);

        signal delta_hpol   : signed(15 downto 0);
        signal delta_vpol   : signed(15 downto 0);
        signal delta_delta  : signed(15 downto 0);
        signal S_uns        : unsigned(43 downto 0); 
        signal S_start_uns  : unsigned(43 downto 0);
        signal S_diff       : signed(26 downto 0);
        signal full_product : signed(27+16-1 downto 0);
        
        signal cd_config_start_ts : std_logic_vector(31 downto 0);

    begin
        
        E_MULT_DSP: entity work.ctc_output_dsp
        generic map(
            g_MREG  => 1
        ) port map (
            i_CLK   => i_hbm_clk,
            i_A     => S_diff,
            i_B     => delta_delta,
            o_P     => full_product
        );

        P_CONTROL_COARSE_DELAY_DELTA: process(i_hbm_clk)
            variable S            : signed(44 downto 0); --extra bit for '0' sign
            variable S_start      : signed(44 downto 0); --extra bit for '0' sign
            variable S_full_diff  : signed(44 downto 0);
            variable cut_product  : signed(15 downto 0);
        begin
            if rising_edge(i_hbm_clk) then
                
                coarse_delay_delta_we <= coarse_delay_delta_we(c_CD_CYCLES-2 downto 0) & '0';
                o_error_dsp_overflow(fifo*2+1 downto fifo*2)  <= (others => '0');
                
                if i_hbm_clk_rst='1' then
                    second_delta    <= '0';
                    cd_packet_count <= (others => '0');
                    cd_config_start_ts <= i_hbm_config_start_ts;
                    coarse_delay_delta_we <= (others => '0');
                    delta_hpol   <= (others => '0');
                    delta_vpol   <= (others => '0');
                    delta_delta  <= (others => '0');
                    S_uns        <= (others => '0');
                    S_start_uns  <= (others => '0');
                else 
                    if end_of_integration_period='1' and unsigned(current_packet_count)>=unsigned(i_coarse_delay_packet_count) then
                        cd_config_start_ts<=i_coarse_delay_packet_count;
                    end if;
                    
                    assert g_INPUT_BLOCK_SIZE<=2048 report "g_INPUT_BLOCK_SIZE bigger than 2048 not supported by the bitsizes below!" severity FAILURE;
                    if coarse_delay_addr_vld='1' then
                        delta_hpol   <= signed(i_coarse_delay_delta_hpol);
                        delta_vpol   <= signed(i_coarse_delay_delta_vpol);
                        delta_delta  <= signed(i_coarse_delay_delta_delta);
                        S_uns        <= (unsigned(current_packet_count) + cd_packet_count) * to_unsigned(g_INPUT_BLOCK_SIZE, 12) + (unsigned(i_coarse_delay_value));
                        S_start_uns  <= unsigned(cd_config_start_ts) * to_unsigned(g_INPUT_BLOCK_SIZE, 12);
                    end if;
                     
                    S            := signed('0' & std_logic_vector(S_uns));
                    S_start      := signed('0' & std_logic_vector(S_start_uns));
                    S_full_diff  := S - S_start; 
                    --keep the signed bit, divide by 64 = cut the last 6 bits, reduce to width of (1 sign bit + 26 bit):
                    S_diff       <= S_full_diff(44) & S_full_diff(31 downto 6);
                    
                    if (S_full_diff(44)='0' and (OR(S_full_diff(43 downto 32))/='0')) or (S_full_diff(44)='1' and AND(S_full_diff(43 downto 32))/='1') then
                        o_error_dsp_overflow(fifo*2+0) <= '1';
                    end if;
                    
                    -- IN DSP:
                    -- hpol_ps := delta_hpol + delta_delta * ((S-S_start)/64);
                    -- vpol_ps := delta_vpol + delta_delta * ((S-S_start)/64);

                    --keep the sign bit, drop the low 15 bits, cut down to 16 bit width:
                    cut_product := full_product(27+16-1) & full_product(29 downto 15);
                    if (full_product(27+16-1)='0' and (OR(full_product(27+16-2 downto 30))/='0')) or (full_product(27+16-1)='1' and AND(full_product(27+16-2 downto 30))/='1') then
                        o_error_dsp_overflow(fifo*2+1) <= '1';
                    end if;
                    
                    coarse_delay_hpol_delta_out <= std_logic_vector(delta_hpol + cut_product);
                    coarse_delay_vpol_delta_out <= std_logic_vector(delta_vpol + cut_product);
                                            
                    if coarse_delay_we='1' and wr_en_station(fifo)='1' then
                        second_delta <= not second_delta;
                        if second_delta='1' then
                            if cd_packet_count=2*g_OUTPUT_TIME_COUNT+2*g_OUTPUT_PRELOAD-2 then
                                cd_packet_count <= (others => '0');
                            else    
                                cd_packet_count <= cd_packet_count+2;
                            end if;    
                            
                            coarse_delay_delta_we(0) <= '1';
                        end if;
                    end if;    
                end if;
            end if;
        end process;
        
        E_FIFO_COARSE_DELAY_DELTA : xpm_fifo_async
        generic map (
            DOUT_RESET_VALUE    => "0",
            ECC_MODE            => "no_ecc",
            FIFO_MEMORY_TYPE    => "auto",
            FIFO_READ_LATENCY   => 0,
            FIFO_WRITE_DEPTH    => 32,
            FULL_RESET_VALUE    => 1,
            PROG_EMPTY_THRESH   => 5,
            PROG_FULL_THRESH    => 5,     
            RD_DATA_COUNT_WIDTH => log2_ceil(32),
            READ_DATA_WIDTH     => 32,
            READ_MODE           => "fwft",
            USE_ADV_FEATURES    => "0000",
            WAKEUP_TIME         => 0,
            WRITE_DATA_WIDTH    => 32,
            WR_DATA_COUNT_WIDTH => log2_ceil(32)
        ) port map (
            --di
            wr_clk        => i_hbm_clk,
            rst           => i_hbm_clk_rst,
            din           => coarse_delay_vpol_delta_out & coarse_delay_hpol_delta_out,
            wr_en         => coarse_delay_delta_we(c_CD_CYCLES-1),
            full          => coarse_delay_delta_full,
            --do
            rd_clk        => i_output_clk,
            dout          => out_coarse_delay_delta(fifo),
            rd_en         => coarse_delay_re,
            empty         => coarse_delay_delta_empty(fifo),
            --unused
            sleep         => '0', 
            injectdbiterr => '0',
            injectsbiterr => '0'
        );
        assert coarse_delay_delta_we(c_CD_CYCLES-1)/='1' or coarse_delay_delta_full/='1' report "Coarse Delay Delta FIFO overflow!" severity FAILURE;

    
        P_DIN: process (i_hbm_clk)
        begin
            if rising_edge(i_hbm_clk) then
                if THIS_IS_SIMULATION then
                    if i_block_vld='1' then
                        din <= i_block_vld & std_logic_vector(coarse_delay_start(c_COARSE_DELAY_WIDTH-1 downto 0)) & meta_to_slv(i_data_in.meta) & i_data_in.data;
                    else
                        din <= i_block_vld & std_logic_vector(coarse_delay_start(c_COARSE_DELAY_WIDTH-1 downto 0)) & meta_to_slv(pc_CTC_HBM_DATA_RFI.meta) & pc_CTC_HBM_DATA_RFI.data;
                    end if;    
                else
                    if i_block_vld='1' then
                        din <= i_block_vld & std_logic_vector(coarse_delay_start(c_COARSE_DELAY_WIDTH-1 downto 0)) & i_data_in.data;
                    else
                        din <= i_block_vld & std_logic_vector(coarse_delay_start(c_COARSE_DELAY_WIDTH-1 downto 0)) & pc_CTC_HBM_DATA_RFI.data;
                    end if;                
                end if;    
            end if;    
        end process;    
    
        E_FIFO1 : xpm_fifo_async
        generic map (
            DOUT_RESET_VALUE    => "0",
            ECC_MODE            => "no_ecc",
            FIFO_MEMORY_TYPE    => "block",
            FIFO_READ_LATENCY   => 0,
            FIFO_WRITE_DEPTH    => g_FIFO1_DEPTH,
            FULL_RESET_VALUE    => 1,
            PROG_EMPTY_THRESH   => 10,
            PROG_FULL_THRESH    => g_FIFO1_DEPTH-c_ALMOST_FULL_THRESHOLD,     
            RD_DATA_COUNT_WIDTH => log2_ceil(g_FIFO1_DEPTH),
            READ_DATA_WIDTH     => c_FIFO1_WIDTH,
            READ_MODE           => "fwft",
            USE_ADV_FEATURES    => "0002",       --prog full activated
            WAKEUP_TIME         => 0,
            WRITE_DATA_WIDTH    => c_FIFO1_WIDTH,
            WR_DATA_COUNT_WIDTH => log2_ceil(g_FIFO1_DEPTH)
        ) port map (
            --di
            wr_clk        => i_hbm_clk,
            rst           => i_hbm_clk_rst,
            wr_rst_busy   => wr_rst_busy(fifo),
            din           => segment_valid_in & coarse_delay_we & din,
            wr_en         => wr_en_station(fifo) and wr_en_coarse,
            prog_full     => almost_full(fifo),
            --do
            rd_clk        => i_hbm_clk,
            dout          => local_dout,
            rd_en         => local_re,
            empty         => local_empty,
            --unused
            sleep         => '0', 
            injectdbiterr => '0',
            injectsbiterr => '0'
        );    

        local_re <= '1' when segment=c_NUMBER_OF_SEGMENTS-1 and local_full='0' and local_empty='0' else '0';
    
        ----------------------------------------------------------------------------
        -- Coarse Delay - Second Stage (32 bit granularity):
        -- Only write to the FIFO if the data is required (based on the coarse delay value).
        ----------------------------------------------------------------------------
        P_COARSE_DELAY: process (i_hbm_clk)
            variable start         : std_logic;
            variable segment_valid : unsigned(c_COARSE_DELAY_ONE_CYCLE_POS-1 downto 0);
            variable meta : t_ctc_meta_a(1 downto 0);
        begin
            if rising_edge(i_hbm_clk) then
                --defaults:
                local_we <= '0';
                
                if i_hbm_clk_rst='1' then
                    segment<=0;
                    second_coarse_delay_we <= '0';
                elsif local_full='0' and local_empty='0' then
                    segment<=segment+1;
                    if segment=c_NUMBER_OF_SEGMENTS-1 then
                        segment<=0;
                    end if;    
                end if;
                
                --valid (based on coarse delay):
                start         := local_dout(c_FIFO1_WIDTH-1);
                segment_valid := unsigned(local_dout(c_FIFO1_WIDTH-2 downto c_FIFO1_WIDTH-(c_COARSE_DELAY_ONE_CYCLE_POS+1)));
                if i_hbm_clk_rst='1'or local_full='1' or local_empty='1' then
                    local_we <= '0';
                elsif (start='1' and to_unsigned(segment, c_COARSE_DELAY_ONE_CYCLE_POS)>=segment_valid) or
                      (start='0' and to_unsigned(segment, c_COARSE_DELAY_ONE_CYCLE_POS)<=segment_valid) then
                    local_we <= '1';
                else
                    local_we <= '0';
                end if;
                
                --packet valid (or missing/RFI):
                local_din(c_FIFO2_WIDTH-1) <= local_dout(c_FIFO1_WIDTH-(c_COARSE_DELAY_ONE_CYCLE_POS+1)-2);
                
                --coarse delay value:
                local_coarse_delay    <= local_dout(c_FIFO1_WIDTH-(c_COARSE_DELAY_ONE_CYCLE_POS+1)-3 downto c_FIFO1_WIDTH-(c_COARSE_DELAY_ONE_CYCLE_POS+1)-2-c_COARSE_DELAY_WIDTH);
                if (local_dout(c_FIFO1_WIDTH-(c_COARSE_DELAY_ONE_CYCLE_POS+1)-1) and local_re) = '1' then
                    --Only write every second coarse_delay value, since we get two per output block (output block size = 2 * input block size)
                    local_coarse_delay_we <= second_coarse_delay_we;
                    second_coarse_delay_we <= not second_coarse_delay_we;
                else    
                    local_coarse_delay_we <= '0';
                end if;    
                
                --data:
                local_din(c_DUAL_POL_WIDTH-1 downto 0) <= local_dout(c_DUAL_POL_WIDTH*(segment+1)-1 downto c_DUAL_POL_WIDTH*segment);
                
                --meta:
                if THIS_IS_SIMULATION then
                    local_din(2*c_META_WIDTH-1+c_DUAL_POL_WIDTH downto c_DUAL_POL_WIDTH) <= local_dout(2*c_META_WIDTH*(segment+1)-1+c_HBM_WIDTH downto 2*c_META_WIDTH*segment+c_HBM_WIDTH);
                    meta :=  slv_to_meta(local_dout(2*c_META_WIDTH*(segment+1)-1+c_HBM_WIDTH downto 2*c_META_WIDTH*segment+c_HBM_WIDTH));
                end if;     
            end if;
        end process;    

        E_FIFO2 : xpm_fifo_async
        generic map (
            DOUT_RESET_VALUE    => "0",
            ECC_MODE            => "no_ecc",
            FIFO_MEMORY_TYPE    => "block",
            FIFO_READ_LATENCY   => 0,
            FIFO_WRITE_DEPTH    => g_FIFO2_DEPTH,
            FULL_RESET_VALUE    => 1,
            PROG_EMPTY_THRESH   => g_OUTPUT_PACKET_LEN,
            PROG_FULL_THRESH    => g_FIFO2_DEPTH-10,     
            RD_DATA_COUNT_WIDTH => log2_ceil(g_FIFO2_DEPTH),
            READ_DATA_WIDTH     => c_FIFO2_WIDTH,
            READ_MODE           => "fwft",
            USE_ADV_FEATURES    => "0002",       --prog full
            WAKEUP_TIME         => 0,
            WRITE_DATA_WIDTH    => c_FIFO2_WIDTH,
            WR_DATA_COUNT_WIDTH => log2_ceil(g_FIFO2_DEPTH)
        ) port map (
            --di
            wr_clk        => i_hbm_clk,
            rst           => i_hbm_clk_rst,
            din           => local_din,
            wr_en         => local_we,
            prog_full     => local_full,
            --do
            rd_clk        => i_output_clk,
            dout          => dout(fifo),
            rd_en         => rd_en,
            empty         => empty(fifo),
            --unused
            sleep         => '0', 
            injectdbiterr => '0',
            injectsbiterr => '0'
        );    
        
        E_FIFO_COARSE_DELAY : xpm_fifo_async
        generic map (
            DOUT_RESET_VALUE    => "0",
            ECC_MODE            => "no_ecc",
            FIFO_MEMORY_TYPE    => "auto",
            FIFO_READ_LATENCY   => 0,
            FIFO_WRITE_DEPTH    => 16,
            FULL_RESET_VALUE    => 1,
            PROG_EMPTY_THRESH   => 5,
            PROG_FULL_THRESH    => 5,     
            RD_DATA_COUNT_WIDTH => log2_ceil(16),
            READ_DATA_WIDTH     => c_COARSE_DELAY_WIDTH,
            READ_MODE           => "fwft",
            USE_ADV_FEATURES    => "0000",
            WAKEUP_TIME         => 0,
            WRITE_DATA_WIDTH    => c_COARSE_DELAY_WIDTH,
            WR_DATA_COUNT_WIDTH => log2_ceil(16)
        ) port map (
            --di
            wr_clk        => i_hbm_clk,
            rst           => i_hbm_clk_rst,
            din           => local_coarse_delay,
            wr_en         => local_coarse_delay_we,
            full          => local_coarse_delay_full,
            --do
            rd_clk        => i_output_clk,
            dout          => out_coarse_delay(fifo),
            rd_en         => coarse_delay_re,
            empty         => coarse_delay_empty(fifo),
            --unused
            sleep         => '0', 
            injectdbiterr => '0',
            injectsbiterr => '0'
        );
                
        error_coarse_delay_fifo_overflow(fifo) <= local_coarse_delay_full and local_coarse_delay_we;
        assert error_coarse_delay_fifo_overflow(fifo)/='1' report "Coarse Delay FIFO overflow!" severity FAILURE; 
        
        assert g_INPUT_PACKET_LEN*8*2=g_OUTPUT_PACKET_LEN report "Assumption: two input blocks = one output block. If not, change code here." severity FAILURE; 

    end generate;
    
    
    ------------------------------------------------------------------------
    -- DATA OUT:
    -- All output ports are synchronous in regard to data_valid.
    -- Output is timed (setup via MACE).
    ------------------------------------------------------------------------
    P_OUTPUT_TIME: process (i_output_clk)
    begin
        if rising_edge(i_output_clk) then

            o_error_ctc_underflow <= output_trigger and not rd_en;        

            if i_output_clk_rst ='1' then
                cycle_counter  <= (others => '0');
                output_trigger <= '0';
                wait_for_start <= '1';
                o_error_output_aligment_loss <= '0';
                my_enable_timed_output <= i_enable_timed_output;
                my_update      <= '0';
            else
                if i_out_config_update='1' then
                    my_update<='1';
                end if;
                if my_update='1' and out_packet_count_raw>=unsigned(i_out_config_start_ts) then
                    wait_for_start<='1';
                    my_update     <='0';
                end if;
                if (wait_for_start='1' and i_output_clk_wall_time >= i_config_start_wt) then 
                    wait_for_start <= '0';
                    my_update      <= '0';
                    output_trigger <= '1';
                    cycle_counter  <= unsigned(i_config_output_cycles);
                elsif wait_for_start='0' then     
                    if cycle_counter=0 then
                        cycle_counter  <= unsigned(i_config_output_cycles);
                        o_error_output_aligment_loss <= output_trigger and not rd_en;
                        output_trigger <= '1';
                    else
                        cycle_counter <= cycle_counter - 1;
                        if rd_en='1' then
                            output_trigger <= '0';                                        
                        end if;
                    end if;
                end if;
            end if;

            if my_enable_timed_output='0' then
                output_trigger               <= '1';
                o_error_output_aligment_loss <= '0';
                o_error_ctc_underflow        <= '0';
            end if;
        end if;
    end process;


    rd_en <= '1' when i_data_out_stop='0' and ((OR(coarse_delay_empty)='0' and (OR(coarse_delay_delta_empty)='0') and output_trigger='1') or out_running='1') else '0';
    

    P_DATA_OUTPUT: process (i_output_clk)
        variable meta : t_ctc_meta_a(1 downto 0);
    begin
        if rising_edge(i_output_clk) then
            
            --defaults:
            o_data_out_vld  <= rd_en;
            coarse_delay_re <= '0';
            
            if i_output_clk_rst='1' then
                out_running <= '0';
                out_counter <= (others => '0');
            elsif rd_en='1' then
                out_counter <= out_counter + 1;
                out_running <= '1';
                if out_counter=g_OUTPUT_PACKET_LEN-1 then
                    out_counter     <= (others =>'0');
                    out_running     <= '0';
                end if;
                if out_counter=1 then 
                    coarse_delay_re <= '1';
                end if;    
            end if;          
            
            for out_port in 0 to pc_CTC_OUTPUT_NUMBER-1 loop

                --packet valid (not missing/RFI):
                o_packet_vld(out_port) <= dout(out_port)(c_FIFO2_WIDTH-1);
                
                --data:
                o_data_out(out_port).data.hpol <= slv_to_payload(dout(out_port)(c_DUAL_POL_WIDTH-1 downto 0), 0);
                o_data_out(out_port).data.vpol <= slv_to_payload(dout(out_port)(c_DUAL_POL_WIDTH-1 downto 0), 1);
                
                --meta:
                if THIS_IS_SIMULATION then
                    meta := slv_to_meta(dout(out_port)(c_FIFO2_WIDTH-2 downto c_DUAL_POL_WIDTH));
                    o_data_out(out_port).meta(0) <= meta(0); 
                    o_data_out(out_port).meta(1) <= meta(1);
                end if;     
            end loop;
        end if;
    end process;    
    

    ------------------------------------------------------------------------
    -- HEADER OUT:
    -- This is the output packet metadata used in post-synthesis.
    -- Most of it is recreated here, because that is way more efficient
    -- than transporting it through all the FIFOs. This is possible
    -- because the output scheme is fix.
    ------------------------------------------------------------------------
    P_HEADER_DATA_OUT: process(i_output_clk)
    begin
        if rising_edge(i_output_clk) then
            
            o_start_of_frame <= '0';
            o_header_out_vld <= '0';
            
            if i_output_clk_rst='1' then
                out_inner_packet_count <= (others => '0');
                out_packet_count_raw   <= unsigned(i_out_config_start_ts);
                out_virtual_channel    <= (others => '0');
                out_station            <= (others => '0');
            else
            
                if out_counter=0 and rd_en='1' then
                    if out_inner_packet_count=0 then
                        o_start_of_frame <= '1';
                    end if;    
                     
                    if out_inner_packet_count < g_OUTPUT_TIME_COUNT+g_OUTPUT_PRELOAD-1 then
                        out_inner_packet_count <= out_inner_packet_count + 1;
                    else   
                        out_inner_packet_count <= (others=>'0');
                        if out_station < pc_STATION_NUMBER/g_STATION_GROUP_SIZE-1 then
                            out_station <= out_station + 1;
                        else
                            out_station <= (others => '0');
                            if out_virtual_channel < g_COARSE_CHANNELS-1 then
                                out_virtual_channel <= out_virtual_channel + 1;
                            else
                                out_virtual_channel  <= (others => '0');
                                out_packet_count_raw <= out_packet_count_raw + g_INPUT_TIME_COUNT;
                            end if;
                        end if;
                    end if;
                end if;
                
                if out_counter=0 and rd_en='1' then
                    for out_port in 0 to pc_CTC_OUTPUT_NUMBER-1 loop
                        o_header_out(out_port).timestamp        <= std_logic_vector(to_unsigned(to_integer(out_packet_count_raw*g_INPUT_BLOCK_SIZE) + to_integer(unsigned(out_coarse_delay(out_port))), o_header_out(out_port).timestamp'length));
                        o_header_out(out_port).coarse_delay     <= out_coarse_delay(out_port);
                        o_header_out(out_port).virtual_channel  <= std_logic_vector(out_virtual_channel);
                        o_header_out(out_port).station_id       <= std_logic_vector(to_unsigned(g_STATION_GROUP_SIZE*to_integer(out_station) + (out_port), 9));
                        o_header_out(out_port).hpol_phase_shift <= out_coarse_delay_delta(out_port)(15 downto 00);
                        o_header_out(out_port).vpol_phase_shift <= out_coarse_delay_delta(out_port)(31 downto 16);
                        o_header_out_vld <= '1';
                    end loop;    
                end if;
            end if;            
        end if;
    end process;    
        
        
end Behavioral;
