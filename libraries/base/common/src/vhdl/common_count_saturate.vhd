----------------------------------------------------------------------------------
-- Company: CSIRO
-- Engineer: David Humphrey (dave.humphrey@csiro.au)
-- 
-- Create Date: 15.03.2019 16:45:05
-- Module Name: common_count_saturate - Behavioral
-- Description: 
--  Saturating Counter. Saturates at all ones.
--  The determination of when saturation will occur uses a register stage, so there
--  should only be two levels of logic for counters less than 64 bits wide.
--  Place and route easily meets timing at 500 MHz on ultrascale+ parts. 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity common_count_saturate is
    generic(
        WIDTH : natural := 32
    );
    Port(
        enable   : in std_logic;  -- counts up whenever enable is high
        clk      : in std_logic; 
        rst      : in std_logic;  -- reset to zero.
        count    : out std_logic_vector(WIDTH-1 downto 0) 
    );
end common_count_saturate;

architecture Behavioral of common_count_saturate is

    signal cval : std_logic_vector((WIDTH-1) downto 0) := (others => '0');
    signal enable_del : std_logic;
    signal enable_final : std_logic;
    signal rst_del : std_logic;
    signal allhigh : std_logic;
    signal allhighTop : std_logic;
    constant allones : std_logic_vector((WIDTH-1) downto 0) := (others => '1');

begin

    process(clk)
    begin
        if rising_edge(clk) then
            enable_del <= enable;
            rst_del <= rst;
            
            if enable_del = '1' and (allhigh = '0' or 
                                     (allhigh = '1' and cval(1) = '0') or 
                                     (allhigh = '1' and cval(1 downto 0) = "10" and enable_final = '0')) then
                enable_final <= '1';
            else
                enable_final <= '0';
            end if;
            
            if rst_del = '1' then
                cval <= (others => '0');
            else
                if enable_final = '1' then
                    cval <= std_logic_vector(unsigned(cval) + 1);
                end if;
            end if;
        end if;
    end process;
    
    count <= cval;

    g32 : if WIDTH <= 32 generate
        process(clk)
        begin
            if rising_edge(clk) then
                if cval((WIDTH-1) downto 2) = allones((WIDTH-1) downto 2) then -- ((cval'left-1) => '1') then
                    allhigh <= '1';
                else
                    allhigh <= '0';
                end if;
            end if;
        end process;
    end generate;
    
    g64 : if WIDTH > 32 generate
        process(clk)
        begin
            if rising_edge(clk) then
                if cval((WIDTH-1) downto 32) = allones((WIDTH-1) downto 32) then -- ((cval'left-1) => '1') then
                    allhighTOP <= '1';
                else
                    allhighTOP <= '0';
                end if;
                
                if ((cval(31 downto 2) = allones(31 downto 2)) and (allhighTop = '1')) then
                    allhigh <= '1';
                else
                    allhigh <= '0';
                end if;
            end if;
        end process;       
    
    end generate;


end Behavioral;
