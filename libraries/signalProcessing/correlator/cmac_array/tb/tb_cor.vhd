-------------------------------------------------------------------------------
-- Title      : Testbench for design "cmac_array"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tb\cmac_array_tb.vhd
-- Author     : William Kamp  <william.kamp@aut.ac.nz>
-- Company    : High Performance Computing Research Lab, Auckland University of Technology
-- Created    : 2017-08-03
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
-- 2017-08-03  1.0      will	Created
-- 2019-09-16  2.0p     nabel   Ported to Perentie
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.all;

Library axi4_lib;
USE axi4_lib.axi4_lite_pkg.ALL;

use work.cor_config_reg_pkg.all;

use work.misc_tools_pkg.all;            -- ceil_log2, bit_width
use work.cmac_pkg.all;                  -- t_cmac_input_bus_a
use work.misc_tools_pkg.all;            -- wired_or
use work.common_types_pkg.all;          -- slv_8_a
use work.cmac_tdm_pkg.all;              -- t_tdm_rd_ctrl, t_tdm_cache_wr_bus_a
use work.visibility_pkg.all;            -- t_visibility_context
use work.mta_regs_pkg.all;              -- t_cci_ram_wr_reg

library common_tb_lib;
use common_tb_lib.common_tb_pkg.all;

------------------------------------------------------------------------------------------------------------------------

entity tb_cor is
    generic (
        g_COL_DIMENSION   : natural := 2;
        g_ANTENNA_PER_COL : natural := 3
        );
end entity tb_cor;

------------------------------------------------------------------------------------------------------------------------

