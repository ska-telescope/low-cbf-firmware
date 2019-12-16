-------------------------------------------------------------------------------
--
-- File Name: tech_mac_40g.vhd
-- Contributing Authors: Andrew Brown
-- Type: RTL
-- Created: Thurs Oct 19 16:40:00 2017
-- Template Rev: 1.0
--
-- Title: Technology Wrapper for 40G MAC
--
-- Description: Wraps up the various technologies 40G MAC implemenattions into
--              a single VHDL module
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

LIBRARY IEEE, technology_lib, axi4_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE work.tech_mac_40g_component_pkg.ALL;
USE work.tech_mac_40g_pkg.ALL;

ENTITY tech_mac_40g IS
   GENERIC (
      g_technology            : t_technology;
      g_device                : t_quad_locations_40g;
      g_error_passing         : BOOLEAN := TRUE;
      g_txpostcursor          : t_tech_slv_5_arr(3 DOWNTO 0) := (OTHERS => "10101");
      g_txmaincursor          : t_tech_slv_7_arr(3 DOWNTO 0) := (OTHERS => "0000000");
      g_txprecursor           : t_tech_slv_5_arr(3 DOWNTO 0) := (OTHERS => "00000");   -- 0.1dB pre emphasis
      g_txdiffctrl            : t_tech_slv_5_arr(3 DOWNTO 0) := (OTHERS => "11000");   -- 950mVpp
      g_txpolarity            : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '1');
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

      loopback                : IN t_tech_slv_3_arr(3 DOWNTO 0);
      tx_enable               : IN STD_LOGIC;
      rx_enable               : IN STD_LOGIC;

      tx_clk_out              : OUT STD_LOGIC;
      rx_clk_in               : IN STD_LOGIC;                        -- Should be driven by one of the tx_clk_outs
      rx_clk_out              : OUT STD_LOGIC;

      -- Ethernet Status
      rx_locked               : OUT STD_LOGIC_vector(3 DOWNTO 0);
      rx_synced               : OUT STD_LOGIC_vector(3 DOWNTO 0);
      rx_aligned              : OUT STD_LOGIC;
      rx_status               : OUT STD_LOGIC;

      user_rx_reset           : OUT STD_LOGIC;
      user_tx_reset           : OUT STD_LOGIC;

      -- Statistics Interface
      stat_rx_total_bytes     : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);    -- Number of bytes received
      stat_rx_total_packets   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);    -- Total RX packets
      stat_rx_bad_fcs         : OUT STD_LOGIC;                       -- Bad checksums
      stat_rx_bad_code        : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);    -- Bit errors on the line

      stat_tx_total_bytes     : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);    -- Number of bytes transmitted
      stat_tx_total_packets   : OUT STD_LOGIC;                       -- Total TX packets

      -- Recieved data from optics
      data_rx_sosi            : OUT t_axi4_sosi;
      data_rx_siso            : IN t_axi4_siso;

      -- Data to be transmitted to optics
      data_tx_sosi            : IN t_axi4_sosi;
      data_tx_siso            : OUT t_axi4_siso);
END tech_mac_40g;

ARCHITECTURE str OF tech_mac_40g IS

   CONSTANT c_txdiffctrl         : STD_LOGIC_VECTOR(19 DOWNTO 0) := STD_LOGIC_VECTOR(g_txdiffctrl(3)) & STD_LOGIC_VECTOR(g_txdiffctrl(2)) & STD_LOGIC_VECTOR(g_txdiffctrl(1)) & STD_LOGIC_VECTOR(g_txdiffctrl(0));
   CONSTANT c_txmaincursor       : STD_LOGIC_VECTOR(27 DOWNTO 0) := STD_LOGIC_VECTOR(g_txmaincursor(3)) & STD_LOGIC_VECTOR(g_txmaincursor(2)) & STD_LOGIC_VECTOR(g_txmaincursor(1)) & STD_LOGIC_VECTOR(g_txmaincursor(0));
   CONSTANT c_txpostcursor       : STD_LOGIC_VECTOR(19 DOWNTO 0) := STD_LOGIC_VECTOR(g_txpostcursor(3)) & STD_LOGIC_VECTOR(g_txpostcursor(2)) & STD_LOGIC_VECTOR(g_txpostcursor(1)) & STD_LOGIC_VECTOR(g_txpostcursor(0));
   CONSTANT c_txprecursor        : STD_LOGIC_VECTOR(19 DOWNTO 0) := STD_LOGIC_VECTOR(g_txprecursor(3)) & STD_LOGIC_VECTOR(g_txprecursor(2)) & STD_LOGIC_VECTOR(g_txprecursor(1)) & STD_LOGIC_VECTOR(g_txprecursor(0));

   SIGNAL i_loopback             : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL dclk_slv               : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL gnd                    : STD_LOGIC_VECTOR(79 DOWNTO 0);
   SIGNAL tx_send_idle           : STD_LOGIC;
   SIGNAL tx_send_lfi            : STD_LOGIC;
   SIGNAL tx_send_rfi            : STD_LOGIC;
   SIGNAL rx_remote_fault        : STD_LOGIC;
   SIGNAL rx_local_fault         : STD_LOGIC;
   SIGNAL i_rx_locked            : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL rx_receive_local_fault : STD_LOGIC;


