----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    09:10:43 06/22/2006
-- Design Name:
-- Module Name:    dev_si7020 - Structure
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:    Simple simulation of a si7020 sensor
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

entity dev_si7020 is
   generic (
      dev_name    : string;                                          -- For display purposes
      tconv_rh    : time := 12 ms;
      tconv_temp  : time := 10.8 ms;
      tckl        : time := 1.3 us;
      tckh        : time := 0.6 us;
      tsusta      : time := 0.6 us;                                  -- Min Repeat Start Setup time
      tsth        : time := 0.6 us;                                  -- Min Start Hold time
      tdh         : time := 100 ns;                                  -- Min Data hold time
      tds         : time := 100 ns;                                  -- Min Data setup time
      tsps        : time := 0.6 us;                                  -- Min Stop Setup time
      tbuf        : time := 1.3 us);                                 -- Min Free time between stop and start


   port (
      sda         : inout std_logic;
      scl         : inOUT std_logic);
end dev_si7020;

architecture structure of dev_si7020 is

   type t_i2c_states is (s_address,
                         s_command,
                         s_recieve,
                         s_send);

   signal sig_start_detected        : std_logic;
   signal sig_stop_detected         : std_logic;
   signal sig_sequence_running      : std_logic;

   signal sig_data_enable           : std_logic;
   signal sig_data_in               : std_logic;
   signal sig_unit_address          : std_logic_vector(6 downto 0);

   signal sig_bit_counter           : integer;
   signal wait_measurement           : std_logic := '0';
   signal block_measurement         : std_logic := '0';
   signal stretch                   : std_logic := '0';


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
         if now < startedge + tsth then
            write(myline, string'("ERROR: "));
            write(myline, dev_name);
            write(myline, string'(" timing violated, tsth too small, required "));
            write(myline, tsth);
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
            if stopedge < clockedge + tsps then
               write(myline, string'("ERROR: "));
               write(myline, dev_name);
               write(myline, string'(" timing violated, tsps too small, required "));
               write(myline, tsps);
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
               write(myline, string'("ERROR: "));
               write(myline, dev_name);
               write(myline, string'(" timing violated, tSUSTA too small, required "));
               write(myline, tsusta);
               write(myline, string'(" but got "));
               write(myline, startedge - clockedge);
               write(myline, string'(" @ "));
               write(myline, now);
               writeline(output, myline);
            end if;
            if firstcycle = '0' then
               if startedge < (stopedge + tbuf) then
                  write(myline, string'("ERROR: "));
                  write(myline, dev_name);
                  write(myline, string'(" timing violated, tBUF too small, required "));
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

max6620: process(scl, sig_sequence_running, sig_start_detected)

      -- Registers
      variable var_state         : t_i2c_states := s_address;
      variable i2c_address       : std_logic_vector(7 downto 0) := X"00";
      variable i2c_command       : std_logic_vector(7 downto 0) := X"00";
      variable i2c_data          : std_logic_vector(15 downto 0) := X"0000";
      variable var_output_data   : std_logic_vector(63 downto 0);
      variable var_bit_counter   : integer := 0;
      variable var_send_ack      : std_logic := '0';
      VARIABLE user_reg          : std_logic_vector(7 downto 0) := X"00";

      variable byte_counter      : integer;
      variable expected_bytes    : integer;
      variable myline            : line;
   begin
      if sig_sequence_running = '0' then                             -- If a start byte hasn't been detected
         var_state := s_address;
         var_bit_counter := 0;
      elsif sig_start_detected = '1' then                            -- On a start reset the current condition (repeated start)
         var_state := s_address;
         var_bit_counter := 0;
      elsif rising_edge(scl) then                                    -- On the rising edge of the scl
         case var_state is
            when s_address =>
               wait_measurement <= '0';
               byte_counter := 0;

               if var_bit_counter /= 55 and block_measurement = '0' then
                  i2c_address := i2c_address(6 downto 0) & to_x01(sda);
                  if var_bit_counter = 7 then                        -- s_send ACK, check s_address and select the correct register if reading
                     if i2c_address(7 downto 1) = "1000000" then
                        var_send_ack := '1';

                        if i2c_address(0) = '1' then
--                           write(myline, string'("INFO: "));
--                           write(myline, dev_name);
--                           write(myline, string'(" Command 0x"));
--                           hwrite(myline, i2c_command);
--                           writeline(output, myline);


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
               i2c_data := (OTHERS => '0');
               if var_bit_counter = 8 then
                     write(myline, string'("INFO: "));
                     write(myline, dev_name);
                     write(myline, string'(" Got command 0x"));
                     hwrite(myline, i2c_command);
                     write(myline, string'(" @ "));
                     write(myline, now);
                     writeline(output, myline);

                  -- No bytes
                  if i2c_command = X"FE" then
                     var_send_ack := '1';
                     expected_bytes := 0;

                     write(myline, string'("INFO: "));
                     write(myline, dev_name);
                     write(myline, string'(" Reset recieved"));
                     writeline(output, myline);
                     var_bit_counter := 55;
                     var_state := s_address;

                  -- Write 1 byte
                  elsif i2c_command = X"E6" then
                     var_send_ack := '1';                                   -- s_send ACK
                     expected_bytes := 1;
                     var_state := s_recieve;
                     var_bit_counter := 0;

                  -- Read N bytes but with data first
                  elsif i2c_command = X"FA" OR i2c_command = X"FC" OR i2c_command = X"84" then
                     var_send_ack := '1';                                   -- s_send ACK
                     expected_bytes := 1;
                     var_state := s_recieve;
                     var_bit_counter := 0;

                  -- Read 1 byte
                  elsif i2c_command = X"E7" THEN
                     var_send_ack := '1';
                     var_bit_counter := 55;
                     var_state := s_address;
                     expected_bytes := 1;

                  -- Read 2 bytes
                  elsif i2c_command = X"E5" or i2c_command = X"F5" or i2c_command = X"E3" or i2c_command = X"F3" or
                        i2c_command = X"E0" then
                     var_send_ack := '1';
                     var_bit_counter := 55;

                     IF i2c_command = X"E5" OR i2c_command = X"E3" THEN
                        stretch <= '1';
                        wait_measurement <= '1';
                     ELSIF i2c_command = X"F5" OR i2c_command = X"F3" THEN
                        stretch <= '0';
                        wait_measurement <= '1';
                     ELSE
                        stretch <= '0';
                        wait_measurement <= '0';
                     END IF;

                     var_state := s_address;
                     expected_bytes := 2;
                  else
                     write(myline, string'("WARNING: "));
                     write(myline, dev_name);
                     write(myline, string'(" Bad command recieved 0x"));
                     hwrite(myline, i2c_command);
                     write(myline, string'(" @ "));
                     write(myline, now);
                     writeline(output, myline);
                     var_bit_counter := 55;
                     var_state := s_address;
                  end if;
               else
                  var_bit_counter := var_bit_counter + 1;
               end if;
            when s_recieve =>
               i2c_data := i2c_data(14 downto 0) & to_x01(sda);
               if var_bit_counter = 8 then
                  var_send_ack := '1';                                   -- s_send ACK
                  expected_bytes := expected_bytes - 1;
                  if expected_bytes = 0 then
                     IF i2c_command = X"FA" THEN
                        IF i2c_data(7 DOWNTO 0) /= X"0F" THEN
                           write(myline, string'("ERROR: "));
                           write(myline, dev_name);
                           write(myline, string'(" Unexpected value of 0x"));
                           hwrite(myline, i2c_data);
                           writeline(output, myline);
                        ELSE
                           expected_bytes := 8;
                        END IF;
                     ELSIF i2c_command = X"FC" THEN
                        IF i2c_data(7 DOWNTO 0) /= X"C9" THEN
                           write(myline, string'("ERROR: "));
                           write(myline, dev_name);
                           write(myline, string'(" Unexpected value of 0x"));
                           hwrite(myline, i2c_data);
                           writeline(output, myline);
                        ELSE
                           expected_bytes := 6;
                        END IF;
                     ELSIF i2c_command = X"84" THEN
                        IF i2c_data(7 DOWNTO 0) /= X"B8" THEN
                           write(myline, string'("ERROR: "));
                           write(myline, dev_name);
                           write(myline, string'(" Unexpected value of 0x"));
                           hwrite(myline, i2c_data);
                           writeline(output, myline);
                        ELSE
                           expected_bytes := 1;
                        END IF;
                     ELSE
                        user_reg := i2c_data(7 DOWNTO 0);

                        write(myline, string'("INFO: "));
                        write(myline, dev_name);
                        write(myline, string'(" Wrote value 0x"));
                        hwrite(myline, i2c_data);
                        write(myline, string'(" to user register"));
                        writeline(output, myline);
                     END IF;
                     var_bit_counter := 0;
                  end if;
               else
                  var_bit_counter := var_bit_counter + 1;
               end if;
            when s_send =>
               if var_bit_counter = 9 then
                  if to_x01(sda) = '1' then
                     var_bit_counter := 55;
                     var_state := s_address;
                  else
                     var_bit_counter := 0;
                     expected_bytes := expected_bytes - 1;
                     byte_counter := byte_counter + 1;
                     if expected_bytes = 0 then
                        var_bit_counter := 55;
                        var_state := s_address;
                     end if;
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
                     when X"E5"|X"F5"        => var_output_data := X"8B44000000000000";
                     when X"E3"|X"F3"|X"E0"  => var_output_data := X"6A6D000000000000";
                     when X"E7"              => var_output_data := user_reg & X"00000000000000";
                     when X"FA"              => var_output_data := X"1122334455667788";
                     when X"FC"              => var_output_data := X"99aabbccddee0000";
                     when X"84"              => var_output_data := X"FF00000000000000";
                     when others             => var_output_data := X"0000000000000000";
                  end case;

                  -- LSByte comes first
                  sig_data_enable <= var_output_data(7-var_bit_counter+((7-byte_counter)*8));
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

sig_data_in <= sda;

   process
   begin
      sda <= 'Z';

      update_loop: loop
         wait until sig_data_enable'event;
         wait for tdh;
         if sig_data_enable = '0' then
            sda <= '0';
         else
            sda <= 'Z';
         end if;
      end loop;
   end process;


   process
   begin
      wait until rising_edge(wait_measurement);
      wait until falling_edge(scl);                -- End of current data cycle
      wait until falling_edge(scl);                -- End of ack cycle
      block_measurement <= '1';
      wait for tconv_rh;
      wait for tconv_temp;
      block_measurement <= '0';
   end process;


   scl <= '0' WHEN (block_measurement = '1' AND stretch = '1') ELSE 'Z';

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

      IF lowCycle < tckl THEN
         write(myline, string'("ERROR: "));
         write(myline, dev_name);
         write(myline, string'(" timing violated, tckl too small, required "));
         write(myline, tckl);
         write(myline, string'(" but got "));
         write(myline, lowCycle);
         write(myline, string'(" @ "));
         write(myline, now);
         writeline(output, myline);
      ELSIF highCycle < tckh THEN
         write(myline, string'("ERROR: "));
         write(myline, dev_name);
         write(myline, string'(" timing violated, tckh too small, required "));
         write(myline, tckh);
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

      IF clockChange < dataChange + tds THEN
         write(myline, string'("ERROR: "));
         write(myline, dev_name);
         write(myline, string'(" timing violated, tds too small, required "));
         write(myline, tds);
         write(myline, string'(" but got "));
         write(myline, clockChange - dataChange);
         write(myline, string'(" @ "));
         write(myline, now);
         writeline(output, myline);
      END IF;

   END PROCESS;

END Structure;

