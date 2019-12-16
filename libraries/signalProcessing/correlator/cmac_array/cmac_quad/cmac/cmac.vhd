-------------------------------------------------------------------------------
-- Title      : 9b Complex Multiply Accumulate
-- Project    : 
-------------------------------------------------------------------------------
-- File       : cmac.vhd
-- Author     : William Kamp  <william.kamp@aut.ac.nz>
-- Company    : 
-- Created    : 2016-07-22
-- Last update: 2018-07-20
-- Platform   : 
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: Implements the kernel of a complex multiply accumulate function,
--              a node in the systolic array correlator.
--
--              The kernel performs one complex multiply and accumulate per cycle.
--
--              The 'last' flag on the column input bus dumps the accumulators to
--              the readout and resets to zero for the next accumulation.
--              The complex conjugate of the accumulation can also be dumped to
--              the readout bus, either before or after, and only when i_col.auto_corr = '1'.
---------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-03-06  1.0      will    Created
-- 2019-09-16  2.0p     nabel   Ported to Perentie
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cmac_pkg.all;                  -- t_cmac_input_bus

entity cmac is

    generic (
        g_MAX_ACCUM_SAMPLES           : natural;
        g_SAMPLE_WIDTH                : natural range 1 to 9 := 6;  -- >6 uses two 18b multiplers
        -- For the auto correlations, XY and YX polarisation products are the conjugates of each other.
        -- Generate the conjugate at readout time, placing it in the readout shift register before or after.
        g_READOUT_ONLY_WHEN_AUTO_MODE : boolean              := false;
        g_USE_SCAN_IN                 : boolean := false;
        g_CMAC_LATENCY                : natural range work.cmac_pkg.c_CMAC_LATENCY to work.cmac_pkg.c_CMAC_LATENCY
        );

    port (
        i_clk       : in std_logic;
        i_clk_reset : in std_logic;

        i_row : in t_cmac_input_bus;
        i_col : in t_cmac_input_bus;
        i_scan : in signed(3*g_SAMPLE_WIDTH-1 downto 0) := (others => '-');
        o_scan : out signed(3*g_SAMPLE_WIDTH-1 downto 0);

        -- Readout interface. Basically a big sideloaded shift register.
        -- Loaded by i_<col|row>.last
        -- accumulators sized as cmac_pkg.f_cmac_accum_width() written to
        -- o_readout_data as accum_real & accum_imag.
        i_readout_vld  : in  std_logic := '0';
        i_readout_data : in  std_logic_vector;
        o_readout_vld  : out std_logic;
        o_readout_data : out std_logic_vector
        );

end entity cmac;


