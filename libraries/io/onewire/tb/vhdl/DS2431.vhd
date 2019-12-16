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

ENTITY ds2431 IS
   GENERIC (
      g_dev_name     : string;                                          -- For display purposes
      g_rom          : STD_LOGIC_VECTOR(63 DOWNTO 0) := X"0F00000001B81C2D";
      g_mem_init     : t_slv_64_arr(0 TO 7) := (X"CCAAAABEFAC83474",
                                                X"CCA80808C0A80807",
                                                X"CC0000C0A808AAC0",
                                                X"F0F0F0F0F0F0F0F0",
                                                X"F0F0F0F0F0F0F0F0",
                                                X"F0F0F0F0F0F0F0F0",
                                                X"F0F0F0F0F0F0F0F0",
                                                X"F0F0F0F0F0F0F0F0"));
   PORT (
      onewire     : inout std_logic);
END ds2431;

ARCHITECTURE behavior OF ds2431 IS

   -- Simulation Model
   signal sim_onewire_oe            : STD_LOGIC := '1';
   SIGNAL sim_onewire_i             : STD_LOGIC;

begin


---------------------------------------------------------------------------
-- Onewire Test Model  --
---------------------------------------------------------------------------

   onewire <= '0' when sim_onewire_oe = '0' else 'Z';
   sim_onewire_i <= to_x01(onewire);

