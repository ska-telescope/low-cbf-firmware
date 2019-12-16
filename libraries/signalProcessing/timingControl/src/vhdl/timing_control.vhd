----------------------------------------------------------------------------
-- Timing control module for Perentie 
--
-- Functions
--
--  Manages a local version of unix time, with a resolution of 8 ns.
--  The local time tracks a master timing source, which can either be MACE or another FPGA.
--
--  Two control loops :
--  * The internal counter is adjusted to remove offsets between the time at the master and the local time
--
--  * The OCXO control voltage is adjusted to remove frequency offsets between the master and the local oscillator
--    - Tracking :
--       The DAC is 16 bits, and the 25 MHz crystal has a range of about +/-10 ppm, so
--       the DAC step size is about 20ppm/65536 = 0.3 ppb
--       Low order bits on the DAC are unreliable and the crystal has temperature dependence etc so 
--       realistically we will get control of about a few ppb.
--       So we want to measure the frequency offset relative to the timing master down to about 1 ppb
--       Intervals between timing packets should be in the range 10 milliseconds to 10 seconds.
--       The frequency offset is calculated by doing a division :
--          Error = ((packet interval according to master) - (packet interval according to local clock)) / (packet_interval according to local clock)
--       The intervals are all measured using the 125 MHz clock (i.e. with an 8ns period).
--       For the division operation :
--        - The packet interval "P" is recorded with 32 bits
--        - The difference "D" in the master and slave intervals is recorded with 16 bits (signed)
--           - If the difference doesn't fit in 16 bits, then it is saturated so it does.
--        - The difference is multiplied by 2^32 and divided by P, i.e.
--            E = (2^32 * D) / P
--          This corresponds to an integer division with 48 bits in the numerator and 32 bits in the denominator
--        - The division generates a 16 bit result. The result can be multiplied by (1e9/2^32) to get the frequency difference in PPB.
--        - The largest possible value this can generate is a frequency offset of 8192 PPB = 8.192 PPM.
--
-------------------------------------------------------------------------------

LIBRARY IEEE, common_lib, axi4_lib, UNISIM, DSP_top_lib, ctc_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE common_lib.common_pkg.ALL;
use UNISIM.vcomponents.all;
USE work.timingControl_timingcontrol_reg_pkg.ALL;

use DSP_top_lib.dsp_top_pkg.all;
--use ctc_lib.ctc_pkg.all;

Library xpm;
use xpm.vcomponents.all;

