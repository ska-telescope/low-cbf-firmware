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
-- code was licensed to you.
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
--               to control the front panel LEDS. The LEDs are driven in PWM
--               mode with the current sink set using parameters. Each colour
--               red, green & blue has an 8 bit PWM signal driving it. Maximum 
--               SPI frequency is 25MHz whihc gives an update rate of 190KHz. 
--               LEDs are ramped up with full current when the enable is taken 
--               from low to high or at startup if the enable is already high
--
-------------------------------------------------------------------------------

library ieee;
library unisim;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;
use work.utils_pkg.all;

entity spi_max6966 is
   generic (
      con_simulation       : boolean := false;
      con_configuration    : std_logic_vector(7 downto 0) := "00100001";      -- Run mode with staggered PWM outputs
      con_global_current   : std_logic_vector(7 downto 0) := "00000000";      -- 2.5mA full and 1.25mA half current for leds
      con_current_select   : std_logic_vector(9 downto 0) := "0001001001";    -- Half/Full current flags
      con_ramp_up          : std_logic_vector(7 downto 0) := "00000101";      -- 1s ramp up
      con_ramp_down        : std_logic_vector(7 downto 0) := "00000101";      -- 1s ramp down
      con_input_clk        : integer := 125;                                  -- Input clock frequency in MHz
      con_tch              : integer := 40;                                   -- sclk high time, in ns
      con_tcl              : integer := 40;                                   -- sclk low time, in ns
      con_tcss             : integer := 20;                                   -- CS fall to SCLK rise time, in ns (must be biffer than tds)
      con_tcsh             : integer := 0;                                    -- Sclk rise to cs rise hold time, in ns
      con_tds              : integer := 16;                                   -- DIN setup time, in ns  (must be bigger than actual tds)
      con_tdh              : integer := 0;                                    -- DIN data hold time, in ns
      con_tdo              : integer := 21;                                   -- Data ouput propegation delay, in ns
      con_tcsw             : integer := 39);                                  -- Minimum CS pulse high time


   port (
      -- Clocks
      clock                : in std_logic;
      reset                : in std_logic;

      enable               : in std_logic;

      -- Registers
      led1_colour          : in std_logic_vector(23 downto 0);        -- In format R, G, B. Each is 8 bits for intensity
      led2_colour          : in std_logic_vector(23 downto 0);
      led3_colour          : in std_logic_vector(23 downto 0);

      full_cycle           : out std_logic;                          -- Pulsed when a complete cycle is done (for synchronisation of outputs)
      
      -- SPI Interface
      din                  : out std_logic;
      sclk                 : out std_logic;
      cs                   : out std_logic;
      dout                 : in std_logic);
end spi_max6966;

architecture structure of spi_max6966 is


