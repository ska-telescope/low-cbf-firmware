-------------------------------------------------------------------------------
--
-- File Name: pmbus_control.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Thurs Oct 19 16:40:00 2017
-- Template Rev: 1.0
--
-- Title: M&C support for Power Supplies
--
-- Description: Provides the register level interface for the power supply
--              components for monitoring and manual adjustment of registers
--              if required.
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
USE i2c_lib.i2c_dev_bmr466_pkg.ALL;
USE i2c_lib.i2c_dev_bmr457_pkg.ALL;
USE i2c_lib.i2c_dev_ltm4676_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE work.i2c_addresses_pkg.ALL;
USE work.vcu128_board_pmbus_reg_pkg.ALL;


ENTITY pmbus_control IS
   GENERIC (
      g_technology      : t_technology := c_tech_select_default;
      g_clk_rate        : INTEGER := 156250000;                   -- Clk rate in HZ
      g_i2c_rate        : INTEGER := 25000;                       -- i2c clock rate in HZ (min 10KHz, max 100KHz)
      g_startup_time    : INTEGER := 50);                         -- Startup time in mS

   PORT (
      -- Clocks & Resets
      clk               : IN  STD_LOGIC;
      rst               : IN  STD_LOGIC;

      --AXI Interface
      s_axi_mosi        : IN t_axi4_lite_mosi;
      s_axi_miso        : OUT t_axi4_lite_miso;

      -- Power Interface
      power_sda         : INOUT std_logic;                        -- OC drive, internal Pullups
      power_sdc         : INOUT std_logic;                        -- LVCMOS 1.8V
      power_alert_n     : IN std_logic);                          -- Active low interrupt
END ENTITY;


