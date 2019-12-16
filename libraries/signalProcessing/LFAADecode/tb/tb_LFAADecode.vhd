------------------------------------------------------------------------------------
---- Company: CSIRO 
---- Engineer: David Humphrey (dave.humphrey@csiro.au)
---- 
---- Create Date: 12.04.2019 16:54:16
---- Module Name: tb_LFAADecode - Behavioral
---- Description: 
----  Testbench for the LFAA decode module.
---- 
------------------------------------------------------------------------------------

--library IEEE;
--library LFAADecode_lib, timingControl_lib, capture128bit_lib, interconnect_lib, common_lib, dsp_top_lib;
--library axi4_lib;
--use IEEE.STD_LOGIC_1164.ALL;
--use axi4_lib.axi4_stream_pkg.ALL;
--USE axi4_lib.axi4_lite_pkg.ALL;
--use axi4_lib.axi4_full_pkg.all;
--use dsp_top_lib.run2_tb_pkg.ALL;
--use std.textio.all;
--use IEEE.std_logic_textio.all;
--use IEEE.NUMERIC_STD.ALL;
--use common_lib.common_pkg.all;

--use LFAADecode_lib.LFAADecode_LFAADecode_reg_pkg.all;
--USE capture128bit_lib.capture128bit_reg_pkg.ALL;

--entity tb_LFAADecode is
--end tb_LFAADecode;

--architecture Behavioral of tb_LFAADecode is

--    signal cmd_file_name : string(1 to 20) := "LFAA40GE_tb_data.txt";

--    signal data_clk : std_logic := '0'; 
--    signal LFAA40GE_sosi : t_axi4_sosi;
--    signal mac40G : std_logic_vector(47 downto 0);

--    signal mm_clk : std_logic := '0';
--    signal mm_rst : std_logic := '0';
--    signal IC_clk : std_logic := '0';
--    signal IC_rst : std_logic := '0';
--    signal IC_clk_count : std_logic_vector(3 downto 0) := "0000";
--    signal mc_lite_mosi : t_axi4_lite_mosi;
--    signal mc_lite_miso : t_axi4_lite_miso;
--    signal mc_lite_mosi_tc : t_axi4_lite_mosi;  -- separate axi lite bus for timing control.
--    signal mc_lite_miso_tc : t_axi4_lite_miso;    
--    signal mc_full_mosi : t_axi4_full_mosi;
--    signal mc_full_miso : t_axi4_full_miso;

--    signal mc_lite_mosi_cap : t_axi4_lite_mosi;
--    signal mc_lite_miso_cap : t_axi4_lite_miso;
--    signal mc_full_mosi_cap : t_axi4_full_mosi;
--    signal mc_full_miso_cap : t_axi4_full_miso;
    
--    signal mc_lite_mosi_IC : t_axi4_lite_mosi;  -- interconnect module slave
--    signal mc_lite_miso_IC : t_axi4_lite_miso;    
    
--    signal ptp_pll_reset : std_logic;
--    signal wallTime_clk : std_logic := '0';
--    signal ptp_clkin : std_logic := '0';
--    signal ptp_clkin_n : std_logic := '0';
--    signal wallTimeFrac : std_logic_vector(26 downto 0); -- fraction of a second in units of 8 ns
--    signal wallTimeSec : std_logic_vector(31 downto 0);
--    signal LFAARun : std_logic := '0'; 

--    signal ptp_clk_sel :  std_logic;                     -- PTP Interface (156.25MH select when high)
--    signal ptp_sync_n : std_logic_vector(1 downto 0);  -- bit(0) = active low enable for DAC controlling the clk_e = 25 MHz crystal (which is then upconverted to either 125 or 156.25 MHz), bit(1) = active low enable for DAC controlling the clk_f = 20 MHz crystal.  
--    signal ptp_sclk :  std_logic;
--    signal ptp_din : std_logic;
--    signal pps : std_logic;
--    signal LFAA_data : std_logic_vector(127 downto 0);
--    signal LFAA_valid : std_logic;

