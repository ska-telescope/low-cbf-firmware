----------------------------------------------------------------------------------
-- Company: CSIRO 
-- Engineer: David Humphrey (dave.humphrey@csiro.au)
-- 
-- Create Date: 02.04.2019 13:40:03
-- Module Name: IC_LFAAInputFifo - Behavioral
-- Description:
--  * Data goes into a FIFO, 128 bits wide, on i_data_clk. Data is assumed to be written at a faster
--    rate than it is read.
--  * When the FIFO is not empty, the packet is read out using i_IC_clk
--    i_IC_clk may be faster than the input clock, but the FIFO output is 64 bits wide, so the 
--    read rate is lower than the write rate.
--  * Before reading the packet, the header address word is created and pre-pended to the packet.
--    The header address word is used for routing within and between FPGAs, and contains
--       (63 downto 52) <= myX & myY & ZDest; -- destination XYZ
--       (51 downto 40) <= myX & myY & myZ;   -- SRC1 - address of this FPGA
--       (39 downto 28) <= x"fff";            -- SRC2 - unused - only a single hop on the Z network is required
--       (27 downto 16) <= x"fff";            -- SRC3 - unused
--       (15 downto 8)  <= "00000001";        -- 0x01 identifies this as a LFAA ingest --> CTC packet.
--       (7 downto 0)   <= x"00";             -- Used as the SOF indicator when sent over the optics. 
--  * The output of this module should go to an instance of IC_URAMBuffer
----------------------------------------------------------------------------------

library IEEE, axi4_lib;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
Library xpm;
use xpm.vcomponents.all;

entity IC_LFAAInputFifo is
    generic(
        -- 0 = 3 FPGAs (X x Y x Z = 1x1x3), 1 = 12 FPGAs (X x Y x Z = 1x6x2), 2 = etc....
        -- See confluence page (perentie - Model development - packetised model overview - model configuration)    
        ARRAYRELEASE : integer range 0 to 5 := 0 
    );
    port(
        -- Configuration (on i_IC_clk)
        i_myAddr : in std_logic_vector(11 downto 0); -- X,Y and Z coordinates of this FPGA in the array (needed for routing).
        -- FIFO data input interface
        i_data_clk  : in  std_logic;
        i_data_rst  : in  std_logic;
        i_fifoDin   : in  std_logic_vector(131 downto 0);
        i_fifoWr    : in  std_logic;
        o_fifoEmpty : out std_logic;
        -- Packets output.
        i_IC_clk : in  std_logic;     -- Interconnect clock (about 400 MHz)
        o_data   : out std_logic_vector(63 downto 0);
        o_valid  : out std_logic;
        o_sof    : out std_logic;
        o_eof    : out std_logic
    );
end IC_LFAAInputFifo;

architecture Behavioral of IC_LFAAInputFifo is
    
    signal fifo_wr_rst_busy, fifo_rd_rst_busy : std_logic;
    signal fifoWrEn, fifoRdEn, fifoFull, fifoEmpty : std_logic;
    signal fifoRdEnDel1, fifoRdEnDel2 : std_logic;
    signal fifoDout : std_logic_vector(65 downto 0);
    signal LFAADrop, LFAADropDel1 : std_logic := '0';
    signal wrDataCount : std_logic_vector(9 downto 0);
    type rd_fsm_type is (idle, waitFirstWord0, waitFirstWord1, getFirstWord, wrFirstWord, wrAddrWord, wrRestOfPacket, finishPacket);
    signal rd_fsm : rd_fsm_type := idle;
    signal bufDin : std_logic_vector(63 downto 0);
    signal bufValid : std_logic;
    signal myX, myY, myZ : std_logic_vector(3 downto 0);
    signal sof, eof : std_logic;
    signal fifoRdEn_fsm : std_logic;
    signal VC : std_logic_vector(8 downto 0);
    signal firstWordHold : std_logic_vector(65 downto 0);
    signal ZDest : std_logic_vector(3 downto 0);
    signal ZDest9bit : unsigned(8 downto 0);
    
