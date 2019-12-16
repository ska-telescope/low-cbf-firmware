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
USE axi4_lib.axi4_lite_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE work.dhcp_reg_pkg.ALL;

-------------------------------------------------------------------------------
ENTITY dhcp_protocol IS
   GENERIC (
      g_technology                  : t_technology := c_tech_select_default;
      g_axi_clk_freq                : INTEGER := 156250;                   -- Clock rate in KHz
      g_dhcpdiscover_short_interval : INTEGER := 2000;                     -- Initial time between DHCPDISCOVER requests  (in mS)
      g_dhcpdiscover_long_interval  : INTEGER := 30000;                    -- After failover use this time between DHCPDISCOVER requests  (in mS)
      g_dhcpdiscover_timeout_count  : INTEGER := 15;                       -- After this many DHCPDISCOVER failover
      g_startup_delay               : INTEGER := 2000;                     -- Startup delay (after reset) before transmitting (in mS)
      g_acknowledge_timeout         : INTEGER := 500;                      -- 500mS timeout waiting for ack or offer (in mS)
      g_renew_interval              : INTEGER := 60000);                   -- 30s between renew requests

   PORT (
      -- Clocks & Resets
      axi_clk                 : IN STD_LOGIC;

      axi_rst                 : IN STD_LOGIC;
      mm_rst                  : in std_logic; -- for logic connected to s_axi_mosi, s_axi_miso.

      -- Settings In
      ip_address_default      : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      mac_address             : IN STD_LOGIC_VECTOR(47 DOWNTO 0);

      serial_number           : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      dhcp_start              : IN STD_LOGIC;

      -- Settings Out
      ip_address              : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      ip_event                : OUT STD_LOGIC;

      --AXI Interface
      s_axi_mosi              : IN t_axi4_lite_mosi;
      s_axi_miso              : OUT t_axi4_lite_miso;

      -- Ethernet Input
      frame_in_sosi           : IN t_axi4_sosi;
      frame_in_siso           : OUT t_axi4_siso;

      -- Ethernet Output
      frame_out_sosi          : OUT t_axi4_sosi;
      frame_out_siso          : IN t_axi4_siso);
END dhcp_protocol;

-------------------------------------------------------------------------------
ARCHITECTURE behaviour of dhcp_protocol is

  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------



  ---------------------------------------------------------------------------
  -- SIGNAL DECLARATIONS  --
  ---------------------------------------------------------------------------

   -- Register Signals
   SIGNAL dhcp_reg_fields_rw        : t_dhcp_rw;
   SIGNAL dhcp_reg_fields_ro        : t_dhcp_ro;


   SIGNAL i_ip_address              : STD_LOGIC_VECTOR(31 DOWNTO 0);

   SIGNAL rx_ok                     : STD_LOGIC;
   SIGNAL rx_dhcp_op                : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL rx_xid                    : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL rx_dhcp_ip                : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL rx_dhcp_mac               : STD_LOGIC_VECTOR(47 DOWNTO 0);
   SIGNAL rx_lease_time             : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL rx_my_ip                  : STD_LOGIC_VECTOR(31 DOWNTO 0);

   SIGNAL tx_pending_ip             : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL tx_dhcp_mac               : STD_LOGIC_VECTOR(47 DOWNTO 0);
   SIGNAL tx_dhcp_ip                : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL tx_xid                    : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL tx_dhcp_op                : STD_LOGIC_VECTOR(2 DOWNTO 0);
   SIGNAL tx_dhcp_gen               : STD_LOGIC;
   SIGNAL tx_dhcp_complete          : STD_LOGIC;


  ---------------------------------------------------------------------------
  -- COMPONENT DECLARATIONS  --
  ---------------------------------------------------------------------------


BEGIN


   ip_address <= i_ip_address WHEN dhcp_reg_fields_rw.ip_override_enable = '0' ELSE
                 dhcp_reg_fields_rw.ip_override;

   ip_event <= dhcp_reg_fields_ro.status_dhcp_configured;

---------------------------------------------------------------------------
-- Registers --
---------------------------------------------------------------------------
-- Top level register file

