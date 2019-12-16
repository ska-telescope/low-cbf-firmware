---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Coarse (CTC) - CONFIGURATION MODULE
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert_abel@gmx.net)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- This module is the interface between MACE and the CTC.
--
-- It manages clock domain crossings of config, debug and error signals.
-- It also has a reset FSM that releases the internal resets in a well-defined order.
-- Plus: it allows MACE to reset the design at any point in time. 
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

Library xpm;
use xpm.vcomponents.all;

Library axi4_lib;
USE axi4_lib.axi4_lite_pkg.ALL;

use work.ctc_pkg.all;
use work.ctc_config_reg_pkg.all;

entity ctc_config is
    Port ( 
        i_mace_clk                  : in  std_logic;
        i_mace_clk_rst              : in  std_logic;
        i_input_clk                 : in  std_logic;            
        o_input_clk_rst             : out std_logic;            
        i_hbm_clk                   : in  std_logic;
        o_hbm_clk_rst               : out std_logic;
        i_output_clk                : in  std_logic;            
        o_output_clk_rst            : out std_logic;
        
        --MACE:
        i_saxi_mosi                 : IN  t_axi4_lite_mosi;
        o_saxi_miso                 : OUT t_axi4_lite_miso;
        
        -- coarse delay (hbm_clk):
        i_coarse_delay_addr         : in  std_logic_vector(31 downto 0); -- coarse*STATIONS + station
        i_coarse_delay_addr_vld     : in  std_logic;
        o_coarse_delay_packet_count : out std_logic_vector(31 downto 0);
        o_coarse_delay_value        : out std_logic_vector(15 downto 0); -- valid data cycles
        o_coarse_delay_delta_hpol   : out std_logic_vector(15 downto 0);
        o_coarse_delay_delta_vpol   : out std_logic_vector(15 downto 0);
        o_coarse_delay_delta_delta  : out std_logic_vector(15 downto 0);        
        i_end_of_integration_period : in  std_logic;                     -- pulse
        i_curent_packet_count       : in  std_logic_vector(31 downto 0); -- packet count
        
        -- input buffer config (input_clk):
        o_input_update              : out std_logic;
        o_input_start_ts            : out std_logic_vector(31 downto 0); -- packet count
        o_input_prime_wt            : out t_wall_time;                   -- wall time
        o_input_cycles_per_packet   : out std_logic_vector(31 downto 0); -- clock cycles
        o_enable_timed_input        : out std_logic;                     -- boolean
        i_min_packet_seen           : in std_logic;                      --the minimum packet has been seen
        i_max_packet_reached        : in std_logic;                      --the maximum packet has been reached
        o_input_end_ts              : out std_logic_vector(31 downto 0); --maximum packet count - filter packets higher than this            
        
        -- hbm config (hbm_clk):
        o_hbm_update                : out std_logic;
        i_hbm_ready                 : in std_logic;                      -- boolean
        o_hbm_start_ts              : out std_logic_vector(31 downto 0); -- packet count - only change in rst
        
        -- output buffer config (output_clk):
        o_output_update             : out std_logic;
        o_output_start_ts           : out std_logic_vector(31 downto 0); -- packet count
        o_output_start_wt           : out t_wall_time;                   -- wall time
        o_output_cycles_per_packet  : out std_logic_vector(31 downto 0); -- clock cycles        
        o_enable_timed_output       : out std_logic;                     -- boolean
                        
        -- error (in input clk):
        i_error_input_buffer_full          : in std_logic;  --the INPUT buffer is going into full state (if everything runs smoothly this should not happen) -- this causes packet loss
        i_error_input_buffer_overflow      : in std_logic;  --INPUT_FIFO overflows because data has not been read out fast enough and we cannot send in more dummy headers to keep the CTC going

        -- error/debug (in hbm clk):
        i_debug_station_channel            : in std_logic_vector(9 downto 0);
        i_debug_station_channel_inc        : in std_logic;
        i_debug_ctc_ra_cursor              : in std_logic_vector(15 downto 0);
        i_debug_ctc_ra_phase               : in std_logic_vector(1 downto 0);
        i_debug_ctc_empty                  : in std_logic;
        i_error_ctc_full                   : in std_logic;  --the HBM buffer is going into full state (if everything runs smoothly this should not happen)
        i_error_overwrite                  : in std_logic;  --blocks have not been read and are overwritten (HBM read is too slow)
        i_error_too_late                   : in std_logic;  --blocks did get actively dropped due to being too late
        i_error_wa_fifo_full               : in std_logic;  --the wa_fifo in the block_tracker overflows: FAILURE! -- this should NEVER happen
        i_error_ra_fifo_full               : in std_logic;  --the ra_fifo in the block_tracker overflows: FAILURE! -- this should NEVER happen
        i_error_bv_fifo_full               : in std_logic;  --the fv_fifo in the block_tracker overflows: FAILURE! -- this should NEVER happen
        i_error_bv_fifo_underflow          : in std_logic; --the fv_fifo in the block_tracker underflows: FAILURE! -- HBM ra_ack comes too fast
        i_error_coarse_delay_fifo_overflow : in std_logic; --the coarse_delay fifo in the output_buffer overflows: FAILURE! -- this should NEVER happen
        i_error_dsp_overflow               : in std_logic_vector(3 downto 0); --the delta_P_coarse_out calculations had to cut used bits
        
        -- error (in output_clk):
        i_error_ctc_underflow              : in std_logic; --readout was triggered, but the data FIFO does not contain enough data to start output
        i_error_output_aligment_loss       : in std_logic  --underflow is so massive, that we miss a whole out packet
        
    );        
end ctc_config;

