-------------------------------------------------------------------------------
-- (c) Copyright - Commonwealth Scientific and Industrial Research Organisation
-- (CSIRO) - 2012
--
-- All Rights Reserved.
--
-- Restricted Use.
--
-- Copyright protects this code. Except as permitted by the Copyright Act, you
-- may only use the code as expressly permitted under the terms on which the
-- code was licensed TO you.
--
-------------------------------------------------------------------------------
--
-- File Name:    mon_leds.vhd
-- Type:         RTL
-- Designer:
-- Created:      Fri Mar 2 09:34:08 2012
-- Template Rev: 0.1
--
-- Title:        Single MAX6966 SPI Master
--
-- Description:  This module communciates with the MAX6966 LED controller
--               TO control the front panel LEDS. The LEDs are driven in PWM
--               mode with the current sink set using parameters. Each colour
--               red, green & blue has an 8 bit PWM SIGNAL driving it. Maximum
--               SPI frequency IS 25MHz whihc gives an update rate of 190KHz.
--               LEDs are ramped up with full current WHEN the enable IS taken
--               from low TO high OR at startup IF the enable IS already high
--
-------------------------------------------------------------------------------

LIBRARY IEEE, common_lib;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE common_lib.common_pkg.ALL;

ENTITY spi_max6966 IS
   GENERIC (
      g_simulation       : BOOLEAN := false;
      g_configuration    : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00100001";      -- Run mode with staggered PWM outputs
      g_global_current   : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000";      -- 2.5mA full and 1.25mA half current for leds
      g_current_select   : STD_LOGIC_VECTOR(9 DOWNTO 0) := "0011011011";    -- Half/Full current flags
      g_ramp_up          : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000101";      -- 1s ramp up
      g_ramp_down        : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000101";      -- 1s ramp down
      g_input_clk        : INTEGER := 125;                                  -- Input clk frequency in MHz
      g_tch              : INTEGER := 40;                                   -- sclk high time, in ns
      g_tcl              : INTEGER := 40;                                   -- sclk low time, in ns
      g_tcss             : INTEGER := 20;                                   -- CS fall TO SCLK rise time, in ns (must be biffer than tds)
      g_tcsh             : INTEGER := 0;                                    -- Sclk rise TO cs rise hold time, in ns
      g_tds              : INTEGER := 16;                                   -- DIN setup time, in ns  (must be bigger than actual tds)
      g_tdh              : INTEGER := 0;                                    -- DIN data hold time, in ns
      g_tdo              : INTEGER := 21;                                   -- Data ouput propegation delay, in ns
      g_tcsw             : INTEGER := 39);                                  -- Minimum CS pulse high time

   PORT (
      -- Clocks
      clk                : in std_logic;
      rst                : in std_logic;

      enable             : in std_logic;

      -- Registers
      led1_colour        : IN STD_LOGIC_VECTOR(23 DOWNTO 0);        -- In format R, G, B. Each is 8 bits for intensity
      led2_colour        : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
      led3_colour        : IN STD_LOGIC_VECTOR(23 DOWNTO 0);

      full_cycle         : out std_logic;                          -- Pulsed when a complete cycle is done (for synchronisation of outputs)

      -- SPI Interface
      din                : out std_logic;
      sclk               : out std_logic;
      cs                 : out std_logic;
      dout               : in std_logic);
END spi_max6966;

ARCHITECTURE structure OF spi_max6966 IS


-------------------------------------------------------------------------------
--                                  Types                                    --
-------------------------------------------------------------------------------

   type t_shifter_fsm IS (s_idle,
                          s_chip_select_low,
                          s_clock_high,
                          s_clock_low,
                          s_chip_select_high,
                          s_complete);

   type t_main_fsm IS (s_startup,
                       s_latch_data,
                       s_update_outputs,
                       s_update_outputs_wait,
                       s_load_configuration,
                       s_load_configuration_wait,
                       s_start_chips,
                       s_start_chips_wait,
                       s_wait_ramp,
                       s_load_currents,
                       s_load_currents_wait);