axi_regs: ENTITY work.dhcp_reg
          PORT MAP (mm_clk                => axi_clk,
                    mm_rst                => mm_rst,
                    sla_in                => s_axi_mosi,
                    sla_out               => s_axi_miso,
                    dhcp_fields_rw        => dhcp_reg_fields_rw,
                    dhcp_fields_ro        => dhcp_reg_fields_ro);

dhcp_reg_fields_ro.dhcp_server <= tx_dhcp_ip;
dhcp_reg_fields_ro.local_ip <= i_ip_address;

---------------------------------------------------------------------------
-- Depacketiser --
---------------------------------------------------------------------------

dhcp_depacketiser_1: ENTITY work.dhcp_depacketiser
                     GENERIC MAP (g_technology     => g_technology)
                     PORT MAP (axi_clk          => axi_clk,
                               axi_rst          => axi_rst,
                               rx_ok            => rx_ok,
                               dhcp_op          => rx_dhcp_op,
                               xid              => rx_xid,
                               dhcp_ip          => rx_dhcp_ip,
                               dhcp_mac         => rx_dhcp_mac,
                               lease_time       => rx_lease_time,
                               my_ip            => rx_my_ip,
                               frame_in_sosi    => frame_in_sosi,
                               frame_in_siso    => frame_in_siso);

---------------------------------------------------------------------------
-- Controller --
---------------------------------------------------------------------------

dhcp_transaction_fsm_1: ENTITY work.dhcp_transaction_fsm
                        GENERIC MAP (g_axi_clk_freq                  => g_axi_clk_freq,
                                     g_dhcpdiscover_short_interval   => g_dhcpdiscover_short_interval,
                                     g_dhcpdiscover_long_interval    => g_dhcpdiscover_long_interval,
                                     g_dhcpdiscover_timeout_count    => g_dhcpdiscover_timeout_count,
                                     g_startup_delay                 => g_startup_delay,
                                     g_acknowledge_timeout           => g_acknowledge_timeout,
                                     g_renew_interval                => g_renew_interval)
                        PORT MAP (axi_clk             => axi_clk,
                                  axi_rst             => axi_rst,
                                  ip_address_default  => ip_address_default,
                                  ip_address          => i_ip_address,
                                  mac_address         => mac_address,
                                  dhcp_start          => dhcp_start,
                                  lease_time          => dhcp_reg_fields_ro.lease_time,
                                  dhcp_success        => dhcp_reg_fields_ro.status_dhcp_configured,
                                  ip_failover         => dhcp_reg_fields_ro.status_ip_failover,
                                  rx_ok               => rx_ok,
                                  rx_dhcp_op          => rx_dhcp_op,
                                  rx_xid              => rx_xid,
                                  rx_dhcp_ip          => rx_dhcp_ip,
                                  rx_dhcp_mac         => rx_dhcp_mac,
                                  rx_lease_time       => rx_lease_time,
                                  rx_my_ip            => rx_my_ip,
                                  tx_pending_ip       => tx_pending_ip,
                                  tx_dhcp_mac         => tx_dhcp_mac,
                                  tx_dhcp_ip          => tx_dhcp_ip,
                                  tx_xid              => tx_xid,
                                  tx_dhcp_op          => tx_dhcp_op,
                                  tx_dhcp_gen         => tx_dhcp_gen,
                                  tx_dhcp_complete    => tx_dhcp_complete);


---------------------------------------------------------------------------
-- Packetiser --
---------------------------------------------------------------------------

dhcp_packetiser_1: ENTITY work.dhcp_packetiser
                   PORT MAP (axi_clk         => axi_clk,
                             axi_rst         => axi_rst,
                             serial_number   => serial_number,
                             ip_address      => i_ip_address,
                             mac_address     => mac_address,
                             pending_ip      => tx_pending_ip,
                             dhcp_mac        => tx_dhcp_mac,
                             dhcp_ip         => tx_dhcp_ip,
                             dhcp_xid        => tx_xid,
                             dhcp_op         => tx_dhcp_op,
                             dhcp_gen        => tx_dhcp_gen,
                             dhcp_complete   => tx_dhcp_complete,
                             frame_out_sosi  => frame_out_sosi,
                             frame_out_siso  => frame_out_siso);



END behaviour;
-------------------------------------------------------------------------------