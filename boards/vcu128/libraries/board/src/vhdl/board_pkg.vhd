-------------------------------------------------------------------------------
--
-- File Name: board_pkg.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Tuesday Nov 28 16:40:00 2017
-- Template Rev: 1.0
--
-- Title: LRU Board Library Defines
--
-- Description:
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

LIBRARY IEEE, common_lib, technology_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;

PACKAGE board_pkg IS

   TYPE t_qsfp IS (QSFP1, QSFP2, QSFP3, QSFP4);

   -- Index is quad/gty number and data is actual port
   CONSTANT c_qsfp1_rx_remap       : t_integer_arr(0 TO 3) := (3, 2, 1, 0);  -- 126
   CONSTANT c_qsfp1_tx_remap       : t_integer_arr(0 TO 3) := (1, 0, 2, 3);
   
   CONSTANT c_qsfp1_tx_polarity    : STD_LOGIC_VECTOR(0 TO 3) := (OTHERS => '1');
   CONSTANT c_qsfp1_rx_polarity    : STD_LOGIC_VECTOR(0 TO 3) := (OTHERS => '0');
   
   CONSTANT c_qsfp2_rx_remap       : t_integer_arr(0 TO 3) := (3, 2, 1, 0);  -- 125
   CONSTANT c_qsfp2_tx_remap       : t_integer_arr(0 TO 3) := (1, 0, 2, 3);
   
   CONSTANT c_qsfp2_tx_polarity    : STD_LOGIC_VECTOR(0 TO 3) := (OTHERS => '1');
   CONSTANT c_qsfp2_rx_polarity    : STD_LOGIC_VECTOR(0 TO 3) := (OTHERS => '0');
   
   CONSTANT c_qsfp3_rx_remap       : t_integer_arr(0 TO 3) := (3, 2, 1, 0);  -- 124
   CONSTANT c_qsfp3_tx_remap       : t_integer_arr(0 TO 3) := (1, 0, 2, 3);
   
   CONSTANT c_qsfp3_tx_polarity    : STD_LOGIC_VECTOR(0 TO 3) := (OTHERS => '1');
   CONSTANT c_qsfp3_rx_polarity    : STD_LOGIC_VECTOR(0 TO 3) := (OTHERS => '0');
   
   CONSTANT c_qsfp4_rx_remap       : t_integer_arr(0 TO 3) := (3, 2, 1, 0);  -- 122
   CONSTANT c_qsfp4_tx_remap       : t_integer_arr(0 TO 3) := (1, 0, 2, 3);
   
   CONSTANT c_qsfp4_tx_polarity    : STD_LOGIC_VECTOR(0 TO 3) := (OTHERS => '1');
   CONSTANT c_qsfp4_rx_polarity    : STD_LOGIC_VECTOR(0 TO 3) := (OTHERS => '0');
   
   -- Functions
   FUNCTION sel_qsfp_mapping(qsfp : t_qsfp; tx: BOOLEAN) RETURN t_integer_arr;
   FUNCTION sel_qsfp_polarity(qsfp : t_qsfp; tx : BOOLEAN) RETURN STD_LOGIC_VECTOR;

   FUNCTION remap_attribute_slv(unmapped  : STD_LOGIC_VECTOR; mapping : t_integer_arr) RETURN STD_LOGIC_VECTOR;
   FUNCTION remap_attribute_slv(unmapped  : STD_LOGIC_VECTOR; quad : INTEGER; mapping : t_integer_arr) RETURN STD_LOGIC_VECTOR;
   FUNCTION remap_attribute_slv5(unmapped : t_slv_5_arr; mapping : t_integer_arr) RETURN t_tech_slv_5_arr;
   FUNCTION remap_attribute_slv5(unmapped : t_slv_5_arr; quad : INTEGER; mapping : t_integer_arr) RETURN t_tech_slv_5_arr;
   FUNCTION remap_attribute_slv7(unmapped : t_slv_7_arr; mapping : t_integer_arr) RETURN t_tech_slv_7_arr;
   FUNCTION remap_attribute_slv7(unmapped : t_slv_7_arr; quad : INTEGER; mapping : t_integer_arr) RETURN t_tech_slv_7_arr;

END board_pkg;

