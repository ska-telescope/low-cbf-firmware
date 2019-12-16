-------------------------------------------------------------------------------
-- Title      : Mid Term Accumulator
-- Project    : 
-------------------------------------------------------------------------------
-- File       : mid_term_accumulator.vhd
-- Author     : William Kamp  <william.kamp@aut.ac.nz>
-- Company    : High Performance Computing Research Lab, Auckland University of Technology
-- Created    : 2017-03-08
-- Last update: 2018-07-09
-- Platform   : 
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Accumulates all baselines over the time division multiplexing of the CMACs for a single frequency channel.
-------------------------------------------------------------------------------
-- Copyright (c) 2017 High Performance Computing Research Lab, Auckland University of Technology
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-03-08  1.0      will    Created
-- 2019-09-17  2.0p     nabel   Ported to Perentie (fixed misbehaviour of Vivado synthesis)
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.misc_tools_pkg.all;                  -- ceil_log2, bit_width
use work.visibility_pkg.all;
use work.cmac_pkg.all;
use work.misc_tools_pkg.all;            -- ceil_pow2
use work.mta_regs_pkg.all;              -- t_cci_ram_wr_reg


entity mid_term_accumulator is

    generic (
        g_COL_DIMENSION           : natural;  -- number of columns in CMAC array, e.g. 20
        g_THIS_COLUMN             : natural;  -- column number that this MTA is asigned to.
        g_ANTENNA_PER_COL         : natural;  -- number of antenna multiplexed onto each column
        g_NUM_CHANNELS            : natural;  -- number of frequency channels.
        g_SAMPLE_WIDTH            : natural;  -- sample width into the CMAC array, e.g. 9
        g_CMAC_ACCUM_SAMPLES      : natural;  -- number of samples in a sub accumulation. e.g. 112. Used to derive
                                              -- DATA_VALID and TCI readout widths.
        g_CMAC_DUMPS_PER_MTA_DUMP : natural range 2 to 256;  -- number of CMAC dumps in a minimum integration period. e.g. 17.
        g_MAX_CHANNEL_AVERAGE     : natural   -- maximum number of channels that can be averaged.
        );

    port (
        i_clk       : in std_logic;
        i_clk_reset : in std_logic;

        i_cmac_readout_data : in std_logic_vector;
        i_cmac_readout_vld  : in std_logic;
        i_cmac_context      : in t_visibility_context;

        ---------------------------------------------------------------------------
        -- Programming Interfaces
        ---------------------------------------------------------------------------
        i_cci_prog       : in  t_cci_ram_wr_reg;
        ---------------------------------------------------------------------------
        -- Output to Debursting Buffer.
        ---------------------------------------------------------------------------
        o_mta_data_frame : out t_mta_data_frame;
        o_mta_context    : out t_visibility_context;
        o_mta_vld        : out std_logic
        );

end entity mid_term_accumulator;

