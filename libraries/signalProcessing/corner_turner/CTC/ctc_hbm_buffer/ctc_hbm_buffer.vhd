---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Coarse (CTC) - HBM Main Buffer
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert_abel@gmx.net)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- The basic structure of the Coarse Corner Turner is as follows:
-- => INPUT_BUFFER => HBM_BUFFER => OUTPUT_BUFFER =>
--
-- This module performs the actual corner turn
--
-- We get two input streams: data & header
-- Based on the used AXI4 interface, they are completely independent.
-- + the data stream contains the actual payload
-- + the header stream contains the packet information required to calculate the correct address
--
-- Address calculation happens the Address Managers
-- (one for read, one for write)
-- This is where the actual magic happens.
-- 
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

Library xpm;
use xpm.vcomponents.all;

library axi4_lib;
use axi4_lib.axi4_full_pkg.all;

use work.ctc_pkg.all;

entity ctc_hbm_buffer is
    Generic (
        g_USE_HBM             : boolean;
        g_HBM_EMU_STUTTER     : boolean;
        g_ATOM_SIZE           : integer range 1 to 16 := 16;
        g_INPUT_TIME_COUNT    : integer := 204*2;
        --
        g_INPUT_BLOCK_SIZE    : integer := 2048/8;     --in 256 bit words              
        g_OUTPUT_BLOCK_SIZE   : integer := 4096/8;     --in 256 bit words              
        g_STATION_GROUP_SIZE  : integer := 2;                    
        g_COARSE_CHANNELS     : integer := 128;
        g_AUX_WIDTH           : integer := 24; --unit: INPUT_TIME_COUNT
        g_WIDTH_PADDING       : integer := 26; --unit: INPUT_TIME_COUNT
        g_OUTPUT_PRELOAD      : integer := 11; --how many output blocks do we need to preload before the real data comes?
        g_MAXIMUM_DRIFT       : integer := 20; --unit: INPUT_TIME_COUNT
        g_COARSE_DELAY_OFFSET : integer := 2   --unit: INPUT_TIME_COUNT
    );
    Port (
        i_hbm_clk       : in  STD_LOGIC;
        i_hbm_rst       : in  STD_LOGIC;
        --config in:
        o_hbm_ready      : out std_logic;
        i_config_start_ts: in  std_logic_vector(31 downto 0);
        --data in:        
        i_data_in       : in  t_ctc_hbm_data;
        i_data_in_vld   : in  std_logic;
        o_data_in_rdy   : out std_logic;
        --header in (i.e. meta data used to determine the address):
        i_header_in     : in  t_ctc_input_header;
        i_dummy_header  : in  std_logic;
        i_header_in_vld : in  std_logic;
        o_header_in_rdy : out std_logic;
        --data out:
        o_data_out       : out t_ctc_hbm_data;
        o_data_out_vld   : out std_logic;
        o_block_vld      : out std_logic;
        i_data_out_stop  : in  std_logic;
        --debug out:
        o_debug_station_channel     : out std_logic_vector(9 downto 0);
        o_debug_station_channel_inc : out std_logic;
        o_debug_ctc_ra_cursor       : out std_logic_vector(15 downto 0) := (others => '0');
        o_debug_ctc_ra_phase        : out std_logic_vector(1 downto 0);
        o_debug_ctc_empty           : out std_logic;
        --error out: 
        o_error_ctc_full  : out std_logic;
        o_error_overwrite : out std_logic;
        o_error_too_late  : out std_logic;
        o_error_wa_fifo_full  : out std_logic;
        o_error_ra_fifo_full  : out std_logic;
        o_error_bv_fifo_full  : out std_logic;
        o_error_bv_fifo_underflow : out std_logic;
       --HBM INTERFACE
        o_hbm_mosi  : out t_axi4_full_mosi;
        i_hbm_miso  : in  t_axi4_full_miso;
        i_hbm_ready : in  std_logic
    );  
end ctc_hbm_buffer;

