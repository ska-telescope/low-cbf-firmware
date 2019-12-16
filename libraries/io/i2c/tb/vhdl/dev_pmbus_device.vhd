----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    09:10:43 06/22/2006
-- Design Name:
-- Module Name:    dev_pmbus_device - Structure
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:    Simple simulation of a  PMBus interface
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

entity dev_pmbus_device is
   generic (
      dev_name    : string;                                          -- For display purposes
      tlow        : time := 1.3 us;
      thigh       : time := 0.6 us;
      tsusta      : time := 0.6 us;                                  -- Min Repeat Start Setup time
      thdsta      : time := 0.6 us;                                  -- Min Start Hold time
      thddat      : time := 900 ns;                                  -- Min Data hold time
      tsudat      : time := 100 ns;                                  -- Min Data setup time
      tsusto      : time := 0.6 us;                                  -- Min Stop Setup time
      tbuf        : time := 1.6 us);                                 -- Min Free time between stop and start

   port (
      address     : in std_logic_vector(6 downto 0);

      sda         : inout std_logic;
      scl         : in std_logic);
end dev_pmbus_device;

architecture structure of dev_pmbus_device is

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
            write(myline, string'("ERROR: "));
            write(myline, dev_name);
            write(myline, string'(" timing violated, tHDSTA too small, required "));
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
               write(myline, string'("ERROR: "));
               write(myline, dev_name);
               write(myline, string'(" timing violated, tSUSTO too small, required "));
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
      variable var_output_data   : std_logic_vector(15 downto 0);  
      variable var_bit_counter   : integer := 0;
      variable var_send_ack      : std_logic := '0';
      variable i2c_page          : std_logic := '0';

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
               if var_bit_counter /= 55 then
                  i2c_address := i2c_address(6 downto 0) & to_x01(sda);
                  if var_bit_counter = 7 then                        -- s_send ACK, check s_address and select the correct register if reading
                     if i2c_address(7 downto 1) = address then
                        var_send_ack := '1';
                        if i2c_address(0) = '1' then
                           write(myline, string'("INFO: "));
                           write(myline, dev_name);
                           if i2c_page = '1' then
                              write(myline, string'(" On Page 1"));
                           end if;
                           write(myline, string'(" Read of register 0x"));
                           hwrite(myline, i2c_command);
                           writeline(output, myline);
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
               byte_counter := 0;
               i2c_command := i2c_command(6 downto 0) & to_x01(sda);
               i2c_data := (OTHERS => '0');
               if var_bit_counter = 8 then
                  -- No bytes
                  if i2c_command = X"03" or i2c_command = X"11" or i2c_command = X"12" then
                     var_send_ack := '1';
                     expected_bytes := 0;
                     
                     write(myline, string'("INFO: "));
                     write(myline, dev_name);
                     write(myline, string'(" No data command, register 0x"));
                     hwrite(myline, i2c_command);
                     writeline(output, myline);
                     var_bit_counter := 55;
                     var_state := s_address;                 
                  elsif i2c_command = X"00" or i2c_command = X"01" or i2c_command = X"02" or i2c_command = X"10" or 
                        i2c_command = X"13" or i2c_command = X"14" or i2c_command = X"20" or i2c_command = X"41" or 
                        i2c_command = X"45" or i2c_command = X"78" or i2c_command = X"7a" or i2c_command = X"7b" or 
                        i2c_command = X"7d" or i2c_command = X"7e" or i2c_command = X"98" then
                     var_send_ack := '1';                                   -- s_send ACK
                     expected_bytes := 1;
                     var_state := s_recieve;
                     var_bit_counter := 0;
                  elsif i2c_command = X"22" or i2c_command = X"25" or i2c_command = X"26" or i2c_command = X"29" or 
                        i2c_command = X"35" or i2c_command = X"36" or i2c_command = X"38" or i2c_command = X"39" or 
                        i2c_command = X"40" or i2c_command = X"44" or i2c_command = X"4a" or i2c_command = X"5e" or 
                        i2c_command = X"5f" or i2c_command = X"61" or i2c_command = X"79" or i2c_command = X"88" or 
                        i2c_command = X"8b" or i2c_command = X"8c" or i2c_command = X"8d" or i2c_command = X"8e" or 
                        i2c_command = X"a0" or i2c_command = X"a4" or i2c_command = X"d0" or i2c_command = X"d4" or 
                        i2c_command = X"d5" or i2c_command = X"d6" or i2c_command = X"d7" then
                     var_send_ack := '1';                                   -- s_send ACK
                     expected_bytes := 2;
                     var_state := s_recieve;
                     var_bit_counter := 0;
                  else
                     write(myline, string'("WARNING: "));
                     write(myline, dev_name);
                     write(myline, string'(" Bad Register Value, recieved 0x"));
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
                     if i2c_command = X"00" then
                        i2c_page := i2c_data(0);                           -- Set page
                     else
                        write(myline, string'("INFO: "));
                        write(myline, dev_name);
                        write(myline, string'(" Wrote value 0x"));
                        hwrite(myline, i2c_data);
                        write(myline, string'(" to register 0x"));
                        hwrite(myline, i2c_command);
                        writeline(output, myline);
                     end if;
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
                     when X"01" => var_output_data := X"0000";
                     when X"02" => var_output_data := X"1717";
                     when X"10" => var_output_data := X"0000";
                     when X"20" => var_output_data := X"1616";
                     when X"22" => var_output_data := X"0000";
                     when X"25" => var_output_data := X"4747";
                     when X"26" => var_output_data := X"5151";
                     when X"29" => var_output_data := X"0000";
                     when X"35" => var_output_data := X"0b0b";
                     when X"36" => var_output_data := X"0a0a";
                     when X"38" => var_output_data := X"0000";
                     when X"39" => var_output_data := X"0000";
                     when X"40" => var_output_data := X"0a0a";
                     when X"41" => var_output_data := X"fcfc";
                     when X"44" => var_output_data := X"8f8f";
                     when X"45" => var_output_data := X"0404";
                     when X"4a" => var_output_data := X"1b6b";
                     when X"5e" => var_output_data := X"6a6a";
                     when X"5f" => var_output_data := X"5252";
                     when X"61" => var_output_data := X"2a2a";
                     when X"78" => var_output_data := X"0000";
                     when X"79" => var_output_data := X"0000";    -- Status word
                     when X"7a" => var_output_data := X"0000";
                     when X"7b" => var_output_data := X"0000";
                     when X"7d" => var_output_data := X"0000";
                     when X"7e" => var_output_data := X"0000";
                     when X"88" => var_output_data := X"d301";    -- Vin 12.02
                     when X"8b" => var_output_data := X"BA66";    -- Vout 1.2
                     when X"8c" => var_output_data := X"8A0C";    -- Iout 0.016A
                     when X"8d" => var_output_data := X"def0";    -- Temp 1 55.5
                     when X"8e" => var_output_data := X"DBCF";    -- Temp 2 30.47
                     when X"98" => var_output_data := X"1111";
                     when X"a0" => var_output_data := X"0c0c";
                     when X"a4" => var_output_data := X"6666";
                     when X"d0" => var_output_data := X"0606";
                     when X"d4" => var_output_data := X"0000";
                     when X"d5" => var_output_data := X"0000";
                     when X"d6" => var_output_data := X"0000";
                     when X"d7" => var_output_data := X"0000";
                     when others => var_output_data := X"0000";
                  end case;

                  -- LSByte comes first
                  sig_data_enable <= var_output_data(7-var_bit_counter+(byte_counter*8));
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
         wait for thddat;
         if sig_data_enable = '0' then
            sda <= '0';
         else
            sda <= 'Z';
         end if;
      end loop;
   end process;



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
         write(myline, string'("ERROR: "));
         write(myline, dev_name);
         write(myline, string'(" timing violated, tLOW too small, required "));
         write(myline, tLOW);
         write(myline, string'(" but got "));
         write(myline, lowCycle);
         write(myline, string'(" @ "));
         write(myline, now);
         writeline(output, myline);
      ELSIF highCycle < tHIGH THEN
         write(myline, string'("ERROR: "));
         write(myline, dev_name);
         write(myline, string'(" timing violated, tHIGH too small, required "));
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
         write(myline, string'("ERROR: "));
         write(myline, dev_name);
         write(myline, string'(" timing violated, tSUDAT too small, required "));
         write(myline, tSUDAT);
         write(myline, string'(" but got "));
         write(myline, clockChange - dataChange);
         write(myline, string'(" @ "));
         write(myline, now);
         writeline(output, myline);
      END IF;

   END PROCESS;

END Structure;

