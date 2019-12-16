-------------------------------------------------------------------------------
-- (c) Copyright - Commonwealth Scientific and Industrial Research Organisation
-- (CSIRO) - 2012
--
-- All Rights Reserved.
--
-- Restricted Use.
--
-- Copyright protects this code. Except as permitted by the Copyright Act, you
-- may only use the code as expressly permitted under the terms on which the
-- code was licensed to you.
--
-------------------------------------------------------------------------------
--
-- File Name:    delay.vhd
-- Type:         RTL
-- Designer:
-- Created:      Thu Mar 8 14:34:08 2012
-- Template Rev: 0.1
--
-- Title:        Delay Block
--
-- Description:  This module generates a generic delay element. It is 
--               configurable to use SRLs (16 or 32) or flip flops. The last  
--               element in a delay chain is a flip flop
--
-------------------------------------------------------------------------------

library ieee;
library unisim;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use unisim.vcomponents.all;

entity delay is
   generic (
      con_init       : bit := '0';
      con_cycles     : integer := 2;                                 -- Number of clock cycles to add
      con_width      : integer := 8;                                 -- Width of the delay element
      con_use_srl16  : boolean := false;                             -- Use SRL16
      con_use_srl32  : boolean := false);                            -- Use SRL32
      
   port (
      c              : in std_logic;                                 -- Clock input
      d              : in std_logic_vector(con_width-1 downto 0);    -- Data input
      q              : out std_logic_vector(con_width-1 downto 0));  -- Delayed data output
end delay;

architecture behavioral of delay is

-------------------------------------------------------------------------------
--                                Functions                                  -- 
-------------------------------------------------------------------------------

   function func_cutoff(a : integer) return integer is
   begin
      if a < 0 then
         return 0;
      else
         return a;
      end if;
   end func_cutoff;


-------------------------------------------------------------------------------
--                                Constants                                  -- 
-------------------------------------------------------------------------------

   -- Always use a FF on the output
   constant con_cycles_corrected : integer                        := con_cycles - 1;

   constant con_srl16            : integer                        := ((con_cycles_corrected-1)/16)+1;
   constant con_final_val16      : std_logic_vector(3 downto 0)   := std_logic_vector(to_unsigned(func_cutoff((con_cycles_corrected - 16*(con_srl16-1)) -1), 4));

   constant con_srl32            : integer                        := ((con_cycles_corrected-1)/32)+1;
   constant con_final_val32      : std_logic_vector(4 downto 0)   := std_logic_vector(to_unsigned(func_cutoff((con_cycles_corrected - 32*(con_srl32-1)) -1), 5));

-------------------------------------------------------------------------------
--                                Signals                                    -- 
-------------------------------------------------------------------------------

   signal sig_busses       : std_logic_vector(con_cycles*con_width-1 downto 0);
   signal sig_carry        : std_logic_vector((con_srl16+1)*con_width-1 downto 0);
   signal sig_srl_output   : std_logic_vector(con_srl16*con_width-1 downto 0);
   signal sig_srl_bitmask  : std_logic_vector(con_srl16*5-1 downto 0);
   signal sig_output       : std_logic_vector(con_width-1 downto 0);
   
begin

-------------------------------------------------------------------------------
--                     Discreet Flip Flop Implementation                     -- 
-------------------------------------------------------------------------------

use_ff: if con_use_srl16 = false and con_use_srl32 = false and con_cycles /= 0 generate
   sig_busses(con_width-1 downto 0) <= d;

   chain_generate: for i in 0 to con_cycles_corrected-1 generate
         width_generate: for j in 0 to con_width-1 generate
         
            ff: fd generic map (init   => con_init) 
                   port map(c          => c, 
                            d          => sig_busses(i*con_width+j), 
                            q          => sig_busses((i+1)*con_width+j));
         
         end generate width_generate;
      end generate chain_generate;

   sig_output <= sig_busses(con_cycles_corrected*con_width+con_width-1 downto con_cycles_corrected*con_width);
end generate use_ff;

-------------------------------------------------------------------------------
--                          SRL16 Implementation                             -- 
-------------------------------------------------------------------------------

