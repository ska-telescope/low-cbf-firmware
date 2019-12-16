-------------------------------------------------------------------------------
--
-- Copyright (C) 2010
-- ASTRON (Netherlands Institute for Radio Astronomy) <http://www.astron.nl/>
-- JIVE (Joint Institute for VLBI in Europe) <http://www.jive.nl/>
-- P.O.Box 2, 7990 AA Dwingeloo, The Netherlands
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-------------------------------------------------------------------------------

LIBRARY IEEE, common_lib, common_mult_lib, technology_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE common_lib.common_lfsr_sequences_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE work.util_heater_pkg.ALL;

-- Purpose:
--   Use multiplier DSP elements, RAM and logic in an FPGA to heat up the PFGA
--   to see how the FPGA behaves when it gets warm. This is useful to verify
--   whether the FPGA remains functional, especially its various external IO
--   interfaces (e.g. gigabit transceivers and DDR memory).
-- Desription:
--   The heater elements can be enabled or disabled via an MM register.
--   Each heater element consists of a MAC4. A MAC4 uses 4 18x18 multipliers.
--   The MAC4 inputs are random so: mac4 = r0r1 + r1r2 + r2r3+ r3r0. For
--   g_pipeline > 0 the output data gets pipelined to use more logic. For
--   g_nof_ram > the output data is put through a FIFO to use more RAM. The
--   final output data gets XOR-ed to get a single bit value that can be read
--   via the same MM register. The read value is not relevant, but the read
--   access connection ensures that the heater element logic will not be
--   optimized away by synthesis.
--   The number of heater elements can be set via g_nof_mac4. The MM register
--   allows enabling 0, 1, more or all MAC4 under SW control. In this way it
--   is possible to vary the power consumption during run time.
--   Using common_pipeline.vhd to invoke logic can get implemented in RAM
--   blocks for larger pipeline settings. Therefor g_nof_logic to instantiate
--   util_logic stages to enforce using logic (LUTs and FF).


ENTITY util_heater IS
  GENERIC (    
    g_technology  : t_technology := c_tech_gemini;
    g_nof_mac4  : NATURAL := 1;    -- >= 1, number of multiply 18x18 and accumulate 4 elements in the heater <= c_util_heater_nof_mac4_max
    g_pipeline  : NATURAL := 1;    -- >= 0, number of pipelining register stages after the multiplier
    g_nof_ram   : NATURAL := 1;    -- >= 0, number of 1k Byte RAM blocks in the FIFO per multiplier
    g_nof_logic : NATURAL := 1     -- >= 0, number of XOR register stages after the FIFO
  );
  PORT (
    mm_rst  : IN  STD_LOGIC;  -- MM is the microprocessor control clock domain 
    mm_clk  : IN  STD_LOGIC;
    st_rst  : IN  STD_LOGIC;  -- ST is the DSP clock domain
    st_clk  : IN  STD_LOGIC;
    -- Memory Mapped Slave
    --sla_in  : IN  t_mem_mosi;
    --sla_out : OUT t_mem_miso
    sla_in  : IN  STD_LOGIC_VECTOR(g_nof_mac4-1 DOWNTO 0);
    sla_out : OUT STD_LOGIC_VECTOR(g_nof_mac4-1 DOWNTO 0)
  );
END;


ARCHITECTURE rtl OF util_heater IS

  -- Use MM bus data width = c_word_w = 32
