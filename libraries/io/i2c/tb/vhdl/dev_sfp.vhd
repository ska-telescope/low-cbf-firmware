----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    09:10:43 06/22/2006
-- Design Name:
-- Module Name:    SFP - Structure
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:    Simple simulation of a SFP module
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity dev_sfp is
   generic (
      dev_name    : string;                                          -- For display purposes
      tlow        : time := 1.3 us;
      thigh       : time := 0.6 us;
      tsusta      : time := 0.6 us;                                  -- Min Repeat Start Setup time
      thdsta      : time := 0.6 us;                                  -- Min Start Hold time
      thddat      : time := 900 ns;                                  -- Min Data hold time
      tsudat      : time := 100 ns;                                  -- Min Data setup time
      tsusto      : time := 0.6 us;                                  -- Min Stop Setup time
      tbuf        : time := 1.6 us);                                  -- Min Free time between stop and start

   port (
      sda         : inout std_logic;
      scl         : in std_logic);
end dev_sfp;

architecture structure of dev_sfp is

   type t_i2c_states is (s_address,
                         s_command,
                         s_recieve,
                         s_send);

   signal sig_start_detected        : std_logic;
   signal sig_stop_detected         : std_logic;
   signal sig_sequence_running      : std_logic;

   signal sig_data_enable           : std_logic;
   signal sig_data_in               : std_logic;

   signal sig_bit_counter           : integer;

begin

