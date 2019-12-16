----------------------------------------------------------------------------------
-- Company: CSIRO - CASS 
-- Engineer: David Humphrey (dave.humphrey@csiro.au)
-- 
-- Create Date: 10.12.2018 10:33:12
-- Module Name: FBDistFIFOWrapper - Behavioral
-- Description: 
--  Wrapper for a FIFO instantiated using XPM (Xilinx Parameterised Macro)
--  Used in the filterbanks
--  Fixed Properties
--   * single clock
--   * 1 cycle read latency
--   * Distributed ram
--  Parameters
--   * Bit width
--   * Depth
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
Library xpm;
use xpm.vcomponents.all;

entity FBDistFIFOWrapper is
    generic(
        WIDTH : integer := 64;
        DEPTH : integer := 32
    );
    port(
        clk   : in std_logic;
        rst   : in std_logic;
        -- data in
        din           : in std_logic_vector(WIDTH-1 downto 0);
        wr_en         : in std_logic;
        full          : out std_logic;
        wr_data_count : out std_logic_vector(7 downto 0);
        -- data out
        dout          : out std_logic_vector(WIDTH-1 downto 0);
        rd_en         : in std_logic;
        empty         : out std_logic;
        rd_data_count : out std_logic_vector(7 downto 0)
    );
end FBDistFIFOWrapper;

architecture Behavioral of FBDistFIFOWrapper is

