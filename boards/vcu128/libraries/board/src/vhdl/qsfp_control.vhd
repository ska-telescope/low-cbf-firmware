-------------------------------------------------------------------------------
--
-- File Name: qsfp_control.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Thurs Oct 19 16:40:00 2017
-- Template Rev: 1.0
--
-- Title: M&C support for QSFP Parts
--
-- Description: Provides the register level interface for the QSFP components
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
USE i2c_lib.i2c_dev_qsfp_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE work.i2c_addresses_pkg.ALL;
USE work.vcu128_board_qsfp_reg_pkg.ALL;

-------------------------------------------------------------------------------
ENTITY qsfp_control IS
   GENERIC (
      g_technology      : t_technology := c_tech_select_default;
      g_clk_rate        : INTEGER := 156250000;  -- Clk rate in HZ
      g_i2c_rate        : INTEGER := 50000;      -- i2c clock rate in HZ
      g_startup_time    : INTEGER := 100;        -- Startup time in milliseconds, state machine is idle for this time after startup, then resets QSFPs, then is ready for normal operation.
      g_reset_time      : INTEGER := 10          -- milliseconds prior to the end of g_startup_time to apply the QSFP reset.
   ); 
   PORT (
      rst               : IN  STD_LOGIC;
      clk               : IN  STD_LOGIC;

      --AXI Interface
      s_axi_mosi        : IN t_axi4_lite_mosi;
      s_axi_miso        : OUT t_axi4_lite_miso;

      -- Transciever Links
      qsfp_a_tx_disable : OUT STD_LOGIC_VECTOR(0 TO 3);
      qsfp_a_rx_disable : OUT STD_LOGIC_VECTOR(0 TO 3);
      qsfp_a_loopback   : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      qsfp_a_rx_locked  : IN STD_LOGIC_VECTOR(0 TO 3);

      qsfp_b_tx_disable : OUT STD_LOGIC_VECTOR(0 TO 3);
      qsfp_b_rx_disable : OUT STD_LOGIC_VECTOR(0 TO 3);
      qsfp_b_loopback   : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      qsfp_b_rx_locked  : IN STD_LOGIC_VECTOR(0 TO 3);

      qsfp_c_tx_disable : OUT STD_LOGIC_VECTOR(0 TO 3);
      qsfp_c_rx_disable : OUT STD_LOGIC_VECTOR(0 TO 3);
      qsfp_c_loopback   : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      qsfp_c_rx_locked  : IN STD_LOGIC_VECTOR(0 TO 3);

      qsfp_d_tx_disable : OUT STD_LOGIC_VECTOR(0 TO 3);
      qsfp_d_rx_disable : OUT STD_LOGIC_VECTOR(0 TO 3);
      qsfp_d_loopback   : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      qsfp_d_rx_locked  : IN STD_LOGIC_VECTOR(0 TO 3);

      -- Physical Interfaces
      qsfp_a_mod_prs_n  : IN std_logic;
      qsfp_a_mod_sel    : OUT std_logic;                          -- Active high (inverted on board)
      qsfp_a_reset      : OUT std_logic;                          -- Active high (inverted on board)

      qsfp_b_mod_prs_n  : IN std_logic;
      qsfp_b_mod_sel    : OUT std_logic;
      qsfp_b_reset      : OUT std_logic;

      qsfp_c_mod_prs_n  : IN std_logic;
      qsfp_c_mod_sel    : OUT std_logic;
      qsfp_c_reset      : OUT std_logic;

      qsfp_d_mod_prs_n  : IN std_logic;
      qsfp_d_mod_sel    : OUT std_logic;
      qsfp_d_reset      : OUT std_logic;

      qsfp_int_n        : IN std_logic;
      qsfp_sda          : INOUT std_logic;                        -- OC drive, internal Pullups
      qsfp_scl          : INOUT std_logic);                       -- LVCMOS 1.8V
END qsfp_control;


