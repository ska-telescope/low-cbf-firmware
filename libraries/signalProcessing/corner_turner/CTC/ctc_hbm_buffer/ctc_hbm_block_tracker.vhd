---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Coarse (CTC) - Block Valid Tracker
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert_abel@gmx.net)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- This module tracks which blocks are valid and which are not (missing).
-- When writing a block, we write a '1' to the according bit position in the block tracker.
-- When reading a block, we write a '0' to the according bit position in the block tracker,
--   iff this is the last read (AUX_E).
--
-- This runs in parallel to the HBM.
-- If the HBM response is too fast, it will fail, indicated by o_error_bv_fifo_underflow,
-- which should never happen.
---------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

Library xpm;
use xpm.vcomponents.all;

use work.ctc_pkg.all;

entity ctc_hbm_block_tracker is
    Generic (
        g_DEPTH_IN_BLOCKS  : natural := 1024; -- used HBM memory depth in INPUT_BLOCKS
        g_INPUT_BLOCK_SIZE : natural := 2048;
        g_HBM_BURST_LEN    : natural := 16
    );    
    Port (
        i_hbm_clk                 : in  std_logic;
        i_hbm_rst                 : in  std_logic;
        i_wa_block_offset         : in  std_logic_vector(log2_ceil(g_DEPTH_IN_BLOCKS)-1 downto 0);
        i_wa_block_offset_vld     : in  std_logic;
        i_wa_ack                  : in  std_logic;
        i_wa_block_good           : in  std_logic; 
        i_ra_block_offset         : in  std_logic_vector(log2_ceil(g_DEPTH_IN_BLOCKS)-1 downto 0);
        i_ra_block_offset_vld     : in  std_logic;
        i_ra_block_clear          : in  std_logic;
        i_ra_ack                  : in  std_logic; 
        o_error_overwrite         : out std_logic;
        o_error_wa_fifo_full      : out std_logic;
        o_error_ra_fifo_full      : out std_logic;
        o_error_bv_fifo_full      : out std_logic;
        o_error_bv_fifo_underflow : out std_logic;
        o_new_block               : out std_logic;
        o_block_vld               : out std_logic;
        o_reset_busy              : out std_logic
    );
end ctc_hbm_block_tracker;

architecture Behavioral of ctc_hbm_block_tracker is

    constant c_FIFO_SIZE  : integer := 128;
    constant c_ADDR_WIDTH : integer := log2_ceil(g_DEPTH_IN_BLOCKS);

    signal wa_rst_busy           : std_logic;
    signal ra_rst_busy           : std_logic;
    signal block_valid_rst_busy  : std_logic;

    signal wa_fifo_empty : std_logic;
    
    signal wa             : std_logic_vector(c_ADDR_WIDTH downto 0);
    signal wa_re          : std_logic;
    signal wa_empty       : std_logic;

    signal ra             : std_logic_vector(c_ADDR_WIDTH downto 0);
    signal ra_re          : std_logic;
    signal ra_empty       : std_logic;
    
    type t_state is (s_IDLE, s_RESET1,s_RESET2, s_RESET3, s_WA_READ1, s_WA_READ2, s_WA_WRITE, s_RA_READ1, s_RA_READ2, s_RA_WRITE);
    signal state : t_state := s_RESET1;
    
    signal addr_in  : std_logic_vector(c_ADDR_WIDTH-6-1 downto 0);
    signal data_in  : std_logic_vector(63 downto 0);
    signal write_enable : std_logic;
    
    signal addr_out : std_logic_vector(c_ADDR_WIDTH-6-1 downto 0);
    signal data_out : std_logic_vector(63 downto 0);
    
    signal bv_fifo_empty  : std_logic;
    
    signal block_valid    : std_logic;
    signal block_valid_we : std_logic;
    
    signal wa_ack_counter1 : unsigned(log2_ceil(g_INPUT_BLOCK_SIZE)-1 downto 0);
    signal wa_ack          : std_logic;
    signal wa_ack_counter2 : unsigned(log2_ceil(g_INPUT_BLOCK_SIZE)-1 downto 0);

    signal ra_ack_counter : unsigned(log2_ceil(g_INPUT_BLOCK_SIZE)-1 downto 0);
    signal ra_ack         : std_logic;
    
