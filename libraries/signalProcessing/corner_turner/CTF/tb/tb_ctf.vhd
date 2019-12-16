---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Fine (CTF) - Test Bench
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert.abel@aut.ac.nz)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- Simulates the Fine Corner Turner
-- 
-- Creates stimuli and checks the DUT's output response
--
---------------------------------------------------------------------------------------------------
-- NOTE:
-- There are plenty of generics in play. However, not every combination is supported by the code.
-- The validity of generics is checked by assertions.
--
-- The data bus format supports a metadata part that is only used in simulation to ease debugging.
-- It is explicitly excluded from synthesis using pragmas.
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

library std;
use std.env.all;

library cor_lib;
use cor_lib.cmac_pkg.all;                  -- t_cmac_input_bus_a
use cor_lib.cmac_tdm_pkg.all;              -- t_tdm_rd_ctrl, t_tdm_cache_wr_bus_a
use cor_lib.visibility_pkg.all;            -- t_visibility_context
use cor_lib.mta_regs_pkg.all;              -- t_cci_ram_wr_reg

library ct_hbm_lib;

library common_tb_lib;
use common_tb_lib.common_tb_pkg.all;

Library axi4_lib;
USE axi4_lib.axi4_lite_pkg.ALL;
use axi4_lib.axi4_full_pkg.all;

use work.ctf_pkg.all;
use work.ctf_config_reg_pkg.all;

Library common_lib;
use common_lib.common_pkg.ALL;

entity tb_ctf is
    generic (
        g_USE_HBM          : boolean := FALSE;
        g_SIMULATE_COR     : boolean := TRUE;
        g_HBM_AXI_PORT     : natural := 15;
        g_HBM_EMU_STUTTER  : boolean := FALSE;
        g_INPUT_STUTTER    : boolean := FALSE;
        g_PROVOKE_EMPTY    : boolean := FALSE;
        g_OUTPUT_STUTTER   : boolean := FALSE;
        g_HBM_BURST_LENGTH : integer := 6;                       -- 1-16 (determines burst length for HBM)
        g_COARSE_CHANNELS  : integer := 32;                      --PISA: 128
        g_STATION_GROUPS   : integer := 12/pc_CTF_INPUT_NUMBER;  --PISA: 3
        g_TIME_STAMPS      : integer := 48;                      --PISA: 204
        g_FINE_CHANNELS    : integer := 128                      --PISA: 3456
    );
end tb_ctf;

architecture sim of tb_ctf is

    --CORRELATOR CONSTANTS RELEVANT TO THE CTF OUTPUT:
    constant g_CMAC_DUMPS_PER_MTA_DUMP : integer := 2;                       --smallest possible value for now: used to balance MTA size vs. input BRAM size
    constant g_COR_NUM_SAMPLES         : integer := g_TIME_STAMPS/g_CMAC_DUMPS_PER_MTA_DUMP;
    constant g_COL_DIMENSION           : integer := pc_CTF_OUTPUT_FACTOR/2;  --2 polarisations in one COR input
    constant g_ANTENNA_PER_COL         : integer := g_STATION_GROUPS;        --this is what we got with the current setup 
    constant g_CTF_OUTPUT_BUST_SIZE    : integer := g_COR_NUM_SAMPLES * g_ANTENNA_PER_COL;

    function addr (i: t_register_address) return integer is
    begin
        return i.base_address + i.address;
    end function;

    
    signal mace_clk     : std_logic := '0';
    signal mace_clk_rst : std_logic := '0';

    signal input_clk : std_logic := '0';
    signal hbm_clk   : std_logic := '0';
    signal apb_clk   : std_logic := '0';
    signal rst       : std_logic := '1';

    signal data_in      : t_ctf_input_data_a(pc_CTF_INPUT_NUMBER-1 downto 0);
    signal data_in_vld  : std_logic;
    signal data_in_stop : std_logic;
    signal data_in_slv  : std_logic_vector(63 downto 0);

    signal data_out      : t_ctf_output_data_a(pc_CTF_OUTPUT_NUMBER-1 downto 0);
    signal header_out    : t_ctf_output_header_a(pc_CTF_OUTPUT_NUMBER-1 downto 0);
    signal data_out_vld  : std_logic;
    signal data_out_stop : std_logic := '0';

    signal hbm_buffer_data_out        : t_ctf_hbm_data;
    signal hbm_buffer_data_out_vld    : std_logic;
    signal hbm_buffer_data_out_stop   : std_logic := '0';

    signal port_done : std_logic_vector(pc_CTF_OUTPUT_NUMBER-1 downto 0) := (others => '0');

    signal hbm_rst   : std_logic;
    signal hbm_mosi  : t_axi4_full_mosi;
    signal hbm_miso  : t_axi4_full_miso;
    signal hbm_ready : std_logic;    

    signal unused_mosi   : t_axi4_full_mosi;
    signal hbm_mace_mosi : t_axi4_full_mosi;

    signal saxi_mosi : t_axi4_lite_mosi;
    signal saxi_miso : t_axi4_lite_miso;

    signal MTA_ready  : std_logic := '0';
    signal MACE_ready : std_logic := '0';

    signal cor_stop   : std_logic;

