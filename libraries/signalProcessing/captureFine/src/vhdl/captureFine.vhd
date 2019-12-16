----------------------------------------------------------------------------------
-- Company: CSIRO 
-- Engineer: David Humphrey (dave.humphrey@csiro.au)
-- 
-- Create Date: 02.04.2019 13:40:03
-- Module Name: CaptureFine - Behavioral
-- Description: 
--  Capture packets at the output of the coarse corner turn and at the output of the filterbanks.
-- 
----------------------------------------------------------------------------------

library IEEE, axi4_lib, captureFine_lib, ctc_lib, common_lib;
use ctc_lib.ctc_pkg.all;
use common_lib.common_pkg.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
Library xpm;
use xpm.vcomponents.all;
use axi4_lib.axi4_lite_pkg.ALL;
use axi4_lib.axi4_full_pkg.ALL;
use xpm.vcomponents.all;
USE captureFine_lib.captureFine_capturefine_reg_pkg.ALL;

entity captureFine is
    port(
        -- Packet Data to capture
        -- ctc correlator data
        i_CTC_data   : in t_ctc_output_data_a(1 downto 0);   -- Each of the 2 inputs is 32 bits, 8 bits each for VpolRe, VpolIm, HpolRe, HpolIm 
        i_CTC_hdr    : in t_ctc_output_header_a(1 downto 0); -- 
        i_CTC_valid  : in std_logic;
        i_data_clk  : in std_logic;
        -- Correlator Filterbank output data
        i_CFB_data   : in t_ctc_output_data_a(1 downto 0);   -- 2 streams, each 32 bits, as per CTC correlator data.
        i_CFB_hdr    : in t_ctc_output_header_a(1 downto 0); -- 
        i_CFB_valid  : in std_logic;
        -- CTC PSS/PST data (comes out on the same bus)
        i_CTC_PSSPST_data  : in t_ctc_output_data_a(2 downto 0);  -- 3 different streams, each 32 bits (8 bits each for VpolRe, VpolIm, HpolRe, HpolIm)
        i_CTC_PSSPST_hdr   : in t_ctc_output_header_a(2 downto 0); -- one header per stream
        i_CTC_PSSPST_valid : in std_logic;
        -- PSS Filterbank output data
        i_PSSFB_data  : in t_ctc_output_data_a(2 downto 0);  -- 3 different streams, each 32 bits (8 bits each for VpolRe, VpolIm, HpolRe, HpolIm)
        i_PSSFB_hdr   : in t_ctc_output_header_a(2 downto 0); -- one header per stream
        i_PSSFB_valid : in std_logic;
        -- PST Filterbank output data
        i_PSTFB_data  : in t_ctc_output_data_a(2 downto 0);  -- 3 different streams, each 32 bits (8 bits each for VpolRe, VpolIm, HpolRe, HpolIm)
        i_PSTFB_hdr   : in t_ctc_output_header_a(2 downto 0); -- one header per stream
        i_PSTFB_valid : in std_logic;
        -- control registers AXI Lite Interface
        i_s_axi_mosi     : in t_axi4_lite_mosi;
        o_s_axi_miso     : out t_axi4_lite_miso;
        i_s_axi_clk      : in std_logic;
        i_s_axi_rst      : in std_logic;
        -- AXI Full interface for the capture buffer
        i_capmem_MM_IN  : in  t_axi4_full_mosi;
        o_capmem_MM_OUT : out t_axi4_full_miso        
    );
end captureFine;

