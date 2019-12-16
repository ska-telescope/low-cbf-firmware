-------------------------------------------------------------------------------
-- Title      : Quad CMAC to generate 4 polarisation products
-- Project    : 
-------------------------------------------------------------------------------
-- File       : cmac_quad.vhd
-- Author     : William Kamp  <william.kamp@aut.ac.nz>
-- Company    : High Performance Computing Research Lab, Auckland University of Technology
-- Created    : 2017-08-01
-- Last update: 2018-06-29
-- Platform   : 
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description:
-- Computes the 4 polarisation products in parallel,
-- outputting them serially onto the readout bus with the
-- Time-centroid index and Data valid count first, followed by YY, XY, YX, XX.
--
-- If the quad cmac is on the diagonal, then it can compute two auto correlations at the same time,
-- using 6 CMACs, and two RFI counters for TCI. It outputs the 4 polarisation products for each,
-- where the cross polarisation products are the complex conjugates of each other.
-- CMAC resources are instanciated when g_AUTOCORRELATION_CMAC = true, and dynamically enabled by i_col(x).auto_corr.
-- g_READOUT_DELAY is tuned for each CMAC so that all their o_readout_vld goes high at the same time.
-- This loads the readout bus at the same time, so that it can be shifted out.
-------------------------------------------------------------------------------
-- Copyright (c) 2017 High Performance Computing Research Lab, Auckland University of Technology
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-08-01  1.0      will    Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.cmac_pkg.all;

entity cmac_quad is

    generic (
        g_AUTOCORRELATION_CMAC : boolean := false;
        g_MAX_ACCUM_SAMPLES    : natural;
        g_SAMPLE_WIDTH         : natural range 1 to 9;  --  >6 uses two multiplers per cmac.
        g_QUAD_CMAC_LATENCY    : natural;  -- measure in simulator from rising_edge(i_col.last) to
                                           -- rising_edge(o_readout_vld) in cycles.
        g_USE_SCAN_IN          : boolean := false;
        g_PIPELINE_CYCLES      : natural range 1 to 16
        );
    port (
        i_clk       : in std_logic;
        i_clk_reset : in std_logic;

        i_row : in t_cmac_input_bus_a(0 to 1);  -- dual polarisations
        i_col : in t_cmac_input_bus_a(0 to 1);  -- dual polarisations

        i_scan_polX : in  signed(3*g_SAMPLE_WIDTH-1 downto 0) := (others => '-');
        o_scan_polX : out signed(3*g_SAMPLE_WIDTH-1 downto 0);
        i_scan_polY : in  signed(3*g_SAMPLE_WIDTH-1 downto 0) := (others => '-');
        o_scan_polY : out signed(3*g_SAMPLE_WIDTH-1 downto 0);

        o_row : out t_cmac_input_bus_a(0 to 1);  -- dual polarisations
        o_col : out t_cmac_input_bus_a(0 to 1);  -- dual polarisations

        -- Readout interface. Basically a big sideloaded shift register.
        -- Loaded by i_<col|row>.last
        i_readout_vld  : in  std_logic := '0';
        i_readout_data : in  std_logic_vector;
        o_readout_vld  : out std_logic;
         o_readout_data : out std_logic_vector);

end entity cmac_quad;