architecture rtl of mid_term_accumulator is

    -- calculate the actual width of the accumulators at the input from the cmac_readout bus.
    constant c_CMAC_TCI_WIDTH   : natural := f_cmac_tci_width(g_CMAC_ACCUM_SAMPLES);
    constant c_CMAC_DVC_WIDTH   : natural := f_cmac_dv_width(g_CMAC_ACCUM_SAMPLES);
    constant c_CMAC_ACCUM_WIDTH : natural := f_cmac_accum_width(g_SAMPLE_WIDTH, g_CMAC_ACCUM_SAMPLES);

    -- calculate the actual width of the accumulators in the MTA visibility RAM.
    constant c_MTA_ACCUM_SAMPLES : natural := g_CMAC_ACCUM_SAMPLES * g_CMAC_DUMPS_PER_MTA_DUMP;
    constant c_MTA_TCI_WIDTH     : natural := f_cmac_tci_width(c_MTA_ACCUM_SAMPLES, g_MAX_CHANNEL_AVERAGE);
    constant c_MTA_DVC_WIDTH     : natural := f_cmac_dv_width(c_MTA_ACCUM_SAMPLES, g_MAX_CHANNEL_AVERAGE);
    constant c_MTA_CCI_WIDTH     : natural := f_cmac_cci_width(c_MTA_ACCUM_SAMPLES, g_MAX_CHANNEL_AVERAGE);
    constant c_MTA_ACCUM_WIDTH   : natural := f_cmac_accum_width(g_SAMPLE_WIDTH, c_MTA_ACCUM_SAMPLES, g_MAX_CHANNEL_AVERAGE);

    constant c_NUM_OF_NON_AUTO_SLOTS : natural := g_ANTENNA_PER_COL * (g_ANTENNA_PER_COL-1) / 2;
    constant c_NUM_OF_AUTO_SLOTS     : natural := (g_ANTENNA_PER_COL+1) / 2;
    constant c_NUM_BASELINES         : natural := c_NUM_OF_AUTO_SLOTS*(g_COL_DIMENSION+1) + c_NUM_OF_NON_AUTO_SLOTS*g_COL_DIMENSION;
    -- if g_ANTENNA_PER_COL is odd, then the last auto correlation TDM slot will only be half used (upper triangle), so
    -- will get some dummy baselines come through.
    constant c_NUM_DUMMY_BASELINES   : natural := (g_COL_DIMENSION-g_THIS_COLUMN)*(g_ANTENNA_PER_COL mod 2);
    constant c_NUM_VALID_BASELINES   : natural := c_NUM_BASELINES - c_NUM_DUMMY_BASELINES;

    -- calculate a ROM to store the "Base Sample" number for each TDM lap.
    -- This is the number of previous samples and is used to cacluate the offset in the TCI calculation.
    constant c_BS_WIDTH : natural := bit_width(g_CMAC_ACCUM_SAMPLES*g_CMAC_DUMPS_PER_MTA_DUMP);
    type t_bs_rom is array (0 to ceil_pow2(g_CMAC_DUMPS_PER_MTA_DUMP)-1) of unsigned(c_BS_WIDTH-1 downto 0);
    function f_bs_rom (
        constant c_CMAC_DUMPS_PER_MTA_DUMP : natural;
        constant c_CMAC_ACCUM_SAMPLES      : natural)
        return t_bs_rom is
        variable rom : t_bs_rom;
    begin
        rom := (others => (others => '0'));
        for idx in 0 to c_CMAC_DUMPS_PER_MTA_DUMP-1 loop
            rom(idx) := to_unsigned(idx * c_CMAC_ACCUM_SAMPLES, rom(idx)'length);
        end loop;  -- idx
        return rom;
    end function f_bs_rom;
    signal c_BASE_SAMPLE_ROM                : t_bs_rom := f_bs_rom(g_CMAC_DUMPS_PER_MTA_DUMP, g_CMAC_ACCUM_SAMPLES);
    attribute romstyle                      : string;
    attribute romstyle of c_BASE_SAMPLE_ROM : signal is "logic";

    -- Calculate the required size of the multiplier and accumulator in the RFI section.
    constant c_MULT_WIDTH      : natural := maxim(c_BS_WIDTH, c_CMAC_DVC_WIDTH);
    constant c_RAM_ACCUM_WIDTH : natural := maxim(maxim(c_MTA_DVC_WIDTH, c_MTA_CCI_WIDTH), c_MTA_TCI_WIDTH);
    --constant c_RAM_ACCUM_WIDTH : natural := maximum(maximum(c_MTA_DVC_WIDTH, c_MTA_CCI_WIDTH), c_MTA_TCI_WIDTH);

    ------------------------------------------------------------
    -- TDM   | Antenna group:
    -- SLOT  | A(0) B(1) C(2) D(3) E(4) F(5) G(6) H(7) I(8) J(9)
    ---------+--------------------------------------------------
    -- A(0)  |   9a
    -- B(1)  |   0   9a 
    -- C(2)  |   1   10   25a  
    -- D(3)  |   2   11   18   25a
    -- E(4)  |   3   12   19   26   37a
    -- F(5)  |   4   13   20   27   32   37a
    -- G(6)  |   5   14   21   28   33   38   45a
    -- H(7)  |   6   15   22   29   34   39   42   45a
    -- I(8)  |   7   16   23   30   35   40   43   46   49a
    -- J(9)  |   8   17   24   31   36   41   44   47   48   49a
    ------------------------------------------------------------
    function f_get_column_antenna (
        baseline                   : natural;
        constant c_ANTENNA_PER_COL : natural;
        antenna                    : natural := 0)
        return natural is
    begin
        if c_ANTENNA_PER_COL <= 1 then
            return 0;
        end if;
        if baseline <= (c_ANTENNA_PER_COL-2)*g_COL_DIMENSION then                     --1
            -- in first column.
            return 0;
        elsif baseline <= (c_ANTENNA_PER_COL-2)*g_COL_DIMENSION+g_THIS_COLUMN+2 then  --2
            -- auto-corr TDM slot, baseline above the diagonal.
            return 0;
        elsif baseline < (c_ANTENNA_PER_COL)*g_COL_DIMENSION+1 then                   --4
            -- auto-corr TDM slot, baseline below the diagonal.
            return 1;
        elsif baseline < (c_ANTENNA_PER_COL-1)*2*g_COL_DIMENSION+1 then               --5
            -- second column            
            return 1;
        else
            -- recurse to 3rd column.
            return 2 + f_get_column_antenna(baseline - ((c_ANTENNA_PER_COL-1)*2*g_COL_DIMENSION+1),
                                            c_ANTENNA_PER_COL - 2);
        end if;
    end function f_get_column_antenna;

    type t_ant_rom is array (0 to ceil_pow2(c_NUM_BASELINES)-1) of
        unsigned(ceil_log2(g_ANTENNA_PER_COL)-1 downto 0);

    function f_antenna_rom_init
        return t_ant_rom is
        variable v_ant_rom : t_ant_rom;
    begin
        v_ant_rom := (others => (others => '0'));
        for baseline in 0 to c_NUM_VALID_BASELINES - 1 loop
            v_ant_rom(baseline) := to_unsigned(f_get_column_antenna(baseline,
                                                                    g_ANTENNA_PER_COL,
                                                                    0),
                                               v_ant_rom(0)'length);
        end loop;  -- baseline
        return v_ant_rom;
    end function f_antenna_rom_init;

    signal c_antenna_rom                : t_ant_rom := f_antenna_rom_init;
    attribute romstyle of c_antenna_rom : signal is "logic";

    ----------------------------------------------------------------------
    -- Signals
    ----------------------------------------------------------------------
    signal c0_cmac_readout_data_hi : std_logic_vector(i_cmac_readout_data'length/2-1 downto 0);
    signal c0_cmac_readout_data_lo : std_logic_vector(c0_cmac_readout_data_hi'range);
    signal c0_cmac_readout_vld     : std_logic;
    signal c0_context              : t_visibility_context := T_VISIBILITY_CONTEXT_ZERO;

    type t_df_value is (s_RFI_XX_ACCUM, s_XY_YX_ACCUM, s_YY_ACCUM);
    signal c0_df_value : t_df_value;

    signal c5_tdm_lap : unsigned(ceil_log2(g_CMAC_DUMPS_PER_MTA_DUMP)-1 downto 0);

    signal c0_baseline      : unsigned(ceil_log2(c_NUM_BASELINES) -1 downto 0);
    signal c2_baseline      : unsigned(ceil_log2(c_NUM_BASELINES) -1 downto 0) := (others => '0');
    signal c1_new_vis_data  : t_mta_data_frame := T_MTA_DATA_FRAME_ZERO;
    signal c1_new_vis_valid : std_logic;
    signal c4_new_vis_data  : t_mta_data_frame;
    signal c2_new_vis_valid : std_logic;

    signal c3_rd_vis_valid    : std_logic;
    signal c4_rd_vis_data_slv : std_logic_vector(T_MTA_DATA_FRAME_SLV_WIDTH-1 downto 0);
    signal c4_rd_vis_valid    : std_logic;
    signal c5_rd_vis_data     : t_mta_data_frame;
    signal c5_rd_vis_valid    : std_logic;
    signal c5_new_vis_data    : t_mta_data_frame;

    signal c6_new_vis_data   : t_mta_data_frame;
    signal c6_acc_vis_data   : t_mta_data_frame;
    signal c6_acc_vis_valid  : std_logic;
    signal c7_acc_vis_valid  : std_logic;
    signal c8_acc_vis_valid  : std_logic;
    signal c9_acc_vis_valid  : std_logic;
    signal c10_acc_vis_valid : std_logic;

    signal c1_channel : unsigned(ceil_log2(g_NUM_CHANNELS)-1 downto 0) := (others => '0');
    signal c2_channel : unsigned(ceil_log2(g_NUM_CHANNELS)-1 downto 0);
    signal c3_antenna : unsigned(ceil_log2(g_ANTENNA_PER_COL)-1 downto 0) := (others => '0');
    signal c4_antenna : unsigned(c3_antenna'range) := (others => '0');

    --signal c2_channel_offset    : unsigned(ceil_log2(g_NUM_CHANNELS*g_ANTENNA_PER_COL)-1 downto 0);
    --signal c2_antenna           : unsigned(ceil_log2(g_ANTENNA_PER_COL)-1 downto 0);
    signal c3_channel_antenna   : unsigned(ceil_log2(g_NUM_CHANNELS*g_ANTENNA_PER_COL)-1 downto 0);
    signal c3_cci_mult_data_slv : std_logic_vector(g_ANTENNA_PER_COL*bit_width(g_MAX_CHANNEL_AVERAGE-1)-1 downto 0);
    signal c4_cci_mult_data_slv : std_logic_vector(c3_cci_mult_data_slv'range);
    signal c5_cci_mult_data     : unsigned(bit_width(g_MAX_CHANNEL_AVERAGE-1)-1 downto 0);
    signal c6_cci_mult_data     : unsigned(c5_cci_mult_data'range);
    signal c6_new_dvc           : unsigned(c_CMAC_DVC_WIDTH-1 downto 0);
    signal c6_new_tci           : unsigned(c_CMAC_TCI_WIDTH-1 downto 0);
    signal c6_base_sample       : unsigned(c_BS_WIDTH-1 downto 0);
    signal c6_mult_opA          : unsigned(c_MULT_WIDTH-1 downto 0);
    signal c7_mult_opA          : unsigned(c_MULT_WIDTH-1 downto 0);
    signal c7_mult_opB          : unsigned(c_MULT_WIDTH-1 downto 0);
    signal c8_mult_opA          : unsigned(c_MULT_WIDTH-1 downto 0);
    signal c8_mult_opB          : unsigned(c_MULT_WIDTH-1 downto 0);
    signal c9_mult_opA          : unsigned(c_MULT_WIDTH-1 downto 0);
    signal c9_mult_opB          : unsigned(c_MULT_WIDTH-1 downto 0);
    signal c6_add_operand       : unsigned(c_MULT_WIDTH*2 -1 downto 0);
    signal c7_add_operand       : unsigned(c_MULT_WIDTH*2 -1 downto 0);
    signal c8_add_operand       : unsigned(c_MULT_WIDTH*2 -1 downto 0);
    signal c9_add_operand       : unsigned(c_MULT_WIDTH*2 -1 downto 0);

    signal c10_product : unsigned(2*c_MULT_WIDTH-1 downto 0);
    signal c11_product : unsigned(2*c_MULT_WIDTH-1 downto 0);
    signal c12_product : unsigned(2*c_MULT_WIDTH-1 downto 0);

    signal c9_acc_vis_data       : t_mta_data_frame;
    signal c12_acc_vis_data      : t_mta_data_frame;
    signal c15_acc_vis_data      : t_mta_data_frame;
    signal c11_acc_vis_valid     : std_logic;
    signal c12_acc_vis_valid     : std_logic;
    signal c13_acc_vis_valid     : std_logic;
    signal c14_acc_vis_valid     : std_logic;
    signal c15_acc_rfi_vis_data  : t_mta_data_frame;
    signal c15_acc_rfi_vis_valid : std_logic;

    signal c6_dump            : std_logic;
    signal c7_dump_and_clear  : std_logic;
    signal c9_dump_and_clear  : std_logic;
    signal c12_dump_and_clear : std_logic;
    signal c15_dump_and_clear : std_logic;

    signal c16_vis_wr_data : t_mta_data_frame := T_MTA_DATA_FRAME_ZERO;
    signal c16_vis_wr_vld  : std_logic;

begin  -- architecture rtl

    -- Input data arrives in 3 cycles per baseline.
    -- high half of word, low half of word
    --   RFI data       ,  XX pol
    --   XY pol         ,  YX pol
    --   YY pol         ,  empty.
    P_INPUT_DESERIALISE : process (i_clk) is
        variable v_inc              : unsigned(c0_baseline'range);
        variable v0_sub_vis_real_hi : signed(c1_new_vis_data.pol_YY_real'range);
        variable v0_sub_vis_imag_hi : signed(c1_new_vis_data.pol_YY_imag'range);
        variable v0_sub_vis_real_lo : signed(c1_new_vis_data.pol_YY_real'range);
        variable v0_sub_vis_imag_lo : signed(c1_new_vis_data.pol_YY_imag'range);
    begin
        if rising_edge(i_clk) then
            c0_cmac_readout_data_hi <= i_cmac_readout_data(i_cmac_readout_data'high downto i_cmac_readout_data'length/2);
            c0_cmac_readout_data_lo <= i_cmac_readout_data(i_cmac_readout_data'length/2-1 downto 0);
            c0_cmac_readout_vld     <= i_cmac_readout_vld;

            v0_sub_vis_real_hi := resize(signed(
                c0_cmac_readout_data_hi(2*c_CMAC_ACCUM_WIDTH-1 downto
                                        1*c_CMAC_ACCUM_WIDTH)
                ), c1_new_vis_data.pol_YY_real'length);
            v0_sub_vis_imag_hi := resize(signed(
                c0_cmac_readout_data_hi(1*c_CMAC_ACCUM_WIDTH-1 downto
                                        0*c_CMAC_ACCUM_WIDTH)
                ), c1_new_vis_data.pol_YY_imag'length);
            v0_sub_vis_real_lo := resize(signed(
                c0_cmac_readout_data_lo(2*c_CMAC_ACCUM_WIDTH-1 downto
                                        1*c_CMAC_ACCUM_WIDTH)
                ), c1_new_vis_data.pol_YY_real'length);
            v0_sub_vis_imag_lo := resize(signed(
                c0_cmac_readout_data_lo(1*c_CMAC_ACCUM_WIDTH-1 downto
                                        0*c_CMAC_ACCUM_WIDTH)
                ), c1_new_vis_data.pol_YY_imag'length);

            c1_new_vis_valid <= '0';
            if c0_cmac_readout_vld='1' then
                case c0_df_value is
                    when s_RFI_XX_ACCUM =>
                        c1_new_vis_data.DVC <= resize(unsigned(
                            c0_cmac_readout_data_hi(c_CMAC_DVC_WIDTH-1 downto 0)
                            ), c1_new_vis_data.DVC'length);
                        c1_new_vis_data.TCI <= resize(unsigned(
                            c0_cmac_readout_data_hi(c_CMAC_TCI_WIDTH+c_CMAC_DVC_WIDTH-1 downto c_CMAC_DVC_WIDTH)
                            ), c1_new_vis_data.TCI'length);
                        c1_new_vis_data.pol_XX_real <= v0_sub_vis_real_lo;
                        c1_new_vis_data.pol_XX_imag <= v0_sub_vis_imag_lo;
                        c0_df_value                 <= s_XY_YX_ACCUM;
                    when s_XY_YX_ACCUM =>
                        c1_new_vis_data.pol_XY_real <= v0_sub_vis_real_hi;
                        c1_new_vis_data.pol_XY_imag <= v0_sub_vis_imag_hi;
                        c1_new_vis_data.pol_YX_real <= v0_sub_vis_real_lo;
                        c1_new_vis_data.pol_YX_imag <= v0_sub_vis_imag_lo;
                        c0_df_value                 <= s_YY_ACCUM;
                    when s_YY_ACCUM =>
                        c1_new_vis_data.pol_YY_real <= v0_sub_vis_real_hi;
                        c1_new_vis_data.pol_YY_imag <= v0_sub_vis_imag_hi;
                        c1_new_vis_data.baseline    <= resize(c0_baseline, c1_new_vis_data.baseline'length);
                        c1_new_vis_valid            <= '1';
                        c0_df_value                 <= s_RFI_XX_ACCUM;
                    when others =>
                        c0_df_value <= s_RFI_XX_ACCUM;
                end case;
            end if;
            if c0_cmac_readout_vld = '1' and c0_df_value = s_YY_ACCUM then
                v_inc := to_unsigned(1, v_inc'length);
            else
                v_inc := to_unsigned(0, v_inc'length);
            end if;
            c0_baseline <= c0_baseline + v_inc;

            if i_cmac_context.tdm_lap_start='1' then
                c0_df_value <= s_RFI_XX_ACCUM;
                c0_baseline <= to_unsigned(0, c0_baseline'length);
                c0_context  <= i_cmac_context;
            end if;
            c0_context.tdm_lap_start <= i_cmac_context.tdm_lap_start;

            c1_channel <= c0_context.channel(c1_channel'range);
            if c4_rd_vis_valid='1' then
                c5_tdm_lap <= c0_context.tdm_lap(c5_tdm_lap'range);
            end if;


            -- Flop to RAM.
            c2_new_vis_valid <= c1_new_vis_valid;
            if c1_new_vis_valid='1' then
                -- latch and hold for 3 cycles till next baseline received.
                c4_new_vis_data <= c1_new_vis_data;
            end if;
            c2_baseline <= to_01(c1_new_vis_data.baseline(c2_baseline'range));
        end if;
    end process;

    E_VIS_STORE : entity work.sdp_ram
        generic map (
            g_REG_OUTPUT => true)                                        -- [boolean]
        port map (
            i_clk       => i_clk,                                        -- [std_logic]
            i_clk_reset => i_clk_reset,                                  -- [std_logic]
            i_wr_addr   => c16_vis_wr_data.baseline(c2_baseline'range),  -- [unsigned]
            i_wr_en     => c16_vis_wr_vld,                               -- [std_logic]
            i_wr_data   => to_slv(c16_vis_wr_data),                      -- [std_logic_vector]
            i_rd_addr   => c2_baseline,                                  -- [unsigned]
            i_rd_en     => c2_new_vis_valid,                             -- [std_logic]
            o_rd_data   => c4_rd_vis_data_slv);                          -- [std_logic_vector]

    P_FLOP_RAM : process (i_clk) is
    begin
        if rising_edge(i_clk) then
            -- flops to match RAM delay            
            c3_rd_vis_valid <= c2_new_vis_valid;
            c4_rd_vis_valid <= c3_rd_vis_valid;
            -- flop for timing.
            c5_rd_vis_data  <= from_slv(c4_rd_vis_data_slv);
            -- synthesis translate_off
            if c4_rd_vis_data_slv = (c4_rd_vis_data_slv'range => 'X') then
                -- hack to 'initialise' the RAM to all zeros in simulation.
                c5_rd_vis_data <= T_MTA_DATA_FRAME_ZERO;
            end if;
            -- synthesis translate_on
            c5_rd_vis_valid <= c4_rd_vis_valid;

            if c4_rd_vis_valid='1' then
                c5_new_vis_data <= c4_new_vis_data;
            end if;
        end if;
    end process;

    P_VIS_ACCUMULATE : process (i_clk) is
    begin
        if rising_edge(i_clk) then
            if c5_rd_vis_valid='1' then
                -- copy from input. c5_new_vis_data held constant for atleast 3 cycles.
                c6_new_vis_data          <= c5_new_vis_data;
                -- copy RFI values from RAM into the pipeline.
                c6_acc_vis_data          <= c5_rd_vis_data;
                -- get pipeline from generated one rather than from the RAM
                -- this should optimise the baseline out of the RAM in synthesis.
                c6_acc_vis_data.baseline <= c5_new_vis_data.baseline;
                assert c5_new_vis_data.baseline = c5_rd_vis_data.baseline or
                    c5_rd_vis_data.baseline = 0
                    report "baseline for new data and data read from RAM do not match"
                    severity error;

                -- Update the visibility accumulators adding new data to that from the RAM.
                c6_acc_vis_data.pol_YY_real(c_MTA_ACCUM_WIDTH-1 downto 0) <=
                    c5_rd_vis_data.pol_YY_real(c_MTA_ACCUM_WIDTH-1 downto 0) +
                    c5_new_vis_data.pol_YY_real(c_MTA_ACCUM_WIDTH-1 downto 0);

                c6_acc_vis_data.pol_YY_imag(c_MTA_ACCUM_WIDTH-1 downto 0) <=
                    c5_rd_vis_data.pol_YY_imag(c_MTA_ACCUM_WIDTH-1 downto 0) +
                    c5_new_vis_data.pol_YY_imag(c_MTA_ACCUM_WIDTH-1 downto 0);

                c6_acc_vis_data.pol_YX_real(c_MTA_ACCUM_WIDTH-1 downto 0) <=
                    c5_rd_vis_data.pol_YX_real(c_MTA_ACCUM_WIDTH-1 downto 0) +
                    c5_new_vis_data.pol_YX_real(c_MTA_ACCUM_WIDTH-1 downto 0);

                c6_acc_vis_data.pol_YX_imag(c_MTA_ACCUM_WIDTH-1 downto 0) <=
                    c5_rd_vis_data.pol_YX_imag(c_MTA_ACCUM_WIDTH-1 downto 0) +
                    c5_new_vis_data.pol_YX_imag(c_MTA_ACCUM_WIDTH-1 downto 0);

                c6_acc_vis_data.pol_XY_real(c_MTA_ACCUM_WIDTH-1 downto 0) <=
                    c5_rd_vis_data.pol_XY_real(c_MTA_ACCUM_WIDTH-1 downto 0) +
                    c5_new_vis_data.pol_XY_real(c_MTA_ACCUM_WIDTH-1 downto 0);

                c6_acc_vis_data.pol_XY_imag(c_MTA_ACCUM_WIDTH-1 downto 0) <=
                    c5_rd_vis_data.pol_XY_imag(c_MTA_ACCUM_WIDTH-1 downto 0) +
                    c5_new_vis_data.pol_XY_imag(c_MTA_ACCUM_WIDTH-1 downto 0);

                c6_acc_vis_data.pol_XX_real(c_MTA_ACCUM_WIDTH-1 downto 0) <=
                    c5_rd_vis_data.pol_XX_real(c_MTA_ACCUM_WIDTH-1 downto 0) +
                    c5_new_vis_data.pol_XX_real(c_MTA_ACCUM_WIDTH-1 downto 0);

                c6_acc_vis_data.pol_XX_imag(c_MTA_ACCUM_WIDTH-1 downto 0) <=
                    c5_rd_vis_data.pol_XX_imag(c_MTA_ACCUM_WIDTH-1 downto 0) +
                    c5_new_vis_data.pol_XX_imag(c_MTA_ACCUM_WIDTH-1 downto 0);
            end if;
            c6_acc_vis_valid <= c5_rd_vis_valid;
        end if;
    end process;

    E_CCI_FACTOR_STORE : entity work.dual_clock_simple_dual_port_ram
        generic map (
            g_REG_OUTPUT => true)                                                 -- [boolean]
        port map (
            i_wr_clk       => i_cci_prog.clk,                                     -- [std_logic]
            i_wr_clk_reset => i_cci_prog.reset,                                   -- [std_logic]
            i_wr_addr      => i_cci_prog.address(c1_channel'range),               -- [unsigned]
            i_wr_en        => i_cci_prog.wr_req,                                  -- [std_logic]
            i_wr_data      => i_cci_prog.cci_factor(c4_cci_mult_data_slv'range),  -- [std_logic_vector]
            i_rd_clk       => i_clk,
            i_rd_clk_reset => i_clk_reset,
            i_rd_addr      => c1_channel,                                         -- [unsigned]
            i_rd_en        => '1',                                                -- [std_logic]
            o_rd_data      => c3_cci_mult_data_slv);                              -- [std_logic_vector]


    GEN_SEL_SUBARRAY: if true generate
        type t_antenna_i is array(g_ANTENNA_PER_COL-1 downto 0) of unsigned(c5_cci_mult_data'range); 
        signal c4_antenna_i : t_antenna_i;
    begin
        GEN_HELPER: for ant in 0 to g_ANTENNA_PER_COL-1  generate
            constant c_idx_high : natural := ant*c5_cci_mult_data'length + c5_cci_mult_data'high;
            constant c_idx_low  : natural := ant*c5_cci_mult_data'length;
        begin
            c4_antenna_i(ant) <= unsigned(c4_cci_mult_data_slv(c_idx_high downto c_idx_low));
        end generate;            

        P_SEL_SUBARRAY : process (i_clk) is
            --variable v_idx_high : natural;
            --variable v_idx_low  : natural;
        begin
            if rising_edge(i_clk) then
                c4_cci_mult_data_slv <= c3_cci_mult_data_slv;
    
                c3_antenna <= c_antenna_rom(to_integer(c2_baseline));
                c4_antenna <= c3_antenna;
                
                --v_idx_high := to_integer(c4_antenna)*c5_cci_mult_data'length + c5_cci_mult_data'high;
                --v_idx_low  := to_integer(c4_antenna)*c5_cci_mult_data'length;
                --c5_cci_mult_data <= unsigned(c4_cci_mult_data_slv(v_idx_high downto v_idx_low));
                
                c5_cci_mult_data <= c4_antenna_i(to_integer(c4_antenna));
                c6_cci_mult_data <= c5_cci_mult_data;
            end if;
        end process;
    end generate;

    c6_new_dvc <= c6_new_vis_data.DVC(c_CMAC_DVC_WIDTH-1 downto 0);
    c6_new_tci <= c6_new_vis_data.TCI(c_CMAC_TCI_WIDTH-1 downto 0);

    P_RFI_ACCUMULATE : process (i_clk) is
    begin
        if rising_edge(i_clk) then
            -- Mux in values to feed to multiplier.
            if c5_rd_vis_valid='1' then
                c6_base_sample <= c_BASE_SAMPLE_ROM(to_integer(to_01(c5_tdm_lap)));
            end if;
            c7_acc_vis_valid <= c6_acc_vis_valid;

            if c5_rd_vis_valid='1' then
                -- Data Valid Count (first)
                c6_mult_opA    <= to_unsigned(1, c_MULT_WIDTH);
                c6_add_operand <= to_unsigned(0, 2*c_MULT_WIDTH);
            elsif c6_acc_vis_valid='1' then
                -- Time Centroid Index (second)
                c6_mult_opA    <= resize(c6_base_sample, c_MULT_WIDTH);
                c6_add_operand <= resize(c6_new_tci, 2*c_MULT_WIDTH);
            elsif c7_acc_vis_valid='1' then
                -- Channel Centroid Index (third)
                c6_mult_opA    <= resize(c6_cci_mult_data, c_MULT_WIDTH);
                c6_add_operand <= to_unsigned(0, 2*c_MULT_WIDTH);
            else
                c6_mult_opA    <= (others => '-');
                c6_add_operand <= (others => '-');
            end if;

            -- Three pipeline flops for multiplier.
            c7_mult_opA <= c6_mult_opA;
            c8_mult_opA <= c7_mult_opA;
            c9_mult_opA <= c8_mult_opA;

            c7_mult_opB <= resize(c6_new_dvc, c_MULT_WIDTH);
            c8_mult_opB <= c7_mult_opB;
            c9_mult_opB <= c8_mult_opB;

            c7_add_operand <= c6_add_operand;
            c8_add_operand <= c7_add_operand;
            c9_add_operand <= c8_add_operand;
            --------------------------------------

            c10_product <= (c9_mult_opA * c9_mult_opB) + c9_add_operand;
            c11_product <= c10_product;
            c12_product <= c11_product;  -- flop for timing, out of DSP.

            -- flop delays to match multiplier.
            c8_acc_vis_valid  <= c7_acc_vis_valid;
            c9_acc_vis_valid  <= c8_acc_vis_valid;
            c10_acc_vis_valid <= c9_acc_vis_valid;
            c11_acc_vis_valid <= c10_acc_vis_valid;
            c12_acc_vis_valid <= c11_acc_vis_valid;
            if c6_acc_vis_valid='1' then
                c9_acc_vis_data <= c6_acc_vis_data;
            end if;
            if c9_acc_vis_valid='1' then
                c12_acc_vis_data <= c9_acc_vis_data;
            end if;

            -- Combine RFI updates with visibilty accumulator values.
            -- Timing of signals gets squirrely below.
            -- On c12_acc_vis_valid, c12_product is the DVC.
            -- On c13_acc_vis_valid, c12_product is the TCI.
            -- On c14_acc_vis_valid, c12_product is the CCI.
            if c12_acc_vis_valid='1' then   -- cycle DVC
                c15_acc_vis_data <= c12_acc_vis_data;
                c15_acc_rfi_vis_data.DVC <= resize(
                    resize(c12_product, c_MTA_DVC_WIDTH) +
                    c12_acc_vis_data.DVC(c_MTA_DVC_WIDTH-1 downto 0),
                    c15_acc_rfi_vis_data.DVC'length);
            end if;
            if c13_acc_vis_valid='1' then   -- add in the TCI value from the CMAC.
                c15_acc_rfi_vis_data.TCI <= resize(
                    resize(c12_product, c_MTA_TCI_WIDTH) +
                    c15_acc_vis_data.TCI(c_MTA_TCI_WIDTH-1 downto 0),
                    c15_acc_rfi_vis_data.TCI'length);
            end if;
            if c14_acc_vis_valid='1' then   -- cycle CCI
                c15_acc_rfi_vis_data.CCI <= resize(
                    resize(c12_product, c_MTA_CCI_WIDTH) +
                    c15_acc_vis_data.CCI(c_MTA_CCI_WIDTH-1 downto 0),
                    c15_acc_rfi_vis_data.CCI'length);
            end if;
            c13_acc_vis_valid     <= c12_acc_vis_valid;
            c14_acc_vis_valid     <= c13_acc_vis_valid;
            c15_acc_rfi_vis_valid <= c14_acc_vis_valid;

        end if;
    end process;
    c15_acc_rfi_vis_data.pol_XX_real <= c15_acc_vis_data.pol_XX_real;
    c15_acc_rfi_vis_data.pol_XX_imag <= c15_acc_vis_data.pol_XX_imag;
    c15_acc_rfi_vis_data.pol_XY_real <= c15_acc_vis_data.pol_XY_real;
    c15_acc_rfi_vis_data.pol_XY_imag <= c15_acc_vis_data.pol_XY_imag;
    c15_acc_rfi_vis_data.pol_YX_real <= c15_acc_vis_data.pol_YX_real;
    c15_acc_rfi_vis_data.pol_YX_imag <= c15_acc_vis_data.pol_YX_imag;
    c15_acc_rfi_vis_data.pol_YY_real <= c15_acc_vis_data.pol_YY_real;
    c15_acc_rfi_vis_data.pol_YY_imag <= c15_acc_vis_data.pol_YY_imag;
    c15_acc_rfi_vis_data.baseline    <= c15_acc_vis_data.baseline;

    P_DUMP : process (i_clk) is
    begin
        if rising_edge(i_clk) then

            if c5_rd_vis_valid='1' then
                if c5_tdm_lap >= g_CMAC_DUMPS_PER_MTA_DUMP-1 then
                    c6_dump <= '1';
                else
                    c6_dump <= '0';
                end if;
            end if;
            if c6_acc_vis_valid='1' then
                if c6_cci_mult_data = 0 then
                    -- clear
                    c9_dump_and_clear <= c6_dump;
                else
                    c9_dump_and_clear <= '0';
                end if;
            end if;


            if c9_acc_vis_valid='1' then
                c12_dump_and_clear <= c9_dump_and_clear;
            end if;
            if c12_acc_vis_valid='1' then
                c15_dump_and_clear <= c12_dump_and_clear;
            end if;

            if c15_dump_and_clear='1' then
                c16_vis_wr_data <= T_MTA_DATA_FRAME_ZERO;
            else
                c16_vis_wr_data <= c15_acc_rfi_vis_data;
            end if;
            -- keep baseline even when cleared because we need it as the address into RAM.
            c16_vis_wr_data.baseline <= to_01(c15_acc_rfi_vis_data.baseline);
            c16_vis_wr_vld           <= c15_acc_rfi_vis_valid;

        end if;
    end process;

    o_mta_data_frame <= c15_acc_rfi_vis_data;
    o_mta_vld        <= c15_dump_and_clear and c15_acc_rfi_vis_valid;



end architecture rtl;
