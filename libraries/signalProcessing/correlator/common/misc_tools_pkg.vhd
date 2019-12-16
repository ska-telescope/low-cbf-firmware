-------------------------------------------------------------------------------
-- Title      : Miscellaneous Tools Package
-- Project    :
-------------------------------------------------------------------------------
-- File       : misc_tools_pkg.vhd
-- Author     :   <wkamp@WT608-002WSW>
-- Company    : High Performance Computing Research Lab, Auckland University of Technology
-- Created    : 2015-10-13
-- Last update: 2018-07-10
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2015 High Performance Computing Research Lab, Auckland University of Technology
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2015-10-13  1.0      wkamp   Created
-- 2019-09-16  2.0p     nabel   Ported to Perentie
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.common_types_pkg.all;

package misc_tools_pkg is

    function wired_or (slv  : std_logic_vector) return std_logic;
    function wired_and (slv : std_logic_vector) return std_logic;
    function shift_left (slv             : std_logic_vector;
                         constant amount : natural   := 1;
                         constant fill   : std_logic := '-') return std_logic_vector;
    function shift_right (slv             : std_logic_vector;
                          constant amount : natural   := 1;
                          constant fill   : std_logic := '-') return std_logic_vector;

    -- floor(log_b(n))
    function floor_log(val, base : positive)
        return natural;

    -- ceiling(log_b(n))
    function ceil_log(val, base : positive)
        return natural;

    -- floor(log2(n))
    function floor_log2(val : positive)
        return natural;

    -- ceiling(log2(n))
    function ceil_log2(val : positive)
        return natural;

    -- Number of bits needed to represent a number n in binary
    function bit_width(val : natural)
        return natural;

    -- Number of bits needed to encode n items
    function encoding_width(val : positive)
        return natural;

    function power_of_2 (power        : unsigned;
                         constant len : natural)
        return unsigned;

    -- Returns the next power of two greater than or equal val
    function ceil_pow2 (val : natural)
        return natural;

    function is_pow_2 (val : natural)
        return boolean;

    function maxim (constant a : natural;
                      constant b : natural)
        return natural;

    function bit_swap (slv                  : std_logic_vector;
                       constant slice_width : natural := 1)  -- size of the groups to swap. e.g swap order of bytes = 8.
        return std_logic_vector;

    function byte_swap(slv : std_logic_vector)
        return std_logic_vector;

    -- Convert a one-hot vector into an unsigned value.
    function from_onehot(slv            : std_logic_vector;
                         allow_zero_hot : boolean := false)
        return unsigned;

    function count_trailing_zeros (val : std_logic_vector)
        return unsigned;

    function count_leading_zeros (val : std_logic_vector)
        return unsigned;

    procedure p_sum_carry (
        a         : in  unsigned;
        b         : in  unsigned;
        carry_in  : in  std_logic := '0';
        sum_out   : out unsigned;
        carry_out : out std_logic);

end package misc_tools_pkg;