start_stop: process(scl, sda)
      variable stopedge : time;
      variable clockedge : time;
      variable startedge : time;
      variable firstcycle : std_logic := '1';
      variable myline : line;
   begin
      if rising_edge(scl) then
         clockedge := now;
      elsif falling_edge(scl) then
         if now < startedge + thdsta then
            write(myline, string'("ERROR: SFP "));
            write(myline, dev_name);
            write(myline, string'(" - timing violated, tHDSTA too small, required "));
            write(myline, thdsta);
            write(myline, string'(" but got "));
            write(myline, now - startedge);
            write(myline, string'(" @ "));
            write(myline, now);
            writeline(output, myline);
         end if;
      end if;
      if scl /= '0' then
         if rising_edge(sda) then
            firstcycle := '0';
            stopedge := now;
            if stopedge < clockedge + tsusto then
               write(myline, string'("ERROR: SFP "));
               write(myline, dev_name);
               write(myline, string'(" - timing violated, tSUSTO too small, required "));
               write(myline, tsusto);
               write(myline, string'(" but got "));
               write(myline, stopedge - clockedge);
               write(myline, string'(" @ "));
               write(myline, now);
               writeline(output, myline);
            end if;
            sig_stop_detected <= '1';
            sig_start_detected <= '0';
         elsif falling_edge(sda) then
            startedge := now;
            if startedge < clockedge + tsusta then
               write(myline, string'("ERROR: SFP "));
               write(myline, dev_name);
               write(myline, string'(" - timing violated, tSUSTA too small, required "));
               write(myline, tsusta);
               write(myline, string'(" but got "));
               write(myline, startedge - clockedge);
               write(myline, string'(" @ "));
               write(myline, now);
               writeline(output, myline);
            end if;
            if firstcycle = '0' then
               if startedge < (stopedge + tbuf) then
                  write(myline, string'("ERROR: SFP "));
                  write(myline, dev_name);
                  write(myline, string'(" - timing violated, tBUF too small, required "));
                  write(myline, tbuf);
                  write(myline, string'(" but got "));
                  write(myline, startedge - stopedge);
                  write(myline, string'(" @ "));
                  write(myline, now);
                  writeline(output, myline);
               end if;
            end if;
            sig_start_detected <= '1';
            sig_stop_detected <= '0';
         end if;
      else
         sig_start_detected <= '0';
         sig_stop_detected <= '0';
      end if;
   end process;


state: process(sig_start_detected, sig_stop_detected)
   begin
      if sig_start_detected = '1' then
         sig_sequence_running <= '1';
      elsif sig_stop_detected = '1' then
         sig_sequence_running <= '0';
      end if;
   end process;

main_fsm: process(scl, sig_sequence_running, sig_start_detected)


      variable var_state         : t_i2c_states := s_address;
      variable i2c_address       : std_logic_vector(7 downto 0) := X"00";
      variable i2c_command       : std_logic_vector(7 downto 0) := X"00";
      variable i2c_data          : std_logic_vector(7 downto 0) := X"00";
      variable var_output_data   : std_logic_vector(7 downto 0) := X"00";
      variable var_bit_counter   : integer := 0;
      variable var_send_ack      : std_logic := '0';

      variable myline : line;
   begin
      if sig_sequence_running = '0' then                             -- If a start byte hasn't been detected
         var_state := s_address;
         var_bit_counter := 0;
      elsif sig_start_detected = '1' then                            -- On a start reset the current condition (repeated start)
         var_state := s_address;
         var_bit_counter := 0;
      elsif rising_edge(scl) then   -- On the rising edge of the scl
         case var_state is
            when s_address =>
               if var_bit_counter /= 55 then
                  i2c_address := i2c_address(6 downto 0) & to_x01(sda);
                  if var_bit_counter = 7 then                        -- s_send ACK, check s_address and select the correct register if reading
                     if i2c_address(7 downto 1) = "1010001" then
                        var_send_ack := '1';
                        if i2c_address(0) = '1' then
                           var_state := s_send;
                           var_bit_counter := 0;
                        else
                           var_state := s_command;
                           var_bit_counter := 0;
                        end if;
                     else
                        var_bit_counter := 55;        -- Stop state machine
                     end if;
                  else
                     var_bit_counter := var_bit_counter + 1;
                  end if;
               end if;
            when s_command =>
               i2c_command := i2c_command(6 downto 0) & to_x01(sda);
               i2c_data := (others => '0');
               if var_bit_counter = 8 then
                  var_send_ack := '1';                                   -- s_send ACK
                  var_state := s_recieve;
                  var_bit_counter := 0;
               else
                  var_bit_counter := var_bit_counter + 1;
               end if;
            when s_recieve =>
               i2c_data := i2c_data(6 downto 0) & to_x01(sda);
               if var_bit_counter = 8 then
                  var_send_ack := '1';                                   -- s_send ACK
                  write(myline, string'("INFO: SFP "));
                  write(myline, dev_name);
                  write(myline, string'(" - Wrote value 0x"));
                  hwrite(myline, i2c_data);
                  write(myline, string'(" to register "));
                  write(myline, to_integer(unsigned(i2c_command)));
                  writeline(output, myline);
                  var_bit_counter := 0;

                  i2c_command := i2c_command + 1;
               else
                  var_bit_counter := var_bit_counter + 1;
               end if;
            when s_send =>
               if var_bit_counter = 9 then
                  write(myline, string'("INFO: SFP "));
                  write(myline, dev_name);
                  write(myline, string'(" - Read of register "));
                  write(myline, to_integer(unsigned(i2c_command)));
                  writeline(output, myline);
                  if to_x01(sda) = '1' then
                     var_bit_counter := 55;
                     var_state := s_address;
                  else
                     var_bit_counter := 0;
                     i2c_command := i2c_command + 1;
                  end if;
               end if;
         end case;
      elsif falling_edge(scl) then                                   -- Output setup occurs on the falling edge of the scl
         if var_send_ack = '1' then                                  -- s_send an ack byte, drag the bus low for a clock cycle
            sig_data_enable <= '0';
            var_send_ack := '0';
         else
            if var_state /= s_send then                              -- If we are not sending then keep the line tristated
               sig_data_enable <= '1';
            else
               if var_bit_counter < 8 then                           -- For the data transmission
                  case i2c_command is

                     when X"4a" => var_output_data := X"6b";
                     when X"4b" => var_output_data := X"1b";

                     when X"60" => var_output_data := X"02";         -- Temperature
                     when X"61" => var_output_data := X"0C";

                     when X"62" => var_output_data := X"03";         -- Voltage
                     when X"63" => var_output_data := X"01";

                     when X"64" => var_output_data := X"00";         -- TX Bias
                     when X"65" => var_output_data := X"1A";

                     when X"66" => var_output_data := X"02";         -- TX Power
                     when X"67" => var_output_data := X"66";

                     when X"68" => var_output_data := X"00";         -- RX Power
                     when X"69" => var_output_data := X"17";



                     when others => var_output_data := X"00";
                  end case;
                  sig_data_enable <= var_output_data(7-var_bit_counter);
               else
                  sig_data_enable <= '1';
               end if;
               var_bit_counter := var_bit_counter + 1;
            end if;
         end if;
      end if;
      sig_bit_counter <= var_bit_counter;
   end process;

-- Tristate Drivers

sig_data_in <= SDA;

   PROCESS
   BEGIN
      SDA <= 'Z';

      UPDATE_LOOP: LOOP
         WAIT UNTIL sig_data_enable'EVENT;
         WAIT FOR tHDDAT;
         IF sig_data_enable = '0' THEN
            SDA <= '0';
         ELSE
            SDA <= 'Z';
         END IF;
      END LOOP;
   END PROCESS;



---------------------------------------------------------------------
-- Timing validation
---------------------------------------------------------------------

CLOCK_CHECK:
   PROCESS
      VARIABLE cycleStart, cycleMidpoint, cycleEnd : time;
      VARIABLE highCycle, lowCycle : TIME;
      VARIABLE myline : LINE;
   BEGIN
      WAIT UNTIL rising_edge(SCL);
      cycleStart := now;
      WAIT UNTIL falling_edge(SCL);
      cycleMidpoint := now;
      WAIT UNTIL rising_edge(SCL);
      cycleEnd := now;

      -- Calculate period and frequency
      highCycle := cycleMidpoint - cycleStart;
      lowCycle := cycleEnd - cycleMidpoint;

      IF lowCycle < tLOW THEN
         write(myline, string'("ERROR: SFP "));
         write(myline, DEV_NAME);
         write(myline, string'(" - timing violated, tLOW too small, required "));
         write(myline, tLOW);
         write(myline, string'(" but got "));
         write(myline, lowCycle);
         write(myline, string'(" @ "));
         write(myline, now);
         writeline(output, myline);
      ELSIF highCycle < tHIGH THEN
         write(myline, string'("ERROR: SFP "));
         write(myline, DEV_NAME);
         write(myline, string'(" - timing violated, tHIGH too small, required "));
         write(myline, tHIGH);
         write(myline, string'(" but got "));
         write(myline, highCycle);
         write(myline, string'(" @ "));
         write(myline, now);
         writeline(output, myline);
      END IF;
   END PROCESS;

DATA_SETUP:
   PROCESS
      VARIABLE myline : LINE;
      VARIABLE dataChange,clockChange : TIME;
   BEGIN
      WAIT UNTIL SDA'EVENT AND sig_data_enable = '1';
      dataChange := now;
      WAIT UNTIL rising_edge(SCL);
      clockChange := now;

      IF clockChange < dataChange + tSUDAT THEN
         write(myline, string'("ERROR: SFP "));
         write(myline, DEV_NAME);
         write(myline, string'(" - timing violated, tSUDAT too small, required "));
         write(myline, tSUDAT);
         write(myline, string'(" but got "));
         write(myline, clockChange - dataChange);
         write(myline, string'(" @ "));
         write(myline, now);
         writeline(output, myline);
      END IF;

   END PROCESS;



END Structure;

