-------------------------------------------------------------------------------
-- Title      : Common Type Declarations
-- Project    : 
-------------------------------------------------------------------------------
-- File       : common_types_pkg.vhd
-- Author     : William Kamp  <william.kamp@aut.ac.nz>
-- Company    : High Performance Computing Research Lab, Auckland University of Technology
-- Created    : 2015-12-07
-- Last update: 2018-01-01
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2015 High Performance Computing Research Lab, Auckland University of Technology
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2015-12-07  1.0      wkamp   Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package common_types_pkg is

    -- Standard powers of two
    type slv_1_a is array (natural range <>) of std_logic_vector(0 downto 0);
    type slv_2_a is array (natural range <>) of std_logic_vector(1 downto 0);
    type slv_4_a is array (natural range <>) of std_logic_vector(3 downto 0);    
    type slv_8_a is array (natural range <>) of std_logic_vector(7 downto 0);
    type slv_16_a is array (natural range <>) of std_logic_vector(15 downto 0);
    type slv_32_a is array (natural range <>) of std_logic_vector(31 downto 0);
    type slv_64_a is array (natural range <>) of std_logic_vector(63 downto 0);
    type slv_128_a is array (natural range <>) of std_logic_vector(127 downto 0);
    type slv_256_a is array (natural range <>) of std_logic_vector(255 downto 0);

    -- Unsigned powers of two vectors
    type unsigned_1_a is array (natural range <>) of unsigned(0 downto 0);
    type unsigned_2_a is array (natural range <>) of unsigned(1 downto 0);
    type unsigned_4_a is array (natural range <>) of unsigned(3 downto 0);    
    type unsigned_8_a is array (natural range <>) of unsigned(7 downto 0);
    type unsigned_16_a is array (natural range <>) of unsigned(15 downto 0);
    type unsigned_32_a is array (natural range <>) of unsigned(31 downto 0);
    type unsigned_64_a is array (natural range <>) of unsigned(63 downto 0);
    type unsigned_128_a is array (natural range <>) of unsigned(127 downto 0);
    type unsigned_256_a is array (natural range <>) of unsigned(255 downto 0);
    
    -- Stratix5 transciever interfaces.
    type slv_80_a is array (natural range <>) of std_logic_vector(79 downto 0);
    type slv_92_a is array (natural range <>) of std_logic_vector(91 downto 0);
    type slv_140_a is array (natural range <>) of std_logic_vector(139 downto 0);
    
end package common_types_pkg;