architecture Behavioral of ctc_config is

    signal mace_reset   : std_logic;
    signal mace_hbm_rst : std_logic;
    signal mace_out_rst : std_logic;
    signal mace_in_rst  : std_logic;

    signal hbm_ready    : std_logic;

    signal mace_enable_timed_input  : std_logic;
    signal mace_enable_timed_output : std_logic;

    signal mace_config_prime_wt      : t_wall_time;
    signal mace_config_input_cycles  : std_logic_vector(31 downto 0);
    
    signal mace_config_start_ts      : std_logic_vector(31 downto 0);
    signal mace_config_start_wt      : t_wall_time;
    signal mace_config_output_cycles : std_logic_vector(31 downto 0);

    signal mace_config_vld           : std_logic;

    signal SETUP_FIELDS_RW         : t_setup_rw;
    signal SETUP_FIELDS_RO         : t_setup_ro;
    
    signal TIMING_FIELDS_RW        : t_timing_rw;
    
    signal COARSE_DELAY_FIELDS_RW   : t_coarse_delay_rw;
    signal COARSE_DELAY_FIELDS_RO   : t_coarse_delay_ro;
    signal COARSE_DELAY_TABLE_0_IN  : t_coarse_delay_table_0_ram_in;
    signal COARSE_DELAY_TABLE_0_OUT : t_coarse_delay_table_0_ram_out;
    signal COARSE_DELAY_TABLE_1_IN  : t_coarse_delay_table_1_ram_in;
    signal COARSE_DELAY_TABLE_1_OUT : t_coarse_delay_table_1_ram_out;
    
    signal REPORT_FIELDS_RW      : t_report_rw;
    signal REPORT_FIELDS_RO      : t_report_ro;
    signal REPORT_FIELDS_RO_HOLD : t_report_ro;

    signal VALID_BLOCKS_FIELDS_RW	: t_valid_blocks_rw;
    signal VALID_BLOCKS_COUNT_IN	: t_valid_blocks_count_ram_in;
	signal VALID_BLOCKS_COUNT_OUT	: t_valid_blocks_count_ram_out;

