-------------------------------------------------------------------------------
-- Author : David Humphrey (dave.humphrey@csiro.au)
-- Integer divider. Calculates one bit per clock.
-- Not pipelined, so only accepts new data when the previous division is
-- complete. For a pipelined version, use the Xilinx library component.
--
-------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.common_pkg.ALL;

entity common_divide is
    generic (
        BitsNumerator   : integer;  -- Number of bits in the numerator
        BitsDenominator : integer;  -- Number of bits in the denominator
        BitsInt         : integer;  -- Number of integer bits to generate
        BitsFrac        : integer  -- Number of fractional bits to generate
    );
    port (
        rst   : in std_logic := '0';
        clk   : in std_logic;
        rdy_o : out std_logic;
        valid_i : in std_logic;
        numerator_i   : in std_logic_vector((BitsNumerator - 1) downto 0);
        denominator_i : in std_logic_vector((BitsDenominator - 1) downto 0);
        quotient_o : out std_logic_vector((BitsInt + BitsFrac - 1) downto 0);
        valid_o : out std_logic
    );
end common_divide;


architecture rtl of common_divide is
    
    signal stepCount : natural range 0 to (BitsInt + BitsFrac + 8);
    signal denominatori : std_logic_vector((BitsDenominator + bitsInt - 1) downto 0);
    signal numeratori, numeratorSub : std_logic_vector((BitsNumerator + bitsFrac - 1) downto 0);
    signal quotienti : std_logic_vector((BitsInt + BitsFrac - 1) downto 0);
    signal validi : std_logic;
    
begin

    valid_o <= validi;
    quotient_o <= quotienti;
  
    process(rst, clk)
    begin
        if rst='1' then
            stepCount <= 0;
        elsif rising_edge(clk) then
            if stepCount /= 0 or valid_i = '1' then
                rdy_o <= '0';
            else
                rdy_o <= '1';
            end if;

            if valid_i = '1' and stepCount = 0 then
                denominatori((bitsDenominator + BitsInt - 1) downto bitsInt) <= denominator_i;
                denominatori((bitsInt - 1) downto 0) <= (others => '0');
                numeratori((bitsNumerator + BitsFrac - 1) downto BitsFrac) <= numerator_i;
                numeratori((BitsFrac - 1) downto 0) <= (others => '0');
                stepCount <= 1;
                validi <= '0';           
            elsif stepCount /= 0 then
                numeratorSub <= std_logic_vector(signed(numeratori) - signed(denominatori));
                denominatori((BitsDenominator + bitsInt - 2) downto 0) <= denominatori((BitsDenominator + bitsInt - 1) downto 1);
--                if numeratorSub'high = '1' then
--                    numeratori <= numeratorSub;
--                    quotienti(0) <= '1';
--                else
                    quotienti(0) <= '0';
--                end if;
                quotienti((BitsInt + BitsFrac - 1) downto 1) <= quotienti((BitsInt + BitsFrac - 2) downto 0);
                if stepCount = (BitsInt + BitsFrac) then
                    stepCount <= 0;
                    validi <= '1';
                else
                    stepCount <= stepCount + 1;
                    validi <= '0';
                end if;
            else
                validi <= '0';
            end if;
            
        end if;
    end process;
     
      
end rtl;
