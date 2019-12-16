-------------------------------------------------------------------------------
-- Title      : Testbench for design "mta_dv_cci_tci_accumulator_tb"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : mid_term_accumulator_tb.vhd
-- Author     : William Kamp  <william.kamp@aut.ac.nz>
-- Company    : High Performance Computing Research Lab, Auckland University of Technology
-- Created    : 2017-11-08
-- Last update: 2018-07-10
-- Platform   : 
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2017 High Performance Computing Research Lab, Auckland University of Technology
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-11-03  1.0      will    Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.MATH_REAL.ALL;

library std;
use std.env.all;

library work;
use work.misc_tools_pkg.all;                  -- ceil_log2

library work;
use work.visibility_pkg.all;
use work.cmac_pkg.all;
use work.mta_regs_pkg.all;  -- t_cci_ram_wr_reg

library common_tb_lib;
use common_tb_lib.common_tb_pkg.all;
------------------------------------------------------------------------------------------------------------------------

entity mid_term_accumulator_tb is
end entity mid_term_accumulator_tb;

------------------------------------------------------------------------------------------------------------------------

architecture sim of mid_term_accumulator_tb is

    -- component generics
    constant g_COL_DIMENSION           : natural              := 4;  -- number of columns in CMAC array, e.g. 20
    constant g_ANTENNA_PER_COL           : natural              := 4;  -- number of times the CMAC-array is tiled over the full systolic array, e.g. 50 = 32/4 polarisation products.
    constant g_THIS_COLUMN : natural := 0;
    constant g_NUM_CHANNELS : natural := 16;
    constant g_SAMPLE_WIDTH            : natural range 1 to 9 := 9;
    constant g_CMAC_ACCUM_SAMPLES      : natural              := 112;  -- number of samples in a sub accumulation. e.g. 112. Used to derive
    -- DATA_VALID and TCI readout widths.
    constant g_CMAC_DUMPS_PER_MTA_DUMP : natural              := 17;  -- number of CMAC dumps in a minimum integration period. e.g. 17.
    constant g_MAX_CHANNEL_AVERAGE     : natural              := 4;  -- maximum number of channels that can be averaged.

    constant c_CMAC_ACCUM_WIDTH : natural := f_cmac_accum_width(g_SAMPLE_WIDTH, g_CMAC_ACCUM_SAMPLES);
    constant c_TCI_ACCUM_WIDTH  : natural := f_cmac_tci_width(g_CMAC_ACCUM_SAMPLES);
    constant c_DVC_COUNT_WIDTH   : natural := f_cmac_dv_width(g_CMAC_ACCUM_SAMPLES);

    -- component ports
    signal clk       : std_logic := '1';
    signal clk_reset : std_logic;

    signal cmac_readout_data_hi : std_logic_vector(2*c_CMAC_ACCUM_WIDTH-1 downto 0);
    signal cmac_readout_data_lo : std_logic_vector(2*c_CMAC_ACCUM_WIDTH-1 downto 0);
    signal cmac_readout_data : std_logic_vector(4*c_CMAC_ACCUM_WIDTH-1 downto 0);
    signal cmac_readout_vld  : std_logic;
    signal cmac_context : t_visibility_context;
    
    signal cci_prog : t_cci_ram_wr_reg := T_CCI_RAM_WR_REG_ZERO;
    
    signal lta_data : t_mta_data_frame;
    signal lta_vld  : std_logic;


    function f_is_autocorrelation_tdm_slot (
        slot              : natural;
        c_ANTENNA_PER_COL : natural)
        return boolean is
    begin  -- function f_is_autocorrelation_tdm_slot
        if slot = 0 then
            return true;
        elsif slot < (c_ANTENNA_PER_COL*2-2) then
            return false;
        else
            return f_is_autocorrelation_tdm_slot(slot - (c_ANTENNA_PER_COL*2-2),
                                                 c_ANTENNA_PER_COL-2);            
        end if;
    end function f_is_autocorrelation_tdm_slot;
    
