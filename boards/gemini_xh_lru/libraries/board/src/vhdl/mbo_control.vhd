-------------------------------------------------------------------------------
--
-- File Name: mbo_control.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Thurs Oct 19 16:40:00 2017
-- Template Rev: 1.0
--
-- Title: M&C support for MBO Parts
--
-- Description: Provides the register level interface for the MBO components
--              for monitoring and manual adjustment of registers if required.
--              Also provides a mechanism for programming the MBOs with parameters
--              at startup
--
--
-- Compiler options:
--
--
-- Dependencies:
--
--
--
-------------------------------------------------------------------------------

LIBRARY IEEE, common_lib, i2c_lib, axi4_lib, technology_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE i2c_lib.i2c_smbus_pkg.ALL;
USE i2c_lib.i2c_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE work.i2c_addresses_pkg.ALL;
USE work.gemini_xh_lru_board_mbo_reg_pkg.ALL;

-------------------------------------------------------------------------------
ENTITY mbo_control IS
   GENERIC (
      g_technology      : t_technology := c_tech_select_default;
      g_clk_rate        : INTEGER := 156250000;                   -- Clk rate in HZ
      g_i2c_rate        : INTEGER := 25000;                       -- i2c clock rate in HZ
      g_startup_time    : INTEGER := 2500);                       -- Startup time in mS

   PORT (
      -- Clocks & Resets
      clk               : IN  STD_LOGIC;
      rst               : IN  STD_LOGIC;

      --AXI Interface
      s_axi_mosi        : IN t_axi4_lite_mosi;
      s_axi_miso        : OUT t_axi4_lite_miso;

      -- Transciever Links
      mbo_a_tx_disable  : OUT STD_LOGIC_VECTOR(0 TO 11);
      mbo_a_rx_disable  : OUT STD_LOGIC_VECTOR(0 TO 11);
      mbo_a_loopback    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      mbo_a_rx_locked   : IN STD_LOGIC_VECTOR(0 TO 11);

      mbo_b_tx_disable  : OUT STD_LOGIC_VECTOR(0 TO 11);
      mbo_b_rx_disable  : OUT STD_LOGIC_VECTOR(0 TO 11);
      mbo_b_loopback    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      mbo_b_rx_locked   : IN STD_LOGIC_VECTOR(0 TO 11);

      mbo_c_tx_disable  : OUT STD_LOGIC_VECTOR(0 TO 11);
      mbo_c_rx_disable  : OUT STD_LOGIC_VECTOR(0 TO 11);
      mbo_c_loopback    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      mbo_c_rx_locked   : IN STD_LOGIC_VECTOR(0 TO 11);

      -- Physical Interfaces
      mbo_a_reset       : OUT std_logic;                          -- LVCMOS 1.8V active high
      mbo_b_reset       : OUT std_logic;                          -- LVCMOS 1.8V
      mbo_c_reset       : OUT std_logic;                          -- LVCMOS 1.8V

      mbo_int_n         : IN std_logic;
      mbo_sda           : INOUT std_logic;                        -- OC drive, internal Pullups
      mbo_scl           : INOUT std_logic);                       -- LVCMOS 1.8V
END mbo_control;

