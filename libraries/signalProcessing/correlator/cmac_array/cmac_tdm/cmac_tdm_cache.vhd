-------------------------------------------------------------------------------
-- Title      : Systolic Array CMAC Row and Column Driver
-- Project    : 
-------------------------------------------------------------------------------
-- File       : cmac_tdm_cache.vhd
-- Author     : William Kamp  <william.kamp@aut.ac.nz>
-- Company    : High Performance Computing Research Lab, Auckland University of Technology
-- Created    : 2016-08-01
-- Last update: 2018-07-20
-- Platform   : 
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: Drives the input to a row or column of CMACs with appropriate signalling and data duplication and ordering to
-- achieve two polarisation products.
--
-- For each packet of samples:
--      Set I and Q to zero if sample is RFI flagged.
--      Encode I and Q of up to 9 bits each into a single value of up to 27 bit value.
--      Send a burst of samples.
-------------------------------------------------------------------------------
-- Copyright (c) 2016 High Performance Computing Research Lab, Auckland University of Technology
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-08-01  1.0      wkamp   Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.cmac_pkg.all;                  -- to_6bj6b, t_cmac_input_bus, conjugate
use work.cmac_tdm_pkg.all;              -- t_tdm_rd_ctrl, t_tdm_cache_wr_bus

library work;
use work.misc_tools_pkg.all;                  -- ceil_log2

entity cmac_tdm_cache is

    generic (
        g_SAMPLE_WIDTH    : natural range 1 to 9                      := 9;
        g_ANTENNA_PER_COL : natural range 1 to pc_MAX_ANTENNA_PER_COL := 10;   -- g_NUM_ANTENNA/g_COL_DIMENSION
        g_NUM_SAMPLES     : natural range 3 to pc_MAX_NUM_SAMPLES     := 112;  -- number of samples in a sub-accumulation.
                                        -- set for memory efficiency i.e <= 1024/(g_ANTENNA_PER_COL-1).
        g_IS_COLUMN_CACHE : boolean;    -- If true then the samples are to be formatted for a column.
        g_PIPELINE_CYCLES : natural
        );

    port (
        -- Data input interface
        i_cturn_clk       : in std_logic;
        i_cturn_clk_reset : in std_logic;

        i_tdm_cache_wr_bus : in  t_tdm_cache_wr_bus;
        o_wr_stop          : out std_logic := '1';  -- stop at the end of this burst.

        -- Read driver interface
        -- connect to global cmac_tdm_cache_driver module.
        i_cmac_clk       : in std_logic;
        i_cmac_clk_reset : in std_logic;

        i_tdm_rd_ctrl : in  t_tdm_rd_ctrl;
        o_tdm_rd_ctrl : out t_tdm_rd_ctrl;  -- pipeline delayed version of input.

        -- Output to CMAC row or column
        o_cmac_bus : out t_cmac_input_bus_a(0 to 1)
        );

end entity cmac_tdm_cache;