-------------------------------------------------------------------------------
--                                  Types                                    --
-------------------------------------------------------------------------------
   
   type t_vector6 is array (natural range <>) of std_logic_vector(5 downto 0);
   type t_vector8 is array (natural range <>) of std_logic_vector(7 downto 0);
   type t_vector24 is array (natural range <>) of std_logic_vector(23 downto 0);

   type t_shifter_fsm is (s_idle,
                          s_chip_select_low,
                          s_clock_high,
                          s_clock_low,
                          s_chip_select_high,
                          s_complete);

   type t_main_fsm is (s_startup,
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

   -- The width of the counter, in bits, used to divide down the clock(add a bit for long timeouts)
   constant con_counter_width : integer := ceil_log2(con_tch*con_input_clk/1000) + 1;             

   -- Clock generator constants
   constant con_tch_cnt    : unsigned(con_counter_width-1 downto 0) := to_unsigned((con_tch*con_input_clk)/1000 -1, con_counter_width);
   constant con_tcl_cnt    : unsigned(con_counter_width-1 downto 0) := to_unsigned((con_tcl*con_input_clk)/1000 -1, con_counter_width);
   constant con_tcss_cnt   : unsigned(con_counter_width-1 downto 0) := to_unsigned((con_tcss*con_input_clk)/1000 -1, con_counter_width);
   constant con_tcsh_cnt   : unsigned(con_counter_width-1 downto 0) := to_unsigned((con_tcsh*con_input_clk)/1000 -1, con_counter_width);
   constant con_tds_cnt    : unsigned(con_counter_width-1 downto 0) := to_unsigned((con_tds*con_input_clk)/1000 -1, con_counter_width);
   constant con_tdh_cnt    : unsigned(con_counter_width-1 downto 0) := to_unsigned((con_tdh*con_input_clk)/1000 -1, con_counter_width);
   constant con_tdo_cnt    : unsigned(con_counter_width-1 downto 0) := to_unsigned((con_tdo*con_input_clk)/1000 -1, con_counter_width);
   constant con_tcsw_cnt   : unsigned(con_counter_width-1 downto 0) := to_unsigned((con_tcsw*con_input_clk)/1000 -1, con_counter_width);

   constant con_tcsds_cnt  : unsigned(con_counter_width-1 downto 0) := con_tcss_cnt - con_tds_cnt;
   constant con_tclds_cnt  : unsigned(con_counter_width-1 downto 0) := con_tcl_cnt - con_tds_cnt;

-------------------------------------------------------------------------------
--                                Signals                                    --
-------------------------------------------------------------------------------

   -- State Machine
   signal sig_register_index  : unsigned(3 downto 0);
   signal sig_start_counter   : unsigned(27 downto 0);
   signal sig_state           : t_main_fsm;
   signal sig_shifter_state   : t_shifter_fsm;
   signal sig_shift_data      : std_logic;


   -- IO registers
   signal sig_din             : std_logic;
   signal sig_dout            : std_logic;
   signal sig_sclk            : std_logic;
   signal sig_enable          : std_logic;
   signal sig_led_colour      : t_vector24(0 to 2);
   signal sig_led_colour_reg  : t_vector24(0 to 2);

   -- Data MUX
   signal sig_led_r_pwm       : t_vector8(0 to 2);
   signal sig_led_g_pwm       : t_vector8(0 to 2);
   signal sig_led_b_pwm       : t_vector8(0 to 2);
   signal sig_write_data      : std_logic_vector(15 downto 0);

   -- Output Controller
   signal sig_divide_counter  : unsigned(con_counter_width-1 downto 0);
   signal sig_bit_counter     : unsigned(4 downto 0);
   signal sig_cs              : std_logic;
   signal sig_dout_shifter    : std_logic_vector(15 downto 0);
   signal sig_din_shifter     : std_logic_vector(15 downto 0);

begin


-------------------------------------------------------------------------------
--                             Output Flip Flops                             --
-------------------------------------------------------------------------------

din_reg: fd port map (c => clock, d => sig_din, q => din);
sclk_reg: fd port map (c => clock, d => sig_sclk, q => sclk);
cs_reg: fd port map (c => clock, d => sig_cs, q => cs);

dout_reg: fd port map (c => clock, d => dout, q => sig_dout);


-------------------------------------------------------------------------------
--                              Input Registers                              --
-------------------------------------------------------------------------------

   sig_led_colour(0) <= led1_colour;
   sig_led_colour(1) <= led2_colour;
   sig_led_colour(2) <= led3_colour;

register_gen: for i in 0 to 2 generate
   colour_reg: entity work.delay generic map(con_width   => 24, 
                                             con_cycles  => 1)
                                 port map(c              => clock,
                                          d              => sig_led_colour(i),
                                          q              => sig_led_colour_reg(i));
end generate;

enable_reg: fd port map (c => clock, d => enable, q => sig_enable);

-------------------------------------------------------------------------------
--                              Led State decoding                           --
-------------------------------------------------------------------------------

led_decode: process(clock)
      variable var_led_r_pwm     : t_vector8(0 to 2);
      variable var_led_g_pwm     : t_vector8(0 to 2);
      variable var_led_b_pwm     : t_vector8(0 to 2);
   begin
      if rising_edge(clock) then
         if sig_state = s_latch_data then
            for i in 0 to 2 loop
               
               -- Red
               case sig_led_colour_reg(i)(23 downto 16) is
                  when X"00" =>
                     var_led_r_pwm(i) := X"FF";                               -- Ouput in high impedance
                  when X"01" | X"02" =>
                     var_led_r_pwm(i) := X"03";                               -- Remap to 3/256 duty cycle
                  when X"FF" =>
                     var_led_r_pwm(i) := X"02";                               -- Constant current sink
                  when others =>
                     var_led_r_pwm(i) := sig_led_colour_reg(i)(23 downto 16); -- Map the duty cycle across
               end case;

               -- Green
               case sig_led_colour_reg(i)(15 downto 8) is
                  when X"00" =>
                     var_led_g_pwm(i) := X"FF";                               -- Ouput in high impedance
                  when X"01" | X"02" =>
                     var_led_g_pwm(i) := X"03";                               -- Remap to 3/256 duty cycle
                  when X"FF" =>
                     var_led_g_pwm(i) := X"02";                               -- Constant current sink
                  when others =>
                     var_led_g_pwm(i) := sig_led_colour_reg(i)(15 downto 8);  -- Map the duty cycle across
               end case;

               -- Blue
               case sig_led_colour_reg(i)(7 downto 0) is
                  when X"00" =>
                     var_led_b_pwm(i) := X"FF";                               -- Ouput in high impedance
                  when X"01" | X"02" =>
                     var_led_b_pwm(i) := X"03";                               -- Remap to 3/256 duty cycle
                  when X"FF" =>
                     var_led_b_pwm(i) := X"02";                               -- Constant current sink
                  when others =>
                     var_led_b_pwm(i) := sig_led_colour_reg(i)(7 downto 0);   -- Map the duty cycle across
               end case;
            end loop;
         end if;
      end if;
      sig_led_r_pwm <= var_led_r_pwm;
      sig_led_g_pwm <= var_led_g_pwm;
      sig_led_b_pwm <= var_led_b_pwm;
   end process;

-------------------------------------------------------------------------------
--                           Top Level State Machine                         --
-------------------------------------------------------------------------------

control_fsm: process(clock)
      variable var_state            : t_main_fsm;
      variable var_shift_data       : std_logic;
      variable var_register_index   : unsigned(3 downto 0);
      variable var_start_counter    : unsigned(27 downto 0);
      variable var_full_cycle       : std_logic;
   begin
      if rising_edge(clock) then
         var_shift_data := '0';
         var_full_cycle := '0';
         if reset = '1' or sig_enable = '0' then
            var_state := s_startup;
            var_register_index := (others => '0');
            var_start_counter := X"0FFFFFF";
         else
            case sig_state is
               --------------------------------------------
               when s_latch_data =>
                  var_state := s_update_outputs;
               when s_update_outputs =>
                  if sig_register_index = 9 then
                     var_register_index := (others => '0');
                     var_full_cycle := '1';
                     var_state := s_latch_data;
                  else
                     var_shift_data := '1';
                     var_state := s_update_outputs_wait;   
                  end if;
               when s_update_outputs_wait =>
                  if sig_shifter_state = s_complete then
                     var_register_index := var_register_index + 1;
                     var_state := s_update_outputs;
                  end if;
               --------------------------------------------
               when s_startup =>                                     -- Wait for a little while after FPGA configures
                  var_register_index := (others => '0');
                  var_start_counter := var_start_counter - 1;
                  if (sig_start_counter = 0 and con_simulation = false) or (sig_start_counter(15 downto 0) = 0 and con_simulation = true) then
                     var_state := s_load_configuration;
                  end if;
               --------------------------------------------
               when s_load_configuration =>                          -- Load constant current and global settings. Start the chips with all outputs enabled 
                  if sig_register_index = 7 then                     -- then ramp up. Afterwards the outputs revert to normal. Should make the leds all ramp
                     var_register_index := (others => '0');          -- up to white then turn off.
                     var_state := s_start_chips;
                  else
                     var_shift_data := '1';
                     var_state := s_load_configuration_wait;
                  end if;
               when s_load_configuration_wait =>
                  if sig_shifter_state = s_complete then
                     var_register_index := var_register_index + 1;
                     var_state := s_load_configuration;
                  end if;
               when s_start_chips =>                                 -- Ramp up all the LED outputs to the selected drive current
                  var_shift_data := '1';
                  var_state := s_start_chips_wait;
               when s_start_chips_wait =>
                  if sig_shifter_state = s_complete then
                     var_state := s_wait_ramp;
                     var_start_counter := (others => '1');
                  end if;
               when s_wait_ramp =>                                -- Wait for 2 seconds before we start writeing real data to chips
                  var_start_counter := var_start_counter - 1;
                  if (sig_start_counter = 0 and con_simulation = false) or (sig_start_counter(15 downto 0) = 0 and con_simulation = true) then
                     var_state := s_load_currents;
                  end if;
               when s_load_currents =>                               -- Update the global current settings to the right values after startup ramp
                  var_shift_data := '1';
                  var_state := s_load_currents_wait;
               when s_load_currents_wait =>
                  if sig_shifter_state = s_complete then
                     var_state := s_latch_data;
                     var_register_index := (others => '0');
                  end if;
            end case;
         end if;
      end if;
      sig_state <= var_state;
      sig_shift_data <= var_shift_data;
      
      sig_register_index <= var_register_index;
      sig_start_counter <= var_start_counter;
      
      full_cycle <= var_full_cycle;
   end process;

   -- Register address (MSB defines read/write 1 for read)
   sig_write_data(15 downto 8) <= X"10" when sig_state = s_load_configuration_wait and sig_register_index = 0 else
                                  X"11" when sig_state = s_load_configuration_wait and sig_register_index = 1 else
                                  X"12" when sig_state = s_load_configuration_wait and sig_register_index = 2 else
                                  X"15" when sig_state = s_load_configuration_wait and sig_register_index = 3 else
                                  X"0A" when sig_state = s_load_configuration_wait and sig_register_index = 4 else
                                  X"13" when sig_state = s_load_configuration_wait and sig_register_index = 5 else
                                  X"14" when sig_state = s_load_configuration_wait and sig_register_index = 6 else
                                  X"10" when sig_state = s_start_chips_wait else
                                  X"15" when sig_state = s_load_currents_wait else
                                  X"00" when sig_state = s_update_outputs_wait and sig_register_index = 0 else
                                  X"01" when sig_state = s_update_outputs_wait and sig_register_index = 1 else
                                  X"02" when sig_state = s_update_outputs_wait and sig_register_index = 2 else
                                  X"03" when sig_state = s_update_outputs_wait and sig_register_index = 3 else
                                  X"04" when sig_state = s_update_outputs_wait and sig_register_index = 4 else
                                  X"05" when sig_state = s_update_outputs_wait and sig_register_index = 5 else
                                  X"06" when sig_state = s_update_outputs_wait and sig_register_index = 6 else
                                  X"07" when sig_state = s_update_outputs_wait and sig_register_index = 7 else
                                  X"08" when sig_state = s_update_outputs_wait and sig_register_index = 8 else
                                  X"00";
   
   -- Register Data
   sig_write_data(7 downto 0) <= con_configuration and X"FC"      when sig_state = s_load_configuration_wait and sig_register_index = 0 else
                                 con_ramp_down                    when sig_state = s_load_configuration_wait and sig_register_index = 1 else
                                 con_ramp_up                      when sig_state = s_load_configuration_wait and sig_register_index = 2 else
                                 X"07"                            when sig_state = s_load_configuration_wait and sig_register_index = 3 else
                                 X"02"                            when sig_state = s_load_configuration_wait and sig_register_index = 4 else
                                 con_current_select(7 downto 0)   when sig_state = s_load_configuration_wait and sig_register_index = 5 else
                                 "000000" & con_current_select(9 downto 8) when sig_state = s_load_configuration_wait and sig_register_index = 6 else
                                 con_configuration or X"05"       when sig_state = s_start_chips_wait else
                                 con_global_current               when sig_state = s_load_currents_wait else
                                 sig_led_r_pwm(0)                 when sig_state = s_update_outputs_wait and sig_register_index = 0 else 
                                 sig_led_b_pwm(0)                 when sig_state = s_update_outputs_wait and sig_register_index = 1 else 
                                 sig_led_g_pwm(0)                 when sig_state = s_update_outputs_wait and sig_register_index = 2 else 
                                 sig_led_r_pwm(1)                 when sig_state = s_update_outputs_wait and sig_register_index = 3 else 
                                 sig_led_b_pwm(1)                 when sig_state = s_update_outputs_wait and sig_register_index = 4 else 
                                 sig_led_g_pwm(1)                 when sig_state = s_update_outputs_wait and sig_register_index = 5 else 
                                 sig_led_r_pwm(2)                 when sig_state = s_update_outputs_wait and sig_register_index = 6 else 
                                 sig_led_b_pwm(2)                 when sig_state = s_update_outputs_wait and sig_register_index = 7 else 
                                 sig_led_g_pwm(2)                 when sig_state = s_update_outputs_wait and sig_register_index = 8 else 
                                 X"00";

-------------------------------------------------------------------------------
--                               Data Shifter                                --
-------------------------------------------------------------------------------

data_shifter: process(clock)
      variable var_shifter_state    : t_shifter_fsm;
      variable var_din_shifter      : std_logic_vector(15 downto 0);
      variable var_dout_shifter     : std_logic_vector(15 downto 0);
      variable var_bit_counter      : unsigned(4 downto 0);
      variable var_divide_counter   : unsigned(con_counter_width-1 downto 0);
   begin
      if rising_edge(clock) then
         var_divide_counter := var_divide_counter + 1;
         
         -- Clock generation state machine
         case sig_shifter_state is
            when s_idle =>
               var_din_shifter := sig_write_data;
               var_bit_counter := (others => '0');
               if sig_shift_data = '1' then
                  var_shifter_state := s_chip_select_low;
                  var_divide_counter := (others => '0');
               end if;
            when s_chip_select_low =>                                -- Drop chip select low
               if sig_divide_counter = con_tcss_cnt then
                  var_shifter_state := s_clock_high;
                  var_divide_counter := (others => '0');
               end if;
            when s_clock_high =>
               if sig_divide_counter = con_tch_cnt then
                  var_shifter_state := s_clock_low;
                  var_divide_counter := (others => '0');
               end if;
            when s_clock_low =>
               if sig_divide_counter = con_tcl_cnt then
                  if sig_bit_counter = 16 then
                     var_shifter_state := s_chip_select_high;
                     var_divide_counter := (others => '0');
                  else
                     var_shifter_state := s_clock_high;
                     var_divide_counter := (others => '0');
                  end if;
               end if;
            when s_chip_select_high =>
               if sig_divide_counter = con_tcsw_cnt then
                  var_shifter_state := s_complete;
               end if;
            when s_complete =>
               var_shifter_state := s_idle;
         end case;
            
         -- Data output shifter (changes on falling clock edge)
         if sig_shifter_state = s_clock_low and sig_divide_counter = 0 then
            var_din_shifter := var_din_shifter(14 downto 0) & '0';
            var_bit_counter := var_bit_counter + 1;
         end if;
            
         -- Data input shifter
         if (sig_shifter_state = s_clock_high and sig_divide_counter = 0) or 
            (sig_shifter_state = s_chip_select_high and sig_divide_counter = con_tdo_cnt) then
            var_dout_shifter := var_din_shifter(14 downto 0) & sig_dout;
         end if;
            
      end if;
      sig_shifter_state <= var_shifter_state;
      
      sig_bit_counter <= var_bit_counter;
      sig_divide_counter <= var_divide_counter;
      
      sig_dout_shifter <= var_dout_shifter;
      sig_din_shifter <= var_din_shifter;
   end process;
               
   sig_din <= sig_din_shifter(15);
               
   sig_cs <= '1' when sig_shifter_state = s_idle or sig_shifter_state = s_complete else '0';

   sig_sclk <= '1' when sig_shifter_state = s_clock_high else '0';

end structure;