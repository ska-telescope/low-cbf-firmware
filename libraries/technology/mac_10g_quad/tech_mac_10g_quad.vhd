LIBRARY IEEE, technology_lib, axi4_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE work.tech_mac_10g_quad_component_pkg.ALL;
USE work.tech_mac_10g_quad_pkg.ALL;

ENTITY tech_mac_10g_quad IS
   GENERIC (
      g_technology            : t_technology;
      g_device                : t_quad_locations_10g;
      g_txpostcursor          : t_tech_slv_5_arr(3 DOWNTO 0) := (OTHERS => "00000");   -- No post emphasis
      g_txmaincursor          : t_tech_slv_7_arr(3 DOWNTO 0) := (OTHERS => "1010000");
      g_txprecursor           : t_tech_slv_5_arr(3 DOWNTO 0) := (OTHERS => "00000");   -- 0.1dB pre emphasis
      g_txdiffctrl            : t_tech_slv_5_arr(3 DOWNTO 0) := (OTHERS => "11000");   -- 950mVpp
      g_txpolarity            : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
      g_rxpolarity            : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
      g_rxlpmen               : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0'));                          -- DFE
   PORT (
      gt_rxp_in               : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      gt_rxn_in               : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      gt_txp_out              : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      gt_txn_out              : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);

      gt_refclk_p             : IN STD_LOGIC;
      gt_refclk_n             : IN STD_LOGIC;

      sys_reset               : IN STD_LOGIC;
      dclk                    : IN STD_LOGIC;

      loopback                : IN t_tech_slv_3_arr(3 DOWNTO 0);
      tx_enable               : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      rx_enable               : IN STD_LOGIC_VECTOR(3 DOWNTO 0);

      tx_clk_out              : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      rx_clk_in               : IN STD_LOGIC_VECTOR(3 DOWNTO 0);                                                -- Should be driven by one of the tx_clk_outs
      rx_clk_out              : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);

      -- Ethernet Control
      rx_locked               : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      rx_local_fault          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      rx_remote_fault         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      rx_receive_local_fault  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);

      tx_send_idle            : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      tx_send_lfi             : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      tx_send_rfi             : IN STD_LOGIC_VECTOR(3 DOWNTO 0);

      user_rx_reset           : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      user_tx_reset           : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);

      -- Statistics Interface
      stat_rx_total_bytes     : OUT t_tech_slv_4_arr(3 DOWNTO 0);    -- Number of bytes received
      stat_rx_total_packets   : OUT t_tech_slv_2_arr(3 DOWNTO 0);    -- Total RX packets
      stat_rx_bad_fcs         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);    -- Bad checksums
      stat_rx_bad_code        : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);    -- Bit errors on the line (bad 64/66 code)

      stat_tx_total_bytes     : OUT t_tech_slv_4_arr(3 DOWNTO 0);    -- Number of bytes transmitted
      stat_tx_total_packets   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);    -- Total TX packets

      -- Recieved data from optics
      data_rx_sosi         : OUT t_axi4_sosi_arr(3 DOWNTO 0);
      data_rx_siso         : IN t_axi4_siso_arr(3 DOWNTO 0);

      -- Data to be transmitted to optics
      data_tx_sosi         : IN t_axi4_sosi_arr(3 DOWNTO 0);
      data_tx_siso         : OUT t_axi4_siso_arr(3 DOWNTO 0));
END tech_mac_10g_quad;

ARCHITECTURE str OF tech_mac_10g_quad IS


   SIGNAL gnd                       : STD_LOGIC_VECTOR(79 DOWNTO 0);

