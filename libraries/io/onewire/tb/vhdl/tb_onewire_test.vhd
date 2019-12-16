-------------------------------------------------------------------------------
--
-- File Name: tb_pmbus_control.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: 10:28:16 07/15/2009
-- Template Rev: 1.0
--
-- Title: Onewire Testbench
--
-- Description:
--
-- Compiler options:
--
--
-- Dependencies:
--
--
--
-------------------------------------------------------------------------------


LIBRARY ieee, common_lib;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_textio.all;
USE std.textio.all;
USE work.onewire_pkg.ALL;
USE common_lib.common_pkg.ALL;

ENTITY tb_onewire_test IS
END tb_onewire_test;

ARCHITECTURE behavior OF tb_onewire_test IS

  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   CONSTANT c_clk_period      : TIME := 8 ns;                -- 125MHz
   CONSTANT c_reset_len       : INTEGER := 10;

   CONSTANT c_rom             : STD_LOGIC_VECTOR(63 DOWNTO 0) := X"0F00000001B81C2D";

  ---------------------------------------------------------------------------
  -- SIGNAL DECLARATIONS  --
  ---------------------------------------------------------------------------

   -- Clocks
   SIGNAL clk                       : STD_LOGIC := '0';


   -- DUT
   SIGNAL write_data                : STD_LOGIC_VECTOR(63 downto 0);
   SIGNAL rom_valid                 : STD_LOGIC;
   SIGNAL rom                       : STD_LOGIC_VECTOR(47 DOWNTO 0);
   SIGNAL read_data                 : STD_LOGIC_VECTOR(63 DOWNTO 0);
   SIGNAL error                     : STD_LOGIC;
   SIGNAL running                   : STD_LOGIC;
   SIGNAL strobe                    : STD_LOGIC;
   SIGNAL mode                      : t_onewire_cmd;
   SIGNAL mem_address               : STD_LOGIC_VECTOR(15 downto 0);

   -- Testbench
   SIGNAL reset                     : STD_LOGIC := '0';
   SIGNAL tb_end                    : STD_LOGIC := '0';

   -- Onewire Bus
   signal onewire_strong            : STD_LOGIC;
   signal onewire                   : STD_LOGIC;



begin

---------------------------------------------------------------------------
-- Clocks  --
---------------------------------------------------------------------------

   clk <= NOT clk OR tb_end AFTER c_clk_period/2;
   reset <= '1', '0'    AFTER c_clk_period*c_reset_len;


---------------------------------------------------------------------------
-- DUT  --
---------------------------------------------------------------------------

dut: entity work.onewire_memory
      port map (clk                 => clk,
                rst                 => reset,
                strobe              => strobe,
                mode                => mode,
                mem_address         => mem_address,
                read_data           => read_data,
                write_data          => write_data,
                error              => error,
                running            => running,
                rom                => rom,
                rom_valid          => rom_valid,
                onewire_strong     => onewire_strong,
                onewire            => onewire);

   onewire <= '1' WHEN onewire_strong = '0' ELSE 'H';

---------------------------------------------------------------------------
-- Onewire Test Model  --
---------------------------------------------------------------------------

ds2431_1: ENTITY work.ds2431
          GENERIC MAP (g_dev_name => string'(""))
          PORT MAP (onewire => onewire);

--------------------------------------------------------------------------

   -- Stimulus process
stim_proc: process

   begin

      WAIT FOR 1 us;
      WAIT UNTIL running = '0';
      WAIT UNTIL RISING_EDGE(clk);

      ASSERT(rom_valid = '1') REPORT "ROM not valid" SEVERITY failure;
      ASSERT(rom = c_rom(55 DOWNTO 8)) REPORT "ROM wrong" SEVERITY failure;


      -- Read Address 0
      WAIT UNTIL RISING_EDGE(clk);
      mode <= CMD_READ_MEMORY;
      mem_address <= X"0000";
      strobe <= '1';
      wait until rising_edge(clk);
      strobe <= '0';

      WAIT FOR 1 us;
      WAIT UNTIL running = '0';
      WAIT UNTIL RISING_EDGE(clk);

      ASSERT(error = '0') REPORT "Error asserted" SEVERITY failure;
      ASSERT(read_data = X"CCAAAABEFAC83474") REPORT "Read data wrong" SEVERITY failure;

      -- Write Address 0
      wait until rising_edge(clk);
      mode <= CMD_WRITE_MEMORY;
      mem_address <=  X"0000";
      strobe <=  '1';
      write_data <= X"0123456789abcdef";
      wait until rising_edge(clk);
      strobe <= '0';

      WAIT FOR 1 us;
      WAIT UNTIL running = '0';
      WAIT UNTIL RISING_EDGE(clk);

      ASSERT(error = '0') REPORT "Error asserted" SEVERITY failure;

      -- Read Address 0
      WAIT UNTIL RISING_EDGE(clk);
      mode <= CMD_READ_MEMORY;
      mem_address <= X"0000";
      strobe <= '1';
      wait until rising_edge(clk);
      strobe <= '0';

      WAIT FOR 1 us;
      WAIT UNTIL running = '0';
      WAIT UNTIL RISING_EDGE(clk);

      ASSERT(error = '0') REPORT "Error asserted" SEVERITY failure;
      ASSERT(read_data = X"0123456789abcdef") REPORT "Read data wrong" SEVERITY failure;

      WAIT FOR 10 us;

      tb_end <= '1';
      REPORT "Finished Simulation" SEVERITY note;
      WAIT;
   END PROCESS;

END;
