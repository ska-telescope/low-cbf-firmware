----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    09:10:43 06/22/2006
-- Design Name:
-- Module Name:    OBT - Structure
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:    Simple simulation of a FCI Leap module
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
library ieee, common_lib;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use common_lib.common_pkg.ALL;

entity dev_obt is
   generic (
      dev_name    : string;                                          -- For display purposes
      tlow        : time := 1.3 us;
      thigh       : time := 0.6 us;
      tsusta      : time := 0.6 us;                                  -- Min Repeat Start Setup time
      thdsta      : time := 0.6 us;                                  -- Min Start Hold time
      thddat      : time := 0 ns;                                  -- Min Data hold time
      tsudat      : time := 250 ns;                                  -- Min Data setup time
      tsusto      : time := 0.6 us;                                  -- Min Stop Setup time
      tbuf        : time := 20 us;                                  -- Min Free time between stop and start
      tClkhold    : time := 500 us;                                 -- Max clock hold time
      t_reset_init: time := 2 us);                                   -- Min reset pulse length

   port (
      a           : in std_logic_vector(3 downto 0);

      reset_n     : in std_logic;

      sda         : inout std_logic;
      scl         : inout std_logic);
end dev_obt;

architecture structure of dev_obt is

   type t_i2c_states is (s_address,
                         s_command,
                         s_recieve,
                         s_send);

   signal sig_state                 : t_i2c_states;
   signal sig_start_detected        : std_logic;
   signal sig_stop_detected         : std_logic;
   signal sig_sequence_running      : std_logic;

   signal sig_data_enable           : std_logic;
   signal sig_data_in               : std_logic;

   signal sig_bit_counter           : integer;

   signal sig_dev_rx_address        : std_logic_vector(6 downto 0);
   signal sig_dev_tx_address        : std_logic_vector(6 downto 0);

   signal scl_o                     : std_logic := 'Z';
   signal clock_stretch             : boolean := false;

   constant c_tx_reserved           : t_integer_arr := (0, 1, 4, 5, 11, 12, 13, 14, 19, 20, 21, 24, 25, 38, 39, 40, 52, 53, 60, 61, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 99, 100, 101, 102, 107, 108, 109, 110, 111, 112, 113, 114, 115);
   constant c_rx_reserved           : t_integer_arr := (0, 1, 4, 5, 11, 14, 15, 16, 17, 19, 20, 21, 22, 23, 24, 25, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 42, 44, 45, 46, 47, 48, 49, 50, 60, 61, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 99, 100, 101, 102, 103, 104, 105, 107, 110, 111, 112, 113, 114, 115, 118);

begin

   sig_dev_tx_address <= "101" & a;
   sig_dev_rx_address <= "100" & a;

   scl <= scl_o;

