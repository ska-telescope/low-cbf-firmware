-------------------------------------------------------------------------------
-- Title      : DSP wrapper for Output Buffer
-- Author     : Norbert Abel  <norbert_abel@gmx.net>
-------------------------------------------------------------------------------
-- Description: Implements the Xilinx DSP48E2 via a macro
---------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

ENTITY ctc_output_dsp IS
  GENERIC (
    g_MREG      : natural range 0 to 1 := 0
  );
  PORT (
    i_CLK   : IN  std_logic;
    i_A     : IN  signed;
    i_B     : IN  signed;
    o_P     : OUT signed
  );
END ctc_output_dsp;

ARCHITECTURE struct OF ctc_output_dsp IS
    
    signal A : std_logic_vector(29 downto 0) := (others => '0');
    signal B : std_logic_vector(17 downto 0) := (others => '0');
    signal C : std_logic_vector(47 downto 0) := (others => '0');
    signal D : std_logic_vector(26 downto 0) := (others => '0');
    signal P : std_logic_vector(47 downto 0) := (others => '0');
    
    signal OPMODE : std_logic_vector(8 downto 0) := (others => '0');
    signal INMODE : std_logic_vector(4 downto 0) := (others => '0');
    
BEGIN

    A(i_A'range) <= std_logic_vector(i_A);
    A(A'high downto i_A'high+1) <= (others => i_A(i_A'high));
    
    B(i_B'range) <= std_logic_vector(i_B);
    B(B'high downto i_B'high+1) <= (others => i_B(i_B'high));
    
    o_P <= signed(P(P'high) & P(o_P'high-1 downto 0));
    
    OPMODE <=      B"00_000_01_01";   -- 9-bit input: Operation mode: W=0, Z=0,    X+Y=M

    INMODE <=      B"10001";          -- 5-bit input: INMODE control:  A1 * B1
              
    DSP48E2_inst : DSP48E2
    GENERIC MAP (
          -- Feature Control Attributes: Data Path Selection
        AMULTSEL => "A",                   -- Selects A input to multiplier (A, AD)
        A_INPUT => "DIRECT",               -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
        BMULTSEL => "B",                   -- Selects B input to multiplier (AD, B)
        B_INPUT => "DIRECT",               -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
        PREADDINSEL => "A",                -- Selects input to pre-adder (A, B)
        RND => X"000000000000",            -- Rounding Constant
        USE_MULT => "MULTIPLY",            -- Select multiplier usage (DYNAMIC, MULTIPLY, NONE)
        USE_SIMD => "ONE48",               -- SIMD selection (FOUR12, ONE48, TWO24)
        USE_WIDEXOR => "FALSE",            -- Use the Wide XOR function (FALSE, TRUE)
        XORSIMD => "XOR24_48_96",          -- Mode of operation for the Wide XOR (XOR12, XOR24_48_96)
        -- Pattern Detector Attributes: Pattern Detection Configuration
        AUTORESET_PATDET => "NO_RESET",    -- NO_RESET, RESET_MATCH, RESET_NOT_MATCH
        AUTORESET_PRIORITY => "RESET",     -- Priority of AUTORESET vs. CEP (CEP, RESET).
        MASK => X"3fffffffffff",           -- 48-bit mask value for pattern detect (1=ignore)
        PATTERN => X"000000000000",        -- 48-bit pattern match for pattern detect
        SEL_MASK => "MASK",                -- C, MASK, ROUNDING_MODE1, ROUNDING_MODE2
        SEL_PATTERN => "PATTERN",          -- Select pattern value (C, PATTERN)
        USE_PATTERN_DETECT => "NO_PATDET", -- Enable pattern detect (NO_PATDET, PATDET)
        -- Programmable Inversion Attributes: Specifies built-in programmable inversion on specific pins
        IS_ALUMODE_INVERTED => "0000",     -- Optional inversion for ALUMODE
        IS_CARRYIN_INVERTED => '0',        -- Optional inversion for CARRYIN
        IS_CLK_INVERTED => '0',            -- Optional inversion for CLK
        IS_INMODE_INVERTED => "00000",     -- Optional inversion for INMODE
        IS_OPMODE_INVERTED => "000000000", -- Optional inversion for OPMODE
        IS_RSTALLCARRYIN_INVERTED => '0',  -- Optional inversion for RSTALLCARRYIN
        IS_RSTALUMODE_INVERTED => '0',     -- Optional inversion for RSTALUMODE
        IS_RSTA_INVERTED => '0',           -- Optional inversion for RSTA
        IS_RSTB_INVERTED => '0',           -- Optional inversion for RSTB
        IS_RSTCTRL_INVERTED => '0',        -- Optional inversion for RSTCTRL
        IS_RSTC_INVERTED => '0',           -- Optional inversion for RSTC
        IS_RSTD_INVERTED => '0',           -- Optional inversion for RSTD
        IS_RSTINMODE_INVERTED => '0',      -- Optional inversion for RSTINMODE
        IS_RSTM_INVERTED => '0',           -- Optional inversion for RSTM
        IS_RSTP_INVERTED => '0',           -- Optional inversion for RSTP
        -- Register Control Attributes: Pipeline Register Configuration
        ACASCREG => 1,                     -- Number of pipeline stages between A/ACIN and ACOUT (0-2)
        ADREG => 1,                        -- Pipeline stages for pre-adder (0-1)
        ALUMODEREG => 1,                   -- Pipeline stages for ALUMODE (0-1)
        AREG => 1,                         -- Pipeline stages for A (0-2)
        BCASCREG => 1,                     -- Number of pipeline stages between B/BCIN and BCOUT (0-2)
        BREG => 1,                         -- Pipeline stages for B (0-2)
        CARRYINREG => 1,                   -- Pipeline stages for CARRYIN (0-1)
        CARRYINSELREG => 1,                -- Pipeline stages for CARRYINSEL (0-1)
        CREG => 1,                         -- Pipeline stages for C (0-1)
        DREG => 1,                         -- Pipeline stages for D (0-1)
        INMODEREG => 1,                    -- Pipeline stages for INMODE (0-1)
        MREG => g_MREG,                    -- Multiplier pipeline stages (0-1)
        OPMODEREG => 1,                    -- Pipeline stages for OPMODE (0-1)
        PREG => 1                          -- Number of pipeline stages for P (0-1)
    )
    port map (
        -- Cascade outputs: Cascade Ports
        ACOUT => open,                   -- 30-bit output: A port cascade
        BCOUT => open,                   -- 18-bit output: B cascade
        CARRYCASCOUT => open,            -- 1-bit output: Cascade carry
        MULTSIGNOUT => open,             -- 1-bit output: Multiplier sign cascade
        PCOUT => open,                   -- 48-bit output: Cascade output
        -- Control outputs: Control Inputs/Status Bits
        OVERFLOW => open,                -- 1-bit output: Overflow in add/acc
        PATTERNBDETECT => open,          -- 1-bit output: Pattern bar detect
        PATTERNDETECT => open,           -- 1-bit output: Pattern detect
        UNDERFLOW => open,               -- 1-bit output: Underflow in add/acc
        -- Data outputs: Data Ports
        CARRYOUT => open,                 -- 4-bit output: Carry
        P => P,                           -- 48-bit output: Primary data
        XOROUT => open,                   -- 8-bit output: XOR data
        -- Cascade inputs: Cascade Ports
        ACIN => (others => '0'),          -- 30-bit input: A cascade data
        BCIN => (others => '0'),          -- 18-bit input: B cascade
        CARRYCASCIN => '0',               -- 1-bit input: Cascade carry
        MULTSIGNIN => '0',                -- 1-bit input: Multiplier sign cascade
        PCIN => (others => '0'),          -- 48-bit input: P cascade
        -- Control inputs: Control Inputs/Status Bits
        ALUMODE => B"0000",               -- 4-bit input: ALU control:    P=W+Z+X+Y+CIN
        CARRYINSEL => B"000",             -- 3-bit input: Carry select:   0
        CLK => i_CLK,                     -- 1-bit input: Clock
        INMODE => INMODE,                 -- 5-bit input: INMODE control 
        OPMODE => OPMODE,                 -- 9-bit input: Operation mode
        -- Data inputs: Data Ports
        A => A,                           -- 30-bit input: A data
        B => B,                           -- 18-bit input: B data
        C => C,                           -- 48-bit input: C data
        CARRYIN => '0',                   -- 1-bit input: Carry-in
        D => D,                           -- 27-bit input: D data
        -- Reset/Clock Enable inputs: Reset/Clock Enable Inputs
        CEA1 => '1',                       -- 1-bit input: Clock enable for 1st stage AREG
        CEA2 => '1',                       -- 1-bit input: Clock enable for 2nd stage AREG
        CEAD => '1',                       -- 1-bit input: Clock enable for ADREG
        CEALUMODE => '1',                  -- 1-bit input: Clock enable for ALUMODE
        CEB1 => '1',                       -- 1-bit input: Clock enable for 1st stage BREG
        CEB2 => '1',                       -- 1-bit input: Clock enable for 2nd stage BREG
        CEC => '1',                        -- 1-bit input: Clock enable for CREG
        CECARRYIN => '1',                  -- 1-bit input: Clock enable for CARRYINREG
        CECTRL => '1',                     -- 1-bit input: Clock enable for OPMODEREG and CARRYINSELREG
        CED => '1',                        -- 1-bit input: Clock enable for DREG
        CEINMODE => '1',                   -- 1-bit input: Clock enable for INMODEREG
        CEM => '1',                        -- 1-bit input: Clock enable for MREG
        CEP => '1',                        -- 1-bit input: Clock enable for PREG
        RSTA => '0',                       -- 1-bit input: Reset for AREG
        RSTALLCARRYIN => '0',              -- 1-bit input: Reset for CARRYINREG
        RSTALUMODE => '0',                 -- 1-bit input: Reset for ALUMODEREG
        RSTB => '0',                       -- 1-bit input: Reset for BREG
        RSTC => '0',                       -- 1-bit input: Reset for CREG
        RSTCTRL => '0',                    -- 1-bit input: Reset for OPMODEREG and CARRYINSELREG
        RSTD => '0',                       -- 1-bit input: Reset for DREG and ADREG
        RSTINMODE => '0',                  -- 1-bit input: Reset for INMODEREG
        RSTM => '0',                       -- 1-bit input: Reset for MREG
        RSTP => '0'                        -- 1-bit input: Reset for PREG
    );
 
 END struct;
