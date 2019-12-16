onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /tb_ctc/g_SAMPLE_RATE_IN_NS
add wave -noupdate -radix unsigned /tb_ctc/g_INTEGRATION_TIME_IN_PS
add wave -noupdate -radix unsigned /tb_ctc/g_PS_PER_OUTPUT_BLOCK
add wave -noupdate -radix unsigned /tb_ctc/g_NS_PER_OUTPUT_BLOCK
add wave -noupdate -radix unsigned /tb_ctc/g_NS_PER_INPUT_BLOCK
add wave -noupdate -radix decimal /tb_ctc/g_PRIME_TIME
add wave -noupdate -radix unsigned /tb_ctc/g_READOUT_START_TIME
add wave -noupdate -radix unsigned /tb_ctc/g_INPUT_BLOCK_TIME_OFFSET
add wave -noupdate /tb_ctc/hbm_clk
add wave -noupdate /tb_ctc/apb_clk
add wave -noupdate /tb_ctc/input_clk
add wave -noupdate -radix unsigned -childformat {{/tb_ctc/input_clk_time_in_ps(63) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(62) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(61) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(60) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(59) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(58) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(57) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(56) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(55) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(54) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(53) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(52) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(51) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(50) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(49) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(48) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(47) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(46) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(45) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(44) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(43) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(42) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(41) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(40) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(39) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(38) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(37) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(36) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(35) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(34) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(33) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(32) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(31) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(30) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(29) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(28) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(27) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(26) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(25) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(24) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(23) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(22) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(21) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(20) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(19) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(18) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(17) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(16) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(15) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(14) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(13) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(12) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(11) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(10) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(9) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(8) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(7) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(6) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(5) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(4) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(3) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(2) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(1) -radix unsigned} {/tb_ctc/input_clk_time_in_ps(0) -radix unsigned}} -subitemconfig {/tb_ctc/input_clk_time_in_ps(63) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(62) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(61) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(60) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(59) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(58) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(57) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(56) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(55) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(54) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(53) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(52) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(51) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(50) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(49) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(48) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(47) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(46) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(45) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(44) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(43) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(42) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(41) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(40) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(39) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(38) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(37) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(36) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(35) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(34) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(33) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(32) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(31) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(30) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(29) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(28) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(27) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(26) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(25) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(24) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(23) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(22) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(21) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(20) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(19) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(18) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(17) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(16) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(15) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(14) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(13) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(12) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(11) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(10) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(9) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(8) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(7) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(6) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(5) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(4) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(3) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(2) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(1) {-height 16 -radix unsigned} /tb_ctc/input_clk_time_in_ps(0) {-height 16 -radix unsigned}} /tb_ctc/input_clk_time_in_ps
add wave -noupdate -radix unsigned /tb_ctc/input_clk_time_in_ns
add wave -noupdate -radix unsigned /tb_ctc/input_packet_counter
add wave -noupdate /tb_ctc/output_clk
add wave -noupdate /tb_ctc/output_clk_time_in_ps
add wave -noupdate /tb_ctc/output_clk_time_in_ns
add wave -noupdate /tb_ctc/output_clk_wall_time
add wave -noupdate -radix unsigned -childformat {{/tb_ctc/input_clk_wall_time.sec -radix unsigned} {/tb_ctc/input_clk_wall_time.ns -radix unsigned}} -subitemconfig {/tb_ctc/input_clk_wall_time.sec {-height 16 -radix unsigned} /tb_ctc/input_clk_wall_time.ns {-height 16 -radix unsigned}} /tb_ctc/input_clk_wall_time
add wave -noupdate /tb_ctc/hbm_data_out_stop
add wave -noupdate /tb_ctc/E_DUT/E_HBM_BUFFER/ra_phase
add wave -noupdate /tb_ctc/E_DUT/E_HBM_BUFFER/wa_phase_low
add wave -noupdate /tb_ctc/E_DUT/E_HBM_BUFFER/wa_phase_high
add wave -noupdate -childformat {{/tb_ctc/P_STIMULI/outer_time(5) -radix unsigned} {/tb_ctc/P_STIMULI/outer_time(4) -radix unsigned} {/tb_ctc/P_STIMULI/outer_time(3) -radix unsigned} {/tb_ctc/P_STIMULI/outer_time(2) -radix unsigned} {/tb_ctc/P_STIMULI/outer_time(1) -radix unsigned} {/tb_ctc/P_STIMULI/outer_time(0) -radix unsigned}} -subitemconfig {/tb_ctc/P_STIMULI/outer_time(5) {-height 16 -radix unsigned} /tb_ctc/P_STIMULI/outer_time(4) {-height 16 -radix unsigned} /tb_ctc/P_STIMULI/outer_time(3) {-height 16 -radix unsigned} /tb_ctc/P_STIMULI/outer_time(2) {-height 16 -radix unsigned} /tb_ctc/P_STIMULI/outer_time(1) {-height 16 -radix unsigned} /tb_ctc/P_STIMULI/outer_time(0) {-height 16 -radix unsigned}} /tb_ctc/P_STIMULI/outer_time
add wave -noupdate /tb_ctc/data_in
add wave -noupdate /tb_ctc/data_in_slv
add wave -noupdate /tb_ctc/data_in_vld
add wave -noupdate /tb_ctc/data_in_sop
add wave -noupdate -color Magenta /tb_ctc/data_in_stop
add wave -noupdate /tb_ctc/E_DUT/enable_timed_input
add wave -noupdate /tb_ctc/E_DUT/enable_timed_output
add wave -noupdate /tb_ctc/E_DUT/E_HBM_BUFFER/o_error_ctc_full
add wave -noupdate -group HBM_EMU_RAM /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/BRAM/g_FULL_DEPTH
add wave -noupdate -group HBM_EMU_RAM /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/BRAM/g_PRIMITIVE_DEPTH
add wave -noupdate -group HBM_EMU_RAM /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/BRAM/g_DATA_WIDTH
add wave -noupdate -group HBM_EMU_RAM /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/BRAM/clka
add wave -noupdate -group HBM_EMU_RAM /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/BRAM/clkb
add wave -noupdate -group HBM_EMU_RAM /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/BRAM/rstb
add wave -noupdate -group HBM_EMU_RAM /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/BRAM/wea
add wave -noupdate -group HBM_EMU_RAM /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/BRAM/addra
add wave -noupdate -group HBM_EMU_RAM /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/BRAM/dina
add wave -noupdate -group HBM_EMU_RAM /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/BRAM/addrb
add wave -noupdate -group HBM_EMU_RAM /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/BRAM/doutb
add wave -noupdate -group HBM_EMU_RAM /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/BRAM/dout_array
add wave -noupdate -group HBM_EMU_RAM /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/BRAM/p1_addrb
add wave -noupdate -group HBM_EMU_RAM /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/BRAM/g_LOWER_BITS
add wave -noupdate -group HBM_EMU_RAM /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/BRAM/g_UPPER_BITS
add wave -noupdate -group HBM_EMU_RAM /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/BRAM/g_PRIMITIVE_COUNT
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/TIMING_FIELDS_RW
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/REPORT_FIELDS_RW
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/REPORT_FIELDS_RO
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/REPORT_FIELDS_RO_HOLD
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_mace_clk
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_mace_clk_rst
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_input_clk
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/o_input_clk_rst
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_hbm_clk
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/o_hbm_clk_rst
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_output_clk
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/o_output_clk_rst
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_debug_ctc_ra_cursor
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_debug_ctc_ra_phase
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_debug_ctc_empty
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_min_packet_seen
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_max_packet_reached
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/o_input_end_ts
add wave -noupdate -expand -group CONFIG -expand /tb_ctc/E_DUT/E_CTC_CONFIG/SETUP_FIELDS_RW
add wave -noupdate -expand -group CONFIG -expand /tb_ctc/E_DUT/E_CTC_CONFIG/SETUP_FIELDS_RO
add wave -noupdate -expand -group CONFIG -group COARSE_DELAY /tb_ctc/E_DUT/E_CTC_CONFIG/COARSE_DELAY_FIELDS_RW
add wave -noupdate -expand -group CONFIG -group COARSE_DELAY /tb_ctc/E_DUT/E_CTC_CONFIG/COARSE_DELAY_FIELDS_RO
add wave -noupdate -expand -group CONFIG -group COARSE_DELAY /tb_ctc/E_DUT/E_CTC_CONFIG/COARSE_DELAY_TABLE_0_IN
add wave -noupdate -expand -group CONFIG -group COARSE_DELAY /tb_ctc/E_DUT/E_CTC_CONFIG/COARSE_DELAY_TABLE_0_OUT
add wave -noupdate -expand -group CONFIG -group COARSE_DELAY /tb_ctc/E_DUT/E_CTC_CONFIG/COARSE_DELAY_TABLE_1_IN
add wave -noupdate -expand -group CONFIG -group COARSE_DELAY /tb_ctc/E_DUT/E_CTC_CONFIG/COARSE_DELAY_TABLE_1_OUT
add wave -noupdate -expand -group CONFIG -group COARSE_DELAY /tb_ctc/E_DUT/E_CTC_CONFIG/mace_out_rst
add wave -noupdate -expand -group CONFIG -group COARSE_DELAY /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_COARSE_DELAY/mace_out_rst_p
add wave -noupdate -expand -group CONFIG -group COARSE_DELAY /tb_ctc/E_DUT/E_CTC_CONFIG/i_coarse_delay_addr
add wave -noupdate -expand -group CONFIG -group COARSE_DELAY /tb_ctc/E_DUT/E_CTC_CONFIG/i_coarse_delay_addr_vld
add wave -noupdate -expand -group CONFIG -group COARSE_DELAY /tb_ctc/E_DUT/E_CTC_CONFIG/o_coarse_delay_value
add wave -noupdate -expand -group CONFIG -group COARSE_DELAY /tb_ctc/E_DUT/E_CTC_CONFIG/o_coarse_delay_delta_hpol
add wave -noupdate -expand -group CONFIG -group COARSE_DELAY /tb_ctc/E_DUT/E_CTC_CONFIG/o_coarse_delay_delta_vpol
add wave -noupdate -expand -group CONFIG -group COARSE_DELAY /tb_ctc/E_DUT/E_CTC_CONFIG/o_coarse_delay_delta_delta
add wave -noupdate -expand -group CONFIG -group COARSE_DELAY /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_COARSE_DELAY/active_table
add wave -noupdate -expand -group CONFIG -group COARSE_DELAY /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_COARSE_DELAY/addr
add wave -noupdate -expand -group CONFIG -group COARSE_DELAY /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_COARSE_DELAY/rd_en
add wave -noupdate -expand -group CONFIG -group COARSE_DELAY /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_COARSE_DELAY/rd_vld
add wave -noupdate -expand -group CONFIG -group COARSE_DELAY /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_COARSE_DELAY/state
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_end_of_integration_period
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_curent_packet_count
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/o_input_start_ts
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/o_input_prime_wt
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/o_input_cycles_per_packet
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/o_enable_timed_input
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_hbm_ready
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/o_hbm_start_ts
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/o_output_start_ts
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/o_output_start_wt
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/o_output_cycles_per_packet
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/o_enable_timed_output
add wave -noupdate -expand -group CONFIG -group VALID_COUNTER /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_VALID_BLOCK_COUNT/addr
add wave -noupdate -expand -group CONFIG -group VALID_COUNTER /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_VALID_BLOCK_COUNT/wr_en
add wave -noupdate -expand -group CONFIG -group VALID_COUNTER /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_VALID_BLOCK_COUNT/rd_en
add wave -noupdate -expand -group CONFIG -group VALID_COUNTER /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_VALID_BLOCK_COUNT/rd_vld
add wave -noupdate -expand -group CONFIG -group VALID_COUNTER /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_VALID_BLOCK_COUNT/wr_dat
add wave -noupdate -expand -group CONFIG -group VALID_COUNTER /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_VALID_BLOCK_COUNT/rd_dat
add wave -noupdate -expand -group CONFIG -group VALID_COUNTER /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_VALID_BLOCK_COUNT/state
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/REPORT_FIELDS_RO
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/REPORT_FIELDS_RO_HOLD
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_error_input_buffer_full
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_error_input_buffer_overflow
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_error_ctc_full
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_error_overwrite
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_error_too_late
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_error_wa_fifo_full
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_error_ra_fifo_full
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_error_bv_fifo_full
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_error_bv_fifo_underflow
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_error_coarse_delay_fifo_overflow
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_error_ctc_underflow
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/i_error_output_aligment_loss
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/mace_config_vld
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_CDC/input_config_vld
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_CDC/hbm_config_vld
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_CDC/output_config_vld
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_CDC/input_start_ts
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_CDC/input_config_prime_wt_slv
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_CDC/input_cycles_per_packet
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_CDC/hbm_start_ts
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_CDC/output_start_ts
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_CDC/output_config_start_wt_slv
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_CDC/output_cycles_per_packet
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/mace_config_prime_wt
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/mace_config_input_cycles
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/mace_config_start_ts
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/mace_config_start_wt
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/mace_config_output_cycles
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/mace_reset
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/mace_hbm_rst
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/hbm_ready
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/mace_out_rst
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/mace_in_rst
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_RESET/state
add wave -noupdate -expand -group CONFIG /tb_ctc/E_DUT/E_CTC_CONFIG/GEN_RESET/counter
add wave -noupdate -group HBM /tb_ctc/hbm_rst
add wave -noupdate -group HBM /tb_ctc/hbm_mosi
add wave -noupdate -group HBM /tb_ctc/hbm_miso
add wave -noupdate -group HBM /tb_ctc/hbm_ready
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/g_FPGA_COUNT
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/g_HBM_BURST_LEN
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/g_INPUT_STOP_WORDS
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/o_error_input_buffer_full
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/o_error_input_buffer_overflow
add wave -noupdate -group INPUT_BUFFER -childformat {{/tb_ctc/E_DUT/E_INPUT_BUFFER/i_input_clk_wall_time.sec -radix unsigned} {/tb_ctc/E_DUT/E_INPUT_BUFFER/i_input_clk_wall_time.ns -radix unsigned}} -expand -subitemconfig {/tb_ctc/E_DUT/E_INPUT_BUFFER/i_input_clk_wall_time.sec {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_INPUT_BUFFER/i_input_clk_wall_time.ns {-height 16 -radix unsigned}} /tb_ctc/E_DUT/E_INPUT_BUFFER/i_input_clk_wall_time
add wave -noupdate -group INPUT_BUFFER -radix unsigned -childformat {{/tb_ctc/E_DUT/E_INPUT_BUFFER/i_config_prime_wt.sec -radix unsigned} {/tb_ctc/E_DUT/E_INPUT_BUFFER/i_config_prime_wt.ns -radix unsigned}} -expand -subitemconfig {/tb_ctc/E_DUT/E_INPUT_BUFFER/i_config_prime_wt.sec {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_INPUT_BUFFER/i_config_prime_wt.ns {-height 16 -radix unsigned}} /tb_ctc/E_DUT/E_INPUT_BUFFER/i_config_prime_wt
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/i_config_start_ts
add wave -noupdate -group INPUT_BUFFER -radix decimal /tb_ctc/E_DUT/E_INPUT_BUFFER/i_config_input_cycles
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/i_input_end_ts
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/o_min_packet_seen
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/o_max_packet_reached
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/i_data_in_record
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/i_data_in
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/i_data_in_vld
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/i_data_in_sop
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/GEN_INPUT_BUFFER/prog_full
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/GEN_INPUT_BUFFER/h_full
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/GEN_INPUT_BUFFER/h_prog_full
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/GEN_INPUT_BUFFER/cycle_counter
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/GEN_INPUT_BUFFER/wait_for_start
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/GEN_INPUT_BUFFER/trigger_dummy
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/GEN_INPUT_BUFFER/dummy_packet_count
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/GEN_INPUT_BUFFER/dummy_header
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/GEN_INPUT_BUFFER/input_state
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/GEN_INPUT_BUFFER/header_slv
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/GEN_INPUT_BUFFER/in_packet_count
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/GEN_INPUT_BUFFER/din
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/GEN_INPUT_BUFFER/wr_en
add wave -noupdate -group INPUT_BUFFER -expand /tb_ctc/E_DUT/E_INPUT_BUFFER/GEN_INPUT_BUFFER/in_header
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/GEN_INPUT_BUFFER/in_header_we
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/GEN_INPUT_BUFFER/header_dout
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/wr_rst_busy
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/rd_rst_busy
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/dout
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/mout
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/out_dummy_header
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/out_header_empty
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/out_header
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/o_data_in_stop
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/o_data_out
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/o_data_out_vld
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/i_data_out_rdy
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/o_header_out
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/o_dummy_header
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/o_header_out_vld
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/i_header_out_rdy
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/c_FIFO_DEPTH_LOG2
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/c_FIFO_DEPTH
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/c_HBM_WIDTH
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/c_FIFO_WIDTH_64
add wave -noupdate -group INPUT_BUFFER /tb_ctc/E_DUT/E_INPUT_BUFFER/c_FIFO_WIDTH_256
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/read_out_delay
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/g_DEPTH
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/g_BURST_LEN
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/g_USE_HBM
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/g_HBM_EMU_STUTTER
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/i_hbm_rst
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/i_we
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/i_wa
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/i_wae
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/i_wid
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/o_w_ack
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/o_w_ack_id
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/i_data_in
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/i_last
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/i_ra
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/i_re
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/i_rid
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/o_data_out_id
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/o_read_ready
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/o_write_ready
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/o_wa_ready
add wave -noupdate -group HBM_EMU -color Yellow /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/i_hbm_clk
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/i_data_out_stop
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/f_wa_ready
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/f_read_ready
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/f_write_ready
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/f_w_ack
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/f_w_ack_id
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/f_data_out
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/c_HBM_WIDTH
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/g_LOG2_DEPTH
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/g_FIFO_SIZE
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/w_din
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/w_dout
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/w_re
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/w_empty
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/w_burst_count
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/wa_din
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/wa_dout
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/wa_re
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/wa_empty
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/ra_din
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/ra_dout
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/ra_re
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/ra_empty
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/r_burst_count
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/w_we
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/w
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/r
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/wa
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/GEN_EMULATOR/ra
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/f_data_out_vld
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/f_data_out_id
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/o_data_out
add wave -noupdate -group HBM_EMU /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/o_data_out_vld
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/g_USE_HBM
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/g_HBM_EMU_STUTTER
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/g_ATOM_SIZE
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/g_INPUT_TIME_COUNT
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/g_STATION_GROUP_SIZE
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/g_COARSE_CHANNELS
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/g_AUX_WIDTH
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/g_WIDTH_PADDING
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/g_OUTPUT_PRELOAD
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/o_debug_ctc_ra_cursor
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/o_debug_ctc_ra_phase
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/o_debug_ctc_empty
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/i_hbm_clk
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/i_hbm_rst
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/i_data_in
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/i_data_in_vld
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/o_data_in_rdy
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/i_header_in
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/i_header_in_vld
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/o_header_in_rdy
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/write_ready
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/wa_ready
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/ra_ready
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/write_enable
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/w_last
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/burst_count
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/wa_valid
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/write_address
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/ra_valid
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/read_address
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/w_ack
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/wait_for_aux_e
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/empty
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/full
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/wa_phase_low
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/wa_phase_high
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/wa_high_is_aux
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/ra_phase
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/ra_cursor
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/wa_cursor
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/o_data_out
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/o_data_out_vld
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/new_block
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/station_channel
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/p_station_channel
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/station_channel_vld
add wave -noupdate -group HBM_BUFFER -radix unsigned -childformat {{/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(23) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(22) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(21) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(20) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(19) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(18) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(17) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(16) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(15) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(14) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(13) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(12) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(11) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(10) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(9) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(8) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(7) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(6) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(5) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(4) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(3) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(2) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(1) -radix unsigned} {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(0) -radix unsigned}} -subitemconfig {/tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(23) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(22) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(21) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(20) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(19) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(18) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(17) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(16) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(15) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(14) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(13) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(12) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(11) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(10) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(9) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(8) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(7) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(6) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(5) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(4) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(3) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(2) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(1) {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter(0) {-height 16 -radix unsigned}} /tb_ctc/E_DUT/E_HBM_BUFFER/ra_counter
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/g_OUTPUT_TIME_COUNT
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/g_STATION_NUMBER
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/g_MAIN_WIDTH
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/g_MAIN_HEIGHT
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/g_HEIGHT_FACTOR
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/g_HEIGHT_PADDING
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/g_BUFFER_WIDTH
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/g_BUFFER_HEIGHT
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/g_MAIN_BUFFER_SIZE
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/g_AUX_HEIGHT
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/c_AUX_NUMBER
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/g_AUX_BUFFER_SIZE
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/g_OVERALL_SIZE
add wave -noupdate -group HBM_BUFFER /tb_ctc/E_DUT/E_HBM_BUFFER/g_OVERALL_SIZE_LOG2
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_USE_CASE_IS_WRITE
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_START_PHASE
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_ATOM_SIZE
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_OUTPUT_TIME_COUNT
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_STATION_GROUP_SIZE
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_COARSE_CHANNELS
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_AUX_WIDTH
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_WIDTH_PADDING
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_OUTPUT_PRELOAD
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_MAXIMUM_DRIFT
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_2_POW_40
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_TIME_WIDTH_INV40
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/i_clk
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/i_rst
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/i_header_in
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/i_header_in_vld
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/o_header_in_rdy
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/i_address_rdy
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/i_address_stop
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/header_in_rdy
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/o_phase_low
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/o_phase_high
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/o_cursor
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/pa_packet_count
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/pa_adjusted
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/pa_min_adjusted
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/pa_station
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/pa_channel
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/pa_dummy_header
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/pb_full_product_0
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/pb_full_product_1
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/pb_full_product_2
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/pb_full_product_3
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/pb_min_full_product_0
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/pb_min_full_product_1
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/pb_min_full_product_2
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/pb_min_full_product_3
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/pb_min_quotient
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/pc_iteration
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/GEN_READ_OR_WRITE/PC_EXTRACT_DATA/min_cut_product
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/GEN_READ_OR_WRITE/PC_EXTRACT_DATA/min_full_product
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/pc_min_iteration
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/pd_time_main
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/pd_time_aux
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p1_dummy_header
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p1_iteration_low
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p1_iteration
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p1_phase
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p1_buffer
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p1_aux
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p1_time
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p1_station
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p1_group
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p1_channel
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p1_inner_time
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p1_packet_count
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p2_dummy_header
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p2_dev_null
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p2_maximum_pc
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p2_minimum_pc
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p2_iteration_high
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p2_iteration_low
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p2_phase
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p2_buffer
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p2_aux
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p2_time
add wave -noupdate -group WA_MAN -radix hexadecimal /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p2_sc
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p2_station
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p2_cursor
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p3_dev_null
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p3_buffer
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p3_x
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p3_y
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p3_aux_buffer_offset
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p3_aux_x
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p3_aux_y
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p4_address_in_packet
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p4_offset
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p4_block_offset
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p4_clear
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p4_good
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/packet_state
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/address_we
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/address
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/o_address
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/o_address_vld
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/pa_vld
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/pb_vld
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/pc_vld
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p1_vld
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p2_vld
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p3_vld
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/p4_vld
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_INPUT_TIME_COUNT
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_MAIN_WIDTH
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_MAIN_HEIGHT
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_HEIGHT_FACTOR
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_HEIGHT_PADDING
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_BUFFER_WIDTH
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_BUFFER_HEIGHT
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_MAIN_BUFFER_SIZE
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_AUX_HEIGHT
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/c_AUX_NUMBER
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_AUX_BUFFER_SIZE
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_OVERALL_SIZE
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_OVERALL_SIZE_LOG2
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/g_PRELOAD_OFFSET
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/c_MAIN
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/c_AUX_S
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/c_AUX_E
add wave -noupdate -group WA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_WRITE_ADDRESS_MANAGER/c_INIT
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_USE_CASE_IS_WRITE
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_START_PHASE
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_ATOM_SIZE
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_OUTPUT_TIME_COUNT
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_STATION_GROUP_SIZE
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_COARSE_CHANNELS
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_AUX_WIDTH
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_WIDTH_PADDING
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_OUTPUT_PRELOAD
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_COARSE_DELAY_OFFSET
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/i_clk
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/i_rst
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/i_header_in
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/i_address_stop
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/o_cursor
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p1_phase
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p1_buffer
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p1_aux
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p1_time
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p1_station
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p1_group
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p1_channel
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p1_inner_time
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p1_cursor
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p1_address_in_packet
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p2_phase
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p2_buffer
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p2_aux
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p2_time
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p2_sc
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p2_station
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p2_cursor
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p2_address_in_packet
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p3_buffer
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p3_x
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p3_y
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p3_aux_buffer_offset
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p3_aux_x
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p3_aux_y
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p3_address_in_packet
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p4_offset
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p4_address_in_packet
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/packet_state
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/address_we
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/address
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/o_address
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/o_address_vld
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/i_address_rdy
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p1_vld
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p2_vld
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p3_vld
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/p4_vld
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_INPUT_TIME_COUNT
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_MAIN_WIDTH
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_MAIN_HEIGHT
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_HEIGHT_FACTOR
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_HEIGHT_PADDING
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_BUFFER_WIDTH
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_BUFFER_HEIGHT
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_MAIN_BUFFER_SIZE
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_AUX_HEIGHT
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/c_AUX_NUMBER
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_AUX_BUFFER_SIZE
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_OVERALL_SIZE
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_OVERALL_SIZE_LOG2
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/g_PRELOAD_OFFSET
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/c_MAIN
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/c_AUX_S
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/c_AUX_E
add wave -noupdate -group RA_MAN /tb_ctc/E_DUT/E_HBM_BUFFER/E_READ_ADDRESS_MANAGER/c_INIT
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/g_DEPTH_IN_BLOCKS
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/g_INPUT_BLOCK_SIZE
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/g_HBM_BURST_LEN
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/i_hbm_clk
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/i_hbm_rst
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/i_wa_block_offset
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/i_wa_block_offset_vld
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/i_wa_ack
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/i_wa_block_good
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/i_ra_block_offset
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/i_ra_block_offset_vld
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/i_ra_block_clear
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/i_ra_ack
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/o_error_overwrite
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/o_error_wa_fifo_full
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/o_error_ra_fifo_full
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/o_error_bv_fifo_full
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/o_error_bv_fifo_underflow
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/o_new_block
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/o_block_vld
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/o_reset_busy
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/wa_rst_busy
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/ra_rst_busy
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/block_valid_rst_busy
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/wa_fifo_empty
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/wa
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/wa_re
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/wa_empty
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/ra
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/ra_re
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/ra_empty
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/state
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/addr_in
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/data_in
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/write_enable
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/addr_out
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/data_out
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/bv_fifo_empty
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/block_valid
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/block_valid_we
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/wa_ack_counter1
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/wa_ack
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/wa_ack_counter2
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/ra_ack_counter
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/ra_ack
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/c_FIFO_SIZE
add wave -noupdate -group BLOCK_TRACKER /tb_ctc/E_DUT/E_HBM_BUFFER/GEN_BUFFER/E_BUFFER/E_BLOCK_TRACKER/c_ADDR_WIDTH
add wave -noupdate -group OUTPUT_BUFFER -radix unsigned /tb_ctc/E_DUT/E_OUTPUT_BUFFER/g_INPUT_PACKET_LEN
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/g_INPUT_STOP_WORDS
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/c_COARSE_DELAY_ONE_CYCLE_POS
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/c_COARSE_DELAY_PACKET_NUM_POS
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/c_COARSE_DELAY_WIDTH
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/c_MAXIMUM_TIME
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_data_in
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_data_in_vld
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/o_data_in_stop
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_data_out_stop
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/coarse_delay_addr_vld
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_hbm_config_update
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_out_config_update
add wave -noupdate -group OUTPUT_BUFFER -radix decimal /tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_coarse_delay_value
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_coarse_delay_delta_hpol
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_coarse_delay_delta_vpol
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_coarse_delay_delta_delta
add wave -noupdate -group OUTPUT_BUFFER -radix decimal /tb_ctc/E_DUT/E_OUTPUT_BUFFER/coarse_delay_start
add wave -noupdate -group OUTPUT_BUFFER -radix unsigned /tb_ctc/E_DUT/E_OUTPUT_BUFFER/P_DEMULTIPLEX/coarse_delay_start_time
add wave -noupdate -group OUTPUT_BUFFER -radix unsigned /tb_ctc/E_DUT/E_OUTPUT_BUFFER/P_DEMULTIPLEX/coarse_delay_start_inpacket
add wave -noupdate -group OUTPUT_BUFFER -radix decimal /tb_ctc/E_DUT/E_OUTPUT_BUFFER/coarse_delay_end
add wave -noupdate -group OUTPUT_BUFFER -radix unsigned /tb_ctc/E_DUT/E_OUTPUT_BUFFER/P_DEMULTIPLEX/coarse_delay_end_time
add wave -noupdate -group OUTPUT_BUFFER -radix unsigned /tb_ctc/E_DUT/E_OUTPUT_BUFFER/P_DEMULTIPLEX/coarse_delay_end_inpacket
add wave -noupdate -group OUTPUT_BUFFER -color Yellow /tb_ctc/E_DUT/E_OUTPUT_BUFFER/wr_en_coarse
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/wr_en_station
add wave -noupdate -group OUTPUT_BUFFER -radix unsigned /tb_ctc/E_DUT/E_OUTPUT_BUFFER/curr_time
add wave -noupdate -group OUTPUT_BUFFER -color Yellow -radix hexadecimal -childformat {{/tb_ctc/E_DUT/E_OUTPUT_BUFFER/segment_valid_in(3) -radix unsigned} {/tb_ctc/E_DUT/E_OUTPUT_BUFFER/segment_valid_in(2) -radix unsigned} {/tb_ctc/E_DUT/E_OUTPUT_BUFFER/segment_valid_in(1) -radix unsigned} {/tb_ctc/E_DUT/E_OUTPUT_BUFFER/segment_valid_in(0) -radix unsigned}} -subitemconfig {/tb_ctc/E_DUT/E_OUTPUT_BUFFER/segment_valid_in(3) {-color Yellow -height 16 -radix unsigned} /tb_ctc/E_DUT/E_OUTPUT_BUFFER/segment_valid_in(2) {-color Yellow -height 16 -radix unsigned} /tb_ctc/E_DUT/E_OUTPUT_BUFFER/segment_valid_in(1) {-color Yellow -height 16 -radix unsigned} /tb_ctc/E_DUT/E_OUTPUT_BUFFER/segment_valid_in(0) {-color Yellow -height 16 -radix unsigned}} /tb_ctc/E_DUT/E_OUTPUT_BUFFER/segment_valid_in
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/next_station
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/next_time
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/next_group
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/next_coarse
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/next_address
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/o_end_of_integration_period
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/o_current_packet_count
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/post_reset
add wave -noupdate -group OUTPUT_BUFFER -radix unsigned /tb_ctc/E_DUT/E_OUTPUT_BUFFER/counter
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/switch_fifo
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/almost_full
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/o_coarse_delay_addr
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/o_coarse_delay_addr_vld
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/coarse_delay_we
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/o_error_dsp_overflow
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/E_MULT_DSP/g_MREG
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/E_MULT_DSP/i_CLK
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/E_MULT_DSP/i_A
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/E_MULT_DSP/i_B
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/E_MULT_DSP/o_P
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/E_MULT_DSP/A
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/E_MULT_DSP/B
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/E_MULT_DSP/C
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/E_MULT_DSP/D
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/E_MULT_DSP/P
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/E_MULT_DSP/OPMODE
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/E_MULT_DSP/INMODE
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/S_uns
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/S_start_uns
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/S_diff
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/P_CONTROL_COARSE_DELAY_DELTA/S
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/P_CONTROL_COARSE_DELAY_DELTA/S_full_diff
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/P_CONTROL_COARSE_DELAY_DELTA/S_start
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/cd_config_start_ts
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/delta_hpol
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/delta_vpol
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/delta_delta
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/current_packet_count
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 -radix decimal /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/cd_packet_count
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 -radix decimal /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/coarse_delay_hpol_delta_out
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 -radix decimal /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/coarse_delay_vpol_delta_out
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/coarse_delay_delta_we
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/coarse_delay_delta_full
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/second_delta
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/local_dout(1132)
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 -radix unsigned /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/local_coarse_delay
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/local_coarse_delay_we
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/din
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/P_COARSE_DELAY/segment_valid
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/P_COARSE_DELAY/start
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/local_re
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/local_empty
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/local_full
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/local_dout
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/P_COARSE_DELAY/meta
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/local_din
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/local_we
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO0 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/segment
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/coarse_delay_re
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_output_clk
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(1)/cd_config_start_ts
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/delta_hpol
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/delta_vpol
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(0)/delta_delta
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/current_packet_count
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 -radix decimal /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(1)/cd_packet_count
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 -radix decimal /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(1)/coarse_delay_hpol_delta_out
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 -radix decimal /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(1)/coarse_delay_vpol_delta_out
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(1)/coarse_delay_delta_we
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(1)/coarse_delay_delta_full
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(1)/second_delta
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(1)/local_dout(1132)
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 -radix unsigned /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(1)/local_coarse_delay
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(1)/local_coarse_delay_we
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(1)/din
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(1)/P_COARSE_DELAY/segment_valid
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(1)/P_COARSE_DELAY/start
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(1)/local_re
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(1)/local_empty
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(1)/local_full
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(1)/local_dout
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(1)/P_COARSE_DELAY/meta
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(1)/local_din
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(1)/local_we
add wave -noupdate -group OUTPUT_BUFFER -expand -group FIFO1 /tb_ctc/E_DUT/E_OUTPUT_BUFFER/GEN_FIFOS(1)/segment
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/dout
add wave -noupdate -group OUTPUT_BUFFER -color Magenta /tb_ctc/E_DUT/E_OUTPUT_BUFFER/out_counter
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/out_running
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/rd_en
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/empty
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_output_clk_rst
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_output_clk
add wave -noupdate -group OUTPUT_BUFFER -childformat {{/tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_output_clk_wall_time.sec -radix unsigned} {/tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_output_clk_wall_time.ns -radix unsigned}} -expand -subitemconfig {/tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_output_clk_wall_time.sec {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_output_clk_wall_time.ns {-height 16 -radix unsigned}} /tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_output_clk_wall_time
add wave -noupdate -group OUTPUT_BUFFER -childformat {{/tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_config_start_wt.sec -radix unsigned} {/tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_config_start_wt.ns -radix unsigned}} -expand -subitemconfig {/tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_config_start_wt.sec {-height 16 -radix unsigned} /tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_config_start_wt.ns {-height 16 -radix unsigned}} /tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_config_start_wt
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/i_config_output_cycles
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/wait_for_start
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/my_update
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/cycle_counter
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/output_trigger
add wave -noupdate -group OUTPUT_BUFFER -color Magenta /tb_ctc/E_DUT/E_OUTPUT_BUFFER/coarse_delay_re
add wave -noupdate -group OUTPUT_BUFFER -color Magenta /tb_ctc/E_DUT/E_OUTPUT_BUFFER/coarse_delay_empty
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/out_packet_count_raw
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/out_inner_packet_count
add wave -noupdate -group OUTPUT_BUFFER -childformat {{/tb_ctc/E_DUT/E_OUTPUT_BUFFER/out_coarse_delay(1) -radix unsigned} {/tb_ctc/E_DUT/E_OUTPUT_BUFFER/out_coarse_delay(0) -radix unsigned}} -expand -subitemconfig {/tb_ctc/E_DUT/E_OUTPUT_BUFFER/out_coarse_delay(1) {-color Magenta -height 16 -radix unsigned} /tb_ctc/E_DUT/E_OUTPUT_BUFFER/out_coarse_delay(0) {-color Magenta -height 16 -radix unsigned}} /tb_ctc/E_DUT/E_OUTPUT_BUFFER/out_coarse_delay
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/out_virtual_channel
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/out_station
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/o_start_of_frame
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/o_error_ctc_underflow
add wave -noupdate -group OUTPUT_BUFFER -expand -subitemconfig {/tb_ctc/header_out(0) -expand} /tb_ctc/header_out
add wave -noupdate -group OUTPUT_BUFFER -color Magenta /tb_ctc/E_DUT/E_OUTPUT_BUFFER/o_data_out_vld
add wave -noupdate -group OUTPUT_BUFFER -expand -subitemconfig {/tb_ctc/E_DUT/E_OUTPUT_BUFFER/o_data_out(0) -expand /tb_ctc/E_DUT/E_OUTPUT_BUFFER/o_data_out(0).meta -expand} /tb_ctc/E_DUT/E_OUTPUT_BUFFER/o_data_out
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/c_HBM_WIDTH
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/c_META_WIDTH
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/c_ALMOST_FULL_THRESHOLD
add wave -noupdate -group OUTPUT_BUFFER /tb_ctc/E_DUT/E_OUTPUT_BUFFER/c_NUMBER_OF_SEGMENTS
add wave -noupdate /tb_ctc/hbm_data_out
add wave -noupdate /tb_ctc/hbm_data_out_vld
add wave -noupdate /tb_ctc/E_DUT/o_debug_hbm_block_vld
add wave -noupdate /tb_ctc/start_of_frame
add wave -noupdate /tb_ctc/E_DUT/o_header_out_vld
add wave -noupdate -radix decimal /tb_ctc/GEN_CHECK_OUT_DATA(0)/P_CHECK_OUTPUT_DATA/delta_delta
add wave -noupdate -radix decimal /tb_ctc/GEN_CHECK_OUT_DATA(0)/P_CHECK_OUTPUT_DATA/hpol_ps
add wave -noupdate -radix decimal /tb_ctc/GEN_CHECK_OUT_DATA(0)/P_CHECK_OUTPUT_DATA/vpol_ps
add wave -noupdate -radix decimal /tb_ctc/GEN_CHECK_OUT_DATA(0)/P_CHECK_OUTPUT_DATA/S
add wave -noupdate -radix decimal /tb_ctc/GEN_CHECK_OUT_DATA(0)/P_CHECK_OUTPUT_DATA/S_start
add wave -noupdate /tb_ctc/GEN_CHECK_OUT_DATA(0)/P_CHECK_OUTPUT_DATA/product_64
add wave -noupdate /tb_ctc/GEN_CHECK_OUT_DATA(0)/P_CHECK_OUTPUT_DATA/product_16
add wave -noupdate -radix decimal /tb_ctc/GEN_CHECK_OUT_DATA(0)/P_CHECK_OUTPUT_DATA/delta_hpol
add wave -noupdate -radix decimal /tb_ctc/GEN_CHECK_OUT_DATA(0)/P_CHECK_OUTPUT_DATA/delta_vpol
add wave -noupdate -expand -subitemconfig {/tb_ctc/header_out(1) {-height 16 -childformat {{/tb_ctc/header_out(1).hpol_phase_shift -radix decimal} {/tb_ctc/header_out(1).vpol_phase_shift -radix decimal}} -expand} /tb_ctc/header_out(1).hpol_phase_shift {-height 16 -radix decimal} /tb_ctc/header_out(1).vpol_phase_shift {-height 16 -radix decimal} /tb_ctc/header_out(0) {-height 16 -childformat {{/tb_ctc/header_out(0).hpol_phase_shift -radix decimal} {/tb_ctc/header_out(0).vpol_phase_shift -radix decimal}} -expand} /tb_ctc/header_out(0).hpol_phase_shift {-height 16 -radix decimal} /tb_ctc/header_out(0).vpol_phase_shift {-height 16 -radix decimal}} /tb_ctc/header_out
add wave -noupdate /tb_ctc/data_out
add wave -noupdate /tb_ctc/data_out_vld
add wave -noupdate /tb_ctc/E_DUT/o_packet_vld
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {242114172027 fs} 0}
quietly wave cursor active 1
configure wave -namecolwidth 239
configure wave -valuecolwidth 141
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 fs} {1724454870600 fs}