begin

    ---------------------------------------------------------------------------------------------------
    -- HBM
    ---------------------------------------------------------------------------------------------------
    unused_mosi.wvalid <= '0';
    unused_mosi.awvalid <= '0';
    unused_mosi.arvalid <= '0';

    hbm_mace_mosi.wvalid <= '0';
    hbm_mace_mosi.awvalid <= '0';
    hbm_mace_mosi.arvalid <= '0';
    
    GEN_HBM: if g_USE_HBM generate
    begin
        E_HBM: entity ct_hbm_lib.hbm_wrapper
        Port Map (
            i_hbm_ref_clk       => apb_clk, 
            i_axi_clk           => hbm_clk, 
            i_axi_clk_rst       => hbm_rst,
            i_saxi_00           => unused_mosi,
            o_saxi_00           => open,
            i_saxi_14           => hbm_mace_mosi,
            o_saxi_14           => open,
            i_saxi_15           => hbm_mosi,
            o_saxi_15           => hbm_miso,
            o_apb_complete      => hbm_ready,
            i_apb_clk           => apb_clk   
        );
    else generate
        hbm_ready <= '1';
    end generate;


    --------------------------------------------
    -- DUT: CTF
    --------------------------------------------
    E_DUT: entity work.ctf
    generic map (
        g_USE_HBM           => g_USE_HBM,
        g_HBM_AXI_PORT      => g_HBM_AXI_PORT,
        g_HBM_EMU_STUTTER   => g_HBM_EMU_STUTTER,
        g_HBM_BURST_LENGTH  => g_HBM_BURST_LENGTH,
        g_COARSE_CHANNELS   => g_COARSE_CHANNELS,
        g_STATION_GROUPS    => g_STATION_GROUPS,
        g_TIME_STAMPS       => g_TIME_STAMPS,
        g_FINE_CHANNELS     => g_FINE_CHANNELS,
        g_OUTPUT_BURST_SIZE => g_CTF_OUTPUT_BUST_SIZE
    ) port map (
        i_mace_clk       => mace_clk,
        i_mace_clk_rst   => mace_clk_rst,
        o_saxi_miso      => saxi_miso,
        i_saxi_mosi      => saxi_mosi,
        i_input_clk      => input_clk,
        i_hbm_clk        => hbm_clk,
        i_data_in        => data_in_slv,
        i_data_in_record => data_in,
        i_data_in_vld    => data_in_vld, 
        o_data_in_stop   => data_in_stop,
        o_data_out       => data_out,
        o_header_out     => header_out,
        o_data_out_vld   => data_out_vld,
        i_data_out_stop  => cor_stop or data_out_stop,
        --DEBUG--
        o_hbm_buffer_data_out      => hbm_buffer_data_out,
        o_hbm_buffer_data_out_vld  => hbm_buffer_data_out_vld,
        --HBM--
        o_hbm_clk_rst => hbm_rst,
        o_hbm_mosi    => hbm_mosi,
        i_hbm_miso    => hbm_miso,
        i_hbm_ready   => hbm_ready        
    );
    

    --##########################################################################################################################
    -- <BEGIN CORRELATOR>
    --##########################################################################################################################
    E_CORRLELATOR: if g_SIMULATE_COR=true generate
        constant g_MAX_CHANNEL_AVERAGE     : integer := 8; -- maximum number of channels that can be averaged. e.g. 8
        constant g_SAMPLE_WIDTH            : integer := 8; -- re and im are 8 bit wide
        constant g_NUM_CHANNELS            : integer := g_FINE_CHANNELS;

        constant g_NUM_OF_NON_AUTO_SLOTS       : natural := g_ANTENNA_PER_COL * (g_ANTENNA_PER_COL-1) / 2;
        constant g_NUM_OF_AUTO_SLOTS           : natural := (g_ANTENNA_PER_COL+1) / 2;
        constant g_NUM_OF_SLOTS                : natural := g_NUM_OF_NON_AUTO_SLOTS + g_NUM_OF_AUTO_SLOTS;
        constant g_NUMBER_OF_BASELINES_PER_COL : natural := g_NUM_OF_AUTO_SLOTS*(g_COL_DIMENSION+1) + g_NUM_OF_NON_AUTO_SLOTS*g_COL_DIMENSION;

        constant c_MTA_ACCUM_SAMPLES : natural := g_COR_NUM_SAMPLES * g_CMAC_DUMPS_PER_MTA_DUMP;
        constant c_MTA_ACCUM_WIDTH   : natural := f_cmac_accum_width(g_SAMPLE_WIDTH, c_MTA_ACCUM_SAMPLES, g_MAX_CHANNEL_AVERAGE);
        
        constant c_NUMBER_OF_PAGES : natural := 4;

        type ant_array2  is array(0 to g_ANTENNA_PER_COL*g_COL_DIMENSION-1, 0 to g_COR_NUM_SAMPLES*g_CMAC_DUMPS_PER_MTA_DUMP-1) of integer;

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

        signal cci_progs : t_cci_ram_wr_reg_a(g_COL_DIMENSION-1 downto 0) := (others => T_CCI_RAM_WR_REG_ZERO);
    
        signal tdm_cache_wr_bus : t_tdm_cache_wr_bus_a(g_COL_DIMENSION-1 downto 0);
        signal wr_stop          : std_logic_vector(g_COL_DIMENSION-1 downto 0);

        signal cor_context : t_visibility_context;
        signal context_vld : std_logic := '0';
        signal context_rdy : std_logic;
        
        signal cor_ts : std_logic_vector(31 downto 0);
        
        type acc_array is array(0 to c_NUMBER_OF_PAGES-1, 0 to g_ANTENNA_PER_COL*g_COL_DIMENSION-1, 0 to g_ANTENNA_PER_COL*g_COL_DIMENSION-1) of integer;
        signal s_acc_XX_re, s_acc_XX_im   : acc_array := (others => (others => (others => 0)));
        signal s_acc_XY_re, s_acc_XY_im   : acc_array := (others => (others => (others => 0)));
        signal s_acc_YX_re, s_acc_YX_im   : acc_array := (others => (others => (others => 0)));
        signal s_acc_YY_re, s_acc_YY_im   : acc_array := (others => (others => (others => 0)));
    
        signal mta_data_frames : t_mta_data_frame_a(g_COL_DIMENSION-1 downto 0);
        signal mta_vld         : std_logic_vector(g_COL_DIMENSION-1 downto 0);

        signal bl_count : integer := 0;
        
        signal context_vld_p1 : std_logic;
        signal context_vld_p2 : std_logic;
        

    begin

        --------------------------------------------
        -- COR: PROGRAM THE MTA
        --------------------------------------------
        P_PROGRAM_MTA : process is
        begin
    
            wait until hbm_rst = '0';       
            wait for 200 ns;
            wait until rising_edge(hbm_clk);
            
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
            
            wait for 100 ns;
            
            MTA_ready <= '1';
            
            wait;
        end process;

        --------------------------------------------
        -- CTF -> COR
        --------------------------------------------
        -- Here we are only instantiating and 
        -- connecting the first correllator of
        -- the 4 for PISA
        --------------------------------------------
        P_CTF_OUT_TO_COR_IN: process is
            variable X_re, X_im, Y_re, Y_im : ant_array2;
            variable first : boolean;
            variable ant : integer := 0;
            variable idx : integer := 0;
            variable lap : integer := 0;
            variable w_page : integer := 0;
            variable acc_XX_re, acc_XX_im   : acc_array := (others => (others => (others => 0)));
            variable acc_XY_re, acc_XY_im   : acc_array := (others => (others => (others => 0)));
            variable acc_YX_re, acc_YX_im   : acc_array := (others => (others => (others => 0)));
            variable acc_YY_re, acc_YY_im   : acc_array := (others => (others => (others => 0)));
        begin
            
            wait until rising_edge (hbm_clk);
            
            --defaults:
            context_vld <= '0';
            context_vld_p1 <= context_vld;
            context_vld_p2 <= context_vld_p1;
            
            
            if hbm_rst='1' then
                context_vld_p1 <= '0';
                context_vld_p2 <= '0';
                cor_context.tdm_lap_start <= '0';  --set internally
                cor_context.tdm_lap       <= to_unsigned(0, 08);
                cor_context.channel       <= to_unsigned(0, 16);
                cor_context.timestamp     <= to_unsigned(0, 32);
                for cache in 0 to g_COL_DIMENSION-1 loop
                    tdm_cache_wr_bus(cache).dbl_buf_sel <= '0';
                end loop;
                ant := 0;
                idx := 0;
                lap := 0;
                w_page := 0;    
                first  := true;
            else
                for cache in 0 to g_COL_DIMENSION-1 loop
                    if data_out_vld='1' then
                        X_re(ant*g_COL_DIMENSION+cache, idx+lap*g_COR_NUM_SAMPLES) := to_integer(signed(data_out(0)(2*cache+0).data.re));
                        X_im(ant*g_COL_DIMENSION+cache, idx+lap*g_COR_NUM_SAMPLES) := to_integer(signed(data_out(0)(2*cache+0).data.im));
                        Y_re(ant*g_COL_DIMENSION+cache, idx+lap*g_COR_NUM_SAMPLES) := to_integer(signed(data_out(0)(2*cache+1).data.re));
                        Y_im(ant*g_COL_DIMENSION+cache, idx+lap*g_COR_NUM_SAMPLES) := to_integer(signed(data_out(0)(2*cache+1).data.im));
    
                        tdm_cache_wr_bus(cache).real_polX   <= to_signed(X_re(ant*g_COL_DIMENSION+cache, idx+lap*g_COR_NUM_SAMPLES), 9);   
                        tdm_cache_wr_bus(cache).imag_polX   <= to_signed(X_im(ant*g_COL_DIMENSION+cache, idx+lap*g_COR_NUM_SAMPLES), 9);       
                        tdm_cache_wr_bus(cache).real_polY   <= to_signed(Y_re(ant*g_COL_DIMENSION+cache, idx+lap*g_COR_NUM_SAMPLES), 9); 
                        tdm_cache_wr_bus(cache).imag_polY   <= to_signed(Y_im(ant*g_COL_DIMENSION+cache, idx+lap*g_COR_NUM_SAMPLES), 9);       
                        tdm_cache_wr_bus(cache).wr_addr     <= to_unsigned(ant * f_ADDR_STRIDE(g_ANTENNA_PER_COL, g_COR_NUM_SAMPLES) + idx, 16);
                        tdm_cache_wr_bus(cache).wr_enable   <= '1';
                    else
                        tdm_cache_wr_bus(cache).wr_enable   <= '0';
                    end if;   
                end loop;       
                
                if data_out_vld='1' then        

                    if ant=0 and idx=0 then
                        if first=false then
                            for cache in 0 to g_COL_DIMENSION-1 loop
                                tdm_cache_wr_bus(cache).dbl_buf_sel <= not tdm_cache_wr_bus(cache).dbl_buf_sel;
                            end loop;
                        else
                            first := false;
                        end if;            
                        cor_ts <= header_out(0).timestamp(31 downto 0); --todo: extend cor_timestamp to 43bit
                    end if;

                    if ant<g_ANTENNA_PER_COL-1 then
                        ant:=ant+1;
                    else
                        ant:=0;
                        if idx<g_COR_NUM_SAMPLES-1 then
                            idx:=idx+1;
                        else
                            --SET CONTEXT 
                            cor_context.channel(header_out(0).fine'range) <= unsigned(header_out(0).fine);
                            cor_context.timestamp  <= unsigned(cor_ts);
                            cor_context.tdm_lap    <= to_unsigned(lap, 08);
                            context_vld <= '1';

                            if lap=0 then                
                                for col in 0 to g_ANTENNA_PER_COL*g_COL_DIMENSION-1 loop
                                    for row in 0 to g_ANTENNA_PER_COL*g_COL_DIMENSION-1 loop
                                        acc_XX_im(w_page, row, col) := 0;
                                        acc_XX_re(w_page, row, col) := 0;
                                        acc_YX_im(w_page, row, col) := 0;
                                        acc_YX_re(w_page, row, col) := 0;
                                        acc_XY_im(w_page, row, col) := 0;
                                        acc_XY_re(w_page, row, col) := 0;
                                        acc_YY_im(w_page, row, col) := 0;
                                        acc_YY_re(w_page, row, col) := 0;
                                    end loop;
                                end loop;
                            end if;
                            

                            --EMULATE THE COR: CALCULATE SIMULATION TEST VALUE
                            for col in 0 to g_ANTENNA_PER_COL*g_COL_DIMENSION-1 loop
                                for row in 0 to g_ANTENNA_PER_COL*g_COL_DIMENSION-1 loop
                                    for s in g_COR_NUM_SAMPLES*lap to g_COR_NUM_SAMPLES*(lap+1)-1  loop
                                        acc_XX_im(w_page, row, col) := acc_XX_im(w_page, row, col) + X_im(row, s) * X_re(col, s) + X_re(row,s) * (-X_im(col,s));
                                        acc_XX_re(w_page, row, col) := acc_XX_re(w_page, row, col) + X_re(row, s) * X_re(col, s) - X_im(row,s) * (-X_im(col,s));
                
                                        acc_YX_im(w_page, row, col) := acc_YX_im(w_page, row, col) + Y_im(row, s) * X_re(col, s) + Y_re(row,s) * (-X_im(col,s));
                                        acc_YX_re(w_page, row, col) := acc_YX_re(w_page, row, col) + Y_re(row, s) * X_re(col, s) - Y_im(row,s) * (-X_im(col,s));
                
                                        acc_XY_im(w_page, row, col) := acc_XY_im(w_page, row, col) + X_im(row, s) * Y_re(col, s) + X_re(row,s) * (-Y_im(col,s));
                                        acc_XY_re(w_page, row, col) := acc_XY_re(w_page, row, col) + X_re(row, s) * Y_re(col, s) - X_im(row,s) * (-Y_im(col,s));
                
                                        acc_YY_im(w_page, row, col) := acc_YY_im(w_page, row, col) + Y_im(row, s) * Y_re(col, s) + Y_re(row,s) * (-Y_im(col,s));
                                        acc_YY_re(w_page, row, col) := acc_YY_re(w_page, row, col) + Y_re(row, s) * Y_re(col, s) - Y_im(row,s) * (-Y_im(col,s));
                                    end loop;
                                end loop;
                            end loop;      

                            for col in 0 to g_ANTENNA_PER_COL*g_COL_DIMENSION-1 loop
                                for row in 0 to g_ANTENNA_PER_COL*g_COL_DIMENSION-1 loop
                                    s_acc_XX_im(w_page, row, col) <= acc_XX_im(w_page, row, col);
                                    s_acc_XX_re(w_page, row, col) <= acc_XX_re(w_page, row, col);
                                    s_acc_YX_im(w_page, row, col) <= acc_YX_im(w_page, row, col);
                                    s_acc_YX_re(w_page, row, col) <= acc_YX_re(w_page, row, col);
                                    s_acc_XY_im(w_page, row, col) <= acc_XY_im(w_page, row, col);
                                    s_acc_XY_re(w_page, row, col) <= acc_XY_re(w_page, row, col);
                                    s_acc_YY_im(w_page, row, col) <= acc_YY_im(w_page, row, col);
                                    s_acc_YY_re(w_page, row, col) <= acc_YY_re(w_page, row, col);
                                end loop;
                            end loop;      

                            idx:=0;
                            
                            if lap<g_CMAC_DUMPS_PER_MTA_DUMP-1 then
                                lap:=lap+1;
                            else
                                lap:=0;
                                w_page := (w_page + 1) mod c_NUMBER_OF_PAGES; 
                            end if;        
                        end if;
                    end if;
                end if;   
             end if;   
        end process;

        
        --------------------------------------------
        -- DUT: COR
        --------------------------------------------
        E_DUT_COR: entity cor_lib.cmac_array
        generic map (
            g_COL_DIMENSION   => g_COL_DIMENSION,    -- [natural]
            g_ANTENNA_PER_COL => g_ANTENNA_PER_COL,  -- [natural]
            g_NUM_SAMPLES     => g_COR_NUM_SAMPLES,  -- [natural]
            g_CMAC_DUMPS_PER_MTA_DUMP => g_CMAC_DUMPS_PER_MTA_DUMP,
            g_MAX_CHANNEL_AVERAGE => g_MAX_CHANNEL_AVERAGE,
            g_SAMPLE_WIDTH    => g_SAMPLE_WIDTH,
            g_NUM_CHANNELS    => g_NUM_CHANNELS)     -- [natural range 0 to 9]
        port map (
            -- Input data interface
            i_cturn_clks       => (others => hbm_clk),  -- [std_logic]
            i_cturn_clk_resets => (others => hbm_rst),  -- [std_logic]
            i_tdm_cache_wr_bus => tdm_cache_wr_bus,     -- [t_tdm_cache_wr_bus_a(g_COL_DIMENSION-1 downto 0)]
            o_wr_stop          => wr_stop,
    
            --Context interface
            i_ctx_clk          => hbm_clk,
            i_ctx_clk_reset    => hbm_rst,
            i_context          => cor_context,  -- t_visibility_context;
            i_context_vld      => context_vld_p2,  -- set high when new context is available.
            o_context_ready    => context_rdy,  -- high when new context is accepted.
    
            --Programming interface
            i_cci_progs        => cci_progs, -- t_cci_ram_wr_reg_a(g_COL_DIMENSION-1 downto 0);
    
            -- Output Interface to Debursting Buffer
            i_cmac_clk         => hbm_clk,
            i_cmac_clk_reset   => hbm_rst,
            o_mta_context      => open,
            o_mta_context_vld  => open,
            o_mta_data_frame   => mta_data_frames, 
            o_mta_vld          => mta_vld  
        );
        
        cor_stop <= OR(wr_stop); --this is a stop of size g_COR_NUM_SAMPLES

        --------------------------------------------
        -- COR: OUTPUT CHECKER
        --------------------------------------------
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
            
            variable r_page : natural := 0;

        begin

            wait until rising_edge(hbm_clk);
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
                        
                        check_equal(mta_xx_im, s_acc_XX_im(r_page, coordinates.row, coordinates.col), "XX Imaginary" & loc_string.all);  
                        check_equal(mta_xx_re, s_acc_XX_re(r_page, coordinates.row, coordinates.col), "XX Real" & loc_string.all);
                        if coordinates.au then
                            -- In auto correlations one of XY or YX will be correct, the other will be zero, depending on if it is above or
                            -- below the diagonal.
                            if mta_yx_re = 0 then
                                check_equal(mta_xy_im, s_acc_XY_im(r_page, coordinates.row, coordinates.col), "XY Imaginary" & loc_string.all);  
                                check_equal(mta_xy_re, s_acc_XY_re(r_page, coordinates.row, coordinates.col), "XY Real" & loc_string.all);
                            else
                                check_equal(mta_yx_im, s_acc_YX_im(r_page, coordinates.row, coordinates.col), "YX Imaginary" & loc_string.all);  
                                check_equal(mta_yx_re, s_acc_YX_re(r_page, coordinates.row, coordinates.col), "YX Real" & loc_string.all);
                            end if;
                        else
                            check_equal(mta_yx_im, s_acc_YX_im(r_page, coordinates.row, coordinates.col), "YX Imaginary" & loc_string.all);  
                            check_equal(mta_yx_re, s_acc_YX_re(r_page, coordinates.row, coordinates.col), "YX Real" & loc_string.all);  
                            check_equal(mta_xy_im, s_acc_XY_im(r_page, coordinates.row, coordinates.col), "XY Imaginary" & loc_string.all);  
                            check_equal(mta_xy_re, s_acc_XY_re(r_page, coordinates.row, coordinates.col), "XY Real" & loc_string.all);
                        end if;
                        check_equal(mta_yy_im, s_acc_YY_im(r_page, coordinates.row, coordinates.col), "YY Imaginary" & loc_string.all);  
                        check_equal(mta_yy_re, s_acc_YY_re(r_page, coordinates.row, coordinates.col), "YY Real" & loc_string.all);  
                    else
                        assert false report "Invalid data filtered out at baseline " & integer'image(baseline) severity NOTE;
                    end if;
    
                end if;
            end loop;
    
            bl_count <= bl_count + baslines_vld_cnt;
            wait for 0 ns;
            
            if or(mta_vld)='1' and bl_count=g_COL_DIMENSION*g_NUMBER_OF_BASELINES_PER_COL then
                r_page   := (r_page+1) mod c_NUMBER_OF_PAGES;
                bl_count <= 0;
            end if;            
    
        end process;
    
    else generate --NO COR
    
        MTA_ready <= '1';
        cor_stop  <= '0';    
    
    end generate;
    --##########################################################################################################################
    -- <END CORRELATOR>
    --########################################################################################################################## 


    --------------------------------------------
    -- ClOCKS AND RESETS
    --------------------------------------------
    rst <= '0', '1' after 10 ns, '0' after 100 us;  

    --450MHz
    hbm_clk <= not hbm_clk after 1.111 ns;

    --100MHz
    apb_clk <= not apb_clk after 5 ns;

    --420MHz
    input_clk <= not input_clk after 1.2 ns;

    --100MHz
    mace_clk <= not mace_clk after 5 ns;
    


    ---------------------------------------------------------------------------------------------------
    -- MACE
    ---------------------------------------------------------------------------------------------------
    P_MACE: process
    begin
        wait for 10 us;
        wait until rising_edge(mace_clk);
        
        -- For some reason the first transaction doesn't work; this is just a dummy transaction
        axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_setup_full_reset_address), true, x"00000001");
        wait until rising_edge(mace_clk);

        --turn mace reset on 
        axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_setup_full_reset_address), true, x"00000001");
        
        --STATIONS:
        for adr in 0 to g_STATION_GROUPS-1 loop
            axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_stations_table_address)+adr, true,
                                 std_logic_vector(to_unsigned(2*adr+1, 16) & to_unsigned(2*adr+0, 16)));
        end loop;        

        --turn mace reset off 
        axi_lite_transaction(mace_clk, saxi_miso, saxi_mosi, addr(c_setup_full_reset_address), true, x"00000000");
        
        MACE_ready <= '1';
        
        wait;
        
    end process;

    --------------------------------------------
    -- INPUT STIMULUS
    --------------------------------------------
    P_STIMULUS: process
        variable seed1: positive := 1;
        variable seed2: positive := 1; -- all 4 ports have to behave the same in terms of stutter 
        variable rand: real;
        variable dice: integer;
        variable header     : t_ctf_input_header;
        variable header_slv : std_logic_vector(127 downto 0);
    begin
        wait until rising_edge(rst);
        wait until falling_edge(rst);
        wait until rising_edge(input_clk);
        wait until rising_edge(input_clk);
        wait until rising_edge(input_clk);
        wait until rising_edge(input_clk);
        wait until rising_edge(input_clk);
        
        for coarse in 0 to g_COARSE_CHANNELS-1 loop
            for st_group in 0 to g_STATION_GROUPS-1 loop
                for ts in 0 to g_TIME_STAMPS-1 loop
                    
                    while data_in_stop='1' or MTA_ready='0' or MACE_ready='0' loop
                        data_in_vld <= '0';
                        wait until rising_edge(input_clk);
                    end loop;
                
                    --header:
                    header.timestamp         := std_logic_vector(to_unsigned(ts, 44));
                    header.virtual_channel   := std_logic_vector(to_unsigned(coarse, 9));
                    header.station_id_1      := std_logic_vector(to_unsigned(2*st_group+0, 9));
                    header.station_id_2      := std_logic_vector(to_unsigned(2*st_group+1, 9));
                    header.reserved          := (others => '0');
                    header_slv               := header_to_slv(header);

                    data_in_slv              <= header_slv(63 downto 0);
                    data_in_vld              <= '1';
                    wait until rising_edge(input_clk);
                    
                    data_in_slv              <= header_slv(127 downto 64);
                    data_in_vld              <= '1';
                    wait until rising_edge(input_clk);
                    
                    for fine in 0 to g_FINE_CHANNELS-1 loop
                        
                        --stutter & stop logic
                        uniform(seed1, seed2, rand);
                        if g_PROVOKE_EMPTY then
                            dice := integer(rand*2.0);
                        else    
                            dice := integer(rand*10.0);
                        end if;    
                        while (g_PROVOKE_EMPTY and dice/=1) or (g_INPUT_STUTTER and not g_PROVOKE_EMPTY and dice=1) loop
                            data_in_vld <= '0';
                            wait until rising_edge(input_clk);
                            uniform(seed1, seed2, rand);
                            if g_PROVOKE_EMPTY then
                                dice := integer(rand*2.0);
                            else
                                dice := integer(rand*10.0);
                            end if;    
                        end loop;
                        
                        --data generator
                        for in_port in 0 to pc_CTF_INPUT_NUMBER-1 loop
                            data_in(in_port).data.im       <= std_logic_vector(to_unsigned(in_port  + ts*16,   7)) & B"1"; --leave out the 8th bit to avoid accidental -128
                            data_in(in_port).data.re       <= std_logic_vector(to_unsigned(st_group + fine*16, 7)) & B"1"; --leave out the 8th bit to avoid accidental -128
                            data_in(in_port).meta.coarse   <= std_logic_vector(to_unsigned(coarse, 9));
                            data_in(in_port).meta.st_group <= std_logic_vector(to_unsigned(st_group, 4));
                            data_in(in_port).meta.station  <= std_logic_vector(to_unsigned((in_port/2)+(2*st_group), 9));
                            data_in(in_port).meta.pol      <= std_logic_vector(to_unsigned((in_port rem 2), 1));
                            data_in(in_port).meta.ts       <= std_logic_vector(to_unsigned(ts, 32));
                            data_in(in_port).meta.fine     <= std_logic_vector(to_unsigned(fine, 13));
                            wait for 1 ps;
                            data_in_slv((in_port+1)*16-1 downto in_port*16) <= payload_to_slv(data_in(in_port).data);
                        end loop;
                        data_in_vld <= '1';
                        wait until rising_edge(input_clk);
                        
                    end loop;        
                end loop;        
            end loop;
        end loop;
        
        data_in_vld <= '0';
        wait until rising_edge(input_clk);
        wait until rising_edge(input_clk);
        wait until rising_edge(input_clk);
        wait until rising_edge(input_clk);
        
        wait;
            
    end process; 


       
    --------------------------------------------
    -- HBM OUTPUT CHECKER
    --------------------------------------------
    P_HBM_OUTPUT_CHECKER: process
        variable o  : natural;  
        variable u  : natural;
        variable fine : natural;
        variable seg  : natural;
        variable ts   : natural;
    begin
        wait until rising_edge(rst);
        wait until falling_edge(rst);
        wait until rising_edge(hbm_clk);
        
        while hbm_buffer_data_out_vld='0' loop
            wait until rising_edge(hbm_clk);
        end loop;
        for coarse in 0 to g_COARSE_CHANNELS-1 loop
           for outer_fine in 0 to g_FINE_CHANNELS/pc_CTF_OUTPUT_NUMBER-1 loop
               for outer_ts in 0 to g_TIME_STAMPS/g_HBM_BURST_LENGTH-1 loop
                   for st_group in 0 to g_STATION_GROUPS-1 loop
                       for inner_ts in 0 to g_HBM_BURST_LENGTH-1 loop
                           ts := outer_ts*g_HBM_BURST_LENGTH + inner_ts;
                           while hbm_buffer_data_out_vld='0' loop
                               wait until rising_edge(hbm_clk);
                           end loop;
                           for inner_fine in 0 to pc_CTF_OUTPUT_NUMBER-1 loop
                               fine := pc_CTF_OUTPUT_NUMBER*outer_fine + inner_fine;
                               for segment in 0 to (16/pc_CTF_OUTPUT_NUMBER)-1 loop
                                   seg := inner_fine*(16/pc_CTF_OUTPUT_NUMBER) + segment;
                                   o := (15-seg)*16+15;
                                   u := (15-seg)*16;
                                   check_equal(unsigned(hbm_buffer_data_out.meta(15-seg).coarse),   coarse,                   "HBM Coarse Channel wrong!");
                                   check_equal(unsigned(hbm_buffer_data_out.meta(15-seg).st_group), st_group,                 "HBM Station Group wrong!");
                                   check_equal(unsigned(hbm_buffer_data_out.meta(15-seg).station),  (segment/2)+(st_group*2), "HBM Station wrong!");
                                   check_equal(unsigned(hbm_buffer_data_out.meta(15-seg).pol),      (segment rem 2),          "HBM Polarity wrong!");
                                   check_equal(unsigned(hbm_buffer_data_out.meta(15-seg).ts),       ts,                       "HBM Timestamp wrong!");
                                   check_equal(unsigned(hbm_buffer_data_out.meta(15-seg).fine),     fine,                     "HBM Fine Channel wrong!");

                                   check_equal(unsigned(hbm_buffer_data_out.data(o-8 downto u+0)), to_unsigned(segment  + (ts*16), 7) & B"1", "HBM Imaginary value wrong!");
                                   check_equal(unsigned(hbm_buffer_data_out.data(o-0 downto u+8)), to_unsigned(st_group + fine*16, 7) & B"1", "HBM Real value wrong!");
                                   
                               end loop;
                           end loop;        
                           wait until rising_edge(hbm_clk);
                        end loop;        
                    end loop;
               end loop;             
           end loop;
       end loop;    
      
       wait;
    end process;



    --------------------------------------------
    -- CTF OUTPUT CHECKER
    --------------------------------------------
    GEN_OUTPUT_STUTTER: if g_OUTPUT_STUTTER generate
    begin 
        P_OUTPUT_STUTTER: process
            variable seed1: positive := 2;
            variable seed2: positive := 1;
            variable rand: real;
            variable dice: integer;
        begin
            uniform(seed1, seed2, rand);
            dice := integer(rand*2.0);
            if dice=1 then
                data_out_stop <= '1';
            else
                data_out_stop <= '0';
            end if;
            wait until rising_edge(hbm_clk);    
        end process;
    end generate;


    GEN_OUTPUT_CHECKER: for out_port in 0 to pc_CTF_OUTPUT_NUMBER-1 generate
    begin
        P_OUTPUT_CHECKER: process
            variable fine    : natural;
            variable station : natural;
        begin
            wait until rising_edge(rst);
            wait until falling_edge(rst);
            wait until rising_edge(hbm_clk);
            
            report "SIMULATION STARTED." severity NOTE;
            
            while data_out_vld='0' loop
                wait until rising_edge(hbm_clk);
            end loop;
            for coarse in 0 to g_COARSE_CHANNELS-1 loop
               for outer_fine in 0 to g_FINE_CHANNELS/pc_CTF_OUTPUT_NUMBER-1 loop
                   for ts in 0 to g_TIME_STAMPS-1 loop
                       for st_group in 0 to g_STATION_GROUPS-1 loop
                           while data_out_vld='0' loop
                               wait until rising_edge(hbm_clk);
                           end loop;
                           fine := pc_CTF_OUTPUT_NUMBER*outer_fine + out_port;
                           for inner_station in 0 to pc_CTF_OUTPUT_NUMBER-1 loop
                               station := st_group*4+inner_station;
                               check_equal(unsigned(data_out(out_port)(inner_station).meta.coarse),   coarse,        "Coarse Channel wrong!");
                               check_equal(unsigned(data_out(out_port)(inner_station).meta.st_group), st_group,      "Station Group wrong!");
                               check_equal(unsigned(data_out(out_port)(inner_station).meta.station),  station/2,     "Station wrong!");
                               check_equal(unsigned(data_out(out_port)(inner_station).meta.pol),      station rem 2, "Polarity wrong!");
                               check_equal(unsigned(data_out(out_port)(inner_station).meta.ts),       ts,            "Timestamp wrong!");
                               check_equal(unsigned(data_out(out_port)(inner_station).meta.fine),     fine,          "Fine Channel wrong!");
                               
                               check_equal(unsigned(data_out(out_port)(inner_station).data.im), to_unsigned(inner_station  + (ts*16), 7) & B"1", "Imaginary value wrong!");
                               check_equal(unsigned(data_out(out_port)(inner_station).data.re), to_unsigned(st_group + fine*16, 7) & B"1",       "Real value wrong!");
                           end loop;
                           
                           check_equal(unsigned(data_out(out_port)(0).meta.ts),      unsigned(header_out(out_port).timestamp),       "HEADER: Virtual Channel wrong!"); 
                           check_equal(unsigned(data_out(out_port)(0).meta.coarse),  unsigned(header_out(out_port).virtual_channel), "HEADER: Virtual Channel wrong!"); 
                           check_equal(unsigned(data_out(out_port)(0).meta.station), unsigned(header_out(out_port).station_id_1),    "HEADER: Station_ID_1 wrong!"); 
                           check_equal(unsigned(data_out(out_port)(2).meta.station), unsigned(header_out(out_port).station_id_2),    "HEADER: Station_ID_2 wrong!"); 
                           check_equal(unsigned(data_out(out_port)(0).meta.fine),    unsigned(header_out(out_port).fine),            "HEADER: Fine wrong!"); 
                           
                           wait until rising_edge(hbm_clk);
                        end loop;
                   end loop;             
               end loop;
           end loop;    
           
           wait for 1 us;
           
           report "PORT " & integer'image(out_port) & " DONE." severity NOTE;
           port_done(out_port) <= '1'; 
                   
           wait;
               
        end process;
    end generate;
    
    process
    begin
        wait until port_done=(port_done'range=>'1');

        wait for 50 us;

        echoln;
        echoln("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        echoln("!                             !");
        echoln("!     SIMULATION FINISHED     !");
        echoln("!                             !");
        echoln("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        echoln;
        
        stop(2); --end simulation
        

        wait;
    end process;    


    
end sim;
