---------------------------------------------------------------------------------------------------
-- 
-- INPUT BUFFER
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert_abel@gmx.net)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- This module separates the header from the payload.
-- It then does a CDC to hbm_clk.
--
-- The header data is used downstream to create HBM addresses.
-- The payload is written to the HBM data port.
-- Based on the used AXI4 interface, the two streams are completely independent
-- (they eventually come together in the integrated HBM design).
------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.ctc_pkg.all;

Library xpm;
use xpm.vcomponents.all;

entity ctc_input_buffer is
    generic(
        g_USE_DATA_IN_STOP   : boolean := FALSE;
        g_FPGA_COUNT         : integer := 3;
        g_HBM_BURST_LEN      : integer range 4 to 16 := 16;
        g_INPUT_BLOCK_SIZE   : integer := 2048;
        g_INPUT_STOP_WORDS   : integer := 10;
        g_USE_DATA_IN_RECORD  : boolean
    );
    port (
        i_hbm_clk        : in  std_logic;
        i_hbm_clk_rst    : in  std_logic;
        i_input_clk      : in  std_logic;
        i_input_clk_rst  : in  std_logic;
        --config in:
        i_config_update       : in std_logic;
        i_enable_timed_input  : in std_logic;
        i_input_clk_wall_time : in t_wall_time;
        i_config_prime_wt     : in t_wall_time; 
        i_config_start_ts     : in std_logic_vector(31 downto 0);
        i_config_input_cycles : in std_logic_vector(31 downto 0);
        o_min_packet_seen       : out std_logic;                      --the minimum packet has been seen
        o_max_packet_reached    : out std_logic;                      --the maximum packet has been reached
        i_input_end_ts          : in  std_logic_vector(31 downto 0);  --maximum packet count - filter packets higher than this            
        --data in:
        i_data_in_record  : in  t_ctc_input_data := (others => pc_CTC_DATA_ZERO); --FOR SIMULATION ONLY!
        i_data_in         : in  std_logic_vector(pc_CTC_INPUT_WIDTH-1 downto 0);
        i_data_in_vld     : in  std_logic;
        i_data_in_sop     : in  std_logic;
        o_data_in_stop    : out std_logic;  
        --data out:
        o_data_out       : out t_ctc_hbm_data;
        o_data_out_vld   : out std_logic;
        i_data_out_rdy   : in  std_logic;  
        --header out:
        o_dummy_header   : out std_logic;
        o_header_out     : out t_ctc_input_header;
        o_header_out_vld : out std_logic;
        i_header_out_rdy : in  std_logic;
        --error out (in input_clk):
        o_error_input_buffer_full     : out std_logic;
        o_error_input_buffer_overflow : out std_logic
    );
end ctc_input_buffer;

architecture Behavioral of ctc_input_buffer is

    constant c_INPUT_BLOCK_LENGTH_64  : integer := g_INPUT_BLOCK_SIZE/pc_CTC_INPUT_TS_NUM;
    constant c_INPUT_BLOCK_LENGTH_256 : integer := c_INPUT_BLOCK_LENGTH_64/4;
    
    constant c_FIFO_DEPTH       : integer := sel(g_USE_DATA_IN_STOP, 512, 2*g_INPUT_BLOCK_SIZE);                               
    constant c_FIFO_DEPTH_LOG2  : integer := log2_ceil(c_FIFO_DEPTH);
    constant c_PROG_FULL        : integer := sel(g_USE_DATA_IN_STOP, c_FIFO_DEPTH-g_INPUT_STOP_WORDS-5, c_FIFO_DEPTH-g_INPUT_BLOCK_SIZE-5);
    
    constant c_HBM_WIDTH       : integer := 256;                     --fix for this design
    constant c_FIFO_WIDTH_64   : integer := c_HBM_WIDTH/4;
    constant c_FIFO_WIDTH_256  : integer := c_HBM_WIDTH; 

    signal dout        : std_logic_vector(c_FIFO_WIDTH_256-1 downto 0);
    signal mout        : std_logic_vector(pc_CTC_META_WIDTH*16-1 downto 0);
    signal empty       : std_logic;
   
    signal out_header_empty  : std_logic;
    signal out_header        : t_ctc_input_header;
    signal out_dummy_header  : std_logic;
    
    signal wr_rst_busy : std_logic;
    signal rd_rst_busy : std_logic;
    
    signal my_update             : std_logic;
    signal my_enable_timed_input : std_logic;
    signal my_config_start_ts    : std_logic_vector(31 downto 0);