architecture sim of tb_cor is

    -- component generics
    constant g_NUM_SAMPLES                 : natural := 24;
    constant g_CMAC_DUMPS_PER_MTA_DUMP     : natural := 2;   -- number of CMAC dumps in a minimum integration period. e.g. 17.
    constant g_MAX_CHANNEL_AVERAGE         : natural := 8;   -- maximum number of channels that can be averaged. e.g. 8
    constant g_NUM_CHANNELS                : natural := 16;

    constant g_NUM_OF_NON_AUTO_SLOTS       : natural := g_ANTENNA_PER_COL * (g_ANTENNA_PER_COL-1) / 2;
    constant g_NUM_OF_AUTO_SLOTS           : natural := (g_ANTENNA_PER_COL+1) / 2;
    constant g_NUM_OF_SLOTS                : natural := g_NUM_OF_NON_AUTO_SLOTS + g_NUM_OF_AUTO_SLOTS;
    constant g_NUMBER_OF_BASELINES_PER_COL : natural := g_NUM_OF_AUTO_SLOTS*(g_COL_DIMENSION+1) + g_NUM_OF_NON_AUTO_SLOTS*g_COL_DIMENSION;

    constant g_SAMPLE_WIDTH    : natural range 0 to 9 := 8;

    constant c_MTA_ACCUM_SAMPLES : natural := g_NUM_SAMPLES * g_CMAC_DUMPS_PER_MTA_DUMP;
    constant c_MTA_ACCUM_WIDTH   : natural := f_cmac_accum_width(g_SAMPLE_WIDTH, c_MTA_ACCUM_SAMPLES, g_MAX_CHANNEL_AVERAGE);


    type ant_array2  is array(0 to g_ANTENNA_PER_COL*g_COL_DIMENSION-1, 0 to g_NUM_SAMPLES*g_CMAC_DUMPS_PER_MTA_DUMP-1) of integer;

    -------------------------------------
    -- TDM   | Antenna group:
    -- slot  | A(0)   B(1)   C(2)   D(3)   <-g_ANTENNA_PER_COL
    ---------+---------------------------
    -- A(0)  |   
    -- B(1)  |   0,3a 
    -- C(2)  |   1    4   
    -- D(3)  |   2    5      6, 7a
    -------------------------------------
    --
    -- Non-Auto slots contain g_COL_DIMENSION   baselines per cache column
    --     Auto slots contain g_COL_DIMENSION+1 baselines per cache column
    -------------------------------------
    type t_bl_coordinates is record
        x   : integer; -- x coordinate of the TDM slot
        y   : integer; -- y coordinate of the TDM slot
        z   : integer; -- TDM slot#
        au  : boolean; -- auto correlation: this is an auto TDM
        r   : integer; -- helper row: the antenna row# inside a TDM slot
        bl  : integer; -- baseline
        row : integer; -- the antenna row#    this baseline belongs to
        col : integer; -- the antenna column# this baseline belongs to
        vld : boolean; -- this baseline reflects a valid value and needs to be checked
    end record;
    type t_bl_coordinates_a is array(g_COL_DIMENSION-1 downto 0, g_NUMBER_OF_BASELINES_PER_COL-1 downto 0) of t_bl_coordinates;

    constant c_BLC_ZERO : t_bl_coordinates := (
        x   => 0,
        y   => 0,
        z   => 0,
        au  => false,                   -- auto
        r   => 0,
        bl  => 0,                       -- baseline
        row => 0,
        col => 0,
        vld => true
    );

    function get_bl_coordinates (
        i_cache : integer;              -- column
        i_bl    : integer               -- baseline
    ) return t_bl_coordinates is
        variable bl  : integer;
        variable blc : t_bl_coordinates;
    begin
        bl     := i_bl;
        blc    := c_BLC_ZERO;
        blc.bl := i_bl;
        blc.y  := 1;
        
        --determine TDM slot:
        while true loop
            if ((g_ANTENNA_PER_COL mod 2) = 1) and (blc.z=g_NUM_OF_SLOTS-1) then
                    -- this is the last slot for an odd g_ANTENNA_PER_COL (special case with partially invalid data)
                    assert bl <= g_COL_DIMENSION report "Baseline number out of bounds!" severity ERROR;
                    blc.au := true;
                    blc.r  := bl;
                    blc.x  := g_ANTENNA_PER_COL-1;
                    blc.y  := g_ANTENNA_PER_COL-1;
                    exit;
            end if;
            assert blc.y < g_ANTENNA_PER_COL report "Baseline number out of bounds!" severity ERROR;
            if bl < g_COL_DIMENSION then
                -- this is the slot
                blc.r := bl;
                exit;
            elsif (blc.y = g_ANTENNA_PER_COL-1) and (blc.x mod 2)=0 then
                -- move to auto correlation slot and treat it here
                blc.z  := blc.z + 1;
                blc.y  := blc.x + 1;
                bl     := bl - g_COL_DIMENSION;
                if bl < g_COL_DIMENSION+1 then
                    -- this is an auto slot
                    blc.au := true;
                    blc.r  := bl;
                    exit;
                else
                    -- move from auto slot to the next column
                    blc.z  := blc.z + 1;
                    blc.x  := blc.x + 1;
                    blc.y  := blc.y + 1;
                    bl     := bl - (g_COL_DIMENSION+1);
               end if;
            elsif (blc.y = g_ANTENNA_PER_COL-1) and (blc.x mod 2)=1 then
                -- move to the next column (no auto here)
                blc.z := blc.z + 1;
                blc.x := blc.x + 1;
                blc.y := blc.x + 1;
                bl    := bl - g_COL_DIMENSION;
            else
                -- move one slot down
                blc.z := blc.z + 1;
                blc.y := blc.y + 1;
                bl    := bl - g_COL_DIMENSION;
            end if;
        end loop;                                                 -- Example: z=0 => y=1, x=2
                                                                  --
        --determine row & col:                                    -- bl: r:      A(0) A(1) A(2) A(3) (n)
        if blc.au=false then                                      --  3  0   B(4)
            --non-auto slot                                       --  2  1   B(5)         \/
            blc.row := g_COL_DIMENSION * blc.y + blc.r;           --  1  2   B(6)         /\
            blc.col := g_COL_DIMENSION * blc.x + i_cache;         --  0  3   B(7)
        else                                                      --           m
            --auto slot                                           --
            if blc.r < i_cache then                               -- Same example as an auto correlation slot:
                blc.row := g_COL_DIMENSION * blc.x + blc.r;       -- above the diagonal we have A(n)*A(m)
                blc.col := g_COL_DIMENSION * blc.x + i_cache;
                if ((g_ANTENNA_PER_COL mod 2) = 1) and (blc.z=g_NUM_OF_SLOTS-1) then
                    -- If Odd number of antenna per column and last TDM slot.
                    -- Then the last slot is only valid below the diagonal - since only the rows have the data for the
                    -- last set of antenna. Above the diagonal, the first upper triangle is repeated.
                    blc.vld := false;                             --invalid baselines above the diagonal
                end if;
            elsif blc.r = i_cache then
                blc.row := g_COL_DIMENSION * blc.x + i_cache;    
                blc.col := g_COL_DIMENSION * blc.x + i_cache;     -- On the 1. diagonal we have A(n)*A(n)
                if ((g_ANTENNA_PER_COL mod 2) = 1) and (blc.z=g_NUM_OF_SLOTS-1) then
                    blc.vld := false;                             -- invalid baseline above the diagonal.
                end if;
            elsif blc.r = i_cache+1 then                          -- (this is semantically also on the diagonal)
                blc.row := g_COL_DIMENSION * blc.y + i_cache;     -- On the 2. diagonal we have B(n)*B(n)
                blc.col := g_COL_DIMENSION * blc.y + i_cache;
            else
                blc.row := g_COL_DIMENSION * blc.y + blc.r-1;     -- below the diagonal we have B(n)*B(m)
                blc.col := g_COL_DIMENSION * blc.y + i_cache;    
            end if;
                
        end if;    
                
        return blc;
    end function;

        
    function create_baseline_coordinates return t_bl_coordinates_a is
        variable blc_array : t_bl_coordinates_a;
    begin
        for cache in 0 to g_COL_DIMENSION-1 loop
            for bl in 0 to g_NUMBER_OF_BASELINES_PER_COL-1 loop
                blc_array(cache, bl) := get_bl_coordinates(cache, bl);
            end loop;
        end loop;
        return blc_array;
    end function;

    constant c_baseline_coordinates : t_bl_coordinates_a := create_baseline_coordinates;


    -- component ports
    signal cturn_clk       : std_logic := '1';

    -- Input packet bus
    signal tdm_cache_wr_bus : t_tdm_cache_wr_bus_a(g_COL_DIMENSION-1 downto 0);
    signal wr_stop          : std_logic_vector(g_COL_DIMENSION-1 downto 0);  -- stop at the end of this burst.

    signal cmac_clk       : std_logic := '1';

    signal i_context   : t_visibility_context;
    signal context_vld : std_logic := '0';
    signal context_rdy : std_logic;

    signal cci_progs : t_cci_ram_wr_reg_a(g_COL_DIMENSION-1 downto 0) := (others => T_CCI_RAM_WR_REG_ZERO);
    
    signal mta_data_frames : t_mta_data_frame_a(g_COL_DIMENSION-1 downto 0);
    signal mta_vld         : std_logic_vector(g_COL_DIMENSION-1 downto 0);

    type acc_array is array(0 to g_ANTENNA_PER_COL*g_COL_DIMENSION-1, 0 to g_ANTENNA_PER_COL*g_COL_DIMENSION-1) of integer;
    signal acc_XX_re, acc_XX_im   : acc_array := (others => (others => 0));
    signal acc_XY_re, acc_XY_im   : acc_array := (others => (others => 0));
    signal acc_YX_re, acc_YX_im   : acc_array := (others => (others => 0));
    signal acc_YY_re, acc_YY_im   : acc_array := (others => (others => 0));

    signal bl_count : integer := 0;
    
    signal mace_clk     : std_logic := '0';
    signal mace_clk_rst : std_logic := '1'; 
    signal saxi_mosi    : t_axi4_lite_mosi;
    signal saxi_miso    : t_axi4_lite_miso;