begin  -- architecture sim

    cmac_readout_data <= cmac_readout_data_hi & cmac_readout_data_lo;
    -- component instantiation
    DUT : entity work.mid_term_accumulator
        generic map (
            g_COL_DIMENSION           => g_COL_DIMENSION,  -- [natural] number of columns in CMAC array, e.g. 20
            g_THIS_COLUMN => g_THIS_COLUMN,
            g_SAMPLE_WIDTH            => g_SAMPLE_WIDTH,
            g_ANTENNA_PER_COL         => g_ANTENNA_PER_COL,
            g_CMAC_ACCUM_SAMPLES      => g_CMAC_ACCUM_SAMPLES,  -- [natural] number of samples in a sub accumulation. e.g. 112. Used to derive
            -- DATA_VALID and TCI readout widths.
            g_NUM_CHANNELS => g_NUM_CHANNELS,
            g_CMAC_DUMPS_PER_MTA_DUMP => g_CMAC_DUMPS_PER_MTA_DUMP,  -- [natural] number of CMAC dumps in a minimum integration period. e.g. 17.
            g_MAX_CHANNEL_AVERAGE     => g_MAX_CHANNEL_AVERAGE)  -- [natural] maximum number of channels that can be averaged.
        port map (
            i_clk       => clk,         -- [std_logic]
            i_clk_reset => clk_reset,   -- [std_logic]

            i_cmac_readout_data => cmac_readout_data,  -- [std_logic_vector]
            i_cmac_readout_vld  => cmac_readout_vld,   -- [std_logic]
            i_cmac_context      => cmac_context,

            i_cci_prog => cci_prog,

            o_mta_data_frame => lta_data,     -- [t_mta_data_frame]
            o_mta_vld  => lta_vld);     -- [std_logic]

    -- clock generation
    clk       <= not clk  after 1 ns;
    clk_reset <= '1', '0' after 100 ns;

    cci_prog.clk <= not cci_prog.clk after 4 ns;
    cci_prog.reset <= '1', '0' after 100 ns;
    
    P_MAIN : process is
        variable seed1:        positive := 1;
        variable seed2:        positive := 1;  
        variable rand:         real;
        variable dice:         integer;
        variable v_row_start : natural := 0;
        variable v_idx_high : natural;
        variable v_idx_low  : natural;
    begin
        cmac_context.tdm_lap_start         <= '0';
        cmac_readout_data_hi <= (others => '-');
        cmac_readout_data_lo <= (others => '-');
        cmac_readout_vld  <= '0';
        cci_prog.address <= to_unsigned(0, 32);
        cci_prog.wr_req <= '0';        
        wait until clk_reset = '0';
        wait until rising_edge(clk);

        for freq in 0 to g_NUM_CHANNELS-1 loop
            cci_prog.address <= to_unsigned(freq, 32);
            cci_prog.wr_req <= '1';
            cci_prog.cci_factor <= (others => '0');
            for ant in 0 to g_ANTENNA_PER_COL-1 loop
                v_idx_high := (ant+1)*ceil_log2(g_MAX_CHANNEL_AVERAGE)-1;
                v_idx_low  := (ant)*ceil_log2(g_MAX_CHANNEL_AVERAGE);
                cci_prog.cci_factor(v_idx_high downto v_idx_low) <= std_logic_vector(to_unsigned(
                    g_MAX_CHANNEL_AVERAGE
                    - (freq mod g_MAX_CHANNEL_AVERAGE)
                    - 1,
                    ceil_log2(g_MAX_CHANNEL_AVERAGE) ));
            end loop;                       -- ant
            wait until rising_edge(cci_prog.clk);
        end loop;                   -- freq
        cci_prog.wr_req <= '0';        

        wait until rising_edge(clk);
        
        ---------------------------------------------------------------------
        -- Basic Datapath
        ---------------------------------------------------------------------
        for freq in 0 to g_MAX_CHANNEL_AVERAGE-1 loop
            cmac_context.channel <= to_unsigned(freq, cmac_context.channel'length);
            for time_slice in 1 to g_CMAC_DUMPS_PER_MTA_DUMP loop
                cmac_context.tdm_lap <= to_unsigned(time_slice-1, cmac_context.tdm_lap'length);
                cmac_context.tdm_lap_start <= '1';
                for tdm_slot in 0 to g_ANTENNA_PER_COL**2/2-1 loop
                    if f_is_autocorrelation_tdm_slot(tdm_slot, g_ANTENNA_PER_COL) then
                        v_row_start := 0;
                    else
                        v_row_start := 1;
                    end if;
                    for row in v_row_start to g_COL_DIMENSION loop
                        -- TCI & DVC
                        cmac_readout_data_hi <= (others => '-');
                        cmac_readout_data_hi(c_TCI_ACCUM_WIDTH + c_DVC_COUNT_WIDTH-1 downto 0) <=
                            std_logic_vector(
                            to_unsigned((g_CMAC_ACCUM_SAMPLES+1)*g_CMAC_ACCUM_SAMPLES/2, c_TCI_ACCUM_WIDTH) &
                            to_unsigned(g_CMAC_ACCUM_SAMPLES, c_DVC_COUNT_WIDTH));
                        -- XX Pol Real & Imag
                        cmac_readout_data_lo <= (others => '-');
                        cmac_readout_data_lo(2*c_CMAC_ACCUM_WIDTH-1 downto 0) <=
                            std_logic_vector(
                            to_unsigned(freq*2**8 + 4, c_CMAC_ACCUM_WIDTH) &
                            to_unsigned(tdm_slot*2**8 + row, c_CMAC_ACCUM_WIDTH));
                        cmac_readout_vld <= '1';
                        wait until rising_edge(clk);
                        cmac_context.tdm_lap_start <= '0';
                        uniform(seed1, seed2, rand); dice := integer(FLOOR(rand*5.0));
                        while dice = 0 loop
                            cmac_readout_vld <= '0';
                            wait until rising_edge(clk);
                            uniform(seed1, seed2, rand); dice := integer(FLOOR(rand*5.0));
                        end loop;
                        -- XY Pol Real & Imag
                        cmac_readout_data_hi <= (others => '-');
                        cmac_readout_data_hi(2*c_CMAC_ACCUM_WIDTH-1 downto 0) <=
                            std_logic_vector(
                            to_unsigned(freq*2**8 + 3, c_CMAC_ACCUM_WIDTH) &
                            to_unsigned(tdm_slot*2**8 + row, c_CMAC_ACCUM_WIDTH));
                        -- YX Pol Real & Imag
                        cmac_readout_data_lo <= (others => '-');
                        cmac_readout_data_lo(2*c_CMAC_ACCUM_WIDTH-1 downto 0) <=
                            std_logic_vector(
                            to_unsigned(freq*2**8 + 2, c_CMAC_ACCUM_WIDTH) &
                            to_unsigned(tdm_slot*2**8 + row, c_CMAC_ACCUM_WIDTH));
                        cmac_readout_vld <= '1';
                        wait until rising_edge(clk);
                        uniform(seed1, seed2, rand); dice := integer(FLOOR(rand*5.0));
                        while dice /= 0 loop
                            cmac_readout_vld <= '0';
                            wait until rising_edge(clk);
                            uniform(seed1, seed2, rand); dice := integer(FLOOR(rand*5.0));
                        end loop;
                        -- YY Pol Real & Imag
                        cmac_readout_data_hi <= (others => '-');
                        cmac_readout_data_hi(2*c_CMAC_ACCUM_WIDTH-1 downto 0) <=
                            std_logic_vector(
                            to_unsigned(freq*2**8 + 1, c_CMAC_ACCUM_WIDTH) &
                            to_unsigned(tdm_slot*2**8 + row, c_CMAC_ACCUM_WIDTH));
                        cmac_readout_data_lo <= (others => '-');
                        cmac_readout_vld <= '1';
                        wait until rising_edge(clk);
                        uniform(seed1, seed2, rand); dice := integer(FLOOR(rand*5.0));
                        while dice /= 0 loop
                            cmac_readout_vld <= '0';
                            wait until rising_edge(clk);
                            uniform(seed1, seed2, rand); dice := integer(FLOOR(rand*5.0));
                        end loop;
                    end loop;  -- row
                    for invalid in 1 to g_CMAC_ACCUM_SAMPLES - g_COL_DIMENSION*5 loop
                        cmac_readout_data_hi <= (others => '-');
                        cmac_readout_data_lo <= (others => '-');
                        cmac_readout_vld  <= '0';
                        wait until rising_edge(clk);
                    end loop;  -- invalid
                end loop;  -- tdm_slot
            end loop;  -- time_slice
        end loop;  -- freq
        wait for 1 us;          -- for data to finish being output.
        ---------------------------------------------------------------------------------

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

    P_CHECK_OUTPUT : process (clk) is
    begin  -- process
        if rising_edge(clk) then      -- rising clock edge
            if lta_vld then
                check_equal(lta_data.DVC,
                            g_MAX_CHANNEL_AVERAGE *
                            g_CMAC_DUMPS_PER_MTA_DUMP *
                            g_CMAC_ACCUM_SAMPLES,
                            "Data Valid Count.");
                check_equal(lta_data.TCI,
                            g_MAX_CHANNEL_AVERAGE *
                            (g_CMAC_DUMPS_PER_MTA_DUMP * g_CMAC_ACCUM_SAMPLES) *
                            (g_CMAC_DUMPS_PER_MTA_DUMP * g_CMAC_ACCUM_SAMPLES + 1) / 2,
                            "Time Centroid Index.");
                check_equal(lta_data.CCI,
                            g_MAX_CHANNEL_AVERAGE * (g_MAX_CHANNEL_AVERAGE - 1) / 2 *
                            g_CMAC_DUMPS_PER_MTA_DUMP * g_CMAC_ACCUM_SAMPLES,
                            "Channel Centroid Index.");
                check_equal(lta_data.pol_XX_real,
                            (4 * g_MAX_CHANNEL_AVERAGE +
                             g_MAX_CHANNEL_AVERAGE * (g_MAX_CHANNEL_AVERAGE - 1) / 2 *
                             16#100#) *
                            g_CMAC_DUMPS_PER_MTA_DUMP,
                            "Polarisation XX Real Accumulation");
                check_equal(lta_data.pol_XY_real,
                            (3 * g_MAX_CHANNEL_AVERAGE +
                             g_MAX_CHANNEL_AVERAGE * (g_MAX_CHANNEL_AVERAGE - 1) / 2 *
                             16#100#) *
                            g_CMAC_DUMPS_PER_MTA_DUMP,
                            "Polarisation XY Real Accumulation");
                check_equal(lta_data.pol_YX_real,
                            (2 * g_MAX_CHANNEL_AVERAGE +
                             g_MAX_CHANNEL_AVERAGE * (g_MAX_CHANNEL_AVERAGE - 1) / 2 *
                             16#100#) *
                            g_CMAC_DUMPS_PER_MTA_DUMP,
                            "Polarisation YX Real Accumulation");
                check_equal(lta_data.pol_YY_real,
                            (1 * g_MAX_CHANNEL_AVERAGE +
                             g_MAX_CHANNEL_AVERAGE * (g_MAX_CHANNEL_AVERAGE - 1) / 2 *
                             16#100#) *
                            g_CMAC_DUMPS_PER_MTA_DUMP,
                            "Polarisation YY Real Accumulation");
            end if;
        end if;
    end process;

end architecture sim;

------------------------------------------------------------------------------------------------------------------------
