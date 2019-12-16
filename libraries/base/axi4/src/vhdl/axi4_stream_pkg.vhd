--------------------------------------------------------------------------------
--
-- Copyright (C) 2017
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
--------------------------------------------------------------------------------

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;

PACKAGE axi4_stream_pkg Is

  ------------------------------------------------------------------------------
  -- General DP stream record defintion
  ------------------------------------------------------------------------------

  -- Remarks:
  -- * Choose smallest maximum SOSI slv lengths that fit all use cases, because unconstrained record fields slv is not allowed
  -- * The large SOSI data field width of 256b has some disadvantages:
  --   . about 10% extra simulation time and PC memory usage compared to 72b (measured using tb_unb_tse_board)
  --   . a 256b number has 64 hex digits in the Wave window which is awkward because of the leading zeros when typically
  --     only 32b are used, fortunately integer representation still works OK (except 0 which is shown as blank).
  --   However the alternatives are not attractive, because they affect the implementation of the streaming
  --   components that use the SOSI record. Alternatives are e.g.:
  --   . define an extra long SOSI data field ldata[255:0] in addition to the existing data[71:0] field
  --   . use the array of SOSI records to contain wider data, all with the same SOSI control field values
  --   . define another similar SOSI record with data[255:0].
  --   Therefore define data width as 256b, because the disadvantages are acceptable and the benefit is great, because all
  --   streaming components can remain as they are.
  -- * Added sync and bsn to SOSI to have timestamp information with the data
  -- * Added re and im to SOSI to support complex data for DSP
  CONSTANT c_axi4_stream_data_w     : NATURAL :=  512;   -- Data width, upto 512bit for Xilinx IP
  CONSTANT c_axi4_stream_user_w     : NATURAL :=  70;    -- User data, upto 70bit for Xilinx IP
  CONSTANT c_axi4_stream_tid_w      : NATURAL :=  4;     -- Thread ID, upto 4bit for Xilinx IP
  CONSTANT c_axi4_stream_dest_w     : NATURAL :=  32;    -- Routing data, upto 32bit for Xilinx IP

  TYPE t_axi4_siso IS RECORD  -- Source In and Sink Out
    tready    : STD_LOGIC;                                              -- Ready to accept data from destination
  END RECORD;

  TYPE t_axi4_sosi IS RECORD  -- Source Out and Sink In
    tvalid    : STD_LOGIC;                                              -- Data valid
    tdata     : STD_LOGIC_VECTOR(c_axi4_stream_data_w-1 DOWNTO 0);      -- Data bus
    tstrb     : STD_LOGIC_VECTOR((c_axi4_stream_data_w/8)-1 DOWNTO 0);  -- Byte valids, indicates if data is position (0) or data (1). Generally not used
    tkeep     : STD_LOGIC_VECTOR((c_axi4_stream_data_w/8)-1 DOWNTO 0);  -- Indicate valid data bytes (1) or null bytes (0).
    tlast     : STD_LOGIC;                                              -- Last transaction in a burst
    tid       : STD_LOGIC_VECTOR(c_axi4_stream_tid_w-1 DOWNTO 0);       -- Transaction ID
    tdest     : STD_LOGIC_VECTOR(c_axi4_stream_dest_w-1 DOWNTO 0);      -- Destination rounting information
    tuser     : STD_LOGIC_VECTOR(c_axi4_stream_user_w-1 DOWNTO 0);      -- Tranaction user fields
  END RECORD;


  -- Initialise signal declarations with c_axi4_stream_rst/rdy to ease the interpretation of slv fields with unused bits
  CONSTANT c_axi4_siso_rst   : t_axi4_siso := (tready => '0');
  CONSTANT c_axi4_siso_x     : t_axi4_siso := (tready => 'X');
  CONSTANT c_axi4_siso_hold  : t_axi4_siso := (tready => '0');
  CONSTANT c_axi4_siso_rdy   : t_axi4_siso := (tready => '1');
  CONSTANT c_axi4_siso_flush : t_axi4_siso := (tready => '1');
  CONSTANT c_axi4_sosi_rst   : t_axi4_sosi := (tvalid => '0', tdata => (OTHERS=>'0'), tstrb => (OTHERS=>'0'), tkeep => (OTHERS=>'0'), tlast => '0', tid => (OTHERS=>'0'), tdest => (OTHERS=>'0'), tuser => (OTHERS=>'0'));
  CONSTANT c_axi4_sosi_x     : t_axi4_sosi := ('X', (OTHERS=>'X'), (OTHERS=>'X'), (OTHERS=>'X'), 'X', (OTHERS=>'X'), (OTHERS=>'X'), (OTHERS=>'X'));


  -- Multi port or multi register array for DP stream records
  TYPE t_axi4_siso_arr IS ARRAY (INTEGER RANGE <>) OF t_axi4_siso;
  TYPE t_axi4_sosi_arr IS ARRAY (INTEGER RANGE <>) OF t_axi4_sosi;

  -- Multi-dimemsion array types with fixed LS-dimension
  -- . 2 dimensional array with 2 fixed LS sosi/siso interfaces (axi4_split, axi4_concat)
  TYPE t_axi4_siso_2arr_2 IS ARRAY (INTEGER RANGE <>) OF t_axi4_siso_arr(1 DOWNTO 0);
  TYPE t_axi4_sosi_2arr_2 IS ARRAY (INTEGER RANGE <>) OF t_axi4_sosi_arr(1 DOWNTO 0);

  -- 2-dimensional streaming array type:
  -- Note:
  --   This t_*_mat is less useful then a t_*_2arr array of arrays, because assignments can only be done per element (i.e. not per row). However for t_*_2arr
  --   the arrays dimension must be fixed, so these t_*_2arr types are application dependent and need to be defined where used.
  TYPE t_axi4_siso_mat IS ARRAY (INTEGER RANGE <>, INTEGER RANGE <>) OF t_axi4_siso;
  TYPE t_axi4_sosi_mat IS ARRAY (INTEGER RANGE <>, INTEGER RANGE <>) OF t_axi4_sosi;

  -- Check sosi.valid against siso.ready
  PROCEDURE proc_axi4_siso_alert(CONSTANT c_ready_latency : IN    NATURAL;
                               SIGNAL   clk             : IN    STD_LOGIC;
                               SIGNAL   sosi            : IN    t_axi4_sosi;
                               SIGNAL   siso            : IN    t_axi4_siso;
                               SIGNAL   ready_reg       : INOUT STD_LOGIC_VECTOR);

  -- Default RL=1
  PROCEDURE proc_axi4_siso_alert(SIGNAL   clk             : IN    STD_LOGIC;
                               SIGNAL   sosi            : IN    t_axi4_sosi;
                               SIGNAL   siso            : IN    t_axi4_siso;
                               SIGNAL   ready_reg       : INOUT STD_LOGIC_VECTOR);

  -- SOSI/SISO array version
  PROCEDURE proc_axi4_siso_alert(CONSTANT c_ready_latency : IN    NATURAL;
                               SIGNAL   clk             : IN    STD_LOGIC;
                               SIGNAL   sosi_arr        : IN    t_axi4_sosi_arr;
                               SIGNAL   siso_arr        : IN    t_axi4_siso_arr;
                               SIGNAL   ready_reg       : INOUT STD_LOGIC_VECTOR);

  -- SOSI/SISO array version with RL=1
  PROCEDURE proc_axi4_siso_alert(SIGNAL   clk             : IN    STD_LOGIC;
                               SIGNAL   sosi_arr        : IN    t_axi4_sosi_arr;
                               SIGNAL   siso_arr        : IN    t_axi4_siso_arr;
                               SIGNAL   ready_reg       : INOUT STD_LOGIC_VECTOR);


  -- Keep part of head data and combine part of tail data, use the other sosi from head_sosi
  FUNCTION func_axi4_data_shift_first(head_sosi, tail_sosi : t_axi4_sosi; symbol_w, nof_symbols_per_data, nof_symbols_from_tail              : NATURAL) RETURN t_axi4_sosi;
  -- Shift and combine part of previous data and this data, use the other sosi from prev_sosi
  FUNCTION func_axi4_data_shift(      prev_sosi, this_sosi : t_axi4_sosi; symbol_w, nof_symbols_per_data, nof_symbols_from_this              : NATURAL) RETURN t_axi4_sosi;
  -- Shift part of tail data and account for input empty
  FUNCTION func_axi4_data_shift_last(            tail_sosi : t_axi4_sosi; symbol_w, nof_symbols_per_data, nof_symbols_from_tail, input_empty : NATURAL) RETURN t_axi4_sosi;

  -- Determine resulting empty if two streams are concatenated or split
  FUNCTION func_axi4_empty_concat(head_empty, tail_empty : STD_LOGIC_VECTOR; nof_symbols_per_data : NATURAL) RETURN STD_LOGIC_VECTOR;
  FUNCTION func_axi4_empty_split(input_empty, head_empty : STD_LOGIC_VECTOR; nof_symbols_per_data : NATURAL) RETURN STD_LOGIC_VECTOR;

  -- Multiplex the t_axi4_sosi_arr based on the valid, assuming that at most one input is active valid.
  FUNCTION func_axi4_sosi_arr_mux(axi4 : t_axi4_sosi_arr) RETURN t_axi4_sosi;

  -- Determine the combined logical value of corresponding STD_LOGIC fields in t_axi4_*_arr (for all elements or only for the mask[]='1' elements)
  FUNCTION func_axi4_stream_arr_and(axi4 : t_axi4_siso_arr; mask : STD_LOGIC_VECTOR; str : STRING) RETURN STD_LOGIC;
  FUNCTION func_axi4_stream_arr_and(axi4 : t_axi4_sosi_arr; mask : STD_LOGIC_VECTOR; str : STRING) RETURN STD_LOGIC;
  FUNCTION func_axi4_stream_arr_and(axi4 : t_axi4_siso_arr;                          str : STRING) RETURN STD_LOGIC;
  FUNCTION func_axi4_stream_arr_and(axi4 : t_axi4_sosi_arr;                          str : STRING) RETURN STD_LOGIC;
  FUNCTION func_axi4_stream_arr_or( axi4 : t_axi4_siso_arr; mask : STD_LOGIC_VECTOR; str : STRING) RETURN STD_LOGIC;
  FUNCTION func_axi4_stream_arr_or( axi4 : t_axi4_sosi_arr; mask : STD_LOGIC_VECTOR; str : STRING) RETURN STD_LOGIC;
  FUNCTION func_axi4_stream_arr_or( axi4 : t_axi4_siso_arr;                          str : STRING) RETURN STD_LOGIC;
  FUNCTION func_axi4_stream_arr_or( axi4 : t_axi4_sosi_arr;                          str : STRING) RETURN STD_LOGIC;

  -- Functions to set or get a STD_LOGIC field as a STD_LOGIC_VECTOR to or from an siso or an sosi array
  FUNCTION func_axi4_stream_arr_set(axi4 : t_axi4_siso_arr; slv : STD_LOGIC_VECTOR; str : STRING) RETURN t_axi4_siso_arr;
  FUNCTION func_axi4_stream_arr_set(axi4 : t_axi4_sosi_arr; slv : STD_LOGIC_VECTOR; str : STRING) RETURN t_axi4_sosi_arr;
  FUNCTION func_axi4_stream_arr_set(axi4 : t_axi4_siso_arr; sl  : STD_LOGIC;        str : STRING) RETURN t_axi4_siso_arr;
  FUNCTION func_axi4_stream_arr_set(axi4 : t_axi4_sosi_arr; sl  : STD_LOGIC;        str : STRING) RETURN t_axi4_sosi_arr;
  FUNCTION func_axi4_stream_arr_get(axi4 : t_axi4_siso_arr;                         str : STRING) RETURN STD_LOGIC_VECTOR;
  FUNCTION func_axi4_stream_arr_get(axi4 : t_axi4_sosi_arr;                         str : STRING) RETURN STD_LOGIC_VECTOR;

  -- Functions to select elements from two siso or two sosi arrays (sel[] = '1' selects a, sel[] = '0' selects b)
  FUNCTION func_axi4_stream_arr_select(sel : STD_LOGIC_VECTOR; a,                 b : t_axi4_siso)     RETURN t_axi4_siso_arr;
  FUNCTION func_axi4_stream_arr_select(sel : STD_LOGIC_VECTOR; a,                 b : t_axi4_sosi)     RETURN t_axi4_sosi_arr;
  FUNCTION func_axi4_stream_arr_select(sel : STD_LOGIC_VECTOR; a : t_axi4_siso_arr; b : t_axi4_siso)     RETURN t_axi4_siso_arr;
  FUNCTION func_axi4_stream_arr_select(sel : STD_LOGIC_VECTOR; a : t_axi4_sosi_arr; b : t_axi4_sosi)     RETURN t_axi4_sosi_arr;
  FUNCTION func_axi4_stream_arr_select(sel : STD_LOGIC_VECTOR; a : t_axi4_siso;     b : t_axi4_siso_arr) RETURN t_axi4_siso_arr;
  FUNCTION func_axi4_stream_arr_select(sel : STD_LOGIC_VECTOR; a : t_axi4_sosi;     b : t_axi4_sosi_arr) RETURN t_axi4_sosi_arr;
  FUNCTION func_axi4_stream_arr_select(sel : STD_LOGIC_VECTOR; a,                 b : t_axi4_siso_arr) RETURN t_axi4_siso_arr;
  FUNCTION func_axi4_stream_arr_select(sel : STD_LOGIC_VECTOR; a,                 b : t_axi4_sosi_arr) RETURN t_axi4_sosi_arr;

  -- Fix reversed buses due to connecting TO to DOWNTO range arrays.
  FUNCTION func_axi4_stream_arr_reverse_range(in_arr : t_axi4_sosi_arr) RETURN t_axi4_sosi_arr;
  FUNCTION func_axi4_stream_arr_reverse_range(in_arr : t_axi4_siso_arr) RETURN t_axi4_siso_arr;

  -- Functions to combinatorially hold the data fields and to set or reset the control fields in an sosi array
  FUNCTION func_axi4_stream_arr_set_control(  axi4 : t_axi4_sosi_arr; ctrl : t_axi4_sosi) RETURN t_axi4_sosi_arr;
  FUNCTION func_axi4_stream_arr_reset_control(axi4 : t_axi4_sosi_arr                  ) RETURN t_axi4_sosi_arr;

