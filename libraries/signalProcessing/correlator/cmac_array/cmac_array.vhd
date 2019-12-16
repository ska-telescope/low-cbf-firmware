-------------------------------------------------------------------------------
-- Title      : CMAC Systolic array
-- Project    : 
-------------------------------------------------------------------------------
-- File       : cmac_array.vhd
-- Author     : William Kamp  <william.kamp@aut.ac.nz>
-- Company    : High Performance Computing Research Lab, Auckland University of Technology
-- Created    : 2016-10-12
-- Last update: 2018-07-09
-- Platform   : 
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: 
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

Library axi4_lib;
USE axi4_lib.axi4_lite_pkg.ALL;

use work.cmac_pkg.all;                  -- t_cmac_input_bus_a
use work.misc_tools_pkg.all;            -- wired_or, ceil_pow2(),  bit_width(), ceil_log2()
use work.common_types_pkg.all;          -- slv_8_a
use work.cmac_tdm_pkg.all;              -- t_tdm_rd_ctrl, t_tdm_cache_wr_bus_a
use work.visibility_pkg.all;
use work.mta_regs_pkg.all;              -- t_cci_ram_wr_reg_a

entity cmac_array is

    generic (
        g_COL_DIMENSION           : natural              := 20;
        g_ANTENNA_PER_COL         : natural              := 10;
        g_NUM_SAMPLES             : natural              := 100;
        g_SAMPLE_WIDTH            : natural range 0 to 9 := 9;
        g_NUM_CHANNELS            : natural;  -- number of frequency channels.
        g_CMAC_DUMPS_PER_MTA_DUMP : natural;  -- number of CMAC dumps in a minimum integration period. e.g. 17.
        g_MAX_CHANNEL_AVERAGE     : natural   -- maximum number of channels that can be averaged. e.g. 8
        );

    port (
        ----------------------------------------------------------------------------------------------------------------
        -- MACE
        ----------------------------------------------------------------------------------------------------------------
        i_mace_clk         : in std_logic;
        i_mace_clk_rst     : in std_logic;
        i_saxi_mosi        : IN  t_axi4_lite_mosi;
        o_saxi_miso        : OUT t_axi4_lite_miso;
        ----------------------------------------------------------------------------------------------------------------
        -- Input Data Interface.
        ----------------------------------------------------------------------------------------------------------------
        i_cturn_clks       : in  std_logic_vector(g_COL_DIMENSION-1 downto 0);  -- each clock/reset corresponds to one i_tdm_cache_wr_bus.
        i_tdm_cache_wr_bus : in  t_tdm_cache_wr_bus_a(g_COL_DIMENSION-1 downto 0);
        o_wr_stop          : out std_logic_vector(g_COL_DIMENSION-1 downto 0);  -- stop at the end of this burst.

        ----------------------------------------------------------------------------------------------------------------
        -- Context Interface
        ----------------------------------------------------------------------------------------------------------------
        i_ctx_clk       : in  std_logic;
        i_context       : in  t_visibility_context;
        i_context_vld   : in  std_logic;  -- set high when new context is available.
        o_context_ready : out std_logic;  -- high when new context is accepted.

        ---------------------------------------------------------------------------
        -- Programming Interfaces
        ---------------------------------------------------------------------------
        i_cci_progs : in t_cci_ram_wr_reg_a(g_COL_DIMENSION-1 downto 0);

        ---------------------------------------------------------------------------
        -- Output Interface to Debursting Buffer
        ---------------------------------------------------------------------------
        i_cmac_clk        : in  std_logic;
        o_mta_context     : out t_visibility_context;
        o_mta_context_vld : out std_logic;
        o_mta_data_frame  : out t_mta_data_frame_a;
        o_mta_vld         : out std_logic_vector(g_COL_DIMENSION-1 downto 0)
        );

end entity cmac_array;

