LIBRARY IEEE, technology_lib, axi4_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE work.tech_mac_100g_component_pkg.ALL;
USE work.tech_mac_100g_pkg.ALL;

ENTITY tech_mac_100g IS
   GENERIC (
      g_technology            : t_technology;
      g_device                : t_quad_locations_100g;


      g_txpostcursor          : t_tech_slv_5_arr(3 DOWNTO 0) := (OTHERS => "00000");   -- No post emphasis
      g_txmaincursor          : t_tech_slv_7_arr(3 DOWNTO 0) := (OTHERS => "1010000");
      g_txprecursor           : t_tech_slv_5_arr(3 DOWNTO 0) := (OTHERS => "00000");   -- 0.1dB pre emphasis
      g_txdiffctrl            : t_tech_slv_5_arr(3 DOWNTO 0) := (OTHERS => "11000");   -- 950mVpp
      g_txpolarity            : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
      g_rxpolarity            : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
      g_rxlpmen               : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0'));      -- DFE
   PORT (
      gt_rxp_in               : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      gt_rxn_in               : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      gt_txp_out              : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      gt_txn_out              : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);

      gt_refclk_p             : IN STD_LOGIC;
      gt_refclk_n             : IN STD_LOGIC;

      sys_reset               : IN STD_LOGIC;
      dclk                    : IN STD_LOGIC;

      loopback                : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      tx_enable               : IN STD_LOGIC;
      rx_enable               : IN STD_LOGIC;

      tx_clk_out              : OUT STD_LOGIC;
      rx_clk_in               : IN STD_LOGIC;                        -- Should be driven by one of the tx_clk_outs
      rx_clk_out              : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);

      -- User Interface Signals
      rx_locked               : OUT STD_LOGIC;

      user_rx_reset           : OUT STD_LOGIC;
      user_tx_reset           : OUT STD_LOGIC;

      -- Statistics Interface
      stat_rx_total_bytes     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);    -- Number of bytes received
      stat_rx_total_packets   : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);    -- Total RX packets
      stat_rx_bad_fcs         : OUT STD_LOGIC;                       -- Bad checksums
      stat_rx_bad_code        : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);    -- Bit errors on the line

      stat_tx_total_bytes     : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);    -- Number of bytes transmitted
      stat_tx_total_packets   : OUT STD_LOGIC;                       -- Total TX packets

      -- Recieved data from optics
      data_rx_sosi            : OUT t_lbus_sosi;

      -- Data to be transmitted to optics
      data_tx_sosi            : IN t_lbus_sosi;
      data_tx_siso            : OUT t_lbus_siso);
END tech_mac_100g;

ARCHITECTURE str OF tech_mac_100g IS

   CONSTANT c_txdiffctrl         : STD_LOGIC_VECTOR(19 DOWNTO 0) := g_txdiffctrl(3) & g_txdiffctrl(2) & g_txdiffctrl(1) & g_txdiffctrl(0);
   CONSTANT c_txmaincursor       : STD_LOGIC_VECTOR(27 DOWNTO 0) := g_txmaincursor(3) & g_txmaincursor(2) & g_txmaincursor(1) & g_txmaincursor(0);
   CONSTANT c_txpostcursor       : STD_LOGIC_VECTOR(19 DOWNTO 0) := g_txpostcursor(3) & g_txpostcursor(2) & g_txpostcursor(1) & g_txpostcursor(0);
   CONSTANT c_txprecursor        : STD_LOGIC_VECTOR(19 DOWNTO 0) := g_txprecursor(3) & g_txprecursor(2) & g_txprecursor(1) & g_txprecursor(0);

   SIGNAL i_loopback             : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL gnd                    : STD_LOGIC_VECTOR(79 DOWNTO 0);
   SIGNAL tx_send_idle           : STD_LOGIC;
   SIGNAL tx_send_lfi            : STD_LOGIC;
   SIGNAL tx_send_rfi            : STD_LOGIC;
   SIGNAL rx_remote_fault        : STD_LOGIC;
   SIGNAL rx_local_fault         : STD_LOGIC;
   SIGNAL rx_receive_local_fault : STD_LOGIC;
   SIGNAL i_rx_locked            : STD_LOGIC;
   SIGNAL i_user_tx_reset        : STD_LOGIC;
   SIGNAL i_user_rx_reset        : STD_LOGIC;
   SIGNAL i_tx_enable            : STD_LOGIC;
   SIGNAL i_rx_enable            : STD_LOGIC;
   SIGNAL rsfec_tx_enable        : STD_LOGIC;
   SIGNAL rsfec_rx_enable        : STD_LOGIC;
   SIGNAL i_tx_clk_out           : STD_LOGIC;

BEGIN


   gnd <= (OTHERS => '0');

   i_loopback(2 DOWNTO 0) <= loopback;
   i_loopback(5 DOWNTO 3) <= loopback;
   i_loopback(8 DOWNTO 6) <= loopback;
   i_loopback(11 DOWNTO 9) <= loopback;

   user_tx_reset <= i_user_tx_reset;
   user_rx_reset <= i_user_rx_reset;


   tx_clk_out <= i_tx_clk_out;

   rx_locked <= i_rx_locked AND NOT rx_remote_fault;

   tx_send_idle <= rx_receive_local_fault;                  -- Send idles if we detect remote error

tx_startup_fsm: PROCESS(i_tx_clk_out)
   BEGIN
      IF RISING_EDGE(i_tx_clk_out) THEN
         IF i_user_tx_reset = '1' THEN
            tx_send_rfi <= '0';
            tx_send_lfi <= '0';
            rsfec_tx_enable <= '0';
            i_tx_enable <= '0';
         ELSE
            IF i_rx_locked = '1' THEN
               tx_send_rfi <= '0';
               tx_send_lfi <= rx_local_fault;
               rsfec_tx_enable <= '1';
               i_tx_enable <= tx_enable;
            ELSE
               tx_send_rfi <= '1';
               tx_send_lfi <= '1';
               rsfec_tx_enable <= '1';
               i_tx_enable <= '0';
            END IF;
         END IF;
      END IF;
   END PROCESS;

rx_startup_fsm: PROCESS(rx_clk_in)
   BEGIN
      IF RISING_EDGE(rx_clk_in) THEN
         IF i_user_rx_reset = '1' THEN
            rsfec_rx_enable <= '0';
            i_rx_enable <= '0';
         ELSE
            rsfec_rx_enable <= '1';
            i_rx_enable <= rx_enable;
         END IF;
      END IF;
   END PROCESS;

