----------------------------------------------------------------------------------
-- Company:  CSIRO - CASS
-- Engineer: David Humphrey
-- 
-- Create Date: 21.11.2018 23:51:01
-- Module Name: correlatorFB_tb - Behavioral
-- Description: 
--  Testbench for the low.CBF correlator Filterbank
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.fb_types.all;

entity correlatorFB_tb is
end correlatorFB_tb;

architecture Behavioral of correlatorFB_tb is
    
    signal clk : std_logic := '0';
    signal clkCount : std_logic_vector(7 downto 0) := "00000000";
    signal rst : std_logic := '1';
    
    signal samples0, samples1, samples2, samples3 : std_logic_vector(15 downto 0);
    signal tx_rst : std_logic := '1';
    signal tx_rdy : std_logic := '0';
    signal s0Valid, s1Valid, s2Valid, s3Valid, s4Valid : std_logic; 
    
    signal data0, data1, data2, data3 : array8bit_type(1 downto 0);
    signal data0Out, data1Out, data2Out, data3Out : array16bit_type(1 downto 0);
    signal validIn, validInDel : std_logic;
    signal metaIn, metaOut : std_logic_vector(63 downto 0) := (others => '0');
    signal validOut : std_logic;
    
    signal FIRTapDataIn : std_logic_vector(17 downto 0);  -- For register writes of the filtertaps.
    signal FIRTapDataOut : std_logic_vector(17 downto 0); -- For register reads of the filtertaps. 3 cycle latency from FIRTapAddr_i
    signal FIRTapAddrIn : std_logic_vector(15 downto 0);  -- 4096 * 12 filter taps = 49152 total.
    signal FIRTapWE : std_logic;
    signal FIRTapClk : std_logic;
    