architecture Behavioral of ctc_hbm_buffer is

    --The names below are oriented on Phase 1
    
    constant g_OUTPUT_BLOCK_FACTOR : integer := g_OUTPUT_BLOCK_SIZE/g_INPUT_BLOCK_SIZE;                 --2
    constant g_OUTPUT_TIME_COUNT   : integer := g_INPUT_TIME_COUNT/g_OUTPUT_BLOCK_FACTOR;               --204
    
    constant g_STATION_NUMBER      : integer := pc_STATIONS_PER_PORT*pc_CTC_INPUT_NUMBER;                --6 
    
    constant g_MAIN_WIDTH          : integer := g_INPUT_TIME_COUNT-g_AUX_WIDTH;                         --384                                            
    constant g_MAIN_HEIGHT         : integer := g_COARSE_CHANNELS * g_STATION_NUMBER;                   --768

    constant g_HEIGHT_FACTOR       : integer := g_MAIN_HEIGHT/g_MAIN_WIDTH;                             --2
    constant g_HEIGHT_PADDING      : integer := g_WIDTH_PADDING * g_HEIGHT_FACTOR;                      --52
                   
    constant g_BUFFER_WIDTH        : integer := g_MAIN_WIDTH + g_WIDTH_PADDING;                         --410
    constant g_BUFFER_HEIGHT       : integer := g_MAIN_HEIGHT + g_HEIGHT_PADDING;                       --820
    
    constant g_MAIN_BUFFER_SIZE    : integer := g_BUFFER_WIDTH * g_BUFFER_HEIGHT * g_INPUT_BLOCK_SIZE;  --86,067,200

    constant g_AUX_HEIGHT          : integer := g_MAIN_HEIGHT;                                          --768
    constant c_AUX_NUMBER          : integer := 3;                                                      --3
    constant g_AUX_BUFFER_SIZE     : integer := g_AUX_HEIGHT * g_AUX_WIDTH * g_INPUT_BLOCK_SIZE;        --4,718,592
    
    constant g_OVERALL_SIZE           : integer := g_MAIN_BUFFER_SIZE + c_AUX_NUMBER*g_AUX_BUFFER_SIZE + 1; --100,222,977  ==(*256bit)==> 25,657,081,856 bit <=> 13 AXI interfaces (each 2Gb)
    constant g_OVERALL_SIZE_LOG2      : integer := log2_ceil(g_OVERALL_SIZE);                               --27 bit (256bit-word)-addressing <=> 32 bit byte-addressing on HBM
    constant g_OVERALL_SIZE_IN_BLOCKS : integer := (g_BUFFER_WIDTH*g_BUFFER_HEIGHT) + (c_AUX_NUMBER*g_AUX_HEIGHT*g_AUX_WIDTH);

    signal write_ready     : std_logic;
    signal wa_ready        : std_logic;
    signal ra_ready        : std_logic;
    
    signal write_enable    : std_logic;
    signal w_last          : std_logic;
    signal burst_count     : unsigned(log2_ceil(g_ATOM_SIZE)-1 downto 0);
        
    signal wa_valid        : std_logic;
    signal write_address   : std_logic_vector(g_OVERALL_SIZE_LOG2-1 downto 0); 
    
    signal ra_valid        : std_logic; 
    signal read_address    : std_logic_vector(g_OVERALL_SIZE_LOG2-1 downto 0); 
    
    signal w_ack           : std_logic;

    signal wait_for_aux_e  : std_logic;
    signal empty           : std_logic;
    signal full            : std_logic;
    signal ra_phase        : std_logic_vector(1 downto 0);
    signal wa_phase_low    : std_logic_vector(1 downto 0);
    signal wa_phase_high   : std_logic_vector(1 downto 0);
    signal wa_high_is_aux  : std_logic;
    
    signal ra_cursor       : unsigned(log2_ceil(2*g_OUTPUT_TIME_COUNT+g_WIDTH_PADDING)-1 downto 0);
    signal wa_cursor       : unsigned(log2_ceil(2*g_OUTPUT_TIME_COUNT+g_WIDTH_PADDING)-1 downto 0);
    
    signal ra_block_offset_vld : std_logic;
    signal ra_block_offset     : std_logic_vector (log2_ceil(g_OVERALL_SIZE_IN_BLOCKS)-1 downto 0);
    signal ra_block_clear      : std_logic;
    
    signal wa_block_offset_vld : std_logic;
    signal wa_block_offset     : std_logic_vector (log2_ceil(g_OVERALL_SIZE_IN_BLOCKS)-1 downto 0);
    signal wa_block_good       : std_logic;

    signal new_block           : std_logic;

    type t_integer_a is array(integer range<>) of integer; 
    signal ra_counter : t_integer_a(g_COARSE_CHANNELS*pc_STATION_NUMBER-1 downto 0) := (others => 0);
    signal station_channel     : std_logic_vector(9 downto 0);
    signal p_station_channel   : std_logic_vector(10 downto 0);
    signal station_channel_vld : std_logic;
    signal station_channel_aux : std_logic;
    