package body misc_tools_pkg is

    -- purpose: OR all bits together
    function wired_or (slv : std_logic_vector)
        return std_logic is
        variable ored : std_logic := '0';
    begin  -- function wired_or
        if slv = (slv'range => '0') then
            return '0';
        else
            return '1';
        end if;
    end function wired_or;

    function wired_and (slv : std_logic_vector)
        return std_logic is
        variable ored : std_logic := '0';
    begin  -- function wired_or
        if slv = (slv'range => '1') then
            return '1';
        else
            return '0';
        end if;
    end function wired_and;

    -- purpose: shift a std_logic_vector left an <amount> and shift in bits with value <fill>.
    function shift_left (slv             : std_logic_vector;
                         constant amount : natural   := 1;
                         constant fill   : std_logic := '-')
        return std_logic_vector is
    begin
        return slv(slv'high-amount downto slv'low) & (amount-1 downto 0 => fill);
    end function shift_left;

    function shift_right (slv             : std_logic_vector;
                          constant amount : natural   := 1;
                          constant fill   : std_logic := '-')
        return std_logic_vector is
    begin
        return (amount-1 downto 0 => fill) & slv(slv'high downto slv'low+amount);
    end function shift_right;

    function floor_log(val, base : positive)
        return natural is
        variable log, residual : natural;
    begin
        residual := val;
        log      := 0;
        while residual > (base - 1) loop
            residual := residual / base;
            log      := log + 1;
        end loop;
        return log;
    end function;

    function ceil_log(val, base : positive)
        return natural is
        variable log, residual : natural;
    begin
        residual := val - 1;
        log      := 0;
        while residual > 0 loop
            residual := residual / base;
            log      := log + 1;
        end loop;
        return log;
    end function;

    function floor_log2(val : positive)
        return natural is
    begin
        return floor_log(val, 2);
    end function;

    function ceil_log2(val : positive)
        return natural is
    begin
        return ceil_log(val, 2);
    end function;

    function bit_width(val : natural)
        return natural is
    begin
        if val = 0 then
            return 1;
        else
            return floor_log2(val) + 1;
        end if;
    end function;

    function encoding_width(val : positive)
        return natural is
    begin
        if val = 1 then
            return 1;
        else
            return ceil_log2(val);
        end if;
    end function;

    function power_of_2 (power        : unsigned;
                         constant len : natural)
        return unsigned is
        variable res : unsigned(len -1 downto 0) := (others => '0');
    begin
        res(to_integer(power)) := '1';
        return res;
    end function power_of_2;

    -- Returns the next power of two.
    function ceil_pow2 (val : natural)
        return natural is
        variable res : natural;
    begin  -- function ceil_pow2
        if val = 0 then
            return 0;
        end if;
        res := 1;
        while res < val loop
            res := res * 2;
        end loop;
        return res;
    end function ceil_pow2;

    function is_pow_2 (
        val : natural)
        return boolean is
        variable test : natural;
    begin  -- function is_pow_2
        test := val;
        while test mod 2 = 0 loop
            test := test/2;
        end loop;
        return test = 1;
    end function is_pow_2;

    function maxim (constant a : natural;
                      constant b : natural)
        return natural is
    begin  -- function maxim
        if a > b then
            return a;
        else
            return b;
        end if;
    end function maxim;

    function bit_swap (slv                  : std_logic_vector;
                       constant slice_width : natural := 1)  -- size of the groups to swap. e.g swap order of bytes = 8.
        return std_logic_vector is
        variable out_slv : std_logic_vector(slv'range);
        variable lo, hi  : natural;
    begin
        assert slv'length mod slice_width = 0
            report "std_logic_vector input length (" & natural'image(slv'length) & ") is not a multiple of the slice_width (" & natural'image(slice_width) & ")."
            severity failure;
        for idx in 0 to slv'length/slice_width - 1 loop
            lo                                  := out_slv'low + idx * slice_width;
            hi                                  := slv'high - idx * slice_width;
            out_slv(lo+slice_width-1 downto lo) := slv(hi downto hi-slice_width+1);
        end loop;
        return out_slv;
    end function bit_swap;

    function byte_swap(slv : std_logic_vector)
        return std_logic_vector is
    begin
        return bit_swap(slv, 8);
    end function byte_swap;

    constant c_OHOT_MASK : slv_64_a := (0 => x"AAAAAAAA_AAAAAAAA",
                                        1 => x"CCCCCCCC_CCCCCCCC",
                                        2 => x"F0F0F0F0_F0F0F0F0",
                                        3 => x"FF00FF00_FF00FF00",
                                        4 => x"FFFF0000_FFFF0000",
                                        5 => x"FFFFFFFF_00000000");

    function from_onehot(slv            : std_logic_vector;
                         allow_zero_hot : boolean := false)
        return unsigned is
        variable val  : unsigned(5 downto 0);
        variable mask : std_logic_vector(slv'range);
    begin
        assert slv'length < 65
            report "misc_tools_pkg.from_onehot function currently only supports up to 64 bit vectors."
            severity failure;
        assert slv /= (slv'range => '0') or allow_zero_hot
            report "Argument to misc_tools_pkg.from_onehot function is zero-hot."
            severity error;
        val := to_unsigned(0, val'length);
        for pow in val'range loop
            mask     := c_OHOT_MASK(pow)(slv'range);
            val(pow) := wired_or(slv and mask);
        end loop;
        return val(ceil_log2(slv'length)-1 downto 0);
    end function;

    function count_trailing_zeros (
        val : std_logic_vector)
        return unsigned is
        variable ohot : signed(val'length-1 downto 0);
        variable idx  : unsigned(ceil_log2(val'length)-1 downto 0);
    begin  -- function count_trailing_zeros
        ohot := signed(val) and -signed(val); -- AND itself with its two's complement.
        idx  := unsigned(from_onehot(std_logic_vector(ohot)));
        return idx;
    end function count_trailing_zeros;

    function count_leading_zeros (
        val : std_logic_vector)
        return unsigned is
        variable rev : std_logic_vector(val'length-1 downto 0);
    begin  -- function count_leading_zeros
        for idx in rev'range loop
            rev(idx) := val(val'high - idx);
        end loop;
        return count_trailing_zeros(rev);
    end function count_leading_zeros;


    procedure p_sum_carry (
        a         : in  unsigned;
        b         : in  unsigned;
        carry_in  : in  std_logic := '0';
        sum_out   : out unsigned;
        carry_out : out std_logic) is
        variable opa : unsigned(a'length+1 downto 0);
        variable opb : unsigned(b'length+1 downto 0);
        variable sum : unsigned(opa'range);
    begin  -- procedure p_sum_carry
        opa       := '0' & a & carry_in;
        opb       := '0' & b & '1';
        sum       := opa + opb;
        carry_out := sum(sum'high);
        sum_out   := sum_out(sum_out'high-1 downto 1);
    end procedure p_sum_carry;


end package body misc_tools_pkg;