architecture ultrascale of cmac is

    -- Multiplier in Small Fast mode, has at its input:
    -- two signed operands with encoded values with width 3*g_SAMPLE_WIDTH.
    constant c_MULT_WIDTH    : natural := (g_SAMPLE_WIDTH) + (g_SAMPLE_WIDTH - 1) + 1;
    constant c_MULT_OP_WIDTH : natural := 3*g_SAMPLE_WIDTH;
    constant c_ACCUM_WIDTH   : natural := f_cmac_accum_width(g_SAMPLE_WIDTH, g_MAX_ACCUM_SAMPLES);

    constant c_DSP_PIPELINE_CYCLES : natural := g_CMAC_LATENCY-1;

    -- Pipelines for the DSP block.
    signal pipe_col : t_cmac_input_bus_a(c_DSP_PIPELINE_CYCLES-1 downto 0);     

    signal c5_col : t_cmac_input_bus;

    signal c4_prod : signed(c_MULT_OP_WIDTH*2-1 downto 0);
    signal c5_prod_imag  : signed(c_MULT_WIDTH-1 downto 0);
    signal c5_prod_real  : signed(c_MULT_WIDTH-1 downto 0);
    signal c5_carry_real : std_logic;
    signal c5_carry_imag : std_logic;

    signal c6_accum_real : signed(c_ACCUM_WIDTH-1 downto 0);
    signal c6_accum_imag : signed(c_ACCUM_WIDTH-1 downto 0);
    signal c6_accum      : signed(c6_accum_real'length+c6_accum_imag'length-1 downto 0);
    signal c6_accum_conj : signed(c6_accum'range);
    
    signal c6_load_readout : std_logic;
    signal c6_auto_mode    : std_logic;
    signal c6_load_readout_delay : std_logic;
    signal c6_auto_mode_delay    : std_logic;

begin  -- architecture rtl    

    P_FLOP_INPUTS : process (i_clk) is
    begin
        if rising_edge(i_clk) then
            pipe_col <= i_col & pipe_col(pipe_col'high downto 1);
        end if;
    end process;
    c5_col   <= pipe_col(0);

    E_MULT_ADD: ENTITY work.mult_add
    GENERIC MAP (
        g_DSP_PIPELINE_CYCLES => c_DSP_PIPELINE_CYCLES,     
        g_BIT_WIDTH           => g_SAMPLE_WIDTH
    ) PORT MAP (
        i_clk   => i_clk,
        i_vld   => '1',
        i_a_re  => i_row.data(g_SAMPLE_WIDTH*1-1 downto g_SAMPLE_WIDTH*0), 
        i_a_im  => i_row.data(g_SAMPLE_WIDTH*3-1 downto g_SAMPLE_WIDTH*2),
        i_b_re  => i_col.data(g_SAMPLE_WIDTH*1-1 downto g_SAMPLE_WIDTH*0),
        i_b_im  => i_col.data(g_SAMPLE_WIDTH*3-1 downto g_SAMPLE_WIDTH*2),
        o_p_vld => open,
        o_p_re  => c5_prod_real,
        o_p_im  => c5_prod_imag
    );

    c5_carry_real <= c5_prod_imag(c5_prod_imag'HIGH); -- correction if imaginary was negative
    c5_carry_imag <= '0';
    
    P_ACCUMULATE : process (i_clk) is
        variable v_feedback_real : signed(c6_accum_real'range);
        variable v_accum_real    : signed(c6_accum_real'high+1 downto 0);
        variable v_feedback_imag : signed(c6_accum_imag'range);
        variable v_accum_imag    : signed(c6_accum_imag'high+1 downto 0);
    begin
        if rising_edge(i_clk) then
            -- Real Accumulator
            if c5_col.first='1' then
                v_feedback_real := (others => '0');
            else
                v_feedback_real := c6_accum_real;
            end if;
            v_accum_real  := (v_feedback_real & '1') + (resize(c5_prod_real, c6_accum_real'length) & c5_carry_real);
            c6_accum_real <= v_accum_real(v_accum_real'high downto 1);

            -- Imag Accumulator
            if c5_col.first='1' then
                v_feedback_imag := (others => '0');
            else
                v_feedback_imag := c6_accum_imag;
            end if;
            v_accum_imag  := (v_feedback_imag & '1') + (resize(c5_prod_imag, c6_accum_imag'length) & c5_carry_imag);
            if g_READOUT_ONLY_WHEN_AUTO_MODE then
                -- We are an auto correlation CMAC, therefore the result will always have a zero imaginary part.
                -- Do that explicitly here so the synthesiser will optimise away the imaginary accumulator logic.
                assert to_01(v_accum_imag(v_accum_imag'high downto 1)) = 0 or i_clk_reset = '1'
                    report "Expected auto correlation to have a zero imaginary part. Are the inputs conjugated?"
                    severity error;
                c6_accum_imag <= to_signed(0, c6_accum_imag'length);
            else
                c6_accum_imag <= v_accum_imag(v_accum_imag'high downto 1);
            end if;
        end if;
    end process;

--------------------------------------------------------------------------------------------------------------------
-- Readout
--------------------------------------------------------------------------------------------------------------------

    P_READOUT_VLD : process (i_clk) is
    begin  -- process
        if rising_edge(i_clk) then
            if g_READOUT_ONLY_WHEN_AUTO_MODE then
                -- don't enable unless in auto mode.
                c6_load_readout <= c5_col.last and c5_col.auto_corr;
            else
                -- don't enable c4_auto_mode.
                c6_load_readout <= c5_col.last;
            end if;
        end if;
    end process;
    
    c6_accum <= c6_accum_real & to_signed(0, c6_accum_imag'length) when g_READOUT_ONLY_WHEN_AUTO_MODE else
                c6_accum_real & c6_accum_imag;
    --c6_accum_conj <= c6_accum_real & (- c6_accum_imag);

    o_readout_data(o_readout_data'high downto c6_accum'length) <= (others => '0');
    o_readout_data(c6_accum'range) <= std_logic_vector(c6_accum) when c6_load_readout='1' else (others => '0');
    o_readout_vld <= c6_load_readout;
    
    -- synthesis translate_off
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
                if i_row.rfi='1' and i_row.vld='1' then
                    assert i_row.data = 0
                        report "i_row.data(idx) expected to be zero when i_row.RFI = '1'"
                        severity error;
                end if;
                if i_col.rfi='1' and i_col.vld='1' then
                    assert i_col.data = 0
                        report "i_row.data(idx) expected to be zero when i_row.RFI = '1'"
                        severity error;
                end if;
            end if;
        end if;
    end process;
    -- synthesis translate_on

end architecture ultrascale;

