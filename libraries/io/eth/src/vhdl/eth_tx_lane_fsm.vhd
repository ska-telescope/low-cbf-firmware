-------------------------------------------------------------------------------
--
-- File Name: eth_tx_lane_fsm.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Wed Aug 15 15:40:00 2017
-- Template Rev: 1.0
--
-- Title: Lane Selection & Header MUX FSM
--
-- Description: Handles the selection of lanes for transmisison based on priority
--              and pending pause requests. Each lane is read until the end of 
--              packet is detected and then stopped
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

LIBRARY IEEE, common_lib, technology_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;

-------------------------------------------------------------------------------
ENTITY eth_tx_lane_fsm IS
   GENERIC (
      g_num_frame_inputs      : INTEGER;
      g_lane_priority         : t_integer_arr(0 to 15));
   PORT (
      -- Clocks & Resets
      axi_clk                 : IN STD_LOGIC;
      axi_rst                 : IN STD_LOGIC;
      eth_rx_clk              : IN STD_LOGIC;

      -- Pause Interface
      eth_pause_rx_enable     : OUT STD_LOGIC_VECTOR(8 downto 0);
      eth_pause_rx_req        : IN STD_LOGIC_VECTOR(8 downto 0);
      eth_pause_rx_ack        : OUT STD_LOGIC_VECTOR(8 downto 0);

      -- Inputs
      lane_ready              : IN STD_LOGIC_VECTOR(0 TO g_num_frame_inputs-1);        -- Lane not-empty Intidcators
      lane_ip                 : IN STD_LOGIC_VECTOR(0 TO g_num_frame_inputs-1);        -- Lane traffic is IP
      lane_udp                : IN STD_LOGIC_VECTOR(0 TO g_num_frame_inputs-1);        -- Lane traffic is UDP
      lane_tlast              : IN STD_LOGIC_VECTOR(0 TO g_num_frame_inputs-1);        -- Finished indicator for lane packet
      lane_short              : IN STD_LOGIC_VECTOR(0 TO g_num_frame_inputs-1);        -- Detector for extra valid cycle
      
      -- Logic Output
      lane_mux_sel            : OUT STD_LOGIC_VECTOR(ceil_log2(g_num_frame_inputs)-1 DOWNTO 0);
      meta_mux_sel            : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);

      lane_read               : OUT STD_LOGIC_VECTOR(0 TO g_num_frame_inputs-1);
      meta_data_valid         : OUT STD_LOGIC;
      new_packet              : OUT STD_LOGIC;
      
      packet_type             : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      start_transmit          : OUT STD_LOGIC);
END eth_tx_lane_fsm;

-------------------------------------------------------------------------------
ARCHITECTURE behaviour of eth_tx_lane_fsm is
   
  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   TYPE t_slv_lanes_arr       IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(g_num_frame_inputs-1 DOWNTO 0);
   TYPE t_read_state          IS (s_idle, s_lane_read, s_finished);

  ---------------------------------------------------------------------------
  -- SIGNAL DECLARATIONS  --
  ---------------------------------------------------------------------------

   SIGNAL lane_ready_masked         : t_slv_lanes_arr(0 TO 7);

   SIGNAL reading_lane              : STD_LOGIC_VECTOR(0 TO g_num_frame_inputs-1);
   SIGNAL selected_lane             : STD_LOGIC_VECTOR(0 TO g_num_frame_inputs-1);
   SIGNAL lane_finished             : STD_LOGIC_VECTOR(0 TO g_num_frame_inputs-1);
   SIGNAL lane_extra_cycle          : STD_LOGIC_VECTOR(0 TO g_num_frame_inputs-1);

   SIGNAL i_new_packet              : STD_LOGIC;
   SIGNAL i_lane_read               : STD_LOGIC_VECTOR(0 TO g_num_frame_inputs-1);
   SIGNAL i_lane_mux_sel            : STD_LOGIC_VECTOR(ceil_log2(g_num_frame_inputs)-1 DOWNTO 0);
   
   SIGNAL i_eth_pause_rx_ack        : STD_LOGIC_VECTOR(8 downto 0);
   SIGNAL eth_pause_rx_ack_dly      : STD_LOGIC_VECTOR(8 downto 0);
   SIGNAL paused_ely                : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL paused                    : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL global_paused_ely         : STD_LOGIC;
   SIGNAL global_paused             : STD_LOGIC;

   SIGNAL read_state                : t_read_state;
   SIGNAL word_counter              : UNSIGNED(3 DOWNTO 0);
   SIGNAL ip_sel                    : STD_LOGIC;
   SIGNAL udp_sel                   : STD_LOGIC;
   SIGNAL start_transmit_ely        : STD_LOGIC;
   SIGNAL meta_data_valid_ely       : STD_LOGIC;
   SIGNAL meta_mux_sel_ely          : STD_LOGIC_VECTOR(2 DOWNTO 0);

  ---------------------------------------------------------------------------
  -- FUNCTION DECLARATIONS  --
  ---------------------------------------------------------------------------

   FUNCTION priority_present(pri : NATURAL) RETURN STD_LOGIC IS
   BEGIN
      FOR i IN 0 TO g_num_frame_inputs-1 LOOP
         IF g_lane_priority(i) = pri THEN
            RETURN '1';
         END IF;
      END LOOP;
      RETURN '0';
   END;

   
