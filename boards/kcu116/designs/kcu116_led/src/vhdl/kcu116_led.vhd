-------------------------------------------------------------------------------
--
-- Copyright (C) 2016
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

LIBRARY IEEE, UNISIM, common_lib, axi4_lib, technology_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE UNISIM.vcomponents.all;
USE technology_lib.technology_pkg.ALL;

ENTITY kcu116_led IS
  Port ( 
        SYSCLK_300_N : in std_logic;
        SYSCLK_300_P : in std_logic;
        o_led        : out STD_LOGIC_VECTOR (7 downto 0)
  );
END kcu116_led;


ARCHITECTURE str OF kcu116_led IS

    signal clk300     : std_logic;
    signal clk_raw    : std_logic;
    signal led        : unsigned(31 downto 0) := (others => '0');

BEGIN

    IBUFDS_inst : IBUFDS
    port map (
        O => clk_raw, 
        I => SYSCLK_300_P,
        IB => SYSCLK_300_N
    );
    
    BUFGCE_1_inst : BUFGCE_1
    port map (
        O  => clk300,
        CE => '1' , 
        I  => clk_raw
    );

    P_LED: process(clk300)
    begin
        if rising_edge(clk300) then
            led <= led + 1;
        end if;
    end process;

    o_led <= std_logic_vector(led(31 downto 24));


END str;