ARCHITECTURE rtl OF pmbus_control IS

   ---------------------------------------------------------------------------
   -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
   ---------------------------------------------------------------------------

   TYPE fsm_states IS (s_idle, s_startup_wait, s_startup, s_running_monitor, s_running_clear, s_running_program);

   -- Program for i2c Master. Will be implemenetd in ROM by synthessier. Different
   -- Commands have a different numbers of parameters (see Table 5 in i2c documentation)
   -- The sequence order reflects the order they are loaded into the local registers
   CONSTANT c_monitor_seq : t_nat_natural_arr := (
     -- |    Command         |   Parameters
         SMBUS_READ_WORD,     c_pmbus_vdd0v72a_address, BMR466_STATUS_WORD,            -- Result 0|1
         SMBUS_READ_WORD,     c_pmbus_vdd0v72a_address, BMR466_READ_VIN,               -- Result 2|3
         SMBUS_READ_WORD,     c_pmbus_vdd0v72a_address, BMR466_READ_VOUT,              -- Result 4|5
         SMBUS_READ_WORD,     c_pmbus_vdd0v72a_address, BMR466_READ_IOUT,              -- Result 6|7
         SMBUS_READ_WORD,     c_pmbus_vdd0v72a_address, BMR466_READ_TEMPERATURE_1,     -- Result 8|9

         SMBUS_READ_WORD,     c_pmbus_vdd0v72b_address, BMR466_STATUS_WORD,            -- Result 10|11
         SMBUS_READ_WORD,     c_pmbus_vdd0v72b_address, BMR466_READ_VIN,               -- Result 12|13
         SMBUS_READ_WORD,     c_pmbus_vdd0v72b_address, BMR466_READ_VOUT,              -- Result 14|15
         SMBUS_READ_WORD,     c_pmbus_vdd0v72b_address, BMR466_READ_IOUT,              -- Result 16|17
         SMBUS_READ_WORD,     c_pmbus_vdd0v72b_address, BMR466_READ_TEMPERATURE_1,     -- Result 18|19

         SMBUS_READ_WORD,     c_pmbus_vdd0v72c_address, BMR466_STATUS_WORD,            -- Result 20|21
         SMBUS_READ_WORD,     c_pmbus_vdd0v72c_address, BMR466_READ_VIN,               -- Result 22|23
         SMBUS_READ_WORD,     c_pmbus_vdd0v72c_address, BMR466_READ_VOUT,              -- Result 24|25
         SMBUS_READ_WORD,     c_pmbus_vdd0v72c_address, BMR466_READ_IOUT,              -- Result 26|27
         SMBUS_READ_WORD,     c_pmbus_vdd0v72c_address, BMR466_READ_TEMPERATURE_1,     -- Result 28|29

         SMBUS_WRITE_BYTE,    c_pmbus_vdd0v85_address, LTM4676_PAGE, 0,
         SMBUS_READ_WORD,     c_pmbus_vdd0v85_address, LTM4676_STATUS_WORD,            -- Result 30|31
         SMBUS_READ_WORD,     c_pmbus_vdd0v85_address, LTM4676_READ_VIN,               -- Result 32|33
         SMBUS_READ_WORD,     c_pmbus_vdd0v85_address, LTM4676_READ_VOUT,              -- Result 34|35
         SMBUS_READ_WORD,     c_pmbus_vdd0v85_address, LTM4676_READ_IOUT,              -- Result 36|37
         SMBUS_READ_WORD,     c_pmbus_vdd0v85_address, LTM4676_READ_TEMPERATURE_1,     -- Result 38|39
         SMBUS_READ_WORD,     c_pmbus_vdd0v85_address, LTM4676_READ_TEMPERATURE_2,     -- Result 40|41

         SMBUS_WRITE_BYTE,    c_pmbus_vdd0v9_address, LTM4676_PAGE, 1,
         SMBUS_READ_WORD,     c_pmbus_vdd0v9_address, LTM4676_STATUS_WORD,             -- Result 42|43
         SMBUS_READ_WORD,     c_pmbus_vdd0v9_address, LTM4676_READ_VIN,                -- Result 44|45
         SMBUS_READ_WORD,     c_pmbus_vdd0v9_address, LTM4676_READ_VOUT,               -- Result 46|47
         SMBUS_READ_WORD,     c_pmbus_vdd0v9_address, LTM4676_READ_IOUT,               -- Result 48|49
         SMBUS_READ_WORD,     c_pmbus_vdd0v9_address, LTM4676_READ_TEMPERATURE_1,      -- Result 50|51
         SMBUS_READ_WORD,     c_pmbus_vdd0v9_address, LTM4676_READ_TEMPERATURE_2,      -- Result 52|53

         SMBUS_WRITE_BYTE,    c_pmbus_vdd1v2_tr_address, LTM4676_PAGE, 0,
         SMBUS_READ_WORD,     c_pmbus_vdd1v2_tr_address, LTM4676_STATUS_WORD,          -- Result 54|55
         SMBUS_READ_WORD,     c_pmbus_vdd1v2_tr_address, LTM4676_READ_VIN,             -- Result 56|57
         SMBUS_READ_WORD,     c_pmbus_vdd1v2_tr_address, LTM4676_READ_VOUT,            -- Result 58|59
         SMBUS_READ_WORD,     c_pmbus_vdd1v2_tr_address, LTM4676_READ_IOUT,            -- Result 60|61
         SMBUS_READ_WORD,     c_pmbus_vdd1v2_tr_address, LTM4676_READ_TEMPERATURE_1,   -- Result 62|63
         SMBUS_READ_WORD,     c_pmbus_vdd1v2_tr_address, LTM4676_READ_TEMPERATURE_2,   -- Result 64|65

         SMBUS_WRITE_BYTE,    c_pmbus_vdd1v2_ddr_address, LTM4676_PAGE, 1,
         SMBUS_READ_WORD,     c_pmbus_vdd1v2_ddr_address, LTM4676_STATUS_WORD,         -- Result 66|67
         SMBUS_READ_WORD,     c_pmbus_vdd1v2_ddr_address, LTM4676_READ_VIN,            -- Result 68|69
         SMBUS_READ_WORD,     c_pmbus_vdd1v2_ddr_address, LTM4676_READ_VOUT,           -- Result 70|71
         SMBUS_READ_WORD,     c_pmbus_vdd1v2_ddr_address, LTM4676_READ_IOUT,           -- Result 72|73
         SMBUS_READ_WORD,     c_pmbus_vdd1v2_ddr_address, LTM4676_READ_TEMPERATURE_1,  -- Result 74|75
         SMBUS_READ_WORD,     c_pmbus_vdd1v2_ddr_address, LTM4676_READ_TEMPERATURE_2,  -- Result 76|77

         SMBUS_WRITE_BYTE,    c_pmbus_vdd1v8_address, LTM4676_PAGE, 0,
         SMBUS_READ_WORD,     c_pmbus_vdd1v8_address, LTM4676_STATUS_WORD,             -- Result 78|79
         SMBUS_READ_WORD,     c_pmbus_vdd1v8_address, LTM4676_READ_VIN,                -- Result 80|81
         SMBUS_READ_WORD,     c_pmbus_vdd1v8_address, LTM4676_READ_VOUT,               -- Result 82|83
         SMBUS_READ_WORD,     c_pmbus_vdd1v8_address, LTM4676_READ_IOUT,               -- Result 84|85
         SMBUS_READ_WORD,     c_pmbus_vdd1v8_address, LTM4676_READ_TEMPERATURE_1,      -- Result 86|87
         SMBUS_READ_WORD,     c_pmbus_vdd1v8_address, LTM4676_READ_TEMPERATURE_2,      -- Result 88|89

         SMBUS_WRITE_BYTE,    c_pmbus_vdd2v5_address, LTM4676_PAGE, 1,
         SMBUS_READ_WORD,     c_pmbus_vdd2v5_address, LTM4676_STATUS_WORD,             -- Result 90|91
         SMBUS_READ_WORD,     c_pmbus_vdd2v5_address, LTM4676_READ_VIN,                -- Result 92|93
         SMBUS_READ_WORD,     c_pmbus_vdd2v5_address, LTM4676_READ_VOUT,               -- Result 94|95
         SMBUS_READ_WORD,     c_pmbus_vdd2v5_address, LTM4676_READ_IOUT,               -- Result 96|97
         SMBUS_READ_WORD,     c_pmbus_vdd2v5_address, LTM4676_READ_TEMPERATURE_1,      -- Result 98|99
         SMBUS_READ_WORD,     c_pmbus_vdd2v5_address, LTM4676_READ_TEMPERATURE_2,      -- Result 100|101

         SMBUS_WRITE_BYTE,    c_pmbus_vdd3v3_address, LTM4676_PAGE, 0,
         SMBUS_READ_WORD,     c_pmbus_vdd3v3_address, LTM4676_STATUS_WORD,             -- Result 102|103
         SMBUS_READ_WORD,     c_pmbus_vdd3v3_address, LTM4676_READ_VIN,                -- Result 104|105
         SMBUS_READ_WORD,     c_pmbus_vdd3v3_address, LTM4676_READ_VOUT,               -- Result 106|107
         SMBUS_READ_WORD,     c_pmbus_vdd3v3_address, LTM4676_READ_IOUT,               -- Result 108|109
         SMBUS_READ_WORD,     c_pmbus_vdd3v3_address, LTM4676_READ_TEMPERATURE_1,      -- Result 110|111
         SMBUS_WRITE_BYTE,    c_pmbus_vdd3v3_address, LTM4676_PAGE, 1,
         SMBUS_READ_WORD,     c_pmbus_vdd3v3_address, LTM4676_READ_IOUT,               -- Result 112|113
         SMBUS_READ_WORD,     c_pmbus_vdd3v3_address, LTM4676_READ_TEMPERATURE_1,      -- Result 114|115
         SMBUS_READ_WORD,     c_pmbus_vdd3v3_address, LTM4676_READ_TEMPERATURE_2,      -- Result 116|117

         SMBUS_READ_WORD,     c_pmbus_vdd12v_address, BMR457_STATUS_WORD,              -- Result 118|119
         SMBUS_READ_WORD,     c_pmbus_vdd12v_address, BMR457_READ_VIN,                 -- Result 120|121
         SMBUS_READ_WORD,     c_pmbus_vdd12v_address, BMR457_READ_VOUT,                -- Result 122|123
         SMBUS_READ_WORD,     c_pmbus_vdd12v_address, BMR457_READ_IOUT,                -- Result 124|125
         SMBUS_READ_WORD,     c_pmbus_vdd12v_address, BMR457_READ_TEMPERATURE_1,       -- Result 126|127
         SMBUS_READ_WORD,     c_pmbus_vdd12v_address, BMR457_READ_TEMPERATURE_2,       -- Result 128|129

         SMBUS_C_END,
         SMBUS_C_NOP);

   CONSTANT c_clear_seq : t_nat_natural_arr := (
         SMBUS_SEND_BYTE,    c_pmbus_vdd0v72a_address,  BMR466_CLEAR_FAULTS,
         SMBUS_SEND_BYTE,    c_pmbus_vdd0v72b_address,  BMR466_CLEAR_FAULTS,
         SMBUS_SEND_BYTE,    c_pmbus_vdd0v72c_address,  BMR466_CLEAR_FAULTS,
         SMBUS_SEND_BYTE,    c_pmbus_vdd0v9_address,    LTM4676_CLEAR_FAULTS,
         SMBUS_SEND_BYTE,    c_pmbus_vdd1v2_tr_address, LTM4676_CLEAR_FAULTS,
         SMBUS_SEND_BYTE,    c_pmbus_vdd1v8_address,    LTM4676_CLEAR_FAULTS,
         SMBUS_SEND_BYTE,    c_pmbus_vdd3v3_address,    LTM4676_CLEAR_FAULTS,
         SMBUS_SEND_BYTE,    c_pmbus_vdd12v_address,    BMR457_CLEAR_FAULTS,
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
   SIGNAL clear_pending       : STD_LOGIC;
   SIGNAL program_pending     : STD_LOGIC;
   SIGNAL running             : STD_LOGIC;
   SIGNAL sequence_count      : NATURAL RANGE 0 TO 229;
   SIGNAL sequence_count_slv  : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL smbus_out_ack_dly   : STD_LOGIC;
   SIGNAL startup_counter     : UNSIGNED(c_startup_width-1 DOWNTO 0);
   SIGNAL i_rst               : STD_LOGIC;

   SIGNAL power_alert         : STD_LOGIC;
	SIGNAL control_fields_rw	: t_control_rw;
	SIGNAL control_fields_ro	: t_control_ro;
	SIGNAL control_program_in	: t_control_program_ram_in;
	SIGNAL control_program_out	: t_control_program_ram_out;
	SIGNAL control_results_in	: t_control_results_ram_in;
	SIGNAL vcc0v72_fields_ro	: t_vcc0V72_ro;
	SIGNAL vcc0v85_fields_ro	: t_vcc0v85_ro;
	SIGNAL vcc0v9_fields_ro    : t_vcc0v9_ro;
	SIGNAL vcc1v2_tr_fields_ro	: t_vcc1v2_tr_ro;
	SIGNAL vcc1v2_ddr_fields_ro: t_vcc1v2_ddr_ro;
	SIGNAL vcc1v8_fields_ro    : t_vcc1v8_ro;
	SIGNAL vcc2v5_fields_ro    : t_vcc2v5_ro;
	SIGNAL vcc3v3_fields_ro    : t_vcc3v3_ro;
	SIGNAL vcc12v_fields_ro    : t_vcc12v_ro;

   SIGNAL result_count        : UNSIGNED(7 DOWNTO 0);
   SIGNAL result_count_dly    : UNSIGNED(7 DOWNTO 0);
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

   ATTRIBUTE DONT_TOUCH                : STRING;
   ATTRIBUTE DONT_TOUCH OF i_rst       : SIGNAL IS "true";

BEGIN

   -- Done this way to avoid simulator warnings
   sequence_count_slv <= STD_LOGIC_VECTOR(TO_UNSIGNED(sequence_count, 8));

   io_reg: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         i_rst <= rst;
      END IF;
   END PROCESS;

---------------------------------------------------------------------------
-- Registers  --
---------------------------------------------------------------------------

regs: ENTITY work.gemini_lru_board_pmbus_reg
      GENERIC MAP (g_technology        => g_technology)
      PORT MAP (mm_clk                 => clk,
                mm_rst                 => i_rst,
                sla_in                 => s_axi_mosi,
                sla_out                => s_axi_miso,
                control_fields_rw      => control_fields_rw,
                control_fields_ro      => control_fields_ro,
                control_program_in     => control_program_in,
                control_program_out    => control_program_out,
                control_results_in     => control_results_in,
                control_results_out    => open,
                vcc0v72_fields_ro      => vcc0v72_fields_ro,
                vcc0v85_fields_ro      => vcc0v85_fields_ro,
                vcc0v9_fields_ro       => vcc0v9_fields_ro,
                vcc1v2_tr_fields_ro    => vcc1v2_tr_fields_ro,
                vcc1v2_ddr_fields_ro   => vcc1v2_ddr_fields_ro,
                vcc1v8_fields_ro       => vcc1v8_fields_ro,
                vcc2v5_fields_ro       => vcc2v5_fields_ro,
                vcc3v3_fields_ro       => vcc3v3_fields_ro,
                vcc12v_fields_ro       => vcc12v_fields_ro);

   control_fields_ro.status_error <= error_flag;
   control_fields_ro.status_prog_finished <= prog_finished;
   control_fields_ro.status_alert <= power_alert;
   control_fields_ro.status_idle <= '1' WHEN mode = s_idle ELSE '0';


   -- Setup RAMs for custom PROGRAM
   control_program_in.clk <= clk;
   control_program_in.rst <= i_rst;
   control_program_in.adr <= sequence_count_slv(4 DOWNTO 0);
   control_program_in.wr_dat <= (OTHERS => '0');
   control_program_in.wr_en <= '0';
   control_program_in.rd_en <= '1' WHEN mode = s_running_program else '0';

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
         power_alert <= NOT(power_alert_n);

         smbus_out_ack_dly <= smbus_out_ack;

         IF i_rst = '1' THEN
            mode <= s_startup_wait;
            prog_finished <= '0';
            error_flag <= '0';
            clear_pending <= '0';
            program_pending <= '0';
            running <= '0';
            startup_counter <= TO_UNSIGNED(c_startup_count, c_startup_width);
         ELSE
            error_flag <= error_flag OR smbus_out_err;
            clear_pending <= clear_pending OR control_fields_rw.control_clear_fault_flags;
            program_pending <= program_pending OR control_fields_rw.control_prog_execute;

            -- Clear finished flag when new command requested
            IF control_fields_rw.control_clear_fault_flags = '1' OR control_fields_rw.control_prog_execute = '1' THEN
               prog_finished <= '0';
            END IF;


            CASE mode IS
               -------------------------------
               WHEN s_idle =>
                  running <= '0';
                  sequence_count <= 0;
                  IF smbus_st_idle = '1' THEN
                     IF clear_pending = '1' THEN
                        mode <= s_running_clear;
                        error_flag <= '0';
                        clear_pending <= '0';
                     ELSIF program_pending = '1' THEN
                        mode <= s_running_program;
                        program_pending <= '0';
                        error_flag <= '0';
                     ELSE
                        IF control_fields_rw.control_monitor_enable = '1' THEN
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
               WHEN s_running_clear =>
                  running <= '1';
                  IF smbus_st_end = '1' THEN
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
                   STD_LOGIC_VECTOR(TO_UNSIGNED(c_clear_seq(sequence_count), c_byte_w)) WHEN mode = s_running_clear ELSE
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
               word_shift <= smbus_out_dat & word_shift(15 DOWNTO 8);
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
               WHEN 1 =>
                  vcc0v72_fields_ro.status_unknown(0) <= word_shift(0);
                  vcc0v72_fields_ro.status_comms(0) <= word_shift(1);
                  vcc0v72_fields_ro.status_temp(0) <= word_shift(2);
                  vcc0v72_fields_ro.status_undervolt(0) <= word_shift(3);
                  vcc0v72_fields_ro.status_overcurrent(0) <= word_shift(4);
                  vcc0v72_fields_ro.status_overvoltage(0) <= word_shift(5);
                  vcc0v72_fields_ro.status_off(0) <= word_shift(6);
                  vcc0v72_fields_ro.status_busy(0) <= word_shift(7);
                  vcc0v72_fields_ro.status_powergood(0) <= word_shift(11);
                  vcc0v72_fields_ro.status_manufacturer(0) <= word_shift(12);
                  vcc0v72_fields_ro.status_input(0) <= word_shift(13);
                  vcc0v72_fields_ro.status_power(0) <= word_shift(14);
                  vcc0v72_fields_ro.status_output(0) <= word_shift(15);
               WHEN 3 =>
                  vcc0v72_fields_ro.vin_mantissa(0) <= word_shift(10 DOWNTO 0);
                  vcc0v72_fields_ro.vin_exponent(0) <= word_shift(15 DOWNTO 11);
               WHEN 5 =>
                  vcc0v72_fields_ro.vout(0) <= word_shift;
               WHEN 7 =>
                  vcc0v72_fields_ro.iout_mantissa(0) <= word_shift(10 DOWNTO 0);
                  vcc0v72_fields_ro.iout_exponent(0) <= word_shift(15 DOWNTO 11);
               WHEN 9 =>
                  vcc0v72_fields_ro.temp_mantissa(0) <= word_shift(10 DOWNTO 0);
                  vcc0v72_fields_ro.temp_exponent(0) <= word_shift(15 DOWNTO 11);
               WHEN 11 =>
                  vcc0v72_fields_ro.status_unknown(1) <= word_shift(0);
                  vcc0v72_fields_ro.status_comms(1) <= word_shift(1);
                  vcc0v72_fields_ro.status_temp(1) <= word_shift(2);
                  vcc0v72_fields_ro.status_undervolt(1) <= word_shift(3);
                  vcc0v72_fields_ro.status_overcurrent(1) <= word_shift(4);
                  vcc0v72_fields_ro.status_overvoltage(1) <= word_shift(5);
                  vcc0v72_fields_ro.status_off(1) <= word_shift(6);
                  vcc0v72_fields_ro.status_busy(1) <= word_shift(7);
                  vcc0v72_fields_ro.status_powergood(1) <= word_shift(11);
                  vcc0v72_fields_ro.status_manufacturer(1) <= word_shift(12);
                  vcc0v72_fields_ro.status_input(1) <= word_shift(13);
                  vcc0v72_fields_ro.status_power(1) <= word_shift(14);
                  vcc0v72_fields_ro.status_output(1) <= word_shift(15);
               WHEN 13 =>
                  vcc0v72_fields_ro.vin_mantissa(1) <= word_shift(10 DOWNTO 0);
                  vcc0v72_fields_ro.vin_exponent(1) <= word_shift(15 DOWNTO 11);
               WHEN 15 =>
                  vcc0v72_fields_ro.vout(1) <= word_shift;
               WHEN 17 =>
                  vcc0v72_fields_ro.iout_mantissa(1) <= word_shift(10 DOWNTO 0);
                  vcc0v72_fields_ro.iout_exponent(1) <= word_shift(15 DOWNTO 11);
               WHEN 19 =>
                  vcc0v72_fields_ro.temp_mantissa(1) <= word_shift(10 DOWNTO 0);
                  vcc0v72_fields_ro.temp_exponent(1) <= word_shift(15 DOWNTO 11);
               WHEN 21 =>
                  vcc0v72_fields_ro.status_unknown(2) <= word_shift(0);
                  vcc0v72_fields_ro.status_comms(2) <= word_shift(1);
                  vcc0v72_fields_ro.status_temp(2) <= word_shift(2);
                  vcc0v72_fields_ro.status_undervolt(2) <= word_shift(3);
                  vcc0v72_fields_ro.status_overcurrent(2) <= word_shift(4);
                  vcc0v72_fields_ro.status_overvoltage(2) <= word_shift(5);
                  vcc0v72_fields_ro.status_off(2) <= word_shift(6);
                  vcc0v72_fields_ro.status_busy(2) <= word_shift(7);
                  vcc0v72_fields_ro.status_powergood(2) <= word_shift(11);
                  vcc0v72_fields_ro.status_manufacturer(2) <= word_shift(12);
                  vcc0v72_fields_ro.status_input(2) <= word_shift(13);
                  vcc0v72_fields_ro.status_power(2) <= word_shift(14);
                  vcc0v72_fields_ro.status_output(2) <= word_shift(15);
               WHEN 23 =>
                  vcc0v72_fields_ro.vin_mantissa(2) <= word_shift(10 DOWNTO 0);
                  vcc0v72_fields_ro.vin_exponent(2) <= word_shift(15 DOWNTO 11);
               WHEN 25 =>
                  vcc0v72_fields_ro.vout(2) <= word_shift;
               WHEN 27 =>
                  vcc0v72_fields_ro.iout_mantissa(2) <= word_shift(10 DOWNTO 0);
                  vcc0v72_fields_ro.iout_exponent(2) <= word_shift(15 DOWNTO 11);
               WHEN 29 =>
                  vcc0v72_fields_ro.temp_mantissa(2) <= word_shift(10 DOWNTO 0);
                  vcc0v72_fields_ro.temp_exponent(2) <= word_shift(15 DOWNTO 11);
               WHEN 31 =>
                  vcc0v85_fields_ro.status_toff_max_warn <= word_shift(1);
                  vcc0v85_fields_ro.status_ton_max_warn <= word_shift(2);
                  vcc0v85_fields_ro.status_vout_max_warn <= word_shift(3);
                  vcc0v85_fields_ro.status_undervolt_fault <= word_shift(4);
                  vcc0v85_fields_ro.status_undervolt_warn <= word_shift(5);
                  vcc0v85_fields_ro.status_overvoltage_warn <= word_shift(6);
                  vcc0v85_fields_ro.status_overvoltage_fault <= word_shift(7);
                  vcc0v85_fields_ro.status_powergood <= word_shift(11);
                  vcc0v85_fields_ro.status_manufacturer <= word_shift(12);
                  vcc0v85_fields_ro.status_input <= word_shift(13);
                  vcc0v85_fields_ro.status_output_iout <= word_shift(14);
                  vcc0v85_fields_ro.status_output_vout <= word_shift(15);
               WHEN 33 =>
                  vcc0v85_fields_ro.vin_mantissa <= word_shift(10 DOWNTO 0);
                  vcc0v85_fields_ro.vin_exponent <= word_shift(15 DOWNTO 11);
               WHEN 35 =>
                  vcc0v85_fields_ro.vout <= word_shift;
               WHEN 37 =>
                  vcc0v85_fields_ro.iout_mantissa <= word_shift(10 DOWNTO 0);
                  vcc0v85_fields_ro.iout_exponent <= word_shift(15 DOWNTO 11);
               WHEN 39 =>
                  vcc0v85_fields_ro.temp_mantissa <= word_shift(10 DOWNTO 0);
                  vcc0v85_fields_ro.temp_exponent <= word_shift(15 DOWNTO 11);
               WHEN 41 =>
                  vcc0v85_fields_ro.temp_int_mantissa <= word_shift(10 DOWNTO 0);
                  vcc0v85_fields_ro.temp_int_exponent <= word_shift(15 DOWNTO 11);
               WHEN 43 =>
                  vcc0v9_fields_ro.status_toff_max_warn <= word_shift(1);
                  vcc0v9_fields_ro.status_ton_max_warn <= word_shift(2);
                  vcc0v9_fields_ro.status_vout_max_warn <= word_shift(3);
                  vcc0v9_fields_ro.status_undervolt_fault <= word_shift(4);
                  vcc0v9_fields_ro.status_undervolt_warn <= word_shift(5);
                  vcc0v9_fields_ro.status_overvoltage_warn <= word_shift(6);
                  vcc0v9_fields_ro.status_overvoltage_fault <= word_shift(7);
                  vcc0v9_fields_ro.status_powergood <= word_shift(11);
                  vcc0v9_fields_ro.status_manufacturer <= word_shift(12);
                  vcc0v9_fields_ro.status_input <= word_shift(13);
                  vcc0v9_fields_ro.status_output_iout <= word_shift(14);
                  vcc0v9_fields_ro.status_output_vout <= word_shift(15);
               WHEN 45 =>
                  vcc0v9_fields_ro.vin_mantissa <= word_shift(10 DOWNTO 0);
                  vcc0v9_fields_ro.vin_exponent <= word_shift(15 DOWNTO 11);
               WHEN 47 =>
                  vcc0v9_fields_ro.vout <= word_shift;
               WHEN 49 =>
                  vcc0v9_fields_ro.iout_mantissa <= word_shift(10 DOWNTO 0);
                  vcc0v9_fields_ro.iout_exponent <= word_shift(15 DOWNTO 11);
               WHEN 51 =>
                  vcc0v9_fields_ro.temp_mantissa <= word_shift(10 DOWNTO 0);
                  vcc0v9_fields_ro.temp_exponent <= word_shift(15 DOWNTO 11);
               WHEN 53 =>
                  vcc0v9_fields_ro.temp_int_mantissa <= word_shift(10 DOWNTO 0);
                  vcc0v9_fields_ro.temp_int_exponent <= word_shift(15 DOWNTO 11);
               WHEN 55 =>
                  vcc1v2_tr_fields_ro.status_toff_max_warn <= word_shift(1);
                  vcc1v2_tr_fields_ro.status_ton_max_warn <= word_shift(2);
                  vcc1v2_tr_fields_ro.status_vout_max_warn <= word_shift(3);
                  vcc1v2_tr_fields_ro.status_undervolt_fault <= word_shift(4);
                  vcc1v2_tr_fields_ro.status_undervolt_warn <= word_shift(5);
                  vcc1v2_tr_fields_ro.status_overvoltage_warn <= word_shift(6);
                  vcc1v2_tr_fields_ro.status_overvoltage_fault <= word_shift(7);
                  vcc1v2_tr_fields_ro.status_powergood <= word_shift(11);
                  vcc1v2_tr_fields_ro.status_manufacturer <= word_shift(12);
                  vcc1v2_tr_fields_ro.status_input <= word_shift(13);
                  vcc1v2_tr_fields_ro.status_output_iout <= word_shift(14);
                  vcc1v2_tr_fields_ro.status_output_vout <= word_shift(15);
               WHEN 57 =>
                  vcc1v2_tr_fields_ro.vin_mantissa <= word_shift(10 DOWNTO 0);
                  vcc1v2_tr_fields_ro.vin_exponent <= word_shift(15 DOWNTO 11);
               WHEN 59 =>
                  vcc1v2_tr_fields_ro.vout <= word_shift;
               WHEN 61 =>
                  vcc1v2_tr_fields_ro.iout_mantissa <= word_shift(10 DOWNTO 0);
                  vcc1v2_tr_fields_ro.iout_exponent <= word_shift(15 DOWNTO 11);
               WHEN 63 =>
                  vcc1v2_tr_fields_ro.temp_mantissa <= word_shift(10 DOWNTO 0);
                  vcc1v2_tr_fields_ro.temp_exponent <= word_shift(15 DOWNTO 11);
               WHEN 65 =>
                  vcc1v2_tr_fields_ro.temp_int_mantissa <= word_shift(10 DOWNTO 0);
                  vcc1v2_tr_fields_ro.temp_int_exponent <= word_shift(15 DOWNTO 11);
               WHEN 67 =>
                  vcc1v2_ddr_fields_ro.status_toff_max_warn <= word_shift(1);
                  vcc1v2_ddr_fields_ro.status_ton_max_warn <= word_shift(2);
                  vcc1v2_ddr_fields_ro.status_vout_max_warn <= word_shift(3);
                  vcc1v2_ddr_fields_ro.status_undervolt_fault <= word_shift(4);
                  vcc1v2_ddr_fields_ro.status_undervolt_warn <= word_shift(5);
                  vcc1v2_ddr_fields_ro.status_overvoltage_warn <= word_shift(6);
                  vcc1v2_ddr_fields_ro.status_overvoltage_fault <= word_shift(7);
                  vcc1v2_ddr_fields_ro.status_powergood <= word_shift(11);
                  vcc1v2_ddr_fields_ro.status_manufacturer <= word_shift(12);
                  vcc1v2_ddr_fields_ro.status_input <= word_shift(13);
                  vcc1v2_ddr_fields_ro.status_output_iout <= word_shift(14);
                  vcc1v2_ddr_fields_ro.status_output_vout <= word_shift(15);
               WHEN 69 =>
                  vcc1v2_ddr_fields_ro.vin_mantissa <= word_shift(10 DOWNTO 0);
                  vcc1v2_ddr_fields_ro.vin_exponent <= word_shift(15 DOWNTO 11);
               WHEN 71 =>
                  vcc1v2_ddr_fields_ro.vout <= word_shift;
               WHEN 73 =>
                  vcc1v2_ddr_fields_ro.iout_mantissa <= word_shift(10 DOWNTO 0);
                  vcc1v2_ddr_fields_ro.iout_exponent <= word_shift(15 DOWNTO 11);
               WHEN 75 =>
                  vcc1v2_ddr_fields_ro.temp_mantissa <= word_shift(10 DOWNTO 0);
                  vcc1v2_ddr_fields_ro.temp_exponent <= word_shift(15 DOWNTO 11);
               WHEN 77 =>
                  vcc1v2_ddr_fields_ro.temp_int_mantissa <= word_shift(10 DOWNTO 0);
                  vcc1v2_ddr_fields_ro.temp_int_exponent <= word_shift(15 DOWNTO 11);
               WHEN 79 =>
                  vcc1v8_fields_ro.status_toff_max_warn <= word_shift(1);
                  vcc1v8_fields_ro.status_ton_max_warn <= word_shift(2);
                  vcc1v8_fields_ro.status_vout_max_warn <= word_shift(3);
                  vcc1v8_fields_ro.status_undervolt_fault <= word_shift(4);
                  vcc1v8_fields_ro.status_undervolt_warn <= word_shift(5);
                  vcc1v8_fields_ro.status_overvoltage_warn <= word_shift(6);
                  vcc1v8_fields_ro.status_overvoltage_fault <= word_shift(7);
                  vcc1v8_fields_ro.status_powergood <= word_shift(11);
                  vcc1v8_fields_ro.status_manufacturer <= word_shift(12);
                  vcc1v8_fields_ro.status_input <= word_shift(13);
                  vcc1v8_fields_ro.status_output_iout <= word_shift(14);
                  vcc1v8_fields_ro.status_output_vout <= word_shift(15);
               WHEN 81 =>
                  vcc1v8_fields_ro.vin_mantissa <= word_shift(10 DOWNTO 0);
                  vcc1v8_fields_ro.vin_exponent <= word_shift(15 DOWNTO 11);
               WHEN 83 =>
                  vcc1v8_fields_ro.vout <= word_shift;
               WHEN 85 =>
                  vcc1v8_fields_ro.iout_mantissa <= word_shift(10 DOWNTO 0);
                  vcc1v8_fields_ro.iout_exponent <= word_shift(15 DOWNTO 11);
               WHEN 87 =>
                  vcc1v8_fields_ro.temp_mantissa <= word_shift(10 DOWNTO 0);
                  vcc1v8_fields_ro.temp_exponent <= word_shift(15 DOWNTO 11);
               WHEN 89 =>
                  vcc1v8_fields_ro.temp_int_mantissa <= word_shift(10 DOWNTO 0);
                  vcc1v8_fields_ro.temp_int_exponent <= word_shift(15 DOWNTO 11);
               WHEN 91 =>
                  vcc2v5_fields_ro.status_toff_max_warn <= word_shift(1);
                  vcc2v5_fields_ro.status_ton_max_warn <= word_shift(2);
                  vcc2v5_fields_ro.status_vout_max_warn <= word_shift(3);
                  vcc2v5_fields_ro.status_undervolt_fault <= word_shift(4);
                  vcc2v5_fields_ro.status_undervolt_warn <= word_shift(5);
                  vcc2v5_fields_ro.status_overvoltage_warn <= word_shift(6);
                  vcc2v5_fields_ro.status_overvoltage_fault <= word_shift(7);
                  vcc2v5_fields_ro.status_powergood <= word_shift(11);
                  vcc2v5_fields_ro.status_manufacturer <= word_shift(12);
                  vcc2v5_fields_ro.status_input <= word_shift(13);
                  vcc2v5_fields_ro.status_output_iout <= word_shift(14);
                  vcc2v5_fields_ro.status_output_vout <= word_shift(15);
               WHEN 93 =>
                  vcc2v5_fields_ro.vin_mantissa <= word_shift(10 DOWNTO 0);
                  vcc2v5_fields_ro.vin_exponent <= word_shift(15 DOWNTO 11);
               WHEN 95 =>
                  vcc2v5_fields_ro.vout <= word_shift;
               WHEN 97 =>
                  vcc2v5_fields_ro.iout_mantissa <= word_shift(10 DOWNTO 0);
                  vcc2v5_fields_ro.iout_exponent <= word_shift(15 DOWNTO 11);
               WHEN 99 =>
                  vcc2v5_fields_ro.temp_mantissa <= word_shift(10 DOWNTO 0);
                  vcc2v5_fields_ro.temp_exponent <= word_shift(15 DOWNTO 11);
               WHEN 101 =>
                  vcc2v5_fields_ro.temp_int_mantissa <= word_shift(10 DOWNTO 0);
                  vcc2v5_fields_ro.temp_int_exponent <= word_shift(15 DOWNTO 11);
               WHEN 103 =>
                  vcc3v3_fields_ro.status_toff_max_warn <= word_shift(1);
                  vcc3v3_fields_ro.status_ton_max_warn <= word_shift(2);
                  vcc3v3_fields_ro.status_vout_max_warn <= word_shift(3);
                  vcc3v3_fields_ro.status_undervolt_fault <= word_shift(4);
                  vcc3v3_fields_ro.status_undervolt_warn <= word_shift(5);
                  vcc3v3_fields_ro.status_overvoltage_warn <= word_shift(6);
                  vcc3v3_fields_ro.status_overvoltage_fault <= word_shift(7);
                  vcc3v3_fields_ro.status_powergood <= word_shift(11);
                  vcc3v3_fields_ro.status_manufacturer <= word_shift(12);
                  vcc3v3_fields_ro.status_input <= word_shift(13);
                  vcc3v3_fields_ro.status_output_iout <= word_shift(14);
                  vcc3v3_fields_ro.status_output_vout <= word_shift(15);
               WHEN 105 =>
                  vcc3v3_fields_ro.vin_mantissa <= word_shift(10 DOWNTO 0);
                  vcc3v3_fields_ro.vin_exponent <= word_shift(15 DOWNTO 11);
               WHEN 107 =>
                  vcc3v3_fields_ro.vout <= word_shift;
               WHEN 109 =>
                  vcc3v3_fields_ro.iout_a_mantissa <= word_shift(10 DOWNTO 0);
                  vcc3v3_fields_ro.iout_a_exponent <= word_shift(15 DOWNTO 11);
               WHEN 111 =>
                  vcc3v3_fields_ro.temp_a_mantissa <= word_shift(10 DOWNTO 0);
                  vcc3v3_fields_ro.temp_a_exponent <= word_shift(15 DOWNTO 11);
               WHEN 113 =>
                  vcc3v3_fields_ro.iout_b_mantissa <= word_shift(10 DOWNTO 0);
                  vcc3v3_fields_ro.iout_b_exponent <= word_shift(15 DOWNTO 11);
               WHEN 115 =>
                  vcc3v3_fields_ro.temp_b_mantissa <= word_shift(10 DOWNTO 0);
                  vcc3v3_fields_ro.temp_b_exponent <= word_shift(15 DOWNTO 11);
               WHEN 117 =>
                  vcc3v3_fields_ro.temp_int_mantissa <= word_shift(10 DOWNTO 0);
                  vcc3v3_fields_ro.temp_int_exponent <= word_shift(15 DOWNTO 11);
               WHEN 119 =>
                  vcc12v_fields_ro.status_unknown <= word_shift(0);
                  vcc12v_fields_ro.status_comms <= word_shift(1);
                  vcc12v_fields_ro.status_temp <= word_shift(2);
                  vcc12v_fields_ro.status_undervolt <= word_shift(3);
                  vcc12v_fields_ro.status_overcurrent <= word_shift(4);
                  vcc12v_fields_ro.status_overvoltage <= word_shift(5);
                  vcc12v_fields_ro.status_off <= word_shift(6);
                  vcc12v_fields_ro.status_busy <= word_shift(7);
                  vcc12v_fields_ro.status_powergood <= word_shift(11);
                  vcc12v_fields_ro.status_manufacturer <= word_shift(12);
                  vcc12v_fields_ro.status_input <= word_shift(13);
                  vcc12v_fields_ro.status_power <= word_shift(14);
                  vcc12v_fields_ro.status_output <= word_shift(15);
               WHEN 121 =>
                  vcc12v_fields_ro.vin_mantissa <= word_shift(10 DOWNTO 0);
                  vcc12v_fields_ro.vin_exponent <= word_shift(15 DOWNTO 11);
               WHEN 123 =>
                  vcc12v_fields_ro.vout <= word_shift;
               WHEN 125 =>
                  vcc12v_fields_ro.iout_mantissa <= word_shift(10 DOWNTO 0);
                  vcc12v_fields_ro.iout_exponent <= word_shift(15 DOWNTO 11);
               WHEN 127 =>
                  vcc12v_fields_ro.temp_mantissa <= word_shift(10 DOWNTO 0);
                  vcc12v_fields_ro.temp_exponent <= word_shift(15 DOWNTO 11);
               WHEN 129 =>
                  vcc12v_fields_ro.temp_int <= word_shift;
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
                   scl           => power_sdc,
                   sda           => power_sda);








END rtl;