-------------------------------------------------------------------------------
ARCHITECTURE rtl OF mbo_control IS


   ---------------------------------------------------------------------------
   -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
   ---------------------------------------------------------------------------

   TYPE fsm_states IS (s_idle, s_startup_wait, s_startup, s_running_monitor, s_running_program, s_running_disable_a, s_running_disable_b, s_running_disable_c);


   CONSTANT c_write_wait         : INTEGER := 16#10#;

   -- Program for i2c Master. Will be implemenetd in ROM by synthessier. Different
   -- Commands have a different numbers of parameters (see Table 5 in i2c documentation)
   -- The sequence order reflects the order they are loaded into the local registers
   CONSTANT c_monitor_seq : t_nat_natural_arr := (
     -- |    Command         |   Parameters
         SMBUS_READ_BYTE,     c_mboa_tx_address, 2,            -- Result 0
         SMBUS_READ_WORD,     c_mboa_tx_address, 9,            -- Result 1|2   (TX Fault)
         SMBUS_READ_WORD,     c_mboa_tx_address, 15,           -- Result 3|4   (TX CDR Unlocked)
         SMBUS_READ_WORD,     c_mboa_tx_address, 22,           -- Result 5|6   (Temperature monitor)
         SMBUS_READ_WORD,     c_mboa_tx_address, 26,           -- Result 7|8   (Vcc monitor)
         SMBUS_READ_WORD,     c_mboa_tx_address, 28,           -- Result 9|10  (VccHI monitor)

         SMBUS_READ_BYTE,     c_mbob_tx_address, 2,            -- Result 11
         SMBUS_READ_WORD,     c_mbob_tx_address, 9,            -- Result 12|13 (TX Fault)
         SMBUS_READ_WORD,     c_mbob_tx_address, 15,           -- Result 14|15 (TX CDR Unlocked)
         SMBUS_READ_WORD,     c_mbob_tx_address, 22,           -- Result 16|17 (Temperature monitor)
         SMBUS_READ_WORD,     c_mbob_tx_address, 26,           -- Result 18|19 (Vcc monitor)
         SMBUS_READ_WORD,     c_mbob_tx_address, 28,           -- Result 20|21 (VccHI monitor)

         SMBUS_READ_BYTE,     c_mboc_tx_address, 2,            -- Result 22
         SMBUS_READ_WORD,     c_mboc_tx_address, 9,            -- Result 23|24 (TX Fault)
         SMBUS_READ_WORD,     c_mboc_tx_address, 15,           -- Result 25|26 (TX CDR Unlocked)
         SMBUS_READ_WORD,     c_mboc_tx_address, 22,           -- Result 27|28 (Temperature monitor)
         SMBUS_READ_WORD,     c_mboc_tx_address, 26,           -- Result 29|30 (Vcc monitor)
         SMBUS_READ_WORD,     c_mboc_tx_address, 28,           -- Result 31|32 (VccHI monitor)

         SMBUS_READ_BYTE,     c_mboa_rx_address, 2,            -- Result 33
         SMBUS_READ_WORD,     c_mboa_rx_address, 7,            -- Result 34|35 (RX loss of signal)
         SMBUS_READ_WORD,     c_mboa_rx_address, 9,            -- Result 36|37 (RX Fault)
         SMBUS_READ_WORD,     c_mboa_rx_address, 12,           -- Result 38|39 (RX CDR Unlocked)
         SMBUS_READ_WORD,     c_mboa_rx_address, 26,           -- Result 40|41 (Vcc monitor)

         SMBUS_READ_BYTE,     c_mbob_rx_address, 2,            -- Result 42
         SMBUS_READ_WORD,     c_mbob_rx_address, 7,            -- Result 43|44 (RX loss of signal)
         SMBUS_READ_WORD,     c_mbob_rx_address, 9,            -- Result 45|46 (RX Fault)
         SMBUS_READ_WORD,     c_mbob_rx_address, 12,           -- Result 47|48 (RX CDR Unlocked)
         SMBUS_READ_WORD,     c_mbob_rx_address, 26,           -- Result 49|50 (Vcc monitor)

         SMBUS_READ_BYTE,     c_mboc_rx_address, 2,            -- Result 51
         SMBUS_READ_WORD,     c_mboc_rx_address, 7,            -- Result 52|53 (RX loss of signal)
         SMBUS_READ_WORD,     c_mboc_rx_address, 9,            -- Result 54|55 (RX Fault)
         SMBUS_READ_WORD,     c_mboc_rx_address, 12,           -- Result 56|57 (RX CDR Unlocked)
         SMBUS_READ_WORD,     c_mboc_rx_address, 26,           -- Result 58|59 (Vcc monitor)

         SMBUS_C_END,
         SMBUS_C_NOP);

   CONSTANT c_disable_a_seq : t_nat_natural_arr := (
     -- |    Command         |   Parameters
         SMBUS_WRITE_BYTE,    c_mboa_tx_address, 117, 0,        -- Link 8->11 TX disable
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_tx_address, 118, 0,        -- Link 0->7 TX disable
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_rx_address, 116, 0,        -- Link 8->11 RX disable
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_rx_address, 117, 0,        -- Link 0->7 RX disable

         SMBUS_C_END,
         SMBUS_C_NOP);

   CONSTANT c_disable_b_seq : t_nat_natural_arr := (
     -- |    Command         |   Parameters
         SMBUS_WRITE_BYTE,    c_mbob_tx_address, 117, 0,        -- Link 8->11 TX disable
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mbob_tx_address, 118, 0,        -- Link 0->7 TX disable
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mbob_rx_address, 116, 0,        -- Link 8->11 RX disable
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mbob_rx_address, 117, 0,        -- Link 0->7 RX disable

         SMBUS_C_END,
         SMBUS_C_NOP);

   CONSTANT c_disable_c_seq : t_nat_natural_arr := (
     -- |    Command         |   Parameters
         SMBUS_WRITE_BYTE,    c_mboc_tx_address, 117, 0,        -- Link 8->11 TX disable
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboc_tx_address, 118, 0,        -- Link 0->7 TX disable
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboc_rx_address, 116, 0,        -- Link 8->11 RX disable
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboc_rx_address, 117, 0,        -- Link 0->7 RX disable

         SMBUS_C_END,
         SMBUS_C_NOP);

   -- Seems to need a long recovery after writes so we interleave all transactions
   CONSTANT c_startup_seq : t_nat_natural_arr := (
         SMBUS_WRITE_BYTE,    c_mboa_tx_address, 43, 1,                 -- All CDR On
         SMBUS_WRITE_BYTE,    c_mbob_tx_address, 43, 1,                 -- All CDR On
         SMBUS_WRITE_BYTE,    c_mboc_tx_address, 43, 1,                 -- All CDR On
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_rx_address, 43, 1,                 -- All CDR On
         SMBUS_WRITE_BYTE,    c_mbob_rx_address, 43, 1,                 -- All CDR On
         SMBUS_WRITE_BYTE,    c_mboc_rx_address, 43, 1,                 -- All CDR On

         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_WORD,    c_mboa_tx_address, 56, 16#0f#, 16#ff#,    -- Squelch disabled
         SMBUS_WRITE_WORD,    c_mbob_tx_address, 56, 16#0f#, 16#ff#,    -- Squelch disabled
         SMBUS_WRITE_WORD,    c_mboc_tx_address, 56, 16#0f#, 16#ff#,    -- Squelch disabled
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_WORD,    c_mboa_rx_address, 56, 16#0f#, 16#ff#,    -- Squelch disabled
         SMBUS_WRITE_WORD,    c_mbob_rx_address, 56, 16#0f#, 16#ff#,    -- Squelch disabled
         SMBUS_WRITE_WORD,    c_mboc_rx_address, 56, 16#0f#, 16#ff#,    -- Squelch disabled

         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_tx_address, 62, 16#88#,            -- High Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mbob_tx_address, 62, 16#66#,            -- High Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mboc_tx_address, 62, 16#aa#,            -- High Frequency equiliser pole
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_rx_address, 62, 16#ee#,            -- Maximum swing
         SMBUS_WRITE_BYTE,    c_mbob_rx_address, 62, 16#ee#,            -- Maximum swing
         SMBUS_WRITE_BYTE,    c_mboc_rx_address, 62, 16#ee#,            -- Maximum swing

         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_tx_address, 63, 16#88#,            -- High Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mbob_tx_address, 63, 16#66#,            -- High Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mboc_tx_address, 63, 16#aa#,            -- High Frequency equiliser pole
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_rx_address, 63, 16#ee#,            -- Maximum swing
         SMBUS_WRITE_BYTE,    c_mbob_rx_address, 63, 16#ee#,            -- Maximum swing
         SMBUS_WRITE_BYTE,    c_mboc_rx_address, 63, 16#ee#,            -- Maximum swing

         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_tx_address, 64, 16#88#,            -- High Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mbob_tx_address, 64, 16#66#,            -- High Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mboc_tx_address, 64, 16#aa#,            -- High Frequency equiliser pole
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_rx_address, 64, 16#ee#,            -- Maximum swing
         SMBUS_WRITE_BYTE,    c_mbob_rx_address, 64, 16#ee#,            -- Maximum swing
         SMBUS_WRITE_BYTE,    c_mboc_rx_address, 64, 16#ee#,            -- Maximum swing

         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_tx_address, 65, 16#88#,            -- High Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mbob_tx_address, 65, 16#66#,            -- High Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mboc_tx_address, 65, 16#aa#,            -- High Frequency equiliser pole
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_rx_address, 65, 16#ee#,            -- Maximum swing
         SMBUS_WRITE_BYTE,    c_mbob_rx_address, 65, 16#ee#,            -- Maximum swing
         SMBUS_WRITE_BYTE,    c_mboc_rx_address, 65, 16#ee#,            -- Maximum swing

         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_tx_address, 66, 16#88#,            -- High Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mbob_tx_address, 66, 16#66#,            -- High Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mboc_tx_address, 66, 16#aa#,            -- High Frequency equiliser pole
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_rx_address, 66, 16#ee#,            -- Maximum swing
         SMBUS_WRITE_BYTE,    c_mbob_rx_address, 66, 16#ee#,            -- Maximum swing
         SMBUS_WRITE_BYTE,    c_mboc_rx_address, 66, 16#ee#,            -- Maximum swing

         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_tx_address, 67, 16#88#,            -- High Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mbob_tx_address, 67, 16#66#,            -- High Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mboc_tx_address, 67, 16#aa#,            -- High Frequency equiliser pole
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_rx_address, 67, 16#ee#,            -- Maximum swing
         SMBUS_WRITE_BYTE,    c_mbob_rx_address, 67, 16#ee#,            -- Maximum swing
         SMBUS_WRITE_BYTE,    c_mboc_rx_address, 67, 16#ee#,            -- Maximum swing

         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_tx_address, 68, 16#11#,            -- Mid Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mbob_tx_address, 68, 16#11#,            -- Mid Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mboc_tx_address, 68, 16#11#,            -- Mid Frequency equiliser pole
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_rx_address, 68, 16#22#,            -- Little bit of deempthesis
         SMBUS_WRITE_BYTE,    c_mbob_rx_address, 68, 16#0#,             -- Deempthesis minimum
         SMBUS_WRITE_BYTE,    c_mboc_rx_address, 68, 16#22#,            -- Little bit of deempthesis

         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_tx_address, 69, 16#11#,            -- Mid Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mbob_tx_address, 69, 16#11#,            -- Mid Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mboc_tx_address, 69, 16#11#,            -- Mid Frequency equiliser pole
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_rx_address, 69, 16#22#,            -- Little bit of deempthesis
         SMBUS_WRITE_BYTE,    c_mbob_rx_address, 69, 16#0#,             -- Deempthesis minimum
         SMBUS_WRITE_BYTE,    c_mboc_rx_address, 69, 16#22#,            -- Little bit of deempthesis

         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_tx_address, 70, 16#11#,            -- Mid Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mbob_tx_address, 70, 16#11#,            -- Mid Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mboc_tx_address, 70, 16#11#,            -- Mid Frequency equiliser pole
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_rx_address, 70, 16#22#,            -- Deempthesis minimum
         SMBUS_WRITE_BYTE,    c_mbob_rx_address, 70, 16#0#,             -- Deempthesis minimum
         SMBUS_WRITE_BYTE,    c_mboc_rx_address, 70, 16#22#,            -- Deempthesis minimum

         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_tx_address, 71, 16#11#,            -- Mid Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mbob_tx_address, 71, 16#11#,            -- Mid Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mboc_tx_address, 71, 16#11#,            -- Mid Frequency equiliser pole
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_rx_address, 71, 16#22#,            -- Little bit of deempthesis
         SMBUS_WRITE_BYTE,    c_mbob_rx_address, 71, 16#0#,             -- Deempthesis minimum
         SMBUS_WRITE_BYTE,    c_mboc_rx_address, 71, 16#22#,            -- Little bit of deempthesis

         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_tx_address, 72, 16#11#,            -- Mid Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mbob_tx_address, 72, 16#11#,            -- Mid Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mboc_tx_address, 72, 16#11#,            -- Mid Frequency equiliser pole
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_rx_address, 72, 16#22#,            -- Little bit of deempthesis
         SMBUS_WRITE_BYTE,    c_mbob_rx_address, 72, 16#0#,             -- Deempthesis minimum
         SMBUS_WRITE_BYTE,    c_mboc_rx_address, 72, 16#22#,            -- Little bit of deempthesis

         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_tx_address, 73, 16#11#,            -- Mid Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mbob_tx_address, 73, 16#11#,            -- Mid Frequency equiliser pole
         SMBUS_WRITE_BYTE,    c_mboc_tx_address, 73, 16#11#,            -- Mid Frequency equiliser pole
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_rx_address, 73, 16#22#,            -- Little bit of deempthesis
         SMBUS_WRITE_BYTE,    c_mbob_rx_address, 73, 16#0#,             -- Deempthesis minimum
         SMBUS_WRITE_BYTE,    c_mboc_rx_address, 73, 16#22#,            -- Little bit of deempthesis

         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again
         SMBUS_WRITE_BYTE,    c_mboa_rx_address, 41, 16#07#,            -- 25G rate select
         SMBUS_WRITE_BYTE,    c_mbob_rx_address, 41, 16#07#,            -- 25G rate select
         SMBUS_WRITE_BYTE,    c_mboc_rx_address, 41, 16#07#,            -- 25G rate select
         SMBUS_C_WAIT,        16#00#, 16#00#, c_write_wait, 16#00#,     -- Wait before accessing same module again

         SMBUS_C_END,
         SMBUS_C_NOP);

   CONSTANT c_i2c_phy   : t_c_i2c_phy := (clk_cnt => g_clk_rate/(5*g_i2c_rate)-1,
                                          comma_w => 0);

   CONSTANT c_startup_width   : INTEGER := ceil_log2(g_clk_rate/1000 * g_startup_time);
   CONSTANT c_startup_count   : INTEGER := (g_clk_rate/1000 * g_startup_time) -1;

   ---------------------------------------------------------------------------
   -- SIGNAL DECLARATIONS  --
   ---------------------------------------------------------------------------

   SIGNAL mode                : fsm_states := s_startup_wait;
   SIGNAL prog_finished       : STD_LOGIC;
   SIGNAL error_flag          : STD_LOGIC;
   SIGNAL program_pending     : STD_LOGIC;
   SIGNAL startup_pending     : STD_LOGIC;
   SIGNAL running             : STD_LOGIC;
   SIGNAL sequence_count      : NATURAL RANGE 0 TO 511;
   SIGNAL sequence_count_slv  : STD_LOGIC_VECTOR(8 DOWNTO 0);
   SIGNAL smbus_out_ack_dly   : STD_LOGIC;
   SIGNAL startup_counter     : UNSIGNED(c_startup_width-1 DOWNTO 0) := TO_UNSIGNED(c_startup_count, c_startup_width);
   SIGNAL startup             : STD_LOGIC := '0';
   SIGNAL i_rst               : STD_LOGIC;
   SIGNAL tx_a_cached         : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL rx_a_cached         : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL tx_b_cached         : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL rx_b_cached         : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL tx_c_cached         : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL rx_c_cached         : STD_LOGIC_VECTOR(11 DOWNTO 0);


   SIGNAL i_mbo_int_n         : STD_LOGIC;
   SIGNAL control_fields_rw   : t_control_rw;
   SIGNAL control_fields_ro   : t_control_ro;
   SIGNAL control_program_in  : t_control_program_ram_in;
   SIGNAL control_program_out : t_control_program_ram_out;
   SIGNAL control_results_in  : t_control_results_ram_in;
   SIGNAL control_results_out : t_control_results_ram_out;
   SIGNAL mbo_fields_rw       : t_mbo_rw;
   SIGNAL mbo_fields_ro       : t_mbo_ro;

   SIGNAL result_count        : UNSIGNED(7 DOWNTO 0);
   SIGNAL result_count_dly    : UNSIGNED(7 DOWNTO 0);
   SIGNAL word_shift          : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL smbus_out_val_dly   : STD_LOGIC;

   SIGNAL mbo_reset           : STD_LOGIC_VECTOR(2 DOWNTO 0);

   -- I2c Core
   SIGNAL smbus_out_dat       : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL smbus_in_dat        : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL smbus_in_req        : STD_LOGIC;
   SIGNAL smbus_out_val       : STD_LOGIC;
   SIGNAL smbus_out_err       : STD_LOGIC;
   SIGNAL smbus_out_ack       : STD_LOGIC;
   SIGNAL smbus_st_idle       : STD_LOGIC;
   SIGNAL smbus_st_end        : STD_LOGIC;

   ---------------------------------------------------------------------------
   -- ATTRIBUTES  --
   ---------------------------------------------------------------------------

   ATTRIBUTE DONT_TOUCH                : STRING;
   ATTRIBUTE DONT_TOUCH OF i_rst       : SIGNAL IS "true";

