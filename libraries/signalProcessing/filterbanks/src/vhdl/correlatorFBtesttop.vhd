----------------------------------------------------------------------------------
-- Company: CSIRO - CASS 
-- Engineer: David Humphrey
-- 
-- Create Date: 04.12.2018 16:17:07
-- Module Name: correlatorFBtesttop - Behavioral
-- Description: 
--  Top level to test place and route of the correlator filterbank. 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.fb_types.all;

entity correlatorFBtesttop is
    port(
        clkin : in std_logic;
        din  : in std_logic;
        dout : out std_logic_vector(15 downto 0)
     );
end correlatorFBtesttop;

architecture Behavioral of correlatorFBtesttop is

    component clk_wiz_0
    port (
        clk400out : out std_logic;
        clk100in  : in  std_logic);
    end component;

    signal clk400 : std_logic;
    signal rst400 : std_logic;
    signal rstCount : std_logic_vector(7 downto 0) := "11111111";
    signal validIn, validOut : std_logic;
    
    signal din1 : array8bit_type(7 downto 0);
    signal data0, data1, data2, data3 : array8bit_type(1 downto 0);
    signal data0Out, data1Out, data2Out, data3Out : array16bit_type(1 downto 0);
    
    signal FIRTapDataIn : std_logic_vector(17 downto 0);  -- For register writes of the filtertaps.
    signal FIRTapDataOut : std_logic_vector(17 downto 0); -- For register reads of the filtertaps. 3 cycle latency from FIRTapAddr_i
    signal FIRTapAddrIn : std_logic_vector(15 downto 0);  -- 4096 * 12 filter taps = 49152 total.
    signal FIRTapWE : std_logic;
    signal FIRTapClk : std_logic;
    signal metain, metaout : std_logic_vector(63 downto 0);
    
begin
    
    c1 : clk_wiz_0
    port map (
        clk100in => clkin,
        clk400out => clk400
    );
    
    process(clk400)
    begin
        if rising_edge(clk400) then
            if rstCount /= "00000000" then
                rst400 <= '1';
                rstCount <= std_logic_vector(unsigned(rstCount) - 1);
            else
                rst400 <= '0';
            end if;        
        
            for i in 0 to 7 loop
                if rst400 = '1' then
                    din1(i) <= std_logic_vector(to_unsigned(i,8));
                else
                    din1(i) <= std_logic_vector(unsigned(din1(i)) + 1);
                end if;
            end loop;
            
            validIn <= rstCount(2); 
            
            if rstCount(5 downto 2) = "0000" then
                dout <= data0Out(0);
            elsif rstCount(5 downto 2) = "0001" then
                dout <= data0Out(1);
            elsif rstCount(5 downto 2) = "0010" then
                dout <= data1Out(0);
            elsif rstCount(5 downto 2) = "0011" then
                dout <= data1Out(1);
            elsif rstCount(5 downto 2) = "0100" then
                dout <= data2Out(0);
            elsif rstCount(5 downto 2) = "0101" then
                dout <= data2Out(1);
            elsif rstCount(5 downto 2) = "0110" then
                dout <= data3Out(0);
            elsif rstCount(5 downto 2) = "0111" then
                dout <= data3Out(1);
            else
                dout <= metaout(15 downto 0);
            end if;
            
        end if;
    end process;
    
    metain(15 downto 0) <= din1(1) & din1(0);
    metain(63 downto 16) <= (others => '0');
    
    data0(0) <= din1(0);
    data0(1) <= din1(1);
    data1(0) <= din1(2);
    data1(1) <= din1(3);
    data2(0) <= din1(4);
    data2(1) <= din1(5);
    data3(0) <= din1(6);
    data3(1) <= din1(7);
    
    fb : entity work.correlatorFBTop25
    port map(
        -- clock, target is 380 MHz
        clk => clk400,
        rst => rst400,
        -- Data input, common valid signal, expects packets of 4096 samples. Requires at least 2 clocks idle time between packets.
        data0_i => data0, -- in array8bit_type(1 downto 0);  -- 4 Inputs, each complex data, 8 bit real, 8 bit imaginary.
        data1_i => data1, -- in array8bit_type(1 downto 0);
        data2_i => data2, -- in array8bit_type(1 downto 0);
        data3_i => data3, -- in array8bit_type(1 downto 0);
        meta_i  => metain,
        valid_i => validIn, -- in std_logic;
        -- Data out; bursts of 3456 clocks for each channel.
        data0_o => data0Out, -- out array16bit_type(1 downto 0);   -- 4 outputs, real and imaginary parts in (0) and (1) respectively;
        data1_o => data1Out, -- out array16bit_type(1 downto 0);
        data2_o => data2Out, -- out array16bit_type(1 downto 0);
        data3_o => data3Out, -- out array16bit_type(1 downto 0);
        meta_o  => metaout,
        valid_o => validOut, -- out std_logic;
        -- Writing FIR Taps
        FIRTapData_i => FIRTapDataIn,  -- in std_logic_vector(17 downto 0);  -- For register writes of the filtertaps.
        FIRTapData_o => FIRTapDataOut, -- out std_logic_vector(17 downto 0); -- For register reads of the filtertaps. 3 cycle latency from FIRTapAddr_i
        FIRTapAddr_i => FIRTapAddrIn,  -- in std_logic_vector(15 downto 0);  -- 4096 * 12 filter taps = 49152 total.
        FIRTapWE_i   => FIRTapWE,      -- in std_logic;
        FIRTapClk    => FIRTapClk      -- in std_logic
    );
    
    FIRTapDataIn <= (others => '0');
    FIRTapAddrIn <= (others => '0');
    FIRTapWE <= '0';
    FIRTapClk <= '0';
    
     
end Behavioral;
