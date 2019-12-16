----------------------------------------------------------------------------------
-- Company: CSIRO
-- Engineer: David Humphrey
-- 
-- Create Date: 14.03.2019 10:06:50
-- Module Name: common_counter_dc - Behavioral
-- Description: 
--  Dual clock saturating counter, intended to be used for registers in conjunction with ARGs.
--  Counts up by one every src_clk in which count_up is high.
-- Notes:
--  * dest_clk is assumed to be slower than src_clk.
--    In the intended use case, it is assumed that dest_clk is the domain of ARGs memory mapped (MM) slave, 
--  * Since the counter value has to be transferred to the MM slave, putting the counter in the slave
--    domain minimises the resources used.
--  * Placing the counter in the slower dest_clk domain also makes timing easy to meet for wide counters.  
--  * src_clk may count many times in one dest_clk (e.g. typical use case, src_clk = 500 MHz, dest_clk = 100 MHz
--    so to ensure no counts are lost, a small counter is used in the src_clk domain. Whenever it is
--    non-zero, it is copied to a second register, which holds the value until it is added to the full width 
--    adder in the dest_clk domain. 
--   
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
Library xpm;
use xpm.vcomponents.all;

entity common_counter_dc is
    generic(
        FULLCOUNT_WIDTH : natural := 32;  -- width of the full counter in the dest_clk domain
        TEMPCOUNT_WIDTH : natural := 4   -- width of the temporary counter in the src_clk domain
    );
    port(
        -- Input side
        src_clk : in std_logic;
        countUp : in std_logic;
        -- Output side
        dest_clk   : in std_logic;
        rst        : in std_logic;
        countValue : out std_logic_vector(FULLCOUNT_WIDTH-1 downto 0)
    );
end common_counter_dc;

architecture Behavioral of common_counter_dc is

    signal tempCount : std_logic_vector(TEMPCOUNT_WIDTH-1 downto 0);
    signal tempCountHold : std_logic_vector(TEMPCOUNT_WIDTH-1 downto 0);
    
    signal transfer : std_logic;
    signal tempCountSend : std_logic;
    signal tempCountSent : std_logic;
    
    signal dest_valid : std_logic;
    signal tempCountHoldDest : std_logic_vector(TEMPCOUNT_WIDTH-1 downto 0);
    
    signal countInt : std_logic_vector(FULLCOUNT_WIDTH -1 downto 0);
    signal countIntNew : std_logic_vector(FULLCOUNT_WIDTH downto 0);
    
begin
    
    process(src_clk)
    begin
        if rising_edge(src_clk) then
            if countUp = '1' and transfer = '0' then
                tempCount <= std_logic_vector(unsigned(tempCount) + 1);
            elsif countUp = '0' and transfer = '1' then
                tempCount <= (others => '0');
                tempCountHold <= tempCount;
            elsif countUp = '1' and transfer = '1' then
                tempCount <= std_logic_vector(to_unsigned(1,TEMPCOUNT_WIDTH));
                tempCountHold <= tempCount;
            end if;
            
            if transfer = '1' then
                tempCountSend <= '1';
            elsif tempCountSent = '1' then
                tempCountSend <= '0';
            end if;
            
        end if;
    end process;
    
    transfer <= '1' when ((unsigned(tempCount) /= 0) and (tempCountSend = '0')) else '0';
    
    
    -- Send tempCountHold to the other clock domain
    -- xpm_cdc_handshake: Clock Domain Crossing Bus Synchronizer with Full Handshake
    -- Xilinx Parameterized Macro, Version 2017.4
    xpm_cdc_handshake_inst:  xpm_cdc_handshake
    generic map (
        -- Common module generics
        DEST_EXT_HSK   => 0, -- integer; 0=internal handshake, 1=external handshake
        DEST_SYNC_FF   => 2, -- integer; range: 2-10
        INIT_SYNC_FF   => 0, -- integer; 0=disable simulation init values, 1=enable simulation init values
        SIM_ASSERT_CHK => 0, -- integer; 0=disable simulation messages, 1=enable simulation messages
        SRC_SYNC_FF    => 2, -- integer; range: 2-10
        WIDTH          => TEMPCOUNT_WIDTH)  -- integer; range: 1-1024
    port map (    
        src_clk  => src_clk,
        src_in   => tempCountHold,
        src_send => tempCountSend,
        src_rcv  => tempCountSent,
        dest_clk => dest_clk,
        dest_req => dest_valid,
        dest_ack => '1', -- optional; required when DEST_EXT_HSK = 1
        dest_out => tempCountHoldDest
    );
    
    
    -- saturating counter in the dest_clk domain
    countIntNew <= std_logic_vector(unsigned(countInt) + unsigned(tempCountHoldDest));
    
    process(dest_clk)
    begin
        if rising_edge(dest_clk) then
            if rst = '1' then
                countInt <= (others => '0');
            elsif dest_valid = '1' then -- new data from the other clock domain is available.
                if countIntNew(FULLCOUNT_WIDTH) = '1'  then
                    countInt <= (others => '1'); -- saturated.
                else
                    countInt <= countIntNew(FULLCOUNT_WIDTH-1 downto 0);
                end if;
            end if;
        end if;
    end process;
    
    countValue <= countInt;
    
end Behavioral;