-------------------------------------------------------------------------------
--                               Constants                                   --
-------------------------------------------------------------------------------

   -- The width of the counter, in bits, used TO divide down the clk(add a bit for long timeouts)
   constant c_counter_width : integer := ceil_log2(g_tch*g_input_clk/1000) + 1;

   -- clk generaTOr constants
   constant c_tch_cnt    : unsigned(c_counter_width-1 DOWNTO 0) := TO_unsigned((g_tch*g_input_clk)/1000 -1, c_counter_width);
   constant c_tcl_cnt    : unsigned(c_counter_width-1 DOWNTO 0) := TO_unsigned((g_tcl*g_input_clk)/1000 -1, c_counter_width);
   constant c_tcss_cnt   : unsigned(c_counter_width-1 DOWNTO 0) := TO_unsigned((g_tcss*g_input_clk)/1000 -1, c_counter_width);
   constant c_tds_cnt    : unsigned(c_counter_width-1 DOWNTO 0) := TO_unsigned((g_tds*g_input_clk)/1000 -1, c_counter_width);
   constant c_tdo_cnt    : unsigned(c_counter_width-1 DOWNTO 0) := TO_unsigned((g_tdo*g_input_clk)/1000 -1, c_counter_width);
   constant c_tcsw_cnt   : unsigned(c_counter_width-1 DOWNTO 0) := TO_unsigned((g_tcsw*g_input_clk)/1000 -1, c_counter_width);

   constant c_tcsds_cnt  : unsigned(c_counter_width-1 DOWNTO 0) := c_tcss_cnt - c_tds_cnt;
   constant c_tclds_cnt  : unsigned(c_counter_width-1 DOWNTO 0) := c_tcl_cnt - c_tds_cnt;

-------------------------------------------------------------------------------
--                                SIGNALs                                    --
-------------------------------------------------------------------------------

   -- State Machine
   SIGNAL register_index      : unsigned(3 DOWNTO 0);
   SIGNAL start_counter       : unsigned(27 DOWNTO 0);
   SIGNAL state               : t_main_fsm;
   SIGNAL shifter_state       : t_shifter_fsm;
   SIGNAL shift_data          : std_logic;


   -- IO registers
   SIGNAL i_din               : std_logic;
   SIGNAL i_dout              : std_logic;
   SIGNAL i_sclk              : std_logic;
   SIGNAL enable_dly          : std_logic;
   SIGNAL led_colour          : t_slv_24_arr(0 TO 2);
   SIGNAL led_colour_dly      : t_slv_24_arr(0 TO 2);

   -- Data MUX
   SIGNAL led_r_pwm           : t_slv_8_arr(0 TO 2);
   SIGNAL led_g_pwm           : t_slv_8_arr(0 TO 2);
   SIGNAL led_b_pwm           : t_slv_8_arr(0 TO 2);
   SIGNAL write_data          : std_logic_vecTOr(15 DOWNTO 0);

   -- Output Controller
   SIGNAL divide_counter      : unsigned(c_counter_width-1 DOWNTO 0);
   SIGNAL bit_counter         : unsigned(4 DOWNTO 0);
   SIGNAL sig_cs              : std_logic;
   SIGNAL dout_shifter        : std_logic_vecTOr(15 DOWNTO 0);
   SIGNAL din_shifter         : std_logic_vecTOr(15 DOWNTO 0);

BEGIN


-------------------------------------------------------------------------------
--                             Output Flip Flops                             --
-------------------------------------------------------------------------------

io_reg: ENTITY common_lib.common_delay
        GENERIC MAP (g_dat_w    => 4,
                     g_depth    => 1)
        PORT MAP (clk         => clk,
                  in_dat(0)   => i_din,
                  in_dat(1)   => i_sclk,
                  in_dat(2)   => sig_cs,
                  in_dat(3)   => dout,
                  out_dat(0)  => din,
                  out_dat(1)  => sclk,
                  out_dat(2)  => cs,
                  out_dat(3)  => i_dout);

-------------------------------------------------------------------------------
--                              Input Registers                              --
-------------------------------------------------------------------------------

   led_colour(0) <= led1_colour;
   led_colour(1) <= led2_colour;
   led_colour(2) <= led3_colour;