--  CONSTANT c_mm_reg  : t_c_mem := (latency  => 1,
--                                   adr_w    => c_util_heater_reg_addr_w,
--                                   dat_w    => c_word_w,
--                                   nof_dat  => c_util_heater_reg_nof_words,
--                                   init_sl  => '0');
                                   
  --CONSTANT c_remote_len     : NATURAL := 5;                                -- >> 0 to ease timing to reach logic throughout the whole chip
  --CONSTANT c_remote_len     : NATURAL := 16;                                -- >> 0 to ease timing to reach logic throughout the whole chip
  -- I get Xilinx' Implementation error: [Opt 31-2] SRLC32E u_heater/gen_cross[0].u_cross_en/din_meta_reg[16]_srl17_u_heater_gen_cross_c_15 is missing a connection on D pin.

  CONSTANT c_remote_len     : NATURAL := 0;                                -- >> 0 to ease timing to reach logic throughout the whole chip
  CONSTANT c_sync_delay_len : NATURAL := c_meta_delay_len + c_remote_len;  -- >= c_meta_delay_len=3
  
  -- Use a MAC with 4 multipliers as basic heater element to be able to use all 18x18 in a Stratix4 DSP block
  CONSTANT c_mac4                 : NATURAL := 4;   -- 4 multipliers per mac4
  CONSTANT c_mac_pipeline_input   : NATURAL := 1;
  CONSTANT c_mac_pipeline_product : NATURAL := 0;
  CONSTANT c_mac_pipeline_adder   : NATURAL := 1;
  CONSTANT c_mac_pipeline_output  : NATURAL := 1;
  
  -- Random input generators
  CONSTANT c_in_dat_w       : NATURAL := 18;              -- fixed multiplier input data width
  CONSTANT c_prsg_0_w       : NATURAL := c_in_dat_w ;     -- generate sufficiently large random range
  CONSTANT c_prsg_1_w       : NATURAL := c_in_dat_w + 1;  -- generate different range
  CONSTANT c_prsg_2_w       : NATURAL := c_in_dat_w + 2;  -- generate different range
  CONSTANT c_prsg_3_w       : NATURAL := c_in_dat_w + 3;  -- generate different range
  
  CONSTANT c_mac_in_dat_w   : NATURAL := c_mac4*c_in_dat_w;        -- aggregate mac4 input data width
  CONSTANT c_mult_dat_w     : NATURAL := c_in_dat_w + c_in_dat_w;  -- = 36
  CONSTANT c_mac_out_dat_w  : NATURAL := c_mult_dat_w + 2;         -- + 2 = ceil_log2(c_mac4)
  CONSTANT c_fifo_dat_w     : NATURAL := c_mult_dat_w;             -- = 36
  
  CONSTANT c_nof_fifo_dat_in_1kbyte_ram : NATURAL := (1024 * 9) / c_fifo_dat_w;  -- = a byte has 8 + 1 = 9 bits
  
  TYPE t_prsg_0_arr      IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_prsg_0_w-1 DOWNTO 0);
  TYPE t_prsg_1_arr      IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_prsg_1_w-1 DOWNTO 0);
  TYPE t_prsg_2_arr      IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_prsg_2_w-1 DOWNTO 0);
  TYPE t_prsg_3_arr      IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_prsg_3_w-1 DOWNTO 0);
  
  TYPE t_mac_in_dat_arr  IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_mac_in_dat_w-1 DOWNTO 0);
  TYPE t_mac_out_dat_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_mac_out_dat_w-1 DOWNTO 0);
  
  TYPE t_fifo_dat_arr    IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_fifo_dat_w-1 DOWNTO 0);
  
  -- Available bits
  SIGNAL mm_reg_en          : STD_LOGIC_VECTOR(c_util_heater_nof_mac4_max-1 DOWNTO 0);
  SIGNAL mm_reg_xor         : STD_LOGIC_VECTOR(c_util_heater_nof_mac4_max-1 DOWNTO 0);
  
  -- Used bits
  SIGNAL mm_element_en      : STD_LOGIC_VECTOR(g_nof_mac4-1 DOWNTO 0);
  SIGNAL mm_element_xor     : STD_LOGIC_VECTOR(g_nof_mac4-1 DOWNTO 0);
  SIGNAL st_element_en      : STD_LOGIC_VECTOR(g_nof_mac4-1 DOWNTO 0);
  SIGNAL st_element_xor     : STD_LOGIC_VECTOR(g_nof_mac4-1 DOWNTO 0);
  SIGNAL nxt_st_element_xor : STD_LOGIC_VECTOR(g_nof_mac4-1 DOWNTO 0);
  
  SIGNAL st_clken           : STD_LOGIC_VECTOR(g_nof_mac4-1 DOWNTO 0);
  
  SIGNAL prsg_0_reg         : STD_LOGIC_VECTOR(c_prsg_0_w-1 DOWNTO 0);
  SIGNAL prsg_0             : STD_LOGIC_VECTOR(c_prsg_0_w-1 DOWNTO 0);
  SIGNAL nxt_prsg_0         : STD_LOGIC_VECTOR(c_prsg_0_w-1 DOWNTO 0);
  SIGNAL prsg_1_reg         : STD_LOGIC_VECTOR(c_prsg_1_w-1 DOWNTO 0);
  SIGNAL prsg_1             : STD_LOGIC_VECTOR(c_prsg_1_w-1 DOWNTO 0);
  SIGNAL nxt_prsg_1         : STD_LOGIC_VECTOR(c_prsg_1_w-1 DOWNTO 0);
  SIGNAL prsg_2_reg         : STD_LOGIC_VECTOR(c_prsg_2_w-1 DOWNTO 0);
  SIGNAL prsg_2             : STD_LOGIC_VECTOR(c_prsg_2_w-1 DOWNTO 0);
  SIGNAL nxt_prsg_2         : STD_LOGIC_VECTOR(c_prsg_2_w-1 DOWNTO 0);
  SIGNAL prsg_3_reg         : STD_LOGIC_VECTOR(c_prsg_3_w-1 DOWNTO 0);
  SIGNAL prsg_3             : STD_LOGIC_VECTOR(c_prsg_3_w-1 DOWNTO 0);
  SIGNAL nxt_prsg_3         : STD_LOGIC_VECTOR(c_prsg_3_w-1 DOWNTO 0);
  
  SIGNAL in_dat_a           : t_mac_in_dat_arr( 0 TO g_nof_mac4-1);
  SIGNAL in_dat_b           : t_mac_in_dat_arr( 0 TO g_nof_mac4-1);
  SIGNAL mac4               : t_mac_out_dat_arr(0 TO g_nof_mac4-1);
  SIGNAL fifo_in_dat        : t_fifo_dat_arr(   0 TO g_nof_mac4-1);
  SIGNAL fifo_out_dat       : t_fifo_dat_arr(   0 TO g_nof_mac4-1);
  SIGNAL logic_dat          : t_fifo_dat_arr(   0 TO g_nof_mac4-1);
  