--    signal ICIn_gtyZData : t_slv_64_arr(6 downto 0);
--    signal ICIn_gtyZValid : std_logic_vector(6 downto 0);
--    signal ICIn_gtyZSof : std_logic_vector(6 downto 0);
--    signal ICIn_gtyZEof : std_logic_vector(6 downto 0);
--    signal ICIn_gtyYData : t_slv_64_arr(4 downto 0);
--    signal ICIn_gtyYValid : std_logic_vector(4 downto 0);
--    signal ICIn_gtyYSof : std_logic_vector(4 downto 0);
--    signal ICIn_gtyYEof : std_logic_vector(4 downto 0);
--    signal ICIn_gtyXData : t_slv_64_arr(4 downto 0);
--    signal ICIn_gtyXValid : std_logic_vector(4 downto 0);
--    signal ICIn_gtyXSof : std_logic_vector(4 downto 0);
--    signal ICIn_gtyXEof : std_logic_vector(4 downto 0);
    
--    signal ICOut_gtyZData : t_slv_64_arr(6 downto 0);
--    signal ICOut_gtyZValid : std_logic_vector(6 downto 0);
--    signal ICOut_gtyYData : t_slv_64_arr(4 downto 0);
--    signal ICOut_gtyYValid : std_logic_vector(4 downto 0);
--    signal ICOut_gtyXData : t_slv_64_arr(4 downto 0);
--    signal ICOut_gtyXValid : std_logic_vector(4 downto 0);
--    signal timingData : std_logic_vector(63 downto 0);
--    signal timingValid : std_logic;
--    signal CTCin_data : std_logic_vector(63 downto 0);
--    signal CTCIn_valid : std_logic;    
    
--begin
    
--    data_clk <= not data_clk after 1.6 ns; -- 312.5 MHz clock.
--    mm_clk <= not mm_clk after 5 ns; -- 100 MHz clock.
--    mac40G <= x"123456789abc";
    
--    -- ptp clock
--    ptp_clkin <= not ptp_clkin after 2 ns; -- 4 ns = 125 MHz clock, 2 ns = 250 MHz clock
--    ptp_clkin_n <= not ptp_clkin;
    
--    -- Interconnect clock
--    --IC_clk <= not IC_clk after 2.21 ns;
--    IC_clk <= not IC_clk after 1.25 ns; -- 400 MHz interconnect clock
    
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
    
--    dut : entity LFAADecode_lib.LFAADecodeTop
--    port map(
--        -- Data in from the 40GE MAC
--        i_data_rx_sosi   => LFAA40GE_sosi, -- in t_axi4_sosi;   -- 128 bit wide data in, only fields that are used are .tdata, .tvalid, .tuser
--        o_data_rx_siso   => open, -- out t_axi4_siso;  -- Only tready, and actually ignored by the 40GE MAC 
--        i_data_clk       => data_clk, -- in std_logic;     -- 312.5 MHz for 40GE MAC
--        i_data_rst       => '0', -- in std_logic;
--        -- Data out 
--        o_data_out       => LFAA_data,  --  out std_logic_vector(127 downto 0);
--        o_valid_out      => LFAA_valid, --  out std_logic;
--        -- miscellaneous
--        i_my_mac         => mac40G, -- in std_logic_vector(47 downto 0); -- MAC address for this board; incoming packets from the 40GE interface are filtered using this.
--        i_time_sec       => wallTimeSec,  --  in std_logic_vector(31 downto 0); -- UNIX time in seconds (i.e. since 1970)
--        i_time_frac      => wallTimeFrac, --  in std_logic_vector(26 downto 0); -- Fractional of a second in units of 8 ns 
--        i_ptp_clk        => wallTime_clk, --  in std_logic;                     -- Should be 125 MHz.       
--        --AXI Interface
--        i_s_axi_mosi       => mc_lite_mosi,   -- IN t_axi4_lite_mosi;
--        o_s_axi_miso       => mc_lite_miso,   -- OUT t_axi4_lite_miso;
--        i_s_axi_clk        => mm_clk,        -- in std_logic
--        i_s_axi_rst        => mm_rst,
--        -- registers AXI Full interface
--        i_vcstats_MM_IN    => mc_full_mosi, -- in  t_axi4_full_mosi;
--        o_vcstats_MM_OUT   => mc_full_miso, -- out t_axi4_full_miso;
--        -- debug
--        o_dbg              => open
--    );

