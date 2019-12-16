-------------------------------------------------------------------------------
-- Title      : Wrapper for a dual clock simple dual port RAM
-- Project    : CSP
-------------------------------------------------------------------------------
-- File       : dual_clock_simple_dual_port_ram.vhd
-- Author     : William Kamp  <william.kamp@aut.ac.nz>
-- Company    : 
-- Created    : 2015-10-01
-- Last update: 2018-01-08
-- Platform   : 
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description:
-- Dual Clock Simple Dual Port RAM
-- One write port in one clock domain.
-- One read port in another clock domain.
--
-- 
-- g_FORCE_TO_ZERO := true - Forces the read port to ZERO (others => '0'), when rd_en = '0'.
-- This is useful when stitching multiple RAMs together, as the multiplexer
-- can then be a OR-gate which will have better area and timing.
-- g_FORCE_TO_ZERO := false - Read output will hold its value when rd_en = '0'.
--
-- g_REG_OUTPUT := true. Add an additional flop to the output. Useful for timing.
-------------------------------------------------------------------------------
-- Copyright (c) 2015 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2015-10-06  1.0      wkamp   Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.misc_tools_pkg.all;


entity dual_clock_simple_dual_port_ram is

    generic (
        g_REG_OUTPUT    : boolean := false;
        g_FORCE_TO_ZERO : boolean := false);  -- Force o_rd_data to zero when i_rd_en = '0'.
    port (
        i_wr_clk       : in std_logic;
        i_wr_clk_reset : in std_logic;
        i_wr_addr      : in unsigned;
        i_wr_en        : in std_logic;
        i_wr_data      : in std_logic_vector;

        i_rd_clk       : in  std_logic;
        i_rd_clk_reset : in  std_logic;
        i_rd_addr      : in  unsigned;
        i_rd_en        : in  std_logic;
        o_rd_data      : out std_logic_vector
        );

end entity dual_clock_simple_dual_port_ram;

architecture rtl of dual_clock_simple_dual_port_ram is

    type t_memory is array (2**i_wr_addr'length-1 downto 0) of std_logic_vector(i_wr_data'range);

    signal ram : t_memory := (others => (others => '0'));

    signal rd_data : std_logic_vector(o_rd_data'range);

begin  -- architecture rtl

    P_WRITE : process (i_wr_clk) is
    begin
        if rising_edge(i_wr_clk) then
            if i_wr_en='1' then
                ram(to_integer(i_wr_addr)) <= i_wr_data;
            end if;
        end if;
    end process;

    P_READ : process (i_rd_clk) is
    begin
        if rising_edge(i_rd_clk) then
            if i_rd_en='1' then
                rd_data <= ram(to_integer(i_rd_addr));
            elsif g_FORCE_TO_ZERO then
                rd_data <= (others => '0');
            end if;
        end if;
    end process;

    G_OUT_FLOP : if g_REG_OUTPUT generate
        P_FLOP : process (i_rd_clk) is
        begin
            if rising_edge(i_rd_clk) then
                o_rd_data <= rd_data;
            end if;
        end process;
    end generate;

    G_NO_OUT_FLOP : if not g_REG_OUTPUT generate
        o_rd_data <= rd_data;
    end generate;

end architecture rtl;


