-------------------------------------------------------------------------------
--
-- File Name: tb_dhcp.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Wed Oct 11 15:40:00 2017
-- Template Rev: 1.0
--
-- Title: Top Level of DHCP Protocol Testbench
--
-- Description: Test the transactions & packet formats of the DHCP protocol
--              module.
--
--              The tetsbench plays with time. The clock runs 1000 times faster than
--              actual to speed up simulation (resolution should be in 1fs). Also
--              the timers run 1000 times fast as the clock speed is set fast so
--              a 2sec startup delay is 2us in simulation time
--
-- Compiler options:
--
--
-- Dependencies:
--
--
--
-------------------------------------------------------------------------------

LIBRARY IEEE, common_lib, axi4_lib, technology_lib, eth_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.math_real.ALL;
USE IEEE.std_logic_textio.ALL;
USE STD.textio.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE work.dhcp_reg_pkg.ALL;

ENTITY tb_dhcp IS

END tb_dhcp;

ARCHITECTURE testbench OF tb_dhcp IS

  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   CONSTANT c_default_ip         : STD_LOGIC_VECTOR(31 DOWNTO 0) := X"c0010101";
   CONSTANT c_local_mac          : STD_LOGIC_VECTOR(47 DOWNTO 0) := X"001122334455";
   CONSTANT c_mm_clk_period      : TIME := 6.4 ps;
   CONSTANT c_reset_len          : INTEGER := 10;

   CONSTANT c_ifg_clocks         : INTEGER := 100;

   CONSTANT c_class_id_type      : STD_LOGIC_VECTOR(7 DOWNTO 0)  := X"00";
   CONSTANT c_serial_number      : STD_LOGIC_VECTOR(31 DOWNTO 0) := X"FFFFFFFF"; --X"38745629";

   CONSTANT c_dhcp_mac_address   : STD_LOGIC_VECTOR(47 DOWNTO 0) := X"66778899aabb";
   CONSTANT c_dhcp_ip_address    : STD_LOGIC_VECTOR(31 DOWNTO 0) := X"0a0501fa";

   CONSTANT c_xid                : STD_LOGIC_VECTOR(31 DOWNTO 0) := c_local_mac(31 DOWNTO 0);

  ---------------------------------------------------------------------------
  -- SIGNAL DECLARATIONS  --
  ---------------------------------------------------------------------------

   SIGNAL axi_clk                   : STD_LOGIC := '0';

   -- DUT Signals
   SIGNAL frame_out_sosi            : t_axi4_sosi;
   SIGNAL frame_out_siso            : t_axi4_siso;
   SIGNAL frame_in_sosi             : t_axi4_sosi;
   SIGNAL frame_in_siso             : t_axi4_siso;
   SIGNAL s_axi_mosi                : t_axi4_lite_mosi;
   SIGNAL s_axi_miso                : t_axi4_lite_miso;
   SIGNAL ip_address                : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL ip_event                  : STD_LOGIC;
   SIGNAL dhcp_start                : STD_LOGIC;

   -- Testbench
   SIGNAL reset                     : STD_LOGIC := 'L';
   SIGNAL finished_sim              : STD_LOGIC := '0';
   SIGNAL tb_end                    : STD_LOGIC := '0';
   SIGNAL mac_ifg                   : INTEGER;
   SIGNAL mac_word_count_ely        : INTEGER;
   SIGNAL mac_word_count            : INTEGER;
   SIGNAL transaction_cycle_count   : INTEGER;
   SIGNAL mac_valid_ely             : STD_LOGIC;
   SIGNAL mac_valid                 : STD_LOGIC;
   SIGNAL mac_recieving_ely         : BOOLEAN;
   SIGNAL mac_recieving             : BOOLEAN;
   SIGNAL mac_recieving_dly         : BOOLEAN;
   SIGNAL mac_word_long             : STD_LOGIC_VECTOR(255 DOWNTO 0);
   SIGNAL mac_keep_long             : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL mac_tready                : STD_LOGIC := '1';

   SIGNAL send_dhcp                 : STD_LOGIC_VECTOR(1 DOWNTO 0);
   SIGNAL sending_dhcp              : BOOLEAN;
   SIGNAL dhcp_payload              : INTEGER;
   SIGNAL dhcp_type                 : STD_LOGIC_VECTOR(1 DOWNTO 0);

   SIGNAL dhcp_detected             : BOOLEAN;
   SIGNAL dhcp_mtu                  : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL dhcp_requested_ip         : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL dhcp_lease_time           : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL dhcp_op                   : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL dhcp_server_ip            : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL dhcp_class_id             : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL dhcp_class_id_type        : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL ci_addr                   : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL yi_addr                   : STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL dhcp_dest_mac             : STD_LOGIC_VECTOR(47 DOWNTO 0);

   CONSTANT c_dhcp_offer            : STD_LOGIC_VECTOR(40*73-1 DOWNTO 0) := "0" & X"FF" & c_dhcp_mac_address(39 DOWNTO 32) & c_dhcp_mac_address(47 DOWNTO 40) & c_local_mac(7 DOWNTO 0) & c_local_mac(15 DOWNTO 8) & c_local_mac(23 DOWNTO 16) & c_local_mac(31 DOWNTO 24) & c_local_mac(39 DOWNTO 32) & c_local_mac(47 DOWNTO 40) &
                                                                            "0" & X"FF" & X"00450008" & c_dhcp_mac_address(7 DOWNTO 0) & c_dhcp_mac_address(15 DOWNTO 8) & c_dhcp_mac_address(23 DOWNTO 16) & c_dhcp_mac_address(31 DOWNTO 24) &
                                                                            "0" & X"FF" & X"114000001ca23201" &
                                                                            "0" & X"FF" & X"FFFF" & c_dhcp_ip_address(7 DOWNTO 0) & c_dhcp_ip_address(15 DOWNTO 8) & c_dhcp_ip_address(23 DOWNTO 16) & c_dhcp_ip_address(31 DOWNTO 24) & X"0000" &
                                                                            "0" & X"FF" & X"1e0144004300FFFF" & -- length
                                                                            "0" & X"FF" & c_xid(23 DOWNTO 16) & c_xid(31 DOWNTO 24) & X"000601020000" &
                                                                            "0" & X"FF" & X"000000800000" & c_xid(7 DOWNTO 0) & c_xid(15 DOWNTO 8) &
                                                                            "0" & X"FF" & c_dhcp_ip_address(23 DOWNTO 16) & c_dhcp_ip_address(31 DOWNTO 24) & X"0601050a0000" &
                                                                            "0" & X"FF" & c_local_mac(39 DOWNTO 32) & c_local_mac(47 DOWNTO 40) & X"00000000" & c_dhcp_ip_address(7 DOWNTO 0) & c_dhcp_ip_address(15 DOWNTO 8) &
                                                                            "0" & X"FF" & X"00000000" & c_dhcp_mac_address(7 DOWNTO 0) & c_dhcp_mac_address(15 DOWNTO 8) & c_dhcp_mac_address(23 DOWNTO 16) & c_dhcp_mac_address(31 DOWNTO 24) &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"8263000000000000" &
                                                                            "0" & X"FF" & X"FF04010201356353" &
                                                                            "0" & X"FF" & X"01050a040300FFFF" &
                                                                            "0" & X"FF" & X"363C000000043301" &         -- 60 second lease
                                                                            "0" & X"FF" & X"23021a" & c_dhcp_ip_address(7 DOWNTO 0) & c_dhcp_ip_address(15 DOWNTO 8) & c_dhcp_ip_address(23 DOWNTO 16) & c_dhcp_ip_address(31 DOWNTO 24) & X"04" &
                                                                            "1" & X"FF" & X"ff00696d67044c28";


   CONSTANT c_dhcp_ack              : STD_LOGIC_VECTOR(40*73-1 DOWNTO 0) := "0" & X"FF" & c_dhcp_mac_address(39 DOWNTO 32) & c_dhcp_mac_address(47 DOWNTO 40) & c_local_mac(7 DOWNTO 0) & c_local_mac(15 DOWNTO 8) & c_local_mac(23 DOWNTO 16) & c_local_mac(31 DOWNTO 24) & c_local_mac(39 DOWNTO 32) & c_local_mac(47 DOWNTO 40) &
                                                                            "0" & X"FF" & X"00450008" & c_dhcp_mac_address(7 DOWNTO 0) & c_dhcp_mac_address(15 DOWNTO 8) & c_dhcp_mac_address(23 DOWNTO 16) & c_dhcp_mac_address(31 DOWNTO 24) &
                                                                            "0" & X"FF" & X"114000001ca23201" &
                                                                            "0" & X"FF" & X"FFFF" & c_dhcp_ip_address(7 DOWNTO 0) & c_dhcp_ip_address(15 DOWNTO 8) & c_dhcp_ip_address(23 DOWNTO 16) & c_dhcp_ip_address(31 DOWNTO 24) & X"0000" &
                                                                            "0" & X"FF" & X"1e0144004300FFFF" & -- length
                                                                            "0" & X"FF" & c_xid(23 DOWNTO 16) & c_xid(31 DOWNTO 24) & X"000601020000" &
                                                                            "0" & X"FF" & X"000000800000" & c_xid(7 DOWNTO 0) & c_xid(15 DOWNTO 8) &
                                                                            "0" & X"FF" & c_dhcp_ip_address(23 DOWNTO 16) & c_dhcp_ip_address(31 DOWNTO 24) & X"0601050a0000" &
                                                                            "0" & X"FF" & c_local_mac(39 DOWNTO 32) & c_local_mac(47 DOWNTO 40) & X"00000000" & c_dhcp_ip_address(7 DOWNTO 0) & c_dhcp_ip_address(15 DOWNTO 8) &
                                                                            "0" & X"FF" & X"00000000" & c_dhcp_mac_address(7 DOWNTO 0) & c_dhcp_mac_address(15 DOWNTO 8) & c_dhcp_mac_address(23 DOWNTO 16) & c_dhcp_mac_address(31 DOWNTO 24) &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"8263000000000000" &
                                                                            "0" & X"FF" & X"FF04010501356353" &
                                                                            "0" & X"FF" & X"01050a040300FFFF" &
                                                                            "0" & X"FF" & X"363C000000043301" &         -- 60 second lease
                                                                            "0" & X"FF" & X"23021a" & c_dhcp_ip_address(7 DOWNTO 0) & c_dhcp_ip_address(15 DOWNTO 8) & c_dhcp_ip_address(23 DOWNTO 16) & c_dhcp_ip_address(31 DOWNTO 24) & X"04" &
                                                                            "1" & X"FF" & X"ff00696d67044c28";

   CONSTANT c_dhcp_nack             : STD_LOGIC_VECTOR(40*73-1 DOWNTO 0) := "0" & X"FF" & c_dhcp_mac_address(39 DOWNTO 32) & c_dhcp_mac_address(47 DOWNTO 40) & c_local_mac(7 DOWNTO 0) & c_local_mac(15 DOWNTO 8) & c_local_mac(23 DOWNTO 16) & c_local_mac(31 DOWNTO 24) & c_local_mac(39 DOWNTO 32) & c_local_mac(47 DOWNTO 40) &
                                                                            "0" & X"FF" & X"00450008" & c_dhcp_mac_address(7 DOWNTO 0) & c_dhcp_mac_address(15 DOWNTO 8) & c_dhcp_mac_address(23 DOWNTO 16) & c_dhcp_mac_address(31 DOWNTO 24) &
                                                                            "0" & X"FF" & X"114000001ca23201" &
                                                                            "0" & X"FF" & X"FFFF" & c_dhcp_ip_address(7 DOWNTO 0) & c_dhcp_ip_address(15 DOWNTO 8) & c_dhcp_ip_address(23 DOWNTO 16) & c_dhcp_ip_address(31 DOWNTO 24) & X"0000" &
                                                                            "0" & X"FF" & X"1e0144004300FFFF" & -- length
                                                                            "0" & X"FF" & c_xid(23 DOWNTO 16) & c_xid(31 DOWNTO 24) & X"000601020000" &
                                                                            "0" & X"FF" & X"000000800000" & c_xid(7 DOWNTO 0) & c_xid(15 DOWNTO 8) &
                                                                            "0" & X"FF" & c_dhcp_ip_address(23 DOWNTO 16) & c_dhcp_ip_address(31 DOWNTO 24) & X"0601050a0000" &
                                                                            "0" & X"FF" & c_local_mac(39 DOWNTO 32) & c_local_mac(47 DOWNTO 40) & X"00000000" & c_dhcp_ip_address(7 DOWNTO 0) & c_dhcp_ip_address(15 DOWNTO 8) &
                                                                            "0" & X"FF" & X"00000000" & c_dhcp_mac_address(7 DOWNTO 0) & c_dhcp_mac_address(15 DOWNTO 8) & c_dhcp_mac_address(23 DOWNTO 16) & c_dhcp_mac_address(31 DOWNTO 24) &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"0000000000000000" &
                                                                            "0" & X"FF" & X"8263000000000000" &
                                                                            "0" & X"FF" & X"FF04010601356353" &
                                                                            "0" & X"FF" & X"01050a040300FFFF" &
                                                                            "0" & X"FF" & X"363C000000043301" &         -- 60 second lease
                                                                            "0" & X"FF" & X"23021a" & c_dhcp_ip_address(7 DOWNTO 0) & c_dhcp_ip_address(15 DOWNTO 8) & c_dhcp_ip_address(23 DOWNTO 16) & c_dhcp_ip_address(31 DOWNTO 24) & X"04" &
                                                                            "1" & X"FF" & X"ff00696d67044c28";