begin

   xpm_fifo_sync_inst : xpm_fifo_sync
   generic map (
      DOUT_RESET_VALUE => "0",    -- String; Reset value of read data path.
      ECC_MODE => "no_ecc",       -- String; "no_ecc" - Disables ECC, "en_ecc" - Enables both ECC Encoder and Decoder 
      FIFO_MEMORY_TYPE => "distributed", -- String; "auto"- Allow Vivado Synthesis to choose, "block"- Block RAM FIFO, "distributed"- Distributed RAM FIFO, "ultra"- URAM FIFO
      FIFO_READ_LATENCY => 1,     -- DECIMAL; Number of output register stages in the read data path; If READ_MODE = "fwft", then the only applicable value is 0
      FIFO_WRITE_DEPTH => 2048,   -- DECIMAL; Defines the FIFO Write Depth, must be power of two; In standard READ_MODE, the effective depth = FIFO_WRITE_DEPTH; In First-Word-Fall-Through READ_MODE, the effective depth = FIFO_WRITE_DEPTH+2
      FULL_RESET_VALUE => 0,      -- DECIMAL; Sets full, almost_full and prog_full to FULL_RESET_VALUE during reset
      PROG_EMPTY_THRESH => 10,    -- DECIMAL; Specifies the minimum number of read words in the FIFO at or below which prog_empty is asserted.
                                  --   Min_Value = 3 + (READ_MODE_VAL*2); Max_Value = (FIFO_WRITE_DEPTH-3) - (READ_MODE_VAL*2)
                                  -- If READ_MODE = "std", then READ_MODE_VAL = 0; Otherwise READ_MODE_VAL = 1
                                  -- NOTE: The default threshold value is dependent on default FIFO_WRITE_DEPTH value. If FIFO_WRITE_DEPTH value is 
                                  -- changed, ensure the threshold value is within the valid range though the programmable flags are not used.
      PROG_FULL_THRESH => 10,     -- DECIMAL; Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted.
                                  --   Min_Value = 3 + (READ_MODE_VAL*2*(FIFO_WRITE_DEPTH/FIFO_READ_DEPTH))
                                  --   Max_Value = (FIFO_WRITE_DEPTH-3) - (READ_MODE_VAL*2*(FIFO_WRITE_DEPTH/FIFO_READ_DEPTH))                                                                       |
                                  -- If READ_MODE = "std", then READ_MODE_VAL = 0; Otherwise READ_MODE_VAL = 1
                                  -- NOTE: The default threshold value is dependent on default FIFO_WRITE_DEPTH value. If FIFO_WRITE_DEPTH value is
                                  -- changed, ensure the threshold value is within the valid range though the programmable flags are not used.
      RD_DATA_COUNT_WIDTH => 8,   -- DECIMAL; Specifies the width of rd_data_count; FIFO_READ_DEPTH = FIFO_WRITE_DEPTH*WRITE_DATA_WIDTH/READ_DATA_WIDTH
      READ_DATA_WIDTH => WIDTH,   -- DECIMAL; Defines the width of the read data port, dout; Range: 1 - 23
      READ_MODE => "std",         -- String; "std"- standard read mode; "fwft"- First-Word-Fall-Through read mode
      USE_ADV_FEATURES => "0404", -- String; 
                                  --  USE_ADV_FEATURES[0] - '1' enables overflow flag;     Default '1'
                                  --  USE_ADV_FEATURES[1] - '1' enables prog_full flag;    Default '1'
                                  --  USE_ADV_FEATURES[2] - '1' enables wr_data_count;     Default '1'
                                  --  USE_ADV_FEATURES[3] - '1' enables almost_full flag;  Default '0'
                                  --  USE_ADV_FEATURES[4] - '1' enables wr_ack flag;       Default '0'
                                  --  USE_ADV_FEATURES[5,6,7] - ? Unused ?
                                  --  USE_ADV_FEATURES[8] - '1' enables underflow flag;    Default '1'
                                  --  USE_ADV_FEATURES[9] - '1' enables prog_empty flag;   Default '1'
                                  --  USE_ADV_FEATURES[10]- '1' enables rd_data_count;     Default '1'
                                  --  USE_ADV_FEATURES[11]- '1' enables almost_empty flag; Default '0'
                                  --  USE_ADV_FEATURES[12]- '1' enables data_valid flag;   Default '0'
      WAKEUP_TIME => 0,           -- DECIMAL;  0 - Disable sleep, 2 - Use Sleep Pin
      WRITE_DATA_WIDTH => WIDTH,  -- DECIMAL; Defines the width of the write data port, din
      WR_DATA_COUNT_WIDTH => 8    -- DECIMAL; Specifies the width of wr_data_count; Range: 1 - 23
   )
   port map (
      almost_empty => open,   -- 1-bit output: Almost Empty : When asserted, this signal indicates that only one more read can be performed before the FIFO goes to empty.
      almost_full => open,    -- 1-bit output: Almost Full: When asserted, this signal indicates that only one more write can be performed before the FIFO is full.
      data_valid => open,     -- 1-bit output: Read Data Valid: When asserted, this signal indicates that valid data is available on the output bus (dout).
      dbiterr => open,        -- 1-bit output: Double Bit Error: Indicates that the ECC decoder detected a double-bit error and data in the FIFO core is corrupted.
      dout => dout,           -- READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven when reading the FIFO.
      empty => empty,         -- 1-bit output: Empty Flag: When asserted, this signal indicates that the FIFO is empty. 
                              -- Read requests are ignored when the FIFO is empty, initiating a read while empty is not destructive to the FIFO.
      full => full,           -- 1-bit output: Full Flag: When asserted, this signal indicates that the FIFO is full.
                              -- Write requests are ignored when the FIFO is full, initiating a write when the FIFO is full is not destructive to the contents of the FIFO.
      overflow => open,       -- 1-bit output: Overflow: This signal indicates that a write request (wren) during the prior clock cycle was rejected, 
                              -- because the FIFO is full. Overflowing the FIFO is not destructive to the contents of the FIFO.
      prog_empty => open,     -- 1-bit output: Programmable Empty: This signal is asserted when the number of words in the FIFO is less than or equal to the programmable
                              -- empty threshold value. It is de-asserted when the number of words in the FIFO exceeds the programmable empty threshold value.
      prog_full => open,      -- 1-bit output: Programmable Full: This signal is asserted when the number of words in the FIFO is greater than or equal to the
                              -- programmable full threshold value. It is de-asserted when the number of words in the FIFO is less than the programmable full threshold value.
      rd_data_count => rd_data_count, -- RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates the number of words read from the FIFO.
      rd_rst_busy => open,    -- 1-bit output: Read Reset Busy: Active-High indicator that the FIFO read domain is currently in a reset state.
      sbiterr => open,        -- 1-bit output: Single Bit Error: Indicates that the ECC decoder detected and fixed a single-bit error.
      underflow => open,      -- 1-bit output: Underflow: Indicates that the read request (rd_en) during the previous clock cycle was rejected because the FIFO is
                              -- empty. Under flowing the FIFO is not destructive to the FIFO.
      wr_ack => open,         -- 1-bit output: Write Acknowledge: This signal indicates that a write request (wr_en) during the prior clock cycle is succeeded.
      wr_data_count => wr_data_count, -- WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates the number of words written into the FIFO.
      wr_rst_busy => open,    -- 1-bit output: Write Reset Busy: Active-High indicator that the FIFO write domain is currently in a reset state.
      din => din,             -- WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when writing the FIFO.
      injectdbiterr => '0',   -- 1-bit input: Double Bit Error Injection: Injects a double bit error if the ECC feature is used on block RAMs or UltraRAM macros.
      injectsbiterr => '0',   -- 1-bit input: Single Bit Error Injection: Injects a single bit error if the ECC feature is used on block RAMs or UltraRAM macros.
      rd_en => rd_en,         -- 1-bit input: Read Enable: If the FIFO is not empty, asserting this signal causes data (on dout) to be read from the FIFO. Must be held
                              -- active-low when rd_rst_busy is active high.
      rst => rst,             -- 1-bit input: Reset: Must be synchronous to wr_clk. Must be applied only when wr_clk is stable and free-running.
      sleep => '0',           -- 1-bit input: Dynamic power saving- If sleep is High, the memory/fifo block is in power saving mode.
      wr_clk => clk,          -- 1-bit input: Write clock: Used for write operation. wr_clk must be a free running clock.
      wr_en => wr_en          -- 1-bit input: Write Enable: If the FIFO is not full, asserting this signal causes data (on din) to be written to the FIFO Must be held
                              -- active-low when rst or wr_rst_busy or rd_rst_busy is active high
   );