begin
    
    myZ <= i_myAddr(3 downto 0);
    myY <= i_myAddr(7 downto 4);
    myX <= i_myAddr(11 downto 8);
    
    process(i_data_clk)
    begin
        if rising_edge(i_data_clk) then
            if wrDataCount = "0000000000" then
                o_fifoEmpty <= '1';
            else
                o_fifoEmpty <= '0';
            end if;
        end if;
    end process;
    
    
    
    ---------------------------------------------------------------------------------
    -- FIFO read side
    --  + Read from the FIFO
    --  + Generate the first word in the frame containing the addressing information
    --  + write to the URAM
    ---------------------------------------------------------------------------------
    
    fifoRdEn <= fifoRdEn_fsm and not fifoEmpty;
    
    ----------------------------------------------------------------
    -- Calculate the destination FPGA based on the virtual channel
    VC <= firstWordHold(8 downto 0);
    
    GEN_PISA : if ARRAYRELEASE = 0 generate
        -- Z is 0,1 or 2 based on the virtual channel v, with
        -- V  Z
        -- 0  0
        -- 1  1
        -- 2  2
        -- 3  0
        -- 4  1
        -- etc.
        ZDest9bit <= unsigned(VC) mod 3;
        ZDest <= "00" & std_logic_vector(ZDest9bit(1 downto 0));
        
    end generate;
    
    GEN_AA1AA2 : if (ARRAYRELEASE = 1 or ARRAYRELEASE = 2) generate
        -- Z is 0 or 1 based on the virtual channel V
        -- Just use lsb of V
        ZDest <= "000" & VC(0);
    end generate;
    
    GEN_AA3 : if ARRAYRELEASE = 3 generate
        -- Z is 0, 1, 2, or 3, based on low 2 bits of channel 
        ZDest <= "00" & VC(1 downto 0);
    end generate;
    
    GEN_AA4AA5 : if ARRAYRELEASE = 4 or ARRAYRELEASE = 5 generate
        -- Z is 0 to 7, based on low 3 bits of channel
        ZDest <= '0' & VC(2 downto 0);
    end generate;
    
    -----------------------------------------------------------------------------
    -- State machine for reading the fifo and sending data on to the URAM buffer. 
    process(i_IC_clk)
    begin
        if rising_edge(i_IC_clk) then
            -- state machine
            --  - Get the first word from the FIFO
            --  - Generate the address word and send to the URAM
            --  - Send the rest of the data to the URAM
            
            case rd_fsm is
                when idle =>
                    if fifoEmpty = '0' then
                        fifoRdEn_fsm <= '1';
                        rd_fsm <= waitFirstWord0;
                    else
                        fifoRdEn_fsm <= '0';
                    end if;
                    bufValid <= '0';
                    sof <= '0';
                    eof <= '0';
                    
                when waitFirstWord0 =>
                    rd_fsm <= waitFirstWord1;
                    fifoRdEn_fsm <= '0';
                    bufValid <= '0';
                    
                when waitFirstWord1 =>
                    rd_fsm <= getFirstWord;
                    fifoRdEn_fsm <= '0';
                    bufValid <= '0';
                    
                when getFirstWord => -- First word of data out from the FIFO is valid in this state.
                    firstWordHold <= fifoDout;
                    fifoRdEn_fsm <= '1';
                    rd_fsm <= wrAddrWord;
                    bufValid <= '0';
                    
                when wrAddrWord =>
                    rd_fsm <= wrFirstWord;
                    -- Address word at the front of the packet contains DEST, SRC1, SRC2, SRC3, TYPE, SOF
                    bufDin(63 downto 52) <= myX & myY & ZDest; -- destination XYZ
                    bufDin(51 downto 40) <= myX & myY & myZ; -- SRC1 - address of this FPGA
                    bufDin(39 downto 28) <= x"fff"; -- SRC2 - unused - only a single hop on the Z network is required
                    bufDin(27 downto 16) <= x"fff"; -- SRC3 - unused
                    bufDin(15 downto 8) <= "00000001"; -- 0x01 identifies this as a LFAA ingest --> CTC packet.
                    bufDin(7 downto 0) <= x"00";   -- Used as the SOF indicator when sent over the optics. 
                    bufValid <= '1';
                    sof <= '1';
                    eof <= '0';
                
                when wrFirstWord =>
                    rd_fsm <= wrRestOfPacket;
                    bufDin <= firstWordHold(63 downto 0);
                    bufValid <= '1';
                    sof <= '0';
                    eof <= '0';
                
                when wrRestOfPacket =>
                    bufDin <= fifoDout(63 downto 0);
                    bufValid <= '1';
                    if fifoEmpty = '1' then
                        rd_fsm <= finishPacket;
                        fifoRdEn_fsm <= '0';
                    else
                        fifoRdEn_fsm <= '1';
                    end if;
                    sof <= '0';
                    eof <= '0';
                
                when finishPacket => 
                    -- 
                    bufDin <= fifoDout(63 downto 0);
                    rd_fsm <= idle;
                    bufValid <= '1';
                    sof <= '0';
                    eof <= '1';
                
                when others =>
                    rd_fsm <= idle;
            end case;
            
            fifoRdEnDel1 <= fifoRdEn;
            fifoRdEnDel2 <= fifoRdEnDel1;
            
        end if;
    end process;
    
    o_data <= bufDin;
    o_valid <= bufValid;
    o_sof <= sof;
    o_eof <= eof;
    
    -- dual clock FIFO
    -- 132 bit input, 66 bit output.
    -- Top 2 bits of each 66 bit word are used to indicate start and end of frame :
    --  "01" = first word in frame
    --  "10" = last word in frame
    --  "11" = invalid
    --  "00" = data word (not first or last).
    -- xpm_fifo_async: Asynchronous FIFO
    -- Xilinx Parameterized Macro, version 2019.1

    xpm_fifo_async_inst : xpm_fifo_async
    generic map (
        CDC_SYNC_STAGES => 2,       -- Integer, Range: 2 - 8. Specifies the number of synchronization stages on the CDC path.
        DOUT_RESET_VALUE => "0",    -- String, Reset value of read data path.
        ECC_MODE => "no_ecc",       -- String, Allowed values: no_ecc, en_ecc.
        FIFO_MEMORY_TYPE => "block", -- String, Allowed values: auto, block, distributed. 
        FIFO_READ_LATENCY => 2,     -- Integer, Range: 0 - 10. Must be 0 for first READ_MODE = "fwft" (first word fall through).    
        FIFO_WRITE_DEPTH => 512,    -- Integer, Range: 16 - 4194304. Defines the FIFO Write Depth. Must be power of two.
        FULL_RESET_VALUE => 0,      -- Integer, Range: 0 - 1. Sets full, almost_full and prog_full to FULL_RESET_VALUE during reset
        PROG_EMPTY_THRESH => 10,    -- Integer, Range: 3 - 4194301.Specifies the minimum number of read words in the FIFO at or below which prog_empty is asserted.
        PROG_FULL_THRESH => 10,     -- Integer, Range: 5 - 4194301. Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted.
        RD_DATA_COUNT_WIDTH => 1,   -- Integer, Range: 1 - 23. Specifies the width of rd_data_count. To reflect the correct value, the width should be log2(FIFO_READ_DEPTH)+1. FIFO_READ_DEPTH = FIFO_WRITE_DEPTH*WRITE_DATA_WIDTH/READ_DATA_WIDTH         
        READ_DATA_WIDTH => 66,      -- Integer, Range: 1 - 4096. Defines the width of the read data port, dout
        READ_MODE => "std",         -- String, Allowed values: std, fwft. Default value = std.
        RELATED_CLOCKS => 0,        -- Integer, Range: 0 - 1. Specifies if the wr_clk and rd_clk are related having the same source but different clock ratios                    |
        --SIM_ASSERT_CHK => 0,        -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
        USE_ADV_FEATURES => "0004", -- String
        -- |---------------------------------------------------------------------------------------------------------------------|
        -- | Enables data_valid, almost_empty, rd_data_count, prog_empty, underflow, wr_ack, almost_full, wr_data_count,         |
        -- | prog_full, overflow features.                                                                                       |
        -- |                                                                                                                     |
        -- |   Setting USE_ADV_FEATURES[0] to 1 enables overflow flag;     Default value of this bit is 1                        |
        -- |   Setting USE_ADV_FEATURES[1]  to 1 enables prog_full flag;    Default value of this bit is 1                       |
        -- |   Setting USE_ADV_FEATURES[2]  to 1 enables wr_data_count;     Default value of this bit is 1                       |
        -- |   Setting USE_ADV_FEATURES[3]  to 1 enables almost_full flag;  Default value of this bit is 0                       |
        -- |   Setting USE_ADV_FEATURES[4]  to 1 enables wr_ack flag;       Default value of this bit is 0                       |
        -- |   Setting USE_ADV_FEATURES[8]  to 1 enables underflow flag;    Default value of this bit is 1                       |
        -- |   Setting USE_ADV_FEATURES[9]  to 1 enables prog_empty flag;   Default value of this bit is 1                       |
        -- |   Setting USE_ADV_FEATURES[10] to 1 enables rd_data_count;     Default value of this bit is 1                       |
        -- |   Setting USE_ADV_FEATURES[11] to 1 enables almost_empty flag; Default value of this bit is 0                       |
        -- |   Setting USE_ADV_FEATURES[12] to 1 enables data_valid flag;   Default value of this bit is 0                       |
        WAKEUP_TIME => 0,           -- Integer, Range: 0 - 2. 0 = Disable sleep 
        WRITE_DATA_WIDTH => 132,    -- Integer, Range: 1 - 4096. Defines the width of the write data port, din             
        WR_DATA_COUNT_WIDTH => 10   -- Integer, Range: 1 - 23. Specifies the width of wr_data_count. To reflect the correct value, the width should be log2(FIFO_WRITE_DEPTH)+1.   |
    )
    port map (
        almost_empty => open, -- 1-bit output: Almost Empty : When asserted, this signal indicates that only one more read can be performed before the FIFO goes to empty.
        almost_full => open,  -- 1-bit output: Almost Full: When asserted, this signal indicates that only one more write can be performed before the FIFO is full.
        data_valid => open,   -- 1-bit output: Read Data Valid: When asserted, this signal indicates that valid data is available on the output bus (dout).
        dbiterr => open,      -- 1-bit output: Double Bit Error: Indicates that the ECC decoder detected a double-bit error and data in the FIFO core is corrupted.
        dout => fifoDout,   -- READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven when reading the FIFO.
        empty => fifoEmpty, -- 1-bit output: Empty Flag: When asserted, this signal indicates that
                            -- the FIFO is empty. Read requests are ignored when the FIFO is empty, initiating a read while empty is not destructive to the FIFO.
        full => fifoFull,   -- 1-bit output: Full Flag: When asserted, this signal indicates that the FIFO is full. Write requests are ignored when the FIFO is full,
                            -- initiating a write when the FIFO is full is not destructive to the contents of the FIFO.
        overflow => open,   -- 1-bit output: Overflow: This signal indicates that a write request (wren) during the prior clock cycle was rejected, because the FIFO is
                            -- full. Overflowing the FIFO is not destructive to the contents of the FIFO.
        prog_empty => open, -- 1-bit output: Programmable Empty: This signal is asserted when the number of words in the FIFO is less than or equal to the programmable
                            -- empty threshold value. It is de-asserted when the number of words in the FIFO exceeds the programmable empty threshold value.
        prog_full => open,  -- 1-bit output: Programmable Full: This signal is asserted when the number of words in the FIFO is greater than or equal to the
                            -- programmable full threshold value. It is de-asserted when the number of words in the FIFO is less than the programmable full threshold value.
        rd_data_count => open, -- RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates the number of words read from the FIFO.
        rd_rst_busy => fifo_rd_rst_busy, -- 1-bit output: Read Reset Busy: Active-High indicator that the FIFO read domain is currently in a reset state.
        sbiterr => open,                 -- 1-bit output: Single Bit Error: Indicates that the ECC decoder detected and fixed a single-bit error.
        underflow => open,         -- 1-bit output: Underflow: Indicates that the read request (rd_en) during the previous clock cycle was rejected because the FIFO is empty. Under flowing the FIFO is not destructive to the FIFO.
        wr_ack => open,            -- 1-bit output: Write Acknowledge: This signal indicates that a write request (wr_en) during the prior clock cycle is succeeded.
        wr_data_count => wrDataCount,    -- WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates the number of words written into the FIFO.
        wr_rst_busy => fifo_wr_rst_busy, -- 1-bit output: Write Reset Busy: Active-High indicator that the FIFO write domain is currently in a reset state.
        din => i_fifoDin,       -- WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when writing the FIFO.
        injectdbiterr => '0', -- 1-bit input: Double Bit Error Injection: Injects a double bit error if the ECC feature is used on block RAMs or UltraRAM macros.
        injectsbiterr => '0', -- 1-bit input: Single Bit Error Injection: Injects a single bit error if the ECC feature is used on block RAMs or UltraRAM macros.
        rd_clk => i_IC_clk, -- 1-bit input: Read clock: Used for read operation. rd_clk must be a free running clock.
        rd_en => fifoRdEn,   -- 1-bit input: Read Enable: If the FIFO is not empty, asserting this signal causes data (on dout) to be read from the FIFO. Must be held active-low when rd_rst_busy is active high.
        rst => i_data_rst, -- 1-bit input: Reset: Must be synchronous to wr_clk. The clock(s) can be unstable at the time of applying reset, but reset must be released only after the clock(s) is/are stable.
        sleep => '0',      -- 1-bit input: Dynamic power saving: If sleep is High, the memory/fifo block is in power saving mode.
        wr_clk => i_data_clk, -- 1-bit input: Write clock: Used for write operation. wr_clk must be a free running clock.
        wr_en => i_fifoWr     -- bit input: Write Enable: If the FIFO is not full, asserting this signal causes data (on din) to be written to the FIFO. Must be held active-low when rst or wr_rst_busy is active high.
    );
   
    
end Behavioral;

