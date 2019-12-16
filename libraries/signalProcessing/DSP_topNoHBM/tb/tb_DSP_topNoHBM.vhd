----------------------------------------------------------------------------------
-- Company: CSIRO 
-- Engineer: David Humphrey (dave.humphrey@csiro.au)
-- 
-- Create Date: 20 August 2019 
-- Module Name: tb_DSP_top - Behavioral
-- Description: 
--  Testbench for the Perentie signal processing code.
-- 
----------------------------------------------------------------------------------

library IEEE;
library LFAADecode_lib, timingControl_lib, capture128bit_lib, interconnect_lib, common_lib, dsp_top_lib;
library axi4_lib;
use IEEE.STD_LOGIC_1164.ALL;
use axi4_lib.axi4_stream_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
use axi4_lib.axi4_full_pkg.all;
use dsp_top_lib.run2_tb_pkg.ALL;
--use dsp_top_lib.setup_ctc_pkg.all;
use std.textio.all;
use IEEE.std_logic_textio.all;
use IEEE.NUMERIC_STD.ALL;
use common_lib.common_pkg.all;

use LFAADecode_lib.LFAADecode_LFAADecode_reg_pkg.all;
USE capture128bit_lib.capture128bit_reg_pkg.ALL;

entity tb_DSP_top is
end tb_DSP_top;

architecture Behavioral of tb_DSP_top is

    signal cmd_file_name : string(1 to 20) := "LFAA40GE_tb_data.txt";

    signal data_clk : std_logic := '0'; 
    signal LFAA40GE_sosi : t_axi4_sosi;
    signal mac40G : std_logic_vector(47 downto 0);

    signal mm_clk : std_logic := '0';
    signal mm_rst : std_logic := '0';
    signal IC_clk : std_logic := '0';
    signal IC_rst : std_logic := '0';
    signal IC_clk_count : std_logic_vector(3 downto 0) := "0000";

    signal mc_lite_mosi_cap : t_axi4_lite_mosi;
    signal mc_lite_miso_cap : t_axi4_lite_miso;
    signal mc_full_mosi_cap : t_axi4_full_mosi;
    signal mc_full_miso_cap : t_axi4_full_miso;
    
    signal mc_lite_mosi_IC : t_axi4_lite_mosi;  -- interconnect module slave
    signal mc_lite_miso_IC : t_axi4_lite_miso;    
    
    signal ptp_pll_reset : std_logic;
    signal wallTime_clk : std_logic := '0';
    signal ptp_clkin : std_logic := '0';
    signal ptp_clkin_n : std_logic := '0';
    signal wallTimeFrac : std_logic_vector(26 downto 0); -- fraction of a second in units of 8 ns
    signal wallTimeSec : std_logic_vector(31 downto 0);
    signal LFAARun : std_logic := '0'; 

    signal ptp_clk_sel :  std_logic;                     -- PTP Interface (156.25MH select when high)
    signal ptp_sync_n : std_logic_vector(1 downto 0);  -- bit(0) = active low enable for DAC controlling the clk_e = 25 MHz crystal (which is then upconverted to either 125 or 156.25 MHz), bit(1) = active low enable for DAC controlling the clk_f = 20 MHz crystal.  
    signal ptp_sclk :  std_logic;
    signal ptp_din : std_logic;
    signal pps : std_logic;
    signal LFAA_data : std_logic_vector(127 downto 0);
    signal LFAA_valid : std_logic;

    signal ICIn_gtyZData : t_slv_64_arr(6 downto 0);
    signal ICIn_gtyZValid : std_logic_vector(6 downto 0);
    signal ICIn_gtyZSof : std_logic_vector(6 downto 0);
    signal ICIn_gtyZEof : std_logic_vector(6 downto 0);
    signal ICIn_gtyYData : t_slv_64_arr(4 downto 0);
    signal ICIn_gtyYValid : std_logic_vector(4 downto 0);
    signal ICIn_gtyYSof : std_logic_vector(4 downto 0);
    signal ICIn_gtyYEof : std_logic_vector(4 downto 0);
    signal ICIn_gtyXData : t_slv_64_arr(4 downto 0);
    signal ICIn_gtyXValid : std_logic_vector(4 downto 0);
    signal ICIn_gtyXSof : std_logic_vector(4 downto 0);
    signal ICIn_gtyXEof : std_logic_vector(4 downto 0);
    
    signal ICOut_gtyZData : t_slv_64_arr(6 downto 0);
    signal ICOut_gtyZValid : std_logic_vector(6 downto 0);
    signal ICOut_gtyYData : t_slv_64_arr(4 downto 0);
    signal ICOut_gtyYValid : std_logic_vector(4 downto 0);
    signal ICOut_gtyXData : t_slv_64_arr(4 downto 0);
    signal ICOut_gtyXValid : std_logic_vector(4 downto 0);
    signal timingData : std_logic_vector(63 downto 0);
    signal timingValid : std_logic;
    signal CTCin_data : std_logic_vector(63 downto 0);
    signal CTCIn_valid : std_logic;    
    
    signal clk_100 : std_logic := '0';
    signal clk_400 : std_logic := '0';
    signal wall_clk : std_logic := '0';
    
    constant c_dsp_top_full_index : integer := 0;
    constant c_lfaadecode_full_index : integer := 1;
    constant c_capture128bit_full_index : integer := 2;
    constant c_capturefine_full_index : integer := 3;
    constant c_filterbanks_full_index : integer := 4;
    constant c_dsp_top_lite_index : integer := 0;
    constant c_LFAADecode_lite_index : integer := 1;
    constant c_capture128bit_lite_index : integer := 2;
    constant c_timingcontrol_lite_index : integer := 3;
    constant c_interconnect_lite_index : integer := 4;
    constant c_config_lite_index : integer := 5;
    constant c_capturefine_lite_index : integer := 6;
    
    signal mc_lite_miso : t_axi4_lite_miso_arr(0 TO 6);
    signal mc_lite_mosi : t_axi4_lite_mosi_arr(0 TO 6);
    signal mc_full_miso : t_axi4_full_miso_arr(0 TO 4);
    signal mc_full_mosi : t_axi4_full_mosi_arr(0 TO 4);
    signal ctcSetupDone : std_logic := '0';
    signal clk_400_rst : std_logic := '0';
    signal dbgIPAddr : std_logic_vector(31 downto 0);
    
    signal dbg25GE_sosi : t_axi4_sosi;
    signal dbg25GE_siso : t_axi4_siso;
    signal dbg25GE_clk : std_logic := '0';
    
    signal tready_check : std_logic_vector(7 downto 0) := x"00";
    