begin

    assert c_INPUT_BLOCK_LENGTH_256 rem g_HBM_BURST_LEN = 0 report "c_INPUT_BLOCK_LENGTH_256 has to be a multiple of g_HBM_BURST_LEN!" severity FAILURE;
    
    GEN_INPUT_BUFFER: if true generate
        type t_input_state is (s_WAITING, s_HEADER_1, s_HEADER_2, s_DATA);
        signal input_state     : t_input_state;
        signal header_slv      : std_logic_vector(127 downto 0) := (others => '0');
        signal in_packet_count : unsigned(log2_ceil(c_INPUT_BLOCK_LENGTH_64)-1 downto 0);
        signal dummy_header    : std_logic;
        
        signal din         : std_logic_vector(c_FIFO_WIDTH_64-1 downto 0);
        signal wr_en       : std_logic;
        signal prog_full   : std_logic;
        signal full        : std_logic;
        signal h_full      : std_logic;
        signal h_prog_full : std_logic;
        
        signal in_header         : t_ctc_input_header;
        signal in_header_we      : std_logic :='0';
        signal header_dout       : std_logic_vector(pc_CTC_HEADER_WIDTH downto 0);
        
        signal cycle_counter      : unsigned(31 downto 0);
        signal dummy_packet_count : unsigned(31 downto 0);
        signal wait_for_start     : std_logic;
        signal trigger_dummy      : std_logic;
        signal highest_ts         : unsigned(31 downto 0);

    begin


        ---------------------------------------------------------------------------------------------------
        -- TIMED INPUT
        --
        -- This process creates dummy packets that are used to keep the CTC ticking along, even
        -- if there is no data from any of the stations.
        -- They cause the write address manager to keep going (in time), but result in no actual HBM access.
        ---------------------------------------------------------------------------------------------------
        P_INPUT_TIME: process (i_input_clk)
        begin
            if rising_edge(i_input_clk) then

                --default:
                trigger_dummy <= '0';

                if i_input_clk_rst ='1' then
                    cycle_counter  <= (others => '0');
                    wait_for_start <= '1';
                    dummy_packet_count <= (others => '0');
                    my_enable_timed_input <= i_enable_timed_input;
                    my_update <= '0';
                else
                    if i_config_update='1' then
                        my_update<='1';
                    end if;
                    if my_update='1' and i_input_clk_wall_time >= i_config_prime_wt then
                        wait_for_start <= '1';
                        my_update      <= '0';
                    end if;    
                    if wait_for_start='0' then
                        if cycle_counter=0 then
                            cycle_counter      <= unsigned(i_config_input_cycles);
                            dummy_packet_count <= dummy_packet_count + 1;
                            trigger_dummy      <= '1';
                        else
                            cycle_counter <= cycle_counter - 1;
                        end if;
                    else
                        if i_input_clk_wall_time >= i_config_prime_wt and my_enable_timed_input='1' then
                            wait_for_start     <= '0';
                            cycle_counter      <= unsigned(i_config_input_cycles);
                            dummy_packet_count <= unsigned(i_config_start_ts);
                            trigger_dummy      <= '1'; 
                        end if;   
                    end if;
                end if;
            end if;
        end process;


        ---------------------------------------------------------------------------------------------------
        -- EXTRACT HEADER
        --
        -- The first two words of a package are actually header data.
        -- This is extracted here.
        -- We also wait for the packet count ts in the extracted header to be >= i_config_start_ts
        ---------------------------------------------------------------------------------------------------
        P_INPUT_STATE: process (i_input_clk)
        begin
            if rising_edge(i_input_clk) then
                
                --defaults:
                in_header_we <= '0';
                dummy_header <= '0';
                o_error_input_buffer_full     <= '0';
                o_error_input_buffer_overflow <= '0';
                
                if i_input_clk_rst='1' then
                    input_state          <= s_WAITING;
                    in_packet_count      <= (others => '0');
                    my_config_start_ts   <= i_config_start_ts;
                    highest_ts           <= (others => '0');
                    o_min_packet_seen    <= '0';
                    o_max_packet_reached <= '0';
                else
                    case input_state is
                    
                    --wait for minimum packet_count per station
                    when s_WAITING  | s_HEADER_1 =>
                        if (input_state=s_WAITING  and i_data_in_vld='1' and i_data_in_sop='1')
                        or (input_state=s_HEADER_1 and i_data_in_vld='1') then
                            assert i_data_in_sop='1' report "Input data misalignment. SOP missing." severity FAILURE;
                            if i_data_in(58 downto 27)=i_input_end_ts and (OR(i_input_end_ts)/='0') then
                                o_max_packet_reached <= '1';
                            end if;
                            if my_config_start_ts <= i_data_in(58 downto 27) and (OR(i_input_end_ts)='0' or i_data_in(58 downto 27) <= i_input_end_ts) then
                                o_min_packet_seen         <= '1';
                                o_error_input_buffer_full <= prog_full;
                                if (prog_full='0' or g_USE_DATA_IN_STOP=TRUE) then
                                    header_slv(63 downto 0) <= i_data_in;
                                    input_state <= s_HEADER_2;
                                else    
                                    assert g_USE_DATA_IN_STOP=TRUE report "Skipping input packet because input FIFO is full!" severity WARNING;
                                    input_state <= s_WAITING;
                                    --DUMMY HEADER to keep the CTC running, even if FIFO is full
                                    in_header.virtual_channel <= (others => '0');
                                    in_header.station_id      <= (others => '0');
                                    in_header.packet_count    <= slv_to_header(X"0000000000000000" & i_data_in).packet_count; 
                                    if unsigned(slv_to_header(X"0000000000000000" & i_data_in).packet_count) > highest_ts then
                                        if h_prog_full='0' then
                                            in_header_we  <= '1';
                                            dummy_header  <= '1';
                                            highest_ts    <= unsigned(slv_to_header(X"0000000000000000" & i_data_in).packet_count);
                                        else
                                            o_error_input_buffer_overflow <= '1';
                                        end if;         
                                    end if;    
                                end if;
                            else
                                input_state <= s_WAITING;
                            end if;
                        elsif trigger_dummy='1' and o_max_packet_reached='0' then
                            --DUMMY HEADER to keep the CTC running, even if all stations are AWOL
                            in_header.virtual_channel <= (others => '0');
                            in_header.station_id      <= (others => '0');
                            in_header.packet_count    <= std_logic_vector(dummy_packet_count);
                            if dummy_packet_count>highest_ts then
                                if h_prog_full='0' then
                                    in_header_we              <= '1';
                                    dummy_header              <= '1';
                                else
                                    o_error_input_buffer_overflow <= '1';
                                end if;    
                                if dummy_packet_count > highest_ts then
                                    highest_ts <= dummy_packet_count;
                                end if;
                            end if;    
                        end if;
                    
                    when s_HEADER_2 =>
                        if i_data_in_vld='1' then
                            input_state     <= s_DATA;
                            in_header <= slv_to_header(i_data_in & header_slv(63 downto 0));
                            --devide channel by number of FPGAs:
                            in_header.virtual_channel <= std_logic_vector(unsigned(header_slv(8 downto 0))/g_FPGA_COUNT);
                            in_header_we <= '1';  --write the header at the START of a packet
                            if unsigned(slv_to_header(i_data_in & header_slv(63 downto 0)).packet_count) > highest_ts then
                                highest_ts <= unsigned(slv_to_header(i_data_in & header_slv(63 downto 0)).packet_count);
                            end if;    
                        end if;
                    
                    when s_DATA   =>
                        if i_data_in_vld='1' then
                            in_packet_count <= in_packet_count + 1;
                            if in_packet_count=c_INPUT_BLOCK_LENGTH_64-1 then
                                in_packet_count <= (others=>'0');
                                input_state     <= s_HEADER_1;
                            end if;                          
                            assert ((not g_USE_DATA_IN_RECORD) or (i_data_in = payload_to_slv(i_data_in_record))) report "Input data on record and slv differ!" severity FAILURE;
                            assert i_data_in_sop='0' report "Input data misalignment. Unexpected SOP." severity FAILURE;
                        end if;                        
                    end case;
                end if;         
            end if;
        end process;
        
        GEN_META_FIFO: if THIS_IS_SIMULATION generate
            signal min     : std_logic_vector(pc_CTC_META_WIDTH*4-1 downto 0);
            signal m_empty : std_logic;
            signal m_full  : std_logic;
        begin

            min <= meta_to_slv(i_data_in_record(3).meta)
                 & meta_to_slv(i_data_in_record(2).meta) 
                 & meta_to_slv(i_data_in_record(1).meta) 
                 & meta_to_slv(i_data_in_record(0).meta);

            E_META_FIFO : xpm_fifo_async
            generic map (
                DOUT_RESET_VALUE    => "0",
                ECC_MODE            => "no_ecc",
                FIFO_MEMORY_TYPE    => "block",
                FIFO_READ_LATENCY   => 0,
                FIFO_WRITE_DEPTH    => c_FIFO_DEPTH,
                FULL_RESET_VALUE    => 1,
                PROG_EMPTY_THRESH   => 10,
                PROG_FULL_THRESH    => 10,     
                RD_DATA_COUNT_WIDTH => log2_ceil(c_FIFO_DEPTH/4),
                READ_DATA_WIDTH     => pc_CTC_META_WIDTH*16,
                READ_MODE           => "fwft",
                USE_ADV_FEATURES    => "0000",
                WAKEUP_TIME         => 0,
                WRITE_DATA_WIDTH    => pc_CTC_META_WIDTH*4,
                WR_DATA_COUNT_WIDTH => log2_ceil(c_FIFO_DEPTH)
            ) port map (
                --di
                wr_clk        => i_input_clk,
                rst           => i_input_clk_rst,
                din           => min,
                wr_en         => wr_en,
                full          => m_full,
                --do
                rd_clk        => i_hbm_clk,
                dout          => mout,
                rd_en         => not empty and i_data_out_rdy,
                empty         => m_empty,
                --unused
                sleep         => '0', 
                injectdbiterr => '0',
                injectsbiterr => '0'
            );    
    
            assert m_empty/='1' or (not empty and i_data_out_rdy)/='1' report "Meta FIFO underflow!" severity FAILURE;
            assert m_full/='1' or wr_en/='1' report "Meta FIFO overflow!" severity FAILURE;
    
        end generate;    
       
        
        din <= i_data_in;
        
        wr_en <= i_data_in_vld when input_state=s_DATA else '0';
        
        assert full/='1' or wr_en/='1' report "INPUT FIFO OVERFLOW!" severity FAILURE;
        
        E_DATA_FIFO : xpm_fifo_async
        generic map (
            DOUT_RESET_VALUE    => "0",
            ECC_MODE            => "no_ecc",
            FIFO_MEMORY_TYPE    => "block",
            FIFO_READ_LATENCY   => 0,
            FIFO_WRITE_DEPTH    => c_FIFO_DEPTH,
            FULL_RESET_VALUE    => 1,
            PROG_EMPTY_THRESH   => 10,
            PROG_FULL_THRESH    => c_PROG_FULL,     
            RD_DATA_COUNT_WIDTH => log2_ceil(c_FIFO_DEPTH/4),
            READ_DATA_WIDTH     => c_FIFO_WIDTH_256,
            READ_MODE           => "fwft",
            USE_ADV_FEATURES    => "0002",       --prog_full activated
            WAKEUP_TIME         => 0,
            WRITE_DATA_WIDTH    => c_FIFO_WIDTH_64,
            WR_DATA_COUNT_WIDTH => log2_ceil(c_FIFO_DEPTH)
        ) port map (
            --di
            wr_clk        => i_input_clk,
            rst           => i_input_clk_rst,
            wr_rst_busy   => wr_rst_busy,
            din           => din,
            wr_en         => wr_en,
            prog_full     => prog_full,
            full          => full,
            --do
            rd_clk        => i_hbm_clk,
            rd_rst_busy   => rd_rst_busy,
            dout          => dout,
            rd_en         => not empty and i_data_out_rdy,
            empty         => empty,
            --unused
            sleep         => '0', 
            injectdbiterr => '0',
            injectsbiterr => '0'
        ); 
        
        o_data_in_stop            <= wr_rst_busy or prog_full or i_input_clk_rst when g_USE_DATA_IN_STOP=TRUE else '0';   
        
        assert h_full/='1' or in_header_we/='1' report "HEADER FIFO OVERFLOW!" severity FAILURE;
        
        E_HEADER_FIFO : xpm_fifo_async
        generic map (
            DOUT_RESET_VALUE    => "0",
            ECC_MODE            => "no_ecc",
            FIFO_MEMORY_TYPE    => "distributed",
            FIFO_READ_LATENCY   => 0,
            FIFO_WRITE_DEPTH    => 16,
            FULL_RESET_VALUE    => 1,
            PROG_EMPTY_THRESH   => 10,
            PROG_FULL_THRESH    => 7,     
            RD_DATA_COUNT_WIDTH => log2_ceil(16),
            READ_DATA_WIDTH     => pc_CTC_HEADER_WIDTH+1,
            READ_MODE           => "fwft",
            USE_ADV_FEATURES    => "0002",       --prog_full activated
            WAKEUP_TIME         => 0,
            WRITE_DATA_WIDTH    => pc_CTC_HEADER_WIDTH+1,
            WR_DATA_COUNT_WIDTH => log2_ceil(16)
        ) port map (
            --di
            wr_clk        => i_input_clk,
            rst           => i_input_clk_rst,
            din           => dummy_header & header_to_slv(in_header),
            wr_en         => in_header_we,
            full          => h_full,
            prog_full     => h_prog_full,
            --do
            rd_clk        => i_hbm_clk,
            dout          => header_dout,
            rd_en         => not out_header_empty and i_header_out_rdy,
            empty         => out_header_empty,
            --unused
            sleep         => '0', 
            injectdbiterr => '0',
            injectsbiterr => '0'
        );    
        
        out_header        <= slv_to_header(header_dout(pc_CTC_HEADER_WIDTH-1 downto 0));
        out_dummy_header  <= header_dout(pc_CTC_HEADER_WIDTH);
        
    end generate;

    o_dummy_header   <= out_dummy_header;
    o_header_out     <= out_header;
    o_header_out_vld <= not out_header_empty;
    
    o_data_out_vld <= not empty;
    o_data_out.data <= dout;
    GEN_META: if THIS_IS_SIMULATION generate
        GEN_METAS: for idx in 0 to 15 generate
            o_data_out.meta(idx) <= slv_to_meta(mout((idx+1)*pc_CTC_META_WIDTH-1 downto idx*pc_CTC_META_WIDTH)); 
        end generate;
    end generate;

end Behavioral;
