-------------------------------------------------------------------------------
--
-- File Name: eth_tx_ip_checksum.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Wed Aug 15 15:40:00 2017
-- Template Rev: 1.0
--
-- Title: IP Checksum Calculator
--
-- Description: Assumes the incoming packet is an IP packet with a VLAN header
--              and calculates the checksum for the IP header. New packet 
--              should be asserted at the beginning of a packet to reset the 
--              checksum generator to 0
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

-------------------------------------------------------------------------------
ENTITY eth_tx_ip_checksum IS
   GENERIC (
      g_technology            : t_technology);                            -- Max length of packet
   PORT (
      -- Clocks & Resets
      axi_clk        : IN STD_LOGIC;
      eth_tx_clk     : IN STD_LOGIC;
      rst            : IN STD_LOGIC;
      
      new_packet     : IN STD_LOGIC;
      
      tdata          : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      tkeep          : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      tlast          : IN STD_LOGIC;
      tvalid         : IN STD_LOGIC;
      
      checksum_pop   : IN STD_LOGIC;
      checksum       : OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
END eth_tx_ip_checksum;

-------------------------------------------------------------------------------
ARCHITECTURE behaviour of eth_tx_ip_checksum is
   
  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------


  ---------------------------------------------------------------------------
  -- SIGNAL DECLARATIONS  --
  ---------------------------------------------------------------------------

   SIGNAL word_counter        : UNSIGNED(3 DOWNTO 0);
   SIGNAL i_checksum          : UNSIGNED(17 DOWNTO 0);
   SIGNAL tdata_reg           : UNSIGNED(63 DOWNTO 0);
   SIGNAL tvalid_reg          : STD_LOGIC;
   SIGNAL checksum_final      : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL checksum_write      : STD_LOGIC;

  ---------------------------------------------------------------------------
  -- COMPONENT DECLARATIONS  --
  ---------------------------------------------------------------------------
   
   
BEGIN

word_cnt: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         IF new_packet = '1' OR rst = '1' THEN
            word_counter <= (OTHERS => '0');
         ELSE
            IF tvalid = '1' AND word_counter(3) = '0' THEN
               word_counter <= word_counter + 1;
            ELSE
               word_counter <= word_counter;
            END IF;
         END IF;
      END IF;
   END PROCESS;

crc_calc: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         tdata_reg <= UNSIGNED(tdata);
         tvalid_reg <= tvalid;
         
         IF tvalid_reg = '1' THEN
            IF word_counter = 3 THEN      -- Needs to be +1 becasue of the reset to 0 before the first valid
               i_checksum <= ("00" & tdata_reg(23 DOWNTO 16) & tdata_reg(31 DOWNTO 24)) +
                             ("00" & tdata_reg(39 DOWNTO 32) & tdata_reg(47 DOWNTO 40)) + 
                             ("00" & tdata_reg(55 DOWNTO 48) & tdata_reg(63 DOWNTO 56));
            ELSIF word_counter = 4 THEN
               i_checksum <= ("00" & i_checksum(15 DOWNTO 0)) + 
                             (X"00" & i_checksum(17 DOWNTO 16)) +
                             ("00" & tdata_reg(7 DOWNTO 0) & tdata_reg(15 DOWNTO 8)) +
                             ("00" & tdata_reg(23 DOWNTO 16) & tdata_reg(31 DOWNTO 24)) +
                             ("00" & tdata_reg(55 DOWNTO 48) & tdata_reg(63 DOWNTO 56));
            ELSIF word_counter = 5 THEN
               i_checksum <= ("00" & i_checksum(15 DOWNTO 0)) +  
                             (X"00" & i_checksum(17 DOWNTO 16)) +
                             ("00" & tdata_reg(7 DOWNTO 0) & tdata_reg(15 DOWNTO 8)) +
                             ("00" & tdata_reg(23 DOWNTO 16) & tdata_reg(31 DOWNTO 24)) +
                             ("00" & tdata_reg(39 DOWNTO 32) & tdata_reg(47 DOWNTO 40));
            ELSIF word_counter = 6 THEN
               i_checksum <= ("00" & i_checksum(15 DOWNTO 0)) +  
                             (X"00" & i_checksum(17 DOWNTO 16));
            ELSE
               i_checksum <= i_checksum;
            END IF;
         ELSE
            i_checksum <= i_checksum;
         END IF;
      END IF;
   END PROCESS;

   
   checksum_final <= NOT(STD_LOGIC_VECTOR(i_checksum(15 DOWNTO 0)));
   checksum_write <= tlast AND tvalid;

checksum_buffer: ENTITY common_lib.common_fifo_dc
                 GENERIC MAP (g_technology     => g_technology,
                              g_use_lut        => TRUE,
                              g_fifo_latency   => 1,
                              g_dat_w          => 16,
                              g_nof_words      => 16)         -- Length doesn't matter, just needs to be a couple long
                 PORT MAP (rst           => rst,
                           wr_clk        => axi_clk,
                           wr_dat        => checksum_final,
                           wr_req        => checksum_write,
                           wr_ful        => OPEN,
                           wr_prog_ful   => OPEN,
                           wrusedw       => OPEN,
                           rd_clk        => eth_tx_clk,
                           rd_dat        => checksum,
                           rd_req        => checksum_pop,
                           rd_emp        => OPEN,
                           rd_prog_emp   => OPEN,
                           rdusedw       => OPEN,
                           rd_val        => OPEN);

END behaviour;
-------------------------------------------------------------------------------