begin  -- architecture sim

    -- component instantiation
    DUT: entity work.cmac_array
    generic map (
        g_COL_DIMENSION   => g_COL_DIMENSION,    -- [natural]
        g_ANTENNA_PER_COL => g_ANTENNA_PER_COL,  -- [natural]
        g_NUM_SAMPLES     => g_NUM_SAMPLES,      -- [natural]
        g_CMAC_DUMPS_PER_MTA_DUMP => g_CMAC_DUMPS_PER_MTA_DUMP,
        g_MAX_CHANNEL_AVERAGE => g_MAX_CHANNEL_AVERAGE,
        g_SAMPLE_WIDTH    => g_SAMPLE_WIDTH,
        g_NUM_CHANNELS    => g_NUM_CHANNELS)     -- [natural range 0 to 9]
    port map (
        --MACE
        i_mace_clk         => mace_clk,
        i_mace_clk_rst     => mace_clk_rst,
        o_saxi_miso        => saxi_miso,
        i_saxi_mosi        => saxi_mosi,
        
        -- Input data interface
        i_cturn_clks       => (others => cturn_clk),        -- [std_logic]
        i_tdm_cache_wr_bus => tdm_cache_wr_bus,  -- [t_tdm_cache_wr_bus_a(g_COL_DIMENSION-1 downto 0)]
        o_wr_stop          => wr_stop,  -- [std_logic_vector(g_COL_DIMENSION-1 downto 0)] stop at the end of this burst.

        --Context interface
        i_ctx_clk          => cturn_clk,
        i_context          => i_context,    -- t_visibility_context;
        i_context_vld      => context_vld,  -- set high when new context is available.
        o_context_ready    => context_rdy,  -- high when new context is accepted.

        --Programming interface
        i_cci_progs        => cci_progs, -- t_cci_ram_wr_reg_a(g_COL_DIMENSION-1 downto 0);

        -- Output Interface to Debursting Buffer
        i_cmac_clk         => cmac_clk,
        o_mta_context      => open,
        o_mta_context_vld  => open,
        o_mta_data_frame   => mta_data_frames,
        o_mta_vld          => mta_vld
    );

    -- clock generation
    cturn_clk       <= not cturn_clk after 2 ns;
    cmac_clk        <= not cmac_clk  after 2 ns;
    
    mace_clk <= not mace_clk after 10 ns;
    
    mace_clk_rst <= '1', '0' after 200 ns;
    
    
    P_MAIN : process is
        variable X_re, X_im, Y_re, Y_im : ant_array2;
        variable baseline : integer;
    begin

        for cache in 0 to g_COL_DIMENSION-1 loop                        
            tdm_cache_wr_bus(cache).wr_enable   <= '0';
            tdm_cache_wr_bus(cache).dbl_buf_sel <= '0';
        end loop;
    
        i_context.tdm_lap_start <= '0';  --set internally
        i_context.tdm_lap       <= to_unsigned(0, 08);
        i_context.channel       <= to_unsigned(7, 16);
        i_context.timestamp     <= to_unsigned(4711, 32);
        context_vld <= '0';
        
        wait until mace_clk_rst = '0';       
        wait for 200 ns;
        
        wait until rising_edge(mace_clk);

        -- For some reason the first transaction doesn't work; this is just a dummy transaction
        axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, c_setup_full_reset_address.base_address, true, x"00000001");
        wait until rising_edge(mace_clk);

        --turn mace reset on 
        axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, c_setup_full_reset_address.base_address, true, x"00000001");
        
        --turn mace reset off 
        axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, c_setup_full_reset_address.base_address, true, x"00000000");
        
        
        
        wait until rising_edge(cturn_clk);
        
        --Program MTA
        for cache in 0 to g_COL_DIMENSION-1 loop                        
            cci_progs(cache).reset <= '1';
            for idx in 0 to 5 loop
                cci_progs(cache).clk <= '0'; wait for 2 ns; cci_progs(cache).clk <= '1'; wait for 2 ns;
            end loop;
            cci_progs(cache).reset <= '0';
            for idx in 0 to 5 loop
                cci_progs(cache).clk <= '0'; wait for 2 ns; cci_progs(cache).clk <= '1'; wait for 2 ns;
            end loop;
            for addr in 0 to 2**(ceil_log2(g_NUM_CHANNELS))-1 loop
                cci_progs(cache).address    <= to_unsigned(addr, 32);
                cci_progs(cache).wr_req     <= '1';
                cci_progs(cache).cci_factor <= (others => '0'); --no inter-channel accumulation
                cci_progs(cache).clk <= '0'; wait for 2 ns; cci_progs(cache).clk <= '1'; wait for 2 ns;
            end loop;
            cci_progs(cache).wr_req <= '0';
            cci_progs(cache).clk <= '0'; wait for 2 ns; cci_progs(cache).clk <= '1'; wait for 2 ns;
        end loop;

        wait until rising_edge(cturn_clk);

        for lap in 0 to g_CMAC_DUMPS_PER_MTA_DUMP-1 loop
            if context_rdy='0' then
                wait until context_rdy='1';
            end if;
            wait until rising_edge(cturn_clk);

            i_context.tdm_lap       <= to_unsigned(lap, 08);
            i_context.channel       <= to_unsigned(7, 16);
            i_context.timestamp     <= to_unsigned(now / 1 ns, 32);

            -- Write data into the cache.
            for idx in g_NUM_SAMPLES*lap to g_NUM_SAMPLES*(lap+1)-1 loop
                for ant in 0 to g_ANTENNA_PER_COL-1 loop
                    for cache in 0 to g_COL_DIMENSION-1 loop                        
                        X_re(ant*g_COL_DIMENSION+cache, idx) := ((ant*g_COL_DIMENSION+cache)*(idx*4)+0) mod (2**g_SAMPLE_WIDTH/2);
                        X_im(ant*g_COL_DIMENSION+cache, idx) := ((ant*g_COL_DIMENSION+cache)*(idx*4)+1) mod (2**g_SAMPLE_WIDTH/2);
                        Y_re(ant*g_COL_DIMENSION+cache, idx) := ((ant*g_COL_DIMENSION+cache)*(idx*4)+2) mod (2**g_SAMPLE_WIDTH/2);
                        Y_im(ant*g_COL_DIMENSION+cache, idx) := ((ant*g_COL_DIMENSION+cache)*(idx*4)+3) mod (2**g_SAMPLE_WIDTH/2);

                        tdm_cache_wr_bus(cache).real_polX   <= to_signed(X_re(ant*g_COL_DIMENSION+cache, idx), 9);   
                        tdm_cache_wr_bus(cache).imag_polX   <= to_signed(X_im(ant*g_COL_DIMENSION+cache, idx), 9);       
                        tdm_cache_wr_bus(cache).real_polY   <= to_signed(Y_re(ant*g_COL_DIMENSION+cache, idx), 9); 
                        tdm_cache_wr_bus(cache).imag_polY   <= to_signed(Y_im(ant*g_COL_DIMENSION+cache, idx), 9);       
                        tdm_cache_wr_bus(cache).wr_addr     <= to_unsigned(ant * f_ADDR_STRIDE(g_ANTENNA_PER_COL, g_NUM_SAMPLES) + (idx-g_NUM_SAMPLES*lap), 16);
                        tdm_cache_wr_bus(cache).wr_enable   <= '1';
                    end loop;  -- bus
                    wait until rising_edge(cturn_clk);
                end loop;
            end loop;
            for cache in 0 to g_COL_DIMENSION-1 loop                        
                tdm_cache_wr_bus(cache).wr_enable   <= '0';
                tdm_cache_wr_bus(cache).dbl_buf_sel <= not tdm_cache_wr_bus(cache).dbl_buf_sel;
            end loop;
            wait until rising_edge(cturn_clk);

            context_vld <= '1';
            wait until rising_edge(cturn_clk);
            context_vld <= '0';

            for col in 0 to g_ANTENNA_PER_COL*g_COL_DIMENSION-1 loop
                for row in 0 to g_ANTENNA_PER_COL*g_COL_DIMENSION-1 loop
                    for idx in g_NUM_SAMPLES*lap to g_NUM_SAMPLES*(lap+1)-1  loop

                        acc_XX_im(row, col) <= acc_XX_im(row, col) + X_im(row, idx) * X_re(col, idx) + X_re(row,idx) * (-X_im(col,idx));
                        acc_XX_re(row, col) <= acc_XX_re(row, col) + X_re(row, idx) * X_re(col, idx) - X_im(row,idx) * (-X_im(col,idx));

                        acc_YX_im(row, col) <= acc_YX_im(row, col) + Y_im(row, idx) * X_re(col, idx) + Y_re(row,idx) * (-X_im(col,idx));
                        acc_YX_re(row, col) <= acc_YX_re(row, col) + Y_re(row, idx) * X_re(col, idx) - Y_im(row,idx) * (-X_im(col,idx));

                        acc_XY_im(row, col) <= acc_XY_im(row, col) + X_im(row, idx) * Y_re(col, idx) + X_re(row,idx) * (-Y_im(col,idx));
                        acc_XY_re(row, col) <= acc_XY_re(row, col) + X_re(row, idx) * Y_re(col, idx) - X_im(row,idx) * (-Y_im(col,idx));

                        acc_YY_im(row, col) <= acc_YY_im(row, col) + Y_im(row, idx) * Y_re(col, idx) + Y_re(row,idx) * (-Y_im(col,idx));
                        acc_YY_re(row, col) <= acc_YY_re(row, col) + Y_re(row, idx) * Y_re(col, idx) - Y_im(row,idx) * (-Y_im(col,idx));

                        wait for 0 ns; --actually update the signal, to allow accumulation

                    end loop;
                end loop;
            end loop;      

            wait until context_rdy='1';
            --wait for 3 us; --todo: wr_stop should be implemented

        end loop;
        
        while bl_count < g_COL_DIMENSION*g_NUMBER_OF_BASELINES_PER_COL loop
              wait for 1 us;
        end loop;                    

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
    


    P_CHECK: process
        variable baseline    : integer;
        variable coordinates : t_bl_coordinates;
        
        variable mta_xx_im : integer;
        variable mta_xx_re : integer;
        variable mta_yx_im : integer;
        variable mta_yx_re : integer;
        variable mta_xy_im : integer;
        variable mta_xy_re : integer;
        variable mta_yy_im : integer;
        variable mta_yy_re : integer;

        type str_ptr is access string;
        variable loc_string : str_ptr;

        variable baslines_vld_cnt : natural;
                            

    begin
        wait until rising_edge(cmac_clk);
        baslines_vld_cnt := 0;
           
        for cache in 0 to g_COL_DIMENSION-1 loop
            if mta_vld(cache)='1' then
                baslines_vld_cnt := baslines_vld_cnt + 1;
                
                baseline    := to_integer(unsigned(mta_data_frames(cache).baseline));
                coordinates := c_baseline_coordinates(cache, baseline);

                mta_xx_im := to_integer(signed(mta_data_frames(cache).pol_XX_imag(c_MTA_ACCUM_WIDTH-1 downto 0)));
                mta_xx_re := to_integer(signed(mta_data_frames(cache).pol_XX_real(c_MTA_ACCUM_WIDTH-1 downto 0)));
                mta_yx_im := to_integer(signed(mta_data_frames(cache).pol_YX_imag(c_MTA_ACCUM_WIDTH-1 downto 0)));
                mta_yx_re := to_integer(signed(mta_data_frames(cache).pol_YX_real(c_MTA_ACCUM_WIDTH-1 downto 0)));
                mta_xy_im := to_integer(signed(mta_data_frames(cache).pol_XY_imag(c_MTA_ACCUM_WIDTH-1 downto 0)));
                mta_xy_re := to_integer(signed(mta_data_frames(cache).pol_XY_real(c_MTA_ACCUM_WIDTH-1 downto 0)));
                mta_yy_im := to_integer(signed(mta_data_frames(cache).pol_YY_imag(c_MTA_ACCUM_WIDTH-1 downto 0)));
                mta_yy_re := to_integer(signed(mta_data_frames(cache).pol_YY_real(c_MTA_ACCUM_WIDTH-1 downto 0)));

                
                
                if coordinates.vld then
                    loc_string := new string'(", Column: " & integer'image(cache) &
                                              ", Baseline: " & integer'image(baseline) &
                                              ", Row: " & integer'image(coordinates.row) &
                                              ", Col: " & integer'image(coordinates.col));
                    
                    check_equal(mta_xx_im, acc_XX_im(coordinates.row, coordinates.col), "XX Imaginary" & loc_string.all);  
                    check_equal(mta_xx_re, acc_XX_re(coordinates.row, coordinates.col), "XX Real" & loc_string.all);
                    if coordinates.au then
                        -- In auto correlations one of XY or YX will be correct, the other will be zero, depending on if it is above or
                        -- below the diagonal.
                        if mta_yx_re = 0 then
                            check_equal(mta_xy_im, acc_XY_im(coordinates.row, coordinates.col), "XY Imaginary" & loc_string.all);  
                            check_equal(mta_xy_re, acc_XY_re(coordinates.row, coordinates.col), "XY Real" & loc_string.all);
                        else
                            check_equal(mta_yx_im, acc_YX_im(coordinates.row, coordinates.col), "YX Imaginary" & loc_string.all);  
                            check_equal(mta_yx_re, acc_YX_re(coordinates.row, coordinates.col), "YX Real" & loc_string.all);
                        end if;
                    else
                        check_equal(mta_yx_im, acc_YX_im(coordinates.row, coordinates.col), "YX Imaginary" & loc_string.all);  
                        check_equal(mta_yx_re, acc_YX_re(coordinates.row, coordinates.col), "YX Real" & loc_string.all);  
                        check_equal(mta_xy_im, acc_XY_im(coordinates.row, coordinates.col), "XY Imaginary" & loc_string.all);  
                        check_equal(mta_xy_re, acc_XY_re(coordinates.row, coordinates.col), "XY Real" & loc_string.all);
                    end if;
                    check_equal(mta_yy_im, acc_YY_im(coordinates.row, coordinates.col), "YY Imaginary" & loc_string.all);  
                    check_equal(mta_yy_re, acc_YY_re(coordinates.row, coordinates.col), "YY Real" & loc_string.all);  
                else
                    assert false report "Invalid data filtered out at baseline " & integer'image(baseline) severity NOTE;
                end if;

            end if;
        end loop;

        bl_count <= bl_count + baslines_vld_cnt;

    end process;
        
                                            

end architecture sim;

------------------------------------------------------------------------------------------------------------------------