end Behavioral;

-- XPM_FIFO instantiation template for Synchronous FIFO configurations
-- Refer to the targeted device family architecture libraries guide for XPM_FIFO documentation
-- =======================================================================================================================
-- Parameter usage table, organized as follows:
-- +---------------------------------------------------------------------------------------------------------------------+
-- | Parameter name       | Data type          | Restrictions, if applicable                                             |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Description                                                                                                         |
-- +---------------------------------------------------------------------------------------------------------------------+
-- +---------------------------------------------------------------------------------------------------------------------+
-- | DOUT_RESET_VALUE     | String             | Default value = 0.                                                      |
-- |---------------------------------------------------------------------------------------------------------------------|
-- +---------------------------------------------------------------------------------------------------------------------+
-- | ECC_MODE             | String             | Allowed values: no_ecc, en_ecc. Default value = no_ecc.                 |
-- |---------------------------------------------------------------------------------------------------------------------|                                                                |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | FIFO_MEMORY_TYPE     | String             | Allowed values: auto, block, distributed, ultra. Default value = auto.  |
-- |---------------------------------------------------------------------------------------------------------------------|
-- +---------------------------------------------------------------------------------------------------------------------+
-- | FIFO_READ_LATENCY    | Integer            | Range: 0 - 100. Default value = 1.                                      |
-- |---------------------------------------------------------------------------------------------------------------------|
-- +---------------------------------------------------------------------------------------------------------------------+
-- | FIFO_WRITE_DEPTH     | Integer            | Range: 16 - 4194304. Default value = 2048.                              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- +---------------------------------------------------------------------------------------------------------------------+
-- | FULL_RESET_VALUE     | Integer            | Range: 0 - 1. Default value = 0.                                        |
-- |---------------------------------------------------------------------------------------------------------------------|
-- +---------------------------------------------------------------------------------------------------------------------+
-- | PROG_EMPTY_THRESH    | Integer            | Range: 3 - 4194304. Default value = 10.                                 |
-- |---------------------------------------------------------------------------------------------------------------------|
-- +---------------------------------------------------------------------------------------------------------------------+
-- | PROG_FULL_THRESH     | Integer            | Range: 3 - 4194301. Default value = 10.                                 |
-- |---------------------------------------------------------------------------------------------------------------------|
-- +---------------------------------------------------------------------------------------------------------------------+
-- | RD_DATA_COUNT_WIDTH  | Integer            | Range: 1 - 23. Default value = 1.                                       |
-- |---------------------------------------------------------------------------------------------------------------------|
-- +---------------------------------------------------------------------------------------------------------------------+
-- | READ_DATA_WIDTH      | Integer            | Range: 1 - 4096. Default value = 32.                                    |
-- |---------------------------------------------------------------------------------------------------------------------|
-- +---------------------------------------------------------------------------------------------------------------------+
-- | READ_MODE            | String             | Allowed values: std, fwft. Default value = std.                         |
-- |---------------------------------------------------------------------------------------------------------------------|
-- +---------------------------------------------------------------------------------------------------------------------+
-- | USE_ADV_FEATURES     | String             | Default value = 0707.                                                   |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Enables data_valid, almost_empty, rd_data_count, prog_empty, underflow, wr_ack, almost_full, wr_data_count,         |
-- | prog_full, overflow features.                                                                                       |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | WAKEUP_TIME          | Integer            | Range: 0 - 2. Default value = 0.                                        |
-- |---------------------------------------------------------------------------------------------------------------------|
-- +---------------------------------------------------------------------------------------------------------------------+
-- | WRITE_DATA_WIDTH     | Integer            | Range: 1 - 4096. Default value = 32.                                    |
-- |---------------------------------------------------------------------------------------------------------------------|
-- +---------------------------------------------------------------------------------------------------------------------+
-- | WR_DATA_COUNT_WIDTH  | Integer            | Range: 1 - 23. Default value = 1.                                       |
-- |---------------------------------------------------------------------------------------------------------------------|
-- +---------------------------------------------------------------------------------------------------------------------+

