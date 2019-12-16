-------------------------------------------------------------------------------
--
-- File Name: eth_tx_fsm.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Wed Aug 15 15:40:00 2017
-- Template Rev: 1.0
--
-- Title: FIFO Read State Machine
--
-- Description: FIFO to Ethernet MAC state machine. Needs to ensure minimum packet 
--              sizes are met for 10G comms, minimum of 64bytes. We add zeros to the 
--              end.
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
ENTITY eth_tx_fsm IS
   GENERIC (
      g_technology            : t_technology);
   PORT (
      -- Clocks & Resets
      axi_clk                 : IN STD_LOGIC;
      eth_tx_rst              : IN STD_LOGIC;
      eth_tx_clk              : IN STD_LOGIC;

      -- Inputs
      start_transmit          : IN STD_LOGIC;
      packet_type             : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      tlast                   : IN STD_LOGIC;
      tready                  : IN STD_LOGIC;
      
      -- Logic Output
      hdr_mux_sel             : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      tvalid                  : OUT STD_LOGIC;

      checksum_pop            : OUT STD_LOGIC;
      packet_buffer_read      : OUT STD_LOGIC;
      packet_buffer_pipe_read : OUT STD_LOGIC;
      pad_mux_sel             : OUT STD_LOGIC_VECTOR(1 DOWNTO 0));
END eth_tx_fsm;

-------------------------------------------------------------------------------
ARCHITECTURE behaviour of eth_tx_fsm is
   
  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   TYPE t_read_states IS (s_idle, s_precharge, s_read_buffer, s_add_pad, s_cleanout);

  ---------------------------------------------------------------------------
  -- SIGNAL DECLARATIONS  --
  ---------------------------------------------------------------------------

   SIGNAL fifo_pop               : STD_LOGIC;
   SIGNAL tvalid_ely             : STD_LOGIC;

   SIGNAL ip_type_retimed        : STD_LOGIC;
   SIGNAL udp_type_retimed       : STD_LOGIC;
   
   SIGNAL new_packet             : STD_LOGIC;
   SIGNAL read_state             : t_read_states;
   SIGNAL word_counter           : UNSIGNED(3 DOWNTO 0);
   SIGNAL udp_type               : STD_LOGIC;
   SIGNAL ip_type                : STD_LOGIC;
   SIGNAL fifo_empty             : STD_LOGIC;
   SIGNAL pad_mux_sel_ely        : STD_LOGIC_VECTOR(1 DOWNTO 0);

  ---------------------------------------------------------------------------
  -- COMPONENT DECLARATIONS  --
  ---------------------------------------------------------------------------
   
   
BEGIN


   checksum_pop <= fifo_pop;

---------------------------------------------------------------------------
-- Domain Crossing  --
---------------------------------------------------------------------------
-- Trick here is we use a small FIFO to store the pakcet type. We can just keep
-- running the redout FSM untile the FIFO is empty

packet_type_fifo: ENTITY common_lib.common_fifo_dc
                  GENERIC MAP (g_technology     => g_technology,
                               g_use_lut        => TRUE,
                               g_fifo_latency   => 1,
                               g_dat_w          => 2,
                               g_nof_words      => 16)         -- Length doesn't matter, just needs to be a couple long
                  PORT MAP (rst              => eth_tx_rst,
                            wr_clk           => axi_clk,
                            wr_dat           => packet_type,
                            wr_req           => start_transmit,
                            wr_ful           => OPEN,
                            wr_prog_ful      => OPEN,
                            wrusedw          => OPEN,
                            rd_clk           => eth_tx_clk,
                            rd_dat(0)        => ip_type,
                            rd_dat(1)        => udp_type,
                            rd_req           => fifo_pop,
                            rd_emp           => fifo_empty,
                            rd_prog_emp      => OPEN,
                            rdusedw          => OPEN,
                            rd_val           => OPEN);

---------------------------------------------------------------------------
-- Controller  --
---------------------------------------------------------------------------
-- Wait until packet transmit is requested. Start reading and stop if ready 
-- is dropped. When tlast comes out of FIFO then we are done