--    pcapture : entity capture128bit_lib.capture128bit
--    port map (
--        -- Packet Data to capture
--        i_data      => LFAA_data,         --  in 127:0;
--        i_valid     => LFAA_valid,        --  in std_logic;
--        i_data_clk  => data_clk, -- in std_logic;
--        -- control registers AXI Lite Interface
--        i_s_axi_mosi => mc_lite_mosi_cap, -- in t_axi4_lite_mosi;
--        o_s_axi_miso => mc_lite_miso_cap, -- out t_axi4_lite_miso;
--        i_s_axi_clk  => mm_clk,
--        i_s_axi_rst  => mm_rst,
--        -- AXI Full interface for the capture buffer
--        i_capmem_MM_IN  => mc_full_mosi_cap, -- in  t_axi4_full_mosi;
--        o_capmem_MM_OUT => mc_full_miso_cap  -- out t_axi4_full_miso;        
--    );


--    timingInst : entity timingcontrol_lib.timing_control
--    generic map (
--        pll_bypass => '1'
--    )
--    port map (
--        -- Registers
--        mm_clk  => mm_clk, -- in std_logic;
--        mm_rst  => mm_rst, -- in std_logic;
--        i_sla_in  => mc_lite_mosi_tc, -- in  t_axi4_lite_mosi;
--        o_sla_out => mc_lite_miso_tc, -- out t_axi4_lite_miso;
--        -------------------------------------------------------
--        -- FPGA pins
--        clk_e_p => ptp_clkin, -- : in std_logic;         -- Either 156.25 MHz or 125MHz PTP clk, output of PLL chip CDCM61004, controlled by ptp_clk_sel
--        clk_e_n => ptp_clkin_n, -- : in std_logic;
--        --
--        -- Serial interface to AD5662BRM nanodacs, which controls the voltage to two oscillators
--        -- * 20 MHz, which comes in as 20 MHz on clk_f. This crystal has a range of +/-100 ppm, so better to use the 25 MHz crystal 
--        -- * 25 MHz, which is converted up to either 156.25 MHz or 125 MHz, depending on ptp_clk_sel.
--        --           The crystal has a range of +/-6 ppm (or maybe 12.. not clear which version we have). 
--        --           This clock comes in on both sfp_clk_e_p/n and clk_e_p/n.
--        --           sfp_clk_e_p/n could be used for synchronous ethernet/white rabbit.
--        -- AD5662BRM info -
--        --   - ptp_sclk maximum frequency is MHz
--        --   - data sampled on the falling edge of ptp_sclk
--        --   - 24 bits per command, with
--        --      - 6 don't cares
--        --      - "00" for normal operation (other options are power-down states).
--        --      - 16 data bits, straight binary 0 to 65535.
--        o_ptp_pll_reset        => ptp_pll_reset, -- out std_logic;                     -- PLL reset
--        o_ptp_clk_sel          => ptp_clk_sel,   -- out std_logic;                     -- PTP Interface (156.25MH select when high)
--        o_ptp_sync_n           => ptp_sync_n,    -- out std_logic_vector(1 downto 0);  -- bit(0) = active low enable for DAC controlling the clk_e = 25 MHz crystal (which is then upconverted to either 125 or 156.25 MHz), bit(1) = active low enable for DAC controlling the clk_f = 20 MHz crystal.  
--        o_ptp_sclk             => ptp_sclk,      -- out std_logic;
--        o_ptp_din              => ptp_din,       -- out std_logic;
--        --------------------------------------------------------
--        -- Time outputs
--        -- Note - ptp_time_frac is in units of 8 ns, and counts 0 to 124999999.
--        -- triggering of events should use ptp_time_frac(26 downto 3), which is in units of 64 ns
--        -- and counts 0 to 15624999. ptp_time_frac may skip counts in order to
--        -- match the master time that it is tracking, but every count of
--        -- ptp_time_frac(26:3) will occur.
--        o_ptp_clk       => wallTime_clk, -- : out std_logic;                     -- 125 MHz clock
--        o_ptp_time_frac => wallTimeFrac, -- out std_logic_vector(26 downto 0); -- fraction of a second in units of 8 ns
--        o_ptp_time_sec  => wallTimeSec,  -- out std_logic_vector(31 downto 0); -- time in seconds since January 1, 1970 (32 bit unsigned, so wraps in the year 2106)
--        o_pps           => pps,           -- out std_logic;
--        --------------------------------------------------------
--        -- Packets from the internal network
--        -- Timing packets from other FPGAs come in on this link.
--        -- Expected format is 3 words :
--        --   (1) source MAC (6 bytes) + source port (1 byte) + packet type (1 byte)
--        --       - This should be the header of all packets on the internal network
--        --       - Packet type of 0 = timing information.
--        --   (2) source time (24 bit fractional + 32 bit integer seconds + 1 byte unused).
--        --   (3) Interval (24 bit fractional + 32 bit integer seconds + 1 bit to indicate valid)
--        --       - This is the time gap since the last packet according to the remote clock.  
--        --         The source time in the previous word can have jumps, so we cannot calculate the
--        --         time locally.
--        --   (4) Last word in the packet (FCS + 4 bytes unused).
--        i_packet_valid => '0',             --  in std_logic;
--        i_packet_data  => (others => '0')  --  in std_logic_vector(63 downto 0)
--    );
    
