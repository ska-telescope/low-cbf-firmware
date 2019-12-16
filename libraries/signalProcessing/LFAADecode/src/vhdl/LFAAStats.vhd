----------------------------------------------------------------------------------
-- Company: CSIRO 
-- Engineer: David Humphrey (dave.humphrey@csiro.au)
-- 
-- Create Date: 02.04.2019 13:40:03
-- Module Name: LFAAStats - Behavioral
-- Description: 
--  Log statistics for the data coming in from LFAA.
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
Library xpm;
use xpm.vcomponents.all;
USE work.LFAADecode_lfaadecode_reg_pkg.ALL;

entity LFAAStats is
    port(
        -- Data in
        data_in   : in std_logic_vector(127 downto 0);
        valid_in  : in std_logic;
        data_clk   : in std_logic;
        -- Register interface
        VSTATS_FIELDS_RW		: in t_vstats_rw;
        VSTATS_FIELDS_RO        : out  t_vstats_ro;
        VSTATS_CHANNELPOWER_IN  : out  t_vstats_channelpower_ram_in;
        VSTATS_CHANNELPOWER_OUT : in t_vstats_channelpower_ram_out;
        VSTATS_VHISTOGRAM_IN    : out  t_vstats_vhistogram_ram_in;
        VSTATS_VHISTOGRAM_OUT   : in t_vstats_vhistogram_ram_out
    );
end LFAAStats;

architecture Behavioral of LFAAStats is

    signal sampleSelect : std_logic_vector(1 downto 0); -- Only one of the four samples received in a clock cycle is used for power; this selects which one.
    signal VpolRe : std_logic_vector(8 downto 0);
    signal VpolIm : std_logic_vector(8 downto 0);
    signal HpolRe : std_logic_vector(8 downto 0);
    signal HpolIm : std_logic_vector(8 downto 0);
    signal valid_in_del : std_logic;
    signal sampleValid : std_logic;
    signal curVirtualChannel : std_logic_vector(8 downto 0);
    signal curStationSelect : std_logic;
    
    signal VpolReSqr, VpolImSqr, HpolReSqr, HpolImSqr : signed(17 downto 0);
    signal sampleValidDel1 : std_logic;

    signal VpolReSqrExt, VpolImSqrExt, HpolReSqrExt, HpolImSqrExt : signed(31 downto 0);
    signal sampleValidDel2 : std_logic;    

    signal sampleValidDel3 : std_logic;
    signal VpolSqrSum, HpolSqrSum : signed(31 downto 0); 

    signal sampleValidDel4 : std_logic;
    signal VpolAccumulator : signed(31 downto 0);
    signal HpolAccumulator : signed(31 downto 0);

    signal newVpol, newHpol : signed(31 downto 0);
    signal virtualChannel : std_logic_vector(8 downto 0);
    signal stationSelect : std_logic;
    signal newPowerValid : std_logic;

    signal oldVpol, oldHpol : std_logic_vector(31 downto 0);
    signal channelPowerWrDat : std_logic_vector(31 downto 0);
    signal channelPowerWrEn : std_logic;
    signal channelPowerAddr : std_logic_vector(11 downto 0);
    signal oldSamples : std_logic_vector(31 downto 0);
    signal channelPowerRdDat : std_logic_vector(31 downto 0);

    type t_power_fsm is (idle, clr_mem, rd_Vpol, rd_Hpol, get_samples, get_Vpol, get_Hpol, check_ok, wr_samples, wr_Vpol, wr_Hpol);
    signal power_fsm : t_power_fsm := idle;        
    signal clearMemory, control_powerrun, control_powerrun_del : std_logic := '0';

    -- FIFO holds an input packet while we process it for the voltage histogram. 
    signal FIFO_rst : std_logic;
    signal FIFO_wr : std_logic;
    signal FIFO_prog_full : std_logic;
    signal FIFO_rd : std_logic;
    signal FIFO_dout : std_logic_vector(127 downto 0);
    signal FIFO_din : std_logic_vector(127 downto 0);
    signal FIFO_empty : std_logic;

    signal control_VHrun_del, control_VHrun : std_logic := '0';
    signal VHPacketsDone : std_logic_vector(31 downto 0) := (others => '0');
    signal VHWrEn : std_logic;
    signal VHWrDat : std_logic_vector(31 downto 0);
    signal VHAddr : std_logic_vector(9 downto 0);
    type t_vh_fsm is (idle, clear_memory, rd_fifo, get_fifo_data, rd_shift, wr_back);
    signal vh_fsm : t_vh_fsm := idle;
    signal VHCount : std_logic_vector(1 downto 0) := "00"; -- counts through the 4 samples in the word read from the FIFO.
    signal rdShiftCount : std_logic_vector(1 downto 0) := "00"; -- counts through the four sample types for reading (Vpol Real, Vpol Imaginary, Hpol Real, Hpol Imaginary).
    signal wrShiftCount : std_logic_vector(1 downto 0) := "00"; -- counts through the four sample types for writing.
    signal VHData : std_logic_vector(127 downto 0);
    signal VHData_del1, VHData_del2, VHData_del3, VHData_del4 : std_logic_vector(7 downto 0);
    signal VHSamplesDone : std_logic_vector(31 downto 0) := (others => '0');
    signal vh_dat_del1, vh_dat_plus1 : std_logic_vector(31 downto 0) := (others => '0');
    signal clear_VH : std_logic := '0';
    signal VHDone : std_logic := '0';
    signal VHPacketMatch : std_logic := '0';
    signal VHDroppedWord : std_logic := '0';

