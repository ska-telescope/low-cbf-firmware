-------------------------------------------------------------------------------
-- Title      : Multiplier & Adder for the CMAC in Xilinx DSPs
-- Project    : 
-------------------------------------------------------------------------------
-- File       : mult_add.vhd
-- Author     : Norbert Abel  <norbert.abel@aut.ac.nz>
-- Company    : 
-- Created    : 2018-05-16
-- Last update: 2018-05-18
-- Platform   : 
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: Implements the Multiplier-Adder part of the CMAC
--              Input:  a, b       (each complex)
--              Output: p = a*(b') (complex) with b' = conjugate of b
--
-- Please Note: The output p_re is one too low if p_im is negative.
--              This is to be corrected in the accumulator.
--
---------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

ENTITY mult_add IS
    GENERIC (
        g_DSP_PIPELINE_CYCLES : natural range 4 to 4;     --sets the actual pipeline number and forces instantiating modules to use it
        g_BIT_WIDTH           : natural range 3 to 9 := 8
    );
    PORT (
        i_clk  : in std_logic;
        i_vld  : in std_logic;
        i_a_re : in signed (g_BIT_WIDTH-1 downto 0);
        i_a_im : in signed (g_BIT_WIDTH-1 downto 0);
        i_b_re : in signed (g_BIT_WIDTH-1 downto 0);
        i_b_im : in signed (g_BIT_WIDTH-1 downto 0);
        o_p_vld: out std_logic;
        o_p_re : out signed (2*g_BIT_WIDTH-1 downto 0);
        o_p_im : out signed (2*g_BIT_WIDTH-1 downto 0)
    );
END mult_add;

ARCHITECTURE struct OF mult_add IS
    
    signal dsp_1_in_a   : std_logic_vector(g_BIT_WIDTH*3-1 downto 0) := (others => '0');
    signal dsp_1_in_b   : std_logic_vector(g_BIT_WIDTH-1   downto 0);
    signal dsp_1_in_d   : std_logic_vector(g_BIT_WIDTH*3-1 downto 0);
    signal dsp_1_out    : std_logic_vector(g_BIT_WIDTH*4-1 downto 0);
    signal p1_im        : signed(g_BIT_WIDTH*2-1 downto 0);
    signal p1_re        : signed(g_BIT_WIDTH*2-1 downto 0);
    
    signal p_concat   : std_logic_vector(47 downto 0);
    
    signal dsp_2_in_a   : std_logic_vector(g_BIT_WIDTH*3-1 downto 0) := (others => '0');
    signal dsp_2_in_b   : std_logic_vector(g_BIT_WIDTH-1   downto 0);
    signal dsp_2_in_d   : std_logic_vector(g_BIT_WIDTH*3-1 downto 0);
    signal dsp_2_out    : std_logic_vector(g_BIT_WIDTH*4-1 downto 0);
    signal p2_im        : signed(g_BIT_WIDTH*2-1 downto 0);
    signal p2_re        : signed(g_BIT_WIDTH*2-1 downto 0);
    
    --set the pipeline depth of the DSP here: 
    signal vld_chain  : std_logic_vector(g_DSP_PIPELINE_CYCLES-1 downto 0) := (others => '0');

begin

    P_VALID: process(i_clk)
    begin
        if rising_edge(i_clk) then
            vld_chain   <= vld_chain(vld_chain'high-1 downto 0) & i_vld;
        end if;    
    end process;

    -------------------------------------------------------
    -- DSP1: (A+D)*B_re
    -------------------------------------------------------
    
    dsp_1_in_d  <= std_logic_vector(resize(i_a_im, dsp_1_in_d'length));           --we do A+D
    dsp_1_in_a  <= std_logic_vector(i_a_re) & (g_BIT_WIDTH*2-1 downto 0 => '0');  --bits 23 downto 16 are the overlapping ones
    dsp_1_in_b  <= std_logic_vector(i_b_re);
    
    DSP1 : entity work.mult_add_dsp
    GENERIC MAP (
        g_BIT_WIDTH           => g_BIT_WIDTH,
        g_USE_PCIN            => false,
        g_AD_ADD_SUBn         => true,
        g_MREG                => 0
    ) PORT MAP (
        i_CLK => i_clk,
        i_A => dsp_1_in_a,
        i_D => dsp_1_in_d,
        i_B => dsp_1_in_b,
        o_P => dsp_1_out,
        o_PCOUT => p_concat
    );
    
    --for debug only:
    p1_im <= signed(dsp_1_out(g_BIT_WIDTH*2-1 downto 00));
    p1_re <= signed(dsp_1_out(g_BIT_WIDTH*4-1 downto g_BIT_WIDTH*2)) - signed(dsp_1_out(g_BIT_WIDTH*2-1 downto g_BIT_WIDTH*2-1));
    
    
    -------------------------------------------------------
    -- DSP2: (A+D)*B_im
    -------------------------------------------------------
    dsp_2_in_d  <= std_logic_vector(i_a_im) & (g_BIT_WIDTH*2-1 downto 0 => '0'); --we do D-A
    dsp_2_in_a  <= std_logic_vector(resize(i_a_re, dsp_2_in_d'length));          --bits 23 downto 16 are the overlapping ones
    dsp_2_in_b  <= std_logic_vector(i_b_im);                                     --conjugate is hidden in the multiplier/adder math
    
    DSP2 : entity work.mult_add_dsp
    GENERIC MAP (
        g_BIT_WIDTH   => g_BIT_WIDTH,
        g_USE_PCIN    => true,
        g_AD_ADD_SUBn => false,
        g_MREG        => 1
    ) PORT MAP (
        i_CLK => i_clk,
        i_A => dsp_2_in_a,
        i_D => dsp_2_in_d,
        i_B => dsp_2_in_b,
        i_PCIN => p_concat,
        o_P => dsp_2_out
    );
    
    -------------------------------------------------------
    -- NO OUTPUT CORRECTION
    -------------------------------------------------------
    -- o_p_re is exactly 1 too low if the imaginary part is negative
    -- The according output correction will take place in the accumulator
    
    o_p_re <= signed(dsp_2_out(g_BIT_WIDTH*4-1 downto g_BIT_WIDTH*2));  
    o_p_im <= signed(dsp_2_out(g_BIT_WIDTH*2-1 downto g_BIT_WIDTH*0));
    o_p_vld  <= vld_chain(vld_chain'high);

end struct;
