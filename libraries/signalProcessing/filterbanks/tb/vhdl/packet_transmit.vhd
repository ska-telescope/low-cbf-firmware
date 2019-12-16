----------------------------------------------------------------------------------
-- Company:  CSIRO
-- Engineer: David Humphrey (dave.humphrey@csiro.au)
-- 
-- Create Date:    08:27:43 03/02/2010 
-- Module Name:    packet_transmit - Behavioral 
-- Description: 
--   This is a testbench model for sending data packets.
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use std.textio.all;
use IEEE.std_logic_textio.all;

entity packet_transmit is
    Generic (
        BIT_WIDTH : integer := 32;
        cmd_file_name : string := "packet_cmds.txt"
    );
    port ( 
        clk     : in  std_logic;     -- clock
        rdy_i   : in  std_logic;     -- reset input
        valid_o : out std_logic;
        dout_o  : out std_logic_vector((BIT_WIDTH - 1) downto 0)  -- actual data out.
    );
end packet_transmit;

architecture Behavioral of packet_transmit is
    
    signal cur_cmd : std_logic_vector(3 downto 0);
    signal cur_data : std_logic_vector((BIT_WIDTH-1) downto 0);
    signal next_data : std_logic_vector((BIT_WIDTH-1) downto 0);
   
    signal ftdi_d_int : std_logic_vector((BIT_WIDTH-1) downto 0);

    signal get_a_cmd : std_logic;
    signal timer_count : integer;

    function lower_case(c : character) return character is
    begin
        if c >= 'A' and c <= 'Z' then
            return character'val(character'pos(c) + 32);
        else 
            return c;
        end if;
    end;

    -- compare two strings ignoring case
    function strcmp(a, b : string) return boolean is
        alias a_val : string(1 to a'length) is a;
        alias b_val : string(1 to b'length) is b;
        variable a_char, b_char : character;
    begin
        if a'length /= b'length then
            return false;
        elsif a = b then
            return true;
        end if;
        for i in 1 to a'length loop
            a_char := lower_case(a_val(i));
            b_char := lower_case(b_val(i));
            if a_char /= b_char then
                return false;
            end if;
        end loop;
        return true;
    end;

begin

    valid_o <= cur_cmd(0);
    dout_o <= cur_data;
   
    cmd_store_proc : process
        file cmdfile: TEXT;
        variable data_in : std_logic_vector((BIT_WIDTH-1) downto 0);
        variable cmd_in : std_logic_vector(3 downto 0);
        variable wait_length : std_logic_vector(31 downto 0);
  
        procedure get_a_command(file cmdfile: TEXT;
                                variable cmd : out std_logic_vector(3 downto 0);
                                variable argument : out std_logic_vector((BIT_WIDTH-1) downto 0)) is
            variable line_in : Line;
            variable cmd_str : string(1 to 2);
            variable data : std_logic_vector((BIT_WIDTH-1) downto 0);
            variable cmd1 : std_logic_vector(3 downto 0);
            variable good : boolean;   -- Status of the read operations
        begin
            if (not endfile(cmdfile)) then
                readline(cmdfile,line_in);
            end if;
            -- skip empty lines and lines starting with comment character #
            while (not endfile(cmdfile)) and ((line_in'length = 0) or (line_in(line_in'left) = '#')) loop
                readline(cmdfile,line_in);
            end loop;
            if endfile(cmdfile) then  -- Check EOF
                data := (others => '0');
            else
                hread(line_in,cmd1,good);
                assert good
                    report "Text I/O read error (data)"
                    severity ERROR;                
                hread(line_in,data,good);     -- Read the data
                assert good
                    report "Text I/O read error (data)"
                    severity ERROR;
            end if;
            argument := data;
            cmd := cmd1;
        end procedure;
    
    begin
    
        FILE_OPEN(cmdfile,cmd_file_name,READ_MODE);
        cur_data <= (others => '0');
        cur_cmd <= "0000";
        loop
            -- wait until we need to read another command
            -- need to when : rising clock edge, and last_cmd_cycle high
            -- read the next entry from the file and put it out into the command queue.
            wait until (rising_edge(clk) and rdy_i = '1');
            
            get_a_command(cmdfile,cmd_in,data_in);
            cur_cmd <= cmd_in;
            cur_data <= data_in;
         
        end loop;
        file_close(cmdfile); 
        wait;
    end process cmd_store_proc;


end Behavioral;

