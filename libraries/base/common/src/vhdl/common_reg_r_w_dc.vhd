-------------------------------------------------------------------------------
--
-- File Name: common_reg_r_w_dc.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Fri May 25 14:40:00 2018
-- Template Rev: 1.0
--
-- Title: Low level register block with dual clock
--
-- Description: Break the local memory mapped bus into a seperate domain
--              from the registers themselves. Each slave is mapped to
--              a separate clock domain. The pipline parameter isn't supported
--              as it has no meaning when dealing with multiple clock domains.
--
--              The register has g_reg.nof_slaves replicas of g_reg.nof_dat
--              words and each word is g_reg.dat_w bits wide. At the control
--              side the register is accessed per word using the address input
--              wr_adr or rd_adr as index. At the data side the whole register
--              group of g_reg.nof_slaves*g_reg.dat_w*g_reg.nof_dat bits is
--              available at once.
--
--              Example: For g_reg.nof_slaves = 1, g_reg.nof_dat = 3 and
--              g_reg.dat_w = 32 the addressing accesses the register bits as
--              follows:
--                 wr_adr[1:0], rd_adr[1:0] = 0 --> reg[31:0]
--                 wr_adr[1:0], rd_adr[1:0] = 1 --> reg[63:32]
--                 wr_adr[1:0], rd_adr[1:0] = 2 --> reg[95:64]
--
--
--
-- Compiler options:
--
--
-- Dependencies:
--
--
--
-------------------------------------------------------------------------------

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;

ENTITY common_reg_r_w_dc IS
   GENERIC (
      g_reg       : t_c_mem := c_mem_reg;
      g_init_reg  : STD_LOGIC_VECTOR(c_mem_reg_init_w-1 DOWNTO 0) := (OTHERS => '0');
      g_clr_mask  : STD_LOGIC_VECTOR(c_mem_reg_init_w-1 DOWNTO 0) := (OTHERS => '0'));
   PORT (
      mm_rst      : IN STD_LOGIC := '0';
      mm_clk      : IN STD_LOGIC;                                      -- Control Clock
      st_clk      : IN STD_LOGIC_VECTOR(0 TO g_reg.nof_slaves-1);  -- Register clock
      st_rst      : IN STD_LOGIC_VECTOR(0 TO g_reg.nof_slaves-1) := (OTHERS => '0');

      -- control side
      wr_en       : IN  STD_LOGIC;                                   -- Write Strobe
      wr_adr      : IN  STD_LOGIC_VECTOR(g_reg.adr_w-1 DOWNTO 0);
      wr_dat      : IN  STD_LOGIC_VECTOR(g_reg.dat_w-1 DOWNTO 0);
      wr_val      : OUT STD_LOGIC;                                   -- Write ack
      wr_busy     : OUT STD_LOGIC;                                   -- Write busy

      rd_en       : IN  STD_LOGIC;                                   -- Read Strobe
      rd_adr      : IN  STD_LOGIC_VECTOR(g_reg.adr_w-1 DOWNTO 0);
      rd_dat      : OUT STD_LOGIC_VECTOR(g_reg.dat_w-1 DOWNTO 0);
      rd_val      : OUT STD_LOGIC;                                   -- Read ack
      rd_busy     : OUT STD_LOGIC;                                   -- Read busy

      -- data side
      reg_wr_arr  : OUT STD_LOGIC_VECTOR(            g_reg.nof_slaves*g_reg.nof_dat-1 DOWNTO 0);
      reg_rd_arr  : OUT STD_LOGIC_VECTOR(            g_reg.nof_slaves*g_reg.nof_dat-1 DOWNTO 0);
      out_reg     : OUT STD_LOGIC_VECTOR(g_reg.dat_w*g_reg.nof_slaves*g_reg.nof_dat-1 DOWNTO 0);
      in_reg      : IN  STD_LOGIC_VECTOR(g_reg.dat_w*g_reg.nof_slaves*g_reg.nof_dat-1 DOWNTO 0));
END common_reg_r_w_dc;