start_stop: process(scl, sda, reset_n)
      variable stopedge : time;
      variable clockedge : time;
      variable clockedge_old : time;
      variable startedge : time;
      variable firstcycle : std_logic := '1';
      variable myline : line;
   begin
      if rising_edge(scl) then
         clockedge_old := clockedge;
         clockedge := now;
      elsif falling_edge(scl) then
         if now < startedge + thdsta then
            write(myline, string'("ERROR: OBT "));
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
      if scl /= '0' AND reset_n = '1' then
         if rising_edge(sda) then
            firstcycle := '0';
            stopedge := now;
            if stopedge < clockedge + tsusto then
               write(myline, string'("ERROR: OBT "));
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
               write(myline, string'("ERROR: OBT "));
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
                  write(myline, string'("ERROR: OBT "));
                  write(myline, dev_name);
                  write(myline, string'(" - timing violated, tBUF too small, required "));
                  write(myline, tbuf);
                  write(myline, string'(" but got "));
                  write(myline, startedge - stopedge);
                  write(myline, string'(" @ "));
                  write(myline, now);
                  writeline(output, myline);
               end if;

               if startedge < (clockedge_old + tbuf) then
                  write(myline, string'("ERROR: OBT "));
                  write(myline, dev_name);
                  write(myline, string'(" - timing violated, tBUF (repeated start) too small, required "));
                  write(myline, tbuf);
                  write(myline, string'(" but got "));
                  write(myline, startedge - clockedge_old);
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

main_fsm: process(scl, sig_sequence_running, sig_start_detected, reset_n)


      variable var_state         : t_i2c_states := s_address;
      variable i2c_address       : std_logic_vector(7 downto 0) := X"00";
      variable i2c_command       : std_logic_vector(7 downto 0) := X"00";
      variable i2c_data          : std_logic_vector(7 downto 0) := X"00";
      variable var_output_data   : std_logic_vector(7 downto 0) := X"00";
      variable var_bit_counter   : integer := 0;
      variable var_send_ack      : std_logic := '0';
      variable var_tx_access     : std_logic := '0';

      variable myline : line;
   begin
      if sig_sequence_running = '0' then                             -- If a start byte hasn't been detected
         var_state := s_address;
         var_bit_counter := 0;
      elsif sig_start_detected = '1' then                            -- On a start reset the current condition (repeated start)
         var_state := s_address;
         var_bit_counter := 0;
      elsif rising_edge(scl) AND reset_n = '1' then   -- On the rising edge of the scl
         case var_state is
            when s_address =>
               clock_stretch <= false;
               if var_bit_counter /= 55 then
                  i2c_address := i2c_address(6 downto 0) & to_x01(sda);
                  if var_bit_counter = 7 then                        -- s_send ACK, check s_address and select the correct register if reading
                     if i2c_address(7 downto 1) = sig_dev_rx_address or i2c_address(7 downto 1) = sig_dev_tx_address then

                        if i2c_address(7 downto 1) = sig_dev_tx_address then
                           var_tx_access := '1';
                        else
                           var_tx_access := '0';
                        end if;

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
                  write(myline, string'("INFO: OBT "));
                  write(myline, dev_name);
                  if var_tx_access = '1' then
                     write(myline, string'(" TX"));
                  else
                     write(myline, string'(" RX"));
                  end if;

                  write(myline, string'(" - Wrote value 0x"));
                  hwrite(myline, i2c_data);
                  write(myline, string'(" to register "));
                  write(myline, to_integer(unsigned(i2c_command)));
                  writeline(output, myline);
                  var_bit_counter := 0;

                  if var_tx_access = '1' then
                     for i in c_tx_reserved'range loop
                        if c_tx_reserved(i) = to_integer(unsigned(i2c_command)) then
                           write(myline, string'("Error Unsupported TX Register"));
                           writeline(output, myline);
                        end if;
                     end loop;
                  end if;

                  if var_tx_access = '0' then
                     for i in c_rx_reserved'range loop
                        if c_rx_reserved(i) = to_integer(unsigned(i2c_command)) then
                           write(myline, string'("Error Unsupported RX Register"));
                           writeline(output, myline);
                        end if;
                     end loop;
                  end if;

                  i2c_command := i2c_command + 1;
               else
                  var_bit_counter := var_bit_counter + 1;
               end if;
            when s_send =>
               if var_bit_counter = 9 then
                  write(myline, string'("INFO: OBT "));
                  write(myline, dev_name);
                  if var_tx_access = '1' then
                     write(myline, string'(" TX"));
                  else
                     write(myline, string'(" RX"));
                  end if;

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
            if to_integer(unsigned(i2c_command)) = 43 and var_state = s_recieve then
               clock_stretch <= true;
            end if;
         else
            if var_state /= s_send then                              -- If we are not sending then keep the line tristated
               sig_data_enable <= '1';
            else
               if var_bit_counter < 8 then                           -- For the data transmission
                  case to_integer(unsigned(i2c_command)) is
                     when 2 => var_output_data := X"02";             -- Interrupt asserted

                     when 7 => var_output_data := X"00";             -- LOS
                     when 8 => var_output_data := X"8" & "000" & var_tx_access;

                     when 9 => var_output_data := X"02";             -- Fault
                     when 10 => var_output_data := X"00";

                     when 22 => var_output_data := X"18";         -- Temp MSB 24.62 degrees
                     when 23 => var_output_data := X"9e";         -- Temp LSB

                     when 26 => var_output_data := X"81";         -- Voltage MSB 3.31V
                     when 27 => var_output_data := X"4C";
                     when 28 => var_output_data := X"88";         -- High Voltage MSB 3.5V
                     when 29 => var_output_data := X"B8";

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
      sig_state <= var_state;
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

   PROCESS
   BEGIN
      wait until clock_stretch = true;
      scl_o <= '0';
      WAIT FOR tClkhold;
      scl_o <= 'Z';
      wait until sig_state = s_command;
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
         write(myline, string'("ERROR: QSFP "));
         write(myline, DEV_NAME);
         write(myline, string'(" - timing violated, tLOW too small, required "));
         write(myline, tLOW);
         write(myline, string'(" but got "));
         write(myline, lowCycle);
         write(myline, string'(" @ "));
         write(myline, now);
         writeline(output, myline);
      ELSIF highCycle < tHIGH THEN
         write(myline, string'("ERROR: QSFP "));
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
         write(myline, string'("ERROR: QSFP "));
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

reset_time:
   PROCESS
      VARIABLE myline : LINE;
      VARIABLE starttime,stoptime : TIME;
   BEGIN
      WAIT UNTIL falling_edge(reset_n);
      starttime := now;
      WAIT UNTIL rising_edge(reset_n);
      stoptime := now;

      IF stoptime - starttime <  t_reset_init THEN
         write(myline, string'("ERROR: QSFP "));
         write(myline, DEV_NAME);
         write(myline, string'(" - timing violated, reset low time too small, required "));
         write(myline, t_reset_init);
         write(myline, string'(" but got "));
         write(myline, stoptime - starttime);
         write(myline, string'(" @ "));
         write(myline, now);
         writeline(output, myline);
      END IF;

   END PROCESS;



END Structure;

