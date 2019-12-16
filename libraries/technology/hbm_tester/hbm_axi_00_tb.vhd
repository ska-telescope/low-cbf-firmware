----------------------------------------------------------------------------------
-- Company: Massey University
-- Engineer: Vignesh raja balu
-- 
-- Create Date: 09.05.2019 17:55:58
-- Design Name: 
-- Module Name: hbm_test - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.hbm_pkg.all;

entity hbm_test is
--  Port ( );
end hbm_test;

architecture Behavioral of hbm_test is
    constant g_FRAME_SIZE_BITS    : natural := 8;
    constant g_FRAME_COUNT_BITS   : natural := 8;
    constant g_BURST_BITS         : natural := 4;
    constant g_BURST_LEN          : natural := 12; -- ranges from 1 to 16
    constant g_WRITE_SKIP         : natural := 37;
    constant g_READ_SKIP          : natural := 37;

    signal clk_in_100_p : std_logic := '0';
    signal clk_in_100_n : std_logic := '0';

    alias rw_start is << signal .dut.rw_start : std_logic >>; 

begin
    --100MHz
    clk_in_100_p <= not clk_in_100_p after 5 ns;
    clk_in_100_n <= not clk_in_100_p;
    

    dut: entity work.hbm_input_gen 
    generic map(
        g_FRAME_SIZE_BITS    => g_FRAME_SIZE_BITS,
        g_FRAME_COUNT_BITS   => g_FRAME_COUNT_BITS,
        g_BURST_LEN          => g_BURST_LEN,
        g_WRITE_SKIP         => g_WRITE_SKIP,
        g_READ_SKIP          => g_READ_SKIP)
    Port map(              
        clk_in_100_p => clk_in_100_p,
        clk_in_100_n => clk_in_100_n
    );
    
    process
    begin
        wait for 50 us;
        rw_start <= force '1';
        wait;
    end process;

end Behavioral;

 