register_gen: FOR i IN 0 TO 2 GENERATE
   colour_reg: ENTITY common_lib.common_delay
               GENERIC MAP (g_dat_w    => 24,
                            g_depth    => 1)
               PORT MAP (clk         => clk,
                         in_dat      => led_colour(i),
                         out_dat     => led_colour_dly(i));
END GENERATE;

enable_reg: ENTITY common_lib.common_delay
        GENERIC MAP (g_dat_w    => 1,
                     g_depth    => 1)
        PORT MAP (clk         => clk,
                  in_dat(0)   => enable,
                  out_dat(0)  => enable_dly);

-------------------------------------------------------------------------------
--                              Led State decoding                           --
-------------------------------------------------------------------------------

led_decode: PROCESS(clk)
   BEGIN
      IF rising_edge(clk) THEN
         IF state = s_latch_data THEN
            for i in 0 TO 2 LOOP
               -- Red
               CASE led_colour_dly(i)(23 DOWNTO 16) IS
                  WHEN X"00" =>
                     led_r_pwm(i) <= X"FF";                             -- Ouput in high impedance
                  WHEN X"01" | X"02" =>
                     led_r_pwm(i) <= X"03";                             -- Remap TO 3/256 duty cycle
                  WHEN X"FF" =>
                     led_r_pwm(i) <= X"02";                             -- Constant current sink
                  WHEN OTHERS =>
                     led_r_pwm(i) <= led_colour_dly(i)(23 DOWNTO 16);   -- Map the duty cycle across
               END CASE;

               -- Green
               CASE led_colour_dly(i)(15 DOWNTO 8) IS
                  WHEN X"00" =>
                     led_g_pwm(i) <= X"FF";                             -- Ouput in high impedance
                  WHEN X"01" | X"02" =>
                     led_g_pwm(i) <= X"03";                             -- Remap TO 3/256 duty cycle
                  WHEN X"FF" =>
                     led_g_pwm(i) <= X"02";                             -- Constant current sink
                  WHEN OTHERS =>
                     led_g_pwm(i) <= led_colour_dly(i)(15 DOWNTO 8);    -- Map the duty cycle across
               END CASE;

               -- Blue
               CASE led_colour_dly(i)(7 DOWNTO 0) IS
                  WHEN X"00" =>
                     led_b_pwm(i) <= X"FF";                             -- Ouput in high impedance
                  WHEN X"01" | X"02" =>
                     led_b_pwm(i) <= X"03";                             -- Remap TO 3/256 duty cycle
                  WHEN X"FF" =>
                     led_b_pwm(i) <= X"02";                             -- Constant current sink
                  WHEN OTHERS =>
                     led_b_pwm(i) <= led_colour_dly(i)(7 DOWNTO 0);     -- Map the duty cycle across
               END CASE;
            END LOOP;
         END IF;
      END IF;
   END PROCESS;

-------------------------------------------------------------------------------
--                           TOp Level State Machine                         --
-------------------------------------------------------------------------------

