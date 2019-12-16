-------------------------------------------------------------------------------
-- File Name: eth_rx_tvalid_extend.vhd
-- Contributing Authors: Leon Hiemstra
-- Created: September, 2017
--
-- Title: Ethernet RX tvalid signal extender
--
-- Description: pipelines the tvalid signals
--
-------------------------------------------------------------------------------

LIBRARY IEEE, technology_lib, common_lib;
USE IEEE.std_logic_1164.ALL;
USE common_lib.common_pkg.ALL;
USE work.eth_pkg.ALL;


ENTITY eth_rx_tvalid_extend IS
  GENERIC (
      g_dat_w : INTEGER := 7
  );
  PORT (
    clk   : IN STD_LOGIC;
    rst   : IN STD_LOGIC;

    tvalid_on  : IN STD_LOGIC;
    tvalid_off : IN STD_LOGIC;

    in_dat  : IN  STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
    out_dat : OUT STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0)
  );
END eth_rx_tvalid_extend;


ARCHITECTURE str OF eth_rx_tvalid_extend IS

TYPE t_reg IS RECORD
    out_dat : STD_LOGIC_VECTOR(g_dat_w-1 DOWNTO 0);
END RECORD;

SIGNAL r, nxt_r  : t_reg;

BEGIN

  p_comb: PROCESS(rst, r, in_dat, tvalid_on, tvalid_off)
    VARIABLE v : t_reg;
  BEGIN
      -- defaults:
      v := r;

      IF tvalid_on = '1' THEN
          FOR i IN 0 TO g_dat_w-1 LOOP
            v.out_dat(i) := in_dat(i);
          END LOOP;
      END IF;

      IF tvalid_on = '0' AND tvalid_off = '0' THEN
          FOR i IN 0 TO g_dat_w-1 LOOP
            v.out_dat(i) := '0';
          END LOOP;
      END IF;

      IF rst='1' THEN
        FOR i IN 0 TO g_dat_w-1 LOOP
          v.out_dat(i) := '0';
        END LOOP;
      END IF;
  
      nxt_r <= v; -- updating registers

  END PROCESS;

  p_reg : PROCESS(clk)
  BEGIN
      IF rising_edge(clk) THEN
          r <= nxt_r;
      END IF;
  END PROCESS;


  -- connect to outside world
  gen_out_dat_ext : FOR i IN g_dat_w-1 DOWNTO 0 GENERATE
    out_dat(i) <= r.out_dat(i);
  END GENERATE;


END str;