ARCHITECTURE rtl OF qsfp_control IS

  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   TYPE fsm_states IS (s_idle, s_startup_wait, s_startup, s_running_monitor, s_set_mask, s_running_program);

   -- Runs the same program for each of the 4 QSFP modules
   CONSTANT c_monitor_seq : t_nat_natural_arr := (
     -- |    Command         |   Parameters
         SMBUS_C_WAIT,        16#00#, 16#01#, 16#00#, 16#00#,           -- Wait 256 Clocks for select to be stable
         SMBUS_WRITE_BYTE,    c_qsfp_address, QSFP_CTRL_TX_DISABLE, 0,  -- Write Out Disable bits everytime

         SMBUS_READ_WORD,     c_qsfp_address, QSFP_STATUS,              -- Result 0|1
         SMBUS_READ_WORD,     c_qsfp_address, QSFP_MON_VOLTAGE,         -- Result 2|3
         SMBUS_READ_WORD,     c_qsfp_address, QSFP_MON_TX1_BIAS,        -- Result 4|5
         SMBUS_READ_WORD,     c_qsfp_address, QSFP_MON_TX2_BIAS,        -- Result 6|7
         SMBUS_READ_WORD,     c_qsfp_address, QSFP_MON_TX3_BIAS,        -- Result 8|9
         SMBUS_READ_WORD,     c_qsfp_address, QSFP_MON_TX4_BIAS,        -- Result 10|11
         SMBUS_READ_WORD,     c_qsfp_address, QSFP_MON_RX1_POWER,       -- Result 12|13
         SMBUS_READ_WORD,     c_qsfp_address, QSFP_MON_RX2_POWER,       -- Result 14|15
         SMBUS_READ_WORD,     c_qsfp_address, QSFP_MON_RX3_POWER,       -- Result 16|17
         SMBUS_READ_WORD,     c_qsfp_address, QSFP_MON_RX4_POWER,       -- Result 18|19
         SMBUS_READ_WORD,     c_qsfp_address, QSFP_MON_TEMPERATURE,     -- Result 20|21

         SMBUS_C_END,
         SMBUS_C_NOP);

   CONSTANT c_i2c_phy   : t_c_i2c_phy := (clk_cnt => g_clk_rate/(5*g_i2c_rate)-1,
                                          comma_w => 0);

   CONSTANT c_startup_width   : INTEGER := ceil_log2(g_clk_rate/1000 * g_startup_time);
   CONSTANT c_startup_count   : INTEGER := (g_clk_rate/1000 * g_startup_time) -1;
   CONSTANT c_reset_count     : INTEGER := (g_clk_rate/1000 * g_reset_time) -1;

   ---------------------------------------------------------------------------
   -- SIGNAL DECLARATIONS  --
   ---------------------------------------------------------------------------

   SIGNAL mode                : fsm_states;
   SIGNAL prog_finished       : STD_LOGIC;
   SIGNAL error_flag          : STD_LOGIC;
   SIGNAL program_pending     : STD_LOGIC;
   SIGNAL running             : STD_LOGIC;
   SIGNAL sequence_count      : NATURAL RANGE 0 TO 63;
   SIGNAL sequence_count_slv  : STD_LOGIC_VECTOR(5 DOWNTO 0);
   SIGNAL smbus_out_ack_dly   : STD_LOGIC;
   SIGNAL qsfp_reset          : STD_LOGIC_VECTOR(0 TO 3);
   signal qsfp_reset_in       : std_logic_vector(0 to 3);
   SIGNAL i_qsfp_int_n        : STD_LOGIC;
   SIGNAL i_qsfp_mod_sel      : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL qsfp_program_select : STD_LOGIC_VECTOR(4 DOWNTO 0);
   SIGNAL qsfp_select         : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL qsfp_mask           : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL startup_counter     : UNSIGNED(c_startup_width-1 DOWNTO 0);
   SIGNAL i_rst               : STD_LOGIC;

   SIGNAL control_fields_rw   : t_control_rw;
   SIGNAL control_fields_ro   : t_control_ro;
   SIGNAL control_program_in  : t_control_program_ram_in;
   SIGNAL control_program_out : t_control_program_ram_out;
   SIGNAL control_results_in  : t_control_results_ram_in;
   SIGNAL qsfp_fields_rw      : t_qsfp_rw;
   SIGNAL qsfp_fields_ro      : t_qsfp_ro;

   SIGNAL result_count        : UNSIGNED(4 DOWNTO 0);
   SIGNAL result_count_dly    : UNSIGNED(4 DOWNTO 0);
   SIGNAL word_shift          : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL smbus_out_val_dly   : STD_LOGIC;
   SIGNAL qsfp_index          : INTEGER RANGE 0 TO 3;

   -- I2c Core
   SIGNAL smbus_out_dat       : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL smbus_in_dat        : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL smbus_in_req        : STD_LOGIC;
   SIGNAL smbus_out_val       : STD_LOGIC;
   SIGNAL smbus_out_err       : STD_LOGIC;
   SIGNAL smbus_out_ack       : STD_LOGIC;
   SIGNAL smbus_st_idle       : STD_LOGIC;
   SIGNAL smbus_st_end        : STD_LOGIC;
   
   signal startup_reset : std_logic;

   ATTRIBUTE DONT_TOUCH                   : STRING;
   ATTRIBUTE DONT_TOUCH OF qsfp_a_reset   : SIGNAL IS "true";
   ATTRIBUTE DONT_TOUCH OF qsfp_b_reset   : SIGNAL IS "true";
   ATTRIBUTE DONT_TOUCH OF qsfp_c_reset   : SIGNAL IS "true";
   ATTRIBUTE DONT_TOUCH OF qsfp_d_reset   : SIGNAL IS "true";
   ATTRIBUTE DONT_TOUCH OF i_rst          : SIGNAL IS "true";

