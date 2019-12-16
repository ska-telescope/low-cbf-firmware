-------------------------------------------------------------------------------
--
-- File Name: eth_tx.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Wed Aug 15 15:40:00 2017
-- Template Rev: 1.0
--
-- Title: Top Level of Ethernet Framer
--
-- Description: Top level file for implmentation the ethernet TX framer. Muxes
--              multiple lanes together
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
ENTITY eth_tx IS
   GENERIC (
      g_technology            : t_technology := c_tech_select_default;
      g_num_frame_inputs      : INTEGER := 16;
      g_max_packet_length     : INTEGER := 8192;
      g_lane_priority         : t_integer_arr(0 to 15) := (OTHERS => 3);
      g_valid_id              : INTEGER := 100);                                 -- 8 bit vlan

   PORT (
      -- Clocks & Resets
      eth_tx_clk              : IN STD_LOGIC;
      eth_rx_clk              : IN STD_LOGIC;
      axi_clk                 : IN STD_LOGIC;

      eth_tx_rst              : IN STD_LOGIC;
      axi_rst                 : IN STD_LOGIC;

      -- Addressing
      eth_address_ip          : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      eth_address_mac         : IN STD_LOGIC_VECTOR(47 DOWNTO 0);

      -- Pause Interface
      eth_pause_rx_enable     : OUT STD_LOGIC_VECTOR(8 downto 0);
      eth_pause_rx_req        : IN STD_LOGIC_VECTOR(8 downto 0);
      eth_pause_rx_ack        : OUT STD_LOGIC_VECTOR(8 downto 0);

      -- Ethernet Output
      eth_out_sosi            : OUT t_axi4_sosi;
      eth_out_siso            : IN t_axi4_siso;

      -- Framer Input
      framer_in_sosi          : IN t_axi4_sosi_arr(0 TO g_num_frame_inputs-1);
      framer_in_siso          : OUT t_axi4_siso_arr(0 TO g_num_frame_inputs-1));
END eth_tx;