ARCHITECTURE rtl OF common_reg_r_w_dc IS

   ---------------------------------------------------------------------------
   -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
   ---------------------------------------------------------------------------

   CONSTANT c_rd_latency      : NATURAL := 1;
   CONSTANT c_pipeline        : NATURAL := g_reg.latency - c_rd_latency;
   CONSTANT c_pipe_dat_addr_w : NATURAL := g_reg.adr_w + g_reg.dat_w;

   TYPE t_data_array IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR(g_reg.dat_w-1 DOWNTO 0);

   ---------------------------------------------------------------------------
   -- SIGNAL DECLARATIONS  --
   ---------------------------------------------------------------------------


   SIGNAL write_latch_in   : STD_LOGIC_VECTOR(c_pipe_dat_addr_w-1 DOWnTO 0);
   SIGNAL write_latch_out  : STD_LOGIC_VECTOR(c_pipe_dat_addr_w-1 DOWnTO 0);
   SIGNAL wr_adr_user      : STD_LOGIC_VECTOR(g_reg.adr_w-1 DOWnTO 0);
   SIGNAL wr_dat_user      : STD_LOGIC_VECTOR(g_reg.dat_w-1 DOWnTO 0);
   SIGNAL wr_en_user       : STD_LOGIC_VECTOR(0 TO g_reg.nof_slaves-1);
   SIGNAL i_wr_val         : STD_LOGIC_VECTOR(0 TO g_reg.nof_slaves-1);
   SIGNAL i_wr_busy        : STD_LOGIC_VECTOR(0 TO 2*g_reg.nof_slaves-1);

   SIGNAL rd_adr_user      : STD_LOGIC_VECTOR(g_reg.adr_w-1 DOWnTO 0);
   SIGNAL rd_en_user       : STD_LOGIC_VECTOR(0 TO g_reg.nof_slaves-1);
   SIGNAL i_rd_busy_user   : STD_LOGIC_VECTOR(0 TO g_reg.nof_slaves-1);
   SIGNAL i_rd_busy        : STD_LOGIC_VECTOR(0 TO 2*g_reg.nof_slaves-1);

   SIGNAL nxt_reg_wr_arr  : STD_LOGIC_VECTOR(reg_wr_arr'RANGE);
   SIGNAL nxt_reg_rd_arr  : STD_LOGIC_VECTOR(reg_rd_arr'RANGE);

   SIGNAL i_out_reg       : STD_LOGIC_VECTOR(out_reg'RANGE) := (OTHERS => g_reg.init_sl);
   SIGNAL nxt_out_reg     : STD_LOGIC_VECTOR(out_reg'RANGE) := (OTHERS => g_reg.init_sl);

   SIGNAL int_rd_val      : STD_LOGIC_VECTOR(0 TO g_reg.nof_slaves-1) := (OTHERS => '0');
   SIGNAL nxt_rd_val      : STD_LOGIC_VECTOR(0 TO g_reg.nof_slaves-1) := (OTHERS => '0');

   SIGNAL int_wr_val      : STD_LOGIC_VECTOR(0 TO g_reg.nof_slaves-1) := (OTHERS => '0');
   SIGNAL nxt_wr_val      : STD_LOGIC_VECTOR(0 TO g_reg.nof_slaves-1) := (OTHERS => '0');

   SIGNAL int_rd_dat      : t_data_array(0 TO g_reg.nof_slaves-1) := (OTHERS => (OTHERS => g_reg.init_sl));
   SIGNAL nxt_rd_dat      : t_data_array(0 TO g_reg.nof_slaves-1) := (OTHERS => (OTHERS => g_reg.init_sl));

   SIGNAL i_rd_dat         : t_data_array(0 TO g_reg.nof_slaves-1);
   SIGNAL i_rd_val         : STD_LOGIC_VECTOR(0 TO g_reg.nof_slaves-1);

BEGIN

   out_reg <= i_out_reg;

---------------------------------------------------------------------------
-- Write Clock Crossing  --
---------------------------------------------------------------------------

   wr_busy <= '1' WHEN i_wr_busy /= (i_wr_busy'RANGE => '0') ELSE '0';

   write_latch_in <= wr_dat & wr_adr;

   -- Latches data & address on write
   write_latch: ENTITY common_lib.common_delay
   GENERIC MAP (
      g_dat_w  => c_pipe_dat_addr_w,
      g_depth  => 1)
   PORT MAP (
      clk      => mm_clk,
      in_val   => wr_en,
      in_dat   => write_latch_in,
      out_dat  => write_latch_out);

   wr_adr_user <= write_latch_out(g_reg.adr_w-1 DOWNTO 0);
   wr_dat_user <= write_latch_out(c_pipe_dat_addr_w-1 DOWNTO g_reg.adr_w);

   write_slave_gen: FOR i IN 0 TO g_reg.nof_slaves-1 GENERATE

      -- 1 input & 2 output clocks
      write_req: ENTITY common_lib.common_spulse
      GENERIC MAP (
         g_delay_len => 1)
      PORT MAP (
         in_rst      => mm_rst,
         in_clk      => mm_clk,
         in_clken    => '1',
         in_pulse    => wr_en,
         in_busy     => i_wr_busy(2*i+0),
         out_rst     => st_rst(i),
         out_clk     => st_clk(i),
         out_clken   => '1',
         out_pulse   => wr_en_user(i));

      write_ack: ENTITY common_lib.common_spulse
      GENERIC MAP (
         g_delay_len => 1)
      PORT MAP (
         in_rst      => st_rst(i),
         in_clk      => st_clk(i),
         in_clken    => '1',
         in_pulse    => int_wr_val(i),
         in_busy     => i_wr_busy(2*i+1),
         out_rst     => mm_rst,
         out_clk     => mm_clk,
         out_clken   => '1',
         out_pulse   => i_wr_val(i));

   END GENERATE;

   wr_val <= '1' WHEN i_wr_val /= (i_wr_val'RANGE => '0') ELSE '0';

---------------------------------------------------------------------------
-- Read Clock Crossing  --
---------------------------------------------------------------------------

   rd_busy <= '1' WHEN i_rd_busy /= (i_rd_busy'RANGE => '0') ELSE '0';

   -- Latches address on read
   read_latch: ENTITY common_lib.common_delay
   GENERIC MAP (
      g_dat_w  => g_reg.adr_w,
      g_depth  => 1)
   PORT MAP (
      clk      => mm_clk,
      in_val   => rd_en,
      in_dat   => rd_adr,
      out_dat  => rd_adr_user);

   read_slave_gen: FOR i IN 0 TO g_reg.nof_slaves-1 GENERATE

      read_req: ENTITY common_lib.common_spulse
      GENERIC MAP (
         g_delay_len => 1)
      PORT MAP (
         in_rst      => mm_rst,
         in_clk      => mm_clk,
         in_clken    => '1',
         in_pulse    => rd_en,
         in_busy     => i_rd_busy(2*i+0),
         out_rst     => st_rst(i),
         out_clk     => st_clk(i),
         out_clken   => '1',
         out_pulse   => rd_en_user(i));

      -- Latch response in source domain (should be latched anyway)
      u_pipe_rd : ENTITY common_lib.common_delay
      GENERIC MAP (
         g_depth   => 1,
         g_dat_w   => g_reg.dat_w)
      PORT MAP (
         clk     => st_clk(i),
         in_val  => int_rd_val(i),
         in_dat  => int_rd_dat(i),
         out_dat => i_rd_dat(i));

      -- 1 input & 2 output clocks
      read_ack: ENTITY common_lib.common_spulse
      GENERIC MAP (
         g_delay_len => 1)
      PORT MAP (
         in_rst      => st_rst(i),
         in_clk      => st_clk(i),
         in_clken    => '1',
         in_pulse    => int_rd_val(i),
         in_busy     => i_rd_busy_user(i),
         out_rst     => mm_rst,
         out_clk     => mm_clk,
         out_clken   => '1',
         out_pulse   => i_rd_val(i));

      -- Cross back to AXI clock
      busy_cross: ENTITY common_lib.common_delay
      GENERIC MAP (
         g_dat_w     => 1,
         g_depth     => 1)
      PORT MAP (
         clk         => mm_clk,
         in_val      => '1',
         in_dat(0)   => i_rd_busy_user(i),
         out_dat(0)  => i_rd_busy(2*i+1));
   END GENERATE;

   rd_val <= '1' WHEN i_rd_val /= (i_rd_val'RANGE => '0') ELSE '0';

   out_sel : PROCESS (i_rd_dat, i_rd_val)
   BEGIN
      rd_dat <= (OTHERS => '0');
      FOR i IN 0 TO g_reg.nof_slaves-1 LOOP
         IF i_rd_val(i) = '1' THEN
            rd_dat <= i_rd_dat(i);
         END IF;
      END LOOP;
   END PROCESS;

---------------------------------------------------------------------------
-- Control  --
---------------------------------------------------------------------------

   p_control : PROCESS (rd_en_user, int_rd_dat, rd_adr_user, in_reg, i_out_reg, wr_adr_user, wr_en_user, wr_dat_user)
   BEGIN
      nxt_reg_rd_arr <= (OTHERS=>'0');
      nxt_rd_dat <= int_rd_dat;
      nxt_rd_val <= (OTHERS => '0');
      FOR i IN 0 TO g_reg.nof_slaves-1 LOOP
         IF rd_en_user(i) = '1' THEN
            FOR j IN 0 TO g_reg.nof_dat-1 LOOP
               IF UNSIGNED(rd_adr_user) = (i*g_reg.nof_dat+j + g_reg.addr_base) THEN
                  nxt_reg_rd_arr(i*g_reg.nof_dat+j) <= '1';
                  nxt_rd_dat(i) <= in_reg((i*g_reg.nof_dat+j+1)*g_reg.dat_w-1 DOWNTO (i*g_reg.nof_dat+j)*g_reg.dat_w);
                  nxt_rd_val(i) <= '1';
               END IF;
            END LOOP;
         END IF;
      END LOOP;

      nxt_reg_wr_arr <= (OTHERS=>'0');
      nxt_out_reg <= i_out_reg;
      nxt_wr_val <= (OTHERS => '0');
      FOR i IN 0 TO g_reg.nof_slaves-1 LOOP
         IF wr_en_user(i) = '1' THEN
            FOR j IN 0 TO g_reg.nof_dat-1 LOOP
               IF UNSIGNED(wr_adr_user) = (i*g_reg.nof_dat+j + g_reg.addr_base) THEN
                  nxt_reg_wr_arr(i*g_reg.nof_dat+j) <= '1';
                  nxt_out_reg((i*g_reg.nof_dat+j+1)*g_reg.dat_w-1 DOWNTO (i*g_reg.nof_dat+j)*g_reg.dat_w) <= wr_dat_user;
                  nxt_wr_val(i) <= '1';
               END IF;
            END LOOP;
         ELSIF rd_en_user(i) = '1' THEN
            FOR j in 0 to g_reg.nof_dat-1 LOOP
               IF UNSIGNED(rd_adr_user) = (i*g_reg.nof_dat+j + g_reg.addr_base) THEN
                  nxt_out_reg((i*g_reg.nof_dat+j+1)*g_reg.dat_w-1 DOWNTO (i*g_reg.nof_dat+j)*g_reg.dat_w) <= i_out_reg((i*g_reg.nof_dat+j+1)*g_reg.dat_w-1 DOWNTO (i*g_reg.nof_dat+j)*g_reg.dat_w) and not g_clr_mask((i*g_reg.nof_dat+j+1)*g_reg.dat_w-1 DOWNTO (i*g_reg.nof_dat+j)*g_reg.dat_w);
               END IF;
            END LOOP;
         END IF;
      END LOOP;
   END PROCESS;

---------------------------------------------------------------------------
-- Register  --
---------------------------------------------------------------------------

   process_gen: FOR i IN 0 TO g_reg.nof_slaves-1 GENERATE
      p_reg : PROCESS (st_rst, st_clk)
      BEGIN
         IF st_rst(i) = '1' THEN
            -- Internal signals.
            i_out_reg(g_reg.dat_w*g_reg.nof_dat*(i+1)-1 DOWNTO g_reg.dat_w*g_reg.nof_dat*i) <= g_init_reg(g_reg.dat_w*g_reg.nof_dat-1 DOWNTO 0);
         ELSIF rising_edge(st_clk(i)) THEN
            -- Output signals.
            reg_wr_arr((i+1)*g_reg.nof_dat-1 DOWNTO i*g_reg.nof_dat) <= nxt_reg_wr_arr((i+1)*g_reg.nof_dat-1 DOWNTO i*g_reg.nof_dat);
            reg_rd_arr((i+1)*g_reg.nof_dat-1 DOWNTO i*g_reg.nof_dat) <= nxt_reg_rd_arr((i+1)*g_reg.nof_dat-1 DOWNTO i*g_reg.nof_dat);
            int_rd_val(i) <= nxt_rd_val(i);
            int_wr_val(i) <= nxt_wr_val(i);
            int_rd_dat(i) <= nxt_rd_dat(i);

            -- Internal signals.
            i_out_reg((i+1)*g_reg.nof_dat*g_reg.dat_w-1 DOWNTO i*g_reg.nof_dat*g_reg.dat_w) <= nxt_out_reg((i+1)*g_reg.nof_dat*g_reg.dat_w-1 DOWNTO i*g_reg.nof_dat*g_reg.dat_w);
         END IF;
      END PROCESS;
   END GENERATE;


END rtl;