control_fsm: PROCESS(clk)
   BEGIN
      IF rising_edge(clk) THEN
         shift_data <= '0';
         full_cycle <= '0';
         IF rst = '1' OR enable_dly = '0' THEN
            state <= s_startup;
            register_index <= (OTHERS => '0');
            start_counter <= X"0FFFFFF";
         ELSE
            CASE state IS
               --------------------------------------------
               WHEN s_latch_data =>
                  state <= s_update_outputs;
               WHEN s_update_outputs =>
                  IF register_index = 9 THEN
                     register_index <= (OTHERS => '0');
                     full_cycle <= '1';
                     state <= s_latch_data;
                  ELSE
                     shift_data <= '1';
                     state <= s_update_outputs_wait;
                  END IF;
               WHEN s_update_outputs_wait =>
                  IF shifter_state = s_complete THEN
                     register_index <= register_index + 1;
                     state <= s_update_outputs;
                  END IF;
               --------------------------------------------
               WHEN s_startup =>                                     -- Wait for a little while after FPGA configures
                  register_index <= (OTHERS => '0');
                  start_counter <= start_counter - 1;
                  IF (start_counter = 0 and g_simulation = false) OR (start_counter(15 DOWNTO 0) = 0 and g_simulation = true) THEN
                     state <= s_load_configuration;
                  END IF;
               --------------------------------------------
               WHEN s_load_configuration =>                          -- Load constant current and global settings. Start the chips with all outputs enabled
                  IF register_index = 7 THEN                     -- THEN ramp up. Afterwards the outputs revert TO normal. Should make the leds all ramp
                     register_index <= (OTHERS => '0');          -- up TO white THEN turn off.
                     state <= s_start_chips;
                  ELSE
                     shift_data <= '1';
                     state <= s_load_configuration_wait;
                  END IF;
               WHEN s_load_configuration_wait =>
                  IF shifter_state = s_complete THEN
                     register_index <= register_index + 1;
                     state <= s_load_configuration;
                  END IF;
               WHEN s_start_chips =>                                 -- Ramp up all the LED outputs TO the selected drive current
                  shift_data <= '1';
                  state <= s_start_chips_wait;
               WHEN s_start_chips_wait =>
                  IF shifter_state = s_complete THEN
                     state <= s_wait_ramp;
                     start_counter <= (OTHERS => '1');
                  END IF;
               WHEN s_wait_ramp =>                                -- Wait for 2 seconds before we start writeing real data TO chips
                  start_counter <= start_counter - 1;
                  IF (start_counter = 0 and g_simulation = false) OR (start_counter(15 DOWNTO 0) = 0 and g_simulation = true) THEN
                     state <= s_load_currents;
                  END IF;
               WHEN s_load_currents =>                               -- Update the global current settings TO the right values after startup ramp
                  shift_data <= '1';
                  state <= s_load_currents_wait;
               WHEN s_load_currents_wait =>
                  IF shifter_state = s_complete THEN
                     state <= s_latch_data;
                     register_index <= (OTHERS => '0');
                  END IF;
            END CASE;
         END IF;
      END IF;
   END PROCESS;

   -- Register address (MSB defines read/write 1 for read)
   write_data(15 DOWNTO 8) <= X"10" WHEN state = s_load_configuration_wait and register_index = 0 ELSE
                              X"11" WHEN state = s_load_configuration_wait and register_index = 1 ELSE
                              X"12" WHEN state = s_load_configuration_wait and register_index = 2 ELSE
                              X"15" WHEN state = s_load_configuration_wait and register_index = 3 ELSE
                              X"0A" WHEN state = s_load_configuration_wait and register_index = 4 ELSE
                              X"13" WHEN state = s_load_configuration_wait and register_index = 5 ELSE
                              X"14" WHEN state = s_load_configuration_wait and register_index = 6 ELSE
                              X"10" WHEN state = s_start_chips_wait ELSE
                              X"15" WHEN state = s_load_currents_wait ELSE
                              X"00" WHEN state = s_update_outputs_wait and register_index = 0 ELSE
                              X"01" WHEN state = s_update_outputs_wait and register_index = 1 ELSE
                              X"02" WHEN state = s_update_outputs_wait and register_index = 2 ELSE
                              X"03" WHEN state = s_update_outputs_wait and register_index = 3 ELSE
                              X"04" WHEN state = s_update_outputs_wait and register_index = 4 ELSE
                              X"05" WHEN state = s_update_outputs_wait and register_index = 5 ELSE
                              X"06" WHEN state = s_update_outputs_wait and register_index = 6 ELSE
                              X"07" WHEN state = s_update_outputs_wait and register_index = 7 ELSE
                              X"08" WHEN state = s_update_outputs_wait and register_index = 8 ELSE
                              X"00";

   -- Register Data
   write_data(7 DOWNTO 0) <= g_configuration and X"FC"               WHEN state = s_load_configuration_wait and register_index = 0 ELSE
                             g_ramp_down                             WHEN state = s_load_configuration_wait and register_index = 1 ELSE
                             g_ramp_up                               WHEN state = s_load_configuration_wait and register_index = 2 ELSE
                             X"07"                                   WHEN state = s_load_configuration_wait and register_index = 3 ELSE
                             X"02"                                   WHEN state = s_load_configuration_wait and register_index = 4 ELSE
                             g_current_select(7 DOWNTO 0)            WHEN state = s_load_configuration_wait and register_index = 5 ELSE
                             "000000" & g_current_select(9 DOWNTO 8) WHEN state = s_load_configuration_wait and register_index = 6 ELSE
                             g_configuration OR X"05"                WHEN state = s_start_chips_wait ELSE
                             g_global_current                        WHEN state = s_load_currents_wait ELSE
                             led_r_pwm(0)                            WHEN state = s_update_outputs_wait and register_index = 0 ELSE
                             led_b_pwm(0)                            WHEN state = s_update_outputs_wait and register_index = 1 ELSE
                             led_g_pwm(0)                            WHEN state = s_update_outputs_wait and register_index = 2 ELSE
                             led_r_pwm(1)                            WHEN state = s_update_outputs_wait and register_index = 3 ELSE
                             led_b_pwm(1)                            WHEN state = s_update_outputs_wait and register_index = 4 ELSE
                             led_g_pwm(1)                            WHEN state = s_update_outputs_wait and register_index = 5 ELSE
                             led_r_pwm(2)                            WHEN state = s_update_outputs_wait and register_index = 6 ELSE
                             led_b_pwm(2)                            WHEN state = s_update_outputs_wait and register_index = 7 ELSE
                             led_g_pwm(2)                            WHEN state = s_update_outputs_wait and register_index = 8 ELSE
                             X"00";