END axi4_stream_pkg;


PACKAGE BODY axi4_stream_pkg IS

  -- Check sosi.valid against siso.ready
  PROCEDURE proc_axi4_siso_alert(CONSTANT c_ready_latency : IN    NATURAL;
                               SIGNAL   clk             : IN    STD_LOGIC;
                               SIGNAL   sosi            : IN    t_axi4_sosi;
                               SIGNAL   siso            : IN    t_axi4_siso;
                               SIGNAL   ready_reg       : INOUT STD_LOGIC_VECTOR) IS
  BEGIN
    ready_reg(0) <= siso.tready;
    -- Register siso.ready in c_ready_latency registers
    IF rising_edge(clk) THEN
      -- Check DP sink
      IF sosi.tvalid = '1' AND ready_reg(c_ready_latency) = '0' THEN
        REPORT "RL ERROR" SEVERITY FAILURE;
      END IF;
      ready_reg( 1 TO c_ready_latency) <= ready_reg( 0 TO c_ready_latency-1);
    END IF;
  END proc_axi4_siso_alert;

  -- Default RL=1
  PROCEDURE proc_axi4_siso_alert(SIGNAL   clk             : IN    STD_LOGIC;
                               SIGNAL   sosi            : IN    t_axi4_sosi;
                               SIGNAL   siso            : IN    t_axi4_siso;
                               SIGNAL   ready_reg       : INOUT STD_LOGIC_VECTOR) IS
  BEGIN
    proc_axi4_siso_alert(1, clk, sosi, siso, ready_reg);
  END proc_axi4_siso_alert;

  -- SOSI/SISO array version
  PROCEDURE proc_axi4_siso_alert(CONSTANT c_ready_latency : IN    NATURAL;
                               SIGNAL   clk             : IN    STD_LOGIC;
                               SIGNAL   sosi_arr        : IN    t_axi4_sosi_arr;
                               SIGNAL   siso_arr        : IN    t_axi4_siso_arr;
                               SIGNAL   ready_reg       : INOUT STD_LOGIC_VECTOR) IS
  BEGIN
    FOR i IN 0 TO sosi_arr'LENGTH-1 LOOP
      ready_reg(i*(c_ready_latency+1)) <= siso_arr(i).tready; -- SLV is used as an array: nof_streams*(0..c_ready_latency)
    END LOOP;
    -- Register siso.ready in c_ready_latency registers
    IF rising_edge(clk) THEN
      FOR i IN 0 TO sosi_arr'LENGTH-1 LOOP
        -- Check DP sink
        IF sosi_arr(i).tvalid = '1' AND ready_reg(i*(c_ready_latency+1)+1) = '0' THEN
          REPORT "RL ERROR" SEVERITY FAILURE;
        END IF;
        ready_reg(i*(c_ready_latency+1)+1 TO i*(c_ready_latency+1)+c_ready_latency) <=  ready_reg(i*(c_ready_latency+1) TO i*(c_ready_latency+1)+c_ready_latency-1);
      END LOOP;
    END IF;
  END proc_axi4_siso_alert;

  -- SOSI/SISO array version with RL=1
  PROCEDURE proc_axi4_siso_alert(SIGNAL   clk             : IN    STD_LOGIC;
                               SIGNAL   sosi_arr        : IN    t_axi4_sosi_arr;
                               SIGNAL   siso_arr        : IN    t_axi4_siso_arr;
                               SIGNAL   ready_reg       : INOUT STD_LOGIC_VECTOR) IS
  BEGIN
    proc_axi4_siso_alert(1, clk, sosi_arr, siso_arr, ready_reg);
  END proc_axi4_siso_alert;

  -- Keep part of head data and combine part of tail data
  FUNCTION func_axi4_data_shift_first(head_sosi, tail_sosi : t_axi4_sosi; symbol_w, nof_symbols_per_data, nof_symbols_from_tail : NATURAL) RETURN t_axi4_sosi IS
    VARIABLE vN     : NATURAL := nof_symbols_per_data;
    VARIABLE v_sosi : t_axi4_sosi;
  BEGIN
    ASSERT nof_symbols_from_tail<vN REPORT "func_axi4_data_shift_first : no symbols from head" SEVERITY FAILURE;
    -- use the other sosi from head_sosi
    v_sosi := head_sosi;     -- I = nof_symbols_from_tail = 0
    FOR I IN 1 TO vN-1 LOOP  -- I > 0
      IF nof_symbols_from_tail = I THEN
        v_sosi.tdata(I*symbol_w-1 DOWNTO 0) := tail_sosi.tdata(vN*symbol_w-1 DOWNTO (vN-I)*symbol_w);
      END IF;
    END LOOP;
    RETURN v_sosi;
  END func_axi4_data_shift_first;


  -- Shift and combine part of previous data and this data,
  FUNCTION func_axi4_data_shift(prev_sosi, this_sosi : t_axi4_sosi; symbol_w, nof_symbols_per_data, nof_symbols_from_this : NATURAL) RETURN t_axi4_sosi IS
    VARIABLE vK     : NATURAL := nof_symbols_from_this;
    VARIABLE vN     : NATURAL := nof_symbols_per_data;
    VARIABLE v_sosi : t_axi4_sosi;
  BEGIN
    -- use the other sosi from this_sosi if nof_symbols_from_this > 0 else use other sosi from prev_sosi
    IF vK>0 THEN
      v_sosi := this_sosi;
    ELSE
      v_sosi := prev_sosi;
    END IF;

    -- use sosi data from both if 0 < nof_symbols_from_this < nof_symbols_per_data (i.e. 0 < I < vN)
    IF vK<nof_symbols_per_data THEN   -- I = vK = nof_symbols_from_this < vN
      -- Implementation using variable vK directly instead of via I in a LOOP
      -- IF vK > 0 THEN
      --   v_sosi.data(vN*symbol_w-1 DOWNTO vK*symbol_w)            := prev_sosi.data((vN-vK)*symbol_w-1 DOWNTO                0);
      --   v_sosi.data(                     vK*symbol_w-1 DOWNTO 0) := this_sosi.data( vN    *symbol_w-1 DOWNTO (vN-vK)*symbol_w);
      -- END IF;
      -- Implementaion using LOOP vK rather than VARIABLE vK directly as index to help synthesis and avoid potential multiplier
      v_sosi.tdata := prev_sosi.tdata;  -- I = vK = nof_symbols_from_this = 0
      FOR I IN 1 TO vN-1 LOOP         -- I = vK = nof_symbols_from_this > 0
        IF vK = I THEN
          v_sosi.tdata(vN*symbol_w-1 DOWNTO I*symbol_w)            := prev_sosi.tdata((vN-I)*symbol_w-1 DOWNTO               0);
          v_sosi.tdata(                     I*symbol_w-1 DOWNTO 0) := this_sosi.tdata( vN   *symbol_w-1 DOWNTO (vN-I)*symbol_w);
        END IF;
      END LOOP;
    END IF;
    RETURN v_sosi;
  END func_axi4_data_shift;


  -- Shift part of tail data and account for input empty
  FUNCTION func_axi4_data_shift_last(tail_sosi : t_axi4_sosi; symbol_w, nof_symbols_per_data, nof_symbols_from_tail, input_empty : NATURAL) RETURN t_axi4_sosi IS
    VARIABLE vK     : NATURAL := nof_symbols_from_tail;
    VARIABLE vL     : NATURAL := input_empty;
    VARIABLE vN     : NATURAL := nof_symbols_per_data;
    VARIABLE v_sosi : t_axi4_sosi;
  BEGIN
    ASSERT vK   > 0  REPORT "func_axi4_data_shift_last : no symbols from tail" SEVERITY FAILURE;
    ASSERT vK+vL<=vN REPORT "func_axi4_data_shift_last : impossible shift" SEVERITY FAILURE;
    v_sosi := tail_sosi;
    -- Implementation using variable vK directly instead of via I in a LOOP
    -- IF vK > 0 THEN
    --   v_sosi.data(vN*symbol_w-1 DOWNTO (vN-vK)*symbol_w) <= tail_sosi.data((vK+vL)*symbol_w-1 DOWNTO vL*symbol_w);
    -- END IF;
    -- Implementation using LOOP vK rather than VARIABLE vK directly as index to help synthesis and avoid potential multiplier
    -- Implementation using LOOP vL rather than VARIABLE vL directly as index to help synthesis and avoid potential multiplier
    FOR I IN 1 TO vN-1 LOOP
      IF vK = I THEN
        FOR J IN 0 TO vN-1 LOOP
          IF vL = J THEN
            v_sosi.tdata(vN*symbol_w-1 DOWNTO (vN-I)*symbol_w) := tail_sosi.tdata((I+J)*symbol_w-1 DOWNTO J*symbol_w);
          END IF;
        END LOOP;
      END IF;
    END LOOP;
    RETURN v_sosi;
  END func_axi4_data_shift_last;


  -- Determine resulting empty if two streams are concatenated
  -- . both empty must use the same nof symbols per data
  FUNCTION func_axi4_empty_concat(head_empty, tail_empty : STD_LOGIC_VECTOR; nof_symbols_per_data : NATURAL) RETURN STD_LOGIC_VECTOR IS
    VARIABLE v_a, v_b, v_empty : NATURAL;
  BEGIN
    v_a := TO_UINT(head_empty);
    v_b := TO_UINT(tail_empty);
    v_empty := v_a + v_b;
    IF v_empty >= nof_symbols_per_data THEN
      v_empty := v_empty - nof_symbols_per_data;
    END IF;
    RETURN TO_UVEC(v_empty, head_empty'LENGTH);
  END func_axi4_empty_concat;

  FUNCTION func_axi4_empty_split(input_empty, head_empty : STD_LOGIC_VECTOR; nof_symbols_per_data : NATURAL) RETURN STD_LOGIC_VECTOR IS
    VARIABLE v_a, v_b, v_empty : NATURAL;
  BEGIN
    v_a   := TO_UINT(input_empty);
    v_b   := TO_UINT(head_empty);
    IF v_a >= v_b THEN
      v_empty := v_a - v_b;
    ELSE
      v_empty := (nof_symbols_per_data + v_a) - v_b;
    END IF;
    RETURN TO_UVEC(v_empty, head_empty'LENGTH);
  END func_axi4_empty_split;


  -- Multiplex the t_axi4_sosi_arr based on the valid, assuming that at most one input is active valid.
  FUNCTION func_axi4_sosi_arr_mux(axi4 : t_axi4_sosi_arr) RETURN t_axi4_sosi IS
    VARIABLE v_sosi : t_axi4_sosi := c_axi4_sosi_rst;
  BEGIN
    FOR I IN axi4'RANGE LOOP
      IF axi4(I).tvalid='1' THEN
        v_sosi := axi4(I);
        EXIT;
      END IF;
    END LOOP;
    RETURN v_sosi;
  END func_axi4_sosi_arr_mux;


  -- Determine the combined logical value of corresponding STD_LOGIC fields in t_axi4_*_arr (for all elements or only for the mask[]='1' elements)
  FUNCTION func_axi4_stream_arr_and(axi4 : t_axi4_siso_arr; mask : STD_LOGIC_VECTOR; str : STRING) RETURN STD_LOGIC IS
    VARIABLE v_vec : STD_LOGIC_VECTOR(axi4'RANGE) := (OTHERS=>'1');  -- set default v_vec such that unmasked input have no influence on operation result
    VARIABLE v_any : STD_LOGIC := '0';
  BEGIN
    -- map siso field to v_vec
    FOR I IN axi4'RANGE LOOP
      IF mask(I)='1' THEN
        v_any := '1';
        IF    str="READY" THEN v_vec(I) := axi4(I).tready;
        ELSE  REPORT "Error in func_axi4_stream_arr_and for t_axi4_siso_arr";
        END IF;
      END IF;
    END LOOP;
    -- do operation on the selected record field
    IF v_any='1' THEN
      RETURN vector_and(v_vec);   -- return AND of the masked input fields
    ELSE
      RETURN '0';                 -- return '0' if no input was masked
    END IF;
  END func_axi4_stream_arr_and;

  FUNCTION func_axi4_stream_arr_and(axi4 : t_axi4_sosi_arr; mask : STD_LOGIC_VECTOR; str : STRING) RETURN STD_LOGIC IS
    VARIABLE v_vec : STD_LOGIC_VECTOR(axi4'RANGE) := (OTHERS=>'1');  -- set default v_vec such that unmasked input have no influence on operation result
    VARIABLE v_any : STD_LOGIC := '0';
  BEGIN
    -- map siso field to v_vec
    FOR I IN axi4'RANGE LOOP
      IF mask(I)='1' THEN
        v_any := '1';
        IF    str="VALID" THEN v_vec(I) := axi4(I).tvalid;
        ELSE  REPORT "Error in func_axi4_stream_arr_and for t_axi4_sosi_arr";
        END IF;
      END IF;
    END LOOP;
    -- do operation on the selected record field
    IF v_any='1' THEN
      RETURN vector_and(v_vec);   -- return AND of the masked input fields
    ELSE
      RETURN '0';                 -- return '0' if no input was masked
    END IF;
  END func_axi4_stream_arr_and;

  FUNCTION func_axi4_stream_arr_and(axi4 : t_axi4_siso_arr; str : STRING) RETURN STD_LOGIC IS
    CONSTANT c_mask : STD_LOGIC_VECTOR(axi4'RANGE) := (OTHERS=>'1');
  BEGIN
    RETURN func_axi4_stream_arr_and(axi4, c_mask, str);
  END func_axi4_stream_arr_and;

  FUNCTION func_axi4_stream_arr_and(axi4 : t_axi4_sosi_arr; str : STRING) RETURN STD_LOGIC IS
    CONSTANT c_mask : STD_LOGIC_VECTOR(axi4'RANGE) := (OTHERS=>'1');
  BEGIN
    RETURN func_axi4_stream_arr_and(axi4, c_mask, str);
  END func_axi4_stream_arr_and;

  FUNCTION func_axi4_stream_arr_or(axi4 : t_axi4_siso_arr; mask : STD_LOGIC_VECTOR; str : STRING) RETURN STD_LOGIC IS
    VARIABLE v_vec : STD_LOGIC_VECTOR(axi4'RANGE) := (OTHERS=>'0');  -- set default v_vec such that unmasked input have no influence on operation result
    VARIABLE v_any : STD_LOGIC := '0';
  BEGIN
    -- map siso field to v_vec
    FOR I IN axi4'RANGE LOOP
      IF mask(I)='1' THEN
        v_any := '1';
        IF    str="READY" THEN v_vec(I) := axi4(I).tready;
        ELSE  REPORT "Error in func_axi4_stream_arr_or for t_axi4_siso_arr";
        END IF;
      END IF;
    END LOOP;
    -- do operation on the selected record field
    IF v_any='1' THEN
      RETURN vector_or(v_vec);   -- return OR of the masked input fields
    ELSE
      RETURN '0';                -- return '0' if no input was masked
    END IF;
  END func_axi4_stream_arr_or;

  FUNCTION func_axi4_stream_arr_or(axi4 : t_axi4_sosi_arr; mask : STD_LOGIC_VECTOR; str : STRING) RETURN STD_LOGIC IS
    VARIABLE v_vec : STD_LOGIC_VECTOR(axi4'RANGE) := (OTHERS=>'0');  -- set default v_vec such that unmasked input have no influence on operation result
    VARIABLE v_any : STD_LOGIC := '0';
  BEGIN
    -- map siso field to v_vec
    FOR I IN axi4'RANGE LOOP
      IF mask(I)='1' THEN
        v_any := '1';
        IF    str="VALID" THEN v_vec(I) := axi4(I).tvalid;
        ELSE  REPORT "Error in func_axi4_stream_arr_or for t_axi4_sosi_arr";
        END IF;
      END IF;
    END LOOP;
    -- do operation on the selected record field
    IF v_any='1' THEN
      RETURN vector_or(v_vec);   -- return OR of the masked input fields
    ELSE
      RETURN '0';                -- return '0' if no input was masked
    END IF;
  END func_axi4_stream_arr_or;

  FUNCTION func_axi4_stream_arr_or(axi4 : t_axi4_siso_arr; str : STRING) RETURN STD_LOGIC IS
    CONSTANT c_mask : STD_LOGIC_VECTOR(axi4'RANGE) := (OTHERS=>'1');
  BEGIN
    RETURN func_axi4_stream_arr_or(axi4, c_mask, str);
  END func_axi4_stream_arr_or;

  FUNCTION func_axi4_stream_arr_or(axi4 : t_axi4_sosi_arr; str : STRING) RETURN STD_LOGIC IS
    CONSTANT c_mask : STD_LOGIC_VECTOR(axi4'RANGE) := (OTHERS=>'1');
  BEGIN
    RETURN func_axi4_stream_arr_or(axi4, c_mask, str);
  END func_axi4_stream_arr_or;


  -- Functions to set or get a STD_LOGIC field as a STD_LOGIC_VECTOR to or from an siso or an sosi array
  FUNCTION func_axi4_stream_arr_set(axi4 : t_axi4_siso_arr; slv : STD_LOGIC_VECTOR; str : STRING) RETURN t_axi4_siso_arr IS
    VARIABLE v_axi4  : t_axi4_siso_arr(axi4'RANGE)    := axi4;   -- default
    VARIABLE v_slv : STD_LOGIC_VECTOR(axi4'RANGE) := slv;  -- map to ensure same range as for axi4
  BEGIN
    FOR I IN axi4'RANGE LOOP
      IF    str="READY" THEN v_axi4(I).tready := v_slv(I);
      ELSE  REPORT "Error in func_axi4_stream_arr_set for t_axi4_siso_arr";
      END IF;
    END LOOP;
    RETURN v_axi4;
  END func_axi4_stream_arr_set;

  FUNCTION func_axi4_stream_arr_set(axi4 : t_axi4_sosi_arr; slv : STD_LOGIC_VECTOR; str : STRING) RETURN t_axi4_sosi_arr IS
    VARIABLE v_axi4  : t_axi4_sosi_arr(axi4'RANGE)    := axi4;   -- default
    VARIABLE v_slv : STD_LOGIC_VECTOR(axi4'RANGE) := slv;  -- map to ensure same range as for axi4
  BEGIN
    FOR I IN axi4'RANGE LOOP
      IF    str="VALID" THEN v_axi4(I).tvalid := v_slv(I);
      ELSE  REPORT "Error in func_axi4_stream_arr_set for t_axi4_sosi_arr";
      END IF;
    END LOOP;
    RETURN v_axi4;
  END func_axi4_stream_arr_set;

  FUNCTION func_axi4_stream_arr_set(axi4 : t_axi4_siso_arr; sl : STD_LOGIC; str : STRING) RETURN t_axi4_siso_arr IS
    VARIABLE v_slv : STD_LOGIC_VECTOR(axi4'RANGE) := (OTHERS=>sl);
  BEGIN
    RETURN func_axi4_stream_arr_set(axi4, v_slv, str);
  END func_axi4_stream_arr_set;

  FUNCTION func_axi4_stream_arr_set(axi4 : t_axi4_sosi_arr; sl : STD_LOGIC; str : STRING) RETURN t_axi4_sosi_arr IS
    VARIABLE v_slv : STD_LOGIC_VECTOR(axi4'RANGE) := (OTHERS=>sl);
  BEGIN
    RETURN func_axi4_stream_arr_set(axi4, v_slv, str);
  END func_axi4_stream_arr_set;

  FUNCTION func_axi4_stream_arr_get(axi4 : t_axi4_siso_arr; str : STRING) RETURN STD_LOGIC_VECTOR IS
    VARIABLE v_ctrl : STD_LOGIC_VECTOR(axi4'RANGE);
  BEGIN
    FOR I IN axi4'RANGE LOOP
      IF    str="READY" THEN v_ctrl(I) := axi4(I).tready;
      ELSE  REPORT "Error in func_axi4_stream_arr_get for t_axi4_siso_arr";
      END IF;
    END LOOP;
    RETURN v_ctrl;
  END func_axi4_stream_arr_get;

  FUNCTION func_axi4_stream_arr_get(axi4 : t_axi4_sosi_arr; str : STRING) RETURN STD_LOGIC_VECTOR IS
    VARIABLE v_ctrl : STD_LOGIC_VECTOR(axi4'RANGE);
  BEGIN
    FOR I IN axi4'RANGE LOOP
      IF    str="VALID" THEN v_ctrl(I) := axi4(I).tvalid;
      ELSE  REPORT "Error in func_axi4_stream_arr_get for t_axi4_sosi_arr";
      END IF;
    END LOOP;
    RETURN v_ctrl;
  END func_axi4_stream_arr_get;


  -- Functions to select elements from two siso or two sosi arrays (sel[] = '1' selects a, sel[] = '0' selects b)
  FUNCTION func_axi4_stream_arr_select(sel : STD_LOGIC_VECTOR; a, b : t_axi4_siso) RETURN t_axi4_siso_arr IS
    VARIABLE v_axi4 : t_axi4_siso_arr(sel'RANGE);
  BEGIN
    FOR I IN sel'RANGE LOOP
      IF sel(I)='1' THEN
        v_axi4(I) := a;
      ELSE
        v_axi4(I) := b;
      END IF;
    END LOOP;
    RETURN v_axi4;
  END func_axi4_stream_arr_select;

  FUNCTION func_axi4_stream_arr_select(sel : STD_LOGIC_VECTOR; a : t_axi4_siso_arr; b : t_axi4_siso) RETURN t_axi4_siso_arr IS
    VARIABLE v_axi4 : t_axi4_siso_arr(sel'RANGE);
  BEGIN
    FOR I IN sel'RANGE LOOP
      IF sel(I)='1' THEN
        v_axi4(I) := a(I);
      ELSE
        v_axi4(I) := b;
      END IF;
    END LOOP;
    RETURN v_axi4;
  END func_axi4_stream_arr_select;

  FUNCTION func_axi4_stream_arr_select(sel : STD_LOGIC_VECTOR; a : t_axi4_siso; b : t_axi4_siso_arr) RETURN t_axi4_siso_arr IS
    VARIABLE v_axi4 : t_axi4_siso_arr(sel'RANGE);
  BEGIN
    FOR I IN sel'RANGE LOOP
      IF sel(I)='1' THEN
        v_axi4(I) := a;
      ELSE
        v_axi4(I) := b(I);
      END IF;
    END LOOP;
    RETURN v_axi4;
  END func_axi4_stream_arr_select;

  FUNCTION func_axi4_stream_arr_select(sel : STD_LOGIC_VECTOR; a, b : t_axi4_siso_arr) RETURN t_axi4_siso_arr IS
    VARIABLE v_axi4 : t_axi4_siso_arr(sel'RANGE);
  BEGIN
    FOR I IN sel'RANGE LOOP
      IF sel(I)='1' THEN
        v_axi4(I) := a(I);
      ELSE
        v_axi4(I) := b(I);
      END IF;
    END LOOP;
    RETURN v_axi4;
  END func_axi4_stream_arr_select;

  FUNCTION func_axi4_stream_arr_select(sel : STD_LOGIC_VECTOR; a, b : t_axi4_sosi) RETURN t_axi4_sosi_arr IS
    VARIABLE v_axi4 : t_axi4_sosi_arr(sel'RANGE);
  BEGIN
    FOR I IN sel'RANGE LOOP
      IF sel(I)='1' THEN
        v_axi4(I) := a;
      ELSE
        v_axi4(I) := b;
      END IF;
    END LOOP;
    RETURN v_axi4;
  END func_axi4_stream_arr_select;

  FUNCTION func_axi4_stream_arr_select(sel : STD_LOGIC_VECTOR; a : t_axi4_sosi_arr; b : t_axi4_sosi) RETURN t_axi4_sosi_arr IS
    VARIABLE v_axi4 : t_axi4_sosi_arr(sel'RANGE);
  BEGIN
    FOR I IN sel'RANGE LOOP
      IF sel(I)='1' THEN
        v_axi4(I) := a(I);
      ELSE
        v_axi4(I) := b;
      END IF;
    END LOOP;
    RETURN v_axi4;
  END func_axi4_stream_arr_select;

  FUNCTION func_axi4_stream_arr_select(sel : STD_LOGIC_VECTOR; a : t_axi4_sosi; b : t_axi4_sosi_arr) RETURN t_axi4_sosi_arr IS
    VARIABLE v_axi4 : t_axi4_sosi_arr(sel'RANGE);
  BEGIN
    FOR I IN sel'RANGE LOOP
      IF sel(I)='1' THEN
        v_axi4(I) := a;
      ELSE
        v_axi4(I) := b(I);
      END IF;
    END LOOP;
    RETURN v_axi4;
  END func_axi4_stream_arr_select;

  FUNCTION func_axi4_stream_arr_select(sel : STD_LOGIC_VECTOR; a, b : t_axi4_sosi_arr) RETURN t_axi4_sosi_arr IS
    VARIABLE v_axi4 : t_axi4_sosi_arr(sel'RANGE);
  BEGIN
    FOR I IN sel'RANGE LOOP
      IF sel(I)='1' THEN
        v_axi4(I) := a(I);
      ELSE
        v_axi4(I) := b(I);
      END IF;
    END LOOP;
    RETURN v_axi4;
  END func_axi4_stream_arr_select;

  FUNCTION func_axi4_stream_arr_reverse_range(in_arr : t_axi4_siso_arr) RETURN t_axi4_siso_arr IS
    VARIABLE v_to_range : t_axi4_siso_arr(0 TO in_arr'HIGH);
    VARIABLE v_downto_range : t_axi4_siso_arr(in_arr'HIGH DOWNTO 0);
  BEGIN
    FOR i IN in_arr'RANGE LOOP
      v_to_range(i)     := in_arr(in_arr'HIGH-i);
      v_downto_range(i) := in_arr(in_arr'HIGH-i);
    END LOOP;
    IF in_arr'LEFT>in_arr'RIGHT THEN
      RETURN v_downto_range;
    ELSIF in_arr'LEFT<in_arr'RIGHT THEN
      RETURN v_to_range;
    ELSE
      RETURN in_arr;
    END IF;
  END func_axi4_stream_arr_reverse_range;

  FUNCTION func_axi4_stream_arr_reverse_range(in_arr : t_axi4_sosi_arr) RETURN t_axi4_sosi_arr IS
    VARIABLE v_to_range : t_axi4_sosi_arr(0 TO in_arr'HIGH);
    VARIABLE v_downto_range : t_axi4_sosi_arr(in_arr'HIGH DOWNTO 0);
  BEGIN
    FOR i IN in_arr'RANGE LOOP
      v_to_range(i)     := in_arr(in_arr'HIGH-i);
      v_downto_range(i) := in_arr(in_arr'HIGH-i);
    END LOOP;
    IF in_arr'LEFT>in_arr'RIGHT THEN
      RETURN v_downto_range;
    ELSIF in_arr'LEFT<in_arr'RIGHT THEN
      RETURN v_to_range;
    ELSE
      RETURN in_arr;
    END IF;
  END func_axi4_stream_arr_reverse_range;

  -- Functions to combinatorially hold the data fields and to set or reset the control fields in an sosi array
  FUNCTION func_axi4_stream_arr_set_control(axi4 : t_axi4_sosi_arr; ctrl : t_axi4_sosi) RETURN t_axi4_sosi_arr IS
    VARIABLE v_axi4 : t_axi4_sosi_arr(axi4'RANGE) := axi4;  -- hold sosi data
  BEGIN
    FOR I IN axi4'RANGE LOOP                          -- set sosi control
      v_axi4(I).tvalid := ctrl.tvalid;
      v_axi4(I).tuser := ctrl.tuser;
      v_axi4(I).tdest := ctrl.tdest;
    END LOOP;
    RETURN v_axi4;
  END func_axi4_stream_arr_set_control;

  FUNCTION func_axi4_stream_arr_reset_control(axi4 : t_axi4_sosi_arr) RETURN t_axi4_sosi_arr IS
    VARIABLE v_axi4 : t_axi4_sosi_arr(axi4'RANGE) := axi4;  -- hold sosi data
  BEGIN
    FOR I IN axi4'RANGE LOOP                          -- reset sosi control
      v_axi4(I).tvalid := '0';
    END LOOP;
    RETURN v_axi4;
  END func_axi4_stream_arr_reset_control;


END axi4_stream_pkg;