PACKAGE BODY board_pkg IS

   FUNCTION sel_qsfp_mapping(qsfp  : t_qsfp;
                             tx    : BOOLEAN) RETURN t_integer_arr IS
   BEGIN
      IF qsfp = QSFP1 THEN
         IF tx = TRUE THEN
            RETURN c_qsfp1_tx_remap;
         ELSE
            RETURN c_qsfp1_rx_remap;
         END IF;
      ELSIF qsfp = QSFP2 THEN
         IF tx = TRUE THEN
            RETURN c_qsfp2_tx_remap;
         ELSE
            RETURN c_qsfp2_rx_remap;
         END IF;
      ELSIF qsfp = QSFP3 THEN
         IF tx = TRUE THEN
            RETURN c_qsfp3_tx_remap;
         ELSE
            RETURN c_qsfp3_rx_remap;
         END IF;
      ELSIF qsfp = QSFP4 THEN
         IF tx = TRUE THEN
            RETURN c_qsfp4_tx_remap;
         ELSE
            RETURN c_qsfp4_rx_remap;
         END IF;
      ELSE
        RETURN c_qsfp1_tx_remap;
      END IF;
   END FUNCTION;

   FUNCTION sel_qsfp_polarity(qsfp  : t_qsfp;
                              tx    : BOOLEAN) RETURN STD_LOGIC_VECTOR IS
   BEGIN
      IF qsfp = QSFP1 THEN
         IF tx = TRUE THEN
            RETURN c_qsfp1_tx_polarity;
         ELSE
            RETURN c_qsfp1_rx_polarity;
         END IF;
      ELSIF qsfp = QSFP2 THEN
         IF tx = TRUE THEN
            RETURN c_qsfp2_tx_polarity;
         ELSE
            RETURN c_qsfp2_rx_polarity;
         END IF;
      ELSIF qsfp = QSFP3 THEN
         IF tx = TRUE THEN
            RETURN c_qsfp3_tx_polarity;
         ELSE
            RETURN c_qsfp3_rx_polarity;
         END IF;
      ELSIF qsfp = QSFP4 THEN
         IF tx = TRUE THEN
            RETURN c_qsfp4_tx_polarity;
         ELSE
            RETURN c_qsfp4_rx_polarity;
         END IF;
      ELSE
        RETURN c_qsfp1_tx_polarity;
      END IF;
   END FUNCTION;

   -- Generic Functions
   -----------------------
   FUNCTION remap_attribute_slv(unmapped  : STD_LOGIC_VECTOR;
                                mapping   : t_integer_arr) RETURN STD_LOGIC_VECTOR IS
       VARIABLE v_result : STD_LOGIC_VECTOR(unmapped'HIGH DOWNTO 0);
   BEGIN
      remap_loop: FOR i IN 0 TO unmapped'HIGH LOOP
         v_result(i) := unmapped(mapping(i));
      END LOOP;

      RETURN v_result;
   END;

   -----------------------
   -- Map transciever attributes so that the data in the mapping array is used as lookup indexes
   -- into the unmapped array. Return a quad worth of results
   FUNCTION remap_attribute_slv(unmapped  : STD_LOGIC_VECTOR;
                                quad      : INTEGER;
                                mapping   : t_integer_arr) RETURN STD_LOGIC_VECTOR IS
       VARIABLE v_result : STD_LOGIC_VECTOR(3 DOWNTO 0);
   BEGIN
      remap_loop: FOR i IN 0 TO 3 LOOP
         v_result(i) := unmapped(mapping(quad*4+i));
      END LOOP;

      RETURN v_result;
   END;

   -----------------------
   FUNCTION remap_attribute_slv5(unmapped : t_slv_5_arr;
                                 mapping  : t_integer_arr) RETURN t_tech_slv_5_arr IS
       VARIABLE v_result   : t_tech_slv_5_arr(unmapped'HIGH DOWNTO 0);
   BEGIN
      remap_loop: FOR i IN 0 TO unmapped'HIGH LOOP
         v_result(i) := unmapped(mapping(i));
      END LOOP;

      RETURN v_result;
   END;

   -----------------------
   FUNCTION remap_attribute_slv5 (unmapped   : t_slv_5_arr;
                                  quad       : INTEGER;
                                  mapping    : t_integer_arr) RETURN t_tech_slv_5_arr IS
       VARIABLE v_result : t_tech_slv_5_arr(3 DOWNTO 0);
   BEGIN
      remap_loop: FOR i IN 0 TO 3 LOOP
         v_result(i) := unmapped(mapping(quad*4+i));
      END LOOP;

      RETURN v_result;
   END;

   -----------------------
   FUNCTION remap_attribute_slv7(unmapped : t_slv_7_arr;
                                 mapping  : t_integer_arr) RETURN t_tech_slv_7_arr IS
       VARIABLE v_result : t_tech_slv_7_arr(unmapped'HIGH DOWNTO 0);
   BEGIN
      remap_loop: FOR i IN 0 TO unmapped'HIGH LOOP
         v_result(i) := unmapped(mapping(i));
      END LOOP;

      RETURN v_result;
   END;

   -----------------------
   FUNCTION remap_attribute_slv7(unmapped : t_slv_7_arr;
                                 quad     : INTEGER;
                                 mapping  : t_integer_arr) RETURN t_tech_slv_7_arr IS
       VARIABLE v_result : t_tech_slv_7_arr(3 DOWNTO 0);
   BEGIN
      remap_loop: FOR i IN 0 TO 3 LOOP
         v_result(i) := unmapped(mapping(quad*4+i));
      END LOOP;

      RETURN v_result;
   END;

END PACKAGE BODY;


