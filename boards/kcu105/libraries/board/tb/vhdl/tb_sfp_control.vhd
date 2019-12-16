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

LIBRARY IEEE, common_lib, axi4_lib, technology_lib, i2c_lib;
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
USE work.kcu105_board_sfp_reg_pkg.ALL;

ENTITY tb_sfp_control IS

END tb_sfp_control;

ARCHITECTURE testbench OF tb_sfp_control IS

  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   CONSTANT c_axi_clk_period     : TIME := 6.4 ns;

  ---------------------------------------------------------------------------
  -- SIGNAL DECLARATIONS  --
  ---------------------------------------------------------------------------

   SIGNAL axi_clk                   : STD_LOGIC := '0';

   -- DUT Signals
   SIGNAL s_axi_mosi                : t_axi4_lite_mosi;
   SIGNAL s_axi_miso                : t_axi4_lite_miso;

   SIGNAL sfp_sda                   : STD_LOGIC;
   SIGNAL sfp_scl                   : STD_LOGIC;
   SIGNAL sfp_fault                 : STD_LOGIC;
   SIGNAL sfp_tx_enable             : STD_LOGIC;
   SIGNAL sfp_mod_abs               : STD_LOGIC;

   -- Testbench
   SIGNAL reset                     : STD_LOGIC;
   SIGNAL finished_sim              : STD_LOGIC;

BEGIN



---------------------------------------------------------------------------
-- Clocks  --
---------------------------------------------------------------------------

   axi_clk <= NOT axi_clk or finished_sim AFTER c_axi_clk_period/2;

---------------------------------------------------------------------------
-- DUT  --
---------------------------------------------------------------------------

dut: ENTITY work.sfp_control
     GENERIC MAP (g_clk_rate  => 156250000,
                  g_i2c_rate  => 50000,
                  g_sim       => TRUE)
     PORT MAP (clk            => axi_clk,
               rst            => reset,
               s_axi_mosi     => s_axi_mosi,
               s_axi_miso     => s_axi_miso,
               sfp_sda        => sfp_sda,
               sfp_scl        => sfp_scl,
               sfp_fault      => sfp_fault,
               sfp_tx_enable  => sfp_tx_enable,
               sfp_mod_abs    => sfp_mod_abs);


---------------------------------------------------------------------------
-- Devices  --
---------------------------------------------------------------------------

   sfp_sda <= 'H';
   sfp_scl <= 'H';

   sfp_mod_abs <= '0';
   sfp_fault <= '0';

U1: ENTITY i2c_lib.dev_M24AA128
    PORT MAP (A0           => '1',
              A1           => '0',
              A2           => '0',
              RESET        => '0',
              WP           => '1',
              sda          => sfp_sda,
              scl          => sfp_scl);

---------------------------------------------------------------------------
-- Test Script  --
---------------------------------------------------------------------------

