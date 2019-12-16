-------------------------------------------------------------------------------
--
-- File Name: backplane_control.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Tuesday Nov 21 10:50:00 2017
-- Template Rev: 1.0
--
-- Title: M&C support for PCA9555
--
-- Description: Provides the register level interface for the backplane GPIO
--              expander (PCA9555) thats used for power control. All LRU cards
--              have access to the backplane. Theer are protection sin the i2c
--              core to limit concurrent communications from cards, however higher
--              level control mechanism should be employed to ensure only 1 card
--              communicates.
--
--              When a card is disabled through the regsiter interface the
--              associated GPIO conyrtol pin is set to an output and set to 0
--              to turn off the card. The GPIO IO state and outpu level are
--              modified using RMW cycles with the outptu state modified first
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
USE i2c_lib.i2c_dev_pca9555_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE work.i2c_addresses_pkg.ALL;
USE work.gemini_lru_board_backplane_control_reg_pkg.ALL;

-------------------------------------------------------------------------------
ENTITY backplane_control IS
   GENERIC (
      g_technology      : t_technology := c_tech_select_default;
      g_clk_rate        : INTEGER := 156250000;                   -- Clk rate in HZ
      g_i2c_rate        : INTEGER := 50000;                       -- i2c clock rate in HZ
      g_pulse_time      : INTEGER := 100;                         -- Reset pulse length in ms
      g_startup_time    : INTEGER := 50);                         -- Startup time in mS

   PORT (
      rst               : IN  STD_LOGIC;
      clk               : IN  STD_LOGIC;

      --AXI Interface
      s_axi_mosi        : IN t_axi4_lite_mosi;
      s_axi_miso        : OUT t_axi4_lite_miso;

      -- Physical Interfaces
      bp_sda           : INOUT STD_LOGIC;                        -- OC drive, internal Pullups
      bp_scl           : INOUT STD_LOGIC);                       -- LVCMOS 1.8V
END backplane_control;


ARCHITECTURE rtl OF backplane_control IS

  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   TYPE fsm_states IS (s_idle, s_startup_wait, s_startup, s_run_power_update, s_running_program, s_wait_bus_finished);

   CONSTANT c_i2c_phy   : t_c_i2c_phy := (clk_cnt => g_clk_rate/(5*g_i2c_rate)-1,
                                          comma_w => 0);

   CONSTANT c_startup_width   : INTEGER := ceil_log2(g_clk_rate/1000 * g_startup_time);
   CONSTANT c_startup_count   : INTEGER := (g_clk_rate/1000 * g_startup_time) -1;

   CONSTANT c_pulse_count     : UNSIGNED(31 DOWNTO 0) := TO_UNSIGNED(INTEGER((g_clk_rate/1000 * g_pulse_time) -1), 32);

   -- Executes RMW cycles on port data registers, config registers are just configured
   CONSTANT c_set_port_seq : t_nat_natural_arr := (
     -- |    Command         |   Parameters
         SMBUS_WRITE_WORD,     c_bp_gpio_address, PCA9555_REG_CONFIG0, 16#3F#, 16#3F#,  -- Overridden by selected ports to be reset

         SMBUS_READ_WORD,      c_bp_gpio_address, PCA9555_REG_OUTPUT0,
         SMBUS_WRITE_WORD,     c_bp_gpio_address, PCA9555_REG_OUTPUT0, 16#00#, 16#00#,  -- Need to make sure the LED status is copied across so RMW

         SMBUS_C_WAIT,         TO_INTEGER(c_pulse_count(7 DOWNTO 0)), TO_INTEGER(c_pulse_count(15 DOWNTO 8)), TO_INTEGER(c_pulse_count(23 DOWNTO 16)), TO_INTEGER(c_pulse_count(31 DOWNTO 24)),                          -- Wait for about 0.1sec (assuming 156.25MHz)

         SMBUS_WRITE_WORD,     c_bp_gpio_address, PCA9555_REG_CONFIG0, 16#3F#, 16#3F#,

         SMBUS_C_END,
         SMBUS_C_NOP);

   ---------------------------------------------------------------------------
   -- SIGNAL DECLARATIONS  --
   ---------------------------------------------------------------------------

   SIGNAL mode                            : fsm_states;
   SIGNAL prog_finished                   : STD_LOGIC;
   SIGNAL error_flag                      : STD_LOGIC;
   SIGNAL program_pending                 : STD_LOGIC;
   SIGNAL running                         : STD_LOGIC;
   SIGNAL sequence_count                  : NATURAL RANGE 0 TO 31;
   SIGNAL smbus_out_ack_dly               : STD_LOGIC;
   SIGNAL startup_counter                 : UNSIGNED(c_startup_width-1 DOWNTO 0);
   SIGNAL power_reset                     : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL update_leds                     : STD_LOGIC;

   SIGNAL backplane_control_fields_rw     : t_backplane_control_rw;
   SIGNAL backplane_control_fields_ro     : t_backplane_control_ro;
   SIGNAL backplane_control_program_in    : t_backplane_control_program_ram_in;
   SIGNAL backplane_control_program_out   : t_backplane_control_program_ram_out;
   SIGNAL backplane_control_results_in    : t_backplane_control_results_ram_in;

   SIGNAL result_count                    : UNSIGNED(4 DOWNTO 0);
   SIGNAL word_shift                      : STD_LOGIC_VECTOR(15 DOWNTO 0);


   -- I2c Core
   SIGNAL smbus_out_dat                   : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL smbus_in_dat                    : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL smbus_in_req                    : STD_LOGIC;
   SIGNAL smbus_out_val                   : STD_LOGIC;
   SIGNAL smbus_out_err                   : STD_LOGIC;
   SIGNAL smbus_out_ack                   : STD_LOGIC;
   SIGNAL smbus_st_idle                   : STD_LOGIC;
   SIGNAL smbus_st_end                    : STD_LOGIC;
   SIGNAL smbus_out_busy                  : STD_LOGIC;
   SIGNAL smbus_out_al                    : STD_LOGIC;

