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
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;

PACKAGE axi4_full_pkg IS

  ------------------------------------------------------------------------------
  -- Full AXI4 memory access (for MM control interface)
  ------------------------------------------------------------------------------

  CONSTANT c_axi4_full_address_w    : NATURAL := 33;
  CONSTANT c_axi4_full_data_w       : NATURAL := 512;
  CONSTANT c_axi4_full_prot_w       : NATURAL := 3;
  CONSTANT c_axi4_full_resp_w       : NATURAL := 2;
  CONSTANT c_axi4_full_alen_w       : NATURAL := 8;
  CONSTANT c_axi4_full_asize_w      : NATURAL := 3;
  CONSTANT c_axi4_full_aburst_w     : NATURAL := 2;
  CONSTANT c_axi4_full_acache_w     : NATURAL := 4;
  CONSTANT c_axi4_full_auser_w      : NATURAL := 4;
  CONSTANT c_axi4_full_id_w         : NATURAL := 8;
  CONSTANT c_axi4_full_aregion_w    : NATURAL := 4;
  CONSTANT c_axi4_full_aqos_w       : NATURAL := 4;

  TYPE t_axi4_full_mosi IS RECORD  -- Master Out Slave In
    -- write address channel
    awid    : std_logic_vector(c_axi4_full_id_w-1 downto 0);             -- write id
    awaddr  : std_logic_vector(c_axi4_full_address_w-1 downto 0);         -- write address
    awprot  : std_logic_vector(c_axi4_full_prot_w-1 downto 0);            -- access permission for write
    awvalid : std_logic;                                                  -- write address valid
    awlen : std_logic_vector(c_axi4_full_alen_w-1 DOWNTO 0);
    awsize : std_logic_vector(c_axi4_full_asize_w-1 DOWNTO 0);
    awburst : std_logic_vector(c_axi4_full_aburst_w-1 DOWNTO 0);
    awcache : std_logic_vector(c_axi4_full_acache_w-1 DOWNTO 0);
    awuser : std_logic_vector(c_axi4_full_auser_w-1 DOWNTO 0);
    awlock : std_logic;
    -- write data channel
    wdata   : std_logic_vector(c_axi4_full_data_w-1 downto 0);            -- write data
    wstrb   : std_logic_vector((c_axi4_full_data_w/c_byte_w)-1 downto 0); -- write strobes
    wvalid  : std_logic;                                                  -- write valid
    wlast   : std_logic;
    wid     : std_logic_vector(c_axi4_full_id_w-1 downto 0);              -- write data id
    -- write response channel
    bready  : std_logic;                                                  -- response ready
    -- read address channel
    arid    : std_logic_vector(c_axi4_full_id_w-1 downto 0);              -- read id
    araddr  : std_logic_vector(c_axi4_full_address_w-1 downto 0);         -- read address
    arprot  : std_logic_vector(c_axi4_full_prot_w-1 downto 0);            -- access permission for read
    arvalid : std_logic;                                                  -- read address valid
    arlen : std_logic_vector(c_axi4_full_alen_w-1 DOWNTO 0);
    arsize : std_logic_vector(c_axi4_full_asize_w-1 DOWNTO 0);
    arburst : std_logic_vector(c_axi4_full_aburst_w-1 DOWNTO 0);
    arcache : std_logic_vector(c_axi4_full_acache_w-1 DOWNTO 0);
    aruser : std_logic_vector(c_axi4_full_auser_w-1 DOWNTO 0);
    arlock : std_logic;
    -- read data channel
    rready  : std_logic;                                                  -- read ready

    awregion : std_logic_vector(c_axi4_full_aregion_w-1 downto 0);
    arregion : std_logic_vector(c_axi4_full_aregion_w-1 downto 0);
    arqos   : std_logic_vector(c_axi4_full_aqos_w-1 downto 0);
    awqos   : std_logic_vector(c_axi4_full_aqos_w-1 downto 0);
  END RECORD;

  TYPE t_axi4_full_miso IS RECORD  -- Master In Slave Out
    -- write_address channel
    awready : std_logic;                                       -- write address ready
    -- write data channel
    wready  : std_logic;                                       -- write ready
    -- write response channel
    bid     : std_logic_vector(c_axi4_full_id_w-1 downto 0);   -- write response id
    bresp   : std_logic_vector(c_axi4_full_resp_w-1 downto 0); -- write response
    bvalid  : std_logic;                                       -- write response valid
    buser   : std_logic_vector(c_axi4_full_auser_w-1 DOWNTO 0);
    -- read address channel
    arready : std_logic;                                       -- read address ready
    -- read data channel
    rid     : std_logic_vector(c_axi4_full_id_w-1 downto 0);   -- read id
    rdata   : std_logic_vector(c_axi4_full_data_w-1 downto 0); -- read data
    rresp   : std_logic_vector(c_axi4_full_resp_w-1 downto 0); -- read response
    rvalid  : std_logic;                                       -- read valid
    ruser   : std_logic_vector(c_axi4_full_auser_w-1 DOWNTO 0);
    rlast   : std_logic;
  END RECORD;

  -- Multi port array for MM records
  TYPE t_axi4_full_miso_arr IS ARRAY (INTEGER RANGE <>) OF t_axi4_full_miso;
  TYPE t_axi4_full_mosi_arr IS ARRAY (INTEGER RANGE <>) OF t_axi4_full_mosi;

  CONSTANT c_axi4_full_resp_okay   : STD_LOGIC_VECTOR(c_axi4_full_resp_w-1 DOWNTO 0) := "00"; -- normal access success
  CONSTANT c_axi4_full_resp_exokay : STD_LOGIC_VECTOR(c_axi4_full_resp_w-1 DOWNTO 0) := "01"; -- exclusive access okay
  CONSTANT c_axi4_full_resp_slverr : STD_LOGIC_VECTOR(c_axi4_full_resp_w-1 DOWNTO 0) := "10"; -- slave error
  CONSTANT c_axi4_full_resp_decerr : STD_LOGIC_VECTOR(c_axi4_full_resp_w-1 DOWNTO 0) := "11"; -- decode error


  CONSTANT c_axi4_full_miso_flush : t_axi4_full_miso := (awready => '1', wready => '1', bid     => (OTHERS => '0'), bresp   => c_axi4_full_resp_okay, bvalid  => '1', ruser => (OTHERS => '0'), buser => (OTHERS => '0'),
                                                         arready => '1', rid    => (OTHERS => '0'), rdata => (OTHERS => '0'), rresp  => c_axi4_full_resp_okay, rvalid  => '1', rlast => '1');

  CONSTANT c_axi4_full_mosi_null : t_axi4_full_mosi := (awid => (OTHERS => '0'), awaddr => (OTHERS => '0'), awprot => (OTHERS => '0'), awvalid => '0', awlen => (OTHERS => '0'), awsize => (OTHERS => '0'),
                                                        awburst => (OTHERS => '0'), awcache => (OTHERS => '0'), awuser => (OTHERS => '0'), awlock => '0', wdata => (OTHERS => '0'), wstrb => (OTHERS => '0'),
                                                        wvalid => '0', wlast => '0', wid => (OTHERS => '0'), bready => '1', arid => (OTHERS => '0'), araddr => (OTHERS => '0'), arprot => (OTHERS => '0'),
                                                        arvalid => '0', arlen => (OTHERS => '0'), arsize => (OTHERS => '0'), arburst => (OTHERS => '0'), arcache => (OTHERS => '0'), aruser => (OTHERS => '0'),
                                                        arlock => '0', rready => '1', awregion => (OTHERS => '0'), arregion => (OTHERS => '0'), arqos => (OTHERS => '0'), awqos => (OTHERS => '0'));

  -- Resize functions to fit an integer or an SLV in the corresponding t_axi4_full_miso or t_axi4_full_mosi field width
  FUNCTION TO_AXI4_FULL_ADDRESS(n : INTEGER) RETURN STD_LOGIC_VECTOR;  -- unsigned, use integer to support 32 bit range
  FUNCTION TO_AXI4_FULL_DATA(   n : INTEGER) RETURN STD_LOGIC_VECTOR;  -- unsigned, alias of TO_AXI4_full_DATA()
  FUNCTION TO_AXI4_FULL_UDATA(  n : INTEGER) RETURN STD_LOGIC_VECTOR;  -- unsigned, use integer to support 32 bit range
  FUNCTION TO_AXI4_FULL_SDATA(  n : INTEGER) RETURN STD_LOGIC_VECTOR;  -- sign extended
  FUNCTION RESIZE_AXI4_FULL_ADDRESS(vec : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR;  -- unsigned
  FUNCTION RESIZE_AXI4_FULL_DATA(   vec : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR;  -- unsigned, alias of RESIZE_AXI4_full_UDATA
  FUNCTION RESIZE_AXI4_FULL_UDATA(  vec : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR;  -- unsigned
  FUNCTION RESIZE_AXI4_FULL_SDATA(  vec : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR;  -- sign extended
  FUNCTION RESIZE_AXI4_FULL_XDATA(  vec : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR;  -- set unused MSBits to 'X'


  CONSTANT c_axi4_full_reg_rd_latency : NATURAL := 0;
  CONSTANT c_axi4_full_reg            : t_c_mem := (latency    => c_axi4_full_reg_rd_latency,
                                                    adr_w      => 1,
                                                    dat_w      => 32,
                                                    addr_base  => 0,
                                                    nof_dat    => 1,
                                                    nof_slaves => 1,
                                                    init_sl    => 'X');

  CONSTANT c_axi4_full_reg_init_w     : NATURAL := 1*256*32;  -- >= largest expected value of dat_w*nof_dat (256 * 32 bit = 1k byte)


END axi4_full_pkg;

PACKAGE BODY axi4_full_pkg IS

  -- Resize functions to fit an integer or an SLV in the corresponding t_axi4_full_miso or t_axi4_full_mosi field width
  FUNCTION TO_AXI4_FULL_ADDRESS(n : INTEGER) RETURN STD_LOGIC_VECTOR IS
  BEGIN
    RETURN RESIZE_UVEC(TO_SVEC(n, 32), c_axi4_full_address_w);
  END TO_AXI4_FULL_ADDRESS;

  FUNCTION TO_AXI4_FULL_DATA(n : INTEGER) RETURN STD_LOGIC_VECTOR IS
  BEGIN
    RETURN TO_AXI4_FULL_UDATA(n);
  END TO_AXI4_FULL_DATA;

  FUNCTION TO_AXI4_FULL_UDATA(n : INTEGER) RETURN STD_LOGIC_VECTOR IS
  BEGIN
    RETURN RESIZE_UVEC(TO_SVEC(n, 32), c_axi4_full_data_w);
  END TO_AXI4_FULL_UDATA;

  FUNCTION TO_AXI4_FULL_SDATA(n : INTEGER) RETURN STD_LOGIC_VECTOR IS
  BEGIN
    RETURN RESIZE_SVEC(TO_SVEC(n, 32), c_axi4_full_data_w);
  END TO_AXI4_FULL_SDATA;

  FUNCTION RESIZE_AXI4_FULL_ADDRESS(vec : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
  BEGIN
    RETURN RESIZE_UVEC(vec, c_axi4_full_address_w);
  END RESIZE_AXI4_FULL_ADDRESS;

  FUNCTION RESIZE_AXI4_FULL_DATA(vec : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
  BEGIN
    RETURN RESIZE_AXI4_FULL_UDATA(vec);
  END RESIZE_AXI4_FULL_DATA;

  FUNCTION RESIZE_AXI4_FULL_UDATA(vec : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
  BEGIN
    RETURN RESIZE_UVEC(vec, c_axi4_full_data_w);
  END RESIZE_AXI4_FULL_UDATA;

  FUNCTION RESIZE_AXI4_FULL_SDATA(vec : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
  BEGIN
    RETURN RESIZE_SVEC(vec, c_axi4_full_data_w);
  END RESIZE_AXI4_FULL_SDATA;

  FUNCTION RESIZE_AXI4_FULL_XDATA(vec : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
    VARIABLE v_vec : STD_LOGIC_VECTOR(c_axi4_full_data_w-1 DOWNTO 0) := (OTHERS=>'X');
  BEGIN
    v_vec(vec'LENGTH-1 DOWNTO 0) := vec;
    RETURN v_vec;
  END RESIZE_AXI4_FULL_XDATA;

END axi4_full_pkg;