BEGIN

  ------------------------------------------------------------------------------
  -- MM clock domain
  ------------------------------------------------------------------------------
--  u_mm_reg : ENTITY common_lib.common_reg_r_w
--  GENERIC MAP (
--    g_reg       => c_mm_reg,
--    g_init_reg  => (OTHERS => '0')
--  )
--  PORT MAP (
--    rst       => mm_rst,
--    clk       => mm_clk,
--    -- control side
--		wr_en     => sla_in.wr,
--		wr_adr    => sla_in.address(c_mm_reg.adr_w-1 DOWNTO 0),
--		wr_dat    => sla_in.wrdata(c_mm_reg.dat_w-1 DOWNTO 0),
--		rd_en     => sla_in.rd,
--		rd_adr    => sla_in.address(c_mm_reg.adr_w-1 DOWNTO 0),
--		rd_dat    => sla_out.rddata(c_mm_reg.dat_w-1 DOWNTO 0),
--		rd_val    => OPEN,
--    -- data side
--    out_reg   => mm_reg_en,
--    in_reg    => mm_reg_xor
--  );
  
  mm_reg_en(g_nof_mac4-1 downto 0) <= sla_in;
  mm_element_en                    <= mm_reg_en(mm_element_en'RANGE);
  
  sla_out <= mm_element_xor;
  mm_reg_xor(mm_element_xor'RANGE) <= mm_element_xor(g_nof_mac4-1 downto 0);
  


  ------------------------------------------------------------------------------
  -- Clock domain crossing
  ------------------------------------------------------------------------------
  gen_cross : FOR I IN 0 TO g_nof_mac4-1 GENERATE
    -- The MM reg bits are use individually (i.e. not as numbers) therefore it is allowed
    -- to synchronize them using a series of flip flops per bit. If the bits would be
    -- interpreted as numbers then common_reg_cross_domain would have to be used, to ensure
    -- that all bits that make the number are transfered synchronously.
    
    -- MM --> ST
    u_cross_en : ENTITY common_lib.common_async
    GENERIC MAP (
      g_rst_level => '0',
      g_delay_len => c_sync_delay_len
    )
    PORT MAP (
      rst  => st_rst,
      clk  => st_clk,
      din  => mm_element_en(I),
      dout => st_element_en(I)
    );
  
    -- MM <-- ST
    u_cross_xor : ENTITY common_lib.common_async
    GENERIC MAP (
      g_rst_level => '0',
      g_delay_len => c_sync_delay_len
    )
    PORT MAP (
      rst  => mm_rst,
      clk  => mm_clk,
      din  => st_element_xor(I),
      dout => mm_element_xor(I)
    );
  END GENERATE;
  
  ------------------------------------------------------------------------------
  -- ST clock domain
  ------------------------------------------------------------------------------
  
  -- Heater element enable/disable
  st_clken <= st_element_en(g_nof_mac4-1 DOWNTO 0);
  
  -- Shared PSRG source
  p_st_clk : PROCESS (st_rst, st_clk)
  BEGIN
    IF st_rst='1' THEN
      prsg_0         <= (OTHERS=>'0');
      prsg_1         <= (OTHERS=>'0');
      prsg_2         <= (OTHERS=>'0');
      prsg_3         <= (OTHERS=>'0');
      st_element_xor <= (OTHERS=>'0');
    ELSIF rising_edge(st_clk) THEN
      prsg_0         <= nxt_prsg_0;
      prsg_1         <= nxt_prsg_1;
      prsg_2         <= nxt_prsg_2;
      prsg_3         <= nxt_prsg_3;
      st_element_xor <= nxt_st_element_xor;
    END IF;
  END PROCESS;

  nxt_prsg_0 <= func_common_random(prsg_0);
  nxt_prsg_1 <= func_common_random(prsg_1);
  nxt_prsg_2 <= func_common_random(prsg_2);
  nxt_prsg_3 <= func_common_random(prsg_3);
  
  u_prsg_0_reg : ENTITY common_lib.common_pipeline
  GENERIC MAP (
    g_pipeline    => c_remote_len,
    g_in_dat_w    => prsg_0'LENGTH,
    g_out_dat_w   => prsg_0'LENGTH
  )
  PORT MAP (
    rst     => st_rst,
    clk     => st_clk,
    in_dat  => prsg_0,
    out_dat => prsg_0_reg
  );
  
  u_prsg_1_reg : ENTITY common_lib.common_pipeline
  GENERIC MAP (
    g_pipeline    => c_remote_len,
    g_in_dat_w    => prsg_1'LENGTH,
    g_out_dat_w   => prsg_1'LENGTH
  )
  PORT MAP (
    rst     => st_rst,
    clk     => st_clk,
    in_dat  => prsg_1,
    out_dat => prsg_1_reg
  );

  u_prsg_2_reg : ENTITY common_lib.common_pipeline
  GENERIC MAP (
    g_pipeline    => c_remote_len,
    g_in_dat_w    => prsg_2'LENGTH,
    g_out_dat_w   => prsg_2'LENGTH
  )
  PORT MAP (
    rst     => st_rst,
    clk     => st_clk,
    in_dat  => prsg_2,
    out_dat => prsg_2_reg
  );
  
  u_prsg_3_reg : ENTITY common_lib.common_pipeline
  GENERIC MAP (
    g_pipeline    => c_remote_len,
    g_in_dat_w    => prsg_3'LENGTH,
    g_out_dat_w   => prsg_3'LENGTH
  )
  PORT MAP (
    rst     => st_rst,
    clk     => st_clk,
    in_dat  => prsg_3,
    out_dat => prsg_3_reg
  );
  
  ------------------------------------------------------------------------------
  -- Heater elements
  ------------------------------------------------------------------------------
  gen_heat : FOR I IN 0 TO g_nof_mac4-1 GENERATE
  
    ----------------------------------------------------------------------------
    -- Multipliers
    ----------------------------------------------------------------------------
  
    -- Random input stimuli: mac4 = r0*r1 + r1*r2 + r2*r3 + r3*r0
    in_dat_a(I) <= prsg_0_reg(c_in_dat_w-1 DOWNTO 0) &
                   prsg_1_reg(c_in_dat_w-1 DOWNTO 0) &
                   prsg_2_reg(c_in_dat_w-1 DOWNTO 0) &
                   prsg_3_reg(c_in_dat_w-1 DOWNTO 0);
    in_dat_b(I) <= prsg_1_reg(c_in_dat_w-1 DOWNTO 0) &
                   prsg_2_reg(c_in_dat_w-1 DOWNTO 0) &
                   prsg_3_reg(c_in_dat_w-1 DOWNTO 0) &
                   prsg_0_reg(c_in_dat_w-1 DOWNTO 0);
  
    -- Complex multipliers, these should get mapped on DSP elements in the FPGA
    u_dsp : ENTITY common_mult_lib.common_mult_add4 --(rtl)
    GENERIC MAP (
      g_technology       => g_technology,
      g_in_a_w           => c_in_dat_w,
      g_in_b_w           => c_in_dat_w,
      g_res_w            => c_mac_out_dat_w,
      g_pipeline_input   => c_mac_pipeline_input,
      g_pipeline_product => c_mac_pipeline_product,
      g_pipeline_adder   => c_mac_pipeline_adder,
      g_pipeline_output  => c_mac_pipeline_output
    )
    PORT MAP (
      clk        => st_clk,
      clken      => st_clken(I),
      in_a       => in_dat_a(I),
      in_b       => in_dat_b(I),
      res        => mac4(I)
    );
    
    -- Pipeline, use g_pipeline > 0 to run some more logic resources or to ease achieving timing closure
    u_logic : ENTITY common_lib.common_pipeline
    GENERIC MAP (
      g_pipeline    => g_pipeline,  -- use 0 for no logic, so only wires
      g_in_dat_w    => c_mac_out_dat_w,
      g_out_dat_w   => c_fifo_dat_w
    )
    PORT MAP (
      rst     => st_rst,
      clk     => st_clk,
      clken   => st_clken(I),
      in_dat  => mac4(I),
      out_dat => fifo_in_dat(I)
    );
    
    ----------------------------------------------------------------------------
    -- RAM
    ----------------------------------------------------------------------------
    
    -- FIFO, use g_nof_ram > 0 to use RAM or g_nof_ram = 0 to bypass
    gen_ram : IF g_nof_ram > 0 GENERATE
      u_fifo : ENTITY common_lib.common_fifo_sc
      GENERIC MAP (
        g_technology=> g_technology,
        g_dat_w     => c_fifo_dat_w,
        g_nof_words => g_nof_ram * c_nof_fifo_dat_in_1kbyte_ram
      )
      PORT MAP (
        rst      => st_rst,
        clk      => st_clk,
        wr_dat   => fifo_in_dat(I),
        wr_req   => st_clken(I),
        wr_ful   => OPEN,
        rd_dat   => fifo_out_dat(I),
        rd_req   => st_clken(I),
        rd_emp   => OPEN,
        rd_val   => OPEN,
        usedw    => OPEN
      );
    END GENERATE;
  
    no_ram : IF g_nof_ram = 0 GENERATE
      fifo_out_dat(I) <= fifo_in_dat(I);
    END GENERATE;
    
    ----------------------------------------------------------------------------
    -- LUTs and FFs
    ----------------------------------------------------------------------------
    
    gen_logic : IF g_nof_logic > 0 GENERATE
      u_logic : ENTITY work.util_logic
      GENERIC MAP (
        g_nof_reg => g_nof_logic
      )
      PORT MAP (
        clk     => st_clk,
        clken   => st_clken(I),
        in_dat  => fifo_out_dat(I),
        out_dat => logic_dat(I)
      );
    END GENERATE;
    no_logic : IF g_nof_logic = 0 GENERATE
      logic_dat(I) <= fifo_out_dat(I);
    END GENERATE;
    
    -- Preserve result, to avoid that the synthesis will optimize all heater element away    
    nxt_st_element_xor(I) <= vector_xor(logic_dat(I));  -- arbitrary function to group product bits into single output bit
  END GENERATE;
  
END rtl;
