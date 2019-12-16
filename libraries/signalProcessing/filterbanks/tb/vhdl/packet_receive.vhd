----------------------------------------------------------------------------------
-- Company:  CSIRO
-- Engineer: David Humphrey (dave.humphrey@csiro.au)
-- 
-- Create Date:    12:17:33 03/02/2010 
-- Module Name:    packet_receive - Behavioral 
-- Description: 
--   Logs data from a packet interface to a file.
--
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use std.textio.all;
use IEEE.std_logic_textio.all;

--library textutil;       -- Synposys Text I/O package
--use textutil.std_logic_textio.all;

entity packet_receive is
   Generic (
      BIT_WIDTH : integer := 32;
      log_file_name : string := "logfile.txt"
   );
   Port ( 
      clk     : in  std_logic;     -- clock
      rst_i   : in  std_logic;     -- reset input
      din0_i  : in  std_logic_vector((BIT_WIDTH - 1) downto 0);  -- actual data out.
      din1_i  : in  std_logic_vector((BIT_WIDTH - 1) downto 0); 
      valid_i : in  std_logic;     -- data out valid (high for duration of the packet)
      rdy_o   : out std_logic      -- module we are sending the packet to is ready to receive data.
   );
end packet_receive;

architecture Behavioral of packet_receive is

   signal do_write : std_logic;
   signal valid_del : std_logic;
   constant FOUR0 : std_logic_vector(3 downto 0) := "0000";
   constant FOUR1 : std_logic_vector(3 downto 0) := "0001";
   constant T0 : std_logic_vector((BIT_WIDTH-1) downto 0) := (others => '0');

   signal rdy_count : std_logic_vector(15 downto 0) := x"0000";

begin

   process(clk)
   begin
      if rising_edge(clk) then
         valid_del <= valid_i;
      end if;
      
      rdy_count <= rdy_count + 1;
      rdy_o <= '1'; --  rdy_count(12);
      
   end process;
   

   -- write to the file when we receive packet data or we reach the end of the packet (valid transitions from 1 to 0).
   do_write <= '1' when valid_i = '1' or (valid_i = '0' and valid_del = '1') else '0';
   
	cmd_store_proc : process
		file logfile: TEXT;
      
		variable data_in : std_logic_vector((BIT_WIDTH-1) downto 0);
		variable line_out : Line;
      
	begin
	   FILE_OPEN(logfile,log_file_name,WRITE_MODE);
		
		loop
			-- wait until we need to read another command
			-- need to when : rising clock edge, and last_cmd_cycle high
			-- read the next entry from the file and put it out into the command queue.
         wait until (rising_edge(clk) and do_write = '1');
         if valid_i = '1' then
            -- write data to the file
            hwrite(line_out,FOUR1,RIGHT,2);
            hwrite(line_out,din0_i,RIGHT,6);
            hwrite(line_out,din1_i,RIGHT,6);
         else
            -- no data, write gap to the file
            hwrite(line_out,FOUR0,RIGHT,2);
            hwrite(line_out,T0,RIGHT,6);
            hwrite(line_out,T0,RIGHT,6);
         end if;
         
         writeline(logfile,line_out);
         
      end loop;
      file_close(logfile);	
      wait;
   end process cmd_store_proc;


end Behavioral;