entity timing_control is
    port (
        -- Registers
        mm_clk  : in std_logic;
        mm_rst  : in std_logic;
        i_sla_in  : in  t_axi4_lite_mosi;
        o_sla_out : out t_axi4_lite_miso;
        -------------------------------------------------------
        -- clocks :
        i_HBM_clk : in std_logic; -- 400 MHz for the vcu128 board, up to 450 for production devices. Also used for general purpose processing.
        i_wall_clk : in std_logic;    -- 250 MHz, derived from the 125MHz OCXO. Used for timing of events (e.g. when to start reading in the corner turn)
        i_LFAA40GE_clk : in std_logic;
        -- wall time outputs in each clock domain
        o_clk_HBM_wallTime : out t_wall_time;      -- wall time in i_HBM_AXI_clk domain
        o_clk_LFAA40GE_wallTime : out t_wall_time; -- wall time in LFAA40GE clk domain
        o_clk_wall_wallTime : out t_wall_time;     -- wall time in wall clk domain
        
      -- MMCM for the 125 MHz clock is now at the top level
      --  -- FPGA pins
      --  clk_e_p : in std_logic;         -- Either 156.25 MHz or 125MHz PTP clk, output of PLL chip CDCM61004, controlled by ptp_clk_sel
      --  clk_e_n : in std_logic;
      
        --
        -- Serial interface to AD5662BRM nanodacs on the gemini board, which controls the voltage to two oscillators
        --   - 20 MHz, which comes in as 20 MHz on clk_f. This crystal has a range of +/-100 ppm, so better to use the 25 MHz crystal 
        --   - 25 MHz, which is converted up to either 156.25 MHz or 125 MHz, depending on ptp_clk_sel.
        --           The crystal has a range of +/-6 ppm (or maybe 12.. not clear which version we have). 
        --           This clock comes in on both sfp_clk_e_p/n and clk_e_p/n.
        --           sfp_clk_e_p/n could be used for synchronous ethernet/white rabbit.
        -- AD5662BRM info -
        --   - ptp_sclk maximum frequency is MHz
        --   - data sampled on the falling edge of ptp_sclk
        --   - 24 bits per command, with
        --      - 6 don't cares
        --      - "00" for normal operation (other options are power-down states).
        --      - 16 data bits, straight binary 0 to 65535.
        o_ptp_pll_reset : out std_logic;                     -- PLL reset
        o_ptp_clk_sel   : out std_logic;                     -- PTP Interface (156.25MH select when high)
        o_ptp_sync_n    : out std_logic_vector(1 downto 0);  -- bit(0) = active low enable for DAC controlling the clk_e = 25 MHz crystal (which is then upconverted to either 125 or 156.25 MHz), bit(1) = active low enable for DAC controlling the clk_f = 20 MHz crystal.  
        o_ptp_sclk      : out std_logic;
        o_ptp_din       : out std_logic;
        --------------------------------------------------------
        -- Time outputs
        -- Note - ptp_time_frac is in units of 8 ns, and counts 0 to 124999999.
        -- triggering of events should use ptp_time_frac(26 downto 3), which is in units of 64 ns
        -- and counts 0 to 15624999. ptp_time_frac may skip counts in order to
        -- match the master time that it is tracking, but every count of
        -- ptp_time_frac(26:3) will occur.
        o_pps           : out std_logic;
        --------------------------------------------------------
        -- Packets from the internal network
        -- Timing packets from other FPGAs come in on this link.
        -- Expected format is 3 words :
        --   (1) source MAC (6 bytes) + source port (1 byte) + packet type (1 byte)
        --       - This should be the header of all packets on the internal network
        --       - Packet type of 0 = timing information.
        --   (2) source time (24 bit fractional + 32 bit integer seconds + 1 byte unused).
        --   (3) Interval (24 bit fractional + 32 bit integer seconds + 1 bit to indicate valid)
        --       - This is the time gap since the last packet according to the remote clock.  
        --         The source time in the previous word can have jumps, so we cannot calculate the
        --         time locally.
        --   (4) Last word in the packet (FCS + 4 bytes unused).
        i_packet_valid : in std_logic;
        i_packet_data  : in std_logic_vector(63 downto 0)
        
        --clk              : IN STD_LOGIC;
        --rst              : IN STD_LOGIC;
        --pps              : OUT STD_LOGIC;
        --tod              : OUT STD_LOGIC_VECTOR(g_tod_width-1 DOWNTO 0);
        --tod_rollover     : OUT STD_LOGIC
    );
end timing_control;

architecture Behavioral of timing_control is
    
    ---------------------------------------------------------------------------
    -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
    ---------------------------------------------------------------------------
    
    --CONSTANT c_msCount_width      : INTEGER := ceil_log2(INTEGER(g_clk_freq / 1000.0 - 1.0));
    --CONSTANT c_msCount            : UNSIGNED(c_msCount_width-1 DOWNTO 0) := TO_UNSIGNED(INTEGER(g_clk_freq / 1000.0 - 1.0), c_msCount_width);
    
    ---------------------------------------------------------------------------
    -- SIGNAL DECLARATIONS  --
    ---------------------------------------------------------------------------
    
    -- Initial time set to Unix time at 12:20, friday, May 3, 2019
    signal wallTime : t_wall_time := (sec => "01011100110010111010011000011000", ns => "000000000000000000000000000000");   -- t_wall_time is a record with .sec and .ns
    signal wallTimePlus16ns : t_wall_time;
    signal MasterTime : t_wall_time;           -- Either from MACE or from a timing packet from another FPGA
    signal MasterTimeCorrected : t_wall_time;  -- Master Time after subtracting off the register value fixed_offset nanoseconds.
    
    signal ppsi : std_logic;
    
    signal ptp_clkiv : std_logic_vector(0 downto 0);
    signal dummy0 : std_logic_vector(0 downto 0);
    
    signal timing_rw : t_timing_rw;
    signal timing_ro : t_timing_ro;
    
    signal MACETime8ns : std_logic_vector(31 downto 0);
    signal fixedOffset : std_logic_vector(29 downto 0);
    signal MACETimeSec : std_logic_vector(31 downto 0);
    signal MACESetDel2, MACESetDel1 : std_logic := '0';
    signal copyMACETime : std_logic;
    signal MACETime8nsCorrected : std_logic_vector(31 downto 0);
    signal MACETime8nsCorrectedPlus1 : std_logic_vector(31 downto 0);
    
    signal MACETime : t_wall_time;
    signal MACETime_set : std_logic;
    signal MACETime_track : std_logic;
    signal masterTimeSet, masterTimeSetDel1, masterTimeSetDel2, masterTimeSetDel3 : std_logic;
    signal oldtopbit : std_logic;
    signal wallTimeSend : std_logic := '0';
    signal wallTimeSendDel1 : std_logic := '0';
    signal wallTimeHold : std_logic_vector(61 downto 0);
    signal wallTimeHBMClk : std_logic_vector(61 downto 0);
    signal wallTimeHBMClkValid : std_logic;
    signal wallTimeLFAAClkValid : std_logic;
    signal wallTimeLFAAClk : std_logic_vector(61 downto 0);
    
    
    --SIGNAL msCount                : UNSIGNED(c_msCount_width-1 DOWNTO 0);
    --SIGNAL msPulse                : STD_LOGIC;
    --SIGNAL ppsPulse               : STD_LOGIC;
    --SIGNAL ppsCount               : UNSIGNED(9 DOWNTO 0);
    --SIGNAL uptime_count           : UNSIGNED(g_tod_width-1 DOWNTO 0);
        
