---------------------------------------------------------------------------------------------------
-- 
-- Recursive Permutation - Full/Empty Indicator 
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert.abel@autac.nz)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- This entity is part of the Recursive Permutation architecture.
-- It calculates if the Buffer is full or emtpy (i.e. can be written to or read from). 
--
-- This calculation only depends on w_x and r_x, not on the actual read or write adresses.
-- r_x represents the position in the permutation vector (r_addr is the r_x'th address in the FRAME)
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

entity buffer_level_indicator is
    generic (
        g_ADDR_RANGE       : natural;
        g_ADDR_RANGE_LOG2  : natural range log2_ceil(g_ADDR_RANGE) to log2_ceil(g_ADDR_RANGE) := log2_ceil(g_ADDR_RANGE);
        g_ATOM_SIZE        : natural;
        g_INPUT_STOP_WORDS : natural range 1 to 1
    );
    port ( i_clk          : in STD_LOGIC;
           i_rst          : in STD_LOGIC;
           i_write_enable : in std_logic;
           i_w_x          : in unsigned(g_ADDR_RANGE_LOG2-1 downto 0);
           i_w_atom_count : in unsigned(maxi(log2_ceil(g_ATOM_SIZE)-1,0) downto 0);
           i_read_enable  : in std_logic;
           i_r_x          : in unsigned(g_ADDR_RANGE_LOG2-1 downto 0);
           i_r_atom_count : in unsigned(maxi(log2_ceil(g_ATOM_SIZE)-1,0) downto 0);
           o_empty        : out std_logic;
           o_full         : out std_logic
         );
end buffer_level_indicator;

architecture Behavioral of buffer_level_indicator is

    type t_state is (s_NOREAD_WRITE1, s_READ1_WRITE2); 
    signal state : t_state;

    signal just_got_full : std_logic;

begin
    
    --------------------------------------------------------------------
    -- BASIC STATE:
    -- Are we initially writing the first frame (s_NOREAD_WRITE1)
    -- or are we reading and writing (s_READ1_WRITE2)?
    --
    -- We return to s_NOREAD_WRITE1 when we reach the end of a FRAME.
    -- At this point read is enabled by a number of exceptions
    -- in the empty logic.
    --------------------------------------------------------------------
    P_FSM: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst='1' then
                state<=s_NOREAD_WRITE1;
            else
                case state is
                    when s_NOREAD_WRITE1 =>
                        if i_w_x = g_ADDR_RANGE-1 and i_write_enable='1' and i_w_atom_count=g_ATOM_SIZE-1 then
                            state<=s_READ1_WRITE2;                            
                        end if;
                    when s_READ1_WRITE2 =>
                        --the last read is happening in s_NOREAD_WRITE1 (through exceptions for empty)
                        if g_ATOM_SIZE=1 then
                            if (i_r_x = g_ADDR_RANGE-2) and i_read_enable='1'then
                                state<=s_NOREAD_WRITE1;
                            end if;
                        else
                            if (i_r_x = g_ADDR_RANGE-1) and i_read_enable='1' and i_r_atom_count=g_ATOM_SIZE-2 then
                                state<=s_NOREAD_WRITE1;
                            end if;
                        end if;    
                end case;
            end if;
        end if;    
    end process;


    --------------------------------------------------------------------
    -- EMPTY LOGIC:
    --
    -- The exceptions are used to allow a read/write
    -- overlap at the end of a frame.
    -- They are based on the fact that the first address is always 0
    -- and the last address is always (FRAMESIZE-1), and we therefore
    -- know that they differ from any other address read or written. 
    --------------------------------------------------------------------
    P_EMPTY: process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst='1' then
                o_empty <= '1'; 
            else
                if state=s_NOREAD_WRITE1 then
                    if just_got_full='1' then
                        o_empty<='0';
                    elsif i_r_x = 0 and i_w_x /= 0 and (i_read_enable='0' or i_r_atom_count/=g_ATOM_SIZE-1) then
                        --fist read address is always different from other addresses
                        o_empty<='0';
                    elsif i_r_x = g_ADDR_RANGE-1 and i_w_x/=0 and i_read_enable='1' and i_r_atom_count=g_ATOM_SIZE-1 then
                        --LOOK_AHEAD: first read address is always different from other addresses
                        o_empty<='0';
                    elsif i_r_x = g_ADDR_RANGE-1 and i_w_x=0 and (i_read_enable='0' or i_r_atom_count/=g_ATOM_SIZE-1)  then
                        --finish readout in stutter situation
                        o_empty<='0';
                    elsif i_write_enable='1' and i_w_atom_count=g_ATOM_SIZE-1 and i_w_x = g_ADDR_RANGE-2 and (i_r_x=0 or i_r_x=1)  then
                        --LOOK_AHEAD: last write address is always different from other addresses
                        o_empty<='0';
                    elsif i_w_x = g_ADDR_RANGE-1 and (i_r_x=0 or i_r_x=1) then
                        --last write address is always different from other addresses
                        --plus: after last write we are not empty for quite a while
                        o_empty<='0';
                    else
                        o_empty<='1';
                    end if;    
                else
                    o_empty<='0';
                end if;    
            end if;
        end if;
    end process;
    
    
    --------------------------------------------------------------------
    -- FULL LOGIC:
    --------------------------------------------------------------------
    P_FULL: process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst='1' then
                o_full        <= '1';
                just_got_full <= '0' ;
            else
                if    ((i_w_x=i_r_x) and (just_got_full='1'))                     --distance 0 and just got full (in contrast to empty)
                  or  ((i_w_x=i_r_x-1) or (i_w_x=g_ADDR_RANGE-1 and i_r_x=0))     --distance 1
                  or  ((i_write_enable='1' and i_read_enable='0') and             --distance 2 - removing this would make full an ir_n signal
                       ((i_w_x=i_r_x-2) or (i_w_x=g_ADDR_RANGE-2 and i_r_x=0) or (i_w_x=g_ADDR_RANGE-1 and i_r_x=1))
                      )
                then
                    o_full        <= '1';
                    just_got_full <= '1';
                else
                    o_full        <= '0';
                    just_got_full <= '0';
                end if;
            end if;
        end if;
    end process;

end Behavioral;