begin
    
    data_clk <= not data_clk after 1.6 ns; -- 312.5 MHz clock.
    mm_clk <= not mm_clk after 2 ns; -- 2 ns to reduce setup time. 3.2 ns for 156.5 MHz clock used in real system.
    mac40G <= x"123456789abc";
    
    clk_100 <= not clk_100 after 5 ns; -- 100 MHz (HBM reference clock).
    clk_400 <= not clk_400 after 1.25 ns; -- 400 MHz, used for signal processing and HBM
    wall_clk <= not wall_clk after 2 ns; -- 2 ns = 250 MHz wall clock
    
    dbg25GE_clk <= not dbg25GE_clk after 1.28 ns; -- 390.24 MHz 
    
--    process(IC_clk)
--    begin
--        if rising_edge(IC_clk) then
--            if IC_clk_count /= "1111" then
--                IC_clk_count <= std_logic_vector(unsigned(IC_clk_count) + 1);
--                IC_rst <= '1';
--            else
--                IC_rst <= '0';
--            end if;
--        end if;
--    end process;
    

    --------------------------------------------------------------------------
    -- Signal Processing
    
    dbgIPAddr <= x"c0123456";
    process(dbg25GE_clk)
    begin
        if rising_edge(dbg25GE_clk) then
            
            -- Assert tready most of the time, while also testing occasional '0' and short bursts of '0'.
            tready_check <= std_logic_vector(unsigned(tready_check) + 1);
            
            if (tready_check /= "00001111" and 
                tready_check(7 downto 1) /= "0010000" and
                tready_check(7 downto 2) /= "101000") then
                dbg25GE_siso.tready <= '1';
            else
                dbg25GE_siso.tready <= '0';
            end if;
        end if;
    end process;
    
    
    dsp_topi : entity dsp_top_lib.DSP_topNoHBM
    generic map (
        ARRAYRELEASE => -3, -- : integer range 0 to 5 := 0;
        g_sim        => true, -- : BOOLEAN := FALSE
        INCLUDE_FB   => false
    )
    port map (
        -- Processing clocks
        i_clk100 => clk_100,    -- in std_logic; -- HBM reference clock
        -- HBM_AXI_clk and wallClk should be derived from the OCXO on the gemini boards, so that clocks on different boards run very close to the same frequency.
        i_HBM_clk => clk_400,   -- in std_logic; -- 400 MHz for the vcu128 board, up to 450 for production devices. Also used for general purpose processing.
        i_HBM_clk_rst => clk_400_rst,   -- in std_logic;
        i_wall_clk => wall_clk, -- in std_logic;    -- 250 MHz, derived from the 125MHz OCXO. Used for timing of events (e.g. when to start reading in the corner turn)
        -- source IP address, used for the 25GE debug output 
        i_srcIPAddr => dbgIPAddr,
        i_srcIPAddr_clk => clk_100,
        -- 40GE LFAA ingest data
        i_LFAA40GE => LFAA40GE_sosi,  -- in t_axi4_sosi;
        o_LFAA40GE => open,           -- out t_axi4_siso;
        i_LFAA40GE_clk => data_clk,   -- in std_logic;
        i_mac40G => mac40G,           -- in std_logic_vector(47 downto 0); --    mac40G <= x"aabbccddeeff";
        -- 25 GE debug port (output of the interconnect module)
        o_dbg25GE => dbg25GE_sosi, -- out t_axi4_sosi;
        i_dbg25GE => dbg25GE_siso, -- in  t_axi4_siso;
        i_dbg25GE_clk => dbg25GE_clk, -- in std_logic;
        -- XYZ interconnect inputs
        i_gtyZdata  => (others => (others => '0')), -- in t_slv_64_arr(6 downto 0);
        i_gtyZValid => "0000000", -- in std_logic_vector(6 downto 0);
        i_gtyZSof   => "0000000", -- in std_logic_vector(6 downto 0);
        i_gtyZEof   => "0000000", -- in std_logic_vector(6 downto 0);
        i_gtyYdata  => (others => (others => '0')), -- in t_slv_64_arr(4 downto 0);
        i_gtyYValid => "00000", -- in std_logic_vector(4 downto 0);
        i_gtyYSof   => "00000", -- in std_logic_vector(4 downto 0);
        i_gtyYEof   => "00000", -- in std_logic_vector(4 downto 0);
        i_gtyXdata  => (others => (others => '0')), -- in t_slv_64_arr(4 downto 0);
        i_gtyXValid => "00000", -- in std_logic_vector(4 downto 0);
        i_gtyXSof   => "00000", -- in std_logic_vector(4 downto 0);
        i_gtyXEof   => "00000", -- in std_logic_vector(4 downto 0);        
        -- XYZ interconnect outputs
        o_gtyZData  => open,    -- out t_slv_64_arr(6 downto 0);
        o_gtyZValid => open,    -- out std_logic_vector(6 downto 0);
        o_gtyYData  => open,    -- out t_slv_64_arr(4 downto 0);
        o_gtyYValid => open,    -- out std_logic_vector(4 downto 0);
        o_gtyXData  => open,    -- out t_slv_64_arr(4 downto 0);
        o_gtyXValid => open,    -- out std_logic_vector(4 downto 0);
        -- Serial interface to the OCXO
        o_ptp_pll_reset => open, -- out std_logic;                     -- PLL reset
        o_ptp_clk_sel   => open, -- out std_logic;                     -- PTP Interface (156.25MH select when high)
        o_ptp_sync_n    => open, -- out std_logic_vector(1 downto 0);  -- bit(0) = active low enable for DAC controlling the clk_e = 25 MHz crystal (which is then upconverted to either 125 or 156.25 MHz), bit(1) = active low enable for DAC controlling the clk_f = 20 MHz crystal.  
        o_ptp_sclk      => open, -- out std_logic;
        o_ptp_din       => open, -- out std_logic;
        -----------------------------------------------------------------------
        -- AXI slave interfaces for modules
        i_MACE_clk  => mm_clk,   -- in std_logic;
        i_MACE_rst  => mm_rst,   -- in std_logic;
        -- DSP top lite slave
        i_dsptopLite_axi_mosi => mc_lite_mosi(c_dsp_top_lite_index), -- in  t_axi4_lite_mosi;
        o_dsptopLite_axi_miso => mc_lite_miso(c_dsp_top_lite_index), -- out t_axi4_lite_miso;
        -- LFAADecode, lite + full slave
        i_LFAALite_axi_mosi => mc_lite_mosi(c_LFAADecode_lite_index), -- in  t_axi4_lite_mosi; 
        o_LFAALite_axi_miso => mc_lite_miso(c_LFAADecode_lite_index), -- out t_axi4_lite_miso;
        i_LFAAFull_axi_mosi => mc_full_mosi(c_lfaadecode_full_index), -- in  t_axi4_full_mosi;
        o_LFAAFull_axi_miso => mc_full_miso(c_lfaadecode_full_index), -- out t_axi4_full_miso;
        -- Capture, lite + full
        i_Cap128Lite_axi_mosi => mc_lite_mosi(c_capture128bit_lite_index), -- in t_axi4_lite_mosi;
        o_Cap128Lite_axi_miso => mc_lite_miso(c_capture128bit_lite_index), -- out t_axi4_lite_miso;
        i_Cap128Full_axi_mosi => mc_full_mosi(c_capture128bit_full_index), -- in  t_axi4_full_mosi;
        o_Cap128Full_axi_miso => mc_full_miso(c_capture128bit_full_index), -- out t_axi4_full_miso;
        -- Timing control
        i_timing_axi_mosi => mc_lite_mosi(c_timingcontrol_lite_index), -- in  t_axi4_lite_mosi;
        o_timing_axi_miso => mc_lite_miso(c_timingcontrol_lite_index), -- out t_axi4_lite_miso;
        -- Interconnect
        i_IC_axi_mosi => mc_lite_mosi(c_interconnect_lite_index), -- in t_axi4_lite_mosi;
        o_IC_axi_miso => mc_lite_miso(c_interconnect_lite_index)  -- out t_axi4_lite_miso;
    );
    
    
    
    -- Load the registers and then send data in.
    process
    begin
        
        mm_rst <= '0';
        for i in 1 to 20 loop
            WAIT UNTIL RISING_EDGE(mm_clk);
        end loop;
        mm_rst <= '1';
        clk_400_rst <= '1';
        for i in 1 to 100 loop
             WAIT UNTIL RISING_EDGE(mm_clk);
        end loop;
        mm_rst <= '0';
        clk_400_rst <= '0';
        
        for i in 1 to 100 loop
             WAIT UNTIL RISING_EDGE(mm_clk);
        end loop;        
        
        -- For some reason the first transaction doesn't work; this is just a dummy transaction
        axi_lite_transaction(mm_clk, mc_lite_miso(c_LFAADecode_lite_index), mc_lite_mosi(c_LFAADecode_lite_index), c_statctrl_stationid1_address.base_address + c_statctrl_stationid1_address.address, true, x"00000001");
        
        setupLFAADecode(mm_clk, mc_lite_miso(c_LFAADecode_lite_index), mc_lite_mosi(c_LFAADecode_lite_index));
        
        -- set capture parameters - capture everything.
        axi_lite_transaction(mm_clk, mc_lite_miso(c_capture128bit_lite_index), mc_lite_mosi(c_capture128bit_lite_index), c_cap128ctrl_dontcaremask0_address.base_address + c_cap128ctrl_dontcaremask0_address.address, true, x"FFFFFFFF");
        axi_lite_transaction(mm_clk, mc_lite_miso(c_capture128bit_lite_index), mc_lite_mosi(c_capture128bit_lite_index), c_cap128ctrl_dontcaremask0_address.base_address + c_cap128ctrl_dontcaremask0_address.address, true, x"FFFFFFFF");
        axi_lite_transaction(mm_clk, mc_lite_miso(c_capture128bit_lite_index), mc_lite_mosi(c_capture128bit_lite_index), c_cap128ctrl_dontcaremask1_address.base_address + c_cap128ctrl_dontcaremask1_address.address, true, x"FFFFFFFF");
        axi_lite_transaction(mm_clk, mc_lite_miso(c_capture128bit_lite_index), mc_lite_mosi(c_capture128bit_lite_index), c_cap128ctrl_dontcaremask2_address.base_address + c_cap128ctrl_dontcaremask2_address.address, true, x"FFFFFFFF");
        axi_lite_transaction(mm_clk, mc_lite_miso(c_capture128bit_lite_index), mc_lite_mosi(c_capture128bit_lite_index), c_cap128ctrl_dontcaremask3_address.base_address + c_cap128ctrl_dontcaremask3_address.address, true, x"FFFFFFFF");
        -- enable capture
        axi_lite_transaction(mm_clk, mc_lite_miso(c_capture128bit_lite_index), mc_lite_mosi(c_capture128bit_lite_index), c_cap128ctrl_enable_address.base_address + c_cap128ctrl_enable_address.address, true, x"00000001");
        
        WAIT UNTIL RISING_EDGE(mm_clk);
        WAIT UNTIL RISING_EDGE(mm_clk);
        WAIT UNTIL RISING_EDGE(mm_clk);
        
        LFAARun <= '1';

        wait;
        
    end process;
    
    
    -- 40 GE data input
    process
        
        file cmdfile: TEXT;
        variable line_in : Line;
        variable good : boolean;
        variable LFAArepeats : std_logic_vector(15 downto 0);
        variable LFAAvalid : std_logic_vector(3 downto 0);
        variable LFAAtuserSeg0 : std_logic_vector(7 downto 0);
        variable LFAAtuserSeg1 : std_logic_vector(7 downto 0);
        variable LFAAdataSeg0 : std_logic_vector(63 downto 0);
        variable LFAAdataSeg1 : std_logic_vector(63 downto 0);
        
    begin
        -- For data coming in from the 40G MAC, the only fields that are used are
        --  data_rx_sosi.tdata
        --  data_rx_sosi.tuser
        --  data_rx_sosi.tvalid
        -- segment 0 relates to data_rx_sosi.tdata(63:0)
        --tuserSeg0.ena <= i_data_rx_sosi.tuser(56);
        --tuserSeg0.sop <= i_data_rx_sosi.tuser(57);  -- start of packet
        --tuserSeg0.eop <= i_data_rx_sosi.tuser(58);  -- end of packet
        --tuserSeg0.mty <= i_data_rx_sosi.tuser(61 DOWNTO 59); -- number of unused bytes in segment 0, only used when eop0 = '1', ena0 = '1', tvalid = '1'. 
        --tuserSeg0.err <= i_data_rx_sosi.tuser(62);  -- error reported by 40GE MAC (e.g. FCS, bad 64/66 bit block, bad packet length), only valid on eop0, ena0 and tvalid all = '1'
        -- segment 1 relates to data_rx_sosi.tdata(127:64)
        --tuserSeg1.ena <= i_data_rx_sosi.tuser(63);
        --tuserSeg1.sop <= i_data_rx_sosi.tuser(64);
        --tuserSeg1.eop <= i_data_rx_sosi.tuser(65);
        --tuserSeg1.mty <= i_data_rx_sosi.tuser(68 DOWNTO 66);
        --tuserSeg1.err <= i_data_rx_sosi.tuser(69);
        
        LFAA40GE_sosi.tdata <= (others => '0');  -- 128 bits
        LFAA40GE_sosi.tvalid <= '0';             -- 1 bit
        LFAA40GE_sosi.tuser <= (others => '0');  -- 
        
        FILE_OPEN(cmdfile,cmd_file_name,READ_MODE);
        wait until LFAARun = '1';
        
        
        wait until rising_edge(data_clk);
        
        while (not endfile(cmdfile)) loop 
            readline(cmdfile, line_in);
            hread(line_in,LFAArepeats,good);
            hread(line_in,LFAAvalid,good);
            hread(line_in,LFAAtuserSeg0,good);
            hread(line_in,LFAAtuserSeg1,good);
            hread(line_in,LFAAdataSeg0,good);
            hread(line_in,LFAAdataSeg1,good);
            
            LFAA40GE_sosi.tvalid <= LFAAvalid(0);
            LFAA40GE_sosi.tdata(63 downto 0) <= LFAAdataSeg0;
            LFAA40GE_sosi.tdata(127 downto 64) <= LFAAdataSeg1;
            LFAA40GE_sosi.tuser(62 downto 56) <= LFAAtuserSeg0(6 downto 0);
            LFAA40GE_sosi.tuser(69 downto 63) <= LFAAtuserSeg1(6 downto 0);
            while LFAArepeats /= "0000000000000000" loop
                LFAArepeats := std_logic_vector(unsigned(LFAArepeats) - 1);
                wait until rising_edge(data_clk);
            end loop;
        end loop;
        
    end process;
    
    
end Behavioral;