use_srl16s: if con_use_srl16 = true and con_cycles /= 0 generate
   sig_carry(con_width-1 downto 0) <= d;

   
   srl_coefficients: for i in 0 to con_srl16-1 generate
      end_srl: if (i = con_srl16-1) generate
         sig_srl_bitmask(i*4 + 0) <= con_final_val16(0);
         sig_srl_bitmask(i*4 + 1) <= con_final_val16(1);
         sig_srl_bitmask(i*4 + 2) <= con_final_val16(2);
         sig_srl_bitmask(i*4 + 3) <= con_final_val16(3);
      end generate;
   
      middle_srl: if (i /= con_srl16-1) generate
         sig_srl_bitmask(i*4 + 0) <= '1';
         sig_srl_bitmask(i*4 + 1) <= '1';
         sig_srl_bitmask(i*4 + 2) <= '1';
         sig_srl_bitmask(i*4 + 3) <= '1';
      end generate;
   end generate;

   width_generate: for j in 0 to con_width-1 generate
      chain_generate: for i in 0 to con_srl16-1 generate
         shifter: srlc16 port map(clk  => c, 
                                  d    => sig_carry(i*con_width + j), 
                                  q    => sig_srl_output(i*con_width+j),
                                  q15  => sig_carry((i+1)*con_width + j),
                                  a0   => sig_srl_bitmask(i*4+0),
                                  a1   => sig_srl_bitmask(i*4+1),
                                  a2   => sig_srl_bitmask(i*4+2),
                                  a3   => sig_srl_bitmask(i*4+3));
      end generate chain_generate;
   end generate width_generate;
   
   -- Zero Delay
   zero_delay: if con_cycles_corrected = 0 generate
      sig_output <= sig_carry(con_width-1 downto 0);
   end generate;
   
   non_zero_delay: if con_cycles_corrected > 0 generate
      sig_output <= sig_srl_output((con_srl16-1)*con_width+con_width-1 downto (con_srl16-1)*con_width);
   end generate;
end generate;

-------------------------------------------------------------------------------
--                          SRL32 Implementation                             -- 
-------------------------------------------------------------------------------

use_srl32s: if con_use_srl32 = true and con_cycles /= 0 generate
   sig_carry(con_width-1 downto 0) <= d;
   
   srl_coefficients: for i in 0 to con_srl32-1 generate
      end_srl: if (i = con_srl32-1) generate
         sig_srl_bitmask(i*5 + 0) <= con_final_val32(0);
         sig_srl_bitmask(i*5 + 1) <= con_final_val32(1);
         sig_srl_bitmask(i*5 + 2) <= con_final_val32(2);
         sig_srl_bitmask(i*5 + 3) <= con_final_val32(3);
         sig_srl_bitmask(i*5 + 4) <= con_final_val32(4);
      end generate;
   
      middle_srl: if (i /= con_srl32-1) generate
         sig_srl_bitmask(i*5 + 0) <= '1';
         sig_srl_bitmask(i*5 + 1) <= '1';
         sig_srl_bitmask(i*5 + 2) <= '1';
         sig_srl_bitmask(i*5 + 3) <= '1';
         sig_srl_bitmask(i*5 + 4) <= '1';
      end generate;
   end generate;

   width_generate: for j in 0 to con_width-1 generate
      chain_generate: for i in 0 to con_srl32-1 generate
         shifter: srlc32e port map(clk    => c,
                                   ce     => '1', 
                                   d      => sig_carry(i*con_width + j), 
                                   q      => sig_srl_output(i*con_width+j),
                                   q31    => sig_carry((i+1)*con_width + j),
                                   a(0)   => sig_srl_bitmask(i*5 + 0),
                                   a(1)   => sig_srl_bitmask(i*5 + 1),
                                   a(2)   => sig_srl_bitmask(i*5 + 2),
                                   a(3)   => sig_srl_bitmask(i*5 + 3),
                                   a(4)   => sig_srl_bitmask(i*5 + 4));
      end generate chain_generate;
   end generate width_generate;
   
   -- Zero Delay
   zero_delay: if con_cycles_corrected = 0 generate
      sig_output <= sig_carry(con_width-1 downto 0);
   end generate;
   
   non_zero_delay: if con_cycles_corrected > 0 generate
      sig_output <= sig_srl_output((con_srl32-1)*con_width+con_width-1 downto (con_srl32-1)*con_width);
   end generate;
end generate;

-------------------------------------------------------------------------------
--                           Terminal Flip Flop                              -- 
-------------------------------------------------------------------------------

terminal_ff: for i in 0 to con_width-1 generate
   
   zero_delay: if con_cycles = 0 generate
      q(i) <= d(i);
   end generate;
   
   non_zero_delay: if con_cycles > 0 generate
      terminal_ff: fd generic map (init   => con_init) 
                      port map(c          => c, 
                               d          => sig_output(i), 
                               q          => q(i));
   end generate;
end generate;

end behavioral;
