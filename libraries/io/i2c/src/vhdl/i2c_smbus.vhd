-------------------------------------------------------------------------------
--
-- Copyright (C) 2009
-- ASTRON (Netherlands Institute for Radio Astronomy) <http://www.astron.nl/>
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

LIBRARY ieee, common_lib;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
USE ieee.std_logic_1164.all;
--USE IEEE.numeric_std.ALL;
USE ieee.std_logic_arith.all;
USE common_lib.common_pkg.ALL;
USE work.i2c_pkg.ALL;
USE work.i2c_smbus_pkg.ALL;


ENTITY i2c_smbus is
  GENERIC (
    g_i2c_phy                 : t_c_i2c_phy
  );
  port (
    -- GENERIC Signal
    gs_sim      : IN BOOLEAN := FALSE;
    clk         : IN STD_LOGIC;
    rst         : IN STD_LOGIC;
    in_dat      : IN STD_LOGIC_VECTOR(c_byte_w-1 DOWNTO 0);
    in_req      : IN STD_LOGIC;
    out_dat     : OUT STD_LOGIC_VECTOR(c_byte_w-1 DOWNTO 0);
    out_val     : OUT STD_LOGIC;
    out_err     : OUT STD_LOGIC;
    out_ack     : OUT STD_LOGIC;
    st_idle     : OUT STD_LOGIC;
    st_end      : OUT STD_LOGIC;
    busy        : OUT STD_LOGIC;
    al          : OUT STD_LOGIC;

    scl_reg     : OUT STD_LOGIC;
    sda_reg     : OUT STD_LOGIC;

    scl         : INOUT STD_LOGIC;
    sda         : INOUT STD_LOGIC
  );
END ENTITY;