architecture rtl of cmac_tdm_cache is

    constant c_ADDR_WIDTH : natural := 1+ceil_log2(g_NUM_SAMPLES*(g_ANTENNA_PER_COL-1));  -- 1 for bank

    ----------------------------------------------------------------------------------------
    -- i_cturn_clk domain signals.
    ----------------------------------------------------------------------------------------
    signal c1_wr_real_polX : signed(g_SAMPLE_WIDTH-1 downto 0);
    signal c1_wr_imag_polX : signed(g_SAMPLE_WIDTH-1 downto 0);
    signal c1_wr_real_polY : signed(g_SAMPLE_WIDTH-1 downto 0);
    signal c1_wr_imag_polY : signed(g_SAMPLE_WIDTH-1 downto 0);
    signal c1_wr_enable    : std_logic;
    signal c1_wr_addr      : unsigned(c_ADDR_WIDTH-1 downto 0);
    signal c1_rfi          : std_logic;

    signal c2_wr_data   : std_logic_vector(1+4*g_SAMPLE_WIDTH-1 downto 0);
    signal c2_wr_enable : std_logic;
    signal c2_wr_addr   : unsigned(c1_wr_addr'range);

    signal c3_wr_data   : std_logic_vector(1+4*g_SAMPLE_WIDTH-1 downto 0);
    signal c3_wr_enable : std_logic;
    signal c3_wr_addr   : unsigned(c1_wr_addr'range);

    ----------------------------------------------------------------------------------------
    -- i_cmac_clk domain signals.
    ----------------------------------------------------------------------------------------

    signal c0_tdm_rd_ctrl : t_tdm_rd_ctrl;

    signal c2_rd_data_compact : std_logic_vector(c2_wr_data'range);
    signal c3_rd_polX_data    : signed(3*g_SAMPLE_WIDTH-1 downto 0);
    signal c3_rd_polY_data    : signed(3*g_SAMPLE_WIDTH-1 downto 0);
    signal c3_rd_rfi_flag     : std_logic;

    signal c1_cmac_common_bus : t_cmac_input_bus;
    signal c2_cmac_common_bus : t_cmac_input_bus;
    signal c3_cmac_common_bus : t_cmac_input_bus;
    signal c4_cmac_polX_bus   : t_cmac_input_bus;
    signal c4_cmac_polY_bus   : t_cmac_input_bus;

    signal cmac_polX_bus_pipelined_slv : std_logic_vector(T_CMAC_INPUT_BUS_SLV_WIDTH-1 downto 0);
    signal cmac_polY_bus_pipelined_slv : std_logic_vector(T_CMAC_INPUT_BUS_SLV_WIDTH-1 downto 0);
    signal tdm_rd_ctrl_delayed         : std_logic_vector(T_TDM_RD_CTRL_SLV_WIDTH-1 downto 0);
    
    signal cdc_rd_dbl_buf_sel : std_logic;

begin  -- architecture rtl

    -- convert RFI samples (with most negative value) to zero and flag as RFI.
    -- Samples that are ZERO will not add to the accumulation.
    -- CMAC can't handle the most negative value anyway.
    P_RFI_TO_ZERO : process (i_cturn_clk) is
        variable v_wr_bus : t_tdm_cache_wr_bus;
        variable v2_wr_real_polX : signed(g_SAMPLE_WIDTH-1 downto 0);
        variable v2_wr_imag_polX : signed(g_SAMPLE_WIDTH-1 downto 0);
        variable v2_wr_real_polY : signed(g_SAMPLE_WIDTH-1 downto 0);
        variable v2_wr_imag_polY : signed(g_SAMPLE_WIDTH-1 downto 0);
    begin
        if rising_edge(i_cturn_clk) then

            if g_IS_COLUMN_CACHE then
                -- Conjugate the input data.
                -- Whether the conjugate is performed depends on the architecture of the CMAC.
                -- Check the appropriate version of cmac_pkg.vhd.
                v_wr_bus := conjugate(i_tdm_cache_wr_bus, g_SAMPLE_WIDTH);
            else
                v_wr_bus := i_tdm_cache_wr_bus;
            end if;
            c1_wr_real_polX <= v_wr_bus.real_polX(c1_wr_real_polX'range);
            c1_wr_real_polY <= v_wr_bus.real_polY(c1_wr_real_polY'range);
            c1_wr_imag_polX <= v_wr_bus.imag_polX(c1_wr_imag_polX'range);
            c1_wr_imag_polY <= v_wr_bus.imag_polY(c1_wr_imag_polY'range);

            if v_wr_bus.dbl_buf_sel/=cdc_rd_dbl_buf_sel then
                o_wr_stop <= '1';
            else
                o_wr_stop <= '0';
            end if;

            -- Caches on the columns do not need to store the data for the LAST antenna,
            -- so we gate off the write enable for addresses that exceed the RAM depth.
            -- Caches on the rows will not read the data for the FIRST antenna,
            -- so we let the address wrap - overwriting the samples for the first antenna
            -- with the last.
            if g_IS_COLUMN_CACHE and v_wr_bus.wr_addr(c_ADDR_WIDTH-1) = '1' then
                -- gate off write enable for overflowing address.
                c1_wr_enable <= '0';
            else
                c1_wr_enable <= v_wr_bus.wr_enable;
            end if;
            c1_wr_addr   <= v_wr_bus.dbl_buf_sel & v_wr_bus.wr_addr(c_ADDR_WIDTH-2 downto 0);

            -- If most negative number then is RFI. 
            if to_01(v_wr_bus.real_polX(g_SAMPLE_WIDTH-1 downto 0)) = -2**(g_SAMPLE_WIDTH-1) then
                c1_rfi <= '1';
            else
                c1_rfi <= '0';
            end if;

            if c1_rfi='1' then
                -- If any of the samples are marked as RFI (most negative number) then set both polarisation's samples to zero, and flag as RFI
                -- in the highest bit.
                v2_wr_real_polX := to_signed(0, c1_wr_real_polX'length);
                v2_wr_imag_polX := to_signed(0, c1_wr_imag_polX'length);
                v2_wr_real_polY := to_signed(0, c1_wr_real_polY'length);
                v2_wr_imag_polY := to_signed(0, c1_wr_imag_polY'length);
            else
                v2_wr_real_polX := c1_wr_real_polX;
                v2_wr_imag_polX := c1_wr_imag_polX;
                v2_wr_real_polY := c1_wr_real_polY;
                v2_wr_imag_polY := c1_wr_imag_polY;
            end if;
            -- Pack into the RAM.
            -- Apparently the synthesiser will NOT merge the identical bits
            -- (g_SAMPLE_WIDTH bits between the real and imagnary part, to save block RAM.  
            -- So we do it manually, doing the addition in the slower clock domain, and
            -- expanding/replicating the identical bits in the faster i_cmac_clk domain.
            c2_wr_data <= c1_rfi &
                          std_logic_vector(to_6bj6b_add(v2_wr_real_polX,
                                                        v2_wr_imag_polX,
                                                        g_SAMPLE_WIDTH)) &
                          std_logic_vector(to_6bj6b_add(v2_wr_real_polY,
                                                        v2_wr_imag_polY,
                                                        g_SAMPLE_WIDTH));           
            c2_wr_enable <= c1_wr_enable;
            c2_wr_addr   <= c1_wr_addr;

            -- Flop for timing
            c3_wr_data   <= c2_wr_data;
            c3_wr_enable <= c2_wr_enable;
            c3_wr_addr   <= c2_wr_addr;
        end if;
    end process;

    E_CDC_RD_DBL_BUF_SEL: entity work.synchroniser 
    generic map (
        g_SYNCHRONISER_FLOPS => 2
    ) port map (
        i_bit    => c0_tdm_rd_ctrl.dbl_buf_sel,
        i_clk    => i_cturn_clk,
        o_bit_rt => cdc_rd_dbl_buf_sel
    );    


    -- This RAM stores the samples to be correlated, in one iteration of the TDM.
    -- It is read multiple times to achieve time-division multiplexing of the CMAC array.
    -- Currently it is double buffered, but this is not strictly necessary the antennas
    -- can be retired in order as the TDM progresses.
    -- Data is stored by antenna,
    -- Antenna 0 in the address range 0 to g_NUM_SAMPLES-1.
    -- Antenna 1 in the address range g_NUM_SAMPLES to 2*g_NUM_SAMPLES-1.
    -- and so on.
    -- The RAM also crosses the samples into the faster CMAC clock domain. 
    E_CDC_CACHE : entity work.dual_clock_simple_dual_port_ram
        generic map (
            g_REG_OUTPUT => true)
        port map (
            i_wr_clk       => i_cturn_clk,        -- [std_logic]
            i_wr_clk_reset => i_cturn_clk_reset,  -- [std_logic]
            i_wr_addr      => c3_wr_addr,         -- [unsigned]
            i_wr_en        => c3_wr_enable,       -- [std_logic]
            i_wr_data      => c3_wr_data,         -- [std_logic_vector]

            i_rd_clk       => i_cmac_clk,                -- [std_logic]
            i_rd_clk_reset => i_cmac_clk_reset,          -- [std_logic]
            i_rd_addr      => c0_tdm_rd_ctrl.dbl_buf_sel & c0_tdm_rd_ctrl.rd_addr(c_ADDR_WIDTH-2 downto 0),  -- [unsigned]
            i_rd_en        => c0_tdm_rd_ctrl.rd_enable,  -- [std_logic]
            o_rd_data      => c2_rd_data_compact);       -- [std_logic_vector]

    P_TIMING_FLOP : process (i_cmac_clk) is
    begin
        if rising_edge(i_cmac_clk) then
            c3_rd_polY_data <= to_6bj6b_expand(signed(c2_rd_data_compact(2*g_SAMPLE_WIDTH-1 downto 0*g_SAMPLE_WIDTH)));
            c3_rd_polX_data <= to_6bj6b_expand(signed(c2_rd_data_compact(4*g_SAMPLE_WIDTH-1 downto 2*g_SAMPLE_WIDTH)));
            c3_rd_rfi_flag  <= c2_rd_data_compact(c2_rd_data_compact'high);
        end if;
    end process;

    P_OUTPUT : process (i_cmac_clk) is
    begin
        if rising_edge(i_cmac_clk) then
            c0_tdm_rd_ctrl <= i_tdm_rd_ctrl;  -- flop for timing.

            c1_cmac_common_bus.vld        <= c0_tdm_rd_ctrl.rd_enable;
            c1_cmac_common_bus.last       <= c0_tdm_rd_ctrl.sample_last;
            -- calculate first, for the next burst using a feedback of last and vld.
            if i_cmac_clk_reset='1' then
                c1_cmac_common_bus.first  <= '1';
            elsif c1_cmac_common_bus.last='1' then
                c1_cmac_common_bus.first  <= '1';
            elsif c1_cmac_common_bus.vld='1' then
                c1_cmac_common_bus.first  <= '0';
            end if;
            c1_cmac_common_bus.auto_corr  <= c0_tdm_rd_ctrl.auto_corr;
            c1_cmac_common_bus.sample_cnt <= resize(c0_tdm_rd_ctrl.sample_cnt, c2_cmac_common_bus.sample_cnt'length);

            c2_cmac_common_bus <= c1_cmac_common_bus;
            c3_cmac_common_bus <= c2_cmac_common_bus;
            c4_cmac_polX_bus   <= c3_cmac_common_bus;
            c4_cmac_polY_bus   <= c3_cmac_common_bus;

            c4_cmac_polX_bus.data <= resize(c3_rd_polX_data, c4_cmac_polX_bus.data'length);

            c4_cmac_polY_bus.data <= resize(c3_rd_polY_data, c4_cmac_polY_bus.data'length);

            c4_cmac_polX_bus.rfi <= c3_rd_rfi_flag;
            c4_cmac_polY_bus.rfi <= c3_rd_rfi_flag;

        end if;
    end process;

    -- No delay here (unless some needed for timing). Entity here to be consistent with Y polarisation.
    E_OUT_POLX_PIPELINE : entity work.pipeline_delay
        generic map (
            g_CYCLES_DELAY => 0)                        -- [natural]
        port map (
            i_clk      => i_cmac_clk,                   -- [std_logic]
            i_bus      => to_slv(c4_cmac_polX_bus),     -- [std_logic_vector]
            o_bus_stop => open,                         -- [std_logic]
            o_bus      => cmac_polX_bus_pipelined_slv,  -- [std_logic_vector]
            i_bus_stop => '0');                         -- [std_logic]
    o_cmac_bus(0) <= from_slv(cmac_polX_bus_pipelined_slv);

    -- Quad CMAC wants the Y polarisation one cycle later.
    E_OUT_POLY_PIPELINE : entity work.pipeline_delay
        generic map (
            g_CYCLES_DELAY => 1)        -- [natural]
        port map (
            i_clk      => i_cmac_clk,                   -- [std_logic]
            i_bus      => to_slv(c4_cmac_polY_bus),     -- [std_logic_vector]
            o_bus_stop => open,                         -- [std_logic]
            o_bus      => cmac_polY_bus_pipelined_slv,  -- [std_logic_vector]
            i_bus_stop => '0');                         -- [std_logic]
    o_cmac_bus(1) <= from_slv(cmac_polY_bus_pipelined_slv);

    -- Pass control to the next cache with a g_PIPELINE_CYCLES delay so that its
    -- samples enter the CMAC array at the appropriate time.
    E_ROW_DELAY : entity work.pipeline_delay
        generic map (
            g_CYCLES_DELAY => g_PIPELINE_CYCLES)  -- [natural]
        port map (
            i_clk      => i_cmac_clk,             -- [std_logic]
            i_bus      => to_slv(i_tdm_rd_ctrl),  -- [std_logic_vector]
            o_bus_stop => open,                   -- [std_logic]
            o_bus      => tdm_rd_ctrl_delayed,    -- [std_logic_vector]
            i_bus_stop => '0');                   -- [std_logic]
    o_tdm_rd_ctrl <= from_slv(tdm_rd_ctrl_delayed);

end architecture rtl;