architecture rtl of cmac_quad is

    constant c_CMAC_LATENCY : natural := g_QUAD_CMAC_LATENCY - g_PIPELINE_CYCLES;    

    constant polX : natural := 0;
    constant polY : natural := 1;

    signal rowX   : t_cmac_input_bus_a(0 to 1);
    signal colX   : t_cmac_input_bus_a(0 to 1);
    signal rowY   : t_cmac_input_bus_a(0 to 1);
    signal colY   : t_cmac_input_bus_a(0 to 1);

    signal rowX_turn0 : t_cmac_input_bus;
    signal rowY_turn0 : t_cmac_input_bus;
    signal colX_turn  : t_cmac_input_bus;
    signal row_to_XX : t_cmac_input_bus;
    
    signal autoX0 : t_cmac_input_bus;
    signal autoX0_conj : t_cmac_input_bus;
    signal autoY1 : t_cmac_input_bus;

    signal autoY1_conj : t_cmac_input_bus;
    signal autoY0_conj  : t_cmac_input_bus;

    signal colY_out: t_cmac_input_bus;
    signal slv_rowX : std_logic_vector(T_CMAC_INPUT_BUS_SLV_WIDTH-1 downto 0);
    signal slv_rowY : std_logic_vector(T_CMAC_INPUT_BUS_SLV_WIDTH-1 downto 0);
    signal slv_colX : std_logic_vector(T_CMAC_INPUT_BUS_SLV_WIDTH-1 downto 0);
    signal slv_colY : std_logic_vector(T_CMAC_INPUT_BUS_SLV_WIDTH-1 downto 0);

    signal rowY_out : t_cmac_input_bus;
    signal rowX_out : t_cmac_input_bus;

    -- Readout interface. Basically a big sideloaded shift register.
    -- Loaded by i_<col|row>.last
    signal readout_XX_vld    : std_logic;
    signal readout_XX_data   : std_logic_vector(i_readout_data'length/2-1 downto 0);
    signal readout_XY_vld    : std_logic;
    signal readout_XY_data   : std_logic_vector(readout_XX_data'range);
    signal readout_YX_vld    : std_logic;
    signal readout_YX_data   : std_logic_vector(readout_XX_data'range);
    signal readout_YY_vld    : std_logic;
    signal readout_YY_data   : std_logic_vector(readout_XX_data'range);
    signal readout_AX_vld    : std_logic;
    signal readout_AX_data   : std_logic_vector(readout_XX_data'range);
    signal readout_AY_vld    : std_logic;
    signal readout_AY_data   : std_logic_vector(readout_XX_data'range);
    signal readout_A_RFI_vld   : std_logic;
    signal readout_A_RFI_data  : std_logic_vector(readout_XX_data'range);
    signal readout_RFI_vld   : std_logic;
    signal readout_RFI_data  : std_logic_vector(readout_XX_data'range);
    signal readout_pipe_vld  : std_logic;
    signal readout_pipe_data : std_logic_vector(i_readout_data'range);

    function f_XX_delay_hack (
        constant auto : boolean)
        return natural is
    begin  -- function f_XX_delay_hack
        if auto then
            return 1;
        else
            return 2;
        end if;
    end function f_XX_delay_hack;

    signal scan_out_XX : signed(3*g_SAMPLE_WIDTH-1 downto 0) := (others => '0');
    signal scan_out_XY : signed(3*g_SAMPLE_WIDTH-1 downto 0) := (others => '0');
    
    
begin  -- architecture rtl

    P_AUTO_CORR_MUX : process (i_clk) is
        variable v_muxed_row : t_cmac_input_bus;
        variable v_muxed_col : t_cmac_input_bus;
        variable v_do_conj : std_logic;
    begin
        if rising_edge(i_clk) then
            -- INPUT
            colY(0)    <= i_col(polY);
            rowX(0)    <= i_row(polX);
            rowY(0)    <= i_row(polY);
                        
            if g_AUTOCORRELATION_CMAC then
                -- We turn rows into columns and columns into rows when in auto-correlation mode.
                colX_turn <= f_turn_row_to_column(i_col(polX), i_row(polX), g_SAMPLE_WIDTH);
                colX(0) <= colX_turn;   -- extra flop here for DSP input pipeline. Latency introduced removed from
                                        -- CMAC_XX readout latency.
                row_to_XX <= rowX(0);
                colX(1) <= colX_turn;

                autoX0     <= i_col(polX);
                autoX0_conj <= conjugate(i_col(polX), g_SAMPLE_WIDTH);

                rowY_turn0 <= f_turn_column_to_row(i_col(polY), i_row(polY), g_SAMPLE_WIDTH);
                rowY(1) <= rowY_turn0;
                rowX_turn0 <= f_turn_column_to_row(i_col(polX), i_row(polX), g_SAMPLE_WIDTH);
                rowX(1) <= rowX_turn0;
                
                rowY_out <= f_turn_column_to_row(colY(0), rowY(0), g_SAMPLE_WIDTH);                
                rowX_out <= f_turn_column_to_row(autoX0, rowX(0), g_SAMPLE_WIDTH);
                colY_out <= f_turn_row_to_column(colY(0), rowY(0), g_SAMPLE_WIDTH);

                -- Take the control signals from the col so that they can be optimised away on the rows.
                autoY1      <= colY(0);       -- control signals
                autoY1.data <= rowY(0).data;  -- data
                autoY1.rfi  <= rowY(0).rfi;   -- rfi
                autoY0_conj <= conjugate(i_row(polY), g_SAMPLE_WIDTH);
                autoY1_conj      <= colY(0); -- control signals
                autoY1_conj.data <= autoY0_conj.data;  -- data
                autoY1_conj.rfi  <= autoY0_conj.rfi;  -- rfi
            else
                colX(0) <= i_col(polX);                
                colX(1)     <= colX(0);
                rowY(1) <= rowY(0);
                rowX(1) <= rowX(0);
                rowY_out <= rowY(0);
                rowX_out <= rowX(0);
                colY_out <= colY(0);
                row_to_XX <= i_row(polX);
            end if;

            -- INTERNAL          
            colY(1)     <= colY(0);

        end if;
    end process P_AUTO_CORR_MUX;

    -- ===========================================================
    -- LAYOUT: g_AUTOCORRELATION_CMAC = false;
    -- ===========================================================
    --              i_col(0)=X                       i_col(1)=Y  |
    --                   |                              |        |
    --                   V                              V        |
    --               colX(0)                         colY(0)     |
    -- i_row(0)=X -> E_CMAC_XX -----rowX(1)--------> E_CMAC_XY -> o_row(polX)
    --                   | (R0)                         | (R2)   |
    --               colX(1)                          colY(1)    |
    -- P_PIPE_IN         |                              |        |
    --                   V                              V        |
    -- i_row(1)=Y -> E_CMAC_YX -----rowY(1)--------> E_CMAC_YY -> o_row(polY)
    --                   | (R1)                         | (R3)   |
    -- P_PIPE_OUT        V                              V        |
    --                o_col(polX)                    o_col(polY) |
    -- ===========================================================

    -- ===========================================================
    -- LAYOUT: g_AUTOCORRELATION_CMAC = true AND i_col.auto_corr = '0';
    -- ===========================================================
    --                  i_col(0)=X                   i_col(1)=Y  |
    --               colX(0) |   autoX1                 |        |
    --                   |-------------|                V        |
    --                   v             |              colY(0)    |
    -- i_row(0)=X -> E_CMAC_XX         V  -rowX(1)-> E_CMAC_XY -> o_row(polX)
    --                   | (R0)   E_CMAC_AUTO_X         | (R2)   |
    --                   |                              |        |
    -- P_PIPE_IN         V                              V        |
    --               colX(1)     autoY1      rowY(1)   colY(1)   |
    -- i_row(1)=Y -> E_CMAC_YX --------v-----------> E_CMAC_YY -> o_row(polY)
    --                   | (R1)  E_CMAC_AUTO_Y          | (R3)   |
    --                   |                              |        |
    -- P_PIPE_OUT        V                              V        |
    --                o_col(polX)                    o_col(polY) |
    -- ===========================================================

    -- ===========================================================
    -- LAYOUT: g_AUTOCORRELATION_CMAC = true AND i_col.auto_corr = '1';
    -- ===========================================================
    --                             i_col(0)=X        i_col(1)=Y  |
    --               colX(0)     autoX1|                |        |
    --            /``````|             |-----rowX(1)    V        |
    --            |      v             |         |   colY(0)     |
    -- i_row(0)=X -> E_CMAC_XX         V         \-> E_CMAC_XY -> o_row(polX)
    --                   | (R0)   E_CMAC_AUTO_X         | (R5=R6*)
    --                   |                  (R4)  ______| (R6)   |
    -- P_PIPE_IN         V                       /      V        |
    --               colX(1)     autoY1      rowY(1)   colY(1)   |
    -- i_row(1)=Y -> E_CMAC_YX --------v         \-> E_CMAC_YY -> o_row(polY)
    --                   | (R1)  E_CMAC_AUTO_Y            (R7)   |
    --                   | (R2=R1*)    |   (R3)                  |
    -- P_PIPE_OUT        V             V                         |
    --                o_col(polX)   o_col(polY)                  |
    -- ===========================================================

    
    E_CMAC_RFI_ROW : entity work.cmac_rfi
        generic map (
            g_MAX_ACCUM_SAMPLES => g_MAX_ACCUM_SAMPLES,  -- [natural]
            g_CMAC_LATENCY      => c_CMAC_LATENCY,       -- [natural]
            g_READOUT_DELAY     => 0)                    -- [natural]
        port map (
            i_clk       => i_clk,                        -- [std_logic]
            i_clk_reset => i_clk_reset,                  -- [std_logic]

            i_row => row_to_XX,           -- [t_cmac_input_bus]
            i_col => colX(0),           -- [t_cmac_input_bus]

            -- Readout interface. Basically a big sideloaded shift register.
            -- Loaded by i_<col|row>.last
            i_readout_vld  => readout_YY_vld,      -- [std_logic := '0']
            i_readout_data => readout_YY_data,     -- [std_logic_vector]
            o_readout_vld  => readout_RFI_vld,    -- [std_logic]
            o_readout_data => readout_RFI_data);  -- [std_logic_vector]
    
    -- Pol X * Pol X
    E_CMAC_XX : entity work.cmac
        generic map (
            g_MAX_ACCUM_SAMPLES => g_MAX_ACCUM_SAMPLES,  -- [natural]
            g_SAMPLE_WIDTH      => g_SAMPLE_WIDTH,       -- [natural range 1 to 9]  >  6 uses two multiplers
            g_USE_SCAN_IN       => g_USE_SCAN_IN,        -- [boolean]
            g_CMAC_LATENCY     => c_CMAC_LATENCY)

        port map (
            i_clk       => i_clk,        -- [std_logic]
            i_clk_reset => i_clk_reset,  -- [std_logic]

            i_row => row_to_XX,           -- [t_cmac_input_bus]
            i_col => colX(0),           -- [t_cmac_input_bus]

            i_scan => i_scan_polX,
            o_scan => scan_out_XX,

            -- Readout interface. Basically a big sideloaded shift register.
            -- Loaded by i_<col|row>.last
            i_readout_vld  => '0',     -- [std_logic := '0']
            i_readout_data => readout_XX_data,    -- [std_logic_vector]
            o_readout_vld  => readout_XX_vld,    -- [std_logic]
            o_readout_data => readout_XX_data);  -- [std_logic_vector]


    -- Pol Y * Pol X
    E_CMAC_YX : entity work.cmac
        generic map (
            g_MAX_ACCUM_SAMPLES       => g_MAX_ACCUM_SAMPLES,  -- [natural]
            g_SAMPLE_WIDTH            => g_SAMPLE_WIDTH,       -- [natural range 1 to 9]  >  6 uses two multiplers
            g_USE_SCAN_IN            => not g_AUTOCORRELATION_CMAC,        -- [boolean]
            g_CMAC_LATENCY           => c_CMAC_LATENCY)
        port map (
            i_clk       => i_clk,                              -- [std_logic]
            i_clk_reset => i_clk_reset,                        -- [std_logic]

            i_row => rowY(0),           -- [t_cmac_input_bus]
            i_col => colX(1),           -- [t_cmac_input_bus]

            i_scan => scan_out_XX,
            o_scan => o_scan_polX,

            -- Readout interface. Basically a big sideloaded shift register.
            -- Loaded by i_<col|row>.last
            i_readout_vld  => readout_XX_vld,    -- [std_logic := '0']
            i_readout_data => readout_XX_data,   -- [std_logic_vector]
            o_readout_vld  => readout_YX_vld,    -- [std_logic]
            o_readout_data => readout_YX_data);  -- [std_logic_vector]

    G_AUTO : if g_AUTOCORRELATION_CMAC generate
        signal autoX1 : t_cmac_input_bus;
        signal autoX1_conj : t_cmac_input_bus;
    begin

        P_DSP_FLOP : process (i_clk) is
        begin
            if rising_edge(i_clk) then
                autoX1 <= autoX0;
                autoX1_conj <= autoX0_conj;
            end if;
        end process;
        
        -- Pol X * Pol X
        E_CMAC_AUTO_X : entity work.cmac
            generic map (
                g_MAX_ACCUM_SAMPLES           => g_MAX_ACCUM_SAMPLES,  -- [natural]
                g_SAMPLE_WIDTH                => g_SAMPLE_WIDTH,  -- [natural range 1 to 9]  >  6 uses two multiplers
                g_READOUT_ONLY_WHEN_AUTO_MODE => true,
                g_USE_SCAN_IN                 => false,        -- [boolean]
                g_CMAC_LATENCY                => c_CMAC_LATENCY)

            port map (
                i_clk       => i_clk,        -- [std_logic]
                i_clk_reset => i_clk_reset,  -- [std_logic]

                i_row => autoX1,        -- [t_cmac_input_bus]
                i_col => autoX1_conj,   -- [t_cmac_input_bus]

                -- Readout interface. Basically a big sideloaded shift register.
                -- Loaded by i_<col|row>.last
                i_readout_vld  => readout_A_RFI_vld,   -- [std_logic := '0']
                i_readout_data => readout_A_RFI_data,  -- [std_logic_vector]
                o_readout_vld  => readout_AX_vld,    -- [std_logic]
                o_readout_data => readout_AX_data);  -- [std_logic_vector]

        E_CMAC_RFI_AUTO : entity work.cmac_rfi
            generic map (
                g_MAX_ACCUM_SAMPLES           => g_MAX_ACCUM_SAMPLES,  -- [natural]
                g_READOUT_ONLY_WHEN_AUTO_MODE => true,                 -- [boolean]
                g_CMAC_LATENCY                => c_CMAC_LATENCY,       -- [natural]
                g_READOUT_DELAY               => 0)                    -- [natural]
            port map (
                i_clk       => i_clk,                                  -- [std_logic]
                i_clk_reset => i_clk_reset,                            -- [std_logic]

                i_row => autoX1,        -- [t_cmac_input_bus]
                i_col => autoX1_conj,   -- [t_cmac_input_bus]

                -- Readout interface. Basically a big sideloaded shift register.
                -- Loaded by i_<col|row>.last
                i_readout_vld  => readout_AY_vld,     -- [std_logic := '0']
                i_readout_data => readout_AY_data,    -- [std_logic_vector]
                o_readout_vld  => readout_A_RFI_vld,    -- [std_logic]
                o_readout_data => readout_A_RFI_data);  -- [std_logic_vector]

        -- Pol Y * Pol Y
        E_CMAC_AUTO_Y : entity work.cmac
            generic map (
                g_MAX_ACCUM_SAMPLES           => g_MAX_ACCUM_SAMPLES,  -- [natural]
                g_SAMPLE_WIDTH                => g_SAMPLE_WIDTH,  -- [natural range 1 to 9]  >  6 uses two multiplers
                g_READOUT_ONLY_WHEN_AUTO_MODE => true,
                g_CMAC_LATENCY               => c_CMAC_LATENCY)
            port map (
                i_clk       => i_clk,   -- [std_logic]
                i_clk_reset => i_clk_reset,                       -- [std_logic]

                i_row => autoY1,        -- [t_cmac_input_bus]
                i_col => autoY1_conj,   -- [t_cmac_input_bus]

                -- Readout interface. Basically a big sideloaded shift register.
                -- Loaded by i_<col|row>.last
                i_readout_vld  => readout_YX_vld,    -- [std_logic := '0']
                i_readout_data => readout_YX_data,   -- [std_logic_vector]
                o_readout_vld  => readout_AY_vld,    -- [std_logic]
                o_readout_data => readout_AY_data);  -- [std_logic_vector]

    else generate

        readout_AX_vld  <= readout_YX_vld;
        readout_AX_data <= readout_YX_data;

    end generate G_AUTO;

    -- Pol X * Pol Y
    E_CMAC_XY : entity work.cmac
        generic map (
            g_MAX_ACCUM_SAMPLES        => g_MAX_ACCUM_SAMPLES,  -- [natural]
            g_SAMPLE_WIDTH             => g_SAMPLE_WIDTH,       -- [natural range 1 to 9]  >  6 uses two multiplers
            g_USE_SCAN_IN              => g_USE_SCAN_IN,
            g_CMAC_LATENCY             => c_CMAC_LATENCY)
        port map (
            i_clk       => i_clk,                               -- [std_logic]
            i_clk_reset => i_clk_reset,                         -- [std_logic]

            i_row => rowX(1),           -- [t_cmac_input_bus]
            i_col => colY(0),           -- [t_cmac_input_bus]
            i_scan => i_scan_polY,
            o_scan => scan_out_XY,
            -- Readout interface. Basically a big sideloaded shift register.
            -- Loaded by i_<col|row>.last
            i_readout_vld  => readout_AX_vld,    -- [std_logic := '0']
            i_readout_data => readout_AX_data,   -- [std_logic_vector]
            o_readout_vld  => readout_XY_vld,    -- [std_logic]
            o_readout_data => readout_XY_data);  -- [std_logic_vector]


    -- Pol Y * Pol Y
    E_CMAC_YY : entity work.cmac
        generic map (
            g_MAX_ACCUM_SAMPLES => g_MAX_ACCUM_SAMPLES,  -- [natural]
            g_SAMPLE_WIDTH      => g_SAMPLE_WIDTH,       -- [natural range 1 to 9]  >  6 uses two multiplers
            g_USE_SCAN_IN       => true,
            g_CMAC_LATENCY      => c_CMAC_LATENCY)
        port map (
            i_clk       => i_clk,                        -- [std_logic]
            i_clk_reset => i_clk_reset,                  -- [std_logic]

            i_row => rowY(1),           -- [t_cmac_input_bus]
            i_col => colY(1),           -- [t_cmac_input_bus]
            i_scan => scan_out_XY,
            o_scan => o_scan_polY,
            -- Readout interface. Basically a big sideloaded shift register.
            -- Loaded by i_<col|row>.last
            i_readout_vld  => readout_XY_vld,    -- [std_logic := '0']
            i_readout_data => readout_XY_data,   -- [std_logic_vector]
            o_readout_vld  => readout_YY_vld,    -- [std_logic]
            o_readout_data => readout_YY_data);  -- [std_logic_vector]




    --------------------------------------------------------------------------------------------------------------------
    -- Readout Data Frame
    --------------------------------------------------------------------------------------------------------------------
    -- 3 cycles to output data frame. Outputs of CMACs are muxed together with their natural relative latency.
    -- Latency
    -- 0 : CMAC_XX | RFI
    -- 1 : CMAC_XY | CMAC_YX
    -- 2 : CMAC_YY | null
    G_AUTO_READOUT : if g_AUTOCORRELATION_CMAC generate
        signal delayed_readout_XY_vld    : std_logic;
        signal delayed_readout_XY_data   : std_logic_vector(readout_XX_data'range);
        signal delayed_readout_YX_vld    : std_logic;
        signal delayed_readout_YX_data   : std_logic_vector(readout_XX_data'range);
        signal delayed_readout_YY_vld    : std_logic;
        signal delayed_readout_YY_data   : std_logic_vector(readout_XX_data'range);
        signal delayed_readout_AY_vld    : std_logic;
        signal delayed_readout_AY_data   : std_logic_vector(readout_XX_data'range);
        signal delayed_readout_RFI_vld   : std_logic;
        signal delayed_readout_RFI_data  : std_logic_vector(readout_XX_data'range);

        signal readout_in_data : std_logic_vector(readout_pipe_data'range);
        signal readout_in_vld : std_logic;
        
        signal readout_auto_data : std_logic_vector(readout_pipe_data'range);
        signal readout_auto_vld : std_logic;
        signal readout_auto_pipe_data : std_logic_vector(readout_pipe_data'range);
        signal readout_auto_pipe_vld : std_logic;
        signal auto_mode : std_logic;
    begin

        P_DELAY_READOUT : process (i_clk) is
        begin  
            if rising_edge(i_clk) then
                -- XX and AX and A_RFI data is already delayed by one - to full register the DSP input.
                -- delay others to match.
                delayed_readout_XY_data <= readout_XY_data;
                delayed_readout_XY_vld <= readout_XY_vld;
                delayed_readout_YX_data <= readout_YX_data;
                delayed_readout_YX_vld <= readout_YX_vld;
                delayed_readout_YY_data <= readout_YY_data;
                delayed_readout_YY_vld <= readout_YY_vld;
                delayed_readout_AY_data <= readout_AY_data;
                delayed_readout_AY_vld <= readout_AY_vld;
                --delayed_readout_RFI_data <= readout_RFI_data;
                --delayed_readout_RFI_vld <= readout_RFI_vld;
                readout_in_data <= i_readout_data;
                readout_in_vld <= i_readout_vld;
                if coly(1).last='1' then
                    auto_mode <= coly(1).auto_corr;
                end if;
            end if;
        end process;

        -- This out second.
        readout_auto_data(readout_auto_data'high downto readout_auto_data'length/2) <=
            readout_RFI_data
            or (delayed_readout_XY_data and not auto_mode)
            or (delayed_readout_YY_data and not auto_mode)
            or delayed_readout_AY_data
            or readout_in_data(readout_auto_data'high downto readout_auto_data'length/2);

        readout_auto_data(readout_auto_data'length/2-1 downto 0)          <=
            readout_XX_data
            or delayed_readout_YX_data
            or readout_in_data(readout_auto_data'length/2-1 downto 0);
        
        readout_auto_vld <= readout_XX_vld or
                            delayed_readout_YX_vld or
                            delayed_readout_AY_vld or
                            (delayed_readout_YY_vld and not auto_mode) or
                            readout_in_vld;

        E_AUTO_READOUT : entity work.pipeline_delay
            generic map (
                g_CYCLES_DELAY => 3)  -- [natural]
            port map (
                i_clk     => i_clk,                   -- [std_logic]
                i_bus     => readout_auto_data,       -- [std_logic_vector]
                i_bus_vld => readout_auto_vld,        -- [std_logic]
                o_bus     => readout_auto_pipe_data,          -- [std_logic_vector]
                o_bus_vld => readout_auto_pipe_vld            -- [std_logic]
                );

        -- This out first.
        readout_pipe_data(readout_pipe_data'high downto readout_pipe_data'length/2) <=
            readout_A_RFI_data
            or (delayed_readout_XY_data and auto_mode)
            or (delayed_readout_YY_data and auto_mode)
            or readout_auto_pipe_data(readout_auto_pipe_data'high downto readout_auto_pipe_data'length/2);
        
        readout_pipe_data(readout_pipe_data'length/2-1 downto 0) <=
            readout_AX_data
            or (readout_YX_data'range => '0')  -- or conjugate
            or readout_auto_pipe_data(readout_auto_pipe_data'length/2-1 downto 0);
        
        readout_pipe_vld <= readout_AX_vld or ((delayed_readout_YX_vld or delayed_readout_YY_vld) and auto_mode) or readout_auto_pipe_vld;

    else generate
             readout_pipe_data(readout_pipe_data'high downto readout_pipe_data'length/2) <=
                 readout_RFI_data
                 or readout_XY_data
                 or readout_YY_data
                 or i_readout_data(readout_pipe_data'high downto readout_pipe_data'length/2);

             readout_pipe_data(readout_pipe_data'length/2-1 downto 0)          <=
                 readout_XX_data
                 or readout_YX_data
                 or i_readout_data(readout_pipe_data'length/2-1 downto 0);

             readout_pipe_vld <= readout_XX_vld or readout_XY_vld or readout_YY_vld or i_readout_vld;
    end generate G_AUTO_READOUT;


    -----------------------------------------------------------------------------------------
    -- Add delay for any additional pipeline cycles. One cycle used in P_AUTO_CORR_MUX.

    E_PIPE_ROWX : entity work.pipeline_delay
        generic map (
            g_CYCLES_DELAY => g_PIPELINE_CYCLES-2)  -- [natural]
        port map (
            i_clk => i_clk,                         -- [std_logic]
            i_bus => to_slv(rowX_out),              -- [std_logic_vector]
            o_bus => slv_rowX                       -- [std_logic_vector]
            );
    o_row(polX) <= from_slv(slv_rowX);

    E_PIPE_ROWY : entity work.pipeline_delay
        generic map (
            g_CYCLES_DELAY => g_PIPELINE_CYCLES-2)  -- [natural]
        port map (
            i_clk => i_clk,                         -- [std_logic]
            i_bus => to_slv(rowY_out),              -- [std_logic_vector]
            o_bus => slv_rowY                       -- [std_logic_vector]
            );
    o_row(polY) <= from_slv(slv_rowY);

    E_PIPE_COLX : entity work.pipeline_delay
        generic map (
            g_CYCLES_DELAY => g_PIPELINE_CYCLES-2)  -- [natural]
        port map (
            i_clk => i_clk,                         -- [std_logic]
            i_bus => to_slv(colX(1)),               -- [std_logic_vector]
            o_bus => slv_colX                       -- [std_logic_vector]
            );
    o_col(polX) <= from_slv(slv_colX);

    E_PIPE_COLY : entity work.pipeline_delay
        generic map (
            g_CYCLES_DELAY => g_PIPELINE_CYCLES-2)  -- [natural]
        port map (
            i_clk => i_clk,                         -- [std_logic]
            i_bus => to_slv(colY_out),              -- [std_logic_vector]
            o_bus => slv_colY                       -- [std_logic_vector]
            );
    o_col(polY) <= from_slv(slv_colY);

    E_PIPE_READOUT : entity work.pipeline_delay
        generic map (
            g_CYCLES_DELAY => 3-g_PIPELINE_CYCLES)  -- [natural]
        port map (
            i_clk     => i_clk,                   -- [std_logic]
            i_bus     => readout_pipe_data,       -- [std_logic_vector]
            i_bus_vld => readout_pipe_vld,        -- [std_logic]
            o_bus     => o_readout_data,          -- [std_logic_vector]
            o_bus_vld => o_readout_vld            -- [std_logic]
            );
----------------------------------------------------------------------------------------
end architecture rtl;