tb_stim: PROCESS
      procedure axi_lite_reset is
      begin
         s_axi_mosi.arvalid <= '0';
         s_axi_mosi.awvalid <= '0';
         s_axi_mosi.wvalid <= '0';
         s_axi_mosi.bready <= '0';
         s_axi_mosi.rready <= '0';

         s_axi_mosi.awaddr <= (OTHERS => '0');
         s_axi_mosi.wdata <= (OTHERS => '0');
         s_axi_mosi.wstrb <= (OTHERS => '0');
         s_axi_mosi.araddr <= (OTHERS => '0');
         wait until rising_edge(axi_clk);
      end procedure;



      procedure axi_lite_transaction (register_addr   : t_register_address;
                                      write_reg       : boolean;
                                      data            : std_logic_vector(31 downto 0);
                                      validate        : boolean := false;
                                      check_mask      : std_logic_vector(31 downto 0) := (OTHERS => '1')) is

         variable stdio             : line;
         VARIABLE write_response    : STD_LOGIC_VECTOR(1 DOWNTO 0);
         VARIABLE masked_data       : STD_LOGIC_VECTOR(31 DOWNTO 0);
      begin

         write(stdio, LF);
         writeline(output, stdio);

         -- Start transaction
         WAIT UNTIL rising_edge(axi_clk);

         IF write_reg = false THEN

            -- Setup read address
            s_axi_mosi.arvalid <= '1';
            s_axi_mosi.araddr(31 DOWNTO 0) <= std_logic_vector(to_unsigned(register_addr.base_address + register_addr.address, 32));
            s_axi_mosi.rready <= '1';

            -- wait for address ready and read back data valid
            read_addr_wait: LOOP
               WAIT UNTIL rising_edge(axi_clk);
               IF s_axi_miso.arready = '1' THEN
                  s_axi_mosi.arvalid <= '0';
                  EXIT;
               END IF;
            END LOOP;

            read_valid_wait: LOOP
               IF s_axi_miso.rvalid = '1' THEN
                  EXIT;
               END IF;
               WAIT UNTIL rising_edge(axi_clk);
            END LOOP;

            write(stdio, string'("INFO: AXI Lite read of register "));
            write(stdio, register_addr.address);
            write(stdio, string'(" returned "));

            -- Read response
            IF s_axi_miso.rresp = "00" THEN
               write(stdio, string'("OK "));
            ELSIF s_axi_miso.rresp = "01" THEN
               write(stdio, string'("exclusive access error "));
            ELSIF s_axi_miso.rresp = "10" THEN
               write(stdio, string'("slave error "));
            ELSIF s_axi_miso.rresp = "11" THEN
               write(stdio, string'("address decode error "));
            END IF;

            masked_data := (OTHERS => '0');
            data_masking_read: FOR i IN 0 TO register_addr.width-1 LOOP
               masked_data(i) := s_axi_miso.rdata(register_addr.offset+i);
            END LOOP;

            write(stdio, string'("with data 0x"));
            hwrite(stdio, masked_data);
            writeline(output, stdio);

            IF (masked_data AND check_mask) /= (data AND check_mask) AND validate = TRUE THEN
               write(stdio, string'("ERROR: Return data doesn't match mask"));
               writeline(output, stdio);
            END IF;

            WAIT UNTIL rising_edge(axi_clk);
            s_axi_mosi.rready <= '0';
            s_axi_mosi.arvalid <= '0';
            WAIT UNTIL rising_edge(axi_clk);
         ELSE

            -- Needs to actually do a read first to perform a RMW on the shared fields

            s_axi_mosi.arvalid <= '1';
            s_axi_mosi.araddr(31 DOWNTO 0) <= std_logic_vector(to_unsigned(register_addr.base_address + register_addr.address, 32));
            s_axi_mosi.rready <= '1';

            -- wait for address ready and read back data valid
            write_read_addr_wait: LOOP
               WAIT UNTIL rising_edge(axi_clk);
               IF s_axi_miso.arready = '1' THEN
                  s_axi_mosi.arvalid <= '0';
                  EXIT;
               END IF;
            END LOOP;

            write_read_valid_wait: LOOP
               IF s_axi_miso.rvalid = '1' THEN
                  EXIT;
               END IF;
               WAIT UNTIL rising_edge(axi_clk);
            END LOOP;

            IF s_axi_miso.rresp /= "00" THEN
               write(stdio, string'("ERROR: Failure to read during write "));
               writeline(output, stdio);
            END IF;

            -- Preload masked data variable with current register data
            masked_data := s_axi_miso.rdata;

            WAIT UNTIL rising_edge(axi_clk);
            s_axi_mosi.rready <= '0';
            s_axi_mosi.arvalid <= '0';

            -- Setup write address, data, & reponse ready
            s_axi_mosi.awvalid <= '1';
            s_axi_mosi.awaddr <= std_logic_vector(to_unsigned(register_addr.base_address + register_addr.address, 32));

            data_masking_write: FOR i IN 0 TO register_addr.width-1 LOOP
               masked_data(register_addr.offset+i) := data(i);
            END LOOP;

            s_axi_mosi.wvalid <= '1';
            s_axi_mosi.wdata <= masked_data;
            s_axi_mosi.wstrb <= X"f";

            s_axi_mosi.bready <= '1';

            -- wait for ready & response
            write_data_wait: LOOP
               WAIT UNTIL rising_edge(axi_clk);
               IF s_axi_miso.awready = '1' THEN
                  s_axi_mosi.awvalid <= '0';
                  s_axi_mosi.awaddr <= (OTHERS => '0');
               END IF;

               IF s_axi_miso.wready = '1' THEN
                  s_axi_mosi.wvalid <= '0';
                  s_axi_mosi.wdata <= (OTHERS => '0');
                  s_axi_mosi.wstrb <= X"0";
               END IF;

               IF s_axi_miso.bvalid = '1' THEN
                  s_axi_mosi.bready <= '0';
                  write_response := s_axi_miso.bresp;
               END IF;

               IF s_axi_mosi.bready = '0' THEN
                  EXIT;
               END IF;
            END LOOP;


            write(stdio, string'("AXI Lite write of register "));
            write(stdio, register_addr.address);
            write(stdio, string'(" returned "));

            -- Read response
            IF write_response = "00" THEN
               write(stdio, string'("OK"));
            ELSIF write_response = "01" THEN
               write(stdio, string'("exclusive access error "));
            ELSIF write_response = "10" THEN
               write(stdio, string'("slave error "));
            ELSIF write_response = "11" THEN
               write(stdio, string'("address decode error "));
            END IF;

            writeline(output, stdio);

            WAIT UNTIL rising_edge(axi_clk);
         END IF;

      END PROCEDURE;


      PROCEDURE axi_lite_burst (register_addr   : t_register_address;
                                write_reg       : boolean;
                                data_length     : integer;
                                data_burst      : t_slv_32_arr) is

         VARIABLE check_mask        : STD_LOGIC_VECTOR(31 DOWNTO 0);
         VARIABLE i_register_addr   : t_register_address;
      BEGIN

         check_mask := (OTHERS => '0');
         mask_build: FOR i IN 0 TO register_addr.width-1 LOOP
            check_mask(i) := '1';
         END LOOP;

         i_register_addr := register_addr;
         transactions: FOR i IN 0 TO data_length-1 LOOP

            -- Increment the address
            i_register_addr.address := register_addr.address + i;

            -- Run individual commands
            axi_lite_transaction (i_register_addr, write_reg, data_burst(i), not(write_reg), check_mask);
         END LOOP;
      END PROCEDURE;



      VARIABLE data_burst  : t_slv_32_arr(0 TO 31);
      VARIABLE start_time  : TIME;
   BEGIN
      reset <= '1';

      finished_sim <= '0';

      -- Reset the AXI-Lite bus
      axi_lite_reset;

      reset <= '1';
      WAIT FOR 100 ps;
      reset <= '0';
      WAIT FOR 500 ps;

      -------------------------------------------
      --                Test 1                 --
      -------------------------------------------
      -- Let the monitor cycle complete
      -- Verify the downloaded data

      WAIT FOR 5 ms;

      -- Check saved data
      axi_lite_transaction (c_sfp_voltage_address, false, X"00000301", true, X"000007FF");
      axi_lite_transaction (c_sfp_tx_bias_address, false, X"0000001A", true, X"0000001F");
      axi_lite_transaction (c_sfp_tx_power_address, false, X"00000266", true, X"000007FF");
      axi_lite_transaction (c_sfp_rx_power_address, false, X"00000017", true, X"0000001F");
      axi_lite_transaction (c_sfp_temperature_address, false, X"0000020C", true, X"000007FF");

      -------------------------------------------
      --                Test 2                 --
      -------------------------------------------
      -- Upload a custom program to write a byte to a register and downlaod a word
      -- Verify the downloaded data

      -- Test Program mode
      data_burst(0) := X"00000006";    -- Write Byte OP
      data_burst(1) := X"00000051";    -- DMI
      data_burst(2) := X"00000041";    -- Register Address
      data_burst(3) := X"000000aa";    -- Data
      data_burst(4) := X"00000009";    -- Read word OP
      data_burst(5) := X"00000051";    -- DMI
      data_burst(6) := X"0000004a";    -- Register Address
      data_burst(7) := X"00000013";    -- End

      axi_lite_burst(c_sfp_program_address, true, 8, data_burst); -- Write Program

      -- Queue program
      axi_lite_transaction (c_sfp_control_prog_execute_address, true, X"00000001");

      -- Wait for completion
      WAIT FOR 10 ms;

      -- Check sucess
      axi_lite_transaction (c_sfp_status_prog_finished_address, false, X"00000001", true, X"00000001");

      -- Verify Data
      data_burst(0) := X"0000006b";    -- LSB first
      data_burst(1) := X"0000001b";    -- MSB second

      axi_lite_burst(c_sfp_results_address, false, 2, data_burst); -- Check results

      finished_sim <= '1';
      REPORT "Finished Simulation" SEVERITY note;
      WAIT;
   END PROCESS;






END testbench;