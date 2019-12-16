-------------------------------------------------------------------------------
--
-- File Name: humidity_control.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Tuesday Nov 21 10:50:00 2017
-- Template Rev: 1.0
--
-- Title: M&C support for Si7020
--
-- Description: Provides the register level interface for the Humidity components
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
USE i2c_lib.i2c_dev_si7020_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE work.i2c_addresses_pkg.ALL;
USE work.gemini_xh_lru_board_humidity_reg_pkg.ALL;


-------------------------------------------------------------------------------
ENTITY humidity_control IS
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
      hum_sda           : INOUT STD_LOGIC;                        -- OC drive, internal Pullups
      hum_scl           : INOUT STD_LOGIC);                       -- LVCMOS 1.8V
END humidity_control;


ARCHITECTURE rtl OF humidity_control IS

  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   TYPE fsm_states IS (s_idle, s_startup_wait, s_startup, s_running_monitor, s_running_program);


   CONSTANT c_monitor_seq : t_nat_natural_arr := (
     -- |    Command                |   Parameters
         SMBUS_C_DELAYED_READ_WORD,   c_hum_address, SI7020_MES_HUMIDITY_HOLD, 16#16#, 16#D6#, 16#36#, 16#00#,   -- Result 0|1
         SMBUS_READ_WORD,             c_hum_address, SI7020_READ_TEMP_OLD,                                          -- Result 2|3

         SMBUS_C_END,
         SMBUS_C_NOP);

   CONSTANT c_i2c_phy   : t_c_i2c_phy := (clk_cnt => g_clk_rate/(5*g_i2c_rate)-1,
                                          comma_w => 0);

   CONSTANT c_startup_width   : INTEGER := ceil_log2(g_clk_rate/1000 * g_startup_time);
   CONSTANT c_startup_count   : INTEGER := (g_clk_rate/1000 * g_startup_time) -1;

   ---------------------------------------------------------------------------
   -- SIGNAL DECLARATIONS  --
   ---------------------------------------------------------------------------

   SIGNAL mode                   : fsm_states;
   SIGNAL prog_finished          : STD_LOGIC;
   SIGNAL error_flag             : STD_LOGIC;
   SIGNAL program_pending        : STD_LOGIC;
   SIGNAL running                : STD_LOGIC;
   SIGNAL sequence_count         : NATURAL RANGE 0 TO 31;
   SIGNAL smbus_out_ack_dly      : STD_LOGIC;
   SIGNAL startup_counter        : UNSIGNED(c_startup_width-1 DOWNTO 0);
   SIGNAL i_rst                  : STD_LOGIC;

   SIGNAL humidity_fields_rw     : t_humidity_rw;
   SIGNAL humidity_fields_ro     : t_humidity_ro;
   SIGNAL humidity_program_in    : t_humidity_program_ram_in;
   SIGNAL humidity_program_out   : t_humidity_program_ram_out;
   SIGNAL humidity_results_in    : t_humidity_results_ram_in;

   SIGNAL result_count           : UNSIGNED(4 DOWNTO 0);
   SIGNAL result_count_dly       : UNSIGNED(4 DOWNTO 0);
   SIGNAL word_shift             : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL smbus_out_val_dly      : STD_LOGIC;


   -- I2c Core
   SIGNAL smbus_out_dat          : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL smbus_in_dat           : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL smbus_in_req           : STD_LOGIC;
   SIGNAL smbus_out_val          : STD_LOGIC;
   SIGNAL smbus_out_err          : STD_LOGIC;
   SIGNAL smbus_out_ack          : STD_LOGIC;
   SIGNAL smbus_st_idle          : STD_LOGIC;
   SIGNAL smbus_st_end           : STD_LOGIC;

   ---------------------------------------------------------------------------
   -- ATTRIBUTES  --
   ---------------------------------------------------------------------------

   ATTRIBUTE DONT_TOUCH                : STRING;
   ATTRIBUTE DONT_TOUCH OF i_rst       : SIGNAL IS "true";

BEGIN

   io_reg: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         i_rst <= rst;
      END IF;
   END PROCESS;


---------------------------------------------------------------------------
-- Registers  --
---------------------------------------------------------------------------

regs: ENTITY work.gemini_xh_lru_board_humidity_reg
      GENERIC MAP (g_technology        => g_technology)
      PORT MAP (mm_clk                 => clk,
                mm_rst                 => i_rst,
                sla_in                 => s_axi_mosi,
                sla_out                => s_axi_miso,
                humidity_fields_rw    => humidity_fields_rw,
                humidity_fields_ro    => humidity_fields_ro,
                humidity_program_in   => humidity_program_in,
                humidity_program_out  => humidity_program_out,
                humidity_results_in   => humidity_results_in,
                humidity_results_out  => OPEN);

   humidity_fields_ro.status_error <= error_flag;
   humidity_fields_ro.status_prog_finished <= prog_finished;
   humidity_fields_ro.status_idle <= '1' WHEN mode = s_idle ELSE '0';

   -- Setup RAMs for custom PROGRAM
   humidity_program_in.clk <= clk;
   humidity_program_in.rst <= i_rst;
   humidity_program_in.adr <= STD_LOGIC_VECTOR(TO_UNSIGNED(sequence_count, 5));
   humidity_program_in.wr_dat <= (OTHERS => '0');
   humidity_program_in.wr_en <= '0';
   humidity_program_in.rd_en <= '1' WHEN mode = s_running_program else '0';

   -- Program Results
   humidity_results_in.clk <= clk;
   humidity_results_in.rst <= i_rst;
   humidity_results_in.rd_en <= '0';
   humidity_results_in.adr <= STD_LOGIC_VECTOR(result_count(4 DOWNTO 0));
   humidity_results_in.wr_dat <= smbus_out_dat;
   humidity_results_in.wr_en <= smbus_out_val WHEN mode = s_running_program else '0';

---------------------------------------------------------------------------
-- High Level Controller  --
---------------------------------------------------------------------------
-- There is one stored programs that can be run, the standard monitoring loop.
-- There is also a programmable mode that allows for arbitary programs to be
-- uploaded through the registers and execute with the results stored in a RAM
-- that can be downloaded

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
            program_pending <= program_pending OR humidity_fields_rw.control_prog_execute;

            -- Clear finished flag when new command requested
            IF humidity_fields_rw.control_prog_execute = '1' THEN
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
                        IF humidity_fields_rw.control_monitor_enable = '1' THEN
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
                   humidity_program_out.rd_dat;

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
               WHEN 1 =>
                  humidity_fields_ro.humidity <= word_shift;
               WHEN 3 =>
                  humidity_fields_ro.temperature <= word_shift;
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
                   scl           => hum_scl,
                   sda           => hum_sda);

END rtl;