--    -----------------------------------------------------------
--    ICi : entity interconnect_lib.IC_Top
--    generic map (
--        ARRAYRELEASE => 0 -- : integer range 0 to 5 := 0 
--    )
--    port map(
--        -- Packets from GTYs.
--        -- All GTYs send data in on the same clock.
--        i_IC_clk => IC_clk,  -- in std_logic;
--        i_IC_rst => IC_rst,  -- in std_logic;
--        -- Wall time is used to timestamp incoming packets. This is only used for timing packets.
--        i_wallTimeSec  => wallTimeSec,   -- in std_logic_vector(31 downto 0);  -- seconds since 1970
--        i_wallTimeFrac => wallTimeFrac,  -- in std_logic_vector(26 downto 0); -- 8 ns fraction of a second
--        i_wall_clk     => wallTime_clk,  -- in std_logic;
--        -- XYZ interconnect inputs
--        i_gtyZdata  => ICIn_gtyZData,  -- in t_slv_64_arr(6 downto 0);
--        i_gtyZValid => ICIn_gtyZValid, -- in std_logic_vector(6 downto 0);
--        i_gtyZSof   => ICIn_gtyZSof,   -- in std_logic_vector(6 downto 0);
--        i_gtyZEof   => ICIn_gtyZEof,   -- in std_logic_vector(6 downto 0);
--        i_gtyYdata  => ICIn_gtyYData,  -- in t_slv_64_arr(4 downto 0);
--        i_gtyYValid => ICIn_gtyYValid, -- in std_logic_vector(4 downto 0);
--        i_gtyYSof   => ICIn_gtyYSof,   -- in std_logic_vector(4 downto 0);
--        i_gtyYEof   => ICIn_gtyYEof,   -- in std_logic_vector(4 downto 0);
--        i_gtyXdata  => ICIn_gtyXData,  -- in t_slv_64_arr(4 downto 0);
--        i_gtyXValid => ICIn_gtyXValid, -- in std_logic_vector(4 downto 0);
--        i_gtyXSof   => ICIn_gtyXSof,   -- in std_logic_vector(4 downto 0);
--        i_gtyXEof   => ICIn_gtyXEof,   -- in std_logic_vector(4 downto 0);
--        -------------------------------------------------
--        -- Signal chain inputs 
--        -- 1. LFAA ingest pipeline
--        i_LFAAingest_data => LFAA_data,   -- in std_logic_vector(127 downto 0);
--        i_LFAAingest_valid => LFAA_valid, -- in std_logic;
--        i_LFAAingest_clk => data_clk,     -- in std_logic;
--        -- 2. 
--        -------------------------------------------------
--        -- XYZ interconnect outputs
--        o_gtyZData => ICOut_gtyZData,   -- out t_slv_64_arr(6 downto 0);
--        o_gtyZValid => ICOut_gtyZValid, -- out std_logic_vector(6 downto 0);
--        o_gtyYData => ICOut_gtyYData,   -- out t_slv_64_arr(4 downto 0);
--        o_gtyYValid => ICOut_gtyYValid, -- out std_logic_vector(4 downto 0);
--        o_gtyXData => ICOut_gtyXData,   -- out t_slv_64_arr(4 downto 0);
--        o_gtyXValid => ICOut_gtyXValid, -- out std_logic_vector(4 downto 0);
--        -------------------------------------------------
--        -- Signal chain outputs
--        -- 1. timing
--        o_timingData => timingData,   -- out std_logic_vector(63 downto 0);
--        o_timingValid => timingValid, -- out std_logic;
--        -- 2. Coarse Corner Turn
--        o_CTCData => CTCin_data,      -- out std_logic_vector(63 downto 0);
--        o_CTCValid => CTCIn_valid,    -- out std_logic;
--        --------------------------------------------------
--        -- Registers AXI Lite Interface
--        i_s_axi_mosi => mc_lite_mosi_IC, -- in t_axi4_lite_mosi;
--        o_s_axi_miso => mc_lite_miso_IC, -- out t_axi4_lite_miso;
--        i_s_axi_clk  => mm_clk,          -- in std_logic;
--        i_s_axi_rst  => mm_rst           -- in std_logic       
--    );  
    
