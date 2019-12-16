------------------------------------------------------------------------------------
-- Company: CSIRO
-- Engineer: David Humphrey (dave.humphrey@csiro.au)
-- 
-- Create Date: 08.03.2019 15:11:37
-- Module Name: LFAADecodeTop - Behavioral
-- Description: 
--  Decode LFAA packets.
-- Assumptions:
--  - No Q-tags for ethernet frames; ethertype field will always be 2 bytes
--  - IPv4 will always be 20 bytes long
--  - 40GE MAC will always put at least 8 bytes of idle time on the data_rx_sosi bus
--
-- About timestamps :
--  Original intention was to use ptp for timing, which uses a 68 bit timestamp
--  The 68 bit PTP timestamp allows for 40 bits of seconds, and 28 fractional
--  bits, with the fractional part counting up to 124,999,999 for each second
--  using a 125 MHz clock. The PTP epoch is january 1 1970. A 32 bit count of
--  seconds corresponds to about 136 years.
--  An alternative approach is to synchronise time between FPGAs using an
--  exchange of timestamps between FPGA on the internal interconnect.
--  Whichever method is used, the timestamp into this module should use a 125
--  MHz clock, with 28 fractional bits counting 0 to 124,999,999, and 32
--  integer bits (for a maximum future date of around 2106)
--  
--  The timestamp of the most recent packet for each virtual channel is recorded
--  here with a fractional part using 24 bits, counting from 0 to 15624999, i.e. in units of 64
--  ns, and a 32 bit integer part.
--
-- Structure :
--  - LFAAProcess : Takes in the data from the 40GE interface, validates it and outputs packets 
--                  for downstream processing, with a header that contains the virtual channel.
--  - dummyProcess : Ignores the 40GE interface, and instead outputs packets in accord with the
--                   virtual channel table, with data generated from an LFSR.
--  - muxBlock : Grants either LFAAProcess or dummyProcess access to the virtual channel table 
--               and virtual channel statistics memories, which reside in the registers.
--  - registers : register interface for control and statistics registers, and also for the 
--                virtual channel table and 
--  - ptpBlock : transfer ptp time to the data_clk domain.
------------------------------------------------------------------------------------

library IEEE, axi4_lib, xpm, LFAADecode_lib, ctc_lib, dsp_top_lib;
--use ctc_lib.ctc_pkg.all;
use DSP_top_lib.DSP_top_pkg.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use axi4_lib.axi4_stream_pkg.ALL;
use axi4_lib.axi4_lite_pkg.ALL;
use axi4_lib.axi4_full_pkg.ALL;
use xpm.vcomponents.all;
use LFAADecode_lib.LFAADecode_lfaadecode_reg_pkg.ALL;

entity LFAADecodeTop is
    port(
        -- Data in from the 40GE MAC
        i_data_rx_sosi   : in t_axi4_sosi;   -- 128 bit wide data in, only fields that are used are .tdata, .tvalid, .tuser
        o_data_rx_siso   : out t_axi4_siso;  -- Only tready, and actually ignored by the 40GE MAC 
        i_data_clk       : in std_logic;     -- 312.5 MHz for 40GE MAC
        i_data_rst       : in std_logic;
        -- Data out 
        o_data_out       : out std_logic_vector(127 downto 0);
        o_valid_out      : out std_logic;
        -- miscellaneous
        i_my_mac         : in std_logic_vector(47 downto 0); -- MAC address for this board; incoming packets from the 40GE interface are filtered using this.
        i_wallTime       : in t_wall_time;
        -- Registers AXI Lite Interface
        i_s_axi_mosi     : in t_axi4_lite_mosi;
        o_s_axi_miso     : out t_axi4_lite_miso;
        i_s_axi_clk      : in std_logic;
        i_s_axi_rst      : in std_logic;
        -- registers AXI Full interface
        i_vcstats_MM_IN  : in  t_axi4_full_mosi;
        o_vcstats_MM_OUT : out t_axi4_full_miso;
        -- debug ports
        o_dbg            : out std_logic_vector(13 downto 0)
   );
end LFAADecodeTop;