-------------------------------------------------------------------------------
ARCHITECTURE behaviour of eth_tx is

  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   TYPE t_slv_76_arr      IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(75 DOWNTO 0);

  ---------------------------------------------------------------------------
  -- SIGNAL DECLARATIONS  --
  ---------------------------------------------------------------------------

   SIGNAL axi_rst_reg               : STD_LOGIC;
   SIGNAL eth_tx_rst_reg            : STD_LOGIC;
   SIGNAL eth_address_mac_reg       : STD_LOGIC_VECTOR(47 DOWNTO 0);
   SIGNAL eth_address_ip_reg        : STD_LOGIC_VECTOR(31 DOWNTO 0);

   -- Read Controller
   SIGNAL new_packet                : STD_LOGIC;
   SIGNAL start_transmit            : STD_LOGIC;
   SIGNAL packet_type               : STD_LOGIC_vector(1 DOWNTO 0);

   -- Lane Signals
   SIGNAL lane_read                 : STD_LOGIC_VECTOR(0 TO g_num_frame_inputs-1);
   SIGNAL lane_ready                : STD_LOGIC_VECTOR(0 TO g_num_frame_inputs-1);
   SIGNAL lane_ip                   : STD_LOGIC_VECTOR(0 TO g_num_frame_inputs-1);
   SIGNAL lane_udp                  : STD_LOGIC_VECTOR(0 TO g_num_frame_inputs-1);
   SIGNAL lane_tlast                : STD_LOGIC_VECTOR(0 TO g_num_frame_inputs-1);
   SIGNAL lane_short                : STD_LOGIC_VECTOR(0 TO g_num_frame_inputs-1);
   SIGNAL lane_data                 : t_slv_76_arr(0 TO g_num_frame_inputs-1);

   -- Lane Mux
   SIGNAL lane_mux_sel              : STD_LOGIC_VECTOR(ceil_log2(g_num_frame_inputs)-1 DOWNTO 0);
   SIGNAL lane_mux_input            : STD_LOGIC_VECTOR(76*g_num_frame_inputs-1 DOWNTO 0);
   SIGNAL selected_lane_data        : STD_LOGIC_VECTOR(75 DOWNTO 0);
   SIGNAL selected_lane_data_dly    : STD_LOGIC_VECTOR(75 DOWNTO 0);
   SIGNAL selected_lane_data_2dly   : STD_LOGIC_VECTOR(75 DOWNTO 0);
   SIGNAL selected_lane_data_3dly   : STD_LOGIC_VECTOR(75 DOWNTO 0);


   -- Meta Data
   SIGNAL meta_mux_input            : STD_LOGIC_VECTOR(364 DOWNTO 0);
   SIGNAL meta_mux_sel              : STD_LOGIC_VECTOR(2 DOWNTO 0);
   SIGNAL meta_mux_input_valid      : STD_LOGIC;
   SIGNAL meta_mux_output           : STD_LOGIC_VECTOR(72 DOWNTO 0);
   SIGNAL meta_mux_valid            : STD_LOGIC;

   -- Packet Buffer
   SIGNAL packet_buffer_output      : STD_LOGIC_VECTOR(72 DOWNTO 0);
   SIGNAL packet_buffer_read        : STD_LOGIC;
   SIGNAL packet_buffer_pipe_read   : STD_LOGIC;

   -- Checksum Mux
   SIGNAL hdr_mux_sel               : STD_LOGIC_VECTOR(1 DOWNTO 0);
   SIGNAL udp_checksum              : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL ip_checksum               : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL checksum_mux_input        : STD_LOGIC_VECTOR(218 DOWNTO 0);
   SIGNAL checksum_mux_output       : STD_LOGIC_VECTOR(72 DOWNTO 0);
   SIGNAL checksum_mux_pipe         : STD_LOGIC_VECTOR(72 DOWNTO 0);

   -- Pad Mux
   SIGNAL pad_mux_input             : STD_LOGIC_VECTOR(291 DOWNTO 0);
   SIGNAL pad_mux_output            : STD_LOGIC_VECTOR(72 DOWNTO 0);
   SIGNAL pad_mux_sel               : STD_LOGIC_VECTOR(1 DOWNTO 0);

   SIGNAL checksum_pop              : STD_LOGIC;

  ---------------------------------------------------------------------------
  -- COMPONENT DECLARATIONS  --
  ---------------------------------------------------------------------------


BEGIN

input_retime: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         axi_rst_reg <= axi_rst;

         eth_address_mac_reg <= eth_address_mac;
         eth_address_ip_reg <= eth_address_ip;
      END IF;
   END PROCESS;

input_retime2: PROCESS(eth_tx_clk)
   BEGIN
      IF RISING_EDGE(eth_tx_clk) THEN
         eth_tx_rst_reg <= eth_tx_rst;
      END IF;
   END PROCESS;

---------------------------------------------------------------------------
-- Read Controller  --
---------------------------------------------------------------------------

read_controller: ENTITY work.eth_tx_lane_fsm
                 GENERIC MAP (g_num_frame_inputs      => g_num_frame_inputs,
                              g_lane_priority         => g_lane_priority)
                 PORT MAP (axi_clk              => axi_clk,
                           eth_rx_clk           => eth_rx_clk,
                           axi_rst              => axi_rst_reg,
                           eth_pause_rx_enable  => eth_pause_rx_enable,
                           eth_pause_rx_req     => eth_pause_rx_req,
                           eth_pause_rx_ack     => eth_pause_rx_ack,
                           lane_ready           => lane_ready,
                           lane_ip              => lane_ip,
                           lane_udp             => lane_udp,
                           lane_tlast           => lane_tlast,
                           lane_short           => lane_short,
                           lane_mux_sel         => lane_mux_sel,
                           meta_mux_sel         => meta_mux_sel,
                           lane_read            => lane_read,
                           meta_data_valid      => meta_mux_input_valid,
                           new_packet           => new_packet,
                           start_transmit       => start_transmit,
                           packet_type          => packet_type);

---------------------------------------------------------------------------
-- Incoming Framer  --
---------------------------------------------------------------------------
-- Each input lane gets its own FIFO and small controller to ensure that the
-- data can be absorbed as per AXI streaming specs.

