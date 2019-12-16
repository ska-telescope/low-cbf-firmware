----------------------------------------------------------------------------------
-- Company: CSIRO 
-- Engineer: David Humphrey (dave.humphrey@csiro.au)
-- 
-- Create Date: 02.04.2019 13:40:03
-- Module Name: IC_LFAAInput - Behavioral
-- Description: 
--  Takes in packets from the LFAA Ingest pipeline.
--  Input packets have a 128bit wide interface, and their own clock.
--  Output side uses the common interconnect clock.
-- 
-- Structure:
--
--  i_data  ==>  fifo1 ==>  to URAM_buffer (via 64 bit output bus o_data1, o_valid1, o_sof1, o_eof1)
--               fifo2 ==>  to URAM_buffer (via 64 bit output bus o_data2, o_valid2, o_sof2, o_eof2)
--               
--  i_data_clk <--|--> i_IC_clk 
--
-- The fifos do a few jobs :
--  + Cross from the 312.5 MHz clock to the 400 MHz interconnect clock
--  + Change from 128 bit wide to 64 bit data bus
--  + Buffer so that we can absorb bursts - the data rate in, 128bits@312.5MHz exceeds the data rate out, 64bits@400MHz
--    - To do this, we alternate packets between the two FIFOs
--    - If both FIFOs are empty, then packets with an even virtual channel go to FIFO1, and odd virtual channel go to FIFO2
--       * Since packets should come in a burst of 8 virtual channels, this should mean that FIFO1 always has even virtual channels, and FIFO2 always has odd virtual channels.      
--
----------------------------------------------------------------------------------

library IEEE, axi4_lib, interconnect_lib;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
Library xpm;
use xpm.vcomponents.all;

entity IC_LFAAInput is
    generic(
        -- 0 = 3 FPGAs (X x Y x Z = 1x1x3), 1 = 12 FPGAs (X x Y x Z = 1x6x2), 2 = etc....
        -- See confluence page (perentie - Model development - packetised model overview - model configuration)    
        ARRAYRELEASE : integer range 0 to 5 := 0 
    );
    port(
        -- Configuration (on i_IC_clk)
        i_myAddr : in std_logic_vector(11 downto 0); -- X, Y and Z coordinates of this FPGA.
        -- Packet Data input
        i_data     : in std_logic_vector(127 downto 0);
        i_valid    : in std_logic;
        i_data_clk : in std_logic;  -- LFAA ingest pipeline clock; 312.5 MHz, from the 40GE input
        -- Packets output.
        -- Two output interfaces, one for even and one for odd indexed virtual channels.
        i_IC_clk : in std_logic;     -- Interconnect clock (about 400 MHz)
        o_data1  : out std_logic_vector(63 downto 0);
        o_valid1 : out std_logic;
        o_sof1   : out std_logic;
        o_eof1   : out std_logic;
        o_data2  : out std_logic_vector(63 downto 0);
        o_valid2 : out std_logic;
        o_sof2   : out std_logic;
        o_eof2   : out std_logic;
        -- status - Output on i_IC_clk
        o_LFAADrop : out std_logic; -- input packet from LFAA was dropped since neither FIFO was empty; should be impossible.
        o_overflow : out std_logic
    );
end IC_LFAAInput;

architecture Behavioral of IC_LFAAInput is

    signal dataDel1 : std_logic_vector(127 downto 0);
    signal validDel1, validDel2 : std_logic;
    signal fifo1WrEn, fifo1Empty : std_logic;
    signal fifo2WrEn, fifo2Empty : std_logic;
    signal fifoDin : std_logic_vector(131 downto 0);
    signal fifo1Dout, fifo2Dout : std_logic_vector(65 downto 0);
    signal LFAADrop, LFAADropDel1 : std_logic := '0';

    signal bufDin1, bufDin2 : std_logic_vector(63 downto 0);
    signal bufDin1Valid, bufDin2Valid : std_logic;
    signal virtualChannel : std_logic_vector(8 downto 0);
    
    signal LFAADrop_data_clk : std_logic;
    
