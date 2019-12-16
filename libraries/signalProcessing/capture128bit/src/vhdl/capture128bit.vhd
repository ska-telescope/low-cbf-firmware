----------------------------------------------------------------------------------
-- Company: CSIRO 
-- Engineer: David Humphrey (dave.humphrey@csiro.au)
-- 
-- Create Date: 02.04.2019 13:40:03
-- Module Name: Capture128bit - Behavioral
-- Description: 
--  Capture packets with a 128bit wide interface.
-- 
----------------------------------------------------------------------------------

library IEEE, axi4_lib, capture128bit_lib;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
Library xpm;
use xpm.vcomponents.all;
use axi4_lib.axi4_lite_pkg.ALL;
use axi4_lib.axi4_full_pkg.ALL;
use xpm.vcomponents.all;
-- use LFAADecode_lib.LFAADecode_lfaadecode_reg_pkg.ALL;
USE capture128bit_lib.capture128bit_reg_pkg.ALL;

entity capture128bit is
    port(
        -- Packet Data to capture
        i_data      : in std_logic_vector(127 downto 0);
        i_valid     : in std_logic;
        i_data_clk  : in std_logic;
        -- control registers AXI Lite Interface
        i_s_axi_mosi     : in t_axi4_lite_mosi;
        o_s_axi_miso     : out t_axi4_lite_miso;
        i_s_axi_clk      : in std_logic;
        i_s_axi_rst      : in std_logic;
        -- AXI Full interface for the capture buffer
        i_capmem_MM_IN  : in  t_axi4_full_mosi;
        o_capmem_MM_OUT : out t_axi4_full_miso        
    );
end capture128bit;

architecture Behavioral of capture128bit is

    type cap_fsm_type is (reset, idle, clearCap, capturePacket, waitReset);
    signal cap_fsm : cap_fsm_type := idle;
     
    signal dontCareMask : std_logic_vector(127 downto 0);
    signal triggerMask : std_logic_vector(127 downto 0);
    signal trigger : std_logic_vector(127 downto 0);
    signal triggerAnd : std_logic_vector(3 downto 0);
    signal valid_del1 : std_logic;
    signal valid_del2 : std_logic;
    signal valid_del3 : std_logic;
    signal triggerFinal : std_logic;
    signal reg_rw : t_cap128ctrl_rw;
    signal reg_ro : t_cap128ctrl_ro;
    
    signal capBufWE : std_logic;
    signal capBufWrAddr : std_logic_vector(11 downto 0);
    signal capBufWrData : std_logic_vector(127 downto 0);

    signal packetAddrWE : std_logic;
    signal packetAddrWrData : std_logic_vector(31 downto 0);
    signal packetAddrWrAddr : std_logic_vector(4 downto 0);  -- Capture up to 32 packets.
    
    signal ploc_in : t_cap128ctrl_packetlocations_ram_in;
    signal ploc_out : t_cap128ctrl_packetlocations_ram_out;
    signal capEnable, capEnableDel1 : std_logic;
    signal packetsCaptured : std_logic_vector(4 downto 0);
    signal capWrAddr, capWrAddrOld : std_logic_vector(11 downto 0);
    signal capWrAddrStart : std_logic_vector(11 downto 0);
    
    signal i_data_clk_vec : std_logic_vector(0 downto 0);
    signal rst_vec : std_logic_vector(0 downto 0);
    signal data_del1, data_del2, data_del3 : std_logic_vector(127 downto 0);
    