BEGIN

   
   lane_read <= i_lane_read;
   lane_mux_sel <= i_lane_mux_sel;
   
   eth_pause_rx_ack <= i_eth_pause_rx_ack;

-- Assign the lanes to each priority level. Needs to dynamically create a big IF tree based on 
-- priority. Also include the previous reading lane to make sure we don't keep hitting the same 
-- lane over and over again.
   
lane_loop: FOR lane IN 0 TO g_num_frame_inputs-1 GENERATE
   priority_loop: FOR priority IN 0 TO 7 GENERATE
      lane_ready_masked(priority)(lane) <= lane_ready(lane) AND NOT(reading_lane(lane)) when g_lane_priority(lane) = priority else '0';
   END GENERATE;
END GENERATE;

---------------------------------------------------------------------------
-- Pause Logic  --
---------------------------------------------------------------------------
-- The PAUSE logic runs off a much faster clock. When a PAUSE request comes 
-- in we acknowledge it set the pause vector correctly whcih masks out any 
-- lanes with that priority level, oterh traffic continues as normal

enable_priorities: FOR priority IN 0 TO 7 GENERATE
   eth_pause_rx_enable(priority) <= priority_present(priority);
END GENERATE;

   -- Global Pause always enabled
   eth_pause_rx_enable(8) <= '1';

pause: PROCESS(eth_rx_clk)
   BEGIN
      IF RISING_EDGE(eth_rx_clk) THEN
         eth_pause_rx_ack_dly <= i_eth_pause_rx_ack;
         
         
         FOR I IN 0 TO 8 LOOP
            IF eth_pause_rx_req(i) = '1' THEN
               i_eth_pause_rx_ack(i) <= '1';
            ELSE
               i_eth_pause_rx_ack(i) <= '0';
            END IF;
         END LOOP;
      END IF;
   END PROCESS;

pause_retime: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         paused_ely <= eth_pause_rx_ack_dly(7 downto 0);
         paused <= paused_ely;
         
         global_paused_ely <= eth_pause_rx_ack_dly(8);
         global_paused <= global_paused_ely;
      END IF;
   END PROCESS;

---------------------------------------------------------------------------
-- Controller  --
---------------------------------------------------------------------------
-- Wait until one of the lanes asserts data ready. Selection is based on 
-- priority and orver form 0 to N. Once a lane is selected it is read until 
-- TLAST comes out. 

   lane_finished <= selected_lane and lane_tlast;
   lane_extra_cycle <= selected_lane and lane_short;

