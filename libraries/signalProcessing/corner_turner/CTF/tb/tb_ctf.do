onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_ctf/hbm_clk
add wave -noupdate /tb_ctf/apb_clk
add wave -noupdate /tb_ctf/rst
add wave -noupdate /tb_ctf/data_in
add wave -noupdate /tb_ctf/data_in_vld
add wave -noupdate /tb_ctf/data_in_stop
add wave -noupdate /tb_ctf/data_out
add wave -noupdate /tb_ctf/data_out_vld
add wave -noupdate /tb_ctf/data_out_stop
add wave -noupdate /tb_ctf/hbm_buffer_data_out
add wave -noupdate /tb_ctf/hbm_buffer_data_out_vld
add wave -noupdate /tb_ctf/hbm_buffer_data_out_stop
add wave -noupdate /tb_ctf/port_done
add wave -noupdate /tb_ctf/MTA_ready
add wave -noupdate /tb_ctf/MACE_ready
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/GEN_RESET/state
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/GEN_STOP_CONTROL/halt_ts
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/GEN_STOP_CONTROL/halt_ts_cdc
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/GEN_STOP_CONTROL/halt_ts_vld
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/GEN_STOP_CONTROL/halt_ts_vld_cdc
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/GEN_STOP_CONTROL/empty_cdc
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/GEN_STOP_CONTROL/running
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/i_mace_clk
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/i_mace_clk_rst
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/i_input_clk
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/o_input_clk_rst
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/i_hbm_clk
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/o_hbm_clk_rst
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/i_saxi_mosi
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/o_saxi_miso
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/o_input_halt_ts
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/i_input_stopped
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/i_hbm_ready
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/i_debug_ctf_empty
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/i_station_addr
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/o_station_value
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/mace_reset
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/mace_hbm_rst
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/mace_in_rst
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/hbm_ready
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/SETUP_FIELDS_RW
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/SETUP_FIELDS_RO
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/STATIONS_TABLE_IN
add wave -noupdate -group CONFIG /tb_ctf/E_DUT/E_CONFIG/STATIONS_TABLE_OUT
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/i_input_halt_ts
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/o_input_stopped
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/i_hbm_clk
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/i_hbm_clk_rst
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/i_input_clk
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/i_input_clk_rst
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/i_data_in_record
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/i_data_in_slv
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/i_data_in_vld
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/o_data_in_stop
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/o_data_out
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/o_data_out_vld
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/i_data_out_stop
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/o_header_out
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/o_header_out_vld
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/state
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/header_1
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/header_in
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/header_in_vld
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/header_out
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/header_rd_en
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/header_empty
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/input_count
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/output_count
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/wr_en
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/rd_en
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/full
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/empty
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/data_out
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/meta_in
add wave -noupdate -group INPUT_DECODER /tb_ctf/E_DUT/E_INPUT_DECODER/meta_out
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/g_DEPTH
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/g_BURST_LEN
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/g_INPUT_STOP_WORDS
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/g_USE_HBM
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/i_hbm_clk
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/i_hbm_rst
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/i_we
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/i_wa
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/i_wae
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/i_wid
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/o_w_ack
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/o_w_ack_id
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/i_data_in
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/i_last
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/i_ra
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/i_re
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/i_rid
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/o_data_out_vld
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/o_data_out_id
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/o_data_out
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/i_data_out_stop
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/o_read_ready
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/o_write_ready
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/o_wa_ready
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/f_wa_ready
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/f_read_ready
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/f_write_ready
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/f_w_ack
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/f_w_ack_id
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/f_data_out
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/f_data_out_vld
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/f_data_out_id
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/c_HBM_WIDTH
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/g_LOG2_DEPTH
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/g_FIFO_SIZE
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/read_out_delay
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/w_din
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/w_dout
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/w_re
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/w_empty
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/w_we
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/w_full
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/w_burst_count
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/wa_din
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/wa_dout
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/wa_re
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/wa_empty
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/wa_full
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/ra_din
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/ra_dout
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/ra_re
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/ra_empty
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/ra_full
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/r_burst_count
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/w
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/r
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/wa
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/ra
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/r_vld
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/r_id
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/r_vld_p1
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/r_id_p1
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/r_din
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/r_dout
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/r_re
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/r_empty
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/r_full
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/r_we
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/ra_wr_rst_busy
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/wa_wr_rst_busy
add wave -noupdate -group HBM_EMU /tb_ctf/E_DUT/E_HBM_BUFFER/E_BUFFER/GEN_EMULATOR/w_wr_rst_busy
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/i_hbm_clk
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/i_hbm_rst
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/o_hbm_ready
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/i_data_in
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/i_data_in_vld
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/o_data_in_stop
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/o_data_in_rdy
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/o_data_out
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/o_data_out_vld
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/i_data_out_stop
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/o_debug_ctf_empty
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/o_hbm_mosi
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/i_hbm_miso
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/i_hbm_ready
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/atom_count
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/frame_ra
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/ra
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/rx
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/rblock
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/rgroup
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/write_limit
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/r_ack_x
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/new_frame
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/frame_wa
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/wx
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/wa
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/w_ack
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/rst_p1
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/burst_count
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/data_out_vld
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/read_ready
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/write_ready
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/wa_ready
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/empty
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/almost_full
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/read_enable
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/write_enable
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/wa_write_enable
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/w_last
add wave -noupdate -group HBM_BUFFER /tb_ctf/E_DUT/E_HBM_BUFFER/reset_counter
add wave -noupdate /tb_ctf/E_DUT/o_data_out
add wave -noupdate /tb_ctf/E_DUT/o_header_out
add wave -noupdate /tb_ctf/E_DUT/o_data_out_vld
add wave -noupdate /tb_ctf/E_DUT/i_data_out_stop
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/E_DUT_COR/g_COL_DRIVERS(0)/E_CACHE/i_tdm_cache_wr_bus
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/E_DUT_COR/g_COL_DRIVERS(0)/E_CACHE/c0_tdm_rd_ctrl
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/E_DUT_COR/g_COL_DRIVERS(0)/E_CACHE/o_wr_stop
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/E_DUT_COR/o_wr_stop
add wave -noupdate -expand -group COR /tb_ctf/E_DUT/GEN_OUTPUT_BUFFER(0)/E_OUTPUT_BUFFER/g_OUTPUT_BURST_SIZE
add wave -noupdate -expand -group COR -radix hexadecimal -childformat {{/tb_ctf/E_DUT/GEN_OUTPUT_BUFFER(0)/E_OUTPUT_BUFFER/output_count(4) -radix hexadecimal} {/tb_ctf/E_DUT/GEN_OUTPUT_BUFFER(0)/E_OUTPUT_BUFFER/output_count(3) -radix hexadecimal} {/tb_ctf/E_DUT/GEN_OUTPUT_BUFFER(0)/E_OUTPUT_BUFFER/output_count(2) -radix hexadecimal} {/tb_ctf/E_DUT/GEN_OUTPUT_BUFFER(0)/E_OUTPUT_BUFFER/output_count(1) -radix hexadecimal} {/tb_ctf/E_DUT/GEN_OUTPUT_BUFFER(0)/E_OUTPUT_BUFFER/output_count(0) -radix hexadecimal}} -subitemconfig {/tb_ctf/E_DUT/GEN_OUTPUT_BUFFER(0)/E_OUTPUT_BUFFER/output_count(4) {-height 16 -radix hexadecimal} /tb_ctf/E_DUT/GEN_OUTPUT_BUFFER(0)/E_OUTPUT_BUFFER/output_count(3) {-height 16 -radix hexadecimal} /tb_ctf/E_DUT/GEN_OUTPUT_BUFFER(0)/E_OUTPUT_BUFFER/output_count(2) {-height 16 -radix hexadecimal} /tb_ctf/E_DUT/GEN_OUTPUT_BUFFER(0)/E_OUTPUT_BUFFER/output_count(1) {-height 16 -radix hexadecimal} /tb_ctf/E_DUT/GEN_OUTPUT_BUFFER(0)/E_OUTPUT_BUFFER/output_count(0) {-height 16 -radix hexadecimal}} /tb_ctf/E_DUT/GEN_OUTPUT_BUFFER(0)/E_OUTPUT_BUFFER/output_count
add wave -noupdate -expand -group COR /tb_ctf/E_DUT/GEN_OUTPUT_BUFFER(0)/E_OUTPUT_BUFFER/i_data_out_stop
add wave -noupdate -expand -group COR /tb_ctf/E_DUT/GEN_OUTPUT_BUFFER(0)/E_OUTPUT_BUFFER/o_data_out_vld
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/P_CTF_OUT_TO_COR_IN/w_page
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/P_CHECK/r_page
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/P_CHECK/baseline
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/P_CHECK/coordinates
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/P_CHECK/mta_xx_im
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/P_CHECK/mta_xx_re
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/P_CHECK/mta_xy_im
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/P_CHECK/mta_xy_re
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/P_CHECK/mta_yx_im
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/P_CHECK/mta_yx_re
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/P_CHECK/mta_yy_im
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/P_CHECK/mta_yy_re
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/cci_progs
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/tdm_cache_wr_bus
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/wr_stop
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/cor_context
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/context_vld
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/context_rdy
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/cor_ts
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/P_CTF_OUT_TO_COR_IN/ant
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/P_CTF_OUT_TO_COR_IN/idx
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/P_CTF_OUT_TO_COR_IN/lap
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/P_CTF_OUT_TO_COR_IN/X_im
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/P_CTF_OUT_TO_COR_IN/X_re
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/P_CTF_OUT_TO_COR_IN/Y_im
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/P_CTF_OUT_TO_COR_IN/Y_re
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/s_acc_XX_re
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/s_acc_XX_im
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/s_acc_XY_re
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/s_acc_XY_im
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/s_acc_YX_re
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/s_acc_YX_im
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/s_acc_YY_re
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/s_acc_YY_im
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/mta_data_frames
add wave -noupdate -expand -group COR /tb_ctf/E_CORRLELATOR/mta_vld
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {144042777493 fs} 0}
quietly wave cursor active 1
configure wave -namecolwidth 192
configure wave -valuecolwidth 100
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
WaveRestoreZoom {92456959687 fs} {201176504007 fs}
