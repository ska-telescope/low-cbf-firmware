-------------------------------------------------------------------------------
-- Title      : Testbench for design "cmac"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : cmac_tb.vhd
-- Author     : William Kamp  <william.kamp@aut.ac.nz>
-- Company    : High Performance Computing Research Lab, Auckland University of Technology
-- Created    : 2016-07-28
-- Platform   : 
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2016 High Performance Computing Research Lab, Auckland University of Technology
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-07-28  1.0      wkamp   Created
-- 2019-09-16  2.0p     nabel   Ported to Perentie
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.all;

library work;
use work.cmac_pkg.all;

library common_tb_lib;
use common_tb_lib.common_tb_pkg.all;


------------------------------------------------------------------------------------------------------------------------

entity cmac_tb is
    generic (
        g_READOUT_ONLY_WHEN_AUTO_MODE : boolean := true
        );
end entity cmac_tb;

------------------------------------------------------------------------------------------------------------------------

architecture sim of cmac_tb is

    -- component generics
    constant g_MAX_ACCUM_SAMPLES : natural := 69;
    constant g_SAMPLE_WIDTH      : natural := 5;
    constant g_READOUT_DELAY     : natural := 0;
    constant g_CMAC_LATENCY      : natural := work.cmac_pkg.c_CMAC_LATENCY;




    constant c_MAX_VAL : integer := 2**(g_SAMPLE_WIDTH-1)-1;

    -- component ports
    signal clk       : std_logic := '1';
    signal clk_d     : std_logic := '1';
    signal clk_reset : std_logic;

    signal col : t_cmac_input_bus;
    signal row : t_cmac_input_bus;

    -- Readout interface. Basically a big side loaded shift register.
    signal i_readout_vld  : std_logic := '0';
    signal i_readout_data : std_logic_vector(f_cmac_readout_width(g_SAMPLE_WIDTH, g_MAX_ACCUM_SAMPLES)-1 downto 0);
    --signal i_readout_data : std_logic_vector(31 downto 0);
    signal o_readout_vld  : std_logic;
    signal o_readout_data : std_logic_vector(i_readout_data'range);

    signal expected_real         : integer;
    signal expected_imag         : integer;
    signal expected_real_delayed : integer;
    signal expected_imag_delayed : integer;

    signal i_scan : signed(3*g_SAMPLE_WIDTH-1 downto 0) := (others => '0');
    signal o_scan : signed(3*g_SAMPLE_WIDTH-1 downto 0);

    signal row_real : integer range -c_MAX_VAL to c_MAX_VAL;
    signal row_imag : integer range -c_MAX_VAL to c_MAX_VAL;
    signal col_real : integer range -c_MAX_VAL to c_MAX_VAL;
    signal col_imag : integer range -c_MAX_VAL to c_MAX_VAL;
    
begin  -- architecture sim

    -- clock generation
    clk       <= not clk  after 5 ns;
    clk_reset <= '1', '0' after 200 ns;

    clk_d <= transport clk after 1 ns;    

    i_readout_data <= (others => '-');
    i_readout_vld  <= '0';

    E_CMAC_DUT : entity work.cmac
        generic map (
            g_MAX_ACCUM_SAMPLES           => g_MAX_ACCUM_SAMPLES,            -- [natural]
            g_SAMPLE_WIDTH                => g_SAMPLE_WIDTH,  -- [natural range 1 to 9] > 6 uses two multiplers
            -- For the auto correlations, XY and YX polarisation products are the conjugates of each other.
            -- Generate the conjugate at readout time, placing it in the readout shift register before or after.
            g_READOUT_ONLY_WHEN_AUTO_MODE => g_READOUT_ONLY_WHEN_AUTO_MODE,  -- [boolean]
            g_CMAC_LATENCY                => g_CMAC_LATENCY)                -- [natural]
        port map (
            i_clk       => clk,         -- [std_logic]
            i_clk_reset => clk_reset,   -- [std_logic]

            i_row => row,               -- [t_cmac_input_bus]
            i_col => col,               -- [t_cmac_input_bus]

            i_scan => i_scan,
            o_scan => o_scan,

            -- Readout interface. Basically a big sideloaded shift register.
            -- Loaded by i_<col|row>.last
            i_readout_vld  => i_readout_vld,    -- [std_logic := '0']
            i_readout_data => i_readout_data,   -- [std_logic_vector]
            o_readout_vld  => o_readout_vld,    -- [std_logic]
            o_readout_data => o_readout_data);  -- [std_logic_vector]

    expected_real_delayed <= transport expected_real after (g_CMAC_LATENCY*10+1) * 1 ns;
    expected_imag_delayed <= transport expected_imag after (g_CMAC_LATENCY*10+1) * 1 ns;

    P_CHECK : process (clk) is
        variable accu_real : std_logic_vector(f_cmac_accum_width(g_SAMPLE_WIDTH, g_MAX_ACCUM_SAMPLES)-1 downto 0);
        variable accu_imag : std_logic_vector(accu_real'range);
    begin
        if rising_edge(clk) then
            if o_readout_vld and not clk_reset then
                accu_real := o_readout_data(2*accu_real'length-1 downto accu_real'length);
                accu_imag := o_readout_data(accu_imag'length-1 downto 0);
                check_equal(signed(accu_real), expected_real_delayed, "Real Accumulation");
                check_equal(signed(accu_imag), expected_imag_delayed, "Imaginary Accumulation");
            end if;
        end if;
    end process;


    P_MAIN : process is
        variable sample_real : integer := 2;
        variable sample_imag : integer := 0;
        variable accu_real   : integer := 0;
        variable accu_imag   : integer := 0;
        variable a, b, c, d  : integer;
        variable sample_cnt  : natural := 0;
    begin
        col.vld        <= '0';
        col.rfi        <= '0';
        col.last       <= '0';
        col.first      <= '0';
        col.sample_cnt <= to_unsigned(0, col.sample_cnt'length);
        col.auto_corr  <= '0';
        col.data(3*g_SAMPLE_WIDTH-1 downto 0) <= to_6bj6b(0, 0, g_SAMPLE_WIDTH);
        row.data(3*g_SAMPLE_WIDTH-1 downto 0) <= to_6bj6b(0, 0, g_SAMPLE_WIDTH);
        
        wait until clk_reset = '0';
        
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        for a_imag in -c_MAX_VAL to c_MAX_VAL loop                    
            for a_real in -c_MAX_VAL to c_MAX_VAL loop
                for b_imag in -c_MAX_VAL to c_MAX_VAL loop
                    for b_real in -c_MAX_VAL to c_MAX_VAL loop
                        if sample_cnt = 0 then
                            col.first <= '1';
                            col.vld   <= '1';
                            accu_real := 0;
                            accu_imag := 0;
                        else
                            col.first <= '0';
                        end if;

                        col.data(3*g_SAMPLE_WIDTH-1 downto 0) <= f_format_col(to_6bj6b(a_real, a_imag, g_SAMPLE_WIDTH), g_SAMPLE_WIDTH);
                        row.data(3*g_SAMPLE_WIDTH-1 downto 0) <= f_format_row(to_6bj6b(b_real, b_imag, g_SAMPLE_WIDTH), g_SAMPLE_WIDTH);

                        row_real <=  b_real;
                        row_imag <=  b_imag;
                        col_real <=  a_real;
                        col_imag <= -a_imag;
                                    

                        accu_real := accu_real + (a_real*b_real - a_imag*b_imag);
                        accu_imag := accu_imag + (a_real*b_imag + b_real*a_imag);

                        col.sample_cnt <= to_unsigned(sample_cnt, col.sample_cnt'length);
                        
                        if sample_cnt = g_MAX_ACCUM_SAMPLES-1 then
                            col.last      <= '1';
                            expected_real <= accu_real;
                            expected_imag <= accu_imag;
                        else
                            col.last <= '0';
                        end if;
                        wait until rising_edge(clk);
                        sample_cnt     := (sample_cnt + 1) mod g_MAX_ACCUM_SAMPLES;
                    end loop;
                end loop;
            end loop;
            echoln("Percent complete : " & integer'image(100*(a_imag+c_MAX_VAL+1)/(2*c_MAX_VAL+1)) & "%.");
        end loop;
        col.vld <= '0';
        col.last <= '0';

        wait for 2 us;

        echoln;
        echoln("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        echoln("!                             !");
        echoln("!     SIMULATION FINISHED     !");
        echoln("!                             !");
        echoln("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        echoln;
        
        stop(2); --end simulation

    end process P_MAIN;

    row.first      <= col.first;
    row.rfi        <= col.rfi;
    row.last       <= col.last;
    row.vld        <= col.vld;
    row.sample_cnt <= col.sample_cnt;
    row.auto_corr  <= col.auto_corr;

end architecture sim;