input_gen: FOR i IN 0 TO g_num_frame_inputs-1 GENERATE
   lane_in: ENTITY work.eth_tx_lane
            GENERIC MAP (g_technology     => g_technology,
                         g_lane_priority  => g_lane_priority(i))
            PORT MAP (clk              => axi_clk,
                      rst              => axi_rst_reg,
                      fifo_read        => lane_read(i),
                      fifo_data        => lane_data(i),
                      fifo_ready       => lane_ready(i),
                      is_ip            => lane_ip(i),
                      is_udp           => lane_udp(i),
                      framer_in_sosi   => framer_in_sosi(i),
                      framer_in_siso   => framer_in_siso(i));

   lane_tlast(i) <= lane_data(i)(72);
   lane_short(i) <= '0' when lane_data(i)(71 DOWNTO 68) = X"0" ELSE '1';

END GENERATE;

---------------------------------------------------------------------------
-- Lane MUX  --
---------------------------------------------------------------------------
-- Mux the correct lane onto the ouput channel

lane_mux_input_gen: FOR i IN 0 TO g_num_frame_inputs-1 GENERATE
   lane_mux_input(75+76*i downto 0+76*i) <= lane_data(i);
END GENERATE;

   -- Select correct lane
lane_mux: ENTITY common_lib.common_multiplexer
          GENERIC MAP (g_pipeline_in   => 1,
                       g_pipeline_out  => 1,
                       g_nof_in        => g_num_frame_inputs,
                       g_dat_w         => 76)
          PORT MAP (clk       => axi_clk,
                    rst       => '0',
                    in_sel    => lane_mux_sel,
                    in_dat    => lane_mux_input,
                    in_val    => '1',
                    out_dat   => selected_lane_data,
                    out_val   => open);

   -- Pipeline for FSM latency
lane_pipe: ENTITY common_lib.common_pipeline
           GENERIC MAP (g_pipeline  => 1,
                        g_in_dat_w  => 76,
                        g_out_dat_w => 76)
           PORT MAP (clk      => axi_clk,
                     rst      => '0',
                     in_dat   => selected_lane_data,
                     out_dat  => selected_lane_data_dly);

---------------------------------------------------------------------------
-- Header Data MUX  --
---------------------------------------------------------------------------
-- Need to MUX in MAC, IP and VLAN header at correct places. Uses combination
-- of delays and MUXes to achieve operation.
--
-- T0 select S0 (input 0)
-- T1 select S1
-- T2 select S2
-- T3 for non IP traffic select S2, for IP traffic S3
-- T4 for non IP traffic select S2, for IP traffic S4
-- T5-> Tn select S2

lane_data_reg: ENTITY common_lib.common_pipeline
               GENERIC MAP (g_pipeline  => 1,
                            g_in_dat_w  => 76,
                            g_out_dat_w => 76)
               PORT MAP (clk      => axi_clk,
                         rst      => '0',
                         in_en    => meta_mux_input_valid,
                         in_dat   => selected_lane_data_dly,
                         out_dat  => selected_lane_data_2dly);

