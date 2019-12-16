----------------------------------------------------------------------------------
-- Company: CSIRO - CASS
-- Engineer: David Humphrey (dave.humphrey@csiro.au)
-- 
-- Create Date: 03.12.2018 16:33:21
-- Module Name: correlatorFFTwrapper - Behavioral
-- Description: 
--  Wrapper for the correlator 4096 point FFT. Outputs 3456 fine channels in order from low frequency to high.
--  
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PSSFFTwrapper is
    port(
        clk : in std_logic;
        -- Input
        real_i  : in std_logic_vector(15 downto 0); -- 16 bit real data
        imag_i  : in std_logic_vector(15 downto 0); -- 16 bit imaginary data
        start_i : in std_logic;                     -- pulse high; one clock in advance of the data.
        -- Output
        real_o  : out std_logic_vector(15 downto 0);
        imag_o  : out std_logic_vector(15 downto 0);
        index_o : out std_logic_vector(5 downto 0);
        valid_o : out std_logic
    );
end PSSFFTwrapper;

architecture Behavioral of PSSFFTwrapper is

    -- Tcl:
    --  create_ip -name xfft -vendor xilinx.com -library ip -version 9.1 -module_name fft64_16bit -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --  set_property -dict [list CONFIG.Component_Name {fft64_16bit} CONFIG.transform_length {64} CONFIG.xk_index {true}  CONFIG.implementation_options {pipelined_streaming_io} CONFIG.throttle_scheme {realtime} CONFIG.complex_mult_type {use_mults_performance} CONFIG.number_of_stages_using_block_ram_for_data_and_phase_factors {0}] [get_ips fft64_16bit]
    component fft64_16bit
    port (
        aclk : in std_logic;
        s_axis_config_tdata  : in std_logic_vector(7 downto 0);
        s_axis_config_tvalid : in std_logic;
        s_axis_config_tready : out std_logic;
        s_axis_data_tdata    : in std_logic_vector(31 downto 0);
        s_axis_data_tvalid   : in std_logic;
        s_axis_data_tready   : out std_logic;
        s_axis_data_tlast    : in std_logic;
        m_axis_data_tdata    : out std_logic_vector(31 downto 0);
        m_axis_data_tuser    : out std_logic_vector(7 downto 0);
        m_axis_data_tvalid   : out std_logic;
        m_axis_data_tlast    : out std_logic;
        event_frame_started  : out std_logic;
        event_tlast_unexpected : out std_logic;
        event_tlast_missing    : out std_logic;
        event_data_in_channel_halt  : out std_logic);
    end component;
    
    signal scalingConfig : std_logic_vector(7 downto 0);
    signal dataValid : std_logic;
    signal firstFFTSample : std_logic := '0';
    signal tlastIn : std_logic;
    signal validCount : std_logic_vector(6 downto 0) := "1000000";
    signal fft_tlast : std_logic;
    signal validOut : std_logic;
    signal configtrdy : std_logic;
    signal trdy : std_logic;
    signal fftDin, fftDout : std_logic_vector(31 downto 0);
    signal realDel1, realDel2 : std_logic_vector(15 downto 0);
    signal imagDel1, imagDel2 : std_logic_vector(15 downto 0);
    signal fftIndex : std_logic_vector(7 downto 0);
    signal fft_frame_started, fft_tlast_unexpected, fft_tlast_missing, fft_data_halt : std_logic;
    signal reScaled : std_logic_vector(15 downto 0);
    signal imScaled : std_logic_vector(15 downto 0);
    
begin

    -- bit(0) = fwd_inv, set to '1' for forward transform
    -- bits(6:1) = scaling schedule, set to "101010" for 2 bits per two stages. 
    scalingConfig <= "01010101";

    process(clk)
    begin
        if rising_edge(clk) then
            if start_i = '1' then
               dataValid <= '1';
               --infoInt <= info_i;
               validCount <= (others => '0');
               firstFFTSample <= '1';
            elsif (unsigned(validCount) < 64) then
               validCount <= std_logic_vector(unsigned(validCount) + 1);
               dataValid <= '1';
               firstFFTSample <= '0';
            else
               dataValid <= '0';
               firstFFTSample <= '0';
            end if;
            
            if (unsigned(validCount) = 63) then
                tlastIn <= '1';
            else
                tlastIn <= '0';
            end if; 
        end if;
    end process;
    

    -- The Xilinx FFT has this weird thing where it de-asserts trdy on the second clock cycle in "real-time" mode
    -- This is a hack to make it work; the first sample goes straight in, the subsequent samples are delayed by one.
    process(clk)
    begin
        if rising_edge(clk) then
            realDel1 <= real_i;
            imagDel1 <= imag_i;
            
            realDel2 <= realDel1;
            imagDel2 <= imagDel1;
            
        end if;
    end process;
        
    fftDin <= imag_i & real_i when firstFFTSample = '1' else imagDel1 & realDel1;
        
    fft64 : fft64_16bit
    port map (
        aclk => clk,
        s_axis_config_tdata  => scalingConfig, -- in(7:0);
        s_axis_config_tvalid => '1',           -- in std_logic;
        s_axis_config_tready => configtrdy,    -- out std_logic;
        s_axis_data_tdata    => fftDin,        -- in(31:0);
        s_axis_data_tvalid   => dataValid,     -- in std_logic;
        s_axis_data_tready   => trdy,          -- out std_logic;
        s_axis_data_tlast    => tlastIn,       -- in std_logic;
        m_axis_data_tdata    => fftDout,       -- out(31:0);
        m_axis_data_tuser    => fftIndex,      -- out std_logic_vector(7 downto 0);
        m_axis_data_tvalid   => validOut,      -- out std_logic;
        m_axis_data_tlast    => fft_tlast,     -- out std_logic;
        event_frame_started  => fft_frame_started,      -- out std_logic;
        event_tlast_unexpected => fft_tlast_unexpected, -- out std_logic;
        event_tlast_missing    => fft_tlast_missing,    -- out std_logic;
        event_data_in_channel_halt  => fft_data_halt    -- out std_logic;
    );    
    
    -- final scaling by a factor of 16
    reScaled <= fftDout(15) & fftDout(15) & fftDout(15) & fftDout(15) & fftDout(15 downto 4);
    imScaled <= fftDout(31) & fftDout(31) & fftDout(31) & fftDout(31) & fftDout(31 downto 20);
    
    real_o <= reScaled when fftDout(3) = '0' else std_logic_vector(unsigned(reScaled) + 1);
    imag_o <= imScaled when fftDout(19) = '0' else std_logic_vector(unsigned(imScaled) + 1);
    index_o <= fftIndex(5 downto 0);
    valid_o <= validOut;
    
    
end Behavioral;
