---------------------------------------------------------------------------------------------------
-- 
-- Recursive Permutation - Address Permuter 
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert.abel@autac.nz)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- This entity is part of the Recursive Permutation architecture.
-- It starts with an initial inc of g_INITIAL_INC and calculates the
-- next inc value representing (IP)^(n+1), which is used as soon as
-- the next FRAME is reached.
--
-- For more information on Recursive Permutation see Confluence.
--
---------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

library work;
use work.ctf_pkg.all;

entity address_permuter is
    Generic (
        g_ADDR_RANGE      : natural;                         -- Size of the FRAME
        g_ADDR_RANGE_LOG2 : natural range log2_ceil(g_ADDR_RANGE) to log2_ceil(g_ADDR_RANGE) := log2_ceil(g_ADDR_RANGE);
        g_BLOCK_SIZE      : natural range 4 to integer'HIGH; -- Blocksize in Atoms
        g_ATOM_SIZE       : natural;                         -- used to determine when to jump to the next address
        g_INITIAL_INC     : natural                          -- determines with which permutation we start (Read starts with (IP)^1, Write with (IP)^0)
    );
    Port (
        i_clk        : in  std_logic;  -- input clock
        i_rst        : in  std_logic;  -- global reset
        i_next       : in  std_logic;  -- request next address
        o_addr       : out std_logic_vector(g_ADDR_RANGE_LOG2-1 downto 0);      -- next address
        o_x          : out unsigned(g_ADDR_RANGE_LOG2-1 downto 0);              -- x represents the position in the permutation vector (o_addr is the o_x'th address in the FRAME)
        o_atom_count : out unsigned(maxi(log2_ceil(g_ATOM_SIZE)-1,0) downto 0)  -- count at which atom you are 
    );
end address_permuter;

architecture Behavioral of address_permuter is
    
    constant g_MODULO : natural := g_ADDR_RANGE-1;
    
    signal x          : unsigned(g_ADDR_RANGE_LOG2-1 downto 0);
    signal addr       : unsigned(g_ADDR_RANGE_LOG2   downto 0);
    signal next_addr  : unsigned(g_ADDR_RANGE_LOG2   downto 0);
    signal inc        : unsigned(g_ADDR_RANGE_LOG2   downto 0);
    signal next_inc   : unsigned(g_ADDR_RANGE_LOG2+1 downto 0);
    signal inc_done   : std_logic;
    signal inc_x      : unsigned(g_ADDR_RANGE_LOG2-1   downto 0);
    signal atom_count : unsigned(maxi(log2_ceil(g_ATOM_SIZE)-1,0) downto 0);    

begin

    P_READ: process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst='1' then
                next_addr  <= to_unsigned(g_INITIAL_INC, next_addr'length);
                addr       <= to_unsigned(0, addr'length);
                x          <= to_unsigned(0, x'length);
                inc        <= to_unsigned(g_INITIAL_INC, inc'length);
                atom_count <= (others => '0');
            else
                if i_next='1' then
                    
                    atom_count <= atom_count+1;

                    if g_ATOM_SIZE=1 or atom_count=g_ATOM_SIZE-1 then
                        atom_count <= (others=>'0');
                    
                        --addr <= (addr + inc) rem g_MODULO
                        if next_addr>=g_MODULO then
                            addr      <= next_addr       - to_unsigned(g_MODULO, next_addr'length);
                            next_addr <= next_addr + inc - to_unsigned(g_MODULO, next_addr'length);
                        else
                            addr      <= next_addr;
                            next_addr <= next_addr + inc;
                        end if;
                        if x = g_ADDR_RANGE-2 then
                            --exception for the last address of a block
                            addr      <= to_unsigned(g_MODULO, addr'length);
                            next_addr <= (others=>'0'); 
                        end if;
                        if x = g_ADDR_RANGE-1 then
                            --start a new block, change the permutation
                            assert inc_done='1' report "r_next_inc did not finish to calculate!" severity FAILURE;
                            addr      <= (others => '0');
                            next_addr <= next_inc(next_addr'range);
                            inc       <= next_inc(inc'range);
                        end if;    
                        
                        if x = g_ADDR_RANGE-1 then
                            x <= (others => '0');
                        else
                            x <= x + 1;
                        end if;
                    end if;        
                end if;
            end if;
        end if;
    end process;
    
    P_NEXT_INC: process(i_clk)
    begin
        --next_inc  <= (next_inc * g_BLOCK_SIZE) rem g_MODULO
        if rising_edge(i_clk) then
            if i_rst='1' then
                next_inc <= to_unsigned(g_BLOCK_SIZE, next_inc'length);
                inc_done <= '1';
                inc_x    <= (others => '0');
            else
                if x = 0 and atom_count=0 then
                    next_inc <= inc(g_ADDR_RANGE_LOG2-1 downto 0) & B"00"; --*4 
                    inc_done <= '0';
                    inc_x    <= to_unsigned(4, inc_x'length);
                elsif inc_done='0' then
                    if next_inc > g_MODULO then
                        next_inc <= next_inc - g_MODULO;
                    elsif inc_x = g_BLOCK_SIZE then
                        inc_done <= '1';
                    else
                        next_inc <= next_inc + inc;
                        inc_x    <= inc_x + 1;
                    end if;    
                end if;                                                       
            end if;    
        end if;
    end process;
    
    o_addr       <= std_logic_vector(addr(o_addr'range));
    o_x          <= x;
    o_atom_count <= atom_count;

end Behavioral;
