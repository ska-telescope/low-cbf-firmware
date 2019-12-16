-------------------------------------------------------------------------------
--
-- File Name: dhcp_transaction_fsm.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Wed Aug 15 15:40:00 2017
-- Template Rev: 1.0
--
-- Title: DHCP Client Transaction State Machine
--
-- Description: Controls the DHCP negoiation & renewal process
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

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;

-------------------------------------------------------------------------------
ENTITY dhcp_transaction_fsm IS
   GENERIC (
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

      dhcp_start              : IN STD_LOGIC;
      ip_address_default      : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      ip_address              : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      mac_address             : IN STD_LOGIC_VECTOR(47 DOWNTO 0);

      -- Status
      lease_time              : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      dhcp_success            : OUT STD_LOGIC;
      ip_failover             : OUT STD_LOGIC;

      -- RX Packet Fields
      rx_ok                   : IN STD_LOGIC;                              -- RX packet decode complete
      rx_dhcp_op              : IN STD_LOGIC_VECTOR(7 DOWNTO 0);           -- RX packet type
      rx_xid                  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);          -- XID field from packet
      rx_dhcp_ip              : IN STD_LOGIC_VECTOR(31 DOWNTO 0);          -- IP of DHCP server
      rx_dhcp_mac             : IN STD_LOGIC_VECTOR(47 DOWNTO 0);          -- MAC of DHCP server
      rx_lease_time           : IN STD_LOGIC_VECTOR(31 DOWNTO 0);          -- Lease time of IP allocation
      rx_my_ip                : IN STD_LOGIC_VECTOR(31 DOWNTO 0);          -- Suggested IP allocation

      -- TX Packet Fields
      tx_pending_ip           : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      tx_dhcp_mac             : OUT STD_LOGIC_VECTOR(47 DOWNTO 0);
      tx_dhcp_ip              : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      tx_xid                  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);

      tx_dhcp_op              : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      tx_dhcp_gen             : OUT STD_LOGIC;
      tx_dhcp_complete        : IN STD_LOGIC);
END dhcp_transaction_fsm;

-------------------------------------------------------------------------------
ARCHITECTURE behaviour of dhcp_transaction_fsm is

  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   TYPE t_dhcp_state IS (s_startup, s_send_discover, s_wait_offer,
                         s_send_request, s_wait_acknowledge,
                         s_done, s_send_renew, s_wait_renew_ack);

   CONSTANT c_dhcp_offer_op         : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"2";
   CONSTANT c_dhcp_ack_op           : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"5";
   CONSTANT c_dhcp_nack_op          : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"6";

   CONSTANT c_discover_count_width  : INTEGER := ceil_log2(g_dhcpdiscover_timeout_count);
   CONSTANT c_startup_width         : INTEGER := ceil_log2(g_startup_delay-1);
   CONSTANT c_acknowledge_width     : INTEGER := ceil_log2(g_acknowledge_timeout-1);
   CONSTANT c_discover_width        : INTEGER := ceil_log2(g_dhcpdiscover_long_interval-1);
   CONSTANT c_renew_width           : INTEGER := ceil_log2(g_renew_interval-1);
   CONSTANT c_msecond_width         : INTEGER := ceil_log2(g_axi_clk_freq-1);

  ---------------------------------------------------------------------------
  -- SIGNAL DECLARATIONS  --
  ---------------------------------------------------------------------------

   -- State Machine
   SIGNAL dhcp_state                : t_dhcp_state;
   SIGNAL discover_count            : UNSIGNED(c_discover_count_width-1 DOWNTO 0);
   SIGNAL xid                       : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL accepted_dhcp_server      : STD_LOGIC;
   SIGNAL i_ip_failover             : STD_LOGIC;
   SIGNAL latch_parameters          : STD_LOGIC;
   SIGNAL latch_parameters_dly      : STD_LOGIC;

   -- Parameter Latch
   SIGNAL pending_ip                : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL i_lease_time              : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL i_dhcp_success            : STD_LOGIC;

   -- Timers
   SIGNAL startup_count             : UNSIGNED(c_startup_width-1 DOWNTO 0);
   SIGNAL startup_timeout           : STD_LOGIC;
   SIGNAL acknowledge_count         : UNSIGNED(c_acknowledge_width-1 DOWNTO 0);
   SIGNAL acknowledge_timeout       : STD_LOGIC;
   SIGNAL discover_timeout_count    : UNSIGNED(c_discover_width-1 DOWNTO 0);
   SIGNAL discover_timeout          : STD_LOGIC;
   SIGNAL discover_slow             : STD_LOGIC;
   SIGNAL renew_count               : UNSIGNED(c_renew_width-1 DOWNTO 0);
   SIGNAL renew_interval_expired    : STD_LOGIC;
   SIGNAL t1_counter                : UNSIGNED(30 DOWNTO 0);
   SIGNAL t1_expired                : STD_LOGIC;
   SIGNAL t1_expired_dly            : STD_LOGIC;
   SIGNAL t2_counter                : UNSIGNED(31 DOWNTO 0);
   SIGNAL t2_expired                : STD_LOGIC;
   SIGNAL t2_expired_dly            : STD_LOGIC;
   SIGNAL lease_expired             : STD_LOGIC;

   SIGNAL msecond_count             : UNSIGNED(c_msecond_width-1 DOWNTO 0);
   SIGNAL msec_pulse                : STD_LOGIC;
   SIGNAL sec_counter               : UNSIGNED(9 DOWNTO 0);
   SIGNAL sec_pulse                 : STD_LOGIC;

