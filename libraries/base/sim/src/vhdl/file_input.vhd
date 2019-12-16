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

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;


ENTITY file_input IS
  GENERIC (
    g_file_name   : STRING;
    g_file_repeat : NATURAL := 1;
    g_nof_data    : NATURAL := 1;
    g_data_width  : NATURAL;
    g_data_type   : STRING := "SIGNED"
  );
  PORT (
    clk      : IN  STD_LOGIC;
    rst      : IN  STD_LOGIC;
    en       : IN  STD_LOGIC := '1';
    sync     : IN  STD_LOGIC := '1';
    out_dat  : OUT STD_LOGIC_VECTOR(g_nof_data*g_data_width-1 DOWNTO 0);
    out_val  : OUT STD_LOGIC;
    out_sync : OUT STD_LOGIC;
    out_msg  : OUT STRING(1 TO 80);
    out_lno  : OUT NATURAL;
    out_rep  : OUT NATURAL;
    out_eof  : OUT STD_LOGIC;
    out_wait : OUT STD_LOGIC
  );
BEGIN
  ASSERT g_data_type = "SIGNED" OR g_data_type = "UNSIGNED"
    REPORT "Unknown data type."
    SEVERITY ERROR;
END file_input;


ARCHITECTURE beh OF file_input IS

  CONSTANT c_prag         : CHARACTER := '%';
  CONSTANT c_prag_sync    : STRING := c_prag & "SYNC";
  CONSTANT c_prag_gap     : STRING := c_prag & "GAP ";
  CONSTANT c_prag_msg     : STRING := c_prag & "MSG ";
  CONSTANT c_prag_next    : STRING := c_prag & "NEXT";


  TYPE STATE_TYPE IS
    ( s_init, s_idle, s_next, s_read, s_enable, s_data, s_pragma, s_msg, s_sync, s_gap, s_eof);

  SIGNAL state           : STATE_TYPE;
  SIGNAL nxt_state       : STATE_TYPE;

  SIGNAL rd_dat      : STD_LOGIC_VECTOR(out_dat'RANGE);
  SIGNAL nxt_rd_dat  : STD_LOGIC_VECTOR(out_dat'RANGE);
  SIGNAL rd_val      : STD_LOGIC;
  SIGNAL nxt_rd_val  : STD_LOGIC;

  SIGNAL eof     : STD_LOGIC;
  SIGNAL nxt_eof : STD_LOGIC;
  SIGNAL lno     : NATURAL;
  SIGNAL nxt_lno : NATURAL;
  SIGNAL rep     : NATURAL;
  SIGNAL nxt_rep : NATURAL;
  SIGNAL msg     : STRING(out_msg'RANGE);
  SIGNAL nxt_msg : STRING(msg'RANGE);
  SIGNAL gap_count     : NATURAL;
  SIGNAL nxt_gap_count : NATURAL;
  SIGNAL nxt_wait    : STD_LOGIC;
  SIGNAL nxt_sync : STD_LOGIC;

BEGIN

  out_dat <= rd_dat;
  out_val <= rd_val;
  out_eof <= eof;
  out_lno <= lno;
  out_rep <= rep;
  out_msg <= msg;

  regs: PROCESS(rst, clk)
  BEGIN
    IF rst='1' THEN
      state     <= s_init;
      rd_dat    <= (OTHERS => '0');
      rd_val    <= '0';
      eof       <= '0';
      lno       <= 0;
      rep       <= 1;
      msg       <= (OTHERS => ' ');
      gap_count <= 0;
      out_wait  <= '0';
      out_sync  <= '0';
    ELSIF RISING_EDGE(clk) THEN
      state     <= nxt_state;
      rd_dat    <= nxt_rd_dat;
      rd_val    <= nxt_rd_val;
      eof       <= nxt_eof;
      lno       <= nxt_lno;
      rep       <= nxt_rep;
      msg       <= nxt_msg;
      gap_count <= nxt_gap_count;
      out_wait  <= nxt_wait;
      out_sync  <= nxt_sync;
    END IF;
  END PROCESS;

  PROCESS (rst, state, eof, sync, en, gap_count, msg, lno, rep)

    VARIABLE  file_status  : FILE_OPEN_STATUS;
    FILE      in_file : TEXT ;
    VARIABLE  in_line : LINE;
    VARIABLE  num     : INTEGER;
    VARIABLE  cycle_lno : INTEGER;      -- file line number
    VARIABLE  cycle_rep : NATURAL;      -- read file g_file_repeat times
    VARIABLE  cycle_state     : STATE_TYPE;
    VARIABLE  nxt_cycle_state : STATE_TYPE;


    PROCEDURE show_msg(sev : IN SEVERITY_LEVEL; msg : IN STRING) IS
    BEGIN
      REPORT msg & character'val(13)
             & "    Repeat: " & INTEGER'IMAGE(cycle_rep)
             & "    Line: " & INTEGER'IMAGE(cycle_lno)
             & "    File: " & g_file_name
        SEVERITY sev;
    END show_msg;

  BEGIN
    nxt_cycle_state := state;
    cycle_lno := lno;
    cycle_rep := rep;

    nxt_rd_dat <= (OTHERS => '0');
    nxt_rd_val <= '0';
    nxt_eof <= '0';
    nxt_msg <= msg;
    nxt_lno <= lno;
    nxt_rep <= rep;
    nxt_gap_count <= 0;
    nxt_wait <= '0';
    nxt_sync <= '0';

    -- We use a loop to enable mutiple state transitions
    -- within a clock cycle.
    -- To break out of the loop,  'EXIT cycle' is used. This will
    -- bring the process to the next clock cycle.

    cycle: LOOP
      -- cycle_state signal is used to hold the current state
      cycle_state := nxt_cycle_state;

      CASE cycle_state IS
        WHEN s_init =>
          IF rst='0' THEN
            IF file_status=OPEN_OK THEN
              file_close(in_file);
            END IF;
            file_open (file_status, in_file, g_file_name, READ_MODE);
            IF file_status=OPEN_OK THEN
              nxt_cycle_state := s_next;
              show_msg(NOTE,"file opened for reading");
            ELSE
              nxt_cycle_state := s_idle;
              show_msg(WARNING,"unable to open file");
              EXIT;
            END IF;
          ELSE
            EXIT cycle;
          END IF;

        WHEN s_idle =>
          IF cycle_rep < g_file_repeat THEN
            cycle_lno := 0;
            cycle_rep := cycle_rep + 1;
            nxt_cycle_state := s_init;
          ELSE
            -- do nothing
            nxt_rd_dat <= (OTHERS  => '0');
            nxt_rd_val <= '0';
            nxt_eof <= eof;
            EXIT cycle;
          END IF;

        WHEN s_next =>
          -- check if end of file is reached
          IF ENDFILE(in_file) THEN
            show_msg(NOTE, "end of file");
            nxt_eof   <= '1';
            nxt_cycle_state := s_idle;
          ELSE
            nxt_cycle_state := s_read;
          END IF;

        WHEN s_read =>
          -- read a line from the file
          READLINE(in_file, in_line);
          cycle_lno := cycle_lno+1;
          IF in_line'LENGTH >= 1 AND in_line(1)=c_prag THEN
            nxt_cycle_state := s_pragma;
          ELSE
            nxt_cycle_state := s_enable;
          END IF;

        WHEN s_enable =>
          -- wait for enable to become high
          IF en='1' THEN
            nxt_cycle_state := s_data;
          ELSE
            EXIT cycle;
          END IF;

        WHEN s_data =>
          -- output data
          FOR i IN 0 TO g_nof_data-1 LOOP
            READ(in_line, num);
            IF g_data_type = "UNSIGNED" THEN
              nxt_rd_dat((i+1)*g_data_width-1 DOWNTO i*g_data_width) <= STD_LOGIC_VECTOR(TO_UNSIGNED(num, g_data_width));
            ELSE
              nxt_rd_dat((i+1)*g_data_width-1 DOWNTO i*g_data_width) <= STD_LOGIC_VECTOR(TO_SIGNED(num, g_data_width));
            END IF;
          END LOOP;
          nxt_rd_val  <= '1';
          nxt_cycle_state := s_next;
          EXIT cycle;

        WHEN s_pragma =>
          -- handle pragmas
          CASE in_line(1 TO 5) IS
            WHEN c_prag_msg  => nxt_cycle_state := s_msg;
            WHEN c_prag_gap  => nxt_cycle_state := s_gap;
            WHEN c_prag_sync => nxt_cycle_state := s_sync;
            WHEN c_prag_next => nxt_cycle_state := s_sync;
            WHEN OTHERS =>
              show_msg(ERROR, "unknown pragma: " & in_line(1 TO in_line'LENGTH));
              nxt_cycle_state := s_next;
          END CASE;

        WHEN s_msg =>
          -- handle msg pragma.
          -- This displays a notice to the user, and
          nxt_msg <= (OTHERS => ' ');
          nxt_msg(1 TO in_line'LENGTH-c_prag_gap'LENGTH)
            <= in_line(c_prag_gap'LENGTH+1 TO in_line'LENGTH);
          show_msg(NOTE, in_line(c_prag_gap'LENGTH+1 TO in_line'LENGTH));
          nxt_cycle_state := s_next;

        WHEN s_sync =>
          -- handle sync pragma. This waits sync to become high
          IF sync='1' THEN
            nxt_cycle_state := s_next;
            nxt_sync <= '1';
          ELSE
            nxt_wait <= '1';
            nxt_cycle_state := s_sync;
            EXIT cycle;
          END IF;

        WHEN s_gap =>
          -- handle gap pragma. This creates a gap.
          IF gap_count=0 THEN
            -- initialize the counter
            nxt_gap_count <=
              INTEGER'VALUE(in_line(c_prag_gap'LENGTH+1 TO in_line'LENGTH));
            -- create the first gap cycle.
            EXIT cycle;
          ELSIF gap_count>1 THEN
            -- decrease the counter
            nxt_gap_count <= gap_count-1;
            -- create another gap cycle.
            EXIT cycle;
          ELSE
            -- end the gap
            nxt_cycle_state := s_next;
          END IF;

        WHEN OTHERS =>
          -- unkown state.
          REPORT "unknown state"  SEVERITY ERROR;
          nxt_cycle_state := s_idle;
      END CASE;
    END LOOP;

    nxt_state <= nxt_cycle_state;
    nxt_lno   <= cycle_lno;
    nxt_rep   <= cycle_rep;
  END PROCESS;

END beh;
