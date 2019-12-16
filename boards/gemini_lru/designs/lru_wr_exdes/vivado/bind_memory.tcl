proc bind_memory {source_dir fpn_elf fpn_bit_in fpn_bit_out} {

}

source c:/SKA/Firmware/boards/gemini_lru/designs/lru_wr_exdes/src/write_mmi.tcl
write_mmi c:/SKA/Firmware/boards/gemini_lru/designs/lru_wr_exdes/src/lru_wr_exdes_top.bmm

updatemem -force --meminfo c:/SKA/Firmware/boards/gemini_lru/designs/lru_wr_exdes/src/lru_wr_exdes_top.mmi --data c:/tmp/ml605/wrc_180321_7.elf --bit c:/tmp/ml605/lru/lru_wr_exdes_top.bit --proc dummy --out c:/tmp/ml605/lru/lru_wr_exdes_top_o_2903_2.bit