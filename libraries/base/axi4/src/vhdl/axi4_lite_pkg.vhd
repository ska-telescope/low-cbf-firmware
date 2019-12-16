-------------------------------------------------------------------------------
--
-- Copyright (C) 2017
--
-- ASTRON (Netherlands Institute for Radio Astronomy) <http://www.astron.nl/>
-- P.O.Box 2, 7990 AA Dwingeloo, The Netherlands
--
-- CSIRO - Commonwealth Scientific and Industrial Research Organisation
--
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
LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE std.textio.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;

PACKAGE axi4_lite_pkg IS

  ------------------------------------------------------------------------------
  -- Simple AXI4 lite memory access (for MM control interface)
  ------------------------------------------------------------------------------


  CONSTANT c_axi4_lite_address_w  : NATURAL := 32;
  CONSTANT c_axi4_lite_data_w     : NATURAL := 32;
  CONSTANT c_axi4_lite_prot_w     : NATURAL := 3;
  CONSTANT c_axi4_lite_resp_w     : NATURAL := 2;


  TYPE t_axi4_lite_mosi IS RECORD  -- Master Out Slave In
    -- write address channel
    awaddr  : std_logic_vector(c_axi4_lite_address_w-1 downto 0);         -- write address
    awprot  : std_logic_vector(c_axi4_lite_prot_w-1 downto 0);            -- access permission for write
    awvalid : std_logic;                                                  -- write address valid
    -- write data channel
    wdata   : std_logic_vector(c_axi4_lite_data_w-1 downto 0);            -- write data
    wstrb   : std_logic_vector((c_axi4_lite_data_w/c_byte_w)-1 downto 0); -- write strobes
    wvalid  : std_logic;                                                  -- write valid
    -- write response channel
    bready  : std_logic;                                                  -- response ready
    -- read address channel
    araddr  : std_logic_vector(c_axi4_lite_address_w-1 downto 0);         -- read address
    arprot  : std_logic_vector(c_axi4_lite_prot_w-1 downto 0);            -- access permission for read
    arvalid : std_logic;                                                  -- read address valid
    -- read data channel
    rready  : std_logic;                                                  -- read ready
  END RECORD;

  TYPE t_axi4_lite_miso IS RECORD  -- Master In Slave Out
    -- write_address channel
    awready : std_logic;                                       -- write address ready
    -- write data channel
    wready  : std_logic;                                       -- write ready
    -- write response channel
    bresp   : std_logic_vector(c_axi4_lite_resp_w-1 downto 0); -- write response
    bvalid  : std_logic;                                       -- write response valid
    -- read address channel
    arready : std_logic;                                       -- read address ready
    -- read data channel
    rdata   : std_logic_vector(c_axi4_lite_data_w-1 downto 0); -- read data
    rresp   : std_logic_vector(c_axi4_lite_resp_w-1 downto 0); -- read response
    rvalid  : std_logic;                                       -- read valid
  END RECORD;


  CONSTANT c_axi4_lite_mosi_rst : t_axi4_lite_mosi := ((OTHERS=>'0'), (OTHERS=>'0'), '0', (OTHERS=>'0'), (OTHERS=>'0'), '0', '0', (OTHERS=>'0'), (OTHERS=>'0'), '0', '0');
  CONSTANT c_axi4_lite_miso_rst : t_axi4_lite_miso := ('0', '0', (OTHERS=>'0'), '0', '0', (OTHERS=>'0'), (OTHERS=>'0'), '0');

  -- Multi port array for MM records
  TYPE t_axi4_lite_miso_arr IS ARRAY (INTEGER RANGE <>) OF t_axi4_lite_miso;
  TYPE t_axi4_lite_mosi_arr IS ARRAY (INTEGER RANGE <>) OF t_axi4_lite_mosi;

  CONSTANT c_axi4_lite_resp_okay   : STD_LOGIC_VECTOR(c_axi4_lite_resp_w-1 DOWNTO 0) := "00"; -- normal access success
  CONSTANT c_axi4_lite_resp_exokay : STD_LOGIC_VECTOR(c_axi4_lite_resp_w-1 DOWNTO 0) := "01"; -- exclusive access okay
  CONSTANT c_axi4_lite_resp_slverr : STD_LOGIC_VECTOR(c_axi4_lite_resp_w-1 DOWNTO 0) := "10"; -- slave error
  CONSTANT c_axi4_lite_resp_decerr : STD_LOGIC_VECTOR(c_axi4_lite_resp_w-1 DOWNTO 0) := "11"; -- decode error


  -- Resize functions to fit an integer or an SLV in the corresponding t_axi4_lite_miso or t_axi4_lite_mosi field width
  FUNCTION TO_AXI4_LITE_ADDRESS(n : INTEGER) RETURN STD_LOGIC_VECTOR;  -- unsigned, use integer to support 32 bit range
  FUNCTION TO_AXI4_LITE_DATA(   n : INTEGER) RETURN STD_LOGIC_VECTOR;  -- unsigned, alias of TO_AXI4_LITE_DATA()
  FUNCTION TO_AXI4_LITE_UDATA(  n : INTEGER) RETURN STD_LOGIC_VECTOR;  -- unsigned, use integer to support 32 bit range
  FUNCTION TO_AXI4_LITE_SDATA(  n : INTEGER) RETURN STD_LOGIC_VECTOR;  -- sign extended
  FUNCTION RESIZE_AXI4_LITE_ADDRESS(vec : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR;  -- unsigned
  FUNCTION RESIZE_AXI4_LITE_DATA(   vec : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR;  -- unsigned, alias of RESIZE_AXI4_LITE_UDATA
  FUNCTION RESIZE_AXI4_LITE_UDATA(  vec : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR;  -- unsigned
  FUNCTION RESIZE_AXI4_LITE_SDATA(  vec : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR;  -- sign extended
  FUNCTION RESIZE_AXI4_LITE_XDATA(  vec : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR;  -- set unused MSBits to 'X'


  CONSTANT c_axi4_lite_reg_rd_latency : NATURAL := 0;
  CONSTANT c_axi4_lite_reg            : t_c_mem := (latency    => c_axi4_lite_reg_rd_latency,
                                                    adr_w      => 1,
                                                    dat_w      => 32,
                                                    addr_base  => 0,
                                                    nof_dat    => 1,
                                                    nof_slaves => 1,
                                                    init_sl    => 'X');

   CONSTANT c_axi4_lite_reg_init_w     : NATURAL := 1*256*32;  -- >= largest expected value of dat_w*nof_dat (256 * 32 bit = 1k byte)

   CONSTANT c_mask_ones                : t_slv_32_arr(0 TO 0)  := (OTHERS => (OTHERS => '1'));
   CONSTANT c_mask_zeros               : t_slv_32_arr(0 TO 0)  := (OTHERS => (OTHERS => '0'));

   PROCEDURE axi_lite_blockwrite (SIGNAL mm_clk   : IN STD_LOGIC;
                                  SIGNAL axi_miso : IN t_axi4_lite_miso;
                                  SIGNAL axi_mosi : OUT t_axi4_lite_mosi;
                                  register_addr   : NATURAL;
                                  dataFileName    : STRING;
                                  name            : STRING := pad("");
                                  expected_fail   : BOOLEAN := false;
                                  fail_on_error   : BOOLEAN := false);

   -- Multiple variants of the same function
   PROCEDURE axi_lite_transaction (SIGNAL mm_clk : IN STD_LOGIC; SIGNAL axi_miso : IN t_axi4_lite_miso; SIGNAL axi_mosi : OUT t_axi4_lite_mosi; register_addr : NATURAL; write_reg : BOOLEAN; data : t_slv_32_arr; validate : boolean := false; mask : t_slv_32_arr := c_mask_zeros; expected_fail : BOOLEAN := false; fail_on_error : BOOLEAN := false);

   PROCEDURE axi_lite_transaction (SIGNAL mm_clk : IN STD_LOGIC; SIGNAL axi_miso : IN t_axi4_lite_miso; SIGNAL axi_mosi : OUT t_axi4_lite_mosi; register_addr : t_register_address; write_reg : BOOLEAN; data : t_slv_32_arr; validate : boolean := false; mask : t_slv_32_arr := c_mask_zeros; expected_fail : BOOLEAN := false; fail_on_error : BOOLEAN := false);
   PROCEDURE axi_lite_transaction (SIGNAL mm_clk : IN STD_LOGIC; SIGNAL axi_miso : IN t_axi4_lite_miso; SIGNAL axi_mosi : OUT t_axi4_lite_mosi; register_addr : t_register_address; write_reg : BOOLEAN; data : STD_LOGIC_VECTOR(c_axi4_lite_data_w-1 DOWNTO 0); validate : boolean := false; mask : STD_LOGIC_VECTOR(c_axi4_lite_data_w-1 DOWNTO 0) := (OTHERS => '0'); expected_fail : BOOLEAN := false; fail_on_error : BOOLEAN := false);

   -- Base function
   PROCEDURE axi_lite_transaction (SIGNAL mm_clk   : IN STD_LOGIC;
                                   SIGNAL axi_miso : IN t_axi4_lite_miso;
                                   SIGNAL axi_mosi : OUT t_axi4_lite_mosi;
                                   register_addr   : NATURAL;
                                   write_reg       : BOOLEAN;
                                   data            : STD_LOGIC_VECTOR(c_axi4_lite_data_w-1 DOWNTO 0);
                                   validate        : boolean := false;
                                   mask            : STD_LOGIC_VECTOR(c_axi4_lite_data_w-1 DOWNTO 0) := (OTHERS => '0');
                                   offset          : NATURAL := 0;
                                   width           : NATURAL := 32;
                                   name            : STRING  := pad("");
                                   expected_fail   : BOOLEAN := false;
                                   fail_on_error   : BOOLEAN := false);

   PROCEDURE axi_lite_init (SIGNAL mm_rst : IN STD_LOGIC; SIGNAL mm_clk : IN STD_LOGIC; SIGNAL axi_miso : IN t_axi4_lite_miso; SIGNAL axi_mosi : OUT t_axi4_lite_mosi);
   PROCEDURE axi_lite_wait (SIGNAL mm_clk : IN STD_LOGIC; SIGNAL axi_miso : IN t_axi4_lite_miso; SIGNAL axi_mosi : OUT t_axi4_lite_mosi; register_addr : t_register_address; data : STD_LOGIC_VECTOR(c_axi4_lite_data_w-1 DOWNTO 0); fail_on_error   : BOOLEAN := TRUE);


END axi4_lite_pkg;

PACKAGE BODY axi4_lite_pkg IS

  -- Resize functions to fit an integer or an SLV in the corresponding t_axi4_lite_miso or t_axi4_lite_mosi field width
  FUNCTION TO_AXI4_LITE_ADDRESS(n : INTEGER) RETURN STD_LOGIC_VECTOR IS
  BEGIN
    RETURN RESIZE_UVEC(TO_SVEC(n, 32), c_axi4_lite_address_w);
  END TO_AXI4_LITE_ADDRESS;

  FUNCTION TO_AXI4_LITE_DATA(n : INTEGER) RETURN STD_LOGIC_VECTOR IS
  BEGIN
    RETURN TO_AXI4_LITE_UDATA(n);
  END TO_AXI4_LITE_DATA;

  FUNCTION TO_AXI4_LITE_UDATA(n : INTEGER) RETURN STD_LOGIC_VECTOR IS
  BEGIN
    RETURN RESIZE_UVEC(TO_SVEC(n, 32), c_axi4_lite_data_w);
  END TO_AXI4_LITE_UDATA;

  FUNCTION TO_AXI4_LITE_SDATA(n : INTEGER) RETURN STD_LOGIC_VECTOR IS
  BEGIN
    RETURN RESIZE_SVEC(TO_SVEC(n, 32), c_axi4_lite_data_w);
  END TO_AXI4_LITE_SDATA;

  FUNCTION RESIZE_AXI4_LITE_ADDRESS(vec : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
  BEGIN
    RETURN RESIZE_UVEC(vec, c_axi4_lite_address_w);
  END RESIZE_AXI4_LITE_ADDRESS;

  FUNCTION RESIZE_AXI4_LITE_DATA(vec : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
  BEGIN
    RETURN RESIZE_AXI4_LITE_UDATA(vec);
  END RESIZE_AXI4_LITE_DATA;

  FUNCTION RESIZE_AXI4_LITE_UDATA(vec : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
  BEGIN
    RETURN RESIZE_UVEC(vec, c_axi4_lite_data_w);
  END RESIZE_AXI4_LITE_UDATA;

  FUNCTION RESIZE_AXI4_LITE_SDATA(vec : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
  BEGIN
    RETURN RESIZE_SVEC(vec, c_axi4_lite_data_w);
  END RESIZE_AXI4_LITE_SDATA;

   FUNCTION RESIZE_AXI4_LITE_XDATA(vec : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
      VARIABLE v_vec : STD_LOGIC_VECTOR(c_axi4_lite_data_w-1 DOWNTO 0) := (OTHERS=>'X');
   BEGIN
      v_vec(vec'LENGTH-1 DOWNTO 0) := vec;
      RETURN v_vec;
   END RESIZE_AXI4_LITE_XDATA;


   ------------------------------------------------------------------------------
   ------------------------------------------------------------------------------
   PROCEDURE axi_lite_init (SIGNAL mm_rst   : IN STD_LOGIC;
                            SIGNAL mm_clk   : IN STD_LOGIC;
                            SIGNAL axi_miso : IN t_axi4_lite_miso;
                            SIGNAL axi_mosi : OUT t_axi4_lite_mosi) is

   BEGIN

      axi_mosi <= c_axi4_lite_mosi_rst;

      -- wait for reset to be released
      WAIT UNTIL to_x01(mm_rst) = '0';
      WAIT UNTIL rising_edge(mm_clk);
      WAIT UNTIL rising_edge(mm_clk);

   END PROCEDURE;



   ------------------------------------------------------------------------------
   ------------------------------------------------------------------------------
   PROCEDURE axi_lite_transaction (SIGNAL mm_clk   : IN STD_LOGIC;
                                   SIGNAL axi_miso : IN t_axi4_lite_miso;
                                   SIGNAL axi_mosi : OUT t_axi4_lite_mosi;
                                   register_addr   : NATURAL;
                                   write_reg       : BOOLEAN;
                                   data            : t_slv_32_arr;
                                   validate        : BOOLEAN := false;
                                   mask            : t_slv_32_arr := c_mask_zeros;
                                   expected_fail   : BOOLEAN := false;
                                   fail_on_error   : BOOLEAN := false) is

         VARIABLE mask_unit         : STD_LOGIC_VECTOR(31 DOWNTO 0);
   BEGIN
      data_write_loop: FOR i IN data'RANGE LOOP

         IF mask'LENGTH = data'LENGTH THEN
            mask_unit := mask(i);
         ELSE
            mask_unit := mask(0);
         END IF;

         axi_lite_transaction(mm_clk, axi_miso, axi_mosi, register_addr+i, write_reg, data(i), validate, mask_unit, 0, 32,  pad(""), expected_fail, fail_on_error);
      END LOOP;
   END PROCEDURE;

   ------------------------------------------------------------------------------
   ------------------------------------------------------------------------------
   PROCEDURE axi_lite_transaction (SIGNAL mm_clk   : IN STD_LOGIC;
                                   SIGNAL axi_miso : IN t_axi4_lite_miso;
                                   SIGNAL axi_mosi : OUT t_axi4_lite_mosi;
                                   register_addr   : t_register_address;
                                   write_reg       : BOOLEAN;
                                   data            : t_slv_32_arr;
                                   validate        : BOOLEAN := false;
                                   mask            : t_slv_32_arr := c_mask_zeros;
                                   expected_fail   : BOOLEAN := false;
                                   fail_on_error   : BOOLEAN := false) is

         VARIABLE mask_unit         : STD_LOGIC_VECTOR(31 DOWNTO 0);
   BEGIN
      data_write_loop: FOR i IN data'RANGE LOOP

         IF mask'LENGTH = data'LENGTH THEN
            mask_unit := mask(i);
         ELSE
            mask_unit := mask(0);
         END IF;

         axi_lite_transaction(mm_clk, axi_miso, axi_mosi, register_addr.base_address+register_addr.address+i, write_reg, data(i), validate, mask_unit, register_addr.offset, register_addr.width, register_addr.name, expected_fail, fail_on_error);
      END LOOP;
   END PROCEDURE;

   ------------------------------------------------------------------------------
   ------------------------------------------------------------------------------
   PROCEDURE axi_lite_transaction (SIGNAL mm_clk   : IN STD_LOGIC;
                                   SIGNAL axi_miso : IN t_axi4_lite_miso;
                                   SIGNAL axi_mosi : OUT t_axi4_lite_mosi;
                                   register_addr   : t_register_address;
                                   write_reg       : BOOLEAN;
                                   data            : STD_LOGIC_VECTOR(c_axi4_lite_data_w-1 DOWNTO 0);
                                   validate        : BOOLEAN := false;
                                   mask            : STD_LOGIC_VECTOR(c_axi4_lite_data_w-1 DOWNTO 0) := (OTHERS => '0');
                                   expected_fail   : BOOLEAN := false;
                                   fail_on_error   : BOOLEAN := false) is

   BEGIN
      axi_lite_transaction(mm_clk, axi_miso, axi_mosi, register_addr.base_address+register_addr.address, write_reg, data, validate, mask, register_addr.offset, register_addr.width, register_addr.name, expected_fail, fail_on_error);
   END PROCEDURE;




   ------------------------------------------------------------------------------
   ------------------------------------------------------------------------------
   PROCEDURE axi_lite_transaction (SIGNAL mm_clk   : IN STD_LOGIC;
                                   SIGNAL axi_miso : IN t_axi4_lite_miso;
                                   SIGNAL axi_mosi : OUT t_axi4_lite_mosi;
                                   register_addr   : NATURAL;
                                   write_reg       : BOOLEAN;
                                   data            : STD_LOGIC_VECTOR(c_axi4_lite_data_w-1 DOWNTO 0);
                                   validate        : BOOLEAN := false;
                                   mask            : STD_LOGIC_VECTOR(c_axi4_lite_data_w-1 DOWNTO 0) := (OTHERS => '0');
                                   offset          : NATURAL := 0;
                                   width           : NATURAL := 32;
                                   name            : STRING := pad("");
                                   expected_fail   : BOOLEAN := false;
                                   fail_on_error   : BOOLEAN := false) is

         VARIABLE stdio             : line;
         VARIABLE result            : STD_LOGIC_VECTOR(31 DOWNTO 0);
   BEGIN

      -- Start transaction
      WAIT UNTIL rising_edge(mm_clk);

      IF write_reg = false THEN
         -- Setup read address
         axi_mosi.arvalid <= '1';
         axi_mosi.araddr <= std_logic_vector(to_unsigned(register_addr*4, 32));
         axi_mosi.rready <= '1';

         read_address_wait: LOOP
            WAIT UNTIL rising_edge(mm_clk);
            IF axi_miso.arready = '1' THEN
               axi_mosi.arvalid <= '0';
               axi_mosi.araddr <= (OTHERS => '0');
            END IF;

            IF axi_miso.rvalid = '1' THEN
               EXIT;
            END IF;
         END LOOP;


         write(stdio, string'("INFO: AXI Lite read of register "));
         IF name(1) /= ' ' THEN
            write(stdio, strip(name));
         ELSE
            write(stdio, (register_addr));
         END IF;
         write(stdio, string'(" returned "));

         -- Read response
         IF axi_miso.rresp = "00" THEN
            write(stdio, string'("OK "));
         ELSIF axi_miso.rresp = "01" THEN
            write(stdio, string'("exclusive access error "));
         ELSIF axi_miso.rresp = "10" THEN
            write(stdio, string'("slave error "));
         ELSIF axi_miso.rresp = "11" THEN
            write(stdio, string'("address decode error "));
         END IF;

         write(stdio, string'("with data 0x"));
         hwrite(stdio, axi_miso.rdata(offset+width-1 DOWNTO offset));
         writeline(output, stdio);

         IF validate = TRUE THEN
            IF (axi_miso.rdata(offset+width-1 DOWNTO offset) AND mask(width-1 DOWNTO 0)) /= (data(width-1 DOWNTO 0) AND mask(width-1 DOWNTO 0) ) THEN
               IF expected_fail THEN
                  write(stdio, string'("INFO (Expected Error)"));
               ELSE
                  write(stdio, string'("ERROR"));
               END IF;
               write(stdio, string'(": Return data doesn't match mask"));
               writeline(output, stdio);
               ASSERT NOT(fail_on_error) REPORT "Return data doesn't match mask" SEVERITY ERROR;
            END IF;
         END IF;

         WAIT UNTIL rising_edge(mm_clk);
         axi_mosi.rready <= '0';
      ELSE

         -- Needs to actually do a read first to perform a RMW on the shared fields
         axi_mosi.arvalid <= '1';
         axi_mosi.araddr <= std_logic_vector(to_unsigned(register_addr*4, 32));
         axi_mosi.rready <= '1';

         rmw_address_wait: LOOP
            WAIT UNTIL rising_edge(mm_clk);
            IF axi_miso.arready = '1' THEN
               axi_mosi.arvalid <= '0';
               axi_mosi.araddr <= (OTHERS => '0');
               EXIT;
            END IF;
         END LOOP;

         rmw_response_wait: WHILE axi_miso.rvalid = '0' LOOP
            WAIT UNTIL rising_edge(mm_clk);
         END LOOP;

         result := axi_miso.rdata;

         IF axi_miso.rresp /= "00" THEN
            IF expected_fail THEN
               write(stdio, string'("INFO (Expected Error)"));
            ELSE
               write(stdio, string'("ERROR"));
            END IF;
            write(stdio, string'(": Failure to read during write of register "));
            IF name(1) /= ' ' THEN
               write(stdio, strip(name));
            ELSE
               write(stdio, (register_addr));
            END IF;
            write(stdio, string'(" got "));
            write(stdio, to_integer(unsigned(axi_miso.rresp)));
            writeline(output, stdio);
            ASSERT NOT(fail_on_error and not expected_fail) REPORT "Failure to read during write of register" SEVERITY ERROR;
         END IF;

         WAIT UNTIL rising_edge(mm_clk);
         axi_mosi.rready <= '0';

         -- Setup write address, data, & reponse ready
         axi_mosi.awvalid <= '1';
         axi_mosi.awaddr <= std_logic_vector(to_unsigned(register_addr*4, 32));
         axi_mosi.bready <= '1';
         axi_mosi.wvalid <= '1';

         FOR i IN 0 TO 31 LOOP
            IF (i >= offset) and (i < (offset+width)) THEN
               axi_mosi.wdata(i) <= (result(i) AND mask(i-offset)) OR data(i-offset);
            ELSE
               axi_mosi.wdata(i) <= result(i);
            END IF;
         END LOOP;

         axi_mosi.wstrb <= X"f";

         write_address_wait: LOOP
            WAIT UNTIL rising_edge(mm_clk);

            IF axi_miso.wready = '1' THEN
               axi_mosi.wvalid <= '0';
            END IF;

            IF axi_miso.awready = '1' THEN
               axi_mosi.awvalid <= '0';
               axi_mosi.awaddr <= (OTHERS => '0');
            END IF;

            IF axi_miso.awready = '1' AND axi_miso.wready  = '1' THEN
               EXIT;
            END IF;
         END LOOP;

         response_wait: WHILE axi_miso.bvalid = '0' LOOP
            WAIT UNTIL rising_edge(mm_clk);
         END LOOP;

         IF axi_miso.bresp = "00" THEN
            write(stdio, string'("INFO"));
         ELSE
            IF expected_fail THEN
               write(stdio, string'("INFO (Expected Error)"));
            ELSE
               write(stdio, string'("ERROR"));
            END IF;
         END IF;

         write(stdio, string'(": AXI Lite write of register "));
         IF name(1) /= ' ' THEN
            write(stdio, strip(name));
         ELSE
            write(stdio, (register_addr));
         END IF;
         write(stdio, string'(" returned "));

         -- Print response
         IF axi_miso.bresp = "00" THEN
            write(stdio, string'("OK"));
         ELSIF axi_miso.bresp = "01" THEN
            write(stdio, string'("exclusive access error "));
            ASSERT NOT(fail_on_error and not expected_fail) REPORT "AXI LIte error code exclusive access error" SEVERITY ERROR;
         ELSIF axi_miso.bresp = "10" THEN
            write(stdio, string'("slave error "));
            ASSERT NOT(fail_on_error and not expected_fail) REPORT "AXI LIte error code slave error" SEVERITY ERROR;
         ELSIF axi_miso.bresp = "11" THEN
            write(stdio, string'("address decode error "));
            ASSERT NOT(fail_on_error and not expected_fail) REPORT "AXI LIte error code address decode error" SEVERITY ERROR;
         END IF;

         writeline(output, stdio);

         WAIT UNTIL rising_edge(mm_clk);
         axi_mosi.bready <= '0';
      END IF;

   END PROCEDURE;

   ------------------------------------------------------------------------------
   ------------------------------------------------------------------------------
   -- Write a block of values from a file starting at a given address.
   PROCEDURE axi_lite_blockwrite (SIGNAL mm_clk   : IN STD_LOGIC;
                                  SIGNAL axi_miso : IN t_axi4_lite_miso;
                                  SIGNAL axi_mosi : OUT t_axi4_lite_mosi;
                                  register_addr   : NATURAL;
                                  dataFileName    : STRING;
                                  name            : STRING := pad("");
                                  expected_fail   : BOOLEAN := false;
                                  fail_on_error   : BOOLEAN := false) is

      VARIABLE stdio   : line;
      VARIABLE result  : STD_LOGIC_VECTOR(31 DOWNTO 0);
      variable wrData : std_logic_vector(31 downto 0);
      variable wrCount : natural := 0; -- which word we are up to
      file dataFile : TEXT;
      variable lineIn : line;
      variable good : boolean;
      
   BEGIN
      
      FILE_OPEN(dataFile,dataFileName,READ_MODE);
      
      while (not endfile(dataFile)) loop 
         
         -- Get the data to write
         readline(dataFile, lineIn);
         
         while (not endfile(dataFile)) and ((lineIn'length = 0) or (lineIn(lineIn'left) = '#')) loop
            readline(dataFile, lineIn);  -- skip empty lines or lines starting with a comment character ('#')
         end loop;
         if endfile(dataFile) and ((lineIn'length = 0) or (lineIn(lineIn'left) = '#')) then
            exit;
         end if;
         hread(lineIn,wrData,good);
         assert good
            report "text IO Read error" severity ERROR;
         
         -- Start transaction
         WAIT UNTIL rising_edge(mm_clk);
         axi_mosi.rready <= '0';
    
         -- Setup write address, data, & response ready
         axi_mosi.awvalid <= '1';
         axi_mosi.awaddr <= std_logic_vector(to_unsigned((register_addr + wrCount)*4, 32));
         axi_mosi.bready <= '1';
         axi_mosi.wvalid <= '1';
         axi_mosi.wdata <= wrData;
         axi_mosi.wstrb <= X"f";
   
         write_address_wait: LOOP
            WAIT UNTIL rising_edge(mm_clk);
   
            IF axi_miso.wready = '1' THEN
               axi_mosi.wvalid <= '0';
            END IF;
   
            IF axi_miso.awready = '1' THEN
               axi_mosi.awvalid <= '0';
               axi_mosi.awaddr <= (OTHERS => '0');
            END IF;
   
            IF axi_miso.awready = '1' AND axi_miso.wready  = '1' THEN
               EXIT;
            END IF;
         END LOOP;
   
         response_wait: WHILE axi_miso.bvalid = '0' LOOP
            WAIT UNTIL rising_edge(mm_clk);
         END LOOP;
   
         IF axi_miso.bresp /= "00" THEN

            IF expected_fail THEN
               write(stdio, string'("INFO (Expected Error)"));
            ELSE
               write(stdio, string'("ERROR"));
            END IF;
   
            write(stdio, string'(": AXI Lite write of register "));
            IF name(1) /= ' ' THEN
               write(stdio, strip(name));
            ELSE
               write(stdio, (register_addr));
            END IF;
            write(stdio, string'(" returned "));
       
            -- Print response
            IF axi_miso.bresp = "00" THEN
               write(stdio, string'("OK"));
            ELSIF axi_miso.bresp = "01" THEN
               write(stdio, string'("exclusive access error "));
               ASSERT NOT(fail_on_error and not expected_fail) REPORT "AXI LIte error code exclusive access error" SEVERITY ERROR;
            ELSIF axi_miso.bresp = "10" THEN
               write(stdio, string'("slave error "));
               ASSERT NOT(fail_on_error and not expected_fail) REPORT "AXI LIte error code slave error" SEVERITY ERROR;
            ELSIF axi_miso.bresp = "11" THEN
               write(stdio, string'("address decode error "));
               ASSERT NOT(fail_on_error and not expected_fail) REPORT "AXI LIte error code address decode error" SEVERITY ERROR;
            END IF;
       
            writeline(output, stdio);
             
         end if;
   
         WAIT UNTIL rising_edge(mm_clk);
         axi_mosi.bready <= '0';
         
         wrCount := wrCount + 1;
         
      end loop;
   
   END PROCEDURE;   

   ------------------------------------------------------------------------------
   ------------------------------------------------------------------------------
   PROCEDURE axi_lite_wait (SIGNAL mm_clk   : IN STD_LOGIC;
                            SIGNAL axi_miso : IN t_axi4_lite_miso;
                            SIGNAL axi_mosi : OUT t_axi4_lite_mosi;
                            register_addr   : t_register_address;
                            data            : STD_LOGIC_VECTOR(c_axi4_lite_data_w-1 DOWNTO 0);
                            fail_on_error   : BOOLEAN := TRUE) is

      VARIABLE response    : STD_LOGIC_VECTOR(1 DOWNTO 0);
      VARIABLE stdio       : LINE;
      VARIABLE timeout     : INTEGER := 100000;           -- 100K iteration limit, about 50M clocks
   BEGIN

      wait_loop: LOOP
         -- Start transaction
         WAIT UNTIL rising_edge(mm_clk);


         -- Setup read address
         axi_mosi.arvalid <= '1';
         axi_mosi.araddr <= std_logic_vector(to_unsigned((register_addr.base_address+register_addr.address)*4, 32));
         axi_mosi.rready <= '1';

         read_address_wait: LOOP
            WAIT UNTIL rising_edge(mm_clk);
            IF axi_miso.arready = '1' THEN
               axi_mosi.arvalid <= '0';
               axi_mosi.araddr <= (OTHERS => '0');
            END IF;

            IF axi_miso.rvalid = '1' THEN
               EXIT;
            END IF;
         END LOOP;

         response := axi_miso.rresp;

         IF (axi_miso.rdata(register_addr.offset+register_addr.width-1 DOWNTO register_addr.offset) = data(register_addr.width-1 DOWNTO 0)) OR response /= "00" THEN
            EXIT;
         END IF;

         WAIT UNTIL rising_edge(mm_clk);
         axi_mosi.rready <= '0';

         delay_loop: FOR i IN 0 TO 500 LOOP
            WAIT UNTIL rising_edge(mm_clk);
         END LOOP;
         timeout := timeout - 1;
         IF timeout = 0 THEN
            EXIT;
         END IF;
      END LOOP;

      IF timeout = 0 THEN
         write(stdio, string'("ERROR: AXI Lite wait on register "));
         write(stdio, strip(register_addr.name));
         write(stdio, string'("failed"));
         ASSERT not fail_on_error REPORT "AXI LIte wait timed out" SEVERITY ERROR;
      ELSE

         write(stdio, string'("INFO: AXI Lite wait on register "));
         write(stdio, strip(register_addr.name));

         write(stdio, string'(" completed with response "));

         IF response = "00" THEN
            write(stdio, string'("OK "));
         ELSIF response = "01" THEN
            write(stdio, string'("exclusive access error "));
         ELSIF response = "10" THEN
            write(stdio, string'("slave error "));
         ELSIF response = "11" THEN
            write(stdio, string'("address decode error "));
         END IF;
      END IF;


      writeline(output, stdio);
   END PROCEDURE;


END axi4_lite_pkg;
