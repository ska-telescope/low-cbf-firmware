-------------------------------------------------------------------------------
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
-- File Name: service_fsm.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Monday Sept 11 15:40:00 2017
-- Template Rev: 1.0
--
-- Title: Client Servicing State Machine
--
-- Description: 
--
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

LIBRARY IEEE, common_lib, axi4_lib, technology_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;

-------------------------------------------------------------------------------
ENTITY service_fsm IS  
   GENERIC (
      g_num_clients           : INTEGER := 4);
    
   PORT (
      -- Clocks & Resets
      axi_clk                 : IN STD_LOGIC;

      axi_rst                 : IN STD_LOGIC;

      -- Client Interfaces
      client_tvalid           : IN STD_LOGIC_VECTOR(0 TO g_num_clients-1);
      client_tready           : OUT STD_LOGIC_VECTOR(0 TO g_num_clients-1);
      client_tlast            : IN STD_LOGIC;
      client_mux              : OUT STD_LOGIC_VECTOR(ceil_log2(g_num_clients)-1 DOWNTO 0);

      client_pipe_enable      : OUT STD_LOGIC;

      -- Output Port 
      tvalid                  : OUT STD_LOGIC;
      tready                  : IN STD_LOGIC);
END service_fsm;

-------------------------------------------------------------------------------
ARCHITECTURE behaviour of service_fsm is
   
  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   CONSTANT c_num_clients_width     : INTEGER := ceil_log2(g_num_clients);
   
   TYPE service_fsm_states IS (s_idle, s_lane_selected);
   
  ---------------------------------------------------------------------------
  -- SIGNAL DECLARATIONS  --
  ---------------------------------------------------------------------------

   -- FSM Details
   SIGNAL service_state          : service_fsm_states;
   SIGNAL client_selected        : STD_LOGIC_VECTOR(c_num_clients_width-1 DOWNTO 0);
   SIGNAL tvalid_masked          : STD_LOGIC_VECTOR(g_num_clients-1 DOWNTO 0);
   SIGNAL publish_available      : STD_LOGIC_VECTOR(g_num_clients-1 DOWNTO 0);
   SIGNAL last_selected          : STD_LOGIC_VECTOR(g_num_clients-1 DOWNTO 0);
   SIGNAL client_mask            : STD_LOGIC_VECTOR(g_num_clients-1 DOWNTO 0);
   SIGNAL tvalid_ely             : STD_LOGIC;
   SIGNAL precharge              : STD_LOGIC;
   SIGNAL ready_pipe_enable      : STD_LOGIC;
   
BEGIN

   client_mux <= client_selected;

   client_pipe_enable <= ready_pipe_enable;

---------------------------------------------------------------------------
-- Control FSM  --
---------------------------------------------------------------------------

   
   publish_available <= client_tvalid and not(last_selected);

   tvalid_masked <= client_tvalid AND client_mask;

service_fsm: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         IF axi_rst = '1' THEN
            service_state <= s_idle;
            client_mask <= (OTHERS => '0');
            last_selected <= (OTHERS => '0');
            client_selected <= (OTHERS => '0');
         ELSE
            CASE service_state IS
               -------------------------------
               WHEN s_idle =>                                        -- Wait for paket to be ready
                  loop1: FOR i IN 0 TO g_num_clients -1 LOOP
                     IF publish_available(i) = '1' THEN
                        client_selected <= STD_LOGIC_VECTOR(TO_UNSIGNED(i, c_num_clients_width));
                        service_state <= s_lane_selected;
                        
                        -- Clear old last selected status and set new one
                        last_selected <= (OTHERS => '0');
                        last_selected(i) <= '1';
                        
                        client_mask <= (OTHERS => '0');
                        client_mask(i) <= '1';
                        precharge <= '1';
                        EXIT loop1;
                     END IF;
                  END LOOP;

               -------------------------------
               WHEN s_lane_selected =>                               -- Wait for end of packet to come out
                  precharge <= '0';
                  IF tready = '1' AND client_tlast = '1' THEN
                     service_state <= s_idle;
                     client_mask <= (OTHERS => '0');
                     
                     IF publish_available = STD_LOGIC_VECTOR(TO_UNSIGNED(0, g_num_clients)) THEN
                        last_selected <= (OTHERS => '0');
                     END IF;
                  END IF;
            END CASE;
         END IF;
      END IF;
   END PROCESS;


   tvalid_ely <= '1' WHEN tvalid_masked /= STD_LOGIC_VECTOR(TO_UNSIGNED(0, g_num_clients)) AND client_tlast = '0' ELSE '0';

   client_tready <= client_mask WHEN ready_pipe_enable = '1' ELSE (OTHERS => '0');

   ready_pipe_enable <= '1' WHEN precharge = '1' OR (tready = '1' AND service_state = s_lane_selected) ELSE '0';


valid_data_pipe: ENTITY common_lib.common_pipeline
                 GENERIC MAP (g_pipeline  => 1,
                              g_in_dat_w  => 1,
                              g_out_dat_w => 1)
                 PORT MAP (clk                   => axi_clk,
                           rst                   => '0',
                           in_en                 => ready_pipe_enable,
                           in_dat(0)             => tvalid_ely,
                           out_dat(0)            => tvalid);


   
END ARCHITECTURE;