LIBRARY IEEE, technology_lib;
USE IEEE.std_logic_1164.ALL;
USE technology_lib.technology_pkg.ALL;


PACKAGE tech_mac_100g_pkg IS

   TYPE t_quad_locations_100g IS (
      QUAD_100G_122, QUAD_100G_124, QUAD_100G_125, QUAD_100G_126, QUAD_100G_128, QUAD_100G_130, QUAD_100G_131, QUAD_100G_132, QUAD_100G_134, QUAD_100G_135);

   CONSTANT c_lbus_data_w            : NATURAL :=  512;   -- Data width
   CONSTANT c_segment_w              : NATURAL :=  128;   -- Segment data width

   TYPE t_empty_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(tech_ceil_log2(c_segment_w/8)-1 DOWNTO 0);


   TYPE t_lbus_siso IS RECORD  -- Source In and Sink Out
      ready      : STD_LOGIC;                                              -- Data bus ready to accept data
      overflow   : STD_LOGIC;                                              -- Transaction overflow
      underflow  : STD_LOGIC;                                              -- Transaction underflow
   END RECORD;

   TYPE t_lbus_sosi IS RECORD  -- Source Out and Sink In
      data       : STD_LOGIC_VECTOR(c_lbus_data_w-1 DOWNTO 0);                -- Data bus
      valid      : STD_LOGIC_VECTOR(c_lbus_data_w/c_segment_w-1 DOWNTO 0);    -- Data segment enable
      eop        : STD_LOGIC_VECTOR(c_lbus_data_w/c_segment_w-1 DOWNTO 0);    -- End of packet
      sop        : STD_LOGIC_VECTOR(c_lbus_data_w/c_segment_w-1 DOWNTO 0);    -- Start of packet
      error      : STD_LOGIC_VECTOR(c_lbus_data_w/c_segment_w-1 DOWNTO 0);    -- Error flag, indicates data has an error
      empty      : t_empty_arr(c_lbus_data_w/c_segment_w-1 DOWNTO 0);         -- Number of bytes empty in the segment
   END RECORD;

   CONSTANT c_lbus_siso_rst   : t_lbus_siso := (ready => '0', overflow => '0', underflow => '0');
   CONSTANT c_lbus_sosi_rst   : t_lbus_sosi := (data => (OTHERS => '0'),
                                                valid => (OTHERS => '0'),
                                                eop => (OTHERS => '0'),
                                                sop => (OTHERS => '0'),
                                                error => (OTHERS => '0'),
                                                empty => (OTHERS => (OTHERS => '1')));


END tech_mac_100g_pkg;