BEGIN

   -- Done this way to avoid simulator warnings
   sequence_count_slv <= STD_LOGIC_VECTOR(TO_UNSIGNED(sequence_count, 6));

   io_reg: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         i_rst <= rst;

         control_fields_ro.status_interrupt <= not i_qsfp_int_n;

         qsfp_fields_ro.status_present(0) <= NOT(qsfp_a_mod_prs_n);
         qsfp_fields_ro.status_present(1) <= NOT(qsfp_b_mod_prs_n);
         qsfp_fields_ro.status_present(2) <= NOT(qsfp_c_mod_prs_n);
         qsfp_fields_ro.status_present(3) <= NOT(qsfp_d_mod_prs_n);

         qsfp_fields_ro.status_rx_locked(0) <= flip(qsfp_a_rx_locked);
         qsfp_fields_ro.status_rx_locked(1) <= flip(qsfp_b_rx_locked);
         qsfp_fields_ro.status_rx_locked(2) <= flip(qsfp_c_rx_locked);
         qsfp_fields_ro.status_rx_locked(3) <= flip(qsfp_d_rx_locked);

         qsfp_a_tx_disable <= flip(qsfp_fields_rw.control_tx_disable(0));
         qsfp_a_rx_disable <= flip(qsfp_fields_rw.control_rx_disable(0));
         qsfp_a_loopback<= qsfp_fields_rw.control_loopback(0);

         qsfp_b_tx_disable <= flip(qsfp_fields_rw.control_tx_disable(1));
         qsfp_b_rx_disable <= flip(qsfp_fields_rw.control_rx_disable(1));
         qsfp_b_loopback<= qsfp_fields_rw.control_loopback(1);

         qsfp_c_tx_disable <= flip(qsfp_fields_rw.control_tx_disable(2));
         qsfp_c_rx_disable <= flip(qsfp_fields_rw.control_rx_disable(2));
         qsfp_c_loopback<= qsfp_fields_rw.control_loopback(2);

         qsfp_d_tx_disable <= flip(qsfp_fields_rw.control_tx_disable(3));
         qsfp_d_rx_disable <= flip(qsfp_fields_rw.control_rx_disable(3));
         qsfp_d_loopback<= qsfp_fields_rw.control_loopback(3);
      END IF;
   END PROCESS;


---------------------------------------------------------------------------
-- Registers  --
---------------------------------------------------------------------------

   regs: ENTITY work.vcu128_board_qsfp_reg
   GENERIC MAP (
      g_technology     => g_technology)
   PORT MAP (
      mm_clk              => clk,
      mm_rst              => i_rst,
      sla_in              => s_axi_mosi,
      sla_out             => s_axi_miso,
      control_fields_rw   => control_fields_rw,
      control_fields_ro   => control_fields_ro,
      control_program_in  => control_program_in,
      control_program_out => control_program_out,
      control_results_in  => control_results_in,
      control_results_out => OPEN,
      qsfp_fields_rw      => qsfp_fields_rw,
      qsfp_fields_ro      => qsfp_fields_ro);



   control_fields_ro.status_error <= error_flag;
   control_fields_ro.status_prog_finished <= prog_finished;

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
   control_results_in.wr_en <= smbus_out_val WHEN mode = s_running_program ELSE '0';





