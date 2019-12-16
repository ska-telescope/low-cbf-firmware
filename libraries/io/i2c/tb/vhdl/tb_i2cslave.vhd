-------------------------------------------------------------------------------
--
-- Copyright (C) 2009
-- ASTRON (Netherlands Institute for Radio Astronomy) <http://www.astron.nl/>
-- P.O.Box 2, 7990 AA Dwingeloo, The Netherlands
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-------------------------------------------------------------------------------

--23-7-2005
--file i2cslave_tb.vhd
--testbench for i2cslave function
--written by A.W. Gunst

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY tb_i2cslave IS
END tb_i2cslave;

ARCHITECTURE tb OF tb_i2cslave IS 
    
  CONSTANT c_period         : TIME := 25 ns;
  CONSTANT c_address        : STD_LOGIC_VECTOR(6 downto 0) := "0000001";  -- Slave I2C address
  CONSTANT c_nof_ctrl_bytes : INTEGER := 3;

  COMPONENT i2cslave
    GENERIC (
      g_rx_filter       : BOOLEAN := TRUE;
      g_address         : STD_LOGIC_VECTOR(6 downto 0) := "0000001";
      g_nof_ctrl_bytes  : NATURAL := 3
    );
    PORT(
      clk         : IN  STD_LOGIC;
      SDA         : INOUT  STD_LOGIC;
      SCL         : IN  STD_LOGIC;
      RST         : IN  STD_LOGIC;
      CTRL_REG    : OUT STD_LOGIC_VECTOR(8*g_nof_ctrl_bytes-1 downto 0)
    );
  END COMPONENT;

   SIGNAL SDA      : STD_LOGIC; --I2C Serial Data Line
   SIGNAL SCL      : STD_LOGIC; --I2C Serial Clock Line
   SIGNAL RST      : STD_LOGIC; --optional reset bit
   SIGNAL CTRL_REG : STD_LOGIC_VECTOR(8*c_nof_ctrl_bytes-1 downto 0); --ctrl for RCU control 

BEGIN

  uut: i2cslave
  GENERIC MAP (
    g_rx_filter        => FALSE,
    g_address          => c_address,
    g_nof_ctrl_bytes   => c_nof_ctrl_bytes
  )
  PORT MAP(
    clk => '0',
    SDA => SDA,
    SCL => SCL,
    RST => RST,
    CTRL_REG => CTRL_REG
  );

tbctrl : PROCESS
  variable cnt : std_logic_vector(11 downto 0) := "000000000000";
  BEGIN
    WHILE (true) LOOP
      SCL <= '0';
      cnt := cnt + 1;
      WAIT FOR c_period;
      SCL <= 'H';
      WAIT FOR c_period;
    END LOOP;
    WAIT;
  END PROCESS;

--SCL low: 0-25 ns
--SCL high: 25-50 ns