begin
    
    o_overflow <= '0';
    
    -- xpm_cdc_pulse: Pulse Transfer
    -- Xilinx Parameterized Macro, version 2019.1

    xpm_cdc_pulse_inst : xpm_cdc_pulse
    generic map (
        DEST_SYNC_FF => 2,   -- DECIMAL; range: 2-10
        INIT_SYNC_FF => 0,   -- DECIMAL; 0=disable simulation init values, 1=enable simulation init values
        REG_OUTPUT => 1,     -- DECIMAL; 0=disable registered output, 1=enable registered output
        RST_USED => 0,       -- DECIMAL; 0=no reset, 1=implement reset
        SIM_ASSERT_CHK => 0  -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    )
    port map (
        dest_pulse => o_LFAADrop, -- 1-bit output: Outputs a pulse the size of one dest_clk period when a pulse
                                  -- transfer is correctly initiated on src_pulse input. This output is
                                  -- combinatorial unless REG_OUTPUT is set to 1.
        dest_clk => i_IC_clk,     -- 1-bit input: Destination clock.
        dest_rst => '0',          -- 1-bit input: optional; required when RST_USED = 1
        src_clk => i_data_clk,    -- 1-bit input: Source clock.
        src_pulse => LFAADrop_data_clk, -- 1-bit input: Rising edge of this signal initiates a pulse transfer to the destination clock domain. 
        src_rst => '0'        -- 1-bit input: optional; required when RST_USED = 1
    );
    
    
    ---------------------------------------------------------------------------------
    -- FIFO write side
    ---------------------------------------------------------------------------------
    
    process(i_data_clk)
    begin
        if rising_edge(i_data_clk) then
            
            dataDel1 <= i_data;
            validDel1 <= i_valid;
            if i_valid = '1' and validDel1 = '0' then
                virtualChannel <= i_data(8 downto 0);
            end if;
            
            --
            validDel2 <= validDel1;
            fifoDin(63 downto 0) <= dataDel1(63 downto 0);
            fifoDin(129 downto 66) <= dataDel1(127 downto 64);
            if validDel1 = '1' and validDel2 = '0' then
                fifoDin(65 downto 64) <= "01";  -- first word in a frame
                fifoDin(131 downto 130) <= "00";
            elsif i_valid = '0' and validDel1 = '1' then
                fifoDin(65 downto 64) <= "00";  
                fifoDin(131 downto 130) <= "10";  -- Last word in a frame
            elsif validDel1 = '1' then
                fifoDin(65 downto 64) <= "00";  
                fifoDin(131 downto 130) <= "00";
            else -- This case should not go into the FIFO 
                fifoDin(65 downto 64) <= "11";
                fifoDin(131 downto 130) <= "11";
            end if;
            
            if validDel1 = '1' and validDel2 = '0' then
                -- data_del1 has the first word of the packet; Work out which fifo to put it into.
                if fifo1Empty = '1' and fifo2Empty = '1' then
                    -- Both empty, even virtual channels go to fifo1, odd to fifo2
                    if virtualChannel(0) = '0' then
                        fifo1WrEn <= '1';
                        fifo2WrEn <= '0';
                    else
                        fifo1WrEn <= '0';
                        fifo2WrEn <= '1';
                    end if;
                elsif fifo1Empty = '1' and fifo2Empty = '0' then -- Must have just used fifo2, now use fifo1
                    fifo1WrEn <= '1';
                    fifo2WrEn <= '0';
                elsif fifo1Empty = '0' and fifo2Empty = '1' then -- Must have just used fifo1, now use fifo2
                    fifo1WrEn <= '0';
                    fifo2WrEn <= '1';
                else -- This should be impossible, since the FIFO read rate is more than half the fifo write rate.
                    LFAADrop <= '1';
                end if;
            elsif validDel1 = '0' then
                LFAADrop <= '0';
                fifo1WrEn <= '0';
                fifo2WrEn <= '0';
            end if;
            
            LFAADropDel1 <= LFAADrop;
            if LFAADrop = '1' and LFAADropDel1 = '0' then
                LFAADrop_data_clk <= '1';
            else
                LFAADrop_data_clk <= '0';
            end if;
            
        end if;
    end process;
    
    
    -- dual clock FIFO
    -- 132 bit input, 66 bit output.
    -- Top 2 bits of each 66 bit word are used to indicate start and end of frame :
    --  "01" = first word in frame
    --  "10" = last word in frame
    --  "11" = invalid
    --  "00" = data word (not first or last).
    --
    -- There are two instances of this FIFO because the write rate can temporarily exceed the read rate.
    -- Note : Time to write a frame (312.5 MHz clock) = 513 * 3.2ns = 1641 ns
    --        Time to read a frame (400 MHz clock) = 1026 * 2.5ns = 2565 ns = 1.56 x the time to write.
    --
    fifo1 : entity interconnect_lib.IC_LFAAInputFifo
    generic map (
        -- 0 = 3 FPGAs (X x Y x Z = 1x1x3), 1 = 12 FPGAs (X x Y x Z = 1x6x2), 2 = etc....
        -- See confluence page (perentie - Model development - packetised model overview - model configuration)    
        ARRAYRELEASE => ARRAYRELEASE
    ) port map (
        -- Configuration (on i_IC_clk)
        i_myAddr => i_myAddr,
        -- FIFO data input interface
        i_data_clk => i_data_clk,
        i_data_rst => '0',
        i_fifoDin  => fifoDin,     -- in(131:0);
        i_fifoWr    => fifo1WrEn,  -- in std_logic;
        o_fifoEmpty => fifo1Empty, -- in std_logic;
        -- Packets output to the URAM buffer
        i_IC_clk => i_IC_clk, --  in std_logic;     -- Interconnect clock (about 400 MHz)
        o_data   => o_data1,  --  out(63:0);
        o_valid  => o_valid1, --  out std_logic
        o_sof    => o_sof1,
        o_eof    => o_eof1
    );
    
    fifo2 : entity interconnect_lib.IC_LFAAInputFifo
    generic map (
        -- 0 = 3 FPGAs (X x Y x Z = 1x1x3), 1 = 12 FPGAs (X x Y x Z = 1x6x2), 2 = etc....
        -- See confluence page (perentie - Model development - packetised model overview - model configuration)    
        ARRAYRELEASE => ARRAYRELEASE
    ) port map (
        -- Configuration (on i_IC_clk)
        i_myAddr => i_myAddr,
        -- FIFO data input interface
        i_data_clk => i_data_clk,
        i_data_rst => '0',
        i_fifoDin  => fifoDin,     -- in(131:0);
        i_fifoWr    => fifo2WrEn,  -- in std_logic;
        o_fifoEmpty => fifo2Empty, -- in std_logic;
        -- Packets output to the URAM buffer
        i_IC_clk => i_IC_clk,      -- in std_logic;     -- Interconnect clock (about 400 MHz)
        o_data   => o_data2,       -- out(63:0);
        o_valid  => o_valid2,      -- out std_logic
        o_sof    => o_sof2,
        o_eof    => o_eof2
    );
    
    
end Behavioral;