begin
    
    clk <= not clk after 1.25 ns;  -- 400 MHz
    
    -- Generate input data
    process(clk)
    begin
        if rising_edge(clk) then
            
            if clkCount /= "11111111" then
                clkCount <= std_logic_vector(unsigned(clkCount) + 1);
                rst <= '1';
            else
                rst <= '0';
            end if;
            
            if clkCount /= "11111111" and clkCount /= "11111110" then
                tx_rst <= '1';
                tx_rdy <= '0';
            else
                tx_rst <= '0';
                tx_rdy <= '1';
            end if;

            validInDel <= validIn;
            if validIn = '0' and validInDel = '1' then
                metaIn <= std_logic_vector(unsigned(metaIn) + 1);
            end if;
            
        end if;
    end process;   
    
    -- Note assumes the working directory for the simulation is 
    --   zcu111\zcu111.sim\sim_1\behav\xsim
    -- and the directory for the matlab code is
    --   matlab_model
    tx0 : entity work.packet_transmit
    generic map (
        BIT_WIDTH => 16,
        cmd_file_name => "..\..\..\..\..\filterbank_matlab\correlatorFBDin0.txt"
    )
    port map ( 
        clk     => clk,
        dout_o  => samples0, -- out std_logic_vector((BIT_WIDTH - 1) downto 0);
        valid_o => validIn,  -- out std_logic;
        rdy_i   => tx_rdy    -- in std_logic;    -- module we are sending the packet to is ready to receive data.
    );

    tx1 : entity work.packet_transmit
    generic map (
        BIT_WIDTH => 16,
        cmd_file_name => "..\..\..\..\..\filterbank_matlab\correlatorFBDin1.txt"
    )
    port map ( 
        clk     => clk,
        dout_o  => samples1, -- out std_logic_vector((BIT_WIDTH - 1) downto 0);
        valid_o => open,
        rdy_i   => tx_rdy    -- in std_logic;    -- module we are sending the packet to is ready to receive data.
    );

    tx2 : entity work.packet_transmit
    generic map (
        BIT_WIDTH => 16,
        cmd_file_name => "..\..\..\..\..\filterbank_matlab\correlatorFBDin2.txt"
    )
    port map ( 
        clk     => clk,
        dout_o  => samples2, -- out std_logic_vector((BIT_WIDTH - 1) downto 0);
        valid_o => open, 
        rdy_i   => tx_rdy    -- in std_logic;    -- module we are sending the packet to is ready to receive data.
    );

    tx3 : entity work.packet_transmit
    generic map (
        BIT_WIDTH => 16,
        cmd_file_name => "..\..\..\..\..\filterbank_matlab\correlatorFBDin3.txt"
    )
    port map ( 
        clk     => clk,
        dout_o  => samples3, -- out std_logic_vector((BIT_WIDTH - 1) downto 0);
        valid_o => open,
        rdy_i   => tx_rdy    -- in std_logic;    -- module we are sending the packet to is ready to receive data.
    );

    data0(0) <= samples0(7 downto 0);
    data0(1) <= samples0(15 downto 8);
    data1(0) <= samples1(7 downto 0);
    data1(1) <= samples1(15 downto 8);
    data2(0) <= samples2(7 downto 0);
    data2(1) <= samples2(15 downto 8);
    data3(0) <= samples3(7 downto 0);
    data3(1) <= samples3(15 downto 8);
    
    fb : entity work.correlatorFBTop25
    port map(
        -- clock, target is 380 MHz
        clk => clk,
        rst => rst,
        -- Data input, common valid signal, expects packets of 4096 samples. Requires at least 2 clocks idle time between packets.
        data0_i => data0, -- in array8bit_type(1 downto 0);  -- 4 Inputs, each complex data, 8 bit real, 8 bit imaginary.
        data1_i => data1, -- in array8bit_type(1 downto 0);
        data2_i => data2, -- in array8bit_type(1 downto 0);
        data3_i => data3, -- in array8bit_type(1 downto 0);
        meta_i  => metaIn, -- in(63:0)
        valid_i => validIn, -- in std_logic;
        -- Data out; bursts of 3456 clocks for each channel.
        data0_o => data0Out, -- out array16bit_type(1 downto 0);   -- 4 outputs, real and imaginary parts in (0) and (1) respectively;
        data1_o => data1Out, -- out array16bit_type(1 downto 0);
        data2_o => data2Out, -- out array16bit_type(1 downto 0);
        data3_o => data3Out, -- out array16bit_type(1 downto 0);
        meta_o  => metaOut,  -- out(63:0)
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
    
    log0 : entity work.packet_receive
    Generic map (
        BIT_WIDTH => 16,
        log_file_name => "..\..\..\..\..\filterbank_matlab\correlatorFBDout0_log.txt"
    )
    Port map (
        clk     => clk, -- in  std_logic;     -- clock
        rst_i   => rst,  -- in  std_logic;     -- reset input
        din0_i  => data0Out(0), -- in  std_logic_vector((BIT_WIDTH - 1) downto 0);  -- actual data out.
        din1_i  => data0Out(1),
        valid_i => validOut, -- in  std_logic;     -- data out valid (high for duration of the packet)
        rdy_o   => open         -- out std_logic      -- module we are sending the packet to is ready to receive data.
    );

    log1 : entity work.packet_receive
    Generic map (
        BIT_WIDTH => 16,
        log_file_name => "..\..\..\..\..\filterbank_matlab\correlatorFBDout1_log.txt"
    )
    Port map (
        clk     => clk, -- in  std_logic;     -- clock
        rst_i   => rst,  -- in  std_logic;     -- reset input
        din0_i  => data1Out(0), -- in  std_logic_vector((BIT_WIDTH - 1) downto 0);  -- actual data out.
        din1_i  => data1Out(1),
        valid_i => validOut,    -- in  std_logic;     -- data out valid (high for duration of the packet)
        rdy_o   => open         -- out std_logic      -- module we are sending the packet to is ready to receive data.
    );

    log2 : entity work.packet_receive
    Generic map (
        BIT_WIDTH => 16,
        log_file_name => "..\..\..\..\..\filterbank_matlab\correlatorFBDout2_log.txt"
    )
    Port map (
        clk     => clk, -- in  std_logic;     -- clock
        rst_i   => rst,  -- in  std_logic;     -- reset input
        din0_i  => data2Out(0), -- in  std_logic_vector((BIT_WIDTH - 1) downto 0);  -- actual data out.
        din1_i  => data2Out(1),
        valid_i => validOut,    -- in  std_logic;     -- data out valid (high for duration of the packet)
        rdy_o   => open         -- out std_logic      -- module we are sending the packet to is ready to receive data.
    );
    
    log3 : entity work.packet_receive
    Generic map (
        BIT_WIDTH => 16,
        log_file_name => "..\..\..\..\..\filterbank_matlab\correlatorFBDout3_log.txt"
    )
    Port map (
        clk     => clk,  -- in  std_logic;     -- clock
        rst_i   => rst,  -- in  std_logic;     -- reset input
        din0_i  => data3Out(0), -- in  std_logic_vector((BIT_WIDTH - 1) downto 0);  -- actual data out.
        din1_i  => data3Out(1),
        valid_i => validOut, -- in  std_logic;     -- data out valid (high for duration of the packet)
        rdy_o   => open         -- out std_logic      -- module we are sending the packet to is ready to receive data.
    );
    
end Behavioral;
