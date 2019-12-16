-------------------------------------------------------------------------------
-- Title      : Testbench for design "cmac_quad"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tb/cmac_quad_tb.vhd
-- Author     : William Kamp  <william.kamp@aut.ac.nz>
-- Company    : High Performance Computing Research Lab, Auckland University of Technology
-- Created    : 2017-07-31
-- Platform   : 
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2017 High Performance Computing Research Lab, Auckland University of Technology
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-07-31  1.0      will    Created
-- 2019-09-16  2.0p     nabel   Ported to Perentie
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cmac_pkg.all;
use work.cmac_tdm_pkg.all;              -- t_tdm_rd_ctrl, t_tdm_cache_wr_bus, f_ADDR_STRIDE
use work.misc_tools_pkg.all;            -- ceil_log2

library common_tb_lib;
use common_tb_lib.common_tb_pkg.all;

library std;
use std.env.all;

------------------------------------------------------------------------------------------------------------------------
entity cmac_quad_tb is
    generic (
        g_AUTOCORRELATION_CMAC : boolean := true
        );
end entity cmac_quad_tb;
------------------------------------------------------------------------------------------------------------------------

architecture sim of cmac_quad_tb is

    -- component generics
    constant g_MAX_ACCUM_SAMPLES : natural              := 100;
    constant g_SAMPLE_WIDTH      : natural range 1 to 9 := 8;  --  > 6 uses two multiplers per cmac.
    constant g_QUAD_CMAC_LATENCY : natural              := work.cmac_pkg.c_CMAC_LATENCY+2; -- measure in simulator from rising_edge(i_col.last) to rising_edge(o_readout_vld) in cycles.
    constant g_NUM_ANTENNA     : natural                                   := 10;
    constant g_ANTENNA_PER_COL : natural range 1 to pc_MAX_ANTENNA_PER_COL := 10;   -- g_NUM_ANTENNA/g_COL_DIMENSION
    constant g_NUM_SAMPLES     : natural range 3 to pc_MAX_NUM_SAMPLES     := 48;  -- number of samples in a sub-accumulation.set for memory efficiency i.e 512/g_ANTENNA_PER_COL.
    constant g_PIPELINE_CYCLES : natural                                   := 2;

    constant c_CMAC_TCI_WIDTH   : natural := f_cmac_tci_width(g_MAX_ACCUM_SAMPLES);
    constant c_CMAC_DVC_WIDTH   : natural := f_cmac_dv_width(g_MAX_ACCUM_SAMPLES);
    constant c_ACCUM_WIDTH      : natural := f_cmac_accum_width(g_SAMPLE_WIDTH, g_MAX_ACCUM_SAMPLES);

    type ant_array   is array(0 to g_NUM_ANTENNA*(g_NUM_ANTENNA+1)/2) of integer;
    type ant_array2  is array(0 to g_NUM_ANTENNA, 0 to g_MAX_ACCUM_SAMPLES-1) of integer;
    type bl_array2   is array(0 to g_NUM_ANTENNA-1, 0 to g_NUM_ANTENNA-1) of integer;

    function get_baseline (
        col      : integer;
        row      : integer;
        tdm_col  : natural := g_ANTENNA_PER_COL;
        even     : boolean := true)
    return integer is
    begin
        if g_AUTOCORRELATION_CMAC then
            ------------------------------------------------------------
            -- base  | Antenna group:
            -- line  | A(0) B(1) C(2) D(3) E(4) F(5) G(6) H(7) I(8) J(9)
            ---------+--------------------------------------------------
            -- A(0)  |   9a
            -- B(1)  |   0   10a
            -- C(2)  |   1   11   26a
            -- D(3)  |   2   12   19   27a
            -- E(4)  |   3   13   20   28   39a
            -- F(5)  |   4   14   21   29   34   40a
            -- G(6)  |   5   15   22   30   35   41   48a
            -- H(7)  |   6   16   23   31   36   42   45   49a
            -- I(8)  |   7   17   24   32   37   43   46   50   53a
            -- J(9)  |   8   18   25   33   38   44   47   51   52   54a
            ------------------------------------------------------------
            if col=0 and row=0 then
                return tdm_col-1;        --Auto BB
            elsif row < col then
                return -1000000; --not a baseline
            elsif col=0 then
                return row-1;
            elsif col=1 then
                return tdm_col+row-1;
            else                
                return get_baseline(col-2, row-2, tdm_col-2) + tdm_col*2-1;
            end if;
        else
            ------------------------------------------------------------
            -- base  | Antenna group:
            -- line  | A(0) B(1) C(2) D(3) E(4) F(5) G(6) H(7) I(8) J(9)
            ---------+--------------------------------------------------
            -- A(0)  |   
            -- B(1)  |   0   9
            -- C(2)  |   1   10      
            -- D(3)  |   2   11   18   25 
            -- E(4)  |   3   12   19   26   
            -- F(5)  |   4   13   20   27   32   37
            -- G(6)  |   5   14   21   28   33   38   
            -- H(7)  |   6   15   22   29   34   39   42   45
            -- I(8)  |   7   16   23   30   35   40   43   46   
            -- J(9)  |   8   17   24   31   36   41   44   47   48   49
            ------------------------------------------------------------
            if col = 0 and row = 0 then
                return -1000000;        --AA (which should be auto but is not)
            elsif row < col then
                return -1000000; --not a baseline
            elsif col = 0 then
                return row - 1;
            elsif col = 1 then
                return tdm_col + row - 2;
            else
                return get_baseline(col-2, row-2, tdm_col-2) + tdm_col*2-2;
            end if;
        end if;
    end function get_baseline;

    function test_baseline return bl_array2 is
        variable bl : bl_array2;
    begin
        for col in 0 to g_NUM_ANTENNA-1 loop
            for row in 0 to g_NUM_ANTENNA-1 loop
                bl(row, col) := get_baseline(col, row);
            end loop;
        end loop;
        return bl;
    end function test_baseline;

    constant bl_test : bl_array2 := test_baseline;
    
    -- Data input interface
    signal cturn_clk       : std_logic := '1';
    signal cturn_clk_reset : std_logic;

    signal cmac_clk       : std_logic := '1';
    signal cmac_clk_reset : std_logic;
    signal cmac_clk_reset_n : std_logic;

    signal start_check : std_logic;
    signal expr_check : std_logic;

    signal wr_stop : std_logic;         -- stop at the end of this burst.

    signal col_tdm_cache_wr_bus : t_tdm_cache_wr_bus;
    signal row_tdm_cache_wr_bus : t_tdm_cache_wr_bus;
    signal start            : std_logic;
    signal started          : std_logic;
    signal col_rd_ctrl      : t_tdm_rd_ctrl;
    signal row_rd_ctrl      : t_tdm_rd_ctrl;
    signal tdm_last         : std_logic;
    signal tdm_slot : unsigned(ceil_log2((g_ANTENNA_PER_COL**2+1)/2)-1 downto 0);
    
    signal i_row : t_cmac_input_bus_a(0 to 1);  -- dual polarisations
    signal i_col : t_cmac_input_bus_a(0 to 1);  -- dual polarisations
    signal mux_row : t_cmac_input_bus_a(0 to 1);  -- dual polarisations
    signal mux_col : t_cmac_input_bus_a(0 to 1);  -- dual polarisations
    
    signal o_row : t_cmac_input_bus_a(0 to 1);  -- dual polarisations
    signal o_col : t_cmac_input_bus_a(0 to 1);  -- dual polarisations

    -- Readout interface. Basically a big sideloaded shift register.
    -- Loaded by i_<col|row>.last
    signal i_readout_vld  : std_logic := '0';
    signal i_readout_data : std_logic_vector(128-1 downto 0) := (others => '0');
    signal o_readout_vld  : std_logic;
    signal o_readout_vld_n : std_logic;
    signal o_readout_data : std_logic_vector(i_readout_data'range);

    signal readout_dvc : std_logic_vector(c_CMAC_DVC_WIDTH-1 downto 0);
    signal readout_tci : std_logic_vector(c_CMAC_TCI_WIDTH-1 downto 0);
    signal readout_hi_im : std_logic_vector(c_ACCUM_WIDTH-1 downto 0);
    signal readout_hi_re : std_logic_vector(c_ACCUM_WIDTH-1 downto 0);
    signal readout_lo_im : std_logic_vector(c_ACCUM_WIDTH-1 downto 0);
    signal readout_lo_re : std_logic_vector(c_ACCUM_WIDTH-1 downto 0);

    signal acc_XX_re, acc_XX_im   : ant_array := (others => 0);
    signal acc_XY_re, acc_XY_im   : ant_array := (others => 0);
    signal acc_YX_re, acc_YX_im   : ant_array := (others => 0);
    signal acc_YY_re, acc_YY_im   : ant_array := (others => 0);
    signal dut_baseline : natural := 0;    
    
begin  -- architecture sim

    E_CACHE_DRIVER : entity work.cmac_tdm_cache_driver
        generic map (
            g_ANTENNA_PER_COL => g_ANTENNA_PER_COL,  -- [natural range 1 to pc_MAX_ANTENNA_PER_COL] g_NUM_ANTENNA/g_COL_DIMENSION
            g_NUM_SAMPLES     => g_NUM_SAMPLES)  -- [natural range 3 to pc_MAX_NUM_SAMPLES] number of samples in a sub-accumulation.
        port map (
            i_clk         => cmac_clk,  -- [std_logic]
            i_clk_reset   => cmac_clk_reset,     -- [std_logic]
            i_start       => start,     -- [std_logic]
            o_started     => started,   -- [std_logic]
            o_col_rd_ctrl => col_rd_ctrl,        -- [t_tdm_rd_ctrl]
            o_row_rd_ctrl => row_rd_ctrl,        -- [t_tdm_rd_ctrl]
            o_tdm_slot    => tdm_slot,  -- [unsigned]
            o_tdm_last    => tdm_last);          -- [std_logic]

    E_COL_CACHE : entity work.cmac_tdm_cache
        generic map (
            g_SAMPLE_WIDTH    => g_SAMPLE_WIDTH,     -- [natural range 1 to 9]
            g_ANTENNA_PER_COL => g_ANTENNA_PER_COL,  -- [natural range 1 to pc_MAX_ANTENNA_PER_COL] g_NUM_ANTENNA/g_COL_DIMENSION
            g_NUM_SAMPLES     => g_NUM_SAMPLES,  -- [natural range 3 to pc_MAX_NUM_SAMPLES] number of samples in a sub-accumulation.
            -- set for memory efficiency i.e 512/g_ANTENNA_PER_COL.
            g_IS_COLUMN_CACHE => true,
            g_PIPELINE_CYCLES => g_PIPELINE_CYCLES)  -- [natural]
        port map (
            -- Data input interface
            i_cturn_clk       => cturn_clk,      -- [std_logic]
            i_cturn_clk_reset => cturn_clk_reset,    -- [std_logic]

            i_tdm_cache_wr_bus => col_tdm_cache_wr_bus,  -- [t_tdm_cache_wr_bus]
            o_wr_stop          => wr_stop,           -- [std_logic] stop at the end of this burst.

            -- Read driver interface
            -- connect to global cmac_tdm_cache_driver module.
            i_cmac_clk       => cmac_clk,        -- [std_logic]
            i_cmac_clk_reset => cmac_clk_reset,  -- [std_logic]

            i_tdm_rd_ctrl => col_rd_ctrl,  -- [t_tdm_rd_ctrl]

            -- Output to CMAC row or column
            o_cmac_bus => i_col);       -- [t_cmac_input_bus_a(0 to 1)]

    E_ROW_CACHE : entity work.cmac_tdm_cache
        generic map (
            g_SAMPLE_WIDTH    => g_SAMPLE_WIDTH,     -- [natural range 1 to 9]
            g_ANTENNA_PER_COL => g_ANTENNA_PER_COL,  -- [natural range 1 to pc_MAX_ANTENNA_PER_COL] g_NUM_ANTENNA/g_COL_DIMENSION
            g_NUM_SAMPLES     => g_NUM_SAMPLES,  -- [natural range 3 to pc_MAX_NUM_SAMPLES] number of samples in a sub-accumulation.
            -- set for memory efficiency i.e 512/g_ANTENNA_PER_COL.
            g_IS_COLUMN_CACHE => false,
            g_PIPELINE_CYCLES => g_PIPELINE_CYCLES)  -- [natural]
        port map (
            -- Data input interface
            i_cturn_clk       => cturn_clk,      -- [std_logic]
            i_cturn_clk_reset => cturn_clk_reset,    -- [std_logic]

            i_tdm_cache_wr_bus => row_tdm_cache_wr_bus,  -- [t_tdm_cache_wr_bus]
            o_wr_stop          => open,              -- [std_logic] stop at the end of this burst.

            -- Read driver interface
            -- connect to global cmac_tdm_cache_driver module.
            i_cmac_clk       => cmac_clk,        -- [std_logic]
            i_cmac_clk_reset => cmac_clk_reset,  -- [std_logic]

            i_tdm_rd_ctrl => row_rd_ctrl,  -- [t_tdm_rd_ctrl]

            -- Output to CMAC row or column
            o_cmac_bus => i_row);       -- [t_cmac_input_bus_a(0 to 1)]

    -- Emulate the Row-to-Column mux of a g_AUTOCORRELATION_CMAC=True CMAC that is above this one.
    mux_col(0) <= f_turn_row_to_column(i_col(0), i_row(0), g_SAMPLE_WIDTH) when not g_AUTOCORRELATION_CMAC
                  else i_col(0);
    mux_col(1) <= f_turn_row_to_column(i_col(1), i_row(1), g_SAMPLE_WIDTH) when not g_AUTOCORRELATION_CMAC
                  else i_col(1);

    E_CMAC_QUAD : entity work.cmac_quad
        generic map (
            g_AUTOCORRELATION_CMAC => g_AUTOCORRELATION_CMAC,  -- [boolean]
            g_MAX_ACCUM_SAMPLES    => g_MAX_ACCUM_SAMPLES,     -- [natural]
            g_SAMPLE_WIDTH         => g_SAMPLE_WIDTH,  -- [natural range 1 to 9]  > 6 uses two multiplers per cmac.
            g_QUAD_CMAC_LATENCY    => g_QUAD_CMAC_LATENCY, -- measure in simulator from rising_edge(i_col.last) to
                                                           -- rising_edge(o_readout_vld) in cycles.
            g_PIPELINE_CYCLES      => g_PIPELINE_CYCLES)
        port map (
            i_clk       => cmac_clk,    -- [std_logic]
            i_clk_reset => cmac_clk_reset,             -- [std_logic]

            i_row => i_row,             -- [t_cmac_input_bus_a(0 to 1)] dual polarisations
            i_col => mux_col,             -- [t_cmac_input_bus_a(0 to 1)] dual polarisations

            o_row => o_row,             -- [t_cmac_input_bus_a(0 to 1)] dual polarisations
            o_col => o_col,             -- [t_cmac_input_bus_a(0 to 1)] dual polarisations

            -- Readout interface. Basically a big sideloaded shift register.
            -- Loaded by i_<col|row>.last
            i_readout_vld  => i_readout_vld,    -- [std_logic := '0']
            i_readout_data => i_readout_data,   -- [std_logic_vector]
            o_readout_vld  => o_readout_vld,    -- [std_logic]
            o_readout_data => o_readout_data);  -- [std_logic_vector]

    readout_dvc <= o_readout_data(c_CMAC_DVC_WIDTH-1+64 downto 0+64);
    readout_tci <= o_readout_data(c_CMAC_TCI_WIDTH+c_CMAC_DVC_WIDTH-1+64 downto c_CMAC_DVC_WIDTH+64);
    readout_hi_re <= o_readout_data(c_ACCUM_WIDTH*2-1+64 downto c_ACCUM_WIDTH+64);
    readout_hi_im <= o_readout_data(c_ACCUM_WIDTH-1+64 downto 0+64);
    readout_lo_re <= o_readout_data(c_ACCUM_WIDTH*2-1 downto c_ACCUM_WIDTH);
    readout_lo_im <= o_readout_data(c_ACCUM_WIDTH-1 downto 0);

    -- clock generation
    cturn_clk       <= not cturn_clk after 2 ns;
    cmac_clk        <= not cmac_clk  after 2 ns;
    cturn_clk_reset <= '1', '0' after 1000 ns, '1' after 2000 ns, '0' after 3000 ns;
    cmac_clk_reset  <= '1', '0' after 1000 ns, '1' after 2000 ns, '0' after 3000 ns;


    P_MAIN : process is
        variable X_re, X_im, Y_re, Y_im : ant_array2;
        variable baseline : integer;
        variable auto : boolean;
        variable even : boolean;
    begin
        col_tdm_cache_wr_bus.wr_enable <= '0';
        row_tdm_cache_wr_bus.wr_enable <= '0';
        start                      <= '0';
        wait until cturn_clk_reset = '0';
        wait until rising_edge(cturn_clk);

        -- Write data into the cache --
        for ant in 0 to g_NUM_ANTENNA-1 loop
            for idx in 0 to g_NUM_SAMPLES-1 loop
                X_re(ant, idx) := ((ant+1)*(idx*4)+0) mod (2**g_SAMPLE_WIDTH/2);
                X_im(ant, idx) := ((ant+1)*(idx*4)+1) mod (2**g_SAMPLE_WIDTH/2);
                Y_re(ant, idx) := ((ant+1)*(idx*4)+2) mod (2**g_SAMPLE_WIDTH/2);
                Y_im(ant, idx) := ((ant+1)*(idx*4)+3) mod (2**g_SAMPLE_WIDTH/2);
                
                col_tdm_cache_wr_bus.real_polX   <= to_signed(X_re(ant, idx),9); 
                col_tdm_cache_wr_bus.imag_polX   <= to_signed(X_im(ant, idx),9); 
                col_tdm_cache_wr_bus.real_polY   <= to_signed(Y_re(ant, idx),9); 
                col_tdm_cache_wr_bus.imag_polY   <= to_signed(Y_im(ant, idx),9); 
                col_tdm_cache_wr_bus.dbl_buf_sel <= '0';
                col_tdm_cache_wr_bus.wr_addr     <= to_unsigned(
                    ant * f_ADDR_STRIDE(g_ANTENNA_PER_COL, g_NUM_SAMPLES) + idx,
                    16);
                -- don't write the last antenna into the column cache - it is not used.
                col_tdm_cache_wr_bus.wr_enable   <= '1' when ant < g_NUM_ANTENNA-1 else '0';

                row_tdm_cache_wr_bus.real_polX   <= to_signed(X_re(ant, idx),9); 
                row_tdm_cache_wr_bus.imag_polX   <= to_signed(X_im(ant, idx),9); 
                row_tdm_cache_wr_bus.real_polY   <= to_signed(Y_re(ant, idx),9); 
                row_tdm_cache_wr_bus.imag_polY   <= to_signed(Y_im(ant, idx),9); 
                row_tdm_cache_wr_bus.dbl_buf_sel <= '0';
                row_tdm_cache_wr_bus.wr_addr     <= to_unsigned(
                    ant * f_ADDR_STRIDE(g_ANTENNA_PER_COL, g_NUM_SAMPLES) + idx,
                    16);
                -- don't write the first antenna into the row cache - it is not used.
                row_tdm_cache_wr_bus.wr_enable   <= '1' when ant >= 1 else '0';
                                    
                wait until rising_edge(cturn_clk);
                col_tdm_cache_wr_bus.wr_enable <= '0';
                row_tdm_cache_wr_bus.wr_enable <= '0';
            end loop;

        end loop;

        even := true;
        for col in 0 to g_NUM_ANTENNA-1 loop
            for row in col to g_NUM_ANTENNA-1 loop
                baseline := get_baseline(col, row);
                auto := row = col;
                echoln ("Baseline " & integer'image(baseline) &
                     "; col "& integer'image(col) &
                     "; row " & integer'image(row) &
                     ";");
                if baseline>=0 then
                    for idx in 0 to g_NUM_SAMPLES-1 loop

                        acc_XX_im(baseline) <= acc_XX_im(baseline) + X_im(row, idx) * X_re(col, idx) + X_re(row,idx) * (-X_im(col, idx));
                        acc_XX_re(baseline) <= acc_XX_re(baseline) + X_re(row, idx) * X_re(col, idx) - X_im(row,idx) * (-X_im(col,idx));

                        acc_YX_im(baseline) <= acc_YX_im(baseline) + Y_im(row, idx) * X_re(col, idx) + Y_re(row,idx) * (-X_im(col,idx));
                        acc_YX_re(baseline) <= acc_YX_re(baseline) + Y_re(row, idx) * X_re(col, idx) - Y_im(row,idx) * (-X_im(col,idx));

                        acc_XY_im(baseline) <= acc_XY_im(baseline) + X_im(row, idx) * Y_re(col, idx) + X_re(row,idx) * (-Y_im(col,idx));
                        acc_XY_re(baseline) <= acc_XY_re(baseline) + X_re(row, idx) * Y_re(col, idx) - X_im(row,idx) * (-Y_im(col,idx));

                        acc_YY_im(baseline) <= acc_YY_im(baseline) + Y_im(row, idx) * Y_re(col, idx) + Y_re(row,idx) * (-Y_im(col,idx));
                        acc_YY_re(baseline) <= acc_YY_re(baseline) + Y_re(row, idx) * Y_re(col, idx) - Y_im(row,idx) * (-Y_im(col,idx));
                        wait until rising_edge(cturn_clk);
                       
                    end loop;
                    if g_AUTOCORRELATION_CMAC and auto then
                        if even then
                            acc_YX_im(baseline) <= 0;
                            acc_YX_re(baseline) <= 0;
                        else
                            acc_XY_im(baseline) <= 0;
                            acc_XY_re(baseline) <= 0;
                        end if;
                        even := not even;
                    end if;                            
                end if;
            end loop;
        end loop;      
        wait until rising_edge(cturn_clk);

        --START DUT--
        start <= '1';
        wait until started = '1';
        start <= '0';
        wait until tdm_last = '1';
        wait for 1 us;

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

    P_CHECK : process
        type t_readout_state is (s_RFI_XX_DATA, s_YX_XY_ACCUM, s_YY_ACCUM);
        variable readout_state : t_readout_state := s_RFI_XX_DATA;
    begin
        wait until rising_edge(cmac_clk);
        if o_readout_vld and not cmac_clk_reset then
            case readout_state is
            when s_RFI_XX_DATA =>
                check_equal(unsigned(readout_dvc), g_NUM_SAMPLES, "Static Data Valid Count - assumes no RFI");
                check_equal(unsigned(readout_tci), g_NUM_SAMPLES*(g_NUM_SAMPLES-1)/2, "Static Time Centroid Index - assumes no RFI");
                check_equal(signed(readout_lo_re), acc_XX_re(dut_baseline), "Baseline: " & integer'image(dut_baseline) & " XX Real Accumulation");
                check_equal(signed(readout_lo_im), acc_XX_im(dut_baseline), "Baseline: " & integer'image(dut_baseline) & " XX Imaginary Accumulation");
                readout_state := S_YX_XY_ACCUM;
            when s_YX_XY_ACCUM =>
                check_equal(signed(readout_lo_re), acc_YX_re(dut_baseline), "Baseline: " & integer'image(dut_baseline) & " YX Real Accumulation");
                check_equal(signed(readout_lo_im), acc_YX_im(dut_baseline), "Baseline: " & integer'image(dut_baseline) & " YX Imaginary Accumulation");
                check_equal(signed(readout_hi_re), acc_XY_re(dut_baseline), "Baseline: " & integer'image(dut_baseline) & " XY Real Accumulation");
                check_equal(signed(readout_hi_im), acc_XY_im(dut_baseline), "Baseline: " & integer'image(dut_baseline) & " XY Imaginary Accumulation");
                readout_state := S_YY_ACCUM;
            when s_YY_ACCUM =>
                check_equal(signed(readout_hi_re), acc_YY_re(dut_baseline), "Baseline: " & integer'image(dut_baseline) & " YY Real Accumulation");
                check_equal(signed(readout_hi_im), acc_YY_im(dut_baseline), "Baseline: " & integer'image(dut_baseline) & " YY Imaginary Accumulation");
                readout_state := s_RFI_XX_DATA;
                dut_baseline <= dut_baseline + 1;
            end case;
        end if;
    end process;



end architecture sim;

------------------------------------------------------------------------------------------------------------------------