lane_data_2reg: ENTITY common_lib.common_pipeline
                GENERIC MAP (g_pipeline  => 1,
                             g_in_dat_w  => 76,
                             g_out_dat_w => 76)
                PORT MAP (clk      => axi_clk,
                          rst      => '0',
                          in_en    => meta_mux_input_valid,
                          in_dat   => selected_lane_data_2dly,
                          out_dat  => selected_lane_data_3dly);

   -- S0
   meta_mux_input(0*73+47 downto 0*73+0)  <= selected_lane_data_dly(47 downto 0);
   meta_mux_input(0*73+55 downto 0*73+48) <= eth_address_mac_reg(47 downto 40);
   meta_mux_input(0*73+63 downto 0*73+56) <= eth_address_mac_reg(39 downto 32);
   meta_mux_input(0*73+72 downto 0*73+64) <= selected_lane_data_dly(72 downto 64);

   -- S1
   meta_mux_input(1*73+7 downto  1*73+0)  <= eth_address_mac_reg(31 downto 24);
   meta_mux_input(1*73+15 downto 1*73+8)  <= eth_address_mac_reg(23 downto 16);
   meta_mux_input(1*73+23 downto 1*73+16) <= eth_address_mac_reg(15 downto 8);
   meta_mux_input(1*73+31 downto 1*73+24) <= eth_address_mac_reg(7 downto 0);
   meta_mux_input(1*73+47 downto 1*73+32) <= X"0081";                                -- 802.1Q Tag
   meta_mux_input(1*73+51 downto 1*73+48) <= (others => '0');                        -- Upper VLAN ID
   meta_mux_input(1*73+52)                <= '0';                                    -- DEI
   meta_mux_input(1*73+55 downto 1*73+53) <= selected_lane_data_dly(75 downto 73) ;  -- PCP

   meta_mux_input(1*73+63 downto 1*73+56) <= STD_LOGIC_VECTOR(TO_UNSIGNED(g_valid_id, 8));

   meta_mux_input(1*73+67 downto 1*73+64) <= selected_lane_data_dly(67 downto 64);
   meta_mux_input(1*73+71 downto 1*73+68) <= X"F";                                   -- Byte enable for VLAN header
   meta_mux_input(1*73+72)                <= selected_lane_data_dly(72);             -- TLast

   -- S2 -> End for Non-IP Traffic
   meta_mux_input(2*73+31 downto 2*73+0)  <= selected_lane_data_2dly(63 downto 32);
   meta_mux_input(2*73+63 downto 2*73+32) <= selected_lane_data_dly(31 downto 0);
   meta_mux_input(2*73+67 downto 2*73+64) <= selected_lane_data_2dly(71 downto 68);
   meta_mux_input(2*73+71 downto 2*73+68) <= selected_lane_data_dly(67 downto 64);

   -- TLAST needs to be asserted on last bit of data. As we extended the packet by 4
   -- bytes we need to detect if an extra clock is needed based on the tkeep bits
   meta_mux_input(2*73+72)                <= selected_lane_data_dly(72) when selected_lane_data_dly(71 downto 68) = X"0" AND selected_lane_data_dly(67 downto 64) /= X"0" else
                                             selected_lane_data_2dly(72);

   -- S3 for IP Traffic
   meta_mux_input(3*73+31 downto 3*73+0)  <= selected_lane_data_2dly(63 downto 32);
   meta_mux_input(3*73+47 downto 3*73+32) <= selected_lane_data_dly(15 downto 0);
   meta_mux_input(3*73+55 downto 3*73+48) <= eth_address_ip_reg(31 downto 24);
   meta_mux_input(3*73+63 downto 3*73+56) <= eth_address_ip_reg(23 downto 16);
   meta_mux_input(3*73+67 downto 3*73+64) <= selected_lane_data_2dly(71 downto 68);
   meta_mux_input(3*73+71 downto 3*73+68) <= selected_lane_data_dly(67 downto 64);
   meta_mux_input(3*73+72)                <= selected_lane_data_dly(72);             -- TLast

   -- S4 for IP Traffic
   meta_mux_input(4*73+7  downto 4*73+0)  <= eth_address_ip_reg(15 downto 8);
   meta_mux_input(4*73+15 downto 4*73+8)  <= eth_address_ip_reg(7 downto 0);
   meta_mux_input(4*73+31 downto 4*73+16) <= selected_lane_data_2dly(63 downto 48);
   meta_mux_input(4*73+63 downto 4*73+32) <= selected_lane_data_dly(31 downto 0);
   meta_mux_input(4*73+67 downto 4*73+64) <= selected_lane_data_2dly(71 downto 68);
   meta_mux_input(4*73+71 downto 4*73+68) <= selected_lane_data_dly(67 downto 64);
   meta_mux_input(4*73+72)                <= selected_lane_data_dly(72);             -- TLast

hdr_data_mux: ENTITY common_lib.common_multiplexer
              GENERIC MAP (g_pipeline_in   => 0,
                           g_pipeline_out  => 1,
                           g_nof_in        => 5,
                           g_dat_w         => 73)
              PORT MAP (clk       => axi_clk,
                        rst       => '0',
                        in_sel    => meta_mux_sel,
                        in_dat    => meta_mux_input,
                        in_val    => meta_mux_input_valid,
                        out_dat   => meta_mux_output,
                        out_val   => meta_mux_valid);