---------------------------------------------------------------------------
-- High Level Controller  --
---------------------------------------------------------------------------
-- There are two stored programs that can be run, the standard monitoring loop
-- or the clear faults loop. There is also a programmable mode that allows
-- for arbitary programs to be uploaded through the registers and execuet with
-- the results stored in a RAM that can be downloaded

-- QSFPs need to be enabled in order to run the stored program. After each iteration
-- of the monitor program the enable bit is shifted and the monitor program is
-- re-run with a new QSFP selected

   monitor_fsm: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN

         -- IO Registers
         i_qsfp_int_n <= qsfp_int_n;
         qsfp_a_mod_sel <= i_qsfp_mod_sel(0);
         qsfp_b_mod_sel <= i_qsfp_mod_sel(1);
         qsfp_c_mod_sel <= i_qsfp_mod_sel(2);
         qsfp_d_mod_sel <= i_qsfp_mod_sel(3);

         qsfp_a_reset <= qsfp_reset(0);
         qsfp_b_reset <= qsfp_reset(1);
         qsfp_c_reset <= qsfp_reset(2);
         qsfp_d_reset <= qsfp_reset(3);

         smbus_out_ack_dly <= smbus_out_ack;

         IF i_rst = '1' THEN
            mode <= s_startup_wait;
            prog_finished <= '0';
            error_flag <= '0';
            program_pending <= '0';
            running <= '0';
            qsfp_select <= "1000";
            startup_counter <= TO_UNSIGNED(c_startup_count, c_startup_width);
         ELSE
            error_flag <= error_flag OR smbus_out_err;
            program_pending <= program_pending OR control_fields_rw.control_prog_execute;

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
                        -- Save mask to indicate which of the QSFPs we want
                        -- the loaded program to run on
                        qsfp_mask <= control_fields_rw.control_prog_select;
                        qsfp_program_select <= "00001";
                        mode <= s_set_mask;
                        program_pending <= '0';
                        error_flag <= '0';
                     ELSE
                        IF control_fields_rw.control_monitor_enable = '1' THEN
                           qsfp_select <= qsfp_select(2 DOWNTO 0) & qsfp_select(3);
                           mode <= s_running_monitor;
                        ELSE
                           qsfp_select <= "1000";
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
               WHEN s_set_mask =>                                          -- Check whats enabled in the mask and run the program if nessecary
                  running <= '0';
                  IF (qsfp_program_select(3 DOWNTO 0) AND qsfp_mask) /= "0000" THEN
                     mode <= s_running_program;
                     sequence_count <= 0;
                  ELSE
                     IF qsfp_program_select(4) = '1' THEN
                        mode <= s_idle;
                        prog_finished <= '1';
                     ELSE
                        qsfp_program_select <= qsfp_program_select(3 DOWNTO 0) & '0';
                     END IF;
                  END IF;

               -------------------------------
               WHEN s_running_program =>
                  running <= '1';
                  IF smbus_st_end = '1' OR sequence_count = 32 THEN        -- Memory is only 32 elements long, so should be done by now
                     mode <= s_set_mask;
                     qsfp_program_select <= qsfp_program_select(3 DOWNTO 0) & '0';
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
         
         if (mode = s_startup_wait and (startup_counter = TO_UNSIGNED(c_reset_count, c_startup_width))) then
            startup_reset <= '1';
         else
            startup_reset <= '0';
         end if;
         
      END IF;
   END PROCESS;

   smbus_in_dat <= X"0" & qsfp_fields_rw.control_tx_disable(0) WHEN mode = s_running_monitor AND sequence_count = 8 AND qsfp_select(0) = '1' ELSE
                   X"0" & qsfp_fields_rw.control_tx_disable(1) WHEN mode = s_running_monitor AND sequence_count = 8 AND qsfp_select(1) = '1' ELSE
                   X"0" & qsfp_fields_rw.control_tx_disable(2) WHEN mode = s_running_monitor AND sequence_count = 8 AND qsfp_select(2) = '1' ELSE
                   X"0" & qsfp_fields_rw.control_tx_disable(3) WHEN mode = s_running_monitor AND sequence_count = 8 AND qsfp_select(3) = '1' ELSE
                   STD_LOGIC_VECTOR(TO_UNSIGNED(c_monitor_seq(sequence_count), c_byte_w)) WHEN mode = s_running_monitor ELSE
                   control_program_out.rd_dat;

   -- Extra delay from RAM so we drop the req on the increment and reassert a cycle later
   -- smbus_out_ack is asychronous so we need clocked versions
   smbus_in_req <= '0' WHEN mode = s_running_program and smbus_out_ack_dly = '1' ELSE
                   running AND NOT(smbus_st_end);


   -- Active low QSFP select
