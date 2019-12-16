----------------------------------------------------------------------------
-- (c) Copyright - Commonwealth Scientific and Industrial Research Organisation
-- (CSIRO) - 2017
--
-- All Rights Reserved.
--
-- Restricted Use.
--
-- Copyright protects this code. Except as permitted by the Copyright Act, you
-- may only use the code as expressly permitted under the terms on which the
-- code was licensed to you.
--
-------------------------------------------------------------------------------
--
-- File Name: uptime_counter.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Thurs Feb 8 10:53:00 2018
-- Template Rev: 1.0
--
-- Title: Uptime Counter
--
-- Description: Generates a count of seconds since FPGA was started. Counters are
--              made in a couple fo stages so the widths aren't so bad
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
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ALL;
USE common_lib.common_pkg.ALL;

ENTITY uptime_counter IS
  GENERIC (
    g_tod_width      : INTEGER := 14;
    g_clk_freq       : REAL := 125.0E6);
  PORT (
    clk              : IN STD_LOGIC;
    rst              : IN STD_LOGIC;
    pps              : OUT STD_LOGIC;
    tod              : OUT STD_LOGIC_VECTOR(g_tod_width-1 DOWNTO 0);
    tod_rollover     : OUT STD_LOGIC);
END uptime_counter;

ARCHITECTURE arch OF uptime_counter IS

  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   CONSTANT c_msCount_width      : INTEGER := ceil_log2(INTEGER(g_clk_freq / 1000.0 - 1.0));
   CONSTANT c_msCount            : UNSIGNED(c_msCount_width-1 DOWNTO 0) := TO_UNSIGNED(INTEGER(g_clk_freq / 1000.0 - 1.0), c_msCount_width);

  ---------------------------------------------------------------------------
  -- SIGNAL DECLARATIONS  --
  ---------------------------------------------------------------------------

   SIGNAL msCount                : UNSIGNED(c_msCount_width-1 DOWNTO 0);
   SIGNAL msPulse                : STD_LOGIC;
   SIGNAL ppsPulse               : STD_LOGIC;
   SIGNAL ppsCount               : UNSIGNED(9 DOWNTO 0);
   SIGNAL uptime_count           : UNSIGNED(g_tod_width-1 DOWNTO 0);

BEGIN

   -- Output pulse extended by 2^8 clocks
pps_extend : ENTITY common_lib.common_pulse_extend
             GENERIC MAP (g_extend_w => 8)
             PORT MAP (clk     => clk,
                       rst     => rst,
                       p_in    => ppsPulse,
                       ep_out  => pps);

   tod <= STD_LOGIC_VECTOR(uptime_count);

---------------------------------------------------------------------------
-- Counters  --
---------------------------------------------------------------------------

   -- Generate a 1ms pulse first
   PROCESS(clk)
   BEGIN
      IF RISING_EDGE(CLK) THEN
         msPulse <= '0';
         IF rst = '1' THEN
            msCount <= (OTHERS => '0');
         ELSE
            IF msCount = c_msCount THEN
               msCount <= (OTHERS => '0');
               msPulse <= '1';
            ELSE
               msCount <= msCount + 1;
            END IF;
         END IF;
      END IF;
   END PROCESS;


   -- Generate a 1pps
   PROCESS(clk)
   BEGIN
      IF RISING_EDGE(CLK) THEN
         ppsPulse <= '0';
         IF rst = '1' THEN
            ppsCount <= (OTHERS => '0');
         ELSE
            IF msPulse = '1' THEN
               IF ppsCount = TO_UNSIGNED(999, 10) THEN
                  ppsCount <= (OTHERS => '0');
                  ppsPulse <= '1';
               ELSE
                  ppsCount <= ppsCount + 1;
               END IF;
            END IF;
         END IF;
      END IF;
   END PROCESS;

---------------------------------------------------------------------------
-- TOD Counter  --
---------------------------------------------------------------------------

   -- Count seconds
   PROCESS(clk)
   BEGIN
      IF RISING_EDGE(CLK) THEN
         IF rst = '1' THEN
            uptime_count <= (OTHERS => '0');
            tod_rollover <= '0';
         ELSE
            IF ppsPulse = '1' THEN
               uptime_count <= uptime_count + 1;

               IF uptime_count = (uptime_count'RANGE => '1') THEN
                  tod_rollover <= '1';
               END IF;
            END IF;
         END IF;
      END IF;
   END PROCESS;
END arch;