begin
    
    o_ptp_clk_sel <= '0';  -- select the 125 MHz clock.
    o_pps <= ppsi;
    
    o_clk_wall_wallTime <= wallTime;
    
    process(i_wall_clk)
    begin
        if rising_edge(i_wall_clk) then
        
            if (masterTimeSetDel2 = '1') then
                wallTime <= masterTime;
            elsif (unsigned(wallTime.ns) > 999999995) then
                wallTime.ns <= (others => '0');
                walltime.sec <= std_logic_vector(unsigned(wallTime.sec) + 1);
            else
                wallTime.ns <= std_logic_vector(unsigned(wallTime.ns) + 4);  -- Assumes i_wall_clk is 250 MHz.
            end if;
            
            if (unsigned(wallTime.ns) > 999999979) then
                wallTimePlus16ns.ns <= std_logic_vector(unsigned(wallTime.ns) + 20 - 1000000000);
                wallTimePlus16ns.sec <= std_logic_vector(unsigned(wallTime.sec) + 1);
            else
                wallTimePlus16ns.ns <= std_logic_vector(unsigned(wallTime.ns) + 20);
                wallTimePlus16ns.sec <= wallTime.sec;
            end if;
            
            
            if (unsigned(wallTime.ns) < 10000000) then  -- 10 ms
                ppsi <= '1';
            else
                ppsi <= '0';
            end if;
            
            -- Get the time from the master, either MACE (via a register setting) or another FPGA (via an input timing packet from the optics)
            -- and subtract off the register value fixedOffset
            -- When using MACE as the master,
            --  bit(31) of 
            -- Tracking of MACE time - subtract off the programmed offset to approximately account for the latency in setting the time
            MACESetDel1 <= MACETime_set;
            MACESetDel2 <= MACESetDel1;
            
            masterTimeSetDel1 <= masterTimeSet;
            masterTimeSetDel2 <= masterTimeSetDel1;
            masterTimeSetDel3 <= masterTimeSetDel2;
            
            if MACESetDel1 = '1' and MACESetDel2 = '0' then
                masterTimeSet <= '1';
                masterTime <= MACETime;
            else
                masterTimeSet <= '0';
            end if;
            
            if masterTimeSet = '1' then
                masterTime.ns <= std_logic_vector(unsigned(masterTime.ns) - unsigned(fixedOffset));
                oldtopbit <= masterTime.ns(29);
            elsif masterTimeSetDel1 = '1' then
                if oldTopBit = '0' and masterTime.ns(29) = '1' then
                    -- subtracting off the fixed offset caused us to go to the previous second
                    masterTime.sec <= std_logic_vector(unsigned(masterTime.sec) - 1);
                    masterTime.ns <= std_logic_vector(unsigned(masterTime.ns) + 1000000000);
                end if;
            end if;
            
        end if;
    end process;
    
    regif : entity work.timingControl_timingcontrol_reg
    port map (
        MM_CLK        => mm_clk, --  in std_logic;
        MM_RST        => mm_rst, --  in std_logic;
        st_clk_timing => ptp_clkiv, -- in STD_LOGIC_VECTOR(0 TO 0);
        st_rst_timing => dummy0,    -- in STD_LOGIC_VECTOR(0 TO 0);
        SLA_IN        => i_sla_in,  -- in t_axi4_lite_mosi;
        SLA_OUT       => o_sla_out, -- out t_axi4_lite_miso;
        TIMING_FIELDS_RW => timing_rw, -- OUT t_timing_rw;
        TIMING_FIELDS_RO => timing_ro  -- IN  t_timing_ro
    );
    
    ptp_clkiv(0) <= i_wall_clk;
    dummy0(0) <= '0';
    
    MACETime.sec <= timing_rw.mace_time_seconds;
    MACETime.ns <= timing_rw.mace_time_ns(29 downto 0);
    MACETime_set <= timing_rw.mace_time_ns(31);
    MACETime_track <= timing_rw.mace_time_ns(30);
    
    fixedOffset <= "000000" & timing_rw.fixed_offset;
    
    timing_ro.cur_time_seconds <= wallTime.sec;
    timing_ro.cur_time_ns <= "00" & wallTime.ns;
    timing_ro.last_freq_offset <= (others => '0');
    timing_ro.filtered_freq_offset <= (others => '0');
    timing_ro.last_time_offset <= (others => '0');
    timing_ro.filtered_time_offset <= (others => '0');
    
    -- Fields in the structure :
    --  TIMING_FIELDS_RW.vc_step_size	   <= timing_out_reg(c_byte_w*0+15 downto c_byte_w*0);
    --  TIMING_FIELDS_RW.ocxo_forget       <= timing_out_reg(c_byte_w*4+3 downto c_byte_w*4);
    --  TIMING_FIELDS_RW.timing_forget     <= timing_out_reg(c_byte_w*8+3 downto c_byte_w*8);
    --  TIMING_FIELDS_RW.track_select      <= timing_out_reg(c_byte_w*12+7 downto c_byte_w*12);
    --  TIMING_FIELDS_RW.fixed_offset      <= timing_out_reg(c_byte_w*16+23 downto c_byte_w*16);  -- Offset is in units of 8 ns.
    --  TIMING_FIELDS_RW.mace_time_seconds <= timing_out_reg(c_byte_w*20+31 downto c_byte_w*20);
    --  TIMING_FIELDS_RW.mace_time_8ns	   <= timing_out_reg(c_byte_w*24+31 downto c_byte_w*24);  -- Note rising edge of bit(31) means set the time to the MACE value, bit(30) tells this module to track this MACE time.
    -- 
    --  TIMING_FIELDS_RO.cur_time_seconds;
    --  TIMING_FIELDS_RO.cur_time_8ns;
    --  TIMING_FIELDS_RO.last_freq_offset;
    --  TIMING_FIELDS_RO.filtered_freq_offset;
    --  TIMING_FIELDS_RO.last_time_offset;
    --  TIMING_FIELDS_RO.filtered_time_offset;
    
    -----------------------------------------------------------------------------------
    -- Division operation to get the frequency offset
    -- Uses repeated subtraction.
    -- (from common library)
    
    -- multiply by 2^32, so the division result is in units of roughly 1/4 of 1 ppb
