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
-- File Name: subscription_top.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Monday Sept 11 15:40:00 2017
-- Template Rev: 1.0
--
-- Title: Top Level of Gemini Subscription Module
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

LIBRARY IEEE, common_lib, axi4_lib, technology_lib, gemini_subscription_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE gemini_subscription_lib.gemini_subscription_reg_pkg.ALL;

-------------------------------------------------------------------------------
ENTITY subscription_protocol IS
   GENERIC (
      g_technology            : t_technology := c_tech_select_default;
      g_num_clients           : INTEGER := 4);

   PORT (
      -- Clocks & Resets
      axi_clk                 : IN STD_LOGIC;
      axi_rst                 : IN STD_LOGIC;
      mm_rst                  : in std_logic;
      -- Time
      time_in                 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);

      -- Events In
      event_in                : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

      --AXI Interface
      s_axi_mosi              : IN t_axi4_lite_mosi;
      s_axi_miso              : OUT t_axi4_lite_miso;

      -- Framer Output
      stream_out_sosi         : OUT t_axi4_sosi;
      stream_out_siso         : IN t_axi4_siso);
END subscription_protocol;

-------------------------------------------------------------------------------
ARCHITECTURE behaviour of subscription_protocol is

   ---------------------------------------------------------------------------
   -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
   ---------------------------------------------------------------------------



   ---------------------------------------------------------------------------
   -- SIGNAL DECLARATIONS  --
   ---------------------------------------------------------------------------

   -- Register Signals
   SIGNAL client_reg_fields_rw      : t_client_rw;
   SIGNAL client_reg_fields_ro      : t_client_ro;
   SIGNAL broadcast_reg_fields_rw   : t_broadcast_rw;

   -- Clients
   SIGNAL client_framer_sosi        : t_axi4_sosi_arr(0 TO g_num_clients);
   SIGNAL client_framer_siso        : t_axi4_siso_arr(0 TO g_num_clients);

   -- Client Mux
   SIGNAL client_mux_input          : STD_LOGIC_VECTOR(((g_num_clients+1) * 73) -1 DOWNTO 0);
   SIGNAL client_mux_sel            : STD_LOGIC_VECTOR(ceil_log2(g_num_clients+1)-1 DOWNTO 0);
   SIGNAL client_pipe_enable        : STD_LOGIC;
   SIGNAL selected_client_data      : STD_LOGIC_VECTOR(72 DOWNTO 0);
   SIGNAL selected_client_data_pipe : STD_LOGIC_VECTOR(72 DOWNTO 0);

   SIGNAL client_valid              : STD_LOGIC_VECTOR(g_num_clients DOWNTO 0);
   SIGNAl client_tready             : STD_LOGIC_VECTOR(g_num_clients DOWNTO 0);
BEGIN





---------------------------------------------------------------------------
-- Register File  --
---------------------------------------------------------------------------
-- Top level register file

axi_regs: ENTITY work.gemini_subscription_reg
          PORT MAP (mm_clk                => axi_clk,
                    mm_rst                => mm_rst,
                    sla_in                => s_axi_mosi,
                    sla_out               => s_axi_miso,
                    client_fields_rw      => client_reg_fields_rw,
                    client_fields_ro      => client_reg_fields_ro,
                    broadcast_fields_rw   => broadcast_reg_fields_rw);

---------------------------------------------------------------------------
-- Clients --
---------------------------------------------------------------------------

clients: FOR i IN 0 TO g_num_clients-1 GENERATE
   clients_1: ENTITY work.client
              GENERIC MAP (g_technology         => g_technology)
              PORT MAP (axi_clk                 => axi_clk,
                        axi_rst                 => axi_rst,
                        time_in                 => time_in,
                        event_in                => event_in,
                        event_mask              => client_reg_fields_rw.event_mask(i),
                        acknowledge             => client_reg_fields_rw.control_acknowledge(i),
                        dest_mac(31 DOWNTO 0)   => client_reg_fields_rw.destination_mac_lower(i),
                        dest_mac(47 DOWNTO 32)  => client_reg_fields_rw.destination_mac_upper(i),
                        dest_ip                 => client_reg_fields_rw.destination_ip(i),
                        dest_port               => client_reg_fields_rw.destination_port(i),
                        delivery_int            => client_reg_fields_rw.delivery_interval(i),
                        event_top               => client_reg_fields_ro.event(i),
                        event_overflow          => client_reg_fields_ro.status_event_overflow(i),
                        stream_out_sosi         => client_framer_sosi(i),
                        stream_out_siso         => client_framer_siso(i));