onewire_sim: process
      variable bit_count      : integer := 0;
      variable word_count     : integer := 0;
      variable bit_shifter    : std_logic_vector(7 downto 0);
      variable word_shifter   : std_logic_vector(15 downto 0);
      variable rom            : std_logic_vector(63 downto 0) := g_rom;
      
      VARIABLE write_address  : INTEGER;
      VARIABLE selected_row   : STD_LOGIC_VECTOR (63 DOWNTO 0);
      VARIABLE scratch        : STD_LOGIC_VECTOR (63 DOWNTO 0);
      VARIABLE mem_space      : t_slv_64_arr(0 TO 7) := g_mem_init;

      variable myline         : line;
      variable crc            : std_logic_vector(15 downto 0);
      
   function crc16(data: in std_logic_vector(7 downto 0);             
                  crc_i: in std_logic_vector(15 downto 0))
   return std_logic_vector is  
      variable crc_o : std_logic_vector(15 downto 0);
   begin
      crc_o := crc_i;
      bit_loop: for i in 0 to 7 loop
         crc_o := (crc_o(0) xor data(i)) &
                   crc_o(15) &
                  (crc_o(14) xor (crc_o(0) xor data(i))) &
                   crc_o(13 downto 2) &
                   (crc_o(1) xor (crc_o(0) xor data(i)));
      end loop;
      return crc_o;
   end;      
      
      
      
      
      
   begin

      process_loop: loop

         wait until falling_edge(sim_onewire_i);
         wait for 100 us;
         if onewire = '1' then
            exit;
         end if;
         wait for 100 us;
         if onewire = '1' then
            exit;
         end if;
         wait for 100 us;
         if onewire = '1' then
            exit;
         end if;
         wait for 100 us;
         if onewire = '1' then
            exit;
         end if;
         wait for 50 us;
         if onewire = '1' then
            exit;
         end if;

         wait until rising_edge(sim_onewire_i);
         wait for 3 us;
         sim_onewire_oe <= '0';
         wait for 240 us;

         sim_onewire_oe <= '1';

         bit_count := 0;
         rom_cmd : loop
            wait until falling_edge(sim_onewire_i);
            wait for 45 us;
            bit_shifter := sim_onewire_i & bit_shifter(7 downto 1);
            if bit_count = 7 then
               exit;
            else
               bit_count := bit_count + 1;
            end if;
         end loop rom_cmd;

         write(myline, string'("-------------------"));
         writeline(output, myline);
         write(myline, string'("INFO: "));
         write(myline, g_dev_name);
         write(myline, string'(" Got ROM Command 0x"));
         hwrite(myline, bit_shifter);
         writeline(output, myline);

         bit_count := 0;
         if bit_shifter = X"33" then         -- Read ROM

            write_data : loop
               wait until falling_edge(sim_onewire_i);
               wait for 8 us;
               sim_onewire_oe <= rom(0);
               wait for 30 us;
               sim_onewire_oe <= '1';
               rom := '0' & rom(63 downto 1);
               if bit_count = 63 then
                  exit;
               else
                  bit_count := bit_count + 1;
               end if;
            end loop write_data;

         elsif bit_shifter = X"CC" then      -- Skip ROM

            bit_count := 0;
            mem_cmd : loop
               wait until falling_edge(sim_onewire_i);
               wait for 45 us;
               bit_shifter := sim_onewire_i & bit_shifter(7 downto 1);
               if bit_count = 7 then
                  exit;
               else
                  bit_count := bit_count + 1;
               end if;
            end loop mem_cmd;

            write(myline, string'("INFO: "));
            write(myline, g_dev_name);
            write(myline, string'(" Got Command 0x"));
            hwrite(myline, bit_shifter);
            writeline(output, myline);

            ------------
            if bit_shifter = X"F0" then      -- Read MEM

               bit_count := 0;
               read_arg1 : loop
                  wait until falling_edge(sim_onewire_i);
                  wait for 45 us;
                  word_shifter := sim_onewire_i & word_shifter(15 downto 1);
                  if bit_count = 15 then
                     exit;
                  else
                     bit_count := bit_count + 1;
                  end if;
               end loop read_arg1;

               write(myline, string'("INFO: "));
               write(myline, g_dev_name);
               write(myline, string'(" Read Address 0x"));
               hwrite(myline, word_shifter);
               writeline(output, myline);

               selected_row :=  mem_space(to_integer(unsigned(word_shifter(7 DOWNTO 3))));

               bit_count := 0;
               read_location : loop
                  wait until falling_edge(sim_onewire_i);
                  wait for 8 us;
                  sim_onewire_oe <= selected_row(0);
                  wait for 30 us;
                  sim_onewire_oe <= '1';
                  selected_row := '0' & selected_row(63 downto 1);
                  if bit_count = 63 then
                     exit;
                  else
                     bit_count := bit_count + 1;
                  end if;
               end loop;

            ------------
            elsif bit_shifter = X"0F" then      -- Write Scratchpad
               crc := crc16(bit_shifter, X"0000");          


               bit_count := 0;
               write_scratch_arg1 : loop
                  wait until falling_edge(sim_onewire_i);
                  wait for 45 us;
                  word_shifter := sim_onewire_i & word_shifter(15 downto 1);
                  if bit_count = 15 then
                     exit;
                  else
                     bit_count := bit_count + 1;
                  end if;
               end loop write_scratch_arg1;

               crc := crc16(word_shifter(7 DOWNTO 0), crc);
               crc := crc16(word_shifter(15 DOWNTO 8), crc);

               write(myline, string'("INFO: "));
               write(myline, g_dev_name);
               write(myline, string'(" Write Address 0x"));
               hwrite(myline, word_shifter);
               writeline(output, myline);

               write_address := to_integer(unsigned(word_shifter(7 DOWNTO 3)));

               word_count := 0;
               write_scratch_data_loop : loop
                  bit_count := 0;
                  write_scratch_byte_loop : loop
                     wait until falling_edge(sim_onewire_i);
                     wait for 45 us;
                     bit_shifter := sim_onewire_i & bit_shifter(7 downto 1);
                     if bit_count = 7 then
                        exit;
                     else
                        bit_count := bit_count + 1;
                     end if;
                  end loop write_scratch_byte_loop;

                  crc := crc16(bit_shifter, crc);

                  write(myline, string'("INFO: "));
                  write(myline, g_dev_name);
                  write(myline, string'(" Got data 0x"));
                  hwrite(myline, bit_shifter);
                  writeline(output, myline);

                  scratch := bit_shifter & scratch(63 DOWNTO 8);

                  if word_count = 7 then
                     exit;
                  else
                     word_count := word_count + 1;
                  end if;
               end loop write_scratch_data_loop;

               -- Write out CRC words
               word_shifter := not(crc);

               crc := crc16(not(word_shifter(7 DOWNTO 0)), crc);
               crc := crc16(not(word_shifter(15 DOWNTO 8)), crc);

               bit_count := 0;
               write_scratch_write_crc: loop
                  wait until falling_edge(sim_onewire_i);
                  wait for 8 us;
                  sim_onewire_oe <= word_shifter(0);
                  wait for 30 us;
                  sim_onewire_oe <= '1';
                  word_shifter := '0' & word_shifter(15 downto 1);

                  if bit_count = 15 then
                     exit;
                  else
                     bit_count := bit_count + 1;
                  end if;
               end loop write_scratch_write_crc;

            ------------
            elsif bit_shifter = X"AA" then      -- Read Scratchpad

               write(myline, string'("INFO: "));
               write(myline, g_dev_name);
               write(myline, string'(" Read Scratchpad"));
               writeline(output, myline);

               word_shifter := STD_LOGIC_VECTOR(to_unsigned(write_address*8, 16));

               bit_count := 0;
               read_scratch_write_crc: loop
                  wait until falling_edge(sim_onewire_i);
                  wait for 8 us;
                  sim_onewire_oe <= word_shifter(0);
                  wait for 30 us;
                  sim_onewire_oe <= '1';
                  word_shifter := '0' & word_shifter(15 downto 1);
                  
                  if bit_count = 23 then
                     exit;
                  else
                     bit_count := bit_count + 1;
                  end if;
               end loop read_scratch_write_crc;



            ------------
            elsif bit_shifter = X"55" then      -- Write Mem

               bit_count := 0;
               write_mem_arg1 : loop
                  wait until falling_edge(sim_onewire_i);
                  wait for 45 us;
                  word_shifter := sim_onewire_i & word_shifter(15 downto 1);
                  if bit_count = 15 then
                     exit;
                  else
                     bit_count := bit_count + 1;
                  end if;
               end loop write_mem_arg1;

               write(myline, string'("INFO: "));
               write(myline, g_dev_name);
               write(myline, string'(" Write Mem Address 0x"));
               hwrite(myline, word_shifter);
               writeline(output, myline);


               bit_count := 0;
               write_mem_arg2 : loop
                  wait until falling_edge(sim_onewire_i);
                  wait for 45 us;
                  bit_shifter := sim_onewire_i & bit_shifter(7 downto 1);
                  if bit_count = 7 then
                     exit;
                  else
                     bit_count := bit_count + 1;
                  end if;
               end loop write_mem_arg2;

               write(myline, string'("INFO: "));
               write(myline, g_dev_name);
               write(myline, string'(" Write Mem E/S 0x"));
               hwrite(myline, bit_shifter);
               writeline(output, myline);

               -- Save result
               mem_space(write_address) := scratch;

               -- Send finished word
               bit_shifter := X"AA";
               
               bit_count := 0;
               write_mem_write_result : loop
                  wait until falling_edge(sim_onewire_i);
                  wait for 8 us;
                  sim_onewire_oe <= bit_shifter(0);
                  wait for 30 us;
                  sim_onewire_oe <= '1';
                  bit_shifter := bit_shifter(0) & bit_shifter(7 downto 1);
                  
                  if bit_count = 7 then
                     exit;
                  else
                     bit_count := bit_count + 1;
                  end if;
               end loop write_mem_write_result;


            end if;
         end if;
      end loop process_loop;
   end process;


END;