QSFP_SEL: FOR i IN 0 TO 3 GENERATE
   i_qsfp_mod_sel(i) <= '1' WHEN (qsfp_program_select(i) = '1' AND mode = s_running_program) OR
                                 (qsfp_select(i) = '1' AND mode = s_running_monitor) ELSE
                        '0';
END GENERATE;


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
               word_shift <= word_shift(7 DOWNTO 0) & smbus_out_dat;
            END IF;
         END IF;
      END IF;
   END PROCESS;

   qsfp_index <= 0 WHEN qsfp_select(0) = '1' ELSE
                 1 WHEN qsfp_select(1) = '1' ELSE
                 2 WHEN qsfp_select(2) = '1' ELSE
                 3;

   data_store: PROCESS (clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         smbus_out_val_dly <= smbus_out_val;
         result_count_dly <= result_count;

         IF smbus_out_val_dly = '1' AND mode = s_running_monitor THEN
            IF qsfp_select /= "0000" THEN
               CASE TO_INTEGER(result_count_dly) IS
                  WHEN 1 =>  qsfp_fields_ro.status_not_ready(qsfp_index) <= word_shift(0);
                  WHEN 3 =>  qsfp_fields_ro.voltage(qsfp_index) <= word_shift;
                  WHEN 5 =>  qsfp_fields_ro.tx_bias0(qsfp_index) <= word_shift;
                  WHEN 7 =>  qsfp_fields_ro.tx_bias1(qsfp_index) <= word_shift;
                  WHEN 9 =>  qsfp_fields_ro.tx_bias2(qsfp_index) <= word_shift;
                  WHEN 11 => qsfp_fields_ro.tx_bias3(qsfp_index) <= word_shift;
                  WHEN 13 => qsfp_fields_ro.rx_power0(qsfp_index) <= word_shift;
                  WHEN 15 => qsfp_fields_ro.rx_power1(qsfp_index) <= word_shift;
                  WHEN 17 => qsfp_fields_ro.rx_power2(qsfp_index) <= word_shift;
                  WHEN 19 => qsfp_fields_ro.rx_power3(qsfp_index) <= word_shift;
                  WHEN 21 => qsfp_fields_ro.temperature(qsfp_index) <= word_shift;
                  WHEN OTHERS =>
               END CASE;
            END IF;
         END IF;
      END IF;
   END PROCESS;

---------------------------------------------------------------------------
-- SMBUS Controller  --
---------------------------------------------------------------------------

   u_smbus: ENTITY i2c_lib.i2c_smbus
   GENERIC MAP (
      g_i2c_phy  => c_i2c_phy)
   PORT MAP (
      gs_sim        => FALSE,
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
      scl           => qsfp_scl,
      sda           => qsfp_sda);

---------------------------------------------------------------------------
-- QSFP Reset Extender  --
---------------------------------------------------------------------------

   reset_gen: FOR i in 0 TO 3 GENERATE
   
      -- Reset after the startup time (default of 100ms after booting).
      -- Put in since the QSFP sometimes doesn't come up correctly without it.
      qsfp_reset_in(i) <= startup_reset or qsfp_fields_rw.control_reset(i);
   
      qsfp_reset_stretch: ENTITY common_lib.common_pulse_extend
      GENERIC MAP (
         g_rst_level     => '1',      -- Hold in reset during chip reset
         g_p_in_level    => '1',
         g_ep_out_level  => '1',      -- Reset
         g_extend_w      => 9)
      PORT MAP (
         rst       => i_rst,
         clk       => clk,
         clken     => '1',
         p_in      => qsfp_reset_in(i),
         ep_out    => qsfp_reset(i));

   END GENERATE;

END rtl;