END GENERATE;

---------------------------------------------------------------------------
-- Broadcast Client --
---------------------------------------------------------------------------
-- Handles the critical default broadcast events

clients_2: ENTITY work.client
           GENERIC MAP (g_technology   => g_technology)
           PORT MAP (axi_clk           => axi_clk,
                     axi_rst           => axi_rst,
                     time_in           => time_in,
                     event_in          => event_in,
                     event_mask        => X"00000001",
                     acknowledge       => broadcast_reg_fields_rw.control_acknowledge,
                     dest_mac          => X"FFFFFFFFFFFF",
                     dest_ip           => X"FFFFFFFF",
                     dest_port         => X"7531",
                     delivery_int      => "00011111010000",       -- 2000mS
                     event_top         => open,
                     event_overflow    => open,
                     stream_out_sosi   => client_framer_sosi(g_num_clients),
                     stream_out_siso   => client_framer_siso(g_num_clients));

---------------------------------------------------------------------------
-- Output Mux --
---------------------------------------------------------------------------


client_mux_input_gen: FOR i IN 0 TO g_num_clients GENERATE
   client_mux_input(63+73*i downto 0+73*i) <= client_framer_sosi(i).tdata(63 DOWNTO 0);
   client_mux_input(71+73*i downto 64+73*i) <= client_framer_sosi(i).tkeep(7 DOWNTO 0);
   client_mux_input(72+73*i) <= client_framer_sosi(i).tlast;
END GENERATE;

   -- Select client
client_mux: ENTITY common_lib.common_multiplexer
            GENERIC MAP (g_pipeline_in   => 0,
                         g_pipeline_out  => 0,
                         g_nof_in        => g_num_clients+1,
                         g_dat_w         => 73)
            PORT MAP (clk       => axi_clk,
                      rst       => '0',
                      in_val    => '1',
                      in_sel    => client_mux_sel,
                      in_dat    => client_mux_input,
                      out_dat   => selected_client_data,
                      out_val   => open);


client_mux_pipe: ENTITY common_lib.common_pipeline
                 GENERIC MAP (g_pipeline  => 1,
                              g_in_dat_w  => 73,
                              g_out_dat_w => 73)
                 PORT MAP (clk                   => axi_clk,
                           rst                   => '0',
                           in_en                 => client_pipe_enable,
                           in_dat                => selected_client_data,
                           out_dat               => selected_client_data_pipe);


   stream_out_sosi.tdata(63 downto 0) <= selected_client_data_pipe(63 DOWNTO 0);
   stream_out_sosi.tkeep(7 downto 0) <= selected_client_data_pipe(71 DOWNTO 64);
   stream_out_sosi.tlast <= selected_client_data_pipe(72);

---------------------------------------------------------------------------
-- Control State Machine --
---------------------------------------------------------------------------

client_valid_collate: FOR i IN 0 TO g_num_clients GENERATE
   client_valid(i) <= client_framer_sosi(i).tvalid;
END GENERATE;

service_fsm_1: ENTITY work.service_fsm
               GENERIC MAP (g_num_clients    => g_num_clients+1)
               PORT MAP (axi_clk             => axi_clk,
                         axi_rst             => axi_rst,
                         client_tvalid       => client_valid,
                         client_tready       => client_tready,
                         client_tlast        => selected_client_data_pipe(72),
                         client_mux          => client_mux_sel,
                         client_pipe_enable  => client_pipe_enable,
                         tvalid              => stream_out_sosi.tvalid,
                         tready              => stream_out_siso.tready);

client_tready_amp: FOR i IN 0 TO g_num_clients GENERATE
   client_framer_siso(i).tready  <= client_tready(i);
END GENERATE;


END ARCHITECTURE;