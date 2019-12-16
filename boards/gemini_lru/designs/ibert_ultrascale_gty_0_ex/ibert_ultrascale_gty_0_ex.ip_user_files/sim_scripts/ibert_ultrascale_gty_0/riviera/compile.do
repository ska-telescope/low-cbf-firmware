vlib work
vlib riviera

vlib riviera/xil_defaultlib
vlib riviera/xpm

vmap xil_defaultlib riviera/xil_defaultlib
vmap xpm riviera/xpm

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../ibert_ultrascale_gty_0_ex.srcs/sources_1/ip/ibert_ultrascale_gty_0/hdl/verilog" "+incdir+../../../../ibert_ultrascale_gty_0_ex.srcs/sources_1/ip/ibert_ultrascale_gty_0/synth" "+incdir+../../../../ibert_ultrascale_gty_0_ex.srcs/sources_1/ip/ibert_ultrascale_gty_0/hdl/verilog" "+incdir+../../../../ibert_ultrascale_gty_0_ex.srcs/sources_1/ip/ibert_ultrascale_gty_0/synth" \
"/home/software/Xilinx/Vivado/2017.4/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/home/software/Xilinx/Vivado/2017.4/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93 \
"/home/software/Xilinx/Vivado/2017.4/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../ibert_ultrascale_gty_0_ex.srcs/sources_1/ip/ibert_ultrascale_gty_0/hdl/verilog" "+incdir+../../../../ibert_ultrascale_gty_0_ex.srcs/sources_1/ip/ibert_ultrascale_gty_0/synth" "+incdir+../../../../ibert_ultrascale_gty_0_ex.srcs/sources_1/ip/ibert_ultrascale_gty_0/hdl/verilog" "+incdir+../../../../ibert_ultrascale_gty_0_ex.srcs/sources_1/ip/ibert_ultrascale_gty_0/synth" \
"/home/hiemstra/svnlowcbf/LOWCBF/Firmware/build/lru/vivado/lru_qsfp_mbobc_25G_ibert_build_180111_153000/ibert_ultrascale_gty_0_ex/ibert_ultrascale_gty_0_ex.srcs/sources_1/ip/ibert_ultrascale_gty_0/ibert_ultrascale_gty_0_sim_netlist.v" \

vlog -work xil_defaultlib \
"glbl.v"