fsm: PROCESS(eth_tx_clk)
   BEGIN
      IF RISING_EDGE(eth_tx_clk) THEN
         IF eth_tx_rst = '1' THEN
            read_state     <= s_idle;
            word_counter <= (OTHERS => '0');
         ELSE
            IF read_state = s_read_buffer OR read_state = s_add_pad THEN
               IF word_counter(3) = '0' AND tready = '1' THEN
                  word_counter <= word_counter + 1;
               ELSE
                  word_counter <= word_counter;
               END IF;
            ELSE
               word_counter <= X"0";
            END IF;
            
            CASE read_state IS
               -------------------------------
               WHEN s_idle =>                                              -- Wait for packet to be buffered
                  IF fifo_empty = '0' THEN
                     read_state <= s_precharge;
                  ELSE
                     read_state <= read_state;
                  END IF;

               -------------------------------
               WHEN s_precharge =>                                         -- Charge Pipline
                  read_state <= s_read_buffer;

               -------------------------------
               WHEN s_read_buffer =>                                       -- Read the buffer until tlast appears
                  IF tlast = '1' AND tready = '1' THEN
                     IF word_counter(3) = '1' THEN
                        read_state <= s_cleanout;
                     ELSE
                        read_state <= s_add_pad;
                     END IF;
                  ELSE
                     read_state <= read_state;
                  END IF;
               -------------------------------
               WHEN s_add_pad =>                                           -- Add extra 0's after the last word (hold tlast)
                  IF tready = '1' THEN
                     IF word_counter(3) = '1' THEN
                        read_state <= s_cleanout;
                     END IF;
                  END IF;
               -------------------------------
               WHEN s_cleanout => 
                  IF tready = '1' THEN
                     read_state <= s_idle;
                  END IF;
            END CASE;
         END IF;
      END IF;
   END PROCESS;

   fifo_pop <= '1' WHEN read_state = s_precharge ELSE '0'; 

   packet_buffer_pipe_read <= tready WHEN read_state = s_read_buffer ELSE
                              '1' WHEN read_state = s_precharge ELSE
                              '0';

   packet_buffer_read <= tready and not(tlast) WHEN read_state = s_read_buffer ELSE       -- Don't read the FIFO again on last as it might be a new packet
                         '1' WHEN read_state = s_precharge ELSE
                         '0';

   pad_mux_sel_ely <= "01" WHEN word_counter(3) = '1' AND read_state = s_read_buffer ELSE            -- Allow true tlast and mask bits to proceed as we are over minimum
                      "11" WHEN word_counter(3) = '1' AND read_state = s_add_pad ELSE                -- Make data 0's and mask all 1's and tlast
                      "10" WHEN read_state = s_add_pad ELSE                                          -- Make data 0's and mask all 1's and not tlast
                      "00";                                                                          -- Block Tlast and set mask bits to all 1's

   tvalid_ely <= '1' when read_state = s_read_buffer OR read_state = s_add_pad else '0';

   hdr_mux_sel <= "01" WHEN word_counter = 3 AND ip_type = '1' ELSE
                  "10" WHEN word_counter = 5 AND udp_type = '1' ELSE
                  "00";
      
valid_pipe: ENTITY common_lib.common_pipeline
            GENERIC MAP (g_pipeline  => 1,
                         g_in_dat_w  => 1,
                         g_out_dat_w => 1)
            PORT MAP (clk          => eth_tx_clk,
                      rst          => '0',
                      in_en        => tready,
                      in_dat(0)    => tvalid_ely,
                      out_dat(0)   => tvalid);  

pad_mux_sel_pipe: ENTITY common_lib.common_pipeline
                  GENERIC MAP (g_pipeline  => 1,
                               g_in_dat_w  => 2,
                               g_out_dat_w => 2)
                  PORT MAP (clk           => eth_tx_clk,
                            rst           => '0',
                            in_en         => tready,
                            in_dat        => pad_mux_sel_ely,
                            out_dat       => pad_mux_sel);  

END behaviour;
-------------------------------------------------------------------------------