---------------------------------------------------------------------------
-- Data Buffer  --
---------------------------------------------------------------------------
-- Don't need a full double buffer as the output rate is much higehr than
-- input rate. But the whole packet is buffered before we start so we need
-- at least max MTU space. There is some latency associated with startup so
-- we need an extra bit (20%) to buffer packets that arrive at the same time
-- as a big packet. We assuem that TX has started soon after the first packet
-- is stuffed into buffer


packet_buffer: ENTITY common_lib.common_fifo_dc
               GENERIC MAP (g_technology     => g_technology,
                            g_fifo_latency   => 1,
                            g_dat_w          => 73,
                            g_nof_words      => (12*(g_max_packet_length/8)/10)+1)
               PORT MAP (rst           => axi_rst_reg,
                         wr_clk        => axi_clk,
                         wr_dat        => meta_mux_output,
                         wr_req        => meta_mux_valid,
                         wr_ful        => OPEN,
                         wr_prog_ful   => OPEN,
                         wrusedw       => OPEN,
                         rd_clk        => eth_tx_clk,
                         rd_dat        => packet_buffer_output,
                         rd_req        => packet_buffer_read,
                         rd_emp        => OPEN,
                         rd_prog_emp   => OPEN,
                         rdusedw       => OPEN,
                         rd_val        => OPEN);

---------------------------------------------------------------------------
-- Checksum Calculators  --
---------------------------------------------------------------------------
-- Checksum calculators. Checksums are always generated even if they are not
-- needed. Results are stored in small FIFOs as the packet buffer can contain
-- multiple packets

udp_checksum_gen: ENTITY work.eth_tx_udp_checksum
                  GENERIC MAP(g_technology   => g_technology)
                  PORT MAP (rst           => axi_rst_reg,
                            axi_clk       => axi_clk,
                            eth_tx_clk    => eth_tx_clk,
                            new_packet    => new_packet,
                            tdata         => meta_mux_output(63 DOWNTO 0),
                            tkeep         => meta_mux_output(71 DOWNTO 64),
                            tlast         => meta_mux_output(72),
                            tvalid        => meta_mux_valid,
                            checksum_pop  => checksum_pop,
                            checksum      => udp_checksum);

ip_checksum_gen: ENTITY work.eth_tx_ip_checksum
                 GENERIC MAP(g_technology    => g_technology)
                 PORT MAP (rst            => axi_rst_reg,
                           axi_clk        => axi_clk,
                           eth_tx_clk     => eth_tx_clk,
                           new_packet     => new_packet,
                           tdata          => meta_mux_output(63 DOWNTO 0),
                           tkeep          => meta_mux_output(71 DOWNTO 64),
                           tlast          => meta_mux_output(72),
                           tvalid         => meta_mux_valid,
                           checksum_pop   => checksum_pop,
                           checksum       => ip_checksum);

---------------------------------------------------------------------------
-- Checkum Mux  --
---------------------------------------------------------------------------
-- Mux that controls the addition of UDP/IP checksum to the data if needed


   -- Passthrough
   checksum_mux_input(0*73+72 DOWNTO 0*73+0)  <= packet_buffer_output;

   -- Inclusion of IP checksum
   checksum_mux_input(1*73+31 DOWNTO 1*73+0)  <= packet_buffer_output(31 DOWNTO 0);
   checksum_mux_input(1*73+39 DOWNTO 1*73+32) <= ip_checksum(15 DOWNTO 8);
   checksum_mux_input(1*73+47 DOWNTO 1*73+40) <= ip_checksum(7 DOWNTO 0);
   checksum_mux_input(1*73+72 DOWNTO 1*73+48) <= packet_buffer_output(72 DOWNTO 48);

   -- Inclusion of UDP checksum
   checksum_mux_input(2*73+31 DOWNTO 2*73+0) <= packet_buffer_output(31 DOWNTO 0);
   checksum_mux_input(2*73+39 DOWNTO 2*73+32) <= udp_checksum(15 DOWNTO 8);
   checksum_mux_input(2*73+47 DOWNTO 2*73+40) <= udp_checksum(7 DOWNTO 0);
   checksum_mux_input(2*73+72 DOWNTO 2*73+48) <= packet_buffer_output(72 DOWNTO 48);

