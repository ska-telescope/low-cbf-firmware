---------------------------------------------------------------------------------------------------
-- 
-- Correlator (COR) - Synth Wrapper
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert.abel@autac.nz)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- This is a dummy synth wrapper flopping all inputs and outputs to make timing analysis meaningful.
-- Set "More Options" of Synthesis Settings to "-mode out_of_context" to compile without using
-- real pins.
--
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.misc_tools_pkg.all;                  -- ceil_log2, bit_width
use work.cmac_pkg.all;                  -- t_cmac_input_bus_a
use work.misc_tools_pkg.all;            -- wired_or
use work.common_types_pkg.all;          -- slv_8_a
use work.cmac_tdm_pkg.all;              -- t_tdm_rd_ctrl, t_tdm_cache_wr_bus_a
use work.visibility_pkg.all;            -- t_visibility_context
use work.mta_regs_pkg.all;              -- t_cci_ram_wr_reg

entity synth_wrapper is
    Generic (
        g_COL_DIMENSION   : natural := 2;
        g_ANTENNA_PER_COL : natural := 6
    );      
    port (
        ----------------------------------------------------------------------------------------------------------------
        -- Input Data Interface.
        ----------------------------------------------------------------------------------------------------------------
        i_cturn_clk        : in  std_logic;
        i_cturn_clk_reset  : in  std_logic;
        i_tdm_cache_wr_bus : in  t_tdm_cache_wr_bus_a(g_COL_DIMENSION-1 downto 0);
        o_wr_stop          : out std_logic_vector(g_COL_DIMENSION-1 downto 0);  -- stop at the end of this burst.

        ----------------------------------------------------------------------------------------------------------------
        -- Context Interface
        ----------------------------------------------------------------------------------------------------------------
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
        i_cmac_clk_reset  : in  std_logic;
        o_mta_context     : out t_visibility_context;
        o_mta_context_vld : out std_logic;
        o_mta_data_frame  : out t_mta_data_frame_a(g_COL_DIMENSION-1 downto 0);
        o_mta_vld         : out std_logic_vector(g_COL_DIMENSION-1 downto 0)
    ); 
end synth_wrapper;

architecture Behavioral of synth_wrapper is
    
    constant g_NUM_SAMPLES                 : natural := 51;
    constant g_CMAC_DUMPS_PER_MTA_DUMP     : natural := 4;   -- number of CMAC dumps in a minimum integration period. e.g. 17.
    constant g_MAX_CHANNEL_AVERAGE         : natural := 8;   -- maximum number of channels that can be averaged. e.g. 8
    constant g_NUM_CHANNELS                : natural := 16;

    constant g_NUM_OF_NON_AUTO_SLOTS       : natural := g_ANTENNA_PER_COL * (g_ANTENNA_PER_COL-1) / 2;
    constant g_NUM_OF_AUTO_SLOTS           : natural := (g_ANTENNA_PER_COL+1) / 2;
    constant g_NUM_OF_SLOTS                : natural := g_NUM_OF_NON_AUTO_SLOTS + g_NUM_OF_AUTO_SLOTS;
    constant g_NUMBER_OF_BASELINES_PER_COL : natural := g_NUM_OF_AUTO_SLOTS*(g_COL_DIMENSION+1) + g_NUM_OF_NON_AUTO_SLOTS*g_COL_DIMENSION;

    constant g_SAMPLE_WIDTH    : natural range 0 to 9 := 8;

    constant c_MTA_ACCUM_SAMPLES : natural := g_NUM_SAMPLES * g_CMAC_DUMPS_PER_MTA_DUMP;
    constant c_MTA_ACCUM_WIDTH   : natural := f_cmac_accum_width(g_SAMPLE_WIDTH, c_MTA_ACCUM_SAMPLES, g_MAX_CHANNEL_AVERAGE);
    

    signal i_cturn_clk_reset_p  : std_logic;
    signal i_tdm_cache_wr_bus_p : t_tdm_cache_wr_bus_a(g_COL_DIMENSION-1 downto 0);
    signal o_wr_stop_p          : std_logic_vector(g_COL_DIMENSION-1 downto 0);  -- stop at the end of this burst.
    
    signal i_ctx_clk_reset_p : std_logic;
    signal i_context_p       : t_visibility_context;
    signal i_context_vld_p   : std_logic;  -- set high when new context is available.
    signal o_context_ready_p : std_logic;  -- high when new context is accepted.

    signal i_cmac_clk_reset_p  : std_logic;
    signal o_mta_context_p     : t_visibility_context;
    signal o_mta_context_vld_p : std_logic;
    signal o_mta_data_frame_p  : t_mta_data_frame_a(g_COL_DIMENSION-1 downto 0);
    signal o_mta_vld_p         : std_logic_vector(g_COL_DIMENSION-1 downto 0);


begin

    ---------------------------------------------------------------------------------------------------
    -- Correlator
    ---------------------------------------------------------------------------------------------------
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
        -- Input data interface
        i_cturn_clks       => (others => i_cturn_clk),        -- [std_logic]
        i_cturn_clk_resets => (others => i_cturn_clk_reset_p),  -- [std_logic]
        i_tdm_cache_wr_bus => i_tdm_cache_wr_bus_p,  -- [t_tdm_cache_wr_bus_a(g_COL_DIMENSION-1 downto 0)]
        o_wr_stop          => o_wr_stop_p,  -- [std_logic_vector(g_COL_DIMENSION-1 downto 0)] stop at the end of this burst.

        --Context interface
        i_ctx_clk          => i_cturn_clk,
        i_ctx_clk_reset    => i_cturn_clk_reset,
        i_context          => i_context_p,    -- t_visibility_context;
        i_context_vld      => i_context_vld_p,  -- set high when new context is available.
        o_context_ready    => o_context_ready_p,  -- high when new context is accepted.

        --Programming interface
        i_cci_progs        => i_cci_progs, -- t_cci_ram_wr_reg_a(g_COL_DIMENSION-1 downto 0);

        -- Output Interface to Debursting Buffer
        i_cmac_clk         => i_cmac_clk,
        i_cmac_clk_reset   => i_cmac_clk_reset_p,
        o_mta_context      => o_mta_context_p,
        o_mta_context_vld  => o_mta_context_vld_p,
        o_mta_data_frame   => o_mta_data_frame_p,
        o_mta_vld          => o_mta_vld_p
    );

    process (i_cturn_clk)
    begin
        if rising_edge(i_cturn_clk) then
            i_cturn_clk_reset_p  <= i_cturn_clk_reset;
            i_tdm_cache_wr_bus_p <= i_tdm_cache_wr_bus;
            o_wr_stop            <= o_wr_stop_p;
            
            i_context_p          <= i_context;
            i_context_vld_p      <= i_context_vld;
            o_context_ready      <= o_context_ready_p;
        end if;
    end process;

    process (i_cmac_clk)
    begin
        if rising_edge(i_cmac_clk) then
            i_cmac_clk_reset_p <= i_cmac_clk_reset;
            o_mta_context      <= o_mta_context_p;
            o_mta_context_vld  <= o_mta_context_vld_p;
            o_mta_data_frame   <= o_mta_data_frame_p;
            o_mta_vld          <= o_mta_vld_p;
        end if;
    end process;

end Behavioral;
