-------------------------------------------------------------------------------
-- Title      : Correlator Sample Bus Delay Line
-- Project    : 
-------------------------------------------------------------------------------
-- File       : cmac_sample_bus_delay.vhd
-- Author     : William Kamp  <william.kamp@aut.ac.nz>
-- Company    : High Performance Computing Research Lab, Auckland University of Technology
-- Created    : 2016-10-12
-- Last update: 2018-01-15
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Delays a std_logic_vector by a constant number of cycles g_CYCLES_DELAY.
-- This is done using using flip-flops. This should create travel flops in the hyperflex
-- architecture.
-------------------------------------------------------------------------------
-- Copyright (c) 2016 High Performance Computing Research Lab, Auckland University of Technology
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-10-12  1.0      wkamp   Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pipeline_delay is

    generic (
        g_CYCLES_DELAY : natural;
        g_FORCE_USE_FLOPS : boolean := false
        );

    port (
        i_clk      : in  std_logic;
        i_bus      : in  std_logic_vector;
        i_bus_vld  : in  std_logic := '1';
        o_bus_stop : out std_logic;
        o_bus      : out std_logic_vector;
        o_bus_vld  : out std_logic;
        i_bus_stop : in  std_logic := '0'
        );

end entity pipeline_delay;

architecture rtl of pipeline_delay is

    type t_delay is array (natural range <>) of std_logic_vector(i_bus'range);

    signal delay_line     : t_delay(g_CYCLES_DELAY downto 0);
    signal delay_line_vld : std_logic_vector(g_CYCLES_DELAY downto 0);

begin  -- architecture rtl
    assert g_CYCLES_DELAY < 4 or g_FORCE_USE_FLOPS
        report "Pipeline length of " & integer'image(g_CYCLES_DELAY) & " cycles used here, consider using a pipeline_delay_ram instead, and/or set g_FORCE_USE_FLOPS = true."
        severity warning;
    
    o_bus_stop <= i_bus_stop;

    delay_line(0)     <= i_bus;
    delay_line_vld(0) <= i_bus_vld;
    o_bus             <= delay_line(g_CYCLES_DELAY);
    o_bus_vld         <= delay_line_vld(g_CYCLES_DELAY);

    G_DELAY : if g_CYCLES_DELAY > 0 generate
        P_DELAY : process (i_clk) is
        begin
            if rising_edge(i_clk) then
                delay_line(g_CYCLES_DELAY downto 1)     <= delay_line(g_CYCLES_DELAY-1 downto 0);
                delay_line_vld(g_CYCLES_DELAY downto 1) <= delay_line_vld(g_CYCLES_DELAY-1 downto 0);
            end if;
        end process;
    end generate;

end architecture rtl;