architecture struct of cmac_array is

    constant c_PIPELINE_CYCLES : natural range 2 to natural'high := 2;

    -----------------------------------------------------------------------------------
    -- i_cturn_clk Domains
    -----------------------------------------------------------------------------------
    signal cturn_clk_resets     : std_logic_vector(g_COL_DIMENSION-1 downto 0);
    signal col_cturn_clk_resets : std_logic_vector(cturn_clk_resets'range);
    signal row_cturn_clk_resets : std_logic_vector(cturn_clk_resets'range);

    -----------------------------------------------------------------------------------
    -- i_cmac_clk Domain.
    -----------------------------------------------------------------------------------
    signal cmac_clk_reset  : std_logic;
    signal col_cmac_clk_reset : std_logic_vector(g_COL_DIMENSION downto 0);
    signal row_cmac_clk_reset : std_logic_vector(g_COL_DIMENSION downto 0);

    signal col_rd_ctrl : t_tdm_rd_ctrl_a(g_COL_DIMENSION downto 0);
    signal row_rd_ctrl : t_tdm_rd_ctrl_a(g_COL_DIMENSION downto 0);

    type t_cmac_input_bus_dual_pol_a is array (natural range <>) of t_cmac_input_bus_a(0 to 1);
    type t_cmac_input_bus_dual_pol_matrix is array (natural range 0 to g_COL_DIMENSION) of t_cmac_input_bus_dual_pol_a(0 to g_COL_DIMENSION);  -- Matrix for rows and columns
    -- Row interconnect.
    signal rows                  : t_cmac_input_bus_dual_pol_matrix;
    signal cols                  : t_cmac_input_bus_dual_pol_matrix;
    -- Prevents Quartus Prime from merging a register with a duplicate register - bad for resource usage, better 
    -- for timing. 
    --attribute dont_merge         : boolean; 
    --attribute dont_merge of rows : signal is true; 
    --attribute dont_merge of cols : signal is true; 

    signal ctx_clk_reset   : std_logic;
    signal tdm_context     : t_visibility_context;
    signal tdm_context_slv : std_logic_vector(T_VISIBILITY_CONTEXT_SLV_WIDTH-1 downto 0);
    signal tdm_context_vld : std_logic;
    signal tdm_context_ack : std_logic;

    signal tdm_first : std_logic;
    signal tdm_last  : std_logic;
    signal tdm_slot  : unsigned(ceil_log2((g_ANTENNA_PER_COL**2+1)/2)-1 downto 0);

    signal cmac_context : t_visibility_context;

    signal mta_context  : t_visibility_context_a(0 to g_COL_DIMENSION);

    constant c_CACHE_LATENCY : natural := 5;
    constant c_QUAD_CMAC_LATENCY  : natural := work.cmac_pkg.c_CMAC_LATENCY + 2;  -- measure in simulator from rising_edge(i_col.last) to rising_edge(o_readout_vld) in cycles.
    constant c_PIPELINE_DELAY  : natural := c_PIPELINE_CYCLES;
    constant c_DELAY_COUNT_INIT : natural range 6 to natural'high := c_CACHE_LATENCY + c_QUAD_CMAC_LATENCY + c_PIPELINE_DELAY;
    signal delay_cnt : unsigned(ceil_log2(c_DELAY_COUNT_INIT+1) downto 0);
    signal delay_cnt_prev : std_logic;
    signal delay_term : std_logic;

    constant c_READOUT_CYCLES : natural := 3*(g_COL_DIMENSION+1);
    constant c_MTA_LATENCY : natural := 16;
    constant c_TDM_LAST_DELAY_COUNT_INIT : natural := c_DELAY_COUNT_INIT + c_READOUT_CYCLES + c_MTA_LATENCY + c_PIPELINE_CYCLES*g_COL_DIMENSION;
    signal tdm_last_delay_cnt : unsigned(ceil_log2(c_TDM_LAST_DELAY_COUNT_INIT) downto 0);
    signal tdm_last_delay_cnt_prev : std_logic;
    signal tdm_last_delay_term : std_logic;

    
begin  -- architecture struct

    --connection to MACE
    E_CONFIG: entity work.cor_config
    generic map (
        g_COL_DIMENSION    => g_COL_DIMENSION
    ) port map( 
        i_mace_clk         => i_mace_clk,
        i_mace_clk_rst     => i_mace_clk_rst,
        i_cturn_clks       => i_cturn_clks,             
        o_cturn_clk_resets => cturn_clk_resets,            
        i_ctx_clk          => i_ctx_clk,
        o_ctx_clk_reset    => ctx_clk_reset,
        i_cmac_clk         => i_cmac_clk,
        o_cmac_clk_reset   => cmac_clk_reset,
        --MACE:
        i_saxi_mosi     => i_saxi_mosi,
        o_saxi_miso     => o_saxi_miso
    );            

    col_cmac_clk_reset(0) <= cmac_clk_reset;
    row_cmac_clk_reset(0) <= cmac_clk_reset;
                                                   
    E_COL_CMAC_RESET_PIPE : entity work.pipeline_delay
        generic map (
            g_CYCLES_DELAY => c_PIPELINE_CYCLES)                      -- [natural]
        port map (
            i_clk => i_cmac_clk,                                      -- [std_logic]
            i_bus => col_cmac_clk_reset(g_COL_DIMENSION-1 downto 0),  -- [std_logic_vector]
            o_bus => col_cmac_clk_reset(g_COL_DIMENSION downto 1));   -- [std_logic_vector]

    E_ROW_CMAC_RESET_PIPE : entity work.pipeline_delay
        generic map (
            g_CYCLES_DELAY => c_PIPELINE_CYCLES)                      -- [natural]
        port map (
            i_clk => i_cmac_clk,                                      -- [std_logic]
            i_bus => row_cmac_clk_reset(g_COL_DIMENSION-1 downto 0),  -- [std_logic_vector]
            o_bus => row_cmac_clk_reset(g_COL_DIMENSION downto 1));   -- [std_logic_vector]

    -- Retime the new context into the i_cmac_clk domain.
    E_RETIME_CONTEXT : entity work.retime_slv
        generic map (
            g_SYNCHRONISER_FLOPS => 3)            -- [natural range 2 to 4]
        port map (
            i_tx_clk       => i_ctx_clk,          -- [std_logic]
            i_tx_clk_reset => ctx_clk_reset,    -- [std_logic]
            i_tx_data      => to_slv(i_context),  -- [std_logic_vector]
            i_tx_vld       => i_context_vld,      -- [std_logic]
            o_tx_ready     => o_context_ready,    -- [std_logic]
            --------------------------------------
            i_rx_clk       => i_cmac_clk,         -- [std_logic]
            i_rx_clk_reset => cmac_clk_reset,   -- [std_logic]
            o_rx_data      => tdm_context_slv,    -- [std_logic_vector]
            o_rx_vld       => tdm_context_vld,    -- [std_logic]
            i_rx_ack       => tdm_context_ack);   -- [std_logic  :=  '1']
    tdm_context <= from_slv(tdm_context_slv);

    P_CMAC_CONTEXT_LATCH : process (i_cmac_clk) is
    begin
        if rising_edge(i_cmac_clk) then
            if tdm_context_ack='1' then
                cmac_context <= tdm_context;
            end if;
        end if;
    end process;
    -- tdm_context stores the context of the sample data loaded into the tdm cache for the next TDM lap.
    -- cmac_context stores the context of the sample data currently being processed into the CMAC array.
    -- mta_context stores the context of the sample data currently being processed into the MTA.

    E_ARRAY_DRIVER : entity work.cmac_tdm_cache_driver
        generic map (
            g_ANTENNA_PER_COL => g_ANTENNA_PER_COL,  -- [natural range 1 to pc_MAX_ANTENNA_PER_COL] g_NUM_ANTENNA/g_COL_DIMENSION
            g_NUM_SAMPLES     => g_NUM_SAMPLES)  -- [natural range 3 to pc_MAX_NUM_SAMPLES] number of samples in a sub-accumulation.
        port map (
            i_clk         => i_cmac_clk,         -- [std_logic]
            i_clk_reset   => cmac_clk_reset,   -- [std_logic]
            i_start       => tdm_context_vld,    -- [std_logic]
            o_started     => tdm_context_ack,    -- [std_logic]
            o_col_rd_ctrl => col_rd_ctrl(0),     -- [t_tdm_rd_ctrl]
            o_row_rd_ctrl => row_rd_ctrl(0),     -- [t_tdm_rd_ctrl]
            o_tdm_slot    => tdm_slot,           -- [unsigned]
            o_tdm_first   => tdm_first,          -- [std_logic]
            o_tdm_last    => tdm_last);          -- [std_logic]


    -- generate chip enable from column address.
    --rfi_bl_thresh_wr_en <= i_rfi_bl_thresh_wr_en when i_rfi_bl_thresh_wr_col_addr = col else '0';

    g_COL_DRIVERS : for col in 0 to g_COL_DIMENSION-1 generate
        signal tdm_cache_wr_bus_slv : std_logic_vector(T_TDM_CACHE_WR_BUS_SLV_WIDTH-1 downto 0);
    begin
        E_PIPE_WR_BUS : entity work.pipeline_delay
            generic map (
                g_CYCLES_DELAY => 4)                       -- [natural]
            port map (
                i_clk => i_cturn_clks(col),                -- [std_logic]
                i_bus_vld => cturn_clk_resets(col),          -- [std_logic]
                i_bus => to_slv(i_tdm_cache_wr_bus(col)),  -- [std_logic_vector]
                o_bus_vld => col_cturn_clk_resets(col),        -- [std_logic]
                o_bus => tdm_cache_wr_bus_slv);            -- [std_logic_vector]

        E_CACHE : entity work.cmac_tdm_cache
            generic map (
                g_SAMPLE_WIDTH    => g_SAMPLE_WIDTH,     -- [natural range 1 to 9]
                g_ANTENNA_PER_COL => g_ANTENNA_PER_COL,  -- [natural range 1 to pc_MAX_ANTENNA_PER_COL] g_NUM_ANTENNA/g_COL_DIMENSION
                g_NUM_SAMPLES     => g_NUM_SAMPLES,  -- [natural range 3 to pc_MAX_NUM_SAMPLES] number of samples in a sub-accumulation.
                -- set for memory efficiency i.e 512/g_ANTENNA_PER_COL.
                g_IS_COLUMN_CACHE => true,
                g_PIPELINE_CYCLES => c_PIPELINE_CYCLES)  -- [natural]
            port map (
                -- Data input interface
                i_cturn_clk       => i_cturn_clks(col),    -- [std_logic]
                i_cturn_clk_reset => col_cturn_clk_resets(col),  -- [std_logic]

                i_tdm_cache_wr_bus => from_slv(tdm_cache_wr_bus_slv),  -- master, row cache gets same data, but does not
                                                                       -- provide reverse flow control.
                o_wr_stop          => o_wr_stop(col),                  -- [std_logic] stop at the end of this burst.

                -- Read driver interface
                -- connect to global cmac_tdm_cache_driver module.
                i_cmac_clk       => i_cmac_clk,               -- [std_logic]
                i_cmac_clk_reset => col_cmac_clk_reset(col),  -- [std_logic]

                i_tdm_rd_ctrl => col_rd_ctrl(col),  -- [t_tdm_rd_ctrl]
                o_tdm_rd_ctrl => col_rd_ctrl(col+1),

                -- Output to CMAC row or column
                o_cmac_bus => cols(0)(col)  -- [t_cmac_input_bus]
                );
    end generate;

    g_ROW_DRIVERS : for row in 0 to g_COL_DIMENSION-1 generate
        signal tdm_cache_wr_bus_slv : std_logic_vector(T_TDM_CACHE_WR_BUS_SLV_WIDTH-1 downto 0);
    begin
        E_PIPE_WR_BUS : entity work.pipeline_delay
            generic map (
                g_CYCLES_DELAY => 4)                       -- [natural]
            port map (
                i_clk => i_cturn_clks(row),                -- [std_logic]
                i_bus_vld => cturn_clk_resets(row),          -- [std_logic]
                i_bus => to_slv(i_tdm_cache_wr_bus(row)),  -- [std_logic_vector]
                o_bus_vld => row_cturn_clk_resets(row),        -- [std_logic]
                o_bus => tdm_cache_wr_bus_slv);            -- [std_logic_vector]

        E_CACHE : entity work.cmac_tdm_cache
            generic map (
                g_SAMPLE_WIDTH    => g_SAMPLE_WIDTH,     -- [natural range 1 to 9]
                g_ANTENNA_PER_COL => g_ANTENNA_PER_COL,  -- [natural range 1 to pc_MAX_ANTENNA_PER_COL] g_NUM_ANTENNA/g_COL_DIMENSION
                g_NUM_SAMPLES     => g_NUM_SAMPLES,  -- [natural range 3 to pc_MAX_NUM_SAMPLES] number of samples in a sub-accumulation.
                -- set for memory efficiency i.e 512/(g_ANTENNA_PER_COL-1).
                g_IS_COLUMN_CACHE => false,
                g_PIPELINE_CYCLES => c_PIPELINE_CYCLES)  -- [natural]
            port map (
                -- Data input interface
                i_cturn_clk       => i_cturn_clks(row),    -- [std_logic]
                i_cturn_clk_reset => row_cturn_clk_resets(row),  -- [std_logic]

                i_tdm_cache_wr_bus => from_slv(tdm_cache_wr_bus_slv),  -- blindly following, slave to column
                o_wr_stop          => open,  -- slave,  -- [std_logic] stop at the end of this burst.

                -- Read driver interface
                -- connect to global cmac_tdm_cache_driver module.
                i_cmac_clk       => i_cmac_clk,               -- [std_logic]
                i_cmac_clk_reset => row_cmac_clk_reset(row),  -- [std_logic]

                i_tdm_rd_ctrl => row_rd_ctrl(row),  -- [t_tdm_rd_ctrl]
                o_tdm_rd_ctrl => row_rd_ctrl(row+1),

                -- Output to CMAC row or column
                o_cmac_bus => rows(row)(0)  -- [t_cmac_input_bus]
                );
    end generate;

    G_CMACS_COL : for col in 0 to g_COL_DIMENSION-1 generate
        signal readout_vld  : std_logic_vector(g_COL_DIMENSION downto 0);
        signal readout_data : slv_128_a(g_COL_DIMENSION downto 0);

        signal to_mta_readout       : std_logic_vector(readout_data(0)'range);
        signal to_mta_valid         : std_logic;
        signal mta_context_slv      : std_logic_vector(T_VISIBILITY_CONTEXT_SLV_WIDTH-1 downto 0);
        signal this_mta_context_slv : std_logic_vector(T_VISIBILITY_CONTEXT_SLV_WIDTH-1 downto 0);
        signal this_mta_context     : t_visibility_context;

        type t_scan_a is array (0 to g_COL_DIMENSION) of signed(3*g_SAMPLE_WIDTH-1 downto 0);
        signal scan_polX : t_scan_a;
        signal scan_polY : t_scan_a;

        function f_use_scan_in (
            constant row : natural;
            constant col : natural)
            return boolean is
        begin  -- function f_use_scan_in
            return false;
            if row = 0 then
                -- first row so intitialise the scan-in chain.
                return false;
            elsif row = col then
                -- auto correlation CMAC_QUAD.
                return false;
            elsif row = col+1 then
                -- after the auto, so re-initialise scan-in chain with turned signals.
                return false;
            elsif row mod 10 = 0  then
                -- keep chains less than length of 10 to help placer. 
                return false;
            else
                return true;
            end if;
        end function f_use_scan_in;
        
    begin
        readout_vld(g_COL_DIMENSION)  <= '0';
        readout_data(g_COL_DIMENSION) <= (others => '0');
--        readout_vld(0)  <= '0';
--        readout_data(0) <= (others => '0');

        G_CMACS_ROW : for row in 0 to g_COL_DIMENSION-1 generate

            E_CMAC_QUAD : entity work.cmac_quad
                generic map (
                    g_AUTOCORRELATION_CMAC => col = row,       -- [boolean]
                    g_MAX_ACCUM_SAMPLES    => g_NUM_SAMPLES,   -- [natural]
                    g_SAMPLE_WIDTH         => g_SAMPLE_WIDTH,  -- [natural range 1 to 9]  > 6 uses two multiplers per cmac.
                    g_QUAD_CMAC_LATENCY    => c_QUAD_CMAC_LATENCY, -- measure in simulator from rising_edge(i_col.last) to
                                                                   -- rising_edge(o_readout_vld) in cycles.
                    g_USE_SCAN_IN          => f_use_scan_in(row, col),
                    g_PIPELINE_CYCLES      => c_PIPELINE_CYCLES)
                port map (
                    i_clk       => i_cmac_clk,                 -- [std_logic]
                    i_clk_reset => col_cmac_clk_reset(col),    -- [std_logic]

                    i_row => rows(row)(col),  -- [t_cmac_input_bus_a(0 to 1)] dual polarisations
                    i_col => cols(row)(col),  -- [t_cmac_input_bus_a(0 to 1)] dual polarisations

                    i_scan_polX => scan_polX(row),
                    o_scan_polX => scan_polX(row+1),
                    i_scan_polY => scan_polY(row),
                    o_scan_polY => scan_polY(row+1),

                    o_row          => rows(row)(col+1),    -- [t_cmac_input_bus_a(0 to 1)] dual polarisations
                    o_col          => cols(row+1)(col),    -- [t_cmac_input_bus_a(0 to 1)] dual polarisations
                    -- Readout interface. Basically a big sideloaded shift register.
                    -- Loaded by i_<col|row>.last
                    i_readout_vld  => readout_vld(row+1),    -- [std_logic := '0']
                    i_readout_data => readout_data(row+1),   -- [std_logic_vector]
                    o_readout_vld  => readout_vld(row),  -- [std_logic]
                    o_readout_data => readout_data(row)  -- [std_logic_vector]
                    );
            
        end generate;

        E_READOUT_PIPE : entity work.pipeline_delay
            generic map (
                g_CYCLES_DELAY => 0)                         -- [natural]
            port map (
                i_clk     => i_cmac_clk,                     -- [std_logic]
                i_bus     => readout_data(0),  -- [std_logic_vector]
                i_bus_vld => readout_vld(0),   -- [std_logic]
                o_bus     => to_mta_readout,                 -- [std_logic_vector]    
                o_bus_vld => to_mta_valid);                  -- [std_logic]

        E_MTA_LAP_DISTRIBUTE : entity work.pipeline_delay
            generic map (
                g_CYCLES_DELAY => c_PIPELINE_CYCLES)  -- [natural]
            port map (
                i_clk => i_cmac_clk,                  -- [std_logic]
                i_bus => to_slv(mta_context(col)),    -- [std_logic_vector]
                o_bus => mta_context_slv);            -- [std_logic_vector]
        mta_context(col+1) <= from_slv(mta_context_slv);

        E_MTA_LAP_PIPE : entity work.pipeline_delay
            generic map (
                g_CYCLES_DELAY => 0)                -- [natural]
            port map (
                i_clk => i_cmac_clk,                -- [std_logic]
                i_bus => to_slv(mta_context(col)),  -- [std_logic_vector]
                o_bus => this_mta_context_slv);     -- [std_logic_vector]
        this_mta_context <= from_slv(this_mta_context_slv);

        E_MTA : entity work.mid_term_accumulator
            generic map (
                g_COL_DIMENSION           => g_COL_DIMENSION,  -- [natural] number of columns in CMAC array, e.g. 20
                g_THIS_COLUMN             => col,
                g_ANTENNA_PER_COL         => g_ANTENNA_PER_COL,      -- [natural]
                g_NUM_CHANNELS            => g_NUM_CHANNELS,   -- [natural]
                g_SAMPLE_WIDTH            => g_SAMPLE_WIDTH,   -- [natural range 1 to 9]
                g_CMAC_ACCUM_SAMPLES      => g_NUM_SAMPLES,  -- [natural] number of samples in a sub accumulation. e.g. 112. Used to derive
                -- DATA_VALID and TCI readout widths.
                g_CMAC_DUMPS_PER_MTA_DUMP => g_CMAC_DUMPS_PER_MTA_DUMP,  -- [natural] number of CMAC dumps in a minimum integration period. e.g. 17.
                g_MAX_CHANNEL_AVERAGE     => g_MAX_CHANNEL_AVERAGE)  -- [natural] maximum number of channels that can be averaged.
            port map (
                i_clk       => i_cmac_clk,                   -- [std_logic]
                i_clk_reset => cmac_clk_reset,             -- [std_logic]

                i_cmac_readout_data => to_mta_readout,    -- [std_logic_vector]
                i_cmac_readout_vld  => to_mta_valid,      -- [std_logic]
                i_cmac_context      => this_mta_context,  -- [t_visibility_context]

                i_cci_prog => i_cci_progs(col),

                o_mta_data_frame => o_mta_data_frame(col),  -- [t_mta_data_frame]
                o_mta_vld        => o_mta_vld(col));        -- [std_logic]
    end generate;

    -- follow the readout of the first column.
    -- The delay in mta_context(0) is calculated based on knowledge of the latency through the cache and cmac_quad. If
    -- either of these change then the associated constants must be updated. See c_CACHE_LATENCY and c_QUAD_CMAC_LATENCY.
    P_TDM_FOLLOW : process (i_cmac_clk) is
        variable v_delay_feedback : unsigned(delay_cnt'range);
        variable v_dec : unsigned(delay_cnt'range);
        variable v_delay_cnt_term : std_logic;
    begin
        if rising_edge(i_cmac_clk) then

            -- Update the context into the MTA at the beginning of each TDM lap.
            -- This will reset the MTA to the first baseline.
            v_delay_cnt_term := delay_cnt(delay_cnt'high);  -- terminate count when underflow to -1.
            if tdm_first='1' then
                v_delay_feedback := to_unsigned(c_DELAY_COUNT_INIT-6, delay_cnt'length);
                -- minus 7 above is from
                -- -2 to get to termination value of delay_cnt = -1, i.e. underflow detected.
                -- -3 for pipelining from tdm_first to mta_context(0).tdm_lap_start
                -- -1 for delay count not decrementing on the first cycle.
            else
                v_delay_feedback := delay_cnt;
            end if;
            if v_delay_cnt_term='1' then
                -- stop counting down.
                v_dec := to_unsigned(0, delay_cnt'length);
            else
                -- continue to count down.
                v_dec := to_unsigned(1, delay_cnt'length);
            end if;
            delay_cnt <= v_delay_feedback - v_dec;
            if cmac_clk_reset='1' then
                -- start with down count stopped.
                delay_cnt <= (others => '1');
            end if;

            delay_cnt_prev <= v_delay_cnt_term;
            delay_term <= v_delay_cnt_term and not delay_cnt_prev;
            
            mta_context(0).tdm_lap_start <= '0';
            if delay_term='1' then
                mta_context(0).channel   <= cmac_context.channel;
                mta_context(0).timestamp <= cmac_context.timestamp;
                mta_context(0).tdm_lap   <= cmac_context.tdm_lap;
                mta_context(0).tdm_lap_start <= '1';
            end if;            

            -- Output the context to the LTA when all MTA outputs are finished at the end of a TDM lap.
            if tdm_last='1' then
                tdm_last_delay_cnt <= to_unsigned(c_TDM_LAST_DELAY_COUNT_INIT-3, tdm_last_delay_cnt'length);
            elsif not tdm_last_delay_cnt(tdm_last_delay_cnt'high)='1' then
                tdm_last_delay_cnt <= tdm_last_delay_cnt - 1;
            end if;
            tdm_last_delay_cnt_prev <= tdm_last_delay_cnt(tdm_last_delay_cnt'high);
            tdm_last_delay_term <= tdm_last_delay_cnt(tdm_last_delay_cnt'high) and not tdm_last_delay_cnt_prev;
            if cmac_clk_reset='1' then
                tdm_last_delay_cnt <= (others => '1');
            end if;

            o_mta_context_vld <= '0';
            if tdm_last_delay_term = '1' and mta_context(0).tdm_lap >= g_CMAC_DUMPS_PER_MTA_DUMP-1 then
                o_mta_context <= mta_context(0);  -- FIXME not quite aligned with last mta output. Will be offset by the
                                                -- latency of the MTA and the latency of the E_MTA_LAP_DISTRIBUTE
                                                -- pipline.
                o_mta_context_vld <= '1';
            end if;
            
        end if;
    end process;

end architecture struct;