BEGIN


   -- Use MAC as transaction ID
   xid <= mac_address(31 DOWNTO 0);
   tx_xid <= xid;

   lease_time <= i_lease_time;
   dhcp_success <= i_dhcp_success;
   ip_failover <= i_ip_failover;

-------------------------------------------------------------------------------
--                              Parameter Latch                              --
-------------------------------------------------------------------------------

param_latch: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         IF axi_rst = '1' OR dhcp_state = s_send_discover THEN
            i_dhcp_success <= '0';

            IF i_ip_failover = '1' THEN
               ip_address <= ip_address_default;         -- Failover if discover times out
            ELSE
               ip_address <= (OTHERS => '0');            -- Starts at 0.0.0.0
            END IF;
         ELSE
            -- When offer recieved store relevant details about DHCP server & offer
            IF accepted_dhcp_server = '1' THEN
               tx_dhcp_mac  <= rx_dhcp_mac;
               tx_dhcp_ip <= rx_dhcp_ip;

               pending_ip <= rx_my_ip;
            END IF;

            -- When acknowledge is complete activate IP address
            IF latch_parameters = '1' THEN
               ip_address <= pending_ip;
               i_lease_time <= rx_lease_time;
               i_dhcp_success <= '1';
            END IF;
         END IF;
      END IF;
   END PROCESS;

   tx_pending_ip <= pending_ip;

-------------------------------------------------------------------------------
--                               State Machine                               --
-------------------------------------------------------------------------------
-- On startup send a discover command every 30 seconds. We should get an offer from
-- the server soon after sending a discover (maybe multiple). We take the server IP
-- of the offer send it in the request packet.

