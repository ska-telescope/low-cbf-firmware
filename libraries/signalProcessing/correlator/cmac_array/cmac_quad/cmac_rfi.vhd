-------------------------------------------------------------------------------
-- Title      : CMAC RFI METADATA GENERATOR
-- Project    : 
-------------------------------------------------------------------------------
-- File       : cmac_rfi.vhd
-- Author     : William Kamp  <william.kamp@aut.ac.nz>
-- Company    : 
-- Created    : 2016-07-22
-- Last update: 2018-06-26
-- Platform   : 
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: Generates the Time Centroid Index and Data valid counts.
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-07-22  1.0      will    Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.cmac_pkg.all;                  -- t_cmac_input_bus
use work.misc_tools_pkg.all;            -- maximum

library work;
use work.misc_tools_pkg.all;                  -- ceil_log2

entity cmac_rfi is

    generic (
        g_MAX_ACCUM_SAMPLES           : natural;
        g_READOUT_ONLY_WHEN_AUTO_MODE : boolean := false;
        g_CMAC_LATENCY                : natural;
        g_READOUT_DELAY               : natural
        );
    port (
        i_clk       : in std_logic;
        i_clk_reset : in std_logic;

        i_row : in t_cmac_input_bus;
        i_col : in t_cmac_input_bus;

        -- Readout interface. Basically a big sideloaded shift register.
        -- Loaded by i_<col|row>.last
        i_readout_vld  : in  std_logic := '0';
        i_readout_data : in  std_logic_vector;
        o_readout_vld  : out std_logic;
        o_readout_data : out std_logic_vector
        );

end entity cmac_rfi;

architecture rtl of cmac_rfi is

    constant c_THIS_LATENCY : natural := 2;
    
    signal piped_col : std_logic_vector(T_CMAC_INPUT_BUS_SLV_WIDTH-1 downto 0);
    signal piped_row : std_logic_vector(T_CMAC_INPUT_BUS_SLV_WIDTH-1 downto 0);

    signal c0_rfi : std_logic;
    signal c0_col : t_cmac_input_bus;
    signal c1_col : t_cmac_input_bus;

    signal c2_tci_accum : unsigned(f_cmac_tci_width(g_MAX_ACCUM_SAMPLES)-1 downto 0);
    signal c2_dv_count  : unsigned(f_cmac_dv_width(g_MAX_ACCUM_SAMPLES)-1 downto 0);

    signal c2_data      : std_logic_vector(c2_tci_accum'length+c2_dv_count'length-1 downto 0);
    signal c0_do_readout : std_logic;
    signal c1_do_readout : std_logic;
    signal c2_do_readout : std_logic;

begin  -- architecture rtl

    -- Pipeline, adjusted so that the output has the same latency as a CMAC.
    -- Put the pipeline delay here because the number of signals at the input is fewer than at the output.
    E_COL_PIPE : entity work.pipeline_delay
        generic map (
            g_CYCLES_DELAY => g_READOUT_DELAY+g_CMAC_LATENCY-c_THIS_LATENCY)        -- [natural]
        port map (
            i_clk => i_clk,
            i_bus => to_slv(i_col),
            o_bus => piped_col);
    E_ROW_PIPE : entity work.pipeline_delay
        generic map (
            g_CYCLES_DELAY => g_READOUT_DELAY+1)        -- [natural]
        port map (
            i_clk => i_clk,
            i_bus => to_slv(i_row),
            o_bus => piped_row);

    c0_col <= from_slv(piped_col);
    c0_rfi <= from_slv(piped_col).rfi or from_slv(piped_row).rfi;
    P_FLOP_INPUTS : process (i_clk) is
    begin
        if rising_edge(i_clk) then
            c1_col     <= c0_col;
            c1_col.rfi <= c0_rfi;
        end if;
    end process;

    P_TIME_CENTROID : process (i_clk) is
        variable v_feedback_cnt : unsigned(c2_tci_accum'range);
        variable v_increment    : unsigned(c2_tci_accum'range);
    begin
        if rising_edge(i_clk) then

            if c1_col.first='1' then
                v_feedback_cnt := to_unsigned(0, c2_tci_accum'length);
            else
                v_feedback_cnt := c2_tci_accum;
            end if;
            if c1_col.rfi='1' then
                v_increment := to_unsigned(0, c2_tci_accum'length);
            else
                v_increment := resize(c1_col.sample_cnt, c2_tci_accum'length);
            end if;
            if c1_col.vld='1' then
                c2_tci_accum <= v_feedback_cnt + v_increment;
            end if;
        end if;
    end process;

    P_COUNT_DV : process (i_clk) is
        variable v_feedback_cnt : unsigned(c2_dv_count'range);
        variable v_increment    : unsigned(c2_dv_count'range);
    begin
        if rising_edge(i_clk) then
            if c1_col.first='1' then
                v_feedback_cnt := to_unsigned(0, c2_dv_count'length);
            else
                v_feedback_cnt := c2_dv_count;
            end if;
            if c1_col.rfi='1' then
                v_increment := to_unsigned(0, c2_dv_count'length);
            else
                v_increment := to_unsigned(1, c2_dv_count'length);
            end if;
            if c1_col.vld='1' then
                c2_dv_count <= v_feedback_cnt + v_increment;
            end if;
        end if;
    end process;

--------------------------------------------------------------------------------------------------------------------
-- Readout
--------------------------------------------------------------------------------------------------------------------

    P_READOUT : process (i_clk) is
    begin
        if rising_edge(i_clk) then
            if g_READOUT_ONLY_WHEN_AUTO_MODE then
                c1_do_readout <= c0_col.last and c0_col.auto_corr; 
            else 
                c1_do_readout <= c0_col.last;
            end if;        
            c2_do_readout <= c1_do_readout;
        end if;
    end process;

    c2_data <= std_logic_vector(c2_tci_accum) & std_logic_vector(c2_dv_count);

    o_readout_data(o_readout_data'High downto c2_data'length) <= (others => '0');
    o_readout_data(c2_data'range) <= c2_data when c2_do_readout='1' else (others => '0');
    o_readout_vld <= c2_do_readout;


    
    P_CHECK_INPUT : process (i_clk) is
    begin
        if rising_edge(i_clk) then
            if not i_clk_reset='1' then
                assert i_row.vld = i_col.vld
                    report "Row and Column data must be vaild at exactly the same time."
                    severity error;
                assert i_row.last = i_col.last
                    report "Row and Column data packets must end at exactly the same time."
                    severity error;
            end if;
        end if;
    end process;


end architecture rtl;