--    ICIn_gtyZData <= (others => (others => '0')); -- : t_slv_64_arr(6 downto 0);
--    ICIn_gtyZValid <= (others => '0'); -- std_logic_vector(6 downto 0);
--    ICIn_gtyZSof <= (others => '0');   -- std_logic_vector(6 downto 0);
--    ICIn_gtyZEof <= (others => '0'); -- std_logic_vector(6 downto 0);
--    ICIn_gtyYData <= (others => (others => '0')); -- t_slv_64_arr(4 downto 0);
--    ICIn_gtyYValid <= (others => '0'); -- std_logic_vector(4 downto 0);
--    ICIn_gtyYSof <= (others => '0'); -- std_logic_vector(4 downto 0);
--    ICIn_gtyYEof <= (others => '0'); -- std_logic_vector(4 downto 0);
--    ICIn_gtyXData <= (others => (others => '0')); -- t_slv_64_arr(4 downto 0);
--    ICIn_gtyXValid <= (others => '0'); -- std_logic_vector(4 downto 0);
--    ICIn_gtyXSof <= (others => '0'); -- std_logic_vector(4 downto 0);
--    ICIn_gtyXEof <= (others => '0'); -- std_logic_vector(4 downto 0);
    
    
--    -- Load the registers and then send data in.
--    process
--    begin
        
--        mm_rst <= '0';
--        for i in 1 to 20 loop
--            WAIT UNTIL RISING_EDGE(mm_clk);
--        end loop;
--        mm_rst <= '1';
--        for i in 1 to 100 loop
--             WAIT UNTIL RISING_EDGE(mm_clk);
--        end loop;
--        mm_rst <= '0';
        
--        for i in 1 to 100 loop
--             WAIT UNTIL RISING_EDGE(mm_clk);
--        end loop;        
        
--        -- For some reason the first transaction doesn't work; this is just a dummy transaction
--        axi_lite_transaction(mm_clk, mc_lite_miso, mc_lite_mosi, c_statctrl_stationid1_address.base_address + c_statctrl_stationid1_address.address, true, x"00000001");
        
--        setupLFAADecode(mm_clk, mc_lite_miso, mc_lite_mosi);
        
--        -- set capture parameters - capture everything.
--        axi_lite_transaction(mm_clk, mc_lite_miso_cap, mc_lite_mosi_cap, c_cap128ctrl_dontcaremask0_address.base_address + c_cap128ctrl_dontcaremask0_address.address, true, x"FFFFFFFF");
--        axi_lite_transaction(mm_clk, mc_lite_miso_cap, mc_lite_mosi_cap, c_cap128ctrl_dontcaremask0_address.base_address + c_cap128ctrl_dontcaremask0_address.address, true, x"FFFFFFFF");
--        axi_lite_transaction(mm_clk, mc_lite_miso_cap, mc_lite_mosi_cap, c_cap128ctrl_dontcaremask1_address.base_address + c_cap128ctrl_dontcaremask1_address.address, true, x"FFFFFFFF");
--        axi_lite_transaction(mm_clk, mc_lite_miso_cap, mc_lite_mosi_cap, c_cap128ctrl_dontcaremask2_address.base_address + c_cap128ctrl_dontcaremask2_address.address, true, x"FFFFFFFF");
--        axi_lite_transaction(mm_clk, mc_lite_miso_cap, mc_lite_mosi_cap, c_cap128ctrl_dontcaremask3_address.base_address + c_cap128ctrl_dontcaremask3_address.address, true, x"FFFFFFFF");
--        -- enable capture
--        axi_lite_transaction(mm_clk, mc_lite_miso_cap, mc_lite_mosi_cap, c_cap128ctrl_enable_address.base_address + c_cap128ctrl_enable_address.address, true, x"00000001");
        