BEGIN

   -- Done this way to avoid simulator warnings
   sequence_count_slv <= STD_LOGIC_VECTOR(TO_UNSIGNED(sequence_count, 9));

   io_reg: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         i_rst <= rst;

         control_fields_ro.status_interrupt <= NOT i_mbo_int_n;

         mbo_a_reset <= mbo_reset(0);
         mbo_b_reset <= mbo_reset(1);
         mbo_c_reset <= mbo_reset(2);

         mbo_fields_ro.status_rx_locked(0) <= flip(mbo_a_rx_locked);
         mbo_fields_ro.status_rx_locked(1) <= flip(mbo_b_rx_locked);
         mbo_fields_ro.status_rx_locked(2) <= flip(mbo_c_rx_locked);

         mbo_a_tx_disable <= flip(mbo_fields_rw.control_tx_disable(0));
         mbo_a_rx_disable <= flip(mbo_fields_rw.control_rx_disable(0));
         mbo_a_loopback<= mbo_fields_rw.control_loopback(0);

         mbo_b_tx_disable <= flip(mbo_fields_rw.control_tx_disable(1));
         mbo_b_rx_disable <= flip(mbo_fields_rw.control_rx_disable(1));
         mbo_b_loopback<= mbo_fields_rw.control_loopback(1);

         mbo_c_tx_disable <= flip(mbo_fields_rw.control_tx_disable(2));
         mbo_c_rx_disable <= flip(mbo_fields_rw.control_rx_disable(2));
         mbo_c_loopback<= mbo_fields_rw.control_loopback(2);
      END IF;
   END PROCESS;