checksum_data_mux: ENTITY common_lib.common_multiplexer
                   GENERIC MAP (g_pipeline_in   => 0,
                                g_pipeline_out  => 0,
                                g_nof_in        => 3,
                                g_dat_w         => 73)
                   PORT MAP (clk       => eth_tx_clk,
                             rst       => '0',
                             in_val    => '1',
                             in_sel    => hdr_mux_sel,
                             in_dat    => checksum_mux_input,
                             out_dat   => checksum_mux_output);

checksum_data_pipe: ENTITY common_lib.common_pipeline
                    GENERIC MAP (g_pipeline  => 1,
                                 g_in_dat_w  => 73,
                                 g_out_dat_w => 73)
                    PORT MAP (clk                   => eth_tx_clk,
                              rst                   => '0',
                              in_en                 => packet_buffer_pipe_read,
                              in_dat                => checksum_mux_output,
                              out_dat               => checksum_mux_pipe);


   -- Passthrough with all enables and no tlast (T<7)
   pad_mux_input(0*73+63 DOWNTO 0*73+0) <= checksum_mux_pipe(63 DOWNTO 0);
   pad_mux_input(0*73+71 DOWNTO 0*73+64) <= (OTHERS => '1');
   pad_mux_input(0*73+72) <= '0';

   -- Passthrough (T >= 8)
   pad_mux_input(1*73+72 DOWNTO 1*73+0) <= checksum_mux_pipe;

   -- Pad 0's in data and all mask bits (T <7 if tlast occurs in real data)
   pad_mux_input(2*73+63 DOWNTO 2*73+0) <= (OTHERS => '0');
   pad_mux_input(2*73+71 DOWNTO 2*73+64) <= (OTHERS => '1');
   pad_mux_input(2*73+72) <= '0';

   -- Pad 0's in data and all mask bits (T <7 if tlast occurs in real data)
   pad_mux_input(3*73+63 DOWNTO 3*73+0) <= (OTHERS => '0');
   pad_mux_input(3*73+71 DOWNTO 3*73+64) <= (OTHERS => '1');
   pad_mux_input(3*73+72) <= '1';

pad_mux: ENTITY common_lib.common_multiplexer
                   GENERIC MAP (g_pipeline_in   => 0,
                                g_pipeline_out  => 0,
                                g_nof_in        => 4,
                                g_dat_w         => 73)
                   PORT MAP (clk                   => eth_tx_clk,
                             rst                   => '0',
                             in_val                => '1',
                             in_sel                => pad_mux_sel,
                             in_dat                => pad_mux_input,
                             out_dat(63 DOWNTO 0)  => eth_out_sosi.tdata(63 downto 0),
                             out_dat(71 DOWNTO 64) => eth_out_sosi.tkeep(7 downto 0),
                             out_dat(72)           => eth_out_sosi.tlast);

---------------------------------------------------------------------------
-- Write Controller  --
---------------------------------------------------------------------------
-- Controls the checksum MUX and the reading of packet buffer

framer_tx: ENTITY work.eth_tx_fsm
           GENERIC MAP (g_technology         => g_technology)
           PORT MAP (axi_clk                 => axi_clk,
                     eth_tx_rst              => eth_tx_rst_reg,
                     eth_tx_clk              => eth_tx_clk,
                     start_transmit          => start_transmit,
                     checksum_pop            => checksum_pop,
                     packet_type             => packet_type,
                     tlast                   => checksum_mux_output(72),
                     tready                  => eth_out_siso.tready,
                     tvalid                  => eth_out_sosi.tvalid,
                     hdr_mux_sel             => hdr_mux_sel,
                     packet_buffer_read      => packet_buffer_read,
                     packet_buffer_pipe_read => packet_buffer_pipe_read,
                     pad_mux_sel             => pad_mux_sel);

END behaviour;
-------------------------------------------------------------------------------