--    master_minus_slave_ext(47 downto 32) <= master_minus_slave;
--    master_minus_slave_ext(31 downto 0) <= (others => '0');
--    
--    divide1 : common_lib.common_divide
--    generic map (
--        BitsNumerator   => 48;  -- Number of bits in the numerator
--        BitsDenominator => 32;  -- Number of bits in the denominator
--        BitsInt         => 16;  -- Number of integer bits to generate
--        BitsFrac        => 0;  -- Number of fractional bits to generate
--    );
--    port (
--        rst   => '0',
--        clk   => ptp_clki,
--        rdy_o => div_rdy,
--        valid_i => get_timing_error,         -- in std_logic;
--        numerator_i   => master_minus_slave_ext, -- in std_logic_vector((BitsNumerator - 1) downto 0);
--        denominator_i => slave_time,         -- in std_logic_vector((BitsDenominator - 1) downto 0);
--        quotient_o => timing_error,          -- out std_logic_vector((BitsInt + BitsFrac - 1) downto 0);
--        valid_o    => timing_error_valid     -- out std_logic;
--    );
    
    
    -----------------------------------------------------------------------------
    --
    -----------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    -- Get the wall time into the i_IC_clk domain
    -- Continuously transfers the current wall clock time to the i_IC_clk domain.
    
    process(i_wall_clk)
    begin
        if rising_edge(i_wall_clk) then
            if wallTimeSend = '0' and wallTimeSendDel1 = '0' then
                wallTimeSend <= '1';  -- hold high for two clocks
            elsif wallTimeSend = '1' and wallTimeSendDel1 = '1' then
                wallTimeSend <= '0';  -- hold low for two clocks
            end if;
            wallTimeSendDel1 <= wallTimeSend;
        end if;
    end process;
    
    wallTimeHold <= wallTimePlus16ns.sec & wallTimePlus16ns.ns;
    
    -- xpm_cdc_handshake: Clock Domain Crossing Bus Synchronizer with Full Handshake
    -- Xilinx Parameterized Macro,
    -- This captures the value on src_in on the first cycle where src_send is high.
    -- A single bit crosses the clock domain with resynchronising registers to trigger capture
    -- of the src_in value on another set of registers using dest_clk.
    -- Usage guidelines say that we should wait until src_rcv goes high, then clear src_send,
    -- then wait until src_rcv goes low again before setting src_send.
    -- However, this means it takes many clocks between transfers.
    -- All that really matters is that the single bit synchronising signal (i.e. src_send) is reliably captured in 
    -- the dest_clk domain. If dest_clk is faster than src_clk, then this is guaranteed providing we hold src_send 
    -- unchanged for two clocks.
    -- So we can safely update dest_out every 4 src_clk cycles by driving src_send high two clocks, low two clocks.
    --
    -- Latency through the synchroniser = (1 src_clk cycle) + (DEST_SYNC_FF * dest_clk cycles) + (up to 1 dest_clk_cycle)
    -- e.g. if src_clk period = 4 ns, dest_clk period = 2.5 ns, then latency = 9 to 11.5 ns
    xpm_cdc_handshake1i : xpm_cdc_handshake
    generic map (
        -- Common module generics
        DEST_EXT_HSK   => 0, -- integer; 0=internal handshake, 1=external handshake
        DEST_SYNC_FF   => 2, -- integer; range: 2-10
        INIT_SYNC_FF   => 0, -- integer; 0=disable simulation init values, 1=enable simulation init values
        SIM_ASSERT_CHK => 0, -- integer; 0=disable simulation messages, 1=enable simulation messages. Turn this off so it doesn't complain about violating recommended behaviour or src_send.
        SRC_SYNC_FF    => 2, -- integer; range: 2-10
        WIDTH          => 62 -- integer; range: 1-1024
    )
    port map (
        src_clk  => i_wall_clk,
        src_in   => wallTimeHold, -- src_in is captured by internal registers on the rising edge of src_send (i.e. in the first src_clk where src_send = '1')
        src_send => wallTimeSend,
        src_rcv  => open,         -- Not used; see discussion above.
        dest_clk => i_HBM_clk,
        dest_req => wallTimeHBMClkValid,
        dest_ack => '0', -- optional; required when DEST_EXT_HSK = 1
        dest_out => wallTimeHBMClk
    );
    
    process(i_HBM_clk)
    begin
        if rising_edge(i_HBM_clk) then
            if wallTimeHBMClkValid = '1' then
                o_clk_HBM_wallTime.sec <= wallTimeHBMClk(61 downto 30);
                o_clk_HBM_wallTime.ns <= wallTimeHBMClk(29 downto 0);
            end if;
        end if;
    end process;
    
    xpm_cdc_handshake2i : xpm_cdc_handshake
    generic map (
        -- Common module generics
        DEST_EXT_HSK   => 0, -- integer; 0=internal handshake, 1=external handshake
        DEST_SYNC_FF   => 2, -- integer; range: 2-10
        INIT_SYNC_FF   => 0, -- integer; 0=disable simulation init values, 1=enable simulation init values
        SIM_ASSERT_CHK => 0, -- integer; 0=disable simulation messages, 1=enable simulation messages. Turn this off so it doesn't complain about violating recommended behaviour or src_send.
        SRC_SYNC_FF    => 2, -- integer; range: 2-10
        WIDTH          => 62 -- integer; range: 1-1024
    )
    port map (
        src_clk  => i_wall_clk,
        src_in   => wallTimeHold,  -- src_in is captured by internal registers on the rising edge of src_send (i.e. in the first src_clk where src_send = '1')
        src_send => wallTimeSend,
        src_rcv  => open,          -- Not used; see discussion above.
        dest_clk => i_LFAA40GE_clk,
        dest_req => wallTimeLFAAClkValid,
        dest_ack => '0', -- optional; required when DEST_EXT_HSK = 1
        dest_out => wallTimeLFAAClk
    );
    
    process(i_LFAA40GE_clk)
    begin
        if rising_edge(i_LFAA40GE_clk) then
            if wallTimeLFAAClkValid = '1' then
                o_clk_LFAA40GE_wallTime.sec <= wallTimeLFAAClk(61 downto 30);
                o_clk_LFAA40GE_wallTime.ns <= wallTimeLFAAClk(29 downto 0);
            end if;
        end if;
    end process;
    
    
end Behavioral;