begin

    process(data_clk)
    begin
        if rising_edge(data_clk) then
            
            --------------------------------------------------------------------------------------------
            --------------------------------------------------------------------------------------------
            -- POWER CAPTURE
            --
            -- As a packet comes in, accumulate the power for the given virtual channel
            
            valid_in_del <= valid_in;
            if valid_in = '1' and valid_in_del = '0' then
                sampleSelect <= "00";
                curVirtualChannel <= data_in(8 downto 0);
                curStationSelect <= data_in(59);
            elsif valid_in = '1' then
                sampleSelect <= std_logic_vector(unsigned(sampleSelect) + 1); -- which of the 4 samples available that we look at changes each clock, so we sample all offsets.
            end if;
            
            -- first stage of pipeline to get the power
            sampleValid <= valid_in_del and valid_in; -- Drop the header word; high for 512 clocks when 
            if sampleSelect = "00" then
                VpolRe <= data_in(7) & data_in(7 downto 0);
                VpolIm <= data_in(15) & data_in(15 downto 8);
                HpolRe <= data_in(23) & data_in(23 downto 16);
                HpolIm <= data_in(31) & data_in(31 downto 24);
            elsif sampleSelect = "01" then
                VpolRe <= data_in(39) & data_in(39 downto 32);
                VpolIm <= data_in(47) & data_in(47 downto 40);
                HpolRe <= data_in(55) & data_in(55 downto 48);
                HpolIm <= data_in(63) & data_in(63 downto 56);            
            elsif sampleSelect = "10" then
                VpolRe <= data_in(71) & data_in(71 downto 64);
                VpolIm <= data_in(79) & data_in(79 downto 72);
                HpolRe <= data_in(87) & data_in(87 downto 80);
                HpolIm <= data_in(95) & data_in(95 downto 88);            
            else
                VpolRe <= data_in(103) & data_in(103 downto 96);
                VpolIm <= data_in(111) & data_in(111 downto 104);
                HpolRe <= data_in(119) & data_in(119 downto 112);
                HpolIm <= data_in(127) & data_in(127 downto 120);
            end if;
            
            -- second stage
            sampleValidDel1 <= sampleValid;
            VpolReSqr <= signed(VpolRe) * signed(VpolRe);
            VpolImSqr <= signed(VpolIm) * signed(VpolIm);
            HpolReSqr <= signed(HpolRe) * signed(HpolRe);
            HpolImSqr <= signed(HpolIm) * signed(HpolIm);
            
            -- third stage
            sampleValidDel2 <= sampleValidDel1;
            VpolReSqrExt(17 downto 0) <= VpolReSqr;
            VpolReSqrExt(31 downto 18) <= "00000000000000"; -- squared value must be positivie.
            VpolImSqrExt(17 downto 0) <= VpolImSqr;
            VpolIMSqrExt(31 downto 18) <= "00000000000000";
            HpolReSqrExt(17 downto 0) <= HpolReSqr;
            HpolReSqrExt(31 downto 18) <= "00000000000000";
            HpolImSqrExt(17 downto 0) <= HpolImSqr;
            HpolImSqrExt(31 downto 18) <= "00000000000000";
            
            -- fourth stage
            sampleValidDel3 <= sampleValidDel2;
            VpolSqrSum <= VpolReSqrExt + VpolImSqrExt;
            HpolSqrSum <= HpolReSqrExt + HpolImSqrExt;
            
            -- fifth stage; accumulator
            if sampleValidDel2 = '1' and sampleValidDel3 = '0' then
                VpolAccumulator <= (others => '0');
                HpolAccumulator <= (others => '0');
            elsif sampleValidDel3 = '1' then
                VpolAccumulator <= VpolAccumulator + VpolSqrSum;
                HpolAccumulator <= HpolAccumulator + HpolSqrSum;
            end if;
            sampleValidDel4 <= sampleValidDel3;
            
            -- End of the line; capture the accumulated value for the packet and use a state machine to do a read-modify-write to update the memory in the registers.
            if (sampleValidDel4 = '1' and sampleValidDel3 = '0') then -- accumulation is finished
                newVpol <= VpolAccumulator;
                newHpol <= HpolAccumulator;
                virtualChannel <= curVirtualChannel;
                stationSelect <= curStationSelect;
                newPowerValid <= '1';
            else
                newPowerValid <= '0';
            end if;
            
            control_powerrun <= VSTATS_FIELDS_RW.control_powerrun;
            control_powerrun_del <= control_powerrun;
            
            clearMemory <= control_powerrun and (not control_powerrun_del); -- rising edge of enable for running power calculation.
            
            if control_powerrun = '0' then
                power_fsm <= idle;
            else
                case power_fsm is
                    when idle =>
                        if clearMemory = '1' then
                            channelPowerAddr <= (others => '0');
                            power_fsm <= clr_mem;
                            channelPowerWrEn <= '1';
                            channelPowerWrDat <= (others => '0');
                        elsif control_powerrun_del = '1' and newPowerValid = '1' then
                            -- Read the current number of samples
                            channelPowerAddr <= virtualChannel & stationSelect & "00";  -- Offset of 0 = Number of packets accumulated so far
                            power_fsm <= rd_Vpol;
                            channelPowerWrEn <= '0';
                        else
                            channelPowerWrEn <= '0';
                        end if;
                        
                    when clr_mem =>
                        if unsigned(channelPowerAddr) = 3071 then
                            power_fsm <= idle;
                            channelPowerWrEn <= '0';
                        else
                            channelPowerAddr <= std_logic_vector(unsigned(channelPowerAddr) + 1);
                            channelPowerWrEn <= '1';
                        end if;
                        channelPowerWrDat <= (others => '0');
                        
                    when rd_Vpol =>
                        channelPowerAddr <= virtualChannel & stationSelect & "01"; -- Offset of 1 = address for the current vpol power
                        power_fsm <= rd_Hpol;
                        channelPowerWrEn <= '0';
                    
                    when rd_Hpol =>
                        channelPowerAddr <= virtualChannel & stationSelect & "10"; -- Offset of 2 = address for the current hpol power
                        power_fsm <= get_samples;
                        channelPowerWrEn <= '0';
                    
                    when get_samples =>
                        oldSamples <= channelPowerRdDat;  -- Capture the value from the memory, address was set two cycle earlier.
                        channelPowerWrEn <= '0';
                        power_fsm <= get_Vpol;
                        
                    when get_Vpol =>
                        oldVpol <= channelPowerRdDat;
                        channelPowerWrEn <= '0';
                        power_fsm <= get_Hpol;
                
                    when get_Hpol =>
                        oldHpol <= channelPowerRdDat;
                        channelPowerWrEn <= '0';
                        power_fsm <= check_ok;
                        
                    when check_ok =>
                        if oldVpol(31) = '1' or oldHpol(31) = '1' or oldSamples(31) = '1' then
                            power_fsm <= idle; -- don't accumulate any more to avoid overflow.
                        else
                            power_fsm <= wr_samples;
                        end if;
                        channelPowerWrEn <= '0';
                    
                    when wr_samples =>
                        channelPowerAddr <= virtualChannel & stationSelect & "00";
                        channelPowerWrEn <= '1';
                        channelPowerWrDat <= std_logic_vector(unsigned(oldSamples) + 1);
                        power_fsm <= wr_Vpol;
                    
                    when wr_Vpol =>
                        channelPowerAddr <= virtualChannel & stationSelect & "01";
                        channelPowerWrEn <= '1';
                        channelPowerWrDat <= std_logic_vector(signed(oldVpol) + signed(newVpol));
                        power_fsm <= wr_Hpol;
                        
                    when wr_Hpol =>
                        channelPowerAddr <= virtualChannel & stationSelect & "10";
                        channelPowerWrEn <= '1';
                        channelPowerWrDat <= std_logic_vector(signed(oldHpol) + signed(newHpol));
                        power_fsm <= idle;
                        
                    when others =>
                        power_fsm <= idle;
                
                end case;
            end if;
            
            channelPowerRdDat <= VSTATS_CHANNELPOWER_OUT.rd_dat; -- Extra register stage here, assumes 1 cycle latency on the memory itself. 
            
            
            -----------------------------------------------------------------------------
            -----------------------------------------------------------------------------
            -- Voltage Histogram Capture
            --
            -- The packet goes into a FIFO, and is read out with 16 clocks per word, so 
            -- we have one clock cycle per byte.
            -- In the 32 clock cycles, we go through the following cycle 4 times : 
            --  Read Sample 1 Vpol Real 
            --  Read Sample 1 Vpol Imaginary
            --  Read Sample 1 Hpol Real
            --  Read Sample 1 Hpol Imaginary
            --  Write Sample 1 Vpol Real
            --  Write Sample 1 Vpol Imaginary
            --  Write Sample 1 Hpol Real
            --  Write Sample 1 Hpol Real
            -- 
            --    

            control_VHRun <= VSTATS_FIELDS_RW.control_VHrun;
            control_VHRun_del <= control_VHRun;
            clear_VH <= control_VHRun and (not control_VHRun_del); -- rising edge of run signal
            
            -- Manage Data input to the FIFO
            -- FIFO_wr
            -- FIFO_din
            --data_in
            --valid_in
            
            if valid_in = '0' then
                VHPacketMatch <= '0';
            elsif ((control_VHRun_del = '1') and 
                   (valid_in = '1' and valid_in_del = '0') and   -- first word in the frame, so we are looking at the header.
                   (data_in(59) = VSTATS_FIELDS_RW.VHStation and data_in(8 downto 0) = VSTATS_FIELDS_RW.VHChannel(8 downto 0))) then
                VHPacketMatch <= '1';
            end if;
            
            
            if clear_VH = '0' and (vh_fsm /= clear_memory) and (valid_in = '1' and VHPacketMatch = '1') then
                if FIFO_prog_full = '0' then
                    FIFO_wr <= '1';
                    VHDroppedWord <= '0';
                else
                    FIFO_wr <= '0';
                    VHDroppedWord <= '1';
                end if;
            else
                FIFO_wr <= '0';
                VHDroppedWord <= '0';
            end if; 
            FIFO_din <= data_in;
            
            -- Manage processing of data at the output of the FIFO
            
            if control_VHrun = '0' then
                vh_fsm <= idle;
            else
                case vh_fsm is
                    when idle =>
                        if clear_VH = '1' then
                            vh_fsm <= clear_memory;
                            FIFO_rst <= '1';
                            FIFO_rd <= '0';
                            VHAddr <= (others => '0');
                            VHWrEn <= '1';
                            VHWrDat <= (others => '0');
                        elsif VHDone = '0' and control_VHrun_del = '1' and FIFO_empty = '0' then
                            vh_fsm <= rd_fifo;
                            FIFO_rd <= '1';
                            FIFO_rst <= '0';
                        end if;
                        
                    when clear_memory =>
                        FIFO_rst <= '0';
                        VHSamplesDone <= (others => '0');
                        VHAddr <= std_logic_vector(unsigned(VHAddr) + 1);
                        VHWrDat <= (others => '0');
                        if VHAddr = "1111111111" then
                            vh_fsm <= idle;
                            VHWrEn <= '0';
                        else
                            VHWrEn <= '1';
                        end if;
                        VHCount <= (others => '0'); -- counts to 16, for the number of bytes in a word read from the FIFO.
 
                    when rd_fifo =>
                        vh_fsm <= get_fifo_data;
                        FIFO_rd <= '0';
                        VHWrEn <= '0';
                        FIFO_rst <= '0';
                        
                    when get_fifo_data =>
                        vh_fsm <= rd_shift;
                        VHCount <= "00"; -- counts through the 4 samples in the word read from the FIFO.
                        rdShiftCount <= "00"; -- counts through the four sample types (Vpol Real, Vpol Imaginary, Hpol Real, Hpol Imaginary).
                        wrShiftCount <= "00";
                        FIFO_rd <= '0';
                        FIFO_rst <= '0';
                        VHWrEn <= '0';
                        
                    when rd_shift => -- Do four memory reads (Vpol Real, Vpol Imaginary, Hpol Real, Hpol Imaginary).
                        rdShiftCount <= std_logic_vector(unsigned(rdShiftCount) + 1);
                        wrShiftCount <= "00";
                        VHWrEn <= '0';
                        VHAddr <= rdShiftCount & vhdata(7 downto 0);
                        if rdShiftCount(1 downto 0) = "11" then
                            vh_fsm <= wr_back;
                        end if;
                    
                    when wr_back =>  -- Do four memory writes (Vpol Real, Vpol Imaginary, Hpol Real, Hpol Imaginary).
                        wrShiftCount <= std_logic_vector(unsigned(wrShiftCount) + 1);
                        VHwrDat <= vh_dat_plus1;
                        VHAddr <= wrShiftCount & vhdata_del4;
                        VHWrEn <= '1';
                        if (wrShiftCount = "11") then
                            VHSamplesDone <= std_logic_vector(unsigned(VHSamplesDone) + 1);
                            VHCount <= std_logic_vector(unsigned(VHCount) + 1);
                            if (VHCount = "11") then
                                if VHDone = '1' then
                                    vh_fsm <= idle;
                                    FIFO_rd <= '0';
                                elsif FIFO_empty = '0' then
                                    vh_fsm <= rd_fifo;
                                    FIFO_rd <= '1';
                                else
                                    vh_fsm <= idle;
                                    FIFO_rd <= '0';
                                end if;
                            else
                                vh_fsm <= rd_shift;
                            end if;
                        end if;
                    
                    when others =>
                        vh_fsm <= idle;
                    
                end case;
            end if;
            
            if vh_fsm = get_fifo_data then
                vhdata <= FIFO_dout;
            elsif vh_fsm = rd_shift then
                vhdata(119 downto 0) <= vhdata(127 downto 8);
            end if;
            
            vhdata_del1 <= vhdata(7 downto 0);
            vhdata_del2 <= vhdata_del1;
            vhdata_del3 <= vhdata_del2;
            vhdata_del4 <= vhdata_del3;
            
            if (unsigned(VHSamplesDone) > unsigned(VSTATS_FIELDS_RW.vhMaxSamples)) then
                VHDone <= '1';
            else
                VHDone <= '0';
            end if;
            
            -- Pipeline stages to align the modified histogram value with the write cycle in the state machine 4 clocks later.
            vh_dat_del1 <= VSTATS_VHISTOGRAM_OUT.rd_dat;
            vh_dat_plus1 <= std_logic_vector(unsigned(vh_dat_del1) + 1);
            
            vstats_fields_ro.control_VHRunning <= (not VHDone) and control_VHRun;
            vstats_fields_ro.control_powerRunning <= control_powerrun;
            
            if clear_VH = '1' then
                vstats_fields_ro.control_VHDrops <= '0'; 
            elsif VHDroppedWord = '1' then
                vstats_fields_ro.control_VHDrops <= '1';   --
            end if; 
            
        end if;
    end process;

    vstats_channelpower_in.clk <= data_clk;
    vstats_channelpower_in.rst <= '0';
    vstats_channelpower_in.rd_en <= '1';
    vstats_channelpower_in.adr <= channelPowerAddr;
    vstats_channelpower_in.wr_en <= channelPowerWrEn;
    vstats_channelpower_in.wr_dat <= channelPowerWrDat;
    
    vstats_vhistogram_in.clk <= data_clk;
    vstats_vhistogram_in.wr_en <= VHWrEn;
    vstats_vhistogram_in.wr_dat <= VHwrDat;  -- 32 bit data.
    vstats_vhistogram_in.adr <= VHAddr;      -- 10 bit address
    vstats_vhistogram_in.rst <= '0';
    vstats_vhistogram_in.rd_en <= '1';

    vstats_fields_ro.VHSamplesDone <= VHSamplesDone; 


    -- xpm_fifo_sync: Synchronous FIFO
    -- Xilinx Parameterized Macro, Version 2017.4
    xpm_fifo_sync_inst : xpm_fifo_sync
    generic map (
        FIFO_MEMORY_TYPE         => "auto",           --string; "auto", "block", "distributed", or "ultra" ;
        ECC_MODE                 => "no_ecc",         --string; "no_ecc" or "en_ecc";
        FIFO_WRITE_DEPTH         => 512,              --positive integer
        WRITE_DATA_WIDTH         => 128,              --positive integer
        WR_DATA_COUNT_WIDTH      => 10,               --positive integer
        PROG_FULL_THRESH         => 500,              --positive integer
        FULL_RESET_VALUE         => 0,                --positive integer; 0 or 1;
        -- |    Setting USE_ADV_FEATURES[0]  to 1 enables overflow flag;     Default value of this bit is 1                      |
        -- |    Setting USE_ADV_FEATURES[1]  to 1 enables prog_full flag;    Default value of this bit is 1                      |
        -- |    Setting USE_ADV_FEATURES[2]  to 1 enables wr_data_count;     Default value of this bit is 1                      |
        -- |    Setting USE_ADV_FEATURES[3]  to 1 enables almost_full flag;  Default value of this bit is 0                      |
        -- |    Setting USE_ADV_FEATURES[4]  to 1 enables wr_ack flag;       Default value of this bit is 0                      |
        -- |    Setting USE_ADV_FEATURES[8]  to 1 enables underflow flag;    Default value of this bit is 1                      |
        -- |    Setting USE_ADV_FEATURES[9]  to 1 enables prog_empty flag;   Default value of this bit is 1                      |
        -- |    Setting USE_ADV_FEATURES[10] to 1 enables rd_data_count;     Default value of this bit is 1                      |
        -- |    Setting USE_ADV_FEATURES[11] to 1 enables almost_empty flag; Default value of this bit is 0                      |
        -- |    Setting USE_ADV_FEATURES[12] to 1 enables data_valid flag;   Default value of this bit is 0                      |
        USE_ADV_FEATURES         => "0002",           --string; "0000" to "1F1F";
        READ_MODE                => "std",            --string; "std" or "fwft";
        FIFO_READ_LATENCY        => 1,                --positive integer;
        READ_DATA_WIDTH          => 128,              --positive integer
        RD_DATA_COUNT_WIDTH      => 10,               --positive integer
        PROG_EMPTY_THRESH        => 10,               --positive integer
        DOUT_RESET_VALUE         => "0",              --string
        WAKEUP_TIME              => 0                 --positive integer; 0 or 2;
    )
    port map (
        rst              => FIFO_rst,
        wr_clk           => data_clk,
        wr_en            => FIFO_wr,
        din              => FIFO_din,
        full             => open,
        overflow         => open,
        wr_rst_busy      => open,
        prog_full        => FIFO_prog_full,
        wr_data_count    => open,
        almost_full      => open,
        wr_ack           => open,
        rd_en            => FIFO_rd,
        dout             => FIFO_dout,
        empty            => FIFO_empty,
        underflow        => open,
        rd_rst_busy      => open,
        prog_empty       => open,
        rd_data_count    => open,
        almost_empty     => open,
        data_valid       => open,
        sleep            => '0',
        injectsbiterr    => '0',
        injectdbiterr    => '0',
        sbiterr          => open,
        dbiterr          => open
    );