---------------------------------------------------------------------------
-- Registers  --
---------------------------------------------------------------------------

   regs: ENTITY work.gemini_xh_lru_board_mbo_reg
   GENERIC MAP (
      g_technology         => g_technology)
   PORT MAP (
      mm_clk               => clk,
      mm_rst               => i_rst,
      sla_in               => s_axi_mosi,
      sla_out              => s_axi_miso,
      control_fields_rw    => control_fields_rw,
      control_fields_ro    => control_fields_ro,
      control_program_in   => control_program_in,
      control_program_out  => control_program_out,
      control_results_in   => control_results_in,
      control_results_out  => OPEN,
      mbo_fields_rw        => mbo_fields_rw,
      mbo_fields_ro        => mbo_fields_ro);

   control_fields_ro.status_error <= error_flag;
   control_fields_ro.status_prog_finished <= prog_finished;
   control_fields_ro.status_startup <= startup;

   control_fields_ro.status_idle <= '1' WHEN mode = s_idle ELSE '0';

   -- Setup RAMs for custom PROGRAM
   control_program_in.clk <= clk;
   control_program_in.rst <= i_rst;
   control_program_in.adr <= sequence_count_slv(4 DOWNTO 0);
   control_program_in.wr_dat <= (OTHERS => '0');
   control_program_in.wr_en <= '0';
   control_program_in.rd_en <= '1' WHEN mode = s_running_program ELSE '0';

   -- Program Results
   control_results_in.clk <= clk;
   control_results_in.rst <= i_rst;
   control_results_in.rd_en <= '0';
   control_results_in.adr <= STD_LOGIC_VECTOR(result_count(4 DOWNTO 0));
   control_results_in.wr_dat <= smbus_out_dat;
   control_results_in.wr_en <= smbus_out_val WHEN mode = s_running_program else '0';