begin

    E_WA_FIFO : xpm_fifo_sync
    generic map (
        DOUT_RESET_VALUE    => "0",
        ECC_MODE            => "no_ecc",
        FIFO_MEMORY_TYPE    => "block",
        FIFO_READ_LATENCY   => 0,
        FIFO_WRITE_DEPTH    => c_FIFO_SIZE,
        FULL_RESET_VALUE    => 0,
        PROG_EMPTY_THRESH   => 10,
        PROG_FULL_THRESH    => 10,     
        RD_DATA_COUNT_WIDTH => log2_ceil(c_FIFO_SIZE),
        READ_DATA_WIDTH     => c_ADDR_WIDTH+1,
        READ_MODE           => "fwft",
        USE_ADV_FEATURES    => "0000",       
        WAKEUP_TIME         => 0,
        WRITE_DATA_WIDTH    => c_ADDR_WIDTH+1,
        WR_DATA_COUNT_WIDTH => log2_ceil(c_FIFO_SIZE)
    ) port map (
        wr_clk        => i_hbm_clk,
        rst           => i_hbm_rst,
        wr_rst_busy   => wa_rst_busy,
        --di
        din           => i_wa_block_good & i_wa_block_offset,
        wr_en         => i_wa_block_offset_vld,
        full          => o_error_wa_fifo_full,
        --do
        dout          => wa,
        rd_en         => wa_re,
        empty         => wa_fifo_empty,
        --unused
        sleep         => '0', 
        injectdbiterr => '0',
        injectsbiterr => '0'
    ); 
    
    assert o_error_wa_fifo_full/='1' report "WA FIFO overflow!" severity FAILURE;
    assert wa_fifo_empty/='1' or wa_re/='1' report "WA FIFO underflow!" severity FAILURE;
       

    ---------------------------------------
    -- Did we write a full block?
    ---------------------------------------
    P_WA_ACK_COUNTER_1: process (i_hbm_clk)
    begin
        if rising_edge(i_hbm_clk) then
            
            wa_ack <= '0';
            
            if i_hbm_rst='1' then
                wa_ack_counter1 <= (others => '0');
            elsif i_wa_ack='1' then    
                if wa_ack_counter1=g_INPUT_BLOCK_SIZE/g_HBM_BURST_LEN-1 then
                    wa_ack_counter1 <= (others => '0');
                    wa_ack <= '1';
                else    
                    wa_ack_counter1 <= wa_ack_counter1 + 1;
                end if;
            end if;        
        end if;
    end process;

    ------------------------------------------------------
    -- How many block infos are stored in the FIFO below?
    ------------------------------------------------------
    P_WA_ACK_COUNTER_2: process (i_hbm_clk)
    begin
        if rising_edge(i_hbm_clk) then
            
            if i_hbm_rst='1' then
                wa_ack_counter2 <= (others => '0');
            elsif wa_ack='1' and wa_re='0' then    
                wa_ack_counter2 <= wa_ack_counter2 + 1;
            elsif wa_ack='0' and wa_re='1' then
                wa_ack_counter2 <= wa_ack_counter2 - 1;                
            end if;        
        end if;
    end process;
    
    wa_empty <= '1' when wa_ack_counter2=0 else '0';

    E_RA_FIFO : xpm_fifo_sync
    generic map (
        DOUT_RESET_VALUE    => "0",
        ECC_MODE            => "no_ecc",
        FIFO_MEMORY_TYPE    => "block",
        FIFO_READ_LATENCY   => 0,
        FIFO_WRITE_DEPTH    => c_FIFO_SIZE,
        FULL_RESET_VALUE    => 0,
        PROG_EMPTY_THRESH   => 10,
        PROG_FULL_THRESH    => 10,     
        RD_DATA_COUNT_WIDTH => log2_ceil(c_FIFO_SIZE),
        READ_DATA_WIDTH     => c_ADDR_WIDTH+1,
        READ_MODE           => "fwft",
        USE_ADV_FEATURES    => "0000",       
        WAKEUP_TIME         => 0,
        WRITE_DATA_WIDTH    => c_ADDR_WIDTH+1,
        WR_DATA_COUNT_WIDTH => log2_ceil(c_FIFO_SIZE)
    ) port map (
        wr_clk        => i_hbm_clk,
        rst           => i_hbm_rst,
        wr_rst_busy   => ra_rst_busy,
        --di
        din           => i_ra_block_clear & i_ra_block_offset,
        wr_en         => i_ra_block_offset_vld,
        full          => o_error_ra_fifo_full,
        --do
        dout          => ra,
        rd_en         => ra_re,
        empty         => ra_empty,
        --unused
        sleep         => '0', 
        injectdbiterr => '0',
        injectsbiterr => '0'
    );    

    assert o_error_ra_fifo_full/='1' report "RA FIFO overflow!" severity FAILURE;
    assert ra_empty/='1' or ra_re/='1' report "RA FIFO underflow!" severity FAILURE;


    P_FSM: process(i_hbm_clk)
    begin
        if rising_edge(i_hbm_clk) then
            
            --defaults:
            o_reset_busy   <= '0';
            write_enable <= '0';
            wa_re <= '0';
            ra_re <= '0';
            block_valid_we <= '0';
            
            if i_hbm_rst='1' then
                state                 <= s_RESET1;
                o_reset_busy          <= '1';
                block_valid           <= '0';
                o_error_overwrite     <= '0';
            else    
                case state is
                when s_RESET1 =>
                    o_reset_busy <= '1';
                    addr_in <= (others => '0');
                    data_in <= (others => '0');
                    write_enable <= '1';
                    state <= s_RESET2;
                    
                when s_RESET2 =>
                    o_reset_busy <= '1';
                    addr_in <= std_logic_vector(unsigned(addr_in) + 1);
                    data_in <= (others => '0');
                    write_enable <= '1';
                    if addr_in=(addr_in'range => '1') then
                        state <= s_RESET3;
                    end if;    
                
                when s_RESET3 =>
                    o_reset_busy <= '1';
                    if ra_rst_busy='0' and wa_rst_busy='0' and block_valid_rst_busy='0' then
                        state <= s_IDLE;
                    end if;    
                                        
                when s_IDLE =>
                    if ra_empty='0' then
                        state <= s_RA_READ1;
                        addr_out <= ra(c_ADDR_WIDTH-1 downto 6);
                    elsif wa_empty='0' then
                        state <= s_WA_READ1;                        
                        addr_out <= wa(c_ADDR_WIDTH-1 downto 6); 
                    end if;
                    
                
                --Set bit to '1' via read-modify-write
                when s_WA_READ1 =>
                    state <= s_WA_READ2;
                when s_WA_READ2 =>
                    state <= s_WA_WRITE;
                    wa_re <= '1';
                    
                when s_WA_WRITE =>
                    write_enable <= '1';
                    addr_in <= wa(c_ADDR_WIDTH-1 downto 6);
                    data_in <= data_out;
                    if wa(c_ADDR_WIDTH)='1' then --block good
                        data_in(to_integer(unsigned(wa(5 downto 0)))) <= '1'; --set
                    end if;
                    o_error_overwrite <= data_out(to_integer(unsigned(wa(5 downto 0))));
                    state <= s_IDLE;
                    
                --Set bit to '0' via read-modify-write
                when s_RA_READ1 =>
                    state <= s_RA_READ2;
                when s_RA_READ2 =>
                    state <= s_RA_WRITE;
                    ra_re <= '1';
                                    
                when s_RA_WRITE =>
                    block_valid    <= data_out(to_integer(unsigned(ra(5 downto 0)))); 
                    block_valid_we <= '1';
                    
                    write_enable <= '1';
                    addr_in <= ra(c_ADDR_WIDTH-1 downto 6);
                    data_in <= data_out;
                    if ra(c_ADDR_WIDTH)='1' then --clear
                        data_in(to_integer(unsigned(ra(5 downto 0)))) <= '0'; --clear
                    end if;
                    state <= s_IDLE;
                
                end case;
            end if;    
        end if;
    end process;
    
    
    URAM : xpm_memory_sdpram
    generic map (
      ADDR_WIDTH_A => c_ADDR_WIDTH-6,     
      ADDR_WIDTH_B => c_ADDR_WIDTH-6,     
      AUTO_SLEEP_TIME => 0,            
      BYTE_WRITE_WIDTH_A => 64,   
      CLOCKING_MODE => "common_clock", 
      ECC_MODE => "no_ecc",            
      MEMORY_INIT_FILE => "none",      
      MEMORY_INIT_PARAM => "0",        
      MEMORY_OPTIMIZATION => "true",   
      MEMORY_PRIMITIVE => "ultra",      
      MEMORY_SIZE => (2**(c_ADDR_WIDTH-6))*64,   
      MESSAGE_CONTROL => 0,           
      READ_DATA_WIDTH_B => 64,   
      READ_LATENCY_B => 2, --create output register to achieve timing closure            
      READ_RESET_VALUE_B => "0",      
      USE_EMBEDDED_CONSTRAINT => 0,   
      USE_MEM_INIT => 0,              
      WAKEUP_TIME => "disable_sleep", 
      WRITE_DATA_WIDTH_A => 64,  
      WRITE_MODE_B => "read_first"     
    )
    port map (
      clka  => i_hbm_clk,
      clkb  => i_hbm_clk,
      rstb  => i_hbm_rst,
      --di:
      ena   => '1',     
      wea   => (others=>write_enable),
      addra => addr_in,      
      dina  => data_in,       
      --do:
      enb   => '1',      
      addrb => addr_out,     
      doutb => data_out, 
      --unused:
      sleep => '0',
      injectsbiterra => '0',
      injectdbiterra => '0',
      regceb         => '1'
    );

    E_BLOCK_VALID_FIFO : xpm_fifo_sync
    generic map (
        DOUT_RESET_VALUE    => "0",
        ECC_MODE            => "no_ecc",
        FIFO_MEMORY_TYPE    => "auto",
        FIFO_READ_LATENCY   => 0,
        FIFO_WRITE_DEPTH    => c_FIFO_SIZE,
        FULL_RESET_VALUE    => 0,
        PROG_EMPTY_THRESH   => 10,
        PROG_FULL_THRESH    => 10,     
        RD_DATA_COUNT_WIDTH => log2_ceil(c_FIFO_SIZE),
        READ_DATA_WIDTH     => 1,
        READ_MODE           => "fwft",
        USE_ADV_FEATURES    => "0000",       
        WAKEUP_TIME         => 0,
        WRITE_DATA_WIDTH    => 1,
        WR_DATA_COUNT_WIDTH => log2_ceil(c_FIFO_SIZE)
    ) port map (
        wr_clk        => i_hbm_clk,
        rst           => i_hbm_rst,
        wr_rst_busy   => block_valid_rst_busy,
        --di
        din(0)        => block_valid,
        wr_en         => block_valid_we,
        full          => o_error_bv_fifo_full,
        --do
        dout(0)       => o_block_vld,
        rd_en         => ra_ack,
        empty         => bv_fifo_empty,
        --unused
        sleep         => '0', 
        injectdbiterr => '0',
        injectsbiterr => '0'
    );    
    assert o_error_bv_fifo_full/='1' report "FV FIFO overflow!" severity FAILURE;
    assert o_error_bv_fifo_underflow/='1' report "FV FIFO underflow!" severity FAILURE;
    
    P_UNDERFLOW: process (i_hbm_clk)
    begin
        if rising_edge(i_hbm_clk) then
            o_error_bv_fifo_underflow <= bv_fifo_empty and i_ra_ack;
        end if;            
    end process;    
    
    ra_ack      <= '1' when ra_ack_counter=g_INPUT_BLOCK_SIZE-1 and i_ra_ack='1' else '0';
    o_new_block <= '1' when ra_ack_counter=0 and i_ra_ack='1' else '0';
    
    P_RA_ACK_COUNTER: process (i_hbm_clk)
    begin
        if rising_edge(i_hbm_clk) then
            if i_hbm_rst='1' then
                ra_ack_counter <= (others => '0');
            elsif i_ra_ack='1' then    
                if ra_ack_counter=g_INPUT_BLOCK_SIZE-1 then
                    ra_ack_counter <= (others => '0');
                else    
                    ra_ack_counter <= ra_ack_counter + 1;
                end if;
            end if;        
        end if;
    end process;

end Behavioral;