gen_ip: IF tech_is_board(g_technology, c_tech_board_gemini_lru) OR tech_is_board(g_technology, c_tech_board_gemini_xh_lru) OR tech_is_board(g_technology, c_tech_board_vcu128) GENERATE

   quad124_gen: IF g_device = QUAD_100G_124 GENERATE

      mac_1: mac_100g_quad_124
      PORT MAP (
         gt0_rxp_in => gt_rxp_in(0), gt1_rxp_in => gt_rxp_in(1), gt2_rxp_in => gt_rxp_in(2), gt3_rxp_in => gt_rxp_in(3),
         gt0_rxn_in => gt_rxn_in(0), gt1_rxn_in => gt_rxn_in(1), gt2_rxn_in => gt_rxn_in(2), gt3_rxn_in => gt_rxn_in(3),
         gt0_txp_out => gt_txp_out(0), gt1_txp_out => gt_txp_out(1), gt2_txp_out => gt_txp_out(2), gt3_txp_out => gt_txp_out(3),
         gt0_txn_out => gt_txn_out(0), gt1_txn_out => gt_txn_out(1), gt2_txn_out => gt_txn_out(2), gt3_txn_out => gt_txn_out(3),
         gt_ref_clk_p => gt_refclk_p, gt_ref_clk_n => gt_refclk_n, gt_ref_clk_out => OPEN,

         sys_reset => sys_reset, core_drp_reset => '0', core_rx_reset => '0', core_tx_reset => '0',
         gt_rxresetdone => OPEN, gt_txresetdone => OPEN,

         drp_clk => '0', init_clk => dclk, gt_drpclk => dclk,
         gt_rxrecclkout => rx_clk_out, rx_clk => rx_clk_in, gt_txusrclk2 => i_tx_clk_out,

         gt_rxpolarity => g_rxpolarity, gt_txpolarity => g_txpolarity,
         gt_loopback_in => i_loopback,

         gt_eyescandataerror => OPEN,  gt_eyescanreset => X"0", gt_eyescantrigger => X"0",
         gt_rxbufstatus => OPEN, gt_rxcdrhold => X"0", gt_rxdfelpmreset => X"0", gt_rxlpmen => g_rxlpmen,
         gt_rxrate => X"000", gt_rxprbscntreset => X"0", gt_rxprbserr => OPEN, gt_rxprbssel => X"0000",
         gt_txbufstatus => OPEN, gt_txdiffctrl => c_txdiffctrl, gt_txinhibit => X"0", gt_txpostcursor => c_txpostcursor,
         gt_txprbsforceerr => X"0", gt_txprbssel => X"0000", gt_txprecursor => c_txprecursor,
         gtwiz_reset_tx_datapath => '0', gtwiz_reset_rx_datapath => '0',

         common0_drpaddr => X"0000", common0_drpdi => X"0000", common0_drpwe => '0',
         common0_drpen => '0', common0_drprdy => OPEN, common0_drpdo => OPEN,

         gt0_drpdo => OPEN, gt1_drpdo => OPEN, gt2_drpdo => OPEN, gt3_drpdo => OPEN,
         gt0_drprdy => OPEN, gt1_drprdy => OPEN, gt2_drprdy => OPEN, gt3_drprdy => OPEN,
         gt0_drpen => '0', gt1_drpen => '0', gt2_drpen => '0', gt3_drpen => '0',
         gt0_drpwe => '0', gt1_drpwe => '0', gt2_drpwe => '0', gt3_drpwe => '0',
         gt0_drpaddr => gnd(9 DOWNTO 0), gt1_drpaddr => gnd(9 DOWNTO 0), gt2_drpaddr => gnd(9 DOWNTO 0), gt3_drpaddr => gnd(9 DOWNTO 0),
         gt0_drpdi => X"0000", gt1_drpdi => X"0000", gt2_drpdi => X"0000", gt3_drpdi => X"0000",
         drp_addr => gnd(9 DOWNTO 0), drp_di => X"0000", drp_en => '0',
         drp_we => '0', drp_do => OPEN, drp_rdy => OPEN,

         gt_powergoodout => OPEN,

         ctl_tx_rsfec_enable => rsfec_tx_enable, ctl_rx_rsfec_enable => rsfec_rx_enable, ctl_rsfec_ieee_error_indication_mode => '1',
         ctl_rx_rsfec_enable_correction => '1', ctl_rx_rsfec_enable_indication => '1',

         usr_rx_reset => i_user_rx_reset,
         rx_dataout0 => data_rx_sosi.data(127 DOWNTO 0), rx_dataout1 => data_rx_sosi.data(255 DOWNTO 128),
         rx_dataout2 => data_rx_sosi.data(383 DOWNTO 256), rx_dataout3 => data_rx_sosi.data(511 DOWNTO 384),
         rx_enaout0 => data_rx_sosi.valid(0), rx_enaout1 => data_rx_sosi.valid(1), rx_enaout2 => data_rx_sosi.valid(2), rx_enaout3 => data_rx_sosi.valid(3),
         rx_eopout0 => data_rx_sosi.eop(0), rx_eopout1 => data_rx_sosi.eop(1), rx_eopout2 => data_rx_sosi.eop(2), rx_eopout3 => data_rx_sosi.eop(3),
         rx_errout0 => data_rx_sosi.error(0), rx_errout1 => data_rx_sosi.error(1), rx_errout2 => data_rx_sosi.error(2), rx_errout3 => data_rx_sosi.error(3),
         rx_mtyout0 => data_rx_sosi.empty(0), rx_mtyout1 => data_rx_sosi.empty(1), rx_mtyout2 => data_rx_sosi.empty(2), rx_mtyout3 => data_rx_sosi.empty(3),
         rx_sopout0 => data_rx_sosi.sop(0), rx_sopout1 => data_rx_sosi.sop(1), rx_sopout2 => data_rx_sosi.sop(2), rx_sopout3 => data_rx_sosi.sop(3),

         ctl_rx_enable => rx_enable, ctl_rx_force_resync => '0', ctl_rx_test_pattern => '0',
         stat_rx_local_fault => OPEN, stat_rx_block_lock => OPEN,
         rx_otn_bip8_0 => OPEN, rx_otn_bip8_1 => OPEN, rx_otn_bip8_2 => OPEN, rx_otn_bip8_3 => OPEN, rx_otn_bip8_4 => OPEN,
         rx_otn_data_0 => OPEN, rx_otn_data_1 => OPEN, rx_otn_data_2 => OPEN, rx_otn_data_3 => OPEN, rx_otn_data_4 => OPEN,
         rx_otn_ena => OPEN, rx_otn_lane0 => OPEN, rx_otn_vlmarker => OPEN,

         stat_rx_unicast => OPEN, stat_rx_vlan => OPEN, stat_rx_pcsl_demuxed => OPEN,
         stat_rx_rsfec_am_lock0 => OPEN, stat_rx_rsfec_am_lock1 => OPEN, stat_rx_rsfec_am_lock2 => OPEN, stat_rx_rsfec_am_lock3 => OPEN,
         stat_rx_rsfec_corrected_cw_inc => OPEN, stat_rx_rsfec_cw_inc => OPEN,
         stat_rx_rsfec_err_count0_inc => OPEN, stat_rx_rsfec_err_count1_inc => OPEN, stat_rx_rsfec_err_count2_inc => OPEN,
         stat_rx_rsfec_err_count3_inc => OPEN, stat_rx_rsfec_hi_ser => OPEN, stat_rx_rsfec_lane_alignment_status => OPEN,
         stat_rx_rsfec_lane_fill_0 => OPEN, stat_rx_rsfec_lane_fill_1 => OPEN, stat_rx_rsfec_lane_fill_2 => OPEN,
         stat_rx_rsfec_lane_fill_3 => OPEN, stat_rx_rsfec_lane_mapping => OPEN, stat_rx_rsfec_uncorrected_cw_inc => OPEN,
         stat_rx_status => OPEN, stat_rx_test_pattern_mismatch => OPEN,
         stat_rx_remote_fault => rx_remote_fault, stat_rx_bad_fcs => OPEN, stat_rx_stomped_fcs => OPEN, stat_rx_truncated => OPEN,
         stat_rx_internal_local_fault => rx_local_fault, stat_rx_received_local_fault => rx_receive_local_fault, stat_rx_hi_ber => OPEN, stat_rx_got_signal_os => OPEN,
         stat_rx_total_bytes => stat_rx_total_bytes, stat_rx_total_packets => stat_rx_total_packets, stat_rx_total_good_bytes => OPEN, stat_rx_total_good_packets => OPEN,
         stat_rx_packet_bad_fcs => stat_rx_bad_fcs, stat_rx_packet_64_bytes => OPEN, stat_rx_packet_65_127_bytes => OPEN, stat_rx_packet_128_255_bytes => OPEN,
         stat_rx_packet_256_511_bytes => OPEN, stat_rx_packet_512_1023_bytes => OPEN, stat_rx_packet_1024_1518_bytes => OPEN,
         stat_rx_packet_1519_1522_bytes => OPEN, stat_rx_packet_1523_1548_bytes => OPEN, stat_rx_packet_1549_2047_bytes => OPEN,
         stat_rx_packet_2048_4095_bytes => OPEN, stat_rx_packet_4096_8191_bytes => OPEN, stat_rx_packet_8192_9215_bytes => OPEN,
         stat_rx_packet_small => OPEN, stat_rx_packet_large => OPEN,  stat_rx_oversize => OPEN, stat_rx_toolong => OPEN, stat_rx_undersize => OPEN,
         stat_rx_fragment => OPEN, stat_rx_jabber => OPEN, stat_rx_bad_code => stat_rx_bad_code, stat_rx_bad_sfd => OPEN, stat_rx_bad_preamble => OPEN,
         stat_rx_pcsl_number_0 => OPEN, stat_rx_pcsl_number_1 => OPEN, stat_rx_pcsl_number_2 => OPEN, stat_rx_pcsl_number_3 => OPEN,
         stat_rx_pcsl_number_4 => OPEN, stat_rx_pcsl_number_5 => OPEN, stat_rx_pcsl_number_6 => OPEN, stat_rx_pcsl_number_7 => OPEN,
         stat_rx_pcsl_number_8 => OPEN, stat_rx_pcsl_number_9 => OPEN, stat_rx_pcsl_number_10 => OPEN, stat_rx_pcsl_number_11 => OPEN,
         stat_rx_pcsl_number_12 => OPEN, stat_rx_pcsl_number_13 => OPEN, stat_rx_pcsl_number_14 => OPEN, stat_rx_pcsl_number_15 => OPEN,
         stat_rx_pcsl_number_16 => OPEN, stat_rx_pcsl_number_17 => OPEN, stat_rx_pcsl_number_18 => OPEN, stat_rx_pcsl_number_19 => OPEN,
         stat_tx_broadcast => OPEN, stat_tx_multicast => OPEN, stat_tx_unicast => OPEN, stat_tx_vlan => OPEN,
         stat_rx_bip_err_0 => OPEN, stat_rx_bip_err_1 => OPEN, stat_rx_bip_err_2 => OPEN, stat_rx_bip_err_3 => OPEN,
         stat_rx_bip_err_4 => OPEN, stat_rx_bip_err_5 => OPEN, stat_rx_bip_err_6 => OPEN, stat_rx_bip_err_7 => OPEN,
         stat_rx_bip_err_8 => OPEN, stat_rx_bip_err_9 => OPEN, stat_rx_bip_err_10 => OPEN, stat_rx_bip_err_11 => OPEN,
         stat_rx_bip_err_12 => OPEN, stat_rx_bip_err_13 => OPEN, stat_rx_bip_err_14 => OPEN, stat_rx_bip_err_15 => OPEN,
         stat_rx_bip_err_16 => OPEN, stat_rx_bip_err_17 => OPEN, stat_rx_bip_err_18 => OPEN, stat_rx_bip_err_19 => OPEN,
         stat_rx_framing_err_0 => OPEN, stat_rx_framing_err_1 => OPEN, stat_rx_framing_err_2 => OPEN, stat_rx_framing_err_3 => OPEN,
         stat_rx_framing_err_4 => OPEN, stat_rx_framing_err_5 => OPEN, stat_rx_framing_err_6 => OPEN, stat_rx_framing_err_7 => OPEN,
         stat_rx_framing_err_8 => OPEN, stat_rx_framing_err_9 => OPEN, stat_rx_framing_err_10 => OPEN, stat_rx_framing_err_11 => OPEN,
         stat_rx_framing_err_12 => OPEN, stat_rx_framing_err_13 => OPEN, stat_rx_framing_err_14 => OPEN, stat_rx_framing_err_15 => OPEN,
         stat_rx_framing_err_16 => OPEN, stat_rx_framing_err_17 => OPEN, stat_rx_framing_err_18 => OPEN, stat_rx_framing_err_19 => OPEN,
         stat_rx_framing_err_valid_0 => OPEN, stat_rx_framing_err_valid_1 => OPEN, stat_rx_framing_err_valid_2 => OPEN,
         stat_rx_framing_err_valid_3 => OPEN, stat_rx_framing_err_valid_4 => OPEN, stat_rx_framing_err_valid_5 => OPEN,
         stat_rx_framing_err_valid_6 => OPEN, stat_rx_framing_err_valid_7 => OPEN, stat_rx_framing_err_valid_8 => OPEN,
         stat_rx_framing_err_valid_9 => OPEN, stat_rx_framing_err_valid_10 => OPEN, stat_rx_framing_err_valid_11 => OPEN,
         stat_rx_framing_err_valid_12 => OPEN, stat_rx_framing_err_valid_13 => OPEN, stat_rx_framing_err_valid_14 => OPEN,
         stat_rx_framing_err_valid_15 => OPEN, stat_rx_framing_err_valid_16 => OPEN, stat_rx_framing_err_valid_17 => OPEN,
         stat_rx_framing_err_valid_18 => OPEN, stat_rx_framing_err_valid_19 => OPEN, stat_rx_inrangeerr => OPEN, stat_rx_mf_err => OPEN,
         stat_rx_mf_len_err => OPEN, stat_rx_broadcast => OPEN, stat_rx_mf_repeat_err => OPEN, stat_rx_misaligned => OPEN,
         stat_rx_multicast => OPEN, stat_rx_aligned => i_rx_locked, stat_rx_aligned_err => OPEN,
         stat_rx_synced => OPEN, stat_rx_synced_err => OPEN,

         usr_tx_reset => i_user_tx_reset,
         tx_unfout => data_tx_siso.underflow, tx_ovfout => data_tx_siso.overflow, tx_rdyout => data_tx_siso.ready,
         tx_datain0 => data_tx_sosi.data(127 DOWNTO 0), tx_datain1 => data_tx_sosi.data(255 DOWNTO 128),
         tx_datain2 => data_tx_sosi.data(383 DOWNTO 256), tx_datain3 => data_tx_sosi.data(511 DOWNTO 384),
         tx_enain0 => data_tx_sosi.valid(0), tx_enain1 => data_tx_sosi.valid(1), tx_enain2 => data_tx_sosi.valid(2), tx_enain3 => data_tx_sosi.valid(3),
         tx_eopin0 => data_tx_sosi.eop(0), tx_eopin1 => data_tx_sosi.eop(1), tx_eopin2 => data_tx_sosi.eop(2), tx_eopin3 => data_tx_sosi.eop(3),
         tx_errin0 => data_tx_sosi.error(0), tx_errin1 => data_tx_sosi.error(1), tx_errin2 => data_tx_sosi.error(2), tx_errin3 => data_tx_sosi.error(3),
         tx_mtyin0 => data_tx_sosi.empty(0), tx_mtyin1 => data_tx_sosi.empty(1), tx_mtyin2 => data_tx_sosi.empty(2), tx_mtyin3 => data_tx_sosi.empty(3),
         tx_sopin0 => data_tx_sosi.sop(0), tx_sopin1 => data_tx_sosi.sop(1), tx_sopin2 => data_tx_sosi.sop(2), tx_sopin3 => data_tx_sosi.sop(3),

         tx_preamblein => gnd(55 DOWNTO 0), rx_preambleout => OPEN, stat_tx_local_fault => OPEN,
         stat_tx_total_bytes => stat_tx_total_bytes, stat_tx_total_packets => stat_tx_total_packets, stat_tx_total_good_bytes => OPEN, stat_tx_total_good_packets => OPEN,
         stat_tx_bad_fcs => OPEN, stat_tx_packet_64_bytes => OPEN, stat_tx_packet_65_127_bytes => OPEN, stat_tx_packet_128_255_bytes => OPEN,
         stat_tx_packet_256_511_bytes => OPEN, stat_tx_packet_512_1023_bytes => OPEN, stat_tx_packet_1024_1518_bytes => OPEN,
         stat_tx_packet_1519_1522_bytes => OPEN, stat_tx_packet_1523_1548_bytes => OPEN, stat_tx_packet_1549_2047_bytes => OPEN,
         stat_tx_packet_2048_4095_bytes => OPEN, stat_tx_packet_4096_8191_bytes => OPEN,stat_tx_packet_8192_9215_bytes => OPEN,
         stat_tx_packet_small => OPEN, stat_tx_packet_large => OPEN, stat_tx_frame_error => OPEN,

         ctl_tx_enable => i_tx_enable, ctl_tx_send_rfi => tx_send_rfi,  ctl_tx_send_lfi => tx_send_lfi,  ctl_tx_send_idle => tx_send_idle,
         ctl_tx_test_pattern => '0');

   END GENERATE;

   quad125_gen: IF g_device = QUAD_100G_125 GENERATE

      mac_1: mac_100g_quad_125
      PORT MAP (
         gt0_rxp_in => gt_rxp_in(0), gt1_rxp_in => gt_rxp_in(1), gt2_rxp_in => gt_rxp_in(2), gt3_rxp_in => gt_rxp_in(3),
         gt0_rxn_in => gt_rxn_in(0), gt1_rxn_in => gt_rxn_in(1), gt2_rxn_in => gt_rxn_in(2), gt3_rxn_in => gt_rxn_in(3),
         gt0_txp_out => gt_txp_out(0), gt1_txp_out => gt_txp_out(1), gt2_txp_out => gt_txp_out(2), gt3_txp_out => gt_txp_out(3),
         gt0_txn_out => gt_txn_out(0), gt1_txn_out => gt_txn_out(1), gt2_txn_out => gt_txn_out(2), gt3_txn_out => gt_txn_out(3),
         gt_ref_clk_p => gt_refclk_p, gt_ref_clk_n => gt_refclk_n, gt_ref_clk_out => OPEN,

         sys_reset => sys_reset, core_drp_reset => '0', core_rx_reset => '0', core_tx_reset => '0',
         gt_rxresetdone => OPEN, gt_txresetdone => OPEN,

         drp_clk => '0', init_clk => dclk, gt_drpclk => dclk,
         gt_rxrecclkout => rx_clk_out, rx_clk => rx_clk_in, gt_txusrclk2 => i_tx_clk_out,

         gt_rxpolarity => g_rxpolarity, gt_txpolarity => g_txpolarity,
         gt_loopback_in => i_loopback,

         gt_eyescandataerror => OPEN,  gt_eyescanreset => X"0", gt_eyescantrigger => X"0",
         gt_rxbufstatus => OPEN, gt_rxcdrhold => X"0", gt_rxdfelpmreset => X"0", gt_rxlpmen => g_rxlpmen,
         gt_rxrate => X"000", gt_rxprbscntreset => X"0", gt_rxprbserr => OPEN, gt_rxprbssel => X"0000",
         gt_txbufstatus => OPEN, gt_txdiffctrl => c_txdiffctrl, gt_txinhibit => X"0", gt_txpostcursor => c_txpostcursor,
         gt_txprbsforceerr => X"0", gt_txprbssel => X"0000", gt_txprecursor => c_txprecursor,
         gtwiz_reset_tx_datapath => '0', gtwiz_reset_rx_datapath => '0',

         common0_drpaddr => X"0000", common0_drpdi => X"0000", common0_drpwe => '0',
         common0_drpen => '0', common0_drprdy => OPEN, common0_drpdo => OPEN,

         gt0_drpdo => OPEN, gt1_drpdo => OPEN, gt2_drpdo => OPEN, gt3_drpdo => OPEN,
         gt0_drprdy => OPEN, gt1_drprdy => OPEN, gt2_drprdy => OPEN, gt3_drprdy => OPEN,
         gt0_drpen => '0', gt1_drpen => '0', gt2_drpen => '0', gt3_drpen => '0',
         gt0_drpwe => '0', gt1_drpwe => '0', gt2_drpwe => '0', gt3_drpwe => '0',
         gt0_drpaddr => gnd(9 DOWNTO 0), gt1_drpaddr => gnd(9 DOWNTO 0), gt2_drpaddr => gnd(9 DOWNTO 0), gt3_drpaddr => gnd(9 DOWNTO 0),
         gt0_drpdi => X"0000", gt1_drpdi => X"0000", gt2_drpdi => X"0000", gt3_drpdi => X"0000",
         drp_addr => gnd(9 DOWNTO 0), drp_di => X"0000", drp_en => '0',
         drp_we => '0', drp_do => OPEN, drp_rdy => OPEN,

         gt_powergoodout => OPEN,

         ctl_tx_rsfec_enable => rsfec_tx_enable, ctl_rx_rsfec_enable => rsfec_rx_enable, ctl_rsfec_ieee_error_indication_mode => '1',
         ctl_rx_rsfec_enable_correction => '1', ctl_rx_rsfec_enable_indication => '1',

         usr_rx_reset => i_user_rx_reset,
         rx_dataout0 => data_rx_sosi.data(127 DOWNTO 0), rx_dataout1 => data_rx_sosi.data(255 DOWNTO 128),
         rx_dataout2 => data_rx_sosi.data(383 DOWNTO 256), rx_dataout3 => data_rx_sosi.data(511 DOWNTO 384),
         rx_enaout0 => data_rx_sosi.valid(0), rx_enaout1 => data_rx_sosi.valid(1), rx_enaout2 => data_rx_sosi.valid(2), rx_enaout3 => data_rx_sosi.valid(3),
         rx_eopout0 => data_rx_sosi.eop(0), rx_eopout1 => data_rx_sosi.eop(1), rx_eopout2 => data_rx_sosi.eop(2), rx_eopout3 => data_rx_sosi.eop(3),
         rx_errout0 => data_rx_sosi.error(0), rx_errout1 => data_rx_sosi.error(1), rx_errout2 => data_rx_sosi.error(2), rx_errout3 => data_rx_sosi.error(3),
         rx_mtyout0 => data_rx_sosi.empty(0), rx_mtyout1 => data_rx_sosi.empty(1), rx_mtyout2 => data_rx_sosi.empty(2), rx_mtyout3 => data_rx_sosi.empty(3),
         rx_sopout0 => data_rx_sosi.sop(0), rx_sopout1 => data_rx_sosi.sop(1), rx_sopout2 => data_rx_sosi.sop(2), rx_sopout3 => data_rx_sosi.sop(3),

         ctl_rx_enable => rx_enable, ctl_rx_force_resync => '0', ctl_rx_test_pattern => '0',
         stat_rx_local_fault => OPEN, stat_rx_block_lock => OPEN,
         rx_otn_bip8_0 => OPEN, rx_otn_bip8_1 => OPEN, rx_otn_bip8_2 => OPEN, rx_otn_bip8_3 => OPEN, rx_otn_bip8_4 => OPEN,
         rx_otn_data_0 => OPEN, rx_otn_data_1 => OPEN, rx_otn_data_2 => OPEN, rx_otn_data_3 => OPEN, rx_otn_data_4 => OPEN,
         rx_otn_ena => OPEN, rx_otn_lane0 => OPEN, rx_otn_vlmarker => OPEN,

         stat_rx_unicast => OPEN, stat_rx_vlan => OPEN, stat_rx_pcsl_demuxed => OPEN,
         stat_rx_rsfec_am_lock0 => OPEN, stat_rx_rsfec_am_lock1 => OPEN, stat_rx_rsfec_am_lock2 => OPEN, stat_rx_rsfec_am_lock3 => OPEN,
         stat_rx_rsfec_corrected_cw_inc => OPEN, stat_rx_rsfec_cw_inc => OPEN,
         stat_rx_rsfec_err_count0_inc => OPEN, stat_rx_rsfec_err_count1_inc => OPEN, stat_rx_rsfec_err_count2_inc => OPEN,
         stat_rx_rsfec_err_count3_inc => OPEN, stat_rx_rsfec_hi_ser => OPEN, stat_rx_rsfec_lane_alignment_status => OPEN,
         stat_rx_rsfec_lane_fill_0 => OPEN, stat_rx_rsfec_lane_fill_1 => OPEN, stat_rx_rsfec_lane_fill_2 => OPEN,
         stat_rx_rsfec_lane_fill_3 => OPEN, stat_rx_rsfec_lane_mapping => OPEN, stat_rx_rsfec_uncorrected_cw_inc => OPEN,
         stat_rx_status => OPEN, stat_rx_test_pattern_mismatch => OPEN,
         stat_rx_remote_fault => rx_remote_fault, stat_rx_bad_fcs => OPEN, stat_rx_stomped_fcs => OPEN, stat_rx_truncated => OPEN,
         stat_rx_internal_local_fault => rx_local_fault, stat_rx_received_local_fault => rx_receive_local_fault, stat_rx_hi_ber => OPEN, stat_rx_got_signal_os => OPEN,
         stat_rx_total_bytes => stat_rx_total_bytes, stat_rx_total_packets => stat_rx_total_packets, stat_rx_total_good_bytes => OPEN, stat_rx_total_good_packets => OPEN,
         stat_rx_packet_bad_fcs => stat_rx_bad_fcs, stat_rx_packet_64_bytes => OPEN, stat_rx_packet_65_127_bytes => OPEN, stat_rx_packet_128_255_bytes => OPEN,
         stat_rx_packet_256_511_bytes => OPEN, stat_rx_packet_512_1023_bytes => OPEN, stat_rx_packet_1024_1518_bytes => OPEN,
         stat_rx_packet_1519_1522_bytes => OPEN, stat_rx_packet_1523_1548_bytes => OPEN, stat_rx_packet_1549_2047_bytes => OPEN,
         stat_rx_packet_2048_4095_bytes => OPEN, stat_rx_packet_4096_8191_bytes => OPEN, stat_rx_packet_8192_9215_bytes => OPEN,
         stat_rx_packet_small => OPEN, stat_rx_packet_large => OPEN,  stat_rx_oversize => OPEN, stat_rx_toolong => OPEN, stat_rx_undersize => OPEN,
         stat_rx_fragment => OPEN, stat_rx_jabber => OPEN, stat_rx_bad_code => stat_rx_bad_code, stat_rx_bad_sfd => OPEN, stat_rx_bad_preamble => OPEN,
         stat_rx_pcsl_number_0 => OPEN, stat_rx_pcsl_number_1 => OPEN, stat_rx_pcsl_number_2 => OPEN, stat_rx_pcsl_number_3 => OPEN,
         stat_rx_pcsl_number_4 => OPEN, stat_rx_pcsl_number_5 => OPEN, stat_rx_pcsl_number_6 => OPEN, stat_rx_pcsl_number_7 => OPEN,
         stat_rx_pcsl_number_8 => OPEN, stat_rx_pcsl_number_9 => OPEN, stat_rx_pcsl_number_10 => OPEN, stat_rx_pcsl_number_11 => OPEN,
         stat_rx_pcsl_number_12 => OPEN, stat_rx_pcsl_number_13 => OPEN, stat_rx_pcsl_number_14 => OPEN, stat_rx_pcsl_number_15 => OPEN,
         stat_rx_pcsl_number_16 => OPEN, stat_rx_pcsl_number_17 => OPEN, stat_rx_pcsl_number_18 => OPEN, stat_rx_pcsl_number_19 => OPEN,
         stat_tx_broadcast => OPEN, stat_tx_multicast => OPEN, stat_tx_unicast => OPEN, stat_tx_vlan => OPEN,
         stat_rx_bip_err_0 => OPEN, stat_rx_bip_err_1 => OPEN, stat_rx_bip_err_2 => OPEN, stat_rx_bip_err_3 => OPEN,
         stat_rx_bip_err_4 => OPEN, stat_rx_bip_err_5 => OPEN, stat_rx_bip_err_6 => OPEN, stat_rx_bip_err_7 => OPEN,
         stat_rx_bip_err_8 => OPEN, stat_rx_bip_err_9 => OPEN, stat_rx_bip_err_10 => OPEN, stat_rx_bip_err_11 => OPEN,
         stat_rx_bip_err_12 => OPEN, stat_rx_bip_err_13 => OPEN, stat_rx_bip_err_14 => OPEN, stat_rx_bip_err_15 => OPEN,
         stat_rx_bip_err_16 => OPEN, stat_rx_bip_err_17 => OPEN, stat_rx_bip_err_18 => OPEN, stat_rx_bip_err_19 => OPEN,
         stat_rx_framing_err_0 => OPEN, stat_rx_framing_err_1 => OPEN, stat_rx_framing_err_2 => OPEN, stat_rx_framing_err_3 => OPEN,
         stat_rx_framing_err_4 => OPEN, stat_rx_framing_err_5 => OPEN, stat_rx_framing_err_6 => OPEN, stat_rx_framing_err_7 => OPEN,
         stat_rx_framing_err_8 => OPEN, stat_rx_framing_err_9 => OPEN, stat_rx_framing_err_10 => OPEN, stat_rx_framing_err_11 => OPEN,
         stat_rx_framing_err_12 => OPEN, stat_rx_framing_err_13 => OPEN, stat_rx_framing_err_14 => OPEN, stat_rx_framing_err_15 => OPEN,
         stat_rx_framing_err_16 => OPEN, stat_rx_framing_err_17 => OPEN, stat_rx_framing_err_18 => OPEN, stat_rx_framing_err_19 => OPEN,
         stat_rx_framing_err_valid_0 => OPEN, stat_rx_framing_err_valid_1 => OPEN, stat_rx_framing_err_valid_2 => OPEN,
         stat_rx_framing_err_valid_3 => OPEN, stat_rx_framing_err_valid_4 => OPEN, stat_rx_framing_err_valid_5 => OPEN,
         stat_rx_framing_err_valid_6 => OPEN, stat_rx_framing_err_valid_7 => OPEN, stat_rx_framing_err_valid_8 => OPEN,
         stat_rx_framing_err_valid_9 => OPEN, stat_rx_framing_err_valid_10 => OPEN, stat_rx_framing_err_valid_11 => OPEN,
         stat_rx_framing_err_valid_12 => OPEN, stat_rx_framing_err_valid_13 => OPEN, stat_rx_framing_err_valid_14 => OPEN,
         stat_rx_framing_err_valid_15 => OPEN, stat_rx_framing_err_valid_16 => OPEN, stat_rx_framing_err_valid_17 => OPEN,
         stat_rx_framing_err_valid_18 => OPEN, stat_rx_framing_err_valid_19 => OPEN, stat_rx_inrangeerr => OPEN, stat_rx_mf_err => OPEN,
         stat_rx_mf_len_err => OPEN, stat_rx_broadcast => OPEN, stat_rx_mf_repeat_err => OPEN, stat_rx_misaligned => OPEN,
         stat_rx_multicast => OPEN, stat_rx_aligned => i_rx_locked, stat_rx_aligned_err => OPEN,
         stat_rx_synced => OPEN, stat_rx_synced_err => OPEN,

         usr_tx_reset => i_user_tx_reset,
         tx_unfout => data_tx_siso.underflow, tx_ovfout => data_tx_siso.overflow, tx_rdyout => data_tx_siso.ready,
         tx_datain0 => data_tx_sosi.data(127 DOWNTO 0), tx_datain1 => data_tx_sosi.data(255 DOWNTO 128),
         tx_datain2 => data_tx_sosi.data(383 DOWNTO 256), tx_datain3 => data_tx_sosi.data(511 DOWNTO 384),
         tx_enain0 => data_tx_sosi.valid(0), tx_enain1 => data_tx_sosi.valid(1), tx_enain2 => data_tx_sosi.valid(2), tx_enain3 => data_tx_sosi.valid(3),
         tx_eopin0 => data_tx_sosi.eop(0), tx_eopin1 => data_tx_sosi.eop(1), tx_eopin2 => data_tx_sosi.eop(2), tx_eopin3 => data_tx_sosi.eop(3),
         tx_errin0 => data_tx_sosi.error(0), tx_errin1 => data_tx_sosi.error(1), tx_errin2 => data_tx_sosi.error(2), tx_errin3 => data_tx_sosi.error(3),
         tx_mtyin0 => data_tx_sosi.empty(0), tx_mtyin1 => data_tx_sosi.empty(1), tx_mtyin2 => data_tx_sosi.empty(2), tx_mtyin3 => data_tx_sosi.empty(3),
         tx_sopin0 => data_tx_sosi.sop(0), tx_sopin1 => data_tx_sosi.sop(1), tx_sopin2 => data_tx_sosi.sop(2), tx_sopin3 => data_tx_sosi.sop(3),

         tx_preamblein => gnd(55 DOWNTO 0), rx_preambleout => OPEN, stat_tx_local_fault => OPEN,
         stat_tx_total_bytes => stat_tx_total_bytes, stat_tx_total_packets => stat_tx_total_packets, stat_tx_total_good_bytes => OPEN, stat_tx_total_good_packets => OPEN,
         stat_tx_bad_fcs => OPEN, stat_tx_packet_64_bytes => OPEN, stat_tx_packet_65_127_bytes => OPEN, stat_tx_packet_128_255_bytes => OPEN,
         stat_tx_packet_256_511_bytes => OPEN, stat_tx_packet_512_1023_bytes => OPEN, stat_tx_packet_1024_1518_bytes => OPEN,
         stat_tx_packet_1519_1522_bytes => OPEN, stat_tx_packet_1523_1548_bytes => OPEN, stat_tx_packet_1549_2047_bytes => OPEN,
         stat_tx_packet_2048_4095_bytes => OPEN, stat_tx_packet_4096_8191_bytes => OPEN,stat_tx_packet_8192_9215_bytes => OPEN,
         stat_tx_packet_small => OPEN, stat_tx_packet_large => OPEN, stat_tx_frame_error => OPEN,

         ctl_tx_enable => i_tx_enable, ctl_tx_send_rfi => tx_send_rfi,  ctl_tx_send_lfi => tx_send_lfi,  ctl_tx_send_idle => tx_send_idle,
         ctl_tx_test_pattern => '0');

   END GENERATE;

   quad126_gen: IF g_device = QUAD_100G_126 GENERATE

      mac_1: mac_100g_quad_126
      PORT MAP (
         gt0_rxp_in => gt_rxp_in(0), gt1_rxp_in => gt_rxp_in(1), gt2_rxp_in => gt_rxp_in(2), gt3_rxp_in => gt_rxp_in(3),
         gt0_rxn_in => gt_rxn_in(0), gt1_rxn_in => gt_rxn_in(1), gt2_rxn_in => gt_rxn_in(2), gt3_rxn_in => gt_rxn_in(3),
         gt0_txp_out => gt_txp_out(0), gt1_txp_out => gt_txp_out(1), gt2_txp_out => gt_txp_out(2), gt3_txp_out => gt_txp_out(3),
         gt0_txn_out => gt_txn_out(0), gt1_txn_out => gt_txn_out(1), gt2_txn_out => gt_txn_out(2), gt3_txn_out => gt_txn_out(3),
         gt_ref_clk_p => gt_refclk_p, gt_ref_clk_n => gt_refclk_n, gt_ref_clk_out => OPEN,

         sys_reset => sys_reset, core_drp_reset => '0', core_rx_reset => '0', core_tx_reset => '0',
         gt_rxresetdone => OPEN, gt_txresetdone => OPEN,

         drp_clk => '0', init_clk => dclk, gt_drpclk => dclk,
         gt_rxrecclkout => rx_clk_out, rx_clk => rx_clk_in, gt_txusrclk2 => i_tx_clk_out,

         gt_rxpolarity => g_rxpolarity, gt_txpolarity => g_txpolarity,
         gt_loopback_in => i_loopback,

         gt_eyescandataerror => OPEN,  gt_eyescanreset => X"0", gt_eyescantrigger => X"0",
         gt_rxbufstatus => OPEN, gt_rxcdrhold => X"0", gt_rxdfelpmreset => X"0", gt_rxlpmen => g_rxlpmen,
         gt_rxrate => X"000", gt_rxprbscntreset => X"0", gt_rxprbserr => OPEN, gt_rxprbssel => X"0000",
         gt_txbufstatus => OPEN, gt_txdiffctrl => c_txdiffctrl, gt_txinhibit => X"0", gt_txpostcursor => c_txpostcursor,
         gt_txprbsforceerr => X"0", gt_txprbssel => X"0000", gt_txprecursor => c_txprecursor,
         gtwiz_reset_tx_datapath => '0', gtwiz_reset_rx_datapath => '0',

         common0_drpaddr => X"0000", common0_drpdi => X"0000", common0_drpwe => '0',
         common0_drpen => '0', common0_drprdy => OPEN, common0_drpdo => OPEN,

         gt0_drpdo => OPEN, gt1_drpdo => OPEN, gt2_drpdo => OPEN, gt3_drpdo => OPEN,
         gt0_drprdy => OPEN, gt1_drprdy => OPEN, gt2_drprdy => OPEN, gt3_drprdy => OPEN,
         gt0_drpen => '0', gt1_drpen => '0', gt2_drpen => '0', gt3_drpen => '0',
         gt0_drpwe => '0', gt1_drpwe => '0', gt2_drpwe => '0', gt3_drpwe => '0',
         gt0_drpaddr => gnd(9 DOWNTO 0), gt1_drpaddr => gnd(9 DOWNTO 0), gt2_drpaddr => gnd(9 DOWNTO 0), gt3_drpaddr => gnd(9 DOWNTO 0),
         gt0_drpdi => X"0000", gt1_drpdi => X"0000", gt2_drpdi => X"0000", gt3_drpdi => X"0000",
         drp_addr => gnd(9 DOWNTO 0), drp_di => X"0000", drp_en => '0',
         drp_we => '0', drp_do => OPEN, drp_rdy => OPEN,

         gt_powergoodout => OPEN,

         ctl_tx_rsfec_enable => rsfec_tx_enable, ctl_rx_rsfec_enable => rsfec_rx_enable, ctl_rsfec_ieee_error_indication_mode => '1',
         ctl_rx_rsfec_enable_correction => '1', ctl_rx_rsfec_enable_indication => '1',

         usr_rx_reset => i_user_rx_reset,
         rx_dataout0 => data_rx_sosi.data(127 DOWNTO 0), rx_dataout1 => data_rx_sosi.data(255 DOWNTO 128),
         rx_dataout2 => data_rx_sosi.data(383 DOWNTO 256), rx_dataout3 => data_rx_sosi.data(511 DOWNTO 384),
         rx_enaout0 => data_rx_sosi.valid(0), rx_enaout1 => data_rx_sosi.valid(1), rx_enaout2 => data_rx_sosi.valid(2), rx_enaout3 => data_rx_sosi.valid(3),
         rx_eopout0 => data_rx_sosi.eop(0), rx_eopout1 => data_rx_sosi.eop(1), rx_eopout2 => data_rx_sosi.eop(2), rx_eopout3 => data_rx_sosi.eop(3),
         rx_errout0 => data_rx_sosi.error(0), rx_errout1 => data_rx_sosi.error(1), rx_errout2 => data_rx_sosi.error(2), rx_errout3 => data_rx_sosi.error(3),
         rx_mtyout0 => data_rx_sosi.empty(0), rx_mtyout1 => data_rx_sosi.empty(1), rx_mtyout2 => data_rx_sosi.empty(2), rx_mtyout3 => data_rx_sosi.empty(3),
         rx_sopout0 => data_rx_sosi.sop(0), rx_sopout1 => data_rx_sosi.sop(1), rx_sopout2 => data_rx_sosi.sop(2), rx_sopout3 => data_rx_sosi.sop(3),

         ctl_rx_enable => rx_enable, ctl_rx_force_resync => '0', ctl_rx_test_pattern => '0',
         stat_rx_local_fault => OPEN, stat_rx_block_lock => OPEN,
         rx_otn_bip8_0 => OPEN, rx_otn_bip8_1 => OPEN, rx_otn_bip8_2 => OPEN, rx_otn_bip8_3 => OPEN, rx_otn_bip8_4 => OPEN,
         rx_otn_data_0 => OPEN, rx_otn_data_1 => OPEN, rx_otn_data_2 => OPEN, rx_otn_data_3 => OPEN, rx_otn_data_4 => OPEN,
         rx_otn_ena => OPEN, rx_otn_lane0 => OPEN, rx_otn_vlmarker => OPEN,

         stat_rx_unicast => OPEN, stat_rx_vlan => OPEN, stat_rx_pcsl_demuxed => OPEN,
         stat_rx_rsfec_am_lock0 => OPEN, stat_rx_rsfec_am_lock1 => OPEN, stat_rx_rsfec_am_lock2 => OPEN, stat_rx_rsfec_am_lock3 => OPEN,
         stat_rx_rsfec_corrected_cw_inc => OPEN, stat_rx_rsfec_cw_inc => OPEN,
         stat_rx_rsfec_err_count0_inc => OPEN, stat_rx_rsfec_err_count1_inc => OPEN, stat_rx_rsfec_err_count2_inc => OPEN,
         stat_rx_rsfec_err_count3_inc => OPEN, stat_rx_rsfec_hi_ser => OPEN, stat_rx_rsfec_lane_alignment_status => OPEN,
         stat_rx_rsfec_lane_fill_0 => OPEN, stat_rx_rsfec_lane_fill_1 => OPEN, stat_rx_rsfec_lane_fill_2 => OPEN,
         stat_rx_rsfec_lane_fill_3 => OPEN, stat_rx_rsfec_lane_mapping => OPEN, stat_rx_rsfec_uncorrected_cw_inc => OPEN,
         stat_rx_status => OPEN, stat_rx_test_pattern_mismatch => OPEN,
         stat_rx_remote_fault => rx_remote_fault, stat_rx_bad_fcs => OPEN, stat_rx_stomped_fcs => OPEN, stat_rx_truncated => OPEN,
         stat_rx_internal_local_fault => rx_local_fault, stat_rx_received_local_fault => rx_receive_local_fault, stat_rx_hi_ber => OPEN, stat_rx_got_signal_os => OPEN,
         stat_rx_total_bytes => stat_rx_total_bytes, stat_rx_total_packets => stat_rx_total_packets, stat_rx_total_good_bytes => OPEN, stat_rx_total_good_packets => OPEN,
         stat_rx_packet_bad_fcs => stat_rx_bad_fcs, stat_rx_packet_64_bytes => OPEN, stat_rx_packet_65_127_bytes => OPEN, stat_rx_packet_128_255_bytes => OPEN,
         stat_rx_packet_256_511_bytes => OPEN, stat_rx_packet_512_1023_bytes => OPEN, stat_rx_packet_1024_1518_bytes => OPEN,
         stat_rx_packet_1519_1522_bytes => OPEN, stat_rx_packet_1523_1548_bytes => OPEN, stat_rx_packet_1549_2047_bytes => OPEN,
         stat_rx_packet_2048_4095_bytes => OPEN, stat_rx_packet_4096_8191_bytes => OPEN, stat_rx_packet_8192_9215_bytes => OPEN,
         stat_rx_packet_small => OPEN, stat_rx_packet_large => OPEN,  stat_rx_oversize => OPEN, stat_rx_toolong => OPEN, stat_rx_undersize => OPEN,
         stat_rx_fragment => OPEN, stat_rx_jabber => OPEN, stat_rx_bad_code => stat_rx_bad_code, stat_rx_bad_sfd => OPEN, stat_rx_bad_preamble => OPEN,
         stat_rx_pcsl_number_0 => OPEN, stat_rx_pcsl_number_1 => OPEN, stat_rx_pcsl_number_2 => OPEN, stat_rx_pcsl_number_3 => OPEN,
         stat_rx_pcsl_number_4 => OPEN, stat_rx_pcsl_number_5 => OPEN, stat_rx_pcsl_number_6 => OPEN, stat_rx_pcsl_number_7 => OPEN,
         stat_rx_pcsl_number_8 => OPEN, stat_rx_pcsl_number_9 => OPEN, stat_rx_pcsl_number_10 => OPEN, stat_rx_pcsl_number_11 => OPEN,
         stat_rx_pcsl_number_12 => OPEN, stat_rx_pcsl_number_13 => OPEN, stat_rx_pcsl_number_14 => OPEN, stat_rx_pcsl_number_15 => OPEN,
         stat_rx_pcsl_number_16 => OPEN, stat_rx_pcsl_number_17 => OPEN, stat_rx_pcsl_number_18 => OPEN, stat_rx_pcsl_number_19 => OPEN,
         stat_tx_broadcast => OPEN, stat_tx_multicast => OPEN, stat_tx_unicast => OPEN, stat_tx_vlan => OPEN,
         stat_rx_bip_err_0 => OPEN, stat_rx_bip_err_1 => OPEN, stat_rx_bip_err_2 => OPEN, stat_rx_bip_err_3 => OPEN,
         stat_rx_bip_err_4 => OPEN, stat_rx_bip_err_5 => OPEN, stat_rx_bip_err_6 => OPEN, stat_rx_bip_err_7 => OPEN,
         stat_rx_bip_err_8 => OPEN, stat_rx_bip_err_9 => OPEN, stat_rx_bip_err_10 => OPEN, stat_rx_bip_err_11 => OPEN,
         stat_rx_bip_err_12 => OPEN, stat_rx_bip_err_13 => OPEN, stat_rx_bip_err_14 => OPEN, stat_rx_bip_err_15 => OPEN,
         stat_rx_bip_err_16 => OPEN, stat_rx_bip_err_17 => OPEN, stat_rx_bip_err_18 => OPEN, stat_rx_bip_err_19 => OPEN,
         stat_rx_framing_err_0 => OPEN, stat_rx_framing_err_1 => OPEN, stat_rx_framing_err_2 => OPEN, stat_rx_framing_err_3 => OPEN,
         stat_rx_framing_err_4 => OPEN, stat_rx_framing_err_5 => OPEN, stat_rx_framing_err_6 => OPEN, stat_rx_framing_err_7 => OPEN,
         stat_rx_framing_err_8 => OPEN, stat_rx_framing_err_9 => OPEN, stat_rx_framing_err_10 => OPEN, stat_rx_framing_err_11 => OPEN,
         stat_rx_framing_err_12 => OPEN, stat_rx_framing_err_13 => OPEN, stat_rx_framing_err_14 => OPEN, stat_rx_framing_err_15 => OPEN,
         stat_rx_framing_err_16 => OPEN, stat_rx_framing_err_17 => OPEN, stat_rx_framing_err_18 => OPEN, stat_rx_framing_err_19 => OPEN,
         stat_rx_framing_err_valid_0 => OPEN, stat_rx_framing_err_valid_1 => OPEN, stat_rx_framing_err_valid_2 => OPEN,
         stat_rx_framing_err_valid_3 => OPEN, stat_rx_framing_err_valid_4 => OPEN, stat_rx_framing_err_valid_5 => OPEN,
         stat_rx_framing_err_valid_6 => OPEN, stat_rx_framing_err_valid_7 => OPEN, stat_rx_framing_err_valid_8 => OPEN,
         stat_rx_framing_err_valid_9 => OPEN, stat_rx_framing_err_valid_10 => OPEN, stat_rx_framing_err_valid_11 => OPEN,
         stat_rx_framing_err_valid_12 => OPEN, stat_rx_framing_err_valid_13 => OPEN, stat_rx_framing_err_valid_14 => OPEN,
         stat_rx_framing_err_valid_15 => OPEN, stat_rx_framing_err_valid_16 => OPEN, stat_rx_framing_err_valid_17 => OPEN,
         stat_rx_framing_err_valid_18 => OPEN, stat_rx_framing_err_valid_19 => OPEN, stat_rx_inrangeerr => OPEN, stat_rx_mf_err => OPEN,
         stat_rx_mf_len_err => OPEN, stat_rx_broadcast => OPEN, stat_rx_mf_repeat_err => OPEN, stat_rx_misaligned => OPEN,
         stat_rx_multicast => OPEN, stat_rx_aligned => i_rx_locked, stat_rx_aligned_err => OPEN,
         stat_rx_synced => OPEN, stat_rx_synced_err => OPEN,

         usr_tx_reset => i_user_tx_reset,
         tx_unfout => data_tx_siso.underflow, tx_ovfout => data_tx_siso.overflow, tx_rdyout => data_tx_siso.ready,
         tx_datain0 => data_tx_sosi.data(127 DOWNTO 0), tx_datain1 => data_tx_sosi.data(255 DOWNTO 128),
         tx_datain2 => data_tx_sosi.data(383 DOWNTO 256), tx_datain3 => data_tx_sosi.data(511 DOWNTO 384),
         tx_enain0 => data_tx_sosi.valid(0), tx_enain1 => data_tx_sosi.valid(1), tx_enain2 => data_tx_sosi.valid(2), tx_enain3 => data_tx_sosi.valid(3),
         tx_eopin0 => data_tx_sosi.eop(0), tx_eopin1 => data_tx_sosi.eop(1), tx_eopin2 => data_tx_sosi.eop(2), tx_eopin3 => data_tx_sosi.eop(3),
         tx_errin0 => data_tx_sosi.error(0), tx_errin1 => data_tx_sosi.error(1), tx_errin2 => data_tx_sosi.error(2), tx_errin3 => data_tx_sosi.error(3),
         tx_mtyin0 => data_tx_sosi.empty(0), tx_mtyin1 => data_tx_sosi.empty(1), tx_mtyin2 => data_tx_sosi.empty(2), tx_mtyin3 => data_tx_sosi.empty(3),
         tx_sopin0 => data_tx_sosi.sop(0), tx_sopin1 => data_tx_sosi.sop(1), tx_sopin2 => data_tx_sosi.sop(2), tx_sopin3 => data_tx_sosi.sop(3),

         tx_preamblein => gnd(55 DOWNTO 0), rx_preambleout => OPEN, stat_tx_local_fault => OPEN,
         stat_tx_total_bytes => stat_tx_total_bytes, stat_tx_total_packets => stat_tx_total_packets, stat_tx_total_good_bytes => OPEN, stat_tx_total_good_packets => OPEN,
         stat_tx_bad_fcs => OPEN, stat_tx_packet_64_bytes => OPEN, stat_tx_packet_65_127_bytes => OPEN, stat_tx_packet_128_255_bytes => OPEN,
         stat_tx_packet_256_511_bytes => OPEN, stat_tx_packet_512_1023_bytes => OPEN, stat_tx_packet_1024_1518_bytes => OPEN,
         stat_tx_packet_1519_1522_bytes => OPEN, stat_tx_packet_1523_1548_bytes => OPEN, stat_tx_packet_1549_2047_bytes => OPEN,
         stat_tx_packet_2048_4095_bytes => OPEN, stat_tx_packet_4096_8191_bytes => OPEN,stat_tx_packet_8192_9215_bytes => OPEN,
         stat_tx_packet_small => OPEN, stat_tx_packet_large => OPEN, stat_tx_frame_error => OPEN,

         ctl_tx_enable => i_tx_enable, ctl_tx_send_rfi => tx_send_rfi,  ctl_tx_send_lfi => tx_send_lfi,  ctl_tx_send_idle => tx_send_idle,
         ctl_tx_test_pattern => '0');

   END GENERATE;

   quad128_gen: IF g_device = QUAD_100G_128 GENERATE

      mac_1: mac_100g_quad_128
      PORT MAP (
         gt0_rxp_in => gt_rxp_in(0), gt1_rxp_in => gt_rxp_in(1), gt2_rxp_in => gt_rxp_in(2), gt3_rxp_in => gt_rxp_in(3),
         gt0_rxn_in => gt_rxn_in(0), gt1_rxn_in => gt_rxn_in(1), gt2_rxn_in => gt_rxn_in(2), gt3_rxn_in => gt_rxn_in(3),
         gt0_txp_out => gt_txp_out(0), gt1_txp_out => gt_txp_out(1), gt2_txp_out => gt_txp_out(2), gt3_txp_out => gt_txp_out(3),
         gt0_txn_out => gt_txn_out(0), gt1_txn_out => gt_txn_out(1), gt2_txn_out => gt_txn_out(2), gt3_txn_out => gt_txn_out(3),
         gt_ref_clk_p => gt_refclk_p, gt_ref_clk_n => gt_refclk_n, gt_ref_clk_out => OPEN,

         sys_reset => sys_reset, core_drp_reset => '0', core_rx_reset => '0', core_tx_reset => '0',
         gt_rxresetdone => OPEN, gt_txresetdone => OPEN,

         drp_clk => '0', init_clk => dclk, gt_drpclk => dclk,
         gt_rxrecclkout => rx_clk_out, rx_clk => rx_clk_in, gt_txusrclk2 => i_tx_clk_out,

         gt_rxpolarity => g_rxpolarity, gt_txpolarity => g_txpolarity,
         gt_loopback_in => i_loopback,

         gt_eyescandataerror => OPEN,  gt_eyescanreset => X"0", gt_eyescantrigger => X"0",
         gt_rxbufstatus => OPEN, gt_rxcdrhold => X"0", gt_rxdfelpmreset => X"0", gt_rxlpmen => g_rxlpmen,
         gt_rxrate => X"000", gt_rxprbscntreset => X"0", gt_rxprbserr => OPEN, gt_rxprbssel => X"0000",
         gt_txbufstatus => OPEN, gt_txdiffctrl => c_txdiffctrl, gt_txinhibit => X"0", gt_txpostcursor => c_txpostcursor,
         gt_txprbsforceerr => X"0", gt_txprbssel => X"0000", gt_txprecursor => c_txprecursor,
         gtwiz_reset_tx_datapath => '0', gtwiz_reset_rx_datapath => '0',

         common0_drpaddr => X"0000", common0_drpdi => X"0000", common0_drpwe => '0',
         common0_drpen => '0', common0_drprdy => OPEN, common0_drpdo => OPEN,

         gt0_drpdo => OPEN, gt1_drpdo => OPEN, gt2_drpdo => OPEN, gt3_drpdo => OPEN,
         gt0_drprdy => OPEN, gt1_drprdy => OPEN, gt2_drprdy => OPEN, gt3_drprdy => OPEN,
         gt0_drpen => '0', gt1_drpen => '0', gt2_drpen => '0', gt3_drpen => '0',
         gt0_drpwe => '0', gt1_drpwe => '0', gt2_drpwe => '0', gt3_drpwe => '0',
         gt0_drpaddr => gnd(9 DOWNTO 0), gt1_drpaddr => gnd(9 DOWNTO 0), gt2_drpaddr => gnd(9 DOWNTO 0), gt3_drpaddr => gnd(9 DOWNTO 0),
         gt0_drpdi => X"0000", gt1_drpdi => X"0000", gt2_drpdi => X"0000", gt3_drpdi => X"0000",
         drp_addr => gnd(9 DOWNTO 0), drp_di => X"0000", drp_en => '0',
         drp_we => '0', drp_do => OPEN, drp_rdy => OPEN,

         gt_powergoodout => OPEN,

         ctl_tx_rsfec_enable => rsfec_tx_enable, ctl_rx_rsfec_enable => rsfec_rx_enable, ctl_rsfec_ieee_error_indication_mode => '1',
         ctl_rx_rsfec_enable_correction => '1', ctl_rx_rsfec_enable_indication => '1',

         usr_rx_reset => i_user_rx_reset,
         rx_dataout0 => data_rx_sosi.data(127 DOWNTO 0), rx_dataout1 => data_rx_sosi.data(255 DOWNTO 128),
         rx_dataout2 => data_rx_sosi.data(383 DOWNTO 256), rx_dataout3 => data_rx_sosi.data(511 DOWNTO 384),
         rx_enaout0 => data_rx_sosi.valid(0), rx_enaout1 => data_rx_sosi.valid(1), rx_enaout2 => data_rx_sosi.valid(2), rx_enaout3 => data_rx_sosi.valid(3),
         rx_eopout0 => data_rx_sosi.eop(0), rx_eopout1 => data_rx_sosi.eop(1), rx_eopout2 => data_rx_sosi.eop(2), rx_eopout3 => data_rx_sosi.eop(3),
         rx_errout0 => data_rx_sosi.error(0), rx_errout1 => data_rx_sosi.error(1), rx_errout2 => data_rx_sosi.error(2), rx_errout3 => data_rx_sosi.error(3),
         rx_mtyout0 => data_rx_sosi.empty(0), rx_mtyout1 => data_rx_sosi.empty(1), rx_mtyout2 => data_rx_sosi.empty(2), rx_mtyout3 => data_rx_sosi.empty(3),
         rx_sopout0 => data_rx_sosi.sop(0), rx_sopout1 => data_rx_sosi.sop(1), rx_sopout2 => data_rx_sosi.sop(2), rx_sopout3 => data_rx_sosi.sop(3),

         ctl_rx_enable => rx_enable, ctl_rx_force_resync => '0', ctl_rx_test_pattern => '0',
         stat_rx_local_fault => OPEN, stat_rx_block_lock => OPEN,
         rx_otn_bip8_0 => OPEN, rx_otn_bip8_1 => OPEN, rx_otn_bip8_2 => OPEN, rx_otn_bip8_3 => OPEN, rx_otn_bip8_4 => OPEN,
         rx_otn_data_0 => OPEN, rx_otn_data_1 => OPEN, rx_otn_data_2 => OPEN, rx_otn_data_3 => OPEN, rx_otn_data_4 => OPEN,
         rx_otn_ena => OPEN, rx_otn_lane0 => OPEN, rx_otn_vlmarker => OPEN,

         stat_rx_unicast => OPEN, stat_rx_vlan => OPEN, stat_rx_pcsl_demuxed => OPEN,
         stat_rx_rsfec_am_lock0 => OPEN, stat_rx_rsfec_am_lock1 => OPEN, stat_rx_rsfec_am_lock2 => OPEN, stat_rx_rsfec_am_lock3 => OPEN,
         stat_rx_rsfec_corrected_cw_inc => OPEN, stat_rx_rsfec_cw_inc => OPEN,
         stat_rx_rsfec_err_count0_inc => OPEN, stat_rx_rsfec_err_count1_inc => OPEN, stat_rx_rsfec_err_count2_inc => OPEN,
         stat_rx_rsfec_err_count3_inc => OPEN, stat_rx_rsfec_hi_ser => OPEN, stat_rx_rsfec_lane_alignment_status => OPEN,
         stat_rx_rsfec_lane_fill_0 => OPEN, stat_rx_rsfec_lane_fill_1 => OPEN, stat_rx_rsfec_lane_fill_2 => OPEN,
         stat_rx_rsfec_lane_fill_3 => OPEN, stat_rx_rsfec_lane_mapping => OPEN, stat_rx_rsfec_uncorrected_cw_inc => OPEN,
         stat_rx_status => OPEN, stat_rx_test_pattern_mismatch => OPEN,
         stat_rx_remote_fault => rx_remote_fault, stat_rx_bad_fcs => OPEN, stat_rx_stomped_fcs => OPEN, stat_rx_truncated => OPEN,
         stat_rx_internal_local_fault => rx_local_fault, stat_rx_received_local_fault => rx_receive_local_fault, stat_rx_hi_ber => OPEN, stat_rx_got_signal_os => OPEN,
         stat_rx_total_bytes => stat_rx_total_bytes, stat_rx_total_packets => stat_rx_total_packets, stat_rx_total_good_bytes => OPEN, stat_rx_total_good_packets => OPEN,
         stat_rx_packet_bad_fcs => stat_rx_bad_fcs, stat_rx_packet_64_bytes => OPEN, stat_rx_packet_65_127_bytes => OPEN, stat_rx_packet_128_255_bytes => OPEN,
         stat_rx_packet_256_511_bytes => OPEN, stat_rx_packet_512_1023_bytes => OPEN, stat_rx_packet_1024_1518_bytes => OPEN,
         stat_rx_packet_1519_1522_bytes => OPEN, stat_rx_packet_1523_1548_bytes => OPEN, stat_rx_packet_1549_2047_bytes => OPEN,
         stat_rx_packet_2048_4095_bytes => OPEN, stat_rx_packet_4096_8191_bytes => OPEN, stat_rx_packet_8192_9215_bytes => OPEN,
         stat_rx_packet_small => OPEN, stat_rx_packet_large => OPEN,  stat_rx_oversize => OPEN, stat_rx_toolong => OPEN, stat_rx_undersize => OPEN,
         stat_rx_fragment => OPEN, stat_rx_jabber => OPEN, stat_rx_bad_code => stat_rx_bad_code, stat_rx_bad_sfd => OPEN, stat_rx_bad_preamble => OPEN,
         stat_rx_pcsl_number_0 => OPEN, stat_rx_pcsl_number_1 => OPEN, stat_rx_pcsl_number_2 => OPEN, stat_rx_pcsl_number_3 => OPEN,
         stat_rx_pcsl_number_4 => OPEN, stat_rx_pcsl_number_5 => OPEN, stat_rx_pcsl_number_6 => OPEN, stat_rx_pcsl_number_7 => OPEN,
         stat_rx_pcsl_number_8 => OPEN, stat_rx_pcsl_number_9 => OPEN, stat_rx_pcsl_number_10 => OPEN, stat_rx_pcsl_number_11 => OPEN,
         stat_rx_pcsl_number_12 => OPEN, stat_rx_pcsl_number_13 => OPEN, stat_rx_pcsl_number_14 => OPEN, stat_rx_pcsl_number_15 => OPEN,
         stat_rx_pcsl_number_16 => OPEN, stat_rx_pcsl_number_17 => OPEN, stat_rx_pcsl_number_18 => OPEN, stat_rx_pcsl_number_19 => OPEN,
         stat_tx_broadcast => OPEN, stat_tx_multicast => OPEN, stat_tx_unicast => OPEN, stat_tx_vlan => OPEN,
         stat_rx_bip_err_0 => OPEN, stat_rx_bip_err_1 => OPEN, stat_rx_bip_err_2 => OPEN, stat_rx_bip_err_3 => OPEN,
         stat_rx_bip_err_4 => OPEN, stat_rx_bip_err_5 => OPEN, stat_rx_bip_err_6 => OPEN, stat_rx_bip_err_7 => OPEN,
         stat_rx_bip_err_8 => OPEN, stat_rx_bip_err_9 => OPEN, stat_rx_bip_err_10 => OPEN, stat_rx_bip_err_11 => OPEN,
         stat_rx_bip_err_12 => OPEN, stat_rx_bip_err_13 => OPEN, stat_rx_bip_err_14 => OPEN, stat_rx_bip_err_15 => OPEN,
         stat_rx_bip_err_16 => OPEN, stat_rx_bip_err_17 => OPEN, stat_rx_bip_err_18 => OPEN, stat_rx_bip_err_19 => OPEN,
         stat_rx_framing_err_0 => OPEN, stat_rx_framing_err_1 => OPEN, stat_rx_framing_err_2 => OPEN, stat_rx_framing_err_3 => OPEN,
         stat_rx_framing_err_4 => OPEN, stat_rx_framing_err_5 => OPEN, stat_rx_framing_err_6 => OPEN, stat_rx_framing_err_7 => OPEN,
         stat_rx_framing_err_8 => OPEN, stat_rx_framing_err_9 => OPEN, stat_rx_framing_err_10 => OPEN, stat_rx_framing_err_11 => OPEN,
         stat_rx_framing_err_12 => OPEN, stat_rx_framing_err_13 => OPEN, stat_rx_framing_err_14 => OPEN, stat_rx_framing_err_15 => OPEN,
         stat_rx_framing_err_16 => OPEN, stat_rx_framing_err_17 => OPEN, stat_rx_framing_err_18 => OPEN, stat_rx_framing_err_19 => OPEN,
         stat_rx_framing_err_valid_0 => OPEN, stat_rx_framing_err_valid_1 => OPEN, stat_rx_framing_err_valid_2 => OPEN,
         stat_rx_framing_err_valid_3 => OPEN, stat_rx_framing_err_valid_4 => OPEN, stat_rx_framing_err_valid_5 => OPEN,
         stat_rx_framing_err_valid_6 => OPEN, stat_rx_framing_err_valid_7 => OPEN, stat_rx_framing_err_valid_8 => OPEN,
         stat_rx_framing_err_valid_9 => OPEN, stat_rx_framing_err_valid_10 => OPEN, stat_rx_framing_err_valid_11 => OPEN,
         stat_rx_framing_err_valid_12 => OPEN, stat_rx_framing_err_valid_13 => OPEN, stat_rx_framing_err_valid_14 => OPEN,
         stat_rx_framing_err_valid_15 => OPEN, stat_rx_framing_err_valid_16 => OPEN, stat_rx_framing_err_valid_17 => OPEN,
         stat_rx_framing_err_valid_18 => OPEN, stat_rx_framing_err_valid_19 => OPEN, stat_rx_inrangeerr => OPEN, stat_rx_mf_err => OPEN,
         stat_rx_mf_len_err => OPEN, stat_rx_broadcast => OPEN, stat_rx_mf_repeat_err => OPEN, stat_rx_misaligned => OPEN,
         stat_rx_multicast => OPEN, stat_rx_aligned => i_rx_locked, stat_rx_aligned_err => OPEN,
         stat_rx_synced => OPEN, stat_rx_synced_err => OPEN,

         usr_tx_reset => i_user_tx_reset,
         tx_unfout => data_tx_siso.underflow, tx_ovfout => data_tx_siso.overflow, tx_rdyout => data_tx_siso.ready,
         tx_datain0 => data_tx_sosi.data(127 DOWNTO 0), tx_datain1 => data_tx_sosi.data(255 DOWNTO 128),
         tx_datain2 => data_tx_sosi.data(383 DOWNTO 256), tx_datain3 => data_tx_sosi.data(511 DOWNTO 384),
         tx_enain0 => data_tx_sosi.valid(0), tx_enain1 => data_tx_sosi.valid(1), tx_enain2 => data_tx_sosi.valid(2), tx_enain3 => data_tx_sosi.valid(3),
         tx_eopin0 => data_tx_sosi.eop(0), tx_eopin1 => data_tx_sosi.eop(1), tx_eopin2 => data_tx_sosi.eop(2), tx_eopin3 => data_tx_sosi.eop(3),
         tx_errin0 => data_tx_sosi.error(0), tx_errin1 => data_tx_sosi.error(1), tx_errin2 => data_tx_sosi.error(2), tx_errin3 => data_tx_sosi.error(3),
         tx_mtyin0 => data_tx_sosi.empty(0), tx_mtyin1 => data_tx_sosi.empty(1), tx_mtyin2 => data_tx_sosi.empty(2), tx_mtyin3 => data_tx_sosi.empty(3),
         tx_sopin0 => data_tx_sosi.sop(0), tx_sopin1 => data_tx_sosi.sop(1), tx_sopin2 => data_tx_sosi.sop(2), tx_sopin3 => data_tx_sosi.sop(3),

         tx_preamblein => gnd(55 DOWNTO 0), rx_preambleout => OPEN, stat_tx_local_fault => OPEN,
         stat_tx_total_bytes => stat_tx_total_bytes, stat_tx_total_packets => stat_tx_total_packets, stat_tx_total_good_bytes => OPEN, stat_tx_total_good_packets => OPEN,
         stat_tx_bad_fcs => OPEN, stat_tx_packet_64_bytes => OPEN, stat_tx_packet_65_127_bytes => OPEN, stat_tx_packet_128_255_bytes => OPEN,
         stat_tx_packet_256_511_bytes => OPEN, stat_tx_packet_512_1023_bytes => OPEN, stat_tx_packet_1024_1518_bytes => OPEN,
         stat_tx_packet_1519_1522_bytes => OPEN, stat_tx_packet_1523_1548_bytes => OPEN, stat_tx_packet_1549_2047_bytes => OPEN,
         stat_tx_packet_2048_4095_bytes => OPEN, stat_tx_packet_4096_8191_bytes => OPEN,stat_tx_packet_8192_9215_bytes => OPEN,
         stat_tx_packet_small => OPEN, stat_tx_packet_large => OPEN, stat_tx_frame_error => OPEN,

         ctl_tx_enable => i_tx_enable, ctl_tx_send_rfi => tx_send_rfi,  ctl_tx_send_lfi => tx_send_lfi,  ctl_tx_send_idle => tx_send_idle,
         ctl_tx_test_pattern => '0');
   END GENERATE;

   quad130_gen: IF g_device = QUAD_100G_130 GENERATE

      mac_1: mac_100g_quad_130
      PORT MAP (
         gt0_rxp_in => gt_rxp_in(0), gt1_rxp_in => gt_rxp_in(1), gt2_rxp_in => gt_rxp_in(2), gt3_rxp_in => gt_rxp_in(3),
         gt0_rxn_in => gt_rxn_in(0), gt1_rxn_in => gt_rxn_in(1), gt2_rxn_in => gt_rxn_in(2), gt3_rxn_in => gt_rxn_in(3),
         gt0_txp_out => gt_txp_out(0), gt1_txp_out => gt_txp_out(1), gt2_txp_out => gt_txp_out(2), gt3_txp_out => gt_txp_out(3),
         gt0_txn_out => gt_txn_out(0), gt1_txn_out => gt_txn_out(1), gt2_txn_out => gt_txn_out(2), gt3_txn_out => gt_txn_out(3),
         gt_ref_clk_p => gt_refclk_p, gt_ref_clk_n => gt_refclk_n, gt_ref_clk_out => OPEN,

         sys_reset => sys_reset, core_drp_reset => '0', core_rx_reset => '0', core_tx_reset => '0',
         gt_rxresetdone => OPEN, gt_txresetdone => OPEN,

         drp_clk => '0', init_clk => dclk, gt_drpclk => dclk,
         gt_rxrecclkout => rx_clk_out, rx_clk => rx_clk_in, gt_txusrclk2 => i_tx_clk_out,

         gt_rxpolarity => g_rxpolarity, gt_txpolarity => g_txpolarity,
         gt_loopback_in => i_loopback,

         gt_eyescandataerror => OPEN,  gt_eyescanreset => X"0", gt_eyescantrigger => X"0",
         gt_rxbufstatus => OPEN, gt_rxcdrhold => X"0", gt_rxdfelpmreset => X"0", gt_rxlpmen => g_rxlpmen,
         gt_rxrate => X"000", gt_rxprbscntreset => X"0", gt_rxprbserr => OPEN, gt_rxprbssel => X"0000",
         gt_txbufstatus => OPEN, gt_txdiffctrl => c_txdiffctrl, gt_txinhibit => X"0", gt_txpostcursor => c_txpostcursor,
         gt_txprbsforceerr => X"0", gt_txprbssel => X"0000", gt_txprecursor => c_txprecursor,
         gtwiz_reset_tx_datapath => '0', gtwiz_reset_rx_datapath => '0',

         common0_drpaddr => X"0000", common0_drpdi => X"0000", common0_drpwe => '0',
         common0_drpen => '0', common0_drprdy => OPEN, common0_drpdo => OPEN,

         gt0_drpdo => OPEN, gt1_drpdo => OPEN, gt2_drpdo => OPEN, gt3_drpdo => OPEN,
         gt0_drprdy => OPEN, gt1_drprdy => OPEN, gt2_drprdy => OPEN, gt3_drprdy => OPEN,
         gt0_drpen => '0', gt1_drpen => '0', gt2_drpen => '0', gt3_drpen => '0',
         gt0_drpwe => '0', gt1_drpwe => '0', gt2_drpwe => '0', gt3_drpwe => '0',
         gt0_drpaddr => gnd(9 DOWNTO 0), gt1_drpaddr => gnd(9 DOWNTO 0), gt2_drpaddr => gnd(9 DOWNTO 0), gt3_drpaddr => gnd(9 DOWNTO 0),
         gt0_drpdi => X"0000", gt1_drpdi => X"0000", gt2_drpdi => X"0000", gt3_drpdi => X"0000",
         drp_addr => gnd(9 DOWNTO 0), drp_di => X"0000", drp_en => '0',
         drp_we => '0', drp_do => OPEN, drp_rdy => OPEN,

         gt_powergoodout => OPEN,

         ctl_tx_rsfec_enable => rsfec_tx_enable, ctl_rx_rsfec_enable => rsfec_rx_enable, ctl_rsfec_ieee_error_indication_mode => '1',
         ctl_rx_rsfec_enable_correction => '1', ctl_rx_rsfec_enable_indication => '1',

         usr_rx_reset => i_user_rx_reset,
         rx_dataout0 => data_rx_sosi.data(127 DOWNTO 0), rx_dataout1 => data_rx_sosi.data(255 DOWNTO 128),
         rx_dataout2 => data_rx_sosi.data(383 DOWNTO 256), rx_dataout3 => data_rx_sosi.data(511 DOWNTO 384),
         rx_enaout0 => data_rx_sosi.valid(0), rx_enaout1 => data_rx_sosi.valid(1), rx_enaout2 => data_rx_sosi.valid(2), rx_enaout3 => data_rx_sosi.valid(3),
         rx_eopout0 => data_rx_sosi.eop(0), rx_eopout1 => data_rx_sosi.eop(1), rx_eopout2 => data_rx_sosi.eop(2), rx_eopout3 => data_rx_sosi.eop(3),
         rx_errout0 => data_rx_sosi.error(0), rx_errout1 => data_rx_sosi.error(1), rx_errout2 => data_rx_sosi.error(2), rx_errout3 => data_rx_sosi.error(3),
         rx_mtyout0 => data_rx_sosi.empty(0), rx_mtyout1 => data_rx_sosi.empty(1), rx_mtyout2 => data_rx_sosi.empty(2), rx_mtyout3 => data_rx_sosi.empty(3),
         rx_sopout0 => data_rx_sosi.sop(0), rx_sopout1 => data_rx_sosi.sop(1), rx_sopout2 => data_rx_sosi.sop(2), rx_sopout3 => data_rx_sosi.sop(3),

         ctl_rx_enable => rx_enable, ctl_rx_force_resync => '0', ctl_rx_test_pattern => '0',
         stat_rx_local_fault => OPEN, stat_rx_block_lock => OPEN,
         rx_otn_bip8_0 => OPEN, rx_otn_bip8_1 => OPEN, rx_otn_bip8_2 => OPEN, rx_otn_bip8_3 => OPEN, rx_otn_bip8_4 => OPEN,
         rx_otn_data_0 => OPEN, rx_otn_data_1 => OPEN, rx_otn_data_2 => OPEN, rx_otn_data_3 => OPEN, rx_otn_data_4 => OPEN,
         rx_otn_ena => OPEN, rx_otn_lane0 => OPEN, rx_otn_vlmarker => OPEN,

         stat_rx_unicast => OPEN, stat_rx_vlan => OPEN, stat_rx_pcsl_demuxed => OPEN,
         stat_rx_rsfec_am_lock0 => OPEN, stat_rx_rsfec_am_lock1 => OPEN, stat_rx_rsfec_am_lock2 => OPEN, stat_rx_rsfec_am_lock3 => OPEN,
         stat_rx_rsfec_corrected_cw_inc => OPEN, stat_rx_rsfec_cw_inc => OPEN,
         stat_rx_rsfec_err_count0_inc => OPEN, stat_rx_rsfec_err_count1_inc => OPEN, stat_rx_rsfec_err_count2_inc => OPEN,
         stat_rx_rsfec_err_count3_inc => OPEN, stat_rx_rsfec_hi_ser => OPEN, stat_rx_rsfec_lane_alignment_status => OPEN,
         stat_rx_rsfec_lane_fill_0 => OPEN, stat_rx_rsfec_lane_fill_1 => OPEN, stat_rx_rsfec_lane_fill_2 => OPEN,
         stat_rx_rsfec_lane_fill_3 => OPEN, stat_rx_rsfec_lane_mapping => OPEN, stat_rx_rsfec_uncorrected_cw_inc => OPEN,
         stat_rx_status => OPEN, stat_rx_test_pattern_mismatch => OPEN,
         stat_rx_remote_fault => rx_remote_fault, stat_rx_bad_fcs => OPEN, stat_rx_stomped_fcs => OPEN, stat_rx_truncated => OPEN,
         stat_rx_internal_local_fault => rx_local_fault, stat_rx_received_local_fault => rx_receive_local_fault, stat_rx_hi_ber => OPEN, stat_rx_got_signal_os => OPEN,
         stat_rx_total_bytes => stat_rx_total_bytes, stat_rx_total_packets => stat_rx_total_packets, stat_rx_total_good_bytes => OPEN, stat_rx_total_good_packets => OPEN,
         stat_rx_packet_bad_fcs => stat_rx_bad_fcs, stat_rx_packet_64_bytes => OPEN, stat_rx_packet_65_127_bytes => OPEN, stat_rx_packet_128_255_bytes => OPEN,
         stat_rx_packet_256_511_bytes => OPEN, stat_rx_packet_512_1023_bytes => OPEN, stat_rx_packet_1024_1518_bytes => OPEN,
         stat_rx_packet_1519_1522_bytes => OPEN, stat_rx_packet_1523_1548_bytes => OPEN, stat_rx_packet_1549_2047_bytes => OPEN,
         stat_rx_packet_2048_4095_bytes => OPEN, stat_rx_packet_4096_8191_bytes => OPEN, stat_rx_packet_8192_9215_bytes => OPEN,
         stat_rx_packet_small => OPEN, stat_rx_packet_large => OPEN,  stat_rx_oversize => OPEN, stat_rx_toolong => OPEN, stat_rx_undersize => OPEN,
         stat_rx_fragment => OPEN, stat_rx_jabber => OPEN, stat_rx_bad_code => stat_rx_bad_code, stat_rx_bad_sfd => OPEN, stat_rx_bad_preamble => OPEN,
         stat_rx_pcsl_number_0 => OPEN, stat_rx_pcsl_number_1 => OPEN, stat_rx_pcsl_number_2 => OPEN, stat_rx_pcsl_number_3 => OPEN,
         stat_rx_pcsl_number_4 => OPEN, stat_rx_pcsl_number_5 => OPEN, stat_rx_pcsl_number_6 => OPEN, stat_rx_pcsl_number_7 => OPEN,
         stat_rx_pcsl_number_8 => OPEN, stat_rx_pcsl_number_9 => OPEN, stat_rx_pcsl_number_10 => OPEN, stat_rx_pcsl_number_11 => OPEN,
         stat_rx_pcsl_number_12 => OPEN, stat_rx_pcsl_number_13 => OPEN, stat_rx_pcsl_number_14 => OPEN, stat_rx_pcsl_number_15 => OPEN,
         stat_rx_pcsl_number_16 => OPEN, stat_rx_pcsl_number_17 => OPEN, stat_rx_pcsl_number_18 => OPEN, stat_rx_pcsl_number_19 => OPEN,
         stat_tx_broadcast => OPEN, stat_tx_multicast => OPEN, stat_tx_unicast => OPEN, stat_tx_vlan => OPEN,
         stat_rx_bip_err_0 => OPEN, stat_rx_bip_err_1 => OPEN, stat_rx_bip_err_2 => OPEN, stat_rx_bip_err_3 => OPEN,
         stat_rx_bip_err_4 => OPEN, stat_rx_bip_err_5 => OPEN, stat_rx_bip_err_6 => OPEN, stat_rx_bip_err_7 => OPEN,
         stat_rx_bip_err_8 => OPEN, stat_rx_bip_err_9 => OPEN, stat_rx_bip_err_10 => OPEN, stat_rx_bip_err_11 => OPEN,
         stat_rx_bip_err_12 => OPEN, stat_rx_bip_err_13 => OPEN, stat_rx_bip_err_14 => OPEN, stat_rx_bip_err_15 => OPEN,
         stat_rx_bip_err_16 => OPEN, stat_rx_bip_err_17 => OPEN, stat_rx_bip_err_18 => OPEN, stat_rx_bip_err_19 => OPEN,
         stat_rx_framing_err_0 => OPEN, stat_rx_framing_err_1 => OPEN, stat_rx_framing_err_2 => OPEN, stat_rx_framing_err_3 => OPEN,
         stat_rx_framing_err_4 => OPEN, stat_rx_framing_err_5 => OPEN, stat_rx_framing_err_6 => OPEN, stat_rx_framing_err_7 => OPEN,
         stat_rx_framing_err_8 => OPEN, stat_rx_framing_err_9 => OPEN, stat_rx_framing_err_10 => OPEN, stat_rx_framing_err_11 => OPEN,
         stat_rx_framing_err_12 => OPEN, stat_rx_framing_err_13 => OPEN, stat_rx_framing_err_14 => OPEN, stat_rx_framing_err_15 => OPEN,
         stat_rx_framing_err_16 => OPEN, stat_rx_framing_err_17 => OPEN, stat_rx_framing_err_18 => OPEN, stat_rx_framing_err_19 => OPEN,
         stat_rx_framing_err_valid_0 => OPEN, stat_rx_framing_err_valid_1 => OPEN, stat_rx_framing_err_valid_2 => OPEN,
         stat_rx_framing_err_valid_3 => OPEN, stat_rx_framing_err_valid_4 => OPEN, stat_rx_framing_err_valid_5 => OPEN,
         stat_rx_framing_err_valid_6 => OPEN, stat_rx_framing_err_valid_7 => OPEN, stat_rx_framing_err_valid_8 => OPEN,
         stat_rx_framing_err_valid_9 => OPEN, stat_rx_framing_err_valid_10 => OPEN, stat_rx_framing_err_valid_11 => OPEN,
         stat_rx_framing_err_valid_12 => OPEN, stat_rx_framing_err_valid_13 => OPEN, stat_rx_framing_err_valid_14 => OPEN,
         stat_rx_framing_err_valid_15 => OPEN, stat_rx_framing_err_valid_16 => OPEN, stat_rx_framing_err_valid_17 => OPEN,
         stat_rx_framing_err_valid_18 => OPEN, stat_rx_framing_err_valid_19 => OPEN, stat_rx_inrangeerr => OPEN, stat_rx_mf_err => OPEN,
         stat_rx_mf_len_err => OPEN, stat_rx_broadcast => OPEN, stat_rx_mf_repeat_err => OPEN, stat_rx_misaligned => OPEN,
         stat_rx_multicast => OPEN, stat_rx_aligned => i_rx_locked, stat_rx_aligned_err => OPEN,
         stat_rx_synced => OPEN, stat_rx_synced_err => OPEN,

         usr_tx_reset => i_user_tx_reset,
         tx_unfout => data_tx_siso.underflow, tx_ovfout => data_tx_siso.overflow, tx_rdyout => data_tx_siso.ready,
         tx_datain0 => data_tx_sosi.data(127 DOWNTO 0), tx_datain1 => data_tx_sosi.data(255 DOWNTO 128),
         tx_datain2 => data_tx_sosi.data(383 DOWNTO 256), tx_datain3 => data_tx_sosi.data(511 DOWNTO 384),
         tx_enain0 => data_tx_sosi.valid(0), tx_enain1 => data_tx_sosi.valid(1), tx_enain2 => data_tx_sosi.valid(2), tx_enain3 => data_tx_sosi.valid(3),
         tx_eopin0 => data_tx_sosi.eop(0), tx_eopin1 => data_tx_sosi.eop(1), tx_eopin2 => data_tx_sosi.eop(2), tx_eopin3 => data_tx_sosi.eop(3),
         tx_errin0 => data_tx_sosi.error(0), tx_errin1 => data_tx_sosi.error(1), tx_errin2 => data_tx_sosi.error(2), tx_errin3 => data_tx_sosi.error(3),
         tx_mtyin0 => data_tx_sosi.empty(0), tx_mtyin1 => data_tx_sosi.empty(1), tx_mtyin2 => data_tx_sosi.empty(2), tx_mtyin3 => data_tx_sosi.empty(3),
         tx_sopin0 => data_tx_sosi.sop(0), tx_sopin1 => data_tx_sosi.sop(1), tx_sopin2 => data_tx_sosi.sop(2), tx_sopin3 => data_tx_sosi.sop(3),

         tx_preamblein => gnd(55 DOWNTO 0), rx_preambleout => OPEN, stat_tx_local_fault => OPEN,
         stat_tx_total_bytes => stat_tx_total_bytes, stat_tx_total_packets => stat_tx_total_packets, stat_tx_total_good_bytes => OPEN, stat_tx_total_good_packets => OPEN,
         stat_tx_bad_fcs => OPEN, stat_tx_packet_64_bytes => OPEN, stat_tx_packet_65_127_bytes => OPEN, stat_tx_packet_128_255_bytes => OPEN,
         stat_tx_packet_256_511_bytes => OPEN, stat_tx_packet_512_1023_bytes => OPEN, stat_tx_packet_1024_1518_bytes => OPEN,
         stat_tx_packet_1519_1522_bytes => OPEN, stat_tx_packet_1523_1548_bytes => OPEN, stat_tx_packet_1549_2047_bytes => OPEN,
         stat_tx_packet_2048_4095_bytes => OPEN, stat_tx_packet_4096_8191_bytes => OPEN,stat_tx_packet_8192_9215_bytes => OPEN,
         stat_tx_packet_small => OPEN, stat_tx_packet_large => OPEN, stat_tx_frame_error => OPEN,

         ctl_tx_enable => i_tx_enable, ctl_tx_send_rfi => tx_send_rfi,  ctl_tx_send_lfi => tx_send_lfi,  ctl_tx_send_idle => tx_send_idle,
         ctl_tx_test_pattern => '0');

   END GENERATE;

   quad131_gen: IF g_device = QUAD_100G_131 GENERATE

      mac_1: mac_100g_quad_131
      PORT MAP (
         gt0_rxp_in => gt_rxp_in(0), gt1_rxp_in => gt_rxp_in(1), gt2_rxp_in => gt_rxp_in(2), gt3_rxp_in => gt_rxp_in(3),
         gt0_rxn_in => gt_rxn_in(0), gt1_rxn_in => gt_rxn_in(1), gt2_rxn_in => gt_rxn_in(2), gt3_rxn_in => gt_rxn_in(3),
         gt0_txp_out => gt_txp_out(0), gt1_txp_out => gt_txp_out(1), gt2_txp_out => gt_txp_out(2), gt3_txp_out => gt_txp_out(3),
         gt0_txn_out => gt_txn_out(0), gt1_txn_out => gt_txn_out(1), gt2_txn_out => gt_txn_out(2), gt3_txn_out => gt_txn_out(3),
         gt_ref_clk_p => gt_refclk_p, gt_ref_clk_n => gt_refclk_n, gt_ref_clk_out => OPEN,

         sys_reset => sys_reset, core_drp_reset => '0', core_rx_reset => '0', core_tx_reset => '0',
         gt_rxresetdone => OPEN, gt_txresetdone => OPEN,

         drp_clk => '0', init_clk => dclk, gt_drpclk => dclk,
         gt_rxrecclkout => rx_clk_out, rx_clk => rx_clk_in, gt_txusrclk2 => i_tx_clk_out,

         gt_rxpolarity => g_rxpolarity, gt_txpolarity => g_txpolarity,
         gt_loopback_in => i_loopback,

         gt_eyescandataerror => OPEN,  gt_eyescanreset => X"0", gt_eyescantrigger => X"0",
         gt_rxbufstatus => OPEN, gt_rxcdrhold => X"0", gt_rxdfelpmreset => X"0", gt_rxlpmen => g_rxlpmen,
         gt_rxrate => X"000", gt_rxprbscntreset => X"0", gt_rxprbserr => OPEN, gt_rxprbssel => X"0000",
         gt_txbufstatus => OPEN, gt_txdiffctrl => c_txdiffctrl, gt_txinhibit => X"0", gt_txpostcursor => c_txpostcursor,
         gt_txprbsforceerr => X"0", gt_txprbssel => X"0000", gt_txprecursor => c_txprecursor,
         gtwiz_reset_tx_datapath => '0', gtwiz_reset_rx_datapath => '0',

         common0_drpaddr => X"0000", common0_drpdi => X"0000", common0_drpwe => '0',
         common0_drpen => '0', common0_drprdy => OPEN, common0_drpdo => OPEN,

         gt0_drpdo => OPEN, gt1_drpdo => OPEN, gt2_drpdo => OPEN, gt3_drpdo => OPEN,
         gt0_drprdy => OPEN, gt1_drprdy => OPEN, gt2_drprdy => OPEN, gt3_drprdy => OPEN,
         gt0_drpen => '0', gt1_drpen => '0', gt2_drpen => '0', gt3_drpen => '0',
         gt0_drpwe => '0', gt1_drpwe => '0', gt2_drpwe => '0', gt3_drpwe => '0',
         gt0_drpaddr => gnd(9 DOWNTO 0), gt1_drpaddr => gnd(9 DOWNTO 0), gt2_drpaddr => gnd(9 DOWNTO 0), gt3_drpaddr => gnd(9 DOWNTO 0),
         gt0_drpdi => X"0000", gt1_drpdi => X"0000", gt2_drpdi => X"0000", gt3_drpdi => X"0000",
         drp_addr => gnd(9 DOWNTO 0), drp_di => X"0000", drp_en => '0',
         drp_we => '0', drp_do => OPEN, drp_rdy => OPEN,

         gt_powergoodout => OPEN,

         ctl_tx_rsfec_enable => rsfec_tx_enable, ctl_rx_rsfec_enable => rsfec_rx_enable, ctl_rsfec_ieee_error_indication_mode => '1',
         ctl_rx_rsfec_enable_correction => '1', ctl_rx_rsfec_enable_indication => '1',

         usr_rx_reset => i_user_rx_reset,
         rx_dataout0 => data_rx_sosi.data(127 DOWNTO 0), rx_dataout1 => data_rx_sosi.data(255 DOWNTO 128),
         rx_dataout2 => data_rx_sosi.data(383 DOWNTO 256), rx_dataout3 => data_rx_sosi.data(511 DOWNTO 384),
         rx_enaout0 => data_rx_sosi.valid(0), rx_enaout1 => data_rx_sosi.valid(1), rx_enaout2 => data_rx_sosi.valid(2), rx_enaout3 => data_rx_sosi.valid(3),
         rx_eopout0 => data_rx_sosi.eop(0), rx_eopout1 => data_rx_sosi.eop(1), rx_eopout2 => data_rx_sosi.eop(2), rx_eopout3 => data_rx_sosi.eop(3),
         rx_errout0 => data_rx_sosi.error(0), rx_errout1 => data_rx_sosi.error(1), rx_errout2 => data_rx_sosi.error(2), rx_errout3 => data_rx_sosi.error(3),
         rx_mtyout0 => data_rx_sosi.empty(0), rx_mtyout1 => data_rx_sosi.empty(1), rx_mtyout2 => data_rx_sosi.empty(2), rx_mtyout3 => data_rx_sosi.empty(3),
         rx_sopout0 => data_rx_sosi.sop(0), rx_sopout1 => data_rx_sosi.sop(1), rx_sopout2 => data_rx_sosi.sop(2), rx_sopout3 => data_rx_sosi.sop(3),

         ctl_rx_enable => rx_enable, ctl_rx_force_resync => '0', ctl_rx_test_pattern => '0',
         stat_rx_local_fault => OPEN, stat_rx_block_lock => OPEN,
         rx_otn_bip8_0 => OPEN, rx_otn_bip8_1 => OPEN, rx_otn_bip8_2 => OPEN, rx_otn_bip8_3 => OPEN, rx_otn_bip8_4 => OPEN,
         rx_otn_data_0 => OPEN, rx_otn_data_1 => OPEN, rx_otn_data_2 => OPEN, rx_otn_data_3 => OPEN, rx_otn_data_4 => OPEN,
         rx_otn_ena => OPEN, rx_otn_lane0 => OPEN, rx_otn_vlmarker => OPEN,

         stat_rx_unicast => OPEN, stat_rx_vlan => OPEN, stat_rx_pcsl_demuxed => OPEN,
         stat_rx_rsfec_am_lock0 => OPEN, stat_rx_rsfec_am_lock1 => OPEN, stat_rx_rsfec_am_lock2 => OPEN, stat_rx_rsfec_am_lock3 => OPEN,
         stat_rx_rsfec_corrected_cw_inc => OPEN, stat_rx_rsfec_cw_inc => OPEN,
         stat_rx_rsfec_err_count0_inc => OPEN, stat_rx_rsfec_err_count1_inc => OPEN, stat_rx_rsfec_err_count2_inc => OPEN,
         stat_rx_rsfec_err_count3_inc => OPEN, stat_rx_rsfec_hi_ser => OPEN, stat_rx_rsfec_lane_alignment_status => OPEN,
         stat_rx_rsfec_lane_fill_0 => OPEN, stat_rx_rsfec_lane_fill_1 => OPEN, stat_rx_rsfec_lane_fill_2 => OPEN,
         stat_rx_rsfec_lane_fill_3 => OPEN, stat_rx_rsfec_lane_mapping => OPEN, stat_rx_rsfec_uncorrected_cw_inc => OPEN,
         stat_rx_status => OPEN, stat_rx_test_pattern_mismatch => OPEN,
         stat_rx_remote_fault => rx_remote_fault, stat_rx_bad_fcs => OPEN, stat_rx_stomped_fcs => OPEN, stat_rx_truncated => OPEN,
         stat_rx_internal_local_fault => rx_local_fault, stat_rx_received_local_fault => rx_receive_local_fault, stat_rx_hi_ber => OPEN, stat_rx_got_signal_os => OPEN,
         stat_rx_total_bytes => stat_rx_total_bytes, stat_rx_total_packets => stat_rx_total_packets, stat_rx_total_good_bytes => OPEN, stat_rx_total_good_packets => OPEN,
         stat_rx_packet_bad_fcs => stat_rx_bad_fcs, stat_rx_packet_64_bytes => OPEN, stat_rx_packet_65_127_bytes => OPEN, stat_rx_packet_128_255_bytes => OPEN,
         stat_rx_packet_256_511_bytes => OPEN, stat_rx_packet_512_1023_bytes => OPEN, stat_rx_packet_1024_1518_bytes => OPEN,
         stat_rx_packet_1519_1522_bytes => OPEN, stat_rx_packet_1523_1548_bytes => OPEN, stat_rx_packet_1549_2047_bytes => OPEN,
         stat_rx_packet_2048_4095_bytes => OPEN, stat_rx_packet_4096_8191_bytes => OPEN, stat_rx_packet_8192_9215_bytes => OPEN,
         stat_rx_packet_small => OPEN, stat_rx_packet_large => OPEN,  stat_rx_oversize => OPEN, stat_rx_toolong => OPEN, stat_rx_undersize => OPEN,
         stat_rx_fragment => OPEN, stat_rx_jabber => OPEN, stat_rx_bad_code => stat_rx_bad_code, stat_rx_bad_sfd => OPEN, stat_rx_bad_preamble => OPEN,
         stat_rx_pcsl_number_0 => OPEN, stat_rx_pcsl_number_1 => OPEN, stat_rx_pcsl_number_2 => OPEN, stat_rx_pcsl_number_3 => OPEN,
         stat_rx_pcsl_number_4 => OPEN, stat_rx_pcsl_number_5 => OPEN, stat_rx_pcsl_number_6 => OPEN, stat_rx_pcsl_number_7 => OPEN,
         stat_rx_pcsl_number_8 => OPEN, stat_rx_pcsl_number_9 => OPEN, stat_rx_pcsl_number_10 => OPEN, stat_rx_pcsl_number_11 => OPEN,
         stat_rx_pcsl_number_12 => OPEN, stat_rx_pcsl_number_13 => OPEN, stat_rx_pcsl_number_14 => OPEN, stat_rx_pcsl_number_15 => OPEN,
         stat_rx_pcsl_number_16 => OPEN, stat_rx_pcsl_number_17 => OPEN, stat_rx_pcsl_number_18 => OPEN, stat_rx_pcsl_number_19 => OPEN,
         stat_tx_broadcast => OPEN, stat_tx_multicast => OPEN, stat_tx_unicast => OPEN, stat_tx_vlan => OPEN,
         stat_rx_bip_err_0 => OPEN, stat_rx_bip_err_1 => OPEN, stat_rx_bip_err_2 => OPEN, stat_rx_bip_err_3 => OPEN,
         stat_rx_bip_err_4 => OPEN, stat_rx_bip_err_5 => OPEN, stat_rx_bip_err_6 => OPEN, stat_rx_bip_err_7 => OPEN,
         stat_rx_bip_err_8 => OPEN, stat_rx_bip_err_9 => OPEN, stat_rx_bip_err_10 => OPEN, stat_rx_bip_err_11 => OPEN,
         stat_rx_bip_err_12 => OPEN, stat_rx_bip_err_13 => OPEN, stat_rx_bip_err_14 => OPEN, stat_rx_bip_err_15 => OPEN,
         stat_rx_bip_err_16 => OPEN, stat_rx_bip_err_17 => OPEN, stat_rx_bip_err_18 => OPEN, stat_rx_bip_err_19 => OPEN,
         stat_rx_framing_err_0 => OPEN, stat_rx_framing_err_1 => OPEN, stat_rx_framing_err_2 => OPEN, stat_rx_framing_err_3 => OPEN,
         stat_rx_framing_err_4 => OPEN, stat_rx_framing_err_5 => OPEN, stat_rx_framing_err_6 => OPEN, stat_rx_framing_err_7 => OPEN,
         stat_rx_framing_err_8 => OPEN, stat_rx_framing_err_9 => OPEN, stat_rx_framing_err_10 => OPEN, stat_rx_framing_err_11 => OPEN,
         stat_rx_framing_err_12 => OPEN, stat_rx_framing_err_13 => OPEN, stat_rx_framing_err_14 => OPEN, stat_rx_framing_err_15 => OPEN,
         stat_rx_framing_err_16 => OPEN, stat_rx_framing_err_17 => OPEN, stat_rx_framing_err_18 => OPEN, stat_rx_framing_err_19 => OPEN,
         stat_rx_framing_err_valid_0 => OPEN, stat_rx_framing_err_valid_1 => OPEN, stat_rx_framing_err_valid_2 => OPEN,
         stat_rx_framing_err_valid_3 => OPEN, stat_rx_framing_err_valid_4 => OPEN, stat_rx_framing_err_valid_5 => OPEN,
         stat_rx_framing_err_valid_6 => OPEN, stat_rx_framing_err_valid_7 => OPEN, stat_rx_framing_err_valid_8 => OPEN,
         stat_rx_framing_err_valid_9 => OPEN, stat_rx_framing_err_valid_10 => OPEN, stat_rx_framing_err_valid_11 => OPEN,
         stat_rx_framing_err_valid_12 => OPEN, stat_rx_framing_err_valid_13 => OPEN, stat_rx_framing_err_valid_14 => OPEN,
         stat_rx_framing_err_valid_15 => OPEN, stat_rx_framing_err_valid_16 => OPEN, stat_rx_framing_err_valid_17 => OPEN,
         stat_rx_framing_err_valid_18 => OPEN, stat_rx_framing_err_valid_19 => OPEN, stat_rx_inrangeerr => OPEN, stat_rx_mf_err => OPEN,
         stat_rx_mf_len_err => OPEN, stat_rx_broadcast => OPEN, stat_rx_mf_repeat_err => OPEN, stat_rx_misaligned => OPEN,
         stat_rx_multicast => OPEN, stat_rx_aligned => i_rx_locked, stat_rx_aligned_err => OPEN,
         stat_rx_synced => OPEN, stat_rx_synced_err => OPEN,

         usr_tx_reset => i_user_tx_reset,
         tx_unfout => data_tx_siso.underflow, tx_ovfout => data_tx_siso.overflow, tx_rdyout => data_tx_siso.ready,
         tx_datain0 => data_tx_sosi.data(127 DOWNTO 0), tx_datain1 => data_tx_sosi.data(255 DOWNTO 128),
         tx_datain2 => data_tx_sosi.data(383 DOWNTO 256), tx_datain3 => data_tx_sosi.data(511 DOWNTO 384),
         tx_enain0 => data_tx_sosi.valid(0), tx_enain1 => data_tx_sosi.valid(1), tx_enain2 => data_tx_sosi.valid(2), tx_enain3 => data_tx_sosi.valid(3),
         tx_eopin0 => data_tx_sosi.eop(0), tx_eopin1 => data_tx_sosi.eop(1), tx_eopin2 => data_tx_sosi.eop(2), tx_eopin3 => data_tx_sosi.eop(3),
         tx_errin0 => data_tx_sosi.error(0), tx_errin1 => data_tx_sosi.error(1), tx_errin2 => data_tx_sosi.error(2), tx_errin3 => data_tx_sosi.error(3),
         tx_mtyin0 => data_tx_sosi.empty(0), tx_mtyin1 => data_tx_sosi.empty(1), tx_mtyin2 => data_tx_sosi.empty(2), tx_mtyin3 => data_tx_sosi.empty(3),
         tx_sopin0 => data_tx_sosi.sop(0), tx_sopin1 => data_tx_sosi.sop(1), tx_sopin2 => data_tx_sosi.sop(2), tx_sopin3 => data_tx_sosi.sop(3),

         tx_preamblein => gnd(55 DOWNTO 0), rx_preambleout => OPEN, stat_tx_local_fault => OPEN,
         stat_tx_total_bytes => stat_tx_total_bytes, stat_tx_total_packets => stat_tx_total_packets, stat_tx_total_good_bytes => OPEN, stat_tx_total_good_packets => OPEN,
         stat_tx_bad_fcs => OPEN, stat_tx_packet_64_bytes => OPEN, stat_tx_packet_65_127_bytes => OPEN, stat_tx_packet_128_255_bytes => OPEN,
         stat_tx_packet_256_511_bytes => OPEN, stat_tx_packet_512_1023_bytes => OPEN, stat_tx_packet_1024_1518_bytes => OPEN,
         stat_tx_packet_1519_1522_bytes => OPEN, stat_tx_packet_1523_1548_bytes => OPEN, stat_tx_packet_1549_2047_bytes => OPEN,
         stat_tx_packet_2048_4095_bytes => OPEN, stat_tx_packet_4096_8191_bytes => OPEN,stat_tx_packet_8192_9215_bytes => OPEN,
         stat_tx_packet_small => OPEN, stat_tx_packet_large => OPEN, stat_tx_frame_error => OPEN,

         ctl_tx_enable => i_tx_enable, ctl_tx_send_rfi => tx_send_rfi,  ctl_tx_send_lfi => tx_send_lfi,  ctl_tx_send_idle => tx_send_idle,
         ctl_tx_test_pattern => '0');
   END GENERATE;
   
   quad132_gen: IF g_device = QUAD_100G_132 GENERATE

      mac_1: mac_100g_quad_132
      PORT MAP (
         gt0_rxp_in => gt_rxp_in(0), gt1_rxp_in => gt_rxp_in(1), gt2_rxp_in => gt_rxp_in(2), gt3_rxp_in => gt_rxp_in(3),
         gt0_rxn_in => gt_rxn_in(0), gt1_rxn_in => gt_rxn_in(1), gt2_rxn_in => gt_rxn_in(2), gt3_rxn_in => gt_rxn_in(3),
         gt0_txp_out => gt_txp_out(0), gt1_txp_out => gt_txp_out(1), gt2_txp_out => gt_txp_out(2), gt3_txp_out => gt_txp_out(3),
         gt0_txn_out => gt_txn_out(0), gt1_txn_out => gt_txn_out(1), gt2_txn_out => gt_txn_out(2), gt3_txn_out => gt_txn_out(3),
         gt_ref_clk_p => gt_refclk_p, gt_ref_clk_n => gt_refclk_n, gt_ref_clk_out => OPEN,

         sys_reset => sys_reset, core_drp_reset => '0', core_rx_reset => '0', core_tx_reset => '0',
         gt_rxresetdone => OPEN, gt_txresetdone => OPEN,

         drp_clk => '0', init_clk => dclk, gt_drpclk => dclk,
         gt_rxrecclkout => rx_clk_out, rx_clk => rx_clk_in, gt_txusrclk2 => i_tx_clk_out,

         gt_rxpolarity => g_rxpolarity, gt_txpolarity => g_txpolarity,
         gt_loopback_in => i_loopback,

         gt_eyescandataerror => OPEN,  gt_eyescanreset => X"0", gt_eyescantrigger => X"0",
         gt_rxbufstatus => OPEN, gt_rxcdrhold => X"0", gt_rxdfelpmreset => X"0", gt_rxlpmen => g_rxlpmen,
         gt_rxrate => X"000", gt_rxprbscntreset => X"0", gt_rxprbserr => OPEN, gt_rxprbssel => X"0000",
         gt_txbufstatus => OPEN, gt_txdiffctrl => c_txdiffctrl, gt_txinhibit => X"0", gt_txpostcursor => c_txpostcursor,
         gt_txprbsforceerr => X"0", gt_txprbssel => X"0000", gt_txprecursor => c_txprecursor,
         gtwiz_reset_tx_datapath => '0', gtwiz_reset_rx_datapath => '0',

         common0_drpaddr => X"0000", common0_drpdi => X"0000", common0_drpwe => '0',
         common0_drpen => '0', common0_drprdy => OPEN, common0_drpdo => OPEN,

         gt0_drpdo => OPEN, gt1_drpdo => OPEN, gt2_drpdo => OPEN, gt3_drpdo => OPEN,
         gt0_drprdy => OPEN, gt1_drprdy => OPEN, gt2_drprdy => OPEN, gt3_drprdy => OPEN,
         gt0_drpen => '0', gt1_drpen => '0', gt2_drpen => '0', gt3_drpen => '0',
         gt0_drpwe => '0', gt1_drpwe => '0', gt2_drpwe => '0', gt3_drpwe => '0',
         gt0_drpaddr => gnd(9 DOWNTO 0), gt1_drpaddr => gnd(9 DOWNTO 0), gt2_drpaddr => gnd(9 DOWNTO 0), gt3_drpaddr => gnd(9 DOWNTO 0),
         gt0_drpdi => X"0000", gt1_drpdi => X"0000", gt2_drpdi => X"0000", gt3_drpdi => X"0000",
         drp_addr => gnd(9 DOWNTO 0), drp_di => X"0000", drp_en => '0',
         drp_we => '0', drp_do => OPEN, drp_rdy => OPEN,

         gt_powergoodout => OPEN,

         ctl_tx_rsfec_enable => rsfec_tx_enable, ctl_rx_rsfec_enable => rsfec_rx_enable, ctl_rsfec_ieee_error_indication_mode => '1',
         ctl_rx_rsfec_enable_correction => '1', ctl_rx_rsfec_enable_indication => '1',

         usr_rx_reset => i_user_rx_reset,
         rx_dataout0 => data_rx_sosi.data(127 DOWNTO 0), rx_dataout1 => data_rx_sosi.data(255 DOWNTO 128),
         rx_dataout2 => data_rx_sosi.data(383 DOWNTO 256), rx_dataout3 => data_rx_sosi.data(511 DOWNTO 384),
         rx_enaout0 => data_rx_sosi.valid(0), rx_enaout1 => data_rx_sosi.valid(1), rx_enaout2 => data_rx_sosi.valid(2), rx_enaout3 => data_rx_sosi.valid(3),
         rx_eopout0 => data_rx_sosi.eop(0), rx_eopout1 => data_rx_sosi.eop(1), rx_eopout2 => data_rx_sosi.eop(2), rx_eopout3 => data_rx_sosi.eop(3),
         rx_errout0 => data_rx_sosi.error(0), rx_errout1 => data_rx_sosi.error(1), rx_errout2 => data_rx_sosi.error(2), rx_errout3 => data_rx_sosi.error(3),
         rx_mtyout0 => data_rx_sosi.empty(0), rx_mtyout1 => data_rx_sosi.empty(1), rx_mtyout2 => data_rx_sosi.empty(2), rx_mtyout3 => data_rx_sosi.empty(3),
         rx_sopout0 => data_rx_sosi.sop(0), rx_sopout1 => data_rx_sosi.sop(1), rx_sopout2 => data_rx_sosi.sop(2), rx_sopout3 => data_rx_sosi.sop(3),

         ctl_rx_enable => rx_enable, ctl_rx_force_resync => '0', ctl_rx_test_pattern => '0',
         stat_rx_local_fault => OPEN, stat_rx_block_lock => OPEN,
         rx_otn_bip8_0 => OPEN, rx_otn_bip8_1 => OPEN, rx_otn_bip8_2 => OPEN, rx_otn_bip8_3 => OPEN, rx_otn_bip8_4 => OPEN,
         rx_otn_data_0 => OPEN, rx_otn_data_1 => OPEN, rx_otn_data_2 => OPEN, rx_otn_data_3 => OPEN, rx_otn_data_4 => OPEN,
         rx_otn_ena => OPEN, rx_otn_lane0 => OPEN, rx_otn_vlmarker => OPEN,

         stat_rx_unicast => OPEN, stat_rx_vlan => OPEN, stat_rx_pcsl_demuxed => OPEN,
         stat_rx_rsfec_am_lock0 => OPEN, stat_rx_rsfec_am_lock1 => OPEN, stat_rx_rsfec_am_lock2 => OPEN, stat_rx_rsfec_am_lock3 => OPEN,
         stat_rx_rsfec_corrected_cw_inc => OPEN, stat_rx_rsfec_cw_inc => OPEN,
         stat_rx_rsfec_err_count0_inc => OPEN, stat_rx_rsfec_err_count1_inc => OPEN, stat_rx_rsfec_err_count2_inc => OPEN,
         stat_rx_rsfec_err_count3_inc => OPEN, stat_rx_rsfec_hi_ser => OPEN, stat_rx_rsfec_lane_alignment_status => OPEN,
         stat_rx_rsfec_lane_fill_0 => OPEN, stat_rx_rsfec_lane_fill_1 => OPEN, stat_rx_rsfec_lane_fill_2 => OPEN,
         stat_rx_rsfec_lane_fill_3 => OPEN, stat_rx_rsfec_lane_mapping => OPEN, stat_rx_rsfec_uncorrected_cw_inc => OPEN,
         stat_rx_status => OPEN, stat_rx_test_pattern_mismatch => OPEN,
         stat_rx_remote_fault => rx_remote_fault, stat_rx_bad_fcs => OPEN, stat_rx_stomped_fcs => OPEN, stat_rx_truncated => OPEN,
         stat_rx_internal_local_fault => rx_local_fault, stat_rx_received_local_fault => rx_receive_local_fault, stat_rx_hi_ber => OPEN, stat_rx_got_signal_os => OPEN,
         stat_rx_total_bytes => stat_rx_total_bytes, stat_rx_total_packets => stat_rx_total_packets, stat_rx_total_good_bytes => OPEN, stat_rx_total_good_packets => OPEN,
         stat_rx_packet_bad_fcs => stat_rx_bad_fcs, stat_rx_packet_64_bytes => OPEN, stat_rx_packet_65_127_bytes => OPEN, stat_rx_packet_128_255_bytes => OPEN,
         stat_rx_packet_256_511_bytes => OPEN, stat_rx_packet_512_1023_bytes => OPEN, stat_rx_packet_1024_1518_bytes => OPEN,
         stat_rx_packet_1519_1522_bytes => OPEN, stat_rx_packet_1523_1548_bytes => OPEN, stat_rx_packet_1549_2047_bytes => OPEN,
         stat_rx_packet_2048_4095_bytes => OPEN, stat_rx_packet_4096_8191_bytes => OPEN, stat_rx_packet_8192_9215_bytes => OPEN,
         stat_rx_packet_small => OPEN, stat_rx_packet_large => OPEN,  stat_rx_oversize => OPEN, stat_rx_toolong => OPEN, stat_rx_undersize => OPEN,
         stat_rx_fragment => OPEN, stat_rx_jabber => OPEN, stat_rx_bad_code => stat_rx_bad_code, stat_rx_bad_sfd => OPEN, stat_rx_bad_preamble => OPEN,
         stat_rx_pcsl_number_0 => OPEN, stat_rx_pcsl_number_1 => OPEN, stat_rx_pcsl_number_2 => OPEN, stat_rx_pcsl_number_3 => OPEN,
         stat_rx_pcsl_number_4 => OPEN, stat_rx_pcsl_number_5 => OPEN, stat_rx_pcsl_number_6 => OPEN, stat_rx_pcsl_number_7 => OPEN,
         stat_rx_pcsl_number_8 => OPEN, stat_rx_pcsl_number_9 => OPEN, stat_rx_pcsl_number_10 => OPEN, stat_rx_pcsl_number_11 => OPEN,
         stat_rx_pcsl_number_12 => OPEN, stat_rx_pcsl_number_13 => OPEN, stat_rx_pcsl_number_14 => OPEN, stat_rx_pcsl_number_15 => OPEN,
         stat_rx_pcsl_number_16 => OPEN, stat_rx_pcsl_number_17 => OPEN, stat_rx_pcsl_number_18 => OPEN, stat_rx_pcsl_number_19 => OPEN,
         stat_tx_broadcast => OPEN, stat_tx_multicast => OPEN, stat_tx_unicast => OPEN, stat_tx_vlan => OPEN,
         stat_rx_bip_err_0 => OPEN, stat_rx_bip_err_1 => OPEN, stat_rx_bip_err_2 => OPEN, stat_rx_bip_err_3 => OPEN,
         stat_rx_bip_err_4 => OPEN, stat_rx_bip_err_5 => OPEN, stat_rx_bip_err_6 => OPEN, stat_rx_bip_err_7 => OPEN,
         stat_rx_bip_err_8 => OPEN, stat_rx_bip_err_9 => OPEN, stat_rx_bip_err_10 => OPEN, stat_rx_bip_err_11 => OPEN,
         stat_rx_bip_err_12 => OPEN, stat_rx_bip_err_13 => OPEN, stat_rx_bip_err_14 => OPEN, stat_rx_bip_err_15 => OPEN,
         stat_rx_bip_err_16 => OPEN, stat_rx_bip_err_17 => OPEN, stat_rx_bip_err_18 => OPEN, stat_rx_bip_err_19 => OPEN,
         stat_rx_framing_err_0 => OPEN, stat_rx_framing_err_1 => OPEN, stat_rx_framing_err_2 => OPEN, stat_rx_framing_err_3 => OPEN,
         stat_rx_framing_err_4 => OPEN, stat_rx_framing_err_5 => OPEN, stat_rx_framing_err_6 => OPEN, stat_rx_framing_err_7 => OPEN,
         stat_rx_framing_err_8 => OPEN, stat_rx_framing_err_9 => OPEN, stat_rx_framing_err_10 => OPEN, stat_rx_framing_err_11 => OPEN,
         stat_rx_framing_err_12 => OPEN, stat_rx_framing_err_13 => OPEN, stat_rx_framing_err_14 => OPEN, stat_rx_framing_err_15 => OPEN,
         stat_rx_framing_err_16 => OPEN, stat_rx_framing_err_17 => OPEN, stat_rx_framing_err_18 => OPEN, stat_rx_framing_err_19 => OPEN,
         stat_rx_framing_err_valid_0 => OPEN, stat_rx_framing_err_valid_1 => OPEN, stat_rx_framing_err_valid_2 => OPEN,
         stat_rx_framing_err_valid_3 => OPEN, stat_rx_framing_err_valid_4 => OPEN, stat_rx_framing_err_valid_5 => OPEN,
         stat_rx_framing_err_valid_6 => OPEN, stat_rx_framing_err_valid_7 => OPEN, stat_rx_framing_err_valid_8 => OPEN,
         stat_rx_framing_err_valid_9 => OPEN, stat_rx_framing_err_valid_10 => OPEN, stat_rx_framing_err_valid_11 => OPEN,
         stat_rx_framing_err_valid_12 => OPEN, stat_rx_framing_err_valid_13 => OPEN, stat_rx_framing_err_valid_14 => OPEN,
         stat_rx_framing_err_valid_15 => OPEN, stat_rx_framing_err_valid_16 => OPEN, stat_rx_framing_err_valid_17 => OPEN,
         stat_rx_framing_err_valid_18 => OPEN, stat_rx_framing_err_valid_19 => OPEN, stat_rx_inrangeerr => OPEN, stat_rx_mf_err => OPEN,
         stat_rx_mf_len_err => OPEN, stat_rx_broadcast => OPEN, stat_rx_mf_repeat_err => OPEN, stat_rx_misaligned => OPEN,
         stat_rx_multicast => OPEN, stat_rx_aligned => i_rx_locked, stat_rx_aligned_err => OPEN,
         stat_rx_synced => OPEN, stat_rx_synced_err => OPEN,

         usr_tx_reset => i_user_tx_reset,
         tx_unfout => data_tx_siso.underflow, tx_ovfout => data_tx_siso.overflow, tx_rdyout => data_tx_siso.ready,
         tx_datain0 => data_tx_sosi.data(127 DOWNTO 0), tx_datain1 => data_tx_sosi.data(255 DOWNTO 128),
         tx_datain2 => data_tx_sosi.data(383 DOWNTO 256), tx_datain3 => data_tx_sosi.data(511 DOWNTO 384),
         tx_enain0 => data_tx_sosi.valid(0), tx_enain1 => data_tx_sosi.valid(1), tx_enain2 => data_tx_sosi.valid(2), tx_enain3 => data_tx_sosi.valid(3),
         tx_eopin0 => data_tx_sosi.eop(0), tx_eopin1 => data_tx_sosi.eop(1), tx_eopin2 => data_tx_sosi.eop(2), tx_eopin3 => data_tx_sosi.eop(3),
         tx_errin0 => data_tx_sosi.error(0), tx_errin1 => data_tx_sosi.error(1), tx_errin2 => data_tx_sosi.error(2), tx_errin3 => data_tx_sosi.error(3),
         tx_mtyin0 => data_tx_sosi.empty(0), tx_mtyin1 => data_tx_sosi.empty(1), tx_mtyin2 => data_tx_sosi.empty(2), tx_mtyin3 => data_tx_sosi.empty(3),
         tx_sopin0 => data_tx_sosi.sop(0), tx_sopin1 => data_tx_sosi.sop(1), tx_sopin2 => data_tx_sosi.sop(2), tx_sopin3 => data_tx_sosi.sop(3),

         tx_preamblein => gnd(55 DOWNTO 0), rx_preambleout => OPEN, stat_tx_local_fault => OPEN,
         stat_tx_total_bytes => stat_tx_total_bytes, stat_tx_total_packets => stat_tx_total_packets, stat_tx_total_good_bytes => OPEN, stat_tx_total_good_packets => OPEN,
         stat_tx_bad_fcs => OPEN, stat_tx_packet_64_bytes => OPEN, stat_tx_packet_65_127_bytes => OPEN, stat_tx_packet_128_255_bytes => OPEN,
         stat_tx_packet_256_511_bytes => OPEN, stat_tx_packet_512_1023_bytes => OPEN, stat_tx_packet_1024_1518_bytes => OPEN,
         stat_tx_packet_1519_1522_bytes => OPEN, stat_tx_packet_1523_1548_bytes => OPEN, stat_tx_packet_1549_2047_bytes => OPEN,
         stat_tx_packet_2048_4095_bytes => OPEN, stat_tx_packet_4096_8191_bytes => OPEN,stat_tx_packet_8192_9215_bytes => OPEN,
         stat_tx_packet_small => OPEN, stat_tx_packet_large => OPEN, stat_tx_frame_error => OPEN,

         ctl_tx_enable => i_tx_enable, ctl_tx_send_rfi => tx_send_rfi,  ctl_tx_send_lfi => tx_send_lfi,  ctl_tx_send_idle => tx_send_idle,
         ctl_tx_test_pattern => '0');
   END GENERATE;
   
   
   quad134_gen: IF g_device = QUAD_100G_134 GENERATE

      mac_1: mac_100g_quad_134
      PORT MAP (
         gt0_rxp_in => gt_rxp_in(0), gt1_rxp_in => gt_rxp_in(1), gt2_rxp_in => gt_rxp_in(2), gt3_rxp_in => gt_rxp_in(3),
         gt0_rxn_in => gt_rxn_in(0), gt1_rxn_in => gt_rxn_in(1), gt2_rxn_in => gt_rxn_in(2), gt3_rxn_in => gt_rxn_in(3),
         gt0_txp_out => gt_txp_out(0), gt1_txp_out => gt_txp_out(1), gt2_txp_out => gt_txp_out(2), gt3_txp_out => gt_txp_out(3),
         gt0_txn_out => gt_txn_out(0), gt1_txn_out => gt_txn_out(1), gt2_txn_out => gt_txn_out(2), gt3_txn_out => gt_txn_out(3),
         gt_ref_clk_p => gt_refclk_p, gt_ref_clk_n => gt_refclk_n, gt_ref_clk_out => OPEN,

         sys_reset => sys_reset, core_drp_reset => '0', core_rx_reset => '0', core_tx_reset => '0',
         gt_rxresetdone => OPEN, gt_txresetdone => OPEN,

         drp_clk => '0', init_clk => dclk, gt_drpclk => dclk,
         gt_rxrecclkout => rx_clk_out, rx_clk => rx_clk_in, gt_txusrclk2 => i_tx_clk_out,

         gt_rxpolarity => g_rxpolarity, gt_txpolarity => g_txpolarity,
         gt_loopback_in => i_loopback,

         gt_eyescandataerror => OPEN,  gt_eyescanreset => X"0", gt_eyescantrigger => X"0",
         gt_rxbufstatus => OPEN, gt_rxcdrhold => X"0", gt_rxdfelpmreset => X"0", gt_rxlpmen => g_rxlpmen,
         gt_rxrate => X"000", gt_rxprbscntreset => X"0", gt_rxprbserr => OPEN, gt_rxprbssel => X"0000",
         gt_txbufstatus => OPEN, gt_txdiffctrl => c_txdiffctrl, gt_txinhibit => X"0", gt_txpostcursor => c_txpostcursor,
         gt_txprbsforceerr => X"0", gt_txprbssel => X"0000", gt_txprecursor => c_txprecursor,
         gtwiz_reset_tx_datapath => '0', gtwiz_reset_rx_datapath => '0',

         common0_drpaddr => X"0000", common0_drpdi => X"0000", common0_drpwe => '0',
         common0_drpen => '0', common0_drprdy => OPEN, common0_drpdo => OPEN,

         gt0_drpdo => OPEN, gt1_drpdo => OPEN, gt2_drpdo => OPEN, gt3_drpdo => OPEN,
         gt0_drprdy => OPEN, gt1_drprdy => OPEN, gt2_drprdy => OPEN, gt3_drprdy => OPEN,
         gt0_drpen => '0', gt1_drpen => '0', gt2_drpen => '0', gt3_drpen => '0',
         gt0_drpwe => '0', gt1_drpwe => '0', gt2_drpwe => '0', gt3_drpwe => '0',
         gt0_drpaddr => gnd(9 DOWNTO 0), gt1_drpaddr => gnd(9 DOWNTO 0), gt2_drpaddr => gnd(9 DOWNTO 0), gt3_drpaddr => gnd(9 DOWNTO 0),
         gt0_drpdi => X"0000", gt1_drpdi => X"0000", gt2_drpdi => X"0000", gt3_drpdi => X"0000",
         drp_addr => gnd(9 DOWNTO 0), drp_di => X"0000", drp_en => '0',
         drp_we => '0', drp_do => OPEN, drp_rdy => OPEN,

         gt_powergoodout => OPEN,

         ctl_tx_rsfec_enable => rsfec_tx_enable, ctl_rx_rsfec_enable => rsfec_rx_enable, ctl_rsfec_ieee_error_indication_mode => '1',
         ctl_rx_rsfec_enable_correction => '1', ctl_rx_rsfec_enable_indication => '1',

         usr_rx_reset => i_user_rx_reset,
         rx_dataout0 => data_rx_sosi.data(127 DOWNTO 0), rx_dataout1 => data_rx_sosi.data(255 DOWNTO 128),
         rx_dataout2 => data_rx_sosi.data(383 DOWNTO 256), rx_dataout3 => data_rx_sosi.data(511 DOWNTO 384),
         rx_enaout0 => data_rx_sosi.valid(0), rx_enaout1 => data_rx_sosi.valid(1), rx_enaout2 => data_rx_sosi.valid(2), rx_enaout3 => data_rx_sosi.valid(3),
         rx_eopout0 => data_rx_sosi.eop(0), rx_eopout1 => data_rx_sosi.eop(1), rx_eopout2 => data_rx_sosi.eop(2), rx_eopout3 => data_rx_sosi.eop(3),
         rx_errout0 => data_rx_sosi.error(0), rx_errout1 => data_rx_sosi.error(1), rx_errout2 => data_rx_sosi.error(2), rx_errout3 => data_rx_sosi.error(3),
         rx_mtyout0 => data_rx_sosi.empty(0), rx_mtyout1 => data_rx_sosi.empty(1), rx_mtyout2 => data_rx_sosi.empty(2), rx_mtyout3 => data_rx_sosi.empty(3),
         rx_sopout0 => data_rx_sosi.sop(0), rx_sopout1 => data_rx_sosi.sop(1), rx_sopout2 => data_rx_sosi.sop(2), rx_sopout3 => data_rx_sosi.sop(3),

         ctl_rx_enable => rx_enable, ctl_rx_force_resync => '0', ctl_rx_test_pattern => '0',
         stat_rx_local_fault => OPEN, stat_rx_block_lock => OPEN,
         rx_otn_bip8_0 => OPEN, rx_otn_bip8_1 => OPEN, rx_otn_bip8_2 => OPEN, rx_otn_bip8_3 => OPEN, rx_otn_bip8_4 => OPEN,
         rx_otn_data_0 => OPEN, rx_otn_data_1 => OPEN, rx_otn_data_2 => OPEN, rx_otn_data_3 => OPEN, rx_otn_data_4 => OPEN,
         rx_otn_ena => OPEN, rx_otn_lane0 => OPEN, rx_otn_vlmarker => OPEN,

         stat_rx_unicast => OPEN, stat_rx_vlan => OPEN, stat_rx_pcsl_demuxed => OPEN,
         stat_rx_rsfec_am_lock0 => OPEN, stat_rx_rsfec_am_lock1 => OPEN, stat_rx_rsfec_am_lock2 => OPEN, stat_rx_rsfec_am_lock3 => OPEN,
         stat_rx_rsfec_corrected_cw_inc => OPEN, stat_rx_rsfec_cw_inc => OPEN,
         stat_rx_rsfec_err_count0_inc => OPEN, stat_rx_rsfec_err_count1_inc => OPEN, stat_rx_rsfec_err_count2_inc => OPEN,
         stat_rx_rsfec_err_count3_inc => OPEN, stat_rx_rsfec_hi_ser => OPEN, stat_rx_rsfec_lane_alignment_status => OPEN,
         stat_rx_rsfec_lane_fill_0 => OPEN, stat_rx_rsfec_lane_fill_1 => OPEN, stat_rx_rsfec_lane_fill_2 => OPEN,
         stat_rx_rsfec_lane_fill_3 => OPEN, stat_rx_rsfec_lane_mapping => OPEN, stat_rx_rsfec_uncorrected_cw_inc => OPEN,
         stat_rx_status => OPEN, stat_rx_test_pattern_mismatch => OPEN,
         stat_rx_remote_fault => rx_remote_fault, stat_rx_bad_fcs => OPEN, stat_rx_stomped_fcs => OPEN, stat_rx_truncated => OPEN,
         stat_rx_internal_local_fault => rx_local_fault, stat_rx_received_local_fault => rx_receive_local_fault, stat_rx_hi_ber => OPEN, stat_rx_got_signal_os => OPEN,
         stat_rx_total_bytes => stat_rx_total_bytes, stat_rx_total_packets => stat_rx_total_packets, stat_rx_total_good_bytes => OPEN, stat_rx_total_good_packets => OPEN,
         stat_rx_packet_bad_fcs => stat_rx_bad_fcs, stat_rx_packet_64_bytes => OPEN, stat_rx_packet_65_127_bytes => OPEN, stat_rx_packet_128_255_bytes => OPEN,
         stat_rx_packet_256_511_bytes => OPEN, stat_rx_packet_512_1023_bytes => OPEN, stat_rx_packet_1024_1518_bytes => OPEN,
         stat_rx_packet_1519_1522_bytes => OPEN, stat_rx_packet_1523_1548_bytes => OPEN, stat_rx_packet_1549_2047_bytes => OPEN,
         stat_rx_packet_2048_4095_bytes => OPEN, stat_rx_packet_4096_8191_bytes => OPEN, stat_rx_packet_8192_9215_bytes => OPEN,
         stat_rx_packet_small => OPEN, stat_rx_packet_large => OPEN,  stat_rx_oversize => OPEN, stat_rx_toolong => OPEN, stat_rx_undersize => OPEN,
         stat_rx_fragment => OPEN, stat_rx_jabber => OPEN, stat_rx_bad_code => stat_rx_bad_code, stat_rx_bad_sfd => OPEN, stat_rx_bad_preamble => OPEN,
         stat_rx_pcsl_number_0 => OPEN, stat_rx_pcsl_number_1 => OPEN, stat_rx_pcsl_number_2 => OPEN, stat_rx_pcsl_number_3 => OPEN,
         stat_rx_pcsl_number_4 => OPEN, stat_rx_pcsl_number_5 => OPEN, stat_rx_pcsl_number_6 => OPEN, stat_rx_pcsl_number_7 => OPEN,
         stat_rx_pcsl_number_8 => OPEN, stat_rx_pcsl_number_9 => OPEN, stat_rx_pcsl_number_10 => OPEN, stat_rx_pcsl_number_11 => OPEN,
         stat_rx_pcsl_number_12 => OPEN, stat_rx_pcsl_number_13 => OPEN, stat_rx_pcsl_number_14 => OPEN, stat_rx_pcsl_number_15 => OPEN,
         stat_rx_pcsl_number_16 => OPEN, stat_rx_pcsl_number_17 => OPEN, stat_rx_pcsl_number_18 => OPEN, stat_rx_pcsl_number_19 => OPEN,
         stat_tx_broadcast => OPEN, stat_tx_multicast => OPEN, stat_tx_unicast => OPEN, stat_tx_vlan => OPEN,
         stat_rx_bip_err_0 => OPEN, stat_rx_bip_err_1 => OPEN, stat_rx_bip_err_2 => OPEN, stat_rx_bip_err_3 => OPEN,
         stat_rx_bip_err_4 => OPEN, stat_rx_bip_err_5 => OPEN, stat_rx_bip_err_6 => OPEN, stat_rx_bip_err_7 => OPEN,
         stat_rx_bip_err_8 => OPEN, stat_rx_bip_err_9 => OPEN, stat_rx_bip_err_10 => OPEN, stat_rx_bip_err_11 => OPEN,
         stat_rx_bip_err_12 => OPEN, stat_rx_bip_err_13 => OPEN, stat_rx_bip_err_14 => OPEN, stat_rx_bip_err_15 => OPEN,
         stat_rx_bip_err_16 => OPEN, stat_rx_bip_err_17 => OPEN, stat_rx_bip_err_18 => OPEN, stat_rx_bip_err_19 => OPEN,
         stat_rx_framing_err_0 => OPEN, stat_rx_framing_err_1 => OPEN, stat_rx_framing_err_2 => OPEN, stat_rx_framing_err_3 => OPEN,
         stat_rx_framing_err_4 => OPEN, stat_rx_framing_err_5 => OPEN, stat_rx_framing_err_6 => OPEN, stat_rx_framing_err_7 => OPEN,
         stat_rx_framing_err_8 => OPEN, stat_rx_framing_err_9 => OPEN, stat_rx_framing_err_10 => OPEN, stat_rx_framing_err_11 => OPEN,
         stat_rx_framing_err_12 => OPEN, stat_rx_framing_err_13 => OPEN, stat_rx_framing_err_14 => OPEN, stat_rx_framing_err_15 => OPEN,
         stat_rx_framing_err_16 => OPEN, stat_rx_framing_err_17 => OPEN, stat_rx_framing_err_18 => OPEN, stat_rx_framing_err_19 => OPEN,
         stat_rx_framing_err_valid_0 => OPEN, stat_rx_framing_err_valid_1 => OPEN, stat_rx_framing_err_valid_2 => OPEN,
         stat_rx_framing_err_valid_3 => OPEN, stat_rx_framing_err_valid_4 => OPEN, stat_rx_framing_err_valid_5 => OPEN,
         stat_rx_framing_err_valid_6 => OPEN, stat_rx_framing_err_valid_7 => OPEN, stat_rx_framing_err_valid_8 => OPEN,
         stat_rx_framing_err_valid_9 => OPEN, stat_rx_framing_err_valid_10 => OPEN, stat_rx_framing_err_valid_11 => OPEN,
         stat_rx_framing_err_valid_12 => OPEN, stat_rx_framing_err_valid_13 => OPEN, stat_rx_framing_err_valid_14 => OPEN,
         stat_rx_framing_err_valid_15 => OPEN, stat_rx_framing_err_valid_16 => OPEN, stat_rx_framing_err_valid_17 => OPEN,
         stat_rx_framing_err_valid_18 => OPEN, stat_rx_framing_err_valid_19 => OPEN, stat_rx_inrangeerr => OPEN, stat_rx_mf_err => OPEN,
         stat_rx_mf_len_err => OPEN, stat_rx_broadcast => OPEN, stat_rx_mf_repeat_err => OPEN, stat_rx_misaligned => OPEN,
         stat_rx_multicast => OPEN, stat_rx_aligned => i_rx_locked, stat_rx_aligned_err => OPEN,
         stat_rx_synced => OPEN, stat_rx_synced_err => OPEN,

         usr_tx_reset => i_user_tx_reset,
         tx_unfout => data_tx_siso.underflow, tx_ovfout => data_tx_siso.overflow, tx_rdyout => data_tx_siso.ready,
         tx_datain0 => data_tx_sosi.data(127 DOWNTO 0), tx_datain1 => data_tx_sosi.data(255 DOWNTO 128),
         tx_datain2 => data_tx_sosi.data(383 DOWNTO 256), tx_datain3 => data_tx_sosi.data(511 DOWNTO 384),
         tx_enain0 => data_tx_sosi.valid(0), tx_enain1 => data_tx_sosi.valid(1), tx_enain2 => data_tx_sosi.valid(2), tx_enain3 => data_tx_sosi.valid(3),
         tx_eopin0 => data_tx_sosi.eop(0), tx_eopin1 => data_tx_sosi.eop(1), tx_eopin2 => data_tx_sosi.eop(2), tx_eopin3 => data_tx_sosi.eop(3),
         tx_errin0 => data_tx_sosi.error(0), tx_errin1 => data_tx_sosi.error(1), tx_errin2 => data_tx_sosi.error(2), tx_errin3 => data_tx_sosi.error(3),
         tx_mtyin0 => data_tx_sosi.empty(0), tx_mtyin1 => data_tx_sosi.empty(1), tx_mtyin2 => data_tx_sosi.empty(2), tx_mtyin3 => data_tx_sosi.empty(3),
         tx_sopin0 => data_tx_sosi.sop(0), tx_sopin1 => data_tx_sosi.sop(1), tx_sopin2 => data_tx_sosi.sop(2), tx_sopin3 => data_tx_sosi.sop(3),

         tx_preamblein => gnd(55 DOWNTO 0), rx_preambleout => OPEN, stat_tx_local_fault => OPEN,
         stat_tx_total_bytes => stat_tx_total_bytes, stat_tx_total_packets => stat_tx_total_packets, stat_tx_total_good_bytes => OPEN, stat_tx_total_good_packets => OPEN,
         stat_tx_bad_fcs => OPEN, stat_tx_packet_64_bytes => OPEN, stat_tx_packet_65_127_bytes => OPEN, stat_tx_packet_128_255_bytes => OPEN,
         stat_tx_packet_256_511_bytes => OPEN, stat_tx_packet_512_1023_bytes => OPEN, stat_tx_packet_1024_1518_bytes => OPEN,
         stat_tx_packet_1519_1522_bytes => OPEN, stat_tx_packet_1523_1548_bytes => OPEN, stat_tx_packet_1549_2047_bytes => OPEN,
         stat_tx_packet_2048_4095_bytes => OPEN, stat_tx_packet_4096_8191_bytes => OPEN,stat_tx_packet_8192_9215_bytes => OPEN,
         stat_tx_packet_small => OPEN, stat_tx_packet_large => OPEN, stat_tx_frame_error => OPEN,

         ctl_tx_enable => i_tx_enable, ctl_tx_send_rfi => tx_send_rfi,  ctl_tx_send_lfi => tx_send_lfi,  ctl_tx_send_idle => tx_send_idle,
         ctl_tx_test_pattern => '0');
   END GENERATE;
   
   quad135_gen: IF g_device = QUAD_100G_135 GENERATE

      mac_1: mac_100g_quad_135
      PORT MAP (
         gt0_rxp_in => gt_rxp_in(0), gt1_rxp_in => gt_rxp_in(1), gt2_rxp_in => gt_rxp_in(2), gt3_rxp_in => gt_rxp_in(3),
         gt0_rxn_in => gt_rxn_in(0), gt1_rxn_in => gt_rxn_in(1), gt2_rxn_in => gt_rxn_in(2), gt3_rxn_in => gt_rxn_in(3),
         gt0_txp_out => gt_txp_out(0), gt1_txp_out => gt_txp_out(1), gt2_txp_out => gt_txp_out(2), gt3_txp_out => gt_txp_out(3),
         gt0_txn_out => gt_txn_out(0), gt1_txn_out => gt_txn_out(1), gt2_txn_out => gt_txn_out(2), gt3_txn_out => gt_txn_out(3),
         gt_ref_clk_p => gt_refclk_p, gt_ref_clk_n => gt_refclk_n, gt_ref_clk_out => OPEN,

         sys_reset => sys_reset, core_drp_reset => '0', core_rx_reset => '0', core_tx_reset => '0',
         gt_rxresetdone => OPEN, gt_txresetdone => OPEN,

         drp_clk => '0', init_clk => dclk, gt_drpclk => dclk,
         gt_rxrecclkout => rx_clk_out, rx_clk => rx_clk_in, gt_txusrclk2 => i_tx_clk_out,

         gt_rxpolarity => g_rxpolarity, gt_txpolarity => g_txpolarity,
         gt_loopback_in => i_loopback,

         gt_eyescandataerror => OPEN,  gt_eyescanreset => X"0", gt_eyescantrigger => X"0",
         gt_rxbufstatus => OPEN, gt_rxcdrhold => X"0", gt_rxdfelpmreset => X"0", gt_rxlpmen => g_rxlpmen,
         gt_rxrate => X"000", gt_rxprbscntreset => X"0", gt_rxprbserr => OPEN, gt_rxprbssel => X"0000",
         gt_txbufstatus => OPEN, gt_txdiffctrl => c_txdiffctrl, gt_txinhibit => X"0", gt_txpostcursor => c_txpostcursor,
         gt_txprbsforceerr => X"0", gt_txprbssel => X"0000", gt_txprecursor => c_txprecursor,
         gtwiz_reset_tx_datapath => '0', gtwiz_reset_rx_datapath => '0',

         common0_drpaddr => X"0000", common0_drpdi => X"0000", common0_drpwe => '0',
         common0_drpen => '0', common0_drprdy => OPEN, common0_drpdo => OPEN,

         gt0_drpdo => OPEN, gt1_drpdo => OPEN, gt2_drpdo => OPEN, gt3_drpdo => OPEN,
         gt0_drprdy => OPEN, gt1_drprdy => OPEN, gt2_drprdy => OPEN, gt3_drprdy => OPEN,
         gt0_drpen => '0', gt1_drpen => '0', gt2_drpen => '0', gt3_drpen => '0',
         gt0_drpwe => '0', gt1_drpwe => '0', gt2_drpwe => '0', gt3_drpwe => '0',
         gt0_drpaddr => gnd(9 DOWNTO 0), gt1_drpaddr => gnd(9 DOWNTO 0), gt2_drpaddr => gnd(9 DOWNTO 0), gt3_drpaddr => gnd(9 DOWNTO 0),
         gt0_drpdi => X"0000", gt1_drpdi => X"0000", gt2_drpdi => X"0000", gt3_drpdi => X"0000",
         drp_addr => gnd(9 DOWNTO 0), drp_di => X"0000", drp_en => '0',
         drp_we => '0', drp_do => OPEN, drp_rdy => OPEN,

         gt_powergoodout => OPEN,

         ctl_tx_rsfec_enable => rsfec_tx_enable, ctl_rx_rsfec_enable => rsfec_rx_enable, ctl_rsfec_ieee_error_indication_mode => '1',
         ctl_rx_rsfec_enable_correction => '1', ctl_rx_rsfec_enable_indication => '1',

         usr_rx_reset => i_user_rx_reset,
         rx_dataout0 => data_rx_sosi.data(127 DOWNTO 0), rx_dataout1 => data_rx_sosi.data(255 DOWNTO 128),
         rx_dataout2 => data_rx_sosi.data(383 DOWNTO 256), rx_dataout3 => data_rx_sosi.data(511 DOWNTO 384),
         rx_enaout0 => data_rx_sosi.valid(0), rx_enaout1 => data_rx_sosi.valid(1), rx_enaout2 => data_rx_sosi.valid(2), rx_enaout3 => data_rx_sosi.valid(3),
         rx_eopout0 => data_rx_sosi.eop(0), rx_eopout1 => data_rx_sosi.eop(1), rx_eopout2 => data_rx_sosi.eop(2), rx_eopout3 => data_rx_sosi.eop(3),
         rx_errout0 => data_rx_sosi.error(0), rx_errout1 => data_rx_sosi.error(1), rx_errout2 => data_rx_sosi.error(2), rx_errout3 => data_rx_sosi.error(3),
         rx_mtyout0 => data_rx_sosi.empty(0), rx_mtyout1 => data_rx_sosi.empty(1), rx_mtyout2 => data_rx_sosi.empty(2), rx_mtyout3 => data_rx_sosi.empty(3),
         rx_sopout0 => data_rx_sosi.sop(0), rx_sopout1 => data_rx_sosi.sop(1), rx_sopout2 => data_rx_sosi.sop(2), rx_sopout3 => data_rx_sosi.sop(3),

         ctl_rx_enable => rx_enable, ctl_rx_force_resync => '0', ctl_rx_test_pattern => '0',
         stat_rx_local_fault => OPEN, stat_rx_block_lock => OPEN,
         rx_otn_bip8_0 => OPEN, rx_otn_bip8_1 => OPEN, rx_otn_bip8_2 => OPEN, rx_otn_bip8_3 => OPEN, rx_otn_bip8_4 => OPEN,
         rx_otn_data_0 => OPEN, rx_otn_data_1 => OPEN, rx_otn_data_2 => OPEN, rx_otn_data_3 => OPEN, rx_otn_data_4 => OPEN,
         rx_otn_ena => OPEN, rx_otn_lane0 => OPEN, rx_otn_vlmarker => OPEN,

         stat_rx_unicast => OPEN, stat_rx_vlan => OPEN, stat_rx_pcsl_demuxed => OPEN,
         stat_rx_rsfec_am_lock0 => OPEN, stat_rx_rsfec_am_lock1 => OPEN, stat_rx_rsfec_am_lock2 => OPEN, stat_rx_rsfec_am_lock3 => OPEN,
         stat_rx_rsfec_corrected_cw_inc => OPEN, stat_rx_rsfec_cw_inc => OPEN,
         stat_rx_rsfec_err_count0_inc => OPEN, stat_rx_rsfec_err_count1_inc => OPEN, stat_rx_rsfec_err_count2_inc => OPEN,
         stat_rx_rsfec_err_count3_inc => OPEN, stat_rx_rsfec_hi_ser => OPEN, stat_rx_rsfec_lane_alignment_status => OPEN,
         stat_rx_rsfec_lane_fill_0 => OPEN, stat_rx_rsfec_lane_fill_1 => OPEN, stat_rx_rsfec_lane_fill_2 => OPEN,
         stat_rx_rsfec_lane_fill_3 => OPEN, stat_rx_rsfec_lane_mapping => OPEN, stat_rx_rsfec_uncorrected_cw_inc => OPEN,
         stat_rx_status => OPEN, stat_rx_test_pattern_mismatch => OPEN,
         stat_rx_remote_fault => rx_remote_fault, stat_rx_bad_fcs => OPEN, stat_rx_stomped_fcs => OPEN, stat_rx_truncated => OPEN,
         stat_rx_internal_local_fault => rx_local_fault, stat_rx_received_local_fault => rx_receive_local_fault, stat_rx_hi_ber => OPEN, stat_rx_got_signal_os => OPEN,
         stat_rx_total_bytes => stat_rx_total_bytes, stat_rx_total_packets => stat_rx_total_packets, stat_rx_total_good_bytes => OPEN, stat_rx_total_good_packets => OPEN,
         stat_rx_packet_bad_fcs => stat_rx_bad_fcs, stat_rx_packet_64_bytes => OPEN, stat_rx_packet_65_127_bytes => OPEN, stat_rx_packet_128_255_bytes => OPEN,
         stat_rx_packet_256_511_bytes => OPEN, stat_rx_packet_512_1023_bytes => OPEN, stat_rx_packet_1024_1518_bytes => OPEN,
         stat_rx_packet_1519_1522_bytes => OPEN, stat_rx_packet_1523_1548_bytes => OPEN, stat_rx_packet_1549_2047_bytes => OPEN,
         stat_rx_packet_2048_4095_bytes => OPEN, stat_rx_packet_4096_8191_bytes => OPEN, stat_rx_packet_8192_9215_bytes => OPEN,
         stat_rx_packet_small => OPEN, stat_rx_packet_large => OPEN,  stat_rx_oversize => OPEN, stat_rx_toolong => OPEN, stat_rx_undersize => OPEN,
         stat_rx_fragment => OPEN, stat_rx_jabber => OPEN, stat_rx_bad_code => stat_rx_bad_code, stat_rx_bad_sfd => OPEN, stat_rx_bad_preamble => OPEN,
         stat_rx_pcsl_number_0 => OPEN, stat_rx_pcsl_number_1 => OPEN, stat_rx_pcsl_number_2 => OPEN, stat_rx_pcsl_number_3 => OPEN,
         stat_rx_pcsl_number_4 => OPEN, stat_rx_pcsl_number_5 => OPEN, stat_rx_pcsl_number_6 => OPEN, stat_rx_pcsl_number_7 => OPEN,
         stat_rx_pcsl_number_8 => OPEN, stat_rx_pcsl_number_9 => OPEN, stat_rx_pcsl_number_10 => OPEN, stat_rx_pcsl_number_11 => OPEN,
         stat_rx_pcsl_number_12 => OPEN, stat_rx_pcsl_number_13 => OPEN, stat_rx_pcsl_number_14 => OPEN, stat_rx_pcsl_number_15 => OPEN,
         stat_rx_pcsl_number_16 => OPEN, stat_rx_pcsl_number_17 => OPEN, stat_rx_pcsl_number_18 => OPEN, stat_rx_pcsl_number_19 => OPEN,
         stat_tx_broadcast => OPEN, stat_tx_multicast => OPEN, stat_tx_unicast => OPEN, stat_tx_vlan => OPEN,
         stat_rx_bip_err_0 => OPEN, stat_rx_bip_err_1 => OPEN, stat_rx_bip_err_2 => OPEN, stat_rx_bip_err_3 => OPEN,
         stat_rx_bip_err_4 => OPEN, stat_rx_bip_err_5 => OPEN, stat_rx_bip_err_6 => OPEN, stat_rx_bip_err_7 => OPEN,
         stat_rx_bip_err_8 => OPEN, stat_rx_bip_err_9 => OPEN, stat_rx_bip_err_10 => OPEN, stat_rx_bip_err_11 => OPEN,
         stat_rx_bip_err_12 => OPEN, stat_rx_bip_err_13 => OPEN, stat_rx_bip_err_14 => OPEN, stat_rx_bip_err_15 => OPEN,
         stat_rx_bip_err_16 => OPEN, stat_rx_bip_err_17 => OPEN, stat_rx_bip_err_18 => OPEN, stat_rx_bip_err_19 => OPEN,
         stat_rx_framing_err_0 => OPEN, stat_rx_framing_err_1 => OPEN, stat_rx_framing_err_2 => OPEN, stat_rx_framing_err_3 => OPEN,
         stat_rx_framing_err_4 => OPEN, stat_rx_framing_err_5 => OPEN, stat_rx_framing_err_6 => OPEN, stat_rx_framing_err_7 => OPEN,
         stat_rx_framing_err_8 => OPEN, stat_rx_framing_err_9 => OPEN, stat_rx_framing_err_10 => OPEN, stat_rx_framing_err_11 => OPEN,
         stat_rx_framing_err_12 => OPEN, stat_rx_framing_err_13 => OPEN, stat_rx_framing_err_14 => OPEN, stat_rx_framing_err_15 => OPEN,
         stat_rx_framing_err_16 => OPEN, stat_rx_framing_err_17 => OPEN, stat_rx_framing_err_18 => OPEN, stat_rx_framing_err_19 => OPEN,
         stat_rx_framing_err_valid_0 => OPEN, stat_rx_framing_err_valid_1 => OPEN, stat_rx_framing_err_valid_2 => OPEN,
         stat_rx_framing_err_valid_3 => OPEN, stat_rx_framing_err_valid_4 => OPEN, stat_rx_framing_err_valid_5 => OPEN,
         stat_rx_framing_err_valid_6 => OPEN, stat_rx_framing_err_valid_7 => OPEN, stat_rx_framing_err_valid_8 => OPEN,
         stat_rx_framing_err_valid_9 => OPEN, stat_rx_framing_err_valid_10 => OPEN, stat_rx_framing_err_valid_11 => OPEN,
         stat_rx_framing_err_valid_12 => OPEN, stat_rx_framing_err_valid_13 => OPEN, stat_rx_framing_err_valid_14 => OPEN,
         stat_rx_framing_err_valid_15 => OPEN, stat_rx_framing_err_valid_16 => OPEN, stat_rx_framing_err_valid_17 => OPEN,
         stat_rx_framing_err_valid_18 => OPEN, stat_rx_framing_err_valid_19 => OPEN, stat_rx_inrangeerr => OPEN, stat_rx_mf_err => OPEN,
         stat_rx_mf_len_err => OPEN, stat_rx_broadcast => OPEN, stat_rx_mf_repeat_err => OPEN, stat_rx_misaligned => OPEN,
         stat_rx_multicast => OPEN, stat_rx_aligned => i_rx_locked, stat_rx_aligned_err => OPEN,
         stat_rx_synced => OPEN, stat_rx_synced_err => OPEN,

         usr_tx_reset => i_user_tx_reset,
         tx_unfout => data_tx_siso.underflow, tx_ovfout => data_tx_siso.overflow, tx_rdyout => data_tx_siso.ready,
         tx_datain0 => data_tx_sosi.data(127 DOWNTO 0), tx_datain1 => data_tx_sosi.data(255 DOWNTO 128),
         tx_datain2 => data_tx_sosi.data(383 DOWNTO 256), tx_datain3 => data_tx_sosi.data(511 DOWNTO 384),
         tx_enain0 => data_tx_sosi.valid(0), tx_enain1 => data_tx_sosi.valid(1), tx_enain2 => data_tx_sosi.valid(2), tx_enain3 => data_tx_sosi.valid(3),
         tx_eopin0 => data_tx_sosi.eop(0), tx_eopin1 => data_tx_sosi.eop(1), tx_eopin2 => data_tx_sosi.eop(2), tx_eopin3 => data_tx_sosi.eop(3),
         tx_errin0 => data_tx_sosi.error(0), tx_errin1 => data_tx_sosi.error(1), tx_errin2 => data_tx_sosi.error(2), tx_errin3 => data_tx_sosi.error(3),
         tx_mtyin0 => data_tx_sosi.empty(0), tx_mtyin1 => data_tx_sosi.empty(1), tx_mtyin2 => data_tx_sosi.empty(2), tx_mtyin3 => data_tx_sosi.empty(3),
         tx_sopin0 => data_tx_sosi.sop(0), tx_sopin1 => data_tx_sosi.sop(1), tx_sopin2 => data_tx_sosi.sop(2), tx_sopin3 => data_tx_sosi.sop(3),

         tx_preamblein => gnd(55 DOWNTO 0), rx_preambleout => OPEN, stat_tx_local_fault => OPEN,
         stat_tx_total_bytes => stat_tx_total_bytes, stat_tx_total_packets => stat_tx_total_packets, stat_tx_total_good_bytes => OPEN, stat_tx_total_good_packets => OPEN,
         stat_tx_bad_fcs => OPEN, stat_tx_packet_64_bytes => OPEN, stat_tx_packet_65_127_bytes => OPEN, stat_tx_packet_128_255_bytes => OPEN,
         stat_tx_packet_256_511_bytes => OPEN, stat_tx_packet_512_1023_bytes => OPEN, stat_tx_packet_1024_1518_bytes => OPEN,
         stat_tx_packet_1519_1522_bytes => OPEN, stat_tx_packet_1523_1548_bytes => OPEN, stat_tx_packet_1549_2047_bytes => OPEN,
         stat_tx_packet_2048_4095_bytes => OPEN, stat_tx_packet_4096_8191_bytes => OPEN,stat_tx_packet_8192_9215_bytes => OPEN,
         stat_tx_packet_small => OPEN, stat_tx_packet_large => OPEN, stat_tx_frame_error => OPEN,

         ctl_tx_enable => i_tx_enable, ctl_tx_send_rfi => tx_send_rfi,  ctl_tx_send_lfi => tx_send_lfi,  ctl_tx_send_idle => tx_send_idle,
         ctl_tx_test_pattern => '0');
   END GENERATE;




END GENERATE;

END str;