--        WAIT UNTIL RISING_EDGE(mm_clk);
--        WAIT UNTIL RISING_EDGE(mm_clk);
--        WAIT UNTIL RISING_EDGE(mm_clk);
        
--        LFAARun <= '1';

--        wait;
        
--    end process;
    
    
--    -- 40 GE data input
--    process
        
--        file cmdfile: TEXT;
--        variable line_in : Line;
--        variable good : boolean;
--        variable LFAArepeats : std_logic_vector(15 downto 0);
--        variable LFAAvalid : std_logic_vector(3 downto 0);
--        variable LFAAtuserSeg0 : std_logic_vector(7 downto 0);
--        variable LFAAtuserSeg1 : std_logic_vector(7 downto 0);
--        variable LFAAdataSeg0 : std_logic_vector(63 downto 0);
--        variable LFAAdataSeg1 : std_logic_vector(63 downto 0);
        
--    begin
--        -- For data coming in from the 40G MAC, the only fields that are used are
--        --  data_rx_sosi.tdata
--        --  data_rx_sosi.tuser
--        --  data_rx_sosi.tvalid
--        -- segment 0 relates to data_rx_sosi.tdata(63:0)
--        --tuserSeg0.ena <= i_data_rx_sosi.tuser(56);
--        --tuserSeg0.sop <= i_data_rx_sosi.tuser(57);  -- start of packet
--        --tuserSeg0.eop <= i_data_rx_sosi.tuser(58);  -- end of packet
--        --tuserSeg0.mty <= i_data_rx_sosi.tuser(61 DOWNTO 59); -- number of unused bytes in segment 0, only used when eop0 = '1', ena0 = '1', tvalid = '1'. 
--        --tuserSeg0.err <= i_data_rx_sosi.tuser(62);  -- error reported by 40GE MAC (e.g. FCS, bad 64/66 bit block, bad packet length), only valid on eop0, ena0 and tvalid all = '1'
--        -- segment 1 relates to data_rx_sosi.tdata(127:64)
--        --tuserSeg1.ena <= i_data_rx_sosi.tuser(63);
--        --tuserSeg1.sop <= i_data_rx_sosi.tuser(64);
--        --tuserSeg1.eop <= i_data_rx_sosi.tuser(65);
--        --tuserSeg1.mty <= i_data_rx_sosi.tuser(68 DOWNTO 66);
--        --tuserSeg1.err <= i_data_rx_sosi.tuser(69);
        
--        LFAA40GE_sosi.tdata <= (others => '0');  -- 128 bits
--        LFAA40GE_sosi.tvalid <= '0';             -- 1 bit
--        LFAA40GE_sosi.tuser <= (others => '0');  -- 
        
--        FILE_OPEN(cmdfile,cmd_file_name,READ_MODE);
--        wait until LFAARun = '1';
        
--        wait until rising_edge(data_clk);
        
--        while (not endfile(cmdfile)) loop 
--            readline(cmdfile, line_in);
--            hread(line_in,LFAArepeats,good);
--            hread(line_in,LFAAvalid,good);
--            hread(line_in,LFAAtuserSeg0,good);
--            hread(line_in,LFAAtuserSeg1,good);
--            hread(line_in,LFAAdataSeg0,good);
--            hread(line_in,LFAAdataSeg1,good);
            
--            LFAA40GE_sosi.tvalid <= LFAAvalid(0);
--            LFAA40GE_sosi.tdata(63 downto 0) <= LFAAdataSeg0;
--            LFAA40GE_sosi.tdata(127 downto 64) <= LFAAdataSeg1;
--            LFAA40GE_sosi.tuser(62 downto 56) <= LFAAtuserSeg0(6 downto 0);
--            LFAA40GE_sosi.tuser(69 downto 63) <= LFAAtuserSeg1(6 downto 0);
--            while LFAArepeats /= "0000000000000000" loop
--                LFAArepeats := std_logic_vector(unsigned(LFAArepeats) - 1);
--                wait until rising_edge(data_clk);
--            end loop;
--        end loop;
        
--    end process;
    
    
--end Behavioral;