BEGIN


   gnd <= (OTHERS => '0');

   gen_ip: IF tech_is_board(g_technology, c_tech_board_gemini_lru) GENERATE

      quad122_gen: IF g_device = QUAD_10G_122 GENERATE
         mac_1: mac_10g_quad_122
         PORT MAP (
            gt_rxp_in_0 => gt_rxp_in(0), gt_rxp_in_1 => gt_rxp_in(1), gt_rxp_in_2 => gt_rxp_in(2), gt_rxp_in_3 => gt_rxp_in(3),
            gt_rxn_in_0 => gt_rxn_in(0), gt_rxn_in_1 => gt_rxn_in(1), gt_rxn_in_2 => gt_rxn_in(2), gt_rxn_in_3 => gt_rxn_in(3),
            gt_txp_out_0 => gt_txp_out(0), gt_txp_out_1 => gt_txp_out(1), gt_txp_out_2 => gt_txp_out(2), gt_txp_out_3 => gt_txp_out(3),
            gt_txn_out_0 => gt_txn_out(0), gt_txn_out_1 => gt_txn_out(1), gt_txn_out_2 => gt_txn_out(2), gt_txn_out_3 => gt_txn_out(3),
            gt_refclk_p => gt_refclk_p, gt_refclk_n => gt_refclk_n, gt_refclk_out => OPEN,

            sys_reset => sys_reset,
            rx_reset_0 => sys_reset, rx_reset_1 => sys_reset, rx_reset_2 => sys_reset, rx_reset_3 => sys_reset,
            tx_reset_0 => sys_reset, tx_reset_1 => sys_reset, tx_reset_2 => sys_reset, tx_reset_3 => sys_reset,
            gt_txpcsreset_0 => '0', gt_txpcsreset_1 => '0', gt_txpcsreset_2 => '0', gt_txpcsreset_3 => '0',
            gt_txpmareset_0 => '0', gt_txpmareset_1 => '0', gt_txpmareset_2 => '0', gt_txpmareset_3 => '0',
            gtwiz_reset_tx_datapath_0 => '0', gtwiz_reset_tx_datapath_1 => '0', gtwiz_reset_tx_datapath_2 => '0', gtwiz_reset_tx_datapath_3 => '0',
            gtwiz_reset_rx_datapath_0 => '0', gtwiz_reset_rx_datapath_1 => '0', gtwiz_reset_rx_datapath_2 => '0', gtwiz_reset_rx_datapath_3 => '0',


            txoutclksel_in_0 => "101", rxoutclksel_in_0  => "101", txoutclksel_in_1  => "101", rxoutclksel_in_1  => "101",
            txoutclksel_in_2  => "101", rxoutclksel_in_2  => "101", txoutclksel_in_3  => "101", rxoutclksel_in_3  => "101",
            tx_clk_out_0 => tx_clk_out(0), tx_clk_out_1 => tx_clk_out(1), tx_clk_out_2 => tx_clk_out(2), tx_clk_out_3 => tx_clk_out(3),
            rx_core_clk_0 => rx_clk_in(0), rx_core_clk_1 => rx_clk_in(1), rx_core_clk_2 => rx_clk_in(2), rx_core_clk_3 => rx_clk_in(3),
            rx_clk_out_0 => rx_clk_out(0), rx_clk_out_1 => rx_clk_out(1), rx_clk_out_2 => rx_clk_out(2), rx_clk_out_3 => rx_clk_out(3),
            dclk => dclk,
            rxrecclkout_0 => OPEN, rxrecclkout_1 => OPEN, rxrecclkout_2 => OPEN, rxrecclkout_3 => OPEN,
            gt_txlatclk_0 => dclk, gt_txlatclk_1 => dclk, gt_txlatclk_2 => dclk, gt_txlatclk_3 => dclk,

            gt_rxpolarity_0 => g_rxpolarity(0), gt_rxpolarity_1 => g_rxpolarity(1), gt_rxpolarity_2 => g_rxpolarity(2), gt_rxpolarity_3 => g_rxpolarity(3),
            gt_txpolarity_0 => g_txpolarity(0), gt_txpolarity_1 => g_txpolarity(1), gt_txpolarity_2 => g_txpolarity(2), gt_txpolarity_3 => g_txpolarity(3),
            gt_loopback_in_0 => loopback(0), gt_loopback_in_1 => loopback(1), gt_loopback_in_2 => loopback(2), gt_loopback_in_3 => loopback(3),

            gt_txdiffctrl_0 => g_txdiffctrl(0), gt_txdiffctrl_1 => g_txdiffctrl(1), gt_txdiffctrl_2 => g_txdiffctrl(2), gt_txdiffctrl_3 => g_txdiffctrl(3),
            gt_txprecursor_0 => g_txprecursor(0), gt_txprecursor_1 => g_txprecursor(1), gt_txprecursor_2 => g_txprecursor(2), gt_txprecursor_3 => g_txprecursor(3),
            gt_txmaincursor_0 => g_txmaincursor(0), gt_txmaincursor_1 => g_txmaincursor(1), gt_txmaincursor_2 => g_txmaincursor(2), gt_txmaincursor_3 => g_txmaincursor(3),
            gt_txpostcursor_0 => g_txpostcursor(0), gt_txpostcursor_1 => g_txpostcursor(1), gt_txpostcursor_2 => g_txpostcursor(2), gt_txpostcursor_3 => g_txpostcursor(3),


            gt_dmonitorout_0 => OPEN, gt_dmonitorout_1 => OPEN, gt_dmonitorout_2 => OPEN, gt_dmonitorout_3 => OPEN,
            gt_eyescandataerror_0 => OPEN, gt_eyescandataerror_1 => OPEN, gt_eyescandataerror_2 => OPEN, gt_eyescandataerror_3 => OPEN,
            gt_eyescanreset_0 => '0', gt_eyescanreset_1 => '0', gt_eyescanreset_2 => '0', gt_eyescanreset_3 => '0',
            gt_eyescantrigger_0 => '0', gt_eyescantrigger_1 => '0', gt_eyescantrigger_2 => '0', gt_eyescantrigger_3 => '0',

            gt_pcsrsvdin_0 => X"0000", gt_pcsrsvdin_1 => X"0000", gt_pcsrsvdin_2 => X"0000", gt_pcsrsvdin_3 => X"0000",
            gt_rxbufreset_0 => '0', gt_rxbufreset_1 => '0', gt_rxbufreset_2 => '0', gt_rxbufreset_3 => '0',
            gt_rxbufstatus_0 => OPEN, gt_rxbufstatus_1 => OPEN, gt_rxbufstatus_2 => OPEN, gt_rxbufstatus_3 => OPEN,
            gt_rxcdrhold_0 => '0', gt_rxcdrhold_1 => '0', gt_rxcdrhold_2 => '0', gt_rxcdrhold_3 => '0',
            gt_rxcommadeten_0 => '0', gt_rxcommadeten_1 => '0', gt_rxcommadeten_2 => '0', gt_rxcommadeten_3 => '0',
            gt_rxdfeagchold_0 => '0', gt_rxdfeagchold_1 => '0', gt_rxdfeagchold_2 => '0', gt_rxdfeagchold_3 => '0',
            gt_rxdfelpmreset_0 => '0', gt_rxdfelpmreset_1 => '0', gt_rxdfelpmreset_2 => '0', gt_rxdfelpmreset_3 => '0',
            gt_rxlatclk_0 => dclk, gt_rxlatclk_1 => dclk, gt_rxlatclk_2 => dclk, gt_rxlatclk_3 => dclk,
            gt_rxlpmen_0 => g_rxlpmen(0), gt_rxlpmen_1 => g_rxlpmen(1), gt_rxlpmen_2 => g_rxlpmen(2), gt_rxlpmen_3 => g_rxlpmen(3),
            gt_rxpcsreset_0 => '0', gt_rxpcsreset_1 => '0', gt_rxpcsreset_2 => '0', gt_rxpcsreset_3 => '0',
            gt_rxpmareset_0 => '0', gt_rxpmareset_1 => '0', gt_rxpmareset_2 => '0', gt_rxpmareset_3 => '0',
            gt_rxprbscntreset_0 => '0', gt_rxprbscntreset_1 => '0', gt_rxprbscntreset_2 => '0', gt_rxprbscntreset_3 => '0',
            gt_rxprbserr_0 => OPEN, gt_rxprbserr_1 => OPEN, gt_rxprbserr_2 => OPEN, gt_rxprbserr_3 => OPEN,
            gt_rxprbssel_0 => X"0", gt_rxprbssel_1 => X"0", gt_rxprbssel_2 => X"0", gt_rxprbssel_3 => X"0",
            gt_rxrate_0 => "000", gt_rxrate_1 => "000", gt_rxrate_2 => "000", gt_rxrate_3 => "000",
            gt_rxslide_in_0 => '0', gt_rxslide_in_1 => '0', gt_rxslide_in_2 => '0', gt_rxslide_in_3 => '0',
            gt_rxstartofseq_0 => OPEN, gt_rxstartofseq_1 => OPEN, gt_rxstartofseq_2 => OPEN, gt_rxstartofseq_3 => OPEN,

            gt_txbufstatus_0 => OPEN, gt_txbufstatus_1 => OPEN, gt_txbufstatus_2 => OPEN, gt_txbufstatus_3 => OPEN,
            gt_txinhibit_0 => '0', gt_txinhibit_1 => '0', gt_txinhibit_2 => '0', gt_txinhibit_3 => '0',
            gt_txprbsforceerr_0 => '0', gt_txprbsforceerr_1 => '0', gt_txprbsforceerr_2 => '0', gt_txprbsforceerr_3 => '0',
            gt_txprbssel_0 => X"0", gt_txprbssel_1 => X"0", gt_txprbssel_2 => X"0", gt_txprbssel_3 => X"0",

            gt_drpclk_0 => dclk, gt_drpclk_1 => dclk, gt_drpclk_2 => dclk, gt_drpclk_3 => dclk,
            gt_drpdo_0 => OPEN, gt_drpdo_1 => OPEN, gt_drpdo_2 => OPEN, gt_drpdo_3 => OPEN,
            gt_drprdy_0 => OPEN, gt_drprdy_1 => OPEN, gt_drprdy_2 => OPEN, gt_drprdy_3 => OPEN,
            gt_drpen_0 => '0', gt_drpen_1 => '0', gt_drpen_2 => '0', gt_drpen_3 => '0',
            gt_drpwe_0 => '0', gt_drpwe_1 => '0', gt_drpwe_2 => '0', gt_drpwe_3 => '0',
            gt_drpaddr_0 => gnd(9 DOWNTO 0), gt_drpaddr_1 => gnd(9 DOWNTO 0), gt_drpaddr_2 => gnd(9 DOWNTO 0), gt_drpaddr_3 => gnd(9 DOWNTO 0),
            gt_drpdi_0 => X"0000", gt_drpdi_1 => X"0000", gt_drpdi_2 => X"0000", gt_drpdi_3 => X"0000",

            gtpowergood_out_0 => OPEN, gtpowergood_out_1 => OPEN, gtpowergood_out_2 => OPEN, gtpowergood_out_3 => OPEN,

            user_rx_reset_0 => user_rx_reset(0), user_rx_reset_1 => user_rx_reset(1), user_rx_reset_2 => user_rx_reset(2), user_rx_reset_3 => user_rx_reset(3),
            rx_axis_tvalid_0 => data_rx_sosi(0).tvalid, rx_axis_tvalid_1 => data_rx_sosi(1).tvalid, rx_axis_tvalid_2 => data_rx_sosi(2).tvalid, rx_axis_tvalid_3 => data_rx_sosi(3).tvalid,
            rx_axis_tdata_0 => data_rx_sosi(0).tdata(63 DOWNTO 0), rx_axis_tdata_1 => data_rx_sosi(1).tdata(63 DOWNTO 0), rx_axis_tdata_2 => data_rx_sosi(2).tdata(63 DOWNTO 0), rx_axis_tdata_3 => data_rx_sosi(3).tdata(63 DOWNTO 0),
            rx_axis_tlast_0 => data_rx_sosi(0).tlast, rx_axis_tlast_1 => data_rx_sosi(1).tlast, rx_axis_tlast_2 => data_rx_sosi(2).tlast, rx_axis_tlast_3 => data_rx_sosi(3).tlast,
            rx_axis_tkeep_0 => data_rx_sosi(0).tkeep(7 DOWNTO 0), rx_axis_tkeep_1 => data_rx_sosi(1).tkeep(7 DOWNTO 0), rx_axis_tkeep_2 => data_rx_sosi(2).tkeep(7 DOWNTO 0), rx_axis_tkeep_3 => data_rx_sosi(3).tkeep(7 DOWNTO 0),
            rx_axis_tuser_0 => data_rx_sosi(0).tuser(0), rx_axis_tuser_1 => data_rx_sosi(1).tuser(0), rx_axis_tuser_2 => data_rx_sosi(2).tuser(0), rx_axis_tuser_3 => data_rx_sosi(3).tuser(0),

            ctl_rx_enable_0 => rx_enable(0), ctl_rx_enable_1 => rx_enable(1), ctl_rx_enable_2 => rx_enable(2), ctl_rx_enable_3 => rx_enable(3),
            ctl_rx_check_preamble_0 => '1', ctl_rx_check_preamble_1 => '1', ctl_rx_check_preamble_2 => '1', ctl_rx_check_preamble_3 => '1',
            ctl_rx_check_sfd_0 => '1', ctl_rx_check_sfd_1 => '1', ctl_rx_check_sfd_2 => '1', ctl_rx_check_sfd_3 => '1',
            ctl_rx_force_resync_0 => '0', ctl_rx_force_resync_1 => '0', ctl_rx_force_resync_2 => '0', ctl_rx_force_resync_3 => '0',
            ctl_rx_delete_fcs_0 => '1', ctl_rx_delete_fcs_1 => '1', ctl_rx_delete_fcs_2 => '1', ctl_rx_delete_fcs_3 => '1',
            ctl_rx_ignore_fcs_0 => '0', ctl_rx_ignore_fcs_1 => '0', ctl_rx_ignore_fcs_2 => '0', ctl_rx_ignore_fcs_3 => '0',
            ctl_rx_max_packet_len_0 => "011111111111111", ctl_rx_max_packet_len_1 => "011111111111111", ctl_rx_max_packet_len_2 => "011111111111111", ctl_rx_max_packet_len_3 => "011111111111111",
            ctl_rx_min_packet_len_0 => "00001000", ctl_rx_min_packet_len_1 => "00001000", ctl_rx_min_packet_len_2 => "00001000", ctl_rx_min_packet_len_3 => "00001000",
            ctl_rx_process_lfi_0 => '1', ctl_rx_process_lfi_1 => '1', ctl_rx_process_lfi_2 => '1', ctl_rx_process_lfi_3 => '1',

            ctl_rx_test_pattern_0 => '0', ctl_rx_test_pattern_1 => '0', ctl_rx_test_pattern_2 => '0', ctl_rx_test_pattern_3 => '0',
            ctl_rx_data_pattern_select_0 => '0', ctl_rx_data_pattern_select_1 => '0', ctl_rx_data_pattern_select_2 => '0', ctl_rx_data_pattern_select_3 => '0',
            ctl_rx_test_pattern_enable_0 => '0', ctl_rx_test_pattern_enable_1 => '0', ctl_rx_test_pattern_enable_2 => '0', ctl_rx_test_pattern_enable_3 => '0',
            stat_rx_test_pattern_mismatch_0 => OPEN, stat_rx_test_pattern_mismatch_1 => OPEN, stat_rx_test_pattern_mismatch_2 => OPEN, stat_rx_test_pattern_mismatch_3 => OPEN,

            stat_rx_total_bytes_0 => stat_rx_total_bytes(0), stat_rx_total_bytes_1 => stat_rx_total_bytes(1), stat_rx_total_bytes_2 => stat_rx_total_bytes(2), stat_rx_total_bytes_3 => stat_rx_total_bytes(3),
            stat_rx_total_packets_0 => stat_rx_total_packets(0), stat_rx_total_packets_1 => stat_rx_total_packets(1), stat_rx_total_packets_2 => stat_rx_total_packets(2), stat_rx_total_packets_3 => stat_rx_total_packets(3),
            stat_rx_packet_bad_fcs_0 => stat_rx_bad_fcs(0), stat_rx_packet_bad_fcs_1 => stat_rx_bad_fcs(1), stat_rx_packet_bad_fcs_2 => stat_rx_bad_fcs(2), stat_rx_packet_bad_fcs_3 => stat_rx_bad_fcs(3),
            stat_rx_bad_code_0 => stat_rx_bad_code(0), stat_rx_bad_code_1 => stat_rx_bad_code(1), stat_rx_bad_code_2 => stat_rx_bad_code(2), stat_rx_bad_code_3 => stat_rx_bad_code(3),

            stat_rx_block_lock_0 => rx_locked(0), stat_rx_block_lock_1 => rx_locked(1), stat_rx_block_lock_2 => rx_locked(2), stat_rx_block_lock_3 => rx_locked(3),
            stat_rx_remote_fault_0 => rx_remote_fault(0), stat_rx_remote_fault_1 => rx_remote_fault(1), stat_rx_remote_fault_2 => rx_remote_fault(2), stat_rx_remote_fault_3 => rx_remote_fault(3),
            stat_rx_internal_local_fault_0 => rx_local_fault(0), stat_rx_internal_local_fault_1 => rx_local_fault(1), stat_rx_internal_local_fault_2 => rx_local_fault(2), stat_rx_internal_local_fault_3 => rx_local_fault(3),
            stat_rx_received_local_fault_0 => rx_receive_local_fault(0), stat_rx_received_local_fault_1 => rx_receive_local_fault(1), stat_rx_received_local_fault_2 => rx_receive_local_fault(2), stat_rx_received_local_fault_3 => rx_receive_local_fault(3),

            ctl_rx_custom_preamble_enable_0 => '0', ctl_rx_custom_preamble_enable_1 => '0', ctl_rx_custom_preamble_enable_2 => '0', ctl_rx_custom_preamble_enable_3 => '0',
            stat_rx_framing_err_0 => OPEN, stat_rx_framing_err_1 => OPEN, stat_rx_framing_err_2 => OPEN, stat_rx_framing_err_3 => OPEN,
            stat_rx_framing_err_valid_0 => OPEN, stat_rx_framing_err_valid_1 => OPEN, stat_rx_framing_err_valid_2 => OPEN, stat_rx_framing_err_valid_3 => OPEN,
            stat_rx_local_fault_0 => OPEN, stat_rx_local_fault_1 => OPEN, stat_rx_local_fault_2 => OPEN, stat_rx_local_fault_3 => OPEN,

            stat_rx_valid_ctrl_code_0 => OPEN, stat_rx_valid_ctrl_code_1 => OPEN, stat_rx_valid_ctrl_code_2 => OPEN, stat_rx_valid_ctrl_code_3 => OPEN,
            stat_rx_status_0 => OPEN, stat_rx_status_1 => OPEN, stat_rx_status_2 => OPEN, stat_rx_status_3 => OPEN,
            stat_rx_stomped_fcs_0 => OPEN, stat_rx_stomped_fcs_1 => OPEN, stat_rx_stomped_fcs_2 => OPEN, stat_rx_stomped_fcs_3 => OPEN,
            stat_rx_truncated_0 => OPEN, stat_rx_truncated_1 => OPEN, stat_rx_truncated_2 => OPEN, stat_rx_truncated_3 => OPEN,
            stat_rx_hi_ber_0 => OPEN, stat_rx_hi_ber_1 => OPEN, stat_rx_hi_ber_2 => OPEN, stat_rx_hi_ber_3 => OPEN,
            stat_rx_got_signal_os_0 => OPEN, stat_rx_got_signal_os_1 => OPEN, stat_rx_got_signal_os_2 => OPEN, stat_rx_got_signal_os_3 => OPEN,
            stat_rx_total_good_bytes_0 => OPEN, stat_rx_total_good_bytes_1 => OPEN, stat_rx_total_good_bytes_2 => OPEN, stat_rx_total_good_bytes_3 => OPEN,
            stat_rx_total_good_packets_0 => OPEN, stat_rx_total_good_packets_1 => OPEN, stat_rx_total_good_packets_2 => OPEN, stat_rx_total_good_packets_3 => OPEN,
            stat_rx_bad_fcs_0 => OPEN, stat_rx_bad_fcs_1 => OPEN, stat_rx_bad_fcs_2 => OPEN, stat_rx_bad_fcs_3 => OPEN,
            stat_rx_packet_64_bytes_0 => OPEN, stat_rx_packet_64_bytes_1 => OPEN, stat_rx_packet_64_bytes_2 => OPEN, stat_rx_packet_64_bytes_3 => OPEN,
            stat_rx_packet_65_127_bytes_0 => OPEN, stat_rx_packet_65_127_bytes_1 => OPEN, stat_rx_packet_65_127_bytes_2 => OPEN, stat_rx_packet_65_127_bytes_3 => OPEN,
            stat_rx_packet_128_255_bytes_0 => OPEN, stat_rx_packet_128_255_bytes_1 => OPEN, stat_rx_packet_128_255_bytes_2 => OPEN, stat_rx_packet_128_255_bytes_3 => OPEN,
            stat_rx_packet_256_511_bytes_0 => OPEN, stat_rx_packet_256_511_bytes_1 => OPEN, stat_rx_packet_256_511_bytes_2 => OPEN, stat_rx_packet_256_511_bytes_3 => OPEN,
            stat_rx_packet_512_1023_bytes_0 => OPEN, stat_rx_packet_512_1023_bytes_1 => OPEN, stat_rx_packet_512_1023_bytes_2 => OPEN, stat_rx_packet_512_1023_bytes_3 => OPEN,
            stat_rx_packet_1024_1518_bytes_0 => OPEN, stat_rx_packet_1024_1518_bytes_1 => OPEN, stat_rx_packet_1024_1518_bytes_2 => OPEN, stat_rx_packet_1024_1518_bytes_3 => OPEN,
            stat_rx_packet_1519_1522_bytes_0 => OPEN, stat_rx_packet_1519_1522_bytes_1 => OPEN, stat_rx_packet_1519_1522_bytes_2 => OPEN, stat_rx_packet_1519_1522_bytes_3 => OPEN,
            stat_rx_packet_1523_1548_bytes_0 => OPEN, stat_rx_packet_1523_1548_bytes_1 => OPEN, stat_rx_packet_1523_1548_bytes_2 => OPEN, stat_rx_packet_1523_1548_bytes_3 => OPEN,
            stat_rx_packet_1549_2047_bytes_0 => OPEN, stat_rx_packet_1549_2047_bytes_1 => OPEN, stat_rx_packet_1549_2047_bytes_2 => OPEN, stat_rx_packet_1549_2047_bytes_3 => OPEN,
            stat_rx_packet_2048_4095_bytes_0 => OPEN, stat_rx_packet_2048_4095_bytes_1 => OPEN, stat_rx_packet_2048_4095_bytes_2 => OPEN, stat_rx_packet_2048_4095_bytes_3 => OPEN,
            stat_rx_packet_4096_8191_bytes_0 => OPEN, stat_rx_packet_4096_8191_bytes_1 => OPEN, stat_rx_packet_4096_8191_bytes_2 => OPEN, stat_rx_packet_4096_8191_bytes_3 => OPEN,
            stat_rx_packet_8192_9215_bytes_0 => OPEN, stat_rx_packet_8192_9215_bytes_1 => OPEN, stat_rx_packet_8192_9215_bytes_2 => OPEN, stat_rx_packet_8192_9215_bytes_3 => OPEN,
            stat_rx_packet_small_0 => OPEN, stat_rx_packet_small_1 => OPEN, stat_rx_packet_small_2 => OPEN, stat_rx_packet_small_3 => OPEN,
            stat_rx_packet_large_0 => OPEN, stat_rx_packet_large_1 => OPEN, stat_rx_packet_large_2 => OPEN, stat_rx_packet_large_3 => OPEN,
            stat_rx_oversize_0 => OPEN, stat_rx_oversize_1 => OPEN, stat_rx_oversize_2 => OPEN, stat_rx_oversize_3 => OPEN,
            stat_rx_toolong_0 => OPEN, stat_rx_toolong_1 => OPEN, stat_rx_toolong_2 => OPEN, stat_rx_toolong_3 => OPEN,
            stat_rx_undersize_0 => OPEN, stat_rx_undersize_1 => OPEN, stat_rx_undersize_2 => OPEN, stat_rx_undersize_3 => OPEN,
            stat_rx_fragment_0 => OPEN, stat_rx_fragment_1 => OPEN, stat_rx_fragment_2 => OPEN, stat_rx_fragment_3 => OPEN,
            stat_rx_jabber_0 => OPEN, stat_rx_jabber_1 => OPEN, stat_rx_jabber_2 => OPEN, stat_rx_jabber_3 => OPEN,
            stat_rx_bad_sfd_0 => OPEN, stat_rx_bad_sfd_1 => OPEN, stat_rx_bad_sfd_2 => OPEN, stat_rx_bad_sfd_3 => OPEN,
            stat_rx_bad_preamble_0 => OPEN, stat_rx_bad_preamble_1 => OPEN, stat_rx_bad_preamble_2 => OPEN, stat_rx_bad_preamble_3 => OPEN,

            user_tx_reset_0 => user_tx_reset(0), user_tx_reset_1 => user_tx_reset(1), user_tx_reset_2 => user_tx_reset(2), user_tx_reset_3 => user_tx_reset(3),
            tx_axis_tready_0 => data_tx_siso(0).tready, tx_axis_tready_1 => data_tx_siso(1).tready, tx_axis_tready_2 => data_tx_siso(2).tready, tx_axis_tready_3 => data_tx_siso(3).tready,
            tx_axis_tvalid_0 => data_tx_sosi(0).tvalid, tx_axis_tvalid_1 => data_tx_sosi(1).tvalid, tx_axis_tvalid_2 => data_tx_sosi(2).tvalid, tx_axis_tvalid_3 => data_tx_sosi(3).tvalid,
            tx_axis_tdata_0 => data_tx_sosi(0).tdata(63 DOWNTO 0), tx_axis_tdata_1 => data_tx_sosi(1).tdata(63 DOWNTO 0), tx_axis_tdata_2 => data_tx_sosi(2).tdata(63 DOWNTO 0), tx_axis_tdata_3 => data_tx_sosi(3).tdata(63 DOWNTO 0),
            tx_axis_tlast_0 => data_tx_sosi(0).tlast, tx_axis_tlast_1 => data_tx_sosi(1).tlast, tx_axis_tlast_2 => data_tx_sosi(2).tlast, tx_axis_tlast_3 => data_tx_sosi(3).tlast,
            tx_axis_tkeep_0 => data_tx_sosi(0).tkeep(7 DOWNTO 0), tx_axis_tkeep_1 => data_tx_sosi(1).tkeep(7 DOWNTO 0), tx_axis_tkeep_2 => data_tx_sosi(2).tkeep(7 DOWNTO 0), tx_axis_tkeep_3 => data_tx_sosi(3).tkeep(7 DOWNTO 0),
            tx_axis_tuser_0 => data_tx_sosi(0).tuser(0), tx_axis_tuser_1 => data_tx_sosi(1).tuser(0), tx_axis_tuser_2 => data_tx_sosi(2).tuser(0), tx_axis_tuser_3 => data_tx_sosi(3).tuser(0),

            tx_unfout_0 => OPEN, tx_unfout_1 => OPEN, tx_unfout_2 => OPEN, tx_unfout_3 => OPEN,
            tx_preamblein_0 => gnd(55 DOWNTO 0), rx_preambleout_0 => OPEN,
            tx_preamblein_1 => gnd(55 DOWNTO 0), rx_preambleout_1 => OPEN,
            tx_preamblein_2 => gnd(55 DOWNTO 0), rx_preambleout_2 => OPEN,
            tx_preamblein_3 => gnd(55 DOWNTO 0), rx_preambleout_3 => OPEN,

            stat_tx_total_bytes_0 => stat_tx_total_bytes(0), stat_tx_total_bytes_1 => stat_tx_total_bytes(1), stat_tx_total_bytes_2 => stat_tx_total_bytes(2), stat_tx_total_bytes_3 => stat_tx_total_bytes(3),
            stat_tx_total_packets_0 => stat_tx_total_packets(0), stat_tx_total_packets_1 => stat_tx_total_packets(1), stat_tx_total_packets_2 => stat_tx_total_packets(2), stat_tx_total_packets_3 => stat_tx_total_packets(3),

            stat_tx_local_fault_0 => OPEN, stat_tx_local_fault_1 => OPEN, stat_tx_local_fault_2 => OPEN, stat_tx_local_fault_3 => OPEN,
            stat_tx_total_good_bytes_0 => OPEN, stat_tx_total_good_bytes_1 => OPEN, stat_tx_total_good_bytes_2 => OPEN, stat_tx_total_good_bytes_3 => OPEN,
            stat_tx_total_good_packets_0 => OPEN, stat_tx_total_good_packets_1 => OPEN, stat_tx_total_good_packets_2 => OPEN, stat_tx_total_good_packets_3 => OPEN,
            stat_tx_bad_fcs_0 => OPEN, stat_tx_bad_fcs_1 => OPEN, stat_tx_bad_fcs_2 => OPEN, stat_tx_bad_fcs_3 => OPEN,
            stat_tx_packet_64_bytes_0 => OPEN, stat_tx_packet_64_bytes_1 => OPEN, stat_tx_packet_64_bytes_2 => OPEN, stat_tx_packet_64_bytes_3 => OPEN,
            stat_tx_packet_65_127_bytes_0 => OPEN, stat_tx_packet_65_127_bytes_1 => OPEN, stat_tx_packet_65_127_bytes_2 => OPEN, stat_tx_packet_65_127_bytes_3 => OPEN,
            stat_tx_packet_128_255_bytes_0 => OPEN, stat_tx_packet_128_255_bytes_1 => OPEN, stat_tx_packet_128_255_bytes_2 => OPEN, stat_tx_packet_128_255_bytes_3 => OPEN,
            stat_tx_packet_256_511_bytes_0 => OPEN, stat_tx_packet_256_511_bytes_1 => OPEN, stat_tx_packet_256_511_bytes_2 => OPEN, stat_tx_packet_256_511_bytes_3 => OPEN,
            stat_tx_packet_512_1023_bytes_0 => OPEN, stat_tx_packet_512_1023_bytes_1 => OPEN, stat_tx_packet_512_1023_bytes_2 => OPEN, stat_tx_packet_512_1023_bytes_3 => OPEN,
            stat_tx_packet_1024_1518_bytes_0 => OPEN, stat_tx_packet_1024_1518_bytes_1 => OPEN, stat_tx_packet_1024_1518_bytes_2 => OPEN, stat_tx_packet_1024_1518_bytes_3 => OPEN,
            stat_tx_packet_1519_1522_bytes_0 => OPEN, stat_tx_packet_1519_1522_bytes_1 => OPEN, stat_tx_packet_1519_1522_bytes_2 => OPEN, stat_tx_packet_1519_1522_bytes_3 => OPEN,
            stat_tx_packet_1523_1548_bytes_0 => OPEN, stat_tx_packet_1523_1548_bytes_1 => OPEN, stat_tx_packet_1523_1548_bytes_2 => OPEN, stat_tx_packet_1523_1548_bytes_3 => OPEN,
            stat_tx_packet_1549_2047_bytes_0 => OPEN, stat_tx_packet_1549_2047_bytes_1 => OPEN, stat_tx_packet_1549_2047_bytes_2 => OPEN, stat_tx_packet_1549_2047_bytes_3 => OPEN,
            stat_tx_packet_2048_4095_bytes_0 => OPEN, stat_tx_packet_2048_4095_bytes_1 => OPEN, stat_tx_packet_2048_4095_bytes_2 => OPEN, stat_tx_packet_2048_4095_bytes_3 => OPEN,
            stat_tx_packet_4096_8191_bytes_0 => OPEN, stat_tx_packet_4096_8191_bytes_1 => OPEN, stat_tx_packet_4096_8191_bytes_2 => OPEN, stat_tx_packet_4096_8191_bytes_3 => OPEN,
            stat_tx_packet_8192_9215_bytes_0 => OPEN, stat_tx_packet_8192_9215_bytes_1 => OPEN, stat_tx_packet_8192_9215_bytes_2 => OPEN, stat_tx_packet_8192_9215_bytes_3 => OPEN,
            stat_tx_packet_small_0 => OPEN, stat_tx_packet_small_1 => OPEN, stat_tx_packet_small_2 => OPEN, stat_tx_packet_small_3 => OPEN,
            stat_tx_packet_large_0 => OPEN, stat_tx_packet_large_1 => OPEN, stat_tx_packet_large_2 => OPEN, stat_tx_packet_large_3 => OPEN,
            stat_tx_frame_error_0 => OPEN, stat_tx_frame_error_1 => OPEN, stat_tx_frame_error_2 => OPEN, stat_tx_frame_error_3 => OPEN,

            ctl_tx_enable_0 => tx_enable(0), ctl_tx_enable_1 => tx_enable(1), ctl_tx_enable_2 => tx_enable(2), ctl_tx_enable_3 => tx_enable(3),
            ctl_tx_send_rfi_0 => tx_send_rfi(0), ctl_tx_send_rfi_1 => tx_send_rfi(1), ctl_tx_send_rfi_2 => tx_send_rfi(2), ctl_tx_send_rfi_3 => tx_send_rfi(3),
            ctl_tx_send_lfi_0 => tx_send_lfi(0), ctl_tx_send_lfi_1 => tx_send_lfi(1), ctl_tx_send_lfi_2 => tx_send_lfi(2), ctl_tx_send_lfi_3 => tx_send_lfi(3),
            ctl_tx_send_idle_0 => tx_send_idle(0), ctl_tx_send_idle_1 => tx_send_idle(1), ctl_tx_send_idle_2 => tx_send_idle(2), ctl_tx_send_idle_3 => tx_send_idle(3),
            ctl_tx_fcs_ins_enable_0 => '1', ctl_tx_fcs_ins_enable_1 => '1', ctl_tx_fcs_ins_enable_2 => '1', ctl_tx_fcs_ins_enable_3 => '1',
            ctl_tx_ignore_fcs_0 => '0', ctl_tx_ignore_fcs_1 => '0', ctl_tx_ignore_fcs_2 => '0', ctl_tx_ignore_fcs_3 => '0',
            ctl_tx_ipg_value_0 => X"A", ctl_tx_ipg_value_1 => X"A", ctl_tx_ipg_value_2 => X"A", ctl_tx_ipg_value_3 => X"A",
            ctl_tx_custom_preamble_enable_0 => '0', ctl_tx_custom_preamble_enable_1 => '0', ctl_tx_custom_preamble_enable_2 => '0', ctl_tx_custom_preamble_enable_3 => '0',

            ctl_tx_test_pattern_0 => '0', ctl_tx_test_pattern_1 => '0', ctl_tx_test_pattern_2 => '0', ctl_tx_test_pattern_3 => '0',
            ctl_tx_test_pattern_enable_0 => '0', ctl_tx_test_pattern_enable_1 => '0', ctl_tx_test_pattern_enable_2 => '0', ctl_tx_test_pattern_enable_3 => '0',
            ctl_tx_test_pattern_select_0 => '0', ctl_tx_test_pattern_select_1 => '0', ctl_tx_test_pattern_select_2 => '0', ctl_tx_test_pattern_select_3 => '0',
            ctl_tx_data_pattern_select_0 => '0', ctl_tx_data_pattern_select_1 => '0', ctl_tx_data_pattern_select_2 => '0', ctl_tx_data_pattern_select_3 => '0',
            ctl_tx_test_pattern_seed_a_0 => gnd(57 DOWNTO 0), ctl_tx_test_pattern_seed_a_1 => gnd(57 DOWNTO 0), ctl_tx_test_pattern_seed_a_2 => gnd(57 DOWNTO 0), ctl_tx_test_pattern_seed_a_3 => gnd(57 DOWNTO 0),
            ctl_tx_test_pattern_seed_b_0 => gnd(57 DOWNTO 0), ctl_tx_test_pattern_seed_b_1 => gnd(57 DOWNTO 0), ctl_tx_test_pattern_seed_b_2 => gnd(57 DOWNTO 0), ctl_tx_test_pattern_seed_b_3 => gnd(57 DOWNTO 0));
   END GENERATE;

END GENERATE;





END str;