fsm: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         IF axi_rst = '1' THEN
            read_state     <= s_idle;
            selected_lane  <= (OTHERS => '0');
            reading_lane   <= (OTHERS => '0');
            word_counter   <= (OTHERS => '0');
            i_lane_mux_sel   <= (OTHERS => '0');
            i_new_packet     <= '0';
         ELSE
            CASE read_state IS
               -------------------------------
               WHEN s_idle =>                                              -- Pick one of g_num_frame_inputs start at highest priority level and work backwards
                  selected_lane  <= (OTHERS => '0');
                  word_counter   <= (OTHERS => '0');
                  i_lane_mux_sel   <= (OTHERS => '0');
                  read_state     <= s_idle;
                  i_new_packet   <= '0';
               
                  loop1: FOR priority IN 7 DOWNTO 0 LOOP
                     IF (lane_ready_masked(priority) /= STD_LOGIC_VECTOR(TO_UNSIGNED(0, g_num_frame_inputs))) AND (paused(priority) = '0') AND (global_paused = '0') THEN
                        loop2: FOR lane_select in 0 TO g_num_frame_inputs-1 LOOP
                           IF lane_ready_masked(priority)(lane_select) = '1' THEN
                              read_state <= s_lane_read;
                              selected_lane(lane_select) <= '1';
                              i_lane_mux_sel <= STD_LOGIC_VECTOR(TO_UNSIGNED(lane_select, ceil_log2(g_num_frame_inputs)));
                              ip_sel <= lane_ip(lane_select);
                              udp_sel <= lane_udp(lane_select);
                              i_new_packet <= '1';
                              EXIT loop1;
                           END IF;
                        END LOOP;           
                     END IF;
                  END LOOP;

               -------------------------------
               WHEN s_lane_read =>                                            -- Read the lane until the TLAST pops out
                  i_new_packet <= '0';
                  reading_lane <= selected_lane;
                  i_lane_mux_sel <= i_lane_mux_sel;
                  
                  IF (lane_ready AND selected_lane) /= STD_LOGIC_VECTOR(TO_UNSIGNED(0, g_num_frame_inputs)) THEN
                     IF word_counter(3) = '0' THEN
                        word_counter <= word_counter + 1;
                     END IF;
                  END IF;
                  
                  IF lane_finished /= STD_LOGIC_VECTOR(TO_UNSIGNED(0, g_num_frame_inputs)) THEN
                     read_state <= s_finished;
                  END IF;

               -------------------------------
               WHEN s_finished =>
                  -- If nothing else is waiting then don't mask out the current lane
                  IF (lane_ready AND NOT(reading_lane)) = STD_LOGIC_VECTOR(TO_UNSIGNED(0, g_num_frame_inputs)) THEN
                     reading_lane <= (OTHERS => '0');
                  END IF;
                     
                  selected_lane <= (OTHERS => '0');
                  
                  read_state <= s_idle;
            END CASE;
         END IF;
      END IF;
   END PROCESS;
   
   start_transmit_ely <= '1' when read_state = s_finished else '0';
      
start_transmit_pipe: ENTITY common_lib.common_pipeline
                     GENERIC MAP (g_pipeline  => 7,        -- Needs adjustment
                                  g_in_dat_w  => 3,
                                  g_out_dat_w => 3)
                      PORT MAP (clk                   => axi_clk,
                                rst                   => '0',
                                in_dat(0)             => start_transmit_ely,
                                in_dat(1)             => ip_sel,
                                in_dat(2)             => udp_sel,
                                out_dat(0)            => start_transmit,
                                out_dat(2 DOWNTO 1)   => packet_type);   
      
   
   -- Read lane while it is selected and the fifo has data
   -- Stop reading when tlast appears
   i_lane_read <= selected_lane WHEN i_new_packet = '1' ELSE
                  selected_lane AND NOT(lane_tlast) AND lane_ready;
   
   -- Mux in the IP/MAC addresses where nessecary
   meta_mux_sel_ely <= "000" WHEN word_counter = 0 ELSE
                       "001" WHEN word_counter = 1 ELSE
                       "011" WHEN word_counter = 3 and ip_sel = '1' ELSE
                       "100" WHEN word_counter = 4 and ip_sel = '1' ELSE
                       "010";
   
meta_mux_sel_pipe: ENTITY common_lib.common_pipeline
                   GENERIC MAP (g_pipeline  => 4,           -- Needs adjustment
                                g_in_dat_w  => 3,
                                g_out_dat_w => 3)
                   PORT MAP (clk       => axi_clk,
                             rst       => '0',
                             in_dat    => meta_mux_sel_ely,
                             out_dat   => meta_mux_sel);   

   meta_data_valid_ely <= '1' WHEN i_lane_read /= STD_LOGIC_VECTOR(TO_UNSIGNED(0, g_num_frame_inputs)) ELSE
                          '1' WHEN lane_extra_cycle /= STD_LOGIC_VECTOR(TO_UNSIGNED(0, g_num_frame_inputs)) ELSE
                          '0';

meta_valid_sel_pipe: ENTITY common_lib.common_pipeline
                     GENERIC MAP (g_pipeline  => 4,
                                  g_in_dat_w  => 1,
                                  g_out_dat_w => 1)
                     PORT MAP (clk          => axi_clk,
                               rst          => '0',
                               in_dat(0)    => meta_data_valid_ely,
                               out_dat(0)   => meta_data_valid);   

new_packet_pipe: ENTITY common_lib.common_pipeline
                 GENERIC MAP (g_pipeline  => 4,
                              g_in_dat_w  => 1,
                              g_out_dat_w => 1)
                 PORT MAP (clk          => axi_clk,
                           rst          => '0',
                           in_dat(0)    => i_new_packet,
                           out_dat(0)   => new_packet);  

END behaviour;
-------------------------------------------------------------------------------