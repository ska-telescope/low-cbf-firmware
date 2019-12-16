-------------------------------------------------------------------------------
--
-- Copyright (C) 2017
-- ASTRON (Netherlands Institute for Radio Astronomy) <http://www.astron.nl/>
-- JIVE (Joint Institute for VLBI in Europe) <http://www.jive.nl/>
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

LIBRARY IEEE, common_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE work.axi4_lite_pkg.ALL;


ENTITY tb_axi4_lite_reg_r_w IS
END tb_axi4_lite_reg_r_w;

ARCHITECTURE tb OF tb_axi4_lite_reg_r_w IS

  CONSTANT mm_clk_period : TIME := 40 ns;
  CONSTANT c_reset_len   : NATURAL := 4;

  CONSTANT c_mm_reg_led    : t_c_mem := (latency      => 1,
                                         adr_w        => 1,
                                         dat_w        => c_word_w,
                                         nof_dat      => 2,
                                         addr_base    => 0,
                                         nof_slaves   => 1,
                                         init_sl      => '0');

  SIGNAL mm_rst               : STD_LOGIC;
  SIGNAL mm_clk               : STD_LOGIC := '0';
  SIGNAL tb_end               : STD_LOGIC := '0';
  SIGNAL sim_finished         : STD_LOGIC := '0';

  SIGNAL rd_dat               : STD_LOGIC_VECTOR(c_mm_reg_led.dat_w-1 DOWNTO 0);
  SIGNAL wr_dat               : STD_LOGIC_VECTOR(c_mm_reg_led.dat_w-1 DOWNTO 0);
  SIGNAL wr_val               : STD_LOGIC;
  SIGNAL rd_val               : STD_LOGIC;
  SIGNAL rd_busy              : STD_LOGIC;
  SIGNAL wr_busy              : STD_LOGIC;
  SIGNAL reg_wren             : STD_LOGIC;
  SIGNAL reg_rden             : STD_LOGIC;
  SIGNAL wr_adr               : STD_LOGIC_VECTOR(c_mm_reg_led.adr_w-1 DOWNTO 0);
  SIGNAL rd_adr               : STD_LOGIC_VECTOR(c_mm_reg_led.adr_w-1 DOWNTO 0);

  SIGNAL led2_colour_arr      : STD_LOGIC_VECTOR((c_mm_reg_led.nof_dat * c_word_w)-1 DOWNTO 0);
  SIGNAL reg_led_mosi         : t_axi4_lite_mosi;
  SIGNAL reg_led_miso         : t_axi4_lite_miso;

  signal sendIt               : std_logic := '0';
  signal readIt               : std_logic := '0';

BEGIN

  -- as 10
  -- run 10 us

  mm_clk <= NOT mm_clk OR sim_finished  AFTER mm_clk_period/2;
  mm_rst <= '1', '0'    AFTER mm_clk_period*c_reset_len;

u_mem_to_axi4_lite : ENTITY work.mem_to_axi4_lite
                     GENERIC MAP (g_adr_w => c_mm_reg_led.adr_w,
                                  g_dat_w => c_mm_reg_led.dat_w)
                     PORT MAP (rst        => mm_rst,
                               clk        => mm_clk,
                               sla_in     => reg_led_mosi,
                               sla_out    => reg_led_miso,
                               wren       => reg_wren,
                               rden       => reg_rden,
                               wr_adr     => wr_adr,
                               wr_dat     => wr_dat,
                               wr_val     => wr_val,
                               wr_busy    => wr_busy,
                               rd_adr     => rd_adr,
                               rd_dat     => rd_dat,
                               rd_busy    => rd_busy,
                               rd_val     => rd_val);

