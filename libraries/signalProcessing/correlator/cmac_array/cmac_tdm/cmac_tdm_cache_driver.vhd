-------------------------------------------------------------------------------
-- Title      : CMAC Time-division multiplexing cache and row/column driver
-- Project    : 
-------------------------------------------------------------------------------
-- File       : cmac_tdm_cache_driver.vhd
-- Author     : William Kamp  <william.kamp@aut.ac.nz>
-- Company    : High Performance Computing Research Lab, Auckland University of Technology
-- Created    : 2017-05-01
-- Last update: 2018-07-10
-- Platform   : 
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Drives the CMAC Array with the packets from the correct antenna and polarisation
-- at the right time and to both the column the row.
--
-- Samples are loaded into the sample cache by the Corner Turner. The cache is double buffered.
-- These are then read out according to a ROM or start addresses and a polarity selector.
-- The polarity selector operates a MUX on the output data. For the row driver this allows both polarities to be output
-- at once, as is required for the auto-correlation TDM slots.
-------------------------------------------------------------------------------
-- Copyright (c) 2017 High Performance Computing Research Lab, Auckland University of Technology
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-05-01  1.0      will    Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.misc_tools_pkg.all;            -- ceil_pow2
use work.cmac_tdm_pkg.all;              -- t_tdm_rd_ctrl, f_ADDR_STRIDE

library work;
use work.misc_tools_pkg.all;                  -- ceil_log2

entity cmac_tdm_cache_driver is

    generic (
        g_ANTENNA_PER_COL : natural range 1 to pc_MAX_ANTENNA_PER_COL;  -- g_NUM_ANTENNA/g_COL_DIMENSION
        g_NUM_SAMPLES     : natural range 4 to pc_MAX_NUM_SAMPLES       -- number of samples in a sub-accumulation.
                                                                        -- set for memory efficiency i.e 512/g_ANTENNA_PER_COL.
        );

    port (
        i_clk         : in  std_logic;
        i_clk_reset   : in  std_logic;
        i_start       : in  std_logic;
        o_started     : out std_logic;
        o_col_rd_ctrl : out t_tdm_rd_ctrl;
        o_row_rd_ctrl : out t_tdm_rd_ctrl;
        o_tdm_slot    : out unsigned;
        o_tdm_first   : out std_logic;
        o_tdm_last    : out std_logic
        );

end entity cmac_tdm_cache_driver;