begin
    
    dontCareMask(31 downto 0) <= reg_rw.dontCareMask0;
    dontCareMask(63 downto 32) <= reg_rw.dontCareMask1;
    dontCareMask(95 downto 64) <= reg_rw.dontCareMask2;
    dontCareMask(127 downto 96) <= reg_rw.dontCareMask3;

    triggerMask(31 downto 0) <= reg_rw.trigger0;
    triggerMask(63 downto 32) <= reg_rw.trigger1;
    triggerMask(95 downto 64) <= reg_rw.trigger2;
    triggerMask(127 downto 96) <= reg_rw.trigger3;
    
    process(i_data_clk)
        variable triggerAnd_v : std_logic_vector(3 downto 0);
    begin
        if rising_edge(i_data_clk) then
            -- Compare the first word of packets with the trigger and dontCare masks

            
            if valid_del1 = '0' and i_valid = '1' then -- first word of the packet
                trigger <= (i_data xnor triggerMask) or dontCareMask;
            end if;
            valid_del1 <= i_valid;
            data_del1 <= i_data;
            
            -- Reduce trigger down to 4 bits.
            for j in 0 to 3 loop
                triggerAnd_v(j) := '1';
                for i in 0 to 31 loop
                    triggerAnd_v(j) := triggerAnd_v(j) and trigger(j*32 + i);
                end loop;
            end loop;
            valid_del2 <= valid_del1;
            data_del2 <= data_del1;
            triggerAnd <= triggerAnd_v;
            
            -- Reduce to a single bit capture trigger
            if valid_del2 = '1' and valid_del3 = '0' then -- triggerAnd is valid
                triggerFinal <= triggerAnd(0) and triggerAnd(1) and triggerAnd(2) and triggerAnd(3);
            else
                triggerFinal <= '0';
            end if;
            data_del3 <= data_del2;
            valid_del3 <= valid_del2;
            
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
                        if reg_rw.enable = '1' and triggerFinal = '1' then
                            cap_fsm <= capturePacket;
                            capWrAddrStart <= capWrAddr;
                            if capWrAddr = "111111111111" then
                                cap_fsm <= waitReset;
                            else
                                capWrAddr <= std_logic_vector(unsigned(capWrAddr) + 1);
                                capWrAddrOld <= capWrAddr;
                            end if;
                        end if;
                    
                    when capturePacket =>
                        -- wait until valid goes low, then go back to idle.
                        if valid_del3 = '0' then
                            packetAddrWrAddr <= packetsCaptured;
                            packetsCaptured <= std_logic_vector(unsigned(packetsCaptured) + 1);
                            -- start address and finish address
                            -- addresses are for 128 bit words, so multiply by 4 to get the 32bit word address that MACE uses.
                            -- Also pad with 2 bits, so that the addresses are 16 bit aligned.
                            packetAddrWrData <= "00" & capWrAddrOld & "00" & "00" & capWrAddrStart & "00"; 
                            packetAddrWe <= '1';
                            if (capWrAddr = "111111111111") then
                                cap_fsm <= waitReset;
                            else
                                cap_fsm <= idle;
                            end if;
                        else
                            if capWrAddr = "111111111111" then
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
            capBufWrData <= data_del3;
            if (cap_fsm = idle and triggerFinal = '1') or (cap_fsm = capturePacket and valid_del3 = '1') then
                capBufWE <= '1';
            else
                capBufWE <= '0';
            end if;
            
            
        end if;
    end process;
    
    -- current write address into the capture buffer. x4 so that it is in 32-bit word addresses (since the firmware side interface is 128 bits wide).
    reg_ro.capwraddr <= x"0000" & "00" & capWrAddr & "00"; --	(31:0);
    reg_ro.packetscaptured <= x"00" & "000" & packetsCaptured; -- (15:0), maximum number of packets captured is 31.
    
    ploc_in.rst <= '0';
    ploc_in.rd_en <= '0';
    ploc_in.adr <= packetAddrWrAddr;
    ploc_in.wr_en <= packetAddrWe;
    ploc_in.wr_dat <= packetAddrWrData;
    ploc_in.clk <= i_data_clk;
    
    reg:  entity work.capture128bit_reg
    port map (
        MM_CLK               => i_s_axi_clk,       -- in STD_LOGIC;
        MM_RST               => i_s_axi_rst,       -- in STD_LOGIC;
        st_clk_cap128ctrl    => i_data_clk_vec,    -- in STD_LOGIC_VECTOR(0 TO 0);
        st_rst_cap128ctrl    => rst_vec,        -- in STD_LOGIC_VECTOR(0 TO 0);
        SLA_IN               => i_s_axi_mosi,      -- in  t_axi4_lite_mosi;
        SLA_OUT              => o_s_axi_miso,      -- out t_axi4_lite_miso;
        CAP128CTRL_FIELDS_RW => reg_rw,            -- out t_cap128ctrl_rw;
        CAP128CTRL_FIELDS_RO => reg_ro,            -- in  t_cap128ctrl_ro
        CAP128CTRL_PACKETLOCATIONS_IN  => ploc_in, -- IN  t_cap128ctrl_packetlocations_ram_in;
        CAP128CTRL_PACKETLOCATIONS_OUT => ploc_out -- OUT t_cap128ctrl_packetlocations_ram_out
    );
    i_data_clk_vec(0) <= i_data_clk;
    rst_vec(0) <= '0';
    
    cmem : entity work.capture128bit_capbuf_ram
    PORT map (
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