dhcp_fsm: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         latch_parameters <= '0';
         accepted_dhcp_server <= '0';
         IF axi_rst = '1' then
            dhcp_state <= s_startup;
            discover_count <= (OTHERS => '0');
            i_ip_failover <= '0';
         ELSE
            CASE dhcp_state IS

               -------------------------------
               WHEN s_startup =>
                  discover_count <= (OTHERS => '0');
                  discover_slow <= '0';
                  IF startup_timeout = '1' AND dhcp_start = '1' THEN
                     dhcp_state <= s_send_discover;
                  END IF;

               -------------------------------
               WHEN s_send_discover =>
                  IF tx_dhcp_complete = '1' THEN
                     dhcp_state <= s_wait_offer;
                     discover_count <= discover_count + 1;
                  END IF;

               -------------------------------
               WHEN s_wait_offer =>
                  IF rx_ok = '1' THEN
                     IF rx_dhcp_op(3 DOWNTO 0) = c_dhcp_offer_op AND rx_xid = xid THEN
                        i_ip_failover <= '0';
                        dhcp_state <= s_send_request;
                        accepted_dhcp_server <= '1';
                        discover_slow <= '0';
                     END IF;
                  ELSE
                     IF discover_timeout = '1' THEN
                        IF discover_count = TO_UNSIGNED(g_dhcpdiscover_timeout_count, c_discover_count_width) THEN
                           discover_slow <= '1';
                           i_ip_failover <= '1';
                        END IF;

                        dhcp_state <= s_send_discover;
                     END IF;
                  END IF;

               -------------------------------
               WHEN s_send_request =>
                  discover_count <= (OTHERS => '0');
                  IF tx_dhcp_complete = '1' THEN
                     dhcp_state <= s_wait_acknowledge;
                  END IF;

               -------------------------------
               WHEN s_wait_acknowledge =>
                  IF rx_ok = '1' THEN
                     IF rx_xid = xid THEN
                        IF rx_dhcp_op(3 DOWNTO 0) = c_dhcp_ack_op THEN
                           dhcp_state <= s_done;
                           latch_parameters <= '1';
                        ELSIF rx_dhcp_op(3 DOWNTO 0) = c_dhcp_nack_op THEN                 -- Unable to allocate requested IP, go back to beginning and start again
                           dhcp_state <= s_send_discover;
                        END IF;
                     END IF;
                  ELSE
                     IF acknowledge_timeout = '1' THEN
                        dhcp_state <= s_send_discover;
                     END IF;
                  END IF;

               -------------------------------
               WHEN s_done =>
                  IF dhcp_start = '0' THEN
                     -- If link goes down then re-request new address (or validate old address)
                     dhcp_state <= s_send_discover;
                  ELSE
                     -- If lease expires and renews all fail go back to failsafe settings
                     IF lease_expired = '1' THEN
                        dhcp_state <= s_send_discover;
                        i_ip_failover <= '1';
                     ELSE
                        IF t2_expired = '1' THEN
                           IF renew_interval_expired = '1' or t2_expired_dly = '0' THEN
                              dhcp_state <= s_send_renew;
                           END IF;
                        ELSE
                           IF t1_expired = '1' THEN
                              IF renew_interval_expired = '1' or t1_expired_dly = '0' THEN
                                 dhcp_state <= s_send_renew;
                              END IF;
                           END IF;
                        END IF;
                     END IF;
                  END IF;

               -------------------------------
               WHEN s_send_renew =>
                  IF tx_dhcp_complete = '1' THEN
                     dhcp_state <= s_wait_renew_ack;
                  END IF;

               -------------------------------
               WHEN s_wait_renew_ack =>
                  IF rx_ok = '1' THEN
                     IF rx_xid = xid THEN
                        IF rx_dhcp_op(3 DOWNTO 0) = c_dhcp_ack_op THEN                       -- Got renewal OK
                           dhcp_state <= s_done;
                           latch_parameters <= '1';
                        ELSIF rx_dhcp_op(3 DOWNTO 0) = c_dhcp_nack_op THEN                 -- Unable to allocate requested IP, go back to beginning and start again
                           dhcp_state <= s_send_discover;
                        END IF;
                     END IF;
                  ELSE
                     IF acknowledge_timeout = '1' THEN                           -- No response so try again later
                        dhcp_state <= s_done;
                     END IF;
                  END IF;
            END CASE;
         END IF;
      END IF;
   END PROCESS;


   tx_dhcp_op(0) <= '0' WHEN dhcp_state = s_send_discover ELSE '1';
   tx_dhcp_op(1) <= i_dhcp_success;
   tx_dhcp_op(2) <= not(t2_expired) WHEN dhcp_state = s_send_renew ELSE '1';

   tx_dhcp_gen <= '1' WHEN dhcp_state = s_send_discover OR dhcp_state = s_send_request OR dhcp_state = s_send_renew ELSE '0';

-------------------------------------------------------------------------------
--                                 Counters                                  --
-------------------------------------------------------------------------------
-- Need to generate a 1 pulse per millisecond. To make the numbers a bit more correct we
-- reset the pulse per second counter after a sucessful transmission of a packet