---------------------------------------------------------------------------
-- High Level Controller  --
---------------------------------------------------------------------------
-- There are two stored programs that can be run, the standard monitoring loop
-- or the clear faults loop. There is also a programmable mode that allows
-- for arbitary programs to be uploaded through the registers and execuet with
-- the results stored in a RAM that can be downloaded

   monitor_fsm: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         i_mbo_int_n <= mbo_int_n;

         smbus_out_ack_dly <= smbus_out_ack;

         IF i_rst = '1' THEN
            mode <= s_startup_wait;
            prog_finished <= '0';
            error_flag <= '0';
            program_pending <= '0';
            startup_pending <= '0';
            running <= '0';
            startup_counter <= TO_UNSIGNED(c_startup_count, c_startup_width);
            startup <= '0';
            tx_a_cached <= (OTHERS => '0');
            rx_a_cached <= (OTHERS => '0');
            tx_b_cached <= (OTHERS => '0');
            rx_b_cached <= (OTHERS => '0');
            tx_c_cached <= (OTHERS => '0');
            rx_c_cached <= (OTHERS => '0');
         ELSE
            error_flag <= error_flag OR smbus_out_err;
            program_pending <= program_pending OR control_fields_rw.control_prog_execute;
            startup_pending <= startup_pending OR control_fields_rw.control_startup_execute;

            -- Clear finished flag when new command requested
            IF control_fields_rw.control_prog_execute = '1' THEN
               prog_finished <= '0';
            END IF;


            CASE mode IS
               -------------------------------
               WHEN s_idle =>
                  running <= '0';
                  sequence_count <= 0;
                  IF smbus_st_idle = '1' THEN
                     IF program_pending = '1' THEN
                        mode <= s_running_program;
                        program_pending <= '0';
                        error_flag <= '0';
                     ELSE
                        IF mbo_fields_rw.control_tx_disable(0) /= tx_a_cached OR mbo_fields_rw.control_rx_disable(0) /= rx_a_cached THEN
                           error_flag <= '0';
                           tx_a_cached <= mbo_fields_rw.control_tx_disable(0);
                           rx_a_cached <= mbo_fields_rw.control_rx_disable(0);
                           mode <= s_running_disable_a;
                        ELSE
                           IF mbo_fields_rw.control_tx_disable(1) /= tx_b_cached OR mbo_fields_rw.control_rx_disable(1) /= rx_b_cached THEN
                              error_flag <= '0';
                              tx_b_cached <= mbo_fields_rw.control_tx_disable(1);
                              rx_b_cached <= mbo_fields_rw.control_rx_disable(1);
                              mode <= s_running_disable_b;
                           ELSE
                              IF mbo_fields_rw.control_tx_disable(2) /= tx_c_cached OR mbo_fields_rw.control_rx_disable(2) /= rx_c_cached THEN
                                 error_flag <= '0';
                                 tx_c_cached <= mbo_fields_rw.control_tx_disable(2);
                                 rx_c_cached <= mbo_fields_rw.control_rx_disable(2);
                                 mode <= s_running_disable_c;
                              ELSE
                                 -- Need to wait until not ready flags are de-asserted before we can program device
                                 IF (startup = '0' OR startup_pending = '1') AND mbo_fields_ro.status_tx_not_ready = "000" AND mbo_fields_ro.status_rx_not_ready = "000" THEN
                                    error_flag <= '0';
                                    mode <= s_startup;
                                    startup_pending <= '0';
                                 ELSE
                                    IF control_fields_rw.control_monitor_enable = '1' THEN
                                       mode <= s_running_monitor;
                                    ELSE
                                       error_flag <= '0';
                                    END IF;
                                 END IF;
                              END IF;
                           END IF;
                        END IF;
                     END IF;
                  END IF;
               -------------------------------
               WHEN s_running_monitor =>
                  running <= '1';
                  IF smbus_st_end = '1' THEN
                     mode <= s_idle;
                  ELSE
                     IF smbus_out_ack = '1' THEN
                        sequence_count <= sequence_count + 1;
                     END IF;
                  END IF;

               -------------------------------
               WHEN s_running_program =>
                  running <= '1';
                  IF smbus_st_end = '1' OR sequence_count = 32 THEN        -- Memory is only 32 elements long, so should be done by now
                     mode <= s_idle;
                     prog_finished <= '1';
                  ELSE
                     IF smbus_out_ack = '1' THEN
                        sequence_count <= sequence_count + 1;
                     END IF;
                  END IF;

               -------------------------------
               WHEN s_running_disable_a | s_running_disable_b | s_running_disable_c =>
                  running <= '1';
                  IF smbus_st_end = '1' THEN
                     mode <= s_idle;
                  ELSE
                     IF smbus_out_ack = '1' THEN
                        sequence_count <= sequence_count + 1;
                     END IF;
                  END IF;

               -------------------------------
               WHEN s_startup_wait =>
                  IF startup_counter = 0 THEN
                     mode <= s_running_monitor;
                  ELSE
                     startup_counter <= startup_counter - 1;
                  END IF;

               -------------------------------
               WHEN s_startup =>
                  running <= '1';
                  IF smbus_st_end = '1' THEN
                     mode <= s_idle;
                     startup <= NOT error_flag;
                  ELSE
                     IF smbus_out_ack = '1' THEN
                        sequence_count <= sequence_count + 1;
                     END IF;
                  END IF;
            END CASE;
         END IF;
      END IF;
   END PROCESS;

   smbus_in_dat <= X"0" & mbo_fields_rw.control_tx_disable(0)(11 DOWNTO 8) WHEN mode = s_running_disable_a AND sequence_count = 3 ELSE
                   mbo_fields_rw.control_tx_disable(0)(7 DOWNTO 0) WHEN mode = s_running_disable_a AND sequence_count = 12 ELSE
                   X"0" & mbo_fields_rw.control_rx_disable(0)(11 DOWNTO 8) WHEN mode = s_running_disable_a AND sequence_count = 21 ELSE
                   mbo_fields_rw.control_rx_disable(0)(7 DOWNTO 0) WHEN mode = s_running_disable_a AND sequence_count = 30 ELSE
                   STD_LOGIC_VECTOR(TO_UNSIGNED(c_disable_a_seq(sequence_count), c_byte_w)) WHEN mode = s_running_disable_a ELSE
                   X"0" & mbo_fields_rw.control_tx_disable(1)(11 DOWNTO 8) WHEN mode = s_running_disable_b AND sequence_count = 3 ELSE
                   mbo_fields_rw.control_tx_disable(1)(7 DOWNTO 0) WHEN mode = s_running_disable_b AND sequence_count = 12 ELSE
                   X"0" & mbo_fields_rw.control_rx_disable(1)(11 DOWNTO 8) WHEN mode = s_running_disable_b AND sequence_count = 21 ELSE
                   mbo_fields_rw.control_rx_disable(1)(7 DOWNTO 0) WHEN mode = s_running_disable_b AND sequence_count = 30 ELSE
                   STD_LOGIC_VECTOR(TO_UNSIGNED(c_disable_b_seq(sequence_count), c_byte_w)) WHEN mode = s_running_disable_b ELSE
                   X"0" & mbo_fields_rw.control_tx_disable(2)(11 DOWNTO 8) WHEN mode = s_running_disable_c AND sequence_count = 3 ELSE
                   mbo_fields_rw.control_tx_disable(2)(7 DOWNTO 0) WHEN mode = s_running_disable_c AND sequence_count = 12 ELSE
                   X"0" & mbo_fields_rw.control_rx_disable(2)(11 DOWNTO 8) WHEN mode = s_running_disable_c AND sequence_count = 21 ELSE
                   mbo_fields_rw.control_rx_disable(2)(7 DOWNTO 0) WHEN mode = s_running_disable_c AND sequence_count = 30 ELSE
                   STD_LOGIC_VECTOR(TO_UNSIGNED(c_disable_c_seq(sequence_count), c_byte_w)) WHEN mode = s_running_disable_c ELSE
                   STD_LOGIC_VECTOR(TO_UNSIGNED(c_monitor_seq(sequence_count), c_byte_w)) WHEN mode = s_running_monitor ELSE
                   STD_LOGIC_VECTOR(TO_UNSIGNED(c_startup_seq(sequence_count), c_byte_w)) WHEN mode = s_startup ELSE
                   control_program_out.rd_dat;

   -- Extra delay from RAM so we drop the req on the increment and reassert a cycle later
   -- smbus_out_ack is asychronous so we need clocked versions
   smbus_in_req <= '0' WHEN mode = s_running_program and smbus_out_ack_dly = '1' ELSE
                   running AND NOT(smbus_st_end);