architecture Behavioral of LFAADecodeTop is

    signal reg_rw    : t_statctrl_rw;
    signal LFAAreg_count, testReg_count, reg_count : t_statctrl_count;
    
    signal LFAAData_out, testdata_out, data_out : std_logic_vector(127 downto 0);
    signal LFAAValid_out, testValid_out, valid_out : std_logic;

    signal vstats_field_wr : t_vstats_rw;
    signal vstats_field_ro : t_vstats_ro;
    signal vstats_channelPower_in : t_vstats_channelpower_ram_in;
    signal vstats_channelPower_out : t_vstats_channelpower_ram_out;
    signal vstats_VHistogram_in    : t_vstats_vhistogram_ram_in;
    signal vstats_VHistogram_out   : t_vstats_vhistogram_ram_out;
    
    signal ptp_hold, ptp_out : std_logic_vector(58 downto 0);
    signal ptp_send : std_logic := '0';
    signal ptp_rcv : std_logic;
    signal ptp_valid : std_logic;
    signal data_clk_vec : std_logic_vector(0 downto 0);
    
    -- One only of the "LFAAProcess" and the "TestProcess" modules controls the memories in the registers.
    signal LFAAVCTable_addr, testVCTable_addr : std_logic_vector(9 downto 0);
    signal LFAAstats_wr_data, testStats_wr_data : std_logic_vector(31 downto 0);
    signal LFAAstats_we, testStats_we : std_logic;
    signal LFAAstats_addr, testStats_addr : std_logic_vector(12 downto 0); 
    signal VCTable_ram_in : t_statctrl_vctable_ram_in;
    signal VCTable_ram_out : t_statctrl_vctable_ram_out;
    
    signal VCStats_ram_in_wr_dat : std_logic_vector(31 downto 0);
    signal VCStats_ram_in_wr_en : std_logic; 
    signal VCStats_ram_in_adr : std_logic_vector(12 downto 0);
    signal VCStats_ram_out_rd_dat : std_logic_vector(31 downto 0);
    
    signal reg_ro : t_statctrl_ro;
    
