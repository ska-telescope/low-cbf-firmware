-------------------------------------------------------------------------------
--
-- File Name: tb_sfp_control.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created:
-- Template Rev: 1.0
--
-- Title: SFP M&C Testbench
--
-- Description: Runs a simple test on the suppoort module for the Gemini LRU
--              SFP module
--
-- Compiler options:
--
--
-- Dependencies:
--
--
--
-------------------------------------------------------------------------------

LIBRARY IEEE, common_lib, axi4_lib, technology_lib, i2c_lib, onewire_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.math_real.ALL;
USE IEEE.std_logic_textio.ALL;
USE STD.textio.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE work.gemini_lru_board_onewire_prom_reg_pkg.ALL;

ENTITY tb_prom_control IS

END tb_prom_control;

ARCHITECTURE testbench OF tb_prom_control IS

  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   CONSTANT c_mm_clk_period         : TIME := 6.4 ns;
   CONSTANT c_reset_len             : INTEGER := 10;

  ---------------------------------------------------------------------------
  -- SIGNAL DECLARATIONS  --
  ---------------------------------------------------------------------------

   SIGNAL axi_clk                   : STD_LOGIC := '0';
   SIGNAL sim_finished              : STD_LOGIC := '0';
   SIGNAL tb_end                    : STD_LOGIC := '0';

   -- DUT Signals
   SIGNAL s_axi_mosi                : t_axi4_lite_mosi;
   SIGNAL s_axi_miso                : t_axi4_lite_miso;

   SIGNAL mac                       : STD_LOGIC_VECTOR(47 DOWNTO 0);
   SIGNAL ip                        : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL serial_number             : STD_LOGIC_VECTOR(31 DOWNTO 0);

   SIGNAL onewire                   : STD_LOGIC;
   SIGNAL onewire_strong            : STD_LOGIC;

   -- Testbench
   SIGNAL reset                     : STD_LOGIC;
   SIGNAL read_data                 : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN



---------------------------------------------------------------------------
-- Clocks  --
---------------------------------------------------------------------------

   axi_clk <= NOT axi_clk OR sim_finished  AFTER c_mm_clk_period/2;
   reset <= '1', '0'    AFTER c_mm_clk_period*c_reset_len;

---------------------------------------------------------------------------
-- DUT  --
---------------------------------------------------------------------------

dut: ENTITY work.prom_interface
     GENERIC MAP (g_technology         => c_tech_gemini)
     PORT MAP (clk                     => axi_clk,
               rst                     => reset,
               mac                     => mac,
               ip                      => ip,
               serial_number           => serial_number,
               s_axi_mosi              => s_axi_mosi,
               s_axi_miso              => s_axi_miso,
               onewire_strong          => onewire_strong,
               onewire                 => onewire);


   onewire <= '1' WHEN onewire_strong = '0' ELSE 'H';

---------------------------------------------------------------------------
-- Devices  --
---------------------------------------------------------------------------

onewire_test: ENTITY onewire_lib.ds2431
              GENERIC MAP (g_dev_name => string'(""),
                           g_rom      => X"0F00000001B81C2D",
                           g_mem_init => (X"CA000000000a0001",
                                          X"ab0000000a0f020e",
                                          X"ffffffffffffffff",
                                          X"ffffffffffffffff",
                                          X"ffffffffffffffff",
                                          X"ffffffffffffffff",
                                          X"ffffffffffffffff",
                                          X"ffffffffffffffff"))

              PORT MAP (onewire => onewire);


---------------------------------------------------------------------------
-- Test Script  --
---------------------------------------------------------------------------

tb_stim: PROCESS

   BEGIN
      axi_lite_init (reset, axi_clk, s_axi_miso, s_axi_mosi);

      -------------------------------------------
      --                Test 1                 --
      -------------------------------------------
      -- Wait for running completed and then check IP address
      -- MAC and serial number OK

      WAIT FOR 1 ms;

      axi_lite_wait (axi_clk, s_axi_miso, s_axi_mosi, c_onewire_prom_status_running_address, X"00000000");


      ASSERT(mac = X"C0000001B81C") REPORT "MAC not valid" SEVERITY failure;
      ASSERT(ip = X"0a0f020e") REPORT "IP not valid" SEVERITY failure;
      ASSERT(serial_number = X"000a0001") REPORT "Serial number not valid" SEVERITY failure;

      -- Check saved data
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_onewire_prom_status_error_address, false, X"00000000", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_onewire_prom_status_rom_invalid_address, false, X"00000000", validate => true);

      -------------------------------------------
      --                Test 2                 --
      -------------------------------------------
      -- Read memory, write memory and readback value

      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_onewire_prom_control_address_address, true, X"00000003");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_onewire_prom_control_read_execute_address, true, X"00000001");

      axi_lite_wait (axi_clk, s_axi_miso, s_axi_mosi, c_onewire_prom_status_running_address, X"00000000");


      -- Check read data
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_onewire_prom_status_error_address, false, X"00000000", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_onewire_prom_data_read_low_address, false, X"ffffffff", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_onewire_prom_data_read_high_address, false, X"ffffffff", validate => true);

      -----------------

      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_onewire_prom_data_write_low_address, true, X"89abcdef");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_onewire_prom_data_write_high_address, true, X"01234567");
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_onewire_prom_control_write_execute_address, true, X"00000001");

      axi_lite_wait (axi_clk, s_axi_miso, s_axi_mosi, c_onewire_prom_status_running_address, X"00000000");

      -- Check error flag
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_onewire_prom_status_error_address, false, X"00000000", validate => true);

      -----------------

      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_onewire_prom_control_read_execute_address, true, X"00000001");

      axi_lite_wait (axi_clk, s_axi_miso, s_axi_mosi, c_onewire_prom_status_running_address, X"00000000");

      -- Check read data
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_onewire_prom_status_error_address, false, X"00000000", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_onewire_prom_data_read_low_address, false, X"89abcdef", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_onewire_prom_data_read_high_address, false, X"01234567", validate => true);

      sim_finished <= '1';
      tb_end <= '1';
      WAIT FOR 1 us;
      REPORT "Finished Simulation" SEVERITY FAILURE;
      WAIT;
   END PROCESS;

END testbench;