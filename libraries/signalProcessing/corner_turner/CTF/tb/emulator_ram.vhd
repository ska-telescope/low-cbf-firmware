---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Coarse (CTC) - EMULATOR RAM 
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert_abel@gmx.net)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- This module instantiates the XPM memory for the emulator. 
-- The XPM primitive size can not exceed 2^17 bits.
-- If more memory is needed, this module instantiates multiple XPM primitives.
--
-- Please note that Modelsim potentially allocates a lot of memory to do this.
-- You can easily crash your machine by using too much memory this way.
-- A full PISA setup lead to more than 150GB of memory used - which is where I stopped this.
-- Recommendation: if using big generic values, keep a permanent eye on the memory consumption.
-- Abort if need be. 
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

Library xpm;
use xpm.vcomponents.all;

use work.ctf_pkg.all;

entity emulator_ram is
    generic (
        g_FULL_DEPTH      : natural := 10000;
        g_PRIMITIVE_DEPTH : natural := 4096;
        g_DATA_WIDTH      : natural := 256
    );
    Port (
        clka  : in   std_logic;
        clkb  : in   std_logic;
        rstb  : in   std_logic;
        wea   : in   std_logic;
        addra : in   std_logic_vector(log2_ceil(g_FULL_DEPTH)-1 downto 0);
        dina  : in   std_logic_vector(g_DATA_WIDTH-1 downto 0);
        addrb : in   std_logic_vector(log2_ceil(g_FULL_DEPTH)-1 downto 0);
        doutb : out  std_logic_vector(g_DATA_WIDTH-1 downto 0)
    );
end emulator_ram;

architecture Behavioral of emulator_ram is

    constant g_LOWER_BITS : natural := sel(g_FULL_DEPTH>g_PRIMITIVE_DEPTH, log2_ceil(g_PRIMITIVE_DEPTH), log2_ceil(g_FULL_DEPTH));
    constant g_UPPER_BITS : natural := sel(g_FULL_DEPTH>g_PRIMITIVE_DEPTH, log2_ceil(g_FULL_DEPTH) - g_LOWER_BITS, 0);

    constant g_PRIM_DEPTH : natural := sel(g_FULL_DEPTH>g_PRIMITIVE_DEPTH, g_PRIMITIVE_DEPTH, g_FULL_DEPTH);

    constant g_PRIMITIVE_COUNT : natural := 2**g_UPPER_BITS;

    type t_dout_array is array (g_PRIMITIVE_COUNT-1 downto 0) of std_logic_vector(g_DATA_WIDTH-1 downto 0);
    signal dout_array : t_dout_array;
    
    signal p1_addrb : std_logic_vector(log2_ceil(g_FULL_DEPTH)-1 downto 0);

begin

    assert g_PRIMITIVE_DEPTH=2**(log2_ceil(g_PRIMITIVE_DEPTH)) report "g_PRIMITIVE_DEPTH has to be a power of 2!" severity FAILURE;

    GEN_PRIMS: for prim in 0 to g_PRIMITIVE_COUNT-1 generate
        signal prim_wea : std_logic;
    begin    
        
        GEN_SELECT: if g_UPPER_BITS>0 generate
            prim_wea <= '1' when to_integer(unsigned(addra(g_UPPER_BITS+g_LOWER_BITS-1 downto g_LOWER_BITS)))=prim else '0';
        else generate
            prim_wea <= '1';
        end generate;    
        
        BRAM : xpm_memory_sdpram
        generic map (
            ADDR_WIDTH_A => g_LOWER_BITS,     
            ADDR_WIDTH_B => g_LOWER_BITS,     
            AUTO_SLEEP_TIME => 0,            
            BYTE_WRITE_WIDTH_A => g_DATA_WIDTH,   
            CLOCKING_MODE => "common_clock", 
            ECC_MODE => "no_ecc",            
            MEMORY_INIT_FILE => "none",      
            MEMORY_INIT_PARAM => "0",        
            MEMORY_OPTIMIZATION => "true",   
            MEMORY_PRIMITIVE => "bram",      
            MEMORY_SIZE => g_PRIM_DEPTH*g_DATA_WIDTH,   
            MESSAGE_CONTROL => 0,           
            READ_DATA_WIDTH_B => g_DATA_WIDTH,   
            READ_LATENCY_B => 1,            
            READ_RESET_VALUE_B => "0",      
            USE_EMBEDDED_CONSTRAINT => 0,   
            USE_MEM_INIT => 0,              
            WAKEUP_TIME => "disable_sleep", 
            WRITE_DATA_WIDTH_A => g_DATA_WIDTH,  
            WRITE_MODE_B => "no_change"     
        )
        port map (
            clka  => clka,
            clkb  => clkb,
            rstb  => rstb,
            --di:
            ena   => '1',     
            wea   => (others => wea and prim_wea),
            addra => addra(g_LOWER_BITS-1 downto 0),      
            dina  => dina,       
            --do:
            enb   => '1',      
            addrb => addrb(g_LOWER_BITS-1 downto 0),     
            doutb => dout_array(prim), 
            --unused:
            sleep => '0',
            injectsbiterra => '0',
            injectdbiterra => '0',
            regceb         => '1'
        );
    end generate;    
    
    P_DELAY: process(clkb)
    begin
        if rising_edge(clkb) then
            p1_addrb <= addrb;
        end if;
    end process;
    
    GEN_SELECT: if g_UPPER_BITS>0 generate
        doutb <= dout_array(to_integer(unsigned(p1_addrb(g_UPPER_BITS+g_LOWER_BITS-1 downto g_LOWER_BITS))));
    else generate
        doutb <= dout_array(0);
    end generate;    
     
    
end Behavioral;