begin
    
    o_data_out <= data_out;
    o_valid_out <= valid_out;
    
    process(i_data_clk)
    begin
        if rising_edge(i_data_clk) then
            if (reg_rw.packetgenmode = "000") then
                data_out <= LFAAData_out;
                valid_out <= LFAAValid_out;
            else
                data_out <= testData_out;
                valid_out <= testValid_out;
            end if;
        end if;
    end process;
        
    
    -------------------------------------------------------------------------------------------------
    -- Process packets from the 40GE LFAA input 
    --
    
    -- Always ready for a new packet, although this is actually ignored (assumed high) by the 40G MAC.
    o_data_rx_siso.tready <= '1';
    
    LFAAProcessInst : entity LFAADecode_lib.LFAAProcess
    port map(
        -- Data in from the 40GE MAC
        i_data_rx_sosi    => i_data_rx_sosi, -- in t_axi4_sosi;   -- 128 bit wide data in, only fields that are used are .tdata, .tvalid, .tuser
        i_data_clk        => i_data_clk,     -- in std_logic;     -- 312.5 MHz for 40GE MAC
        i_data_rst        => i_data_rst,     -- in std_logic;
        -- Data out 
        o_data_out        => LFAAData_out,   -- out(127:0);
        o_valid_out       => LFAAValid_out,  -- out std_logic;
        -- Miscellaneous
        i_my_mac          => i_my_mac,       -- in(47:0); -- MAC address for this board; incoming packets from the 40GE interface are filtered using this.
        i_wallTime        => i_wallTime,     -- in t_wall_time; Defined in DSP_top_pkg, 32 bit seconds (.sec), 30 bit nanoseconds (.ns). 
        --i_time_sec        => ptp_out(58 downto 27),     -- PTP time; 32 bit second count and 27 bit fractional count. (note this module records a 32 bit second count and 24 bit fractional count)
        --i_time_frac       => ptp_out(26 downto 0),
        -- Interface to the registers
        i_reg_rw          => reg_rw,         -- in t_statctrl_rw;
        o_reg_count       => LFAAreg_count,  -- out t_statctrl_count;
        -- Virtual channel table memory in the registers
        o_searchAddr      => LFAAVCTable_addr,    -- out std_logic_vector(9 downto 0); -- read address to the VCTable_ram in the registers.
        i_VCTable_rd_data => VCTable_ram_out.rd_dat, -- in std_logic_vector(31 downto 0); -- read data from VCTable_ram in the registers; assumed valid 2 clocks after searchAddr.
        -- Virtual channel stats in the registers.
        o_statsWrData     => LFAAstats_wr_data, -- out std_logic_vector(31 downto 0);
        o_statsWE         => LFAAstats_we,      -- out std_logic;
        o_statsAddr       => LFAAstats_addr,    -- out std_logic_vector(12 downto 0);
        i_statsRdData     => VCStats_ram_out_rd_dat,  -- in  std_logic_vector(31 downto 0)
        -- debug ports
        o_dbg             => o_dbg
    );
    

    -------------------------------------------------------------------------------------------------
    -- Generation of Dummy data. 
    -- 
    dummygenInst : entity LFAADecode_lib.TestProcess
    port map (
        i_data_clk         => i_data_clk,
        i_data_rst         => i_data_rst,
        -- Data out 
        o_data_out         => testData_out,  -- out(127:0);
        o_valid_out        => testValid_out, -- out std_logic;
        -- Miscellaneous
        i_time_sec         => ptp_out(58 downto 27),    -- in(31:0);  -- PTP time; 32 bit second count and 24 bit fractional count. (note this module records a 32 bit second count and 24 bit fractional count)
        i_time_frac        => ptp_out(26 downto 3),    -- units of 64 ns for test data.
        -- Interface to the registers
        i_reg_rw           => reg_rw,        -- in t_statctrl_rw;
        o_reg_ro           => reg_ro,        -- out t_statctrl_ro;
        o_reg_count        => testReg_count, -- out t_statctrl_count;
        -- Virtual channel table memory in the registers
        o_searchAddr       => testVCTable_addr, -- out std_logic_vector(9 downto 0); -- read address to the VCTable_ram in the registers.
        i_VCTable_rd_data  => VCTable_ram_out.rd_dat, -- in std_logic_vector(31 downto 0); -- read data from VCTable_ram in the registers; assumed valid 2 clocks after searchAddr.
        -- Virtual channel stats in the registers.
        o_statsWrData      => testStats_wr_data, -- out std_logic_vector(31 downto 0);
        o_statsWE          => testStats_we,      -- out std_logic;
        o_statsAddr        => testStats_addr,    -- out std_logic_vector(11 downto 0);
        i_statsRdData      => VCStats_ram_out_rd_dat  -- in  std_logic_vector(31 downto 0)         
    );
    
    
    ---------------------------------------------------------------------------------------------------
    -- Mux the LFAA and test to the registers, depending on the mode we are in.
    
    data_clk_vec(0) <= i_data_clk;
        
    -- VCTable memory inputs
    VCTable_ram_in.rd_en <= '1';
    VCTable_ram_in.clk <= i_data_clk;
    VCTable_ram_in.wr_dat <= (others => '0'); -- STD_LOGIC_VECTOR(31 downto 0); -- never write to the virtual channel table.
    VCTable_ram_in.wr_en <= '0';
    VCTable_ram_in.adr <= LFAAVCTable_addr when (reg_rw.packetgenmode = "000") else testVCTable_addr; -- STD_LOGIC_VECTOR(9 downto 0);
    VCTable_ram_in.rst <= '0';
    -- VCTable memory outputs
    --VCTable_ram_out.rd_dat    -- STD_LOGIC_VECTOR(31 downto 0);
    --VCTable_ram_out.rd_val  -- STD_LOGIC;
    
    -- VCStats memory inputs
    --VCStats_ram_in.rd_en <= '1';
    --VCStats_ram_in.clk <= i_data_clk;
    VCStats_ram_in_wr_dat <= LFAAstats_wr_data when (reg_rw.packetgenmode = "000") else testStats_wr_data; -- (31:0);
    VCStats_ram_in_wr_en <= LFAAstats_we when (reg_rw.packetgenmode = "000") else testStats_we;
    VCStats_ram_in_adr <= LFAAstats_addr when (reg_rw.packetgenmode = "000") else testStats_addr; -- STD_LOGIC_VECTOR(12 downto 0);
    --VCStats_ram_in.rst <= '0';
    -- VCStats memory outputs
    --VCStats_ram_out.rd_dat; -- STD_LOGIC_VECTOR(31 downto 0);
    --VCStats_ram_out.rd_val; -- STD_LOGIC;    
    
    reg_count <= LFAAreg_count when (reg_rw.packetgenmode = "000") else testreg_count;
    
    ---------------------------------------------------------------------------------------------------
    -- Register interface
    regif : entity work.LFAADecode_lfaadecode_reg
    --   GENERIC (g_technology : t_technology := c_tech_select_default);
    port map (
        MM_CLK               => i_s_axi_clk, --  IN    STD_LOGIC;
        MM_RST               => i_s_axi_rst, --  IN    STD_LOGIC;
        st_clk_statctrl      => data_clk_vec,
        st_rst_statctrl      => "0",
        st_clk_vstats        => data_clk_vec,
        st_rst_vstats        => "0",
        SLA_IN               => i_s_axi_mosi, --  IN    t_axi4_lite_mosi;
        SLA_OUT              => o_s_axi_miso, --  OUT   t_axi4_lite_miso;
        statctrl_fields_rw   => reg_rw,       --  out t_statctrl_rw;
        statctrl_fields_ro	 => reg_ro,       --  in  t_statctrl_ro;
        statctrl_fields_count => reg_count,   --  in t_statctrl_count;
        --statctrl_fields_RO => reg_ro, -- : IN  t_lfaadecode_ro;
        count_rsti           => '0', -- : in std_logic := '0'
        statctrl_VCTable_in  => VCTable_ram_in, -- in t_statctrl_vctable_ram_in;
        statctrl_VCTable_out => VCTable_ram_out, -- OUT t_statctrl_vctable_ram_out;
        --statctrl_VCStats_in  => VCStats_ram_in,  -- IN  t_statctrl_vcstats_ram_in;
        --statctrl_VCStats_out => VCStats_ram_out,  -- OUT t_statctrl_vcstats_ram_out
        --
        VSTATS_FIELDS_RW		=> vstats_field_wr, -- : OUT t_vstats_rw;
        VSTATS_FIELDS_RO        => vstats_field_ro, -- : IN  t_vstats_ro;
        VSTATS_CHANNELPOWER_IN  => vstats_channelPower_in,  -- IN  t_vstats_channelpower_ram_in;
        VSTATS_CHANNELPOWER_OUT => vstats_channelPower_out, -- OUT t_vstats_channelpower_ram_out;
        VSTATS_VHISTOGRAM_IN    => vstats_VHistogram_in,    -- IN  t_vstats_vhistogram_ram_in;
        VSTATS_VHISTOGRAM_OUT   => vstats_VHistogram_out    -- OUT t_vstats_vhistogram_ram_out
    );
    
    data_clk_vec(0) <= i_data_clk; 

    regif2 : entity work.LFAADecode_lfaadecode_vcstats_ram
    --GENERIC (
    --    g_ram_b     : t_c_mem   := (latency => 1, adr_w => 13, dat_w => 32, addr_base => 0, nof_slaves => 1, nof_dat => 8192, init_sl => '0')
    --);
    port map (
        CLK_A       => i_s_axi_clk, -- in STD_LOGIC;
        RST_A       => i_s_axi_rst, -- in STD_LOGIC;
        CLK_B       => i_data_clk,  -- in STD_LOGIC;
        RST_B       => '0',         -- in STD_LOGIC;
        MM_IN       => i_vcstats_MM_IN,  -- in  t_axi4_full_mosi;
        MM_OUT      => o_vcstats_MM_out, -- out t_axi4_full_miso;
        --
        user_we     => VCStats_ram_in_wr_en,  --  in    std_logic;
        user_addr   => VCStats_ram_in_adr,    --  in    std_logic_vector(g_ram_b.adr_w-1 downto 0);
        user_din    => VCStats_ram_in_wr_dat, --  in    std_logic_vector(g_ram_b.dat_w-1 downto 0);
        user_dout   => VCStats_ram_out_rd_dat --  out   std_logic_vector(g_ram_b.dat_w-1 downto 0)  
    );

   --i_vcstats_MM_IN  : in  t_axi4_full_mosi;
   --     o_vcstats_MM_OUT

    ----------------------------------------------------------------------------------------
    -- Statistics capture
    --
    statsCapture : entity work.LFAAStats
    port map(
        -- Data in
        data_in   => data_out,   -- in std_logic_vector(127 downto 0);
        valid_in  => valid_out,  -- in std_logic;
        data_clk   => i_data_clk,      -- in std_logic;
        -- Register interface
        VSTATS_FIELDS_RW		=> vstats_field_wr, --  in t_vstats_rw;
        VSTATS_FIELDS_RO        => vstats_field_ro, -- : out  t_vstats_ro;
        VSTATS_CHANNELPOWER_IN  => vstats_channelPower_in,  -- out  t_vstats_channelpower_ram_in;
        VSTATS_CHANNELPOWER_OUT => vstats_channelPower_out, -- in t_vstats_channelpower_ram_out;
        VSTATS_VHISTOGRAM_IN    => vstats_VHistogram_in,    -- out  t_vstats_vhistogram_ram_in;
        VSTATS_VHISTOGRAM_OUT   => vstats_VHistogram_out    -- in t_vstats_vhistogram_ram_out
    );
    
end Behavioral;
