onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/g_USE_HBM
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/g_BLOCK_SIZE
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/g_BLOCK_COUNT
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/g_GROUP_COUNT
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/g_ATOM_SIZE
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/g_BUFFER_FACTOR
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/g_INPUT_STOP_WORDS
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/g_OUTPUT_STOP_WORDS
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/i_hbm_ref_clk
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/i_hbm_clk
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/i_hbm_rst
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/i_apb_clk
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/i_data_in
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/i_data_in_vld
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/o_data_out
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/o_data_out_vld
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/o_data_in_rdy
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/o_data_in_stop
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/i_data_out_stop
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/atom_count
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/frame_ra
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/ra
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/rx
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/rblock
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/rgroup
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/write_limit
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/r_ack_x
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/new_frame
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/frame_wx
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/wx
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/frame_ww
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/ww
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/frame_wa
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/wa
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/w_ack
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/rst_p1
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/burst_count
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/data_out_vld
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/read_ready
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/write_ready
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/wa_ready
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/empty
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/almost_full
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/read_enable
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/write_enable
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/wa_write_enable
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/w_last
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/g_BUFFER_FACTOR_LOG2
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/g_BLOCKS_PER_GROUP
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/g_GROUP_COUNT_LOG2
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/g_BLOCK_COUNT_LOG2
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/g_ATOM_SIZE_LOG2
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/g_BLOCK_SIZE_IN_ATOMS
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/g_ADDR_RANGE_IN_ATOMS
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/g_ADDR_RANGE_IN_ATOMS_LOG2
add wave -noupdate -expand -group CONTROLLER /tb_ctf_hbm_buffer/E_DUT/g_ALMOST_FULL_THRESHOLD
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/G_HBM/hbm_state
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/G_HBM/hbm_counter
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/G_HBM/hbm_counter_reset
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/apb_complete
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/i_r_sel_axi
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/i_w_sel_axi
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/i_wa_sel_axi
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/o_data_out_vld
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/o_data_out
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/o_read_ready
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/o_write_ready
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/o_wa_ready
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/G_HBM/r_throughput
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/G_HBM/w_throughput
add wave -noupdate -expand -group HBM -expand -subitemconfig {/tb_ctf_hbm_buffer/E_DUT/E_BUFFER/G_HBM/E_HBM/i_saxi_00.aw -expand} /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/G_HBM/E_HBM/i_saxi_00
add wave -noupdate -expand -group HBM -expand /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/G_HBM/E_HBM/o_saxi_00
add wave -noupdate -expand -group HBM -expand -subitemconfig {/tb_ctf_hbm_buffer/E_DUT/E_BUFFER/G_HBM/E_HBM/i_saxi_01.aw -expand} /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/G_HBM/E_HBM/i_saxi_01
add wave -noupdate -expand -group HBM -expand /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/G_HBM/E_HBM/o_saxi_01
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/G_HBM/E_HBM/i_sapb_0
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/G_HBM/E_HBM/o_sapb_0
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/G_HBM/E_HBM/hbm_ref_clk_0
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/G_HBM/E_HBM/axi_00_aclk
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/G_HBM/E_HBM/apb_0_pclk
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/G_HBM/E_HBM/axi_00_areset_n
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/G_HBM/E_HBM/apb_0_preset_n
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/G_HBM/E_HBM/apb_complete_0
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/G_HBM/E_HBM/DRAM_0_STAT_CATTRIP
add wave -noupdate -expand -group HBM /tb_ctf_hbm_buffer/E_DUT/E_BUFFER/G_HBM/E_HBM/DRAM_0_STAT_TEMP
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {41994689000 fs} 0}
quietly wave cursor active 1
configure wave -namecolwidth 192
configure wave -valuecolwidth 134
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
WaveRestoreZoom {0 fs} {52374595350 fs}