architecture Behavioral of captureFine is

    type cap_fsm_type is (reset, idle, clearCap, capturePacket, waitReset);
    signal cap_fsm : cap_fsm_type := idle;
     
   -- signal dontCareMask : std_logic_vector(127 downto 0);
  --  signal triggerMask : std_logic_vector(127 downto 0);
  --  signal trigger : std_logic_vector(127 downto 0);
    signal triggerAnd : std_logic_vector(3 downto 0);
    signal valid_del1 : std_logic;
    signal valid_del2 : std_logic;
    signal valid_del3 : std_logic;
    signal triggerFinal : std_logic;
    signal reg_rw : t_capfinectrl_rw;
    signal reg_ro : t_capfinectrl_ro;
    
    signal capBufWE : std_logic;
    signal capBufWrAddr : std_logic_vector(13 downto 0);
    signal capBufWrData : std_logic_vector(31 downto 0);

    signal packetAddrWE : std_logic;
    signal packetAddrWrData : std_logic_vector(31 downto 0);
    signal packetAddrWrAddr : std_logic_vector(4 downto 0);  -- Capture up to 32 packets.
    
    signal ploc_in : t_capfinectrl_packetlocations_ram_in;
    signal ploc_out : t_capfinectrl_packetlocations_ram_out;
    signal capEnable, capEnableDel1 : std_logic;
    signal packetsCaptured : std_logic_vector(4 downto 0);
    signal capWrAddr, capWrAddrOld : std_logic_vector(13 downto 0);
    signal capWrAddrStart : std_logic_vector(13 downto 0);
    
    signal i_data_clk_vec : std_logic_vector(0 downto 0);
    signal rst_vec : std_logic_vector(0 downto 0);
  --  signal data_del1, data_del2, data_del3 : std_logic_vector(127 downto 0);
    
    signal validDel2 : std_logic := '0';
    signal capture0, capture1, capture2 : std_logic := '0';
    signal hdrTimestamp : t_slv_32_arr(2 downto 0);
    signal timestampDel2 : std_logic_vector(31 downto 0);
    signal validSel, validDel1 : std_logic_vector(2 downto 0);
    signal hdrSel : t_ctc_output_header_a(2 downto 0);
    signal dataSel, dataDel1 : t_ctc_output_data_a(2 downto 0);
    signal dataDel2 : t_ctc_output_data;
    signal hdrStationOk : std_logic_vector(2 downto 0);
    signal hdrChannelOk : std_logic_vector(2 downto 0);
    signal hdrTimestampOk  : std_logic_vector(2 downto 0);
    signal validOk : std_logic_vector(2 downto 0);
    signal packetCountsWrData : std_logic_vector(31 downto 0);
    
    signal pcounts_in : t_capFinectrl_packetCounts_ram_in;
    signal pcounts_out : t_capFinectrl_packetCounts_ram_out;
    