ARCHITECTURE rtl OF i2c_smbus IS

  CONSTANT c_i2c_octet_sz : NATURAL := 9;

  -- CONSTANT Signals that depend on GENERIC Signal gs_sim
  SIGNAL cs_clk_cnt       : unsigned(15 downto 0);
  SIGNAL cs_comma_w       : NATURAL;

  SIGNAL pid         : INTEGER RANGE 0 TO 255;
  SIGNAL nxt_pid     : INTEGER RANGE 0 TO 255;
  SIGNAL pix         : NATURAL RANGE 0 TO SMBUS_PROTOCOL'HIGH;
  SIGNAL nxt_pix     : NATURAL;
  SIGNAL adr         : STD_LOGIC_VECTOR(6 DOWNTO 0);
  SIGNAL nxt_adr     : STD_LOGIC_VECTOR(6 DOWNTO 0);
  SIGNAL cnt         : INTEGER RANGE 0 TO 255;
  SIGNAL nxt_cnt     : INTEGER RANGE 0 TO 255;

  SIGNAL op          : OPCODE;
  SIGNAL nxt_op      : OPCODE;

  SIGNAL rdy         : STD_LOGIC;
  SIGNAL nrst        : STD_LOGIC;
  SIGNAL srst        : STD_LOGIC_VECTOR(0 TO 2);
  SIGNAL nxt_srst    : STD_LOGIC_VECTOR(srst'RANGE);

  SIGNAL scl_i       : STD_LOGIC;
  SIGNAL sda_i_reg   : STD_LOGIC;
  SIGNAL scl_o       : STD_LOGIC;
  SIGNAL scl_i_reg   : STD_LOGIC;
  SIGNAL sda_o       : STD_LOGIC;


  SIGNAL scl_oe      : STD_LOGIC;
  SIGNAL scl_oe_comma_reg    : STD_LOGIC;
  SIGNAL sda_oe      : STD_LOGIC;
  SIGNAL sda_oe_reg    : STD_LOGIC;

  -- Insert comma after start and after each octet to support slow I2C slave
  SIGNAL scl_cnt      : INTEGER RANGE 0 TO c_i2c_octet_sz;
  SIGNAL nxt_scl_cnt  : INTEGER RANGE 0 TO c_i2c_octet_sz;
  SIGNAL scl_m        : STD_LOGIC;     -- master driven scl, used to detect scl edge change independent of slow scl
  SIGNAL nxt_scl_m    : STD_LOGIC;
  SIGNAL sda_m        : STD_LOGIC;     -- master driven sda, used to detect scl edge change independent of slow sda
  SIGNAL nxt_sda_m    : STD_LOGIC;
  SIGNAL scl_m_dly    : STD_LOGIC;
  SIGNAL sda_m_dly    : STD_LOGIC;
  SIGNAL start_detect : STD_LOGIC;
  SIGNAL octet_end    : STD_LOGIC;
  SIGNAL scl_m_n      : STD_LOGIC;
  SIGNAL comma_hi     : STD_LOGIC;
  SIGNAL comma        : STD_LOGIC;
  SIGNAL comma_dly    : STD_LOGIC;
  SIGNAL comma_evt    : STD_LOGIC;
  SIGNAL comma_sc_low : STD_LOGIC;
  SIGNAL comma_sc_low_yes : STD_LOGIC;  -- drives comma_sc_low when comma time is supported
  SIGNAL comma_sc_low_no  : STD_LOGIC;  -- drives comma_sc_low when comma time is not supported

  SIGNAL i2c_start   : STD_LOGIC;
  SIGNAL i2c_stop    : STD_LOGIC;
  SIGNAL i2c_read    : STD_LOGIC;
  SIGNAL i2c_write   : STD_LOGIC;
  SIGNAL i2c_ack_in  : STD_LOGIC;
  SIGNAL i2c_dat_in  : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL i2c_dat_out : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL i2c_cmd_ack : STD_LOGIC;
  SIGNAL i2c_ack_out : STD_LOGIC;

  SIGNAL i_out_dat   : STD_LOGIC_VECTOR(out_dat'RANGE);
  SIGNAL nxt_out_dat : STD_LOGIC_VECTOR(out_dat'RANGE);
  SIGNAL nxt_out_val : STD_LOGIC;
  SIGNAL i_out_err   : STD_LOGIC;
  SIGNAL nxt_out_err : STD_LOGIC;

  SIGNAL op_val      : STD_LOGIC;
  SIGNAL nxt_op_val  : STD_LOGIC;

  SIGNAL ld_to         : STD_LOGIC;
  SIGNAL to_index      : NATURAL RANGE 0 TO c_smbus_timeout_nof_byte-1;
  SIGNAL nxt_to_index  : NATURAL RANGE 0 TO c_smbus_timeout_nof_byte-1;
  SIGNAL to_cnt_en     : STD_LOGIC;
  SIGNAL to_cnt        : STD_LOGIC_VECTOR(c_smbus_timeout_w-1 DOWNTO 0);
  SIGNAL to_value      : STD_LOGIC_VECTOR(c_smbus_timeout_word_w-1 DOWNTO 0);
  SIGNAL nxt_to_value  : STD_LOGIC_VECTOR(c_smbus_timeout_word_w-1 DOWNTO 0);
  SIGNAL timeout       : STD_LOGIC;
  SIGNAL nxt_timeout   : STD_LOGIC;
  SIGNAL i2c_busy      : STD_LOGIC;
  SIGNAL i2c_al        : STD_LOGIC;

   ATTRIBUTE KEEP                      : BOOLEAN;
   ATTRIBUTE KEEP OF sda_oe_reg        : SIGNAL IS TRUE;
   ATTRIBUTE KEEP OF scl_oe_comma_reg  : SIGNAL IS TRUE;

BEGIN

  -- CONSTANT Signals dependent on GENERIC Signal gs_sim
  cs_clk_cnt <= conv_unsigned(g_i2c_phy.clk_cnt, cs_clk_cnt'LENGTH) WHEN gs_sim=FALSE ELSE
                conv_unsigned(c_i2c_clk_cnt_sim, cs_clk_cnt'LENGTH);
  cs_comma_w <= g_i2c_phy.comma_w WHEN gs_sim=FALSE ELSE c_i2c_comma_w_dis;

  out_dat <= i_out_dat;
  out_err <= i_out_err;

  scl <= scl_o when scl_oe_comma_reg = '0' else 'Z';  -- note scl_o is fixed '0' in i2c_bit
  sda <= sda_o when sda_oe_reg       = '0' else 'Z';  -- note sda_o is fixed '0' in i2c_bit

  nrst <= NOT rst;

  busy <= i2c_busy;
  al <= i2c_al;

  p_srst : PROCESS(clk)
  BEGIN
    IF rising_edge(clk) THEN
      srst             <= '0' & srst(0 TO srst'HIGH-1);
      scl_oe_comma_reg <= scl_oe AND NOT(comma_sc_low);
      sda_oe_reg       <= sda_oe;

      sda_i_reg        <= to_x01(sda);  -- sample SDA line
      scl_i_reg        <= to_x01(scl);
    END IF;
  END PROCESS;

   scl_reg <= scl_i_reg;
   sda_reg <= sda_i_reg;

  byte : ENTITY work.i2c_byte
  PORT MAP (
    clk         => clk,
    rst         => srst(srst'HIGH),
    ena         => '1',
    clk_cnt     => cs_clk_cnt,
    nReset      => nrst,
    read        => i2c_read,
    write       => i2c_write,
    start       => i2c_start,
    stop        => i2c_stop,
    ack_in      => i2c_ack_in,
    cmd_ack     => i2c_cmd_ack,
    i2c_busy    => i2c_busy,
    i2c_al      => i2c_al,
    Din         => i2c_dat_in,
    Dout        => i2c_dat_out,
    ack_out     => i2c_ack_out,
    scl_i       => scl_i_reg,
    scl_o       => scl_o,
    scl_oen     => scl_oe,
    sda_i       => sda_i_reg,
    sda_o       => sda_o,
    sda_oen     => sda_oe
  );

  comma_sc_low <= comma_sc_low_no WHEN cs_comma_w=0 ELSE comma_sc_low_yes;

  no_comma : IF g_i2c_phy.comma_w=0 GENERATE
    comma_sc_low_no <= '0';
  END GENERATE;

  gen_comma : IF g_i2c_phy.comma_w>0 GENERATE
    p_comma_reg : PROCESS(rst, clk)
    BEGIN
      IF rst='1' THEN
        scl_m     <= '0';
        sda_m     <= '0';
        scl_m_dly <= '0';
        sda_m_dly <= '0';
        scl_cnt   <= 0;
        comma_dly <= '0';
     ELSIF rising_edge(clk) THEN
        scl_m     <= nxt_scl_m;
        sda_m     <= nxt_sda_m;
        scl_m_dly <= scl_m;
        sda_m_dly <= sda_m;
        scl_cnt   <= nxt_scl_cnt;
        comma_dly <= comma;
     END IF;
    END PROCESS;

    nxt_scl_m <= scl_oe;
    nxt_sda_m <= sda_oe;

    start_detect <= scl_m_dly AND scl_m AND sda_m_dly AND NOT sda_m;
    octet_end <= '1' WHEN scl_cnt = c_i2c_octet_sz ELSE '0';

    bit_count : PROCESS (scl_cnt, start_detect, octet_end, scl_m_dly, scl_m)
    BEGIN
      nxt_scl_cnt <= scl_cnt;
      IF start_detect='1' OR octet_end='1' THEN
        nxt_scl_cnt <= 0;
      ELSIF scl_m_dly='0' AND scl_m/='0' THEN
        nxt_scl_cnt <= scl_cnt + 1;
      END IF;
    END PROCESS;

    comma_hi <= start_detect OR octet_end;
    scl_m_n <= NOT scl_m;

    u_comma : ENTITY common_lib.common_switch
    GENERIC MAP (
      g_rst_level => '0'
    )
    PORT MAP (
      clk         => clk,
      rst         => rst,
      switch_high => comma_hi,
      switch_low  => scl_m_n,
      out_level   => comma
    );

    comma_evt <= NOT comma AND comma_dly;

    u_comma_sc_low : ENTITY common_lib.common_pulse_extend
    GENERIC MAP (
      g_rst_level    => '0',
      g_p_in_level   => '1',
      g_ep_out_level => '1',
      g_extend_w     => g_i2c_phy.comma_w
    )
    PORT MAP (
      rst     => rst,
      clk     => clk,
      p_in    => comma_evt,
      ep_out  => comma_sc_low_yes
    );
  END GENERATE;  -- gen_comma

  regs : PROCESS(rst, clk)
  BEGIN
    IF rst='1' THEN
      pix       <= 0;
      pid       <= 0;
      cnt       <= 0;
      op        <= OP_IDLE;
      op_val    <= '1';
      adr       <= (OTHERS => '0');
      i_out_dat <= (OTHERS => '0');
      i_out_err <= '0';
      out_val   <= '0';
      to_index  <= 0;
      to_value  <= (OTHERS => '0');
      timeout   <= '0';
   ELSIF rising_edge(clk) THEN
      pix       <= nxt_pix;
      pid       <= nxt_pid;
      op        <= nxt_op;
      op_val    <= nxt_op_val;
      cnt       <= nxt_cnt;
      adr       <= nxt_adr;
      i_out_dat <= nxt_out_dat;
      i_out_err <= nxt_out_err;
      out_val   <= nxt_out_val;
      to_index  <= nxt_to_index;
      to_value  <= nxt_to_value;
      timeout   <= nxt_timeout;
   END IF;
  END PROCESS;

  get_op : PROCESS(pid,pix,op,rdy)
  BEGIN
    nxt_pix <= pix;
    nxt_op_val <= '1';
    IF op=OP_IDLE AND rdy='1' THEN
      nxt_pix    <=  0;
      nxt_op_val <= '0';
    ELSIF rdy='1' THEN
      nxt_pix  <= pix + 1;
      nxt_op_val <= '0';
    END IF;

    IF pid>c_smbus_unknown_protocol THEN
      nxt_op <= SMBUS_PROTOCOLS(SMBUS_C_END)(pix);
    ELSE
      nxt_op <= SMBUS_PROTOCOLS(pid)(pix);
    END IF;
  END PROCESS;

  decode_opcode : PROCESS(adr, cnt, to_index, to_value, i_out_dat, i_out_err, pid,
                          op_val, op, in_req, in_dat, sda_i_reg,
                          i2c_cmd_ack, i2c_ack_out, i2c_dat_out, timeout)
  BEGIN

    nxt_adr <= adr;
    nxt_cnt <= cnt;

    -- default values
    i2c_start    <= '0';
    i2c_stop     <= '0';
    i2c_read     <= '0';
    i2c_write    <= '0';
    i2c_ack_in   <= '0';
    i2c_dat_in   <= (OTHERS => '0');

    nxt_to_index <= to_index;
    nxt_to_value <= to_value;
    ld_to        <= '0';

    -- default output values
    nxt_out_dat <= i_out_dat;
    nxt_out_err <= i_out_err;
    nxt_out_val <= '0';
    out_ack <= '0';
    st_idle <= '0';
    st_end  <= '0';

    nxt_pid <= pid;

    rdy <= '0';

    -- generate the i2c control signals
    IF op_val='1' THEN
      CASE op IS
        WHEN OP_IDLE =>
          st_idle <= '1';
          IF in_req='1' THEN
            nxt_pid      <= conv_integer(unsigned(in_dat));
            nxt_out_err  <= '0';
            out_ack      <= '1';
            rdy          <= '1';

          END IF;

        WHEN OP_RD_SDA =>
          IF in_req='1' THEN
            nxt_out_err  <= NOT To_X01(sda_i_reg);  -- expect pull up
            rdy          <= '1';
          END IF;

        WHEN OP_END =>
          st_end  <= '1';
          out_ack <= '1';
          rdy     <= '1';

        WHEN OP_LD_ADR =>
          IF in_req='1' THEN
            nxt_adr <= in_dat(6 DOWNTO 0);
            out_ack <= '1';
            rdy     <= '1';
          END IF;

        WHEN OP_LD_CNT =>
          IF in_req='1' THEN
            nxt_cnt <= conv_integer(unsigned(in_dat));
            out_ack <= '1';
            rdy     <= '1';
          END IF;

        WHEN OP_WR_ADR_WR  =>
          IF i2c_cmd_ack='1' THEN
            nxt_out_err  <= To_X01(i2c_ack_out);
            rdy          <= '1';
          ELSE
            i2c_start    <= '1';
            i2c_write    <= '1';
            i2c_dat_in   <= adr & '0' ;
          END IF;

        WHEN OP_WR_ADR_RD  =>
          IF i2c_cmd_ack='1' THEN
            nxt_out_err  <= To_X01(i2c_ack_out);
            rdy          <= '1';
          ELSE
            i2c_start    <= '1';
            i2c_write    <= '1';
            i2c_dat_in   <= adr & '1';
          END IF;

        WHEN OP_WR_CNT  =>
          IF i2c_cmd_ack='1' THEN
            nxt_out_err  <= To_X01(i2c_ack_out);
            rdy          <= '1';
          ELSE
            i2c_write    <= '1';
            i2c_dat_in   <= STD_LOGIC_VECTOR(conv_unsigned(cnt,8));
          END IF;

        WHEN OP_WR_DAT  =>
          IF i2c_cmd_ack='1' THEN
            nxt_out_err  <= To_X01(i2c_ack_out);
            out_ack      <= '1';
            rdy          <= '1';
          ELSE
            IF in_req='1' THEN
              i2c_write  <= '1';
              i2c_dat_in <= in_dat;
            END IF;
          END IF;

        WHEN OP_WR_BLOCK  =>
          IF i2c_cmd_ack='1' THEN
            nxt_out_err  <= To_X01(i2c_ack_out);
            out_ack      <= '1';
            nxt_cnt      <= cnt-1;
            IF cnt=1 THEN
              rdy <= '1';
            END IF;
          ELSE
            IF in_req='1' THEN
              i2c_write  <= '1';
              i2c_dat_in <= in_dat;
            END IF;
          END IF;

        WHEN OP_RD_ACK  =>
          IF i2c_cmd_ack='1' THEN
            nxt_out_dat  <= To_X01(i2c_dat_out);
            nxt_out_val  <= '1';
            rdy          <= '1';
          ELSE
            i2c_read     <= '1';
            i2c_ack_in   <= '0';
          END IF;

        WHEN OP_RD_NACK  =>
          IF i2c_cmd_ack='1' THEN
            nxt_out_dat  <= To_X01(i2c_dat_out);
            nxt_out_val  <= '1';
            rdy          <= '1';
          ELSE
            i2c_read     <= '1';
            i2c_ack_in   <= '1';
          END IF;

        WHEN OP_RD_BLOCK  =>
          IF i2c_cmd_ack='1' THEN
            nxt_out_dat  <= To_X01(i2c_dat_out);
            nxt_out_val  <= '1';
            nxt_cnt      <= cnt-1;
            IF cnt=1 THEN
              rdy <= '1';
            END IF;
          ELSE
            i2c_read     <= '1';
            IF cnt=1 THEN
              i2c_ack_in <= '1';
            ELSE
              i2c_ack_in <= '0';
            END IF;
          END IF;

        WHEN OP_STOP =>
          IF i2c_cmd_ack='1' THEN
            rdy          <= '1';
          ELSE
            i2c_stop     <= '1';
          END IF;

        WHEN OP_LD_TIMEOUT =>
          IF in_req='1' THEN
            FOR i IN 0 TO c_smbus_timeout_nof_byte-1 LOOP
              IF i = to_index THEN
                nxt_to_value(7+i*8 DOWNTO i*8) <= in_dat;
              END IF;
            END LOOP;
            IF to_index = c_smbus_timeout_nof_byte-1 THEN
              nxt_to_index <= 0;
              ld_to <= '1';
            ELSE
              nxt_to_index <= to_index+1;
            END IF;
            out_ack <= '1';
            rdy     <= '1';
          END IF;

        WHEN OP_WAIT =>
          IF timeout='1' THEN
            nxt_to_index <= 0;
            rdy          <= '1';
          END IF;

        WHEN OTHERS =>
          nxt_out_err <= '1';
          rdy         <= '1';
          REPORT "Illegal opcode ";
      END CASE;
    END IF;
  END PROCESS;


  to_cnt_en <= NOT timeout;

  u_timeout : ENTITY common_lib.common_counter
  GENERIC MAP(
    g_width     => to_cnt'LENGTH
  )
  PORT MAP(
    rst     => rst,
    clk     => clk,
    cnt_clr => ld_to,
    cnt_en  => to_cnt_en,
    count   => to_cnt
  );

  nxt_timeout <= '1' WHEN UNSIGNED(to_cnt) > UNSIGNED(to_value(to_cnt'RANGE)) ELSE '0';

END ARCHITECTURE;