BEGIN


---------------------------------------------------------------------------
-- Registers  --
---------------------------------------------------------------------------

regs: ENTITY work.gemini_lru_board_backplane_control_reg
      GENERIC MAP (g_technology        => g_technology)
      PORT MAP (mm_clk                 => clk,
                mm_rst                 => rst,
                sla_in                 => s_axi_mosi,
                sla_out                => s_axi_miso,
                backplane_control_fields_rw    => backplane_control_fields_rw,
                backplane_control_fields_ro    => backplane_control_fields_ro,
                backplane_control_program_in   => backplane_control_program_in,
                backplane_control_program_out  => backplane_control_program_out,
                backplane_control_results_in   => backplane_control_results_in,
                backplane_control_results_out  => OPEN);

   backplane_control_fields_ro.status_error <= error_flag;
   backplane_control_fields_ro.status_prog_finished <= prog_finished;
   backplane_control_fields_ro.status_idle <= '1' WHEN mode = s_idle ELSE '0';

   -- Setup RAMs for custom PROGRAM
   backplane_control_program_in.clk <= clk;
   backplane_control_program_in.rst <= rst;
   backplane_control_program_in.adr <= STD_LOGIC_VECTOR(TO_UNSIGNED(sequence_count, 5));
   backplane_control_program_in.wr_dat <= (OTHERS => '0');
   backplane_control_program_in.wr_en <= '0';
   backplane_control_program_in.rd_en <= '1' WHEN mode = s_running_program else '0';

   -- Program Results
   backplane_control_results_in.clk <= clk;
   backplane_control_results_in.rst <= rst;
   backplane_control_results_in.rd_en <= '0';
   backplane_control_results_in.adr <= STD_LOGIC_VECTOR(result_count(4 DOWNTO 0));
   backplane_control_results_in.wr_dat <= smbus_out_dat;
   backplane_control_results_in.wr_en <= smbus_out_val WHEN mode = s_running_program else '0';

---------------------------------------------------------------------------
-- High Level Controller  --
---------------------------------------------------------------------------
-- Sits in idle until the power disabled state is changed