-------------------------------------------------------------------------------
--                               Data Shifter                                --
-------------------------------------------------------------------------------

data_shifter: PROCESS(clk)
   BEGIN
      IF rising_edge(clk) THEN
         divide_counter <= divide_counter + 1;

         -- clk generation state machine
         CASE shifter_state IS
            WHEN s_idle =>
               din_shifter <= write_data;
               bit_counter <= (OTHERS => '0');
               IF shift_data = '1' THEN
                  shifter_state <= s_chip_select_low;
                  divide_counter <= (OTHERS => '0');
               END IF;
            WHEN s_chip_select_low =>                                -- Drop chip select low
               IF divide_counter = c_tcss_cnt THEN
                  shifter_state <= s_clock_high;
                  divide_counter <= (OTHERS => '0');
               END IF;
            WHEN s_clock_high =>
               IF divide_counter = c_tch_cnt THEN
                  shifter_state <= s_clock_low;
                  divide_counter <= (OTHERS => '0');
               END IF;
            WHEN s_clock_low =>
               IF divide_counter = c_tcl_cnt THEN
                  divide_counter <= (OTHERS => '0');
                  IF bit_counter = 16 THEN
                     shifter_state <= s_chip_select_high;
                  ELSE
                     shifter_state <= s_clock_high;
                  END IF;
               END IF;
            WHEN s_chip_select_high =>
               IF divide_counter = c_tcsw_cnt THEN
                  shifter_state <= s_complete;
               END IF;
            WHEN s_complete =>
               shifter_state <= s_idle;
         END CASE;

         -- Data output shifter (changes on falling clk edge)
         IF shifter_state = s_clock_low and divide_counter = 0 THEN
            din_shifter <= din_shifter(14 DOWNTO 0) & '0';
            bit_counter <= bit_counter + 1;
         END IF;

         -- Data input shifter (not used yet)
         IF (shifter_state = s_clock_high and divide_counter = 0) OR
            (shifter_state = s_chip_select_high and divide_counter = c_tdo_cnt) THEN
            dout_shifter <= dout_shifter(14 DOWNTO 0) & i_dout;
         END IF;

      END IF;
   END PROCESS;

   i_din <= din_shifter(15);

   sig_cs <= '1' WHEN shifter_state = s_idle OR shifter_state = s_complete ELSE '0';

   i_sclk <= '1' WHEN shifter_state = s_clock_high ELSE '0';

END structure;