BEGIN



---------------------------------------------------------------------------
-- Clocks  --
---------------------------------------------------------------------------

   axi_clk <= NOT axi_clk OR finished_sim AFTER c_mm_clk_period/2;
   reset <= '1', 'L'    AFTER c_mm_clk_period*c_reset_len;

---------------------------------------------------------------------------
-- Serial Enable  --
---------------------------------------------------------------------------

   PROCESS
   BEGIN
      dhcp_start <= '0';
      WAIT FOR 3 ns;
      dhcp_start <= '1';
      WAIT;
   END PROCESS;


---------------------------------------------------------------------------
-- DUT  --
---------------------------------------------------------------------------

dut: ENTITY work.dhcp_protocol
     GENERIC MAP (g_technology         => c_tech_gemini,
                  g_axi_clk_freq       => 156)
     PORT MAP (axi_clk                 => axi_clk,
               axi_rst                 => reset,
               ip_address_default      => c_default_ip,
               mac_address             => c_local_mac,
               serial_number           => c_serial_number,
               dhcp_start              => dhcp_start,
               ip_address              => ip_address,
               ip_event                => ip_event,
               s_axi_mosi              => s_axi_mosi,
               s_axi_miso              => s_axi_miso,
               frame_in_sosi           => frame_in_sosi,
               frame_in_siso           => frame_in_siso,
               frame_out_sosi          => frame_out_sosi,
               frame_out_siso          => frame_out_siso);