tbsda : PROCESS
  BEGIN
    SDA <= 'Z';
    WAIT FOR 200 ns; --initial time to let the fpga set up things
    RST <= '1', '0' AFTER 100 ns;
    WAIT FOR 200 ns; --initial time to let the fpga set up things

     --I2C write sequence (from master to slave)
     SDA <= 'H', '0' AFTER 30 ns, '0' AFTER 60 ns,'0' AFTER 110 ns,'0' AFTER 160 ns,'0' AFTER 210 ns,'0' AFTER 260 ns,'0' AFTER 310 ns,'H' AFTER 360 ns,'0' AFTER 410 ns;
     --     start                     sent address: 0000001,                                                                                              sent rw=0
    --the previous is evaluated at time = 0
    WAIT FOR 452 ns; --next lines are evaluated 450 ns later
    SDA <= 'Z'; -- time for slave to acknowledge       
    WAIT FOR 50 ns; --WAIT 1 clk cycle
    SDA <='Z','H' AFTER 10 ns, '0' AFTER 60 ns, 'H' AFTER 110 ns, '0' AFTER 160 ns,'H' AFTER 210 ns, 'H' AFTER 260 ns, 'H' AFTER 310 ns, '0' AFTER 360 ns; -- sent first data byte
    WAIT FOR 400 ns;
    SDA <= 'Z'; -- time for slave to acknowledge
    WAIT FOR 50 ns; --WAIT 1 clk cycle
    SDA <='Z','0' AFTER 10 ns, 'H' AFTER 60 ns, 'H' AFTER 110 ns, '0' AFTER 160 ns,'H' AFTER 210 ns, '0' AFTER 260 ns, 'H' AFTER 310 ns, 'H' AFTER 360 ns; -- sent second data byte
    
    WAIT FOR 400 ns;
    SDA <= 'Z'; -- time for slave to acknowledge
    WAIT FOR 50 ns; --WAIT 1 clk cycle
    SDA <='Z','0' AFTER 10 ns, 'H' AFTER 60 ns, 'H' AFTER 110 ns, '0' AFTER 160 ns,'H' AFTER 210 ns, '0' AFTER 260 ns, 'H' AFTER 310 ns, 'H' AFTER 360 ns; -- sent third data byte

    WAIT FOR 400 ns;
    SDA <= 'Z'; -- time for slave to nacknowledge
    WAIT FOR 70 ns; --WAIT 1.5 clk cycle
    SDA <= '0'; -- stop
    WAIT FOR 30 ns; --to get in line with falling clk edge

    --reset slave
    RST <= '1';
    WAIT FOR 50 ns;
    RST <= '0';
  
    --time is 1500ns + 450ns
    --I2C read sequence (from slave to master)
    SDA <= 'H', '0' AFTER 30 ns, '0' AFTER 60 ns,'0' AFTER 110 ns,'0' AFTER 160 ns,'0' AFTER 210 ns,'0' AFTER 260 ns,'0' AFTER 310 ns,'H' AFTER 360 ns,'H' AFTER 410 ns;
    --     start                     sent address: 0000001                                                                                             sent rw=1
    WAIT FOR 450 ns; --next lines are evaluated 450 ns later
    SDA <= 'Z'; -- time for slave to acknowledge address      
    WAIT FOR 505 ns;
    SDA <= '0','Z' AFTER 30 ns; --acknowledge first byte

    WAIT FOR 500 ns;
    SDA <= '0','Z' AFTER 30 ns; --acknowledge second byte

    --time is 2455ns + 450ns
    WAIT FOR 505 ns; --on purpose the nack is given 100 ns later
    SDA <= 'H','Z' AFTER 50 ns; --nacknowledge third byte
    WAIT FOR 125 ns; --WAIT 2.5 clk to give stop command
    SDA <= 'H'; -- stop
    WAIT FOR 15 ns; --to get in line with falling clk edge
    --time is 3115

    WAIT FOR 200 ns;
    --reset slave
    RST <= '0';
    WAIT FOR 50 ns;
    RST <= '1';
    SDA <= '0';

    WAIT FOR 50 ns;
    
    --I2C sequence for another slave
    SDA <= 'H', '0' AFTER 30 ns, 'H' AFTER 60 ns,'0' AFTER 110 ns,'0' AFTER 160 ns,'0' AFTER 210 ns,'0' AFTER 260 ns,'0' AFTER 310 ns,'0' AFTER 360 ns,'0' AFTER 410 ns;
    --     start                     sent address: 0000001,                                                                                              sent rw=0
    --the previous is evaluated at time = 0
    WAIT FOR 450 ns; --next lines are evaluated 450 ns later
    SDA <= 'Z'; -- time for slave to acknowledge       
    WAIT FOR 50 ns; --WAIT 1 clk cycle
    SDA <='Z','0' AFTER 10 ns, '0' AFTER 60 ns, 'H' AFTER 110 ns, '0' AFTER 160 ns,'H' AFTER 210 ns, 'H' AFTER 260 ns, 'H' AFTER 310 ns, '0' AFTER 360 ns; -- sent first data byte
    WAIT FOR 400 ns;
    SDA <= 'Z'; -- time for slave to acknowledge
    WAIT FOR 50 ns; --WAIT 1 clk cycle
    SDA <='Z','0' AFTER 10 ns, 'H' AFTER 60 ns, 'H' AFTER 110 ns, '0' AFTER 160 ns,'H' AFTER 210 ns, '0' AFTER 260 ns, 'H' AFTER 310 ns, 'H' AFTER 360 ns; -- sent second data byte
    WAIT FOR 400 ns;
    SDA <= 'Z'; -- time for slave to nacknowledge
    WAIT FOR 80 ns; --WAIT 1.5 clk cycle
    SDA <= '0'; -- stop
    WAIT FOR 20 ns; --to get in line with falling clk edge
  END PROCESS;

END;

