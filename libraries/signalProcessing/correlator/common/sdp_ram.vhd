-------------------------------------------------------------------------------
-- Title      : Wrapper for a simple dual port RAM
-- Project    : CSP
-------------------------------------------------------------------------------
-- File       : sdp_ram.vhd
-- Author     : William Kamp  <william.kamp@aut.ac.nz>
-- Company    : 
-- Created    : 2015-10-01
-- Platform   : 
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: Entity declaration for a Simple Dual Port RAM.
-- Needs to be attached to an appropriate architecture that implements it for a
-- particular family of chips.
-------------------------------------------------------------------------------
-- Copyright (c) 2015 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2015-10-06  1.0      wkamp	Created
-- 2019-09-16  2.0p     nabel   Ported to Perentie
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.misc_tools_pkg.all;


entity sdp_ram is
  
  generic (
    g_REG_OUTPUT : boolean := false);

  port (
    i_clk       : in std_logic;
    i_clk_reset : in std_logic;
    i_wr_addr   : in unsigned;
    i_wr_en     : in std_logic;
    i_wr_data   : in std_logic_vector;
    i_rd_addr   : in unsigned;
    i_rd_en     : in std_logic;
    o_rd_data   : out std_logic_vector
    );

end entity sdp_ram;

architecture rtl of sdp_ram is

    type t_memory is array (2**i_wr_addr'length-1 downto 0) of std_logic_vector(i_wr_data'range);

    signal ram : t_memory := (others => (others => '0'));

    signal rd_data : std_logic_vector(o_rd_data'range);

begin  -- architecture rtl

    P_WRITE : process (i_clk) is
    begin
        if rising_edge(i_clk) then
            if i_wr_en='1' then
                ram(to_integer(to_01(i_wr_addr))) <= i_wr_data;
            end if;
        end if;
    end process;

    P_READ : process (i_clk) is
    begin
        if rising_edge(i_clk) then
            if i_rd_en='1' then
                rd_data <= ram(to_integer(to_01(i_rd_addr)));
            end if;
        end if;
    end process;

    G_OUT_FLOP : if g_REG_OUTPUT generate
        P_FLOP : process (i_clk) is
        begin
            if rising_edge(i_clk) then
                o_rd_data <= rd_data;
            end if;
        end process;
    end generate;

    G_NO_OUT_FLOP : if not g_REG_OUTPUT generate
        o_rd_data <= rd_data;
    end generate;

end architecture rtl;