-- Port usage table, organized as follows:
-- +---------------------------------------------------------------------------------------------------------------------+
-- | Port name      | Direction | Size, in bits                         | Domain  | Sense       | Handling if unused     |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Description                                                                                                         |
-- +---------------------------------------------------------------------------------------------------------------------+
-- +---------------------------------------------------------------------------------------------------------------------+
-- | almost_empty   | Output    | 1                                     | wr_clk  | Active-high | DoNotCare              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Almost Empty : When asserted, this signal indicates that only one more read can be performed before the FIFO goes to|
-- | empty.                                                                                                              |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | almost_full    | Output    | 1                                     | wr_clk  | Active-high | DoNotCare              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Almost Full: When asserted, this signal indicates that only one more write can be performed before the FIFO is full.|
-- +---------------------------------------------------------------------------------------------------------------------+
-- | data_valid     | Output    | 1                                     | wr_clk  | Active-high | DoNotCare              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Read Data Valid: When asserted, this signal indicates that valid data is available on the output bus (dout).        |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | dbiterr        | Output    | 1                                     | wr_clk  | Active-high | DoNotCare              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Double Bit Error: Indicates that the ECC decoder detected a double-bit error and data in the FIFO core is corrupted.|
-- +---------------------------------------------------------------------------------------------------------------------+
-- | din            | Input     | WRITE_DATA_WIDTH                      | wr_clk  | NA          | Required               |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Write Data: The input data bus used when writing the FIFO.                                                          |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | dout           | Output    | READ_DATA_WIDTH                       | wr_clk  | NA          | Required               |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Read Data: The output data bus is driven when reading the FIFO.                                                     |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | empty          | Output    | 1                                     | wr_clk  | Active-high | Required               |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Empty Flag: When asserted, this signal indicates that the FIFO is empty.                                            |
-- | Read requests are ignored when the FIFO is empty, initiating a read while empty is not destructive to the FIFO.     |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | full           | Output    | 1                                     | wr_clk  | Active-high | Required               |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Full Flag: When asserted, this signal indicates that the FIFO is full.                                              |
-- | Write requests are ignored when the FIFO is full, initiating a write when the FIFO is full is not destructive       |
-- | to the contents of the FIFO.                                                                                        |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | injectdbiterr  | Input     | 1                                     | wr_clk  | Active-high | Tie to 1'b0            |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Double Bit Error Injection: Injects a double bit error if the ECC feature is used on block RAMs or                  |
-- | UltraRAM macros.                                                                                                    |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | injectsbiterr  | Input     | 1                                     | wr_clk  | Active-high | Tie to 1'b0            |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Single Bit Error Injection: Injects a single bit error if the ECC feature is used on block RAMs or                  |
-- | UltraRAM macros.                                                                                                    |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | overflow       | Output    | 1                                     | wr_clk  | Active-high | DoNotCare              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Overflow: This signal indicates that a write request (wren) during the prior clock cycle was rejected,              |
-- | because the FIFO is full. Overflowing the FIFO is not destructive to the contents of the FIFO.                      |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | prog_empty     | Output    | 1                                     | wr_clk  | Active-high | DoNotCare              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Programmable Empty: This signal is asserted when the number of words in the FIFO is less than or equal              |
-- | to the programmable empty threshold value.                                                                          |
-- | It is de-asserted when the number of words in the FIFO exceeds the programmable empty threshold value.              |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | prog_full      | Output    | 1                                     | wr_clk  | Active-high | DoNotCare              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Programmable Full: This signal is asserted when the number of words in the FIFO is greater than or equal            |
-- | to the programmable full threshold value.                                                                           |
-- | It is de-asserted when the number of words in the FIFO is less than the programmable full threshold value.          |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | rd_data_count  | Output    | RD_DATA_COUNT_WIDTH                   | wr_clk  | NA          | DoNotCare              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Read Data Count: This bus indicates the number of words read from the FIFO.                                         |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | rd_en          | Input     | 1                                     | wr_clk  | Active-high | Required               |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Read Enable: If the FIFO is not empty, asserting this signal causes data (on dout) to be read from the FIFO.        |
-- |                                                                                                                     |
-- |  Must be held active-low when rd_rst_busy is active high.                                                           |
-- | .                                                                                                                   |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | rd_rst_busy    | Output    | 1                                     | wr_clk  | Active-high | DoNotCare              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Read Reset Busy: Active-High indicator that the FIFO read domain is currently in a reset state.                     |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | rst            | Input     | 1                                     | wr_clk  | Active-high | Required               |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Reset: Must be synchronous to wr_clk. Must be applied only when wr_clk is stable and free-running.                  |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | sbiterr        | Output    | 1                                     | wr_clk  | Active-high | DoNotCare              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Single Bit Error: Indicates that the ECC decoder detected and fixed a single-bit error.                             |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | sleep          | Input     | 1                                     | NA      | Active-high | Tie to 1'b0            |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Dynamic power saving- If sleep is High, the memory/fifo block is in power saving mode.                              |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | underflow      | Output    | 1                                     | wr_clk  | Active-high | DoNotCare              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Underflow: Indicates that the read request (rd_en) during the previous clock cycle was rejected                     |
-- | because the FIFO is empty. Under flowing the FIFO is not destructive to the FIFO.                                   |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | wr_ack         | Output    | 1                                     | wr_clk  | Active-high | DoNotCare              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Write Acknowledge: This signal indicates that a write request (wr_en) during the prior clock cycle is succeeded.    |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | wr_clk         | Input     | 1                                     | NA      | Rising edge | Required               |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Write clock: Used for write operation. wr_clk must be a free running clock.                                         |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | wr_data_count  | Output    | WR_DATA_COUNT_WIDTH                   | wr_clk  | NA          | DoNotCare              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Write Data Count: This bus indicates the number of words written into the FIFO.                                     |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | wr_en          | Input     | 1                                     | wr_clk  | Active-high | Required               |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Write Enable: If the FIFO is not full, asserting this signal causes data (on din) to be written to the FIFO         |
-- |                                                                                                                     |
-- |  Must be held active-low when rst or wr_rst_busy or rd_rst_busy is active high                                      |
-- +---------------------------------------------------------------------------------------------------------------------+
-- | wr_rst_busy    | Output    | 1                                     | wr_clk  | Active-high | DoNotCare              |
-- |---------------------------------------------------------------------------------------------------------------------|
-- | Write Reset Busy: Active-High indicator that the FIFO write domain is currently in a reset state.                   |
-- +---------------------------------------------------------------------------------------------------------------------+


-- xpm_fifo_sync : In order to incorporate this function into the design,
--     VHDL      : the following instance declaration needs to be placed
--   instance    : in the body of the design code.  The instance name
--  declaration  : (xpm_fifo_sync_inst) and/or the port declarations after the
--     code      : "=>" declaration maybe changed to properly reference and
--               : connect this function to the design.  All inputs and outputs
--               : must be connected.

--    Library    : In addition to adding the instance declaration, a use
--  declaration  : statement for the UNISIM.vcomponents library needs to be
--      for      : added before the entity declaration.  This library
--    Xilinx     : contains the component declarations for all Xilinx
--  primitives   : primitives and points to the models that will be used
--               : for simulation.

--  Please reference the appropriate libraries guide for additional information on the XPM modules.

--  Copy the following two statements and paste them before the
--  Entity declaration, unless they already exist.



-- <-----Cut code below this line and paste into the architecture body---->

   -- xpm_fifo_sync: Synchronous FIFO
   -- Xilinx Parameterized Macro, version 2018.2



   -- End of xpm_fifo_sync_inst instantiation
				
			
