-------------------------------------------------------------------------------
--
-- File Name: sfp_control.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Thurs Oct 19 16:40:00 2017
-- Template Rev: 1.0
--
-- Title: M&C support for SFP Parts
--
-- Description: Provides the register level interface for the SFP components
--              for monitoring and manual adjustment of registers if required.
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
USE i2c_lib.i2c_dev_sfp_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE work.i2c_addresses_pkg.ALL;
USE work.gemini_lru_board_sfp_reg_pkg.ALL;

-------------------------------------------------------------------------------
ENTITY sfp_control IS
   GENERIC (
      g_technology      : t_technology := c_tech_select_default;
      g_clk_rate        : INTEGER := 156250000;                   -- Clk rate in HZ
      g_i2c_rate        : INTEGER := 50000;                       -- i2c clock rate in HZ
      g_startup_time    : INTEGER := 50);                         -- Startup time in mS

   PORT (
      rst               : IN  STD_LOGIC;
      clk               : IN  STD_LOGIC;

      --AXI Interface
      s_axi_mosi        : IN t_axi4_lite_mosi;
      s_axi_miso        : OUT t_axi4_lite_miso;

      -- Physical Interfaces
      sfp_sda           : INOUT STD_LOGIC;                        -- OC drive, internal Pullups
      sfp_scl           : INOUT STD_LOGIC;                        -- LVCMOS 1.8V
      sfp_fault         : IN STD_LOGIC;
      sfp_tx_enable     : OUT STD_LOGIC;
      sfp_mod_abs       : IN STD_LOGIC);
END sfp_control;


ARCHITECTURE rtl OF sfp_control IS

  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   TYPE fsm_states IS (s_idle, s_startup_wait, s_startup, s_running_monitor, s_running_program);

   -- Assume that SFP+ modules are internally calibrated
   CONSTANT c_monitor_seq : t_nat_natural_arr := (
     -- |    Command         |   Parameters
         SMBUS_READ_BYTE,     c_sfp_mon_address, SFP_MON_STATUS,            -- Result 0
         SMBUS_READ_WORD,     c_sfp_mon_address, SFP_MON_VOLTAGE,           -- Result 1|2
         SMBUS_READ_WORD,     c_sfp_mon_address, SFP_MON_TX_BIAS,           -- Result 3|4
         SMBUS_READ_WORD,     c_sfp_mon_address, SFP_MON_TX_POWER,          -- Result 5|6
         SMBUS_READ_WORD,     c_sfp_mon_address, SFP_MON_RX_POWER,          -- Result 7|8
         SMBUS_READ_WORD,     c_sfp_mon_address, SFP_MON_TEMPERATURE,       -- Result 9|10

         SMBUS_C_END,
         SMBUS_C_NOP);

   CONSTANT c_i2c_phy   : t_c_i2c_phy := (clk_cnt => g_clk_rate/(5*g_i2c_rate)-1,
                                          comma_w => 0);

   CONSTANT c_startup_width   : INTEGER := ceil_log2(g_clk_rate/1000 * g_startup_time);
   CONSTANT c_startup_count   : INTEGER := (g_clk_rate/1000 * g_startup_time) -1;

   ---------------------------------------------------------------------------
   -- SIGNAL DECLARATIONS  --
   ---------------------------------------------------------------------------

   SIGNAL mode                : fsm_states;
   SIGNAL prog_finished       : STD_LOGIC;
   SIGNAL error_flag          : STD_LOGIC;
   SIGNAL program_pending     : STD_LOGIC;
   SIGNAL running             : STD_LOGIC;
   SIGNAL sequence_count      : NATURAL RANGE 0 TO 31;
   SIGNAL smbus_out_ack_dly   : STD_LOGIC;
   SIGNAL startup_counter     : UNSIGNED(c_startup_width-1 DOWNTO 0);
   SIGNAL i_rst               : STD_LOGIC;

   SIGNAL sfp_fields_rw       : t_sfp_rw;
   SIGNAL sfp_fields_ro       : t_sfp_ro;
   SIGNAL sfp_program_in      : t_sfp_program_ram_in;
   SIGNAL sfp_program_out     : t_sfp_program_ram_out;
   SIGNAL sfp_results_in      : t_sfp_results_ram_in;

   SIGNAL result_count        : UNSIGNED(4 DOWNTO 0);
   SIGNAL result_count_dly    : UNSIGNED(4 DOWNTO 0);
   SIGNAL word_shift          : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL smbus_out_val_dly   : STD_LOGIC;


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

   ATTRIBUTE DONT_TOUCH             : STRING;
   ATTRIBUTE DONT_TOUCH OF i_rst    : SIGNAL IS "true";

BEGIN


   io_reg: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         i_rst <= rst;

         sfp_tx_enable <= not(sfp_fields_rw.control_tx_disable);

         sfp_fields_ro.status_tx_fault <= sfp_fault;
         sfp_fields_ro.status_present <= not(sfp_mod_abs);
      END IF;
   END PROCESS;


---------------------------------------------------------------------------
-- Registers  --
---------------------------------------------------------------------------