begin
    
    process(i_data_clk)
        variable triggerAnd_v : std_logic_vector(3 downto 0);
    begin
        if rising_edge(i_data_clk) then
            -- Select the bus that we are capturing
            case reg_rw.BusSel(3 downto 0) is
                when "0000" => -- CTC correlator output
                    dataSel(1 downto 0) <= i_CTC_data;
                    hdrSel(1 downto 0) <= i_CTC_hdr;
                    validSel(2 downto 0) <= '0' & i_CTC_valid & i_CTC_valid;
                when "0001" => -- CTC PSS/PST output
                    -- CTC PSS/PST data (comes out on the same bus)
                    dataSel <= i_CTC_PSSPST_data;   -- in t_ctc_output_data_a(2 downto 0);  -- 3 different streams, each 32 bits (8 bits each for VpolRe, VpolIm, HpolRe, HpolIm)
                    hdrSel <= i_CTC_PSSPST_hdr;     -- in t_ctc_output_header_a(2 downto 0); -- one header per stream
                    validSel(2 downto 0) <= i_CTC_PSSPST_valid & i_CTC_PSSPST_valid & i_CTC_PSSPST_valid; -- in std_logic;
                when "0010" => -- Correlator Filterbank output
                    dataSel(1 downto 0) <= i_CFB_data;   -- in t_ctc_output_data_a(1 downto 0);   -- 2 streams, each 32 bits, as per CTC correlator data.
                    hdrSel(1 downto 0) <= i_CFB_hdr;     -- in t_ctc_output_header_a(1 downto 0); -- 
                    validSel(2 downto 0) <= '0' & i_CFB_valid & i_CFB_valid; -- in std_logic;
                when "0011" => -- PSS Filterbank output
                    dataSel <= i_PSSFB_data;   --  in t_ctc_output_data_a(2 downto 0);  -- 3 different streams, each 32 bits (8 bits each for VpolRe, VpolIm, HpolRe, HpolIm)
                    hdrSel <= i_PSSFB_hdr;     -- in t_ctc_output_header_a(2 downto 0); -- one header per stream
                    validSel(2 downto 0) <= i_PSSFB_valid & i_PSSFB_valid & i_PSSFB_valid; -- in std_logic;
                when others => -- PST Filterbank output
                     dataSel <= i_PSTFB_data;   -- in t_ctc_output_data_a(2 downto 0);  -- 3 different streams, each 32 bits (8 bits each for VpolRe, VpolIm, HpolRe, HpolIm)
                     hdrSel <= i_PSTFB_hdr;     -- in t_ctc_output_header_a(2 downto 0); -- one header per stream
                     validSel(2 downto 0) <= i_PSTFB_valid & i_PSTFB_valid & i_PSTFB_valid; -- in std_logic;
            end case;
            
            -- Pipeline stage for determining the trigger condition
            -- On the first cycle of valid, compare the header with the trigger condition.
            for i in 0 to 2 loop
                if (hdrSel(i).station_id = reg_rw.CaptureStation) then
                    hdrStationOk(i) <= '1';
                else
                    hdrStationOk(i) <= '0'; 
                end if;
                if (hdrSel(i).virtual_channel = reg_rw.CaptureVirtualChannel) then
                    hdrChannelOk(i) <= '1';
                else
                    hdrChannelOk(i) <= '0';
                end if;
                if (unsigned(hdrSel(i).timestamp(42 downto 11)) >= unsigned(reg_rw.CapturePacketCount)) then
                    hdrTimestampOk(i) <= '1';
                else
                    hdrTimestampOk(i) <= '0';
                end if;
                if validSel(i) = '1' and validDel1(i) = '0' then
                    validOk(i) <= '1'; -- rising edge of valid; only capture at the start of the packet.
                else
                    validOk(i) <= '0';
                end if;
                hdrTimestamp(i) <= hdrSel(i).timestamp(42 downto 11);
            end loop;
            dataDel1 <= dataSel;
            validDel1 <= validSel;
             
            
            -- Choose the data to capture.
            if capture0 = '1' and validDel1(0) = '1' then
                dataDel2 <= dataDel1(0);
                validDel2 <= '1';
            elsif capture1 = '1' and validDel1(1) = '1' then
                dataDel2 <= dataDel1(1);
                validDel2 <= '1';
            elsif capture2 = '1' and validDel1(2) = '1' then
                dataDel2 <= dataDel1(2);
                validDel2 <= '1';
            else
                if (hdrStationOk(0) = '1' and hdrChannelOk(0) = '1' and validOk(0) = '1') then
                    dataDel2 <= dataDel1(0);
                    timestampDel2 <= hdrTimestamp(0);
                    validDel2 <= '1';
                    capture0 <= '1';
                    capture1 <= '0';
                    capture2 <= '0';
                elsif (hdrStationOk(1) = '1' and hdrChannelOk(1) = '1' and validOk(1) = '1') then
                    dataDel2 <= dataDel1(1);
                    timestampDel2 <= hdrTimestamp(1);
                    validDel2 <= '1';
                    capture0 <= '0';
                    capture1 <= '1';
                    capture2 <= '0';
                elsif (hdrStationOk(2) = '1' and hdrChannelOk(2) = '1' and validOk(2) = '1') then
                    dataDel2 <= dataDel1(2);
                    timestampDel2 <= hdrTimestamp(2);
                    validDel2 <= '1';
                    capture0 <= '0';
                    capture1 <= '0';
                    capture2 <= '1';
                else
                    validDel2 <= '0';
                    capture0 <= '0';
                    capture1 <= '0';
                    capture2 <= '0';
                end if;
            end if;
            
            -- Capture state machine
            capEnable <= reg_rw.enable;
            capEnableDel1 <= capEnable;
            if capEnable = '1' and capEnableDel1 = '0' then -- On the rising edge of enable, reset the capture buffer.
                cap_fsm <= reset;
            else
                case cap_fsm is
                    when reset =>
                        packetsCaptured <= (others => '0');
                        capBufWrAddr <= (others => '0');
                        cap_fsm <= clearCap;
                        packetAddrWrData <= (others => '0');
                        packetAddrWe <= '1';
                        capWrAddr <= (others => '0');
                        capWrAddrOld <= (others => '0');
                        
                    when clearCap =>
                        packetsCaptured <= std_logic_vector(unsigned(packetsCaptured) + 1);
                        packetAddrWrData <= (others => '0');
                        packetAddrWe <= '1';
                        capWrAddr <= (others => '0');
                        capWrAddrOld <= capWrAddr;
                        if packetsCaptured = "11111" then
                            cap_fsm <= idle;
                        end if;
                        
                    when idle =>
                        packetAddrWe <= '0';
                        if reg_rw.enable = '1' and validDel2 = '1' then
                            cap_fsm <= capturePacket;
                            capWrAddrStart <= capWrAddr;
                            packetCountsWrData <= timestampDel2;
                            if capWrAddr = "11111111111111" then
                                cap_fsm <= waitReset;
                            else
                                capWrAddr <= std_logic_vector(unsigned(capWrAddr) + 1);
                                capWrAddrOld <= capWrAddr;
                            end if;
                        end if;
                    
                    when capturePacket =>
                        -- wait until valid goes low, then go back to idle.
                        if validDel2 = '0' then
                            packetAddrWrAddr <= packetsCaptured;
                            packetsCaptured <= std_logic_vector(unsigned(packetsCaptured) + 1);
                            -- start address and finish address
                            -- addresses are for 128 bit words, so multiply by 4 to get the 32bit word address that MACE uses.
                            -- Also pad with 2 bits, so that the addresses are 16 bit aligned.
                            packetAddrWrData <= "00" & capWrAddrOld & "00" & capWrAddrStart; 
                            packetAddrWe <= '1';
                            if (capWrAddr = "11111111111111") then
                                cap_fsm <= waitReset;
                            else
                                cap_fsm <= idle;
                            end if;
                        else
                            if capWrAddr = "11111111111111" then
                                cap_fsm <= waitReset;
                            else
                                capWrAddr <= std_logic_vector(unsigned(capWrAddr) + 1);
                                capWrAddrOld <= capWrAddr;
                            end if;
                        end if;
                    
                    when waitReset =>
                        -- The buffer is full, wait until enable is reset.
                        cap_fsm <= waitReset;  -- rising edge of enable takes the state machine to the reset state (see above outside of the case statement).
                        packetAddrWe <= '0';
                        packetAddrWrData <= (others => '0');
                        capWrAddr <= (others => '0');
                        
                    when others =>
                        cap_fsm <= idle;
                        
                end case;
            end if;
            
            -- Write whenever we are in the state capturePacket
            capBufWraddr <= capWrAddr;
            capBufWrData(7 downto 0) <= dataDel2.data.vpol.re;
            capBufWrData(15 downto 8) <= dataDel2.data.vpol.im;
            capBufWrData(23 downto 16) <= dataDel2.data.hpol.re;
            capBufWrData(31 downto 24) <= dataDel2.data.hpol.im;
            
        end if;
    end process;
    
    capBufWE <= '1' when cap_fsm = capturePacket else '0';
    
    -- Current write address into the capture buffer.
    reg_ro.capwraddr <= x"0000" & "00" & capWrAddr; --	(31:0);
    reg_ro.packetscaptured <= x"00" & "000" & packetsCaptured; -- (15:0), maximum number of packets captured is 31.
    
    ploc_in.rst <= '0';
    ploc_in.rd_en <= '0';
    ploc_in.adr <= packetAddrWrAddr;
    ploc_in.wr_en <= packetAddrWe;
    ploc_in.wr_dat <= packetAddrWrData;
    ploc_in.clk <= i_data_clk;
    
    pcounts_in.rst <= '0';
    pcounts_in.rd_en <= '0';
    pcounts_in.adr <= packetAddrWrAddr;
    pcounts_in.wr_en <= packetAddrWe;
    pcounts_in.wr_dat <= packetCountsWrData;
    pcounts_in.clk <= i_data_clk;
    
    reg:  entity work.captureFine_capturefine_reg
    port map (
        MM_CLK                => i_s_axi_clk,        -- in STD_LOGIC;
        MM_RST                => i_s_axi_rst,        -- in STD_LOGIC;
        st_clk_capFinectrl    => i_data_clk_vec,     -- in STD_LOGIC_VECTOR(0 TO 0);
        st_rst_capFinectrl    => rst_vec,            -- in STD_LOGIC_VECTOR(0 TO 0);
        SLA_IN                => i_s_axi_mosi,       -- in  t_axi4_lite_mosi;
        SLA_OUT               => o_s_axi_miso,       -- out t_axi4_lite_miso;
        CAPFINECTRL_FIELDS_RW => reg_rw,             -- out t_capFinectrl_rw;
        CAPFINECTRL_FIELDS_RO => reg_ro,             -- in  t_capFinectrl_ro
        CAPFINECTRL_PACKETLOCATIONS_IN  => ploc_in,  -- IN  t_capFinectrl_packetlocations_ram_in;
        CAPFINECTRL_PACKETLOCATIONS_OUT => ploc_out, -- OUT t_capFinectrl_packetlocations_ram_out
        CAPFINECTRL_PACKETCOUNTS_IN  => pcounts_in,  -- IN  t_capFinectrl_packetCounts_ram_in;
        CAPFINECTRL_PACKETCOUNTS_OUT => pcounts_out  -- OUT t_capFinectrl_packetCounts_ram_out
    );
    i_data_clk_vec(0) <= i_data_clk;
    rst_vec(0) <= '0';
    
    cmem : entity work.captureFine_capturefine_capbuf_ram
    port map (
        CLK_A     => i_s_axi_clk,     -- in STD_LOGIC;
        RST_A     => i_s_axi_rst,     -- in STD_LOGIC;
        CLK_B     => i_data_clk,      -- in STD_LOGIC;
        RST_B     => '0',             -- in STD_LOGIC;
        MM_IN     => i_capmem_MM_IN,  -- in  t_axi4_full_mosi;
        MM_OUT    => o_capmem_MM_OUT, -- out t_axi4_full_miso;
        user_we   => capBufWE,        -- in  std_logic;
        user_addr => capBufWrAddr,    -- in  std_logic_vector(g_ram_b.adr_w-1 downto 0);
        user_din  => capBufWrData,    -- in  std_logic_vector(g_ram_b.dat_w-1 downto 0);
        user_dout => open             -- out std_logic_vector(g_ram_b.dat_w-1 downto 0)
    );
    
end Behavioral;