pps_counter: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         msec_pulse <= '0';
         IF msecond_count = TO_UNSIGNED(g_axi_clk_freq-1, c_msecond_width) OR axi_rst = '1' THEN
            msecond_count <= (OTHERS => '0');
            msec_pulse <= NOT(axi_rst);
         ELSE
            msecond_count <= msecond_count + 1;
         END IF;
      END IF;
   END PROCESS;

timeouts: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         latch_parameters_dly <= latch_parameters;
         t1_expired_dly <= t1_expired;
         t2_expired_dly <= t2_expired;

         -- Packet acknowledge timeout
         IF dhcp_state /= s_wait_acknowledge AND dhcp_state /= s_wait_renew_ack THEN
            acknowledge_count <= (OTHERS => '0');
            acknowledge_timeout <= '0';
         ELSE
            IF msec_pulse = '1' THEN
               acknowledge_count <= acknowledge_count + 1;
            END IF;

            IF acknowledge_count = TO_UNSIGNED(g_acknowledge_timeout-1, c_acknowledge_width) THEN
               acknowledge_timeout <= '1';
            END IF;
         END IF;

         -- Discover timeout
         IF dhcp_state /= s_wait_offer THEN
            discover_timeout_count <= (OTHERS => '0');
            discover_timeout <= '0';
         ELSE
            IF msec_pulse = '1' THEN
               discover_timeout_count <= discover_timeout_count + 1;
            END IF;

            IF ((discover_timeout_count = TO_UNSIGNED(g_dhcpdiscover_short_interval-1, c_discover_width) AND discover_slow = '0') OR
                (discover_timeout_count = TO_UNSIGNED(g_dhcpdiscover_long_interval-1, c_discover_width) AND discover_slow = '1')) THEN
               discover_timeout <= '1';
            END IF;
         END IF;

         -- Startup timeout
         IF axi_rst = '1' THEN
            startup_count <= (OTHERS => '0');
            startup_timeout <= '0';
         ELSE
            IF msec_pulse = '1' THEN
               startup_count <= startup_count + 1;
            END IF;

            IF startup_count = TO_UNSIGNED(g_startup_delay-1, c_startup_width) THEN
               startup_timeout <= '1';
            END IF;
         END IF;

         -- Renew timeout
         IF t1_expired = '0' OR dhcp_state /= s_done THEN
            renew_count <= (OTHERS => '0');
            renew_interval_expired <= '0';
         ELSE
            IF msec_pulse = '1' THEN
               renew_count <= renew_count + 1;
            END IF;

            IF renew_count = TO_UNSIGNED(g_renew_interval-1, c_renew_width) THEN
               renew_interval_expired <= '1';
            END IF;
         END IF;

         -- Second Counter
         IF axi_rst = '1' THEN
            sec_counter <= (OTHERS => '0');
            sec_pulse <= '0';
         ELSE
            sec_pulse <= '0';
            IF msec_pulse = '1' THEN
               IF sec_counter = TO_UNSIGNED(999, 10) THEN
                  sec_counter <= (OTHERS => '0');
                  sec_pulse <= '1';
               ELSE
                  sec_counter <= sec_counter + 1;
               END IF;
            END IF;
         END IF;


         -- Lease timers, latch new times as needed (held in reset until successufl allocation)
         IF latch_parameters_dly = '1' OR i_dhcp_success = '0' THEN
            t1_counter <= UNSIGNED(i_lease_time(31 DOWNTO 1));    -- 1/2 of lease time, counts to 0
            t2_counter <= UNSIGNED(i_lease_time);                 -- 7/8 of lease time, counts to 1/8 lease time

            t1_expired <= '0';
            t2_expired <= '0';
            lease_expired <= '0';
         ELSE
            IF sec_pulse = '1' THEN
               t1_counter <= t1_counter - 1;
               t2_counter <= t2_counter - 1;
            END IF;

            IF t1_counter = 0 THEN
               t1_expired <= '1';
            END IF;

            IF t2_counter = ("000" & UNSIGNED(i_lease_time(31 DOWNTO 3))) THEN
               t2_expired <= '1';
            END IF;

            IF t2_counter = 0 THEN
               lease_expired <= '1';
            END IF;
         END IF;
      END IF;
   END PROCESS;

END behaviour;
-------------------------------------------------------------------------------