led_reg : ENTITY common_lib.common_reg_r_w
          GENERIC MAP (g_reg        => c_mm_reg_led)
          PORT MAP (mm_rst          => mm_rst,
                    mm_clk          => mm_clk,
                    wr_en           => reg_wren,
                    wr_adr          => wr_adr,
                    wr_dat          => wr_dat,
                    wr_val          => wr_val,
                    wr_busy         => wr_busy,
                    rd_en           => reg_rden,
                    rd_adr          => rd_adr,
                    rd_dat          => rd_dat,
                    rd_val          => rd_val,
                    rd_busy         => rd_busy,
                    reg_wr_arr      => open,
                    reg_rd_arr      => open,
                    out_reg         => led2_colour_arr,
                    in_reg          => x"00000000AAAA5555");



 -- Initiate process which simulates a master wanting to write.
 -- This process is blocked on a "Send Flag" (sendIt).
 -- When the flag goes to 1, the process exits the wait state and
 -- execute a write transaction.
 send : PROCESS
 BEGIN
    reg_led_mosi.awvalid<='0';
    reg_led_mosi.wvalid<='0';
    reg_led_mosi.bready<='0';
    loop
        wait until sendIt = '1';
        wait until mm_clk= '0';
            reg_led_mosi.awvalid<='1';
            reg_led_mosi.wvalid<='1';
        WHILE (reg_led_miso.awready and reg_led_miso.wready) /= '1' LOOP
          wait until (reg_led_miso.awready and reg_led_miso.wready) = '1';  --Client ready to read address/data
        END LOOP;

            reg_led_mosi.bready<='1';
        wait until reg_led_miso.bvalid = '1';  -- Write result valid
            assert reg_led_miso.bresp = "00" report "AXI data not written" severity failure;
            reg_led_mosi.awvalid<='0';
            reg_led_mosi.wvalid<='0';
            reg_led_mosi.bready<='1';
        wait until reg_led_miso.bvalid = '0';  -- All finished
            reg_led_mosi.bready<='0';
    end loop;
 END PROCESS send;

  -- Initiate process which simulates a master wanting to read.
  -- This process is blocked on a "Read Flag" (readIt).
  -- When the flag goes to 1, the process exits the wait state and
  -- execute a read transaction.
  read : PROCESS
  BEGIN
    reg_led_mosi.arvalid<='0';
    reg_led_mosi.rready<='0';
     loop
         wait until readIt = '1';
         wait until mm_clk= '0';
             reg_led_mosi.arvalid<='1';
             reg_led_mosi.rready<='1';
         wait until (reg_led_miso.rvalid and reg_led_miso.arready) = '1';  --Client provided data
            wait until mm_clk= '0';
            assert reg_led_miso.rresp = "00" report "AXI data not read" severity failure;
             reg_led_mosi.arvalid<='0';
            reg_led_mosi.rready<='0';
     end loop;
  END PROCESS read;



 --
 tb : PROCESS
 BEGIN
        sendIt<='0';
    wait until mm_rst = '0';
    wait for 15 ns;

        reg_led_mosi.awaddr <= TO_AXI4_LITE_ADDRESS(0);
        reg_led_mosi.wdata  <= TO_AXI4_LITE_DATA(0);
        reg_led_mosi.wstrb  <= (OTHERS => '1');
        sendIt<='1';                --Start AXI Write to Slave
        wait for 1 ns; sendIt<='0'; --Clear Start Send Flag
    wait until reg_led_miso.bvalid = '1';
    wait until reg_led_miso.bvalid = '0';  --AXI Write finished
        reg_led_mosi.wstrb  <= (OTHERS => '0');
        reg_led_mosi.awaddr <= TO_AXI4_LITE_ADDRESS(0);
        reg_led_mosi.wdata  <= TO_AXI4_LITE_DATA(1);
        reg_led_mosi.wstrb  <= (OTHERS => '1');
        sendIt<='1';                --Start AXI Write to Slave
        wait for 1 ns; sendIt<='0'; --Clear Start Send Flag
    wait until reg_led_miso.bvalid = '1';
    wait until reg_led_miso.bvalid = '0';  --AXI Write finished
        reg_led_mosi.wstrb  <= (OTHERS => '0');
        reg_led_mosi.awaddr <= TO_AXI4_LITE_ADDRESS(0);
        reg_led_mosi.wdata  <= TO_AXI4_LITE_DATA(2);
        reg_led_mosi.wstrb  <= (OTHERS => '1');
        sendIt<='1';                --Start AXI Write to Slave
        wait for 1 ns; sendIt<='0'; --Clear Start Send Flag
    wait until reg_led_miso.bvalid = '1';
    wait until reg_led_miso.bvalid = '0';  --AXI Write finished
        reg_led_mosi.wstrb  <= (OTHERS => '0');
        reg_led_mosi.awaddr <= TO_AXI4_LITE_ADDRESS(0);
        reg_led_mosi.wdata  <= x"A5A5A5A5";
        reg_led_mosi.wstrb  <= (OTHERS => '1');
        sendIt<='1';                --Start AXI Write to Slave
        wait for 1 ns; sendIt<='0'; --Clear Start Send Flag
    wait until reg_led_miso.bvalid = '1';
    wait until reg_led_miso.bvalid = '0';  --AXI Write finished
        reg_led_mosi.wstrb  <= (OTHERS => '0');
        reg_led_mosi.araddr <= TO_AXI4_LITE_ADDRESS(0);
        readIt<='1';                --Start AXI Read from Slave
        wait for 1 ns; readIt<='0'; --Clear "Start Read" Flag
    wait until reg_led_miso.rvalid = '1';
    wait until reg_led_miso.rvalid = '0';
        reg_led_mosi.araddr <= TO_AXI4_LITE_ADDRESS(4);
        readIt<='1';                --Start AXI Read from Slave
        wait for 1 ns; readIt<='0'; --Clear "Start Read" Flag
    wait until reg_led_miso.rvalid = '1';
    wait until reg_led_miso.rvalid = '0';

      sim_finished <= '1';
      tb_end <= '1';
      wait for 1 us;
      REPORT "Finished Simulation" SEVERITY FAILURE;
      WAIT;
 END PROCESS tb;


END tb;
