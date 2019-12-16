LIBRARY IEEE, technology_lib;
USE IEEE.std_logic_1164.ALL;
USE technology_lib.technology_pkg.ALL;


PACKAGE tech_mac_25g_quad_pkg IS

   TYPE t_quad_locations_25g IS (
      QUAD_25G_234,
      QUAD_25G_233, QUAD_25G_232, QUAD_25G_231,
      QUAD_25G_230, QUAD_25G_229, QUAD_25G_228,
      QUAD_25G_226, QUAD_25G_225, QUAD_25G_224,
      QUAD_25G_222, QUAD_25G_221, QUAD_25G_220,
      QUAD_25G_131, QUAD_25G_130, QUAD_25G_128,
      QUAD_25G_126, QUAD_25G_125, QUAD_25G_124,
      QUAD_25G_122, QUAD_25G_132, QUAD_25G_134,
      QUAD_25G_135);

END tech_mac_25g_quad_pkg;