architecture rtl of cmac_tdm_cache_driver is

    constant c_ADDR_LEN      : natural := ceil_log2(g_ANTENNA_PER_COL*g_NUM_SAMPLES);
    constant c_NUM_TDM_SLOTS : natural := (g_ANTENNA_PER_COL**2+1)/2;  -- triangle array.

    type t_tdm is record
        col_addr  : unsigned(c_ADDR_LEN-1 downto 0);
        row_addr  : unsigned(c_ADDR_LEN-1 downto 0);
        auto_corr : std_logic;
    --col_pol       : std_logic;      -- X = 0, Y = 1
    --row_left_pol  : std_logic;      -- X = 0, Y = 1
    --row_right_pol : std_logic;      -- X = 0, Y = 1
    end record t_tdm;

    constant c_TDM_UDEF : t_tdm := (
        col_addr  => (others => '-'),
        row_addr  => (others => '-'),
        auto_corr => '-'
     --col_pol       => '-',
     --row_left_pol  => '-',
     --row_right_pol => '-'
        );

    type t_tdm_a is array (natural range <>) of t_tdm;

    function get_addr (
        constant antenna : natural)
        return unsigned is
    begin
        return to_unsigned(
            antenna * f_ADDR_STRIDE(g_ANTENNA_PER_COL, g_NUM_SAMPLES),
            c_ADDR_LEN);
    end function get_addr;

    -- Function get_tdm_double_buffered(slot = 0..49 , num_cols = 10). e.g.
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
    -- Function reverses out the column and row from the given slot number
    -- Output is 
    --           0 -> rB cA
    --           1 -> rB cA
    --          ...-> r. cA
    --           8 -> rJ cA
    --           9 -> rB cA auto corr,  -- Antenna group A retired.
    --          10 -> rC cB
    --          ...-> r. cB
    --          17 -> rJ cB  -- Antenna group B retired.
    --          18 -> rD cC
    --          ...-> r. cC
    --          24 -> rJ cC
    --          25 -> rD cC auto corr,  -- Antenna group C retired.
    --          26 -> rE cD
    --          ...-> r. cD
    --          31 -> rJ cD  -- Antenna group D retired.
    --          32 -> rF cE
    --          ...-> r. cE
    --          36 -> rJ cE  
    --          37 -> rF cE auto corr, -- Antenna group E retired.
    --          etc.
    ------------------------------------------------------------
    function get_tdm_double_buffered (
        slot     : natural;
        num_cols : natural)
        return t_tdm is
        variable tdm : t_tdm;
    begin
        --report "Slot (" & integer'image(slot) & "), num_cols (" & integer'image(num_cols) & ")." severity note;
        assert slot < num_cols**2 report "Slot argument (" & integer'image(slot) & ") exceeds number of available TDM slots (" & integer'image(num_cols**2) & ")." severity failure;
        if slot < 2*num_cols-2 then
            -- First or second column.
            if slot < num_cols-1 then
                -- Down first column.
                tdm.col_addr  := get_addr(0);
                tdm.row_addr  := get_addr(slot+1);
                tdm.auto_corr := '0';
            elsif slot = num_cols-1 then
                -- Auto correlation
                tdm.col_addr  := get_addr(0);
                tdm.row_addr  := get_addr(1);
                tdm.auto_corr := '1';
            else
                -- Down second column.                
                tdm.col_addr  := get_addr(1);
                tdm.row_addr  := get_addr(slot-num_cols+2);
                tdm.auto_corr := '0';
            end if;
        elsif num_cols > 1 then
            -- recurse to next column and row.            
            tdm          := get_tdm_double_buffered(slot+2-2*num_cols, num_cols-2);
            tdm.row_addr := get_addr(2) + tdm.row_addr;
            tdm.col_addr := get_addr(2) + tdm.col_addr;
        else
            -- Auto correlation for the last slot of an odd TDM dimension
            tdm.col_addr  := get_addr(0); --invalid data (to be ignored by SDP)
            tdm.row_addr  := get_addr(0);
            tdm.auto_corr := '1';             
        end if;
        return tdm;
    end function get_tdm_double_buffered;

    function get_tdm (
        slot     : natural;
        num_cols : natural)
        return t_tdm is
    begin  -- function get_tdm
        return get_tdm_double_buffered(slot, num_cols);
    end function get_tdm;

    -- Function get_tdm_fifo_order(slot = 0..49 , num_cols = 10). e.g.
    -- "Sad" Order. Read across diagonal top-right to bottom-left, starting in the top left.
    ------------------------------------------------------------
    -- TDM   | Antenna group:
    -- SLOT  | A(0) B(1) C(2) D(3) E(4) F(5) G(6) H(7) I(8) J(9)
    ---------+--------------------------------------------------
    -- A(0)  |   0a
    -- B(1)  |   1   0a
    -- C(2)  |   2   3    5a  
    -- D(3)  |   4   6    8    5a
    -- E(4)  |   7   9    11   14   18a
    -- F(5)  |   10  12   15   19   23   18a
    -- G(6)  |   13  16   20   24   28   32   36a
    -- H(7)  |   17  21   25   29   33   37   40   36a
    -- I(8)  |   22  26   30   34   38   41   43   45   47a
    -- J(9)  |   27  31   35   39   42   44   46   48   49   47a
    ------------------------------------------------------------
    -- "Happy" order. Read across diagonal bottom-left to top-right, starting in the top left.
    ------------------------------------------------------------
    -- TDM   | Antenna group:
    -- SLOT  | A(0) B(1) C(2) D(3) E(4) F(5) G(6) H(7) I(8) J(9)
    ---------+--------------------------------------------------
    -- A(0)  |   0a
    -- B(1)  |   1   0a
    -- C(2)  |   2   4    7a  
    -- D(3)  |   3   6    10   7a
    -- E(4)  |   5   9    13   17   22a
    -- F(5)  |   8   12   16   21   27   22a
    -- G(6)  |   11  15   20   26   31   35   39a
    -- H(7)  |   14  19   25   30   34   38   42   39a
    -- I(8)  |   18  24   29   33   37   41   44   46   48a
    -- J(9)  |   23  28   32   36   40   43   45   47   49   48a
    ------------------------------------------------------------
    -- Function creates a ROM containing the column and row with slot number as address
    ------------------------------------------------------------
    function fill_tdm_rom_fifo_order(
        num_cols : natural)
        return t_tdm_a is
        variable tdm_rom   : t_tdm_a(0 to ceil_pow2(c_NUM_TDM_SLOTS)-1);
        variable start_row : integer := 0;
        variable start_col : integer := 0;
        variable auto_row  : integer := 0;
        variable row       : integer := 0;
        variable col       : integer := 0;
        variable idx       : natural := 0;
    begin
        tdm_rom := (others => c_TDM_UDEF);
        while idx < (num_cols**2+1)/2 loop
            if col = row then
                tdm_rom(idx).col_addr := get_addr(col+1);
                tdm_rom(idx).row_addr := get_addr(row);
                if row = auto_row then
                    tdm_rom(idx).auto_corr := '1';
                    auto_row               := auto_row + 2;
                else
                    tdm_rom(idx).auto_corr := '0';
                    idx                    := idx - 1;  -- undo, and overwrite next.
                end if;
            else
                tdm_rom(idx).col_addr  := get_addr(col);
                tdm_rom(idx).row_addr  := get_addr(row);
                tdm_rom(idx).auto_corr := '0';
            end if;
            idx := idx + 1;
            row := row - 1;
            col := col + 1;
            if col > row then
                -- Just past the diagonal. Reset to:
                if start_row = num_cols-1 then
                    -- bottom of triangle.
                    start_col := start_col + 1;
                else
                    -- left of triangle.
                    start_row := start_row + 1;
                end if;
                col := start_col;
                row := start_row;
            end if;
        end loop;
        return tdm_rom;
    end function fill_tdm_rom_fifo_order;

    function fill_tdm_rom_double_buffered_order (
        constant num_cols : natural)
        return t_tdm_a is
        variable tdm_rom : t_tdm_a(0 to ceil_pow2(c_NUM_TDM_SLOTS)-1);
    begin  -- function fill_rom
        tdm_rom := (others => c_TDM_UDEF);
        for i in 0 to c_NUM_TDM_SLOTS-1 loop
            tdm_rom(i) := get_tdm(i, num_cols);
        end loop;  -- i
        return tdm_rom;
    end function fill_tdm_rom_double_buffered_order;

    function fill_tdm_rom (
        constant num_cols : natural)
        return t_tdm_a is
        variable tdm_rom : t_tdm_a(0 to ceil_pow2(c_NUM_TDM_SLOTS)-1);
    begin  -- function fill_rom
        tdm_rom := (others => c_TDM_UDEF);
        return fill_tdm_rom_double_buffered_order(num_cols);
        --return fill_tdm_rom_fifo_order(num_cols);
    end function fill_tdm_rom;

    function from_bool (
        val : boolean)
        return std_logic is
    begin
        if val then
            return '1';
        end if;
        return '0';
    end function from_bool;

    constant c_TDM_SEL : t_tdm_a := fill_tdm_rom(g_ANTENNA_PER_COL);

    signal c1_running : std_logic;
    signal c2_running : std_logic;
    signal c3_running : std_logic;

    signal c1_dbl_buf_sel : std_logic;
    signal c3_dbl_buf_sel : std_logic;

    signal c2_next_in_3 : std_logic;
    signal c2_next_in_2 : std_logic;
    signal c2_next_in_1 : std_logic;

    signal c2_last_in_2 : std_logic;
    signal c2_last_in_1 : std_logic;

    signal c2_tdm_first   : std_logic;
    signal c3_tdm_first   : std_logic;
    signal c4_tdm_first   : std_logic;
    
    signal c3_tdm_last    : std_logic;
    signal c3_sample_last : std_logic;

    signal c3_tdm : t_tdm;

    signal c1_tdm_slot_reset : std_logic;
    signal c2_tdm_slot       : unsigned(ceil_log2(c_NUM_TDM_SLOTS)-1 downto 0);
    signal c3_tdm_slot       : unsigned(c2_tdm_slot'range);
    signal c4_tdm_slot       : unsigned(c2_tdm_slot'range);
    signal c2_sample_cnt     : unsigned(ceil_log2(g_NUM_SAMPLES)-1 downto 0);
    signal c3_sample_cnt     : unsigned(ceil_log2(g_NUM_SAMPLES)-1 downto 0);

    signal c4_col_rd_ctrl : t_tdm_rd_ctrl;
    signal c4_row_rd_ctrl : t_tdm_rd_ctrl;
    signal c4_tdm_last : std_logic;
    
begin  -- architecture rtl

    P_TDM_MEMORY_GEN : process (i_clk) is
    begin
        if rising_edge(i_clk) then
            o_started         <= '0';
            c1_tdm_slot_reset <= '0';
            if not c1_running='1' and i_start='1' then
                o_started      <= '1';
                c1_running     <= '1';
                c1_dbl_buf_sel <= not c1_dbl_buf_sel;
            end if;
            c2_next_in_3 <= from_bool(c2_sample_cnt = g_NUM_SAMPLES-4);
            c2_next_in_2 <= c2_next_in_3;
            c2_next_in_1 <= c2_next_in_2;
            c2_last_in_2 <= from_bool(c2_tdm_slot = c_NUM_TDM_SLOTS-1);
            c2_last_in_1 <= c2_last_in_2;
            if c2_last_in_2='1' and c2_next_in_2='1' then
                c1_running        <= '0';
                c1_tdm_slot_reset <= '1';
            end if;
            if c1_running='1' then
                c2_sample_cnt <= c2_sample_cnt + 1;
            end if;
            if c2_next_in_1='1' then
                c2_sample_cnt <= to_unsigned(0, c2_sample_cnt'length);
                if c1_tdm_slot_reset='1' then
                    c2_tdm_slot <= to_unsigned(0, c2_tdm_slot'length);
                else
                    c2_tdm_slot <= c2_tdm_slot + 1;
                end if;
            end if;

            c2_running                <= c1_running or (not c1_running and i_start);
            c2_tdm_first              <= c2_next_in_2 and from_bool(c2_tdm_slot = 0);
            c3_sample_last            <= c2_next_in_1;
            c3_tdm_last               <= c2_next_in_1 and c2_last_in_1;
            c3_tdm_first              <= c2_tdm_first;
            c3_running                <= c2_running;
            c3_tdm                    <= c_TDM_SEL(to_integer(c2_tdm_slot));
            c3_tdm_slot               <= c2_tdm_slot;
            c3_sample_cnt             <= c2_sample_cnt;
            c4_col_rd_ctrl.sample_cnt  <= resize(c3_sample_cnt, c4_col_rd_ctrl.sample_cnt'length);
            c4_col_rd_ctrl.sample_last <= c3_sample_last;
            c4_row_rd_ctrl.sample_cnt  <= resize(c3_sample_cnt, c4_row_rd_ctrl.sample_cnt'length);
            c4_row_rd_ctrl.sample_last <= c3_sample_last;
            c4_tdm_slot                <= c3_tdm_slot;
            c4_tdm_last                <= c3_tdm_last;
            c4_tdm_first               <= c3_tdm_first;

            -- increment addresses every cycle for a new sample.
            c4_row_rd_ctrl.rd_addr <= resize(
                c3_tdm.row_addr + resize(c3_sample_cnt, c3_tdm.row_addr'length),
                c4_row_rd_ctrl.rd_addr'length);
            c4_col_rd_ctrl.rd_addr <= resize(
                c3_tdm.col_addr + resize(c3_sample_cnt, c3_tdm.col_addr'length),
                c4_col_rd_ctrl.rd_addr'length);

            c4_col_rd_ctrl.auto_corr <= c3_tdm.auto_corr;
            c4_row_rd_ctrl.auto_corr <= c3_tdm.auto_corr;
            c4_col_rd_ctrl.rd_enable <= c3_running;
            c4_row_rd_ctrl.rd_enable <= c3_running;

            c3_dbl_buf_sel            <= c1_dbl_buf_sel;  -- skip ahead one pipeline. 
            c4_col_rd_ctrl.dbl_buf_sel <= c3_dbl_buf_sel;
            c4_row_rd_ctrl.dbl_buf_sel <= c3_dbl_buf_sel;

            o_col_rd_ctrl <= c4_col_rd_ctrl;
            o_row_rd_ctrl <= c4_row_rd_ctrl;
            o_tdm_slot    <= resize(c4_tdm_slot, o_tdm_slot'length);
            o_tdm_last    <= c4_tdm_last;
            o_tdm_first   <= c4_tdm_first;
            
            if i_clk_reset = '1' then
                c1_running              <= '0';
                o_col_rd_ctrl.rd_enable <= '0';
                o_row_rd_ctrl.rd_enable <= '0';                
                c1_dbl_buf_sel          <= '1';
                c2_tdm_slot             <= to_unsigned(0, c2_tdm_slot'length);
                c2_sample_cnt           <= to_unsigned(0, c2_sample_cnt'length);
            end if;
        end if;
    end process;


end architecture rtl;
