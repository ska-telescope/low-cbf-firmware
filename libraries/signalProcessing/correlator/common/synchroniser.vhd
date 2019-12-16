-------------------------------------------------------------------------------
-- Title      : Synchroniser flops
-- Project    :
-------------------------------------------------------------------------------
-- File       : synchroniser.vhd
-- Author     : William Kamp  <william.kamp@aut.ac.nz>
-- Company    : High Performance Computing Research Lab, Auckland University of Technology
-- Created    : 2018-01-22
-- Platform   :
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2018 High Performance Computing Research Lab, Auckland University of Technology
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2018-01-22  1.0      will    Created
-- 2019-09-17  2.0p     nabel   Ported to Perentie (using XPM)
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

Library xpm;
use xpm.vcomponents.all;

entity synchroniser is

    generic (
        g_SYNCHRONISER_FLOPS : natural range 2 to 4 := 3);

    port (
        i_bit    : in  std_logic; -- bit in another clock domain.
        i_clk    : in  std_logic;
        o_bit_rt : out std_logic); -- synchronised to i_clk domain.

end entity synchroniser;

architecture rtl of synchroniser is

    signal unused : std_logic; 

begin

   xpm_cdc_single_inst : xpm_cdc_single
   generic map (
      DEST_SYNC_FF   => 2, 
      INIT_SYNC_FF   => 0, 
      SIM_ASSERT_CHK => 0,
      SRC_INPUT_REG  => 0  
   )
   port map (
      src_clk  => unused, 
      src_in   => i_bit,    
      dest_clk => i_clk,
      dest_out => o_bit_rt 
   );

end architecture rtl;