BEGIN

   dclk_slv <= (OTHERS => dclk);

   i_loopback(2 DOWNTO 0) <= loopback(0);
   i_loopback(5 DOWNTO 3) <= loopback(1);
   i_loopback(8 DOWNTO 6) <= loopback(2);
   i_loopback(11 DOWNTO 9) <= loopback(3);

   gnd <= (OTHERS => '0');

   rx_locked <= i_rx_locked WHEN rx_remote_fault = '0' OR g_error_passing = FALSE ELSE (OTHERS => '0');

   tx_send_idle <= rx_receive_local_fault WHEN g_error_passing = TRUE ELSE '0';     -- Send idles if we detect remote error
   tx_send_rfi <= '1' WHEN i_rx_locked /= X"F" AND g_error_passing = TRUE ELSE '0';             -- Send remote error until we are locked locally
   tx_send_lfi <= rx_local_fault WHEN g_error_passing = TRUE ELSE '0';              -- Send local error if something breaks here

   gen_ip: IF tech_is_board(g_technology, c_tech_board_gemini_lru) OR tech_is_board(g_technology, c_tech_board_gemini_xh_lru) OR tech_is_board(g_technology, c_tech_board_vcu128) GENERATE

      quad122_gen: IF g_device = QUAD_40G_122 GENERATE
         mac_1: mac_40g_quad_122
         PORT MAP (
            gt_rxp_in_0 => gt_rxp_in(0), gt_rxp_in_1 => gt_rxp_in(1), gt_rxp_in_2 => gt_rxp_in(2), gt_rxp_in_3 => gt_rxp_in(3),
            gt_rxn_in_0 => gt_rxn_in(0), gt_rxn_in_1 => gt_rxn_in(1), gt_rxn_in_2 => gt_rxn_in(2), gt_rxn_in_3 => gt_rxn_in(3),
            gt_txp_out_0 => gt_txp_out(0), gt_txp_out_1 => gt_txp_out(1), gt_txp_out_2 => gt_txp_out(2), gt_txp_out_3 => gt_txp_out(3),
            gt_txn_out_0 => gt_txn_out(0), gt_txn_out_1 => gt_txn_out(1), gt_txn_out_2 => gt_txn_out(2), gt_txn_out_3 => gt_txn_out(3),
            gt_refclk_p => gt_refclk_p, gt_refclk_n => gt_refclk_n,

            txoutclksel_in_0 => "101101101101", rxoutclksel_in_0 => "101101101101",
            rx_core_clk_0 => rx_clk_in, tx_clk_out_0 => tx_clk_out, rx_clk_out_0 => rx_clk_out,
            dclk => dclk,
            gt_common_drpclk => dclk, gt_ch_drpclk_0 => dclk, gt_ch_drpclk_1 => dclk, gt_ch_drpclk_2 => dclk, gt_ch_drpclk_3 => dclk,


            tx_reset_0 => sys_reset, sys_reset => sys_reset, rx_reset_0 => sys_reset,
            gt_loopback_in_0 => i_loopback,

            gt_dmonitorout_0 => OPEN, gt_eyescandataerror_0 => OPEN, gt_eyescanreset_0 => X"0",
            gt_eyescantrigger_0 => X"0", gt_pcsrsvdin_0 => gnd(63 DOWNTO 0), gt_rxbufreset_0 => X"0",
            gt_rxbufstatus_0 => OPEN, gt_rxcdrhold_0 => X"0", gt_rxcommadeten_0 => X"0",

            gt_rxdfeagchold_0 => X"0", gt_rxdfelpmreset_0 => X"0", gt_rxlatclk_0 => dclk_slv,
            gt_rxlpmen_0 => g_rxlpmen, gt_rxpcsreset_0 => X"0", gt_rxpmareset_0 => X"0",
            gt_rxprbscntreset_0 => X"0", gt_rxprbserr_0 => OPEN, gt_rxprbssel_0 => X"0000",
            gt_rxrate_0 => X"000", gt_rxslide_in_0 => X"0", gt_rxstartofseq_0 => OPEN,
            gt_txbufstatus_0 => OPEN, gt_txinhibit_0 => X"0", gt_txlatclk_0 => dclk_slv,

            gt_txdiffctrl_0 => c_txdiffctrl, gt_txmaincursor_0 => c_txmaincursor, gt_txpostcursor_0 => c_txpostcursor,
            gt_txprecursor_0 => c_txprecursor, gt_rxpolarity_0 => g_rxpolarity, gt_txpolarity_0 => g_txpolarity,

            gt_refclk_out => OPEN, gtpowergood_out_0 => OPEN,
            gt_txpcsreset_0 => X"0", gt_txpmareset_0 => X"0", gt_txprbsforceerr_0 => X"0",
            gt_txprbssel_0 => X"0000", gtwiz_reset_tx_datapath_0 => "0",
            gtwiz_reset_rx_datapath_0 => "0", rxrecclkout_0 => OPEN,

            gt_common_drpdo => OPEN, gt_ch_drpdo_0 => OPEN, gt_ch_drpdo_1 => OPEN, gt_ch_drpdo_2 => OPEN, gt_ch_drpdo_3 => OPEN,
            gt_common_drprdy => OPEN, gt_ch_drprdy_0 => OPEN, gt_ch_drprdy_1 => OPEN, gt_ch_drprdy_2 => OPEN, gt_ch_drprdy_3 => OPEN,
            gt_common_drpen => '0', gt_common_drpwe => '0',
            gt_ch_drpen_0 => '0', gt_ch_drpen_1 => '0', gt_ch_drpen_2 => '0', gt_ch_drpen_3 => '0',
            gt_ch_drpwe_0 => '0', gt_ch_drpwe_1 => '0', gt_ch_drpwe_2 => '0', gt_ch_drpwe_3 => '0',
            gt_common_drpaddr => gnd(9 DOWNTO 0), gt_common_drpdi => X"0000",
            gt_ch_drpaddr_0 => gnd(9 DOWNTO 0), gt_ch_drpaddr_1 => gnd(9 DOWNTO 0), gt_ch_drpaddr_2 => gnd(9 DOWNTO 0), gt_ch_drpaddr_3 => gnd(9 DOWNTO 0),
            gt_ch_drpdi_0 => X"0000", gt_ch_drpdi_1 => X"0000", gt_ch_drpdi_2 => X"0000", gt_ch_drpdi_3 => X"0000",

            -- AXI RX
            user_rx_reset_0 => user_rx_reset, rx_axis_tvalid_0 => data_rx_sosi.tvalid,
            rx_axis_tdata_0 => data_rx_sosi.tdata(127 DOWNTO 0), rx_axis_tuser_0 => data_rx_sosi.tuser(69 DOWNTO 0),

            -- RX Control
            ctl_rx_enable_0 => rx_enable, ctl_rx_check_preamble_0 => '1', ctl_rx_check_sfd_0 => '1',
            ctl_rx_force_resync_0 => '0', ctl_rx_delete_fcs_0 => '1', ctl_rx_ignore_fcs_0 => '0',
            ctl_rx_max_packet_len_0 => "011111111111111", ctl_rx_min_packet_len_0 => "00001000",
            ctl_rx_process_lfi_0 => '1', ctl_rx_test_pattern_0 => '0' ,
            ctl_rx_custom_preamble_enable_0 => '0',

            -- Statistics
            stat_rx_block_lock_0 => i_rx_locked,
            stat_rx_bad_fcs_0 => OPEN,
            stat_tx_total_bytes_0 => stat_tx_total_bytes, stat_rx_total_bytes_0 => stat_rx_total_bytes,
            stat_tx_total_packets_0 => stat_tx_total_packets, stat_rx_total_packets_0 => stat_rx_total_packets,
            stat_rx_packet_bad_fcs_0 => stat_rx_bad_fcs, stat_rx_bad_code_0 => stat_rx_bad_code,

            stat_rx_internal_local_fault_0 => rx_local_fault, stat_rx_remote_fault_0 => rx_remote_fault,
            stat_rx_received_local_fault_0 => rx_receive_local_fault,

            stat_rx_framing_err_0_0 => OPEN, stat_rx_framing_err_1_0 => OPEN, stat_rx_framing_err_2_0 => OPEN, stat_rx_framing_err_3_0 => OPEN,
            stat_rx_framing_err_valid_0_0 => OPEN, stat_rx_framing_err_valid_1_0 => OPEN, stat_rx_framing_err_valid_2_0 => OPEN, stat_rx_framing_err_valid_3_0 => OPEN,
            stat_rx_local_fault_0 => OPEN, stat_rx_status_0 => rx_status, stat_rx_stomped_fcs_0 => OPEN, stat_rx_truncated_0 => OPEN,
            stat_rx_hi_ber_0 => OPEN, stat_rx_got_signal_os_0 => OPEN, stat_rx_test_pattern_mismatch_0 => OPEN,
            stat_rx_total_good_bytes_0 => OPEN, stat_rx_total_good_packets_0 => OPEN,
            stat_rx_packet_64_bytes_0 => OPEN, stat_rx_packet_65_127_bytes_0 => OPEN, stat_rx_packet_128_255_bytes_0 => OPEN,
            stat_rx_packet_256_511_bytes_0 => OPEN, stat_rx_packet_512_1023_bytes_0 => OPEN,
            stat_rx_packet_1024_1518_bytes_0 => OPEN, stat_rx_packet_1519_1522_bytes_0 => OPEN,
            stat_rx_packet_1523_1548_bytes_0 => OPEN, stat_rx_packet_1549_2047_bytes_0 => OPEN,
            stat_rx_packet_2048_4095_bytes_0 => OPEN, stat_rx_packet_4096_8191_bytes_0 => OPEN,
            stat_rx_packet_8192_9215_bytes_0 => OPEN, stat_rx_packet_small_0 => OPEN, stat_rx_packet_large_0 => OPEN,
            stat_rx_oversize_0 => OPEN, stat_rx_toolong_0 => OPEN, stat_rx_undersize_0 => OPEN,
            stat_rx_fragment_0 => OPEN, stat_rx_bad_preamble_0 => OPEN, stat_rx_vl_demuxed_0 => OPEN,
            stat_rx_jabber_0 => OPEN, stat_rx_bad_sfd_0 => OPEN,
            stat_rx_vl_number_0_0 => OPEN, stat_rx_vl_number_1_0 => OPEN, stat_rx_vl_number_2_0 => OPEN, stat_rx_vl_number_3_0 => OPEN,
            stat_rx_synced_0 => rx_synced, stat_rx_synced_err_0 => OPEN, stat_rx_mf_len_err_0 => OPEN, stat_rx_mf_repeat_err_0 => OPEN,
            stat_rx_mf_err_0 => OPEN, stat_rx_aligned_0 => rx_aligned, stat_rx_misaligned_0 => OPEN, stat_rx_aligned_err_0 => OPEN,
            stat_rx_bip_err_0_0 => OPEN, stat_rx_bip_err_1_0 => OPEN, stat_rx_bip_err_2_0 => OPEN, stat_rx_bip_err_3_0 => OPEN,
            stat_tx_frame_error_0 => OPEN, stat_tx_local_fault_0 => OPEN,
            stat_tx_total_good_bytes_0 => OPEN, stat_tx_total_good_packets_0 => OPEN, stat_tx_bad_fcs_0 => OPEN,
            stat_tx_packet_64_bytes_0 => OPEN, stat_tx_packet_65_127_bytes_0 => OPEN, stat_tx_packet_128_255_bytes_0 => OPEN,
            stat_tx_packet_256_511_bytes_0 => OPEN, stat_tx_packet_512_1023_bytes_0 => OPEN,
            stat_tx_packet_1024_1518_bytes_0 => OPEN, stat_tx_packet_1519_1522_bytes_0 => OPEN,
            stat_tx_packet_1523_1548_bytes_0 => OPEN, stat_tx_packet_1549_2047_bytes_0 => OPEN,
            stat_tx_packet_2048_4095_bytes_0 => OPEN, stat_tx_packet_4096_8191_bytes_0 => OPEN,
            stat_tx_packet_8192_9215_bytes_0 => OPEN, stat_tx_packet_small_0 => OPEN, stat_tx_packet_large_0 => OPEN,

            -- AXI TX
            user_tx_reset_0 => user_tx_reset, tx_axis_tready_0 => data_tx_siso.tready,
            tx_axis_tvalid_0 => data_tx_sosi.tvalid, tx_axis_tdata_0 => data_tx_sosi.tdata(127 DOWNTO 0),
            tx_axis_tuser_0 => data_tx_sosi.tuser(69 DOWNTO 0),

            -- TX Settings
            tx_unfout_0 => OPEN, ctl_tx_enable_0 => tx_enable,
            ctl_tx_send_rfi_0 => tx_send_rfi, ctl_tx_send_lfi_0 => tx_send_lfi, ctl_tx_send_idle_0 => tx_send_idle,
            ctl_tx_fcs_ins_enable_0 => '1', ctl_tx_ignore_fcs_0 => '0', ctl_tx_test_pattern_0 => '0',
            ctl_tx_ipg_value_0 => X"C", ctl_tx_custom_preamble_enable_0 => '0');
      END GENERATE;

      quad124_gen: IF g_device = QUAD_40G_124 GENERATE
         mac_1: mac_40g_quad_124
         PORT MAP (
            gt_rxp_in_0 => gt_rxp_in(0), gt_rxp_in_1 => gt_rxp_in(1), gt_rxp_in_2 => gt_rxp_in(2), gt_rxp_in_3 => gt_rxp_in(3),
            gt_rxn_in_0 => gt_rxn_in(0), gt_rxn_in_1 => gt_rxn_in(1), gt_rxn_in_2 => gt_rxn_in(2), gt_rxn_in_3 => gt_rxn_in(3),
            gt_txp_out_0 => gt_txp_out(0), gt_txp_out_1 => gt_txp_out(1), gt_txp_out_2 => gt_txp_out(2), gt_txp_out_3 => gt_txp_out(3),
            gt_txn_out_0 => gt_txn_out(0), gt_txn_out_1 => gt_txn_out(1), gt_txn_out_2 => gt_txn_out(2), gt_txn_out_3 => gt_txn_out(3),
            gt_refclk_p => gt_refclk_p, gt_refclk_n => gt_refclk_n,

            txoutclksel_in_0 => "101101101101", rxoutclksel_in_0 => "101101101101",
            rx_core_clk_0 => rx_clk_in, tx_clk_out_0 => tx_clk_out, rx_clk_out_0 => rx_clk_out,
            dclk => dclk,
            gt_common_drpclk => dclk, gt_ch_drpclk_0 => dclk, gt_ch_drpclk_1 => dclk, gt_ch_drpclk_2 => dclk, gt_ch_drpclk_3 => dclk,


            tx_reset_0 => sys_reset, sys_reset => sys_reset, rx_reset_0 => sys_reset,
            gt_loopback_in_0 => i_loopback,

            gt_dmonitorout_0 => OPEN, gt_eyescandataerror_0 => OPEN, gt_eyescanreset_0 => X"0",
            gt_eyescantrigger_0 => X"0", gt_pcsrsvdin_0 => gnd(63 DOWNTO 0), gt_rxbufreset_0 => X"0",
            gt_rxbufstatus_0 => OPEN, gt_rxcdrhold_0 => X"0", gt_rxcommadeten_0 => X"0",

            gt_rxdfeagchold_0 => X"0", gt_rxdfelpmreset_0 => X"0", gt_rxlatclk_0 => dclk_slv,
            gt_rxlpmen_0 => g_rxlpmen, gt_rxpcsreset_0 => X"0", gt_rxpmareset_0 => X"0",
            gt_rxprbscntreset_0 => X"0", gt_rxprbserr_0 => OPEN, gt_rxprbssel_0 => X"0000",
            gt_rxrate_0 => X"000", gt_rxslide_in_0 => X"0", gt_rxstartofseq_0 => OPEN,
            gt_txbufstatus_0 => OPEN, gt_txinhibit_0 => X"0", gt_txlatclk_0 => dclk_slv,

            gt_txdiffctrl_0 => c_txdiffctrl, gt_txmaincursor_0 => c_txmaincursor, gt_txpostcursor_0 => c_txpostcursor,
            gt_txprecursor_0 => c_txprecursor, gt_rxpolarity_0 => g_rxpolarity, gt_txpolarity_0 => g_txpolarity,

            gt_refclk_out => OPEN, gtpowergood_out_0 => OPEN,
            gt_txpcsreset_0 => X"0", gt_txpmareset_0 => X"0", gt_txprbsforceerr_0 => X"0",
            gt_txprbssel_0 => X"0000", gtwiz_reset_tx_datapath_0 => "0",
            gtwiz_reset_rx_datapath_0 => "0", rxrecclkout_0 => OPEN,

            gt_common_drpdo => OPEN, gt_ch_drpdo_0 => OPEN, gt_ch_drpdo_1 => OPEN, gt_ch_drpdo_2 => OPEN, gt_ch_drpdo_3 => OPEN,
            gt_common_drprdy => OPEN, gt_ch_drprdy_0 => OPEN, gt_ch_drprdy_1 => OPEN, gt_ch_drprdy_2 => OPEN, gt_ch_drprdy_3 => OPEN,
            gt_common_drpen => '0', gt_common_drpwe => '0',
            gt_ch_drpen_0 => '0', gt_ch_drpen_1 => '0', gt_ch_drpen_2 => '0', gt_ch_drpen_3 => '0',
            gt_ch_drpwe_0 => '0', gt_ch_drpwe_1 => '0', gt_ch_drpwe_2 => '0', gt_ch_drpwe_3 => '0',
            gt_common_drpaddr => gnd(9 DOWNTO 0), gt_common_drpdi => X"0000",
            gt_ch_drpaddr_0 => gnd(9 DOWNTO 0), gt_ch_drpaddr_1 => gnd(9 DOWNTO 0), gt_ch_drpaddr_2 => gnd(9 DOWNTO 0), gt_ch_drpaddr_3 => gnd(9 DOWNTO 0),
            gt_ch_drpdi_0 => X"0000", gt_ch_drpdi_1 => X"0000", gt_ch_drpdi_2 => X"0000", gt_ch_drpdi_3 => X"0000",

            -- AXI RX
            user_rx_reset_0 => user_rx_reset, rx_axis_tvalid_0 => data_rx_sosi.tvalid,
            rx_axis_tdata_0 => data_rx_sosi.tdata(127 DOWNTO 0), rx_axis_tuser_0 => data_rx_sosi.tuser(69 DOWNTO 0),

            -- RX Control
            ctl_rx_enable_0 => rx_enable, ctl_rx_check_preamble_0 => '1', ctl_rx_check_sfd_0 => '1',
            ctl_rx_force_resync_0 => '0', ctl_rx_delete_fcs_0 => '1', ctl_rx_ignore_fcs_0 => '0',
            ctl_rx_max_packet_len_0 => "011111111111111", ctl_rx_min_packet_len_0 => "00001000",
            ctl_rx_process_lfi_0 => '1', ctl_rx_test_pattern_0 => '0' ,
            ctl_rx_custom_preamble_enable_0 => '0',

            -- Statistics
            stat_rx_block_lock_0 => i_rx_locked,
            stat_rx_bad_fcs_0 => OPEN,
            stat_tx_total_bytes_0 => stat_tx_total_bytes, stat_rx_total_bytes_0 => stat_rx_total_bytes,
            stat_tx_total_packets_0 => stat_tx_total_packets, stat_rx_total_packets_0 => stat_rx_total_packets,
            stat_rx_packet_bad_fcs_0 => stat_rx_bad_fcs, stat_rx_bad_code_0 => stat_rx_bad_code,

            stat_rx_internal_local_fault_0 => rx_local_fault, stat_rx_remote_fault_0 => rx_remote_fault,
            stat_rx_received_local_fault_0 => rx_receive_local_fault,

            stat_rx_framing_err_0_0 => OPEN, stat_rx_framing_err_1_0 => OPEN, stat_rx_framing_err_2_0 => OPEN, stat_rx_framing_err_3_0 => OPEN,
            stat_rx_framing_err_valid_0_0 => OPEN, stat_rx_framing_err_valid_1_0 => OPEN, stat_rx_framing_err_valid_2_0 => OPEN, stat_rx_framing_err_valid_3_0 => OPEN,
            stat_rx_local_fault_0 => OPEN, stat_rx_status_0 => rx_status, stat_rx_stomped_fcs_0 => OPEN, stat_rx_truncated_0 => OPEN,
            stat_rx_hi_ber_0 => OPEN, stat_rx_got_signal_os_0 => OPEN, stat_rx_test_pattern_mismatch_0 => OPEN,
            stat_rx_total_good_bytes_0 => OPEN, stat_rx_total_good_packets_0 => OPEN,
            stat_rx_packet_64_bytes_0 => OPEN, stat_rx_packet_65_127_bytes_0 => OPEN, stat_rx_packet_128_255_bytes_0 => OPEN,
            stat_rx_packet_256_511_bytes_0 => OPEN, stat_rx_packet_512_1023_bytes_0 => OPEN,
            stat_rx_packet_1024_1518_bytes_0 => OPEN, stat_rx_packet_1519_1522_bytes_0 => OPEN,
            stat_rx_packet_1523_1548_bytes_0 => OPEN, stat_rx_packet_1549_2047_bytes_0 => OPEN,
            stat_rx_packet_2048_4095_bytes_0 => OPEN, stat_rx_packet_4096_8191_bytes_0 => OPEN,
            stat_rx_packet_8192_9215_bytes_0 => OPEN, stat_rx_packet_small_0 => OPEN, stat_rx_packet_large_0 => OPEN,
            stat_rx_oversize_0 => OPEN, stat_rx_toolong_0 => OPEN, stat_rx_undersize_0 => OPEN,
            stat_rx_fragment_0 => OPEN, stat_rx_bad_preamble_0 => OPEN, stat_rx_vl_demuxed_0 => OPEN,
            stat_rx_jabber_0 => OPEN, stat_rx_bad_sfd_0 => OPEN,
            stat_rx_vl_number_0_0 => OPEN, stat_rx_vl_number_1_0 => OPEN, stat_rx_vl_number_2_0 => OPEN, stat_rx_vl_number_3_0 => OPEN,
            stat_rx_synced_0 => rx_synced, stat_rx_synced_err_0 => OPEN, stat_rx_mf_len_err_0 => OPEN, stat_rx_mf_repeat_err_0 => OPEN,
            stat_rx_mf_err_0 => OPEN, stat_rx_aligned_0 => rx_aligned, stat_rx_misaligned_0 => OPEN, stat_rx_aligned_err_0 => OPEN,
            stat_rx_bip_err_0_0 => OPEN, stat_rx_bip_err_1_0 => OPEN, stat_rx_bip_err_2_0 => OPEN, stat_rx_bip_err_3_0 => OPEN,
            stat_tx_frame_error_0 => OPEN, stat_tx_local_fault_0 => OPEN,
            stat_tx_total_good_bytes_0 => OPEN, stat_tx_total_good_packets_0 => OPEN, stat_tx_bad_fcs_0 => OPEN,
            stat_tx_packet_64_bytes_0 => OPEN, stat_tx_packet_65_127_bytes_0 => OPEN, stat_tx_packet_128_255_bytes_0 => OPEN,
            stat_tx_packet_256_511_bytes_0 => OPEN, stat_tx_packet_512_1023_bytes_0 => OPEN,
            stat_tx_packet_1024_1518_bytes_0 => OPEN, stat_tx_packet_1519_1522_bytes_0 => OPEN,
            stat_tx_packet_1523_1548_bytes_0 => OPEN, stat_tx_packet_1549_2047_bytes_0 => OPEN,
            stat_tx_packet_2048_4095_bytes_0 => OPEN, stat_tx_packet_4096_8191_bytes_0 => OPEN,
            stat_tx_packet_8192_9215_bytes_0 => OPEN, stat_tx_packet_small_0 => OPEN, stat_tx_packet_large_0 => OPEN,

            -- AXI TX
            user_tx_reset_0 => user_tx_reset, tx_axis_tready_0 => data_tx_siso.tready,
            tx_axis_tvalid_0 => data_tx_sosi.tvalid, tx_axis_tdata_0 => data_tx_sosi.tdata(127 DOWNTO 0),
            tx_axis_tuser_0 => data_tx_sosi.tuser(69 DOWNTO 0),

            -- TX Settings
            tx_unfout_0 => OPEN, ctl_tx_enable_0 => tx_enable,
            ctl_tx_send_rfi_0 => tx_send_rfi, ctl_tx_send_lfi_0 => tx_send_lfi, ctl_tx_send_idle_0 => tx_send_idle,
            ctl_tx_fcs_ins_enable_0 => '1', ctl_tx_ignore_fcs_0 => '0', ctl_tx_test_pattern_0 => '0',
            ctl_tx_ipg_value_0 => X"C", ctl_tx_custom_preamble_enable_0 => '0');
      END GENERATE;

      quad125_gen: IF g_device = QUAD_40G_125 GENERATE
         mac_1: mac_40g_quad_125
         PORT MAP (
            gt_rxp_in_0 => gt_rxp_in(0), gt_rxp_in_1 => gt_rxp_in(1), gt_rxp_in_2 => gt_rxp_in(2), gt_rxp_in_3 => gt_rxp_in(3),
            gt_rxn_in_0 => gt_rxn_in(0), gt_rxn_in_1 => gt_rxn_in(1), gt_rxn_in_2 => gt_rxn_in(2), gt_rxn_in_3 => gt_rxn_in(3),
            gt_txp_out_0 => gt_txp_out(0), gt_txp_out_1 => gt_txp_out(1), gt_txp_out_2 => gt_txp_out(2), gt_txp_out_3 => gt_txp_out(3),
            gt_txn_out_0 => gt_txn_out(0), gt_txn_out_1 => gt_txn_out(1), gt_txn_out_2 => gt_txn_out(2), gt_txn_out_3 => gt_txn_out(3),
            gt_refclk_p => gt_refclk_p, gt_refclk_n => gt_refclk_n,

            txoutclksel_in_0 => "101101101101", rxoutclksel_in_0 => "101101101101",
            rx_core_clk_0 => rx_clk_in, tx_clk_out_0 => tx_clk_out, rx_clk_out_0 => rx_clk_out,
            dclk => dclk,
            gt_common_drpclk => dclk, gt_ch_drpclk_0 => dclk, gt_ch_drpclk_1 => dclk, gt_ch_drpclk_2 => dclk, gt_ch_drpclk_3 => dclk,


            tx_reset_0 => sys_reset, sys_reset => sys_reset, rx_reset_0 => sys_reset,
            gt_loopback_in_0 => i_loopback,

            gt_dmonitorout_0 => OPEN, gt_eyescandataerror_0 => OPEN, gt_eyescanreset_0 => X"0",
            gt_eyescantrigger_0 => X"0", gt_pcsrsvdin_0 => gnd(63 DOWNTO 0), gt_rxbufreset_0 => X"0",
            gt_rxbufstatus_0 => OPEN, gt_rxcdrhold_0 => X"0", gt_rxcommadeten_0 => X"0",

            gt_rxdfeagchold_0 => X"0", gt_rxdfelpmreset_0 => X"0", gt_rxlatclk_0 => dclk_slv,
            gt_rxlpmen_0 => g_rxlpmen, gt_rxpcsreset_0 => X"0", gt_rxpmareset_0 => X"0",
            gt_rxprbscntreset_0 => X"0", gt_rxprbserr_0 => OPEN, gt_rxprbssel_0 => X"0000",
            gt_rxrate_0 => X"000", gt_rxslide_in_0 => X"0", gt_rxstartofseq_0 => OPEN,
            gt_txbufstatus_0 => OPEN, gt_txinhibit_0 => X"0", gt_txlatclk_0 => dclk_slv,

            gt_txdiffctrl_0 => c_txdiffctrl, gt_txmaincursor_0 => c_txmaincursor, gt_txpostcursor_0 => c_txpostcursor,
            gt_txprecursor_0 => c_txprecursor, gt_rxpolarity_0 => g_rxpolarity, gt_txpolarity_0 => g_txpolarity,

            gt_refclk_out => OPEN, gtpowergood_out_0 => OPEN,
            gt_txpcsreset_0 => X"0", gt_txpmareset_0 => X"0", gt_txprbsforceerr_0 => X"0",
            gt_txprbssel_0 => X"0000", gtwiz_reset_tx_datapath_0 => "0",
            gtwiz_reset_rx_datapath_0 => "0", rxrecclkout_0 => OPEN,

            gt_common_drpdo => OPEN, gt_ch_drpdo_0 => OPEN, gt_ch_drpdo_1 => OPEN, gt_ch_drpdo_2 => OPEN, gt_ch_drpdo_3 => OPEN,
            gt_common_drprdy => OPEN, gt_ch_drprdy_0 => OPEN, gt_ch_drprdy_1 => OPEN, gt_ch_drprdy_2 => OPEN, gt_ch_drprdy_3 => OPEN,
            gt_common_drpen => '0', gt_common_drpwe => '0',
            gt_ch_drpen_0 => '0', gt_ch_drpen_1 => '0', gt_ch_drpen_2 => '0', gt_ch_drpen_3 => '0',
            gt_ch_drpwe_0 => '0', gt_ch_drpwe_1 => '0', gt_ch_drpwe_2 => '0', gt_ch_drpwe_3 => '0',
            gt_common_drpaddr => gnd(9 DOWNTO 0), gt_common_drpdi => X"0000",
            gt_ch_drpaddr_0 => gnd(9 DOWNTO 0), gt_ch_drpaddr_1 => gnd(9 DOWNTO 0), gt_ch_drpaddr_2 => gnd(9 DOWNTO 0), gt_ch_drpaddr_3 => gnd(9 DOWNTO 0),
            gt_ch_drpdi_0 => X"0000", gt_ch_drpdi_1 => X"0000", gt_ch_drpdi_2 => X"0000", gt_ch_drpdi_3 => X"0000",

            -- AXI RX
            user_rx_reset_0 => user_rx_reset, rx_axis_tvalid_0 => data_rx_sosi.tvalid,
            rx_axis_tdata_0 => data_rx_sosi.tdata(127 DOWNTO 0), rx_axis_tuser_0 => data_rx_sosi.tuser(69 DOWNTO 0),

            -- RX Control
            ctl_rx_enable_0 => rx_enable, ctl_rx_check_preamble_0 => '1', ctl_rx_check_sfd_0 => '1',
            ctl_rx_force_resync_0 => '0', ctl_rx_delete_fcs_0 => '1', ctl_rx_ignore_fcs_0 => '0',
            ctl_rx_max_packet_len_0 => "011111111111111", ctl_rx_min_packet_len_0 => "00001000",
            ctl_rx_process_lfi_0 => '1', ctl_rx_test_pattern_0 => '0' ,
            ctl_rx_custom_preamble_enable_0 => '0',

            -- Statistics
            stat_rx_block_lock_0 => i_rx_locked,
            stat_rx_bad_fcs_0 => OPEN,
            stat_tx_total_bytes_0 => stat_tx_total_bytes, stat_rx_total_bytes_0 => stat_rx_total_bytes,
            stat_tx_total_packets_0 => stat_tx_total_packets, stat_rx_total_packets_0 => stat_rx_total_packets,
            stat_rx_packet_bad_fcs_0 => stat_rx_bad_fcs, stat_rx_bad_code_0 => stat_rx_bad_code,

            stat_rx_internal_local_fault_0 => rx_local_fault, stat_rx_remote_fault_0 => rx_remote_fault,
            stat_rx_received_local_fault_0 => rx_receive_local_fault,

            stat_rx_framing_err_0_0 => OPEN, stat_rx_framing_err_1_0 => OPEN, stat_rx_framing_err_2_0 => OPEN, stat_rx_framing_err_3_0 => OPEN,
            stat_rx_framing_err_valid_0_0 => OPEN, stat_rx_framing_err_valid_1_0 => OPEN, stat_rx_framing_err_valid_2_0 => OPEN, stat_rx_framing_err_valid_3_0 => OPEN,
            stat_rx_local_fault_0 => OPEN, stat_rx_status_0 => rx_status, stat_rx_stomped_fcs_0 => OPEN, stat_rx_truncated_0 => OPEN,
            stat_rx_hi_ber_0 => OPEN, stat_rx_got_signal_os_0 => OPEN, stat_rx_test_pattern_mismatch_0 => OPEN,
            stat_rx_total_good_bytes_0 => OPEN, stat_rx_total_good_packets_0 => OPEN,
            stat_rx_packet_64_bytes_0 => OPEN, stat_rx_packet_65_127_bytes_0 => OPEN, stat_rx_packet_128_255_bytes_0 => OPEN,
            stat_rx_packet_256_511_bytes_0 => OPEN, stat_rx_packet_512_1023_bytes_0 => OPEN,
            stat_rx_packet_1024_1518_bytes_0 => OPEN, stat_rx_packet_1519_1522_bytes_0 => OPEN,
            stat_rx_packet_1523_1548_bytes_0 => OPEN, stat_rx_packet_1549_2047_bytes_0 => OPEN,
            stat_rx_packet_2048_4095_bytes_0 => OPEN, stat_rx_packet_4096_8191_bytes_0 => OPEN,
            stat_rx_packet_8192_9215_bytes_0 => OPEN, stat_rx_packet_small_0 => OPEN, stat_rx_packet_large_0 => OPEN,
            stat_rx_oversize_0 => OPEN, stat_rx_toolong_0 => OPEN, stat_rx_undersize_0 => OPEN,
            stat_rx_fragment_0 => OPEN, stat_rx_bad_preamble_0 => OPEN, stat_rx_vl_demuxed_0 => OPEN,
            stat_rx_jabber_0 => OPEN, stat_rx_bad_sfd_0 => OPEN,
            stat_rx_vl_number_0_0 => OPEN, stat_rx_vl_number_1_0 => OPEN, stat_rx_vl_number_2_0 => OPEN, stat_rx_vl_number_3_0 => OPEN,
            stat_rx_synced_0 => rx_synced, stat_rx_synced_err_0 => OPEN, stat_rx_mf_len_err_0 => OPEN, stat_rx_mf_repeat_err_0 => OPEN,
            stat_rx_mf_err_0 => OPEN, stat_rx_aligned_0 => rx_aligned, stat_rx_misaligned_0 => OPEN, stat_rx_aligned_err_0 => OPEN,
            stat_rx_bip_err_0_0 => OPEN, stat_rx_bip_err_1_0 => OPEN, stat_rx_bip_err_2_0 => OPEN, stat_rx_bip_err_3_0 => OPEN,
            stat_tx_frame_error_0 => OPEN, stat_tx_local_fault_0 => OPEN,
            stat_tx_total_good_bytes_0 => OPEN, stat_tx_total_good_packets_0 => OPEN, stat_tx_bad_fcs_0 => OPEN,
            stat_tx_packet_64_bytes_0 => OPEN, stat_tx_packet_65_127_bytes_0 => OPEN, stat_tx_packet_128_255_bytes_0 => OPEN,
            stat_tx_packet_256_511_bytes_0 => OPEN, stat_tx_packet_512_1023_bytes_0 => OPEN,
            stat_tx_packet_1024_1518_bytes_0 => OPEN, stat_tx_packet_1519_1522_bytes_0 => OPEN,
            stat_tx_packet_1523_1548_bytes_0 => OPEN, stat_tx_packet_1549_2047_bytes_0 => OPEN,
            stat_tx_packet_2048_4095_bytes_0 => OPEN, stat_tx_packet_4096_8191_bytes_0 => OPEN,
            stat_tx_packet_8192_9215_bytes_0 => OPEN, stat_tx_packet_small_0 => OPEN, stat_tx_packet_large_0 => OPEN,

            -- AXI TX
            user_tx_reset_0 => user_tx_reset, tx_axis_tready_0 => data_tx_siso.tready,
            tx_axis_tvalid_0 => data_tx_sosi.tvalid, tx_axis_tdata_0 => data_tx_sosi.tdata(127 DOWNTO 0),
            tx_axis_tuser_0 => data_tx_sosi.tuser(69 DOWNTO 0),

            -- TX Settings
            tx_unfout_0 => OPEN, ctl_tx_enable_0 => tx_enable,
            ctl_tx_send_rfi_0 => tx_send_rfi, ctl_tx_send_lfi_0 => tx_send_lfi, ctl_tx_send_idle_0 => tx_send_idle,
            ctl_tx_fcs_ins_enable_0 => '1', ctl_tx_ignore_fcs_0 => '0', ctl_tx_test_pattern_0 => '0',
            ctl_tx_ipg_value_0 => X"C", ctl_tx_custom_preamble_enable_0 => '0');
      END GENERATE;

      quad126_gen: IF g_device = QUAD_40G_126 GENERATE
         mac_1: mac_40g_quad_126
         PORT MAP (
            gt_rxp_in_0 => gt_rxp_in(0), gt_rxp_in_1 => gt_rxp_in(1), gt_rxp_in_2 => gt_rxp_in(2), gt_rxp_in_3 => gt_rxp_in(3),
            gt_rxn_in_0 => gt_rxn_in(0), gt_rxn_in_1 => gt_rxn_in(1), gt_rxn_in_2 => gt_rxn_in(2), gt_rxn_in_3 => gt_rxn_in(3),
            gt_txp_out_0 => gt_txp_out(0), gt_txp_out_1 => gt_txp_out(1), gt_txp_out_2 => gt_txp_out(2), gt_txp_out_3 => gt_txp_out(3),
            gt_txn_out_0 => gt_txn_out(0), gt_txn_out_1 => gt_txn_out(1), gt_txn_out_2 => gt_txn_out(2), gt_txn_out_3 => gt_txn_out(3),
            gt_refclk_p => gt_refclk_p, gt_refclk_n => gt_refclk_n,

            txoutclksel_in_0 => "101101101101", rxoutclksel_in_0 => "101101101101",
            rx_core_clk_0 => rx_clk_in, tx_clk_out_0 => tx_clk_out, rx_clk_out_0 => rx_clk_out,
            dclk => dclk,
            gt_common_drpclk => dclk, gt_ch_drpclk_0 => dclk, gt_ch_drpclk_1 => dclk, gt_ch_drpclk_2 => dclk, gt_ch_drpclk_3 => dclk,


            tx_reset_0 => sys_reset, sys_reset => sys_reset, rx_reset_0 => sys_reset,
            gt_loopback_in_0 => i_loopback,

            gt_dmonitorout_0 => OPEN, gt_eyescandataerror_0 => OPEN, gt_eyescanreset_0 => X"0",
            gt_eyescantrigger_0 => X"0", gt_pcsrsvdin_0 => gnd(63 DOWNTO 0), gt_rxbufreset_0 => X"0",
            gt_rxbufstatus_0 => OPEN, gt_rxcdrhold_0 => X"0", gt_rxcommadeten_0 => X"0",

            gt_rxdfeagchold_0 => X"0", gt_rxdfelpmreset_0 => X"0", gt_rxlatclk_0 => dclk_slv,
            gt_rxlpmen_0 => g_rxlpmen, gt_rxpcsreset_0 => X"0", gt_rxpmareset_0 => X"0",
            gt_rxprbscntreset_0 => X"0", gt_rxprbserr_0 => OPEN, gt_rxprbssel_0 => X"0000",
            gt_rxrate_0 => X"000", gt_rxslide_in_0 => X"0", gt_rxstartofseq_0 => OPEN,
            gt_txbufstatus_0 => OPEN, gt_txinhibit_0 => X"0", gt_txlatclk_0 => dclk_slv,

            gt_txdiffctrl_0 => c_txdiffctrl, gt_txmaincursor_0 => c_txmaincursor, gt_txpostcursor_0 => c_txpostcursor,
            gt_txprecursor_0 => c_txprecursor, gt_rxpolarity_0 => g_rxpolarity, gt_txpolarity_0 => g_txpolarity,

            gt_refclk_out => OPEN, gtpowergood_out_0 => OPEN,
            gt_txpcsreset_0 => X"0", gt_txpmareset_0 => X"0", gt_txprbsforceerr_0 => X"0",
            gt_txprbssel_0 => X"0000", gtwiz_reset_tx_datapath_0 => "0",
            gtwiz_reset_rx_datapath_0 => "0", rxrecclkout_0 => OPEN,

            gt_common_drpdo => OPEN, gt_ch_drpdo_0 => OPEN, gt_ch_drpdo_1 => OPEN, gt_ch_drpdo_2 => OPEN, gt_ch_drpdo_3 => OPEN,
            gt_common_drprdy => OPEN, gt_ch_drprdy_0 => OPEN, gt_ch_drprdy_1 => OPEN, gt_ch_drprdy_2 => OPEN, gt_ch_drprdy_3 => OPEN,
            gt_common_drpen => '0', gt_common_drpwe => '0',
            gt_ch_drpen_0 => '0', gt_ch_drpen_1 => '0', gt_ch_drpen_2 => '0', gt_ch_drpen_3 => '0',
            gt_ch_drpwe_0 => '0', gt_ch_drpwe_1 => '0', gt_ch_drpwe_2 => '0', gt_ch_drpwe_3 => '0',
            gt_common_drpaddr => gnd(9 DOWNTO 0), gt_common_drpdi => X"0000",
            gt_ch_drpaddr_0 => gnd(9 DOWNTO 0), gt_ch_drpaddr_1 => gnd(9 DOWNTO 0), gt_ch_drpaddr_2 => gnd(9 DOWNTO 0), gt_ch_drpaddr_3 => gnd(9 DOWNTO 0),
            gt_ch_drpdi_0 => X"0000", gt_ch_drpdi_1 => X"0000", gt_ch_drpdi_2 => X"0000", gt_ch_drpdi_3 => X"0000",

            -- AXI RX
            user_rx_reset_0 => user_rx_reset, rx_axis_tvalid_0 => data_rx_sosi.tvalid,
            rx_axis_tdata_0 => data_rx_sosi.tdata(127 DOWNTO 0), rx_axis_tuser_0 => data_rx_sosi.tuser(69 DOWNTO 0),

            -- RX Control
            ctl_rx_enable_0 => rx_enable, ctl_rx_check_preamble_0 => '1', ctl_rx_check_sfd_0 => '1',
            ctl_rx_force_resync_0 => '0', ctl_rx_delete_fcs_0 => '1', ctl_rx_ignore_fcs_0 => '0',
            ctl_rx_max_packet_len_0 => "010010110000000", ctl_rx_min_packet_len_0 => "01000000",
            ctl_rx_process_lfi_0 => '1', ctl_rx_test_pattern_0 => '0',
            ctl_rx_custom_preamble_enable_0 => '0',

            -- Statistics
            stat_rx_block_lock_0 => i_rx_locked,
            stat_rx_bad_fcs_0 => OPEN,
            stat_tx_total_bytes_0 => stat_tx_total_bytes, stat_rx_total_bytes_0 => stat_rx_total_bytes,
            stat_tx_total_packets_0 => stat_tx_total_packets, stat_rx_total_packets_0 => stat_rx_total_packets,
            stat_rx_packet_bad_fcs_0 => stat_rx_bad_fcs, stat_rx_bad_code_0 => stat_rx_bad_code,

            stat_rx_internal_local_fault_0 => rx_local_fault, stat_rx_remote_fault_0 => rx_remote_fault,
            stat_rx_received_local_fault_0 => rx_receive_local_fault,

            stat_rx_framing_err_0_0 => OPEN, stat_rx_framing_err_1_0 => OPEN, stat_rx_framing_err_2_0 => OPEN, stat_rx_framing_err_3_0 => OPEN,
            stat_rx_framing_err_valid_0_0 => OPEN, stat_rx_framing_err_valid_1_0 => OPEN, stat_rx_framing_err_valid_2_0 => OPEN, stat_rx_framing_err_valid_3_0 => OPEN,
            stat_rx_local_fault_0 => OPEN, stat_rx_status_0 => rx_status, stat_rx_stomped_fcs_0 => OPEN, stat_rx_truncated_0 => OPEN,
            stat_rx_hi_ber_0 => OPEN, stat_rx_got_signal_os_0 => OPEN, stat_rx_test_pattern_mismatch_0 => OPEN,
            stat_rx_total_good_bytes_0 => OPEN, stat_rx_total_good_packets_0 => OPEN,
            stat_rx_packet_64_bytes_0 => OPEN, stat_rx_packet_65_127_bytes_0 => OPEN, stat_rx_packet_128_255_bytes_0 => OPEN,
            stat_rx_packet_256_511_bytes_0 => OPEN, stat_rx_packet_512_1023_bytes_0 => OPEN,
            stat_rx_packet_1024_1518_bytes_0 => OPEN, stat_rx_packet_1519_1522_bytes_0 => OPEN,
            stat_rx_packet_1523_1548_bytes_0 => OPEN, stat_rx_packet_1549_2047_bytes_0 => OPEN,
            stat_rx_packet_2048_4095_bytes_0 => OPEN, stat_rx_packet_4096_8191_bytes_0 => OPEN,
            stat_rx_packet_8192_9215_bytes_0 => OPEN, stat_rx_packet_small_0 => OPEN, stat_rx_packet_large_0 => OPEN,
            stat_rx_oversize_0 => OPEN, stat_rx_toolong_0 => OPEN, stat_rx_undersize_0 => OPEN,
            stat_rx_fragment_0 => OPEN, stat_rx_bad_preamble_0 => OPEN, stat_rx_vl_demuxed_0 => OPEN,
            stat_rx_jabber_0 => OPEN, stat_rx_bad_sfd_0 => OPEN,
            stat_rx_vl_number_0_0 => OPEN, stat_rx_vl_number_1_0 => OPEN, stat_rx_vl_number_2_0 => OPEN, stat_rx_vl_number_3_0 => OPEN,
            stat_rx_synced_0 => rx_synced, stat_rx_synced_err_0 => OPEN, stat_rx_mf_len_err_0 => OPEN, stat_rx_mf_repeat_err_0 => OPEN,
            stat_rx_mf_err_0 => OPEN, stat_rx_aligned_0 => rx_aligned, stat_rx_misaligned_0 => OPEN, stat_rx_aligned_err_0 => OPEN,
            stat_rx_bip_err_0_0 => OPEN, stat_rx_bip_err_1_0 => OPEN, stat_rx_bip_err_2_0 => OPEN, stat_rx_bip_err_3_0 => OPEN,
            stat_tx_frame_error_0 => OPEN, stat_tx_local_fault_0 => OPEN,
            stat_tx_total_good_bytes_0 => OPEN, stat_tx_total_good_packets_0 => OPEN, stat_tx_bad_fcs_0 => OPEN,
            stat_tx_packet_64_bytes_0 => OPEN, stat_tx_packet_65_127_bytes_0 => OPEN, stat_tx_packet_128_255_bytes_0 => OPEN,
            stat_tx_packet_256_511_bytes_0 => OPEN, stat_tx_packet_512_1023_bytes_0 => OPEN,
            stat_tx_packet_1024_1518_bytes_0 => OPEN, stat_tx_packet_1519_1522_bytes_0 => OPEN,
            stat_tx_packet_1523_1548_bytes_0 => OPEN, stat_tx_packet_1549_2047_bytes_0 => OPEN,
            stat_tx_packet_2048_4095_bytes_0 => OPEN, stat_tx_packet_4096_8191_bytes_0 => OPEN,
            stat_tx_packet_8192_9215_bytes_0 => OPEN, stat_tx_packet_small_0 => OPEN, stat_tx_packet_large_0 => OPEN,

            -- AXI TX
            user_tx_reset_0 => user_tx_reset, tx_axis_tready_0 => data_tx_siso.tready,
            tx_axis_tvalid_0 => data_tx_sosi.tvalid, tx_axis_tdata_0 => data_tx_sosi.tdata(127 DOWNTO 0),
            tx_axis_tuser_0 => data_tx_sosi.tuser(69 DOWNTO 0),

            -- TX Settings
            tx_unfout_0 => OPEN, ctl_tx_enable_0 => tx_enable,
            ctl_tx_send_rfi_0 => tx_send_rfi, ctl_tx_send_lfi_0 => tx_send_lfi, ctl_tx_send_idle_0 => tx_send_idle,
            ctl_tx_fcs_ins_enable_0 => '1', ctl_tx_ignore_fcs_0 => '0', ctl_tx_test_pattern_0 => '0',
            ctl_tx_ipg_value_0 => X"C", ctl_tx_custom_preamble_enable_0 => '0');
      END GENERATE;

      quad128_gen: IF g_device = QUAD_40G_128 GENERATE
         mac_1: mac_40g_quad_128
         PORT MAP (
            gt_rxp_in_0 => gt_rxp_in(0), gt_rxp_in_1 => gt_rxp_in(1), gt_rxp_in_2 => gt_rxp_in(2), gt_rxp_in_3 => gt_rxp_in(3),
            gt_rxn_in_0 => gt_rxn_in(0), gt_rxn_in_1 => gt_rxn_in(1), gt_rxn_in_2 => gt_rxn_in(2), gt_rxn_in_3 => gt_rxn_in(3),
            gt_txp_out_0 => gt_txp_out(0), gt_txp_out_1 => gt_txp_out(1), gt_txp_out_2 => gt_txp_out(2), gt_txp_out_3 => gt_txp_out(3),
            gt_txn_out_0 => gt_txn_out(0), gt_txn_out_1 => gt_txn_out(1), gt_txn_out_2 => gt_txn_out(2), gt_txn_out_3 => gt_txn_out(3),
            gt_refclk_p => gt_refclk_p, gt_refclk_n => gt_refclk_n,

            txoutclksel_in_0 => "101101101101", rxoutclksel_in_0 => "101101101101",
            rx_core_clk_0 => rx_clk_in, tx_clk_out_0 => tx_clk_out, rx_clk_out_0 => rx_clk_out,
            dclk => dclk,
            gt_common_drpclk => dclk, gt_ch_drpclk_0 => dclk, gt_ch_drpclk_1 => dclk, gt_ch_drpclk_2 => dclk, gt_ch_drpclk_3 => dclk,


            tx_reset_0 => sys_reset, sys_reset => sys_reset, rx_reset_0 => sys_reset,
            gt_loopback_in_0 => i_loopback,

            gt_dmonitorout_0 => OPEN, gt_eyescandataerror_0 => OPEN, gt_eyescanreset_0 => X"0",
            gt_eyescantrigger_0 => X"0", gt_pcsrsvdin_0 => gnd(63 DOWNTO 0), gt_rxbufreset_0 => X"0",
            gt_rxbufstatus_0 => OPEN, gt_rxcdrhold_0 => X"0", gt_rxcommadeten_0 => X"0",

            gt_rxdfeagchold_0 => X"0", gt_rxdfelpmreset_0 => X"0", gt_rxlatclk_0 => dclk_slv,
            gt_rxlpmen_0 => g_rxlpmen, gt_rxpcsreset_0 => X"0", gt_rxpmareset_0 => X"0",
            gt_rxprbscntreset_0 => X"0", gt_rxprbserr_0 => OPEN, gt_rxprbssel_0 => X"0000",
            gt_rxrate_0 => X"000", gt_rxslide_in_0 => X"0", gt_rxstartofseq_0 => OPEN,
            gt_txbufstatus_0 => OPEN, gt_txinhibit_0 => X"0", gt_txlatclk_0 => dclk_slv,

            gt_txdiffctrl_0 => c_txdiffctrl, gt_txmaincursor_0 => c_txmaincursor, gt_txpostcursor_0 => c_txpostcursor,
            gt_txprecursor_0 => c_txprecursor, gt_rxpolarity_0 => g_rxpolarity, gt_txpolarity_0 => g_txpolarity,

            gt_refclk_out => OPEN, gtpowergood_out_0 => OPEN,
            gt_txpcsreset_0 => X"0", gt_txpmareset_0 => X"0", gt_txprbsforceerr_0 => X"0",
            gt_txprbssel_0 => X"0000", gtwiz_reset_tx_datapath_0 => "0",
            gtwiz_reset_rx_datapath_0 => "0", rxrecclkout_0 => OPEN,

            gt_common_drpdo => OPEN, gt_ch_drpdo_0 => OPEN, gt_ch_drpdo_1 => OPEN, gt_ch_drpdo_2 => OPEN, gt_ch_drpdo_3 => OPEN,
            gt_common_drprdy => OPEN, gt_ch_drprdy_0 => OPEN, gt_ch_drprdy_1 => OPEN, gt_ch_drprdy_2 => OPEN, gt_ch_drprdy_3 => OPEN,
            gt_common_drpen => '0', gt_common_drpwe => '0',
            gt_ch_drpen_0 => '0', gt_ch_drpen_1 => '0', gt_ch_drpen_2 => '0', gt_ch_drpen_3 => '0',
            gt_ch_drpwe_0 => '0', gt_ch_drpwe_1 => '0', gt_ch_drpwe_2 => '0', gt_ch_drpwe_3 => '0',
            gt_common_drpaddr => gnd(9 DOWNTO 0), gt_common_drpdi => X"0000",
            gt_ch_drpaddr_0 => gnd(9 DOWNTO 0), gt_ch_drpaddr_1 => gnd(9 DOWNTO 0), gt_ch_drpaddr_2 => gnd(9 DOWNTO 0), gt_ch_drpaddr_3 => gnd(9 DOWNTO 0),
            gt_ch_drpdi_0 => X"0000", gt_ch_drpdi_1 => X"0000", gt_ch_drpdi_2 => X"0000", gt_ch_drpdi_3 => X"0000",

            -- AXI RX
            user_rx_reset_0 => user_rx_reset, rx_axis_tvalid_0 => data_rx_sosi.tvalid,
            rx_axis_tdata_0 => data_rx_sosi.tdata(127 DOWNTO 0), rx_axis_tuser_0 => data_rx_sosi.tuser(69 DOWNTO 0),

            -- RX Control
            ctl_rx_enable_0 => rx_enable, ctl_rx_check_preamble_0 => '1', ctl_rx_check_sfd_0 => '1',
            ctl_rx_force_resync_0 => '0', ctl_rx_delete_fcs_0 => '1', ctl_rx_ignore_fcs_0 => '0',
            ctl_rx_max_packet_len_0 => "011111111111111", ctl_rx_min_packet_len_0 => "00001000",
            ctl_rx_process_lfi_0 => '1', ctl_rx_test_pattern_0 => '0' ,
            ctl_rx_custom_preamble_enable_0 => '0',

            -- Statistics
            stat_rx_block_lock_0 => i_rx_locked,
            stat_rx_bad_fcs_0 => OPEN,
            stat_tx_total_bytes_0 => stat_tx_total_bytes, stat_rx_total_bytes_0 => stat_rx_total_bytes,
            stat_tx_total_packets_0 => stat_tx_total_packets, stat_rx_total_packets_0 => stat_rx_total_packets,
            stat_rx_packet_bad_fcs_0 => stat_rx_bad_fcs, stat_rx_bad_code_0 => stat_rx_bad_code,

            stat_rx_internal_local_fault_0 => rx_local_fault, stat_rx_remote_fault_0 => rx_remote_fault,
            stat_rx_received_local_fault_0 => rx_receive_local_fault,

            stat_rx_framing_err_0_0 => OPEN, stat_rx_framing_err_1_0 => OPEN, stat_rx_framing_err_2_0 => OPEN, stat_rx_framing_err_3_0 => OPEN,
            stat_rx_framing_err_valid_0_0 => OPEN, stat_rx_framing_err_valid_1_0 => OPEN, stat_rx_framing_err_valid_2_0 => OPEN, stat_rx_framing_err_valid_3_0 => OPEN,
            stat_rx_local_fault_0 => OPEN, stat_rx_status_0 => rx_status, stat_rx_stomped_fcs_0 => OPEN, stat_rx_truncated_0 => OPEN,
            stat_rx_hi_ber_0 => OPEN, stat_rx_got_signal_os_0 => OPEN, stat_rx_test_pattern_mismatch_0 => OPEN,
            stat_rx_total_good_bytes_0 => OPEN, stat_rx_total_good_packets_0 => OPEN,
            stat_rx_packet_64_bytes_0 => OPEN, stat_rx_packet_65_127_bytes_0 => OPEN, stat_rx_packet_128_255_bytes_0 => OPEN,
            stat_rx_packet_256_511_bytes_0 => OPEN, stat_rx_packet_512_1023_bytes_0 => OPEN,
            stat_rx_packet_1024_1518_bytes_0 => OPEN, stat_rx_packet_1519_1522_bytes_0 => OPEN,
            stat_rx_packet_1523_1548_bytes_0 => OPEN, stat_rx_packet_1549_2047_bytes_0 => OPEN,
            stat_rx_packet_2048_4095_bytes_0 => OPEN, stat_rx_packet_4096_8191_bytes_0 => OPEN,
            stat_rx_packet_8192_9215_bytes_0 => OPEN, stat_rx_packet_small_0 => OPEN, stat_rx_packet_large_0 => OPEN,
            stat_rx_oversize_0 => OPEN, stat_rx_toolong_0 => OPEN, stat_rx_undersize_0 => OPEN,
            stat_rx_fragment_0 => OPEN, stat_rx_bad_preamble_0 => OPEN, stat_rx_vl_demuxed_0 => OPEN,
            stat_rx_jabber_0 => OPEN, stat_rx_bad_sfd_0 => OPEN,
            stat_rx_vl_number_0_0 => OPEN, stat_rx_vl_number_1_0 => OPEN, stat_rx_vl_number_2_0 => OPEN, stat_rx_vl_number_3_0 => OPEN,
            stat_rx_synced_0 => rx_synced, stat_rx_synced_err_0 => OPEN, stat_rx_mf_len_err_0 => OPEN, stat_rx_mf_repeat_err_0 => OPEN,
            stat_rx_mf_err_0 => OPEN, stat_rx_aligned_0 => rx_aligned, stat_rx_misaligned_0 => OPEN, stat_rx_aligned_err_0 => OPEN,
            stat_rx_bip_err_0_0 => OPEN, stat_rx_bip_err_1_0 => OPEN, stat_rx_bip_err_2_0 => OPEN, stat_rx_bip_err_3_0 => OPEN,
            stat_tx_frame_error_0 => OPEN, stat_tx_local_fault_0 => OPEN,
            stat_tx_total_good_bytes_0 => OPEN, stat_tx_total_good_packets_0 => OPEN, stat_tx_bad_fcs_0 => OPEN,
            stat_tx_packet_64_bytes_0 => OPEN, stat_tx_packet_65_127_bytes_0 => OPEN, stat_tx_packet_128_255_bytes_0 => OPEN,
            stat_tx_packet_256_511_bytes_0 => OPEN, stat_tx_packet_512_1023_bytes_0 => OPEN,
            stat_tx_packet_1024_1518_bytes_0 => OPEN, stat_tx_packet_1519_1522_bytes_0 => OPEN,
            stat_tx_packet_1523_1548_bytes_0 => OPEN, stat_tx_packet_1549_2047_bytes_0 => OPEN,
            stat_tx_packet_2048_4095_bytes_0 => OPEN, stat_tx_packet_4096_8191_bytes_0 => OPEN,
            stat_tx_packet_8192_9215_bytes_0 => OPEN, stat_tx_packet_small_0 => OPEN, stat_tx_packet_large_0 => OPEN,

            -- AXI TX
            user_tx_reset_0 => user_tx_reset, tx_axis_tready_0 => data_tx_siso.tready,
            tx_axis_tvalid_0 => data_tx_sosi.tvalid, tx_axis_tdata_0 => data_tx_sosi.tdata(127 DOWNTO 0),
            tx_axis_tuser_0 => data_tx_sosi.tuser(69 DOWNTO 0),

            -- TX Settings
            tx_unfout_0 => OPEN, ctl_tx_enable_0 => tx_enable,
            ctl_tx_send_rfi_0 => tx_send_rfi, ctl_tx_send_lfi_0 => tx_send_lfi, ctl_tx_send_idle_0 => tx_send_idle,
            ctl_tx_fcs_ins_enable_0 => '1', ctl_tx_ignore_fcs_0 => '0', ctl_tx_test_pattern_0 => '0',
            ctl_tx_ipg_value_0 => X"C", ctl_tx_custom_preamble_enable_0 => '0');
      END GENERATE;

      quad130_gen: IF g_device = QUAD_40G_130 GENERATE
         mac_1: mac_40g_quad_130
         PORT MAP (
            gt_rxp_in_0 => gt_rxp_in(0), gt_rxp_in_1 => gt_rxp_in(1), gt_rxp_in_2 => gt_rxp_in(2), gt_rxp_in_3 => gt_rxp_in(3),
            gt_rxn_in_0 => gt_rxn_in(0), gt_rxn_in_1 => gt_rxn_in(1), gt_rxn_in_2 => gt_rxn_in(2), gt_rxn_in_3 => gt_rxn_in(3),
            gt_txp_out_0 => gt_txp_out(0), gt_txp_out_1 => gt_txp_out(1), gt_txp_out_2 => gt_txp_out(2), gt_txp_out_3 => gt_txp_out(3),
            gt_txn_out_0 => gt_txn_out(0), gt_txn_out_1 => gt_txn_out(1), gt_txn_out_2 => gt_txn_out(2), gt_txn_out_3 => gt_txn_out(3),
            gt_refclk_p => gt_refclk_p, gt_refclk_n => gt_refclk_n,

            txoutclksel_in_0 => "101101101101", rxoutclksel_in_0 => "101101101101",
            rx_core_clk_0 => rx_clk_in, tx_clk_out_0 => tx_clk_out, rx_clk_out_0 => rx_clk_out,
            dclk => dclk,
            gt_common_drpclk => dclk, gt_ch_drpclk_0 => dclk, gt_ch_drpclk_1 => dclk, gt_ch_drpclk_2 => dclk, gt_ch_drpclk_3 => dclk,


            tx_reset_0 => sys_reset, sys_reset => sys_reset, rx_reset_0 => sys_reset,
            gt_loopback_in_0 => i_loopback,

            gt_dmonitorout_0 => OPEN, gt_eyescandataerror_0 => OPEN, gt_eyescanreset_0 => X"0",
            gt_eyescantrigger_0 => X"0", gt_pcsrsvdin_0 => gnd(63 DOWNTO 0), gt_rxbufreset_0 => X"0",
            gt_rxbufstatus_0 => OPEN, gt_rxcdrhold_0 => X"0", gt_rxcommadeten_0 => X"0",

            gt_rxdfeagchold_0 => X"0", gt_rxdfelpmreset_0 => X"0", gt_rxlatclk_0 => dclk_slv,
            gt_rxlpmen_0 => g_rxlpmen, gt_rxpcsreset_0 => X"0", gt_rxpmareset_0 => X"0",
            gt_rxprbscntreset_0 => X"0", gt_rxprbserr_0 => OPEN, gt_rxprbssel_0 => X"0000",
            gt_rxrate_0 => X"000", gt_rxslide_in_0 => X"0", gt_rxstartofseq_0 => OPEN,
            gt_txbufstatus_0 => OPEN, gt_txinhibit_0 => X"0", gt_txlatclk_0 => dclk_slv,

            gt_txdiffctrl_0 => c_txdiffctrl, gt_txmaincursor_0 => c_txmaincursor, gt_txpostcursor_0 => c_txpostcursor,
            gt_txprecursor_0 => c_txprecursor, gt_rxpolarity_0 => g_rxpolarity, gt_txpolarity_0 => g_txpolarity,

            gt_refclk_out => OPEN, gtpowergood_out_0 => OPEN,
            gt_txpcsreset_0 => X"0", gt_txpmareset_0 => X"0", gt_txprbsforceerr_0 => X"0",
            gt_txprbssel_0 => X"0000", gtwiz_reset_tx_datapath_0 => "0",
            gtwiz_reset_rx_datapath_0 => "0", rxrecclkout_0 => OPEN,

            gt_common_drpdo => OPEN, gt_ch_drpdo_0 => OPEN, gt_ch_drpdo_1 => OPEN, gt_ch_drpdo_2 => OPEN, gt_ch_drpdo_3 => OPEN,
            gt_common_drprdy => OPEN, gt_ch_drprdy_0 => OPEN, gt_ch_drprdy_1 => OPEN, gt_ch_drprdy_2 => OPEN, gt_ch_drprdy_3 => OPEN,
            gt_common_drpen => '0', gt_common_drpwe => '0',
            gt_ch_drpen_0 => '0', gt_ch_drpen_1 => '0', gt_ch_drpen_2 => '0', gt_ch_drpen_3 => '0',
            gt_ch_drpwe_0 => '0', gt_ch_drpwe_1 => '0', gt_ch_drpwe_2 => '0', gt_ch_drpwe_3 => '0',
            gt_common_drpaddr => gnd(9 DOWNTO 0), gt_common_drpdi => X"0000",
            gt_ch_drpaddr_0 => gnd(9 DOWNTO 0), gt_ch_drpaddr_1 => gnd(9 DOWNTO 0), gt_ch_drpaddr_2 => gnd(9 DOWNTO 0), gt_ch_drpaddr_3 => gnd(9 DOWNTO 0),
            gt_ch_drpdi_0 => X"0000", gt_ch_drpdi_1 => X"0000", gt_ch_drpdi_2 => X"0000", gt_ch_drpdi_3 => X"0000",

            -- AXI RX
            user_rx_reset_0 => user_rx_reset, rx_axis_tvalid_0 => data_rx_sosi.tvalid,
            rx_axis_tdata_0 => data_rx_sosi.tdata(127 DOWNTO 0), rx_axis_tuser_0 => data_rx_sosi.tuser(69 DOWNTO 0),

            -- RX Control
            ctl_rx_enable_0 => rx_enable, ctl_rx_check_preamble_0 => '1', ctl_rx_check_sfd_0 => '1',
            ctl_rx_force_resync_0 => '0', ctl_rx_delete_fcs_0 => '1', ctl_rx_ignore_fcs_0 => '0',
            ctl_rx_max_packet_len_0 => "011111111111111", ctl_rx_min_packet_len_0 => "00001000",
            ctl_rx_process_lfi_0 => '1', ctl_rx_test_pattern_0 => '0' ,
            ctl_rx_custom_preamble_enable_0 => '0',

            -- Statistics
            stat_rx_block_lock_0 => i_rx_locked,
            stat_rx_bad_fcs_0 => OPEN,
            stat_tx_total_bytes_0 => stat_tx_total_bytes, stat_rx_total_bytes_0 => stat_rx_total_bytes,
            stat_tx_total_packets_0 => stat_tx_total_packets, stat_rx_total_packets_0 => stat_rx_total_packets,
            stat_rx_packet_bad_fcs_0 => stat_rx_bad_fcs, stat_rx_bad_code_0 => stat_rx_bad_code,

            stat_rx_internal_local_fault_0 => rx_local_fault, stat_rx_remote_fault_0 => rx_remote_fault,
            stat_rx_received_local_fault_0 => rx_receive_local_fault,

            stat_rx_framing_err_0_0 => OPEN, stat_rx_framing_err_1_0 => OPEN, stat_rx_framing_err_2_0 => OPEN, stat_rx_framing_err_3_0 => OPEN,
            stat_rx_framing_err_valid_0_0 => OPEN, stat_rx_framing_err_valid_1_0 => OPEN, stat_rx_framing_err_valid_2_0 => OPEN, stat_rx_framing_err_valid_3_0 => OPEN,
            stat_rx_local_fault_0 => OPEN, stat_rx_status_0 => rx_status, stat_rx_stomped_fcs_0 => OPEN, stat_rx_truncated_0 => OPEN,
            stat_rx_hi_ber_0 => OPEN, stat_rx_got_signal_os_0 => OPEN, stat_rx_test_pattern_mismatch_0 => OPEN,
            stat_rx_total_good_bytes_0 => OPEN, stat_rx_total_good_packets_0 => OPEN,
            stat_rx_packet_64_bytes_0 => OPEN, stat_rx_packet_65_127_bytes_0 => OPEN, stat_rx_packet_128_255_bytes_0 => OPEN,
            stat_rx_packet_256_511_bytes_0 => OPEN, stat_rx_packet_512_1023_bytes_0 => OPEN,
            stat_rx_packet_1024_1518_bytes_0 => OPEN, stat_rx_packet_1519_1522_bytes_0 => OPEN,
            stat_rx_packet_1523_1548_bytes_0 => OPEN, stat_rx_packet_1549_2047_bytes_0 => OPEN,
            stat_rx_packet_2048_4095_bytes_0 => OPEN, stat_rx_packet_4096_8191_bytes_0 => OPEN,
            stat_rx_packet_8192_9215_bytes_0 => OPEN, stat_rx_packet_small_0 => OPEN, stat_rx_packet_large_0 => OPEN,
            stat_rx_oversize_0 => OPEN, stat_rx_toolong_0 => OPEN, stat_rx_undersize_0 => OPEN,
            stat_rx_fragment_0 => OPEN, stat_rx_bad_preamble_0 => OPEN, stat_rx_vl_demuxed_0 => OPEN,
            stat_rx_jabber_0 => OPEN, stat_rx_bad_sfd_0 => OPEN,
            stat_rx_vl_number_0_0 => OPEN, stat_rx_vl_number_1_0 => OPEN, stat_rx_vl_number_2_0 => OPEN, stat_rx_vl_number_3_0 => OPEN,
            stat_rx_synced_0 => rx_synced, stat_rx_synced_err_0 => OPEN, stat_rx_mf_len_err_0 => OPEN, stat_rx_mf_repeat_err_0 => OPEN,
            stat_rx_mf_err_0 => OPEN, stat_rx_aligned_0 => rx_aligned, stat_rx_misaligned_0 => OPEN, stat_rx_aligned_err_0 => OPEN,
            stat_rx_bip_err_0_0 => OPEN, stat_rx_bip_err_1_0 => OPEN, stat_rx_bip_err_2_0 => OPEN, stat_rx_bip_err_3_0 => OPEN,
            stat_tx_frame_error_0 => OPEN, stat_tx_local_fault_0 => OPEN,
            stat_tx_total_good_bytes_0 => OPEN, stat_tx_total_good_packets_0 => OPEN, stat_tx_bad_fcs_0 => OPEN,
            stat_tx_packet_64_bytes_0 => OPEN, stat_tx_packet_65_127_bytes_0 => OPEN, stat_tx_packet_128_255_bytes_0 => OPEN,
            stat_tx_packet_256_511_bytes_0 => OPEN, stat_tx_packet_512_1023_bytes_0 => OPEN,
            stat_tx_packet_1024_1518_bytes_0 => OPEN, stat_tx_packet_1519_1522_bytes_0 => OPEN,
            stat_tx_packet_1523_1548_bytes_0 => OPEN, stat_tx_packet_1549_2047_bytes_0 => OPEN,
            stat_tx_packet_2048_4095_bytes_0 => OPEN, stat_tx_packet_4096_8191_bytes_0 => OPEN,
            stat_tx_packet_8192_9215_bytes_0 => OPEN, stat_tx_packet_small_0 => OPEN, stat_tx_packet_large_0 => OPEN,

            -- AXI TX
            user_tx_reset_0 => user_tx_reset, tx_axis_tready_0 => data_tx_siso.tready,
            tx_axis_tvalid_0 => data_tx_sosi.tvalid, tx_axis_tdata_0 => data_tx_sosi.tdata(127 DOWNTO 0),
            tx_axis_tuser_0 => data_tx_sosi.tuser(69 DOWNTO 0),

            -- TX Settings
            tx_unfout_0 => OPEN, ctl_tx_enable_0 => tx_enable,
            ctl_tx_send_rfi_0 => tx_send_rfi, ctl_tx_send_lfi_0 => tx_send_lfi, ctl_tx_send_idle_0 => tx_send_idle,
            ctl_tx_fcs_ins_enable_0 => '1', ctl_tx_ignore_fcs_0 => '0', ctl_tx_test_pattern_0 => '0',
            ctl_tx_ipg_value_0 => X"C", ctl_tx_custom_preamble_enable_0 => '0');
      END GENERATE;

      quad131_gen: IF g_device = QUAD_40G_131 GENERATE
         mac_1: mac_40g_quad_131
         PORT MAP (
            gt_rxp_in_0 => gt_rxp_in(0), gt_rxp_in_1 => gt_rxp_in(1), gt_rxp_in_2 => gt_rxp_in(2), gt_rxp_in_3 => gt_rxp_in(3),
            gt_rxn_in_0 => gt_rxn_in(0), gt_rxn_in_1 => gt_rxn_in(1), gt_rxn_in_2 => gt_rxn_in(2), gt_rxn_in_3 => gt_rxn_in(3),
            gt_txp_out_0 => gt_txp_out(0), gt_txp_out_1 => gt_txp_out(1), gt_txp_out_2 => gt_txp_out(2), gt_txp_out_3 => gt_txp_out(3),
            gt_txn_out_0 => gt_txn_out(0), gt_txn_out_1 => gt_txn_out(1), gt_txn_out_2 => gt_txn_out(2), gt_txn_out_3 => gt_txn_out(3),
            gt_refclk_p => gt_refclk_p, gt_refclk_n => gt_refclk_n,

            txoutclksel_in_0 => "101101101101", rxoutclksel_in_0 => "101101101101",
            rx_core_clk_0 => rx_clk_in, tx_clk_out_0 => tx_clk_out, rx_clk_out_0 => rx_clk_out,
            dclk => dclk,
            gt_common_drpclk => dclk, gt_ch_drpclk_0 => dclk, gt_ch_drpclk_1 => dclk, gt_ch_drpclk_2 => dclk, gt_ch_drpclk_3 => dclk,


            tx_reset_0 => sys_reset, sys_reset => sys_reset, rx_reset_0 => sys_reset,
            gt_loopback_in_0 => i_loopback,

            gt_dmonitorout_0 => OPEN, gt_eyescandataerror_0 => OPEN, gt_eyescanreset_0 => X"0",
            gt_eyescantrigger_0 => X"0", gt_pcsrsvdin_0 => gnd(63 DOWNTO 0), gt_rxbufreset_0 => X"0",
            gt_rxbufstatus_0 => OPEN, gt_rxcdrhold_0 => X"0", gt_rxcommadeten_0 => X"0",

            gt_rxdfeagchold_0 => X"0", gt_rxdfelpmreset_0 => X"0", gt_rxlatclk_0 => dclk_slv,
            gt_rxlpmen_0 => g_rxlpmen, gt_rxpcsreset_0 => X"0", gt_rxpmareset_0 => X"0",
            gt_rxprbscntreset_0 => X"0", gt_rxprbserr_0 => OPEN, gt_rxprbssel_0 => X"0000",
            gt_rxrate_0 => X"000", gt_rxslide_in_0 => X"0", gt_rxstartofseq_0 => OPEN,
            gt_txbufstatus_0 => OPEN, gt_txinhibit_0 => X"0", gt_txlatclk_0 => dclk_slv,

            gt_txdiffctrl_0 => c_txdiffctrl, gt_txmaincursor_0 => c_txmaincursor, gt_txpostcursor_0 => c_txpostcursor,
            gt_txprecursor_0 => c_txprecursor, gt_rxpolarity_0 => g_rxpolarity, gt_txpolarity_0 => g_txpolarity,

            gt_refclk_out => OPEN, gtpowergood_out_0 => OPEN,
            gt_txpcsreset_0 => X"0", gt_txpmareset_0 => X"0", gt_txprbsforceerr_0 => X"0",
            gt_txprbssel_0 => X"0000", gtwiz_reset_tx_datapath_0 => "0",
            gtwiz_reset_rx_datapath_0 => "0", rxrecclkout_0 => OPEN,

            gt_common_drpdo => OPEN, gt_ch_drpdo_0 => OPEN, gt_ch_drpdo_1 => OPEN, gt_ch_drpdo_2 => OPEN, gt_ch_drpdo_3 => OPEN,
            gt_common_drprdy => OPEN, gt_ch_drprdy_0 => OPEN, gt_ch_drprdy_1 => OPEN, gt_ch_drprdy_2 => OPEN, gt_ch_drprdy_3 => OPEN,
            gt_common_drpen => '0', gt_common_drpwe => '0',
            gt_ch_drpen_0 => '0', gt_ch_drpen_1 => '0', gt_ch_drpen_2 => '0', gt_ch_drpen_3 => '0',
            gt_ch_drpwe_0 => '0', gt_ch_drpwe_1 => '0', gt_ch_drpwe_2 => '0', gt_ch_drpwe_3 => '0',
            gt_common_drpaddr => gnd(9 DOWNTO 0), gt_common_drpdi => X"0000",
            gt_ch_drpaddr_0 => gnd(9 DOWNTO 0), gt_ch_drpaddr_1 => gnd(9 DOWNTO 0), gt_ch_drpaddr_2 => gnd(9 DOWNTO 0), gt_ch_drpaddr_3 => gnd(9 DOWNTO 0),
            gt_ch_drpdi_0 => X"0000", gt_ch_drpdi_1 => X"0000", gt_ch_drpdi_2 => X"0000", gt_ch_drpdi_3 => X"0000",

            -- AXI RX
            user_rx_reset_0 => user_rx_reset, rx_axis_tvalid_0 => data_rx_sosi.tvalid,
            rx_axis_tdata_0 => data_rx_sosi.tdata(127 DOWNTO 0), rx_axis_tuser_0 => data_rx_sosi.tuser(69 DOWNTO 0),

            -- RX Control
            ctl_rx_enable_0 => rx_enable, ctl_rx_check_preamble_0 => '1', ctl_rx_check_sfd_0 => '1',
            ctl_rx_force_resync_0 => '0', ctl_rx_delete_fcs_0 => '1', ctl_rx_ignore_fcs_0 => '0',
            ctl_rx_max_packet_len_0 => "011111111111111", ctl_rx_min_packet_len_0 => "00001000",
            ctl_rx_process_lfi_0 => '1', ctl_rx_test_pattern_0 => '0' ,
            ctl_rx_custom_preamble_enable_0 => '0',

            -- Statistics
            stat_rx_block_lock_0 => i_rx_locked,
            stat_rx_bad_fcs_0 => OPEN,
            stat_tx_total_bytes_0 => stat_tx_total_bytes, stat_rx_total_bytes_0 => stat_rx_total_bytes,
            stat_tx_total_packets_0 => stat_tx_total_packets, stat_rx_total_packets_0 => stat_rx_total_packets,
            stat_rx_packet_bad_fcs_0 => stat_rx_bad_fcs, stat_rx_bad_code_0 => stat_rx_bad_code,

            stat_rx_internal_local_fault_0 => rx_local_fault, stat_rx_remote_fault_0 => rx_remote_fault,
            stat_rx_received_local_fault_0 => rx_receive_local_fault,

            stat_rx_framing_err_0_0 => OPEN, stat_rx_framing_err_1_0 => OPEN, stat_rx_framing_err_2_0 => OPEN, stat_rx_framing_err_3_0 => OPEN,
            stat_rx_framing_err_valid_0_0 => OPEN, stat_rx_framing_err_valid_1_0 => OPEN, stat_rx_framing_err_valid_2_0 => OPEN, stat_rx_framing_err_valid_3_0 => OPEN,
            stat_rx_local_fault_0 => OPEN, stat_rx_status_0 => rx_status, stat_rx_stomped_fcs_0 => OPEN, stat_rx_truncated_0 => OPEN,
            stat_rx_hi_ber_0 => OPEN, stat_rx_got_signal_os_0 => OPEN, stat_rx_test_pattern_mismatch_0 => OPEN,
            stat_rx_total_good_bytes_0 => OPEN, stat_rx_total_good_packets_0 => OPEN,
            stat_rx_packet_64_bytes_0 => OPEN, stat_rx_packet_65_127_bytes_0 => OPEN, stat_rx_packet_128_255_bytes_0 => OPEN,
            stat_rx_packet_256_511_bytes_0 => OPEN, stat_rx_packet_512_1023_bytes_0 => OPEN,
            stat_rx_packet_1024_1518_bytes_0 => OPEN, stat_rx_packet_1519_1522_bytes_0 => OPEN,
            stat_rx_packet_1523_1548_bytes_0 => OPEN, stat_rx_packet_1549_2047_bytes_0 => OPEN,
            stat_rx_packet_2048_4095_bytes_0 => OPEN, stat_rx_packet_4096_8191_bytes_0 => OPEN,
            stat_rx_packet_8192_9215_bytes_0 => OPEN, stat_rx_packet_small_0 => OPEN, stat_rx_packet_large_0 => OPEN,
            stat_rx_oversize_0 => OPEN, stat_rx_toolong_0 => OPEN, stat_rx_undersize_0 => OPEN,
            stat_rx_fragment_0 => OPEN, stat_rx_bad_preamble_0 => OPEN, stat_rx_vl_demuxed_0 => OPEN,
            stat_rx_jabber_0 => OPEN, stat_rx_bad_sfd_0 => OPEN,
            stat_rx_vl_number_0_0 => OPEN, stat_rx_vl_number_1_0 => OPEN, stat_rx_vl_number_2_0 => OPEN, stat_rx_vl_number_3_0 => OPEN,
            stat_rx_synced_0 => rx_synced, stat_rx_synced_err_0 => OPEN, stat_rx_mf_len_err_0 => OPEN, stat_rx_mf_repeat_err_0 => OPEN,
            stat_rx_mf_err_0 => OPEN, stat_rx_aligned_0 => rx_aligned, stat_rx_misaligned_0 => OPEN, stat_rx_aligned_err_0 => OPEN,
            stat_rx_bip_err_0_0 => OPEN, stat_rx_bip_err_1_0 => OPEN, stat_rx_bip_err_2_0 => OPEN, stat_rx_bip_err_3_0 => OPEN,
            stat_tx_frame_error_0 => OPEN, stat_tx_local_fault_0 => OPEN,
            stat_tx_total_good_bytes_0 => OPEN, stat_tx_total_good_packets_0 => OPEN, stat_tx_bad_fcs_0 => OPEN,
            stat_tx_packet_64_bytes_0 => OPEN, stat_tx_packet_65_127_bytes_0 => OPEN, stat_tx_packet_128_255_bytes_0 => OPEN,
            stat_tx_packet_256_511_bytes_0 => OPEN, stat_tx_packet_512_1023_bytes_0 => OPEN,
            stat_tx_packet_1024_1518_bytes_0 => OPEN, stat_tx_packet_1519_1522_bytes_0 => OPEN,
            stat_tx_packet_1523_1548_bytes_0 => OPEN, stat_tx_packet_1549_2047_bytes_0 => OPEN,
            stat_tx_packet_2048_4095_bytes_0 => OPEN, stat_tx_packet_4096_8191_bytes_0 => OPEN,
            stat_tx_packet_8192_9215_bytes_0 => OPEN, stat_tx_packet_small_0 => OPEN, stat_tx_packet_large_0 => OPEN,

            -- AXI TX
            user_tx_reset_0 => user_tx_reset, tx_axis_tready_0 => data_tx_siso.tready,
            tx_axis_tvalid_0 => data_tx_sosi.tvalid, tx_axis_tdata_0 => data_tx_sosi.tdata(127 DOWNTO 0),
            tx_axis_tuser_0 => data_tx_sosi.tuser(69 DOWNTO 0),

            -- TX Settings
            tx_unfout_0 => OPEN, ctl_tx_enable_0 => tx_enable,
            ctl_tx_send_rfi_0 => tx_send_rfi, ctl_tx_send_lfi_0 => tx_send_lfi, ctl_tx_send_idle_0 => tx_send_idle,
            ctl_tx_fcs_ins_enable_0 => '1', ctl_tx_ignore_fcs_0 => '0', ctl_tx_test_pattern_0 => '0',
            ctl_tx_ipg_value_0 => X"C", ctl_tx_custom_preamble_enable_0 => '0');
      END GENERATE;



   END GENERATE;





END str;