begin
    
    ----------------------------------------------------------------------------
    -- HBM memory
    ----------------------------------------------------------------------------
    o_hbm_ready <= write_ready and ra_ready and wa_ready;

    GEN_BUFFER: if true generate
    begin
    
        E_BUFFER: entity work.ctc_hbm_buffer_ram
        generic map(
           g_USE_HBM          => g_USE_HBM,
           g_HBM_EMU_STUTTER  => g_HBM_EMU_STUTTER,
           g_DEPTH            => g_OVERALL_SIZE,
           g_DEPTH_IN_BLOCKS  => g_OVERALL_SIZE_IN_BLOCKS,
           g_INPUT_BLOCK_SIZE => g_INPUT_BLOCK_SIZE, 
           g_BURST_LEN        => g_ATOM_SIZE
        ) port map (
           i_hbm_clk      => i_hbm_clk,
           i_hbm_rst      => i_hbm_rst,
           --ready:
           o_read_ready   => ra_ready,
           o_write_ready  => write_ready,
           o_wa_ready     => wa_ready,
           --block tracker:
           i_wa_block_offset     => wa_block_offset,
           i_wa_block_offset_vld => wa_block_offset_vld,
           i_wa_block_good       => wa_block_good,      
           i_ra_block_offset     => ra_block_offset,    
           i_ra_block_offset_vld => ra_block_offset_vld,
           i_ra_block_clear      => ra_block_clear,
           o_error_overwrite     => o_error_overwrite,
           o_error_wa_fifo_full  => o_error_wa_fifo_full, 
           o_error_ra_fifo_full  => o_error_ra_fifo_full, 
           o_error_bv_fifo_full  => o_error_bv_fifo_full,
           o_error_bv_fifo_underflow => o_error_bv_fifo_underflow, 
           o_new_block           => new_block,
           o_block_vld           => o_block_vld,
           --write:
           i_we           => write_enable,
           i_wa           => write_address,
           i_wae          => wa_valid,
           i_wid          => (others => '0'),
           o_w_ack        => w_ack,
           o_w_ack_id     => open,
           i_data_in      => i_data_in,
           i_last         => w_last,
           --read:
           i_re             => ra_valid,
           i_ra             => read_address,
           o_data_out_vld   => o_data_out_vld,
           o_data_out       => o_data_out,
           i_data_out_stop  => i_data_out_stop,
           --HBM INTERFACE:
           o_hbm_mosi  => o_hbm_mosi, 
           i_hbm_miso  => i_hbm_miso, 
           i_hbm_ready => i_hbm_ready
        );
    end generate;
         
         
    ----------------------------------------------------------------------------
    -- Write Data
    ----------------------------------------------------------------------------
    write_enable <= i_data_in_vld;
    w_last       <= '1' when write_enable='1' and burst_count=g_ATOM_SIZE-1 else '0';

    P_WRITE: process (i_hbm_clk)
    begin
        if rising_edge(i_hbm_clk) then
            if i_hbm_rst='1' then
                burst_count <= (others => '0');
            elsif write_enable='1' and write_ready='1' then
                burst_count <= burst_count + 1;
                if burst_count=g_ATOM_SIZE-1 then
                    burst_count <= (others => '0');
                end if;
            end if;
        end if;
    end process;


    ----------------------------------------------------------------------------
    -- Write Address
    --
    -- The write address depends on the header
    ----------------------------------------------------------------------------
    E_WRITE_ADDRESS_MANAGER: entity work.ctc_address_manager
    generic map(
        g_USE_CASE_IS_WRITE   => true,
        g_START_PHASE         => 0,
        g_ATOM_SIZE           => g_ATOM_SIZE,
        g_INPUT_BLOCK_SIZE    => g_INPUT_BLOCK_SIZE,             
        g_OUTPUT_BLOCK_SIZE   => g_OUTPUT_BLOCK_SIZE,              
        g_OUTPUT_TIME_COUNT   => g_OUTPUT_TIME_COUNT,
        g_STATION_GROUP_SIZE  => g_STATION_GROUP_SIZE,                    
        g_COARSE_CHANNELS     => g_COARSE_CHANNELS,
        g_AUX_WIDTH           => g_AUX_WIDTH,
        g_WIDTH_PADDING       => g_WIDTH_PADDING,
        g_OUTPUT_PRELOAD      => g_OUTPUT_PRELOAD,
        g_MAXIMUM_DRIFT       => g_MAXIMUM_DRIFT,
        g_COARSE_DELAY_OFFSET => g_COARSE_DELAY_OFFSET   
    ) port map (
        i_clk             => i_hbm_clk,
        i_rst             => i_hbm_rst,
        --header in (i.e. meta data used to determine the address):
        i_config_start_ts => i_config_start_ts,
        i_header_in       => i_header_in,
        i_dummy_header    => i_dummy_header,
        i_header_in_vld   => i_header_in_vld,
        o_header_in_rdy   => o_header_in_rdy,
        --block out:
        o_block_offset    => wa_block_offset,
        o_block_offset_vld=> wa_block_offset_vld,
        o_block_good      => wa_block_good,
        o_error_too_late  => o_error_too_late,
        --address out:
        o_address         => write_address,
        o_address_vld     => wa_valid,
        i_address_rdy     => wa_ready,
        i_address_stop    => full,
        --indicator out:
        o_phase_low       => wa_phase_low,
        o_phase_high      => wa_phase_high,
        o_high_is_aux     => wa_high_is_aux,
        o_cursor          => wa_cursor
    );   



    ----------------------------------------------------------------------------
    -- Empty & Full Logic
    --
    -- Reading of a Frame is only allowed if we are not writing
    -- to this Frame anymore.
    --
    -- This happens at pipeline stage p3 of the Address Managers.
    --
    -- The Address Managers deliver Cursors that serve as level indicators, 
    -- can be directly compared, and indicate how the read and write relate
    -- to each other.
    ----------------------------------------------------------------------------
    P_EMPTY: process (i_hbm_clk)
    begin
        if rising_edge(i_hbm_clk) then
            if i_hbm_rst='1' then
                empty <= '1';
                wait_for_aux_e <= '1';
            else
                if ra_phase/=wa_phase_low and wait_for_aux_e='0' then
                    empty<='0';
                else
                    empty<='1';
                end if;
                if wa_phase_low="01" then
                    wait_for_aux_e <= '0';
                end if;
            end if;                    
        end if;
    end process;


    P_FULL: process (i_hbm_clk)
    begin
        if rising_edge(i_hbm_clk) then
            if i_hbm_rst='1' then
                full <= '0';
            else
                if (wa_phase_high=std_logic_vector(unsigned(ra_phase)+1) and (ra_cursor-2=wa_cursor or ra_cursor-1=wa_cursor) and wa_high_is_aux='0') --this needs a distance of 2 to allow for fuzziness on the read and write side (that could happen simultaneously)
                or (wa_phase_high=std_logic_vector(unsigned(ra_phase)+2) and wa_cursor>=(g_WIDTH_PADDING-2)) then
                    full<='1';
                else    
                    full<='0';
                end if;
            end if;                    
        end if;
    end process;

    o_debug_ctc_ra_cursor(o_debug_ctc_ra_cursor'HIGH downto ra_cursor'high+1) <= (others => '0');
    o_debug_ctc_ra_cursor(ra_cursor'range) <= std_logic_vector(ra_cursor);
    o_debug_ctc_ra_phase <= ra_phase;
    o_debug_ctc_empty    <= empty;
    o_error_ctc_full     <= full;
    o_data_in_rdy        <= write_ready;

    ----------------------------------------------------------------------------
    -- Read Address
    --
    -- The addressing reflects the corner turn
    ----------------------------------------------------------------------------
    E_READ_ADDRESS_MANAGER: entity work.ctc_address_manager
    generic map(
        g_USE_CASE_IS_WRITE   => false,
        g_START_PHASE         => 1,
        g_ATOM_SIZE           => g_ATOM_SIZE,
        g_INPUT_BLOCK_SIZE    => g_INPUT_BLOCK_SIZE,             
        g_OUTPUT_BLOCK_SIZE   => g_OUTPUT_BLOCK_SIZE,              
        g_OUTPUT_TIME_COUNT   => g_OUTPUT_TIME_COUNT,
        g_STATION_GROUP_SIZE  => g_STATION_GROUP_SIZE,                    
        g_COARSE_CHANNELS     => g_COARSE_CHANNELS,
        g_AUX_WIDTH           => g_AUX_WIDTH,
        g_WIDTH_PADDING       => g_WIDTH_PADDING,
        g_OUTPUT_PRELOAD      => g_OUTPUT_PRELOAD,
        g_COARSE_DELAY_OFFSET => g_COARSE_DELAY_OFFSET   
    ) port map (
        i_clk           => i_hbm_clk,
        i_rst           => i_hbm_rst,
        --block out:
        o_block_offset     => ra_block_offset,
        o_block_offset_vld => ra_block_offset_vld,
        o_block_clear      => ra_block_clear,
        --address out:
        o_address       => read_address,
        o_address_vld   => ra_valid,
        i_address_rdy   => ra_ready,
        i_address_stop  => empty,
        --station/channel
        o_station_channel     => station_channel,
        o_station_channel_vld => station_channel_vld,
        o_station_channel_aux => station_channel_aux,
        --indicator out:
        o_phase_low     => ra_phase,
        o_cursor        => ra_cursor
    );   



    ----------------------------------------------------------------------------
    -- Read Output Counters
    --
    -- This counts the vld blocks for each station/channel combination
    ----------------------------------------------------------------------------
    E_STATION_CHANNEL_FIFO : xpm_fifo_sync
        generic map (
            DOUT_RESET_VALUE    => "0",
            ECC_MODE            => "no_ecc",
            FIFO_MEMORY_TYPE    => "auto",
            FIFO_READ_LATENCY   => 0,
            FIFO_WRITE_DEPTH    => 128,
            FULL_RESET_VALUE    => 1,
            PROG_EMPTY_THRESH   => 10,
            PROG_FULL_THRESH    => 7,     
            RD_DATA_COUNT_WIDTH => log2_ceil(128),
            READ_DATA_WIDTH     => 11,
            READ_MODE           => "fwft",
            USE_ADV_FEATURES    => "0000",
            WAKEUP_TIME         => 0,
            WRITE_DATA_WIDTH    => 11,
            WR_DATA_COUNT_WIDTH => log2_ceil(128)
        ) port map (
            --di
            wr_clk        => i_hbm_clk,
            rst           => i_hbm_rst,
            din           => station_channel_aux & station_channel,
            wr_en         => station_channel_vld,
            --do
            dout          => p_station_channel,
            rd_en         => new_block,
            --unused
            sleep         => '0', 
            injectdbiterr => '0',
            injectsbiterr => '0'
        );    
    
    P_RA_COUNTER: process (i_hbm_clk)
    begin
        if rising_edge(i_hbm_clk) then
            
            o_debug_station_channel_inc <= '0';
            
            if i_hbm_rst='1' then
                ra_counter        <= (others=>0);
            else
                if new_block='1' then
                    if o_block_vld='1' and p_station_channel(10)='0' then --new block but not preload or coarse_delay_offset
                        o_debug_station_channel     <= p_station_channel(9 downto 0);
                        o_debug_station_channel_inc <= '1';
                    end if; 
                end if;    
            end if;    
        end if;
    end process;

end Behavioral;
