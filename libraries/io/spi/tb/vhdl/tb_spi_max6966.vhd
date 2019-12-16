--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:   16:00:45 03/27/2012
-- Design Name:
-- Module Name:   D:/PROJECTS/ASKAP/ADE/Firmware/ControlMonitoringDEC/source/hdl/monitor/tb_spi_max6966.vhd
-- Project Name:  bullant
-- Target Device:
-- Tool versions:
-- Description:
--
-- VHDL Test Bench Created by ISE for module: mon_leds
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes:
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee, std;
USE ieee.std_logic_1164.ALL;
use ieee.std_logic_textio.all;
use std.textio.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;

ENTITY tb_spi_max6966 IS
END tb_spi_max6966;

ARCHITECTURE behavior OF tb_spi_max6966 IS

   --Inputs
   signal clock : std_logic := '0';
   signal reset : std_logic := '0';
   signal led1_colour : std_logic_vector(23 downto 0) := (others => '0');
   signal led2_colour : std_logic_vector(23 downto 0) := (others => '0');
   signal led3_colour : std_logic_vector(23 downto 0) := (others => '0');
   signal enable : std_logic := '0';
   signal dout   : std_logic := '0';

   --Outputs
   signal full_cycle : std_logic;
   signal din : std_logic;
   signal sclk : std_logic;
   signal cs : std_logic;

   -- Clock period definitions
   constant clock_period : time := 8 ns;

BEGIN

--------------------------------------------------------------------------------

   -- Instantiate the Unit Under Test (UUT)
   uut: entity work.spi_max6966 
        generic map (g_simulation   => true)
        port map (clk                 => clock,
                  rst                 => reset,
                  led1_colour         => led1_colour,
                  led2_colour         => led2_colour,
                  led3_colour         => led3_colour,
                  full_cycle          => full_cycle,
                  enable              => enable,
                  din                 => din,
                  sclk                => sclk,
                  cs                  => cs,
                  dout                => dout);

--------------------------------------------------------------------------------

-- Clock process definitions
clock_process :process
   begin
      clock <= '0';
      wait for clock_period/2;
      clock <= '1';
      wait for clock_period/2;
   end process;

--------------------------------------------------------------------------------

chip_sim: process(cs, sclk)
      variable t0          : time;
      variable recieving   : boolean := false;
      variable data        : std_logic_vector(15 downto 0);
      variable stdio       : line;
   begin
      if falling_edge(cs) then
         recieving := true;
      elsif rising_edge(cs) then
         if recieving = true then
            if data(15) = '1' then
               write(stdio, string'("INFO - MAX6966 Read of"));
            else
               write(stdio, string'("INFO - MAX6966 Write to"));
            end if;
               
            write(stdio, string'(" register 0x"));
            hwrite(stdio, ('0' & data(14 downto 8)));
            
            if data(15) = '0' then
               write(stdio, string'(" with data 0x"));
               hwrite(stdio, data(7 downto 0));
            end if;
            writeline(output, stdio);
            recieving := false;
         end if;
      else
         if rising_edge(sclk) then
            if recieving = true then
               data := data(14 downto 0) & din;
            end if; 
         end if;
      end if;
   end process;


--------------------------------------------------------------------------------

   -- Stimulus process
   stim_proc: process
   begin
      -- hold reset state for 100 ns.
      reset <= transport '1';
      enable <= transport '0';
      wait for 100 ns;
      reset <= transport '0';

      wait for clock_period*10;

      enable <= transport '1';


      led1_colour <= X"4578ef";
      led2_colour <= (others => '0');
      led3_colour <= X"47a6c8";


      wait;
   end process;

END;