regs: ENTITY work.gemini_lru_board_sfp_reg
      GENERIC MAP (g_technology  => g_technology)
      PORT MAP (mm_clk           => clk,
                mm_rst           => i_rst,
                sla_in           => s_axi_mosi,
                sla_out          => s_axi_miso,
                sfp_fields_rw    => sfp_fields_rw,
                sfp_fields_ro    => sfp_fields_ro,
                sfp_program_in   => sfp_program_in,
                sfp_program_out  => sfp_program_out,
                sfp_results_in   => sfp_results_in,
                sfp_results_out  => OPEN);

   sfp_fields_ro.status_error <= error_flag;
   sfp_fields_ro.status_prog_finished <= prog_finished;
   sfp_fields_ro.status_idle <= '1' WHEN mode = s_idle ELSE '0';


   -- Setup RAMs for custom PROGRAM
   sfp_program_in.clk <= clk;
   sfp_program_in.rst <= i_rst;
   sfp_program_in.adr <= STD_LOGIC_VECTOR(TO_UNSIGNED(sequence_count, 5));
   sfp_program_in.wr_dat <= (OTHERS => '0');
   sfp_program_in.wr_en <= '0';
   sfp_program_in.rd_en <= '1' WHEN mode = s_running_program else '0';

   -- Program Results
   sfp_results_in.clk <= clk;
   sfp_results_in.rst <= i_rst;
   sfp_results_in.rd_en <= '0';
   sfp_results_in.adr <= STD_LOGIC_VECTOR(result_count(4 DOWNTO 0));
   sfp_results_in.wr_dat <= smbus_out_dat;
   sfp_results_in.wr_en <= smbus_out_val WHEN mode = s_running_program else '0';

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
         smbus_out_ack_dly <= smbus_out_ack;

         IF i_rst = '1' THEN
            mode <= s_startup_wait;
            prog_finished <= '0';
            error_flag <= '0';
            program_pending <= '0';
            running <= '0';
            startup_counter <= TO_UNSIGNED(c_startup_count, c_startup_width);
         ELSE
            error_flag <= error_flag OR smbus_out_err;
            program_pending <= program_pending OR sfp_fields_rw.control_prog_execute;

            -- Clear finished flag when new command requested
            IF sfp_fields_rw.control_prog_execute = '1' THEN
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
                        IF sfp_fields_rw.control_monitor_enable = '1' THEN
                           mode <= s_running_monitor;
                        ELSE
                           error_flag <= '0';
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
               WHEN s_startup_wait =>
                  IF startup_counter = 0 THEN
                     mode <= s_startup;
                  ELSE
                     startup_counter <= startup_counter - 1;
                  END IF;

               -------------------------------
               WHEN s_startup =>
                  mode <= s_idle;
            END CASE;
         END IF;
      END IF;
   END PROCESS;

   smbus_in_dat <= STD_LOGIC_VECTOR(TO_UNSIGNED(c_monitor_seq(sequence_count), c_byte_w)) WHEN mode = s_running_monitor ELSE
                   sfp_program_out.rd_dat;

   -- Extra delay from RAM so we drop the req on the increment and reassert a cycle later
   -- smbus_out_ack is asychronous so we need clocked versions
   smbus_in_req <= '0' WHEN mode = s_running_program and smbus_out_ack_dly = '1' ELSE
                   running AND NOT(smbus_st_end);

---------------------------------------------------------------------------
-- Result Storage  --
---------------------------------------------------------------------------

result_counters: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         IF mode = s_idle THEN
            result_count <= (OTHERS => '0');
         ELSE
            IF smbus_out_val = '1' THEN
               result_count <= result_count + 1;
               word_shift <=  word_shift(7 DOWNTO 0) & smbus_out_dat;
            END IF;
         END IF;
      END IF;
   END PROCESS;

data_store: PROCESS (clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         smbus_out_val_dly <= smbus_out_val;
         result_count_dly <= result_count;

         IF smbus_out_val_dly = '1' AND mode = s_running_monitor THEN
            CASE TO_INTEGER(result_count_dly) IS
               WHEN 0 =>
                  sfp_fields_ro.status_tx_disable <= word_shift(7);
                  sfp_fields_ro.status_rate_select <= word_shift(5 DOWNTO 4);
                  sfp_fields_ro.status_rx_los <= word_shift(1);
                  sfp_fields_ro.status_not_ready <= word_shift(0);
               WHEN 2 =>
                  sfp_fields_ro.voltage <= word_shift;
               WHEN 4 =>
                  sfp_fields_ro.tx_bias <= word_shift;
               WHEN 6 =>
                  sfp_fields_ro.tx_power <= word_shift;
               WHEN 8 =>
                  sfp_fields_ro.rx_power <= word_shift;
               WHEN 10 =>
                  sfp_fields_ro.temperature <= word_shift;
               WHEN OTHERS =>
            END CASE;
         END IF;
      END IF;
   END PROCESS;

---------------------------------------------------------------------------
-- SMBUS Controller  --
---------------------------------------------------------------------------

u_smbus: ENTITY i2c_lib.i2c_smbus
         GENERIC MAP (g_i2c_phy  => c_i2c_phy)
         PORT MAP (gs_sim        => FALSE,
                   rst           => i_rst,
                   clk           => clk,
                   in_dat        => smbus_in_dat,           -- Command or paramater byte
                   in_req        => smbus_in_req,           -- Valid for in_dat
                   out_dat       => smbus_out_dat,          -- Output data
                   out_val       => smbus_out_val,          -- Valid flag for output data
                   out_err       => smbus_out_err,          -- Transaction Error
                   out_ack       => smbus_out_ack,          -- Acknowledge in_dat
                   st_idle       => smbus_st_idle,          -- FSM in idle
                   st_end        => smbus_st_end,           -- End terminator reached
                   scl           => sfp_scl,
                   sda           => sfp_sda);

END rtl;