control_fsm: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         smbus_out_ack_dly <= smbus_out_ack;

         IF rst = '1' THEN
            mode <= s_startup_wait;
            prog_finished <= '0';
            error_flag <= '0';
            program_pending <= '0';
            running <= '0';
            startup_counter <= TO_UNSIGNED(c_startup_count, c_startup_width);
            power_reset <= (OTHERS => '0');
            update_leds <= '0';
         ELSE
            error_flag <= error_flag OR smbus_out_err OR smbus_out_al;
            program_pending <= program_pending OR backplane_control_fields_rw.control_prog_execute;
            power_reset <= power_reset OR backplane_control_fields_rw.power_reset;

            update_leds <= update_leds OR backplane_control_fields_rw.control_update_leds;

            -- Clear finished flag when new command requested
            IF backplane_control_fields_rw.control_prog_execute = '1' THEN
               prog_finished <= '0';
            END IF;


            CASE mode IS
               -------------------------------
               WHEN s_idle =>
                  running <= '0';
                  sequence_count <= 0;
                  IF smbus_st_idle = '1' AND smbus_out_busy = '0' THEN
                     IF program_pending = '1' THEN
                        mode <= s_running_program;
                        program_pending <= '0';
                        error_flag <= '0';
                     ELSE
                        IF power_reset /= (power_reset'RANGE => '0') OR update_leds = '1' THEN
                           mode <= s_run_power_update;
                           error_flag <= '0';
                        END IF;
                     END IF;
                  END IF;

               -------------------------------
               WHEN s_run_power_update =>                                        -- Set select ports to ouputs
                  running <= '1';
                  IF smbus_out_al = '1' THEN
                     mode <= s_wait_bus_finished;
                  ELSE
                     IF smbus_st_end = '1' THEN
                        mode <= s_idle;
                        power_reset <= (OTHERS => '0');
                        update_leds <= '0';
                     ELSE
                        IF smbus_out_ack = '1' THEN
                           sequence_count <= sequence_count + 1;
                        END IF;
                     END IF;
                  END IF;

               -------------------------------
               WHEN s_running_program =>
                  running <= '1';
                  IF smbus_out_al = '1' THEN
                     mode <= s_idle;
                     prog_finished <= '1';
                  ELSE
                     IF smbus_st_end = '1' OR sequence_count = 32 THEN        -- Memory is only 32 elements long, so should be done by now
                        mode <= s_idle;
                        prog_finished <= '1';
                     ELSE
                        IF smbus_out_ack = '1' THEN
                           sequence_count <= sequence_count + 1;
                        END IF;
                     END IF;
                  END IF;

               -------------------------------
               WHEN s_wait_bus_finished =>
                  IF smbus_out_al = '0' AND smbus_out_busy = '0' THEN
                     mode <= s_idle;
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

   -- Mux in the user supplied data into the fixed program
   -- Also handle the RMW cycle for the output register
   smbus_in_dat <= "00" & not(power_reset(11 DOWNTO 6))                                      WHEN mode = s_run_power_update AND sequence_count = 3 AND update_leds = '0' ELSE
                   "00" & not(power_reset(5 DOWNTO 0))                                       WHEN mode = s_run_power_update AND sequence_count = 4 AND update_leds = '0' ELSE
                   word_shift(15) & "0000000"                                                WHEN mode = s_run_power_update AND sequence_count = 11 AND update_leds = '0' ELSE
                   word_shift(8) & "0000000"                                                 WHEN mode = s_run_power_update AND sequence_count = 12 AND update_leds = '0' ELSE
                   X"3F"                                                                     WHEN mode = s_run_power_update AND sequence_count = 3 AND update_leds = '1' ELSE
                   X"3F"                                                                     WHEN mode = s_run_power_update AND sequence_count = 4 AND update_leds = '1' ELSE
                   backplane_control_fields_rw.control_red_led & "0000000"                   WHEN mode = s_run_power_update AND sequence_count = 11 AND update_leds = '1' ELSE
                   backplane_control_fields_rw.control_green_led & "0000000"                 WHEN mode = s_run_power_update AND sequence_count = 12 AND update_leds = '1' ELSE
                   STD_LOGIC_VECTOR(TO_UNSIGNED(c_set_port_seq(sequence_count), c_byte_w))   WHEN mode = s_run_power_update ELSE
                   backplane_control_program_out.rd_dat;

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
         IF rst = '1' OR mode = s_idle THEN
            result_count <= (OTHERS => '0');
         ELSE
            IF smbus_out_val = '1' THEN
               result_count <= result_count + 1;
               word_shift <=  word_shift(7 DOWNTO 0) & smbus_out_dat;
            END IF;
         END IF;
      END IF;
   END PROCESS;

---------------------------------------------------------------------------
-- SMBUS Controller  --
---------------------------------------------------------------------------

u_smbus: ENTITY i2c_lib.i2c_smbus
         GENERIC MAP (g_i2c_phy  => c_i2c_phy)
         PORT MAP (gs_sim        => FALSE,
                   rst           => rst,
                   clk           => clk,
                   in_dat        => smbus_in_dat,           -- Command or paramater byte
                   in_req        => smbus_in_req,           -- Valid for in_dat
                   out_dat       => smbus_out_dat,          -- Output data
                   out_val       => smbus_out_val,          -- Valid flag for output data
                   out_err       => smbus_out_err,          -- Transaction Error
                   out_ack       => smbus_out_ack,          -- Acknowledge in_dat
                   st_idle       => smbus_st_idle,          -- FSM in idle
                   st_end        => smbus_st_end,           -- End terminator reached
                   al            => smbus_out_al,
                   busy          => smbus_out_busy,
                   scl           => bp_scl,
                   sda           => bp_sda);

END rtl;
