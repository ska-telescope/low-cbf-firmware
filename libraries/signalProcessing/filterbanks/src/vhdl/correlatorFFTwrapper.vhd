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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity correlatorFFTwrapper is
    port(
        clk : in std_logic;
        -- Input
        real_i  : in std_logic_vector(15 downto 0); -- 16 bit real data
        imag_i  : in std_logic_vector(15 downto 0); -- 16 bit imaginary data
        start_i : in std_logic;                     -- pulse high; one clock in advance of the data ?
        -- Output
        real_o  : out std_logic_vector(15 downto 0);
        imag_o  : out std_logic_vector(15 downto 0);
        index_o : out std_logic_vector(11 downto 0);
        valid_o : out std_logic
    );
end correlatorFFTwrapper;

architecture Behavioral of correlatorFFTwrapper is

    -- Tcl:
    --  create_ip -name xfft -vendor xilinx.com -library ip -version 9.1 -module_name fft4096_16bit -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --  set_property -dict [list CONFIG.Component_Name {fft4096_16bit} CONFIG.transform_length {4096} CONFIG.implementation_options {pipelined_streaming_io} CONFIG.xk_index {true} CONFIG.throttle_scheme {realtime} CONFIG.complex_mult_type {use_mults_performance} CONFIG.number_of_stages_using_block_ram_for_data_and_phase_factors {5}] [get_ips fft4096_16bit]
    component fft4096_16bit
    port (
        aclk : in std_logic;
        s_axis_config_tdata  : in std_logic_vector(15 downto 0);
        s_axis_config_tvalid : in std_logic;
        s_axis_config_tready : out std_logic;
        s_axis_data_tdata    : in std_logic_vector(31 downto 0);
        s_axis_data_tvalid   : in std_logic;
        s_axis_data_tready   : out std_logic;
        s_axis_data_tlast    : in std_logic;
        m_axis_data_tdata    : out std_logic_vector(31 downto 0);
        m_axis_data_tuser    : out std_logic_vector(15 downto 0);
        m_axis_data_tvalid   : out std_logic;
        m_axis_data_tlast    : out std_logic;
        event_frame_started  : out std_logic;
        event_tlast_unexpected : out std_logic;
        event_tlast_missing    : out std_logic;
        event_data_in_channel_halt  : out std_logic);
    end component;

    -- Simple dual port memory for double buffering of the FFT Output.
    -- 7168 deep by 32 bits wide.
    -- 2 cycle read latency.
    -- Tcl : 
    --  create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name CorrelatorFBReorderMem -dir C:/projects/perentie/xilinx_test_projects/filterbank_ip
    --  set_property -dict [list CONFIG.Component_Name {CorrelatorFBReorderMem} CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Write_Width_A {32} CONFIG.Write_Depth_A {7168} CONFIG.Read_Width_A {32} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {32} CONFIG.Read_Width_B {32} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Fill_Remaining_Memory_Locations {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100} CONFIG.Collision_Warnings {GENERATE_X_ONLY} CONFIG.Disable_Collision_Warnings {true} CONFIG.Disable_Out_of_Range_Warnings {true}] [get_ips CorrelatorFBReorderMem]
    component CorrelatorFBReorderMem
    port (
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(12 downto 0);
        dina  : in std_logic_vector(31 downto 0);
        clkb  : in std_logic;
        addrb : in std_logic_vector(12 downto 0);
        doutb : out std_logic_vector(31 downto 0));
    end component;
    
    signal scalingConfig : std_logic_vector(15 downto 0);
    signal dataValid : std_logic;
    signal firstFFTSample : std_logic := '0';
    signal tlastIn : std_logic;
    signal validCount : std_logic_vector(12 downto 0) := "1000000000000";
    signal fft_tlast : std_logic;
    signal validOut : std_logic;
    signal configtrdy : std_logic;
    signal trdy : std_logic;
    signal fftDin, fftDout : std_logic_vector(31 downto 0);
    signal realDel1, realDel2 : std_logic_vector(15 downto 0);
    signal imagDel1, imagDel2 : std_logic_vector(15 downto 0);
    signal fftIndex : std_logic_vector(15 downto 0);
    signal fft_frame_started, fft_tlast_unexpected, fft_tlast_missing, fft_data_halt : std_logic;
    signal realInt, imagInt : std_logic_vector(15 downto 0);
    
begin

    -- bit(0) = fwd_inv, set to '1' for forward transform
    -- bits(12:1) = scaling schedule, set to "101010101010" for 2 bits per two stages.
    scalingConfig <= "0001110101010101";

    process(clk)
    begin
        if rising_edge(clk) then
            if start_i = '1' then
               dataValid <= '1';
               --infoInt <= info_i;
               validCount <= (others => '0');
               firstFFTSample <= '1';
            elsif (unsigned(validCount) < 4096) then
               validCount <= std_logic_vector(unsigned(validCount) + 1);
               dataValid <= '1';
               firstFFTSample <= '0';
            else
               dataValid <= '0';
               firstFFTSample <= '0';
            end if;
            
            if (unsigned(validCount) = 4095) then
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
        
    fft4096 : fft4096_16bit
    port map (
        aclk => clk,
        s_axis_config_tdata  => scalingConfig, -- in(15:0);
        s_axis_config_tvalid => '1',           -- in std_logic;
        s_axis_config_tready => configtrdy,    -- out std_logic;
        s_axis_data_tdata    => fftDin,        -- in(31:0);
        s_axis_data_tvalid   => dataValid,     -- in std_logic;
        s_axis_data_tready   => trdy,          -- out std_logic;
        s_axis_data_tlast    => tlastIn,       -- in std_logic;
        m_axis_data_tdata    => fftDout,       -- out(31:0);
        m_axis_data_tuser    => fftIndex,      -- out std_logic_vector(15 downto 0);
        m_axis_data_tvalid   => validOut,      -- out std_logic;
        m_axis_data_tlast    => fft_tlast,     -- out std_logic;
        event_frame_started  => fft_frame_started,      -- out std_logic;
        event_tlast_unexpected => fft_tlast_unexpected, -- out std_logic;
        event_tlast_missing    => fft_tlast_missing,    -- out std_logic;
        event_data_in_channel_halt  => fft_data_halt    -- out std_logic;
    );    
    
    -- Divide the output by 2 with rounding
   -- realInt <= fftDout(15) & fftDout(15 downto 1);
   -- imagInt <= fftDout(31) & fftDout(31 downto 17);
    
   -- real_o <= realInt when fftDout(0) = '0' else std_logic_vector(unsigned(realInt) + 1);
   -- imag_o <= imagInt when fftDout(16) = '0' else std_logic_vector(unsigned(imagInt) + 1);
    
    real_o <= fftDout(15 downto 0);
    imag_o <= fftDout(31 downto 16);
    
    index_o <= fftIndex(11 downto 0);
    valid_o <= validOut;
    
end Behavioral;