-- XPM_FIFO instantiation template for Synchronous FIFO configurations
-- Refer to the targeted device family architecture libraries guide for XPM_FIFO documentation
-- =======================================================================================================================
--
-- Parameter usage table, organized as follows:
-- +---------------------------------------------------------------------------------------------------------------------+
-- | Parameter name          | Data type          | Restrictions, if applicable                                          |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Description                                                                                                         |
-- +---------------------------------------------------------------------------------------------------------------------+
-- +---------------------------------------------------------------------------------------------------------------------+
-- | FIFO_MEMORY_TYPE        | String             | Must be "auto", "block", "distributed" or "ultra"                    |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Designate the fifo memory primitive (resource type) to use:                                                         |
-- |   "auto": Allow Vivado Synthesis to choose                                                                          |
-- |   "block": Block RAM FIFO                                                                                           |
-- |   "distributed": Distributed RAM FIFO                                                                               |
-- |   "ultra": URAM FIFO                                                                                                |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | FIFO_WRITE_DEPTH        | Integer            | Must be between 16 and 4194304                                       |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Defines the FIFO Write Depth, must be power of two                                                                  |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | WRITE_DATA_WIDTH        | Integer            | Must be between 1 and 4096                                           |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Defines the width of the write data port, din                                                                       |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | WR_DATA_COUNT_WIDTH     | Integer            | Must be between 1 and log2(FIFO_WRITE_DEPTH)+1                       |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Specifies the width of wr_data_count                                                                                |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | READ_MODE               | String             | Must be "std" or "fwft"                                              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- |  "std": standard read mode                                                                                          |
-- |  "fwft": First-Word-Fall-Through read mode                                                                          |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | FIFO_READ_LATENCY       | Integer            | Must be >= 0                                                         |
-- |---------------------------------------------------------------------------------------------------------------------|
-- |  Number of output register stages in the read data path                                                             |
-- |  If READ_MODE = "fwft", then the only applicable value is 0.                                                        |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | FULL_RESET_VALUE        | Integer            | Must be 0 or 1                                                       |
-- |---------------------------------------------------------------------------------------------------------------------|
-- |  Sets FULL, PROG_FULL and ALMOST_FULL to FULL_RESET_VALUE during reset                                              |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | USE_ADV_FEATURES        | String             | Must be between "0000" and "1F1F"                                    |
-- |---------------------------------------------------------------------------------------------------------------------|
-- |  Enables data_valid, almost_empty, rd_data_count, prog_empty, underflow, wr_ack, almost_full, wr_data_count,        |
-- |  prog_full, overflow features                                                                                       |
-- |    Setting USE_ADV_FEATURES[0]  to 1 enables overflow flag;     Default value of this bit is 1                      |
-- |    Setting USE_ADV_FEATURES[1]  to 1 enables prog_full flag;    Default value of this bit is 1                      |
-- |    Setting USE_ADV_FEATURES[2]  to 1 enables wr_data_count;     Default value of this bit is 1                      |
-- |    Setting USE_ADV_FEATURES[3]  to 1 enables almost_full flag;  Default value of this bit is 0                      |
-- |    Setting USE_ADV_FEATURES[4]  to 1 enables wr_ack flag;       Default value of this bit is 0                      |
-- |    Setting USE_ADV_FEATURES[8]  to 1 enables underflow flag;    Default value of this bit is 1                      |
-- |    Setting USE_ADV_FEATURES[9]  to 1 enables prog_empty flag;   Default value of this bit is 1                      |
-- |    Setting USE_ADV_FEATURES[10] to 1 enables rd_data_count;     Default value of this bit is 1                      |
-- |    Setting USE_ADV_FEATURES[11] to 1 enables almost_empty flag; Default value of this bit is 0                      |
-- |    Setting USE_ADV_FEATURES[12] to 1 enables data_valid flag;   Default value of this bit is 0                      |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | READ_DATA_WIDTH         | Integer            | Must be between >= 1                                                 |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Defines the width of the read data port, dout                                                                       |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | RD_DATA_COUNT_WIDTH     | Integer            | Must be between 1 and log2(FIFO_READ_DEPTH)+1                        |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Specifies the width of rd_data_count                                                                                |
-- | FIFO_READ_DEPTH = FIFO_WRITE_DEPTH*WRITE_DATA_WIDTH/READ_DATA_WIDTH                                                 |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | ECC_MODE                | String             | Must be "no_ecc" or "en_ecc"                                         |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | "no_ecc" : Disables ECC                                                                                             |
-- | "en_ecc" : Enables both ECC Encoder and Decoder                                                                     |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | PROG_FULL_THRESH        | Integer            | Must be between "Min_Value" and "Max_Value"                          |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted.                    |
-- | Min_Value = 3 + (READ_MODE_VAL*2*(FIFO_WRITE_DEPTH/FIFO_READ_DEPTH))+CDC_SYNC_STAGES                                |
-- | Max_Value = (FIFO_WRITE_DEPTH-3) - (READ_MODE_VAL*2*(FIFO_WRITE_DEPTH/FIFO_READ_DEPTH))                             |
-- | If READ_MODE = "std", then READ_MODE_VAL = 0; Otherwise READ_MODE_VAL = 1                                           |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | PROG_EMPTY_THRESH       | Integer            | Must be between "Min_Value" and "Max_Value"                          |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Specifies the minimum number of read words in the FIFO at or below which prog_empty is asserted                     |
-- | Min_Value = 3 + (READ_MODE_VAL*2)                                                                                   |
-- | Max_Value = (FIFO_WRITE_DEPTH-3) - (READ_MODE_VAL*2)                                                                |
-- | If READ_MODE = "std", then READ_MODE_VAL = 0; Otherwise READ_MODE_VAL = 1                                           |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | DOUT_RESET_VALUE        | String             | Must be >="0". Valid hexa decimal value                              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Reset value of read data path.                                                                                      |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | WAKEUP_TIME             | Integer            | Must be 0 or 2                                                       |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | 0 : Disable sleep.                                                                                                  |
-- | 2 : Use Sleep Pin.                                                                                                  |
-- +---------------------------------------------------------------------------------------------------------------------+
--
-- Port usage table, organized as follows:
-- +---------------------------------------------------------------------------------------------------------------------+
-- | Port name      | Direction | Size, in bits                         | Domain | Sense       | Handling if unused      |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Description                                                                                                         |
-- +---------------------------------------------------------------------------------------------------------------------+
-- +---------------------------------------------------------------------------------------------------------------------+
-- | sleep          | Input     | 1                                     |        | Active-high | Tie to 1'b0             |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Dynamic power saving: If sleep is High, the memory/fifo block is in power saving mode.                              |
-- | Synchronous to the slower of wr_clk and rd_clk when COMMON_CLOCK = 0, otherwise synchronous to rd_clk.              |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | rst            | Input     | 1                                     | wr_clk | Active-high | Required                |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | Reset: Must be synchronous to wr_clk. Must be applied only when wr_clk is stable and free-running.                  |
-- | Once reset is applied to FIFO, the subsequent reset must be applied only when wr_rst_busy becomes zero from one.    |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | wr_clk         | Input     | 1                                     |        | Rising edge | Required                |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Write clock: Used for write operation.                                                                              |
-- | When parameter COMMON_CLOCK = 1, wr_clk is used for both write and read operation.                                  |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | wr_en          | Input     | 1                                     | wr_clk | Active-high | Required                |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Write Enable: If the FIFO is not full, asserting this signal causes data (on din) to be written to the FIFO         |
-- | Must be held active-low when rst or wr_rst_busy or rd_rst_busy is active high.                                      |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | din            | Input     | WRITE_DATA_WIDTH                      | wr_clk |             | Required                |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Write Data: The input data bus used when writing the FIFO.                                                          |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | full           | Output    | 1                                     | wr_clk | Active-high | Leave open              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Full Flag: When asserted, this signal indicates that the FIFO is full.                                              |
-- | Write requests are ignored when the FIFO is full, initiating a write when the FIFO is full is not destructive       |
-- | to the contents of the FIFO.                                                                                        |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | overflow       | Output    | 1                                     | wr_clk | Active-high | Leave open              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Overflow: This signal indicates that a write request (wren) during the prior clock cycle was rejected,              |
-- | because the FIFO is full. Overflowing the FIFO is not destructive to the contents of the FIFO.                      |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | wr_rst_busy    | Output    | 1                                     | wr_clk | Active-high | Leave open              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Write Reset Busy: Active-High indicator that the FIFO write domain is currently in a reset state.                   |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | almost_full    | Output    | 1                                     | wr_clk | Active-high | Leave open              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Almost Full: When asserted, this signal indicates that only one more write can be performed before the FIFO is full.|
-- +---------------------------------------------------------------------------------------------------------------------+
-- | wr_ack         | Output    | 1                                     | wr_clk | Active-high | Leave open              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Write Acknowledge: This signal indicates that a write request (wr_en) during the prior clock cycle succeeded.       |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | rd_en          | Input     | 1                                     | wr_clk | Active-high | Required                |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Read Enable: If the FIFO is not empty, asserting this signal causes data (on dout) to be read from the FIFO         |
-- | Must be held active-low when rst or wr_rst_busy or rd_rst_busy is active high.                                      |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | dout           | Output    | READ_DATA_WIDTH                       | wr_clk |             | Required                |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Read Data: The output data bus is driven when reading the FIFO.                                                     |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | empty          | Output    | 1                                     | wr_clk | Active-high | Leave open              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Empty Flag: When asserted, this signal indicates that the FIFO is empty.                                            |
-- | Read requests are ignored when the FIFO is empty, initiating a read while empty is not destructive to the FIFO.     |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | underflow      | Output    | 1                                     | wr_clk | Active-high | Leave open              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Underflow: Indicates that the read request (rd_en) during the previous clock cycle was rejected                     |
-- | because the FIFO is empty. Under flowing the FIFO is not destructive to the FIFO.                                   |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | rd_rst_busy    | Output    | 1                                     | wr_clk | Active-high | Leave open              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Read Reset Busy: Active-High indicator that the FIFO read domain is currently in a reset state.                     |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | prog_full      | Output    | 1                                     | wr_clk | Active-high | Leave open              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Programmable Full: This signal is asserted when the number of words in the FIFO is greater than or equal            |
-- | to the programmable full threshold value.                                                                           |
-- | It is de-asserted when the number of words in the FIFO is less than the programmable full threshold value.          |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | wr_data_count  | Output    | WR_DATA_COUNT_WIDTH                   | wr_clk |             | Leave open              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Write Data Count: This bus indicates the number of words written into the FIFO.                                     |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | prog_empty     | Output    | 1                                     | wr_clk | Active-high | Leave open              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Programmable Empty: This signal is asserted when the number of words in the FIFO is less than or equal              |
-- | to the programmable empty threshold value.                                                                          |
-- | It is de-asserted when the number of words in the FIFO exceeds the programmable empty threshold value.              |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | rd_data_count  | Output    | RD_DATA_COUNT_WIDTH                   | wr_clk |             | Leave open              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Read Data Count: This bus indicates the number of words read from the FIFO.                                         |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | almost_empty   | Output    | 1                                     | wr_clk | Active-high | Leave open              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Almost Empty : When asserted, this signal indicates that only one more read can be performed before the FIFO is     |
-- | empty.                                                                                                              |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | data_valid     | Output    | 1                                     | wr_clk | Active-high | Leave open              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Read Data Valid: When asserted, this signal indicates that valid data is available on the output bus (dout).        |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | injectsbiterr  | Intput    | 1                                     |        | Active-high | Tie to 1'b0             |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Single Bit Error Injection: Injects a single bit error if the ECC feature is used on block RAMs or                  |
-- | built-in FIFO macros.                                                                                               |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | injectdbiterr  | Intput    | 1                                     |        | Active-high | Tie to 1'b0             |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Double Bit Error Injection: Injects a double bit error if the ECC feature is used on block RAMs or                  |
-- | built-in FIFO macros.                                                                                               |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | sbiterr        | Output    | 1                                     |        | Active-high | Leave open              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Single Bit Error: Indicates that the ECC decoder detected and fixed a single-bit error.                             |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | dbiterr        | Output    | 1                                     |        | Active-high | Leave open              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Double Bit Error: Indicates that the ECC decoder detected a double-bit error and data in the FIFO core is corrupted.|
-- +---------------------------------------------------------------------------------------------------------------------+

end Behavioral;