begin
    
    ------------------------------------------------------------------------------------
    -- MACE
    ------------------------------------------------------------------------------------
    E_MACE_CONFIG: entity work.ctc_config_reg
    PORT MAP(
        MM_CLK  => i_mace_clk,
        MM_RST  => i_mace_clk_rst,
        SLA_IN  => i_saxi_mosi,
        SLA_OUT => o_saxi_miso,
        --setup
        SETUP_FIELDS_RW          => SETUP_FIELDS_RW,
        SETUP_FIELDS_RO          => SETUP_FIELDS_RO,
        --timing
        TIMING_FIELDS_RW         => TIMING_FIELDS_RW,
        --station/channel counter
        st_clk_valid_blocks(0)   => i_hbm_clk,
        st_rst_valid_blocks(0)   => '0',
        VALID_BLOCKS_FIELDS_RW	 => VALID_BLOCKS_FIELDS_RW,
		VALID_BLOCKS_COUNT_IN	 => VALID_BLOCKS_COUNT_IN,
		VALID_BLOCKS_COUNT_OUT	 => VALID_BLOCKS_COUNT_OUT, 
        --coarse_delay
        st_clk_coarse_delay(0)   => i_hbm_clk,
        st_rst_coarse_delay(0)   => '0',
        COARSE_DELAY_FIELDS_RW   => COARSE_DELAY_FIELDS_RW,
        COARSE_DELAY_FIELDS_RO   => COARSE_DELAY_FIELDS_RO,
        COARSE_DELAY_TABLE_0_IN	 => COARSE_DELAY_TABLE_0_IN,
        COARSE_DELAY_TABLE_0_OUT => COARSE_DELAY_TABLE_0_OUT,
        COARSE_DELAY_TABLE_1_IN	 => COARSE_DELAY_TABLE_1_IN,
        COARSE_DELAY_TABLE_1_OUT => COARSE_DELAY_TABLE_1_OUT,
        --report
        REPORT_FIELDS_RW         => REPORT_FIELDS_RW,
        REPORT_FIELDS_RO         => REPORT_FIELDS_RO_HOLD
    );
    
    mace_reset                <= SETUP_FIELDS_RW.full_reset;
    
    mace_enable_timed_output  <= TIMING_FIELDS_RW.control_enable_timed_output;
    mace_enable_timed_input   <= TIMING_FIELDS_RW.control_enable_timed_input;
    
    mace_config_start_ts      <= TIMING_FIELDS_RW.starting_packet_count;
    
    mace_config_start_wt.sec  <= TIMING_FIELDS_RW.starting_wall_time_seconds;
    mace_config_start_wt.ns   <= TIMING_FIELDS_RW.starting_wall_time_nanos(29 downto 0);
    mace_config_output_cycles <= TIMING_FIELDS_RW.output_cycles;
    
    mace_config_prime_wt.sec  <= TIMING_FIELDS_RW.prime_wall_time_seconds;
    mace_config_prime_wt.ns   <= TIMING_FIELDS_RW.prime_wall_time_nanos(29 downto 0);
    mace_config_input_cycles  <= TIMING_FIELDS_RW.input_cycles;
    
    mace_config_vld           <= TIMING_FIELDS_RW.control_use_new_config;
    
    -----------------------------------------------------------------
    -- Stop Control:
    --
    -- Halt the Input on a given packet count
    -----------------------------------------------------------------
    GEN_STOP_CONTROL: if true generate
        signal halt_packet_count         : std_logic_vector(31 downto 0);
        signal halt_packet_count_cdc     : std_logic_vector(31 downto 0);
        signal halt_packet_count_vld     : std_logic;
        signal halt_packet_count_vld_cdc : std_logic;
        signal empty_cdc : std_logic;
    begin
        E_CDC_EMPTY : xpm_cdc_single
        generic map (
            DEST_SYNC_FF => 2,   
            INIT_SYNC_FF => 0, 
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG => 1  
        )
        port map (
            src_clk  => i_hbm_clk,  
            src_in   => i_debug_ctc_empty,     
            dest_clk => i_input_clk,
            dest_out => empty_cdc
        );

        E_CDC_RUNNING : xpm_cdc_single
        generic map (
            DEST_SYNC_FF   => 2,
            INIT_SYNC_FF   => 0,
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG  => 1
        ) port map (
            src_clk   => i_input_clk,   
            src_in    => i_min_packet_seen and not (i_max_packet_reached and empty_cdc),
            dest_out  => SETUP_FIELDS_RO.running, 
            dest_clk  => i_mace_clk 
        );
    
        P_HALT_PACKET_COUNT: process (i_mace_clk)
        begin
            if rising_edge(i_mace_clk) then
                halt_packet_count <= SETUP_FIELDS_RW.halt_packet_count;
                if i_mace_clk_rst='1' then
                    halt_packet_count_vld <= '1';
                elsif halt_packet_count /= SETUP_FIELDS_RW.halt_packet_count then
                    halt_packet_count_vld <= '1';
                else
                    halt_packet_count_vld <= '0';
                end if;
            end if;
        end process;

        E_CDC_LAST_VLD : xpm_cdc_pulse
        generic map (
            DEST_SYNC_FF   => 5,
            INIT_SYNC_FF   => 0,
            REG_OUTPUT     => 1,  
            RST_USED       => 1,    
            SIM_ASSERT_CHK => 1 
        )
        port map (
            src_clk    => i_mace_clk,
            src_rst    => i_mace_clk_rst,     
            src_pulse  => halt_packet_count_vld,  
            dest_clk   => i_input_clk, 
            dest_rst   => '0', 
            dest_pulse => halt_packet_count_vld_cdc 
        );

        E_CDC_LAST_TS : xpm_cdc_array_single
        generic map (
            DEST_SYNC_FF   => 2,
            INIT_SYNC_FF   => 0,
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG  => 1,
            WIDTH          => 32
        ) port map (
            src_clk   => i_mace_clk,   
            src_in    => SETUP_FIELDS_RW.halt_packet_count,
            dest_out  => halt_packet_count_cdc, 
            dest_clk  => i_input_clk
        );

        P_HALT_PACKET_COUNT_CDC: process (i_input_clk)
        begin
            if rising_edge(i_input_clk) then
                if halt_packet_count_vld_cdc='1' then
                    o_input_end_ts <= halt_packet_count_cdc;
                end if;
            end if;
        end process;
        
    end generate;
    
    
    
    -----------------------------------------------------------------
    -- Coarse Delay Memory
    -----------------------------------------------------------------
    -- The incoming coarse delay address is generated by the
    -- Output Buffer. It represents the address of the next
    -- packet and the logic here has therefore a whole output
    -- packet time to deliver the correct coarse delay value.
    -----------------------------------------------------------------
    GEN_COARSE_DELAY: if true generate
        signal active_table : std_logic;
        signal addr   : std_logic_vector(10 downto 0);
        signal rd_en  : std_logic;
        signal rd_vld : std_logic;
        type t_state is (s_IDLE, s_READ1, s_READ2, s_READ3, s_READ4);
        signal state : t_state := s_IDLE;
        signal mace_out_rst_p : std_logic;        
    begin
        COARSE_DELAY_TABLE_0_IN.clk    <= i_hbm_clk;
        COARSE_DELAY_TABLE_0_IN.rst    <= '0';
        COARSE_DELAY_TABLE_0_IN.adr    <= addr;
        COARSE_DELAY_TABLE_0_IN.wr_en  <= '0';
        COARSE_DELAY_TABLE_0_IN.wr_dat <= (others => '0');
        COARSE_DELAY_TABLE_0_IN.rd_en  <= rd_en;

        COARSE_DELAY_TABLE_1_IN.clk    <= i_hbm_clk;
        COARSE_DELAY_TABLE_1_IN.rst    <= '0';
        COARSE_DELAY_TABLE_1_IN.adr    <= addr;
        COARSE_DELAY_TABLE_1_IN.wr_en  <= '0';
        COARSE_DELAY_TABLE_1_IN.wr_dat <= (others => '0');
        COARSE_DELAY_TABLE_1_IN.rd_en  <= rd_en;
        
        COARSE_DELAY_FIELDS_RO.active_table  <= active_table;
        
        rd_vld <= COARSE_DELAY_TABLE_0_OUT.rd_val when active_table='0' else COARSE_DELAY_TABLE_1_OUT.rd_val;
        
        P_FSM: process(i_hbm_clk)
        begin
            if rising_edge(i_hbm_clk) then
                
                rd_en      <= '0';
                
                case state is
                when s_IDLE =>
                    mace_out_rst_p <= mace_out_rst;
                    if i_coarse_delay_addr_vld='1' or (mace_out_rst='0' and mace_out_rst_p='1') then
                        state <= s_READ1;
                    end if;
                when s_READ1 =>
                    addr <= i_coarse_delay_addr(9 downto 0) & '0';
                    rd_en <= '1';
                    state <= s_READ2;
                when s_READ2 =>
                    if rd_vld='1' then
                        if active_table='0' then
                            o_coarse_delay_value      <= COARSE_DELAY_TABLE_0_OUT.rd_dat(15 downto 00);
                            o_coarse_delay_delta_hpol <= COARSE_DELAY_TABLE_0_OUT.rd_dat(31 downto 16);
                        else
                            o_coarse_delay_value      <= COARSE_DELAY_TABLE_1_OUT.rd_dat(15 downto 00);
                            o_coarse_delay_delta_hpol <= COARSE_DELAY_TABLE_1_OUT.rd_dat(31 downto 16);
                        end if;                            
                        state  <= s_READ3;
                    end if;
                when s_READ3 =>
                    addr <= i_coarse_delay_addr(9 downto 0) & '1';
                    rd_en <= '1';
                    state <= s_READ4;
                when s_READ4 =>
                    if rd_vld='1' then
                        if active_table='0' then
                            o_coarse_delay_delta_vpol  <= COARSE_DELAY_TABLE_0_OUT.rd_dat(15 downto 00);
                            o_coarse_delay_delta_delta <= COARSE_DELAY_TABLE_0_OUT.rd_dat(31 downto 16);
                        else
                            o_coarse_delay_delta_vpol  <= COARSE_DELAY_TABLE_1_OUT.rd_dat(15 downto 00);
                            o_coarse_delay_delta_delta <= COARSE_DELAY_TABLE_1_OUT.rd_dat(31 downto 16);
                        end if;                            
                        state  <= s_IDLE;
                    end if;
                end case;    
            end if;        
        end process;
                        
        P_TABLE_SELECT: process(i_hbm_clk)
        begin
            if rising_edge(i_hbm_clk) then
                if o_hbm_clk_rst='1' then
                    active_table <= '0';
                end if;    
                
                if i_end_of_integration_period='1' and i_curent_packet_count>=COARSE_DELAY_FIELDS_RW.packet_count and active_table/=COARSE_DELAY_FIELDS_RW.table_select then
                    active_table <= COARSE_DELAY_FIELDS_RW.table_select;
                end if;
            end if;        
        end process;
        
        o_coarse_delay_packet_count <= COARSE_DELAY_FIELDS_RW.packet_count;

    end generate;    
    

    
    ------------------------------------------------------------------------------------
    -- Reset FSM
    ------------------------------------------------------------------------------------
    -- Release reset in a defined order from output to input.
    -- We actively wait for the HBM to report having finished its setup routine.
    ------------------------------------------------------------------------------------
    GEN_RESET: if true generate
        type t_state is (s_POR, s_RESET, s_RELEASE_OUTPUT, s_RELEASE_HBM, s_RUNNING); 
        signal state   : t_state := s_POR;
        signal counter : unsigned(7 downto 0); 
    begin
        P_FSM: process(i_mace_clk)
        begin
            if rising_edge(i_mace_clk) then
                if i_mace_clk_rst='1' then
                    state <= s_POR;
                    mace_in_rst  <= '1';
                    mace_hbm_rst <= '1';
                    mace_out_rst <= '1';
                else
                    case state is
                    when s_POR =>
                        mace_in_rst  <= '1';
                        mace_hbm_rst <= '1';
                        mace_out_rst <= '1';
                        if mace_reset='1' then
                            state <= s_RESET;
                        end if;
                    
                    when s_RESET =>
                        mace_in_rst  <= '1';
                        mace_hbm_rst <= '1';
                        mace_out_rst <= '1';
                        if mace_reset='0' then
                            state <= s_RELEASE_OUTPUT;
                            counter <= (others => '1');
                        end if;
                    
                    when s_RELEASE_OUTPUT =>
                        mace_in_rst  <= '1';
                        mace_hbm_rst <= '1';
                        mace_out_rst <= '0';
                        if counter=0 then
                            state <= s_RELEASE_HBM;
                        else
                            counter <= counter - 1;
                        end if;    
                    
                    when s_RELEASE_HBM =>
                        mace_in_rst  <= '1';
                        mace_hbm_rst <= '0';
                        mace_out_rst <= '0';
                        if hbm_ready='1' then
                            state <= s_RUNNING;                        
                        end if;
                        
                    when s_RUNNING =>
                        mace_in_rst  <= '0';
                        mace_hbm_rst <= '0';
                        mace_out_rst <= '0';
                        if mace_reset='1' then
                            state <= s_RESET;
                        end if;
                    end case;
                end if; 
            end if;
        end process;
        
        E_CDC_HBM_READY : xpm_cdc_single
        generic map (
            DEST_SYNC_FF => 2,   
            INIT_SYNC_FF => 0, 
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG => 1  
        )
        port map (
            src_clk  => i_hbm_clk,  
            src_in   => i_hbm_ready,     
            dest_clk => i_mace_clk,
            dest_out => hbm_ready
        );

        E_CDC_INPUT_RST : xpm_cdc_single
        generic map (
            DEST_SYNC_FF => 2,   
            INIT_SYNC_FF => 0, 
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG => 1  
        )
        port map (
            src_clk  => i_mace_clk,  
            src_in   => mace_in_rst,     
            dest_clk => i_input_clk,
            dest_out => o_input_clk_rst
        );

        E_CDC_HBM_RST : xpm_cdc_single
        generic map (
            DEST_SYNC_FF => 2,   
            INIT_SYNC_FF => 0, 
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG => 1  
        )
        port map (
            src_clk  => i_mace_clk,  
            src_in   => mace_hbm_rst,     
            dest_clk => i_hbm_clk,
            dest_out => o_hbm_clk_rst
        );
        
        E_CDC_OUTPUT_RST : xpm_cdc_single
        generic map (
            DEST_SYNC_FF => 2,   
            INIT_SYNC_FF => 0, 
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG => 1  
        )
        port map (
            src_clk  => i_mace_clk,  
            src_in   => mace_out_rst,     
            dest_clk => i_output_clk,
            dest_out => o_output_clk_rst
        );
        
    end generate;
    


    ------------------------------------------------------------------------------------
    -- Clock Domain Crossing of Config Signals
    --
    -- Please note that without a rising edge on VLD, nothing gets promoted to the CTC.
    ------------------------------------------------------------------------------------
    GEN_CDC: if true generate
        constant c_DATA_FLOPS  : integer := 2;
        constant c_VALID_FLOPS : integer := c_DATA_FLOPS+3; -- vld signal has 3 more flops to avoid any meta stability issues 

        signal input_start_ts             : std_logic_vector(31 downto 0);
        signal input_config_prime_wt_slv  : std_logic_vector(pc_WALL_TIME_LEN-1 downto 0);
        signal input_cycles_per_packet    : std_logic_vector(31 downto 0);

        signal hbm_start_ts               : std_logic_vector(31 downto 0);
        
        signal output_start_ts            : std_logic_vector(31 downto 0);
        signal output_config_start_wt_slv : std_logic_vector(pc_WALL_TIME_LEN-1 downto 0);
        signal output_cycles_per_packet   : std_logic_vector(31 downto 0);
        
        signal input_config_vld  : std_logic;
        signal hbm_config_vld    : std_logic;
        signal output_config_vld : std_logic;
    begin

        -----------------------------------------------------------------
        -- CDC VLD
        -----------------------------------------------------------------
        CDC_INPUT_VLD : xpm_cdc_pulse
        generic map (
            DEST_SYNC_FF   => c_VALID_FLOPS,
            INIT_SYNC_FF   => 0,
            REG_OUTPUT     => 1,  
            RST_USED       => 1,    
            SIM_ASSERT_CHK => 1 
        )
        port map (
            src_clk    => i_mace_clk,
            src_rst    => i_mace_clk_rst,     
            src_pulse  => mace_config_vld,  
            dest_clk   => i_input_clk, 
            dest_rst   => '0', 
            dest_pulse => input_config_vld 
        );

        CDC_HBM_VLD : xpm_cdc_pulse
        generic map (
            DEST_SYNC_FF   => c_VALID_FLOPS,
            INIT_SYNC_FF   => 0,
            REG_OUTPUT     => 1,
            RST_USED       => 1,
            SIM_ASSERT_CHK => 1 
        )
        port map (
            src_clk    => i_mace_clk,
            src_rst    => i_mace_clk_rst,     
            src_pulse  => mace_config_vld,  
            dest_clk   => i_hbm_clk, 
            dest_rst   => '0', 
            dest_pulse => hbm_config_vld 
        );

        CDC_OUTPUT_VLD : xpm_cdc_pulse
        generic map (
            DEST_SYNC_FF   => c_VALID_FLOPS, 
            INIT_SYNC_FF   => 0,   
            REG_OUTPUT     => 1,     
            RST_USED       => 1,       
            SIM_ASSERT_CHK => 1  
        )
        port map (
            src_clk    => i_mace_clk,
            src_rst    => i_mace_clk_rst,     
            src_pulse  => mace_config_vld,  
            dest_clk   => i_output_clk, 
            dest_rst   => '0', 
            dest_pulse => output_config_vld 
        );


        -----------------------------------------------------------------
        -- CDC ENABLE TIMED INPUT / OUTPUT
        -----------------------------------------------------------------
        E_CDC_ENABLE_TIMED_INPUT : xpm_cdc_single
        generic map (
            DEST_SYNC_FF => c_DATA_FLOPS,   
            INIT_SYNC_FF => 0, 
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG => 1  
        )
        port map (
            src_clk  => i_mace_clk,  
            src_in   => mace_enable_timed_input,     
            dest_clk => i_input_clk,
            dest_out => o_enable_timed_input
        );

        E_CDC_ENABLE_TIMED_OUTPUT : xpm_cdc_single
        generic map (
            DEST_SYNC_FF => c_DATA_FLOPS,   
            INIT_SYNC_FF => 0, 
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG => 1  
        )
        port map (
            src_clk  => i_mace_clk,  
            src_in   => mace_enable_timed_output,     
            dest_clk => i_output_clk,
            dest_out => o_enable_timed_output
        );



        -----------------------------------------------------------------
        -- CDC INPUT TIME CONTROL
        -----------------------------------------------------------------
        E_CDC_INPUT_CONFIG_TS : xpm_cdc_array_single
        generic map (
            DEST_SYNC_FF   => c_DATA_FLOPS,
            INIT_SYNC_FF   => 0,
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG  => 1,
            WIDTH => 32 
        ) port map (
            src_clk  => i_mace_clk,   
            src_in   => mace_config_start_ts,
            dest_out => input_start_ts, 
            dest_clk => i_input_clk 
        );

        E_CDC_INPUT_CONFIG_WT : xpm_cdc_array_single
        generic map (
            DEST_SYNC_FF   => c_DATA_FLOPS,
            INIT_SYNC_FF   => 0,
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG  => 1,
            WIDTH => pc_WALL_TIME_LEN
        ) port map (
            src_clk  => i_mace_clk,   
            src_in   => wall_time_to_slv(mace_config_prime_wt),
            dest_out => input_config_prime_wt_slv, 
            dest_clk => i_input_clk 
        );
    
        E_CDC_INPUT_CONFIG_OUTPUT_CYCLES : xpm_cdc_array_single
        generic map (
            DEST_SYNC_FF   => c_DATA_FLOPS,
            INIT_SYNC_FF   => 0,
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG  => 1,
            WIDTH => 32 
        ) port map (
            src_clk  => i_mace_clk,   
            src_in   => mace_config_input_cycles,
            dest_out => input_cycles_per_packet, 
            dest_clk => i_input_clk 
        );
        
        P_SYNC_INPUT: process (i_input_clk)
        begin
            if rising_edge(i_input_clk) then
                o_input_update <= '0';
                if input_config_vld='1' then
                    o_input_start_ts          <= input_start_ts;
                    o_input_cycles_per_packet <= input_cycles_per_packet;
                    o_input_prime_wt          <= slv_to_wall_time(input_config_prime_wt_slv);
                    o_input_update            <= '1';
                end if;    
            end if;    
        end process;
        
        
        -----------------------------------------------------------------
        -- CDC OUTPUT TIME CONTROL
        -----------------------------------------------------------------
        E_CDC_OUTPUT_CONFIG_WT : xpm_cdc_array_single
        generic map (
            DEST_SYNC_FF   => c_DATA_FLOPS,
            INIT_SYNC_FF   => 0,
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG  => 1,
            WIDTH => pc_WALL_TIME_LEN
        ) port map (
            src_clk  => i_mace_clk,   
            src_in   => wall_time_to_slv(mace_config_start_wt),
            dest_out => output_config_start_wt_slv, 
            dest_clk => i_output_clk 
        );
    
        E_CDC_OUTPUT_CONFIG_OUTPUT_CYCLES : xpm_cdc_array_single
        generic map (
            DEST_SYNC_FF   => c_DATA_FLOPS,
            INIT_SYNC_FF   => 0,
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG  => 1,
            WIDTH => 32 
        ) port map (
            src_clk  => i_mace_clk,   
            src_in   => mace_config_output_cycles,
            dest_out => output_cycles_per_packet, 
            dest_clk => i_output_clk 
        );

        E_CDC_OUTPUT_CONFIG_TS : xpm_cdc_array_single
        generic map (
            DEST_SYNC_FF   => c_DATA_FLOPS,
            INIT_SYNC_FF   => 0,
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG  => 1,
            WIDTH => 32 
        ) port map (
            src_clk  => i_mace_clk,   
            src_in   => mace_config_start_ts,
            dest_out => output_start_ts, 
            dest_clk => i_output_clk 
        );
    
        P_SYNC_OUTPUT: process (i_output_clk)
        begin
            if rising_edge(i_output_clk) then
                o_output_update <= '0';
                if output_config_vld='1' then
                    o_output_start_ts          <= output_start_ts;
                    o_output_cycles_per_packet <= output_cycles_per_packet;
                    o_output_start_wt          <= slv_to_wall_time(output_config_start_wt_slv);
                    o_output_update            <= '1';
                end if;    
            end if;    
        end process;

        -----------------------------------------------------------------
        -- CDC HBM TIME CONTROL
        -----------------------------------------------------------------
        E_CDC_HBM_CONFIG_TS : xpm_cdc_array_single
        generic map (
            DEST_SYNC_FF   => c_DATA_FLOPS,
            INIT_SYNC_FF   => 0,
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG  => 1,
            WIDTH => 32 
        ) port map (
            src_clk  => i_mace_clk,   
            src_in   => mace_config_start_ts,
            dest_out => hbm_start_ts, 
            dest_clk => i_hbm_clk 
        );

        P_SYNC_HBM: process (i_hbm_clk)
        begin
            if rising_edge(i_hbm_clk) then
                o_hbm_update <= '0';
                if hbm_config_vld='1' then
                    o_hbm_start_ts  <= hbm_start_ts;
                    o_hbm_update    <= '1';
                end if;    
            end if;    
        end process;
        
    end generate;


    -----------------------------------------------------------------
    -- Report: Errors & Debug
    -----------------------------------------------------------------
    E_CDC_INPUT_ERROR_1 : xpm_cdc_pulse
    generic map (
        DEST_SYNC_FF   => 2, 
        INIT_SYNC_FF   => 0,   
        REG_OUTPUT     => 1,     
        RST_USED       => 1,       
        SIM_ASSERT_CHK => 1  
    )
    port map (
        src_clk    => i_input_clk,
        src_rst    => o_input_clk_rst,     
        src_pulse  => i_error_input_buffer_full,  
        dest_clk   => i_mace_clk, 
        dest_rst   => mace_in_rst, 
        dest_pulse => REPORT_FIELDS_RO.error_input_buffer_full
    );

    E_CDC_INPUT_ERROR_2 : xpm_cdc_pulse
    generic map (
        DEST_SYNC_FF   => 2, 
        INIT_SYNC_FF   => 0,   
        REG_OUTPUT     => 1,     
        RST_USED       => 1,       
        SIM_ASSERT_CHK => 1  
    )
    port map (
        src_clk    => i_input_clk,
        src_rst    => o_input_clk_rst,     
        src_pulse  => i_error_input_buffer_overflow,  
        dest_clk   => i_mace_clk, 
        dest_rst   => mace_in_rst, 
        dest_pulse => REPORT_FIELDS_RO.error_input_buffer_overflow
    );


    E_CDC_HBM_ERROR_0 : xpm_cdc_pulse
    generic map (
        DEST_SYNC_FF   => 2, 
        INIT_SYNC_FF   => 0,   
        REG_OUTPUT     => 1,     
        RST_USED       => 1,       
        SIM_ASSERT_CHK => 1  
    )
    port map (
        src_clk    => i_hbm_clk,
        src_rst    => o_hbm_clk_rst,     
        src_pulse  => i_error_ctc_full,  
        dest_clk   => i_mace_clk, 
        dest_rst   => mace_in_rst, 
        dest_pulse => REPORT_FIELDS_RO.error_ctc_full
    );

    E_CDC_HBM_ERROR_1 : xpm_cdc_pulse
    generic map (
        DEST_SYNC_FF   => 2, 
        INIT_SYNC_FF   => 0,   
        REG_OUTPUT     => 1,     
        RST_USED       => 1,       
        SIM_ASSERT_CHK => 1  
    )
    port map (
        src_clk    => i_hbm_clk,
        src_rst    => o_hbm_clk_rst,     
        src_pulse  => i_error_overwrite,  
        dest_clk   => i_mace_clk, 
        dest_rst   => mace_in_rst, 
        dest_pulse => REPORT_FIELDS_RO.error_overwrite
    );

    E_CDC_HBM_ERROR_2 : xpm_cdc_pulse
    generic map (
        DEST_SYNC_FF   => 2, 
        INIT_SYNC_FF   => 0,   
        REG_OUTPUT     => 1,     
        RST_USED       => 1,       
        SIM_ASSERT_CHK => 1  
    )
    port map (
        src_clk    => i_hbm_clk,
        src_rst    => o_hbm_clk_rst,     
        src_pulse  => i_error_too_late,  
        dest_clk   => i_mace_clk, 
        dest_rst   => mace_in_rst, 
        dest_pulse => REPORT_FIELDS_RO.error_drop
    );

    E_CDC_HBM_ERROR_3 : xpm_cdc_pulse
    generic map (
        DEST_SYNC_FF   => 2, 
        INIT_SYNC_FF   => 0,   
        REG_OUTPUT     => 1,     
        RST_USED       => 1,       
        SIM_ASSERT_CHK => 1  
    )
    port map (
        src_clk    => i_hbm_clk,
        src_rst    => o_hbm_clk_rst,     
        src_pulse  => i_error_wa_fifo_full,  
        dest_clk   => i_mace_clk, 
        dest_rst   => mace_in_rst, 
        dest_pulse => REPORT_FIELDS_RO.debug_wa_fifo_overflow
    );

    E_CDC_HBM_ERROR_4 : xpm_cdc_pulse
    generic map (
        DEST_SYNC_FF   => 2, 
        INIT_SYNC_FF   => 0,   
        REG_OUTPUT     => 1,     
        RST_USED       => 1,       
        SIM_ASSERT_CHK => 1  
    )
    port map (
        src_clk    => i_hbm_clk,
        src_rst    => o_hbm_clk_rst,     
        src_pulse  => i_error_ra_fifo_full,  
        dest_clk   => i_mace_clk, 
        dest_rst   => mace_in_rst, 
        dest_pulse => REPORT_FIELDS_RO.debug_ra_fifo_overflow
    );

    E_CDC_HBM_ERROR_5 : xpm_cdc_pulse
    generic map (
        DEST_SYNC_FF   => 2, 
        INIT_SYNC_FF   => 0,   
        REG_OUTPUT     => 1,     
        RST_USED       => 1,       
        SIM_ASSERT_CHK => 1  
    )
    port map (
        src_clk    => i_hbm_clk,
        src_rst    => o_hbm_clk_rst,     
        src_pulse  => i_error_bv_fifo_full,  
        dest_clk   => i_mace_clk, 
        dest_rst   => mace_in_rst, 
        dest_pulse => REPORT_FIELDS_RO.debug_bv_fifo_overflow
    );

    E_CDC_HBM_ERROR_6 : xpm_cdc_pulse
    generic map (
        DEST_SYNC_FF   => 2, 
        INIT_SYNC_FF   => 0,   
        REG_OUTPUT     => 1,     
        RST_USED       => 1,       
        SIM_ASSERT_CHK => 1  
    )
    port map (
        src_clk    => i_hbm_clk,
        src_rst    => o_hbm_clk_rst,     
        src_pulse  => i_error_bv_fifo_underflow,  
        dest_clk   => i_mace_clk, 
        dest_rst   => mace_in_rst, 
        dest_pulse => REPORT_FIELDS_RO.debug_bv_fifo_underflow
    );

    E_CDC_HBM_ERROR_7 : xpm_cdc_pulse
    generic map (
        DEST_SYNC_FF   => 2, 
        INIT_SYNC_FF   => 0,   
        REG_OUTPUT     => 1,     
        RST_USED       => 1,       
        SIM_ASSERT_CHK => 1  
    )
    port map (
        src_clk    => i_hbm_clk,
        src_rst    => o_hbm_clk_rst,     
        src_pulse  => i_error_coarse_delay_fifo_overflow,  
        dest_clk   => i_mace_clk, 
        dest_rst   => mace_in_rst, 
        dest_pulse => REPORT_FIELDS_RO.debug_delay_fifo_overflow
    );

    GEN_CDC_DSP_OVERFLOW: for i in 0 to 3 generate
    begin
        E_CDC_HBM_ERROR_8 : xpm_cdc_pulse
        generic map (
            DEST_SYNC_FF   => 2, 
            INIT_SYNC_FF   => 0,   
            REG_OUTPUT     => 1,     
            RST_USED       => 1,       
            SIM_ASSERT_CHK => 1  
        )
        port map (
            src_clk    => i_hbm_clk,
            src_rst    => o_hbm_clk_rst,     
            src_pulse  => i_error_dsp_overflow(i),  
            dest_clk   => i_mace_clk, 
            dest_rst   => mace_in_rst, 
            dest_pulse => REPORT_FIELDS_RO.error_dsp_overflow(i)
        );
    end generate;


    E_CDC_OUTPUT_ERROR_1 : xpm_cdc_pulse
    generic map (
        DEST_SYNC_FF   => 2, 
        INIT_SYNC_FF   => 0,   
        REG_OUTPUT     => 1,     
        RST_USED       => 1,       
        SIM_ASSERT_CHK => 1  
    )
    port map (
        src_clk    => i_output_clk,
        src_rst    => o_output_clk_rst,     
        src_pulse  => i_error_ctc_underflow,  
        dest_clk   => i_mace_clk, 
        dest_rst   => mace_in_rst, 
        dest_pulse => REPORT_FIELDS_RO.error_ctc_underflow
    );

    E_CDC_OUTPUT_ERROR_2 : xpm_cdc_pulse
    generic map (
        DEST_SYNC_FF   => 2, 
        INIT_SYNC_FF   => 0,   
        REG_OUTPUT     => 1,     
        RST_USED       => 1,       
        SIM_ASSERT_CHK => 1  
    )
    port map (
        src_clk    => i_output_clk,
        src_rst    => o_output_clk_rst,     
        src_pulse  => i_error_output_aligment_loss,  
        dest_clk   => i_mace_clk, 
        dest_rst   => mace_in_rst, 
        dest_pulse => REPORT_FIELDS_RO.error_ctc_aligment_loss
    );

    E_CDC_READ_PHASE : xpm_cdc_array_single
    generic map (
        DEST_SYNC_FF   => 2,
        INIT_SYNC_FF   => 0,
        SIM_ASSERT_CHK => 0,
        SRC_INPUT_REG  => 1,
        WIDTH => 2 
    ) port map (
        src_clk  => i_hbm_clk,   
        src_in   => i_debug_ctc_ra_phase,
        dest_out => REPORT_FIELDS_RO.debug_ctc_read_phase, 
        dest_clk => i_mace_clk 
    );

    E_CDC_READ_CURSOR : xpm_cdc_array_single
    generic map (
        DEST_SYNC_FF   => 2,
        INIT_SYNC_FF   => 0,
        SIM_ASSERT_CHK => 0,
        SRC_INPUT_REG  => 1,
        WIDTH => 16 
    ) port map (
        src_clk  => i_hbm_clk,   
        src_in   => i_debug_ctc_ra_cursor,
        dest_out => REPORT_FIELDS_RO.debug_ctc_read_cursor, 
        dest_clk => i_mace_clk 
    );

    E_CDC_EMPTY : xpm_cdc_single
    generic map (
        DEST_SYNC_FF   => 2,
        INIT_SYNC_FF   => 0,
        SIM_ASSERT_CHK => 0,
        SRC_INPUT_REG  => 1
    ) port map (
        src_clk  => i_hbm_clk,   
        src_in   => i_debug_ctc_empty,
        dest_out => REPORT_FIELDS_RO.debug_ctc_empty, 
        dest_clk => i_mace_clk 
    );
                 
    P_HOLD_ERRORS: process(i_mace_clk)
    begin
        if rising_edge(i_mace_clk) then
            if i_mace_clk_rst='1' or REPORT_FIELDS_RW.reset='1' or mace_reset='1' then
                REPORT_FIELDS_RO_HOLD <= (error_dsp_overflow=>B"0000", debug_ctc_read_phase=>B"00", debug_ctc_read_cursor=>X"0000", others=>'0');
            else
                
                --no actual hold here (only read these values when CTC has been halted via halt_packet_count):
                REPORT_FIELDS_RO_HOLD.debug_ctc_read_phase  <= REPORT_FIELDS_RO.debug_ctc_read_phase;
                REPORT_FIELDS_RO_HOLD.debug_ctc_read_cursor <= REPORT_FIELDS_RO.debug_ctc_read_cursor;
                REPORT_FIELDS_RO_HOLD.debug_ctc_empty       <= REPORT_FIELDS_RO.debug_ctc_empty;
                
                --hold:
                if REPORT_FIELDS_RO.error_input_buffer_full='1' then
                    REPORT_FIELDS_RO_HOLD.error_input_buffer_full<='1';
                end if;    
                if REPORT_FIELDS_RO.error_input_buffer_overflow='1' then
                    REPORT_FIELDS_RO_HOLD.error_input_buffer_overflow<='1';
                end if;    
                if REPORT_FIELDS_RO.error_ctc_full='1' then
                    REPORT_FIELDS_RO_HOLD.error_ctc_full<='1';
                end if;    
                if REPORT_FIELDS_RO.error_overwrite='1' then
                    REPORT_FIELDS_RO_HOLD.error_overwrite<='1';
                end if;    
                if REPORT_FIELDS_RO.error_drop='1' then
                    REPORT_FIELDS_RO_HOLD.error_drop<='1';
                end if;
                if REPORT_FIELDS_RO.error_dsp_overflow(0)='1' then
                    REPORT_FIELDS_RO_HOLD.error_dsp_overflow(0)<='1';
                end if;
                if REPORT_FIELDS_RO.error_dsp_overflow(1)='1' then
                    REPORT_FIELDS_RO_HOLD.error_dsp_overflow(1)<='1';
                end if;
                if REPORT_FIELDS_RO.debug_wa_fifo_overflow='1' then
                    REPORT_FIELDS_RO_HOLD.debug_wa_fifo_overflow<='1';
                end if;    
                if REPORT_FIELDS_RO.debug_ra_fifo_overflow='1' then
                    REPORT_FIELDS_RO_HOLD.debug_ra_fifo_overflow<='1';
                end if;    
                if REPORT_FIELDS_RO.debug_bv_fifo_overflow='1' then
                    REPORT_FIELDS_RO_HOLD.debug_bv_fifo_overflow<='1';
                end if;    
                if REPORT_FIELDS_RO.debug_bv_fifo_underflow='1' then
                    REPORT_FIELDS_RO_HOLD.debug_bv_fifo_underflow<='1';
                end if;    
                if REPORT_FIELDS_RO.debug_delay_fifo_overflow='1' then
                    REPORT_FIELDS_RO_HOLD.debug_delay_fifo_overflow<='1';
                end if;    
                if REPORT_FIELDS_RO.error_ctc_underflow='1' then
                    REPORT_FIELDS_RO_HOLD.error_ctc_underflow<='1';
                end if;    
                if REPORT_FIELDS_RO.error_ctc_aligment_loss='1' then
                    REPORT_FIELDS_RO_HOLD.error_ctc_aligment_loss<='1';
                end if;    
            end if;
        end if;
    end process;              


    -----------------------------------------------------------------
    -- Valid Count Memory
    -----------------------------------------------------------------
    GEN_VALID_BLOCK_COUNT: if true generate
        signal addr   : std_logic_vector(9 downto 0);
        signal wr_en  : std_logic;
        signal rd_en  : std_logic;
        signal rd_vld : std_logic;
        signal wr_dat : std_logic_vector(31 downto 0);
        signal rd_dat : std_logic_vector(31 downto 0);
        type t_state is (s_IDLE, s_READ, s_RESET1, s_RESET2);
        signal state : t_state;
    begin
        VALID_BLOCKS_COUNT_IN.clk    <= i_hbm_clk;
        VALID_BLOCKS_COUNT_IN.rst    <= '0';
        VALID_BLOCKS_COUNT_IN.adr    <= addr;
        VALID_BLOCKS_COUNT_IN.wr_en  <= wr_en;
        VALID_BLOCKS_COUNT_IN.wr_dat <= wr_dat;
        VALID_BLOCKS_COUNT_IN.rd_en  <= rd_en;

        rd_dat <= VALID_BLOCKS_COUNT_OUT.rd_dat;
        rd_vld <= VALID_BLOCKS_COUNT_OUT.rd_val;
        
        P_FSM: process(i_hbm_clk)
        begin
            if rising_edge(i_hbm_clk) then
                
                rd_en <= '0';
                wr_en <= '0';
                
                if VALID_BLOCKS_FIELDS_RW.reset='1' then 
                    state  <= s_RESET1;
                    addr   <= (others=>'0');
                    wr_dat <= (others=>'0');
                    wr_en  <= '1';
                else
                    case state is
                    when s_IDLE =>
                        if i_debug_station_channel_inc='1' then
                            addr  <= i_debug_station_channel;
                            rd_en <= '1';
                            state <= s_READ;
                        end if;
                    when s_READ =>
                        if rd_vld='1' then
                            wr_dat <= std_logic_vector(unsigned(rd_dat) + 1);
                            wr_en  <= '1';
                            state  <= s_IDLE;
                        end if;
                    when s_RESET1 =>
                        wr_en <= '1';
                        if unsigned(addr)=767 then
                            state <= s_RESET2;
                        else
                            addr  <= std_logic_vector(unsigned(addr) + 1);
                        end if;
                    when s_RESET2 =>
                        if VALID_BLOCKS_FIELDS_RW.reset='0' then
                            state <= s_IDLE; 
                        end if;
                    end case;    
                end if;    
            end if;        
        end process;
        
    end generate;    



end Behavioral;