---------------------------------------------------------------------------
-- result Storage  --
---------------------------------------------------------------------------

   result_counters: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         IF mode = s_idle THEN
            result_count <= (OTHERS => '0');
         ELSE
            IF smbus_out_val = '1' THEN
               result_count <= result_count + 1;
               word_shift <= word_shift(7 DOWNTO 0) & smbus_out_dat;
            END IF;
         END IF;
      END IF;
   END PROCESS;

   data_store: PROCESS (clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         smbus_out_val_dly <= smbus_out_val;
         result_count_dly <= result_count;

         IF smbus_out_val_dly = '1' AND mode = s_running_monitor AND smbus_out_err = '0'THEN
            CASE TO_INTEGER(result_count_dly) IS
               WHEN 0 =>
                  mbo_fields_ro.status_interrupt(0) <= word_shift(1);
                  mbo_fields_ro.status_tx_not_ready(0) <= word_shift(0);
               WHEN 2 =>
                  mbo_fields_ro.tx_fault(0) <= word_shift(11 DOWNTO 0);
               WHEN 4 =>
                  mbo_fields_ro.tx_cdr_unlocked(0) <= word_shift(11 DOWNTO 0);
               WHEN 6 =>
                  mbo_fields_ro.temperature(0) <= word_shift;
               WHEN 8 =>
                  mbo_fields_ro.tx_vcc(0) <= word_shift;
               WHEN 10 =>
                  mbo_fields_ro.vcchi(0) <= word_shift;
               WHEN 11 =>
                  mbo_fields_ro.status_interrupt(1) <= word_shift(1);
                  mbo_fields_ro.status_tx_not_ready(1) <= word_shift(0);
               WHEN 13 =>
                  mbo_fields_ro.tx_fault(1) <= word_shift(11 DOWNTO 0);
               WHEN 15 =>
                  mbo_fields_ro.tx_cdr_unlocked(1) <= word_shift(11 DOWNTO 0);
               WHEN 17 =>
                  mbo_fields_ro.temperature(1) <= word_shift;
               WHEN 19 =>
                  mbo_fields_ro.tx_vcc(1) <= word_shift;
               WHEN 21 =>
                  mbo_fields_ro.vcchi(1) <= word_shift;
               WHEN 22 =>
                  mbo_fields_ro.status_interrupt(2) <= word_shift(1);
                  mbo_fields_ro.status_tx_not_ready(2) <= word_shift(0);
               WHEN 24 =>
                  mbo_fields_ro.tx_fault(2) <= word_shift(11 DOWNTO 0);
               WHEN 26 =>
                  mbo_fields_ro.tx_cdr_unlocked(2) <= word_shift(11 DOWNTO 0);
               WHEN 28 =>
                  mbo_fields_ro.temperature(2) <= word_shift;
               WHEN 30 =>
                  mbo_fields_ro.tx_vcc(2) <= word_shift;
               WHEN 32 =>
                  mbo_fields_ro.vcchi(2) <= word_shift;
               WHEN 33 =>
                  mbo_fields_ro.status_rx_not_ready(0) <= word_shift(0);
               WHEN 35 =>
                  mbo_fields_ro.rx_los(0) <= word_shift(11 DOWNTO 0);
               WHEN 37 =>
                  mbo_fields_ro.rx_fault(0) <= word_shift(11 DOWNTO 0);
               WHEN 39 =>
                  mbo_fields_ro.rx_cdr_unlocked(0) <= word_shift(11 DOWNTO 0);
               WHEN 41 =>
                  mbo_fields_ro.rx_vcc(0) <= word_shift;
               WHEN 42 =>
                  mbo_fields_ro.status_rx_not_ready(1) <= word_shift(0);
               WHEN 44 =>
                  mbo_fields_ro.rx_los(1) <= word_shift(11 DOWNTO 0);
               WHEN 46 =>
                  mbo_fields_ro.rx_fault(1) <= word_shift(11 DOWNTO 0);
               WHEN 48 =>
                  mbo_fields_ro.rx_cdr_unlocked(1) <= word_shift(11 DOWNTO 0);
               WHEN 50 =>
                  mbo_fields_ro.rx_vcc(1) <= word_shift;
               WHEN 51 =>
                  mbo_fields_ro.status_rx_not_ready(2) <= word_shift(0);
               WHEN 53 =>
                  mbo_fields_ro.rx_los(2) <= word_shift(11 DOWNTO 0);
               WHEN 55 =>
                  mbo_fields_ro.rx_fault(2) <= word_shift(11 DOWNTO 0);
               WHEN 57 =>
                  mbo_fields_ro.rx_cdr_unlocked(2) <= word_shift(11 DOWNTO 0);
               WHEN 59 =>
                  mbo_fields_ro.rx_vcc(2) <= word_shift;
               WHEN OTHERS =>
            END CASE;
         END IF;
      END IF;
   END PROCESS;

---------------------------------------------------------------------------
-- SMBUS Controller  --
---------------------------------------------------------------------------

   u_smbus: ENTITY i2c_lib.i2c_smbus
   GENERIC MAP (
      g_i2c_phy   => c_i2c_phy)
   PORT MAP (
      gs_sim       => FALSE,
      rst          => i_rst,
      clk          => clk,
      in_dat       => smbus_in_dat,           -- Command or paramater byte
      in_req       => smbus_in_req,           -- Valid for in_dat
      out_dat      => smbus_out_dat,          -- Output data
      out_val      => smbus_out_val,          -- Valid flag for output data
      out_err      => smbus_out_err,          -- Transaction Error
      out_ack      => smbus_out_ack,          -- Acknowledge in_dat
      st_idle      => smbus_st_idle,          -- FSM in idle
      st_end       => smbus_st_end,           -- End terminator reached
      scl          => mbo_scl,
      sda          => mbo_sda);

---------------------------------------------------------------------------
-- MBO Reset Extender  --
---------------------------------------------------------------------------

   mbo_reset_gen: FOR i IN 0 TO 2 GENERATE
      reset_stretch: ENTITY common_lib.common_pulse_extend
      GENERIC MAP (
         g_rst_level      => '1',
         g_p_in_level     => '1',
         g_ep_out_level   => '1',
         g_extend_w       => 9)
      PORT MAP (
         rst       => i_rst,
         clk       => clk,
         clken     => '1',
         p_in      => mbo_fields_rw.control_reset(i),
         ep_out    => mbo_reset(i));
   END GENERATE;

END rtl;