---------------------------------------------------------------------------
-- Packet Decoder  --
---------------------------------------------------------------------------
-- Generate textual descriptions of the packets

rx_pkt_decode: ENTITY eth_lib.packet_decoder
               GENERIC MAP (prefix => string'("Testbench"))
               PORT MAP (clk           => axi_clk,
                         reset         => reset,
                         eth_out_sosi  => frame_in_sosi,
                         eth_out_siso  => frame_in_siso);

tx_pkt_decode: ENTITY eth_lib.packet_decoder
               GENERIC MAP (prefix => string'("DUT"))
               PORT MAP (clk           => axi_clk,
                         reset         => reset,
                         eth_out_sosi  => frame_out_sosi,
                         eth_out_siso  => frame_out_siso);

---------------------------------------------------------------------------
-- Traffic Generators  --
---------------------------------------------------------------------------

dhcp_control: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         IF sending_dhcp = TRUE THEN
            IF frame_in_siso.tready = '1' THEN
               IF dhcp_payload = 0 THEN
                  sending_dhcp <= FALSE;
               ELSE
                  dhcp_payload <= dhcp_payload - 1;
               END IF;
            END IF;
         ELSE
            IF send_dhcp /= "00" THEN
               sending_dhcp <= TRUE;
               dhcp_type <= send_dhcp;

               IF send_dhcp = "01" THEN
                  dhcp_payload <= ((c_dhcp_offer'LEFT+1)/73)-1;
               ELSIF send_dhcp = "10" THEN
                  dhcp_payload <= ((c_dhcp_ack'LEFT+1)/73)-1;
               ELSIF send_dhcp = "11" THEN
                  dhcp_payload <= ((c_dhcp_nack'LEFT+1)/73)-1;
               END IF;
            END IF;
         END IF;
      END IF;
   END PROCESS;

   frame_in_sosi.tvalid <= '1' WHEN sending_dhcp = TRUE ELSE '0';

dhcp_data: PROCESS(dhcp_payload, sending_dhcp)
   BEGIN
      IF sending_dhcp = TRUE THEN
         IF dhcp_type = "01" THEN
            frame_in_sosi.tdata(63 DOWNTO 0) <= c_dhcp_offer((dhcp_payload*73)+63 DOWNTO (dhcp_payload*73)+0);
            frame_in_sosi.tkeep(7 DOWNTO 0) <= c_dhcp_offer((dhcp_payload*73)+71 DOWNTO (dhcp_payload*73)+64);
            frame_in_sosi.tlast <= c_dhcp_offer((dhcp_payload*73)+72);
         ELSIF dhcp_type = "10" THEN
            frame_in_sosi.tdata(63 DOWNTO 0) <= c_dhcp_ack((dhcp_payload*73)+63 DOWNTO (dhcp_payload*73)+0);
            frame_in_sosi.tkeep(7 DOWNTO 0) <= c_dhcp_ack((dhcp_payload*73)+71 DOWNTO (dhcp_payload*73)+64);
            frame_in_sosi.tlast <= c_dhcp_ack((dhcp_payload*73)+72);
         ELSIF dhcp_type = "11" THEN
            frame_in_sosi.tdata(63 DOWNTO 0) <= c_dhcp_nack((dhcp_payload*73)+63 DOWNTO (dhcp_payload*73)+0);
            frame_in_sosi.tkeep(7 DOWNTO 0) <= c_dhcp_nack((dhcp_payload*73)+71 DOWNTO (dhcp_payload*73)+64);
            frame_in_sosi.tlast <= c_dhcp_nack((dhcp_payload*73)+72);
         END IF;
      ELSE
         frame_in_sosi.tdata(63 DOWNTO 0) <= X"0000000000000000";
         frame_in_sosi.tkeep(7 DOWNTO 0) <= X"00";
         frame_in_sosi.tlast <= '0';
      END IF;
   END PROCESS;



---------------------------------------------------------------------------
-- Transmit MAC Reciever  --
---------------------------------------------------------------------------

tx_mac: PROCESS(axi_clk)
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         mac_word_count <= mac_word_count_ely;
         mac_recieving <= mac_recieving_ely;
         mac_valid <= mac_valid_ely;

         mac_recieving_dly <= mac_recieving;

         -- Gap counter between frames
         IF mac_ifg /= 0 THEN
            mac_ifg <= mac_ifg - 1;
         END IF;

         IF reset = '1' THEN
            mac_recieving_ely <= FALSE;
            mac_word_count_ely <= 0;
            mac_ifg <= 0;
         ELSE
            -- Enable
            IF mac_recieving_ely = FALSE THEN
               IF frame_out_sosi.tvalid = '1' AND mac_ifg = 0 THEN
                  mac_recieving_ely <= TRUE;
               END IF;
            END IF;

            -- Used to insert random tready deassertions
            IF mac_recieving = FALSE THEN
               transaction_cycle_count <= 0;
            ELSE
               transaction_cycle_count <= transaction_cycle_count + 1;
            END IF;

            IF frame_out_sosi.tvalid = '1' AND frame_out_siso.tready = '1' THEN

               -- Count words in packet (for decoding)
               IF mac_recieving_ely = FALSE THEN
                  mac_word_count_ely <= 1;
               ELSE
                  mac_word_count_ely <= mac_word_count_ely + 1;
               END IF;

               -- Go back to big endian and store 2 words incase fields cross boundaries
               mac_word_long <= mac_word_long(191 DOWNTO 0) &
                                frame_out_sosi.tdata(7 DOWNTO 0) &
                                frame_out_sosi.tdata(15 DOWNTO 8) &
                                frame_out_sosi.tdata(23 DOWNTO 16) &
                                frame_out_sosi.tdata(31 DOWNTO 24) &
                                frame_out_sosi.tdata(39 DOWNTO 32) &
                                frame_out_sosi.tdata(47 DOWNTO 40) &
                                frame_out_sosi.tdata(55 DOWNTO 48) &
                                frame_out_sosi.tdata(63 DOWNTO 56);

               mac_keep_long <= mac_keep_long(23 downto 0) &
                                frame_out_sosi.tkeep(0) &
                                frame_out_sosi.tkeep(1) &
                                frame_out_sosi.tkeep(2) &
                                frame_out_sosi.tkeep(3) &
                                frame_out_sosi.tkeep(4) &
                                frame_out_sosi.tkeep(5) &
                                frame_out_sosi.tkeep(6) &
                                frame_out_sosi.tkeep(7);

               -- Stop receiving and insert gap
               IF frame_out_sosi.tlast = '1' THEN
                  mac_ifg <= c_ifg_clocks;
                  mac_recieving_ely <= FALSE;
                  mac_word_count_ely <= 0;
               END IF;
            END IF;
         END IF;
      END IF;
   END PROCESS;

   mac_valid_ely <= frame_out_sosi.tvalid and frame_out_siso.tready when mac_recieving_ely = TRUE ELSE '0';

read_randomiser: PROCESS(axi_clk)
      VARIABLE seed1    : POSITIVE     := 52548;
      VARIABLE seed2    : POSITIVE     := 5087986;
      VARIABLE rand1    : REAL         := 0.5;                 -- random real-number value in range 0 to 1.0
   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         IF mac_recieving_ely = TRUE THEN
            uniform(seed1, seed2, rand1);

            IF rand1 > 0.5 or transaction_cycle_count = 2 THEN
               mac_tready <= '0';
            ELSE
               mac_tready <= '1';
            END IF;
         END IF;
      END IF;
   END PROCESS;

   -- Handle the ready (ready when nothing going on, not ready duing interf frame gap, random ready during packet)
   frame_out_siso.tready <= '0' WHEN mac_ifg > 0 ELSE
                            '1' WHEN mac_recieving_ely = FALSE OR mac_word_count_ely < 1 ELSE
                            mac_tready;

---------------------------------------------------------------------------
-- RX Code  --
---------------------------------------------------------------------------

dhcp_decode: PROCESS(axi_clk)
      VARIABLE stdio                   : line;
      VARIABLE dhcp_shifter            : STD_LOGIC_VECTOR(255 DOWNTO 0);
      VARIABLE dhcp_found_magic        : BOOLEAN;
      VARIABLE udp_payload_length      : INTEGER;
      VARIABLE dhcp_processing_option  : INTEGER;
      VARIABLE dhcp_option             : INTEGER;
      VARIABLE dhcp_option_length      : INTEGER;
      VARIABLE option_payload          : INTEGER;

   BEGIN
      IF RISING_EDGE(axi_clk) THEN
         IF mac_recieving = TRUE THEN
            IF mac_valid = '1' AND (dhcp_detected = TRUE OR mac_word_count = 1) THEN

               -- Check length of packet OK
               IF mac_word_count > 4 THEN
                  length_check: FOR i IN 0 TO 7 LOOP
                     IF mac_keep_long(i) = '1' THEN
                        udp_payload_length := udp_payload_length - 1;
                     END IF;
                  END LOOP;
               END IF;

               CASE mac_word_count IS
                  WHEN 0 =>
                  WHEN 1 =>
                     dhcp_mtu <= (OTHERS => 'X');
                     dhcp_requested_ip <= (OTHERS => 'X');
                     dhcp_lease_time <= (OTHERS => 'X');
                     dhcp_op <= (OTHERS => 'X');
                     dhcp_server_ip <= (OTHERS => 'X');
                     dhcp_class_id <= (OTHERS => 'X');
                     dhcp_class_id_type <= (OTHERS => 'X');

                     dhcp_dest_mac <= mac_word_long(127 DOWNTO 80);

                     IF mac_word_long(31 DOWNTO 16) = X"0800" THEN
                        dhcp_detected <= TRUE; -- Maybe
                     END IF;
                  WHEN 2 =>
                     IF mac_word_long(7 DOWNTO 0) /= X"11" THEN
                        dhcp_detected <= FALSE;
                     END IF;
                  WHEN 3 =>
                  WHEN 4 =>
                     ASSERT mac_word_long(47 DOWNTO 32) = X"0044" REPORT "Should be sourced from port 68" SEVERITY failure;
                     ASSERT mac_word_long(31 DOWNTO 16) = X"0043" REPORT "Should be destined to port 67" SEVERITY failure;

                     udp_payload_length := to_integer(unsigned(mac_word_long(15 DOWNTO 0))) - 6;
                  WHEN 5 =>
                     ASSERT mac_word_long(47 DOWNTO 40) = X"01" REPORT "Only requests issued by client" SEVERITY failure;
                     ASSERT mac_word_long(39 DOWNTO 32) = X"01" REPORT "Only ethernet MAC addresses as HW address" SEVERITY failure;
                     ASSERT mac_word_long(31 DOWNTO 24) = X"06" REPORT "HW address 6 octets long" SEVERITY failure;
                  WHEN 6 =>
                     ASSERT mac_word_long(79 DOWNTO 48) = c_local_mac(31 DOWNTO 0) REPORT "XID should be 32 LSB of MAC address" SEVERITY failure;
                  WHEN 7 =>
                     ci_addr <= mac_word_long(79 DOWNTO 48);
                     yi_addr <= mac_word_long(47 DOWNTO 16);
                  WHEN 8 =>
                     ASSERT mac_word_long(79 DOWNTO 48) = X"00000000" REPORT "SIADDR should be 0 for client requests" SEVERITY failure;
                     ASSERT mac_word_long(47 DOWNTO 16) = X"00000000" REPORT "Proxy commands not supported GIADDR should be 0" SEVERITY failure;
                  WHEN 9 =>
                     ASSERT mac_word_long(79 DOWNTO 32) = c_local_mac REPORT "HW address incorrect" SEVERITY failure;
                     dhcp_found_magic := FALSE;
                  WHEN OTHERS =>
                     -- Some amount of zeros pass so look for magic number
                     -- Then process options 1 at a time.
                     byte_loop: FOR i IN 7 DOWNTO 0 LOOP
                        -- Option payload needs to be less than 32 bytes
                        dhcp_shifter := dhcp_shifter(247 DOWNTO 0) & mac_word_long(i*8+7 DOWNTO i*8+0);

                        IF dhcp_found_magic = FALSE THEN
                           IF dhcp_shifter(31 DOWNTO 0) = X"63825363" THEN
                              dhcp_found_magic := TRUE;
                              dhcp_processing_option := 0;
                           END IF;
                        ELSE
                           IF dhcp_processing_option = 0 THEN
                              dhcp_option := TO_INTEGER(unsigned(dhcp_shifter(7 DOWNTO 0)));

                              IF dhcp_option = 255 THEN
                                 dhcp_found_magic := FALSE;
                              ELSIF dhcp_option /= 0 THEN
                                 dhcp_processing_option := 1;
                              END IF;
                           ELSIF dhcp_processing_option = 1 THEN
                              dhcp_option_length := TO_INTEGER(unsigned(dhcp_shifter(7 DOWNTO 0)));
                              option_payload := 0;
                              dhcp_processing_option := 2;
                           ELSE
                              option_payload := option_payload + 1;

                              -- Process Option if everything is in shifter
                              IF option_payload = dhcp_option_length THEN
                                 dhcp_processing_option := 0;
                                 CASE dhcp_option IS
                                    WHEN 26 => dhcp_mtu <= dhcp_shifter(15 DOWNTO 0);
                                    WHEN 50 => dhcp_requested_ip <= dhcp_shifter(31 DOWNTO 0);
                                    WHEN 51 => dhcp_lease_time <= dhcp_shifter(31 DOWNTO 0);
                                    WHEN 53 => dhcp_op <= dhcp_shifter(7 DOWNTO 0);
                                    WHEN 54 => dhcp_server_ip <= dhcp_shifter(31 DOWNTO 0);
                                    WHEN 61 => dhcp_class_id <= dhcp_shifter(31 DOWNTO 0); -- Actually 40 bits but first 8 bits defines data type so not used
                                               dhcp_class_id_type <= dhcp_shifter(39 DOWNTO 32);
                                    WHEN OTHERS =>
                                 END CASE;
                              END IF;
                           END IF;
                        END IF;
                     END LOOP;
               END CASE;
            END IF;
         ELSE
            IF mac_recieving_dly = TRUE AND dhcp_detected = TRUE THEN
               ASSERT udp_payload_length = 0 REPORT "DHCP Payload wrong" SEVERITY failure;
            END IF;
            dhcp_detected <= FALSE;
         END IF;
      END IF;
   END PROCESS;

---------------------------------------------------------------------------
-- Test Script  --
---------------------------------------------------------------------------

tb_stim: PROCESS

      VARIABLE start_time : TIME;
   BEGIN
      send_dhcp <= "00";

      axi_lite_init (reset, axi_clk, s_axi_miso, s_axi_mosi);


      -------------------------------------------
      --                Test 1                 --
      -------------------------------------------
      -- Perform a normal DISCOVER, OFFER, REQUEST, ACK cycle
      -- Wait for lease expiry and rerequest and ack
      -- Wait for lease expiry, don't acknowlegde, wait for IP failover

      -- Wait for discover
      WAIT UNTIL FALLING_EDGE(dhcp_detected);
      ASSERT dhcp_dest_mac = X"FFFFFFFFFFFF" REPORT "DHCPDISCOVER messages should be broadcast" SEVERITY failure;
      ASSERT dhcp_op = X"01" REPORT "Message not DHCPDISCOVER" SEVERITY failure;
      ASSERT dhcp_class_id = c_serial_number REPORT "Class ID not set" SEVERITY failure;
      ASSERT dhcp_class_id_type = c_class_id_type REPORT "Class ID type not set" SEVERITY failure;

      -- Send Offer 60s lease
      WAIT UNTIL RISING_EDGE(axi_clk);
      send_dhcp <= "01";
      WAIT UNTIL RISING_EDGE(axi_clk);
      send_dhcp <= "00";
      WAIT UNTIL FALLING_EDGE(sending_dhcp);

      -- Delay for packet reception, decoding & processing
      WAIT FOR 2 ns;

      -- Check that server details are correct
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_dhcp_dhcp_server_address, FALSE, c_dhcp_ip_address, validate => true);

      -- Wait for request
      WAIT UNTIL FALLING_EDGE(dhcp_detected);
      ASSERT dhcp_dest_mac = X"ffffffffffff" REPORT "DHCPREQUEST messages should be broadcast" SEVERITY failure;
      ASSERT dhcp_requested_ip = X"0a050106" REPORT "Wrong IP requested" SEVERITY failure;
      ASSERT dhcp_op = X"03" REPORT "Message not DHCPREQUEST" SEVERITY failure;
      ASSERT dhcp_server_ip = c_dhcp_ip_address REPORT "Server IP address no set" SEVERITY failure;
      ASSERT dhcp_class_id = c_serial_number REPORT "Class ID not set" SEVERITY failure;
      ASSERT dhcp_class_id_type = c_class_id_type REPORT "Class ID type not set" SEVERITY failure;
      ASSERT ci_addr = X"00000000" REPORT "Client IP should be 0" SEVERITY failure;
      ASSERT yi_addr = X"00000000" REPORT "Your IP should be 0" SEVERITY failure;

      -- Send ACK
      WAIT UNTIL RISING_EDGE(axi_clk);
      send_dhcp <= "10";
      WAIT UNTIL RISING_EDGE(axi_clk);
      send_dhcp <= "00";
      start_time := now;

      -- Delay for packet reception, decoding & processing
      WAIT FOR 5 ns;

      --Check DHCP allocation details correct
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_dhcp_lease_time_address, FALSE, X"0000003C", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_dhcp_local_ip_address, FALSE, X"0a050106", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_dhcp_status_dhcp_configured_address, FALSE, X"00000001", validate => true);

      -- Wait for lease expiry, and new request
      WAIT UNTIL FALLING_EDGE(dhcp_detected);
      ASSERT dhcp_dest_mac = c_dhcp_mac_address REPORT "DHCPREQUEST messages for renew should be unicast" SEVERITY failure;
      ASSERT Is_X(dhcp_requested_ip) = TRUE REPORT "Requested IP should not be set" SEVERITY failure;
      ASSERT dhcp_op = X"03" REPORT "Message not DHCPREQUEST" SEVERITY failure;
      ASSERT Is_X(dhcp_server_ip) = TRUE REPORT "Server IP address should not be set" SEVERITY failure;
      ASSERT dhcp_class_id = c_serial_number REPORT "Class ID not set" SEVERITY failure;
      ASSERT dhcp_class_id_type = c_class_id_type REPORT "Class ID type not set" SEVERITY failure;
      ASSERT ci_addr = X"0a050106" REPORT "Client IP should be 10.5.1.6" SEVERITY failure;
      ASSERT yi_addr = X"00000000" REPORT "Your IP should be 0" SEVERITY failure;
      ASSERT (now - start_time) > 29.95 us REPORT "Lease renewal occured too soon" SEVERITY failure; -- clock is not exactly 1000 times faster

      -- Send back ACK
      WAIT UNTIL RISING_EDGE(axi_clk);
      send_dhcp <= "10";
      WAIT UNTIL RISING_EDGE(axi_clk);
      send_dhcp <= "00";
      WAIT UNTIL FALLING_EDGE(sending_dhcp);

      -- Wait for 7/8th of lease time
      WAIT FOR 52.45 us;

      WAIT UNTIL FALLING_EDGE(dhcp_detected);
      ASSERT dhcp_dest_mac = X"FFFFFFFFFFFF" REPORT "DHCPREQUEST messages should be broadcast now" SEVERITY failure;
      ASSERT Is_X(dhcp_requested_ip) = TRUE REPORT "Requested IP should not be set" SEVERITY failure;
      ASSERT dhcp_op = X"03" REPORT "Message not DHCPREQUEST" SEVERITY failure;
      ASSERT Is_X(dhcp_server_ip) = TRUE REPORT "Server IP address should not be set" SEVERITY failure;
      ASSERT dhcp_class_id = c_serial_number REPORT "Class ID not set" SEVERITY failure;
      ASSERT dhcp_class_id_type = c_class_id_type REPORT "Class ID type not set" SEVERITY failure;
      ASSERT ci_addr = X"0a050106" REPORT "Client IP should be 10.5.1.6" SEVERITY failure;
      ASSERT yi_addr = X"00000000" REPORT "Your IP should be 0" SEVERITY failure;

      -- Wait for lease expiry, should go back to discover
      WAIT FOR 7.5 us;

      WAIT UNTIL FALLING_EDGE(dhcp_detected);
      ASSERT dhcp_dest_mac = X"FFFFFFFFFFFF" REPORT "DHCPDISCOVER messages should be broadcast" SEVERITY failure;
      ASSERT dhcp_op = X"01" REPORT "Message not DHCPDISCOVER" SEVERITY failure;
      ASSERT dhcp_class_id = c_serial_number REPORT "Class ID not set" SEVERITY failure;
      ASSERT dhcp_class_id_type = c_class_id_type REPORT "Class ID type not set" SEVERITY failure;

      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_dhcp_status_dhcp_configured_address, FALSE, X"00000000", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_dhcp_status_ip_failover_address, FALSE, X"00000001", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_dhcp_local_ip_address, FALSE, c_default_ip, validate => true);

      REPORT "Finished Test 1" SEVERITY note;
      WAIT FOR 1 us;

      -------------------------------------------
      --                Test 2                 --
      -------------------------------------------
      -- Wait for DISCOVER and send OFFER, WAIT for requests but send NAK instead

      reset <= '1';
      WAIT FOR 100 ps;
      reset <= 'L';
      WAIT FOR 500 ps;

      -- Wait for discover
      WAIT UNTIL FALLING_EDGE(dhcp_detected);
      ASSERT dhcp_dest_mac = X"FFFFFFFFFFFF" REPORT "DHCPDISCOVER messages should be broadcast" SEVERITY failure;
      ASSERT dhcp_op = X"01" REPORT "Message not DHCPDISCOVER" SEVERITY failure;
      ASSERT dhcp_class_id = c_serial_number REPORT "Class ID not set" SEVERITY failure;
      ASSERT dhcp_class_id_type = c_class_id_type REPORT "Class ID type not set" SEVERITY failure;

      -- Send Offer 60s lease
      WAIT UNTIL RISING_EDGE(axi_clk);
      send_dhcp <= "01";
      WAIT UNTIL RISING_EDGE(axi_clk);
      send_dhcp <= "00";
      WAIT UNTIL FALLING_EDGE(sending_dhcp);

      -- Delay for packet reception, decoding & processing
      WAIT FOR 2 ns;

      -- Wait for request
      WAIT UNTIL FALLING_EDGE(dhcp_detected);

      -- Send NACK
      WAIT UNTIL RISING_EDGE(axi_clk);
      send_dhcp <= "11";
      WAIT UNTIL RISING_EDGE(axi_clk);
      send_dhcp <= "00";

      -- Wait for failover
      WAIT FOR 30 us;

      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_dhcp_status_ip_failover_address, FALSE, X"00000001", validate => true);
      axi_lite_transaction (axi_clk, s_axi_miso, s_axi_mosi, c_dhcp_local_ip_address, FALSE, c_default_ip, validate => true);

      REPORT "Finished Test 2" SEVERITY note;

      finished_sim <= '1';
      tb_end       <= '1';
      wait for 1 us;
      REPORT "Finished Simulation" SEVERITY FAILURE;
      WAIT;
   END PROCESS;






END testbench;