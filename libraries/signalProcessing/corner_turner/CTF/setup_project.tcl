set_property target_simulator ModelSim [current_project]
set_property compxlib.modelsim_compiled_library_dir $::env(MODEL_TECH_XILINX_LIB) [current_project]
set_property -name {modelsim.simulate.vsim.more_options} -value {+notimingchecks} -objects [get_filesets sim_1]
set_property -name {modelsim.compile.vlog.more_options} -value {+notimingchecks} -objects [get_filesets sim_1]
set_property -name {modelsim.simulate.runtime} -value {2ms} -objects [get_filesets sim_1]
set_property -name {modelsim.simulate.custom_wave_do} -value {../../../../../../../../../libraries/signalProcessing/corner_turner/CTF/tb/tb_ctf.do} -objects [get_filesets sim_1]
set_property INCREMENTAL false [get_filesets sim_1]
set_property used_in_synthesis false [get_files *tb_*.vhd]
set_property used_in_synthesis true [get_files  *common_tb_pkg.vhd]
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]

set_property file_type {VHDL 2008} [get_files  *.vhd]